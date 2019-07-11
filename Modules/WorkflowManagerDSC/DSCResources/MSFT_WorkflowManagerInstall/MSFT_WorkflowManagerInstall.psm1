$Script:UninstallPathManager = "SOFTWARE\Microsoft\Workflow Manager"
$Script:UninstallPathClient = "SOFTWARE\Microsoft\Workflow Manager Client"
$script:InstallKeyPattern = "[0-9].[0-9]"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebPIPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $XMLFeedPath,

        [parameter()]
        [System.String]
        [ValidateSet("All", "ClientOnly")]
        $ComponentsToInstall = "All"
    )
    Write-Verbose -Message "Getting details of installation of the Workflow Manager"

    if ($Ensure -eq "Absent")
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }

    if (-not (Test-Path -Path $WebPIPath))
    {
        throw "The specified path for the Web Platform Installer does not exist."
    }

    if (-not (Test-Path -Path $XMLFeedPath))
    {
        throw "The specified path for the XML Feed does not exist."
    }

    Write-Verbose -Message "Checking file status of $WebPIPath"
    $zone = Get-Item $WebPIPath -Stream "Zone.Identifier" -EA SilentlyContinue

    if ($null -ne $zone)
    {
        throw ("Setup file is blocked! Please use 'Unblock-File -Path $WebPIPath' " + `
               "to unblock the file before continuing.")
    }

    $matchPath = "HKEY_LOCAL_MACHINE\\$($Script:UninstallPathManager.Replace('\','\\'))" + `
                 "\\$script:InstallKeyPattern"
    $wmfPathManager = Get-ChildItem -Path "HKLM:\$Script:UninstallPathManager" -ErrorAction SilentlyContinue | Where-Object -FilterScript {
        $_.Name -match $matchPath
    }

    $matchPath = "HKEY_LOCAL_MACHINE\\$($Script:UninstallPathClient.Replace('\','\\'))" + `
                 "\\$script:InstallKeyPattern"
    $wmfPathClient = Get-ChildItem -Path "HKLM:\$Script:UninstallPathClient" -ErrorAction SilentlyContinue | Where-Object -FilterScript {
        $_.Name -match $matchPath
    }

    $localEnsure = "Absent"
    if ($null -ne $wmfPathClient)
    {
        $installedComponent = "ClientOnly"
        $localEnsure        = "Present"
    }

    if ($null -ne $wmfPathManager)
    {
        $installedComponent = "All"
        $localEnsure        = "Present"
    }

    return @{
        Ensure              = $localEnsure
        WebPIPath           = $WebPIPath
        XMLFeedPath         = $XMLFeedPath
        ComponentsToInstall = $installedComponent
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebPIPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $XMLFeedPath,

        [parameter()]
        [System.String]
        [ValidateSet("All", "ClientOnly")]
        $ComponentsToInstall = "All"
    )
    Write-Verbose -Message "Starting installation of the Workflow Manager"

    if ($Ensure -eq "Absent")
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }

    if (-not (Test-Path -Path $WebPIPath))
    {
        throw "The specified path for the Web Platform Installer does not exist."
    }

    if (-not (Test-Path -Path $XMLFeedPath))
    {
        throw "The specified path for the XML Feed does not exist."
    }

    Write-Verbose -Message "Checking file status of $WebPIPath"
    $zone = Get-Item $WebPIPath -Stream "Zone.Identifier" -EA SilentlyContinue

    if ($null -ne $zone)
    {
        throw ("Setup file is blocked! Please use 'Unblock-File -Path $WebPIPath' " + `
               "to unblock the file before continuing.")
    }

    Write-Verbose -Message "Checking if WebPIPath is an UNC path"
    $uncInstall = $false
    if ($WebPIPath.StartsWith("\\"))
    {
        Write-Verbose -Message ("Specified WebPIPath is an UNC path. Adding servername to Local " +
                                "Intranet Zone")

        $uncInstall = $true

        if ($WebPIPath -match "\\\\(.*?)\\.*")
        {
            $serverName = $Matches[1]
        }
        else
        {
            throw "Cannot extract servername from UNC path. Check if it is in the correct format."
        }

        Set-WMDscZoneMap -Server $serverName
    }

    if ($ComponentsToInstall -eq "All")
    {
        # Install all Workflow Manager components
        Write-Verbose -Message "Installing all Workflow Manager components"
        $arguments = "/Install /Products:WorkflowManager /XML:" + $XMLFeedPath + " /AcceptEULA /SuppressPostFinish"
    }
    else
    {
        # Install the Workflow Manager Client component
        Write-Verbose -Message "Installing the Workflow Manager Client components"
        $arguments = "/Install /Products:WorkflowClient /XML:" + $XMLFeedPath + " /AcceptEULA /SuppressPostFinish"
    }
    $installer = Start-Process -FilePath $WebPIPath `
                               -ArgumentList $arguments `
                               -Wait `
                               -NoNewWindow `
                               -PassThru

    if ($uncInstall -eq $true)
    {
        Write-Verbose -Message "Removing added path from the Local Intranet Zone"
        Remove-WMDscZoneMap -ServerName $serverName
    }

    switch ($installer.ExitCode) {
        0 {
            Write-Verbose -Message "Installation of the Workflow Manager succeeded."
         }
        Default {
            throw ("The Workflow Manager installation failed. Exit code " + `
                   "'$($installer.ExitCode)' was returned.")
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure,

        [parameter(Mandatory = $true)]
        [System.String]
        $WebPIPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $XMLFeedPath,

        [parameter()]
        [System.String]
        [ValidateSet("All", "ClientOnly")]
        $ComponentsToInstall = "All"
    )
    Write-Verbose -Message "Testing for installation of the Workflow Manager"

    if ($Ensure -eq "Absent")
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }

    $result = Get-TargetResource @PSBoundParameters

    return ($result.Ensure -eq $Ensure -and `
            $result.ComponentsToInstall -eq $ComponentsToInstall)
}

Export-ModuleMember -Function *-TargetResource

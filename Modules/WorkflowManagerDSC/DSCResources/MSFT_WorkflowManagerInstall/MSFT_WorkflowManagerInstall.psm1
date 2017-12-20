$Script:UninstallPath = "SOFTWARE\Microsoft\Workflow Manager"
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
        $XMLFeedPath
    )

    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }

    if(!(Test-Path $WebPIPath))
    {
        throw "The specified path for the Web Platform Installer does not exist."
    }

    if(!(Test-Path $XMLFeedPath))
    {
        throw "The specified path for the XML Feed does not exist."
    }

    Write-Verbose -Message "Getting details of installation of the Workflow Manager"
    
    $matchPath = "HKEY_LOCAL_MACHINE\\$($Script:UninstallPath.Replace('\','\\'))" + `
                 "\\$script:InstallKeyPattern"
    $wmfPath = Get-ChildItem -Path "HKLM:\$Script:UninstallPath" -ErrorAction SilentlyContinue | Where-Object -FilterScript {
        $_.Name -match $matchPath
    }

    $localEnsure = "Absent"
    if($null -ne $wmfPath)
    {
        $localEnsure = "Present"
    }
    
    return @{
        Ensure = $localEnsure
        WebPIPath = $WebPIPath
        XMLFeedPath = $XMLFeedPath
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
        $XMLFeedPath
    )
    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }

    Write-Verbose -Message "Starting installation of the Workflow Manager"

    $arguments = "/Install /Products:WorkflowManager /XML:" + $XMLFeedPath + " /AcceptEULA /SuppressPostFinish"
    $installer = Start-Process -FilePath $WebPIPath `
                                -ArgumentList $arguments -Wait -NoNewWindow -PassThru

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
        $XMLFeedPath
    )

    if ($Ensure -eq "Absent") 
    {
        throw "Uninstallation is not supported by Workflow Manager DSC"
    }
    
    Write-Verbose -Message "Testing for installation of the Workflow Manager"
    $result = Get-TargetResource @PSBoundParameters

    return ($result.Ensure -eq $Ensure)
}

Export-ModuleMember -Function *-TargetResource

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

    Write-Verbose -Message 'Reading XMLFeedPath file'
    [xml]$xmlFile = Get-Content -Path $XMLFeedPath

    if ($ComponentsToInstall -eq "All")
    {
        # Install all Workflow Manager components
        Write-Verbose -Message "Installing all Workflow Manager components"

        # If C:\Program Files\Workflow Manager folder exists, install will fail
        # Throw error is the folder exists and contains less than 5 files.
        if ((Test-Path -Path 'C:\Program Files\Workflow Manager') -and `
            ((Get-ChildItem -Path 'C:\Program Files\Workflow Manager' -Recurse).Count -le 5))
        {
            throw 'Folder C:\Program Files\Workflow Manager exists. Please make sure this folder is removed.'
        }

        if ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowManagerRefresh' }))
        {
            Write-Verbose -Message 'Installing Workflow Manager Refresh package'

            if ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'ServiceBus_1_1_TLS_1_2' }))
            {
                Write-Verbose -Message 'Install package contains Service Bus v1.1 TLS v1.2 update files, installing.....'
                $result = Start-WMInstall -ComponentName 'ServiceBus_1_1_TLS_1_2' `
                                          -WebPIPath $WebPIPath `
                                          -XMLFeedPath $XMLFeedPath

                switch ($result.ExitCode) {
                    0 {
                        Write-Verbose -Message "Installation of the Service Bus v1.1 TLS v1.2 update succeeded."
                    }
                    Default {
                        throw ("The Service Bus v1.1 TLS v1.2 update installation failed. " + `
                               "Exit code '$($result.ExitCode)' was returned.")
                    }
                }
            }

            Write-Verbose -Message 'Install package contains Workflow Manager Refresh files, installing.....'
            $result = Start-WMInstall -ComponentName 'WorkflowManagerRefresh' `
                                      -WebPIPath $WebPIPath `
                                      -XMLFeedPath $XMLFeedPath

            switch ($result.ExitCode) {
                0 {
                    Write-Verbose -Message "Installation of the Workflow Manager Refresh succeeded."
                }
                Default {
                    throw ("The Workflow Manager Refresh installation failed. " + `
                           "Exit code '$($result.ExitCode)' was returned.")
                }
            }

            if ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowCU5' }))
            {
                Write-Verbose -Message 'Install package contains Workflow Manager CU5 files, installing.....'
                $result = Start-WMInstall -ComponentName 'WorkflowCU5' `
                                          -WebPIPath $WebPIPath `
                                          -XMLFeedPath $XMLFeedPath

                switch ($result.ExitCode) {
                    0 {
                        Write-Verbose -Message "Installation of the Workflow Manager CU5 succeeded."
                    }
                    Default {
                        throw ("The Workflow Manager CU5 installation failed. " + `
                               "Exit code '$($result.ExitCode)' was returned.")
                    }
                }
            }
        }
        elseif ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowManager' }))
        {
            Write-Verbose -Message 'Installing Workflow Manager RTM package'

            Write-Verbose -Message 'Install package contains Workflow Manager RTM files, installing.....'
            $result = Start-WMInstall -ComponentName 'WorkflowManager' `
                                      -WebPIPath $WebPIPath `
                                      -XMLFeedPath $XMLFeedPath

            switch ($result.ExitCode) {
                0 {
                    Write-Verbose -Message "Installation of the Workflow Manager RTM succeeded."
                }
                Default {
                    throw ("The Workflow Manager RTM installation failed. " + `
                           "Exit code '$($result.ExitCode)' was returned.")
                }
            }
        }
        else
        {
            throw 'Install packages does not contain Workflow Manager RTM or Refresh files. Aborting!'
        }
    }
    else
    {
        # Install the Workflow Manager Client component
        Write-Verbose -Message "Installing the Workflow Manager Client component"

        if ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowClientCU4' }))
        {
            Write-Verbose -Message 'Installing Workflow Manager Client incl CU 4 package'

            Write-Verbose -Message 'Install package contains Workflow Manager Client incl CU4 files, installing.....'
            $result = Start-WMInstall -ComponentName 'WorkflowClientCU4' `
                                      -WebPIPath $WebPIPath `
                                      -XMLFeedPath $XMLFeedPath

            switch ($result.ExitCode) {
                0 {
                    Write-Verbose -Message "Installation of the Workflow Manager Client incl CU4 succeeded."
                }
                Default {
                    throw ("The Workflow Manager Client incl CU4 installation failed. " + `
                           "Exit code '$($result.ExitCode)' was returned.")
                }
            }

            if ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowCU5' }))
            {
                Write-Verbose -Message 'Install package contains Workflow Manager CU5 files, installing.....'
                $result = Start-WMInstall -ComponentName 'WorkflowCU5' `
                                          -WebPIPath $WebPIPath `
                                          -XMLFeedPath $XMLFeedPath

                switch ($result.ExitCode) {
                    0 {
                        Write-Verbose -Message "Installation of the Workflow Manager CU5 succeeded."
                    }
                    Default {
                        throw ("The Workflow Manager CU5 installation failed. " + `
                               "Exit code '$($result.ExitCode)' was returned.")
                    }
                }
            }
        }
        elseif ($null -ne ($xmlFile.ChildNodes.entry | Where-Object -FilterScript { $_.productId -eq 'WorkflowClient' }))
        {
            Write-Verbose -Message 'Installing Workflow Manager Client RTM package'

            Write-Verbose -Message 'Install package contains Workflow Manager Client RTM files, installing.....'
            $result = Start-WMInstall -ComponentName 'WorkflowClient' `
                                      -WebPIPath $WebPIPath `
                                      -XMLFeedPath $XMLFeedPath

            switch ($result.ExitCode) {
                0 {
                    Write-Verbose -Message "Installation of the Workflow Manager Client RTM succeeded."
                }
                Default {
                    throw ("The Workflow Manager Client RTM installation failed. " + `
                           "Exit code '$($result.ExitCode)' was returned.")
                }
            }
        }
        else
        {
            throw 'Install packages does not contain Workflow Manager Client RTM or Client incl CU4 files. Aborting!'
        }
    }

    if ($uncInstall -eq $true)
    {
        Write-Verbose -Message "Removing added path from the Local Intranet Zone"
        Remove-WMDscZoneMap -ServerName $serverName
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

function Start-WMInstall
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ComponentName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebPIPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $XMLFeedPath
    )

    $arguments = "/Install /Products:$ComponentName /XML:$XMLFeedPath /AcceptEULA /SuppressPostFinish"
    $installer = Start-Process -FilePath $WebPIPath `
                               -ArgumentList $arguments `
                               -Wait `
                               -NoNewWindow `
                               -PassThru
    return $installer
}

[CmdletBinding()]
param(
    [String] $WFCmdletModule = (Join-Path -Path $PSScriptRoot -ChildPath '..\Stubs\1.0\WorkflowManager.psm1' -Resolve)
)

$Script:DSCModuleName      = 'WorkflowManagerDsc'
$Script:DSCResourceName    = 'MSFT_WorkflowManagerInstall'
$Global:CurrentWFCmdletModule = $WFCmdletModule

[String] $moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\Modules\WorkflowManagerDsc" -Resolve
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Script:DSCModuleName `
    -DSCResourceName $Script:DSCResourceName `
    -TestType Unit

try
{
    InModuleScope $Script:DSCResourceName {
        Describe "WorkflowManagerInstall [WorkflowManager version $((Get-Item $Global:CurrentWFCmdletModule).Directory.BaseName)]" {

            Import-Module (Join-Path $PSScriptRoot "..\..\..\Modules\WorkflowManagerDsc" -Resolve)
            #Remove-Module -Name "WorkflowManager" -Force -ErrorAction SilentlyContinue
            Import-Module $Global:CurrentWFCmdletModule -WarningAction SilentlyContinue
            $Global:MethodCalledCount = 0

            Context "Workflow Manager is not installed and but should be, but package does not contain correct package" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManagerINCORRECT</productId>
</entry>
<entry>
    <productId>WorkflowClientINCORRECT</productId>
</entry>
</feed>
"@
                    return $content
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Throws exception about incorrect package in the set method" {
                    { Set-TargetResource @testParams } | Should Throw 'Install packages does not contain Workflow Manager RTM or Refresh files. Aborting!'
                }
            }

            Context "Workflow Manager is not installed, but should be" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Starts the install from the set method" {
                    { Set-TargetResource @testParams } | Should Throw 'Folder C:\Program Files\Workflow Manager exists. Please make sure this folder is removed.'
                }
            }

            Context "Workflow Manager is not installed, but should be" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager Refresh is not installed, but should be" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManagerRefresh</productId>
</entry>
<entry>
    <productId>ServiceBus_1_1_TLS_1_2</productId>
</entry>
<entry>
    <productId>WorkflowCU5</productId>
</entry>
<entry>
    <productId>WorkflowClientCU4</productId>
</entry>
</feed>
"@
                    return $content
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process -Times 3
                }
            }
            Context "Workflow Manager is not installed, but should be and using UNC path" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "\\server\Install\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "\\server\InstallWFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-Item -MockWith {
                    return $null
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager Client is not installed, but should be" {
                $testParams = @{
                    Ensure              = "Present"
                    WebPIPath           = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath         = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                    ComponentsToInstall = "ClientOnly"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager Client CU4 is not installed, but should be" {
                $testParams = @{
                    Ensure              = "Present"
                    WebPIPath           = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath         = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                    ComponentsToInstall = "ClientOnly"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManagerRefresh</productId>
</entry>
<entry>
    <productId>ServiceBus_1_1_TLS_1_2</productId>
</entry>
<entry>
    <productId>WorkflowCU5</productId>
</entry>
<entry>
    <productId>WorkflowClientCU4</productId>
</entry>
</feed>
"@
                    return $content
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager Client is not installed, but should be and using UNC path" {
                $testParams = @{
                    Ensure              = "Present"
                    WebPIPath           = "\\server\Install\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath         = "\\server\Install\WFFiles\Feeds\Latest\webproductlist.xml"
                    ComponentsToInstall = "ClientOnly"
                }

                Mock -CommandName Get-Item -MockWith {
                    return $null
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                It "Returns that it is not installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Starts the install from the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context "Workflow Manager is installed and should be" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock Get-ChildItem -MockWith {
                    return @(
                        @{
                            Name = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Workflow Manager\1.0"
                        }
                    )
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Returns that it is installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "Workflow Manager Client is installed and should be" {
                $testParams = @{
                    Ensure              = "Present"
                    WebPIPath           = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath         = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                    ComponentsToInstall = "ClientOnly"
                }

                Mock Get-ChildItem -MockWith {
                    return @(
                        @{
                            Name = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Workflow Manager Client\1.0"
                        }
                    )
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                It "Returns that it is installed from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context "Invalid path for installer was passed" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                It "Should throw an error about invalid path for the Web Platform Installer in the Get method" {
                    { Get-TargetResource @testParams } | Should throw "The specified path for the Web Platform Installer does not exist."
                }

                It "Should throw an error about invalid path for the Web Platform Installer in the Set method" {
                    { Set-TargetResource @testParams } | Should throw "The specified path for the Web Platform Installer does not exist."
                }
            }

            Context "Invalid path for the XML was passed" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Test-Path -MockWith {
                    return $false
                } -ParameterFilter { $Path -eq $testParams.XMLFeedPath }

                It "Should throw an error about invalid path for the XML feed in the Get method" {
                    { Get-TargetResource @testParams } | Should throw "The specified path for the XML Feed does not exist."
                }

                It "Should throw an error about invalid path for the XML feed in the Set method" {
                    { Set-TargetResource @testParams } | Should throw "The specified path for the XML Feed does not exist."
                }
            }

            Context "Trying to uninstall the product" {
                $testParams = @{
                    Ensure      = "Absent"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                It "Should throw an error that uninstall is not supported in the Get method" {
                    { Get-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }

                It "Should throw an error that uninstall is not supported in the Test method" {
                    { Test-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }

                It "Should throw an error that uninstall is not supported in the Set method" {
                    { Set-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }
            }

            Context "Setup file is blocked" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-Item -MockWith {
                    return "header"
                }

                It "Should throw an error about blocked setup in the Get method" {
                    { Get-TargetResource @testParams } | Should throw "Setup file is blocked!"
                }

                It "Should throw an error about blocked setup in the Test method" {
                    { Test-TargetResource @testParams } | Should throw "Setup file is blocked!"
                }

                It "Should throw an error about blocked setup in the Set method" {
                    { Set-TargetResource @testParams } | Should throw "Setup file is blocked!"
                }
            }

            Context "An error occured during the installation" {
                $testParams = @{
                    Ensure      = "Present"
                    WebPIPath   = "C:\WFFiles\bin\WebPICmd.exe"
                    XMLFeedPath = "C:\WFFiles\Feeds\Latest\webproductlist.xml"
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @()
                }

                Mock -CommandName Start-Process -MockWith {
                    return @{
                        ExitCode = -1
                    }
                }

                Mock -CommandName Test-Path -MockWith {
                    return $true
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    return @(1,2,3,4,5,6)
                } -ParameterFilter { $Path -eq 'C:\Program Files\Workflow Manager'}

                Mock -CommandName Get-Content -MockWith {
                    $content = @"
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
    <productId>WorkflowManager</productId>
</entry>
<entry>
    <productId>WorkflowClient</productId>
</entry>
</feed>
"@
                    return $content
                }

                It "Throws an error about a failure in the installation in the Set method" {
                    { Set-TargetResource @testParams } | Should throw "The Workflow Manager RTM installation failed. Exit code '-1' was returned."
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

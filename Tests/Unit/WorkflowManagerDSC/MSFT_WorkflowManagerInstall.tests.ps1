[CmdletBinding()]
param(
    [String] $WFCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\1.0\WorkflowManager.psm1" -Resolve)
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
            Context "Workflow Manager is not installed, but should be" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
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
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
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

            Context "Invalid path for installer was passed" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                It "Should throw an error about invalid path for the Web Platform Installer" {
                    { Get-TargetResource @testParams } | Should throw "The specified path for the Web Platform Installer does not exist."
                }
            }

            Context "Invalid path for the XML was passed" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    if($Global:MethodCalledCount -eq 0)
                    {
                        $Global:MethodCalledCount++
                        return $true
                    }
                    else
                    {
                        return $false
                    }
                }

                It "Should throw an error about invalid path for the XML feed" {
                    { Get-TargetResource @testParams } | Should throw "The specified path for the XML Feed does not exist."
                }
            }

            Context "Trying to uninstall the product" {
                $testParams = @{
                    Ensure = "Absent"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
                }

                Mock -CommandName Test-Path -MockWith {
                    return $false
                }

                It "Should throw an error about invalid paths" {
                    { Get-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }

                It "Should throw an error about invalid paths" {
                    { Test-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }

                It "Should throw an error about invalid paths" {
                    { Set-TargetResource @testParams } | Should throw "Uninstallation is not supported by Workflow Manager DSC"
                }
            }

            Context "An error occured during the installation" {
                $testParams = @{
                    Ensure = "Present"
                    WebPIPath = "C:/WFFiles/bin/WebPICmd.exe"
                    XMLFeedPath = "C:/WFFiles/Feeds/Latest/webproductlist.xml"
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

                It "Throws an error about a failure in the installation" {
                    { Set-TargetResource @testParams } | Should throw "The Workflow Manager installation failed. Exit code '-1' was returned."
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

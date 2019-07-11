[CmdletBinding()]
param(
    [String] $WFCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\1.0\WorkflowManager.psm1" -Resolve)
)

$Script:DSCModuleName      = 'WorkflowManagerDsc'
$Script:DSCResourceName    = 'MSFT_WorkflowManagerFarm'
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
        Describe "WorkflowManagerFarm [WF server version $((Get-Item $Global:CurrentWFCmdletModule).Directory.BaseName)]" {

            $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
            $mockFarmAccount = New-Object -TypeName "System.Management.Automation.PSCredential" `
                                          -ArgumentList @("username", $mockPassword)

            Import-Module (Join-Path $PSScriptRoot "..\..\..\Modules\WorkflowManagerDsc" -Resolve)
            #Remove-Module -Name "WorkflowManager" -Force -ErrorAction SilentlyContinue
            Import-Module $Global:CurrentWFCmdletModule -WarningAction SilentlyContinue

            Mock -CommandName Remove-WFHost -MockWith {
                return @()
            }

            Mock -CommandName Remove-SBHost -MockWith {
                return @()
            }

            Context "Workflow Manager farm is not configured, and should not be" {
                $testParams = @{
                    Ensure                = "Absent"
                    DatabaseServer        = "localhost"
                    CertAutoGenerationKey = $mockFarmAccount
                    RunAsAccount          = $mockFarmAccount
                    SBNamespace           = "ServiceBus"
                }

                Mock -CommandName Get-WFFarm -MockWith {
                    throw "Farm does not exist"
                }

                It "Properly removes the current server from the Farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SBHost
                    Assert-MockCalled Remove-WFHost
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }

                It "Returns an empty database connection string" {
                    (Get-TargetResource @testParams).DatabaseServer | Should be $null
                }
            }

            Context "Workflow Manager farm is not configured, and should be without allowing HTTP" {
                $testParams = @{
                    Ensure                = "Present"
                    DatabaseServer        = "localhost"
                    CertAutoGenerationKey = $mockFarmAccount
                    RunAsAccount          = $mockFarmAccount
                    SBNamespace           = "ServiceBus"
                }

                Mock -CommandName Get-WFFarm -MockWith {
                    throw "Farm does not exist"
                }

                Mock -CommandName New-SBFarm -MockWith {
                    return $null
                }

                Mock -CommandName Add-SBHost -MockWith {
                    return $null
                }

                Mock -CommandName New-SBNamespace -MockWith {
                    return $null
                }

                Mock -CommandName New-WFFarm -MockWith {
                    return $null
                }

                Mock -CommandName Get-SBClientConfiguration -MockWith {
                    return @()
                }

                Mock -CommandName Add-WFHost -MockWith {
                    return $null
                }

                It "Properly configures the current server from the Farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SBFarm
                    Assert-MockCalled Add-SBHost
                    Assert-MockCalled New-SBNamespace
                    Assert-MockCalled New-WFFarm
                    Assert-MockCalled Get-SBClientConfiguration
                    Assert-MockCalled Add-WFHost
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Returns an empty database connection string" {
                    (Get-TargetResource @testParams).DatabaseServer | Should be $null
                }
            }

            Context "Workflow Manager farm is not configured, and should be while allowing HTTP" {
                $testParams = @{
                    Ensure                = "Present"
                    DatabaseServer        = "localhost"
                    CertAutoGenerationKey = $mockFarmAccount
                    RunAsAccount          = $mockFarmAccount
                    EnableHttpPort        = $true
                    SBNamespace           = "ServiceBus"
                }

                Mock -CommandName Get-WFFarm -MockWith {
                    throw "Farm does not exist"
                }

                Mock -CommandName New-SBFarm -MockWith {
                    return $null
                }

                Mock -CommandName Add-SBHost -MockWith {
                    return $null
                }

                Mock -CommandName New-SBNamespace -MockWith {
                    return $null
                }

                Mock -CommandName New-WFFarm -MockWith {
                    return $null
                }

                Mock -CommandName Get-SBClientConfiguration -MockWith {
                    return @()
                }

                Mock -CommandName Add-WFHost -MockWith {
                    return $null
                }

                It "Properly configures the current server from the Farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SBFarm
                    Assert-MockCalled Add-SBHost
                    Assert-MockCalled New-SBNamespace
                    Assert-MockCalled New-WFFarm
                    Assert-MockCalled Get-SBClientConfiguration
                    Assert-MockCalled Add-WFHost
                }

                It "Returns false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Returns an empty database connection string" {
                    (Get-TargetResource @testParams).DatabaseServer | Should be $null
                }
            }

            Context "Workflow Manager farm is already configured, and should be" {
                $testParams = @{
                    Ensure                = "Present"
                    DatabaseServer        = "localhost"
                    CertAutoGenerationKey = $mockFarmAccount
                    RunAsAccount          = $mockFarmAccount
                    EnableHttpPort        = $true
                    SBNamespace           = "ServiceBus"
                }

                Mock -CommandName Get-WFFarm -MockWith {
                    return @{
                        WFFarmDBConnectionString   = 'Data Source=localhost;Initial Catalog=WFManagementDB;Integrated Security=True;Encrypt=False'
                        InstanceDBConnectionString = 'Data Source=localhost;Initial Catalog=WFInstanceManagementDB;Integrated Security=True;Encrypt=False'
                        ResourceDBConnectionString = 'Data Source=localhost;Initial Catalog=WFResourceManagementDB;Integrated Security=True;Encrypt=False'
                    }
                }

                Mock -CommandName Get-SBFarm -MockWith {
                    return @{
                        SBFarmDBConnectionString  = 'Data Source=localhost;Initial Catalog=SBManagementDB;Integrated Security=True;Encrypt=False'
                        GatewayDBConnectionString = 'Data Source=localhost;Initial Catalog=SBGatewayDatabase;Integrated Security=True;Encrypt=False'
                    }
                }

                Mock -CommandName Get-SBMessageContainer -MockWith {
                    return @{
                        ConnectionString = 'Data Source=localhost;Initial Catalog=SBMessageContainer01;Integrated Security=True;Encrypt=False'
                    }
                }

                It "Returns true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }

                It "Returns the correct database connection string" {
                    (Get-TargetResource @testParams).DatabaseServer | Should be "localhost"
                }
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

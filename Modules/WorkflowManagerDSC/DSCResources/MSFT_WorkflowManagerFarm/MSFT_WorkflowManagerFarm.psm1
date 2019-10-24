Import-Module ServiceBus -ErrorAction SilentlyContinue
Import-Module WorkflowManager -ErrorAction SilentlyContinue

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
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsAccount,

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusFarmDB = "SBManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusGatewayDB = "SBGatewayDatabase",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusMessageContainerDB = "SBMessageContainer01",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerFarmDB = "WFManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerInstanceDB = "WFInstanceManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerResourceDB = "WFResourceManagementDB",

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )

    Write-Verbose -Message "Getting settings for Workflow Manager farm"

    Confirm-WmfDscEnvironmentVariables

    $result = @{}
    try
    {
        $WFFarm = Get-WFFarm
        $SBNamespace = Get-SBNamespace | Select-Object -First 1

        if ($WFFarm.WFFarmDBConnectionString -match 'Initial Catalog=(.*?);')
        {
            $WFFarmDB = $Matches[1]
        }

        if ($WFFarm.WFFarmDBConnectionString -match 'Data Source=(.*?);')
        {
            $dbServer = $Matches[1]
        }

        if ($WFFarm.InstanceDBConnectionString -match 'Initial Catalog=(.*?);')
        {
            $WFInstanceDB = $Matches[1]
        }

        if ($WFFarm.ResourceDBConnectionString -match 'Initial Catalog=(.*?);')
        {
            $WFResourceDB = $Matches[1]
        }

        $SBFarm = Get-SBFarm
        if ($SBFarm.SBFarmDBConnectionString -match 'Initial Catalog=(.*?);')
        {
            $SBFarmDB = $Matches[1]
        }

        if ($SBFarm.GatewayDBConnectionString -match 'Initial Catalog=(.*?);')
        {
            $SBGatewayDB = $Matches[1]
        }

        $SBMessageContainer = Get-SBMessageContainer
        if ($SBMessageContainer.ConnectionString -match 'Initial Catalog=(.*?);')
        {
            $SBMessageContainerDB = $Matches[1]
        }

        $result = @{
            Ensure                       = "Present"
            DatabaseServer               = $dbServer
            CertAutoGenerationKey        = $CertAutoGenerationKey
            FarmAccount                  = $FarmAccount
            RunAsPassword                = $RunAsPassword
            ServiceBusFarmDB             = $SBFarmDB
            ServiceBusGatewayDB          = $SBGatewayDB
            ServiceBusMessageContainerDB = $SBMessageContainerDB
            WorkflowManagerFarmDB        = $WFFarmDB
            WorkflowManagerInstanceDB    = $WFInstanceDB
            WorkflowManagerResourceDB    = $WFResourceDB
            EnableFirewallRules          = $EnableFirewallRules
            EnableHttpPort               = $EnableHttpPort
            SBNamespace                  = $SBNamespace.Name
        }
    }
    catch
    {
        $result = @{
            Ensure                       = "Absent"
            DatabaseServer               = $null
            CertAutoGenerationKey        = $null
            FarmAccount                  = $null
            RunAsPassword                = $null
            ServiceBusFarmDB             = $null
            ServiceBusGatewayDB          = $null
            ServiceBusMessageContainerDB = $null
            WorkflowManagerFarmDB        = $null
            WorkflowManagerInstanceDB    = $null
            WorkflowManagerResourceDB    = $null
            EnableFirewallRules          = $null
            EnableHttpPort               = $null
            SBNamespace                  = $null
        }
    }

    return $result
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
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsAccount,

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusFarmDB = "SBManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusGatewayDB = "SBGatewayDatabase",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusMessageContainerDB = "SBMessageContainer01",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerFarmDB = "WFManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerInstanceDB = "WFInstanceManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerResourceDB = "WFResourceManagementDB",

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )

    Write-Verbose -Message "Updating settings for Workflow Manager farm"

    Confirm-WmfDscEnvironmentVariables

    if ($Ensure.ToLower() -eq "present")
    {
        $SBFADBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$ServiceBusFarmDB
        $SBGWDBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$ServiceBusGatewayDB
        $SBMCDBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$ServiceBusMessageContainerDB

        New-SBFarm -SBFarmDBConnectionString $SBFADBConnstring `
                   -GatewayDBConnectionString $SBGWDBConnstring `
                   -MessageContainerDBConnectionString $SBMCDBConnstring `
                   -RunAsAccount $RunAsAccount.UserName `
                   -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

        Add-SBHost -SBFarmDBConnectionString $SBFADBConnstring `
                   -RunAsPassword $RunAsAccount.Password `
                   -EnableFirewallRules $EnableFirewallRules `
                   -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

        New-SBNamespace -Name $SBNamespace `
                        -AddressingScheme 'Path' `
                        -ManageUsers $RunAsAccount.UserName

        $WFFADBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$WorkflowManagerFarmDB
        $WFINDBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$WorkflowManagerInstanceDB
        $WFREDBConnstring = "Data Source={0};Initial Catalog={1};Integrated Security=True;Encrypt=False" -f $DatabaseServer,$WorkflowManagerResourceDB

        New-WFFarm -WFFarmDBConnectionString $WFFADBConnstring `
                   -InstanceDBConnectionString $WFINDBConnstring `
                   -ResourceDBConnectionString $WFREDBConnstring `
                   -RunAsAccount $RunAsAccount.UserName `
                   -EnableHttpPort $EnableHttpPort `
                   -CertificateAutoGenerationKey $CertAutoGenerationKey.Password

        $SBConfig = Get-SBClientConfiguration -Namespaces $SBNamespace

        if ($EnableHttpPort)
        {
            Add-WFHost -WFFarmDBConnectionString $WFFADBConnstring `
                       -RunAsPassword $RunAsAccount.Password `
                       -EnableFirewallRules $EnableFirewallRules `
                       -CertificateAutoGenerationKey $CertAutoGenerationKey.Password `
                       -SBClientConfiguration $SBConfig `
                       -EnableHttpPort
        }
        else
        {
            Add-WFHost -WFFarmDBConnectionString $WFFADBConnstring `
                       -RunAsPassword $RunAsAccount.Password `
                       -EnableFirewallRules $EnableFirewallRules `
                       -CertificateAutoGenerationKey $CertAutoGenerationKey.Password `
                       -SBClientConfiguration $SBConfig
        }
    }
    else
    {
        Write-Verbose -Message "Removing the current server from the Workflow Farm"
        Remove-SBHost
        Remove-WFHost
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
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $CertAutoGenerationKey,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $RunAsAccount,

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusFarmDB = "SBManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusGatewayDB = "SBGatewayDatabase",

        [parameter(Mandatory = $false)]
        [System.String]
        $ServiceBusMessageContainerDB = "SBMessageContainer01",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerFarmDB = "WFManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerInstanceDB = "WFInstanceManagementDB",

        [parameter(Mandatory = $false)]
        [System.String]
        $WorkflowManagerResourceDB = "WFResourceManagementDB",

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableFirewallRules = $false,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $EnableHttpPort = $false,

        [parameter(Mandatory = $false)]
        [System.String]
        $SBNamespace = "ServiceBus"
    )

    Write-Verbose -Message "Testing settings of Workflow Manager farm"

    Confirm-WmfDscEnvironmentVariables

    $result = Get-TargetResource @PSBoundParameters

    return ($result.Ensure -eq $Ensure)
}

Export-ModuleMember -Function *-TargetResource

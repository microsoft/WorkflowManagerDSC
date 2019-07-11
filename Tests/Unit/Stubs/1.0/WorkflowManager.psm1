function Get-WFFarm {
  [CmdletBinding()]
param()


 }

 function Get-SBFarm {
  [CmdletBinding()]
param()


 }

 function Get-SBMessageContainer {
  [CmdletBinding()]
param()


 }

function Get-SBNamespace {
  [CmdletBinding()]
param()


 }

function Get-SBClientConfiguration {
  [CmdletBinding()]
param(
  [array]
  ${Namespaces}
)


}

function Remove-SBHost {
  [CmdletBinding()]
param()


}

function Remove-WFHost {
  [CmdletBinding()]
param()


}

function New-SBFarm {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${SBFarmDBConnectionString},

    [string]
    ${GatewayDBConnectionString},

    [string]
    ${MessageContainerDBConnectionString},

    [string]
    ${RunAsAccount},

    [System.Security.SecureString]
    ${CertificateAutoGenerationKey}
)
}

function Add-SBHost {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${SBFarmDBConnectionString},

    [System.Security.SecureString]
    ${RunAsPassword},

    [System.Boolean]
    ${EnableFirewallRules},

    [System.Security.SecureString]
    ${CertificateAutoGenerationKey}
)
}

function New-SBNamespace {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Name},

    [string]
    ${AddressingScheme},

    [array]
    ${ManageUsers}
)
}

function New-WFFarm {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${WFFarmDBConnectionString},

    [string]
    ${InstanceDBConnectionString},

    [string]
    ${ResourceDBConnectionString},

    [string]
    ${RunAsAccount},

    [System.Security.SecureString]
    ${CertificateAutoGenerationKey}
)
}

function Add-WFHost {
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${WFFarmDBConnectionString},

    [System.Security.SecureString]
    ${RunAsPassword},

    [System.Boolean]
    ${EnableFirewallRules},

    [switch]
    ${EnableHttpPort},

    [System.Security.SecureString]
    ${CertificateAutoGenerationKey},

    [object]
    ${SBClientConfiguration}
)
}

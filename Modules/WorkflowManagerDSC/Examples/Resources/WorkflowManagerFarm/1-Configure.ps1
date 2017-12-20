<#
.EXAMPLE
    This example shows how to configure a Workflow Manager farm on a server.
#>

    Configuration Example 
    {
        param()

        Import-DscResource -ModuleName WorkflowManagerDSC

        $SetupAccount = Get-Credential
        WorkflowManagerFarm FarmConfig
        {
            Ensure = "Present"
            DatabaseServer = "localhost"
            CertAutoGenerationKey = $SetupAccount
            RunAsPassword = $SetupAccount
            FarmAccount = $SetupAccount
            SBNamespace = "ServiceBus"
            PsDscRunAsCredential = $SetupAccount
        }
    }
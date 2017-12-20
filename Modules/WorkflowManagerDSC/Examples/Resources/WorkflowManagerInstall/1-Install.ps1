<#
.EXAMPLE
    This example shows how to install Workflow Manager on a server.
#>

    Configuration Example 
    {
        param()

        Import-DscResource -ModuleName WorkflowManagerDSC

        $SetupAccount = Get-Credential
        WorkflowManagerinstall WFInstall
        {  
            Ensure = "Present"
            WebPIPath = "C:/WorkflowManagerFiles/bin/WebpiCmd.exe"
            XMLFeedPath = "C:/WorkflowManagerFiles/feeds/latest/webproductlist.xml"
            PsDscRunAsCredential = $SetupAccount
        }
    }
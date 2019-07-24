# Description

The WorkflowManagerInstall DSC resource is used to manage the installation
of the main binaries used for the Workflow Manager using the Web Platform
Installer to perform an Offline Installation.

Currently the only supported scenario is installation of the binaries, this
resource doesn't allow them to be uninstalled.

This resource is able to install the RTM and Refresh packages of Workflow
Manager. Just download the correct packages using the below commands.

More information:
Workflow Manager Offline Install: https://docs.microsoft.com/en-us/previous-versions/dotnet/workflow-manager/jj906604%28v%3dazure.10%29
WebPI download: https://docs.microsoft.com/en-us/iis/install/web-platform-installer/web-platform-installer-v4-command-line-webpicmdexe-rtw-release

## Commands to download Workflow Manager and required components

Workflow Manager RTM

```Script
webpicmd /offline /Products:WorkflowManager /Path:c:\WorkflowManagerFiles
```

Workflow Manager Refresh

```Script
webpicmd /offline /Products:WorkflowManagerRefresh /Path:c:\WorkflowManagerFiles
```

Service Bus v1.1 incl TLS 1.2 update

```Script
webpicmd /offline /Products:ServiceBus_1_1_TLS_1_2 /Path:c:\WorkflowManagerFiles
```

Workflow Manager CU5

```Script
webpicmd /offline /Products:WorkflowCU5 /Path:c:\WorkflowManagerFiles
```

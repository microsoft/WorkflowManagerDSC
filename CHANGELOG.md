# Change log for WorkflowManagerDsc

## Unreleased

* WorkflowManagerInstall
  * Added ability to install Workflow Manager Refresh package (including
    CU4), CU5 and Service Bus v1.1 with TLS 1.2 update.

## 1.2.0.1

* WorkflowManagerFarm
  * Corrected small issue in schema that was added during previous change.

## 1.2

* WorkflowManagerFarm
  * Added ability to specify custom database names
  * Corrected cmdlet parameters to make sure the farm is actually using
    the specified credentials

## 1.1.0.1

* WorkflowManagerFarm
  * Updated resource to make sure the Windows Environment
    variables are loaded into the PowerShell session
  * Fixed typo in Get method where it returned an incorrectly
    named property

## 1.1

* WorkflowManagerInstall
  * Added ability to install the Workflow Manager Client only
  * Added check to unblock setup file if it is blocked because it is coming
    from a network location. This to prevent endless wait
  * Added ability to install from a UNC path, by adding server
    to IE Local Intranet Zone. This will prevent an endless wait
    caused by security warning

## 1.0

* Initial Release;

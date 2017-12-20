function Invoke-WFDscUnitTestSuite() {
    param
    (
        [parameter(Mandatory = $false)] [System.String]  $TestResultsFile,
        [parameter(Mandatory = $false)] [System.String]  $DscTestsPath,
        [parameter(Mandatory = $false)] [System.Boolean] $CalculateTestCoverage = $true
    )

    Write-Verbose -Message "Commencing WorkflowManagerDsc unit tests"

    $repoDir = Join-Path $PSScriptRoot "..\..\" -Resolve

    $testCoverageFiles = @()
    if ($CalculateTestCoverage -eq $true) {
        Write-Warning -Message ("Code coverage statistics are being calculated. This will slow the " + `
                                "start of the tests by several minutes while the code matrix is " + `
                                "built. Please be patient")
        Get-ChildItem "$repoDir\modules\WorkflowManagerDsc\**\*.psm1" -Recurse | ForEach-Object { 
            if ($_.FullName -notlike "*\DSCResource.Tests\*") {
                $testCoverageFiles += $_.FullName    
            }
        }    
    }
    

    $testResultSettings = @{ }
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) {
        $testResultSettings.Add("OutputFormat", "NUnitXml" )
        $testResultSettings.Add("OutputFile", $TestResultsFile)
    }
    Import-Module "$repoDir\modules\WorkflowManagerDsc\WorkflowManagerDsc.psd1"
    
    
    $versionsToTest = (Get-ChildItem (Join-Path $repoDir "\Tests\Unit\Stubs\")).Name
    
    # Import the first stub found so that there is a base module loaded before the tests start
    $firstVersion = $versionsToTest | Select-Object -First 1
    Import-Module (Join-Path $repoDir "\Tests\Unit\Stubs\$firstVersion\WorkflowManager.psm1") -WarningAction SilentlyContinue

    $testsToRun = @()
    $versionsToTest | ForEach-Object {
        $testsToRun += @(@{
            'Path' = (Join-Path -Path $repoDir -ChildPath "\Tests\Unit")
            'Parameters' = @{ 
                'WACCmdletModule' = (Join-Path $repoDir "\Tests\Unit\Stubs\$_\WorkflowManager.psm1")
            }
        })
    }
    
    if ($PSBoundParameters.ContainsKey("DscTestsPath") -eq $true) {
        $testsToRun += @{
            'Path' = $DscTestsPath
            'Parameters' = @{ }
        }
    }
    $previousVerbosePreference = $Global:VerbosePreference 
    try {
        $Global:VerbosePreference = "SilentlyContinue"
        $results = Invoke-Pester -Script $testsToRun -CodeCoverage $testCoverageFiles -PassThru @testResultSettings    
    }
    finally {
        $Global:VerbosePreference = $previousVerbosePreference
    }
    
    return $results
}

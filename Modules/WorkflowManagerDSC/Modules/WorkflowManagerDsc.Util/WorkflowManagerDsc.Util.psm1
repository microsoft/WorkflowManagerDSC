<#
.SYNOPSIS

This cmdlet checks if all environment variables are loaded into the PSModulePath
variable.

#>
function Confirm-WmfDscEnvironmentVariables
{
    [CmdletBinding()]
    [OutputType()]
    param()

    $envPSMod = [Environment]::GetEnvironmentVariable("PSModulePath","Machine") -split ";"
    $curPsMod = $env:PSModulePath -split ";"
    foreach ($path in $envPSMod)
    {
        if ($curPSMod -notcontains $path)
        {
            $env:PSModulePath = $env:PSModulePath + ";$path"
        }
    }
}

<#
.SYNOPSIS

This cmdlet determines the version number of Office Web Apps that is installed locally

#>
function Get-WmfDscInstalledProductVersion
{
    [CmdletBinding()]
    [OutputType([Version])]
    param()

    return Get-ItemProperty 'HKLM:\Software\Microsoft\Workflow Manager\*' | `
        Select-Object Version | `
        ForEach-Object -Process {
            return [Version]::Parse($_.Version)
        } | Select-Object -First 1
}

<#
.SYNOPSIS

This method is used remove a server name to the IE Local Intranet Zone.

.PARAMETER ServerName

This specifies the server that needs to be removed from the zone

#>
function Remove-WMDscZoneMap
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]
        $ServerName
    )

    $zoneMap = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap"

    $escDomainsPath = Join-Path -Path $zoneMap -ChildPath "\EscDomains\$ServerName"
    if (Test-Path -Path $escDomainsPath)
    {
        Remove-Item -Path $escDomainsPath
    }

    $domainsPath = Join-Path -Path $zoneMap -ChildPath "\Domains\$ServerName"
    if (Test-Path -Path $domainsPath)
    {
        Remove-Item -Path $domainsPath
    }
}

<#
.SYNOPSIS

This method is used add a server name to the IE Local Intranet Zone.
This to prevent a security message when Start-Process is called for
an UNC path.

.PARAMETER ServerName

This specifies the server that needs to be added to the zone

#>
function Set-WMDscZoneMap
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]
        $ServerName
    )

    $zoneMap = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap"

    $escDomainsPath = Join-Path -Path $zoneMap -ChildPath "\EscDomains\$ServerName"
    if (-not (Test-Path -Path $escDomainsPath))
    {
        $null = New-Item -Path $escDomainsPath -Force
    }

    if ((Get-ItemProperty -Path $escDomainsPath).File -ne 1)
    {
        Set-ItemProperty -Path $escDomainsPath -Name file -Value 1 -Type DWord
    }

    $domainsPath = Join-Path -Path $zoneMap -ChildPath "\Domains\$ServerName"
    if (-not (Test-Path -Path $domainsPath))
    {
        $null = New-Item -Path $domainsPath -Force
    }

    if ((Get-ItemProperty -Path $domainsPath).File -ne 1)
    {
        Set-ItemProperty -Path $domainsPath -Name file -Value 1 -Type DWord
    }
}

<#
.SYNOPSIS

This method is used to compare current and desired values for any DSC resource

.PARAMETER CurrentValues

This is hashtable of the current values that are applied to the resource

.PARAMETER DesiredValues

This is a PSBoundParametersDictionary of the desired values for the resource

.PARAMETER ValuesToCheck

This is a list of which properties in the desired values list should be checkked.
If this is empty then all values in DesiredValues are checked.

#>
function Test-WFDscParameterState() {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true, Position=1)]
        [HashTable]
        $CurrentValues,

        [parameter(Mandatory = $true, Position=2)]
        [Object]
        $DesiredValues,

        [parameter(Mandatory = $false, Position=3)]
        [Array]
        $ValuesToCheck
    )

    $returnValue = $true

    if (($DesiredValues.GetType().Name -ne "HashTable") `
        -and ($DesiredValues.GetType().Name -ne "CimInstance") `
        -and ($DesiredValues.GetType().Name -ne "PSBoundParametersDictionary"))
    {
        throw ("Property 'DesiredValues' in Test-SPDscParameterState must be either a " + `
               "Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if (($DesiredValues.GetType().Name -eq "CimInstance") -and ($null -eq $ValuesToCheck))
    {
        throw ("If 'DesiredValues' is a Hashtable then property 'ValuesToCheck' must contain " + `
               "a value")
    }

    if (($null -eq $ValuesToCheck) -or ($ValuesToCheck.Count -lt 1))
    {
        $KeyList = $DesiredValues.Keys
    }
    else
    {
        $KeyList = $ValuesToCheck
    }

    $KeyList | ForEach-Object -Process {
        if ($_ -ne "Verbose")
        {
            if (($CurrentValues.ContainsKey($_) -eq $false) `
            -or ($CurrentValues.$_ -ne $DesiredValues.$_) `
            -or (($DesiredValues.ContainsKey($_) -eq $true) -and ($DesiredValues.$_.GetType().IsArray)))
            {
                if ($DesiredValues.GetType().Name -eq "HashTable" -or `
                    $DesiredValues.GetType().Name -eq "PSBoundParametersDictionary")
                {
                    $CheckDesiredValue = $DesiredValues.ContainsKey($_)
                }
                else
                {
                    $CheckDesiredValue = Test-WFDSCObjectHasProperty $DesiredValues $_
                }

                if ($CheckDesiredValue)
                {
                    $desiredType = $DesiredValues.$_.GetType()
                    $fieldName = $_
                    if ($desiredType.IsArray -eq $true)
                    {
                        if (($CurrentValues.ContainsKey($fieldName) -eq $false) `
                        -or ($null -eq $CurrentValues.$fieldName))
                        {
                            Write-Verbose -Message ("Expected to find an array value for " + `
                                                    "property $fieldName in the current " + `
                                                    "values, but it was either not present or " + `
                                                    "was null. This has caused the test method " + `
                                                    "to return false.")
                            $returnValue = $false
                        }
                        else
                        {
                            $arrayCompare = Compare-Object -ReferenceObject $CurrentValues.$fieldName `
                                                           -DifferenceObject $DesiredValues.$fieldName
                            if ($null -ne $arrayCompare)
                            {
                                Write-Verbose -Message ("Found an array for property $fieldName " + `
                                                        "in the current values, but this array " + `
                                                        "does not match the desired state. " + `
                                                        "Details of the changes are below.")
                                $arrayCompare | ForEach-Object -Process {
                                    Write-Verbose -Message "$($_.InputObject) - $($_.SideIndicator)"
                                }
                                $returnValue = $false
                            }
                        }
                    }
                    else
                    {
                        switch ($desiredType.Name)
                        {
                            "String" {
                                if ([string]::IsNullOrEmpty($CurrentValues.$fieldName) `
                                -and [string]::IsNullOrEmpty($DesiredValues.$fieldName))
                                {}
                                else
                                {
                                    Write-Verbose -Message ("String value for property " + `
                                                            "$fieldName does not match. " + `
                                                            "Current state is " + `
                                                            "'$($CurrentValues.$fieldName)' " + `
                                                            "and desired state is " + `
                                                            "'$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            "Int32" {
                                if (($DesiredValues.$fieldName -eq 0) `
                                -and ($null -eq $CurrentValues.$fieldName))
                                {}
                                else
                                {
                                    Write-Verbose -Message ("Int32 value for property " + `
                                                            "$fieldName does not match. " + `
                                                            "Current state is " + `
                                                            "'$($CurrentValues.$fieldName)' " + `
                                                            "and desired state is " + `
                                                            "'$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            "Int16" {
                                if (($DesiredValues.$fieldName -eq 0) `
                                -and ($null -eq $CurrentValues.$fieldName))
                                {}
                                else
                                {
                                    Write-Verbose -Message ("Int16 value for property " + `
                                                            "$fieldName does not match. " + `
                                                            "Current state is " + `
                                                            "'$($CurrentValues.$fieldName)' " + `
                                                            "and desired state is " + `
                                                            "'$($DesiredValues.$fieldName)'")
                                    $returnValue = $false
                                }
                            }
                            default {
                                Write-Verbose -Message ("Unable to compare property $fieldName " + `
                                                        "as the type ($($desiredType.Name)) is " + `
                                                        "not handled by the " + `
                                                        "Test-WFDscParameterState cmdlet")
                                $returnValue = $false
                            }
                        }
                    }
                }
            }
        }
    }
    return $returnValue
}

function Test-WFDSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true,Position=1)]
        [Object]
        $Object,

        [Parameter(Mandatory = $true,Position=2)]
        [String]
        $PropertyName
    )

    if (([bool]($Object.PSobject.Properties.name -contains $PropertyName)) -eq $true)
    {
        if ($null -ne $Object.$PropertyName)
        {
            return $true
        }
    }
    return $false
}

Export-ModuleMember -Function *

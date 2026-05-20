function Set-GroupPolicyConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'HashTable')]
        [ValidateNotNullOrEmpty()]
        [hashtable]$PolicySettings,

        [Parameter(ParameterSetName = 'JsonFile')]
        [ValidateNotNullOrEmpty()]
        [string]$JsonPath,

        [Parameter()]
        [switch]$OfflineRegistry,

        [Parameter()]
        [switch]$SkipAppLocker,

        [Parameter()]
        [switch]$SkipADMX
    )
    
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    
    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Setting Group Policy Configuration..."

    $combinedPolicies = @{}
    $appLockerRules = $null
    $admxPolicies = @{}

    if ($JsonPath) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Loading policies from JSON file: $JsonPath"
        
        if (-not (Test-Path -Path $JsonPath -ErrorAction SilentlyContinue)) {
            Write-Error "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] JSON file not found: $JsonPath"
            return
        }

        try {
            $jsonContent = Get-Content -Path $JsonPath -Raw -ErrorAction Stop
            $jsonPolicies = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            
            if ($null -eq $jsonPolicies) {
                Write-Error "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] JSON file is empty or invalid: $JsonPath"
                return
            }

            $jsonHashtable = @{}
            foreach ($key in $jsonPolicies.PSObject.Properties.Name) {
                $value = $jsonPolicies.$key
                
                # Extract AppLocker rules if present
                if ($key -eq 'AppLockerRules') {
                    $appLockerRules = $value
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found AppLocker rules in JSON"
                    continue
                }
                
                # Extract ADMX policies if present
                if ($key -eq 'ADMXPolicies') {
                    if ($value -is [System.Management.Automation.PSCustomObject]) {
                        foreach ($admxKey in $value.PSObject.Properties.Name) {
                            $admxPolicies[$admxKey] = $value.$admxKey
                        }
                    }
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $($admxPolicies.Count) ADMX policies in JSON"
                    continue
                }
                
                # Process standard registry policies (backward compatibility)
                if ($value -is [System.Management.Automation.PSCustomObject]) {
                    $nestedHashtable = @{}
                    foreach ($nestedKey in $value.PSObject.Properties.Name) {
                        $nestedValue = $value.$nestedKey
                        
                        if ($nestedValue -is [System.Management.Automation.PSCustomObject]) {
                            $deepHashtable = @{}
                            foreach ($deepKey in $nestedValue.PSObject.Properties.Name) {
                                $deepHashtable[$deepKey] = $nestedValue.$deepKey
                            }
                            $nestedHashtable[$nestedKey] = $deepHashtable
                        } else {
                            $nestedHashtable[$nestedKey] = $nestedValue
                        }
                    }
                    $jsonHashtable[$key] = $nestedHashtable
                } else {
                    $jsonHashtable[$key] = $value
                }
            }
            
            $combinedPolicies = $jsonHashtable
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Loaded $($combinedPolicies.Count) policy paths from JSON file"
        } catch {
            Write-Error "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to parse JSON file: $_"
            return
        }
    }

    if ($PolicySettings) {
        foreach ($key in $PolicySettings.Keys) {
            # Skip special sections if passed via hashtable
            if ($key -in @('AppLockerRules', 'ADMXPolicies')) {
                if ($key -eq 'AppLockerRules') {
                    $appLockerRules = $PolicySettings[$key]
                } elseif ($key -eq 'ADMXPolicies') {
                    $admxPolicies = $PolicySettings[$key]
                }
                continue
            }
            
            if ($combinedPolicies.ContainsKey($key)) {
                foreach ($valueKey in $PolicySettings[$key].Keys) {
                    $combinedPolicies[$key][$valueKey] = $PolicySettings[$key][$valueKey]
                }
            } else {
                $combinedPolicies[$key] = $PolicySettings[$key]
            }
        }
    }

    $totalResults = @{
        'RegistryPolicies' = @{ Success = 0; Failed = 0 }
        'AppLockerRules' = @{ Success = 0; Failed = 0 }
        'ADMXPolicies' = @{ Success = 0; Failed = 0 }
    }

    # Process Registry Policies
    if ($combinedPolicies -and $combinedPolicies.Count -gt 0) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Processing $($combinedPolicies.Count) registry policy paths"
        
        $PolicyCount = 0
        $FailureCount = 0

        foreach ($PolicyPath in $combinedPolicies.Keys) {
            $PolicyValues = $combinedPolicies[$PolicyPath]

            if ($PolicyValues -is [hashtable]) {
                foreach ($ValueName in $PolicyValues.Keys) {
                    $ValueData = $PolicyValues[$ValueName]
                    
                    if ($ValueData -is [hashtable]) {
                        $Value = $ValueData['Value']
                        $Type = $ValueData['Type'] -as [string] ?? 'String'
                    } else {
                        $Value = $ValueData
                        $Type = 'String'
                    }

                    try {
                        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Applying: $PolicyPath\$ValueName = $Value"
                        Set-RegistryValue -Path $PolicyPath -Name $ValueName -Value $Value -PropertyType $Type -OfflineRegistry:$OfflineRegistry -ErrorAction Stop
                        $PolicyCount++
                    } catch {
                        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set policy: $PolicyPath\$ValueName - $_"
                        $FailureCount++
                    }
                }
            }
        }
        
        $totalResults['RegistryPolicies']['Success'] = $PolicyCount
        $totalResults['RegistryPolicies']['Failed'] = $FailureCount
        Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Registry Policies: $PolicyCount configured, $FailureCount failures"
    }

    # Process AppLocker Rules
    if ($appLockerRules -and -not $SkipAppLocker) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Processing AppLocker rules"
            
            if ($appLockerRules -is [System.Management.Automation.PSCustomObject]) {
                $appLockerXml = $appLockerRules | ConvertTo-Json -Depth 10
            } else {
                $appLockerXml = $appLockerRules -as [string]
            }
            
            Set-AppLockerRules -RulesXml $appLockerXml -ErrorAction Stop
            $totalResults['AppLockerRules']['Success'] = 1
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to apply AppLocker rules: $_"
            $totalResults['AppLockerRules']['Failed'] = 1
        }
    }

    # Process ADMX Policies
    if ($admxPolicies -and $admxPolicies.Count -gt 0 -and -not $SkipADMX) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Processing $($admxPolicies.Count) ADMX policies"
            Set-ADMXPolicies -PolicySettings $admxPolicies -ErrorAction Stop
            $totalResults['ADMXPolicies']['Success'] = $admxPolicies.Count
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to apply ADMX policies: $_"
            $totalResults['ADMXPolicies']['Failed'] = $admxPolicies.Count
        }
    }

    # Summary report
    Write-Host -ForegroundColor Cyan "`n[$(Get-Date -format s)] Configuration Summary:"
    foreach ($section in $totalResults.Keys) {
        if ($totalResults[$section]['Success'] -gt 0 -or $totalResults[$section]['Failed'] -gt 0) {
            $successMsg = "$($totalResults[$section]['Success']) applied"
            $failMsg = "$($totalResults[$section]['Failed']) failed"
            Write-Host "  $section : $successMsg, $failMsg"
        }
    }

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

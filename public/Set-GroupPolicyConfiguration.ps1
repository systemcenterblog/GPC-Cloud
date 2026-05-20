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
        [switch]$OfflineRegistry
    )
    
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    
    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Setting Group Policy Settings..."

    $combinedPolicies = @{}

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
            if ($combinedPolicies.ContainsKey($key)) {
                foreach ($valueKey in $PolicySettings[$key].Keys) {
                    $combinedPolicies[$key][$valueKey] = $PolicySettings[$key][$valueKey]
                }
            } else {
                $combinedPolicies[$key] = $PolicySettings[$key]
            }
        }
    }

    if (-not $combinedPolicies -or $combinedPolicies.Count -eq 0) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No policy settings provided"
        return
    }

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

    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Group Policy Settings Complete: $PolicyCount configured, $FailureCount failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

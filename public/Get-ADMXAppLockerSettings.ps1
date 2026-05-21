function Get-ADMXAppLockerSettings {
    <#
    .SYNOPSIS
    Retrieves current ADMX and AppLocker settings from the local computer and optionally exports to JSON.

    .DESCRIPTION
    This function queries the system registry for current ADMX policy settings and retrieves
    AppLocker policy rules. It returns the current configuration as a PowerShell object and
    optionally saves it to a JSON file for use with Set-GroupPolicyConfiguration.

    .PARAMETER OutputPath
    Path where the JSON file will be saved. If not specified, no file is created but the
    settings object is still returned.

    .PARAMETER IncludeADMX
    Include ADMX policy settings in the output. Default is $true.

    .PARAMETER IncludeAppLocker
    Include AppLocker rules in the output. Default is $true.

    .PARAMETER IncludeRegistry
    Include base registry policies in the output. Default is $false.
    Registry policies require scanning many registry paths and may take longer.

    .OUTPUTS
    PSCustomObject with properties:
    - ADMXPolicies: Hashtable of current ADMX policy settings
    - AppLockerRules: XML string of current AppLocker policy
    - RegistryPolicies: (optional) Hashtable of registry policies

    .EXAMPLE
    # Get current settings and return as object
    $settings = Get-ADMXAppLockerSettings
    $settings.ADMXPolicies

    .EXAMPLE
    # Get settings and save to JSON file
    Get-ADMXAppLockerSettings -OutputPath 'C:\policies\current-settings.json'

    .EXAMPLE
    # Get only AppLocker rules
    $applockerOnly = Get-ADMXAppLockerSettings -IncludeADMX $false

    .EXAMPLE
    # Get ADMX and registry policies (no AppLocker)
    $settings = Get-ADMXAppLockerSettings -IncludeAppLocker $false -IncludeRegistry $true
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [bool]$IncludeADMX = $true,

        [Parameter()]
        [bool]$IncludeAppLocker = $true,

        [Parameter()]
        [bool]$IncludeRegistry = $false
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Retrieving current ADMX and AppLocker settings..."

    $settings = @{}

    # Get ADMX Policies
    if ($IncludeADMX) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Reading ADMX policies from registry..."
        
        $admxPolicies = @{}
        
        # Define ADMX registry mappings (same as Set-ADMXPolicies)
        $ADMXRegistry = @{
            'EnableUAC' = @{
                'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                'Name' = 'EnableLUA'
            }
            'DisableAutoRun' = @{
                'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                'Name' = 'NoDriveTypeAutoRun'
            }
            'DisableCommandPrompt' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\System'
                'Name' = 'DisableCMD'
            }
            'DisableRegistryEdit' = @{
                'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                'Name' = 'DisableRegistryTools'
            }
            'RestrictRemoteDesktop' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services'
                'Name' = 'fDenyTSConnections'
            }
            'EnableWindowsDefender' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\Windows Defender'
                'Name' = 'DisableAntiSpyware'
            }
            'EnableFirewall' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
                'Name' = 'EnableFirewall'
            }
            'DisableWindowsUpdate' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
                'Name' = 'NoAutoUpdate'
            }
            'RestrictPowerShellExecution' = @{
                'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell'
                'Name' = 'EnableScripts'
            }
            'DisableUSBStorage' = @{
                'Path' = 'HKLM:\System\CurrentControlSet\Services\USBSTOR'
                'Name' = 'Start'
            }
        }

        foreach ($policyName in $ADMXRegistry.Keys) {
            try {
                $registryConfig = $ADMXRegistry[$policyName]
                $registryPath = $registryConfig['Path']
                $valueName = $registryConfig['Name']

                if (Test-Path -Path $registryPath -ErrorAction SilentlyContinue) {
                    $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName -ErrorAction SilentlyContinue
                    
                    if ($null -ne $value) {
                        $admxPolicies[$policyName] = $value
                        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $policyName = $value"
                    }
                } else {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Registry path not found for $policyName"
                }
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Error reading $policyName`: $_"
            }
        }

        $settings['ADMXPolicies'] = $admxPolicies
        Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Found $($admxPolicies.Count) ADMX policies"
    }

    # Get AppLocker Rules
    if ($IncludeAppLocker) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Reading AppLocker policy..."
        
        try {
            # Check if AppLocker cmdlets are available
            if (Get-Command -Name Get-AppLockerPolicy -ErrorAction SilentlyContinue) {
                try {
                    $appLockerPolicy = Get-AppLockerPolicy -Effective -ErrorAction SilentlyContinue
                    
                    if ($null -ne $appLockerPolicy) {
                        # Convert policy object to XML string
                        $appLockerXml = $appLockerPolicy | ConvertTo-Xml -As String -ErrorAction SilentlyContinue
                        
                        if ($null -ne $appLockerXml) {
                            $settings['AppLockerRules'] = $appLockerXml
                            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] AppLocker policy retrieved successfully"
                            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] AppLocker XML length: $($appLockerXml.Length) characters"
                        } else {
                            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to convert AppLocker policy to XML"
                        }
                    } else {
                        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No AppLocker policy found on system"
                    }
                } catch {
                    Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Error retrieving AppLocker policy`: $_"
                }
            } else {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] AppLocker cmdlets not available. Install AppLocker feature or skip with -IncludeAppLocker `$false"
            }
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Error checking AppLocker availability`: $_"
        }
    }

    # Get Registry Policies (optional, can be time-consuming)
    if ($IncludeRegistry) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Scanning for registry policies (this may take a moment)..."
        
        $registryPolicies = @{}
        $policyRootPaths = @(
            'HKLM:\Software\Policies',
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies'
        )

        foreach ($basePath in $policyRootPaths) {
            if (Test-Path -Path $basePath -ErrorAction SilentlyContinue) {
                try {
                    Get-ChildItem -Path $basePath -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        $key = $_
                        $keyPath = $key.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry::', ''
                        
                        Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
                            $properties = $_ | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notlike 'PS*' }
                            
                            foreach ($prop in $properties) {
                                $propName = $prop.Name
                                $propValue = $_.$propName
                                
                                $policyKey = "$keyPath\$propName"
                                $registryPolicies[$policyKey] = @{
                                    'Value' = $propValue
                                    'Type' = (Get-ItemProperty -Path $key.PSPath | Select-Object -ExpandProperty $propName).GetType().Name
                                }
                            }
                        }
                    }
                } catch {
                    Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Error scanning $basePath`: $_"
                }
            }
        }

        if ($registryPolicies.Count -gt 0) {
            $settings['RegistryPolicies'] = $registryPolicies
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Found $($registryPolicies.Count) registry policies"
        } else {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No registry policies found"
        }
    }

    # Create the output object
    $resultObject = [PSCustomObject]$settings
    
    # Save to JSON file if OutputPath is specified
    if ($OutputPath) {
        try {
            # Ensure output directory exists
            $outputDirectory = Split-Path -Parent $OutputPath
            if (-not (Test-Path -Path $outputDirectory -ErrorAction SilentlyContinue)) {
                $null = New-Item -ItemType Directory -Path $outputDirectory -Force -ErrorAction Stop
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Created output directory: $outputDirectory"
            }

            # Convert to JSON and save
            $jsonContent = $settings | ConvertTo-Json -Depth 10 -ErrorAction Stop
            Set-Content -Path $OutputPath -Value $jsonContent -Encoding UTF8 -Force -ErrorAction Stop
            
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Settings exported to JSON: $OutputPath"
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] JSON file size: $(Get-Item -Path $OutputPath | Select-Object -ExpandProperty Length) bytes"
        } catch {
            Write-Error "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to save JSON file to $OutputPath`: $_"
        }
    }

    # Return the settings object
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Returning settings object with $($resultObject.PSObject.Properties.Name -join ', ') properties"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    return $resultObject
}

function Set-ADMXPolicies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$PolicySettings
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Setting ADMX Policies..."

    <#
    ADMX Policies mapping - Maps ADMX policy names to their registry equivalents
    This is a subset of common ADMX policies. More can be added as needed.
    #>
    $ADMXRegistry = @{
        'EnableUAC' = @{
            'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
            'Name' = 'EnableLUA'
            'Type' = 'DWord'
        }
        'DisableAutoRun' = @{
            'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
            'Name' = 'NoDriveTypeAutoRun'
            'Type' = 'DWord'
        }
        'DisableCommandPrompt' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\System'
            'Name' = 'DisableCMD'
            'Type' = 'DWord'
        }
        'DisableRegistryEdit' = @{
            'Path' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
            'Name' = 'DisableRegistryTools'
            'Type' = 'DWord'
        }
        'RestrictRemoteDesktop' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services'
            'Name' = 'fDenyTSConnections'
            'Type' = 'DWord'
        }
        'EnableWindowsDefender' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\Windows Defender'
            'Name' = 'DisableAntiSpyware'
            'Type' = 'DWord'
        }
        'EnableFirewall' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile'
            'Name' = 'EnableFirewall'
            'Type' = 'DWord'
        }
        'DisableWindowsUpdate' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
            'Name' = 'NoAutoUpdate'
            'Type' = 'DWord'
        }
        'RestrictPowerShellExecution' = @{
            'Path' = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell'
            'Name' = 'EnableScripts'
            'Type' = 'DWord'
        }
        'DisableUSBStorage' = @{
            'Path' = 'HKLM:\System\CurrentControlSet\Services\USBSTOR'
            'Name' = 'Start'
            'Type' = 'DWord'
        }
    }

    if (-not $PolicySettings -or $PolicySettings.Count -eq 0) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No ADMX policies provided"
        return
    }

    $PolicyCount = 0
    $FailureCount = 0

    foreach ($PolicyName in $PolicySettings.Keys) {
        try {
            if (-not $ADMXRegistry.ContainsKey($PolicyName)) {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unknown ADMX policy: $PolicyName (skipping)"
                $FailureCount++
                continue
            }

            $PolicyConfig = $ADMXRegistry[$PolicyName]
            $RegistryPath = $PolicyConfig['Path']
            $ValueName = $PolicyConfig['Name']
            $ValueType = $PolicyConfig['Type']
            $Value = $PolicySettings[$PolicyName]

            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Applying ADMX policy: $PolicyName -> $RegistryPath\$ValueName = $Value"

            # Create registry path if it doesn't exist
            if (-not (Test-Path -Path $RegistryPath)) {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Creating registry path: $RegistryPath"
                $null = New-Item -Path $RegistryPath -Force -ErrorAction SilentlyContinue
            }

            # Set the registry value
            $null = Set-ItemProperty -Path $RegistryPath -Name $ValueName -Value $Value -Type $ValueType -Force -ErrorAction Stop
            
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ADMX policy applied: $PolicyName"
            $PolicyCount++
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to apply ADMX policy $PolicyName`: $_"
            $FailureCount++
        }
    }

    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] ADMX Policies Complete: $PolicyCount applied, $FailureCount failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

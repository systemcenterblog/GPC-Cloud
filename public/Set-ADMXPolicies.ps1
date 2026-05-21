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
    
    # Control Panel Restrictions
    'ProhibitControlPanel' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        'Name' = 'NoControlPanel'
        'Type' = 'DWord'
    }

    'ShowOnlySpecifiedControlPanelItems' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        'Name' = 'RestrictCpl'
        'Type' = 'DWord'
    }

    # Desktop Restrictions
    'HideDesktopIcons' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        'Name' = 'NoDesktop'
        'Type' = 'DWord'
    }

    # Wallpaper Enforcement
    'SetDesktopWallpaper' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop'
        'Name' = 'Wallpaper'
        'Type' = 'String'
    }

    'WallpaperStyle' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop'
        'Name' = 'WallpaperStyle'
        'Type' = 'String'
    }

    # Disable Context Menu
    'DisableContextMenu' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
        'Name' = 'NoViewContextMenu'
        'Type' = 'DWord'
    }

    # Ctrl+Alt+Del Options
    'RemoveLockComputer' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
        'Name' = 'DisableLockWorkstation'
        'Type' = 'DWord'
    }

    # Attachment Manager
    'LowRiskFileTypes' = @{
        'Path' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations'
        'Name' = 'LowRiskFileTypes'
        'Type' = 'String'
    }

    # Screen Saver
    'EnableScreenSaver' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
        'Name' = 'ScreenSaveActive'
        'Type' = 'String'
    }

    'ForceScreenSaver' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
        'Name' = 'SCRNSAVE.EXE'
        'Type' = 'String'
    }

    # Office Sign-in restriction (modern Office ADMX)
    'BlockOfficeSignIn' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Common\SignIn'
        'Name' = 'SignInOptions'
        'Type' = 'DWord'
    }

    # OneDrive prompt
    'DisableOneDriveSignInPrompt' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Common\General'
        'Name' = 'ShownFirstRunOptin'
        'Type' = 'DWord'
    }

    # Word AutoRecover location
    'WordAutoRecoverLocation' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Options'
        'Name' = 'AutoRecover Path'
        'Type' = 'String'
    }

    # Word Start screen
    'DisableWordStartScreen' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Options'
        'Name' = 'DisableBootToOfficeStart'
        'Type' = 'DWord'
    }

    # Word AutoCorrect / Proofing examples
    'DisableAutoCorrectReplaceText' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Options\Proofing'
        'Name' = 'AutoFormatReplaceText'
        'Type' = 'DWord'
    }

    'DisableAutoBulletLists' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Options\Proofing'
        'Name' = 'AutoFormatApplyBulletedLists'
        'Type' = 'DWord'
    }

    'DisableAutoNumberLists' = @{
        'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Options\Proofing'
        'Name' = 'AutoFormatApplyNumberedLists'
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

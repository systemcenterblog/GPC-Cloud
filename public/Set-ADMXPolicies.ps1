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

    # Word - Disabled CommandBar Items List (flattened TCIDs)
'WordDisabledCmdBar_TCID1' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID1'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID2' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID2'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID3' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID3'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID4' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID4'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID5' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID5'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID6' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID6'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID7' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID7'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID8' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID8'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID9' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID9'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID10' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID10'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID11' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID11'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID12' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID12'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID13' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID13'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID14' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID14'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID15' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID15'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID16' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID16'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID17' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID17'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID18' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID18'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID19' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID19'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID20' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID20'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID21' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID21'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID22' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID22'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID23' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID23'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID24' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID24'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID25' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID25'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID26' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID26'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID27' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID27'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID28' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID28'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID29' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID29'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID30' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID30'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID31' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID31'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID32' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID32'
    'Type' = 'String'
}

'WordDisabledCmdBar_TCID33' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledCmdBarItemsList'
    'Name' = 'TCID33'
    'Type' = 'String'
}
# Word - Disabled Shortcut Keys List
'WordDisabledShortcutKeys_KeyMod1' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledShortcutKeysList'
    'Name' = 'KeyMod1'
    'Type' = 'String'   # REG_SZ
}

'WordDisabledShortcutKeys_KeyMod2' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledShortcutKeysList'
    'Name' = 'KeyMod2'
    'Type' = 'String'   # REG_SZ
}

'WordDisabledShortcutKeys_KeyMod3' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledShortcutKeysList'
    'Name' = 'KeyMod3'
    'Type' = 'String'   # REG_SZ
}

'WordDisabledShortcutKeys_KeyMod4' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledShortcutKeysList'
    'Name' = 'KeyMod4'
    'Type' = 'String'   # REG_SZ
}

'WordDisabledShortcutKeys_KeyMod5' = @{
    'Path' = 'HKCU:\Software\Policies\Microsoft\Office\16.0\Word\DisabledShortcutKeysList'
    'Name' = 'KeyMod5'
    'Type' = 'String'   # REG_SZ
}
#Printer Connections (example of multi-value policy with subkeys)
'PrintersConnections__printdir_kprn015793_GuidPrinter' = @{
    'Path' = 'HKCU:\Printers\Connections\,,printdir,kprn015793'
    'Name' = 'GuidPrinter'
    'Type' = 'String'   # REG_SZ
    'Value' = '{26371990-41CD-415B-8872-DC4FF4145F76}'
}

'PrintersConnections__printdir_kprn015793_Server' = @{
    'Path' = 'HKCU:\Printers\Connections\,,printdir,kprn015793'
    'Name' = 'Server'
    'Type' = 'String'   # REG_SZ
    'Value' = '\\printdir'
}

'PrintersConnections__printdir_kprn015793_Provider' = @{
    'Path' = 'HKCU:\Printers\Connections\,,printdir,kprn015793'
    'Name' = 'Provider'
    'Type' = 'String'   # REG_SZ
    'Value' = 'win32spl.dll'
}

'PrintersConnections__printdir_kprn015793_LocalConnection' = @{
    'Path' = 'HKCU:\Printers\Connections\,,printdir,kprn015793'
    'Name' = 'LocalConnection'
    'Type' = 'DWord'    # REG_DWORD
    'Value' = 1
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

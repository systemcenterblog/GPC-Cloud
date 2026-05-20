# Group Policy Configuration Module

A standalone PowerShell module for applying Windows group policy settings, Defender configuration, Firewall rules, and Windows features. Supports both direct hashtable input and JSON file imports for easy policy management and version control.

## Installation

1. Copy the `GroupPolicyConfiguration` folder to your PowerShell modules directory:
   - User: `$PROFILE\..\Modules\`
   - System: `C:\Program Files\PowerShell\Modules\`

2. Import the module:
   ```powershell
   Import-Module GroupPolicyConfiguration
   ```

## Commands

### Set-GroupPolicyConfiguration
Applies group policy settings from hashtable or JSON file.

```powershell
# Using JSON file
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\security-baseline.json'

# Using hashtable
$policies = @{
    'HKLM:\Software\Policies\Microsoft\Windows\System' = @{
        'DisableThumbsDB' = @{ Value = 1; Type = 'DWord' }
    }
}
Set-GroupPolicyConfiguration -PolicySettings $policies
```

### Set-WindowsDefender
Configures Windows Defender settings.

```powershell
Set-WindowsDefender -RealTimeProtectionEnabled $true -CloudProtectionEnabled $true
```

### Set-WindowsFirewall
Configures Windows Firewall profiles and rules.

```powershell
$DomainSettings = @{
    'Enabled' = $true
    'DefaultInboundAction' = 'Block'
}
Set-WindowsFirewall -DomainProfile $DomainSettings
```

### Set-WindowsFeatures
Enables/disables Windows optional features.

```powershell
Set-WindowsFeatures -EnableFeatures @('Hyper-V', 'Containers')
```

## JSON Policy Format

Create policy files with this structure:

```json
{
  "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
    "DisableThumbsDB": { "Value": 1, "Type": "DWord" },
    "LocalAccountTokenFilterPolicy": 0
  }
}
```

**Important:** Use `\\` for backslashes in JSON registry paths.

## Features

- ✅ JSON-based policy configuration
- ✅ Hashtable parameter support
- ✅ Online (full OS) and offline (WinPE) registry modification
- ✅ Comprehensive error handling
- ✅ Verbose logging
- ✅ Administrator privilege requirements

## License

MIT

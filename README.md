# Group Policy Configuration Module

A standalone PowerShell module for applying Windows group policy settings, AppLocker rules, ADMX policies, Defender configuration, Firewall rules, and Windows features. Supports both direct hashtable input and JSON file imports for easy policy management and version control.

## Installation

1. Copy the `GroupPolicyConfiguration` folder to your PowerShell modules directory:
   - User: `$PROFILE\..\Modules\`
   - System: `C:\Program Files\PowerShell\Modules\`

2. Import the module:
   ```powershell
   Import-Module GroupPolicyConfiguration
   ```

## Commands

### Get-ADMXAppLockerSettings
Retrieves current ADMX policies and AppLocker rules from the local computer and optionally exports to JSON.

```powershell
# Get current settings and return as object
$settings = Get-ADMXAppLockerSettings
$settings.ADMXPolicies

# Get settings and save to JSON file
Get-ADMXAppLockerSettings -OutputPath 'C:\policies\current-settings.json'

# Get only AppLocker rules
$appLockerOnly = Get-ADMXAppLockerSettings -IncludeADMX $false

# Get ADMX and registry policies (exclude AppLocker)
$settings = Get-ADMXAppLockerSettings -IncludeAppLocker $false -IncludeRegistry $true
```

### Set-GroupPolicyConfiguration
Applies group policy settings, AppLocker rules, and ADMX policies from hashtable or JSON file.

```powershell
# Using JSON file with all configuration types
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\security-baseline.json'

# Using hashtable
$policies = @{
    'HKLM:\Software\Policies\Microsoft\Windows\System' = @{
        'DisableThumbsDB' = @{ Value = 1; Type = 'DWord' }
    }
}
Set-GroupPolicyConfiguration -PolicySettings $policies

# Skip AppLocker or ADMX processing if needed
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\policies.json' -SkipAppLocker -SkipADMX
```

### Set-AppLockerRules
Applies AppLocker rules from XML content.

```powershell
$appLockerXml = Get-Content -Path 'C:\policies\applocker.xml' -Raw
Set-AppLockerRules -RulesXml $appLockerXml
```

### Set-ADMXPolicies
Applies ADMX-controlled policies via registry.

```powershell
$admxSettings = @{
    'EnableUAC' = 1
    'EnableFirewall' = 1
    'DisableAutoRun' = 255
}
Set-ADMXPolicies -PolicySettings $admxSettings
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

Create policy files with this comprehensive structure:

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": { "Value": 1, "Type": "DWord" },
      "LocalAccountTokenFilterPolicy": 0
    }
  },
  "ADMXPolicies": {
    "EnableUAC": 1,
    "EnableFirewall": 1,
    "DisableAutoRun": 255
  },
  "AppLockerRules": "<?xml version=\"1.0\"?><!-- XML content here -->"
}
```

### JSON Sections

- **RegistryPolicies** (optional): Registry-based group policy settings. Use double backslashes (`\\`) in paths.
- **ADMXPolicies** (optional): ADMX-controlled policies mapped to registry equivalents.
- **AppLockerRules** (optional): AppLocker rules in XML format.

### Supported ADMX Policies

- `EnableUAC` - User Account Control enabled (1) or disabled (0)
- `DisableAutoRun` - AutoRun behavior (255 = disabled all drives)
- `DisableCommandPrompt` - Disable command prompt (1) or allow (0)
- `DisableRegistryEdit` - Registry editor access (1) or allowed (0)
- `RestrictRemoteDesktop` - RDP connections (1 = deny, 0 = allow)
- `EnableWindowsDefender` - Windows Defender enabled (0) or disabled (1)
- `EnableFirewall` - Windows Firewall enabled (1) or disabled (0)
- `DisableWindowsUpdate` - Windows Update disabled (1) or enabled (0)
- `RestrictPowerShellExecution` - PowerShell script execution (1 = restricted)
- `DisableUSBStorage` - USB storage status (4 = disabled, 3 = enabled)

## Features

- ✅ Retrieve current ADMX and AppLocker settings from local computer
- ✅ Export settings to JSON for backup or replication
- ✅ JSON-based policy configuration
- ✅ AppLocker rule support (XML format)
- ✅ ADMX policy support
- ✅ Hashtable parameter support
- ✅ Online (full OS) and offline (WinPE) registry modification
- ✅ Comprehensive error handling
- ✅ Per-item error isolation (failures don't cascade)
- ✅ Verbose logging and status reporting
- ✅ Administrator privilege requirements
- ✅ Unified configuration in single JSON file

## Examples

See the `examples/` folder for complete examples:
- `get-settings-output-example.json` - Example output from Get-ADMXAppLockerSettings
- `unified-policies-example.json` - Registry + ADMX + AppLocker
- `admx-policies-example.json` - ADMX policies only
- `applocker-rules-example.json` - AppLocker rules only
- `security-baseline.json` - Registry policies only (legacy format)

## License

MIT

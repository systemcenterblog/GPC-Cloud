# Quick Start Guide

## Installation

```powershell
# Option 1: Add to PowerShell Modules
Copy-Item -Path "C:\GroupPolicyConfiguration" -Destination "$PROFILE\..\Modules\" -Recurse -Force

# Option 2: Import directly from current location
Import-Module "C:\GroupPolicyConfiguration\GroupPolicyConfiguration.psd1"
```

## Basic Usage (5 minutes)

### 1. Apply Group Policy from JSON (Registry only)

Create a file: `C:\policies\my-policies.json`

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": {
        "Value": 1,
        "Type": "DWord"
      }
    }
  }
}
```

Then apply it:

```powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\my-policies.json'
```

### 2. Apply ADMX Policies from JSON

Create a file: `C:\policies\admx-policies.json`

```json
{
  "ADMXPolicies": {
    "EnableUAC": 1,
    "EnableFirewall": 1,
    "DisableAutoRun": 255
  }
}
```

Apply:

```powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\admx-policies.json'
```

### 3. Apply AppLocker Rules from JSON

Create a file: `C:\policies\applocker.json`

```json
{
  "AppLockerRules": "<?xml version=\"1.0\"?><!-- AppLocker XML rules here -->"
}
```

Apply:

```powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\applocker.json'
```

### 4. Apply All Three in One JSON

Create a file: `C:\policies\unified-config.json`

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": { "Value": 1, "Type": "DWord" }
    }
  },
  "ADMXPolicies": {
    "EnableUAC": 1,
    "EnableFirewall": 1
  },
  "AppLockerRules": "<?xml version=\"1.0\"?><!-- XML here -->"
}
```

Apply:

```powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\unified-config.json'
```

### 5. Apply Policies from PowerShell (Hashtable)

```powershell
$policies = @{
    'RegistryPolicies' = @{
        'HKLM:\Software\Policies\Test' = @{
            'Setting1' = @{ Value = 1; Type = 'DWord' }
        }
    }
    'ADMXPolicies' = @{
        'EnableUAC' = 1
        'EnableFirewall' = 1
    }
}

Set-GroupPolicyConfiguration -PolicySettings $policies
```

### 6. Configure Defender

```powershell
Set-WindowsDefender `
    -RealTimeProtectionEnabled $true `
    -CloudProtectionEnabled $true `
    -ScheduledScansEnabled $true
```

### 7. Configure Firewall

```powershell
$Domain = @{
    'Enabled' = $true
    'DefaultInboundAction' = 'Block'
    'DefaultOutboundAction' = 'Allow'
}

Set-WindowsFirewall -DomainProfile $Domain
```

### 8. Enable Windows Features

```powershell
Set-WindowsFeatures -EnableFeatures @('Hyper-V', 'Containers')
```

## JSON Policy Tips

- **Use double backslashes** in registry paths: `HKLM:\\Software\\...`
- **Type options**: `String`, `DWord`, `ExpandString`, `Binary`, `MultiString`
- **Simple values** work without Type specification (defaults to String)
- **Complex values** use `{ "Value": <value>, "Type": "<type>" }` format
- **Optional sections**: Include only the sections you need (RegistryPolicies, ADMXPolicies, AppLockerRules)

## Common Scenarios

### Security Hardening (Complete)

Create `security-hardened.json`:

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": { "Value": 1, "Type": "DWord" }
    }
  },
  "ADMXPolicies": {
    "EnableUAC": 1,
    "DisableAutoRun": 255,
    "EnableFirewall": 1,
    "RestrictRemoteDesktop": 1
  }
}
```

Apply:
```powershell
Set-GroupPolicyConfiguration -JsonPath 'security-hardened.json'
```

### Application Lockdown (AppLocker Focus)

```powershell
$appLockerXml = @"
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe" EnforcementMode="Enforce">
    <FilePathRule Id="1" Name="Allow Program Files" UserOrGroupSid="S-1-1-0" Action="Allow">
      <Conditions>
        <FilePathCondition Path="C:\Program Files\*" />
      </Conditions>
    </FilePathRule>
  </RuleCollection>
</AppLockerPolicy>
"@

Set-AppLockerRules -RulesXml $appLockerXml
```

### Skip Specific Configuration Types

```powershell
# Skip AppLocker rules
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -SkipAppLocker

# Skip ADMX policies
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -SkipADMX

# Skip both
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -SkipAppLocker -SkipADMX
```

## Troubleshooting

**"JSON file not found"**
- Check the path is absolute (not relative)
- Example: `C:\policies\my.json` not `.\my.json`

**"Administrator privileges required"**
- Run PowerShell as Administrator
- Example: `sudo pwsh` (PowerShell 7+)

**"Registry path not found"**
- Path will be created automatically if it doesn't exist
- Ensure HKLM:\\ is used for system policies

**"AppLocker cmdlets not available"**
- Ensure AppLocker role is installed: `Install-WindowsFeature -Name AppLocker`
- Import AppLocker module: `Import-Module AppLocker`

**"Feature not found"**
- Run: `Get-WindowsOptionalFeature -Online | Where Name -like '*Hyper*'`
- Use exact feature names from the list

## Advanced: Offline Registry (WinPE)

```powershell
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -OfflineRegistry
```

This uses `reg.exe` instead of PowerShell provider for WinPE environments.

## Help

Get detailed help for any command:

```powershell
Get-Help Set-GroupPolicyConfiguration -Full
Get-Help Set-AppLockerRules -Full
Get-Help Set-ADMXPolicies -Full
Get-Help Set-WindowsDefender -Full
Get-Help Set-WindowsFirewall -Full
Get-Help Set-WindowsFeatures -Full
```

## Example Files

Check the `examples/` folder:
- `unified-policies-example.json` - Complete example with all three types
- `admx-policies-example.json` - ADMX policies only
- `applocker-rules-example.json` - AppLocker rules only
- `security-baseline.json` - Registry policies only (legacy)

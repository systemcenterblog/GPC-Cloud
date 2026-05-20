# Quick Start Guide

## Installation

```powershell
# Option 1: Add to PowerShell Modules
Copy-Item -Path "C:\GroupPolicyConfiguration" -Destination "$PROFILE\..\Modules\" -Recurse -Force

# Option 2: Import directly from current location
Import-Module "C:\GroupPolicyConfiguration\GroupPolicyConfiguration.psd1"
```

## Basic Usage (5 minutes)

### 1. Apply Group Policy from JSON

Create a file: `C:\policies\my-policies.json`

```json
{
  "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
    "DisableThumbsDB": {
      "Value": 1,
      "Type": "DWord"
    }
  }
}
```

Then apply it:

```powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\my-policies.json'
```

### 2. Apply Group Policy from PowerShell

```powershell
$policies = @{
    'HKLM:\Software\Policies\Test' = @{
        'Setting1' = @{ Value = 1; Type = 'DWord' }
        'Setting2' = 'StringValue'
    }
}

Set-GroupPolicyConfiguration -PolicySettings $policies
```

### 3. Configure Defender

```powershell
Set-WindowsDefender `
    -RealTimeProtectionEnabled $true `
    -CloudProtectionEnabled $true `
    -ScheduledScansEnabled $true
```

### 4. Configure Firewall

```powershell
$Domain = @{
    'Enabled' = $true
    'DefaultInboundAction' = 'Block'
    'DefaultOutboundAction' = 'Allow'
}

Set-WindowsFirewall -DomainProfile $Domain
```

### 5. Enable Windows Features

```powershell
Set-WindowsFeatures -EnableFeatures @('Hyper-V', 'Containers')
```

## JSON Policy Tips

- **Use double backslashes** in registry paths: `HKLM:\\Software\\...`
- **Type options**: `String`, `DWord`, `ExpandString`, `Binary`, `MultiString`
- **Simple values** work without Type specification (defaults to String)
- **Complex values** use `{ "Value": <value>, "Type": "<type>" }` format

## Common Scenarios

### Security Hardening

Create `security.json`:

```json
{
  "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
    "DisableThumbsDB": { "Value": 1, "Type": "DWord" }
  },
  "HKLM:\\Software\\Policies\\Microsoft\\Windows\\PowerShell": {
    "ExecutionPolicy": { "Value": "RemoteSigned", "Type": "String" }
  }
}
```

Apply:
```powershell
Set-GroupPolicyConfiguration -JsonPath 'security.json'
```

### Development Machine Setup

```powershell
# Enable dev features
Set-WindowsFeatures -EnableFeatures @('HypervisorPlatform', 'VirtualMachinePlatform', 'Containers')

# Configure firewall for dev
$InboundRules = @(
    @{
        'Name' = 'AllowSSH'
        'DisplayName' = 'Allow SSH'
        'Protocol' = 'TCP'
        'LocalPort' = 22
        'Action' = 'Allow'
    }
)
Set-WindowsFirewall -DomainProfile @{'Enabled' = $true} -InboundRules $InboundRules
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
Get-Help Set-WindowsDefender -Full
Get-Help Set-WindowsFirewall -Full
Get-Help Set-WindowsFeatures -Full
```

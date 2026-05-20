# Standalone Group Policy Configuration Module - Summary

## What Was Created

A complete, self-contained PowerShell module extracted from the OSDCloud project for managing Windows group policy settings, Defender configuration, Firewall rules, and Windows features.

**Location:** C:\GroupPolicyConfiguration

## Module Contents

### Public Functions (4 cmdlets)
1. **Set-GroupPolicyConfiguration** - Apply group policies from JSON or hashtable
   - JSON file import support
   - Hashtable parameter support
   - Merge JSON + hashtable
   - Online/offline registry support

2. **Set-WindowsDefender** - Configure Windows Defender
   - Real-time protection
   - Cloud protection
   - Scheduled scans
   - Per-setting error handling

3. **Set-WindowsFirewall** - Configure Windows Firewall
   - Profile settings (Domain, Private, Public)
   - Inbound/outbound rules
   - Automatic rule replacement

4. **Set-WindowsFeatures** - Enable/disable Windows optional features
   - Hyper-V, Containers, WSL, etc.
   - State verification

### Private Functions (1 helper)
- **Set-RegistryValue** - Unified registry modification (online and offline)

## Directory Structure

`
C:\GroupPolicyConfiguration\
├── GroupPolicyConfiguration.psd1      # Module manifest
├── GroupPolicyConfiguration.psm1      # Root module file
├── README.md                           # Full documentation
├── QUICKSTART.md                       # Quick start guide
├── public/
│   ├── Set-GroupPolicyConfiguration.ps1
│   ├── Set-WindowsDefender.ps1
│   ├── Set-WindowsFirewall.ps1
│   └── Set-WindowsFeatures.ps1
├── private/
│   └── main/
│       └── Set-RegistryValue.ps1
├── examples/
│   ├── security-baseline.json          # Example policy file
│   └── usage-example.ps1               # Usage examples
└── docs/                               # (for future documentation)
`

## Key Features

✅ **JSON Policy Support** - Define policies in version-controllable JSON files
✅ **Hashtable Support** - Direct PowerShell parameter usage
✅ **Online/Offline** - Works in both full OS and WinPE environments
✅ **Error Resilience** - Per-setting error handling (one failure doesn't cascade)
✅ **Logging** - Comprehensive verbose/debug output
✅ **Registry Management** - Unified online/offline registry handling
✅ **Path Creation** - Automatically creates missing registry paths

## Installation (3 ways)

### Method 1: System-wide (Recommended)
\\\powershell
Copy-Item -Path 'C:\GroupPolicyConfiguration' -Destination 'C:\Program Files\PowerShell\Modules\' -Recurse -Force
Import-Module GroupPolicyConfiguration
\\\

### Method 2: User Profile
\\\powershell
Copy-Item -Path 'C:\GroupPolicyConfiguration' -Destination "\C:\Users\k1630678\OneDrive - King's College London\Documents\PowerShell\Microsoft.PowerShell_profile.ps1\..\Modules\" -Recurse -Force
Import-Module GroupPolicyConfiguration
\\\

### Method 3: Direct Import
\\\powershell
Import-Module 'C:\GroupPolicyConfiguration\GroupPolicyConfiguration.psd1'
\\\

## Quick Examples

### Apply JSON policies:
\\\powershell
Set-GroupPolicyConfiguration -JsonPath 'C:\policies\security.json'
\\\

### Apply hashtable policies:
\\\powershell
\ = @{
    'HKLM:\Software\Policies\Test' = @{
        'Setting1' = @{ Value = 1; Type = 'DWord' }
    }
}
Set-GroupPolicyConfiguration -PolicySettings \
\\\

### Configure Defender:
\\\powershell
Set-WindowsDefender -RealTimeProtectionEnabled \True -CloudProtectionEnabled \True
\\\

### Configure Firewall:
\\\powershell
\ = @{ 'Enabled' = \True; 'DefaultInboundAction' = 'Block' }
Set-WindowsFirewall -DomainProfile \
\\\

### Enable features:
\\\powershell
Set-WindowsFeatures -EnableFeatures @('Hyper-V', 'Containers')
\\\

## JSON Policy Format

Registry paths use double backslashes (JSON escaping):
\\\json
{
  "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
    "DisableThumbsDB": {
      "Value": 1,
      "Type": "DWord"
    },
    "SimpleSetting": "StringValue"
  }
}
\\\

**Supported Types:** String, DWord, ExpandString, Binary, MultiString

## Requirements

- PowerShell 5.1+ (Windows built-in) or PowerShell 7+
- Administrator privileges
- Windows 10/11 or Windows Server 2016+

## Extracted From

OSDCloud project (GitHub: systemcenterblog/OSDCloud)

All functions maintain the same structure, error handling, and logging patterns as the original OSDCloud implementations. This module can be used standalone without importing the full OSDCloud module.

## Files Created

- 4 public cmdlet files (550 lines total)
- 1 private helper file (91 lines)
- 1 module manifest (psd1)
- 1 root module file (psm1)
- 1 README with full documentation
- 1 QUICKSTART guide with examples
- 1 example policy file (JSON)
- 1 example usage script
- Full directory structure ready to use

Total: **12 files**, ~1,500 lines of code and documentation

## Next Steps

1. Review the examples in \\examples\
2. Create your own policy JSON files following the format
3. Import the module and start applying policies
4. Reference QUICKSTART.md for common scenarios

## Support

- Use \Get-Help\ on any cmdlet for detailed documentation
- Check QUICKSTART.md for troubleshooting
- Review examples folder for usage patterns

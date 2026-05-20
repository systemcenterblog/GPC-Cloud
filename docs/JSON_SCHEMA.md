# JSON Configuration Schema

Complete documentation of the JSON configuration file format supported by GroupPolicyConfiguration module.

## Overview

The JSON configuration file supports three optional sections:

1. **RegistryPolicies** - Registry-based group policy settings
2. **ADMXPolicies** - ADMX-controlled policies (mapped to registry)
3. **AppLockerRules** - AppLocker XML rules

All sections are optional. You can include any combination of them.

## RegistryPolicies Section

Registry-based group policy settings applied directly to the Windows registry.

### Structure

```json
{
  "RegistryPolicies": {
    "REGISTRY_PATH": {
      "ValueName": "SimpleValue",
      "AnotherValue": {
        "Value": "ComplexValue",
        "Type": "String"
      }
    }
  }
}
```

### Registry Path Format

- Use **double backslashes** (`\\`) to escape path separators
- Required root hives: `HKLM\\`, `HKCU\\`, `HKU\\`, `HKCR\\`
- Example: `HKLM:\\Software\\Policies\\Microsoft\\Windows\\System`

### Value Types

Supported registry value types:

| Type | Description | Example |
|------|-------------|---------|
| String | Text string | `"RemoteSigned"` |
| DWord | 32-bit unsigned integer | `1`, `0`, `255` |
| ExpandString | String with environment variables | `%SystemRoot%\System32` |
| Binary | Binary data | `"A1B2C3D4"` |
| MultiString | Multiple strings separated by null | `["String1", "String2"]` |

### Value Format

Simple values (default to String type):
```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Test": {
      "SimpleSetting": "StringValue"
    }
  }
}
```

Complex values (with explicit type):
```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Test": {
      "DWordSetting": {
        "Value": 1,
        "Type": "DWord"
      },
      "ExpandSetting": {
        "Value": "%SystemRoot%\\System32",
        "Type": "ExpandString"
      }
    }
  }
}
```

### Example

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": {
        "Value": 1,
        "Type": "DWord"
      },
      "LocalAccountTokenFilterPolicy": {
        "Value": 0,
        "Type": "DWord"
      }
    },
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\PowerShell": {
      "ExecutionPolicy": {
        "Value": "RemoteSigned",
        "Type": "String"
      }
    }
  }
}
```

## ADMXPolicies Section

ADMX-controlled policies that are automatically mapped to registry equivalents.

### Structure

```json
{
  "ADMXPolicies": {
    "PolicyName": PolicyValue,
    "AnotherPolicy": PolicyValue
  }
}
```

### Supported ADMX Policies

| Policy Name | Registry Path | Value Name | Type | Description |
|-----------|---------------|-----------|------|-------------|
| `EnableUAC` | `HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System` | `EnableLUA` | DWord | User Account Control (1=enabled, 0=disabled) |
| `DisableAutoRun` | `HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer` | `NoDriveTypeAutoRun` | DWord | Disable AutoRun (255=all drives disabled) |
| `DisableCommandPrompt` | `HKLM:\Software\Policies\Microsoft\Windows\System` | `DisableCMD` | DWord | Disable command prompt (1=disabled, 0=allowed) |
| `DisableRegistryEdit` | `HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System` | `DisableRegistryTools` | DWord | Registry editor access (1=disabled, 0=allowed) |
| `RestrictRemoteDesktop` | `HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services` | `fDenyTSConnections` | DWord | RDP (1=deny, 0=allow) |
| `EnableWindowsDefender` | `HKLM:\Software\Policies\Microsoft\Windows Defender` | `DisableAntiSpyware` | DWord | Windows Defender (0=enabled, 1=disabled) |
| `EnableFirewall` | `HKLM:\Software\Policies\Microsoft\WindowsFirewall\DomainProfile` | `EnableFirewall` | DWord | Firewall (1=enabled, 0=disabled) |
| `DisableWindowsUpdate` | `HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU` | `NoAutoUpdate` | DWord | Windows Update (0=enabled, 1=disabled) |
| `RestrictPowerShellExecution` | `HKLM:\Software\Policies\Microsoft\Windows\PowerShell` | `EnableScripts` | DWord | PowerShell scripts (0=disabled, 1=enabled) |
| `DisableUSBStorage` | `HKLM:\System\CurrentControlSet\Services\USBSTOR` | `Start` | DWord | USB storage (3=enabled, 4=disabled) |

### Example

```json
{
  "ADMXPolicies": {
    "EnableUAC": 1,
    "DisableAutoRun": 255,
    "DisableCommandPrompt": 0,
    "EnableFirewall": 1,
    "EnableWindowsDefender": 0,
    "RestrictRemoteDesktop": 0,
    "DisableUSBStorage": 3
  }
}
```

### Adding Custom ADMX Policies

Extend `Set-ADMXPolicies.ps1` with additional policy mappings:

```powershell
$ADMXRegistry = @{
    'CustomPolicy' = @{
        'Path' = 'HKLM:\Custom\Registry\Path'
        'Name' = 'ValueName'
        'Type' = 'DWord'
    }
}
```

## AppLockerRules Section

AppLocker rules in XML format applied to the local system.

### Structure

```json
{
  "AppLockerRules": "<?xml version=\"1.0\"?><!-- XML content -->"
}
```

### AppLocker XML Format

Must be a valid AppLocker policy XML document with the following structure:

```xml
<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">
  <RuleCollection Type="Exe|Dll|Script|Appx|Msi" EnforcementMode="Enforce|AuditOnly">
    <FilePublisherRule Id="..." Name="..." UserOrGroupSid="..." Action="Allow|Deny">
      <Conditions>
        <FilePublisherCondition PublisherName="..." ProductName="..." BinaryName="...">
          <BinaryVersionRange LowSection="*" HighSection="*" />
        </FilePublisherCondition>
      </Conditions>
      <Exceptions></Exceptions>
    </FilePublisherRule>
    
    <FilePathRule Id="..." Name="..." UserOrGroupSid="..." Action="Allow|Deny">
      <Conditions>
        <FilePathCondition Path="..." />
      </Conditions>
      <Exceptions></Exceptions>
    </FilePathRule>
    
    <FileHashRule Id="..." Name="..." UserOrGroupSid="..." Action="Allow|Deny">
      <Conditions>
        <FileHashCondition>
          <FileHash Type="SHA1|MD5" Data="..." />
        </FileHashCondition>
      </Conditions>
      <Exceptions></Exceptions>
    </FileHashRule>
  </RuleCollection>
</AppLockerPolicy>
```

### Rule Types

| Type | Description | Collection Type |
|------|-------------|-----------------|
| `FilePublisherRule` | Based on publisher/version | Any |
| `FilePathRule` | Based on file path | Any |
| `FileHashRule` | Based on file hash | Any |
| `NetworkShareRule` | Based on network path | Exe |

### Collection Types

| Type | Description |
|------|-------------|
| `Exe` | Executable files (.exe, .com) |
| `Dll` | Dynamic link libraries (.dll, .ocx) |
| `Script` | Scripts (.ps1, .vbs, .js, .bat, .cmd) |
| `Appx` | Windows Store apps |
| `Msi` | Windows Installer packages (.msi) |

### Enforcement Modes

- `Enforce` - Rules are enforced
- `AuditOnly` - Rules logged but not enforced

### Example: Simple AppLocker Rules

```json
{
  "AppLockerRules": "<?xml version=\"1.0\" encoding=\"utf-8\"?><AppLockerPolicy Version=\"1\"><RuleCollection Type=\"Exe\" EnforcementMode=\"Enforce\"><FilePublisherRule Id=\"921cc481\" Name=\"Allow Microsoft\" UserOrGroupSid=\"S-1-1-0\" Action=\"Allow\"><Conditions><FilePublisherCondition PublisherName=\"O=MICROSOFT CORPORATION, L=REDMOND, S=WASHINGTON, C=US\" ProductName=\"*\" BinaryName=\"*\"><BinaryVersionRange LowSection=\"*\" HighSection=\"*\" /></FilePublisherCondition></Conditions></FilePublisherRule></RuleCollection></AppLockerPolicy>"
}
```

## Unified Configuration Example

```json
{
  "RegistryPolicies": {
    "HKLM:\\Software\\Policies\\Microsoft\\Windows\\System": {
      "DisableThumbsDB": {
        "Value": 1,
        "Type": "DWord"
      }
    }
  },
  "ADMXPolicies": {
    "EnableUAC": 1,
    "EnableFirewall": 1,
    "DisableAutoRun": 255
  },
  "AppLockerRules": "<?xml version=\"1.0\" encoding=\"utf-8\"?><AppLockerPolicy Version=\"1\"><!-- rules here --></AppLockerPolicy>"
}
```

## Usage Examples

### Apply Registry Policies Only

```powershell
Set-GroupPolicyConfiguration -JsonPath 'policies.json'
```

### Apply with Offline Registry

```powershell
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -OfflineRegistry
```

### Skip AppLocker During Application

```powershell
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -SkipAppLocker
```

### Skip ADMX During Application

```powershell
Set-GroupPolicyConfiguration -JsonPath 'policies.json' -SkipADMX
```

## Best Practices

1. **Path Escaping** - Always use double backslashes in registry paths
2. **GUIDs** - Use unique GUIDs for AppLocker rule IDs
3. **Minimal Permissions** - Request only necessary permissions
4. **Testing** - Use AuditOnly mode first before Enforce
5. **Documentation** - Include comments explaining policy purpose
6. **Version Control** - Store JSON files in version control

## Validation

Before applying, ensure:

- ✅ Registry paths use correct hive prefixes
- ✅ JSON is valid (use JSON validator tool)
- ✅ AppLocker XML is well-formed
- ✅ ADMX policy names are correct
- ✅ File paths are absolute (not relative)
- ✅ Administrator privileges available

## Error Handling

The module implements per-item error isolation:
- Individual policy failures don't cascade
- Missing registry paths are auto-created
- Invalid ADMX policies are skipped with warning
- AppLocker parsing errors are reported

## References

- [Group Policy Overview](https://learn.microsoft.com/windows/security/threat-protection/group-policy/group-policy-overview)
- [AppLocker Overview](https://learn.microsoft.com/windows/security/threat-protection/windows-defender-application-control/applocker/applocker-overview)
- [Registry Hives](https://learn.microsoft.com/windows/win32/sysinfo/registry-hives)

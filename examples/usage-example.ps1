# Example: Using the Group Policy Configuration Module

# Import the module
Import-Module 'C:\GroupPolicyConfiguration'

# Example 1: Apply policies from JSON file
Write-Host "Example 1: Apply policies from JSON file"
Set-GroupPolicyConfiguration -JsonPath 'C:\GroupPolicyConfiguration\examples\security-baseline.json' -Verbose

# Example 2: Apply policies from hashtable
Write-Host "`nExample 2: Apply policies from hashtable"
$CustomPolicies = @{
    'HKLM:\Software\Policies\Microsoft\Windows\Update' = @{
        'AutoRebootWithLoggedOnUsers' = @{ Value = 0; Type = 'DWord' }
    }
}
Set-GroupPolicyConfiguration -PolicySettings $CustomPolicies -Verbose

# Example 3: Merge JSON file with additional hashtable policies
Write-Host "`nExample 3: Merge JSON with hashtable"
$AdditionalPolicies = @{
    'HKLM:\Software\Custom\App' = @{
        'Setting1' = 1
    }
}
Set-GroupPolicyConfiguration -JsonPath 'C:\GroupPolicyConfiguration\examples\security-baseline.json' -PolicySettings $AdditionalPolicies -Verbose

# Example 4: Configure Defender
Write-Host "`nExample 4: Configure Windows Defender"
Set-WindowsDefender -RealTimeProtectionEnabled $true -CloudProtectionEnabled $true -ScheduledScansEnabled $true -ScheduledScanDay Daily -Verbose

# Example 5: Configure Firewall
Write-Host "`nExample 5: Configure Windows Firewall"
$DomainProfile = @{
    'Enabled' = $true
    'DefaultInboundAction' = 'Block'
    'DefaultOutboundAction' = 'Allow'
}

$InboundRule = @{
    'Name' = 'AllowSSH'
    'DisplayName' = 'Allow SSH (Port 22)'
    'Protocol' = 'TCP'
    'LocalPort' = 22
    'Action' = 'Allow'
}

Set-WindowsFirewall -DomainProfile $DomainProfile -InboundRules @($InboundRule) -Verbose

# Example 6: Enable Windows Features
Write-Host "`nExample 6: Enable Windows Features"
Set-WindowsFeatures -EnableFeatures @('Hyper-V', 'Containers') -Verbose

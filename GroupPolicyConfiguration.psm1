# Group Policy Configuration Module
# Loads all public and private functions

# Dot-source private functions first
Get-ChildItem -Path "$PSScriptRoot\private\main\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

# Dot-source public functions
Get-ChildItem -Path "$PSScriptRoot\public\*.ps1" -ErrorAction SilentlyContinue | ForEach-Object {
    . $_.FullName
}

# Export functions
Export-ModuleMember -Function @(
    'Set-GroupPolicyConfiguration',
    'Set-WindowsDefender',
    'Set-WindowsFirewall',
    'Set-WindowsFeatures'
)

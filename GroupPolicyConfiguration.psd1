@{
    RootModule = 'GroupPolicyConfiguration.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d'
    Author = 'Group Policy Module'
    Description = 'Standalone module for Group Policy configuration, AppLocker rules, and ADMX policies with JSON file support'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-GroupPolicyConfiguration',
        'Set-WindowsDefender',
        'Set-WindowsFirewall',
        'Set-WindowsFeatures',
        'Set-AppLockerRules',
        'Set-ADMXPolicies'
    )
}

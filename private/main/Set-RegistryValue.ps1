function Set-RegistryValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Value,

        [Parameter()]
        [ValidateSet('String', 'DWord', 'ExpandString', 'Binary', 'MultiString')]
        [string]$PropertyType = 'String',

        [Parameter()]
        [switch]$OfflineRegistry
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    if ($OfflineRegistry) {
        $RegistryTypeMap = @{
            'String'       = 'REG_SZ'
            'DWord'        = 'REG_DWORD'
            'ExpandString' = 'REG_EXPAND_SZ'
            'Binary'       = 'REG_BINARY'
            'MultiString'  = 'REG_MULTI_SZ'
        }
        
        $RegType = $RegistryTypeMap[$PropertyType]
        $RegValue = $Value
        if ($PropertyType -eq 'DWord') {
            $RegValue = [uint32]$Value
        }

        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting offline registry: $Path\$Name = $RegValue ($PropertyType)"
        
        $null = & reg add "$Path" /v "$Name" /t "$RegType" /d "$RegValue" /f 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Registry value set successfully (offline)"
        } else {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set registry value (offline): $Path\$Name"
        }
    } else {
        try {
            if (-not (Test-Path -Path $Path)) {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Creating registry path: $Path"
                $null = New-Item -Path $Path -Force -ErrorAction SilentlyContinue
            }

            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting online registry: $Path\$Name = $Value ($PropertyType)"
            
            $PropertyTypeMap = @{
                'String'       = [Microsoft.Win32.RegistryValueKind]::String
                'DWord'        = [Microsoft.Win32.RegistryValueKind]::DWord
                'ExpandString' = [Microsoft.Win32.RegistryValueKind]::ExpandString
                'Binary'       = [Microsoft.Win32.RegistryValueKind]::Binary
                'MultiString'  = [Microsoft.Win32.RegistryValueKind]::MultiString
            }

            $RegistryValueKind = $PropertyTypeMap[$PropertyType]
            $null = Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $RegistryValueKind -Force -ErrorAction Stop
            
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Registry value set successfully (online)"
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set registry value: $_"
        }
    }

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

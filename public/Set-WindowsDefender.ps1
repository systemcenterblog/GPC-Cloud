function Set-WindowsDefender {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$RealTimeProtectionEnabled,

        [Parameter()]
        [bool]$CloudProtectionEnabled,

        [Parameter()]
        [bool]$ScheduledScansEnabled,

        [Parameter()]
        [ValidateRange(0, 23)]
        [int]$ScheduledScanTime = 2,

        [Parameter()]
        [ValidateSet('Never', 'Daily', 'Weekly', 'Monthly')]
        [string]$ScheduledScanDay = 'Daily'
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Configuring Windows Defender..."

    try {
        $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if (-not $DefenderStatus) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Windows Defender is not available on this system."
            return
        }
    } catch {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to access Windows Defender - $_"
        return
    }

    $SettingsApplied = 0
    $SettingsFailed = 0

    if ($PSBoundParameters.ContainsKey('RealTimeProtectionEnabled')) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting Real-Time Protection to: $RealTimeProtectionEnabled"
            Set-MpPreference -DisableRealtimeMonitoring $(-not $RealTimeProtectionEnabled) -ErrorAction Stop
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Real-Time Protection: $RealTimeProtectionEnabled"
            $SettingsApplied++
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set Real-Time Protection - $_"
            $SettingsFailed++
        }
    }

    if ($PSBoundParameters.ContainsKey('CloudProtectionEnabled')) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting Cloud Protection to: $CloudProtectionEnabled"
            Set-MpPreference -MAPSReporting $(if ($CloudProtectionEnabled) { 2 } else { 0 }) -ErrorAction Stop
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Cloud Protection: $CloudProtectionEnabled"
            $SettingsApplied++
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set Cloud Protection - $_"
            $SettingsFailed++
        }
    }

    if ($PSBoundParameters.ContainsKey('ScheduledScansEnabled')) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting Scheduled Scans to: $ScheduledScansEnabled"
            
            if ($ScheduledScansEnabled) {
                $ScanDay = switch ($ScheduledScanDay) {
                    'Daily' { 0 }
                    'Weekly' { 1 }
                    'Monthly' { 2 }
                    default { 0 }
                }
                Set-MpPreference -ScanScheduleDay $ScanDay -ScanScheduleQuickScanTime $ScheduledScanTime -ErrorAction Stop
                Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Scheduled Scans: Enabled ($ScheduledScanDay at $($ScheduledScanTime):00)"
            } else {
                Set-MpPreference -DisableScheduledScanning $true -ErrorAction Stop
                Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Scheduled Scans: Disabled"
            }
            $SettingsApplied++
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to set Scheduled Scans - $_"
            $SettingsFailed++
        }
    }

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Windows Defender Configuration Complete: $SettingsApplied configured, $SettingsFailed failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

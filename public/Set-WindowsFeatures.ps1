function Set-WindowsFeatures {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$EnableFeatures,

        [Parameter()]
        [string[]]$DisableFeatures
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Configuring Windows Features..."

    $FeaturesApplied = 0
    $FeaturesFailed = 0

    if ($EnableFeatures) {
        foreach ($Feature in $EnableFeatures) {
            try {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Enabling feature: $Feature"
                
                $FeatureState = Get-WindowsOptionalFeature -FeatureName $Feature -Online -ErrorAction SilentlyContinue
                if ($FeatureState.State -ne 'Enabled') {
                    Enable-WindowsOptionalFeature -FeatureName $Feature -Online -NoRestart -WarningAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Feature enabled: $Feature"
                    $FeaturesApplied++
                } else {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Feature already enabled: $Feature"
                }
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to enable feature $Feature - $_"
                $FeaturesFailed++
            }
        }
    }

    if ($DisableFeatures) {
        foreach ($Feature in $DisableFeatures) {
            try {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Disabling feature: $Feature"
                
                $FeatureState = Get-WindowsOptionalFeature -FeatureName $Feature -Online -ErrorAction SilentlyContinue
                if ($FeatureState.State -eq 'Enabled') {
                    Disable-WindowsOptionalFeature -FeatureName $Feature -Online -NoRestart -WarningAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Feature disabled: $Feature"
                    $FeaturesApplied++
                } else {
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Feature already disabled: $Feature"
                }
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to disable feature $Feature - $_"
                $FeaturesFailed++
            }
        }
    }

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Windows Features Configuration Complete: $FeaturesApplied features modified, $FeaturesFailed failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

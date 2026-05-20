function Set-WindowsFirewall {
    [CmdletBinding()]
    param (
        [Parameter()]
        [hashtable]$DomainProfile,

        [Parameter()]
        [hashtable]$PrivateProfile,

        [Parameter()]
        [hashtable]$PublicProfile,

        [Parameter()]
        [object[]]$InboundRules,

        [Parameter()]
        [object[]]$OutboundRules
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Configuring Windows Firewall..."

    $RulesApplied = 0
    $RulesFailed = 0

    @{
        'Domain' = $DomainProfile
        'Private' = $PrivateProfile
        'Public' = $PublicProfile
    }.GetEnumerator() | Where-Object { $_.Value } | ForEach-Object {
        $ProfileName = $_.Key
        $ProfileSettings = $_.Value

        foreach ($Setting in $ProfileSettings.Keys) {
            try {
                $Value = $ProfileSettings[$Setting]
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting firewall profile $ProfileName : $Setting = $Value"
                
                $CmdParams = @{ Name = $ProfileName }
                $CmdParams[$Setting] = $Value
                
                Set-NetFirewallProfile @CmdParams -ErrorAction Stop
                Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Firewall $ProfileName profile: $Setting = $Value"
                $RulesApplied++
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to configure firewall profile $ProfileName : $Setting - $_"
                $RulesFailed++
            }
        }
    }

    if ($InboundRules) {
        foreach ($Rule in $InboundRules) {
            try {
                if ($Rule -is [hashtable]) {
                    $RuleName = $Rule['Name'] ?? $Rule['DisplayName']
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Adding inbound rule: $RuleName"
                    
                    $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                    if ($ExistingRule) {
                        Remove-NetFirewallRule -DisplayName $RuleName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    }
                    
                    New-NetFirewallRule @Rule -Direction Inbound -ErrorAction Stop | Out-Null
                    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Inbound rule added: $RuleName"
                    $RulesApplied++
                }
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to add inbound rule - $_"
                $RulesFailed++
            }
        }
    }

    if ($OutboundRules) {
        foreach ($Rule in $OutboundRules) {
            try {
                if ($Rule -is [hashtable]) {
                    $RuleName = $Rule['Name'] ?? $Rule['DisplayName']
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Adding outbound rule: $RuleName"
                    
                    $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                    if ($ExistingRule) {
                        Remove-NetFirewallRule -DisplayName $RuleName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    }
                    
                    New-NetFirewallRule @Rule -Direction Outbound -ErrorAction Stop | Out-Null
                    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Outbound rule added: $RuleName"
                    $RulesApplied++
                }
            } catch {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to add outbound rule - $_"
                $RulesFailed++
            }
        }
    }

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Windows Firewall Configuration Complete: $RulesApplied configured, $RulesFailed failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

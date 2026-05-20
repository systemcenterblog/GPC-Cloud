function Set-AppLockerRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RulesXml,

        [Parameter()]
        [ValidateSet('Exe', 'Dll', 'Script', 'Appx', 'Msi')]
        [string[]]$CollectionTypes = @('Exe', 'Dll', 'Script', 'Appx', 'Msi')
    )

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    Write-Host -ForegroundColor Cyan "[$(Get-Date -format s)] Setting AppLocker Rules..."

    try {
        # Validate XML format
        $xmlDocument = New-Object System.Xml.XmlDocument
        $xmlDocument.LoadXml($RulesXml) | Out-Null
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] XML validation passed"
    } catch {
        Write-Error "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invalid XML format: $_"
        return
    }

    $RuleCount = 0
    $FailureCount = 0

    foreach ($CollectionType in $CollectionTypes) {
        try {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Checking AppLocker module availability..."
            
            if (-not (Get-Command -Name Set-AppLockerPolicy -ErrorAction SilentlyContinue)) {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] AppLocker cmdlets not available. Import AppLocker module first."
                $FailureCount++
                continue
            }

            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Applying AppLocker rules for collection type: $CollectionType"
            
            # Parse rules from XML for this collection type
            $rules = $xmlDocument.SelectNodes("//FilePublisherRule[@Type='$CollectionType'] | //PathRule[@Type='$CollectionType'] | //FileHashRule[@Type='$CollectionType'] | //NetworkShareRule[@Type='$CollectionType']")
            
            if ($rules.Count -gt 0) {
                # Create AppLocker policy object from XML
                $appLockerPolicy = New-Object -TypeName 'AppLocker.Policy' -ArgumentList $RulesXml
                
                if ($null -ne $appLockerPolicy) {
                    Set-AppLockerPolicy -AppLockerPolicy $appLockerPolicy -Confirm:$false -ErrorAction Stop
                    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] AppLocker rules applied for $CollectionType"
                    $RuleCount += $rules.Count
                } else {
                    Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to parse AppLocker policy from XML for $CollectionType"
                    $FailureCount++
                }
            } else {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No rules found for collection type: $CollectionType"
            }
        } catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Failed to apply AppLocker rules for $CollectionType`: $_"
            $FailureCount++
        }
    }

    Write-Host -ForegroundColor Green "[$(Get-Date -format s)] AppLocker Rules Complete: $RuleCount applied, $FailureCount failures"

    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
}

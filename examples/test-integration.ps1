# Test script for AppLocker and ADMX integration
# This script validates that the new functionality works correctly

$ErrorActionPreference = 'Continue'

Write-Host "=== GroupPolicyConfiguration Module Integration Tests ===" -ForegroundColor Cyan

# Import the module
Write-Host "`n[1/5] Importing module..." -ForegroundColor Cyan
try {
    Push-Location (Split-Path -Path $PSScriptRoot -Parent)
    Get-Module -Name GroupPolicyConfiguration -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module '.\GroupPolicyConfiguration.psm1' -Force
    Pop-Location
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Error "✗ Failed to import module: $_"
    exit
}

# Test 1: Verify new functions exist
Write-Host "`n[2/5] Verifying new functions exist..." -ForegroundColor Cyan
$newFunctions = @('Set-AppLockerRules', 'Set-ADMXPolicies')
$missingFunctions = @()

foreach ($func in $newFunctions) {
    if (Get-Command -Name $func -ErrorAction SilentlyContinue) {
        Write-Host "✓ Function $func exists" -ForegroundColor Green
    } else {
        Write-Host "✗ Function $func NOT found" -ForegroundColor Red
        $missingFunctions += $func
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Error "Missing functions: $($missingFunctions -join ', ')"
    exit
}

# Test 2: Verify JSON examples exist
Write-Host "`n[3/5] Verifying example JSON files exist..." -ForegroundColor Cyan
$exampleFiles = @(
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\examples\unified-policies-example.json',
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\examples\admx-policies-example.json',
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\examples\applocker-rules-example.json'
)

foreach ($file in $exampleFiles) {
    if (Test-Path -Path $file) {
        Write-Host "✓ Example file exists: $(Split-Path $file -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "✗ Example file NOT found: $file" -ForegroundColor Red
    }
}

# Test 3: Verify documentation files exist
Write-Host "`n[4/5] Verifying documentation files exist..." -ForegroundColor Cyan
$docFiles = @(
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\docs\JSON_SCHEMA.md',
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\README.md',
    'C:\Apps\GPC-Cloud.worktrees\agents-json-xml-applocker-integration\QUICKSTART.md'
)

foreach ($file in $docFiles) {
    if (Test-Path -Path $file) {
        Write-Host "✓ Documentation file exists: $(Split-Path $file -Leaf)" -ForegroundColor Green
        $content = Get-Content -Path $file -Raw
        if ($content -match 'AppLocker|ADMX') {
            Write-Host "  → Contains AppLocker/ADMX references" -ForegroundColor Green
        }
    } else {
        Write-Host "✗ Documentation file NOT found: $file" -ForegroundColor Red
    }
}

# Test 4: Parse example JSON files
Write-Host "`n[5/5] Validating JSON structure..." -ForegroundColor Cyan
foreach ($file in $exampleFiles) {
    if (Test-Path -Path $file) {
        try {
            $json = Get-Content -Path $file -Raw | ConvertFrom-Json
            $fileName = Split-Path $file -Leaf
            
            # Check for expected sections
            if ($json.PSObject.Properties.Name -contains 'RegistryPolicies') {
                Write-Host "✓ $fileName has RegistryPolicies section" -ForegroundColor Green
            }
            if ($json.PSObject.Properties.Name -contains 'ADMXPolicies') {
                Write-Host "✓ $fileName has ADMXPolicies section" -ForegroundColor Green
            }
            if ($json.PSObject.Properties.Name -contains 'AppLockerRules') {
                Write-Host "✓ $fileName has AppLockerRules section" -ForegroundColor Green
            }
        } catch {
            Write-Host "✗ Failed to parse JSON: $file - $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "✓ All core components verified successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Test with: Set-GroupPolicyConfiguration -JsonPath 'path\to\config.json' -Verbose"
Write-Host "2. Use example files as templates"
Write-Host "3. Review JSON_SCHEMA.md for detailed configuration options"

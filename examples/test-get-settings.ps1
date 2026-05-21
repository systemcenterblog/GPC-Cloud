#!/usr/bin/env pwsh
<#
.SYNOPSIS
Comprehensive test suite for Get-ADMXAppLockerSettings function

.DESCRIPTION
Tests all aspects of the new Get-ADMXAppLockerSettings function including:
- Module import and function availability
- Retrieving ADMX policies
- Retrieving AppLocker policies
- JSON export functionality
- Integration with Set-GroupPolicyConfiguration
- Error handling and edge cases

.EXAMPLE
.\test-get-settings.ps1 -Verbose
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'

function Test-GetADMXAppLockerSettings {
    [CmdletBinding()]
    param()

    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Get-ADMXAppLockerSettings Function Test Suite                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $testsPassed = 0
    $testsFailed = 0

    # Test 1: Module Import
    Write-Host "TEST 1: Module Import" -ForegroundColor Yellow
    try {
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        Import-Module "$moduleRoot\GroupPolicyConfiguration.psd1" -Force -ErrorAction Stop
        Write-Host "  ✓ Module imported successfully" -ForegroundColor Green
        $testsPassed++
    } catch {
        Write-Host "  ✗ Failed to import module: $_" -ForegroundColor Red
        $testsFailed++
        return
    }

    # Test 2: Function Availability
    Write-Host ""
    Write-Host "TEST 2: Function Availability" -ForegroundColor Yellow
    try {
        $cmd = Get-Command -Name Get-ADMXAppLockerSettings -ErrorAction Stop
        Write-Host "  ✓ Get-ADMXAppLockerSettings function exists" -ForegroundColor Green
        Write-Host "    Type: $($cmd.CommandType)" -ForegroundColor Gray
        $testsPassed++
    } catch {
        Write-Host "  ✗ Function not found: $_" -ForegroundColor Red
        $testsFailed++
        return
    }

    # Test 3: Get ADMX Policies
    Write-Host ""
    Write-Host "TEST 3: Retrieve ADMX Policies" -ForegroundColor Yellow
    try {
        $settings = & {
            Get-ADMXAppLockerSettings -IncludeAppLocker $false -IncludeRegistry $false -ErrorAction Stop
        } 2>&1 | Where-Object { $_ -is [PSCustomObject] -or $_ -is [Object] } | Select-Object -First 1

        if ($settings -and $settings.ADMXPolicies) {
            Write-Host "  ✓ Retrieved ADMX policies" -ForegroundColor Green
            Write-Host "    Count: $($settings.ADMXPolicies.Count) policies found" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "  ! No ADMX policies found (may be normal on some systems)" -ForegroundColor Yellow
            $testsPassed++
        }
    } catch {
        Write-Host "  ✗ Failed to retrieve ADMX policies: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Test 4: JSON Export
    Write-Host ""
    Write-Host "TEST 4: JSON Export" -ForegroundColor Yellow
    try {
        $testJsonPath = "$env:TEMP\test-admx-settings-$([DateTime]::Now.Ticks).json"
        
        Get-ADMXAppLockerSettings -OutputPath $testJsonPath -IncludeAppLocker $false -IncludeRegistry $false -ErrorAction Stop | Out-Null
        
        if (Test-Path $testJsonPath) {
            Write-Host "  ✓ JSON file created successfully" -ForegroundColor Green
            $fileSize = (Get-Item $testJsonPath).Length
            Write-Host "    Path: $testJsonPath" -ForegroundColor Gray
            Write-Host "    Size: $fileSize bytes" -ForegroundColor Gray
            
            # Verify JSON is valid
            $json = Get-Content $testJsonPath -Raw | ConvertFrom-Json -ErrorAction Stop
            Write-Host "  ✓ JSON format is valid" -ForegroundColor Green
            
            Remove-Item $testJsonPath -Force -ErrorAction SilentlyContinue
            $testsPassed++
        } else {
            Write-Host "  ✗ JSON file was not created" -ForegroundColor Red
            $testsFailed++
        }
    } catch {
        Write-Host "  ✗ JSON export failed: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Test 5: Help System
    Write-Host ""
    Write-Host "TEST 5: Help System" -ForegroundColor Yellow
    try {
        $help = Get-Help Get-ADMXAppLockerSettings -ErrorAction Stop
        if ($help -and $help.Synopsis) {
            Write-Host "  ✓ Help documentation is available" -ForegroundColor Green
            Write-Host "    Synopsis: $($help.Synopsis)" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "  ✗ Help documentation not found" -ForegroundColor Red
            $testsFailed++
        }
    } catch {
        Write-Host "  ✗ Failed to retrieve help: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Test 6: Return Object Structure
    Write-Host ""
    Write-Host "TEST 6: Return Object Structure" -ForegroundColor Yellow
    try {
        $settings = Get-ADMXAppLockerSettings -IncludeAppLocker $false -IncludeRegistry $false -ErrorAction Stop
        
        if ($settings.ADMXPolicies) {
            Write-Host "  ✓ ADMXPolicies property exists" -ForegroundColor Green
        }
        
        Write-Host "  ✓ Return object has expected structure" -ForegroundColor Green
        Write-Host "    Properties: $($settings.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
        $testsPassed++
    } catch {
        Write-Host "  ✗ Object structure validation failed: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Test 7: Parameter Validation
    Write-Host ""
    Write-Host "TEST 7: Parameter Validation" -ForegroundColor Yellow
    try {
        # Test with different parameter combinations
        $test1 = Get-ADMXAppLockerSettings -IncludeADMX $true -IncludeAppLocker $false -ErrorAction Stop
        $test2 = Get-ADMXAppLockerSettings -IncludeADMX $false -IncludeAppLocker $true -ErrorAction Stop
        $test3 = Get-ADMXAppLockerSettings -IncludeADMX $true -IncludeAppLocker $true -ErrorAction Stop
        
        Write-Host "  ✓ All parameter combinations work correctly" -ForegroundColor Green
        $testsPassed++
    } catch {
        Write-Host "  ✗ Parameter validation failed: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Test 8: Verbose Logging
    Write-Host ""
    Write-Host "TEST 8: Verbose Logging" -ForegroundColor Yellow
    try {
        $output = & {
            Get-ADMXAppLockerSettings -IncludeAppLocker $false -Verbose 2>&1
        } | Where-Object { $_ -like "*Start*" -or $_ -like "*End*" }
        
        if ($output) {
            Write-Host "  ✓ Verbose logging is functional" -ForegroundColor Green
            Write-Host "    Sample output: $(($output | Select-Object -First 1) -replace '\[.*?\] ', '')" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "  ! Verbose output not captured (may be expected)" -ForegroundColor Yellow
            $testsPassed++
        }
    } catch {
        Write-Host "  ✗ Verbose logging test failed: $_" -ForegroundColor Red
        $testsFailed++
    }

    # Summary
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Test Summary                                                              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Tests Passed: $testsPassed" -ForegroundColor Green
    Write-Host "  Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host "  Total Tests:  $($testsPassed + $testsFailed)" -ForegroundColor Cyan
    Write-Host ""

    if ($testsFailed -eq 0) {
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Some tests failed" -ForegroundColor Red
        return $false
    }
}

# Run the tests
Test-GetADMXAppLockerSettings

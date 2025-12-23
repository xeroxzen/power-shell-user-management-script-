#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates PowerShell scripts for syntax, best practices, and potential issues.
.DESCRIPTION
    This script performs comprehensive validation of PowerShell scripts without requiring
    Windows-specific features. It can be run on Linux, macOS, or Windows.
.NOTES
    Can be run locally before pushing to repository or deploying to Windows environment.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$InstallDependencies,

    [Parameter(Mandatory=$false)]
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

# Color output functions
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Failure { param([string]$Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param([string]$Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param([string]$Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }

# Test results
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Failure "PowerShell 7.0 or later required. Current: $psVersion"
        Write-Info "Install from: https://aka.ms/powershell"
        return $false
    }
    Write-Success "PowerShell version: $psVersion"

    # Check for PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        if ($InstallDependencies) {
            Write-Info "Installing PSScriptAnalyzer..."
            Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -Repository PSGallery
            Write-Success "PSScriptAnalyzer installed"
        }
        else {
            Write-Warning "PSScriptAnalyzer not found. Run with -InstallDependencies to install."
            Write-Info "Or install manually: Install-Module -Name PSScriptAnalyzer -Force"
            return $false
        }
    }
    else {
        Write-Success "PSScriptAnalyzer is installed"
    }

    return $true
}

function Test-ScriptSyntax {
    param([string]$ScriptPath)

    Write-Info "Testing syntax: $ScriptPath"

    try {
        $content = Get-Content -Path $ScriptPath -Raw
        $errors = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)

        if ($errors) {
            Write-Failure "Syntax errors found in $ScriptPath"
            $errors | ForEach-Object {
                Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red
            }
            $script:TestResults.Failed++
            return $false
        }

        Write-Success "Syntax validation passed: $ScriptPath"
        $script:TestResults.Passed++
        return $true
    }
    catch {
        Write-Failure "Failed to parse $ScriptPath : $_"
        $script:TestResults.Failed++
        return $false
    }
}

function Test-ScriptAnalyzer {
    param([string]$ScriptPath)

    Write-Info "Running PSScriptAnalyzer: $ScriptPath"

    try {
        $results = Invoke-ScriptAnalyzer -Path $ScriptPath -Severity @('Error', 'Warning', 'Information')

        if (-not $results) {
            Write-Success "PSScriptAnalyzer: No issues found"
            $script:TestResults.Passed++
            return $true
        }

        # Separate by severity
        $errors = $results | Where-Object Severity -eq 'Error'
        $warnings = $results | Where-Object Severity -eq 'Warning'
        $info = $results | Where-Object Severity -eq 'Information'

        if ($errors) {
            Write-Failure "PSScriptAnalyzer found $($errors.Count) error(s)"
            $errors | ForEach-Object {
                Write-Host "  [ERROR] Line $($_.Line): $($_.Message)" -ForegroundColor Red
                Write-Host "    Rule: $($_.RuleName)" -ForegroundColor Gray
            }
            $script:TestResults.Failed++
        }

        if ($warnings) {
            Write-Warning "PSScriptAnalyzer found $($warnings.Count) warning(s)"
            $warnings | ForEach-Object {
                Write-Host "  [WARN] Line $($_.Line): $($_.Message)" -ForegroundColor Yellow
                Write-Host "    Rule: $($_.RuleName)" -ForegroundColor Gray
            }
            $script:TestResults.Warnings += $warnings.Count
        }

        if ($info -and $Verbose) {
            Write-Info "PSScriptAnalyzer found $($info.Count) informational message(s)"
            $info | ForEach-Object {
                Write-Host "  [INFO] Line $($_.Line): $($_.Message)" -ForegroundColor Cyan
            }
        }

        return (-not $errors)
    }
    catch {
        Write-Failure "PSScriptAnalyzer failed: $_"
        $script:TestResults.Failed++
        return $false
    }
}

function Test-ScriptParameters {
    param([string]$ScriptPath)

    Write-Info "Validating parameters: $ScriptPath"

    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $ScriptPath,
            [ref]$null,
            [ref]$null
        )

        $paramBlock = $ast.ParamBlock

        if (-not $paramBlock) {
            Write-Warning "No parameter block found in $ScriptPath"
            $script:TestResults.Warnings++
            return $true
        }

        $parameters = $paramBlock.Parameters
        Write-Success "Found $($parameters.Count) parameters"

        foreach ($param in $parameters) {
            $paramName = $param.Name.VariablePath.UserPath
            $hasValidation = $param.Attributes | Where-Object { $_.TypeName.Name -like 'Validate*' }
            $isMandatory = $param.Attributes | Where-Object { $_.NamedArguments.ArgumentName -eq 'Mandatory' -and $_.NamedArguments.Argument.Value -eq $true }

            if ($Verbose) {
                $validationInfo = if ($hasValidation) { " [Validated]" } else { "" }
                $mandatoryInfo = if ($isMandatory) { " [Mandatory]" } else { "" }
                Write-Host "  - $paramName$mandatoryInfo$validationInfo" -ForegroundColor Gray
            }
        }

        $script:TestResults.Passed++
        return $true
    }
    catch {
        Write-Failure "Parameter validation failed: $_"
        $script:TestResults.Failed++
        return $false
    }
}

function Test-ScriptFunctions {
    param([string]$ScriptPath)

    Write-Info "Analyzing functions: $ScriptPath"

    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $ScriptPath,
            [ref]$null,
            [ref]$null
        )

        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)

        if (-not $functions) {
            Write-Info "No functions found in $ScriptPath"
            return $true
        }

        Write-Success "Found $($functions.Count) functions"

        foreach ($func in $functions) {
            $funcName = $func.Name
            $hasHelp = $func.Body.ParamBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.Language.AttributeAst] -and $_.TypeName.Name -eq 'CmdletBinding' }

            if ($Verbose) {
                Write-Host "  - $funcName" -ForegroundColor Gray
            }

            # Check if function follows Verb-Noun naming
            if ($funcName -notmatch '^[A-Z][a-z]+-[A-Z][a-z]+') {
                Write-Warning "Function '$funcName' doesn't follow Verb-Noun naming convention"
                $script:TestResults.Warnings++
            }
        }

        $script:TestResults.Passed++
        return $true
    }
    catch {
        Write-Failure "Function analysis failed: $_"
        $script:TestResults.Failed++
        return $false
    }
}

function Test-ScriptRequirements {
    param([string]$ScriptPath)

    Write-Info "Checking script requirements: $ScriptPath"

    try {
        $content = Get-Content -Path $ScriptPath -Raw

        # Check for #Requires statements
        $requiresStatements = [regex]::Matches($content, '(?m)^#Requires\s+-(.+)$')

        if ($requiresStatements.Count -eq 0) {
            Write-Warning "No #Requires statements found. Consider adding version/module requirements."
            $script:TestResults.Warnings++
        }
        else {
            Write-Success "Found $($requiresStatements.Count) requirement(s)"
            foreach ($req in $requiresStatements) {
                if ($Verbose) {
                    Write-Host "  - #Requires $($req.Groups[1].Value)" -ForegroundColor Gray
                }
            }
        }

        $script:TestResults.Passed++
        return $true
    }
    catch {
        Write-Failure "Requirements check failed: $_"
        $script:TestResults.Failed++
        return $false
    }
}

function Test-ScriptHelp {
    param([string]$ScriptPath)

    Write-Info "Checking script documentation: $ScriptPath"

    try {
        $content = Get-Content -Path $ScriptPath -Raw

        # Check for comment-based help
        if ($content -match '(?s)<#.*?\.SYNOPSIS.*?#>') {
            Write-Success "Comment-based help found"
            $script:TestResults.Passed++
            return $true
        }
        else {
            Write-Warning "No comment-based help found. Consider adding .SYNOPSIS, .DESCRIPTION, etc."
            $script:TestResults.Warnings++
            return $true
        }
    }
    catch {
        Write-Failure "Help documentation check failed: $_"
        $script:TestResults.Failed++
        return $false
    }
}

# Main execution
function Start-Validation {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "PowerShell Script Validation Tool v1.0" -ForegroundColor Cyan
    Write-Host "================================================`n" -ForegroundColor Cyan

    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Failure "Prerequisites not met. Exiting."
        exit 1
    }

    Write-Host ""

    # Find scripts to validate
    $scripts = @(
        './Invoke-LocalAccountCleanup.ps1',
        './Test-RemoteConnectivity.ps1'
    )

    $scriptsToTest = $scripts | Where-Object { Test-Path $_ }

    if ($scriptsToTest.Count -eq 0) {
        Write-Failure "No scripts found to validate!"
        Write-Info "Expected files: $($scripts -join ', ')"
        exit 1
    }

    Write-Info "Found $($scriptsToTest.Count) script(s) to validate`n"

    # Run tests on each script
    foreach ($script in $scriptsToTest) {
        $scriptName = Split-Path $script -Leaf

        Write-Host "`n================================================" -ForegroundColor Yellow
        Write-Host "Validating: $scriptName" -ForegroundColor Yellow
        Write-Host "================================================`n" -ForegroundColor Yellow

        Test-ScriptSyntax -ScriptPath $script
        Test-ScriptAnalyzer -ScriptPath $script
        Test-ScriptParameters -ScriptPath $script
        Test-ScriptFunctions -ScriptPath $script
        Test-ScriptRequirements -ScriptPath $script
        Test-ScriptHelp -ScriptPath $script

        Write-Host ""
    }

    # Summary
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "Validation Summary" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Passed:   " -NoNewline
    Write-Host $script:TestResults.Passed -ForegroundColor Green
    Write-Host "Failed:   " -NoNewline
    Write-Host $script:TestResults.Failed -ForegroundColor Red
    Write-Host "Warnings: " -NoNewline
    Write-Host $script:TestResults.Warnings -ForegroundColor Yellow
    Write-Host "================================================`n" -ForegroundColor Cyan

    if ($script:TestResults.Failed -gt 0) {
        Write-Failure "Validation FAILED with $($script:TestResults.Failed) error(s)"
        exit 1
    }
    elseif ($script:TestResults.Warnings -gt 0) {
        Write-Warning "Validation PASSED with $($script:TestResults.Warnings) warning(s)"
        exit 0
    }
    else {
        Write-Success "Validation PASSED - All tests successful!"
        exit 0
    }
}

# Run validation
Start-Validation

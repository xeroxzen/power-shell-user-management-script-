#Requires -Version 7.0
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Test connectivity and PowerShell remoting to target computers
.DESCRIPTION
    Validates that computers are online and PowerShell remoting is working before running cleanup.
    Enhanced version with PowerShell 7 support, credential handling, and performance optimizations.
.NOTES
    Version: 2.0
    Requires PowerShell 7.0+ for better performance and cross-platform compatibility
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^(OU|CN)=.+,DC=.+,DC=.+$')]
    [string]$TargetOU,

    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Scripts\Logs",

    [Parameter(Mandatory=$false)]
    [int]$ConnectionTimeout = 5
)

function Test-BulkConnectivity {
    param([string]$OU)

    Write-Host "`nTesting Connectivity for OU: $OU`n" -ForegroundColor Cyan

    try {
        # Query AD with credential support
        $adParams = @{
            Filter = '*'
            SearchBase = $OU
            Properties = @('Name', 'Enabled')
        }
        if ($Credential) {
            $adParams['Credential'] = $Credential
        }

        $computers = Get-ADComputer @adParams | Where-Object { $_.Enabled -eq $true }
        $totalCount = $computers.Count
        Write-Host "Found $totalCount enabled computers to test`n"

        # Use ArrayList for better performance
        $results = [System.Collections.ArrayList]::new()
        $currentCount = 0
        
        foreach ($computer in $computers) {
            $currentCount++
            Write-Progress -Activity "Testing Connectivity" `
                -Status "Testing $($computer.Name) ($currentCount of $totalCount)" `
                -PercentComplete (($currentCount / $totalCount) * 100)
            
            $result = [PSCustomObject]@{
                ComputerName = $computer.Name
                PingTest = 'Failed'
                PSRemoting = 'Failed'
                Error = $null
            }

            # Test Ping with timeout
            if (Test-Connection -ComputerName $computer.Name -Count 1 -TimeoutSeconds $ConnectionTimeout -Quiet) {
                $result.PingTest = 'Success'

                # Test PS Remoting with credential support
                try {
                    $sessionParams = @{
                        ComputerName = $computer.Name
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) {
                        $sessionParams['Credential'] = $Credential
                    }

                    $session = New-PSSession @sessionParams
                    $result.PSRemoting = 'Success'
                    Remove-PSSession -Session $session
                }
                catch {
                    $result.Error = $_.Exception.Message
                }
            }

            # Use ArrayList Add method instead of += operator
            [void]$results.Add($result)
        }
        
        Write-Progress -Activity "Testing Connectivity" -Completed
        
        # Summary
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "CONNECTIVITY TEST RESULTS" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Green
        
        $online = ($results | Where-Object { $_.PingTest -eq 'Success' }).Count
        $remoting = ($results | Where-Object { $_.PSRemoting -eq 'Success' }).Count
        
        Write-Host "Total Computers: $totalCount"
        Write-Host "Online: $online " -NoNewline
        Write-Host "($([Math]::Round(($online/$totalCount)*100,2))%)" -ForegroundColor $(if($online -eq $totalCount){'Green'}else{'Yellow'})
        Write-Host "PS Remoting OK: $remoting " -NoNewline
        Write-Host "($([Math]::Round(($remoting/$totalCount)*100,2))%)" -ForegroundColor $(if($remoting -eq $totalCount){'Green'}else{'Yellow'})
        
        # Failed computers
        $failed = $results | Where-Object { $_.PSRemoting -ne 'Success' }
        if ($failed.Count -gt 0) {
            Write-Host "`nComputers with Issues:" -ForegroundColor Red
            $failed | Format-Table ComputerName, PingTest, PSRemoting, Error -AutoSize
        }
        
        # Export results
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $reportFile = Join-Path $OutputPath "ConnectivityTest_$timestamp.csv"
        $results | Export-Csv -Path $reportFile -NoTypeInformation
        
        Write-Host "`nDetailed report saved to: " -NoNewline
        Write-Host $reportFile -ForegroundColor Yellow
        
        return $results
    }
    catch {
        Write-Error "Failed to test connectivity: $_"
        throw
    }
}

# Verify PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7.0 or later."
    Write-Host "Download PowerShell 7: https://aka.ms/powershell" -ForegroundColor Yellow
    exit 1
}

# Verify AD module
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "ActiveDirectory module is not installed. Please install RSAT tools."
    exit 1
}

# Create output directory if needed
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Run the test
Test-BulkConnectivity -OU $TargetOU
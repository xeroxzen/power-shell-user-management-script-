#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Displays an informative ASCII art banner for the Local Account Cleanup script.
.DESCRIPTION
    Shows a colorful banner with script information, tips, and quick start commands.
    Can be integrated into the main script or run standalone.
#>

function Show-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$SkipTips,

        [Parameter(Mandatory=$false)]
        [switch]$Minimal
    )

    # Clear screen for better presentation
    Clear-Host

    # Define color gradient for the banner
    $colors = @('Blue', 'Cyan', 'Green', 'Yellow', 'Magenta')

    if (-not $Minimal) {
        # Full ASCII art banner
        $banner = @"

 ██╗      ██████╗  ██████╗ █████╗ ██╗
 ██║     ██╔═══██╗██╔════╝██╔══██╗██║
 ██║     ██║   ██║██║     ███████║██║
 ██║     ██║   ██║██║     ██╔══██║██║
 ███████╗╚██████╔╝╚██████╗██║  ██║███████╗
 ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝

  █████╗  ██████╗ ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗
 ██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝
 ███████║██║     ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║
 ██╔══██║██║     ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║
 ██║  ██║╚██████╗╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║
 ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝

  ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗
 ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
 ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
 ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝
 ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║
  ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝

"@
        Write-Host $banner -ForegroundColor Cyan
    }

    # Script information
    Write-Host "                    " -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "                    " -NoNewline
    Write-Host "        v2.1 - Enhanced Edition        " -ForegroundColor Yellow
    Write-Host "                    " -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    🎯 " -NoNewline -ForegroundColor Green
    Write-Host "Automated Local User Account Management" -ForegroundColor White
    Write-Host "    🖥️  " -NoNewline -ForegroundColor Cyan
    Write-Host "Windows Domain Environments - AD Integration" -ForegroundColor White
    Write-Host "    ⚡ " -NoNewline -ForegroundColor Yellow
    Write-Host "Thread-Safe Parallel Processing" -ForegroundColor White
    Write-Host "    🔒 " -NoNewline -ForegroundColor Magenta
    Write-Host "Security Hardened - Backup Protected" -ForegroundColor White
    Write-Host ""
    Write-Host "                    " -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""

    if (-not $SkipTips) {
        # Tips and quick start
        Write-Host "  📋 Quick Start Commands:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    1. Test Connectivity First:" -ForegroundColor Yellow
        Write-Host "       " -NoNewline
        Write-Host "./Test-RemoteConnectivity.ps1 -TargetOU 'OU=Computers,DC=domain,DC=com'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "    2. Generate Report (Safe - No Changes):" -ForegroundColor Yellow
        Write-Host "       " -NoNewline
        Write-Host "./Invoke-LocalAccountCleanup.ps1 -TargetOU 'OU=Computers,DC=domain,DC=com' -Mode Report" -ForegroundColor Gray
        Write-Host ""
        Write-Host "    3. Disable Inactive Accounts:" -ForegroundColor Yellow
        Write-Host "       " -NoNewline
        Write-Host "./Invoke-LocalAccountCleanup.ps1 -TargetOU 'OU=Computers,DC=domain,DC=com' -Mode Disable" -ForegroundColor Gray
        Write-Host ""
        Write-Host "    4. Delete Old Profiles (After Review Period):" -ForegroundColor Yellow
        Write-Host "       " -NoNewline
        Write-Host "./Invoke-LocalAccountCleanup.ps1 -TargetOU 'OU=Computers,DC=domain,DC=com' -Mode DeleteProfiles" -ForegroundColor Gray
        Write-Host ""
        Write-Host "                    " -NoNewline
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  💡 Tips:" -ForegroundColor Cyan
        Write-Host "     • " -NoNewline -ForegroundColor Green
        Write-Host "Always run in Report mode first to preview changes" -ForegroundColor White
        Write-Host "     • " -NoNewline -ForegroundColor Green
        Write-Host "Test on small OU (5-10 computers) before full deployment" -ForegroundColor White
        Write-Host "     • " -NoNewline -ForegroundColor Green
        Write-Host "Protected accounts: GBPS, DefaultAccount, WDAGUtilityAccount, Most Recent User" -ForegroundColor White
        Write-Host "     • " -NoNewline -ForegroundColor Green
        Write-Host "Logs saved to: C:\Scripts\Logs\" -ForegroundColor White
        Write-Host "     • " -NoNewline -ForegroundColor Green
        Write-Host "Use -Force to skip confirmation prompts" -ForegroundColor White
        Write-Host ""
        Write-Host "                    " -NoNewline
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  📚 Documentation:" -ForegroundColor Cyan
        Write-Host "     • " -NoNewline -ForegroundColor Magenta
        Write-Host "Get-Help ./Invoke-LocalAccountCleanup.ps1 -Full" -ForegroundColor Gray
        Write-Host "     • " -NoNewline -ForegroundColor Magenta
        Write-Host "Read usage_guide.md for comprehensive instructions" -ForegroundColor Gray
        Write-Host "     • " -NoNewline -ForegroundColor Magenta
        Write-Host "See TESTING.md for validation and testing strategies" -ForegroundColor Gray
        Write-Host ""
        Write-Host "                    " -NoNewline
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  ⚡ Key Features (v2.1):" -ForegroundColor Cyan
        Write-Host "     ✅ Thread-safe parallel processing (10+ computers simultaneously)" -ForegroundColor Green
        Write-Host "     ✅ Automatic backup creation before destructive operations" -ForegroundColor Green
        Write-Host "     ✅ Early credential validation (fail-fast)" -ForegroundColor Green
        Write-Host "     ✅ Configurable retry delays and parallel threads" -ForegroundColor Green
        Write-Host "     ✅ Security hardening with restrictive ACLs on backups" -ForegroundColor Green
        Write-Host "     ✅ Enhanced error context for faster troubleshooting" -ForegroundColor Green
        Write-Host "     ✅ Real-time progress indicators" -ForegroundColor Green
        Write-Host ""
    }

    Write-Host "                    " -NoNewline
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Clear-Host
    Write-Host ""
}

# Alternative compact banner for script integration
function Show-CompactBanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Mode = 'Report',

        [Parameter(Mandatory=$false)]
        [string]$TargetOU,

        [Parameter(Mandatory=$false)]
        [int]$ComputerCount = 0
    )

    Write-Host ""
    Write-Host "  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
    Write-Host "LOCAL ACCOUNT CLEANUP v2.1" -NoNewline -ForegroundColor Yellow
    Write-Host " - Enhanced Edition         ║" -ForegroundColor Cyan
    Write-Host "  ╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║  Mode: " -NoNewline -ForegroundColor Cyan
    Write-Host ([string]$Mode).PadRight(54) -NoNewline -ForegroundColor $(
        switch ($Mode) {
            'Report' { 'Green' }
            'Disable' { 'Yellow' }
            'DeleteProfiles' { 'Red' }
            default { 'White' }
        }
    )
    Write-Host " ║" -ForegroundColor Cyan

    if ($TargetOU) {
        $ouDisplay = if ($TargetOU.Length -gt 48) { $TargetOU.Substring(0, 45) + "..." } else { $TargetOU }
        Write-Host "  ║  Target: " -NoNewline -ForegroundColor Cyan
        Write-Host $ouDisplay.PadRight(52) -NoNewline -ForegroundColor Gray
        Write-Host " ║" -ForegroundColor Cyan
    }

    if ($ComputerCount -gt 0) {
        Write-Host "  ║  Computers: " -NoNewline -ForegroundColor Cyan
        Write-Host ([string]$ComputerCount).PadRight(49) -NoNewline -ForegroundColor White
        Write-Host " ║" -ForegroundColor Cyan
    }

    Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Interactive menu banner
function Show-MenuBanner {
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Blue
    Write-Host "  │                                                                 │" -ForegroundColor Blue
    Write-Host "  │       " -NoNewline -ForegroundColor Blue
    Write-Host "🔧 LOCAL ACCOUNT CLEANUP TOOLKIT 🔧" -NoNewline -ForegroundColor Cyan
    Write-Host "               │" -ForegroundColor Blue
    Write-Host "  │                                                                 │" -ForegroundColor Blue
    Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  Select an operation:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    [1] " -NoNewline -ForegroundColor Cyan
    Write-Host "Test Connectivity" -NoNewline -ForegroundColor White
    Write-Host "          - Check if computers are online and accessible" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [2] " -NoNewline -ForegroundColor Cyan
    Write-Host "Generate Report" -NoNewline -ForegroundColor White
    Write-Host "            - Preview accounts without making changes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [3] " -NoNewline -ForegroundColor Cyan
    Write-Host "Disable Inactive Accounts" -NoNewline -ForegroundColor White
    Write-Host "  - Disable accounts meeting criteria" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [4] " -NoNewline -ForegroundColor Cyan
    Write-Host "Delete Old Profiles" -NoNewline -ForegroundColor White
    Write-Host "        - Remove profiles after retention period" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [5] " -NoNewline -ForegroundColor Cyan
    Write-Host "View Documentation" -NoNewline -ForegroundColor White
    Write-Host "        - Open help and usage guide" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [Q] " -NoNewline -ForegroundColor Red
    Write-Host "Quit" -ForegroundColor White
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Enter your choice: " -NoNewline -ForegroundColor Yellow
}

# Export functions if used as module
Export-ModuleMember -Function Show-Banner, Show-CompactBanner, Show-MenuBanner

# If run directly, show the banner
if ($MyInvocation.InvocationName -ne '.') {
    Show-Banner
}

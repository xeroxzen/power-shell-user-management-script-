# ASCII Art Banner System

Professional ASCII art banners for the Local Account Cleanup toolkit.

---

## Files Created

- `Show-Banner.ps1` - Interactive banner system with multiple display modes
- `banner.txt` - Raw ASCII art for reference

---

## Quick Test

### See the Full Banner:
```bash
pwsh -File ./Show-Banner.ps1
```

### See Compact Banner:
```powershell
pwsh -Command {
    . ./Show-Banner.ps1
    Show-CompactBanner -Mode "Report" -TargetOU "OU=Computers,DC=domain,DC=com" -ComputerCount 150
}
```

### See Menu Banner:
```powershell
pwsh -Command {
    . ./Show-Banner.ps1
    Show-MenuBanner
}
```

---

## Banner Styles

### 1. Full Banner (Show-Banner)
**When to use:** Script startup, documentation, presentations

**Features:**
- Large ASCII art logo
- Version information
- Quick start commands
- Tips and best practices
- Documentation links
- Key features list
- "Press any key to continue" prompt

```powershell
Show-Banner
# or with options
Show-Banner -SkipTips    # Skip the tips section
Show-Banner -Minimal     # Compact version without large ASCII
```

---

### 2. Compact Banner (Show-CompactBanner)
**When to use:** During script execution, progress updates

**Features:**
- Box-drawn border
- Current mode display (color-coded)
- Target OU
- Computer count
- Minimal space usage

```powershell
Show-CompactBanner -Mode "Disable" -TargetOU "OU=Workstations,DC=corp,DC=com" -ComputerCount 250
```

**Color Coding:**
- `Report` mode: Green (safe, no changes)
- `Disable` mode: Yellow (caution, makes changes)
- `DeleteProfiles` mode: Red (destructive, permanent)

---

### 3. Menu Banner (Show-MenuBanner)
**When to use:** Interactive mode, user selection

**Features:**
- Numbered menu options
- Operation descriptions
- Color-coded choices
- Clean, professional layout

```powershell
Show-MenuBanner
$choice = Read-Host
```

---

## Integration Examples

### Add to Main Script (Invoke-LocalAccountCleanup.ps1)

**Option 1: Show at startup (before parameter processing)**

Add near the top of the script, after the param block:

```powershell
# After param block, before main execution
if (-not $Quiet) {
    $bannerPath = Join-Path $PSScriptRoot "Show-Banner.ps1"
    if (Test-Path $bannerPath) {
        . $bannerPath
        Show-CompactBanner -Mode $Mode -TargetOU $TargetOU
    }
}
```

**Option 2: Show in Start-AccountCleanup function**

Add at the beginning of the `Start-AccountCleanup` function:

```powershell
function Start-AccountCleanup {
    try {
        Initialize-Logging

        # Show compact banner
        $bannerPath = Join-Path $PSScriptRoot "Show-Banner.ps1"
        if (Test-Path $bannerPath) {
            . $bannerPath
            Show-CompactBanner -Mode $Script:Config.Mode -TargetOU $TargetOU
        }

        # ... rest of function
    }
}
```

---

### Add to Connectivity Test Script

Add at the beginning of `Test-BulkConnectivity` function:

```powershell
function Test-BulkConnectivity {
    param([string]$OU)

    # Show banner
    $bannerPath = Join-Path $PSScriptRoot "Show-Banner.ps1"
    if (Test-Path $bannerPath) {
        . $bannerPath
        Write-Host "  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║  " -NoNewline -ForegroundColor Cyan
        Write-Host "CONNECTIVITY TEST" -NoNewline -ForegroundColor Yellow
        Write-Host "                                          ║" -ForegroundColor Cyan
        Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
    }

    # ... rest of function
}
```

---

## Customization

### Change Colors

Edit the color values in `Show-Banner.ps1`:

```powershell
# Current colors
Write-Host $banner -ForegroundColor Cyan          # ASCII art
Write-Host "v2.1 - Enhanced Edition" -ForegroundColor Yellow  # Version
Write-Host "Quick Start Commands:" -ForegroundColor Cyan      # Headers

# Available colors:
# Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow
# Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
```

### Modify ASCII Art

The ASCII art can be regenerated using online tools:
- https://patorjk.com/software/taag/
- Font: "ANSI Shadow" or "Big"
- Text: "LOCAL ACCOUNT CLEANUP"

### Add Custom Tips

Edit the tips section in `Show-Banner`:

```powershell
Write-Host "   Tips:" -ForegroundColor Cyan
Write-Host "     • " -NoNewline -ForegroundColor Green
Write-Host "Your custom tip here" -ForegroundColor White
```

---

## Banner Output Examples

### Full Banner Output:
```

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

                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            v2.1 - Enhanced Edition
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Automated Local User Account Management
      Windows Domain Environments - AD Integration
     Thread-Safe Parallel Processing
     Security Hardened - Backup Protected
```

### Compact Banner Output:
```
  ╔════════════════════════════════════════════════════════════════╗
  ║  LOCAL ACCOUNT CLEANUP v2.1 - Enhanced Edition         ║
  ╠════════════════════════════════════════════════════════════════╣
  ║  Mode: Report                                                  ║
  ║  Target: OU=Workstations,DC=contoso,DC=com                    ║
  ║  Computers: 150                                                ║
  ╚════════════════════════════════════════════════════════════════╝
```

---

## Demo Script

Create a demo to see all banners:

```powershell
# demo-banners.ps1
. ./Show-Banner.ps1

# 1. Full banner
Show-Banner -SkipTips
Start-Sleep -Seconds 2

# 2. Compact banner - Report mode
Clear-Host
Show-CompactBanner -Mode "Report" -TargetOU "OU=Test,DC=domain,DC=com" -ComputerCount 50
Start-Sleep -Seconds 2

# 3. Compact banner - Disable mode
Clear-Host
Show-CompactBanner -Mode "Disable" -TargetOU "OU=Test,DC=domain,DC=com" -ComputerCount 50
Start-Sleep -Seconds 2

# 4. Compact banner - DeleteProfiles mode
Clear-Host
Show-CompactBanner -Mode "DeleteProfiles" -TargetOU "OU=Test,DC=domain,DC=com" -ComputerCount 50
Start-Sleep -Seconds 2

# 5. Menu banner
Clear-Host
Show-MenuBanner
```

Run with:
```bash
pwsh -File demo-banners.ps1
```

---

## Best Practices

1. **Always show banner in Report mode** - Helps users confirm what they're about to do
2. **Use compact banner for progress** - Doesn't clutter output
3. **Color-code by risk level**:
   - Green = Safe (Report, Test)
   - Yellow = Caution (Disable)
   - Red = Destructive (DeleteProfiles)
4. **Include OU in banner** - Helps prevent mistakes
5. **Show computer count** - Sets expectations
6. **Allow -Quiet flag** - Skip banner for automation

---

## Advanced Integration

### Add -ShowBanner parameter to main script:

```powershell
param(
    # ... existing parameters ...

    [Parameter(Mandatory=$false)]
    [switch]$ShowBanner
)

# At start of script
if ($ShowBanner) {
    $bannerScript = Join-Path $PSScriptRoot "Show-Banner.ps1"
    if (Test-Path $bannerScript) {
        . $bannerScript
        Show-Banner
    }
}
```

### Create wrapper script with banner:

```powershell
# run-cleanup-interactive.ps1
. ./Show-Banner.ps1

Show-Banner

# Get user input
$targetOU = Read-Host "Enter Target OU"
$mode = Read-Host "Enter Mode (Report/Disable/DeleteProfiles)"

# Show confirmation
Show-CompactBanner -Mode $mode -TargetOU $targetOU

$confirm = Read-Host "Proceed? (Y/N)"
if ($confirm -eq 'Y') {
    .\Invoke-LocalAccountCleanup.ps1 -TargetOU $targetOU -Mode $mode
}
```

---

## Notes

- Banner scripts work on Linux, macOS, and Windows
- ASCII art uses Unicode box-drawing characters
- Colors work in most modern terminals
- Falls back gracefully if banner file is missing
- No dependencies required (pure PowerShell)

---

## Alternative Styles

### Minimal Style:
```
═══════════════════════════════════════
 LOCAL ACCOUNT CLEANUP v2.1
═══════════════════════════════════════
Mode: Report | Target: OU=Test,DC=...
```

### Progress Style:
```
[●●●●●●●○○○] 60% | Processing: WS-001
Mode: Disable | 150 of 250 computers
```

Add these by creating custom functions in `Show-Banner.ps1`!

---

Enjoy your professional-looking script banners!

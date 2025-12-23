# PowerShell Local Account Cleanup System

**Version:** 2.1 - Enhanced Edition
**Status:**  Production Ready
**Platform:** Windows Server 2016+ / Windows 10+ with Active Directory
**PowerShell:** 7.0 or later required

---

## Overview

Automated solution for managing local user accounts across Windows domain-joined workstations. Identifies, disables, and optionally removes inactive local accounts and profiles across 1000+ computers with thread-safe parallel processing.

### Key Features

- **Parallel Processing** - Process 10-50 computers simultaneously
- **Thread-Safe** - Mutex-based logging prevents file conflicts
- **Security Hardened** - Automatic backups with restrictive ACLs
- **Credential Validation** - Fail-fast before processing
- **Protected Accounts** - Multiple safety layers prevent critical account deletion
- **Comprehensive Logging** - Detailed audit trail for compliance
- **Batch Processing** - Pause between batches for control
- **Profile Cleanup** - Safely remove old user profiles after retention period

---

##  Repository Contents

### Core Scripts

| File | Description | Purpose |
|------|-------------|---------|
| `Invoke-LocalAccountCleanup.ps1` | **Main script** | Account cleanup across AD computers |
| `Test-RemoteConnectivity.ps1` | Connectivity test | Validate WinRM and network access |
| `Show-Banner.ps1` | Banner system | Professional UI for scripts |
| `Validate-Scripts.ps1` | Validation tool | Syntax and quality checks |

### Documentation

| File | Description | Audience |
|------|-------------|----------|
| `usage_guide.md` | **Complete usage guide** | IT Administrators |
| `TESTING.md` | Testing strategies | DevOps / QA |
| `QUICKSTART-TESTING.md` | Quick validation | Developers |
| `BANNER-README.md` | Banner integration | Customization |

### Testing

| Directory/File | Description |
|----------------|-------------|
| `Tests/` | Pester unit tests (60+ tests) |
| `Tests/Invoke-LocalAccountCleanup.Tests.ps1` | Main script tests |
| `Tests/Test-RemoteConnectivity.Tests.ps1` | Connectivity tests |

### Configuration

| File | Description |
|------|-------------|
| `.gitignore` | Excludes logs, credentials, temp files |

---

##  Quick Start

### Prerequisites

1. **PowerShell 7.0+** installed
2. **ActiveDirectory module** (RSAT tools)
3. **Domain Admin** credentials or equivalent
4. **WinRM enabled** on target computers
5. **Network access** to target computers (port 5985)

### Installation

```powershell
# 1. Clone or download repository
git clone <repository-url>
cd power-shell-user-management-script-

# 2. Verify PowerShell version
$PSVersionTable.PSVersion  # Should be 7.0+

# 3. Import ActiveDirectory module
Import-Module ActiveDirectory

# 4. Validate scripts (optional but recommended)
.\Validate-Scripts.ps1 -InstallDependencies
```

### First Run - Safe Testing

```powershell
# Step 1: Test connectivity (no changes)
.\Test-RemoteConnectivity.ps1 -TargetOU "OU=TestComputers,DC=domain,DC=com"

# Step 2: Generate report (no changes)
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestComputers,DC=domain,DC=com" `
    -Mode Report `
    -InactiveDays 30

# Step 3: Review the CSV report
Import-Csv "C:\Scripts\Logs\AccountReport_*.csv" | Out-GridView

# Step 4: If satisfied, disable accounts on TEST OU only
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestComputers,DC=domain,DC=com" `
    -Mode Disable `
    -InactiveDays 30
```

---

##  Usage Modes

### Mode 1: Report (Safe - Recommended First)

**Purpose:** Preview what would be changed without making any modifications

```powershell
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode Report `
    -InactiveDays 30
```

**Output:** CSV file showing all accounts that meet criteria

### Mode 2: Disable (Makes Changes)

**Purpose:** Disable inactive local accounts

```powershell
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode Disable `
    -InactiveDays 30 `
    -Force  # Skip confirmation prompts
```

**Action:** Disables accounts, creates backups

### Mode 3: DeleteProfiles (Destructive - Use with Caution)

**Purpose:** Remove user profiles for disabled accounts after retention period

```powershell
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode DeleteProfiles `
    -ProfileRetentionDays 7
```

**Action:** Permanently deletes profiles (CANNOT be undone)

---

##  Safety Features

### Protected Accounts

The following accounts are automatically protected from modification:

1. **System Accounts:**
   - `Administrator`
   - `Guest`
   - `DefaultAccount`
   - `WDAGUtilityAccount`

2. **Custom Protected:**
   - `GBPS` (default, configurable)
   - Any accounts in `-CustomProtectedAccounts` parameter

3. **Dynamic Protection:**
   - Most recently logged-in user on each computer

### Backup System

-  Automatic backups created before ANY destructive operation
-  JSON format for easy recovery
-  Restrictive ACLs (only script user and SYSTEM have access)
-  Backup failure in Disable/DeleteProfiles modes **aborts operation**
-  Timestamped for audit trail

---

##  Advanced Parameters

```powershell
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode Disable `
    -InactiveDays 60 `                    # Days since last logon
    -BatchSize 100 `                       # Computers per batch
    -ParallelThreads 20 `                  # Concurrent processing
    -MaxRetries 3 `                        # Retry failed connections
    -RetryDelaySeconds 10 `                # Wait between retries (NEW v2.1)
    -CustomProtectedAccounts @('GBPS','LocalAdmin','Kiosk') `
    -Credential (Get-Credential) `         # Use specific credentials
    -LogPath "D:\Logs" `                   # Custom log location
    -Force                                 # Skip confirmations
```

---

##  Output Files

All output saved to `C:\Scripts\Logs\` (or custom `-LogPath`):

| File | Description | Format |
|------|-------------|--------|
| `LocalAccountCleanup_[timestamp].log` | Main operation log | Text |
| `AccountReport_[timestamp].csv` | Account details | CSV |
| `Errors_[timestamp].log` | Failed operations | Text |
| `Backups_[timestamp]/` | Account backups | JSON |
| `ConnectivityTest_[timestamp].csv` | Connectivity results | CSV |

---

##  Testing & Validation

### Pre-Deployment Testing

```powershell
# 1. Validate script syntax (no Windows needed)
.\Validate-Scripts.ps1 -InstallDependencies

# 2. Run unit tests (60+ tests)
Invoke-Pester -Path .\Tests\ -Output Detailed

# 3. Test on small OU (5-10 computers)
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestComputers,DC=domain,DC=com" `
    -Mode Report

# 4. Manually verify a few computers
# Remote into 2-3 computers and check local users match report
```

### Recommended Testing Phases

1. **Syntax Validation** (5 minutes) - Run `Validate-Scripts.ps1`
2. **Small Test OU** (30 minutes) - 5-10 computers in Report mode
3. **Pilot Deployment** (1 week) - 50-100 computers in Disable mode
4. **Full Rollout** (Ongoing) - All computers in batches

---

##  Monitoring & Troubleshooting

### Check Logs

```powershell
# View main log
Get-Content "C:\Scripts\Logs\LocalAccountCleanup_*.log" -Tail 50

# View errors only
Get-Content "C:\Scripts\Logs\Errors_*.log"

# Analyze report
Import-Csv "C:\Scripts\Logs\AccountReport_*.csv" |
    Group-Object ComputerName |
    Sort-Object Count -Descending
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Access Denied" | Insufficient permissions | Run with Domain Admin credentials |
| "WinRM failed" | WinRM not enabled | Enable via GPO, see `usage_guide.md` |
| "Computer offline" | Network/power issues | Check connectivity test results |
| "Backup failed" | Disk space/permissions | Check `-LogPath` directory permissions |

### Error Phases (v2.1 Enhancement)

Errors now include phase information:
- `[Session creation]` - Connection/authentication failed
- `[Account retrieval]` - Remote query failed
- `[Account processing]` - Disable/delete operation failed

---

## Documentation Reference

| Document | When to Read | Estimated Time |
|----------|-------------|----------------|
| This README | **Start here** | 10 minutes |
| `usage_guide.md` | Before first production use | 30 minutes |
| `QUICKSTART-TESTING.md` | Before running scripts | 10 minutes |
| `TESTING.md` | For comprehensive testing strategy | 20 minutes |
| `BANNER-README.md` | For UI customization | 10 minutes |

---

##  Version History

### v2.1 - Enhanced Edition (Current)
**Release Date:** 2025-12-23

**New Features:**
-  Thread-safe logging with mutex
-  Early credential validation
-  Configurable retry delays (`-RetryDelaySeconds`)
-  Session creation helper function (DRY)
-  Enhanced error context (shows failure phase)
-  Real-time progress indicators
-  Security hardened backups (restrictive ACLs)
-  Critical backup failure protection

**Bug Fixes:**
-  Fixed profile path hardcoding (removed C: drive assumption)
-  Fixed array concatenation in connectivity test (ArrayList)

**Breaking Changes:**
-  File renames (PowerShell conventions):
  - `psum script` → `Invoke-LocalAccountCleanup.ps1`
  - `test_connectivity_script.txt` → `Test-RemoteConnectivity.ps1`

### v2.0 - Production Ready
- Parallel processing with PowerShell 7
- Session reuse optimization
- Protected accounts system
- Batch processing

### v1.0 - Initial Release
- Basic account cleanup functionality

---

##  Support & Contributions

### Getting Help

1. **Read Documentation:** Check `usage_guide.md` first
2. **Review Examples:** See Quick Start section above
3. **Check Logs:** Review error logs for specific issues
4. **Test Environment:** Try on test OU before reporting issues

### Reporting Issues

Include:
- PowerShell version (`$PSVersionTable.PSVersion`)
- Script version (v2.1)
- Full error message
- Log files (sanitize sensitive data)
- Steps to reproduce

---

##  License & Credits

**Author:** IT Administrator
**Reviewed by:** Andile Mbele, Software Engineer
**Version:** 2.1 - Enhanced Edition
**Last Updated:** 2025-12-23

---

##  Important Warnings

### Before Running in Production

-  Always run in **Report mode first**
-  Test on **small OU** before full deployment
-  **Verify connectivity** to all computers
-  **Backup critical data** independently
-  **Review logs** after each run
-  **Monitor closely** during first week
-  **Communicate** with users about account cleanup policy

### DeleteProfiles Mode

-  **PERMANENT** - Cannot be undone
-  **Use with extreme caution**
-  Wait minimum 7 days after disabling
-  Verify backups exist
-  Test on non-production computers first

---

##  Success Metrics

### Expected Results

- **Report Mode:** 5-15% of accounts flagged as inactive (typical)
- **Processing Speed:** 50-100 computers per 10 minutes (depends on network)
- **Success Rate:** 90%+ computers processed (offline computers excluded)
- **Error Rate:** <5% (WinRM/network issues)

### Performance Benchmarks

| Computers | Report Mode | Disable Mode | Notes |
|-----------|-------------|--------------|-------|
| 10 | ~1 min | ~2 min | Test environment |
| 100 | ~5 min | ~10 min | Small deployment |
| 1,000 | ~30 min | ~60 min | Large deployment |
| 5,000+ | ~2-3 hours | ~4-6 hours | Enterprise (use batching) |

---

##  Production Readiness Checklist

Before handing to IT department:

- [x] Scripts validated with PSScriptAnalyzer
- [x] 60+ unit tests passing
- [x] Documentation complete
- [x] Safety features implemented
- [x] Backup system verified
- [x] Error handling comprehensive
- [x] Logging detailed
- [x] File naming conventions (PowerShell standard)
- [x] .gitignore configured
- [x] Version 2.1 tested

---

##  Quick Reference

```powershell
# Safety First - Always start with these
.\Test-RemoteConnectivity.ps1 -TargetOU "OU=Computers,DC=domain,DC=com"
.\Invoke-LocalAccountCleanup.ps1 -TargetOU "OU=Computers,DC=domain,DC=com" -Mode Report

# Production Commands
.\Invoke-LocalAccountCleanup.ps1 -TargetOU "OU=Computers,DC=domain,DC=com" -Mode Disable -Force
.\Invoke-LocalAccountCleanup.ps1 -TargetOU "OU=Computers,DC=domain,DC=com" -Mode DeleteProfiles -ProfileRetentionDays 7 -Force

# Validation
.\Validate-Scripts.ps1
Invoke-Pester -Path .\Tests\

# Help
Get-Help .\Invoke-LocalAccountCleanup.ps1 -Full
```

---

**Ready for Production Deployment**

For detailed usage instructions, see [`usage_guide.md`](usage_guide.md)

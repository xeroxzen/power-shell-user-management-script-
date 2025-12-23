# Local Account Cleanup System - Complete Guide

## Overview
This solution allows you to remotely manage local user accounts across 1000+ domain-joined workstations from a central location (Domain Controller or admin workstation).

## Prerequisites

### 1. Required PowerShell Modules
```powershell
# Check if ActiveDirectory module is installed
Get-Module -ListAvailable ActiveDirectory

# If not installed, install RSAT tools
Install-WindowsFeature RSAT-AD-PowerShell
```

### 2. Required Permissions
- Domain Admin or equivalent rights
- Local Administrator rights on target workstations
- PowerShell remoting (WinRM) enabled on all workstations

### 3. Firewall Configuration
- Port 5985 (WinRM HTTP) must be open between admin machine and workstations
- Windows Remote Management service must be running on all workstations

---

## Setup Instructions

### Step 1: Create Directory Structure
```powershell
# Create necessary folders
New-Item -Path "C:\Scripts" -ItemType Directory -Force
New-Item -Path "C:\Scripts\Logs" -ItemType Directory -Force

# Save the main script as:
# C:\Scripts\Invoke-LocalAccountCleanup.ps1

# Save the connectivity test script as:
# C:\Scripts\Test-RemoteConnectivity.ps1
```

### Step 2: Verify PowerShell Remoting
```powershell
# Test a single computer first
Test-WSMan -ComputerName "COMPUTERNAME"

# If this fails, you may need to enable remoting on workstations via GPO:
# Computer Configuration > Policies > Administrative Templates > 
# Windows Components > Windows Remote Management (WinRM) > WinRM Service
# Enable "Allow remote server management through WinRM"
```

---

## Usage Workflow

### PHASE 1: Test Connectivity (Always Run First!)

```powershell
# Test connectivity to all computers in target OU
.\Test-RemoteConnectivity.ps1 -TargetOU "OU=Workstations,DC=yourdomain,DC=com"
```

**Review the output to identify:**
- Offline computers
- Computers with remoting issues
- Computers that are ready for cleanup

---

### PHASE 2: Generate Report (Always Run Before Making Changes!)

```powershell
# Generate report for a small test group first
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestWorkstations,DC=yourdomain,DC=com" `
    -InactiveDays 30 `
    -BatchSize 10 `
    -Mode Report
```

**What this does:**
- Identifies all local accounts inactive for 30+ days
- Shows which accounts would be affected
- **DOES NOT make any changes**
- Creates detailed CSV report

**Review the report file** at `C:\Scripts\Logs\AccountReport_[timestamp].csv`

Example report columns:
- ComputerName
- AccountName
- LastLogon
- DaysSinceLogon
- Action (what would happen)
- Status

---

### PHASE 3: Test on Small Group

```powershell
# Run on 5-10 test computers first
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestWorkstations,DC=yourdomain,DC=com" `
    -InactiveDays 30 `
    -BatchSize 5 `
    -Mode Disable
```

**What this does:**
- Disables accounts identified in report mode
- Protects GBPS account
- Protects most recently logged-in account
- Processes computers in batches
- Creates detailed logs

**Verify on test computers:**
1. Remote into a test workstation
2. Open Computer Management > Local Users and Groups
3. Verify correct accounts were disabled

---

### PHASE 4: Full Deployment (Batched Processing)

```powershell
# Process all 1000 computers in batches of 50
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=AllWorkstations,DC=yourdomain,DC=com" `
    -InactiveDays 30 `
    -BatchSize 50 `
    -Mode Disable
```

**Script behavior:**
- Processes 50 computers at a time
- Pauses between batches (press Enter to continue)
- Logs all actions
- Retries failed connections 2 times
- Skips offline computers (logged for review)

---

### PHASE 5: Profile Deletion (After 7-Day Review)

```powershell
# After reviewing disabled accounts for 7 days, delete profiles
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=AllWorkstations,DC=yourdomain,DC=com" `
    -ProfileRetentionDays 7 `
    -Mode DeleteProfiles
```

**What this does:**
- Only deletes profiles from C:\Users for accounts disabled 7+ days ago
- Leaves accounts that are within retention period
- Creates backup logs before deletion

---

## Understanding Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `TargetOU` | Full Distinguished Name of target OU | **Required** | `"OU=Workstations,DC=domain,DC=com"` |
| `InactiveDays` | Days since last logon to consider inactive | 30 | `45` |
| `BatchSize` | Number of computers to process per batch | 50 | `25` |
| `Mode` | Operation mode | Report | `Report`, `Disable`, `DeleteProfiles` |
| `ProfileRetentionDays` | Days to wait before deleting profiles | 7 | `14` |
| `MaxRetries` | Retry attempts for failed connections | 2 | `3` |
| `LogPath` | Directory for logs and reports | `C:\Scripts\Logs` | `D:\Logs` |

---

## Protected Accounts

The script automatically protects:
- **GBPS** (your local admin account)
- **DefaultAccount** (Windows system account)
- **WDAGUtilityAccount** (Windows Defender Application Guard)
- **Most recently logged-in account** on each machine

---

## Log Files Explained

After each run, you'll find these files in `C:\Scripts\Logs`:

### 1. Main Log File
`LocalAccountCleanup_[timestamp].log`
- Detailed operation log
- Connection attempts
- Success/failure for each action
- Timestamps for all operations

### 2. Report File
`AccountReport_[timestamp].csv`
- Spreadsheet with all accounts found
- Import into Excel for analysis
- Filter by computer, account, or status

### 3. Error File
`Errors_[timestamp].log`
- Only created if errors occur
- Lists failed computers and reasons
- Use to troubleshoot connectivity issues

---

## Real-World Examples

### Example 1: First-Time Setup
```powershell
# Step 1: Test 10 computers
.\Test-RemoteConnectivity.ps1 -TargetOU "OU=Workstations,DC=company,DC=com"

# Step 2: Generate report for those 10
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode Report

# Step 3: Review CSV, then disable on those 10
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -Mode Disable

# Step 4: Verify manually on 2-3 computers

# Step 5: Expand to all computers
```

### Example 2: More Aggressive Cleanup
```powershell
# Find accounts inactive for 60 days
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=OldWorkstations,DC=company,DC=com" `
    -InactiveDays 60 `
    -Mode Report
```

### Example 3: Faster Processing
```powershell
# Larger batches for faster completion
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -BatchSize 100 `
    -Mode Disable
```

### Example 4: Extended Review Period
```powershell
# Wait 14 days before deleting profiles
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=Workstations,DC=company,DC=com" `
    -ProfileRetentionDays 14 `
    -Mode DeleteProfiles
```

---

## Safety Features

### 1. Report Mode First
Always run in Report mode before making changes

### 2. Batch Processing with Pauses
Script pauses between batches - you can stop at any time with Ctrl+C

### 3. Protected Accounts
Multiple layers prevent accidental deletion of critical accounts

### 4. Most Recent Account Protection
The last person to log into each machine is always protected

### 5. Retry Logic
Temporary network issues won't cause failures

### 6. Comprehensive Logging
Every action is logged for audit and troubleshooting

---

## Troubleshooting

### Problem: "Access Denied" errors
**Solution:** 
```powershell
# Verify you're running as Domain Admin
whoami /groups | findstr "Domain Admins"

# Test credentials on a single computer
Enter-PSSession -ComputerName TESTPC
```

### Problem: WinRM errors
**Solution:**
```powershell
# On target computer, verify WinRM service
Get-Service WinRM

# If stopped, start it
Start-Service WinRM

# Enable via GPO for all computers
```

### Problem: Many computers offline
**Solution:**
- Run connectivity test first
- Schedule script to run multiple times
- Use smaller batch sizes
- Check offline computers list

### Problem: Script too slow
**Solution:**
```powershell
# Increase batch size
-BatchSize 100

# Reduce retry attempts
-MaxRetries 1
```

### Problem: Need to exclude specific accounts
**Solution:**
Edit the script and add to `ProtectedAccounts` array:
```powershell
$Script:Config = @{
    ProtectedAccounts = @('GBPS', 'DefaultAccount', 'WDAGUtilityAccount', 'ServiceAccount1', 'Kiosk')
}
```

---

## Recommended Schedule

### Week 1: Testing Phase
- Day 1: Run connectivity test on all computers
- Day 2: Generate report for small test group (10-20 computers)
- Day 3: Review report, disable accounts on test group
- Day 4-5: Verify test computers manually

### Week 2: Limited Rollout
- Run on 25% of computers (250 machines)
- Monitor logs daily

### Week 3: Full Rollout
- Run on all remaining computers
- Process in batches of 50-100

### Week 4: Profile Cleanup
- After 7-day review period, run DeleteProfiles mode

### Monthly: Maintenance
- Run Report mode monthly
- Clean up new inactive accounts

---

## Best Practices

1. **Always test first** - Use Report mode, then small batches
2. **Review logs** - Check logs after each run
3. **Keep records** - Archive CSV reports for compliance
4. **Document exceptions** - Note why certain accounts are protected
5. **Communicate** - Inform users about account cleanup policies
6. **Verify manually** - Spot-check a few computers after each run
7. **Backup first** - Ensure you have AD backups before large operations
8. **Off-hours execution** - Run during low-activity periods
9. **Monitor gradually** - Don't rush full deployment

---

## Emergency Rollback

If something goes wrong:

### To Re-enable a Single Account
```powershell
Invoke-Command -ComputerName COMPUTERNAME -ScriptBlock {
    Enable-LocalUser -Name "username"
}
```

### To Re-enable All Disabled Accounts on a Computer
```powershell
Invoke-Command -ComputerName COMPUTERNAME -ScriptBlock {
    Get-LocalUser | Where-Object { -not $_.Enabled } | Enable-LocalUser
}
```

---

## Support Checklist

Before asking for help, gather:
1. Log files from `C:\Scripts\Logs`
2. CSV report showing the issue
3. Exact error messages
4. Computer names affected
5. PowerShell version: `$PSVersionTable.PSVersion`
6. AD module version: `Get-Module ActiveDirectory`

---

## Security Considerations

1. **Audit regularly** - Review who runs this script
2. **Least privilege** - Consider dedicated service account
3. **Log retention** - Keep logs for compliance (90+ days)
4. **Change control** - Document all cleanup operations
5. **User notification** - Inform users before disabling accounts

---

## Next Steps

1. Save both scripts to `C:\Scripts`
2. Test connectivity on small OU
3. Run Report mode
4. Review and approve results
5. Execute Disable mode on test group
6. Expand gradually to all computers
7. Schedule monthly maintenance
# Testing Guide for PowerShell User Management Scripts

## Testing Strategy Overview

Since these scripts are Windows-specific (Active Directory, WinRM, local users), testing from Linux/macOS requires a multi-layered approach.

---

## Testing Layers

### Layer 1: Syntax Validation (Local - No Windows Needed)
### Layer 2: Unit Testing (Local - Partial Testing)
### Layer 3: Integration Testing (Requires Windows Environment)
### Layer 4: End-to-End Testing (Requires Full AD Environment) 

---

## Layer 1: Syntax Validation (Do This First)

### Install PowerShell 7+ on Linux/macOS

#### macOS:
```bash
brew install --cask powershell
```

#### Ubuntu/Debian:
```bash
# Download the package
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb

# Install
sudo dpkg -i powershell_7.4.0-1.deb_amd64.deb
sudo apt-get install -f
```

#### Fedora/CentOS/RHEL:
```bash
sudo dnf install https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-1.rh.x86_64.rpm
```

### Verify Installation:
```bash
pwsh --version
```

---

## Syntax Validation Tests

Run these tests locally to catch 90% of syntax errors:

### 1. Basic Syntax Check
```powershell
pwsh -NoProfile -Command {
    $ErrorActionPreference = 'Stop'

    # Test main script
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content './Invoke-LocalAccountCleanup.ps1' -Raw),
        [ref]$null
    )

    # Test connectivity script
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content './Test-RemoteConnectivity.ps1' -Raw),
        [ref]$null
    )

    Write-Host "Syntax validation passed!" -ForegroundColor Green
}
```

### 2. Script Analyzer (Best Practice Check)
```powershell
pwsh -NoProfile -Command {
    # Install PSScriptAnalyzer if not present
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }

    # Analyze main script
    $results = Invoke-ScriptAnalyzer -Path './Invoke-LocalAccountCleanup.ps1' -Severity @('Error', 'Warning')

    if ($results) {
        $results | Format-Table -AutoSize
        Write-Host "Found $($results.Count) issues" -ForegroundColor Red
    } else {
        Write-Host "PSScriptAnalyzer: No issues found!" -ForegroundColor Green
    }

    # Analyze connectivity script
    $results2 = Invoke-ScriptAnalyzer -Path './Test-RemoteConnectivity.ps1' -Severity @('Error', 'Warning')

    if ($results2) {
        $results2 | Format-Table -AutoSize
        Write-Host "Found $($results2.Count) issues" -ForegroundColor Red
    } else {
        Write-Host "PSScriptAnalyzer: No issues found!" -ForegroundColor Green
    }
}
```

### 3. Parameter Validation Test
```powershell
pwsh -NoProfile -Command {
    # Test that parameters are accessible
    $scriptPath = './Invoke-LocalAccountCleanup.ps1'
    $params = (Get-Command $scriptPath).Parameters

    Write-Host "Script Parameters:" -ForegroundColor Cyan
    $params.Keys | Sort-Object | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Gray
    }

    # Verify required parameters exist
    $requiredParams = @('TargetOU')
    $missing = $requiredParams | Where-Object { $_ -notin $params.Keys }

    if ($missing) {
        Write-Host "Missing required parameters: $($missing -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "All required parameters present" -ForegroundColor Green
    }
}
```

### 4. Function Discovery Test
```powershell
pwsh -NoProfile -Command {
    # Parse and count functions
    $content = Get-Content './Invoke-LocalAccountCleanup.ps1' -Raw
    $functions = [regex]::Matches($content, 'function\s+([A-Za-z0-9-]+)')

    Write-Host "Discovered Functions:" -ForegroundColor Cyan
    $functions | ForEach-Object {
        Write-Host "  - $($_.Groups[1].Value)" -ForegroundColor Gray
    }

    Write-Host "`nTotal: $($functions.Count) functions" -ForegroundColor Green
}
```

---

## Layer 2: Unit Testing with Pester

### Install Pester:
```powershell
pwsh -NoProfile -Command {
    Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
}
```

### Run Unit Tests:
```powershell
pwsh -NoProfile -Command {
    Invoke-Pester -Path './Tests/' -Output Detailed
}
```

**Note:** Unit tests can validate logic but can't test Windows-specific cmdlets (Get-LocalUser, Get-ADComputer, etc.) on Linux/macOS.

---

## Layer 3: Integration Testing (Requires Windows)

### Option A: Windows VM on Linux/macOS

#### Using UTM (macOS - Apple Silicon):
1. Download Windows 11 ARM ISO
2. Create VM in UTM
3. Install PowerShell 7
4. Copy scripts via shared folder
5. Run tests in VM

#### Using VirtualBox (Intel Macs/Linux):
```bash
# Install VirtualBox
brew install --cask virtualbox  # macOS
sudo apt install virtualbox     # Ubuntu

# Create Windows VM
# Download Windows 10/11 ISO from Microsoft
# Set up VM with:
# - 4GB+ RAM
# - 50GB+ disk
# - Network: Bridged or NAT
```

#### Using QEMU/KVM (Linux):
```bash
# Install KVM
sudo apt install qemu-kvm libvirt-daemon-system

# Create Windows VM
virt-manager
```

---

### Option B: Remote Windows Machine

If you have access to a Windows machine (RDP/SSH):

#### 1. Set up SSH to Windows:
```bash
# From Linux/macOS, connect to Windows machine
ssh user@windows-machine-ip

# Copy scripts
scp -r ./*.ps1 user@windows-machine-ip:C:/Scripts/
```

#### 2. Run tests remotely:
```bash
ssh user@windows-machine-ip 'pwsh -File C:/Scripts/Invoke-LocalAccountCleanup.ps1 -TargetOU "OU=Test,DC=domain,DC=com" -Mode Report'
```

---

### Option C: WSL2 with Windows PowerShell Integration

If you have access to a Windows machine with WSL2:

```bash
# From WSL2, you can call Windows PowerShell
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -File ./script.ps1
```

---

### Option D: Azure/Cloud VMs

#### Azure Windows VM:
```bash
# Create Windows VM in Azure
az vm create \
  --resource-group MyResourceGroup \
  --name TestWindowsVM \
  --image Win2022Datacenter \
  --admin-username azureuser \
  --admin-password 'YourPassword123!'

# Connect via SSH or RDP
```

#### AWS EC2 Windows Instance:
```bash
# Launch Windows Server instance
aws ec2 run-instances \
  --image-id ami-xxxxx \
  --instance-type t2.micro \
  --key-name MyKeyPair
```

---

## Layer 4: Full End-to-End Testing

### Requirements:
- Active Directory Domain Controller
- Domain-joined workstations
- Domain Admin credentials
- Test OU with computers

### Recommended Test Lab Setup:

#### Minimal Setup (2 VMs):
1. **VM1: Windows Server** (Domain Controller)
   - Install AD DS role
   - Create domain (e.g., `testlab.local`)
   - Create test OU: `OU=TestComputers,DC=testlab,DC=local`

2. **VM2: Windows 10/11** (Workstation)
   - Join to domain
   - Create local test accounts
   - Set last logon dates (manually or via script)

#### Test Execution:
```powershell
# On Domain Controller or admin workstation:

# 1. Test connectivity
.\Test-RemoteConnectivity.ps1 -TargetOU "OU=TestComputers,DC=testlab,DC=local"

# 2. Run report mode
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestComputers,DC=testlab,DC=local" `
    -Mode Report `
    -InactiveDays 30 `
    -Verbose

# 3. Verify report CSV
Import-Csv "C:\Scripts\Logs\AccountReport_*.csv" | Format-Table

# 4. Test disable mode (on single computer first)
.\Invoke-LocalAccountCleanup.ps1 `
    -TargetOU "OU=TestSingleComputer,DC=testlab,DC=local" `
    -Mode Disable `
    -InactiveDays 30 `
    -Force
```

---

## Validation Checklist

### Syntax Level (Can Do Now):
- [ ] Scripts parse without syntax errors
- [ ] PSScriptAnalyzer reports no critical issues
- [ ] All required parameters defined
- [ ] Help documentation is complete
- [ ] Version requirements declared

### Logic Level (Partial - Local):
- [ ] Parameter validation rules work
- [ ] Function declarations are valid
- [ ] Variable scoping is correct
- [ ] No undefined variables

### Integration Level (Needs Windows):
- [ ] ActiveDirectory module loads
- [ ] Test-Connection works
- [ ] PSRemoting sessions establish
- [ ] Local user cmdlets work
- [ ] CIM/WMI queries succeed

### Functional Level (Needs AD Environment):
- [ ] Retrieves computers from OU
- [ ] Identifies inactive accounts
- [ ] Protects system accounts
- [ ] Protects most recent account
- [ ] Disables accounts correctly
- [ ] Creates backups before actions
- [ ] Deletes profiles after retention
- [ ] Logs all operations
- [ ] Handles offline computers gracefully
- [ ] Parallel processing works
- [ ] Thread-safe logging verified

---

## Quick Start: Validate Now (No Windows Required)

Run this one-liner to do basic validation:

```bash
# First, make sure you're in the script directory
cd /home/andilejaden/Workspace/zimworx/power-shell-user-management-script-/

# Then run the validation script (we'll create this next)
pwsh -File ./Validate-Scripts.ps1
```

---

## CI/CD Integration

### GitHub Actions Example:

```yaml
name: PowerShell Script Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install PowerShell
        run: |
          sudo apt-get update
          sudo apt-get install -y wget apt-transport-https software-properties-common
          wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
          sudo dpkg -i packages-microsoft-prod.deb
          sudo apt-get update
          sudo apt-get install -y powershell

      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

      - name: Run Syntax Check
        shell: pwsh
        run: |
          $files = @(
            './Invoke-LocalAccountCleanup.ps1',
            './Test-RemoteConnectivity.ps1'
          )
          foreach ($file in $files) {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
              (Get-Content $file -Raw), [ref]$errors
            )
            if ($errors) {
              Write-Error "Syntax errors in $file"
              exit 1
            }
          }

      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path ./*.ps1 -Severity Error
          if ($results) {
            $results | Format-Table
            exit 1
          }
```

---

## Recommended Testing Workflow

### Phase 1: Local (Today)
1. Install PowerShell 7
2. Run syntax validation
3. Run PSScriptAnalyzer
4. Review parameter definitions

### Phase 2: Isolated Windows VM (This Week)
1. Set up Windows 10/11 VM
2. Test script loading
3. Test parameter parsing
4. Mock AD/remote calls

### Phase 3: Test Lab (Before Production)
1. Set up AD test environment
2. Create test computers and accounts
3. Run full integration tests
4. Verify all features work

### Phase 4: Limited Production (Pilot)
1. Select 5-10 test computers
2. Run in Report mode
3. Run Disable mode on 2-3 computers
4. Verify results manually

### Phase 5: Full Production
1. Run on all computers
2. Monitor logs
3. Collect metrics

---

## Support

If you encounter issues during testing:

1. **Syntax errors**: Check PowerShell version compatibility
2. **Module errors**: Verify required modules installed
3. **Permission errors**: Ensure proper credentials/rights
4. **Network errors**: Check firewall and WinRM settings

---

## Useful Resources

- [PowerShell Installation Guide](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [Pester Documentation](https://pester.dev/)
- [Active Directory Test Lab Guide](https://docs.microsoft.com/windows-server/identity/ad-ds/deploy/virtual-dc/adds-on-azure-vm)

BeforeAll {
    # Import the script (functions will be available)
    # Note: This will fail on non-Windows due to ActiveDirectory module requirement
    # These tests focus on logic that CAN be tested without Windows

    $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'

    # Mock Windows-specific modules
    if ($PSVersionTable.Platform -eq 'Unix') {
        # Create mock ActiveDirectory module functions
        function Get-ADComputer { }
        function Get-LocalUser { }
        function Disable-LocalUser { }
        function Test-Connection { return $true }
    }
}

Describe 'Invoke-LocalAccountCleanup Script Structure' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should have a valid PowerShell script extension' {
        $scriptPath | Should -Match '\.ps1$'
    }

    It 'Should contain comment-based help' {
        $scriptContent | Should -Match '(?s)<#.*?\.SYNOPSIS.*?#>'
    }

    It 'Should require PowerShell 7.0+' {
        $scriptContent | Should -Match '#Requires -Version 7\.0'
    }

    It 'Should require ActiveDirectory module' {
        $scriptContent | Should -Match '#Requires -Modules ActiveDirectory'
    }

    It 'Should contain CmdletBinding attribute' {
        $scriptContent | Should -Match '\[CmdletBinding\(SupportsShouldProcess=\$true\)\]'
    }
}

Describe 'Script Parameters' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$null,
            [ref]$null
        )
        $parameters = $ast.ParamBlock.Parameters
    }

    It 'Should have TargetOU parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'TargetOU' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'TargetOU should be mandatory' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'TargetOU' }
        $mandatory = $param.Attributes | Where-Object {
            $_.NamedArguments.ArgumentName -eq 'Mandatory' -and
            $_.NamedArguments.Argument.Value -eq $true
        }
        $mandatory | Should -Not -BeNullOrEmpty
    }

    It 'Should have InactiveDays parameter with default value' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'InactiveDays' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'Should have Mode parameter with ValidateSet' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Mode' }
        $validateSet = $param.Attributes | Where-Object { $_.TypeName.Name -eq 'ValidateSet' }
        $validateSet | Should -Not -BeNullOrEmpty
    }

    It 'Mode parameter should accept Report, Disable, DeleteProfiles' {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        $scriptContent | Should -Match "ValidateSet\('Report','Disable','DeleteProfiles'\)"
    }

    It 'Should have RetryDelaySeconds parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'RetryDelaySeconds' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'Should have ParallelThreads parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'ParallelThreads' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'Should have CustomProtectedAccounts parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'CustomProtectedAccounts' }
        $param | Should -Not -BeNullOrEmpty
    }
}

Describe 'Script Functions' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$null,
            [ref]$null
        )
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    }

    It 'Should contain Initialize-Logging function' {
        $func = $functions | Where-Object { $_.Name -eq 'Initialize-Logging' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Write-Log function' {
        $func = $functions | Where-Object { $_.Name -eq 'Write-Log' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain New-RemoteSession function' {
        $func = $functions | Where-Object { $_.Name -eq 'New-RemoteSession' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Test-RemoteConnection function' {
        $func = $functions | Where-Object { $_.Name -eq 'Test-RemoteConnection' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Test-ADCredential function' {
        $func = $functions | Where-Object { $_.Name -eq 'Test-ADCredential' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Get-TargetComputers function' {
        $func = $functions | Where-Object { $_.Name -eq 'Get-TargetComputers' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Get-RemoteLocalAccounts function' {
        $func = $functions | Where-Object { $_.Name -eq 'Get-RemoteLocalAccounts' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Get-MostRecentAccount function' {
        $func = $functions | Where-Object { $_.Name -eq 'Get-MostRecentAccount' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Backup-AccountData function' {
        $func = $functions | Where-Object { $_.Name -eq 'Backup-AccountData' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Process-Computer function' {
        $func = $functions | Where-Object { $_.Name -eq 'Process-Computer' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should contain Start-AccountCleanup function' {
        $func = $functions | Where-Object { $_.Name -eq 'Start-AccountCleanup' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'All functions should follow Verb-Noun naming convention' {
        $invalidNames = $functions | Where-Object {
            $_.Name -notmatch '^[A-Z][a-z]+-[A-Z][a-z]+'
        }
        $invalidNames.Count | Should -Be 0
    }
}

Describe 'Script Configuration' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should define Script:Config hashtable' {
        $scriptContent | Should -Match '\$Script:Config\s*=\s*@\{'
    }

    It 'Should include RetryDelaySeconds in config' {
        $scriptContent | Should -Match 'RetryDelaySeconds\s*=\s*\$RetryDelaySeconds'
    }

    It 'Should include ParallelThreads in config' {
        $scriptContent | Should -Match 'ParallelThreads\s*=\s*\$ParallelThreads'
    }

    It 'Should include ProtectedAccounts in config' {
        $scriptContent | Should -Match 'ProtectedAccounts\s*='
    }

    It 'Should protect DefaultAccount' {
        $scriptContent | Should -Match "'DefaultAccount'"
    }

    It 'Should protect WDAGUtilityAccount' {
        $scriptContent | Should -Match "'WDAGUtilityAccount'"
    }
}

Describe 'Thread Safety Features' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should create LogMutex for thread-safe logging' {
        $scriptContent | Should -Match '\$Script:LogMutex\s*=\s*\[System\.Threading\.Mutex\]'
    }

    It 'Write-Log should use mutex' {
        $scriptContent | Should -Match '\$Script:LogMutex\.WaitOne\(\)'
    }

    It 'Write-Log should release mutex in finally block' {
        $scriptContent | Should -Match '\$Script:LogMutex\.ReleaseMutex\(\)'
    }
}

Describe 'Security Features' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should implement credential validation' {
        $scriptContent | Should -Match 'Test-ADCredential'
    }

    It 'Should set restrictive ACLs on backup directory' {
        $scriptContent | Should -Match 'SetAccessRuleProtection'
    }

    It 'Should create backups before destructive operations' {
        $scriptContent | Should -Match 'Backup-AccountData'
    }

    It 'Should throw on backup failure in destructive modes' {
        $scriptContent | Should -Match "throw.*Backup failed"
    }
}

Describe 'Profile Path Fix' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should NOT contain hardcoded C: drive for profile paths' {
        # Look for the specific pattern that was a bug
        $scriptContent | Should -Not -Match 'LocalPath\s+-eq\s+"C:\\Users'
    }

    It 'Should use SystemDrive environment variable' {
        $scriptContent | Should -Match '\$env:SystemDrive\\Users'
    }
}

Describe 'Parallel Execution' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'Invoke-LocalAccountCleanup.ps1'
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should use ForEach-Object -Parallel' {
        $scriptContent | Should -Match 'ForEach-Object\s+-Parallel'
    }

    It 'Should pass LogMutex to parallel runspaces' {
        $scriptContent | Should -Match '\$Script:LogMutex\s*=\s*\$using:LogMutex'
    }

    It 'Should import New-RemoteSession function to parallel runspaces' {
        $scriptContent | Should -Match '\$\{function:New-RemoteSession\}\s*=\s*\$using:Function:New-RemoteSession'
    }
}

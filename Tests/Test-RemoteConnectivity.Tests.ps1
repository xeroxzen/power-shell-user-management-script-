BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '..' 'Test-RemoteConnectivity.ps1'
}

Describe 'Test-RemoteConnectivity Script Structure' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should exist' {
        Test-Path $scriptPath | Should -Be $true
    }

    It 'Should have .ps1 extension' {
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

    It 'Should have version documentation' {
        $scriptContent | Should -Match 'Version:\s*2\.0'
    }
}

Describe 'Script Parameters' {
    BeforeAll {
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

    It 'TargetOU should have ValidatePattern for DN format' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'TargetOU' }
        $validatePattern = $param.Attributes | Where-Object { $_.TypeName.Name -eq 'ValidatePattern' }
        $validatePattern | Should -Not -BeNullOrEmpty
    }

    It 'Should have Credential parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Credential' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'Should have OutputPath parameter with default value' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'OutputPath' }
        $param | Should -Not -BeNullOrEmpty
    }

    It 'Should have ConnectionTimeout parameter' {
        $param = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'ConnectionTimeout' }
        $param | Should -Not -BeNullOrEmpty
    }
}

Describe 'Test-BulkConnectivity Function' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $scriptPath,
            [ref]$null,
            [ref]$null
        )
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
    }

    It 'Should contain Test-BulkConnectivity function' {
        $func = $functions | Where-Object { $_.Name -eq 'Test-BulkConnectivity' }
        $func | Should -Not -BeNullOrEmpty
    }

    It 'Should use ArrayList for results (not array concatenation)' {
        $scriptContent | Should -Match '\[System\.Collections\.ArrayList\]::new\(\)'
    }

    It 'Should use ArrayList Add method' {
        $scriptContent | Should -Match '\[void\]\$results\.Add\('
    }

    It 'Should NOT use array concatenation operator (+=)' {
        # Check that we're not using $results += pattern
        $scriptContent | Should -Not -Match '\$results\s*\+=\s*\$result'
    }
}

Describe 'Credential Support' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should pass credentials to Get-ADComputer' {
        $scriptContent | Should -Match 'if\s*\(\$Credential\)\s*\{[^}]*\$adParams\[.Credential.\]\s*=\s*\$Credential'
    }

    It 'Should pass credentials to New-PSSession' {
        $scriptContent | Should -Match 'if\s*\(\$Credential\)\s*\{[^}]*\$sessionParams\[.Credential.\]\s*=\s*\$Credential'
    }

    It 'Should use splat pattern for session creation' {
        $scriptContent | Should -Match 'New-PSSession\s+@sessionParams'
    }
}

Describe 'Connection Testing' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should use Test-Connection with timeout' {
        $scriptContent | Should -Match 'Test-Connection.*-TimeoutSeconds\s+\$ConnectionTimeout'
    }

    It 'Should NOT use Test-NetConnection' {
        $scriptContent | Should -Not -Match 'Test-NetConnection'
    }

    It 'Should test PSRemoting capability' {
        $scriptContent | Should -Match 'New-PSSession'
    }

    It 'Should clean up test sessions' {
        $scriptContent | Should -Match 'Remove-PSSession\s+-Session\s+\$session'
    }
}

Describe 'Progress Reporting' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should implement Write-Progress' {
        $scriptContent | Should -Match 'Write-Progress'
    }

    It 'Should show percentage complete' {
        $scriptContent | Should -Match '-PercentComplete'
    }

    It 'Should complete progress when done' {
        $scriptContent | Should -Match 'Write-Progress.*-Completed'
    }
}

Describe 'Output and Reporting' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should export results to CSV' {
        $scriptContent | Should -Match 'Export-Csv'
    }

    It 'Should include timestamp in report filename' {
        $scriptContent | Should -Match 'ConnectivityTest_.*\.csv'
    }

    It 'Should display summary statistics' {
        $scriptContent | Should -Match 'Total Computers:'
    }

    It 'Should show computers with issues' {
        $scriptContent | Should -Match 'Computers with Issues:'
    }
}

Describe 'Version Validation' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should verify PowerShell version' {
        $scriptContent | Should -Match '\$PSVersionTable\.PSVersion\.Major\s+-lt\s+7'
    }

    It 'Should provide download link for PowerShell' {
        $scriptContent | Should -Match 'https://aka\.ms/powershell'
    }

    It 'Should verify ActiveDirectory module' {
        $scriptContent | Should -Match 'Get-Module.*ActiveDirectory'
    }
}

Describe 'Error Handling' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should have try-catch blocks' {
        $scriptContent | Should -Match 'try\s*\{'
        $scriptContent | Should -Match 'catch\s*\{'
    }

    It 'Should capture error messages' {
        $scriptContent | Should -Match '\$_\.Exception\.Message'
    }

    It 'Should handle computer query failures' {
        $scriptContent | Should -Match 'catch.*Get-ADComputer'
    }
}

Describe 'Output Result Properties' {
    BeforeAll {
        $scriptContent = Get-Content -Path $scriptPath -Raw
    }

    It 'Should include ComputerName in results' {
        $scriptContent | Should -Match 'ComputerName\s*='
    }

    It 'Should include PingTest status' {
        $scriptContent | Should -Match 'PingTest\s*='
    }

    It 'Should include PSRemoting status' {
        $scriptContent | Should -Match 'PSRemoting\s*='
    }

    It 'Should include Error information' {
        $scriptContent | Should -Match 'Error\s*=\s*\$null'
    }

    It 'Should NOT include WinRMPort (removed in v2.0)' {
        $scriptContent | Should -Not -Match 'WinRMPort\s*='
    }
}

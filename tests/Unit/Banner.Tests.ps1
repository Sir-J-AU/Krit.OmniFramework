#requires -Modules Pester
# Author: Joshua Finley - Kritical Pty Ltd

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\src\Krit.OmniFramework.psd1') -Force -DisableNameChecking -ErrorAction SilentlyContinue
    # Manifest may fail strict module checks until RequiredModules are installed; fall back to .psm1
    if (-not (Get-Module Krit.OmniFramework)) {
        Import-Module (Join-Path $PSScriptRoot '..\..\src\Krit.OmniFramework.psm1') -Force
    }
}

Describe 'Get-KritBanner' {
    It 'returns the canonical SirJ-deaddrop banner when present' {
        $b = Get-KritBanner
        $b | Should -Match 'SirJ'
        $b | Should -Match 'Kritical'
        $b | Should -Match '1300 274 655'
    }

    It '-Compact returns one-line summary' {
        $b = Get-KritBanner -Compact
        $b | Should -Match 'Kritical'
        @(($b -split "`r?`n") | Where-Object { $_ }).Count | Should -BeLessOrEqual 1
    }

    It '-Title appends a title block when not Compact' {
        (Get-KritBanner -Title 'UnitTest') | Should -Match '--- UnitTest ---'
    }

    It 'falls back gracefully when LogoPath does not exist' {
        $b = Get-KritBanner -LogoPath 'X:\nope\does\not\exist.txt'
        $b | Should -Match 'Kritical'
    }
}

Describe 'Write-KritBanner' {
    It 'does not throw (full)'    { { Write-KritBanner -Title 'Unit' -NoColor } | Should -Not -Throw }
    It 'does not throw (compact)' { { Write-KritBanner -Compact -NoColor } | Should -Not -Throw }
}

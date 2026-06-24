#requires -Modules Pester
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\src\Krit.OmniFramework.psm1') -Force
}

Describe 'Get-KritFoundationStatus' {
    It 'returns module + platform sections' {
        $s = Get-KritFoundationStatus
        $s.Modules  | Should -Not -BeNullOrEmpty
        $s.Platform | Should -Not -BeNullOrEmpty
        ($s.Modules | Where-Object Module -eq 'PSFramework') | Should -Not -BeNullOrEmpty
        ($s.Modules | Where-Object Module -eq 'PSWriteHTML') | Should -Not -BeNullOrEmpty
        ($s.Modules | Where-Object Module -eq 'ImportExcel') | Should -Not -BeNullOrEmpty
    }
}

Describe 'Import-KritFoundation (NoInstall, NoBanner, Quiet)' {
    It 'returns a status object without throwing' {
        $r = Import-KritFoundation -NoInstall -NoBanner -Quiet
        $r        | Should -Not -BeNullOrEmpty
        $r.Modules | Should -Not -BeNullOrEmpty
        $r.Ok     | Should -BeOfType [bool]
        $r.Platform | Should -Not -BeNullOrEmpty
    }
}

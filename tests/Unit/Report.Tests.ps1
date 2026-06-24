#requires -Modules Pester
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\src\Krit.OmniFramework.psm1') -Force
    $script:Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("krit-omni-rpt-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:Tmp | Out-Null
}
AfterAll {
    Remove-Item -LiteralPath $script:Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Describe 'New-KritHtmlReport' {
    It 'writes a valid HTML file (uses fallback when PSWriteHTML absent)' {
        $out = Join-Path $script:Tmp 'rpt.html'
        $data = @(
            [pscustomobject]@{ Name = 'pwsh'; Present = $true }
            [pscustomobject]@{ Name = 'nope'; Present = $false }
        )
        $r = New-KritHtmlReport -Title 'UnitTest' -Section @{ Tools = $data } -OutFile $out -NoOpen
        Test-Path -LiteralPath $out | Should -BeTrue
        (Get-Content -LiteralPath $out -Raw) | Should -Match 'Kritical'
        (Get-Content -LiteralPath $out -Raw) | Should -Match 'UnitTest'
        $r.Sections | Should -Be 1
    }

    It 'auto-creates the parent directory when OutFile parent does not exist' {
        $deepOut = Join-Path $script:Tmp ("missing-parent-" + [guid]::NewGuid() + "\sub\rpt.html")
        $data = @([pscustomobject]@{ X = 1; Y = 2 })
        { New-KritHtmlReport -Title 'AutoParent' -Section @{ T = $data } -OutFile $deepOut -NoOpen } | Should -Not -Throw
        Test-Path -LiteralPath $deepOut | Should -BeTrue
    }
}

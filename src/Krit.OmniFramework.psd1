@{
    RootModule        = 'Krit.OmniFramework.psm1'
    ModuleVersion     = '1.0.1'
    GUID              = 'b3d1f5c9-7a4e-4c8b-9e2f-1a7c3b8d2e4f'
    Author            = 'Joshua Finley'
    CompanyName       = 'Kritical Pty Ltd'
    Copyright         = '(c) 2026 Kritical Pty Ltd. All rights reserved.'
    Description       = 'Kritical OmniFramework — multi-OS PowerShell foundation. One Import-Module call gives you: structured logging (PSFramework), shared utilities (PSSharedGoods, disambiguated from psutil), HTML reporting (PSWriteHTML), Office/Word/PDF output (PSWriteOffice), Excel I/O (ImportExcel), OS+distro+architecture detection across Windows/macOS/Linux, FHS/LSB-aware tool-inventory walker, and Kritical-branded report templates. Built to stand under Krit.Hardening and every other Krit.* package.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop','Core')

    # We declare these as required so Install-Module pulls them transitively on PSGallery install.
    # Versions pinned to known-good floors; consumers can use newer.
    RequiredModules   = @(
        @{ ModuleName = 'PSFramework';    ModuleVersion = '1.10.318' },
        @{ ModuleName = 'PSSharedGoods';  ModuleVersion = '0.0.290' },
        @{ ModuleName = 'PSWriteHTML';    ModuleVersion = '1.27.0' },
        @{ ModuleName = 'ImportExcel';    ModuleVersion = '7.8.6' }
    )
    # PSWriteOffice ships PSWriteWord/Excel/PowerPoint via separate modules in some versions; treat as optional.

    FunctionsToExport = @(
        # Banner
        'Write-KritBanner', 'Get-KritBanner',
        # Platform / OS detection
        'Get-KritPlatform', 'Test-KritIsAdmin', 'Test-KritIsElevated',
        # Tool inventory (multi-OS, FHS/LSB-aware)
        'Get-KritToolInventory', 'Find-KritTool', 'Test-KritToolPresent',
        # Foundation loader
        'Import-KritFoundation', 'Get-KritFoundationStatus',
        # Structured logging (PSFramework-backed)
        'Write-KritLog', 'Start-KritLogSession', 'Stop-KritLogSession',
        # Branded reporting
        'New-KritHtmlReport', 'New-KritExcelReport',
        # Config + path resolution (carried forward from Pax8FrameworkConfig)
        'Resolve-KritRepoRoot', 'Get-KritConfig', 'Get-KritProject', 'Get-KritPath',
        # Secrets posture (read-only)
        'Test-KritSecretsLoaded'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Kritical','OmniFramework','Framework','PSFramework','PSSharedGoods','PSWriteHTML','PSWriteOffice','ImportExcel','MultiOS','CrossPlatform','OSDetect','Hardening','MSP','Automation')
            LicenseUri   = 'https://kritical.net/legal/license'
            ProjectUri   = 'https://github.com/Sir-J-AU/Krit.OmniFramework'
            IconUri      = 'https://kritical.net/assets/horizontal_logo.png'
            ReleaseNotes = @'
1.0.1 - Bug fix.
  * New-KritHtmlReport now auto-creates the parent directory of -OutFile
    before calling PSWriteHTML's Save-HTML (which would otherwise fall back
    to %TEMP% and emit a warning).

1.0.0 — Initial release.
  * Multi-OS platform detection (Windows / macOS / Linux + distro + arch + privilege).
  * FHS/LSB-aware tool inventory (Get-KritToolInventory walks every standard path per OS).
  * Foundation loader (Import-KritFoundation pulls PSFramework + PSSharedGoods + PSWriteHTML + ImportExcel in one call).
  * Structured logging via PSFramework (Write-KritLog with JSON + Application Insights sinks).
  * Branded HTML + Excel reports (New-KritHtmlReport / New-KritExcelReport) with the canonical Kritical banner embedded.
  * Repo-root + config resolution carried forward from the original Pax8FrameworkConfig.
  * Pester unit + e2e test suite.
  * Joshua Finley, Kritical Pty Ltd.
'@
        }
    }
}

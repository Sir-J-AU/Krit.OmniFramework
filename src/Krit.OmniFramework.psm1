<#
.SYNOPSIS
    Krit.OmniFramework - Kritical multi-OS PowerShell foundation.

.DESCRIPTION
    Single Import-Module brings up the Kritical PowerShell foundation:
      - PSFramework (logging, configuration)
      - PSSharedGoods (shared utilities; disambiguated from psutil)
      - PSWriteHTML (HTML reports)
      - ImportExcel (Excel I/O)
      - Optional: PSWriteOffice / PSWriteWord / PSWritePDF when present
    Plus Kritical primitives:
      - Multi-OS detection (Windows/macOS/Linux + distro + arch + privilege)
      - FHS/LSB-aware tool inventory across every standard path per OS
      - Kritical-branded report templates and the canonical brand banner

.AUTHOR
    Joshua Finley - Kritical Pty Ltd - https://kritical.net
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Dot-source Private then Public
$here = Split-Path -Parent $PSCommandPath
foreach ($dir in 'Private','Public') {
    $folder = Join-Path $here $dir
    if (Test-Path -LiteralPath $folder) {
        Get-ChildItem -LiteralPath $folder -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
            . $_.FullName
        }
    }
}

Export-ModuleMember -Function @(
    'Write-KritBanner', 'Get-KritBanner',
    'Get-KritPlatform', 'Test-KritIsAdmin', 'Test-KritIsElevated',
    'Get-KritToolInventory', 'Find-KritTool', 'Test-KritToolPresent',
    'Import-KritFoundation', 'Get-KritFoundationStatus',
    'Write-KritLog', 'Start-KritLogSession', 'Stop-KritLogSession',
    'New-KritHtmlReport', 'New-KritExcelReport',
    'Resolve-KritRepoRoot', 'Get-KritConfig', 'Get-KritProject', 'Get-KritPath',
    'Test-KritSecretsLoaded'
)

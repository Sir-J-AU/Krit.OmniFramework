function New-KritBrandedDocument {
    <#
    .SYNOPSIS
        Renders a Markdown (or HTML) source file to a Kritical-branded artefact
        in one or more output formats: PDF, DOCX, HTML.

    .DESCRIPTION
        End-to-end pipeline for customer proposals, internal reports, training
        decks etc. Pulls brand spec from Get-KritBrandSpec (single source of
        truth). Applies:
          - Primary colour (#13365C Kritical dark blue) on headings + tables
          - Secondary colour (#15AFD1 Kritical cyan) on accents
          - Roboto headings + Assistant sub-headings (via @font-face when fonts
            available in Kritical-Branding/public/fonts/)
          - Horizontal_Logo.png in header
          - Canonical footer (ABN, ACN, address, tagline, phone, email, web)
          - Optional Outlook email signature appended

        Render engines (auto-detected; first match wins):
          - PDF:  Pandoc + wkhtmltopdf  (preferred)
                  Pandoc + Chrome / Edge headless  (fallback)
                  Markdown-it + Chrome headless  (last-ditch)
          - DOCX: Pandoc --reference-doc=Kritical-BaseTemplate-CURRENT.docx
          - HTML: Pandoc + brand-aligned CSS, single-file with base64 images

        Output filename: <CustomerName>-<DocumentTitle>-<utc-stamp>.<ext>

    .PARAMETER Source
        Path to source .md or .html file.

    .PARAMETER OutDir
        Output directory. Created if missing.

    .PARAMETER Format
        One or more of: PDF, DOCX, HTML. Default: PDF + DOCX + HTML.

    .PARAMETER CustomerName
        Customer name (e.g. 'Kitchenworx', 'EES'). Used in output filename + Word
        --metadata for use in templates.

    .PARAMETER DocumentTitle
        Short document title (e.g. 'Proposal-Cover', 'Rate-Card').

    .PARAMETER EmbedSignature
        Append the Outlook signature (email-signature.htm) at the end of the
        rendered HTML / PDF (not DOCX).

    .PARAMETER NoFooter
        Skip the canonical footer (rare; only for unbranded internal previews).

    .PARAMETER NoBanner
        Skip the Kritical banner Write-Host on console.

    .EXAMPLE
        New-KritBrandedDocument -Source .\Kitchenworx-Proposal.md `
            -OutDir .\out -CustomerName Kitchenworx -DocumentTitle Proposal-Cover

    .EXAMPLE
        # PDF only
        New-KritBrandedDocument -Source .\report.md -OutDir .\out -Format PDF `
            -CustomerName Internal -DocumentTitle Q2-Report

    .EXAMPLE
        # Bulk a folder of .md files
        Get-ChildItem .\drafts\*.md | ForEach-Object {
            New-KritBrandedDocument -Source $_.FullName -OutDir .\out `
                -CustomerName EES -DocumentTitle ($_.BaseName)
        }

    .NOTES
        Author: Joshua Finley - Kritical Pty Ltd
        Inventory: Github/KRTPax8ToShopifyConnector/reference/KRITICAL-BRAND-ASSET-INVENTORY-1507.md
        Architecture: KRITICAL-BRAND-ASSET-INVENTORY-1507 section 8
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string]   $Source,
        [Parameter(Mandatory)] [string]   $OutDir,
        [ValidateSet('PDF','DOCX','HTML')] [string[]] $Format = @('PDF','DOCX','HTML'),
        [Parameter(Mandatory)] [string]   $CustomerName,
        [Parameter(Mandatory)] [string]   $DocumentTitle,
        [switch] $EmbedSignature,
        [switch] $NoFooter,
        [switch] $NoBanner
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source file not found: $Source"
    }
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

    if (-not $NoBanner.IsPresent) {
        try { Write-KritBanner -Title "BrandedDocument: $CustomerName - $DocumentTitle" -Compact } catch { }
    }

    $spec = Get-KritBrandSpec
    $brandRoot = $null
    if ($env:USERPROFILE) {
        $candidate = Join-Path $env:USERPROFILE 'OneDrive - Kritical Pty Ltd\Kritical-Branding\public'
        if (Test-Path -LiteralPath $candidate) { $brandRoot = $candidate }
    }

    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmssZ')
    $safeCustomer = ($CustomerName -replace '[^\w\-]','_')
    $safeTitle    = ($DocumentTitle -replace '[^\w\-]','_')
    $baseName     = "{0}-{1}-{2}" -f $safeCustomer, $safeTitle, $stamp

    # Build the brand-aligned CSS once; reused for HTML + PDF-via-headless paths.
    $primary    = $spec.colours.primary.kriticalDarkBlue
    $secondary  = $spec.colours.secondary.kriticalCyan
    $lightGrey  = $spec.colours.secondary.lightGrey
    $textColor  = $spec.colours.tertiary.black
    $entity     = $spec.entity
    $contact    = $spec.contact
    $messaging  = $spec.messaging

    $logoPath = $null
    if ($brandRoot) {
        $logoCandidate = Join-Path $brandRoot 'logos\Horizontal_Logo.png'
        if (Test-Path -LiteralPath $logoCandidate) { $logoPath = $logoCandidate }
    }

    $logoDataUri = ''
    if ($logoPath) {
        $bytes = [IO.File]::ReadAllBytes($logoPath)
        $logoDataUri = "data:image/png;base64,$([Convert]::ToBase64String($bytes))"
    }

    $sigDataHtml = ''
    if ($EmbedSignature.IsPresent -and $brandRoot) {
        $sigPath = Join-Path $brandRoot 'email-signature.htm'
        if (Test-Path -LiteralPath $sigPath) {
            $sigDataHtml = Get-Content -LiteralPath $sigPath -Raw -Encoding UTF8
        }
    }

    $footerHtml = if ($NoFooter.IsPresent) { '' } else {
        @"
<footer class="kr-footer">
  <div class="kr-tagline"><em>$($messaging.tagline)</em></div>
  <div class="kr-corp">$($entity.legalName) &middot; ABN $($entity.abn) &middot; ACN $($entity.acn)</div>
  <div class="kr-corp">$($entity.registeredAddress)</div>
  <div class="kr-contact">$($contact.phoneMain) &middot; <a href="mailto:$($contact.emailSales)">$($contact.emailSales)</a> &middot; <a href="$($contact.webPrimary)">$($contact.webPrimary)</a></div>
</footer>
"@
    }

    $headerHtml = if ($logoDataUri) {
        "<header class='kr-header'><img src='$logoDataUri' alt='Kritical' class='kr-logo'/><div class='kr-positioning'>$($messaging.positioning)</div></header>"
    } else {
        "<header class='kr-header'><div class='kr-wordmark'>Kritical&trade;</div><div class='kr-positioning'>$($messaging.positioning)</div></header>"
    }

    $css = @"
@font-face { font-family:'Roboto';    src: local('Roboto'); font-weight: normal; }
@font-face { font-family:'Assistant'; src: local('Assistant'); font-weight: 500; }
* { box-sizing: border-box; }
html,body { margin:0; padding:0; }
body { font-family: 'Assistant', 'Segoe UI', Calibri, Arial, sans-serif; color:$textColor; line-height:1.55; font-size: 11pt; max-width: 1100px; margin: 0 auto; padding: 1.5em 1em 3em 1em; background:#fff; }
h1,h2,h3,h4 { font-family: 'Roboto', 'Segoe UI', Calibri, Arial, sans-serif; color:$primary; font-weight: normal; line-height:1.25; margin: 1.2em 0 0.5em 0; }
h1 { font-size: 28pt; border-bottom: 3px solid $primary; padding-bottom: 0.2em; }
h2 { font-size: 18pt; border-bottom: 1px solid $secondary; padding-bottom: 0.15em; margin-top: 1.8em; }
h3 { font-size: 14pt; color: $primary; }
h4 { font-size: 12pt; color: $secondary; }
p { margin: 0.5em 0; }
strong { color: $primary; }
a { color: $secondary; text-decoration: none; }
a:hover { text-decoration: underline; }
table { border-collapse: collapse; margin: 1em 0; width: 100%; }
th, td { border: 1px solid $lightGrey; padding: 0.5em 0.75em; text-align: left; vertical-align: top; font-size: 10pt; }
th { background: $primary; color: #fff; font-family: 'Roboto', Calibri, sans-serif; font-weight: normal; }
tr:nth-child(even) td { background: #f7f9fb; }
blockquote { border-left: 4px solid $primary; margin: 1em 0; padding: 0.5em 1em; background: $lightGrey; color: $textColor; }
code { background: $lightGrey; padding: 0.1em 0.4em; font-family: Consolas, 'Courier New', monospace; font-size: 10pt; }
pre { background: $lightGrey; padding: 0.8em; overflow-x: auto; font-family: Consolas, monospace; font-size: 9.5pt; border-left: 4px solid $secondary; }
hr { border: 0; border-top: 1px solid $lightGrey; margin: 1.5em 0; }
ul, ol { margin: 0.5em 0 0.5em 1.5em; padding: 0; }
li { margin: 0.2em 0; }
.kr-header { display: flex; align-items: center; justify-content: space-between; border-bottom: 2px solid $primary; padding: 0 0 0.6em 0; margin-bottom: 1.5em; }
.kr-logo { max-height: 56px; }
.kr-wordmark { font-family: 'Roboto', sans-serif; font-size: 22pt; color: $primary; }
.kr-positioning { font-family: 'Assistant', sans-serif; font-size: 9pt; color: $primary; text-align: right; }
.kr-footer { margin-top: 3em; padding-top: 0.8em; border-top: 1px solid $primary; font-size: 8.5pt; color: $textColor; text-align: center; }
.kr-tagline { color: $primary; font-size: 10pt; margin-bottom: 0.3em; }
.kr-corp { color: $textColor; opacity: 0.85; }
.kr-contact { color: $secondary; margin-top: 0.2em; }
.kr-signature { margin-top: 2em; padding-top: 1em; border-top: 1px dashed $lightGrey; font-size: 10pt; }
@page { size: A4; margin: 18mm; }
@media print {
  body { max-width: none; padding: 0; }
  .kr-header { page-break-after: avoid; }
  h1, h2, h3 { page-break-after: avoid; }
  table, tr, td, th { page-break-inside: avoid; }
}
"@

    # --- Render Markdown source -> HTML via Pandoc (preferred) -----------------------
    $haveP = $null -ne (Get-Command pandoc -ErrorAction SilentlyContinue)
    $haveW = $null -ne (Get-Command wkhtmltopdf -ErrorAction SilentlyContinue)
    $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    if (-not (Test-Path -LiteralPath $chromePath)) { $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" }
    $haveChrome = Test-Path -LiteralPath $chromePath
    $edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    $haveEdge = Test-Path -LiteralPath $edgePath
    $headlessBrowser = if ($haveChrome) { $chromePath } elseif ($haveEdge) { $edgePath } else { $null }

    if (-not $haveP) {
        throw "Pandoc is required for New-KritBrandedDocument. Install: winget install --id JohnMacFarlane.Pandoc"
    }

    $intermediateHtml = Join-Path $OutDir ("{0}-intermediate.html" -f $baseName)
    $isHtml = ([IO.Path]::GetExtension($Source)).ToLowerInvariant() -eq '.html'

    # Generate the styled HTML body wrapper
    $bodyHtmlPath = Join-Path $OutDir ("{0}-body.html" -f $baseName)
    if ($isHtml) {
        Copy-Item -LiteralPath $Source -Destination $bodyHtmlPath -Force
    } else {
        & pandoc $Source -f 'gfm+raw_html' -t html5 -o $bodyHtmlPath 2>&1 | Write-Verbose
    }
    $bodyHtml = Get-Content -LiteralPath $bodyHtmlPath -Raw -Encoding UTF8

    $fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$($entity.tradeName) - $CustomerName - $DocumentTitle</title>
<meta name="author" content="$($messaging.directorName)">
<meta name="generator" content="Krit.OmniFramework / New-KritBrandedDocument">
<style>$css</style>
</head>
<body>
$headerHtml
$bodyHtml
$footerHtml
$(if ($sigDataHtml) { "<div class='kr-signature'>$sigDataHtml</div>" })
</body>
</html>
"@

    Set-Content -LiteralPath $intermediateHtml -Value $fullHtml -Encoding UTF8
    Remove-Item -LiteralPath $bodyHtmlPath -ErrorAction SilentlyContinue

    $results = [System.Collections.Generic.List[pscustomobject]]::new()

    # --- HTML output -------------------------------------------------------------
    if ($Format -contains 'HTML') {
        $htmlOut = Join-Path $OutDir ("{0}.html" -f $baseName)
        Copy-Item -LiteralPath $intermediateHtml -Destination $htmlOut -Force
        $results.Add([pscustomobject]@{ Format='HTML'; Path=$htmlOut; Engine='pandoc+css'; Size=(Get-Item $htmlOut).Length })
    }

    # --- PDF output --------------------------------------------------------------
    if ($Format -contains 'PDF') {
        $pdfOut = Join-Path $OutDir ("{0}.pdf" -f $baseName)
        if ($haveW) {
            & wkhtmltopdf --enable-local-file-access --quiet $intermediateHtml $pdfOut 2>&1 | Write-Verbose
            $engine = 'wkhtmltopdf'
        } elseif ($headlessBrowser) {
            $absUri = ([Uri]$intermediateHtml).AbsoluteUri
            & $headlessBrowser --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdfOut" $absUri 2>&1 | Write-Verbose
            $engine = if ($chromePath -eq $headlessBrowser) { 'chrome-headless' } else { 'edge-headless' }
        } else {
            Write-Warning "No PDF engine available (wkhtmltopdf / Chrome / Edge). Skipping PDF for $baseName."
            $engine = $null
        }
        if ($engine -and (Test-Path -LiteralPath $pdfOut)) {
            $results.Add([pscustomobject]@{ Format='PDF'; Path=$pdfOut; Engine=$engine; Size=(Get-Item $pdfOut).Length })
        }
    }

    # --- DOCX output (via Pandoc --reference-doc) --------------------------------
    if ($Format -contains 'DOCX') {
        $docxOut = Join-Path $OutDir ("{0}.docx" -f $baseName)
        $referenceDoc = $null
        if ($brandRoot) {
            $candidate = Join-Path $brandRoot 'Kritical-BaseTemplate-CURRENT.docx'
            if (Test-Path -LiteralPath $candidate) { $referenceDoc = $candidate }
        }
        $pargs = @(
            $Source
            '-f', 'gfm+raw_html'
            '-t', 'docx'
            '--metadata', "title=$CustomerName - $DocumentTitle"
            '--metadata', "author=$($messaging.directorName)"
            '-o', $docxOut
        )
        if ($referenceDoc) { $pargs += '--reference-doc'; $pargs += $referenceDoc }
        & pandoc @pargs 2>&1 | Write-Verbose
        if (Test-Path -LiteralPath $docxOut) {
            $engine = if ($referenceDoc) { "pandoc+reference-doc" } else { "pandoc (no template)" }
            $results.Add([pscustomobject]@{ Format='DOCX'; Path=$docxOut; Engine=$engine; Size=(Get-Item $docxOut).Length })
        }
    }

    # --- Cleanup intermediate ----------------------------------------------------
    Remove-Item -LiteralPath $intermediateHtml -ErrorAction SilentlyContinue

    [pscustomobject]@{
        Source          = (Resolve-Path -LiteralPath $Source).Path
        OutDir          = (Resolve-Path -LiteralPath $OutDir).Path
        CustomerName    = $CustomerName
        DocumentTitle   = $DocumentTitle
        BaseName        = $baseName
        BrandSpecSource = if ($spec.PSObject.Properties['_sourcePath']) { $spec._sourcePath } else { 'fallback' }
        Outputs         = @($results)
        RenderedAtUtc   = (Get-Date).ToUniversalTime()
    }
}

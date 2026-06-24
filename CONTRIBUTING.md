# Contributing to Krit.OmniFramework

```text
·· × × × ···  SirJ's Deaddrop  ··· × × × ···
---------------- A Seriously Kritical™ Production ----------------
```

Author: Joshua Finley — Kritical Pty Ltd — <https://kritical.net>

Outside contributions require a Contributor License Agreement; reach Kritical at +61 1300 274 655 or `sales at kritical dot net` before opening a PR.

## Local dev

- PowerShell 7+ recommended (PS 5.1 works for everything except OS-detection on non-Windows).
- Pester 5.5+ for tests: `Install-Module Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck -Scope CurrentUser`.

## Code standards

- `Set-StrictMode -Version Latest`.
- Comment-based help on every public function (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.NOTES Author: Joshua Finley - Kritical Pty Ltd`).
- Private helpers go in `src/Private/`; public in `src/Public/`; all dot-sourced by the root `.psm1`.
- Every operator-facing path emits the Kritical banner via `Write-KritBanner` (full or compact).
- No `Claude` / `Hermes` / `Codex` / `Copilot` / `GPT` strings anywhere in published output.

## Tests

```powershell
.\tests\Invoke-AllTests.ps1
```

Output lands at `%LOCALAPPDATA%\Kritical\Krit.OmniFramework\test-output\`. Exit 0 = all pass.

## Versioning + publish

See [docs/PUBLISHING.md](docs/PUBLISHING.md).

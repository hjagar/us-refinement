param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('patch','minor','major')]
    [string]$ReleaseType
)

$ErrorActionPreference = "Stop"

Write-Host "=== Release-Repo ===" -ForegroundColor Cyan

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

# [1/5] Quality gate
Write-Host "[1/5] Quality gate..." -ForegroundColor Cyan

# Prerequisites checks
if (-not (Get-Command shellcheck -ErrorAction SilentlyContinue)) {
    Write-Host "shellcheck not found. Install: winget install koalaman.shellcheck" -ForegroundColor Red
    exit 1
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "python not found. Please install Python 3." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "gh CLI not found. Please install GitHub CLI." -ForegroundColor Red
    exit 1
}

# Shellcheck loop
$shFiles = Get-ChildItem -Path $repoRoot -Filter *.sh -File
foreach ($file in $shFiles) {
    Write-Host "  checking $($file.Name)..." -ForegroundColor Gray
    shellcheck $file.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "shellcheck failed on $($file.Name). Aborting." -ForegroundColor Red
        exit 1
    }
}
Write-Host "  All shell scripts passed shellcheck." -ForegroundColor Green

# Python validation tests
Write-Host "  Running Python validation on mock_valid_us.md (expecting success)..." -ForegroundColor Gray
python scripts/validate_refinement.py tests/mock_valid_us.md
if ($LASTEXITCODE -ne 0) {
    Write-Host "Validation failed on mock_valid_us.md. Aborting." -ForegroundColor Red
    exit 1
}
Write-Host "  Running Python validation on mock_invalid_us.md (expecting failure)..." -ForegroundColor Gray
python scripts/validate_refinement.py tests/mock_invalid_us.md 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Validation unexpectedly succeeded on mock_invalid_us.md. Aborting." -ForegroundColor Red
    exit 1
}
Write-Host "  All quality gate checks passed." -ForegroundColor Green

# [2/5] Version bump
Write-Host "[2/5] Version bump..." -ForegroundColor Cyan
$lastTag = $null
try {
    $lastTag = git describe --tags --abbrev=0 2>$null
    if ($lastTag) { $lastTag = $lastTag.Trim() }
} catch {
    $lastTag = $null
}
if ([string]::IsNullOrWhiteSpace($lastTag)) {
    $nextVersion = "v1.0.0"
    Write-Host "  No existing tags. Proposing first release $nextVersion." -ForegroundColor Yellow
} else {
    $parts = $lastTag.TrimStart('v').Split('.')
    $major = [int]$parts[0]; $minor = [int]$parts[1]; $patch = [int]$parts[2]
    switch ($ReleaseType) {
        'major' { $major++; $minor = 0; $patch = 0 }
        'minor' { $minor++; $patch = 0 }
        'patch' { $patch++ }
    }
    $nextVersion = "v$major.$minor.$patch"
    Write-Host "  $lastTag -> $nextVersion ($ReleaseType)" -ForegroundColor Green
}

$confirm = Read-Host "Create release $nextVersion? (y/N)"
if ($confirm -notin @('y','Y')) {
    Write-Host "Cancelled. Nothing was created." -ForegroundColor Gray
    exit 0
}

# [3/5] Package
Write-Host "[3/5] Packaging..." -ForegroundColor Cyan
$buildDir = Join-Path $repoRoot 'build'
$zipPath  = Join-Path $buildDir 'us-refinement.zip'
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir | Out-Null

$items = @(
    (Join-Path $repoRoot "SKILL.md"),
    (Join-Path $repoRoot "us-refinement-uninstall.ps1"),
    (Join-Path $repoRoot "us-refinement-uninstall.sh")
)
Compress-Archive -Path $items -DestinationPath $zipPath -Force
Write-Host "  Created build/us-refinement.zip" -ForegroundColor Green

# [4/5] Tag + push
Write-Host "[4/5] Tag + push..." -ForegroundColor Cyan
git tag -a $nextVersion -m "Release $nextVersion"
if ($LASTEXITCODE -ne 0) { Write-Host "git tag failed." -ForegroundColor Red; exit 1 }
git push --follow-tags
if ($LASTEXITCODE -ne 0) { Write-Host "git push failed." -ForegroundColor Red; exit 1 }
Write-Host "  Tagged and pushed $nextVersion." -ForegroundColor Green

# [5/5] Publish + cleanup
Write-Host "[5/5] Publishing GitHub release..." -ForegroundColor Cyan
gh release create $nextVersion $zipPath --generate-notes
if ($LASTEXITCODE -ne 0) {
    Write-Host "gh release create failed (check 'gh auth status'). Tag $nextVersion is already pushed - re-run after auth to reuse it." -ForegroundColor Red
    exit 1
}
Remove-Item $buildDir -Recurse -Force
Write-Host "`nDone. Release $nextVersion published." -ForegroundColor Green

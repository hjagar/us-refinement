[CmdletBinding()]
param(
    [switch]$Local,
    [string]$Path
)

$ErrorActionPreference = "Stop"

# 1. Prerequisites Check
Write-Host "Checking prerequisites..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git is required to use this skill."
    exit 1
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Warning "Warning: gh CLI was not found. Issue refinement write-backs will fallback to copy/paste."
}

# 2. Path Setup
$HomeDir = $env:USERPROFILE
$CentralDir = Join-Path $HomeDir ".hjagar\skills\us-refinement"
$AgentPaths = [System.Collections.Generic.List[string]]::new()
$AgentPaths.Add((Join-Path $HomeDir ".gemini\skills\us-refinement"))
$AgentPaths.Add((Join-Path $HomeDir ".claude\skills\us-refinement"))
$AgentPaths.Add((Join-Path $HomeDir ".config\opencode\skills\us-refinement"))
$AgentPaths.Add((Join-Path $HomeDir ".copilot\skills\us-refinement"))
$AgentPaths.Add((Join-Path $HomeDir ".agents\skills\us-refinement"))
$AgentPaths.Add((Join-Path $HomeDir ".cursor\skills\us-refinement"))

if (Test-Path $HomeDir) {
    Get-ChildItem -Path $HomeDir -Filter ".claude-*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $AgentPaths.Add((Join-Path $_.FullName "skills\us-refinement"))
    }
}

$SrcDir = if ($Path) { Resolve-Path $Path } else { $PSScriptRoot }

# 3. Payload Copy Helper (SKILL.md + scripts/ + tests/ — docs/ excluded on purpose)
# Stages the payload in a sibling ".staging" dir and swaps it into place only after every
# copy succeeds, so a mid-copy failure leaves the existing installed payload untouched.
function Copy-SkillFile ($targetPath, $sourcePath) {
    $stagingPath = "$targetPath.staging"
    if (Test-Path $stagingPath) {
        Remove-Item -Path $stagingPath -Force -Recurse | Out-Null
    }
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

    $srcFile = Join-Path $sourcePath "SKILL.md"
    if (Test-Path $srcFile) {
        Write-Host "Copying SKILL.md to: $targetPath"
        Copy-Item -Path $srcFile -Destination $stagingPath -Force
    } else {
        Write-Error "Error: SKILL.md not found at $sourcePath"
        Remove-Item -Path $stagingPath -Force -Recurse | Out-Null
        exit 1
    }

    foreach ($dir in @("scripts", "tests")) {
        $srcDir = Join-Path $sourcePath $dir
        if (Test-Path $srcDir) {
            Write-Host "Copying $dir/ to: $targetPath"
            Copy-Item -Path $srcDir -Destination $stagingPath -Recurse -Force
        } else {
            Write-Warning "Warning: $dir/ not found at $sourcePath - skipping."
        }
    }

    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Force -Recurse | Out-Null
    }
    Move-Item -Path $stagingPath -Destination $targetPath
}

# 4. Installation Logic
if ($Local) {
    Write-Host "Installing us-refinement in LOCAL Mode..."
    foreach ($agent in $AgentPaths) {
        Copy-SkillFile $agent $SrcDir
    }
} else {
    Write-Host "Installing us-refinement in GLOBAL Mode..."
    if (Test-Path $CentralDir) {
        Remove-Item -Path $CentralDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $CentralDir -Force | Out-Null
    
    $zipUrl = "https://github.com/hjagar/us-refinement/releases/latest/download/us-refinement.zip"
    $tempZip = Join-Path $env:TEMP ("us-refinement-" + [System.Guid]::NewGuid().ToString() + ".zip")
    $downloadSuccess = $false
    
    # Try downloading via gh CLI first (useful for private repos)
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        try {
            Write-Host "Downloading latest release ZIP using GitHub CLI..."
            & gh release download --repo hjagar/us-refinement --pattern "us-refinement.zip" --output $tempZip --clobber 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $tempZip)) {
                $downloadSuccess = $true
            }
        } catch {
            # Ignore and fallback
        }
    }
    
    # Fallback to Invoke-WebRequest
    if (-not $downloadSuccess) {
        try {
            Write-Host "Downloading latest release ZIP from public GitHub URL..."
            Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing
            $downloadSuccess = $true
        } catch {
            Write-Error "Failed to download release ZIP: $_"
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
            exit 1
        }
    }
    
    try {
        Write-Host "Extracting release ZIP..."
        Expand-Archive -Path $tempZip -DestinationPath $CentralDir -Force
    } catch {
        Write-Error "Failed to extract release ZIP: $_"
        if (Test-Path $CentralDir) { Remove-Item $CentralDir -Recurse -Force }
        exit 1
    } finally {
        if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    }
    
    foreach ($agent in $AgentPaths) {
        Copy-SkillFile $agent $CentralDir
    }
}

Write-Host "Installation completed successfully!"

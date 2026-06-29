[CmdletBinding()]
param(
    [switch]$Local,
    [string]$Path
)

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
$CentralDir = Join-Path $HomeDir ".config\skills\us-refinement"
$AgentPaths = @(
    (Join-Path $HomeDir ".gemini\skills\us-refinement"),
    (Join-Path $HomeDir ".claude\skills\us-refinement"),
    (Join-Path $HomeDir ".config\opencode\skills\us-refinement")
)

$SrcDir = if ($Path) { Resolve-Path $Path } else { $PSScriptRoot }

# 3. Directory Link Helper
function Create-Link ($targetPath, $sourcePath) {
    $parentDir = Split-Path $targetPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath
        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            if ($item.Target -eq $sourcePath) {
                Write-Host "Link already exists and points to the correct target: $targetPath -> $sourcePath"
                return
            } else {
                Write-Host "Link points to a different target ($($item.Target)). Recreating..."
                Remove-Item -Path $targetPath -Recurse -Force
            }
        } else {
            Write-Host "Physical directory found at $targetPath. Removing to replace with link..."
            Remove-Item -Path $targetPath -Recurse -Force
        }
    }
    
    Write-Host "Creating Junction: $targetPath -> $sourcePath"
    # Create Junction to prevent requiring elevation
    New-Item -ItemType Junction -Path $targetPath -Value $sourcePath | Out-Null
}

# 4. Installation Logic
if ($Local) {
    Write-Host "Installing us-refinement in LOCAL Mode..."
    foreach ($agent in $AgentPaths) {
        Create-Link $agent $SrcDir
    }
} else {
    Write-Host "Installing us-refinement in GLOBAL Mode..."
    if (Test-Path $CentralDir) {
        Remove-Item -Path $CentralDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $CentralDir -Force | Out-Null
    
    # Copy essential skill items
    Copy-Item -Path (Join-Path $SrcDir "SKILL.md") -Destination $CentralDir -Force
    if (Test-Path (Join-Path $SrcDir "scripts")) {
        Copy-Item -Path (Join-Path $SrcDir "scripts") -Destination $CentralDir -Recurse -Force
    }
    if (Test-Path (Join-Path $SrcDir "docs")) {
        Copy-Item -Path (Join-Path $SrcDir "docs") -Destination $CentralDir -Recurse -Force
    }
    if (Test-Path (Join-Path $SrcDir "tests")) {
        Copy-Item -Path (Join-Path $SrcDir "tests") -Destination $CentralDir -Recurse -Force
    }
    
    foreach ($agent in $AgentPaths) {
        Create-Link $agent $CentralDir
    }
}

Write-Host "Installation completed successfully!"

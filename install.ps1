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
$CentralDir = Join-Path $HomeDir ".hjagar\skills\us-refinement"
$AgentPaths = @(
    (Join-Path $HomeDir ".gemini\skills\us-refinement"),
    (Join-Path $HomeDir ".claude\skills\us-refinement"),
    (Join-Path $HomeDir ".config\opencode\skills\us-refinement"),
    (Join-Path $HomeDir ".copilot\skills\us-refinement"),
    (Join-Path $HomeDir ".agents\skills\us-refinement")
)

$SrcDir = if ($Path) { Resolve-Path $Path } else { $PSScriptRoot }

# 3. Directory Link Helper
function New-Link ($targetPath, $sourcePath) {
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
        New-Link $agent $SrcDir
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
        New-Link $agent $CentralDir
    }
}

Write-Host "Installation completed successfully!"

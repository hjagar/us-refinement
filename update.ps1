# us-refinement Auto-Updater for Windows
$ErrorActionPreference = "Stop"

$HomeDir = $env:USERPROFILE
$CentralDir = Join-Path $HomeDir ".hjagar\skills\us-refinement"
$LocalSkill = Join-Path $CentralDir "SKILL.md"

Write-Host "Checking for updates..." -ForegroundColor Cyan

# 1. Read local version
if (-not (Test-Path $LocalSkill)) {
    Write-Error "Error: us-refinement is not installed globally at $CentralDir. Run install.ps1 first."
    exit 1
}

$localContent = Get-Content $LocalSkill -Raw
$localVersion = "v0.0.0"
if ($localContent -match '<!-- version: (v[\d\.]+) -->') {
    $localVersion = $Matches[1]
}

Write-Host "Local version: $localVersion" -ForegroundColor Gray

# 2. Fetch latest remote version from GitHub
$repo = "hjagar/us-refinement"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$latestVersion = $null

try {
    # Skip basic parsing issues
    $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
    $latestVersion = $release.tag_name
} catch {
    Write-Warning "Failed to query GitHub API. Check connection."
    exit 1
}

if (-not $latestVersion) {
    Write-Warning "No release version info found."
    exit 1
}

Write-Host "Latest remote version: $latestVersion" -ForegroundColor Gray

# 3. Compare versions
if ($localVersion -eq $latestVersion) {
    Write-Host "You are already on the latest version: $localVersion" -ForegroundColor Green
    exit 0
}

Write-Host "New version $latestVersion is available! Updating..." -ForegroundColor Cyan

# 4. Perform download and safe update
$zipUrl = "https://github.com/$repo/releases/latest/download/us-refinement.zip"
$tempZip = Join-Path $env:TEMP "us-refinement-update-$latestVersion.zip"
$tempExtractDir = Join-Path $env:TEMP "us-refinement-update-extract"

try {
    Write-Host "Downloading release archive..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $zipUrl -OutFile $tempZip -UseBasicParsing | Out-Null
    
    if (Test-Path $tempExtractDir) { Remove-Item $tempExtractDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempExtractDir | Out-Null
    
    Write-Host "Extracting archive..." -ForegroundColor Gray
    Expand-Archive -Path $tempZip -DestinationPath $tempExtractDir -Force
    
    # Safely overwrite central files (pisin' individual files to prevent locking on script itself)
    Write-Host "Updating central files..." -ForegroundColor Gray
    foreach ($dir in @("scripts", "tests")) {
        # Clear stale central-store dirs first: a plain merge-copy below would leave behind
        # files removed/renamed in the new release, and those orphans would then be
        # re-propagated to every agent path.
        $centralSubdir = Join-Path $CentralDir $dir
        if (Test-Path $centralSubdir) { Remove-Item -Path $centralSubdir -Force -Recurse }
    }
    Get-ChildItem -Path $tempExtractDir -Force | ForEach-Object {
        $destPath = Join-Path $CentralDir $_.Name
        Copy-Item -Path $_.FullName -Destination $destPath -Force -Recurse
    }
    
    # 5. Propagate SKILL.md + scripts/ + tests/ to all agents
    Write-Host "Updating agents..." -ForegroundColor Gray
    $AgentPaths = [System.Collections.Generic.List[string]]::new()
    $AgentPaths.Add((Join-Path $HomeDir ".gemini\skills\us-refinement"))
    $AgentPaths.Add((Join-Path $HomeDir ".config\opencode\skills\us-refinement"))
    $AgentPaths.Add((Join-Path $HomeDir ".copilot\skills\us-refinement"))
    $AgentPaths.Add((Join-Path $HomeDir ".agents\skills\us-refinement"))
    $AgentPaths.Add((Join-Path $HomeDir ".claude\skills\us-refinement"))
    $AgentPaths.Add((Join-Path $HomeDir ".cursor\skills\us-refinement"))

    # Multi-account support
    if (Test-Path $HomeDir) {
        Get-ChildItem -Path $HomeDir -Filter ".claude-*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $AgentPaths.Add((Join-Path $_.FullName "skills\us-refinement"))
        }
    }
    
    $newSkill = Join-Path $CentralDir "SKILL.md"
    foreach ($agent in $AgentPaths) {
        if (Test-Path $agent) {
            # Stage into a sibling dir and swap it into place only after every copy
            # succeeds, so a mid-copy failure leaves the previously-installed agent
            # payload untouched instead of wiped-and-broken.
            $staging = "$agent.staging"
            if (Test-Path $staging) { Remove-Item -Path $staging -Force -Recurse | Out-Null }
            New-Item -ItemType Directory -Path $staging -Force | Out-Null
            Copy-Item -Path $newSkill -Destination $staging -Force
            foreach ($dir in @("scripts", "tests")) {
                $srcDir = Join-Path $CentralDir $dir
                if (Test-Path $srcDir) {
                    Copy-Item -Path $srcDir -Destination $staging -Recurse -Force
                }
            }
            Remove-Item -Path $agent -Force -Recurse | Out-Null
            Move-Item -Path $staging -Destination $agent
            Write-Host "Updated agent skill path: $agent" -ForegroundColor Green
        }
    }

    # Kiro is a special case: a single generated steering file at
    # ~/.kiro/steering/us-refinement.md (SKILL.md's frontmatter with `inclusion: always`
    # injected), not a folder+SKILL.md copy - no scripts/ or tests/ payload.
    $kiroSteeringDir = Join-Path $HomeDir ".kiro\steering"
    $kiroTarget = Join-Path $kiroSteeringDir "us-refinement.md"
    if (Test-Path $kiroTarget) {
        $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
        $rawContent = [System.IO.File]::ReadAllText($newSkill, $utf8NoBom)
        $frontmatterStart = [regex]::Match($rawContent, "^---(\r?\n)")
        if (-not $frontmatterStart.Success) {
            Write-Error "Error: SKILL.md at $CentralDir does not start with a '---' YAML frontmatter delimiter - cannot update Kiro steering file."
            exit 1
        }
        $eol = $frontmatterStart.Groups[1].Value
        $insertPos = $frontmatterStart.Length
        $transformed = $rawContent.Substring(0, $insertPos) + "inclusion: always" + $eol + $rawContent.Substring($insertPos)
        $kiroStaging = "$kiroTarget.staging"
        [System.IO.File]::WriteAllText($kiroStaging, $transformed, $utf8NoBom)
        Remove-Item -Path $kiroTarget -Force
        Move-Item -Path $kiroStaging -Destination $kiroTarget
        Write-Host "Updated agent skill path: $kiroTarget" -ForegroundColor Green
    }

    Write-Host "Update completed successfully to version $latestVersion!" -ForegroundColor Green
}
catch {
    Write-Error "Error during update: $_"
    exit 1
}
finally {
    # Cleanup temp resources
    if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
    if (Test-Path $tempExtractDir) { Remove-Item $tempExtractDir -Recurse -Force }
}

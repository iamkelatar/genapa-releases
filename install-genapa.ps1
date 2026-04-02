#!/usr/bin/env pwsh

<#
.SYNOPSIS
    GENAPA Forge bootstrapper. Downloads and runs the platform-specific installer from GitHub Releases.
.DESCRIPTION
    Single-script entry point for installing GENAPA Forge. Detects the current OS, resolves the
    latest (or a pinned) release from the GitHub Releases API, downloads the correct platform
    bundle, verifies its SHA256 checksum, extracts it, and delegates to the root installer.

    Supports both piped execution (irm | iex) with defaults and direct file execution with parameters.
.EXAMPLE
    $env:GH_TOKEN = "<your-github-token>"
    & ([scriptblock]::Create((irm "https://api.github.com/repos/iamkelatar/genapa-releases/contents/install-genapa.ps1" -Headers @{Authorization="Bearer $env:GH_TOKEN";Accept="application/vnd.github.v3.raw"})))
.EXAMPLE
    .\install-genapa.ps1 -Version v1.2.0 -Slug test -GitHubToken $myToken
#>

param(
    [string]$Version,
    [string]$Slug = 'prod',
    [string]$InstallRoot,
    [switch]$Force,
    [switch]$PreRelease,
    [switch]$DownloadOnly,
    [string]$GitHubRepo = 'iamkelatar/genapa-releases',
    [string]$GitHubToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve GitHub auth token: explicit param > GH_TOKEN > GITHUB_TOKEN
if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    $GitHubToken = if ($env:GH_TOKEN) { $env:GH_TOKEN } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { '' }
}

$script:AuthHeaders = @{}
if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
    $script:AuthHeaders = @{
        Authorization = "Bearer $GitHubToken"
        Accept        = 'application/vnd.github+json'
    }
}

# region --- Output helpers ---

function Write-Banner {
    Write-Host ''
    Write-Host '  ================================================================' -ForegroundColor Cyan
    Write-Host '   GENAPA FORGE - EZ INSTALL' -ForegroundColor Cyan
    Write-Host '  ================================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Step([string]$Message) {
    Write-Host "  [*] $Message" -ForegroundColor Green
}

function Write-Info([string]$Message) {
    Write-Host "      $Message" -ForegroundColor Gray
}

function Write-Fail([string]$Message) {
    Write-Host "  [X] $Message" -ForegroundColor Red
}

# endregion

# region --- Prerequisite checks ---

function Assert-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Fail "PowerShell 7+ is required. Current version: $($PSVersionTable.PSVersion)"
        Write-Host ''
        Write-Host '      Install PowerShell 7:  https://aka.ms/install-powershell' -ForegroundColor Yellow
        exit 1
    }
}

function Assert-DockerRunning {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Fail 'Docker is not installed or not on PATH.'
        Write-Host ''
        if ($IsLinux) {
            Write-Host '      Install Docker Engine:  https://docs.docker.com/engine/install/' -ForegroundColor Yellow
        } elseif ($IsMacOS) {
            Write-Host '      Install Docker Desktop:  https://docs.docker.com/desktop/setup/install/mac-install/' -ForegroundColor Yellow
        } else {
            Write-Host '      Install Docker Desktop:  https://docs.docker.com/desktop/setup/install/windows-install/' -ForegroundColor Yellow
        }
        exit 1
    }

    try {
        $null = docker info 2>&1
        if ($LASTEXITCODE -ne 0) { throw 'docker info returned non-zero' }
    }
    catch {
        Write-Fail 'Docker is installed but not running.'
        Write-Host ''
        Write-Host '      Start Docker Desktop and wait for the engine to be ready, then re-run this script.' -ForegroundColor Yellow
        exit 1
    }
}

function Assert-NetworkConnectivity {
    try {
        $null = Invoke-RestMethod -Uri 'https://api.github.com' -Method Head -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Fail 'Cannot reach the GitHub API (https://api.github.com).'
        Write-Host ''
        Write-Host '      Check your internet connection, proxy settings, and firewall rules.' -ForegroundColor Yellow
        exit 1
    }
}

# endregion

# region --- Release resolution ---

function Resolve-LatestRelease {
    param(
        [Parameter(Mandatory)][string]$Repo,
        [bool]$IncludePreRelease
    )

    if (-not $IncludePreRelease) {
        $url = "https://api.github.com/repos/$Repo/releases/latest"
        try {
            return Invoke-RestMethod -Uri $url -Headers $script:AuthHeaders -TimeoutSec 30 -ErrorAction Stop
        }
        catch {
            Write-Fail "Failed to query latest release from $url"
            Write-Host "      $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host ''
            Write-Host '      If you are behind a corporate proxy or hitting GitHub API rate limits,' -ForegroundColor Yellow
            Write-Host '      re-run with -Version <tag> to skip the API call.' -ForegroundColor Yellow
            exit 1
        }
    }

    $url = "https://api.github.com/repos/$Repo/releases?per_page=20"
    try {
        $releases = Invoke-RestMethod -Uri $url -Headers $script:AuthHeaders -TimeoutSec 30 -ErrorAction Stop
    }
    catch {
        Write-Fail "Failed to query releases from $url"
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Yellow
        exit 1
    }

    if ($releases.Count -eq 0) {
        Write-Fail "No releases found in $Repo."
        exit 1
    }

    return $releases[0]
}

function Resolve-TaggedRelease {
    param(
        [Parameter(Mandatory)][string]$Repo,
        [Parameter(Mandatory)][string]$Tag
    )

    $url = "https://api.github.com/repos/$Repo/releases/tags/$Tag"
    try {
        return Invoke-RestMethod -Uri $url -Headers $script:AuthHeaders -TimeoutSec 30 -ErrorAction Stop
    }
    catch {
        Write-Fail "Release '$Tag' not found in $Repo."
        Write-Host "      $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host ''
        Write-Host "      Verify the tag exists: https://github.com/$Repo/releases" -ForegroundColor Yellow
        exit 1
    }
}

# endregion

# region --- Download and verify ---

function Get-ReleaseAssetUrl {
    param(
        [Parameter(Mandatory)]$Release,
        [Parameter(Mandatory)][string]$Pattern
    )

    $asset = $Release.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $asset) { return $null }
    return $asset.browser_download_url
}

function Invoke-FileDownload {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination
    )

    $parentDir = Split-Path -Parent $Destination
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $ProgressPreference_Saved = $ProgressPreference
    try {
        # Invoke-WebRequest progress rendering is extremely slow; disable it for downloads
        $global:ProgressPreference = 'SilentlyContinue'
        $downloadHeaders = @{}
        if ($script:AuthHeaders.Count -gt 0) {
            $downloadHeaders = @{ Authorization = $script:AuthHeaders['Authorization']; Accept = 'application/octet-stream' }
        }
        Invoke-WebRequest -Uri $Url -Headers $downloadHeaders -OutFile $Destination -TimeoutSec 300 -ErrorAction Stop
    }
    finally {
        $global:ProgressPreference = $ProgressPreference_Saved
    }
}

function Test-Sha256Checksum {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$ChecksumFilePath
    )

    $checksumContent = Get-Content -Path $ChecksumFilePath -Raw
    $targetFileName = [IO.Path]::GetFileName($FilePath)

    # Checksum file format: <hash>  <filename> or <hash> <filename>
    $match = $checksumContent -split "`n" |
        Where-Object { $_ -match '^\s*([0-9a-fA-F]{64})\s+(.+)\s*$' -and $Matches[2].Trim() -eq $targetFileName } |
        Select-Object -First 1

    if (-not $match) {
        # Try single-hash-only format (just the hash on one line, no filename)
        $singleHash = ($checksumContent -split "`n" |
            Where-Object { $_ -match '^\s*([0-9a-fA-F]{64})\s*$' } |
            Select-Object -First 1)

        if (-not $singleHash) {
            Write-Fail "Could not find a SHA256 entry for '$targetFileName' in the checksum file."
            return $false
        }

        $null = $singleHash -match '^\s*([0-9a-fA-F]{64})\s*$'
        $expectedHash = $Matches[1].ToUpperInvariant()
    }
    else {
        $null = $match -match '^\s*([0-9a-fA-F]{64})\s+'
        $expectedHash = $Matches[1].ToUpperInvariant()
    }

    $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToUpperInvariant()

    if ($actualHash -ne $expectedHash) {
        Write-Fail "SHA256 checksum mismatch for '$targetFileName'."
        Write-Info "Expected: $expectedHash"
        Write-Info "Actual:   $actualHash"
        Write-Host ''
        Write-Host '      The download may be corrupted. Delete the file and re-run this script.' -ForegroundColor Yellow
        return $false
    }

    return $true
}

# endregion

# region --- Main ---

Write-Banner

Assert-PowerShellVersion
Assert-DockerRunning
Assert-NetworkConnectivity

Write-Step 'Prerequisites OK.'

$detectedOs = if ($IsWindows) { 'windows' }
              elseif ($IsLinux) { 'linux' }
              elseif ($IsMacOS) { 'macos' }
              else { throw 'Unsupported OS.' }

$bundleExt = if ($detectedOs -eq 'windows') { 'zip' } else { 'tar.gz' }

Write-Info "Detected platform: $detectedOs"

# Resolve the target release
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Step 'Resolving latest release...'
    $release = Resolve-LatestRelease -Repo $GitHubRepo -IncludePreRelease $PreRelease.IsPresent
}
else {
    Write-Step "Resolving release $Version..."
    $release = Resolve-TaggedRelease -Repo $GitHubRepo -Tag $Version
}

$resolvedTag = $release.tag_name
$resolvedVersion = $resolvedTag -replace '^v', ''
Write-Info "Release: $resolvedTag ($($release.name))"

# Locate the platform bundle asset (new format), with fallback to legacy format
$bundlePattern = "genapa-forge-*-$detectedOs.$bundleExt"
$bundleUrl = Get-ReleaseAssetUrl -Release $release -Pattern $bundlePattern
$checksumPattern = "genapa-forge-*-$detectedOs.sha256"
$useLegacyFormat = $false

if (-not $bundleUrl) {
    # Backward compat: try old single-ZIP format for older releases
    $bundlePattern = "genapa-customer-installer-*.zip"
    $bundleUrl = Get-ReleaseAssetUrl -Release $release -Pattern $bundlePattern
    $checksumPattern = "genapa-customer-installer-*.sha256"
    $useLegacyFormat = $true

    if (-not $bundleUrl) {
        Write-Fail "No bundle asset found for platform '$detectedOs' in release $resolvedTag."
        Write-Host ''
        Write-Host "      Check the release assets at: https://github.com/$GitHubRepo/releases/tag/$resolvedTag" -ForegroundColor Yellow
        exit 1
    }

    Write-Host '      Using legacy release format (pre-platform bundles).' -ForegroundColor Yellow
}

$zipAssetName = ($release.assets | Where-Object { $_.name -like $bundlePattern } | Select-Object -First 1).name

$checksumUrl = Get-ReleaseAssetUrl -Release $release -Pattern $checksumPattern

# Prepare temp download directory
$tempBase = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$downloadDir = Join-Path $tempBase "genapa-install-$resolvedVersion"
if (-not (Test-Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
}

$bundlePath = Join-Path $downloadDir $zipAssetName

# Download the bundle
Write-Step "Downloading $zipAssetName..."
Invoke-FileDownload -Url $bundleUrl -Destination $bundlePath
Write-Info "Saved to $bundlePath"

# Download and verify checksum
if ($checksumUrl) {
    $checksumAssetName = ($release.assets | Where-Object { $_.name -like $checksumPattern } | Select-Object -First 1).name
    $checksumPath = Join-Path $downloadDir $checksumAssetName

    Write-Step 'Verifying SHA256 checksum...'
    Invoke-FileDownload -Url $checksumUrl -Destination $checksumPath

    if (-not (Test-Sha256Checksum -FilePath $bundlePath -ChecksumFilePath $checksumPath)) {
        exit 1
    }
    Write-Info 'Checksum verified.'
}
else {
    Write-Host '      No .sha256 checksum asset found in this release. Skipping verification.' -ForegroundColor Yellow
}

# Extract the bundle
$extractDir = Join-Path $downloadDir 'extracted'
if (Test-Path $extractDir) {
    Remove-Item -Path $extractDir -Recurse -Force
}

Write-Step 'Extracting installer bundle...'
if ($bundlePath -match '\.tar\.gz$') {
    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
    tar -xzf $bundlePath -C $extractDir
} else {
    Expand-Archive -Path $bundlePath -DestinationPath $extractDir -Force
}

# Locate the root installer in the extracted bundle
if ($useLegacyFormat) {
    $installer = Get-ChildItem -Path $extractDir -Filter 'Install-GenapaCustomer.ps1' -Recurse | Select-Object -First 1
} elseif ($detectedOs -eq 'windows') {
    $installer = Get-ChildItem -Path $extractDir -Filter 'Install-GenapaForge.ps1' -Recurse | Select-Object -First 1
} else {
    $installer = Get-ChildItem -Path $extractDir -Filter 'install-genapa-forge.sh' -Recurse | Select-Object -First 1
}

if (-not $installer) {
    Write-Fail 'Root installer not found inside the extracted bundle.'
    Write-Host ''
    Write-Host "      The extracted contents are at: $extractDir" -ForegroundColor Yellow
    exit 1
}

Write-Info "Found installer at $($installer.FullName)"

if ($DownloadOnly) {
    Write-Step 'Download-only mode. Skipping installer execution.'
    Write-Info "Bundle extracted to: $extractDir"
    Write-Info "Run manually:  pwsh -File `"$($installer.FullName)`" -Slug $Slug"
    exit 0
}

# Build arguments for the installer
$installerArgs = @(
    '-Slug', $Slug
)

if ($Force) {
    $installerArgs += '-Force'
}

if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
    $installerArgs += @('-InstallRoot', $InstallRoot)
}

Write-Step 'Launching installer...'
Write-Host ''

if ($installer.Name -match '\.sh$') {
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Fail 'bash is required to run the installer on this platform.'
        exit 1
    }
    chmod +x $installer.FullName 2>$null
    & bash $installer.FullName --slug $Slug
} else {
    & $installer.FullName @installerArgs
}
$installerExitCode = $LASTEXITCODE

# Cleanup on success
if ($installerExitCode -eq 0 -or $null -eq $installerExitCode) {
    try {
        Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        # Non-fatal; leave temp files for manual cleanup
    }
}
else {
    Write-Host ''
    Write-Host "      Installer exited with code $installerExitCode. Temp files preserved at: $downloadDir" -ForegroundColor Yellow
    exit $installerExitCode
}

# endregion

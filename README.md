# GENAPA Forge Releases

This repository hosts customer installer packages for GENAPA Forge.

## Prerequisites

- **PowerShell 7+** (Windows, Linux, or macOS) — [Install PowerShell](https://aka.ms/install-powershell)
- **Docker** (Docker Desktop on Windows/macOS, Docker Engine on Linux)
- **GitHub access token** with `repo` scope granted to this repository

## Quick Install

Set your GitHub token, then run the one-liner for your platform.

### Windows (PowerShell 7+)

```powershell
$env:GH_TOKEN = "<your-github-token>"
& ([scriptblock]::Create((irm "https://api.github.com/repos/iamkelatar/genapa-releases/contents/install-genapa.ps1" -Headers @{Authorization="Bearer $env:GH_TOKEN";Accept="application/vnd.github.v3.raw"})))
```

### Linux / macOS

```bash
export GH_TOKEN="<your-github-token>"
curl -fsSL -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github.v3.raw" \
  https://api.github.com/repos/iamkelatar/genapa-releases/contents/install-genapa.sh | bash
```

### Using GitHub CLI (any platform)

If you have `gh` installed and authenticated:

```powershell
gh api repos/iamkelatar/genapa-releases/contents/install-genapa.ps1 --jq '.content' | base64 -d | pwsh -Command -
```

## Manual Install

1. Download the bundle for your OS from the [latest release](../../releases/latest)
2. Extract and run the root installer:

| OS | Bundle | Installer |
|----|--------|-----------|
| Windows | `genapa-forge-<version>-windows.zip` | `Install-GenapaForge.ps1` |
| Linux | `genapa-forge-<version>-linux.tar.gz` | `install-genapa-forge.sh` |
| macOS | `genapa-forge-<version>-macos.tar.gz` | `install-genapa-forge.sh` |

## Options

The bootstrap script accepts parameters when run as a file:

```powershell
.\install-genapa.ps1 -Version v1.2.0 -Slug test -GitHubToken $myToken
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Version` | latest | Pin to a specific release tag |
| `-Slug` | `prod` | Environment slug (`prod` or `test`) |
| `-GitHubToken` | `$env:GH_TOKEN` | GitHub PAT for private repo access |
| `-DownloadOnly` | off | Download and extract without running the installer |
| `-Force` | off | Overwrite existing installation |
| `-PreRelease` | off | Include pre-release versions |

## Support

Contact your GENAPA administrator for assistance.
# GENAPA Forge Releases

This repository hosts customer installer packages for GENAPA Forge.

## Prerequisites

- **PowerShell 7+** (Windows, Linux, or macOS) — [Install PowerShell](https://aka.ms/install-powershell)
- **Docker** (Docker Desktop on Windows/macOS, Docker Engine on Linux)

## Quick Install

### Windows (PowerShell 7+)

```powershell
irm https://raw.githubusercontent.com/iamkelatar/genapa-releases/main/install-genapa.ps1 | iex
```

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/iamkelatar/genapa-releases/main/install-genapa.sh | bash
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
.\install-genapa.ps1 -Version v1.2.0 -Slug test
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Version` | latest | Pin to a specific release tag |
| `-Slug` | `prod` | Environment slug (`prod` or `test`) |
| `-DownloadOnly` | off | Download and extract without running the installer |
| `-Force` | off | Overwrite existing installation |
| `-PreRelease` | off | Include pre-release versions |

## Support

Contact your GENAPA administrator for assistance.
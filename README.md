# GENAPA Forge

## Prerequisites

- **Docker** — [Docker Desktop](https://docs.docker.com/desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

## Quick Install

### Windows

```powershell
irm https://raw.githubusercontent.com/iamkelatar/genapa-releases/main/Install-GenapaRelease.ps1 | iex
```

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/iamkelatar/genapa-releases/main/install-genapa-release.sh | bash
```

## Native Installers

Download the installer for your platform from the [latest release](https://github.com/iamkelatar/genapa-releases/releases/latest):

| Platform | Installer | Install Command |
|----------|-----------|-----------------|
| Windows  | `genapa-forge-<version>.msi` | Double-click or `msiexec /i genapa-forge-<version>.msi` |
| Debian/Ubuntu | `genapa-forge_<version>_amd64.deb` | `sudo dpkg -i genapa-forge_<version>_amd64.deb` |
| RHEL/Fedora | `genapa-forge-<version>.x86_64.rpm` | `sudo rpm -i genapa-forge-<version>.x86_64.rpm` |
| macOS | `genapa-forge-<version>.pkg` | Double-click or `sudo installer -pkg genapa-forge-<version>.pkg -target /` |

Native installers register with your OS package manager (Add/Remove Programs, dpkg, rpm, pkgutil) and handle the full setup automatically.

## Manual Install (Bundle)

If you prefer the bundle approach, download the archive for your platform:

| Platform | Bundle | Entry Point |
|----------|--------|-------------|
| Windows  | `genapa-forge-<version>-windows.zip` | `Install-GenapaBundle.ps1` |
| Linux    | `genapa-forge-<version>-linux.tar.gz` | `install-genapa-bundle.sh` |
| macOS    | `genapa-forge-<version>-macos.tar.gz` | `install-genapa-bundle.sh` |

## Bootstrap Script Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Version` / `--version` | latest | Target a specific release version |
| `-Slug` / `--slug` | prod | Environment name (e.g., prod, test) |
| `-DownloadOnly` / `--download-only` | false | Download without installing |
| `-Force` / `--force` | false | Overwrite existing installation |
| `-PreRelease` / `--pre-release` | false | Include pre-release versions |

## Offline Install

All installers and bundles include bundled Docker images for fully offline installation. Download the installer on an internet-connected machine and transfer it to the target system. The only prerequisite is Docker.

## Support

Contact your organization's GENAPA administrator for assistance.

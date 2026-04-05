# GENAPA Forge

## Prerequisites

- **Docker** — [Docker Desktop](https://docs.docker.com/desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

## Installer Downloads

Download the installer for your platform from the [latest release](https://github.com/iamkelatar/genapa-releases/releases/latest). Each download is the complete GENAPA install package for that OS and can be run through the OS GUI or CLI.

| Platform | Installer | Install Command |
|----------|-----------|-----------------|
| Windows  | `GENAPA.Installer.Windows.msi` | Open the MSI or `msiexec /i GENAPA.Installer.Windows.msi` |
| Debian/Ubuntu | `genapa-forge_<version>_amd64.deb` | `sudo dpkg -i genapa-forge_<version>_amd64.deb` |
| RHEL/Fedora | `genapa-forge-<version>.x86_64.rpm` | `sudo rpm -i genapa-forge-<version>.x86_64.rpm` |
| macOS | `genapa-forge-<version>-universal.pkg` | Open the PKG or `sudo installer -pkg genapa-forge-<version>-universal.pkg -target /` |

## Notes

- Each installer already contains the GENAPA payload. Installation does not require downloading additional GENAPA release assets.
- Linux uses one installer contract under the OS package manager. Choose the `.deb` package for Debian/Ubuntu or the `.rpm` package for RHEL/Fedora-family systems.
- Linux GUI install depends on your distro desktop. If no package UI is available, use the CLI command shown above.
- macOS installs through Installer or `installer -pkg`. `pkgutil` tracks the package receipt, but service and data cleanup remain separate from receipt removal.

## Support

Contact your organization's GENAPA administrator for assistance.

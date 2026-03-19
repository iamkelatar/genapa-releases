# GENAPA Forge Releases

This repository hosts customer installer packages for GENAPA Forge.

## Installation

1. Download `genapa-customer-installer-<version>.zip` from the [latest release](../../releases/latest)
2. Extract the zip on your Windows machine
3. Run `.\Install-GenapaCustomer.ps1 -Slug prod` (or `-Slug test` for test environments)

## Prerequisites

- Windows host
- Docker Desktop or compatible Docker engine
- Access to GHCR: `docker login ghcr.io -u <github-username>`

## Support

Contact your GENAPA administrator for assistance.

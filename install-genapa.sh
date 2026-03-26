#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
    echo "PowerShell 7+ (pwsh) is required." >&2
    echo "" >&2
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "  Install on macOS:  brew install powershell/tap/powershell" >&2
    elif [[ -f /etc/debian_version ]]; then
        echo "  Install on Debian/Ubuntu:  https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu" >&2
    elif [[ -f /etc/redhat-release ]]; then
        echo "  Install on RHEL/CentOS:  https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel" >&2
    else
        echo "  Install PowerShell:  https://aka.ms/install-powershell" >&2
    fi
    exit 1
fi

exec pwsh -NoProfile -File "$SCRIPT_DIR/install-genapa.ps1" "$@"

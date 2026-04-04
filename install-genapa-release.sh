#!/usr/bin/env bash

set -euo pipefail

VERSION=""
SLUG="prod"
GITHUB_REPO="iamkelatar/genapa-releases"
DOWNLOAD_ONLY=false
PRE_RELEASE=false
GITHUB_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
INSTALLER_ARGS=()

usage() {
  cat <<'EOF'
Usage:
    install-genapa-release.sh [options]

Options:
    --version, -v <tag>                      Install a specific release tag
    --slug, -s <slug>                        Target environment slug
    --force                                  Regenerate secrets and redeploy with reset
    --show-logs                              Stream container logs after startup
    --enable-autostart                       Register Host Manager for auto-start
    --no-autostart                           Skip Host Manager auto-start registration
    --allow-new-secrets-with-existing-volume Allow destructive secret regeneration when a volume exists
    --download-only                          Download and extract without running the bundle installer
    --pre-release                            Resolve the latest pre-release instead of the latest stable release
    --repo <owner/repo>                      Override the distribution repository
    --token <token>                          GitHub token for release download access
    --help, -h                               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v)
      [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
      VERSION="$2"; shift 2 ;;
    --slug|-s)
      [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
      SLUG="$2"; shift 2 ;;
    --force|--show-logs|--enable-autostart|--no-autostart|--allow-new-secrets-with-existing-volume)
      INSTALLER_ARGS+=("$1"); shift ;;
    --download-only) DOWNLOAD_ONLY=true; shift ;;
    --pre-release) PRE_RELEASE=true; shift ;;
    --repo)
      [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
      GITHUB_REPO="$2"; shift 2 ;;
    --token)
      [[ $# -lt 2 ]] && { echo "Missing value for $1" >&2; usage >&2; exit 1; }
      GITHUB_TOKEN="$2"; shift 2 ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1 ;;
  esac
done

AUTH_HEADER=""
if [[ -n "$GITHUB_TOKEN" ]]; then
  AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

case "$(uname -s)" in
  Linux*)  OS="linux"; EXT="tar.gz" ;;
  Darwin*) OS="macos"; EXT="tar.gz" ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "  [X] install-genapa-release.sh is supported on Linux and macOS only." >&2
    echo "      Use Install-GenapaRelease.ps1 on Windows." >&2
    exit 1 ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

echo ""
echo "  ================================================================"
echo "   GENAPA FORGE - EZ INSTALL"
echo "  ================================================================"
echo ""

if ! command -v curl >/dev/null 2>&1; then
  echo "  [X] curl is required but not found on PATH." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "  [X] Docker is not installed or not on PATH." >&2
  if [[ "$OS" == "linux" ]]; then
    echo "      Install Docker Engine:  https://docs.docker.com/engine/install/" >&2
  else
    echo "      Install Docker Desktop:  https://docs.docker.com/desktop/setup/install/mac-install/" >&2
  fi
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "  [X] Docker is installed but not running." >&2
  echo "      Start Docker and wait for the engine to be ready, then re-run this script." >&2
  exit 1
fi

echo "  [*] Prerequisites OK."
echo "      Detected platform: ${OS}"

if [[ -z "$VERSION" ]]; then
  if [[ "$PRE_RELEASE" == true ]]; then
    echo "  [*] Resolving latest release (including pre-releases)..."
    RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases?per_page=20"
  else
    echo "  [*] Resolving latest release..."
    RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
  fi
else
  echo "  [*] Resolving release ${VERSION}..."
  RELEASE_URL="https://api.github.com/repos/$GITHUB_REPO/releases/tags/$VERSION"
fi

CURL_AUTH=()
if [[ -n "$AUTH_HEADER" ]]; then
  CURL_AUTH=(-H "$AUTH_HEADER")
fi

RELEASE_JSON=$(curl -fsSL "${CURL_AUTH[@]}" "$RELEASE_URL") || {
  echo "  [X] Failed to query release from ${RELEASE_URL}" >&2
  exit 1
}

if [[ -z "$VERSION" ]]; then
  VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name"\s*:\s*"[^"]*"' | head -1 | cut -d'"' -f4)
fi

echo "      Release: ${VERSION}"

BUNDLE_NAME="genapa-forge-${VERSION}-${OS}.${EXT}"
BUNDLE_URL=$(echo "$RELEASE_JSON" | grep -o "\"browser_download_url\"\s*:\s*\"[^\"]*${BUNDLE_NAME}\"" | head -1 | cut -d'"' -f4)

if [[ -z "$BUNDLE_URL" ]]; then
  echo "  [X] Bundle ${BUNDLE_NAME} not found in release ${VERSION}." >&2
  echo "      Check: https://github.com/${GITHUB_REPO}/releases/tag/${VERSION}" >&2
  exit 1
fi

SHA_NAME="genapa-forge-${VERSION}-${OS}.sha256"
SHA_URL=$(echo "$RELEASE_JSON" | grep -o "\"browser_download_url\"\s*:\s*\"[^\"]*${SHA_NAME}\"" | head -1 | cut -d'"' -f4)

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "  [*] Downloading ${BUNDLE_NAME}..."
curl -fSL "${CURL_AUTH[@]}" -o "$TMP_DIR/$BUNDLE_NAME" "$BUNDLE_URL"
echo "      Saved to ${TMP_DIR}/${BUNDLE_NAME}"

if [[ -n "$SHA_URL" ]]; then
  echo "  [*] Verifying SHA256 checksum..."
  curl -fsSL "${CURL_AUTH[@]}" -o "$TMP_DIR/$SHA_NAME" "$SHA_URL"
  EXPECTED_HASH=$(grep -oE '[0-9a-fA-F]{64}' "$TMP_DIR/$SHA_NAME" | head -1 | tr '[:upper:]' '[:lower:]')
  if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_HASH=$(sha256sum "$TMP_DIR/$BUNDLE_NAME" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL_HASH=$(shasum -a 256 "$TMP_DIR/$BUNDLE_NAME" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
  else
    echo "      No sha256sum or shasum found. Skipping checksum verification." >&2
    ACTUAL_HASH="$EXPECTED_HASH"
  fi
  if [[ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]]; then
    echo "  [X] SHA256 checksum mismatch." >&2
    echo "      Expected: ${EXPECTED_HASH}" >&2
    echo "      Actual:   ${ACTUAL_HASH}" >&2
    exit 1
  fi
  echo "      Checksum verified."
else
  echo "      No .sha256 checksum asset found. Skipping verification."
fi

EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

echo "  [*] Extracting installer bundle..."
if [[ "$EXT" == "tar.gz" ]]; then
  tar -xzf "$TMP_DIR/$BUNDLE_NAME" -C "$EXTRACT_DIR"
else
  unzip -q "$TMP_DIR/$BUNDLE_NAME" -d "$EXTRACT_DIR"
fi

INSTALLER=$(find "$EXTRACT_DIR" -maxdepth 2 -name 'install-genapa-bundle.sh' | head -1)
if [[ -z "$INSTALLER" ]]; then
  echo "  [X] install-genapa-bundle.sh not found in bundle." >&2
  exit 1
fi

echo "      Found installer at ${INSTALLER}"

if [[ "$DOWNLOAD_ONLY" == true ]]; then
  echo "  [*] Download-only mode. Skipping installer execution."
  echo "      Bundle extracted to: ${EXTRACT_DIR}"
  echo "      Run manually: bash ${INSTALLER} --slug ${SLUG}"
  trap - EXIT
  exit 0
fi

chmod +x "$INSTALLER"
echo "  [*] Launching installer..."
echo ""

exec bash "$INSTALLER" --slug "$SLUG" "${INSTALLER_ARGS[@]}"

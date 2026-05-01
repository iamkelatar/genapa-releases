# GENAPA

**GENAPA** — *generally applicable platform assistance* — is a local-first AI knowledge archive. It ingests your files (code, docs, PDFs, notes, configs) and builds a navigable graph of **Sources, References, Entities, and Synths** that you query with natural language. Your data, embeddings, and any AI calls run on your own machine; bring your own LLM / embedding provider, or run fully offline with Ollama.

This repository is the **public release-distribution channel** for GENAPA. End users download installers from here; installed environments self-update from the Velopack feed published on each release.

## Install

GENAPA installs through the **Package Manager**, a small bootstrap that then manages your Forge environments. Download the installer for your platform from the [latest release](https://github.com/iamkelatar/genapa-releases/releases/latest), then launch it.

| Platform | Installer asset |
|----------|-----------------|
| Windows x64 | `GENAPA.PackageManager.Windows-<version>-Setup.exe` |
| Linux x64 | `GENAPA.PackageManager.Linux-<version>.AppImage` |
| macOS Apple Silicon | `GENAPA.PackageManager.macOS-arm64-<version>-Setup.pkg` |
| macOS Intel | `GENAPA.PackageManager.macOS-x64-<version>-Setup.pkg` |

### Windows
Double-click the `.exe`. The Package Manager installs to `%LOCALAPPDATA%\GENAPA\` and registers a Start Menu entry. Launch **GENAPA Package Manager** from the Start Menu.

### Linux
```bash
chmod +x GENAPA.PackageManager.Linux-<version>.AppImage
./GENAPA.PackageManager.Linux-<version>.AppImage
```

The AppImage launches the GUI by default. For headless servers, pass CLI verbs directly to the AppImage.

### macOS
Double-click the `.pkg` and follow the Installer GUI, or run `sudo installer -pkg <file>.pkg -target /`. Open **GENAPA Package Manager** from Launchpad.

## After Install

Open the Package Manager and install a **Forge** environment from the GUI. Once Forge is installed and started, you get:

- A local **Portal** (Blazor web UI) for file ingestion, watchers, environment management, and natural-language chat over your archive.
- A local **Forge API** with semantic search, incremental file watchers, and an **MCP server** (Streamable HTTP, legacy SSE, and stdio) so AI assistants can read from and write to the archive directly.
- **Agent sessions** that clone the workspace into isolated git worktrees, enabling safe parallel agent coding against the same archive.

Updates apply automatically through Velopack — you do not re-download installers for routine updates.

## Channels and the Asset List

Each release publishes against a channel. As of today only the **alpha** channel is shipping; **beta**, **rc**, and **stable** are wired into CI and will appear here as they are cut.

The release page lists more files than just the installers above. The additional assets are the **Velopack feed machinery** the installed Package Manager and Forge environments consume for self-update:

- `*.nupkg` — full and delta update packages.
- `RELEASES-*`, `releases.*.json`, `assets.*.json` — Velopack feed indexes.

Channels emit as `win-x64-<channel>`, `linux-<channel>`, `osx-x64-<channel>`, `osx-arm64-<channel>`. Package Manager self-update channels carry the `-pm` suffix.

## Notes for Alpha Builds

Alpha builds may be unsigned or partially signed. Windows SmartScreen and macOS Gatekeeper may warn on first install — click **More info → Run anyway** on Windows, or right-click → **Open** on macOS, to approve once.

## Support

Contact your organization's GENAPA administrator for assistance.

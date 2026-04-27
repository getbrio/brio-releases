#!/usr/bin/env bash
# brio-cli installer — downloads the latest release binary for the current
# OS/arch and drops it into ~/.local/bin (or /usr/local/bin with --system).
#
# Usage:
#   curl -fsSL https://github.com/pw42020/brio-releases/releases/latest/download/install.sh | bash
#   ./install.sh [--system] [--version cli-vX.Y.Z]
set -euo pipefail

REPO="pw42020/brio-releases"
DEST_USER="${HOME}/.local/bin"
DEST_SYSTEM="/usr/local/bin"
dest="$DEST_USER"
version="latest"
use_sudo=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)  dest="$DEST_SYSTEM"; use_sudo="sudo"; shift ;;
        --version) version="$2"; shift 2 ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
done

os_raw="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch_raw="$(uname -m)"
case "$os_raw" in
    linux)  os="linux" ;;
    darwin) os="darwin" ;;
    *) echo "unsupported OS: $os_raw" >&2; exit 1 ;;
esac
case "$arch_raw" in
    x86_64|amd64)  arch="x86_64" ;;
    arm64|aarch64) arch="arm64" ;;
    *) echo "unsupported arch: $arch_raw" >&2; exit 1 ;;
esac

asset="brio-${os}-${arch}"
if [[ "$version" == "latest" ]]; then
    url="https://github.com/${REPO}/releases/latest/download/${asset}"
else
    url="https://github.com/${REPO}/releases/download/${version}/${asset}"
fi

tmp="$(mktemp -t brio.XXXXXX)"
trap 'rm -f "$tmp"' EXIT

echo "→ downloading $asset ($version)"
echo "  $url"
curl -fL --progress-bar -o "$tmp" "$url"
chmod +x "$tmp"

# Strip macOS quarantine xattr so Gatekeeper doesn't block the first launch.
if [[ "$os" == "darwin" ]]; then
    xattr -d com.apple.quarantine "$tmp" 2>/dev/null || true
fi

target="${dest}/brio"
echo "→ installing to $target"
$use_sudo install -d "$dest"
$use_sudo install -m 0755 "$tmp" "$target"

echo "→ verifying"
if ! "$target" --help >/dev/null 2>&1; then
    echo "verify failed: $target --help did not exit cleanly." >&2
    exit 1
fi

echo "✓ brio-cli installed at $target"

# PATH check (warn, don't edit shell rc).
case ":$PATH:" in
    *":$dest:"*) ;;
    *) echo "  note: $dest is not on \$PATH — add it to your shell rc or move the binary." >&2 ;;
esac

echo
echo "next: run 'brio login' to set BRIO_API_URL / BRIO_API_KEY."

#!/usr/bin/env bash
# install-deck.sh: install the latest decK release (KGLL-115, Lesson 1.3).
#
# Works on Linux (amd64, arm64), macOS (Intel and Apple silicon), and
# Windows through WSL. Needs curl, jq, and tar.
#
# Usage:  curl -fsSL <url>/install-deck.sh | bash
#    or:  bash install-deck.sh
# Option: INSTALL_DIR=/some/dir (default /usr/local/bin)
#
# Everything runs inside main(), called on the last line, so a partly
# downloaded script piped into bash does nothing.
set -euo pipefail

main() {
  local INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
  local OS ARCH URL tool   # TMP stays global: the EXIT trap runs after main returns

  for tool in curl jq tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "Missing $tool. Install it (Lesson 1.2), then run this script again." >&2
      exit 1
    fi
  done

  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$OS" in
    linux)
      case "$(uname -m)" in
        x86_64|amd64)  ARCH=amd64 ;;
        aarch64|arm64) ARCH=arm64 ;;
        *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
      esac ;;
    darwin)
      ARCH=all ;;   # decK ships one universal build for macOS
    *)
      echo "Unsupported system: $OS. On Windows, run this inside WSL (Lesson 1.1)." >&2
      exit 1 ;;
  esac

  URL=$(curl -fsSL https://api.github.com/repos/kong/deck/releases/latest |
    jq -r --arg suffix "${OS}_${ARCH}.tar.gz" \
      '.assets[] | select(.name | endswith($suffix)) | .browser_download_url')
  if [ -z "$URL" ]; then
    echo "Couldn't find a decK release for ${OS}_${ARCH}." >&2
    exit 1
  fi

  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  echo "Downloading $URL"
  curl -fsSL "$URL" | tar -xz -C "$TMP" deck

  if [ -d "$INSTALL_DIR" ] && [ -w "$INSTALL_DIR" ]; then
    install -m 0755 "$TMP/deck" "$INSTALL_DIR/deck"
  else
    echo "Installing to $INSTALL_DIR (sudo may ask for your password)"
    sudo mkdir -p "$INSTALL_DIR"
    sudo install -m 0755 "$TMP/deck" "$INSTALL_DIR/deck"
  fi

  case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) echo "Note: $INSTALL_DIR isn't on your PATH. Add it, or run $INSTALL_DIR/deck." >&2 ;;
  esac

  echo "Installed: $("$INSTALL_DIR/deck" version)"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# node-serviced installer (Linux only)
# Downloads the latest GitHub release for the detected arch and installs to /usr/local/bin/node-serviced

REPO_OWNER="PasarGuard"
REPO_NAME="node-serviced"
INSTALL_PATH="/usr/local/bin/node-serviced"
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

ARCH=""
OS="linux"
TMPDIR=""

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

cleanup() {
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l|armv7) ARCH="armv7" ;;
    armv6l|armv6) ARCH="armv6" ;;
    *) log "Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    log "This installer supports Linux only."
    exit 1
  }
}

require_tools() {
  for bin in curl tar; do
    if ! command -v "$bin" >/dev/null 2>&1; then
      log "Missing required tool: $bin"
      exit 1
    fi
  done
}

fetch_latest_url() {
  local asset_name="${REPO_NAME}_*_Linux_${ARCH}.tar.gz"
  local url
  url=$(curl -sSf "$API_URL" | grep -oE "\"browser_download_url\": \"[^\"]*${asset_name}\"" | head -n1 | cut -d\" -f4)
  if [[ -z "$url" ]]; then
    log "Could not find a release asset for arch=${ARCH}"
    exit 1
  fi
  echo "$url"
}

download_and_install() {
  TMPDIR=$(mktemp -d)
  local url="$1"
  local archive="$TMPDIR/node-serviced.tar.gz"

  log "Downloading: $url"
  curl -fL "$url" -o "$archive"

  log "Extracting archive"
  tar -xzf "$archive" -C "$TMPDIR"

  if [[ ! -f "$TMPDIR/node-serviced" ]]; then
    log "Binary node-serviced not found in archive"
    exit 1
  fi

  log "Installing to $INSTALL_PATH"
  install -m 0755 "$TMPDIR/node-serviced" "$INSTALL_PATH"
}

main() {
  require_linux
  require_tools
  detect_arch

  log "Detected linux/${ARCH}"
  local url
  url=$(fetch_latest_url)

  download_and_install "$url"
  log "Install complete: $INSTALL_PATH"
}

main "$@"


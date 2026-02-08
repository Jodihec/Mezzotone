#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root (so relative package paths work consistently)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$REPO_ROOT" ]]; then
  cd "$REPO_ROOT"
fi

# Config (override via env if you want)
OUT_DIR="${OUT_DIR:-build}"
APP_NAME="${APP_NAME:-app}"

mkdir -p "$OUT_DIR"
MAIN_PKG="${MAIN_PKG:-.}"

# Common build flags
# -trimpath removes local machine paths from the binary
# -ldflags "-s -w" strips symbols (smaller binaries)
GOFLAGS_COMMON=("-trimpath" "-ldflags=-s -w")

# If your project uses CGO/native libs, set CGO_ENABLED=1 before running.
# Cross-compiling with CGO can require extra toolchains.
export CGO_ENABLED="${CGO_ENABLED:-0}"

build() {
  local goos="$1"
  local goarch="$2"
  local out="$3"
  local goarm="${4:-}"

  echo "==> Building: GOOS=$goos GOARCH=$goarch${goarm:+ GOARM=$goarm} -> $out"

  if [[ -n "$goarm" ]]; then
    GOOS="$goos" GOARCH="$goarch" GOARM="$goarm" \
      go build "${GOFLAGS_COMMON[@]}" -o "$out" "$MAIN_PKG"
  else
    GOOS="$goos" GOARCH="$goarch" \
      go build "${GOFLAGS_COMMON[@]}" -o "$out" "$MAIN_PKG"
  fi
}

# ---- Targets ----

# Linux
build linux amd64  "$OUT_DIR/${APP_NAME}-linux-amd64"
build linux arm64  "$OUT_DIR/${APP_NAME}-linux-arm64"
build linux arm    "$OUT_DIR/${APP_NAME}-linux-armv6" 6   # Raspberry Pi Zero / Pi 1
build linux arm    "$OUT_DIR/${APP_NAME}-linux-armv7" 7   # Raspberry Pi 2 (armv7)

# Windows
build windows amd64 "$OUT_DIR/${APP_NAME}-windows-amd64.exe"
build windows arm64 "$OUT_DIR/${APP_NAME}-windows-arm64.exe"

# macOS
build darwin amd64 "$OUT_DIR/${APP_NAME}-macos-amd64"
build darwin arm64 "$OUT_DIR/${APP_NAME}-macos-arm64"


echo "✅ Done. Binaries in: $OUT_DIR"
echo "ℹ️  MAIN_PKG=$MAIN_PKG  (override with: MAIN_PKG=./cmd/<name>)"
echo "ℹ️  APP_NAME=$APP_NAME  (override with: APP_NAME=<name>)"
echo "ℹ️  CGO_ENABLED=$CGO_ENABLED (set 1 only if needed)"

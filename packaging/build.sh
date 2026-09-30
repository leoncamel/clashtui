#!/usr/bin/env bash
# Build .deb and .rpm packages for clashtui.
# Usage: build.sh <binary-path> <version> <arch> <out-dir>
#   arch: amd64 or arm64 (deb naming); rpm mapping: amd64->x86_64, arm64->aarch64
set -euo pipefail

BIN="$1"
VERSION="$2"
ARCH="$3"
OUT="$4"

# rpm/fpm arch names
case "$ARCH" in
amd64) RPM_ARCH=x86_64 ;;
arm64) RPM_ARCH=aarch64 ;;
*) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# --- Stage FHS tree ---
install -Dm755 "$BIN" "$STAGE/usr/bin/clashtui"
install -Dm644 "$REPO_ROOT/contrib/systemd/clashtui_mihomo.service" \
  "$STAGE/usr/lib/systemd/system/clashtui_mihomo.service"
install -Dm644 "$REPO_ROOT/contrib/systemd/clashtui_singbox.service" \
  "$STAGE/usr/lib/systemd/system/clashtui_singbox.service"
install -dm750 "$STAGE/etc/clashtui/mihomo"
install -dm750 "$STAGE/etc/clashtui/sing-box"

# --- postinst: create system users idempotently ---
POSTINST="$(mktemp)"
cat >"$POSTINST" <<'EOF'
#!/bin/sh
set -e
id mihomo >/dev/null 2>&1 || useradd --system --no-create-home --shell /bin/false mihomo
id sing-box >/dev/null 2>&1 || useradd --system --no-create-home --shell /bin/false sing-box
chown mihomo:mihomo /etc/clashtui/mihomo
chown sing-box:sing-box /etc/clashtui/sing-box
EOF
chmod 755 "$POSTINST"

mkdir -p "$OUT"

# --- deb ---
fpm -s dir -t deb \
  -n clashtui -v "$VERSION" -a "$ARCH" \
  --description "Mihomo (Clash.Meta) TUI Client" \
  --url "https://github.com/JohanChane/clashtui" \
  --license "MIT" \
  --depends "libc6 >= 2.17" \
  --after-install "$POSTINST" \
  -p "$OUT/clashtui_${VERSION}-1_${ARCH}.deb" \
  "$STAGE/=/"

# --- rpm ---
fpm -s dir -t rpm \
  -n clashtui -v "$VERSION" -a "$RPM_ARCH" \
  --description "Mihomo (Clash.Meta) TUI Client" \
  --url "https://github.com/JohanChane/clashtui" \
  --license "MIT" \
  --depends "glibc >= 2.17" \
  --after-install "$POSTINST" \
  -p "$OUT/clashtui-${VERSION}-1.${RPM_ARCH}.rpm" \
  "$STAGE/=/"

echo "packages in $OUT:"
ls -la "$OUT"

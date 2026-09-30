#!/usr/bin/env bash
# Build .pkg.tar.zst for clashtui via fpm (Arch users should prefer the AUR
# source package; packaging/arch/PKGBUILD).
# Usage: pacman.sh <binary> <version> <arch> <outdir>
set -euo pipefail

BIN="${1:?binary path required}"
VERSION="${2:?version required}"
ARCH="${3:?arch required}"
OUTDIR="${4:?output dir required}"

case "$ARCH" in
amd64) PACMAN_ARCH=x86_64 ;;
arm64) PACMAN_ARCH=aarch64 ;;
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

# --- Arch uses sysusers.d, not post-install scripts ---
install -Dm644 /dev/null "$STAGE/usr/lib/sysusers.d/clashtui.conf"
cat >"$STAGE/usr/lib/sysusers.d/clashtui.conf" <<'EOF'
u mihomo - "mihomo daemon user" -
u sing-box - "sing-box daemon user" -
EOF

mkdir -p "$OUTDIR"

fpm -s dir -t pacman \
  -n clashtui -v "$VERSION" -a "$PACMAN_ARCH" \
  --description "Mihomo (Clash.Meta) TUI Client" \
  --url "https://github.com/JohanChane/clashtui" \
  --license "MIT" \
  --depends glibc \
  -p "$OUTDIR/clashtui-${VERSION}-1-${PACMAN_ARCH}.pkg.tar.zst" \
  "$STAGE/=/"

echo "packages in $OUTDIR:"
ls -la "$OUTDIR"

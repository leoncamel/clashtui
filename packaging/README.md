# clashtui packaging

Distribution packaging for clashtui (FHS layout, systemd services).

## Layout

- `arch/PKGBUILD` — build clashtui from source (AUR-ready).
- `deb/`, `rpm/` — packaging scripts and unit files for deb/rpm packages.
- The `packaging.yml` workflow builds packages from the release binaries and
  attaches them to the same GitHub Release as the raw binaries.

## FHS layout (packaged install)

```
/usr/bin/clashtui
/usr/bin/mihomo        (downloaded by user, not packaged)
/usr/bin/sing-box       (downloaded by user, not packaged)
/usr/lib/systemd/system/clashtui_mihomo.service
/usr/lib/systemd/system/clashtui_singbox.service
/etc/clashtui/mihomo/config.yaml
/etc/clashtui/sing-box/config.json
```

The `clashtui` binary and units are packaged; mihomo/sing-box binaries are
user-installed (AUR has `mihomo` and `sing-box`; Debian/Ubuntu: download from
upstream releases).

## User/group creation

- Arch: `sysusers.d` fragment (package-managed).
- deb: `postinst` runs `useradd --system` (idempotent).

Usernames match current install script: `mihomo`, `sing-box`.

#!/usr/bin/env zsh
# Remove facelock face unlock installed by setup.zsh.
# Run as your user, never root: ./omarchy/face-unlock/remove.zsh
set -euo pipefail

readonly GREEN=$'\e[32m' RED=$'\e[31m' NC=$'\e[0m'
info() { print -r -- "${GREEN}$*${NC}" }
die() { print -r -- "${RED}$*${NC}" >&2; exit 1 }

(( EUID != 0 )) || die "Run as your user, not root."

if command -v facelock >/dev/null; then
  sudo facelock pam remove --service omarchy-lock-face --service sudo \
    --service polkit-1 --if-present --no-confirm || true
fi

sudo python3 - <<'PY'
import pathlib

needle = "pam_unix.so try_first_pass likeauth nullok"
for service in ("/etc/pam.d/sudo", "/etc/pam.d/polkit-1"):
    path = pathlib.Path(service)
    if not path.exists():
        continue
    lines = path.read_text().splitlines()
    if not any(needle in l for l in lines):
        continue
    path.write_text("\n".join(l for l in lines if needle not in l) + "\n")
PY

sudo rm -f /etc/pam.d/omarchy-lock-face
sudo rm -f /etc/systemd/system/facelock-daemon.service.d/omarchy-writable-keys.conf
sudo rmdir /etc/systemd/system/facelock-daemon.service.d 2>/dev/null || true
sudo systemctl disable --now facelock-daemon.service 2>/dev/null || true
sudo systemctl daemon-reload

info "Removing facelock packages..."
yay -Rns --noconfirm facelock-bin 2>/dev/null || true

info "Removed. Revert the lock-screen patch: git checkout -- omarchy/lock, then omarchy restart shell."
print -r -- "Biometric data (if any) remains in /var/lib/facelock; purge with: sudo facelock data purge"

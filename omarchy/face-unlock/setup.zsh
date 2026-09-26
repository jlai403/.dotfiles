#!/usr/bin/env zsh
# Facelock face unlock for Omarchy on the built-in RGB camera.
# Idempotent. Run as your user, never root: ./omarchy/face-unlock/setup.zsh
#
# RGB-only camera and no TPM on this T2 Mac: require_ir=false, keyfile
# encryption. Face auth is a convenience, not a security boundary.
# Backend contract: facelock 0.2.x (upstream Omarchy PR #11612).
set -euo pipefail

readonly GREEN=$'\e[32m' RED=$'\e[31m' YELLOW=$'\e[33m' NC=$'\e[0m'
readonly CONFIG=/etc/facelock/config.toml
readonly DEVICE=/dev/v4l/by-path/pci-0000:04:00.1-usb-0:2:1.0-video-index0
readonly DROPIN=/etc/systemd/system/facelock-daemon.service.d

info() { print -r -- "${GREEN}$*${NC}" }
warn() { print -r -- "${YELLOW}$*${NC}" }
die() { print -r -- "${RED}$*${NC}" >&2; exit 1 }

(( EUID != 0 )) || die "Run as your user, not root."
command -v yay >/dev/null || die "yay is required."

if ! command -v facelock >/dev/null; then
  info "Installing onnxruntime-cpu and facelock-bin..."
  yay -S --needed --noconfirm onnxruntime-cpu facelock-bin
fi
command -v facelock >/dev/null || die "facelock did not install."

info "Configuring facelock for an RGB camera and the lock screen..."
sudo python3 - "$CONFIG" "$DEVICE" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
device = sys.argv[2]
text = path.read_text()


def set_key(text, section, key, value):
    lines = text.splitlines()
    out, in_section, done = [], False, False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            in_section = stripped == f"[{section}]"
        if in_section and re.match(rf"^\s*#?\s*{re.escape(key)}\s*=", line) and not done:
            out.append(f"{key} = {value}")
            done = True
            continue
        out.append(line)
    if not done:
        for i, line in enumerate(out):
            if line.strip() == f"[{section}]":
                out.insert(i + 1, f"{key} = {value}")
                done = True
                break
    if not done:
        out += ["", f"[{section}]", f"{key} = {value}"]
    return "\n".join(out) + "\n"


text = set_key(text, "device", "path", f'"{device}"')
text = set_key(text, "security", "require_ir", "false")
text = set_key(text, "security", "abort_if_ssh", "false")
path.write_text(text)
PY

info "Allowing the daemon to write its keyfile..."
sudo mkdir -p "$DROPIN"
sudo tee "$DROPIN/omarchy-writable-keys.conf" >/dev/null <<'EOF'
[Service]
ReadWritePaths=/etc/facelock
EOF
sudo systemctl daemon-reload

# facelock setup downloads the ONNX models and enables the daemon; asking
# systemd to start the daemon before this fails every time, since it refuses to
# come up with no models to load.
info "Running facelock setup (models)..."
sudo facelock setup --no-pam --no-systemd --non-interactive --yes --no-enroll \
  --models standard --execution-provider cpu --encryption keyfile

info "Enabling the facelock daemon..."
sudo systemctl enable --now facelock-daemon.service

info "Look at the camera to enroll your face."
if ! sudo facelock enroll --user "$USER" --label primary; then
  die "Enrollment failed. Re-run this script."
fi

info "Writing the lock-screen face PAM service..."
sudo tee /etc/pam.d/omarchy-lock-face >/dev/null <<'EOF'
#%PAM-1.0
auth       required                    pam_deny.so
account    include                     system-local-login
EOF

if [[ ! -f /etc/pam.d/polkit-1 ]]; then
  sudo tee /etc/pam.d/polkit-1 >/dev/null <<'EOF'
#%PAM-1.0
auth       include                     system-auth
account    include                     system-auth
password   include                     system-auth
session    include                     system-auth
EOF
fi

sudo facelock pam add --service omarchy-lock-face --service sudo --service polkit-1 --no-confirm

# Password-first for sudo/polkit: a typed password authenticates instantly and
# only an empty Enter starts a scan, so an unattended sudo cannot be face-approved.
info "Ordering sudo/polkit for password-first fallback..."
sudo python3 - <<'PY'
import pathlib

line = "auth       sufficient                    pam_unix.so try_first_pass likeauth nullok"
for service in ("/etc/pam.d/sudo", "/etc/pam.d/polkit-1"):
    path = pathlib.Path(service)
    if not path.exists():
        continue
    lines = path.read_text().splitlines()
    if any("pam_unix.so try_first_pass likeauth nullok" in l for l in lines):
        continue
    for i, l in enumerate(lines):
        if "pam_facelock.so" in l:
            lines.insert(i, line)
            break
    else:
        lines.insert(1, line)
    path.write_text("\n".join(lines) + "\n")
PY

info "Done. Face unlock is configured for the lock screen, sudo, and polkit."
print -r -- "Verify: sudo echo ok (empty Enter scans), then lock with Super+Ctrl+L."

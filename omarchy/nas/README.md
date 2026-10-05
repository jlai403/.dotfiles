# nas

Mount SMB shares from your NAS on demand. Linux only (cifs). No automount,
nothing mounts at boot, and no password is stored.

## Usage

```sh
nas ls joey@dns323.lan                     # list shares on a host
nas mount joey@dns323.lan                  # pick a share, then mount
nas mount joey@dns323.lan/main             # mount a specific share
nas mount joey@cockpit.lan/smb joey@cockpit.lan/docker-data
nas mount joey@dns323.lan --all            # every share on the host
nas mount --all                            # every share on every host in NAS_HOSTS
nas status                                 # what is mounted under /mnt/nas
nas umount joey@dns323.lan/main            # or: nas umount --all
```

Flags for `mount`: `--all`, `--ro`, `--vers=DIALECT`. `user` defaults to
`$USER`. Multiple specs are grouped by host, so you authenticate once per host.
`--all` with no host expands `NAS_HOSTS` (default `joey@dns323.lan
joey@cockpit.lan`; override via the env var).

## Behavior

- Prompts once per host for the password, writes it to a temporary 0600 auth
  file, reuses that file for listing and mounting, and shreds it on exit. The
  password never appears in argv, history, or the repo.
- Mounts live at `/mnt/nas/<host>/<share>`, created `0755` so you (and Files)
  can traverse them.
- SMB dialect is negotiated by the kernel. If a mount fails, it retries with
  `vers=2.0` (for the DNS-323). Override with `--vers`.
- Mounting needs root, so you get a `sudo` prompt in addition to the password.

## Files (Nautilus) integration

- A bookmark `NAS` points at `/mnt/nas` (in `~/.config/gtk-{3,4}.0/bookmarks`),
  so the mounts show in the Nautilus sidebar.
- `~/NAS` symlinks to `/mnt/nas` for Home/terminal access.
- A `nautilus-python` extension (`nas-unmount.py`) adds **Unmount NAS** to the
  right-click menu for anything under `/mnt/nas`; it opens a floating terminal
  running `nas umount <mountpoint>`. Restart Nautilus after install
  (`nautilus -q`).


## Notes

- The DNS-323 is SMB2-only; `dns323.lan` resolves to 192.168.20.110 with shares
  `main` and `secondary`. Cockpit (`cockpit.lan`) serves `smb` and `docker-data`.
- An empty `/mnt/nas/<host>/<share>` before you mount is expected.
- macOS would need a separate backend (`mount_smbfs`/`smbutil`); this script is
  Linux-only and lives under `omarchy/`.

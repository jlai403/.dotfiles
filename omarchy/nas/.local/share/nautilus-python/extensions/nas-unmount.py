import os
import shlex
import shutil

from gi import require_version

require_version("Nautilus", "4.1")

from gi.repository import GObject, Gio, Nautilus


MOUNT_ROOT = os.environ.get("NAS_MOUNT_ROOT", "/mnt/nas")
TERMINAL = "omarchy-launch-floating-terminal-with-presentation"


def _nas_bin():
    return shutil.which("nas") or os.path.expanduser("~/.local/bin/nas")


def _mountpoint(path):
    path = os.path.realpath(path)
    while path != "/" and not os.path.ismount(path):
        path = os.path.dirname(path)
    return path if os.path.ismount(path) else None


def _under_nas(path):
    real = os.path.realpath(path)
    return real == MOUNT_ROOT or real.startswith(MOUNT_ROOT + "/")


def _nas_mountpoint(path):
    return _mountpoint(path) if path and _under_nas(path) else None


class NasUnmount(GObject.GObject, Nautilus.MenuProvider):
    def _make_item(self, mountpoint):
        item = Nautilus.MenuItem(
            name="NasUnmount::nas_unmount",
            label="Unmount NAS",
            icon="media-eject",
        )
        item.connect("activate", self._on_activate, mountpoint)
        return item

    def _on_activate(self, _menu, mountpoint):
        wrapper = shutil.which(TERMINAL)
        cmd = shlex.join([_nas_bin(), "umount", mountpoint])
        argv = [wrapper, cmd] if wrapper else ["sh", "-c", cmd]
        Gio.Subprocess.new(argv, Gio.SubprocessFlags.NONE)

    def _target(self, files):
        for file in files:
            location = file.get_location()
            path = location.get_path() if location else None
            mountpoint = _nas_mountpoint(path)
            if mountpoint:
                return mountpoint
        return None

    def get_file_items(self, *args):
        files = args[0] if len(args) == 1 else args[1]
        mountpoint = self._target(files)
        return [self._make_item(mountpoint)] if mountpoint else []

    def get_background_items(self, current_folder):
        location = current_folder.get_location() if current_folder else None
        path = location.get_path() if location else None
        mountpoint = _nas_mountpoint(path)
        return [self._make_item(mountpoint)] if mountpoint else []

# Menu Stats Bar

An iStat-Menus-style system monitor for the [Omarchy](https://omarchy.org/) bar:
CPU, memory, disk, and temperature, each with a history sparkline in the bar and
a click-through detail panel.

## What it shows

Bar (left to right):

- **CPU** — usage %, with a history sparkline
- **Memory** — usage %, with a history sparkline
- **Disk** — usage %, with dual read/write activity bars (shared scale)
- **Temperature** — package temp °C, with a history sparkline

Each metric tints to the theme's urgent color, independently, when it crosses
its threshold (defaults: CPU 80 %, memory 80 %, disk 90 %, temp 90 °C).

Left-click opens a detail panel with:

- **CPU** — usage + history graph, load average, uptime, 16 per-core vertical
  bars (hover for the exact core), and the top CPU processes
- **Memory** — usage + history graph, used/total, swap, cached, and the top
  memory processes
- **Disk** — usage meter, used/free/space and mount, plus an I/O-throughput
  graph and peak
- **Temperature** — current reading + history graph with min/max

The panel is sized to fit a 960-logical-tall screen without scrolling.

## Install

```sh
omarchy plugin add https://github.com/jlai403/menu-stats-bar.git --enable
```

Then place it on the bar (it defaults to the center section):

```sh
omarchy bar move jlai.menu-stats-bar --section center
```

## Usage

- **Left-click** the bar item to open or close the detail panel.
- **Escape**, or clicking outside, closes the panel.

## Configure

Settings are read from the plugin's `barWidget` entry in `shell.json`:

| Key | Default | Meaning |
|---|---|---|
| `intervalSec` | `2` | Polling interval, in seconds (1–10) |
| `historySamples` | `300` | Samples retained per metric (60–900); sets the graph window |
| `cpuAlertPct` | `80` | Tint CPU above this usage; `0` disables |
| `ramAlertPct` | `80` | Tint memory above this usage; `0` disables |
| `diskAlertPct` | `90` | Tint disk above this usage; `0` disables |
| `tempAlertC` | `90` | Tint temperature above this reading; `0` disables |

## Remove

```sh
omarchy plugin remove jlai.menu-stats-bar
```

## Requirements

Linux (Omarchy/Arch). Runs as your user — no root, no network, no services. It
reads standard kernel interfaces and the sampler is invoked as:

- `bash`
- `/proc/stat`, `/proc/meminfo`, `/proc/loadavg`, `/proc/uptime`
- `/sys/block/*/stat` (disk I/O) and `/proc/diskstats`
- `/sys/class/hwmon/hwmon*/` (`coretemp`, `k10temp`, `cpu_thermal`, `zenpower`)
- `df` (filesystem usage) and `ps` (top processes)

History is cached at `${XDG_CACHE_HOME:-$HOME/.cache}/jlai.menu-stats-bar/history.ndjson`
(about 10 minutes at the default 2 s interval) so graphs survive a shell
restart.

## License

MIT — see [LICENSE](LICENSE).

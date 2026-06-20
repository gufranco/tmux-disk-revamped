# tmux-disk-revamped

[![Tests](https://github.com/gufranco/tmux-disk-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-disk-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Disk usage for your tmux status bar, without ever blocking the status render.

The value is read from a tmux server user-option and returns instantly, while a
detached worker runs `df` in the background. No temp files are used.

Built from
[tmux-plugin-template](https://github.com/gufranco/tmux-plugin-template).

## Placeholders

| Placeholder | Output |
|-------------|--------|
| `#{disk_percentage}` | used space, for example `55%` |
| `#{disk_icon}` | a tier icon for the current usage |
| `#{disk_fg_color}` / `#{disk_bg_color}` | colors for the current tier |
| `#{disk_used}` | used space in gigabytes, for example `100G` |
| `#{disk_total}` | total space in gigabytes, for example `466G` |
| `#{disk_read}` | disk read rate, Linux only, for example `1.2MB/s` |
| `#{disk_write}` | disk write rate, Linux only |

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'gufranco/tmux-disk-revamped'
set -g status-right '#{disk_icon} #{disk_percentage}'
```

Press `prefix + I` to install.

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@disk_revamped_mount` | `/` | the mount point to report |
| `@disk_revamped_interval` | `30` | seconds a reading stays fresh |
| `@disk_revamped_percentage_format` | `%s%%` | format for the value |
| `@disk_revamped_size_format` | `%sG` | format for used and total sizes |
| `@disk_revamped_medium_thresh` | `70` | usage percent for the medium tier |
| `@disk_revamped_high_thresh` | `90` | usage percent for the high tier |
| `@disk_revamped_{low,medium,high}_icon` | `▰▱▱`, `▰▰▱`, `▰▰▰` | tier icons |
| `@disk_revamped_{low,medium,high}_{fg,bg}_color` | empty | tier colors |
| `@disk_revamped_enable_logging` | `0` | set to `1` to log under `~/.tmux/disk-revamped-logs` |

## Support by platform and architecture

Works on every supported platform and architecture with built-in tools, no extra
package required. macOS (Intel and Apple Silicon) uses `df -g`; Linux (x86_64 and
arm64) uses `df -BG`. Sizes are reported in gigabytes.

Disk read and write I/O rates come from `/proc/diskstats` deltas and are Linux
only. macOS does not expose cumulative per-disk read and write byte counters
without a blocking sampler, so the I/O placeholders stay empty there.

## License

[MIT](LICENSE), copyright Gustavo Franco.

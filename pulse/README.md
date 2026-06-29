# pulse 🖥️

A lightweight, cyberpunk-themed system monitor for Debian/Linux, built with Python and Rich.

## Preview

> CPU, RAM, Disk panels with live sparkline graph and process table with interactive sorting.

## Features

- Real-time CPU, RAM and Disk monitoring with progress bars
- CPU usage sparkline graph (last 20 seconds)
- Live process table sortable by CPU or RAM
- Hostname, IP, uptime and current time in the header
- Cyberpunk color scheme (violet, cyan, neon pink)
- Smooth refresh with no flicker via Rich Live

## Requirements

- Debian/Linux
- Python 3
- python3-rich
- python3-psutil
- readchar

## Installation

```bash
git clone https://github.com/tuousername/script-debian.git
cd script-debian/pulse
chmod +x install.sh
./install.sh
```

## Usage

```bash
pulse
```

| Key | Action |
|-----|--------|
| `C` | Sort processes by CPU |
| `M` | Sort processes by RAM |
| `Ctrl+C` | Exit |

## Author

[github.com/OmarSabri4](https://github.com/OmarSabri4)

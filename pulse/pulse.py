#!/usr/bin/env python3
import psutil
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.columns import Columns
from rich.text import Text
from rich.live import Live
from rich.layout import Layout
from rich import box
import socket
import datetime
import time
import readchar
import threading

VIOLET = "#a78bfa"
CYAN   = "#22d3ee"
PINK   = "#f472b6"

console = Console()
cpu_history = []
sort_by = "cpu"
def sparkline(history):
    bars = " ▁▂▃▄▅▆▇█"
    return "".join(bars[min(int(v / 12.5), 8)] for v in history)

def bar(percent, color):
    filled = int(percent / 5)
    return f"[{color}]{'█' * filled}{'░' * (20 - filled)}[/{color}]"

def stat_panel(label, percent, color, used=None, total=None):
    content = Text()
    content.append(f"{percent}%\n", style=f"bold {color}")
    if used is not None:
        content.append(f"{used:.1f} GB / {total:.1f} GB\n", style="dim")
    content.append_text(Text.from_markup(f"[{color}]{sparkline(cpu_history)}[/{color}]\n"))
    content.append_text(Text.from_markup(bar(percent, color)))
    return Panel(content, title=f"[{color}]{label}[/{color}]", border_style=color, width=26)

def process_table():
    table = Table(box=box.SIMPLE, header_style=f"bold {VIOLET}", show_edge=False)
    table.add_column("PID",  style="dim", width=8)
    table.add_column("NAME", width=25)
    table.add_column(f"CPU% {'▼' if sort_by == 'cpu' else ''}", style=PINK, width=8)
    table.add_column(f"RAM% {'▼' if sort_by == 'ram' else ''}", style=CYAN, width=8)

    key = "cpu_percent" if sort_by == "cpu" else "memory_percent"
    procs = sorted(
        psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']),
        key=lambda p: p.info[key],
        reverse=True
    )
    for proc in procs[:15]:
        table.add_row(
            str(proc.info['pid']),
            proc.info['name'][:24],
            f"{proc.info['cpu_percent']:.1f}%",
            f"{proc.info['memory_percent']:.1f}%",
        )
    return table
def get_header():
    hostname = socket.gethostname()
    ip = socket.gethostbyname(hostname)
    uptime_sec = int(time.time() - psutil.boot_time())
    uptime = str(datetime.timedelta(seconds=uptime_sec))
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    header = Text()
    header.append("▓▓ PULSE  ", style=f"bold {VIOLET}")
    header.append(f"{hostname} ", style=f"bold {CYAN}")
    header.append(f"{ip}  ", style="dim")
    header.append(f"up {uptime}  ", style=f"{PINK}")
    header.append(now, style="dim")
    return header

def build_layout():
    ram  = psutil.virtual_memory()
    disk = psutil.disk_usage('/')

    layout = Layout()
    layout.split_column(
        Layout(name="title",  size=2),
        Layout(name="stats",  size=7),
        Layout(name="procs"),
        Layout(name="footer", size=2),
    )

    cpu_percent = psutil.cpu_percent()
    cpu_history.append(cpu_percent)
    cpu_history[:] = cpu_history[-20:]

    layout["title"].update(get_header())
    layout["stats"].update(Columns([
        stat_panel("CPU",  cpu_percent,  VIOLET),
        stat_panel("RAM",  ram.percent,  CYAN, ram.used/1e9,  ram.total/1e9),
        stat_panel("DISK", disk.percent, PINK, disk.used/1e9, disk.total/1e9),
    ]))
    layout["procs"].update(process_table())
    layout["footer"].update(Text("[ C: sort by CPU  |  M: sort by RAM  |  CTRL+C TO EXIT ]", style="dim", justify="center"))

    return layout

def input_listener():
    global sort_by
    while True:
        key = readchar.readkey()
        if key == "c":
            sort_by = "cpu"
        elif key == "m":
            sort_by = "ram"

listener = threading.Thread(target=input_listener, daemon=True)
listener.start()

try:
    with Live(build_layout(), console=console, refresh_per_second=2, screen=True) as live:
        while True:
            time.sleep(0.5)
            live.update(build_layout())  # ricostruisce il layout ad ogni tick, aggiorna header, uptime e ora

except KeyboardInterrupt:
    console.print(f"[bold {VIOLET}]pulse closed.[/bold {VIOLET}]")


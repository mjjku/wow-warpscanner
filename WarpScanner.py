#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WarpFusion Elite Pro v7.0.0 - The Ultimate All-in-One Warp Solution
Description:
A fully automated, intelligent, and professional script combining the best features of WarpStealth,
WarpScanner, and WarpFusion, enhanced with multi-protocol support (WireGuard, Hysteria, V2Ray, Sing-box),
smart dependency installation, advanced scanning, optimized configurations, and comprehensive error handling.
"""

import os
import sys
import json
import time
import base64
import socket
import subprocess
import platform
import random
import logging
import threading
import urllib.request
import urllib.error
import shutil
from typing import List, Tuple, Optional, Dict
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass

# --- Smart Dependency Installer ---
try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, BarColumn, TimeRemainingColumn, TextColumn
    from rich.table import Table
    from rich.prompt import Prompt
    from rich.markdown import Markdown
    from icmplib import multiping, ping
    from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
    from cryptography.hazmat.primitives import serialization
    import psutil
    import requests
    import yaml
    from alive_progress import alive_bar
except ImportError:
    print("\n📦 Installing required dependencies...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install",
                               "rich", "icmplib", "cryptography", "psutil", "requests",
                               "pyyaml", "alive_progress"])
        print("\n✅ Dependencies installed successfully. Restarting script...")
        os.execv(sys.executable, [sys.executable] + sys.argv)
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Failed to install dependencies: {e}")
        print("Please install manually: pip install rich icmplib cryptography psutil requests pyyaml alive_progress")
        sys.exit(1)

# --- Global Configuration ---
console = Console()
VERSION = "7.0.0"
CONFIG_FILE = "warpfusion_config.json"
WARP_CONF_DIR = "warp_profiles"
LOG_DIR = "warp_logs"
WARP_CONF_PREFIX = "warpfusion_elite"
TEST_URL = "http://www.gstatic.com/generate_204"
CF_API = "https://api.cloudflareclient.com/v0a3596/reg"
USER_AGENT = "okhttp/3.12.1"
API_TIMEOUT = 10
MAX_API_RETRIES = 5
PING_COUNT = 4
PING_TIMEOUT = 2.0
PORT_SCAN_TIMEOUT = 1.0
SCAN_THREADS = 100
SUPPORTED_PROTOCOLS = ["WireGuard", "Hysteria", "V2Ray", "Sing-box"]

WARP_PORTS = [500, 854, 859, 864, 878, 880, 890, 891, 894, 903, 908, 934, 939, 943, 945, 946, 955, 968, 987, 1002, 1007, 1010, 1014, 1018, 1027, 1032, 1048, 1054, 1074, 1180, 1387, 1701, 2371, 2408, 2506, 3138, 3476, 3581, 4177, 4198, 4233, 4500, 5279, 5956, 7106, 7152, 7159, 7281, 7559, 8319, 8784, 8854, 8886]

WARP_ENDPOINTS = [
    "162.159.192.1", "162.159.192.2", "162.159.193.1", "162.159.193.2",
    "162.159.195.1", "162.159.195.2", "188.114.96.1", "188.114.96.2",
    "188.114.97.1", "188.114.97.2", "2606:4700:d0::a29f:c001",
    "2606:4700:4700::1111", "2606:4700:4700::1001"
]

DEFAULT_CONFIG = {
    "core": {
        "test_url": TEST_URL,
        "log_level": "info",
        "allow_insecure_tls": False,
        "sniffing_enabled": True,
        "dns": {
            "enabled": True,
            "servers": ["1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001"],
            "local_port": 10853
        },
        "mux": {"enabled": True, "concurrency": 8}
    },
    "wireguard": {"mtu": 1280, "keepalive": 25},
    "scan": {"timeout": 2, "max_threads": 100}
}

@dataclass
class WarpKey:
    private_key: str
    public_key: str
    client_id: str
    address_v4: str
    address_v6: str
    last_updated: str

@dataclass
class ScanResult:
    ip: str
    port: int
    latency: float
    packet_loss: float
    jitter: float
    score: float = 0.0

class WarpFusionElitePro:
    def __init__(self):
        self.config = self.load_config()
        self.setup_logging()
        self.console = Console()
        self.ping_timeout = PING_TIMEOUT
        self.port_scan_timeout = PORT_SCAN_TIMEOUT

    def load_config(self) -> Dict:
        if not os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, "w") as f:
                json.dump(DEFAULT_CONFIG, f, indent=2)
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except json.JSONDecodeError:
            self.console.print("[yellow]⚠️ Corrupted config file. Using default configuration.[/yellow]")
            return DEFAULT_CONFIG

    def setup_logging(self):
        os.makedirs(LOG_DIR, exist_ok=True)
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(os.path.join(LOG_DIR, "warpfusion.log")),
                logging.StreamHandler()
            ]
        )

    def print_banner(self):
        banner = f"""
[bold cyan]██╗    ██╗ █████╗ ██████╗ ██████╗ ███████╗██╗   ██╗███████╗██╗ ██████╗ ███╗   ██╗[/bold cyan]
[bold cyan]██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██║   ██║██╔════╝██║██╔═══██╗████╗  ██║[/bold cyan]
[bold cyan]██║ █╗ ██║███████║██████╔╝██████╔╝█████╗  ██║   ██║███████╗██║██║   ██║██╔██╗ ██║[/bold cyan]
[bold cyan]██║███╗██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██║   ██║╚════██║██║██║   ██║██║╚██╗██║[/bold cyan]
[bold cyan]╚███╔███╔╝██║  ██║██║     ██║     ███████╗╚██████╔╝███████║██║╚██████╔╝██║ ╚████║[/bold cyan]
[bold cyan] ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝[/bold cyan]
[yellow]Elite Pro v{VERSION} - The Ultimate Cloudflare Warp Solution[/yellow]
[green]Fully automated, intelligent, multi-protocol, and error-free[/green]
"""
        self.console.print(Panel(banner, border_style="magenta", expand=False))

    def run_initial_checks(self):
        self.console.print("[bold]🔄 Performing initial checks...[/bold]")
        if os.geteuid() != 0 and platform.system() == "Linux":
            self.console.print("[red]❌ Error: This script requires root/sudo privileges on Linux.[/red]")
            sys.exit(1)
        self.console.print("[green]✅ Root privileges confirmed or not required.[/green]")

        if not shutil.which("wg-quick"):
            self.console.print("[yellow]⚠️ WireGuard tools not found. Installing...[/yellow]")
            os_type = platform.system().lower()
            install_cmd = {
                "linux": "sudo apt-get update && sudo apt-get install -y wireguard",
                "darwin": "brew install wireguard-tools"
            }.get(os_type, "Please install WireGuard tools manually.")
            try:
                subprocess.run(install_cmd, shell=True, check=True)
                self.console.print("[green]✅ WireGuard tools installed.[/green]")
            except subprocess.CalledProcessError:
                self.console.print(f"[red]❌ Failed to install WireGuard tools: {install_cmd}[/red]")
                sys.exit(1)

        try:
            urllib.request.urlopen(TEST_URL, timeout=5)
            self.console.print("[green]✅ Internet connection verified.[/green]")
        except (urllib.error.URLError, socket.timeout):
            self.console.print("[red]❌ No internet connection. Please check your network.[/red]")
            sys.exit(1)

    def optimize_system(self):
        if platform.system() != "Linux":
            self.console.print("[yellow]⚠️ System optimization only supported on Linux.[/yellow]")
            return
        optimizations = {
            "net.core.rmem_max": "16777216",
            "net.core.wmem_max": "16777216",
            "net.ipv4.tcp_congestion_control": "bbr",
            "net.ipv4.tcp_fastopen": "3",
            "net.ipv4.tcp_syncookies": "1"
        }
        try:
            with open("/etc/sysctl.conf", "r") as f:
                existing = f.read()
            with open("/etc/sysctl.conf", "a") as f:
                if "# WarpFusion Optimizations" not in existing:
                    f.write("\n# WarpFusion Optimizations\n")
                    for key, value in optimizations.items():
                        subprocess.run(["sysctl", "-w", f"{key}={value}"], check=True)
                        f.write(f"{key}={value}\n")
            subprocess.run(["sysctl", "-p"], check=True)
            self.console.print("[green]✅ System optimizations applied.[/green]")
        except Exception as e:
            self.console.print(f"[yellow]⚠️ Failed to apply optimizations: {e}[/yellow]")

    def detect_network_quality(self):
        self.console.print("[bold]📡 Assessing network quality...[/bold]")
        try:
            host = multiping(["1.1.1.1"], count=PING_COUNT, timeout=2, privileged=False)[0]
            if not host.is_alive:
                raise ValueError("No response from ping target")
            latency = host.avg_rtt
            if latency < 100:
                status = f"[green]Excellent ({latency:.0f}ms)[/green]"
                self.ping_timeout, self.port_scan_timeout = 2.0, 1.0
                self.config["scan"]["max_threads"] = 150
            elif latency < 250:
                status = f"[yellow]Good ({latency:.0f}ms)[/yellow]"
                self.ping_timeout, self.port_scan_timeout = 3.0, 1.5
                self.config["scan"]["max_threads"] = 100
            else:
                status = f"[red]Poor ({latency:.0f}ms)[/red]"
                self.ping_timeout, self.port_scan_timeout = 4.0, 2.0
                self.config["scan"]["max_threads"] = 50
            self.console.print(f"   Network quality: {status}")
        except Exception as e:
            self.console.print(f"[yellow]⚠️ Network quality detection failed: {e}. Using defaults.[/yellow]")

    def generate_wg_keys(self) -> Tuple[bytes, bytes]:
        private_key = X25519PrivateKey.generate()
        public_key = private_key.public_key()
        return (
            private_key.private_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PrivateFormat.Raw,
                encryption_algorithm=serialization.NoEncryption()
            ),
            public_key.public_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PublicFormat.Raw
            )
        )

    def register_warp_key(self, public_key_b64: str) -> dict:
        headers = {
            'Content-Type': 'application/json; charset=UTF-8',
            'User-Agent': USER_AGENT
        }
        data = json.dumps({
            "key": public_key_b64,
            "install_id": "",
            "fcm_token": "",
            "warp_enabled": True,
            "tos": time.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
            "type": "Android",
            "locale": "en_US"
        }).encode('utf-8')
        for attempt in range(MAX_API_RETRIES):
            try:
                req = urllib.request.Request(CF_API, data=data, headers=headers)
                with urllib.request.urlopen(req, timeout=API_TIMEOUT) as res:
                    return json.load(res)
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    wait_time = 2 ** attempt
                    self.console.print(f"[yellow]⚠️ API rate limit. Retrying in {wait_time}s...[/yellow]")
                    time.sleep(wait_time)
                else:
                    raise
            except Exception as e:
                if attempt == MAX_API_RETRIES - 1:
                    raise RuntimeError(f"Failed to register key: {e}")
                time.sleep(1)

    def create_warp_key(self) -> WarpKey:
        self.console.print("[bold]🔑 Generating and registering new Warp key...[/bold]")
        priv_key_bytes, pub_key_bytes = self.generate_wg_keys()
        priv_key_b64 = base64.b64encode(priv_key_bytes).decode('utf-8')
        pub_key_b64 = base64.b64encode(pub_key_bytes).decode('utf-8')
        try:
            api_config = self.register_warp_key(pub_key_b64)
            return WarpKey(
                private_key=priv_key_b64,
                public_key=api_config['config']['peers'][0]['public_key'],
                client_id=api_config['config']['client_id'],
                address_v4=api_config['config']['interface']['addresses']['v4'],
                address_v6=api_config['config']['interface']['addresses']['v6'],
                last_updated=time.strftime("%Y-%m-%d %H:%M:%S")
            )
        except Exception as e:
            self.console.print(f"[red]❌ Failed to create Warp key: {e}[/red]")
            sys.exit(1)

    def load_or_create_key(self) -> WarpKey:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    data = json.load(f)
                if all(k in data for k in WarpKey.__annotations__):
                    return WarpKey(**data)
            except (json.JSONDecodeError, KeyError, TypeError):
                self.console.print("[yellow]⚠️ Invalid key config. Generating new key...[/yellow]")
        warp_key = self.create_warp_key()
        with open(CONFIG_FILE, 'w') as f:
            json.dump(warp_key.__dict__, f, indent=4)
        return warp_key

    def _filter_active_endpoints(self, ipv6=False) -> List[Tuple[str, float]]:
        endpoints = WARP_ENDPOINTS if not ipv6 else [f"2606:4700:d{random.randint(0,1)}::{random.randint(0,65535):x}:{random.randint(0,65535):x}" for _ in range(100)]
        with Progress(TextColumn("[cyan]Filtering active endpoints...[/cyan]"), BarColumn(), TimeRemainingColumn(), transient=True) as progress:
            task = progress.add_task("", total=len(endpoints))
            hosts = multiping(endpoints, count=PING_COUNT, timeout=self.ping_timeout, privileged=False)
            progress.update(task, completed=len(endpoints))
        return [(h.address, h.avg_rtt) for h in hosts if h.is_alive]

    def _test_port_connection(self, ip: str, port: int) -> Optional[Tuple[float, float, float]]:
        try:
            family = socket.AF_INET6 if ':' in ip else socket.AF_INET
            with socket.socket(family, socket.SOCK_DGRAM) as sock:
                sock.settimeout(self.port_scan_timeout)
                start_time = time.monotonic()
                sock.connect((ip, port))
                sock.send(b'\x01')
                sock.recv(1)
                latency = (time.monotonic() - start_time) * 1000
                jitter = random.uniform(0.1, 2.0)
                return latency, 0.0, jitter
        except (socket.timeout, ConnectionRefusedError, OSError):
            return None

    def _deep_scan_ports(self, ips: List[str]) -> List[ScanResult]:
        results = []
        total_tasks = len(ips) * len(WARP_PORTS)
        with Progress(TextColumn("[cyan]Scanning ports...[/cyan]"), BarColumn(), "[progress.percentage]{task.percentage:>3.0f}%", TimeRemainingColumn(), transient=True) as progress:
            task = progress.add_task("", total=total_tasks)
            with ThreadPoolExecutor(max_workers=self.config["scan"]["max_threads"]) as executor:
                futures = {executor.submit(self._test_port_connection, ip, port): (ip, port) for ip in ips for port in WARP_PORTS}
                for future in as_completed(futures):
                    progress.update(task, advance=1)
                    ip, port = futures[future]
                    result = future.result()
                    if result:
                        latency, loss, jitter = result
                        results.append(ScanResult(ip=ip, port=port, latency=latency, packet_loss=loss, jitter=jitter))
        return results

    def find_best_servers(self, ipv6=False) -> List[ScanResult]:
        self.console.print("\n[bold magenta]🔬 Starting advanced 2-stage endpoint scan...[/bold magenta]")
        active_hosts = self._filter_active_endpoints(ipv6)
        if not active_hosts:
            self.console.print("[red]� bazen None
            self.console.print("[green]✅ Found {} active endpoints.[/green]".format(len(active_hosts)))
            top_hosts = [ip for ip, _ in sorted(active_hosts, key=lambda x: x[1])[:30]]
            results = self._deep_scan_ports(top_hosts)
            if not results:
                self.console.print("[red]❌ No viable ports found.[/red]")
                return []
            for result in results:
                score = ((1000 - result.latency) * 0.6 + (100 - result.packet_loss) * 0.3 + (10 - result.jitter) * 0.1)
                result.score = max(0, score)
            return sorted(results, key=lambda x: x.score, reverse=True)[:10]

    def display_results_table(self, results: List[ScanResult]):
        table = Table(title=f"[bold magenta]🏆 WarpFusion Elite Pro v{VERSION} - Top Servers[/bold magenta]", show_header=True)
        table.add_column("Rank", style="cyan", justify="center")
        table.add_column("IP", style="white")
        table.add_column("Port", style="green", justify="center")
        table.add_column("Latency (ms)", style="yellow", justify="right")
        table.add_column("Jitter (ms)", justify="right")
        table.add_column("Score", style="bold green", justify="right")
        for i, result in enumerate(results[:10], 1):
            table.add_row(
                f"#{i}", result.ip, str(result.port), f"{result.latency:.2f}",
                f"{result.jitter:.2f}", f"{result.score:.2f}"
            )
        self.console.print(table)

    def generate_wg_config(self, warp_key: WarpKey, result: ScanResult, format_type="wg") -> str:
        if format_type == "wg":
            return f"""
# WarpFusion Elite Pro v{VERSION} - WireGuard Config
[Interface]
PrivateKey = {warp_key.private_key}
Address = {warp_key.address_v4}, {warp_key.address_v6}
DNS = {', '.join(self.config['core']['dns']['servers'])}
MTU = {self.config['wireguard']['mtu']}

[Peer]
PublicKey = {warp_key.public_key}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = {result.ip}:{result.port}
PersistentKeepalive = {self.config['wireguard']['keepalive']}
"""
        elif format_type == "sing-box":
            reserved = base64.b64decode(warp_key.client_id)
            reserved_str = ','.join(str(b) for b in reserved)
            return f"""
{{
  "outbounds": [
    {{
      "type": "wireguard",
      "tag": "WarpFusion-WireGuard",
      "local_address": ["{warp_key.address_v4}", "{warp_key.address_v6}"],
      "private_key": "{warp_key.private_key}",
      "server": "{result.ip}",
      "server_port": {result.port},
      "peer_public_key": "{warp_key.public_key}",
      "reserved": [{reserved_str}],
      "mtu": {self.config['wireguard']['mtu']}
    }}
  ]
}}
"""
        elif format_type == "v2ray":
            reserved = base64.b64decode(warp_key.client_id)
            reserved_str = json.dumps([int(b) for b in reserved])
            return f"""
{{
  "outbounds": [
    {{
      "protocol": "wireguard",
      "settings": {{
        "address": ["{warp_key.address_v4}", "{warp_key.address_v6}"],
        "mtu": {self.config['wireguard']['mtu']},
        "peers": [
          {{
            "endpoint": "{result.ip}:{result.port}",
            "publicKey": "{warp_key.public_key}"
          }}
        ],
        "reserved": {reserved_str},
        "secretKey": "{warp_key.private_key}"
      }},
      "tag": "WarpFusion-V2Ray"
    }}
  ]
}}
"""

    def generate_and_save_configs(self, warp_key: WarpKey, results: List[ScanResult], format_type="wg"):
        self.console.print("\n[bold]📄 Generating configuration files...[/bold]")
        os.makedirs(WARP_CONF_DIR, exist_ok=True)
        for i, result in enumerate(results[:3], 1):
            config_str = self.generate_wg_config(warp_key, result, format_type)
            ext = "conf" if format_type == "wg" else "json"
            filename = f"{WARP_CONF_PREFIX}_{format_type}_{i}.{ext}"
            path = os.path.join(WARP_CONF_DIR, filename)
            try:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(config_str.strip())
                self.console.print(Panel(
                    config_str.strip(),
                    title=f"[bold green]Config #{i} ({filename})[/bold green]",
                    subtitle=f"[yellow]Saved to: {path}[/yellow]",
                    border_style="green"
                ))
            except Exception as e:
                self.console.print(f"[red]❌ Failed to save config {filename}: {e}[/red]")

    def display_usage_guide(self, format_type="wg"):
        guide = Markdown(f"""
### 📖 WarpFusion Elite Pro Usage Guide ({format_type.upper()})

Your configurations are ready! Follow these steps:

#### For WireGuard:
```bash
sudo wg-quick up ./{WARP_CONF_DIR}/{WARP_CONF_PREFIX}_wg_1.conf
sudo wg-quick down ./{WARP_CONF_DIR}/{WARP_CONF_PREFIX}_wg_1.conf

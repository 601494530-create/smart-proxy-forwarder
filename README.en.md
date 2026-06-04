# Smart Proxy Forwarder

A lightweight, DNS-leak-free CONNECT/SOCKS5 proxy with automatic China IP routing.
**Domestic → direct | International → via remote proxy.**

Designed for WSL users behind China's firewall who want their terminal tools
(curl, git, npm, Python, AI agents) to enjoy the same connectivity as their
browser VPN, **without leaking DNS queries**.

> **中文版：** [README.md](README.md)

---

## Feature Overview

| Feature | Description |
|---------|-------------|
| ✅ **Smart Routing** | Domain whitelist → direct / IP lookup → China check / else → proxy |
| ✅ **Dual Upstream** | HTTPS CONNECT (default) + **SOCKS5** |
| ✅ **Multi-Upstream** | Comma-separated failover servers |
| ✅ **TLS Connection Pool** | Pre-warmed connections, reduced handshake latency |
| ✅ **Web Dashboard** | `http://127.0.0.1:10809/` — live status, Chinese/English toggle |
| ✅ **REST API** | `/stats` returns JSON, integrable with monitoring |
| ✅ **Request Logging** | `--log-requests` shows target, route, timing per connection |
| ✅ **Health Check** | Tests upstream every 30s, status on dashboard |
| ✅ **Connection Stats** | Total/active connections, traffic, uptime |
| ✅ **DNS Leak Free** | Routing never resolves hostnames locally |
| ✅ **One-Click Install** | `bash setup.sh your-proxy.com 443` |
| ✅ **Docker + systemd** | Container + system service support |

---

## How It Works

```
Your apps (curl / git / npm / Python / agent-browser)
    │  http_proxy=http://127.0.0.1:10808
    ▼
┌─ proxy_forwarder.py ──────────────────────────────┐
│                                                    │
│  Domain in the whitelist? (Baidu, DeepSeek, etc.)  │
│    → Direct connection (fast)                      │
│                                                    │
│  Raw IP address?                                   │
│    → Check 44 built-in China CIDR ranges           │
│                                                    │
│  Other hostnames                                   │
│    → Default to proxy (DNS-safe, no leak)          │
│      ├─ HTTPS CONNECT → TLS tunnel → proxy → dst   │
│      └─ SOCKS5       → TCP + SOCKS5 handshake      │
└────────────────────────────────────────────────────┘
```

**No DNS leak:** routing decisions never resolve hostnames locally.
Only the proxy server itself is resolved once via system DNS — unavoidable.

---

## Requirements

- **Python 3.8+** (stdlib only — no pip dependencies)
- **Linux / WSL2**
- An **HTTPS CONNECT** or **SOCKS5** proxy server upstream

---

## Quick Start

```bash
git clone https://github.com/pocraft/smart-proxy-forwarder.git
cd smart-proxy-forwarder

# One-click install
bash setup.sh your-proxy.example.com 443

# Self-signed cert? Add a 3rd arg:
bash setup.sh your-proxy.example.com 443 true

# Verify
curl -v https://www.google.com    # → proxy
curl -v https://www.baidu.com     # → direct (faster)
```

---

## CLI Reference

| Argument | Default | Description |
|----------|---------|-------------|
| `--listen-host` | `127.0.0.1` | Local listen address |
| `--listen-port` | `10808` | Local listen port |
| `--remote-host` | **(required)** | Remote proxy (comma-separated for multi) |
| `--remote-port` | `443` | Remote proxy port |
| `--upstream-type` | `connect` | `connect` (HTTPS CONNECT) or `socks5` |
| `--pool-size` | `4` | TLS connection pool size |
| `--config` | `""` | Path to JSON config file |
| `--insecure` / `-k` | `false` | Skip TLS certificate verification |
| `--log-requests` | `false` | Log each CONNECT target, route, timing |
| `--api-port` | `10809` | REST API / dashboard port |
| `--version` | - | Show version |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXY_PORT` | `10808` | Override port in all scripts |
| `PROXY_LOG` | `/tmp/proxy-forwarder.log` | Log file path |
| `XDG_CONFIG_HOME` | `~/.config` | Config directory base |

### Config file

Installed at `~/.config/proxy-forwarder/config.json`:

```json
{
  "remote": { "host": "your-proxy.com", "port": 443 },
  "listen": { "host": "127.0.0.1", "port": 10808 },
  "insecure": false,
  "upstream_type": "connect",
  "pool_size": 4,
  "log_requests": false,
  "china_ip_list_url": "",
  "direct_domains": ["*.my-corp.com"],
  "api_port": 10809
}
```

CLI args override config file values.

---

## Management

```bash
bash ~/.config/proxy-forwarder/proxy-manager.sh status   # Status + stats
bash ~/.config/proxy-forwarder/proxy-manager.sh logs     # View log
bash ~/.config/proxy-forwarder/proxy-manager.sh restart  # Restart
bash ~/.config/proxy-forwarder/proxy-manager.sh stop     # Stop
bash ~/.config/proxy-forwarder/proxy-manager.sh start    # Start
```

**Sample output:**
```
  Running
   PID:      11454
   Port:     10808
   RAM:      27MB
   Uptime:   1h23m
   Conns:    42 total, 0 active
   Traffic:  2343 KB (22 KB ↓ / 2321 KB ↑)
   Health:   ✅ alive
```

---

## Web Dashboard

Open `http://127.0.0.1:10809/` in your browser:

```
┌───────────────────────────────────────┐
│  🔄 Proxy Forwarder    [中文] [EN]   │
│                                       │
│  Status       Alive                   │
│  Uptime       1h23m                   │
│  Connections  42 total, 0 active      │
│  Traffic      2343 KB                 │
│  Upstream     fan.226278.xyz:443      │
│  Type         connect                 │
│  Pool Size    4                       │
│  Version      1.2.0                   │
└───────────────────────────────────────┘
```

Auto-refreshes every 5 seconds. Toggle Chinese/English in the top-right.

---

## REST API

```bash
curl http://127.0.0.1:10809/stats
# → {"uptime":"1h23m","total_connections":42,"health":"alive",
#     "upstream_type":"connect","pool_size":4,...}
```

---

## Request Logging

```bash
proxy-forwarder --remote-host x.com --log-requests

# [14:00:01] www.google.com:443 → proxy (DNS-safe) 2.1s
# [14:00:02] www.baidu.com:443 → direct (direct-domain) 0.1s
```

---

## Multi-Upstream

```bash
proxy-forwarder --remote-host "hk-proxy.com:443,jp-proxy.com:8443"
```

Random selection with health monitoring on all upstreams.

---

## SOCKS5 Upstream

```bash
# SSH tunnel
ssh -D 1080 your-server
proxy-forwarder --upstream-type socks5 --remote-host 127.0.0.1 --remote-port 1080

# Shadowsocks / V2Ray / airport subscription
proxy-forwarder --upstream-type socks5 --remote-host node.example.com --remote-port 1080
```

---

## TLS Connection Pool

```bash
# Default pool size: 4
proxy-forwarder --remote-host x.com --pool-size 4

# High concurrency: increase pool
proxy-forwarder --remote-host x.com --pool-size 16
```

Connections recycled after 5 minutes. HTTPS CONNECT upstream only.

---

## DNS Leak Protection

1. Domain whitelist → no DNS needed
2. Raw IP → checked against built-in China CIDR set
3. Other hostnames → **default to proxy** without resolving

The only DNS query leaving your machine is for the proxy server itself.

---

## Security

- **TLS certificate verification is ON by default.** Use `--insecure`/`-k` to disable:
  ```bash
  proxy-forwarder --remote-host example.com --insecure
  ```
- `--insecure` exposes you to MITM — only use with **trusted proxies**
- Traffic content is end-to-end encrypted (your tool → target server)
- REST API and proxy port bind to `127.0.0.1` only

---

## Docker

```bash
docker build -t proxy-forwarder .
docker run -d --restart unless-stopped --name proxy \
  -p 10808:10808 \
  -e REMOTE_HOST=your-proxy.com \
  proxy-forwarder
```

---

## systemd

```bash
sudo cp deploy/proxy-forwarder.service /etc/systemd/system/
sudo systemctl enable proxy-forwarder
sudo systemctl start proxy-forwarder
```

---

## Project Files

| File | Description |
|------|-------------|
| `proxy_forwarder.py` | Core forwarder (762 lines, pure Python stdlib) |
| `proxy-manager.sh` | Management script |
| `setup.sh` | One-click install |
| `bash-integration.sh` | Shell integration snippet |
| `config.example.json` | Config template |
| `deploy/proxy-forwarder.service` | systemd service unit |
| `Dockerfile` | Container build |
| `README.md` | Chinese documentation |
| `CHANGELOG.md` | Version history |
| `tests/` | **42 unit + integration tests** |

Compatible with HTTPS CONNECT and SOCKS5 proxies.

---

## License

MIT

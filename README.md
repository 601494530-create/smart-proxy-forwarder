# Smart Proxy Forwarder

A lightweight, DNS-leak-free CONNECT proxy that auto-routes traffic:
**domestic → direct**, **international → via remote HTTPS proxy**.

Designed for WSL users behind China's GFW who use a Chrome extension VPN
or any HTTPS CONNECT proxy as their gateway, and want their WSL terminal
tools (curl, git, npm, agent-browser, etc.) to enjoy the same connectivity
**without leaking DNS queries**.

---

## How It Works

```
Your apps (curl / git / npm / Python / agent-browser)
    │  http_proxy=http://127.0.0.1:10808
    ▼
┌─ proxy-forwarder.py ──────────────────────────────┐
│                                                    │
│  Domain in direct list? (Baidu, DeepSeek, etc.)    │
│    → Direct connection (fast)                       │
│                                                    │
│  Raw IP address?                                   │
│    → Check China IP set → Direct / Proxy            │
│                                                    │
│  Everything else                                   │
│    → Route via remote HTTPS proxy (DNS-safe)        │
│      └─ TLS tunnel → your proxy → internet          │
└────────────────────────────────────────────────────┘
```

**No DNS leak:** routing decisions never resolve hostnames locally.
Only the proxy server itself is resolved once per session via system DNS
— unavoidable, like any VPN.

---

## Requirements

- **Python 3.8+** (stdlib only — no pip dependencies)
- **WSL2** (Linux) — but works anywhere with Python
- An **HTTPS CONNECT proxy server** (e.g., a Chrome VPN extension's
  upstream server, a VPS with squid/caddy, etc.)

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_USER/smart-proxy-forwarder.git
cd smart-proxy-forwarder

# 2. Run setup (provide your proxy server)
bash setup.sh your-proxy.example.com 443

# 3. Source or restart terminal
source ~/.bashrc

# 4. Verify
curl -v https://www.google.com    # → should work
curl -v https://www.baidu.com     # → should also work (fast, direct)
```

---

## Manual Setup

### 1. Start the forwarder

```bash
python3 proxy-forwarder.py \
    --remote-host your-proxy.example.com \
    --remote-port 443 \
    --listen-port 10808
```

### 2. Set proxy env vars

```bash
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export no_proxy="localhost,127.0.0.1,::1,api.deepseek.com,*.deepseek.com,\
*.baidu.com,*.qq.com,*.aliyun.com,*.taobao.com,*.jd.com,*.weixin.qq.com,\
*.zhihu.com,*.bilibili.com,*.tuna.tsinghua.edu.cn,*.ustc.edu.cn,\
10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="$no_proxy"
```

### 3. (Optional) Configure git & npm

```bash
git config --global http.proxy http://127.0.0.1:10808
npm config set proxy http://127.0.0.1:10808
npm config set https-proxy http://127.0.0.1:10808
```

---

## Configuration

### Command-line args

| Argument | Default | Description |
|----------|---------|-------------|
| `--listen-host` | `127.0.0.1` | Local listen address |
| `--listen-port` | `10808` | Local listen port |
| `--remote-host` | (required) | Remote HTTPS CONNECT proxy host |
| `--remote-port` | `443` | Remote HTTPS CONNECT proxy port |
| `--config` | `""` | Path to config JSON file |

### Config file (`config.json`)

```json
{
  "remote": { "host": "your-proxy.com", "port": 443 },
  "listen": { "host": "127.0.0.1", "port": 10808 },
  "china_ip_list_url": "",
  "direct_domains": ["*.my-corp.com"]
}
```

CLI args take precedence over config file values.

---

## Management

```bash
bash ~/.hermes/scripts/proxy-manager.sh status   # Check status
bash ~/.hermes/scripts/proxy-manager.sh restart  # Restart proxy
bash ~/.hermes/scripts/proxy-manager.sh stop     # Stop proxy
bash ~/.hermes/scripts/proxy-manager.sh start    # Start proxy
```

---

## DNS Leak Protection

The forwarder **never performs local DNS resolution** for routing decisions:

1. Direct domain list → no DNS needed
2. Raw IP address → checked against built-in China CIDR set
3. Other hostnames → **default to proxy** without resolving locally

The only DNS query that leaves your machine is for the proxy server
itself (`remote-host`) — a single, unavoidable lookup.

---

## Architecture

- **`proxy-forwarder.py`** — Core CONNECT forwarder with China IP routing
- **`proxy-manager.sh`** — Service management (start/stop/status)
- **`setup.sh`** — One-click installation
- **`bash-integration.sh`** — `.bashrc` snippet (auto-start + env vars)
- **`config.example.json`** — Configuration template

Works with any HTTPS CONNECT proxy (VPN extensions, Squid, Caddy,
mitmproxy, etc.).

---

## License

MIT

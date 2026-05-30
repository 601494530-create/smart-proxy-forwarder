# Smart Proxy Forwarder

轻量级 DNS 防泄漏 CONNECT 代理转发器。**国内直连、国际走远程 HTTPS 代理**，自动分流。

专为 WSL 用户设计——你在 Chrome 里用 VPN 插件/代理能翻墙，但 WSL 终端里的 curl、git、npm、Python、AI agent 等工具也能享受同样的能力，**且不泄漏 DNS 查询**。

---

## 工作原理

```
你的程序（curl / git / npm / Python / agent-browser）
    │  http_proxy=http://127.0.0.1:10808
    ▼
┌─ proxy-forwarder.py ──────────────────────────────┐
│                                                    │
│  域名在白名单？（百度/DeepSeek/B站等）               │
│    → 直连（快速）                                   │
│                                                    │
│  目标是纯 IP 地址？                                 │
│    → 查国内 IP 段 → 国内直连 / 国际代理              │
│                                                    │
│  其他域名                                           │
│    → 默认走远程代理（DNS 防泄漏）                    │
│      └─ TLS 隧道 → 你的代理服务器 → 国际互联网       │
└────────────────────────────────────────────────────┘
```

**没有 DNS 泄漏：** 路由判定从不进行本地 DNS 解析。只有代理服务器本身会在启动时通过系统 DNS 解析一次 —— 这是任何 VPN/代理都不可避免的。

---

## 运行环境

- **Python 3.8+**（只用了标准库，无需 pip 安装任何依赖）
- **WSL2 / Linux**（实际上任何有 Python 的地方都能跑）
- 一个 **HTTPS CONNECT 代理服务器**（比如 Chrome VPN 插件的上游服务器、VPS 上搭的 squid/caddy 等）

---

## 快速开始

```bash
# 1. 克隆
git clone https://github.com/601494530-create/smart-proxy-forwarder.git
cd smart-proxy-forwarder

# 2. 一键安装（填你的代理服务器地址）
bash setup.sh your-proxy.example.com 443

# 3. 重新打开终端或执行 source
source ~/.bashrc

# 4. 验证
curl -v https://www.google.com    # → 应成功（走代理）
curl -v https://www.baidu.com     # → 也应成功（直连，更快）
```

---

## 手动安装

### 1. 启动转发器

```bash
python3 proxy-forwarder.py \
    --remote-host your-proxy.example.com \
    --remote-port 443 \
    --listen-port 10808
```

### 2. 设置代理环境变量

```bash
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export no_proxy="localhost,127.0.0.1,::1,api.deepseek.com,*.deepseek.com,\
*.baidu.com,*.qq.com,*.aliyun.com,*.taobao.com,*.jd.com,*.weixin.qq.com,\
*.zhihu.com,*.bilibili.com,*.tuna.tsinghua.edu.cn,*.ustc.edu.cn,\
10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="$no_proxy"
```

### 3. （可选）配置 git 和 npm

```bash
git config --global http.proxy http://127.0.0.1:10808
npm config set proxy http://127.0.0.1:10808
npm config set https-proxy http://127.0.0.1:10808
```

### 4. 开机自启

把 `bash-integration.sh` 的内容追加到 `~/.bashrc`，或直接运行 `setup.sh` 自动配置。

---

## 参数说明

### 命令行参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--listen-host` | `127.0.0.1` | 本地监听地址 |
| `--listen-port` | `10808` | 本地监听端口 |
| `--remote-host` | **必填** | 远程 HTTPS CONNECT 代理地址 |
| `--remote-port` | `443` | 远程代理端口 |
| `--config` | `""` | JSON 配置文件路径 |

### 配置文件 (`config.json`)

```json
{
  "remote": { "host": "your-proxy.com", "port": 443 },
  "listen": { "host": "127.0.0.1", "port": 10808 },
  "china_ip_list_url": "",
  "direct_domains": ["*.my-corp.com"]
}
```

命令行参数优先级高于配置文件。

---

## 管理命令

```bash
bash ~/.hermes/scripts/proxy-manager.sh status   # 查看运行状态
bash ~/.hermes/scripts/proxy-manager.sh restart  # 重启
bash ~/.hermes/scripts/proxy-manager.sh stop     # 停止
bash ~/.hermes/scripts/proxy-manager.sh start    # 启动
```

---

## DNS 泄漏防护

转发器的路由判定**永远不会进行本地 DNS 解析**：

1. 直连域名白名单 → 无需 DNS
2. 纯 IP 地址 → 查内置中国 IP 段
3. 其他域名 → **默认走代理**，不做本地解析

唯一会离开你机器的 DNS 查询是代理服务器本身（`--remote-host`） —— 一次不可避免的连接。

---

## 项目文件结构

| 文件 | 说明 |
|------|------|
| `proxy-forwarder.py` | 核心转发器（350 行，纯 Python 3 标准库） |
| `proxy-manager.sh` | 管理脚本（start/stop/status） |
| `setup.sh` | 一键安装脚本（复制文件 + 配置 bashrc + 配 git/npm） |
| `bash-integration.sh` | `.bashrc` 集成片段（自动启动 + 环境变量） |
| `config.example.json` | 配置模板 |
| `README.md` | 本文档 |
| `LICENSE` | MIT 开源协议 |

兼容任何 HTTPS CONNECT 代理（Chrome VPN 插件、Squid、Caddy、mitmproxy 等）。

---

## 开源协议

MIT

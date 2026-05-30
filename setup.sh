#!/bin/bash
# ============================================================================
# Smart Proxy Forwarder — One-Click Setup
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORWARDER_SRC="$SCRIPT_DIR/proxy_forwarder.py"
MANAGER_SRC="$SCRIPT_DIR/proxy-manager.sh"

# Detect shell rc file
if [ -n "${ZSH_VERSION:-}" ]; then
    RC_FILE="${ZDOTDIR:-$HOME}/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

# Install directory (XDG-compatible)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/proxy-forwarder"

echo "========================================"
echo "  Smart Proxy Forwarder — Setup"
echo "========================================"
echo "  Config dir: $CONFIG_DIR"
echo "  Shell rc:   $RC_FILE"
echo ""

# ── 1. Copy files ──
echo "[1/5] Installing scripts..."
mkdir -p "$CONFIG_DIR"
cp "$FORWARDER_SRC" "$CONFIG_DIR/proxy_forwarder.py"
cp "$MANAGER_SRC" "$CONFIG_DIR/proxy-manager.sh"
cp "$SCRIPT_DIR/bash-integration.sh" "$CONFIG_DIR/bash-integration.sh"
chmod +x "$CONFIG_DIR/proxy_forwarder.py"
chmod +x "$CONFIG_DIR/proxy-manager.sh"
echo "  → $CONFIG_DIR/proxy_forwarder.py"
echo "  → $CONFIG_DIR/proxy-manager.sh"

# ── 2. Configure remote proxy ──
echo ""
echo "[2/5] Remote proxy server..."
REMOTE_HOST=""
REMOTE_PORT="443"
INSECURE="false"
if [ $# -ge 1 ]; then
    REMOTE_HOST="$1"
    REMOTE_PORT="${2:-443}"
    INSECURE="${3:-false}"
    echo "  Using: $REMOTE_HOST:$REMOTE_PORT (insecure: $INSECURE)"
else
    echo "  ⚠ No proxy host provided."
    echo "  Usage: bash setup.sh <remote-host> [remote-port] [insecure]"
    echo "  Example: bash setup.sh your-proxy.example.com 443 true"
    echo ""
    echo "  Setup will continue without a proxy server."
    echo "  You can set it later by editing:"
    echo "    $CONFIG_DIR/config.json"
fi

cat > "$CONFIG_DIR/config.json" << CONFIGEOF
{
  "remote": { "host": "$REMOTE_HOST", "port": $REMOTE_PORT },
  "listen": { "host": "127.0.0.1", "port": 10808 },
  "insecure": $INSECURE
}
CONFIGEOF
echo "  Config saved to $CONFIG_DIR/config.json"

# ── 3. Add shell integration ──
echo ""
echo "[3/5] Adding shell integration..."
MARKER="# --- Smart Proxy Forwarder ---"
if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
    echo "  Already present in $RC_FILE (skipped)"
else
    cat >> "$RC_FILE" << 'BASHEOF'

# --- Smart Proxy Forwarder ---
PROXY_PORT="${PROXY_PORT:-10808}"
PROXY_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/proxy-forwarder"
PROXY_SCRIPT="$PROXY_CONF_DIR/proxy_forwarder.py"
PROXY_CONFIG="$PROXY_CONF_DIR/config.json"
PROXY_LOG="${PROXY_LOG:-/tmp/proxy-forwarder.log}"

_port_ready() {
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep -q ":$PROXY_PORT "
    elif [ -f /proc/net/tcp ]; then
        local hex=$(printf "%04X" "$PROXY_PORT")
        grep -q ":$hex " /proc/net/tcp 2>/dev/null
    else
        curl -s -o /dev/null --connect-timeout 1 http://127.0.0.1:$PROXY_PORT/ 2>/dev/null
        return $?
    fi
}

_start_proxy_forwarder() {
    if _port_ready; then return 0; fi
    if [ -f "$PROXY_CONFIG" ]; then
        nohup python3 -u "$PROXY_SCRIPT" --config "$PROXY_CONFIG" > "$PROXY_LOG" 2>&1 &
        for i in $(seq 1 10); do
            if _port_ready; then break; fi
            sleep 0.5
        done
    fi
}
if ! pgrep -f "proxy_forwarder.py" >/dev/null 2>&1; then
    _start_proxy_forwarder
fi

export http_proxy=http://127.0.0.1:$PROXY_PORT
export https_proxy=http://127.0.0.1:$PROXY_PORT
export no_proxy="localhost,127.0.0.1,::1,api.deepseek.com,*.deepseek.com,*.baidu.com,*.qq.com,*.aliyun.com,*.taobao.com,*.jd.com,*.weixin.qq.com,*.zhihu.com,*.bilibili.com,*.tuna.tsinghua.edu.cn,*.ustc.edu.cn,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="$no_proxy"
BASHEOF
    echo "  ✓ Appended to $RC_FILE"
fi

# ── 4. Configure git & npm proxy ──
echo ""
echo "[4/5] Configuring git & npm..."
git config --global http.proxy http://127.0.0.1:10808 2>/dev/null && echo "  ✓ git proxy set" || echo "  - git not found, skipping"
npm config set proxy http://127.0.0.1:10808 2>/dev/null && npm config set https-proxy http://127.0.0.1:10808 2>/dev/null && echo "  ✓ npm proxy set" || echo "  - npm not found, skipping"

# ── 5. Install agent-browser (optional) ──
echo ""
echo "[5/5] Optional: agent-browser for AI agents..."
if command -v agent-browser &>/dev/null; then
    echo "  ✓ agent-browser already installed"
else
    echo "  Installing agent-browser (this may take a while)..."
    if npm install -g agent-browser > /tmp/agent-browser-install.log 2>&1; then
        echo "  ✓ agent-browser installed, installing browser..."
        agent-browser install 2>&1 | tail -3 || echo "  ⚠ Browser install skipped (run 'agent-browser install' later)"
    else
        echo "  ⚠ agent-browser install failed (npm issue). You can install later with:"
        echo "    npm install -g agent-browser && agent-browser install"
    fi
fi

# ── Start ──
echo ""
echo "========================================"
echo "  Starting forwarder..."
bash "$CONFIG_DIR/proxy-manager.sh" start

echo ""
echo "  ✅ Setup complete!"
echo "  Config: $CONFIG_DIR"
echo "  Shell:  $RC_FILE"
echo "  Manage: bash $CONFIG_DIR/proxy-manager.sh status"
echo "========================================"

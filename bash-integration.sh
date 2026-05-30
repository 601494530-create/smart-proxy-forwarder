#!/bin/bash
# ============================================================================
# bash-integration.sh — Add to ~/.bashrc or ~/.zshrc
#
# Smart Proxy Forwarder auto-start + env variables.
# After running setup.sh, config lives at ~/.config/proxy-forwarder/config.json
# ============================================================================

# ── Config (override via env vars) ──
PROXY_PORT="${PROXY_PORT:-10808}"
PROXY_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/proxy-forwarder"
PROXY_SCRIPT="$PROXY_CONF_DIR/proxy_forwarder.py"
PROXY_CONFIG="$PROXY_CONF_DIR/config.json"
PROXY_LOG="${PROXY_LOG:-/tmp/proxy-forwarder.log}"

# ── Port check (ss → /proc/net/tcp → curl fallback) ──
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

# ── Auto-start forwarder if not running ──
_start_proxy_forwarder() {
    if _port_ready; then return 0; fi
    if [ -f "$PROXY_CONFIG" ]; then
        nohup python3 -u "$PROXY_SCRIPT" --config "$PROXY_CONFIG" > "$PROXY_LOG" 2>&1 &
        for i in $(seq 1 10); do
            if _port_ready; then break; fi
            sleep 0.5
        done
    else
        echo "proxy-forwarder: no config at $PROXY_CONFIG" >&2
        return 1
    fi
}

if ! pgrep -f "proxy_forwarder.py" >/dev/null 2>&1; then
    _start_proxy_forwarder
fi

# ── Proxy env vars ──
export http_proxy=http://127.0.0.1:$PROXY_PORT
export https_proxy=http://127.0.0.1:$PROXY_PORT

# ── no_proxy: domestic services that should never go through proxy ──
export no_proxy="\
localhost,127.0.0.1,::1,\
api.deepseek.com,*.deepseek.com,\
*.baidu.com,*.qq.com,*.aliyun.com,\
*.taobao.com,*.jd.com,*.weixin.qq.com,\
*.zhihu.com,*.bilibili.com,\
*.tuna.tsinghua.edu.cn,*.ustc.edu.cn,\
10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
export NO_PROXY="$no_proxy"

#!/bin/bash
# ============================================================================
# bash-integration.sh — Add to ~/.bashrc (or source from it)
#
# Smart Proxy Forwarder auto-start + env variables.
# ============================================================================

# ── Paths ──
PROXY_SCRIPT="$HOME/.hermes/scripts/proxy-forwarder.py"
PROXY_LOG="/tmp/proxy-forwarder.log"

# ── Auto-start forwarder if not running ──
_start_proxy_forwarder() {
    if ss -tlnp 2>/dev/null | grep -q ":10808 "; then
        return 0
    fi
    nohup python3 -u "$PROXY_SCRIPT" --remote-host "your-proxy-server.com" \
        --remote-port 443 --listen-port 10808 > "$PROXY_LOG" 2>&1 &
    for i in $(seq 1 10); do
        if ss -tlnp 2>/dev/null | grep -q ":10808 "; then break; fi
        sleep 0.5
    done
}

if ! pgrep -f "proxy-forwarder.py" >/dev/null 2>&1; then
    _start_proxy_forwarder
fi

# ── Proxy env vars ──
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808

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

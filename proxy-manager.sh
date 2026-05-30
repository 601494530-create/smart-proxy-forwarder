#!/bin/bash
# Smart Proxy Forwarder — management script
PORT=10808
LOG_FILE="/tmp/proxy-forwarder.log"

forwarder_pid() {
    pgrep -f "proxy-forwarder.py" | head -1
}

start() {
    local pid=$(forwarder_pid)
    if [ -n "$pid" ]; then
        echo "  Forwarder already running (PID $pid, port $PORT)"
        return 0
    fi
    nohup python3 -u "$HOME/.hermes/scripts/proxy-forwarder.py" \
        --listen-port "$PORT" > "$LOG_FILE" 2>&1 &
    local new_pid=$!
    for i in $(seq 1 10); do
        if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then break; fi
        sleep 0.5
    done
    if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
        echo "  Forwarder started (PID $new_pid, port $PORT)"
    else
        echo "  Start failed, check: $LOG_FILE"
        tail -5 "$LOG_FILE" 2>/dev/null
    fi
}

stop() {
    local pid=$(forwarder_pid)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null
        echo "Stopped (PID $pid)"
    else
        echo "Not running"
    fi
}

status() {
    local pid=$(forwarder_pid)
    if [ -n "$pid" ]; then
        local rss=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
        local mem=$((rss / 1024))
        echo "  Running"
        echo "   PID:   $pid"
        echo "   Port:  $PORT"
        echo "   RAM:   ${mem}MB"
        echo "   Log:   $LOG_FILE"
    else
        echo "  Stopped"
    fi
}

case "${1:-status}" in
    start) start ;;
    stop) stop ;;
    restart) stop; sleep 1; start ;;
    status) status ;;
    *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac

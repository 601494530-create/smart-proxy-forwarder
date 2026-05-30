# Smart Proxy Forwarder — Docker
#
# Build:
#   docker build -t proxy-forwarder .
#
# Run:
#   docker run -d --restart unless-stopped --name proxy \
#     -p 10808:10808 \
#     -v ./config.json:/app/config.json \
#     proxy-forwarder
#
# Or with env vars:
#   docker run -d --restart unless-stopped --name proxy \
#     -p 10808:10808 \
#     -e REMOTE_HOST=your-proxy.com \
#     -e REMOTE_PORT=443 \
#     -e INSECURE=true \
#     proxy-forwarder

FROM python:3.12-alpine

WORKDIR /app

# Copy only what's needed
COPY proxy_forwarder.py .
COPY config.example.json config.json

# Default command (can be overridden)
CMD ["python3", "proxy_forwarder.py", "--config", "config.json"]

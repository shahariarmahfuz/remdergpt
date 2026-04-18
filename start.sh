#!/bin/bash
set -e

PORT=${PORT:-10000}

# Render Health Check এর জন্য ডামি সার্ভার
echo "OK" > /tmp/index.html
cd /tmp && python3 -m http.server $PORT &
cd /home/devuser

SSH_PASS=${SSH_PASS:-"dev123"}
echo "devuser:$SSH_PASS" | chpasswd
echo "root:$SSH_PASS" | chpasswd

service ssh start

# Cloudflare Tunnel চালু করা
if [ -n "$CF_TUNNEL_TOKEN" ]; then
    echo "Starting Cloudflare Tunnel..."
    # টোকেন দিয়ে টানেল রান করানো হচ্ছে
    cloudflared tunnel --no-autoupdate run --token $CF_TUNNEL_TOKEN &
else
    echo "Error: CF_TUNNEL_TOKEN পাওয়া যায়নি!"
fi

tail -f /dev/null

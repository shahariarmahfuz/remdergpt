#!/bin/bash
set -e

# Render Health Check এর জন্য সাধারণ HTTP সার্ভার
PORT=${PORT:-10000}
python3 -m http.server $PORT &

# ইউজারের পাসওয়ার্ড সেট করা (ডিফল্ট: dev123)
# আপনি চাইলে Render এর Environment Variables থেকে SSH_PASS সেট করে দিতে পারেন
SSH_PASS=${SSH_PASS:-"dev123"}
echo "devuser:$SSH_PASS" | chpasswd
echo "root:$SSH_PASS" | chpasswd

# SSH সার্ভার চালু করা
service ssh start

# Ngrok চালু করা (Render এর Environment Variables এ NGROK_AUTHTOKEN দিতে হবে)
if [ -n "$NGROK_AUTHTOKEN" ]; then
    echo "Starting Ngrok TCP tunnel..."
    ngrok config add-authtoken $NGROK_AUTHTOKEN
    # পোর্ট 22 (SSH) এর জন্য TCP টানেল তৈরি
    ngrok tcp 22 --log=stdout > /tmp/ngrok.log &
    
    sleep 5
    echo "=========================================="
    echo "আপনার SSH সার্ভার রেডি! কানেকশন ডিটেইলস জানতে আপনার Ngrok ড্যাশবোর্ডে (Endpoints -> Edges) যান।"
    echo "ইউজারনেম: devuser"
    echo "পাসওয়ার্ড: $SSH_PASS"
    echo "=========================================="
else
    echo "Error: NGROK_AUTHTOKEN পাওয়া যায়নি! টানেল চালু হচ্ছে না।"
fi

tail -f /dev/null

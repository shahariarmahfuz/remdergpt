#!/bin/bash
set -euo pipefail

echo "==> starting container"

mkdir -p /run/sshd
mkdir -p /home/devuser/.ssh
chmod 700 /home/devuser/.ssh

cat > /home/devuser/.ssh/authorized_keys <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDj5xwV9XcOQO/bOhFgufHwucQoisy9GKP0S9E1I6F/z
EOF

chmod 600 /home/devuser/.ssh/authorized_keys
chown -R devuser:devuser /home/devuser/.ssh

ssh-keygen -A

echo "==> devuser info"
getent passwd devuser || true
ls -ld /home/devuser /home/devuser/.ssh || true
ls -l /home/devuser/.ssh || true

echo "==> starting sshd"
/usr/sbin/sshd -D -e &

if [ -n "${NGROK_AUTHTOKEN:-}" ]; then
  echo "==> starting ngrok"
  ngrok config add-authtoken "${NGROK_AUTHTOKEN}" || true
  ngrok tcp 22 --log=stdout &
else
  echo "WARNING: NGROK_AUTHTOKEN is not set"
fi

echo "==> starting health server on PORT=${PORT:-10000}"
exec python3 /healthz.py

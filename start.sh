#!/bin/bash
set -euo pipefail

PORT="${PORT:-10000}"

mkdir -p /home/devuser/.ssh
chmod 700 /home/devuser/.ssh

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /home/devuser/.ssh/authorized_keys
  chmod 600 /home/devuser/.ssh/authorized_keys
  chown devuser:devuser /home/devuser/.ssh/authorized_keys
else
  echo "WARNING: SSH_PUBLIC_KEY is not set"
fi

sudo mkdir -p /var/run/sshd
sudo ssh-keygen -A
sudo /usr/sbin/sshd

python3 /healthz.py &

if [ -n "${NGROK_AUTHTOKEN:-}" ]; then
  ngrok config add-authtoken "${NGROK_AUTHTOKEN}"
  ngrok tcp 22 --log=stdout &
else
  echo "WARNING: NGROK_AUTHTOKEN is not set"
fi

wait -n

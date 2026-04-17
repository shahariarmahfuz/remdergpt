#!/bin/bash
set -euo pipefail

mkdir -p /home/devuser/.ssh
chmod 700 /home/devuser/.ssh

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /home/devuser/.ssh/authorized_keys
  chmod 600 /home/devuser/.ssh/authorized_keys
  chown devuser:devuser /home/devuser/.ssh/authorized_keys
else
  echo "WARNING: SSH_PUBLIC_KEY is not set"
fi

mkdir -p /var/run/sshd
ssh-keygen -A
/usr/sbin/sshd

if [ -n "${NGROK_AUTHTOKEN:-}" ]; then
  (
    ngrok config add-authtoken "${NGROK_AUTHTOKEN}" || true
    ngrok tcp 22 --log=stdout || echo "WARNING: ngrok tunnel failed. Check ngrok dashboard for endpoint/session limits."
  ) &
else
  echo "WARNING: NGROK_AUTHTOKEN is not set"
fi

exec python3 /healthz.py

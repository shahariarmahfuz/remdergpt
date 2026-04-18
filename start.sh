#!/bin/bash
set -euo pipefail

echo "==> starting container"

mkdir -p /run/sshd
mkdir -p /home/devuser/.ssh
chmod 700 /home/devuser/.ssh
touch /home/devuser/.ssh/authorized_keys

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /home/devuser/.ssh/authorized_keys
  chmod 600 /home/devuser/.ssh/authorized_keys
  chown -R devuser:devuser /home/devuser/.ssh
else
  echo "WARNING: SSH_PUBLIC_KEY is not set"
fi

ssh-keygen -A

echo "==> devuser info"
getent passwd devuser || true
ls -ld /home/devuser /home/devuser/.ssh || true
ls -l /home/devuser/.ssh || true

echo "==> sshd effective config"
sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication|challengeresponseauthentication|pubkeyauthentication|usepam|permittty|authorizedkeysfile|allowusers|subsystem'

echo "==> starting sshd"
/usr/sbin/sshd -D -e &
SSHD_PID=$!

if [ -n "${NGROK_AUTHTOKEN:-}" ]; then
  echo "==> starting ngrok"
  ngrok config add-authtoken "${NGROK_AUTHTOKEN}" || true
  ngrok tcp 22 --log=stdout &
else
  echo "WARNING: NGROK_AUTHTOKEN is not set"
fi

echo "==> starting health server on PORT=${PORT:-10000}"
exec python3 /healthz.py

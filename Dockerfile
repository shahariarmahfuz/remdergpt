FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    git \
    nano \
    unzip \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ngrok install
RUN curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && rm -f /tmp/ngrok.zip

# SSH user setup
RUN mkdir -p /run/sshd && \
    useradd -m -s /bin/bash -u 1000 devuser && \
    mkdir -p /home/devuser/.ssh && \
    chown -R devuser:devuser /home/devuser/.ssh && \
    chmod 700 /home/devuser/.ssh && \
    printf '%s\n' \
      'PasswordAuthentication no' \
      'KbdInteractiveAuthentication no' \
      'ChallengeResponseAuthentication no' \
      'PermitRootLogin no' \
      'PubkeyAuthentication yes' \
      'PermitTTY yes' \
      'UsePAM no' \
      >> /etc/ssh/sshd_config

# health check server for Render Web Service
RUN cat > /healthz.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

PORT = int(os.environ.get("PORT", "10000"))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/healthz"):
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok\n")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
PY

# startup script
RUN cat > /start.sh <<'SH'
#!/bin/bash
set -euo pipefail

mkdir -p /run/sshd
mkdir -p /home/devuser/.ssh
chmod 700 /home/devuser/.ssh

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "${SSH_PUBLIC_KEY}" > /home/devuser/.ssh/authorized_keys
  chmod 600 /home/devuser/.ssh/authorized_keys
  chown -R devuser:devuser /home/devuser/.ssh
else
  echo "WARNING: SSH_PUBLIC_KEY is not set"
fi

ssh-keygen -A
/usr/sbin/sshd

if [ -n "${NGROK_AUTHTOKEN:-}" ]; then
  ngrok config add-authtoken "${NGROK_AUTHTOKEN}" || true
  ngrok tcp 22 --log=stdout &
else
  echo "WARNING: NGROK_AUTHTOKEN is not set"
fi

exec python3 /healthz.py
SH

RUN chmod +x /start.sh

WORKDIR /home/devuser
EXPOSE 10000

CMD ["/start.sh"]

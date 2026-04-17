FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

RUN apt-get update && apt-get install -y \
    openssh-server sudo curl wget git nano unzip python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ngrok install
RUN curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && rm -f /tmp/ngrok.zip

# user + ssh setup
RUN mkdir -p /var/run/sshd && \
    useradd -m -s /bin/bash -u 1000 devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/devuser/.ssh && \
    chown -R devuser:devuser /home/devuser/.ssh && \
    chmod 700 /home/devuser/.ssh && \
    printf '%s\n' \
      'PasswordAuthentication no' \
      'KbdInteractiveAuthentication no' \
      'ChallengeResponseAuthentication no' \
      'PermitRootLogin no' \
      'PubkeyAuthentication yes' \
      'UsePAM yes' \
      >> /etc/ssh/sshd_config

# tiny HTTP server for Render health checks
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

RUN cat > /start.sh <<'SH'
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
SH

RUN chmod +x /start.sh

USER devuser
WORKDIR /home/devuser

EXPOSE 10000

CMD ["/start.sh"]

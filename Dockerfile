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

# ngrok
RUN curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && rm -f /tmp/ngrok.zip

# user
RUN useradd -m -d /home/devuser -s /bin/bash -u 1000 devuser \
    && mkdir -p /home/devuser/.ssh /run/sshd \
    && chown -R devuser:devuser /home/devuser \
    && chmod 700 /home/devuser/.ssh

# custom sshd config
RUN cat > /etc/ssh/sshd_config <<'EOF'
Port 22
Protocol 2
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
UsePAM no
PermitTTY yes
X11Forwarding no
PrintMotd no
Subsystem sftp internal-sftp

AuthorizedKeysFile .ssh/authorized_keys
AllowUsers devuser
LogLevel VERBOSE
EOF

# render health server
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

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/devuser
EXPOSE 10000

CMD ["/start.sh"]

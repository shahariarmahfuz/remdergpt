FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update && apt-get install -y \
    curl wget git nano python3 sudo openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Cloudflared ইন্সটল করা
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# SSH কনফিগারেশন আপডেট (লগইন ফাস্ট করার জন্য)
RUN mkdir -p /var/run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "UsePAM no" >> /etc/ssh/sshd_config \
    && echo "UseDNS no" >> /etc/ssh/sshd_config

RUN useradd -m -s /bin/bash -u 1000 devuser \
    && usermod -aG sudo devuser \
    && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/devuser

CMD ["/start.sh"]

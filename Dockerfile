FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# প্রয়োজনীয় প্যাকেজ এবং OpenSSH সার্ভার ইন্সটল
RUN apt-get update && apt-get install -y \
    curl wget git nano python3 sudo openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Ngrok ডাউনলোড ও ইন্সটল
RUN wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz \
    && tar -xvzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin \
    && rm ngrok-v3-stable-linux-amd64.tgz

# SSH এর জন্য ডিরেক্টরি তৈরি এবং কনফিগারেশন
RUN mkdir /var/run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# ইউজার তৈরি (devuser) এবং sudo পারমিশন দেওয়া
RUN useradd -m -s /bin/bash -u 1000 devuser \
    && usermod -aG sudo devuser \
    && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home/devuser

CMD ["/start.sh"]

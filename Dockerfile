FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

# System packages
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    openssl \
    ca-certificates \
    gnupg \
    firefox \
    xubuntu-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && node --version \
    && npm --version

# Dreamchat
WORKDIR /Dreamchat

RUN git clone https://github.com/Airp333/Dreamchat.git . \
    && npm install

# Startup script
RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

echo "Starting VNC..."

mkdir -p /root/.vnc
touch /root/.Xauthority

vncserver -localhost no \
    -SecurityTypes None \
    -geometry 1024x768 \
    --I-KNOW-THIS-IS-INSECURE || true

echo "Starting noVNC..."

openssl req -new \
    -subj "/C=US" \
    -x509 \
    -days 365 \
    -nodes \
    -out /tmp/self.pem \
    -keyout /tmp/self.pem

websockify \
    --web=/usr/share/novnc/ \
    --cert=/tmp/self.pem \
    6080 \
    localhost:5901 &

echo "Starting Dreamchat..."

cd /Dreamchat
exec node index.js
EOF

RUN chmod +x /start.sh

# Dreamchat
EXPOSE 8080

# noVNC
EXPOSE 6080

CMD ["/start.sh"]

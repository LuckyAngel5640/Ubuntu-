FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production

RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    nginx \
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

echo "=== Starting VNC ==="

mkdir -p /root/.vnc
touch /root/.Xauthority

vncserver \
    -localhost no \
    -SecurityTypes None \
    -geometry 1024x768 \
    --I-KNOW-THIS-IS-INSECURE || true

echo "=== Starting noVNC ==="

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

echo "=== Starting Dreamchat on port 3000 ==="

cd /Dreamchat
PORT=3000 node index.js &

echo "=== Configuring nginx ==="

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 8080 default_server;
    server_name ubuntu-production-dab0.up.railway.app;

    location / {
        proxy_pass http://127.0.0.1:6080;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 8080;
    server_name dreamcast.cam;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

echo "=== Starting nginx ==="

exec nginx -g "daemon off;"
EOF

RUN chmod +x /start.sh

EXPOSE 8080
EXPOSE 6080

CMD ["/start.sh"]

FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install --no-install-recommends -y nodejs npm git
RUN apt update -y && apt install -y curl wget
EXPOSE 6080

RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting Dreamchat application..."
cd /Dreamchat
npm install
node index.js
EOF

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]


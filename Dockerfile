FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt install --no-install-recommends -y xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify sudo xterm init systemd snapd vim net-tools curl wget git tzdata openssh-server openssh-client
RUN apt update -y && apt install -y dbus-x11 x11-utils x11-xserver-utils x11-apps
RUN apt install software-properties-common -y
RUN add-apt-repository ppa:mozillateam/ppa -y
RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: \"LP-PPA-mozillateam:jammy\";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
RUN apt update -y && apt install -y firefox
RUN apt update -y && apt install -y xubuntu-icon-theme
RUN touch /root/.Xauthority
RUN mkdir -p /run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
EXPOSE 5901
EXPOSE 6080
EXPOSE 22

RUN mkdir -p /startup && cat > /startup/start.sh << 'EOF'
#!/bin/bash
set -e

# Start SSH
echo "Starting SSH..."
service ssh start

# Start VNC
echo "Starting VNC server..."
vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE :1

# Generate SSL cert
echo "Generating SSL certificate..."
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /tmp/self.pem -keyout /tmp/self.pem

# Start websockify
echo "Starting websockify on port 6080..."
websockify --web=/usr/share/novnc/ --cert=/tmp/self.pem 6080 localhost:5901

EOF

RUN chmod +x /startup/start.sh

CMD ["/startup/start.sh"]


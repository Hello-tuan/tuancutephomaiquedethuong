FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Thêm i386 cho wine32
RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y --no-install-recommends \
    # === Quan trọng nhất ===
    xrdp \
    xorgxrdp \
    # Desktop
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xorg \
    dbus-x11 \
    # Tools
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    policykit-1 \
    ca-certificates \
    locales \
    # Audio
    pulseaudio \
    pulseaudio-utils \
    # Wine
    wine \
    wine32 \
    # Browser
    firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Tạo user thường (khuyến nghị)
RUN useradd -m -s /bin/bash tuan && \
    echo "tuan:tuan123" | chpasswd && \
    usermod -aG sudo tuan

# Mật khẩu root (nếu cần)
RUN echo "root:root" | chpasswd

# Cho phép mọi user chạy X
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Cấu hình session XFCE
RUN echo "#!/bin/sh\nexec startxfce4" > /root/.xsession && chmod +x /root/.xsession && \
    echo "#!/bin/sh\nexec startxfce4" > /home/tuan/.xsession && \
    chown tuan:tuan /home/tuan/.xsession && chmod +x /home/tuan/.xsession

# Machine-id dbus
RUN mkdir -p /var/run/dbus /var/lib/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# Cấu hình XRDP
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini

# startwm.sh chuẩn (rất quan trọng)
RUN cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

exec startxfce4
EOF

RUN chmod +x /etc/xrdp/startwm.sh

# Thêm user xrdp vào group
RUN adduser xrdp ssl-cert || true

# Copy file cấu hình
COPY pulse-client.conf /etc/pulse/client.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]

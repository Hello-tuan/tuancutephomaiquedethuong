FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Thêm kiến trúc i386
RUN dpkg --add-architecture i386

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Desktop
    xrdp \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    xorg \
    dbus-x11 \
    # Tools
    sudo curl wget nano net-tools \
    policykit-1 \
    ca-certificates \
    locales \
    # Audio
    pulseaudio pulseaudio-utils \
    # Wine
    wine wine32 \
    # Browser
    firefox-esr \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Tạo user thường (khuyên dùng thay vì root)
RUN useradd -m -s /bin/bash tuan && \
    echo "tuan:tuan123" | chpasswd && \
    usermod -aG sudo tuan

# Mật khẩu root (nếu vẫn muốn dùng)
RUN echo "root:root" | chpasswd

# Cấu hình Xwrapper
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || \
    echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

# Cấu hình session cho cả root và user tuan
RUN echo "startxfce4" > /root/.xsession && chmod 700 /root/.xsession && \
    echo "startxfce4" > /home/tuan/.xsession && \
    chown tuan:tuan /home/tuan/.xsession && \
    chmod 700 /home/tuan/.xsession

# Machine-id cho dbus
RUN mkdir -p /var/run/dbus /var/lib/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# Cấu hình XRDP quan trọng (chống màn hình xanh)
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini

# File startwm.sh chuẩn (rất quan trọng)
RUN cat > /etc/xrdp/startwm.sh << 'EOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi

# Fix XDG
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start XFCE
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

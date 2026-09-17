FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Thêm kiến trúc i386 để cài wine32
RUN dpkg --add-architecture i386

# Cài đặt các package cần thiết
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Desktop & XRDP
    xrdp \
    xfce4 \
    xfce4-goodies \
    xorg \
    dbus-x11 \
    # Tools cơ bản
    sudo \
    curl \
    wget \
    nano \
    net-tools \
    policykit-1 \
    # Audio
    pulseaudio \
    pulseaudio-utils \
    # Wine (32-bit + 64-bit)
    wine \
    wine32 \
    # Browser
    firefox-esr \
    # Dependencies bổ sung thường thiếu
    ca-certificates \
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Đặt mật khẩu root (đổi lại nếu cần)
RUN echo "root:root" | chpasswd

# Cho phép bất kỳ user nào chạy X
RUN sed -i 's/^allowed_users=.*/allowed_users=anybody/' /etc/X11/Xwrapper.config || \
    echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config

# Cấu hình session XFCE
RUN echo "startxfce4" > /root/.xsession && chmod 700 /root/.xsession

# Tạo machine-id cho dbus
RUN mkdir -p /var/run/dbus /var/lib/dbus && \
    dbus-uuidgen > /var/lib/dbus/machine-id

# Cấu hình XRDP (giảm security để dễ kết nối)
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    echo "exec startxfce4" > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Thêm user xrdp vào group ssl-cert
RUN adduser xrdp ssl-cert || true

# Copy file cấu hình PulseAudio (nếu có)
COPY pulse-client.conf /etc/pulse/client.conf

# Copy và cấp quyền script khởi động
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]

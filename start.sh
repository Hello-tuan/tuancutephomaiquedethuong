#!/bin/bash

# Khởi động dbus
service dbus start 2>/dev/null || true

# Tạo thư mục X11
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Khởi động PulseAudio (nếu cần)
pulseaudio --start --system --disallow-exit --disable-shm 2>/dev/null || true

# Khởi động sesman trước
/usr/sbin/xrdp-sesman

# Khởi động xrdp
/usr/sbin/xrdp

# Giữ container sống
tail -f /var/log/xrdp-sesman.log

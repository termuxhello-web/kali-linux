#!/usr/bin/env bash
# install_kex.sh — Script cài đặt và cấu hình NetHunter KeX tự chế (Termux)
# Dùng: bash install_kex.sh

set -e

DISTRO_NAME="${DISTRO_NAME:-kali}"

echo "[1/4] Cài gói cần thiết trong Termux..."
pkg update -y
pkg install -y proot-distro

echo "[2/4] Cài đặt Kali Linux nếu chưa có..."
if ! proot-distro list | grep -q "^${DISTRO_NAME}\b"; then
  proot-distro install ${DISTRO_NAME}
else
  echo "Đã có ${DISTRO_NAME}, bỏ qua bước cài."
fi

echo "[3/4] Cài KeX server trong Kali..."
proot-distro login ${DISTRO_NAME} -- bash -lc '
  set -e
  apt update && apt upgrade -y
  apt install -y kali-linux-core tightvncserver novnc dbus-x11 xfce4 xfce4-goodies
  mkdir -p $HOME/.vnc
  cat > $HOME/.vnc/xstartup << "EOF"
#!/bin/sh
xrdb $HOME/.Xresources
startxfce4 &
EOF
  chmod +x $HOME/.vnc/xstartup

  # script start/stop KeX
  install -Dm755 /dev/stdin /usr/local/bin/kex-start << "EOS"
#!/usr/bin/env bash
vncserver -kill :1 >/dev/null 2>&1 || true
vncserver :1 -geometry 1920x1080 -depth 24 -localhost
echo "KeX server chạy tại :1 (port 5901)."
EOS

  install -Dm755 /dev/stdin /usr/local/bin/kex-stop << "EOS"
#!/usr/bin/env bash
vncserver -kill :1 || true
EOS
'

echo "[4/4] Tạo file tools quản lý..."
cat > $HOME/tools << 'EOF'
#!/usr/bin/env bash
# tools — tiện ích quản lý KeX (VNC) trong Kali proot
DISTRO="${DISTRO_NAME:-kali}"

case "$1" in
  start)  proot-distro login "$DISTRO" -- bash -lc "kex-start" ;;
  stop)   proot-distro login "$DISTRO" -- bash -lc "kex-stop" ;;
  passwd) proot-distro login "$DISTRO" -- bash -lc "vncpasswd" ;;
  status) proot-distro login "$DISTRO" -- bash -lc "pgrep -a Xtightvnc || echo 'KeX chưa chạy'" ;;
  login)  proot-distro login "$DISTRO" ;;
  *) echo "Dùng: tools {start|stop|passwd|status|login}" ;;
esac
EOF

chmod +x $HOME/tools
echo "XONG! Dùng './tools start' để bật KeX, './tools stop' để tắt."

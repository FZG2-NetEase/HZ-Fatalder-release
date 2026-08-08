#!/data/data/com.termux/files/usr/bin/sh
# Termux 安装脚本：将 Fatalder 注册为全局 fatalder 命令。
set -eu

MIRROR='https://mirrors.tuna.tsinghua.edu.cn/termux/termux-main'
INSTALL_DIR="$PREFIX/libexec/fatalder"
BINARY="$INSTALL_DIR/Fatalder-cli_linux_arm64"
LAUNCHER="$PREFIX/bin/fatalder.sh"
COMMAND="$PREFIX/bin/fatalder"
DOWNLOAD_URL='https://github.yuansi.xyz/https://raw.githubusercontent.com/FZG2-NetEase/HZ-Fatalder-release/main/Fatalder-cli_linux_arm64'

# 已安装时不重复下载，直接启动本地程序。
if [ -x "$BINARY" ]; then
    exec "$COMMAND" "$@"
fi

printf '%s\n' "deb $MIRROR stable main" > "$PREFIX/etc/apt/sources.list"
pkg update -y
pkg install -y curl

mkdir -p "$INSTALL_DIR"
curl -fL --retry 3 -o "$BINARY" "$DOWNLOAD_URL"
chmod 755 "$BINARY"

cat > "$LAUNCHER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# 使用 Termux 系统默认 CA 证书；可在启动前自行设置 GODEBUG。
set -eu
export GODEBUG="${GODEBUG:-}"
exec "$PREFIX/libexec/fatalder/Fatalder-cli_linux_arm64" "$@"
EOF

cat > "$COMMAND" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec "$PREFIX/bin/fatalder.sh" "$@"
EOF

chmod 755 "$LAUNCHER" "$COMMAND"
exec "$COMMAND" "$@"

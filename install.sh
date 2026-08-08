#!/data/data/com.termux/files/usr/bin/sh
# Termux 安装脚本：将 Fatalder 注册为全局 fatalder 命令。
set -eu

MIRROR='https://mirrors.tuna.tsinghua.edu.cn/termux/termux-main'
INSTALL_DIR="$PREFIX/libexec/fatalder"
BINARY="$INSTALL_DIR/Fatalder-cli_linux_arm64"
LAUNCHER="$PREFIX/bin/fatalder.sh"
COMMAND="$PREFIX/bin/fatalder"
DOWNLOAD_URL='https://github.180280.xyz/https://raw.githubusercontent.com/FZG2-NetEase/HZ-Fatalder-release/main/Fatalder-cli_linux_arm64'
APT_DIR="$PREFIX/etc/apt"

# 只保留清华源，避免 Termux 其他仓库配置触发逐个测速。
mkdir -p "$APT_DIR/sources.list.d"
printf '%s\n' "deb $MIRROR stable main" > "$APT_DIR/sources.list"
for source_file in "$APT_DIR"/sources.list.d/*.list "$APT_DIR"/sources.list.d/*.sources; do
    [ -e "$source_file" ] || continue
    mv "$source_file" "$source_file.disabled"
done

pkg update -y
pkg install -y ca-certificates curl
update-ca-certificates >/dev/null 2>&1 || true

if [ ! -x "$BINARY" ]; then
    mkdir -p "$INSTALL_DIR"
    curl -fL --retry 3 -o "$BINARY" "$DOWNLOAD_URL"
    chmod 755 "$BINARY"
fi

cat > "$LAUNCHER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# Termux 的 CA 路径不会被所有 Go 版本自动识别，这里显式指定证书包。
set -eu
export LANG="${LANG:-zh_CN.UTF-8}"
export LC_ALL="${LC_ALL:-zh_CN.UTF-8}"
export LANGUAGE="${LANGUAGE:-zh_CN:zh}"
if [ -f "$PREFIX/etc/tls/cert.pem" ]; then
    export SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem"
elif [ -f "$PREFIX/etc/ssl/certs/ca-certificates.crt" ]; then
    export SSL_CERT_FILE="$PREFIX/etc/ssl/certs/ca-certificates.crt"
fi
if [ -d "$PREFIX/etc/tls" ]; then
    export SSL_CERT_DIR="$PREFIX/etc/tls"
fi
exec "$PREFIX/libexec/fatalder/Fatalder-cli_linux_arm64" "$@"
EOF

cat > "$COMMAND" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec "$PREFIX/bin/fatalder.sh" "$@"
EOF

chmod 755 "$LAUNCHER" "$COMMAND"
exec "$COMMAND" "$@"

#!/data/data/com.termux/files/usr/bin/sh
# Termux 安装脚本：将 Fatalder 注册为全局 fatalder 命令。
set -eu

MIRROR='https://mirrors.tuna.tsinghua.edu.cn/termux/termux-main'
INSTALL_DIR="$PREFIX/libexec/fatalder"
BINARY="$INSTALL_DIR/Fatalder-cli_linux_arm64"
COMMIT_FILE="$INSTALL_DIR/.commit"
LAUNCHER="$PREFIX/bin/fatalder.sh"
COMMAND="$PREFIX/bin/fatalder"
REPOSITORY='FZG2-NetEase/HZ-Fatalder-release'
BRANCH='main'
GITHUB_PROXY='https://hub.ilatency.com/'
DOWNLOAD_URL="${GITHUB_PROXY}https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}/Fatalder-cli_linux_arm64"
COMMIT_API_URL="${GITHUB_PROXY}https://api.github.com/repos/${REPOSITORY}/commits/${BRANCH}"
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

# 从 GitHub API 获取目标分支最新提交；无本地记录时一律重新安装。
if ! latest_commit="$(curl -fsSL --retry 3 "$COMMIT_API_URL" | sed -n 's/^[[:space:]]*"sha"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{40\}\)".*/\1/p' | head -n 1)"; then
    echo "无法获取最新版本提交信息。" >&2
    exit 1
fi
if [ -z "$latest_commit" ]; then
    echo "GitHub API 返回中未找到提交信息。" >&2
    exit 1
fi

installed_commit=''
if [ -f "$COMMIT_FILE" ]; then
    installed_commit="$(tr -d '\r\n' < "$COMMIT_FILE")"
fi

if [ ! -x "$BINARY" ] || [ "$installed_commit" != "$latest_commit" ]; then
    mkdir -p "$INSTALL_DIR"
    # 更新前删除旧二进制和提交记录，避免旧文件干扰下载或版本判断。
    rm -f "$BINARY" "$COMMIT_FILE"
    curl -fL --retry 3 -o "$BINARY" "$DOWNLOAD_URL"
    chmod 755 "$BINARY"
    printf '%s\n' "$latest_commit" > "$COMMIT_FILE"
fi

cat > "$LAUNCHER" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# Termux 的 CA 路径不会被所有 Go 版本自动识别，这里显式指定证书包。
set -eu
export LANG="${LANG:-zh_CN.UTF-8}"
export LC_ALL="${LC_ALL:-zh_CN.UTF-8}"
export LANGUAGE="${LANGUAGE:-zh_CN:zh}"
# 让 Go 使用自身 DNS 解析器，避免 Android/Termux 的系统解析兼容问题。
export GODEBUG="netdns=go"
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

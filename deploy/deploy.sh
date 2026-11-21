#!/usr/bin/env bash
# 用法: bash deploy.sh [user@host]   默认 root@81.70.239.202 (deepsong.top)
# 将 deepsong-site.tar.gz 上传并替换 nginx 站点根目录内容（旧内容自动备份，可回滚）
set -euo pipefail
HOST="${1:-root@81.70.239.202}"
DIR="$(cd "$(dirname "$0")" && pwd)"

scp "$DIR/deepsong-site.tar.gz" "$HOST:/tmp/deepsong-site.tar.gz"

ssh "$HOST" 'bash -s' <<'EOF'
set -euo pipefail
CONF="$(grep -rl 'server_name[^;]*deepsong\.top' /etc/nginx/ 2>/dev/null || true)"
ROOT=""
for f in $CONF; do
  ROOT="$(sed -nE 's/^[[:space:]]*root[[:space:]]+([^;]+);.*/\1/p' "$f" | head -1)"
  [ -n "$ROOT" ] && break
done
ROOT="${ROOT:-/usr/share/nginx/html}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/deepsong/site-$STAMP"
mkdir -p "$BACKUP" /tmp/deepsong-new
tar -xzf /tmp/deepsong-site.tar.gz -C /tmp/deepsong-new
find "$ROOT" -mindepth 1 -maxdepth 1 -exec mv {} "$BACKUP"/ \;
cp -a /tmp/deepsong-new/. "$ROOT"/
rm -rf /tmp/deepsong-new /tmp/deepsong-site.tar.gz
nginx -t
nginx -s reload
echo "DEPLOYED to $ROOT (old content backed up at $BACKUP)"
EOF
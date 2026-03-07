#!/bin/bash
# =================================================================
# migrate.sh — Миграция XHTTP → WebSocket+TLS
# Использование: bash migrate.sh
# =================================================================

set -e

CONFIG_PATH='/usr/local/etc/xray/config.json'
NGINX_PATH='/etc/nginx/conf.d/xray.conf'

red=$(tput setaf 1 && tput bold 2>/dev/null || echo "")
green=$(tput setaf 2 && tput bold 2>/dev/null || echo "")
cyan=$(tput setaf 6 && tput bold 2>/dev/null || echo "")
yellow=$(tput setaf 3 && tput bold 2>/dev/null || echo "")
reset=$(tput sgr0 2>/dev/null || echo "")

echo -e "${cyan}================================================================${reset}"
echo -e "   VWN — Migrate XHTTP → WebSocket+TLS"
echo -e "${cyan}================================================================${reset}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "${red}Run as root!${reset}"; exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo "${red}Xray config not found: $CONFIG_PATH${reset}"
    echo "Nothing to migrate."
    exit 0
fi

# Определяем тип сети
network=$(jq -r '.inbounds[0].streamSettings.network // ""' "$CONFIG_PATH" 2>/dev/null)

if [ "$network" = "ws" ]; then
    echo "${green}Already WebSocket — nothing to migrate.${reset}"
    exit 0
fi

if [ "$network" != "xhttp" ]; then
    echo "${yellow}Unknown network type: '$network' — skipping.${reset}"
    exit 0
fi

echo "Detected: XHTTP config. Migrating to WebSocket..."
echo ""

# Бэкап
backup_file="/root/vwn-pre-migrate-$(date '+%Y-%m-%d_%H-%M-%S').tar.gz"
echo -n "Creating backup: $backup_file ... "
tar -czf "$backup_file" "$CONFIG_PATH" "$NGINX_PATH" /etc/nginx/cert 2>/dev/null || true
echo "${green}OK${reset}"

# Читаем параметры из XHTTP конфига
xhttp_path=$(jq -r '.inbounds[0].streamSettings.xhttpSettings.path // "/"' "$CONFIG_PATH" 2>/dev/null)
xray_port=$(jq -r '.inbounds[0].port' "$CONFIG_PATH" 2>/dev/null)
domain=$(jq -r '.inbounds[0].streamSettings.xhttpSettings.host // ""' "$CONFIG_PATH" 2>/dev/null)

# Fallback: читаем домен из nginx если не было в конфиге
if [ -z "$domain" ] && [ -f "$NGINX_PATH" ]; then
    domain=$(grep -E '^\s*server_name\s+' "$NGINX_PATH" 2>/dev/null \
        | grep -v 'server_name\s*_;' \
        | awk '{print $2}' | tr -d ';' | grep -v '^_$' | head -1)
fi

echo "  Path:   $xhttp_path"
echo "  Port:   $xray_port"
echo "  Domain: ${domain:-unknown}"
echo ""

# ── Миграция Xray конфига ─────────────────────────────────────────
echo -n "Migrating Xray config (xhttpSettings → wsSettings + sockopt)... "

jq --arg path "$xhttp_path" --arg domain "$domain" '
    .inbounds[0].streamSettings = {
        "network": "ws",
        "wsSettings": {
            "path": $path,
            "host": $domain,
            "heartbeatPeriod": 30
        },
        "sockopt": {
            "tcpKeepAliveIdle": 100,
            "tcpKeepAliveInterval": 10,
            "tcpKeepAliveRetry": 3
        }
    }
' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"

echo "${green}OK${reset}"

# ── Миграция Nginx конфига ────────────────────────────────────────
echo -n "Migrating Nginx config (adding WS headers, removing http2, fixing timeouts)... "

python3 - "$NGINX_PATH" "$xray_port" << 'PYEOF'
import sys, re

path = sys.argv[1]
port = sys.argv[2]

with open(path, 'r') as f:
    content = f.read()

# Убираем http2 из listen директивы
content = re.sub(r'listen 443 ssl http2;', 'listen 443 ssl;', content)

# Убираем xhttp-специфичные строки
lines_to_remove = [
    r'\s*proxy_cache off;\s*\n',
    r'\s*chunked_transfer_encoding on;\s*\n',
    r'\s*proxy_buffer_size \S+;\s*\n',
]
for pattern in lines_to_remove:
    content = re.sub(pattern, '\n', content)

# Заменяем таймауты на большие (3600s для WS)
content = re.sub(r'proxy_read_timeout \S+;', 'proxy_read_timeout 3600s;', content)
content = re.sub(r'proxy_send_timeout \S+;', 'proxy_send_timeout 3600s;', content)

# Добавляем WS заголовки если нет
ws_location_pattern = r'(location \S+ \{[^}]*proxy_pass http://127\.0\.0\.1:' + port + r'[^}]*?)(proxy_set_header Host)'
if 'proxy_set_header Upgrade' not in content:
    ws_headers = (
        '        proxy_set_header Upgrade $http_upgrade;\n'
        '        proxy_set_header Connection "upgrade";\n'
        '        '
    )
    content = re.sub(ws_location_pattern, r'\1' + ws_headers + r'\2', content, flags=re.DOTALL)

# Добавляем proxy_socket_keepalive если нет
if 'proxy_socket_keepalive' not in content:
    content = re.sub(
        r'(proxy_request_buffering off;)',
        r'\1\n        proxy_socket_keepalive on;',
        content
    )

with open(path, 'w') as f:
    f.write(content)
PYEOF

echo "${green}OK${reset}"

# ── Проверка ──────────────────────────────────────────────────────
echo -n "Testing Xray config... "
if /usr/local/bin/xray -test -config "$CONFIG_PATH" &>/dev/null; then
    echo "${green}OK${reset}"
else
    echo "${red}FAIL${reset}"
    /usr/local/bin/xray -test -config "$CONFIG_PATH"
    echo ""
    echo "${red}Migration failed. Restoring from backup...${reset}"
    tar -xzf "$backup_file" -C / 2>/dev/null
    exit 1
fi

echo -n "Testing Nginx config... "
if nginx -t &>/dev/null; then
    echo "${green}OK${reset}"
else
    echo "${yellow}WARNING — check nginx config manually${reset}"
    nginx -t
fi

echo -n "Restarting services... "
systemctl restart xray nginx 2>/dev/null || true
echo "${green}OK${reset}"

echo ""
echo -e "${cyan}================================================================${reset}"
echo -e "   ${green}Migration complete!${reset}"
echo -e "   Backup saved: $backup_file"
echo -e ""
echo -e "   Update your clients — use type=ws instead of type=xhttp"
echo -e "   Run 'vwn' → item 2 to get new QR codes"
echo -e "${cyan}================================================================${reset}"

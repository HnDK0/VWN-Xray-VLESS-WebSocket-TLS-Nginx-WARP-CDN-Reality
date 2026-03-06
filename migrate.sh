#!/bin/bash
# =================================================================
# migrate.sh — Одноразовая миграция VLESS+WS → VLESS+XHTTP
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
echo -e "   VWN — Migrate VLESS+WS → VLESS+XHTTP"
echo -e "${cyan}================================================================${reset}"
echo ""

# Проверяем root
if [ "$EUID" -ne 0 ]; then
    echo "${red}Run as root!${reset}"; exit 1
fi

# Проверяем что конфиг существует
if [ ! -f "$CONFIG_PATH" ]; then
    echo "${red}Xray config not found: $CONFIG_PATH${reset}"
    echo "Nothing to migrate."
    exit 0
fi

# Проверяем что это WS конфиг (а не уже XHTTP)
network=$(jq -r '.inbounds[0].streamSettings.network // ""' "$CONFIG_PATH" 2>/dev/null)
if [ "$network" = "xhttp" ]; then
    echo "${green}Already XHTTP — nothing to migrate.${reset}"
    exit 0
fi

if [ "$network" != "ws" ]; then
    echo "${yellow}Unknown network type: '$network' — skipping.${reset}"
    exit 0
fi

echo "Detected: VLESS+WS config. Starting migration..."
echo ""

# Бэкап перед миграцией
backup_file="/root/vwn-pre-migrate-$(date '+%Y-%m-%d_%H-%M-%S').tar.gz"
echo -n "Creating backup: $backup_file ... "
tar -czf "$backup_file" "$CONFIG_PATH" "$NGINX_PATH" /etc/nginx/cert 2>/dev/null || true
echo "${green}OK${reset}"

# Читаем текущие параметры из WS конфига
ws_path=$(jq -r '.inbounds[0].streamSettings.wsSettings.path // "/"' "$CONFIG_PATH" 2>/dev/null)
xray_port=$(jq -r '.inbounds[0].port' "$CONFIG_PATH" 2>/dev/null)

# Читаем домен из nginx
domain=$(grep -E '^\s*server_name\s+' "$NGINX_PATH" 2>/dev/null \
    | grep -v 'proxy_ssl' \
    | grep -v 'server_name\s*_;' \
    | awk '{print $2}' | tr -d ';' | grep -v '^_$' | head -1)

echo "  Path:   $ws_path"
echo "  Port:   $xray_port"
echo "  Domain: ${domain:-unknown}"
echo ""

# ── Миграция Xray конфига ─────────────────────────────────────────
echo -n "Migrating Xray config (wsSettings → xhttpSettings)... "

jq --arg path "$ws_path" --arg domain "$domain" '
    .inbounds[0].streamSettings = {
        "network": "xhttp",
        "xhttpSettings": {
            "path": $path,
            "host": $domain
        }
    }
' "$CONFIG_PATH" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"

echo "${green}OK${reset}"

# ── Миграция Nginx конфига ────────────────────────────────────────
echo -n "Migrating Nginx config (removing WS headers)... "

python3 - "$NGINX_PATH" << 'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Убираем WebSocket-специфичные строки
lines_to_remove = [
    r'\s*if \(\$http_upgrade != "websocket"\) \{ return 404; \}\n?',
    r'\s*proxy_set_header Upgrade \$http_upgrade;\n?',
    r'\s*proxy_set_header Connection "upgrade";\n?',
]
for pattern in lines_to_remove:
    content = re.sub(pattern, '', content)

# Добавляем proxy_cache off после proxy_buffering off если ещё нет
if 'proxy_cache off' not in content:
    content = content.replace(
        'proxy_buffering off;',
        'proxy_buffering off;\n    proxy_cache off;'
    )

with open(path, 'w') as f:
    f.write(content)
PYEOF

echo "${green}OK${reset}"

# ── Проверка и перезапуск ─────────────────────────────────────────
echo -n "Testing Xray config... "
if /usr/local/bin/xray -test -config "$CONFIG_PATH" &>/dev/null; then
    echo "${green}OK${reset}"
else
    echo "${red}FAIL${reset}"
    echo ""
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
fi

echo -n "Restarting services... "
systemctl restart xray nginx 2>/dev/null || true
echo "${green}OK${reset}"

echo ""
echo -e "${cyan}================================================================${reset}"
echo -e "   ${green}Migration complete!${reset}"
echo -e "   Backup saved: $backup_file"
echo -e ""
echo -e "   Update your clients — use type=xhttp instead of type=ws"
echo -e "   Run 'vwn' → item 2 to get new QR codes"
echo -e "${cyan}================================================================${reset}"

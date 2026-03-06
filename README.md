<details open>
<summary>🇬🇧 English</summary>

# VWN — Xray VLESS + WARP + CDN + Reality

Automated installer for Xray VLESS with XHTTP+TLS, Reality, Cloudflare WARP, CDN, Relay, Psiphon, and Tor support.

## Quick Install

```bash
curl -L https://raw.githubusercontent.com/HnDK0/VLESS-WebSocket-TLS-Nginx-WARP/main/install.sh -o vwn && bash vwn
```

After installation the script is available as a command:
```bash
vwn
```

Update modules (without touching configs):
```bash
vwn update
```

## Requirements

- Ubuntu 22.04+ / Debian 11+
- Root access
- A domain pointed at the server (for XHTTP+TLS)
- For Reality — only the server IP is needed, no domain required

## Features

- ✅ **VLESS + XHTTP + TLS** — connections via Cloudflare CDN
- ✅ **VLESS + Reality** — direct connections without CDN (router, Clash)
- ✅ **Nginx** — reverse proxy with a stub/decoy site
- ✅ **Cloudflare WARP** — route selected domains or all traffic
- ✅ **Psiphon** — censorship bypass with exit country selection
- ✅ **Tor** — censorship bypass with exit country selection, bridge support (obfs4, snowflake, meek)
- ✅ **Relay** — external outbound (VLESS/VMess/Trojan/SOCKS via link)
- ✅ **CDN protection** — blocks direct access, only via Cloudflare
- ✅ **Multi-user** — multiple UUIDs with labels, individual QR codes
- ✅ **Backup & Restore** — manual backup/restore of all configs
- ✅ **Diagnostics** — full system check with per-component breakdown
- ✅ **WARP Watchdog** — auto-reconnect WARP on failure
- ✅ **Fail2Ban + Web-Jail** — brute-force and scanner protection
- ✅ **BBR** — TCP acceleration
- ✅ **Anti-Ping** — ICMP disabled
- ✅ **IPv6 disabled system-wide** — forced IPv4
- ✅ **Privacy** — access logs off, sniffing disabled
- ✅ **RU / EN interface** — language selector on first run

## Architecture

```
Client (CDN/mobile)
    └── Cloudflare CDN → 443/HTTPS → Nginx → VLESS+XHTTP → Xray → outbound

Client (router/Clash/direct)
    └── IP:8443/TCP → VLESS+Reality → Xray → outbound

outbound (by routing rules):
    ├── free    — direct exit (default)
    ├── warp    — Cloudflare WARP (SOCKS5:40000)
    ├── psiphon — Psiphon tunnel (SOCKS5:40002)
    ├── tor     — Tor (SOCKS5:40003)
    ├── relay   — external server (vless/vmess/trojan/socks)
    └── block   — blackhole (geoip:private)
```

## Ports

| Port  | Purpose                           |
|-------|-----------------------------------|
| 22    | SSH (configurable)                |
| 443   | VLESS+XHTTP+TLS via Nginx         |
| 8443  | VLESS+Reality (default)           |
| 40000 | WARP SOCKS5 (warp-cli, local)     |
| 40002 | Psiphon SOCKS5 (local)            |
| 40003 | Tor SOCKS5 (local)                |
| 40004 | Tor Control Port (local)          |

## CLI Commands

```bash
vwn                # Open interactive menu
vwn update         # Update modules (no config changes)
vwn status         # Run full diagnostics (no menu)
vwn backup         # Create backup immediately
vwn restore        # Restore from backup (interactive)
vwn qr             # Show QR codes (no menu)
```

## Menu

```
================================================================
   XRAY VLESS + WARP + CDN + REALITY | 27.02.2026 21:00
================================================================
  NGINX: RUNNING  |  XRAY: RUNNING  |  WARP: ACTIVE | Split
  SSL: OK (89 d)  |  BBR: ON  |  F2B: OFF
  WebJail: NO  |  CDN: OFF  |  Reality: ON (port 8443)
  Relay: ON | Split  |  Psiphon: ON | Split, DE  |  Tor: ON | Split, US
----------------------------------------------------------------
    1.  Install Xray (VLESS+XHTTP+TLS+WARP+CDN)
    2.  Show QR code and link
    3.  Change UUID
    --- Configuration ---
    4.  Change Xray port
    5.  Change XHTTP path
    6.  Change stub site
    7.  Reissue SSL certificate
    8.  Change domain
    --- CDN & WARP ---
    9.  Toggle CDN mode (ON/OFF)
    10. Toggle WARP mode (Global/Split/OFF)
    11. Add domain to WARP
    12. Remove domain from WARP
    13. Edit WARP list (Nano)
    14. Check IP (Real vs WARP)
    --- Security ---
    15. Enable BBR
    16. Enable Fail2Ban
    17. Enable Web-Jail
    18. Change SSH port
    30. Install WARP Watchdog
    --- Logs ---
    19. Xray logs (access)
    20. Xray logs (error)
    21. Nginx logs (access)
    22. Nginx logs (error)
    23. Clear all logs
    --- Services ---
    24. Restart all services
    25. Update Xray-core
    26. Full removal
    --- UFW, SSL, Logs ---
    27. Manage UFW
    28. Manage SSL auto-renewal
    29. Manage log auto-clear
    --- Tunnels ---
    31. Manage VLESS + Reality
    32. Manage Relay (external)
    33. Manage Psiphon
    34. Manage Tor
    35. Change language
    --- Tools ---
    36. Diagnostics
    37. Manage users
    38. Backup & Restore
    39. Update Cloudflare IPs
    --- Exit ---
    0.  Exit
```

### Status indicators

| Status | Meaning |
|--------|---------|
| `ACTIVE | Global` | All traffic routed through tunnel |
| `ACTIVE | Split` | Only domains from the list |
| `ACTIVE | route OFF` | Service running but not in routing |
| `OFF` | Service not running |

## Multi-user (item 37)

Multiple VLESS UUIDs with labels (e.g. "iPhone Vasya", "Laptop work").

- Each user gets their own UUID; changes apply to both XHTTP and Reality configs instantly
- Add / Remove / Rename users
- Individual QR code per user (XHTTP and Reality links)
- Cannot delete the last user
- Users stored in `/usr/local/etc/xray/users.conf`

On first open, the existing UUID is automatically imported as user `default`.

## Backup & Restore (item 38)

Manual backup of all configs, certificates, cron tasks, fail2ban rules.

Backups stored in `/root/vwn-backups/` with timestamps. No auto-deletion.

```bash
vwn backup    # Quick backup from CLI
vwn restore   # Interactive restore from CLI
```

What is backed up: Xray configs, Nginx + SSL certs, Cloudflare API key, cron tasks, Fail2Ban rules.

## Diagnostics (item 36)

```bash
vwn status    # Full diagnostics from CLI
```

Full scan or per-component check via submenu:

| Section | Checks |
|---------|--------|
| System | RAM, disk, swap, clock sync |
| Xray | Config validity, service status, ports |
| Nginx | Config, service, port 443, SSL expiry, DNS |
| WARP | warp-svc, connection, SOCKS5 response |
| Tunnels | Psiphon / Tor / Relay status |
| Connectivity | Internet, domain reachability |

Output: `✓` / `✗` per check, summary of issues at the end.

## WS → XHTTP Migration

If you have an existing WebSocket installation, run once:

```bash
bash migrate.sh
```

Creates a backup, converts config, removes WS headers from Nginx, tests, restarts. Auto-rollback on failure. Update clients to `type=xhttp` after migration.

## SSL Certificates

**Method 1 — Cloudflare DNS API** (recommended): port 80 not needed.  
**Method 2 — Standalone**: temporarily opens port 80.

Auto-renewal via cron every 35 days at 03:00.

## CDN Mode (item 9)

Blocks direct server access, only Cloudflare Proxy allowed. Enable after setting up orange cloud in Cloudflare. Use item 39 to refresh the IP list manually.

## File Structure

```
/usr/local/lib/vwn/
├── lang.sh       # Localisation (RU/EN)
├── core.sh       # Variables, utilities, status
├── xray.sh       # Xray XHTTP+TLS config
├── nginx.sh      # Nginx, CDN, SSL
├── warp.sh       # WARP management
├── reality.sh    # VLESS+Reality
├── relay.sh      # External outbound
├── psiphon.sh    # Psiphon tunnel
├── tor.sh        # Tor tunnel
├── security.sh   # UFW, BBR, Fail2Ban, SSH
├── logs.sh       # Logs, logrotate, cron
├── backup.sh     # Backup & Restore
├── users.sh      # Multi-user management
├── diag.sh       # Diagnostics
└── menu.sh       # Main menu

/usr/local/etc/xray/
├── config.json              # VLESS+XHTTP config
├── reality.json             # VLESS+Reality config
├── reality_client.txt       # Reality client params
├── vwn.conf                 # VWN settings
├── users.conf               # User list (UUID|label)
├── warp_domains.txt
├── psiphon.json
├── psiphon_domains.txt
├── tor_domains.txt
├── relay.conf
└── relay_domains.txt

/root/vwn-backups/
└── vwn-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
```

## Troubleshooting

```bash
# Something not working
vwn status

# WARP won't connect
systemctl restart warp-svc && sleep 5 && warp-cli --accept-tos connect

# Psiphon logs
tail -50 /var/log/psiphon/psiphon.log

# Reality won't start
xray -test -config /usr/local/etc/xray/reality.json

# Nginx after IPv6 disable
sed -i '/listen \[::\]:443/d' /etc/nginx/conf.d/xray.conf && nginx -t && systemctl reload nginx

# Tor — try bridges (item 34 → 11)
tail -50 /var/log/tor/notices.log
```

## Removal

```bash
vwn  # Item 26
```

Note: backups in `/root/vwn-backups/` are not removed automatically.

## Dependencies

- [Xray-core](https://github.com/XTLS/Xray-core)
- [Cloudflare WARP](https://1.1.1.1/)
- [Psiphon tunnel core](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries)
- [acme.sh](https://github.com/acmesh-official/acme.sh)
- nginx, jq, ufw, tor, obfs4proxy, qrencode

## License

MIT License

</details>

---

<details>
<summary>🇷🇺 Русский</summary>

# VWN — Xray VLESS + WARP + CDN + Reality

Автоматический установщик Xray VLESS с поддержкой XHTTP+TLS, Reality, Cloudflare WARP, CDN, Relay, Psiphon и Tor.

## Быстрая установка

```bash
curl -L https://raw.githubusercontent.com/HnDK0/VLESS-WebSocket-TLS-Nginx-WARP/main/install.sh -o vwn && bash vwn
```

После установки скрипт доступен как команда:
```bash
vwn
```

Обновить модули (без изменения конфигов):
```bash
vwn update
```

## Требования

- Ubuntu 22.04+ / Debian 11+
- Root доступ
- Домен, направленный на сервер (для XHTTP+TLS)
- Для Reality — только IP сервера, домен не нужен

## Особенности

- ✅ **VLESS + XHTTP + TLS** — подключения через Cloudflare CDN
- ✅ **VLESS + Reality** — прямые подключения без CDN (роутер, Clash)
- ✅ **Nginx** — reverse proxy с сайтом-заглушкой
- ✅ **Cloudflare WARP** — роутинг выбранных доменов или всего трафика
- ✅ **Psiphon** — обход блокировок с выбором страны выхода
- ✅ **Tor** — обход блокировок с выбором страны выхода, поддержка мостов (obfs4, snowflake, meek)
- ✅ **Relay** — внешний outbound (VLESS/VMess/Trojan/SOCKS по ссылке)
- ✅ **CDN защита** — блокировка прямого доступа, только через Cloudflare
- ✅ **Мульти-пользователи** — несколько UUID с метками, индивидуальные QR коды
- ✅ **Бэкап и восстановление** — ручной бэкап/восстановление всех конфигов
- ✅ **Диагностика** — полная проверка системы с детализацией по компонентам
- ✅ **WARP Watchdog** — автовосстановление WARP при обрыве
- ✅ **Fail2Ban + Web-Jail** — защита от брутфорса и сканеров
- ✅ **BBR** — ускорение TCP
- ✅ **Anti-Ping** — отключение ICMP
- ✅ **IPv6 отключён системно** — принудительный IPv4
- ✅ **Приватность** — access логи отключены, sniffing выключен
- ✅ **RU / EN интерфейс** — выбор языка при первом запуске

## Архитектура

```
Клиент (CDN/мобильный)
    └── Cloudflare CDN → 443/HTTPS → Nginx → VLESS+XHTTP → Xray → outbound

Клиент (роутер/Clash/прямое)
    └── IP:8443/TCP → VLESS+Reality → Xray → outbound

outbound (по routing rules):
    ├── free    — прямой выход (default)
    ├── warp    — Cloudflare WARP (SOCKS5:40000)
    ├── psiphon — Psiphon tunnel (SOCKS5:40002)
    ├── tor     — Tor (SOCKS5:40003)
    ├── relay   — внешний сервер (vless/vmess/trojan/socks)
    └── block   — blackhole (geoip:private)
```

## Порты

| Порт  | Назначение                        |
|-------|-----------------------------------|
| 22    | SSH (изменяемый)                  |
| 443   | VLESS+XHTTP+TLS через Nginx       |
| 8443  | VLESS+Reality (по умолчанию)      |
| 40000 | WARP SOCKS5 (warp-cli, локальный) |
| 40002 | Psiphon SOCKS5 (локальный)        |
| 40003 | Tor SOCKS5 (локальный)            |
| 40004 | Tor Control Port (локальный)      |

## CLI команды

```bash
vwn                # Открыть интерактивное меню
vwn update         # Обновить модули (без изменения конфигов)
vwn status         # Полная диагностика (без меню)
vwn backup         # Создать бэкап немедленно
vwn restore        # Восстановить из бэкапа (интерактивно)
vwn qr             # Показать QR коды (без меню)
```

## Меню управления

```
================================================================
   XRAY VLESS + WARP + CDN + REALITY | 27.02.2026 21:00
================================================================
  NGINX: RUNNING  |  XRAY: RUNNING  |  WARP: ACTIVE | Split
  SSL: OK (89 d)  |  BBR: ON  |  F2B: OFF
  WebJail: NO  |  CDN: OFF  |  Reality: ON (порт 8443)
  Relay: ON | Split  |  Psiphon: ON | Split, DE  |  Tor: ON | Split, US
----------------------------------------------------------------
    1.  Установить Xray (VLESS+XHTTP+TLS+WARP+CDN)
    2.  Показать QR-код и ссылку
    3.  Сменить UUID
    --- Конфигурация ---
    4.  Изменить порт Xray
    5.  Изменить путь XHTTP
    6.  Изменить сайт-заглушку
    7.  Перевыпустить SSL сертификат
    8.  Сменить домен
    --- CDN и WARP ---
    9.  Переключить CDN режим (ON/OFF)
    10. Переключить режим WARP (Global/Split/OFF)
    11. Добавить домен в WARP
    12. Удалить домен из WARP
    13. Редактировать список WARP (Nano)
    14. Проверить IP (Real vs WARP)
    --- Безопасность ---
    15. Включить BBR
    16. Включить Fail2Ban
    17. Включить Web-Jail
    18. Сменить SSH порт
    30. Установить WARP Watchdog
    --- Логи ---
    19. Логи Xray (access)
    20. Логи Xray (error)
    21. Логи Nginx (access)
    22. Логи Nginx (error)
    23. Очистить все логи
    --- Сервисы ---
    24. Перезапустить все сервисы
    25. Обновить Xray-core
    26. Полное удаление
    --- UFW, SSL, Logs ---
    27. Управление UFW
    28. Управление автообновлением SSL
    29. Управление автоочисткой логов
    --- Туннели ---
    31. Управление VLESS + Reality
    32. Управление Relay (внешний сервер)
    33. Управление Psiphon
    34. Управление Tor
    35. Сменить язык / Change language
    --- Инструменты ---
    36. Диагностика
    37. Управление пользователями
    38. Бэкап и восстановление
    39. Обновить IP Cloudflare
    --- Выход ---
    0.  Выйти
```

### Статусы в заголовке

| Статус | Описание |
|--------|----------|
| `ACTIVE | Global` | Весь трафик идёт через туннель |
| `ACTIVE | Split` | Только домены из списка |
| `ACTIVE | маршрут OFF` | Сервис запущен, но не в роутинге |
| `OFF` | Сервис не запущен |

## Туннели (пункты 31–34)

Все туннели: **Global / Split / OFF**. Применяются к обоим конфигам (XHTTP и Reality).

### VLESS + Reality (пункт 31)

Прямые подключения без CDN. Отдельный сервис `xray-reality`.

```
vless://UUID@IP:8443?security=reality&sni=microsoft.com&fp=chrome&pbk=KEY&sid=SID&type=tcp&flow=xtls-rprx-vision
```

### Relay (пункт 32)

Поддерживает: `vless://` `vmess://` `trojan://` `socks5://`

### Psiphon (пункт 33)

Выбор страны выхода: DE, NL, US, GB, FR, AT, CA, SE и др.

### Tor (пункт 34)

Выбор страны выхода через `ExitNodes`. Поддержка мостов: obfs4, snowflake, meek-azure. **Рекомендуется Split режим** — Tor медленнее обычного интернета.

## WARP (пункты 10–14)

**Split** (по умолчанию): `openai.com, chatgpt.com, oaistatic.com, oaiusercontent.com, auth0.openai.com`

**Global** — весь трафик через WARP. **OFF** — отключён от роутинга.

**WARP Watchdog (пункт 30)** — cron каждые 2 минуты, автопереподключение.

## Мульти-пользователи (пункт 37)

Несколько VLESS UUID с произвольными метками ("iPhone Vasya", "Ноутбук работа").

- Добавить / Удалить / Переименовать / QR для каждого
- Изменения мгновенно применяются к обоим конфигам
- Последнего пользователя удалить нельзя
- Хранится в `/usr/local/etc/xray/users.conf`

При первом открытии существующий UUID импортируется как `default`.

## Бэкап и восстановление (пункт 38)

Бэкапы в `/root/vwn-backups/` с датой и временем. Автоудаления нет.

```bash
vwn backup    # Быстрый бэкап из CLI
vwn restore   # Интерактивное восстановление
```

Включает: конфиги Xray, Nginx + SSL, API ключи Cloudflare, cron, Fail2Ban.

## Диагностика (пункт 36)

```bash
vwn status    # Полная диагностика из CLI
```

| Раздел | Проверки |
|--------|----------|
| Система | RAM, диск, swap, часы |
| Xray | Конфиги, сервисы, порты |
| Nginx | Конфиг, сервис, SSL, DNS |
| WARP | warp-svc, подключение, SOCKS5 |
| Туннели | Psiphon / Tor / Relay |
| Связность | Интернет, домен |

Вывод: `✓` / `✗` по каждой проверке + итоговый список проблем.

## Миграция WS → XHTTP

```bash
bash migrate.sh
```

Автобэкап → конвертация конфига → обновление Nginx → перезапуск. Автооткат при ошибке. После миграции обновите клиенты на `type=xhttp`.

## SSL сертификаты

**Метод 1 — Cloudflare DNS API** (рекомендуется): порт 80 не нужен.  
**Метод 2 — Standalone**: временно открывает порт 80.

Автообновление через cron раз в 35 дней в 3:00.

## CDN режим (пункт 9)

Блокирует прямой доступ, только через Cloudflare Proxy. Включайте после настройки оранжевого облака. Пункт 39 — обновить список IP вручную.

## Структура файлов

```
/usr/local/lib/vwn/
├── lang.sh       # Локализация (RU/EN)
├── core.sh       # Переменные, утилиты, статусы
├── xray.sh       # Xray XHTTP+TLS конфиг
├── nginx.sh      # Nginx, CDN, SSL
├── warp.sh       # WARP управление
├── reality.sh    # VLESS+Reality
├── relay.sh      # Внешний outbound
├── psiphon.sh    # Psiphon туннель
├── tor.sh        # Tor туннель
├── security.sh   # UFW, BBR, Fail2Ban, SSH
├── logs.sh       # Логи, logrotate, cron
├── backup.sh     # Бэкап и восстановление
├── users.sh      # Управление пользователями
├── diag.sh       # Диагностика
└── menu.sh       # Главное меню

/usr/local/etc/xray/
├── config.json              # Конфиг VLESS+XHTTP
├── reality.json             # Конфиг VLESS+Reality
├── reality_client.txt       # Параметры клиента Reality
├── vwn.conf                 # Настройки VWN
├── users.conf               # Список пользователей (UUID|метка)
├── warp_domains.txt
├── psiphon.json
├── psiphon_domains.txt
├── tor_domains.txt
├── relay.conf
└── relay_domains.txt

/root/vwn-backups/
└── vwn-backup-YYYY-MM-DD_HH-MM-SS.tar.gz
```

## Решение проблем

```bash
# Что-то не работает
vwn status

# WARP не подключается
systemctl restart warp-svc && sleep 5 && warp-cli --accept-tos connect

# Логи Psiphon
tail -50 /var/log/psiphon/psiphon.log

# Reality не запускается
xray -test -config /usr/local/etc/xray/reality.json

# Nginx после отключения IPv6
sed -i '/listen \[::\]:443/d' /etc/nginx/conf.d/xray.conf && nginx -t && systemctl reload nginx

# Tor — попробовать мосты (пункт 34 → 11)
tail -50 /var/log/tor/notices.log
```

## Удаление

```bash
vwn  # Пункт 26
```

Бэкапы в `/root/vwn-backups/` автоматически не удаляются.

## Зависимости

- [Xray-core](https://github.com/XTLS/Xray-core)
- [Cloudflare WARP](https://1.1.1.1/)
- [Psiphon tunnel core](https://github.com/Psiphon-Labs/psiphon-tunnel-core-binaries)
- [acme.sh](https://github.com/acmesh-official/acme.sh)
- nginx, jq, ufw, tor, obfs4proxy, qrencode

## Лицензия

MIT License
</details>

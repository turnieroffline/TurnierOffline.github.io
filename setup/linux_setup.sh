#!/bin/bash
# ══════════════════════════════════════════════════════════════
# TurnierOffline V14 – Linux Setup (Ubuntu / Debian / openSUSE)
# Ausführen: sudo bash linux_setup.sh
# ══════════════════════════════════════════════════════════════

OR='\033[38;5;208m'; GN='\033[0;32m'; RD='\033[0;31m'
BL='\033[0;34m'; CY='\033[0;36m'; NC='\033[0m'; BD='\033[1m'

banner() {
  echo -e "\n${OR}${BD}╔══════════════════════════════════════════════╗
║  🏆  TurnierOffline V14 – Linux Setup       ║
╚══════════════════════════════════════════════╝${NC}\n"
}
ok()   { echo -e "  ${GN}✓ $1${NC}"; }
err()  { echo -e "  ${RD}✗ $1${NC}"; exit 1; }
warn() { echo -e "  ${OR}⚠ $1${NC}"; }
info() { echo -e "  ${CY}ℹ $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }
TOTAL=7

banner

# Root-Check
[ "$EUID" -ne 0 ] && err "Bitte mit sudo ausführen: sudo bash linux_setup.sh"

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
REAL_HOME=$(eval echo ~"$REAL_USER")

# Distro erkennen
DISTRO=""
if command -v apt-get &>/dev/null; then
    DISTRO="debian"
    info "Erkannt: Ubuntu/Debian"
elif command -v zypper &>/dev/null; then
    DISTRO="opensuse"
    info "Erkannt: openSUSE"
elif command -v dnf &>/dev/null; then
    DISTRO="fedora"
    info "Erkannt: Fedora/RHEL"
else
    err "Unbekannte Distribution. Unterstützt: Ubuntu, Debian, openSUSE, Fedora"
fi

# VM erkennen
IS_VM=false
VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
[[ "$VIRT" != "none" ]] && { IS_VM=true; info "VM erkannt: $VIRT"; }

# ── 1) System aktualisieren ───────────────────────────────────
step 1 "System aktualisieren"
case "$DISTRO" in
    debian)  apt-get update -q && apt-get upgrade -y -q ;;
    opensuse) zypper --non-interactive --quiet refresh && zypper --non-interactive --quiet update ;;
    fedora)  dnf update -y -q ;;
esac
ok "System aktuell"

# ── 2) PHP + Extensions installieren ─────────────────────────
step 2 "PHP + Erweiterungen installieren"
case "$DISTRO" in
    debian)
        apt-get install -y -q php php-sqlite3 php-curl php-mbstring php-json php-gd php-zip unzip curl wget
        ;;
    opensuse)
        zypper --non-interactive install -y php8 php8-sqlite php8-curl php8-mbstring php8-json php8-gd php8-zip unzip curl wget 2>&1 | grep -E "Installing|already|Error" || true
        ;;
    fedora)
        dnf install -y php php-pdo php-curl php-mbstring php-json php-gd php-zip unzip curl wget
        ;;
esac

PHP_V=$(php --version 2>/dev/null | head -1 | awk '{print $2}')
[[ -z "$PHP_V" ]] && err "PHP Installation fehlgeschlagen"
ok "PHP $PHP_V"
php -r "new PDO('sqlite::memory:');" &>/dev/null && ok "SQLite verfügbar" || err "SQLite nicht verfügbar"

# ── 3) Firewall ───────────────────────────────────────────────
step 3 "Firewall konfigurieren"
PORT=8080
if command -v firewall-cmd &>/dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/tcp &>/dev/null
    firewall-cmd --reload &>/dev/null
    ok "firewalld: Port $PORT geöffnet"
elif command -v ufw &>/dev/null; then
    ufw allow $PORT/tcp &>/dev/null
    ok "ufw: Port $PORT geöffnet"
else
    warn "Kein Firewall-Tool gefunden – Port $PORT manuell öffnen falls nötig"
fi

# ── 4) TurnierOffline installieren ────────────────────────────
step 4 "TurnierOffline installieren"
INSTALL_DIR="$REAL_HOME/TurnierOffline"
ZIP_FILE=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for loc in "$SCRIPT_DIR" "$REAL_HOME/Downloads" "$REAL_HOME/Desktop" "/tmp"; do
    f=$(find "$loc" -maxdepth 1 -name "TurnierOffline*.zip" 2>/dev/null | head -1)
    [[ -n "$f" ]] && ZIP_FILE="$f" && break
done

if [[ -z "$ZIP_FILE" ]]; then
    echo -e "  ${RD}✗ TurnierOffline ZIP nicht gefunden!${NC}"
    echo "  ZIP-Datei in diesen Ordner legen: $SCRIPT_DIR"
    exit 1
fi
ok "ZIP: $ZIP_FILE"

[[ -d "$INSTALL_DIR" ]] && mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%H%M)"
mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Unterordner hochschieben
if [[ ! -f "$INSTALL_DIR/index.php" ]]; then
    INNER=$(find "$INSTALL_DIR" -maxdepth 2 -name "index.php" | head -1 | xargs dirname 2>/dev/null)
    [[ -n "$INNER" && "$INNER" != "$INSTALL_DIR" ]] && \
        mv "$INNER"/* "$INSTALL_DIR/" && rmdir "$INNER" 2>/dev/null
fi
ok "Installiert: $INSTALL_DIR"

# ── 5) Berechtigungen setzen ─────────────────────────────────
step 5 "Berechtigungen + Ordner"
for d in uploads/teams uploads/werbung uploads/qr uploads/regeln database; do
    mkdir -p "$INSTALL_DIR/$d"
done
chown -R "$REAL_USER:$REAL_USER" "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 777 "$INSTALL_DIR/uploads" "$INSTALL_DIR/database" 2>/dev/null
ok "Fertig"

# ── 6) Systemd Service ────────────────────────────────────────
step 6 "Systemd Service einrichten (Auto-Start)"
PHP_BIN=$(command -v php)
SERVICE_FILE="/etc/systemd/system/turnieroffline.service"

cat > "$SERVICE_FILE" << SERVICE
[Unit]
Description=TurnierOffline V14 PHP Server
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$PHP_BIN -S 0.0.0.0:$PORT -t $INSTALL_DIR
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable turnieroffline 2>/dev/null
systemctl start turnieroffline 2>/dev/null
sleep 1

if systemctl is-active --quiet turnieroffline; then
    ok "Systemd Service läuft (startet automatisch beim Booten)"
else
    warn "Service-Start fehlgeschlagen – manuell starten: php -S 0.0.0.0:$PORT -t $INSTALL_DIR"
fi

# ── 7) Startskript + Desktop-Shortcut ────────────────────────
step 7 "Startskript + Desktop-Shortcut"
START="$REAL_HOME/start_turnier.sh"
cat > "$START" << STARTSCRIPT
#!/bin/bash
PORT=$PORT
INSTALL_DIR="$INSTALL_DIR"

# Service Status prüfen
if systemctl is-active --quiet turnieroffline 2>/dev/null; then
    echo "TurnierOffline läuft bereits (systemd)"
else
    # Freien Port finden
    for P in 8080 8181 9090 7777; do
        ss -ltn | grep -q ":$P " 2>/dev/null || { PORT=\$P; break; }
    done
    cd "\$INSTALL_DIR"
    php -S 0.0.0.0:\$PORT -t "\$INSTALL_DIR" &
    SERVER_PID=\$!
fi

IP=\$(hostname -I | awk '{print \$1}')
echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║  🏆  TurnierOffline V14 läuft!              ║"
echo "  ╠══════════════════════════════════════════════╣"
echo "  ║  Admin:     http://localhost:\$PORT/admin/"
echo "  ║  Zuschauer: http://\$IP:\$PORT/mobile/"
echo "  ║  TV:        http://\$IP:\$PORT/tv/"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
xdg-open "http://localhost:\$PORT/admin/" 2>/dev/null &
wait \$SERVER_PID 2>/dev/null || read -rp "ENTER zum Beenden..." _
STARTSCRIPT
chmod +x "$START"
chown "$REAL_USER:$REAL_USER" "$START"

# Installer-Verzeichnis in Home kopieren
INSTALLER_DIR="$REAL_HOME/TurnierOffline_Installer"
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$INSTALLER_DIR/linux"
cp "$SCRIPT_SRC/start.sh" "$INSTALLER_DIR/" 2>/dev/null ||     cp "$(dirname "$0")/start.sh" "$INSTALLER_DIR/" 2>/dev/null || true
cp "$SCRIPT_SRC/linux/"*.sh "$INSTALLER_DIR/linux/" 2>/dev/null || true
chmod +x "$INSTALLER_DIR/start.sh" "$INSTALLER_DIR/linux/"*.sh 2>/dev/null || true
chown -R "$REAL_USER:$REAL_USER" "$INSTALLER_DIR"

# TO_DIR in Skripten eintragen
sed -i "s|TO_DIR:-\$HOME/TurnierOffline|TO_DIR:-$INSTALL_DIR|g"     "$INSTALLER_DIR/start.sh" "$INSTALLER_DIR/linux/"*.sh 2>/dev/null || true

# Desktop-Shortcut → öffnet Startmenü
DESKTOP_FILE="$REAL_HOME/Desktop/TurnierOffline.desktop"
mkdir -p "$REAL_HOME/Desktop"
cat > "$DESKTOP_FILE" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=TurnierOffline V14
Comment=Admin / Server-Modus / TV-Modus
Exec=bash $INSTALLER_DIR/start.sh
Icon=network-server
Terminal=true
Categories=Sports;
StartupNotify=false
DESKTOP
chmod +x "$DESKTOP_FILE"
chown "$REAL_USER:$REAL_USER" "$DESKTOP_FILE"
ok "Desktop-Shortcut → Startmenü (Admin / Server / TV)"

# ── VM-Hinweise ───────────────────────────────────────────────
if [[ "$IS_VM" == "true" ]]; then
    echo -e "\n${CY}${BD}VM-Netzwerk Hinweise:${NC}"
    echo -e "  ${CY}VirtualBox: Netzwerkadapter → Überbrückter Adapter (Bridged)${NC}"
    echo -e "  ${CY}Dann bekommen VM und Handy IPs im gleichen Netz.${NC}"
    echo -e "  ${CY}Alternativ NAT + Port-Weiterleitung: 8080 → 8080${NC}"
fi

# ── Fertig ────────────────────────────────────────────────────
IP=$(hostname -I | awk '{print $1}')
echo -e "\n${GN}${BD}╔══════════════════════════════════════════════╗
║  ✅  Installation erfolgreich!               ║
╠══════════════════════════════════════════════╣
║  Admin:     http://localhost:$PORT/admin/
║  Zuschauer: http://$IP:$PORT/mobile/
║  TV:        http://$IP:$PORT/tv/
╚══════════════════════════════════════════════╝${NC}\n"
echo -e "  ${OR}Desktop-Shortcut: TurnierOffline.desktop${NC}"
echo -e "  ${BL}Startskript: ~/start_turnier.sh${NC}\n"

#!/bin/bash
# ══════════════════════════════════════════════════════
# TurnierOffline V14 – Setup für openSUSE Leap
# Für: Laptop/PC direkt + VirtualBox VM
# Ausführen: sudo bash opensuse_setup.sh
# ══════════════════════════════════════════════════════

OR='\033[38;5;208m'; GN='\033[0;32m'; RD='\033[0;31m'
BL='\033[0;34m'; CY='\033[0;36m'; NC='\033[0m'; BD='\033[1m'

[ "$EUID" -ne 0 ] && { echo -e "${RD}Bitte mit sudo ausführen: sudo bash opensuse_setup.sh${NC}"; exit 1; }

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
REAL_HOME=$(eval echo ~"$REAL_USER")
TOTAL=7

banner() {
  echo -e "\n${OR}${BD}╔══════════════════════════════════════════════════╗
║  🏆 TurnierOffline V14 – openSUSE Leap Setup   ║
╚══════════════════════════════════════════════════╝${NC}\n"
}
ok()   { echo -e "  ${GN}✓ $1${NC}"; }
err()  { echo -e "  ${RD}✗ $1${NC}"; }
info() { echo -e "  ${CY}ℹ $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }

banner

# VM-Erkennung
IS_VM=false
VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
[ "$VIRT" != "none" ] && { IS_VM=true; info "VM erkannt: $VIRT"; }

# 1) System aktualisieren
step 1 "System aktualisieren"
zypper --non-interactive --quiet refresh
zypper --non-interactive --quiet update
ok "System aktuell"

# 2) PHP 8 + Extensions
step 2 "PHP 8 + Erweiterungen installieren"
zypper --non-interactive install -y \
  php8 php8-sqlite php8-curl php8-mbstring php8-json php8-gd php8-zip \
  unzip curl wget 2>&1 | grep -E "Installing|already|Error" || true
PHP_V=$(php --version | head -1 | awk '{print $2}')
ok "PHP $PHP_V"

# 3) Firewall
step 3 "Firewall Port 8080 freigeben"
if command -v firewall-cmd &>/dev/null; then
  firewall-cmd --add-port=8080/tcp --permanent -q
  firewall-cmd --reload -q
  ok "Port 8080 offen (firewalld)"
else
  err "firewalld nicht gefunden – Port manuell freigeben"
fi

if $IS_VM; then
  echo ""
  info "VirtualBox-Netzwerk: Für Zugriff vom Host benötigst du"
  info "  Bridged Adapter  ODER  NAT + Port-Forwarding 8080→8080"
fi

# 4) TurnierOffline installieren
step 4 "TurnierOffline V14 entpacken"
INSTALL_DIR="$REAL_HOME/TurnierOffline"
mkdir -p "$INSTALL_DIR"
chown "$REAL_USER:$REAL_USER" "$INSTALL_DIR"

ZIP_FOUND=""
for loc in \
  "$REAL_HOME/Downloads/TurnierOffline_V14.zip" \
  "$REAL_HOME/Desktop/TurnierOffline_V14.zip" \
  "$REAL_HOME/TurnierOffline_V14.zip" \
  "/tmp/TurnierOffline_V14.zip"
do
  [ -f "$loc" ] && { ZIP_FOUND="$loc"; break; }
done

if [ -z "$ZIP_FOUND" ]; then
  err "ZIP nicht gefunden!"
  echo -e "  ${OR}Bitte TurnierOffline_V14.zip in ~/Downloads/ kopieren und nochmal: sudo bash opensuse_setup.sh${NC}"
else
  echo "  → ZIP: $ZIP_FOUND"
  unzip -q -o "$ZIP_FOUND" -d "$INSTALL_DIR/"
  chown -R "$REAL_USER:$REAL_USER" "$INSTALL_DIR/"
  ok "Entpackt nach $INSTALL_DIR"
fi

TO_DIR="$INSTALL_DIR/TurnierOffline_V14"

# 5) Systemdienst
step 5 "Systemd-Dienst erstellen (Auto-Start)"
cat > /etc/systemd/system/turnieroffline.service << SVCEOF
[Unit]
Description=TurnierOffline V14
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$TO_DIR
ExecStart=/usr/bin/php -S 0.0.0.0:8080
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
ok "Dienst 'turnieroffline' erstellt"

# 6) Start-Skript
step 6 "Start-Skript erstellen"
cat > "$REAL_HOME/start_turnier.sh" << STARTEOF
#!/bin/bash
DIR="$TO_DIR"
IP=\$(hostname -I | awk '{print \$1}')
printf '\n\033[38;5;208m\033[1m🏆 TurnierOffline V14\033[0m\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '📱 Admin:      \033[0;32mhttp://localhost:8080/admin/\033[0m\n'
printf '📺 TV:         \033[0;32mhttp://localhost:8080/tv/\033[0m\n'
printf "👥 Zuschauer:  \033[0;32mhttp://\${IP}:8080/mobile/\033[0m\n"
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '  Dienst:  sudo systemctl start turnieroffline\n'
printf '  Stop:    sudo systemctl stop turnieroffline\n'
printf '  Logs:    sudo journalctl -u turnieroffline -f\n\n'
cd "\$DIR" && php -S 0.0.0.0:8080 2>&1
STARTEOF
chmod +x "$REAL_HOME/start_turnier.sh"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/start_turnier.sh"
ok "~/start_turnier.sh erstellt"

# 7) Desktop-Shortcut
step 7 "Desktop-Verknüpfung"
DESK="$REAL_HOME/Desktop"
if [ -d "$DESK" ]; then
  cat > "$DESK/TurnierOffline.desktop" << DESKEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TurnierOffline V14
Comment=Turnierverwaltung starten
Exec=bash -c 'cd $TO_DIR && php -S 0.0.0.0:8080 & sleep 1 && xdg-open http://localhost:8080/admin/'
Icon=applications-games
Terminal=true
Categories=Game;
DESKEOF
  chmod +x "$DESK/TurnierOffline.desktop"
  chown "$REAL_USER:$REAL_USER" "$DESK/TurnierOffline.desktop"
  ok "Desktop-Verknüpfung erstellt"
else
  info "Kein Desktop-Ordner – übersprungen"
fi

IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "\n${OR}${BD}╔══════════════════════════════════════════════════╗
║        ✅ SETUP ABGESCHLOSSEN!                  ║
╚══════════════════════════════════════════════════╝${NC}"
echo -e "\n  Direkt starten:  ${OR}bash ~/start_turnier.sh${NC}"
echo -e "  Als Dienst:       ${OR}sudo systemctl enable --now turnieroffline${NC}"
echo -e "\n  Deine IP:         ${GN}$IP_ADDR${NC}"
echo -e "  Admin:            ${GN}http://localhost:8080/admin/${NC}"
echo -e "  Zuschauer:        ${GN}http://$IP_ADDR:8080/mobile/${NC}"
echo -e "\n  Passwort:         ${RD}admin123 → sofort ändern!${NC}\n"

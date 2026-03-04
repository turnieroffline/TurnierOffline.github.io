#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════
# TurnierOffline V14 – Setup für Termux
# Ausführen: bash termux_setup.sh
# ══════════════════════════════════════════════

OR='\033[38;5;208m'; GN='\033[0;32m'; RD='\033[0;31m'
BL='\033[0;34m'; NC='\033[0m'; BD='\033[1m'

banner() {
  echo -e "\n${OR}${BD}╔══════════════════════════════════════════╗
║   🏆 TurnierOffline V14 – Termux Setup  ║
╚══════════════════════════════════════════╝${NC}\n"
}
ok()   { echo -e "  ${GN}✓ $1${NC}"; }
err()  { echo -e "  ${RD}✗ $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }

banner
TOTAL=6

# 1) Pakete aktualisieren
step 1 "Pakete aktualisieren"
pkg update -y -q && pkg upgrade -y -q
ok "Pakete aktuell"

# 2) PHP + Tools
step 2 "PHP + SQLite installieren"
pkg install -y -q php php-sqlite curl unzip
PHP_V=$(php -r 'echo PHP_VERSION;')
ok "PHP $PHP_V installiert"

# 3) Speicherzugang
step 3 "Speicher-Zugang einrichten"
if [ ! -d "$HOME/storage/shared" ]; then
  echo "  → Android-Dialog erscheint – bitte 'Erlauben' tippen"
  termux-setup-storage
  sleep 3
fi
mkdir -p /storage/emulated/0/TurnierOffline
ok "Speicher eingerichtet"

# 4) ZIP suchen & entpacken
step 4 "TurnierOffline V14 installieren"
INSTALL_DIR="/storage/emulated/0/TurnierOffline"
ZIP_FOUND=""
for loc in \
  "/storage/emulated/0/Download/TurnierOffline_V14.zip" \
  "/storage/emulated/0/TurnierOffline_V14.zip" \
  "$HOME/TurnierOffline_V14.zip"
do
  [ -f "$loc" ] && { ZIP_FOUND="$loc"; break; }
done

if [ -z "$ZIP_FOUND" ]; then
  err "ZIP nicht gefunden!"
  echo -e "  ${OR}Bitte TurnierOffline_V14.zip in den Download-Ordner kopieren und nochmal starten.${NC}"
else
  echo "  → ZIP: $ZIP_FOUND"
  unzip -q -o "$ZIP_FOUND" -d "$INSTALL_DIR/"
  ok "Entpackt nach $INSTALL_DIR"
fi

# 5) Start-Skript
step 5 "Start-Skript + Alias erstellen"
cat > "$HOME/start_turnier.sh" << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
DIR="/storage/emulated/0/TurnierOffline/TurnierOffline_V14"
[ ! -d "$DIR" ] && { echo "Ordner nicht gefunden: $DIR"; exit 1; }
IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
printf '\n\033[38;5;208m\033[1m🏆 TurnierOffline V14\033[0m\n'
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf '📱 Admin:     \033[0;32mhttp://localhost:8080/admin/\033[0m\n'
printf '📺 TV:        \033[0;32mhttp://localhost:8080/tv/\033[0m\n'
printf "👥 Zuschauer: \033[0;32mhttp://${IP:-DEINE-IP}:8080/mobile/\033[0m\n"
printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
printf 'Strg+C zum Beenden\n\n'
cd "$DIR" && php -S 0.0.0.0:8080 2>&1
STARTEOF
chmod +x "$HOME/start_turnier.sh"

BASHRC="$HOME/.bashrc"
grep -q "alias turnier=" "$BASHRC" 2>/dev/null || {
  printf '\n# TurnierOffline\nalias turnier="bash ~/start_turnier.sh"\n' >> "$BASHRC"
}
ok "~/start_turnier.sh erstellt + Alias 'turnier' gesetzt"

# 6) Boot-Auto-Start (optional)
step 6 "Auto-Start beim Handy-Neustart (optional)"
if pkg list-installed 2>/dev/null | grep -q "termux-boot"; then
  mkdir -p ~/.termux/boot
  cat > ~/.termux/boot/start_turnier.sh << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/sh
sleep 5
cd /storage/emulated/0/TurnierOffline/TurnierOffline_V14
nohup php -S 0.0.0.0:8080 > /tmp/to_boot.log 2>&1 &
BOOTEOF
  chmod +x ~/.termux/boot/start_turnier.sh
  ok "Auto-Start konfiguriert (Termux:Boot)"
else
  echo "  → Termux:Boot nicht installiert (optional)"
  echo "     Aus F-Droid installieren für Auto-Start beim Neustart"
fi

# Fertig
echo -e "\n${OR}${BD}╔══════════════════════════════════════════╗
║        ✅ SETUP ABGESCHLOSSEN!           ║
╚══════════════════════════════════════════╝${NC}"
echo -e "\n  Starten:      ${OR}bash ~/start_turnier.sh${NC}"
echo -e "  Kurzbefehl:   ${OR}turnier${NC}  (nach Termux-Neustart)"
echo -e "  Passwort:     ${RD}admin123 → sofort ändern!${NC}\n"

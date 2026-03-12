#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  🏆 TurnierOffline V16 — Linux Setup
#  Ausführen: bash linux_setup.sh
#  Getestet auf: Ubuntu 22/24, Debian 12, openSUSE Leap 15, Raspberry Pi OS
# ══════════════════════════════════════════════════════════════════

OR='\033[38;5;208m'
GN='\033[0;32m'
RD='\033[0;31m'
BL='\033[0;34m'
YL='\033[0;33m'
NC='\033[0m'
BD='\033[1m'

PORT=8080
APP_DIR="$(pwd)/TurnierOffline_V16"
ZIP_NAME="TurnierOffline_V16.zip"

banner() {
  clear
  echo -e "${OR}${BD}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║   🏆  TurnierOffline V16  –  Linux Setup    ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

ok()   { echo -e "  ${GN}✓  $1${NC}"; }
err()  { echo -e "  ${RD}✗  $1${NC}"; }
info() { echo -e "  ${YL}→  $1${NC}"; }

banner

# ── PHP prüfen / installieren ─────────────────────────────────────
echo -e "${BL}${BD}[1/4] PHP prüfen${NC}"
if command -v php &>/dev/null; then
  PHP_V=$(php -r 'echo PHP_VERSION;')
  ok "PHP $PHP_V bereits installiert"
else
  info "PHP wird installiert..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -q && sudo apt-get install -y php php-sqlite3 php-mbstring
  elif command -v zypper &>/dev/null; then
    sudo zypper install -y php8 php8-sqlite php8-mbstring
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y php php-sqlite3 php-mbstring
  else
    err "Paketmanager nicht erkannt — PHP bitte manuell installieren"
    exit 1
  fi
  ok "PHP installiert"
fi

# ── ZIP entpacken ─────────────────────────────────────────────────
echo -e "\n${BL}${BD}[2/4] Dateien entpacken${NC}"
if [ ! -f "$ZIP_NAME" ]; then
  err "ZIP nicht gefunden: $ZIP_NAME"
  info "Bitte $ZIP_NAME in diesen Ordner legen und nochmal starten."
  exit 1
fi
unzip -q -o "$ZIP_NAME"
mkdir -p "$APP_DIR/uploads/werbung" "$APP_DIR/uploads/regeln"
chmod -R 755 "$APP_DIR/uploads"
ok "Entpackt nach: $APP_DIR"

# ── IP ermitteln ──────────────────────────────────────────────────
echo -e "\n${BL}${BD}[3/4] Netzwerk${NC}"
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
[ -z "$IP" ] && IP=$(hostname -I | awk '{print $1}')
[ -z "$IP" ] && IP="localhost"
ok "IP-Adresse: $IP"

# ── Server starten ────────────────────────────────────────────────
echo -e "\n${BL}${BD}[4/4] Server starten${NC}"
echo ""
echo -e "${OR}${BD}  ══════════════════════════════════════════════${NC}"
echo -e "${GN}${BD}  ✓  TurnierOffline V16 ist bereit!${NC}"
echo -e "${OR}${BD}  ══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BD}Admin:${NC}   ${GN}http://$IP:$PORT/admin/${NC}"
echo -e "  ${BD}TV:${NC}      ${GN}http://$IP:$PORT/tv/${NC}"
echo -e "  ${BD}Handy:${NC}   ${GN}http://$IP:$PORT/mobile/${NC}"
echo ""
echo -e "  ${BD}Passwort:${NC}  ${YL}admin123${NC}  ${RD}← bitte sofort ändern!${NC}"
echo -e "  ${YL}Zum Beenden: Strg+C${NC}"
echo ""
cd "$APP_DIR"
php -S 0.0.0.0:$PORT -t .

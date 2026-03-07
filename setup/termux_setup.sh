#!/data/data/com.termux/files/usr/bin/bash
# ══════════════════════════════════════════════════════════════════
#  🏆 TurnierOffline V16 — Termux Setup
#  Ausführen in Termux: bash termux_setup.sh
# ══════════════════════════════════════════════════════════════════

OR='\033[38;5;208m'
GN='\033[0;32m'
RD='\033[0;31m'
BL='\033[0;34m'
YL='\033[0;33m'
NC='\033[0m'
BD='\033[1m'

TOTAL=7
ZIP_NAME="TurnierOffline_V16.zip"
INSTALL_DIR="/storage/emulated/0/TurnierOffline"
PORT=8080

banner() {
  clear
  echo -e "${OR}${BD}"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║   🏆  TurnierOffline V16  –  Termux Setup   ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "${NC}"
}

ok()   { echo -e "  ${GN}✓  $1${NC}"; }
err()  { echo -e "  ${RD}✗  $1${NC}"; }
info() { echo -e "  ${YL}→  $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }

banner

# ── 1) Pakete ──────────────────────────────────────────────────────
step 1 "Pakete aktualisieren"
pkg update -y -q && pkg upgrade -y -q
ok "Pakete aktuell"

# ── 2) PHP + Tools ────────────────────────────────────────────────
step 2 "PHP + SQLite installieren"
pkg install -y -q php php-sqlite curl unzip qrencode 2>/dev/null || \
  pkg install -y -q php curl unzip 2>/dev/null
PHP_V=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "unbekannt")
ok "PHP $PHP_V installiert"

# ── 3) Speicherzugang ─────────────────────────────────────────────
step 3 "Android-Speicher einrichten"
if [ ! -d "$HOME/storage/shared" ]; then
  info "Android-Dialog erscheint — bitte 'Erlauben' antippen"
  termux-setup-storage
  sleep 4
fi
mkdir -p "$INSTALL_DIR"
ok "Speicher bereit: $INSTALL_DIR"

# ── 4) ZIP suchen ─────────────────────────────────────────────────
step 4 "TurnierOffline V16 installieren"
ZIP_FOUND=""
for loc in \
  "/storage/emulated/0/Download/$ZIP_NAME" \
  "/storage/emulated/0/$ZIP_NAME" \
  "$HOME/storage/downloads/$ZIP_NAME" \
  "$HOME/$ZIP_NAME" \
  "$(pwd)/$ZIP_NAME"
do
  [ -f "$loc" ] && { ZIP_FOUND="$loc"; break; }
done

if [ -z "$ZIP_FOUND" ]; then
  err "ZIP nicht gefunden!"
  echo ""
  echo -e "  ${OR}${BD}Bitte so vorgehen:${NC}"
  echo -e "  ${OR}1) $ZIP_NAME herunterladen${NC}"
  echo -e "  ${OR}2) In den Download-Ordner kopieren${NC}"
  echo -e "  ${OR}3) Dieses Skript nochmal starten${NC}"
  echo ""
  exit 1
fi

info "ZIP gefunden: $ZIP_FOUND"
rm -rf "$INSTALL_DIR/TurnierOffline_V16" 2>/dev/null
unzip -q -o "$ZIP_FOUND" -d "$INSTALL_DIR/"
APP_DIR="$INSTALL_DIR/TurnierOffline_V16"

if [ ! -d "$APP_DIR" ]; then
  err "Entpacken fehlgeschlagen — Ordner nicht gefunden"
  exit 1
fi

# Uploads-Ordner sicherstellen
mkdir -p "$APP_DIR/uploads/werbung"
mkdir -p "$APP_DIR/uploads/regeln"
chmod 755 "$APP_DIR/uploads" "$APP_DIR/uploads/werbung" "$APP_DIR/uploads/regeln"

ok "TurnierOffline V16 installiert"

# ── 5) Datenbank initialisieren ───────────────────────────────────
step 5 "Datenbank vorbereiten"
mkdir -p "$APP_DIR/database"
chmod 755 "$APP_DIR/database"
ok "Datenbank-Ordner bereit (wird beim ersten Start erstellt)"

# ── 6) IP-Adresse ermitteln ───────────────────────────────────────
step 6 "Netzwerk-Adresse ermitteln"
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
[ -z "$IP" ] && IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$IP" ] && IP="192.168.x.x"
ok "IP-Adresse: $IP"

# ── 7) PHP-Server starten ─────────────────────────────────────────
step 7 "PHP-Server starten"
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
echo ""

# QR-Code für Handy-URL anzeigen (falls qrencode verfügbar)
if command -v qrencode &>/dev/null; then
  echo -e "  ${BD}QR-Code für Handy-App:${NC}"
  qrencode -t ANSI "http://$IP:$PORT/mobile/" 2>/dev/null
  echo ""
fi

echo -e "  ${YL}Zum Beenden: Strg+C${NC}"
echo ""
cd "$APP_DIR"
php -S 0.0.0.0:$PORT -t . 2>/dev/null

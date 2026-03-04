#!/bin/bash
# ══════════════════════════════════════════════════════════════
# TurnierOffline V14 – macOS Setup
# Ausführen: bash macos_setup.sh
# ══════════════════════════════════════════════════════════════

OR='\033[38;5;208m'; GN='\033[0;32m'; RD='\033[0;31m'
BL='\033[0;34m'; NC='\033[0m'; BD='\033[1m'

banner() {
  echo -e "\n${OR}${BD}╔══════════════════════════════════════════════╗
║  🏆  TurnierOffline V14 – macOS Setup       ║
╚══════════════════════════════════════════════╝${NC}\n"
}
ok()   { echo -e "  ${GN}✓ $1${NC}"; }
err()  { echo -e "  ${RD}✗ $1${NC}"; exit 1; }
warn() { echo -e "  ${OR}⚠ $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }
TOTAL=6

banner

# ── 1) Homebrew ──────────────────────────────────────────────
step 1 "Homebrew prüfen / installieren"
if ! command -v brew &>/dev/null; then
    warn "Homebrew nicht gefunden – wird installiert..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon Pfad
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null
    eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi
command -v brew &>/dev/null && ok "Homebrew $(brew --version | head -1)" || err "Homebrew Installation fehlgeschlagen"

# ── 2) PHP installieren ───────────────────────────────────────
step 2 "PHP installieren"
if ! command -v php &>/dev/null || ! php -r "new PDO('sqlite::memory:');" &>/dev/null 2>&1; then
    warn "PHP wird installiert/aktualisiert..."
    brew install php
fi
PHP_V=$(php -r 'echo PHP_VERSION;')
ok "PHP $PHP_V"
php -r "new PDO('sqlite::memory:');" &>/dev/null && ok "SQLite verfügbar" || err "SQLite nicht verfügbar"

# ── 3) ZIP suchen + entpacken ────────────────────────────────
step 3 "TurnierOffline installieren"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/TurnierOffline"
ZIP_FILE=""

# ZIP suchen
for loc in "$SCRIPT_DIR" "$HOME/Downloads" "$HOME/Desktop"; do
    f=$(find "$loc" -maxdepth 1 -name "TurnierOffline*.zip" 2>/dev/null | head -1)
    [[ -n "$f" ]] && ZIP_FILE="$f" && break
done

if [[ -z "$ZIP_FILE" ]]; then
    echo -e "  ${RD}✗ TurnierOffline ZIP nicht gefunden!${NC}"
    echo "  Bitte ZIP-Datei in diesen Ordner legen: $SCRIPT_DIR"
    exit 1
fi
ok "ZIP: $ZIP_FILE"

# Sicherung + Entpacken
[[ -d "$INSTALL_DIR" ]] && mv "$INSTALL_DIR" "${INSTALL_DIR}_backup_$(date +%H%M)"
mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Unterordner hochschieben falls nötig
SUB=$(find "$INSTALL_DIR" -maxdepth 1 -name "index.php" 2>/dev/null)
if [[ -z "$SUB" ]]; then
    INNER=$(find "$INSTALL_DIR" -maxdepth 2 -name "index.php" | head -1 | xargs dirname)
    [[ -n "$INNER" && "$INNER" != "$INSTALL_DIR" ]] && \
        mv "$INNER"/* "$INSTALL_DIR/" && rmdir "$INNER" 2>/dev/null
fi
ok "Installiert: $INSTALL_DIR"

# ── 4) Ordner + Berechtigungen ───────────────────────────────
step 4 "Ordner einrichten"
for d in uploads/teams uploads/werbung uploads/qr uploads/regeln database; do
    mkdir -p "$INSTALL_DIR/$d"
done
chmod -R 755 "$INSTALL_DIR"
chmod -R 777 "$INSTALL_DIR/uploads" "$INSTALL_DIR/database" 2>/dev/null
ok "Berechtigungen gesetzt"

# ── 5) Startskript erstellen ─────────────────────────────────
step 5 "Startskript erstellen"
START="$HOME/Desktop/TurnierOffline_starten.sh"
cat > "$START" << 'STARTSCRIPT'
#!/bin/bash
PORT=8080
# Freien Port finden falls 8080 belegt
for P in 8080 8181 9090 7777; do
    lsof -i ":$P" &>/dev/null 2>&1 || { PORT=$P; break; }
done

INSTALL_DIR="$HOME/TurnierOffline"
cd "$INSTALL_DIR"

IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║  🏆  TurnierOffline V14 läuft!              ║"
echo "  ╠══════════════════════════════════════════════╣"
echo "  ║  Admin:     http://localhost:$PORT/admin/"
echo "  ║  Zuschauer: http://$IP:$PORT/mobile/"
echo "  ║  TV:        http://$IP:$PORT/tv/"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  STRG+C zum Beenden"
echo ""

open "http://localhost:$PORT/admin/" 2>/dev/null &
php -S 0.0.0.0:$PORT -t "$INSTALL_DIR"
STARTSCRIPT

chmod +x "$START"
ok "Startskript: $START"

# ── 6) Launchd Service (optional, Auto-Start) ─────────────────
step 6 "Auto-Start einrichten (optional)"
PLIST="$HOME/Library/LaunchAgents/de.turnieroffline.server.plist"
cat > "$PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>de.turnieroffline.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(command -v php)</string>
        <string>-S</string>
        <string>0.0.0.0:8080</string>
        <string>-t</string>
        <string>$INSTALL_DIR</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/turnieroffline.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/turnieroffline.log</string>
</dict>
</plist>
PLIST
launchctl load "$PLIST" 2>/dev/null
ok "LaunchAgent erstellt (deaktiviert – nur bei Bedarf)"

# ── Fertig ───────────────────────────────────────────────────
echo -e "\n${GN}${BD}╔══════════════════════════════════════════════╗
║  ✅  Installation erfolgreich!               ║
╠══════════════════════════════════════════════╣
║  Starten: Doppelklick auf Desktop-Skript    ║
║  Oder: bash ~/Desktop/TurnierOffline_starten.sh
╚══════════════════════════════════════════════╝${NC}\n"

echo -e "  ${OR}Jetzt starten?${NC} [j/n] "
read -r ans
if [[ "$ans" =~ ^[jJyY] ]]; then
    bash "$START"
fi

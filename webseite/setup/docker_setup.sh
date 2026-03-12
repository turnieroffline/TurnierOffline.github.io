#!/bin/bash
# ══════════════════════════════════════════════════════════════
# TurnierOffline V14 – Docker Installer
# Funktioniert auf: Linux, macOS, Windows (WSL/Git Bash)
# Ausführen: bash docker_setup.sh
# ══════════════════════════════════════════════════════════════

OR='\033[38;5;208m'; GN='\033[0;32m'; RD='\033[0;31m'
BL='\033[0;34m'; CY='\033[0;36m'; NC='\033[0m'; BD='\033[1m'

banner() {
  echo -e "\n${OR}${BD}╔══════════════════════════════════════════════════╗
║  🏆  TurnierOffline V14 – Docker Setup          ║
║  Plattform-unabhängig: Windows / Linux / macOS  ║
╚══════════════════════════════════════════════════╝${NC}\n"
}
ok()   { echo -e "  ${GN}✓ $1${NC}"; }
err()  { echo -e "  ${RD}✗ $1${NC}"; exit 1; }
warn() { echo -e "  ${OR}⚠ $1${NC}"; }
info() { echo -e "  ${CY}ℹ $1${NC}"; }
step() { echo -e "\n${BL}${BD}[$1/$TOTAL] $2${NC}"; }
TOTAL=5

banner

# ── 1) Docker prüfen ──────────────────────────────────────────
step 1 "Docker prüfen"
if ! command -v docker &>/dev/null; then
    echo -e "  ${RD}✗ Docker nicht installiert!${NC}"
    echo ""
    echo "  Docker Desktop installieren:"
    echo "  Windows/macOS: https://www.docker.com/products/docker-desktop"
    echo "  Ubuntu:  sudo apt install docker.io docker-compose-plugin"
    echo "  openSUSE: sudo zypper install docker docker-compose"
    echo ""
    echo "  Nach der Installation: Docker Desktop starten, dann dieses Skript erneut."
    exit 1
fi
DOCKER_V=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
ok "Docker $DOCKER_V"

if ! docker info &>/dev/null 2>&1; then
    err "Docker läuft nicht. Docker Desktop starten und erneut versuchen."
fi
ok "Docker läuft"

# Compose prüfen
if docker compose version &>/dev/null 2>&1; then
    ok "Docker Compose (Plugin)"
    COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
    ok "docker-compose"
    COMPOSE="docker-compose"
else
    warn "Docker Compose nicht gefunden – nur 'docker run' verfügbar"
    COMPOSE=""
fi

# ── 2) ZIP suchen ─────────────────────────────────────────────
step 2 "TurnierOffline ZIP suchen"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP_FILE=""

for loc in "$SCRIPT_DIR" "$HOME/Downloads" "$HOME/Desktop" "/tmp"; do
    f=$(find "$loc" -maxdepth 1 -name "TurnierOffline*.zip" 2>/dev/null | head -1)
    [[ -n "$f" ]] && ZIP_FILE="$f" && break
done

if [[ -z "$ZIP_FILE" ]]; then
    echo -e "  ${RD}✗ TurnierOffline ZIP nicht gefunden!${NC}"
    echo "  ZIP-Datei in diesen Ordner legen: $SCRIPT_DIR"
    exit 1
fi
ok "ZIP: $ZIP_FILE"

# ── 3) Entpacken + Dockerfile kopieren ───────────────────────
step 3 "Vorbereiten"
BUILD_DIR="/tmp/turnieroffline_docker_build"
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"

unzip -q "$ZIP_FILE" -d "$BUILD_DIR"

# Unterordner hochschieben
if [[ ! -f "$BUILD_DIR/index.php" ]]; then
    INNER=$(find "$BUILD_DIR" -maxdepth 2 -name "index.php" | head -1 | xargs dirname 2>/dev/null)
    [[ -n "$INNER" && "$INNER" != "$BUILD_DIR" ]] && \
        mv "$INNER"/* "$BUILD_DIR/" && rmdir "$INNER" 2>/dev/null
fi

# Dockerfile kopieren
cp "$SCRIPT_DIR/Dockerfile" "$BUILD_DIR/Dockerfile" 2>/dev/null || \
cat > "$BUILD_DIR/Dockerfile" << 'DOCKERFILE'
FROM php:8.3-cli-alpine
RUN docker-php-ext-install pdo_sqlite && apk add --no-cache curl
WORKDIR /app
COPY . /app/
RUN mkdir -p uploads/teams uploads/werbung uploads/qr uploads/regeln database \
 && chmod -R 777 uploads database
EXPOSE 8080
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app"]
DOCKERFILE

ok "Build-Verzeichnis vorbereitet"

# ── 4) Docker Image bauen ─────────────────────────────────────
step 4 "Docker Image bauen (kann 2-3 Min dauern beim ersten Mal)"
cd "$BUILD_DIR"
docker build -t turnieroffline:v14 . 2>&1 | grep -E "Step|---> |Successfully|Error|FROM|RUN|COPY" || true

if docker image inspect turnieroffline:v14 &>/dev/null 2>&1; then
    ok "Image: turnieroffline:v14"
else
    err "Image-Build fehlgeschlagen. Logs oben prüfen."
fi

# ── 5) Starten ────────────────────────────────────────────────
step 5 "Container starten"

# Alten Container stoppen falls vorhanden
docker stop turnieroffline 2>/dev/null; docker rm turnieroffline 2>/dev/null

# Freien Port finden
PORT=8080
for P in 8080 8181 9090 7777; do
    docker run --rm -d --name test_port_$P -p $P:8080 turnieroffline:v14 &>/dev/null 2>&1 && \
    docker stop test_port_$P &>/dev/null 2>&1 && PORT=$P && break
    docker stop test_port_$P &>/dev/null 2>&1
done

# Persistente Volumes für DB + Uploads
docker run -d \
    --name turnieroffline \
    --restart unless-stopped \
    -p ${PORT}:8080 \
    -v turnieroffline_db:/app/database \
    -v turnieroffline_uploads:/app/uploads \
    turnieroffline:v14

sleep 2
if docker ps --filter name=turnieroffline --filter status=running -q | grep -q .; then
    ok "Container läuft (Port $PORT)"
else
    err "Container-Start fehlgeschlagen: docker logs turnieroffline"
fi

# ── Startskript erstellen ─────────────────────────────────────
START="$SCRIPT_DIR/docker_start.sh"
cat > "$START" << STARTSCRIPT
#!/bin/bash
# TurnierOffline – Docker starten / stoppen
case "\$1" in
    stop)   docker stop turnieroffline; echo "Gestoppt.";;
    logs)   docker logs -f turnieroffline;;
    update)
        docker stop turnieroffline; docker rm turnieroffline
        cd "$BUILD_DIR" && docker build -t turnieroffline:v14 .
        bash "$START"
        ;;
    *)
        docker start turnieroffline 2>/dev/null || \\
        docker run -d --name turnieroffline --restart unless-stopped \\
            -p ${PORT}:8080 \\
            -v turnieroffline_db:/app/database \\
            -v turnieroffline_uploads:/app/uploads \\
            turnieroffline:v14
        IP=\$(hostname -I 2>/dev/null | awk '{print \$1}' || ipconfig getifaddr en0 2>/dev/null || echo "localhost")
        echo ""
        echo "  🏆 TurnierOffline läuft!"
        echo "  Admin:     http://localhost:${PORT}/admin/"
        echo "  Zuschauer: http://\$IP:${PORT}/mobile/"
        echo "  TV:        http://\$IP:${PORT}/tv/"
        echo ""
        ;;
esac
STARTSCRIPT
chmod +x "$START"

# IP ermitteln
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "localhost")

echo -e "\n${GN}${BD}╔══════════════════════════════════════════════╗
║  ✅  Docker-Installation erfolgreich!        ║
╠══════════════════════════════════════════════╣
║  Admin:     http://localhost:$PORT/admin/
║  Zuschauer: http://$IP:$PORT/mobile/
║  TV:        http://$IP:$PORT/tv/
╠══════════════════════════════════════════════╣
║  Stoppen: bash docker_start.sh stop
║  Logs:    bash docker_start.sh logs
║  Update:  bash docker_start.sh update
╚══════════════════════════════════════════════╝${NC}\n"

# Browser öffnen
sleep 1
xdg-open "http://localhost:$PORT/admin/" 2>/dev/null || \
    open "http://localhost:$PORT/admin/" 2>/dev/null || \
    start "http://localhost:$PORT/admin/" 2>/dev/null || true

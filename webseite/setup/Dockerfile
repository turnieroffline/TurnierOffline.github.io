FROM php:8.3-cli-alpine

# Minimales Image - kein Apache, nur PHP built-in Server
# Alpine = 50MB statt 300MB+ bei full PHP

# PHP Extensions
RUN docker-php-ext-install pdo_sqlite \
 && apk add --no-cache curl unzip

# Arbeitsverzeichnis
WORKDIR /app

# App-Dateien kopieren
COPY . /app/

# Upload + DB Ordner
RUN mkdir -p uploads/teams uploads/werbung uploads/qr uploads/regeln database \
 && chmod -R 777 uploads database

# Port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
  CMD curl -f http://localhost:8080/mobile/ping.php || exit 1

# Starten
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app"]

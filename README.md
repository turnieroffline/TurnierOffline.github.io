# 🏆 TurnierOffline

**Kostenloses Turnierverwaltungssystem — offline, lokal, ohne Cloud.**

[![Version](https://img.shields.io/badge/Version-V16-brightgreen)](https://github.com/turnieroffline/TurnierOffline.github.io)
[![Lizenz](https://img.shields.io/badge/Lizenz-Open%20Source-blue)](https://github.com/turnieroffline/TurnierOffline.github.io/blob/main/LICENSE.txt)
[![Ko-fi](https://img.shields.io/badge/Support-Ko--fi-ff5e5b?logo=ko-fi)](https://ko-fi.com/turnieroffline)
[![Plattform](https://img.shields.io/badge/Plattform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey)]()

> Dein Gerät wird zum Turnierserver. Live-Stände, TV-Anzeige, KI-Assistent — kein Konto, kein Abo, keine Cloud.

---

## 📸 Vorschau

| TV-Anzeige | Handy-App | Admin |
|---|---|---|
| *(Screenshot einfügen)* | *(Screenshot einfügen)* | *(Screenshot einfügen)* |

---

## ✨ Features

- 📺 **TV-Anzeige** — Automatischer Seitenwechsel mit Spielstand, KO-Bracket, Tabelle und Werbung
- ⚽ **Live-Eingabe** — Tore, Karten, Auswechslungen in Echtzeit — ein Tipp und alle sehen es sofort
- 📱 **Handy-App** — Zuschauer verbinden sich per QR-Code, PWA, kein Download nötig
- 🏆 **KO-Runden** — Losziehung per Knopfdruck, automatischer Spielbaum
- 🤖 **KI-Assistent** — „Wer spielt gerade?" — regelbasiert oder via Ollama, auch komplett offline
- 🔊 **Sprachansagen** — Automatische Text-to-Speech-Ansagen bei Toren, Karten, Halbzeit
- 🏟 **Multi-Feld** — Bis zu 4 Felder parallel, TV zeigt Split-Screen
- 🎯 **Wetten-Spiel** — Zuschauer Wetten Ergebnisse, Live-Rangliste *(neu in V16)*
- 🌐 **GitHub Sync** — Nach jedem Tor automatisch auf GitHub Pages gepusht
- 🔌 **WordPress-Plugin** — Live-Stand direkt auf der Vereinswebseite einbetten
- 🏅 **Siegerehrung** — Automatisches Podest, Export als HTML

---

## 📵 100% Offline — wirklich

- Kein Konto, kein Abo, kein Ablaufdatum
- Keine Cloud, keine Telemetrie, kein Update-Checking
- Alle Daten bleiben lokal in einer SQLite-Datenbank
- Internet nur **optional** für GitHub Sync

---

## 📦 Installation

> **Standard-Passwort nach der Installation: `admin123` — bitte sofort nach dem ersten Login ändern!**

---

### 🪟 Windows

**Voraussetzung:** Windows 10 oder 11

**Schritt 1 — XAMPP installieren** *(falls noch nicht vorhanden)*
1. [XAMPP herunterladen](https://www.apachefriends.org/) und installieren
2. Nur PHP wird benötigt — Apache und MySQL müssen nicht laufen

**Schritt 2 — TurnierOffline herunterladen**
1. ZIP-Datei aus dem [Releases-Bereich](https://github.com/turnieroffline/TurnierOffline.github.io/releases) herunterladen
2. ZIP in einen beliebigen Ordner entpacken (z.B. `C:\TurnierOffline\`)

**Schritt 3 — Starten**
1. In den entpackten Ordner wechseln
2. `start_windows.bat` per **Doppelklick** starten
3. Windows-Firewall-Abfrage mit **"Zugriff erlauben"** bestätigen
4. Der Browser öffnet sich automatisch auf `http://localhost:8080/admin/`

**Zugriff für andere Geräte im WLAN:**
- Alle Geräte müssen im selben WLAN sein
- Adresse für Zuschauer/TV: `http://[DEINE-IP]:8080/mobile/` bzw. `/tv/`
- Deine IP wird beim Start im Konsolenfenster angezeigt

---

### 🐧 Linux (Ubuntu, Debian, openSUSE)

**Voraussetzung:** Ubuntu 20.04+ / Debian 11+ / openSUSE Leap 15+

**Schritt 1 — ZIP herunterladen**
```bash
# ZIP aus dem Releases-Bereich herunterladen und in den Download-Ordner legen
# https://github.com/turnieroffline/TurnierOffline.github.io/releases
```

**Schritt 2 — Setup starten**
```bash
bash linux_setup.sh
```

Das Script erledigt automatisch:
- PHP + benötigte Erweiterungen installieren (apt / zypper / dnf)
- ZIP entpacken und Ordnerrechte setzen
- IP-Adresse ermitteln
- PHP-Server auf Port 8080 starten

**Schritt 3 — Als Systemdienst (optional, für Dauerbetrieb)**
```bash
sudo systemctl enable --now turnieroffline
```

Nützliche Befehle:
```bash
sudo systemctl start turnieroffline    # Starten
sudo systemctl stop turnieroffline     # Stoppen
sudo journalctl -u turnieroffline -f   # Logs anzeigen
```

**Nach dem Start erreichbar unter:**
- Admin: `http://localhost:8080/admin/`
- TV: `http://localhost:8080/tv/`
- Zuschauer: `http://[IP]:8080/mobile/`

---

### 🤖 Android (Termux)

**Voraussetzung:** Android 7.0+, ca. 300 MB freier Speicher

**Schritt 1 — Termux installieren**
1. [Termux von F-Droid installieren](https://f-droid.org/packages/com.termux/) *(empfohlen, nicht aus dem Play Store)*
2. Termux öffnen

**Schritt 2 — ZIP herunterladen**
1. ZIP-Datei aus dem [Releases-Bereich](https://github.com/turnieroffline/TurnierOffline.github.io/releases) herunterladen
2. ZIP in den **Download-Ordner** des Handys legen

**Schritt 3 — Setup starten**
```bash
bash termux_setup.sh
```

Das Script erledigt automatisch:
- Pakete aktualisieren
- PHP + SQLite installieren
- Speicherzugang einrichten *(Android-Dialog erscheint — "Erlauben" antippen)*
- ZIP suchen und entpacken nach `/storage/emulated/0/TurnierOffline/`
- PHP-Server auf Port 8080 starten
- QR-Code für die Handy-App anzeigen *(falls qrencode installiert)*

**Wichtige Hinweise für Android:**
- ⚠️ Akku im Auge behalten — PHP-Server läuft dauerhaft
- ⚠️ "Über anderen Apps anzeigen" ggf. für Termux erlauben
- ⚠️ WLAN-Hotspot des Handys für andere Geräte verwenden
- ✗ TV-Anzeige via HDMI nicht unterstützt
- ✗ KI / Ollama nicht unterstützt (zu wenig RAM)

---

### 🐳 Docker

**Voraussetzung:** Docker Engine 20+

```bash
docker run -p 8080:80 turnieroffline/turnieroffline
```

Danach erreichbar unter `http://localhost:8080/admin/`

---

## 🖥 Plattform-Übersicht

| Feature | Android | Windows | Linux | Docker |
|---|:---:|:---:|:---:|:---:|
| 📺 TV-Anzeige (HDMI) | ✗ | ✓ | ✓ | ✓ |
| 🤖 KI / Ollama | ✗ | ✓ | ✓ | ✓ |
| 🔄 GitHub Sync | ✓ | ✓ | ✓ | ✓ |
| 🔊 Sprachansagen | ✓ | ✓ | ✓ | ⚠ |
| 🐳 Docker | ✗ | ✓ | ✓ | ✓ |
| 📡 DHCP / DNS | ⚠ | ⚠ | ✓ | ⚠ |
| 📶 Hotspot | ✓ | ✓ | ✓ | ⚠ |

---

## 🧰 Technisches

- **88** PHP-Dateien · **35** Datenbanktabellen
- **0** externe Abhängigkeiten · **0** Pflicht-Internet
- PHP 8.0+ · SQLite 3 · kein Composer, kein npm

---

## 🐛 Bugs & Feedback

Fehler gefunden oder Verbesserungsidee?
→ [Issue erstellen](https://github.com/turnieroffline/TurnierOffline.github.io/issues)
→ Oder per E-Mail: turnieroffline@gmail.com

Pull Requests sind willkommen!

---

## 👋 Über das Projekt

Beim Organisieren unseres Vereinsturniers habe ich gemerkt: Es gibt keine Software die wirklich offline läuft, kostenlos ist, und trotzdem eine vernünftige TV-Anzeige hat. Also habe ich TurnierOffline gebaut — für unseren eigenen Verein, an Wochenenden und Abenden.

Inzwischen ist es **V16** geworden, mit KI-Assistent, Tipp-Spiel, Sprachansagen und lokalem Betrieb ohne Cloud-Zwang.

Das Projekt ist kein kommerzielles Produkt und wird es auch nicht werden.

*Hobbyprojekt von Tobias · turnieroffline@gmail.com*

---

## ☕ Projekt unterstützen

TurnierOffline ist kostenlos und bleibt es. Keine Werbung, kein Abo, keine versteckten Kosten.

Wer das Projekt bei einem Turnier nutzt und möchte, kann einen Kaffee spendieren — vollkommen freiwillig, einmalig, kein Abo.

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/turnieroffline)

---

*Copyright © 2024–2026 Tobias · Privates Hobbyprojekt · Kein kommerzielles Produkt*

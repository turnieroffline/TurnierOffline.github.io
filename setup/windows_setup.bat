@echo off
REM ══════════════════════════════════════════════════════════════════
REM  TurnierOffline V16 — Windows Starter (mit XAMPP)
REM  Doppelklick auf diese Datei zum Starten
REM ══════════════════════════════════════════════════════════════════
title TurnierOffline V16 – Windows Setup

echo.
echo   ============================================================
echo     TurnierOffline V16 -- Windows Setup
echo   ============================================================
echo.

REM PHP suchen
set PHP_EXE=
for %%p in (
  "C:\xampp\php\php.exe"
  "C:\php\php.exe"
  "C:\Program Files\PHP\php.exe"
) do (
  if exist %%p (
    set PHP_EXE=%%p
    goto :found_php
  )
)

echo   [!] PHP nicht gefunden.
echo.
echo   Bitte XAMPP herunterladen und installieren:
echo   https://www.apachefriends.org/
echo.
echo   Danach dieses Skript erneut starten.
pause
exit /b 1

:found_php
echo   [OK] PHP gefunden: %PHP_EXE%
echo.

REM Uploads-Ordner erstellen
if not exist "uploads\werbung" mkdir "uploads\werbung"
if not exist "uploads\regeln" mkdir "uploads\regeln"

REM IP-Adresse ermitteln
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  set IP=%%a
  goto :got_ip
)
:got_ip
set IP=%IP: =%

echo   ============================================================
echo     TurnierOffline V16 ist bereit!
echo   ============================================================
echo.
echo   Admin:   http://%IP%:8080/admin/
echo   TV:      http://%IP%:8080/tv/
echo   Handy:   http://%IP%:8080/mobile/
echo.
echo   Passwort: admin123  (bitte sofort aendern!)
echo   Zum Beenden: dieses Fenster schliessen
echo.

start http://localhost:8080/admin/
%PHP_EXE% -S 0.0.0.0:8080 -t .
pause

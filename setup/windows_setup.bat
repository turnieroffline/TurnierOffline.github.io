@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion

:: ══════════════════════════════════════════════════════════════
:: TurnierOffline V14 – Windows Installer (XAMPP)
:: Doppelklick auf diese Datei → alles wird automatisch eingerichtet
:: ══════════════════════════════════════════════════════════════

title TurnierOffline V14 – Windows Setup

set "OR=[93m"
set "GN=[92m"
set "RD=[91m"
set "BL=[94m"
set "NC=[0m"
set "BD=[1m"

echo.
echo  %OR%%BD%╔══════════════════════════════════════════════╗
echo  ║  🏆  TurnierOffline V14 – Windows Setup     ║
echo  ╚══════════════════════════════════════════════╝%NC%
echo.

:: ── Administratorrechte prüfen ──────────────────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo  %RD%✗ Bitte als Administrator ausführen!%NC%
    echo    Rechtsklick auf die .bat-Datei → "Als Administrator ausführen"
    pause
    exit /b 1
)

:: ── XAMPP prüfen / Pfad finden ──────────────────────────────────
echo  %BL%[1/5] XAMPP suchen...%NC%
set "XAMPP="
if exist "C:\xampp\php\php.exe"        set "XAMPP=C:\xampp"
if exist "C:\XAMPP\php\php.exe"        set "XAMPP=C:\XAMPP"
if exist "D:\xampp\php\php.exe"        set "XAMPP=D:\xampp"
if exist "%ProgramFiles%\xampp\php\php.exe" set "XAMPP=%ProgramFiles%\xampp"

if "%XAMPP%"=="" (
    echo  %RD%✗ XAMPP nicht gefunden!%NC%
    echo.
    echo  Bitte zuerst XAMPP installieren:
    echo    1. https://www.apachefriends.org/de/index.html
    echo    2. XAMPP installieren ^(Standard: C:\xampp^)
    echo    3. Danach dieses Skript erneut ausführen
    echo.
    echo  %OR%Tipp: XAMPP-Installer nach Download einfach durchklicken.%NC%
    pause
    exit /b 1
)
echo  %GN%✓ XAMPP gefunden: %XAMPP%%NC%

set "PHP=%XAMPP%\php\php.exe"
set "HTDOCS=%XAMPP%\htdocs"

:: ── PHP Version prüfen ──────────────────────────────────────────
echo  %BL%[2/5] PHP prüfen...%NC%
"%PHP%" -r "echo PHP_VERSION;" >nul 2>&1
if %errorLevel% neq 0 (
    echo  %RD%✗ PHP funktioniert nicht. XAMPP korrekt installiert?%NC%
    pause
    exit /b 1
)
for /f "delims=" %%v in ('"%PHP%" -r "echo PHP_VERSION;"') do set PHP_VER=%%v
echo  %GN%✓ PHP %PHP_VER%%NC%

:: SQLite prüfen
"%PHP%" -r "new PDO('sqlite::memory:');" >nul 2>&1
if %errorLevel% neq 0 (
    echo  %RD%✗ PHP SQLite nicht verfügbar.%NC%
    echo    In %XAMPP%\php\php.ini: extension=pdo_sqlite aktivieren
    pause
    exit /b 1
)
echo  %GN%✓ SQLite verfügbar%NC%

:: ── TurnierOffline installieren ─────────────────────────────────
echo  %BL%[3/5] TurnierOffline einrichten...%NC%

set "INSTALL_DIR=%HTDOCS%\TurnierOffline"

:: ZIP suchen (aktuelles Verzeichnis oder Downloads)
set "ZIP_FILE="
set "SCRIPT_DIR=%~dp0"
for %%f in ("%SCRIPT_DIR%TurnierOffline*.zip") do set "ZIP_FILE=%%f"
if "%ZIP_FILE%"=="" (
    for %%f in ("%USERPROFILE%\Downloads\TurnierOffline*.zip") do set "ZIP_FILE=%%f"
)
if "%ZIP_FILE%"=="" (
    for %%f in ("%USERPROFILE%\Desktop\TurnierOffline*.zip") do set "ZIP_FILE=%%f"
)

if "%ZIP_FILE%"=="" (
    echo  %RD%✗ TurnierOffline ZIP nicht gefunden!%NC%
    echo    ZIP-Datei in diesen Ordner legen und erneut ausführen:
    echo    %SCRIPT_DIR%
    echo    Oder in: Downloads / Desktop
    pause
    exit /b 1
)
echo  %GN%✓ ZIP gefunden: %ZIP_FILE%%NC%

:: Entpacken
if exist "%INSTALL_DIR%" (
    echo  %OR%→ Vorhandene Installation wird gesichert...%NC%
    if exist "%INSTALL_DIR%_backup" rmdir /s /q "%INSTALL_DIR%_backup"
    move "%INSTALL_DIR%" "%INSTALL_DIR%_backup" >nul
)
mkdir "%INSTALL_DIR%" >nul 2>&1

:: PowerShell zum Entpacken nutzen (in Windows 10+ eingebaut)
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force" >nul 2>&1
if %errorLevel% neq 0 (
    echo  %RD%✗ Entpacken fehlgeschlagen!%NC%
    pause
    exit /b 1
)

:: Falls ZIP einen Unterordner enthält, Dateien hochschieben
for /d %%d in ("%INSTALL_DIR%\*") do (
    if exist "%%d\index.php" (
        xcopy "%%d\*" "%INSTALL_DIR%\" /e /y /q >nul
        rmdir /s /q "%%d"
    )
)
echo  %GN%✓ Dateien installiert: %INSTALL_DIR%%NC%

:: ── Uploads-Ordner + Berechtigungen ────────────────────────────
echo  %BL%[4/5] Ordner einrichten...%NC%
for %%d in (uploads uploads\teams uploads\werbung uploads\qr uploads\regeln database) do (
    if not exist "%INSTALL_DIR%\%%d" mkdir "%INSTALL_DIR%\%%d"
)
:: Schreibrechte setzen
icacls "%INSTALL_DIR%" /grant "IIS_IUSRS:(OI)(CI)F" /T /Q >nul 2>&1
icacls "%INSTALL_DIR%" /grant "IUSR:(OI)(CI)F" /T /Q >nul 2>&1
icacls "%INSTALL_DIR%" /grant "Everyone:(OI)(CI)F" /T /Q >nul 2>&1
echo  %GN%✓ Ordner und Berechtigungen gesetzt%NC%

:: ── Startskript erstellen ───────────────────────────────────────
echo  %BL%[5/5] Startskript erstellen...%NC%

:: start_turnier.bat auf Desktop
set "START_SCRIPT=%USERPROFILE%\Desktop\TurnierOffline starten.bat"
(
echo @echo off
echo chcp 65001 ^>nul
echo title TurnierOffline V14
echo.
echo :: XAMPP Apache starten falls nötig
echo net start Apache2.4 ^>nul 2^>^&1
echo.
echo :: IP-Adresse ermitteln
echo for /f "tokens=2 delims=:" %%%%a in ^('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"'^) do set IP=%%%%a
echo set IP=%%IP: =%%
echo.
echo echo.
echo echo  ╔══════════════════════════════════════════════╗
echo echo  ║  🏆  TurnierOffline läuft!                   ║
echo echo  ╠══════════════════════════════════════════════╣
echo echo  ║  Admin:     http://localhost/TurnierOffline/admin/
echo echo  ║  Zuschauer: http://%%IP%%/TurnierOffline/mobile/
echo echo  ║  TV:        http://%%IP%%/TurnierOffline/tv/
echo echo  ╚══════════════════════════════════════════════╝
echo echo.
echo echo  QR-Code erstellen: Admin ^> QR-Codes
echo echo  IP für Zuschauer:  %%IP%%
echo echo.
echo start http://localhost/TurnierOffline/admin/
echo pause
) > "%START_SCRIPT%"

echo  %GN%✓ Desktop-Verknüpfung erstellt%NC%

:: ── Apache starten ──────────────────────────────────────────────
echo.
echo  %OR%→ Starte Apache...%NC%
net start Apache2.4 >nul 2>&1
"%XAMPP%\apache\bin\httpd.exe" -k start >nul 2>&1

:: ── Fertig ──────────────────────────────────────────────────────
echo.
echo  %GN%%BD%╔══════════════════════════════════════════════╗
echo  ║  ✅  Installation erfolgreich!               ║
echo  ╠══════════════════════════════════════════════╣
echo  ║  Admin:  http://localhost/TurnierOffline/admin/
echo  ╚══════════════════════════════════════════════╝%NC%
echo.
echo  %OR%Desktop-Verknüpfung: "TurnierOffline starten.bat"%NC%
echo  %BL%Installiert in: %INSTALL_DIR%%NC%
echo.

:: Browser öffnen
timeout /t 2 /nobreak >nul
start http://localhost/TurnierOffline/admin/

pause

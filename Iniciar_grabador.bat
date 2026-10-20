@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
TITLE Mi Grabador v3 - Panel de control
color 0A
cd /d "%~dp0"

:: Página pública (GitHub Pages). El invitado entra aquí, sin ngrok.
set "PUBLICA=https://jhonnyvasquez240973-coder.github.io/tuusuario.github.io/"

echo ========================================================
echo   INICIANDO MI GRABADOR v3 (videollamada + chat)
echo ========================================================
echo.

:: ---------- 1. Código de sala aleatorio ----------
:: Tu navegador crea esta sala solo y la invitación ya la incluye.
set "ABC=ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
set "SALA="
for /L %%i in (1,1,6) do (
  set /a "N=!RANDOM! %% 32"
  for %%n in (!N!) do set "SALA=!SALA!!ABC:~%%n,1!"
)
set "INVITACION=!PUBLICA!?sala=!SALA!#sala=!SALA!"

:: ---------- 2. ¿Está en línea la página pública? ----------
echo [1/3] Comprobando la página en línea ...
set "MODO=local"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-WebRequest -Uri '%PUBLICA%' -UseBasicParsing -Method Head -TimeoutSec 8; if ($r.StatusCode -lt 400) { exit 0 } else { exit 1 } } catch { exit 1 }"
if not errorlevel 1 set "MODO=publico"

if "!MODO!"=="publico" (
  echo       En línea: !PUBLICA!
  echo [2/3] Abriendo el navegador con la sala !SALA! ...
  start "" "!PUBLICA!?crear=!SALA!"
  goto :invitar
)

:: ---------- 3. Respaldo: servidor local ----------
echo       No se pudo abrir la página en línea; uso el servidor local.
set "HTML="
if exist "index.html" set "HTML=index.html"
if not defined HTML if exist "grabador.html" set "HTML=grabador.html"
if not defined HTML for %%F in ("grabador*.html" "*.html") do if not defined HTML set "HTML=%%~nxF"
if not defined HTML (
  echo [ERROR] No hay conexión con la página en línea y no encuentro
  echo         ningún .html en esta carpeta: !CD!
  echo         Revisa tu internet o copia "index.html" junto a este .bat.
  goto :fin_error
)
set "PAGINA=!HTML: =%%20!"

set "PY="
py -3 --version >nul 2>&1 && set "PY=py -3"
if not defined PY python --version >nul 2>&1 && set "PY=python"
if not defined PY (
  echo [ERROR] No encuentro Python. Instálalo desde https://www.python.org/downloads/
  echo         y marca "Add python.exe to PATH" durante la instalación.
  goto :fin_error
)

netstat -ano | findstr /R /C:":8000 .*LISTENING" >nul
if not errorlevel 1 (
  echo [ERROR] El puerto 8000 ya está en uso. ¿Tienes otra ventana del grabador abierta?
  goto :fin_error
)

echo [2/3] Iniciando servidor local en http://localhost:8000 ...
start "Grabador - Servidor" /min cmd /c %PY% -m http.server 8000 --bind 127.0.0.1
timeout /t 2 >nul
start "" "http://localhost:8000/!PAGINA!?crear=!SALA!"

:invitar
echo !INVITACION!| clip
echo.
echo ========================================================
echo   TODO LISTO - Sala creada: !SALA!
echo.
echo   ENLACE DE INVITACIÓN (ya copiado al portapapeles):
echo   !INVITACION!
echo.
echo   Tu invitado solo abre el enlace y permite cámara y
echo   micrófono: se conecta solo a la videollamada y al chat.
echo ========================================================
echo.

:: ---------- 4. Enviar invitación ----------
set "MSG=Hola, te invito a una videollamada con chat en Mi Grabador. Abre este enlace y permite la cámara y el micrófono: !INVITACION! (Código de sala: !SALA!)"
:menu
echo [3/3] ¿Cómo quieres enviar la invitación?
echo       [W] WhatsApp    [C] Correo    [N] Ninguno (ya está copiada)
choice /C WCN /N /M "      Elige W, C o N: "
if errorlevel 3 goto :esperar
if errorlevel 2 goto :correo
if errorlevel 1 goto :whatsapp

:whatsapp
set "TEL="
set /p "TEL=      Número con código de país (Enter = elegir contacto en WhatsApp): "
if defined TEL set "TEL=!TEL: =!"
if defined TEL set "TEL=!TEL:+=!"
if defined TEL set "TEL=!TEL:-=!"
powershell -NoProfile -Command ^
  "$t=[uri]::EscapeDataString($env:MSG); Start-Process ('https://wa.me/' + $env:TEL + '?text=' + $t)"
echo       WhatsApp abierto: solo pulsa Enviar.
echo.
goto :menu

:correo
set "MAIL="
set /p "MAIL=      Correo del invitado (Enter = escribirlo después): "
if defined MAIL set "MAIL=!MAIL: =!"
powershell -NoProfile -Command ^
  "$s=[uri]::EscapeDataString('Invitación a videollamada - sala ' + $env:SALA); $b=[uri]::EscapeDataString($env:MSG); Start-Process ('mailto:' + $env:MAIL + '?subject=' + $s + '&body=' + $b)"
echo       Programa de correo abierto con la invitación.
echo.
goto :menu

:esperar
echo.
echo ========================================================
if "!MODO!"=="local" (
  echo   Servidor local activo. Pulsa cualquier tecla para APAGARLO.
  pause >nul
  taskkill /FI "WINDOWTITLE eq Grabador - Servidor*" /T /F >nul 2>&1
  echo Servidor apagado.
) else (
  echo   La llamada sigue en tu navegador. Puedes cerrar esta ventana.
  pause >nul
)
exit /b 0

:fin_error
echo.
pause
exit /b 1

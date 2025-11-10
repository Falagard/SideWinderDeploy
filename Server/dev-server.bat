@echo off
echo SideWinder Deploy Server - Development Mode
echo.
echo This will rebuild and restart the server when you press Enter.
echo Press Ctrl+C to exit.
echo.

:loop
echo.
echo Building...
lime build hl

if %ERRORLEVEL% NEQ 0 (
    echo Build failed! Fix errors and press Enter to try again...
    pause > nul
    goto loop
)

echo Build successful! Starting server...
echo Press Ctrl+C to stop server, then Enter to rebuild and restart.
echo.

start /B Export\hl\bin\SideWinderServer.exe

pause > nul

REM Kill the running server
taskkill /F /IM SideWinderServer.exe > nul 2>&1

goto loop

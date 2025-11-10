@echo off
echo Building SideWinder Deploy Server...
echo.

REM Build the project
lime build hl

REM Check if build was successful
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed! Please check the errors above.
    pause
    exit /b 1
)

echo.
echo Build successful!
echo.

REM Run the server
call run-server.bat

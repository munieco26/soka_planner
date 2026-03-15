@echo off
echo ========================================
echo  Agenda SGIAR - Web Deployment
echo ========================================
echo.

echo Building for web with base-href /app/agenda/...
call flutter build web --base-href /app/agenda/

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Build Complete!
echo ========================================
echo.
echo Your app is ready to deploy from:
echo   build\web\
echo.
echo Deploy to:
echo   domain.com/app/agenda/
echo.
echo See deploy.md for detailed instructions
echo.
pause


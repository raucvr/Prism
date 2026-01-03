@echo off
chcp 65001 >nul
title Prism AI

echo Starting Prism AI...
echo.

:: Find available backend port (start from 8000)
set BACKEND_PORT=8000
:find_backend_port
netstat -an | findstr ":%BACKEND_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo Port %BACKEND_PORT% is in use, trying next...
    set /a BACKEND_PORT+=1
    if %BACKEND_PORT% gtr 8010 (
        echo ERROR: No available port found for backend ^(8000-8010^)
        pause
        exit /b 1
    )
    goto find_backend_port
)
echo Backend will use port: %BACKEND_PORT%

:: Find available frontend port (start from 3000)
set FRONTEND_PORT=3000
:find_frontend_port
netstat -an | findstr ":%FRONTEND_PORT% " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo Port %FRONTEND_PORT% is in use, trying next...
    set /a FRONTEND_PORT+=1
    if %FRONTEND_PORT% gtr 3010 (
        echo ERROR: No available port found for frontend ^(3000-3010^)
        pause
        exit /b 1
    )
    goto find_frontend_port
)
echo Frontend will use port: %FRONTEND_PORT%
echo.

:: Start backend with dynamic port
start "Prism Backend" cmd /k "cd /d "%~dp0backend" && python -m uvicorn main:app --reload --host 0.0.0.0 --port %BACKEND_PORT%"

:: Wait for backend to start
timeout /t 3 /nobreak >nul

:: Create .env.local with dynamic backend URL
echo NEXT_PUBLIC_API_URL=http://localhost:%BACKEND_PORT%> "%~dp0frontend\.env.local"

:: Start frontend with dynamic port
start "Prism Frontend" cmd /k "cd /d "%~dp0frontend" && npm run dev -- -p %FRONTEND_PORT%"

:: Wait for services
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo   Prism AI Started!
echo ========================================
echo   Frontend: http://localhost:%FRONTEND_PORT%
echo   Backend:  http://localhost:%BACKEND_PORT%
echo ========================================
echo.

:: Open browser
start http://localhost:%FRONTEND_PORT%

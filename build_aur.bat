@echo off
REM Quick build script for Nexus OS AUR packages (Windows batch)
REM Usage: build_aur.bat [output_dir]

setlocal enabledelayedexpansion

if "%1"=="" (
    set OUTPUT_DIR=build_output
) else (
    set OUTPUT_DIR=%1
)

echo =========================================
echo Nexus OS AUR Package Builder (Windows)
echo =========================================
echo.
echo Output directory: %OUTPUT_DIR%
echo.

REM Check if bash/git bash is available
where bash >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: bash not found. Please install:
    echo   - Git for Windows (includes bash)
    echo   - Or WSL2 with a Linux distribution
    echo.
    pause
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%OUTPUT_DIR%\packages" mkdir "%OUTPUT_DIR%\packages"
if not exist "%OUTPUT_DIR%\logs" mkdir "%OUTPUT_DIR%\logs"

echo [1/2] Running build script...
bash scripts/build_aur_local.sh %OUTPUT_DIR%

if %errorlevel% equ 0 (
    echo.
    echo [2/2] Build complete!
    echo.
    echo Artifacts in: %OUTPUT_DIR%\packages\
    dir /b "%OUTPUT_DIR%\packages\"
    echo.
    echo Logs in: %OUTPUT_DIR%\logs\
    echo.
    pause
) else (
    echo.
    echo ERROR: Build failed. Check logs:
    echo   %OUTPUT_DIR%\logs\
    echo.
    pause
    exit /b 1
)

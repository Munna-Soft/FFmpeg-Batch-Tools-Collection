@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Smart Audio Noise Remover - by Munna MasterMind

REM --- Base directory ---
set "BASE_DIR=%~dp0"
set "FFMPEG_DIR=%BASE_DIR%FFmpeg"

REM --- FFmpeg/FFprobe/FFplay binaries check ---
if not exist "%FFMPEG_DIR%\ffmpeg.exe" (
    echo [ERROR] ffmpeg.exe not found in "FFmpeg" folder!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffprobe.exe" (
    echo [ERROR] ffprobe.exe not found in "FFmpeg" folder!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffplay.exe" (
    echo [ERROR] ffplay.exe not found in "FFmpeg" folder!
    pause
    exit /b
)

REM --- Use local FFmpeg ---
set "FFMPEG=%FFMPEG_DIR%\ffmpeg.exe"

REM --- Folder paths ---
set "AUDIOS_DIR=%BASE_DIR%Audios"
set "OUTPUT_DIR=%BASE_DIR%Output"

REM --- Create Audios folder if missing ---
if not exist "%AUDIOS_DIR%" (
    echo.
    echo [INFO] Creating "Audios" folder...
    mkdir "%AUDIOS_DIR%"
    echo.
    echo Please put your audio files inside the "Audios" folder and run again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║  Smart Audio Noise Remover by - Munna MasterMind  ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- Detect audio files ---
echo ====== Available Audios ======
set i=0
for %%E in (mp3 wav m4a flac aac ogg wma opus) do (
    for %%f in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "audio[!i!]=%%~nxf"
            echo    !i! = %%~nxf
        )
    )
)

if %i%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    echo.
    echo Supported extensions: mp3 wav m4a flac aac ogg wma opus
    echo.
    pause
    exit /b
)

if %i%==1 (
    echo.
    echo Only one audio file found → Selecting automatically...
    set sel=1
    goto noise_level
)
echo ==================================================
echo.

set /p sel="Enter audio number to process (0 for All): "

REM --- Replace + with space (loop format) ---
set sel=%sel:+= %

REM --- If 0 → select all ---
if "%sel%"=="0" (
    echo 0 = Select All Audios
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

REM --- Validate selection ---
:noise_level
echo.
echo ====== Select Noise Reduction Level ======
echo    1 = LOW     Noise Reduction
echo    2 = MEDIUM  Noise Reduction
echo    3 = HIGH    Noise Reduction
echo =============================================================
echo.
set /p lvl="Select reduction quality (1-3): "

if "%lvl%"=="1" set NR=afftdn=nr=6:nf=-25
if "%lvl%"=="2" set NR=afftdn=nr=12:nf=-35
if "%lvl%"=="3" set NR=afftdn=nr=20:nf=-45

if "%NR%"=="" (
    echo Invalid selection.
    pause
    exit /b
)

echo.
set /p outputname="Enter output base name (default: CleanAudio): "
if "%outputname%"=="" set outputname=CleanAudio

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo Processing audio files... Please wait.
echo --------------------------------------------------

set count=0
for %%n in (%sel%) do (
    set "f=!audio[%%n]!"
    if defined f (
        set /a count+=1
        echo.
        echo Cleaning Noise From: !f!
        
        "%FFMPEG%" -y -i "%AUDIOS_DIR%\!f!" ^
        -af "%NR%" ^
        "%OUTPUT_DIR%\%outputname%_!count!.mp3"
    )
)

echo.
echo =============================================================
echo    ✅ All Audio Files Have Been Noise-Reduced!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo =============================================================
echo.
pause
exit /b
REM --- Code by Munna MasterMind ---
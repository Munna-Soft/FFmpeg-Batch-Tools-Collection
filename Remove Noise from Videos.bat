@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Smart Video Noise Remover - by Munna MasterMind

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
set "VIDEOS_DIR=%BASE_DIR%Videos"
set "OUTPUT_DIR=%BASE_DIR%Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo.
    echo [INFO] Creating "Videos" folder...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your video files inside the "Videos" folder and run again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║  Smart Video Noise Remover by - Munna MasterMind  ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- Detect video files ---
echo ====== Available Videos ======
set i=0
for %%E in (mp4 mkv avi mov flv wmv mpg mpeg webm) do (
    for %%f in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "video[!i!]=%%~nxf"
            echo 	!i! = %%~nxf
        )
    )
)

if %i%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported extensions: mp4 mkv avi mov flv wmv mpg mpeg webm
    echo.
    pause
    exit /b
)

if %i%==1 (
    echo.
    echo Only one video found → Selecting automatically...
    set sel=1
    goto noise_level
)
echo ==================================================
echo.

set /p sel="Enter video number to process (0 for All): "

REM replace + with space for loop-friendly format
set sel=%sel:+= %

REM If 0 → select all
if "%sel%"=="0" (
    echo 0 = Select All Videos
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

REM --- Validate selection ---
:noise_level
echo.
echo ====== Select Noise Reduction Level ======
echo 	1 = LOW    	Noise Reduction
echo 	2 = MEDIUM 	Noise Reduction
echo 	3 = HIGH   	Noise Reduction
echo =============================================================
echo.
set /p lvl="Select reduction quality (1-3): "

if "%lvl%"=="1" set NR=vaguedenoiser=threshold=3
if "%lvl%"=="2" set NR=vaguedenoiser=threshold=6
if "%lvl%"=="3" set NR=vaguedenoiser=threshold=12

if "%NR%"=="" (
    echo Invalid selection.
    pause
    exit /b
)

echo.
set /p outputname="Enter output base name (default: CleanVideo): "
if "%outputname%"=="" set outputname=CleanVideo

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo Processing videos... Please wait.
echo --------------------------------------------------

set count=0
for %%n in (%sel%) do (
    set "f=!video[%%n]!"
    if defined f (
        set /a count+=1
        echo.
        echo Cleaning Noise From: !f!

        "%FFMPEG%" -y -i "%VIDEOS_DIR%\!f!" ^
        -vf "%NR%" ^
        -c:v libx264 -preset ultrafast -crf 25 ^
        -af "highpass=f=200, lowpass=f=3000" ^
        "%OUTPUT_DIR%\%outputname%_!count!.mp4"
    )
)

echo.
echo =============================================================
echo    ✅ All Videos Have Been Noise-Reduced!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo =============================================================
echo.
pause
exit /b
REM --- Code by Munna MasterMind ---
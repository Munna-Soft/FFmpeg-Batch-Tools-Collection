@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Vertical To Horizontal Rotate - by Munna MasterMind

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
    echo [INFO] "Videos" folder not found. Creating This...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your video files inside the "Videos" folder and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔══════════════════════════════════════════════════════════╗
echo        ║   Portrait To Landscape Converter by - Munna MasterMind  ║
echo        ║         https://munna-soft.github.io/Portfolio           ║
echo        ║             https://facebook.com/The.Munna               ║
echo        ╚══════════════════════════════════════════════════════════╝
echo.

REM --- Detect video files ---
set /a idx=0
for %%E in (mp4 mov avi mkv flv wmv mpg mpeg webm) do (
    for %%F in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a idx+=1
            set "file!idx!=%%~nxF"
            set "path!idx!=%%~fF"
        )
    )
)

if %idx%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported extensions: mp4 mov avi mkv flv wmv mpg mpeg webm
    echo.
    pause
    exit /b
)

echo ========== Available Videos ==========
if %idx% GTR 1 (
    echo  0 = Select All Videos
)
for /l %%i in (1,1,%idx%) do (
    echo  %%i = !file%%i!
)
echo ==================================================
echo.

:ASK_VIDEO
if %idx% GTR 1 (
    set /p "choice=Enter video number to convert (0 for All): "
) else (
    set "choice=1"
    echo Only one video file found, Auto-selecting it...
)

if "%choice%"=="" goto ASK_VIDEO
if %choice% lss 0 goto ASK_VIDEO
if %choice% gtr %idx% goto ASK_VIDEO

echo.
echo ========== Select Output Resolution ==========
echo   1 = 720p  (1280x720)
echo   2 = 1080p (1920x1080)
echo   3 = 2K    (2560x1440)
echo   4 = 4K    (3840x2160)
echo ==================================================
echo.

:ASK_RES
set /p "res=Enter output resolution option number (1-4): "
if "%res%"=="" goto ASK_RES

if "%res%"=="1" set "WIDTH=1280" & set "HEIGHT=720"
if "%res%"=="2" set "WIDTH=1920" & set "HEIGHT=1080"
if "%res%"=="3" set "WIDTH=2560" & set "HEIGHT=1440"
if "%res%"=="4" set "WIDTH=3840" & set "HEIGHT=2160"

if not defined WIDTH (
    echo Invalid resolution!
    goto ASK_RES
)

echo.
echo ========== Select Rotate Angle ==========
echo   1 = 90° Right  (Clockwise)
echo   2 = 90° Left   (Counter-Clockwise)
echo ==================================================
echo.

:ASK_ROTATE
set /p "rot=Enter output rotate option number (1-2): "
if "%rot%"=="" goto ASK_ROTATE

if "%rot%"=="1" (
    set "TRANSPOSE=1"
    set "ROT_TEXT=90° Right"
)
if "%rot%"=="2" (
    set "TRANSPOSE=2"
    set "ROT_TEXT=90° Left"
)

if not defined TRANSPOSE (
    echo Invalid rotate option!
    goto ASK_ROTATE
)

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo   Rotating Vertical → Horizontal
echo   Resolution: %WIDTH%x%HEIGHT%
echo   Rotate: %ROT_TEXT%
echo --------------------------------------------------

if %choice%==0 (
    for /l %%i in (1,1,%idx%) do (
        call :ConvertOne "%%i" "!path%%i!"
    )
) else (
    call :ConvertOne "%choice%" "!path%choice%!"
)

echo.
echo ==================================================
echo    ✅ All videos converted successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:ConvertOne
set "NUM=%~1"
set "INPATH=%~2"

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%_horizontal.mp4"

echo.
echo Converting [#%NUM%]: %NAME%
echo.

"%FFMPEG%" -hide_banner -loglevel error -stats -y ^ -i "%INPATH%" ^
-vf "transpose=%TRANSPOSE%,scale=%WIDTH%:%HEIGHT%" ^
-c:v libx264 -preset ultrafast -crf 25 ^
-c:a copy ^ "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Conversion failed for %NAME%
) else (
    echo [OK] %NAME% converted successfully!
    echo --------------------------------------------------
)
goto :eof
REM --- Code by Munna MasterMind ---
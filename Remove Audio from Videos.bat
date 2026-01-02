@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Remove Audio from Video - by Munna MasterMind

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
    echo [INFO] "Videos" folder not found. Creating this...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your video files inside the "Videos" folder and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║   Remove Audio from Video by - Munna MasterMind   ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
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
    set /p "choice=Enter video number to process (0 for All): "
) else (
    set "choice=1"
    echo Only one video file found, auto-selecting it...
)

if "%choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%choice%") do set invalid=1
if defined invalid set invalid= & goto ASK_VIDEO
if %choice% lss 0 goto ASK_VIDEO
if %choice% gtr %idx% if not "%choice%"=="0" goto ASK_VIDEO

REM --- Resolution Selection ---
echo.
echo ========== Select Output Resolution ==========
echo    1 = Original Resolution
echo    2 = 1280x720      (HD)
echo    3 = 1920x1080     (Full HD)
echo    4 = 2560x1440     (2k)
echo    5 = 3840x2160     (4k)
echo ==================================================
set /p "RES_CHOICE=Enter choice (1-5): "

set "SCALE_OPT="
if "%RES_CHOICE%"=="2" set "SCALE_OPT=-vf scale=1280:720"
if "%RES_CHOICE%"=="3" set "SCALE_OPT=-vf scale=1920:1080"
if "%RES_CHOICE%"=="4" set "SCALE_OPT=-vf scale=2560:1440"
if "%RES_CHOICE%"=="5" set "SCALE_OPT=-vf scale=3840:2160"

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo   Starting Audio Removal Process...
echo   Resolution Format: %SCALE_OPT%
echo --------------------------------------------------
echo.

if %choice%==0 (
    for /l %%i in (1,1,%idx%) do (
        call :RemoveOne "%%i" "!path%%i!"
    )
) else (
    call :RemoveOne "%choice%" "!path%choice%!"
)

echo.
echo ==================================================
echo    ✅ All videos processed successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:RemoveOne
set "NUM=%~1"
set "INPATH=%~2"

if not exist "%INPATH%" (
    echo [ERROR] File not found: "%INPATH%"
    goto :eof
)

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%.mp4"

echo --------------------------------------------------
echo Processing [#%NUM%]: "%NAME%"
echo --------------------------------------------------

"%FFMPEG%" -y -i "%INPATH%" %SCALE_OPT% -c:v libx264 -preset ultrafast -crf 25 -an "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Audio removal failed for "%NAME%"
) else (
    echo [OK] "%NAME%" processed successfully!
)
goto :eof
REM --- Code by Munna MasterMind ---
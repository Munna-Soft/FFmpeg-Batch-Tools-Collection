@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Video Format Converter - by Munna MasterMind

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
echo        ╔═══════════════════════════════════════════════════╗
echo        ║   Video Format Converter by - Munna MasterMind    ║
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
    set /p "choice=Enter video number to convert (0 for All): "
) else (
    set "choice=1"
    echo Only one video file found, auto-selecting it...
)

if "%choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_VIDEO
if %choice% lss 0 goto ASK_VIDEO
if %choice% gtr %idx% goto ASK_VIDEO

echo.
echo ========== Choose Output Format ==========
echo      1 = mp4
echo      2 = mkv
echo      3 = avi
echo      4 = mov
echo ==================================================
echo.

:ASK_FORMAT
set /p "fmt_choice=Enter output format option number (1-4): "
if "%fmt_choice%"=="" goto ASK_FORMAT
for /f "delims=0123456789" %%B in ("%fmt_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_FORMAT
if %fmt_choice% lss 1 goto ASK_FORMAT
if %fmt_choice% gtr 4 goto ASK_FORMAT

if "%fmt_choice%"=="1" set "EXT=mp4"
if "%fmt_choice%"=="2" set "EXT=mkv"
if "%fmt_choice%"=="3" set "EXT=avi"
if "%fmt_choice%"=="4" set "EXT=mov"

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo   Starting Conversion...
echo   Output Format: %EXT%
echo --------------------------------------------------
echo.

if %choice%==0 (
    for /l %%i in (1,1,%idx%) do (
        call :ConvertOne "%%i" "!path%%i!"
    )
) else (
    call :ConvertOne "%choice%" "!path%choice%!"
)

echo.
echo ==================================================
echo    ✅ All conversions completed successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:ConvertOne
set "NUM=%~1"
set "INPATH=%~2"

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%.%EXT%"

echo --------------------------------------------------
echo Converting [#%NUM%]: %NAME%
echo --------------------------------------------------

"%FFMPEG%" -hide_banner -loglevel error -stats -y ^ -i "%INPATH%" ^
 -c:v libx264 -preset ultrafast -crf 25 ^
 -c:a aac -b:a 128k ^ "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Conversion failed for %NAME%
) else (
    echo [OK] %NAME% converted successfully!
)
goto :eof
REM --- Code by Munna MasterMind ---
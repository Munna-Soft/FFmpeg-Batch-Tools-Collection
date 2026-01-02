@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Frame-by-Frame Image Extractor - by Munna MasterMind

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
echo        ╔══════════════════════════════════════════════════════╗
echo        ║ Frame-by-Frame Image Extractor by - Munna MasterMind ║
echo        ║        https://munna-soft.github.io/Portfolio        ║
echo        ║            https://facebook.com/The.Munna            ║
echo        ╚══════════════════════════════════════════════════════╝
echo.

REM --- Detect video files ---
set "IDX=0"
for %%E in (mp4 mov avi mkv flv wmv mpg mpeg webm) do (
    for %%F in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a IDX+=1
            set "FILE_!IDX!=%%~nxF"
            set "PATH_!IDX!=%%~fF"
        )
    )
)

if %IDX%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported formats: mp4 mov avi mkv flv wmv mpg mpeg webm
    echo.
    pause
    exit /b
)

echo ========== Available Videos ==========
if %IDX% GTR 1 (
    echo  0 = Select All Videos
)
for /l %%I in (1,1,%IDX%) do (
    echo  %%I = !FILE_%%I!
)
echo ==================================================
echo.

:ASK_VIDEO
if %IDX% GTR 1 (
    set /p "CHOICE=Enter video number (0 for All): "
) else (
    set "CHOICE=1"
    echo Only one video found, auto-selected.
)

if "%CHOICE%"=="" goto ASK_VIDEO
if %CHOICE% lss 0 goto ASK_VIDEO
if %CHOICE% gtr %IDX% goto ASK_VIDEO

echo.
echo ========== Select FPS ==========
echo    1 = 1 FPS
echo    2 = 5 FPS
echo    3 = 10 FPS
echo    4 = 24 FPS
echo    5 = Custom FPS
echo ==================================================
echo.

:ASK_FPS
set /p "FPS_CHOICE=Enter option (1-5): "
if "%FPS_CHOICE%"=="" goto ASK_FPS

if "%FPS_CHOICE%"=="1" set "FPS=1"
if "%FPS_CHOICE%"=="2" set "FPS=5"
if "%FPS_CHOICE%"=="3" set "FPS=10"
if "%FPS_CHOICE%"=="4" set "FPS=24"
if "%FPS_CHOICE%"=="5" set /p "FPS=Enter custom FPS value: "

if not defined FPS goto ASK_FPS

echo.
echo ========== Output Image Format ==========
echo    1 = PNG
echo    2 = JPG
echo ==================================================
echo.

:ASK_IMG
set /p "IMG_CHOICE=Choose format (1-2): "
if "%IMG_CHOICE%"=="1" set "IMG_EXT=png"
if "%IMG_CHOICE%"=="2" set "IMG_EXT=jpg"
if not defined IMG_EXT goto ASK_IMG

echo.
echo ========== Time Range (Leave blank for full video) ==========
set /p "START_TIME=Start Time (HH:MM:SS or blank): "
set /p "END_TIME=End Time   (HH:MM:SS or blank): "
echo ==================================================

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo    Starting Frame Extraction
echo --------------------------------------------------
echo.

if %IDX% GTR 1 (
    if %CHOICE%==0 (
        for /l %%I in (1,1,%IDX%) do (
            call :EXTRACT %%I "!PATH_%%I!"
        )
    ) else (
        call :EXTRACT %CHOICE% "!PATH_%CHOICE%!"
    )
) else (
    call :EXTRACT 1 "!PATH_1!"
)

echo.
echo ==================================================
echo   ✅ Frame Extraction Completed Successfully!
echo   📁 Output Folder: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:EXTRACT
set "NUM=%~1"
set "INFILE=%~2"

for %%A in ("%INFILE%") do set "NAME=%%~nA"
set "OUT_DIR=%OUTPUT_DIR%\%NAME%"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "TIME_RANGE="
if not "%START_TIME%"=="" set "TIME_RANGE=-ss %START_TIME%"
if not "%END_TIME%"=="" set "TIME_RANGE=%TIME_RANGE% -to %END_TIME%"

echo ----------------------------------------------------------
echo Extracting Frames [#%NUM%] : %NAME%
echo ----------------------------------------------------------

"%FFMPEG%" -hide_banner -loglevel error -stats %TIME_RANGE% ^
 -i "%INFILE%" -vf fps=%FPS% "%OUT_DIR%\frame_%%04d.%IMG_EXT%"

if errorlevel 1 (
    echo [FAILED] Extraction failed for %NAME%
) else (
    echo [OK] %NAME% frames extracted successfully!
)
goto :eof
REM --- Code by Munna MasterMind ---
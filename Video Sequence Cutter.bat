@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Video Sequence Cutter - by Munna MasterMind

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
set "TEMP=%BASE_DIR%Temp"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo.
    echo [INFO] "Videos" folder not found. Creating This...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your video files there and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║     Video Sequence Cutter by - Munna MasterMind   ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- Detect Video Files ---
set "INDEX=0"
for %%E in (mp4 mkv avi mov webm flv) do (
    for %%F in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a INDEX+=1
            set "VIDEO_!INDEX!=%%~nxF"
            set "VIDEO_PATH_!INDEX!=%%~fF"
        )
    )
)

if %INDEX%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported extensions: mp4 mkv avi mov webm flv
    echo.
    pause
    exit /b
)

:SELECT_VIDEO
echo ========== Available Videos ==========
for /l %%I in (1,1,%INDEX%) do (
    echo  %%I. !VIDEO_%%I!
)
echo ==================================================
echo.
set /p "CHOICE=Select a video file (1-%INDEX%): "

if "%CHOICE%"=="" goto SELECT_VIDEO
if %CHOICE% lss 1 goto SELECT_VIDEO
if %CHOICE% gtr %INDEX% goto SELECT_VIDEO

set "SELECTED_VIDEO=!VIDEO_%CHOICE%!"
set "INPUT_FILE=!VIDEO_PATH_%CHOICE%!"

echo.
echo Selected Video: !SELECTED_VIDEO!
echo ==================================================
echo.

REM --- INPUT CUT TIMES ---
:ASK_START
set /p "START_TIME=Enter Start Time (HH:MM:SS / MM:SS / Seconds): "
if "%START_TIME%"=="" goto ASK_START

:ASK_END
set /p "END_TIME=Enter End Time (HH:MM:SS / MM:SS / Seconds): "
if "%END_TIME%"=="" goto ASK_END
set "BASENAME=!SELECTED_VIDEO:~0,-4!"

echo.
set /p "OUTPUT_NAME=Enter Output file Name (default: !BASENAME!_cut): "
if "%OUTPUT_NAME%"=="" set "OUTPUT_NAME=!BASENAME!_cut"

echo.
echo --------------------------------------------------
echo Input File : !SELECTED_VIDEO!
echo Start Time : !START_TIME!
echo End Time   : !END_TIME!
echo Output File: !OUTPUT_NAME!.mp4
echo --------------------------------------------------
echo.

REM --- Create Temp and Output folders ---
if not exist "%TEMP%" mkdir "%TEMP%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
set "OUTPUT_FILE=%OUTPUT_DIR%\!OUTPUT_NAME!.mp4"

echo 🎬 Cutting video, please wait...
echo.

"%FFMPEG%" -y -ss !START_TIME! -to !END_TIME! -i "!INPUT_FILE!" ^
 -c:v libx264 -preset ultrafast -crf 25 -c:a aac ^
 -loglevel error -stats "%OUTPUT_FILE%"

if errorlevel 1 (
    echo [ERROR] Conversion failed for !OUTPUT_NAME!
    echo.
    pause
) else (
    echo [OK] !OUTPUT_NAME! Conversion successfully!
    echo.
    pause
)

REM --- Cleanup ---
if exist "%TEMP%" (
    rmdir /s /q "%TEMP%" >nul 2>&1
)
exit /b
REM --- Code by Munna MasterMind ---
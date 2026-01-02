@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Audio Sequence Cutter - by Munna MasterMind

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
set "TEMP=%BASE_DIR%Temp"

REM --- Create Audios folder if missing ---
if not exist "%AUDIOS_DIR%" (
    echo.
    echo [INFO] "Audios" folder not found. Creating This...
    mkdir "%AUDIOS_DIR%"
    echo.
    echo Please put your audio files there and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║     Audio Sequence Cutter by - Munna MasterMind   ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- Detect Audio Files ---
set "INDEX=0"
for %%E in (mp3 wav flac aac m4a ogg) do (
    for %%F in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a INDEX+=1
            set "AUDIO_!INDEX!=%%~nxF"
            set "AUDIO_PATH_!INDEX!=%%~fF"
        )
    )
)

if %INDEX%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    echo.
    echo Supported extensions: mp3 wav flac aac m4a ogg
    echo.
    pause
    exit /b
)

:SELECT_AUDIO
echo ========== Available Audios ==========
for /l %%I in (1,1,%INDEX%) do (
    echo  %%I. !AUDIO_%%I!
)
echo ==================================================
echo.
set /p "CHOICE=Select an audio file (1-%INDEX%): "

if "%CHOICE%"=="" goto SELECT_AUDIO
if %CHOICE% lss 1 goto SELECT_AUDIO
if %CHOICE% gtr %INDEX% goto SELECT_AUDIO

set "SELECTED_AUDIO=!AUDIO_%CHOICE%!"
set "INPUT_FILE=!AUDIO_PATH_%CHOICE%!"

echo.
echo Selected Audio: !SELECTED_AUDIO!
echo ==================================================
echo.

REM --- INPUT CUT TIMES ---
:ASK_START
set /p "START_TIME=Enter Start Time (HH:MM:SS / MM:SS / Seconds): "
if "%START_TIME%"=="" goto ASK_START

:ASK_END
set /p "END_TIME=Enter End Time (HH:MM:SS / MM:SS / Seconds): "
if "%END_TIME%"=="" goto ASK_END
set "BASENAME=!SELECTED_AUDIO:~0,-4!"

echo.
set /p "OUTPUT_NAME=Enter Output file Name (default: !BASENAME!_cut): "
if "%OUTPUT_NAME%"=="" set "OUTPUT_NAME=!BASENAME!_cut"

echo.
echo --------------------------------------------------
echo Input File : !SELECTED_AUDIO!
echo Start Time : !START_TIME!
echo End Time   : !END_TIME!
echo Output File: !OUTPUT_NAME!.mp3
echo --------------------------------------------------
echo.

REM --- Create Temp and Output folders ---
if not exist "%TEMP%" mkdir "%TEMP%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
set "OUTPUT_FILE=%OUTPUT_DIR%\!OUTPUT_NAME!.mp3"

echo Cutting audio, please wait...
echo.

"%FFMPEG%" -y -ss !START_TIME! -to !END_TIME! -i "!INPUT_FILE!" ^
 -c copy -loglevel error -stats "%OUTPUT_FILE%"

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
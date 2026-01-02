@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Merge Multiple Audios - by Munna MasterMind

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

REM --- Folder Paths ---
set "AUDIOS_DIR=%BASE_DIR%Audios"
set "OUTPUT_DIR=%BASE_DIR%Output"

REM --- Create Audios folder if missing ---
if not exist "%AUDIOS_DIR%" (
    echo.
    echo [INFO] "Audios" folder not found. Creating This...
    mkdir "%AUDIOS_DIR%"
    echo.
    echo Please put your audio files inside the "Audios" folder and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║     Join Multiple Audios by - Munna MasterMind    ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- List available audio files ---
set i=0
for %%E in (mp3 wav m4a flac aac ogg wma opus) do (
    for %%f in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "audio[!i!]=%%~nxf"
        )
    )
)

if %i%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    echo.
    echo Supported audio formats: mp3, wav, m4a, flac, aac, ogg, wma, opus
    echo.
    pause
    exit /b
)

echo ========== Available Audio Files ==========
if %i% gtr 1 echo 0 = Join ALL audio files
for /l %%n in (1,1,%i%) do (
    echo %%n = !audio[%%n]!
)
echo ==================================================
echo.
set /p sel="Enter the numbers of audio files to merge (e.g: 1+3+5, 1 3 5, or 0 for ALL Sequential): "

REM --- If user selects 0, join all ---
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

set sel=%sel:+= %
echo You selected: %sel%

REM --- Ask for audio bitrate ---
echo.
echo ========== Select Output Audio Quality ==========
echo     1 = 128 kbps
echo     2 = 192 kbps
echo     3 = 256 kbps
echo     4 = 320 kbps
echo ==================================================
echo.
set /p q="Enter quality number (1-5): "

if "%q%"=="1" set bitrate=128k
if "%q%"=="2" set bitrate=192k
if "%q%"=="3" set bitrate=256k
if "%q%"=="4" set bitrate=320k

if "%bitrate%"=="" (
    echo Invalid choice.
    pause
    exit /b
)

REM --- Output filename ---
echo.
set /p outputname="Enter output file name (without extension, default: MergedAudio): "
if "%outputname%"=="" set outputname=MergedAudio

REM --- Temp files ---
set "tempfilelist=%BASE_DIR%temp_audio_list.txt"
set "tempfolder=%BASE_DIR%Temp"

if exist "%tempfolder%" rd /s /q "%tempfolder%"
mkdir "%tempfolder%"
if exist "%tempfilelist%" del "%tempfilelist%"

REM --- Convert selected audios to uniform MP3 ---
for %%n in (%sel%) do (
    set "f=!audio[%%n]!"
    if defined f (
        set "outfile=%tempfolder%\%%~nf.mp3"
        echo Converting "!f!" to uniform MP3 format...
        "%FFMPEG%" -y -i "%AUDIOS_DIR%\!f!" -vn -ar 44100 -ac 2 -b:a %bitrate% "!outfile!"
        echo file '!outfile!'>> "%tempfilelist%"
    ) else (
        echo [WARN] Audio number %%n not found, skipping.
    )
)

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo Merging audios into "%outputname%.mp3" 
echo --------------------------------------------------
echo.

"%FFMPEG%" -f concat -safe 0 -i "%tempfilelist%" -c copy "%OUTPUT_DIR%\%outputname%.mp3"

REM --- Cleanup ---
del "%tempfilelist%"
rd /s /q "%tempfolder%"

echo.
echo ==================================================
echo    ✅ All selected audios have been merged successfully!
echo    📁 File saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b
REM ---Code by Munna MasterMind---
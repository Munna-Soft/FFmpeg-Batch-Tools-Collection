@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Silent Video + Audio Joiner - by Munna MasterMind

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
set "AUDIOS_DIR=%BASE_DIR%Audios"
set "OUTPUT_DIR=%BASE_DIR%Output"

REM --- Create Videos/Audios folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo.
    echo [INFO] "Videos" folder not found. Creating This...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your silent video files inside the "Videos" folder and run this script again
    echo.
    pause
    exit /b
)
if not exist "%AUDIOS_DIR%" (
    echo.
    echo [INFO] "Audios" folder not found. Creating This...
    mkdir "%AUDIOS_DIR%"
    echo.
    echo Please put your audios files inside the "Audios" folder and run this script again
    echo.
    pause
    exit /b
)

echo.
echo        ╔════════════════════════════════════════════════════╗
echo        ║  Add Music to Silent Videos by - Munna MasterMind  ║
echo        ║       https://munna-soft.github.io/Portfolio       ║
echo        ║           https://facebook.com/The.Munna           ║
echo        ╚════════════════════════════════════════════════════╝
echo.

REM --- Detect video files ---
set /a v_idx=0
for %%E in (mp4 mov avi mkv flv wmv mpg mpeg webm) do (
    for %%F in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a v_idx+=1
            set "vfile!v_idx!=%%~nxF"
            set "vpath!v_idx!=%%~fF"
        )
    )
)

if %v_idx%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported extensions: mp4 mov avi mkv flv wmv mpg mpeg webm
    echo.
    pause
    exit /b
)

if %v_idx%==1 (
    set "SELECTED_VIDEO=!vpath1!"
    echo Only one video file found, auto-selected: !vfile1!
    echo.
    goto SKIP_VIDEO_SELECTION
)

echo ========== Available Videos ==========
echo  0 = Select All Videos
for /l %%i in (1,1,%v_idx%) do (
    echo  %%i = !vfile%%i!
)
echo ==================================================
echo.

:ASK_VIDEO
set /p "v_choice=Enter video number to process (0 for all): "
if "%v_choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%v_choice%") do set invalid=1
if defined invalid set invalid= & goto ASK_VIDEO
if %v_choice% lss 0 goto ASK_VIDEO
if %v_choice% gtr %v_idx% goto ASK_VIDEO

if %v_choice%==0 (
    set "SELECTED_VIDEO=ALL"
) else (
    set "SELECTED_VIDEO=!vpath%v_choice%!"
)
echo.

:SKIP_VIDEO_SELECTION
set /a m_idx=0
for %%E in (mp3 wav aac flac ogg m4a wma) do (
    for %%F in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a m_idx+=1
            set "mfile!m_idx!=%%~nxF"
            set "mpath!m_idx!=%%~fF"
        )
    )
)

if %m_idx%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    echo.
    echo Supported extensions: mp3 wav aac flac ogg m4a wma
    echo.
    pause
    exit /b
)

echo ========== Available Audio Files ==========
for /l %%i in (1,1,%m_idx%) do (
    echo  %%i = !mfile%%i!
)
echo ==================================================
echo.

:ASK_AUDIO
set /p "m_choice=Enter audio number to process: "
if "%m_choice%"=="" goto ASK_AUDIO
for /f "delims=0123456789" %%A in ("%m_choice%") do set invalid=1
if defined invalid set invalid= & goto ASK_AUDIO
if %m_choice% lss 1 goto ASK_AUDIO
if %m_choice% gtr %m_idx% goto ASK_AUDIO

set "SELECTED_AUDIO=!mpath%m_choice%!"
echo.

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo --------------------------------------------------
echo    Joining Video + Audio...
echo --------------------------------------------------
echo.

if "%SELECTED_VIDEO%"=="ALL" (
    for /l %%i in (1,1,%v_idx%) do (
        call :JoinVideoAudio "!vpath%%i!" "!SELECTED_AUDIO!"
    )
) else (
    call :JoinVideoAudio "!SELECTED_VIDEO!" "!SELECTED_AUDIO!"
)

echo.
echo ==================================================
echo    ✅ Joining completed successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:JoinVideoAudio
set "VID=%~1"
set "AUD=%~2"

for %%Z in ("%VID%") do (
    set "NAME=%%~nZ"
    set "EXT=%%~xZ"
)
set "OUTFILE=%OUTPUT_DIR%\%NAME%_joined%EXT%"

echo --------------------------------------------------
echo Processing: "%NAME%"
echo --------------------------------------------------

"%FFMPEG%" -hide_banner -loglevel error -stats -y ^
 -i "%VID%" -i "%AUD%" -map 0:v -map 1:a -c:v copy -c:a aac -shortest "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Conversion failed for "%NAME%"
) else (
    echo [OK] "%NAME%" converted successfully!
)
goto :eof
REM --- Code by Munna MasterMind ---
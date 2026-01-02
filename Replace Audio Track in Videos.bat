@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Replace Audio Track in Videos - by Munna MasterMind

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
set "AUDIO_DIR=%BASE_DIR%Audios"
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
if not exist "%AUDIO_DIR%" (
    echo.
    echo [INFO] "Audios" folder not found. Creating This...
    mkdir "%AUDIO_DIR%"
    echo.
    echo Please put your audio files inside the "Audios" folder and run this script again
    echo.
    pause
    exit /b
)

echo.
echo        ╔═════════════════════════════════════════════════════╗
echo        ║ Replace Audio Track in Videos by - Munna MasterMind ║
echo        ║       https://munna-soft.github.io/Portfolio        ║
echo        ║          https://facebook.com/The.Munna             ║
echo        ╚═════════════════════════════════════════════════════╝
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
    set "MULTI_VIDEO=0"
    set "SELECTED_VIDEO=!vpath1!"
    echo Only one video found, auto-selected: !vfile1!
    echo.
    goto AUDIO_STEP
)

echo ========== Available Videos ==========
echo  0 = Select All Videos
for /l %%i in (1,1,%v_idx%) do (
    echo  %%i = !vfile%%i!
)
echo ==================================================
echo.

:ASK_VIDEO
set /p "v_choice=Enter video number (0 = All): "
if "%v_choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%v_choice%") do set invalid=1
if defined invalid set invalid= & goto ASK_VIDEO
if %v_choice% lss 0 goto ASK_VIDEO
if %v_choice% gtr %v_idx% goto ASK_VIDEO

if "%v_choice%"=="0" (
    set "MULTI_VIDEO=1"
) else (
    set "MULTI_VIDEO=0"
    set "SELECTED_VIDEO=!vpath%v_choice%!"
)
echo.

:AUDIO_STEP
set /a m_idx=0
for %%E in (mp3 wav aac flac ogg m4a wma) do (
    for %%F in ("%AUDIO_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a m_idx+=1
            set "mfile!m_idx!=%%~nxF"
            set "mpath!m_idx!=%%~fF"
        )
    )
)

if %m_idx%==0 (
    echo.
    echo [WARN] No Audio files found in "%AUDIO_DIR%".
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

:START_PROCESS
echo --------------------------------------------------
echo   Replacing Audio Track...
echo --------------------------------------------------
echo.

if "%MULTI_VIDEO%"=="1" (
    for /l %%i in (1,1,%v_idx%) do (
        call :ReplaceAudio "!vpath%%i!" "!SELECTED_AUDIO!"
    )
) else (
    call :ReplaceAudio "!SELECTED_VIDEO!" "!SELECTED_AUDIO!"
)

echo.
echo ==================================================
echo    ✅ Audio replacement completed successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b

:ReplaceAudio
set "VID=%~1"
set "AUD=%~2"

for %%Z in ("%VID%") do (
    set "NAME=%%~nZ"
    set "EXT=%%~xZ"
)
set "OUTFILE=%OUTPUT_DIR%\%NAME%%EXT%"

echo --------------------------------------------------
echo Processing: [#%NUM%]: %NAME%
echo --------------------------------------------------

"%FFMPEG%" -hide_banner -loglevel error -stats -y ^
 -i "%VID%" -i "%AUD%" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] "%NAME%"
) else (
    echo [OK] "%NAME%" audio replaced successfully!
)
goto :eof
REM --- Code by Munna MasterMind ---
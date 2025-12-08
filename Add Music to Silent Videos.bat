@echo off
REM ============================================================
REM Silent Video + Audio Joiner Tools (Smart Selection Edition)
REM                 Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "MUSIC_DIR=%~dp0Music"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create missing folders ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] "Videos" folder not found. Creating...
    mkdir "%VIDEOS_DIR%"
)
if not exist "%MUSIC_DIR%" (
    echo [INFO] "Music" folder not found. Creating...
    mkdir "%MUSIC_DIR%"
)
if not exist "%OUTPUT_DIR%" (
    echo [INFO] "Output" folder not found. Creating...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================================================================
echo            Silent Video + Audio Joiner Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

:: ==============================================================
::  STEP 1: Check and list available videos
:: ==============================================================

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
    echo Please add video files and run this script again.
    pause
    exit /b
)

:: --- Auto select if only one video is found ---
if %v_idx%==1 (
    set "SELECTED_VIDEO=!vpath1!"
    echo Only one video file found, auto-selected: !vfile1!
    echo.
    goto SKIP_VIDEO_SELECTION
)

:: --- If multiple videos are found ---
echo ========== Available Videos ==========
echo  0 = Select All Videos
for /l %%i in (1,1,%v_idx%) do (
    echo  %%i = !vfile%%i!
)
echo ======================================
echo.

:ASK_VIDEO
set /p "v_choice=Enter video number to process (0 for all): "
if "%v_choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%v_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_VIDEO
if %v_choice% lss 0 echo Invalid choice. & goto ASK_VIDEO
if %v_choice% gtr %v_idx% echo Invalid choice. & goto ASK_VIDEO

if %v_choice%==0 (
    echo All videos selected.
    set "SELECTED_VIDEO=ALL"
) else (
    set "SELECTED_VIDEO=!vpath%v_choice%!"
    echo Selected Video: !vfile%v_choice%!
)
echo.

:SKIP_VIDEO_SELECTION

:: ==============================================================
::  STEP 2: Check and list available music files
:: ==============================================================

set /a m_idx=0
for %%E in (mp3 wav aac flac ogg m4a wma) do (
    for %%F in ("%MUSIC_DIR%\*.%%E") do (
        if exist "%%~fF" (
            set /a m_idx+=1
            set "mfile!m_idx!=%%~nxF"
            set "mpath!m_idx!=%%~fF"
        )
    )
)

if %m_idx%==0 (
    echo [WARN] No music files found in "%MUSIC_DIR%".
    echo Please add audio files and run again.
    pause
    exit /b
)

echo ========== Available Music Files ==========
for /l %%i in (1,1,%m_idx%) do (
    echo  %%i = !mfile%%i!
)
echo ============================================
echo.

:ASK_MUSIC
set /p "m_choice=Enter music number to use: "
if "%m_choice%"=="" goto ASK_MUSIC
for /f "delims=0123456789" %%A in ("%m_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_MUSIC
if %m_choice% lss 1 echo Invalid choice. & goto ASK_MUSIC
if %m_choice% gtr %m_idx% echo Invalid choice. & goto ASK_MUSIC

set "SELECTED_MUSIC=!mpath%m_choice%!"
echo.
echo Selected Music: !mfile%m_choice%!
echo.

:: ==============================================================
::  STEP 3: Join Video + Audio
:: ==============================================================

echo ========================================
echo   Joining Video + Audio...
echo ========================================
echo.

if "%SELECTED_VIDEO%"=="ALL" (
    for /l %%i in (1,1,%v_idx%) do (
        call :JoinVideoAudio "!vpath%%i!" "!SELECTED_MUSIC!"
    )
) else (
    call :JoinVideoAudio "!SELECTED_VIDEO!" "!SELECTED_MUSIC!"
)

echo.
echo ========================================================================================
echo        ✅ Joining completed successfully!
echo        Files saved in: "%OUTPUT_DIR%"
echo ========================================================================================
echo.
pause
exit /b


:JoinVideoAudio
set "VID=%~1"
set "AUD=%~2"

if not exist "%VID%" (
    echo [ERROR] Video not found: "%VID%"
    goto :eof
)
if not exist "%AUD%" (
    echo [ERROR] Audio not found: "%AUD%"
    goto :eof
)

for %%Z in ("%VID%") do (
    set "NAME=%%~nZ"
    set "EXT=%%~xZ"
)
set "OUTFILE=%OUTPUT_DIR%\%NAME%_joined%EXT%"

echo ----------------------------------------------------------
echo Processing: "%NAME%"
ffmpeg -hide_banner -loglevel error -stats -y ^
 -i "%VID%" -i "%AUD%" -map 0:v -map 1:a -c:v copy -c:a aac -shortest "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Failed to join "%NAME%"
) else (
    echo [OK] "%NAME%" joined successfully!
)
echo ----------------------------------------------------------
goto :eof

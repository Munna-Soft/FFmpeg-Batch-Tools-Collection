@echo off
REM ============================================================
REM Replace Audio Track in Video Tools (Smart Selection Edition)
REM                Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "MUSIC_DIR=%~dp0Music"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create missing folders ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] "Videos" folder not found. Creating this...
    mkdir "%VIDEOS_DIR%"
)
if not exist "%MUSIC_DIR%" (
    echo [INFO] "Music" folder not found. Creating this...
    mkdir "%MUSIC_DIR%"
)
if not exist "%OUTPUT_DIR%" (
    echo [INFO] "Output" folder not found. Creating this...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================================================================
echo                Replace Audio Track in Video Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

:: ==============================================================
:: STEP 1: Detect and select VIDEO first
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
    echo Please add your video files and run this script again.
    pause
    exit /b
)

if %v_idx%==1 (
    echo [INFO] Only one video file found, auto-selecting it...
    set "v_choice=1"
    goto VIDEO_SELECTED
)

echo ========== Available Videos ==========
echo   0 = Select All Videos
for /l %%i in (1,1,%v_idx%) do (
    echo   %%i = !vfile%%i!
)
echo ======================================
echo.

:ASK_VIDEO
set /p "v_choice=Enter video number (0 = All): "
if "%v_choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%v_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_VIDEO
if %v_choice% lss 0 echo Invalid choice. & goto ASK_VIDEO
if %v_choice% gtr %v_idx% echo Invalid choice. & goto ASK_VIDEO

:VIDEO_SELECTED
if "%v_choice%"=="0" (
    echo [INFO] All videos selected.
    set "MULTI_VIDEO=1"
) else (
    set "MULTI_VIDEO=0"
    set "SELECTED_VIDEO=!vpath%v_choice%!"
    echo Selected Video: !vfile%v_choice%!
)

echo.

:: ==============================================================
:: STEP 2: Detect and select MUSIC after video
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
    echo Please add your audio files and run this script again.
    pause
    exit /b
)

if %m_idx%==1 (
    echo [INFO] Only one music file found, auto-selecting it...
    set "m_choice=1"
    goto MUSIC_SELECTED
)

echo ========== Available Music Files ==========
REM "0 = Select All" No Option
for /l %%i in (1,1,%m_idx%) do (
    echo   %%i = !mfile%%i!
)
echo ======================================
echo.

:ASK_MUSIC
set /p "m_choice=Enter music number: "
if "%m_choice%"=="" goto ASK_MUSIC
for /f "delims=0123456789" %%A in ("%m_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_MUSIC
if %m_choice% lss 1 echo Invalid choice. & goto ASK_MUSIC
if %m_choice% gtr %m_idx% echo Invalid choice. & goto ASK_MUSIC

:MUSIC_SELECTED
set "SELECTED_MUSIC=!mpath%m_choice%!"
echo Selected Music: !mfile%m_choice%!

)

echo.
echo ========================================
echo   Replacing Audio Track...
echo ========================================
echo.

if "%MULTI_VIDEO%"=="1" (
    for /l %%V in (1,1,%v_idx%) do (
        call :ReplaceAudio "!vpath%%V!" "!SELECTED_MUSIC!"
    )
) else (
    call :ReplaceAudio "!SELECTED_VIDEO!" "!SELECTED_MUSIC!"
)

echo.
echo ========================================================================================
echo        ✅ Audio track replaced successfully!
echo        File saved in: "%OUTPUT_DIR%"
echo ========================================================================================
echo.
pause
exit /b

:ReplaceAudio
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
set "OUTFILE=%OUTPUT_DIR%\%NAME%%EXT%"
set "TEMPFILE=%OUTPUT_DIR%\TEMP_%RANDOM%_%NAME%%EXT%"

echo ----------------------------------------------------------
echo Processing [#%NUM%]: "%NAME%"
ffmpeg -hide_banner -loglevel error -stats -y ^
 -i "%VID%" -i "%AUD%" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest "%TEMPFILE%"

if errorlevel 1 (
    echo [FAILED] Failed to replace audio for "%NAME%"
    if exist "%TEMPFILE%" del "%TEMPFILE%"
) else (
    if exist "%OUTFILE%" del "%OUTFILE%"
    move /y "%TEMPFILE%" "%OUTFILE%" >nul
    echo [OK] "%NAME%" audio replaced successfully!
)
echo ----------------------------------------------------------
goto :eof

@echo off
REM ============================================================
REM Video to Audio Converter Tools (Smart Selection Edition)
REM             Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] "Videos" folder not found. Creating This...
    mkdir "%VIDEOS_DIR%"
    echo Please put your video files inside the "Videos" folder and run this script again.
    pause
    exit /b
)

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
    echo Supported extensions: mp4 mov avi mkv flv wmv mpg mpeg webm
    pause
    exit /b
)

echo.
echo ========================================================================================
echo                Video to Audio Converter Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

echo ========== Available Videos ==========
REM --- Show list ---
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
if %choice% lss 0 echo Invalid choice. & goto ASK_VIDEO
if %choice% gtr %idx% echo Invalid choice. & goto ASK_VIDEO

echo.
echo ========== Select Audio Bitrate ==========
echo      1 = 128k
echo      2 = 192k
echo      3 = 256k
echo      4 = 320k
echo ==================================================
echo.

:ASK_BITRATE
set /p "brate_choice=Enter audio bitrate option number (1-4): "
if "%brate_choice%"=="" goto ASK_BITRATE
for /f "delims=0123456789" %%B in ("%brate_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_BITRATE
if %brate_choice% lss 1 echo Invalid choice. & goto ASK_BITRATE
if %brate_choice% gtr 4 echo Invalid choice. & goto ASK_BITRATE

if "%brate_choice%"=="1" set "BITRATE=128k"
if "%brate_choice%"=="2" set "BITRATE=192k"
if "%brate_choice%"=="3" set "BITRATE=256k"
if "%brate_choice%"=="4" set "BITRATE=320k"

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================
echo   Starting Conversion...
echo   Bitrate: %BITRATE%
echo ========================================
echo.

if %idx% GTR 1 (
    if %choice%==0 (
        echo You chose to convert ALL videos.
        echo.
        for /l %%i in (1,1,%idx%) do (
            call :ConvertOne "%%i" "!path%%i!"
        )
    ) else (
        echo You chose: !file%choice%!
        echo.
        call :ConvertOne "%choice%" "!path%choice%!"
    )
) else (
    call :ConvertOne "1" "!path1!"
)

echo.
echo ========================================================================================
echo        ✅ All conversions completed successfully!
echo        Files saved in: "%OUTPUT_DIR%"
echo ========================================================================================
echo.
pause
exit /b

:ConvertOne
REM --- Convert one video with progress & clean output ---
set "NUM=%~1"
set "INPATH=%~2"

if not exist "%INPATH%" (
    echo [ERROR] File not found: "%INPATH%"
    goto :eof
)
for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%.mp3"

echo ----------------------------------------------------------
echo Converting [#%NUM%]: "%NAME%"
echo.
echo (Progress shown below — warnings suppressed)

REM --- Run ffmpeg with clean output but visible progress ---
ffmpeg -hide_banner -loglevel error -stats -y ^
 -fflags +genpts -i "%INPATH%" -vn -acodec libmp3lame -b:a %BITRATE% -ar 44100 ^
 -avoid_negative_ts make_zero -map_metadata -1 "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Conversion failed for "%NAME%"
) else (
    echo.
    echo [OK] "%NAME%" converted successfully!
)
echo ----------------------------------------------------------
goto :eof
REM --- Code by Munna MasterMind ---
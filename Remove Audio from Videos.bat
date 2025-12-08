@echo off
REM ============================================================
REM Remove Audio from Video Tools (Smart Selection Edition)
REM             Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] "Videos" folder not found. Creating this...
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
echo              Remove Audio from Video Tools - by Munna MasterMind
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
    set /p "choice=Enter video number to process (0 for All): "
) else (
    set "choice=1"
    echo Only one video file found, auto-selecting it...
)

if "%choice%"=="" goto ASK_VIDEO
for /f "delims=0123456789" %%A in ("%choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_VIDEO
if %choice% lss 0 echo Invalid choice. & goto ASK_VIDEO
if %choice% gtr %idx% if not "%choice%"=="0" echo Invalid choice. & goto ASK_VIDEO

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================
echo   Starting Audio Removal Process...
echo ========================================
echo.

if %idx% GTR 1 (
    if %choice%==0 (
        echo You chose to process ALL videos.
        echo.
        for /l %%i in (1,1,%idx%) do (
            call :RemoveOne "%%i" "!path%%i!"
        )
    ) else (
        echo You chose: !file%choice%!
        echo.
        call :RemoveOne "%choice%" "!path%choice%!"
    )
) else (
    call :RemoveOne "1" "!path1!"
)

echo.
echo ========================================================================================
echo        ✅ All videos processed successfully!
echo        Files saved in: "%OUTPUT_DIR%"
echo ========================================================================================
echo.
pause
exit /b

:RemoveOne
REM --- Remove audio from one video ---
set "NUM=%~1"
set "INPATH=%~2"

if not exist "%INPATH%" (
    echo [ERROR] File not found: "%INPATH%"
    goto :eof
)

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%_noaudio.mp4"

echo ----------------------------------------------------------
echo  Processing [#%NUM%]: "%NAME%"
echo.
echo (Progress shown below — warnings suppressed)

REM --- Run ffmpeg with clean output but visible progress ---
ffmpeg -hide_banner -loglevel error -stats -y ^
 -fflags +genpts -i "%INPATH%" -c copy -an "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Audio removal failed for "%NAME%"
) else (
    echo.
    echo [OK] "%NAME%" processed successfully!
)
echo ----------------------------------------------------------
goto :eof

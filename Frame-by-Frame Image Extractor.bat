@echo off
REM ============================================================
REM Frame-by-Frame Image Extractor (Smart Selection Edition)
REM 		    Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] "Videos" folder not found. Creating...
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
    pause
    exit /b
)


echo.
echo ========================================================================================
echo                  Frame-by-Frame Image Extractor Tools- by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

echo ========== Available Videos ==========
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
    set /p "choice=Enter video number (0 for All): "
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
echo ========== Select FPS (Frames Per Second) ==========
echo    1 = 1 FPS
echo    2 = 5 FPS
echo    3 = 10 FPS
echo    4 = 24 FPS
echo    5 = Custom FPS
echo ====================================================

:ASK_FPS
set /p "fps_choice=Enter FPS option number (1-5): "
if "%fps_choice%"=="" goto ASK_FPS
for /f "delims=0123456789" %%B in ("%fps_choice%") do set invalid=1
if defined invalid set invalid= & echo Invalid input. Try again. & goto ASK_FPS
if %fps_choice% lss 1 echo Invalid choice. & goto ASK_FPS
if %fps_choice% gtr 5 echo Invalid choice. & goto ASK_FPS

if "%fps_choice%"=="1" set "FPS=1"
if "%fps_choice%"=="2" set "FPS=5"
if "%fps_choice%"=="3" set "FPS=10"
if "%fps_choice%"=="4" set "FPS=24"
if "%fps_choice%"=="5" (
    set /p "FPS=Enter custom FPS value: "
)

echo.
echo ========== Select Output Image Format ==========
echo    1 = PNG
echo    2 = JPG
echo ==================================================

:ASK_IMG
set /p "img_choice=Choose format (1-2): "
if "%img_choice%"=="1" set "IMG_EXT=png"
if "%img_choice%"=="2" set "IMG_EXT=jpg"
if NOT DEFINED IMG_EXT echo Invalid choice. & goto ASK_IMG

echo.
echo ========== Time Range (Optional) ==========
echo Leave blank for full video.
set /p "START_TIME=Start time (e.g. HH:MM:SS, 00:00:00 or blank): "
set /p "END_TIME=End time (e.g. HH:MM:SS, 00:01:00 or blank): "
echo ==================================================


if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================
echo        Starting Frame Extraction
echo ========================================
echo.

if %idx% GTR 1 (
    if %choice%==0 (
        echo Extracting frames from ALL videos.
        for /l %%i in (1,1,%idx%) do (
            call :ExtractFrames "%%i" "!path%%i!"
        )
    ) else (
        echo You chose: !file%choice%!
        call :ExtractFrames "%choice%" "!path%choice%!"
    )
) else (
    call :ExtractFrames "1" "!path1!"
)

echo.
echo ==========================================================================
echo        ✅ Frame Extraction Completed Successfully!
echo        Files Saved in: "%OUTPUT_DIR%"
echo ==========================================================================
echo.
pause
exit /b


:ExtractFrames
set "NUM=%~1"
set "INPATH=%~2"

if not exist "%INPATH%" (
    echo [ERROR] File not found: "%INPATH%"
    goto :eof
)

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "FRAME_DIR=%OUTPUT_DIR%\%NAME%"

if not exist "%FRAME_DIR%" mkdir "%FRAME_DIR%"

echo ----------------------------------------------------------
echo Extracting Frames From [#%NUM%]: "%NAME%"
echo.

echo (Progress shown below)

set "T_RANGE="
if NOT "%START_TIME%"=="" set "T_RANGE=-ss %START_TIME%"
if NOT "%END_TIME%"=="" set "T_RANGE=%T_RANGE% -to %END_TIME%"

ffmpeg -hide_banner -loglevel error -stats %T_RANGE% -i "%INPATH%" -vf fps=%FPS% "%FRAME_DIR%/frame_%%04d.%IMG_EXT%"

if errorlevel 1 (
    echo [FAILED] Extraction failed for "%NAME%"
) else (
    echo [OK] Frames extracted successfully: "%NAME%"
)
echo ----------------------------------------------------------
goto :eof
REM --- Code by Munna MasterMind ---
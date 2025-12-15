@echo off
REM ============================================================
REM     Video Watermark Tools (Smart Selection Edition)
REM        Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder Paths ---
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
for %%E in (mp4 mkv avi mov flv wmv mpg mpeg webm) do (
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
    echo Supported extensions: mp4 mkv avi mov flv wmv mpg mpeg webm
    pause
    exit /b
)

echo.
echo ========================================================================================
echo                Video Watermark Tools- by Munna MasterMind
echo                    https://munna-soft.github.io/Portfolio
echo                       https://facebook.com/The.Munna
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
    set /p "choice=Enter video number to process (0 for All): "
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
set /p "watermark=Enter watermark text (English only): "
if "%watermark%"=="" (
    echo [WARN] Watermark cannot be empty.
    goto :ASK_VIDEO
)

echo.
echo ========== Select Watermark Position ==========
echo    1 = Top
echo    2 = Center
echo    3 = Bottom
echo ==============================================
echo.

:ASK_POS
set /p "pos_choice=Enter option number (1-3): "
if "%pos_choice%"=="" goto ASK_POS
if %pos_choice% lss 1 goto ASK_POS
if %pos_choice% gtr 3 goto ASK_POS

if "%pos_choice%"=="1" (
    set "xpos=(w-text_w)/2"
    set "ypos=50"
)
if "%pos_choice%"=="2" (
    set "xpos=(w-text_w)/2"
    set "ypos=(h-text_h)/2"
)
if "%pos_choice%"=="3" (
    set "xpos=(w-text_w)/2"
    set "ypos=h-text_h-50"
)

echo.
echo ========== Choose Watermark Color ==========
echo Examples: white, red, yellow, blue, green, cyan
echo =============================================
set /p "fontcolor=Enter color name (default white): "
if "%fontcolor%"=="" set "fontcolor=white"

echo.
set /p "fontsize=Enter font size (default 36): "
if "%fontsize%"=="" set "fontsize=36"

echo.
set /p "opacity=Enter opacity (1.0=solid, 0.5=semi-transparent, 0.3=light): "
if "%opacity%"=="" set "opacity=1.0"

set "font=C:\\Windows\\Fonts\\arial.ttf"

REM --- FAST RENDER PRESET ---
set "FAST_VIDEO_PRESET=-preset ultrafast -crf 25"

REM --- Create Output folder if missing ---
if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ========================================
echo   Starting Watermark Process...
echo   Watermark: "%watermark%"
echo   Color: %fontcolor%
echo   Font Size: %fontsize%
echo   Opacity: %opacity%
echo   FAST RENDER: ENABLED
echo ========================================
echo.

if %idx% GTR 1 (
    if %choice%==0 (
        echo You chose to watermark ALL videos.
        echo.
        for /l %%i in (1,1,%idx%) do (
            call :WatermarkOne "%%i" "!path%%i!"
        )
    ) else (
        echo You chose: !file%choice%!
        echo.
        call :WatermarkOne "%choice%" "!path%choice%!"
    )
) else (
    call :WatermarkOne "1" "!path1!"
)

echo.
echo ========================================================================================
echo        ✅ All videos processed successfully!
echo        Files saved in: "%OUTPUT_DIR%"
echo ========================================================================================
echo.
pause
exit /b

:WatermarkOne
set "NUM=%~1"
set "INPATH=%~2"

if not exist "%INPATH%" (
    echo [ERROR] File not found: "%INPATH%"
    goto :eof
)

for %%Z in ("%INPATH%") do set "NAME=%%~nZ"
set "OUTFILE=%OUTPUT_DIR%\%NAME%_watermarked.mp4"

echo ----------------------------------------------------------
echo Processing [#%NUM%]: "%NAME%"
echo.
echo (Progress shown below — warnings suppressed)

ffmpeg -hide_banner -loglevel error -stats -y ^
 -i "%INPATH%" ^
-vf "drawtext=fontfile=C\\:/Windows/Fonts/arial.ttf:text=%watermark%:fontcolor=%fontcolor%@%opacity%:fontsize=%fontsize%:x=%xpos%:y=%ypos%:shadowcolor=black:shadowx=2:shadowy=2" ^
 -preset ultrafast -crf 25 ^
 -codec:a copy "%OUTFILE%"

if errorlevel 1 (
    echo [FAILED] Watermark failed for "%NAME%"
) else (
    echo.
    echo [OK] "%NAME%" watermarked successfully!
)
echo ----------------------------------------------------------

goto :eof
REM --- Code by Munna MasterMind ---
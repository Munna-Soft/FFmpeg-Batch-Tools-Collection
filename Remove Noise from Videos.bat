@echo off
REM ============================================================
REM Smart Video Noise Removal Tool (Smart Selection Edition)
REM             Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "VIDEOS_DIR=%~dp0Videos"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo [INFO] Creating "Videos" folder...
    mkdir "%VIDEOS_DIR%"
    echo Please put your videos inside the "Videos" folder and run again.
    pause
    exit /b
)

echo.
echo ========================================================================================
echo                Smart Video Noise Remover Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

REM List videos
set i=0

echo ====== Available Videos ======
echo 	0 = Process ALL videos
for %%E in (mp4 mkv avi mov flv wmv mpg mpeg webm) do (
    for %%f in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "video[!i!]=%%~nxf"
            echo 	!i! = %%~nxf
        )
    )
)

if %i%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    pause
    exit /b
)

echo =============================================================

if %i%==1 (
    echo.
    echo Only one video found → Selecting automatically...
    set sel=1
    goto noise_level
)

echo.
set /p sel="Enter video numbers (e.g: 1+3+5 or 0): "

REM replace + with space for loop-friendly format
set sel=%sel:+= %

REM If 0 → select all
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

:noise_level
echo.
echo ====== Select Noise Reduction Level ======
echo 	1 = LOW    	Noise Reduction
echo 	2 = MEDIUM 	Noise Reduction
echo 	3 = HIGH   	Noise Reduction
echo =============================================================
echo.
set /p lvl="Select reduction quality (1-3): "

if "%lvl%"=="1" set NR=vaguedenoiser=threshold=3
if "%lvl%"=="2" set NR=vaguedenoiser=threshold=6
if "%lvl%"=="3" set NR=vaguedenoiser=threshold=12

if "%NR%"=="" (
    echo Invalid selection.
    pause
    exit /b
)

echo.
set /p outputname="Enter output base name (default: CleanVideo): "
if "%outputname%"=="" set outputname=CleanVideo

REM Ensure Output folder exists
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo ===============================================
echo Processing videos... Please wait.
echo ===============================================

set count=0

for %%n in (%sel%) do (
    set "f=!video[%%n]!"
    if defined f (
        set /a count+=1
        echo.
        echo Cleaning Noise From: !f!
        
        ffmpeg -y -i "%VIDEOS_DIR%\!f!" ^
        -vf "%NR%" ^
        -c:v libx264 -preset ultrafast -crf 25 ^
        -af "highpass=f=200, lowpass=f=3000" ^
        "%OUTPUT_DIR%\%outputname%_!count!.mp4"
    )
)

echo.
echo =============================================================
echo          All Videos Have Been Noise-Reduced!
echo          Files saved in: "%OUTPUT_DIR%"
echo =============================================================
pause
exit /b
REM --- Code by Munna MasterMind ---
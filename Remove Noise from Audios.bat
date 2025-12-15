@echo off
REM ============================================================
REM Smart Audio Noise Removal Tool (Smart Selection Edition)
REM               Author: Munna MasterMind
REM ============================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM --- Folder paths ---
set "AUDIOS_DIR=%~dp0Audios"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Audios folder if missing ---
if not exist "%AUDIOS_DIR%" (
    echo [INFO] Creating "Audios" folder...
    mkdir "%AUDIOS_DIR%"
    echo Please put your audio files inside the "Audios" folder and run again.
    pause
    exit /b
)

echo.
echo ========================================================================================
echo                Smart Audio Noise Remover Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.

REM List audio files
set i=0

echo ====== Available Audios ======
echo    0 = Process ALL audios
for %%E in (mp3 wav m4a flac aac ogg wma opus) do (
    for %%f in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "audio[!i!]=%%~nxf"
            echo    !i! = %%~nxf
        )
    )
)

if %i%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    pause
    exit /b
)

echo =============================================================

if %i%==1 (
    echo.
    echo Only one audio file found → Selecting automatically...
    set sel=1
    goto noise_level
)

echo.
set /p sel="Enter audio numbers (e.g: 1+3+5 or 0): "

REM Replace + with space (loop format)
set sel=%sel:+= %

REM If 0 → select all
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

:noise_level
echo.
echo ====== Select Noise Reduction Level ======
echo    1 = LOW     Noise Reduction
echo    2 = MEDIUM  Noise Reduction
echo    3 = HIGH    Noise Reduction
echo =============================================================
echo.
set /p lvl="Select reduction quality (1-3): "

if "%lvl%"=="1" set NR=afftdn=nr=6:nf=-25
if "%lvl%"=="2" set NR=afftdn=nr=12:nf=-35
if "%lvl%"=="3" set NR=afftdn=nr=20:nf=-45

if "%NR%"=="" (
    echo Invalid selection.
    pause
    exit /b
)

echo.
set /p outputname="Enter output base name (default: CleanAudio): "
if "%outputname%"=="" set outputname=CleanAudio

REM Ensure Output folder exists
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo ===============================================
echo Processing audio files... Please wait.
echo ===============================================

set count=0

for %%n in (%sel%) do (
    set "f=!audio[%%n]!"
    if defined f (
        set /a count+=1
        echo.
        echo Cleaning Noise From: !f!
        
        ffmpeg -y -i "%AUDIOS_DIR%\!f!" ^
        -af "%NR%" ^
        "%OUTPUT_DIR%\%outputname%_!count!.mp3"
    )
)

echo.
echo =============================================================
echo          All Audio Files Have Been Noise-Reduced!
echo          Files saved in: "%OUTPUT_DIR%"
echo =============================================================
pause
exit /b
REM --- Code by Munna MasterMind ---

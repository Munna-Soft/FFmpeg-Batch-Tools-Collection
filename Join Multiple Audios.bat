@echo off
REM ============================================================
REM Smart Merge Multiple Audio Tools (Smart Selection Edition)
REM            Author: Munna MasterMind
REM ============================================================

setlocal enabledelayedexpansion

REM --- Folder Paths ---
set "AUDIOS_DIR=%~dp0Audios"
set "OUTPUT_DIR=%~dp0Output"

REM --- Create Audios folder if missing ---
if not exist "%AUDIOS_DIR%" (
    echo [INFO] "Audios" folder not found. Creating This...
    mkdir "%AUDIOS_DIR%"
    echo Please put your audio files inside the "Audios" folder and run this script again.
    pause
    exit /b
)

REM --- Step: List available audio files ---
echo.
echo ========================================================================================
echo                 Merge Multiple Audio Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.
echo ========== Available Audio Files ==========
set i=0
for %%E in (mp3 wav m4a flac aac ogg wma opus) do (
    for %%f in ("%AUDIOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "audio[!i!]=%%~nxf"
        )
    )
)

if %i%==0 (
    echo [WARN] No audio files found in "%AUDIOS_DIR%".
    pause
    exit /b
)

REM --- Show list ---
if %i% gtr 1 echo 0 = Join ALL audio files  
for /l %%n in (1,1,%i%) do (
    echo %%n = !audio[%%n]!
)

echo ================================================
echo.
set /p sel="Enter the numbers of audio files to merge (e.g: 1+3+5, 1 3 5, or 0 for ALL): "

REM --- If user selects 0, join all ---
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

REM --- Normalize input ---
set sel=%sel:+= %
echo You selected: %sel%

REM --- Step: Ask for audio bitrate ---
echo.
echo ========== Select Output Audio Quality ==========
echo     1 = 96 kbps
echo     2 = 128 kbps
echo     3 = 192 kbps
echo     4 = 256 kbps
echo     5 = 320 kbps (Best)
echo ================================================
set /p q="Enter quality number (1-5): "

if "%q%"=="1" set bitrate=96k
if "%q%"=="2" set bitrate=128k
if "%q%"=="3" set bitrate=192k
if "%q%"=="4" set bitrate=256k
if "%q%"=="5" set bitrate=320k

if "%bitrate%"=="" (
    echo Invalid choice.
    pause
    exit /b
)

REM --- Step: Output filename ---
echo.
set /p outputname="Enter output file name (without extension, default: MergedAudio): "
if "%outputname%"=="" set outputname=MergedAudio

REM --- Step: Temporary folder ---
set tempfilelist=temp_audio_list.txt
set tempfolder=TempAudioConvert
if exist "%tempfolder%" rd /s /q "%tempfolder%"
mkdir "%tempfolder%"
if exist "%tempfilelist%" del "%tempfilelist%"

REM --- Convert all selected audios to MP3 uniform format ---
for %%n in (%sel%) do (
    set "f=!audio[%%n]!"
    if defined f (
        set "outfile=%tempfolder%\%%~nf.mp3"
        echo Converting "!f!" to uniform MP3 format...
        ffmpeg -y -i "%AUDIOS_DIR%\!f!" -vn -ar 44100 -ac 2 -b:a %bitrate% "!outfile!"
        echo file '!outfile!'>> "%tempfilelist%"
    ) else (
        echo Warning: Audio number %%n not found, skipping.
    )
)

REM --- Ensure Output folder exists ---
if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

REM --- Merge all audios ---
echo.
echo Merging audios into "%OUTPUT_DIR%\%outputname%.mp3"...
ffmpeg -f concat -safe 0 -i "%tempfilelist%" -c copy "%OUTPUT_DIR%\%outputname%.mp3"

REM --- Cleanup ---
del "%tempfilelist%"
rd /s /q "%tempfolder%"

echo.
echo ========================================================================================
echo       All selected audios have been merged successfully!
echo        File saved in: "%OUTPUT_DIR%"
echo ========================================================================================
pause
exit /b

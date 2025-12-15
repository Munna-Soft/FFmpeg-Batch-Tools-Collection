@echo off
REM ============================================================
REM     Audio Sequence Cutter Tools - Munna MasterMind
REM         https://munna-soft.github.io/Portfolio
REM        	    Author: Munna MasterMind
REM ============================================================

setlocal enabledelayedexpansion

:: ---------- FOLDER SETUP ----------
set "ROOT=%~dp0"
set "INPUT_FOLDER=%ROOT%Audios"
set "OUTPUT_FOLDER=%ROOT%Output"
set "TEMP=%ROOT%Temp"

if not exist "%INPUT_FOLDER%" (
    md "%INPUT_FOLDER%"
    echo [INFO] Created "Audios" folder. Please put your audio files there and run this script again.
    pause
    exit /b
)
if not exist "%OUTPUT_FOLDER%" md "%OUTPUT_FOLDER%"
if not exist "%TEMP%" md "%TEMP%"

:: ---------- FFMPEG CHECK ----------
set "FFMPEG=ffmpeg.exe"
if not exist "%FFMPEG%" set "FFMPEG=ffmpeg"

%FFMPEG% -version >nul 2>&1 || (
    echo [ERROR] ffmpeg not found! Please install or put ffmpeg.exe in this folder.
    pause
    exit /b
)

:: ---------- SCAN FOR AUDIOS ----------
echo Searching for audio files in "%INPUT_FOLDER%"...
set "INDEX=0"
for %%E in (mp3 wav flac aac m4a ogg) do (
    for %%F in ("%INPUT_FOLDER%\*.%%E") do (
        if exist "%%~fF" (
            set /a INDEX+=1
            set "AUDIO_!INDEX!=%%~nxF"
            set "AUDIO_PATH_!INDEX!=%%~fF"
        )
    )
)

if %INDEX%==0 (
    echo [ERROR] No audio files found in "%INPUT_FOLDER%".
    pause
    exit /b
)

:: ---------- SELECT AUDIO ----------
:SELECT_AUDIO
cls
echo ================================================================================
echo        Audio Sequence Cutter Tools - Munna MasterMind
REM         	https://munna-soft.github.io/Portfolio
REM        	    Author: Munna MasterMind
echo ================================================================================
echo.
echo Available Audio Files:
for /l %%I in (1,1,%INDEX%) do (
    echo  %%I. !AUDIO_%%I!
)
echo --------------------------------------------------------------------------------
echo.
set /p "CHOICE=Select an audio file (1-%INDEX%): "
if "%CHOICE%"=="" goto SELECT_AUDIO
if %CHOICE% lss 1 goto SELECT_AUDIO
if %CHOICE% gtr %INDEX% goto SELECT_AUDIO

set "SELECTED_AUDIO=!AUDIO_%CHOICE%!"
set "INPUT_FILE=!AUDIO_PATH_%CHOICE%!"

echo.
echo Selected Audio: !SELECTED_AUDIO!
echo --------------------------------------------------------------------------------

:: ---------- INPUT CUT TIMES ----------
echo.
:ASK_START
set /p "START_TIME=Enter Start Time (HH:MM:SS or MM:SS or seconds): "
if "%START_TIME%"=="" goto ASK_START

:ASK_END
set /p "END_TIME=Enter End Time (HH:MM:SS or MM:SS or seconds): "
if "%END_TIME%"=="" goto ASK_END

:: ---------- OUTPUT FILE NAME ----------
set "BASENAME=!SELECTED_AUDIO:~0,-4!"
echo.
set /p "OUTPUT_NAME=Enter Output Name (default: !BASENAME!_cut): "
if "%OUTPUT_NAME%"=="" set "OUTPUT_NAME=!BASENAME!_cut"
set "OUTPUT_FILE=%OUTPUT_FOLDER%\!OUTPUT_NAME!.mp3"

echo --------------------------------------------------------------------------------
echo Input File : !SELECTED_AUDIO!
echo Start Time : !START_TIME!
echo End Time   : !END_TIME!
echo Output File: !OUTPUT_NAME!.mp3
echo --------------------------------------------------------------------------------
echo.

:: ---------- AUTO-CUT OPERATION ----------
echo ✂️ Cutting audio precisely...
echo Please wait...

%FFMPEG% -y -ss !START_TIME! -to !END_TIME! -i "!INPUT_FILE!" -c copy "%OUTPUT_FILE%" -loglevel error -stats

if errorlevel 1 (
    echo [ERROR] Cutting failed!
    pause
    exit /b
)

:: ---------- CLEANUP TEMP FOLDER ----------
if exist "%TEMP%" (
    echo 🧹 Cleaning up temporary files...
    rmdir /s /q "%TEMP%" >nul 2>&1
)

echo.
echo ✅ Successfully cut audio!
echo 📁 Output saved at: !OUTPUT_FILE!
echo --------------------------------------------------------------------------------
pause
exit /b

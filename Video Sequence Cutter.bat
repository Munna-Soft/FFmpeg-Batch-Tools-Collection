@echo off
REM ============================================================
REM     Perfect Video Cutter Tools - by Munna MasterMind
REM         https://munna-soft.github.io/Portfolio
REM        	    Author: Munna MasterMind
REM ============================================================

setlocal enabledelayedexpansion

:: ---------- FOLDER SETUP ----------
set "ROOT=%~dp0"
set "INPUT_FOLDER=%ROOT%Videos"
set "OUTPUT_FOLDER=%ROOT%Output"
set "TEMP=%ROOT%Temp"

if not exist "%INPUT_FOLDER%" (
    md "%INPUT_FOLDER%"
    echo [INFO] Created "Videos" folder. Please put your videos there and run this script again.
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

:: ---------- SCAN FOR VIDEOS ----------
echo Searching for video files in "%INPUT_FOLDER%"...
set "INDEX=0"
for %%E in (mp4 mov mkv avi webm) do (
    for %%F in ("%INPUT_FOLDER%\*.%%E") do (
        if exist "%%~fF" (
            set /a INDEX+=1
            set "VIDEO_!INDEX!=%%~nxF"
            set "VIDEO_PATH_!INDEX!=%%~fF"
        )
    )
)

if %INDEX%==0 (
    echo [ERROR] No videos found in "%INPUT_FOLDER%".
    pause
    exit /b
)

:: ---------- SELECT VIDEO ----------
:SELECT_VIDEO
cls
echo ================================================================================
echo                 Perfect Video Cutter Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ================================================================================
echo.
echo Available Videos:
for /l %%I in (1,1,%INDEX%) do (
    echo  %%I. !VIDEO_%%I!
)
echo --------------------------------------------------------------------------------
set /p "CHOICE=Select a video (1-%INDEX%): "
if "%CHOICE%"=="" goto SELECT_VIDEO
if %CHOICE% lss 1 goto SELECT_VIDEO
if %CHOICE% gtr %INDEX% goto SELECT_VIDEO

set "SELECTED_VIDEO=!VIDEO_%CHOICE%!"
set "INPUT_FILE=!VIDEO_PATH_%CHOICE%!"

echo.
echo Selected Video: !SELECTED_VIDEO!
echo --------------------------------------------------------------------------------

:: ---------- INPUT CUT TIMES ----------
:ASK_START
set /p "START_TIME=Enter Start Time (HH:MM:SS or MM:SS or seconds): "
if "%START_TIME%"=="" goto ASK_START

:ASK_END
set /p "END_TIME=Enter End Time (HH:MM:SS or MM:SS or seconds): "
if "%END_TIME%"=="" goto ASK_END

:: ---------- OUTPUT FILE NAME ----------
set "BASENAME=!SELECTED_VIDEO:~0,-4!"
set /p "OUTPUT_NAME=Enter Output Name (default: !BASENAME!_cut): "
if "%OUTPUT_NAME%"=="" set "OUTPUT_NAME=!BASENAME!_cut"
set "OUTPUT_FILE=%OUTPUT_FOLDER%\!OUTPUT_NAME!.mp4"

echo --------------------------------------------------------------------------------
echo Input File : !SELECTED_VIDEO!
echo Start Time : !START_TIME!
echo End Time   : !END_TIME!
echo Output File: !OUTPUT_NAME!.mp4
echo --------------------------------------------------------------------------------
echo.

:: ---------- AUTO-CUT OPERATION ----------
echo 🎬 Cutting video precisely (frame accurate)...
echo Please wait...

%FFMPEG% -y -ss !START_TIME! -to !END_TIME! -i "!INPUT_FILE!" -c:v libx264 -preset veryfast -crf 22 -c:a aac "%OUTPUT_FILE%" -loglevel error -stats

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
echo ✅ Successfully cut video!
echo 📁 Output saved at: !OUTPUT_FILE!
echo --------------------------------------------------------------------------------
pause
exit /b

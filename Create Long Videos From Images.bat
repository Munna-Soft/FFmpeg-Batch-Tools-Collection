@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Create Long Videos From Images - by Munna MasterMind

REM --- Base directory ---
set "BASE_DIR=%~dp0"
set "FFMPEG_DIR=%BASE_DIR%FFmpeg"

REM --- FFmpeg/FFprobe/FFplay binaries check ---
if not exist "%FFMPEG_DIR%\ffmpeg.exe" (
    echo [ERROR] ffmpeg.exe not found in "FFmpeg" folder!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffprobe.exe" (
    echo [ERROR] ffprobe.exe not found in "FFmpeg" folder!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffplay.exe" (
    echo [ERROR] ffplay.exe not found in "FFmpeg" folder!
    pause
    exit /b
)

REM --- Use local FFmpeg ---
set "FFM=%FFMPEG_DIR%\ffmpeg.exe"
set "FFP=%FFMPEG_DIR%\ffprobe.exe"

:: ---- Folder Paths ----
set "IMGDIR=%BASE_DIR%Images"
set "AUDDIR=%BASE_DIR%Audios"
set "OUT=%BASE_DIR%Output"
set "TEMP=%BASE_DIR%Temp"

if not exist "%IMGDIR%" mkdir "%IMGDIR%"
if not exist "%AUDDIR%" mkdir "%AUDDIR%"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%TEMP%" md "%TEMP%"

echo.
echo        ╔═══════════════════════════════════════════════════════╗
echo        ║  Create Long Videos From Images by - Munna MasterMind ║
echo        ║        https://munna-soft.github.io/Portfolio         ║
echo        ║             https://facebook.com/The.Munna            ║
echo        ╚═══════════════════════════════════════════════════════╝
echo.

set i=0
echo ========== Available Images ==========
for %%F in ("%IMGDIR%\*.jpg" "%IMGDIR%\*.jpeg" "%IMGDIR%\*.png" "%IMGDIR%\*.bmp" "%IMGDIR%\*.webp") do (
    set /a i+=1
    set "IMG!i!=%%~fF"
    echo   !i!. %%~nxF
)

if %i%==0 (
    echo ❌ No image files found in %IMGDIR%!
    echo Please put your image files inside the "Images" folder.
    pause
    exit /b
)
echo ------------------------------------------
echo.

:ASKIMG
set "IMGCHOICE="
set /p "IMGCHOICE=Select Your Image [1-%i%]: "
if "%IMGCHOICE%"=="" goto ASKIMG
set "IMAGE=!IMG%IMGCHOICE%!"
if not defined IMAGE (
    echo ❌ Invalid selection!
    goto ASKIMG
)

echo.
echo ➜ You Selected: %IMAGE%
echo.

:: ---- STEP 2: SELECT AUDIO ----
set j=0
echo ========== Available Audios ==========
echo   1. None (No Music)
set "AUD1="

for %%F in ("%AUDDIR%\*.mp3" "%AUDDIR%\*.wav" "%AUDDIR%\*.m4a" "%AUDDIR%\*.aac" "%AUDDIR%\*.flac" "%AUDDIR%\*.ogg") do (
    set /a j+=1
    set /a idx=j+1
    set "AUD!idx!=%%~fF"
    echo   !idx!. %%~nxF
)

set /a TOTAL=j+1
if %TOTAL%==1 (
    echo ❌ No audio files found in %AUDDIR%!
    echo Continuing without audio...
    set "AUDCHOICE=1"
    goto AFTER_AUDIO
)
echo ------------------------------------------
echo.

:ASKAUD
set "AUDCHOICE="
set /p "AUDCHOICE=Select Your Audio [1-%TOTAL%]: "
if "%AUDCHOICE%"=="" goto ASKAUD

set "AUDIO=!AUD%AUDCHOICE%!"
if not defined AUDIO (
    if "%AUDCHOICE%"=="1" (
        set "AUDIO="
    ) else (
        echo ❌ Invalid selection!
        goto ASKAUD
    )
)

:AFTER_AUDIO
echo.
if "%AUDCHOICE%"=="1" (
    echo ➜ You Selected: None (No music will be added)
) else (
    echo ➜ You Selected: !AUDIO!
    :: Get audio duration
    if exist "%TEMP%\audio_dur.txt" del "%TEMP%\audio_dur.txt"
    "%FFP%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%AUDIO%" > "%TEMP%\audio_dur.txt" 2>nul
    set /p "AUDIO_DURATION=" < "%TEMP%\audio_dur.txt" 2>nul
    if "!AUDIO_DURATION!"=="" (
        set "AUDIO_DURATION=0"
    ) else (
        echo Audio Duration: !AUDIO_DURATION! seconds
    )
)
echo.

:: ---- STEP 3: ASK VIDEO DURATION ----
:ASKDUR
echo ========== Video Duration (Examples) ==========
echo     5       = 5 minutes
echo     10      = 10 minutes
echo     1:30    = 1 hour 30 minutes
echo     2:45    = 2 hours 45 minutes
echo     10:15   = 10 hours 15 minutes
echo     24:00   = 24 hours 0 minutes
echo ==================================================
echo.
set "USERDUR="
set /p "USERDUR=Enter Video Duration - max 24 Hours (HH:MM or minutes): "

if "%USERDUR%"=="" goto BADINPUT

:: remove spaces
set "USERDUR=%USERDUR: =%"

:: parse either H:MM or minutes-only
echo %USERDUR% | findstr ":" >nul 2>&1
if errorlevel 1 (
    set "HOURS=0"
    set "MINS=%USERDUR%"
) else (
    for /f "tokens=1,2 delims=:" %%A in ("%USERDUR%") do (
        set "HOURS=%%A"
        set "MINS=%%B"
    )
)

:: default to 0 if empty
if not defined HOURS set "HOURS=0"
if not defined MINS set "MINS=0"

:: Validate numeric and compute total minutes safely
set "BAD=0"
set /a TOTMIN=HOURS*60+MINS 2>nul || set "BAD=1"
if "%BAD%"=="1" goto BADINPUT

:: Reject invalid minutes part (0-59)
set /a MINPART=MINS 2>nul
if %MINPART% LSS 0 goto BADINPUT
if %MINPART% GEQ 60 goto BADINPUT

:: Ensure total minutes in (0 .. 1440]
if %TOTMIN% LEQ 0 goto BADINPUT
if %TOTMIN% GTR 1440 goto BADINPUT

:: Build HH:MM:SS (zero-padded)
set /a HH = TOTMIN / 60
set /a MM = TOTMIN %% 60
if %HH% LSS 10 (set "HH=0%HH%")
if %MM% LSS 10 (set "MM=0%MM%")
set "DUR=%HH%:%MM%:00"
set /a TARGET_SECONDS = (HH * 3600) + (MM * 60)

echo ➜ Selected Duration: %DUR% (!TARGET_SECONDS! seconds)
goto ASKRES

:BADINPUT
echo.
echo ❌ Invalid input! Please type correctly (examples: 5, 10, 1:30, 10:15, 24:00).
echo.
goto ASKDUR

:: ---- STEP 4: ASK RESOLUTION ----
:ASKRES
echo.
echo ========== Select Resolution ==========
echo     1. 720p (1280x720)
echo     2. 1080p (1920x1080)
echo     3. 2K (2560x1440)
echo     4. 4K (3840x2160)
echo ==================================================
echo.
set /p "RESCHOICE=Enter Your Choice [1-4]: "

if "%RESCHOICE%"=="" set "RESCHOICE=1"

if "%RESCHOICE%"=="1" (
    set "WIDTH=1280"
    set "HEIGHT=720"
    set "RESNAME=720p"
    set "SCALE_FILTER=scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2"
) else if "%RESCHOICE%"=="2" (
    set "WIDTH=1920"
    set "HEIGHT=1080"
    set "RESNAME=1080p"
    set "SCALE_FILTER=scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
) else if "%RESCHOICE%"=="3" (
    set "WIDTH=2560"
    set "HEIGHT=1440"
    set "RESNAME=2K"
    set "SCALE_FILTER=scale=2560:1440:force_original_aspect_ratio=decrease,pad=2560:1440:(ow-iw)/2:(oh-ih)/2"
) else if "%RESCHOICE%"=="4" (
    set "WIDTH=3840"
    set "HEIGHT=2160"
    set "RESNAME=4K"
    set "SCALE_FILTER=scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2"
) else (
    echo Invalid choice & goto ASKRES
)

echo.
echo ------------------------------------------
echo 📊 PROCESSING SUMMARY:
echo    Image: %IMAGE%
if "%AUDCHOICE%"=="1" (
    echo    Audio: None
) else (
    echo    Audio: !AUDIO!
    echo    Audio Duration: !AUDIO_DURATION! seconds
)
echo    Video Duration: %DUR% (!TARGET_SECONDS! seconds)
echo    Resolution: %RESNAME% (!WIDTH!x!HEIGHT!)
echo ------------------------------------------
echo.

:: ---- STEP 5: CREATE FINAL VIDEO DIRECTLY ----
for %%Z in ("%IMAGE%") do set "IMG_NAME=%%~nZ"
set "DURSAFE=%DUR::=-%"
set "FINAL=%OUT%\!IMG_NAME!_%RESNAME%_%DURSAFE%.mp4"

echo 🔄 Creating final video...
echo.

REM --- Create video directly without temp file ---
if "%AUDCHOICE%"=="1" (
    REM --- NO AUDIO ---
    echo Creating silent video...
    
    "%FFM%" -y -hide_banner -loglevel error -stats ^
        -loop 1 -i "%IMAGE%" ^
        -t %DUR% ^
        -vf "%SCALE_FILTER%,format=yuv420p" ^
        -c:v libx264 -preset ultrafast -crf 25 ^
        -r 25 ^
        "%FINAL%"
) else (
    REM --- WITH AUDIO ---
    echo Creating video with audio...
    
    if !AUDIO_DURATION! LSS !TARGET_SECONDS! (
        REM Audio is shorter - need to loop audio
        echo Audio is shorter than target - looping audio...
        
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -loop 1 -i "%IMAGE%" ^
            -stream_loop -1 -i "%AUDIO%" ^
            -t %DUR% ^
            -vf "%SCALE_FILTER%,format=yuv420p" ^
            -c:v libx264 -preset ultrafast -crf 25 ^
            -c:a aac -b:a 192k ^
            -shortest ^
            "%FINAL%"
    ) else (
        REM Audio is long enough
        echo Audio is long enough - using as is...
        
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -loop 1 -i "%IMAGE%" ^
            -i "%AUDIO%" ^
            -t %DUR% ^
            -vf "%SCALE_FILTER%,format=yuv420p" ^
            -c:v libx264 -preset ultrafast -crf 25 ^
            -c:a aac -b:a 192k ^
            -shortest ^
            "%FINAL%"
    )
)

:: ---- STEP 6: CLEANUP AND FINAL MESSAGE ----
if exist "%TEMP%\audio_dur.txt" del /q "%TEMP%\audio_dur.txt" >nul 2>&1

if exist "%FINAL%" (
    echo.
    echo ==================================================
    echo ✅ SUCCESS! Video created successfully!
    echo ==================================================
    echo 📁 File: %FINAL%
    echo 📊 Settings:
    echo   - Image: %IMG_NAME%
    echo   - Resolution: %RESNAME% (!WIDTH!x!HEIGHT!)
    echo   - Duration: %DUR%
    echo.
    echo 📦 File size:
    for %%F in ("%FINAL%") do (
        set "BYTES=%%~zF"
        if "!BYTES!"=="" set "BYTES=0"
        set /a MEGABYTES=BYTES/1048576
        if !MEGABYTES! GTR 0 (
            echo   !MEGABYTES! MB (!BYTES! bytes)
        ) else (
            set /a KILOBYTES=BYTES/1024
            echo   !KILOBYTES! KB (!BYTES! bytes)
        )
    )
)
REM --- Code by Munna MasterMind ---
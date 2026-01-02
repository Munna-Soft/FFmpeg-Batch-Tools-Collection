@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Create Long Videos With SlowMotion- by Munna MasterMind

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
set "VIDDIR=%ROOT%Videos"
set "AUDDIR=%ROOT%Audios"
set "OUT=%ROOT%Output"
set "TEMP=%ROOT%Temp"

if not exist "%VIDDIR%" md "%VIDDIR%"
if not exist "%AUDDIR%" md "%AUDDIR%"
if not exist "%OUT%" md "%OUT%"
if not exist "%TEMP%" md "%TEMP%"

echo.
echo        ╔══════════════════════════════════════════════════════════╗
echo        ║ Create Long Videos With SlowMotion by - Munna MasterMind ║
echo        ║          https://munna-soft.github.io/Portfolio          ║
echo        ║               https://facebook.com/The.Munna             ║
echo        ╚══════════════════════════════════════════════════════════╝
echo.

set i=0
echo =========== Available Videos ===========
for %%F in ("%VIDDIR%\*.mp4" "%VIDDIR%\*.mov" "%VIDDIR%\*.mkv" "%VIDDIR%\*.webm" "%VIDDIR%\*.avi") do (
    set /a i+=1
    set "VID!i!=%%~fF"
    echo   !i!. %%~nxF
)
if %i%==0 echo ❌ No video files found in %VIDDIR%! & pause & exit /b
echo ------------------------------------------
echo.
set /p "VIDCHOICE=Select Your Video [1-%i%]: "
set "VIDEO=!VID%VIDCHOICE%!"
if not defined VIDEO echo ❌ Invalid selection & pause & exit /b
echo.

:: ---- LIST AVAILABLE AUDIO ----
set j=0
echo =========== Available Music ===========
echo   1. None (No Music)
set "AUD1="

for %%F in ("%AUDDIR%\*.mp3" "%AUDDIR%\*.wav" "%AUDDIR%\*.m4a" "%AUDDIR%\*.aac") do (
    set /a j+=1
    set /a idx=j+1
    set "AUD!idx!=%%~fF"
    echo   !idx!. %%~nxF
)

set /a TOTAL=j+1
echo ------------------------------------------
echo. 

set /p "AUDCHOICE=Select Your Audio [1-%TOTAL%]: "
set "AUDIO=!AUD%AUDCHOICE%!"

if not defined AUDIO (
    if "%AUDCHOICE%"=="1" (
        set "AUDIO="
    ) else (
        echo ❌ Invalid selection
        pause
        exit /b
    )
)

echo.

if "%AUDCHOICE%"=="1" (
    echo ➜ You Selected: None (No music will be added)
) else (
    echo ➜ You Selected: !AUDIO!
)
echo.
pause

:: ---- GET ORIGINAL VIDEO RESOLUTION AND DURATION ----
echo Getting original video resolution and duration...
"%FFP%" -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "%VIDEO%" > "%TEMP%\resolution.txt" 2>nul
set /p "ORIGINAL_RES=" < "%TEMP%\resolution.txt" 2>nul
for /f "tokens=1,2 delims=x" %%A in ("!ORIGINAL_RES!") do (
    set "ORIG_WIDTH=%%A"
    set "ORIG_HEIGHT=%%B"
)

"%FFP%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%VIDEO%" > "%TEMP%\duration.txt" 2>nul
set /p "ORIG_DURATION=" < "%TEMP%\duration.txt" 2>nul

echo Original resolution: !ORIG_WIDTH!x!ORIG_HEIGHT!
echo Original duration: !ORIG_DURATION! seconds

:: ---- CHECK IF VIDEO HAS AUDIO ----
echo Checking if video has audio stream...
"%FFP%" -v error -select_streams a -show_entries stream=index -of csv=p=0 "%VIDEO%" > "%TEMP%\has_audio.txt" 2>nul
set /p "HAS_AUDIO=" < "%TEMP%\has_audio.txt" 2>nul
if "!HAS_AUDIO!"=="" (
    set "HAS_VIDEO_AUDIO=0"
    echo Video has NO audio stream
) else (
    set "HAS_VIDEO_AUDIO=1"
    echo Video has audio stream
)

:: ---- ASK SLOW-MOTION SPEED ----
:ASKSPEED
cls
echo.
echo        ╔══════════════════════════════════════════════════════════╗
echo        ║ Create Long Videos With SlowMotion by - Munna MasterMind ║
echo        ║          https://munna-soft.github.io/Portfolio          ║
echo        ║               https://facebook.com/The.Munna             ║
echo        ╚══════════════════════════════════════════════════════════╝
echo.

echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
if "%AUDCHOICE%"=="1" (
    echo Audio: None (No Music)
) else (
    echo Audio: %AUDIO%
)
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo Original Duration: !ORIG_DURATION! seconds
echo ------------------------------------------
echo. 
echo Select Slow-Motion Speed:
echo     1. Ultra Slow (0.25x) - 4 times slower
echo     2. Very Slow (0.33x) - 3 times slower
echo     3. Slow (0.5x) - 2 times slower
echo     4. Slightly Slow (0.75x) - 1.33 times slower
echo     5. Custom Speed (enter value between 0.1 to 0.9)
echo ==================================================
echo. 
set /p "SPEEDCHOICE=Enter Your Choice [1-5]: "

if "%SPEEDCHOICE%"=="1" (
    set "SLOW_FACTOR=0.25"
    set "PTS_MULTIPLIER=4.0"
    set "ATEMPO_FILTER=atempo=0.5,atempo=0.5"
    set "SPEEDNAME=Ultra Slow (0.25x)"
) else if "%SPEEDCHOICE%"=="2" (
    set "SLOW_FACTOR=0.3333"
    set "PTS_MULTIPLIER=3.0"
    set "ATEMPO_FILTER=atempo=0.576,atempo=0.576"
    set "SPEEDNAME=Very Slow (0.33x)"
) else if "%SPEEDCHOICE%"=="3" (
    set "SLOW_FACTOR=0.5"
    set "PTS_MULTIPLIER=2.0"
    set "ATEMPO_FILTER=atempo=0.5"
    set "SPEEDNAME=Slow (0.5x)"
) else if "%SPEEDCHOICE%"=="4" (
    set "SLOW_FACTOR=0.75"
    set "PTS_MULTIPLIER=1.3333"
    set "ATEMPO_FILTER=atempo=0.75"
    set "SPEEDNAME=Slightly Slow (0.75x)"
) else if "%SPEEDCHOICE%"=="5" (
    :CUSTOMSPEED
    echo.
    set /p "CUSTOM_FACTOR=Enter custom slow factor (0.1 to 0.9, e.g., 0.25 for 0.25x): "
    
    :: Validate input is numeric
    echo !CUSTOM_FACTOR! | findstr /r "^[0-9]*\.\?[0-9]*$" >nul
    if errorlevel 1 (
        echo ❌ Invalid input! Please enter a number.
        timeout /t 2 /nobreak >nul
        goto CUSTOMSPEED
    )
    
    :: Validate range
    if "!CUSTOM_FACTOR!" LSS "0.1" (
        echo ❌ Too slow! Minimum is 0.1x
        timeout /t 2 /nobreak >nul
        goto CUSTOMSPEED
    )
    if "!CUSTOM_FACTOR!" GTR "0.9" (
        echo ❌ Too fast! Maximum is 0.9x
        timeout /t 2 /nobreak >nul
        goto CUSTOMSPEED
    )
    
    set "SLOW_FACTOR=!CUSTOM_FACTOR!"
    
    :: Calculate PTS multiplier (1 / slow_factor)
    for /f "tokens=*" %%A in ('powershell -Command "1/!CUSTOM_FACTOR!"') do set "PTS_MULTIPLIER=%%A"
    
    :: Handle audio tempo - FFmpeg's atempo filter supports 0.5 to 2.0 range
    :: For very slow speeds, we need multiple atempo filters
    if !CUSTOM_FACTOR! GEQ 0.5 (
        set "ATEMPO_FILTER=atempo=!CUSTOM_FACTOR!"
    ) else if !CUSTOM_FACTOR! GEQ 0.25 (
        set "ATEMPO_FILTER=atempo=0.5,atempo=!CUSTOM_FACTOR!/0.5!"
    ) else (
        set "ATEMPO_FILTER=atempo=0.5,atempo=0.5,atempo=!CUSTOM_FACTOR!/0.25!"
    )
    
    set "SPEEDNAME=Custom (!CUSTOM_FACTOR!x)"
) else (
    echo Invalid choice & goto ASKSPEED
)
echo.

:: ---- ASK DURATION (flexible: minutes or HH:MM) ----
:ASKD
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
if "%AUDCHOICE%"=="1" (
    echo Audio: None (No Music)
) else (
    echo Audio: %AUDIO%
)
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo Original Duration: !ORIG_DURATION! seconds
echo Selected Speed: !SPEEDNAME! (!SLOW_FACTOR!x)
echo ------------------------------------------
echo. 
echo Examples Duration:
echo    5       = 5 minutes
echo    10      = 10 minutes
echo    1:30    = 1 hour 30 minutes
echo    2:45    = 2 hours 45 minutes
echo    10:15   = 10 hours 15 minutes
echo    24:00   = 24 hours 0 minutes
echo ==================================================
echo. 

set "USERDUR="
set /p "USERDUR=Enter Video Duration - max 24 Hours (HH:MM or minutes): "
echo.

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
goto ASKR

:BADINPUT
echo.
echo ❌ Invalid input! Please type correctly (examples: 5, 10, 1:30, 10:15, 24:00).
timeout /t 2 /nobreak >nul
goto ASKD

:: ---- ASK RESOLUTION ----
:ASKR
echo Video: %VIDEO% (!ORIG_WIDTH!x!ORIG_HEIGHT!)
if "%AUDCHOICE%"=="1" (
    echo Audio: None
) else (
    echo Audio: %AUDIO%
)
echo Video In Audio: !HAS_VIDEO_AUDIO! (1=Yes, 0=No)
echo Original Duration: !ORIG_DURATION! seconds
echo Selected Speed: !SPEEDNAME! (!SLOW_FACTOR!x)
echo Duration: %DUR% [Selected]
echo ------------------------------------------
echo. 
echo Select resolution:
echo     1. Original Resolution (!ORIG_WIDTH!x!ORIG_HEIGHT!)
echo     2. 720p (1280x720)
echo     3. 1080p (1920x1080)
echo     4. 2K (2560x1440)
echo     5. 4K (3840x2160)
echo ==================================================
echo. 
set /p "RESCHOICE=Enter Your Choice [1-5]: "
echo.

if "%RESCHOICE%"=="" set "RESCHOICE=1"

if "%RESCHOICE%"=="1" (
    set "WIDTH=!ORIG_WIDTH!"
    set "HEIGHT=!ORIG_HEIGHT!"
    set "RESNAME=Original"
    set "SCALE_FILTER="
) else if "%RESCHOICE%"=="2" (
    set "WIDTH=1280"
    set "HEIGHT=720"
    set "RESNAME=720p"
    set "SCALE_FILTER=scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="3" (
    set "WIDTH=1920"
    set "HEIGHT=1080"
    set "RESNAME=1080p"
    set "SCALE_FILTER=scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="4" (
    set "WIDTH=2560"
    set "HEIGHT=1440"
    set "RESNAME=2K"
    set "SCALE_FILTER=scale=2560:1440:force_original_aspect_ratio=decrease,pad=2560:1440:(ow-iw)/2:(oh-ih)/2,"
) else if "%RESCHOICE%"=="5" (
    set "WIDTH=3840"
    set "HEIGHT=2160"
    set "RESNAME=4K"
    set "SCALE_FILTER=scale=3840:2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2,"
) else (
    echo Invalid choice & goto ASKR
)

echo ➜ Building %DUR% %RESNAME% video with !SPEEDNAME! effect...

:: ---- STEP 1: CREATE SLOW-MOTION VIDEO ----
set "SLOW_VIDEO=%TEMP%\slow_video_temp.mp4"

echo 🔄 Step 1: Creating slow-motion video (!SLOW_FACTOR!x speed)...
echo.

if defined SCALE_FILTER (
    set "VIDEO_FILTER=%SCALE_FILTER%setpts=!PTS_MULTIPLIER!*PTS,format=yuv420p"
) else (
    set "VIDEO_FILTER=setpts=!PTS_MULTIPLIER!*PTS,format=yuv420p"
)

if "!HAS_VIDEO_AUDIO!"=="1" (
    echo Applying video filter: !VIDEO_FILTER!
    echo Applying audio filter: !ATEMPO_FILTER!
    
    "%FFM%" -y -hide_banner -loglevel error -stats -i "%VIDEO%" ^
        -filter_complex "[0:v]!VIDEO_FILTER![v];[0:a]!ATEMPO_FILTER![a]" ^
        -map "[v]" -map "[a]" -c:v libx264 -preset ultrafast -crf 25 -c:a aac -b:a 128k ^
        "%SLOW_VIDEO%"
) else (
    echo Applying video filter: !VIDEO_FILTER!
    
    "%FFM%" -y -hide-banner -loglevel error -stats -i "%VIDEO%" ^
        -filter_complex "!VIDEO_FILTER!" ^
        -c:v libx264 -preset ultrafast -crf 25 ^
        "%SLOW_VIDEO%"
)

if not exist "%SLOW_VIDEO%" (echo ❌ Step 1 failed: Could not create slow-motion video & pause & exit /b 1)

:: ---- STEP 2: GET SLOW VIDEO DURATION ----
"%FFP%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%SLOW_VIDEO%" > "%TEMP%\slow_duration.txt" 2>nul
set /p "SLOW_DURATION=" < "%TEMP%\slow_duration.txt" 2>nul
echo Slow video duration: !SLOW_DURATION! seconds

:: ---- STEP 3: LOOP THE SLOW VIDEO TO REACH TARGET DURATION ----
set "DURSAFE=%DUR::=-%"
set "FINAL=%OUT%\SlowMo-!SLOW_FACTOR!x_%RESNAME%.mp4"

echo 🔄 Step 2: Looping slow video to reach target duration...

if "%AUDCHOICE%"=="1" (
    :: No external music
    if "!HAS_VIDEO_AUDIO!"=="1" (
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -stream_loop -1 -i "%SLOW_VIDEO%" ^
            -t %DUR% -c copy "%FINAL%"
    ) else (
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -stream_loop -1 -i "%SLOW_VIDEO%" ^
            -t %DUR% -c:v copy "%FINAL%"
    )
) else (
    :: With external music
    if "!HAS_VIDEO_AUDIO!"=="1" (
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -stream_loop -1 -i "%SLOW_VIDEO%" -i "%AUDIO%" ^
            -filter_complex "[0:a][1:a]amix=inputs=2:duration=longest[a]" ^
            -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 128k ^
            -t %DUR% "%FINAL%"
    ) else (
        "%FFM%" -y -hide_banner -loglevel error -stats ^
            -stream_loop -1 -i "%SLOW_VIDEO%" -i "%AUDIO%" ^
            -map 0:v -map 1:a -c:v copy -c:a aac -b:a 128k ^
            -t %DUR% "%FINAL%"
    )
)

:: ---- CLEANUP ----
del /q "%TEMP%\has_audio.txt" >nul 2>&1
del /q "%TEMP%\resolution.txt" >nul 2>&1
del /q "%TEMP%\duration.txt" >nul 2>&1
del /q "%TEMP%\slow_duration.txt" >nul 2>&1
del /q "%SLOW_VIDEO%" >nul 2>&1

if exist "%FINAL%" (
    echo.
    echo ==================================================
    echo ✅ SUCCESS! Video created successfully!
    echo ==================================================
    echo File: %FINAL%
    echo Settings:
    echo   - Resolution: %RESNAME% (!WIDTH!x!HEIGHT!)
    echo   - Speed: !SPEEDNAME! (!SLOW_FACTOR!x normal speed)
    echo   - Duration: %DUR%
    echo   - Original Duration: !ORIG_DURATION! seconds
    echo.
    echo File size:
    for %%F in ("%FINAL%") do (
        set "BYTES=%%~zF"
        set /a MEGABYTES=BYTES/1048576
        echo   !MEGABYTES! MB (!BYTES! bytes)
    )
    echo ==================================================
) else (
    echo 
)
pause
REM --- Code by Munna MasterMind ---
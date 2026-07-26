@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Create Long Videos From Images - by Munna MasterMind

REM --- Base directory ---
set "BASE_DIR=%~dp0"
set "FFMPEG_DIR=%BASE_DIR%FFmpeg"

REM --- FFmpeg/FFprobe/FFplay binaries check ---
if not exist "%FFMPEG_DIR%\ffmpeg.exe" (
    echo [ERROR] ffmpeg.exe not found in "FFmpeg" folder^^!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffprobe.exe" (
    echo [ERROR] ffprobe.exe not found in "FFmpeg" folder^^!
    pause
    exit /b
)
if not exist "%FFMPEG_DIR%\ffplay.exe" (
    echo [ERROR] ffplay.exe not found in "FFmpeg" folder^^!
    pause
    exit /b
)

REM --- Use local FFmpeg ---
set "FFM=%FFMPEG_DIR%\ffmpeg.exe"
set "FFP=%FFMPEG_DIR%\ffprobe.exe"

REM ---- Folder Paths ----
REM NOTE: the work folder variable is TMPD, not TEMP - overwriting the system
REM TEMP variable can break ffmpeg and any other child process.
set "IMGDIR=%BASE_DIR%Images"
set "AUDDIR=%BASE_DIR%Audios"
set "OUT=%BASE_DIR%Output"
set "TMPD=%BASE_DIR%Temp"

if not exist "%IMGDIR%" mkdir "%IMGDIR%"
if not exist "%AUDDIR%" mkdir "%AUDDIR%"
if not exist "%OUT%" mkdir "%OUT%"
if not exist "%TMPD%" mkdir "%TMPD%"

REM --- Global output frame rate (drives the seamless-loop math everywhere) ---
set "FPS=25"

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
    echo ❌ No image files found in %IMGDIR%^^!
    echo Please put your image files inside the "Images" folder.
    pause
    exit /b
)
echo ------------------------------------------
echo.

set "TRYIMG=0"
:ASKIMG
set /a TRYIMG+=1
if !TRYIMG! GTR 12 goto TOOMANY
set "IMGCHOICE="
set /p "IMGCHOICE=Select Your Image [1-%i%]: "
if "%IMGCHOICE%"=="" goto ASKIMG
set "IMAGE=!IMG%IMGCHOICE%!"
if not defined IMAGE (
    echo ❌ Invalid selection^^!
    goto ASKIMG
)

echo.
echo ➜ You Selected: %IMAGE%
echo.

REM ---- STEP 2: SELECT AUDIO ----
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
    echo ❌ No audio files found in %AUDDIR%^^!
    echo Continuing without audio...
    set "AUDCHOICE=1"
    goto AFTER_AUDIO
)
echo ------------------------------------------
echo.

set "TRYAUD=0"
:ASKAUD
set /a TRYAUD+=1
if !TRYAUD! GTR 12 goto TOOMANY
set "AUDCHOICE="
set /p "AUDCHOICE=Select Your Audio [1-%TOTAL%]: "
if "%AUDCHOICE%"=="" goto ASKAUD

set "AUDIO=!AUD%AUDCHOICE%!"
if not defined AUDIO (
    if "%AUDCHOICE%"=="1" (
        set "AUDIO="
    ) else (
        echo ❌ Invalid selection^^!
        goto ASKAUD
    )
)

REM ============================================================================
REM  Read the audio length as a real INTEGER number of seconds.
REM  ffprobe returns something like 345.123456 and the old code fed that string
REM  straight into "if LSS", which is a TEXT compare in cmd - so for example
REM  "9.500000" counted as LARGER than "100". That made the audio/target test
REM  pick the wrong branch, which is how the audio ended up being cut.
REM ============================================================================
:AFTER_AUDIO
echo.
set "AUDIO_DURATION="
set "AUD_INT=0"
set "AUD_CEIL=0"
set "AUD_HMS="

if "%AUDCHOICE%"=="1" goto NOAUDIO_INFO
if not defined AUDIO goto NOAUDIO_INFO

echo ➜ You Selected: !AUDIO!
if exist "%TMPD%\audio_dur.txt" del /q "%TMPD%\audio_dur.txt" >nul 2>&1
"%FFP%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "!AUDIO!" > "%TMPD%\audio_dur.txt" 2>nul
set /p "AUDIO_DURATION=" < "%TMPD%\audio_dur.txt"
if not defined AUDIO_DURATION goto AUDIO_DUR_FAIL
if "!AUDIO_DURATION!"=="N/A" goto AUDIO_DUR_FAIL

set "_AI=" & set "_AF="
for /f "tokens=1,2 delims=." %%a in ("!AUDIO_DURATION!") do (
    set "_AI=%%a"
    set "_AF=%%b"
)
call :TONUM "!_AI!"
if not defined _NUM goto AUDIO_DUR_FAIL
set /a AUD_INT=_NUM
set /a AUD_CEIL=AUD_INT
REM round UP when there is a fractional part, so "Auto" never clips the tail
set "_AFZ=!_AF!000"
if not "!_AFZ:~0,3!"=="000" set /a AUD_CEIL=AUD_INT+1
call :FMTTIME !AUD_INT!
set "AUD_HMS=!_HMS!"
echo    Audio Length: !AUD_HMS!  ^(!AUDIO_DURATION! seconds^)
goto AUDIO_INFO_DONE

:AUDIO_DUR_FAIL
echo    [^^!] Could not read the audio length - the "Auto" duration option will be unavailable.
set "AUD_INT=0"
set "AUD_CEIL=0"
goto AUDIO_INFO_DONE

:NOAUDIO_INFO
set "AUDIO="
echo ➜ You Selected: None ^(No music will be added^)

:AUDIO_INFO_DONE
echo.

REM ============================================================================
REM  STEP 3: ASK VIDEO DURATION
REM  The old parser only understood whole minutes or H:MM, so a 5 min 45 sec
REM  song could only be asked for as "5" and the last 45 seconds were lost.
REM  Seconds are supported now, plus an "Auto" mode that matches the audio.
REM ============================================================================
set "TRYDUR=0"
:ASKDUR
set /a TRYDUR+=1
if !TRYDUR! GTR 12 goto TOOMANY
echo ========== Video Duration ==========
echo    Type the duration in ANY of these ways:
echo.
if !AUD_CEIL! GTR 0 echo      A          = Auto - match the audio length exactly  ^(recommended^)
echo      45s        = 45 seconds
echo      10         = 10 minutes
echo      90m        = 90 minutes
echo      2h         = 2 hours
echo      5:45       = 5 min 45 sec          ^(MM:SS^)
echo      1:30:00    = 1 hour 30 min         ^(HH:MM:SS^)
echo      10:15:00   = 10 hours 15 min
echo      24:00:00   = 24 hours  ^(maximum^)
echo ====================================================
echo   Reminder: 5:45 means 5 min 45 sec, exactly like FFmpeg.
echo   For 5 hours 45 minutes type 5:45:00
echo ====================================================
echo.
set "USERDUR="
set "TARGET_SECONDS="
set "DURMODE=Manual"
set /p "USERDUR=Enter Video Duration (max 24 hours): "
if not defined USERDUR goto BADINPUT
set "USERDUR=%USERDUR: =%"

if /i "%USERDUR%"=="a" goto DUR_AUTO
if /i "%USERDUR%"=="auto" goto DUR_AUTO
goto DUR_PARSE

:DUR_AUTO
if !AUD_CEIL! LEQ 0 (
    echo.
    echo ❌ "Auto" needs a readable audio file. Please type a duration instead.
    echo.
    goto ASKDUR
)
set /a TARGET_SECONDS=AUD_CEIL
set "DURMODE=Auto (matched to audio)"
goto DUR_VALIDATE

:DUR_PARSE
REM --- optional s / m / h suffix ---
set "UNIT="
set "SUF=%USERDUR:~-1%"
if /i "%SUF%"=="s" set "UNIT=S"
if /i "%SUF%"=="m" set "UNIT=M"
if /i "%SUF%"=="h" set "UNIT=H"
if defined UNIT set "USERDUR=%USERDUR:~0,-1%"
if not defined USERDUR goto BADINPUT

REM Colon test done with plain string replacement - no pipe, nothing to escape.
if not "!USERDUR!"=="!USERDUR::=!" goto DUR_HASCOLON
goto DUR_PLAIN

:DUR_HASCOLON
REM a suffix together with colons makes no sense (e.g. "5:45m")
if defined UNIT goto BADINPUT
goto DUR_COLON

:DUR_PLAIN
call :TONUM "%USERDUR%"
if not defined _NUM goto BADINPUT
if "%UNIT%"=="S" (
    set /a TARGET_SECONDS=_NUM
) else if "%UNIT%"=="H" (
    set /a TARGET_SECONDS=_NUM*3600
) else (
    REM no suffix means minutes, keeping this tool's original behaviour
    set /a TARGET_SECONDS=_NUM*60
)
goto DUR_VALIDATE

:DUR_COLON
set "P1=" & set "P2=" & set "P3=" & set "P4="
for /f "tokens=1,2,3,4 delims=:" %%A in ("%USERDUR%") do (
    set "P1=%%A"
    set "P2=%%B"
    set "P3=%%C"
    set "P4=%%D"
)
if defined P4 goto BADINPUT
if not defined P2 goto BADINPUT

set "_H=0" & set "_M=0" & set "_S=0"
if defined P3 (
    call :TONUM "!P1!"
    if not defined _NUM goto BADINPUT
    set /a _H=_NUM
    call :TONUM "!P2!"
    if not defined _NUM goto BADINPUT
    set /a _M=_NUM
    call :TONUM "!P3!"
    if not defined _NUM goto BADINPUT
    set /a _S=_NUM
) else (
    call :TONUM "!P1!"
    if not defined _NUM goto BADINPUT
    set /a _M=_NUM
    call :TONUM "!P2!"
    if not defined _NUM goto BADINPUT
    set /a _S=_NUM
)

if !_S! GEQ 60 goto BADINPUT
if !_H! GTR 0 if !_M! GEQ 60 goto BADINPUT
set /a TARGET_SECONDS = _H*3600 + _M*60 + _S
goto DUR_VALIDATE

:DUR_VALIDATE
if not defined TARGET_SECONDS goto BADINPUT
if !TARGET_SECONDS! LEQ 0 goto BADINPUT
if !TARGET_SECONDS! GTR 86400 (
    echo.
    echo ❌ Maximum duration is 24 hours ^(86400 seconds^).
    echo.
    goto ASKDUR
)

REM Build the HH:MM:SS label from the integer second count.
REM The old code did the arithmetic on the zero-padded strings, so a value like
REM "08" was read as an invalid OCTAL number and TARGET_SECONDS came out empty.
call :FMTTIME !TARGET_SECONDS!
set "DUR=!_HMS!"

echo.
echo ➜ Duration: !DUR!   ^(!TARGET_SECONDS! seconds^) - !DURMODE!
if !AUD_INT! GTR 0 if !AUD_INT! GTR !TARGET_SECONDS! echo    [^^!] Your audio is longer than this - it will be cut at !DUR!.
if !AUD_INT! GTR 0 if !AUD_INT! LSS !TARGET_SECONDS! echo    [i] Your audio is shorter than this - it will be looped to fill !DUR!.
goto ASKFILTER

:BADINPUT
echo.
echo ❌ Invalid input^^! Examples: A, 45s, 10, 90m, 2h, 5:45, 1:30:00, 24:00:00
echo.
goto ASKDUR

REM ---- STEP 4: SELECT COLOR FILTER ----
:ASKFILTER
echo.
echo ========== Select Color Filter ==========
echo     1. None (Original Colors)
echo     2. Cinematic (Teal ^& Orange)
echo     3. Warm / Golden Hour
echo     4. Cool / Blue Night
echo     5. Black ^& White
echo     6. Vintage / Sepia
echo     7. Vivid (Punchy Colors)
echo     8. Dreamy Soft Glow
echo ==================================================
echo.
set "FILCHOICE="
set /p "FILCHOICE=Enter Your Choice [1-8]: "
if "%FILCHOICE%"=="" set "FILCHOICE=1"
if "%FILCHOICE%"=="1" goto FIL_1
if "%FILCHOICE%"=="2" goto FIL_2
if "%FILCHOICE%"=="3" goto FIL_3
if "%FILCHOICE%"=="4" goto FIL_4
if "%FILCHOICE%"=="5" goto FIL_5
if "%FILCHOICE%"=="6" goto FIL_6
if "%FILCHOICE%"=="7" goto FIL_7
if "%FILCHOICE%"=="8" goto FIL_8
echo ❌ Invalid choice^^!
goto ASKFILTER

:FIL_1
set "FILNAME=None (Original Colors)"
set "FILTAG="
set "COLOR_FILTER="
goto FILTER_DONE
:FIL_2
set "FILNAME=Cinematic (Teal and Orange)"
set "FILTAG=_cinematic"
set "COLOR_FILTER=curves=preset=increase_contrast,colorbalance=rs=-0.05:bs=0.08:rm=0.06:bm=-0.05:rh=0.04:bh=-0.04,eq=saturation=1.10,"
goto FILTER_DONE
:FIL_3
set "FILNAME=Warm / Golden Hour"
set "FILTAG=_warm"
set "COLOR_FILTER=colorbalance=rm=0.10:gm=0.03:bm=-0.10:rh=0.08:bh=-0.08,eq=saturation=1.12:contrast=1.06,"
goto FILTER_DONE
:FIL_4
set "FILNAME=Cool / Blue Night"
set "FILTAG=_cool"
set "COLOR_FILTER=colorbalance=rm=-0.08:bm=0.12:rh=-0.05:bh=0.10,eq=saturation=1.06:contrast=1.06:brightness=-0.02,"
goto FILTER_DONE
:FIL_5
set "FILNAME=Black and White"
set "FILTAG=_bw"
set "COLOR_FILTER=hue=s=0,eq=contrast=1.12:brightness=0.02,"
goto FILTER_DONE
:FIL_6
set "FILNAME=Vintage / Sepia"
set "FILTAG=_vintage"
set "COLOR_FILTER=colorchannelmixer=0.393:0.769:0.189:0:0.349:0.686:0.168:0:0.272:0.534:0.131:0,eq=contrast=1.05:brightness=0.03,vignette=PI/5,"
goto FILTER_DONE
:FIL_7
set "FILNAME=Vivid (Punchy Colors)"
set "FILTAG=_vivid"
set "COLOR_FILTER=eq=saturation=1.40:contrast=1.12:brightness=0.02,unsharp=5:5:0.8:5:5:0.0,"
goto FILTER_DONE
:FIL_8
set "FILNAME=Dreamy Soft Glow"
set "FILTAG=_dreamy"
set "COLOR_FILTER=split[dg1][dg2];[dg2]gblur=sigma=18[dg3];[dg1][dg3]blend=all_mode=screen:all_opacity=0.35,eq=saturation=1.05,"
goto FILTER_DONE

:FILTER_DONE
echo.
echo ➜ Filter: !FILNAME!

REM ============================================================================
REM  STEP 5: SELECT ANIMATION
REM  Every motion below is built from sin/cos of (frame / CYCLE) using whole
REM  harmonics only, so frame 0 and frame CYCLE are pixel-identical and the
REM  segment can be looped forever with no visible jump.
REM ============================================================================
:ASKANIM
echo.
echo ========== Select Animation ==========
echo     1.  None (Static Image)
echo     2.  Breathing Zoom In ^& Out
echo     3.  Pan Left ^<-^> Right
echo     4.  Pan Up ^<-^> Down
echo     5.  Ken Burns Drift (Zoom + Pan)
echo     6.  Diagonal Drift (Corner to Corner)
echo     7.  Orbit / Circular Pan
echo     8.  Figure-8 / Infinity Drift
echo     9.  Handheld Camera Float
echo     10. Cinematic Push-In ^& Pull-Out (Vignette)
echo     11. Slow Tilt ^& Zoom (Vertical Ken Burns)
echo ==================================================
echo   All animations loop seamlessly - no visible jump.
echo ==================================================
echo.
set "ANIMCHOICE="
set /p "ANIMCHOICE=Enter Your Choice [1-11]: "
if "%ANIMCHOICE%"=="" set "ANIMCHOICE=1"
if "%ANIMCHOICE%"=="1"  goto ASKRES
if "%ANIMCHOICE%"=="2"  goto ASKRES
if "%ANIMCHOICE%"=="3"  goto ASKRES
if "%ANIMCHOICE%"=="4"  goto ASKRES
if "%ANIMCHOICE%"=="5"  goto ASKRES
if "%ANIMCHOICE%"=="6"  goto ASKRES
if "%ANIMCHOICE%"=="7"  goto ASKRES
if "%ANIMCHOICE%"=="8"  goto ASKRES
if "%ANIMCHOICE%"=="9"  goto ASKRES
if "%ANIMCHOICE%"=="10" goto ASKRES
if "%ANIMCHOICE%"=="11" goto ASKRES
echo ❌ Invalid choice^^!
goto ASKANIM

REM ============================================================================
REM  STEP 6: ASK RESOLUTION
REM  Asked last, but resolved BEFORE the animation strings are built - every
REM  zoompan expression bakes in !WIDTH!x!HEIGHT! at the moment it is assigned.
REM ============================================================================
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
    echo ❌ Invalid choice^^! & goto ASKRES
)

echo.
echo ➜ Resolution: !RESNAME! ^(!WIDTH!x!HEIGHT!^)

REM --- Oversized work canvas: gives zoom/pan room without softening the image ---
set /a WORKW = WIDTH * 3 / 2
set /a WORKH = HEIGHT * 3 / 2
set "SCALE_WORK=scale=!WORKW!:!WORKH!:force_original_aspect_ratio=decrease,pad=!WORKW!:!WORKH!:(ow-iw)/2:(oh-ih)/2"

if "%ANIMCHOICE%"=="1" goto ANIM_NONE
goto ANIM_SETUP

:ANIM_NONE
set "ANIMNAME=None (Static Image)"
set "ANIMTAG="
set "ZP="
REM A still picture only needs a few seconds of real video - the rest of the
REM timeline is that same piece stream-copied over and over.
set "SEGSECS=4"
set "SEGPRESET=veryfast"
set "SEGCRF=24"
goto ANIM_DONE

REM ---- Fixed medium animation speed: 15 second seamless loop cycle ----
:ANIM_SETUP
set "SEGSECS=15"
set /a CYCLE = SEGSECS * FPS
set "SEGPRESET=medium"
set "SEGCRF=23"

if "%ANIMCHOICE%"=="2"  goto ANIM_2
if "%ANIMCHOICE%"=="3"  goto ANIM_3
if "%ANIMCHOICE%"=="4"  goto ANIM_4
if "%ANIMCHOICE%"=="5"  goto ANIM_5
if "%ANIMCHOICE%"=="6"  goto ANIM_6
if "%ANIMCHOICE%"=="7"  goto ANIM_7
if "%ANIMCHOICE%"=="8"  goto ANIM_8
if "%ANIMCHOICE%"=="9"  goto ANIM_9
if "%ANIMCHOICE%"=="10" goto ANIM_10
if "%ANIMCHOICE%"=="11" goto ANIM_11

:ANIM_2
set "ANIMNAME=Breathing Zoom In and Out"
set "ANIMTAG=_zoom"
set "ZP=zoompan=z='1.16+0.09*sin(2*PI*on/!CYCLE!-PI/2)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_3
set "ANIMNAME=Pan Left to Right"
set "ANIMTAG=_panLR"
set "ZP=zoompan=z='1.18':x='(iw-iw/zoom)/2*(1+0.92*sin(2*PI*on/!CYCLE!))':y='(ih-ih/zoom)/2':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_4
set "ANIMNAME=Pan Up to Down"
set "ANIMTAG=_panUD"
set "ZP=zoompan=z='1.18':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2*(1+0.92*sin(2*PI*on/!CYCLE!))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_5
set "ANIMNAME=Ken Burns Drift"
set "ANIMTAG=_kenburns"
set "ZP=zoompan=z='1.14+0.07*sin(2*PI*on/!CYCLE!-PI/2)':x='(iw-iw/zoom)/2*(1+0.80*sin(2*PI*on/!CYCLE!))':y='(ih-ih/zoom)/2*(1+0.80*sin(2*PI*on/!CYCLE!-PI/2))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_6
set "ANIMNAME=Diagonal Drift"
set "ANIMTAG=_diagonal"
set "ZP=zoompan=z='1.20':x='(iw-iw/zoom)/2*(1+0.88*sin(2*PI*on/!CYCLE!))':y='(ih-ih/zoom)/2*(1+0.88*sin(2*PI*on/!CYCLE!))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_7
set "ANIMNAME=Orbit / Circular Pan"
set "ANIMTAG=_orbit"
set "ZP=zoompan=z='1.22':x='(iw-iw/zoom)/2*(1+0.85*sin(2*PI*on/!CYCLE!))':y='(ih-ih/zoom)/2*(1+0.85*cos(2*PI*on/!CYCLE!))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_8
set "ANIMNAME=Figure-8 / Infinity Drift"
set "ANIMTAG=_figure8"
set "ZP=zoompan=z='1.22':x='(iw-iw/zoom)/2*(1+0.85*sin(2*PI*on/!CYCLE!))':y='(ih-ih/zoom)/2*(1+0.85*sin(4*PI*on/!CYCLE!))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_9
set "ANIMNAME=Handheld Camera Float"
set "ANIMTAG=_handheld"
REM several whole harmonics stacked = organic drift that still closes the loop
set "ZP=zoompan=z='1.22+0.02*sin(2*PI*2*on/!CYCLE!)':x='(iw-iw/zoom)/2*(1+0.35*sin(2*PI*on/!CYCLE!)+0.12*sin(2*PI*3*on/!CYCLE!))':y='(ih-ih/zoom)/2*(1+0.30*sin(2*PI*2*on/!CYCLE!+1.1)+0.10*sin(2*PI*5*on/!CYCLE!))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE
:ANIM_10
set "ANIMNAME=Cinematic Push-In and Pull-Out"
set "ANIMTAG=_pushin"
set "ZP=zoompan=z='1.18+0.10*sin(2*PI*on/!CYCLE!-PI/2)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!,vignette=PI/4.5"
goto ANIM_DONE
:ANIM_11
set "ANIMNAME=Slow Tilt and Zoom"
set "ANIMTAG=_tilt"
set "ZP=zoompan=z='1.16+0.07*sin(2*PI*on/!CYCLE!)':x='iw/2-(iw/zoom/2)':y='(ih-ih/zoom)/2*(1+0.85*sin(2*PI*on/!CYCLE!-PI/2))':d=1:s=!WIDTH!x!HEIGHT!:fps=!FPS!"
goto ANIM_DONE

:ANIM_DONE
echo.
echo ➜ Animation: !ANIMNAME!

REM --- Assemble the filter chain used to render the master segment ---
if defined ZP (
    set "VFCHAIN=!SCALE_WORK!,!ZP!,!COLOR_FILTER!format=yuv420p"
) else (
    set "VFCHAIN=!SCALE_FILTER!,!COLOR_FILTER!format=yuv420p"
)

REM ============================================================================
REM  Audio chain. This is what fixes the silent start:
REM    silenceremove -> drops any dead air the source file begins with
REM    aresample     -> forces the first sample to land exactly on PTS 0
REM    asetpts       -> clean, monotonic, 0-based audio timeline
REM    apad          -> guarantees audio all the way to the last video frame
REM    afade         -> soft 3 second ending instead of a hard cut
REM ============================================================================
set "AFCHAIN="
set "AUDLOOP="
set "AUDINFO=None"
if not defined AUDIO goto AUDIO_CHAIN_DONE

set /a FADEST = TARGET_SECONDS - 3
if !FADEST! LSS 1 set /a FADEST = TARGET_SECONDS
set "AFCHAIN=silenceremove=start_periods=1:start_duration=0:start_threshold=-45dB:detection=peak,aresample=async=1:first_pts=0,asetpts=N/SR/TB,apad,afade=t=out:st=!FADEST!:d=3"
set "AUDINFO=leading silence trimmed + 3s fade out"
if !AUD_INT! LSS !TARGET_SECONDS! (
    set "AUDLOOP=-stream_loop -1"
    set "AUDINFO=looped, leading silence trimmed + 3s fade out"
)

:AUDIO_CHAIN_DONE

REM --- faststart rewrites the whole file at the end; skip it on huge outputs ---
set "MOVFLAGS=-movflags +faststart"
set "FSNOTE="
if !TARGET_SECONDS! GTR 14400 (
    set "MOVFLAGS="
    set "FSNOTE=faststart disabled (video is longer than 4 hours)"
)

echo.
echo ------------------------------------------
echo 📊 PROCESSING SUMMARY:
echo    Image: %IMAGE%
if not defined AUDIO (
    echo    Audio: None
) else (
    echo    Audio: !AUDIO!
    echo    Audio Length: !AUD_HMS! ^(!AUDIO_DURATION! seconds^)
    echo    Audio Handling: !AUDINFO!
)
echo    Video Duration: !DUR! ^(!TARGET_SECONDS! seconds^) - !DURMODE!
echo    Resolution: %RESNAME% ^(!WIDTH!x!HEIGHT!^)
echo    Frame Rate: !FPS! fps
echo    Filter: !FILNAME!
echo    Animation: !ANIMNAME!
if defined FSNOTE echo    Note: !FSNOTE!
echo ------------------------------------------
echo.

REM ============================================================================
REM  STEP 7: CREATE FINAL VIDEO
REM  Encoding every frame of a multi-hour timeline would take hours. Instead
REM  render ONE short seamless-loop segment, then stream-copy that segment back
REM  to back for the full duration - no re-encode, so the long video is written
REM  at disk speed. Still images go through the same path now.
REM ============================================================================
for %%Z in ("%IMAGE%") do set "IMG_NAME=%%~nZ"
set "DURSAFE=!DUR::=-!"
set "FINAL=%OUT%\!IMG_NAME!_%RESNAME%!FILTAG!!ANIMTAG!_!DURSAFE!.mp4"
set "SEGMENT=%TMPD%\segment_loop.mp4"
set /a SEGFRAMES = SEGSECS * FPS

if exist "%SEGMENT%" del /q "%SEGMENT%" >nul 2>&1

echo 🔄 Step 1/2: Rendering the !SEGSECS!-second loop segment...
echo    (this is the only part that gets encoded - please wait)
echo.

REM -frames:v pins the segment to exactly one animation cycle.
REM -bf 0 keeps every timestamp positive, so looping the segment with
REM -c:v copy produces no edit lists and no A/V offset at the start.
"%FFM%" -y -hide_banner -loglevel error -stats ^
    -loop 1 -i "%IMAGE%" ^
    -frames:v !SEGFRAMES! ^
    -vf "!VFCHAIN!" ^
    -c:v libx264 -preset !SEGPRESET! -crf !SEGCRF! ^
    -r !FPS! -g !FPS! -keyint_min !FPS! -sc_threshold 0 -bf 0 ^
    -pix_fmt yuv420p -an ^
    "%SEGMENT%"

if not exist "%SEGMENT%" (
    echo.
    echo ❌ Failed to create the loop segment^^!
    pause
    exit /b
)

REM --- Estimate final size so the user can check free disk space up front ---
for %%S in ("%SEGMENT%") do set "SEGBYTES=%%~zS"
set /a SEGKB = SEGBYTES / 1024
set /a ESTMB = (SEGKB / SEGSECS) * TARGET_SECONDS / 1024
echo.
echo ⚠  Estimated final size: ~!ESTMB! MB - make sure you have free disk space.
echo.
echo 🔄 Step 2/2: Building the !DUR! video from the loop segment...
echo.

if not defined AUDIO goto MUX_SILENT

echo Creating video with audio...
"%FFM%" -y -hide_banner -loglevel error -stats ^
    -fflags +genpts -stream_loop -1 -i "%SEGMENT%" ^
    !AUDLOOP! -i "!AUDIO!" ^
    -map 0:v:0 -map 1:a:0 ^
    -t !TARGET_SECONDS! ^
    -c:v copy ^
    -c:a aac -b:a 192k -ar 48000 -ac 2 ^
    -af "!AFCHAIN!" ^
    -avoid_negative_ts make_zero -max_interleave_delta 0 ^
    !MOVFLAGS! ^
    "%FINAL%"
goto MUX_DONE

:MUX_SILENT
echo Creating silent video...
"%FFM%" -y -hide_banner -loglevel error -stats ^
    -fflags +genpts -stream_loop -1 -i "%SEGMENT%" ^
    -t !TARGET_SECONDS! ^
    -c:v copy -an ^
    -avoid_negative_ts make_zero ^
    !MOVFLAGS! ^
    "%FINAL%"

:MUX_DONE
if exist "%SEGMENT%" del /q "%SEGMENT%" >nul 2>&1
if exist "%TMPD%\audio_dur.txt" del /q "%TMPD%\audio_dur.txt" >nul 2>&1

if not exist "%FINAL%" (
    echo.
    echo ❌ Failed to create the final video^^!
    pause
    exit /b
)

REM ---- STEP 8: VERIFY AND REPORT ----
set "REALDUR="
"%FFP%" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "%FINAL%" > "%TMPD%\final_dur.txt" 2>nul
set /p "REALDUR=" < "%TMPD%\final_dur.txt"
if exist "%TMPD%\final_dur.txt" del /q "%TMPD%\final_dur.txt" >nul 2>&1

echo.
echo ==================================================
echo ✅ SUCCESS^^! Video created successfully^^!
echo ==================================================
echo 📁 File: %FINAL%
echo 📊 Settings:
echo   - Image: %IMG_NAME%
echo   - Resolution: %RESNAME% ^(!WIDTH!x!HEIGHT!^)
echo   - Requested Duration: !DUR! ^(!TARGET_SECONDS! seconds^)
if defined REALDUR echo   - Actual Duration: !REALDUR! seconds
echo   - Animation: !ANIMNAME!
echo.
echo 📦 File size:
for %%F in ("%FINAL%") do (
    set "BYTES=%%~zF"
    if "!BYTES!"=="" set "BYTES=0"
    set /a MEGABYTES=BYTES/1048576
    if !MEGABYTES! GTR 0 (
        echo   !MEGABYTES! MB ^(!BYTES! bytes^)
    ) else (
        set /a KILOBYTES=BYTES/1024
        echo   !KILOBYTES! KB ^(!BYTES! bytes^)
    )
)
echo.
pause
exit /b

:TOOMANY
echo.
echo ❌ Too many invalid attempts - aborting.
pause
exit /b

REM ============================================================================
REM  HELPERS
REM ============================================================================

REM :TONUM "digits" -> _NUM, left empty when the text is not a plain 1-5 digit
REM number. The "1" prefix trick stops cmd from reading zero-padded values such
REM as 08 or 09 as OCTAL, which is what silently broke the old duration math.
:TONUM
set "_NUM="
set "_TN=%~1"
if not defined _TN goto :EOF
echo(!_TN!| findstr /r /c:"^[0-9][0-9]*$" >nul
if errorlevel 1 goto :EOF
if not "!_TN:~5!"=="" goto :EOF
set "_TN=00000!_TN!"
set "_TN=!_TN:~-5!"
set /a _NUM=1!_TN! - 100000
goto :EOF

REM :FMTTIME seconds -> _HMS formatted as HH:MM:SS
:FMTTIME
set "_HMS=00:00:00"
if "%~1"=="" goto :EOF
set /a _T=%~1
set /a _FH=_T/3600
set /a _FM=(_T%%3600)/60
set /a _FS=_T%%60
set "_FH=0!_FH!" & set "_FH=!_FH:~-2!"
set "_FM=0!_FM!" & set "_FM=!_FM:~-2!"
set "_FS=0!_FS!" & set "_FS=!_FS:~-2!"
set "_HMS=!_FH!:!_FM!:!_FS!"
goto :EOF

REM --- Code by Munna MasterMind ---

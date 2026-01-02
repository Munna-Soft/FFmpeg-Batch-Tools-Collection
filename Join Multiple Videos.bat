@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Merge Multiple Videos - by Munna MasterMind

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
set "FFMPEG=%FFMPEG_DIR%\ffmpeg.exe"

REM --- Folder Paths ---
set "VIDEOS_DIR=%BASE_DIR%Videos"
set "OUTPUT_DIR=%BASE_DIR%Output"

REM --- Create Videos folder if missing ---
if not exist "%VIDEOS_DIR%" (
    echo.
    echo [INFO] "Videos" folder not found. Creating This...
    mkdir "%VIDEOS_DIR%"
    echo.
    echo Please put your video files inside the "Videos" folder and run this script again.
    echo.
    pause
    exit /b
)

echo.
echo        ╔═══════════════════════════════════════════════════╗
echo        ║     Join Multiple Videos by - Munna MasterMind    ║
echo        ║       https://munna-soft.github.io/Portfolio      ║
echo        ║          https://facebook.com/The.Munna           ║
echo        ╚═══════════════════════════════════════════════════╝
echo.

REM --- List available videos files ---
set i=0
for %%E in (mp4 mkv avi mov flv wmv mpg mpeg webm) do (
    for %%f in ("%VIDEOS_DIR%\*.%%E") do (
        if exist "%%~f" (
            set /a i+=1
            set "video[!i!]=%%~nxf"
        )
    )
)

if %i%==0 (
    echo [WARN] No video files found in "%VIDEOS_DIR%".
    echo.
    echo Supported extensions: mp4 mkv avi mov flv wmv mpg mpeg webm
    echo.
    pause
    exit /b
)

echo ========== Available Videos ==========
if %i% gtr 1 echo 0 = Join ALL videos
for /l %%n in (1,1,%i%) do (
    echo %%n = !video[%%n]!
)
echo ==================================================
echo.
set /p sel="Enter the numbers of videos to merge (e.g: 1+3+5, 1 3 5, or 0 for ALL Sequential): "

REM --- If user selects 0, join all videos ---
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

set sel=%sel:+= %
echo You selected: %sel%

REM --- Ask for resolution ---
echo.
echo ========== Select Resolution ==========
echo     1 = 720p (HD)
echo     2 = 1080p (FHD)
echo     3 = 1440p (2K)
echo     4 = 2160p (4K)
echo ==================================================
echo.
set /p reschoice="Enter the resolution number (1-4): "

if "%reschoice%"=="1" set res=1280x720
if "%reschoice%"=="2" set res=1920x1080
if "%reschoice%"=="3" set res=2560x1440
if "%reschoice%"=="4" set res=3840x2160

if "%res%"=="" (
    echo Invalid resolution choice.
    pause
    exit /b
)

REM --- Output filename ---
echo.
set /p outputname="Enter output file name (without extension, default: MergedVideo): "
if "%outputname%"=="" set outputname=MergedVideo

REM --- Temp files ---
set "tempfilelist=%BASE_DIR%temp_filelist.txt"
set "tempfolder=%BASE_DIR%Temp"

if exist "%tempfolder%" rd /s /q "%tempfolder%"
mkdir "%tempfolder%"
if exist "%tempfilelist%" del "%tempfilelist%"

REM --- Convert selected videos to uniform format ---
for %%n in (%sel%) do (
    set "f=!video[%%n]!"
    if defined f (
        set "outfile=%tempfolder%\%%~nf.mp4"
        echo Converting "!f!" to %res%...
        "%FFMPEG%" -y -i "%VIDEOS_DIR%\!f!" ^
        -vf "scale=%res%,fps=24" ^
        -c:v libx264 -preset ultrafast -crf 25 ^
        -c:a aac -b:a 128k -movflags +faststart "!outfile!"
        echo file '!outfile!'>> "%tempfilelist%"
    ) else (
        echo [WARN] Video number %%n not found, skipping.
    )
)

REM --- Create Output folder ---
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo --------------------------------------------------
echo Merging videos into "%outputname%.mp4"
echo --------------------------------------------------
echo.

"%FFMPEG%" -f concat -safe 0 -i "%tempfilelist%" ^
 -c:v libx264 -preset ultrafast -crf 25 ^
 -c:a aac -b:a 128k -movflags +faststart ^
 "%OUTPUT_DIR%\%outputname%.mp4"

REM --- Cleanup ---
del "%tempfilelist%"
rd /s /q "%tempfolder%"

echo.
echo ==================================================
echo    ✅ All selected videos have been merged successfully!
echo    📁 Files saved in: "%OUTPUT_DIR%"
echo ==================================================
echo.
pause
exit /b
REM ---Code by Munna MasterMind---
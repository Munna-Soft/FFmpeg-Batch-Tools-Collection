@echo off
REM ============================================================
REM Smart Merge Multiple Video Tools (Smart Selection Edition)
REM       	Author: Munna MasterMind
REM ============================================================

setlocal enabledelayedexpansion

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

REM --- Step 2: List available videos ---
echo.
echo ========================================================================================
echo                  Merge Multiple Videos Tools - by Munna MasterMind
echo                       https://munna-soft.github.io/Portfolio
echo                          https://facebook.com/The.Munna
echo ========================================================================================
echo.
echo ========== Available Videos ==========
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
    pause
    exit /b
)

REM --- Show list ---
if %i% gtr 1 echo 0 = Join ALL videos
for /l %%n in (1,1,%i%) do (
    echo %%n = !video[%%n]!
)

echo ================================================
echo.
set /p sel="Enter the numbers of videos to merge (e.g: 1+3+5, 1 3 5, or 0 for ALL): "

REM --- Step 2c: If user selects 0, join all videos ---
if "%sel%"=="0" (
    set sel=
    for /l %%n in (1,1,%i%) do set sel=!sel! %%n
)

REM --- Normalize input (replace + with space) ---
set sel=%sel:+= %
echo You selected: %sel%

REM --- Step 3: Ask for resolution ---
echo.
echo ========== Select Resolution ==========
echo     1 = 720p (HD)
echo     2 = 1080p (FHD)
echo     3 = 1440p (2k)
echo     4 = 2160p (4k)
echo ==================================================
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

REM --- Step 4: Ask user for output filename ---
echo.
set /p outputname="Enter output file name (without extension, default: MergedVideo): "
if "%outputname%"=="" set outputname=MergedVideo

REM --- Step 5: Create temporary folder for converted videos ---
set tempfilelist=temp_filelist.txt
set tempfolder=TempConvert
if exist "%tempfolder%" rd /s /q "%tempfolder%"
mkdir "%tempfolder%"
if exist "%tempfilelist%" del "%tempfilelist%"

REM --- Step 6: Convert all selected videos to same resolution & MP4 format ---
for %%n in (%sel%) do (
    set "f=!video[%%n]!"
    if defined f (
        set "outfile=%tempfolder%\%%~nf.mp4"
        echo Converting "!f!" to uniform MP4 format and resolution %res%...
        ffmpeg -y -i "%VIDEOS_DIR%\!f!" -vf "scale=%res%,fps=24" -c:v libx264 -preset veryfast -crf 22 -c:a aac -b:a 128k -movflags +faststart "!outfile!"
        echo file '!outfile!'>> "%tempfilelist%"
    ) else (
        echo Warning: Video number %%n not found, skipping.
    )
)

REM --- Step 7: Ensure Output folder exists (on-demand) ---
if not exist "%OUTPUT_DIR%" (
    echo [INFO] Creating "Output" folder...
    mkdir "%OUTPUT_DIR%"
)

REM --- Step 8: Merge videos using ffmpeg ---
echo.
echo Merging videos into "%OUTPUT_DIR%\%outputname%.mp4" with resolution %res%...
ffmpeg -f concat -safe 0 -i "%tempfilelist%" -c:v libx264 -preset veryfast -crf 22 -c:a aac -b:a 128k -movflags +faststart "%OUTPUT_DIR%\%outputname%.mp4"

REM --- Step 9: Cleanup ---
del "%tempfilelist%"
rd /s /q "%tempfolder%"

echo.
echo ========================================================================================
echo       All selected videos have been merged successfully!
echo        Files saved in: "%OUTPUT_DIR%"
echo ========================================================================================
pause
exit /b

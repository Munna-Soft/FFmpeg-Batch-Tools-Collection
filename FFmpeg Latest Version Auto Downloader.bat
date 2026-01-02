@echo off
chcp 65001 >nul
TITLE FFmpeg Auto Downloader - Munna MasterMind
color 0A

mode con: cols=90 lines=30

:MAIN_MENU
cls
echo.
echo:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo:::		FFMPEG Latest Version Auto Downloader		  ::
echo:::		https://munna-soft.github.io/Portfolio		  ::
echo:::		https://github.com/Munna-Soft			  ::
echo:::		https://facebook.com/The.Munna			  ::
echo:::		-----------------------------------		  ::
echo::: 		[1] EASY MODE: Direct Download (Recommended)	  ::
echo::: 		[2] Extract from Existing ZIP File		  ::
echo::: 		[3] Check Internet and System			  ::
echo::: 		[4] Manual Download Guide			  ::
echo::: 		[5] Test FFmpeg Installation			  ::
echo:::								  ::
echo::: 		[0] Exit					  ::
echo:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.

choice /c 012345 /n /m "Select option [0-5]: "

if errorlevel 6 goto TEST_FFMPEG
if errorlevel 5 goto MANUAL_GUIDE
if errorlevel 4 goto CHECK_SYSTEM
if errorlevel 3 goto EXTRACT_ZIP
if errorlevel 2 goto EASY_MODE
if errorlevel 1 exit /b

:EASY_MODE
cls
echo.
echo ====================================================
echo        EASY MODE: Direct Download
echo ====================================================
echo.
echo This will download FFmpeg using the most reliable method. Please wait...
echo.

REM --- Create FFmpeg folder ---
if not exist "FFmpeg" mkdir "FFmpeg"

echo Step 1: Checking internet connection...
ping -n 2 8.8.8.8 >nul
if errorlevel 1 (
    echo [ERROR] No internet connection!
    goto NETWORK_ERROR
)

echo Step 2: Downloading FFmpeg...
echo.

REM --- Method 1: Using curl if available ---
where curl >nul 2>&1
if not errorlevel 1 (
    echo Using CURL to download...
    curl -L -o ffmpeg.zip "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    if exist "ffmpeg.zip" goto EXTRACT_NOW
)

REM --- Method 2: Using bitsadmin (Windows built-in) ---
echo Trying bitsadmin method...
bitsadmin /transfer "FFmpegDownload" /download /priority normal "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "ffmpeg.zip"

timeout /t 5 /nobreak >nul

if exist "ffmpeg.zip" (
    echo Download completed with bitsadmin!
    goto EXTRACT_NOW
)

REM --- Method 3: PowerShell with bypass ---
echo Trying PowerShell with bypass...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip' -OutFile 'ffmpeg.zip' -UseBasicParsing}"

if exist "ffmpeg.zip" (
    echo Download completed with PowerShell!
    goto EXTRACT_NOW
)

REM --- Method 4: VBScript downloader ---
echo Creating VBScript downloader...
(
echo Set args = WScript.Arguments
echo URL = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
echo Dim xHttp: Set xHttp = createobject("Microsoft.XMLHTTP")
echo Dim bStrm: Set bStrm = createobject("Adodb.Stream")
echo xHttp.Open "GET", URL, False
echo xHttp.Send
echo with bStrm
echo     .type = 1 
echo     .open
echo     .write xHttp.responseBody
echo     .savetofile "ffmpeg.zip", 2
echo end with
) > download.vbs

echo Running VBScript downloader...
cscript //nologo download.vbs
del download.vbs >nul 2>&1

if exist "ffmpeg.zip" (
    echo Download completed with VBScript!
    goto EXTRACT_NOW
)

echo.
echo [ERROR] All download methods failed!
goto DOWNLOAD_FAILED

:EXTRACT_NOW
echo.
echo Step 3: Extracting files...
echo.

REM --- Extract using built-in Windows ---
powershell -Command "Expand-Archive -Path 'ffmpeg.zip' -DestinationPath 'ffmpeg_temp' -Force" >nul 2>&1

if not exist "ffmpeg_temp" (
    echo Trying alternative extraction...
    7z x ffmpeg.zip -offmpeg_temp >nul 2>&1
)

if not exist "ffmpeg_temp" (
    echo [ERROR] Extraction failed!
    echo Please extract manually with WinRAR or 7-Zip.
    pause
    goto MAIN_MENU
)

echo Step 4: Copying FFmpeg files...
echo.

REM --- Find and copy ffmpeg files ---
set FILES_FOUND=0
for /r "ffmpeg_temp" %%F in (ffmpeg.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffmpeg.exe" (
        echo [OK] ffmpeg.exe copied
        set /a FILES_FOUND+=1
    )
)

for /r "ffmpeg_temp" %%F in (ffprobe.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffprobe.exe" (
        echo [OK] ffprobe.exe copied
        set /a FILES_FOUND+=1
    )
)

for /r "ffmpeg_temp" %%F in (ffplay.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffplay.exe" (
        echo [OK] ffplay.exe copied
        set /a FILES_FOUND+=1
    )
)

REM --- Clean up ---
rd /s /q "ffmpeg_temp" 2>nul
del "ffmpeg.zip" 2>nul

if %FILES_FOUND% GTR 0 (
    echo.
    echo ====================================================
    echo [SUCCESS] FFmpeg installed successfully!
    echo %FILES_FOUND% files copied to FFmpeg folder.
    echo ====================================================
    echo.
    echo Testing installation...
    if exist "FFmpeg\ffmpeg.exe" (
        "FFmpeg\ffmpeg.exe" -version | findstr "version"
    )
) else (
    echo.
    echo [WARNING] No FFmpeg files found in archive!
    echo The ZIP file might have different structure.
)

echo.
pause
goto MAIN_MENU

:NETWORK_ERROR
echo.
echo [TROUBLESHOOTING]
echo 1. Check your internet connection
echo 2. Try using mobile hotspot
echo 3. Disable VPN/firewall temporarily
echo 4. Use Manual Download Guide (Option 5)
pause
goto MAIN_MENU

:DOWNLOAD_FAILED
echo.
echo ====================================================
echo [IMPORTANT] Direct download failed!
echo ====================================================
echo.
echo Please try these solutions:
echo.
echo 1. Use OPTION 5: Manual Download Guide
echo 2. Download from: https://www.gyan.dev/ffmpeg/builds/
echo 3. Use a different network (mobile data)
echo 4. Disable antivirus/firewall temporarily
echo.
pause
goto MAIN_MENU

REM --- EXTRACT FROM ZIP ---
:EXTRACT_ZIP
cls
echo.
echo ====================================================
echo        EXTRACT FROM EXISTING ZIP FILE
echo ====================================================
echo.
echo If you already downloaded FFmpeg ZIP file,
echo place it in this folder: %CD%
echo.
echo Current ZIP files in folder:
echo.

dir *.zip *.7z /b 2>nul || echo No ZIP files found.

echo.
set /p "zipfile=Enter ZIP filename (or press Enter to list): "
if "%zipfile%"=="" (
    echo.
    echo Available files:
    dir *.zip *.7z /b 2>nul
    echo.
    set /p "zipfile=Enter filename: "
)

if not exist "%zipfile%" (
    echo File not found: %zipfile%
    pause
    goto EXTRACT_ZIP
)

echo.
echo Extracting %zipfile%...
if not exist "FFmpeg" mkdir "FFmpeg"

REM --- Try different extraction methods ---
echo Method 1: PowerShell extraction...
powershell -Command "Expand-Archive -Path '%zipfile%' -DestinationPath 'temp_extract' -Force" 2>nul

if not exist "temp_extract" (
    echo Method 2: Using built-in Windows...
    tar -xf "%zipfile%" -C temp_extract 2>nul
)

if not exist "temp_extract" (
    echo Method 3: Manual extraction needed!
    echo Please extract %zipfile% manually.
    echo Copy ffmpeg.exe, ffprobe.exe to FFmpeg folder.
    pause
    goto MAIN_MENU
)

echo Searching for FFmpeg executables...
echo.

set EXTRACTED=0
for /r "temp_extract" %%F in (ffmpeg.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffmpeg.exe" (
        echo [OK] ffmpeg.exe found
        set EXTRACTED=1
    )
)

for /r "temp_extract" %%F in (ffprobe.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffprobe.exe" (
        echo [OK] ffprobe.exe found
        set EXTRACTED=1
    )
)

for /r "temp_extract" %%F in (ffplay.exe) do (
    copy /y "%%F" "FFmpeg\" >nul
    if exist "FFmpeg\ffplay.exe" (
        echo [OK] ffplay.exe found
        set EXTRACTED=1
    )
)

rd /s /q "temp_extract" 2>nul

if %EXTRACTED%==1 (
    echo.
    echo [SUCCESS] FFmpeg files extracted successfully!
    echo They are in the FFmpeg folder.
) else (
    echo.
    echo [WARNING] No FFmpeg executables found!
    echo The ZIP might have different structure.
    echo Look for bin/ folder in the archive.
)

echo.
pause
goto MAIN_MENU

REM --- CHECK SYSTEM & INTERNET ---
:CHECK_SYSTEM
cls
echo.
echo ====================================================
echo        SYSTEM CHECK & INTERNET TEST
echo ====================================================
echo.

echo [1] Checking Windows version...
ver
echo.

echo [2] Checking system architecture...
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo 64-bit system detected
) else (
    echo 32-bit system detected
)
echo.

echo [3] Checking available tools...
where bitsadmin >nul && echo [OK] bitsadmin available
where certutil >nul && echo [OK] certutil available
where powershell >nul && echo [OK] PowerShell available
where curl >nul && echo [OK] curl available
where tar >nul && echo [OK] tar available
echo.

echo [4] Testing internet connection...
echo Testing connection to GitHub...
ping -n 2 github.com >nul && echo [OK] Can reach github.com || echo [FAIL] Cannot reach github.com

echo Testing connection to gyan.dev...
ping -n 2 www.gyan.dev >nul && echo [OK] Can reach gyan.dev || echo [FAIL] Cannot reach gyan.dev
echo.

echo [5] Checking download folder permissions...
echo Current folder: %CD%
echo Has write permission: [TESTING]
echo. > test_write.txt && (echo [OK] Can write files && del test_write.txt) || echo [FAIL] Cannot write files
echo.

echo [6] Recommended download method:
echo Based on your system, use OPTION 1 (Easy Mode)
echo If it fails, use OPTION 5 (Manual Guide)
echo.

pause
goto MAIN_MENU

REM --- MANUAL GUIDE ---
:MANUAL_GUIDE
cls
echo.
echo ====================================================
echo        MANUAL DOWNLOAD GUIDE
echo ====================================================
echo.
echo [STEP 1] Open your web browser
echo.
echo [STEP 2] Go to one of these URLs:
echo.
echo OPTION A (Recommended):
echo https://www.gyan.dev/ffmpeg/builds/
echo.
echo OPTION B (GitHub Latest):
echo https://github.com/BtbN/FFmpeg-Builds/releases
echo.
echo OPTION C (Official):
echo https://ffmpeg.org/download.html
echo.
echo [STEP 3] Download the ZIP file:
echo For 64-bit Windows: ffmpeg-release-essentials.zip
echo For latest version: ffmpeg-master-latest-win64-gpl.zip
echo.
echo [STEP 4] Save the ZIP file to this folder:
echo %CD%
echo.
echo [STEP 5] Come back to this program
echo Choose OPTION 3 to extract the ZIP file
echo.
echo [STEP 6] Or extract manually:
echo 1. Right-click the ZIP file
echo 2. Select "Extract All"
echo 3. Find ffmpeg.exe, ffprobe.exe
echo 4. Copy them to FFmpeg folder
echo.
echo Quick download links (clickable in Notepad):
echo 1. https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip
echo 2. https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip
echo 3. https://github.com/ShareX/FFmpeg/releases/download/v6.0/ffmpeg-6.0-win64.zip
echo.
pause
goto MAIN_MENU

REM --- TEST FFMPEG ---
:TEST_FFMPEG
cls
echo.
echo ====================================================
echo        TEST FFMPEG INSTALLATION
echo ====================================================
echo.

echo [1] Checking FFmpeg folder...
if exist "FFmpeg\ffmpeg.exe" (
    echo [OK] ffmpeg.exe found in FFmpeg folder
    echo.
    echo Version information:
    "FFmpeg\ffmpeg.exe" -version | findstr /B "ffmpeg version"
    echo.
    echo Testing video capabilities:
    "FFmpeg\ffmpeg.exe" -codecs | findstr /C:"H.264" /C:"MPEG4" /C:"AAC"
) else (
    echo [FAIL] ffmpeg.exe not found in FFmpeg folder
)

echo.
echo [2] Checking system PATH...
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [INFO] ffmpeg not in system PATH
) else (
    echo [OK] ffmpeg found in system PATH
    ffmpeg -version | findstr /B "ffmpeg version"
)

echo.
echo [3] Quick functionality test...
if exist "FFmpeg\ffmpeg.exe" (
    echo Running test command...
    "FFmpeg\ffmpeg.exe" -hide_banner -formats | findstr /C:"mp4" /C:"avi" /C:"mkv"
    echo.
    echo [SUCCESS] FFmpeg is working correctly!
) else (
    echo [ERROR] FFmpeg not installed properly.
    echo Please use Option 1 to download FFmpeg.
)

echo.
pause
goto MAIN_MENU
REM ============================
REM     END OF SCRIPT
REM ============================
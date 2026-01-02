@echo off
chcp 65001 >nul
title FFMPEG Batch Toolkit Multi Edition - by Munna MasterMind
setlocal enabledelayedexpansion

:MAIN_MENU
cls
echo.
echo 	╔═══════════════════════════════════════════════════╗
echo 	║     FFMPEG Batch Toolkit Multi Edition 2026       ║
echo 	╠═══════════════════════════════════════════════════╣
echo 	║   1.  Download and Setup FFMPEG Dependency        ║
echo 	║   2.  Video Format Converter                      ║
echo 	║   3.  Video To Audio Converter                    ║
echo 	║   4.  Remove Audio from Videos                    ║
echo 	║   5.  Add Music to Silent Videos                  ║
echo 	║   6.  Replace Audio Track in Videos               ║
echo 	║   7.  Join Multiple Audios                        ║
echo 	║   8.  Join Multiple Videos                        ║
echo 	║   9.  Audio Sequence Cutter                       ║
echo 	║  10.  Video Sequence Cutter                       ║
echo 	║  11.  Frame by Frame Image Extractor              ║
echo 	║  12.  Create Short Videos From Images             ║
echo 	║  13.  Create Long Videos From Images              ║
echo 	║  14.  Create Long Videos with Loop                ║
echo 	║  15.  Create Long Videos with SlowMotion          ║
echo 	║  16.  Add Watermark to Videos                     ║
echo 	║  17.  Remove Noise from Audios                    ║
echo 	║  18.  Remove Noise from Videos                    ║
echo 	║   0.  Contact with Me	For Any Issue               ║
echo 	║  00.  Exit Program                                ║
echo 	╚═══════════════════════════════════════════════════╝
echo.

set "opt="
set /p opt=Select option [0-18,00]: 

:: Validation
if "%opt%"=="1"  goto DOWNLOAD_FFMPEG
if "%opt%"=="2"  goto VIDEO_FORMAT_CONVERTER
if "%opt%"=="3"  goto VIDEO_TO_AUDIO_CONVERTER
if "%opt%"=="4"  goto REMOVE_AUDIO_FROM_VIDEOS
if "%opt%"=="5"  goto ADD_MUSIC_TO_SILENT_VIDEOS
if "%opt%"=="6"  goto REPLACE_AUDIO_TRACK_IN_VIDEOS
if "%opt%"=="7"  goto JOIN_MULTIPLE_AUDIOS
if "%opt%"=="8"  goto JOIN_MULTIPLE_VIDEOS
if "%opt%"=="9"  goto AUDIO_SEQUENCE_CUTTER
if "%opt%"=="10" goto VIDEO_SEQUENCE_CUTTER
if "%opt%"=="11" goto FRAME_FRAME_IMAGE_EXTRACTOR
if "%opt%"=="12" goto CREATE_SHORT_VIDEOS_FROM_IMAGES
if "%opt%"=="13" goto CREATE_LONG_VIDEOS_FROM_IMAGES
if "%opt%"=="14" goto CREATE_LONG_VIDEOS_WITH_LOOP
if "%opt%"=="15" goto CREATE_LONG_VIDEOS_WITH_SLOWMOTION
if "%opt%"=="16" goto ADD_WATERMARK_TO_VIDEOS
if "%opt%"=="17" goto REMOVE_NOISE_FROM_AUDIO
if "%opt%"=="18" goto REMOVE_NOISE_FROM_VIDEOS
if "%opt%"=="0"  goto CONTACT
if "%opt%"=="00" exit /b

:: Wrong input
powershell -c "[console]::beep(1000,200)"
echo Invalid option!
timeout /t 1 >nul
goto MENU

:DOWNLOAD_FFMPEG
cls
call "%~dp0\FFmpeg Latest Version Auto Downloader.bat"
goto MAIN_MENU

:VIDEO_FORMAT_CONVERTER
cls
call "%~dp0\Video Format Converter.bat"
goto MAIN_MENU

:VIDEO_TO_AUDIO_CONVERTER
cls
call "%~dp0\Video to Audio Converter.bat"
goto MAIN_MENU

:REMOVE_AUDIO_FROM_VIDEOS
cls
call "%~dp0\Remove Audio from Videos.bat"
goto MAIN_MENU

:ADD_MUSIC_TO_SILENT_VIDEOS
cls
call "%~dp0\Add Music to Silent Videos.bat"
goto MAIN_MENU

:REPLACE_AUDIO_TRACK_IN_VIDEOS
cls
call "%~dp0\Replace Audio Track in Videos.bat"
goto MAIN_MENU

:JOIN_MULTIPLE_AUDIOS
cls
call "%~dp0\Join Multiple Audios.bat"
goto MAIN_MENU

:JOIN_MULTIPLE_VIDEOS
cls
call "%~dp0\Join Multiple Videos.bat"
goto MAIN_MENU

:AUDIO_SEQUENCE_CUTTER
cls
call "%~dp0\Audio Sequence Cutter.bat"
goto MAIN_MENU

:VIDEO_SEQUENCE_CUTTER
cls
call "%~dp0\Video Sequence Cutter.bat"
goto MAIN_MENU

:FRAME_FRAME_IMAGE_EXTRACTOR
cls
call "%~dp0\Frame by Frame Image Extractor.bat"
goto MAIN_MENU

:CREATE_SHORT_VIDEOS_FROM_IMAGES
cls
call "%~dp0\Create Short Videos From Images.bat"
goto MAIN_MENU

:CREATE_LONG_VIDEOS_FROM_IMAGES
cls
call "%~dp0\Create Long Videos From Images.bat"
goto MAIN_MENU

:CREATE_LONG_VIDEOS_WITH_LOOP
cls
call "%~dp0\Create Long Videos with Loop.bat"
goto MAIN_MENU

:CREATE_LONG_VIDEOS_WITH_SLOWMOTION
cls
call "%~dp0\Create Long Videos with SlowMotion.bat"
goto MAIN_MENU

:ADD_WATERMARK_TO_VIDEOS
cls
call "%~dp0\Add Watermark to Videos.bat"
goto MAIN_MENU

:REMOVE_NOISE_FROM_AUDIO
cls
call "%~dp0\Remove Noise from Audios.bat"
goto MAIN_MENU

:REMOVE_NOISE_FROM_VIDEOS
cls
call "%~dp0\Remove Noise from Videos.bat"
goto MAIN_MENU

:CONTACT
cls
color 0A
echo.
echo:	::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo:	::		FFMPEG Batch Toolkit Multi Edition		  ::
echo:	::		Author : Munna MasterMind			  ::
echo:	::		https://github.com/Munna-Soft			  ::
echo:	::		https://facebook.com/The.Munna			  ::
echo:	::		Location : Dhaka, Bangladesh			  ::
echo:	::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.

pause
goto MAIN_MENU

:: ===== Code By Munna MasterMind =====
:: ===== END OF SCRIPT =====
SETLOCAL enabledelayedexpansion
@ECHO off
MODE con lines=20 cols=56
COLOR 0A
CD /D %~dp0
TITLE Chrome Portable
:HEAD
ECHO  ======================================================
ECHO  1. Get / Update Chrome
ECHO  2. Get / Update Chrome++
ECHO  ======================================================
:: Use xcopy to retrieve the key press: https://stackoverflow.com/a/27257111/14168341
<NUL SET /p ".=Press 1-8 to choice, any other key to exit:"
SET "choix=" & for /f "delims=" %%a in ('xcopy /l /w "%~f0" "%~f0" 2^>nul') DO IF not defined choix set "choix=%%a"
SET "choix=%choix:~-1%"
FOR %%i in ( 1 2 ) DO IF %choix%==%%i ECHO %choix% && TIMEOUT /NOBREAK /T 1 >NUL
CLS
ECHO.
IF /i "%choix%"=="1" GOTO CHROME	
IF /i "%choix%"=="2" GOTO CHROMEPLUS
EXIT

:CHROME
CD "%~DP0Utils\"
curl -Lo install.7z https://github.com/coo11/chrofox/releases/download/stable_latest/Chrome_Portable.7z
IF EXIST "..\App\chrome++.ini" (
    CHOICE /c YN /m "Backup chrome++.ini?"
    IF !ERRORLEVEL! EQU 1 (
        MOVE /Y ..\App\chrome++.ini .\chrome++.ini
    )
)
RD ..\App /S /Q >NUL 2>&1 & 7za x install.7z -aoa -o..\
MOVE /Y chrome++.ini  ..\App\chrome++.ini
DEL install.7z /F /Q >NUL 2>&1
PAUSE
GOTO BACK

:CHROMEPLUS
CD "%~DP0Utils\"
curl -Locp.zip https://github.com/coo11/chrofox/releases/download/stable_latest/Chrome_Plus.zip && 7za x cp.zip -aoa && MD ..\App >NUL 2>&1 & MOVE /Y version.dll ..\App\version.dll
MOVE chrome++.ini ..\App\chrome++.ini
DEL cp.zip chrome++.ini /F /Q >NUL 2>&1
PAUSE
GOTO BACK

:BACK
TIMEOUT /T 2 >NUL
CD /D %~dp0
CLS
GOTO HEAD
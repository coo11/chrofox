@ECHO OFF & TITLE Chromium Search Engines ^& Bookmarks Helper v0.4 & SETLOCAL EnableDelayedExpansion
MODE CON lines=14 cols=56 & COLOR 0A
GOTO PREPARE
======================================================================
   Chromium Search Engines & Bookmarks Helper v0.4
   
   A semi-automatic bookmarks & search engines management script
   
   Reference:
       https://github.com/ludovicchabant/Chrome-Search-Engine-Sync
       https://superuser.com/questions/280694/
   
   Others:
       https://github.com/AveYo/Compressed2TXT
       https://stackoverflow.com/a/38371342/14168341

   Files packaged by Compressed2TXT:
       1. sqlite3.exe version: 3.7.11 (First version has '-cmd')
       2. keywords.sql
       3. default.sql
       4. Bookmarks (JSON)

   Build-In browser data starts from line 2346.
   You can use Compressed2TXT (CONFIG: BASE91 + No Long Lines) to package bookmarks and search engines data to a single file.

======================================================================
:PREPARE
:: For dragging File to this batch
SET "CFILE=%~f0"
SET "CPATH=%~dp0" && REM CALL :Unpack "X 1; X 2; X 3; X 4" && GOTO :EOF
SET "TFILE=%~f1"
SET "TPATH="
SET "DEFAULTDIR=%LOCALAPPDATA%\Google\Chrome\User Data\Default"
IF NOT EXIST "%DEFAULTDIR%" SET "DEFAULTDIR=%CPATH%"

IF NOT DEFINED TFILE GOTO HEAD

FOR /F "delims=" %%I IN ("%TFILE%") DO SET "ATTR=%%~aI"
IF NOT DEFINED ATTR ECHO Please deliver correct parameter later. & SET "TFILE=" && TIMEOUT /NOBREAK /T 2 >NUL && GOTO HEAD

IF %ATTR:~0,1%==d IF "%TFILE:~-7%"=="Default" IF EXIST "%TFILE%Web Data" ECHO Profiles directory found. & SET "TPATH=%TFILE%" & SET "TFILE=%TPATH%Web Data" && TIMEOUT /NOBREAK /T 2 >NUL && GOTO HEAD

IF NOT %ATTR:~0,1%==d IF "%TFILE:~-8%"=="Web Data" ECHO Web Data found. & SET "TPATH=%~dp1" && TIMEOUT /NOBREAK /T 2 >NUL && GOTO HEAD

IF NOT %ATTR:~0,1%==d IF "%TFILE:~-9%"=="Bookmarks" ECHO Bookmarks found. & SET "TPATH=%~dp1" & SET "TFILE=%TPATH%Web Data" && TIMEOUT /NOBREAK /T 2 >NUL && GOTO HEAD

ECHO Profiles (directory) not found. & SET "TFILE=" && TIMEOUT /NOBREAK /T 2 >NUL

:HEAD
CLS
ECHO.
ECHO                     Chromium Browser
ECHO           Search Engines ^& Bookmarks Helper
ECHO  ======================================================
ECHO                1. Export Search Engines
ECHO                2. Export Bookmarks
ECHO                3. Export All
ECHO                4. Import Search Engines
ECHO                5. Import Bookmarks
ECHO                6. Import All
ECHO                7. Reset Search Engines To Default
ECHO  ======================================================
:: Use xcopy to retrieve the key press: https://stackoverflow.com/a/27257111/14168341
<NUL SET /P ".=>      Press 1-7 to select or other keys to exit:"
SET "CH=" & FOR /F "delims=" %%a IN ('XCOPY /l /w "%~f0" "%~f0" 2^>NUL') DO IF NOT DEFINED CH SET "CH=%%a"
SET "CH=%CH:~-1%"
FOR %%i IN ( 1 2 3 4 5 6 7 ) DO IF "%CH%"=="%%i" ECHO %CH%
CLS
IF /I "%CH%"=="1" CALL :GetTarget "ExportSP" "Web Data" & CALL :BACK & PAUSE && GOTO HEAD
IF /I "%CH%"=="2" CALL :GetTarget "ExportB" "Bookmarks" & CALL :BACK && GOTO HEAD
IF /I "%CH%"=="3" CALL :GetTarget "ExportSP" "Web Data" & ECHO. & CALL :ExportB & CALL :BACK && GOTO HEAD
IF /I "%CH%"=="4" CALL :GetTarget "ImportSP" "Web Data" %CH% & CALL :BACK & PAUSE && GOTO HEAD
IF /I "%CH%"=="5" CALL :GetTarget "ImportB" "Bookmarks" & CALL :BACK & PAUSE && GOTO HEAD
IF /I "%CH%"=="6" CALL :GetTarget "ImportSP" "Web Data" %CH% & PAUSE & CLS & CALL :ImportB & CALL :BACK & PAUSE && GOTO HEAD
IF /I "%CH%"=="7" CALL :GetTarget "ImportSP" "Web Data" %CH% & CALL :BACK & PAUSE && GOTO HEAD
GOTO :EOF

:ExportSP
ECHO Exporting search engines... The target file path is
ECHO %TFILE%
CALL :Unpack "X 1"

SET "TEMP_WEB_DATA=%TEMP%\temp_web_data"
COPY "%TFILE%" "%TEMP_WEB_DATA%" /Y >NUL
sqlite3.exe -cmd ".output "%CPATH:\=/%keywords.sql"" -cmd ".dump keywords" "%TEMP_WEB_DATA:\=/%" .exit
DEL /F /Q %TEMP_WEB_DATA%
DEL /F /Q sqlite3.exe
ECHO The search engines data has been saved as "keywords.sql" in this scirpt directory.
EXIT/B 0

:ExportB
SET "BPATH=%TPATH%Bookmarks"
IF NOT EXIST "%BPATH%" ECHO "Bookmarks" not found. && PAUSE && SET "BPATH=" && EXIT/B
ECHO Exporting bookmarks... The target file path is
ECHO %BPATH%
COPY "%BPATH%" "Bookmarks" /Y >NUL
ECHO The Bookmarks data has been saved as "Bookmarks" in the this scirpt directory.
SET "BPATH="
PAUSE
EXIT/B

:ImportSP
CLS
TASKLIST /FI "IMAGENAME eq chrome.exe" 2>NUL | FIND /I /N "chrome.exe">NUL
IF "%ERRORLEVEL%"=="0" (
    ECHO WARNING: The Chromium browser is running.
    ECHO Please confirm that the running browser is not related to provided Web Data in case of importing failure.
    ECHO.
    PAUSE
)
CLS
CALL :Confirm "search engines"

IF NOT DEFINED TFILE GOTO :EOF

IF "%~3"=="7" (
    CALL :Unpack "X 1; X 3"
    SET "DPATH=%CPATH:\=/%default.sql"
) ELSE (
    IF EXIST "%CPATH%keywords.sql" (
        SET FOUND=Yes
        ECHO Found keywords.sql in the same directory, skip the built-in data.
        CALL :Unpack "X 1"
    ) ELSE (
        ECHO Use built-in search engines data.
        CALL :Unpack "X 1; X 2"
    )
    SET "DPATH=%CPATH:\=/%keywords.sql"
)

SET "STD=%TEMP%\temp_sql_std"
COPY "%TFILE%" "%TFILE%.bak" /Y >NUL
sqlite3.exe -cmd "DROP TABLE IF EXISTS keywords;" -cmd ".read '%DPATH%'" "%TFILE:\=/%" .exit 1>"%STD%" 2>&1
FIND /I "database is locked" "%STD%" >NUL
IF "%ERRORLEVEL%"=="0" (
    powershell -nop -c write-host -fore White -back Red "Import ERROR: Web Data is in use."
    DEL /F /Q "%TFILE%.bak"
)
IF "%ERRORLEVEL%"=="1" (
    sqlite3.exe -cmd "SELECT * FROM meta WHERE key='version'" "%TFILE:\=/%" .exit 1>"%STD%" 2>&1
    :: version type: LONGVARCHAR
    FOR /F "tokens=1,* delims=^|" %%a in ('findstr "version" "%STD%"') DO SET WDVER=%%b
    sqlite3.exe -cmd "SELECT * FROM pragma_table_info('keywords') WHERE name='is_active' OR name='starter_pack_id' OR name='enforced_by_policy' OR name='featured_by_policy'" "%TFILE:\=/%" .exit 1>"%STD%" 2>&1
    :: Web Data version below 97 will lack of column "is_active".
    IF !WDVER! GEQ 97 (
        >NUL FIND /I "is_active" "%STD%" || sqlite3.exe -cmd "ALTER TABLE keywords ADD COLUMN is_active INTEGER DEFAULT 0; UPDATE keywords SET is_active=1" "%TFILE:\=/%" .exit 1>NUL 2>&1
    )
    REM !! https://chromium.googlesource.com/chromium/src.git/+/cf20219e455fcf309edcb62d42b804515443e340%5E%21/#F3
    :: Web Data version below 103 will lack of column "starter_pack_id".
    IF !WDVER! GEQ 103 (
        >NUL FIND /I "starter_pack_id" "%STD%" || sqlite3.exe -cmd "ALTER TABLE keywords ADD COLUMN starter_pack_id INTEGER DEFAULT 0" "%TFILE:\=/%" .exit 1>NUL 2>&1
    )
    REM !! https://chromium.googlesource.com/chromium/src.git/+/refs/tags/114.0.5734.1/components/search_engines/keyword_table.h#75
    :: Web Data version below 112 will lack of column "enforced_by_policy".
    IF !WDVER! GEQ 112 (
        >NUL FIND /I "enforced_by_policy" "%STD%" || sqlite3.exe -cmd "ALTER TABLE keywords ADD COLUMN enforced_by_policy INTEGER DEFAULT 0" "%TFILE:\=/%" .exit 1>NUL 2>&1
    )
    REM !! https://chromium.googlesource.com/chromium/src.git/+/refs/tags/122.0.6224.0/components/search_engines/keyword_table.h#77
    :: Web Data version below 122 will lack of column "featured_by_policy".
    IF !WDVER! GEQ 122 (
        >NUL FIND /I "featured_by_policy" "%STD%" || sqlite3.exe -cmd "ALTER TABLE keywords ADD COLUMN featured_by_policy INTEGER DEFAULT 0" "%TFILE:\=/%" .exit 1>NUL 2>&1
    )
    REM !! https://chromium.googlesource.com/chromium/src.git/+/refs/tags/137.0.7151.138/components/search_engines/keyword_table.h#86
    :: Web Data version below 137 will lack of column "url_hash".
    IF !WDVER! GEQ 137 (
        >NUL FIND /I "featured_by_policy" "%STD%" || sqlite3.exe -cmd "ALTER TABLE keywords ADD COLUMN url_hash BLOB" "%TFILE:\=/%" .exit 1>NUL 2>&1
    )
    
    IF "%~3"=="7" (
        ECHO Search engines reset. 
    ) ELSE (
        ECHO Import search engines finished. 
    )
    ECHO Please open chrome://settings/searchEngines in your browser and check.
)
DEL /F /Q %STD%
DEL /F /Q sqlite3.exe
IF NOT DEFINED FOUND IF /I "%~3" LSS "7" DEL /F /Q keywords.sql 2>NUL
DEL /F /Q default.sql 2>NUL
SET "FOUND="
EXIT/B

:ImportB
CALL :Confirm "bookmarks"

IF NOT DEFINED TFILE GOTO :EOF

IF EXIST "%CPATH%Bookmarks" (
    SET FOUND=Yes
    ECHO Found Bookmarks in the same directory, skip the built-in data.
) ELSE (
    ECHO Use built-in Bookmarks data.
    CALL :Unpack "X 4"
)

SET "BPATH=%TPATH%Bookmarks"
COPY "%BPATH%" "%BPATH%.bak" /Y >NUL 2>&1
COPY "%CPATH%Bookmarks" "%BPATH%" /Y >NUL
ECHO Import bookmarks finished. Please reboot your chromium browser to check.
IF NOT DEFINED FOUND DEL /F /Q Bookmarks 2>NUL
SET "BPATH="
SET "FOUND="
EXIT/B

:GetTarget
:: Arguments: %~1: Tag name; %~2: "Web Data" or "Bookmarks" %~3: Selected Item
IF NOT DEFINED TFILE CALL :FileSeleciton "%~2"
IF NOT DEFINED TFILE GOTO HEAD
GOTO %~1

:FileSeleciton
:: Argument: %~1: Variable "TFILE"
ECHO Please select %~1.... & TIMEOUT /NOBREAK /T 1 >NUL
IF "%~1"=="Bookmarks" ECHO If file "Bookmarks" not found, you can tell me where is file "Web Data".
ECHO.
SET "FILETER=Data Base^|Web Data"
IF "%~1"=="Bookmarks" SET "FILETER=JSON^|Bookmarks^|Data Base^|Web Data"
SET "DIALOG=powershell -nop -sta "Add-Type -AssemblyName System.windows.forms^|Out-Null;$f=New-Object System.Windows.Forms.OpenFileDialog;$f.InitialDirectory='%DEFAULTDIR%';$f.title='Select %~1';$f.showHelp=$false;$f.Filter='%FILETER%';$f.Multiselect=$false;$f.ShowDialog()^|Out-Null;$f.FileName;""
MODE CON cols=150 && REM Important: Small buffer size might cause wrong FOR /F output
FOR /F "delims=" %%I IN ('%DIALOG%') DO SET "RES=%%~dpI"
MODE CON cols=56
IF DEFINED RES IF NOT "%RES%"==" " SET "TPATH=%RES%" & SET "TFILE=%RES%Web Data"
EXIT/B 0

:Back
SET "TFILE="
SET "TPATH="
EXIT/B

:Confirm
:: Argument: %~1: "search engines" or "bookmarks"
powershell -nop -c write-host -fore Black -back Cyan "WARNING: This operation may overwrite your %~1 data! "
IF "%~1"=="bookmarks" ECHO If you didn't find file "Bookmarks", press 1 is OK.
<NUL SET /P ".=To confirm, press 1 to continue:"
SET "CH=" & FOR /F "delims=" %%a IN ('XCOPY /l /w "%~f0" "%~f0" 2^>NUL') DO IF NOT DEFINED CH SET "CH=%%a"
SET "CH=%CH:~-1%"
FOR %%i IN ( 1 ) DO IF "%CH%"=="%%i" ECHO %CH%
CLS
IF /I NOT "%CH%"=="1" SET "FOUND=" & CALL :BACK & GOTO HEAD

:Unpack
>NUL POWERSHELL -nop -c $f=[IO.File]::ReadAllText($env:CFILE)-split':Files\:.*';iex($f[1]); %~1
EXIT/B

:Files: Compressed2TXT v6.5
$k='.,;{-}[+](/)_|^=?O123456789ABCDeFGHyIdJKLMoN0PQRSTYUWXVZabcfghijklmnpqrstuvwxz!@#$&~E<*`%\>'; Add-Type -Ty @'
using System.IO;public class BAT91{public static void Dec(ref string[] f,int x,string fo,string key){unchecked{int n=0,c=255,q=0
,v=91,z=f[x].Length; byte[]b91=new byte[256]; while(c>0) b91[c--]=91; while(c<91) b91[key[c]]=(byte)c++; using (FileStream o=new
FileStream(fo,FileMode.Create)){for(int i=0;i!=z;i++){c=b91[f[x][i]]; if(c==91)continue; if(v==91){v=c;}else{v+=c*91;q|=v<<n;if(
(v&8191)>88){n+=13;}else{n+=14;}v=91;do{o.WriteByte((byte)q);q>>=8;n-=8;}while(n>7);}}if(v!=91)o.WriteByte((byte)(q|v<<n));} }}}
'@; cd -Lit($env:__CD__); function X([int]$x=1){[BAT91]::Dec([ref]$f,$x+1,$x,$k); expand -R $x -F:* .; del $x -force}

:Files:[ sqlite3_exe
:: Removed

:Files:[ keywords_sql
:: Removed

:Files:[ default_sql
:: Removed

:Files:[ Bookmarks Fake
:: Removed

:Files:]

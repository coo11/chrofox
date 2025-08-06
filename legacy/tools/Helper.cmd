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
:: Binary sqlite3.exe converted by Compressed2TXT 

:Files:[ keywords_sql
::AVEYO...7am}......*D........j}?.k...Rnn,..2{..d,qGy+CX,.......RnPjf4m}0gk=,o!UexgF^][26)6zFI%0om_kv;$qR5h$}.b}7RH1..jsTGj=v!Sa}Q(K
::~z80yMD6Us?=+=.4<B?b{tTzqtv*zyBqNUbJoU/>A6>%vYY[a-((nC\f}MF8$)Lkhp=oz^t?;P-IQ5.(,PM-ri^~1,b74uNVtGL!J,i!R80QpK!L8dEb*~`;Hdm~@/wYlb
::Y0LjY)2H[n8?ClO0F{d-P9e?7Y*uS1`q`?geAZ2qu^/b*,Sajh`\M=a}3-..taM]{Y)PZ02*dBW/|BE[aFjltBj?~/r4(v_\9UFn.maRdtF+0PnaygB]4XC2Vmd~=z2\{X
::to4Xp4)?7M}l|wa=FI[w9(L(Sw[]wTzj_=H2+3/lre?j1=lwXXbW&jsThd#+J%9WeXFIN?/2u5qRm=[[hd\aOEEx7N<J-KFNREpJcxk%Bw;aEQjrwi0#d`z0j0q3VqlnOG
::7]r7|4$}?hY66|5IPhMJ$n\!nH#1yt4e}Z=)j=iw>0$iepY?tUh^.?]EW{.j={G{BF*_(e~8~s#mOq?xwigO1^J#C}o6,N{c#\~mc!0!afCQkrz&1jAW@XDQI).;XF!#3v
::7NyoK+c4?w7yM?KtK*M3rL_L*.`jk-(bg+P%_WqH%.YE77+j3e]DV^uUb[R@.`QrZWZR21;s{Q4KPtChd.=mx`s*IBzXkWI2AYzD\Kdp_VztLA.cJ&>u?$QekeW_.<GIZg
::d8iOHYk!2ERR|FAkDHj%A9LlLxQo,V>KfWQXN*=04XeBf`Ni?E{!58XXlxtlh+(m>g;4j|n&vkl9|m^}~&LN>UVH5!LK>+WGde,psLt4q0tohmzLTZw\H69E>=G5i9g\n_
::iM>=iv(K9]j8|VrrX]H$,<5U72\seL|6HLohDE@O@IEs`tC==^c_|->#V/f0<|>Q=|baOESBpg|e9-k4N%s]Pi#hR<=R3t{`z5?z}f~`ZJs](JSzv^4!3JBzf!js-HudvI
::.!Lo]Xf]m{UwDY#2qVE|`F+~k\7GPNGw-C=8{3$x/y,BtH-bJ?`B/45EfJx-U->P~{r~ym-_l]w]DNFv[N4@7m3%(3>KJBrt1$%jKL@/^]no<l3#}l2Rk-]TWg!4swg{%;
::R7\*N,[Qq]}8E2~35F)vV5*%TGZT7l)zZIp(a*!(VtJ0t7Hv;r%)hu~6U{^t))Hdi;-9&B^;?Q~29VGCYRY]#{a=;(*+jYmr(K=nq^dvEPyFkmEtR($A>xy!nB53]3tw%t
::C0x*ubg\=wsxbt75H[cn%qfQB[O%5ChrG9bI|h*Q[B{E7)|7n`vw><Z`m\]ISlkY;r/r6c*)-#Y~d)@l&iDIR\ny>JM@!AZ*KG[mu|b!PN|#Rd;{]2A;Dm@E}j[3DyI7@,
::i9;]u8F*+m=Bwr12-cBqHU8OE2w_Gl-S/&^hx6,>G`r~N]VjYalaeq(q*r!iC9U^~[eg%eA`CLwbH+lXu+tbO_ZH0mO.n?i%1azM7zQ[p,gAaJ1%=a4,Ycji$@m5;1y)Z5
::7q&Y3x5itz<fX_[uegR-VpItBM>3FZRKE_w{j9ByEONVWfDFoPR!,ZDUlz+ZU8n/X5<AY#{zCm1k?13n>7hnnlto[e9;OcHN6=OKXM]T5m1v>,a0pF9#VA1Cu9-0\LuOL|
::qq4,b@5OaUM92Q`S/uBq&#TmJ$7ZFa@5k+u9Kp.C@]t0%zI^asT$@SZD-&1Vg`SMVlF\HSfU9k\j<z~*}y}h_2)-t0]p=0Pi6N`)9;HKk<IWmxr7?W67zy\Yg1[0jo~Bc8
::vb(i<o26]z`MJwH&-saf=INj0}_$E4kgR61r&{MLqG,r/J|)>3EG4nphC6E3NFS)pm>yuCBAg,AQko`K]2judafpP9(?iNyEEE)XTy9mr<k}IDcs/U@K0vxRFj(b6d=ieY
::Qn-c]ziQv^c5|.PmjI@UF-D-W[+q_Jo\1~9@u^74}8Xo\&W\Fn\rH`MK_0qs4hdqe<~i%$,g76v$MVfWPU[3khwv,?m&?qE{E~Jw,ZFr06gy!pRi)(aB_;d9^qCTdT<,MF
::K1|pbznTvx[8.SD>FBvq(W|q!mXN,>e$i~`DtobOX]}sISfkoU/!jM0B^iF{;[t25C/.t7<pSNi=.U<CH^=,Cj^ZlFeuMn\~F\VN98{,/s9N9zYW3208-mVYoh;1`BkG7g
::pM&f_B1Ideo;wq3fo)O<LUN,`QnRq6Hr>;dW/HWc3s#]9ktv<PR,/FrZ15Xf)!\NE;[^rB)PUWBLi|&`y%^;l<e&+9N5X1I]U#{A}6wC6a{*u|p?+}8*[LOL`ocxi!)A<J
::82r,\j|C1|hZqW*MDan5)3<f;_u}}{-T-HQ9W1HcS%(U^In2OX.#k.ed&7|7/&YoVF<xn^*{CKCgpPjvO8r]u//v{V]\dnues;IBSoDN%84cgS~Qp?^MU,Js^tn?wCHUAm
::OsQ@_EF0Boydb[rW*G]!QVYvB7$f,9[=U.GRmMpWU$unJ8ytyjq}+;5Sc`2$,c=1.(BeFCp)PKmP990rmt-lwZqO.@S~TEdSp2lOis3N&=}r&\%VV0Rli8ki3DBuJ<0P%u
::c>-K1Z/-\szUa8b`W<aF1a-E_NsJ[y<t(9zgV,G-D,s9Y{b-vUIB8)#;BXqG$56u+3(9u(H8Dxe6LG*/BT4`Qn8Ez&VN)n&Am\hVIl#GKN@##xvkPJuDQ+{hi0^c_\FIQM
::V<e?q6ODQm[jh*o<a}ux-TP;>9W@/t\[QgyG;~8U=^O\5NR9mCRL8kV]<9t)Pzv5$1p6n5I_GyQR/~g6BQ^B2OZ/_0[*5Ph%sl{SQJ^V\G5-lvg+bjYSpcVPjBFbeu+y~Q
::kKNp`KN9|cH%{3isS\i3cp4\DCqvs^Pxu4~;TO2QUA2M*+{|,znUMh^#RjQFx\91Uk~F0@$p>j4+nL0}5K)D<hpGei3ap3voUq7#U9;n3W46(96,\UI6D9zP8ZS7lnk].I
::cS)N_Sz2r9L~6/wJwXy|Z?nXi+U#R=m?1g@`ONk0!Fv#*xJ%DG.<P?d8mO|>q/$HelI#g_4]6c<YY]9[5g8uHdRd;Yl{S5E~vct7%wH/]fAt>/{{JKS_Lrw\sE\v1Rn7`6
::Z&)m]&(%]Oh+.FUajY-1m@$w&rF(tv-~n(Du`lrjmpFgN7[,7~d8E1Lo~T*~Cic0Xhd<Q8oGVklH-nNkgOn1zL#|G<vSbg!&v=Rts!P}JD0.~^En]Sl8Vjh<F04wr9YY(d
::?S_Q\Y1/{Vm10k07?!pFAy>CF|f)|0A&-Q%g%/tUE+-wtx}A(qW=?@fhBPab&UiT>zs0u/gKX4=q9`*Nj\JZKGbhQCP)wo9yV,W__-!)1Z6Y2iAU87;MOwZ>SH]nA?+Ua2
::dZzYRe=[sASX>sJ@~QCQ-OrA6aja%YV./HNCf7I0a1b]l]f6!.P=Sg^E[#D41QEbikMt_}oahnVw<\.>R$]\l!9@Qn3\*l9!*?EhVI288/%Ip*w=5M*jc?.B/A/4ogWIGr
::6Tg&[0Y$+sfHiIc><O^_bbCS,wBC75e2yt%[P**9W!_w{lA,<5.Cq6?qz{Q9/[*bf*l&X5HR[qy70MTI5_,Y6{n1U5p2p|/et3mHRH3q^%IWg,occ-{w%#c-,\RZw?~\nl
::]h!^TR]I?&W@,Fvu3lZ5h*Bs7`gQ.0Ul%i2$Nl\AiTo=^WmWB;-!L24+?QiT*u_Wj19&C[EDqR6dfS>[!o.Lw=u4<\ZqdK7~0hNio,CmhvS$!O[sgW9LoP;|wT-7xn1gA1
::B&l=6#hYmFq.nE_LbfV)GK+\UY0~kzZ%z\j<4&.<Ela2}HM;r}T/y+Fvj^<_E6f{1Eku]Km>pHrApEN\]Ly~8v\kvp^cv?f{7)Qyaab|l,/d{~)1u7if]^qdyF/Aj1hu&N
::Q7fHggBZEu97v;m@Wd74[hX^!7J$jzz2SzTH]4uJ%@{ilH(Q>K&G`zJCp(s`B7|ZFxh2+{w\W4X.k/],6[Qxiau2\)d0?QG~ic>Fv3/Ne=G^)6GAJ7_l)T>%D+*NI+Fn%=
::)=N<juF^)W?VNP!;f};C}xdB,VpIOyoD[yfm$sult9e%_,]G^gHV<O1^r)Dk/@aV9pI1pPaV]qTbd=IC3(gf)+8A\b(s|{dnqxidC1<g`e]AA0fc2=ec?M<b||RwnV~iRS
::<NS?EFQ+Xef^(M)_K9VIKf<[3}t-u#@7Fo<|_jkfq|aJ19Wx~R6JqStY4ZEsWAK1sF5Sk^vAhRR<dV~~jkF5w\@vNEpuT0j+[M?u3m}Q)X*4vZ;j6466(5#hmpW>6.`><n
::r$IA;K{<bP\anHc8[br[;IZ<u[{M[=|\R~T$2D-o/5`cD5X9$^U/8f&x1|3*.3g.v_3^MbOFQ_rT03)5C)+gLA#8>pIm-(HAIZ)DF@7og%/(.xGU`E.^>L5Uru$I/pqY>#
::UrHov0CS2U%aDAg[D\%rS*1)P~+#)/,/R_W51{;{mu0>-2n()+AigKv+65w6vP8!J,KduydqW7g9jk4!2%QZ5]<\bJ]<kN[)-Ya+$@4B^o+Z|nX}W@npIY,)&Q/G>*2y4l
::2TXWm!!UU[1z%F_GoYg<MDBh+aRTBj3s1_GRr^3Vq3SgfVo.ZgN{UH@MEUyP&#X_FALM|T!BskH09KnM)5`tfzpl&UzzUSAVHt;;XSMHG/%,k?mn`\y7tuK)^AwE<2FC40
::3w~16Q.[$ag-)RD&YaB3=2KS}EQtGr1IHulS.1;Q`FkaVY]K}T0pKF,O|OVTD+pO*BH7?,K{i61O<g/|gHz@FSD_N%^1zQWNfkR%_R??+3#q|4NT%p%;x|i=ThSj][{PTA
::yJwsBixDMUAd~?`bT}]]P}~M4%|(^VtQ;F=dB*Wg3RUB1;VKa\7}BFL;J2)N;0E*%og<%G;&1]-\dYNlI<;41r0NGZ>F86V6u}Fp\(OMS]5UTAp%F;}.iYALa1Dl}hC0AU
::tfWZHN1pQB=.#(\}&,~tZPz22?LP!W1bG3E{26{sF]ZoVSG9}2;Ygz?6E}QCfI,w`f0@+{<6\T`P|;~}brH>5ZY8+fd&bo@/5/Tun|w$rMhiMy@)J<O[|&fB{U`1N;dj{G
::3WRcIz*w}0eqZc9_OYCvI?qd{AS$IQ&4Jo=C^8HVwEGD~^L`X(%M(j9A1\,

:Files:[ default_sql
::AVEYO...Q5;;......*D........j}?.k...qGT,..={..d,qGy+SM........Rn\hsyk}cY%s5H-y5Z.$.r+P]3HQ5LP]vp7>\d-.ZOV;Rn_.dU,.8}^%fSJ.D/ILhxDS
::Dt#ILJpySd9_J9+L[mM*?lJ2<&~lab==0`=@1P8o;.3Sk?oQI.T?A1b%i=a)_.XO;.Vc..L6E=K)D08)T6cJmcnYU{N<hdeJzN=RzG?*?E&{p)_F!&Mzv9vFxeV[g@Z|&?
::VQQ)h}<\,>.P>06)..v;Q51U,.~\]k0w03b%T.S{[YGnhJeKPRU2GoJtrOQuW)rPf]>yl~onPJ?z[nPMDx>@chYYO8o,Tff_Y_axwNis8VoXF~2Z1Qkna=V6L)H]vr%.m|
::ylFpX%=VIIQ_gHl2!+c^g0l;H4g%WU[O~@`Wo0{#e6z$osu,8AwN(rI}tP)Ae8UCj,&aCa$%87@_=;~+J9(-;dSjg]R;9,IS=q%\s<xe_?|vRMXhu>Vt<z`u%,X]K{l757
::UxbwIvl}%Vb-[gkS6PBrxM#YMR)3de3H+t;b^wsGZ[}VIh`(1hPmb8wnh)v=OPAy9ME[Rm27g8ZiPf|=f}5#IoH4t}36EP;v0+,D4??y%Kn6jOt{\|bxYqvYmCtyH^D\Ml
::YB~4z>pF\?tWZO\QgtBx,<rOe6vO$B$VyY<[y2+5/T5n,K8C#Y{dSbG{^2[dlp<u$H%FQ1!/G/L<ZqRqozSWFfyyhYAAS}=IA#Dau|`<fdtO*HKx>EQ+]h6]jM9%8UU]tq
::DO^@Ov~R\A`sMkzr7wcJ%l5OOwk9tCK5e{_M`*nnsH*i{%~tB5|Bz`R$(FTp)j]a?F]lDEeV\i9gXk7F5R8b1YgaxJevI2Z&xVR<)Y(zd`nc;opW\vX(hG=feu^U\Tl/?(
::iYzU2P0Es9@a=nh,_!&8reo*lc/5XGClx~rhZ9UT%$Jty<G,{k0E@BmXd;*B9^zB*IN=x%L#6^F=^})E7J$-tqWN&Nb^dpH$;n$D}bP*1Q{xk<U4#vBq>|Lu`wQBvU.Xwq
::9~VK<t33ybi9}KT+.\`l2oZ_A76\Equ,i7wRV3V6[YZ1/$hpL-&o=@*F\J~6DOOuK,VRkG&vDNv`gYw+scI/A!Xd|>wFYyVgG}@dk$UpH]`zFKfJ.``Hk`qmp@Oj<wZqW@
::l{p_`jCxMb/dO7BASs7CiPaIW1yR^*UC>dN)j_sh)nv<B??4f#pa~p@a@1]%=JXW1fL6CT1TS`0{aSr6aL0@_Oniu86ylLb&zbi0*5Oe^mHYz|Mm(<t<YYFAi{Iio~B1k+
::;wos~+&O1y^OB*;[Iqe}S-UP+&L2#l0c>%>sDI=$jN\|q?Q/30YD%XQeK-}(u}81jBbXN<BINdMwL&4|8w[^tftkl%Pqnt=[_w(S|OUqAK.)zt}75wGr!Qf|ezhI/dI)1W
::-ilfXhf>#;B`^cZNU{mN6~2xernH1p}flIKDA7h9i,%@J+=!X-D>Ln)f8eT*I%8oEUD%I@U0;$p!y}?mSffN9d{V\e9E`~PKam?Ey;%m60IO/yWDKU2-2.pmugeW]sb9Sj
::]a/v!H5Z,xI=$36dt`+]oAWHGhZG1;5U=$UVu~zg,wM/z3)xkPFwFb[>Z|.8?bgD.%1fnn3DRZrRV\ohu($c$1~Ek<q*=<{K}iOEjHtXKG&cd-&7bXJhN~N/H0[?+!Lu02
::+M?OgjdLm~ppK;CLAekj[}(/pO9syIk,`/xTT_A_\KR#X*(%<*h7oGxGd7T1Dvb|bd1&0YKnIT!@jz#w[@ym=%C~{*6;itl#BFE.5EHqJM,`}LWG[,H]27

:Files:[ Bookmarks Fake
::AVEYO...Rn8,......*D........j}?.k...6)9,..+{..d,qGy+oD........Rn?fhej}v;g~rd,-Wz=$IE4F%{gdYv[x8)P({>BBN.L]{>j6..fsY;R[$=S-B2R!SZ@-
::{{`rM,X6tk!6ezDk`=L2{?jr\)g54+J>$;n+SSkn3e2sG;.$4aVPF.;>P-j~R,X$skJfUpTp>{MMHk}Gdf0+TqIN3hdjk]GQs+@Pl2R^!/_+RNh}GPlQYoz`\0yEt<3,F.
::,P..HgfYWZ4bym_ueFk{{S#R5!lTX!nWZ%Il-0_A?gmOlmuj]&M-X^*5-vn6\?/SNh^{LZZAJIP8!Pa@rgZJp@nMw0%i[jVM(g?Z`idU%8o5t8<ih~7kjgst13$%it/\@/
::-64(cQoY5^0W@.h^D9(B+dtoq6yZS{D[B^LO$P}9g+D.Szo1FVzjqDU%pJ[Rn*<1b^Eswg?x58?z!#GLsJ(r+h4k6z&F!#u3Je^E{Bjc|G/28sE`m0560uU@U,n_Zn@UVI
::s1M8Rr#?g}<K6C,PH-n8AsURfeC4XQR!;%&?Oejuz]F_oY]Ob}T;1UEV@@d(r3NE&5pZ`G~?,|P;L(Xik{Tg37;G)B0G)g05_hpGW\%K3&@Gu<vN$)|13#-+\4B}+Z},Lb
::q.3?[~N`lnLtFB6+z]P,,ES|$xLh3\y0=SO4-I^^^|!!;}|-Vy,|/^+[FxBHo-?bfF;ZU{Pg.vbh-`x_+ZICS9udW%W(aN9YvJJKgbL,I|q]IuoHiTQ_5_~sB)SCpAV-l~
::HS_W0377]Quh?#;N2E}%`zB\hc}#in[gvN%Ysqmq(T9Jzp]c%5yiRFQTv\+Kopg&u^m<;uHe)tjH5Ol-yCFa`>_[p]c52Q;YwY;>($wWHWM;,wvs2HiOr@e_3C/bv!KtEr
::_su%028c;Ck7]3sbBXo*EbdY;[ui1v/do[K!..Oej{Y{-S&(Ekm9M~b\[+eQBUYq{B~pN3q!=oLnosl&X-P9%0w\Q!6mMT%N*\9SkGM1^,^_c_FU%DEA,8MXs+$etA7>lM
::D^FjS#mMH3sz{%9rqZ+ucblxzWLjjhg`>NKP&,T2b}nb7P[*`wQQV$#?g)L#RK\#)9bHt0zDM`n*(`pVYEf/cGOQCnAc9~cUL-$0${RU{
:Files:]

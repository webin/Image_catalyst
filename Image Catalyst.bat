@echo off
>nul chcp 866

::Lorents & Res2001 2010-2012

setlocal enabledelayedexpansion
if "%~1" equ "thrt" call:threadwork "%~2" %3 %4 & exit /b
::if "%~1" equ "thrt" echo on & 1>>%4.log 2>&1 call:threadwork "%~2" %3 %4 & exit /b
if "%~1" equ "updateic" call:icupdate & exit /b

set "name=Image Catalyst"
set "version=2.2"
title [Loading] %name% %version%

set "fullname=%~0"
set "scrpath=%~dp0"
set "sconfig=%scrpath%tools\"
set "scripts=%scrpath%tools\scripts\"
set "tmppath=%TEMP%\%name%\"
set "errortimewait=30"

if exist "%systemroot%\system32\tasklist.exe" (
	for /f "tokens=* delims=" %%a in ('tasklist /v /fi "imagename eq cmd.exe" ^| find /c "%name%" ') do (
		if %%a equ 1 if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	)
)

set "apps=%~dp0Tools\apps\"
PATH %apps%;%PATH%
set "nofile="
if not exist "%apps%advdef.exe" set "nofile=%nofile%advdef.exe "
if not exist "%apps%deflopt.exe" set "nofile=%nofile%deflopt.exe "
if not exist "%apps%defluff.exe" set "nofile=%nofile%defluff.exe "
if not exist "%apps%dlgmsgbox.exe" set "nofile=%nofile%dlgmsgbox.exe "
if not exist "%apps%jhead.exe" set "nofile=%nofile%jhead.exe "
if not exist "%apps%jpegtran.exe" set "nofile=%nofile%jpegtran.exe "
if not exist "%apps%jtype.exe" set "nofile=%nofile%jtype.exe "
if not exist "%apps%miniperl.exe" set "nofile=%nofile%miniperl.exe "
if not exist "%apps%pngout.exe" set "nofile=%nofile%pngout.exe "
if not exist "%apps%truepng.exe" set "nofile=%nofile%truepng.exe "
if not exist "%apps%zlib.dll" set "nofile=%nofile%zlib.dll "
if not exist "%sconfig%config.ini" set "nofile=%nofile%config.ini "
if not exist "%scripts%jpegrescan.pl" set "nofile=%nofile%jpegrescan.pl "
if not exist "%scripts%xmlhttprequest.js" set "nofile=%nofile%xmlhttprequest.js "
if not exist "%scripts%filter.js" set "nofile=%nofile%filter.js "
if defined nofile (
	title [Error] %name% %version%
	if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
	1>&2 echo 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	1>&2 echo  Application can not get access to these files:
	1>&2 echo.
	for %%j in (%nofile%) do 1>&2 echo  - %%j
	1>&2 echo.
	1>&2 echo  Press Enter to exit.
	1>&2 echo 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
	pause>nul & exit
)

:settemp
set "rnd=%random%"
if not exist "%tmppath%%rnd%\" (
	set "tmppath=%tmppath%%rnd%"
	1>nul 2>&1 md "%tmppath%%rnd%" || call:errormsg "Can not create temporary folder:^|%tmppath%%rnd%!"
) else goto:settemp

set "ImageNumPNG=0"
set "ImageNumJPG=0"
set "TotalNumPNG=0"
set "TotalNumJPG=0"
set "TotalNumErrPNG=0"
set "TotalNumErrJPG=0"
set "TotalSizeJPG=0"
set "ImageSizeJPG=0"
set "TotalSizePNG=0"
set "ImageSizePNG=0"
set "changePNG=0"
set "changeJPG=0"
set "percPNG=0"
set "percJPG=0"
set "png="
set "jpeg="
set "stime="

set "updateurl=http://x128.ho.ua/update.ini"
set "configpath=%~dp0\Tools\config.ini"
set "logfile=%tmppath%\Images"
set "iculog=%tmppath%\icu.log"
set "iculck=%tmppath%\icu.lck"
set "countPNG=%tmppath%\countpng"
set "countJPG=%tmppath%\countjpg"
set "filelist=%tmppath%\filelist.txt"
set "filelisterr=%tmppath%\fileerr.txt"
set "isfilter="

set "params="
if "%~1" equ "" (
	dlgmsgbox.exe "Image Catalyst" "File1" " " "Graphic files (*.png;*.jpg;*.jpeg;*.jpe)" | cscript //nologo //E:JScript "%scripts%filter.js" 1>>"%filelist%" 2>>"%filelisterr%" || set "isfilter=1"
	if exist "%filelist%" for %%b in ("%filelist%") do if %%~zb gtr 0  (
		for /f "usebackq tokens=* delims=" %%a in ("%filelist%") do set "params=!params! "%%~a""
		if defined params for %%a in (!params!) do echo.[%%a]>>"%filelist%"
	)
	if not defined params (
		if not defined isfilter (
			call:errormsg "There are no files for optimization!"
			if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
			pause>nul & exit /b
		) else goto:endgettototalnum
	)
	set "params=!params:~1!"
)

::쀢���� ��誓Д��音 �� config.ini
set "fs=" & set "threadpng=" & set "updatecheck=" & set "outdir=" & set "outdir1="
set "sec-jpeg=" & set "dt="
set "na=" & set "nc=" & set "chunks="
call:readini "%configpath%"
if /i "%fs%" equ "true" (set "fs=/s") else (set "fs=")
call:sethread %threadpng% & set "threadpng=!thread!" & set "thread="
set "updatecheck=%update%" & set "update="
call set "outdir=%outdir%"
if /i "%dt%" equ "true" (set "ft=-ft") else (set "ft=")
if /i "%dc%" equ "true" set "sec-jpeg=-dc" & set "dc="
if /i "%de%" equ "true" set "sec-jpeg=%sec-jpeg% -de" & set "de="
if /i "%di%" equ "true" set "sec-jpeg=%sec-jpeg% -di" & set "di="
if /i "%dx%" equ "true" set "sec-jpeg=%sec-jpeg% -dx" & set "dx="
if /i "%du%" equ "true" set "sec-jpeg=%sec-jpeg% -du" & set "du="
if /i "%nc%" equ "false" (set "nc=-nc") else (set "nc=")

set "threadjpg=1"
if %threadpng% equ 1 (set "multithread=0") else (set "multithread=1")

::뫌ℓ젺�� 召ⓤ첓 �□젩졻猶젰щ� � �昔�信첓�щ� �젵ギ�.
if defined params goto:gettotalnum2
set "isinitfirst=1"

:gettotalnum
if "%~1" equ "" goto:gettotalnum2
setlocal disabledelayedexpansion
goto:initsource

:initfirst
set "var=%~f1"
set "isfilter1="
echo."%~f1" | cscript //nologo //E:JScript "%scripts%filter.js" 1>nul 2>&1 || set "isfilter1=1"
if not defined isfilter1 (
	echo.["%~f1"]>>"%filelist%"
	if defined ispng (
		if not defined isfolder (
			if exist "%~f1" (echo."%~f1" | cscript //nologo //E:JScript "%scripts%filter.js" 1>>"%filelist%" 2>>"%filelisterr%" || set "isfilter1=1")
		) else (
			dir /b %fs% /a-d-h "%~f1\*.png" 2>nul | cscript //nologo //E:JScript "%scripts%filter.js" 1>>"%filelist%" 2>>"%filelisterr%" || set "isfilter1=1"
		)
	)
	if defined isjpeg (
		if not defined isfolder (
			if exist "%~f1" (echo."%~f1" | cscript //nologo //E:JScript "%scripts%filter.js" 1>>"%filelist%" 2>>"%filelisterr%" || set "isfilter1=1")
		) else (
			dir /b %fs% /a-d-h "%~f1\*.jpg" "%~f1\*.jpe" 2>nul | cscript //nologo //E:JScript "%scripts%filter.js" 1>>"%filelist%" 2>>"%filelisterr%" || set "isfilter1=1"
		)
	)
) else (
	if defined isfolder (
		dir /b %fs% /a-d-h "%~1\*.png" "%~1\*.jpg" "%~1\*.jpe" 2>nul 1>>"%filelisterr%"
	) else echo."%~f1">>"%filelisterr%"
)
setlocal enabledelayedexpansion
if defined isfilter1 set "isfilter=%isfilter1%"
shift
goto:gettotalnum

:gettotalnum2
set "isinitfirst="
set "isfilter1="
::룼ㅱ曄� �↓ⅲ� ぎエ曄飡쥯 �□젩졻猶젰щ� � �昔�信첓�щ� �젵ギ� � �젳誓㎘ png/jpg
if exist "%filelist%" (
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelist%" ^| find /i /c ".png" 2^>nul') do set /a "TotalNumPNG+=%%a"
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelist%" ^| find /i /c ".jpg" 2^>nul') do set /a "TotalNumJPG+=%%a"
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelist%" ^| find /i /c ".jpe" 2^>nul') do set /a "TotalNumJPG+=%%a"
)
if exist "%filelisterr%" (
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelisterr%" ^| find /i /c ".png" 2^>nul') do set /a "TotalNumErrPNG+=%%a"
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelisterr%" ^| find /i /c ".jpg" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
	for /f "delims=" %%a in ('findstr /v /b "[" "%filelisterr%" ^| find /i /c ".jpe" 2^>nul') do set /a "TotalNumErrJPG+=%%a"
)

:endgettototalnum
if %TotalNumPNG% equ 0 if %TotalNumJPG% equ 0 (
	if defined isfilter  (
		set "jpeg=0" & set "png=0"
		cls
		echo _______________________________________________________________________________
		echo.
		call:end & >nul pause & exit /b
	) else call:errormsg "No files to optimize!"
)
if "%TotalNumPNG%" equ "0" set "multithread=0"

if not defined outdir (
	for /f "tokens=* delims=" %%a in ('dlgmsgbox.exe "Image Catalyst" "Folder3" " " "Select folder for output files:" ') do set "outdir=%%~a"
)
if defined outdir (
	if "!outdir:~-1!" neq "\" set "outdir=!outdir!\"
	if not exist "!outdir!" (1>nul 2>&1 md "!outdir!" || call:errormsg "Can not create folder for optimized files:^|!outdir! !")
)

::⇔�� 캙�젹β昔� ��殊Ж쭬與�
if %TotalNumPNG% gtr 0 if not defined png call:png
if %TotalNumJPG% gtr 0 if not defined jpeg call:jpeg

if "%png%" equ "0" set "multithread=0"
if %multithread% neq 0 (
	for /l %%a in (1,1,%threadpng%) do >"%logfile%png.%%a" echo.
	for /l %%a in (1,1,%threadjpg%) do >"%logfile%jpg.%%a" echo.
)
if not defined png set "png=0"
if not defined jpeg set "jpeg=0"

if /i "%na%" equ "false" (
	set "na=-na"
) else (
	if %png% equ 1 set "na=-a1"
	if %png% equ 2 set "na=-a0"
	if %png% equ 3 set "na=-a1"
	if %png% equ 4 set "na=-a0"
	if %png% equ 5 set "na=-a1"
	if %png% equ 6 set "na=-a0"
)
cls
echo _______________________________________________________________________________
echo.
if /i "%updatecheck%" equ "true" start "" /b cmd.exe /c ""%fullname%" updateic"
call:setitle
call:setvtime stime
for /f "tokens=1 delims=[]" %%a in ('findstr /b "[" "%filelist%" ') do if exist "%%~a" (
	call:initsource "%%~a"
	if defined outdir (
		if defined isfolder (
			set "var=%%~fa"
			if "!var:~-1!" equ "\" set "var=!var:~,-1!"
			for %%b in (!var!) do call:getfilename "%outdir%%%~nxb"
			set "outdir1=!getfilename!"
		) else set "outdir1=%outdir%"
	)
	if defined ispng if "%png%" neq "0" call:pngwork "%%~a"
	if defined isjpeg if "%jpeg%" neq "0" call:jpegwork "%%~a"
)

:waithread
set "thrt="
for /l %%z in (1,1,%threadpng%) do if exist "%tmppath%\thrtpng%%z.lck" (set "thrt=1") else (call:typelog & call:setitle)
for /l %%z in (1,1,%threadjpg%) do if exist "%tmppath%\thrtjpg%%z.lck" (set "thrt=1") else (call:typelog & call:setitle)
if defined thrt call:waitrandom 1000 & goto:waithread
call:end
pause>nul & exit /b

::볚�젺�˚� ㎛좂��⑨ ��誓Д����, º� ぎ獸昔� ��誓쩆�� � %1, � 收ゃ芋� 쩆栒/№�э � 兒席졻� ㄻ� �猶�쩆 ⓥ�．�
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: 볚�젺�˙����� ㎛좂���� ��誓Д���� %1
:setvtime
set "%1=%date% %time:~0,2%:%time:~3,2%:%time:~6,2%"
exit /b

::뤲�´夕� ㄾ飡承��飡� ��¡� ´褻Ŀ IC.
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:icupdate
if not exist "%scripts%xmlhttprequest.js" exit /b
>"%iculck%" echo.Update IC
cscript //nologo //E:JScript "%scripts%xmlhttprequest.js" %updateurl% 2>nul 1>"%iculog%" || 1>nul 2>&1 del /f /q "%iculog%"
1>nul 2>&1 del /f /q "%iculck%"
exit /b

::뇿�信첓β �□젩�洵Ø �젵쳽 � �ㄽ���獸嶺�� Œ� Л�．��獸嶺�� 誓┬Д.
::룧�젹β贍:
::	%1 - png | jpg
::	%2 - ぎエ曄飡¡ ��獸ぎ� 쩆���． ˘쩆
::	%3 - �呻� � �□젩졻猶젰Мс �젵ャ
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:createthread
if %2 equ 1 call:threadwork %3 %1 1 & call:typelog & exit /b
for /l %%z in (1,1,%2) do (
	if not exist "%tmppath%\thrt%1%%z.lck" (
		call:typelog
		>"%tmppath%\thrt%1%%z.lck" echo Process file: %3
		start /b cmd.exe /s /c ""%fullname%" thrt "%~3" %1 %%z"
		exit /b
	)
)
call:waitrandom 1000
goto:createthread

::룯誓‘� �젵ギ� ㄻ� �猶�쩆 飡졻ⓤ殊え ㄻ� Л�．��獸嶺�． 誓┬쵟. 꽑��瑜 葉�좐恂� �� %logfile%*.
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:typelog
if %multithread% equ 0 exit /b
for /l %%c in (1,1,%threadpng%) do (
	if not defined typenumpng%%c set "typenumpng%%c=1"
	call:typelogfile "%logfile%png.%%c" "typenumpng%%c" %%typenumpng%%c%% TotalNumErrPNG
)
for /l %%c in (1,1,%threadjpg%) do (
	if not defined typenumjpg%%c set "typenumjpg%%c=1"
	call:typelogfile "%logfile%jpg.%%c" "typenumjpg%%c" %%typenumjpg%%c%% TotalNumErrJPG
)
exit /b

::쀢���� �젵쳽 � �젳‘� 飡昔� ㄻ� �猶�쩆 飡졻ⓤ殊え ㄻ� Л�．��獸嶺�． 誓┬쵟.
::룧�젹β贍:	%1 - �젵� � 兒席졻� images.csv
::		%2 - º� ��誓Д����, � ぎ獸昔� 魚젺ⓥ碎 ぎエ曄飡¡ �□젩��젺�音 飡昔� � 쩆���� �젵ゥ
::		%3 - ぎエ曄飡¡ �□젩��젺�音 飡昔� � 쩆���� �젵ゥ
::		%4 - TotalNumErrJPG | TotalNumErrPNG
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:typelogfile
if not exist "%~1" exit /b
for /f "skip=%3 tokens=1-5 delims=;" %%b in ('type "%~1" ') do (
	if "%%d" equ "" (
		1>&2 echo  File  - "%%~b"
		1>&2 echo  Error - %%c
		1>&2 echo._______________________________________________________________________________
		1>&2 echo.
		set /a "%4+=1"
	) else (
		call:printfileinfo "%%~b" %%c %%d %%e %%f
	)
	set /a "%~2+=1"
)
exit /b

::귣¡� Þ兒席졿Ŀ � �젵ゥ � ��誓¡ㄾ� � 뒃.
::룧�젹β贍:
::	%1 - º� �젵쳽
::	%2 - �젳Д� ℡�ㄽ�． �젵쳽 � 줎⒱졾
::	%3 - �젳Д� �音�ㄽ�． �젵쳽 � 줎⒱졾
::	%4 - �젳�ⓩ� � 줎⒱졾
::	%5 - �젳�ⓩ� � �昔璵��졾
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:printfileinfo
echo  File  - "%~f1"
set "float=%2"
call:division float 1024 100
echo  In    - %float% 뒃
set "change=%4"
call:division change 1024 100
set "float=%3"
call:division float 1024 100
echo  Out   - %float% Kb ^(%change% Kb, %5%%^)
echo _______________________________________________________________________________
echo.
exit /b

::뇿�信� �□젩�洵Ø�� �젵ギ� ㄻ� Л�．��獸嶺�� �□젩�洙�.
::룧�젹β贍:
::	%1 - �呻� � �□젩졻猶젰Мс �젵ャ
::	%2 - png | jpg
::	%3 - ��Д� ��獸첓 쩆���． ˘쩆
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:threadwork
if /i "%2" equ "png" call:pngfilework %1 %3 & if %multithread% neq 0 >>"%countPNG%.%3" echo.1
if /i "%2" equ "jpg" call:jpegfilework %1 %3
if exist "%tmppath%\thrt%2%3.lck" >nul 2>&1 del /f /q "%tmppath%\thrt%2%3.lck"
exit /b

::렑Ħ젰� �恂呻飡˘� 쭬쩆���． � %1 �젵쳽. 뫉拾ⓥ ㄻ� �┬쩆�⑨ 說汀⑨ ∥�え昔˚� �黍 Л�．��獸嶺�� �□젩�洙�.
::룧�젹β贍: %1 - �呻� � �젵ャ 氏젫�.
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:waitflag
if not exist "%~1" (>"%~1" echo.%~2 & exit /b)
call:waitrandom 2000
goto:waitflag

::렑Ħ젰� 笹晨젵��� ぎエ曄飡¡ Жカⓤⅹ勝�, �｀젺①����� 쭬쩆��臾 캙�젹β昔�.
::룧�젹β贍: %1 - �｀젺①���� 笹晨젵��． ㎛좂��⑨ ぎエ曄飡쥯 Й醒�.
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:waitrandom
set /a "ww=%random%%%%1"
1>nul 2>&1 ping -n 1 -w %ww% 127.255.255.255
exit /b

::뤲�璵ㅳ�� Þⓩ쯄エ쭬與� ��誓Д��音 ㄻ� �曄誓ㄽ�． ⓤ獸嶺Ø� �□젩�洙�.
::룧�젹β贍: %1 - �呻� � ⓤ獸嶺Ø� �□젩�洙� (�젵ャ Œ� 캙�ぅ).
::궙㎖�좈젰щ� ㎛좂��⑨: �昔Þⓩ쯄エ㎤昔쥯��瑜 ��誓Д��瑜 isjpeg, ispng, isfolder.
:initsource
set "isjpeg="
set "ispng="
set "isfolder="
1>nul 2>&1 dir /ad "%~1" && set "isfolder=1"
if not defined isfolder (
	if /i "%~x1" equ ".png" set "ispng=1"
	if /i "%~x1" equ ".jpg" set "isjpeg=1"
	if /i "%~x1" equ ".jpeg" set "isjpeg=1"
	if /i "%~x1" equ ".jpe" set "isjpeg=1"
) else (
	1>nul 2>nul dir /b %fs% /a-d-h "%~1\*.png" && set "ispng=1"
	1>nul 2>nul dir /b %fs% /a-d-h "%~1\*.jpg" "%~1\*.jpe" && set "isjpeg=1"
)
if defined isinitfirst (goto:initfirst) else exit /b

::볚�젺�˚� ぎエ曄飡쥯 ��獸ぎ� ㄻ� Л�．��獸嶺�� �□젩�洙�. 
::룧�젹β贍: %1 - �誓ㄻ젫젰М� ぎエ曄飡¡ ��獸ぎ� (М┘� �恂呻飡¡쥯筍).
::궙㎖�좈젰щ� ㎛좂��⑨: �昔Þⓩ쯄エ㎤昔쥯�췅� ��誓Д�췅� thread.
:sethread
if "%~1" equ "" (
	set "thread=%NUMBER_OF_PROCESSORS%"
) else (
	set /a "thread=%~1+1-1"
	if "!thread!" equ "0" set "thread=%NUMBER_OF_PROCESSORS%"
)
exit /b

::궋�� 캙�젹β昔� ��殊Ж쭬與� png �젵ギ�. 
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �昔Þⓩ쯄エ㎤昔쥯�췅� ��誓Д�췅� png.
:png
cls
title [PNG: %TotalNumPNG%] %name% %version%
echo  컴컴컴컴컴컴컴컴컴컴컴컴�
echo  PNG optimization mode:
echo  컴컴컴컴컴컴컴컴컴컴컴컴�
echo.
echo  Non-interlaced:
echo  [1] Xtreme	[2] Advanced
echo.
echo  Interlaced:
echo  [3] Xtreme	[4] Advanced
echo.
echo  Default:
echo  [5] Xtreme	[6] Advanced
echo.
echo  [0] Skip PNG optimization
echo.
set png=
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
set /p png="#Select PNG optimization mode and press Enter [0-8]: "
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
echo.
if "%png%" equ "" goto:png
if "%png%" equ "0" exit /b
if "%png%" neq "1" if "%png%" neq "2" if "%png%" neq "3" if "%png%" neq "4" if "%png%" neq "5" if "%png%" neq "6" if "%png%" neq "7" if "%png%" neq "8" goto:png
exit /b

::궋�� 캙�젹β昔� ��殊Ж쭬與� jpg �젵ギ�. 
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �昔Þⓩ쯄エ㎤昔쥯�췅� ��誓Д�췅� jpeg.
:jpeg
cls
title [JPEG: %TotalNumJPG%] %name% %version%
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴
echo  JPEG optimization mode:
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴
echo.
echo  [1] Optimize	[2] Progressive
echo.
echo  [3] Maximum	[4] Default
echo.
echo  [0] Skip JPEG optimization
echo.
set jpeg=
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
set /p jpeg="#Select JPEG optimization mode and press Enter [0-4]: "
echo  컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
echo.
if "%jpeg%" equ "" goto:jpeg
if "%jpeg%" equ "0" exit /b
if "%jpeg%" neq "1" if "%jpeg%" neq "2" if "%jpeg%" neq "3" if "%jpeg%" neq "4" goto:jpeg
exit /b

::볚�젺�˚� 쭬．ギ˚� �き� ¡ №�э ��殊Ж쭬與�.
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:setitle
if "%jpeg%" equ "0" if "%png%" equ "0" (title %~1%name% %version% & exit /b)
if %multithread% neq 0 (
	set "ImageNumPNG=0"
	for /l %%c in (1,1,%threadpng%) do for %%b in ("%countPNG%.%%c") do set /a "ImageNumPNG+=%%~zb/3" 2>nul
)
if "%jpeg%" equ "0" (
	title %~1[PNG - %png%: %ImageNumPNG%/%TotalNumPNG%] %name% %version%
) else (
	if "%png%" equ "0" (
		title %~1[JPEG - %jpeg%: %ImageNumJPG%/%TotalNumJPG%] %name% %version%
	) else (
		title %~1[PNG - %png%: %ImageNumPNG%/%TotalNumPNG%] [JPEG - %jpeg%: %ImageNumJPG%/%TotalNumJPG%] %name% %version%
	)
)
exit /b

::렊若� ⓤ獸嶺Ø� � 쭬�信� �□젩�洵Ø� ㄻ� 첓┐�． png �젵쳽.
::룧�젹β贍: %1 - ⓤ獸嶺Ø (�呻� � �젵ャ Œ� 캙�ぅ)
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:pngwork
set "source=%~f1"
set "source=%source:\=\\%"
if defined isfolder for /f "delims=" %%i in ('findstr /v /b "[" "%filelist%" ^| findstr /i /r /c:"%source%.*\.png$" ') do (
	call:filework "%~f1" "%%~fi" png %threadpng% ImageNumPNG
) else call:filework "%~f1" "%%~f1" png %threadpng% ImageNumPNG
exit /b

::렊若� ⓤ獸嶺Ø� � 쭬�信� �□젩�洵Ø� ㄻ� 첓┐�． jpg �젵쳽.
::룧�젹β贍: %1 - ⓤ獸嶺Ø (�呻� � �젵ャ Œ� 캙�ぅ)
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:jpegwork
set "source=%~f1"
set "source=%source:\=\\%"
if defined isfolder for %%g in (jpg jpe jpeg) do (
	for /f "delims=" %%i in ('findstr /v /b "[" "%filelist%" ^| findstr /i /r /c:"%source%.*\.%%g$" ') do (
		call:filework "%~f1" "%%~fi" jpg %threadjpg% ImageNumJPG
	)
) else call:filework "%~f1" "%%~f1" jpg %threadjpg% ImageNumJPG
exit /b

::뤲� 쭬쩆��� %outdir%, ぎ�ⓣ�쥯��� ⓤ若ㄽ音 �젵ギ� � outdir � 貰魚젺����� 飡說も侁� 첓�젷�．� 
::�狩�歲收レ�� ⓤ獸嶺Ø�. 뇿�信� �□젩�洵Ø� �젵ギ�.
::룧�젹β贍:
::	%1 - ⓤ獸嶺Ø (�呻� � �젵ャ Œ� 캙�ぅ)
::	%2 - �□젩졻猶젰щ� �젵�
::	%3 - png | jpg
::	%4 - %threadpng% | %threadjpg%
::	%5 - ImageNumPNG | ImageNumJPG
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:filework
set "outfile=%~f2"
if defined outdir (
	if defined isfolder (
		call set "outfile=%outdir1%\%%outfile:%~1=%%"
	) else (
		call:getfilename "%outdir1%\%%outfile:%~dp1=%%"
		set "outfile=!getfilename!"
	)
	for %%j in ("!outfile!") do 1>nul 2>&1 md "%%~dpj"
	1>nul 2>&1 copy /y "%~2" "!outfile!"
)
call:createthread %3 %4 "%outfile%"
set /a "%5+=1"
call:setitle
exit /b

::끷エ �젵� %1 率耀飡㏂β, 獸 � º��� �젵쳽 ㄾ줎˙畑恂� ��涉ㄺ��硫 ��Д� � 兒席졻�: 
::%~dpn1-NNNN.%~x1
::룧�젹β贍: %1 - �呻� � �젵ャ
::궙㎖�좈젰щ� ㎛좂��⑨: 宋�席ⓣ�쥯���� º� �젵쳽 � ��誓Д���� getfilename.
:getfilename
set "getfilename=%~1"
if not exist "%~1" exit /b
set "countfn=1"
:gfn
set "countfile=000%countfn%"
set "getfilename=%~dpn1-%countfile:~-4%%~x1"
if not exist "%getfilename%" exit /b
if %countfn% equ 9999 exit /b 
set /a "countfn+=1"
goto:gfn

::렊�젩�洵Ø png �젵ギ�.
::룧�젹β贍:
::	%1 - �呻� � �□젩졻猶젰Мс �젵ャ
::	%2 - ��Д� ��獸첓 �□젩�洙�
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:pngfilework
set "errbackup=0"
set "isinterlaced%2="
set "logfile2=%logfile%png.%2"
set pnglog="%tmppath%\png%2.log"
set "filework=%tmppath%\%~n1-ic%2%~x1"
1>nul 2>&1 copy /b /y "%~f1" "%filework%" || (call:saverrorlog "%~f1" "File not found" & exit /b)
>%pnglog% 2>nul truepng -info "%filework%"
if errorlevel 1 (call:saverrorlog "%~f1" "File not supported" & 1>nul 2>&1 del /f /q %filework% & 1>nul 2>&1 del /f /q %pnglog% & exit /b)
set "psize=%~z1"
if %png% equ 1 call:Non-interlaced-Xtreme "%filework%" >nul
if %png% equ 2 call:Non-interlaced-Advanced "%filework%" >nul
if %png% equ 3 call:Interlaced-Xtreme "%filework%" >nul & set "isinterlaced=1"
if %png% equ 4 call:Interlaced-Advanced "%filework%" >nul & set "isinterlaced=1"
if %png% gtr 4 (
	find /i "Interlaced" <%pnglog% >nul
	if errorlevel 1 (
		if %png% equ 5 call:Non-interlaced-Xtreme "%filework%" >nul
		if %png% equ 6 call:Non-interlaced-Advanced "%filework%" >nul
	) else (
		if %png% equ 5 call:Interlaced-Xtreme "%filework%" >nul
		if %png% equ 6 call:Interlaced-Advanced "%filework%" >nul
	)
)
if %png% gtr 4 (
	call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
) else (
	set "isinterlaced%2="
	find /i "Interlaced" <%pnglog% >nul && set "isinterlaced%2=1"
	if %png% lss 3 (
		if not defined isinterlaced%2 (
			call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
		) else (
			1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
		)
	) else (
		if defined isinterlaced%2 (
			call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
		) else (
			1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
		)
	)
)
if %errbackup% neq 0 (call:saverrorlog "%~f1" "Access denied or file not exists." & 1>nul 2>&1 del /f /q %filework% %pnglog% & exit /b)
truepng -nz -md %chunks% "%~f1" >nul
deflopt -k "%~f1" >nul
defluff < "%~f1" > "%filework%-defluff.png" 2>nul
1>nul 2>&1 move /y "%filework%-defluff.png" "%~f1"
deflopt -k "%~f1" >nul
call:savelog "%~f1" !psize!
if %multithread% equ 0 for %%a in ("%~f1") do (set /a "ImageSizePNG+=%%~za" & set /a "TotalSizePNG+=%psize%")
1>nul 2>&1 del /f /q %pnglog% >nul
exit /b

::렊�젩�洵Ø jpg �젵ギ�.
::룧�젹β贍:
::	%1 - �呻� � �□젩졻猶젰Мс �젵ャ
::	%2 - ��Д� ��獸첓 �□젩�洙�
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:jpegfilework
set "ep="
set "cm="
set "errbackup=0"
set "logfile2=%logfile%jpg.%2"
set "filework=%tmppath%\%~n1%2%~x1"
1>nul 2>&1 copy /b /y "%~f1" "%filework%" || (call:saverrorlog "%~f1" "File not found" & exit /b)
for /f "tokens=*" %%j in ('jtype t "%filework%"') do set ep=%%j
for /f "tokens=*" %%j in ('jtype c "%filework%"') do set cm=%%j
if "!ep!" equ "" (call:saverrorlog "%~f1" "뵠œ �� ��ㄴ�逝Ð젰恂�" & 1>nul 2>&1 del /f /q "%filework%" & exit /b)
if "!cm!" equ "" (call:saverrorlog "%~f1" "뵠œ �� ��ㄴ�逝Ð젰恂�" & 1>nul 2>&1 del /f /q "%filework%" & exit /b)
set "jsize=%~z1"
if %jpeg% equ 1 (
	jpegtran -copy all -optimize "%filework%" "%filework%" >nul
	if /i "!ep!" equ "Baseline" call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
	if /i "!ep!" equ "Progressive" 1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
)
if %jpeg% equ 2 (
	if /i "!cm!" equ "CMYK" jpegtran -copy all -progressive "%filework%" "%filework%" >nul
	if /i "!cm!" equ "RGB" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%" >nul
	if /i "!cm!" equ "BW" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%" >nul
	if /i "!ep!" equ "Baseline" 1>nul 2>&1 move /y "%filework%" "%~f1" || set "errbackup=1"
	if /i "!ep!" equ "Progressive" call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
)
if %jpeg% equ 3 (
	jpegtran -copy all -optimize "%filework%" "%filework%.opt" >nul
	if /i "!cm!" equ "CMYK" jpegtran -copy all -progressive "%filework%" "%filework%.pro" >nul
	if /i "!cm!" equ "RGB" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%.pro" >nul
	if /i "!cm!" equ "BW" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%.pro" >nul
	call:backup "%~f1" "%filework%.opt" >nul || set "errbackup=1"
	call:backup "%~f1" "%filework%.pro" >nul || set "errbackup=1"
)
if %jpeg% equ 4 (
	if /i "!ep!" equ "Baseline" jpegtran -copy all -optimize "%filework%" "%filework%" >nul
	if /i "!ep!" equ "Progressive" (
		if /i "!cm!" equ "CMYK" jpegtran -copy all -progressive "%filework%" "%filework%" >nul
		if /i "!cm!" equ "RGB" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%" >nul
		if /i "!cm!" equ "BW" miniperl "%scripts%jpegrescan.pl" jpegtran "%filework%" "%filework%" >nul
	)
	call:backup "%~f1" "%filework%" >nul || set "errbackup=1"
)
if %errbackup% neq 0 (call:saverrorlog "%~f1" "Access denied or file not exists." & 1>nul 2>&1 del /f /q %filework% & exit /b)
jhead %sec-jpeg% %ft% "%~f1" 1>nul 2>nul
call:savelog "%~f1" !jsize!
if %multithread% equ 0 for %%a in ("%~f1") do (set /a "ImageSizeJPG+=%%~za" & set /a "TotalSizeJPG+=%jsize%")
exit /b

::끷エ �젳Д� �젵쳽 %2 ‘レ蜈, 曄� �젳Д� %1, 獸 %2 ��誓��歲恂� 췅 Д飡� %1, Þ좂� %2 蝨젷畑恂�.
::룧�젹β贍:
::	%1 - �呻� � ��舒�с �젵�
::	%2 - �呻� ぎ ™�昔с �젵ャ
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:backup
if not exist "%~1" exit /b 2
if not exist "%~2" exit /b 3
if %~z1 leq %~z2 (1>nul 2>&1 del /f /q %2) else (1>nul 2>&1 move /y %2 %1 || exit /b 1)
exit /b

::귣葉笹���� �젳�ⓩ� �젳Д�� ⓤ若ㄽ�． � ��殊Ж㎤昔쥯���． �젵쳽 (chaneg � perc).
::꽞� Л�．��獸嶺�� �□젩�洙� 쭬�ⓤ� � %logfile% Þ兒席졿Ŀ �� �□젩��젺��� �젵ゥ.
::꽞� �ㄽ���獸嶺�� �□젩�洙� �猶�� 飡졻ⓤ殊え 췅 咨�젺.
::룧�젹β贍:
::	%1 - �呻� � ��殊Ж㎤昔쥯���с �젵ャ
::	%2 - �젳Д� ⓤ若ㄽ�． �젵쳽
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:savelog
set /a "change=%~z1-%2"
set /a "perc=%change%*100/%2" 2>nul
set /a "fract=%change%*100%%%2*100/%2" 2>nul
set /a "perc=%perc%*100+%fract%"
call:division perc 100 100
if %multithread% neq 0 (
	>>"%logfile2%" echo.%~1;%2;%~z1;%change%;%perc%
) else (
	call:printfileinfo "%~1" %2 %~z1 %change% %perc%
)
exit /b

::렞��졿⑨ ㄵゥ�⑨ ㄲ愼 璵ル� 葉醒�, 誓㎯レ�졻 - ㅰ�∼�� 葉笹�.
::룧�젹β贍:
::	%1 - º� ��誓Д����, 貰ㄵ逝좈ⅸ 璵ギ� 葉笹� ㄵエМ�
::	%2 - ㄵエ收レ
::	%3 - 10/100/1000... - �む膝ゥ��� ㅰ�∼�� �졹殊 (ㄾ ㄵ碎瞬�, ㄾ 貰瞬�, ㄾ 瞬碎嶺音, ...)
::궙㎖�좈젰щ� ㎛좂��⑨: set %1=�揖ⓤゥ���� ㅰ�∼�� �졹狩��
:division
set "sign="
1>nul 2>&1 set /a "int=!%1!/%2"
1>nul 2>&1 set /a "fractd=!%1!*%3/%2%%%3"
if "%fractd:~,1%" equ "-" (set "sign=-" & set "fractd=%fractd:~1%")
1>nul 2>&1 set /a "fractd=%3+%fractd%"
if "%int:~,1%" equ "-" set "sign="
set "%1=%sign%%int%.%fractd:~1%
exit /b

::꽞� Л�．��獸嶺�� �□젩�洙� 쭬�ⓤ� 貰�↓��⑨ �� �鼇―� �□젩�洙� � %logfile%.
::꽞� �ㄽ���獸嶺�� �□젩�洙� �猶�� 貰�↓��⑨ �� �鼇―� 췅 咨�젺.
::룧�젹β贍:
::	%1 - �呻� � ��殊Ж㎤昔쥯���с �젵ャ
::	%2 - 貰�↓���� �� �鼇―�
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:saverrorlog
1>nul 2>&1 del /f /q "%filework%"
if %multithread% neq 0 (
	>>"%logfile2%" echo.%~1;%~2
) else (
	1>&2 echo  File  - "%~f1"
	1>&2 echo  Error - %~2
	1>&2 echo _______________________________________________________________________________
	1>&2 echo.
)
exit /b

::귣¡� ⓥ�．¡． 貰�↓��⑨ � 飡졻ⓤ殊ぅ �□젩�洙� � 췅エ葉� �∼�˙��Ł.
::룧�젹β贍: �β
::궙㎖�좈젰щ� ㎛좂��⑨: �β
:end
if not defined stime call:setvtime stime
call:setvtime ftime
set "changePNG=0" & set "percPNG=0" & set "fract=0"
set "changeJPG=0" & set "percJPG=0" & set "fract=0"
if "%jpeg%" equ "0" if "%png%" equ "0" 1>nul 2>&1 ping -n 1 -w 500 127.255.255.255 & goto:finmessage
if %multithread% neq 0 (
	for /l %%i in (1,1,%threadpng%) do if exist "%logfile%png.%%i" (
		for /f "usebackq tokens=1-5 delims=;" %%a in ("%logfile%png.%%i") do if "%%c" neq "" (
			set /a "TotalSizePNG+=%%b" & set /a "ImageSizePNG+=%%c"
		)
	)
	for /l %%i in (1,1,%threadjpg%) do  if exist "%logfile%jpg.%%i" (
		for /f "usebackq tokens=1-5 delims=;" %%a in ("%logfile%jpg.%%i") do if "%%c" neq "" (
				set /a "TotalSizeJPG+=%%b" & set /a "ImageSizeJPG+=%%c"
		)
	)
)
set /a "changePNG=(%ImageSizePNG%-%TotalSizePNG%)" 2>nul
set /a "percPNG=%changePNG%*100/%TotalSizePNG%" 2>nul
set /a "fract=%changePNG%*100%%%TotalSizePNG%*100/%TotalSizePNG%" 2>nul
set /a "percPNG=%percPNG%*100+%fract%" 2>nul
call:division changePNG 1024 100
call:division percPNG 100 100

set /a "changeJPG=(%ImageSizeJPG%-%TotalSizeJPG%)" 2>nul
set /a "percJPG=%changeJPG%*100/%TotalSizeJPG%" 2>nul
set /a "fract=%changeJPG%*100%%%TotalSizeJPG%*100/%TotalSizeJPG%" 2>nul
set /a "percJPG=%percJPG%*100+%fract%" 2>nul
call:division changeJPG 1024 100
call:division percJPG 100 100

:finmessage
1>nul 2>&1 del /f /q "%logfile%*" "%countJPG%" "%countPNG%*" "%filelist%" "%filelisterr%"
call:totalmsg PNG %png%
call:totalmsg JPG %jpeg%
echo  Started  at - %stime%
echo  Finished at - %ftime%
echo.
echo  Optimization completed. Press Enter for exit.
echo _______________________________________________________________________________
if /i "%updatecheck%" equ "true" (
	call:waitflag "%iculck%"
	1>nul 2>&1 del /f /q "%iculck%"
	if exist "%iculog%" (
		call:readini "%iculog%"
		if "%version%" neq "!ver!" (
			set "isupdate="
			for /f "tokens=* delims=" %%a in ('dlgmsgbox.exe "Image Catalyst" "Msg1" " " "New version exists %name% !ver!^|Do you want to update?" "Q4" "%errortimewait%" 2^>nul') do set "isupdate=%%~a"
			if "!isupdate!" equ "6" start "" !url!
		)
		1>nul 2>&1 del /f /q "%iculog%"
	)
)
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
exit /b

:totalmsg
call set /a "tt=%%TotalNum%1%%+%%TotalNumErr%1%%"
if "%2" equ "0" (
	set "opt=0"
	set "tterr=%tt%"
) else (
	call set opt=%%TotalNum%1%%
	call set "tterr=%%TotalNumErr%1%%"
)
if "%tt%" neq "0" (
	echo  Total Number of %1:	%tt%
	echo  Optimized %1:		%opt%
	if "%tterr%" neq "0" echo  Skipped %1:		%tterr%
	call echo  Total %1:  		%%change%1%% 뒃, %%perc%1%%%%%%
	echo.
)
exit /b

::뿨�젰�-ini �젵�. 뒥┐硫 캙�젹β� ini-�젵쳽 �誓�□젳��猶젰恂� � �ㄽ�º���莘 ��誓Д��莘 � 
::貰�手β飡�迹º 貰ㄵ逝º臾. 뒶Д��졷Ŀ � ini - 歲Б�� ";" � 췅�젷� 飡昔え, º�췅 醒ゆŁ - ª��黍說荻碎.
::룧�젹β贍: %1 - ini-�젵�
::궙㎖�좈젰щ� ㎛좂��⑨: 췅‘� ��誓Д��音 腥���黍昔쥯��音 췅 �說�쥯�Ŀ ini-�젵쳽.
:readini
for /f "usebackq tokens=1,* delims== " %%a in ("%~1") do (
	set param=%%a
	if "!param:~,1!" neq ";" if "!param:~,1!" neq "[" set "%%~a=%%~b"
)
exit /b

:errormsg
title [Error] %name% %version%
if exist "%tmppath%" 1>nul 2>&1 rd /s /q "%tmppath%"
1>nul 2>&1 dlgmsgbox.exe "Image Catalyst" "Msg1" " " "%~1" "E0" "%errortimewait%"
exit

:Non-interlaced-Xtreme
set "kp="
truepng -i0 -zc8-9 -zm3-9 -zs0-3 -fe -fs:7 %nc% %na% -force "%~f1"
for /f "tokens=2 delims=/f " %%j in ('pngout -l "%~f1"') do set "filter=%%j"
if "!filter!" neq "0" set "kp=-kp"
set "psize1=%~z1"
pngout -s3 -k1 "%~f1"
set "psize2=%~z1"
if !psize1! neq !psize2! (for /l %%j in (1,1,8) do pngout -s3 -k1 -n%%j "%~f1") else (pngout -s0 -f6 -k1 -ks !kp! "%~f1")
advdef -z4 "%~f1"
exit /b

:Non-interlaced-Advanced
truepng -i0 -zc9 -zm8-9 -zs0-1 -f0,5 -fs:7 %nc% %na% -force "%~f1"
advdef -z4 "%~f1"
exit /b

:Interlaced-Xtreme
truepng -i1 -zc8-9 -zm3-9 -zs0-3 -fe -fs:7 %nc% %na% -force "%~f1"
advdef -z4 "%~f1"
exit /b

:Interlaced-Advanced
truepng -i1 -zc9 -zm8-9 -zs0-1 -f0,5 -fs:7 %nc% %na% -force "%~f1"
advdef -z4 "%~f1"
exit /b
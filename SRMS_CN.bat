@ECHO OFF
CHCP 65001 > NUL
:: File name:	SRMS
:: Author:		elpsy
:: Version:		1.0.0
:: Date:		20230423
:: Description	利用原有的星铁资源文件在指定位置创建文件/文件夹映射，适用于天空岛服、世界树服和国际服

CD /D %~DP0 & TITLE SRMS-星铁多服创建工具
SETLOCAL ENABLEDELAYEDEXPANSION
SET "logDate=%DATE:~3,4%%DATE:~8,2%%DATE:~11,2%"
SET "logTime=%TIME:~0,8%"
SET /A "successCount=0"

SET "oldGamePath=0"
SET "oldDataPath=0"
SET "oldDataType=0"
SET "oldServerName=0"
SET "oldGameName=0"
SET "oldGameType=0"

SET "newGamePath=0"
SET "newDataPath=0"
SET "newDataType=0"
SET "newServerName=0"
SET "newGameName=0"
SET "newGameType=0"
SET "newPath=0"

SET "gameVersion=0"
SET "resourceName=0"
SET "channel=0"
SET "plugin_sdk_version=0"

:GET_PRIVILEGES
::Get system administrator privileges
IF EXIST "%SystemRoot%\SysWOW64" PATH %PATH%;%windir%\SysNative;%SystemRoot%\SysWOW64;%~dp0
BCDEDIT >NUL
IF ERRORLEVEL 1 (GOTO UACPROMPT) ELSE (GOTO UACADMIN)
:UACPROMPT
%1 START "" MSHTA VBSCRIPT:CREATEOBJECT("SHELL.APPLICATION").SHELLEXECUTE("""%~0""","::",,"RUNAS",1)(WINDOW.CLOSE)&EXIT
EXIT /B
:UACADMIN
CD /D "%~DP0"
ECHO;&ECHO 管理员权限已获取，当前运行路径是: %CD%
IF NOT EXIST "log" MKDIR "log"
ECHO [%logTime%] INFO: Get system administrator privileges 1. >>log\log_%logDate%.log

ECHO [%logTime%] INFO: The processor architecture is: %PROCESSOR_ARCHITECTURE%.>>log\log_%logDate%.log
FOR /F "SKIP=1 TOKENS=1 DELIMS==" %%i IN ('VER') DO (
	SET "OSVersion=%%i"
)
ECHO [%logTime%] INFO: The OS version is: %OSVersion%.>>log\log_%logDate%.log

CALL :INITIALIZATION
::Check successCount
ECHO %successCount%|FINDSTR "^[1-9][0-9]*$" > NUL
IF ERRORLEVEL 1	(
	ECHO;&ECHO 检测到这是第一次运行本软件！
	ECHO [%logTime%] INFO: May be the first time to execute. >>log\log_%logDate%.log 
	rem CALL :GET_OLDPATH_REG
	CALL :INPUT_OLDGAMEPATH
) ELSE (
	ECHO;&ECHO 检测到曾经成功创建过星铁服务器！
	ECHO [%logTime%] INFO: Executed successfully in the past. >>log\log_%logDate%.log
)

CALL :CHOOSE_SERVER
IF "%newGameType%"=="%oldGameType%" (
	CALL :LAND_TREE
) ELSE (
	pause
	CALL :CN_SEA
)

CALL :UPDATECFG
CALL :CREATE_SHORTCUT
ECHO PAUSE>>log\manual.txt
ECHO;&ECHO 服务器创建完成，按任意键退出！
PAUSE>NUL & EXIT

:INITIALIZATION
ECHO CD /D %~DP0>log\manual.txt
ECHO CHCP 65001>>log\manual.txt
::Read cfg.ini
IF EXIST "cfg\cfg.ini" (
	FOR /F "TOKENS=1,2 DELIMS==" %%i IN (cfg\cfg.ini) DO (
		SET "%%i=%%j"
		IF ERRORLEVEL 1 (
			ECHO [%logTime%] ERROR: Failed to read config.ini. >>log\log_%logDate%.log
			CALL :FAILED_BREAK
		)
	)
) ELSE (
	ECHO [%logTime%] ERROR: Cfg.ini not found. >>log\log_%logDate%.log
	CALL :FAILED_BREAK
)
ECHO;&ECHO 正在读取配置文件...
(
	ECHO [%logTime%] INFO: Cfg.ini start to read:
	ECHO gameVersion=%gameVersion%
	ECHO landServerStatus=%landServerStatus%
	ECHO treeServerStatus=%treeServerStatus%
	ECHO seaServerStatus=%seaServerStatus%
	ECHO oldGamePath=%oldGamePath%
	ECHO oldServerName=%oldServerName%
	ECHO oldDataType=%oldDataType%
	ECHO newPath=%newPath%
	ECHO successCount=%successCount%
	ECHO [%logTime%] INFO: Cfg.ini end reading.
)>>log\log_%logDate%.log
GOTO :EOF

:GET_OLDPATH_REG
SET "userErrorLevel=1"
FOR /F "SKIP=2 TOKENS=1,2 DELIMS=:" %%i IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\崩坏：星穹铁道" /V "InstallPath"') DO (
	SET "value1=%%i"
	SET "value2=%%j"
	SET "userErrorLevel=0"
	SET "oldCNRegPath=!value1:~-1!:!value2!"
	SET "oldCNRegGamePath=!oldCNRegPath!\Game"
)
IF %userErrorLevel%==0 (
	IF EXIST "%oldCNRegGamePath%\StarRail.exe" (
		SET "CNRegStatus=1"
		ECHO [%logTime%] DEBUG: CNRegStatus=!CNRegStatus! >>log\log_%logDate%.log
		ECHO [%logTime%] INFO: CNserver client installation path in regedit exists:"%oldCNRegGamePath%". >>log\log_%logDate%.log
	) ELSE (
		SET "CNRegStatus=0"
		ECHO [%logTime%] DEBUG: CNRegStatus=!CNRegStatus! >>log\log_%logDate%.log
		ECHO [%logTime%] WARNING: CNserver client installation path in regedit NOT exists:"%oldCNRegGamePath%". >>log\log_%logDate%.log
	)
) ELSE (
	SET "CNRegStatus=0"
	ECHO [%logTime%] DEBUG: CNRegStatus=!CNRegStatus! >>log\log_%logDate%.log
	ECHO [%logTime%] WARNING: Failed to read CNserver client installation path from regedit. >>log\log_%logDate%.log
)
SET "userErrorLevel=1"
FOR /F "SKIP=2 TOKENS=1,2 DELIMS=:" %%i IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Star Rail" /V "InstallPath"') DO (
	SET "value1=%%i"
	SET "value2=%%j"
	SET "userErrorLevel=0"
	SET "oldSeaRegPath=!value1:~-1!:!value2!"
	SET "oldSeaRegGamePath=!oldSeaRegPath!\Games"
)
IF %userErrorLevel%==0 (
	IF EXIST "%oldSeaRegGamePath%\StarRail.exe" (
		SET "seaRegStatus=1"
		ECHO [%logTime%] DEBUG: seaRegStatus=!seaRegStatus! >>log\log_%logDate%.log
		ECHO [%logTime%] INFO: Seaserver client installation path in regedit exists:"%oldSeaRegGamePath%". >>log\log_%logDate%.log
	) ELSE (
		SET "seaRegStatus=0"
		ECHO [%logTime%] DEBUG: seaRegStatus=!seaRegStatus! >>log\log_%logDate%.log
		ECHO [%logTime%] WARNING: Seaserver client installation path in regedit NOT exists:"%oldSeaRegGamePath%". >>log\log_%logDate%.log
	)
) ELSE (
	SET "seaRegStatus=0"
	ECHO [%logTime%] DEBUG: seaRegStatus=!seaRegStatus! >>log\log_%logDate%.log
	ECHO [%logTime%] WARNING: Failed to read seaserver client installation path from regedit. >>log\log_%logDate%.log
)
IF %seaRegStatus%==1 (
	IF %CNRegStatus%==1 (
		SET "oldGamePath=%oldCNRegGamePath%"
		ECHO [%logTime%] DEBUG: oldGamePath=!oldGamePath! >>log\log_%logDate%.log
		CALL :JUDGE_SERVER_TYPE
	) ELSE (
		SET "oldGamePath=%oldSeaRegGamePath%"
		ECHO [%logTime%] DEBUG: oldGamePath=!oldGamePath! >>log\log_%logDate%.log
		CALL :JUDGE_SERVER_TYPE
	)
) ELSE (
	IF %CNRegStatus%==1 (
		SET "oldGamePath=%oldCNRegGamePath%"
		ECHO [%logTime%] DEBUG: oldGamePath=!oldGamePath! >>log\log_%logDate%.log
		CALL :JUDGE_SERVER_TYPE
	) ELSE (
		CALL :INPUT_OLDGAMEPATH
	)
)
GOTO :EOF

:INPUT_OLDGAMEPATH
ECHO;&ECHO _______________________________________________________________
ECHO;&ECHO 请输入游戏安装路径: 点击鼠标右键粘贴在此处，按Enter键即可:
ECHO;&SET /P "oldGamePath=游戏安装路径为: "
IF EXIST "%oldGamePath%\StarRail.exe" (
	ECHO;&ECHO 输入的游戏安装路径存在，请继续..
	ECHO [%logTime%] INFO: OldGamePath exists: %oldGamePath%. >>log\log_%logDate%.log
) ELSE (
	ECHO;&ECHO 输入的游戏安装路径不存在，请检查并重新输入.
	GOTO INPUT_OLDGAMEPATH
)
CALL :JUDGE_SERVER_TYPE
GOTO :EOF

:READ_CONFIG_INI
CD /D "%oldGamePath%"
FOR /F "TOKENS=1,2 DELIMS==" %%i IN (config.ini) DO (
	SET "%%i=%%j"
	IF ERRORLEVEL 1 (
		ECHO [%logTime%] ERROR: Failed to read config.ini. >>%~DP0log\log_%logDate%.log
		CALL :FAILED_BREAK
	)
)
CD /D %~DP0
(
	ECHO [%logTime%] INFO: Config.ini start to read:
	ECHO channel=%channel%
	ECHO cps=%cps%
	ECHO game_version=%game_version%
	ECHO sub_channel=%sub_channel%
	ECHO [%logTime%] INFO: Config.ini end reading.
)>>log\log_%logDate%.log

SET "gameVersion=%game_version%"

rem IF NOT "%game_version%"=="%gameVersion%" (
rem 	ECHO The game version has expired, please update the game.
rem 	CALL :FAILED_BREAK
rem )
GOTO :EOF

:JUDGE_SERVER_TYPE
CALL :READ_CONFIG_INI
IF EXIST "%oldGamePath%\..\Games" (
	SET "oldServerName=Seaserver"
	SET "oldDataType=StarRail_Data"
	SET "oldGameType=Sea"
	SET /A "seaServerStatus=1"
	ECHO;&ECHO 检测到原始星铁服务器为国际服
	ECHO [%logTime%] INFO: Seaserver detected. >>log\log_%logDate%.log
) ELSE (
	IF EXIST "%oldGamePath%\..\Game" (
		IF %channel%==1 (
			SET "oldServerName=Landserver"
			SET "oldDataType=StarRail_Data"
			SET "oldGameType=CN"
			SET /A "landServerStatus=1"
			ECHO;&ECHO 检测到原始星铁服务器为官服
			ECHO [%logTime%] INFO: Landserver detected. >>log\log_%logDate%.log
		) ELSE (
			IF %channel%==14 (
				SET "oldServerName=Treeserver"
				SET "oldDataType=StarRail_Data"
				SET "oldGameType=CN"
				SET /A "treeServerStatus=1"
				ECHO;&ECHO 检测到原始星铁服务器为b服
				ECHO [%logTime%] INFO: Treeserver detected. >>log\log_%logDate%.log
			) ELSE (
				ECHO;&ECHO Config.ini内容错误.
				ECHO [%logTime%] ERROR: Config.ini error. >>log\log_%logDate%.log
				CALL :FAILED_BREAK
			)
		)
	)
)
GOTO :EOF

:CHOOSE_SERVER
::Choose new server type
SET /A "newServerStatus=0"
ECHO;&ECHO 原始游戏安装路径为"%oldGamePath%"
FOR %%I in ("%oldGamePath%") DO SET "newGameDrive=%%~dI"
CHKNTFS %newGameDrive% | find /I "NTFS" >NUL 2>NUL
IF ERRORLEVEL 1 (
	ECHO;&ECHO %newGameDrive% 不是NTFS格式
	rem SRMS工具不适用，请使用SRSS工具，按Enter键确认。
	ECHO [%logTime%] ERROR: %newGameDrive% is not NTFS. >>log\log_%logDate%.log
	set "newGameDrive=C:"
	rem PAUSE & CALL SRCS.bat
	rem EXIT
) ELSE (
	ECHO;&ECHO %newGameDrive% 是NTFS格式。
	ECHO [%logTime%] INFO: %newGameDrive% is NTFS. >>log\log_%logDate%.log
)
SET "newPath=%newGameDrive%\StarRailNew"
IF NOT EXIST "%newPath%" (
	MD "%newPath%"
	ECHO MD "%newPath%">>log\manual.txt
)
ECHO;&ECHO 新游戏路径默认为: "%newPath%"
ECHO [%logTime%] DEBUG: newPath=%newPath%. >>log\log_%logDate%.log
REM ECHO;&ECHO _______________________________________________________________
ECHO;&ECHO 请选择你想创建的星铁服务器类型:
ECHO;&ECHO 1.星铁官服（ID以1、2开头）
ECHO;&ECHO 2.星铁b服（ID以5开头）
ECHO;&ECHO 3.星铁国际服（ID以6、7、8、9开头）

:INPUT_SERVER
ECHO;&ECHO _______________________________________________________________
ECHO;&SET /P "newServerNum=请输入数字1、2或3，按Enter键继续: "

IF "%newServerNum%"=="1" (
	SET "newServerName=Landserver"
	SET "newServerStatus=%landServerStatus%"
	SET "newGameType=CN"
) ELSE (
	IF "%newServerNum%"=="2" (
		SET "newServerName=Treeserver"
		SET "newServerStatus=%treeServerStatus%"
		SET "newGameType=CN"
	) ELSE (
		IF "%newServerNum%"=="3" (
			SET "newServerName=Seaserver"
			SET "newServerStatus=%seaServerStatus%"
			SET "newGameType=Sea"
		) ELSE (
			ECHO;&ECHO 输入非法，请重新输入！
			GOTO INPUT_SERVER
		)
	)
)
ECHO [%logTime%] DEBUG: newServerStatus=%newServerStatus% >>log\log_%logDate%.log
IF %newServerStatus%==1 (
	ECHO;&ECHO 此服务器已存在，请选择其他服！
	GOTO INPUT_SERVER
) ELSE (
	IF "%newServerName%"=="%oldServerName%" (
		ECHO;&ECHO 此服务器已存在，请选择其他服！
		GOTO INPUT_SERVER
	) ELSE (
		ECHO;&ECHO 等待进行服务器创建！
	)
)
IF "%newServerName%"=="Seaserver" (
	SET "resourceName=SeaRes_"
	SET "newDataType=StarRail_Data"
	SET "newGameName=StarRail.exe"
) ELSE (
	SET "resourceName=CNRes_"
	SET "newDataType=StarRail_Data"
	SET "newGameName=StarRail.exe"
)
SET "oldDataPath=%oldGamePath%\%oldDataType%"
SET "newGamePath=%newPath%\%newServerName%"
SET "newDataPath=%newPath%\%newServerName%\%newDataType%"

ECHO [%logTime%] INFO: New server: %newServerName%.>>log\log_%logDate%.log
ECHO [%logTime%] DEBUG: oldDataPath=%oldDataPath%>>log\log_%logDate%.log
ECHO [%logTime%] DEBUG: newGamePath=%newGamePath%>>log\log_%logDate%.log
ECHO [%logTime%] DEBUG: newDataPath=%newDataPath%>>log\log_%logDate%.log

IF NOT EXIST "%newGamePath%" (
	MD "%newGamePath%"
	ECHO MD "%newGamePath%">>log\manual.txt
)
IF NOT EXIST "%newDataPath%" (
	MD "%newDataPath%"
	ECHO MD "%newDataPath%">>log\manual.txt
)
GOTO :EOF

:CN_SEA
::Detect the resource in this folder (for CN to sea)
IF NOT EXIST "%~DP0%resourceName%V%gameVersion%" (
	ECHO;&ECHO 请确认已下载"%resourceName%V%gameVersion%.exe"，按Enter键继续: 
	PAUSE >NUL
	IF NOT EXIST "%resourceName%V%gameVersion%.exe" (
		ECHO;&ECHO 未检测到"%resourceName%V%gameVersion%.exe"，请重新下载！
		GOTO CN_SEA
	) 
	ECHO;&ECHO 请将"%resourceName%V%gameVersion%.exe"解压至本文件夹，即直接在弹出的对话框中按确定即可。
	"%resourceName%V%gameVersion%.exe"
)
XCOPY /E /Y "%resourceName%V%gameVersion%\" "%newGamePath%">NUL
ECHO XCOPY /E /Y "%resourceName%V%gameVersion%\" "%newGamePath%">>log\manual.txt
ECHO;&ECHO 正在将资源文件复制到新游戏路径..
IF ERRORLEVEL 1 (
	ECHO;&ECHO 资源文件复制失败！
	ECHO [%logTime%] DEBUG: ERRORLEVEL=%ERRORLEVEL%>>log\log_%logDate%.log
	ECHO [%logTime%] DEBUG: XCOPY /E /Y "%resourceName%V%gameVersion%\" "%newGamePath%">>log\log_%logDate%.log
	ECHO [%logTime%] ERROR: Failed to copy resources. >>log\log_%logDate%.log
	CALL :FAILED_BREAK
) ELSE (
	ECHO [%logTime%] INFO: Copy resources successfully. >>log\log_%logDate%.log
)
CALL :COPY_TREESDK
::Make link (for CN to sea)
ECHO;&ECHO 开始创建链接...
FOR /F "EOL=# DELIMS==" %%i IN (cfg\listdir_cn_sea.ini) DO (
	IF NOT EXIST "%oldDataPath%\%%i" (
		ECHO [%logTime%] ERROR: Folder to link not exists: %oldDataPath%\%%i. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
	)
	IF NOT EXIST "%newDataPath%\%%i" (
		MKLINK /D "%newDataPath%\%%i" "%oldDataPath%\%%i" >NUL
		ECHO MKLINK /D "%newDataPath%\%%i" "%oldDataPath%\%%i">>log\manual.txt
		IF ERRORLEVEL 1 (
			ECHO [%logTime%] ERROR: Folder linked unsuccessfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
			CALL :FAILED_BREAK
		) ELSE (
			ECHO [%logTime%] INFO: Folder linked successfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
		)
	) ELSE (
		ECHO [%logTime%] WARNING: Folder link exists: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
	)
)
FOR /F "eol=# delims==" %%i in (cfg\listfile_cn_sea.ini) do (
	IF NOT EXIST "%oldDataPath%\%%i" (
		ECHO [%logTime%] ERROR: File to link not exists: %oldDataPath%\%%i. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
	)
	IF NOT EXIST "%newDataPath%\%%i" (
		MKLINK "%newDataPath%\%%i" "%oldDataPath%\%%i">NUL
		ECHO MKLINK "%newDataPath%\%%i" "%oldDataPath%\%%i">>log\manual.txt
		IF ERRORLEVEL 1 (
			ECHO [%logTime%] ERROR: File linked unsuccessfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
			CALL :FAILED_BREAK
		) ELSE (
			ECHO [%logTime%] INFO: File linked successfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
		)
	) ELSE (
		ECHO [%logTime%] WARNING: File link exists: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
	)
)
GOTO :EOF

:LAND_TREE
::check newServerName is treeserver or not (for land to tree)
IF "%newServerName%"=="Treeserver" (
	::Copy PCGameSDK.dll for treeserver (for land to tree)
	IF NOT EXIST "%newDataPath%" (
		MD "%newDataPath%"
		ECHO MD "%newDataPath%">>log\manual.txt
	)
	IF NOT EXIST "%newDataPath%\Plugins" (
		MD "%newDataPath%\Plugins"
		ECHO MD "%newDataPath%\Plugins">>log\manual.txt
	)
	CALL :COPY_TREESDK
)
::Copy listfile_gamecn files (for land to tree)
ECHO [%logTime%] INFO: Start to copy files according to listfile_gamecn. >>log\log_%logDate%.log
XCOPY /E /Y "%oldGamePath%\AntiCheatExpert\" "%newGamePath%\AntiCheatExpert\">NUL
ECHO XCOPY /Y "%oldGamePath%\AntiCheatExpert\" "%newGamePath%\AntiCheatExpert\">>log\manual.txt
IF ERRORLEVEL 1 (
		ECHO [%logTime%] DEBUG: ERRORLEVEL=%ERRORLEVEL%>>log\log_%logDate%.log
		ECHO [%logTime%] DEBUG: XCOPY /Y "%oldGamePath%\AntiCheatExpert\" "%newGamePath%\AntiCheatExpert\">>log\log_%logDate%.log
		ECHO [%logTime%] ERROR: Failed to copy folder: AntiCheatExpert. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
) ELSE (
	ECHO [%logTime%] INFO: Copy AntiCheatExpert successfully. >>log\log_%logDate%.log
)
FOR /F "eol=#" %%i in (cfg\listfile_gamecn.ini) do (
	COPY /Y "%oldGamePath%\%%i" "%newGamePath%\%%i">NUL
	ECHO COPY /Y "%oldGamePath%\%%i" "%newGamePath%\%%i">>log\manual.txt
	IF ERRORLEVEL 1 (
		ECHO [%logTime%] DEBUG: ERRORLEVEL=%ERRORLEVEL%>>log\log_%logDate%.log
		ECHO [%logTime%] DEBUG: COPY /Y "%oldGamePath%\%%i" "%newGamePath%\%%i">>log\log_%logDate%.log
		ECHO [%logTime%] ERROR: Failed to copy file: %%i. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
	) ELSE (
		ECHO [%logTime%] INFO: Copy file successfully: %%i. >>log\log_%logDate%.log
	)
)
ECHO [%logTime%] INFO: End copying listfile_gamecn. >>log\log_%logDate%.log
::Make directory list and make link (for land to tree)
ECHO;&ECHO Start creating links...
FOR /F "EOL=# DELIMS==" %%i IN (cfg\listdir_land_tree.ini) DO (
	IF NOT EXIST "%oldDataPath%\%%i" (
		ECHO [%logTime%] ERROR: Folder to link not exists: %oldDataPath%\%%i. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
	)
	IF NOT EXIST "%newDataPath%\%%i" (
		MKLINK /D "%newDataPath%\%%i" "%oldDataPath%\%%i" >NUL
		ECHO MKLINK /D "%newDataPath%\%%i" "%oldDataPath%\%%i">>log\manual.txt
		IF ERRORLEVEL 1 (
			ECHO [%logTime%] ERROR: Folder linked unsuccessfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
			CALL :FAILED_BREAK
		) ELSE (
			ECHO [%logTime%] INFO: Folder linked successfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
		)
	) ELSE (
		ECHO [%logTime%] WARNING: Folder link exists: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
	)
)
FOR /F "eol=# delims==" %%i in (cfg\listfile_land_tree.ini) do (
	IF NOT EXIST "%oldDataPath%\%%i" (
		ECHO [%logTime%] ERROR: File to link not exists: %oldDataPath%\%%i. >>log\log_%logDate%.log
		CALL :FAILED_BREAK
	)
	IF NOT EXIST "%newDataPath%\%%i" (
		MKLINK "%newDataPath%\%%i" "%oldDataPath%\%%i">NUL
		ECHO MKLINK "%newDataPath%\%%i" "%oldDataPath%\%%i">>log\manual.txt
		IF ERRORLEVEL 1 (
			ECHO [%logTime%] ERROR: File linked unsuccessfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
			CALL :FAILED_BREAK
		) ELSE (
			ECHO [%logTime%] INFO: File linked successfully: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
		)
	) ELSE (
		ECHO [%logTime%] WARNING: File link exists: %newDataPath%\%%i %oldDataPath%\%%i. >>log\log_%logDate%.log
	)
)
GOTO :EOF

:COPY_TREESDK
::Copy PCGameSDK.dll for treeserver (for CN to sea)
IF "%newServerName%"=="Treeserver" (
	IF NOT EXIST "PCGameSDK.dll" (
		ECHO;&ECHO 请确认已下载"PCGameSDK.dll"，按Enter键继续: 
		PAUSE >NUL
		IF NOT EXIST "PCGameSDK.dll" (
			ECHO;&ECHO 未检测到"PCGameSDK.dll"，请重新下载！
			GOTO COPY_TREESDK
		)
	)
	COPY /Y "PCGameSDK.dll" "%newDataPath%\Plugins\PCGameSDK.dll">NUL
	ECHO COPY /Y "PCGameSDK.dll" "%newDataPath%\Plugins\PCGameSDK.dll">>log\manual.txt
	ECHO;&ECHO 正在复制PCGameSDK.dll到新路径...
	IF ERRORLEVEL 1 (
		ECHO [%logTime%] DEBUG: ERRORLEVEL=%ERRORLEVEL%>>log\log_%logDate%.log
		ECHO [%logTime%] ERROR: Fail to copy PCGameSDK.dll. >>log\log_%logDate%.log
		ECHO [%logTime%] DEBUG: COPY /Y "PCGameSDK.dll" "%newDataPath%\Plugins\PCGameSDK.dll">>log\log_%logDate%.log
		CALL :FAILED_BREAK
	) ELSE (
		ECHO [%logTime%] INFO: Copy PCGameSDK.dll successfully. >>log\log_%logDate%.log
	)
)
GOTO :EOF

:UPDATECFG
::Update data in cfg.ini
IF %newServerName%==Landserver (
	SET /A "landServerStatus=1"
	SET "shortcutName=星铁官服"
	SET "channel=1"
	SET "cps=gw_PC"
	SET "sub_channel=1"
) ELSE (
	IF %newServerName%==Treeserver (
		SET /A "treeServerStatus=1"
		SET "shortcutName=星铁b服"
		SET "channel=14"
		SET "cps=bilibili_PC"
		SET "sub_channel=0"
	) ELSE (
		IF %newServerName%==Seaserver (
			SET /A "seaServerStatus=1"
			SET "shortcutName=星铁国际服"
			SET "channel=1"
			SET "cps=hoyoverse_PC"
			SET "sub_channel=1"
		)
	)
)
CD /D %~DP0
ECHO [%logTime%] INFO: Config.ini start to update:>>log\log_%logDate%.log
(
	ECHO [General]
	ECHO channel=%channel%
	ECHO cps=%cps%
	ECHO game_version=%gameVersion%
	ECHO plugin_sdk_version=3.5.0
	ECHO sub_channel=%sub_channel%
)>"%newGamePath%\config.ini"
ECHO [%logTime%] INFO: Config.ini end updating.>>log\log_%logDate%.log
SET /A "successCount+=1"
ECHO [%logTime%] INFO: Cfg.ini start to update: >>log\log_%logDate%.log
(
	ECHO gameVersion=%gameVersion%
	ECHO landServerStatus=%landServerStatus%
	ECHO treeServerStatus=%treeServerStatus%
	ECHO seaServerStatus=%seaServerStatus%
	ECHO oldGamePath=%oldGamePath%
	ECHO oldServerName=%oldServerName%
	ECHO oldDataType=%oldDataType%
	ECHO newPath=%newPath%
	ECHO successCount=%successCount%
)>cfg\cfg.ini
ECHO [%logTime%] INFO: Cfg.ini end updating.>>log\log_%logDate%.log
GOTO :EOF

:CREATE_SHORTCUT
::Create desktop shortcut
mshta VBScript:Execute("Set a=CreateObject(""WScript.Shell""):Set b=a.CreateShortcut(a.SpecialFolders(""Desktop"") & ""\%shortcutName%.lnk""):b.TargetPath=""%newGamePath%\%newGameName%"":b.WorkingDirectory=""%newGamePath%"":b.Save:close")
ECHO [%logTime%] INFO: StarRail server create successfully. >>log\log_%logDate%.log
GOTO :EOF

:FAILED_BREAK
::This is failed break
ECHO;&ECHO 创建服务器失败，按任意键退出！
ECHO [%logTime%] ERROR: This is failed break. >>log\log_%logDate%.log
PAUSE>NUL && EXIT
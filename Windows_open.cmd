<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v40
@echo off
:: ### 配置选项 ###

:: 更改参数为 1 以启用调试模式
set _Debug=0

:: 更改参数为 0 以通过脚本关闭 Windows 或 Office 激活处理
set ActWindows=1
set ActOffice=1

:: 更改参数为 0 关闭 Office C2R 零售版转为批量版
set AutoR2V=1

:: 更改参数为 0 以将 Windows 10 KMS38 还原为普通 KMS
set SkipKMS38=1

:: ### 无人值守选项 ###

:: 更改参数为 1 并设置 KMS_IP 地址以通过无人值守的外部 KMS 服务器激活
set External=0
set KMS_IP=0.0.0.0

:: 更改参数为 1 以无人值守方式运行手动激活模式
set uManual=0

:: 更改参数为 1 以无人值守运行自动更新激活模式
set uAutoRenewal=0

:: 更改参数为 1 以限制任何输出
set Silent=0

:: 更改参数为 1 可将输出重定向到文本文件，仅适用于 Silent=1
set Logger=0

:: ### 高级 KMS 选项 ###

:: 更改 KMS 自动续订计划，以分钟为单位的范围: 从 15 分钟到 43200 分钟
:: 例如: 10080 = 每周, 1440 = 每天, 43200 = 每月
set KMS_RenewalInterval=10080

:: 更改 KMS 重新尝试失败激活或未激活的计划，以分钟为单位的范围: 从 15 分钟到 43200 分钟
set KMS_ActivationInterval=120

:: 更改 KMS 模拟服务器的硬件哈希值（仅用于 Windows 8.1和10）
set KMS_HWID=0x3A1C049600B60076

:: 更改 KMS TCP 端口
set KMS_Port=1688

set KMS_Emulation=1
set Unattend=0
set _uIP=%KMS_IP%

set "_cmdf=%~f0"
if defined PROCESSOR_ARCHITEW6432 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

set _args=
set _elev=
set _batf=
set _batp=
set fAUR=
set rAUR=
set _args=%*
if not defined _args goto :NoProgArgs

set _args=%_args:"=%
for %%A in (%_args%) do (
if /i "%%A"=="-elevated" (set _elev=1
) else if /i "%%A"=="/d" (set _Debug=1
) else if /i "%%A"=="/u" (set Unattend=1
) else if /i "%%A"=="/s" (set Silent=1
) else if /i "%%A"=="/l" (set Logger=1
) else if /i "%%A"=="/o" (set ActOffice=1&set ActWindows=0
) else if /i "%%A"=="/w" (set ActOffice=0&set ActWindows=1
) else if /i "%%A"=="/c" (set AutoR2V=0
) else if /i "%%A"=="/x" (set SkipKMS38=0
) else if /i "%%A"=="/e" (set fAUR=0&set External=1&set uManual=0&set uAutoRenewal=0
) else if /i "%%A"=="/m" (set fAUR=0&set External=0&set uAutoRenewal=0
) else if /i "%%A"=="/a" (set fAUR=1&set External=0&set uManual=0
) else if /i "%%A"=="/r" (set rAUR=1
) else (set "KMS_IP=%%A")
)

:NoProgArgs
if %External% EQU 1 (if "%KMS_IP%"=="%_uIP%" (set fAUR=0&set External=0) else (set fAUR=0))
if %uManual% EQU 1 (set fAUR=0&set External=0&set uAutoRenewal=0)
if %uAutoRenewal% EQU 1 (set fAUR=1&set External=0&set uManual=0)
if defined fAUR set Unattend=1
if defined rAUR set Unattend=1
if %Silent% EQU 1 set Unattend=1
set _run=nul
if %Logger% EQU 1 set _run="%~dpn0_Silent.log"

set "SysPath=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" (set "SysPath=%SystemRoot%\Sysnative")
set "Path=%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
set "_err===== 错误 ===="
set "_psc=powershell -nop -c"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=31;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"
set "xOS=x64"
set "xBit=x64"
set "_bit=64"
set "_wow=1"
set "_orig=0ca83cdd18845d77e0775f299a111a0591d86883"
if /i %PROCESSOR_ARCHITECTURE%==x86 (if not defined PROCESSOR_ARCHITEW6432 (
  set "xOS=x86"
  set "xBit=x86"
  set "_bit=32"
  set "_wow=0"
  set "_orig=08266ee7d7aac833e04ca037a5435f0438c6b973"
  )
)

if not exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" goto :E_PS

1>nul 2>nul reg query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" %_args% -elevated
set _PSarg=%_PSarg:'=''%

(1>nul 2>nul cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %_args% -elevated) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  1>nul 2>nul %SysPath%\WindowsPowerShell\v1.0\%_psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
set "_batf=%~f0"
set "_batp=%_batf:'=''%"
set "_temp=%SystemRoot%\Temp"
set "_log=%~dpn0"
set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
set preparedcolor=0
set "_mO21c=Detected Office 2021 C2R Retail could not be converted to Volume"
set "_mO19c=Detected Office 2019 C2R Retail could not be converted to Volume"
set "_mO16c=Detected Office 2016 C2R Retail could not be converted to Volume"
set "_mO15c=Detected Office 2013 C2R Retail could not be converted to Volume"
set "_mO14c=Detected Office 2010 C2R Retail is not supported by KMS_VL_ALL"
set "_mO14m=Detected Office 2010 MSI Retail is not supported by KMS_VL_ALL"
set "_mO15m=Detected Office 2013 MSI Retail is not supported by KMS_VL_ALL"
set "_mO16m=Detected Office 2016 MSI Retail is not supported by KMS_VL_ALL"
set "_mOuwp=Detected Office 365/2016 UWP is not supported by KMS_VL_ALL"
set LV16Ids=Mondo,ProPlus,ProjectPro,VisioPro,Standard,ProjectStd,VisioStd,Access,SkypeforBusiness,OneNote,Excel,Outlook,PowerPoint,Publisher,Word
set LR16Ids=%LV16Ids%,Professional,HomeBusiness,HomeStudent,O365Business,O365SmallBusPrem,O365HomePrem,O365EduCloud
set "ESUEditions=Enterprise,EnterpriseE,EnterpriseN,Professional,ProfessionalE,ProfessionalN,Ultimate,UltimateE,UltimateN"
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
set "ESUEditions=ServerDatacenter,ServerDatacenterCore,ServerDatacenterV,ServerDatacenterVCore,ServerStandard,ServerStandardCore,ServerStandardV,ServerStandardVCore,ServerEnterprise,ServerEnterpriseCore,ServerEnterpriseV,ServerEnterpriseVCore"
)
setlocal EnableDelayedExpansion

if %_Debug% EQU 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  if %Unattend% EQU 1 set "_Pause="
  if %Silent% EQU 0 (call :Begin) else (call :Begin >!_run! 2>&1)
) else (
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause="
  copy /y nul "!_work!\#.rw" 1>nul 2>nul && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
  if exist "!_log!_Debug.log" (
  call set "_suf="
  for /f "tokens=2 delims==." %%# in ('wmic os get localdatetime /value') do set "_date=%%#"
  set "_suf=_!_date:~8,6!"
  )
  if %Silent% EQU 0 (
  echo.
  echo 在调试模式下运行...
  if not defined _args (echo 完成后窗口将关闭) else (echo 请稍候...)
  echo.
  echo 正在写入调试日志:
  echo "!_log!_Debug!_suf!.log"
  )
  @echo on
  @prompt $G
  @call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug!_suf!.log"&del "!_log!_tmp.log"
)
@color 07
@title %ComSpec%
@echo off
@exit /b

:Begin
if %_Debug% EQU 1 (
if defined _args echo %_args%
echo "!_batf!"
)
if exist "%PUBLIC%\ReadMeAIO.html" del /f /q "%PUBLIC%\ReadMeAIO.html"
if exist "%_temp%\'" del /f /q "%_temp%\'"
if exist "%_temp%\`.txt" del /f /q "%_temp%\`.txt"
set _verb=0
set "_wApp=55c92734-d682-4d71-983e-d6ec3f16059f"
set "_oApp=0ff1ce15-a989-479d-af46-f275c6370663"
set "_oA14=59a52881-a989-479d-af46-f275c6370663"
set "IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
set "OPPk=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
set _Hook="%SysPath%\SppExtComObjHook.dll"
set w7inf=%SystemRoot%\Migration\WTR\KMS_VL_ALL.inf
set "_TaskEx=\Microsoft\Windows\SoftwareProtectionPlatform\SvcTrigger"
set "_TaskOs=\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskLogon"
set "line1============================================================="
set "line2=************************************************************"
set "line3=____________________________________________________________"
set "line4=__________________________________________________"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set SSppHook=0
for /f %%A in ('dir /b /ad %SysPath%\spp\tokens\skus') do (
  if %winbuild% GEQ 9200 if exist "%SysPath%\spp\tokens\skus\%%A\*GVLK*.xrm-ms" set SSppHook=1
  if %winbuild% LSS 9200 if exist "%SysPath%\spp\tokens\skus\%%A\*VLKMS*.xrm-ms" set SSppHook=1
  if %winbuild% LSS 9200 if exist "%SysPath%\spp\tokens\skus\%%A\*VL-BYPASS*.xrm-ms" set SSppHook=1
)
set OsppHook=1
sc query osppsvc %_Nul3%
if %errorlevel% EQU 1060 set OsppHook=0

set ESU_KMS=0
if %winbuild% LSS 9200 for /f %%A in ('dir /b /ad %SysPath%\spp\tokens\channels') do (
  if exist "%SysPath%\spp\tokens\channels\%%A\*VL-BYPASS*.xrm-ms" set ESU_KMS=1
)
if %ESU_KMS% EQU 1 (set "adoff=and LicenseDependsOn is NULL"&set "addon=and LicenseDependsOn is not NULL") else (set "adoff="&set "addon=")
set ESU_EDT=0
if %ESU_KMS% EQU 1 for %%A in (%ESUEditions%) do (
  if exist "%SysPath%\spp\tokens\skus\Security-SPP-Component-SKU-%%A\*.xrm-ms" set ESU_EDT=1
)
set ESU_ADD=0

if %winbuild% GEQ 9200 (
  set OSType=Win8
  set SppVer=SppExtComObj.exe
) else if %winbuild% GEQ 7600 (
  set OSType=Win7
  set SppVer=sppsvc.exe
) else (
  goto :UnsupportedVersion
)
if %OSType% EQU Win8 reg query "%IFEO%\sppsvc.exe" %_Nul3% && (
reg delete "%IFEO%\sppsvc.exe" /f %_Nul3%
call :StopService sppsvc
)
set _uRI=%KMS_RenewalInterval%
set _uAI=%KMS_ActivationInterval%
set _dDbg=No
if %ActWindows% EQU 0 if %ActOffice% EQU 0 set ActWindows=1
if %_Debug% EQU 1 if not defined fAUR set fAUR=0&set External=0
if %Unattend% EQU 1 if not defined fAUR set fAUR=0&set External=0
if not defined fAUR if not defined rAUR goto :MainMenu
if defined rAUR (set _verb=1&cls&call :RemoveHook&goto :cCache)
set Unattend=1
set AUR=0
if exist %_Hook% dir /b /al %_Hook% %_Nul3% || (
  reg query "%IFEO%\%SppVer%" /v KMS_Emulation %_Nul3% && set AUR=1
  reg query "%IFEO%\osppsvc.exe" /v KMS_Emulation %_Nul3% && set AUR=1
)
if %fAUR% EQU 1 (if %AUR% EQU 0 (set AUR=1&set _verb=1&set _rtr=DoActivate&cls&goto :InstallHook) else (set _verb=0&set _rtr=DoActivate&cls&goto :InstallHook))
if %External% EQU 0 (set AUR=0&cls&goto :DoActivate)
cls&goto :DoActivate

:MainMenu
cls
mode con cols=80 lines=32
color 07
set "_title=KMS_VL_ALL_AIO %uivr%"
title %_title%
set _dMode=手动
set AUR=0
if exist %_Hook% dir /b /al %_Hook% %_Nul3% || (
  reg query "%IFEO%\%SppVer%" /v KMS_Emulation %_Nul3% && (set AUR=1&set "_dMode=自动续期")
  reg query "%IFEO%\osppsvc.exe" /v KMS_Emulation %_Nul3% && (set AUR=1&set "_dMode=自动续期")
)
if %AUR% EQU 0 (set "_dHook=没有添加") else (set "_dHook=已经添加")
if %ActWindows% EQU 0 (set _dAwin=没有激活) else (set _dAwin=已经激活)
if %ActOffice% EQU 0 (set _dAoff=没有激活) else (set _dAoff=已经激活)
if %AutoR2V% EQU 0 (set _dArtv=不去转换) else (set _dArtv=默认转换)
if %SkipKMS38% EQU 0 (set _dWXKMS=已经跳过) else (set _dWXKMS=支持激活)
if %_Debug% EQU 0 (set _dDbg=未启用) else (set _dDbg=已启用)
set _el=
set _quit=
if %preparedcolor%==0 call :colorprep
if %winbuild% LSS 10586 (
pushd %_temp%
if not exist "'" (<nul >"'" set /p "=.")
)
echo.
echo           %line3%
echo.
if %AUR% EQU 1 (           
rem echo                [1] 激  活 [%_dMode% 模式]
call :Cfgbg %_cWht% "               [1] 激活" %_cGrn% "[%_dMode% 模式]"
) else (
call :Cfgbg %_cWht% "               [1] 激活" %_cBlu% "[%_dMode% 模式]"
)
echo.
if %AUR% EQU 1 (           
call :Cfgbg %_cWht% "               [2] 添加自动续期计划任务 " %_cGrn% "[%_dHook%]"
) else (
echo                [2] 添加自动续期计划任务
)
echo                [3] 完全清除续期计划任务
echo                %line4%
echo.
echo                    配置选项:
echo.
if %_dDbg%==No (           
echo                [4] 调试模式          [%_dDbg%]
) else (
call :Cfgbg %_cWht% "               [4] 调试模式         " %_cRed% "[%_dDbg%]"
)
if %_dAwin%==Yes (
echo                [5] 激活 Windows         [%_dAwin%]
) else (
call :Cfgbg %_cWht% "               [5] 激活 Windows         " %_cYel% "[%_dAwin%]"
)
if %_dAoff%==Yes (
echo                [6] 激活 Office          [%_dAoff%]
) else (
call :Cfgbg %_cWht% "               [6] 激活 Office          " %_cYel% "[%_dAoff%]"
)
if %_dArtv%==Yes (
echo                [7] Office零售版转换批量许可版  [%_dArtv%]
) else (
call :Cfgbg %_cWht% "               [7] Office零售版转换批量许可版  " %_cYel% "[%_dArtv%]"
)
if %winbuild% GEQ 10240 (
if %_dWXKMS%==Yes (
echo                [X] 跳过 KMS38 激活 Windows 10    [%_dWXKMS%]
) else (
call :Cfgbg %_cWht% "               [X] 跳过 KMS38 激活 Windows 10  " %_cYel% "[%_dWXKMS%]"
))
echo                %line4%
echo.
echo                    其它选项:
echo.
echo                [8] 检查激活状态 [vbs]
echo                [9] 检查激活状态 [wmic]
echo                [E] 自定义KMS服务器
echo           %line3%
echo.
if %winbuild% LSS 10586 (
popd
)
choice /c 1234567890ERSX /n /m ">           菜单选项（敲0退出）"
set _el=%errorlevel%
if %_el%==14 if %winbuild% GEQ 10240 (if %SkipKMS38% EQU 0 (set SkipKMS38=1) else (set SkipKMS38=0))&goto :MainMenu
if %_el%==13 (call :CreateOEM)&goto :MainMenu
if %_el%==12 (call :CreateReadMe)&goto :MainMenu
if %_el%==11 goto :E_IP
if %_el%==10 (set _quit=1&goto :TheEnd)
if %_el%==9 (call :casWm)&goto :MainMenu
if %_el%==8 (call :casVm)&goto :MainMenu
if %_el%==7 (if %AutoR2V% EQU 0 (set AutoR2V=1) else (set AutoR2V=0))&goto :MainMenu
if %_el%==6 (if %ActOffice% EQU 0 (set ActOffice=1) else (set ActWindows=1&set ActOffice=0))&goto :MainMenu
if %_el%==5 (if %ActWindows% EQU 0 (set ActWindows=1) else (set ActWindows=0&set ActOffice=1))&goto :MainMenu
if %_el%==4 (if %_Debug% EQU 0 (set _Debug=1) else (set _Debug=0))&goto :MainMenu
if %_el%==3 (if %_dDbg%==No (set _verb=1&cls&call :RemoveHook&goto :cCache) else (set _verb=1&cls&goto :RemoveHook))
if %_el%==2 (if %AUR% EQU 0 (set AUR=1&set _verb=1&set _rtr=DoActivate&cls&goto :InstallHook) else (set _verb=0&set _rtr=DoActivate&cls&goto :InstallHook))
if %_el%==1 (cls&goto :DoActivate)
goto :MainMenu

:colorprep
set preparedcolor=1

if %winbuild% GEQ 10586 (
for /f "tokens=1,2 delims=#" %%A in ('"prompt #$H#$E# & echo on & for %%B in (1) do rem"') do set _EC=%%B

set "_cBlu="44;97m""
set "_cRed="40;91m""
set "_cGrn="40;92m""
set "_cYel="40;93m""
set "_cWht="40;37m""
exit /b
)

for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"

set "_cBlu="1F""
set "_cRed="0C""
set "_cGrn="0A""
set "_cYel="0E""
set "_cWht="07""
exit /b

:Cfgbg
if %winbuild% GEQ 10586 (
echo %_EC%[%~1%~2%_EC%[%~3%~4%_EC%[0m
exit /b
)
setlocal
set "s=%~2"
set "t=%~4"
call :Pfgbg %1 s %3 t
exit /b

:Pfgbg
setlocal EnableDelayedExpansion
set "s=!%~2!"
set "t=!%~4!"
for /f delims^=^ eol^= %%i in ("!s!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~1 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
setlocal EnableDelayedExpansion
for /f delims^=^ eol^= %%i in ("!t!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~3 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
echo(
exit /b

:E_IP
cls
set kip=
echo.
echo 输入/粘贴自定义KMS服务器地址，然后按回车键确定：
echo.
set /p kip=
if not defined kip goto :MainMenu
set "kip=%kip: =%"
set "KMS_IP=%kip%"
set External=1
cls

:DoActivate
if %_dDbg%==Yes (
set "_para=/d"
if %ActWindows% EQU 0 set "_para=!_para! /o"
if %ActOffice% EQU 0 set "_para=!_para! /w"
if %SkipKMS38% EQU 0 set "_para=!_para! /x"
if %External% EQU 1 set "_para=!_para! /e %KMS_IP%"
if %External% EQU 0 if %AUR% EQU 0 set "_para=!_para! /m"
if %External% EQU 0 if %AUR% EQU 1 set "_para=!_para! /a"
goto :DoDebug
)
if %External% EQU 1 (
if "%KMS_IP%"=="%_uIP%" set External=0
)
if %External% EQU 1 (
set AUR=1
)
if %External% EQU 0 (
set KMS_IP=%_uIP%
)
if %AUR% EQU 0 (
set KMS_RenewalInterval=43200
set KMS_ActivationInterval=43200
) else (
set KMS_RenewalInterval=%_uRI%
set KMS_ActivationInterval=%_uAI%
)
if %External% EQU 1 (
color 8F&set "mode=外部工具 ^(%KMS_IP%^)"
) else (
if %AUR% EQU 0 (color 1F&set "mode=手动模式") else (color 07&set "mode=自动续期")
)
if %Unattend% EQU 0 (
if %_Debug% EQU 0 (title %_title%) else (set "_title=KMS_VL_ALL_AIO %uivr% : %mode%"&title KMS_VL_ALL_AIO %uivr% : %mode%)
) else (
echo.
echo Running KMS_VL_ALL_AIO %uivr%
)
if %Silent% EQU 0 if %_Debug% EQU 0 (
%_Nul3% %_psc% "&%_buf%"
if %Unattend% EQU 0 title %_title%
)
if %winbuild% GEQ 9600 (
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /f /v NoGenTicket /t REG_DWORD /d 1 %_Nul3%
  if %winbuild% EQU 14393 reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /f /v NoAcquireGT /t REG_DWORD /d 1 %_Nul3%
)
echo.
echo 激活模式: %mode%
call :StopService sppsvc
if %OsppHook% NEQ 0 call :StopService osppsvc
if %External% EQU 0 if %AUR% EQU 0 (set _verb=0&set _rtr=ReturnHook&goto :InstallHook)

:ReturnHook
if %External% EQU 0 if %AUR% EQU 1 (
call :UpdateIFEOEntry %SppVer%
call :UpdateIFEOEntry osppsvc.exe
)
if %External% EQU 1 if %AUR% EQU 1 (
call :UpdateOSPPEntry osppsvc.exe
)

SET Win10Gov=0
SET "EditionWMI="
SET "EditionID="
IF %winbuild% LSS 14393 if %SSppHook% NEQ 0 GOTO :Main
SET "RegKey=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
SET "Pattern=Microsoft-Windows-*Edition~31bf3856ad364e35"
SET "EditionPKG=FFFFFFFF"
FOR /F "TOKENS=8 DELIMS=\" %%A IN ('REG QUERY "%RegKey%" /f "%Pattern%" /k %_Nul6% ^| FIND /I "CurrentVersion"') DO (
  REG QUERY "%RegKey%\%%A" /v "CurrentState" %_Nul2% | FIND /I "0x70" %_Nul1% && (
    FOR /F "TOKENS=3 DELIMS=-~" %%B IN ('ECHO %%A') DO SET "EditionPKG=%%B"
  )
)
IF /I "%EditionPKG:~-7%"=="Edition" (
SET "EditionID=%EditionPKG:~0,-7%"
) ELSE (
FOR /F "TOKENS=3 DELIMS=: " %%A IN ('DISM /English /Online /Get-CurrentEdition %_Nul6% ^| FIND /I "Current Edition :"') DO SET "EditionID=%%A"
)
sc start sppsvc trigger=timer;sessionid=0 %_Nul3%
FOR /F "TOKENS=2 DELIMS==" %%A IN ('"WMIC PATH SoftwareLicensingProduct WHERE (ApplicationID='%_wApp%' %adoff% AND PartialProductKey is not NULL) GET LicenseFamily /VALUE" %_Nul6%') DO SET "EditionWMI=%%A"
IF "%EditionWMI%"=="" (
IF %winbuild% GEQ 17063 FOR /F "SKIP=2 TOKENS=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionId') DO SET "EditionID=%%B"
IF %winbuild% LSS 14393 (
  FOR /F "SKIP=2 TOKENS=2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionId') DO SET "EditionID=%%B"
  GOTO :Main
  )
)
IF NOT "%EditionWMI%"=="" SET "EditionID=%EditionWMI%"
IF /I "%EditionID%"=="IoTEnterprise" SET "EditionID=Enterprise"
IF /I "%EditionID%"=="IoTEnterpriseS" SET "EditionID=EnterpriseS"
IF /I "%EditionID%"=="ProfessionalSingleLanguage" SET "EditionID=Professional"
IF /I "%EditionID%"=="ProfessionalCountrySpecific" SET "EditionID=Professional"
IF /I "%EditionID%"=="EnterpriseG" SET Win10Gov=1
IF /I "%EditionID%"=="EnterpriseGN" SET Win10Gov=1

:Main
if defined EditionID (set "_winos=Windows %EditionID% edition") else (set "_winos=Detected Windows")
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName %_Nul6%') do if not errorlevel 1 set "_winos=%%b"
set "nKMS=不支持 KMS 激活..."
set "nEval=无法激活评估版本.请安装完整的 Windows 操作系统."
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-*EvalEdition~*.mum" set _eval=1
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*EvalEdition~*.mum" set "nEval=Server Evaluation cannot be activated. Please convert to full Server OS."
if exist "%SystemRoot%\Servicing\Packages\Microsoft-Windows-Server*EvalCorEdition~*.mum" set _eval=1&set "nEval=Server Evaluation cannot be activated. Please convert to full Server OS."
set "_C16R="
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath %_Nul3% && for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms" (
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && set "_C16R=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
)
set "_C15R="
reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath %_Nul3% && for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses\ProPlus*.xrm-ms" (
reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration /v ProductReleaseIds %_Nul3% && call set "_C15R=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration"
if not defined _C15R reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid %_Nul3% && call set "_C15R=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag"
)
set "_C14R="
if %_wow%==0 (reg query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set "_C14R=1") else (reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k %_Nul3% && set "_C14R=1")
for %%A in (14,15,16,19) do call :officeLoc %%A
if %_O14MSI% EQU 1 set "_C14R="

set S_OK=1
call :RunSPP
if %ActOffice% NEQ 0 call :RunOSPP
if %ActOffice% EQU 0 (echo.&echo Office 激活已关闭...)
if %S_OK% EQU 0 if %External% EQU 0 call :CheckFR

if exist "!_temp!\crv*.txt" del /f /q "!_temp!\crv*.txt"
if exist "!_temp!\*chk.txt" del /f /q "!_temp!\*chk.txt"
if exist "!_temp!\slmgr.vbs" del /f /q "!_temp!\slmgr.vbs"
call :StopService sppsvc
if %OsppHook% NEQ 0 call :StopService osppsvc

if %AUR% EQU 0 call :RemoveHook

sc start sppsvc trigger=timer;sessionid=0 %_Nul3%
set External=0
set KMS_IP=%_uIP%
if %_verb% EQU 1 (
echo.&echo %line3%&echo.
if "%_rtr%"=="DoActivate" (
echo.
echo 确保在防病毒保护中排除此文件.
echo %SystemRoot%\System32\SppExtComObjHook.dll)
)
if %uManual% EQU 1 timeout 5
if %uAutoRenewal% EQU 1 timeout 5
if %Unattend% NEQ 0 goto :TheEnd
echo.
echo 敲任意键继续...
pause >nul
goto :MainMenu

:RunSPP
set spp=SoftwareLicensingProduct
set sps=SoftwareLicensingService
set W1nd0ws=1
set WinPerm=0
set WinVL=0
set Off1ce=0
set RunR2V=0
if %winbuild% GEQ 9200 if %ActOffice% NEQ 0 call :sppoff
wmic path %spp% where (Description like '%%KMSCLIENT%%') get Name %_Nul2% | findstr /i Windows %_Nul1% && (set WinVL=1)
if %WinVL% EQU 0 (
if %ActWindows% EQU 0 (
  echo.&echo Windows 激活已关闭...
  ) else (
  if %SSppHook% EQU 0 (
    echo.&echo %_winos% %nKMS%
    if defined _eval echo %nEval%
    ) else (
    echo.&echo 当前系统KMS激活ID失败^(s^) .&echo 可能sppsvc服务 或 SppExtComObjHook.dll 均不起作用.&echo 有关故障排除，请参阅“自述文件”.
    exit /b
    )
  )
)
if %WinVL% EQU 0 if %Off1ce% EQU 0 exit /b
if %AUR% EQU 0 (
reg delete "HKLM\%SPPk%\%_wApp%" /f %_Nul3%
reg delete "HKLM\%SPPk%\%_oApp%" /f %_Nul3%
reg delete "HKU\S-1-5-20\%SPPk%\%_wApp%" /f %_Nul3%
reg delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f %_Nul3%
)
set _gvlk=0
if %winbuild% GEQ 10240 wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' and PartialProductKey is not NULL) get Name %_Nul2% | findstr /i Windows %_Nul1% && (set _gvlk=1)
set gpr=0
if %winbuild% GEQ 10240 if %SkipKMS38% NEQ 0 if %_gvlk% EQU 1 for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' and PartialProductKey is not NULL) get GracePeriodRemaining /VALUE" %_Nul6%') do set "gpr=%%A"
if %gpr% NEQ 0 if %gpr% GTR 259200 (
set W1nd0ws=0
wmic path %spp% where "ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' and PartialProductKey is not NULL" get LicenseFamily %_Nul2% | findstr /i EnterpriseG %_Nul1% && (call set W1nd0ws=1)
)
for /f "tokens=2 delims==" %%A in ('"wmic path %sps% get Version /VALUE"') do set ver=%%A
reg add "HKLM\%SPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%" %_Nul3%
reg add "HKLM\%SPPk%" /f /v KeyManagementServicePort /t REG_SZ /d "%KMS_Port%" %_Nul3%
if %W1nd0ws% EQU 0 for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%') get ID /VALUE"') do (set app=%%G&call :sppchkwin)
if %W1nd0ws% EQU 1 if %ActWindows% NEQ 0 for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' %adoff%) get ID /VALUE"') do (set app=%%G&call :sppchkwin)
rem if %ESU_EDT% EQU 1 if %ActWindows% NEQ 0 for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' %addon%) get ID /VALUE"') do (set app=%%G&call :esuchk)
if %W1nd0ws% EQU 1 if %ActWindows% EQU 0 (echo.&echo Windows 激活已关闭...)
if %Off1ce% EQU 1 if %ActOffice% NEQ 0 for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (ApplicationID='%_oApp%' and Description like '%%KMSCLIENT%%') get ID /VALUE"') do (set app=%%G&call :sppchkoff)
if %AUR% EQU 0 (
call :cREG %_Nul3%
) else (
reg delete "HKLM\%SPPk%" /f /v DisableDnsPublishing %_Nul3%
reg delete "HKLM\%SPPk%" /f /v DisableKeyManagementServiceHostCaching %_Nul3%
)
exit /b

:sppoff
set OffUWP=0
if %winbuild% GEQ 10240 reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msosync.exe" %_Nul3% && (
dir /b "%ProgramFiles%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set OffUWP=1
if %xOS%==x64 dir /b "%ProgramW6432%\WindowsApps\Microsoft.Office.Desktop*" %_Nul3% && set OffUWP=1
)
rem nothing installed
if %loc_off19% EQU 0 if %loc_off16% EQU 0 if %loc_off15% EQU 0 (
if %OffUWP% EQU 0 (echo.&echo 没有安装 Office 2013-2021...) else (echo.&echo %_mOuwp%)
exit /b
)
set Off1ce=1
set _sC2R=sppoff
set _fC2R=ReturnSPP
set vol_off15=0&set vol_off16=0&set vol_off19=0
wmic path %spp% where (Description like '%%KMSCLIENT%%' AND NOT Name like '%%MondoR_KMS_Automation%%') get Name > "!_temp!\sppchk.txt" 2>&1
find /i "Office 19" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off19=1)
find /i "Office 16" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off16=1)
find /i "Office 15" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off15=1)
for %%A in (15,16,19) do if !loc_off%%A! EQU 0 set vol_off%%A=0
if %vol_off16% EQU 1 find /i "Office16MondoVL_KMS_Client" "!_temp!\sppchk.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "Office16O365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% || (set vol_off16=0)
)
if %vol_off15% EQU 1 find /i "OfficeMondoVL_KMS_Client" "!_temp!\sppchk.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "OfficeO365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% || (set vol_off15=0)
)
set ret_off15=0&set ret_off16=0&set ret_off19=0
wmic path %spp% where (ApplicationID='%_oApp%' AND NOT Name like '%%O365%%') get Name > "!_temp!\sppchk.txt" 2>&1
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 19" %_Nul1% && (set ret_off19=1)
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 16" %_Nul1% && (set ret_off16=1)
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 15" %_Nul1% && (set ret_off15=1)
if %ret_off19% EQU 1 if %_O16MSI% EQU 0 set vol_off19=0
if %ret_off16% EQU 1 if %_O16MSI% EQU 0 set vol_off16=0
if %ret_off15% EQU 1 if %_O15MSI% EQU 0 set vol_off15=0
set vol_offgl=1
if %vol_off19% EQU 0 if %vol_off16% EQU 0 if %vol_off15% EQU 0 set vol_offgl=0
rem mixed Volume + Retail
if %loc_off19% EQU 1 if %vol_off19% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
if defined _C16R if %loc_off16% EQU 1 if %vol_off16% EQU 0 if %vol_off19% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
if defined _C15R if %loc_off15% EQU 1 if %vol_off15% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
if %loc_off16% EQU 0 if %ret_off16% EQU 1 if %_O16MSI% EQU 0 if %OffUWP% EQU 1 (echo.&echo %_mOuwp%)
rem all supported Volume + message for unsupported
if %vol_offgl% EQU 1 (
if %ret_off16% EQU 1 if %_O16MSI% EQU 1 (echo.&echo %_mO16m%)
if %ret_off15% EQU 1 if %_O15MSI% EQU 1 (echo.&echo %_mO15m%)
exit /b
)
set Off1ce=0
rem Retail C2R
if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
:ReturnSPP
rem Retail MSI or failed C2R-R2V
if %loc_off19% EQU 1 if %vol_off19% EQU 0 (
echo.&echo %_mO19c%
)
if %loc_off16% EQU 1 if %vol_off16% EQU 0 (
if defined _C16R (echo.&echo %_mO16c%) else if %_O16MSI% EQU 1 (echo.&echo %_mO16m%)
)
if %loc_off15% EQU 1 if %vol_off15% EQU 0 (
if defined _C15R (echo.&echo %_mO15c%) else if %_O15MSI% EQU 1 (echo.&echo %_mO15m%)
)
exit /b

:sppchkoff
wmic path %spp% where ID='%app%' get Name > "!_temp!\sppchk.txt"
find /i "Office 15" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off15% EQU 0 exit /b)
find /i "Office 16" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off16% EQU 0 exit /b)
find /i "Office 19" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off19% EQU 0 exit /b)
set _officespp=1
wmic path %spp% where (PartialProductKey is not NULL) get ID %_Nul2% | findstr /i "%app%" %_Nul1% && (echo.&call :activate&exit /b)
for /f "tokens=3 delims==, " %%G in ('"wmic path %spp% where ID='%app%' get Name /value"') do set OffVer=%%G
call :offchk%OffVer%
exit /b

:sppchkwin
set _officespp=0
if %winbuild% GEQ 14393 if %_gvlk% EQU 0 wmic path %spp% where (ApplicationID='%_wApp%' and Description like '%%KMSCLIENT%%' and PartialProductKey is not NULL) get Name %_Nul2% | findstr /i Windows %_Nul1% && (set _gvlk=1)
wmic path %spp% where ID='%app%' get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (echo.&call :activate&exit /b)
wmic path %spp% where (PartialProductKey is not NULL) get ID %_Nul2% | findstr /i "%app%" %_Nul1% && (echo.&call :activate&exit /b)
if %winbuild% GEQ 14393 if %_gvlk% EQU 1 exit /b
if %WinPerm% EQU 1 exit /b
if %winbuild% LSS 10240 (call :winchk&exit /b)
for %%A in (
b71515d9-89a2-4c60-88c8-656fbcca7f3a,af43f7f0-3b1e-4266-a123-1fdb53f4323b,075aca1f-05d7-42e5-a3ce-e349e7be7078
11a37f09-fb7f-4002-bd84-f3ae71d11e90,43f2ab05-7c87-4d56-b27c-44d0f9a3dabd,2cf5af84-abab-4ff0-83f8-f040fb2576eb
6ae51eeb-c268-4a21-9aae-df74c38b586d,ff808201-fec6-4fd4-ae16-abbddade5706,34260150-69ac-49a3-8a0d-4a403ab55763
4dfd543d-caa6-4f69-a95f-5ddfe2b89567,5fe40dd6-cf1f-4cf2-8729-92121ac2e997,903663f7-d2ab-49c9-8942-14aa9e0a9c72
2cc171ef-db48-4adc-af09-7c574b37f139,5b2add49-b8f4-42e0-a77c-adad4efeeeb1
) do (
if /i '%app%' EQU '%%A' exit /b
)
if not defined EditionID (call :winchk&exit /b)
if %winbuild% LSS 14393 (call :winchk&exit /b)
if /i '%app%' EQU '0df4f814-3f57-4b8b-9a9d-fddadcd69fac' if /i %EditionID% NEQ CloudE exit /b
if /i '%app%' EQU 'e0c42288-980c-4788-a014-c080d2e1926e' if /i %EditionID% NEQ Education exit /b
if /i '%app%' EQU '73111121-5638-40f6-bc11-f1d7b0d64300' if /i %EditionID% NEQ Enterprise exit /b
if /i '%app%' EQU '2de67392-b7a7-462a-b1ca-108dd189f588' if /i %EditionID% NEQ Professional exit /b
if /i '%app%' EQU '3f1afc82-f8ac-4f6c-8005-1d233e606eee' if /i %EditionID% NEQ ProfessionalEducation exit /b
if /i '%app%' EQU '82bbc092-bc50-4e16-8e18-b74fc486aec3' if /i %EditionID% NEQ ProfessionalWorkstation exit /b
if /i '%app%' EQU '3c102355-d027-42c6-ad23-2e7ef8a02585' if /i %EditionID% NEQ EducationN exit /b
if /i '%app%' EQU 'e272e3e2-732f-4c65-a8f0-484747d0d947' if /i %EditionID% NEQ EnterpriseN exit /b
if /i '%app%' EQU 'a80b5abf-76ad-428b-b05d-a47d2dffeebf' if /i %EditionID% NEQ ProfessionalN exit /b
if /i '%app%' EQU '5300b18c-2e33-4dc2-8291-47ffcec746dd' if /i %EditionID% NEQ ProfessionalEducationN exit /b
if /i '%app%' EQU '4b1571d3-bafb-4b40-8087-a961be2caf65' if /i %EditionID% NEQ ProfessionalWorkstationN exit /b
if /i '%app%' EQU '58e97c99-f377-4ef1-81d5-4ad5522b5fd8' if /i %EditionID% NEQ Core exit /b
if /i '%app%' EQU 'cd918a57-a41b-4c82-8dce-1a538e221a83' if /i %EditionID% NEQ CoreSingleLanguage exit /b
if /i '%app%' EQU 'ec868e65-fadf-4759-b23e-93fe37f2cc29' if /i %EditionID% NEQ ServerRdsh exit /b
if /i '%app%' EQU 'e4db50ea-bda1-4566-b047-0ca50abc6f07' if /i %EditionID% NEQ ServerRdsh exit /b
if /i '%app%' EQU 'e4db50ea-bda1-4566-b047-0ca50abc6f07' (
wmic path %spp% where 'Description like "%%KMSCLIENT%%"' get ID | findstr /i "ec868e65-fadf-4759-b23e-93fe37f2cc29" %_Nul3% && (exit /b)
)
call :winchk
exit /b

:winchk
if not defined tok (if %winbuild% GEQ 9200 (set "tok=4") else (set "tok=7"))
wmic path %spp% where (LicenseStatus='1' and Description like '%%KMSCLIENT%%' %adoff%) get Name %_Nul2% | findstr /i "Windows" %_Nul3% && (exit /b)
echo.
wmic path %spp% where (LicenseStatus='1' and GracePeriodRemaining='0' %adoff% and PartialProductKey is not NULL) get Name %_Nul2% | findstr /i "Windows" %_Nul3% && (
set WinPerm=1
)
if %WinPerm% EQU 0 (
wmic path %spp% where "ApplicationID='%_wApp%' and LicenseStatus='1' %adoff%" get Name %_Nul2% | findstr /i "Windows" %_Nul3% && (
for /f "tokens=%tok% delims=, " %%G in ('"wmic path %spp% where (ApplicationID='%_wApp%' and LicenseStatus='1' %adoff%) get Description /VALUE"') do set "channel=%%G"
  for %%A in (VOLUME_MAK, RETAIL, OEM_DM, OEM_SLP, OEM_COA, OEM_COA_SLP, OEM_COA_NSLP, OEM_NONSLP, OEM) do if /i "%%A"=="!channel!" set WinPerm=1
  )
)
if %WinPerm% EQU 0 (
copy /y %SysPath%\slmgr.vbs "!_temp!\slmgr.vbs" %_Nul3%
cscript //nologo "!_temp!\slmgr.vbs" /xpr %_Nul2% | findstr /i "permanently" %_Nul3% && set WinPerm=1
)
if %WinPerm% EQU 1 (
for /f "tokens=2 delims==" %%x in ('"wmic path %spp% where (ApplicationID='%_wApp%' and LicenseStatus='1' %adoff%) get Name /VALUE"') do echo Checking: %%x
echo 产品已永久激活.
exit /b
)
call :insKey
exit /b

:esuchk
set _officespp=0
set ESU_ADD=1
wmic path %spp% where ID='%app%' get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (echo.&call :activate&exit /b)
if /i '%app%' EQU '3fcc2df2-f625-428d-909a-1f76efc849b6' (
wmic path %spp% where ID="77db037b-95c3-48d7-a3ab-a9c6d41093e0" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU 'dadfcd24-6e37-47be-8f7f-4ceda614cece' (
wmic path %spp% where ID="0e00c25d-8795-4fb7-9572-3803d91b6880" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU '0c29c85e-12d7-4af8-8e4d-ca1e424c480c' (
wmic path %spp% where ID="4220f546-f522-46df-8202-4d07afd26454" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU 'f2b21bfc-a6b0-4413-b4bb-9f06b55f2812' (
wmic path %spp% where ID="553673ed-6ddf-419c-a153-b760283472fd" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU 'bfc078d0-8c7f-475c-8519-accc46773113' (
wmic path %spp% where ID="04fa0286-fa74-401e-bbe9-fbfbb158010d" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU '23c6188f-c9d8-457e-81b6-adb6dacb8779' (
wmic path %spp% where ID="16c08c85-0c8b-4009-9b2b-f1f7319e45f9" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
if /i '%app%' EQU 'e7cce015-33d6-41c1-9831-022ba63fe1da' (
wmic path %spp% where ID="8e7bfb1e-acc1-4f56-abae-b80fce56cd4b" get LicenseStatus %_Nul2% | findstr "1" %_Nul1% && (exit /b)
)
wmic path %spp% where (PartialProductKey is not NULL) get ID %_Nul2% | findstr /i "%app%" %_Nul1% && (echo.&call :activate&exit /b)
call :insKey
exit /b

:RunOSPP
set spp=OfficeSoftwareProtectionProduct
set sps=OfficeSoftwareProtectionService
set Off1ce=0
set RunR2V=0
if %winbuild% LSS 9200 (set "aword=2010-2021") else (set "aword=2010")
if %OsppHook% EQU 0 (echo.&echo 检测到没有安装可以KMS38激活的 Office %aword% ...&exit /b)
if %winbuild% GEQ 9200 if %loc_off14% EQU 0 (echo.&echo 没有安装 Office %aword% ...&exit /b)
sc start osppsvc %_Nul3%
if %winbuild% GEQ 9200 wmic path %spp% get Description %_Nul2% | findstr /i KMSCLIENT %_Nul1% || (
if defined _C14R (echo.&echo %_mO14c%) else if %_O14MSI% EQU 1 (echo.&echo %_mO14m%)
exit /b
)
if %winbuild% GEQ 9200 set Off1ce=1
if %winbuild% LSS 9200 call :win7off
if %Off1ce% EQU 0 exit /b
if %AUR% EQU 0 (
reg delete "HKLM\%OPPk%\%_oA14%" /f %_Nul3%
reg delete "HKLM\%OPPk%\%_oApp%" /f %_Nul3%
)
set "vPrem="&set "vProf="
if %loc_off14% EQU 1 (
for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where (LicenseFamily='OfficeVisioPrem-MAK') get LicenseStatus /VALUE" %_Nul6%') do set vPrem=%%A
for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where (LicenseFamily='OfficeVisioPro-MAK') get LicenseStatus /VALUE" %_Nul6%') do set vProf=%%A
)
for /f "tokens=2 delims==" %%A in ('"wmic path %sps% get Version /VALUE" %_Nul6%') do set ver=%%A
reg add "HKLM\%OPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%" %_Nul3%
reg add "HKLM\%OPPk%" /f /v KeyManagementServicePort /t REG_SZ /d "%KMS_Port%" %_Nul3%
for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (Description like '%%KMSCLIENT%%') get ID /VALUE"') do (set app=%%G&call :osppchk)
if %AUR% EQU 0 (
call :cREG %_Nul3%
) else (
reg delete "HKLM\%OPPk%" /f /v DisableDnsPublishing %_Nul3%
reg delete "HKLM\%OPPk%" /f /v DisableKeyManagementServiceHostCaching %_Nul3%
)
exit /b

:win7off
rem nothing installed
if %loc_off19% EQU 0 if %loc_off16% EQU 0 if %loc_off15% EQU 0 if %loc_off14% EQU 0 (echo.&echo No Installed Office %aword% Product Detected...&exit /b)
set Off1ce=1
set _sC2R=win7off
set _fC2R=ReturnOSPP
set vol_off14=0&set vol_off15=0&set vol_off16=0&set vol_off19=0
wmic path %spp% where (Description like '%%KMSCLIENT%%' AND NOT Name like '%%MondoR_KMS_Automation%%') get Name > "!_temp!\sppchk.txt" 2>&1
find /i "Office 19" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off19=1)
find /i "Office 16" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off16=1)
find /i "Office 15" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off15=1)
find /i "Office 14" "!_temp!\sppchk.txt" %_Nul1% && (set vol_off14=1)
for %%A in (14,15,16,19) do if !loc_off%%A! EQU 0 set vol_off%%A=0
if %vol_off16% EQU 1 find /i "Office16MondoVL_KMS_Client" "!_temp!\sppchk.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "Office16O365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% || (set vol_off16=0)
)
if %vol_off15% EQU 1 find /i "OfficeMondoVL_KMS_Client" "!_temp!\sppchk.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "OfficeO365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% || (set vol_off15=0)
)
set ret_off15=0&set ret_off16=0&set ret_off19=0
wmic path %spp% where (ApplicationID='%_oApp%' AND NOT Name like '%%O365%%') get Name > "!_temp!\sppchk.txt" 2>&1
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 19" %_Nul1% && (set ret_off19=1)
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 16" %_Nul1% && (set ret_off16=1)
find /i "R_Retail" "!_temp!\sppchk.txt" %_Nul2% | find /i "Office 15" %_Nul1% && (set ret_off15=1)
if %ret_off19% EQU 1 if %_O16MSI% EQU 0 set vol_off19=0
if %ret_off16% EQU 1 if %_O16MSI% EQU 0 set vol_off16=0
if %ret_off15% EQU 1 if %_O15MSI% EQU 0 set vol_off15=0
set vol_offgl=1
if %vol_off19% EQU 0 if %vol_off16% EQU 0 if %vol_off15% EQU 0 if %vol_off14% EQU 0 set vol_offgl=0
rem mixed Volume + Retail
if %loc_off19% EQU 1 if %vol_off19% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
if defined _C16R if %loc_off16% EQU 1 if %vol_off16% EQU 0 if %vol_off19% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
if defined _C15R if %loc_off15% EQU 1 if %vol_off15% EQU 0 if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
rem all supported Volume + message for unsupported
if %vol_offgl% EQU 1 (
if %ret_off16% EQU 1 if %_O16MSI% EQU 1 (echo.&echo %_mO16m%)
if %ret_off15% EQU 1 if %_O15MSI% EQU 1 (echo.&echo %_mO15m%)
if %loc_off14% EQU 1 if %vol_off14% EQU 0 (if defined _C14R (echo.&echo %_mO14c%) else if %_O14MSI% EQU 1 (echo.&echo %_mO14m%))
exit /b
)
set Off1ce=0
rem Retail C2R
if %RunR2V% EQU 0 if %AutoR2V% EQU 1 goto :C2RR2V
:ReturnOSPP
rem Retail MSI or failed C2R-R2V
if %loc_off19% EQU 1 if %vol_off19% EQU 0 (
echo.&echo %_mO19c%
)
if %loc_off16% EQU 1 if %vol_off16% EQU 0 (
if defined _C16R (echo.&echo %_mO16c%) else if %_O16MSI% EQU 1 (echo.&echo %_mO16m%)
)
if %loc_off15% EQU 1 if %vol_off15% EQU 0 (
if defined _C15R (echo.&echo %_mO15c%) else if %_O15MSI% EQU 1 (echo.&echo %_mO15m%)
)
if %loc_off14% EQU 1 if %vol_off14% EQU 0 (
if defined _C14R (echo.&echo %_mO14c%) else if %_O14MSI% EQU 1 (echo.&echo %_mO14m%)
)
exit /b

:osppchk
wmic path %spp% where ID='%app%' get Name > "!_temp!\sppchk.txt"
find /i "Office 14" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off14% EQU 0 exit /b)
find /i "Office 15" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off15% EQU 0 exit /b)
find /i "Office 16" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off16% EQU 0 exit /b)
find /i "Office 19" "!_temp!\sppchk.txt" %_Nul1% && (if %loc_off19% EQU 0 exit /b)
set _officespp=0
wmic path %spp% where (PartialProductKey is not NULL) get ID %_Nul2% | findstr /i "%app%" %_Nul1% && (echo.&call :activate&exit /b)
for /f "tokens=3 delims==, " %%G in ('"wmic path %spp% where ID='%app%' get Name /value"') do set OffVer=%%G
call :offchk%OffVer%
exit /b

:offchk
set ls=0
set ls2=0
for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where (LicenseFamily='Office%~1') get LicenseStatus /VALUE" %_Nul6%') do set /a ls=%%A
if "%~3" NEQ "" (
for /f "tokens=2 delims==" %%A in ('"wmic path %spp% where (LicenseFamily='Office%~3') get LicenseStatus /VALUE" %_Nul6%') do set /a ls2=%%A
)
if "%ls2%" EQU "1" (
echo 检测: %~4
echo 产品已永久激活.
exit /b
)
if "%ls%" EQU "1" (
echo 检测: %~2
echo 产品已永久激活.
exit /b
)
call :insKey
exit /b

:offchk19
if /i '%app%' EQU '0bc88885-718c-491d-921f-6f214349e79c' exit /b
if /i '%app%' EQU 'fc7c4d0c-2e85-4bb9-afd4-01ed1476b5e9' exit /b
if /i '%app%' EQU '500f6619-ef93-4b75-bcb4-82819998a3ca' exit /b
if /i '%app%' EQU '85dd8b5f-eaa4-4af3-a628-cce9e77c9a03' (
call :offchk "19ProPlus2019VL_MAK_AE" "Office ProPlus 2019"
exit /b
)
if /i '%app%' EQU '6912a74b-a5fb-401a-bfdb-2e3ab46f4b02' (
call :offchk "19Standard2019VL_MAK_AE" "Office Standard 2019"
exit /b
)
if /i '%app%' EQU '2ca2bf3f-949e-446a-82c7-e25a15ec78c4' (
call :offchk "19ProjectPro2019VL_MAK_AE" "Project Pro 2019"
exit /b
)
if /i '%app%' EQU '1777f0e3-7392-4198-97ea-8ae4de6f6381' (
call :offchk "19ProjectStd2019VL_MAK_AE" "Project Standard 2019"
exit /b
)
if /i '%app%' EQU '5b5cf08f-b81a-431d-b080-3450d8620565' (
call :offchk "19VisioPro2019VL_MAK_AE" "Visio Pro 2019"
exit /b
)
if /i '%app%' EQU 'e06d7df3-aad0-419d-8dfb-0ac37e2bdf39' (
call :offchk "19VisioStd2019VL_MAK_AE" "Visio Standard 2019"
exit /b
)
call :insKey
exit /b

:offchk16
if /i '%app%' EQU 'd450596f-894d-49e0-966a-fd39ed4c4c64' (
call :offchk "16ProPlusVL_MAK" "Office ProPlus 2016"
exit /b
)
if /i '%app%' EQU 'dedfa23d-6ed1-45a6-85dc-63cae0546de6' (
call :offchk "16StandardVL_MAK" "Office Standard 2016"
exit /b
)
if /i '%app%' EQU '4f414197-0fc2-4c01-b68a-86cbb9ac254c' (
call :offchk "16ProjectProVL_MAK" "Project Pro 2016"
exit /b
)
if /i '%app%' EQU 'da7ddabc-3fbe-4447-9e01-6ab7440b4cd4' (
call :offchk "16ProjectStdVL_MAK" "Project Standard 2016"
exit /b
)
if /i '%app%' EQU '6bf301c1-b94a-43e9-ba31-d494598c47fb' (
call :offchk "16VisioProVL_MAK" "Visio Pro 2016"
exit /b
)
if /i '%app%' EQU 'aa2a7821-1827-4c2c-8f1d-4513a34dda97' (
call :offchk "16VisioStdVL_MAK" "Visio Standard 2016"
exit /b
)
if /i '%app%' EQU '829b8110-0e6f-4349-bca4-42803577788d' (
call :offchk "16ProjectProXC2RVL_MAKC2R" "Project Pro 2016 C2R"
exit /b
)
if /i '%app%' EQU 'cbbaca45-556a-4416-ad03-bda598eaa7c8' (
call :offchk "16ProjectStdXC2RVL_MAKC2R" "Project Standard 2016 C2R"
exit /b
)
if /i '%app%' EQU 'b234abe3-0857-4f9c-b05a-4dc314f85557' (
call :offchk "16VisioProXC2RVL_MAKC2R" "Visio Pro 2016 C2R"
exit /b
)
if /i '%app%' EQU '361fe620-64f4-41b5-ba77-84f8e079b1f7' (
call :offchk "16VisioStdXC2RVL_MAKC2R" "Visio Standard 2016 C2R"
exit /b
)
call :insKey
exit /b

:offchk15
if /i '%app%' EQU 'b322da9c-a2e2-4058-9e4e-f59a6970bd69' (
call :offchk "ProPlusVL_MAK" "Office ProPlus 2013"
exit /b
)
if /i '%app%' EQU 'b13afb38-cd79-4ae5-9f7f-eed058d750ca' (
call :offchk "StandardVL_MAK" "Office Standard 2013"
exit /b
)
if /i '%app%' EQU '4a5d124a-e620-44ba-b6ff-658961b33b9a' (
call :offchk "ProjectProVL_MAK" "Project Pro 2013"
exit /b
)
if /i '%app%' EQU '427a28d1-d17c-4abf-b717-32c780ba6f07' (
call :offchk "ProjectStdVL_MAK" "Project Standard 2013"
exit /b
)
if /i '%app%' EQU 'e13ac10e-75d0-4aff-a0cd-764982cf541c' (
call :offchk "VisioProVL_MAK" "Visio Pro 2013"
exit /b
)
if /i '%app%' EQU 'ac4efaf0-f81f-4f61-bdf7-ea32b02ab117' (
call :offchk "VisioStdVL_MAK" "Visio Standard 2013"
exit /b
)
call :insKey
exit /b

:offchk14
if /i '%app%' EQU '6f327760-8c5c-417c-9b61-836a98287e0c' (
call :offchk "ProPlus-MAK" "Office ProPlus 2010" "ProPlusAcad-MAK" "Office Professional Academic 2010"
exit /b
)
if /i '%app%' EQU '9da2a678-fb6b-4e67-ab84-60dd6a9c819a' (
call :offchk "Standard-MAK" "Office Standard 2010" "StandardAcad-MAK"  "Office Standard Academic 2010"
exit /b
)
if /i '%app%' EQU 'ea509e87-07a1-4a45-9edc-eba5a39f36af' (
call :offchk "SmallBusBasics-MAK" "Office Small Business Basics 2010"
exit /b
)
if /i '%app%' EQU 'df133ff7-bf14-4f95-afe3-7b48e7e331ef' (
call :offchk "ProjectPro-MAK" "Project Pro 2010"
exit /b
)
if /i '%app%' EQU '5dc7bf61-5ec9-4996-9ccb-df806a2d0efe' (
call :offchk "ProjectStd-MAK" "Project Standard 2010" "ProjectStd-MAK2" "Project Standard 2010"
exit /b
)
if /i '%app%' EQU '92236105-bb67-494f-94c7-7f7a607929bd' (
call :offchk "VisioPrem-MAK" "Visio Premium 2010" "VisioPro-MAK" "Visio Pro 2010"
exit /b
)
if defined vPrem exit /b
if /i '%app%' EQU 'e558389c-83c3-4b29-adfe-5e4d7f46c358' (
call :offchk "VisioPro-MAK" "Visio Pro 2010" "VisioStd-MAK" "Visio Standard 2010"
exit /b
)
if defined vProf exit /b
if /i '%app%' EQU '9ed833ff-4f92-4f36-b370-8683a4f13275' (
call :offchk "VisioStd-MAK" "Visio Standard 2010"
exit /b
)
call :insKey
exit /b

:officeLoc
set loc_off%1=0
set _O%1MSI=0
if %1 EQU 19 (
if defined _C16R reg query %_C16R% /v ProductReleaseIds %_Nul2% | findstr 2019 %_Nul1% && set loc_off%1=1
if defined _C16R reg query %_C16R% /v ProductReleaseIds %_Nul2% | findstr 2021 %_Nul1% && set loc_off%1=1
exit /b
)

for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set loc_off%1=1
set _O%1MSI=1
)
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\%1.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" (
set loc_off%1=1
set _O%1MSI=1
)

if %1 EQU 16 if defined _C16R (
for /f "skip=2 tokens=2*" %%a in ('reg query %_C16R% /v ProductReleaseIds') do echo %%b> "!_temp!\c2rchk.txt"
for %%a in (%LV16Ids%,ProjectProX,ProjectStdX,VisioProX,VisioStdX) do (
  findstr /I /C:"%%aVolume" "!_temp!\c2rchk.txt" %_Nul1% && set loc_off%1=1
  )
for %%a in (%LR16Ids%) do (
  findstr /I /C:"%%aRetail" "!_temp!\c2rchk.txt" %_Nul1% && set loc_off%1=1
  )
exit /b
)

if %1 EQU 15 if defined _C15R (
set loc_off%1=1
exit /b
)

if exist "%ProgramFiles%\Microsoft Office\Office%1\OSPP.VBS" set loc_off%1=1
if %xOS%==x64 if exist "%ProgramW6432%\Microsoft Office\Office%1\OSPP.VBS" set loc_off%1=1
if %xOS%==x64 if exist "%ProgramFiles(x86)%\Microsoft Office\Office%1\OSPP.VBS" set loc_off%1=1
exit /b

:insKey
set S_OK=1
echo.
set "_key="
if %ESU_ADD% EQU 0 for /f "tokens=2 delims==" %%x in ('"wmic path %spp% where ID='%app%' get Name /VALUE"') do echo Installing Key: %%x
if %ESU_ADD% EQU 1 for /f "tokens=2 delims==f" %%x in ('"wmic path %spp% where ID='%app%' get Name /VALUE"') do echo Installing Key: %%x
set ESU_ADD=0
call :keys %app%
if "%_key%"=="" (echo 找不到匹配的 KMS 客户端密钥&exit /b)
wmic path %sps% where version='%ver%' call InstallProductKey ProductKey="%_key%" %_Nul3%
set ERRORCODE=%ERRORLEVEL%
if %ERRORCODE% NEQ 0 (
cmd /c exit /b %ERRORCODE%
echo Failed: 0x!=ExitCode!
set S_OK=0
exit /b
)
if %sps% EQU SoftwareLicensingService wmic path %sps% where version='%ver%' call RefreshLicenseStatus %_Nul3%

:activate
set S_OK=1
if %sps% EQU SoftwareLicensingService (
if %_officespp% EQU 0 (reg delete "HKLM\%SPPk%\%_wApp%\%app%" /f %_Nul3%) else (reg delete "HKLM\%SPPk%\%_oApp%\%app%" /f %_Nul3%)
) else (
reg delete "HKLM\%OPPk%\%_oA14%\%app%" /f %_Nul3%
reg delete "HKLM\%OPPk%\%_oApp%\%app%" /f %_Nul3%
)
if %W1nd0ws% EQU 0 if %_officespp% EQU 0 if %sps% EQU SoftwareLicensingService (
reg add "HKLM\%SPPk%\%_wApp%\%app%" /f /v KeyManagementServiceName /t REG_SZ /d "127.0.0.2" %_Nul3%
reg add "HKLM\%SPPk%\%_wApp%\%app%" /f /v KeyManagementServicePort /t REG_SZ /d "%KMS_Port%" %_Nul3%
reg add "HKU\S-1-5-20\%SPPk%\%_wApp%\%app%" /f /v DiscoveredKeyManagementServiceIpAddress /t REG_SZ /d "127.0.0.2" %_Nul3%
for /f "tokens=2 delims==" %%x in ('"wmic path %spp% where ID='%app%' get Name /VALUE"') do echo Checking: %%x
echo KMS2038激活.
exit /b
)
if %ESU_ADD% EQU 0 for /f "tokens=2 delims==" %%x in ('"wmic path %spp% where ID='%app%' get Name /VALUE"') do echo Activating: %%x
if %ESU_ADD% EQU 1 for /f "tokens=2 delims==f" %%x in ('"wmic path %spp% where ID='%app%' get Name /VALUE"') do echo Activating: %%x
set ESU_ADD=0
wmic path %spp% where ID='%app%' call Activate %_Nul3%
call set ERRORCODE=%ERRORLEVEL%
if %ERRORCODE% EQU -1073418187 (
echo 产品激活失败: 0xC004F035
if %OSType% EQU Win7 echo Windows 7 cannot be KMS-activated on this computer due to unqualified OEM BIOS.
echo 有关详情请参见自述文件.
exit /b
)
if %ERRORCODE% EQU -1073417728 (
echo 产品激活失败: 0xC004F200
echo Windows needs to rebuild the activation-related files.
echo 有关详情请参见KB2736303.
exit /b
)
if %ERRORCODE% NEQ 0 (
if %sps% EQU SoftwareLicensingService (call :StopService sppsvc) else (call :StopService osppsvc)
wmic path %spp% where ID='%app%' call Activate %_Nul3%
call set ERRORCODE=!ERRORLEVEL!
)
set gpr=0
set gpr2=0
for /f "tokens=2 delims==" %%x in ('"wmic path %spp% where ID='%app%' get GracePeriodRemaining /VALUE"') do (set gpr=%%x&set /a "gpr2=(%%x+1440-1)/1440")
if %ERRORCODE% EQU 0 if %gpr% EQU 0 (
echo 产品激活成功，但剩余期限未增加。
if %OSType% EQU Win7 echo 可能与KB4487266补丁中描述的错误有关
exit /b
)
set Act_OK=0
if %gpr% EQU 43200 if %_officespp% EQU 0 if %winbuild% GEQ 9200 set Act_OK=1
if %gpr% EQU 64800 set Act_OK=1
if %gpr% GTR 259200 if %Win10Gov% EQU 1 set Act_OK=1
if %gpr% EQU 259200 set Act_OK=1
if %ERRORCODE% EQU 0 if %Act_OK% EQU 1 (
echo 产品激活成功
echo 剩余期限: %gpr2% 天 ^(%gpr% 分钟^)
exit /b
)
cmd /c exit /b %ERRORCODE%
if %ERRORCODE% NEQ 0 (
echo 产品激活失败: 0x!=ExitCode!
) else (
echo 产品激活失败
)
echo 剩余期限: %gpr2% 天 ^(%gpr% 分钟^)
set S_OK=0
exit /b

:StopService
sc query %1 | find /i "STOPPED" %_Nul1% || net stop %1 /y %_Nul3%
sc query %1 | find /i "STOPPED" %_Nul1% || sc stop %1 %_Nul3%
goto :eof

:InstallHook
if %_dDbg%==Yes (
set "_para=/d /a"
if %ActWindows% EQU 0 set "_para=!_para! /o"
if %ActOffice% EQU 0 set "_para=!_para! /w"
if %SkipKMS38% EQU 0 set "_para=!_para! /x"
goto :DoDebug
)
if %_verb% EQU 1 (
if %Silent% EQU 0 if %_Debug% EQU 0 (
mode con cols=100 lines=32
%_Nul3% %_psc% "&%_buf%"
if %Unattend% EQU 0 title %_title%
)
echo.&echo %line3%&echo.
echo 安装本地 KMS 模拟器...
)
set "AddExc="
if %winbuild% GEQ 9600 (
  WMIC /NAMESPACE:\\root\Microsoft\Windows\Defender PATH MSFT_MpPreference call Add ExclusionPath="%SystemRoot%\System32\SppExtComObjHook.dll" %_Nul3% && set "AddExc= and Windows Defender exclusion"
)
if %_verb% EQU 1 (
echo.
echo 添加文件%AddExc%...
echo %SystemRoot%\System32\SppExtComObjHook.dll
)
if %AUR% EQU 1 (
call :StopService sppsvc
if %OsppHook% NEQ 0 call :StopService osppsvc
)
for %%# in (SppExtComObjHookAvrf.dll,SppExtComObjHook.dll,SppExtComObjPatcher.dll,SppExtComObjPatcher.exe) do if exist "%SysPath%\%%#" (
	del /f /q "%SysPath%\%%#" %_Nul3%
)
pushd %SysPath%
%_Nul3% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':%xOS%dll\:.*';iex ($f[1]);X 1;"
popd
if %Unattend% EQU 0 title %_title%
if %_verb% EQU 1 (
echo.
echo 添加注册表项...
)
if %SSppHook% NEQ 0 call :CreateIFEOEntry %SppVer%
if %AUR% EQU 1 (call :CreateIFEOEntry osppsvc.exe) else (if %OsppHook% NEQ 0 call :CreateIFEOEntry osppsvc.exe)
if %AUR% EQU 1 if %OSType% EQU Win7 (
call :CreateIFEOEntry SppExtComObj.exe
if %SSppHook% NEQ 0 if not exist %w7inf% (
  if %_verb% EQU 1 (echo.&echo 添加迁移故障保护...&echo %w7inf%)
  if not exist "%SystemRoot%\Migration\WTR" md "%SystemRoot%\Migration\WTR"
  (
  echo [WTR]
  echo Name="KMS_VL_ALL"
  echo.
  echo [WTR.W8]
  echo NotifyUser="No"
  echo.
  echo [System.Registry]
  echo "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sppsvc.exe [*]"
  )>%w7inf%
  )
)
if %AUR% EQU 1 if %OSType% EQU Win8 call :CreateTask
if %_verb% EQU 1 echo.&echo %line3%&echo.
goto :%_rtr%

:RemoveHook
if %_dDbg%==Yes (
set "_para=/d /r"
goto :DoDebug
)
set "RemExc="
if %winbuild% GEQ 9600 (
  for %%# in (NoGenTicket,NoAcquireGT) do reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v %%# /f %_Nul3%
  WMIC /NAMESPACE:\\root\Microsoft\Windows\Defender PATH MSFT_MpPreference call Remove ExclusionPath=%_Hook% Force=True %_Nul3% && set "RemExc= and Windows Defender exclusions"
)
if %_verb% EQU 1 (
if %Silent% EQU 0 if %_Debug% EQU 0 (
mode con cols=100 lines=32
%_Nul3% %_psc% "&%_buf%"
)
echo.&echo %line3%&echo.
echo 移除本地KMS激活...
echo.
echo 删除文件%RemExc%...
)
for %%# in (SppExtComObjHookAvrf.dll,SppExtComObjHook.dll,SppExtComObjPatcher.dll,SppExtComObjPatcher.exe) do if exist "%SysPath%\%%#" (
	if %_verb% EQU 1 echo %SystemRoot%\System32\%%#
	del /f /q "%SysPath%\%%#" %_Nul3%
)
if exist %w7inf% (
	if %_verb% EQU 1 echo %w7inf%
	del /f /q %w7inf%
)
if %_verb% EQU 1 (
echo.
echo 删除注册表项...
)
for %%# in (SppExtComObj.exe,sppsvc.exe,osppsvc.exe) do reg query "%IFEO%\%%#" %_Nul3% && (
  call :RemoveIFEOEntry %%#
)
if %OSType% EQU Win8 schtasks /query /tn "%_TaskEx%" %_Nul3% && (
if %_verb% EQU 1 (
echo.
echo 正在删除计划任务...
echo %_TaskEx%
)
schtasks /delete /f /tn "%_TaskEx%" %_Nul3%
)
goto :eof

:CreateIFEOEntry
if %_verb% EQU 1 (
echo [%IFEO%\%1]
)
reg delete "%IFEO%\%1" /f /v Debugger %_Nul3%
reg add "%IFEO%\%1" /f /v VerifierDlls /t REG_SZ /d "SppExtComObjHook.dll" %_Nul3%
reg add "%IFEO%\%1" /f /v VerifierDebug /t REG_DWORD /d 0x00000000 %_Nul3%
reg add "%IFEO%\%1" /f /v VerifierFlags /t REG_DWORD /d 0x80000000 %_Nul3%
reg add "%IFEO%\%1" /f /v GlobalFlag /t REG_DWORD /d 0x00000100 %_Nul3%
reg add "%IFEO%\%1" /f /v KMS_Emulation /t REG_DWORD /d %KMS_Emulation% %_Nul3%
reg add "%IFEO%\%1" /f /v KMS_ActivationInterval /t REG_DWORD /d %KMS_ActivationInterval% %_Nul3%
reg add "%IFEO%\%1" /f /v KMS_RenewalInterval /t REG_DWORD /d %KMS_RenewalInterval% %_Nul3%
if /i %1 EQU SppExtComObj.exe if %winbuild% GEQ 9600 (
reg add "%IFEO%\%1" /f /v KMS_HWID /t REG_QWORD /d "%KMS_HWID%" %_Nul3%
)
goto :eof

:RemoveIFEOEntry
if %_verb% EQU 1 (
echo [%IFEO%\%1]
)
if /i %1 NEQ osppsvc.exe (
reg delete "%IFEO%\%1" /f %_Nul3%
goto :eof
)
if %OsppHook% EQU 0 (
reg delete "%IFEO%\%1" /f %_Nul3%
)
if %OsppHook% NEQ 0 for %%A in (Debugger,VerifierDlls,VerifierDebug,VerifierFlags,GlobalFlag,KMS_Emulation,KMS_ActivationInterval,KMS_RenewalInterval,Office2010,Office2013,Office2016,Office2019) do reg delete "%IFEO%\%1" /v %%A /f %_Nul3%
reg delete "HKLM\%OPPk%" /f /v KeyManagementServiceName %_Nul3%
reg delete "HKLM\%OPPk%" /f /v KeyManagementServicePort %_Nul3%
goto :eof

:UpdateIFEOEntry
reg add "%IFEO%\%1" /f /v KMS_ActivationInterval /t REG_DWORD /d %KMS_ActivationInterval% %_Nul3%
reg add "%IFEO%\%1" /f /v KMS_RenewalInterval /t REG_DWORD /d %KMS_RenewalInterval% %_Nul3%
if /i %1 EQU SppExtComObj.exe if %winbuild% GEQ 9600 (
reg add "%IFEO%\%1" /f /v KMS_HWID /t REG_QWORD /d "%KMS_HWID%" %_Nul3%
)
if /i %1 EQU sppsvc.exe (
reg add "%IFEO%\SppExtComObj.exe" /f /v KMS_ActivationInterval /t REG_DWORD /d %KMS_ActivationInterval% %_Nul3%
reg add "%IFEO%\SppExtComObj.exe" /f /v KMS_RenewalInterval /t REG_DWORD /d %KMS_RenewalInterval% %_Nul3%
)

:UpdateOSPPEntry
if /i %1 EQU osppsvc.exe (
reg add "HKLM\%OPPk%" /f /v KeyManagementServiceName /t REG_SZ /d "%KMS_IP%" %_Nul3%
reg add "HKLM\%OPPk%" /f /v KeyManagementServicePort /t REG_SZ /d "%KMS_Port%" %_Nul3%
)
goto :eof

:CheckFR
if not exist %_Hook% (
echo.
echo %_err%
echo 当前系统以下文件丢失.
echo "%SystemRoot%\System32\SppExtComObjHook.dll"
echo.
echo 请检查防病毒保护是否关闭或文件路径已添加到排除.
)

for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile %_Hook% SHA1^|findstr /i /v CertUtil') do set "_hash=%%#"
set "_hash=%_hash: =%"
if /i not "%_hash%"=="%_orig%" (
echo.
echo %_err%
echo 当前系统以下文件MD5验证失败.
echo "%SystemRoot%\System32\SppExtComObjHook.dll"
echo Expected: %_orig%
echo Detected: %_hash%
echo.
echo 请检查防病毒保护是否关闭或文件路径已添加到排除.
)

set E_REG=0
if %SSppHook% NEQ 0 for %%A in (VerifierDlls,VerifierDebug,VerifierFlags,GlobalFlag,KMS_Emulation) do (
reg query "%IFEO%\%SppVer%" /v %%A %_Nul3% || set E_REG=1
)
if %E_REG% EQU 1 (
echo.
echo %_err%
echo 当前系统缺少某些或全部必需的注册表键值.
echo [%IFEO%\%SppVer%]
echo VerifierDlls, VerifierDebug, VerifierFlags, GlobalFlag, KMS_Emulation
echo.
echo 请检查防病毒保护是否关闭或文件路径已添加到排除.
)
set E_REG=0
if %OsppHook% NEQ 0 for %%A in (VerifierDlls,VerifierDebug,VerifierFlags,GlobalFlag,KMS_Emulation) do (
reg query "%IFEO%\osppsvc.exe" /v %%A %_Nul3% || set E_REG=1
)
if %E_REG% EQU 1 (
echo.
echo %_err%
echo 当前系统缺少某些或全部必需的注册表键值.
echo [%IFEO%\osppsvc.exe]
echo VerifierDlls, VerifierDebug, VerifierFlags, GlobalFlag, KMS_Emulation
echo.
echo 请检查防病毒保护是否关闭或文件路径已添加到排除.
)

set E_WMI=0
for /f "skip=2 tokens=2*" %%a in ('reg query HKLM\SYSTEM\CurrentControlSet\Services\WinMgmt /v Start %_Nul6%') do if /i %%b equ 0x4 set E_WMI=1
wmic /locale:ms_409 computersystem get Name %_Nul2% | find /i "Name" %_Nul1%
if %errorlevel% NEQ 0 set E_WMI=1
wmic /locale:ms_409 path SoftwareLicensingService get Version %_Nul2% | find /i "Version" %_Nul1%
if %errorlevel% NEQ 0 set E_WMI=1
if %E_WMI% EQU 1 (
echo.
echo %_err%
echo 运行WMI查询检测失败。
echo.
echo 需要验证这些服务是否正常运行:
echo Windows管理规范[WinMgmt]
echo Windows软件保护[sppsvc]
)

goto :eof

:cREG
reg delete "HKLM\%SPPk%\%_wApp%" /f
reg delete "HKLM\%SPPk%\%_oApp%" /f
reg delete "HKLM\%SPPk%" /f /v DisableDnsPublishing
reg delete "HKLM\%SPPk%" /f /v DisableKeyManagementServiceHostCaching
reg delete "HKLM\%SPPk%" /f /v KeyManagementServiceName
reg delete "HKLM\%SPPk%" /f /v KeyManagementServicePort
reg delete "HKU\S-1-5-20\%SPPk%\%_wApp%" /f
reg delete "HKU\S-1-5-20\%SPPk%\%_oApp%" /f
reg delete "HKLM\%OPPk%\%_oA14%" /f
reg delete "HKLM\%OPPk%\%_oApp%" /f
reg delete "HKLM\%OPPk%" /f /v DisableDnsPublishing
reg delete "HKLM\%OPPk%" /f /v DisableKeyManagementServiceHostCaching
reg delete "HKLM\%OPPk%" /f /v KeyManagementServiceName
reg delete "HKLM\%OPPk%" /f /v KeyManagementServicePort
if %OsppHook% EQU 0 (
reg delete "HKLM\%OPPk%" /f
reg delete "HKU\S-1-5-20\%OPPk%" /f
)
goto :eof

:cCache
echo.
echo 清除KMS缓存...
call :cREG %_Nul3%
if %Unattend% NEQ 0 goto :TheEnd
echo.&echo %line3%&echo.
echo 敲任意键继续...
pause >nul
goto :MainMenu

:CreateTask
schtasks /query /tn "%_TaskEx%" %_Nul3% || (
  schtasks /query /tn "%_TaskOs%" %_Nul3% && (
    schtasks /query /tn "%_TaskOs%" /xml >"!_temp!\SvcTrigger.xml"
    schtasks /create /tn "%_TaskEx%" /xml "!_temp!\SvcTrigger.xml" /f %_Nul3%
    schtasks /change /tn "%_TaskEx%" /enable %_Nul3%
    del /f /q "!_temp!\SvcTrigger.xml" %_Nul3%
  )
)
schtasks /query /tn "%_TaskEx%" %_Nul3% || (
pushd %_temp%
%_Nul3% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':spptask\:.*';iex ($f[1]);"
popd
if %Unattend% EQU 0 title %_title%
if exist "!_temp!\SvcTrigger.xml" (
  schtasks /create /tn "%_TaskEx%" /xml "!_temp!\SvcTrigger.xml" /f %_Nul3%
  del /f /q "!_temp!\SvcTrigger.xml" %_Nul3%
  )
)
schtasks /query /tn "%_TaskEx%" %_Nul3% && if %_verb% EQU 1 (
echo.
echo 添加计划任务...
echo %_TaskEx%
)
goto :eof

:CreateReadMe
if not exist "%PUBLIC%\ReadMeAIO.html" (
pushd %PUBLIC%
%_Nul3% %_psc% "$f=[io.file]::ReadAllText('!_batp!') -split ':readme\:.*';iex ($f[1]);"
popd
if %Unattend% EQU 0 title %_title%
)
if exist "%PUBLIC%\ReadMeAIO.html" start "" "%PUBLIC%\ReadMeAIO.html"
timeout /t 2 %_Nul3%
goto :eof

:CreateOEM
cls
set "_oem=!_work!"
copy /y nul "!_work!\#.rw" 1>nul 2>nul && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_oem=!_dsk!")
if exist "!_oem!\$OEM$\" (
echo.&echo %line3%&echo.
echo $OEM$ 文件夹已存在...
echo "!_oem!\$OEM$"
echo.
echo 如果要创建新副本请手动将其删除.
echo.&echo %line3%&echo.
echo 敲任意键继续...
pause >nul
goto :eof
)
if not exist "!_oem!\$OEM$\$$\Setup\Scripts\KMS_VL_ALL_AIO.cmd" mkdir "!_oem!\$OEM$\$$\Setup\Scripts"
copy /y "!_batf!" "!_oem!\$OEM$\$$\Setup\Scripts\KMS_VL_ALL_AIO.cmd" %_Nul3%
(
echo @echo off
echo call %%~dp0KMS_VL_ALL_AIO.cmd /s /a
echo cd \
echo ^(goto^) 2^>nul^&rd /s /q "%%~dp0"
)>"!_oem!\$OEM$\$$\Setup\Scripts\setupcomplete.cmd"
echo.&echo %line3%&echo.
echo $OEM$ 文件夹已创建...
echo.
echo "!_oem!\$OEM$"
echo.&echo %line3%&echo.
echo.
echo 敲任意键继续...
pause >nul
goto :eof

:C2RR2V
set RunR2V=1
set "_SLMGR=%SysPath%\slmgr.vbs"
if %_Debug% EQU 0 (
set "_cscript=cscript //Nologo //B"
) else (
set "_cscript=cscript //Nologo"
)
sc query ClickToRunSvc %_Nul3%
set error1=%errorlevel%
sc query OfficeSvc %_Nul3%
set error2=%errorlevel%
if %error1% EQU 1060 if %error2% EQU 1060 (
goto :%_fC2R%
)
set _Office16=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses16\ProPlus*.xrm-ms" (
  set _Office16=1
)
set _Office15=0
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath" %_Nul6%') do if exist "%%b\root\Licenses\ProPlus*.xrm-ms" (
  set _Office15=1
)
if %_Office16% EQU 0 if %_Office15% EQU 0 (
goto :%_fC2R%
)

:Reg16istry
if %_Office16% EQU 0 goto :Reg15istry
set "_InstallRoot="
set "_ProductIds="
set "_GUID="
set "_Config="
set "_PRIDs="
set "_LicensesPath="
set "_Integrator="
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" %_Nul6%') do if not errorlevel 1 (set "_InstallRoot=%%b\root")
if not "%_InstallRoot%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v PackageGUID" %_Nul6%') do if not errorlevel 1 (set "_GUID=%%b")
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration /v ProductReleaseIds" %_Nul6%') do if not errorlevel 1 (set "_ProductIds=%%b")
  set "_Config=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
  set "_PRIDs=HKLM\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs"
)
set "_LicensesPath=%_InstallRoot%\Licenses16"
set "_Integrator=%_InstallRoot%\integration\integrator.exe"
for /f "skip=2 tokens=2*" %%a in ('"reg query %_PRIDs% /v ActiveConfiguration" %_Nul6%') do set "_PRIDs=%_PRIDs%\%%b"
if "%_ProductIds%"=="" (
if %_Office15% EQU 0 (goto :%_fC2R%) else (goto :Reg15istry)
)
if not exist "%_LicensesPath%\ProPlus*.xrm-ms" (
if %_Office15% EQU 0 (goto :%_fC2R%) else (goto :Reg15istry)
)
if not exist "%_Integrator%" (
if %_Office15% EQU 0 (goto :%_fC2R%) else (goto :Reg15istry)
)
if exist "%_LicensesPath%\Word2019VL_KMS_Client_AE*.xrm-ms" (set "_tag=2019"&set "_ons= 2019") else (set "_tag="&set "_ons= 2016")
if %_Office15% EQU 0 goto :CheckC2R

:Reg15istry
set "_Install15Root="
set "_Product15Ids="
set "_Con15fig="
set "_PR15IDs="
set "_OSPP15Ready="
set "_Licenses15Path="
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath" %_Nul6%') do if not errorlevel 1 (set "_Install15Root=%%b\root")
if not "%_Install15Root%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration /v ProductReleaseIds" %_Nul6%') do if not errorlevel 1 (set "_Product15Ids=%%b")
  set "_Con15fig=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration /v ProductReleaseIds"
  set "_PR15IDs=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\ProductReleaseIDs"
  set "_OSPP15Ready=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration"
)
set "_OSPP15ReadT=REG_SZ"
if "%_Product15Ids%"=="" (
  for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid" %_Nul6%') do if not errorlevel 1 (set "_Product15Ids=%%b")
  set "_Con15fig=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun\propertyBag /v productreleaseid"
  set "_OSPP15Ready=HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun"
  set "_OSPP15ReadT=REG_DWORD"
)
set "_Licenses15Path=%_Install15Root%\Licenses"
if exist "%ProgramFiles%\Microsoft Office\Office15\OSPP.VBS" (
  set "_OSPP15VBS=%ProgramFiles%\Microsoft Office\Office15\OSPP.VBS"
) else if exist "%ProgramW6432%\Microsoft Office\Office15\OSPP.VBS" (
  set "_OSPP15VBS=%ProgramW6432%\Microsoft Office\Office15\OSPP.VBS"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office15\OSPP.VBS" (
  set "_OSPP15VBS=%ProgramFiles(x86)%\Microsoft Office\Office15\OSPP.VBS"
)
if "%_Product15Ids%"=="" (
if %_Office16% EQU 0 (goto :%_fC2R%) else (goto :CheckC2R)
)
if not exist "%_Licenses15Path%\ProPlus*.xrm-ms" (
if %_Office16% EQU 0 (goto :%_fC2R%) else (goto :CheckC2R)
)
if %winbuild% LSS 9200 if not exist "%_OSPP15VBS%" (
if %_Office16% EQU 0 (goto :%_fC2R%) else (goto :CheckC2R)
)

:CheckC2R
set _OMSI=0
if %_Office16% EQU 0 (
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set _OMSI=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set _OMSI=1
)
if %_Office15% EQU 0 (
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set _OMSI=1
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common\InstallRoot /v Path" %_Nul6%') do if exist "%%b\OSPP.VBS" set _OMSI=1
)
if %winbuild% GEQ 9200 (
set _spp=SoftwareLicensingProduct
set _sps=SoftwareLicensingService
set "_vbsi=%_SLMGR% /ilc "
) else (
set _spp=OfficeSoftwareProtectionProduct
set _sps=OfficeSoftwareProtectionService
set _vbsi="!_OSPP15VBS!" /inslic:
)
set "_wmi="
for /f "tokens=2 delims==" %%# in ('"wmic path %_sps% get version /value" %_Nul6%') do set "_wmi=%%#"
if "%_wmi%"=="" (
goto :%_fC2R%
)
set _Retail=0
wmic path %_spp% where "ApplicationID='%_oApp%' AND LicenseStatus='1' AND PartialProductKey<>NULL" get Description %_Nul2% |findstr /V /R "^$" >"!_temp!\crvRetail.txt"
find /i "RETAIL channel" "!_temp!\crvRetail.txt" %_Nul1% && set _Retail=1
find /i "RETAIL(MAK) channel" "!_temp!\crvRetail.txt" %_Nul1% && set _Retail=1
find /i "TIMEBASED_SUB channel" "!_temp!\crvRetail.txt" %_Nul1% && set _Retail=1
set "_copp="
if exist "%SysPath%\msvcr100.dll" (
set _copp=%_temp%
) else if exist "!_InstallRoot!\vfs\System\msvcr100.dll" (
set _copp="!_InstallRoot!\vfs\System"
) else if exist "!_Install15Root!\vfs\System\msvcr100.dll" (
set _copp="!_Install15Root!\vfs\System"
) else if exist "%SystemRoot%\SysWOW64\msvcr100.dll" (
set _copp=%_temp%
set xBit=x86
) else if exist "!_InstallRoot!\vfs\SystemX86\msvcr100.dll" (
set _copp="!_InstallRoot!\vfs\SystemX86"
set xBit=x86
) else if exist "!_Install15Root!\vfs\SystemX86\msvcr100.dll" (
set _copp="!_Install15Root!\vfs\SystemX86"
set xBit=x86
)
if %_Retail% EQU 0 if %_OMSI% EQU 0 if defined _copp (
pushd %_copp%
%_Nul3% %_psc% "$d='!cd!';$f=[io.file]::ReadAllText('!_batp!') -split ':%xBit%exe\:.*';iex ($f[1]);X 1;"
%_Nul3% cleanospp.exe -Licenses
%_Nul3% del /f /q cleanospp.exe
popd
if %Unattend% EQU 0 title %_title%
)
set _O16O365=0
set _C16Msg=0
set _C15Msg=0
if %_Retail% EQU 1 wmic path %_spp% where "ApplicationID='%_oApp%' AND LicenseStatus='1' AND PartialProductKey<>NULL" get LicenseFamily %_Nul2% |findstr /V /R "^$" >"!_temp!\crvRetail.txt"
wmic path %_spp% where "ApplicationID='%_oApp%'" get LicenseFamily %_Nul2% |findstr /V /R "^$" >"!_temp!\crvVolume.txt" 2>&1

if %_Office16% EQU 0 goto :R15V

set _O19Ids=ProPlus2019,ProjectPro2019,VisioPro2019,Standard2019,ProjectStd2019,VisioStd2019,Access2019,SkypeforBusiness2019
set _O16Ids=ProjectPro,VisioPro,Standard,ProjectStd,VisioStd,Access,SkypeforBusiness
set _A19Ids=Excel2019,Outlook2019,PowerPoint2019,Publisher2019,Word2019
set _A16Ids=Excel,Outlook,PowerPoint,Publisher,Word
set _V19Ids=%_O19Ids%,%_A19Ids%
set _V16Ids=Mondo,%_O16Ids%,%_A16Ids%,OneNote
set _R16Ids=%_V16Ids%,Professional,HomeBusiness,HomeStudent,O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem,O365EduCloud
set _RetIds=%_V19Ids%,Professional2019,HomeBusiness2019,HomeStudent2019,%_R16Ids%

echo %_ProductIds%>"!_temp!\crvProductIds.txt"
for %%a in (%_RetIds%,ProPlus) do (
set _%%a=0
)
for %%a in (%_RetIds%) do (
findstr /I /C:"%%aRetail" "!_temp!\crvProductIds.txt" %_Nul1% && set _%%a=1
)
for %%a in (%_V19Ids%) do (
findstr /I /C:"%%aVolume" "!_temp!\crvProductIds.txt" %_Nul1% && (
  find /i "Office19%%aVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _%%a=0) || (set _%%a=1)
  )
)
for %%a in (%_V16Ids%) do (
findstr /I /C:"%%aVolume" "!_temp!\crvProductIds.txt" %_Nul1% && (
  find /i "Office16%%aVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _%%a=0) || (set _%%a=1)
  )
)
reg query %_PRIDs%\ProPlusRetail.16 %_Nul3% && (
  find /i "Office16ProPlusVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _ProPlus=0) || (set _ProPlus=1)
)
reg query %_PRIDs%\ProPlusVolume.16 %_Nul3% && (
  find /i "Office16ProPlusVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _ProPlus=0) || (set _ProPlus=1)
)
if %_Retail% EQU 1 for %%a in (%_RetIds%) do (
findstr /I /C:"%%aRetail" "!_temp!\crvProductIds.txt" %_Nul1% && (
  find /i "Office16%%aR_Retail" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aR_OEM" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aR_Sub" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aR_PIN" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aE5R_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aEDUR_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aMSDNR_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aO365R_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aCO365R_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aVL_MAK" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office16%%aXC2RVL_MAKC2R" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office19%%aR_Retail" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office19%%aR_OEM" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office19%%aMSDNR_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office19%%aVL_MAK" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  )
)
if %_Retail% EQU 1 reg query %_PRIDs%\ProPlusRetail.16 %_Nul3% && (
  find /i "Office16ProPlusR_Retail" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "Office16ProPlusR_OEM" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "Office16ProPlusMSDNR_" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "Office16ProPlusVL_MAK" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
)
find /i "Office16MondoVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "Office16O365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% && (
  for %%a in (O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem,O365EduCloud) do set _%%a=0
  )
)

for %%a in (%_RetIds%,ProPlus) do if !_%%a! EQU 1 (
set _C16Msg=1
)
if %_C16Msg% EQU 1 (
echo.
echo 将 Office C2R 零售版转换为批量版:
)
if %_C16Msg% EQU 0 (if %_Office15% EQU 1 (goto :R15V) else (goto :GVLKC2R))

if !_Mondo! EQU 1 (
call :InsLic Mondo
)
if !_O365ProPlus! EQU 1 (
echo O365ProPlus 2016 Suite ^<-^> Mondo 2016 Licenses
call :InsLic O365ProPlus DRNV7-VGMM2-B3G9T-4BF84-VMFTK
if !_Mondo! EQU 0 call :InsLic Mondo
)
if !_O365Business! EQU 1 if !_O365ProPlus! EQU 0 (
set _O365ProPlus=1
echo O365Business 2016 Suite ^<-^> Mondo 2016 Licenses
call :InsLic O365Business NCHRJ-3VPGW-X73DM-6B36K-3RQ6B
if !_Mondo! EQU 0 call :InsLic Mondo
)
if !_O365SmallBusPrem! EQU 1 if !_O365Business! EQU 0 if !_O365ProPlus! EQU 0 (
set _O365ProPlus=1
echo O365SmallBusPrem 2016 Suite ^<-^> Mondo 2016 Licenses
call :InsLic O365SmallBusPrem 3FBRX-NFP7C-6JWVK-F2YGK-H499R
if !_Mondo! EQU 0 call :InsLic Mondo
)
if !_O365HomePrem! EQU 1 if !_O365SmallBusPrem! EQU 0 if !_O365Business! EQU 0 if !_O365ProPlus! EQU 0 (
set _O365ProPlus=1
echo O365HomePrem 2016 Suite ^<-^> Mondo 2016 Licenses
call :InsLic O365HomePrem 9FNY8-PWWTY-8RY4F-GJMTV-KHGM9
if !_Mondo! EQU 0 call :InsLic Mondo
)
if !_O365EduCloud! EQU 1 if !_O365HomePrem! EQU 0 if !_O365SmallBusPrem! EQU 0 if !_O365Business! EQU 0 if !_O365ProPlus! EQU 0 (
set _O365ProPlus=1
echo O365EduCloud 2016 Suite ^<-^> Mondo 2016 Licenses
call :InsLic O365EduCloud 8843N-BCXXD-Q84H8-R4Q37-T3CPT
if !_Mondo! EQU 0 call :InsLic Mondo
)
if !_O365ProPlus! EQU 1 set _O16O365=1
if !_Mondo! EQU 1 if !_O365ProPlus! EQU 0 (
echo Mondo 2016 Suite
call :InsLic O365ProPlus DRNV7-VGMM2-B3G9T-4BF84-VMFTK
if %_Office15% EQU 1 (goto :R15V) else (goto :GVLKC2R)
)
if !_ProPlus2019! EQU 1 if !_O365ProPlus! EQU 0 (
echo ProPlus 2019 Suite
call :InsLic ProPlus%_tag%
)
if !_ProPlus! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 (
echo ProPlus 2016 Suite -^> ProPlus%_ons% Licenses
call :InsLic ProPlus%_tag%
)
if !_Professional2019! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 (
echo Professional 2019 Suite -^> ProPlus%_ons% Licenses
call :InsLic ProPlus%_tag%
)
if !_Professional! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 (
echo Professional 2016 Suite -^> ProPlus%_ons% Licenses
call :InsLic ProPlus%_tag%
)
if !_Standard2019! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 (
echo Standard 2019 Suite
call :InsLic Standard2019
)
if !_Standard! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_Standard2019! EQU 0 (
echo Standard 2016 Suite -^> Standard%_ons% Licenses
call :InsLic Standard%_tag%
)
for %%a in (ProjectPro,VisioPro,ProjectStd,VisioStd) do if !_%%a2019! EQU 1 (
echo %%a 2019 SKU
if defined _tag (call :InsLic %%a2019) else (call :InsLic %%a)
)
for %%a in (ProjectPro,VisioPro,ProjectStd,VisioStd) do if !_%%a! EQU 1 (
if !_%%a2019! EQU 0 (
  echo %%a 2016 SKU -^> %%a%_ons% Licenses
  call :InsLic %%a%_tag%
  )
)
for %%a in (HomeBusiness2019,HomeStudent2019) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_Standard2019! EQU 0 if !_Standard! EQU 0 (
  set _Standard2019=1
  echo %%a Suite -^> Standard 2019 Licenses
  call :InsLic Standard2019
  )
)
for %%a in (HomeBusiness,HomeStudent) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_Standard2019! EQU 0 if !_Standard! EQU 0 if !_%%a2019! EQU 0 (
  set _Standard2019=1
  echo %%a 2016 Suite -^> Standard%_ons% Licenses
  call :InsLic Standard%_tag%
  )
)
for %%a in (%_A19Ids%,OneNote) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_Standard2019! EQU 0 if !_Standard! EQU 0 (
  echo %%a App
  call :InsLic %%a
  )
)
for %%a in (%_A16Ids%) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_Standard2019! EQU 0 if !_Standard! EQU 0 if !_%%a2019! EQU 0 (
  echo %%a 2016 App
  call :InsLic %%a%_tag%
  )
)
for %%a in (Access2019) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 (
  echo %%a App
  call :InsLic %%a
  )
)
for %%a in (Access) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_Professional2019! EQU 0 if !_Professional! EQU 0 if !_%%a2019! EQU 0 (
  echo %%a 2016 App
  call :InsLic %%a%_tag%
  )
)
for %%a in (SkypeforBusiness2019) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 (
  echo %%a App
  call :InsLic %%a
  )
)
for %%a in (SkypeforBusiness) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus2019! EQU 0 if !_ProPlus! EQU 0 if !_%%a2019! EQU 0 (
  echo %%a 2016 App
  call :InsLic %%a%_tag%
  )
)
if %_Office15% EQU 1 (goto :R15V) else (goto :GVLKC2R)

:R15V
for %%# in ("!_Licenses15Path!\client-issuance-*.xrm-ms") do (
%_cscript% %_vbsi%"!_Licenses15Path!\%%~nx#"
)
%_cscript% %_vbsi%"!_Licenses15Path!\pkeyconfig-office.xrm-ms"

set _O15Ids=Standard,ProjectPro,VisioPro,ProjectStd,VisioStd,Access,Lync
set _A15Ids=Excel,Groove,InfoPath,OneNote,Outlook,PowerPoint,Publisher,Word
set _R15Ids=SPD,Mondo,%_O15Ids%,%_A15Ids%,Professional,HomeBusiness,HomeStudent,O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem
set _V15Ids=Mondo,%_O15Ids%,%_A15Ids%

echo %_Product15Ids%>"!_temp!\crvProduct15s.txt"
for %%a in (%_R15Ids%,ProPlus) do (
set _%%a=0
)
for %%a in (%_R15Ids%) do (
findstr /I /C:"%%aRetail" "!_temp!\crvProduct15s.txt" %_Nul1% && set _%%a=1
)
for %%a in (%_V15Ids%) do (
findstr /I /C:"%%aVolume" "!_temp!\crvProduct15s.txt" %_Nul1% && (
  find /i "Office%%aVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _%%a=0) || (set _%%a=1)
  )
)
reg query %_PR15IDs%\Active\ProPlusRetail\x-none %_Nul3% && (
  find /i "OfficeProPlusVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _ProPlus=0) || (set _ProPlus=1)
)
reg query %_PR15IDs%\Active\ProPlusVolume\x-none %_Nul3% && (
  find /i "OfficeProPlusVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (set _ProPlus=0) || (set _ProPlus=1)
)
if %_Retail% EQU 1 for %%a in (%_R15Ids%) do (
findstr /I /C:"%%aRetail" "!_temp!\crvProduct15s.txt" %_Nul1% && (
  find /i "Office%%aR_Retail" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aR_OEM" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aR_Sub" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aR_PIN" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aMSDNR_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aO365R_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aCO365R_" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  find /i "Office%%aVL_MAK" "!_temp!\crvRetail.txt" %_Nul1% && set _%%a=0
  )
)
if %_Retail% EQU 1 reg query %_PR15IDs%\Active\ProPlusRetail\x-none %_Nul3% && (
  find /i "OfficeProPlusR_Retail" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "OfficeProPlusR_OEM" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "OfficeProPlusMSDNR_" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
  find /i "OfficeProPlusVL_MAK" "!_temp!\crvRetail.txt" %_Nul1% && set _ProPlus=0
)
find /i "OfficeMondoVL_KMS_Client" "!_temp!\crvVolume.txt" %_Nul1% && (
wmic path %spp% where 'ApplicationID="%_oApp%" AND LicenseFamily like "OfficeO365%%"' get LicenseFamily %_Nul2% | find /i "O365" %_Nul1% && (
  for %%a in (O365ProPlus,O365Business,O365SmallBusPrem,O365HomePrem) do set _%%a=0
  )
)

for %%a in (%_R15Ids%,ProPlus) do if !_%%a! EQU 1 (
set _C15Msg=1
)
if %_C15Msg% EQU 1 if %_C16Msg% EQU 0 (
echo.
echo 将 Office C2R 零售版转换为批量版:
)
if %_C15Msg% EQU 0 goto :GVLKC2R

if !_Mondo! EQU 1 (
call :Ins15Lic Mondo
)
if !_O365ProPlus! EQU 1 if !_O16O365! EQU 0 (
echo O365ProPlus 2013 Suite ^<-^> Mondo 2013 Licenses
call :Ins15Lic O365ProPlus DRNV7-VGMM2-B3G9T-4BF84-VMFTK
if !_Mondo! EQU 0 call :Ins15Lic Mondo
)
if !_O365SmallBusPrem! EQU 1 if !_O365ProPlus! EQU 0 if !_O16O365! EQU 0 (
set _O365ProPlus=1
echo O365SmallBusPrem 2013 Suite ^<-^> Mondo 2013 Licenses
call :Ins15Lic O365SmallBusPrem 3FBRX-NFP7C-6JWVK-F2YGK-H499R
if !_Mondo! EQU 0 call :Ins15Lic Mondo
)
if !_O365HomePrem! EQU 1 if !_O365SmallBusPrem! EQU 0 if !_O365ProPlus! EQU 0 if !_O16O365! EQU 0 (
set _O365ProPlus=1
echo O365HomePrem 2013 Suite ^<-^> Mondo 2013 Licenses
call :Ins15Lic O365HomePrem 9FNY8-PWWTY-8RY4F-GJMTV-KHGM9
if !_Mondo! EQU 0 call :Ins15Lic Mondo
)
if !_O365Business! EQU 1 if !_O365HomePrem! EQU 0 if !_O365SmallBusPrem! EQU 0 if !_O365ProPlus! EQU 0 if !_O16O365! EQU 0 (
set _O365ProPlus=1
echo O365Business 2013 Suite ^<-^> Mondo 2013 Licenses
call :Ins15Lic O365Business MCPBN-CPY7X-3PK9R-P6GTT-H8P8Y
if !_Mondo! EQU 0 call :Ins15Lic Mondo
)
if !_Mondo! EQU 1 if !_O365ProPlus! EQU 0 if !_O16O365! EQU 0 (
echo Mondo 2013 Suite
call :Ins15Lic O365ProPlus DRNV7-VGMM2-B3G9T-4BF84-VMFTK
goto :GVLKC2R
)
if !_SPD! EQU 1 if !_Mondo! EQU 0 if !_O365ProPlus! EQU 0 (
echo SharePoint Designer 2013 App -^> Mondo 2013 Licenses
call :Ins15Lic Mondo
goto :GVLKC2R
)
if !_ProPlus! EQU 1 if !_O365ProPlus! EQU 0 (
echo ProPlus 2013 Suite
call :Ins15Lic ProPlus
)
if !_Professional! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 (
echo Professional 2013 Suite -^> ProPlus 2013 Licenses
call :Ins15Lic ProPlus
)
if !_Standard! EQU 1 if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 if !_Professional! EQU 0 (
echo Standard 2013 Suite
call :Ins15Lic Standard
)
for %%a in (ProjectPro,VisioPro,ProjectStd,VisioStd) do if !_%%a! EQU 1 (
echo %%a 2013 SKU
call :Ins15Lic %%a
)
for %%a in (HomeBusiness,HomeStudent) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 if !_Professional! EQU 0 if !_Standard! EQU 0 (
  set _Standard=1
  echo %%a 2013 Suite -^> Standard 2013 Licenses
  call :Ins15Lic Standard
  )
)
for %%a in (%_A15Ids%) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 if !_Professional! EQU 0 if !_Standard! EQU 0 (
  echo %%a 2013 App
  call :Ins15Lic %%a
  )
)
for %%a in (Access) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 if !_Professional! EQU 0 (
  echo %%a 2013 App
  call :Ins15Lic %%a
  )
)
for %%a in (Lync) do if !_%%a! EQU 1 (
if !_O365ProPlus! EQU 0 if !_ProPlus! EQU 0 (
  echo SkypeforBusiness 2015 App
  call :Ins15Lic %%a
  )
)
goto :GVLKC2R

:InsLic
set "_ID=%1Volume"
set "_pkey="
if not "%2"=="" (
set "_ID=%1Retail"
set "_pkey=PidKey=%2"
)
reg delete %_Config% /f /v %_ID%.OSPPReady %_Nul3%
"!_Integrator!" /I /License PRIDName=%_ID%.16 %_pkey% PackageGUID="%_GUID%" PackageRoot="!_InstallRoot!" %_Nul1%
reg add %_Config% /f /v %_ID%.OSPPReady /t REG_SZ /d 1 %_Nul1%
reg query %_Config% /v ProductReleaseIds | findstr /I "%_ID%" %_Nul1%
if %errorlevel% NEQ 0 (
for /f "skip=2 tokens=2*" %%a in ('reg query %_Config% /v ProductReleaseIds') do reg add %_Config% /v ProductReleaseIds /t REG_SZ /d "%%b,%_ID%" /f %_Nul1%
)
exit /b

:Ins15Lic
set "_ID=%1Volume"
set "_patt=%1VL_"
set "_pkey="
if not "%2"=="" (
set "_ID=%1Retail"
set "_patt=%1R_"
set "_pkey=%2"
)
reg delete %_OSPP15Ready% /f /v %_ID%.OSPPReady %_Nul3%
for %%# in ("!_Licenses15Path!\%_patt%*.xrm-ms") do (
%_cscript% %_vbsi%"!_Licenses15Path!\%%~nx#"
)
if defined _pkey wmic path %_sps% where version='%_wmi%' call InstallProductKey ProductKey="%_pkey%" %_Nul3%
reg add %_OSPP15Ready% /f /v %_ID%.OSPPReady /t %_OSPP15ReadT% /d 1 %_Nul1%
reg query %_Con15fig% | findstr /I "%_ID%" %_Nul1%
if %errorlevel% NEQ 0 (
for /f "skip=2 tokens=2*" %%a in ('reg query %_Con15fig%') do reg add %_Con15fig% /t REG_SZ /d "%%b,%_ID%" /f %_Nul1%
)
exit /b

:GVLKC2R
if %_Office16% EQU 1 (
for %%a in (%_RetIds%,ProPlus) do set "_%%a="
)
if %_Office15% EQU 1 (
for %%a in (%_R15Ids%,ProPlus) do set "_%%a="
)
if %winbuild% GEQ 9200 wmic path %_sps% where version='%_wmi%' call RefreshLicenseStatus %_Nul3%
if exist "%SysPath%\spp\store_test\2.0\tokens.dat" if defined _copp (
%_cscript% %_SLMGR% /rilc
)
goto :%_sC2R%

:casVm
cls
mode con cols=100 lines=32
%_Nul3% %_psc% "&%_buf%"
title 检测激活状态 [vbs命令]
setlocal EnableDelayedExpansion
set _sO16vbs=0
set _sO15vbs=0
if exist "%ProgramFiles%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
) else if exist "%ProgramW6432%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office15\ospp.vbs" (
  set _sO15vbs=1
)
echo %line2%
echo ***                   Windows 激活状态                     ***
echo %line2%
copy /y %Windir%\System32\slmgr.vbs "!_temp!\slmgr.vbs" >nul 2>&1
sc start sppsvc trigger=timer;sessionid=0 >nul 2>&1
cscript //nologo "!_temp!\slmgr.vbs" /dli || (echo Error executing slmgr.vbs&del /f /q "!_temp!\slmgr.vbs"&goto :casVend)
cscript //nologo "!_temp!\slmgr.vbs" /xpr
del /f /q "!_temp!\slmgr.vbs" >nul 2>&1
echo %line3%

:casVo16
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016 %_bit%位 激活状态              ***
) else (
echo ***              Office 2013/2016 激活状态               ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVo13
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\16.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016 32位 激活状态               ***
) else (
echo ***              Office 2013/2016 激活状态                ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVo13
if %_sO16vbs% EQU 1 goto :casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2013 %_bit%位 激活状态               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\15.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2013 32位 激活状态               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVo10
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2010 %_bit%位 激活状态               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)
if %_wow%==0 goto :casVc16
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\Common\InstallRoot /v Path" 2^>nul') do (set "office=%%b")
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2010 32位 激活激活状态               ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc16
reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath >nul 2>&1 || goto :casVc13
set office=
for /f "skip=2 tokens=2*" %%a in ('"reg query HKLM\SOFTWARE\Microsoft\Office\ClickToRun /v InstallPath" 2^>nul') do (set "office=%%b\Office16")
if exist "!office!\ospp.vbs" (
set _sO16vbs=1
echo.
echo %line2%
if %_sO15vbs% EQU 0 (
echo ***              Office 2016-2021 C2R 激活状态             ***
) else (
echo ***              Office 2013-2021 Status             ***
)
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc13
if %_sO16vbs% EQU 1 goto :casVc10
reg query HKLM\SOFTWARE\Microsoft\Office\15.0\ClickToRun /v InstallPath >nul 2>&1 || goto :casVc10
set office=
if exist "%ProgramFiles%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramFiles%\Microsoft Office\Office15"
) else if exist "%ProgramW6432%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramW6432%\Microsoft Office\Office15"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office15\ospp.vbs" (
  set "office=%ProgramFiles(x86)%\Microsoft Office\Office15"
)
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2013 C2R 激活状态                ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVc10
if %_wow%==0 reg query HKLM\SOFTWARE\Microsoft\Office\14.0\CVH /f Click2run /k >nul 2>&1 || goto :casVend
if %_wow%==1 reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Office\14.0\CVH /f Click2run /k >nul 2>&1 || goto :casVend
set office=
if exist "%ProgramFiles%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramFiles%\Microsoft Office\Office14"
) else if exist "%ProgramW6432%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramW6432%\Microsoft Office\Office14"
) else if exist "%ProgramFiles(x86)%\Microsoft Office\Office14\ospp.vbs" (
  set "office=%ProgramFiles(x86)%\Microsoft Office\Office14"
)
if exist "!office!\ospp.vbs" (
echo.
echo %line2%
echo ***              Office 2010 C2R 激活状态                ***
echo %line2%
cscript //nologo "!office!\ospp.vbs" /dstatus
)

:casVend
echo.
echo 敲任意键继续...
pause >nul
goto :eof

:casWm
cls
mode con cols=100 lines=32
%_Nul3% %_psc% "&%_buf%"
title 检测激活状态 [wmic命令]
setlocal
set wspp=SoftwareLicensingProduct
set wsps=SoftwareLicensingService
set ospp=OfficeSoftwareProtectionProduct
set osps=OfficeSoftwareProtectionService
set winApp=55c92734-d682-4d71-983e-d6ec3f16059f
set o14App=59a52881-a989-479d-af46-f275c6370663
set o15App=0ff1ce15-a989-479d-af46-f275c6370663
for %%# in (spp_get,ospp_get,cW1nd0ws,sppw,c0ff1ce15,sppo,osppsvc,ospp14,ospp15) do set "%%#="
set "spp_get=Description, DiscoveredKeyManagementServiceMachineName, DiscoveredKeyManagementServiceMachinePort, EvaluationEndDate, GracePeriodRemaining, ID, KeyManagementServiceMachine, KeyManagementServicePort, KeyManagementServiceProductKeyID, LicenseStatus, LicenseStatusReason, Name, PartialProductKey, ProductKeyID, VLActivationInterval, VLRenewalInterval"
set "ospp_get=%spp_get%"
if %winbuild% GEQ 9200 set "spp_get=%spp_get%, DiscoveredKeyManagementServiceMachineIpAddress, KeyManagementServiceLookupDomain, ProductKeyChannel, VLActivationTypeEnabled"
set OsppHook=1
sc query osppsvc >nul 2>&1
if %errorlevel% EQU 1060 set OsppHook=0

sc start sppsvc trigger=timer;sessionid=0 >nul 2>&1
call :casWpkey %wspp% %winApp% cW1nd0ws sppw
if %winbuild% GEQ 9200 call :casWpkey %wspp% %o15App% c0ff1ce15 sppo
if %OsppHook% NEQ 0 (
sc start osppsvc >nul 2>&1
call :casWpkey %ospp% %o14App% osppsvc ospp14
if %winbuild% LSS 9200 call :casWpkey %ospp% %o15App% osppsvc ospp15
)

echo %line2%
echo ***                   Windows 激活状态                     ***
echo %line2%
if not defined cW1nd0ws (
echo.
echo 错误：找不到产品密钥.
goto :casWcon
)
set winID=1
for /f "tokens=2 delims==" %%# in ('"wmic path %wspp% where (ApplicationID='%winApp%' and PartialProductKey is not null) get ID /value"') do (
  set "chkID=%%#"
  call :casWdet "%wspp%" "%wsps%" "%spp_get%"
  call :casWout
  echo %line3%
  echo.
)

:casWcon
set winID=0
set verbose=1
if not defined c0ff1ce15 (
if defined osppsvc goto :casWospp
goto :casWend
)
echo %line2%
echo ***                   Office 激活状态                     ***
echo %line2%
for /f "tokens=2 delims==" %%# in ('"wmic path %wspp% where (ApplicationID='%o15App%' and PartialProductKey is not null) get ID /value"') do (
  set "chkID=%%#"
  call :casWdet "%wspp%" "%wsps%" "%spp_get%"
  call :casWout
  echo %line3%
  echo.
)
set verbose=0
if defined osppsvc goto :casWospp
goto :casWend

:casWospp
if %verbose%==1 (
echo %line2%
echo ***                   Office 激活状态                      ***
echo %line2%
)
if defined ospp15 for /f "tokens=2 delims==" %%# in ('"wmic path %ospp% where (ApplicationID='%o15App%' and PartialProductKey is not null) get ID /value"') do (
  set "chkID=%%#"
  call :casWdet "%ospp%" "%osps%" "%ospp_get%"
  call :casWout
  echo %line3%
  echo.
)
if defined ospp14 for /f "tokens=2 delims==" %%# in ('"wmic path %ospp% where (ApplicationID='%o14App%' and PartialProductKey is not null) get ID /value"') do (
  set "chkID=%%#"
  call :casWdet "%ospp%" "%osps%" "%ospp_get%"
  call :casWout
  echo %line3%
  echo.
)
goto :casWend

:casWpkey
wmic path %1 where (ApplicationID='%2' and PartialProductKey is not null) get ID /value 2>nul | findstr /i ID 1>nul && (set %3=1&set %4=1)
exit /b

:casWdet
for %%# in (%~3) do set "%%#="
if %~1 EQU %ospp% for %%# in (DiscoveredKeyManagementServiceMachineIpAddress, KeyManagementServiceLookupDomain, ProductKeyChannel, VLActivationTypeEnabled) do set "%%#="
set "cKmsClient="
set "cTblClient="
set "cAvmClient="
set "ExpireMsg="
set "_xpr="
for /f "tokens=* delims=" %%# in ('"wmic path %~1 where ID='%chkID%' get %~3 /value" ^| findstr ^=') do set "%%#"

set /a _gpr=(GracePeriodRemaining+1440-1)/1440
echo %Description%| findstr /i VOLUME_KMSCLIENT 1>nul && (set cKmsClient=1&set _mTag=Volume)
echo %Description%| findstr /i TIMEBASED_ 1>nul && (set cTblClient=1&set _mTag=Timebased)
echo %Description%| findstr /i VIRTUAL_MACHINE_ACTIVATION 1>nul && (set cAvmClient=1&set _mTag=Automatic VM)
cmd /c exit /b %LicenseStatusReason%
set "LicenseReason=%=ExitCode%"
set "LicenseMsg=剩余时间: %GracePeriodRemaining% 分钟 (%_gpr% 天)"
if %_gpr% GEQ 1 for /f "tokens=* delims=" %%# in ('%_psc% "$([DateTime]::Now.addMinutes(%GracePeriodRemaining%)).ToString('yyyy-MM-dd HH:mm:ss')" 2^>nul') do set "_xpr=%%#"
title 检查激活状态 [wmic]

if %LicenseStatus% EQU 0 (
set "License=未授权"
set "LicenseMsg="
)
if %LicenseStatus% EQU 1 (
set "License=已授权"
set "LicenseMsg="
if %GracePeriodRemaining% EQU 0 (
  if %winID% EQU 1 (set "ExpireMsg=此计算机已永久激活.") else (set "ExpireMsg=产品已永久激活.")
  ) else (
  set "LicenseMsg=%_mTag% 激活期限: %GracePeriodRemaining% 分钟 (%_gpr% 天)"
  if defined _xpr set "ExpireMsg=%_mTag% 激活期限 %_xpr%"
  )
)
if %LicenseStatus% EQU 2 (
set "License=Initial grace period"
if defined _xpr set "ExpireMsg=Initial grace period ends %_xpr%"
)
if %LicenseStatus% EQU 3 (
set "License=Additional grace period (KMS license expired or hardware out of tolerance)"
if defined _xpr set "ExpireMsg=Additional grace period ends %_xpr%"
)
if %LicenseStatus% EQU 4 (
set "License=Non-genuine grace period."
if defined _xpr set "ExpireMsg=Non-genuine grace period ends %_xpr%"
)
if %LicenseStatus% EQU 6 (
set "License=Extended grace period"
if defined _xpr set "ExpireMsg=Extended grace period ends %_xpr%"
)
if %LicenseStatus% EQU 5 (
set "License=Notification"
  if "%LicenseReason%"=="C004F200" (set "LicenseMsg=Notification Reason: 0xC004F200 (non-genuine)."
  ) else if "%LicenseReason%"=="C004F009" (set "LicenseMsg=Notification Reason: 0xC004F009 (grace time expired)."
  ) else (set "LicenseMsg=Notification Reason: 0x%LicenseReason%"
  )
)
if %LicenseStatus% GTR 6 (
set "License=Unknown"
set "LicenseMsg="
)
if not defined cKmsClient exit /b

if %KeyManagementServicePort%==0 set KeyManagementServicePort=1688
set "KmsReg=已注册的 KMS 计算机名称: %KeyManagementServiceMachine%:%KeyManagementServicePort%"
if "%KeyManagementServiceMachine%"=="" set "KmsReg=已注册的 KMS 计算机名称: KMS 名称不可用"

if %DiscoveredKeyManagementServiceMachinePort%==0 set DiscoveredKeyManagementServiceMachinePort=1688
set "KmsDns=KMS machine name from DNS: %DiscoveredKeyManagementServiceMachineName%:%DiscoveredKeyManagementServiceMachinePort%"
if "%DiscoveredKeyManagementServiceMachineName%"=="" set "KmsDns=DNS 自动发现: KMS 名称不可用"

for /f "tokens=* delims=" %%# in ('"wmic path %~2 get ClientMachineID, KeyManagementServiceHostCaching /value" ^| findstr ^=') do set "%%#"
if /i %KeyManagementServiceHostCaching%==True (set KeyManagementServiceHostCaching=Enabled) else (set KeyManagementServiceHostCaching=Disabled)

if %winbuild% LSS 9200 exit /b
if %~1 EQU %ospp% exit /b

if "%DiscoveredKeyManagementServiceMachineIpAddress%"=="" set "DiscoveredKeyManagementServiceMachineIpAddress=not available"

if "%KeyManagementServiceLookupDomain%"=="" set "KeyManagementServiceLookupDomain="

if %VLActivationTypeEnabled% EQU 3 (
set VLActivationType=Token
) else if %VLActivationTypeEnabled% EQU 2 (
set VLActivationType=KMS
) else if %VLActivationTypeEnabled% EQU 1 (
set VLActivationType=AD
) else (
set VLActivationType=All
)
exit /b

:casWout
echo.
echo 名称: %Name%
echo 描述: %Description%
echo 激活 ID: %ID%
echo 扩展 PID: %ProductKeyID%
if defined ProductKeyChannel echo 产品密钥类型: %ProductKeyChannel%
echo 部分产品密钥: %PartialProductKey%
echo 许可证状态: %License%
if defined LicenseMsg echo %LicenseMsg%
if not %LicenseStatus%==0 if not %EvaluationEndDate:~0,8%==16010101 echo Evaluation End Date: %EvaluationEndDate:~0,4%-%EvaluationEndDate:~4,2%-%EvaluationEndDate:~6,2% %EvaluationEndDate:~8,2%:%EvaluationEndDate:~10,2% UTC
if not defined cKmsClient (
if defined ExpireMsg echo.&echo.    %ExpireMsg%
exit /b
)
if defined VLActivationTypeEnabled echo 已配置的激活类型: %VLActivationType%
echo.
if not %LicenseStatus%==1 (
echo 激活产品以更新 KMS 客户端信息值.
exit /b
)
echo 最新激活信息:
echo 密钥管理服务客户端信息
echo.    客户端 ID (CMID): %ClientMachineID%
echo.    %KmsDns%
echo.    %KmsReg%
if defined DiscoveredKeyManagementServiceMachineIpAddress echo.    KMS 计算机 IP 地址: %DiscoveredKeyManagementServiceMachineIpAddress%
echo.    KMS 计算机扩展 PID: %KeyManagementServiceProductKeyID%
echo.    激活间隔: %VLActivationInterval% 分钟
echo.    更新间隔: %VLRenewalInterval% 分钟
echo.    KMS 主机缓存: %KeyManagementServiceHostCaching%
if defined KeyManagementServiceLookupDomain echo.    KMS SRV 记录查找域: %KeyManagementServiceLookupDomain%
if defined ExpireMsg echo.&echo.    %ExpireMsg%
exit /b

:casWend
echo.
echo 敲任意键继续...
pause >nul
goto :eof

:keys
if "%~1"=="" exit /b
goto :%1 %_Nul2%

:: Windows 10 [RS5]
:32d2fab3-e4a8-42c2-923b-4bf4fd13e6ee
set "_key=M7XTQ-FN8P6-TTKYV-9D4CC-J462D" &:: Enterprise LTSC 2019
exit /b

:7103a333-b8c8-49cc-93ce-d37c09687f92
set "_key=92NFX-8DJQP-P6BBQ-THF9C-7CG2H" &:: Enterprise LTSC 2019 N
exit /b

:ec868e65-fadf-4759-b23e-93fe37f2cc29
set "_key=CPWHC-NT2C7-VYW78-DHDB2-PG3GK" &:: Enterprise for Virtual Desktops
exit /b

:0df4f814-3f57-4b8b-9a9d-fddadcd69fac
set "_key=NBTWJ-3DR69-3C4V8-C26MC-GQ9M6" &:: Lean
exit /b

:: Windows 10 [RS3]
:82bbc092-bc50-4e16-8e18-b74fc486aec3
set "_key=NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J" &:: Pro Workstation
exit /b

:4b1571d3-bafb-4b40-8087-a961be2caf65
set "_key=9FNHH-K3HBT-3W4TD-6383H-6XYWF" &:: Pro Workstation N
exit /b

:e4db50ea-bda1-4566-b047-0ca50abc6f07
set "_key=7NBT4-WGBQX-MP4H7-QXFF8-YP3KX" &:: Enterprise Remote Server
exit /b

:: Windows 10 [RS2]
:e0b2d383-d112-413f-8a80-97f373a5820c
set "_key=YYVX9-NTFWV-6MDM3-9PT4T-4M68B" &:: Enterprise G
exit /b

:e38454fb-41a4-4f59-a5dc-25080e354730
set "_key=44RPN-FTY23-9VTTB-MP9BX-T84FV" &:: Enterprise G N
exit /b

:: Windows 10 [RS1]
:2d5a5a60-3040-48bf-beb0-fcd770c20ce0
set "_key=DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ" &:: Enterprise 2016 LTSB
exit /b

:9f776d83-7156-45b2-8a5c-359b9c9f22a3
set "_key=QFFDN-GRT3P-VKWWX-X7T3R-8B639" &:: Enterprise 2016 LTSB N
exit /b

:3f1afc82-f8ac-4f6c-8005-1d233e606eee
set "_key=6TP4R-GNPTD-KYYHQ-7B7DP-J447Y" &:: Pro Education
exit /b

:5300b18c-2e33-4dc2-8291-47ffcec746dd
set "_key=YVWGF-BXNMC-HTQYQ-CPQ99-66QFC" &:: Pro Education N
exit /b

:: Windows 10 [TH]
:58e97c99-f377-4ef1-81d5-4ad5522b5fd8
set "_key=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99" &:: Home
exit /b

:7b9e1751-a8da-4f75-9560-5fadfe3d8e38
set "_key=3KHY7-WNT83-DGQKR-F7HPR-844BM" &:: Home N
exit /b

:cd918a57-a41b-4c82-8dce-1a538e221a83
set "_key=7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH" &:: Home Single Language
exit /b

:a9107544-f4a0-4053-a96a-1479abdef912
set "_key=PVMJN-6DFY6-9CCP6-7BKTT-D3WVR" &:: Home China
exit /b

:2de67392-b7a7-462a-b1ca-108dd189f588
set "_key=W269N-WFGWX-YVC9B-4J6C9-T83GX" &:: Pro
exit /b

:a80b5abf-76ad-428b-b05d-a47d2dffeebf
set "_key=MH37W-N47XK-V7XM9-C7227-GCQG9" &:: Pro N
exit /b

:e0c42288-980c-4788-a014-c080d2e1926e
set "_key=NW6C2-QMPVW-D7KKK-3GKT6-VCFB2" &:: Education
exit /b

:3c102355-d027-42c6-ad23-2e7ef8a02585
set "_key=2WH4N-8QGBV-H22JP-CT43Q-MDWWJ" &:: Education N
exit /b

:73111121-5638-40f6-bc11-f1d7b0d64300
set "_key=NPPR9-FWDCX-D2C8J-H872K-2YT43" &:: Enterprise
exit /b

:e272e3e2-732f-4c65-a8f0-484747d0d947
set "_key=DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4" &:: Enterprise N
exit /b

:7b51a46c-0c04-4e8f-9af4-8496cca90d5e
set "_key=WNMTR-4C88C-JK8YV-HQ7T2-76DF9" &:: Enterprise 2015 LTSB
exit /b

:87b838b7-41b6-4590-8318-5797951d8529
set "_key=2F77B-TNFGY-69QQF-B8YKP-D69TJ" &:: Enterprise 2015 LTSB N
exit /b

:: Windows Server 2021 [Fe]
:9bd77860-9b31-4b7b-96ad-2564017315bf
set "_key=VDYBN-27WPP-V4HQT-9VMD4-VMK7H" &:: Standard
exit /b

:ef6cfc9f-8c5d-44ac-9aad-de6a2ea0ae03
set "_key=WX4NM-KYWYW-QJJR4-XV3QB-6VM33" &:: Datacenter
exit /b

:8c8f0ad3-9a43-4e05-b840-93b8d1475cbc
set "_key=6N379-GGTMK-23C6M-XVVTC-CKFRQ" &:: Azure Core
exit /b

:f5e9429c-f50b-4b98-b15c-ef92eb5cff39
set "_key=67KN8-4FYJW-2487Q-MQ2J7-4C4RG" &:: Standard ACor
exit /b

:39e69c41-42b4-4a0a-abad-8e3c10a797cc
set "_key=QFND9-D3Y9C-J3KKY-6RPVP-2DPYV" &:: Datacenter ACor
exit /b

:19b5e0fb-4431-46bc-bac1-2f1873e4ae73
set "_key=NTBV8-9K7Q8-V27C6-M2BTV-KHMXV" &:: Azure Datacenter - ServerTurbine
exit /b

:: Windows Server 2019 [RS5]
:de32eafd-aaee-4662-9444-c1befb41bde2
set "_key=N69G4-B89J2-4G8F4-WWYCC-J464C" &:: Standard
exit /b

:34e1ae55-27f8-4950-8877-7a03be5fb181
set "_key=WMDGN-G9PQG-XVVXX-R3X43-63DFG" &:: Datacenter
exit /b

:034d3cbb-5d4b-4245-b3f8-f84571314078
set "_key=WVDHN-86M7X-466P6-VHXV7-YY726" &:: Essentials
exit /b

:a99cc1f0-7719-4306-9645-294102fbff95
set "_key=FDNH6-VW9RW-BXPJ7-4XTYG-239TB" &:: Azure Core
exit /b

:73e3957c-fc0c-400d-9184-5f7b6f2eb409
set "_key=N2KJX-J94YW-TQVFB-DG9YT-724CC" &:: Standard ACor
exit /b

:90c362e5-0da1-4bfd-b53b-b87d309ade43
set "_key=6NMRW-2C8FM-D24W7-TQWMY-CWH2D" &:: Datacenter ACor
exit /b

:8de8eb62-bbe0-40ac-ac17-f75595071ea3
set "_key=GRFBW-QNDC4-6QBHG-CCK3B-2PR88" &:: ServerARM64
exit /b

:: Windows Server 2016 [RS4]
:43d9af6e-5e86-4be8-a797-d072a046896c
set "_key=K9FYF-G6NCK-73M32-XMVPY-F9DRR" &:: ServerARM64
exit /b

:: Windows Server 2016 [RS3]
:61c5ef22-f14f-4553-a824-c4b31e84b100
set "_key=PTXN8-JFHJM-4WC78-MPCBR-9W4KR" &:: Standard ACor
exit /b

:e49c08e7-da82-42f8-bde2-b570fbcae76c
set "_key=2HXDN-KRXHB-GPYC7-YCKFJ-7FVDG" &:: Datacenter ACor
exit /b

:: Windows Server 2016 [RS1]
:8c1c5410-9f39-4805-8c9d-63a07706358f
set "_key=WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY" &:: Standard
exit /b

:21c56779-b449-4d20-adfc-eece0e1ad74b
set "_key=CB7KF-BWN84-R7R2Y-793K2-8XDDG" &:: Datacenter
exit /b

:2b5a1b0f-a5ab-4c54-ac2f-a6d94824a283
set "_key=JCKRF-N37P4-C2D82-9YXRT-4M63B" &:: Essentials
exit /b

:7b4433f4-b1e7-4788-895a-c45378d38253
set "_key=QN4C6-GBJD2-FB422-GHWJK-GJG2R" &:: Cloud Storage
exit /b

:3dbf341b-5f6c-4fa7-b936-699dce9e263f
set "_key=VP34G-4NPPG-79JTQ-864T4-R3MQX" &:: Azure Core
exit /b

:: Windows 8.1
:fe1c3238-432a-43a1-8e25-97e7d1ef10f3
set "_key=M9Q9P-WNJJT-6PXPY-DWX8H-6XWKK" &:: Core
exit /b

:78558a64-dc19-43fe-a0d0-8075b2a370a3
set "_key=7B9N3-D94CG-YTVHR-QBPX3-RJP64" &:: Core N
exit /b

:c72c6a1d-f252-4e7e-bdd1-3fca342acb35
set "_key=BB6NG-PQ82V-VRDPW-8XVD2-V8P66" &:: Core Single Language
exit /b

:db78b74f-ef1c-4892-abfe-1e66b8231df6
set "_key=NCTT7-2RGK8-WMHRF-RY7YQ-JTXG3" &:: Core China
exit /b

:ffee456a-cd87-4390-8e07-16146c672fd0
set "_key=XYTND-K6QKT-K2MRH-66RTM-43JKP" &:: Core ARM
exit /b

:c06b6981-d7fd-4a35-b7b4-054742b7af67
set "_key=GCRJD-8NW9H-F2CDX-CCM8D-9D6T9" &:: Pro
exit /b

:7476d79f-8e48-49b4-ab63-4d0b813a16e4
set "_key=HMCNV-VVBFX-7HMBH-CTY9B-B4FXY" &:: Pro N
exit /b

:096ce63d-4fac-48a9-82a9-61ae9e800e5f
set "_key=789NJ-TQK6T-6XTH8-J39CJ-J8D3P" &:: Pro with Media Center
exit /b

:81671aaf-79d1-4eb1-b004-8cbbe173afea
set "_key=MHF9N-XY6XB-WVXMC-BTDCT-MKKG7" &:: Enterprise
exit /b

:113e705c-fa49-48a4-beea-7dd879b46b14
set "_key=TT4HM-HN7YT-62K67-RGRQJ-JFFXW" &:: Enterprise N
exit /b

:0ab82d54-47f4-4acb-818c-cc5bf0ecb649
set "_key=NMMPB-38DD4-R2823-62W8D-VXKJB" &:: Embedded Industry Pro
exit /b

:cd4e2d9f-5059-4a50-a92d-05d5bb1267c7
set "_key=FNFKF-PWTVT-9RC8H-32HB2-JB34X" &:: Embedded Industry Enterprise
exit /b

:f7e88590-dfc7-4c78-bccb-6f3865b99d1a
set "_key=VHXM3-NR6FT-RY6RT-CK882-KW2CJ" &:: Embedded Industry Automotive
exit /b

:e9942b32-2e55-4197-b0bd-5ff58cba8860
set "_key=3PY8R-QHNP9-W7XQD-G6DPH-3J2C9" &:: with Bing
exit /b

:c6ddecd6-2354-4c19-909b-306a3058484e
set "_key=Q6HTR-N24GM-PMJFP-69CD8-2GXKR" &:: with Bing N
exit /b

:b8f5e3a3-ed33-4608-81e1-37d6c9dcfd9c
set "_key=KF37N-VDV38-GRRTV-XH8X6-6F3BB" &:: with Bing Single Language
exit /b

:ba998212-460a-44db-bfb5-71bf09d1c68b
set "_key=R962J-37N87-9VVK2-WJ74P-XTMHR" &:: with Bing China
exit /b

:e58d87b5-8126-4580-80fb-861b22f79296
set "_key=MX3RK-9HNGX-K3QKC-6PJ3F-W8D7B" &:: Pro for Students
exit /b

:cab491c7-a918-4f60-b502-dab75e334f40
set "_key=TNFGH-2R6PB-8XM3K-QYHX2-J4296" &:: Pro for Students N
exit /b

:: Windows Server 2012 R2
:b3ca044e-a358-4d68-9883-aaa2941aca99
set "_key=D2N9P-3P6X9-2R39C-7RTCD-MDVJX" &:: Standard
exit /b

:00091344-1ea4-4f37-b789-01750ba6988c
set "_key=W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9" &:: Datacenter
exit /b

:21db6ba4-9a7b-4a14-9e29-64a60c59301d
set "_key=KNC87-3J2TX-XB4WP-VCPJV-M4FWM" &:: Essentials
exit /b

:b743a2be-68d4-4dd3-af32-92425b7bb623
set "_key=3NPTF-33KPT-GGBPR-YX76B-39KDD" &:: Cloud Storage
exit /b

:: Windows 8
:c04ed6bf-55c8-4b47-9f8e-5a1f31ceee60
set "_key=BN3D2-R7TKB-3YPBD-8DRP2-27GG4" &:: Core
exit /b

:197390a0-65f6-4a95-bdc4-55d58a3b0253
set "_key=8N2M2-HWPGY-7PGT9-HGDD8-GVGGY" &:: Core N
exit /b

:8860fcd4-a77b-4a20-9045-a150ff11d609
set "_key=2WN2H-YGCQR-KFX6K-CD6TF-84YXQ" &:: Core Single Language
exit /b

:9d5584a2-2d85-419a-982c-a00888bb9ddf
set "_key=4K36P-JN4VD-GDC6V-KDT89-DYFKP" &:: Core China
exit /b

:af35d7b7-5035-4b63-8972-f0b747b9f4dc
set "_key=DXHJF-N9KQX-MFPVR-GHGQK-Y7RKV" &:: Core ARM
exit /b

:a98bcd6d-5343-4603-8afe-5908e4611112
set "_key=NG4HW-VH26C-733KW-K6F98-J8CK4" &:: Pro
exit /b

:ebf245c1-29a8-4daf-9cb1-38dfc608a8c8
set "_key=XCVCF-2NXM9-723PB-MHCB7-2RYQQ" &:: Pro N
exit /b

:a00018a3-f20f-4632-bf7c-8daa5351c914
set "_key=GNBB8-YVD74-QJHX6-27H4K-8QHDG" &:: Pro with Media Center
exit /b

:458e1bec-837a-45f6-b9d5-925ed5d299de
set "_key=32JNW-9KQ84-P47T8-D8GGY-CWCK7" &:: Enterprise
exit /b

:e14997e7-800a-4cf7-ad10-de4b45b578db
set "_key=JMNMF-RHW7P-DMY6X-RF3DR-X2BQT" &:: Enterprise N
exit /b

:10018baf-ce21-4060-80bd-47fe74ed4dab
set "_key=RYXVT-BNQG7-VD29F-DBMRY-HT73M" &:: Embedded Industry Pro
exit /b

:18db1848-12e0-4167-b9d7-da7fcda507db
set "_key=NKB3R-R2F8T-3XCDP-7Q2KW-XWYQ2" &:: Embedded Industry Enterprise
exit /b

:: Windows Server 2012
:f0f5ec41-0d55-4732-af02-440a44a3cf0f
set "_key=XC9B7-NBPP2-83J2H-RHMBY-92BT4" &:: Standard
exit /b

:d3643d60-0c42-412d-a7d6-52e6635327f6
set "_key=48HP8-DN98B-MYWDG-T2DCC-8W83P" &:: Datacenter
exit /b

:7d5486c7-e120-4771-b7f1-7b56c6d3170c
set "_key=HM7DN-YVMH3-46JC3-XYTG7-CYQJJ" &:: MultiPoint Standard
exit /b

:95fd1c83-7df5-494a-be8b-1300e1c9d1cd
set "_key=XNH6W-2V9GX-RGJ4K-Y8X6F-QGJ2G" &:: MultiPoint Premium
exit /b

:: Windows 7
:b92e9980-b9d5-4821-9c94-140f632f6312
set "_key=FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4" &:: Professional
exit /b

:54a09a0d-d57b-4c10-8b69-a842d6590ad5
set "_key=MRPKT-YTG23-K7D7T-X2JMM-QY7MG" &:: Professional N
exit /b

:5a041529-fef8-4d07-b06f-b59b573b32d2
set "_key=W82YF-2Q76Y-63HXB-FGJG9-GF7QX" &:: Professional E
exit /b

:ae2ee509-1b34-41c0-acb7-6d4650168915
set "_key=33PXH-7Y6KF-2VJC9-XBBR8-HVTHH" &:: Enterprise
exit /b

:1cb6d605-11b3-4e14-bb30-da91c8e3983a
set "_key=YDRBP-3D83W-TY26F-D46B2-XCKRJ" &:: Enterprise N
exit /b

:46bbed08-9c7b-48fc-a614-95250573f4ea
set "_key=C29WB-22CC8-VJ326-GHFJW-H9DH4" &:: Enterprise E
exit /b

:db537896-376f-48ae-a492-53d0547773d0
set "_key=YBYF6-BHCR3-JPKRB-CDW7B-F9BK4" &:: Embedded POSReady 7
exit /b

:e1a8296a-db37-44d1-8cce-7bc961d59c54
set "_key=XGY72-BRBBT-FF8MH-2GG8H-W7KCW" &:: Embedded Standard
exit /b

:aa6dd3aa-c2b4-40e2-a544-a6bbb3f5c395
set "_key=73KQT-CD9G6-K7TQG-66MRP-CQ22C" &:: Embedded ThinPC
exit /b

:: Windows Server 2008 R2
:a78b8bd9-8017-4df5-b86a-09f756affa7c
set "_key=6TPJF-RBVHG-WBW2R-86QPH-6RTM4" &:: Web
exit /b

:cda18cf3-c196-46ad-b289-60c072869994
set "_key=TT8MH-CG224-D3D7Q-498W2-9QCTX" &:: HPC
exit /b

:68531fb9-5511-4989-97be-d11a0f55633f
set "_key=YC6KT-GKW9T-YTKYR-T4X34-R7VHC" &:: Standard
exit /b

:7482e61b-c589-4b7f-8ecc-46d455ac3b87
set "_key=74YFP-3QFB3-KQT8W-PMXWJ-7M648" &:: Datacenter
exit /b

:620e2b3d-09e7-42fd-802a-17a13652fe7a
set "_key=489J6-VHDMP-X63PK-3K798-CPX3Y" &:: Enterprise
exit /b

:8a26851c-1c7e-48d3-a687-fbca9b9ac16b
set "_key=GT63C-RJFQ3-4GMB6-BRFB9-CB83V" &:: Itanium
exit /b

:f772515c-0e87-48d5-a676-e6962c3e1195
set "_key=736RG-XDKJK-V34PF-BHK87-J6X3K" &:: MultiPoint Server - ServerEmbeddedSolution
exit /b

:: Office 2019
:85dd8b5f-eaa4-4af3-a628-cce9e77c9a03
set "_key=NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP" &:: Professional Plus
exit /b

:6912a74b-a5fb-401a-bfdb-2e3ab46f4b02
set "_key=6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK" &:: Standard
exit /b

:2ca2bf3f-949e-446a-82c7-e25a15ec78c4
set "_key=B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B" &:: Project Professional
exit /b

:1777f0e3-7392-4198-97ea-8ae4de6f6381
set "_key=C4F7P-NCP8C-6CQPT-MQHV9-JXD2M" &:: Project Standard
exit /b

:5b5cf08f-b81a-431d-b080-3450d8620565
set "_key=9BGNQ-K37YR-RQHF2-38RQ3-7VCBB" &:: Visio Professional
exit /b

:e06d7df3-aad0-419d-8dfb-0ac37e2bdf39
set "_key=7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2" &:: Visio Standard
exit /b

:9e9bceeb-e736-4f26-88de-763f87dcc485
set "_key=9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT" &:: Access
exit /b

:237854e9-79fc-4497-a0c1-a70969691c6b
set "_key=TMJWT-YYNMB-3BKTF-644FC-RVXBD" &:: Excel
exit /b

:c8f8a301-19f5-4132-96ce-2de9d4adbd33
set "_key=7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK" &:: Outlook
exit /b

:3131fd61-5e4f-4308-8d6d-62be1987c92c
set "_key=RRNCX-C64HY-W2MM7-MCH9G-TJHMQ" &:: PowerPoint
exit /b

:9d3e4cca-e172-46f1-a2f4-1d2107051444
set "_key=G2KWX-3NW6P-PY93R-JXK2T-C9Y9V" &:: Publisher
exit /b

:734c6c6e-b0ba-4298-a891-671772b2bd1b
set "_key=NCJ33-JHBBY-HTK98-MYCV8-HMKHJ" &:: Skype for Business
exit /b

:059834fe-a8ea-4bff-b67b-4d006b5447d3
set "_key=PBX3G-NWMT6-Q7XBW-PYJGG-WXD33" &:: Word
exit /b

:0bc88885-718c-491d-921f-6f214349e79c
set "_key=VQ9DP-NVHPH-T9HJC-J9PDT-KTQRG" &:: Pro Plus 2019 Preview
exit /b

:fc7c4d0c-2e85-4bb9-afd4-01ed1476b5e9
set "_key=XM2V9-DN9HH-QB449-XDGKC-W2RMW" &:: Project Pro 2019 Preview
exit /b

:500f6619-ef93-4b75-bcb4-82819998a3ca
set "_key=N2CG9-YD3YK-936X4-3WR82-Q3X4H" &:: Visio Pro 2019 Preview
exit /b

:f3fb2d68-83dd-4c8b-8f09-08e0d950ac3b
set "_key=HFPBN-RYGG8-HQWCW-26CH6-PDPVF" &:: Pro Plus 2021 Preview
exit /b

:76093b1b-7057-49d7-b970-638ebcbfd873
set "_key=WDNBY-PCYFY-9WP6G-BXVXM-92HDV" &:: Project Pro 2021 Preview
exit /b

:a3b44174-2451-4cd6-b25f-66638bfb9046
set "_key=2XYX7-NXXBK-9CK7W-K2TKW-JFJ7G" &:: Visio Pro 2021 Preview
exit /b

:: Office 2016
:829b8110-0e6f-4349-bca4-42803577788d
set "_key=WGT24-HCNMF-FQ7XH-6M8K7-DRTW9" &:: Project Professional C2R-P
exit /b

:cbbaca45-556a-4416-ad03-bda598eaa7c8
set "_key=D8NRQ-JTYM3-7J2DX-646CT-6836M" &:: Project Standard C2R-P
exit /b

:b234abe3-0857-4f9c-b05a-4dc314f85557
set "_key=69WXN-MBYV6-22PQG-3WGHK-RM6XC" &:: Visio Professional C2R-P
exit /b

:361fe620-64f4-41b5-ba77-84f8e079b1f7
set "_key=NY48V-PPYYH-3F4PX-XJRKJ-W4423" &:: Visio Standard C2R-P
exit /b

:e914ea6e-a5fa-4439-a394-a9bb3293ca09
set "_key=DMTCJ-KNRKX-26982-JYCKT-P7KB6" &:: MondoR
exit /b

:9caabccb-61b1-4b4b-8bec-d10a3c3ac2ce
set "_key=HFTND-W9MK4-8B7MJ-B6C4G-XQBR2" &:: Mondo
exit /b

:d450596f-894d-49e0-966a-fd39ed4c4c64
set "_key=XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99" &:: Professional Plus
exit /b

:dedfa23d-6ed1-45a6-85dc-63cae0546de6
set "_key=JNRGM-WHDWX-FJJG3-K47QV-DRTFM" &:: Standard
exit /b

:4f414197-0fc2-4c01-b68a-86cbb9ac254c
set "_key=YG9NW-3K39V-2T3HJ-93F3Q-G83KT" &:: Project Professional
exit /b

:da7ddabc-3fbe-4447-9e01-6ab7440b4cd4
set "_key=GNFHQ-F6YQM-KQDGJ-327XX-KQBVC" &:: Project Standard
exit /b

:6bf301c1-b94a-43e9-ba31-d494598c47fb
set "_key=PD3PC-RHNGV-FXJ29-8JK7D-RJRJK" &:: Visio Professional
exit /b

:aa2a7821-1827-4c2c-8f1d-4513a34dda97
set "_key=7WHWN-4T7MP-G96JF-G33KR-W8GF4" &:: Visio Standard
exit /b

:67c0fc0c-deba-401b-bf8b-9c8ad8395804
set "_key=GNH9Y-D2J4T-FJHGG-QRVH7-QPFDW" &:: Access
exit /b

:c3e65d36-141f-4d2f-a303-a842ee756a29
set "_key=9C2PK-NWTVB-JMPW8-BFT28-7FTBF" &:: Excel
exit /b

:d8cace59-33d2-4ac7-9b1b-9b72339c51c8
set "_key=DR92N-9HTF2-97XKM-XW2WJ-XW3J6" &:: OneNote
exit /b

:ec9d9265-9d1e-4ed0-838a-cdc20f2551a1
set "_key=R69KK-NTPKF-7M3Q4-QYBHW-6MT9B" &:: Outlook
exit /b

:d70b1bba-b893-4544-96e2-b7a318091c33
set "_key=J7MQP-HNJ4Y-WJ7YM-PFYGF-BY6C6" &:: Powerpoint
exit /b

:041a06cb-c5b8-4772-809f-416d03d16654
set "_key=F47MM-N3XJP-TQXJ9-BP99D-8K837" &:: Publisher
exit /b

:83e04ee1-fa8d-436d-8994-d31a862cab77
set "_key=869NQ-FJ69K-466HW-QYCP2-DDBV6" &:: Skype for Business
exit /b

:bb11badf-d8aa-470e-9311-20eaf80fe5cc
set "_key=WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6" &:: Word
exit /b

:: Office 2013
:dc981c6b-fc8e-420f-aa43-f8f33e5c0923
set "_key=42QTK-RN8M7-J3C4G-BBGYM-88CYV" &:: Mondo
exit /b

:b322da9c-a2e2-4058-9e4e-f59a6970bd69
set "_key=YC7DK-G2NP3-2QQC3-J6H88-GVGXT" &:: Professional Plus
exit /b

:b13afb38-cd79-4ae5-9f7f-eed058d750ca
set "_key=KBKQT-2NMXY-JJWGP-M62JB-92CD4" &:: Standard
exit /b

:4a5d124a-e620-44ba-b6ff-658961b33b9a
set "_key=FN8TT-7WMH6-2D4X9-M337T-2342K" &:: Project Professional
exit /b

:427a28d1-d17c-4abf-b717-32c780ba6f07
set "_key=6NTH3-CW976-3G3Y2-JK3TX-8QHTT" &:: Project Standard
exit /b

:e13ac10e-75d0-4aff-a0cd-764982cf541c
set "_key=C2FG9-N6J68-H8BTJ-BW3QX-RM3B3" &:: Visio Professional
exit /b

:ac4efaf0-f81f-4f61-bdf7-ea32b02ab117
set "_key=J484Y-4NKBF-W2HMG-DBMJC-PGWR7" &:: Visio Standard
exit /b

:6ee7622c-18d8-4005-9fb7-92db644a279b
set "_key=NG2JY-H4JBT-HQXYP-78QH9-4JM2D" &:: Access
exit /b

:f7461d52-7c2b-43b2-8744-ea958e0bd09a
set "_key=VGPNG-Y7HQW-9RHP7-TKPV3-BG7GB" &:: Excel
exit /b

:fb4875ec-0c6b-450f-b82b-ab57d8d1677f
set "_key=H7R7V-WPNXQ-WCYYC-76BGV-VT7GH" &:: Groove
exit /b

:a30b8040-d68a-423f-b0b5-9ce292ea5a8f
set "_key=DKT8B-N7VXH-D963P-Q4PHY-F8894" &:: InfoPath
exit /b

:1b9f11e3-c85c-4e1b-bb29-879ad2c909e3
set "_key=2MG3G-3BNTT-3MFW9-KDQW3-TCK7R" &:: Lync
exit /b

:efe1f3e6-aea2-4144-a208-32aa872b6545
set "_key=TGN6P-8MMBC-37P2F-XHXXK-P34VW" &:: OneNote
exit /b

:771c3afa-50c5-443f-b151-ff2546d863a0
set "_key=QPN8Q-BJBTJ-334K3-93TGY-2PMBT" &:: Outlook
exit /b

:8c762649-97d1-4953-ad27-b7e2c25b972e
set "_key=4NT99-8RJFH-Q2VDH-KYG2C-4RD4F" &:: Powerpoint
exit /b

:00c79ff1-6850-443d-bf61-71cde0de305f
set "_key=PN2WF-29XG2-T9HJ7-JQPJR-FCXK4" &:: Publisher
exit /b

:d9f5b1c6-5386-495a-88f9-9ad6b41ac9b3
set "_key=6Q7VD-NX8JD-WJ2VH-88V73-4GBJ7" &:: Word
exit /b

:: Office 2010
:09ed9640-f020-400a-acd8-d7d867dfd9c2
set "_key=YBJTT-JG6MD-V9Q7P-DBKXJ-38W9R" &:: Mondo
exit /b

:ef3d4e49-a53d-4d81-a2b1-2ca6c2556b2c
set "_key=7TC2V-WXF6P-TD7RT-BQRXR-B8K32" &:: Mondo2
exit /b

:6f327760-8c5c-417c-9b61-836a98287e0c
set "_key=VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB" &:: Professional Plus
exit /b

:9da2a678-fb6b-4e67-ab84-60dd6a9c819a
set "_key=V7QKV-4XVVR-XYV4D-F7DFM-8R6BM" &:: Standard
exit /b

:df133ff7-bf14-4f95-afe3-7b48e7e331ef
set "_key=YGX6F-PGV49-PGW3J-9BTGG-VHKC6" &:: Project Professional
exit /b

:5dc7bf61-5ec9-4996-9ccb-df806a2d0efe
set "_key=4HP3K-88W3F-W2K3D-6677X-F9PGB" &:: Project Standard
exit /b

:92236105-bb67-494f-94c7-7f7a607929bd
set "_key=D9DWC-HPYVV-JGF4P-BTWQB-WX8BJ" &:: Visio Premium
exit /b

:e558389c-83c3-4b29-adfe-5e4d7f46c358
set "_key=7MCW8-VRQVK-G677T-PDJCM-Q8TCP" &:: Visio Professional
exit /b

:9ed833ff-4f92-4f36-b370-8683a4f13275
set "_key=767HD-QGMWX-8QTDB-9G3R2-KHFGJ" &:: Visio Standard
exit /b

:8ce7e872-188c-4b98-9d90-f8f90b7aad02
set "_key=V7Y44-9T38C-R2VJK-666HK-T7DDX" &:: Access
exit /b

:cee5d470-6e3b-4fcc-8c2b-d17428568a9f
set "_key=H62QG-HXVKF-PP4HP-66KMR-CW9BM" &:: Excel
exit /b

:8947d0b8-c33b-43e1-8c56-9b674c052832
set "_key=QYYW6-QP4CB-MBV6G-HYMCJ-4T3J4" &:: Groove - SharePoint Workspace
exit /b

:ca6b6639-4ad6-40ae-a575-14dee07f6430
set "_key=K96W8-67RPQ-62T9Y-J8FQJ-BT37T" &:: InfoPath
exit /b

:ab586f5c-5256-4632-962f-fefd8b49e6f4
set "_key=Q4Y4M-RHWJM-PY37F-MTKWH-D3XHX" &:: OneNote
exit /b

:ecb7c192-73ab-4ded-acf4-2399b095d0cc
set "_key=7YDC2-CWM8M-RRTJC-8MDVC-X3DWQ" &:: Outlook
exit /b

:45593b1d-dfb1-4e91-bbfb-2d5d0ce2227a
set "_key=RC8FX-88JRY-3PF7C-X8P67-P4VTT" &:: Powerpoint
exit /b

:b50c4f75-599b-43e8-8dcd-1081a7967241
set "_key=BFK7F-9MYHM-V68C7-DRQ66-83YTP" &:: Publisher
exit /b

:2d0882e7-a4e7-423b-8ccc-70d91e0158b1
set "_key=HVHB3-C6FV7-KQX9W-YQG79-CRY7T" &:: Word
exit /b

:ea509e87-07a1-4a45-9edc-eba5a39f36af
set "_key=D6QFG-VBYP2-XQHM7-J97RH-VVRCK" &:: Small Business Basics
exit /b

:x86dll:
Add-Type -Language CSharp -TypeDefinition @"
 using System.IO; public class BAT85{ public static void Decode(string tmp, string s) { MemoryStream ms=new MemoryStream(); n=0;
 byte[] b85=new byte[255]; string a85="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$&()+,-./;=?@[]^_{|}~";
 int[] p85={52200625,614125,7225,85,1}; for(byte i=0;i<85;i++){b85[(byte)a85[i]]=i;} bool k=false;int p=0; foreach(char c in s){
 switch(c){ case'\0':case'\n':case'\r':case'\b':case'\t':case'\xA0':case' ':case':': k=false;break; default: k=true;break; }
 if(k){ n+= b85[(byte)c] * p85[p++]; if(p == 5){ ms.Write(n4b(), 0, 4); n=0; p=0; } } }         if(p>0){ for(int i=0;i<5-p;i++){
 n += 84 * p85[p+i]; } ms.Write(n4b(), 0, p-1); } File.WriteAllBytes(tmp, ms.ToArray()); ms.SetLength(0); }
 private static byte[] n4b(){ return new byte[4]{(byte)(n>>24),(byte)(n>>16),(byte)(n>>8),(byte)n}; } private static long n=0; }
"@; function X([int]$r=1){ $tmp="SppExtComObjHook.dll"; [BAT85]::Decode($tmp, $f[$r+1]) }

:x86dll:
::O;Iru0{{R31ONa4|Nj60xBvhE00000KmY($0000000000000000000000000000000000000000fB,mh4j/M?0JI6sA.Dld&]^51X?&ZOa(KpHVQnB|VQy}3bRc47
::AaZqXAZczOL{C#7ZEs{{E+5L|Bme,a00000P)=U$OaTM{_dYzX0000000000.~cWo3jqQi044wc02lxO00000pb_K801yBG06-i$0069P01yBG00IC21][s600000
::1][s6000000B_]R00aO4giQbd0RTV(001BW01yBG000mG01yBG000005C8xG000000000008jt_bprqZ0000000000000000000000000000000AK)BumS+800000
::0000000000000000000000000000000000000000000000000000000kWc]sXaE2J000000000000000000000000000000E^7vhbN~PV6eIuu01yBG044wc00aO4
::000000000000000AOKKcE[WYJVE^OCKn@&]06-i$01yBG04e|g000000000000000KmcICE[[;8bYTDhbprqZ08jt_00aO406G8w000000000000000KmahnE]=jT
::Z){&eumS+80AK)B00aO406qW!000000000000000Kmag800000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000|0VEHtZa~w|0V2DtZa~w|0U?9tZa~w|0U#5tZa~w|0Up1tZa~w|0T#!tZa~w|0TpwtZa~w|0T3gtZa~w|0SqUtZa~wW{^r)
::W{^r)RaaJ1gX|oOTqHD$Oe8SJL@j3R0001sL@k$iR3to!3@zx(iCiQEh1-=/^u0opBnbci|Nn#20ErAF^uGkFBm{}wiPMGBc[6j2^f#YZgVF&]-KJPN$BP6ch1-#d
::Iq!BXiRv..^xFjxiO7pgBnXM}g~[aW^t=Bd0QcI1#2i~,UtPnA^KmzJ00000h5vO6xB(nF05Q^{]NGhX)uwHz^ld[f1SI$OiNWi;IqP?E554n+^8+a5IqPx;G08hT
::BzL8_0RR91?z.ziG4@UZ?z0jn0FAsS00000xF7&k0EzL5_YG^!;B7r3?WT3Q-SBKW?xseB?xon)42kiJ6eQE.iNVwA3Dt@)iRkxqBn,kuiN,KlIn#0=i##NW[zduy
::$8!WZ){vGu=_r[{H2@qqkd3q]00000jZObC^UR+3|NoGXkdTm(RaaJ1gX|oOR3to$Y$Py@bR/y3TqHP!)se~S]L7$3|B2{{]7r$D#2ktGTV7vX!.@62-jR[L0RR91
::G1B-,iNT5RG17y@9QW~w##[Q#iT7Uj[rn9hUBivG00000Ir4WL554-?^aAj6Ir4G^F~B-Ncd[tu0002&s,QF4gTx#$|1rQ[iTYk(UBhOOiTSu70000f^|xKvR3r$A
::!HL@^?WfSy2no[N[_-3(2#NXA;B7r3?WTS[TqF#M?)l0m!PDyr.ih${bR.Cg+__RSWF!nZ+]Zhz_P1b(#d8EX+]rJp,fIa;H~/^tjYI!2|LHCN|NoGXkdTm(Rf,-/
::?;EiR41[RqbT+)d1a(}z?;qaE0002GU^z{HY5=(PL9A[)bRPf!xL_u8Z0PPD004^c5QD[J#{ghKtZeHKgX|3dbqN0zkWj2^gTxHUxB(nF0KyCaRf,-/?;na~7ytkO
::|8+pz0E;8{|8N.p6})WaY{|j|0FaQ7Rf,-SR,iM(gX}PiMF@slXuXMOf(Xv?|1jub{{R1j#0-W5@X|j$iNe9-1p)2z@X|j$^u?J{1$sv+#+)DHjYZgj)pt@{F/I/~
::(}s.!iB/6.Py-w}i-v2a1ONa4gTxT@rHy6yUSD0qRWZql;yTfyi)Lqd1dELn0Exzl$HDFgf#UxD{{F$o2!ZAS0RaJP^8T$QiNe9c5HavE_oYKuG4e6ci3E#5gZTt@
::##?&rUBi&(Rf,-Ri,,cBi)Lp&P?n^~P,dpP6#xK)#1MtRc[c@q42fL_jb.?.UR~-(5C8y/W&yfOUBi&(RWZPc;&@Aa54H?fiiu!LtZax30ziZK5OwWc!/p}WRk/KJ
::001$.iRD,TjeY2Y?=27p2#MD7rEAFjgW)T~ObzIW3;5xd^z.pNgTxSCUtPnHRk/KJ001$.iRD,TjeXctgX}zubqL2r!~g(Q0Q0NIMaTdE0075D&m4rY0LMkpAOHXW
::$3[f)fB,o6^H-+o3^z[GxdZ@J0Ex&,rJ.~}tZaqAbs1MzXm~[cY.o.{tZeAL4,(pz#1Nx(Lac0!Rm6kr3}]rV0Pt!UY5.~gQvc9{#0.VNbq6uq=^~/N0HJI_tZaqA
::bs1JxXrM!]Y.o.{tZe9c4,(pz#1NxwLac03QjJx}QfdHd0BRg+06@s4|8?Ow({;oBz/wHzXhN+Pg}_-gP,7;8L#&9Qjzg@$=sOPp0E5I3qi8~_Y?idSgX|1aY5[Or
::$Y=@G0094W#Q+HP#0.VN4}]IC|No)ILac0sz/zi=P.s6ytZZnGL#&A,^znO7gTxS{a6-tXjaAfY08)lN|8?m()1pMcghBuR|Dk-BtZaqAbs11lXbwcIY.o.{tZeAP
::4gdgy#1Nx=Lac0R0RMFi|8+[mb;F@Jg}[Jl3jhEAp^D@bY=yve8BkDY97L?aXpTdyZ0L#)004u/5TlertZa={)1Yv[Y5.FIbrfm?|8?m()1XMbg}[J$!.IXu01vj@
::bS;HXLac0sz/zi=P.x9VtZZnGL#&A,L=FG|gTxS{h)fGvgX|3db/$qFgTxGjearxKEuoM@tZaqAbs11lXf8yoY.o.{tZe8J4gdgy#1Ny9Lac0q?;s]P&?U4X#0.Od
::!~k@Hp;qI-Y=yve8CO@m.9xNwXpTdyZ0Oz&004u/5Tjs1tZY)JY5[Or#Q+G+UWwR]W&OHKUtPnHRf,-OgX|QcbV96b$3]S^0002TMeqOs0075D]dJBL0ENJH8B$Vc
::ctfmgXpTdyZ0L#(004u/5TkTLtZa={@1StKXaE2J[M/+p0BQhI|ImZP428gT2Qk~}t]fc4p=d(]Y=yve8BkDY{zI(6XpTdyZ0JS}004u/5Tj]9tZa={[Pq6OQfdHd
::0B8)=0094W@Elb&#0.VNbi1K]Lac0sz/zi=P.qTBtZZnGL#&A,2n^&LgTxS{d^t]jY5[Or4F7cq|8@/H)1pNsh[q51tZaqAbs11lXdFbWY.o.{tZeAj3/-Ow#1NyD
::Lac0!RrG_G3~B(U|8+?,0{@aJ|ImZP428fCmBWL5[Bk0C-jK3VkV33&g}_-gP,7-tM67IRjzg@$=#LBl0E5I3qmV-ZY=i6!|8@/H)1XMbgMI7)bS;G]Lac0sz/zi=
::P.xvltZZnGL#&A,TnqpJgTxS{U^z{HQc_LF|8@yD({;fC,o$5K$.|J4Rf,-SR#P$CQj0|hiwu~J1PO_C!RiMk{{H]{f#LxH0Rd~$8!]I.G!lu?!RQBp=KlWv{v_nc
::0Rd~k8!^/S#=.6ff#v}L0Re0N8/vvof#(}H{{AukiO)^jG4P50!Nv&Qb@}MSG5RsaGj/HZ,D=V!(j_W55HbES#,0M=i8Po+gZl)]fLL2zUtPnHRf,-SR#SoOJOTg!
::i)LqV_(+k/i$xH}000000E;Nw#{d8T006jG0002#IRXFxi$x5J5P|vt00jVaRe|~d00sbbO+;cM_Tzg~01t&]0ssJuMGTF#xc?kDjg;_k|NrRG6aWB@l@@v?|B3ME
::loS8}iNjEh1RhXUQ.i}0=syww0E;Nsi5Q6.B;a5a004^c42hMv{{R1jzyyhf#Qp#Of&,Ud1psvyjfK4a|NprJ0001swZ#4Z|B1+,rRzkEwaoqh|4?kky}bVa|7s9c
::=$iom0F8wV{{R2E1ONa4$At|3|NjsG008r+P?qGW{{R0^i$x4.0RJ&PSOfq7gTx@?g~;K@|AXrUP?V$j|Fy,Z|Nm-LiJi#)|Ns9m=raTW0E;Nojg;_k|Nn!+6zKjF
::0051Z4F3QBjfKqq|NrQ{6952?jm.Z4|5}Y40a;DgQ|J}}0050c5QD[FP.-lU=!5-K|6X5H|Fy,Z|NrO)5(!]/eGH95FoVPpfj;BM1]{)^p^oFfY_Fvg004]?oI;Q[
::i@zi4|Nn^YFpWbviBmL,$MdC+Lr9Ia.2MOmiN{b.jfJHC|NmA{=zsYC|BZ$0{r~@]jg_Fq|Nn{jDbP|.R,kj&{r~]yr1}5;jYC-u1ONa4gTx]7rHz&m{{R2E1ONa4
::jkV1E|Nn{C]QDcI&?MuXgX|1w9033TjkUP_|Nkk^iG}R^|No7J@EU}$P?qGW{{R0{P?V$j|1juf0{{Svh3x)R|AWL7i&k&Nz!ZrAQ0UJ0|No195QD[Fiw}v&]Q4PS
::6o~/bz?Q^}TV7vX!/p}WRf,-OgX|QcbV96b$3]r20001mz/zi=P.u8VtZZnGL#&A,6bS$TgTxS{bV96bjaBr6?;ls6XaE2J[M/+p0BQhI|ImZP428gSG[+cdtZaqA
::bs1ArXi.G0Y.o.{tZeAj2mk;s#1NxoLac03|8+rebqxP@]#9OVg}[J$!.IYF01vj@bS;G]Lac0sz/zi=P.xvltZZnGL#&A,m;Rv?gTxS{U^z{HQc_LF|8@~L({;fC
::,o$5K$.|J4Rf,-SR=$t_002{i?=cWA42xX|jfbEB002_]=qnHa0E5I3gX|1b==b/k|A_zV=-F26|5&L#H)FCr=nD_40ErwV==1yk|AWL3gYFP[)}U~_Q|QX~|Nn]_
::B;P~||Nn^y41?fFiG2u.W&OHKUtQ^d4,(p=Rf,-SzYqWb09I3j?=cV#2#a-LQ(#A@4,(pz#1Mn,3{(XQ4gdg(93;#z4,(p)93;$_^W&D^jRZb}#}HamQ0R]i004u/
::5P|=o0001W(4cU=fyST!002|ym;|8{i5w,8Fb[C#iCqkX#1M(f2#sa,TV7vX=~oW_0FaQ7Rf,-RQ/kLFgX|FKm=OQ~g}[Jp2?}2Ajdko)Q/Qv?P][ff0BQtQY6NIl
::MXYT9b@E=og}^=^cngDl?/Mmy1,Af)Y,0{Y0BQtQY6NI?MXYT9b@E=og}^=^cp.s)@7,l10Jy.Y006oV0000FMn(v{^zw@4!e,nOLac01P.,~b1XgMUXre_|Z2xuW
::|I?xQT3L7[fqm[2r~m.Cz]DKKx)[(V01rk,@1T6Z4@[CbqoP8rY,0{,Meu3?Y6wtj3uwwktZe]v=?OA(z,;?(Jc~u}xeyT&5sOvyIl/LR5fKp@)Q][l_u}wngZTe.
::5xD/U|NrX?xDgQ&5xNl)5fP+9Lac0w6_Vq?Y=i6!|8@l.AoBnJF~Ebw42[/[TV7qmp?RR0Y{QU{Rf,-Oi)LqdMGT8o5Q|L|f&]ae1pssyf&]ae1]{(-iA[k(iB$}V
::MF@H#[Bsh.iA[k(iB$}VMF@H#TmS$7F~D10!/p}WRf,-Ri,,Q7i$x5JRS=6!6pLLLf(Ksh1pss$f(Ksh1]{(]iCq-1iA[k,iB$}VMF@H#-yejriCq-1iA[k,iB$}V
::MF@H#L/@T-TQR^1UBi&(Rf,-OgX|QcbV96b$3]e}0001sT@ofT]Z+;=0ENJH8BkDYctfmgXpTdyZ0Lps004u/5TkTLtZa={[Pq6OXaE2J[M/+p0BQhI|ImZP428gT
::2Qk~}wEzGBp=@5|Y=yve8BtMaphK+|XpTdyZ0JG.004u/5Tk5DtZY)JjaBqgY5.~gY8-[}MyzcAb[2btSz3j^bi0MybtIvLLac0sz/#eiP.yW)tZZnGL#&A,00jU5
::gTxS{ghH&r?ouW^Lac0sz/zi=P.w41tZZnGL#&A,-ynpsgTxS{j6$qzY5.Ge0snRM|ImfNb,$.L|Ns9|QvY=j|8+#&0BQkh0RMIL|ImfNSz8a4!.IYF01vj@bS;HX
::Lac0sz/zi=P.x9VtZZnGL#&A,gaiNpgTxS{h)fGvgX|3db[czxgTxGjeeeKuEummStZaqAbs11lXx(4sY.o.{tZe8}1ONbo#1NxkLac03QfdJIb[2btSy-kKi)UN5
::!/p}WRf,-SR#SuQ9E)K|i,,c)7&{/1!w)OIlK=n!iCyH4d?.(Q^jV?xQD_7dtZY~4g!},hSdCZkSyxhtRp98s3jhF&Rp5if5Q,38+?2YvAWf_nR^I?+|Nn!/5QBXP
::0CWyeP,)qS2;Vmz004u/5QF/=bPJ749{.9Ffcg.22a81zi5Tl554Q3#z(Y[A42j40.#QdIbqGM~[F~NIUF3]J5Q|OZi3qp?0001uW&OHKUtPnHRf,-OgX|QcbV96b
::$3]e}0001sT@ofT]Z+;=0ENJH8BkDYctfmgXpTdyZ0Je[004u/5TkTLtZa={[Pq6OXaE2J[M/+p0BQhI|ImZP428gT2Qk~}wg3PCp=@5|Y=yve8BtMaphK+|XpTdy
::Z0H69004u/5Tk5DtZY)JjaBqgY5.~gY8-[}MyzcAb[2btSz3j^bi0MybtIvHLac0sz/#elQ+s|LtZZnGL#&A,!~y]SgTxS{fI^Tn?ouW^Lac0sz/zi=P.w41tZZnG
::L#&A,paK8[gTxS{j6$qzY5.Ge0snRM|ImfNb,$.L|Ns9||8,4qbrAn_3~B(s0crsMb[czxS&tt4mBWL5]Z,aG-jK3Vh)fGvg}_-gP,7/iL#&9Qjzg@$=tlwo0E5I3
::qliMRY=i6!|8@~L)1XMbgMIJ.bS;G]Lac0sz/zi=P.xvltZZnGL#&A,6aoMMgTxS{U^z{HQc_LF|8@/H({;fC,o$5K$.|J4Rf,-SR#SuQ42wk(i)L$h5HY}s)f84V
::/SWKLGzvR+6n9@&-Jk+v0Ex)n,Ym1$4p2~2|8+rHj0pe$gTxR}iQiCYAWf_nQ|PAo|Nn!/5RDWwiTH!Z5INU$8(XnNQ0QU^003E7Xdq3jY,,.k_Tzfe#1QM,i$xHL
::Ft_B#0050/]jltEUBi&(Rf,-SR#SuQ9D^X|K(+(4i,,Q#T[Z^X40J@=^H/mn|8zWy133jGL9A@bGGw6_0000v1uQ|VY/_1yQw+o91dDqJi)3$hRpjWI_TzfmRpe7r
::S61j[^5c4d!0Q!,?;nleBdl!b_~@62gTxF|S62VfgTxSxW&OHKUtPnHRf,-OP=h[nK(+(4i)LqG8.@3-7oj9UtZX@0bq.{q7ytkOIRz|1tZZ}{gX|1woFlAk=(uC/
::0Et}+gTxSvUHr.a/Kv0ZK(+(40000nz?8h{#|0!otZV=P0074YC^$_j00000#|11wtZV=P007Ct1OSkbgFPTXtZV?PiRD,Qi)LqGD23Z}BxIo(0000v1uQ|VY/^h/
::P.rATtZe[@{}tF!tZakC5QV]W8.wf(XcQ![Z0ITl004;y2!q5Bjb.?.UtRy/x-FlXY_H+H004?C]Q,[L00000jb.?Tz,}Ek!UO=2Rf,-RQ/l8dgX}2)bqG_FjO-jZ
::UX69(SXNVN0BQjL6^ik{Y=yvhCXHS2P,DGM3{(WF?/M0aMdVspP.,~E|8@O16^_.0Y=yvi7V8jJQ+(Qe0RI+7P][f+z;J6s!0Q8xMdXcT^,.6G!/p}WRf,-SR,iMo
::Q[emhtZakqRL4cU00000Y5.RM6|hjOY?P$MT3Lxjyo,H+iAC6h?;o$VQ|PJ,004u/41~aSWP|JsiQj|63{#2m=#vQm0E5H~gurz]jb9jp?;o$VQ|NvP004u/41~aS
::DUDwwgX|26[l+t(2?;|t#0.SMbrg-XFoFBfN33jhqQ]zF0{{R3?nO+Xv/zPD0D=3]N33jg8H-/,i(F&NMcj==yopuViSp=82?;|zMYL/Ov;!_Xybrd6;43G+54Mxy
::N33j#Mcj$^iB/H,RoLhy2?;|#v,bstY=OhzN33j&TL^6ouqpF{_~P$(LxafwG1B-,53ksX$Bjk2gX|1Y{}s$otZakC3]~Jg?[m{!^v/OV?;m}_70ghqY=guM0q}_M
::sG+d5tZaqAbs11lXsAN0Y.qkhtZe8){{R1j#1Nx-Lac26)1Yv[iAAi7MX;r)1dFifO{{E,MX.(S/7zP.i[5AftZa=&z+;MD?Hq)WMZk-y#EEs.jdj@G[rixh1pq,n
::+q(DB|NsAqMc{-&42@y-R#1sm;mjph004;a$c/tFiB.(2Q2!OwP][f@MbO7Z-5rFo08m!{70])uY!AOh,n_9vi(e}}i$&yQMbH~n+Pw8{XvqKo0B8WfX+01s=v)Rk
::|AWLFxj/e?05Q[+P?V(V|8oTYb,&UCY6DVGYelpS54V8eN33j6i$$?iu/5LsY.rd,tZZsP|8+rH+ad{Jjb.#)USD0qRf,-SR#SuQ9D^X|K(+(4i)L@leGGJOgMA19
::bZLeEbY-V}1UUsHL9A@bT8lF|H7G&?Y/{m&p&@&F067ILL9A@bLW[QuNQ3zOcR7nw42w$/i-c!,TNH]]/E7G.=wtQ(|BFrJi(fxLQBqgvDDnUQSXycT|8]w,6}V8W
::Y&#!DTk9Hw?;nl/C#.Dfv/hDBgTxF|SO0Yg|ImZP5RGN[TV7vX!/p}WRf,-RQ/S]+i,,cz-jKI8^H.^TJs@1=Yyfm6p)sJDY=yvd9D^Y1L9A?5bQ5HY6(L]j067(b
::L9A@b1UcAr9+s+,Xy^.bZ0Jq^004;~41?fFiCqYdW&yfOUH{/XW&x0_TV7ql2mp|fRf,-OgX|ECT@lAYD6DMg9033TT3P?f3{)HmT3Lm^bufcHAV92a0CXpVJtRS^
::Yyfl~gFPrgtZV?v6=aJQ7ytkOITb8HtZa1#i5+0GtZa,2{K?+y0FaQ7Rf,-SR#SuQ9E)K=i)L$hbr6ev9EnBXi$xTPMdXV_7?PyPh1-y7Qc_G0L#&95{}tF!tZakC
::5QV]X9Ox4C|NnzMAV92a0Cf)4J+}acYyfpRzBEIuY=i6!Xs{[)Z0K$P004^s-=-c0gTxSvP2_Dn5Q$w3iB&YjRp5zD6p2,_jb.#)USD1R/Kv0ZK(+(50001Fp&@&F
::0HZ8HtZYzF|8@Y6Q+psCtZZn20001JBtWce=$q#M|HlU/K(+)o#2^+ijb.#)USD0p7yyuvRk+x,tZcam0001q;yMPz2vdp5)fVuJ7y.jOa}/-7h0=ZwiP7uojYAkI
::)T!36?-U]ZLac0b3OjHVa|O6yLac0Ci$D.wUBi&(Rf,-RQ/oHF|NsAi@3e&m0E;No54KPbQV-IJ4pI.cPz^QKwonXG54KPXQV-IJ3Q_ZYPzh2GwonLC54TVTQV-LK
::1XBMnXxv4tY.(JO=/P+8|BZ!o|NsAk#6akI1ONbqz=]|nDNs/q0BU~!bqHz!R{ynh|NsC06{JwCY,LBC|Fv}g|NrRW;]TVK#0.sP^=)tCUR}eGRf,-RQ/S]+i,,cz
::-jKdF^H/FaJs@1=YyfmDgFPrgtZV?vBV@f&0000v1uQ|VY/^e;QfMSVtZY/N71(U$Y=guQg}_)kgX|1wY$~j5=+@a1|A}=BgTxStT@mb3^,.6G|KLziY6NH_L9A[)
::Z1Dg8p)H_9Y=guQi3W{j^&Xm-UR}Zn0FaQ7Rf,-RQ/S]/QBhO?bqMH90RRAAzHm(eY,;rhU_)uR=sN+b0E5I3gX|1b=u.dy0ErwV=;5Ig0ErwV=u^zb|5#d6R+fY6
::=o0||0E5I3f(LIptZa4AgX|1b=pz6C0ErwV=)^,^0Et}/gTxTWMF;d0tZa?C^,.6G?E8eV0FaQ7RWZPc;&@Aa54H?fiiu!KtZax30ziZK5OwWc!/p}WRWZQ11ONa4
::iRD,TjeW?djdjR^?[1622=l9reb~7K0002;tBK!?O$.6qDfxr{4}KJlMaWWv@-{W[QRo_~|Nn!/5bNMEz(Xc$3W]i~h,SmGK;n~QP?n]{R#3+7J=lQg]#1@;i-vEe
::1ONa4gTxT@rHy6uTV7vX!/p}WRk/KJ001$.iRD,TjeY2Y?=27p2#MD7rHu[Q000000l|ae4~k3/=!gsgK!f.Yb@1Y_5MEzh!/p}WRWZPc;x_7Q42xX|iwuJ@41z#|
::^yl$ITV2DDRf,-SR#SuQEXPIE00000i$(B@54V7TNUUtp=unGA+c?&ANUUuCbqN0z-+&7-gTxSpzz?BM0RRAtMGR)vI89m+g$Mxv0Exi]Ks;psP)=U$4~6#t004_S
::fB,mhh0-g&=?Px#i.3dx004!-4}{wQ004?C0nY,WiABgceaH_n$p8QVgMSPF4}_w}004^c3;C#@bqoV{5Q#;5gFXNcgrEQb05RK)gRnuYY=yvd1Um.nBa21QivWed
::cx/PJ3{q16v#dd]Y?h-#0#NA1/{X4H#1MtRbx[5?;b(+CiFMqKRp3#LMcisYQc$6-P][gnMc[Pg003)LiABu-)2E9,P2_PL/E98;L9A@xgS0_cY?5VqMch(Ub?vb|
::i$&;8|Nqc~#0.PO7=io10000Fg?L_;|AR&+1cSx|=~w]&|AWUA=_R2O|AR&/2!nmp7!QT9{{R1tW&OHKUtPiw0FaQ7i&JAliRD,_$5x5fQ.i@?]Q4WkhyVZpxd{LO
::0EzqarGvvHDZ_1^TV7vX!/p}WRf,-SR,iB9Q/EZa?^m$IiB.gj0#jD#tmXgzi8LgQb3o|H/s5_ORm8aj0000$0l;ku1dY0g0002;rHgY]i-fm!vX}q?0ExPs0001s
::Lr@-0iGrX2000lS1+xH#Y?9&T0000Fw,{g@tZa#br~m+}i$he4Q([?b({(N{,ojrtT2PHe(_|#s+KIK!SzC=|]jltEUBi&(Rf,-RiN/fnUGRhK5a[32|Nl}^P,dn)
::/s5_G?;m^F08{[Jpir!Ajb.?.UR}eGRf,-/?;o)mY7m3KFi@v{2?(qXEaCtEgTxTYg}[J#z_^IoRf,-SiN{un+?DJ,9E)~6D/k6Q|8yopgUJ6e)+aTZuh[x2;b(+C
::SN|2vP][f(#0+vZcJDFL^jTm!4TJ0qQ2!OoP][f(#0(!ljb.#)USD0qRf,-SR#SuQEQ?_9iA~6ha0n|fi-Bthcm&lq|Ns9v[VEc~000]Ia(d#k0fW~7iFMFdR&!rh
::|A~Fn=nLZi|BHRpgTxSt!HLrkulS2a(=0S|0mq9+)D(hqRn!4}+QLsVgX|26O~]6.|8+q7UCjR#&uuXsi&rOh#+HHRJ4Mim^!~vki)Slf,HckfR^M0j|Nn!/5bJk|
::[b}OO^/g/0_.[G/P,9CU,iip;2,,X)00000$3[&#0001qUEs$?;NyEw0O(IR|NqBD(/S4c08//T2#H11{}s$otZXsT14Yn[_4d(tgTxFu#u@Fau!HyjiP0NP+N?Q.
::q=W1X|8+re70ghqY&$V;#0.ml3;C!fR|Jh]]jltEUBU;eRVl+W;yXP^16GZF-.cIQs/a6}iOabL0001k?]O;u]QDR3iN@7G0002;rHysmiRZZn0002;rHRoo)(!EV
::004u/7?#B0TV7vX!/p}WRf,-SR#SuQFo{LbiO5KaRmh87$catNnYjW0008(.iABUYUBrGbjY9#8eb52GYtR]rOc)q+OcxY$0Z41x7z16;xds3L0Bi6V19i}e..,NX
::rR(W0Ma&)pGmAycxdH$H0E6fPnfLiQ!,wBzLjj9[(}.Wmxds3L00F=QUC@XL7?#rn=!xI-rHxqsi$xrbecZVQ0001ubqMpNxdH$H0EtD-jYI#L^xWqn7z0)&IbFzo
::C~NQ.19i}gP0Tq@6muGh,NMZ8Q2+6G0002;rHRnK0ssI2nfLzd(5K3Mjdk3+1][s6iPwom[bjgE#4uZ4UtPnHJ+l9XY/;u|iRD,TQ/Ea4xIwIJgX}yx!,o[RNEnMX
::v^Y)FiA}]ga1@VoiN@7G0001ueb9.,]QDb.)1GfpL9A[Qph2u_DbRz!7,SGaph2u_Q0V(I|NprL0001k#1QkP?jmgp0RRAtMa1i/jb.#)USD0q!/p}WRf,-SR#S;@
::gX}zsRm6!-yo,J|DcC+L0RR9GjvWC20KxbJX~3)hs/Yy1ya0)sxQj+]jY#NqWQ#@)gXjX$^=!cpYjwaFjeXF$1][s6gX|cI,a6=2rHysaiRZZn0002;rHf6ti(enr
::82;nNgTxqveZT/81].RJ?(Am]#2AU#i&rCd&IK?7|No0c#3|T=^!xiY?7f7s0E;Pqje8jXO}vY9EYbLDz!)A8i&=AaRlti@#EVk=J9WTw3p.W7cPKgXb^VMmIr4TC
::P,7J?=)7L.0F6U1gTxSveZ=b|J5|7T1y+v3?,Z2XQ0w4{MZi!{S61ka0001sMZkl]5QD&Njd19TQxrK-{BrVx@.+B,6ms}E{(LicMF[lJ42w/@i(ex?iSX#n{{R1j
::#1M(f#Oc&i|No6/]jltEUBi&(Rk/QL004?QS5}RE-=;3hja}S???!I!6!WEt$Ajn@J5UsJ4!H(Z004=_jd(RIrR)U4.nj-;008r+gTx@PUSD0qRk/QL004?QS5}RE
::/DhWSi,,R|rHg$Cxds3L0E=}D]QDV[42]Z,xds3L0Q04T#2{W[UBi&(|NsC000000|NsC00000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000002m$~A0&iaJ5C8xG000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000EC2uiKtZf,bS$iF000000000000000000000000000000000000000000000000000000000000000006aW@goJ6c^7yuanvP7)G00000uqdo.6aW@goJ6c^
::8~^~v&S5bf00000Y$~j56aW@goJ6c^4ge1T=tQh-000006eO&{6aW@goJ6c^4ge1T^e89000000oFlAk6aW@goJ6c^7yuan21TrF00000R4A.$6aW@goJ6c^6aW;f
::A4RNe00000=qIdf6aW@goJ6c^5(#nbG+1gz00000JSVJd6aW@goJ6c^4ge1TM[6h_0000093!l300000000000000000000000000000000000000000000000000
::00000000000000000000b]x{jmINF-cmQB00RR91M_d)Vd2[7SZA4{eVRdYDOhZXT003)MWdL#jZUAKfYydL=G5{^BWB^acYybcNB?,r0H2_&0EdV6|FaR|GbpR~[
::B?,r0GXQk}EdV6|FaS0HbpR~[B?,r0G5~b|EdV6|bpR~[B?/5,E(wn9FaR)BFaRw8B?,r0GXP_(B?,r0Gyr4)00000F#s|EHvldGFaRz9FaRz9F#rGnZUAEdVE|)Q
::ZUA2ZX#j8lUjTFfV,qdf001Qba{xL3B?.~)TL2{ha{yfc00000Lvnd=bU|Zrb!l?CLvL;$Wq5Q~002P&L/zL,K?$zyNdPkdG5_PoLvnd=bV-S-Z,p_@WqANYa)Qrc
::Q+P5ZWqD9xa$#+&Lvnd=bVY7sa)Qrc07G)laCAgvb98cVc}rz]07G)laCA~.Y.M3{WkYXnbY,yS07G)laCAgvV{(;LbO1wgd2n;@a&Ew3Wk^LjXaGZUd2n;{VRL9i
::VRT]tLvnd=bVp[$NMUnmP-[XmZ2(_Zd2n;[Wpi|LZ-S?zb7&lVa)QrcQ+P5WVRL9uVRB)[07G)laCApyZc;[xWN(Q&Zvb.uZ~$.sZvbKdY5/Qp0046UZ~$.sZvbKd
::Y5/Qp002^}Z~$.sMF4mJbO1vDZvbroPXJ/7Y5+KLasY4uV,qjhbO1B}E(yZzYyfNk002]OV]ef/X?MmiX?Md_Zf8SpZE$aMWmf=FaAQJgZe)e0XGU]wZBuk|X?Mmi
::X?Md_Zf92jQgCBabaH8KXGU]mWmf=FaAQJgZe)e0XGU]mWdKreV@lFyZevMqX?[5}Y.xIBNMUYdY.IpaaAQGpd2VAvZ,6dFWprgjVQg#wPGoXHb9ruKLu^efZgfLo
::Y.|8dWO74nX=QG7Lt$+eG5_PoO8_v)QvhE8MF4F8bpUJtVE}XhX#j5kZU6uPO8_v)QvhE8K?&X^bO31pb]u_jbO31pZvbupNdRsDbO2=lasYM!VE}9Z002t?O#o8?
::UjR}7WdLpfWdL]oVE}9ZNdRsDbO2=lasYM!VE}9Z002t?O#o8?UjRq|R{&+?L/wH+O8_v)QvhE8Pyk5+L/zm]B?,r0H~@$^cmOQ_B?,r0GyrG.cmOQ_B?,r0GyrG.
::cmOQ_B?,r0G5}},cmO2/FaR;DXaINsEdV6|FaR;DXaINsB?,r0G5}},cmO2/FaR;DXaINsB?,r0G5}},cmO2/FaR;DXaINsB?,r0G5}},cmMzZ2m$~A4rTxV5C8xG
::(3;_rDzaV6RsYEEgJi]Ts7S1A1poj51poj5xJayQ1][s61][s6$VjYg2LJ#72LJ#7,hs8w2mk/82mk/8=t!)=000001ONa4=t.;?000001ONa4^)_m6000001ONa4
::2uiGM000001ONa4m_JQ^000001ONa4C_zns000001ONa4I7-N-000001ONa4NJ]}1000001ONa47+h,b000001ONa4Xi2PW000001ONa4SV]pG0RR911ONa47+q?c
::0RR911ONa4I7zH,0ssI21ONa4,h#Ex0ssI21ONa4s7b7B0ssI20{{R3cuA~m0ssI21ONa4xJj(R0{{R30{{R3h+Jw$0{{R31ONa4m_SW_1ONa41ONa42uZAL2?;{9
::2?;{9NJ,[02?;{92?;{9C_qhr2?;{92?;{9$Vseh2?;{92?;{9^).g53IG5A3IG5A00000000000000000000(Hw.a09FqP|F3Zi(Hw.bz#&6Pzk7+i(Hw.czz{@o
::ziOr,(Hw=ez@at_zr-Y4.4Ox=Fm)U_FQPF4U/qFCz;=Bee_[{=(Hw.cfR6GF|35-x(Hw.dKo;.ezsOq~(Hw=efLgLAe~05J(Hw=eI6]A_SCA^J5+T6d00000zv1Kn
::000000000000000000000000000000000005C9SYU^_8J4ge4Uazw0b7yudof;(xr8B,SV_uj?qg2];|tyAb$M+^LkB_(u|gW;ls?,~f4zwxH#K&K+ts.MSuq7_^-
::8}^w[3o^$Nfl9Y+EBgF_v7UWlHt(K[hTx_J/Cq)F--.?tu|qvgqYN,_ogkIQBfp@~^0V!ak=fN-]_wEeJA1jiq?Ly]mluipy-XvSShGMpNLjB&k~?q;AIyGvSQEwJ
::KK=tjq[p_)Ajxx1PZQ!/5snv4oU+MyoD~sBkZ5FW1~wW.hO1eNxJu4~fX9!]1uR.gmk[=o|H&Z_am!^fj7FnMqc^W($;]wtX~3UueI?-8w5N3i6w[a|_?{!c?hO9=
::nX6{Xmg&7N;YPj(k_Km4y!gQ#Uj8Xrz~i5m@4ue;pCv,z1?Un|Syr)T1LpBeoFDM+0k{~5y0P5Lli.0(q-;|wQjz_nHr9O7Vj1Z~i&&!E!an;j;W}J_Z@{rPpON.K
::.Ic6Jhco4mhcHJ)iG}x3G9g/Y]Zg./#mnnNgY,6;PG,3o+9-S;1PqBlhd]6$I8$0?ugt~|4,#xCod_p4cw6_Fw+Ka~M$N!Lux,abSEM(Ti6-XjsHxXNla0[gpCB1n
::0000000000V|/ge[[sF!Fac,P{[1H]&7V##_dLTtt;;8goTPHVxBZhQHb3{wG]OS7ao8~x1ji&87@uT]2NHnd?nE~x34;(e8,W/lQajeODdR7MQ^&qJApEggYRkSk
::N=#VK)C[1ILrpV;Mfn1MP(}WgQKLYQlASp9ytdjQ5dZVi&@uOlUzbD|#HW5eWL-6]V1ZBEA}WxGM))(2.d-pa/4)T2Nd^cb!qco_k)K0m=g2p0jnz+6Y,zH[WqPg&
::x^Bin9Hz9!=.qT5OTCMVa6YwWNCWl_VKrB|hQS[4/rN(lY1xjHn/wVh(Q(PijG?7Qzve;{L76QNuvEJiQVD9-FgB$+zd+m(f&Dh;eB)KSn=k+|G?$^=#NO&4RC|/&
::rotmV@o5?nLi+o^2ri,!DA]?kc3YxJZHv),a_]UShG?_/+TCU[U1heCY/Z^W{q4EhUKK_Hr/VM2kl3pLjJ)qd^vBawxU+qD([3L0&0CYR!LPjo0TYUAI,}1UPiNff
::m.5ff[U.T0maKFl=dCq_/_uk|9ChDrNAVhQ9Vx|$Z@|F(su/c.{8m0o#@pBpn&ltsc-Fb$AKj=khzG|pu[VqjCxGl;U{Qam8MR6cE#.QjlgXU#px_[At}6Ag$m^d2
::gHxGd7b]sQx^8zl/b|0ORUr)01wDfY_Q_A4?t3d4Z16Y7;nPkf-lX~/B5j4{$ulF4rNb0SK_h3fs64Liicu?ILt-Sp=Aj)Sr/XZE[oPh|dpc/kI9Omm.uZm;d32^r
::YfqyG5OvGFC[rgk^SDyLkDzhUo9vx,i;wr,qqO}@RbVPQ-Q3_u0o8OPicBKvDfr+]e3;o{rdY0UD={Spp@wGKh=tfp]c]kNQbmKO#oc+aWT1ZP?@NkA7(wb[N^^~{
::A@=URMNRQLsc2W7sY,eW/sHY~o6AN71=va;$)-3YE1mz.uvWR)wT|=l)vkiv_3wR0Nm{rs{M1X@o-8VeXD.TPE^8BC)x5q(1u+@,5gsc|KWbS4@aE.365zvo1ODhX
::Je09F)O&J_W8TR{X([nURkV/qgz7=)tzBIj#C@2ek/({W6)g;6[5m_b($U&5UVOO-OJ5Yt.!hc(5Qo9qPWyP?1,B{cpkiK|u/rgY{vPL@_@_ya000000000000000
::00000G8F(.[FM]K0Kfw}FpA9q0T}=QfF&F_0KkpX&gW9H91Z{gIXD0S0029a8zj/J91Z{gV@^V}005_l/#t&I91Z{g8(3cL0Klo52D8=y00000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000C{O@Z0000000000EK?jgkWc]s0000000000000000000000000^+q_;8c^fMEKvXe
::Mo|C(R8ar_a!~,PkWl~tno$4&v{3,6(_|(Y;WT@s[=,W+1X2J15?fyFCQ;-ZK2iVxOi}/;Vp0GAcv1iWgi.)ikWv5uno;A(q,4F@u2KL1yix!F00000^+q_;8c^fM
::EKvXeMo|C(R8ar_a!~,PkWl~tno$4&v{3,6(_|(Y;WT@s[=,W+1X2J15?fyFCQ;-ZK2iVxOi}/;Vp0GAcv1iWgi.)ikWv5uno;A(q,4F@u2KL1yix!F00000YXD4S
::aztr!VPb4$RA^Q#VPr#LY/13JbaO]/azt!w0046UOk{FLWpqSrY+D~lWNc,sc?qjgaz|x!P/zf$Wn]_7WkF;Qa&FRK004jhOk{FQZ))FaY.|7kf(ffpa!-t(Zb[xn
::XJtldY.LYybZKvHb4z7/004#nOk{FVb!BpSNo_@gWkzXiWlLpwPjGZ/Z,Bkp.T-Q@Lu^wzWdMZ&PIORmZ,,m2bXI9{bai2DO=WFwa)Ms&sR2&OQFUc;c~E6@W]ZzB
::VQyn)LvM9&bY,e@wE;3aQFUc;c~g0FbY,Q-X?DZy]Z_zEQ+P5Tc4cmK004vnQgm!VY/131VRU6kWnpjta060wY){crWk^XVZ~)spQgm!dZfSHuZgXi;baH8KX8^0p
::Qgm!dZfSH@ZfRq0WMxxya&pa7004CaQgm!mVQyq]ZAEwh-yqi|Y,cA(WkzXbY.Dp)Z(Yb,WdPs=Qgm!oX?DaxZ(Yb,WkzXbY.Do+qX&DiV{?U]ZEyepr3YVkV{?k4
::V{LE&&@E8|ZDVb4007VjZDnn3Z-2w?.UoAZa${|9008j]b9ZoZX?N38UvmHe1PFIyb8Ka90000008jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_
::08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_08jt_Zgga9Y&XMMYybcN00000_dYzX00000C{O@Z0RR910000000000
::C{O@ZC{O@ZC{O@ZQ,dxacyvQ=ZBJrqNN/azE[W)M0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001yBG009610x$|N5.=JtA}}g2GB7$YLNL5C
::!!pe?.ZJbm6,C@,q&]WLy+@o!(ouTl0W}6S6E!3@G(MgpL]V.0cQt}Fhc&Qnt~I$ezBS7=;u(j&]+(+ED?gPZJ2pr,UN(hqZZ?/1kv5z,p,F5I(]GWk]+?=GDK|7X
::IX6Z)XE$//cQ=GLnm464syDYc/5X|x[HhQ86F43@BRDWPWjb(=R6AxnYdd(5nmeUCsynwk,E_}n=R5Q}BRwxYMLknJe@5(oxjo7~3qBD)Ek4,j]gj7M20tx7I6pl;
::N;UjaZ$ElJe@N?rlRut6qd&}e?p&8C_#&5x03ZMW9033T2rwQnDKIWDJ1~AQq&agQFflbTLNRGEbTN4_hB22ht1.4QyD_Wy(oSCD.!belC]9oLI5I]tTQX+cYchB/
::+H3.pCo[AcQ8RxtqcgHI!ZXY?;1^Lz{4+kL7Bn$5Iy6EwQ8Z~ZsWi;r.!uX?6,Ye~mo?mO$2HwG;24F4AvP{HIW|5vOEzCNXf|#)w?HT)7dIg{CO1bnV?fL#dpEf]
::$2a{q1vn2lA2=/IUpRO/fjEjdnmD33-c[Gl]f?+E1vw2lKRHf0S~-AnZ#jlJw?iT)89GfmfjWvhnL466sXDki,E.=k4LcM(N/^(hiaU!umpq^6Aw4}kXFY?Gi9KyT
::dOn/!(]{|aLqEtr05AXm7ytkOGB8~,#WB;|;S^#?2r@8h06-i$d/kCdWHD$lq&o{9v[yIf#4,e;+G]#K;T30q]fCM~1TqXV6fzt#Br-]AG&_FgL]4b=R5DyLfHsUa
::m]P#~ur|Cl$TrkA/5O^w^&/ML5H}n,C]s}WKsQV_ST|&ha5sE6h(Plspf{{HxHrT&ggA]ilsEtY00000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
:x86dll:

:x64dll:
Add-Type -Language CSharp -TypeDefinition @"
 using System.IO; public class BAT85{ public static void Decode(string tmp, string s) { MemoryStream ms=new MemoryStream(); n=0;
 byte[] b85=new byte[255]; string a85="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$&()+,-./;=?@[]^_{|}~";
 int[] p85={52200625,614125,7225,85,1}; for(byte i=0;i<85;i++){b85[(byte)a85[i]]=i;} bool k=false;int p=0; foreach(char c in s){
 switch(c){ case'\0':case'\n':case'\r':case'\b':case'\t':case'\xA0':case' ':case':': k=false;break; default: k=true;break; }
 if(k){ n+= b85[(byte)c] * p85[p++]; if(p == 5){ ms.Write(n4b(), 0, 4); n=0; p=0; } } }         if(p>0){ for(int i=0;i<5-p;i++){
 n += 84 * p85[p+i]; } ms.Write(n4b(), 0, p-1); } File.WriteAllBytes(tmp, ms.ToArray()); ms.SetLength(0); }
 private static byte[] n4b(){ return new byte[4]{(byte)(n>>24),(byte)(n>>16),(byte)(n>>8),(byte)n}; } private static long n=0; }
"@; function X([int]$r=1){ $tmp="SppExtComObjHook.dll"; [BAT85]::Decode($tmp, $f[$r+1]) }

:x64dll:
::O;Iru0{{R31ONa4|Nj60xBvhE00000KmY($0000000000000000000000000000000000000000fB,mh4j/M?0JI6sA.Dld&]^51X?&ZOa(KpHVQnB|VQy}3bRc47
::AaZqXAZczOL{C#7ZEs{{E+5L|Bme,a00000P)=U$WQGI+0$agf0000000000[Bl6&3jzWj04e|g02&.Q00000P!IqB01yBG008_H0000001yBG00IC21][s600000
::1][s6000000Du4h00aO4Y,^#R0RTV(001BW0000001yBG00000000mG0000001yBG00000000005C8xG00000000000AK)BMFao;0000000000000000000000000
::000000B_]RhyVZp000000000000000000000000000000000000000000000000000000000000^-S74(/S4c000000000000000000000000000000E^7vhbN~PV
::uqXfk01yBG04e|g00aO4000000000000000AOKKcE[WYJVE^OCAQ1on06-i$01]NI04[Lk000000000000000KmcICE[[;8bYTDhMFao;0AK)B00sa606-i$00000
::0000000000KmahnE]=jTZ){&ehyVZp0B_]R00IC207d_-000000000000000Kmag8000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000|0S|f005AX|0SYP005AX|0R.9005AX|0RM]005AX|0Qx!005AX|0Oz6005AX|0OC?005AX|0M!Z005AX|0Uv3005AX4;Cd8
::00000Q&HmCAcOh=bUcIl1a(;~jTKrm002yh!$mR4NR5gh{{R0$xCQ^K0O$fH002mh4LdUc0O+2V002mh1[ABb07!_g?jwW7Tu=Z2NQ1/6xB(nF09)V5kdTm(kdTm(
::Wk_zzB_]R007#2KU_dI{G15qjNHG5/girtgkdTm(RY.~DQ&H&]G15qb;nTy@?_-LH0Z6(MiD.c$0000@jYK3cNcZtbjZ7pcNV[H{x{M$I002l2ufj/WdPgY6TFq85
::NCD8g2mk/8NQp!wDCo+q000jtL@l2D5d&nzUHHkvkdTm(kdTm(kdTm(MKQ[jiv+?8jRXLR!a;3_!RiM=f#ClB{{BJ1!U&!l0RaI4YtkD/F~UKKz)K,l5HZk2G0@&t
::2thH?L[~fZi3EvB|G_Ov_2=/h!/p}WR!E7~NQ1(KQ&H&-NQ3Ms=t~/^0ENJL5lDl@C_gI(NQv27Ug/JT002mX#3+.{!/p}WkdTm(kdTm(kdTm(OpOI/JOBVOzz@;,
::0YQos5Qr23NdLe{gZL12@8A^dRWZOwiRDOx;nTy@?;|wS0S^qzBx})9gW@a06cmUQ0Z9MANQ3wgb@eE+kdTm(RY{4/F~GSA0000/iRD35L5b8@R!oV/Q&s4=NQ30@
::NQ1;HO[.1)jeI0rNXJAZKmY($0Q0NIL@k?Q0000/$3!GZ00000NXJAZPyhe_0LMfmSPXyw0CWpM4.f)m5e0[V002mf1&ojF07!-vbs9,G756d#07#7u1~UKv=$jG&
::07!_iWHA5$MKQoJ)#J$3AOHXW[Ikp40000/jZ7p!|ImfNbq6uP?1F_{07#1k7&?0;NQJ;48c2/5+G_17NR17;G5_SRP!a$DNQnjcFaQ8ZjZ_E]MKQ[pi&cXy$3!F_
::00000NQqP=C^&U!0000/jTPc70095cg}_,CNQ)uvFaQ8Zg}_-hNR1WWG5_QbjSXlr008Ly5dZ,4i3OH0002mhR3uPEG09AeL@lQ]iBu#YNQ-D+K+MNl0095cg}[Jl
::TL1t5NQ)uDFaQ8Zg}_-hNR1WLG5_QbjSU;!008K,5dZ,4i3Msf002cX$-_sq002mfOe9cDjYK3]|ImfN4}=,1|Nlsf1$Qt207!-vbs9,G6=5/}07#7u-A#nC=x.4K
::07!_iSTFzpMKQ[miQq^y[;[wJBvAj,g}[Jl-W!ClNQ)uTFaQ8Zg}_-hNR1USG5_QbjSZYJ008JQ5dZ,4i3NHv0075CBp@6+002ylOe8!?iP,XV0000/i&cX@|ImfN
::50$_3gM1_N01vj;bS-4W1s5/@07!-vbs9,G6^7Ci07#7uN.-Qc=.(^k07!_i^&8qeNQ-D+NdM4CgM1_V0CX+#iv;EO002mZz/zl)jTO8x002mh4HYo}0O-a]002md
::1?.LO07#2WBvAj,NP~PNKmc@vNQ)sxF8}~Yg}_-hNR1UXF#rHajSb,1008K95C8y3i3RR1001&4NQ-D+K?yH4jb.48,jrv.L0nzKkdTm(kdTm(SBckFNQur;Oo^ut
::gX~a9iv;cV002nGL@l1}0000/$3!GZ00000$3!GNAOHXWNQJ;48c2/5WH0~#NR171FaQAP2oL}ONQni}E(u?UF~Bj?$3!F_0002-LAe-J002mhOe8[6)1pNt2Qk3u
::&K!iXNQ)t]E(u?Xg}_-hNR1VrFaQ8ZjSVO/008K{4,(p2i3L^J002mhR3u16G08;Sz)|WsBtS[sR3sp}41fRt|ImfNbhAi{1&EC807!-vbs9,G6=]U407#7u/x7OI
::=ywkQ07!_iU[iavMKQ[iiTFr~[;[wJBuM|zg}[Jlb]rhWNQ)ubE(u?Xg}_-hNR1UaFaQ8ZjSZwP008JY4,(p2i3Nf#0075CBp@6+002ylOe8!?iP,XV0000/i&cX+
::|ImfN50$_3gM1_N01vj;bS-4W1wSqT07!-vbs9,G75Og!07#7uQZE1i=/saq07!_iAT9s]NQ-D+NdM4CgM1_F0CX=&iv?z8002mZz/zl)jTLh,002mh4IM840O-y~
::002md1uHE805Q[@i&cXy|IkQ.#88RYTV7wokdTm(kdTm(Q$/b.MvDxQLyZIpMTy8k!RQAi{{H]{L4n_^0RaI/Yrq?pF~CEO1OP/d!bFL~!RiMk{{H]{f#LxH0Rd~$
::8!]yCjT__p!olhXL4o7_{{H[f/sF5x0c-A5L]0Y$iOWGT)=pIQiP|y4MKRdH!U#dZ$OuF-$T8Z&zz{))(^pr7LWu/CN(mu0gZcyyg?V1=|69Y5kdTm(kdTm(gZW#3
::6hX&T00000xK{uG07=II00000!(OL$;v~|LRzX!wiN!&wO]M7_NQu{0Q/Ew-gXHi@f$U&c004]/f&,Ud1pstjf&,Ud1]{$cF~EWP000C44~4[4002mhoFs$,002md
::_AChlBrpL007!}2=/s,#07!}2NQv@2tQi0RNQv[HW57(^!$|@~iP@k05a{-6002RWT?wa9&js;a004pd000F5iIgNT0RR9[jkF|$0000/jkF{&0RRAX4i6AV1P?8}
::Bs2j40P8nMjZ7p(x+1/W0O)!/004],O]NX^)hm@!Bt&S(Mg-&&B!mC}01yBG01pw2Bs2j40O,DU0050k{4vsrOe8?y4[_}J1Wb+gBtT7x^)-Xj6zFCI002mhPZUgv
::]5_lV002md,.VM[=;gT-0J/zW002msNCCr0iP_Aw0000@jYAN-5C8xGNQv3#JpBLvOo{nOiQ4D]7XSc)KL7v,07#8PFieenBxH4DNQ)v8F8}~ZjgFWA000jVR|F3c
::Q#eSA07!{LFi4F=BveR=!bpikBsl2N^y7M$i$o-iOpQhaO]NwPjZ/WWDZ+sJ!RQA0|NjpVTqJZzjYC+u5M)4o4.s2P4.up!Gywnr$3!F_9033Tiw{hVMifnn_ACgc
::1WYNwi9{r1=)^]|0E;K;WQ|A]L5WQONMp)9NcaE$Nn=d^NQuYuq+CYcBuI]A$T7fMUSC06L0v(!L0@^NkdTm(kdTm(R!E7@Q/E|]gX~C1iv@~f002nGL@k!?0000/
::g}_-hNR1WQD,ymUjSc84008KH3jhE}i3LU~001&4MKQp~L@j?p008hoxflQd07#8YBsl.jG17(=bT?$g1?Y$E07!-vbs9,G6?Ka307#7uqALIZ=r/=h07!_iz$pL#
::iP}kt[JNeHBsl.jg}[J$!bpRBBsc(Mw&T-rNQ)uHDF6USg}_-hNR1V@D,ymUjSXNc008Lq3IG5|i3M(c001&4NQ-D+IRDT{gTzRQ,jrx1kdTm(kdTm(kdTm(S4fH1
::R!EJvkN]MxQ&H&-NR5i10000/gX|zkiQ4Eb6#xK8iP_8@^y7OsF!&reNQv=CiP}hm@hxn]6#xK8iP_A-_~Uw+IsSFm=r8yG|L6-$|NlsX#2_qC-DM7;TV7x3=oA0|
::kdTm(kdTm(R!E7~Nr}ryiON$,jb0E+iSbB,#.IQI07!&EDCoWv002yh-32;t008K56aWC|EcXBZNQv1;gToL]iQ4F$6aWB7IrDYeOo_d)kP_p]=t~p/07!$xC_gIf
::TTF[CUg?&i005AXkdTm(kdTm(R#QlW?{v,ROe8@+[D?07g}[JpQUL$}NR4zPJjX/NAOrva0719}0000/i&cXyNXJAZC/$Ke07/4QNQ+hfMF0RujTHtg0095fg}_^W
::gM1_B01uS~04V@fNr~}6xC8)I07#2WBtS]VL@kEx0000/jTQ1M0075CBp@I/0095fg}_^ufqW!9z]DKKxWK3Y0J/wV000k0L@k@e^zw@4!e+sDtSA5g$3!F_1ONa4
::Nr~}Di&cXyLAV3}002nGL@kEx0000/jTOi&0095fg}_^ufqW!9z]DKKxWK3Y0J/wV000k0L@k@e^zw@4!e+sDUMK)nOpQz=NXJAZAP4{e07#2WBtSv93jhEBNXJAZ
::C/$Ke07#7$o-|)V|I?xQcr.}55D]g)5fKp+NQ,=yNJu&,b_MB{_2TeiNXNkb|NsB&3P_vS5fKp+5fKqci3Rc}002mfOe8@+i1YvdF~CTJ#8^Ki!/p}WkdTm(kdTm(
::kdTm(NQ)u[Bme.zkdTm(kdTm(iO5Ka)M,ZLJpcd(08NR=bPPQJ00sbc3h5F8008Md0000nz{8M_kdTm(kdTm(iO5Ka)M,ZLJpcd(08NR=M2k!$D0B=x000I6bqeX7
::1ONc)xB?tGF~Gx-kdTm(S4[e=R!E7~Q&H&-NQ3M]NQ)uzCIA3P$3!GB00000NXJAZH~/^u07!-vbs9,G6(ol307#7uDkuN|=+VU507!_ih$a94MKQoJ)#J$3AOHXW
::[Ikp40000/jZ7pk|ImfNbq6uP?EZwY07#1kJSG4DNQJ;48c2/5^$L4WNR18OCjbEGbO!)cNQng;CIA3PjZ_E!MKQ[pi&cXi$3!F_00000NQqP=C^&U!0000/jTOc!
::0095cg}_,CNQK,VC_gM1L@!@LNQJ;4T}X_/[h1QPNR17LCjbEG90vdZNQng{CIA5IK}d[QJSG4DNQJ;48c2/5hbI64NR16(CjbEG]acO_NQng;CIA3MG091Z,t!7#
::002mfOe8q})1pNtoas3K|NliX$uZJMiF^m|LAU^_002mdbR.~1i&cXq|ImfN50$_3gM1_701vj;bS-4W1.~T#07!-vbs9,G6,wmV07#7u[-JTP=!XUX07!_ipd|nR
::NQ-D+IRDT{gM1^~0CX=&iv{W=002mZz/zl)jTI9o002mh4ZS7-0O)Q&002md1;ND=05Q[@i&cXi|IkQ.#6XGITV7wokdTm(kdTm(L02+rK~^OkK~z/(R#QlW?@lEt
::FhKUk4.bW]0000@WA/pm$4H6ON{wtX[JWfyL5cKCjXkz7002li.F6?HiRny;_sfz?|Nl(lP4GyG?P)5r=vNQ_08EL]?+c3;6]k$c07!}1==1vj|4oJMbPGs{-DwV,
::=ra&i0E7MzbPZ08L]J;EiV&SM5OxHKH|sG)54Org54PGdz+3m7iNSOeOpQ;hNcYe|I#d7wbp=d_)Cg-zImvYeDb7KO]hAj#xB(nF07!$xC|h1&T|rzyT|r)!U(D}+
::kdTm(RYZx-S4[e=R!E7~Q&H&-NQ3NHNQ)spBme-N$3!GR00000NXJAZNB{r/07!-vbs9,G6=x,@07#7ub|nA-=nDk]07!_i+FS_[MKQoJ)#J$3AOHXW[Ikp40000/
::jZ7p!|ImfNbq6uP?E.|c07#1kh$8@1NQJ;48c2/5L@r-KNR16EB?){EzytsQNQnh$BLDzMjZ_E]MKQ[pi&cXy$3!F_00000NQqP=C^&U!0000/jTI6o0095cg}_,C
::NQK,VC_gM1fFl3]NQJ;4T}X_/3@&?nNR18CBme/DXaoQNNQnhuBLD#FK}d[Qh$8@1NQJ;48c2/5);A[[NR17vBme/DKm.5+NQnh$BLDzJG091Z,t!7#002mfOe9GE
::)1pNtoas3K|NliX$uZK2Y$Py2xB(nF07!{]Bq(IWOe9E1iF70(|ImfN50$_3gM1_N01vj;bS-4W1qUMl07!-vbs9,G6[VlF07#7uIwSx9=-6TH07!_i=pq0BNQ-D+
::NdM4CgM1_F0CX=&iv=;w002mZz/zl)jTKuY002mh4Fx0s0O,;n002md1rs6w05Q[@i&cXy|IkQ.#8_?gTV7vX!/p}WkdTm(kdTm(kdTm(K~,upK~z/(R!oV/Q&HmC
::C^#&jL5cW5^s~Iu/15Cnz)S2I2Sho|cWz0E&1DXRM2W#jjTAaWiNH/T)nyKd]Qv@UNQv4]iP7kx4FCX0jTPE0002md-32$P|NlgdW$/XmEypbY07Zr5bR$TOdk{#8
::,-GNs5J.voNQwLCYz-VaOo{49iTUV)_2YXw,oiK;0RR91NQ1/ETV7vXL0myy!/p}WkdTm(kdTm(K~-IiRaZob(r@W=&SeOlV1qq~9RL6TOo[afpa1{?NQ;l^umAu6
::NR5Ofpa1{?Oo[ynr~m+}OpBx?xBvhENQp!wSWJtoB+|Xw0CYY_g~[a|NQKgLG+y[KNFD$Hbt_2]iv&Sw0000/IR!=[004Cv=vVmv|4oVMO]M+0iRy{[=tuPb|1rSp
::JxGlWZ2$lNNQsmrm/e9)Oo?D!Na$)^002yhY$Py2iTOy0,.VLKBq(UaL@lQ]iEJbwNQ/ytm/e9)|IkQ.#9(+rT|rzyUBi&(kdTm(kdTm(K~z/(R#Qlc&SeOlV1qrZ
::8~]|SOo[ynr~m+}i@k&L0000/jf5nq0000/i[YSb0000/i9{q=NQ;l^zyJUMOpBx?$N(HUbU8@c$#gVKISq0h004C?Wk_zzB_]R007y9na2+]ubs6Y]^y7M,iQ!3!
::=tznBiSg+h]Z+.b!0Sv&jSY7H|Nl(hge0H;004=UB$xmI08EKYBuMCu2mk/~iDV==Op8n/NJxp;NQrDDFieYtB&lBQ07!{]Bq+oNB$xmI0Eu+YApg+vgT!E4USC~7
::T,Hu&kdTm(gFV@B0001VBS@kGbRI~H1=Ab=07y9jbrNMriv&Sw0000/IR)xf0049zQ&H&-NR182|Ns9/gX|#a5C{MONQ1/6NQv27|KP^3j2i#|00000F~CU21(15}
::0000007&CLgd6|?00000NXG@&8~]|S0002PkdTm(kdTm(S5rud&SeOlD1$vv8vp;RbSp[O$#f=VNQ)p|FaQ7mNI3/j8~]}y6iAH~G#dZ^NQ),o6]}ds0ENJG7f6i^
::y#N3I=!XXY07!$xC_gIfTVMa-NR1T;8vp?gKmY($NQu|/t4PNK00000NQ1/EF~D12!/p}WkdTm(kdTm(S4fH1NQuf/Q&HmCP+LnjBrr(gbR.~1iP_AM?i^?S)lN;N
::iSbE],#8xgI{,NMz;4Z3ja)!]NQwGLiP_9^?i^?mF~CTP-DMB_Bp])UOe84)6?mEL0ENJL8tW7?)lN;NiSbE],#8w^I{,NMz;Izi!0QD^i$o-SNQ1/sTV7wokdTm(
::kdTm(kdTm(L03UmK~-IiRaZ!jJ]vyA09HtiufPES08?bb)=pOWf$XRN002mhv@P!K002mdj3n?@0075CBy;1)002md[(6SeI{,NSgd~sv002mdoFtF{004;ZBy?oL
::_bdfK=vxc_0EEDGR!E8aNQ1_]NQv=CiTdb83/-Oxz/!lAje8)SiSbB[_sgwY004x,bt6cPdoW0e[kojK=pPIK0EEDG5J.+CKu9^7b,#7p0002&OGr8IxB~zH0CYi&
::ZwO3{Y$SAxPYg)l9nU&d04eE&_Tukw|G|UE|1r|{[ei.aL5akP(rFHw|I;0gcK0#TLHG3Q1x$)Q|I.2JiNi]W[JNaANNf8HNR2JMBLDzQjbtQrNCEE/wpRiVwnqa;
::iIgOe0000@iQ.6!gd~]&008KP3/-N_i-2Qze-Ws5#Y~GmR5}0vL[D=!|NnF&|Hp(K|1r|{^Ybf5i9{r9Oo_z]|JOOkcJ@vS^jDv|?jq4T/X)h_K?[}{iv_LY002mZ
::z/zl)jTKHE002mh4P6}o0O.?F|Nlsd1,/qY0RPZPjZ7qXNx|g=NNd{-iN{Ed1v4oC07)JGO]ba9=&48S|4E7POo_&1iSbCd06?=2Hvj-sNCQM9cua}BB#/0A07!|1
::B$xmI0O;M)002mhj3j]n002md[;[q;B!B;^0RI+CIRF4ijg&ya0000/iSfsTB$5CC009620RI)zIRF5/r?P^ZMT;=UiF^nL55I(YkN]MxNWtL^$3!GJ0{{R3OpOJ.
::8~]}_L@l?9i.aVA0000/D},G70000/nMn8f|G?FGLJt5j)uqVQP)h1D1c]i?NJNS7^wh+Jj3n?@004;ZBq$HJL?(N$R3tFEKmY($i9{qI=#S^B|44zvr~m+}TV7vX
::L0myyL0(/$!/p}WK~^OkK~z/&NQur;Oo^utgY0O7J$4rW002yhge0(4004_uB+|Xw07#95B)MMg08ELDB+9-o08ERdB,,{(07!{MBv@#~tR(C@002yjv@SO7004Ag
::NQKFCTS$e{bXH6_4KEk~0Ci1FIR!2l004DFWk_zzB_]R007y9nBp3hybuvkdKrl&E$Vh|u{dXnkDDwaRO]NYMiRes//+(^#81Dc7NQ-A^G1C7P1ULWyF~I9VNR16a
::|Ns9/iIgO$0000@iA,F(=r02R08EK=BsfWl,hq=.Oo@nHFieX~BuGq(WF#m]i;Bg(0001qY$PE6(_5,CXj[+gL0myyL0.d;kdTm(kdTm(K~^OkK~z/(R!E7@Q&s4=
::NQ3NPgFR(y0000@iHsz/0000@i@k&b0000/jf5n+0001syd=l~002mdL@l?9i?xHj0000@i=.sj0000@i?xHz0001VTS$e/bXH6_H6s[Q0Ci1FISnEg004DFWk_zz
::B_]R007y9n7#9ElbuvkdK_==F$Vh|u{dXnk9P$7EO]NAEiQq^y?WTU24DJ8^NQ-A^G1C7P^&/9lF~I9eNR16e|Ns9@iG)Du0001qlq9GC008JA0ssI]iEJc5Nr~A=
::iSbN{WF$CDi.aVw0000/iEJb=i;Bg(0001qd@YALiF70(|IkQ.#9(+qUtK|5L0v(!!/p}WNQKFCJ4l7nbT+&MUljlV0CX+#iv@yD002mZz/q!;gFR6e0001V7iCO~
::1SK#4002xm1y2@L0CfdOImmP;Q&H&-NR17)|Ns9/gX}O!iBu#g=!XFS07#2eBq(IO#4t#S,;1hMF~Gx-kdTm(Q&H&-NR18k|Ns9/gX|!QR3td+SOEY4i(P{yNQv41
::)1pNtHiJFX6aWAKbS-4OJ;=5b0049(NP|7l6#xJLbs1$yixed=0000/ITgkg004CdNQoV^6#xK8gTx@P!/p}WkdTm(kdTm(kdTm(K~-IiNr}u=S4[e|R!oV/Q&H&]
::NQ3M-NQKf(i?xG(0000/i?xG=0001VHb{,XkQo2~NQv416}vS60ENJHBItVW|NnzMLlgi20Cf~div_LY004k]3/=aKNR2g382|uCjSZIn|NrQb0000;iTO#1[JNZ/
::NQtZ[m/e9)Oo_!4iL4}$0000/gTy#nUSC~7TtQv_/7pALJ{bT2Nr~CIfB,mh#|7RK00031002mh4cij{0A+yv1SK#4002mdd@YAHiF70(NQnj26aWC|pyU7lNR0+x
::69526iA4ZNgTy#7z,}BlT|rzyUBi&(kdTm(kdTm(kdTm(NR0)a6#xK1xC#IO08EL)NYVOCYsxT50l_T.Nho(/NQKgV5=n{B?,Gm{K_==v(_FI[|Lf]UjTQ11002li
::(~yn&J4h(V14xO_NQ,!q!/p}WkdTm(kdTm(kdTm(S4[osEE[m.NQuu[Q&HgA0096154J+NNR6~4fB,mhNQv=[L@mbrwn7exL@mDjwn7bwL@l=bwn7YvL@loTwn7Vu
::L@lQLwn7StL@l2Dwn7PsL@k#5wn7MrL@kc|w@YPqL@kE=w@YJoL@j@Yiwe3x0002!oZ|ogNR3P-c;9/$004!-iNkm^NQ-D+cu9&,LAU^_002md[;^+.Bq#s@0075C
::Bp_kO0093Ld[}$5NQ-D+c!|U4kmCRUNP+xv0RRAr,jrv.!/p}WR!E7~Q&H&-NQ3MsNQKFCJ4l7nbT+&MLlOW00CX+#gFQ)T0001WBV|a71SK#4002li1wRu20Cf?a
::jTIsi0093LfHMF9g}_)gNR17x|NsB!c?e$YNQ1/ENQv[DiP?9T|KLcC4f^&R0J/bO008J(?/L~qiv{Wu002md21tX&C]5iWUc.=)kdTm(R!ND|Q&H?-]dJBLNR6|g
::0000/gX}2iQ~?}0NR186AOHa9NC5x;Oo_d)KmY($==&Tw0O-?j|Nlsd,-^&K5KM{M=qCXH07yCWb=pjc-2|So008LK0000/jSW5^002mX#3+.#iP~Q200961OpOJ3
::9smF^zz@;,0YQos5Qr23NdLe{gZL12@8A^dRY.~DK~z]viN{t,iPlqz&SeOd[JNH~KuE^#Bp@6+002ylWF#O-$3!G300000NXJAZFaQ7m07&C~Bsc(7004vg4}KI#
::iSbN{/z+zW5a=5J|Nn#Q5bNhLz(XQy42l#6h,ShHNdLg=[JNkRBp]s,-enQ}BrwKA958^B@Ee4&4=6-=AP,4.NR4ISTV7v5TwTMEkdTm(kdTm(RWZOwiRDOx;nTy@
::?;|wS0S^qzB#jh?000000m6gg4~i5Nh!g=x|G.Ft^z.pF$.|J4kdTm(kdTm(kdTm(F~CHN1OY[b1OiBdzywHx^z.pO!/p}WkdTm(kdTm(L03UmK~-IiRY/93P#XXM
::S4fH1R#QlW?}W_dj3lrC002Y}w@zO,i(Y3ni/N^(0000;)dhpbbTI$_g}[JmGywnrW_RFVS_URO0RR9;V[Etl0r.J9P)=U$4}}(1004_akN]Mxh1)B=2mt]9i.42?
::004!-4}|(v002k;_$z&UNQp!wFi1IEBrp$#;NyEwgL[1B4}{tP004^~5JZb3NCEyy0sKgVJ](Ady8r-HOpQH75dZ,8jcg=XOpSCTP+UnNAV_J4bOlH|2J0C~iv&P{
::g}__nNsCt+NR3Pf0^aBH|Nn+-bzn[5TqI0QiRes/[;[qvBv4F=TqGbtxj-B^07!$$|4fNoBsfUNL@l=U000306+!LV07#1lO]N7CiSkT~TqHP1gUSCyi&cX/Nr]_w
::NsC7+NQnkaiCiQg{}lo.002mh1(a~[07.-#Fibi44~1j[|NlsX#t2D-#0cp.|Ns9/gToZ,5(![HNR0(&8UO&DgT+X@Ip_0Cmj3^$NQ1/]TV7vXL0myyL0(/$!/p}W
::Nr}jdN)5I.iN{t,iPlJi!3guDNR6^H0002F2?;{9NQwCKrAULoBupv5USGqIRY.~DS5_=kdI)5~(QnN;)[2Bl[JNH~K#Kv10!WF;NQwFAxZnT)NQwFAAm0D~NR3P-
::D2-q^0,ONe4.iH_4.tci0000/i$-vPiG!E_004^dPyxV-gP/Ha07#1koE88854TVV54S+HiIb!N002mhR3tEogQx&i07#2QR7i;LBq/wCL[xjUNR4IaTV7vX!/p}W
::kdTm(kdTm(Q&HmCFi4GDBp]tMOe8@+Z0i62NQv1;iNff+.T)hgi$o-qNQv1o),G5iE(u?XgTydf!/p}WkdTm(kdTm(NQ3MsNQux$ixEM&5C8xGNQ)$agTgTAblv~|
::g}[J#z)|9{D8rDDkdTm(kdTm(L07o_|Ns9&RzX!kR8@12Oo^&,NQu+)gX}m?i-Bi4D?z7tJ&=s/07,H=NR2=NcOpsu$1(1L^xDT?ulPub#Yl;S|JRAYOgZ?.]fA(&
::^x0/tNjb.KQA~|(Bp])Q{Yi;/NWtwONQv4^iRes//Yf,WBq(J7L@j?p0002!eE;LdNQv1=iN]oeiNZ{Y[JPYnAV?kw50b+3ImZvS)sIQ}h0=Av?jy}Q)f_-pz)[lI
::NQ1/UTV7vXL0myyL0(/$!/p}WkdTm(kdTm(L07o_|Ns9&RzX!kR8@12Oo^&,NQu+)gX}m?i-Bi4D?z7tJ.00Y07,H=NR2=NcOpsu$1(1L^xDT?ulPub#Yl;S|JRAY
::OgZ?.]fA(&^x0/tNjb.KQA~|(Bp])Q{Yi;/NWtwONQv4^iRes//Yf,WBq(J7L@j?p0002!eE;LdNQv1=iN]oeiNZ{Y[JPYnAV?kw50b+3ImZvS)sIQ}h0=Av?jy}Q
::)f_-pz)[lINQ1/UTV7vXL0myyL0(/$!/p}WkdTm(kdTm(RY.},xeNdR07!}DS4b)sR!oV/NWuC9NQ30@NQ1;HNR50XQ1hisiN{EZ#;?gt008r+NR50XAh_@x002q2
::tE#H1s/a80NR4zPQ1his53j/ViNP^^OpQz=Am|PN002mhW$;2KUBi&(kdTm(K~zbNK?taJ&eevo0031/iPcD&S4oNLNcZ^xQ&HmCFibhnem6/tS].D^-emBEFiDGi
::6ZlCvd=n]h14#eNO?5FHxeNdR07z[|Fiip4Oo_V^0p3Z8-ViFB#6kAJ0d-V[jX@gn0ssI2NSR3Y_AIp#btOrSLIJr90000[Ytk[C0l.LW([fE^-DVOc6VObF,Yl.J
::jZptdjY9uSiOxug=ShoMD7g#)002mtNr~a}r9r#_0002F0ssI2NcZ^oYr.(10oY7A+qN?QYsfH3jWi2LIbJAp8&T{&|4E6$xeNdR07!|[Oo^-yrAV1c^x$V2NQqn|
::D7g#)002yh$4rUN]QB0G#4uZ4UtK|5!/p}WkdTm(kdTm(K~^OkK~z/(R#Qlg9p4K807!&EP+Ir1bYe)}&|X2|0000;iQY^(LoiG]#dJ-biv{8f002#mU[&EJKqzxB
::Oo^)13/-NCNh#P!jeH~]Oo{UIrAmzqD[cjo=,QXr|45B=Bp|sA0002;rRxYxiNWZZ0RR9]iQwz5NQ1/sTV7vXL0myyL0.d;kdTm(RY.~DL03UmMTyQqRY{4}K~z]r
::jd@IuOo^&,NQuixgXHi@f$Wd~002#i?_5uyNrC)T0{{RIjwk]D07$s2s/a80s/a6;!TbbF53k[zh4x8}RnT?BO]tLU{!ER0Brr-Q{z-]0Fu4o?002#i_ACg@Bw$U6
::/7p0~NCDpSrAUo[Brv&Q0000/jdUbn]QB0M-32@Y|Nl,e^H-eF|IX{dNrUY$NQv1]iRes/?gX!{|Nl(h=twEpNQ3w=f8yz$0000;)fmw{Ls([v(P{9NFiDF=^)=iW
::NsCM,C_mcUa|}p1$af_7Ily+Y?j-Faz/-Z!iTX(1,.eS/=,s{A08EWTVCy4DImmbFOo_(^;xGj;Oo{nSi9{qQ=(Jw#08EQSBq(LPz&WRQQz&W1c-g2XQ2280NrUV#
::Njp?|D01~pIp=c8Oo{46iSbE][JxyMO]N/Jp#J~=?Bav4|45Bx$Xi}tL0myyL0(/$UBi&(kdTm(kdTm(S4fG.xeNdR09Hte#z=$gI82L3C_gItNQvU}rAdjvNQ3Aw
::Ogl([a}Y@4crdvP0000/iN]D#?,Ki$0000@iN{EZ,7K!EgTy#qU(D}+S4fG.xeNdR09Hte#z=$gI7o[.]QE~A0000/iN{EZ,7K!EiRQTs0000/iP!U_NQ1/UUSGqI
::kdTm(kdTm(|NsC0|NsC00000000000|NsC0|NsC00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002m$~A0&iaJ5C8xG000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000000000000000Pyhe_00000U^tz800000/4l1X0000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000006aW@g00000yhi-K000007yuan00000)nkDg000000000000000kSqLY
::000006aW@g00000yhi-K000008~^~v00000?qh+)000000000000000z&Be~000006aW@g00000yhi-K000004ge1T000002uJ,B000000000000000z$E.?00000
::6aW@g00000yhi-K000004ge1T000007f1YQ000000000000000KqUNW000006aW@g00000yhi-K000007yuan00000CP)~f000000000000000AS@W7000006aW@g
::00000yhi-K000006aW;f00000KS&s(000000000000000uqym&000006aW@g00000yhi-K000005(#nb00000R7d=2000000000000000kSP3V000006aW@g00000
::yhi-K000004ge1T00000XGi?L000000000000000fFk]9000006aW@g00000yhi-K000006aW;f00000c1Qea000000000000000peg+m000006aW@g00000yhi-K
::000004ge1T00000i&0xv000000000000000U@co#0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000000000000000b]x{jmINF-cmQB00RR91M_d)Vd2[7SZA4{eVRdYDOhZXT003)M
::WdL#jZUAKfYydL=G5{^BWB^acYybcNB?,r0H2_&0EdV6|FaR|GbpR~[B?,r0GXQk}EdV6|FaS0HbpR~[B?,r0G5~b|EdV6|bpR~[B?/5,E(wn9FaR)BFaRw8B?,r0
::GXP_(B?,r0Gyr4)0000000000F#s|EHvldGFaRz9FaRz9F#rGnZUAEdVE|)QZUA2ZX#j8lUjTFfV,qdf001Qba{xL3B?.~)TL2{ha{yfc00000000000000000000
::Lvnd=bU|Zrb!l?CLvL;$Wq5Q~002P&L/zL,K?$zyNdPkdG5_PoLvnd=bV-S-Z,p_@WqANYa)QrcQ+P5ZWqD9xa$#+&Lvnd=bVY7sa)Qrc07G)laCAgvb98cVc}rz]
::07G)laCA~.Y.M3{WkYXnbY,yS07G)laCAgvV{(;LbO1wgd2n;@a&Ew3Wk^LjXaGZUd2n;{VRL9iVRT]tLvnd=bVp[$NMUnmP-[XmZ2(_Zd2n;[Wpi|LZ-S?zb7&lV
::a)QrcQ+P5WVRL9uVRB)[07G)laCApyZc;[xWN(Q&0000000000Zvb.uZ~$.sZvbKdY5/Qp0046UZ~$.sZvbKdY5/Qp002^}Z~$.sMF4mJbO1vDZvbroPXJ/7Y5+KL
::asY4uV,qjhbO1B}E(yZzYyfNk002]OV]ef/X?MmiX?Md_Zf8SpZE$aMWmf=FaAQJgZe)e0XGU]wZBuk|X?MmiX?Md_Zf92jQgCBabaH8KXGU]mWmf=FaAQJgZe)e0
::XGU]mWdKreV@lFyZevMqX?[5}Y.xIBNMUYdY.IpaaAQGpd2VAvZ,6dFWprgjVQg#wPGoXHb9ruKLu^efZgfLoY.|8dWO74nX=QG7Lt$+eG5}6wayB$Ub9ruKLu^ef
::ZgfLoY.|8dWO74nX=QG7Lt$+eGXMYp00000O8_v)QvhE8MF4F8bpUJtVE}XhX#j5kZU6uPO8_v)QvhE8K?&X^bO31pb]u_jbO31pZvbupNdRsDbO2=lasYM!VE}9Z
::002t?O#o8?UjR}7WdLpfWdL]oVE}9ZNdRsDbO2=lasYM!VE}9Z002t?O#o8?UjRq|R{&+?L/wH+O8_v)QvhE8Pyk5+L/zm]B?,r0H~@$^cmOQ_B?,r0GyrG.cmOQ_
::B?,r0GyrG.cmOQ_B?,r0G5}},cmO2/FaR;DXaINsEdV6|FaR;DXaINsB?,r0G5}},cmO2/FaR;DXaINsB?,r0G5}},cmO2/FaR;DXaINsB?,r0G5}},cmMzZ00000
::phWy?0000000000000002m$~A4rTxV5C8xG(3;_rDzaV6RsYEEgJi]T00000kW2h(000001poj51poj5piBH|000001][s61][s6uuJ[D000002LJ#72LJ#7z+SpT
::000002mk/82mk/8(_bPj00000000001ONa4(_kVk00000000001ONa4/7t5!00000000001ONa4[J#$]00000000001ONa4fJ],o00000000001ONa45Ka7P00000
::000001ONa4AWi(f00000000001ONa4Firev00000000001ONa408IR800000000001ONa4P+z+300000000001ONa4Kur8/000000RR911ONa408RX9000000RR91
::1ONa4AWZye000000ssI21ONa4z+bvU000000ssI21ONa4kWBn)000000ssI20{{R3U_-gJ000000ssI21ONa4piKN}000000{{R30{{R3a7^GZ000000{{R31ONa4
::fK2?p000001ONa41ONa4[Jsw[000002?;{92?;{9FiiYu000002?;{92?;{95KR1O000002?;{92?;{9uuS}E000002?;{92?;{9/7j~z000003IG5A3IG5A(Hw.a
::09FqP|F3Zi(Hw.bz#&6Pzk7+i(Hw.czz{@oziOr,(Hw=ez@at_zr-Y4.4Ox=Fm)U_FQPF4U/qFCz;=Bee_[{=(Hw.cfR6GF|35-x(Hw.dKo;.ezsOq~(Hw=efLgLA
::e~05J(Hw=eI6]A_SCA^J5+T6d00000zv1Kn000000000000000000000000000000000005C9SY00000fJXdj000004ge4U00000l1BV#000007yudo00000qDK5^
::00000000000000000000000008B,SV_uj?qg2];|tyAb$M+^LkB_(u|gW;ls?,~f4zwxH#K&K+ts.MSuq7_^-8}^w[3o^$Nfl9Y+EBgF_v7UWlHt(K[hTx_J/Cq)F
::--.?tu|qvgqYN,_ogkIQBfp@~^0V!ak=fN-]_wEeJA1jiq?Ly]mluipy-XvSShGMpNLjB&k~?q;AIyGvSQEwJKK=tjq[p_)Ajxx1PZQ!/5snv4oU+MyoD~sBkZ5FW
::1~wW.hO1eNxJu4~fX9!]1uR.gmk[=o|H&Z_am!^fj7FnMqc^W($;]wtX~3UueI?-8w5N3i6w[a|_?{!c?hO9=nX6{Xmg&7N;YPj(k_Km4y!gQ#Uj8Xrz~i5m@4ue;
::pCv,z1?Un|Syr)T1LpBeoFDM+0k{~5y0P5Lli.0(q-;|wQjz_nHr9O7Vj1Z~i&&!E!an;j;W}J_Z@{rPpON.K.Ic6Jhco4mhcHJ)iG}x3G9g/Y]Zg./#mnnNgY,6;
::PG,3o+9-S;1PqBlhd]6$I8$0?ugt~|4,#xCod_p4cw6_Fw+Ka~M$N!Lux,abSEM(Ti6-XjsHxXNla0[gpCB1nV|/ge[[sF!Fac,P{[1H]&7V##_dLTtt;;8goTPHV
::xBZhQHb3{wG]OS7ao8~x1ji&87@uT]2NHnd?nE~x34;(e8,W/lQajeODdR7MQ^&qJApEggYRkSkN=#VK)C[1ILrpV;Mfn1MP(}WgQKLYQlASp9ytdjQ5dZVi&@uOl
::UzbD|#HW5eWL-6]V1ZBEA}WxGM))(2.d-pa/4)T2Nd^cb!qco_k)K0m=g2p0jnz+6Y,zH[WqPg&x^Bin9Hz9!=.qT5OTCMVa6YwWNCWl_VKrB|hQS[4/rN(lY1xjH
::n/wVh(Q(PijG?7Qzve;{L76QNuvEJiQVD9-FgB$+zd+m(f&Dh;eB)KSn=k+|G?$^=#NO&4RC|/&rotmV@o5?nLi+o^2ri,!DA]?kc3YxJZHv),a_]UShG?_/+TCU[
::U1heCY/Z^W{q4EhUKK_Hr/VM2kl3pLjJ)qd^vBawxU+qD([3L0&0CYR!LPjo0TYUAI,}1UPiNffm.5ff[U.T0maKFl=dCq_/_uk|9ChDrNAVhQ9Vx|$Z@|F(su/c.
::{8m0o#@pBpn&ltsc-Fb$AKj=khzG|pu[VqjCxGl;U{Qam8MR6cE#.QjlgXU#px_[At}6Ag$m^d2gHxGd7b]sQx^8zl/b|0ORUr)01wDfY_Q_A4?t3d4Z16Y7;nPkf
::-lX~/B5j4{$ulF4rNb0SK_h3fs64Liicu?ILt-Sp=Aj)Sr/XZE[oPh|dpc/kI9Omm.uZm;d32^rYfqyG5OvGFC[rgk^SDyLkDzhUo9vx,i;wr,qqO}@RbVPQ-Q3_u
::0o8OPicBKvDfr+]e3;o{rdY0UD={Spp@wGKh=tfp]c]kNQbmKO#oc+aWT1ZP?@NkA7(wb[N^^~{A@=URMNRQLsc2W7sY,eW/sHY~o6AN71=va;$)-3YE1mz.uvWR)
::wT|=l)vkiv_3wR0Nm{rs{M1X@o-8VeXD.TPE^8BC)x5q(1u+@,5gsc|KWbS4@aE.365zvo1ODhXJe09F)O&J_W8TR{X([nURkV/qgz7=)tzBIj#C@2ek/({W6)g;6
::[5m_b($U&5UVOO-OJ5Yt.!hc(5Qo9qPWyP?1,B{cpkiK|u/rgY{vPL@_@_ya00000000000000000000G8F(.[FM]K0Kfw}FpA9q0T}=QfF&F_0KkpX&gW9H91Z{g
::IXD0S0029a8zj/J91Z{gV@^V}005_l/#t&I91Z{g8(3cL0Klo52D8=y0000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000C}02p0000000000{9]zB
::^-S740000000000000000000000000$YB5g00000?R|u@00000{9yn9000007GeMZ00000Bw^#n00000LSg]^00000U}69O00000YGMEY00000gkk]y00000pke@3
::00000v|;1N00000!eRgb00000+M5Yt00000/$i?,00000^F[14000004r2fS000009Af|g00000GGhP$00000NMis100000RAT[D00000U}FFP00000YGVKZ00000
::bYlPj00000eq#Ut00000jAH.,000000000000000$YB5g00000?R|u@00000{9yn9000007GeMZ00000Bw^#n00000LSg]^00000U}69O00000YGMEY00000gkk]y
::00000pke@300000v|;1N00000!eRgb00000+M5Yt00000/$i?,00000^F[14000004r2fS000009Af|g00000GGhP$00000NMis100000RAT[D00000U}FFP00000
::YGVKZ00000bYlPj00000eq#Ut00000jAH.,000000000000000gaAxraztr!VPb4$RA^Q#VPr#LY/13JbaO]/azt!w004~uOk{FLWpqSrY+D~lWNc,slmJX,az|x!
::P/zf$Wn]_7WkF;Qa&FRK005f-Ok{FQZ))FaY.|7kod8T]a!-t(Zb[xnXJtldY.LYybZKvHb4z7/005![Ok{FVb!BpSNo_@gWkzXiWlLpwPjGZ/Z,Bkp^W)|GLu^wz
::WdNN4PIORmZ,,m2bXI9{bai2DO=WFwa)Ms&!2wQmQFUc;c~E6@W]ZzBVQyn)LvM9&bY,e@&?hnyQFUc;c~g0FbY,Q-X?DZy3j$7bQ+P5Tc4cmK004/sQgm!VY/131
::VRU6kWnpjtasyIyY){crWk^XVZ~)#sQgm!dZfSHuZgXi;baH8KX8^9sQgm!dZfSH@ZfRq0WMxxya&pa70043XQgm!mVQyq]ZAEwh-5}Q_Y,cA(WkzXbY.Dp)Z(Yb,
::WdPm/Qgm!oX?DaxZ(Yb,WkzXbY.Do+eg|K7V{?U]ZEyepfCpc9V{?k4V{LE&sRwOkZDVb400689ZDnn3Z-2w?x)9P~a${|9007Mgb9ZoZX?N38UvmHe/0JeOb8Ka9
::000000AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B0AK)B
::0AK)BZgga9Y&XMMYybcN000000$agf00000C}02p0RR910000000000C}02pC}02pC}02pQ,dxacyvQ=ZBJrqNN/azE[W)M000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::000000000000000000000000006-i$hyVZph[p^7=&M)b2&/FGD55x_NTOJxXrg$ch[zOHsG^+{$fDSy=&V;d2&{LID5E&|NTXPzXrp-eh[-UJsH3=}u(Cgu[TdT)
::5UC+kFsVSPP]n;4aH+W+kg1[lu(KbQ)5c|5[TmZ,5UL=mFseYRP]w^6aH[c-kg7;lSgUBO0000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
::0000000000000000000000000000000000000000
:x64dll:

:x86exe:
Add-Type -Language CSharp -TypeDefinition @"
 using System.IO; public class BAT85{ public static void Decode(string tmp, string s) { MemoryStream ms=new MemoryStream(); n=0;
 byte[] b85=new byte[255]; string a85="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$&()+,-./;=?@[]^_{|}~";
 int[] p85={52200625,614125,7225,85,1}; for(byte i=0;i<85;i++){b85[(byte)a85[i]]=i;} bool k=false;int p=0; foreach(char c in s){
 switch(c){ case'\0':case'\n':case'\r':case'\b':case'\t':case'\xA0':case' ':case':': k=false;break; default: k=true;break; }
 if(k){ n+= b85[(byte)c] * p85[p++]; if(p == 5){ ms.Write(n4b(), 0, 4); n=0; p=0; } } }         if(p>0){ for(int i=0;i<5-p;i++){
 n += 84 * p85[p+i]; } ms.Write(n4b(), 0, p-1); } File.WriteAllBytes(tmp, ms.ToArray()); ms.SetLength(0); }
 private static byte[] n4b(){ return new byte[4]{(byte)(n>>24),(byte)(n>>16),(byte)(n>>8),(byte)n}; } private static long n=0; }
"@; function X([int]$r=1){ $tmp="$r._"; [BAT85]::Decode($tmp, $f[$r+1]); expand $d\$tmp -F:* -R; del $tmp -force }

:x86exe:
::O/bZg00000vK{~c00000EC2ui000000|5a50RR9100000N(o.=0RRIP07L++00000005js0BQgLV{Bz&Zf|pNa4uzdWdQc^MT=k^07P4WfQ;wY20#S?GDBb]000jF
::;nm&MErwD{qEHrEKpp=lE4!StIjVhYGEh-9LZjuPWy,GR62Jlhej|n&_uKW6JX@WuJ4[Z_kYt3O-3H&yT7Xj+o4fURrH}b!/-?A$DH+m5C2L4!4FJpx9Mk~.J=kXZ
::U/CFjr&Rgvoq-h4u$rt9afgky.V1ZJS$m#hvh~{a73J9WY_2l~Yx~|L&G$l}k92Hp8jj}bq(3!5(?aM,uZbN;6eM6P0+iY8xIn]P|NHNMK?Pqe00319Kovt3[14wf
::Gv8x2-Z$F|L5ZeGO8hSfy&OR}5@}vCsQ=|MV#.(700|;!EiMQI=wAwEwmS^a)T42tWFa4HX|+uAA=#L]Hg{?d@eX#1;/l&/?B/Qr@c&!d/p@T?e&DgkS@J|/)Cxv!
::YiYHHOl-=mclY[+rH}t.^hQ_=9cQzpNk7h.3(0R?5@!@Jo=u@rvv(N6tc9_c#IhQ^{@nV1G!ZFl.MPTbqG00FD6It?[hBUDxvbs(5+7}fD^r4,c#+s=]Q)wGfCee8
::xsM;#1g{S&Nb_72^^34Tu0pVq&i90Z_;jS_EOYmnZA$X,49L&_$5OK)wrh5t;k#uCuJbF;P87OqxG66jIDjCB!asve+[Rp=^GRecapW1ufaTT|6tnSgL5Lq,nG17!
::_^H9xIzJik)=_xRS-xF-3g-.;L7IJ^+^b{[v(VP=pbG@9LQ_.E0W}MFiD0p+Lz[T(b0GI&!-^v{a2JC$Gu.6L2tPm(K=}fP6|y)Pb]zI+pb3FDJhB,|ZUN?3ki7H$
::2r^0s0zqI4fENbLbKnzgL)0MN0[4r-{eW}e^/F(e?/d@|NCy!2fmz@$5t{tyKR~UFe7_Lj#$F6c21$R38Bq(ZtAec!MS5PANT=8nI!)Pb$w3O?7v$I7IeBBU!kY-p
::klvN{f,gf7BB/pyCUxy05[+iLC}o&&P.i.[E9rWS;{(za0wz,e?eXya7nNwlDaxU-NjPr]F0(sqn}2DMzi^Jo,Se5.MivntdFL0NCY(!V]A2q6,V0@W24,M+Mjh=8
::F(;^(aEZ},)2FX/lAPFu_vvv99VeC6O3_Qvmpq{igQggsMAzkL8X+yGdmhuD0i9VFc5vX@9Tf!Flv.,b3SDfBbnc9t2TWOtUDE?7lcxWS-IkM-hDLnpL]T&jL+7w9
::u{nv67x?cEdRSkTF^E~mH|6$dgT_hrY0$T4XQNAAJGU6SsX2,Ug?y1^9{AHqv/CLZG;WGi@bYS-;H&3Cv)}@IuTncv@$u;|U6S22o!&Ua=alSCr47d?C&4Z|a!2/(
::U1=8$[tf~bf{EsAS.Vx&=.K7W/L.Tx==RKYYvJ1IY$~RRk.I6A@Mdj@RO/jFhnYYn[50#,^x,8mYIjotRG!)&?mBpJ;.GXOQ{B!(Pwk[(&VeGZCOtyBm[cUflKTF8
::9n4}c(4sBwa|Sh99SG+K-T|2e,G;Jzuv~FFOSdTU@+bRrTAb0KhSNwV#(c6Vh=I4CM0xt5#)q(wNi=@k^M_iVUaG|tJl,wbCPPvD+Ks}?v(3!&8Pei^x)5TNxIq3@
::)HZ.Kf!2,{tQR@CE#6|[qchRl]v!@Ism#ppc0oY5q[J3~ayWfA0Uk;k_!6lWGVo0E/#oOXC-Z2Ca!C&~2d#x98r8ikG33JLeG8(^hKQZ8(5,TI3v3;)-~-FSCK}5b
::no#nRZXg@95UA98Xm5b1LFEYqM0$Zr;;?&(M_$vx{a}n39-eA4fj$eUBGM]V3[$SI,!-7i2]knF=w?j^]wxH0X^k|lOj6?T)IhY[0qYE,h|y.HO9U_V@8ic-1a4(|
::3=0zgh_7j2kcQ4CCLz5{0!RoJ$nnPIhh1obDO/ZuDDoq}HB5xQO$xcTp&iDcSL2UtCn0rQk}~?;^b-8zlqNTYjRsA5W1;#6;WfL8lEC1nqr?hFJfkssE.Je-C1pzF
::id^)GNFx&WJe0~!FXK@e[b/c_08BagZhlgN9e]3ORBXAyI|ztg|8{r]x3H!Fi{#T3a~qi3bcE[FZaO{_q..D24;NJefnrSCnghm](=5RQHK.,hIq5!nB9K5DW]zHw
::rhwb,gvPbM3^(BTVnp$eP2dYzs0^+ZaDH{jRS)NVxAgNZX#UFBykAs|aGy;0jiPW#f}|?jCa7V0e-tY(KbVjp[{{2mF2zOFKOU=USnU8X41MI(-hD64HX5qqioJ;Y
::p}0Zi$48aWXsey}OQ@-6t45zu9DJFoPYOuNX&a,T]xT4~7],Vy@q@lFcwZDyklB^)&9b5hGx(s21oELX[@nVFebC/ZYXpEmJ}Px/LM.2aB[CxQ)fqGBV=UTPq-tLA
::HAWSn&BRYu?X0g@8c3}@P$]pFGRS&n)&Eb6@=d@{2O}u~f)(^7MV36[FX.=F6KZ|0yo=Zv8QMPEy-=xd9wz_FYZ+&mZ~]Yq.-QOZDA~?q4NYSBb!g_hCV~OPV]OOq
::A#7$5D$3Pdll782#-aBb)Z))-eSDp)p?@}m/c7ZBvw;LOs9k5MQHQQQG[L2b{k#hnO^OiR6b.A?No1mqHJC/5BhBzrnRK3GU!hiIZU!12w2pWvrV2IVY!u-{[FN.2
::CG?@Oh-o?+;W4B#;-?tQCtLYdGzD3AFUdDuD(mSc,XZR6bDQ)}h,[J.SI-AFUanfXRkQwoL9~Plr51u!NphusW?i$0c2+d.KY~]lEef1Osp|?N3gA8C.vxw9mvx|H
::ML80+sItx5Ws,x0qjJV)/QFf^g;h=,w=?]mEs$=t;[5CGo!R~8mvoh,,U|&[+qm@W38U|@8a@xJ#4{Cilfa{;,E+zQWn?BN=X@[efk|ZPZ$48]__mOk3@m.=dZSlS
::D$5#k)rj9eRfVM@BZ_~N6b#mY6y1-_k|5Sn#D.neT!zN^,l&#fnU5j/)Vd~tC6nJBxeI&oz;fvUa6V(s#Wko_x8)7mqJ5/+OA),{IPh|XoC6L2vg-VG3JTwli|S#n
::WnDl-Xh+=GEIH3N.{5JHa?nU.hmx,73bvr3_b(?i)K7N]wiSx,R^Q1O?$o!0fR{nTp|=R,;O;N-h.$P)5K^5[4}d4qYKmCvy~FAU,]8)]3+,aLeHZ6IZ-esWs=T7V
::+vl)3PmoOkEp3C1u9t=m=uAx?^q$j#FIv7+n88RPi)4&e3)w;hk9~Pn@;w^((.VUhM@UJ^Mo}Iov=9N|8wZoCvEz;(0yqu~&qE(UGjW9fiYDIM.kuwhl0i[IL08Kc
::D.|@weChO}vuCjUjt^R^4m}V1$87OHXsYOr-TXEab;H!VA=jmkLgGV]HUoPT0fd/;84Q2^ANEl0{hkQ=f9?m_S4Fw.I]OL9.3,DJcy36q)1-Uu1{Xbh@1p[}wD7Eq
::uRH60Jn)r#^;&ZE$u2hpctdBr(OKV^?[4d]oj&5xcWRFAl#6hLH,x6emhNzLtfwf3eg-Qek$#xwd}Udggkb86WfSl.bQU(GA$fAMxi7CVO7bOM4=uT$V4b7cY)t/~
::]~u$uaPVBkYA0j2.ar|c5VPph&YDf#h4LA2snwO1cQNX.@^4kM$g/&|gQQ6fMbbAg9(Yw3q;i}vqgU;Z1tI0q{1)Jjsw2i,n[2l9RH_wT;sds]B5afhs1WHOOM@hX
::L^icEHiKH-vzQdI75=PDIcPuIXYo_9r{,ADI_QIF!1$GXXG?y1{]hA]x@}o?XK;,Neo1WUdswiX2P#$y5;x](k1$0F3T3IzvoL+TlRqp5i($M]vQcG=m!C_unlHSU
::XxFE&TB)y+(Dttd12K9),/lKt!&n$yGm3#SHJZ6H9.#i6mgP2LFM0gvN@THi;z9=dWw;2MS~#X,g.FB/[_##+avx}eCDk8CwYL35u#,gCC|XlPM{V/.2!x8|MWi2A
::_uOOqD!iEms-#2Ccc,u&n3tvI0RP(d;+PCk!aX5a,s2)gPsI2c@fQl,r2NGEZ]d/2{{0hlDzRW(g=Fn1RD#ajPfFgfe|gh#Lm]Z57nccY_FC4?p!jd2tQS)P@7~oR
::$qLD2aBl=1)V?&q57mPKbI;bJ)3eTld/ZE1ef6xj8tJuDbcD_4/Vtl&Na~-rX!v8ol[Ps7cBlPNaRi]{QG25kgfN@BtgVYqkRMYpz-Aj_J)/Xn74Nd$!@8h.3f3iR
::crB1GsH4;$M#KhL1J7e|#{.x,M})g;=6+m{FVFsbj2oXo=ZxOY{c_7nfvp+#B/I^$xo+AO(scNe7oRtDVDasW-2zU&-]OU4.)NRI2vm#8@0p|yUOv[2@;WF-1;d_)
::reT51IjF(D#,5Q-gA2myeo0B+I]67zYU)_=P8IxM,a3fkPxe{36TAeln$qh_3lJeoX~,JiGvkS@=(,SW7UA7-tY=sW-iy}qgBuY)4$Fo,SXCuff&20M=X4xazH(u9
::Bei}DbHzolqGC;$8!2x/pIC,r;!zI9Lw3iLaI9(.I#nd&ILsXn9EqoP1dG_L8|n26Xt{#gXlY~Acutpek,A)X[XW^74(TIm?kn!A&2+jJ^5Ge|uINpNwj]8q8Tab;
::wS=8d9+#3BBHORt0V=g5XQyRFoO89xK1O,p^yJyPuC6M_[NU4Z$Y1!$GX2-JoZB,t.UM(V7E;_}R4Nhp1CNmp4VfzAH1IUW&bf4|6;|^fCz49$,LN&yVWdH2y0=ad
::;)SsZp=tbiMc;SPYwMlT1hA,Fq&1@aDx-U[=FX|}eVi#=73g/cBjxD$a7lbh#WV1uI!hf&K(mOXrX?(z?9OE8{T~53q;2=FNnOg_(ay5BIeVASq[-dcdk1kSEoS$c
::j9qc}b.7KAOIA~aoyyb^.4LNba2S,+ZpZ4M]te2_86N6G+4-D[QQfHJN}4H!YJ[@S/LZaw2LJxBnY6=@O}7C,4yDwvifo6CFg$|w3beFUMEg|NJkR}H.encM@[qpo
::b]+L{BjU(^W_.MNF;HIZo;AF.11sfnM;gp!_WXccf{w4wnB(~!4mA3mmc&=EdeB;o#I,n}&kP1Gr8zgO)Cn4(J{1=W$.2p(y3]ptJvRU{JiN$7VC]hX=oTAx]X/8;
::X=E8RfsVHB5=j18p~ChVW!r=vw#QGiWKDR)run1f{ttDR1OwYy+(&w8Jtb3l+(8M(#ZQR)=(8oKG?o!6AEeA5nU?bNw=bA1&cvwi5,4}rI6QG3=P4ELa;0!djfKHj
::-C~xZ]R~u.g[2u6n,y_R@u?XLX#5&=V[3x4Kb=KG|4y-kwdk}WbZkqn!ib73fCW&kMp9TWS|0oBB=qCD7]~Q1C{TDrq!j8)pJFJxQ[N1v0T7mq8TSf|B|&3ue-C#s
::]qOX.Mg[|hX+Tnt;Ut;qey7Yq&.h~E^dzuP@OgMy,+r8NbB{S@CuHqu3EMV4zA_3EXl~U}UI3eIXZ[5bLrpv&ZZ^+wMX~bQ[Y~tqFNm&#gQgsD_0{]avFMlc,mrW8
::2i)Mv${breta]FkiJ_poz,K5$hDp&-3EWuuPz1cJTPA5.@o.OvB)DpD&Um^}-)k@ZFPT-d|G8^Ei{QH)=BY-GoOr/[D,NnFI3X#x/RThiEtM;q,q@L^Za/e9mn3dT
::dc/}3tr7-om.|Z=e6kDv?+i_ki@Q3Wrp03AXJ-Cvx#aQ/h0P3an5V|hldsoPU3w1JJn9Cs&e5~Sdnk}7I(;V9MzUnNSj^ghvUT#!vL{Qggfl@^kBfQTEY1z~Q+ZH]
::Px=Fvao7KfCFZ_],KpVuVJoFB{P0ujd6|rxN#wHQ4Ka,Rg2mae9n..1?_Qe$R1-iSNKB3HJXfakQ$NdJRi8{l.WVTo^~gI-bg|ue8ffpgwSDwZz.S(ZwPw#_JK7_#
::h2aBvhEyj^p!I[NT&cC?pPe!?yrBFx1)+.,n0|&tyFWDvqE)/;Gm.qjcu7TrfUm^PLoLi.AjoY2-lFEUMuDP7NgViH+StFbGHHds[He-PCd&zwccW&[HZD!|sAk=K
::[?5aeAEo=Mf]!{$x7YTcxx4;2zx6.0MuA!H!CK1PzJAaKcMdtY-{kWhH!?R-jf&#]!QCq61sC)6Fy1{Dtjc;,$e,#uQU8f(FResBv{nnuQ585PcF{RVLwUi42#wL|
::,Z+bUk6d!UM_^)wx9~odBKD&Dp#CS${y=~Htg-_a{lyS@?bTO~48+5xJl|skjA;M9/kaPHPhnQ|_0oZ7XVt;}a.S!1=?cu[Bft8mNJkQWV&fE8Zz]+m2^EBOs.S&g
::Rl9sY&^/b)F{bp2.S,d02[d(hCi05Zc0klLTGX.8HJ]tXv9nFf&M,jl8+UY1@J!,HFODDM7Vr1C{$!8@!{AYU{J^TKu.&^X=qDGug1T5LP5fTN3+plFl6tH)H}2ch
::cCNtf)RlB.lSrxfIFTMp?!_NcyZ0I!9IaiCF{]x!k(2PkeBI,)_fR{.PG[=]!ZW+ms4qG-m)C)[TqPLq;45snC)hMc4uEVGMX9KLQ?xTRr{uKrpMQ_qt[Q0f1;rIU
::j/Fr$V66/z--5{9)CUPO#J0=xr1@,@/T=N7boUQa_f[rH9[?l,+Iyv{]@9Bt0X1pTEj7/9zN],cHLKOT,Kk=wx]^M9L#c=Dd{l#a8^H^p9JAT_tu5{/8r#,XLNb)Z
::^myvpzkW)PZHa,N,R@+XBVwvJZ_1sS88x[t$1jNLG7Pn.]-H=DNY8LkA8Bo08EM4Rm6g(zvbk-S8U@kOD[XJo?P2j{PPb?poAZD/ORG@WaXhy.wEN~i;^w_MQ7dVq
::o/y2GXKDfqWu;59|7paKEuiQZfsK_F]2m4vh$]u8(Q8Gbu}^;80$xAYL0X]F)j6qJ+!0SZ3eUMfVcUl2FHtzS5ssKtfMJHAV_euMq=r$!,-buZx~Lp~?dJDw/D9Br
::{c]U#yDGNxKTUJ@+o8@e&?9xg[Og9ukLoQto6wAc0^raL!|jFo@E)yFG-Q,EdO;o2.ZQC^uHmetY.haA{UkggrdGAV?R9a4w.A_ze6.B)tj?LL@|ZDwP!jHKJ-#hx
::eAyKct(K}~?t7|c19==ZA8H=+Vf52I+fhe-cEdpnsSWhFbrgEgIax|Ctafn689K6zW}sX&Iv4_f^rH$GFxhO~HCzNs2IS[U[DJKXtCam8@1Qza]FY;AgwLSvR)HU8
::&f51J5t7eU|2TtUyp,{ny6DoSy[ewn0+F2.ZrjgdmR{gh|I=H9iC4]5.9O5YssV_b=Ak#MESTY09xn^M.lt_VO{Z7bZ.p?Ed2pO|s-E4Y1v[]&]!zo0VcS9ww4F,o
::m]1/i{.F+b!@aI/bv_tzARO?[_K9MHLPi#6s[#,6TcFTZ8?i@gk_ZQJ-XH$lq9lvG&AXJ.=y;m~fTGEg(ZzAIZj!-K5q7HkKe01&tt_LabaU$hQ5g)d&LUscWIGe9
::PAPT&WKW+3px,ei{J&fynH@e6_d6CP&Oys[o.kA(!Wlki[{9];]dG|Db6I;w5$-?!!JcE^GQ)yq&mlCOl/(E^ddwC_w@DOW.1]|-ayE&6uA1i]t@)4$2zT]Ga;)Dg
::9J3y^Smey_,MC^#SE{xM7!Zhef-aj43h&]aiXvH5ONC/iDROSt=F7,)ySDp6S[Hw43=qEhIM&Roi;^V8503c{RGloxT2PSwNhb4]@Up-G+.GLsLLjSd+-;P6km5Jx
::_kpt}w&Y!KPFq,Ay##yKzaX[agUm|)Mig]xB$U2!l#W5zn&/_,=e5_J3~g?p#f3wYkch8-#]f}E=?,/9iUErT(b-y|7+1SF4.PC]7Y&oFGII9R)_8NckprE|6]#sW
::@!QG8xEZ/TpY@ORLVK|R)TthHv5bnKGood4Hvn^{)cePcy$jsmyUo10K$?3Ln!k5]IC?ZADn{h@ZSwZo0AF$L?jw#;+gMnrQZCh?W=CJ[M.f(&739~u=)p}}j&GVG
::IGNR7i)lv-_g4~2Bze_l5cwp@H0|D$^)GVSHB2Tf?t#Dy!@A[Ao!tCC4o,u)N~i{8a^8D~saKIjGaudgJYI7DXfjh/,BKt}z5DybHJUklG=W[?H/Xs47zp_+{cOC9
::BtDxII)-QxSD6p9cW-$PGKGcEyhf,r/T7-m;#(JrNK+17NdWT)X+{iL)9SvD^g+U(MwWU0q.jX/8./[=)vwU}{/_h?KtVmyoqly8CLgrnE]KML#}Tu~rY^f$5L4[|
::Lu|8=FO9W_9~.W-N!e1X)~tW5oVxK;]&Aak-;aTOwuPOY1P-6(m/d$rc006)@el!~=r6S7UDgUnC7j.VC[r.=oAc^|py}+E#p&d[Mt|{D/hkC-XkT6UXkP-b/-/3|
::cUSC]?gE@K0n=9snUx~.U]dUBuypR/!KVGx+=V5((e36cJHh=Qd+Z.;zWU?_;VxBrCBLRaE}PQm)xuL)smUzKO(00marq$E1D(VI=p?nI9?S$5+kcaMyS-H=SaANj
::J4ez}mo.]!zXDyXx1OgbI^bEb&kL9L!V=n~3GC]#DH}_q+XJF$R=7wJ5~Y)PZfUf-@f,=!q6jO/oe$!v0jRK{B+26{yO2)cRP^=p^b8_zeeZ8nv2&Cs5Sy=$Lspu)
::@!btLrRgXcPk!!WQ,HWXqyJ~Kd3e[gA!wFmR385Rob}oLH6Z}2C.kVrc58C6j]6GqHygyK8{H_C2yor,tyDWZz2@ZLU#M5+zxA=&^}=CC&TD1|8-0bQz;-=Y9IB,s
::Y=~A62)4}lcXIWeMKdo(+hfRr7v7_4!lUWL^s84/H;xSvs!rRqN$1ZZoXLBmUOC1~q91q6kHg#v)i+(J0p|pk7C@0P00bCdV{noI[B#5H83=WOfB}GFiE~IxKyib{
::2p~cr^yB--iZf;GumwN_1LDFU41&i,2b6,#-W.zK8CV4X;@9Z~88kECb8$n/2n.;}7z#o#Ac89kEof_NPyq&S93)R6gupliSq7{pFoXdWVxZ1J2m,i,2Z,x7MfCq7
::-1K-St(!fhPhKv(k}&f}liBvqj)HpZT&V_~#6Tb)1/zoE3#;TaKwYF5B]f2@?,Fl!?[4Lznuq/iA7/abu-fmL5VDBl2wV]~Aag^VLn;MqNb.;EM2NPCy]/2jencJ#
::k9;c]$oG.Ov9~cWu_#hVF,?n4Mtk.rVJ^W]W3j)ji(bKvVu~bINV-SDE~&4HBdM=Mzr/)#OBj/ilE[Ou!u{k?fxfmT?[v1]V@4nh$Yb=ee=Lt7W2j8|V|_,DD8^u9
::jGdgF9.nbcA~p$SleUw,6TVF^o8(v/Jo!HnPi(Lhr1#@aByc42&Kto1=}&gd/$$qDmdr-$MutYVM&G96LpGj^lg.HtneO8~H71?t^-,))Oco}al3kMxWUd-P6gXS;
::FAHU^GPkm[Ws[@xGPoJvnO.tZ-2C1U3~?yw/l7&e^hrA#ml0,4ndoMErCuSH?6gc{s+nvGuiml.4j-]q(]3Vl0C(UJ4P!o^GECmVc0;q&LuY~Z2fqi,2hGFpVEs7$
::5PcYZFnu)C/WHzMj0keVHzIcl_Vtf.!b5~)1n7v$[+GyLy(hg|1]=ZuobMLBXT2aC5$5#XICtVZ{SMr,]/quF@;35EdJk|Ovwwvj&OAv#^mBRA{22eJKA]w8Utuq^
::m+&$5cKOo}^-S?S5=K5uht)MM7J8}_Pl!E454l2(hYUhmM9dO.d4xD)I8r#WJ[OwJN19[cnB$n246.I!kuIi.?0-VSx+?|wD@ui4go.qu(zHj_-p+/lv$2_6!ejd}
::KZeJAjQS3LQlUY_F3Yv#pZF+VCy2[JYUDx&h!YYg|4+^tm_Y;;C?0tSYuMR=ER^ef4s0LX9[qsLnM]2ySQ~-D4wW71H{AIU.C!]Sl]G6DfCmH,6dpJ{fOsMCgW_w9
::hs-O,9~vJxA36_f9w0bG[){s6mIp8oWF9a$LGuT~913|bShd5U2hSW3aY&$gu];QrAhH)GT,S/0=pqD!Rb!y|VvPtkOH[Fu5l3M/1RWtT4UupN08A?Fn1V5JVgkiP
::iwT)&7!x!ma87hifKNash+g1ogk&$fCM..~kjQ3YgoG3lVMt/#5-6)+k@=$UNYq6O@3jMX0Du
:x86exe:

:x64exe:
Add-Type -Language CSharp -TypeDefinition @"
 using System.IO; public class BAT85{ public static void Decode(string tmp, string s) { MemoryStream ms=new MemoryStream(); n=0;
 byte[] b85=new byte[255]; string a85="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$&()+,-./;=?@[]^_{|}~";
 int[] p85={52200625,614125,7225,85,1}; for(byte i=0;i<85;i++){b85[(byte)a85[i]]=i;} bool k=false;int p=0; foreach(char c in s){
 switch(c){ case'\0':case'\n':case'\r':case'\b':case'\t':case'\xA0':case' ':case':': k=false;break; default: k=true;break; }
 if(k){ n+= b85[(byte)c] * p85[p++]; if(p == 5){ ms.Write(n4b(), 0, 4); n=0; p=0; } } }         if(p>0){ for(int i=0;i<5-p;i++){
 n += 84 * p85[p+i]; } ms.Write(n4b(), 0, p-1); } File.WriteAllBytes(tmp, ms.ToArray()); ms.SetLength(0); }
 private static byte[] n4b(){ return new byte[4]{(byte)(n>>24),(byte)(n>>16),(byte)(n>>8),(byte)n}; } private static long n=0; }
"@; function X([int]$r=1){ $tmp="$r._"; [BAT85]::Decode($tmp, $f[$r+1]); expand $d\$tmp -F:* -R; del $tmp -force }

:x64exe:
::O/bZg00000!XN-u00000EC2ui000000|5a50RR9100000N(o.=0RRIP08Rh]00000005js0BQgLV{Bz&Zf|pNa4uzdWdJ2ilOu2.08U$gfQ;wo2jFoN0Jl?HBq9KS
::008cfr?;tDkd,4b?GCKCnmgo^dROl1myYJ8Y[swTP1jY!@&qo78NeWY-&N09^};1hHr_Y9(.i&X?+U{D4J1V3T.t~y[NrC7gAuv$x6wA}pz^=v0APe[s&8KHtqj}V
::TY5IvrZCKGsl^3=tMEw[L91Gg)i,enb^]KESYEUQ6PnPL[Rm1^]OpKairi,f_k7_#d8/Zycui;2LNP+/?8^.jVvHV/3ZIgA/&Vni[4x?0ATj]|0surq15oWyy7zi^
::HB6K?5D5ivNx_HH2x8P2uomP0e@(w3P+Okihc$G8JOM=jN9Tgi2lQOs7XlGjmMdOv2e^psS;i,uh!i&mG#9}&3zwGp/f5_)@F|O,.]LA#aWZMV;b2^cYm9@+Yf-kN
::Wu3[lzAt^+/I.BTzuf=ct|_e/D!OGB$;aNt-,G.)k?f3LU/N1?L&(=eOt?t-&pU/puAE|c)k@C8lM^/[wLofdS]+ZAzPp5~0klq9+~vBWYsSrg,h#f?$X^Tv!5?2?
::fhb,_4&PYTWFJ8ANKu2(oAEFH)flX?_!t$&/Y7rYGdKP&S84@oa!3=&vr^|phoNH4jJEU{I$3PmiL,MfP3_;8Ff7W)-J32J-n^&{)PmjMw4,i/o$K4a^~7~nS{bN$
::M})t9wB41(W$F@zS8$A3$+ML}kOrh+2(RxSbgA78ec|B=mYMh!X9CN5@A7Rn@1i73R#/FkYxogzoNL6730C,U$O;J1;+ifuaHKli/lk_p194KhQ-($VF~]1VFjfmt
::[k9]?6IsaS+ME5yT7kWzYjNEpSi}Af^xYvU1bW$9/[5.;etIM/TIKXRQKYv_lY9awS,LO(=QBUT?R&ZtBGX1bjp7dcH1~Ko-DQIxqjy4/(v.1Ve437#G+0e1H&{.P
::{+fqhnGR0qQuMl}VA}w?|D?!m;DJ(c{,t,tF#B/Q{;&9RKo$.6l3GDt)qTt$a6SvE4)a;2[WI-x=LPV2OlE#Q]U@J/6al{qOV+$r#zw7qQN#]GwC{&QdW+bCyf{FH
::.l2n+d;}@K8ybp7]M/!z(YZp&g;4Q&,p;5AdZ1YHoMsGz=0V3Q]aSrn,4trDV)@3$D;tr9rKh;H#s_xH&Cpxjfoyto9KFG/j!dZ/R0i^mi{7/ZJNzsVRy;Qh#tDv!
::(j=CM;y_ah1tU}p.0v[/!usOKsV@g1JyAdNkOq.IPy9]f0WV&D#YtUJ1Bg$}w4+YGaIJrOu0PFEdZ)$5yHKwrYx@0YaUz/+yIOZCHn1l8C0#J)E0R$DqE!E!xn@s7
::e4IXnLHPJEo~gEXB3$y0uBchan,nkO8$/+w4D9@r6QtW6-Mv2[#EJ&0]oYbaXz{yz&Jd&pa5xNenY}|y!!k!Y#n,wzV4]hj//YvTi_]ZpAuWp8|5=Y3q3N4$Gv#tP
::on@|8au7l]Z8BC;=J[#iM^hP=AB2OwiveWFDHkbU/~j2eS0[+|(}7!10j53pgZgjt#NAE?8y]$FX-IJ8=f4=^yb@Dq)D7BQip~tEZ4RI~o++yp;n@.&;gB0kxtBzg
::m-MhEUP#PQuK0u}SnWNAwtgGA$z5AJ=oJ1+Y4~wPp9=83gn8G]pDwzHEG{VJt6|7=hf}@SoIxQ^ipf_i/qN;_C7g&2DJ=Xar+?XlK0//sHmvQ0Qh^/;M{i@aICoDL
::Km8)&d~l2;.4kFP/0f)yLKBG-vX+pY.Sc_ql9tg2yov514yG6Ap+j61Ckp_eLzM0D=0kJ-,5]~QxU=_vfJPo^_,n._ug_Si|LYeTe4l.x8I9jUt&S8JWk.S!2]9g$
::o}Y(bs@dEU;{=lRUHz,ZEW058ca&!-0q(NpsuPenCS2H1OVvG9Vk.T~wT67Ec_BF)Kh&4t(W#U8EW-2qPqBc4@N(B&RS/+6AM6r44y65S__v2Qa#cTS!@0}zB01mG
::VMTCckW0]}6]S$VDIL+8cCES4iLPaVr{6x_vMtJ539;[W^~gZ[fOFSRuy4id^2WpxFJh!3IY!zCNy13(eRtFD)5x^4(WK=.gw~adMd8JdzasL]09Kin;$)dl)Kp0I
::9?1TXF2thKtNn=weZ/LE;!oI.hL13uH)Fooj^xEI_xqSr_upw~F@o^[8uK#PNWU7UmC63PD_oQS7KpWM_Ov~;K1$VoJUcj_^MN&0x.wMZy-{9I6!?B#UFC=bQ9rng
::[?J3wubU^g-RcQmP=O@&tfLX4g^$a$]l[]JVL?yLA@36FON&uJt5nU0?zfRI57/J^U37G$Gd#s8]rIj;e_m{lB^[p=lGu$!r8t-e??Vp$v+J{@iX,^^cRxVM7}~3a
::yLgs24M/uqVQ];sq^]3Nk{I~Y5NtGkc~XhuUwi1uqx[(_xwBv(OUimXvV;Q?2^.@taC{V?WE5~RpAwNi&zop~1r(ZubmzscFDa1O#^-EoahfJ7l{Z?Wq{jx&KJ&aQ
::uUabHg(mFBqA-BU5e+y[4^jFxpeTs.)PRPIa~5FN432lDO7qY0gQcLYpyvybh3LKkmq_aVko!;.!A=lll}|h42Mu8Rt+_e98(C2[]whw]/p~d,kAr-xvH2_&9+P7y
::;U[1DwZ/l}Gk!k@S#Ii^b#dvWlP[@|BmLeSPpOz|D.{=x.PUm_&.EPRXVimL;XVb1Co?j#Zay9Kj-iTHW&_$U38d#DqDVD^D.iMK-#M1_=5g#g@mws3yVHV_s8bi9
::as[NqZ0T@;VH&[b4rS$Os[6G09_x3~jzNDi^#/JR#y@g&js)oB)!DzrAdl4Nh~+rf78eHeV+s_EFb0,hl[}/})4YQJ6vv)S0|Pcrb@RnYUIsc;WK7rZnPCY-hU#kT
::teoab0{[Rs$(oD|7JW;vkE3M1o$;-),tB&Q)}o~71NyqxvghU.Q^m=LJPBDJ]o5_B?pE,beT8N+Dkv7VwvZ(Ewa;]|I)?cjQN]eh07rpr$TxVr/}Xe;{O4MA?[5[_
::E,tc}6n}}RYQ)ACwp/Im6r_aA!U7~LU=MByEbV,uZ^XoQ8GlN3hLu1K1nVeMAszQHUt09rQf?nlSlkfIG[z4bX|.)rv5fEwCx.uCwK]]@gFz6^{d-@b5dDm=tF6ol
::pjzd+eQiZ9UxTxj&/CcO&LOm^-ti;Ua1rEu.rZPs75,NBY0~^/vE{|hSzJ!bLAF7-AF8nAuNy4g!~MEkAX,oz7eFXJilezFUr8Radx0#-U)snZh6[F)_QK0b8C@eY
::DzkL[2bbnu;;xKYe)60vkL9hLoJR_kht[b@O_rI,Zj6MI2c7JPVdEI+f.mM8Igiyi{5.y;zY6w[y+qvikG(fQC8JReJBG7Wv7giY!uHS8)U?+!HZ(p2wd1[M]{eiQ
::e/^~|+w?fGvMO6R|0s?^Op)$CpOonNV3o]VGp9ZF8B#N)gnxxxiq?upk!trQD[P;Yj9?c2[MdYlJM=-jourz~I+1@{YTT7eUcT}Ysjj_or2QzILejM7l)~]RpC}.V
::&c)0ah!Uu?Vcl1N#U-hoPT6bTE[cy0lQjmU]Cx3,mFWjUiSfn.iCVc^Khqgi)Gl4bhpi9=nnM5H?e{CPJ.x1y=-q4D&r,{Uj)w^@bvjcUi?t#JY}V^m^@rZ&K;{;d
::+KOXvK^b,6^/l!X7c3caYJ;Ilk3sl[,wr{J)Oy})a0qr43@6$CrzB5{VzGOY^noJ(rP4z&PyAKYBl&LfI3J_~KOt5rZpLC7BQPBZR{xjSub;K039mSkd#1B1/q$Nf
::C4X4bcfzgbPh]UHS.sRk+tLouwh#PJr!6hSnxnk@Q.XEG,H8k_eW5j,8S]KuDS~Z=W~wTEf1W?_@nri#X}_AjSF)i^ndAFUSH.{$w-&{oI.=hm|LgaR8mwK=r$PI#
::eaB!r-Ov{YBF-d2/703ks0(H|55h4[eN;w[7goI[?_8e+POv[y@#@][X1[s!A+v6ap.dH0]bHPJlAagn]o{3+bdO|dz(Q=cTtq|iFM4F@+.zg#N3hItRy]NOo4)e1
::@@6jJKZ?HGXHu^KaVpu|R]t(LR9s+.d]v?$-V2NHb(/)sI+7_rAcD8e.}{uB-n!b99/FZUJwN6e@5Uf8)lKi,,hSj_hc}~Npyi$[hfT.PWdB;oTEeCVN[=RV8g#t)
::.|Vv1J4r!.g#F{0)T}-P$k[sp{nF?#8{25G75Tf/IL~|8JXd-L1;O{)^r@!uO7xxcZMMzRNDpj(3v/Och1Y{ldGa4W.01cu^ol^_]9Y4#?}gWiN2}2mpV|QQS)3HZ
::iSFOfA?xb7^w)xp6o&8=#kYe]{5GHVnNo9Im;!xy;~&lHc2hV+w~I-5;hbOqz#N^oQ13E}W.Bf[[fkroHRZFm(6lVNSHfm?bx&~db-UiJzbLYwKYeRt|KQ6/Q|VN;
::;}?}Q^@vz_,K=i1F0HrNO[1}C-[x(1BiuN9aV}XNex@_cRw}gy1@)x;o/B5VgY$n#Qp,tIfs66&L$hhw3@0NORUAaheZ##6$)a]0jUj59n[Q)aN9^r#V??hA{_Cy{
::0;,n4+NG#$2$Q.gU09LRY#2LY-/711p1ml/uv}Kyt|!6Tb2|?pM7I!s,u^o([ulpx{_jA21DqQUd4^i(C8y#N9I3xnnKyOcHI9_m]Fko?m$D&?Q&X]FLjy0zh}+n1
::JyZq!tv$Anm|-(},uAig2a9_C3Aj&mpff!]Eamr.Bis[0vo8i+zn^izw0aSOo|LWIL#Vct|Gtvb(u8Ct5|vse6jNTt0ibHI$pER2Obx,(vz?5uCN-}}t4XK|?;^CF
::uGWXD+K-j#f|Sm~]D[OkZhA$9P,lUnsnYKhIAtat1;)0kPtoM5Tt^0tF6{X~IW-mT0)Sj1lCQ^9U}I!A9&gEsrm-QXa6{9)pf{C6li=.HwYQZ}/lb]O?9[AmwmIC8
::H[f]cIIV)sE~mG8ySZ(!W~F^mZBc;F/C]{d,=zgFU1/0={wzwi0L^Q,+fsrh)ukEyeem~5=kqoH-dr]YQVLD&njD(,ql!y4]IzWSQ|KqGWM4^=8(u^MiPy-Pk)aF[
::|Bi/z8D~96U85nTpj$9G$vv;6$aYEzIYg[G{!p{A8r)+vfw@F,BOF(X@U#L[V3F1n5X(;thlT/p0!5bz&s[~@B[VbM5Ii;f,dICT$i]oCn_|HB0^gx&6ZZwArGl57
::Mi@TgEpwud+)5=Bu}THjeOf2FBR=N#IWq$F37@5#UCW-S^9xF72iF&P6Md^;Mjd+KG0c-3a)3BI{@mJMLJgvn]$1[fVM,sPHWuuNAwqlWO4vp2R)$p[a|4CkR4W.o
::tL]Qo=T0(a,K]VS4ehP(,[js4oiTZmy)8CE7m8[qQza-ab@mu3bXgDTIimE}iF@Vr09[6[Sx$[w!70UfUfM?^#qRLhtr)TCk|0n/{0~qe1xlij^yAxpB@H+XMJ!U^
::rW|lr8-A!~(HNr;6!yJ9.~Kyks2pJI4C#eW=WW@k!7@!Mpp2K7g@^guDYe+Z!Z[T_HgC]4SBcsHF4qXEix|wV&T#qG{Tom@+y[=8ltQ=v|6MR5Qh@Lil5J4)G~|dE
::RjDRd#m$56r,0q^[o@j-tHHJ#Y)+2FZIb/v2haa=JI9[1JApxo4($UMhZ{H]mE!H#?yIf+ZN?wenC{rOZaLqaBGBppvwnpTVK@|.XH]/P51vBdf.|Gq!3D5CtYM@F
::,XlPRGKYZ2)n~aehy;+i-pWBU{o~cA{7ce+So]1|.PO|juIMBCePJI_T,Rk-+h)4FPi(m82Z}nN^AskHbi}~+D!R27Ge.Hp0FIBfkHI0LQ|.o$@Hv_~cK@]m{IoI1
::b3+ZU!}4eU.XVOL63?7cF!.VF!SBP_Ucym+y^mWNv?i}2-5SgZ]6?Kk[,)qKh;AugFnu9#bJj2xbJoKI!{85b9|{k~]+y4|WzIg^JUne6.Qgm_[E8Nu2d?[2IN|uP
::_Ox1G)+_RiSjKEILS8p!#(8CP@PogX(&7T[9zs7r4BmObPp,f_(wLNim$c)eg8#HbHct2sV=.dUygyT4SAx&w{#)9vy7~SrjuEHs!0@1x0B|bO=JqX-HK5u6V.Bjo
::5Yi&98=y$hSkWMe1iH6t[^j[|;8e+5QRcUIP-(J.zWKW^o5Q1uk&Ml7aE0X&/Y1/1xtv0Iqc?&Rgwu^X=s8kWf@tm=G#mY6w6|t7FKS[pBb5tU8Yto;&]b8|UU-?&
::Ip+y{TMi8Ifg+CDC/mc~Ie@G|)^G(SIGUc);rf43RBA~~LnN.5TpN0A5{V1QEubUB^,MvvLq!DR.4aKf+L02cg+9Pb1?hOHz6;2ZB!WYNhs[(;g2s+Iy1iX6OO(aE
::OGj@0Kq&#x451z(#6u{{otZ&niA1EAVhC6o2#nCn8jAB[9t7-nAiVJ{I]/@OAu2fzk^2Qa?Pxo.@m#z|y4V)7gtOnYrzF|oX!S.KbXi!_7PToyP5dC3(hAoORu@2/
::$+-l5mk~3Hjk?_|ORbD5]ojIQln_l}fns#qKY,V(EQx3q;;1+J5S&25Zk7QQxlv1R1Yx~2II2/U{Mr$/n.MHEU=|6.7euQ~goeDANYo|khAHiKEG-Kj5Fx?lOetwE
::CaTcFG5xJ#TnUvWWkG;#1qnbMmM#+59O{ZB&MpmK96TwxXR{?n,&D;/HAf^VsF$haVrlr[rrb;bI??4|y?NISyYNsn7vaw6/OiuktK3YYB{agtejRj4ZfRxHgf[Q]
::rS)mRK/;8ix-f25flXLzw/;KgL.eUoDIui}u;83FY6y@kj1ZLnlX9$TRp@.T7)sG7Ary,7ZXOxZ+P?IzN.#lgv=-Z+J4[t07(+cu[_-Qa.De4)2_rFz0hP,;RFa?|
::r-^W#-N9}Aw_B.SRHaW7DM17mVN7W?uoM~~QTn)k!jYt5mt;0pD(c38fEYnx0RCeco;dTrsSz}@/Y#psQ#s8V2u!9&DAY&5z#7qVyC95HjcKYHiE!U26c|]KsqNNq
::2a[&tO2D^ZLTc!#ER/)K3i?L_IwmTfUka[A7EXvUO;$2B_Bh2;mm?zRzON{~,.g8|LRvy.09=Aa!|.T+!gIx2&]Ol.n]4w7q+PRqB/qJmOKpaPN/3Zy,HQMabd0Ee
::CDN-ZIAYgpGs474+^^DN4m[|kKG+_uA16GfG4$!CUca8!6@7|O7)]F]T$=-8I2D?V-(G9@{k_6?.-UX)b}Qs8+xi7[gX4B.5tOaH&fLZ&]0MD(41|yv?3P543csaA
::Sdo3ZjQxJxYd9[PC;xHt-SPJNw8p(6lNfn_R9KX/nn$8H)60fGw!O@]aMXj##!-mO19,g!gnxPvG&vO_SE0KGS/K}@TUsa[fr+{lZ$L)X,CMC-9@9A(CvujT1+)kG
::VNGzd.;jNqq)r.|z0sr?WI=00M4jea)H]v)5UR06YmMfzC/Xvnmo,thV4aC]jFCgD8kOUHf(wlXTht[WBp4eGnQXsN!Zjl@lSc&ewUaoSOxvinC8B8HwTpg4]MEWR
::=G9E|HI62&6l@m$!bq9+QwxofrKE~,[h{k[FFV{/tNI3@{_s~=BVWIU1{amo2u&Y?I3gJXAzf3+TH(j66=,z=,{C.mGWmy+7A6{]i.Mu(#JnfDi7V1,AVDXk+gsaG
::1|v6,pyYrw,PPp|?fMzd5/_b^VXf5]I3dUhQB$Uis/6$xyZpug,#$KhxttekRT^j#lj3qnx]of-+r6+i[tlx=r5vdFu8}Wpx.NgtSarVuua=O.goYGGu?mphMyjCQ
::H?btM)hy]}GvvKAyCh{-sp7W;TF;vvc3TAXx578T2gFX4@h91x3XW[F^JyKk(C|#!Qwl]9UMS6NRAs5y?tFpPDL_/eV.lErd6K$dLypX9xkflexe@mT??IuSHL4U(
::8Ek7M&-j1tIW#kXZB,+X-WW7iIkXv=E^j!eQi.dZH&J!y)}8Ek@H1b}|Ei7F#lzeXB1o,JYxVJ~njz+)7]1k.cMX?Uad@(;9G1,9R7+XhT2^v1I;}Z?6s{VIiX,6L
::jHoGX=/{zbMloQd=h.A7B{XcMispTPRTS;mk08_NsX?dVX=~/ZG+r+s;uXdJ8D.FQ]tQV&$0v!pI+-g.g|i(@U@xHsN[=cPp#HG8^-|;xHkkwNf-VY6rI[WMz4Ewe
::(TGxuJTWl#e#7kHsPL1h]-=5yb;-5/sv)8&W8=v}e9qI(^J&8DUwVae#GQBma7(6@Oh}OE[iRPo@ZpDco!!qY_sE3PuFeB9&c{Sj-S{$Be$DD!e)YvUg=j+sHV|Yo
::6pC3|wYJkXw^.0EOx|Qn+?zH{c9,i_iw~0AGk;S_c^89q5rmoFs/Z|.nbDw/{LQwp8+w]srZMKin/G)dAP[2V!M#Mjo7Xf/.Z$1QGWLI]v/5#!e=_f#z)8d/]t$##
::AeG.#M)ZpqCF;/6A2rqxdk-Fx+xrf|SZ$jhz_H.Ip4Uv)]j4H1N-G~WEGZSIV)@Y4ROks.P)U?jRuzGTSy~vZ98n5]g3lMh34RhqgeY016^K[.f,6U+b(O4r71sq;
::z/dMvxvxFEDjW]B6;hILy2]JAJiqy92V/kPaQS[yz,Lv(zKY+.pzLh@]y&VGTCh{A{KiE;=wX3Ozpg(2y{SX~+R2n_yb866b?o7FRNPv#3Zc6;Ag{WLqJg-NE1mHk
::3P^])S72+)]?4A4D~9w8JV7_h!!K~RhlvZ|31?((IEgUMyl}zJQVS.Kg3S8WSo0Gw3V0B{PiL_,Olx)qQA&S2Y5[YQ,piiHqGH9BuK?f&N2^nur?a]5Qh&({s67_L
::$tK}hGm5,eF8Cmv0X2)xFR;1,YHPoFp~ImHf@x.GIr)Wia3Gj4NH1/rL,JSOv_eoxHn@rIMz3vyzn8@tSQ&)xc-YJFHoAqB8?a|+C2/U==)JaY1X-lF^D69j.QRL}
::[D}{OyNC-!Xwpl(h/gN56dsbn=Iy}R0{N}4#trwc(eF{#=z?Ur)YD.rAJL4qt!ia|i/dIQh-fgQeY;FEYHuuUJZ6Hh)#qOkcKLDBo!pP)kCZ.52|ItN{laRQbRt;=
::1Hbk}cSfUhfZGJ+PY)Hjnescj]LK_AG+t9CrNL#QdMJp?ZP8Q9+I#|28;FJvH;tf[skBiGuN4mP4qlv2#bDd@h?]nBddFg34!8du8g3B!WYQfO9KYYcF44zy3;t~x
::_nO=yx}IDm^,[wTcv(wHDwJ/=1ez0xS)HdlfcjGYx[GYN[6-tPPHI2hgT~25V;gjr)ws@o&fF&X9HgJ~Or;KI]s=Kd=TzPWOiswPL##?L@X8tNGMPBKr)CFqGGU^A
::N?cZy9256@o@ViS$BUv2|AyNc2A1Hl$pn0?QiEqj8_I]Mo8JqW7Po64uv~VxF#tk7PD7NKj(xLFMK7DolQ^4MlgVsM+a7X}{TkU&5QV;#-9lu,+LzjTvM9$$C5j3;
::3NIJ95TJvy])ReFLANxEIp+OyaH#YR^Q-16At@5VX=W!4qOp#&uqPuLJ@BL$6.]wev4w3LKJ(hlxD-[$b)F3taJu=zlEe^pkCa2^pN|P9p@Q+O.7jB6_0zoct4JiO
::61&&&{gV4ELU!bssq!zsgwDL(jZuhzpb9j1@{jFsB1a=[tU)e5!}bKn_JQeEH0tK=4wKqfwju5=-/3?c&g)g.(knu,HqHOs2E}8!_G5[yr^-aj_M^dP)klCFpj/EW
::&#;{(THlxW&(njH#)4-!M.4.=OwOM460QRePm]ceg_(pqCt8wzIbdpv8X|IWrlNTF4@v_wLL{z4D]v@w^skk#^L.gdCrI@|&sqkcj+$#Vi-}y+WAWUC+axS2G-iSQ
::AbNvU4+Q;!54ZE=|5vQ(ceU^PhRGYscwpTi#RK#P=o{g0TZ~tP+DCGLy?l}i/V.w2QTctCZ43~@Z[{Wyu;zlFhP@Oyp-bkcaQx]!;1$m_m&3,I(;(6_gWtayS!!IE
::oDD!X!_=,m&VmsGFu@}Q9]yU}H$3r?p21xV5zaAGmBGLafo^B14SPKNW3ZVn$).9T!2{|B(?O,T.us@chTvM{6Z.D|g8SGC#NF2~xB1MOmLahByIKFj!?X&Zz[P;^
::Dwa3tYhVCuq4bqm.hm;GU!rig#8wk)BLGbx7oh?)3uYq)jiBX#fd9}(!Lrym/Q_CR,spm)m=F$}m|;uxP$$Bko&/Uxt_!c)EhruCPPo9?T$rHCmP=kh@Sgi&x=$m[
::kD&qi-3|apE.2U8z,L;O)1^hd?^MiYI18aR2@~hP96UY0o[hJ7nCN(9u@a,Qgy/mw7yPhdC5?Q^NK24B#GQF^Rq#s0.F6(ZZKqAWKmrdPd+Io;$jGc-8XhIqRoZ.^
::bGRRDAA5b7t^#hC4,OSzaS4])o!!yhkKc87#dpU$KspGOml#N^/0&QOV|c5oyQ;fyQ)Nb#@op1b.K4roy0W]nI;|F~I?BAx9bNZ$;zG6,y1Y8Qy1kv^U0;DF.Cqk(
::JG$&u,+iEw,j=[2,r~8{W&pvo#cr8hnO(RRj2$?TV7suL(aT{!vwOCy,)urO-3DNu??TX-@ELKh-Iiarh&Ck)synN[jk~pXjyoQAlkVLFyUKT&cX2zxXW[@;@=J67
::^.=RSch_64c=vo4?9hln6([8{2Hsk{2c8c-TzDpURq(PJo#Dgai]B=V3ghVT$MHJ6V!R&n9$p[vG2Rc+53di/2k#+BGF|}BRbo1Ey3T,I0AK
:x64exe:

:DoDebug
set _dDbg=No
cmd.exe /c ""!_batf!" !_para!"
set _dDbg=Yes
echo.
echo 完成.
echo 敲任意键继续...
pause >nul
goto :MainMenu

:E_Admin
echo %_err%
echo 由于此激活脚本需要管理员权限.
echo 因此，请右键选择“以管理员身份运行”

echo.
echo 敲任意键退出.
if %_Debug% EQU 1 goto :eof
if %Unattend% EQU 1 goto :eof
pause >nul
goto :eof

:E_PS
echo %_err%
echo 此脚本需要依赖Windows PowerShell才能正常运行.
echo.
echo 敲任意键退出.
if %_Debug% EQU 1 goto :eof
if %Unattend% EQU 1 goto :eof
pause >nul
goto :eof

:UnsupportedVersion
echo %_err%
echo 检测到不支持的操作系统版本.
echo 项目仅支持 Windows 7/8/8.1/10 及其等效服务器.
:TheEnd
if exist "%PUBLIC%\ReadMeAIO.html" del /f /q "%PUBLIC%\ReadMeAIO.html"
if exist "%_temp%\'" del /f /q "%_temp%\'"
if exist "%_temp%\`.txt" del /f /q "%_temp%\`.txt"
if defined _quit goto :eof
echo.
if %Unattend% EQU 0 echo 敲任意键退出.
%_Pause%
goto :eof

----- Begin wsf script --->
<package>
   <job id="ELAV">
       <script language="VBScript">
           Set strArg=WScript.Arguments.Named
           If Not strArg.Exists("File") Then
               Wscript.Echo "Switch /File:<File> is missing."
               WScript.Quit 1
           End If
           Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
           With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
               With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
                   If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                       strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
                   End If
               End With
               .Terminate
           End With
          CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
       </script>
   </job>
</package>
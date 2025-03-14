:: CREDITS:
:: - AMIT
:: - Artanis
:: - Canonez
:: - CYNAR
:: - EverythingTech
:: - he3als
:: - imribiy
:: - JayXTQ
:: - Melody
:: - nohopestage
:: - Phlegm
:: - Revision
:: - Timecard
:: - Xyueta

@echo off
:: set variables for identifying the operating system
:: - %releaseid% - release ID (e.g. 22H2)
:: - %build% - current build of Windows (e.g. 10.0.19045.2006)
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "DisplayVersion"') do set releaseid=%%a
for /f "tokens=4-7 delims=[.] " %%a in ('ver') do set build=%%a.%%b.%%c.%%d

:: set correct username variable of the currently logged in user
for /f "tokens=3 delims==\" %%a in ('wmic computersystem get username /value ^| find "="') do set loggedinusername=%%a

:: set cpu brand
wmic cpu get name | findstr "Intel" > nul && set CPU=INTEL
wmic cpu get name | findstr "AMD" > nul && set CPU=AMD

:: set other variables (do not touch)
set currentuser=%WinDir%\AtlasModules\Apps\NSudo.exe -U:C -P:E -Wait
set PowerShell=%WinDir%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command
set install_log=%WinDir%\AtlasModules\Logs\install.log
set user_log=%WinDir%\AtlasModules\Logs\userScript.log
set firewallBlockExe=call :firewallBlockExe
set setSvc=call :setSvc
set unZIP=call :unZIP
set system=true

:: script settings
set branch=%releaseid%
set ver=v0.1.0
title Atlas Configuration Script %branch% %ver%

:: check for administrator privileges
if "%~2"=="/skipAdminCheck" goto permSUCCESS
fltmc > nul 2>&1 || (
    goto permFAIL
)

:: check for trusted installer priviliges
whoami /user | find /i "S-1-5-18" > nul 2>&1
if %ERRORLEVEL%==1 (
    set system=false
)

:permSUCCESS
SETLOCAL EnableDelayedExpansion

:: append any new labels/scripts here (with a comment)
:: anything in "" is a comment

:: it has to be the same as the batch labels here

for %%a in (

"Post-Installation script"
startup

"Test prompt"
test

"DWM animations"
aniD
aniE

"Data Execution Prevention (anti-cheat compatibility)"
depD
depE

"Background apps"
backD
backE

"Bluetooth"
btD
btE

"Clipboard service (also required for Snip & Sketch)"
cbdhsvcD
cbdhsvcE

"Event Log"
eventlogD
eventlogE

"Task Scheduler"
scheduleD
scheduleE

"Windows Firewall"
firewallD
firewallE

"HDD performance related features/services"
hddD
hddE

"Hyper-V"
hyperD
hyperE

"Internet Explorer"
ieD
ieE

"Windows Media Player"
wmpD
wmpE

"Microsoft Store"
storeD
storeE

"Network Sharing"
networksharingD
networksharingE

"Notifications"
notiD
notiE

"Sleep states in power scheme"
sleepD
sleepE

"CPU idle states"
idleD
idleE

"Power"
powerD
powerE

"Printing"
printD
printE

"Replace Task Manager with Process Explorer"
processExplorerUninstall
processExplorerInstall

"Search Indexing"
indexD
indexE

"Search and start menu services"
SearchStartDisable
SearchStartEnable

"Unlock start menu layout"
startlayout

"Diagnostics services"
diagD
diagE

"User Account Control (UAC)"
uacD
uacE

"Universal Windows Platform (UWP)"
uwpD
uwpE

"Install Open-Shell (required for disabling search/start menu)"
openshellInstall

"Xbox apps and services"
xboxU
xboxD
xboxE

"VPN"
vpnD
vpnE

"Wi-Fi"
wifiD
wifiE

"Workstation service"
workstationD
workstationE

"Select exe to set DSCP values to"
dscpauto

"NVIDIA Display Container LS service"
nvcontainerD
nvcontainerE

"NVIDIA Display Container LS service context menu"
nvcontainerCMD
nvcontainerCME

"Force P-State 0 on NVIDIA cards"
NVPstate
revertNVPState

"HDCP (High-bandwidth Digital Content Protection)"
hdcpD
hdcpE

"Static IP"
staticip
revertstaticIP

"Network settings"
netAtlasDefault
netWinDefault

"Safe mode scripts"
safeE
safeC
safeN
safe

"Visual C++ Redistributables AIO Pack"
vcreR

"Send To context menu debloat"
sendToDebloat

"Mitigations"
mitD
mitE

) do (
    if "%~1"=="/%%a" (
        goto %%a
    )
)

:: if the first argument does not match any known scripts, fail
goto argumentFAIL

:argumentFAIL
echo atlas-config had no arguements or invalid arguments passed to it.
echo Either you are launching atlas-config directly or the "%~nx0" script is broken.
echo Please report this to the Atlas Discord server or GitHub.
pause & exit /b 1

:test
set /P c="Test with echo on? "
if "%c%"=="Y" echo on
set /P argPrompt="Which script would you like to test? E.g. (:testScript) "
goto %argPrompt%
echo You should not reach this message^^!
pause & exit /b 1

:startup
:: create log directory for troubleshooting
mkdir %WinDir%\AtlasModules\Logs
cls & echo Please wait, this may take a moment.
setx path "%path%;%WinDir%\AtlasModules;%WinDir%\AtlasModules\Apps;%WinDir%\AtlasModules\Other;%WinDir%\AtlasModules\Tools;" -m  > nul 2>nul
call %WinDir%\AtlasModules\refreshenv.cmd
if %ERRORLEVEL%==0 (echo %date% - %time% Atlas Modules path set...>> %install_log%
) ELSE (echo %date% - %time% Failed to set Atlas Modules path! >> %install_log%)

echo false > C:\Users\Public\success.txt

:auto
%WinDir%\AtlasModules\Apps\vcredist.exe /ai
if %ERRORLEVEL%==0 (echo %date% - %time% Visual C++ Redistributables installed...>> %install_log%
) ELSE (echo %date% - %time% Failed to install Visual C++ Redistributables! >> %install_log%)

:: change ntp server from windows server to pool.ntp.org
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org"

:: resync time to pool.ntp.org
net start w32time
w32tm /config /update
w32tm /resync
%setSvc% W32Time 4
if %ERRORLEVEL%==0 (echo %date% - %time% NTP server set...>> %install_log%
) ELSE (echo %date% - %time% Failed to set NTP server! >> %install_log%)

cls & echo Please wait. This may take a moment.

:: optimize ntfs parameters
:: disable last access information on directories, performance/privacy
fsutil behavior set disablelastaccess 1

:: disable the creation of 8.3 character-length file names on FAT- and NTFS-formatted volumes
:: https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security
fsutil behavior set disable8dot3 1

if %ERRORLEVEL%==0 (echo %date% - %time% File system optimized...>> %install_log%
) ELSE (echo %date% - %time% Failed to optimize file system! >> %install_log%)

:: disable useless scheduled tasks
for %%a in (
    "\Microsoft\Windows\ApplicationData\appuriverifierdaily"
    "\Microsoft\Windows\ApplicationData\appuriverifierinstall"
    "\Microsoft\Windows\ApplicationData\DsSvcCleanup"
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
    "\Microsoft\Windows\Application Experience\StartupAppTask"
    "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask"
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "\Microsoft\Windows\Defrag\ScheduledDefrag"
    "\Microsoft\Windows\Device Information\Device"
    "\Microsoft\Windows\Device Setup\Metadata Refresh"
    "\Microsoft\Windows\Diagnosis\Scheduled"
    "\Microsoft\Windows\DiskCleanup\SilentCleanup"
    "\Microsoft\Windows\DiskFootprint\Diagnostics"
    "\Microsoft\Windows\InstallService\ScanForUpdates"
    "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"
    "\Microsoft\Windows\InstallService\SmartRetry"
    "\Microsoft\Windows\Management\Provisioning\Cellular"
    "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents"
    "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic"
    "\Microsoft\Windows\MUI\LPRemove"
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
    "\Microsoft\Windows\Printing\EduPrintProv"
    "\Microsoft\Windows\PushToInstall\LoginCheck"
    "\Microsoft\Windows\Ras\MobilityManager"
    "\Microsoft\Windows\Registry\RegIdleBackup"
    "\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
    "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
    "\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTaskNetwork"
    "\Microsoft\Windows\StateRepository\MaintenanceTasks"
    "\Microsoft\Windows\Time Synchronization\ForceSynchronizeTime"
    "\Microsoft\Windows\Time Synchronization\SynchronizeTime"
    "\Microsoft\Windows\Time Zone\SynchronizeTimeZone"
    "\Microsoft\Windows\UpdateOrchestrator\Report policies"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\UPnP\UPnPHostConfig"
    "\Microsoft\Windows\WaaSMedic\PerformRemediation"
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "\Microsoft\Windows\Windows Filtering Platform\BfeOnServiceStartTypeChange"
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\Wininet\CacheTask"
    "\Microsoft\XblGameSave\XblGameSaveTask"
) do (
	schtasks /change /disable /TN %%a > nul 2>nul
)

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled scheduled tasks...>> %install_log%
) ELSE (echo %date% - %time% Failed to disable scheduled tasks! >> %install_log%)
cls & echo Please wait. This may take a moment.

:: enable MSI mode on USB, GPU, SATA controllers and network adapters
:: deleting DevicePriority sets the priority to undefined
for %%a in (
    Win32_USBController,
    Win32_VideoController,
    Win32_NetworkAdapter,
    Win32_IDEController
) do (
    for /f %%i in ('wmic path %%a get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f > nul 2>nul
        reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f > nul 2>nul
    )
)

:: if e.g. VMWare is used, set network adapter to normal priority as undefined on some virtual machines may break internet connection
wmic computersystem get manufacturer /format:value | findstr /i /C:VMWare && (
    for /f %%a in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /l "PCI\VEN_"') do (
        reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%a\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "2"  /f > nul 2>nul
    )
)

if %ERRORLEVEL%==0 (echo %date% - %time% MSI mode set...>> %install_log%
) ELSE (echo %date% - %time% Failed to set MSI mode! >> %install_log%)

cls & echo Please wait. This may take a moment.

:: --- Hardening and Miscellaneous ---

:: delete defaultuser0 account used during oobe
net user defaultuser0 /delete > nul 2>nul

:: disable reserved storage
DISM /Online /Set-ReservedStorageState /State:Disabled

:: rebuild performance counters
:: https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/manually-rebuild-performance-counters
lodctr /r > nul 2>nul
lodctr /r > nul 2>nul
winmgmt /resyncperf

:: disable PowerShell telemetry
:: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_telemetry?view=powershell-7.3
setx POWERSHELL_TELEMETRY_OPTOUT 1

:: set .ps1 file types to open with PowerShell by default
ftype Microsoft.PowerShellScript.1="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -ExecutionPolicy Unrestricted -File "%1" %*

:: disable hibernation and fast startup
powercfg -h off

:: disable sleep study
wevtutil set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false
wevtutil set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false

:: hide useless windows immersive control panel pages
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:quiethours;tabletmode;project;crossdevice;remotedesktop;mobile-devices;network-cellular;network-wificalling;network-airplanemode;nfctransactions;maps;sync;speech;easeofaccess-magnifier;easeofaccess-narrator;easeofaccess-speechrecognition;easeofaccess-eyecontrol;privacy-speech;privacy-general;privacy-speechtyping;privacy-feedback;privacy-activityhistory;privacy-location;privacy-callhistory;privacy-eyetracker;privacy-messaging;privacy-automaticfiledownloads;windowsupdate;delivery-optimization;windowsdefender;backup;recovery;findmydevice;windowsinsider" /f

:: disable and delete adobe font type manager
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Font Drivers" /v "Adobe Type Manager" /f > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "DisableATMFD" /t REG_DWORD /d "1" /f

:: disable USB autorun/play
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f

:: disable lock screen camera
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreenCamera" /t REG_DWORD /d "1" /f

:: disable remote assistance
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fAllowFullControl" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fAllowToGetHelp" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v "fEnableChatControl" /t REG_DWORD /d "0" /f

:: restrict anonymous access to named pipes and shares
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220932
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v "RestrictNullSessAccess" /t REG_DWORD /d "1" /f

:: disable smb compression (possible smbghost vulnerability workaround)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" /v "DisableCompression" /t REG_DWORD /d "1" /f

:: disable smb bandwidth throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "DisableBandwidthThrottling" /t REG_DWORD /d "1" /f

:: block anonymous enumeration of sam accounts
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220929
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d "1" /f

:: restrict anonymous enumeration of shares
:: https://www.stigviewer.com/stig/windows_10/2021-03-10/finding/V-220930
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RestrictAnonymous" /t REG_DWORD /d "1" /f

:: disable network location wizard
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" /f

:: disable smart multi-homed name resolution
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "DisableParallelAandAAAA " /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "DisableSmartNameResolution" /t REG_DWORD /d "1" /f

:: disable wi-fi sense
reg add "HKLM\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager\config" /v "AutoConnectAllowedOEM" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager" /v "WifiSenseCredShared" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager" /v "WifiSenseOpen" /t REG_DWORD /d "0" /f

:: disable hotspot 2.0 networks
reg add "HKLM\SOFTWARE\Microsoft\WlanSvc\AnqpCache" /v "OsuRegistrationStatus" /t REG_DWORD /d "0" /f

:: netbios hardening
:: netbios is disabled. if it manages to become enabled, protect against NBT-NS poisoning attacks
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v "NodeType" /t REG_DWORD /d "2" /f

:: mitigate against hivenightmare/serious sam
icacls %WinDir%\system32\config\*.* /inheritance:e > nul

:: set strong cryptography on 64 bit and 32 bit .net framework (version 4 and above) to fix the scoop installation issue
:: https://github.com/ScoopInstaller/Scoop/issues/2040#issuecomment-369686748
reg add "HKLM\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v "SchUseStrongCrypto" /t REG_DWORD /d "1" /f

:: duplicate 'High Performance' power plan, customize it and make it the Atlas power plan
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 11111111-1111-1111-1111-111111111111
powercfg -setactive 11111111-1111-1111-1111-111111111111

:: set current power scheme to Atlas
powercfg -changename 11111111-1111-1111-1111-111111111111 "Atlas Power Scheme" "Power scheme optimized for optimal latency and performance (v0.1.0)"
:: turn off hard disk after 0 seconds
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
:: turn off secondary nvme idle timeout
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 0012ee47-9041-4b5d-9b77-535fba8b1442 d3d55efd-c1ff-424e-9dc3-441be7833010 0
:: turn off primary nvme idle timeout
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 0012ee47-9041-4b5d-9b77-535fba8b1442 d639518a-e56d-4345-8af2-b9f32fb26109 0
:: turn off nvme noppme
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 0012ee47-9041-4b5d-9b77-535fba8b1442 fc7372b6-ab2d-43ee-8797-15e9841f2cca 0
:: set slide show to paused
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1
:: turn off system unattended sleep timeout
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 7bc4a2f9-d8fc-4469-b07b-33eb785aaca0 0
:: disable allow wake timers
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 0
:: disable hub selective suspend timeout
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0
:: disable usb selective suspend setting
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
:: set usb 3 link power mangement to maximum performance
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0
:: disable deep sleep
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 2e601130-5351-4d9d-8e04-252966bad054 d502f7ee-1dc7-4efd-a55d-f04b6f5c0545 0
:: turn off display after 0 seconds
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
:: disable critical battery notification
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f 5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f 0
:: disable critical battery action
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f 637ea02f-bbcb-4015-8e2c-a1c7b9c0b546 0
:: set low battery level to 0
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f 8183ba9a-e910-48da-8769-14ae6dc1170a 0
:: set critical battery level to 0
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f 9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469 0
:: disable low battery notification
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f bcded951-187b-4d05-bccc-f7e51960c258 0
:: set reserve battery level to 0
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 e73a048d-bf27-4f12-9731-8b2076e8891f f3c5027d-cd16-4930-aa6b-90db844a8f00 0

:: set the active scheme as the current scheme
powercfg -setactive scheme_current

:: disable power management features
call :powerD /function

if %ERRORLEVEL%==0 (echo %date% - %time% Power management features configured...>> %install_log%
) ELSE (echo %date% - %time% Failed to configure power management features! >> %install_log%)

:: set service split threshold
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "4294967295" /f

if %ERRORLEVEL%==0 (echo %date% - %time% Service split treshold set...>> %install_log%
) ELSE (echo %date% - %time% Failed to set service split treshold! >> %install_log%)

:: disable unnecessary autologgers
for %%a in (
    "Circular Kernel Context Logger"
    "CloudExperienceHostOobe"
    "DefenderApiLogger"
    "DefenderAuditLogger"
    "Diagtrack-Listener"
    "Diaglog"
    "LwtNetLog"
    "Microsoft-Windows-Rdp-Graphics-RdpIdd-Trace"
    "NetCore"
    "NtfsLog"
    "RadioMgr"
    "RdrLog"
    "ReadyBoot"
    "SpoolerLogger"
    "UBPM"
    "WdiContextLog"
    "WiFiSession"
) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~a" /v "Start" /t REG_DWORD /d "0" /f
)
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled unnecessary autologgers...>> %install_log%
) ELSE (echo %date% - %time% Failed to disable unnecessary autologgers! >> %install_log%)

:: disable dma remapping
:: https://docs.microsoft.com/en-us/windows-hardware/drivers/pci/enabling-dma-remapping-for-device-drivers
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "DmaRemappingCompatible" ^| find /i "Services\" ') do (
	reg add "%%a" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)
echo %date% - %time% Disabled dma remapping...>> %install_log%

:: disable netbios over tcp/ip
:: works only when services are enabled
for /f "delims=" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions" ^| findstr "HKEY"') do (
    reg add "%%a" /v "NetbiosOptions" /t REG_DWORD /d "2" /f
)
if %ERRORLEVEL%==0 (echo %date% - %time% Disabled netbios over tcp/ip...>> %install_log%
) ELSE (echo %date% - %time% Failed to disable netbios over tcp/ip! >> %install_log%)

:: make certain applications in the AtlasModules folder request UAC
:: although these applications may already request UAC, setting this compatibility flag ensures they are ran as administrator
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "DevManView.exe" /t REG_SZ /d "~ RUNASADMIN" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "NSudo.exe" /t REG_SZ /d "~ RUNASADMIN" /f

cls & echo Please wait. This may take a moment.

:: unhide power scheme attributes
:: source: https://gist.github.com/Velocet/7ded4cd2f7e8c5fa475b8043b76561b5#file-unlock-powercfg-ps1
%PowerShell% "$PowerCfg = (Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings' -Recurse).Name -notmatch '\bDefaultPowerSchemeValues|(\\[0-9]|\b255)$';foreach ($item in $PowerCfg) { Set-ItemProperty -Path $item.Replace('HKEY_LOCAL_MACHINE','HKLM:') -Name 'Attributes' -Value 0 -Force}"
if %ERRORLEVEL%==0 (echo %date% - %time% Enabled hidden power scheme attributes...>> %install_log%
) ELSE (echo %date% - %time% Failed to enable hidden power scheme attributes! >> %install_log%)

:: disable nagle's algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%a in ('wmic path Win32_NetworkAdapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: set default power saving mode for all network cards to disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d "24" /f

:: configure nic settings
:: modified by Xyueta
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr "HKEY"') do (
    for %%i in (
        "*EEE"
        "*FlowControl"
        "*LsoV2IPv4"
        "*LsoV2IPv6"
        "*SelectiveSuspend"
        "*WakeOnMagicPacket"
        "*WakeOnPattern"
        "AdvancedEEE"
        "AutoDisableGigabit"
        "AutoPowerSaveModeEnabled"
        "EnableConnectedPowerGating"
        "EnableDynamicPowerGating"
        "EnableGreenEthernet"
        "EnableModernStandby"
        "EnablePME"
        "EnablePowerManagement"
        "EnableSavePowerNow"
        "GigaLite"
        "PowerSavingMode"
        "ReduceSpeedOnPowerDown"
        "ULPMode"
        "WakeOnLink"
        "WakeOnSlot"
        "WakeUpModeCap"
    ) do (
        for /f %%j in ('reg query "%%a" /v "%%~i" ^| findstr "HKEY"') do (
            reg add "%%j" /v "%%~i" /t REG_SZ /d "0" /f
        )
    )
)

:: configure netsh settings
netsh int tcp set heuristics disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%a in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%a routerdiscovery=disabled store=persistent
)

if %ERRORLEVEL%==0 (echo %date% - %time% Network optimized...>> %install_log%
) ELSE (echo %date% - %time% Failed to optimize network! >> %install_log%)

:: disable network adapters
:: IPv6, Client for Microsoft Networks, File and Printer Sharing, LLDP Protocol, Link-Layer Topology Discovery Mapper, Link-Layer Topology Discovery Responder
%PowerShell% "Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6, ms_msclient, ms_server, ms_lldp, ms_lltdio, ms_rspndr"

:: disable system devices
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "AMD PSP"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "AMD SMBus"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Base System Device"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "*Bluetooth*" /use_wildcard
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Composite Bus Enumerator"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "High precision event timer"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Intel Management Engine"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Intel SMBus"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Hyper-V NT Kernel Integration VSP"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Hyper-V PCI Server"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Hyper-V Virtual Disk Server"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Hyper-V Virtual Machine Bus Provider"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft Kernel Debug Network Adapter"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Microsoft RRAS Root Enumerator"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Motherboard resources"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "Numeric Data Processor"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "PCI Data Acquisition and Signal Processing Controller"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "PCI Encryption/Decryption Controller"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "PCI Memory Controller"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "PCI Simple Communications Controller"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "SM Bus Controller"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "System CMOS/real time clock"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "System Speaker"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "System Timer"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "UMBus Root Bus Enumerator"

:: disable network devices
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (IKEv2)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (IP)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (IPv6)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (L2TP)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (Network Monitor)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (PPPOE)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (PPTP)"
%WinDir%\AtlasModules\Apps\DevManView.exe /disable "WAN Miniport (SSTP)"

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled system devices...>> %install_log%
) ELSE (echo %date% - %time% Failed to disable system devices! >> %install_log%)

:: backup default windows services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "skip=1" %%a in ('wmic service get Name ^| findstr "[a-z]" ^| findstr /v "TermService"') do (
    set svc=%%a
    set svc=!svc: =!
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
        set /a start=%%a
        echo !start!
        echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
        echo "Start"=dword:0000000!start! >> %filename%
        echo] >> %filename%
	)
) > nul 2>&1

:: backup default windows drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Windows drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%a in ('driverquery /FO CSV') do (
	set svc=%%a
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%a
		echo !start!
		echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: services
%setSvc% AppIDSvc 4
%setSvc% AppVClient 4
%setSvc% AppXSvc 3
%setSvc% bam 4
%setSvc% BthAvctpSvc 4
%setSvc% cbdhsvc 4
%setSvc% CryptSvc 3
%setSvc% defragsvc 3
%setSvc% diagnosticshub.standardcollector.service 4
%setSvc% diagsvc 4
%setSvc% DispBrokerDesktopSvc 4
%setSvc% DisplayEnhancementService 4
%setSvc% DoSvc 3
%setSvc% DPS 4
%setSvc% DsmSvc 3
:: %setSvc% DsSvc 4 < can cause issues with snip & sketch
%setSvc% Eaphost 3
%setSvc% EFS 3
%setSvc% fdPHost 4
%setSvc% FDResPub 4
%setSvc% FontCache 4
%setSvc% gcs 4
%setSvc% hvhost 4
%setSvc% icssvc 4
%setSvc% IKEEXT 4
%setSvc% InstallService 3
%setSvc% iphlpsvc 4
%setSvc% IpxlatCfgSvc 4
:: %setSvc% KeyIso 4 < causes issues with nvcleanstall's driver telemetry tweak
%setSvc% KtmRm 4
%setSvc% LanmanServer 4
%setSvc% LanmanWorkstation 4
%setSvc% lmhosts 4
%setSvc% MSDTC 4
%setSvc% NetTcpPortSharing 4
%setSvc% PcaSvc 4
%setSvc% PhoneSvc 4
%setSvc% RasMan 4
%setSvc% SharedAccess 4
%setSvc% ShellHWDetection 4
%setSvc% SmsRouter 4
%setSvc% Spooler 4
%setSvc% sppsvc 3
%setSvc% SSDPSRV 4
%setSvc% SstpSvc 4
%setSvc% SysMain 4
%setSvc% Themes 4
%setSvc% UsoSvc 3
%setSvc% VaultSvc 4
%setSvc% vmcompute 4
%setSvc% vmicguestinterface 4
%setSvc% vmicheartbeat 4
%setSvc% vmickvpexchange 4
%setSvc% vmicrdv 4
%setSvc% vmicshutdown 4
%setSvc% vmictimesync 4
%setSvc% vmicvmsession 4
%setSvc% vmicvss 4
%setSvc% W32Time 4
%setSvc% WarpJITSvc 4
%setSvc% WdiServiceHost 4
%setSvc% WdiSystemHost 4
%setSvc% Wecsvc 4
%setSvc% WEPHOSTSVC 4
%setSvc% WinHttpAutoProxySvc 4
%setSvc% WPDBusEnum 4
%setSvc% WSearch 4
%setSvc% wuauserv 3

:: drivers
%setSvc% 3ware 4
%setSvc% ADP80XX 4
%setSvc% AmdK8 4
%setSvc% arcsas 4
%setSvc% AsyncMac 4
%setSvc% Beep 4
%setSvc% bindflt 4
%setSvc% bttflt 4
%setSvc% buttonconverter 4
%setSvc% CAD 4
%setSvc% cdfs 4
%setSvc% CimFS 4
%setSvc% circlass 4
%setSvc% cnghwassist 4
%setSvc% CompositeBus 4
%setSvc% Dfsc 4
%setSvc% ErrDev 4
%setSvc% fdc 4
%setSvc% flpydisk 4
:: %setSvc% FileInfo 4 < breaks installing microsoft store apps to different disk (now disabled via store script)
:: %setSvc% FileCrypt 4 < Breaks installing microsoft store apps to different disk (now disabled via store script)
%setSvc% gencounter 4
%setSvc% GpuEnergyDrv 4
%setSvc% hvcrash 4
%setSvc% hvservice 4
%setSvc% hvsocketcontrol 4
%setSvc% KSecPkg 4
%setSvc% mrxsmb 4
%setSvc% mrxsmb20 4
%setSvc% NdisVirtualBus 4
%setSvc% nvraid 4
%setSvc% passthruparser 4
:: %setSvc% PEAUTH 4 < breaks uwp streaming apps like netflix, manual mode does not fix
%setSvc% pvhdparser 4
:: set rdbss to manual instead of disabling (fixes wsl), thanks phlegm
%setSvc% rdbss 3
%setSvc% rdyboost 4
%setSvc% sfloppy 4
%setSvc% SiSRaid2 4
%setSvc% SiSRaid4 4
%setSvc% spaceparser 4
%setSvc% srv2 4
%setSvc% storflt 4
%setSvc% Tcpip6 4
%setSvc% tcpipreg 4
%setSvc% Telemetry 4
%setSvc% udfs 4
%setSvc% umbus 4
%setSvc% VerifierExt 4
%setSvc% vhdparser 4
%setSvc% Vid 4
%setSvc% vkrnlintvsc 4
%setSvc% vkrnlintvsp 4
%setSvc% vmbus 4
%setSvc% vmbusr 4
%setSvc% vmgid 4
:: %setSvc% volmgrx 4 < breaks dynamic disks
%setSvc% vpci 4
%setSvc% vsmraid 4
%setSvc% VSTXRAID 4
:: %setSvc% wcifs 4 < breaks various microsoft store games, erroring with "filter not found"
%setSvc% wcnfs 4
%setSvc% WindowsTrustedRTProxy 4

:: remove lower filters for rdyboost driver
set key="HKLM\SYSTEM\CurrentControlSet\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}"
for /f "skip=1 tokens=3*" %%a in ('reg query %key% /v "LowerFilters"') do (set val=%%a)
:: `val` would be like `rdyboost\0fvevol\0iorate`
set val=%val:rdyboost\0=%
set val=%val:\0rdyboost=%
set val=%val:rdyboost=%
reg add %key% /v "LowerFilters" /t REG_MULTI_SZ /d %val% /f

if %ERRORLEVEL%==0 (echo %date% - %time% Disabled services...>> %install_log%
) ELSE (echo %date% - %time% Failed to disable services! >> %install_log%)

:: backup default Atlas services
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas services.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "skip=1" %%a in ('wmic service get Name ^| findstr "[a-z]" ^| findstr /v "TermService"') do (
	set svc=%%a
	set svc=!svc: =!
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%a
		echo !start!
		echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: backup default Atlas drivers
set filename="C:%HOMEPATH%\Desktop\Atlas\Troubleshooting\Services\Default Atlas drivers.reg"
echo Windows Registry Editor Version 5.00 >> %filename%
echo] >> %filename%
for /f "delims=," %%a in ('driverquery /FO CSV') do (
	set svc=%%a
	for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\!svc!" /t REG_DWORD /s /c /f "Start" /e ^| findstr "[0-4]$"') do (
		set /a start=%%a
		echo !start!
		echo [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\!svc!] >> %filename%
		echo "Start"=dword:0000000!start! >> %filename%
		echo] >> %filename%
	)
) > nul 2>&1

:: Registry

:: clean up firewall rules
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules" /f

:: clear image file execution options
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options" /f

:: bsod quality of life
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "AutoReboot" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "CrashDumpEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "LogEvent" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v "DisplayParameters" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\StorageTelemetry" /v "DeviceDumpEnabled" /t REG_DWORD /d "0" /f

:: gpo for start menu (tiles)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /t REG_EXPAND_SZ /d "%WinDir%\layout.xml" /f

:: configure start menu settings
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoStartMenuMFUprogramsList" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "HideRecentlyAddedApps" /t REG_DWORD /d "1" /f

:: disable startup delay of running apps
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d "0" /f

:: reduce menu show delay time
:: automatically close any apps and continue to restart, shut down, or sign out of windows
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f

:: enable dark mode and disable transparency
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t REG_DWORD /d "0" /f

:: configure visual effect settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f

:: disable desktop wallpaper import quality reduction
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t REG_DWORD /d "100" /f

:: disable lockscreen
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData" /v "AllowLockScreen" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v "NoLockScreen" /t REG_DWORD /d "1" /f

:: disable acrylic blur effect on sign-in screen background
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DisableAcrylicBackgroundOnLogon" /t REG_DWORD /d "1" /f

:: disable show window contents while dragging
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f

:: disable animate windows when minimizing and maximizing
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_SZ /d "0" /f

:: enable window colorization
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableWindowColorization" /t REG_DWORD /d "1" /f

:: do not allow themes to changes desktop iocns and mouse pointers
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v "ThemeChangesMousePointers" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v "ThemeChangesDesktopIcons" /t REG_DWORD /d "0" /f

:: configure desktop window manager
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "Composition" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableWindowColorization" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f

:: disable auto download of microsoft store apps
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d "2" /f

:: disable fast user switching
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "HideFastUserSwitching" /t REG_DWORD /d "1" /f

:: disable website access to language list
%currentuser% reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d "1" /f

:: re-enable onedrive if user manually reinstall it
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "0" /f

:: disable speech model updates
reg add "HKLM\SOFTWARE\Policies\Microsoft\Speech" /v "AllowSpeechModelUpdate" /t REG_DWORD /d "0" /f

:: disable online speech recognition
reg add "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization" /v "AllowInputPersonalization" /t REG_DWORD /d "0" /f

:: disable windows insider and build previews
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableConfigFlighting" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "AllowBuildPreview" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v "EnableExperimentation" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" /v "HideInsiderPage" /t REG_DWORD /d "1" /f

:: disable ceip
reg add "HKLM\SOFTWARE\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM" /v "OptIn" /t REG_DWORD /d "0" /f

:: disable activity feed
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d "0" /f

:: disable windows media DRM internet access
reg add "HKLM\SOFTWARE\Policies\Microsoft\WMDRM" /v "DisableOnline" /t REG_DWORD /d "1" /f

:: disable windows media player wizard on first run
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences" /v "AcceptedPrivacyStatement" /t REG_DWORD /d "1" /f

:: configure search settings
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "DisableWebSearch" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDeviceSearchHistoryEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d "0" /f

:: disable search suggestions
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d "1" /f

:: set search as icon on taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f

:: configure file explorer settings

:: enable old alt tab
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AltTabSettings" /t REG_DWORD /d "1" /f

:: enable always show all icons and notifications on the taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "EnableAutoTray" /t REG_DWORD /d "0" /f

:: hide frequently used files/folders in quick access
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d "0" /f

:: hide recently used files/folders in quick access
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d "0" /f

:: disable dekstop peek
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisablePreviewDesktop" /t REG_DWORD /d "1" /f

:: disable aero shake
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DisallowShaking" /t REG_DWORD /d "1" /f

:: show command prompt on win+x menu
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontUsePowerShellOnWinX" /t REG_DWORD /d "1" /f

:: show hidden files, folders and drives in file epxlorer
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d "1" /f

:: show file extensions in file explorer
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d "0" /f

:: disable show thumbnails instead of icons
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d "1" /f

:: open file explorer to this pc
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d "1" /f

:: disable show translucent selection rectangle on desktop
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t REG_DWORD /d "0" /f

:: set alt tab to open windows only
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "MultiTaskingAltTabFilter" /t REG_DWORD /d "3" /f

:: disable sharing wizard
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SharingWizardOn" /t REG_DWORD /d "0" /f

:: hide sync provider notifications in file explorer
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d "0" /f

:: configure snap settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "JointResize" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapAssist" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SnapFill" /t REG_DWORD /d "0" /f

:: disable recent items and frequent places in file explorer
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d "0" /f

:: disable app launch tracking
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d "0" /f

:: disable taskbar animations
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f

:: hide badges on taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarBadges" /t REG_DWORD /d "0" /f

:: show more details in file transfer dialog
%currentuser% reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" /v "EnthusiastMode" /t REG_DWORD /d "1" /f

:: clear history of recently opened documents on exit
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "ClearRecentDocsOnExit" /t REG_DWORD /d "1" /f

:: do not track shell shortcuts during roaming
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "LinkResolveIgnoreLinkInfo" /t REG_DWORD /d "1" /f

:: disable user tracking
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInstrumentation" /t REG_DWORD /d "1" /f

:: disable internet file association service
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoInternetOpenWith" /t REG_DWORD /d "1" /f

:: disable low disk space warning
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoLowDiskSpaceChecks" /t REG_DWORD /d "1" /f

:: do not history of recently opened documents
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoRecentDocsHistory" /t REG_DWORD /d "1" /f

:: do not use the search-based method when resolving shell shortcuts
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveSearch" /t REG_DWORD /d "1" /f

:: do not use the tracking-based method when resolving shell shortcuts
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoResolveTrack" /t REG_DWORD /d "1" /f

:: do not allow pinning microsoft store app to taskbar
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoPinningStoreToTaskbar" /t REG_DWORD /d "1" /f

:: do not display or track items in jump lists from remote locations
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoRemoteDestinations" /t REG_DWORD /d "1" /f

:: Extend icon cache size to 4 MB
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_SZ /d "4096" /f

:: disable automatic folder type discovery
%currentuser% reg delete "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f
%currentuser% reg add "HKCU\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /v "FolderType" /t REG_SZ /d "NotSpecified" /f

:: disable content delivery manager
:: disable pre-installed apps
:: disable windows welcome experience
:: disable suggested content in immersive control panel
:: disable fun facts, tips, tricks on windows spotlight
:: disable start menu suggestions
:: disable get tips, tricks, and suggestions as you use windows
for %%a in (
    "ContentDeliveryAllowed"
    "OemPreInstalledAppsEnabled"
    "PreInstalledAppsEnabled"
    "PreInstalledAppsEverEnabled"
    "SilentInstalledAppsEnabled"
    "SubscribedContent-310093Enabled"
    "SubscribedContent-338393Enabled"
    "SubscribedContent-353694Enabled"
    "SubscribedContent-353696Enabled"
    "SubscribedContent-338387Enabled"
    "RotatingLockScreenOverlayEnabled"
    "SubscribedContent-338388Enabled"
    "SystemPaneSuggestionsEnabled"
    "SubscribedContent-338389Enabled"
    "SoftLandingEnabled"
) do (
    %currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "%%~a" /t REG_DWORD /d "0" /f
)

:: disable windows spotlight features
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d "1" /f

:: disable tips in immersive control panel
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowOnlineTips" /v "value" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "AllowOnlineTips" /t REG_DWORD /d "0" /f

:: disable suggest ways I can finish setting up my device
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v "ScoobeSystemSettingEnabled" /t REG_DWORD /d "0" /f

:: disable use sign-in info to auto finish setting up device after update or restart
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableAutomaticRestartSignOn" /t REG_DWORD /d "1" /f

:: disable disk quota
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DiskQuota" /v "Enable" /t REG_DWORD /d "0" /f

:: add atlas' website as a start page in internet explorer
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "https://atlasos.net" /f

:: disable program compatibility assistant
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableEngine" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d "1" /f

:: never use tablet mode
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" /v "SignInMode" /t REG_DWORD /d "1" /f

:: disable 'Open file' - security warning message
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v "1806" /t REG_DWORD /d "0" /f

:: do not preserve zone information in file attachments
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d "1" /f

:: disable enhance pointer precison
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Mouse" /v "MouseHoverTime" /t REG_SZ /d "0" /f

:: configure ease of access settings
:: both immersive and legacy control panel

:: disable always read and scan this section in ease of access
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfscan" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Ease of Access" /v "selfvoice" /t REG_DWORD /d "0" /f

:: disable warning sounds and sound on activation in ease of access
%currentuser% reg add "HKCU\Control Panel\Accessibility" /v "Warning Sounds" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility" /v "Sound on Activation" /t REG_DWORD /d "0" /f

:: disable visual warning for sounds in ease of access
%currentuser% reg add "HKCU\Control Panel\Accessibility\SoundSentry" /v "WindowsEffect" /t REG_SZ /d "0" /f

:: disable make touch and tablets easier to use in ease of access
%currentuser% reg add "HKCU\Control Panel\Accessibility\SlateLaunch" /v "LaunchAT" /t REG_DWORD /d "0" /f

:: disable annoying keyboard and mouse features
%currentuser% reg add "HKCU\Control Panel\Accessibility\HighContrast" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_DWORD /d "0" /f

:: disable touch visual feedback
%currentuser% reg add "HKCU\Control Panel\Cursors" /v "GestureVisualization" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\Control Panel\Cursors" /v "ContactVisualization" /t REG_DWORD /d "0" /f

:: disable text/ink/handwriting telemetry
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Personalization\Settings" /v "AcceptedPrivacyPolicy" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d "1" /f

:: disable spell checking
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableSpellchecking" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableTextPrediction" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnablePredictionSpaceInsertion" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableDoubleTapSpace" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\TabletTip\1.7" /v "EnableAutocorrection" /t REG_DWORD /d "0" /f

:: disable typing insights
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Input\Settings" /v "InsightsEnabled" /t REG_DWORD /d "0" /f

:: disable windows error reporting
reg add "HKLM\SOFTWARE\Policies\Microsoft\PCHealth\ErrorReporting" /v "DoReport" /t REG_DWORD /d "0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "LoggingDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultConsent" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting\Consent" /v "DefaultOverrideBehavior" /t REG_DWORD /d "1" /f

:: lock UserAccountControlSettings.exe - users can enable UAC from there without luafv and appinfo enabled, which breaks uac completely and causes issues
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /t REG_SZ /d "atlas-config.cmd /uacSettings /skipAdminCheck" /f

:: disable data collection
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowDeviceNameInTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t REG_DWORD /d "0" /f

:: configure app permissions/privacy in immersive control panel
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" /v "Value" /t REG_SZ /d "Deny" /f

:: configure voice activation settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationOnLockScreenEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationLastUsed" /t REG_DWORD /d "0" /f

:: disable smartscreen for microsoft store apps
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /t REG_DWORD /d "0" /f

:: disable smartscreen for apps and files from web
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d "0" /f

:: disable experimentation
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" /v "Value" /t REG_DWORD /d "0" /f

:: configure miscellaneous settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v "ShowedToastAtLevel" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WDI\{9c5a40da-b965-4fc3-8781-88dd50a6299d}" /v "ScenarioExecutionEnabled" /t REG_DWORD /d "0" /f

:: disable advertising info
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable cloud optimized taskbars
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d "1" /f

:: disable license telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v "NoGenTicket" /t REG_DWORD /d "1" /f

:: disable windows feedback
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d "0" /f
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "PeriodInNanoSeconds" /f > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d "1" /f

:: disable settings sync
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSync" /t REG_DWORD /d "2" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSettingSyncUserOverride" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v "DisableSyncOnPaidNetwork" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" /v "Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync" /v "SyncPolicy" /t REG_DWORD /d "5" /f

:: location tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "AllowFindMyDevice" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\FindMyDevice" /v "LocationSyncEnabled" /t REG_DWORD /d "0" /f

:: remove readyboost tab
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{55B3A0BD-4D28-42fe-8CFB-FA3EDFF969B8}" /f > nul 2>nul

:: hide meet now button on taskbar
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAMeetNow" /t REG_DWORD /d "1" /f

:: hide task view button on taskbar
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MultiTaskingView\AllUpView" /v "Enabled" /f > nul 2>nul
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /D "0" /f

:: hide news and interests on taskbar
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f

:: disable shared experiences
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableCdp" /t REG_DWORD /d "0" /f

:: show all tasks in control panel, credits to tenforums
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "InfoTip" /t REG_SZ /d "View list of all Control Panel tasks" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /v "System.ControlPanel.Category" /t REG_SZ /d "5" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\DefaultIcon" /ve /t REG_SZ /d "C:\Windows\System32\imageres.dll,-27" /f
reg add "HKLM\SOFTWARE\Classes\CLSID\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}\Shell\Open\Command" /ve /t REG_SZ /d "explorer.exe shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D15ED2E1-C75B-443c-BD7C-FC03B2F08C17}" /ve /t REG_SZ /d "All Tasks" /f

:: disable hyper-v and virtualization based security as default
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "EnableVirtualizationBasedSecurity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "RequirePlatformSecurityFeatures" /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HypervisorEnforcedCodeIntegrity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HVCIMATRequired" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "LsaCfgFlags" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "ConfigureSystemGuardLaunch" /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: memory management
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableCfg" /t REG_DWORD /d "0" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t REG_DWORD /d "0" /f

:: configure paging settings
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePageCombining" /t REG_DWORD /d "1" /f

:: disable mitigations
call :mitD /function

:: disable TsX
:: https://www.intel.com/content/www/us/en/support/articles/000059422/processors.html
:: reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: set Win32PrioritySeparation to short variable 1:1, no foreground boost
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d "36" /f

:: configure multimedia class scheduler
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d "10" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t REG_DWORD /d "10000" /f

:: configure gamebar/fullscreen exclusive
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\System\GameConfigStore" /v "GameDVR_DSEBehavior" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v "__COMPAT_LAYER" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f

:: disable game mode
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f

:: disable background apps
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f

:: disable notifications and notification center
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" /v "NoTileApplicationNotification" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f

:: unpin all quick access shortcuts by default
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.WiFi" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.AllSettings" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.BlueLightReduction" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.AvailableNetworks" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Location" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Connect" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.QuietHours" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.ScreenClipping" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Vpn" /t REG_NONE /d "" /f
%currentuser% reg add "HKCU\Control Panel\Quick Actions\Control Center\Unpinned" /v "Microsoft.QuickAction.Project" /t REG_NONE /d "" /f

:: disable all lockscreen notifications
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "LockScreenToastEnabled" /t REG_DWORD /d "0" /f

:: disable autoplay and autorun
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d "255" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoAutorun" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoAutoplayfornonVolume" /t REG_DWORD /d "1" /f

:: disable notify about usb issues
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Shell\USB" /v "NotifyOnUsbErrors" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Shell\USB" /v "NotifyOnWeakCharger" /t REG_DWORD /d "0" /f

:: disable folders in this pc
:: credit: https://www.tenforums.com/tutorials/6015-add-remove-folders-pc-windows-10-a.html
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{a0c69a99-21c8-4671-8703-7934162fcf1d}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" /v "ThisPCPolicy" /t REG_SZ /d "Hide" /f

:: add music and videos folders to quick access
start /b %PowerShell% "$o = new-object -com shell.application; $o.Namespace("""$env:userprofile\Videos""").Self.InvokeVerb("""pintohome"""); $o.Namespace("""$env:userprofile\Music""").Self.InvokeVerb("""pintohome""")" > nul 2>&1

:: fix no downloads folder bug
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" > nul 2>nul
if %ERRORLEVEL%==1 (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
)

:: enable legacy photo viewer
for %%a in (tif tiff bmp dib gif jfif jpe jpeg jpg jxr png) do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v ".%%~a" /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
)

:: set legacy photo viewer as default
for %%a in (tif tiff bmp dib gif jfif jpe jpeg jpg jxr png) do (
    %currentuser% reg add "HKCU\SOFTWARE\Classes\.%%~a" /ve /t REG_SZ /d "PhotoViewer.FileAssoc.Tiff" /f
)

:: disable gamebar presence writer
reg add "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d "0" /f

:: disable maintenance
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "1" /f

:: do not reduce sounds while in a call
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio" /v "UserDuckingPreference" /t REG_DWORD /d "3" /f

:: do not show hidden/disconnected devices in sound settings
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowDisconnectedDevices" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Multimedia\Audio\DeviceCpl" /v "ShowHiddenDevices" /t REG_DWORD /d "0" /f

:: set sound scheme to no sounds
%currentuser% %PowerShell% "New-ItemProperty -Path 'HKCU:\AppEvents\Schemes' -Name '(Default)' -Value '.None' -Force | Out-Null"
%currentuser% %PowerShell% "Get-ChildItem -Path 'HKCU:\AppEvents\Schemes\Apps' | Get-ChildItem | Get-ChildItem | Where-Object {$_.PSChildName -eq '.Current'} | Set-ItemProperty -Name '(Default)' -Value ''"

:: disable audio exclusive mode on all devices
for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

for /f "delims=" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"') do (
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},3" /t REG_DWORD /d "0" /f
    reg add "%%a\Properties" /v "{b3f8fa53-0004-438e-9003-51a46e139bfc},4" /t REG_DWORD /d "0" /f
)

:: show removable drivers only in 'This PC' on the file explorer sidebar
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" /f
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" /f

:: disable network navigation pane in file explorer
reg add "HKCR\CLSID\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}\ShellFolder" /v "Attributes" /t REG_DWORD /d "2962489444" /f

:: remove restore previous versions from context menu and files' properties
reg delete "HKCR\AllFilesystemObjects\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\PropertySheetHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "NoPreviousVersionsPage" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Policies\Microsoft\PreviousVersions" /v "DisableLocalPage" /f > nul 2>nul

:: remove give access to from context menu
reg delete "HKCR\*\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Directory\Background\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Directory\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\Drive\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul
reg delete "HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing" /f > nul 2>nul

:: remove cast to device from context menu
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{7AD84985-87B4-4a16-BE58-8B72A5B390F7}" /t REG_SZ /d "" /f

:: remove share from context menu
reg delete "HKCR\*\shellex\ContextMenuHandlers\ModernSharing" /f > nul 2>nul

:: remove extract all from context menu
reg delete "HKCR\CompressedFolder\ShellEx\ContextMenuHandlers\{b8cdcb65-b1bf-4b42-9428-1dfdb7ee92af}" /f > nul 2>nul

:: remove bitmap image from the 'New' context menu
reg delete "HKCR\.bmp\ShellNew" /f > nul 2>nul

:: remove rich text document from the 'New' context menu
reg delete "HKCR\.rtf\ShellNew" /f > nul 2>nul

:: remove include in library from context menu
reg delete "HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location" /f > nul 2>nul
reg delete "HKLM\SOFTWARE\Classes\Folder\ShellEx\ContextMenuHandlers\Library Location" /f > nul 2>nul

:: remove troubleshooting compatibility from context menu
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{1d27f844-3a1f-4410-85ac-14651078412d}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{1d27f844-3a1f-4410-85ac-14651078412d}" /t REG_SZ /d "" /f

:: remove '- Shortcut' text added onto shortcuts
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "link" /t REG_BINARY /d "00000000" /f

:: debloat 'Send To' context menu, hidden files do not show up in the 'Send To' context menu
attrib +h "C:\Users\%loggedinusername%\AppData\Roaming\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
attrib +h "C:\Users\%loggedinusername%\AppData\Roaming\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail"
attrib +h "C:\Users\%loggedinusername%\AppData\Roaming\Microsoft\Windows\SendTo\Documents.mydocs"

:: remove print from context menu
reg add "HKCR\SystemFileAssociations\image\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f
for %%a in (
    "batfile"
    "cmdfile"
    "docxfile"
    "fonfile"
    "htmlfile"
    "inffile"
    "inifile"
    "JSEFile"
    "otffile"
    "pfmfile"
    "regfile"
    "rtffile"
    "ttcfile"
    "ttffile"
    "txtfile"
    "VBEFile"
    "VBSFile"
    "WSFFile"
) do (
    reg add "HKCR\%%~a\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f
)

:: add .bat, .cmd, .reg and .ps1 to the 'New' context menu
reg add "HKLM\SOFTWARE\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6002" /f
reg add "HKLM\SOFTWARE\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\.cmd\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\.cmd\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6003" /f
reg add "HKLM\SOFTWARE\Classes\.ps1\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\.ps1\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "New file" /f
reg add "HKLM\SOFTWARE\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\regedit.exe,-309" /f

:: add install cab to context menu
reg delete "HKCR\CABFolder\Shell\RunAs" /f > nul 2>nul
reg add "HKCR\CABFolder\Shell\RunAs" /ve /t REG_SZ /d "Install" /f
reg add "HKCR\CABFolder\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\CABFolder\Shell\RunAs\Command" /ve /t REG_SZ /d "cmd /k DISM /online /add-package /packagepath:\"%1\"" /f

:: merge as trusted installer for registry files
reg add "HKCR\regfile\Shell\RunAs" /ve /t REG_SZ /d "Merge As TrustedInstaller" /f
reg add "HKCR\regfile\Shell\RunAs" /v "HasLUAShield" /t REG_SZ /d "1" /f
reg add "HKCR\regfile\Shell\RunAs\Command" /ve /t REG_SZ /d "NSudo.exe -U:T -P:E reg import "%1"" /f

:: double click to import power schemes
reg add "HKLM\SOFTWARE\Classes\powerplan\DefaultIcon" /ve /t REG_SZ /d "C:\Windows\System32\powercpl.dll,1" /f
reg add "HKLM\SOFTWARE\Classes\powerplan\Shell\open\command" /ve /t REG_SZ /d "powercfg /import \"%1\"" /f
reg add "HKLM\SOFTWARE\Classes\.pow" /ve /t REG_SZ /d "powerplan" /f
reg add "HKLM\SOFTWARE\Classes\.pow" /v "FriendlyTypeName" /t REG_SZ /d "Power Plan" /f

if %ERRORLEVEL%==0 (echo %date% - %time% Registry configuration applied...>> %install_log%
) ELSE (echo %date% - %time% Failed to apply registry configuration! >> %install_log%)

:: lowering dual boot choice time
:: no, this does not affect single OS boot time.
:: this is directly shown in microsoft docs https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/--timeout#parameters
bcdedit /timeout 10

:: setting to "no" provides worse results, delete the value instead.
:: this is here as a safeguard incase of user error
bcdedit /deletevalue useplatformclock > nul 2>nul

:: https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set#additional-settings
bcdedit /set disabledynamictick Yes

:: use legacy boot menu
bcdedit /set bootmenupolicy Legacy

:: disable automatic repair
bcdedit /set recoveryenabled no

:: make dual boot menu more descriptive
bcdedit /set description Atlas %branch% %ver%

:: disable hyper-v and vbs
bcdedit /set hypervisorlaunchtype off
bcdedit /set vm no
bcdedit /set vsmlaunchtype Off
bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS

echo %date% - %time% BCD options set...>> %install_log%

:: write to script log file
echo This log keeps track of which scripts have been run. This is never transfered to an online resource and stays local. > %user_log%
echo -------------------------------------------------------------------------------------------------------------------- >> %user_log%

:: clear false value
echo true > C:\Users\Public\success.txt
echo %date% - %time% Post-Install finished redirecting to sub script...>> %install_log%
exit


:::::::::::::::::::
:: Configuration ::
:::::::::::::::::::

:notiD
 %setSvc% WpnService 4
sc stop WpnService > nul 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Deny" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications disabled...>> %user_log%
goto finish

:notiE
%setSvc% WpnUserService 2
%setSvc% WpnService 2
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" /v "ToastEnabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableNotificationCenter" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" /v "Value" /t REG_SZ /d "Allow" /f
if %ERRORLEVEL%==0 echo %date% - %time% Notifications enabled...>> %user_log%
goto finish

:indexD
%setSvc% WSearch 4
sc stop WSearch > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Search Indexing disabled...>> %user_log%
goto finish

:indexE
%setSvc% WSearch 2
sc start WSearch > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Search Indexing enabled...>> %user_log%
goto finish

:wifiD
echo Applications like Microsoft Store and Spotify may not function correctly when Wi-Fi is disabled. If this is a problem, enable Wi-Fi and restart the computer.
%setSvc% WlanSvc 4
%setSvc% vwififlt 4
set /P c="Would you like to disable the network icon? (disables two extra services) [Y/N]: "
if /I "%c%"=="N" goto wifiDskip
%setSvc% netprofm 4
%setSvc% NlaSvc 4

:wifiDskip
if %ERRORLEVEL%==0 echo %date% - %time% Wi-Fi disabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:wifiE
%setSvc% netprofm 3
%setSvc% NlaSvc 2
%setSvc% WlanSvc 2
%setSvc% vwififlt 1
if %ERRORLEVEL%==0 echo %date% - %time% Wi-Fi enabled...>> %user_log%
%setSvc% eventlog 2
echo %date% - %time% EventLog enabled as Wi-Fi dependency...>> %user_log%
goto finish

:hyperD
:: bcdedit commands
bcdedit /set hypervisorlaunchtype off
bcdedit /set vm no
bcdedit /set vsmlaunchtype Off
bcdedit /set loadoptions DISABLE-LSA-ISO,DISABLE-VBS

:: disable hyper-v with DISM
DISM /Online /Disable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

:: apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "EnableVirtualizationBasedSecurity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "RequirePlatformSecurityFeatures" /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HypervisorEnforcedCodeIntegrity" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "HVCIMATRequired" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "LsaCfgFlags" /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /t REG_DWORD /v "ConfigureSystemGuardLaunch" /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable drivers
for %%a in (
    "hvcrash"
    "hvservice"
    "vhdparser"
    "vkrnlintvsc"
    "vkrnlintvsp"
    "vmbus"
    "Vid"
    "bttflt"
    "gencounter"
    "hvsocketcontrol"
    "passthruparser"
    "pvhdparser"
    "spaceparser"
    "storflt"
    "vmgid"
    "vmbusr"
    "vpci"
) do (
    %setSvc% %%~a 4 > nul 2>nul
)

:: disable services
for %%a in (
    "gcs"
    "hvhost"
    "vmcompute"
    "vmicguestinterface"
    "vmicheartbeat"
    "vmickvpexchange"
    "vmicrdv"
    "vmicshutdown"
    "vmictimesync"
    "vmicvmsession"
    "vmicvss"
) do (
    %setSvc% %%~a 4 > nul 2>nul
)

:: disable system devices
DevManView.exe /disable "Microsoft Hyper-V NT Kernel Integration VSP"
DevManView.exe /disable "Microsoft Hyper-V PCI Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Disk Server"
DevManView.exe /disable "Microsoft Hyper-V Virtual Machine Bus Provider"
DevManView.exe /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"

if %ERRORLEVEL%==0 echo %date% - %time% Hyper-V and VBS disabled...>> %user_log%
goto finish

:hyperE
:: bcdedit commands
bcdedit /set hypervisorlaunchtype auto > nul
bcdedit /deletevalue vm > nul
bcdedit /set vsmlaunchtype Auto > nul
bcdedit /deletevalue loadoptions > nul

:: enable hyper-v with DISM
DISM /Online /Enable-Feature:Microsoft-Hyper-V-All /Quiet /NoRestart

:: apply registry changes
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Windows.DeviceGuard::VirtualizationBasedSecuritye
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "RequirePlatformSecurityFeatures" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HypervisorEnforcedCodeIntegrity" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMATRequired" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "LsaCfgFlags" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "ConfigureSystemGuardLaunch" /f

:: found this to be the default
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "RequireMicrosoftSignedBootChain" /t REG_DWORD /d "1" /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "WasEnabledBy" /f
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /f

:: enable drivers
:: default for hvcrash is disabled
%setSvc% hvcrash 4 > nul 2>nul
%setSvc% hvservice 3 > nul 2>nul
%setSvc% vhdparser 3 > nul 2>nul
%setSvc% vmbus 0 > nul 2>nul
%setSvc% Vid 1 > nul 2>nul
%setSvc% bttflt 0 > nul 2>nul
%setSvc% gencounter 3 > nul 2>nul
%setSvc% hvsocketcontrol 3 > nul 2>nul
%setSvc% passthruparser 3 > nul 2>nul
%setSvc% pvhdparser 3 > nul 2>nul
%setSvc% spaceparser 3 > nul 2>nul
%setSvc% storflt 0 > nul 2>nul
%setSvc% vmgid 3 > nul 2>nul
%setSvc% vmbusr 3 > nul 2>nul
%setSvc% vpci 0 > nul 2>nul

:: enable services
for %%a in (
	"gcs"
	"hvhost"
	"vmcompute"
	"vmicguestinterface"
	"vmicheartbeat"
	"vmickvpexchange"
	"vmicrdv"
	"vmicshutdown"
	"vmictimesync"
	"vmicvmsession"
	"vmicvss"
) do (
    %setSvc% %%~a 3 > nul 2>nul
)

:: enable system devices
DevManView.exe /enable "Microsoft Hyper-V NT Kernel Integration VSP"
DevManView.exe /enable "Microsoft Hyper-V PCI Server"
DevManView.exe /enable "Microsoft Hyper-V Virtual Disk Server"
DevManView.exe /enable "Microsoft Hyper-V Virtual Machine Bus Provider"
DevManView.exe /enable "Microsoft Hyper-V Virtualization Infrastructure Driver"

if %ERRORLEVEL%==0 echo %date% - %time% Hyper-V and VBS enabled...>> %user_log%
goto finish

:storeD
echo This will break a majority of UWP apps and their deployment.
echo Extra note: This breaks the "about" page in immersive control panel. If you require it, enable the AppX service.
pause

:: detect if user is using a microsoft account
%PowerShell% "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" > nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" (%setSvc% wlidsvc 4) ELSE (echo "Microsoft Account detected, not disabling wlidsvc...")

:: disable the option for microsoft store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
%setSvc% InstallService 4

%setSvc% WinHttpAutoProxySvc 4
%setSvc% wlidsvc 4
%setSvc% AppXSvc 4
%setSvc% TokenBroker 4
%setSvc% LicenseManager 4
%setSvc% AppXSVC 4
%setSvc% ClipSVC 4
%setSvc% FileInfo 4
%setSvc% FileCrypt 4
if %ERRORLEVEL%==0 echo %date% - %time% Microsoft Store disabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:storeE
:: enable the option for microsoft store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: allow access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
%setSvc% InstallService 3

%setSvc% WinHttpAutoProxySvc 3
%setSvc% wlidsvc 3
%setSvc% AppXSvc 3
%setSvc% TokenBroker 3
%setSvc% LicenseManager 3
%setSvc% wuauserv 3
%setSvc% AppXSVC 3
%setSvc% ClipSVC 3
%setSvc% FileInfo 0
%setSvc% FileCrypt 1
if %ERRORLEVEL%==0 echo %date% - %time% Microsoft Store enabled...>> %user_log%
goto finish

:backD
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Background Apps disabled...>> %user_log%
goto finish

:backE
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "1" /f
if %ERRORLEVEL%==0 echo %date% - %time% Background Apps enabled...>> %user_log%
goto finish

:btD
:: Ran as admin, not as TrustedInstaller
if "%system%"=="true" (
	echo You must run this script as regular admin, not SYSTEM or TrustedInstaller.
	pause
	exit /b 1
)
%setSvc% BthAvctpSvc 4
sc stop BthAvctpSvc > nul 2>nul
DevManView.exe /disable "*Bluetooth*" /use_wildcard
attrib +h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth disabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:btE
:: Ran as admin, not as TrustedInstaller
if "%system%"=="true" (
	echo You must run this script as regular admin, not SYSTEM or TrustedInstaller.
	pause
	exit /b 1
)
%setSvc% BthAvctpSvc 2
DevManView.exe /enable "*Bluetooth*" /use_wildcard
choice /c:yn /n /m "Would you like to enable the 'Bluetooth File Transfer' Send To context menu entry? [Y/N] "
if %ERRORLEVEL%==1 attrib -h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if %ERRORLEVEL%==2 attrib +h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK"
if %ERRORLEVEL%==0 echo %date% - %time% Bluetooth enabled...>> %user_log%
goto finish

:cbdhsvcD
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "cbdhsvc" ^| find /i "cbdhsvc" ') do (
  reg add "%%a" /v "Start" /t REG_DWORD /d "4" /f
)
:: to do: check if service can be set to demand
%setSvc% DsSvc 4
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "0" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /t REG_DWORD /d "0" /f
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History disabled...>> %user_log%
goto finish

:cbdhsvcE
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /k /f "cbdhsvc" ^| find /i "cbdhsvc" ') do (
  reg add "%%a" /v "Start" /t REG_DWORD /d "3" /f
)
%setSvc% DsSvc 2
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Clipboard" /v "EnableClipboardHistory" /t REG_DWORD /d "1" /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "AllowClipboardHistory" /f > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Clipboard History enabled...>> %user_log%
goto finish

:hddD
%setSvc% SysMain 4
%setSvc% FontCache 4
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetching disabled...>> %user_log%
goto finish

:hddE
:: disable memory compression and page combining when sysmain is enabled
%PowerShell% "Disable-MMAgent -MemoryCompression -PageCombining"
%setSvc% SysMain 2
%setSvc% FontCache 2
if %ERRORLEVEL%==0 echo %date% - %time% Hard Drive Prefetch enabled...>> %user_log%
goto finish

:depD
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
echo If you get issues with some anti-cheats, please re-enable DEP.
%PowerShell% "Set-ProcessMitigation -System -Disable DEP, EmulateAtlThunks"
bcdedit /set nx AlwaysOff
if %ERRORLEVEL%==0 echo %date% - %time% Data Execution Policy disabled...>> %user_log%
goto finish

:depE
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
%PowerShell% "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks"
bcdedit /set nx Optin
:: enable cfg for valorant related processes
for %%a in (valorant valorant-win64-shipping vgtray vgc) do (
    %PowerShell% "Set-ProcessMitigation -Name %%a.exe -Enable CFG"
)
if %ERRORLEVEL%==0 echo %date% - %time% Data Execution Policy enabled...>> %user_log%
goto finish

:SearchStartDisable
IF EXIST "C:\Program Files\Open-Shell" goto existS
IF EXIST "C:\Program Files (x86)\StartIsBack" goto existS
echo It seems Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the Start Menu being removed.
pause

:existS
set /P c="This will disable SearchApp and StartMenuExperienceHost, are you sure you want to continue [Y/N]? "
if /I "%c%"=="Y" goto continSS
if /I "%c%"=="N" exit /b

:continSS
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:restartStart
taskkill /f /im StartMenuExperienceHost*
ren StartMenuExperienceHost.exe StartMenuExperienceHost.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto restartStart

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:restartSearch
taskkill /f /im SearchApp* > nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto restartSearch

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu disabled...>> %user_log%
goto finish

:SearchStartEnable
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
ren StartMenuExperienceHost.old StartMenuExperienceHost.exe

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy
ren SearchApp.old SearchApp.exe

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu enabled...>> %user_log%
goto finish

:openshellInstall
curl -L --output %WinDir%\AtlasModules\Open-Shell.exe https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.189/OpenShellSetup_4_4_189.exe
IF EXIST "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy" goto existOS
IF EXIST "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy" goto existOS
goto rmSSOS

:existOS
set /P c="It appears search and start are installed, would you like to disable them also? [Y/N]? "
if /I "%c%"=="Y" goto rmSSOS
if /I "%c%"=="N" goto skipRM

:rmSSOS
:: rename start menu
chdir /d %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy

:OSrestartStart
taskkill /f /im StartMenuExperienceHost*
ren StartMenuExperienceHost.exe StartMenuExperienceHost.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\StartMenuExperienceHost.exe" goto OSrestartStart

:: rename search
chdir /d %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy

:OSrestartSearch
taskkill /f /im SearchApp* > nul 2>nul
ren SearchApp.exe SearchApp.old

:: loop if it fails to rename the first time
if exist "%WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\SearchApp.exe" goto OSrestartSearch

:: search icon
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Search and Start Menu removed...>> %user_log%

:skipRM
:: install silently
echo]
echo Open-Shell is installing...
"Open-Shell.exe" /qn ADDLOCAL=StartMenu
curl -L https://github.com/bonzibudd/Fluent-Metro/releases/download/v1.5.3/Fluent-Metro_1.5.3.zip -o skin.zip
%unZIP% "skin.zip" "C:\Program Files\Open-Shell\Skins"
del /F /Q skin.zip > nul 2>nul
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% Open-Shell installed...>> %user_log%
goto finishNRB

:uwpD
if exist "C:\Program Files\Open-Shell" goto uwpDisableContinue
if exist "C:\Program Files (x86)\StartIsBack" goto uwpDisableContinue
echo It seems neither Open-Shell nor StartIsBack are installed. It is HIGHLY recommended to install one of these before running this due to the start menu being removed.
pause & exit /b 1

:uwpDisableContinue
echo This will remove all UWP packages that are currently installed. This will break multiple features that WILL NOT be supported while disabled.
echo A reminder of a few things this may break.
echo - Searching in file explorer
echo - Microsoft Store
echo - Xbox app
echo - Immersive control panel (Settings app)
echo - Adobe XD
echo - Start context menu
echo - Wi-Fi menu
echo - Microsoft accounts
echo Please PROCEED WITH CAUTION, you are doing this at your own risk.
pause

:: detect if user is using a microsoft account
%PowerShell% "Get-LocalUser | Select-Object Name,PrincipalSource" | findstr /C:"MicrosoftAccount" > nul 2>&1 && set MSACCOUNT=YES || set MSACCOUNT=NO
if "%MSACCOUNT%"=="NO" ( %setSvc% wlidsvc 4 ) ELSE ( echo "Microsoft Account detected, not disabling wlidsvc..." )
choice /c yn /m "Last warning, continue? [Y/N]" /n
sc stop TabletInputService
%setSvc% TabletInputService 4

:: disable the option for microsoft store in the "Open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "1" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "1" /f
%setSvc% InstallService 4

%setSvc% WinHttpAutoProxySvc 4
%setSvc% mpssvc 4
%setSvc% AppXSvc 4
%setSvc% BFE 4
%setSvc% TokenBroker 4
%setSvc% LicenseManager 4
%setSvc% ClipSVC 4

taskkill /f /im StartMenuExperienceHost* > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old
taskkill /f /im SearchApp* > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy Microsoft.Windows.Search_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old

taskkill /f /im RuntimeBroker* > nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe RuntimeBroker.exe.old
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP disabled...>> %user_log%
goto finish
pause

:uwpE

:: disable the option for microsoft store in the "open with" dialog
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "NoUseStoreOpenWith" /t REG_DWORD /d "0" /f

:: block access to microsoft store
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v "RemoveWindowsStore" /t REG_DWORD /d "0" /f
%setSvc% InstallService 3

:: enable taletinput service
%setSvc% TabletInputService 3

%setSvc% WinHttpAutoProxySvc 3
%setSvc% mpssvc 2
%setSvc% wlidsvc 3
%setSvc% AppXSvc 3
%setSvc% BFE 2
%setSvc% TokenBroker 3
%setSvc% LicenseManager 3
%setSvc% ClipSVC 3

taskkill /f /im StartMenuExperienceHost* > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy.old Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy
taskkill /f /im SearchApp* > nul 2>nul
ren %WinDir%\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy.old Microsoft.Windows.Search_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy.old Microsoft.XboxGameCallableUI_cw5n1h2txyewy
ren %WinDir%\SystemApps\Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe.old Microsoft.XboxApp_48.49.31001.0_x64__8wekyb3d8bbwe
taskkill /f /im RuntimeBroker* > nul 2>nul
ren %WinDir%\System32\RuntimeBroker.exe.old RuntimeBroker.exe
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "0" /f
taskkill /f /im explorer.exe
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% UWP enabled...>> %user_log%
goto finish

:startlayout
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>nul
%currentuser% reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy Objects\{2F5183E9-4A32-40DD-9639-F9FAF80C79F4}Machine\Software\Policies\Microsoft\Windows\Explorer" /v "StartLayoutFile" /f > nul 2>nul
%currentuser% reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "LockedStartLayout" /f > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Start Menu layout policy removed...>> %user_log%
goto finish

:sleepD
:: disable away mode policy
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 0

:: disable idle states
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 0

:: disable hybrid sleep
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Sleep States disabled...>> %user_log%
goto finishNRB

:sleepE
:: enable away mode policy
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 25dfa149-5dd1-4736-b5ab-e8a37b5b8187 1

:: enable idle states
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 abfc2519-3608-4c2a-94ea-171b0ed546ab 1

:: enable hybrid sleep
powercfg -setacvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg -setdcvalueindex 11111111-1111-1111-1111-111111111111 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 1
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Sleep States enabled...>> %user_log%
goto finishNRB

:idleD
echo THIS WILL CAUSE YOUR CPU USAGE TO *DISPLAY* AS 100% IN TASK MANAGER. ENABLE IDLE IF THIS IS AN ISSUE.
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Idle disabled...>> %user_log%
goto finishNRB

:idleE
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 0
powercfg -setactive scheme_current
if %ERRORLEVEL%==0 echo %date% - %time% Idle enabled...>> %user_log%
goto finishNRB

:powerD
:: disable drivers power savings
for %%a in (
    "AllowIdleIrpInD3"
    "D3ColdSupported"
    "DeviceSelectiveSuspended"
    "EnableIdlePowerManagement"
    "EnableSelectiveSuspend"
    "EnhancedPowerManagementEnabled"
    "IdleInWorkingState"
    "SelectiveSuspendEnabled"
    "SelectiveSuspendOn"
    "WaitWakeEnabled"
    "WdfDirectedPowerTransitionEnable"
) do (
    for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%~a" ^| findstr "HKEY"') do (
        reg add "%%b" /v "%%~a" /t REG_DWORD /d "0" /f > nul
    )
)

for %%a in (
    "DisableIdlePowerManagement"
) do (
	for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%~a" ^| findstr "HKEY"') do (
		reg add "%%b" /v "%%~a" /t REG_DWORD /d "1" /f > nul
	)
)

if "%CPU%"=="AMD" (
    for %%a in (
        "WakeEnabled"
        "WdkSelectiveSuspendEnable"
    ) do (
        for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /s /f "%%~a" ^| findstr "HKEY"') do (
            reg add "%%b" /v "%%~a" /t REG_DWORD /d "0" /f > nul
        )
    )
)


:: disable PnP power savings
%PowerShell% "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $False; $power_device.psbase.put()}}}}"

:: disable ACPI devices
DevManView.exe /disable "ACPI Processor Aggregator"
DevManView.exe /disable "Microsoft Windows Management Interface for ACPI"

:: disable power throttling
:: exists only on Intel CPUs, 6 generation or higher
:: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d "1" /f

:: set atlas - high performance power scheme
powercfg -setactive 11111111-1111-1111-1111-111111111111 > nul 2>&1

:: callable label which can be used in a post install
:: call :powerD /function
if "%~1"=="/function" exit /b

if %ERRORLEVEL%==0 echo %date% - %time% Power features disabled...>> %user_log%
goto finish

:powerE
:: enable drivers power savings
for %%a in (
    "AllowIdleIrpInD3"
    "D3ColdSupported"
    "DeviceSelectiveSuspended"
    "EnableIdlePowerManagement"
    "EnableSelectiveSuspend"
    "EnhancedPowerManagementEnabled"
    "IdleInWorkingState"
    "SelectiveSuspendEnabled"
    "SelectiveSuspendOn"
    "WaitWakeEnabled"
    "WdfDirectedPowerTransitionEnable"
) do (
    for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%~a" ^| findstr "HKEY"') do (
        reg add "%%b" /v "%%~a" /t REG_DWORD /d "1" /f > nul
    )
)

for %%a in (
    "DisableIdlePowerManagement"
) do (
	for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%~a" ^| findstr "HKEY"') do (
		reg add "%%b" /v "%%~a" /t REG_DWORD /d "0" /f > nul
	)
)

if "%CPU%"=="AMD" (
    for %%a in (
        "WakeEnabled"
        "WdkSelectiveSuspendEnable"
    ) do (
        for /f "delims=" %%b in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /s /f "%%~a" ^| findstr "HKEY"') do (
            reg add "%%b" /v "%%~a" /t REG_DWORD /d "1" /f > nul
        )
    )
)

:: enable PnP power savings
%PowerShell% "$usb_devices = @('Win32_USBController', 'Win32_USBControllerDevice', 'Win32_USBHub'); $power_device_enable = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi; foreach ($power_device in $power_device_enable){$instance_name = $power_device.InstanceName.ToUpper(); foreach ($device in $usb_devices){foreach ($hub in Get-WmiObject $device){$pnp_id = $hub.PNPDeviceID; if ($instance_name -like \"*$pnp_id*\"){$power_device.enable = $True; $power_device.psbase.put()}}}}"

:: enable ACPI devices
DevManView.exe /enable "ACPI Processor Aggregator"
DevManView.exe /enable "Microsoft Windows Management Interface for ACPI"

:: enable power throttling
:: exists only on Intel CPUs, 6 generation or higher
:: https://blogs.windows.com/windows-insider/2017/04/18/introducing-power-throttling/
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /f > nul 2>&1

:: callable label which can be used in a post install
:: call :powerE /function
if "%~1"=="/function" exit /b

choice /c:yn /n /m "Do you want to use Balanced power plan instead of Atlas power plan (Better temperatures on laptops) "
if %ERRORLEVEL%==1 goto powerB
if %ERRORLEVEL%==2 goto powerA

:powerA
:: set atlas - high performance power scheme
powercfg -setactive 11111111-1111-1111-1111-111111111111 > nul 2>&1
goto powerC

:powerB
:: set balanced power scheme - for laptops
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e > nul 2>&1
goto powerC

:powerC
if %ERRORLEVEL%==0 echo %date% - %time% Power features enabled...>> %user_log%
goto finish

:harden
:: LARGELY based on https://gist.github.com/ricardojba/ecdfe30dadbdab6c514a530bc5d51ef6
:: to do:
:: - make it extremely clear that this is not aimed to maintain performance

:: - harden process mitigations (lower compatibilty for legacy apps)
%PowerShell% "Set-ProcessMitigation -System -Enable DEP, EmulateAtlThunks, RequireInfo, BottomUp, HighEntropy, StrictHandle, CFG, StrictCFG, SuppressExports, SEHOP, AuditSEHOP, SEHOPTelemetry, ForceRelocateImages"
:: - open scripts in notepad to preview instead of executing when clicking
for %%a in (
    "batfile"
    "chmfile"
    "cmdfile"
    "htafile"
    "jsefile"
    "jsfile"
    "regfile"
    "sctfile"
    "urlfile"
    "vbefile"
    "vbsfile"
    "wscfile"
    "wsffile"
    "wsfile"
    "wshfile"
) do (
    ftype %%~a="%WinDir%\System32\notepad.exe" "%1"
)

:: - ElamDrivers?
:: - block unsigned processes running from USBS
:: - Kerebos Hardening
:: - UAC Enable

:: Firewall rules
netsh Advfirewall set allprofiles state on
%firewallBlockExe% "calc.exe" "%WinDir%\System32\calc.exe"
%firewallBlockExe% "certutil.exe" "%WinDir%\System32\certutil.exe"
%firewallBlockExe% "cmstp.exe" "%WinDir%\System32\cmstp.exe"
%firewallBlockExe% "cscript.exe" "%WinDir%\System32\cscript.exe"
%firewallBlockExe% "esentutl.exe" "%WinDir%\System32\esentutl.exe"
%firewallBlockExe% "expand.exe" "%WinDir%\System32\expand.exe"
%firewallBlockExe% "extrac32.exe" "%WinDir%\System32\extrac32.exe"
%firewallBlockExe% "findstr.exe" "%WinDir%\System32\findstr.exe"
%firewallBlockExe% "hh.exe" "%WinDir%\System32\hh.exe"
%firewallBlockExe% "makecab.exe" "%WinDir%\System32\makecab.exe"
%firewallBlockExe% "mshta.exe" "%WinDir%\System32\mshta.exe"
%firewallBlockExe% "msiexec.exe" "%WinDir%\System32\msiexec.exe"
%firewallBlockExe% "nltest.exe" "%WinDir%\System32\nltest.exe"
%firewallBlockExe% "Notepad.exe" "%WinDir%\System32\notepad.exe"
%firewallBlockExe% "pcalua.exe" "%WinDir%\System32\pcalua.exe"
%firewallBlockExe% "print.exe" "%WinDir%\System32\print.exe"
%firewallBlockExe% "regsvr32.exe" "%WinDir%\System32\regsvr32.exe"
%firewallBlockExe% "replace.exe" "%WinDir%\System32\replace.exe"
%firewallBlockExe% "rundll32.exe" "%WinDir%\System32\rundll32.exe"
%firewallBlockExe% "runscripthelper.exe" "%WinDir%\System32\runscripthelper.exe"
%firewallBlockExe% "scriptrunner.exe" "%WinDir%\System32\scriptrunner.exe"
%firewallBlockExe% "SyncAppvPublishingServer.exe" "%WinDir%\System32\SyncAppvPublishingServer.exe"
%firewallBlockExe% "wmic.exe" "%WinDir%\System32\wbem\wmic.exe"
%firewallBlockExe% "wscript.exe" "%WinDir%\System32\wscript.exe"
%firewallBlockExe% "regasm.exe" "%WinDir%\System32\regasm.exe"
%firewallBlockExe% "odbcconf.exe" "%WinDir%\System32\odbcconf.exe"

%firewallBlockExe% "regasm.exe" "%WinDir%\SysWOW64\regasm.exe"
%firewallBlockExe% "odbcconf.exe" "%WinDir%\SysWOW64\odbcconf.exe"
%firewallBlockExe% "calc.exe" "%WinDir%\SysWOW64\calc.exe"
%firewallBlockExe% "certutil.exe" "%WinDir%\SysWOW64\certutil.exe"
%firewallBlockExe% "cmstp.exe" "%WinDir%\SysWOW64\cmstp.exe"
%firewallBlockExe% "cscript.exe" "%WinDir%\SysWOW64\cscript.exe"
%firewallBlockExe% "esentutl.exe" "%WinDir%\SysWOW64\esentutl.exe"
%firewallBlockExe% "expand.exe" "%WinDir%\SysWOW64\expand.exe"
%firewallBlockExe% "extrac32.exe" "%WinDir%\SysWOW64\extrac32.exe"
%firewallBlockExe% "findstr.exe" "%WinDir%\SysWOW64\findstr.exe"
%firewallBlockExe% "hh.exe" "%WinDir%\SysWOW64\hh.exe"
%firewallBlockExe% "makecab.exe" "%WinDir%\SysWOW64\makecab.exe"
%firewallBlockExe% "mshta.exe" "%WinDir%\SysWOW64\mshta.exe"
%firewallBlockExe% "msiexec.exe" "%WinDir%\SysWOW64\msiexec.exe"
%firewallBlockExe% "nltest.exe" "%WinDir%\SysWOW64\nltest.exe"
%firewallBlockExe% "Notepad.exe" "%WinDir%\SysWOW64\notepad.exe"
%firewallBlockExe% "pcalua.exe" "%WinDir%\SysWOW64\pcalua.exe"
%firewallBlockExe% "print.exe" "%WinDir%\SysWOW64\print.exe"
%firewallBlockExe% "regsvr32.exe" "%WinDir%\SysWOW64\regsvr32.exe"
%firewallBlockExe% "replace.exe" "%WinDir%\SysWOW64\replace.exe"
%firewallBlockExe% "rpcping.exe" "%WinDir%\SysWOW64\rpcping.exe"
%firewallBlockExe% "rundll32.exe" "%WinDir%\SysWOW64\rundll32.exe"
%firewallBlockExe% "runscripthelper.exe" "%WinDir%\SysWOW64\runscripthelper.exe"
%firewallBlockExe% "scriptrunner.exe" "%WinDir%\SysWOW64\scriptrunner.exe"
%firewallBlockExe% "SyncAppvPublishingServer.exe" "%WinDir%\SysWOW64\SyncAppvPublishingServer.exe"
%firewallBlockExe% "wmic.exe" "%WinDir%\SysWOW64\wbem\wmic.exe"
%firewallBlockExe% "wscript.exe" "%WinDir%\SysWOW64\wscript.exe"

:: disable TsX to mitigate zombieload
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t REG_DWORD /d "1" /f

:: - static arp entry

:: lsass hardening
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\lsass.exe" /v "AuditLevel" /t REG_DWORD /d "8" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation" /v "AllowProtectedCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdminOutboundCreds" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "DisableRestrictedAdmin" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v "Negotiate" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v "UseLogonCredential" /t REG_DWORD /d "0" /f

:processExplorerInstall
call :netcheck

curl.exe -L# "https://live.sysinternals.com/procexp.exe" -o "%WinDir%\AtlasModules\Apps\procexp.exe"
if %ERRORLEVEL%==1 (
	echo Failed to download Process Explorer^^!
	pause
	exit /b 1
)

:: Create the shortcut
%PowerShell% "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut("""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Process Explorer.lnk"""); $Shortcut.TargetPath = """$env:WinDir\AtlasModules\Apps\procexp.exe"""; $Shortcut.Save()"
if %ERRORLEVEL%==1 (
	echo Process Explorer shortcut could not be created in the start menu^^!
)

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /t REG_SZ /d "%WinDir%\AtlasModules\Apps\procexp.exe" /f > nul
%setSvc% pcw 4
goto finishNRB

:processExplorerUninstall
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe" /v "Debugger" /f > nul 2>nul
%setSvc% pcw 0
goto finish

:xboxU
set /P c="This is IRREVERSIBLE (A reinstall is required to restore these components), continue? [Y/N]"
if /I "%c%"=="N" exit /b
if /I "%c%"=="Y" goto :xboxConfirm
exit

:xboxConfirm
echo Removing via PowerShell...
NSudo.exe -U:C -ShowWindowMode:Hide -Wait %PowerShell% "Get-AppxPackage *Xbox* | Remove-AppxPackage" > nul 2>nul
if %ERRORLEVEL%==0 echo %date% - %time% Xbox related apps removed..>> %user_log%
goto finishNRB

:xboxD
echo Disabling services...
%setSvc% XblAuthManager 4
%setSvc% XblGameSave 4
%setSvc% XboxGipSvc 4
%setSvc% XboxNetApiSvc 4
%setSvc% BcastDVRUserService 4
if %ERRORLEVEL%==0 echo %date% - %time% Xbox related services disabled...>> %user_log%
goto finishNRB

:xboxE
echo Enabling services...
%setSvc% XblAuthManager 3
%setSvc% XblGameSave 3
%setSvc% XboxGipSvc 3
%setSvc% XboxNetApiSvc 3
%setSvc% BcastDVRUserService 3
if %ERRORLEVEL%==0 echo %date% - %time% Xbox related services enabled...>> %user_log%
goto finishNRB

:vcreR
echo Uninstalling Visual C++ Redistributables...
vcredist.exe /aiR
echo Finished uninstalling^^!
echo]
echo Opening Visual C++ Redistributables installer, simply click next.
vcredist.exe
echo Installation finished or cancelled.
if %ERRORLEVEL%==0 echo %date% - %time% Visual C++ Redistributables reinstalled...>> %user_log%
goto finishNRB

:uacD
echo Disabling UAC breaks fullscreen on certain UWP applications, one of them being Minecraft Windows 10 Edition.
echo It may also break drag and dropping between certain applications.
echo It is also less secure to disable UAC, as every application you run has complete access to your computer.
echo]
echo With UAC disabled, everything runs as admin, and you can not change that without enabling UAC.
echo]
choice /c:yn /n /m "Do you want to continue? [Y/N] "
if %ERRORLEVEL%==1 goto uacDconfirm
if %ERRORLEVEL%==2 exit /b

:uacDconfirm
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "0" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "0" /f > nul
:: lock UserAccountControlSettings.exe - users can enable UAC from there without luafv and appinfo enabled, which breaks UAC completely and causes issues
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /t REG_SZ /d "atlas-config.cmd /uacSettings /skipAdminCheck" /f > nul
%setSvc% luafv 4
%setSvc% Appinfo 4
if %ERRORLEVEL%==0 echo %date% - %time% UAC disabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:uacE
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "PromptOnSecureDesktop" /t REG_DWORD /d "1" /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d "5" /f > nul
:: unlock UserAccountControlSettings.exe
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\UserAccountControlSettings.exe" /v "Debugger" /f > nul 2>nul
%setSvc% luafv 2
%setSvc% Appinfo 3
if %ERRORLEVEL%==0 echo %date% - %time% UAC enabled...>> %user_log%
echo Note: The regular Windows UAC settings have now been unlocked, as this script enabled the required services for UAC.
echo]
goto finish

:uacSettings
mode con: cols=46 lines=14
chcp 65001 > nul
echo]
echo [32m                 Enabling UAC
echo   ──────────────────────────────────────────[0m
echo   Atlas disables some services that are
echo   needed for UAC to work, and enabling UAC
echo   through the typical UAC settings will
echo   cause issues.
echo]
echo   You [1mneed to enable UAC using the Atlas
echo   script[0m to unlock the typical UAC
echo   configuration panel.
echo]
echo         [1m[33mPress any key to enable UAC...      [?25l
pause > nul
NSudo.exe -U:T -P:E -UseCurrentConsole -Wait atlas-config.cmd /uacE
exit

:firewallD
%setSvc% mpssvc 4
%setSvc% BFE 4
if %ERRORLEVEL%==0 echo %date% - %time% Firewall disabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:firewallE
%setSvc% mpssvc 2
%setSvc% BFE 2
if %ERRORLEVEL%==0 echo %date% - %time% Firewall enabled...>> %user_log%
goto finish

:aniD
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f
if %ERRORLEVEL%==0 echo %date% - %time% Animations disabled...>> %user_log%
goto finish

:aniE
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f > nul 2>nul
%currentuser% reg delete "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f > nul 2>nul
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f
%currentuser% reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f
if %ERRORLEVEL%==0 echo %date% - %time% Animations enabled...>> %user_log%
goto finish

:workstationD
%setSvc% rdbss 4
%setSvc% KSecPkg 4
%setSvc% mrxsmb20 4
%setSvc% mrxsmb 4
%setSvc% srv2 4
%setSvc% LanmanWorkstation 4
DISM /Online /Disable-Feature /FeatureName:SmbDirect /NoRestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation disabled...>> %user_log%
goto finish

:workstationE
%setSvc% rdbss 3
%setSvc% KSecPkg 0
%setSvc% mrxsmb20 3
%setSvc% mrxsmb 3
%setSvc% srv2 3
%setSvc% LanmanWorkstation 2
DISM /Online /Enable-Feature /FeatureName:SmbDirect /NoRestart
if %ERRORLEVEL%==0 echo %date% - %time% Workstation enabled...>> %user_log%
if "%~1"=="int" goto :EOF
goto finish

:printD
:: remove print from context menu
reg add "HKCR\SystemFileAssociations\image\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f
for %%a in (
    "batfile"
    "cmdfile"
    "docxfile"
    "fonfile"
    "htmlfile"
    "inffile"
    "inifile"
    "JSEFile"
    "otffile"
    "pfmfile"
    "regfile"
    "rtffile"
    "ttcfile"
    "ttffile"
    "txtfile"
    "VBEFile"
    "VBSFile"
    "WSFFile"
) do (
    reg add "HKCR\%%~a\shell\print" /v "ProgrammaticAccessOnly" /t REG_SZ /d "" /f
)

%setSvc% Spooler 4
if %ERRORLEVEL%==0 echo %date% - %time% Printing disabled...>> %user_log%
goto finish

:printE
echo You may be vulnerable to Print Nightmare Exploits while printing is enabled.
set /P c="Would you like to add Group Policies to protect against them? [Y/N] "
if /I "%c%"=="Y" goto nightmareGPO
if /I "%c%"=="N" goto printECont
goto nightmareGPO

:nightmareGPO
echo The spooler will not accept client connections nor allow users to share printers.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "RegisterSpoolerRemoteRpcEndPoint" /t REG_DWORD /d "2" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "RestrictDriverInstallationToAdministrators" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint" /v "Restricted" /t REG_DWORD /d "1" /f

:: prevent print drivers over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableWebPnPDownload" /t REG_DWORD /d "1" /f

:: disable printing over HTTP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers" /v "DisableHTTPPrinting" /t REG_DWORD /d "1" /f

:printECont
:: add print to context menu
reg delete "HKCR\SystemFileAssociations\image\shell\print" /v "ProgrammaticAccessOnly" /f
for %%a in (
    "batfile"
    "cmdfile"
    "docxfile"
    "fonfile"
    "htmlfile"
    "inffile"
    "inifile"
    "JSEFile"
    "otffile"
    "pfmfile"
    "regfile"
    "rtffile"
    "ttcfile"
    "ttffile"
    "txtfile"
    "VBEFile"
    "VBSFile"
    "WSFFile"
) do (
    reg delete "HKCR\%%~a\shell\print" /v "ProgrammaticAccessOnly" /f
)

%setSvc% Spooler 2
if %ERRORLEVEL%==0 echo %date% - %time% Printing enabled...>> %user_log%
goto finish

:netWinDefault
netsh int ip reset
netsh winsock reset
for /f "tokens=3* delims=: " %%a in ('pnputil /enum-devices /class Net /connected ^| findstr "Device Description:"') do (
	DevManView.exe /uninstall "%%a %%i"
)
pnputil /scan-devices
if %ERRORLEVEL%==0 echo %date% - %time% Network setting reset to Windows' default...>> %user_log%
goto finish

:netAtlasDefault
:: disable nagle's algorithm
:: https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%a in ('wmic path win32_networkadapter get GUID ^| findstr "{"') do (
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f
    reg add "HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\%%a" /v "TCPNoDelay" /t REG_DWORD /d "1" /f
)

:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f
:: https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d "1" /f
:: reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t REG_DWORD /d "1" /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t REG_DWORD /d "0" /f

:: set default power saving mode for all network cards to disabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d "24" /f

:: configure nic settings
:: modified by Xyueta
for /f %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class" /v "*WakeOnMagicPacket" /s ^| findstr  "HKEY"') do (
    for %%i in (
        "*EEE"
        "*FlowControl"
        "*LsoV2IPv4"
        "*LsoV2IPv6"
        "*SelectiveSuspend"
        "*WakeOnMagicPacket"
        "*WakeOnPattern"
        "AdvancedEEE"
        "AutoDisableGigabit"
        "AutoPowerSaveModeEnabled"
        "EnableConnectedPowerGating"
        "EnableDynamicPowerGating"
        "EnableGreenEthernet"
        "EnableModernStandby"
        "EnablePME"
        "EnablePowerManagement"
        "EnableSavePowerNow"
        "GigaLite"
        "PowerSavingMode"
        "ReduceSpeedOnPowerDown"
        "ULPMode"
        "WakeOnLink"
        "WakeOnSlot"
        "WakeUpModeCap"
    ) do (
        for /f %%j in ('reg query "%%a" /v "%%~i" ^| findstr "HKEY"') do (
            reg add "%%j" /v "%%~i" /t REG_SZ /d "0" /f
        )
    )
)

:: configure netsh settings
netsh int tcp set heuristics disabled
netsh int tcp set supplemental Internet congestionprovider=ctcp
netsh int tcp set global rsc=disabled
for /f "tokens=1" %%a in ('netsh int ip show interfaces ^| findstr [0-9]') do (
	netsh int ip set interface %%a routerdiscovery=disabled store=persistent
)
if %ERRORLEVEL%==0 echo %date% - %time% Network settings reset to Atlas default...>> %user_log%
goto finish

:vpnD
DevManView.exe /disable "WAN Miniport (IKEv2)"
DevManView.exe /disable "WAN Miniport (IP)"
DevManView.exe /disable "WAN Miniport (IPv6)"
DevManView.exe /disable "WAN Miniport (L2TP)"
DevManView.exe /disable "WAN Miniport (Network Monitor)"
DevManView.exe /disable "WAN Miniport (PPPOE)"
DevManView.exe /disable "WAN Miniport (PPTP)"
DevManView.exe /disable "WAN Miniport (SSTP)"
DevManView.exe /disable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /disable "Microsoft RRAS Root Enumerator"
%setSvc% IKEEXT 4
%setSvc% WinHttpAutoProxySvc 4
%setSvc% RasMan 4
%setSvc% SstpSvc 4
%setSvc% iphlpsvc 4
%setSvc% NdisVirtualBus 4
%setSvc% Eaphost 4
if %ERRORLEVEL%==0 echo %date% - %time% VPN support disabled...>> %user_log%
goto finish

:vpnE
DevManView.exe /enable "WAN Miniport (IKEv2)"
DevManView.exe /enable "WAN Miniport (IP)"
DevManView.exe /enable "WAN Miniport (IPv6)"
DevManView.exe /enable "WAN Miniport (L2TP)"
DevManView.exe /enable "WAN Miniport (Network Monitor)"
DevManView.exe /enable "WAN Miniport (PPPOE)"
DevManView.exe /enable "WAN Miniport (PPTP)"
DevManView.exe /enable "WAN Miniport (SSTP)"
DevManView.exe /enable "NDIS Virtual Network Adapter Enumerator"
DevManView.exe /enable "Microsoft RRAS Root Enumerator"
%setSvc% IKEEXT 3
%setSvc% BFE 2
%setSvc% WinHttpAutoProxySvc 3
%setSvc% RasMan 3
%setSvc% SstpSvc 3
%setSvc% iphlpsvc 3
%setSvc% NdisVirtualBus 3
%setSvc% Eaphost 3
if %ERRORLEVEL%==0 echo %date% - %time% VPN support enabled...>> %user_log%
goto finish

:wmpD
DISM /Online /Disable-Feature /FeatureName:WindowsMediaPlayer /NoRestart
goto finish

:wmpE
DISM /Online /Enable-Feature /FeatureName:WindowsMediaPlayer /NoRestart
goto finish

:ieD
DISM /Online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /NoRestart
goto finish

:ieE
DISM /Online Enable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /NoRestart
goto finish

:eventlogD
echo This may break some features:
echo - CapFrameX
echo - Network menu/icon
echo If you experience random issues, please enable Event Log again.
%setSvc% EventLog 4
if %ERRORLEVEL%==0 echo %date% - %time% Event Log disabled...>> %user_log%
goto finish

:eventlogE
%setSvc% EventLog 2
if %ERRORLEVEL%==0 echo %date% - %time% Event Log enabled...>> %user_log%
goto finish

:scheduleD
echo Disabling Task Scheduler will break some features:
echo - MSI Afterburner startup/updates
echo - UWP typing (e.g. Search bar)
%setSvc% Schedule 4
if %ERRORLEVEL%==0 echo %date% - %time% Task Scheduler disabled...>> %user_log%
echo If you experience random issues, please enable Task Scheduler again.
goto finish

:scheduleE
%setSvc% Schedule 2
if %ERRORLEVEL%==0 echo %date% - %time% Task Scheduler enabled...>> %user_log%
goto finish

:staticIP
call :netcheck
set /P DNS1="Set primary DNS Server (e.g. 1.1.1.1): "
set /P DNS2="Set alternate DNS Server (e.g. 1.0.0.1): "
for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set DeviceName=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr "IP Address:"') do set LocalIP=%%a
for /f "tokens=3" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr "Default Gateway:"') do set DHCPGateway=%%a
for /f "tokens=2 delims=()" %%a in ('netsh int ip show config name^="%DeviceName%" ^| findstr /r "(.*)"') do for %%i in (%%a) do set DHCPSubnetMask=%%i

:: set static ip
netsh int ipv4 set address name="%DeviceName%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway% > nul 2>&1
netsh int ipv4 set dns name="%DeviceName%" static %DNS1% primary > nul 2>&1
netsh int ipv4 add dns name="%DeviceName%" %DNS2% index=2 > nul 2>&1

:: display details about the connection
echo Interface: %DeviceName%
echo Private IP: %LocalIP%
echo Subnet Mask: %DHCPSubnetMask%
echo Gateway: %DHCPGateway%
echo Primary DNS: %DNS1%
echo Alternate DNS: %DNS2%
echo.
echo If this information appears to be incorrect or is blank, please report it on Discord or Github.

choice /c:yn /n /m "Do you want to disable static ip services (break internet icon)? [Y/N] "
if %ERRORLEVEL%==1 goto staticIPS
if %ERRORLEVEL%==2 goto staticIPC
goto staticIPS

:staticIPS
%setSvc% Dhcp 4
%setSvc% netprofm 4
%setSvc% NlaSvc 4

:staticIPC
echo %date% - %time% Static IP set! (%DeviceName%) (%LocalIP%) (%DHCPSubnetMask%) (%DHCPGateway%) (%DNS1%) (%DNS2%) >> %user_log%
goto finish

:revertstaticIP
for /f "tokens=4" %%a in ('netsh int show interface ^| find "Connected"') do set DeviceName=%%a

:: set dhcp instead of static ip
netsh int ipv4 set address name="%DeviceName%" dhcp
netsh int ipv4 set dnsservers name="%DeviceName%" dhcp
netsh int ipv4 show config "%DeviceName%"

:: enable static ip services (fixes internet icon)
%setSvc% Dhcp 2
%setSvc% netprofm 3
%setSvc% nlasvc 2

echo %date% - %time% Static IP reverted! >> %user_log%
goto finish

:DSCPauto
for /f "tokens=* delims=\" %%i in ('filepicker.exe exe') do (
    if "%%i"=="cancelled by user" exit /b 1
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Application Name" /t REG_SZ /d "%%~ni%%~xi" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Version" /t REG_SZ /d "1.0" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Protocol" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local Port" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Local IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote Port" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Remote IP Prefix Length" /t REG_SZ /d "*" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "DSCP Value" /t REG_SZ /d "46" /f
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\QoS\%%~ni%%~xi" /v "Throttle Rate" /t REG_SZ /d "-1" /f
)
goto finish

:NVPstate
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /b 1
)
echo This will force P0 on your NVIDIA card AT ALL TIMES, it will always run at full power.
echo It is not recommended if you leave your computer on while idle, have bad cooling or use a laptop.
pause

for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%a" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f
)
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Dynamic P-States disabled...>> %user_log%
goto finish

:revertNVPState
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg delete "%%a" /v "DisableDynamicPstate" /f > nul 2>nul
)
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Dynamic P-States enabled...>> %user_log%
goto finish

:hdcpD
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/blob/master/CONTENT/RESEARCH/WINDRIVERS/README.md#q-are-there-any-configuration-options-that-allow-you-to-disable-hdcp-when-using-nvidia-based-graphics-cards
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /b 1
)

for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%a" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f
)

if %ERRORLEVEL%==0 echo %date% - %time% HDCP disabled...>> %user_log%
goto finish

:hdcpE
:: credits to timecard
:: https://github.com/djdallmann/GamingPCSetup/blob/master/CONTENT/RESEARCH/WINDRIVERS/README.md#q-are-there-any-configuration-options-that-allow-you-to-disable-hdcp-when-using-nvidia-based-graphics-cards
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo You do not have NVIDIA GPU drivers installed.
    pause
    exit /b 1
)

for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HK"') do (
    reg add "%%a" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "0" /f
)

if %ERRORLEVEL%==0 echo %date% - %time% HDCP enabled...>> %user_log%
goto finish

:nvcontainerD
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

echo Disabling the 'NVIDIA Display Container LS' service will stop the NVIDIA Control Panel from working.
echo It will most likely break other NVIDIA driver features as well.
echo These scripts are aimed at users that have a stripped driver, and people that barely touch the NVIDIA Control Panel.
echo]
echo You can enable the NVIDIA Control Panel and the service again by running the enable script.
echo Additionally, you can add a context menu to the desktop with another script in the Atlas folder.
echo]
echo Read README.txt for more info.
pause

%setSvc% NVDisplay.ContainerLocalSystem 4 > nul
sc stop NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS disabled...>> %user_log%
goto finishNRB

:nvcontainerE
:: check if the service exists
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)

%setSvc% NVDisplay.ContainerLocalSystem 2 > nul
sc start NVDisplay.ContainerLocalSystem > nul
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS enabled...>> %user_log%
goto finishNRB

:nvcontainerCME
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)
echo Explorer will be restarted to ensure that the context menu works.
pause

reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Icon" /t REG_SZ /d "NVIDIA.ico,0" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "MUIVerb" /t REG_SZ /d "NVIDIA Container" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "Position" /t REG_SZ /d "Bottom" /f
reg add "HKCR\DesktopBackground\Shell\NVIDIAContainer" /v "SubCommands" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001" /v "MUIVerb" /t REG_SZ /d "Enable NVIDIA Display Container LS" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer001\command" /ve /t REG_SZ /d "NSudo.exe -U:T -P:E -UseCurrentConsole -Wait atlas-config.cmd /nvcontainerE" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "HasLUAShield" /t REG_SZ /d "" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002" /v "MUIVerb" /t REG_SZ /d "Disable NVIDIA Display Container LS" /f
reg add "HKCR\DesktopBackground\shell\NVIDIAContainer\shell\NVIDIAContainer002\command" /ve /t REG_SZ /d "NSudo.exe -U:T -P:E -UseCurrentConsole -Wait atlas-config.cmd /nvcontainerD" /f
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS context menu enabled...>> %user_log%
goto finishNRB

:nvcontainerCMD
:: cm = context menu
sc query NVDisplay.ContainerLocalSystem > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The NVIDIA Display Container LS service does not exist, you can not continue.
	echo You may not have NVIDIA drivers installed.
    pause
    exit /b 1
)
reg query "HKCR\DesktopBackground\shell\NVIDIAContainer" > nul 2>&1
if %ERRORLEVEL%==1 (
    echo The context menu does not exist, you can not continue.
    pause
    exit /b 1
)

echo Explorer will be restarted to ensure that the context menu is removed.
pause

reg delete "HKCR\DesktopBackground\Shell\NVIDIAContainer" /f > nul 2>nul

:: delete icon exe
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
taskkill /f /im explorer.exe > nul 2>&1
NSudo.exe -U:C explorer.exe
if %ERRORLEVEL%==0 echo %date% - %time% NVIDIA Display Container LS context menu disabled...>> %user_log%
goto finishNRB

:networksharingD
call :workstationD "int"
echo %date% - %time% Workstation disbled as Network Sharing dependency...>> %user_log%
%setSvc% NlaSvc 4
%setSvc% lmhosts 4
%setSvc% netman 4
echo %date% - %time% Network Sharing disabled...>> %user_log%
goto finish

:networksharingE
call :workstationE "int"
echo %date% - %time% Workstation enabled as Network Sharing dependency...>> %user_log%
%setSvc% eventlog 2
echo %date% - %time% EventLog enabled as Network Sharing dependency...>> %user_log%
%setSvc% NlaSvc 2
%setSvc% lmhosts 3
%setSvc% netman 3
echo %date% - %time% Network Sharing enabled...>> %user_log%
echo To complete, enable Network Sharing in control panel.
goto finish

:diagD
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v "Start" /t REG_DWORD /d "0" /f
%setSvc% DPS 4
%setSvc% WdiServiceHost 4
%setSvc% WdiSystemHost 4
echo %date% - %time% Diagnotics disabled...>> %user_log%
goto finish

:diagE
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v "Start" /t REG_DWORD /d "1" /f
%setSvc% DPS 2
%setSvc% WdiServiceHost 3
%setSvc% WdiSystemHost 3
echo %date% - %time% Diagnotics enabled...>> %user_log%
goto finish

:safeE
bcdedit /deletevalue {current} safeboot
bcdedit /deletevalue {current} safebootalternateshell
echo %date% - %time% Exit safe mode...>> %user_log%
goto finish

:safeC
bcdedit /set {current} safeboot minimal
bcdedit /set {current} safebootalternateshell yes
echo %date% - %time% Safe mode with command prompt enabled...>> %user_log%
goto finish

:safeN
bcdedit /set {current} safeboot network
echo %date% - %time% Safe mode with networking enabled...>> %user_log%
goto finish

:safe
bcdedit /set {current} safeboot minimal
echo %date% - %time% Safe mode enabled...>> %user_log%
goto finish

:sendToDebloat
:: Ran as admin, not TrustedInstaller
if "%system%"=="true" (
	echo You must run this script as regular admin, not SYSTEM or TrustedInstaller.
	pause
	exit /b 1
)

for %%a in (
	"bluetooth"
	"zipfolder"
	"mail"
	"documents"
	"removableDrives"
) do (
	set "%%~a=false"
)

for /f "usebackq tokens=*" %%a in (
	`multichoice.exe "Send To Debloat" "Tick the default 'Send To' context menu items that you want to disable here (un-checked items are enabled)" "Bluetooth device;Compressed (zipped) folder;Desktop (create shortcut);Mail recipient;Documents;Removable Drives"`
) do (set items=%%a)
for %%a in ("%items:;=" "%") do (
	if "%%~a"=="Bluetooth device" (set bluetooth=true)
	if "%%~a"=="Compressed (zipped) folder" (set zipfolder=true)
	if "%%~a"=="Desktop (create shortcut)" (set desktop=true)
	if "%%~a"=="Mail recipient" (set mail=true)
	if "%%~a"=="Documents" (set documents=true)
	if "%%~a"=="Removable Drives" (set removableDrives=true)
)
if "%bluetooth%"=="true" (attrib +h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK") else (attrib -h "%appdata%\Microsoft\Windows\SendTo\Bluetooth File Transfer.LNK")
if "%zipfolder%"=="true" (attrib +h "%appdata%\Microsoft\Windows\SendTo\Compressed (zipped) Folder.ZFSendToTarget") else (attrib -h "%appdata%\Microsoft\Windows\SendTo\Compressed (zipped) Folder.ZFSendToTarget")
if "%desktop%"=="true" (attrib +h "%appdata%\Microsoft\Windows\SendTo\Desktop (create shortcut).DeskLink") else (attrib -h "%appdata%\Microsoft\Windows\SendTo\Desktop (create shortcut).DeskLink")
if "%mail%"=="true" (attrib +h "%appdata%\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail") else (attrib -h "%appdata%\Microsoft\Windows\SendTo\Mail Recipient.MAPIMail")
if "%documents%"=="true" (attrib +h "%appdata%\Microsoft\Windows\SendTo\Documents.mydocs") else (attrib -h "%appdata%\Microsoft\Windows\SendTo\Documents.mydocs")
if "%removableDrives%"=="true" (
	reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDrivesInSendToMenu" /t REG_DWORD /d "1" /f > nul
) else (
	reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDrivesInSendToMenu" /f > nul 2>nul
)
for /f "usebackq tokens=*" %%a in (`multichoice "Explorer Restart" "You need to restart File Explorer to fully apply the changes." "Restart now"`) do (
	if "%%a"=="Restart now" (
		taskkill /f /im explorer.exe > nul
		start "" "explorer.exe"
	)
)

goto finishNRB

:mitD
:: disable spectre and meltdown
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "3" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f

:: disable fault tolerant heap
:: https://docs.microsoft.com/en-us/windows/win32/win7appqual/fault-tolerant-heap
:: doc listed as only affected in windows 7, is also in 7+
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v "Enabled" /t REG_DWORD /d "0" /f

:: exists in ntoskrnl strings, keep for now
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "1" /f

:: find correct mitigation values for different Windows versions - AMIT
:: initialize bit mask in registry by disabling a random mitigation
%PowerShell% "Set-ProcessMitigation -System -Disable CFG"

:: get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set mitigation_mask=%%a
)

:: set all bits to 2 (disable all mitigations)
for /l %%a in (0,1,9) do (
    set mitigation_mask=!mitigation_mask:%%a=2!
)

:: apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f

:: disable virtualization-based protection of code integrity
:: https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d "0" /f

:: disable data execution prevention
:: may need to enable for faceit, valorant and other anti-cheats
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOff

:: disable file system mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "0" /f

:: callable label which can be used in a post install
:: call :mitD /function
if "%~1"=="/function" exit /b

echo %date% - %time% Mitigations disabled...>> %user_log%
echo]
goto finish

:mitE
:: fully enable spectre variant 2 and meltdown mitigations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d "3" /f
if "%CPU%"=="INTEL" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "0" /f
)
if "%CPU%"=="AMD" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d "64" /f
)

:: enable for hyper-v
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" /v "MinVmVersionForCpuBasedMitigations" /t REG_SZ /d "1.0" /f

:: enable structured exception handling overwrite protection (SEHOP)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t REG_DWORD /d "0" /f

:: enable data execution prevention
:: https://docs.microsoft.com/en-us/windows/win32/memory/data-execution-prevention
bcdedit /set nx AlwaysOn

:: enable all other kernel mitigations
:: find correct mitigation values for different Windows versions - AMIT
:: initialize bit mask in registry by enabling a random mitigation
%PowerShell% "Set-ProcessMitigation -System -Enable CFG"

:: get current bit mask
for /f "tokens=3 skip=2" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions"') do (
    set mitigation_mask=%%a
)

:: set all bits to 1 (enable all mitigations)
for /l %%a in (0,1,9) do (
    set mitigation_mask=!mitigation_mask:%%a=1!
)

:: apply mask to kernel
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationAuditOptions" /t REG_BINARY /d "%mitigation_mask%" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t REG_BINARY /d "%mitigation_mask%" /f

:: enable file system mitigations (default)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t REG_DWORD /d "1" /f

:: callable label which can be used in a post install
:: call :mitE /function
if "%~1"=="/function" exit /b
echo %date% - %time% Mitigations enabled...>> %user_log%
echo]
goto finish

:::::::::::::::::::::
:: Batch Functions ::
:::::::::::::::::::::

:netcheck
ping -n 1 -4 1.1.1.1 | find "time=" > nul 2>nul
if %ERRORLEVEL%==1 (
	echo You must have an internet connection to use this script.
	pause
	exit /b 1
)
goto :EOF

:FDel <location>
:: with NSudo, you should not need things like icacls/takeown
if exist "%~1" del /F /Q "%~1"
goto :EOF

:unZIP <FilePath> <DestinationPath>
%PowerShell% "Expand-Archive -Path '%~1' -DestinationPath '%~2'"
goto :EOF

:setSvc
:: example: %setSvc% AppInfo 4
:: last argument is the startup type: 0, 1, 2, 3, 4
if [%~1]==[] (echo You need to run this with a service/driver to disable. & exit /b 1)
if [%~2]==[] (echo You need to run this with an argument ^(1-5^) to configure the service's startup. & exit /b 1)
if %~2 LSS 0 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
if %~2 GTR 5 (echo Invalid start value ^(%~2^) for %~1. & exit /b 1)
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" > nul 2>&1 || (echo The specified service/driver ^(%~1^) is not found. & exit /b 1)
if "%system%"=="false" (
	if not "%setSvcWarning%"=="false" (
		echo WARNING: Not running as System, could fail modifying some services/drivers with an access denied error.
	)
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v "Start" /t REG_DWORD /d "%~2" /f > nul || (
	if "%system%"=="false" (
		echo Failed to set service %~1 with start value %~2^^! Not running as System, access denied?
		exit /b 1
	) else (
		echo Failed to set service %~1 with start value %~2^^! Unknown error.
		exit /b 1
	)
)
exit /b

:firewallBlockExe
:: usage: %fireBlockExe% "[NAME]" "[EXE]"
:: example: %fireBlockExe% "Calculator" "%WinDir%\System32\calc.exe"
:: have both in quotes

:: get rid of any old rules (prevents duplicates)
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=in > nul 2>&1
netsh advfirewall firewall delete rule name="Block %~1" protocol=any dir=out > nul 2>&1
netsh advfirewall firewall add rule name="Block %~1" program=%2 protocol=any dir=in enable=yes action=block profile=any > nul
netsh advfirewall firewall add rule name="Block %~1" program=%2 protocol=any dir=out enable=yes action=block profile=any > nul
exit /b

:permFAIL
	echo Permission grants failed. Please try again by launching the script through the respected scripts, which will give it the correct permissions.
	pause & exit /b 1
:finish
	echo Finished, please reboot for changes to apply.
	pause & exit /b
:finishNRB
	echo Finished, changes have been applied.
	pause & exit /b

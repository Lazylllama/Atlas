# Atlas source

Here you can find sources files used to build Atlas:
- NTLite preset (1803.xml/20H2.xml/22H2.xml)
- Registry files
- Scripts
- Others, such as programs needed to interface with Windows easier

## Building from source

There are plenty of reasons to build Atlas from source such as:
- To contribute to the project.
- To personalize the build, by removing/restoring components you may/may not need.
- It is safer to build from source, as you can ensure that the build is done with the same version of the source code.

### Prerequisites

- [NTLite](https://ntlite.com) with a "Home" or higher license. 
  - You can use Free license, but usage of NTLite will be limited.
- An archive extractor (e.g. 7-Zip)
- A local copy of the Atlas repository.
- A default Windows build from Microsoft. ([1](https://github.com/pbatard/Fido/releases) [2](https://www.heidoc.net/joomla/technology-science/microsoft/67-microsoft-windows-iso-download-tool) [3](https://uupdump.net))

### Getting started

1. Extract the Windows build using the previously mentioned archive extractor.
2. Open NTLite and add the extracted folder to NTLite's source list.
3. Import the Atlas preset from the repo and apply it.
4. Integrate drivers and registry files if needed.
5. Copy the following folders/files to the NTLite mount directory (%temp%\NLTmpMnt)
  - Web >> %temp%\NLTmpMnt\Windows\Web (delete the existing folder first)
  - layout.xml >> %temp%\NLTmpMnt\Windows\layout.xml
  - AtlasModules >> %temp%\NLTmpMnt\Windows\AtlasModules
  - User Account Pictures >> %temp%\NLTmpMnt\ProgramData\Microsoft\User Account Pictures (delete the existing folder first!=)
  - Desktop/Atlas >> %temp%\NLTmpMnt\Users\Default\Desktop\Atlas
  - Atlas.cmd >> %temp%\NLTmpMnt\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Atlas.cmd

6. Make any changes you want to NTLite's components, settings, services etc.
7. Go to the "Apply" tab and click Process
8. Done!

## Contributing

### Creating scripts

First of all, you will need to [add a flag/argument](https://github.com/Atlas-OS/Atlas/blob/main/src/AtlasModules/atlas-config.cmd#L69) to `atlas-config.cmd`. This will allow it to be called from a seperate script on the desktop.

For this we will use the [Bluetooth disable script](https://github.com/Atlas-OS/Atlas/blob/main/src/AtlasModules/atlas-config.cmd#L1376) as an example. 

```bat
:: the :btD label is part of allowing the script to be called when a specific flag is used, as mentioned previously
:btD
:: now the script disables the services required for bluetooth
sc config BthAvctpSvc start=disabled
sc stop BthAvctpSvc > nul 2>&1

:: once finished it is redirected to a generic message to reboot for changes, then exits at the end of the file
:: if the script does not need to reboot, use "goto finishNRB"
goto finish
```
Now we have the script available in `atlas-config`, let us make a desktop script to easily launch it.

```bat
@echo off
:: this launches the script with TrustedInstaller permissions
:: remove these comments when contributing
NSudo.exe -U:T -P:E -UseCurrentConsole -Wait %WinDir%\AtlasModules\atlas-config.cmd /btd
```

This file will go in the "Atlas" Folder

### Code formatting

To keep code "unified" we have a few guidelines. This way it is easier to understand when contributing.

#### Labels

When creating [labels](http://elearning.algonquincollege.com/coursemat/viljoed/gis8746/concepts/dosbatch/advanced/labels.htm), we prefer the use of camelCase:

```bat
:btD
echo this stands for "Bluetooth disable"
```

## Compatibility

A simple sheet to track what components break what, if not listed on NTLite. This is **not** completed.

| Component          | Affected Feature                       | Version Tested | Notes                                                                     |
| ------------------ | ------------------------------------   | -------------- | ------------------------------------------------------------------------- |
| Mobile PC Sensors  | Xbox app                               | 20H2           | The old Xbox app can function without it, but once updated it will crash. |
| Active Directory   | Store sign-in and Organization sign-in | 20H2           |                                                                           |
| Photo Codec 32-bit | Photos app                             | 20H2           | Test again                                                                |

## Resources

- [VCRedist](https://github.com/abbodi1406/vcredist)
- [DevManView](https://www.nirsoft.net/utils/device_manager_view.html)
- [NSudo](https://github.com/m2team/NSudo)

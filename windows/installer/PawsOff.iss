; Inno Setup script for PawsOff-Windows-Setup.exe.
; Built by CI: ISCC /DAppVersion=<version> /DAppExe=<path to PawsOff.exe> windows\installer\PawsOff.iss
; Installs per user (no admin prompt) into %LOCALAPPDATA%\Programs\Paws Off.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef AppExe
  #define AppExe "..\..\out\PawsOff.exe"
#endif

[Setup]
AppId={{7B3C5E2A-4F1D-4C8B-9E6A-2D5F8A1C3B90}
AppName=Paws Off
AppVersion={#AppVersion}
AppVerName=Paws Off {#AppVersion}
AppPublisher=Zaid
AppPublisherURL=https://github.com/EnigmaticZee/PawsOff
AppSupportURL=https://github.com/EnigmaticZee/PawsOff/issues
AppUpdatesURL=https://github.com/EnigmaticZee/PawsOff/releases
AppCopyright=Made by Zaid
VersionInfoVersion={#AppVersion}
VersionInfoProductName=Paws Off
VersionInfoDescription=Paws Off Setup

PrivilegesRequired=lowest
DefaultDirName={autopf}\Paws Off
DisableDirPage=yes
DefaultGroupName=Paws Off
DisableProgramGroupPage=yes
DisableWelcomePage=no
DisableReadyPage=yes
UsePreviousTasks=yes

; Close a running copy before upgrading (the app holds this mutex).
AppMutex=PawsOff.SingleInstance
CloseApplications=yes
RestartApplications=no

OutputDir=..\..\dist
OutputBaseFilename=PawsOff-Windows-Setup
SetupIconFile=..\Assets\PawsOff.ico
UninstallDisplayIcon={app}\PawsOff.exe
UninstallDisplayName=Paws Off
Compression=lzma2/ultra
SolidCompression=yes

WizardStyle=modern
WizardSizePercent=100
WizardImageFile=..\..\Assets\installer\wizard-large-100.bmp,..\..\Assets\installer\wizard-large-150.bmp,..\..\Assets\installer\wizard-large-200.bmp
WizardSmallImageFile=..\..\Assets\installer\wizard-small-100.bmp,..\..\Assets\installer\wizard-small-150.bmp,..\..\Assets\installer\wizard-small-200.bmp
WizardImageStretch=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to Paws Off
WelcomeLabel2=Pause your keyboard with one click, so you can wipe it down without typing gibberish, or step away without your cat writing your emails.%n%nSetup will install Paws Off [ver] for you. It takes a few seconds and doesn't need admin rights.
FinishedHeadingLabel=Paws Off is ready
FinishedLabel=Paws Off lives in your system tray. Press Ctrl+Alt+Shift+L in any app to lock or unlock the keyboard.
ClickFinish=Click Finish to close Setup.

[Tasks]
Name: "desktopicon"; Description: "Add a &desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked
Name: "startup"; Description: "&Start Paws Off when I sign in (keeps the shortcut and paw detection ready)"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "..\Fonts\OFL.txt"; DestDir: "{app}"; DestName: "Nunito-OFL.txt"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\Paws Off"; Filename: "{app}\PawsOff.exe"; Comment: "Pause your keyboard with one click"
Name: "{autodesktop}\Paws Off"; Filename: "{app}\PawsOff.exe"; Tasks: desktopicon

[Registry]
; Same value the app's "Launch at sign-in" switch uses, so the two stay in sync.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "PawsOff"; ValueData: """{app}\PawsOff.exe"" --minimized"; Tasks: startup; Flags: uninsdeletevalue
; Remove a sign-in entry the app itself created, and the app's settings, on uninstall.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "PawsOff"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\PawsOff"; Flags: uninsdeletekey

[Run]
Filename: "{app}\PawsOff.exe"; Description: "Open Paws Off now"; Flags: nowait postinstall skipifsilent
; After an automatic update (run with /SILENT by the app), start Paws Off again.
Filename: "{app}\PawsOff.exe"; Flags: nowait skipifnotsilent

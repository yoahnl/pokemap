#ifndef AppVersion
  #error AppVersion must be provided with /DAppVersion=x.y.z
#endif
#ifndef SourceDir
  #error SourceDir must point to the Flutter Release bundle
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\release"
#endif

[Setup]
AppId={{B7B33F1A-5D6C-4D62-9B32-65F9FBC8B22A}
AppName=Avelune Studio
AppVersion={#AppVersion}
AppPublisher=Avelune Studio
DefaultDirName={localappdata}\Programs\PokeMap
DefaultGroupName=Avelune Studio
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=PokeMap-Editor-Setup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\PokeMap.exe

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: files; Name: "{app}\WinSparkle.dll"
Type: files; Name: "{autoprograms}\PokeMap.lnk"
Type: files; Name: "{autodesktop}\PokeMap.lnk"

[Icons]
Name: "{autoprograms}\Avelune Studio"; Filename: "{app}\PokeMap.exe"
Name: "{autodesktop}\Avelune Studio"; Filename: "{app}\PokeMap.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"; Flags: unchecked

[Run]
Filename: "{app}\PokeMap.exe"; Description: "Lancer Avelune Studio"; Flags: nowait postinstall skipifsilent

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
AppName=PokeMap
AppVersion={#AppVersion}
AppPublisher=PokeMap
DefaultDirName={localappdata}\Programs\PokeMap
DefaultGroupName=PokeMap
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=no
RestartApplications=no
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=PokeMap-Editor-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\PokeMap.exe

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\PokeMap"; Filename: "{app}\PokeMap.exe"
Name: "{autodesktop}\PokeMap"; Filename: "{app}\PokeMap.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"; Flags: unchecked

[Run]
Filename: "{app}\PokeMap.exe"; Description: "Lancer PokeMap"; Flags: nowait postinstall skipifsilent

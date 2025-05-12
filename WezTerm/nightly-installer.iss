; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define ProjectName "WezTerm"
#define Publisher "Wez Furlong / lboulard.net"
#define PublisherURL "http://wezterm.org"
#define ProjectExecName "wezterm-gui.exe"

#include "nightly-version.inc.iss"

[Setup]
AppId={{3D466BE1-8DFE-4DF5-957D-4E570B94BAC6}
AppName="WezTerm"
AppVersion={#WezTermVersion}
AppVerName="WezTerm Nighly {#WezTermVersion}"
AppPublisher={#Publisher}
AppPublisherURL={#PublisherURL}
AppComments=WezTerm Nightly
AppContact=laurent@lboulard.fr
DefaultDirName={autopf}\WezTerm
UninstallDisplayIcon={app}\{#ProjectExecName}
UninstallDisplayName="WezTerm Nightly"
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
ChangesAssociations=yes
DefaultGroupName=.
AllowNoIcons=yes
PrivilegesRequired=lowest
OutputDir=build
OutputBaseFilename=WezTerm-nightly-{#WezTermVersion}
SetupIconFile={#SourcePath}\terminal.ico
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0.19044

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "dosbatch"; Description: "Create wezterm.cmd for CMD.EXE"; GroupDescription: "Command line usage:"; Flags: unchecked

[Files]
Source: "{#WezTermFolder}\wezterm.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\wezterm-gui.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\wezterm-mux-server.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\mesa\opengl32.dll"; DestDir: "{app}\mesa"; Flags: ignoreversion
Source: "{#WezTermFolder}\libEGL.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\libGLESv2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\conpty.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\OpenConsole.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WezTermFolder}\strip-ansi-escapes.exe"; DestDir: "{app}"; Flags: ignoreversion

#define ShellGroup "WezTerm"
#define ShellText "Open in WezTerm"
#define ShellIcon "{app}\" + ProjectExecName + ",0"
#define ShellOpen """""{app}\" + ProjectExecName + """"" start --no-auto-connect --cwd """"%V"""""

[Registry]
// Edit from Explorer Menu
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"


[Icons]
Name: "{group}\{#ProjectName}"; Filename: "{app}\{#ProjectExecName}"; AppUserModelID: "org.wezfurlong.wezterm"
Name: "{autodesktop}\{#ProjectName}"; Filename: "{app}\{#ProjectExecName}"; AppUserModelID: "org.wezfurlong.wezterm"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ProjectExecName}"; Description: "{cm:LaunchProgram,{#StringChange(ProjectName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent unchecked

[Code]

const
  LBRegistryKey = 'Software\lboulard.net';
  LBWezTermRegistryKey = LBRegistryKey + '\WezTerm';
  InstallDosbatchPathKey = 'InstallDosbatchPath';

var
  InstallDosbatchPath: String;
  InstallDosbatchPage: TInputDirWizardPage;

procedure InstallDosbatch;
var
  Tmpl: String;
  FileName: String;
  ResultStatus: String;
begin
  FileName := AddBackslash(InstallDosbatchPath) + 'wezterm.cmd';

  Log('Will create ' + FileName);
  Tmpl := ExpandConstant('@{app}\wezterm.exe %*'#13#10)
  Log(FileName + #58#13#10 + Tmpl);

  if SaveStringToFile(FileName, Tmpl, False) then
    Log(Format('%s: written', [FileName]))
  else
  begin
    ResultStatus := Format('%s: failed to write', [FileName]);
    MsgBox(ResultStatus, mbError, MB_OK);
  end;
end;

procedure InitializeWizard;
var
  LBPrograms: String;
begin
  RegQueryStringValue(HKA, LBWezTermRegistryKey, InstallDosbatchPathKey, InstallDosbatchPath);
  if InstallDosbatchPath = '' then
  begin
    LBPrograms := GetEnv('LBPROGRAMS');
    Log('GetEnv(LBPrograms)=' + LBPrograms);
    if LBPrograms <> '' then
      InstallDosbatchPath := AddBackslash(LBPrograms) + 'bin'
  end;
  InstallDosbatchPath := GetPreviousData(InstallDosbatchPathKey, InstallDosbatchPath);

  InstallDosbatchPage := CreateInputDirPage(wpSelectTasks,
    'Select location of wezterm.cmd',
    'You should install wezterm.cmd in a location that is accessible'#13#10 +
    'from your PATH environment variable.', '', False, InstallDosbatchPath);
  InstallDosbatchPage.Add('wezterm.cmd installation &path:');
  InstallDosbatchPage.Values[0] := InstallDosbatchPath;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurPageID = InstallDosbatchPage.ID then
    InstallDosbatchPath := InstallDosbatchPage.Values[0];
  Result := True
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('dosbatch') then InstallDosbatch;
  end;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  if WizardIsTaskSelected('dosbatch') then
  begin
    SetPreviousData(PreviousDataKey, InstallDosbatchPathKey, InstallDosbatchPath);
    RegWriteStringValue(HKA, LBWezTermRegistryKey, InstallDosbatchPathKey, InstallDosbatchPath);
    Log(InstallDosbatchPathKey + ': ' + InstallDosbatchPath);
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = InstallDosbatchPage.ID) and not WizardIsTaskSelected('dosbatch');
end;

function Delete(const Path: String): Boolean;
begin
  if FileExists(Path) then
  begin
    Log('Deleting file: ' + Path);
    Result := DeleteFile(path);
  end
  else
    Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    if (InstallDosbatchPath <> '') and DirExists(InstallDosbatchPath) then
      Delete(AddBackslash(InstallDosbatchPath) + 'wezterm.cmd');
end;

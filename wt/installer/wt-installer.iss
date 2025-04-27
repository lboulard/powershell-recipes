; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define ProjectName "Windows Terminal"
#define Publisher "Microsoft © / lboulard.net"
#define PublisherURL "https://github.com/microsoft/terminal"
#define ProjectExecName "WindowsTerminal.exe"

#include "wt-version.inc.iss"

[Setup]
AppId={{E145C46E-85B5-42F1-9B6A-015CF9B36B01}
AppName="Windows Terminal (ZIP release)"
AppVersion={#TerminalVersion}
AppVerName="Windows Terminal (ZIP release) {#TerminalVersion}"
AppPublisher={#Publisher}
AppPublisherURL={#PublisherURL}
AppComments=Installation based on ZIP release
DefaultDirName={autopf}\WindowsTerminal
UninstallDisplayIcon={app}\{#ProjectExecName}
UninstallDisplayName="Windows Terminal (ZIP release)"
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
ChangesAssociations=yes
DefaultGroupName=.
AllowNoIcons=yes
PrivilegesRequired=lowest
OutputDir=build
OutputBaseFilename=Microsoft.Windows.Terminal-Zip-{#TerminalVersion}
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0.19045

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "shim"; Description: "Create wt.exe shim (avoid modifying user PATH)"; GroupDescription: "Program shims:"

[Files]
Source: "{#TerminalFolder}\*"; DestDir: "{app}"; Flags: createallsubdirs recursesubdirs
SOurce: "shim.exe"; DestDir: "{tmp}"; Flags: ignoreversion; AfterInstall: CreateShim; Tasks: "shim"

#define ShellGroup "TerminalTab"
#define ShellText "Open in Terminal Tab (ZIP)"
#define ShellIcon "{app}\" + ProjectExecName + ",0"
#define ShellOpen """""{app}\wt.exe"""" -w 0 new-tab -d """"%V"""""

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
Name: "{group}\{#ProjectName}"; Filename: "{app}\{#ProjectExecName}";
Name: "{autodesktop}\{#ProjectName}"; Filename: "{app}{#ProjectExecName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ProjectExecName}"; Description: "{cm:LaunchProgram,{#StringChange(ProjectName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent unchecked

[Code]

const
  LBRegistryKey = 'Software\lboulard.net';
  LBWindowsTerminalKey = LBRegistryKey + '\WindowsTerminal';
  InstallPathShimKey = 'InstallPathShim';

var
  InstallShimPath: String;
  InstallDirShimPage: TInputDirWizardPage;

procedure CreateShim;
var
  Tmpl: String;
  FileName: String;
  ResultStatus: String;
begin
  CopyFile(ExpandConstant('{tmp}\shim.exe'),
           AddBackslash(InstallShimPath) + 'wt.exe', False);
  FileName := AddBackslash(InstallShimPath) + 'wt.shim';
  Log('Will create ' + FileName);
  Tmpl := ExpandConstant('path = @{app}\wt.exe')
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
  Caption: String;
  CustomPage: TWizardPage;
  Message: TLabel;
begin
  RegQueryStringValue(HKA, LBWindowsTerminalKey, InstallPathShimKey, InstallShimPath);
  if InstallShimPath = '' then
  begin
    LBPrograms := GetEnv('LBPROGRAMS');
    Log('GetEnv(LBPrograms)=' + LBPrograms);
    if LBPrograms <> '' then
      InstallShimPath := AddBackslash(LBPrograms) + 'bin';
  end;
  InstallShimPath := GetPreviousData(InstallPathShimKey, InstallShimPath);

  InstallDirShimPage := CreateInputDirPage(wpSelectTasks,
    'Select location of wt.exe shim',
    'You should install wt.exe shim in a location that is accessible'#13#10 +
    'from your PATH environment variable.', '', False, InstallShimPath);
  InstallDirShimPage.Add('wt.exe shim installation &path:');
  InstallDirShimPage.Values[0] := InstallShimPath;

  Caption := 'User settings will be found at'#13#10 + \
    ExpandConstant('''{localappdata}\Microsoft\Windows Terminal\settings.json''');
  CustomPage := CreateCustomPage(wpInfoAfter, 'Windows Terminal user settings',
                                 'Location of user ''settings.json'' for Windows Terminal');
  Message := TLabel.Create(WizardForm);
  Message.Parent := CustomPage.Surface;
  Message.Caption := Caption;
  Message.AutoSize := True;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
begin
  if WizardIsTaskSelected('shim') then
  begin
    SetPreviousData(PreviousDataKey, InstallPathShimKey, InstallShimPath);
    RegWriteStringValue(HKA, LBWindowsTerminalKey, InstallPathShimKey, InstallShimPath);
  end
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = InstallDirShimPage.ID) and not WizardIsTaskSelected('shim');
end;

function InitializeUninstall: Boolean;
begin
  InstallShimPath := GetPreviousData(InstallPathShimKey, InstallShimPath);
  Log(InstallPathShimKey + ': ' + InstallShimPath);
  Result := True;
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
  begin
    if (InstallShimPath <> '') and DirExists(InstallShimPath) then
    begin
      Delete(AddBackslash(InstallShimPath) + 'wt.exe');
      Delete(AddBackslash(InstallShimPath) + 'wt.shim');
    end;
  end;
end;

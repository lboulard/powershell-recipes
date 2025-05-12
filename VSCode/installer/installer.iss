; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define ProjectName "Code"
#define Publisher "Microsoft © / lboulard.net"
#define ProjectExecName "Code.exe"
#define MyAppAssocName ProjectName + " Workspace"

#include "version.inc.iss"

[Setup]
AppId={{A219659A-D359-4598-A3E5-AEF9D94D6A5B}
AppName="Visual Studio Code"
AppVersion={#VSCodeVersion}
AppVerName="Visual Studio Code {#VSCodeVersion}"
AppPublisher={#Publisher}
AppComments=Custom installation of Visual Studio Code
AppContact=laurent@lboulard.fr
DefaultDirName={autopf}\Code
UninstallDisplayIcon={app}\{#ProjectExecName}
UninstallDisplayName="Visual Studio Code"
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
ChangesAssociations=yes
DefaultGroupName=.
AllowNoIcons=yes
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=vscode-lboulard-{#VSCodeVersion}
SetupIconFile={#SourcePath}\supplies\VSCode.ico
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0.19044

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "applysettings"; Description: "Apply default settings from installer"; GroupDescription: "Visual Studio Code settings:"; Flags: unchecked
Name: "dosbatch"; Description: "Create code.cmd for CMD.EXE"; GroupDescription: "Command line usage:"; Flags: unchecked

[Files]
Source: "files-{#VSCodeVersion}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion allowunsafefiles createallsubdirs
Source: "{#SourcePath}\supplies\jq.exe"; DestDir: "{tmp}"; Tasks: applysettings
Source: "{#SourcePath}\supplies\settings.json"; DestDir: "{tmp}"; AfterInstall: ApplySettings; Tasks: applysettings
Source: "{#SourcePath}\supplies\code.tmpl.cmd"; DestDir: "{tmp}"; AfterInstall: InstallDosBatch; Tasks: dosbatch

#define ShellGroup "vscode"
#define ShellText "Open with Code"
#define ShellIcon "{app}\" + ProjectExecName + ",0"
#define ShellOpen """""{app}\" + ProjectExecName + """"" """"%V"""""
#define ShellOpenFile """""{app}\" + ProjectExecName + """"" -- """"%L"""""

[Registry]
Root: HKA; Subkey: "Software\Classes\.code-workspace"; ValueType: string; ValueName: ""; ValueData: "{#ShellGroup}.workspace"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#ShellGroup}.workspace"; ValueType: string; ValueName: ""; ValueData: "{#MyAppAssocName}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\{#ShellGroup}.workspace"; ValueType: string; ValueName: "DefaultIcon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\{#ShellGroup}.workspace\shell\open\command"; ValueType: string; ValueName: ""; ValueData: "{#ShellOpenFile}"
; Open PowerShell by default
Root: HKA; Subkey: "Software\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command"; ValueType: string; ValueName: ""; ValueData: "{#ShellOpenFile}"
Root: HKA; Subkey: "Software\Classes\Microsoft.PowerShellData.1\Shell\Open\Command"; ValueType: string; ValueName: ""; ValueData: "{#ShellOpenFile}"
Root: HKA; Subkey: "Software\Classes\Microsoft.PowerShellModule.1\Shell\Open\Command"; ValueType: string; ValueName: ""; ValueData: "{#ShellOpenFile}"
; Edit from Explorer Menu
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Drive\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Directory\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "{#ShellText}"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\Directory\background\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpen}"
; Edit a file with Code
Root: HKA; Subkey: "Software\Classes\*\shell\{#ShellGroup}"; ValueType: string; ValueName: ""; ValueData: "Edit with Code"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\*\shell\{#ShellGroup}"; ValueType: string; ValueName: "Icon"; ValueData: "{#ShellIcon}"
Root: HKA; Subkey: "Software\Classes\*\shell\{#ShellGroup}\command"; ValueType: string; ValueName: ""; ValueData:  "{#ShellOpenFile}"


[Icons]
Name: "{group}\{#ProjectName}"; Filename: "{app}\{#ProjectExecName}"
; Name: "{group}\{cm:UninstallProgram,{#VSCodeName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#ProjectName}"; Filename: "{app}\{#ProjectExecName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ProjectExecName}"; Description: "{cm:LaunchProgram,{#StringChange(ProjectName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent unchecked

[Code]
var
  VSCodeSettingsPath: String;

function LineIsComment(Line: String): Boolean;
var
  Trimed: String;
begin
  Trimed := TrimLeft(Line);
  Result := (Length(Trimed) = 0) or (Pos('//', Trimed) = 1);
end;

type
  TComment = record
    Pos: Integer;
    Line: String;
  end;
  TComments = array of TComment;

procedure AddComment(var Comments: TComments; Pos: Integer; Line: String);
begin
  SetArrayLength(Comments, GetArrayLength(Comments) + 1);
  Comments[High(Comments)].Pos := Pos;
  Comments[High(Comments)].Line := Line;
end;

function SaveTStringsToFile(const FileName: String; var S: TStrings; const Append: Boolean): Boolean;
var
  Lines: array of String;
  I: Integer;
begin
  SetLength(Lines, S.Count);
  for I := 0 to (S.Count - 1) do
    Lines[I] := S.Strings[I];
  Result := SaveStringsToUTF8FileWithoutBOM(FileName, Lines, Append);
end;

function FilterJsonComments(const InputPath, OutputPath: String): TComments;
var
  Lines: array of String;
  Comments: TComments;
  Json: TStrings;
  I: Integer;
begin
  if LoadStringsFromFile(InputPath, Lines) then
  begin
    Json := TStringList.Create
    for I := Low(Lines) to High(Lines) do
    begin
      if LineIsComment(Lines[I]) then
        AddComment(Comments, I, Lines[I])
      else
        Json.Add(Lines[I]);
    end;
    if SaveTStringsToFile(OutputPath, Json, False) then
      Result := Comments
    else
      RaiseException(OutputPath + ': cannot write JSON');
  end
  else
    RaiseException(InputPath + ': cannot read JSON');
end;

function MergeJSON(const FileName1, FileName2: String): array of String;
var
  ResultCode: Integer;
  ExecOutput: TExecOutput;
begin
  if ExecAndCaptureOutput(
        ExpandConstant('{tmp}\jq.exe'),
        Format('--indent 4 -n "reduce inputs as $item ({}; . * $item)" "%s" "%s"', [FileName1, FileName2]),
        '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode, ExecOutput) then
  begin
    if ResultCode <> 0 then
      RaiseException('jq.exe: command failed with exit code ' + IntToStr(ResultCode) + #13#10
                     + StringJoin(#13#10, ExecOutput.StdErr));
    Result := ExecOutput.StdOut;
  end
  else
    RaiseException('jq.exe: ' + SysErrorMessage(ResultCode));
end;

procedure AppendToArrayString(var A: array of String; const S: String);
var
  L: Integer;
begin
  L := GetArrayLength(A);
  SetArrayLength(A, L + 1);
  A[L] := S;
end;

procedure MergeSettings(const SettingsPath, InstallerSettingsPath: String);
var
  TmpFile: String;
  MergedFile: String;
  MergedJson: array of String;
  Settings: array of String;
  Comments: TComments;
  I, J, K: Integer;
begin
  try
    TmpFile := GenerateUniqueName(ExpandConstant('{tmp}'), '.tmp.json');
    MergedFile := GenerateUniqueName(ExpandConstant('{tmp}'), '.settings.json');
    Log('TmpFile=' + TmpFile);
    Log('MergedFile=' + MergedFile);

    // Extract comments from user settings.json
    Comments := FilterJsonComments(SettingsPath, TmpFile);

    // Merge cleaning up user settings.json with intaller provided settings.json
    MergedJson := MergeJSON(TmpFile, InstallerSettingsPath)

    // Merge back comments in final user settings.json
    J := 0; K := 0;
    For I := Low(MergedJson) to High(MergedJson) do
    begin
      // Restore comments before current line
      while (J <= High(Comments)) and (Comments[J].Pos <= K) do begin
        Log('merged> ' + Comments[J].Line);
        AppendToArrayString(Settings, Comments[J].Line);
        Inc(J); Inc(K);
      end;
      AppendToArrayString(Settings, MergedJson[I]);
      Log('merged> ' + MergedJson[I]);
      Inc(K);
    end;
    if SaveStringsToUTF8FileWithoutBOM(MergedFile, Settings, False) then
    begin
      if not CopyFile(MergedFile, SettingsPath, False) then
        RaiseException(SettingsPath + ': failed to copy from ' + MergedFile);
    end
    else
      RaiseException(MergedFile + ': failed to write');
  except
    MsgBox(GetExceptionMessage, mbError, MB_OK);
  end;
end;

procedure ApplySettings();
var
  InstallerSettings: String;
begin
  Log('start: apply VSCode settings');
  InstallerSettings := ExpandConstant('{tmp}\settings.json');
  if not FileExists(VSCodeSettingsPath) then
  begin
    Log(Format('Copy %s to %s', [InstallerSettings, VSCodeSettingsPath]));
    if CreateDir(ExtractFilePath(VSCodeSettingsPath)) then
    begin
      if not CopyFile(InstallerSettings, VSCodeSettingsPath, True) then
        MsgBox(VSCodeSettingsPath + ': cannot create', mbError, MB_OK);
    end
    else
      MsgBox(ExtractFilePath(VSCodeSettingsPath) + ': cannot create', mbError, MB_OK);
  end
  else
    MergeSettings(VSCodeSettingsPath, InstallerSettings);
  Log('end: apply VSCode settings');
end;

function AnsiToUnicode(const A: AnsiString): String;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 1 to Length(A) do
    Result[I] := Chr(Ord(A[I]));
end;

const
  LBRegistryKey = 'Software\lboulard.net';
  LBVisualStudioCodeRegistryKey = LBRegistryKey + '\VisualStudioCode';
  InstallDosbatchPathKey = 'InstallDosbatchPath';

var
  InstallDosbatchPath: String;
  InstallDosbatchPage: TInputDirWizardPage;

procedure InstallDosbatch;
var
  Data: AnsiString;
  Tmpl: String;
  FileName: String;
  ResultStatus: String;
  N: Integer;
begin
  FileName := AddBackslash(InstallDosbatchPath) + 'code.cmd';

  Log('Will create ' + FileName);

  ExtractTemporaryFile('code.tmpl.cmd');
  LoadStringFromFile(ExpandConstant('{tmp}\code.tmpl.cmd'), Data);
  Tmpl := AnsiToUnicode(Data);
  N := StringChangeEx(Tmpl, '{{CODE_EXE}}', ExpandConstant('{app}\bin\code.cmd'), True);
  Log(Format('%d substitution(s)', [N]));
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
  RegQueryStringValue(HKA, LBVisualStudioCodeRegistryKey, InstallDosbatchPathKey, InstallDosbatchPath);
  if InstallDosbatchPath = '' then
  begin
    LBPrograms := GetEnv('LBPROGRAMS');
    Log('GetEnv(LBPrograms)=' + LBPrograms);
    if LBPrograms <> '' then
      InstallDosbatchPath := AddBackslash(LBPrograms) + 'bin'
  end;
  InstallDosbatchPath := GetPreviousData(InstallDosbatchPathKey, InstallDosbatchPath);

  InstallDosbatchPage := CreateInputDirPage(wpSelectTasks,
    'Select location of code.cmd',
    'You should install code.cmd in a location that is accessible'#13#10 +
    'from your PATH environment variable.', '', False, InstallDosbatchPath);
  InstallDosbatchPage.Add('code.cmd installation &path:');
  InstallDosbatchPage.Values[0] := InstallDosbatchPath;

  VSCodeSettingsPath := ExpandConstant('{userappdata}\Code\User\settings.json');
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
    RegWriteStringValue(HKCU, LBVisualStudioCodeRegistryKey, '', ExpandConstant('{app}\Code.exe'));
    SetPreviousData(PreviousDataKey, InstallDosbatchPathKey, InstallDosbatchPath);
    RegWriteStringValue(HKA, LBVisualStudioCodeRegistryKey, InstallDosbatchPathKey, InstallDosbatchPath);
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

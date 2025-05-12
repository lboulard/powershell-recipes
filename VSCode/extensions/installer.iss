
#define IconsVersion "12.13.0"
#define PowerShellVersion "2025.0.0"

#define VsixIcons "vscode-icons-" + IconsVersion + ".vsix"
#define VsixPowerShell "powershell-" + PowerShellVersion + ".vsix"

#define Version GetDateTimeString('yyyy/mm/dd', '-', '_')

[Setup]
AppName=Install VSCode Extensions
AppVersion={#Version}
WizardStyle=modern
DefaultDirName={autopf}\lboulard\VSCodeExtensions
DefaultGroupName=lboulard\VSCodeExtensions
OutputDir=installers
OutputBaseFilename=vscode-extensions-{#Version}
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
CreateAppDir=no
Uninstallable=no
DisableWelcomePage=no

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "icons"; Description: "Visual Studio Code Icons {#IconsVersion}"; Types: full
Name: "powershell"; Description: "PowerShell extension {#PowerShellVersion}"; Types: full

[Files]
Source: "{#VsixIcons}"; DestDir: "{tmp}"; Flags: dontcopy noencryption; Components: "icons"
Source: "{#VsixPowerShell}"; DestDir: "{tmp}"; Flags: dontcopy noencryption; Components: "powershell"

[Code]
var
  CodePathPage: TInputFileWizardPage;
  CodePath: String;
  CodeCliPath: String;
  VsixInstallPage: TOutputMsgMemoWizardPage;
const
  LBRegistryKey = 'Software\lboulard.net';

function GetCodeCliPath(Param: String): String;
begin
  Result := CodeCliPath;
end;

function FindVSCodeCLI(Path: String): String;
var
  executableName: String;
begin
  executableName := AddBackslash(ExtractFileDir(Path)) + 'bin\code.cmd';
  if FileExists(executableName) then
    Result := executableName
  else
    Result := '';
end;

function ResolveCodePath(Path: String): String;
var
  pathArray: array of String;
  executableName: String;
begin
  pathArray := StringSplit(Path, ['\'], stExcludeEmpty);
  executableName := Lowercase(pathArray[High(pathArray)]);
  if executableName = 'code.exe' then
    Result := Path
  else
    Result := '';
end;

procedure SaveVSCodePath(Path: String);
begin
  RegWriteStringValue(HKCU, LBRegistryKey + '\VisualStudioCode', '', Path);
end;

function OnNextButtonClick(Sender: TWizardPage) : Boolean;
var
  FileName: String;
  CodeCli: String;
begin
  Result := False
  FileName := RemoveQuotes(TInputFileWizardPage(Sender).Values[0]);
  FileName := ResolveCodePath(Filename);
  if FileName = '' then
    MsgBox('The selected file is not code.exe or vscodium.exe. Please select the correct file.',
      mbError, MB_OK)
  else if FileExists(FileName) then
  begin
    CodeCli := FindVSCodeCLI(FileName)
    if CodeCli = '' then
      MsgBox('Failed to find code.cmd in bin folder as command line tool.', mbError, MB_OK)
    else
    begin
      CodePath := FileName;
      CodeCliPath := CodeCli;
      Result := True;
    end;
  end
  else
    MsgBox(FileName + ': not found', mbError, MB_OK);
end;

function DefaultVisualStudioCodeInstallPath(): String;
var
  Path: String;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, LBRegistryKey + '\VisualStudioCode', '', Path) then
    Path := ExpandConstant('{commonpf}\Microsoft VS Code\code.exe');
  Result := Path;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  S: String;
  Components: array of String;
  I: Integer;
begin
  { Fill the 'Ready Memo' with the normal settings and the custom settings }
  S := '';
  S := S + 'Visual Studio Code installation:' + NewLine;
  S := S + Space + CodePath + NewLine;

  S := S + NewLine;
  S := S + 'Installable components:' + NewLine
  Components := StringSplit(WizardSelectedComponents(True), [','], stAll);
  for I := Low(Components) To High(Components) do
    S := S + Space + '- ' + RemoveQuotes(Components[i]) + NewLine;

  S := S + NewLine + NewLine;
  S := S + MemoDirInfo + NewLine;

  Result := S;
end;

procedure InitializeWizard;
begin
  // Create a page to select the code.exe or vscodium.exe location
  CodePathPage := CreateInputFilePage(wpSelectDir,
    'Select Code Executable',
    'Please select the location of code.exe or vscodium.exe.',
    'Select the Code executable file (code.exe or vscodium.exe):');

  CodePathPage.Add(
    '&Location of code.exe or vscodium.exe',
    'Executable files|*.exe|All files|*.*',
    '.exe');

  CodePathPage.Values[0] := DefaultVisualStudioCodeInstallPath();
  CodePathPage.OnNextButtonClick := @OnNextButtonClick;

  // Create a page to display the output of the installation command
  VsixInstallPage := CreateOutputMsgMemoPage(wpReady, 'Install VSIX packages', 'Installing extensions…', '', '');
end;

var
  CustomExitCode: integer;

procedure ExitProcess(exitCode:integer);
  external 'ExitProcess@kernel32.dll stdcall';

procedure DeinitializeSetup();
begin
  if (CustomExitCode <> 0) then
  begin
    DelTree(ExpandConstant('{tmp}'), True, True, True);
    ExitProcess(CustomExitCode);
  end;
end;


var
  InstallRunning: Boolean;
  InstallCompleted: Boolean;
  InstallCanceled: Boolean;

procedure AppendLine(const TextLine: String);
begin
  with VsixInstallPage.RichEditViewer do
    Lines.Add(TextLine);
end;

procedure OnOutputLog(const S: String; const Error, FirtLine: Boolean);
begin
  if InstallCanceled then
    RaiseException('cancel');
  AppendLine(S);
end;

procedure UpdateProgressProc(
  H: LongWord; Msg: LongWord; Event: LongWord; Time: LongWord);
begin
  //with VsixInstallPage do
  //  SetProgress(ProgressBar.Position, ProgressBar.Max);
end;

function InstallVsix(FileName: String) : Integer;
var
  ResultCode: Integer;
  AppError: String;
  Command: String;
begin
  try
    with WizardForm do
    begin
      BackButton.Visible := False;
      BackButton.Enabled := False;
      NextButton.Visible := False;
      NextButton.Enabled := False;
      CancelButton.Visible := True;
      CancelButton.Enabled := True;
    end;

    ExtractTemporaryFile(FileName);
    Command := Format('%s --install-extension %s --force', \
                [AddQuotes(CodeCliPath),
                 AddQuotes(AddBackSlash(ExpandConstant('{tmp}')) + FileName)])
    // Command := 'ping -n 10 127.0.0.1';
    OnOutputLog(Command, False, False);
    Log('Running ' + Command);

    if not ExecAndLogOutput(
                ExpandConstant('{cmd}'),
                '/S /C "' + Command + '"',
                '',
                SW_SHOWNORMAL,
                ewWaitUntilTerminated,
                ResultCode, @OnOutputLog) then
    begin
      AppError := Format('failed to run "%s"', Command)
    end
    else
      Log('ResultCode = ' + IntToStr(ResultCode));
      if ResultCode <> 0 then
      begin
        AppError := Format('Command "%s" exited with code %d ', \
                      [Command, ResultCode])
      end;
      // AppError := 'test';
      // ResultCode := 1;
    if AppError <> '' then
    begin
      Log(AppError);
      CustomExitCode := 4;
      MsgBox(AppError, mbCriticalError, MB_OK );
     end;
  finally
    with WizardForm do
    begin
      NextButton.Visible := True;
      NextButton.Enabled := True;
      CancelButton.Visible := False;
      CancelButton.Enabled := False;
    end;
  end;

  Result := ResultCode;
end;

function InstallComponent(Name: String) : Integer;
begin
  if Name = 'icons' then
    Result := InstallVsix('{#VsixIcons}')
  else if Name = 'powershell' then
     Result := InstallVsix('{#VsixPowerShell}');
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  if (CurPageID = VsixInstallPage.ID) and InstallRunning then
  begin
    InstallCanceled := True;
    Confirm := False;
  end;
end;

function InstallExtensions(): Boolean;
var
  ResultCode: Integer;
  Components: array of String;
  I: Integer;
begin
  Result := True;
  try
    InstallRunning := True
    Components := StringSplit(WizardSelectedComponents(False), [','], stExcludeEmpty);
    for I := Low(Components) to High(Components) do
    begin
      ResultCode := InstallComponent(Components[i]);
      if ResultCode <> 0 then
        break;
    end;
  except
    MsgBox(GetExceptionMessage, mbError, MB_OK);
    Result := False;
  finally
    InstallRunning := False;
    InstallCompleted := True;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = VsixInstallPage.ID then
    InstallExtensions();
end;

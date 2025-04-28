; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "CascadiaCode Fonts"
#define MyAppVersion "UnknownVersion"
#define MyAppPublisher "Microsoft © / lboulard.net"
#define MyAppURL "https://github.com/microsoft/cascadia-code"
#define MyAppLicense "LICENSE.txt"

#include "version.inc.iss"

[Setup]
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{23009B7E-6F3A-47D6-B89E-6FE60BD6844C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
LicenseFile={#MyAppLicense}
; Remove the following line to run in administrative install mode (install for all users).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=fonts-cascadiacode-{#MyAppVersion}
OutputDir=installers
SolidCompression=yes
; Compression=none
WizardStyle=modern
TimeStampsInUTC=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
#include "files.inc.iss"

[Code]
const
  WM_FONTCHANGE                = $001D;
  SMTO_ABORTIFHUNG             = $0002;

function SendMessageTimeout(hWnd: HWND; Msg: UINT; wParam, lParam: LongInt;
  fuFlags, uTimeout: UINT; out pdwResult: DWORD): Cardinal;
  external 'SendMessageTimeoutW@user32.dll stdcall';

procedure CurStepChanged(CurStep: TSetupStep);
var
  Dummy: DWORD;
begin
  if CurStep = ssPostInstall then
    // Tell Windows to rescan fonts so new ones appear immediately
    SendMessageTimeout(HWND_BROADCAST, WM_FONTCHANGE, 0, 0,
                       SMTO_ABORTIFHUNG, 10000, Dummy);
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = wpReady) or (PageID = wpSelectDir);
end;

var
  ImportantPage: TOutputMsgMemoWizardPage;
  
const
  ImportantText = '' +
    '_______________________________________________________________________'#13#10 +
    ''#13#10 +
    'When you install Windows Terminal, installation register as provider for'#13#10 +
    'variable Cascadia and Cascadia Mono fonts. Both fonts are accessible by'#13#10 +
    'CMD.EXE (conhost.exe). Better use PL variants for pretty prompt.'#13#10 +
    ''#13#10 +
    'WARNING: Installs Cascadia and Cascadia Mono as user only fonts only if'#13#10 +
    'Terminal is not installed.'#13#10 +
    '_______________________________________________________________________'#13#10 +
    ''#13#10 +
    'Cascadia PL/Cascadia Mono PL (add Powerline Symbols) are not provided by'#13#10 +
    'Windows Terminal. For CMD.EXE use (conhost.exe), install as system font,'#13#10 +
    'not user only fonts!'#13#10 +
    '_______________________________________________________________________'#13#10 +
    '';

<event('InitializeWizard')>
procedure InitializeImportantpage;
begin
  ImportantPage := CreateOutputMsgMemoPage(wpLicense,
    'Information',
    'Please read carefully when installing MS © CascadiaCode fonts',
    'Press next button if you understand warning',
    ImportantText);
end;
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Cascadia Code Fonts"
#define MyAppVersion "UnknownVersion"
#define MyAppPublisher "Microsoft © / lboulard.net"
#define MyAppURL "https://github.com/microsoft/cascadia-code"
#define MyAppLicense "LICENSE.txt"
#define MyAppInstaller "fonts-cascadiacode"

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
OutputBaseFilename={#MyAppInstaller}-{#MyAppVersion}
OutputDir=installers
SolidCompression=yes
; Compression=none
WizardStyle=modern
TimeStampsInUTC=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
#include "files-main.inc.iss"

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
    ''#13#10 +
    'When you install new Windows Terminal, installation register as provider'#13#10 +
    'for variable Cascadia and Cascadia Mono fonts. Both fonts are accessible'#13#10 +
    'by CMD.EXE console for all users.'#13#10 +
    ''#13#10 +
    'WARNING:'#13#10 +
    'This installer provide non-variable version of equivalent Cascadia fonts.'#13#10 +
    'Installs Cascadia and Cascadia Mono fonts for all users only when'#13#10 +
    'new Microsoft Windows Terminal is not installed.'#13#10 +
    ''#13#10 +
    'You can install Cascadia and Cascadia Mono fonts as current user, even'#13#10 +
    'in presence of new Microsoft Windows Terminal. Be careful to update'#13#10 +
    'current user installation when new fonts version are installed on upgrade'#13#10 +
    'of new Microsoft Windows Terminal.'#13#10 +
    '';

<event('InitializeWizard')>
procedure InitializeImportantpage;
begin
  ImportantPage := CreateOutputMsgMemoPage(wpLicense,
    'Information',
    'Please read carefully when installing MS © CascadiaCode fonts',
    'Press next button if you understand warnings',
    ImportantText);
end;
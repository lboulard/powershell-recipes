; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Cascadia Code Fonts"
#define MyAppVersion "UnknownVersion"
#define MyAppPublisher "Microsoft © / lboulard.net"
#define MyAppURL "https://github.com/microsoft/cascadia-code"
#define MyAppLicense "LICENSE.txt"

#include "version.inc.iss"

[Setup]
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{73BF0934-6ABA-481B-9A40-8C9918BF0931}
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
OutputBaseFilename=fonts-cascadiacode-variants-{#MyAppVersion}
OutputDir=installers
SolidCompression=yes
; Compression=none
WizardStyle=modern
TimeStampsInUTC=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "powerline"; Description: "Powerline variant installation"
Name: "nerdfonts"; Description: "Nerd Fonts variant installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "PL"; Description: "Powerline variant (PL)"; Types: full powerline
Name: "NF"; Description: "Nerd Fonts variant (NF)"; Types: full nerdfonts

[Files]
#include "files-variants.inc.iss"

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
    'When you install Windows Terminal, installation register as provider for'#13#10 +
    'variable Cascadia and Cascadia Mono fonts. Both fonts are accessible by'#13#10 +
    'CMD.EXE (conhost.exe) for while system.'#13#10 +
    ''#13#10 +
    'Cascadia PL/Cascadia Mono PL (fonts with Powerline Symbols) are not'#13#10 +
    'provided on Windows Terminal installation. For CMD.EXE console usage,'#13#10 +
    'install those fonts as system font not user only fonts!'#13#10 +
    'Same for Nerd Fonts (NF) variant, also not installed at Windows Terminal'#13#10 +
    'installation.'#13#10 +
    ''#13#10 +
    'Notes:'#13#10 +
    ' - Better use Powerline (PL) variant for custom pretty prompt.'#13#10 +
    ' - Better use Nerd fonts (NF) variant for icons with terminal tools.'#13#10 +
    '';

<event('InitializeWizard')>
procedure InitializeImportantpage;
begin
  ImportantPage := CreateOutputMsgMemoPage(wpLicense,
    'Information',
    'Please read carefully when installing MS © CascadiaCode fonts',
    'Press next button if you understand reccommendations',
    ImportantText);
end;
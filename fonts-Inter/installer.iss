; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Inter Fonts"
#define MyAppVersion "UnknownVersion"
#define MyAppPublisher "Rasmus Andersson / lboulard.net"
#define MyAppURL "https://rsms.me/inter/"
#define MyAppLicense ""

#include "version.inc.iss"

[Setup]
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{1FA9AA0C-51CD-408C-833E-983BFBA9C8C0}
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
PrivilegesRequiredOverridesAllowed=commandline
OutputBaseFilename=fonts-inter-{#MyAppVersion}
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
  Result := (PageID = wpReady);
end;

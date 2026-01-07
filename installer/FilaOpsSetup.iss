; FilaOps Windows Installer
; Requires Inno Setup 6.x - https://jrsoftware.org/isinfo.php
;
; This installer:
; 1. Checks for Docker Desktop (prompts install if missing)
; 2. Extracts FilaOps files
; 3. Creates .env from template
; 4. Runs docker-compose up
; 5. Creates Start Menu shortcuts for Start/Stop/Open

#define MyAppName "FilaOps"
#define MyAppVersion "2.0.1"
#define MyAppPublisher "Blb3D"
#define MyAppURL "https://github.com/Blb3D/filaops"
#define MyAppExeName "FilaOpsLauncher.exe"

[Setup]
AppId={{B3D-FILAOPS-2024}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
OutputDir=output
OutputBaseFilename=FilaOpsSetup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
SetupIconFile=assets\filaops.ico
UninstallDisplayIcon={app}\filaops.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupicon"; Description: "Start FilaOps when Windows starts"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Core application files
Source: "..\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\frontend\*"; DestDir: "{app}\frontend"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\docker-compose.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\docker-compose.prod.yml"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\.env.example"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion

; Launcher and scripts
Source: "scripts\FilaOpsLauncher.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "scripts\Start-FilaOps.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\Stop-FilaOps.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\Open-FilaOps.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\Check-Docker.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\Update-FilaOps.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

; Assets
Source: "assets\filaops.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\filaops.ico"
Name: "{group}\Start FilaOps"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\Start-FilaOps.ps1"""; IconFilename: "{app}\filaops.ico"
Name: "{group}\Stop FilaOps"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\Stop-FilaOps.ps1"""; IconFilename: "{app}\filaops.ico"
Name: "{group}\Open FilaOps"; Filename: "http://localhost:5173"; IconFilename: "{app}\filaops.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\filaops.ico"
Name: "{commonstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--autostart"; Tasks: startupicon

[Run]
; Check for Docker after install
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\Check-Docker.ps1"""; StatusMsg: "Checking Docker installation..."; Flags: runhidden
; Create .env if it doesn't exist
Filename: "powershell.exe"; Parameters: "-Command ""if (!(Test-Path '{app}\.env')) {{ Copy-Item '{app}\.env.example' '{app}\.env' }}"""; StatusMsg: "Creating configuration..."; Flags: runhidden
; Offer to start FilaOps
Filename: "{app}\{#MyAppExeName}"; Description: "Launch FilaOps now"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Stop containers before uninstall
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File ""{app}\scripts\Stop-FilaOps.ps1"""; Flags: runhidden

[Code]
var
  DockerPage: TOutputMsgWizardPage;
  DockerInstalled: Boolean;

function IsDockerInstalled(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd.exe', '/c docker --version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

function IsDockerRunning(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('cmd.exe', '/c docker info', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InitializeWizard();
begin
  DockerInstalled := IsDockerInstalled();
  
  if not DockerInstalled then
  begin
    DockerPage := CreateOutputMsgPage(wpWelcome,
      'Docker Desktop Required',
      'FilaOps requires Docker Desktop to run.',
      'Docker Desktop was not detected on your system.'#13#10#13#10 +
      'After completing this installer, you will need to:'#13#10#13#10 +
      '1. Download Docker Desktop from https://docker.com/products/docker-desktop'#13#10 +
      '2. Install and start Docker Desktop'#13#10 +
      '3. Then launch FilaOps'#13#10#13#10 +
      'Click Next to continue with the installation.');
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Log installation
    SaveStringToFile(ExpandConstant('{app}\install.log'), 
      'FilaOps installed: ' + GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':') + #13#10, True);
  end;
end;

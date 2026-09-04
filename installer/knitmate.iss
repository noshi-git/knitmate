; KnitMate Windows インストーラー（Inno Setup）
; ビルド前提: build\windows\x64\runner\Release\ に Release 一式が存在すること
;
; 手順:
;   1. flutter build windows --release
;   2. Inno Setup で installer\KnitMate.iss を Compile
;   3. 出力: installer\Output\KnitMate_Setup.exe

#define MyAppName "KnitMate"
#define MyAppVersion "4.1.0"
#define MyAppPublisher "KnitMate"
#define MyAppExeName "KnitMate.exe"
#define BuildOutputDir "..\build\windows\x64\runner\Release"

[Setup]
; 固定 AppId（再インストール時の上書き更新用。変更しないこと）
AppId={{A7C3E9F1-2B4D-4F8A-9E6C-1D5B0A2E4F00}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\KnitMate
DefaultGroupName=KnitMate
OutputBaseFilename=KnitMate_Setup_4.1.0
OutputDir=Output
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
DisableProgramGroupPage=yes
; Program Files 配下へインストールするため管理者権限を使用
PrivilegesRequired=admin

[Languages]
; 日本語ファイルが無い環境では japanese 行をコメントアウトして Compile してください
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Release フォルダ一式（KnitMate.exe / DLL / data など）をそのままインストール
; ignoreversion: 再インストール時に上書き更新
; ユーザーデータ（Documents 配下など）は対象外
Source: "{#BuildOutputDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; スタートメニュー
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; デスクトップ（インストール時に選択）
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchKnitMate}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
english.LaunchKnitMate=Launch KnitMate
japanese.LaunchKnitMate=KnitMateを起動する

[Messages]
japanese.CreateDesktopIcon=デスクトップにショートカットを作成する(&D)
japanese.AdditionalIcons=追加のショートカット:

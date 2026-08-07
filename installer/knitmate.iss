; KnitMate Windows インストーラー（Inno Setup）
; ビルド前提: build\windows\x64\runner\Release\ に Release 一式が存在すること
;
; 手順:
;   1. flutter clean
;   2. flutter build windows --release
;   3. Inno Setup で installer\knitmate.iss を開いて Compile

#define MyAppName "KnitMate"
#define MyAppVersion "4.0.0"
#define MyAppPublisher "KnitMate"
#define MyAppExeName "KnitMate.exe"
#define BuildOutputDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{A7C3E9F1-2B4D-4F8A-9E6C-1D5B0A2E4F00}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\KnitMate
DefaultGroupName=KnitMate
OutputBaseFilename=KnitMateSetup
OutputDir=output
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest

[Languages]
; 日本語ファイルが無い環境では japanese 行をコメントアウトして Compile してください
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"

[Files]
; Release フォルダ一式（KnitMate.exe / flutter_windows.dll / data など）をすべてインストール
Source: "{#BuildOutputDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; スタートメニュー
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
; デスクトップ（インストールされた KnitMate.exe のアイコンを使用）
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
; インストール完了後に「KnitMateを起動する」チェックを表示
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchKnitMate}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
english.LaunchKnitMate=Launch KnitMate
japanese.LaunchKnitMate=KnitMateを起動する

[Messages]
japanese.CreateDesktopIcon=デスクトップにショートカットを作成する(&D)
japanese.AdditionalIcons=追加のショートカット:

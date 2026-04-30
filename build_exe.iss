[Setup]
; 这里的 ID 是唯一的，以后不要改它
AppId={{5FB957FC-1447-F797-204B-4978547B8920}
AppName=nvm_desktop
AppVersion=1.0.0
DefaultDirName={autopf}\nvm_desktop
DefaultGroupName=nvm_desktop
; --- 核心：强制要求管理员权限，解决软链接失败 ---
PrivilegesRequired=admin
; -------------------------------------------
OutputBaseFilename=nvm_desktop_installer
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64os

[Files]
; 复制 build 生成的所有 Release 文件
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\nvm_desktop"; Filename: "{app}\nvm_desktop.exe"
Name: "{commondesktop}\nvm_desktop"; Filename: "{app}\nvm_desktop.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "额外图标:"; Flags: unchecked

[Run]
; 安装后自动以管理员身份启动应用
Filename: "{app}\nvm_desktop.exe"; Description: "运行 nvm_desktop"; Flags: nowait postinstall skipifsilent runascurrentuser
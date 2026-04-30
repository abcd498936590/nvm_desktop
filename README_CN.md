# **nvm_desktop**

一款基于 Flutter 构建的专业级跨平台 Node.js 版本管理工具。旨在为开发者提供直观、高效的图形化界面，在 Windows 和 macOS 上轻松切换与管理多个 Node.js 环境。

## **预览**

<img src="./perview.png"/>

## **核心特性**

- **跨平台支持：** 完美适配 Windows (x64) 与 macOS (ARM64/x64)。
- **架构感知：**
  - **macOS：** 原生支持 Apple Silicon (ARM64) 以及 Intel (x64) 芯片。
  - **Windows：** 提供对 x64 架构 Node.js 发行版的稳定支持。
- **高性能 UI：** 采用最新的 Flutter 稳定版开发，确保极致的响应速度与丝滑的交互体验。
- **深度集成：** 自动处理环境变量注入与符号链接（Symbolic Links）管理，简化配置流程。

## **技术规范**

| 组件             | 规格                             |
| :--------------- | :------------------------------- |
| 开发框架         | Flutter (Channel stable, 3.41.9) |
| 支持系统         | Windows 10+, macOS 11+           |
| macOS 架构支持   | ARM64, x64                       |
| Windows 架构支持 | x64                              |

## **构建指南**

### **环境准备**

- **Flutter SDK:** 3.41.9
- **macOS 端:** 需安装 create-dmg (brew install create-dmg)。
- **Windows 端:** 需预装 Inno Setup 并将 ISCC.exe 路径添加到系统环境变量。

### **macOS 编译与打包**

`# 1. 编译 Release 版本`  
`flutter build macos --release`

`# 2. 清除扩展属性`  
`xattr -cr build/macos/Build/Products/Release/nvm_desktop.app`

`# 3. 赋予执行权限`  
`chmod -R +x build/macos/Build/Products/Release/nvm_desktop.app`

`# 4. 执行脚本生成 DMG`  
`./build_dmg.sh`

### **Windows 编译与打包**

`# 1. 编译 Windows Release 产物`  
`flutter build windows --release`

`# 2. 使用 Inno Setup 生成安装程序`  
`ISCC.exe build_exe.iss`

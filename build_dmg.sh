#!/bin/bash

# 定义变量
APP_NAME="nvm_desktop"
# 根据架构修改 DMG 文件名
DMG_NAME="nvm-desktop-macos.dmg"
# 注意：这里假设你打包后已经手动或通过脚本将对应的 .app 放在了对应的路径
# 或者你可以在打包脚本里直接把产物移到这里
APP_PATH="build/macos/Build/Products/Release/nvm_desktop.app"

# 检查 .app 是否存在，防止 create-dmg 报错
if [ ! -d "$APP_PATH" ]; then
  echo "错误: 找不到应用文件 $APP_PATH"
  exit 1
fi

# 如果已存在旧的 dmg 则删除
if [ -f "$DMG_NAME" ]; then
  rm "$DMG_NAME"
fi

echo "正在生成 $DMG_NAME..."

# 开始封装
create-dmg \
  --volname "${APP_NAME}" \
  --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/128.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 150 185 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 450 185 \
  "$DMG_NAME" \
  "$APP_PATH"

echo "完成！已生成 $DMG_NAME"
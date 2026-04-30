#!/bin/bash

# 定义变量方便修改
APP_NAME="nvm_desktop"
APP_PATH="build/macos/Build/Products/Release/nvm_desktop.app"
DMG_NAME="nvm-desktop-installer.dmg"

# 如果已存在旧的 dmg 则删除
if [ -f "$DMG_NAME" ]; then
  rm "$DMG_NAME"
fi

# 开始封装
create-dmg \
  --volname "$APP_NAME" \
  --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/128.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 150 185 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 450 185 \
  "$DMG_NAME" \
  "$APP_PATH"
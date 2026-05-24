import 'dart:io';
import 'dart:ffi'; // nullptr 定义在这里
import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:nvm_desktop/utils/path.dart';
import 'package:win32/win32.dart'; // 仅 Windows 需要
import 'package:path/path.dart' as p;

class EnvManager {
  /// 1. 检测环境变量是否已经注入
  static Future<bool> checkIsInPath() async {
    final binPath = await PathManager.getDirPath("bin");
    final pathEnv = Platform.environment['PATH'] ?? '';
    return pathEnv.contains(binPath);
  }

  /// 2. 注入环境变量（跨平台实现）
  static Future<void> injectPath() async {
    final binPath = await PathManager.getDirPath("bin");
    debugPrint("环境变量bin目录：$binPath");
    if (Platform.isMacOS) {
      await _injectMacOS(binPath);
    } else if (Platform.isWindows) {
      await _injectWindows(binPath);
    }
  }

  /// macOS 注入逻辑：直接追加 PATH 字符串
  static Future<void> _injectMacOS(String binPath) async {
    final home = Platform.environment['HOME'];
    final zshrc = File('$home/.zshrc');
    // 1. 读取内容，如果文件不存在则为空字符串
    String content = await zshrc.exists() ? await zshrc.readAsString() : '';
    // 2. 直接检查内容中是否已经包含了你的 bin 路径
    // 这样即便没有注释，只要路径在里面，就不会重复添加
    if (!content.contains(binPath)) {
      // 直接追加到 PATH 的最前面
      // 这里依然建议保留一个简单的注释，方便用户知道这是谁加的，但检测不依赖它
      final exportStr = 'export PATH="$binPath:\$PATH"\n';
      await zshrc.writeAsString(exportStr, mode: FileMode.append);
      // 3. 立即刷新当前 App 进程的环境变量（让接下来的子进程能用）
      await Process.run('launchctl', [
        'setenv',
        'PATH',
        '$binPath:${Platform.environment['PATH']!}',
      ]);
    } else {
      debugPrint("当前环境变量已存在 $binPath");
    }
  }

  /// Windows 注入逻辑：修改 User Registry
  static Future<void> _injectWindows(String binPath) async {
    // 关键：使用单引号包裹路径，并确保变量名在 PS 里被正确识别
    final psCommand =
        '''
    \$bin = '$binPath';
    # 获取当前用户的 Path
    \$oldPath = [Environment]::GetEnvironmentVariable("Path", "User");
    
    # 检查是否已包含（更加健壮的检查逻辑）
    if (\$oldPath -split ';' -notcontains \$bin) {
        # 将新路径加到最前面
        \$newPath = \$bin + ';' + \$oldPath;
        [Environment]::SetEnvironmentVariable("Path", \$newPath, "User");
    }
  ''';

    // 执行时建议添加 -NoProfile 提高速度并减少干扰
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      psCommand,
    ]);

    if (result.exitCode != 0) {
      debugPrint("注入失败: ${result.stderr}");
    } else {
      debugPrint("注入尝试完成，请检查环境变量");
      _broadcastWinChange();
    }
  }

  static void _broadcastWinChange() {
    if (!Platform.isWindows) return;

    final systemMessage = 'Environment'.toNativeUtf16();
    SendMessageTimeout(
      HWND_BROADCAST,
      WM_SETTINGCHANGE,
      WPARAM(0),
      LPARAM(systemMessage.address),
      SMTO_ABORTIFHUNG,
      5000,
      nullptr,
    );
  }

  static Future<bool> isVersionActive(String versionName) async {
    final String supportPath = await PathManager.getDirPath(null);
    final String binLinkPath = p.join(supportPath, 'bin');
    final link = Link(binLinkPath);
    if (await link.exists()) {
      // 获取软链接实际指向的完整路径
      // 例如：/Users/.../versions/v18.16.0/bin
      String targetPath = await link.target();
      // 判断这个路径里是否包含我们要删除的版本号
      // 或者检查 targetPath 是否以 versions/versionName 结尾
      return targetPath.contains(p.join('versions', versionName));
    }
    return false;
  }

  static Future<void> deleteNodeVersion(String targetVersionName) async {
    final String supportPath = await PathManager.getDirPath(null);
    final String binLinkPath = p.join(supportPath, 'bin'); // 环境变量指向这里
    final String targetVersionPath = p.join(
      supportPath,
      'versions',
      targetVersionName,
    );
    // 判断要删除的版本是否是正在使用的版本
    bool curVersionActiveted = await isVersionActive(targetVersionName);
    if (curVersionActiveted) {
      final link = Link(binLinkPath);
      if (await link.exists()) {
        // 仅仅删除这个“快捷方式/链接”本身
        await link.delete();
        debugPrint("已移除旧版本链接");
      }
    }
    await Directory(targetVersionPath).delete(recursive: true);
  }

  static Future<void> switchNodeVersion(
    String targetVersionName,
    VoidCallback cb,
  ) async {
    // 1. 定义路径
    final String supportPath = await PathManager.getDirPath(null);
    final String binLinkPath = p.join(supportPath, 'bin'); // 环境变量指向这里
    final String targetVersionPath = p.join(
      supportPath,
      'versions',
      targetVersionName,
      Platform.isMacOS ? 'bin' : null,
    );
    // 【核心修改】：不要只用 Link.exists，改用 FileSystemEntity 检查所有类型
    final type = await FileSystemEntity.type(binLinkPath);
    if (type != FileSystemEntityType.notFound) {
      debugPrint("发现占位实体 ($type)，正在强制清理...");
      // 无论是文件夹还是旧链接，递归删除它
      await Directory(binLinkPath).delete(recursive: true);
    }
    // // 2. 检查目标版本是否存在
    // if (!await Directory(targetVersionPath).exists()) {
    //   debugPrint("错误：目标版本 $targetVersionName 尚未下载");
    //   return;
    // }
    // 3. 处理软链接
    final link = Link(binLinkPath);
    if (await link.exists()) {
      // 仅仅删除这个“快捷方式/链接”本身
      await link.delete();
      debugPrint("已移除旧版本链接");
    }
    // 4. 创建新链接指向新路径
    // 现在坑位绝对是空的，可以放心创建链接
    try {
      await Link(binLinkPath).create(targetVersionPath);
      cb();
      debugPrint("成功切换至版本: $targetVersionName");
    } catch (e) {
      debugPrint("创建链接依然失败: $e");
    }
  }
}

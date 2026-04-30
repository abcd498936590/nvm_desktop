import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PathManager {
  /// 获取安全的可写目录，用于下载 Node.js 版本
  static Future<String> getDirPath(String? childDirName) async {
    // 1. 获取系统标准的 Application Support 目录
    final Directory appSupportDir = await getApplicationSupportDirectory();
    // 2. 在该目录下创建一个子目录专门存放 node 版本
    // 使用 path 库的 join 方法可以自动处理 \ 和 / 的差异
    final String targetPath = p.join(appSupportDir.path, childDirName);
    // 3. 确保这个目录存在，如果不存在则创建
    final Directory dir = Directory(targetPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return targetPath;
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nvm_desktop/entity/remote_version.dart';
import 'package:nvm_desktop/request/dio_client.dart';
import 'package:nvm_desktop/request/http_response.dart';
import 'package:nvm_desktop/utils/config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

typedef ReceiveProgress = void Function(int, int);

class AppPathConfig {
  String supportDirPath;
  String versionsDirPath;
  String distDirPath;
  AppPathConfig({
    required this.supportDirPath,
    required this.versionsDirPath,
    required this.distDirPath,
  });
}

class PathManager {
  // 生成平台对应的文件名称
  static String getVersionFileName(String version) {
    return Platform.isWindows ? "$version.zip" : "$version.tar.gz";
  }

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

  // 读取本地已经下载下来的所有版本
  static Future<List<NodeVersionEntity>> getLocalVersions(
    String versionDirPath,
  ) async {
    Directory versionDir = Directory(versionDirPath);
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }
    List<NodeVersionEntity> refreshVersionList = [];
    await for (FileSystemEntity entity in versionDir.list(recursive: false)) {
      // 3. 必须是目录
      if (entity is Directory) {
        // 获取目录路径，例如：.../versions/v25.8.0
        String dirPath = entity.path;
        // 4. 拼接并检查 manifest.json
        File manifestFile = File(p.join(dirPath, 'manifest.json'));
        if (await manifestFile.exists()) {
          // 找到了！在这里处理你的逻辑
          String content = await manifestFile.readAsString();
          debugPrint('在目录 ${p.basename(dirPath)} 中找到了 manifest.json');
          Map<String, dynamic> data = jsonDecode(content);
          refreshVersionList.add(NodeVersionEntity.fromJson(data));
        } else {
          debugPrint('目录 ${p.basename(dirPath)} 中没有清单文件，跳过');
        }
      }
    }
    return refreshVersionList;
  }

  // 解压，摆放位置
  static Future<void> arrange({
    required NodeVersionEntity item,
    required String savePath,
    required String curFrameWork,
    required String tempFilePath,
    VoidCallback? finishCallback,
  }) async {
    // 3. 确保目标版本目录存在（如果已存在则先清空，防止旧文件干扰）
    final targetDir = Directory(savePath);
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);
    // 4. 调用系统 tar 命令进行解压
    // -x: 解压
    // -f: 指定文件
    // -C: 指定解压到哪个目录
    // --strip-components 1: 关键！跳过压缩包里的第一层文件夹，直接把内容扔进 savePath
    // Windows 即使是 .zip 格式，tar 也能处理
    List<String> tarArgs = [
      '-xf',
      tempFilePath,
      '-C',
      savePath,
      '--strip-components',
      '1',
    ];
    var result = await Process.run('tar', tarArgs);
    if (result.exitCode != 0) {
      throw Exception("系统解压失败: ${result.stderr}");
    }
    // 5. 解压成功后，删除临时安装包
    await File(tempFilePath).delete();
    // 6. 针对 macOS 的后续处理（权限与隔离标识）
    if (Platform.isMacOS) {
      // 赋予 bin 目录下所有文件执行权限
      await Process.run('chmod', ['-R', '+x', p.join(savePath, 'bin')]);
      // 移除 macOS 安全隔离标识，防止运行 node 时弹窗
      await Process.run('xattr', ['-cr', savePath]);
    }
    // 写入清单文件，用于本地遍历读取对应信息
    if (await Directory(savePath).exists()) {
      String filePath = p.join(savePath, 'manifest.json');
      File file = File(filePath);
      // 1. 获取 Map 对象（不要在这里用 jsonEncode）
      Map<String, dynamic> dataMap = item.toJson();
      // 追加一个字读 架构，用于本地读取查看
      dataMap["framework"] = curFrameWork;
      // 2. 创建美化编码器
      var encoder = JsonEncoder.withIndent('  ');
      // 3. 直接转换 Map 对象
      String prettyString = encoder.convert(dataMap);
      // 4. 写入文件
      await file.writeAsString(prettyString, flush: true);
    }
    finishCallback?.call();
  }

  // 下载sdk
  static Future<MyDioResponse> downloadSdk({
    required NodeVersionEntity item,
    required String curFrameWork,
    VoidCallback? downloadStartCallback,
    ReceiveProgress? receiveProgressCallback,
    VoidCallback? downloadCompleteCallback,
  }) async {
    String version = item.version!;
    int lastDashIndex = curFrameWork.lastIndexOf('-');
    String platformArch = curFrameWork.substring(0, lastDashIndex);
    String extension = curFrameWork.substring(lastDashIndex + 1);
    String tarSdkUrl =
        "$remoteUrl/dist/$version/node-$version-$platformArch.$extension";
    if (Platform.isMacOS) {
      tarSdkUrl = '${tarSdkUrl.replaceAll("osx", "darwin")}.gz';
    }
    String supportDirPath = await PathManager.getDirPath(null);
    String versionsDirPath = p.join(supportDirPath, "versions");
    String distDirPath = p.join(supportDirPath, "dist");
    String savePath = p.join(versionsDirPath, version);
    await Directory(versionsDirPath).create(recursive: true);
    await Directory(distDirPath).create(recursive: true);
    debugPrint("sdk远程地址：$tarSdkUrl");
    debugPrint("本地Support目录：$savePath");
    String tempFileName = Platform.isWindows
        ? "$version.zip"
        : "$version.tar.gz";
    String tempFilePath = p.join(distDirPath, tempFileName);
    downloadStartCallback?.call();
    return HttpUtil()
        .download(
          tarSdkUrl,
          tempFilePath,
          onReceiveProgress: receiveProgressCallback,
        )
        .whenComplete(() {
          downloadCompleteCallback?.call();
        });
  }
}

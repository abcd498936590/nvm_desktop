import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:nvm_desktop/entity/remote_version.dart';
import 'package:nvm_desktop/interface/refresh.dart';
import 'package:nvm_desktop/l10n/app_localizations.dart';
import 'package:nvm_desktop/request/dio_client.dart';
import 'package:nvm_desktop/request/http_response.dart';
import 'package:nvm_desktop/utils/config.dart';
import 'package:nvm_desktop/utils/path.dart';
import 'package:path/path.dart' as p;

class RemoteTabBar extends StatefulWidget {
  const RemoteTabBar({super.key});

  @override
  State<RemoteTabBar> createState() => RemoteTabBarState();
}

class RemoteTabBarState extends RefreshableState<RemoteTabBar>
    with AutomaticKeepAliveClientMixin {
  List<NodeVersionEntity> _nodeVersionList = [];
  String get platformName => Platform.operatingSystem;
  String curFrameWork = "";
  double progress = 0;
  bool loading = false;
  List<String> get _curPlatFormFrameWork =>
      platFormAndFreameWork[platformName]!;

  @override
  void initState() {
    super.initState();
    curFrameWork = platFormAndFreameWork[platformName]?[0] ?? "";
    setState(() {});
    refresh();
  }

  @override
  Future<void> refresh() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      SmartDialog.showLoading(msg: AppLocalizations.of(context)!.pullLoading);
    }
    MyDioResponse myResponse = await HttpUtil()
        .get(remoteVersionUrl, cacheDisk: true)
        .whenComplete(() {
          SmartDialog.dismiss(status: SmartStatus.loading);
        });
    if (myResponse.ok) {
      final List<dynamic> data = myResponse.data;
      setState(() {
        _nodeVersionList = data
            .map<NodeVersionEntity>((it) {
              return NodeVersionEntity.fromJson(it);
            })
            .where(
              (item) => platFormAndFreameWork[platformName]!.any(
                (frItem) => item.files!.contains(frItem),
              ),
            )
            .toList();
      });
    } else {
      debugPrint(myResponse.exc?.message);
      SmartDialog.showToast("请求错误");
    }
  }

  void _showVersionDetailDialog(BuildContext context, int index) {
    progress = 0;
    loading = false;
    // 提前筛选出来对应版本拥有的架构
    NodeVersionEntity item = _nodeVersionList[index];
    List<String> filterFrameWork = _curPlatFormFrameWork
        .where((it) => item.files!.contains(it))
        .toList();
    // 重置默认值
    curFrameWork = filterFrameWork.first;
    setState(() {});
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.dialogInstallTitle),
              content: SizedBox(
                width: 330,
                height: 180,
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${AppLocalizations.of(context)!.dialogNodeVersion}：${item.version}",
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${AppLocalizations.of(context)!.dialogNpmVersion}：${item.npm}",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.dialogSelectFrameWork}：",
                          style: TextStyle(fontSize: 17),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: DropdownButton<String>(
                            value: curFrameWork,
                            focusColor: Colors.transparent,
                            hint: Text(
                              AppLocalizations.of(
                                context,
                              )!.dialogSelectFrameWork,
                            ), // 初始提示文字
                            isExpanded: true, // 让下拉框占满横向空间
                            underline: Container(
                              height: 2,
                              color: Colors.blue,
                            ), // 自定义下划线
                            items: filterFrameWork
                                .map<DropdownMenuItem<String>>((it) {
                                  return DropdownMenuItem<String>(
                                    value: it,
                                    child: Text(it.split("-")[1]),
                                  );
                                })
                                .toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                curFrameWork = newValue!;
                              });
                              debugPrint("用户选择了: $newValue");
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.dialogDownloadProgress}：",
                          style: TextStyle(fontSize: 17),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress, // 0.0 到 1.0 之间的值
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                            minHeight: 5, // 进度条高度
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (!loading) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.dialogClose),
                ),
                FilledButton(
                  style: !loading
                      ? null
                      : ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.grey),
                        ),
                  onPressed: loading
                      ? null
                      : () => _execDownloadSdk(item, setDialogState),
                  child: loading
                      ? Text(AppLocalizations.of(context)!.dialogLoaidng)
                      : Text(AppLocalizations.of(context)!.dialogConfirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _execDownloadSdk(
    NodeVersionEntity item,
    Function setDialogState,
  ) async {
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
    setDialogState(() {
      loading = true;
    });
    MyDioResponse myResponse = await HttpUtil()
        .download(
          tarSdkUrl,
          tempFilePath,
          onReceiveProgress: (count, total) {
            if (total != -1) {
              setDialogState(() {
                progress = (count / total) * 10;
              });
            }
          },
        )
        .whenComplete(() {
          setDialogState(() {
            loading = false;
          });
        });
    if (myResponse.ok) {
      try {
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
        if (mounted) {
          SmartDialog.showToast(AppLocalizations.of(context)!.pullSuccess);
        }
      } catch (exc) {
        if (mounted) {
          SmartDialog.showToast(AppLocalizations.of(context)!.publicError);
        }
      }
    } else {
      debugPrint(myResponse.exc?.message);
      if (mounted) {
        SmartDialog.showToast(AppLocalizations.of(context)!.publicError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(height: 1),
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.colVersion,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.colV8Version,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.colNpmVersion,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.colReleaseDate,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                VerticalDivider(width: 1),
                SizedBox(
                  width: 120,
                  child: Text(
                    AppLocalizations.of(context)!.colOperation,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _nodeVersionList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _nodeVersionList[index];
                return Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.version ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.v8 ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.npm ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.date ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: FilledButton(
                          onPressed: () {
                            _showVersionDetailDialog(context, index);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.colDownloadBtn,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

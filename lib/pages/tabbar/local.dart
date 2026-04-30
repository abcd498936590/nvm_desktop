import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:nvm_desktop/entity/remote_version.dart';
import 'package:nvm_desktop/interface/refresh.dart';
import 'package:nvm_desktop/l10n/app_localizations.dart';
import 'package:nvm_desktop/utils/env.dart';
import 'package:nvm_desktop/utils/path.dart';
import 'package:path/path.dart' as p;

class LocalTabBar extends StatefulWidget {
  const LocalTabBar({super.key});

  @override
  State<LocalTabBar> createState() => LocalTabBarState();
}

class LocalTabBarState extends RefreshableState<LocalTabBar>
    with AutomaticKeepAliveClientMixin {
  List<NodeVersionEntity> _nodeVersionList = [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  // 卸载对应的版本
  Future<void> _unInstallTarVersion(int index) async {
    String version = _nodeVersionList[index].version!;
    debugPrint("删除软连接和对应版本");
    EnvManager.deleteNodeVersion(version)
        .then((_) {
          if (mounted) {
            SmartDialog.showToast(AppLocalizations.of(context)!.deleteSuccess);
          }
          refresh();
        })
        .catchError((_) {
          if (mounted) {
            SmartDialog.showToast(AppLocalizations.of(context)!.publicError);
          }
        });
  }

  // 安装对应的版本，使用软连接，并检查是否有bin目录
  Future<void> _installTarVersion(int index) async {
    // 检查是否存在bin目录，不存在则创建，并且用户path注入环境变量
    if (!await EnvManager.checkIsInPath()) {
      EnvManager.injectPath();
    }
    // 切换软连接到对应的版本
    await EnvManager.switchNodeVersion(_nodeVersionList[index].version!, () {
      if (mounted) {
        SmartDialog.showToast(
          AppLocalizations.of(context)!.versionSwitchSuccess,
        );
      }
    });
  }

  // 读取本地已经下载下来的所有版本
  Future<List<NodeVersionEntity>> _getFirstLevelFolderNames(
    String versionDirPath,
  ) async {
    Directory rootDir = Directory(versionDirPath);
    List<NodeVersionEntity> refreshVersionList = [];
    await for (FileSystemEntity entity in rootDir.list(recursive: false)) {
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

  @override
  Future<void> refresh() async {
    String supportDirPath = await PathManager.getDirPath("versions");
    if (mounted) {
      SmartDialog.showLoading(msg: AppLocalizations.of(context)!.pullLoading);
    }
    await Future.delayed(Duration(milliseconds: 300));
    await _getFirstLevelFolderNames(supportDirPath)
        .then((newValue) {
          setState(() {
            _nodeVersionList = newValue;
          });
        })
        .whenComplete(() {
          SmartDialog.dismiss(status: SmartStatus.loading);
        });
    setState(() {});
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
            width: double.infinity,
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
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.colFrameWork,
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
                      Expanded(
                        child: Text(
                          item.framework?.split("-")[1] ?? "未知",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: SelectButtonGroup(
                          leftText: AppLocalizations.of(context)!.colInstallBtn,
                          rightText: AppLocalizations.of(context)!.colDeleteBtn,
                          leftCb: () {
                            _installTarVersion(index);
                          },
                          rightCb: () {
                            _unInstallTarVersion(index);
                          },
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

class SelectButtonGroup extends StatelessWidget {
  final String leftText;
  final String rightText;
  final VoidCallback leftCb;
  final VoidCallback rightCb;
  const SelectButtonGroup({
    super.key,
    required this.leftText,
    required this.rightText,
    required this.leftCb,
    required this.rightCb,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧按钮
        Expanded(
          child: FilledButton.tonal(
            onPressed: leftCb,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              // 只保留左侧圆角，右侧设为 0
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ),
            child: Text(leftText),
          ),
        ),
        // 中间的缝隙线（可选，如果两个颜色一样，加个细线区分更好）
        Container(
          width: 1,
          height: 24,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        // 右侧按钮
        Expanded(
          child: FilledButton.tonal(
            onPressed: rightCb,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              // 只保留右侧圆角，左侧设为 0
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
            ),
            child: Text(rightText),
          ),
        ),
      ],
    );
  }
}

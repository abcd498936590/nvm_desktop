import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:nvm_desktop/entity/remote_version.dart';
import 'package:nvm_desktop/interface/refresh.dart';
import 'package:nvm_desktop/l10n/app_localizations.dart';
import 'package:nvm_desktop/model/config.dart';
import 'package:nvm_desktop/request/dio_client.dart';
import 'package:nvm_desktop/request/http_response.dart';
import 'package:nvm_desktop/utils/config.dart';
import 'package:nvm_desktop/utils/path.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  Future<void> refresh() async {
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

  void _execDownloadSdk(NodeVersionEntity item, Function setDialogState) {
    AppPathConfig? pathConf = context.read<AppConfigProvider>().appPathConfig;
    // 每个版本自身的保存路径
    String itemSavePath = p.join(pathConf!.versionsDirPath, item.version);
    // 不同平台对应的文件名称
    String platFormFileName = PathManager.getVersionFileName(
      item.version ?? "",
    );
    String tempFilePath = p.join(pathConf.distDirPath, platFormFileName);
    PathManager.downloadSdk(
          item: item,
          curFrameWork: curFrameWork,
          downloadStartCallback: () {
            setDialogState(() {
              loading = true;
            });
          },
          receiveProgressCallback: (int count, int total) {
            if (total != -1) {
              setDialogState(() {
                progress = count / total;
              });
            }
          },
          downloadCompleteCallback: () {
            setDialogState(() {
              loading = false;
            });
          },
        )
        .then((MyDioResponse myRes) {
          if (myRes.ok) {
            PathManager.arrange(
              item: item,
              savePath: itemSavePath,
              curFrameWork: curFrameWork,
              tempFilePath: tempFilePath,
              finishCallback: () {
                if (mounted) {
                  SmartDialog.showToast(
                    AppLocalizations.of(context)!.pullSuccess,
                  );
                }
              },
            );
          } else {}
        })
        .catchError((_) {
          if (mounted) {
            SmartDialog.showToast(AppLocalizations.of(context)!.publicError);
          }
        });
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

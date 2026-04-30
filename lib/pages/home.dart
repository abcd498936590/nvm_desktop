import 'package:flutter/material.dart';
import 'package:nvm_desktop/interface/refresh.dart';
import 'package:nvm_desktop/l10n/app_localizations.dart';
import 'package:nvm_desktop/nodel/config.dart';
import 'package:nvm_desktop/pages/tabbar/local.dart';
import 'package:nvm_desktop/pages/tabbar/remote.dart';
import 'package:nvm_desktop/utils/config.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _keyList = [
    GlobalKey<RefreshableState>(debugLabel: "remote"),
    GlobalKey<RefreshableState>(debugLabel: "local"),
  ];
  late TabController _tabController;

  void refresh(int keyIdx) {
    _keyList[keyIdx].currentState?.refresh();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _keyList.length, vsync: this)
      ..addListener(() {
        // 本地单独执行刷新，每次切换 1=>本地
        if (_tabController.index == 1) {
          refresh(1);
        }
      });
    setState(() {});
  }

  // 系统设置
  void _showSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.dialogSettingTitle),
              content: SizedBox(
                width: 300,
                height: 150,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.dialogSelectLanguage}：",
                          style: TextStyle(fontSize: 17),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: DropdownButton<String>(
                            value:
                                Provider.of<AppConfigProvider>(
                                  context,
                                ).locale?.languageCode ??
                                "en",
                            focusColor: Colors.transparent,
                            hint: Text(
                              AppLocalizations.of(
                                context,
                              )!.dialogSelectLanguage,
                            ), // 初始提示文字
                            isExpanded: true, // 让下拉框占满横向空间
                            underline: Container(
                              height: 2,
                              color: Colors.blue,
                            ), // 自定义下划线
                            items: languageEnum.map<DropdownMenuItem<String>>((
                              it,
                            ) {
                              return DropdownMenuItem<String>(
                                value: it.value,
                                child: Text(it.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              debugPrint("用户选择了: $newValue");
                              Provider.of<AppConfigProvider>(
                                context,
                                listen: false,
                              ).setLocale(Locale(newValue!));
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.dialogSelectTheme}：",
                          style: TextStyle(fontSize: 17),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: DropdownButton<ThemeMode>(
                            value: Provider.of<AppConfigProvider>(
                              context,
                            ).themeMode,
                            focusColor: Colors.transparent,
                            hint: Text(
                              AppLocalizations.of(
                                context,
                              )!.dialogSelectLanguage,
                            ), // 初始提示文字
                            isExpanded: true, // 让下拉框占满横向空间
                            underline: Container(
                              height: 2,
                              color: Colors.blue,
                            ), // 自定义下划线
                            items:
                                [
                                  EnumOptionItem<ThemeMode>(
                                    AppLocalizations.of(
                                      context,
                                    )!.optsItemThemeSystem,
                                    ThemeMode.system,
                                  ),
                                  EnumOptionItem<ThemeMode>(
                                    AppLocalizations.of(
                                      context,
                                    )!.optsItemThemeLight,
                                    ThemeMode.light,
                                  ),
                                  EnumOptionItem<ThemeMode>(
                                    AppLocalizations.of(
                                      context,
                                    )!.optsItemThemeDark,
                                    ThemeMode.dark,
                                  ),
                                ].map<DropdownMenuItem<ThemeMode>>((it) {
                                  return DropdownMenuItem<ThemeMode>(
                                    value: it.value,
                                    child: Text(it.name),
                                  );
                                }).toList(),
                            onChanged: (ThemeMode? newValue) {
                              debugPrint("用户选择了: $newValue");
                              Provider.of<AppConfigProvider>(
                                context,
                                listen: false,
                              ).setThemeMode(newValue!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.dialogClose),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: _keyList.length,
      child: Scaffold(
        appBar: AppBar(
          actionsPadding: EdgeInsets.only(right: 20),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                refresh(_tabController.index);
              },
              icon: Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () {
                _showSettingDialog(context);
              },
              icon: Icon(Icons.settings),
            ),
          ],
          title: TabBar(
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            isScrollable: true,
            controller: _tabController,
            tabs:
                [
                  AppLocalizations.of(context)!.allVersion,
                  AppLocalizations.of(context)!.localVersion,
                ].map((it) {
                  return Tab(text: it);
                }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            RemoteTabBar(key: _keyList[0]),
            LocalTabBar(key: _keyList[1]),
          ],
        ),
      ),
    );
  }
}

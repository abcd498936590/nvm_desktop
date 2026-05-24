const String remoteUrl = "https://nodejs.org";

const String remoteVersionUrl = "$remoteUrl/dist/index.json";

const Map<String, List<String>> platFormAndFreameWork = {
  "windows": ["win-x64-zip"],
  "macos": ["osx-x64-tar", "osx-arm64-tar"],
};

class EnumOptionItem<T> {
  late String name;
  late T value;
  EnumOptionItem(this.name, this.value);
}

final List<EnumOptionItem<String>> languageEnum = [
  EnumOptionItem<String>("English", "en"),
  EnumOptionItem<String>("中文", "zh"),
];

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @allVersion.
  ///
  /// In en, this message translates to:
  /// **'all versions'**
  String get allVersion;

  /// No description provided for @localVersion.
  ///
  /// In en, this message translates to:
  /// **'local'**
  String get localVersion;

  /// No description provided for @colVersion.
  ///
  /// In en, this message translates to:
  /// **'version'**
  String get colVersion;

  /// No description provided for @colV8Version.
  ///
  /// In en, this message translates to:
  /// **'v8 version'**
  String get colV8Version;

  /// No description provided for @colNpmVersion.
  ///
  /// In en, this message translates to:
  /// **'npm version'**
  String get colNpmVersion;

  /// No description provided for @colReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'release date'**
  String get colReleaseDate;

  /// No description provided for @colOperation.
  ///
  /// In en, this message translates to:
  /// **'operation'**
  String get colOperation;

  /// No description provided for @colFrameWork.
  ///
  /// In en, this message translates to:
  /// **'framework'**
  String get colFrameWork;

  /// No description provided for @colDownloadBtn.
  ///
  /// In en, this message translates to:
  /// **'download'**
  String get colDownloadBtn;

  /// No description provided for @colInstallBtn.
  ///
  /// In en, this message translates to:
  /// **'install'**
  String get colInstallBtn;

  /// No description provided for @colDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get colDeleteBtn;

  /// No description provided for @dialogInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'install confirm'**
  String get dialogInstallTitle;

  /// No description provided for @dialogNodeVersion.
  ///
  /// In en, this message translates to:
  /// **'node'**
  String get dialogNodeVersion;

  /// No description provided for @dialogNpmVersion.
  ///
  /// In en, this message translates to:
  /// **'npm'**
  String get dialogNpmVersion;

  /// No description provided for @dialogSelectFrameWork.
  ///
  /// In en, this message translates to:
  /// **'framework'**
  String get dialogSelectFrameWork;

  /// No description provided for @dialogDownloadProgress.
  ///
  /// In en, this message translates to:
  /// **'progress'**
  String get dialogDownloadProgress;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get dialogConfirm;

  /// No description provided for @dialogLoaidng.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get dialogLoaidng;

  /// No description provided for @dialogClose.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get dialogClose;

  /// No description provided for @dialogSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'system setting'**
  String get dialogSettingTitle;

  /// No description provided for @dialogSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'language'**
  String get dialogSelectLanguage;

  /// No description provided for @dialogSelectTheme.
  ///
  /// In en, this message translates to:
  /// **'theme'**
  String get dialogSelectTheme;

  /// No description provided for @optsItemThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'follow system'**
  String get optsItemThemeSystem;

  /// No description provided for @optsItemThemeLight.
  ///
  /// In en, this message translates to:
  /// **'light'**
  String get optsItemThemeLight;

  /// No description provided for @optsItemThemeDark.
  ///
  /// In en, this message translates to:
  /// **'dark'**
  String get optsItemThemeDark;

  /// No description provided for @pullLoading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get pullLoading;

  /// No description provided for @pullSuccess.
  ///
  /// In en, this message translates to:
  /// **'download success'**
  String get pullSuccess;

  /// No description provided for @publicError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get publicError;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'delete success'**
  String get deleteSuccess;

  /// No description provided for @versionSwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'switch success'**
  String get versionSwitchSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

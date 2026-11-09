import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
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
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// No description provided for @unreadableProject.
  ///
  /// In en, this message translates to:
  /// **'Unreadable project: {name}'**
  String unreadableProject(String name);

  /// No description provided for @emptyHintWindows.
  ///
  /// In en, this message translates to:
  /// **'Turn HTML files, a website ZIP, or a live https website into an Android or Windows app. Builds happen on this device.'**
  String get emptyHintWindows;

  /// No description provided for @emptyHintAndroid.
  ///
  /// In en, this message translates to:
  /// **'Turn HTML files, a website ZIP, or a live https website into an Android app. Builds happen on this device.'**
  String get emptyHintAndroid;

  /// No description provided for @notBuiltYet.
  ///
  /// In en, this message translates to:
  /// **'v{version} · not built yet'**
  String notBuiltYet(String version);

  /// No description provided for @lastBuild.
  ///
  /// In en, this message translates to:
  /// **'v{version} · last build {status} {ago}'**
  String lastBuild(String version, String status, String ago);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String daysAgo(int n);

  /// No description provided for @chooseBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a {ext} backup file'**
  String chooseBackupFile(String ext);

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Restored {name}'**
  String restored(String name);

  /// No description provided for @notUsableBackup.
  ///
  /// In en, this message translates to:
  /// **'Not a usable backup: {message}'**
  String notUsableBackup(String message);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @importedFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 file} other{Imported {count} files}}'**
  String importedFiles(int count);

  /// No description provided for @startPageIs.
  ///
  /// In en, this message translates to:
  /// **'Start page: {page}'**
  String startPageIs(String page);

  /// No description provided for @htmlPagesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} HTML pages found; you can change the start page in Settings.'**
  String htmlPagesFound(int count);

  /// No description provided for @filesMissing.
  ///
  /// In en, this message translates to:
  /// **'{count} referenced files are missing:'**
  String filesMissing(int count);

  /// No description provided for @andMore.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String andMore(int count);

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found: {path}'**
  String fileNotFound(String path);

  /// No description provided for @wouldOpenOutside.
  ///
  /// In en, this message translates to:
  /// **'Would open outside the app: {url}'**
  String wouldOpenOutside(String url);

  /// No description provided for @pageFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Page failed to load: {description} ({url})'**
  String pageFailedToLoad(String description, String url);

  /// No description provided for @couldNotStartPreview.
  ///
  /// In en, this message translates to:
  /// **'Could not start the preview: {error}'**
  String couldNotStartPreview(String error);

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview · {name}'**
  String previewTitle(String name);

  /// No description provided for @websiteAnsweredHttp.
  ///
  /// In en, this message translates to:
  /// **'Website answered with HTTP {code}'**
  String websiteAnsweredHttp(int code);

  /// No description provided for @redirected.
  ///
  /// In en, this message translates to:
  /// **'Redirected {count}× — the app will start at this address.'**
  String redirected(int count);

  /// No description provided for @importedKey.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{alias}\"'**
  String importedKey(String alias);

  /// No description provided for @backupSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Backup saved as {alias}.jks. Keep the password with it, separately.'**
  String backupSavedAs(String alias);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @deletedKey.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{alias}\" from this device'**
  String deletedKey(String alias);

  /// No description provided for @releaseKeysIntroWindows.
  ///
  /// In en, this message translates to:
  /// **'Release builds are signed with one of these keys. Google Play and Android only accept updates signed with the same key as the first release. Keys stay on this PC, with passwords encrypted for your Windows account; a backup is a password-protected .jks file that works with iLoveHTML on a phone or a computer, Gradle and keytool.'**
  String get releaseKeysIntroWindows;

  /// No description provided for @releaseKeysIntroAndroid.
  ///
  /// In en, this message translates to:
  /// **'Release builds are signed with one of these keys. Google Play and Android only accept updates signed with the same key as the first release. Keys stay on this phone, encrypted with Android Keystore; a backup is a password-protected .jks file that works with iLoveHTML on a phone or a computer, Gradle and keytool.'**
  String get releaseKeysIntroAndroid;

  /// No description provided for @validUntilDate.
  ///
  /// In en, this message translates to:
  /// **'valid until {date}'**
  String validUntilDate(String date);

  /// No description provided for @atLeast8.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8;

  /// No description provided for @deleteKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Apps signed with \"{alias}\" can only be updated with this exact key. Without a backup, you will never be able to update them again.'**
  String deleteKeyBody(String alias);

  /// No description provided for @typeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"{alias}\" to confirm'**
  String typeToConfirm(String alias);

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved: {file}'**
  String backupSaved(String file);

  /// No description provided for @shortcutExists.
  ///
  /// In en, this message translates to:
  /// **'A shortcut for \"{page}\" already exists'**
  String shortcutExists(String page);

  /// No description provided for @deleteProjectBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes \"{name}\", its website files and built APKs from this device. Apps already installed are not affected.'**
  String deleteProjectBody(String name);

  /// No description provided for @offlinePageShown.
  ///
  /// In en, this message translates to:
  /// **'When the site cannot load, your page \"{page}\" is shown. Link to https://appassets.androidplatform.net/html2apk/retry for a \"Try again\" button.'**
  String offlinePageShown(String page);

  /// No description provided for @downloadedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloaded 1 time.} other{Downloaded {count} times.}}'**
  String downloadedTimes(int count);

  /// No description provided for @couldNotReadFiles.
  ///
  /// In en, this message translates to:
  /// **'Could not read the files: {error}'**
  String couldNotReadFiles(String error);

  /// No description provided for @filesAndSize.
  ///
  /// In en, this message translates to:
  /// **'{count} files, {size}'**
  String filesAndSize(int count, String size);

  /// No description provided for @checkFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed: {error}'**
  String checkFailed(String error);

  /// No description provided for @optimizeResult.
  ///
  /// In en, this message translates to:
  /// **'Optimizing makes {count} files smaller and saves {saved} ({before} → {after}). The APK is compressed too, so the APK saving is often smaller for CSS and JSON.'**
  String optimizeResult(int count, String saved, String before, String after);

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String example(String value);

  /// No description provided for @couldNotLoadKeys.
  ///
  /// In en, this message translates to:
  /// **'Could not load release keys: {error}'**
  String couldNotLoadKeys(String error);

  /// No description provided for @differentKeyBody.
  ///
  /// In en, this message translates to:
  /// **'This app was first released with a different key (SHA-256 {sha}…). Phones that installed that release cannot update to an APK signed with \"{alias}\", and Google Play will reject it as an update.'**
  String differentKeyBody(String sha, String alias);

  /// No description provided for @publisherValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Publisher: {publisher} · valid until {date}'**
  String publisherValidUntil(String publisher, String date);

  /// No description provided for @replaceCertBody.
  ///
  /// In en, this message translates to:
  /// **'Apps installed from installers signed by \"{publisher}\" update only from installers with the same publisher name. Back up the current certificate first if you may need it.'**
  String replaceCertBody(String publisher);

  /// No description provided for @passwordOf.
  ///
  /// In en, this message translates to:
  /// **'Password of {file}'**
  String passwordOf(String file);

  /// No description provided for @savedFile.
  ///
  /// In en, this message translates to:
  /// **'Saved {file}'**
  String savedFile(String file);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @cannotBuildYet.
  ///
  /// In en, this message translates to:
  /// **'Cannot build yet:'**
  String get cannotBuildYet;

  /// No description provided for @shareFilesHint.
  ///
  /// In en, this message translates to:
  /// **'navigator.share() with files sends images and PDFs to other apps. On Android 10+ shared images are also saved to the gallery.'**
  String get shareFilesHint;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackup;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @newApp.
  ///
  /// In en, this message translates to:
  /// **'New app'**
  String get newApp;

  /// No description provided for @htmlFiles.
  ///
  /// In en, this message translates to:
  /// **'HTML files'**
  String get htmlFiles;

  /// No description provided for @htmlFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an .html page, plus its CSS, JavaScript and images if they are separate files. Works offline.'**
  String get htmlFilesHint;

  /// No description provided for @websiteZip.
  ///
  /// In en, this message translates to:
  /// **'Website ZIP'**
  String get websiteZip;

  /// No description provided for @websiteZipHint.
  ///
  /// In en, this message translates to:
  /// **'A whole website folder, zipped. Works offline.'**
  String get websiteZipHint;

  /// No description provided for @websiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get websiteUrl;

  /// No description provided for @websiteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Wrap a live https website. Needs an internet connection.'**
  String get websiteUrlHint;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building…'**
  String get building;

  /// No description provided for @selectHtmlFile.
  ///
  /// In en, this message translates to:
  /// **'Select at least one .html file, plus any CSS, JavaScript or images it uses.'**
  String get selectHtmlFile;

  /// No description provided for @defaultAppName.
  ///
  /// In en, this message translates to:
  /// **'My App'**
  String get defaultAppName;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get appName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @packageId.
  ///
  /// In en, this message translates to:
  /// **'Package ID'**
  String get packageId;

  /// No description provided for @packageIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Unique ID on the device and in Play, e.g. com.yourname.app'**
  String get packageIdHelp;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @noMissingFiles.
  ///
  /// In en, this message translates to:
  /// **'No missing files found'**
  String get noMissingFiles;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get openProject;

  /// No description provided for @noConsoleMessages.
  ///
  /// In en, this message translates to:
  /// **'No console messages or issues'**
  String get noConsoleMessages;

  /// No description provided for @viewport.
  ///
  /// In en, this message translates to:
  /// **'Viewport'**
  String get viewport;

  /// No description provided for @consoleAndIssues.
  ///
  /// In en, this message translates to:
  /// **'Console and issues'**
  String get consoleAndIssues;

  /// No description provided for @checkWebsite.
  ///
  /// In en, this message translates to:
  /// **'Check website'**
  String get checkWebsite;

  /// No description provided for @websiteReachable.
  ///
  /// In en, this message translates to:
  /// **'Website reachable'**
  String get websiteReachable;

  /// No description provided for @liveSiteNote.
  ///
  /// In en, this message translates to:
  /// **'The app shows this site live and needs an internet connection. It does not work offline.'**
  String get liveSiteNote;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @backUpKeyNow.
  ///
  /// In en, this message translates to:
  /// **'Back up this key now'**
  String get backUpKeyNow;

  /// No description provided for @backUpKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Every update of an app must be signed with the same key. If this device is lost or iLoveHTML is uninstalled, the key is gone unless you have a backup.\n\nSave the .jks file somewhere safe (not only on this device) and keep the password separately.'**
  String get backUpKeyBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackup;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @sha256Fingerprint.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get sha256Fingerprint;

  /// No description provided for @sha1Fingerprint.
  ///
  /// In en, this message translates to:
  /// **'SHA-1 fingerprint'**
  String get sha1Fingerprint;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get validUntil;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @saveBackupJks.
  ///
  /// In en, this message translates to:
  /// **'Save backup (.jks)'**
  String get saveBackupJks;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @releaseKeys.
  ///
  /// In en, this message translates to:
  /// **'Release keys'**
  String get releaseKeys;

  /// No description provided for @createKey.
  ///
  /// In en, this message translates to:
  /// **'Create key'**
  String get createKey;

  /// No description provided for @importKeystoreFile.
  ///
  /// In en, this message translates to:
  /// **'Import .jks / .keystore / .p12'**
  String get importKeystoreFile;

  /// No description provided for @noReleaseKeys.
  ///
  /// In en, this message translates to:
  /// **'No release keys yet'**
  String get noReleaseKeys;

  /// No description provided for @createReleaseKey.
  ///
  /// In en, this message translates to:
  /// **'Create release key'**
  String get createReleaseKey;

  /// No description provided for @keyAlias.
  ///
  /// In en, this message translates to:
  /// **'Key alias'**
  String get keyAlias;

  /// No description provided for @keyAliasHelp.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, dots, dashes, underscores'**
  String get keyAliasHelp;

  /// No description provided for @publisherNameField.
  ///
  /// In en, this message translates to:
  /// **'Your name or app publisher'**
  String get publisherNameField;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @organizationOptional.
  ///
  /// In en, this message translates to:
  /// **'Organization (optional)'**
  String get organizationOptional;

  /// No description provided for @countryCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Country code (optional)'**
  String get countryCodeOptional;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHelp.
  ///
  /// In en, this message translates to:
  /// **'Used for the keystore and the key'**
  String get passwordHelp;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repeatPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @createKeyNote.
  ///
  /// In en, this message translates to:
  /// **'RSA 2048-bit, valid for 30 years. You will need this password to use the backup on a computer.'**
  String get createKeyNote;

  /// No description provided for @noPrivateKeys.
  ///
  /// In en, this message translates to:
  /// **'No private keys in this file'**
  String get noPrivateKeys;

  /// No description provided for @importKeystore.
  ///
  /// In en, this message translates to:
  /// **'Import keystore'**
  String get importKeystore;

  /// No description provided for @keystorePassword.
  ///
  /// In en, this message translates to:
  /// **'Keystore password'**
  String get keystorePassword;

  /// No description provided for @keyPassword.
  ///
  /// In en, this message translates to:
  /// **'Key password'**
  String get keyPassword;

  /// No description provided for @keyPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if it is the same as the keystore password'**
  String get keyPasswordHelp;

  /// No description provided for @importKeystoreNote.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML keeps a copy protected by the keystore password. Your original file is not changed.'**
  String get importKeystoreNote;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @deleteReleaseKey.
  ///
  /// In en, this message translates to:
  /// **'Delete release key?'**
  String get deleteReleaseKey;

  /// No description provided for @deleteKey.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get deleteKey;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @backUpProject.
  ///
  /// In en, this message translates to:
  /// **'Back up project'**
  String get backUpProject;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @previewInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Preview in your browser'**
  String get previewInBrowser;

  /// No description provided for @liveSiteOpened.
  ///
  /// In en, this message translates to:
  /// **'The live site opened in your default browser.'**
  String get liveSiteOpened;

  /// No description provided for @servedFromPc.
  ///
  /// In en, this message translates to:
  /// **'Served from this PC only, while this window is open. The phone app adds a console and link checks; here use the browser\'s developer tools (F12).'**
  String get servedFromPc;

  /// No description provided for @missingFiles.
  ///
  /// In en, this message translates to:
  /// **'Missing files:'**
  String get missingFiles;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @stopPreview.
  ///
  /// In en, this message translates to:
  /// **'Stop preview'**
  String get stopPreview;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @iconUpdated.
  ///
  /// In en, this message translates to:
  /// **'Icon updated'**
  String get iconUpdated;

  /// No description provided for @splashUpdated.
  ///
  /// In en, this message translates to:
  /// **'Splash image updated'**
  String get splashUpdated;

  /// No description provided for @offlinePageAdded.
  ///
  /// In en, this message translates to:
  /// **'Offline page added'**
  String get offlinePageAdded;

  /// No description provided for @deleteProjectQ.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get deleteProjectQ;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @sectionContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get sectionContent;

  /// No description provided for @sectionShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get sectionShortcuts;

  /// No description provided for @sectionAppSize.
  ///
  /// In en, this message translates to:
  /// **'App size'**
  String get sectionAppSize;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get sectionDevices;

  /// No description provided for @sectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sectionSecurity;

  /// No description provided for @sectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get sectionOffline;

  /// No description provided for @sectionDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get sectionDanger;

  /// No description provided for @versionName.
  ///
  /// In en, this message translates to:
  /// **'Version name'**
  String get versionName;

  /// No description provided for @versionCode.
  ///
  /// In en, this message translates to:
  /// **'Version code'**
  String get versionCode;

  /// No description provided for @defaultIcon.
  ///
  /// In en, this message translates to:
  /// **'Default icon'**
  String get defaultIcon;

  /// No description provided for @customIcon.
  ///
  /// In en, this message translates to:
  /// **'Custom icon'**
  String get customIcon;

  /// No description provided for @chooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseImage;

  /// No description provided for @iconHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPEG, WebP, GIF, BMP or SVG, at least 48 px; 512 × 512 recommended. Non-square images are centred.'**
  String get iconHint;

  /// No description provided for @startPage.
  ///
  /// In en, this message translates to:
  /// **'Start page'**
  String get startPage;

  /// No description provided for @loadedLive.
  ///
  /// In en, this message translates to:
  /// **'Loaded live; the app needs an internet connection.'**
  String get loadedLive;

  /// No description provided for @otherSites.
  ///
  /// In en, this message translates to:
  /// **'Other sites that open inside the app (optional)'**
  String get otherSites;

  /// No description provided for @otherSitesHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated. Links to any other site open in the browser.'**
  String get otherSitesHelp;

  /// No description provided for @bridgeSites.
  ///
  /// In en, this message translates to:
  /// **'Sites that can also share, save files and notify (optional)'**
  String get bridgeSites;

  /// No description provided for @bridgeSitesHelp.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, from the list above. Your own site always can. Leave login and payment sites out.'**
  String get bridgeSitesHelp;

  /// No description provided for @bridgeSiteNotListed.
  ///
  /// In en, this message translates to:
  /// **'\"{host}\" is not in the list above'**
  String bridgeSiteNotListed(String host);

  /// No description provided for @orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation;

  /// No description provided for @orientationAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get orientationAuto;

  /// No description provided for @portrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait'**
  String get portrait;

  /// No description provided for @landscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape'**
  String get landscape;

  /// No description provided for @shortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press the app icon to see these pages.'**
  String get shortcutsHint;

  /// No description provided for @removeShortcut.
  ///
  /// In en, this message translates to:
  /// **'Remove shortcut'**
  String get removeShortcut;

  /// No description provided for @addShortcut.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut'**
  String get addShortcut;

  /// No description provided for @optimizeFiles.
  ///
  /// In en, this message translates to:
  /// **'Optimize files when building'**
  String get optimizeFiles;

  /// No description provided for @optimizeFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Makes CSS, JSON, PNG and large JPEG files smaller in the app. JPEGs are saved again at 85% quality. Your project files do not change.'**
  String get optimizeFilesHint;

  /// No description provided for @sizeReport.
  ///
  /// In en, this message translates to:
  /// **'Size report'**
  String get sizeReport;

  /// No description provided for @statusBarColour.
  ///
  /// In en, this message translates to:
  /// **'Status bar colour'**
  String get statusBarColour;

  /// No description provided for @navBarColour.
  ///
  /// In en, this message translates to:
  /// **'Navigation bar colour'**
  String get navBarColour;

  /// No description provided for @splashScreen.
  ///
  /// In en, this message translates to:
  /// **'Splash screen'**
  String get splashScreen;

  /// No description provided for @splashIconHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the app icon until the first page has loaded.'**
  String get splashIconHint;

  /// No description provided for @splashImageHint.
  ///
  /// In en, this message translates to:
  /// **'Shows your splash image until the first page has loaded.'**
  String get splashImageHint;

  /// No description provided for @splashBackground.
  ///
  /// In en, this message translates to:
  /// **'Splash background'**
  String get splashBackground;

  /// No description provided for @chooseSplash.
  ///
  /// In en, this message translates to:
  /// **'Choose splash image'**
  String get chooseSplash;

  /// No description provided for @replaceSplash.
  ///
  /// In en, this message translates to:
  /// **'Replace splash image'**
  String get replaceSplash;

  /// No description provided for @useAppIcon.
  ///
  /// In en, this message translates to:
  /// **'Use app icon'**
  String get useAppIcon;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @followPhone.
  ///
  /// In en, this message translates to:
  /// **'Follow phone'**
  String get followPhone;

  /// No description provided for @themeHint.
  ///
  /// In en, this message translates to:
  /// **'Sets prefers-color-scheme, so pages with dark-mode CSS switch to it.'**
  String get themeHint;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @fullscreenHint.
  ///
  /// In en, this message translates to:
  /// **'Hides the status and navigation bars. Swipe from the edge to show them for a moment.'**
  String get fullscreenHint;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOnHint.
  ///
  /// In en, this message translates to:
  /// **'The screen does not turn off while the app is open.'**
  String get keepScreenOnHint;

  /// No description provided for @tvHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the app on the TV home screen with a banner made from the icon and name. The remote\'s arrow keys move between links and buttons; OK opens them.'**
  String get tvHint;

  /// No description provided for @rotateTablets.
  ///
  /// In en, this message translates to:
  /// **'Rotate freely on tablets'**
  String get rotateTablets;

  /// No description provided for @rotateTabletsHint.
  ///
  /// In en, this message translates to:
  /// **'Tablets and foldables may turn to any side, even when phones keep the orientation chosen above. Android 16 and later always allow this on large screens.'**
  String get rotateTabletsHint;

  /// No description provided for @desktopLayout.
  ///
  /// In en, this message translates to:
  /// **'Desktop layout on tablets and TV'**
  String get desktopLayout;

  /// No description provided for @desktopLayoutHint.
  ///
  /// In en, this message translates to:
  /// **'Asks websites for the layout they show on computers instead of the phone layout.'**
  String get desktopLayoutHint;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// No description provided for @appLockHint.
  ///
  /// In en, this message translates to:
  /// **'Asks for the fingerprint, face or screen lock when the app opens, and after 30 seconds in the background. Phones without a screen lock open the app with a hint.'**
  String get appLockHint;

  /// No description provided for @javascriptHint.
  ///
  /// In en, this message translates to:
  /// **'Most sites need this. Turn off for static pages.'**
  String get javascriptHint;

  /// No description provided for @localStorage.
  ///
  /// In en, this message translates to:
  /// **'Local storage'**
  String get localStorage;

  /// No description provided for @internetAccess.
  ///
  /// In en, this message translates to:
  /// **'Internet access'**
  String get internetAccess;

  /// No description provided for @internetAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Adds the INTERNET permission, for CDNs, APIs or fonts loaded from the web.'**
  String get internetAccessHint;

  /// No description provided for @openOtherSites.
  ///
  /// In en, this message translates to:
  /// **'Open other sites in the browser'**
  String get openOtherSites;

  /// No description provided for @openOtherSitesHint.
  ///
  /// In en, this message translates to:
  /// **'When off, links to other sites do nothing.'**
  String get openOtherSitesHint;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @pullToRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe down at the top of a page to reload it, or to retry after an error.'**
  String get pullToRefreshHint;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsHint.
  ///
  /// In en, this message translates to:
  /// **'The page can use the web Notification API to show Android notifications while the app is open. Android 13+ asks the user first. No push messages.'**
  String get notificationsHint;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back button'**
  String get backButton;

  /// No description provided for @backHistory.
  ///
  /// In en, this message translates to:
  /// **'Go back, then close the app'**
  String get backHistory;

  /// No description provided for @backTwice.
  ///
  /// In en, this message translates to:
  /// **'Go back, then press twice to close'**
  String get backTwice;

  /// No description provided for @backConfirm.
  ///
  /// In en, this message translates to:
  /// **'Go back, then ask before closing'**
  String get backConfirm;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Go to the start page, then close'**
  String get backHome;

  /// No description provided for @fileUploads.
  ///
  /// In en, this message translates to:
  /// **'File uploads'**
  String get fileUploads;

  /// No description provided for @fileUploadsHint.
  ///
  /// In en, this message translates to:
  /// **'Lets file inputs open Android\'s file picker. The user chooses each file.'**
  String get fileUploadsHint;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareHint.
  ///
  /// In en, this message translates to:
  /// **'navigator.share opens Android\'s share sheet for text and links.'**
  String get shareHint;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsHint.
  ///
  /// In en, this message translates to:
  /// **'Download links and generated files are saved to the Downloads folder.'**
  String get downloadsHint;

  /// No description provided for @shareFiles.
  ///
  /// In en, this message translates to:
  /// **'Share images and PDFs'**
  String get shareFiles;

  /// No description provided for @galleryFolder.
  ///
  /// In en, this message translates to:
  /// **'Gallery folder (optional)'**
  String get galleryFolder;

  /// No description provided for @galleryFolderExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Photos'**
  String get galleryFolderExample;

  /// No description provided for @galleryFolderHelp.
  ///
  /// In en, this message translates to:
  /// **'Pictures/<folder> for shared and downloaded images. Empty: the app name for shares, Downloads for downloads.'**
  String get galleryFolderHelp;

  /// No description provided for @shareToApp.
  ///
  /// In en, this message translates to:
  /// **'Share straight to app (optional)'**
  String get shareToApp;

  /// No description provided for @shareToAppHelp.
  ///
  /// In en, this message translates to:
  /// **'Package that file shares open directly when installed, instead of the share sheet.'**
  String get shareToAppHelp;

  /// No description provided for @usePackageName.
  ///
  /// In en, this message translates to:
  /// **'Use a package name like com.whatsapp'**
  String get usePackageName;

  /// No description provided for @offlineBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'When the site cannot load, a built-in \"Page unavailable\" screen is shown.'**
  String get offlineBuiltIn;

  /// No description provided for @chooseOfflinePage.
  ///
  /// In en, this message translates to:
  /// **'Choose offline page (.html)'**
  String get chooseOfflinePage;

  /// No description provided for @replaceOfflinePage.
  ///
  /// In en, this message translates to:
  /// **'Replace offline page'**
  String get replaceOfflinePage;

  /// No description provided for @useBuiltInPage.
  ///
  /// In en, this message translates to:
  /// **'Use built-in page'**
  String get useBuiltInPage;

  /// No description provided for @userAgentSuffix.
  ///
  /// In en, this message translates to:
  /// **'User agent suffix (optional)'**
  String get userAgentSuffix;

  /// No description provided for @atMost200.
  ///
  /// In en, this message translates to:
  /// **'At most 200 characters'**
  String get atMost200;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @useColourLike.
  ///
  /// In en, this message translates to:
  /// **'Use a colour like #1A73E8'**
  String get useColourLike;

  /// No description provided for @noNetwork.
  ///
  /// In en, this message translates to:
  /// **'This computer is not on a Wi-Fi or Ethernet network.'**
  String get noNetwork;

  /// No description provided for @installOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Install on phone'**
  String get installOnPhone;

  /// No description provided for @installSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Connect the phone to the same Wi-Fi as this computer.\n2. Scan the code with the phone camera and open the link.\n3. Open the downloaded file. Allow installs from the browser if Android asks.'**
  String get installSteps;

  /// No description provided for @linkStopped.
  ///
  /// In en, this message translates to:
  /// **'The link has stopped.'**
  String get linkStopped;

  /// No description provided for @networkAddress.
  ///
  /// In en, this message translates to:
  /// **'Network address'**
  String get networkAddress;

  /// No description provided for @linkWorks10Min.
  ///
  /// In en, this message translates to:
  /// **'The link works for 10 minutes while this window is open.'**
  String get linkWorks10Min;

  /// No description provided for @trustedNetworkOnly.
  ///
  /// In en, this message translates to:
  /// **'Use this only on a network you trust. Windows may ask to allow iLoveHTML through the firewall: allow it for private networks.'**
  String get trustedNetworkOnly;

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @kindPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get kindPages;

  /// No description provided for @kindImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get kindImages;

  /// No description provided for @kindFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts'**
  String get kindFonts;

  /// No description provided for @kindMedia.
  ///
  /// In en, this message translates to:
  /// **'Audio and video'**
  String get kindMedia;

  /// No description provided for @kindData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get kindData;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindOther;

  /// No description provided for @largestFiles.
  ///
  /// In en, this message translates to:
  /// **'Largest files'**
  String get largestFiles;

  /// No description provided for @advice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get advice;

  /// No description provided for @checkOptimizing.
  ///
  /// In en, this message translates to:
  /// **'Check what optimizing saves'**
  String get checkOptimizing;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @exampleCart.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cart'**
  String get exampleCart;

  /// No description provided for @choosePage.
  ///
  /// In en, this message translates to:
  /// **'Choose a page'**
  String get choosePage;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @differentKey.
  ///
  /// In en, this message translates to:
  /// **'Different release key'**
  String get differentKey;

  /// No description provided for @buildAnyway.
  ///
  /// In en, this message translates to:
  /// **'Build anyway'**
  String get buildAnyway;

  /// No description provided for @windowsExe.
  ///
  /// In en, this message translates to:
  /// **'Windows app (.exe)'**
  String get windowsExe;

  /// No description provided for @exeDescription.
  ///
  /// In en, this message translates to:
  /// **'One .exe file that opens this site in its own window with Microsoft Edge WebView2 (built into Windows 11 and updated Windows 10). It is not code-signed, so Windows may show \"Windows protected your PC\" until people choose More info → Run anyway.'**
  String get exeDescription;

  /// No description provided for @devTools.
  ///
  /// In en, this message translates to:
  /// **'Developer tools (for testing)'**
  String get devTools;

  /// No description provided for @devToolsHint.
  ///
  /// In en, this message translates to:
  /// **'F12 and Inspect work in the app; leave off for the version you share'**
  String get devToolsHint;

  /// No description provided for @buildExe.
  ///
  /// In en, this message translates to:
  /// **'Build .exe'**
  String get buildExe;

  /// No description provided for @windowsMsix.
  ///
  /// In en, this message translates to:
  /// **'Windows installer (.msix)'**
  String get windowsMsix;

  /// No description provided for @msixDescription.
  ///
  /// In en, this message translates to:
  /// **'Installs the app like other Windows software: Start menu entry, clean uninstall, and updates when you share a higher version. Every installer is signed with a certificate.'**
  String get msixDescription;

  /// No description provided for @needsWindowsSdk.
  ///
  /// In en, this message translates to:
  /// **'Needs the Windows SDK. Install it with:\nwinget install Microsoft.WindowsSDK.10.0.26100'**
  String get needsWindowsSdk;

  /// No description provided for @noCertificate.
  ///
  /// In en, this message translates to:
  /// **'No certificate yet. Use your own code-signing certificate, or create a test certificate to try it.'**
  String get noCertificate;

  /// No description provided for @testCertNote.
  ///
  /// In en, this message translates to:
  /// **'Test certificate: Windows installs the app only after people trust it once. Share the .cer file next to the installer; people double-click it → Install Certificate → Local Machine → \"Trusted People\". A certificate bought from a certificate authority needs no such step.'**
  String get testCertNote;

  /// No description provided for @createTestCert.
  ///
  /// In en, this message translates to:
  /// **'Create test certificate'**
  String get createTestCert;

  /// No description provided for @useMyPfx.
  ///
  /// In en, this message translates to:
  /// **'Use my .pfx'**
  String get useMyPfx;

  /// No description provided for @savedCertificate.
  ///
  /// In en, this message translates to:
  /// **'Saved the certificate'**
  String get savedCertificate;

  /// No description provided for @saveCer.
  ///
  /// In en, this message translates to:
  /// **'Save .cer'**
  String get saveCer;

  /// No description provided for @buildInstaller.
  ///
  /// In en, this message translates to:
  /// **'Build installer'**
  String get buildInstaller;

  /// No description provided for @replaceCertQ.
  ///
  /// In en, this message translates to:
  /// **'Replace the certificate?'**
  String get replaceCertQ;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @publisherName.
  ///
  /// In en, this message translates to:
  /// **'Publisher name'**
  String get publisherName;

  /// No description provided for @publisherNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown as the publisher when people install your apps.'**
  String get publisherNameHelp;

  /// No description provided for @testCertCreated.
  ///
  /// In en, this message translates to:
  /// **'Test certificate created'**
  String get testCertCreated;

  /// No description provided for @useMyCertificate.
  ///
  /// In en, this message translates to:
  /// **'Use my certificate'**
  String get useMyCertificate;

  /// No description provided for @certificateAdded.
  ///
  /// In en, this message translates to:
  /// **'Certificate added'**
  String get certificateAdded;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @allowUnknownApps.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Install unknown apps\" for iLoveHTML in the screen that opened, then tap Install again.'**
  String get allowUnknownApps;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @debugHint.
  ///
  /// In en, this message translates to:
  /// **'For testing. Signed with a debug key that stays on this device; not for publishing.'**
  String get debugHint;

  /// No description provided for @releaseHint.
  ///
  /// In en, this message translates to:
  /// **'For publishing. Signed with your release key; every later update must use the same key and a higher version code.'**
  String get releaseHint;

  /// No description provided for @appBundlePlay.
  ///
  /// In en, this message translates to:
  /// **'App Bundle (Play)'**
  String get appBundlePlay;

  /// No description provided for @aabHint.
  ///
  /// In en, this message translates to:
  /// **'Upload the .aab to Google Play Console. It cannot be installed directly; use an APK to test on a phone.'**
  String get aabHint;

  /// No description provided for @createOrImportKey.
  ///
  /// In en, this message translates to:
  /// **'Create or import a release key'**
  String get createOrImportKey;

  /// No description provided for @releaseKey.
  ///
  /// In en, this message translates to:
  /// **'Release key'**
  String get releaseKey;

  /// No description provided for @manageKeys.
  ///
  /// In en, this message translates to:
  /// **'Manage keys'**
  String get manageKeys;

  /// No description provided for @buildDebugApk.
  ///
  /// In en, this message translates to:
  /// **'Build debug APK'**
  String get buildDebugApk;

  /// No description provided for @buildAppBundle.
  ///
  /// In en, this message translates to:
  /// **'Build App Bundle'**
  String get buildAppBundle;

  /// No description provided for @buildReleaseApk.
  ///
  /// In en, this message translates to:
  /// **'Build release APK'**
  String get buildReleaseApk;

  /// No description provided for @buildingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Building is not available on this platform yet.'**
  String get buildingUnavailable;

  /// No description provided for @buildFailed.
  ///
  /// In en, this message translates to:
  /// **'Build failed'**
  String get buildFailed;

  /// No description provided for @saveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as…'**
  String get saveAs;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @buildLog.
  ///
  /// In en, this message translates to:
  /// **'Build log'**
  String get buildLog;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @twoLetters.
  ///
  /// In en, this message translates to:
  /// **'Two letters'**
  String get twoLetters;

  /// No description provided for @invalidHost.
  ///
  /// In en, this message translates to:
  /// **'Invalid host \"{host}\"'**
  String invalidHost(String host);

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML'**
  String get appTitle;

  /// No description provided for @buildingLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Building…} =1{Building… 1 log line} other{Building… {count} log lines}}'**
  String buildingLines(int count);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @accentColour.
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get accentColour;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Terminal green'**
  String get accentGreen;

  /// No description provided for @accentCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get accentCyan;

  /// No description provided for @accentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get accentViolet;

  /// No description provided for @accentPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get accentPink;

  /// No description provided for @animations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animations;

  /// No description provided for @animationsHint.
  ///
  /// In en, this message translates to:
  /// **'ASCII splash, build animation and page transitions'**
  String get animationsHint;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @signing.
  ///
  /// In en, this message translates to:
  /// **'Signing'**
  String get signing;

  /// No description provided for @releaseKeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, import and back up the keys that sign your releases'**
  String get releaseKeysSubtitle;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @projectsAndSize.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project · {size}} other{{count} projects · {size}}}'**
  String projectsAndSize(int count, String size);

  /// No description provided for @buildEngine.
  ///
  /// In en, this message translates to:
  /// **'Build engine'**
  String get buildEngine;

  /// No description provided for @notAvailablePlatform.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform yet'**
  String get notAvailablePlatform;

  /// No description provided for @gradleReady.
  ///
  /// In en, this message translates to:
  /// **'Gradle on this PC (ready)'**
  String get gradleReady;

  /// No description provided for @gradleNotReady.
  ///
  /// In en, this message translates to:
  /// **'Gradle on this PC: not ready'**
  String get gradleNotReady;

  /// No description provided for @buildsRunOnPc.
  ///
  /// In en, this message translates to:
  /// **'Builds run entirely on this PC. No files are uploaded.'**
  String get buildsRunOnPc;

  /// No description provided for @onDeviceReady.
  ///
  /// In en, this message translates to:
  /// **'On-device assembly (ready)'**
  String get onDeviceReady;

  /// No description provided for @onDeviceMissing.
  ///
  /// In en, this message translates to:
  /// **'On-device assembly: base APK missing'**
  String get onDeviceMissing;

  /// No description provided for @buildsRunOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Builds run entirely on this device. No files are uploaded.'**
  String get buildsRunOnDevice;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @howToUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From website to installed app in five steps'**
  String get howToUseSubtitle;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionCopied.
  ///
  /// In en, this message translates to:
  /// **'Version copied'**
  String get versionCopied;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @madeBy.
  ///
  /// In en, this message translates to:
  /// **'Made with <3 by {author}'**
  String madeBy(String author);

  /// No description provided for @supportHint.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML is free, with no ads and no tracking. If it saves you time, you can support its development.'**
  String get supportHint;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeACoffee;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String couldNotOpenLink(String url);

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @howToStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Create a project'**
  String get howToStep1Title;

  /// No description provided for @howToStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap New app and choose HTML files, a website ZIP, or a live https website URL. Files and ZIPs work offline; a URL needs an internet connection.'**
  String get howToStep1Body;

  /// No description provided for @howToStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Name your app'**
  String get howToStep2Title;

  /// No description provided for @howToStep2Body.
  ///
  /// In en, this message translates to:
  /// **'Enter the app name and a unique package ID such as com.yourname.app. Keep the package ID the same for every update.'**
  String get howToStep2Body;

  /// No description provided for @howToStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Customize it'**
  String get howToStep3Title;

  /// No description provided for @howToStep3Body.
  ///
  /// In en, this message translates to:
  /// **'In the Settings tab choose the start page, icon, splash screen, colours, orientation, shortcuts and WebView features. Tap Save when you are done. Use Preview to try the app first.'**
  String get howToStep3Body;

  /// No description provided for @howToStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get howToStep4Title;

  /// No description provided for @howToStep4Body.
  ///
  /// In en, this message translates to:
  /// **'In the Build tab choose Debug to test, or Release to publish. Release builds need a release key: create one and back it up. On Windows you can also build a .exe or an .msix installer.'**
  String get howToStep4Body;

  /// No description provided for @howToStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Install or share'**
  String get howToStep5Title;

  /// No description provided for @howToStep5Body.
  ///
  /// In en, this message translates to:
  /// **'Install the APK on this phone, share it, or save it. On a PC use Install on phone to send it over Wi-Fi. Upload App Bundles (.aab) to Google Play Console.'**
  String get howToStep5Body;

  /// No description provided for @howToTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get howToTipsTitle;

  /// No description provided for @howToTips.
  ///
  /// In en, this message translates to:
  /// **'• Every update must use the same package ID and release key, and a higher version code.\n• Back up your release keys and projects; nobody can recover a lost key.\n• Use the Size report to make the app smaller.\n• Use Back up project (top of a project) to keep a copy you can restore later.'**
  String get howToTips;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'These Terms of Use apply to the iLoveHTML app (\"the app\"), made by 1elevenop. By using the app you agree to them.\n\n## What the app does\n\niLoveHTML turns HTML files, website ZIPs and website addresses into Android and Windows apps. Builds run on your own device.\n\n## Your content\n\nYou keep all rights to the websites, files, icons and apps you create. You are responsible for having the right to use that content, and for the apps you build and publish, including following the law and the rules of app stores such as Google Play.\n\n## Acceptable use\n\nDo not use the app to build software that is illegal, harmful, deceptive, or that infringes the rights of others, such as malware or apps that impersonate other brands.\n\n## Release keys\n\nRelease keys are stored only on your device. You are responsible for backing them up and keeping their passwords safe. A lost key cannot be recovered, and apps signed with it can then no longer be updated.\n\n## No warranty\n\nThe app is provided free of charge and \"as is\", without warranties of any kind. To the extent permitted by law, the author is not liable for any loss of data, keys, income or other damages arising from its use.\n\n## Changes\n\nThese terms may be updated with new versions of the app. The date above shows the latest change. Continuing to use the app means you accept the updated terms.\n\n## Contact\n\nQuestions: open an issue on the iLoveHTML GitHub project by 1elevenop.'**
  String get termsBody;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML is built to work on your device. This policy explains what that means for your data.\n\n## Data we collect\n\nNone. The app has no accounts, no analytics, no advertising and no tracking. The author receives no data about you or your projects.\n\n## Data stored on your device\n\nYour projects, website files, icons, build outputs and settings are stored in the app\'s private storage on your device. Release keys stay on your device too: on Android they are encrypted with the Android Keystore, and on Windows their passwords are encrypted for your Windows account. Uninstalling the app deletes this data, so keep backups.\n\n## Network use\n\nThe app connects to the internet only when you ask it to: to check or preview a website URL you entered, to open links such as Buy Me a Coffee in your browser, and, on Windows, when Gradle downloads build tools. The Install on phone feature serves the file on your local network for 10 minutes, only while its window is open.\n\n## Update check\n\nIf \"Check for updates\" is on (it is by default), about twice a day iLoveHTML asks GitHub (api.github.com) for the latest iLoveHTML release, to tell you when a new version is out. The request contains no account, no identifiers and nothing about your projects; like any website, GitHub sees your IP address. Turn it off in Settings → About.\n\n## Apps you build\n\nApps made with iLoveHTML contain no tracking from iLoveHTML. What they collect depends on the website you put in them, and you are responsible for their privacy policy.\n\n## Children\n\nThe app does not knowingly collect any data, from children or anyone else.\n\n## Changes and contact\n\nThis policy may be updated with new versions of the app; the date above shows the latest change. Questions: open an issue on the iLoveHTML GitHub project by 1elevenop.'**
  String get privacyBody;

  /// No description provided for @replaceWebsite.
  ///
  /// In en, this message translates to:
  /// **'Replace website files'**
  String get replaceWebsite;

  /// No description provided for @replaceWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'Swap in a new ZIP or HTML files. Name, package ID, icon, settings and keys stay the same.'**
  String get replaceWebsiteHint;

  /// No description provided for @replaceWithZipHint.
  ///
  /// In en, this message translates to:
  /// **'A new zipped website folder'**
  String get replaceWithZipHint;

  /// No description provided for @replaceWithFilesHint.
  ///
  /// In en, this message translates to:
  /// **'New .html pages plus their CSS, JavaScript and images'**
  String get replaceWithFilesHint;

  /// No description provided for @replaceWebsiteQ.
  ///
  /// In en, this message translates to:
  /// **'Replace the website?'**
  String get replaceWebsiteQ;

  /// No description provided for @replaceWebsiteBody.
  ///
  /// In en, this message translates to:
  /// **'All website files of \"{name}\" are replaced by the ones you pick next. The app name, package ID, version, icon, settings, release key and build history stay. Build again to get the updated app.'**
  String replaceWebsiteBody(String name);

  /// No description provided for @replaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not replace the website: {error}'**
  String replaceFailed(String error);

  /// No description provided for @websiteReplaced.
  ///
  /// In en, this message translates to:
  /// **'Website replaced'**
  String get websiteReplaced;

  /// No description provided for @startPageChanged.
  ///
  /// In en, this message translates to:
  /// **'\"{page}\" is not in the new files, so the start page changed.'**
  String startPageChanged(String page);

  /// No description provided for @shortcutsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts removed because their pages are gone: {pages}'**
  String shortcutsRemoved(String pages);

  /// No description provided for @rebuildAfterReplace.
  ///
  /// In en, this message translates to:
  /// **'Build again to get the updated app. To update an installed app, raise the version code first.'**
  String get rebuildAfterReplace;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock iLoveHTML'**
  String get unlockReason;

  /// No description provided for @resetReason.
  ///
  /// In en, this message translates to:
  /// **'Verify it is you to reset the iLoveHTML lock'**
  String get resetReason;

  /// No description provided for @wrongSecret.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Wrong. Wait before trying again.} =1{Wrong. 1 try left before a wait.} other{Wrong. {count} tries left before a wait.}}'**
  String wrongSecret(int count);

  /// No description provided for @tooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries. Try again in {seconds} s.'**
  String tooManyTries(int seconds);

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get enterPin;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hidePassword;

  /// No description provided for @hintIs.
  ///
  /// In en, this message translates to:
  /// **'Hint: {hint}'**
  String hintIs(String hint);

  /// No description provided for @showHint.
  ///
  /// In en, this message translates to:
  /// **'Show hint'**
  String get showHint;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDigit;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face'**
  String get useFingerprint;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @digitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{count} digits entered'**
  String digitsEntered(int count);

  /// No description provided for @wrongRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Wrong code. Wait before trying again.} =1{Wrong code. 1 try left before a wait.} other{Wrong code. {count} tries left before a wait.}}'**
  String wrongRecoveryCode(int count);

  /// No description provided for @forgotWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Use this device\'s lock'**
  String get forgotWithDevice;

  /// No description provided for @forgotWithDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Verify with your fingerprint, face or the phone\'s screen lock (PIN, pattern or password), then choose a new one for iLoveHTML.'**
  String get forgotWithDeviceHint;

  /// No description provided for @verifyWithDevice.
  ///
  /// In en, this message translates to:
  /// **'Verify with device lock'**
  String get verifyWithDevice;

  /// No description provided for @forgotWithCode.
  ///
  /// In en, this message translates to:
  /// **'Use your recovery code'**
  String get forgotWithCode;

  /// No description provided for @forgotWithCodeHint.
  ///
  /// In en, this message translates to:
  /// **'The 16-character code shown when you set up the lock.'**
  String get forgotWithCodeHint;

  /// No description provided for @recoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get recoveryCode;

  /// No description provided for @useRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Use code'**
  String get useRecoveryCode;

  /// No description provided for @forgotNoWay.
  ///
  /// In en, this message translates to:
  /// **'Without either, the lock can only be removed by clearing iLoveHTML\'s app data in the system settings. That deletes all projects and release keys on this device.'**
  String get forgotNoWay;

  /// No description provided for @pinDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Digits only'**
  String get pinDigitsOnly;

  /// No description provided for @pinLength.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} digits'**
  String pinLength(int min, int max);

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String passwordMinLength(int count);

  /// No description provided for @chooseNewSecret.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN or password'**
  String get chooseNewSecret;

  /// No description provided for @setUpAppLock.
  ///
  /// In en, this message translates to:
  /// **'Set up app lock'**
  String get setUpAppLock;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @repeatPin.
  ///
  /// In en, this message translates to:
  /// **'Repeat PIN'**
  String get repeatPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @hintOptional.
  ///
  /// In en, this message translates to:
  /// **'Hint (optional)'**
  String get hintOptional;

  /// No description provided for @hintHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on the lock screen to help you remember. Anyone holding the device can read it.'**
  String get hintHelp;

  /// No description provided for @hintGivesAway.
  ///
  /// In en, this message translates to:
  /// **'The hint must not contain the PIN or password'**
  String get hintGivesAway;

  /// No description provided for @unlockWithFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint or face'**
  String get unlockWithFingerprint;

  /// No description provided for @unlockWithFingerprintHint.
  ///
  /// In en, this message translates to:
  /// **'Your PIN or password still works.'**
  String get unlockWithFingerprintHint;

  /// No description provided for @appLockNote.
  ///
  /// In en, this message translates to:
  /// **'The lock hides iLoveHTML and its projects from people who pick up this device. It does not encrypt the project files.'**
  String get appLockNote;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAndContinue;

  /// No description provided for @recoveryCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery code'**
  String get recoveryCodeTitle;

  /// No description provided for @recoveryCodeBody.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN or password, this code lets you set a new one. It is shown only now. Write it down or keep it somewhere safe, not only on this device.'**
  String get recoveryCodeBody;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @iSavedTheCode.
  ///
  /// In en, this message translates to:
  /// **'I saved the code'**
  String get iSavedTheCode;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get enterCurrentPin;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @appLockOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off. Ask for a PIN, password or fingerprint before opening iLoveHTML.'**
  String get appLockOffHint;

  /// No description provided for @appLockOnPin.
  ///
  /// In en, this message translates to:
  /// **'On, with a PIN'**
  String get appLockOnPin;

  /// No description provided for @appLockOnPassword.
  ///
  /// In en, this message translates to:
  /// **'On, with a password'**
  String get appLockOnPassword;

  /// No description provided for @lockAgainAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock again after leaving the app'**
  String get lockAgainAfter;

  /// No description provided for @relockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get relockImmediately;

  /// No description provided for @relockMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{After 1 minute} other{After {count} minutes}}'**
  String relockMinutes(int count);

  /// No description provided for @relockLaunchOnly.
  ///
  /// In en, this message translates to:
  /// **'Only when iLoveHTML starts'**
  String get relockLaunchOnly;

  /// No description provided for @changePinOrHint.
  ///
  /// In en, this message translates to:
  /// **'Change PIN, password or hint'**
  String get changePinOrHint;

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockNow;

  /// No description provided for @turnOffLock.
  ///
  /// In en, this message translates to:
  /// **'Turn off lock'**
  String get turnOffLock;

  /// No description provided for @newUpdate.
  ///
  /// In en, this message translates to:
  /// **'NEW UPDATE'**
  String get newUpdate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update to {version}'**
  String updateTitle(String version);

  /// No description provided for @youHaveVersion.
  ///
  /// In en, this message translates to:
  /// **'You have {version}.'**
  String youHaveVersion(String version);

  /// No description provided for @updateAndroidHint.
  ///
  /// In en, this message translates to:
  /// **'The APK downloads in your browser. Open it to install over this version; your projects, keys and settings stay.'**
  String get updateAndroidHint;

  /// No description provided for @updateWindowsHint.
  ///
  /// In en, this message translates to:
  /// **'The ZIP downloads in your browser. Close iLoveHTML, unzip it and replace your iLoveHTML folder; your projects, keys and settings stay.'**
  String get updateWindowsHint;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @releasePage.
  ///
  /// In en, this message translates to:
  /// **'Release page'**
  String get releasePage;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadUpdate;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesHint.
  ///
  /// In en, this message translates to:
  /// **'About twice a day, ask GitHub if a newer iLoveHTML was released. Nothing about you or your projects is sent.'**
  String get checkForUpdatesHint;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @checkingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get upToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check. Are you online?'**
  String get updateCheckFailed;

  /// No description provided for @updateInAppHint.
  ///
  /// In en, this message translates to:
  /// **'iLoveHTML downloads the update, checks it, then Android asks to install it over this version. Your projects, keys and settings stay.'**
  String get updateInAppHint;

  /// No description provided for @verifyingDownload.
  ///
  /// In en, this message translates to:
  /// **'Checking the file…'**
  String get verifyingDownload;

  /// No description provided for @downloadingMb.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {done} MB'**
  String downloadingMb(String done);

  /// No description provided for @downloadingOf.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {done} of {total} MB'**
  String downloadingOf(String done, String total);

  /// No description provided for @installerOpened.
  ///
  /// In en, this message translates to:
  /// **'Android\'s installer is open. Tap Update there. If it closed, tap Install.'**
  String get installerOpened;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
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

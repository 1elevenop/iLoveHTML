// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String unreadableProject(String name) {
    return 'Unreadable project: $name';
  }

  @override
  String get emptyHintWindows =>
      'Turn HTML files, a website ZIP, or a live https website into an Android or Windows app. Builds happen on this device.';

  @override
  String get emptyHintAndroid =>
      'Turn HTML files, a website ZIP, or a live https website into an Android app. Builds happen on this device.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · not built yet';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · last build $status $ago';
  }

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String daysAgo(int n) {
    return '$n d ago';
  }

  @override
  String chooseBackupFile(String ext) {
    return 'Choose a $ext backup file';
  }

  @override
  String restored(String name) {
    return 'Restored $name';
  }

  @override
  String notUsableBackup(String message) {
    return 'Not a usable backup: $message';
  }

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count files',
      one: 'Imported 1 file',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return 'Start page: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return '$count HTML pages found; you can change the start page in Settings.';
  }

  @override
  String filesMissing(int count) {
    return '$count referenced files are missing:';
  }

  @override
  String andMore(int count) {
    return '…and $count more';
  }

  @override
  String fileNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'Would open outside the app: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'Page failed to load: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'Could not start the preview: $error';
  }

  @override
  String previewTitle(String name) {
    return 'Preview · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'Website answered with HTTP $code';
  }

  @override
  String redirected(int count) {
    return 'Redirected $count× — the app will start at this address.';
  }

  @override
  String importedKey(String alias) {
    return 'Imported \"$alias\"';
  }

  @override
  String backupSavedAs(String alias) {
    return 'Backup saved as $alias.jks. Keep the password with it, separately.';
  }

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String deletedKey(String alias) {
    return 'Deleted \"$alias\" from this device';
  }

  @override
  String get releaseKeysIntroWindows =>
      'Release builds are signed with one of these keys. Google Play and Android only accept updates signed with the same key as the first release. Keys stay on this PC, with passwords encrypted for your Windows account; a backup is a password-protected .jks file that works with iLoveHTML on a phone or a computer, Gradle and keytool.';

  @override
  String get releaseKeysIntroAndroid =>
      'Release builds are signed with one of these keys. Google Play and Android only accept updates signed with the same key as the first release. Keys stay on this phone, encrypted with Android Keystore; a backup is a password-protected .jks file that works with iLoveHTML on a phone or a computer, Gradle and keytool.';

  @override
  String validUntilDate(String date) {
    return 'valid until $date';
  }

  @override
  String get atLeast8 => 'At least 8 characters';

  @override
  String deleteKeyBody(String alias) {
    return 'Apps signed with \"$alias\" can only be updated with this exact key. Without a backup, you will never be able to update them again.';
  }

  @override
  String typeToConfirm(String alias) {
    return 'Type \"$alias\" to confirm';
  }

  @override
  String backupSaved(String file) {
    return 'Backup saved: $file';
  }

  @override
  String shortcutExists(String page) {
    return 'A shortcut for \"$page\" already exists';
  }

  @override
  String deleteProjectBody(String name) {
    return 'This deletes \"$name\", its website files and built APKs from this device. Apps already installed are not affected.';
  }

  @override
  String offlinePageShown(String page) {
    return 'When the site cannot load, your page \"$page\" is shown. Link to https://appassets.androidplatform.net/html2apk/retry for a \"Try again\" button.';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloaded $count times.',
      one: 'Downloaded 1 time.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'Could not read the files: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count files, $size';
  }

  @override
  String checkFailed(String error) {
    return 'Check failed: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return 'Optimizing makes $count files smaller and saves $saved ($before → $after). The APK is compressed too, so the APK saving is often smaller for CSS and JSON.';
  }

  @override
  String example(String value) {
    return 'e.g. $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'Could not load release keys: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'This app was first released with a different key (SHA-256 $sha…). Phones that installed that release cannot update to an APK signed with \"$alias\", and Google Play will reject it as an update.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return 'Publisher: $publisher · valid until $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return 'Apps installed from installers signed by \"$publisher\" update only from installers with the same publisher name. Back up the current certificate first if you may need it.';
  }

  @override
  String passwordOf(String file) {
    return 'Password of $file';
  }

  @override
  String savedFile(String file) {
    return 'Saved $file';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get cannotBuildYet => 'Cannot build yet:';

  @override
  String get shareFilesHint =>
      'navigator.share() with files sends images and PDFs to other apps. On Android 10+ shared images are also saved to the gallery.';

  @override
  String get projects => 'Projects';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get settings => 'Settings';

  @override
  String get newApp => 'New app';

  @override
  String get htmlFiles => 'HTML files';

  @override
  String get htmlFilesHint =>
      'Pick an .html page, plus its CSS, JavaScript and images if they are separate files. Works offline.';

  @override
  String get websiteZip => 'Website ZIP';

  @override
  String get websiteZipHint => 'A whole website folder, zipped. Works offline.';

  @override
  String get websiteUrl => 'Website URL';

  @override
  String get websiteUrlHint =>
      'Wrap a live https website. Needs an internet connection.';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get building => 'Building…';

  @override
  String get selectHtmlFile =>
      'Select at least one .html file, plus any CSS, JavaScript or images it uses.';

  @override
  String get defaultAppName => 'My App';

  @override
  String get appName => 'App name';

  @override
  String get enterName => 'Enter a name';

  @override
  String get packageId => 'Package ID';

  @override
  String get packageIdHelp =>
      'Unique ID on the device and in Play, e.g. com.yourname.app';

  @override
  String get cancel => 'Cancel';

  @override
  String get importButton => 'Import';

  @override
  String get noMissingFiles => 'No missing files found';

  @override
  String get openProject => 'Open project';

  @override
  String get noConsoleMessages => 'No console messages or issues';

  @override
  String get viewport => 'Viewport';

  @override
  String get consoleAndIssues => 'Console and issues';

  @override
  String get checkWebsite => 'Check website';

  @override
  String get websiteReachable => 'Website reachable';

  @override
  String get liveSiteNote =>
      'The app shows this site live and needs an internet connection. It does not work offline.';

  @override
  String get create => 'Create';

  @override
  String get backUpKeyNow => 'Back up this key now';

  @override
  String get backUpKeyBody =>
      'Every update of an app must be signed with the same key. If this device is lost or iLoveHTML is uninstalled, the key is gone unless you have a backup.\n\nSave the .jks file somewhere safe (not only on this device) and keep the password separately.';

  @override
  String get later => 'Later';

  @override
  String get saveBackup => 'Save backup';

  @override
  String get certificate => 'Certificate';

  @override
  String get sha256Fingerprint => 'SHA-256 fingerprint';

  @override
  String get sha1Fingerprint => 'SHA-1 fingerprint';

  @override
  String get validUntil => 'Valid until';

  @override
  String get added => 'Added';

  @override
  String get saveBackupJks => 'Save backup (.jks)';

  @override
  String get delete => 'Delete';

  @override
  String get releaseKeys => 'Release keys';

  @override
  String get createKey => 'Create key';

  @override
  String get importKeystoreFile => 'Import .jks / .keystore / .p12';

  @override
  String get noReleaseKeys => 'No release keys yet';

  @override
  String get createReleaseKey => 'Create release key';

  @override
  String get keyAlias => 'Key alias';

  @override
  String get keyAliasHelp => 'Letters, digits, dots, dashes, underscores';

  @override
  String get publisherNameField => 'Your name or app publisher';

  @override
  String get required => 'Required';

  @override
  String get organizationOptional => 'Organization (optional)';

  @override
  String get countryCodeOptional => 'Country code (optional)';

  @override
  String get password => 'Password';

  @override
  String get passwordHelp => 'Used for the keystore and the key';

  @override
  String get repeatPassword => 'Repeat password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createKeyNote =>
      'RSA 2048-bit, valid for 30 years. You will need this password to use the backup on a computer.';

  @override
  String get noPrivateKeys => 'No private keys in this file';

  @override
  String get importKeystore => 'Import keystore';

  @override
  String get keystorePassword => 'Keystore password';

  @override
  String get keyPassword => 'Key password';

  @override
  String get keyPasswordHelp =>
      'Leave empty if it is the same as the keystore password';

  @override
  String get importKeystoreNote =>
      'iLoveHTML keeps a copy protected by the keystore password. Your original file is not changed.';

  @override
  String get open => 'Open';

  @override
  String get deleteReleaseKey => 'Delete release key?';

  @override
  String get deleteKey => 'Delete key';

  @override
  String get projectNotFound => 'Project not found';

  @override
  String get backUpProject => 'Back up project';

  @override
  String get preview => 'Preview';

  @override
  String get build => 'Build';

  @override
  String get previewInBrowser => 'Preview in your browser';

  @override
  String get liveSiteOpened => 'The live site opened in your default browser.';

  @override
  String get servedFromPc =>
      'Served from this PC only, while this window is open. The phone app adds a console and link checks; here use the browser\'s developer tools (F12).';

  @override
  String get missingFiles => 'Missing files:';

  @override
  String get close => 'Close';

  @override
  String get stopPreview => 'Stop preview';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get iconUpdated => 'Icon updated';

  @override
  String get splashUpdated => 'Splash image updated';

  @override
  String get offlinePageAdded => 'Offline page added';

  @override
  String get deleteProjectQ => 'Delete project?';

  @override
  String get save => 'Save';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionContent => 'Content';

  @override
  String get sectionShortcuts => 'Shortcuts';

  @override
  String get sectionAppSize => 'App size';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionDevices => 'Devices';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get sectionOffline => 'Offline';

  @override
  String get sectionDanger => 'Danger zone';

  @override
  String get versionName => 'Version name';

  @override
  String get versionCode => 'Version code';

  @override
  String get defaultIcon => 'Default icon';

  @override
  String get customIcon => 'Custom icon';

  @override
  String get chooseImage => 'Choose image';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP or SVG, at least 48 px; 512 × 512 recommended. Non-square images are centred.';

  @override
  String get startPage => 'Start page';

  @override
  String get loadedLive => 'Loaded live; the app needs an internet connection.';

  @override
  String get otherSites => 'Other sites that open inside the app (optional)';

  @override
  String get otherSitesHelp =>
      'Comma-separated. Links to any other site open in the browser.';

  @override
  String get bridgeSites =>
      'Sites that can also share, save files and notify (optional)';

  @override
  String get bridgeSitesHelp =>
      'Comma-separated, from the list above. Your own site always can. Leave login and payment sites out.';

  @override
  String bridgeSiteNotListed(String host) {
    return '\"$host\" is not in the list above';
  }

  @override
  String get orientation => 'Orientation';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Landscape';

  @override
  String get shortcutsHint => 'Long-press the app icon to see these pages.';

  @override
  String get removeShortcut => 'Remove shortcut';

  @override
  String get addShortcut => 'Add shortcut';

  @override
  String get optimizeFiles => 'Optimize files when building';

  @override
  String get optimizeFilesHint =>
      'Makes CSS, JSON, PNG and large JPEG files smaller in the app. JPEGs are saved again at 85% quality. Your project files do not change.';

  @override
  String get sizeReport => 'Size report';

  @override
  String get statusBarColour => 'Status bar colour';

  @override
  String get navBarColour => 'Navigation bar colour';

  @override
  String get splashScreen => 'Splash screen';

  @override
  String get splashIconHint =>
      'Shows the app icon until the first page has loaded.';

  @override
  String get splashImageHint =>
      'Shows your splash image until the first page has loaded.';

  @override
  String get splashBackground => 'Splash background';

  @override
  String get chooseSplash => 'Choose splash image';

  @override
  String get replaceSplash => 'Replace splash image';

  @override
  String get useAppIcon => 'Use app icon';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get followPhone => 'Follow phone';

  @override
  String get themeHint =>
      'Sets prefers-color-scheme, so pages with dark-mode CSS switch to it.';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get fullscreenHint =>
      'Hides the status and navigation bars. Swipe from the edge to show them for a moment.';

  @override
  String get keepScreenOn => 'Keep screen on';

  @override
  String get keepScreenOnHint =>
      'The screen does not turn off while the app is open.';

  @override
  String get tvHint =>
      'Shows the app on the TV home screen with a banner made from the icon and name. The remote\'s arrow keys move between links and buttons; OK opens them.';

  @override
  String get rotateTablets => 'Rotate freely on tablets';

  @override
  String get rotateTabletsHint =>
      'Tablets and foldables may turn to any side, even when phones keep the orientation chosen above. Android 16 and later always allow this on large screens.';

  @override
  String get desktopLayout => 'Desktop layout on tablets and TV';

  @override
  String get desktopLayoutHint =>
      'Asks websites for the layout they show on computers instead of the phone layout.';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'Asks for the fingerprint, face or screen lock when the app opens, and after 30 seconds in the background. Phones without a screen lock open the app with a hint.';

  @override
  String get javascriptHint =>
      'Most sites need this. Turn off for static pages.';

  @override
  String get localStorage => 'Local storage';

  @override
  String get internetAccess => 'Internet access';

  @override
  String get internetAccessHint =>
      'Adds the INTERNET permission, for CDNs, APIs or fonts loaded from the web.';

  @override
  String get openOtherSites => 'Open other sites in the browser';

  @override
  String get openOtherSitesHint => 'When off, links to other sites do nothing.';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get pullToRefreshHint =>
      'Swipe down at the top of a page to reload it, or to retry after an error.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsHint =>
      'The page can use the web Notification API to show Android notifications while the app is open. Android 13+ asks the user first. No push messages.';

  @override
  String get backButton => 'Back button';

  @override
  String get backHistory => 'Go back, then close the app';

  @override
  String get backTwice => 'Go back, then press twice to close';

  @override
  String get backConfirm => 'Go back, then ask before closing';

  @override
  String get backHome => 'Go to the start page, then close';

  @override
  String get fileUploads => 'File uploads';

  @override
  String get fileUploadsHint =>
      'Lets file inputs open Android\'s file picker. The user chooses each file.';

  @override
  String get share => 'Share';

  @override
  String get shareHint =>
      'navigator.share opens Android\'s share sheet for text and links.';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsHint =>
      'Download links and generated files are saved to the Downloads folder.';

  @override
  String get shareFiles => 'Share images and PDFs';

  @override
  String get galleryFolder => 'Gallery folder (optional)';

  @override
  String get galleryFolderExample => 'e.g. My Photos';

  @override
  String get galleryFolderHelp =>
      'Pictures/<folder> for shared and downloaded images. Empty: the app name for shares, Downloads for downloads.';

  @override
  String get shareToApp => 'Share straight to app (optional)';

  @override
  String get shareToAppHelp =>
      'Package that file shares open directly when installed, instead of the share sheet.';

  @override
  String get usePackageName => 'Use a package name like com.whatsapp';

  @override
  String get offlineBuiltIn =>
      'When the site cannot load, a built-in \"Page unavailable\" screen is shown.';

  @override
  String get chooseOfflinePage => 'Choose offline page (.html)';

  @override
  String get replaceOfflinePage => 'Replace offline page';

  @override
  String get useBuiltInPage => 'Use built-in page';

  @override
  String get userAgentSuffix => 'User agent suffix (optional)';

  @override
  String get atMost200 => 'At most 200 characters';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get useColourLike => 'Use a colour like #1A73E8';

  @override
  String get noNetwork =>
      'This computer is not on a Wi-Fi or Ethernet network.';

  @override
  String get installOnPhone => 'Install on phone';

  @override
  String get installSteps =>
      '1. Connect the phone to the same Wi-Fi as this computer.\n2. Scan the code with the phone camera and open the link.\n3. Open the downloaded file. Allow installs from the browser if Android asks.';

  @override
  String get linkStopped => 'The link has stopped.';

  @override
  String get networkAddress => 'Network address';

  @override
  String get linkWorks10Min =>
      'The link works for 10 minutes while this window is open.';

  @override
  String get trustedNetworkOnly =>
      'Use this only on a network you trust. Windows may ask to allow iLoveHTML through the firewall: allow it for private networks.';

  @override
  String get startAgain => 'Start again';

  @override
  String get done => 'Done';

  @override
  String get kindPages => 'Pages';

  @override
  String get kindImages => 'Images';

  @override
  String get kindFonts => 'Fonts';

  @override
  String get kindMedia => 'Audio and video';

  @override
  String get kindData => 'Data';

  @override
  String get kindOther => 'Other';

  @override
  String get largestFiles => 'Largest files';

  @override
  String get advice => 'Advice';

  @override
  String get checkOptimizing => 'Check what optimizing saves';

  @override
  String get name => 'Name';

  @override
  String get exampleCart => 'e.g. Cart';

  @override
  String get choosePage => 'Choose a page';

  @override
  String get page => 'Page';

  @override
  String get add => 'Add';

  @override
  String get differentKey => 'Different release key';

  @override
  String get buildAnyway => 'Build anyway';

  @override
  String get windowsExe => 'Windows app (.exe)';

  @override
  String get exeDescription =>
      'One .exe file that opens this site in its own window with Microsoft Edge WebView2 (built into Windows 11 and updated Windows 10). It is not code-signed, so Windows may show \"Windows protected your PC\" until people choose More info → Run anyway.';

  @override
  String get devTools => 'Developer tools (for testing)';

  @override
  String get devToolsHint =>
      'F12 and Inspect work in the app; leave off for the version you share';

  @override
  String get buildExe => 'Build .exe';

  @override
  String get windowsMsix => 'Windows installer (.msix)';

  @override
  String get msixDescription =>
      'Installs the app like other Windows software: Start menu entry, clean uninstall, and updates when you share a higher version. Every installer is signed with a certificate.';

  @override
  String get needsWindowsSdk =>
      'Needs the Windows SDK. Install it with:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      'No certificate yet. Use your own code-signing certificate, or create a test certificate to try it.';

  @override
  String get testCertNote =>
      'Test certificate: Windows installs the app only after people trust it once. Share the .cer file next to the installer; people double-click it → Install Certificate → Local Machine → \"Trusted People\". A certificate bought from a certificate authority needs no such step.';

  @override
  String get createTestCert => 'Create test certificate';

  @override
  String get useMyPfx => 'Use my .pfx';

  @override
  String get savedCertificate => 'Saved the certificate';

  @override
  String get saveCer => 'Save .cer';

  @override
  String get buildInstaller => 'Build installer';

  @override
  String get replaceCertQ => 'Replace the certificate?';

  @override
  String get replace => 'Replace';

  @override
  String get publisherName => 'Publisher name';

  @override
  String get publisherNameHelp =>
      'Shown as the publisher when people install your apps.';

  @override
  String get testCertCreated => 'Test certificate created';

  @override
  String get useMyCertificate => 'Use my certificate';

  @override
  String get certificateAdded => 'Certificate added';

  @override
  String get ok => 'OK';

  @override
  String get allowUnknownApps =>
      'Allow \"Install unknown apps\" for iLoveHTML in the screen that opened, then tap Install again.';

  @override
  String get debug => 'Debug';

  @override
  String get release => 'Release';

  @override
  String get debugHint =>
      'For testing. Signed with a debug key that stays on this device; not for publishing.';

  @override
  String get releaseHint =>
      'For publishing. Signed with your release key; every later update must use the same key and a higher version code.';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      'Upload the .aab to Google Play Console. It cannot be installed directly; use an APK to test on a phone.';

  @override
  String get createOrImportKey => 'Create or import a release key';

  @override
  String get releaseKey => 'Release key';

  @override
  String get manageKeys => 'Manage keys';

  @override
  String get buildDebugApk => 'Build debug APK';

  @override
  String get buildAppBundle => 'Build App Bundle';

  @override
  String get buildReleaseApk => 'Build release APK';

  @override
  String get buildingUnavailable =>
      'Building is not available on this platform yet.';

  @override
  String get buildFailed => 'Build failed';

  @override
  String get saveAs => 'Save as…';

  @override
  String get showInFolder => 'Show in folder';

  @override
  String get install => 'Install';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get buildLog => 'Build log';

  @override
  String get history => 'History';

  @override
  String get twoLetters => 'Two letters';

  @override
  String invalidHost(String host) {
    return 'Invalid host \"$host\"';
  }

  @override
  String get thisDevice => 'This device';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Building… $count log lines',
      one: 'Building… 1 log line',
      zero: 'Building…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentGreen => 'Terminal green';

  @override
  String get accentCyan => 'Cyan';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentPink => 'Pink';

  @override
  String get animations => 'Animations';

  @override
  String get animationsHint =>
      'ASCII splash, build animation and page transitions';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get signing => 'Signing';

  @override
  String get releaseKeysSubtitle =>
      'Create, import and back up the keys that sign your releases';

  @override
  String get storage => 'Storage';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects · $size',
      one: '1 project · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'Build engine';

  @override
  String get notAvailablePlatform => 'Not available on this platform yet';

  @override
  String get gradleReady => 'Gradle on this PC (ready)';

  @override
  String get gradleNotReady => 'Gradle on this PC: not ready';

  @override
  String get buildsRunOnPc =>
      'Builds run entirely on this PC. No files are uploaded.';

  @override
  String get onDeviceReady => 'On-device assembly (ready)';

  @override
  String get onDeviceMissing => 'On-device assembly: base APK missing';

  @override
  String get buildsRunOnDevice =>
      'Builds run entirely on this device. No files are uploaded.';

  @override
  String get about => 'About';

  @override
  String get howToUse => 'How to use';

  @override
  String get howToUseSubtitle => 'From website to installed app in five steps';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get version => 'Version';

  @override
  String get versionCopied => 'Version copied';

  @override
  String get credit => 'Credit';

  @override
  String madeBy(String author) {
    return 'Made with <3 by $author';
  }

  @override
  String get supportHint =>
      'iLoveHTML is free, with no ads and no tracking. If it saves you time, you can support its development.';

  @override
  String get buyMeACoffee => 'Buy me a coffee';

  @override
  String couldNotOpenLink(String url) {
    return 'Could not open $url';
  }

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get howToStep1Title => 'Create a project';

  @override
  String get howToStep1Body =>
      'Tap New app and choose HTML files, a website ZIP, or a live https website URL. Files and ZIPs work offline; a URL needs an internet connection.';

  @override
  String get howToStep2Title => 'Name your app';

  @override
  String get howToStep2Body =>
      'Enter the app name and a unique package ID such as com.yourname.app. Keep the package ID the same for every update.';

  @override
  String get howToStep3Title => 'Customize it';

  @override
  String get howToStep3Body =>
      'In the Settings tab choose the start page, icon, splash screen, colours, orientation, shortcuts and WebView features. Tap Save when you are done. Use Preview to try the app first.';

  @override
  String get howToStep4Title => 'Build';

  @override
  String get howToStep4Body =>
      'In the Build tab choose Debug to test, or Release to publish. Release builds need a release key: create one and back it up. On Windows you can also build a .exe or an .msix installer.';

  @override
  String get howToStep5Title => 'Install or share';

  @override
  String get howToStep5Body =>
      'Install the APK on this phone, share it, or save it. On a PC use Install on phone to send it over Wi-Fi. Upload App Bundles (.aab) to Google Play Console.';

  @override
  String get howToTipsTitle => 'Tips';

  @override
  String get howToTips =>
      '• Every update must use the same package ID and release key, and a higher version code.\n• Back up your release keys and projects; nobody can recover a lost key.\n• Use the Size report to make the app smaller.\n• Use Back up project (top of a project) to keep a copy you can restore later.';

  @override
  String get termsBody =>
      'These Terms of Use apply to the iLoveHTML app (\"the app\"), made by 1elevenop. By using the app you agree to them.\n\n## What the app does\n\niLoveHTML turns HTML files, website ZIPs and website addresses into Android and Windows apps. Builds run on your own device.\n\n## Your content\n\nYou keep all rights to the websites, files, icons and apps you create. You are responsible for having the right to use that content, and for the apps you build and publish, including following the law and the rules of app stores such as Google Play.\n\n## Acceptable use\n\nDo not use the app to build software that is illegal, harmful, deceptive, or that infringes the rights of others, such as malware or apps that impersonate other brands.\n\n## Release keys\n\nRelease keys are stored only on your device. You are responsible for backing them up and keeping their passwords safe. A lost key cannot be recovered, and apps signed with it can then no longer be updated.\n\n## No warranty\n\nThe app is provided free of charge and \"as is\", without warranties of any kind. To the extent permitted by law, the author is not liable for any loss of data, keys, income or other damages arising from its use.\n\n## Changes\n\nThese terms may be updated with new versions of the app. The date above shows the latest change. Continuing to use the app means you accept the updated terms.\n\n## Contact\n\nQuestions: open an issue on the iLoveHTML GitHub project by 1elevenop.';

  @override
  String get privacyBody =>
      'iLoveHTML is built to work on your device. This policy explains what that means for your data.\n\n## Data we collect\n\nNone. The app has no accounts, no analytics, no advertising and no tracking. The author receives no data about you or your projects.\n\n## Data stored on your device\n\nYour projects, website files, icons, build outputs and settings are stored in the app\'s private storage on your device. Release keys stay on your device too: on Android they are encrypted with the Android Keystore, and on Windows their passwords are encrypted for your Windows account. Uninstalling the app deletes this data, so keep backups.\n\n## Network use\n\nThe app connects to the internet only when you ask it to: to check or preview a website URL you entered, to open links such as Buy Me a Coffee in your browser, and, on Windows, when Gradle downloads build tools. The Install on phone feature serves the file on your local network for 10 minutes, only while its window is open.\n\n## Update check\n\nIf \"Check for updates\" is on (it is by default), about twice a day iLoveHTML asks GitHub (api.github.com) for the latest iLoveHTML release, to tell you when a new version is out. The request contains no account, no identifiers and nothing about your projects; like any website, GitHub sees your IP address. Turn it off in Settings → About.\n\n## Apps you build\n\nApps made with iLoveHTML contain no tracking from iLoveHTML. What they collect depends on the website you put in them, and you are responsible for their privacy policy.\n\n## Children\n\nThe app does not knowingly collect any data, from children or anyone else.\n\n## Changes and contact\n\nThis policy may be updated with new versions of the app; the date above shows the latest change. Questions: open an issue on the iLoveHTML GitHub project by 1elevenop.';

  @override
  String get replaceWebsite => 'Replace website files';

  @override
  String get replaceWebsiteHint =>
      'Swap in a new ZIP or HTML files. Name, package ID, icon, settings and keys stay the same.';

  @override
  String get replaceWithZipHint => 'A new zipped website folder';

  @override
  String get replaceWithFilesHint =>
      'New .html pages plus their CSS, JavaScript and images';

  @override
  String get replaceWebsiteQ => 'Replace the website?';

  @override
  String replaceWebsiteBody(String name) {
    return 'All website files of \"$name\" are replaced by the ones you pick next. The app name, package ID, version, icon, settings, release key and build history stay. Build again to get the updated app.';
  }

  @override
  String replaceFailed(String error) {
    return 'Could not replace the website: $error';
  }

  @override
  String get websiteReplaced => 'Website replaced';

  @override
  String startPageChanged(String page) {
    return '\"$page\" is not in the new files, so the start page changed.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'Shortcuts removed because their pages are gone: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      'Build again to get the updated app. To update an installed app, raise the version code first.';

  @override
  String get unlockReason => 'Unlock iLoveHTML';

  @override
  String get resetReason => 'Verify it is you to reset the iLoveHTML lock';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong. $count tries left before a wait.',
      one: 'Wrong. 1 try left before a wait.',
      zero: 'Wrong. Wait before trying again.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return 'Too many wrong tries. Try again in $seconds s.';
  }

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get showPassword => 'Show';

  @override
  String get hidePassword => 'Hide';

  @override
  String hintIs(String hint) {
    return 'Hint: $hint';
  }

  @override
  String get showHint => 'Show hint';

  @override
  String get deleteDigit => 'Delete';

  @override
  String get unlock => 'Unlock';

  @override
  String get useFingerprint => 'Use fingerprint or face';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String digitsEntered(int count) {
    return '$count digits entered';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong code. $count tries left before a wait.',
      one: 'Wrong code. 1 try left before a wait.',
      zero: 'Wrong code. Wait before trying again.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'Use this device\'s lock';

  @override
  String get forgotWithDeviceHint =>
      'Verify with your fingerprint, face or the phone\'s screen lock (PIN, pattern or password), then choose a new one for iLoveHTML.';

  @override
  String get verifyWithDevice => 'Verify with device lock';

  @override
  String get forgotWithCode => 'Use your recovery code';

  @override
  String get forgotWithCodeHint =>
      'The 16-character code shown when you set up the lock.';

  @override
  String get recoveryCode => 'Recovery code';

  @override
  String get useRecoveryCode => 'Use code';

  @override
  String get forgotNoWay =>
      'Without either, the lock can only be removed by clearing iLoveHTML\'s app data in the system settings. That deletes all projects and release keys on this device.';

  @override
  String get pinDigitsOnly => 'Digits only';

  @override
  String pinLength(int min, int max) {
    return '$min to $max digits';
  }

  @override
  String passwordMinLength(int count) {
    return 'At least $count characters';
  }

  @override
  String get chooseNewSecret => 'Choose a new PIN or password';

  @override
  String get setUpAppLock => 'Set up app lock';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get newPassword => 'New password';

  @override
  String get repeatPin => 'Repeat PIN';

  @override
  String get pinsDoNotMatch => 'PINs do not match';

  @override
  String get hintOptional => 'Hint (optional)';

  @override
  String get hintHelp =>
      'Shown on the lock screen to help you remember. Anyone holding the device can read it.';

  @override
  String get hintGivesAway => 'The hint must not contain the PIN or password';

  @override
  String get unlockWithFingerprint => 'Unlock with fingerprint or face';

  @override
  String get unlockWithFingerprintHint => 'Your PIN or password still works.';

  @override
  String get appLockNote =>
      'The lock hides iLoveHTML and its projects from people who pick up this device. It does not encrypt the project files.';

  @override
  String get saveAndContinue => 'Save';

  @override
  String get recoveryCodeTitle => 'Save your recovery code';

  @override
  String get recoveryCodeBody =>
      'If you forget your PIN or password, this code lets you set a new one. It is shown only now. Write it down or keep it somewhere safe, not only on this device.';

  @override
  String get copy => 'Copy';

  @override
  String get iSavedTheCode => 'I saved the code';

  @override
  String get enterCurrentPin => 'Enter current PIN';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get appLockOffHint =>
      'Off. Ask for a PIN, password or fingerprint before opening iLoveHTML.';

  @override
  String get appLockOnPin => 'On, with a PIN';

  @override
  String get appLockOnPassword => 'On, with a password';

  @override
  String get lockAgainAfter => 'Lock again after leaving the app';

  @override
  String get relockImmediately => 'Immediately';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'After $count minutes',
      one: 'After 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'Only when iLoveHTML starts';

  @override
  String get changePinOrHint => 'Change PIN, password or hint';

  @override
  String get lockNow => 'Lock now';

  @override
  String get turnOffLock => 'Turn off lock';

  @override
  String get newUpdate => 'NEW UPDATE';

  @override
  String updateAvailable(String version) {
    return 'iLoveHTML $version is available';
  }

  @override
  String updateTitle(String version) {
    return 'Update to $version';
  }

  @override
  String youHaveVersion(String version) {
    return 'You have $version.';
  }

  @override
  String get updateAndroidHint =>
      'The APK downloads in your browser. Open it to install over this version; your projects, keys and settings stay.';

  @override
  String get updateWindowsHint =>
      'The ZIP downloads in your browser. Close iLoveHTML, unzip it and replace your iLoveHTML folder; your projects, keys and settings stay.';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get releasePage => 'Release page';

  @override
  String get downloadUpdate => 'Download';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkForUpdatesHint =>
      'About twice a day, ask GitHub if a newer iLoveHTML was released. Nothing about you or your projects is sent.';

  @override
  String get checkNow => 'Check now';

  @override
  String get checkingUpdates => 'Checking…';

  @override
  String get upToDate => 'You have the latest version.';

  @override
  String get updateCheckFailed => 'Could not check. Are you online?';

  @override
  String get updateInAppHint =>
      'iLoveHTML downloads the update, checks it, then Android asks to install it over this version. Your projects, keys and settings stay.';

  @override
  String get verifyingDownload => 'Checking the file…';

  @override
  String downloadingMb(String done) {
    return 'Downloading… $done MB';
  }

  @override
  String downloadingOf(String done, String total) {
    return 'Downloading… $done of $total MB';
  }

  @override
  String get installerOpened =>
      'Android\'s installer is open. Tap Update there. If it closed, tap Install.';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get tryAgain => 'Try again';
}

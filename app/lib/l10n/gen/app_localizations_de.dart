// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String unreadableProject(String name) {
    return 'Projekt nicht lesbar: $name';
  }

  @override
  String get emptyHintWindows =>
      'Mach aus HTML-Dateien, einem Website-ZIP oder einer Live-https-Website eine Android- oder Windows-App. Gebaut wird auf diesem Gerät.';

  @override
  String get emptyHintAndroid =>
      'Mach aus HTML-Dateien, einem Website-ZIP oder einer Live-https-Website eine Android-App. Gebaut wird auf diesem Gerät.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · noch nicht gebaut';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · letzter Build $status $ago';
  }

  @override
  String get justNow => 'gerade eben';

  @override
  String minutesAgo(int n) {
    return 'vor $n Min.';
  }

  @override
  String hoursAgo(int n) {
    return 'vor $n Std.';
  }

  @override
  String daysAgo(int n) {
    return 'vor $n T.';
  }

  @override
  String chooseBackupFile(String ext) {
    return 'Wähle eine $ext-Sicherungsdatei';
  }

  @override
  String restored(String name) {
    return '$name wiederhergestellt';
  }

  @override
  String notUsableBackup(String message) {
    return 'Keine verwendbare Sicherung: $message';
  }

  @override
  String restoreFailed(String error) {
    return 'Wiederherstellen fehlgeschlagen: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien importiert',
      one: '1 Datei importiert',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return 'Startseite: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return '$count HTML-Seiten gefunden; die Startseite kannst du in den Einstellungen ändern.';
  }

  @override
  String filesMissing(int count) {
    return '$count referenzierte Dateien fehlen:';
  }

  @override
  String andMore(int count) {
    return '…und $count weitere';
  }

  @override
  String fileNotFound(String path) {
    return 'Datei nicht gefunden: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'Würde außerhalb der App öffnen: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'Seite konnte nicht geladen werden: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'Vorschau konnte nicht gestartet werden: $error';
  }

  @override
  String previewTitle(String name) {
    return 'Vorschau · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'Website antwortete mit HTTP $code';
  }

  @override
  String redirected(int count) {
    return '$count× weitergeleitet — die App startet unter dieser Adresse.';
  }

  @override
  String importedKey(String alias) {
    return '„$alias“ importiert';
  }

  @override
  String backupSavedAs(String alias) {
    return 'Sicherung als $alias.jks gespeichert. Bewahre das Passwort getrennt davon auf.';
  }

  @override
  String backupFailed(String error) {
    return 'Sicherung fehlgeschlagen: $error';
  }

  @override
  String deletedKey(String alias) {
    return '„$alias“ von diesem Gerät gelöscht';
  }

  @override
  String get releaseKeysIntroWindows =>
      'Release-Builds werden mit einem dieser Schlüssel signiert. Google Play und Android akzeptieren nur Updates, die mit demselben Schlüssel wie die erste Version signiert sind. Die Schlüssel bleiben auf diesem PC, die Passwörter verschlüsselt für dein Windows-Konto; eine Sicherung ist eine passwortgeschützte .jks-Datei, die mit iLoveHTML auf Handy oder Computer, Gradle und keytool funktioniert.';

  @override
  String get releaseKeysIntroAndroid =>
      'Release-Builds werden mit einem dieser Schlüssel signiert. Google Play und Android akzeptieren nur Updates, die mit demselben Schlüssel wie die erste Version signiert sind. Die Schlüssel bleiben auf diesem Handy, verschlüsselt mit dem Android Keystore; eine Sicherung ist eine passwortgeschützte .jks-Datei, die mit iLoveHTML auf Handy oder Computer, Gradle und keytool funktioniert.';

  @override
  String validUntilDate(String date) {
    return 'gültig bis $date';
  }

  @override
  String get atLeast8 => 'Mindestens 8 Zeichen';

  @override
  String deleteKeyBody(String alias) {
    return 'Mit „$alias“ signierte Apps lassen sich nur mit genau diesem Schlüssel aktualisieren. Ohne Sicherung kannst du sie nie wieder aktualisieren.';
  }

  @override
  String typeToConfirm(String alias) {
    return 'Zum Bestätigen „$alias“ eingeben';
  }

  @override
  String backupSaved(String file) {
    return 'Sicherung gespeichert: $file';
  }

  @override
  String shortcutExists(String page) {
    return 'Für „$page“ gibt es schon eine Verknüpfung';
  }

  @override
  String deleteProjectBody(String name) {
    return 'Dadurch werden „$name“, die Website-Dateien und gebauten APKs von diesem Gerät gelöscht. Bereits installierte Apps sind nicht betroffen.';
  }

  @override
  String offlinePageShown(String page) {
    return 'Wenn die Website nicht lädt, wird deine Seite „$page“ angezeigt. Verlinke https://appassets.androidplatform.net/html2apk/retry für einen „Erneut versuchen“-Button.';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal heruntergeladen.',
      one: '1-mal heruntergeladen.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'Dateien konnten nicht gelesen werden: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count Dateien, $size';
  }

  @override
  String checkFailed(String error) {
    return 'Prüfung fehlgeschlagen: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return 'Optimieren verkleinert $count Dateien und spart $saved ($before → $after). Die APK ist ebenfalls komprimiert, daher ist die Ersparnis in der APK bei CSS und JSON oft kleiner.';
  }

  @override
  String example(String value) {
    return 'z. B. $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'Release-Schlüssel konnten nicht geladen werden: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'Diese App wurde zuerst mit einem anderen Schlüssel veröffentlicht (SHA-256 $sha…). Handys mit dieser Version können nicht auf eine mit „$alias“ signierte APK aktualisieren, und Google Play lehnt sie als Update ab.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return 'Herausgeber: $publisher · gültig bis $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return 'Apps aus Installern, die von „$publisher“ signiert sind, lassen sich nur mit Installern desselben Herausgebers aktualisieren. Sichere das aktuelle Zertifikat vorher, falls du es noch brauchst.';
  }

  @override
  String passwordOf(String file) {
    return 'Passwort von $file';
  }

  @override
  String savedFile(String file) {
    return '$file gespeichert';
  }

  @override
  String saveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get cannotBuildYet => 'Noch kein Build möglich:';

  @override
  String get shareFilesHint =>
      'navigator.share() mit Dateien sendet Bilder und PDFs an andere Apps. Ab Android 10 werden geteilte Bilder auch in der Galerie gespeichert.';

  @override
  String get projects => 'Projekte';

  @override
  String get restoreBackup => 'Sicherung wiederherstellen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get newApp => 'Neue App';

  @override
  String get htmlFiles => 'HTML-Dateien';

  @override
  String get htmlFilesHint =>
      'Wähle eine .html-Seite, dazu CSS, JavaScript und Bilder, falls diese separate Dateien sind. Funktioniert offline.';

  @override
  String get websiteZip => 'Website-ZIP';

  @override
  String get websiteZipHint =>
      'Ein ganzer Website-Ordner, gezippt. Funktioniert offline.';

  @override
  String get websiteUrl => 'Website-URL';

  @override
  String get websiteUrlHint =>
      'Verpackt eine Live-https-Website. Braucht eine Internetverbindung.';

  @override
  String get noProjectsYet => 'Noch keine Projekte';

  @override
  String get building => 'Wird gebaut…';

  @override
  String get selectHtmlFile =>
      'Wähle mindestens eine .html-Datei, dazu das verwendete CSS, JavaScript oder Bilder.';

  @override
  String get defaultAppName => 'Meine App';

  @override
  String get appName => 'App-Name';

  @override
  String get enterName => 'Gib einen Namen ein';

  @override
  String get packageId => 'Paket-ID';

  @override
  String get packageIdHelp =>
      'Eindeutige ID auf dem Gerät und in Play, z. B. com.deinname.app';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get importButton => 'Importieren';

  @override
  String get noMissingFiles => 'Keine fehlenden Dateien';

  @override
  String get openProject => 'Projekt öffnen';

  @override
  String get noConsoleMessages => 'Keine Konsolenmeldungen oder Probleme';

  @override
  String get viewport => 'Ansichtsgröße';

  @override
  String get consoleAndIssues => 'Konsole und Probleme';

  @override
  String get checkWebsite => 'Website prüfen';

  @override
  String get websiteReachable => 'Website erreichbar';

  @override
  String get liveSiteNote =>
      'Die App zeigt diese Website live und braucht eine Internetverbindung. Offline funktioniert sie nicht.';

  @override
  String get create => 'Erstellen';

  @override
  String get backUpKeyNow => 'Sichere diesen Schlüssel jetzt';

  @override
  String get backUpKeyBody =>
      'Jedes Update einer App muss mit demselben Schlüssel signiert sein. Geht dieses Gerät verloren oder wird iLoveHTML deinstalliert, ist der Schlüssel weg – außer du hast eine Sicherung.\n\nSpeichere die .jks-Datei an einem sicheren Ort (nicht nur auf diesem Gerät) und bewahre das Passwort getrennt auf.';

  @override
  String get later => 'Später';

  @override
  String get saveBackup => 'Sicherung speichern';

  @override
  String get certificate => 'Zertifikat';

  @override
  String get sha256Fingerprint => 'SHA-256-Fingerabdruck';

  @override
  String get sha1Fingerprint => 'SHA-1-Fingerabdruck';

  @override
  String get validUntil => 'Gültig bis';

  @override
  String get added => 'Hinzugefügt';

  @override
  String get saveBackupJks => 'Sicherung speichern (.jks)';

  @override
  String get delete => 'Löschen';

  @override
  String get releaseKeys => 'Release-Schlüssel';

  @override
  String get createKey => 'Schlüssel erstellen';

  @override
  String get importKeystoreFile => '.jks / .keystore / .p12 importieren';

  @override
  String get noReleaseKeys => 'Noch keine Release-Schlüssel';

  @override
  String get createReleaseKey => 'Release-Schlüssel erstellen';

  @override
  String get keyAlias => 'Schlüssel-Alias';

  @override
  String get keyAliasHelp =>
      'Buchstaben, Ziffern, Punkte, Binde- und Unterstriche';

  @override
  String get publisherNameField => 'Dein Name oder App-Herausgeber';

  @override
  String get required => 'Erforderlich';

  @override
  String get organizationOptional => 'Organisation (optional)';

  @override
  String get countryCodeOptional => 'Ländercode (optional)';

  @override
  String get password => 'Passwort';

  @override
  String get passwordHelp => 'Gilt für den Keystore und den Schlüssel';

  @override
  String get repeatPassword => 'Passwort wiederholen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get createKeyNote =>
      'RSA 2048 Bit, 30 Jahre gültig. Dieses Passwort brauchst du, um die Sicherung auf einem Computer zu nutzen.';

  @override
  String get noPrivateKeys => 'Keine privaten Schlüssel in dieser Datei';

  @override
  String get importKeystore => 'Keystore importieren';

  @override
  String get keystorePassword => 'Keystore-Passwort';

  @override
  String get keyPassword => 'Schlüssel-Passwort';

  @override
  String get keyPasswordHelp =>
      'Leer lassen, wenn es dem Keystore-Passwort entspricht';

  @override
  String get importKeystoreNote =>
      'iLoveHTML behält eine Kopie, geschützt durch das Keystore-Passwort. Deine Originaldatei bleibt unverändert.';

  @override
  String get open => 'Öffnen';

  @override
  String get deleteReleaseKey => 'Release-Schlüssel löschen?';

  @override
  String get deleteKey => 'Schlüssel löschen';

  @override
  String get projectNotFound => 'Projekt nicht gefunden';

  @override
  String get backUpProject => 'Projekt sichern';

  @override
  String get preview => 'Vorschau';

  @override
  String get build => 'Build';

  @override
  String get previewInBrowser => 'Vorschau im Browser';

  @override
  String get liveSiteOpened =>
      'Die Live-Website wurde in deinem Standardbrowser geöffnet.';

  @override
  String get servedFromPc =>
      'Nur von diesem PC bereitgestellt, solange dieses Fenster offen ist. Die Handy-App bietet zusätzlich Konsole und Linkprüfung; hier nutzt du die Entwicklertools des Browsers (F12).';

  @override
  String get missingFiles => 'Fehlende Dateien:';

  @override
  String get close => 'Schließen';

  @override
  String get stopPreview => 'Vorschau beenden';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get iconUpdated => 'Symbol aktualisiert';

  @override
  String get splashUpdated => 'Startbild aktualisiert';

  @override
  String get offlinePageAdded => 'Offline-Seite hinzugefügt';

  @override
  String get deleteProjectQ => 'Projekt löschen?';

  @override
  String get save => 'Speichern';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionContent => 'Inhalt';

  @override
  String get sectionShortcuts => 'Verknüpfungen';

  @override
  String get sectionAppSize => 'App-Größe';

  @override
  String get sectionAppearance => 'Darstellung';

  @override
  String get sectionDevices => 'Geräte';

  @override
  String get sectionSecurity => 'Sicherheit';

  @override
  String get sectionOffline => 'Offline';

  @override
  String get sectionDanger => 'Gefahrenzone';

  @override
  String get versionName => 'Versionsname';

  @override
  String get versionCode => 'Versionscode';

  @override
  String get defaultIcon => 'Standardsymbol';

  @override
  String get customIcon => 'Eigenes Symbol';

  @override
  String get chooseImage => 'Bild wählen';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP oder SVG, mindestens 48 px; 512 × 512 empfohlen. Nicht quadratische Bilder werden zentriert.';

  @override
  String get startPage => 'Startseite';

  @override
  String get loadedLive =>
      'Wird live geladen; die App braucht eine Internetverbindung.';

  @override
  String get otherSites => 'Weitere Websites, die in der App öffnen (optional)';

  @override
  String get otherSitesHelp =>
      'Durch Kommas getrennt. Links zu allen anderen Websites öffnen im Browser.';

  @override
  String get orientation => 'Ausrichtung';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get portrait => 'Hochformat';

  @override
  String get landscape => 'Querformat';

  @override
  String get shortcutsHint =>
      'Halte das App-Symbol gedrückt, um diese Seiten zu sehen.';

  @override
  String get removeShortcut => 'Verknüpfung entfernen';

  @override
  String get addShortcut => 'Verknüpfung hinzufügen';

  @override
  String get optimizeFiles => 'Dateien beim Bauen optimieren';

  @override
  String get optimizeFilesHint =>
      'Verkleinert CSS, JSON, PNG und große JPEG-Dateien in der App. JPEGs werden mit 85 % Qualität neu gespeichert. Deine Projektdateien ändern sich nicht.';

  @override
  String get sizeReport => 'Größenbericht';

  @override
  String get statusBarColour => 'Farbe der Statusleiste';

  @override
  String get navBarColour => 'Farbe der Navigationsleiste';

  @override
  String get splashScreen => 'Startbildschirm';

  @override
  String get splashIconHint =>
      'Zeigt das App-Symbol, bis die erste Seite geladen ist.';

  @override
  String get splashImageHint =>
      'Zeigt dein Startbild, bis die erste Seite geladen ist.';

  @override
  String get splashBackground => 'Hintergrund des Startbildschirms';

  @override
  String get chooseSplash => 'Startbild wählen';

  @override
  String get replaceSplash => 'Startbild ersetzen';

  @override
  String get useAppIcon => 'App-Symbol verwenden';

  @override
  String get theme => 'Design';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get followPhone => 'Wie Handy';

  @override
  String get themeHint =>
      'Setzt prefers-color-scheme, damit Seiten mit Dark-Mode-CSS umschalten.';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get fullscreenHint =>
      'Blendet Status- und Navigationsleiste aus. Wische vom Rand, um sie kurz anzuzeigen.';

  @override
  String get keepScreenOn => 'Bildschirm anlassen';

  @override
  String get keepScreenOnHint =>
      'Der Bildschirm geht nicht aus, solange die App offen ist.';

  @override
  String get tvHint =>
      'Zeigt die App auf dem TV-Startbildschirm mit einem Banner aus Symbol und Name. Die Pfeiltasten der Fernbedienung wechseln zwischen Links und Buttons; OK öffnet sie.';

  @override
  String get rotateTablets => 'Freies Drehen auf Tablets';

  @override
  String get rotateTabletsHint =>
      'Tablets und Foldables dürfen sich in jede Richtung drehen, auch wenn Handys die oben gewählte Ausrichtung behalten. Ab Android 16 ist das auf großen Bildschirmen immer erlaubt.';

  @override
  String get desktopLayout => 'Desktop-Layout auf Tablets und TV';

  @override
  String get desktopLayoutHint =>
      'Fordert von Websites das Layout für Computer statt des Handy-Layouts an.';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get appLockHint =>
      'Fragt beim Öffnen der App und nach 30 Sekunden im Hintergrund nach Fingerabdruck, Gesicht oder Displaysperre. Handys ohne Displaysperre öffnen die App mit einem Hinweis.';

  @override
  String get javascriptHint =>
      'Die meisten Websites brauchen das. Für statische Seiten ausschalten.';

  @override
  String get localStorage => 'Lokaler Speicher';

  @override
  String get internetAccess => 'Internetzugriff';

  @override
  String get internetAccessHint =>
      'Fügt die INTERNET-Berechtigung hinzu, für CDNs, APIs oder Schriften aus dem Web.';

  @override
  String get openOtherSites => 'Andere Websites im Browser öffnen';

  @override
  String get openOtherSitesHint =>
      'Wenn aus, tun Links zu anderen Websites nichts.';

  @override
  String get pullToRefresh => 'Zum Aktualisieren ziehen';

  @override
  String get pullToRefreshHint =>
      'Oben auf einer Seite nach unten wischen, um sie neu zu laden oder es nach einem Fehler erneut zu versuchen.';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsHint =>
      'Die Seite kann über die Web-Notification-API Android-Benachrichtigungen anzeigen, solange die App offen ist. Ab Android 13 wird der Nutzer zuerst gefragt. Keine Push-Nachrichten.';

  @override
  String get backButton => 'Zurück-Taste';

  @override
  String get backHistory => 'Zurückgehen, dann App schließen';

  @override
  String get backTwice => 'Zurückgehen, dann zweimal drücken zum Schließen';

  @override
  String get backConfirm => 'Zurückgehen, dann vor dem Schließen fragen';

  @override
  String get backHome => 'Zur Startseite, dann schließen';

  @override
  String get fileUploads => 'Datei-Uploads';

  @override
  String get fileUploadsHint =>
      'Lässt Dateifelder die Android-Dateiauswahl öffnen. Der Nutzer wählt jede Datei selbst.';

  @override
  String get share => 'Teilen';

  @override
  String get shareHint =>
      'navigator.share öffnet das Android-Teilen-Menü für Text und Links.';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsHint =>
      'Download-Links und erzeugte Dateien werden im Ordner Downloads gespeichert.';

  @override
  String get shareFiles => 'Bilder und PDFs teilen';

  @override
  String get galleryFolder => 'Galerie-Ordner (optional)';

  @override
  String get galleryFolderExample => 'z. B. Meine Fotos';

  @override
  String get galleryFolderHelp =>
      'Pictures/<Ordner> für geteilte und heruntergeladene Bilder. Leer: der App-Name beim Teilen, Downloads für Downloads.';

  @override
  String get shareToApp => 'Direkt an App teilen (optional)';

  @override
  String get shareToAppHelp =>
      'Paket, das geteilte Dateien direkt öffnet, wenn es installiert ist, statt des Teilen-Menüs.';

  @override
  String get usePackageName => 'Verwende einen Paketnamen wie com.whatsapp';

  @override
  String get offlineBuiltIn =>
      'Wenn die Website nicht lädt, wird ein eingebauter Bildschirm „Seite nicht verfügbar“ angezeigt.';

  @override
  String get chooseOfflinePage => 'Offline-Seite wählen (.html)';

  @override
  String get replaceOfflinePage => 'Offline-Seite ersetzen';

  @override
  String get useBuiltInPage => 'Eingebaute Seite verwenden';

  @override
  String get userAgentSuffix => 'User-Agent-Zusatz (optional)';

  @override
  String get atMost200 => 'Höchstens 200 Zeichen';

  @override
  String get deleteProject => 'Projekt löschen';

  @override
  String get useColourLike => 'Verwende eine Farbe wie #1A73E8';

  @override
  String get noNetwork =>
      'Dieser Computer ist nicht in einem WLAN- oder Ethernet-Netzwerk.';

  @override
  String get installOnPhone => 'Auf Handy installieren';

  @override
  String get installSteps =>
      '1. Verbinde das Handy mit demselben WLAN wie diesen Computer.\n2. Scanne den Code mit der Handykamera und öffne den Link.\n3. Öffne die heruntergeladene Datei. Erlaube Installationen aus dem Browser, wenn Android fragt.';

  @override
  String get linkStopped => 'Der Link wurde beendet.';

  @override
  String get networkAddress => 'Netzwerkadresse';

  @override
  String get linkWorks10Min =>
      'Der Link funktioniert 10 Minuten, solange dieses Fenster offen ist.';

  @override
  String get trustedNetworkOnly =>
      'Nutze das nur in einem vertrauenswürdigen Netzwerk. Windows fragt eventuell, ob iLoveHTML durch die Firewall darf: Erlaube es für private Netzwerke.';

  @override
  String get startAgain => 'Neu starten';

  @override
  String get done => 'Fertig';

  @override
  String get kindPages => 'Seiten';

  @override
  String get kindImages => 'Bilder';

  @override
  String get kindFonts => 'Schriften';

  @override
  String get kindMedia => 'Audio und Video';

  @override
  String get kindData => 'Daten';

  @override
  String get kindOther => 'Sonstiges';

  @override
  String get largestFiles => 'Größte Dateien';

  @override
  String get advice => 'Tipps';

  @override
  String get checkOptimizing => 'Prüfen, was Optimieren spart';

  @override
  String get name => 'Name';

  @override
  String get exampleCart => 'z. B. Warenkorb';

  @override
  String get choosePage => 'Wähle eine Seite';

  @override
  String get page => 'Seite';

  @override
  String get add => 'Hinzufügen';

  @override
  String get differentKey => 'Anderer Release-Schlüssel';

  @override
  String get buildAnyway => 'Trotzdem bauen';

  @override
  String get windowsExe => 'Windows-App (.exe)';

  @override
  String get exeDescription =>
      'Eine einzige .exe-Datei, die diese Website in einem eigenen Fenster mit Microsoft Edge WebView2 öffnet (in Windows 11 und aktuellem Windows 10 enthalten). Sie ist nicht signiert, daher zeigt Windows eventuell „Der Computer wurde durch Windows geschützt“, bis man Weitere Informationen → Trotzdem ausführen wählt.';

  @override
  String get devTools => 'Entwicklertools (zum Testen)';

  @override
  String get devToolsHint =>
      'F12 und Untersuchen funktionieren in der App; für die geteilte Version aus lassen';

  @override
  String get buildExe => '.exe bauen';

  @override
  String get windowsMsix => 'Windows-Installer (.msix)';

  @override
  String get msixDescription =>
      'Installiert die App wie andere Windows-Software: Startmenü-Eintrag, saubere Deinstallation und Updates, wenn du eine höhere Version teilst. Jeder Installer wird mit einem Zertifikat signiert.';

  @override
  String get needsWindowsSdk =>
      'Benötigt das Windows SDK. Installieren mit:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      'Noch kein Zertifikat. Verwende dein eigenes Code-Signing-Zertifikat oder erstelle ein Testzertifikat zum Ausprobieren.';

  @override
  String get testCertNote =>
      'Testzertifikat: Windows installiert die App erst, nachdem man ihm einmal vertraut. Teile die .cer-Datei mit dem Installer; doppelklicken → Zertifikat installieren → Lokaler Computer → „Vertrauenswürdige Personen“. Ein bei einer Zertifizierungsstelle gekauftes Zertifikat braucht diesen Schritt nicht.';

  @override
  String get createTestCert => 'Testzertifikat erstellen';

  @override
  String get useMyPfx => 'Meine .pfx verwenden';

  @override
  String get savedCertificate => 'Zertifikat gespeichert';

  @override
  String get saveCer => '.cer speichern';

  @override
  String get buildInstaller => 'Installer bauen';

  @override
  String get replaceCertQ => 'Zertifikat ersetzen?';

  @override
  String get replace => 'Ersetzen';

  @override
  String get publisherName => 'Herausgebername';

  @override
  String get publisherNameHelp =>
      'Wird als Herausgeber angezeigt, wenn deine Apps installiert werden.';

  @override
  String get testCertCreated => 'Testzertifikat erstellt';

  @override
  String get useMyCertificate => 'Mein Zertifikat verwenden';

  @override
  String get certificateAdded => 'Zertifikat hinzugefügt';

  @override
  String get ok => 'OK';

  @override
  String get allowUnknownApps =>
      'Erlaube „Unbekannte Apps installieren“ für iLoveHTML im geöffneten Bildschirm und tippe dann erneut auf Installieren.';

  @override
  String get debug => 'Debug';

  @override
  String get release => 'Release';

  @override
  String get debugHint =>
      'Zum Testen. Signiert mit einem Debug-Schlüssel, der auf diesem Gerät bleibt; nicht zum Veröffentlichen.';

  @override
  String get releaseHint =>
      'Zum Veröffentlichen. Signiert mit deinem Release-Schlüssel; jedes spätere Update braucht denselben Schlüssel und einen höheren Versionscode.';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      'Lade die .aab in die Google Play Console hoch. Sie lässt sich nicht direkt installieren; teste auf dem Handy mit einer APK.';

  @override
  String get createOrImportKey =>
      'Release-Schlüssel erstellen oder importieren';

  @override
  String get releaseKey => 'Release-Schlüssel';

  @override
  String get manageKeys => 'Schlüssel verwalten';

  @override
  String get buildDebugApk => 'Debug-APK bauen';

  @override
  String get buildAppBundle => 'App Bundle bauen';

  @override
  String get buildReleaseApk => 'Release-APK bauen';

  @override
  String get buildingUnavailable =>
      'Bauen ist auf dieser Plattform noch nicht verfügbar.';

  @override
  String get buildFailed => 'Build fehlgeschlagen';

  @override
  String get saveAs => 'Speichern unter…';

  @override
  String get showInFolder => 'Im Ordner anzeigen';

  @override
  String get install => 'Installieren';

  @override
  String get saveToDevice => 'Auf Gerät speichern';

  @override
  String get buildLog => 'Build-Protokoll';

  @override
  String get history => 'Verlauf';

  @override
  String get twoLetters => 'Zwei Buchstaben';

  @override
  String invalidHost(String host) {
    return 'Ungültiger Host „$host“';
  }

  @override
  String get thisDevice => 'Dieses Gerät';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wird gebaut… $count Protokollzeilen',
      one: 'Wird gebaut… 1 Protokollzeile',
      zero: 'Wird gebaut…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get accentColour => 'Akzentfarbe';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentGreen => 'Terminal-Grün';

  @override
  String get accentCyan => 'Cyan';

  @override
  String get accentViolet => 'Violett';

  @override
  String get accentPink => 'Pink';

  @override
  String get animations => 'Animationen';

  @override
  String get animationsHint =>
      'ASCII-Startbild, Build-Animation und Seitenübergänge';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get signing => 'Signieren';

  @override
  String get releaseKeysSubtitle =>
      'Schlüssel für deine Releases erstellen, importieren und sichern';

  @override
  String get storage => 'Speicher';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Projekte · $size',
      one: '1 Projekt · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'Build-Engine';

  @override
  String get notAvailablePlatform =>
      'Auf dieser Plattform noch nicht verfügbar';

  @override
  String get gradleReady => 'Gradle auf diesem PC (bereit)';

  @override
  String get gradleNotReady => 'Gradle auf diesem PC: nicht bereit';

  @override
  String get buildsRunOnPc =>
      'Builds laufen komplett auf diesem PC. Es werden keine Dateien hochgeladen.';

  @override
  String get onDeviceReady => 'Bau auf dem Gerät (bereit)';

  @override
  String get onDeviceMissing => 'Bau auf dem Gerät: Basis-APK fehlt';

  @override
  String get buildsRunOnDevice =>
      'Builds laufen komplett auf diesem Gerät. Es werden keine Dateien hochgeladen.';

  @override
  String get about => 'Info';

  @override
  String get howToUse => 'Anleitung';

  @override
  String get howToUseSubtitle =>
      'Von der Website zur installierten App in fünf Schritten';

  @override
  String get termsOfUse => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get version => 'Version';

  @override
  String get versionCopied => 'Version kopiert';

  @override
  String get credit => 'Danksagung';

  @override
  String madeBy(String author) {
    return 'Mit <3 gemacht von $author';
  }

  @override
  String get supportHint =>
      'iLoveHTML ist kostenlos, ohne Werbung und ohne Tracking. Wenn es dir Zeit spart, kannst du die Entwicklung unterstützen.';

  @override
  String get buyMeACoffee => 'Spendier mir einen Kaffee';

  @override
  String couldNotOpenLink(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String lastUpdated(String date) {
    return 'Zuletzt aktualisiert: $date';
  }

  @override
  String get howToStep1Title => 'Projekt anlegen';

  @override
  String get howToStep1Body =>
      'Tippe auf Neue App und wähle HTML-Dateien, ein Website-ZIP oder die URL einer Live-https-Website. Dateien und ZIPs funktionieren offline; eine URL braucht Internet.';

  @override
  String get howToStep2Title => 'App benennen';

  @override
  String get howToStep2Body =>
      'Gib den App-Namen und eine eindeutige Paket-ID wie com.deinname.app ein. Behalte die Paket-ID bei jedem Update bei.';

  @override
  String get howToStep3Title => 'Anpassen';

  @override
  String get howToStep3Body =>
      'Wähle im Tab Einstellungen Startseite, Symbol, Startbildschirm, Farben, Ausrichtung, Verknüpfungen und WebView-Funktionen. Tippe zum Schluss auf Speichern. Mit Vorschau probierst du die App vorher aus.';

  @override
  String get howToStep4Title => 'Bauen';

  @override
  String get howToStep4Body =>
      'Wähle im Tab Build Debug zum Testen oder Release zum Veröffentlichen. Release-Builds brauchen einen Release-Schlüssel: erstelle ihn und sichere ihn. Unter Windows kannst du auch eine .exe oder einen .msix-Installer bauen.';

  @override
  String get howToStep5Title => 'Installieren oder teilen';

  @override
  String get howToStep5Body =>
      'Installiere die APK auf diesem Handy, teile oder speichere sie. Am PC sendest du sie mit Auf Handy installieren per WLAN. App Bundles (.aab) lädst du in die Google Play Console hoch.';

  @override
  String get howToTipsTitle => 'Tipps';

  @override
  String get howToTips =>
      '• Jedes Update braucht dieselbe Paket-ID, denselben Release-Schlüssel und einen höheren Versionscode.\n• Sichere deine Release-Schlüssel und Projekte; einen verlorenen Schlüssel kann niemand wiederherstellen.\n• Mit dem Größenbericht machst du die App kleiner.\n• Mit Projekt sichern (oben in einem Projekt) behältst du eine Kopie, die du später wiederherstellen kannst.';

  @override
  String get termsBody =>
      'Diese Nutzungsbedingungen gelten für die App iLoveHTML („die App“) von 1elevenop. Mit der Nutzung der App stimmst du ihnen zu.\n\n## Was die App macht\n\niLoveHTML macht aus HTML-Dateien, Website-ZIPs und Webadressen Android- und Windows-Apps. Builds laufen auf deinem eigenen Gerät.\n\n## Deine Inhalte\n\nAlle Rechte an den Websites, Dateien, Symbolen und Apps, die du erstellst, bleiben bei dir. Du bist dafür verantwortlich, diese Inhalte nutzen zu dürfen, und für die Apps, die du baust und veröffentlichst – einschließlich der Einhaltung von Gesetzen und den Regeln von App-Stores wie Google Play.\n\n## Zulässige Nutzung\n\nNutze die App nicht, um Software zu bauen, die illegal, schädlich oder irreführend ist oder Rechte anderer verletzt, etwa Malware oder Apps, die andere Marken nachahmen.\n\n## Release-Schlüssel\n\nRelease-Schlüssel werden nur auf deinem Gerät gespeichert. Du bist für ihre Sicherung und die Sicherheit ihrer Passwörter verantwortlich. Ein verlorener Schlüssel lässt sich nicht wiederherstellen, und damit signierte Apps können dann nicht mehr aktualisiert werden.\n\n## Keine Gewährleistung\n\nDie App wird kostenlos und „wie besehen“ ohne jegliche Gewährleistung bereitgestellt. Soweit gesetzlich zulässig, haftet der Autor nicht für den Verlust von Daten, Schlüsseln, Einnahmen oder sonstige Schäden aus ihrer Nutzung.\n\n## Änderungen\n\nDiese Bedingungen können sich mit neuen Versionen der App ändern. Das Datum oben zeigt die letzte Änderung. Wer die App weiter nutzt, akzeptiert die aktualisierten Bedingungen.\n\n## Kontakt\n\nFragen: Eröffne ein Issue im GitHub-Projekt iLoveHTML von 1elevenop.';

  @override
  String get privacyBody =>
      'iLoveHTML ist dafür gemacht, auf deinem Gerät zu arbeiten. Diese Erklärung beschreibt, was das für deine Daten bedeutet.\n\n## Welche Daten wir erheben\n\nKeine. Die App hat keine Konten, keine Analysen, keine Werbung und kein Tracking. Der Autor erhält keine Daten über dich oder deine Projekte.\n\n## Auf deinem Gerät gespeicherte Daten\n\nDeine Projekte, Website-Dateien, Symbole, Build-Ergebnisse und Einstellungen liegen im privaten Speicher der App auf deinem Gerät. Auch Release-Schlüssel bleiben auf deinem Gerät: Unter Android sind sie mit dem Android Keystore verschlüsselt, unter Windows sind ihre Passwörter für dein Windows-Konto verschlüsselt. Beim Deinstallieren der App werden diese Daten gelöscht – mach also Sicherungen.\n\n## Netzwerknutzung\n\nDie App verbindet sich nur mit dem Internet, wenn du es willst: um eine eingegebene Website-URL zu prüfen oder in der Vorschau zu zeigen, um Links wie Buy Me a Coffee in deinem Browser zu öffnen und unter Windows, wenn Gradle Build-Werkzeuge herunterlädt. Die Funktion Auf Handy installieren stellt die Datei 10 Minuten lang in deinem lokalen Netzwerk bereit, nur solange ihr Fenster offen ist.\n\n## Apps, die du baust\n\nMit iLoveHTML gebaute Apps enthalten kein Tracking von iLoveHTML. Was sie erheben, hängt von der Website ab, die du einbindest, und du bist für ihre Datenschutzerklärung verantwortlich.\n\n## Kinder\n\nDie App erhebt wissentlich keine Daten, weder von Kindern noch von sonst jemandem.\n\n## Änderungen und Kontakt\n\nDiese Erklärung kann sich mit neuen Versionen der App ändern; das Datum oben zeigt die letzte Änderung. Fragen: Eröffne ein Issue im GitHub-Projekt iLoveHTML von 1elevenop.';

  @override
  String get replaceWebsite => 'Website-Dateien ersetzen';

  @override
  String get replaceWebsiteHint =>
      'Neues ZIP oder neue HTML-Dateien einsetzen. Name, Paket-ID, Symbol, Einstellungen und Schlüssel bleiben gleich.';

  @override
  String get replaceWithZipHint => 'Ein neuer, gezippter Website-Ordner';

  @override
  String get replaceWithFilesHint =>
      'Neue .html-Seiten mit CSS, JavaScript und Bildern';

  @override
  String get replaceWebsiteQ => 'Website ersetzen?';

  @override
  String replaceWebsiteBody(String name) {
    return 'Alle Website-Dateien von „$name“ werden durch die als Nächstes gewählten ersetzt. App-Name, Paket-ID, Version, Symbol, Einstellungen, Release-Schlüssel und Build-Verlauf bleiben. Baue danach neu, um die aktualisierte App zu erhalten.';
  }

  @override
  String replaceFailed(String error) {
    return 'Website konnte nicht ersetzt werden: $error';
  }

  @override
  String get websiteReplaced => 'Website ersetzt';

  @override
  String startPageChanged(String page) {
    return '„$page“ fehlt in den neuen Dateien, daher wurde die Startseite geändert.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'Verknüpfungen entfernt, weil ihre Seiten fehlen: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      'Baue neu, um die aktualisierte App zu erhalten. Um eine installierte App zu aktualisieren, erhöhe zuerst den Versionscode.';

  @override
  String get unlockReason => 'iLoveHTML entsperren';

  @override
  String get resetReason =>
      'Bestätige deine Identität, um die iLoveHTML-Sperre zurückzusetzen';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Falsch. Noch $count Versuche bis zur Wartezeit.',
      one: 'Falsch. Noch 1 Versuch bis zur Wartezeit.',
      zero: 'Falsch. Warte, bevor du es erneut versuchst.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return 'Zu viele falsche Versuche. Erneut in $seconds s.';
  }

  @override
  String get enterPin => 'PIN eingeben';

  @override
  String get enterPassword => 'Passwort eingeben';

  @override
  String get showPassword => 'Anzeigen';

  @override
  String get hidePassword => 'Verbergen';

  @override
  String hintIs(String hint) {
    return 'Hinweis: $hint';
  }

  @override
  String get showHint => 'Hinweis anzeigen';

  @override
  String get deleteDigit => 'Löschen';

  @override
  String get unlock => 'Entsperren';

  @override
  String get useFingerprint => 'Fingerabdruck oder Gesicht';

  @override
  String get forgotPin => 'PIN vergessen?';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String digitsEntered(int count) {
    return '$count Ziffern eingegeben';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Falscher Code. Noch $count Versuche.',
      one: 'Falscher Code. Noch 1 Versuch.',
      zero: 'Falscher Code. Warte, bevor du es erneut versuchst.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'Gerätesperre verwenden';

  @override
  String get forgotWithDeviceHint =>
      'Bestätige mit Fingerabdruck, Gesicht oder der Displaysperre des Handys (PIN, Muster oder Passwort) und wähle dann einen neuen für iLoveHTML.';

  @override
  String get verifyWithDevice => 'Mit Gerätesperre bestätigen';

  @override
  String get forgotWithCode => 'Wiederherstellungscode verwenden';

  @override
  String get forgotWithCodeHint =>
      'Der 16-stellige Code, der beim Einrichten der Sperre angezeigt wurde.';

  @override
  String get recoveryCode => 'Wiederherstellungscode';

  @override
  String get useRecoveryCode => 'Code verwenden';

  @override
  String get forgotNoWay =>
      'Ohne beides lässt sich die Sperre nur entfernen, indem du die App-Daten von iLoveHTML in den Systemeinstellungen löschst. Dabei werden alle Projekte und Release-Schlüssel auf diesem Gerät gelöscht.';

  @override
  String get pinDigitsOnly => 'Nur Ziffern';

  @override
  String pinLength(int min, int max) {
    return '$min bis $max Ziffern';
  }

  @override
  String passwordMinLength(int count) {
    return 'Mindestens $count Zeichen';
  }

  @override
  String get chooseNewSecret => 'Neue PIN oder neues Passwort wählen';

  @override
  String get setUpAppLock => 'App-Sperre einrichten';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => 'Neue PIN';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get repeatPin => 'PIN wiederholen';

  @override
  String get pinsDoNotMatch => 'PINs stimmen nicht überein';

  @override
  String get hintOptional => 'Hinweis (optional)';

  @override
  String get hintHelp =>
      'Wird auf dem Sperrbildschirm angezeigt, damit du dich erinnerst. Jeder mit dem Gerät kann ihn lesen.';

  @override
  String get hintGivesAway =>
      'Der Hinweis darf die PIN oder das Passwort nicht enthalten';

  @override
  String get unlockWithFingerprint =>
      'Mit Fingerabdruck oder Gesicht entsperren';

  @override
  String get unlockWithFingerprintHint =>
      'Deine PIN oder dein Passwort funktioniert weiterhin.';

  @override
  String get appLockNote =>
      'Die Sperre verbirgt iLoveHTML und seine Projekte vor Personen, die dieses Gerät in die Hand nehmen. Die Projektdateien werden nicht verschlüsselt.';

  @override
  String get saveAndContinue => 'Speichern';

  @override
  String get recoveryCodeTitle => 'Wiederherstellungscode sichern';

  @override
  String get recoveryCodeBody =>
      'Wenn du PIN oder Passwort vergisst, kannst du mit diesem Code ein neues festlegen. Er wird nur jetzt angezeigt. Schreib ihn auf oder bewahre ihn sicher auf, nicht nur auf diesem Gerät.';

  @override
  String get copy => 'Kopieren';

  @override
  String get iSavedTheCode => 'Ich habe den Code gesichert';

  @override
  String get enterCurrentPin => 'Aktuelle PIN eingeben';

  @override
  String get enterCurrentPassword => 'Aktuelles Passwort eingeben';

  @override
  String get wrongPin => 'Falsche PIN';

  @override
  String get wrongPassword => 'Falsches Passwort';

  @override
  String get appLockOffHint =>
      'Aus. Vor dem Öffnen von iLoveHTML nach PIN, Passwort oder Fingerabdruck fragen.';

  @override
  String get appLockOnPin => 'An, mit PIN';

  @override
  String get appLockOnPassword => 'An, mit Passwort';

  @override
  String get lockAgainAfter => 'Erneut sperren nach Verlassen der App';

  @override
  String get relockImmediately => 'Sofort';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nach $count Minuten',
      one: 'Nach 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'Nur beim Start von iLoveHTML';

  @override
  String get changePinOrHint => 'PIN, Passwort oder Hinweis ändern';

  @override
  String get lockNow => 'Jetzt sperren';

  @override
  String get turnOffLock => 'Sperre ausschalten';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String unreadableProject(String name) {
    return 'Projet illisible : $name';
  }

  @override
  String get emptyHintWindows =>
      'Transformez des fichiers HTML, un ZIP de site ou un site https en ligne en app Android ou Windows. Tout est compilé sur cet appareil.';

  @override
  String get emptyHintAndroid =>
      'Transformez des fichiers HTML, un ZIP de site ou un site https en ligne en app Android. Tout est compilé sur cet appareil.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · pas encore compilée';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · dernière compilation $status $ago';
  }

  @override
  String get justNow => 'à l\'instant';

  @override
  String minutesAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String hoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String daysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String chooseBackupFile(String ext) {
    return 'Choisissez un fichier de sauvegarde $ext';
  }

  @override
  String restored(String name) {
    return '$name restauré';
  }

  @override
  String notUsableBackup(String message) {
    return 'Sauvegarde inutilisable : $message';
  }

  @override
  String restoreFailed(String error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String importFailed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers importés',
      one: '1 fichier importé',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return 'Page de démarrage : $page';
  }

  @override
  String htmlPagesFound(int count) {
    return '$count pages HTML trouvées ; vous pouvez changer la page de démarrage dans Réglages.';
  }

  @override
  String filesMissing(int count) {
    return '$count fichiers référencés sont manquants :';
  }

  @override
  String andMore(int count) {
    return '…et $count de plus';
  }

  @override
  String fileNotFound(String path) {
    return 'Fichier introuvable : $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'S\'ouvrirait hors de l\'app : $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'La page n\'a pas pu se charger : $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'Impossible de lancer l\'aperçu : $error';
  }

  @override
  String previewTitle(String name) {
    return 'Aperçu · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'Le site a répondu HTTP $code';
  }

  @override
  String redirected(int count) {
    return 'Redirigé $count× — l\'app démarrera à cette adresse.';
  }

  @override
  String importedKey(String alias) {
    return '« $alias » importée';
  }

  @override
  String backupSavedAs(String alias) {
    return 'Sauvegarde enregistrée sous $alias.jks. Conservez le mot de passe à part.';
  }

  @override
  String backupFailed(String error) {
    return 'Échec de la sauvegarde : $error';
  }

  @override
  String deletedKey(String alias) {
    return '« $alias » supprimée de cet appareil';
  }

  @override
  String get releaseKeysIntroWindows =>
      'Les versions de publication sont signées avec l\'une de ces clés. Google Play et Android n\'acceptent que les mises à jour signées avec la même clé que la première version. Les clés restent sur ce PC, avec des mots de passe chiffrés pour votre compte Windows ; une sauvegarde est un fichier .jks protégé par mot de passe, utilisable avec iLoveHTML sur un téléphone ou un ordinateur, Gradle et keytool.';

  @override
  String get releaseKeysIntroAndroid =>
      'Les versions de publication sont signées avec l\'une de ces clés. Google Play et Android n\'acceptent que les mises à jour signées avec la même clé que la première version. Les clés restent sur ce téléphone, chiffrées avec Android Keystore ; une sauvegarde est un fichier .jks protégé par mot de passe, utilisable avec iLoveHTML sur un téléphone ou un ordinateur, Gradle et keytool.';

  @override
  String validUntilDate(String date) {
    return 'valide jusqu\'au $date';
  }

  @override
  String get atLeast8 => 'Au moins 8 caractères';

  @override
  String deleteKeyBody(String alias) {
    return 'Les apps signées avec « $alias » ne peuvent être mises à jour qu\'avec cette clé exacte. Sans sauvegarde, vous ne pourrez plus jamais les mettre à jour.';
  }

  @override
  String typeToConfirm(String alias) {
    return 'Tapez « $alias » pour confirmer';
  }

  @override
  String backupSaved(String file) {
    return 'Sauvegarde enregistrée : $file';
  }

  @override
  String shortcutExists(String page) {
    return 'Un raccourci pour « $page » existe déjà';
  }

  @override
  String deleteProjectBody(String name) {
    return 'Cela supprime « $name », ses fichiers web et les APK compilés de cet appareil. Les apps déjà installées ne sont pas affectées.';
  }

  @override
  String offlinePageShown(String page) {
    return 'Quand le site ne se charge pas, votre page « $page » s\'affiche. Ajoutez un lien vers https://appassets.androidplatform.net/html2apk/retry pour un bouton « Réessayer ».';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Téléchargé $count fois.',
      one: 'Téléchargé 1 fois.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'Impossible de lire les fichiers : $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count fichiers, $size';
  }

  @override
  String checkFailed(String error) {
    return 'Échec de la vérification : $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return 'L\'optimisation réduit $count fichiers et économise $saved ($before → $after). L\'APK est aussi compressé, donc le gain sur l\'APK est souvent plus faible pour le CSS et le JSON.';
  }

  @override
  String example(String value) {
    return 'ex. $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'Impossible de charger les clés de publication : $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'Cette app a d\'abord été publiée avec une autre clé (SHA-256 $sha…). Les téléphones qui ont installé cette version ne peuvent pas passer à un APK signé avec « $alias », et Google Play le refusera comme mise à jour.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return 'Éditeur : $publisher · valide jusqu\'au $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return 'Les apps installées avec des installateurs signés par « $publisher » ne se mettent à jour qu\'avec des installateurs du même éditeur. Sauvegardez d\'abord le certificat actuel si vous risquez d\'en avoir besoin.';
  }

  @override
  String passwordOf(String file) {
    return 'Mot de passe de $file';
  }

  @override
  String savedFile(String file) {
    return '$file enregistré';
  }

  @override
  String saveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get cannotBuildYet => 'Compilation impossible pour le moment :';

  @override
  String get shareFilesHint =>
      'navigator.share() avec des fichiers envoie images et PDF à d\'autres apps. Sous Android 10+, les images partagées sont aussi enregistrées dans la galerie.';

  @override
  String get projects => 'Projets';

  @override
  String get restoreBackup => 'Restaurer une sauvegarde';

  @override
  String get settings => 'Réglages';

  @override
  String get newApp => 'Nouvelle app';

  @override
  String get htmlFiles => 'Fichiers HTML';

  @override
  String get htmlFilesHint =>
      'Choisissez une page .html, avec son CSS, son JavaScript et ses images s\'ils sont séparés. Fonctionne hors ligne.';

  @override
  String get websiteZip => 'ZIP de site web';

  @override
  String get websiteZipHint =>
      'Un dossier de site complet, compressé. Fonctionne hors ligne.';

  @override
  String get websiteUrl => 'URL du site web';

  @override
  String get websiteUrlHint =>
      'Emballe un site https en ligne. Nécessite une connexion internet.';

  @override
  String get noProjectsYet => 'Aucun projet pour le moment';

  @override
  String get building => 'Compilation…';

  @override
  String get selectHtmlFile =>
      'Sélectionnez au moins un fichier .html, avec le CSS, le JavaScript ou les images qu\'il utilise.';

  @override
  String get defaultAppName => 'Mon app';

  @override
  String get appName => 'Nom de l\'app';

  @override
  String get enterName => 'Saisissez un nom';

  @override
  String get packageId => 'ID du paquet';

  @override
  String get packageIdHelp =>
      'ID unique sur l\'appareil et sur Play, ex. com.votrenom.app';

  @override
  String get cancel => 'Annuler';

  @override
  String get importButton => 'Importer';

  @override
  String get noMissingFiles => 'Aucun fichier manquant';

  @override
  String get openProject => 'Ouvrir le projet';

  @override
  String get noConsoleMessages => 'Aucun message ni problème dans la console';

  @override
  String get viewport => 'Fenêtre d\'affichage';

  @override
  String get consoleAndIssues => 'Console et problèmes';

  @override
  String get checkWebsite => 'Vérifier le site';

  @override
  String get websiteReachable => 'Site accessible';

  @override
  String get liveSiteNote =>
      'L\'app affiche ce site en direct et nécessite une connexion internet. Elle ne fonctionne pas hors ligne.';

  @override
  String get create => 'Créer';

  @override
  String get backUpKeyNow => 'Sauvegardez cette clé maintenant';

  @override
  String get backUpKeyBody =>
      'Chaque mise à jour d\'une app doit être signée avec la même clé. Si cet appareil est perdu ou iLoveHTML désinstallé, la clé disparaît sauf si vous avez une sauvegarde.\n\nEnregistrez le fichier .jks en lieu sûr (pas seulement sur cet appareil) et conservez le mot de passe à part.';

  @override
  String get later => 'Plus tard';

  @override
  String get saveBackup => 'Enregistrer la sauvegarde';

  @override
  String get certificate => 'Certificat';

  @override
  String get sha256Fingerprint => 'Empreinte SHA-256';

  @override
  String get sha1Fingerprint => 'Empreinte SHA-1';

  @override
  String get validUntil => 'Valide jusqu\'au';

  @override
  String get added => 'Ajoutée';

  @override
  String get saveBackupJks => 'Enregistrer la sauvegarde (.jks)';

  @override
  String get delete => 'Supprimer';

  @override
  String get releaseKeys => 'Clés de publication';

  @override
  String get createKey => 'Créer une clé';

  @override
  String get importKeystoreFile => 'Importer .jks / .keystore / .p12';

  @override
  String get noReleaseKeys => 'Aucune clé de publication';

  @override
  String get createReleaseKey => 'Créer une clé de publication';

  @override
  String get keyAlias => 'Alias de la clé';

  @override
  String get keyAliasHelp => 'Lettres, chiffres, points, tirets, tirets bas';

  @override
  String get publisherNameField => 'Votre nom ou l\'éditeur de l\'app';

  @override
  String get required => 'Obligatoire';

  @override
  String get organizationOptional => 'Organisation (facultatif)';

  @override
  String get countryCodeOptional => 'Code pays (facultatif)';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHelp => 'Utilisé pour le magasin de clés et la clé';

  @override
  String get repeatPassword => 'Répétez le mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get createKeyNote =>
      'RSA 2048 bits, valide 30 ans. Ce mot de passe sera nécessaire pour utiliser la sauvegarde sur un ordinateur.';

  @override
  String get noPrivateKeys => 'Aucune clé privée dans ce fichier';

  @override
  String get importKeystore => 'Importer un magasin de clés';

  @override
  String get keystorePassword => 'Mot de passe du magasin';

  @override
  String get keyPassword => 'Mot de passe de la clé';

  @override
  String get keyPasswordHelp =>
      'Laissez vide s\'il est identique à celui du magasin';

  @override
  String get importKeystoreNote =>
      'iLoveHTML garde une copie protégée par le mot de passe du magasin. Votre fichier d\'origine n\'est pas modifié.';

  @override
  String get open => 'Ouvrir';

  @override
  String get deleteReleaseKey => 'Supprimer la clé de publication ?';

  @override
  String get deleteKey => 'Supprimer la clé';

  @override
  String get projectNotFound => 'Projet introuvable';

  @override
  String get backUpProject => 'Sauvegarder le projet';

  @override
  String get preview => 'Aperçu';

  @override
  String get build => 'Compiler';

  @override
  String get previewInBrowser => 'Aperçu dans votre navigateur';

  @override
  String get liveSiteOpened =>
      'Le site en ligne s\'est ouvert dans votre navigateur par défaut.';

  @override
  String get servedFromPc =>
      'Servi uniquement depuis ce PC, tant que cette fenêtre est ouverte. L\'app pour téléphone ajoute une console et la vérification des liens ; ici, utilisez les outils de développement du navigateur (F12).';

  @override
  String get missingFiles => 'Fichiers manquants :';

  @override
  String get close => 'Fermer';

  @override
  String get stopPreview => 'Arrêter l\'aperçu';

  @override
  String get settingsSaved => 'Réglages enregistrés';

  @override
  String get iconUpdated => 'Icône mise à jour';

  @override
  String get splashUpdated => 'Image d\'accueil mise à jour';

  @override
  String get offlinePageAdded => 'Page hors ligne ajoutée';

  @override
  String get deleteProjectQ => 'Supprimer le projet ?';

  @override
  String get save => 'Enregistrer';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionContent => 'Contenu';

  @override
  String get sectionShortcuts => 'Raccourcis';

  @override
  String get sectionAppSize => 'Taille de l\'app';

  @override
  String get sectionAppearance => 'Apparence';

  @override
  String get sectionDevices => 'Appareils';

  @override
  String get sectionSecurity => 'Sécurité';

  @override
  String get sectionOffline => 'Hors ligne';

  @override
  String get sectionDanger => 'Zone de danger';

  @override
  String get versionName => 'Nom de version';

  @override
  String get versionCode => 'Code de version';

  @override
  String get defaultIcon => 'Icône par défaut';

  @override
  String get customIcon => 'Icône personnalisée';

  @override
  String get chooseImage => 'Choisir une image';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP ou SVG, au moins 48 px ; 512 × 512 recommandé. Les images non carrées sont centrées.';

  @override
  String get startPage => 'Page de démarrage';

  @override
  String get loadedLive =>
      'Chargée en direct ; l\'app nécessite une connexion internet.';

  @override
  String get otherSites =>
      'Autres sites qui s\'ouvrent dans l\'app (facultatif)';

  @override
  String get otherSitesHelp =>
      'Séparés par des virgules. Les liens vers tout autre site s\'ouvrent dans le navigateur.';

  @override
  String get orientation => 'Orientation';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get portrait => 'Portrait';

  @override
  String get landscape => 'Paysage';

  @override
  String get shortcutsHint =>
      'Appuyez longuement sur l\'icône de l\'app pour voir ces pages.';

  @override
  String get removeShortcut => 'Retirer le raccourci';

  @override
  String get addShortcut => 'Ajouter un raccourci';

  @override
  String get optimizeFiles => 'Optimiser les fichiers à la compilation';

  @override
  String get optimizeFilesHint =>
      'Réduit les fichiers CSS, JSON, PNG et les gros JPEG dans l\'app. Les JPEG sont réenregistrés à 85 % de qualité. Les fichiers de votre projet ne changent pas.';

  @override
  String get sizeReport => 'Rapport de taille';

  @override
  String get statusBarColour => 'Couleur de la barre d\'état';

  @override
  String get navBarColour => 'Couleur de la barre de navigation';

  @override
  String get splashScreen => 'Écran d\'accueil';

  @override
  String get splashIconHint =>
      'Affiche l\'icône de l\'app jusqu\'au chargement de la première page.';

  @override
  String get splashImageHint =>
      'Affiche votre image d\'accueil jusqu\'au chargement de la première page.';

  @override
  String get splashBackground => 'Fond de l\'écran d\'accueil';

  @override
  String get chooseSplash => 'Choisir l\'image d\'accueil';

  @override
  String get replaceSplash => 'Remplacer l\'image d\'accueil';

  @override
  String get useAppIcon => 'Utiliser l\'icône de l\'app';

  @override
  String get theme => 'Thème';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get followPhone => 'Comme le téléphone';

  @override
  String get themeHint =>
      'Définit prefers-color-scheme, pour que les pages avec un CSS sombre basculent.';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get fullscreenHint =>
      'Masque les barres d\'état et de navigation. Balayez depuis le bord pour les afficher un instant.';

  @override
  String get keepScreenOn => 'Garder l\'écran allumé';

  @override
  String get keepScreenOnHint =>
      'L\'écran ne s\'éteint pas tant que l\'app est ouverte.';

  @override
  String get tvHint =>
      'Affiche l\'app sur l\'écran d\'accueil de la TV avec une bannière faite de l\'icône et du nom. Les flèches de la télécommande passent d\'un lien ou bouton à l\'autre ; OK les ouvre.';

  @override
  String get rotateTablets => 'Rotation libre sur tablette';

  @override
  String get rotateTabletsHint =>
      'Les tablettes et pliables peuvent pivoter dans tous les sens, même si les téléphones gardent l\'orientation choisie ci-dessus. Android 16 et plus le permettent toujours sur grand écran.';

  @override
  String get desktopLayout => 'Mise en page ordinateur sur tablette et TV';

  @override
  String get desktopLayoutHint =>
      'Demande aux sites la mise en page qu\'ils affichent sur ordinateur au lieu de celle pour téléphone.';

  @override
  String get appLock => 'Verrouillage de l\'app';

  @override
  String get appLockHint =>
      'Demande l\'empreinte, le visage ou le verrouillage d\'écran à l\'ouverture de l\'app et après 30 secondes en arrière-plan. Les téléphones sans verrouillage d\'écran ouvrent l\'app avec un avertissement.';

  @override
  String get javascriptHint =>
      'La plupart des sites en ont besoin. Désactivez-le pour les pages statiques.';

  @override
  String get localStorage => 'Stockage local';

  @override
  String get internetAccess => 'Accès à internet';

  @override
  String get internetAccessHint =>
      'Ajoute l\'autorisation INTERNET, pour les CDN, API ou polices chargées depuis le web.';

  @override
  String get openOtherSites => 'Ouvrir les autres sites dans le navigateur';

  @override
  String get openOtherSitesHint =>
      'Désactivé, les liens vers d\'autres sites ne font rien.';

  @override
  String get pullToRefresh => 'Tirer pour actualiser';

  @override
  String get pullToRefreshHint =>
      'Balayez vers le bas en haut d\'une page pour la recharger, ou réessayer après une erreur.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsHint =>
      'La page peut utiliser l\'API web Notification pour afficher des notifications Android quand l\'app est ouverte. Android 13+ demande d\'abord à l\'utilisateur. Pas de notifications push.';

  @override
  String get backButton => 'Bouton Retour';

  @override
  String get backHistory => 'Revenir en arrière, puis fermer l\'app';

  @override
  String get backTwice =>
      'Revenir en arrière, puis appuyer deux fois pour fermer';

  @override
  String get backConfirm => 'Revenir en arrière, puis demander avant de fermer';

  @override
  String get backHome => 'Aller à la page de démarrage, puis fermer';

  @override
  String get fileUploads => 'Envoi de fichiers';

  @override
  String get fileUploadsHint =>
      'Permet aux champs de fichier d\'ouvrir le sélecteur d\'Android. L\'utilisateur choisit chaque fichier.';

  @override
  String get share => 'Partager';

  @override
  String get shareHint =>
      'navigator.share ouvre le menu de partage d\'Android pour le texte et les liens.';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get downloadsHint =>
      'Les liens de téléchargement et fichiers générés sont enregistrés dans le dossier Téléchargements.';

  @override
  String get shareFiles => 'Partager images et PDF';

  @override
  String get galleryFolder => 'Dossier de la galerie (facultatif)';

  @override
  String get galleryFolderExample => 'ex. Mes photos';

  @override
  String get galleryFolderHelp =>
      'Pictures/<dossier> pour les images partagées et téléchargées. Vide : le nom de l\'app pour les partages, Téléchargements pour les téléchargements.';

  @override
  String get shareToApp => 'Partager directement vers une app (facultatif)';

  @override
  String get shareToAppHelp =>
      'Paquet qui ouvre directement les fichiers partagés s\'il est installé, au lieu du menu de partage.';

  @override
  String get usePackageName => 'Utilisez un nom de paquet comme com.whatsapp';

  @override
  String get offlineBuiltIn =>
      'Quand le site ne se charge pas, un écran intégré « Page indisponible » s\'affiche.';

  @override
  String get chooseOfflinePage => 'Choisir une page hors ligne (.html)';

  @override
  String get replaceOfflinePage => 'Remplacer la page hors ligne';

  @override
  String get useBuiltInPage => 'Utiliser la page intégrée';

  @override
  String get userAgentSuffix => 'Suffixe du user agent (facultatif)';

  @override
  String get atMost200 => '200 caractères maximum';

  @override
  String get deleteProject => 'Supprimer le projet';

  @override
  String get useColourLike => 'Utilisez une couleur comme #1A73E8';

  @override
  String get noNetwork =>
      'Cet ordinateur n\'est pas sur un réseau Wi-Fi ou Ethernet.';

  @override
  String get installOnPhone => 'Installer sur le téléphone';

  @override
  String get installSteps =>
      '1. Connectez le téléphone au même Wi-Fi que cet ordinateur.\n2. Scannez le code avec l\'appareil photo du téléphone et ouvrez le lien.\n3. Ouvrez le fichier téléchargé. Autorisez les installations depuis le navigateur si Android le demande.';

  @override
  String get linkStopped => 'Le lien s\'est arrêté.';

  @override
  String get networkAddress => 'Adresse réseau';

  @override
  String get linkWorks10Min =>
      'Le lien fonctionne 10 minutes tant que cette fenêtre est ouverte.';

  @override
  String get trustedNetworkOnly =>
      'N\'utilisez ceci que sur un réseau de confiance. Windows peut demander d\'autoriser iLoveHTML dans le pare-feu : autorisez-le pour les réseaux privés.';

  @override
  String get startAgain => 'Recommencer';

  @override
  String get done => 'Terminé';

  @override
  String get kindPages => 'Pages';

  @override
  String get kindImages => 'Images';

  @override
  String get kindFonts => 'Polices';

  @override
  String get kindMedia => 'Audio et vidéo';

  @override
  String get kindData => 'Données';

  @override
  String get kindOther => 'Autres';

  @override
  String get largestFiles => 'Plus gros fichiers';

  @override
  String get advice => 'Conseils';

  @override
  String get checkOptimizing => 'Voir ce que l\'optimisation économise';

  @override
  String get name => 'Nom';

  @override
  String get exampleCart => 'ex. Panier';

  @override
  String get choosePage => 'Choisissez une page';

  @override
  String get page => 'Page';

  @override
  String get add => 'Ajouter';

  @override
  String get differentKey => 'Clé de publication différente';

  @override
  String get buildAnyway => 'Compiler quand même';

  @override
  String get windowsExe => 'App Windows (.exe)';

  @override
  String get exeDescription =>
      'Un seul fichier .exe qui ouvre ce site dans sa propre fenêtre avec Microsoft Edge WebView2 (intégré à Windows 11 et à Windows 10 à jour). Il n\'est pas signé, donc Windows peut afficher « Windows a protégé votre ordinateur » jusqu\'à ce qu\'on choisisse Informations complémentaires → Exécuter quand même.';

  @override
  String get devTools => 'Outils de développement (pour les tests)';

  @override
  String get devToolsHint =>
      'F12 et Inspecter fonctionnent dans l\'app ; laissez désactivé pour la version que vous partagez';

  @override
  String get buildExe => 'Compiler le .exe';

  @override
  String get windowsMsix => 'Installateur Windows (.msix)';

  @override
  String get msixDescription =>
      'Installe l\'app comme les autres logiciels Windows : entrée dans le menu Démarrer, désinstallation propre et mises à jour quand vous partagez une version supérieure. Chaque installateur est signé avec un certificat.';

  @override
  String get needsWindowsSdk =>
      'Nécessite le Windows SDK. Installez-le avec :\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      'Pas encore de certificat. Utilisez votre propre certificat de signature de code, ou créez un certificat de test pour essayer.';

  @override
  String get testCertNote =>
      'Certificat de test : Windows n\'installe l\'app qu\'après qu\'on lui a fait confiance une fois. Partagez le fichier .cer avec l\'installateur ; on le double-clique → Installer le certificat → Ordinateur local → « Personnes autorisées ». Un certificat acheté auprès d\'une autorité de certification n\'a pas besoin de cette étape.';

  @override
  String get createTestCert => 'Créer un certificat de test';

  @override
  String get useMyPfx => 'Utiliser mon .pfx';

  @override
  String get savedCertificate => 'Certificat enregistré';

  @override
  String get saveCer => 'Enregistrer le .cer';

  @override
  String get buildInstaller => 'Compiler l\'installateur';

  @override
  String get replaceCertQ => 'Remplacer le certificat ?';

  @override
  String get replace => 'Remplacer';

  @override
  String get publisherName => 'Nom de l\'éditeur';

  @override
  String get publisherNameHelp =>
      'Affiché comme éditeur lors de l\'installation de vos apps.';

  @override
  String get testCertCreated => 'Certificat de test créé';

  @override
  String get useMyCertificate => 'Utiliser mon certificat';

  @override
  String get certificateAdded => 'Certificat ajouté';

  @override
  String get ok => 'OK';

  @override
  String get allowUnknownApps =>
      'Autorisez « Installer des applis inconnues » pour iLoveHTML dans l\'écran qui s\'est ouvert, puis touchez Installer à nouveau.';

  @override
  String get debug => 'Débogage';

  @override
  String get release => 'Publication';

  @override
  String get debugHint =>
      'Pour les tests. Signé avec une clé de débogage qui reste sur cet appareil ; pas pour la publication.';

  @override
  String get releaseHint =>
      'Pour la publication. Signé avec votre clé de publication ; chaque mise à jour devra utiliser la même clé et un code de version supérieur.';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      'Envoyez le .aab sur Google Play Console. Il ne peut pas être installé directement ; utilisez un APK pour tester sur un téléphone.';

  @override
  String get createOrImportKey => 'Créer ou importer une clé de publication';

  @override
  String get releaseKey => 'Clé de publication';

  @override
  String get manageKeys => 'Gérer les clés';

  @override
  String get buildDebugApk => 'Compiler l\'APK de débogage';

  @override
  String get buildAppBundle => 'Compiler l\'App Bundle';

  @override
  String get buildReleaseApk => 'Compiler l\'APK de publication';

  @override
  String get buildingUnavailable =>
      'La compilation n\'est pas encore disponible sur cette plateforme.';

  @override
  String get buildFailed => 'Échec de la compilation';

  @override
  String get saveAs => 'Enregistrer sous…';

  @override
  String get showInFolder => 'Afficher dans le dossier';

  @override
  String get install => 'Installer';

  @override
  String get saveToDevice => 'Enregistrer sur l\'appareil';

  @override
  String get buildLog => 'Journal de compilation';

  @override
  String get history => 'Historique';

  @override
  String get twoLetters => 'Deux lettres';

  @override
  String invalidHost(String host) {
    return 'Hôte invalide « $host »';
  }

  @override
  String get thisDevice => 'Cet appareil';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compilation… $count lignes de journal',
      one: 'Compilation… 1 ligne de journal',
      zero: 'Compilation…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'Système';

  @override
  String get accentColour => 'Couleur d\'accent';

  @override
  String get accentOrange => 'Orange';

  @override
  String get accentGreen => 'Vert terminal';

  @override
  String get accentCyan => 'Cyan';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentPink => 'Rose';

  @override
  String get animations => 'Animations';

  @override
  String get animationsHint =>
      'Écran d\'accueil ASCII, animation de compilation et transitions de page';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get signing => 'Signature';

  @override
  String get releaseKeysSubtitle =>
      'Créez, importez et sauvegardez les clés qui signent vos versions';

  @override
  String get storage => 'Stockage';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projets · $size',
      one: '1 projet · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'Moteur de compilation';

  @override
  String get notAvailablePlatform =>
      'Pas encore disponible sur cette plateforme';

  @override
  String get gradleReady => 'Gradle sur ce PC (prêt)';

  @override
  String get gradleNotReady => 'Gradle sur ce PC : pas prêt';

  @override
  String get buildsRunOnPc =>
      'Tout est compilé sur ce PC. Aucun fichier n\'est envoyé.';

  @override
  String get onDeviceReady => 'Assemblage sur l\'appareil (prêt)';

  @override
  String get onDeviceMissing =>
      'Assemblage sur l\'appareil : APK de base manquant';

  @override
  String get buildsRunOnDevice =>
      'Tout est compilé sur cet appareil. Aucun fichier n\'est envoyé.';

  @override
  String get about => 'À propos';

  @override
  String get howToUse => 'Mode d\'emploi';

  @override
  String get howToUseSubtitle =>
      'Du site web à l\'app installée en cinq étapes';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get version => 'Version';

  @override
  String get versionCopied => 'Version copiée';

  @override
  String get credit => 'Crédits';

  @override
  String madeBy(String author) {
    return 'Fait avec <3 par $author';
  }

  @override
  String get supportHint =>
      'iLoveHTML est gratuit, sans publicité ni pistage. S\'il vous fait gagner du temps, vous pouvez soutenir son développement.';

  @override
  String get buyMeACoffee => 'Offrez-moi un café';

  @override
  String couldNotOpenLink(String url) {
    return 'Impossible d\'ouvrir $url';
  }

  @override
  String lastUpdated(String date) {
    return 'Dernière mise à jour : $date';
  }

  @override
  String get howToStep1Title => 'Créez un projet';

  @override
  String get howToStep1Body =>
      'Touchez Nouvelle app et choisissez des fichiers HTML, un ZIP de site ou l\'URL d\'un site https en ligne. Les fichiers et ZIP fonctionnent hors ligne ; une URL nécessite internet.';

  @override
  String get howToStep2Title => 'Nommez votre app';

  @override
  String get howToStep2Body =>
      'Saisissez le nom de l\'app et un ID de paquet unique comme com.votrenom.app. Gardez le même ID de paquet pour chaque mise à jour.';

  @override
  String get howToStep3Title => 'Personnalisez-la';

  @override
  String get howToStep3Body =>
      'Dans l\'onglet Réglages, choisissez la page de démarrage, l\'icône, l\'écran d\'accueil, les couleurs, l\'orientation, les raccourcis et les fonctions WebView. Touchez Enregistrer à la fin. Utilisez Aperçu pour essayer l\'app d\'abord.';

  @override
  String get howToStep4Title => 'Compilez';

  @override
  String get howToStep4Body =>
      'Dans l\'onglet Compiler, choisissez Débogage pour tester ou Publication pour publier. Les versions de publication nécessitent une clé : créez-la et sauvegardez-la. Sous Windows, vous pouvez aussi compiler un .exe ou un installateur .msix.';

  @override
  String get howToStep5Title => 'Installez ou partagez';

  @override
  String get howToStep5Body =>
      'Installez l\'APK sur ce téléphone, partagez-le ou enregistrez-le. Sur PC, utilisez Installer sur le téléphone pour l\'envoyer par Wi-Fi. Envoyez les App Bundles (.aab) sur Google Play Console.';

  @override
  String get howToTipsTitle => 'Astuces';

  @override
  String get howToTips =>
      '• Chaque mise à jour doit utiliser le même ID de paquet et la même clé de publication, avec un code de version supérieur.\n• Sauvegardez vos clés et vos projets ; personne ne peut récupérer une clé perdue.\n• Utilisez le Rapport de taille pour alléger l\'app.\n• Utilisez Sauvegarder le projet (en haut d\'un projet) pour garder une copie restaurable plus tard.';

  @override
  String get termsBody =>
      'Ces Conditions d\'utilisation s\'appliquent à l\'app iLoveHTML (« l\'app »), créée par 1elevenop. En utilisant l\'app, vous les acceptez.\n\n## Ce que fait l\'app\n\niLoveHTML transforme des fichiers HTML, des ZIP de sites et des adresses web en apps Android et Windows. Les compilations s\'exécutent sur votre propre appareil.\n\n## Votre contenu\n\nVous conservez tous les droits sur les sites, fichiers, icônes et apps que vous créez. Vous êtes responsable d\'avoir le droit d\'utiliser ce contenu, ainsi que des apps que vous compilez et publiez, y compris du respect de la loi et des règles des boutiques comme Google Play.\n\n## Utilisation acceptable\n\nN\'utilisez pas l\'app pour créer des logiciels illégaux, nuisibles ou trompeurs, ou qui portent atteinte aux droits d\'autrui, comme des logiciels malveillants ou des apps qui imitent d\'autres marques.\n\n## Clés de publication\n\nLes clés de publication sont stockées uniquement sur votre appareil. Vous êtes responsable de leur sauvegarde et de la sécurité de leurs mots de passe. Une clé perdue ne peut pas être récupérée, et les apps signées avec elle ne pourront plus être mises à jour.\n\n## Absence de garantie\n\nL\'app est fournie gratuitement et « en l\'état », sans garantie d\'aucune sorte. Dans la mesure permise par la loi, l\'auteur n\'est pas responsable des pertes de données, de clés, de revenus ou d\'autres dommages liés à son utilisation.\n\n## Modifications\n\nCes conditions peuvent évoluer avec les nouvelles versions de l\'app. La date ci-dessus indique la dernière modification. Continuer à utiliser l\'app vaut acceptation des conditions mises à jour.\n\n## Contact\n\nQuestions : ouvrez un ticket sur le projet GitHub iLoveHTML de 1elevenop.';

  @override
  String get privacyBody =>
      'iLoveHTML est conçu pour fonctionner sur votre appareil. Cette politique explique ce que cela implique pour vos données.\n\n## Données collectées\n\nAucune. L\'app n\'a ni comptes, ni statistiques, ni publicité, ni pistage. L\'auteur ne reçoit aucune donnée sur vous ou vos projets.\n\n## Données stockées sur votre appareil\n\nVos projets, fichiers web, icônes, compilations et réglages sont stockés dans l\'espace privé de l\'app sur votre appareil. Les clés de publication restent aussi sur votre appareil : sous Android elles sont chiffrées avec Android Keystore, et sous Windows leurs mots de passe sont chiffrés pour votre compte Windows. Désinstaller l\'app supprime ces données : faites des sauvegardes.\n\n## Utilisation du réseau\n\nL\'app se connecte à internet uniquement quand vous le demandez : pour vérifier ou prévisualiser une URL que vous avez saisie, pour ouvrir des liens comme Buy Me a Coffee dans votre navigateur et, sous Windows, quand Gradle télécharge des outils de compilation. La fonction Installer sur le téléphone sert le fichier sur votre réseau local pendant 10 minutes, seulement tant que sa fenêtre est ouverte.\n\n## Apps que vous créez\n\nLes apps créées avec iLoveHTML ne contiennent aucun pistage d\'iLoveHTML. Ce qu\'elles collectent dépend du site que vous y mettez, et vous êtes responsable de leur politique de confidentialité.\n\n## Enfants\n\nL\'app ne collecte sciemment aucune donnée, ni d\'enfants ni de quiconque.\n\n## Modifications et contact\n\nCette politique peut évoluer avec les nouvelles versions de l\'app ; la date ci-dessus indique la dernière modification. Questions : ouvrez un ticket sur le projet GitHub iLoveHTML de 1elevenop.';

  @override
  String get replaceWebsite => 'Remplacer les fichiers du site';

  @override
  String get replaceWebsiteHint =>
      'Remplacez par un nouveau ZIP ou de nouveaux fichiers HTML. Le nom, l\'ID du paquet, l\'icône, les réglages et les clés restent les mêmes.';

  @override
  String get replaceWithZipHint => 'Un nouveau dossier de site, compressé';

  @override
  String get replaceWithFilesHint =>
      'Nouvelles pages .html avec leur CSS, JavaScript et images';

  @override
  String get replaceWebsiteQ => 'Remplacer le site ?';

  @override
  String replaceWebsiteBody(String name) {
    return 'Tous les fichiers du site de « $name » sont remplacés par ceux que vous choisirez ensuite. Le nom, l\'ID du paquet, la version, l\'icône, les réglages, la clé de publication et l\'historique sont conservés. Recompilez pour obtenir l\'app à jour.';
  }

  @override
  String replaceFailed(String error) {
    return 'Impossible de remplacer le site : $error';
  }

  @override
  String get websiteReplaced => 'Site remplacé';

  @override
  String startPageChanged(String page) {
    return '« $page » n\'est pas dans les nouveaux fichiers : la page de démarrage a changé.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'Raccourcis retirés car leurs pages n\'existent plus : $pages';
  }

  @override
  String get rebuildAfterReplace =>
      'Recompilez pour obtenir l\'app à jour. Pour mettre à jour une app installée, augmentez d\'abord le code de version.';

  @override
  String get unlockReason => 'Déverrouiller iLoveHTML';

  @override
  String get resetReason =>
      'Confirmez votre identité pour réinitialiser le verrou d\'iLoveHTML';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Incorrect. Encore $count essais avant une attente.',
      one: 'Incorrect. Encore 1 essai avant une attente.',
      zero: 'Incorrect. Attendez avant de réessayer.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return 'Trop d\'essais incorrects. Réessayez dans $seconds s.';
  }

  @override
  String get enterPin => 'Saisissez votre code PIN';

  @override
  String get enterPassword => 'Saisissez votre mot de passe';

  @override
  String get showPassword => 'Afficher';

  @override
  String get hidePassword => 'Masquer';

  @override
  String hintIs(String hint) {
    return 'Indice : $hint';
  }

  @override
  String get showHint => 'Afficher l\'indice';

  @override
  String get deleteDigit => 'Effacer';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get useFingerprint => 'Utiliser l\'empreinte ou le visage';

  @override
  String get forgotPin => 'Code PIN oublié ?';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String digitsEntered(int count) {
    return '$count chiffres saisis';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Code incorrect. Encore $count essais.',
      one: 'Code incorrect. Encore 1 essai.',
      zero: 'Code incorrect. Attendez avant de réessayer.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'Utiliser le verrouillage de l\'appareil';

  @override
  String get forgotWithDeviceHint =>
      'Confirmez avec votre empreinte, votre visage ou le verrouillage d\'écran du téléphone (PIN, schéma ou mot de passe), puis choisissez-en un nouveau pour iLoveHTML.';

  @override
  String get verifyWithDevice => 'Vérifier avec le verrouillage';

  @override
  String get forgotWithCode => 'Utiliser votre code de récupération';

  @override
  String get forgotWithCodeHint =>
      'Le code de 16 caractères affiché lors de la configuration du verrou.';

  @override
  String get recoveryCode => 'Code de récupération';

  @override
  String get useRecoveryCode => 'Utiliser le code';

  @override
  String get forgotNoWay =>
      'Sans l\'un ou l\'autre, le verrou ne peut être retiré qu\'en effaçant les données d\'iLoveHTML dans les réglages du système. Cela supprime tous les projets et clés de publication de cet appareil.';

  @override
  String get pinDigitsOnly => 'Chiffres uniquement';

  @override
  String pinLength(int min, int max) {
    return 'De $min à $max chiffres';
  }

  @override
  String passwordMinLength(int count) {
    return 'Au moins $count caractères';
  }

  @override
  String get chooseNewSecret => 'Choisissez un nouveau PIN ou mot de passe';

  @override
  String get setUpAppLock => 'Configurer le verrou';

  @override
  String get pin => 'Code PIN';

  @override
  String get newPin => 'Nouveau code PIN';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get repeatPin => 'Répétez le code PIN';

  @override
  String get pinsDoNotMatch => 'Les codes PIN ne correspondent pas';

  @override
  String get hintOptional => 'Indice (facultatif)';

  @override
  String get hintHelp =>
      'Affiché sur l\'écran de verrouillage pour vous aider. Toute personne tenant l\'appareil peut le lire.';

  @override
  String get hintGivesAway =>
      'L\'indice ne doit pas contenir le PIN ou le mot de passe';

  @override
  String get unlockWithFingerprint => 'Déverrouiller par empreinte ou visage';

  @override
  String get unlockWithFingerprintHint =>
      'Votre PIN ou mot de passe fonctionne toujours.';

  @override
  String get appLockNote =>
      'Le verrou cache iLoveHTML et ses projets aux personnes qui prennent cet appareil. Il ne chiffre pas les fichiers des projets.';

  @override
  String get saveAndContinue => 'Enregistrer';

  @override
  String get recoveryCodeTitle => 'Enregistrez votre code de récupération';

  @override
  String get recoveryCodeBody =>
      'Si vous oubliez votre PIN ou mot de passe, ce code permet d\'en définir un nouveau. Il n\'est affiché que maintenant. Notez-le ou gardez-le en lieu sûr, pas seulement sur cet appareil.';

  @override
  String get copy => 'Copier';

  @override
  String get iSavedTheCode => 'J\'ai enregistré le code';

  @override
  String get enterCurrentPin => 'Saisissez le PIN actuel';

  @override
  String get enterCurrentPassword => 'Saisissez le mot de passe actuel';

  @override
  String get wrongPin => 'PIN incorrect';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get appLockOffHint =>
      'Désactivé. Demande un PIN, un mot de passe ou une empreinte avant d\'ouvrir iLoveHTML.';

  @override
  String get appLockOnPin => 'Activé, avec un code PIN';

  @override
  String get appLockOnPassword => 'Activé, avec un mot de passe';

  @override
  String get lockAgainAfter => 'Reverrouiller après avoir quitté l\'app';

  @override
  String get relockImmediately => 'Immédiatement';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Après $count minutes',
      one: 'Après 1 minute',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'Seulement au démarrage d\'iLoveHTML';

  @override
  String get changePinOrHint => 'Changer le PIN, le mot de passe ou l\'indice';

  @override
  String get lockNow => 'Verrouiller maintenant';

  @override
  String get turnOffLock => 'Désactiver le verrou';
}

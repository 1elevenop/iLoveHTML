// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String unreadableProject(String name) {
    return 'Proyecto ilegible: $name';
  }

  @override
  String get emptyHintWindows =>
      'Convierte archivos HTML, un ZIP de sitio web o un sitio https en vivo en una app de Android o Windows. Todo se compila en este dispositivo.';

  @override
  String get emptyHintAndroid =>
      'Convierte archivos HTML, un ZIP de sitio web o un sitio https en vivo en una app de Android. Todo se compila en este dispositivo.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · aún sin compilar';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · última compilación $status $ago';
  }

  @override
  String get justNow => 'ahora mismo';

  @override
  String minutesAgo(int n) {
    return 'hace $n min';
  }

  @override
  String hoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String daysAgo(int n) {
    return 'hace $n d';
  }

  @override
  String chooseBackupFile(String ext) {
    return 'Elige un archivo de copia $ext';
  }

  @override
  String restored(String name) {
    return 'Restaurado: $name';
  }

  @override
  String notUsableBackup(String message) {
    return 'Copia no válida: $message';
  }

  @override
  String restoreFailed(String error) {
    return 'Error al restaurar: $error';
  }

  @override
  String importFailed(String error) {
    return 'Error al importar: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos importados',
      one: '1 archivo importado',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return 'Página de inicio: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return 'Se encontraron $count páginas HTML; puedes cambiar la página de inicio en Ajustes.';
  }

  @override
  String filesMissing(int count) {
    return 'Faltan $count archivos referenciados:';
  }

  @override
  String andMore(int count) {
    return '…y $count más';
  }

  @override
  String fileNotFound(String path) {
    return 'Archivo no encontrado: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'Se abriría fuera de la app: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'La página no se pudo cargar: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'No se pudo iniciar la vista previa: $error';
  }

  @override
  String previewTitle(String name) {
    return 'Vista previa · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'El sitio respondió con HTTP $code';
  }

  @override
  String redirected(int count) {
    return 'Redirigido $count× — la app empezará en esta dirección.';
  }

  @override
  String importedKey(String alias) {
    return 'Importada \"$alias\"';
  }

  @override
  String backupSavedAs(String alias) {
    return 'Copia guardada como $alias.jks. Guarda la contraseña por separado.';
  }

  @override
  String backupFailed(String error) {
    return 'Error en la copia: $error';
  }

  @override
  String deletedKey(String alias) {
    return '\"$alias\" eliminada de este dispositivo';
  }

  @override
  String get releaseKeysIntroWindows =>
      'Las compilaciones de publicación se firman con una de estas claves. Google Play y Android solo aceptan actualizaciones firmadas con la misma clave que la primera versión. Las claves se quedan en este PC, con contraseñas cifradas para tu cuenta de Windows; una copia es un archivo .jks protegido con contraseña que funciona con iLoveHTML en un teléfono o un ordenador, Gradle y keytool.';

  @override
  String get releaseKeysIntroAndroid =>
      'Las compilaciones de publicación se firman con una de estas claves. Google Play y Android solo aceptan actualizaciones firmadas con la misma clave que la primera versión. Las claves se quedan en este teléfono, cifradas con Android Keystore; una copia es un archivo .jks protegido con contraseña que funciona con iLoveHTML en un teléfono o un ordenador, Gradle y keytool.';

  @override
  String validUntilDate(String date) {
    return 'válida hasta $date';
  }

  @override
  String get atLeast8 => 'Al menos 8 caracteres';

  @override
  String deleteKeyBody(String alias) {
    return 'Las apps firmadas con \"$alias\" solo se pueden actualizar con esta misma clave. Sin una copia, nunca podrás volver a actualizarlas.';
  }

  @override
  String typeToConfirm(String alias) {
    return 'Escribe \"$alias\" para confirmar';
  }

  @override
  String backupSaved(String file) {
    return 'Copia guardada: $file';
  }

  @override
  String shortcutExists(String page) {
    return 'Ya existe un acceso directo para \"$page\"';
  }

  @override
  String deleteProjectBody(String name) {
    return 'Esto elimina \"$name\", sus archivos web y los APK compilados de este dispositivo. Las apps ya instaladas no se ven afectadas.';
  }

  @override
  String offlinePageShown(String page) {
    return 'Cuando el sitio no carga, se muestra tu página \"$page\". Enlaza a https://appassets.androidplatform.net/html2apk/retry para un botón \"Reintentar\".';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Descargado $count veces.',
      one: 'Descargado 1 vez.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'No se pudieron leer los archivos: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count archivos, $size';
  }

  @override
  String checkFailed(String error) {
    return 'Error en la comprobación: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return 'La optimización reduce $count archivos y ahorra $saved ($before → $after). El APK también está comprimido, así que el ahorro en el APK suele ser menor para CSS y JSON.';
  }

  @override
  String example(String value) {
    return 'p. ej. $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'No se pudieron cargar las claves de publicación: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'Esta app se publicó por primera vez con otra clave (SHA-256 $sha…). Los teléfonos que instalaron esa versión no pueden actualizar a un APK firmado con \"$alias\", y Google Play lo rechazará como actualización.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return 'Editor: $publisher · válido hasta $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return 'Las apps instaladas con instaladores firmados por \"$publisher\" solo se actualizan desde instaladores con el mismo nombre de editor. Haz antes una copia del certificado actual si podrías necesitarlo.';
  }

  @override
  String passwordOf(String file) {
    return 'Contraseña de $file';
  }

  @override
  String savedFile(String file) {
    return 'Guardado $file';
  }

  @override
  String saveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get cannotBuildYet => 'Aún no se puede compilar:';

  @override
  String get shareFilesHint =>
      'navigator.share() con archivos envía imágenes y PDF a otras apps. En Android 10+ las imágenes compartidas también se guardan en la galería.';

  @override
  String get projects => 'Proyectos';

  @override
  String get restoreBackup => 'Restaurar copia';

  @override
  String get settings => 'Ajustes';

  @override
  String get newApp => 'Nueva app';

  @override
  String get htmlFiles => 'Archivos HTML';

  @override
  String get htmlFilesHint =>
      'Elige una página .html, junto con su CSS, JavaScript e imágenes si son archivos aparte. Funciona sin conexión.';

  @override
  String get websiteZip => 'ZIP de sitio web';

  @override
  String get websiteZipHint =>
      'Una carpeta de sitio web completa, comprimida. Funciona sin conexión.';

  @override
  String get websiteUrl => 'URL del sitio web';

  @override
  String get websiteUrlHint =>
      'Envuelve un sitio https en vivo. Necesita conexión a internet.';

  @override
  String get noProjectsYet => 'Aún no hay proyectos';

  @override
  String get building => 'Compilando…';

  @override
  String get selectHtmlFile =>
      'Selecciona al menos un archivo .html, junto con el CSS, JavaScript o imágenes que use.';

  @override
  String get defaultAppName => 'Mi App';

  @override
  String get appName => 'Nombre de la app';

  @override
  String get enterName => 'Escribe un nombre';

  @override
  String get packageId => 'ID del paquete';

  @override
  String get packageIdHelp =>
      'ID único en el dispositivo y en Play, p. ej. com.tunombre.app';

  @override
  String get cancel => 'Cancelar';

  @override
  String get importButton => 'Importar';

  @override
  String get noMissingFiles => 'No faltan archivos';

  @override
  String get openProject => 'Abrir proyecto';

  @override
  String get noConsoleMessages => 'No hay mensajes ni problemas en la consola';

  @override
  String get viewport => 'Ventana';

  @override
  String get consoleAndIssues => 'Consola y problemas';

  @override
  String get checkWebsite => 'Comprobar sitio';

  @override
  String get websiteReachable => 'Sitio accesible';

  @override
  String get liveSiteNote =>
      'La app muestra este sitio en vivo y necesita conexión a internet. No funciona sin conexión.';

  @override
  String get create => 'Crear';

  @override
  String get backUpKeyNow => 'Haz una copia de esta clave ahora';

  @override
  String get backUpKeyBody =>
      'Cada actualización de una app debe firmarse con la misma clave. Si pierdes este dispositivo o desinstalas iLoveHTML, la clave desaparece salvo que tengas una copia.\n\nGuarda el archivo .jks en un lugar seguro (no solo en este dispositivo) y guarda la contraseña por separado.';

  @override
  String get later => 'Más tarde';

  @override
  String get saveBackup => 'Guardar copia';

  @override
  String get certificate => 'Certificado';

  @override
  String get sha256Fingerprint => 'Huella SHA-256';

  @override
  String get sha1Fingerprint => 'Huella SHA-1';

  @override
  String get validUntil => 'Válida hasta';

  @override
  String get added => 'Añadida';

  @override
  String get saveBackupJks => 'Guardar copia (.jks)';

  @override
  String get delete => 'Eliminar';

  @override
  String get releaseKeys => 'Claves de publicación';

  @override
  String get createKey => 'Crear clave';

  @override
  String get importKeystoreFile => 'Importar .jks / .keystore / .p12';

  @override
  String get noReleaseKeys => 'Aún no hay claves de publicación';

  @override
  String get createReleaseKey => 'Crear clave de publicación';

  @override
  String get keyAlias => 'Alias de la clave';

  @override
  String get keyAliasHelp => 'Letras, dígitos, puntos, guiones y guiones bajos';

  @override
  String get publisherNameField => 'Tu nombre o el editor de la app';

  @override
  String get required => 'Obligatorio';

  @override
  String get organizationOptional => 'Organización (opcional)';

  @override
  String get countryCodeOptional => 'Código de país (opcional)';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordHelp => 'Se usa para el almacén y la clave';

  @override
  String get repeatPassword => 'Repite la contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get createKeyNote =>
      'RSA de 2048 bits, válida 30 años. Necesitarás esta contraseña para usar la copia en un ordenador.';

  @override
  String get noPrivateKeys => 'Este archivo no contiene claves privadas';

  @override
  String get importKeystore => 'Importar almacén de claves';

  @override
  String get keystorePassword => 'Contraseña del almacén';

  @override
  String get keyPassword => 'Contraseña de la clave';

  @override
  String get keyPasswordHelp => 'Déjala vacía si es igual a la del almacén';

  @override
  String get importKeystoreNote =>
      'iLoveHTML guarda una copia protegida con la contraseña del almacén. Tu archivo original no cambia.';

  @override
  String get open => 'Abrir';

  @override
  String get deleteReleaseKey => '¿Eliminar la clave de publicación?';

  @override
  String get deleteKey => 'Eliminar clave';

  @override
  String get projectNotFound => 'Proyecto no encontrado';

  @override
  String get backUpProject => 'Copia del proyecto';

  @override
  String get preview => 'Vista previa';

  @override
  String get build => 'Compilar';

  @override
  String get previewInBrowser => 'Vista previa en tu navegador';

  @override
  String get liveSiteOpened =>
      'El sitio en vivo se abrió en tu navegador predeterminado.';

  @override
  String get servedFromPc =>
      'Se sirve solo desde este PC mientras esta ventana esté abierta. La app del teléfono añade una consola y comprobación de enlaces; aquí usa las herramientas de desarrollo del navegador (F12).';

  @override
  String get missingFiles => 'Archivos que faltan:';

  @override
  String get close => 'Cerrar';

  @override
  String get stopPreview => 'Detener vista previa';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get iconUpdated => 'Icono actualizado';

  @override
  String get splashUpdated => 'Imagen de inicio actualizada';

  @override
  String get offlinePageAdded => 'Página sin conexión añadida';

  @override
  String get deleteProjectQ => '¿Eliminar el proyecto?';

  @override
  String get save => 'Guardar';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionContent => 'Contenido';

  @override
  String get sectionShortcuts => 'Accesos directos';

  @override
  String get sectionAppSize => 'Tamaño de la app';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get sectionDevices => 'Dispositivos';

  @override
  String get sectionSecurity => 'Seguridad';

  @override
  String get sectionOffline => 'Sin conexión';

  @override
  String get sectionDanger => 'Zona de peligro';

  @override
  String get versionName => 'Nombre de versión';

  @override
  String get versionCode => 'Código de versión';

  @override
  String get defaultIcon => 'Icono predeterminado';

  @override
  String get customIcon => 'Icono personalizado';

  @override
  String get chooseImage => 'Elegir imagen';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP o SVG, de al menos 48 px; se recomienda 512 × 512. Las imágenes no cuadradas se centran.';

  @override
  String get startPage => 'Página de inicio';

  @override
  String get loadedLive =>
      'Se carga en vivo; la app necesita conexión a internet.';

  @override
  String get otherSites =>
      'Otros sitios que se abren dentro de la app (opcional)';

  @override
  String get otherSitesHelp =>
      'Separados por comas. Los enlaces a cualquier otro sitio se abren en el navegador.';

  @override
  String get bridgeSites =>
      'Sitios que también pueden compartir, guardar archivos y notificar (opcional)';

  @override
  String get bridgeSitesHelp =>
      'Separados por comas, de la lista de arriba. Tu propio sitio siempre puede. No incluyas sitios de inicio de sesión ni de pago.';

  @override
  String bridgeSiteNotListed(String host) {
    return '\"$host\" no está en la lista de arriba';
  }

  @override
  String get orientation => 'Orientación';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get portrait => 'Vertical';

  @override
  String get landscape => 'Horizontal';

  @override
  String get shortcutsHint =>
      'Mantén pulsado el icono de la app para ver estas páginas.';

  @override
  String get removeShortcut => 'Quitar acceso directo';

  @override
  String get addShortcut => 'Añadir acceso directo';

  @override
  String get optimizeFiles => 'Optimizar archivos al compilar';

  @override
  String get optimizeFilesHint =>
      'Reduce los archivos CSS, JSON, PNG y JPEG grandes dentro de la app. Los JPEG se vuelven a guardar al 85 % de calidad. Los archivos de tu proyecto no cambian.';

  @override
  String get sizeReport => 'Informe de tamaño';

  @override
  String get statusBarColour => 'Color de la barra de estado';

  @override
  String get navBarColour => 'Color de la barra de navegación';

  @override
  String get splashScreen => 'Pantalla de inicio';

  @override
  String get splashIconHint =>
      'Muestra el icono de la app hasta que carga la primera página.';

  @override
  String get splashImageHint =>
      'Muestra tu imagen de inicio hasta que carga la primera página.';

  @override
  String get splashBackground => 'Fondo de inicio';

  @override
  String get chooseSplash => 'Elegir imagen de inicio';

  @override
  String get replaceSplash => 'Cambiar imagen de inicio';

  @override
  String get useAppIcon => 'Usar icono de la app';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get followPhone => 'Según el teléfono';

  @override
  String get themeHint =>
      'Establece prefers-color-scheme, así las páginas con CSS de modo oscuro cambian a él.';

  @override
  String get fullscreen => 'Pantalla completa';

  @override
  String get fullscreenHint =>
      'Oculta las barras de estado y navegación. Desliza desde el borde para verlas un momento.';

  @override
  String get keepScreenOn => 'Mantener pantalla encendida';

  @override
  String get keepScreenOnHint =>
      'La pantalla no se apaga mientras la app está abierta.';

  @override
  String get tvHint =>
      'Muestra la app en la pantalla de inicio de la TV con un banner hecho con el icono y el nombre. Las flechas del mando se mueven entre enlaces y botones; OK los abre.';

  @override
  String get rotateTablets => 'Girar libremente en tabletas';

  @override
  String get rotateTabletsHint =>
      'Tabletas y plegables pueden girar a cualquier lado, aunque los teléfonos mantengan la orientación elegida arriba. Android 16 y posteriores siempre lo permiten en pantallas grandes.';

  @override
  String get desktopLayout => 'Diseño de escritorio en tabletas y TV';

  @override
  String get desktopLayoutHint =>
      'Pide a los sitios el diseño que muestran en ordenadores en lugar del de teléfono.';

  @override
  String get appLock => 'Bloqueo de la app';

  @override
  String get appLockHint =>
      'Pide la huella, la cara o el bloqueo de pantalla al abrir la app y tras 30 segundos en segundo plano. Los teléfonos sin bloqueo de pantalla abren la app con un aviso.';

  @override
  String get javascriptHint =>
      'La mayoría de los sitios lo necesitan. Desactívalo para páginas estáticas.';

  @override
  String get localStorage => 'Almacenamiento local';

  @override
  String get internetAccess => 'Acceso a internet';

  @override
  String get internetAccessHint =>
      'Añade el permiso INTERNET, para CDN, API o fuentes cargadas desde la web.';

  @override
  String get openOtherSites => 'Abrir otros sitios en el navegador';

  @override
  String get openOtherSitesHint =>
      'Si está desactivado, los enlaces a otros sitios no hacen nada.';

  @override
  String get pullToRefresh => 'Deslizar para actualizar';

  @override
  String get pullToRefreshHint =>
      'Desliza hacia abajo en la parte superior de una página para recargarla o reintentar tras un error.';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsHint =>
      'La página puede usar la API web Notification para mostrar notificaciones de Android mientras la app está abierta. Android 13+ pregunta antes al usuario. Sin mensajes push.';

  @override
  String get backButton => 'Botón Atrás';

  @override
  String get backHistory => 'Volver atrás y luego cerrar la app';

  @override
  String get backTwice => 'Volver atrás y luego pulsar dos veces para cerrar';

  @override
  String get backConfirm => 'Volver atrás y luego preguntar antes de cerrar';

  @override
  String get backHome => 'Ir a la página de inicio y luego cerrar';

  @override
  String get fileUploads => 'Subida de archivos';

  @override
  String get fileUploadsHint =>
      'Permite que los campos de archivo abran el selector de Android. El usuario elige cada archivo.';

  @override
  String get share => 'Compartir';

  @override
  String get shareHint =>
      'navigator.share abre el menú para compartir de Android para texto y enlaces.';

  @override
  String get downloads => 'Descargas';

  @override
  String get downloadsHint =>
      'Los enlaces de descarga y archivos generados se guardan en la carpeta Descargas.';

  @override
  String get shareFiles => 'Compartir imágenes y PDF';

  @override
  String get galleryFolder => 'Carpeta de la galería (opcional)';

  @override
  String get galleryFolderExample => 'p. ej. Mis fotos';

  @override
  String get galleryFolderHelp =>
      'Pictures/<carpeta> para imágenes compartidas y descargadas. Vacío: el nombre de la app al compartir, Descargas para descargas.';

  @override
  String get shareToApp => 'Compartir directamente con una app (opcional)';

  @override
  String get shareToAppHelp =>
      'Paquete que abre directamente los archivos compartidos si está instalado, en lugar del menú para compartir.';

  @override
  String get usePackageName => 'Usa un nombre de paquete como com.whatsapp';

  @override
  String get offlineBuiltIn =>
      'Cuando el sitio no carga, se muestra una pantalla integrada de \"Página no disponible\".';

  @override
  String get chooseOfflinePage => 'Elegir página sin conexión (.html)';

  @override
  String get replaceOfflinePage => 'Cambiar página sin conexión';

  @override
  String get useBuiltInPage => 'Usar página integrada';

  @override
  String get userAgentSuffix => 'Sufijo del user agent (opcional)';

  @override
  String get atMost200 => 'Como máximo 200 caracteres';

  @override
  String get deleteProject => 'Eliminar proyecto';

  @override
  String get useColourLike => 'Usa un color como #1A73E8';

  @override
  String get noNetwork => 'Este ordenador no está en una red Wi-Fi o Ethernet.';

  @override
  String get installOnPhone => 'Instalar en el teléfono';

  @override
  String get installSteps =>
      '1. Conecta el teléfono a la misma Wi-Fi que este ordenador.\n2. Escanea el código con la cámara del teléfono y abre el enlace.\n3. Abre el archivo descargado. Permite instalar desde el navegador si Android lo pide.';

  @override
  String get linkStopped => 'El enlace se ha detenido.';

  @override
  String get networkAddress => 'Dirección de red';

  @override
  String get linkWorks10Min =>
      'El enlace funciona 10 minutos mientras esta ventana esté abierta.';

  @override
  String get trustedNetworkOnly =>
      'Úsalo solo en una red de confianza. Windows puede pedir permitir iLoveHTML en el firewall: permítelo para redes privadas.';

  @override
  String get startAgain => 'Empezar de nuevo';

  @override
  String get done => 'Hecho';

  @override
  String get kindPages => 'Páginas';

  @override
  String get kindImages => 'Imágenes';

  @override
  String get kindFonts => 'Fuentes';

  @override
  String get kindMedia => 'Audio y vídeo';

  @override
  String get kindData => 'Datos';

  @override
  String get kindOther => 'Otros';

  @override
  String get largestFiles => 'Archivos más grandes';

  @override
  String get advice => 'Consejos';

  @override
  String get checkOptimizing => 'Comprobar cuánto ahorra optimizar';

  @override
  String get name => 'Nombre';

  @override
  String get exampleCart => 'p. ej. Carrito';

  @override
  String get choosePage => 'Elige una página';

  @override
  String get page => 'Página';

  @override
  String get add => 'Añadir';

  @override
  String get differentKey => 'Clave de publicación distinta';

  @override
  String get buildAnyway => 'Compilar igualmente';

  @override
  String get windowsExe => 'App de Windows (.exe)';

  @override
  String get exeDescription =>
      'Un único archivo .exe que abre este sitio en su propia ventana con Microsoft Edge WebView2 (incluido en Windows 11 y Windows 10 actualizado). No está firmado, así que Windows puede mostrar \"Windows protegió su PC\" hasta que se elija Más información → Ejecutar de todas formas.';

  @override
  String get devTools => 'Herramientas de desarrollo (para pruebas)';

  @override
  String get devToolsHint =>
      'F12 e Inspeccionar funcionan en la app; déjalo desactivado en la versión que compartas';

  @override
  String get buildExe => 'Compilar .exe';

  @override
  String get windowsMsix => 'Instalador de Windows (.msix)';

  @override
  String get msixDescription =>
      'Instala la app como otro software de Windows: entrada en el menú Inicio, desinstalación limpia y actualizaciones cuando compartes una versión superior. Cada instalador se firma con un certificado.';

  @override
  String get needsWindowsSdk =>
      'Necesita el Windows SDK. Instálalo con:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      'Aún no hay certificado. Usa tu propio certificado de firma de código o crea uno de prueba para probarlo.';

  @override
  String get testCertNote =>
      'Certificado de prueba: Windows instala la app solo después de confiar en él una vez. Comparte el archivo .cer junto al instalador; se hace doble clic → Instalar certificado → Equipo local → \"Personas de confianza\". Un certificado comprado a una autoridad de certificación no necesita este paso.';

  @override
  String get createTestCert => 'Crear certificado de prueba';

  @override
  String get useMyPfx => 'Usar mi .pfx';

  @override
  String get savedCertificate => 'Certificado guardado';

  @override
  String get saveCer => 'Guardar .cer';

  @override
  String get buildInstaller => 'Compilar instalador';

  @override
  String get replaceCertQ => '¿Reemplazar el certificado?';

  @override
  String get replace => 'Reemplazar';

  @override
  String get publisherName => 'Nombre del editor';

  @override
  String get publisherNameHelp =>
      'Se muestra como editor cuando se instalan tus apps.';

  @override
  String get testCertCreated => 'Certificado de prueba creado';

  @override
  String get useMyCertificate => 'Usar mi certificado';

  @override
  String get certificateAdded => 'Certificado añadido';

  @override
  String get ok => 'Aceptar';

  @override
  String get allowUnknownApps =>
      'Permite \"Instalar apps desconocidas\" para iLoveHTML en la pantalla que se abrió y luego pulsa Instalar de nuevo.';

  @override
  String get debug => 'Depuración';

  @override
  String get release => 'Publicación';

  @override
  String get debugHint =>
      'Para pruebas. Firmado con una clave de depuración que se queda en este dispositivo; no sirve para publicar.';

  @override
  String get releaseHint =>
      'Para publicar. Firmado con tu clave de publicación; cada actualización posterior debe usar la misma clave y un código de versión mayor.';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      'Sube el .aab a Google Play Console. No se puede instalar directamente; usa un APK para probar en un teléfono.';

  @override
  String get createOrImportKey => 'Crear o importar una clave de publicación';

  @override
  String get releaseKey => 'Clave de publicación';

  @override
  String get manageKeys => 'Gestionar claves';

  @override
  String get buildDebugApk => 'Compilar APK de depuración';

  @override
  String get buildAppBundle => 'Compilar App Bundle';

  @override
  String get buildReleaseApk => 'Compilar APK de publicación';

  @override
  String get buildingUnavailable =>
      'La compilación aún no está disponible en esta plataforma.';

  @override
  String get buildFailed => 'La compilación falló';

  @override
  String get saveAs => 'Guardar como…';

  @override
  String get showInFolder => 'Mostrar en la carpeta';

  @override
  String get install => 'Instalar';

  @override
  String get saveToDevice => 'Guardar en el dispositivo';

  @override
  String get buildLog => 'Registro de compilación';

  @override
  String get history => 'Historial';

  @override
  String get twoLetters => 'Dos letras';

  @override
  String invalidHost(String host) {
    return 'Host no válido \"$host\"';
  }

  @override
  String get thisDevice => 'Este dispositivo';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compilando… $count líneas de registro',
      one: 'Compilando… 1 línea de registro',
      zero: 'Compilando…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'Sistema';

  @override
  String get accentColour => 'Color de acento';

  @override
  String get accentOrange => 'Naranja';

  @override
  String get accentGreen => 'Verde terminal';

  @override
  String get accentCyan => 'Cian';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentPink => 'Rosa';

  @override
  String get animations => 'Animaciones';

  @override
  String get animationsHint =>
      'Inicio ASCII, animación de compilación y transiciones de página';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get signing => 'Firma';

  @override
  String get releaseKeysSubtitle =>
      'Crea, importa y respalda las claves que firman tus versiones';

  @override
  String get storage => 'Almacenamiento';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count proyectos · $size',
      one: '1 proyecto · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'Motor de compilación';

  @override
  String get notAvailablePlatform => 'Aún no disponible en esta plataforma';

  @override
  String get gradleReady => 'Gradle en este PC (listo)';

  @override
  String get gradleNotReady => 'Gradle en este PC: no está listo';

  @override
  String get buildsRunOnPc =>
      'Todo se compila en este PC. No se sube ningún archivo.';

  @override
  String get onDeviceReady => 'Ensamblado en el dispositivo (listo)';

  @override
  String get onDeviceMissing =>
      'Ensamblado en el dispositivo: falta el APK base';

  @override
  String get buildsRunOnDevice =>
      'Todo se compila en este dispositivo. No se sube ningún archivo.';

  @override
  String get about => 'Acerca de';

  @override
  String get howToUse => 'Cómo se usa';

  @override
  String get howToUseSubtitle =>
      'Del sitio web a la app instalada en cinco pasos';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get version => 'Versión';

  @override
  String get versionCopied => 'Versión copiada';

  @override
  String get credit => 'Créditos';

  @override
  String madeBy(String author) {
    return 'Hecho con <3 por $author';
  }

  @override
  String get supportHint =>
      'iLoveHTML es gratis, sin anuncios ni rastreo. Si te ahorra tiempo, puedes apoyar su desarrollo.';

  @override
  String get buyMeACoffee => 'Invítame a un café';

  @override
  String couldNotOpenLink(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String lastUpdated(String date) {
    return 'Última actualización: $date';
  }

  @override
  String get howToStep1Title => 'Crea un proyecto';

  @override
  String get howToStep1Body =>
      'Pulsa Nueva app y elige archivos HTML, un ZIP de sitio web o la URL de un sitio https en vivo. Los archivos y ZIP funcionan sin conexión; una URL necesita internet.';

  @override
  String get howToStep2Title => 'Ponle nombre a tu app';

  @override
  String get howToStep2Body =>
      'Escribe el nombre de la app y un ID de paquete único como com.tunombre.app. Mantén el mismo ID de paquete en cada actualización.';

  @override
  String get howToStep3Title => 'Personalízala';

  @override
  String get howToStep3Body =>
      'En la pestaña Ajustes elige la página de inicio, el icono, la pantalla de inicio, los colores, la orientación, los accesos directos y las funciones del WebView. Pulsa Guardar al terminar. Usa Vista previa para probar la app antes.';

  @override
  String get howToStep4Title => 'Compila';

  @override
  String get howToStep4Body =>
      'En la pestaña Compilar elige Depuración para probar o Publicación para publicar. Las versiones de publicación necesitan una clave: créala y haz una copia. En Windows también puedes compilar un .exe o un instalador .msix.';

  @override
  String get howToStep5Title => 'Instala o comparte';

  @override
  String get howToStep5Body =>
      'Instala el APK en este teléfono, compártelo o guárdalo. En un PC usa Instalar en el teléfono para enviarlo por Wi-Fi. Sube los App Bundles (.aab) a Google Play Console.';

  @override
  String get howToTipsTitle => 'Consejos';

  @override
  String get howToTips =>
      '• Cada actualización debe usar el mismo ID de paquete y la misma clave de publicación, y un código de versión mayor.\n• Haz copias de tus claves y proyectos; nadie puede recuperar una clave perdida.\n• Usa el Informe de tamaño para hacer la app más pequeña.\n• Usa Copia del proyecto (arriba en un proyecto) para guardar una copia que puedas restaurar después.';

  @override
  String get termsBody =>
      'Estos Términos de uso se aplican a la app iLoveHTML (\"la app\"), creada por 1elevenop. Al usar la app los aceptas.\n\n## Qué hace la app\n\niLoveHTML convierte archivos HTML, ZIP de sitios web y direcciones web en apps de Android y Windows. Las compilaciones se ejecutan en tu propio dispositivo.\n\n## Tu contenido\n\nConservas todos los derechos sobre los sitios web, archivos, iconos y apps que creas. Eres responsable de tener derecho a usar ese contenido y de las apps que compilas y publicas, incluido cumplir la ley y las normas de tiendas como Google Play.\n\n## Uso aceptable\n\nNo uses la app para crear software ilegal, dañino o engañoso, ni que infrinja derechos de otros, como malware o apps que suplanten otras marcas.\n\n## Claves de publicación\n\nLas claves de publicación se guardan solo en tu dispositivo. Eres responsable de hacer copias y de proteger sus contraseñas. Una clave perdida no se puede recuperar, y las apps firmadas con ella ya no podrán actualizarse.\n\n## Sin garantía\n\nLa app se ofrece gratis y \"tal cual\", sin garantías de ningún tipo. En la medida en que la ley lo permita, el autor no es responsable de pérdidas de datos, claves, ingresos u otros daños derivados de su uso.\n\n## Cambios\n\nEstos términos pueden actualizarse con nuevas versiones de la app. La fecha de arriba indica el último cambio. Seguir usando la app significa que aceptas los términos actualizados.\n\n## Contacto\n\nPreguntas: abre una incidencia en el proyecto de GitHub de iLoveHTML de 1elevenop.';

  @override
  String get privacyBody =>
      'iLoveHTML está pensado para funcionar en tu dispositivo. Esta política explica qué significa eso para tus datos.\n\n## Datos que recopilamos\n\nNinguno. La app no tiene cuentas, ni analíticas, ni publicidad, ni rastreo. El autor no recibe ningún dato sobre ti ni sobre tus proyectos.\n\n## Datos guardados en tu dispositivo\n\nTus proyectos, archivos web, iconos, compilaciones y ajustes se guardan en el almacenamiento privado de la app en tu dispositivo. Las claves de publicación también se quedan en tu dispositivo: en Android se cifran con Android Keystore y en Windows sus contraseñas se cifran para tu cuenta de Windows. Desinstalar la app borra estos datos, así que haz copias.\n\n## Uso de la red\n\nLa app se conecta a internet solo cuando se lo pides: para comprobar o previsualizar una URL que escribiste, para abrir enlaces como Buy Me a Coffee en tu navegador y, en Windows, cuando Gradle descarga herramientas de compilación. La función Instalar en el teléfono sirve el archivo en tu red local durante 10 minutos, solo mientras su ventana está abierta.\n\n## Comprobación de actualizaciones\n\nSi \"Buscar actualizaciones\" está activado (lo está por defecto), unas dos veces al día iLoveHTML pregunta a GitHub (api.github.com) por la última versión de iLoveHTML para avisarte cuando salga una nueva. La solicitud no contiene cuentas, identificadores ni nada sobre tus proyectos; como cualquier sitio web, GitHub ve tu dirección IP. Desactívalo en Ajustes → Acerca de.\n\n## Apps que creas\n\nLas apps hechas con iLoveHTML no contienen rastreo de iLoveHTML. Lo que recopilen depende del sitio web que pongas en ellas, y tú eres responsable de su política de privacidad.\n\n## Menores\n\nLa app no recopila datos a sabiendas, ni de menores ni de nadie.\n\n## Cambios y contacto\n\nEsta política puede actualizarse con nuevas versiones de la app; la fecha de arriba indica el último cambio. Preguntas: abre una incidencia en el proyecto de GitHub de iLoveHTML de 1elevenop.';

  @override
  String get replaceWebsite => 'Reemplazar archivos del sitio';

  @override
  String get replaceWebsiteHint =>
      'Cambia a un nuevo ZIP o archivos HTML. El nombre, el ID del paquete, el icono, los ajustes y las claves no cambian.';

  @override
  String get replaceWithZipHint => 'Una nueva carpeta del sitio, comprimida';

  @override
  String get replaceWithFilesHint =>
      'Nuevas páginas .html con su CSS, JavaScript e imágenes';

  @override
  String get replaceWebsiteQ => '¿Reemplazar el sitio web?';

  @override
  String replaceWebsiteBody(String name) {
    return 'Todos los archivos del sitio de \"$name\" se reemplazan por los que elijas a continuación. El nombre, el ID del paquete, la versión, el icono, los ajustes, la clave de publicación y el historial se mantienen. Vuelve a compilar para obtener la app actualizada.';
  }

  @override
  String replaceFailed(String error) {
    return 'No se pudo reemplazar el sitio: $error';
  }

  @override
  String get websiteReplaced => 'Sitio reemplazado';

  @override
  String startPageChanged(String page) {
    return '\"$page\" no está en los archivos nuevos, así que la página de inicio cambió.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'Accesos directos quitados porque sus páginas ya no existen: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      'Vuelve a compilar para obtener la app actualizada. Para actualizar una app instalada, sube antes el código de versión.';

  @override
  String get unlockReason => 'Desbloquear iLoveHTML';

  @override
  String get resetReason =>
      'Verifica que eres tú para restablecer el bloqueo de iLoveHTML';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Incorrecto. Quedan $count intentos antes de esperar.',
      one: 'Incorrecto. Queda 1 intento antes de esperar.',
      zero: 'Incorrecto. Espera antes de reintentar.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return 'Demasiados intentos fallidos. Reintenta en $seconds s.';
  }

  @override
  String get enterPin => 'Introduce tu PIN';

  @override
  String get enterPassword => 'Introduce tu contraseña';

  @override
  String get showPassword => 'Mostrar';

  @override
  String get hidePassword => 'Ocultar';

  @override
  String hintIs(String hint) {
    return 'Pista: $hint';
  }

  @override
  String get showHint => 'Ver pista';

  @override
  String get deleteDigit => 'Borrar';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get useFingerprint => 'Usar huella o rostro';

  @override
  String get forgotPin => '¿Olvidaste el PIN?';

  @override
  String get forgotPassword => '¿Olvidaste la contraseña?';

  @override
  String digitsEntered(int count) {
    return '$count dígitos introducidos';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Código incorrecto. Quedan $count intentos.',
      one: 'Código incorrecto. Queda 1 intento.',
      zero: 'Código incorrecto. Espera antes de reintentar.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'Usar el bloqueo de este dispositivo';

  @override
  String get forgotWithDeviceHint =>
      'Verifica con tu huella, tu rostro o el bloqueo de pantalla del teléfono (PIN, patrón o contraseña) y luego elige uno nuevo para iLoveHTML.';

  @override
  String get verifyWithDevice => 'Verificar con el bloqueo del dispositivo';

  @override
  String get forgotWithCode => 'Usar tu código de recuperación';

  @override
  String get forgotWithCodeHint =>
      'El código de 16 caracteres que se mostró al configurar el bloqueo.';

  @override
  String get recoveryCode => 'Código de recuperación';

  @override
  String get useRecoveryCode => 'Usar código';

  @override
  String get forgotNoWay =>
      'Sin ninguno de los dos, el bloqueo solo se puede quitar borrando los datos de iLoveHTML en los ajustes del sistema. Eso elimina todos los proyectos y claves de publicación de este dispositivo.';

  @override
  String get pinDigitsOnly => 'Solo dígitos';

  @override
  String pinLength(int min, int max) {
    return 'De $min a $max dígitos';
  }

  @override
  String passwordMinLength(int count) {
    return 'Al menos $count caracteres';
  }

  @override
  String get chooseNewSecret => 'Elige un nuevo PIN o contraseña';

  @override
  String get setUpAppLock => 'Configurar el bloqueo';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => 'Nuevo PIN';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get repeatPin => 'Repite el PIN';

  @override
  String get pinsDoNotMatch => 'Los PIN no coinciden';

  @override
  String get hintOptional => 'Pista (opcional)';

  @override
  String get hintHelp =>
      'Se muestra en la pantalla de bloqueo para ayudarte a recordar. Cualquiera con el dispositivo puede leerla.';

  @override
  String get hintGivesAway =>
      'La pista no debe contener el PIN ni la contraseña';

  @override
  String get unlockWithFingerprint => 'Desbloquear con huella o rostro';

  @override
  String get unlockWithFingerprintHint =>
      'Tu PIN o contraseña sigue funcionando.';

  @override
  String get appLockNote =>
      'El bloqueo oculta iLoveHTML y sus proyectos a quien tome este dispositivo. No cifra los archivos de los proyectos.';

  @override
  String get saveAndContinue => 'Guardar';

  @override
  String get recoveryCodeTitle => 'Guarda tu código de recuperación';

  @override
  String get recoveryCodeBody =>
      'Si olvidas tu PIN o contraseña, este código te permite poner uno nuevo. Solo se muestra ahora. Apúntalo o guárdalo en un lugar seguro, no solo en este dispositivo.';

  @override
  String get copy => 'Copiar';

  @override
  String get iSavedTheCode => 'He guardado el código';

  @override
  String get enterCurrentPin => 'Introduce el PIN actual';

  @override
  String get enterCurrentPassword => 'Introduce la contraseña actual';

  @override
  String get wrongPin => 'PIN incorrecto';

  @override
  String get wrongPassword => 'Contraseña incorrecta';

  @override
  String get appLockOffHint =>
      'Desactivado. Pide un PIN, contraseña o huella antes de abrir iLoveHTML.';

  @override
  String get appLockOnPin => 'Activado, con PIN';

  @override
  String get appLockOnPassword => 'Activado, con contraseña';

  @override
  String get lockAgainAfter => 'Volver a bloquear al salir de la app';

  @override
  String get relockImmediately => 'Inmediatamente';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tras $count minutos',
      one: 'Tras 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'Solo al iniciar iLoveHTML';

  @override
  String get changePinOrHint => 'Cambiar PIN, contraseña o pista';

  @override
  String get lockNow => 'Bloquear ahora';

  @override
  String get turnOffLock => 'Desactivar bloqueo';

  @override
  String get newUpdate => 'NUEVA ACTUALIZACIÓN';

  @override
  String updateAvailable(String version) {
    return 'iLoveHTML $version está disponible';
  }

  @override
  String updateTitle(String version) {
    return 'Actualizar a $version';
  }

  @override
  String youHaveVersion(String version) {
    return 'Tienes la $version.';
  }

  @override
  String get updateAndroidHint =>
      'El APK se descarga en tu navegador. Ábrelo para instalarlo sobre esta versión; tus proyectos, claves y ajustes se mantienen.';

  @override
  String get updateWindowsHint =>
      'El ZIP se descarga en tu navegador. Cierra iLoveHTML, descomprímelo y reemplaza tu carpeta de iLoveHTML; tus proyectos, claves y ajustes se mantienen.';

  @override
  String get whatsNew => 'Novedades';

  @override
  String get releasePage => 'Página de la versión';

  @override
  String get downloadUpdate => 'Descargar';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checkForUpdatesHint =>
      'Unas dos veces al día, pregunta a GitHub si hay un iLoveHTML más nuevo. No se envía nada sobre ti ni tus proyectos.';

  @override
  String get checkNow => 'Buscar ahora';

  @override
  String get checkingUpdates => 'Buscando…';

  @override
  String get upToDate => 'Tienes la última versión.';

  @override
  String get updateCheckFailed => 'No se pudo comprobar. ¿Tienes conexión?';

  @override
  String get updateInAppHint =>
      'iLoveHTML descarga la actualización, la comprueba y Android te pide instalarla sobre esta versión. Tus proyectos, claves y ajustes se mantienen.';

  @override
  String get verifyingDownload => 'Comprobando el archivo…';

  @override
  String downloadingMb(String done) {
    return 'Descargando… $done MB';
  }

  @override
  String downloadingOf(String done, String total) {
    return 'Descargando… $done de $total MB';
  }

  @override
  String get installerOpened =>
      'El instalador de Android está abierto. Toca Actualizar ahí. Si se cerró, toca Instalar.';

  @override
  String downloadFailed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get tryAgain => 'Reintentar';
}

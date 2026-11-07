// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String unreadableProject(String name) {
    return '无法读取的项目:$name';
  }

  @override
  String get emptyHintWindows =>
      '把 HTML 文件、网站 ZIP 或在线 https 网站变成 Android 或 Windows 应用。构建在本设备上完成。';

  @override
  String get emptyHintAndroid =>
      '把 HTML 文件、网站 ZIP 或在线 https 网站变成 Android 应用。构建在本设备上完成。';

  @override
  String notBuiltYet(String version) {
    return 'v$version · 尚未构建';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · 上次构建 $status $ago';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String hoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String daysAgo(int n) {
    return '$n 天前';
  }

  @override
  String chooseBackupFile(String ext) {
    return '请选择 $ext 备份文件';
  }

  @override
  String restored(String name) {
    return '已恢复 $name';
  }

  @override
  String notUsableBackup(String message) {
    return '备份不可用:$message';
  }

  @override
  String restoreFailed(String error) {
    return '恢复失败:$error';
  }

  @override
  String importFailed(String error) {
    return '导入失败:$error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导入 $count 个文件',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return '起始页:$page';
  }

  @override
  String htmlPagesFound(int count) {
    return '找到 $count 个 HTML 页面;可在设置中更改起始页。';
  }

  @override
  String filesMissing(int count) {
    return '缺少 $count 个被引用的文件:';
  }

  @override
  String andMore(int count) {
    return '……还有 $count 个';
  }

  @override
  String fileNotFound(String path) {
    return '找不到文件:$path';
  }

  @override
  String wouldOpenOutside(String url) {
    return '将在应用外打开:$url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return '页面加载失败:$description($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return '无法启动预览:$error';
  }

  @override
  String previewTitle(String name) {
    return '预览 · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return '网站返回 HTTP $code';
  }

  @override
  String redirected(int count) {
    return '已重定向 $count 次 — 应用将从这个地址启动。';
  }

  @override
  String importedKey(String alias) {
    return '已导入\"$alias\"';
  }

  @override
  String backupSavedAs(String alias) {
    return '备份已保存为 $alias.jks。请另外保管密码。';
  }

  @override
  String backupFailed(String error) {
    return '备份失败:$error';
  }

  @override
  String deletedKey(String alias) {
    return '已从本设备删除\"$alias\"';
  }

  @override
  String get releaseKeysIntroWindows =>
      '发布版本使用这些密钥之一签名。Google Play 和 Android 只接受与首个版本使用相同密钥签名的更新。密钥保存在这台电脑上,密码针对你的 Windows 账户加密;备份是受密码保护的 .jks 文件,可在手机或电脑上的 iLoveHTML、Gradle 和 keytool 中使用。';

  @override
  String get releaseKeysIntroAndroid =>
      '发布版本使用这些密钥之一签名。Google Play 和 Android 只接受与首个版本使用相同密钥签名的更新。密钥保存在这部手机上,由 Android Keystore 加密;备份是受密码保护的 .jks 文件,可在手机或电脑上的 iLoveHTML、Gradle 和 keytool 中使用。';

  @override
  String validUntilDate(String date) {
    return '有效期至 $date';
  }

  @override
  String get atLeast8 => '至少 8 个字符';

  @override
  String deleteKeyBody(String alias) {
    return '用\"$alias\"签名的应用只能用这个密钥更新。没有备份的话,你将再也无法更新它们。';
  }

  @override
  String typeToConfirm(String alias) {
    return '输入\"$alias\"以确认';
  }

  @override
  String backupSaved(String file) {
    return '备份已保存:$file';
  }

  @override
  String shortcutExists(String page) {
    return '\"$page\"的快捷方式已存在';
  }

  @override
  String deleteProjectBody(String name) {
    return '这将从本设备删除\"$name\"、它的网站文件和已构建的 APK。已安装的应用不受影响。';
  }

  @override
  String offlinePageShown(String page) {
    return '网站无法加载时,会显示你的页面\"$page\"。链接到 https://appassets.androidplatform.net/html2apk/retry 可提供\"重试\"按钮。';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已下载 $count 次。',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return '无法读取文件:$error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count 个文件,$size';
  }

  @override
  String checkFailed(String error) {
    return '检查失败:$error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return '优化可缩小 $count 个文件,节省 $saved($before → $after)。APK 本身也会压缩,因此对 CSS 和 JSON 来说,APK 中的节省通常更少。';
  }

  @override
  String example(String value) {
    return '例如 $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return '无法加载发布密钥:$error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return '此应用首次发布时使用了另一个密钥(SHA-256 $sha…)。安装了那个版本的手机无法更新到用\"$alias\"签名的 APK,Google Play 也会拒绝将其作为更新。';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return '发布者:$publisher · 有效期至 $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return '通过\"$publisher\"签名的安装程序安装的应用,只能由发布者名称相同的安装程序更新。如果之后可能需要,请先备份当前证书。';
  }

  @override
  String passwordOf(String file) {
    return '$file 的密码';
  }

  @override
  String savedFile(String file) {
    return '已保存 $file';
  }

  @override
  String saveFailed(String error) {
    return '保存失败:$error';
  }

  @override
  String get cannotBuildYet => '暂时无法构建:';

  @override
  String get shareFilesHint =>
      '带文件的 navigator.share() 可将图片和 PDF 发送到其他应用。在 Android 10 及以上,分享的图片也会保存到相册。';

  @override
  String get projects => '项目';

  @override
  String get restoreBackup => '恢复备份';

  @override
  String get settings => '设置';

  @override
  String get newApp => '新建应用';

  @override
  String get htmlFiles => 'HTML 文件';

  @override
  String get htmlFilesHint =>
      '选择一个 .html 页面,如果 CSS、JavaScript 和图片是单独的文件,也一并选择。可离线使用。';

  @override
  String get websiteZip => '网站 ZIP';

  @override
  String get websiteZipHint => '整个网站文件夹的压缩包。可离线使用。';

  @override
  String get websiteUrl => '网站网址';

  @override
  String get websiteUrlHint => '封装一个在线 https 网站。需要联网。';

  @override
  String get noProjectsYet => '还没有项目';

  @override
  String get building => '正在构建…';

  @override
  String get selectHtmlFile => '请至少选择一个 .html 文件,以及它用到的 CSS、JavaScript 或图片。';

  @override
  String get defaultAppName => '我的应用';

  @override
  String get appName => '应用名称';

  @override
  String get enterName => '请输入名称';

  @override
  String get packageId => '包名';

  @override
  String get packageIdHelp => '设备和 Play 上唯一的 ID,例如 com.yourname.app';

  @override
  String get cancel => '取消';

  @override
  String get importButton => '导入';

  @override
  String get noMissingFiles => '没有缺失的文件';

  @override
  String get openProject => '打开项目';

  @override
  String get noConsoleMessages => '没有控制台消息或问题';

  @override
  String get viewport => '视口';

  @override
  String get consoleAndIssues => '控制台和问题';

  @override
  String get checkWebsite => '检查网站';

  @override
  String get websiteReachable => '网站可访问';

  @override
  String get liveSiteNote => '应用会实时显示这个网站,需要联网。离线时无法使用。';

  @override
  String get create => '创建';

  @override
  String get backUpKeyNow => '立即备份此密钥';

  @override
  String get backUpKeyBody =>
      '应用的每次更新都必须使用同一个密钥签名。如果丢失本设备或卸载 iLoveHTML,除非有备份,否则密钥将永久丢失。\n\n请把 .jks 文件保存在安全的地方(不要只存在本设备上),并另外保管密码。';

  @override
  String get later => '稍后';

  @override
  String get saveBackup => '保存备份';

  @override
  String get certificate => '证书';

  @override
  String get sha256Fingerprint => 'SHA-256 指纹';

  @override
  String get sha1Fingerprint => 'SHA-1 指纹';

  @override
  String get validUntil => '有效期至';

  @override
  String get added => '添加于';

  @override
  String get saveBackupJks => '保存备份(.jks)';

  @override
  String get delete => '删除';

  @override
  String get releaseKeys => '发布密钥';

  @override
  String get createKey => '创建密钥';

  @override
  String get importKeystoreFile => '导入 .jks / .keystore / .p12';

  @override
  String get noReleaseKeys => '还没有发布密钥';

  @override
  String get createReleaseKey => '创建发布密钥';

  @override
  String get keyAlias => '密钥别名';

  @override
  String get keyAliasHelp => '字母、数字、点、连字符、下划线';

  @override
  String get publisherNameField => '你的名字或应用发布者';

  @override
  String get required => '必填';

  @override
  String get organizationOptional => '组织(可选)';

  @override
  String get countryCodeOptional => '国家代码(可选)';

  @override
  String get password => '密码';

  @override
  String get passwordHelp => '用于密钥库和密钥';

  @override
  String get repeatPassword => '再次输入密码';

  @override
  String get passwordsDoNotMatch => '两次密码不一致';

  @override
  String get createKeyNote => 'RSA 2048 位,有效期 30 年。在电脑上使用备份时需要此密码。';

  @override
  String get noPrivateKeys => '此文件中没有私钥';

  @override
  String get importKeystore => '导入密钥库';

  @override
  String get keystorePassword => '密钥库密码';

  @override
  String get keyPassword => '密钥密码';

  @override
  String get keyPasswordHelp => '与密钥库密码相同时留空';

  @override
  String get importKeystoreNote => 'iLoveHTML 会保留一份由密钥库密码保护的副本。你的原始文件不会改变。';

  @override
  String get open => '打开';

  @override
  String get deleteReleaseKey => '删除发布密钥?';

  @override
  String get deleteKey => '删除密钥';

  @override
  String get projectNotFound => '找不到项目';

  @override
  String get backUpProject => '备份项目';

  @override
  String get preview => '预览';

  @override
  String get build => '构建';

  @override
  String get previewInBrowser => '在浏览器中预览';

  @override
  String get liveSiteOpened => '在线网站已在默认浏览器中打开。';

  @override
  String get servedFromPc =>
      '仅在此窗口打开期间由这台电脑提供。手机版应用还有控制台和链接检查;这里请使用浏览器的开发者工具(F12)。';

  @override
  String get missingFiles => '缺失的文件:';

  @override
  String get close => '关闭';

  @override
  String get stopPreview => '停止预览';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get iconUpdated => '图标已更新';

  @override
  String get splashUpdated => '启动图已更新';

  @override
  String get offlinePageAdded => '已添加离线页面';

  @override
  String get deleteProjectQ => '删除项目?';

  @override
  String get save => '保存';

  @override
  String get sectionApp => '应用';

  @override
  String get sectionContent => '内容';

  @override
  String get sectionShortcuts => '快捷方式';

  @override
  String get sectionAppSize => '应用大小';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionDevices => '设备';

  @override
  String get sectionSecurity => '安全';

  @override
  String get sectionOffline => '离线';

  @override
  String get sectionDanger => '危险操作';

  @override
  String get versionName => '版本名称';

  @override
  String get versionCode => '版本号';

  @override
  String get defaultIcon => '默认图标';

  @override
  String get customIcon => '自定义图标';

  @override
  String get chooseImage => '选择图片';

  @override
  String get iconHint =>
      'PNG、JPEG、WebP、GIF、BMP 或 SVG,至少 48 px;建议 512 × 512。非正方形图片会居中。';

  @override
  String get startPage => '起始页';

  @override
  String get loadedLive => '实时加载;应用需要联网。';

  @override
  String get otherSites => '在应用内打开的其他网站(可选)';

  @override
  String get otherSitesHelp => '用逗号分隔。指向其他网站的链接会在浏览器中打开。';

  @override
  String get orientation => '屏幕方向';

  @override
  String get orientationAuto => '自动';

  @override
  String get portrait => '竖屏';

  @override
  String get landscape => '横屏';

  @override
  String get shortcutsHint => '长按应用图标即可看到这些页面。';

  @override
  String get removeShortcut => '移除快捷方式';

  @override
  String get addShortcut => '添加快捷方式';

  @override
  String get optimizeFiles => '构建时优化文件';

  @override
  String get optimizeFilesHint =>
      '缩小应用中的 CSS、JSON、PNG 和大型 JPEG 文件。JPEG 以 85% 质量重新保存。你的项目文件不会改变。';

  @override
  String get sizeReport => '大小报告';

  @override
  String get statusBarColour => '状态栏颜色';

  @override
  String get navBarColour => '导航栏颜色';

  @override
  String get splashScreen => '启动画面';

  @override
  String get splashIconHint => '在首个页面加载完成前显示应用图标。';

  @override
  String get splashImageHint => '在首个页面加载完成前显示你的启动图。';

  @override
  String get splashBackground => '启动画面背景';

  @override
  String get chooseSplash => '选择启动图';

  @override
  String get replaceSplash => '更换启动图';

  @override
  String get useAppIcon => '使用应用图标';

  @override
  String get theme => '主题';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get followPhone => '跟随手机';

  @override
  String get themeHint => '设置 prefers-color-scheme,带有深色模式 CSS 的页面会随之切换。';

  @override
  String get fullscreen => '全屏';

  @override
  String get fullscreenHint => '隐藏状态栏和导航栏。从边缘滑动可暂时显示。';

  @override
  String get keepScreenOn => '保持屏幕常亮';

  @override
  String get keepScreenOnHint => '应用打开时屏幕不会熄灭。';

  @override
  String get tvHint => '在电视主屏幕上显示应用,并用图标和名称生成横幅。遥控器的方向键可在链接和按钮之间移动,按 OK 打开。';

  @override
  String get rotateTablets => '平板上自由旋转';

  @override
  String get rotateTabletsHint =>
      '即使手机保持上面选择的方向,平板和折叠屏也可以任意旋转。Android 16 及以上在大屏幕上始终允许。';

  @override
  String get desktopLayout => '平板和电视上使用桌面布局';

  @override
  String get desktopLayoutHint => '向网站请求电脑版布局,而不是手机版布局。';

  @override
  String get appLock => '应用锁';

  @override
  String get appLockHint => '打开应用时以及在后台 30 秒后,要求验证指纹、面容或屏幕锁。没有屏幕锁的手机会带提示打开应用。';

  @override
  String get javascriptHint => '大多数网站都需要。静态页面可以关闭。';

  @override
  String get localStorage => '本地存储';

  @override
  String get internetAccess => '网络访问';

  @override
  String get internetAccessHint => '添加 INTERNET 权限,用于从网络加载 CDN、API 或字体。';

  @override
  String get openOtherSites => '在浏览器中打开其他网站';

  @override
  String get openOtherSitesHint => '关闭时,指向其他网站的链接不会有任何反应。';

  @override
  String get pullToRefresh => '下拉刷新';

  @override
  String get pullToRefreshHint => '在页面顶部向下滑动可重新加载,或在出错后重试。';

  @override
  String get notifications => '通知';

  @override
  String get notificationsHint =>
      '应用打开时,页面可以通过网页 Notification API 显示 Android 通知。Android 13 及以上会先询问用户。不支持推送消息。';

  @override
  String get backButton => '返回键';

  @override
  String get backHistory => '先返回上一页,再关闭应用';

  @override
  String get backTwice => '先返回上一页,再按两次关闭';

  @override
  String get backConfirm => '先返回上一页,关闭前询问';

  @override
  String get backHome => '先回到起始页,再关闭';

  @override
  String get fileUploads => '文件上传';

  @override
  String get fileUploadsHint => '让文件输入框打开 Android 文件选择器。每个文件都由用户选择。';

  @override
  String get share => '分享';

  @override
  String get shareHint => 'navigator.share 会为文字和链接打开 Android 分享面板。';

  @override
  String get downloads => '下载';

  @override
  String get downloadsHint => '下载链接和生成的文件会保存到 Download 文件夹。';

  @override
  String get shareFiles => '分享图片和 PDF';

  @override
  String get galleryFolder => '相册文件夹(可选)';

  @override
  String get galleryFolderExample => '例如 我的照片';

  @override
  String get galleryFolderHelp =>
      '分享和下载的图片保存在 Pictures/<文件夹>。留空:分享使用应用名称,下载使用 Download。';

  @override
  String get shareToApp => '直接分享到应用(可选)';

  @override
  String get shareToAppHelp => '如果已安装,文件分享会直接打开此包名的应用,而不是分享面板。';

  @override
  String get usePackageName => '请使用 com.whatsapp 这样的包名';

  @override
  String get offlineBuiltIn => '网站无法加载时,会显示内置的\"页面不可用\"画面。';

  @override
  String get chooseOfflinePage => '选择离线页面(.html)';

  @override
  String get replaceOfflinePage => '更换离线页面';

  @override
  String get useBuiltInPage => '使用内置页面';

  @override
  String get userAgentSuffix => 'User-Agent 后缀(可选)';

  @override
  String get atMost200 => '最多 200 个字符';

  @override
  String get deleteProject => '删除项目';

  @override
  String get useColourLike => '请使用 #1A73E8 这样的颜色';

  @override
  String get noNetwork => '这台电脑没有连接 Wi-Fi 或以太网。';

  @override
  String get installOnPhone => '安装到手机';

  @override
  String get installSteps =>
      '1. 让手机连接到与这台电脑相同的 Wi-Fi。\n2. 用手机相机扫描二维码并打开链接。\n3. 打开下载的文件。如果 Android 询问,请允许从浏览器安装。';

  @override
  String get linkStopped => '链接已停止。';

  @override
  String get networkAddress => '网络地址';

  @override
  String get linkWorks10Min => '此窗口打开期间,链接在 10 分钟内有效。';

  @override
  String get trustedNetworkOnly =>
      '只在你信任的网络中使用。Windows 可能会询问是否允许 iLoveHTML 通过防火墙:请允许专用网络。';

  @override
  String get startAgain => '重新开始';

  @override
  String get done => '完成';

  @override
  String get kindPages => '页面';

  @override
  String get kindImages => '图片';

  @override
  String get kindFonts => '字体';

  @override
  String get kindMedia => '音频和视频';

  @override
  String get kindData => '数据';

  @override
  String get kindOther => '其他';

  @override
  String get largestFiles => '最大的文件';

  @override
  String get advice => '建议';

  @override
  String get checkOptimizing => '查看优化能节省多少';

  @override
  String get name => '名称';

  @override
  String get exampleCart => '例如 购物车';

  @override
  String get choosePage => '请选择页面';

  @override
  String get page => '页面';

  @override
  String get add => '添加';

  @override
  String get differentKey => '发布密钥不同';

  @override
  String get buildAnyway => '仍然构建';

  @override
  String get windowsExe => 'Windows 应用(.exe)';

  @override
  String get exeDescription =>
      '一个 .exe 文件,用 Microsoft Edge WebView2(Windows 11 和已更新的 Windows 10 自带)在独立窗口中打开此网站。它没有代码签名,因此 Windows 可能显示\"Windows 已保护你的电脑\",需选择\"更多信息 → 仍要运行\"。';

  @override
  String get devTools => '开发者工具(测试用)';

  @override
  String get devToolsHint => '应用中可使用 F12 和\"检查\";分享的版本请关闭';

  @override
  String get buildExe => '构建 .exe';

  @override
  String get windowsMsix => 'Windows 安装程序(.msix)';

  @override
  String get msixDescription =>
      '像其他 Windows 软件一样安装应用:开始菜单入口、干净卸载,分享更高版本时可更新。每个安装程序都使用证书签名。';

  @override
  String get needsWindowsSdk =>
      '需要 Windows SDK。使用以下命令安装:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate => '还没有证书。使用你自己的代码签名证书,或创建测试证书试用。';

  @override
  String get testCertNote =>
      '测试证书:用户先信任它一次后,Windows 才会安装应用。把 .cer 文件和安装程序一起分享;双击它 → 安装证书 → 本地计算机 →\"受信任人\"。从证书颁发机构购买的证书不需要这一步。';

  @override
  String get createTestCert => '创建测试证书';

  @override
  String get useMyPfx => '使用我的 .pfx';

  @override
  String get savedCertificate => '证书已保存';

  @override
  String get saveCer => '保存 .cer';

  @override
  String get buildInstaller => '构建安装程序';

  @override
  String get replaceCertQ => '替换证书?';

  @override
  String get replace => '替换';

  @override
  String get publisherName => '发布者名称';

  @override
  String get publisherNameHelp => '安装你的应用时显示为发布者。';

  @override
  String get testCertCreated => '测试证书已创建';

  @override
  String get useMyCertificate => '使用我的证书';

  @override
  String get certificateAdded => '证书已添加';

  @override
  String get ok => '确定';

  @override
  String get allowUnknownApps => '请在打开的界面中允许 iLoveHTML\"安装未知应用\",然后再次点按安装。';

  @override
  String get debug => '调试';

  @override
  String get release => '发布';

  @override
  String get debugHint => '用于测试。使用保存在本设备上的调试密钥签名;不能用于发布。';

  @override
  String get releaseHint => '用于发布。使用你的发布密钥签名;之后每次更新都必须使用相同密钥和更高的版本号。';

  @override
  String get appBundlePlay => 'App Bundle(Play)';

  @override
  String get aabHint => '把 .aab 上传到 Google Play Console。它不能直接安装;在手机上测试请使用 APK。';

  @override
  String get createOrImportKey => '创建或导入发布密钥';

  @override
  String get releaseKey => '发布密钥';

  @override
  String get manageKeys => '管理密钥';

  @override
  String get buildDebugApk => '构建调试 APK';

  @override
  String get buildAppBundle => '构建 App Bundle';

  @override
  String get buildReleaseApk => '构建发布 APK';

  @override
  String get buildingUnavailable => '此平台暂不支持构建。';

  @override
  String get buildFailed => '构建失败';

  @override
  String get saveAs => '另存为…';

  @override
  String get showInFolder => '在文件夹中显示';

  @override
  String get install => '安装';

  @override
  String get saveToDevice => '保存到设备';

  @override
  String get buildLog => '构建日志';

  @override
  String get history => '历史记录';

  @override
  String get twoLetters => '两个字母';

  @override
  String invalidHost(String host) {
    return '无效的主机\"$host\"';
  }

  @override
  String get thisDevice => '本设备';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在构建… $count 行日志',
      zero: '正在构建…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => '跟随系统';

  @override
  String get accentColour => '强调色';

  @override
  String get accentOrange => '橙色';

  @override
  String get accentGreen => '终端绿';

  @override
  String get accentCyan => '青色';

  @override
  String get accentViolet => '紫罗兰';

  @override
  String get accentPink => '粉色';

  @override
  String get animations => '动画';

  @override
  String get animationsHint => 'ASCII 启动画面、构建动画和页面过渡';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '系统默认';

  @override
  String get signing => '签名';

  @override
  String get releaseKeysSubtitle => '创建、导入和备份为你的版本签名的密钥';

  @override
  String get storage => '存储';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个项目 · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => '构建引擎';

  @override
  String get notAvailablePlatform => '此平台暂不可用';

  @override
  String get gradleReady => '这台电脑上的 Gradle(就绪)';

  @override
  String get gradleNotReady => '这台电脑上的 Gradle:未就绪';

  @override
  String get buildsRunOnPc => '构建完全在这台电脑上进行。不会上传任何文件。';

  @override
  String get onDeviceReady => '设备端组装(就绪)';

  @override
  String get onDeviceMissing => '设备端组装:缺少基础 APK';

  @override
  String get buildsRunOnDevice => '构建完全在本设备上进行。不会上传任何文件。';

  @override
  String get about => '关于';

  @override
  String get howToUse => '使用方法';

  @override
  String get howToUseSubtitle => '五步从网站到已安装的应用';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get version => '版本';

  @override
  String get versionCopied => '版本已复制';

  @override
  String get credit => '致谢';

  @override
  String madeBy(String author) {
    return '由 $author 用 <3 制作';
  }

  @override
  String get supportHint => 'iLoveHTML 免费,没有广告,也没有跟踪。如果它帮你节省了时间,欢迎支持开发。';

  @override
  String get buyMeACoffee => '请我喝杯咖啡';

  @override
  String couldNotOpenLink(String url) {
    return '无法打开 $url';
  }

  @override
  String lastUpdated(String date) {
    return '最后更新:$date';
  }

  @override
  String get howToStep1Title => '创建项目';

  @override
  String get howToStep1Body =>
      '点按\"新建应用\",选择 HTML 文件、网站 ZIP 或在线 https 网站网址。文件和 ZIP 可离线使用;网址需要联网。';

  @override
  String get howToStep2Title => '为应用命名';

  @override
  String get howToStep2Body =>
      '输入应用名称和唯一的包名,例如 com.yourname.app。每次更新都要使用相同的包名。';

  @override
  String get howToStep3Title => '自定义';

  @override
  String get howToStep3Body =>
      '在\"设置\"标签页中选择起始页、图标、启动画面、颜色、屏幕方向、快捷方式和 WebView 功能。完成后点按\"保存\"。可以先用\"预览\"试用应用。';

  @override
  String get howToStep4Title => '构建';

  @override
  String get howToStep4Body =>
      '在\"构建\"标签页中,测试选择\"调试\",发布选择\"发布\"。发布版本需要发布密钥:请创建并备份。在 Windows 上还可以构建 .exe 或 .msix 安装程序。';

  @override
  String get howToStep5Title => '安装或分享';

  @override
  String get howToStep5Body =>
      '在这部手机上安装 APK,或分享、保存它。在电脑上使用\"安装到手机\"通过 Wi-Fi 发送。App Bundle(.aab)请上传到 Google Play Console。';

  @override
  String get howToTipsTitle => '提示';

  @override
  String get howToTips =>
      '• 每次更新都必须使用相同的包名和发布密钥,以及更高的版本号。\n• 请备份发布密钥和项目;丢失的密钥任何人都无法找回。\n• 使用\"大小报告\"让应用变得更小。\n• 使用\"备份项目\"(项目页面顶部)保留一份以后可以恢复的副本。';

  @override
  String get termsBody =>
      '本使用条款适用于由 1elevenop 制作的 iLoveHTML 应用(\"本应用\")。使用本应用即表示你同意本条款。\n\n## 本应用的功能\n\niLoveHTML 将 HTML 文件、网站 ZIP 和网址转换为 Android 和 Windows 应用。构建在你自己的设备上进行。\n\n## 你的内容\n\n你创建的网站、文件、图标和应用的所有权利都归你所有。你需确保有权使用这些内容,并对你构建和发布的应用负责,包括遵守法律以及 Google Play 等应用商店的规则。\n\n## 可接受的使用\n\n不得使用本应用构建违法、有害、欺骗性或侵犯他人权利的软件,例如恶意软件或冒充其他品牌的应用。\n\n## 发布密钥\n\n发布密钥只保存在你的设备上。你需自行负责备份密钥并保管好密码。丢失的密钥无法找回,用它签名的应用将无法再更新。\n\n## 无担保\n\n本应用免费提供,按\"现状\"提供,不附带任何形式的担保。在法律允许的范围内,作者不对因使用本应用造成的数据、密钥、收入损失或其他损害承担责任。\n\n## 变更\n\n本条款可能随本应用的新版本更新。上方日期为最后一次更改。继续使用本应用即表示你接受更新后的条款。\n\n## 联系方式\n\n如有疑问:请在 1elevenop 的 iLoveHTML GitHub 项目中提交 issue。';

  @override
  String get privacyBody =>
      'iLoveHTML 设计为在你的设备上运行。本政策说明这对你的数据意味着什么。\n\n## 我们收集的数据\n\n没有。本应用没有账户、没有分析、没有广告,也没有跟踪。作者不会收到任何关于你或你的项目的数据。\n\n## 保存在你设备上的数据\n\n你的项目、网站文件、图标、构建产物和设置保存在本应用在你设备上的私有存储中。发布密钥也保存在你的设备上:在 Android 上由 Android Keystore 加密,在 Windows 上其密码针对你的 Windows 账户加密。卸载本应用会删除这些数据,请做好备份。\n\n## 网络使用\n\n本应用只在你要求时连接互联网:检查或预览你输入的网站网址、在浏览器中打开 Buy Me a Coffee 等链接,以及在 Windows 上由 Gradle 下载构建工具时。\"安装到手机\"功能仅在其窗口打开期间,在你的本地网络上提供文件 10 分钟。\n\n## 检查更新\n\n如果开启了\"检查更新\"(默认开启),iLoveHTML 大约每天两次向 GitHub(api.github.com)查询最新的 iLoveHTML 版本,以便在有新版本时通知你。该请求不包含账户、标识符或任何项目信息;和访问任何网站一样,GitHub 能看到你的 IP 地址。可在 设置 → 关于 中关闭。\n\n## 你构建的应用\n\n使用 iLoveHTML 制作的应用不包含来自 iLoveHTML 的跟踪。它们收集什么取决于你放入的网站,你需对其隐私政策负责。\n\n## 儿童\n\n本应用不会有意收集任何人的数据,包括儿童。\n\n## 变更与联系方式\n\n本政策可能随本应用的新版本更新;上方日期为最后一次更改。如有疑问:请在 1elevenop 的 iLoveHTML GitHub 项目中提交 issue。';

  @override
  String get replaceWebsite => '替换网站文件';

  @override
  String get replaceWebsiteHint => '换成新的 ZIP 或 HTML 文件。名称、包名、图标、设置和密钥保持不变。';

  @override
  String get replaceWithZipHint => '新的网站文件夹压缩包';

  @override
  String get replaceWithFilesHint => '新的 .html 页面及其 CSS、JavaScript 和图片';

  @override
  String get replaceWebsiteQ => '替换网站?';

  @override
  String replaceWebsiteBody(String name) {
    return '\"$name\"的所有网站文件将被你接下来选择的文件替换。应用名称、包名、版本、图标、设置、发布密钥和构建历史保持不变。重新构建即可得到更新后的应用。';
  }

  @override
  String replaceFailed(String error) {
    return '无法替换网站:$error';
  }

  @override
  String get websiteReplaced => '网站已替换';

  @override
  String startPageChanged(String page) {
    return '新文件中没有\"$page\",因此起始页已更改。';
  }

  @override
  String shortcutsRemoved(String pages) {
    return '页面已不存在,已移除快捷方式:$pages';
  }

  @override
  String get rebuildAfterReplace => '重新构建即可得到更新后的应用。要更新已安装的应用,请先提高版本号。';

  @override
  String get unlockReason => '解锁 iLoveHTML';

  @override
  String get resetReason => '验证身份以重置 iLoveHTML 锁';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '错误。再错 $count 次需要等待。',
      zero: '错误。请稍后再试。',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return '错误次数过多。请在 $seconds 秒后重试。';
  }

  @override
  String get enterPin => '输入 PIN 码';

  @override
  String get enterPassword => '输入密码';

  @override
  String get showPassword => '显示';

  @override
  String get hidePassword => '隐藏';

  @override
  String hintIs(String hint) {
    return '提示:$hint';
  }

  @override
  String get showHint => '显示提示';

  @override
  String get deleteDigit => '删除';

  @override
  String get unlock => '解锁';

  @override
  String get useFingerprint => '使用指纹或面容';

  @override
  String get forgotPin => '忘记 PIN 码?';

  @override
  String get forgotPassword => '忘记密码?';

  @override
  String digitsEntered(int count) {
    return '已输入 $count 位';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '代码错误。还可尝试 $count 次。',
      zero: '代码错误。请稍后再试。',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => '使用本设备的锁屏';

  @override
  String get forgotWithDeviceHint =>
      '使用指纹、面容或手机锁屏(PIN、图案或密码)验证身份,然后为 iLoveHTML 设置新的。';

  @override
  String get verifyWithDevice => '用设备锁验证';

  @override
  String get forgotWithCode => '使用恢复代码';

  @override
  String get forgotWithCodeHint => '设置锁时显示的 16 位代码。';

  @override
  String get recoveryCode => '恢复代码';

  @override
  String get useRecoveryCode => '使用代码';

  @override
  String get forgotNoWay =>
      '如果两者都没有,只能在系统设置中清除 iLoveHTML 的应用数据来移除锁。这会删除本设备上的所有项目和发布密钥。';

  @override
  String get pinDigitsOnly => '只能是数字';

  @override
  String pinLength(int min, int max) {
    return '$min 到 $max 位数字';
  }

  @override
  String passwordMinLength(int count) {
    return '至少 $count 个字符';
  }

  @override
  String get chooseNewSecret => '设置新的 PIN 码或密码';

  @override
  String get setUpAppLock => '设置应用锁';

  @override
  String get pin => 'PIN 码';

  @override
  String get newPin => '新 PIN 码';

  @override
  String get newPassword => '新密码';

  @override
  String get repeatPin => '再次输入 PIN 码';

  @override
  String get pinsDoNotMatch => '两次 PIN 码不一致';

  @override
  String get hintOptional => '提示(可选)';

  @override
  String get hintHelp => '显示在锁屏上帮助你回忆。拿到设备的任何人都能看到。';

  @override
  String get hintGivesAway => '提示中不能包含 PIN 码或密码';

  @override
  String get unlockWithFingerprint => '使用指纹或面容解锁';

  @override
  String get unlockWithFingerprintHint => 'PIN 码或密码仍可使用。';

  @override
  String get appLockNote => '此锁会对拿到本设备的人隐藏 iLoveHTML 及其项目。它不会加密项目文件。';

  @override
  String get saveAndContinue => '保存';

  @override
  String get recoveryCodeTitle => '保存你的恢复代码';

  @override
  String get recoveryCodeBody =>
      '如果忘记 PIN 码或密码,可以用此代码重新设置。它只显示这一次。请记下来或保存在安全的地方,不要只存在本设备上。';

  @override
  String get copy => '复制';

  @override
  String get iSavedTheCode => '我已保存代码';

  @override
  String get enterCurrentPin => '输入当前 PIN 码';

  @override
  String get enterCurrentPassword => '输入当前密码';

  @override
  String get wrongPin => 'PIN 码错误';

  @override
  String get wrongPassword => '密码错误';

  @override
  String get appLockOffHint => '关闭。打开 iLoveHTML 前要求输入 PIN 码、密码或指纹。';

  @override
  String get appLockOnPin => '已开启,使用 PIN 码';

  @override
  String get appLockOnPassword => '已开启,使用密码';

  @override
  String get lockAgainAfter => '离开应用后重新锁定';

  @override
  String get relockImmediately => '立即';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟后',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => '仅在 iLoveHTML 启动时';

  @override
  String get changePinOrHint => '更改 PIN 码、密码或提示';

  @override
  String get lockNow => '立即锁定';

  @override
  String get turnOffLock => '关闭锁';

  @override
  String get newUpdate => '新版本更新';

  @override
  String updateAvailable(String version) {
    return 'iLoveHTML $version 已发布';
  }

  @override
  String updateTitle(String version) {
    return '更新到 $version';
  }

  @override
  String youHaveVersion(String version) {
    return '你当前的版本是 $version。';
  }

  @override
  String get updateAndroidHint => 'APK 会在浏览器中下载。打开它即可覆盖安装当前版本;你的项目、密钥和设置都会保留。';

  @override
  String get updateWindowsHint =>
      'ZIP 会在浏览器中下载。关闭 iLoveHTML,解压后替换原来的 iLoveHTML 文件夹;你的项目、密钥和设置都会保留。';

  @override
  String get whatsNew => '新功能';

  @override
  String get releasePage => '发布页面';

  @override
  String get downloadUpdate => '下载';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkForUpdatesHint =>
      '大约每天两次向 GitHub 查询是否有更新的 iLoveHTML。不会发送任何关于你或你的项目的信息。';

  @override
  String get checkNow => '立即检查';

  @override
  String get checkingUpdates => '正在检查…';

  @override
  String get upToDate => '已是最新版本。';

  @override
  String get updateCheckFailed => '无法检查。是否已联网?';

  @override
  String get updateInAppHint =>
      'iLoveHTML 会下载并校验更新,然后 Android 会询问是否覆盖安装当前版本。你的项目、密钥和设置都会保留。';

  @override
  String get verifyingDownload => '正在校验文件…';

  @override
  String downloadingMb(String done) {
    return '正在下载… $done MB';
  }

  @override
  String downloadingOf(String done, String total) {
    return '正在下载… $done / $total MB';
  }

  @override
  String get installerOpened => 'Android 安装程序已打开。请在其中点按\"更新\"。如果已关闭,请点按\"安装\"。';

  @override
  String downloadFailed(String error) {
    return '下载失败:$error';
  }

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get tryAgain => '重试';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String unreadableProject(String name) {
    return '読み込めないプロジェクト: $name';
  }

  @override
  String get emptyHintWindows =>
      'HTML ファイル、ウェブサイトの ZIP、または公開中の https サイトを Android・Windows アプリにします。ビルドはこの端末で行われます。';

  @override
  String get emptyHintAndroid =>
      'HTML ファイル、ウェブサイトの ZIP、または公開中の https サイトを Android アプリにします。ビルドはこの端末で行われます。';

  @override
  String notBuiltYet(String version) {
    return 'v$version · 未ビルド';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · 前回のビルド $status $ago';
  }

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(int n) {
    return '$n 分前';
  }

  @override
  String hoursAgo(int n) {
    return '$n 時間前';
  }

  @override
  String daysAgo(int n) {
    return '$n 日前';
  }

  @override
  String chooseBackupFile(String ext) {
    return '$ext バックアップファイルを選んでください';
  }

  @override
  String restored(String name) {
    return '$name を復元しました';
  }

  @override
  String notUsableBackup(String message) {
    return '使用できないバックアップ: $message';
  }

  @override
  String restoreFailed(String error) {
    return '復元に失敗しました: $error';
  }

  @override
  String importFailed(String error) {
    return 'インポートに失敗しました: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のファイルをインポートしました',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return '開始ページ: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return '$count 個の HTML ページが見つかりました。開始ページは設定で変更できます。';
  }

  @override
  String filesMissing(int count) {
    return '参照されている $count 個のファイルが見つかりません:';
  }

  @override
  String andMore(int count) {
    return '…ほか $count 個';
  }

  @override
  String fileNotFound(String path) {
    return 'ファイルが見つかりません: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'アプリ外で開かれます: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'ページを読み込めませんでした: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'プレビューを開始できませんでした: $error';
  }

  @override
  String previewTitle(String name) {
    return 'プレビュー · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'サイトの応答は HTTP $code でした';
  }

  @override
  String redirected(int count) {
    return '$count 回リダイレクトされました — アプリはこのアドレスから始まります。';
  }

  @override
  String importedKey(String alias) {
    return '「$alias」をインポートしました';
  }

  @override
  String backupSavedAs(String alias) {
    return 'バックアップを $alias.jks として保存しました。パスワードは別に保管してください。';
  }

  @override
  String backupFailed(String error) {
    return 'バックアップに失敗しました: $error';
  }

  @override
  String deletedKey(String alias) {
    return '「$alias」をこの端末から削除しました';
  }

  @override
  String get releaseKeysIntroWindows =>
      'リリースビルドはこれらのいずれかの鍵で署名されます。Google Play と Android は、最初のリリースと同じ鍵で署名されたアップデートしか受け付けません。鍵はこの PC に保存され、パスワードは Windows アカウント用に暗号化されます。バックアップはパスワード保護された .jks ファイルで、スマホやパソコンの iLoveHTML、Gradle、keytool で使えます。';

  @override
  String get releaseKeysIntroAndroid =>
      'リリースビルドはこれらのいずれかの鍵で署名されます。Google Play と Android は、最初のリリースと同じ鍵で署名されたアップデートしか受け付けません。鍵はこのスマホに Android Keystore で暗号化して保存されます。バックアップはパスワード保護された .jks ファイルで、スマホやパソコンの iLoveHTML、Gradle、keytool で使えます。';

  @override
  String validUntilDate(String date) {
    return '$date まで有効';
  }

  @override
  String get atLeast8 => '8 文字以上';

  @override
  String deleteKeyBody(String alias) {
    return '「$alias」で署名したアプリは、この鍵でしか更新できません。バックアップがないと、二度と更新できなくなります。';
  }

  @override
  String typeToConfirm(String alias) {
    return '確認のため「$alias」と入力してください';
  }

  @override
  String backupSaved(String file) {
    return 'バックアップを保存しました: $file';
  }

  @override
  String shortcutExists(String page) {
    return '「$page」のショートカットはすでにあります';
  }

  @override
  String deleteProjectBody(String name) {
    return '「$name」とそのウェブサイトファイル、ビルド済み APK をこの端末から削除します。インストール済みのアプリには影響しません。';
  }

  @override
  String offlinePageShown(String page) {
    return 'サイトを読み込めないときは、あなたのページ「$page」が表示されます。「再試行」ボタンには https://appassets.androidplatform.net/html2apk/retry へリンクしてください。';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回ダウンロードされました。',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'ファイルを読み込めませんでした: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count 個のファイル、$size';
  }

  @override
  String checkFailed(String error) {
    return 'チェックに失敗しました: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return '最適化すると $count 個のファイルが小さくなり、$saved 節約できます ($before → $after)。APK 自体も圧縮されるため、CSS や JSON では APK での節約量は小さくなることが多いです。';
  }

  @override
  String example(String value) {
    return '例: $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'リリース鍵を読み込めませんでした: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'このアプリは最初に別の鍵 (SHA-256 $sha…) でリリースされました。そのリリースを入れたスマホは「$alias」で署名した APK に更新できず、Google Play もアップデートとして拒否します。';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return '発行元: $publisher · $date まで有効';
  }

  @override
  String replaceCertBody(String publisher) {
    return '「$publisher」が署名したインストーラーで入れたアプリは、同じ発行元名のインストーラーからしか更新できません。必要になりそうなら、先に現在の証明書をバックアップしてください。';
  }

  @override
  String passwordOf(String file) {
    return '$file のパスワード';
  }

  @override
  String savedFile(String file) {
    return '$file を保存しました';
  }

  @override
  String saveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get cannotBuildYet => 'まだビルドできません:';

  @override
  String get shareFilesHint =>
      'ファイル付きの navigator.share() で画像や PDF を他のアプリに送れます。Android 10 以降では共有した画像はギャラリーにも保存されます。';

  @override
  String get projects => 'プロジェクト';

  @override
  String get restoreBackup => 'バックアップを復元';

  @override
  String get settings => '設定';

  @override
  String get newApp => '新しいアプリ';

  @override
  String get htmlFiles => 'HTML ファイル';

  @override
  String get htmlFilesHint =>
      '.html ページを選び、CSS、JavaScript、画像が別ファイルならそれも選びます。オフラインで動作します。';

  @override
  String get websiteZip => 'ウェブサイト ZIP';

  @override
  String get websiteZipHint => 'ウェブサイトのフォルダー全体を ZIP にしたもの。オフラインで動作します。';

  @override
  String get websiteUrl => 'ウェブサイト URL';

  @override
  String get websiteUrlHint => '公開中の https サイトを包みます。インターネット接続が必要です。';

  @override
  String get noProjectsYet => 'プロジェクトはまだありません';

  @override
  String get building => 'ビルド中…';

  @override
  String get selectHtmlFile =>
      '.html ファイルを 1 つ以上選び、使っている CSS、JavaScript、画像も選んでください。';

  @override
  String get defaultAppName => 'マイアプリ';

  @override
  String get appName => 'アプリ名';

  @override
  String get enterName => '名前を入力してください';

  @override
  String get packageId => 'パッケージ ID';

  @override
  String get packageIdHelp => '端末と Play で一意の ID。例: com.yourname.app';

  @override
  String get cancel => 'キャンセル';

  @override
  String get importButton => 'インポート';

  @override
  String get noMissingFiles => '不足しているファイルはありません';

  @override
  String get openProject => 'プロジェクトを開く';

  @override
  String get noConsoleMessages => 'コンソールのメッセージや問題はありません';

  @override
  String get viewport => '表示サイズ';

  @override
  String get consoleAndIssues => 'コンソールと問題';

  @override
  String get checkWebsite => 'サイトを確認';

  @override
  String get websiteReachable => 'サイトに接続できます';

  @override
  String get liveSiteNote =>
      'このアプリはサイトをライブで表示するため、インターネット接続が必要です。オフラインでは動作しません。';

  @override
  String get create => '作成';

  @override
  String get backUpKeyNow => '今すぐこの鍵をバックアップ';

  @override
  String get backUpKeyBody =>
      'アプリのアップデートは毎回同じ鍵で署名する必要があります。この端末をなくしたり iLoveHTML をアンインストールしたりすると、バックアップがない限り鍵は失われます。\n\n.jks ファイルを安全な場所 (この端末以外にも) に保存し、パスワードは別に保管してください。';

  @override
  String get later => '後で';

  @override
  String get saveBackup => 'バックアップを保存';

  @override
  String get certificate => '証明書';

  @override
  String get sha256Fingerprint => 'SHA-256 フィンガープリント';

  @override
  String get sha1Fingerprint => 'SHA-1 フィンガープリント';

  @override
  String get validUntil => '有効期限';

  @override
  String get added => '追加日';

  @override
  String get saveBackupJks => 'バックアップを保存 (.jks)';

  @override
  String get delete => '削除';

  @override
  String get releaseKeys => 'リリース鍵';

  @override
  String get createKey => '鍵を作成';

  @override
  String get importKeystoreFile => '.jks / .keystore / .p12 をインポート';

  @override
  String get noReleaseKeys => 'リリース鍵はまだありません';

  @override
  String get createReleaseKey => 'リリース鍵を作成';

  @override
  String get keyAlias => '鍵のエイリアス';

  @override
  String get keyAliasHelp => '英字、数字、ドット、ハイフン、アンダースコア';

  @override
  String get publisherNameField => 'あなたの名前またはアプリの発行元';

  @override
  String get required => '必須';

  @override
  String get organizationOptional => '組織 (任意)';

  @override
  String get countryCodeOptional => '国コード (任意)';

  @override
  String get password => 'パスワード';

  @override
  String get passwordHelp => 'キーストアと鍵の両方に使われます';

  @override
  String get repeatPassword => 'パスワード (確認)';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get createKeyNote =>
      'RSA 2048 ビット、有効期間 30 年。パソコンでバックアップを使うときにこのパスワードが必要です。';

  @override
  String get noPrivateKeys => 'このファイルには秘密鍵がありません';

  @override
  String get importKeystore => 'キーストアをインポート';

  @override
  String get keystorePassword => 'キーストアのパスワード';

  @override
  String get keyPassword => '鍵のパスワード';

  @override
  String get keyPasswordHelp => 'キーストアのパスワードと同じなら空欄のまま';

  @override
  String get importKeystoreNote =>
      'iLoveHTML はキーストアのパスワードで保護したコピーを保持します。元のファイルは変更されません。';

  @override
  String get open => '開く';

  @override
  String get deleteReleaseKey => 'リリース鍵を削除しますか?';

  @override
  String get deleteKey => '鍵を削除';

  @override
  String get projectNotFound => 'プロジェクトが見つかりません';

  @override
  String get backUpProject => 'プロジェクトをバックアップ';

  @override
  String get preview => 'プレビュー';

  @override
  String get build => 'ビルド';

  @override
  String get previewInBrowser => 'ブラウザーでプレビュー';

  @override
  String get liveSiteOpened => '公開中のサイトを既定のブラウザーで開きました。';

  @override
  String get servedFromPc =>
      'このウィンドウが開いている間だけ、この PC から配信されます。スマホ版アプリにはコンソールとリンクチェックがあります。ここではブラウザーの開発者ツール (F12) を使ってください。';

  @override
  String get missingFiles => '不足しているファイル:';

  @override
  String get close => '閉じる';

  @override
  String get stopPreview => 'プレビューを停止';

  @override
  String get settingsSaved => '設定を保存しました';

  @override
  String get iconUpdated => 'アイコンを更新しました';

  @override
  String get splashUpdated => 'スプラッシュ画像を更新しました';

  @override
  String get offlinePageAdded => 'オフラインページを追加しました';

  @override
  String get deleteProjectQ => 'プロジェクトを削除しますか?';

  @override
  String get save => '保存';

  @override
  String get sectionApp => 'アプリ';

  @override
  String get sectionContent => 'コンテンツ';

  @override
  String get sectionShortcuts => 'ショートカット';

  @override
  String get sectionAppSize => 'アプリのサイズ';

  @override
  String get sectionAppearance => '外観';

  @override
  String get sectionDevices => 'デバイス';

  @override
  String get sectionSecurity => 'セキュリティ';

  @override
  String get sectionOffline => 'オフライン';

  @override
  String get sectionDanger => '危険な操作';

  @override
  String get versionName => 'バージョン名';

  @override
  String get versionCode => 'バージョンコード';

  @override
  String get defaultIcon => '既定のアイコン';

  @override
  String get customIcon => 'カスタムアイコン';

  @override
  String get chooseImage => '画像を選択';

  @override
  String get iconHint =>
      'PNG、JPEG、WebP、GIF、BMP、SVG。48 px 以上、512 × 512 推奨。正方形でない画像は中央に配置されます。';

  @override
  String get startPage => '開始ページ';

  @override
  String get loadedLive => 'ライブで読み込みます。アプリにはインターネット接続が必要です。';

  @override
  String get otherSites => 'アプリ内で開くほかのサイト (任意)';

  @override
  String get otherSitesHelp => 'カンマ区切り。それ以外のサイトへのリンクはブラウザーで開きます。';

  @override
  String get bridgeSites => '共有、ファイルの保存、通知もできるサイト (任意)';

  @override
  String get bridgeSitesHelp =>
      'カンマ区切りで、上のリストから選びます。自分のサイトは常に使えます。ログインや支払いのサイトは入れないでください。';

  @override
  String bridgeSiteNotListed(String host) {
    return '「$host」は上のリストにありません';
  }

  @override
  String get orientation => '画面の向き';

  @override
  String get orientationAuto => '自動';

  @override
  String get portrait => '縦';

  @override
  String get landscape => '横';

  @override
  String get shortcutsHint => 'アプリのアイコンを長押しするとこれらのページが表示されます。';

  @override
  String get removeShortcut => 'ショートカットを削除';

  @override
  String get addShortcut => 'ショートカットを追加';

  @override
  String get optimizeFiles => 'ビルド時にファイルを最適化';

  @override
  String get optimizeFilesHint =>
      'アプリ内の CSS、JSON、PNG、大きな JPEG を小さくします。JPEG は品質 85% で保存し直されます。プロジェクトのファイルは変わりません。';

  @override
  String get sizeReport => 'サイズレポート';

  @override
  String get statusBarColour => 'ステータスバーの色';

  @override
  String get navBarColour => 'ナビゲーションバーの色';

  @override
  String get splashScreen => 'スプラッシュ画面';

  @override
  String get splashIconHint => '最初のページが読み込まれるまでアプリアイコンを表示します。';

  @override
  String get splashImageHint => '最初のページが読み込まれるまでスプラッシュ画像を表示します。';

  @override
  String get splashBackground => 'スプラッシュの背景';

  @override
  String get chooseSplash => 'スプラッシュ画像を選択';

  @override
  String get replaceSplash => 'スプラッシュ画像を変更';

  @override
  String get useAppIcon => 'アプリアイコンを使う';

  @override
  String get theme => 'テーマ';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get followPhone => 'スマホに合わせる';

  @override
  String get themeHint =>
      'prefers-color-scheme を設定し、ダークモード用 CSS のあるページを切り替えます。';

  @override
  String get fullscreen => '全画面';

  @override
  String get fullscreenHint => 'ステータスバーとナビゲーションバーを隠します。端からスワイプすると一時的に表示されます。';

  @override
  String get keepScreenOn => '画面をオンのままにする';

  @override
  String get keepScreenOnHint => 'アプリを開いている間、画面が消えません。';

  @override
  String get tvHint =>
      'アイコンと名前で作ったバナー付きで、テレビのホーム画面にアプリを表示します。リモコンの矢印キーでリンクやボタン間を移動し、OK で開きます。';

  @override
  String get rotateTablets => 'タブレットでは自由に回転';

  @override
  String get rotateTabletsHint =>
      'スマホが上で選んだ向きのままでも、タブレットや折りたたみ端末はどの向きにも回転できます。Android 16 以降は大画面で常に許可されます。';

  @override
  String get desktopLayout => 'タブレットとテレビでデスクトップ表示';

  @override
  String get desktopLayoutHint => 'サイトにスマホ向けではなくパソコン向けのレイアウトを要求します。';

  @override
  String get appLock => 'アプリロック';

  @override
  String get appLockHint =>
      'アプリを開いたときとバックグラウンドで 30 秒経った後に、指紋・顔・画面ロックを求めます。画面ロックのないスマホでは、案内を表示してアプリを開きます。';

  @override
  String get javascriptHint => 'ほとんどのサイトで必要です。静的なページならオフにできます。';

  @override
  String get localStorage => 'ローカルストレージ';

  @override
  String get internetAccess => 'インターネットアクセス';

  @override
  String get internetAccessHint =>
      'INTERNET 権限を追加します。CDN、API、ウェブから読み込むフォントに必要です。';

  @override
  String get openOtherSites => 'ほかのサイトはブラウザーで開く';

  @override
  String get openOtherSitesHint => 'オフにすると、ほかのサイトへのリンクは何もしません。';

  @override
  String get pullToRefresh => '引っ張って更新';

  @override
  String get pullToRefreshHint => 'ページの一番上で下にスワイプすると再読み込みします。エラー後の再試行にも使えます。';

  @override
  String get notifications => '通知';

  @override
  String get notificationsHint =>
      'アプリを開いている間、ページはウェブの Notification API で Android の通知を表示できます。Android 13 以降は先にユーザーに確認します。プッシュ通知はありません。';

  @override
  String get backButton => '戻るボタン';

  @override
  String get backHistory => '前のページに戻り、最後にアプリを閉じる';

  @override
  String get backTwice => '前のページに戻り、最後は 2 回押して閉じる';

  @override
  String get backConfirm => '前のページに戻り、閉じる前に確認する';

  @override
  String get backHome => '開始ページに戻ってから閉じる';

  @override
  String get fileUploads => 'ファイルのアップロード';

  @override
  String get fileUploadsHint =>
      'ファイル入力で Android のファイル選択画面を開きます。ファイルは毎回ユーザーが選びます。';

  @override
  String get share => '共有';

  @override
  String get shareHint => 'navigator.share でテキストやリンク用の Android 共有シートを開きます。';

  @override
  String get downloads => 'ダウンロード';

  @override
  String get downloadsHint => 'ダウンロードリンクや生成したファイルは Download フォルダーに保存されます。';

  @override
  String get shareFiles => '画像と PDF を共有';

  @override
  String get galleryFolder => 'ギャラリーのフォルダー (任意)';

  @override
  String get galleryFolderExample => '例: マイフォト';

  @override
  String get galleryFolderHelp =>
      '共有・ダウンロードした画像の保存先 Pictures/<フォルダー>。空欄なら共有はアプリ名、ダウンロードは Download。';

  @override
  String get shareToApp => 'アプリへ直接共有 (任意)';

  @override
  String get shareToAppHelp => 'インストールされていれば、共有シートの代わりにファイル共有を直接開くパッケージ。';

  @override
  String get usePackageName => 'com.whatsapp のようなパッケージ名を使ってください';

  @override
  String get offlineBuiltIn => 'サイトを読み込めないときは、内蔵の「ページを表示できません」画面が表示されます。';

  @override
  String get chooseOfflinePage => 'オフラインページを選択 (.html)';

  @override
  String get replaceOfflinePage => 'オフラインページを変更';

  @override
  String get useBuiltInPage => '内蔵ページを使う';

  @override
  String get userAgentSuffix => 'ユーザーエージェントの接尾辞 (任意)';

  @override
  String get atMost200 => '200 文字まで';

  @override
  String get deleteProject => 'プロジェクトを削除';

  @override
  String get useColourLike => '#1A73E8 のような色を使ってください';

  @override
  String get noNetwork => 'このパソコンは Wi-Fi にもイーサネットにも接続されていません。';

  @override
  String get installOnPhone => 'スマホにインストール';

  @override
  String get installSteps =>
      '1. スマホをこのパソコンと同じ Wi-Fi に接続します。\n2. スマホのカメラでコードを読み取り、リンクを開きます。\n3. ダウンロードしたファイルを開きます。Android に聞かれたら、ブラウザーからのインストールを許可してください。';

  @override
  String get linkStopped => 'リンクは停止しました。';

  @override
  String get networkAddress => 'ネットワークアドレス';

  @override
  String get linkWorks10Min => 'このウィンドウが開いている間、リンクは 10 分間使えます。';

  @override
  String get trustedNetworkOnly =>
      '信頼できるネットワークでのみ使ってください。Windows が iLoveHTML のファイアウォール通過を確認したら、プライベートネットワークで許可してください。';

  @override
  String get startAgain => 'もう一度開始';

  @override
  String get done => '完了';

  @override
  String get kindPages => 'ページ';

  @override
  String get kindImages => '画像';

  @override
  String get kindFonts => 'フォント';

  @override
  String get kindMedia => '音声と動画';

  @override
  String get kindData => 'データ';

  @override
  String get kindOther => 'その他';

  @override
  String get largestFiles => '大きいファイル';

  @override
  String get advice => 'アドバイス';

  @override
  String get checkOptimizing => '最適化で減るサイズを確認';

  @override
  String get name => '名前';

  @override
  String get exampleCart => '例: カート';

  @override
  String get choosePage => 'ページを選んでください';

  @override
  String get page => 'ページ';

  @override
  String get add => '追加';

  @override
  String get differentKey => '異なるリリース鍵';

  @override
  String get buildAnyway => 'それでもビルド';

  @override
  String get windowsExe => 'Windows アプリ (.exe)';

  @override
  String get exeDescription =>
      'Microsoft Edge WebView2 (Windows 11 と最新の Windows 10 に搭載) で、このサイトを専用ウィンドウで開く単一の .exe ファイル。コード署名されていないため、「Windows によって PC が保護されました」と表示されることがあり、詳細情報 → 実行 を選ぶ必要があります。';

  @override
  String get devTools => '開発者ツール (テスト用)';

  @override
  String get devToolsHint => 'アプリ内で F12 と検証が使えます。配布するバージョンではオフにしてください';

  @override
  String get buildExe => '.exe をビルド';

  @override
  String get windowsMsix => 'Windows インストーラー (.msix)';

  @override
  String get msixDescription =>
      'ほかの Windows ソフトと同じようにインストールします: スタートメニューへの登録、きれいなアンインストール、上位バージョン配布時の更新。インストーラーはすべて証明書で署名されます。';

  @override
  String get needsWindowsSdk =>
      'Windows SDK が必要です。次のコマンドでインストールします:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate => '証明書はまだありません。自分のコード署名証明書を使うか、試用にテスト証明書を作成してください。';

  @override
  String get testCertNote =>
      'テスト証明書: 一度信頼してもらった後でなければ、Windows はアプリをインストールしません。インストーラーと一緒に .cer ファイルを渡し、ダブルクリック → 証明書のインストール → ローカル コンピューター → 「信頼されたユーザー」と進んでもらいます。認証局で購入した証明書ならこの手順は不要です。';

  @override
  String get createTestCert => 'テスト証明書を作成';

  @override
  String get useMyPfx => '自分の .pfx を使う';

  @override
  String get savedCertificate => '証明書を保存しました';

  @override
  String get saveCer => '.cer を保存';

  @override
  String get buildInstaller => 'インストーラーをビルド';

  @override
  String get replaceCertQ => '証明書を置き換えますか?';

  @override
  String get replace => '置き換え';

  @override
  String get publisherName => '発行元名';

  @override
  String get publisherNameHelp => 'アプリのインストール時に発行元として表示されます。';

  @override
  String get testCertCreated => 'テスト証明書を作成しました';

  @override
  String get useMyCertificate => '自分の証明書を使う';

  @override
  String get certificateAdded => '証明書を追加しました';

  @override
  String get ok => 'OK';

  @override
  String get allowUnknownApps =>
      '開いた画面で iLoveHTML に「不明なアプリのインストール」を許可し、もう一度インストールをタップしてください。';

  @override
  String get debug => 'デバッグ';

  @override
  String get release => 'リリース';

  @override
  String get debugHint => 'テスト用。この端末に保存されたデバッグ鍵で署名されます。公開には使えません。';

  @override
  String get releaseHint =>
      '公開用。リリース鍵で署名されます。以後のアップデートは同じ鍵と、より大きいバージョンコードが必要です。';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      '.aab は Google Play Console にアップロードします。直接インストールはできないので、スマホでのテストには APK を使ってください。';

  @override
  String get createOrImportKey => 'リリース鍵を作成またはインポート';

  @override
  String get releaseKey => 'リリース鍵';

  @override
  String get manageKeys => '鍵を管理';

  @override
  String get buildDebugApk => 'デバッグ APK をビルド';

  @override
  String get buildAppBundle => 'App Bundle をビルド';

  @override
  String get buildReleaseApk => 'リリース APK をビルド';

  @override
  String get buildingUnavailable => 'このプラットフォームではまだビルドできません。';

  @override
  String get buildFailed => 'ビルドに失敗しました';

  @override
  String get saveAs => '名前を付けて保存…';

  @override
  String get showInFolder => 'フォルダーに表示';

  @override
  String get install => 'インストール';

  @override
  String get saveToDevice => '端末に保存';

  @override
  String get buildLog => 'ビルドログ';

  @override
  String get history => '履歴';

  @override
  String get twoLetters => '英字 2 文字';

  @override
  String invalidHost(String host) {
    return '無効なホスト「$host」';
  }

  @override
  String get thisDevice => 'この端末';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ビルド中… ログ $count 行',
      zero: 'ビルド中…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'システム';

  @override
  String get accentColour => 'アクセントカラー';

  @override
  String get accentOrange => 'オレンジ';

  @override
  String get accentGreen => 'ターミナルグリーン';

  @override
  String get accentCyan => 'シアン';

  @override
  String get accentViolet => 'バイオレット';

  @override
  String get accentPink => 'ピンク';

  @override
  String get animations => 'アニメーション';

  @override
  String get animationsHint => 'ASCII スプラッシュ、ビルドアニメーション、画面遷移';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システムの既定';

  @override
  String get signing => '署名';

  @override
  String get releaseKeysSubtitle => 'リリースに署名する鍵の作成・インポート・バックアップ';

  @override
  String get storage => 'ストレージ';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のプロジェクト · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'ビルドエンジン';

  @override
  String get notAvailablePlatform => 'このプラットフォームではまだ使えません';

  @override
  String get gradleReady => 'この PC の Gradle (準備完了)';

  @override
  String get gradleNotReady => 'この PC の Gradle: 準備ができていません';

  @override
  String get buildsRunOnPc => 'ビルドはすべてこの PC で行われます。ファイルはアップロードされません。';

  @override
  String get onDeviceReady => '端末上での組み立て (準備完了)';

  @override
  String get onDeviceMissing => '端末上での組み立て: ベース APK がありません';

  @override
  String get buildsRunOnDevice => 'ビルドはすべてこの端末で行われます。ファイルはアップロードされません。';

  @override
  String get about => 'このアプリについて';

  @override
  String get howToUse => '使い方';

  @override
  String get howToUseSubtitle => '5 つのステップでウェブサイトからアプリへ';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get version => 'バージョン';

  @override
  String get versionCopied => 'バージョンをコピーしました';

  @override
  String get credit => 'クレジット';

  @override
  String madeBy(String author) {
    return '$author が <3 を込めて制作';
  }

  @override
  String get supportHint =>
      'iLoveHTML は無料で、広告もトラッキングもありません。時間の節約になったら、開発を支援していただけます。';

  @override
  String get buyMeACoffee => 'コーヒーをおごる';

  @override
  String couldNotOpenLink(String url) {
    return '$url を開けませんでした';
  }

  @override
  String lastUpdated(String date) {
    return '最終更新日: $date';
  }

  @override
  String get howToStep1Title => 'プロジェクトを作る';

  @override
  String get howToStep1Body =>
      '「新しいアプリ」をタップし、HTML ファイル、ウェブサイト ZIP、または公開中の https サイトの URL を選びます。ファイルと ZIP はオフラインで動作し、URL にはインターネットが必要です。';

  @override
  String get howToStep2Title => 'アプリに名前を付ける';

  @override
  String get howToStep2Body =>
      'アプリ名と、com.yourname.app のような一意のパッケージ ID を入力します。パッケージ ID はアップデートのたびに同じものを使ってください。';

  @override
  String get howToStep3Title => 'カスタマイズする';

  @override
  String get howToStep3Body =>
      '設定タブで開始ページ、アイコン、スプラッシュ画面、色、画面の向き、ショートカット、WebView の機能を選びます。終わったら保存をタップします。先にプレビューで試せます。';

  @override
  String get howToStep4Title => 'ビルドする';

  @override
  String get howToStep4Body =>
      'ビルドタブで、テストならデバッグ、公開ならリリースを選びます。リリースビルドにはリリース鍵が必要です。作成してバックアップしてください。Windows では .exe や .msix インストーラーもビルドできます。';

  @override
  String get howToStep5Title => 'インストール・共有する';

  @override
  String get howToStep5Body =>
      'APK をこのスマホにインストールしたり、共有・保存したりできます。PC では「スマホにインストール」で Wi-Fi 経由で送れます。App Bundle (.aab) は Google Play Console にアップロードします。';

  @override
  String get howToTipsTitle => 'ヒント';

  @override
  String get howToTips =>
      '• アップデートは毎回同じパッケージ ID とリリース鍵、より大きいバージョンコードが必要です。\n• リリース鍵とプロジェクトはバックアップしてください。失った鍵は誰にも復元できません。\n• サイズレポートでアプリを小さくできます。\n• 「プロジェクトをバックアップ」(プロジェクト画面の上部) で、後で復元できるコピーを残せます。';

  @override
  String get termsBody =>
      '本利用規約は、1elevenop が制作したアプリ iLoveHTML (以下「本アプリ」) に適用されます。本アプリを使用することで、本規約に同意したものとみなされます。\n\n## 本アプリの機能\n\niLoveHTML は、HTML ファイル、ウェブサイトの ZIP、ウェブアドレスを Android・Windows アプリに変換します。ビルドはご自身の端末で実行されます。\n\n## あなたのコンテンツ\n\n作成したウェブサイト、ファイル、アイコン、アプリに関するすべての権利はあなたに帰属します。そのコンテンツを使用する権利があること、またビルド・公開するアプリについては、法令や Google Play などのストアの規約の遵守を含め、あなたが責任を負います。\n\n## 禁止事項\n\n違法、有害、欺瞞的なソフトウェアや、マルウェア、他ブランドになりすますアプリなど他者の権利を侵害するソフトウェアの作成に本アプリを使用しないでください。\n\n## リリース鍵\n\nリリース鍵はご自身の端末にのみ保存されます。バックアップとパスワードの管理はあなたの責任です。失った鍵は復元できず、その鍵で署名したアプリは以後更新できなくなります。\n\n## 無保証\n\n本アプリは無料で「現状のまま」提供され、いかなる保証もありません。法令で認められる範囲で、作者は本アプリの使用によるデータ、鍵、収入の損失その他の損害について責任を負いません。\n\n## 変更\n\n本規約は本アプリの新しいバージョンとともに更新されることがあります。上の日付が最終更新日です。引き続き本アプリを使用した場合、更新後の規約に同意したものとみなされます。\n\n## お問い合わせ\n\nご質問は、1elevenop の iLoveHTML GitHub プロジェクトで Issue を作成してください。';

  @override
  String get privacyBody =>
      'iLoveHTML は、あなたの端末上で動作するように作られています。本ポリシーでは、それがあなたのデータにとって何を意味するかを説明します。\n\n## 収集するデータ\n\nありません。本アプリにはアカウント、分析、広告、トラッキングは一切ありません。作者があなたやあなたのプロジェクトに関するデータを受け取ることはありません。\n\n## 端末に保存されるデータ\n\nプロジェクト、ウェブサイトファイル、アイコン、ビルド結果、設定は、端末内の本アプリ専用の領域に保存されます。リリース鍵も端末内に保存されます。Android では Android Keystore で暗号化され、Windows ではパスワードが Windows アカウント用に暗号化されます。本アプリをアンインストールするとこれらのデータは削除されるため、バックアップを取ってください。\n\n## ネットワークの利用\n\n本アプリがインターネットに接続するのは、あなたが求めたときだけです: 入力したウェブサイト URL の確認やプレビュー、Buy Me a Coffee などのリンクをブラウザーで開くとき、そして Windows では Gradle がビルドツールをダウンロードするときです。「スマホにインストール」機能は、そのウィンドウが開いている間だけ、ローカルネットワーク上でファイルを 10 分間配信します。\n\n## アップデートの確認\n\n「アップデートを確認」がオン (既定) の場合、新しいバージョンが出たら知らせるため、iLoveHTML は 1 日に 2 回ほど GitHub (api.github.com) に最新の iLoveHTML リリースを問い合わせます。この通信にはアカウント、識別子、プロジェクトの情報は含まれません。一般的なウェブサイトと同様に、GitHub には IP アドレスが見えます。設定 → このアプリについて でオフにできます。\n\n## あなたが作るアプリ\n\niLoveHTML で作ったアプリには、iLoveHTML によるトラッキングは含まれません。アプリが何を収集するかは組み込んだウェブサイト次第であり、そのプライバシーポリシーについてはあなたが責任を負います。\n\n## お子さま\n\n本アプリは、お子さまを含め、誰からも意図的にデータを収集しません。\n\n## 変更とお問い合わせ\n\n本ポリシーは本アプリの新しいバージョンとともに更新されることがあります。上の日付が最終更新日です。ご質問は、1elevenop の iLoveHTML GitHub プロジェクトで Issue を作成してください。';

  @override
  String get replaceWebsite => 'ウェブサイトのファイルを置き換え';

  @override
  String get replaceWebsiteHint =>
      '新しい ZIP や HTML ファイルに差し替えます。名前、パッケージ ID、アイコン、設定、鍵はそのままです。';

  @override
  String get replaceWithZipHint => '新しいウェブサイトフォルダーの ZIP';

  @override
  String get replaceWithFilesHint => '新しい .html ページと CSS、JavaScript、画像';

  @override
  String get replaceWebsiteQ => 'ウェブサイトを置き換えますか?';

  @override
  String replaceWebsiteBody(String name) {
    return '「$name」のウェブサイトのファイルを、次に選ぶファイルですべて置き換えます。アプリ名、パッケージ ID、バージョン、アイコン、設定、リリース鍵、ビルド履歴はそのままです。更新したアプリはもう一度ビルドすると作られます。';
  }

  @override
  String replaceFailed(String error) {
    return 'ウェブサイトを置き換えられませんでした: $error';
  }

  @override
  String get websiteReplaced => 'ウェブサイトを置き換えました';

  @override
  String startPageChanged(String page) {
    return '「$page」が新しいファイルにないため、開始ページが変わりました。';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'ページがなくなったためショートカットを削除しました: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      '更新したアプリはもう一度ビルドすると作られます。インストール済みのアプリを更新するには、先にバージョンコードを上げてください。';

  @override
  String get unlockReason => 'iLoveHTML のロックを解除';

  @override
  String get resetReason => 'iLoveHTML のロックをリセットするため本人確認をします';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '違います。あと $count 回で待ち時間になります。',
      zero: '違います。しばらく待ってから再試行してください。',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return '間違いが多すぎます。$seconds 秒後に再試行してください。';
  }

  @override
  String get enterPin => 'PIN を入力してください';

  @override
  String get enterPassword => 'パスワードを入力してください';

  @override
  String get showPassword => '表示';

  @override
  String get hidePassword => '隠す';

  @override
  String hintIs(String hint) {
    return 'ヒント: $hint';
  }

  @override
  String get showHint => 'ヒントを表示';

  @override
  String get deleteDigit => '削除';

  @override
  String get unlock => 'ロック解除';

  @override
  String get useFingerprint => '指紋または顔を使う';

  @override
  String get forgotPin => 'PIN を忘れた場合';

  @override
  String get forgotPassword => 'パスワードを忘れた場合';

  @override
  String digitsEntered(int count) {
    return '$count 桁入力済み';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'コードが違います。あと $count 回試せます。',
      zero: 'コードが違います。しばらく待ってから再試行してください。',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'この端末のロックを使う';

  @override
  String get forgotWithDeviceHint =>
      '指紋、顔、またはスマホの画面ロック (PIN、パターン、パスワード) で本人確認し、iLoveHTML 用に新しいものを設定します。';

  @override
  String get verifyWithDevice => '端末のロックで確認';

  @override
  String get forgotWithCode => '回復コードを使う';

  @override
  String get forgotWithCodeHint => 'ロックを設定したときに表示された 16 文字のコード。';

  @override
  String get recoveryCode => '回復コード';

  @override
  String get useRecoveryCode => 'コードを使う';

  @override
  String get forgotNoWay =>
      'どちらもない場合、ロックを解除するにはシステム設定で iLoveHTML のアプリデータを消去するしかありません。この端末のプロジェクトとリリース鍵はすべて削除されます。';

  @override
  String get pinDigitsOnly => '数字のみ';

  @override
  String pinLength(int min, int max) {
    return '$min〜$max 桁';
  }

  @override
  String passwordMinLength(int count) {
    return '$count 文字以上';
  }

  @override
  String get chooseNewSecret => '新しい PIN またはパスワード';

  @override
  String get setUpAppLock => 'アプリロックを設定';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => '新しい PIN';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get repeatPin => 'PIN (確認)';

  @override
  String get pinsDoNotMatch => 'PIN が一致しません';

  @override
  String get hintOptional => 'ヒント (任意)';

  @override
  String get hintHelp => '思い出せるようロック画面に表示されます。端末を持っている人なら誰でも読めます。';

  @override
  String get hintGivesAway => 'ヒントに PIN やパスワードを含めないでください';

  @override
  String get unlockWithFingerprint => '指紋または顔でロック解除';

  @override
  String get unlockWithFingerprintHint => 'PIN やパスワードも引き続き使えます。';

  @override
  String get appLockNote =>
      'ロックは、この端末を手にした人から iLoveHTML とプロジェクトを隠します。プロジェクトのファイル自体は暗号化されません。';

  @override
  String get saveAndContinue => '保存';

  @override
  String get recoveryCodeTitle => '回復コードを保存してください';

  @override
  String get recoveryCodeBody =>
      'PIN やパスワードを忘れたとき、このコードで新しく設定できます。表示されるのは今だけです。書き留めるか、この端末以外の安全な場所に保管してください。';

  @override
  String get copy => 'コピー';

  @override
  String get iSavedTheCode => 'コードを保存しました';

  @override
  String get enterCurrentPin => '現在の PIN を入力';

  @override
  String get enterCurrentPassword => '現在のパスワードを入力';

  @override
  String get wrongPin => 'PIN が違います';

  @override
  String get wrongPassword => 'パスワードが違います';

  @override
  String get appLockOffHint => 'オフ。iLoveHTML を開く前に PIN、パスワード、指紋を求めます。';

  @override
  String get appLockOnPin => 'オン (PIN)';

  @override
  String get appLockOnPassword => 'オン (パスワード)';

  @override
  String get lockAgainAfter => 'アプリを離れた後に再ロック';

  @override
  String get relockImmediately => 'すぐに';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分後',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'iLoveHTML の起動時のみ';

  @override
  String get changePinOrHint => 'PIN・パスワード・ヒントを変更';

  @override
  String get lockNow => '今すぐロック';

  @override
  String get turnOffLock => 'ロックをオフ';

  @override
  String get newUpdate => '新しいアップデート';

  @override
  String updateAvailable(String version) {
    return 'iLoveHTML $version が利用できます';
  }

  @override
  String updateTitle(String version) {
    return '$version にアップデート';
  }

  @override
  String youHaveVersion(String version) {
    return '現在のバージョンは $version です。';
  }

  @override
  String get updateAndroidHint =>
      'APK はブラウザーでダウンロードされます。開くとこのバージョンに上書きインストールされ、プロジェクト・鍵・設定はそのまま残ります。';

  @override
  String get updateWindowsHint =>
      'ZIP はブラウザーでダウンロードされます。iLoveHTML を閉じて展開し、iLoveHTML のフォルダーを置き換えてください。プロジェクト・鍵・設定はそのまま残ります。';

  @override
  String get whatsNew => '新機能';

  @override
  String get releasePage => 'リリースページ';

  @override
  String get downloadUpdate => 'ダウンロード';

  @override
  String get checkForUpdates => 'アップデートを確認';

  @override
  String get checkForUpdatesHint =>
      '1 日に 2 回ほど、新しい iLoveHTML が出ていないか GitHub に確認します。あなたやプロジェクトの情報は送信されません。';

  @override
  String get checkNow => '今すぐ確認';

  @override
  String get checkingUpdates => '確認中…';

  @override
  String get upToDate => '最新バージョンです。';

  @override
  String get updateCheckFailed => '確認できませんでした。オンラインですか?';

  @override
  String get updateInAppHint =>
      'iLoveHTML がアップデートをダウンロードして確認し、Android がこのバージョンへの上書きインストールを確認します。プロジェクト・鍵・設定はそのまま残ります。';

  @override
  String get verifyingDownload => 'ファイルを確認中…';

  @override
  String downloadingMb(String done) {
    return 'ダウンロード中… $done MB';
  }

  @override
  String downloadingOf(String done, String total) {
    return 'ダウンロード中… $done / $total MB';
  }

  @override
  String get installerOpened =>
      'Android のインストーラーが開いています。そこで「更新」をタップしてください。閉じてしまった場合は「インストール」をタップします。';

  @override
  String downloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get openInBrowser => 'ブラウザーで開く';

  @override
  String get tryAgain => '再試行';
}

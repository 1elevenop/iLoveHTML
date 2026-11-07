// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String unreadableProject(String name) {
    return '읽을 수 없는 프로젝트: $name';
  }

  @override
  String get emptyHintWindows =>
      'HTML 파일, 웹사이트 ZIP 또는 실시간 https 웹사이트를 Android 또는 Windows 앱으로 만드세요. 빌드는 이 기기에서 이루어집니다.';

  @override
  String get emptyHintAndroid =>
      'HTML 파일, 웹사이트 ZIP 또는 실시간 https 웹사이트를 Android 앱으로 만드세요. 빌드는 이 기기에서 이루어집니다.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · 아직 빌드하지 않음';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · 마지막 빌드 $status $ago';
  }

  @override
  String get justNow => '방금';

  @override
  String minutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String hoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String daysAgo(int n) {
    return '$n일 전';
  }

  @override
  String chooseBackupFile(String ext) {
    return '$ext 백업 파일을 선택하세요';
  }

  @override
  String restored(String name) {
    return '$name 복원됨';
  }

  @override
  String notUsableBackup(String message) {
    return '사용할 수 없는 백업: $message';
  }

  @override
  String restoreFailed(String error) {
    return '복원 실패: $error';
  }

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개를 가져왔습니다',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return '시작 페이지: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return 'HTML 페이지 $count개를 찾았습니다. 시작 페이지는 설정에서 바꿀 수 있습니다.';
  }

  @override
  String filesMissing(int count) {
    return '참조된 파일 $count개가 없습니다:';
  }

  @override
  String andMore(int count) {
    return '…외 $count개';
  }

  @override
  String fileNotFound(String path) {
    return '파일을 찾을 수 없음: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return '앱 밖에서 열림: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return '페이지를 불러오지 못함: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return '미리보기를 시작할 수 없습니다: $error';
  }

  @override
  String previewTitle(String name) {
    return '미리보기 · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return '웹사이트가 HTTP $code로 응답했습니다';
  }

  @override
  String redirected(int count) {
    return '$count번 리디렉션됨 — 앱은 이 주소에서 시작합니다.';
  }

  @override
  String importedKey(String alias) {
    return '\"$alias\" 가져옴';
  }

  @override
  String backupSavedAs(String alias) {
    return '백업을 $alias.jks로 저장했습니다. 비밀번호는 따로 보관하세요.';
  }

  @override
  String backupFailed(String error) {
    return '백업 실패: $error';
  }

  @override
  String deletedKey(String alias) {
    return '이 기기에서 \"$alias\" 삭제됨';
  }

  @override
  String get releaseKeysIntroWindows =>
      '릴리스 빌드는 이 키 중 하나로 서명됩니다. Google Play와 Android는 첫 릴리스와 같은 키로 서명된 업데이트만 받습니다. 키는 이 PC에 보관되며 비밀번호는 Windows 계정용으로 암호화됩니다. 백업은 비밀번호로 보호된 .jks 파일로, 휴대폰이나 컴퓨터의 iLoveHTML, Gradle, keytool에서 사용할 수 있습니다.';

  @override
  String get releaseKeysIntroAndroid =>
      '릴리스 빌드는 이 키 중 하나로 서명됩니다. Google Play와 Android는 첫 릴리스와 같은 키로 서명된 업데이트만 받습니다. 키는 이 휴대폰에 Android Keystore로 암호화되어 보관됩니다. 백업은 비밀번호로 보호된 .jks 파일로, 휴대폰이나 컴퓨터의 iLoveHTML, Gradle, keytool에서 사용할 수 있습니다.';

  @override
  String validUntilDate(String date) {
    return '$date까지 유효';
  }

  @override
  String get atLeast8 => '8자 이상';

  @override
  String deleteKeyBody(String alias) {
    return '\"$alias\"(으)로 서명한 앱은 정확히 이 키로만 업데이트할 수 있습니다. 백업이 없으면 다시는 업데이트할 수 없습니다.';
  }

  @override
  String typeToConfirm(String alias) {
    return '확인하려면 \"$alias\"을(를) 입력하세요';
  }

  @override
  String backupSaved(String file) {
    return '백업 저장됨: $file';
  }

  @override
  String shortcutExists(String page) {
    return '\"$page\"의 바로가기가 이미 있습니다';
  }

  @override
  String deleteProjectBody(String name) {
    return '이 기기에서 \"$name\"과(와) 웹사이트 파일, 빌드된 APK를 삭제합니다. 이미 설치된 앱에는 영향이 없습니다.';
  }

  @override
  String offlinePageShown(String page) {
    return '사이트를 불러올 수 없으면 \"$page\" 페이지가 표시됩니다. \"다시 시도\" 버튼은 https://appassets.androidplatform.net/html2apk/retry 로 연결하세요.';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count번 다운로드됨.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return '파일을 읽을 수 없습니다: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '파일 $count개, $size';
  }

  @override
  String checkFailed(String error) {
    return '확인 실패: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return '최적화하면 파일 $count개가 작아지고 $saved을(를) 절약합니다 ($before → $after). APK도 압축되므로 CSS와 JSON은 APK에서 절약되는 양이 더 적은 경우가 많습니다.';
  }

  @override
  String example(String value) {
    return '예: $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return '릴리스 키를 불러올 수 없습니다: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return '이 앱은 처음에 다른 키(SHA-256 $sha…)로 출시되었습니다. 그 릴리스를 설치한 휴대폰은 \"$alias\"(으)로 서명한 APK로 업데이트할 수 없으며, Google Play도 업데이트로 받아들이지 않습니다.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return '게시자: $publisher · $date까지 유효';
  }

  @override
  String replaceCertBody(String publisher) {
    return '\"$publisher\"이(가) 서명한 설치 프로그램으로 설치한 앱은 게시자 이름이 같은 설치 프로그램으로만 업데이트됩니다. 필요할 수 있다면 현재 인증서를 먼저 백업하세요.';
  }

  @override
  String passwordOf(String file) {
    return '$file의 비밀번호';
  }

  @override
  String savedFile(String file) {
    return '$file 저장됨';
  }

  @override
  String saveFailed(String error) {
    return '저장 실패: $error';
  }

  @override
  String get cannotBuildYet => '아직 빌드할 수 없습니다:';

  @override
  String get shareFilesHint =>
      '파일을 넣은 navigator.share()로 이미지와 PDF를 다른 앱에 보냅니다. Android 10 이상에서는 공유한 이미지가 갤러리에도 저장됩니다.';

  @override
  String get projects => '프로젝트';

  @override
  String get restoreBackup => '백업 복원';

  @override
  String get settings => '설정';

  @override
  String get newApp => '새 앱';

  @override
  String get htmlFiles => 'HTML 파일';

  @override
  String get htmlFilesHint =>
      '.html 페이지를 고르고, CSS·JavaScript·이미지가 별도 파일이면 함께 고르세요. 오프라인에서 작동합니다.';

  @override
  String get websiteZip => '웹사이트 ZIP';

  @override
  String get websiteZipHint => '웹사이트 폴더 전체를 압축한 파일. 오프라인에서 작동합니다.';

  @override
  String get websiteUrl => '웹사이트 URL';

  @override
  String get websiteUrlHint => '실시간 https 웹사이트를 감쌉니다. 인터넷 연결이 필요합니다.';

  @override
  String get noProjectsYet => '아직 프로젝트가 없습니다';

  @override
  String get building => '빌드 중…';

  @override
  String get selectHtmlFile =>
      '.html 파일을 하나 이상 고르고, 사용하는 CSS·JavaScript·이미지도 함께 고르세요.';

  @override
  String get defaultAppName => '내 앱';

  @override
  String get appName => '앱 이름';

  @override
  String get enterName => '이름을 입력하세요';

  @override
  String get packageId => '패키지 ID';

  @override
  String get packageIdHelp => '기기와 Play에서 고유한 ID, 예: com.yourname.app';

  @override
  String get cancel => '취소';

  @override
  String get importButton => '가져오기';

  @override
  String get noMissingFiles => '누락된 파일이 없습니다';

  @override
  String get openProject => '프로젝트 열기';

  @override
  String get noConsoleMessages => '콘솔 메시지나 문제가 없습니다';

  @override
  String get viewport => '뷰포트';

  @override
  String get consoleAndIssues => '콘솔 및 문제';

  @override
  String get checkWebsite => '웹사이트 확인';

  @override
  String get websiteReachable => '웹사이트에 연결됨';

  @override
  String get liveSiteNote =>
      '앱이 이 사이트를 실시간으로 보여 주므로 인터넷 연결이 필요합니다. 오프라인에서는 작동하지 않습니다.';

  @override
  String get create => '만들기';

  @override
  String get backUpKeyNow => '지금 이 키를 백업하세요';

  @override
  String get backUpKeyBody =>
      '앱의 모든 업데이트는 같은 키로 서명해야 합니다. 이 기기를 잃어버리거나 iLoveHTML을 삭제하면 백업이 없는 한 키도 사라집니다.\n\n.jks 파일을 안전한 곳(이 기기만이 아닌 곳)에 저장하고 비밀번호는 따로 보관하세요.';

  @override
  String get later => '나중에';

  @override
  String get saveBackup => '백업 저장';

  @override
  String get certificate => '인증서';

  @override
  String get sha256Fingerprint => 'SHA-256 지문';

  @override
  String get sha1Fingerprint => 'SHA-1 지문';

  @override
  String get validUntil => '유효 기간';

  @override
  String get added => '추가됨';

  @override
  String get saveBackupJks => '백업 저장(.jks)';

  @override
  String get delete => '삭제';

  @override
  String get releaseKeys => '릴리스 키';

  @override
  String get createKey => '키 만들기';

  @override
  String get importKeystoreFile => '.jks / .keystore / .p12 가져오기';

  @override
  String get noReleaseKeys => '아직 릴리스 키가 없습니다';

  @override
  String get createReleaseKey => '릴리스 키 만들기';

  @override
  String get keyAlias => '키 별칭';

  @override
  String get keyAliasHelp => '영문자, 숫자, 점, 하이픈, 밑줄';

  @override
  String get publisherNameField => '이름 또는 앱 게시자';

  @override
  String get required => '필수';

  @override
  String get organizationOptional => '조직(선택)';

  @override
  String get countryCodeOptional => '국가 코드(선택)';

  @override
  String get password => '비밀번호';

  @override
  String get passwordHelp => '키 저장소와 키에 사용됩니다';

  @override
  String get repeatPassword => '비밀번호 확인';

  @override
  String get passwordsDoNotMatch => '비밀번호가 일치하지 않습니다';

  @override
  String get createKeyNote =>
      'RSA 2048비트, 30년 동안 유효. 컴퓨터에서 백업을 사용하려면 이 비밀번호가 필요합니다.';

  @override
  String get noPrivateKeys => '이 파일에 개인 키가 없습니다';

  @override
  String get importKeystore => '키 저장소 가져오기';

  @override
  String get keystorePassword => '키 저장소 비밀번호';

  @override
  String get keyPassword => '키 비밀번호';

  @override
  String get keyPasswordHelp => '키 저장소 비밀번호와 같으면 비워 두세요';

  @override
  String get importKeystoreNote =>
      'iLoveHTML은 키 저장소 비밀번호로 보호된 사본을 보관합니다. 원본 파일은 바뀌지 않습니다.';

  @override
  String get open => '열기';

  @override
  String get deleteReleaseKey => '릴리스 키를 삭제할까요?';

  @override
  String get deleteKey => '키 삭제';

  @override
  String get projectNotFound => '프로젝트를 찾을 수 없습니다';

  @override
  String get backUpProject => '프로젝트 백업';

  @override
  String get preview => '미리보기';

  @override
  String get build => '빌드';

  @override
  String get previewInBrowser => '브라우저에서 미리보기';

  @override
  String get liveSiteOpened => '기본 브라우저에서 실시간 사이트를 열었습니다.';

  @override
  String get servedFromPc =>
      '이 창이 열려 있는 동안에만 이 PC에서 제공됩니다. 휴대폰 앱에는 콘솔과 링크 검사가 있으니, 여기서는 브라우저 개발자 도구(F12)를 사용하세요.';

  @override
  String get missingFiles => '누락된 파일:';

  @override
  String get close => '닫기';

  @override
  String get stopPreview => '미리보기 중지';

  @override
  String get settingsSaved => '설정이 저장되었습니다';

  @override
  String get iconUpdated => '아이콘이 업데이트되었습니다';

  @override
  String get splashUpdated => '스플래시 이미지가 업데이트되었습니다';

  @override
  String get offlinePageAdded => '오프라인 페이지가 추가되었습니다';

  @override
  String get deleteProjectQ => '프로젝트를 삭제할까요?';

  @override
  String get save => '저장';

  @override
  String get sectionApp => '앱';

  @override
  String get sectionContent => '콘텐츠';

  @override
  String get sectionShortcuts => '바로가기';

  @override
  String get sectionAppSize => '앱 크기';

  @override
  String get sectionAppearance => '모양';

  @override
  String get sectionDevices => '기기';

  @override
  String get sectionSecurity => '보안';

  @override
  String get sectionOffline => '오프라인';

  @override
  String get sectionDanger => '위험 구역';

  @override
  String get versionName => '버전 이름';

  @override
  String get versionCode => '버전 코드';

  @override
  String get defaultIcon => '기본 아이콘';

  @override
  String get customIcon => '사용자 지정 아이콘';

  @override
  String get chooseImage => '이미지 선택';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP 또는 SVG, 최소 48px, 512 × 512 권장. 정사각형이 아닌 이미지는 가운데에 배치됩니다.';

  @override
  String get startPage => '시작 페이지';

  @override
  String get loadedLive => '실시간으로 불러옵니다. 앱에 인터넷 연결이 필요합니다.';

  @override
  String get otherSites => '앱 안에서 열리는 다른 사이트(선택)';

  @override
  String get otherSitesHelp => '쉼표로 구분합니다. 다른 사이트로 가는 링크는 브라우저에서 열립니다.';

  @override
  String get orientation => '화면 방향';

  @override
  String get orientationAuto => '자동';

  @override
  String get portrait => '세로';

  @override
  String get landscape => '가로';

  @override
  String get shortcutsHint => '앱 아이콘을 길게 누르면 이 페이지들이 보입니다.';

  @override
  String get removeShortcut => '바로가기 삭제';

  @override
  String get addShortcut => '바로가기 추가';

  @override
  String get optimizeFiles => '빌드할 때 파일 최적화';

  @override
  String get optimizeFilesHint =>
      '앱 안의 CSS, JSON, PNG와 큰 JPEG 파일을 작게 만듭니다. JPEG는 85% 품질로 다시 저장됩니다. 프로젝트 파일은 바뀌지 않습니다.';

  @override
  String get sizeReport => '크기 보고서';

  @override
  String get statusBarColour => '상태 표시줄 색상';

  @override
  String get navBarColour => '탐색 표시줄 색상';

  @override
  String get splashScreen => '스플래시 화면';

  @override
  String get splashIconHint => '첫 페이지가 로드될 때까지 앱 아이콘을 표시합니다.';

  @override
  String get splashImageHint => '첫 페이지가 로드될 때까지 스플래시 이미지를 표시합니다.';

  @override
  String get splashBackground => '스플래시 배경';

  @override
  String get chooseSplash => '스플래시 이미지 선택';

  @override
  String get replaceSplash => '스플래시 이미지 바꾸기';

  @override
  String get useAppIcon => '앱 아이콘 사용';

  @override
  String get theme => '테마';

  @override
  String get light => '밝게';

  @override
  String get dark => '어둡게';

  @override
  String get followPhone => '휴대폰 설정 따르기';

  @override
  String get themeHint =>
      'prefers-color-scheme을 설정해 다크 모드 CSS가 있는 페이지가 전환되게 합니다.';

  @override
  String get fullscreen => '전체 화면';

  @override
  String get fullscreenHint => '상태 표시줄과 탐색 표시줄을 숨깁니다. 가장자리에서 스와이프하면 잠시 표시됩니다.';

  @override
  String get keepScreenOn => '화면 켜짐 유지';

  @override
  String get keepScreenOnHint => '앱이 열려 있는 동안 화면이 꺼지지 않습니다.';

  @override
  String get tvHint =>
      '아이콘과 이름으로 만든 배너와 함께 TV 홈 화면에 앱을 표시합니다. 리모컨 화살표 키로 링크와 버튼 사이를 이동하고 OK로 엽니다.';

  @override
  String get rotateTablets => '태블릿에서 자유 회전';

  @override
  String get rotateTabletsHint =>
      '휴대폰이 위에서 고른 방향을 유지해도 태블릿과 폴더블은 어느 방향으로든 돌아갈 수 있습니다. Android 16 이상은 큰 화면에서 항상 허용합니다.';

  @override
  String get desktopLayout => '태블릿과 TV에서 데스크톱 레이아웃';

  @override
  String get desktopLayoutHint => '웹사이트에 휴대폰 레이아웃 대신 컴퓨터용 레이아웃을 요청합니다.';

  @override
  String get appLock => '앱 잠금';

  @override
  String get appLockHint =>
      '앱을 열 때와 백그라운드에서 30초가 지난 뒤 지문, 얼굴 또는 화면 잠금을 요청합니다. 화면 잠금이 없는 휴대폰은 안내와 함께 앱을 엽니다.';

  @override
  String get javascriptHint => '대부분의 사이트에 필요합니다. 정적 페이지라면 끄세요.';

  @override
  String get localStorage => '로컬 저장소';

  @override
  String get internetAccess => '인터넷 접근';

  @override
  String get internetAccessHint =>
      'CDN, API 또는 웹에서 불러오는 글꼴을 위해 INTERNET 권한을 추가합니다.';

  @override
  String get openOtherSites => '다른 사이트는 브라우저에서 열기';

  @override
  String get openOtherSitesHint => '끄면 다른 사이트로 가는 링크가 아무 동작도 하지 않습니다.';

  @override
  String get pullToRefresh => '당겨서 새로고침';

  @override
  String get pullToRefreshHint => '페이지 맨 위에서 아래로 스와이프하면 새로고침하거나 오류 후 다시 시도합니다.';

  @override
  String get notifications => '알림';

  @override
  String get notificationsHint =>
      '앱이 열려 있는 동안 페이지는 웹 Notification API로 Android 알림을 표시할 수 있습니다. Android 13 이상은 먼저 사용자에게 묻습니다. 푸시 메시지는 없습니다.';

  @override
  String get backButton => '뒤로 버튼';

  @override
  String get backHistory => '뒤로 간 다음 앱 닫기';

  @override
  String get backTwice => '뒤로 간 다음 두 번 눌러 닫기';

  @override
  String get backConfirm => '뒤로 간 다음 닫기 전에 묻기';

  @override
  String get backHome => '시작 페이지로 간 다음 닫기';

  @override
  String get fileUploads => '파일 업로드';

  @override
  String get fileUploadsHint =>
      '파일 입력란이 Android 파일 선택기를 열게 합니다. 파일은 매번 사용자가 고릅니다.';

  @override
  String get share => '공유';

  @override
  String get shareHint => 'navigator.share는 텍스트와 링크용 Android 공유 시트를 엽니다.';

  @override
  String get downloads => '다운로드';

  @override
  String get downloadsHint => '다운로드 링크와 생성된 파일은 Download 폴더에 저장됩니다.';

  @override
  String get shareFiles => '이미지와 PDF 공유';

  @override
  String get galleryFolder => '갤러리 폴더(선택)';

  @override
  String get galleryFolderExample => '예: 내 사진';

  @override
  String get galleryFolderHelp =>
      '공유하거나 다운로드한 이미지는 Pictures/<폴더>에 저장됩니다. 비우면 공유는 앱 이름, 다운로드는 Download.';

  @override
  String get shareToApp => '앱으로 바로 공유(선택)';

  @override
  String get shareToAppHelp => '설치되어 있으면 공유 시트 대신 파일 공유를 바로 여는 패키지.';

  @override
  String get usePackageName => 'com.whatsapp 같은 패키지 이름을 사용하세요';

  @override
  String get offlineBuiltIn =>
      '사이트를 불러올 수 없으면 기본 제공 \"페이지를 사용할 수 없음\" 화면이 표시됩니다.';

  @override
  String get chooseOfflinePage => '오프라인 페이지 선택(.html)';

  @override
  String get replaceOfflinePage => '오프라인 페이지 바꾸기';

  @override
  String get useBuiltInPage => '기본 제공 페이지 사용';

  @override
  String get userAgentSuffix => '사용자 에이전트 접미사(선택)';

  @override
  String get atMost200 => '최대 200자';

  @override
  String get deleteProject => '프로젝트 삭제';

  @override
  String get useColourLike => '#1A73E8 같은 색상을 사용하세요';

  @override
  String get noNetwork => '이 컴퓨터가 Wi-Fi나 이더넷 네트워크에 연결되어 있지 않습니다.';

  @override
  String get installOnPhone => '휴대폰에 설치';

  @override
  String get installSteps =>
      '1. 휴대폰을 이 컴퓨터와 같은 Wi-Fi에 연결하세요.\n2. 휴대폰 카메라로 코드를 스캔하고 링크를 여세요.\n3. 다운로드한 파일을 여세요. Android가 물으면 브라우저에서 설치를 허용하세요.';

  @override
  String get linkStopped => '링크가 중지되었습니다.';

  @override
  String get networkAddress => '네트워크 주소';

  @override
  String get linkWorks10Min => '이 창이 열려 있는 동안 링크는 10분간 작동합니다.';

  @override
  String get trustedNetworkOnly =>
      '신뢰할 수 있는 네트워크에서만 사용하세요. Windows가 iLoveHTML의 방화벽 통과를 물으면 개인 네트워크에 대해 허용하세요.';

  @override
  String get startAgain => '다시 시작';

  @override
  String get done => '완료';

  @override
  String get kindPages => '페이지';

  @override
  String get kindImages => '이미지';

  @override
  String get kindFonts => '글꼴';

  @override
  String get kindMedia => '오디오 및 동영상';

  @override
  String get kindData => '데이터';

  @override
  String get kindOther => '기타';

  @override
  String get largestFiles => '가장 큰 파일';

  @override
  String get advice => '조언';

  @override
  String get checkOptimizing => '최적화로 절약되는 양 확인';

  @override
  String get name => '이름';

  @override
  String get exampleCart => '예: 장바구니';

  @override
  String get choosePage => '페이지를 선택하세요';

  @override
  String get page => '페이지';

  @override
  String get add => '추가';

  @override
  String get differentKey => '다른 릴리스 키';

  @override
  String get buildAnyway => '그래도 빌드';

  @override
  String get windowsExe => 'Windows 앱(.exe)';

  @override
  String get exeDescription =>
      'Microsoft Edge WebView2(Windows 11과 업데이트된 Windows 10에 내장)로 이 사이트를 자체 창에서 여는 단일 .exe 파일입니다. 코드 서명이 없으므로 사용자가 추가 정보 → 실행을 고를 때까지 Windows가 \"Windows의 PC 보호\"를 표시할 수 있습니다.';

  @override
  String get devTools => '개발자 도구(테스트용)';

  @override
  String get devToolsHint => '앱에서 F12와 검사가 작동합니다. 배포하는 버전에서는 끄세요';

  @override
  String get buildExe => '.exe 빌드';

  @override
  String get windowsMsix => 'Windows 설치 프로그램(.msix)';

  @override
  String get msixDescription =>
      '다른 Windows 소프트웨어처럼 앱을 설치합니다: 시작 메뉴 항목, 깔끔한 제거, 더 높은 버전을 공유하면 업데이트. 모든 설치 프로그램은 인증서로 서명됩니다.';

  @override
  String get needsWindowsSdk =>
      'Windows SDK가 필요합니다. 다음 명령으로 설치하세요:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      '아직 인증서가 없습니다. 자신의 코드 서명 인증서를 사용하거나 테스트 인증서를 만들어 시험해 보세요.';

  @override
  String get testCertNote =>
      '테스트 인증서: 사용자가 한 번 신뢰해야 Windows가 앱을 설치합니다. 설치 프로그램과 함께 .cer 파일을 공유하세요. 더블클릭 → 인증서 설치 → 로컬 컴퓨터 → \"신뢰할 수 있는 사용자\"를 거치면 됩니다. 인증 기관에서 구입한 인증서는 이 단계가 필요 없습니다.';

  @override
  String get createTestCert => '테스트 인증서 만들기';

  @override
  String get useMyPfx => '내 .pfx 사용';

  @override
  String get savedCertificate => '인증서를 저장했습니다';

  @override
  String get saveCer => '.cer 저장';

  @override
  String get buildInstaller => '설치 프로그램 빌드';

  @override
  String get replaceCertQ => '인증서를 바꿀까요?';

  @override
  String get replace => '바꾸기';

  @override
  String get publisherName => '게시자 이름';

  @override
  String get publisherNameHelp => '앱을 설치할 때 게시자로 표시됩니다.';

  @override
  String get testCertCreated => '테스트 인증서를 만들었습니다';

  @override
  String get useMyCertificate => '내 인증서 사용';

  @override
  String get certificateAdded => '인증서를 추가했습니다';

  @override
  String get ok => '확인';

  @override
  String get allowUnknownApps =>
      '열린 화면에서 iLoveHTML에 \"출처를 알 수 없는 앱 설치\"를 허용한 다음 다시 설치를 누르세요.';

  @override
  String get debug => '디버그';

  @override
  String get release => '릴리스';

  @override
  String get debugHint => '테스트용. 이 기기에 보관된 디버그 키로 서명됩니다. 게시용이 아닙니다.';

  @override
  String get releaseHint =>
      '게시용. 릴리스 키로 서명됩니다. 이후 모든 업데이트는 같은 키와 더 높은 버전 코드를 써야 합니다.';

  @override
  String get appBundlePlay => 'App Bundle(Play)';

  @override
  String get aabHint =>
      '.aab는 Google Play Console에 업로드하세요. 직접 설치할 수 없으므로 휴대폰 테스트에는 APK를 사용하세요.';

  @override
  String get createOrImportKey => '릴리스 키 만들기 또는 가져오기';

  @override
  String get releaseKey => '릴리스 키';

  @override
  String get manageKeys => '키 관리';

  @override
  String get buildDebugApk => '디버그 APK 빌드';

  @override
  String get buildAppBundle => 'App Bundle 빌드';

  @override
  String get buildReleaseApk => '릴리스 APK 빌드';

  @override
  String get buildingUnavailable => '이 플랫폼에서는 아직 빌드할 수 없습니다.';

  @override
  String get buildFailed => '빌드 실패';

  @override
  String get saveAs => '다른 이름으로 저장…';

  @override
  String get showInFolder => '폴더에서 보기';

  @override
  String get install => '설치';

  @override
  String get saveToDevice => '기기에 저장';

  @override
  String get buildLog => '빌드 로그';

  @override
  String get history => '기록';

  @override
  String get twoLetters => '영문자 두 글자';

  @override
  String invalidHost(String host) {
    return '잘못된 호스트 \"$host\"';
  }

  @override
  String get thisDevice => '이 기기';

  @override
  String get appTitle => 'iLoveHTML';

  @override
  String buildingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '빌드 중… 로그 $count줄',
      zero: '빌드 중…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => '시스템';

  @override
  String get accentColour => '강조 색상';

  @override
  String get accentOrange => '주황';

  @override
  String get accentGreen => '터미널 초록';

  @override
  String get accentCyan => '청록';

  @override
  String get accentViolet => '보라';

  @override
  String get accentPink => '분홍';

  @override
  String get animations => '애니메이션';

  @override
  String get animationsHint => 'ASCII 스플래시, 빌드 애니메이션, 페이지 전환';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get signing => '서명';

  @override
  String get releaseKeysSubtitle => '릴리스에 서명하는 키를 만들고 가져오고 백업합니다';

  @override
  String get storage => '저장 공간';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '프로젝트 $count개 · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => '빌드 엔진';

  @override
  String get notAvailablePlatform => '이 플랫폼에서는 아직 사용할 수 없습니다';

  @override
  String get gradleReady => '이 PC의 Gradle(준비됨)';

  @override
  String get gradleNotReady => '이 PC의 Gradle: 준비되지 않음';

  @override
  String get buildsRunOnPc => '빌드는 모두 이 PC에서 실행됩니다. 파일은 업로드되지 않습니다.';

  @override
  String get onDeviceReady => '기기 내 조립(준비됨)';

  @override
  String get onDeviceMissing => '기기 내 조립: 기본 APK 없음';

  @override
  String get buildsRunOnDevice => '빌드는 모두 이 기기에서 실행됩니다. 파일은 업로드되지 않습니다.';

  @override
  String get about => '정보';

  @override
  String get howToUse => '사용 방법';

  @override
  String get howToUseSubtitle => '다섯 단계로 웹사이트에서 설치된 앱까지';

  @override
  String get termsOfUse => '이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get version => '버전';

  @override
  String get versionCopied => '버전을 복사했습니다';

  @override
  String get credit => '크레딧';

  @override
  String madeBy(String author) {
    return '$author이(가) <3을 담아 만듦';
  }

  @override
  String get supportHint =>
      'iLoveHTML은 무료이며 광고도 추적도 없습니다. 시간을 아껴 주었다면 개발을 후원할 수 있습니다.';

  @override
  String get buyMeACoffee => '커피 한 잔 사 주기';

  @override
  String couldNotOpenLink(String url) {
    return '$url을(를) 열 수 없습니다';
  }

  @override
  String lastUpdated(String date) {
    return '마지막 업데이트: $date';
  }

  @override
  String get howToStep1Title => '프로젝트 만들기';

  @override
  String get howToStep1Body =>
      '새 앱을 누르고 HTML 파일, 웹사이트 ZIP 또는 실시간 https 웹사이트 URL을 고르세요. 파일과 ZIP은 오프라인에서 작동하고 URL은 인터넷이 필요합니다.';

  @override
  String get howToStep2Title => '앱 이름 정하기';

  @override
  String get howToStep2Body =>
      '앱 이름과 com.yourname.app 같은 고유한 패키지 ID를 입력하세요. 업데이트할 때마다 같은 패키지 ID를 유지하세요.';

  @override
  String get howToStep3Title => '꾸미기';

  @override
  String get howToStep3Body =>
      '설정 탭에서 시작 페이지, 아이콘, 스플래시 화면, 색상, 화면 방향, 바로가기, WebView 기능을 고르세요. 다 되면 저장을 누르세요. 미리보기로 먼저 앱을 써 볼 수 있습니다.';

  @override
  String get howToStep4Title => '빌드하기';

  @override
  String get howToStep4Body =>
      '빌드 탭에서 테스트하려면 디버그, 게시하려면 릴리스를 고르세요. 릴리스 빌드에는 릴리스 키가 필요하니 만들고 백업하세요. Windows에서는 .exe나 .msix 설치 프로그램도 빌드할 수 있습니다.';

  @override
  String get howToStep5Title => '설치 또는 공유';

  @override
  String get howToStep5Body =>
      '이 휴대폰에 APK를 설치하거나 공유하거나 저장하세요. PC에서는 휴대폰에 설치로 Wi-Fi를 통해 보냅니다. App Bundle(.aab)은 Google Play Console에 업로드하세요.';

  @override
  String get howToTipsTitle => '팁';

  @override
  String get howToTips =>
      '• 모든 업데이트는 같은 패키지 ID와 릴리스 키, 더 높은 버전 코드를 써야 합니다.\n• 릴리스 키와 프로젝트를 백업하세요. 잃어버린 키는 누구도 복구할 수 없습니다.\n• 크기 보고서로 앱을 더 작게 만들 수 있습니다.\n• 프로젝트 백업(프로젝트 화면 위쪽)으로 나중에 복원할 수 있는 사본을 보관하세요.';

  @override
  String get termsBody =>
      '이 이용약관은 1elevenop이 만든 iLoveHTML 앱(\"앱\")에 적용됩니다. 앱을 사용하면 이 약관에 동의하는 것입니다.\n\n## 앱의 기능\n\niLoveHTML은 HTML 파일, 웹사이트 ZIP, 웹 주소를 Android 및 Windows 앱으로 바꿉니다. 빌드는 사용자의 기기에서 실행됩니다.\n\n## 사용자의 콘텐츠\n\n사용자가 만든 웹사이트, 파일, 아이콘, 앱에 대한 모든 권리는 사용자에게 있습니다. 그 콘텐츠를 사용할 권리가 있는지, 그리고 빌드하고 게시하는 앱에 대해서는 법률과 Google Play 같은 앱 스토어 규정 준수를 포함해 사용자가 책임집니다.\n\n## 허용되는 사용\n\n악성 코드나 다른 브랜드를 사칭하는 앱처럼 불법적이거나 해롭거나 기만적인 소프트웨어, 또는 타인의 권리를 침해하는 소프트웨어를 만드는 데 앱을 사용하지 마세요.\n\n## 릴리스 키\n\n릴리스 키는 사용자의 기기에만 저장됩니다. 키 백업과 비밀번호 보호는 사용자의 책임입니다. 잃어버린 키는 복구할 수 없으며, 그 키로 서명한 앱은 더 이상 업데이트할 수 없습니다.\n\n## 보증 없음\n\n앱은 무료로 \"있는 그대로\" 제공되며 어떠한 보증도 없습니다. 법이 허용하는 범위에서 작성자는 앱 사용으로 인한 데이터, 키, 수입의 손실이나 기타 손해에 책임지지 않습니다.\n\n## 변경\n\n이 약관은 앱의 새 버전과 함께 바뀔 수 있습니다. 위의 날짜가 마지막 변경일입니다. 앱을 계속 사용하면 변경된 약관에 동의하는 것입니다.\n\n## 문의\n\n문의 사항은 1elevenop의 iLoveHTML GitHub 프로젝트에 이슈를 등록해 주세요.';

  @override
  String get privacyBody =>
      'iLoveHTML은 사용자의 기기에서 작동하도록 만들어졌습니다. 이 방침은 그것이 사용자의 데이터에 어떤 의미인지 설명합니다.\n\n## 수집하는 데이터\n\n없습니다. 앱에는 계정, 분석, 광고, 추적이 없습니다. 작성자는 사용자나 사용자의 프로젝트에 관한 어떤 데이터도 받지 않습니다.\n\n## 기기에 저장되는 데이터\n\n프로젝트, 웹사이트 파일, 아이콘, 빌드 결과, 설정은 기기 안의 앱 전용 저장소에 저장됩니다. 릴리스 키도 기기에 보관됩니다. Android에서는 Android Keystore로 암호화되고, Windows에서는 비밀번호가 Windows 계정용으로 암호화됩니다. 앱을 삭제하면 이 데이터도 지워지니 백업하세요.\n\n## 네트워크 사용\n\n앱은 사용자가 요청할 때만 인터넷에 연결합니다: 입력한 웹사이트 URL을 확인하거나 미리 볼 때, Buy Me a Coffee 같은 링크를 브라우저에서 열 때, 그리고 Windows에서 Gradle이 빌드 도구를 다운로드할 때입니다. 휴대폰에 설치 기능은 그 창이 열려 있는 동안에만 로컬 네트워크에서 10분간 파일을 제공합니다.\n\n## 사용자가 만드는 앱\n\niLoveHTML로 만든 앱에는 iLoveHTML의 추적 기능이 없습니다. 앱이 무엇을 수집하는지는 넣은 웹사이트에 달려 있으며, 그 개인정보 처리방침은 사용자가 책임집니다.\n\n## 아동\n\n앱은 아동을 포함해 누구의 데이터도 의도적으로 수집하지 않습니다.\n\n## 변경 및 문의\n\n이 방침은 앱의 새 버전과 함께 바뀔 수 있으며, 위의 날짜가 마지막 변경일입니다. 문의 사항은 1elevenop의 iLoveHTML GitHub 프로젝트에 이슈를 등록해 주세요.';

  @override
  String get replaceWebsite => '웹사이트 파일 바꾸기';

  @override
  String get replaceWebsiteHint =>
      '새 ZIP이나 HTML 파일로 바꿉니다. 이름, 패키지 ID, 아이콘, 설정, 키는 그대로입니다.';

  @override
  String get replaceWithZipHint => '새 웹사이트 폴더 압축 파일';

  @override
  String get replaceWithFilesHint => '새 .html 페이지와 CSS, JavaScript, 이미지';

  @override
  String get replaceWebsiteQ => '웹사이트를 바꿀까요?';

  @override
  String replaceWebsiteBody(String name) {
    return '\"$name\"의 웹사이트 파일이 모두 다음에 고르는 파일로 바뀝니다. 앱 이름, 패키지 ID, 버전, 아이콘, 설정, 릴리스 키, 빌드 기록은 그대로입니다. 다시 빌드하면 업데이트된 앱이 만들어집니다.';
  }

  @override
  String replaceFailed(String error) {
    return '웹사이트를 바꿀 수 없습니다: $error';
  }

  @override
  String get websiteReplaced => '웹사이트를 바꿨습니다';

  @override
  String startPageChanged(String page) {
    return '새 파일에 \"$page\"이(가) 없어서 시작 페이지가 바뀌었습니다.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return '페이지가 없어져 바로가기를 삭제했습니다: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      '다시 빌드하면 업데이트된 앱이 만들어집니다. 설치된 앱을 업데이트하려면 먼저 버전 코드를 올리세요.';

  @override
  String get unlockReason => 'iLoveHTML 잠금 해제';

  @override
  String get resetReason => 'iLoveHTML 잠금을 재설정하려면 본인 확인이 필요합니다';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '틀렸습니다. $count번 더 틀리면 기다려야 합니다.',
      zero: '틀렸습니다. 잠시 후 다시 시도하세요.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return '틀린 횟수가 너무 많습니다. $seconds초 후 다시 시도하세요.';
  }

  @override
  String get enterPin => 'PIN을 입력하세요';

  @override
  String get enterPassword => '비밀번호를 입력하세요';

  @override
  String get showPassword => '보기';

  @override
  String get hidePassword => '숨기기';

  @override
  String hintIs(String hint) {
    return '힌트: $hint';
  }

  @override
  String get showHint => '힌트 보기';

  @override
  String get deleteDigit => '지우기';

  @override
  String get unlock => '잠금 해제';

  @override
  String get useFingerprint => '지문 또는 얼굴 사용';

  @override
  String get forgotPin => 'PIN을 잊으셨나요?';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String digitsEntered(int count) {
    return '$count자리 입력됨';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '코드가 틀렸습니다. $count번 더 시도할 수 있습니다.',
      zero: '코드가 틀렸습니다. 잠시 후 다시 시도하세요.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => '이 기기의 잠금 사용';

  @override
  String get forgotWithDeviceHint =>
      '지문, 얼굴 또는 휴대폰 화면 잠금(PIN, 패턴, 비밀번호)으로 본인 확인 후 iLoveHTML용 새 잠금을 정하세요.';

  @override
  String get verifyWithDevice => '기기 잠금으로 확인';

  @override
  String get forgotWithCode => '복구 코드 사용';

  @override
  String get forgotWithCodeHint => '잠금을 설정할 때 표시된 16자리 코드.';

  @override
  String get recoveryCode => '복구 코드';

  @override
  String get useRecoveryCode => '코드 사용';

  @override
  String get forgotNoWay =>
      '둘 다 없으면 시스템 설정에서 iLoveHTML의 앱 데이터를 지워야만 잠금을 없앨 수 있습니다. 이 기기의 모든 프로젝트와 릴리스 키가 삭제됩니다.';

  @override
  String get pinDigitsOnly => '숫자만';

  @override
  String pinLength(int min, int max) {
    return '$min~$max자리 숫자';
  }

  @override
  String passwordMinLength(int count) {
    return '$count자 이상';
  }

  @override
  String get chooseNewSecret => '새 PIN 또는 비밀번호 정하기';

  @override
  String get setUpAppLock => '앱 잠금 설정';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => '새 PIN';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get repeatPin => 'PIN 확인';

  @override
  String get pinsDoNotMatch => 'PIN이 일치하지 않습니다';

  @override
  String get hintOptional => '힌트(선택)';

  @override
  String get hintHelp => '기억을 돕기 위해 잠금 화면에 표시됩니다. 기기를 가진 사람은 누구나 볼 수 있습니다.';

  @override
  String get hintGivesAway => '힌트에 PIN이나 비밀번호를 넣을 수 없습니다';

  @override
  String get unlockWithFingerprint => '지문 또는 얼굴로 잠금 해제';

  @override
  String get unlockWithFingerprintHint => 'PIN이나 비밀번호도 계속 쓸 수 있습니다.';

  @override
  String get appLockNote =>
      '잠금은 이 기기를 집어 든 사람에게서 iLoveHTML과 프로젝트를 숨깁니다. 프로젝트 파일을 암호화하지는 않습니다.';

  @override
  String get saveAndContinue => '저장';

  @override
  String get recoveryCodeTitle => '복구 코드를 저장하세요';

  @override
  String get recoveryCodeBody =>
      'PIN이나 비밀번호를 잊으면 이 코드로 새로 정할 수 있습니다. 지금 한 번만 표시됩니다. 적어 두거나 이 기기가 아닌 안전한 곳에 보관하세요.';

  @override
  String get copy => '복사';

  @override
  String get iSavedTheCode => '코드를 저장했습니다';

  @override
  String get enterCurrentPin => '현재 PIN 입력';

  @override
  String get enterCurrentPassword => '현재 비밀번호 입력';

  @override
  String get wrongPin => 'PIN이 틀렸습니다';

  @override
  String get wrongPassword => '비밀번호가 틀렸습니다';

  @override
  String get appLockOffHint => '꺼짐. iLoveHTML을 열기 전에 PIN, 비밀번호 또는 지문을 요구합니다.';

  @override
  String get appLockOnPin => '켜짐, PIN 사용';

  @override
  String get appLockOnPassword => '켜짐, 비밀번호 사용';

  @override
  String get lockAgainAfter => '앱을 나간 뒤 다시 잠그기';

  @override
  String get relockImmediately => '즉시';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 후',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'iLoveHTML을 시작할 때만';

  @override
  String get changePinOrHint => 'PIN, 비밀번호, 힌트 변경';

  @override
  String get lockNow => '지금 잠그기';

  @override
  String get turnOffLock => '잠금 끄기';
}

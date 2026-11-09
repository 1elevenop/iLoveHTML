// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String unreadableProject(String name) {
    return 'Projeto ilegível: $name';
  }

  @override
  String get emptyHintWindows =>
      'Transforme arquivos HTML, um ZIP de site ou um site https ao vivo em um app Android ou Windows. Tudo é compilado neste dispositivo.';

  @override
  String get emptyHintAndroid =>
      'Transforme arquivos HTML, um ZIP de site ou um site https ao vivo em um app Android. Tudo é compilado neste dispositivo.';

  @override
  String notBuiltYet(String version) {
    return 'v$version · ainda não compilado';
  }

  @override
  String lastBuild(String version, String status, String ago) {
    return 'v$version · última compilação $status $ago';
  }

  @override
  String get justNow => 'agora mesmo';

  @override
  String minutesAgo(int n) {
    return 'há $n min';
  }

  @override
  String hoursAgo(int n) {
    return 'há $n h';
  }

  @override
  String daysAgo(int n) {
    return 'há $n d';
  }

  @override
  String chooseBackupFile(String ext) {
    return 'Escolha um arquivo de backup $ext';
  }

  @override
  String restored(String name) {
    return '$name restaurado';
  }

  @override
  String notUsableBackup(String message) {
    return 'Backup inutilizável: $message';
  }

  @override
  String restoreFailed(String error) {
    return 'Falha ao restaurar: $error';
  }

  @override
  String importFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String importedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos importados',
      one: '1 arquivo importado',
    );
    return '$_temp0';
  }

  @override
  String startPageIs(String page) {
    return 'Página inicial: $page';
  }

  @override
  String htmlPagesFound(int count) {
    return '$count páginas HTML encontradas; você pode mudar a página inicial em Configurações.';
  }

  @override
  String filesMissing(int count) {
    return '$count arquivos referenciados estão faltando:';
  }

  @override
  String andMore(int count) {
    return '…e mais $count';
  }

  @override
  String fileNotFound(String path) {
    return 'Arquivo não encontrado: $path';
  }

  @override
  String wouldOpenOutside(String url) {
    return 'Abriria fora do app: $url';
  }

  @override
  String pageFailedToLoad(String description, String url) {
    return 'A página não carregou: $description ($url)';
  }

  @override
  String couldNotStartPreview(String error) {
    return 'Não foi possível iniciar a prévia: $error';
  }

  @override
  String previewTitle(String name) {
    return 'Prévia · $name';
  }

  @override
  String websiteAnsweredHttp(int code) {
    return 'O site respondeu com HTTP $code';
  }

  @override
  String redirected(int count) {
    return 'Redirecionado $count× — o app vai começar neste endereço.';
  }

  @override
  String importedKey(String alias) {
    return '\"$alias\" importada';
  }

  @override
  String backupSavedAs(String alias) {
    return 'Backup salvo como $alias.jks. Guarde a senha separadamente.';
  }

  @override
  String backupFailed(String error) {
    return 'Falha no backup: $error';
  }

  @override
  String deletedKey(String alias) {
    return '\"$alias\" excluída deste dispositivo';
  }

  @override
  String get releaseKeysIntroWindows =>
      'Versões de lançamento são assinadas com uma destas chaves. O Google Play e o Android só aceitam atualizações assinadas com a mesma chave da primeira versão. As chaves ficam neste PC, com senhas criptografadas para sua conta do Windows; um backup é um arquivo .jks protegido por senha que funciona com o iLoveHTML em um celular ou computador, Gradle e keytool.';

  @override
  String get releaseKeysIntroAndroid =>
      'Versões de lançamento são assinadas com uma destas chaves. O Google Play e o Android só aceitam atualizações assinadas com a mesma chave da primeira versão. As chaves ficam neste celular, criptografadas com o Android Keystore; um backup é um arquivo .jks protegido por senha que funciona com o iLoveHTML em um celular ou computador, Gradle e keytool.';

  @override
  String validUntilDate(String date) {
    return 'válida até $date';
  }

  @override
  String get atLeast8 => 'Pelo menos 8 caracteres';

  @override
  String deleteKeyBody(String alias) {
    return 'Apps assinados com \"$alias\" só podem ser atualizados com exatamente esta chave. Sem um backup, você nunca mais poderá atualizá-los.';
  }

  @override
  String typeToConfirm(String alias) {
    return 'Digite \"$alias\" para confirmar';
  }

  @override
  String backupSaved(String file) {
    return 'Backup salvo: $file';
  }

  @override
  String shortcutExists(String page) {
    return 'Já existe um atalho para \"$page\"';
  }

  @override
  String deleteProjectBody(String name) {
    return 'Isso exclui \"$name\", seus arquivos do site e os APKs compilados deste dispositivo. Apps já instalados não são afetados.';
  }

  @override
  String offlinePageShown(String page) {
    return 'Quando o site não carrega, sua página \"$page\" é exibida. Crie um link para https://appassets.androidplatform.net/html2apk/retry para um botão \"Tentar de novo\".';
  }

  @override
  String downloadedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Baixado $count vezes.',
      one: 'Baixado 1 vez.',
    );
    return '$_temp0';
  }

  @override
  String couldNotReadFiles(String error) {
    return 'Não foi possível ler os arquivos: $error';
  }

  @override
  String filesAndSize(int count, String size) {
    return '$count arquivos, $size';
  }

  @override
  String checkFailed(String error) {
    return 'Falha na verificação: $error';
  }

  @override
  String optimizeResult(int count, String saved, String before, String after) {
    return 'Otimizar reduz $count arquivos e economiza $saved ($before → $after). O APK também é compactado, então a economia no APK costuma ser menor para CSS e JSON.';
  }

  @override
  String example(String value) {
    return 'ex.: $value';
  }

  @override
  String couldNotLoadKeys(String error) {
    return 'Não foi possível carregar as chaves de lançamento: $error';
  }

  @override
  String differentKeyBody(String sha, String alias) {
    return 'Este app foi lançado primeiro com outra chave (SHA-256 $sha…). Celulares que instalaram essa versão não podem atualizar para um APK assinado com \"$alias\", e o Google Play vai rejeitá-lo como atualização.';
  }

  @override
  String publisherValidUntil(String publisher, String date) {
    return 'Editor: $publisher · válido até $date';
  }

  @override
  String replaceCertBody(String publisher) {
    return 'Apps instalados por instaladores assinados por \"$publisher\" só se atualizam com instaladores do mesmo editor. Faça backup do certificado atual antes, se puder precisar dele.';
  }

  @override
  String passwordOf(String file) {
    return 'Senha de $file';
  }

  @override
  String savedFile(String file) {
    return '$file salvo';
  }

  @override
  String saveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get cannotBuildYet => 'Ainda não é possível compilar:';

  @override
  String get shareFilesHint =>
      'navigator.share() com arquivos envia imagens e PDFs para outros apps. No Android 10+ as imagens compartilhadas também são salvas na galeria.';

  @override
  String get projects => 'Projetos';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get settings => 'Configurações';

  @override
  String get newApp => 'Novo app';

  @override
  String get htmlFiles => 'Arquivos HTML';

  @override
  String get htmlFilesHint =>
      'Escolha uma página .html, junto com CSS, JavaScript e imagens se forem arquivos separados. Funciona off-line.';

  @override
  String get websiteZip => 'ZIP do site';

  @override
  String get websiteZipHint =>
      'Uma pasta de site inteira, compactada. Funciona off-line.';

  @override
  String get websiteUrl => 'URL do site';

  @override
  String get websiteUrlHint =>
      'Empacota um site https ao vivo. Precisa de conexão com a internet.';

  @override
  String get noProjectsYet => 'Nenhum projeto ainda';

  @override
  String get building => 'Compilando…';

  @override
  String get selectHtmlFile =>
      'Selecione pelo menos um arquivo .html, junto com o CSS, JavaScript ou imagens que ele usa.';

  @override
  String get defaultAppName => 'Meu App';

  @override
  String get appName => 'Nome do app';

  @override
  String get enterName => 'Digite um nome';

  @override
  String get packageId => 'ID do pacote';

  @override
  String get packageIdHelp =>
      'ID único no dispositivo e no Play, ex.: com.seunome.app';

  @override
  String get cancel => 'Cancelar';

  @override
  String get importButton => 'Importar';

  @override
  String get noMissingFiles => 'Nenhum arquivo faltando';

  @override
  String get openProject => 'Abrir projeto';

  @override
  String get noConsoleMessages => 'Nenhuma mensagem ou problema no console';

  @override
  String get viewport => 'Viewport';

  @override
  String get consoleAndIssues => 'Console e problemas';

  @override
  String get checkWebsite => 'Verificar site';

  @override
  String get websiteReachable => 'Site acessível';

  @override
  String get liveSiteNote =>
      'O app mostra este site ao vivo e precisa de conexão com a internet. Não funciona off-line.';

  @override
  String get create => 'Criar';

  @override
  String get backUpKeyNow => 'Faça backup desta chave agora';

  @override
  String get backUpKeyBody =>
      'Toda atualização de um app precisa ser assinada com a mesma chave. Se este dispositivo for perdido ou o iLoveHTML for desinstalado, a chave some, a menos que você tenha um backup.\n\nSalve o arquivo .jks em um lugar seguro (não só neste dispositivo) e guarde a senha separadamente.';

  @override
  String get later => 'Depois';

  @override
  String get saveBackup => 'Salvar backup';

  @override
  String get certificate => 'Certificado';

  @override
  String get sha256Fingerprint => 'Impressão digital SHA-256';

  @override
  String get sha1Fingerprint => 'Impressão digital SHA-1';

  @override
  String get validUntil => 'Válida até';

  @override
  String get added => 'Adicionada';

  @override
  String get saveBackupJks => 'Salvar backup (.jks)';

  @override
  String get delete => 'Excluir';

  @override
  String get releaseKeys => 'Chaves de lançamento';

  @override
  String get createKey => 'Criar chave';

  @override
  String get importKeystoreFile => 'Importar .jks / .keystore / .p12';

  @override
  String get noReleaseKeys => 'Nenhuma chave de lançamento ainda';

  @override
  String get createReleaseKey => 'Criar chave de lançamento';

  @override
  String get keyAlias => 'Alias da chave';

  @override
  String get keyAliasHelp => 'Letras, dígitos, pontos, hifens e sublinhados';

  @override
  String get publisherNameField => 'Seu nome ou editor do app';

  @override
  String get required => 'Obrigatório';

  @override
  String get organizationOptional => 'Organização (opcional)';

  @override
  String get countryCodeOptional => 'Código do país (opcional)';

  @override
  String get password => 'Senha';

  @override
  String get passwordHelp => 'Usada para o keystore e a chave';

  @override
  String get repeatPassword => 'Repita a senha';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get createKeyNote =>
      'RSA de 2048 bits, válida por 30 anos. Você vai precisar desta senha para usar o backup em um computador.';

  @override
  String get noPrivateKeys => 'Nenhuma chave privada neste arquivo';

  @override
  String get importKeystore => 'Importar keystore';

  @override
  String get keystorePassword => 'Senha do keystore';

  @override
  String get keyPassword => 'Senha da chave';

  @override
  String get keyPasswordHelp => 'Deixe vazio se for igual à senha do keystore';

  @override
  String get importKeystoreNote =>
      'O iLoveHTML guarda uma cópia protegida pela senha do keystore. Seu arquivo original não é alterado.';

  @override
  String get open => 'Abrir';

  @override
  String get deleteReleaseKey => 'Excluir a chave de lançamento?';

  @override
  String get deleteKey => 'Excluir chave';

  @override
  String get projectNotFound => 'Projeto não encontrado';

  @override
  String get backUpProject => 'Fazer backup do projeto';

  @override
  String get preview => 'Prévia';

  @override
  String get build => 'Compilar';

  @override
  String get previewInBrowser => 'Prévia no navegador';

  @override
  String get liveSiteOpened => 'O site ao vivo abriu no seu navegador padrão.';

  @override
  String get servedFromPc =>
      'Servido só deste PC, enquanto esta janela estiver aberta. O app do celular adiciona um console e verificação de links; aqui use as ferramentas de desenvolvedor do navegador (F12).';

  @override
  String get missingFiles => 'Arquivos faltando:';

  @override
  String get close => 'Fechar';

  @override
  String get stopPreview => 'Parar prévia';

  @override
  String get settingsSaved => 'Configurações salvas';

  @override
  String get iconUpdated => 'Ícone atualizado';

  @override
  String get splashUpdated => 'Imagem de abertura atualizada';

  @override
  String get offlinePageAdded => 'Página off-line adicionada';

  @override
  String get deleteProjectQ => 'Excluir o projeto?';

  @override
  String get save => 'Salvar';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionContent => 'Conteúdo';

  @override
  String get sectionShortcuts => 'Atalhos';

  @override
  String get sectionAppSize => 'Tamanho do app';

  @override
  String get sectionAppearance => 'Aparência';

  @override
  String get sectionDevices => 'Dispositivos';

  @override
  String get sectionSecurity => 'Segurança';

  @override
  String get sectionOffline => 'Off-line';

  @override
  String get sectionDanger => 'Zona de perigo';

  @override
  String get versionName => 'Nome da versão';

  @override
  String get versionCode => 'Código da versão';

  @override
  String get defaultIcon => 'Ícone padrão';

  @override
  String get customIcon => 'Ícone personalizado';

  @override
  String get chooseImage => 'Escolher imagem';

  @override
  String get iconHint =>
      'PNG, JPEG, WebP, GIF, BMP ou SVG, com pelo menos 48 px; 512 × 512 recomendado. Imagens não quadradas são centralizadas.';

  @override
  String get startPage => 'Página inicial';

  @override
  String get loadedLive =>
      'Carregado ao vivo; o app precisa de conexão com a internet.';

  @override
  String get otherSites => 'Outros sites que abrem dentro do app (opcional)';

  @override
  String get otherSitesHelp =>
      'Separados por vírgula. Links para qualquer outro site abrem no navegador.';

  @override
  String get bridgeSites =>
      'Sites que também podem compartilhar, salvar arquivos e notificar (opcional)';

  @override
  String get bridgeSitesHelp =>
      'Separados por vírgula, da lista acima. Seu próprio site sempre pode. Deixe de fora sites de login e de pagamento.';

  @override
  String bridgeSiteNotListed(String host) {
    return '\"$host\" não está na lista acima';
  }

  @override
  String get orientation => 'Orientação';

  @override
  String get orientationAuto => 'Auto';

  @override
  String get portrait => 'Retrato';

  @override
  String get landscape => 'Paisagem';

  @override
  String get shortcutsHint =>
      'Toque e segure o ícone do app para ver estas páginas.';

  @override
  String get removeShortcut => 'Remover atalho';

  @override
  String get addShortcut => 'Adicionar atalho';

  @override
  String get optimizeFiles => 'Otimizar arquivos ao compilar';

  @override
  String get optimizeFilesHint =>
      'Deixa arquivos CSS, JSON, PNG e JPEG grandes menores no app. JPEGs são salvos de novo com 85% de qualidade. Os arquivos do seu projeto não mudam.';

  @override
  String get sizeReport => 'Relatório de tamanho';

  @override
  String get statusBarColour => 'Cor da barra de status';

  @override
  String get navBarColour => 'Cor da barra de navegação';

  @override
  String get splashScreen => 'Tela de abertura';

  @override
  String get splashIconHint =>
      'Mostra o ícone do app até a primeira página carregar.';

  @override
  String get splashImageHint =>
      'Mostra sua imagem de abertura até a primeira página carregar.';

  @override
  String get splashBackground => 'Fundo da abertura';

  @override
  String get chooseSplash => 'Escolher imagem de abertura';

  @override
  String get replaceSplash => 'Trocar imagem de abertura';

  @override
  String get useAppIcon => 'Usar ícone do app';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get followPhone => 'Seguir o celular';

  @override
  String get themeHint =>
      'Define prefers-color-scheme, para que páginas com CSS de modo escuro mudem para ele.';

  @override
  String get fullscreen => 'Tela cheia';

  @override
  String get fullscreenHint =>
      'Oculta as barras de status e navegação. Deslize da borda para vê-las por um momento.';

  @override
  String get keepScreenOn => 'Manter tela ligada';

  @override
  String get keepScreenOnHint =>
      'A tela não desliga enquanto o app está aberto.';

  @override
  String get tvHint =>
      'Mostra o app na tela inicial da TV com um banner feito do ícone e do nome. As setas do controle remoto se movem entre links e botões; OK abre.';

  @override
  String get rotateTablets => 'Girar livremente em tablets';

  @override
  String get rotateTabletsHint =>
      'Tablets e dobráveis podem girar para qualquer lado, mesmo quando celulares mantêm a orientação escolhida acima. O Android 16 e posteriores sempre permitem isso em telas grandes.';

  @override
  String get desktopLayout => 'Layout de computador em tablets e TV';

  @override
  String get desktopLayoutHint =>
      'Pede aos sites o layout que mostram em computadores em vez do layout de celular.';

  @override
  String get appLock => 'Bloqueio do app';

  @override
  String get appLockHint =>
      'Pede a digital, o rosto ou o bloqueio de tela quando o app abre e após 30 segundos em segundo plano. Celulares sem bloqueio de tela abrem o app com um aviso.';

  @override
  String get javascriptHint =>
      'A maioria dos sites precisa disso. Desative para páginas estáticas.';

  @override
  String get localStorage => 'Armazenamento local';

  @override
  String get internetAccess => 'Acesso à internet';

  @override
  String get internetAccessHint =>
      'Adiciona a permissão INTERNET, para CDNs, APIs ou fontes carregadas da web.';

  @override
  String get openOtherSites => 'Abrir outros sites no navegador';

  @override
  String get openOtherSitesHint =>
      'Quando desativado, links para outros sites não fazem nada.';

  @override
  String get pullToRefresh => 'Puxar para atualizar';

  @override
  String get pullToRefreshHint =>
      'Deslize para baixo no topo de uma página para recarregá-la ou tentar de novo após um erro.';

  @override
  String get notifications => 'Notificações';

  @override
  String get notificationsHint =>
      'A página pode usar a API web Notification para mostrar notificações do Android enquanto o app está aberto. O Android 13+ pergunta ao usuário antes. Sem mensagens push.';

  @override
  String get backButton => 'Botão Voltar';

  @override
  String get backHistory => 'Voltar e depois fechar o app';

  @override
  String get backTwice => 'Voltar e depois tocar duas vezes para fechar';

  @override
  String get backConfirm => 'Voltar e depois perguntar antes de fechar';

  @override
  String get backHome => 'Ir para a página inicial e depois fechar';

  @override
  String get fileUploads => 'Envio de arquivos';

  @override
  String get fileUploadsHint =>
      'Permite que campos de arquivo abram o seletor do Android. O usuário escolhe cada arquivo.';

  @override
  String get share => 'Compartilhar';

  @override
  String get shareHint =>
      'navigator.share abre o menu de compartilhamento do Android para texto e links.';

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadsHint =>
      'Links de download e arquivos gerados são salvos na pasta Downloads.';

  @override
  String get shareFiles => 'Compartilhar imagens e PDFs';

  @override
  String get galleryFolder => 'Pasta da galeria (opcional)';

  @override
  String get galleryFolderExample => 'ex.: Minhas fotos';

  @override
  String get galleryFolderHelp =>
      'Pictures/<pasta> para imagens compartilhadas e baixadas. Vazio: o nome do app para compartilhamentos, Downloads para downloads.';

  @override
  String get shareToApp => 'Compartilhar direto com um app (opcional)';

  @override
  String get shareToAppHelp =>
      'Pacote que abre os arquivos compartilhados diretamente quando instalado, em vez do menu de compartilhamento.';

  @override
  String get usePackageName => 'Use um nome de pacote como com.whatsapp';

  @override
  String get offlineBuiltIn =>
      'Quando o site não carrega, uma tela integrada \"Página indisponível\" é exibida.';

  @override
  String get chooseOfflinePage => 'Escolher página off-line (.html)';

  @override
  String get replaceOfflinePage => 'Trocar página off-line';

  @override
  String get useBuiltInPage => 'Usar página integrada';

  @override
  String get userAgentSuffix => 'Sufixo do user agent (opcional)';

  @override
  String get atMost200 => 'No máximo 200 caracteres';

  @override
  String get deleteProject => 'Excluir projeto';

  @override
  String get useColourLike => 'Use uma cor como #1A73E8';

  @override
  String get noNetwork =>
      'Este computador não está em uma rede Wi-Fi ou Ethernet.';

  @override
  String get installOnPhone => 'Instalar no celular';

  @override
  String get installSteps =>
      '1. Conecte o celular ao mesmo Wi-Fi deste computador.\n2. Escaneie o código com a câmera do celular e abra o link.\n3. Abra o arquivo baixado. Permita instalações pelo navegador se o Android pedir.';

  @override
  String get linkStopped => 'O link parou.';

  @override
  String get networkAddress => 'Endereço de rede';

  @override
  String get linkWorks10Min =>
      'O link funciona por 10 minutos enquanto esta janela estiver aberta.';

  @override
  String get trustedNetworkOnly =>
      'Use isto só em uma rede confiável. O Windows pode pedir para liberar o iLoveHTML no firewall: libere para redes privadas.';

  @override
  String get startAgain => 'Começar de novo';

  @override
  String get done => 'Concluído';

  @override
  String get kindPages => 'Páginas';

  @override
  String get kindImages => 'Imagens';

  @override
  String get kindFonts => 'Fontes';

  @override
  String get kindMedia => 'Áudio e vídeo';

  @override
  String get kindData => 'Dados';

  @override
  String get kindOther => 'Outros';

  @override
  String get largestFiles => 'Maiores arquivos';

  @override
  String get advice => 'Dicas';

  @override
  String get checkOptimizing => 'Ver quanto a otimização economiza';

  @override
  String get name => 'Nome';

  @override
  String get exampleCart => 'ex.: Carrinho';

  @override
  String get choosePage => 'Escolha uma página';

  @override
  String get page => 'Página';

  @override
  String get add => 'Adicionar';

  @override
  String get differentKey => 'Chave de lançamento diferente';

  @override
  String get buildAnyway => 'Compilar mesmo assim';

  @override
  String get windowsExe => 'App do Windows (.exe)';

  @override
  String get exeDescription =>
      'Um único arquivo .exe que abre este site em sua própria janela com o Microsoft Edge WebView2 (incluído no Windows 11 e no Windows 10 atualizado). Ele não é assinado, então o Windows pode mostrar \"O Windows protegeu o computador\" até a pessoa escolher Mais informações → Executar assim mesmo.';

  @override
  String get devTools => 'Ferramentas de desenvolvedor (para testes)';

  @override
  String get devToolsHint =>
      'F12 e Inspecionar funcionam no app; deixe desativado na versão que você compartilhar';

  @override
  String get buildExe => 'Compilar .exe';

  @override
  String get windowsMsix => 'Instalador do Windows (.msix)';

  @override
  String get msixDescription =>
      'Instala o app como outros programas do Windows: entrada no menu Iniciar, desinstalação limpa e atualizações quando você compartilha uma versão maior. Todo instalador é assinado com um certificado.';

  @override
  String get needsWindowsSdk =>
      'Requer o Windows SDK. Instale com:\nwinget install Microsoft.WindowsSDK.10.0.26100';

  @override
  String get noCertificate =>
      'Nenhum certificado ainda. Use seu próprio certificado de assinatura de código ou crie um certificado de teste para experimentar.';

  @override
  String get testCertNote =>
      'Certificado de teste: o Windows só instala o app depois que a pessoa confia nele uma vez. Compartilhe o arquivo .cer junto com o instalador; clique duas vezes nele → Instalar Certificado → Máquina Local → \"Pessoas Confiáveis\". Um certificado comprado de uma autoridade certificadora não precisa desse passo.';

  @override
  String get createTestCert => 'Criar certificado de teste';

  @override
  String get useMyPfx => 'Usar meu .pfx';

  @override
  String get savedCertificate => 'Certificado salvo';

  @override
  String get saveCer => 'Salvar .cer';

  @override
  String get buildInstaller => 'Compilar instalador';

  @override
  String get replaceCertQ => 'Substituir o certificado?';

  @override
  String get replace => 'Substituir';

  @override
  String get publisherName => 'Nome do editor';

  @override
  String get publisherNameHelp =>
      'Mostrado como editor quando instalam seus apps.';

  @override
  String get testCertCreated => 'Certificado de teste criado';

  @override
  String get useMyCertificate => 'Usar meu certificado';

  @override
  String get certificateAdded => 'Certificado adicionado';

  @override
  String get ok => 'OK';

  @override
  String get allowUnknownApps =>
      'Permita \"Instalar apps desconhecidos\" para o iLoveHTML na tela que abriu e toque em Instalar de novo.';

  @override
  String get debug => 'Depuração';

  @override
  String get release => 'Lançamento';

  @override
  String get debugHint =>
      'Para testes. Assinado com uma chave de depuração que fica neste dispositivo; não serve para publicar.';

  @override
  String get releaseHint =>
      'Para publicar. Assinado com sua chave de lançamento; toda atualização futura deve usar a mesma chave e um código de versão maior.';

  @override
  String get appBundlePlay => 'App Bundle (Play)';

  @override
  String get aabHint =>
      'Envie o .aab para o Google Play Console. Ele não pode ser instalado diretamente; use um APK para testar no celular.';

  @override
  String get createOrImportKey => 'Criar ou importar uma chave de lançamento';

  @override
  String get releaseKey => 'Chave de lançamento';

  @override
  String get manageKeys => 'Gerenciar chaves';

  @override
  String get buildDebugApk => 'Compilar APK de depuração';

  @override
  String get buildAppBundle => 'Compilar App Bundle';

  @override
  String get buildReleaseApk => 'Compilar APK de lançamento';

  @override
  String get buildingUnavailable =>
      'A compilação ainda não está disponível nesta plataforma.';

  @override
  String get buildFailed => 'Falha na compilação';

  @override
  String get saveAs => 'Salvar como…';

  @override
  String get showInFolder => 'Mostrar na pasta';

  @override
  String get install => 'Instalar';

  @override
  String get saveToDevice => 'Salvar no dispositivo';

  @override
  String get buildLog => 'Log de compilação';

  @override
  String get history => 'Histórico';

  @override
  String get twoLetters => 'Duas letras';

  @override
  String invalidHost(String host) {
    return 'Host inválido \"$host\"';
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
      other: 'Compilando… $count linhas de log',
      one: 'Compilando… 1 linha de log',
      zero: 'Compilando…',
    );
    return '$_temp0';
  }

  @override
  String get themeSystem => 'Sistema';

  @override
  String get accentColour => 'Cor de destaque';

  @override
  String get accentOrange => 'Laranja';

  @override
  String get accentGreen => 'Verde terminal';

  @override
  String get accentCyan => 'Ciano';

  @override
  String get accentViolet => 'Violeta';

  @override
  String get accentPink => 'Rosa';

  @override
  String get animations => 'Animações';

  @override
  String get animationsHint =>
      'Abertura em ASCII, animação de compilação e transições de página';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get signing => 'Assinatura';

  @override
  String get releaseKeysSubtitle =>
      'Crie, importe e faça backup das chaves que assinam suas versões';

  @override
  String get storage => 'Armazenamento';

  @override
  String projectsAndSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projetos · $size',
      one: '1 projeto · $size',
    );
    return '$_temp0';
  }

  @override
  String get buildEngine => 'Motor de compilação';

  @override
  String get notAvailablePlatform => 'Ainda não disponível nesta plataforma';

  @override
  String get gradleReady => 'Gradle neste PC (pronto)';

  @override
  String get gradleNotReady => 'Gradle neste PC: não está pronto';

  @override
  String get buildsRunOnPc =>
      'Tudo é compilado neste PC. Nenhum arquivo é enviado.';

  @override
  String get onDeviceReady => 'Montagem no dispositivo (pronta)';

  @override
  String get onDeviceMissing => 'Montagem no dispositivo: APK base ausente';

  @override
  String get buildsRunOnDevice =>
      'Tudo é compilado neste dispositivo. Nenhum arquivo é enviado.';

  @override
  String get about => 'Sobre';

  @override
  String get howToUse => 'Como usar';

  @override
  String get howToUseSubtitle => 'Do site ao app instalado em cinco passos';

  @override
  String get termsOfUse => 'Termos de uso';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get version => 'Versão';

  @override
  String get versionCopied => 'Versão copiada';

  @override
  String get credit => 'Créditos';

  @override
  String madeBy(String author) {
    return 'Feito com <3 por $author';
  }

  @override
  String get supportHint =>
      'O iLoveHTML é gratuito, sem anúncios e sem rastreamento. Se ele poupa seu tempo, você pode apoiar o desenvolvimento.';

  @override
  String get buyMeACoffee => 'Me pague um café';

  @override
  String couldNotOpenLink(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String lastUpdated(String date) {
    return 'Última atualização: $date';
  }

  @override
  String get howToStep1Title => 'Crie um projeto';

  @override
  String get howToStep1Body =>
      'Toque em Novo app e escolha arquivos HTML, um ZIP de site ou a URL de um site https ao vivo. Arquivos e ZIPs funcionam off-line; uma URL precisa de internet.';

  @override
  String get howToStep2Title => 'Dê um nome ao app';

  @override
  String get howToStep2Body =>
      'Digite o nome do app e um ID de pacote único, como com.seunome.app. Mantenha o mesmo ID de pacote em todas as atualizações.';

  @override
  String get howToStep3Title => 'Personalize';

  @override
  String get howToStep3Body =>
      'Na aba Configurações escolha a página inicial, o ícone, a tela de abertura, as cores, a orientação, os atalhos e os recursos do WebView. Toque em Salvar ao terminar. Use Prévia para testar o app antes.';

  @override
  String get howToStep4Title => 'Compile';

  @override
  String get howToStep4Body =>
      'Na aba Compilar escolha Depuração para testar ou Lançamento para publicar. Versões de lançamento precisam de uma chave: crie-a e faça backup. No Windows você também pode compilar um .exe ou um instalador .msix.';

  @override
  String get howToStep5Title => 'Instale ou compartilhe';

  @override
  String get howToStep5Body =>
      'Instale o APK neste celular, compartilhe ou salve. No PC use Instalar no celular para enviá-lo por Wi-Fi. Envie App Bundles (.aab) para o Google Play Console.';

  @override
  String get howToTipsTitle => 'Dicas';

  @override
  String get howToTips =>
      '• Toda atualização deve usar o mesmo ID de pacote e a mesma chave de lançamento, com um código de versão maior.\n• Faça backup das chaves e dos projetos; ninguém recupera uma chave perdida.\n• Use o Relatório de tamanho para deixar o app menor.\n• Use Fazer backup do projeto (no topo de um projeto) para guardar uma cópia que você pode restaurar depois.';

  @override
  String get termsBody =>
      'Estes Termos de uso se aplicam ao app iLoveHTML (\"o app\"), feito por 1elevenop. Ao usar o app, você concorda com eles.\n\n## O que o app faz\n\nO iLoveHTML transforma arquivos HTML, ZIPs de sites e endereços web em apps Android e Windows. As compilações rodam no seu próprio dispositivo.\n\n## Seu conteúdo\n\nVocê mantém todos os direitos sobre os sites, arquivos, ícones e apps que cria. Você é responsável por ter o direito de usar esse conteúdo e pelos apps que compila e publica, incluindo cumprir a lei e as regras de lojas como o Google Play.\n\n## Uso aceitável\n\nNão use o app para criar software ilegal, prejudicial ou enganoso, ou que viole direitos de terceiros, como malware ou apps que se passam por outras marcas.\n\n## Chaves de lançamento\n\nAs chaves de lançamento ficam somente no seu dispositivo. Você é responsável por fazer backup delas e proteger suas senhas. Uma chave perdida não pode ser recuperada, e os apps assinados com ela não poderão mais ser atualizados.\n\n## Sem garantia\n\nO app é oferecido gratuitamente e \"como está\", sem garantias de nenhum tipo. Na medida permitida por lei, o autor não se responsabiliza por perda de dados, chaves, receita ou outros danos decorrentes do uso.\n\n## Alterações\n\nEstes termos podem mudar com novas versões do app. A data acima mostra a última alteração. Continuar usando o app significa aceitar os termos atualizados.\n\n## Contato\n\nDúvidas: abra uma issue no projeto do iLoveHTML de 1elevenop no GitHub.';

  @override
  String get privacyBody =>
      'O iLoveHTML foi feito para funcionar no seu dispositivo. Esta política explica o que isso significa para seus dados.\n\n## Dados que coletamos\n\nNenhum. O app não tem contas, análises, anúncios nem rastreamento. O autor não recebe nenhum dado sobre você ou seus projetos.\n\n## Dados guardados no seu dispositivo\n\nSeus projetos, arquivos de site, ícones, compilações e configurações ficam no armazenamento privado do app no seu dispositivo. As chaves de lançamento também ficam no seu dispositivo: no Android são criptografadas com o Android Keystore e, no Windows, suas senhas são criptografadas para sua conta do Windows. Desinstalar o app apaga esses dados, então faça backups.\n\n## Uso da rede\n\nO app só se conecta à internet quando você pede: para verificar ou visualizar uma URL que você digitou, para abrir links como o Buy Me a Coffee no navegador e, no Windows, quando o Gradle baixa ferramentas de compilação. O recurso Instalar no celular serve o arquivo na sua rede local por 10 minutos, só enquanto a janela dele estiver aberta.\n\n## Verificação de atualizações\n\nSe \"Verificar atualizações\" estiver ativado (está por padrão), cerca de duas vezes por dia o iLoveHTML pergunta ao GitHub (api.github.com) qual é a versão mais recente do iLoveHTML, para avisar quando sair uma nova. A solicitação não contém conta, identificadores nem nada sobre seus projetos; como qualquer site, o GitHub vê seu endereço IP. Desative em Configurações → Sobre.\n\n## Apps que você cria\n\nApps feitos com o iLoveHTML não contêm rastreamento do iLoveHTML. O que eles coletam depende do site que você coloca neles, e você é responsável pela política de privacidade deles.\n\n## Crianças\n\nO app não coleta dados intencionalmente, nem de crianças nem de ninguém.\n\n## Alterações e contato\n\nEsta política pode mudar com novas versões do app; a data acima mostra a última alteração. Dúvidas: abra uma issue no projeto do iLoveHTML de 1elevenop no GitHub.';

  @override
  String get replaceWebsite => 'Substituir arquivos do site';

  @override
  String get replaceWebsiteHint =>
      'Troque por um novo ZIP ou arquivos HTML. Nome, ID do pacote, ícone, configurações e chaves continuam os mesmos.';

  @override
  String get replaceWithZipHint => 'Uma nova pasta do site, compactada';

  @override
  String get replaceWithFilesHint =>
      'Novas páginas .html com CSS, JavaScript e imagens';

  @override
  String get replaceWebsiteQ => 'Substituir o site?';

  @override
  String replaceWebsiteBody(String name) {
    return 'Todos os arquivos do site de \"$name\" são substituídos pelos que você escolher a seguir. Nome, ID do pacote, versão, ícone, configurações, chave de lançamento e histórico continuam. Compile de novo para ter o app atualizado.';
  }

  @override
  String replaceFailed(String error) {
    return 'Não foi possível substituir o site: $error';
  }

  @override
  String get websiteReplaced => 'Site substituído';

  @override
  String startPageChanged(String page) {
    return '\"$page\" não está nos novos arquivos, então a página inicial mudou.';
  }

  @override
  String shortcutsRemoved(String pages) {
    return 'Atalhos removidos porque as páginas não existem mais: $pages';
  }

  @override
  String get rebuildAfterReplace =>
      'Compile de novo para ter o app atualizado. Para atualizar um app instalado, aumente antes o código da versão.';

  @override
  String get unlockReason => 'Desbloquear o iLoveHTML';

  @override
  String get resetReason =>
      'Confirme que é você para redefinir o bloqueio do iLoveHTML';

  @override
  String wrongSecret(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Incorreto. Restam $count tentativas antes de aguardar.',
      one: 'Incorreto. Resta 1 tentativa antes de aguardar.',
      zero: 'Incorreto. Aguarde antes de tentar de novo.',
    );
    return '$_temp0';
  }

  @override
  String tooManyTries(int seconds) {
    return 'Muitas tentativas erradas. Tente de novo em $seconds s.';
  }

  @override
  String get enterPin => 'Digite seu PIN';

  @override
  String get enterPassword => 'Digite sua senha';

  @override
  String get showPassword => 'Mostrar';

  @override
  String get hidePassword => 'Ocultar';

  @override
  String hintIs(String hint) {
    return 'Dica: $hint';
  }

  @override
  String get showHint => 'Ver dica';

  @override
  String get deleteDigit => 'Apagar';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get useFingerprint => 'Usar digital ou rosto';

  @override
  String get forgotPin => 'Esqueceu o PIN?';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String digitsEntered(int count) {
    return '$count dígitos digitados';
  }

  @override
  String wrongRecoveryCode(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Código incorreto. Restam $count tentativas.',
      one: 'Código incorreto. Resta 1 tentativa.',
      zero: 'Código incorreto. Aguarde antes de tentar de novo.',
    );
    return '$_temp0';
  }

  @override
  String get forgotWithDevice => 'Usar o bloqueio deste dispositivo';

  @override
  String get forgotWithDeviceHint =>
      'Confirme com sua digital, rosto ou o bloqueio de tela do celular (PIN, padrão ou senha) e escolha um novo para o iLoveHTML.';

  @override
  String get verifyWithDevice => 'Verificar com o bloqueio do dispositivo';

  @override
  String get forgotWithCode => 'Usar seu código de recuperação';

  @override
  String get forgotWithCodeHint =>
      'O código de 16 caracteres mostrado ao configurar o bloqueio.';

  @override
  String get recoveryCode => 'Código de recuperação';

  @override
  String get useRecoveryCode => 'Usar código';

  @override
  String get forgotNoWay =>
      'Sem nenhum dos dois, o bloqueio só pode ser removido limpando os dados do iLoveHTML nas configurações do sistema. Isso apaga todos os projetos e chaves de lançamento deste dispositivo.';

  @override
  String get pinDigitsOnly => 'Apenas dígitos';

  @override
  String pinLength(int min, int max) {
    return 'De $min a $max dígitos';
  }

  @override
  String passwordMinLength(int count) {
    return 'Pelo menos $count caracteres';
  }

  @override
  String get chooseNewSecret => 'Escolha um novo PIN ou senha';

  @override
  String get setUpAppLock => 'Configurar o bloqueio';

  @override
  String get pin => 'PIN';

  @override
  String get newPin => 'Novo PIN';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get repeatPin => 'Repita o PIN';

  @override
  String get pinsDoNotMatch => 'Os PINs não coincidem';

  @override
  String get hintOptional => 'Dica (opcional)';

  @override
  String get hintHelp =>
      'Mostrada na tela de bloqueio para ajudar você a lembrar. Qualquer pessoa com o aparelho pode ler.';

  @override
  String get hintGivesAway => 'A dica não pode conter o PIN ou a senha';

  @override
  String get unlockWithFingerprint => 'Desbloquear com digital ou rosto';

  @override
  String get unlockWithFingerprintHint =>
      'Seu PIN ou senha continua funcionando.';

  @override
  String get appLockNote =>
      'O bloqueio esconde o iLoveHTML e seus projetos de quem pegar este dispositivo. Ele não criptografa os arquivos dos projetos.';

  @override
  String get saveAndContinue => 'Salvar';

  @override
  String get recoveryCodeTitle => 'Guarde seu código de recuperação';

  @override
  String get recoveryCodeBody =>
      'Se você esquecer o PIN ou a senha, este código permite criar um novo. Ele só aparece agora. Anote ou guarde em um lugar seguro, não só neste dispositivo.';

  @override
  String get copy => 'Copiar';

  @override
  String get iSavedTheCode => 'Guardei o código';

  @override
  String get enterCurrentPin => 'Digite o PIN atual';

  @override
  String get enterCurrentPassword => 'Digite a senha atual';

  @override
  String get wrongPin => 'PIN incorreto';

  @override
  String get wrongPassword => 'Senha incorreta';

  @override
  String get appLockOffHint =>
      'Desativado. Peça PIN, senha ou digital antes de abrir o iLoveHTML.';

  @override
  String get appLockOnPin => 'Ativado, com PIN';

  @override
  String get appLockOnPassword => 'Ativado, com senha';

  @override
  String get lockAgainAfter => 'Bloquear de novo ao sair do app';

  @override
  String get relockImmediately => 'Imediatamente';

  @override
  String relockMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Após $count minutos',
      one: 'Após 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get relockLaunchOnly => 'Só quando o iLoveHTML inicia';

  @override
  String get changePinOrHint => 'Alterar PIN, senha ou dica';

  @override
  String get lockNow => 'Bloquear agora';

  @override
  String get turnOffLock => 'Desativar bloqueio';

  @override
  String get newUpdate => 'NOVA ATUALIZAÇÃO';

  @override
  String updateAvailable(String version) {
    return 'O iLoveHTML $version está disponível';
  }

  @override
  String updateTitle(String version) {
    return 'Atualizar para $version';
  }

  @override
  String youHaveVersion(String version) {
    return 'Você tem a $version.';
  }

  @override
  String get updateAndroidHint =>
      'O APK é baixado no navegador. Abra-o para instalar sobre esta versão; seus projetos, chaves e configurações continuam.';

  @override
  String get updateWindowsHint =>
      'O ZIP é baixado no navegador. Feche o iLoveHTML, descompacte e substitua a pasta do iLoveHTML; seus projetos, chaves e configurações continuam.';

  @override
  String get whatsNew => 'Novidades';

  @override
  String get releasePage => 'Página da versão';

  @override
  String get downloadUpdate => 'Baixar';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get checkForUpdatesHint =>
      'Cerca de duas vezes por dia, pergunta ao GitHub se saiu um iLoveHTML mais novo. Nada sobre você ou seus projetos é enviado.';

  @override
  String get checkNow => 'Verificar agora';

  @override
  String get checkingUpdates => 'Verificando…';

  @override
  String get upToDate => 'Você tem a versão mais recente.';

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar. Você está on-line?';

  @override
  String get updateInAppHint =>
      'O iLoveHTML baixa a atualização, verifica e o Android pede para instalá-la sobre esta versão. Seus projetos, chaves e configurações continuam.';

  @override
  String get verifyingDownload => 'Verificando o arquivo…';

  @override
  String downloadingMb(String done) {
    return 'Baixando… $done MB';
  }

  @override
  String downloadingOf(String done, String total) {
    return 'Baixando… $done de $total MB';
  }

  @override
  String get installerOpened =>
      'O instalador do Android está aberto. Toque em Atualizar. Se ele fechou, toque em Instalar.';

  @override
  String downloadFailed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get openInBrowser => 'Abrir no navegador';

  @override
  String get tryAgain => 'Tentar de novo';
}

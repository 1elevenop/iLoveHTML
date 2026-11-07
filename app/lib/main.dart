import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'l10n/gen/app_localizations.dart';
import 'src/app_controller.dart';
import 'src/app_lock.dart';
import 'src/app_settings.dart';
import 'src/update_check.dart';
import 'package:html2apk_core/html2apk_core.dart';

import 'src/engine/desktop_engine.dart';
import 'src/engine/on_device_engine.dart';
import 'src/ui/ascii.dart';
import 'src/ui/lock_screens.dart';
import 'src/ui/projects_screen.dart';
import 'src/ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On Android this is <app>/files, which the FileProvider and the engine expect.
  final support = await getApplicationSupportDirectory();
  final workspace = p.join(support.path, 'workspace');
  final settings = await AppSettings.load();
  final lock = await AppLock.load();
  final updates = await UpdateChecker.load();
  final controller = AppController(
    workspaceDir: workspace,
    settings: settings,
    lock: lock,
    updates: updates,
    engine: Platform.isAndroid
        ? OnDeviceBuildEngine()
        : Platform.isWindows
            ? DesktopBuildEngine(
                workspaceDir: workspace,
                toolchainReport: discoverToolchain(),
                // Installed next to the executable by windows/CMakeLists.txt.
                templateDir: p.join(p.dirname(Platform.resolvedExecutable), 'android_template'),
              )
            : null,
  );
  runApp(Html2ApkApp(controller: controller, showSplash: true));
  // In the background; at most every 12 hours, and only if the user allows it.
  if (settings.checkUpdates) unawaited(updates.checkIfDue());
}

class Html2ApkApp extends StatelessWidget {
  const Html2ApkApp({super.key, required this.controller, this.showSplash = false});

  final AppController controller;

  /// Play the ASCII logo before the project list (once, at launch).
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, settings]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness: Brightness.light, accent: settings.accent, animations: settings.animations),
        darkTheme: buildTheme(brightness: Brightness.dark, accent: settings.accent, animations: settings.animations),
        themeMode: settings.themeMode,
        themeAnimationDuration: settings.animations ? kThemeAnimationDuration : Duration.zero,
        locale: settings.locale,
        supportedLocales: AppSettings.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Above the navigator, so every screen and dialog is covered.
        builder: (context, child) => LockGate(lock: controller.lock, child: child!),
        home: showSplash
            ? AsciiSplash(settings: settings, child: ProjectsScreen(controller: controller))
            : ProjectsScreen(controller: controller),
      ),
    );
  }
}

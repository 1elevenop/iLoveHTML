import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'src/app_controller.dart';
import 'package:html2apk_core/html2apk_core.dart';

import 'src/engine/desktop_engine.dart';
import 'src/engine/on_device_engine.dart';
import 'src/ui/projects_screen.dart';
import 'src/ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On Android this is <app>/files, which the FileProvider and the engine expect.
  final support = await getApplicationSupportDirectory();
  final workspace = p.join(support.path, 'workspace');
  final controller = AppController(
    workspaceDir: workspace,
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
  runApp(Html2ApkApp(controller: controller));
}

class Html2ApkApp extends StatelessWidget {
  const Html2ApkApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: 'HTML2APK',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: controller.themeMode,
        home: ProjectsScreen(controller: controller),
      ),
    );
  }
}

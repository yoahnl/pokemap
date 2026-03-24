import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import 'src/ui/editor_shell_page.dart';

Future<void> main() async {
  if (!kIsWeb && Platform.isMacOS) {
    await const MacosWindowUtilsConfig(
      toolbarStyle: NSWindowToolbarStyle.unified,
    ).apply();
    // La config ajoute une NSToolbar vide : elle masquait toute la zone d’outils Flutter.
    await WindowManipulator.removeToolbar();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  runApp(
    const ProviderScope(
      child: MapEditorApp(),
    ),
  );
}

class MapEditorApp extends StatelessWidget {
  const MapEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'RPG Map Editor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      home: const EditorShellPage(),
    );
  }
}

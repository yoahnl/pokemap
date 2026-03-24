import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show ThemeMode, VisualDensity;
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

  MacosThemeData _buildLightTheme() {
    return MacosThemeData.light().copyWith(
      accentColor: AccentColor.blue,
      primaryColor: const Color(0xFF3D88FF),
      canvasColor: const Color(0xFFF4F6FB),
      dividerColor: const Color(0x14000000),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -0.25),
    );
  }

  MacosThemeData _buildDarkTheme() {
    return MacosThemeData.dark().copyWith(
      accentColor: AccentColor.blue,
      primaryColor: const Color(0xFF4C9CFF),
      canvasColor: const Color(0xFF0B1018),
      dividerColor: const Color(0x1FFFFFFF),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -0.25),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MacosApp(
      title: 'RPG Map Editor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const EditorShellPage(),
    );
  }
}

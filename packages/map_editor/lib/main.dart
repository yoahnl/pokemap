import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart' show MacosWindowUtilsConfig, NSWindowToolbarStyle, WindowManipulator;

import 'src/theme/theme.dart';
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

/// The root widget of the PokeMap Editor application.
///
/// Migrated from [MacosApp] to [MaterialApp] to serve as the unified root
/// for the custom design system. Underneath, a [PokeMapMacosCompatibilityBridge]
/// is inserted to satisfy the styling needs of legacy [macos_ui] components.
class MapEditorApp extends StatelessWidget {
  const MapEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Map Editor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      home: const PokeMapMacosCompatibilityBridge(
        child: EditorShellPage(),
      ),
    );
  }
}

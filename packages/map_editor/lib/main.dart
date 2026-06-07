import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/theme/theme.dart';
import 'src/ui/editor_shell_page.dart';

Future<void> main() async {
  // Ensure the binding is initialized at the absolute beginning of main()
  WidgetsFlutterBinding.ensureInitialized();


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
/// is configured inside [MaterialApp.builder] to ensure all pages, overlays,
/// dialogs, and routes can resolve legacy [MacosTheme] properties safely.
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

      home: const EditorShellPage(),
    );
  }
}

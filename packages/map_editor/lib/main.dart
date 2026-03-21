import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/ui/editor_shell_page.dart';

void main() {
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
    return MaterialApp(
      title: 'RPG Map Editor',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EditorShellPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

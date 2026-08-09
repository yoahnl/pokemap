import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/features/editor_updates/presentation/editor_update_host.dart';
import 'src/infrastructure/riverpod_retry_policy.dart';
import 'src/theme/theme.dart';
import 'src/ui/editor_shell_page.dart';

Future<void> main() async {
  // Ensure the binding is initialized at the absolute beginning of main()
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      retry: disableAutomaticProviderRetry,
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      home: const EditorUpdateHost(
        child: EditorShellPage(),
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/project_session/application/project_session_controller.dart';
import '../features/project_session/presentation/project_session_screen.dart';
import '../shared/design_system/studio_theme.dart';

class StudioApp extends StatefulWidget {
  const StudioApp({
    super.key,
    required this.createSession,
    required this.chooseDirectory,
  });

  final ProjectSessionController Function() createSession;
  final Future<String?> Function() chooseDirectory;

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  late final ProjectSessionController _session;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _session = widget.createSession();
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await _session.dispose();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Avelune Studio',
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ProjectSessionScreen(
      session: _session,
      chooseDirectory: widget.chooseDirectory,
    ),
  );
}

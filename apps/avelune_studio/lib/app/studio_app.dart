import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'di/home_providers.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';

class StudioApp extends ConsumerStatefulWidget {
  const StudioApp({super.key, this.workspaceBuilder});

  final Widget Function(
    ProjectSession,
    Future<void> Function(),
    void Function(Future<bool> Function()?),
  )?
  workspaceBuilder;

  @override
  ConsumerState<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends ConsumerState<StudioApp> {
  late final ProjectSessionController _session;
  late final AppLifecycleListener _lifecycle;
  Future<bool> Function()? _exitGuard;
  String? _guardSession;

  @override
  void initState() {
    super.initState();
    _session = ref.read(projectSessionControllerProvider);
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        if (_exitGuard != null && !await _exitGuard!()) {
          return AppExitResponse.cancel;
        }
        await _session.dispose();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
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
      recentProjects: ref.watch(recentProjectsPortProvider),
      session: _session,
      chooseDirectory: ref.watch(projectDirectoryPickerProvider),
      workspaceBuilder: widget.workspaceBuilder == null
          ? null
          : (session, close) =>
                widget.workspaceBuilder!(session, close, (guard) {
                  if (guard != null) {
                    _exitGuard = guard;
                    _guardSession = session.sessionId;
                  } else if (_guardSession == session.sessionId) {
                    _exitGuard = null;
                    _guardSession = null;
                  }
                }),
    ),
  );
}

import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/rendering/contracts/studio_rendering_preferences_scope.dart';
import '../presentation/shell/studio_root.dart';
import 'di/studio_lifecycle_providers.dart';
import 'studio_lifecycle_controller.dart';

class StudioApp extends ConsumerStatefulWidget {
  const StudioApp({super.key});

  @override
  ConsumerState<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends ConsumerState<StudioApp> {
  late final StudioLifecycleController _lifecycle;
  late final AppLifecycleListener _appLifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = ref.read(studioLifecycleControllerProvider);
    unawaited(_lifecycle.start());
    ref.read(studioUpdateControllerProvider);
    _appLifecycle = AppLifecycleListener(
      onExitRequested: () async => await _lifecycle.prepareForExit()
          ? AppExitResponse.exit
          : AppExitResponse.cancel,
    );
  }

  @override
  void dispose() {
    _appLifecycle.dispose();
    unawaited(_lifecycle.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Avelune Studio',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => StudioRenderingPreferencesScope(
      preferences: _lifecycle.renderingPreferences,
      child: child ?? const SizedBox(),
    ),
    theme: studioTheme(),
    home: const StudioRoot(),
  );
}

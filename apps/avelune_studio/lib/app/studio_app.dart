import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/studio_appearance_preferences.dart';
import '../l10n/app_localizations.dart';
import '../presentation/shared/localization/studio_locale.dart';
import 'di/language_providers.dart';
import '../presentation/shell/studio_root.dart';
import 'di/studio_lifecycle_providers.dart';
import 'di/studio_settings_providers.dart';
import 'studio_lifecycle_controller.dart';

class StudioApp extends ConsumerStatefulWidget {
  const StudioApp({super.key});

  @override
  ConsumerState<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends ConsumerState<StudioApp> {
  static final _lightTheme = studioTheme(brightness: Brightness.light);
  static final _darkTheme = studioTheme();
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
  Widget build(BuildContext context) {
    final language = ref.watch(studioLanguagePreferencesProvider);
    final appearance = ref.watch(studioAppearancePreferencesProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([language, appearance]),
      builder: (context, _) => MaterialApp(
        title: 'Avelune Studio',
        debugShowCheckedModeBanner: false,
        locale: studioLocaleFor(language.languageCode),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        localeResolutionCallback: (requested, _) =>
            resolveStudioLocale(requested),
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: switch (appearance.appearance) {
          StudioAppearance.dark => ThemeMode.dark,
          StudioAppearance.light => ThemeMode.light,
        },
        home: const StudioRoot(),
      ),
    );
  }
}

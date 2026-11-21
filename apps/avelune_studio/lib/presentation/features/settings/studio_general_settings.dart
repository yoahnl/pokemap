import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/language_providers.dart';
import '../../../app/di/rendering_providers.dart';
import '../../../features/language/coordination/studio_language_preferences.dart';
import '../../../features/rendering/coordination/studio_rendering_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/localization/studio_locale.dart';

class StudioLanguageSettings extends ConsumerStatefulWidget {
  const StudioLanguageSettings({super.key});

  @override
  ConsumerState<StudioLanguageSettings> createState() =>
      _StudioLanguageSettingsState();
}

class _StudioLanguageSettingsState
    extends ConsumerState<StudioLanguageSettings> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(studioLanguagePreferencesProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(studioLanguagePreferencesProvider);
    final l10n = context.l10n;
    const system = 'system';
    final options = {
      system: l10n.languageSystem,
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode: lookupAppLocalizations(locale).languageName,
    };
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => StudioPanel(
        title: l10n.studioSettingsGeneral,
        icon: Icons.language,
        compact: true,
        children: [
          SizedBox(
            width: 260,
            child: StudioSelect(
              key: const ValueKey('studio-settings-language'),
              label: l10n.studioSettingsLanguage,
              value: options.containsKey(preferences.languageCode)
                  ? preferences.languageCode
                  : system,
              options: options,
              onChanged: !preferences.loaded || preferences.saving
                  ? null
                  : (value) => unawaited(
                      preferences.select(value == system ? null : value),
                    ),
            ),
          ),
          if (preferences.saving)
            StudioNotice(l10n.studioSettingsSaving)
          else if (preferences.error case final error?)
            StudioNotice(
              error == StudioLanguageFailure.load
                  ? l10n.studioSettingsReadError
                  : l10n.studioSettingsWriteError,
              isError: true,
            ),
        ],
      ),
    );
  }
}

class StudioDisplaySettings extends ConsumerStatefulWidget {
  const StudioDisplaySettings({super.key});

  @override
  ConsumerState<StudioDisplaySettings> createState() =>
      _StudioDisplaySettingsState();
}

class _StudioDisplaySettingsState extends ConsumerState<StudioDisplaySettings> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(studioRenderingPreferencesProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(studioRenderingPreferencesProvider);
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => StudioPanel(
        title: l10n.studioSettingsDisplay,
        icon: Icons.monitor_outlined,
        compact: true,
        children: [
          Wrap(
            spacing: StudioSpacing.xl,
            runSpacing: StudioSpacing.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: StudioSelect(
                  key: const ValueKey('studio-settings-frame-rate'),
                  label: l10n.studioSettingsFps,
                  value: '${preferences.limit}',
                  options: {
                    for (final limit in AveluneFrameRate.supportedLimits)
                      '$limit': l10n.studioSettingsFramesPerSecond(limit),
                  },
                  onChanged: !preferences.loaded
                      ? null
                      : (value) => unawaited(
                          preferences
                              .setLimit(int.parse(value))
                              .catchError((Object _) {}),
                        ),
                ),
              ),
              Text(l10n.studioSettingsFpsHelp),
            ],
          ),
          if (preferences.saving)
            StudioNotice(l10n.studioSettingsSaving)
          else if (preferences.error case final error?)
            StudioNotice(
              error == StudioRenderingPreferencesFailure.load
                  ? l10n.studioSettingsReadError
                  : l10n.studioSettingsWriteError,
              isError: true,
            ),
        ],
      ),
    );
  }
}

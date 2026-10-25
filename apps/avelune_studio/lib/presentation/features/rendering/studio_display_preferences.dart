import 'dart:async';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/material.dart';

import '../../../features/rendering/application/studio_rendering_preferences.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class StudioRenderingPreferencesScope extends InheritedWidget {
  const StudioRenderingPreferencesScope({
    super.key,
    required this.preferences,
    required super.child,
  });

  final StudioRenderingPreferences preferences;

  static StudioRenderingPreferences? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<StudioRenderingPreferencesScope>()
      ?.preferences;

  @override
  bool updateShouldNotify(StudioRenderingPreferencesScope oldWidget) =>
      oldWidget.preferences != preferences;
}

class StudioDisplayPreferencesButton extends StatelessWidget {
  const StudioDisplayPreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = StudioRenderingPreferencesScope.maybeOf(context);
    return StudioTool(
      label: 'Affichage',
      icon: Icons.display_settings_outlined,
      onPressed: preferences == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (_) => _StudioDisplayPreferences(preferences),
            ),
    );
  }
}

class _StudioDisplayPreferences extends StatelessWidget {
  const _StudioDisplayPreferences(this.preferences);

  final StudioRenderingPreferences preferences;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: preferences,
    builder: (context, _) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: StudioPanel(
          title: 'Affichage',
          icon: Icons.display_settings_outlined,
          actions: [
            StudioTool(
              label: 'Fermer les préférences d’affichage',
              icon: Icons.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          children: [
            const Text(
              'La fluidité choisie s’applique à Studio, aux aperçus et aux tests de jeu sur cet appareil.',
            ),
            const SizedBox(height: 16),
            StudioSelect(
              label: 'Fluidité',
              value: preferences.limit.toString(),
              options: {
                for (final limit in AveluneFrameRate.supportedLimits)
                  '$limit': '$limit images/s',
              },
              onChanged: !preferences.loaded
                  ? null
                  : (value) => unawaited(
                      preferences
                          .setLimit(int.parse(value))
                          .catchError((Object _) {}),
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La fréquence réelle dépend de l’écran et des performances de l’appareil.',
            ),
            const SizedBox(height: 12),
            if (!preferences.loaded)
              const StudioNotice('Chargement des préférences…')
            else if (preferences.saving)
              const StudioNotice('Enregistrement…')
            else if (preferences.error case final error?)
              StudioNotice(error, isError: true)
            else if (preferences.hasSaved)
              const Text('Préférence enregistrée sur cet appareil.'),
          ],
        ),
      ),
    ),
  );
}

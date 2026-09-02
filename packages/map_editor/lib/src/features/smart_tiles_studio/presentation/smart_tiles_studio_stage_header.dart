import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_draft_persistence_state.dart';
import '../application/smart_tile_studio_launch_context.dart';
import '../application/smart_tile_studio_session.dart';

class SmartTilesStudioStageHeader extends StatelessWidget {
  const SmartTilesStudioStageHeader({
    super.key,
    required this.step,
    required this.launchContext,
    this.usage,
    this.persistenceState,
    this.useSimplePathFlow = true,
  });

  final SmartTileStudioWizardStep step;
  final SmartTilesStudioLaunchContext launchContext;
  final SmartTileUsage? usage;
  final SmartTileDraftPersistenceState? persistenceState;
  final bool useSimplePathFlow;

  @override
  Widget build(BuildContext context) {
    final savePresentation = _savePresentation(persistenceState);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: usage == SmartTileUsage.path && useSimplePathFlow
              ? 'Construire un chemin'
              : 'Nouveau Smart Tile',
          description: usage == SmartTileUsage.path
              ? 'Créez un chemin pas à pas. Les réglages techniques sont proposés automatiquement.'
              : 'Parcours guidé avec des réglages conseillés à chaque étape.',
          trailing: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              PokeMapBadge(
                key: const Key('smart-tiles-launch-context'),
                label: launchContext is SmartTilesStudioMapContext
                    ? 'Carte capturée'
                    : 'Bibliothèque',
                variant: PokeMapBadgeVariant.neutral,
              ),
              PokeMapBadge(
                key: const Key('smart-tiles-save-state'),
                label: savePresentation.label,
                variant: savePresentation.variant,
              ),
              if (usage != null)
                PokeMapBadge(
                  key: const Key('smart-tiles-guided-usage'),
                  label: switch (usage!) {
                    SmartTileUsage.terrain => 'Terrain guidé',
                    SmartTileUsage.path => 'Chemin guidé',
                    SmartTileUsage.forestSurface => 'Surface guidée',
                  },
                  variant: PokeMapBadgeVariant.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (usage == SmartTileUsage.path && useSimplePathFlow)
          _QuickPathSteps(step: step)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final candidate in SmartTileStudioWizardStep.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PokeMapBadge(
                      label:
                          '${candidate.index + 1}. ${smartTileWizardStepLabel(candidate)}',
                      variant: candidate == step
                          ? PokeMapBadgeVariant.info
                          : PokeMapBadgeVariant.neutral,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickPathSteps extends StatelessWidget {
  const _QuickPathSteps({required this.step});

  final SmartTileStudioWizardStep step;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'Image',
      'Patron',
      'Remplir le patron',
      'Essai',
    ];
    final active = switch (step) {
      SmartTileStudioWizardStep.usage ||
      SmartTileStudioWizardStep.image ||
      SmartTileStudioWizardStep.grid ||
      SmartTileStudioWizardStep.materials =>
        0,
      SmartTileStudioWizardStep.connections => 1,
      SmartTileStudioWizardStep.variants ||
      SmartTileStudioWizardStep.forms =>
        2,
      SmartTileStudioWizardStep.test ||
      SmartTileStudioWizardStep.publish =>
        3,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (var index = 0; index < labels.length; index += 1) ...[
            PokeMapBadge(
              label: index < active ? '${labels[index]} ✓' : labels[index],
              variant: index == active
                  ? PokeMapBadgeVariant.info
                  : index < active
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.neutral,
            ),
            if (index != labels.length - 1) ...[
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.arrow_right, size: 13),
              const SizedBox(width: 6),
            ],
          ],
        ],
      ),
    );
  }
}

({String label, PokeMapBadgeVariant variant}) _savePresentation(
  SmartTileDraftPersistenceState? state,
) {
  if (state == null) {
    return (
      label: 'Brouillon local',
      variant: PokeMapBadgeVariant.neutral
    );
  }
  return switch (state.phase) {
    SmartTileDraftPersistencePhase.localOnly => (
        label: 'Brouillon local',
        variant: PokeMapBadgeVariant.neutral,
      ),
    SmartTileDraftPersistencePhase.dirty => (
        label: 'Modifications à sauvegarder',
        variant: PokeMapBadgeVariant.warning,
      ),
    SmartTileDraftPersistencePhase.saving => (
        label: 'Sauvegarde…',
        variant: PokeMapBadgeVariant.info,
      ),
    SmartTileDraftPersistencePhase.saved => (
        label: 'Sauvegardé',
        variant: PokeMapBadgeVariant.success,
      ),
    SmartTileDraftPersistencePhase.failed => (
        label: 'Échec de sauvegarde',
        variant: PokeMapBadgeVariant.error,
      ),
    SmartTileDraftPersistencePhase.conflict => (
        label: 'Conflit de version',
        variant: PokeMapBadgeVariant.error,
      ),
  };
}

String smartTileWizardStepLabel(SmartTileStudioWizardStep step) =>
    switch (step) {
      SmartTileStudioWizardStep.usage => 'Objectif',
      SmartTileStudioWizardStep.image => 'Image',
      SmartTileStudioWizardStep.grid => 'Découpage',
      SmartTileStudioWizardStep.materials => 'Peinture',
      SmartTileStudioWizardStep.connections => 'Tracé',
      SmartTileStudioWizardStep.variants => 'Options',
      SmartTileStudioWizardStep.forms => 'Associer',
      SmartTileStudioWizardStep.test => 'Tester',
      SmartTileStudioWizardStep.publish => 'Enregistrer',
    };

import 'package:flutter/cupertino.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_draft_persistence_state.dart';
import '../application/smart_tile_studio_launch_context.dart';
import '../application/smart_tile_studio_session.dart';

class SmartTilesStudioStageHeader extends StatelessWidget {
  const SmartTilesStudioStageHeader({
    super.key,
    required this.step,
    required this.launchContext,
    this.persistenceState,
  });

  final SmartTileStudioWizardStep step;
  final SmartTilesStudioLaunchContext launchContext;
  final SmartTileDraftPersistenceState? persistenceState;

  @override
  Widget build(BuildContext context) {
    final savePresentation = _savePresentation(persistenceState);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Nouveau Smart Tile',
          description: 'Parcours guidé, puis workbench libre à tout moment.',
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
            ],
          ),
        ),
        const SizedBox(height: 10),
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

({String label, PokeMapBadgeVariant variant}) _savePresentation(
  SmartTileDraftPersistenceState? state,
) {
  if (state == null) {
    return (
      label: 'Brouillon local',
      variant: PokeMapBadgeVariant.neutral,
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
      SmartTileStudioWizardStep.usage => 'Usage',
      SmartTileStudioWizardStep.image => 'Image',
      SmartTileStudioWizardStep.grid => 'Grille',
      SmartTileStudioWizardStep.materials => 'Matériaux',
      SmartTileStudioWizardStep.connections => 'Raccords',
      SmartTileStudioWizardStep.variants => 'Variantes',
      SmartTileStudioWizardStep.forms => 'Formes',
      SmartTileStudioWizardStep.test => 'Essai',
      SmartTileStudioWizardStep.publish => 'Publier',
    };

import 'package:map_core/map_core.dart';

import '../../../application/services/narrative_template_catalog.dart';
import 'scene_action_builder.dart';

const _sceneActionBuilderPath =
    'packages/map_editor/lib/src/ui/canvas/scenes/'
    'scene_action_builder.dart';
const _narrativeTemplateCatalogPath =
    'packages/map_editor/lib/src/application/services/'
    'narrative_template_catalog.dart';

ProjectCapabilityTruthAttestation
buildMapEditorNarrativeCommandAuthoringAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  const Type controlType = SceneActionBuilder;
  final controlSymbol = controlType.toString();
  final SceneActionPayload Function(Map<String, String>) railJourneyBuilder =
      buildSceneRailJourneyPayload;
  if (railJourneyBuilder != buildSceneRailJourneyPayload) {
    throw StateError('RailJourney authoring builder is unavailable.');
  }
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.editor ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: command.id == NarrativeCommandIds.railJourney
              ? '$_narrativeTemplateCatalogPath#buildSceneRailJourneyPayload'
              : '$_sceneActionBuilderPath#$controlSymbol',
    },
  );
}

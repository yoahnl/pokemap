import 'package:map_core/map_core.dart';

import 'scene_action_builder.dart';

const _sceneActionBuilderPath = 'packages/map_editor/lib/src/ui/canvas/scenes/'
    'scene_action_builder.dart';

ProjectCapabilityTruthAttestation
    buildMapEditorNarrativeCommandAuthoringAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  const Type controlType = SceneActionBuilder;
  final controlSymbol = controlType.toString();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.editor ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: '$_sceneActionBuilderPath#$controlSymbol',
    },
  );
}

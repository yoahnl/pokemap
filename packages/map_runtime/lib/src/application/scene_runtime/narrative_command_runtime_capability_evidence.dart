import 'package:map_core/map_core.dart';

import 'scene_consequence_runtime_writer.dart';
import 'scene_interactive_command_runtime_executor.dart';
import 'scene_runtime_host_callbacks.dart';

ProjectCapabilityTruthAttestation
    buildMapRuntimeNarrativeCommandConsumerAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.runtime ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: _runtimeReference(command.backend),
    },
  );
}

String _runtimeReference(NarrativeCommandBackend backend) {
  const base = 'packages/map_runtime/lib/src/application/scene_runtime/';
  final (fileName, Type runtimeType) = switch (backend) {
    NarrativeCommandBackend.sceneConsequence => (
        'scene_consequence_runtime_writer.dart',
        SceneConsequenceRuntimeWriter
      ),
    NarrativeCommandBackend.interactiveRuntimeCommand => (
        'scene_interactive_command_runtime_executor.dart',
        SceneInteractiveCommandRuntimeExecutor,
      ),
    NarrativeCommandBackend.dedicatedSceneNode => (
        'scene_runtime_host_callbacks.dart',
        SceneRuntimeHostCallbacks
      ),
  };
  return '$base$fileName#${runtimeType.toString()}';
}

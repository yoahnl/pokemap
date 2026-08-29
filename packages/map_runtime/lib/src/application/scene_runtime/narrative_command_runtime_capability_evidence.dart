import 'package:map_core/map_core.dart';

import '../rail_journey_runtime_transaction.dart';
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
          command.id: _runtimeReference(command),
    },
  );
}

String _runtimeReference(NarrativeCommandDescriptor command) {
  if (command.id == NarrativeCommandIds.railJourney) {
    const path = 'packages/map_runtime/lib/src/application/'
        'rail_journey_runtime_transaction.dart';
    const Type runtimeType = RailJourneyRuntimeTransaction;
    return '$path#${runtimeType.toString()}';
  }
  const base = 'packages/map_runtime/lib/src/application/scene_runtime/';
  final (fileName, Type runtimeType) = switch (command.backend) {
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

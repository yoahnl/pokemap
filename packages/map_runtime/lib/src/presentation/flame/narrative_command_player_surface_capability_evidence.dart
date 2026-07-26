import 'package:map_core/map_core.dart';

import 'playable_map_game.dart';

const _playableMapGamePath =
    'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart';

ProjectCapabilityTruthAttestation
    buildMapRuntimeNarrativeCommandPlayerSurfaceAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  const Type playerSurfaceType = PlayableMapGame;
  final playerSurfaceSymbol = playerSurfaceType.toString();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.runtime ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: '$_playableMapGamePath#$playerSurfaceSymbol',
    },
  );
}

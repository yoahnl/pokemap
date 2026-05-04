import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Lot Environment-27 — seed déterministe + SetEnvironmentAreaSeed (pur Dart).
// ---------------------------------------------------------------------------

/// LCG 31 bits : déterministe, testable, sans [DateTime] ni [Random] non seedé.
int nextEnvironmentAreaSeed(int currentSeed) {
  return (currentSeed * 1664525 + 1013904223) & 0x7fffffff;
}

/// Résultat de [SetEnvironmentAreaSeedUseCase] en cas de succès.
///
/// En cas d’échec de validation, utiliser [SetEnvironmentAreaSeedResult.failure].
final class SetEnvironmentAreaSeedResult {
  const SetEnvironmentAreaSeedResult.success({
    required this.map,
    required this.previousSeed,
    required this.seed,
  }) : failureMessage = null;

  const SetEnvironmentAreaSeedResult.failure(this.failureMessage)
      : map = null,
        previousSeed = null,
        seed = null;

  final MapData? map;
  final int? previousSeed;
  final int? seed;
  final String? failureMessage;

  bool get isSuccess => failureMessage == null;
}

/// Met à jour uniquement [EnvironmentArea.seed] ; le reste de la carte est inchangé.
class SetEnvironmentAreaSeedUseCase {
  SetEnvironmentAreaSeedResult execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required int seed,
  }) {
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (envId.isEmpty) {
      return const SetEnvironmentAreaSeedResult.failure(
        'Environment layer id cannot be empty',
      );
    }
    if (aid.isEmpty) {
      return const SetEnvironmentAreaSeedResult.failure(
        'Environment area id cannot be empty',
      );
    }
    if (seed < 0) {
      return const SetEnvironmentAreaSeedResult.failure(
        'EnvironmentArea seed must be >= 0',
      );
    }

    EnvironmentLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        if (layer is! EnvironmentLayer) {
          return SetEnvironmentAreaSeedResult.failure(
            'Layer is not an environment layer: $envId',
          );
        }
        envLayer = layer;
        break;
      }
    }
    if (envLayer == null) {
      return SetEnvironmentAreaSeedResult.failure(
        'Environment layer not found: $envId',
      );
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      return SetEnvironmentAreaSeedResult.failure(
        'Environment area not found: $aid',
      );
    }

    final previousSeed = area.seed;
    final newAreas = <EnvironmentArea>[
      for (final a in envLayer.content.areas)
        if (a.id == aid)
          EnvironmentArea(
            id: a.id,
            name: a.name,
            presetId: a.presetId,
            mask: a.mask,
            seed: seed,
            paramsOverride: a.paramsOverride,
            generatedPlacementIds: a.generatedPlacementIds,
          )
        else
          a,
    ];

    final newContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: newAreas,
    );

    try {
      final updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: newContent,
      );
      MapValidator.validate(updated);
      return SetEnvironmentAreaSeedResult.success(
        map: updated,
        previousSeed: previousSeed,
        seed: seed,
      );
    } catch (e) {
      return SetEnvironmentAreaSeedResult.failure(
        'MapValidator.validate failed: $e',
      );
    }
  }
}

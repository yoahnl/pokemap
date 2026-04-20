import 'package:path/path.dart' as p;
import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';
import '../../application/runtime_map_bundle.dart';
import 'runtime_trainer_battle_overrides.dart';

/// Clé minimale de fond de combat pour le lot 2.
///
/// Garde-fous de périmètre :
/// - on ne construit pas un système générique de theming ;
/// - on ne transporte que des familles visuelles immédiatement utiles ;
/// - on garde la vraie logique de peinture dans le backdrop runtime, pas dans
///   le battle-core ni dans un registre global de palettes.
enum BattleBackgroundKey {
  fallbackField,
  wildOutdoor,
  trainerOutdoor,
  indoor,
}

/// Spec minimale de fond de combat consommée par la scène runtime.
///
/// Le contrat reste volontairement petit :
/// - une seule clé résolue ;
/// - pas de taxonomie de biome large ;
/// - pas de dépendance à des assets non présents ;
/// - pas de promesse de personnalisation future plus large que ce lot.
final class BattleBackgroundSpec {
  const BattleBackgroundSpec({
    required this.key,
    this.explicitImageAbsolutePath,
  });

  const BattleBackgroundSpec.fallbackField()
      : key = BattleBackgroundKey.fallbackField,
        explicitImageAbsolutePath = null;

  const BattleBackgroundSpec.explicitImage({
    required BattleBackgroundKey fallbackKey,
    required String absolutePath,
  })  : key = fallbackKey,
        explicitImageAbsolutePath = absolutePath;

  final BattleBackgroundKey key;
  final String? explicitImageAbsolutePath;

  bool get hasExplicitImage =>
      (explicitImageAbsolutePath?.trim().isNotEmpty ?? false);

  String get debugLabel => switch (key) {
        BattleBackgroundKey.fallbackField => 'fallback_field',
        BattleBackgroundKey.wildOutdoor => 'wild_outdoor',
        BattleBackgroundKey.trainerOutdoor => 'trainer_outdoor',
        BattleBackgroundKey.indoor => 'indoor',
      } +
      (hasExplicitImage ? '+explicit_image' : '');
}

/// Résout le fond de combat à partir du contexte runtime déjà disponible.
///
/// Frontière volontairement stricte :
/// - ce seam vit dans `map_runtime` parce qu'il traduit un contexte overworld
///   vers une ambiance de scène ;
/// - il ne dépend pas du moteur battle ;
/// - il ne modifie aucun contrat battle-core ;
/// - il n'essaie pas de devenir un moteur universel de biome ou de thème.
///
/// Chaîne de résolution retenue pour le lot 2 :
/// 1. vérité indoor explicite de la map actuelle ;
/// 2. type indoor-like de la map actuelle ;
/// 3. rôle indoor-like dans le manifeste projet ;
/// 4. nature trainer vs wild de la requête ;
/// 5. fallback stable côté overlay si aucun contexte n'est injecté.
///
/// Champs volontairement NON utilisés maintenant :
/// - `MapMetadata.tags` : trop libres, pas assez canoniques pour un lot borné ;
/// - `ProjectTrainerEntry.trainerClass` : utile produit plus tard, mais trop
///   instable pour piloter honnêtement le décor maintenant ;
/// - `ProjectTrainerEntry.battleThemeId` : tentant, mais ce repo n'a pas
///   encore de pipeline d'assets battle dédiée à respecter ici ;
/// - `ProjectEncounterTable.tags` : décrivent les rencontres, pas forcément la
///   scène de combat.
final class BattleBackgroundResolver {
  const BattleBackgroundResolver();

  BattleBackgroundSpec resolve({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    final contextualKey = _resolveContextualKey(
      request: request,
      bundle: bundle,
    );

    final explicitTrainerBackgroundAbsolutePath =
        _resolveExplicitTrainerBackgroundAbsolutePath(
      request: request,
      bundle: bundle,
    );
    if (explicitTrainerBackgroundAbsolutePath != null) {
      return BattleBackgroundSpec.explicitImage(
        fallbackKey: contextualKey,
        absolutePath: explicitTrainerBackgroundAbsolutePath,
      );
    }

    final explicitZoneBackgroundAbsolutePath =
        _resolveExplicitEncounterZoneBackgroundAbsolutePath(
      request: request,
      bundle: bundle,
    );
    if (explicitZoneBackgroundAbsolutePath != null) {
      return BattleBackgroundSpec.explicitImage(
        fallbackKey: contextualKey,
        absolutePath: explicitZoneBackgroundAbsolutePath,
      );
    }

    return BattleBackgroundSpec(
      key: contextualKey,
    );
  }

  BattleBackgroundKey _resolveContextualKey({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    if (_isIndoorMap(bundle)) {
      return BattleBackgroundKey.indoor;
    }

    return switch (request) {
      TrainerBattleStartRequest() => BattleBackgroundKey.trainerOutdoor,
      WildBattleStartRequest() => BattleBackgroundKey.wildOutdoor,
    };
  }

  String? _resolveExplicitTrainerBackgroundAbsolutePath({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    final trainer = findTrainerEntryForBattleRequest(
      request: request,
      manifest: bundle.manifest,
    );
    final relativePath = trainer?.battleBackgroundRelativePath?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }

    return p.normalize(
      p.join(bundle.projectRootDirectory, relativePath),
    );
  }

  String? _resolveExplicitEncounterZoneBackgroundAbsolutePath({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    if (request case WildBattleStartRequest(:final zoneId)) {
      final explicitPath = _resolveExplicitZoneBackgroundById(
        bundle: bundle,
        zoneId: zoneId,
      );
      if (explicitPath != null) {
        return explicitPath;
      }
    }

    final lookupPos = switch (request) {
      WildBattleStartRequest(:final playerPos) => playerPos,
      TrainerBattleStartRequest(:final playerPos) => playerPos,
    };
    final zone = _resolveEncounterZoneAtPos(
      bundle: bundle,
      pos: lookupPos,
    );
    final relativePath = zone?.encounter?.battleBackgroundRelativePath?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }

    return p.normalize(
      p.join(bundle.projectRootDirectory, relativePath),
    );
  }

  String? _resolveExplicitZoneBackgroundById({
    required RuntimeMapBundle bundle,
    required String zoneId,
  }) {
    final normalizedZoneId = zoneId.trim();
    if (normalizedZoneId.isEmpty) {
      return null;
    }
    for (final zone in bundle.map.gameplayZones) {
      if (zone.id != normalizedZoneId) {
        continue;
      }
      final relativePath = zone.encounter?.battleBackgroundRelativePath?.trim();
      if (relativePath == null || relativePath.isEmpty) {
        return null;
      }
      return p.normalize(
        p.join(bundle.projectRootDirectory, relativePath),
      );
    }
    return null;
  }

  MapGameplayZone? _resolveEncounterZoneAtPos({
    required RuntimeMapBundle bundle,
    required GridPos pos,
  }) {
    MapGameplayZone? bestZone;
    for (final zone in bundle.map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.encounter) {
        continue;
      }
      final relativePath = zone.encounter?.battleBackgroundRelativePath?.trim();
      if (relativePath == null || relativePath.isEmpty) {
        continue;
      }
      if (!_containsPos(zone.area, pos)) {
        continue;
      }
      if (bestZone == null || zone.priority >= bestZone.priority) {
        bestZone = zone;
      }
    }
    return bestZone;
  }

  bool _containsPos(MapRect rect, GridPos pos) {
    return pos.x >= rect.pos.x &&
        pos.y >= rect.pos.y &&
        pos.x < rect.pos.x + rect.size.width &&
        pos.y < rect.pos.y + rect.size.height;
  }

  bool _isIndoorMap(RuntimeMapBundle bundle) {
    final metadata = bundle.map.mapMetadata;
    if (metadata.isIndoor) {
      return true;
    }
    if (_isIndoorMapType(metadata.mapType)) {
      return true;
    }

    final mapEntry = _findMapEntry(
      manifest: bundle.manifest,
      mapId: bundle.map.id,
    );
    if (mapEntry == null) {
      return false;
    }
    return _isIndoorMapRole(mapEntry.role);
  }

  ProjectMapEntry? _findMapEntry({
    required ProjectManifest manifest,
    required String mapId,
  }) {
    for (final entry in manifest.maps) {
      if (entry.id == mapId) {
        return entry;
      }
    }
    return null;
  }

  bool _isIndoorMapType(MapType mapType) {
    return switch (mapType) {
      MapType.building ||
      MapType.interior ||
      MapType.cave ||
      MapType.facility =>
        true,
      _ => false,
    };
  }

  bool _isIndoorMapRole(MapRole role) {
    return switch (role) {
      MapRole.interior ||
      MapRole.basement ||
      MapRole.upper_floor ||
      MapRole.gate ||
      MapRole.room ||
      MapRole.connector =>
        true,
      _ => false,
    };
  }
}

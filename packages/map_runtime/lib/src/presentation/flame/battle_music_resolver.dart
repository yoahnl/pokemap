import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/battle_start_request.dart';
import '../../application/runtime_map_bundle.dart';
import 'runtime_trainer_battle_overrides.dart';

/// Musiques résolues pour un combat — BETA-BAT-015.
///
/// Chemins absolus prêts à jouer, ou null quand rien n'est authored : un
/// projet sans musique joue en silence, comme avant ce lot.
final class BattleMusicSelection {
  const BattleMusicSelection({
    this.battleMusicAbsolutePath,
    this.victoryMusicAbsolutePath,
  });

  final String? battleMusicAbsolutePath;
  final String? victoryMusicAbsolutePath;
}

/// Résout les musiques de combat depuis le contexte runtime déjà disponible.
///
/// Même frontière que [BattleBackgroundResolver] : ce seam traduit un contexte
/// overworld vers une ambiance de scène, sans dépendre du moteur battle ni
/// modifier un contrat battle-core.
///
/// Chaîne de précédence, calquée sur la référence (le thème explicite du
/// dresseur gagne sur le BGM de zone persistant, qui gagne sur les défauts
/// `Configs.sounds.base*`) — la zone de rencontre s'intercale comme le fait
/// déjà son fond de combat :
/// - combat dresseur : dresseur > zone > carte > défaut projet dresseur ;
/// - combat sauvage : zone > carte > défaut projet sauvage ;
/// - victoire dresseur : dresseur > défaut projet dresseur ;
/// - victoire sauvage : défaut projet sauvage ;
/// - rencontre (le « ! ») : zone sous le joueur > défaut projet.
final class BattleMusicResolver {
  const BattleMusicResolver();

  BattleMusicSelection resolve({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    final isTrainerBattle = request is TrainerBattleStartRequest ||
        request is StaticBattleStartRequest;
    final trainer = isTrainerBattle
        ? findTrainerEntryForBattleRequest(
            request: request,
            manifest: bundle.manifest,
          )
        : null;
    final defaults = bundle.manifest.battleAudio;

    final battleRelativePath = _firstAuthoredPath([
      if (isTrainerBattle) trainer?.battleMusicPath,
      _zoneBattleMusicRelativePath(request: request, bundle: bundle),
      bundle.map.mapMetadata.battleMusicPath,
      if (isTrainerBattle)
        defaults?.trainerBattleMusicPath
      else
        defaults?.wildBattleMusicPath,
    ]);
    final victoryRelativePath = _firstAuthoredPath([
      if (isTrainerBattle) trainer?.victoryMusicPath,
      if (isTrainerBattle)
        defaults?.trainerVictoryMusicPath
      else
        defaults?.wildVictoryMusicPath,
    ]);

    return BattleMusicSelection(
      battleMusicAbsolutePath: _absolute(bundle, battleRelativePath),
      victoryMusicAbsolutePath: _absolute(bundle, victoryRelativePath),
    );
  }

  /// Musique de rencontre jouée au repérage (le « ! ») avant le combat.
  ///
  /// L'équivalent du troisième étage `eye_bgm` de la référence : la zone de
  /// rencontre sous le joueur peut porter la sienne, sinon le défaut projet.
  String? resolveEncounterMusicAbsolutePath({
    required RuntimeMapBundle bundle,
    GridPos? playerPos,
  }) {
    final zone = playerPos == null
        ? null
        : _encounterZoneAtPos(
            bundle: bundle,
            pos: playerPos,
            hasAuthoredValue: (payload) =>
                _isAuthored(payload.encounterMusicPath),
          );
    return _absolute(
      bundle,
      _firstAuthoredPath([
        zone?.encounter?.encounterMusicPath,
        bundle.manifest.battleAudio?.encounterMusicPath,
      ]),
    );
  }

  /// Musique d'ambiance de la carte active (parité RMXP `Game_Map#autoplay`).
  String? resolveMapMusicAbsolutePath({
    required RuntimeMapBundle bundle,
  }) {
    return _absolute(
      bundle,
      _firstAuthoredPath([bundle.map.mapMetadata.musicPath]),
    );
  }

  /// La musique de combat portée par la zone de rencontre concernée.
  ///
  /// Même règle de ciblage que le fond de zone : une rencontre sauvage vise
  /// d'abord la zone qui l'a déclenchée (`zoneId`), puis la zone sous le
  /// joueur ; un combat de dresseur regarde la zone sous le joueur.
  String? _zoneBattleMusicRelativePath({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    if (request case WildBattleStartRequest(:final zoneId)) {
      final normalizedZoneId = zoneId.trim();
      if (normalizedZoneId.isNotEmpty) {
        for (final zone in bundle.map.gameplayZones) {
          if (zone.id != normalizedZoneId) continue;
          final authored = zone.encounter?.battleMusicPath;
          if (_isAuthored(authored)) return authored;
          break;
        }
      }
    }
    final lookupPos = switch (request) {
      WildBattleStartRequest(:final playerPos) => playerPos,
      TrainerBattleStartRequest(:final playerPos) => playerPos,
      StaticBattleStartRequest(:final playerPos) => playerPos,
    };
    final zone = _encounterZoneAtPos(
      bundle: bundle,
      pos: lookupPos,
      hasAuthoredValue: (payload) => _isAuthored(payload.battleMusicPath),
    );
    return zone?.encounter?.battleMusicPath;
  }

  MapGameplayZone? _encounterZoneAtPos({
    required RuntimeMapBundle bundle,
    required GridPos pos,
    required bool Function(EncounterZonePayload payload) hasAuthoredValue,
  }) {
    MapGameplayZone? bestZone;
    for (final zone in bundle.map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.encounter) continue;
      final payload = zone.encounter;
      if (payload == null || !hasAuthoredValue(payload)) continue;
      if (!_containsPos(zone.area, pos)) continue;
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

  bool _isAuthored(String? value) => (value?.trim().isNotEmpty) ?? false;

  String? _firstAuthoredPath(List<String?> candidates) {
    for (final candidate in candidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  String? _absolute(RuntimeMapBundle bundle, String? relativePath) {
    if (relativePath == null) {
      return null;
    }
    return p.normalize(
      p.join(bundle.projectRootDirectory, relativePath),
    );
  }
}

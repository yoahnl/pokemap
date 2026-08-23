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
/// `Configs.sounds.base*`) :
/// - combat dresseur : dresseur > carte > défaut projet dresseur ;
/// - combat sauvage : carte > défaut projet sauvage ;
/// - victoire dresseur : dresseur > défaut projet dresseur ;
/// - victoire sauvage : défaut projet sauvage.
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
  /// L'équivalent du troisième étage `eye_bgm` de la référence, réduit à un
  /// défaut projet unique tant qu'aucun besoin par-dresseur n'existe.
  String? resolveEncounterMusicAbsolutePath({
    required RuntimeMapBundle bundle,
  }) {
    return _absolute(
      bundle,
      _firstAuthoredPath([bundle.manifest.battleAudio?.encounterMusicPath]),
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

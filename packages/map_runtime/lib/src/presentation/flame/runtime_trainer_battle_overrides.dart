import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';

/// Résout la policy adverse réellement utilisée par le runtime pour une requête.
///
/// Ce helper pur existe pour deux besoins immédiats du lot 4b :
/// - durcir la preuve que la difficulté authored côté trainer est bien relue
///   dans le vrai flow runtime ;
/// - éviter de laisser cette lecture enterrée dans une méthode privée géante de
///   `PlayableMapGame`, donc difficile à verrouiller honnêtement par test.
///
/// Garde-fous de périmètre :
/// - ce helper reste runtime-local et ne fuit pas dans `map_battle` ;
/// - il ne rouvre ni scripts trainer, ni switch intelligent, ni lot 5 ;
/// - il route seulement la difficulté produit déjà présente vers le seam
///   `BattleOpponentPolicy` ouvert au lot 3.
BattleOpponentPolicy resolveRuntimeTrainerOpponentPolicy({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  if (request is! TrainerBattleStartRequest) {
    return const BattleFirstLegalOpponentPolicy();
  }

  final trainer = findTrainerEntryForBattleRequest(
    request: request,
    manifest: manifest,
  );
  return battleOpponentPolicyForDifficulty(trainer?.battleDifficulty);
}

/// Relit le trainer authored réellement visé par une requête de combat.
///
/// Pourquoi ce seam existe :
/// - le runtime a déjà `trainerId` dans `TrainerBattleStartRequest` ;
/// - les données produit restent dans `ProjectManifest.trainers` ;
/// - plusieurs lots ont maintenant besoin de la même relecture honnête
///   (difficulté, background explicite) sans recopier la logique.
ProjectTrainerEntry? findTrainerEntryForBattleRequest({
  required BattleStartRequest request,
  required ProjectManifest manifest,
}) {
  if (request is! TrainerBattleStartRequest) {
    return null;
  }

  final normalizedTrainerId = request.trainerId.trim();
  for (final trainer in manifest.trainers) {
    if (trainer.id == normalizedTrainerId) {
      return trainer;
    }
  }
  return null;
}

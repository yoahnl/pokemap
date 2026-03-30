import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';

/// Construit une [TrainerBattleStartRequest] depuis un NPC dresseur.
///
/// **Pure function** : aucun effet de bord, facile à tester.
///
/// Retourne `null` si :
/// - le NPC n'a pas de `trainerId`
/// - le `trainerId` est vide
/// - le trainer n'est pas trouvé dans le manifest
///
/// Pour la gestion d'erreur runtime (log, notification, fallback),
/// voir `_handleTrainerBattleInteraction` dans `playable_map_game.dart`.
TrainerBattleStartRequest? buildTrainerBattleRequestFromNpc({
  required MapEntity entity,
  required ProjectManifest manifest,
  required GameplayWorldState world,
  int? createdAtEpochMs,
}) {
  final trainerId = entity.npc?.trainerId?.trim();
  if (trainerId == null || trainerId.isEmpty) {
    return null;
  }

  final trainer = manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
    (t) => t?.id == trainerId,
    orElse: () => null,
  );

  if (trainer == null) {
    return null;
  }

  final now = createdAtEpochMs ?? DateTime.now().millisecondsSinceEpoch;
  final requestId =
      'trainer:${world.map.id}:${entity.id}:$trainerId:$now';

  return TrainerBattleStartRequest(
    requestId: requestId,
    createdAtEpochMs: now,
    returnContext: OverworldReturnContext(
      mapId: world.map.id,
      playerPos: world.player.pos,
      playerFacing: world.player.facing,
    ),
    trainerId: trainerId,
    npcEntityId: entity.id,
    mapId: world.map.id,
    playerPos: world.player.pos,
  );
}

import 'package:map_core/map_core.dart';

import 'scripted_entity_movement_models.dart';

/// Résout la route de patrouille par défaut d'un NPC de map.
///
/// Contrat:
/// - `idle`         => pas de mouvement automatique,
/// - `scriptedOnly` => pas de mouvement automatique,
/// - `patrol`       => route valide si >= 2 waypoints.
///
/// Ce helper reste volontairement pur et minimal:
/// - il ne déclenche aucun déplacement,
/// - il prépare uniquement la configuration runtime de base.
ScriptedEntityPatrolRoute? resolveNpcDefaultPatrolRoute(MapEntity entity) {
  if (entity.kind != MapEntityKind.npc) {
    return null;
  }
  final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
  if (movement.mode != MapEntityNpcMovementMode.patrol) {
    return null;
  }
  if (movement.waypoints.length < 2) {
    return null;
  }
  final pause = movement.pauseDurationMs < 0 ? 0 : movement.pauseDurationMs;
  final step = movement.stepDurationMs <= 0 ? 200 : movement.stepDurationMs;
  return ScriptedEntityPatrolRoute(
    entityId: entity.id,
    waypoints: movement.waypoints,
    loop: movement.loop,
    pauseDurationMs: pause,
    stepDurationMs: step,
  );
}

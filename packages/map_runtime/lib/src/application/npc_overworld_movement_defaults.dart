import 'package:map_core/map_core.dart';
import 'package:flutter/foundation.dart';

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
  debugPrint(
    '[npc_patrol] read movement entity=${entity.id} pos=(${entity.pos.x},${entity.pos.y}) size=${entity.size.width}x${entity.size.height} mode=${movement.mode.name} waypoints=${movement.waypoints.map((w) => '(${w.x},${w.y})').join(' -> ')} loop=${movement.loop} pauseMs=${movement.pauseDurationMs} stepMs=${movement.stepDurationMs}',
  );
  if (movement.mode != MapEntityNpcMovementMode.patrol) {
    return null;
  }
  if (movement.waypoints.length < 2) {
    debugPrint(
      '[npc_patrol] skip entity=${entity.id} reason="needs at least 2 waypoints"',
    );
    return null;
  }
  final pause = movement.pauseDurationMs < 0 ? 0 : movement.pauseDurationMs;
  final step = movement.stepDurationMs <= 0 ? 200 : movement.stepDurationMs;
  debugPrint(
    '[npc_patrol] route entity=${entity.id} targetWaypoints=${movement.waypoints.map((w) => '(${w.x},${w.y})').join(' -> ')}',
  );
  return ScriptedEntityPatrolRoute(
    entityId: entity.id,
    waypoints: movement.waypoints,
    loop: movement.loop,
    pauseDurationMs: pause,
    stepDurationMs: step,
  );
}

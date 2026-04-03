import 'package:map_core/map_core.dart';

/// États externes d'une commande de déplacement scripté.
///
/// Ce cycle de vie est volontairement simple pour faciliter l'orchestration
/// future par une cutscene:
/// - `idle`      : aucune commande active pour l'entité,
/// - `moving`    : commande en cours,
/// - `completed` : destination atteinte,
/// - `failed`    : échec (pas de chemin, entité inconnue, blocage irrésolu...).
enum ScriptedEntityMovementState {
  idle,
  moving,
  completed,
  failed,
}

/// Snapshot lisible de l'état de déplacement d'une entité.
///
/// Cette structure est:
/// - sérialisable facilement côté debug/logs,
/// - suffisante pour un "wait until movement completed/failed" en cutscene,
/// - indépendante de Flame/UI.
class ScriptedEntityMovementStatus {
  const ScriptedEntityMovementStatus({
    required this.entityId,
    required this.state,
    required this.currentPos,
    this.targetPos,
    this.failureReason,
  });

  const ScriptedEntityMovementStatus.idle({
    required String entityId,
    required GridPos currentPos,
  }) : this(
          entityId: entityId,
          state: ScriptedEntityMovementState.idle,
          currentPos: currentPos,
        );

  final String entityId;
  final ScriptedEntityMovementState state;
  final GridPos currentPos;
  final GridPos? targetPos;
  final String? failureReason;

  bool get isTerminal =>
      state == ScriptedEntityMovementState.completed ||
      state == ScriptedEntityMovementState.failed;
}

/// Spécification d'une patrouille simple par waypoints.
///
/// MVP du lot:
/// - waypoints ordonnés,
/// - boucle optionnelle (`loop=true`),
/// - pas de comportement avancé (pause, vitesse variable, ping-pong...).
class ScriptedEntityPatrolRoute {
  const ScriptedEntityPatrolRoute({
    required this.entityId,
    required this.waypoints,
    this.loop = true,
  });

  final String entityId;
  final List<GridPos> waypoints;
  final bool loop;
}

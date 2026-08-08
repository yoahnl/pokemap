part of 'playable_map_game.dart';

final class _ScenarioContinuationResumeResult {
  const _ScenarioContinuationResumeResult({
    required this.outcomes,
    required this.nextRuntimeSourceId,
    required this.ownedTransitionMapRequest,
  });

  const _ScenarioContinuationResumeResult.invalid()
    : outcomes = const <NarrativeOutcomeRef>[],
      nextRuntimeSourceId = null,
      ownedTransitionMapRequest = null;

  final List<NarrativeOutcomeRef> outcomes;
  final String? nextRuntimeSourceId;
  final _PendingScenarioTransitionMapRequest? ownedTransitionMapRequest;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

final class _PendingScenarioBattleHandoff {
  const _PendingScenarioBattleHandoff({
    required this.requestId,
    required this.runtimeSourceId,
    required this.battleId,
  });

  final String requestId;
  final String runtimeSourceId;
  final String battleId;
}

enum _ScenarioWarpHandoffKind { script, playerMove, leaderMove }

final class _PendingScenarioWarpHandoff {
  const _PendingScenarioWarpHandoff({
    required this.runtimeSourceId,
    required this.expectedWarp,
    required this.kind,
    this.entityId,
  });

  final String runtimeSourceId;
  final TriggeredWarp expectedWarp;
  final _ScenarioWarpHandoffKind kind;
  final String? entityId;

  bool matches(TriggeredWarp? warp) {
    return warp != null &&
        warp.warpId == expectedWarp.warpId &&
        warp.targetMapId == expectedWarp.targetMapId &&
        warp.targetPos == expectedWarp.targetPos &&
        warp.triggerMode == expectedWarp.triggerMode;
  }
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioLeaderWarpHandoff {
  const _PendingScenarioLeaderWarpHandoff({
    required this.leaderEntityId,
    required this.warpId,
    required this.targetMapId,
    required this.targetPos,
    required this.triggerMode,
    required this.runtimeSourceId,
  });

  final String leaderEntityId;
  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
  final MapWarpTriggerMode triggerMode;
  final String? runtimeSourceId;

  bool matches(TriggeredWarp? warp) {
    return warp != null &&
        warp.warpId == warpId &&
        warp.targetMapId == targetMapId &&
        warp.targetPos == targetPos &&
        warp.triggerMode == triggerMode;
  }
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({required this.destination, required this.path});

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle { fade }

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
}

/// Projection World Rules mémoïsée avec les entrées identitaires qui l'ont
/// produite (manifeste, état de jeu, carte).
class _WorldRuleProjectionCache {
  const _WorldRuleProjectionCache({
    required this.manifest,
    required this.gameState,
    required this.map,
    required this.projection,
  });

  final ProjectManifest manifest;
  final GameState gameState;
  final MapData map;
  final RuntimeWorldRuleProjectionState? projection;
}

/// Contexte de planification de route préparé pour une entité : sonde de
/// passabilité (offsets figés) + prédicat de blocage dynamique lié.
class _PreparedNpcRoutePlanningProbe {
  const _PreparedNpcRoutePlanningProbe({
    required this.entityId,
    required this.world,
    required this.probe,
    required this.isDynamicallyBlocked,
  });

  final String entityId;
  final GameplayWorldState world;
  final PreparedScriptedNpcAnchorProbe? probe;
  final ScriptedNpcDynamicCellBlocked isDynamicallyBlocked;
}

/// Fusion d'ombres mémoïsée avec les collections sources ayant servi à la
/// construire ; la validité se vérifie par identité des sources.
class _MergedShadowCollectionCache {
  const _MergedShadowCollectionCache({
    required this.projected,
    required this.staticCollection,
    required this.actorCollection,
    required this.merged,
  });

  final ShadowRuntimeInstructionCollection? projected;
  final ShadowRuntimeInstructionCollection? staticCollection;
  final ShadowRuntimeInstructionCollection? actorCollection;
  final ShadowRuntimeInstructionCollection? merged;
}

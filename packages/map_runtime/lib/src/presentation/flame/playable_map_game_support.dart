part of 'playable_map_game.dart';

final class _PlayableMapCinematicRuntimeHost
    implements FlameCinematicRuntimeHost, FlameCinematicFxHost {
  _PlayableMapCinematicRuntimeHost(this._game);

  final PlayableMapGame _game;
  TextComponent? _dialogueLineOverlay;
  RectangleComponent? _fadeOverlay;
  Paint? _fadePaint;
  TextComponent? _emoteOverlay;
  final Map<String, RectangleComponent> _fxOverlays = {};

  String? get dialogueLine => _dialogueLineOverlay?.text;

  double? get fadeOpacity => _fadePaint?.color.a;

  @override
  bool get isReady => _game.isLoaded && _game._activeMapId.isNotEmpty;

  @override
  String get activeMapId => _game._activeMapId;

  @override
  Vector2 get cameraPosition => _game._pixelCamera.position;

  @override
  set cameraPosition(Vector2 value) {
    _game._pixelCamera.setPosition(value);
  }

  @override
  Vector2? get cameraVisibleGameSize =>
      _game._pixelCamera.requestedVisibleGameSize;

  @override
  set cameraVisibleGameSize(Vector2? value) {
    _game._pixelCamera.setRequestedVisibleGameSize(value);
  }

  @override
  Vector2 get sceneCenter {
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return _game._player.focusPoint;
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x + loaded.bundle.map.size.width * loaded.bundle.cellWidth / 2,
      origin.y + loaded.bundle.map.size.height * loaded.bundle.cellHeight / 2,
    );
  }

  @override
  FlameCinematicRuntimeActorHandle? get playerActor {
    if (!isReady) return null;
    return _PlayableMapPlayerCinematicActorHandle(_game._player);
  }

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) {
    final actor =
        _game._loadedMapsById[_game._activeMapId]?.npcActorByEntityId[entityId];
    return actor == null ? null : _PlayableMapNpcCinematicActorHandle(actor);
  }

  @override
  Vector2? mapEntityFocusPoint(String entityId) {
    final actor = mapEntityActor(entityId);
    if (actor != null) return actor.focusPoint;
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return null;
    MapEntity? entity;
    for (final candidate in loaded.bundle.map.entities) {
      if (candidate.id == entityId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) return null;
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x +
          (entity.pos.x + entity.size.width / 2) * loaded.bundle.cellWidth,
      origin.y +
          (entity.pos.y + entity.size.height / 2) * loaded.bundle.cellHeight,
    );
  }

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) {
    final loaded = _game._loadedMapsById[_game._activeMapId];
    if (loaded == null) return Vector2(point.x, point.y);
    final origin = _game._originPixelsOf(loaded);
    return Vector2(
      origin.x + point.x * loaded.bundle.cellWidth,
      origin.y + point.y * loaded.bundle.cellHeight,
    );
  }

  @override
  void setCinematicInputLocked(bool locked) {
    _game._setCinematicInputLocked(locked);
  }

  @override
  void showCinematicDialogueLine(String? text) {
    _dialogueLineOverlay?.removeFromParent();
    _dialogueLineOverlay = null;
    if (text == null || text.trim().isEmpty) return;
    final component = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Color(0xDD000000),
          fontSize: 16,
          height: 1.35,
        ),
      ),
      anchor: Anchor.bottomCenter,
    )
      ..position = Vector2(
        _game.camera.viewport.size.x / 2,
        _game.camera.viewport.size.y - 24,
      )
      ..priority = 130;
    _game.camera.viewport.add(component);
    _dialogueLineOverlay = component;
  }

  @override
  Future<void> playCinematicDialogueAsset(String dialogueId) async {
    final result = await _game._startSceneDialogue(
      SceneDialogueRuntimeDialogueRequest(
        requestId: 'cinematic:$dialogueId',
        createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        dialogueId: dialogueId,
      ),
    );
    if (!result.success) {
      throw StateError(
        result.message ?? 'Cinematic dialogue "$dialogueId" failed.',
      );
    }
  }

  @override
  void cancelCinematicDialogueAsset() {
    _game._completePendingSceneDialogue(
      const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'Cinematic dialogue was cancelled.',
      ),
    );
    _game._dialogueOverlay?.removeFromParent();
    _game._dialogueOverlay = null;
    _game._setDialoguePresentationSnapshot(null);
    if (_game._flowPhase == _RuntimeFlowPhase.dialogue) {
      _game._setFlowPhase(_RuntimeFlowPhase.overworld);
    }
    _game._clearBlockingInteractionWithoutUnlock(
      reason: 'cinematicDialogueCancelled',
    );
  }

  @override
  void setCinematicFadeOpacity(double? opacity) {
    if (opacity == null) {
      _fadeOverlay?.removeFromParent();
      _fadeOverlay = null;
      _fadePaint = null;
      return;
    }
    var paint = _fadePaint;
    if (paint == null) {
      paint = Paint();
      final component = RectangleComponent(
        size: _game.camera.viewport.size.clone(),
        paint: paint,
      )..priority = 120;
      _game.camera.viewport.add(component);
      _fadePaint = paint;
      _fadeOverlay = component;
    }
    paint.color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0));
  }

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {
    _emoteOverlay?.removeFromParent();
    _emoteOverlay = null;
    if (actor == null || emoteId == null) return;
    final component = TextComponent(
      text: _cinematicEmoteGlyph(emoteId),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[
            Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
      ),
      anchor: Anchor.bottomCenter,
    )
      ..position = actor.focusPoint - Vector2(0, 22)
      ..priority = 200000;
    _game.world.add(component);
    _emoteOverlay = component;
  }

  @override
  void showCinematicFx(String assetId, {required double intensity}) {
    hideCinematicFx(assetId);
    final component = RectangleComponent(
      size: _game.camera.viewport.size.clone(),
      paint: Paint()
        ..color = Color.fromRGBO(
          210,
          230,
          235,
          (0.08 + intensity.clamp(0.0, 1.0) * 0.18).clamp(0.0, 1.0),
        ),
    )..priority = 110;
    _game.camera.viewport.add(component);
    _fxOverlays[assetId] = component;
  }

  @override
  void hideCinematicFx(String assetId) {
    _fxOverlays.remove(assetId)?.removeFromParent();
  }

  @override
  void clearCinematicFx() {
    for (final overlay in _fxOverlays.values) {
      overlay.removeFromParent();
    }
    _fxOverlays.clear();
  }

  void onViewportResize(Vector2 size) {
    _dialogueLineOverlay?.position = Vector2(size.x / 2, size.y - 24);
    _fadeOverlay?.size = size.clone();
    for (final overlay in _fxOverlays.values) {
      overlay.size = size.clone();
    }
  }
}

final class _PlayableMapPlayerCinematicActorHandle
    implements FlameCinematicRuntimeActorHandle {
  const _PlayableMapPlayerCinematicActorHandle(this._player);

  final PlayerComponent _player;

  @override
  Vector2 get focusPoint => _player.focusPoint;

  @override
  EntityFacing get facing => _player.cinematicFacing;

  @override
  void setFocusPoint(Vector2 focusPoint) {
    final delta = focusPoint - _player.focusPoint;
    _player.position += delta;
  }

  @override
  void setFacing(EntityFacing facing) {
    _player.setCinematicFacing(facing);
  }
}

final class _PlayableMapNpcCinematicActorHandle
    implements FlameCinematicRuntimeActorHandle {
  const _PlayableMapNpcCinematicActorHandle(this._actor);

  final OverworldActorComponent _actor;

  @override
  Vector2 get focusPoint => _actor.position + _actor.size / 2;

  @override
  EntityFacing get facing => _actor.facing;

  @override
  void setFocusPoint(Vector2 focusPoint) {
    _actor.position = focusPoint - _actor.size / 2;
  }

  @override
  void setFacing(EntityFacing facing) {
    _actor.setMotion(facing, CharacterAnimationState.idle);
  }
}

String _cinematicEmoteGlyph(String emoteId) {
  return switch (emoteId) {
    'exclamation' || 'alert' => '!',
    'anger' => '#',
    'thought' || 'silence' => '…',
    'question' => '?',
    'music' => '♪',
    'idea' => '*',
    'heart' => '♥',
    'sweat' => '◢',
    _ => '•',
  };
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.actorOcclusionLayers,
    required this.smartTileAnimationController,
    required this.occlusionPatches,
    required this.npcActors,
    required this.npcActorByEntityId,
    required this.tileImagesById,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final SmartTileActorOcclusionLayerCollection actorOcclusionLayers;
  final SmartTileAnimationActivationController smartTileAnimationController;
  final List<PlacedElementOcclusionPatchComponent> occlusionPatches;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
  final Map<String, RuntimeTilesetImage> tileImagesById;
}

final class _LoadRuntimeSnapshot {
  const _LoadRuntimeSnapshot({
    required this.gameState,
    required this.bundle,
    required this.world,
    required this.activeMapId,
    required this.previousMapId,
    required this.flowPhase,
    required this.currentMapActivationId,
    required this.completedMapActivationDispatchCount,
    required this.lastCompletedMapActivation,
  });

  final GameState gameState;
  final RuntimeMapBundle bundle;
  final GameplayWorldState world;
  final String activeMapId;
  final String? previousMapId;
  final _RuntimeFlowPhase flowPhase;
  final String? currentMapActivationId;
  final int completedMapActivationDispatchCount;
  final MapActivation? lastCompletedMapActivation;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingConnectionEntryAnimation {
  _PendingConnectionEntryAnimation({
    required this.mapId,
    required this.initialCameraWorldTopLeft,
    required this.activation,
  });

  final String mapId;
  final Vector2 initialCameraWorldTopLeft;
  final MapActivation activation;
  bool holdInitialCameraFrame = true;
}

class _EncounterCheckMarker {
  const _EncounterCheckMarker({
    required this.mapId,
    required this.pos,
    required this.kind,
  });

  final String mapId;
  final GridPos pos;
  final EncounterKind kind;

  @override
  bool operator ==(Object other) {
    return other is _EncounterCheckMarker &&
        other.mapId == mapId &&
        other.pos == pos &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(mapId, pos, kind);
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

final class _CallbackSceneBattleRuntimeLauncher
    implements SceneBattleRuntimeLauncher {
  const _CallbackSceneBattleRuntimeLauncher(this._startTrainerBattle);

  final Future<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _startTrainerBattle;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) {
    return _startTrainerBattle(request);
  }
}

final class _CallbackSceneDialogueRuntimeLauncher
    implements SceneDialogueRuntimeLauncher {
  const _CallbackSceneDialogueRuntimeLauncher(this._showDialogue);

  final Future<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _showDialogue;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) {
    return _showDialogue(request);
  }
}

final class _PendingNarrativeTriggerEntry {
  const _PendingNarrativeTriggerEntry({
    required this.activationId,
    required this.mapId,
    required this.triggerId,
  });

  final String? activationId;
  final String mapId;
  final String triggerId;
}

final class _NarrativeSceneWorkingSession {
  _NarrativeSceneWorkingSession(this.gameState);

  GameState gameState;
}

final class _NarrativeOutcomeContinuationContext {
  const _NarrativeOutcomeContinuationContext({
    required this.causationId,
    required this.correlationId,
    required this.depth,
  });

  final String causationId;
  final String correlationId;
  final int depth;
}

final class _NarrativeContinuationBarrier {
  _NarrativeContinuationBarrier({
    required this.runtimeSourceId,
    required this.continuation,
    required this.lease,
    required this.resumesScenario,
    required this.postCommitEffect,
  });

  String runtimeSourceId;
  _NarrativeOutcomeContinuationContext continuation;
  final NarrativeRuntimeActivityLease lease;
  final bool resumesScenario;
  final Future<void> Function()? postCommitEffect;
  final Completer<void> closedCompleter = Completer<void>();
  bool advancing = false;
  bool postCommitEffectStarted = false;
  bool cancelled = false;
  bool closed = false;
  _PendingScenarioTransitionMapRequest? ownedTransitionMapRequest;

  Future<void> get closedFuture => closedCompleter.future;
}

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
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

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

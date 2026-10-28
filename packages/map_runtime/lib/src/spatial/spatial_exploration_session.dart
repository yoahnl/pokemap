import '../player/real_weather_service.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:path/path.dart' as p;

import '../application/character_animation_source_resolver.dart';
import '../application/runtime_map_bundle.dart';
import '../application/runtime_player_avatar.dart';
import '../application/load_runtime_map_bundle.dart';
import '../application/dialogue_runtime_models.dart';
import '../application/dialogue_variable_interpolation.dart';
import '../application/dialogue_feedback_playback_port.dart';
import '../application/resolve_dialogue.dart';
import '../application/load_dialogue_content.dart';
import '../application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
import '../presentation/flame/dialogue_overlay_component.dart';
import '../presentation/flame/dialogue_text_speed.dart';
import '../presentation/flame/flame_narrative_sound_playback_adapter.dart';
import '../player/runtime_music_service.dart';
import '../player/runtime_graphics_preferences.dart';
import 'spatial_entity_visual_plan.dart';
import 'spatial_cinematic_runtime_playback_sink.dart';
import 'spatial_cinematic_emote_visuals.dart';
import 'spatial_smart_tile_animation_controller.dart';

final class SpatialExplorationSession {
  SpatialExplorationSession._(this.bundle, this.character, this.movement,
    this._assets,
    this._ownsAssets,
    this._knownMaps,
  ) : _smartTileAnimations = SpatialSmartTileAnimationController(
        map: bundle.map,
        project: bundle.manifest,
      );
  SpatialSmartTileAnimationController _smartTileAnimations;
  RuntimeMapBundle bundle;
  RealWeatherService? realWeather;
  bool realWeatherAllowed = false;
  WorldEnvironmentClock environmentClock = WorldEnvironmentClock(now: DateTime.now);
  ProjectCharacterEntry character;
  SpatialMovementController movement;
  final _SpatialActorAssets _assets;
  final bool _ownsAssets;
  Map<String, ui.Image> get _images => _assets.images;
  Map<String, SpatialActorTexture> get _textures => _assets.textures;
  final Object _assetOwner = Object();
  final Object _avatarAssetOwner = Object();
  Set<String> _imageIds = {};
  final _preparedMaps = <String, _PreparedSpatialMap>{};
  final _modelPresenceIndices = Expando<_SpatialModelPresenceIndex>();
  final _preparingMaps = <String, Future<_PreparedSpatialMap>>{};
  final _mapOrigins = <String, ui.Offset>{};
  Set<String> _visibleMaps = {};
  bool _rendererAttached = false;
  final Map<String, MapData> _knownMaps;
  final _viewConnectionsById = <String, List<MapConnection>>{};
  List<MapConnection> get viewConnections => _connectionsFor(bundle.map);

  List<SpatialMovementNeighbor> get cinematicMovementNeighbors => [
    for (final connection in viewConnections)
      if (_preparedMaps[connection.targetMapId] case final prepared?)
        SpatialMovementNeighbor(controller: prepared.movement,
          offsetX: spatialConnectionOffset(bundle.map.size, prepared.bundle.map.size,
            connection.direction, connection.offset).dx,
          offsetZ: spatialConnectionOffset(bundle.map.size, prepared.bundle.map.size,
            connection.direction, connection.offset).dy),
  ];

  ({MapData map, double x, double z})? _cinematicLocation(double x, double z) {
    if (!x.isFinite || !z.isFinite) return null;
    bool inside(MapData map, double localX, double localZ) =>
        localX >= 0 &&
        localZ >= 0 &&
        localX < map.size.width &&
        localZ < map.size.height;
    if (inside(bundle.map, x, z)) return (map: bundle.map, x: x, z: z);
    for (final connection in viewConnections) {
      final neighbor = _preparedMaps[connection.targetMapId]?.bundle.map;
      if (neighbor == null) continue;
      final offset = spatialConnectionOffset(
        bundle.map.size,
        neighbor.size,
        connection.direction,
        connection.offset,
      );
      final localX = x - offset.dx, localZ = z - offset.dy;
      if (inside(neighbor, localX, localZ)) {
        return (map: neighbor, x: localX, z: localZ);
      }
    }
    return null;
  }

  bool containsCinematicPoint(double x, double z) =>
      _cinematicLocation(x, z) != null;

  double cinematicHeightAt(double x, double z) {
    final location = _cinematicLocation(x, z);
    if (location == null) {
      throw StateError('The cinematic point is outside loaded connected maps.');
    }
    return liftHeightAt?.call(location.map.id,location.x,location.z) ?? location.map.spatialScene!.worldHeightAt(location.x, location.z);
  }

  List<MapConnection> _connectionsFor(MapData map) =>
      _viewConnectionsById.putIfAbsent(map.id, () {
        final result = [...map.connections];
        final occupied = {
          for (final connection in result)
            (connection.direction, connection.targetMapId),
        };
        for (final source in _knownMaps.values) {
          for (final connection in source.connections) {
            final direction = connection.direction.opposite;
            if (connection.targetMapId != map.id ||
                occupied.contains((direction, source.id))) {
              continue;
            }
            occupied.add((direction, source.id));
            result.add(MapConnection(
                direction: direction,
                targetMapId: source.id,
                offset: -connection.offset,
              ),
            );
          }
        }
        final directions = <MapConnectionDirection>{};
        if (result.any((connection) => !directions.add(connection.direction))) {
          throw StateError(
            'Plusieurs voisines sur un bord 3D ne sont pas prises en charge.',
          );
        }
        return List.unmodifiable(result);
      });
  final _resolver = CharacterAnimationSourceResolver();
  late SpatialEntityVisualPlan _entityVisuals;
  bool Function(String mapId, MapEntity entity)? entityIsPresent;
  MapEntity? Function(String mapId, MapEntity entity)? entityProjection;
  GameState Function()? presentationStateProvider;
  final Map<
    String,
    ({
      EntityFacing declaration,
      EntityFacing? override,
      SpatialActorRuntimeState? state,
    })
  >
      _presentationFacingStates = {};
  bool _disposed = false;
  late Future<RuntimeMapBundle> Function(String) _loadMap;
  late SpatialWarpController _warps;
  final mapRevision = ValueNotifier(0);
  final transitioning = ValueNotifier(false);
  final nativeDoorBlackout = ValueNotifier<double>(0);
  Future<void> Function()? waitForNativeDoorBlackoutFrame;
  Future<void> Function()? waitForNativeTraversalStartFrame;
  Future<void> Function(
    RuntimeMapBundle destination,
    bool Function() isCurrent,
  )? prepareNativeDoorDestination;
  int _transferGeneration = 0;
  final _nativeDoor = SpatialDoorTraversalController();
  Object? _nativeDoorLease;
  VoidCallback? _nativeDoorRollback;
  SpatialDoorTraversalBinding? _nativeArrivalDoor;
  Completer<bool>? _nativeDoorRendererReady;
  String? _nativeDoorRendererMap;
  bool get nativeDoorTraversalActive => _nativeDoorLease != null;
  MapWarpTransition _nativeScreenTransition = const MapWarpTransition();
  MapWarpTransition get nativeScreenTransition => _nativeScreenTransition;
  bool get nativeScreenRevealing => _nativeDoor.revealing;
  double get nativeCameraMagnification => nativeDoorTraversalActive &&
          _nativeDoor.cameraMapId == bundle.map.id
      ? _nativeDoor.cameraMagnification : 1;
  ({double x, double z})? get nativeCameraAnchor => nativeDoorTraversalActive &&
          _nativeDoor.cameraMapId == bundle.map.id
      ? _nativeDoor.cameraAnchor : null;
  bool get nativeDoorHeroVisible =>
      !nativeDoorTraversalActive || _nativeDoor.heroVisible;
  ({
    MapConnection connection,
    GridSize sourceSize,
    double sourceX,
    double sourceZ,
  })? _connectionEntry;
  ({
    MapConnection connection,
    GridSize sourceSize,
    double sourceX,
    double sourceZ,
  })? get connectionEntry => _connectionEntry;
  VoidCallback? onFrame;
  void Function(double dt, bool paused)? onPresentationFrame;
  SpatialWorldState Function()? worldStateProvider;
  double? Function(String mapId,double x,double z)? liftHeightAt;
  SpatialModelRuntimeState? Function(String mapId,String instanceId)? liftModelPose;
  SpatialCinematicActorPose? Function()? heroStoryPose;
  SpatialCinematicActorPose? Function(MapEntity)? npcStoryPose;
  SpatialCinematicActorPose? Function(MapEntity)? npcAutonomousPose;
  SpatialCinematicCameraPose? Function()? storyCamera;
  SpatialVisualPatch visualOverrides = SpatialVisualPatch();
  SpatialVisualPatch worldTimeOverrides = SpatialVisualPatch();
  final graphics = ValueNotifier(const RuntimeGraphicsPreferences());
  SpatialVisualPatch cinematicVisualOverrides = SpatialVisualPatch();
  final cinematicFadeOpacity = ValueNotifier(0.0);
  SpatialVisualPatch Function()? worldVisualProfile;
  VoidCallback? onCancelStory, onSkipStory, onBeforeMapChange;
  final storyActive = ValueNotifier(false);
  bool storyInputLocked = false;
  final _companionTrail = PartyCompanionTrail();
  ProjectCharacterEntry? _companionCharacter;

  PartyCompanionTrailPoint? get companionPosition => _companionTrail.position;
  String? get companionCharacterId => _companionCharacter?.id;

  PartyCompanionTrail captureCompanionTrail() => _companionTrail.capture();

  void restoreCompanionTrail(PartyCompanionTrail snapshot) {
    final lead = presentationStateProvider?.call().party.members
        .where((pokemon) => !pokemon.isFainted && !pokemon.isEgg).firstOrNull;
    if (snapshot.mapId == bundle.map.id && snapshot.individualId == lead?.individualId) {
      _companionTrail.restore(snapshot);
    }
  }

  void _updateCompanion(double dt) {
    final config = bundle.manifest.partyCompanion;
    final state = presentationStateProvider?.call();
    final lead = state?.party.members
        .where((pokemon) => !pokemon.isFainted && !pokemon.isEgg)
        .firstOrNull;
    final visual = lead == null
        ? null
        : config.resolve(lead.speciesId, lead.formId);
    if (!config.enabled ||
        visual == null ||
        transitioning.value) {
      _companionTrail.clear();
      _companionCharacter = null;
      return;
    }
    _companionCharacter = bundle.manifest.characters
        .where((actor) => actor.id == visual.characterId)
        .firstOrNull;
    final previousCompanion = _companionTrail.position;
    final story = heroStoryPose?.call();
    final groundY = story == null ? movement.groundY : cinematicHeightAt(story.x, story.z);
    _companionTrail.observe(
      mapId: bundle.map.id,
      individualId: lead!.individualId,
      x: story?.x ?? movement.x,
      z: story?.z ?? movement.z,
      y: story == null ? movement.y : groundY + story.liftCells,
      groundY: groundY,
      airborne: story == null ? movement.isJumping : story.liftCells > .000001,
      traversalSpeed: movement.jumpSpeed,
      dt: dt,
      paused: presentationPaused || interactionActive.value,
      canTraverse: (fromX, fromZ, toX, toZ) =>
          movement.canTraverseActor(fromX, fromZ, toX, toZ),
    );
    final currentCompanion = _companionTrail.position;
    if (!presentationPaused && !interactionActive.value &&
        previousCompanion != null && currentCompanion != null &&
        !currentCompanion.airborne &&
        (_companionTrail.moving || previousCompanion.airborne) &&
        (previousCompanion.airborne ||
         previousCompanion.x.floor() != currentCompanion.x.floor() ||
         previousCompanion.z.floor() != currentCompanion.z.floor())) {
      _smartTileAnimations.onActorEnteredCell(GridPos(
          x: currentCompanion.x.floor(), y: currentCompanion.z.floor()));
    }
  }

  SpatialActorVisual? _companionFrame() {
    final actor = _companionCharacter;
    final position = _companionTrail.position;
    if (actor == null || position == null) return null;
    final facing = _companionTrail.facingX.abs() > _companionTrail.facingZ.abs()
        ? (_companionTrail.facingX > 0 ? EntityFacing.east : EntityFacing.west)
        : (_companionTrail.facingZ < 0 ? EntityFacing.north : EntityFacing.south);
    final motion = _companionTrail.moving
        ? CharacterAnimationState.walk
        : CharacterAnimationState.idle;
    final animation = actor.animations
            .where((value) => value.direction == facing && value.state == motion)
            .firstOrNull ??
        actor.animations.firstWhere((value) =>
            value.direction == facing &&
            value.state == CharacterAnimationState.walk);
    final total = animation.frames
        .fold<int>(0, (sum, frame) => sum + frame.durationMs);
    var remaining = (_companionTrail.animationSeconds * 1000).floor();
    remaining = animation.loop
        ? remaining % total
        : remaining.clamp(0, total - 1);
    var frame = animation.frames.last;
    for (final candidate in animation.frames) {
      if (remaining < candidate.durationMs) {
        frame = candidate;
        break;
      }
      remaining -= candidate.durationMs;
    }
    final resolved = _resolve(animation, frame, actor: actor);
    return SpatialActorVisual(
      x: position.x,
      z: position.z,
      y: (liftHeightAt?.call(bundle.map.id,position.x,position.z) ?? position.groundY) + position.y - position.groundY,
      groundY: liftHeightAt?.call(bundle.map.id,position.x,position.z) ?? position.groundY,
      contactShadow: actor.contactShadow ?? bundle.manifest.settings.actorContactShadowsByDefault,
      texture: _textures[resolved.imageId]!,
      frame: resolved.sourceRect,
    );
  }

  SpatialActorRuntimeState? actorRuntimeState(MapEntity entity) {
    final pose = npcStoryPose?.call(entity) ?? npcAutonomousPose?.call(entity);
    return pose == null
        ? worldStateProvider?.call().actorState(bundle.map.id, entity.id)
        : SpatialActorRuntimeState(x: pose.x, z: pose.z, facing: pose.facing);
  }

  bool modelIsPresent(String mapId, String instanceId) {
    final source = mapId == bundle.map.id
        ? bundle
        : _preparedMaps[mapId]?.bundle;
    if (source == null) return false;
    final index = _modelPresenceIndices[source.map] ??=
        _SpatialModelPresenceIndex(source.map);
    final entityId = index.entityIdsByInstanceId[instanceId];
    if (entityId == null) return true;
    final entity = index.entitiesById[entityId];
    return entity != null && (entityIsPresent?.call(mapId, entity) ?? true);
  }

  SpatialModelRuntimeState? modelRuntimeState(
    String mapId,
    String instanceId,
  ) =>
      _nativeDoor.poseFor(mapId, instanceId) ??
      liftModelPose?.call(mapId, instanceId) ??
      worldStateProvider?.call().modelState(mapId, instanceId) ??
      (mapId == bundle.map.id
              ? _smartTileAnimations
              : _preparedMaps[mapId]?.animations)
          ?.stateFor(instanceId);

  int rasterAnimationElapsedMsForCell(
    String mapId,
    String layerId,
    int cellX,
    int cellY,
    int elapsedMs,
  ) =>
      (mapId == bundle.map.id
              ? _smartTileAnimations
              : _preparedMaps[mapId]?.animations)
          ?.rasterElapsedMsForCell(
            layerId: layerId,
            cellX: cellX,
            cellY: cellY,
            globalElapsedMs: elapsedMs,
          ) ??
      elapsedMs;

  ({bool active, int elapsedMs}) actorOcclusionStateForCell(
    String mapId, String layerId, int cellX, int cellY, int elapsedMs,
  ) => (mapId == bundle.map.id ? _smartTileAnimations : _preparedMaps[mapId]?.animations)
      ?.actorOcclusionStateForCell(layerId: layerId, cellX: cellX, cellY: cellY, globalElapsedMs: elapsedMs)
      ?? (active: false, elapsedMs: 0);

  void attachWorldStateProviders() {
    final source = bundle;
    final index = _modelPresenceIndices[source.map] ??=
        _SpatialModelPresenceIndex(source.map);
    movement.terrainHeightOverride = (x,z) => liftHeightAt?.call(source.map.id,x,z);
    movement.entityProjection = (entity) => entityProjection == null ? entity :
      entityProjection!(source.map.id, entity);
    movement.setRuntimeStateProviders(
      modelStateProvider: (id) => modelRuntimeState(source.map.id, id),
      actorStateProvider: (id) {
        final entity = index.entitiesById[id];
        return entity == null
            ? null
            : source.map.id == bundle.map.id
                ? actorRuntimeState(entity)
                : worldStateProvider?.call().actorState(source.map.id, id);
      },
    );
    if (_preparedMaps.containsKey(bundle.map.id)) {
      _preparedMaps[bundle.map.id] = _capturePrepared();
      _trimPreparedMaps();
    }
  }

  final interactionError = ValueNotifier<Object?>(null);
  final interactionActive = ValueNotifier(false);
  final dialoguePresentation = ValueNotifier<DialoguePresentationSnapshot?>(
    null,
  );
  DialogueOverlayComponent? _dialogue;
  DialogueFeedbackPlaybackPort? dialogueFeedbackPlaybackPort;
  FlameNarrativeSoundPlaybackAdapter? _dialogueSound;
  RuntimeMusicService? _dialogueMusic;
  String? _dialogueEntityId;
  Completer<SceneDialogueRuntimeAwaitableResult>? _dialogueCompletion;
  RuntimeDialogueTextSpeed textSpeed = RuntimeDialogueTextSpeed.instant;
  bool dialoguePaused = false;
  bool _lifecyclePaused = false;
  bool get lifecyclePaused => _lifecyclePaused;
  void Function(bool paused)? onLifecyclePausedChanged;
  double _presentationSeconds = 0;
  double get presentationSeconds => _presentationSeconds;
  bool get presentationPaused => dialoguePaused || _lifecyclePaused;
  void setLifecyclePaused(bool paused) {
    if (_disposed) return;
    _lifecyclePaused = paused;
    onLifecyclePausedChanged?.call(paused);
    if (paused && transitioning.value) cancelPendingTransition();
    movement.setPaused(
      presentationPaused || interactionActive.value || transitioning.value,
    );
  }

  int _revision = 0, _interactionGeneration = 0;
  Future<Uint8List> groundImageBytes(String id) =>
      groundImageBytesForBundle(bundle, id);

  Future<Uint8List> groundImageBytesForBundle(RuntimeMapBundle source, String id) async {
    final path = source.runtimeImageAbsolutePathsById[id];
    if (path == null) throw StateError('Image du terrain introuvable : $id');
    final file = File(path);
    if (await file.length() > source.resourceBudget.profile.maximumEncodedBytes) {
      throw const RuntimeResourceAdmissionException('encoded_bytes');
    }
    return file.readAsBytes();
  }

  final Map<String, EntityFacing> npcFacing = {};
  MapEntity? _interactionEntity;
  String? _interactionMapId;

  MapEntity? get interactionEntity =>
      _interactionMapId == bundle.map.id ? _interactionEntity : null;

  Future<T> withEntityInteraction<T>(
      MapEntity? entity, Future<T> Function() operation) async {
    if (entity?.npc == null) return operation();
    final target = entity!;
    final mapId = bundle.map.id;
    final previousEntity = _interactionEntity;
    final previousMapId = _interactionMapId;
    final previousFacing = npcFacing[target.id];
    _interactionEntity = target;
    _interactionMapId = mapId;
    npcFacing[target.id] = spatialNpcFacingPlayer(target,
        x: movement.x, z: movement.z, actorState: actorRuntimeState(target));
    try {
      return await operation();
    } finally {
      _interactionEntity = previousEntity;
      _interactionMapId = previousMapId;
      if (!_disposed && bundle.map.id == mapId) {
        if (previousFacing == null) {
          npcFacing.remove(target.id);
        } else {
          npcFacing[target.id] = previousFacing;
        }
      }
    }
  }

  void setTextSpeed(RuntimeDialogueTextSpeed value) {
    textSpeed = value;
    _dialogue?.setTextSpeed(value);
  }

  Future<void> interact() async {
    if (_disposed ||
        presentationPaused ||
        interactionActive.value ||
        transitioning.value) {
      return;
    }
    final entity = findSpatialNpcInteraction(
        scene: bundle.map.spatialScene!,
        entities: bundle.map.entities,
        x: movement.x,
        z: movement.z,
      facing: movement.facing,
    );
    if (entity == null) return;
    final ref = entity.npc?.dialogue;
    if (ref == null) return;
    await _openDialogue(ref, entity: entity);
  }

  Future<void> prepareTransientCinematic(CinematicAsset asset) =>
      _assets.emotes.prepare([asset]);

  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(DialogueRef ref,
      {MapEntity? entity, String Function(String)? transformText,
      List<SceneDialogueChoicePolicy> choicePolicies = const [],
    List<SceneDialogueLinePolicy> linePolicies = const [],
  }) async {
    final completion = Completer<SceneDialogueRuntimeAwaitableResult>();
    await _openDialogue(ref,
        entity: entity, completion: completion, transformText: transformText,
      choicePolicies: choicePolicies,
      linePolicies: linePolicies,
    );
    return completion.future;
  }

  Future<void> _openDialogue(DialogueRef ref,
      {MapEntity? entity,
      Completer<SceneDialogueRuntimeAwaitableResult>? completion,
      String Function(String)? transformText,
      List<SceneDialogueChoicePolicy> choicePolicies = const [],
    List<SceneDialogueLinePolicy> linePolicies = const [],
  }) async {
    if (_disposed || interactionActive.value || transitioning.value) {
      completion?.complete(const SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
          message: 'The spatial dialogue owner is unavailable.',
        ),
      );
      return;
    }
    final resolved = resolveDialogue(
        entityId: entity?.id ?? 'scene',
        ref: ref,
        projectRootDirectory: bundle.projectRootDirectory,
      dialogues: bundle.manifest.dialogues,
    );
    if (resolved == null) {
      completion?.complete(const SceneDialogueRuntimeAwaitableResult.failed(
          errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
          message: 'The authored dialogue is unavailable.',
        ),
      );
      return;
    }
    _dialogueCompletion = completion;
    _dialogueEntityId = entity?.id;
    interactionError.value = null;
    final generation = ++_interactionGeneration;
    if (entity != null) {
      npcFacing[entity.id] = spatialNpcFacingPlayer(entity,
        x: movement.x,
        z: movement.z,
        actorState: actorRuntimeState(entity),
      );
    }
    movement.setPaused(true);
    interactionActive.value = true;
    try {
      final loaded = await loadDialogueContent(resolved);
      if (_disposed || generation != _interactionGeneration) return;
      if (loaded == null) {
        throw StateError('Le dialogue ne peut pas être ouvert.');
      }
      final state = presentationStateProvider?.call() ?? const GameState(saveId: 'dialogue');
      final configured = interpolateDialogueVariables(
          loaded.withChoicePolicies(choicePolicies).withLinePolicies(linePolicies), state.scriptVariables,
        factResolver: NarrativeFactRuntimeResolver.fromFacts(
          bundle.manifest.facts,
        ),
        factState: state.narrativeFactRuntimeState,
        storyFlags: state.storyFlags,
      );
      validateDialogueFeedbackReferences(configured.lineFeedback,
        iconAssetIds: bundle.runtimeImageAbsolutePathsById.keys.toSet(),
        mediaAssets: bundle.manifest.cinematicMediaAssets,
      );
      final overlay = DialogueOverlayComponent(
        resourceBudget: bundle.resourceBudget,
          session:
              transformText == null ? configured : configured.mapText(transformText),
          onFinished: (outcome) => _finishDialogue(
          SceneDialogueRuntimeAwaitableResult.completed(outcomeId: outcome),
        ),
          viewportSize: Vector2(640, 480),
          renderInFlame: false,
          textSpeed: textSpeed,
          feedbackPlaybackPort: configured.lineFeedback.any((feedback) => feedback.audioCue != null)
              ? dialogueFeedbackPlaybackPort ?? (_dialogueSound ??= FlameNarrativeSoundPlaybackAdapter(
                  mediaAssets: bundle.manifest.cinematicMediaAssets,
                    resolvePath: (asset) => resolveDialogueFeedbackProjectFile(
                      bundle.projectRootDirectory,
                      asset.relativePath,
                    ),
                    musicService: _dialogueMusic ??= RuntimeMusicService(),
                  ))
            : null,
          iconBytesLoader: ProjectDialogueIconLoader(projectRoot: bundle.projectRootDirectory,
          absolutePathsByAssetId: bundle.runtimeImageAbsolutePathsById,
        ).load,
          onFailed: (error) {
            if (!_disposed && generation == _interactionGeneration) {
              interactionError.value = error;
              _finishDialogue(const SceneDialogueRuntimeAwaitableResult.failed(
                  errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
                message: 'The dialogue feedback could not be presented.',
              ),
            );
            }
          },
          onPresentationSnapshotChanged: (_) {
            if (!_disposed && generation == _interactionGeneration) {
              _publishDialogue();
            }
        },
      );
      _dialogue = overlay;
      await overlay.onLoad();
      if (_disposed || generation != _interactionGeneration) {
        overlay.removeFromParent();
        return;
      }
      _publishDialogue();
    } on Object catch (error) {
      if (!_disposed && generation == _interactionGeneration) {
        interactionError.value = error;
        _dialogue?.removeFromParent();
        _dialogue = null;
        _completeDialogue(SceneDialogueRuntimeAwaitableResult.failed(
            errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
            message: 'The dialogue could not be shown: $error',
          ),
        );
      }
    } finally {
      if (!_disposed &&
          generation == _interactionGeneration &&
          _dialogue == null) {
        closeDialogue();
      }
    }
  }

  void dispatchDialogueCommand(DialoguePresentationCommand command) {
    final snapshot = dialoguePresentation.value;
    if (_disposed ||
        presentationPaused ||
        snapshot == null ||
        !validateDialoguePresentationCommand(snapshot, command).accepted) {
      return;
    }
    if (command is DialogueAdvanceCommand) {
      _dialogue?.advance();
    } else if (command is DialogueSelectChoiceCommand) {
      final state = _dialogue?.currentSession.state;
      if (state is DialogueWaitingForChoice) {
        _dialogue!.moveCursor(command.choiceIndex - state.selectedIndex);
        _dialogue!.confirmChoice();
      }
    }
  }

  void moveDialogueCursor(int delta) {
    if (!_disposed && !presentationPaused) _dialogue?.moveCursor(delta);
  }

  void confirmDialogue() {
    if (_disposed || presentationPaused) return;
    if (_dialogue?.isShowingChoices ?? false) {
      _dialogue!.confirmChoice();
    } else {
      _dialogue?.advance();
    }
  }

  void cancelDialogue() {
    if (_disposed || presentationPaused) return;
    if (_dialogue?.isShowingChoices ?? false) {
      _dialogue!.cancelChoice();
    } else {
      closeDialogue();
    }
  }

  void _publishDialogue() {
    final dialogue = _dialogue;
    final state = dialogue?.currentSession.state;
    if (dialogue == null ||
        (state is! DialogueShowingLine && state is! DialogueWaitingForChoice)) {
      closeDialogue();
      return;
    }
    dialoguePresentation.value = buildDialoguePresentationSnapshot(
        session: dialogue.currentSession,
        revision: ++_revision,
        visibleText: dialogue.visibleText,
        isCurrentLineFullyRevealed: dialogue.isCurrentLineFullyRevealed,
        iconPngBytes: dialogue.currentPresentationSnapshot?.iconPngBytes ?? const {},
      iconImages: dialogue.currentPresentationSnapshot?.iconImages ?? const {},
    );
  }

  void closeDialogue() {
    if (_disposed) return;
    _finishDialogue(const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'The spatial dialogue was cancelled.',
      ),
    );
  }

  void _completeDialogue(SceneDialogueRuntimeAwaitableResult result) {
    final completion = _dialogueCompletion;
    _dialogueCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(result);
    }
  }

  void _finishDialogue(SceneDialogueRuntimeAwaitableResult result) {
    _completeDialogue(result);
    _interactionGeneration++;
    _dialogue?.removeFromParent();
    _dialogue = null;
    _dialogueEntityId = null;
    dialoguePresentation.value = null;
    movement.setPaused(presentationPaused || transitioning.value);
    interactionActive.value = false;
  }

  static Future<SpatialExplorationSession> load(
    RuntimeMapBundle bundle, {
    GridPos? arrival,
    PlayerSpatialPosition? spatialArrival,
    EntityFacing? facing,
    String? characterId,
    bool Function(String mapId, MapEntity entity)? entityIsPresent,
    MapEntity? Function(String mapId, MapEntity entity)? entityProjection,
    GameState Function()? presentationStateProvider,
    SpatialWorldState Function()? worldStateProvider,
    Future<RuntimeMapBundle> Function(String)? loadMap,
    bool allowNpcOverlapRecovery = false,
    Iterable<MapData> knownMaps = const [],
  }) =>
      _load(bundle,
          allowNpcOverlapRecovery: allowNpcOverlapRecovery,
          arrival: arrival,
          spatialArrival: spatialArrival,
          facing: facing,
          characterId: characterId,
          entityIsPresent: entityIsPresent,
          entityProjection: entityProjection,
          presentationStateProvider: presentationStateProvider,
          worldStateProvider: worldStateProvider,
          loadMap: loadMap,
    knownMaps: knownMaps,
  );

  static Future<SpatialExplorationSession> _load(
    RuntimeMapBundle bundle, {
    GridPos? arrival,
    PlayerSpatialPosition? spatialArrival,
    EntityFacing? facing,
    String? characterId,
    bool Function(String mapId, MapEntity entity)? entityIsPresent,
    MapEntity? Function(String mapId, MapEntity entity)? entityProjection,
    GameState Function()? presentationStateProvider,
    SpatialWorldState Function()? worldStateProvider,
    Future<RuntimeMapBundle> Function(String)? loadMap,
    _SpatialActorAssets? sharedAssets,
    SpatialModelRuntimeState? Function(String mapId, String instanceId)?
    modelPoseProvider,
    bool validateSpawn = true,
    bool allowNpcOverlapRecovery = false,
    Iterable<MapData> knownMaps = const [],
  }) async {
    final scene = bundle.map.spatialScene;
    if (scene == null ||
        bundle.manifest.settings.dimension != ProjectDimension.threeD) {
      throw StateError('Une carte 3D est requise.');
    }
    final connectionDirections = <MapConnectionDirection>{};
    if (bundle.map.connections.any(
      (connection) => !connectionDirections.add(connection.direction),
    )) {
      throw StateError(
        'Plusieurs voisines sur un bord 3D ne sont pas prises en charge.',
      );
    }
    if (characterId != null) {
      bundle = await prepareRuntimePlayerAvatarBundle(bundle, characterId);
    }
    final id = characterId ?? bundle.manifest.settings.defaultPlayerCharacterId;
    final character = characterId == null
        ? bundle.manifest.characters.where((v) => v.id == id).firstOrNull
        : resolveScenePlayerAvatarCharacter(bundle.manifest, characterId);
    if (character == null || character.animations.isEmpty) {
      throw StateError(
        'Choisissez un héros animé dans les réglages du projet.',
      );
    }
    for (final direction in [
      EntityFacing.north,
      EntityFacing.south,
      EntityFacing.east,
      EntityFacing.west,
    ]) {
      if (!character.animations.any((v) =>
          v.direction == direction &&
          v.state == CharacterAnimationState.walk &&
            v.frames.isNotEmpty,
      )) {
        throw StateError('Animation de marche absente : ${direction.name}');
      }
    }
    final characters = <ProjectCharacterEntry>{character};
    if (bundle.manifest.partyCompanion.enabled) {
      for (final visual in bundle.manifest.partyCompanion.mappings) {
        final actor = bundle.manifest.characters.where((entry) => entry.id == visual.characterId).firstOrNull;
        if (actor == null) throw StateError('Personnage du compagnon absent : ${visual.characterId}');
        characters.add(actor);
      }
    }
    for (final entity in bundle.map.entities) {
      for (final variant in entity.presentation?.variants ?? const <MapEntityPresentationVariant>[]) {
        final id = variant.characterId;
        if (id == null) continue;
        final matching = bundle.manifest.characters.where((entry) => entry.id == id).toList();
        if (matching.length != 1) throw StateError('Personnage de variante absent : $id');
        characters.add(matching.single);
      }
    }
    for (final entity in bundle.map.entities.where(
      (entity) => entity.kind == MapEntityKind.npc,
    )) {
      final npcCharacter = bundle.manifest.characters
          .where((c) => c.id == entity.npc?.characterId)
          .firstOrNull;
      if (npcCharacter == null) {
        throw StateError('Personnage du PNJ absent : ${entity.id}');
      }
      characters.add(npcCharacter);
    }
    SpatialMovementController movementAt(PlayerSpatialPosition? position) => SpatialMovementController.fromMap(
        map: bundle.map,
        models: bundle.manifest.models3d,
        arrival: arrival,
        spatialArrival: position,
        entityPresencePredicate: (entity) =>
            entityIsPresent?.call(bundle.map.id, entity) ?? true,
        entityProjection: (entity) => entityProjection == null ? entity :
          entityProjection(bundle.map.id, entity),
        modelStateProvider: (id) =>
          modelPoseProvider?.call(bundle.map.id, id) ??
            worldStateProvider?.call().modelState(bundle.map.id, id),
        actorStateProvider: (id) =>
            worldStateProvider?.call().actorState(bundle.map.id, id),
        validateSpawn: validateSpawn && position == null,
      facing: facing,
    );
    var movement = movementAt(spatialArrival);
    if (allowNpcOverlapRecovery && spatialArrival != null && !movement.isPositionTraversable) {
      final recovered = movement.findNpcOverlapRecovery();
      if (recovered != null) movement = movementAt(recovered);
    }
    final entityVisuals = SpatialEntityVisualPlan(bundle.map, bundle.manifest);
    movement.entityProjection = (entity) => entityProjection == null ? entity :
      entityProjection(bundle.map.id, entity);
    final assets = sharedAssets ?? _SpatialActorAssets(bundle.resourceBudget);
    final session = SpatialExplorationSession._(
        bundle,
        character,
        movement,
        assets,
        sharedAssets == null,
      {for (final map in knownMaps) map.id: map},
    );
    final images = assets.images;
    try {
      final paths = bundle.runtimeImageAbsolutePathsById;
      final ids = {
        ...entityVisuals.imageIds,
        for (final actor in characters)
          for (final animation in actor.animations)
            if (animation.sourceAssetId case final asset?
                when asset.trim().isNotEmpty)
              characterAnimationRuntimeImageId(asset)
            else
              actor.tilesetId,
      };
      session._imageIds = ids;
      assets.owners[session._assetOwner] = ids;
      for (final imageId in ids) {
        final path = paths[imageId];
        if (path == null) {
          throw StateError('Image du héros introuvable : $imageId');
        }
        await assets.load(imageId, path, entityVisuals);
      }
      await assets.emotes.prepare(bundle.manifest.cinematics.where((asset) => asset.mapId == bundle.map.id));
      entityVisuals.validateImages(images);
      session._entityVisuals = entityVisuals;
      session.entityIsPresent = entityIsPresent;
      session.entityProjection = entityProjection;
      session.presentationStateProvider = presentationStateProvider;
      session.worldStateProvider = worldStateProvider;
      session._loadMap = loadMap ??
          (id) => loadRuntimeMapBundle(
            projectFilePath: p.join(
              bundle.projectRootDirectory,
              'project.json',
            ),
              mapId: id,
              preloadedManifest: bundle.projectCatalog == null ? bundle.manifest : null,
              projectCatalog: bundle.projectCatalog,
              resourceBudget: bundle.resourceBudget,
            additionalCharacterIds: {session.character.id},
          );
      session._warps = SpatialWarpController(
        map: bundle.map,
        x: movement.x,
        z: movement.z,
      );
      for (final actor in characters) {
        for (final animation in actor.animations) {
          if (animation.frames.isEmpty) {
            throw StateError('Animation du héros vide.');
          }
          for (final frame in animation.frames) {
            final resolved = session._resolve(animation, frame, actor: actor);
            final image = images[resolved.imageId]!;
            final rect = resolved.sourceRect;
            if (frame.durationMs <= 0 ||
                rect.left < 0 ||
                rect.top < 0 ||
                rect.width <= 0 ||
                rect.height <= 0 ||
                rect.right > image.width ||
                rect.bottom > image.height) {
              throw StateError('Frame du héros invalide.');
            }
          }
        }
      }
      session.frames(0);
      session._preparedMaps[bundle.map.id] = session._capturePrepared();
      session._mapOrigins[bundle.map.id] = ui.Offset.zero;
      if (validateSpawn && spatialArrival != null) {
        await session._validateSavedPosition(npcRecoveryAttempted: allowNpcOverlapRecovery);
      }
      return session;
    } on Object {
      assets.owners.remove(session._assetOwner);
      if (sharedAssets == null) assets.dispose();
      rethrow;
    }
  }

  ResolvedCharacterAnimationFrameSource _resolve(
    CharacterAnimation animation,
    CharacterAnimationFrame frame, {
    ProjectCharacterEntry? actor,
  }) =>
      _resolver.resolveFrame(
          character: actor ?? character,
          animation: animation,
          frame: frame,
          tileWidth: bundle.manifest.settings.tileWidth,
          tileHeight: bundle.manifest.settings.tileHeight,
        availableImageIds: _images.keys.toSet(),
      ) ??
      (throw StateError('Source d’animation du héros indisponible.'));
  SpatialActorVisual frame(double dt) {
    if (!_disposed) {
      final previousMapId = bundle.map.id;
      final previousCell = GridPos(
        x: movement.x.floor(),
        y: movement.z.floor(),
      );
      if (!presentationPaused && !transitioning.value) {
        _smartTileAnimations.update(dt);
        for (final prepared in _preparedMaps.values) {
          if (!identical(prepared.animations, _smartTileAnimations)) {
            prepared.animations.update(dt);
          }
        }
      }
      if (!presentationPaused &&
          !storyInputLocked &&
          !interactionActive.value &&
          !transitioning.value) {
        final input = movement.inputDirection;
        final facing = input.x > 0
            ? EntityFacing.east
            : input.x < 0
            ? EntityFacing.west
            : input.z < 0
            ? EntityFacing.north
            : EntityFacing.south;
        final door = _warps.candidateDoorApproach(
          x: movement.x,
          z: movement.z,
          facing: facing,
          inputX: input.x,
          inputZ: input.z,
        );
        if (door != null) unawaited(enterWarp(door));
      }
      final wasJumping = movement.isJumping;
      movement.update(dt);
      _updateCompanion(dt);
      if (!presentationPaused &&
          !storyInputLocked &&
          !movement.isJumping &&
          !interactionActive.value &&
          !transitioning.value) {
        final warp = _warps.update(
            x: movement.x,
            z: movement.z,
            facing: movement.facing,
          bumpedCell: movement.bumpedCell,
        );
        if (warp != null) {
          unawaited(enterWarp(warp));
        } else {
          final direction = movement.edgeExitDirection;
          final connection = direction == null
              ? null
              : findMapConnection(bundle.map, direction);
          if (connection != null) unawaited(enterConnection(connection));
        }
      }
      final cell = GridPos(x: movement.x.floor(), y: movement.z.floor());
      if (!presentationPaused &&
          !storyInputLocked &&
          !transitioning.value &&
          !movement.isJumping &&
          (movement.moving || wasJumping) &&
          (previousMapId != bundle.map.id || previousCell != cell || wasJumping)) {
        _smartTileAnimations.onPlayerEnteredCell(cell);
      }
      onFrame?.call();
      if (!presentationPaused && dt.isFinite && dt > 0) {
        _dialogue?.update(dt.clamp(0.0, .05));
      }
    }
    final story = heroStoryPose?.call();
    final facing = story?.facing ?? movement.facing;
    final climbing =
        _nativeDoor.isClimbing && _nativeDoor.playerPoseMapId == bundle.map.id;
    final state = climbing
        ? CharacterAnimationState.climb
        : story?.motion ??
        (movement.moving
            ? (movement.running
                ? CharacterAnimationState.run
                : CharacterAnimationState.walk)
            : CharacterAnimationState.idle);
    final animation = character.animations
            .where((v) => v.state == state && v.direction == facing)
            .firstOrNull ??
        character.animations
            .where((v) =>
                v.state == CharacterAnimationState.walk &&
                  v.direction == facing,
            )
            .firstOrNull;
    if (animation == null) {
      throw StateError(
        'Animation directionnelle du héros absente : ${movement.facing.name}',
      );
    }
    final total = animation.frames.fold<int>(
      0,
      (sum, frame) => sum + frame.durationMs,
    );
    var remaining =
        ((story?.animationSeconds ?? movement.animationSeconds) * 1000).floor();
    remaining =
        animation.loop ? remaining % total : remaining.clamp(0, total - 1);
    var selected = animation.frames.last;
    for (final frame in animation.frames) {
      if (remaining < frame.durationMs) {
        selected = frame;
        break;
      }
      remaining -= frame.durationMs;
    }
    final resolved = _resolve(animation, selected);
    return SpatialActorVisual(
        x: story?.x ?? movement.x,
        groundY: story == null ? movement.groundY : cinematicHeightAt(story.x, story.z),
        contactShadow:
          !climbing &&
          (character.contactShadow ?? bundle.manifest.settings.actorContactShadowsByDefault),
        y: story == null
            ? movement.y + (climbing ? _nativeDoor.playerPose!.liftCells : 0)
          : cinematicHeightAt(story.x, story.z) + story.liftCells,
        z: story?.z ?? movement.z,
        texture: _textures[resolved.imageId]!,
      frame: resolved.sourceRect,
    );
  }

  Map<String, SpatialActorVisual> frames(double dt, {Set<String>? mapIds}) {
    if (_disposed) return const {};
    if (nativeDoorTraversalActive) {
      try {
        _nativeDoor.update(dt, paused: presentationPaused);
        final pose = _nativeDoor.playerPose;
        if (pose != null && _nativeDoor.playerPoseMapId == bundle.map.id) {
          movement.setNativeTraversalPose(
            x: pose.x,
            z: pose.z,
            facing: pose.facing,
            moving: pose.moving,
            animationSeconds: pose.animationSeconds,
          );
          final door = _nativeArrivalDoor;
          if (door != null &&
              door.mapId == bundle.map.id &&
              door.instance.blocksMovement &&
              (_nativeDoor.phase == SpatialDoorTraversalPhase.closingArrival ||
                  _nativeDoor.phase == SpatialDoorTraversalPhase.completed) &&
              !_canCloseNativeDoor(door.instance.id)) {
            throw StateError('Un personnage bloque la fermeture de la porte.');
          }
        }
      } on Object catch (error) {
        interactionError.value = error;
        cancelPendingTransition();
      }
      nativeDoorBlackout.value = _nativeDoor.blackoutOpacity;
    }
    if (dt.isFinite && dt >= 0) {
      environmentClock.advance(dt, paused: presentationPaused || transitioning.value);
    }
    onPresentationFrame?.call(dt, presentationPaused || transitioning.value);
    if (dt.isFinite && dt > 0 && !presentationPaused && !transitioning.value) {
      _presentationSeconds += dt;
    }
    final hero = frame(dt);
    final result = <String, SpatialActorVisual>{
      if (nativeDoorHeroVisible) 'hero': hero,
      'party-companion': ?_companionFrame(),
    };
    final occupants = <String, Map<String, GridPos?>>{bundle.map.id: {}};
    final reactingActors = <String, Set<String>>{};
    GridPos? occupiedCell(SpatialActorVisual visual) =>
        visual.y > (visual.groundY ?? visual.y) + .000001
          ? null : GridPos(x: visual.x.floor(), y: visual.z.floor());
    if (result['hero'] != null) {
      occupants[bundle.map.id]!['hero'] = occupiedCell(hero);
    }
    final companion = result['party-companion'];
    final lead = presentationStateProvider?.call().party.members.where((p) => !p.isFainted && !p.isEgg).firstOrNull;
    if (companion != null && lead != null) {
      final actorId = 'companion:${lead.individualId}';
      occupants[bundle.map.id]![actorId] = occupiedCell(companion);
    }
    final heroEmote = heroStoryPose?.call();
    if (result['hero'] != null && heroEmote?.emoteId != null) {
      result['cinematic-emote:hero'] = _assets.emotes.frame(actor: hero,
          emoteId: heroEmote!.emoteId!, elapsedSeconds: heroEmote.emoteElapsedSeconds);
    }
    final activeOrigin = _mapOrigins[bundle.map.id] ?? ui.Offset.zero;
    final visible = mapIds ??
        {
          bundle.map.id,
          ..._visibleMaps,
          for (final connection in viewConnections) connection.targetMapId,
        };
    for (final id in visible) {
      final prepared = _preparedMaps[id] ??
          (id == bundle.map.id ? _capturePrepared() : null);
      if (prepared == null) continue;
      final source = prepared.bundle;
      final offset = (_mapOrigins[id] ?? activeOrigin) - activeOrigin;
      for (final entity in source.map.entities.where(
        (entity) => entity.presentation != null,
      )) {
        _presentationFacingFor(entity, source,
          worldStateProvider?.call().actorState(source.map.id, entity.id),
        );
      }
      bool present(MapEntity entity) =>
          entityIsPresent?.call(id, entity) ?? true;
      final visuals = {
        for (final entity in source.map.entities.map((entity) => entityProjection == null
                      ? entity
                      : entityProjection!(id, entity),
                )
                .whereType<MapEntity>()
                .where(
                  (entity) =>
                      entity.kind == MapEntityKind.npc && present(entity),
                ))
          'npc:${entity.id}': npcFrame(entity, sourceBundle: source),
        ...prepared.visuals.frames(
            textures: _textures,
            elapsedMs: (_presentationSeconds * 1000).floor(),
          isPresent: present,
        ),
      };
      final mapOccupants = occupants.putIfAbsent(id, () => {});
      final mapReactingActors = reactingActors.putIfAbsent(id, () => {});
      for (final entry in visuals.entries) {
        final visual = entry.value;
        if (entry.key.startsWith('npc:')) {
          final actorId = '$id:${entry.key}';
          mapOccupants[actorId] = occupiedCell(visual);
          mapReactingActors.add(actorId);
        }
        result['$id:${entry.key}'] = SpatialActorVisual(
            x: visual.x + offset.dx,
            y: visual.y,
            z: visual.z + offset.dy,
            groundY: visual.groundY,
            contactShadow: visual.contactShadow,
            texture: visual.texture,
            frame: visual.frame,
            width: visual.width,
          height: visual.height,
          billboardVerticalOffset: visual.billboardVerticalOffset,
        );
      }
    }
    for (final entity in bundle.map.entities.where((entity) => entity.npc != null)) {
      final pose = npcStoryPose?.call(entity);
      final visual = result['${bundle.map.id}:npc:${entity.id}'];
      if (visual != null && pose?.emoteId != null) {
        result['cinematic-emote:npc:${entity.id}'] = _assets.emotes.frame(
            actor: visual, emoteId: pose!.emoteId!, elapsedSeconds: pose.emoteElapsedSeconds);
      }
    }
    for (final id in {bundle.map.id, ..._preparedMaps.keys}) {
      final animations = id == bundle.map.id ? _smartTileAnimations : _preparedMaps[id]!.animations;
      animations.synchronizeActorOccupancy(occupants[id] ?? const {}, reactingActors: reactingActors[id] ?? const {});
    }
    return result;
  }

  SpatialActorVisual npcFrame(
    MapEntity entity, {
    RuntimeMapBundle? sourceBundle,
  }) {
    final source = sourceBundle ?? bundle;
    final active = source.map.id == bundle.map.id;
    final actor = source.manifest.characters.firstWhere(
      (c) => c.id == entity.npc!.characterId,
    );
    final storyPose = active ? npcStoryPose?.call(entity) : null;
    final pose = storyPose ?? (active ? npcAutonomousPose?.call(entity) : null);
    final saved = active
        ? actorRuntimeState(entity)
        : worldStateProvider?.call().actorState(source.map.id, entity.id);
    final presentationFacing = _presentationFacingFor(entity, source, saved);
    final facing = storyPose?.facing ??
        (active && (_dialogueEntityId == entity.id || interactionEntity?.id == entity.id)
            ? npcFacing[entity.id]
            : null) ??
        pose?.facing ??
        presentationFacing ??
        saved?.facing ??
        (active ? npcFacing[entity.id] : null) ??
        entity.npc!.facing;
    final animation = actor.animations
            .where((clip) =>
                clip.direction == facing &&
                  clip.state == (pose?.motion ?? CharacterAnimationState.idle),
            )
            .firstOrNull ??
        actor.animations.firstWhere((clip) =>
            clip.direction == facing &&
              clip.state == CharacterAnimationState.walk,
        );
    final duration = animation.frames.fold<int>(
      0,
      (sum, frame) => sum + frame.durationMs,
    );
    var elapsed = ((pose?.animationSeconds ?? 0) * 1000).floor();
    elapsed =
        animation.loop ? elapsed % duration : elapsed.clamp(0, duration - 1);
    var selected = animation.frames.last;
    for (final frame in animation.frames) {
      if (elapsed < frame.durationMs) {
        selected = frame;
        break;
      }
      elapsed -= frame.durationMs;
    }
    final resolved = _resolve(animation, selected, actor: actor);
    final x = (saved?.x ?? entity.pos.x + .5) + (entity.size.width - 1) / 2;
    final z = (saved?.z ?? entity.pos.y + .5) + entity.size.height - 1;
    final groundY = active && containsCinematicPoint(x, z)
        ? cinematicHeightAt(x, z)
        : liftHeightAt?.call(source.map.id,x,z) ?? source.map.spatialScene!.worldHeightAt(x, z);
    return SpatialActorVisual(
        x: x,
        z: z,
        y: groundY + (pose?.liftCells ?? 0),
        groundY: groundY,
        contactShadow: actor.contactShadow ?? source.manifest.settings.actorContactShadowsByDefault,
        texture: _textures[resolved.imageId]!,
      frame: resolved.sourceRect,
    );
  }

  EntityFacing? _presentationFacingFor(MapEntity entity, RuntimeMapBundle source,
    SpatialActorRuntimeState? saved,
  ) {
    final state = presentationStateProvider?.call();
    if (entity.presentation == null || state == null) return null;
    final variant = resolveMapEntityPresentation(project: source.manifest,
      gameState: state,
      map: source.map,
      entity: entity,
    );
    if (variant == null) return null;
    final key = '${source.map.id}/${entity.id}';
    final previous = _presentationFacingStates[key];
    final changed = previous != null && previous.declaration != variant.facing;
    final override = changed ? variant.facing :
      previous?.state == saved ? previous?.override : null;
    _presentationFacingStates[key] = (
      declaration: variant.facing,
      override: override,
      state: saved,
    );
    return override;
  }

  Future<Uint8List> modelBytes(String id) => modelBytesForBundle(bundle, id);

  Future<Uint8List> modelBytesForBundle(
    RuntimeMapBundle source,
    String id,
  ) async {
    final model = source.manifest.models3d.where((v) => v.id == id).firstOrNull;
    if (model == null) throw StateError('Modèle absent : $id');
    final path = p.normalize(
      p.join(source.projectRootDirectory, model.relativePath),
    );
    if (!p.isWithin(source.projectRootDirectory, path)) {
      throw StateError('Model path escapes the project.');
    }
    final file = File(path);
    if (await file.length() > source.resourceBudget.profile.maximumEncodedBytes) {
      throw const RuntimeResourceAdmissionException('encoded_bytes');
    }
    return file.readAsBytes();
  }

  Future<void> enterWarp(MapWarp warp) async {
    if (!bundle.map.warps.contains(warp)) return;
    await _transfer(warp.targetMapId, (_) => warp.targetPos, warp: warp);
  }

  SpatialDoorTraversalBinding? _resolveNativeDoor(
    RuntimeMapBundle source,
    MapWarp? warp,
  ) {
    final door = warp?.door;
    if (door == null) return null;
    validateMapWarpDoor(source.map, warp!, models: source.manifest.models3d);
    final instance = source.map.spatialScene!.instances.singleWhere(
      (entry) => entry.id == door.instanceId,
    );
    final model = source.manifest.models3d.singleWhere(
      (entry) => entry.id == instance.modelId,
    );
    return SpatialDoorTraversalBinding(
      mapId: source.map.id,
      instance: instance,
      openAnimationIndex: door.openAnimationIndex,
      closeAnimationIndex: door.closeAnimationIndex,
      openDurationSeconds: model.inspection.animations
          .singleWhere((clip) => clip.index == door.openAnimationIndex)
          .durationSeconds,
      closeDurationSeconds: model.inspection.animations
          .singleWhere((clip) => clip.index == door.closeAnimationIndex)
          .durationSeconds,
      exitPos: door.exitPos,
    );
  }

  bool _canCloseNativeDoor(String instanceId) {
    if (movement.wouldModelBlockActor(instanceId, movement.x, movement.z))
      return false;
    for (final entity in bundle.map.entities.where(
      (entry) => entry.npc != null,
    )) {
      if (!(entityIsPresent?.call(bundle.map.id, entity) ?? true)) continue;
      final pose = actorRuntimeState(entity);
      if (movement.wouldModelBlockActor(
        instanceId,
        pose?.x ?? entity.pos.x + .5,
        pose?.z ?? entity.pos.y + .5,
      )) {
        return false;
      }
    }
    return true;
  }

  Future<void> presentPlayerAvatar(String? characterId) async {
    if (_disposed) throw StateError('The spatial session is closed.');
    final id = characterId ?? bundle.manifest.settings.defaultPlayerCharacterId;
    if (id == null) {
      throw StateError('The default player avatar is unavailable.');
    }
    if (id == character.id) return;
    final avatarBundle = await prepareRuntimePlayerAvatarBundle(bundle, id);
    if (_disposed) throw StateError('The spatial session is closed.');
    final next = resolveScenePlayerAvatarCharacter(avatarBundle.manifest, id);
    final ids = runtimePlayerAvatarImageIds(next);
    final paths = avatarBundle.runtimeImageAbsolutePathsById;
    final avatarVisuals = SpatialEntityVisualPlan(
      avatarBundle.map,
      avatarBundle.manifest,
    );
    final preparationOwner = Object();
    _assets.owners[preparationOwner] = ids;
    try {
      for (final id in ids) {
        final path = paths[id];
        if (path == null) {
          throw StateError('The player avatar media is unavailable: $id');
        }
        await _assets.load(id, path, avatarVisuals);
      }
      if (_disposed) throw StateError('The spatial session is closed.');
      validateRuntimePlayerAvatarImages(
        character: next,
        settings: avatarBundle.manifest.settings,
        availableImageIds: _images.keys.toSet(),
        containsSourceRect: (id, rect) {
          final image = _images[id];
          return image != null &&
              rect.left >= 0 &&
              rect.top >= 0 &&
              rect.width > 0 &&
              rect.height > 0 &&
              rect.right <= image.width &&
              rect.bottom <= image.height;
        },
      );
      _assets.owners[_avatarAssetOwner] = ids;
      character = next;
      bundle = avatarBundle;
    } finally {
      _assets.owners.remove(preparationOwner);
      if (!_disposed) {
        _assets.retain({
          for (final prepared in _preparedMaps.values) ...prepared.imageIds,
        });
      }
    }
  }

  Future<void> restoreGameState(
    GameState state, {
    bool compensatePendingScene = false,
    bool restorePlayerAvatar = true,
  }) async {
    if (_disposed) throw StateError('The spatial session is closed.');
    if (restorePlayerAvatar) await presentPlayerAvatar(state.trainerProfile.avatarCharacterId);
    final position = state.playerSpatialPosition ??
        PlayerSpatialPosition(
          x: state.playerPosition.x + .5,
          z: state.playerPosition.y + .5,
        );
    if (state.currentMapId != bundle.map.id) {
      await _transfer(state.currentMapId, (_) => state.playerPosition,
          spatialArrival: position,
          arrivalFacing: state.playerFacing,
        compensatePendingScene: compensatePendingScene,
      );
      if (_disposed || bundle.map.id != state.currentMapId) {
        throw StateError('The authored spatial relocation could not complete.');
      }
    } else if (movement.spatialPosition != position ||
        movement.facing != state.playerFacing) {
      final source = bundle;
      final previousMovement = movement;
      final diagonal = movement.allowDiagonalMovement;
      movement = SpatialMovementController.fromMap(
          map: bundle.map,
          models: bundle.manifest.models3d,
          spatialArrival: position,
          validateSpawn: false,
          entityPresencePredicate: (entity) =>
              entityIsPresent?.call(source.map.id, entity) ?? true,
          entityProjection: (entity) => entityProjection == null ? entity :
            entityProjection!(source.map.id, entity),
          modelStateProvider: (id) =>
              worldStateProvider?.call().modelState(bundle.map.id, id),
          actorStateProvider: (id) {
            final entity = bundle.map.entities
                .where((value) => value.id == id)
                .firstOrNull;
            return entity == null ? null : actorRuntimeState(entity);
          },
        facing: state.playerFacing,
      );
      attachWorldStateProviders();
      try {
        await _validateSavedPosition();
      } on Object {
        movement = previousMovement;
        attachWorldStateProviders();
        rethrow;
      }
      movement.setDiagonalMovement(diagonal);
      movement.setPaused(presentationPaused || interactionActive.value);
      _warps = SpatialWarpController(
        map: bundle.map,
        x: movement.x,
        z: movement.z,
      );
    }
  }

  Future<void> enterConnection(MapConnection connection) async {
    if (_disposed ||
        transitioning.value ||
        presentationPaused ||
        interactionActive.value ||
        !bundle.map.connections.contains(connection) ||
        movement.edgeExitDirection != connection.direction) {
      return;
    }
    final source = bundle.map;
    final sourcePos = GridPos(x: movement.x.floor(), y: movement.z.floor());
    final sourceHeight = movement.y;
    final entry = (
      connection: connection,
      sourceSize: source.size,
      sourceX: movement.x,
      sourceZ: movement.z,
    );
    final prepared = _preparedMaps[connection.targetMapId];
    if (prepared != null &&
        _visibleMaps.contains(connection.targetMapId) &&
        movement.connectionArrival != null) {
      try {
        onBeforeMapChange?.call();
        prepared.movement.adoptConnectionMotion(movement);
        _preparedMaps[bundle.map.id] = _capturePrepared();
        bundle = prepared.bundle;
        movement = prepared.movement;
        _smartTileAnimations = prepared.animations;
        _entityVisuals = prepared.visuals;
        _imageIds = prepared.imageIds;
        _assets.owners[_assetOwner] = _imageIds;
        attachWorldStateProviders();
        _warps = SpatialWarpController(
          map: bundle.map,
          x: movement.x,
          z: movement.z,
        );
        npcFacing.clear();
        _connectionEntry = entry;
        interactionError.value = null;
        _trimPreparedMaps();
        mapRevision.value++;
      } on Object catch (error) {
        interactionError.value = error;
      }
      return;
    }
    await _transfer(connection.targetMapId, (next) {
      final arrival = resolveConnectedMapTargetPos(
          sourcePos: sourcePos,
          sourceSize: source.size,
          targetSize: next.size,
          direction: connection.direction,
        offset: connection.offset,
      );
      if (arrival == null) {
        throw StateError(
          'Le bord de la connexion ne rejoint pas la destination.',
        );
      }
      final scene = next.spatialScene;
      if (scene == null ||
          (scene.worldHeightAt(arrival.x + .5, arrival.y + .5) - sourceHeight)
                  .abs() >
              .25) {
        throw StateError('La hauteur de la connexion 3D est incompatible.');
      }
      return arrival;
    }, connectionEntry: entry);
  }

  Future<RuntimeMapBundle> loadConnectionNeighbor(
    MapConnection connection,
  ) async {
    if (_disposed || !viewConnections.contains(connection)) {
      throw StateError('La connexion ne possède pas de voisin actif.');
    }
    final source = bundle;
    final sourceOrigin = _mapOrigins[source.map.id] ?? ui.Offset.zero;
    final prepared = await _prepareMap(connection.targetMapId);
    if (_preparedMaps.containsKey(prepared.bundle.map.id)) {
      _mapOrigins[prepared.bundle.map.id] = sourceOrigin +
          spatialConnectionOffset(source.map.size, prepared.bundle.map.size,
            connection.direction,
            connection.offset,
          );
    }
    _trimPreparedMaps();
    return prepared.bundle;
  }

  _PreparedSpatialMap _capturePrepared() =>
      _PreparedSpatialMap(
    bundle,
    movement,
    _entityVisuals,
    _imageIds,
    _smartTileAnimations,
  );

  void setVisibleMaps(Set<String> ids) {
    if (_disposed) return;
    _rendererAttached = true;
    _visibleMaps = Set.of(ids);
    if (_nativeDoorRendererMap == bundle.map.id &&
        ids.contains(bundle.map.id)) {
      _completeNativeRenderer(true);
    }
    _trimPreparedMaps();
  }

  Future<bool> _waitForNativeRenderer(String mapId) {
    if (!_rendererAttached ||
        _visibleMaps.contains(mapId) && bundle.map.id == mapId) {
      return Future.value(true);
    }
    _nativeDoorRendererMap = mapId;
    _nativeDoorRendererReady = Completer<bool>();
    return _nativeDoorRendererReady!.future;
  }

  void _completeNativeRenderer(bool ready) {
    final completion = _nativeDoorRendererReady;
    _nativeDoorRendererReady = null;
    _nativeDoorRendererMap = null;
    if (completion != null && !completion.isCompleted)
      completion.complete(ready);
  }

  void reportNativeDoorRenderFailure(String mapId, Object error) {
    if (_disposed || !nativeDoorTraversalActive || bundle.map.id != mapId)
      return;
    interactionError.value = error;
    cancelPendingTransition();
  }

  Future<void> _validateSavedPosition({bool npcRecoveryAttempted = false}) async {
    if (movement.isPositionTraversable) return;
    for (final connection in viewConnections) {
      await loadConnectionNeighbor(connection);
    }
    _linkPreparedMaps(_preparedMaps.keys.toSet());
    if (!movement.isPositionTraversable) {
      throw StateError(npcRecoveryAttempted
          ? 'La position sauvegardée est bloquée. Aucune position de reprise accessible autour des personnages. La sauvegarde d’origine est conservée.'
          : 'La position sauvegardée est bloquée.');
    }
  }

  Future<_PreparedSpatialMap> _prepareMap(String id) async {
    final existing = _preparedMaps[id];
    if (existing != null) return existing;
    final future = _preparingMaps.putIfAbsent(id, () async {
      final next = await _loadMap(id);
      if (_disposed) throw StateError('La session est fermée.');
      _validateDestination(next, id, bundle.projectRootDirectory);
      final candidate = await _load(next,
          characterId: character.id,
          worldStateProvider: worldStateProvider,
          entityIsPresent: entityIsPresent,
          entityProjection: entityProjection,
          presentationStateProvider: presentationStateProvider,
          loadMap: _loadMap,
          sharedAssets: _assets,
          knownMaps: _knownMaps.values,
        validateSpawn: false,
      );
      try {
        if (_disposed) throw StateError('La session est fermée.');
        final prepared = candidate._capturePrepared();
        _preparedMaps[id] = prepared;
        return prepared;
      } finally {
        candidate.dispose();
      }
    });
    try {
      return await future;
    } finally {
      if (identical(_preparingMaps[id], future)) {
        _preparingMaps.remove(id);
        if (!_disposed) _trimPreparedMaps();
      }
    }
  }

  void _trimPreparedMaps() {
    final retained = {
      bundle.map.id,
      ..._visibleMaps,
      for (final connection in viewConnections) connection.targetMapId,
      ..._preparingMaps.keys,
    };
    for (final id
        in _preparedMaps.keys.where((id) => !retained.contains(id)).toList()) {
      _preparedMaps.remove(id)!.movement.setConnectedNeighbors({});
      _mapOrigins.remove(id);
    }
    _linkPreparedMaps(_visibleMaps);
    _assets.retain({
      for (final prepared in _preparedMaps.values) ...prepared.imageIds,
    });
  }

  void _linkPreparedMaps(Set<String> ready) {
    for (final prepared in _preparedMaps.values) {
      final neighbors = <MapConnectionDirection, SpatialMovementNeighbor>{};
      for (final source in _preparedMaps.values) {
        if (!ready.contains(source.bundle.map.id)) continue;
        for (final connection in _connectionsFor(source.bundle.map)) {
          if (connection.targetMapId != prepared.bundle.map.id) continue;
          final offset = spatialConnectionOffset(
              source.bundle.map.size,
              prepared.bundle.map.size,
              connection.direction,
            connection.offset,
          );
          neighbors[connection.direction.opposite] = SpatialMovementNeighbor(
              controller: source.movement,
              offsetX: -offset.dx,
            offsetZ: -offset.dy,
          );
        }
      }
      neighbors.addAll({
        for (final connection in _connectionsFor(prepared.bundle.map))
          if (ready.contains(connection.targetMapId))
            if (_preparedMaps[connection.targetMapId] case final neighbor?)
              connection.direction: SpatialMovementNeighbor(
                  controller: neighbor.movement,
                  offsetX: spatialConnectionOffset(
                          prepared.bundle.map.size,
                          neighbor.bundle.map.size,
                          connection.direction,
                  connection.offset,
                ).dx,
                  offsetZ: spatialConnectionOffset(
                          prepared.bundle.map.size,
                          neighbor.bundle.map.size,
                          connection.direction,
                  connection.offset,
                ).dy,
              ),
      });
      prepared.movement.setConnectedNeighbors(
        neighbors,
        waitForReady: _rendererAttached,
      );
    }
  }

  static void _validateDestination(
    RuntimeMapBundle next,
    String targetMapId,
    String root,
  ) {
    final scene = next.map.spatialScene;
    if (next.map.id != targetMapId ||
        p.normalize(next.projectRootDirectory) != p.normalize(root) ||
        next.manifest.settings.dimension != ProjectDimension.threeD ||
        scene == null ||
        scene.width != next.map.size.width ||
        scene.depth != next.map.size.height) {
      throw StateError('La destination du passage est invalide.');
    }
  }

  Future<void> _transfer(
    String targetMapId,
    GridPos Function(MapData) resolveArrival, {
    ({
      MapConnection connection,
      GridSize sourceSize,
      double sourceX,
      double sourceZ,
    })?
    connectionEntry,
    PlayerSpatialPosition? spatialArrival,
    EntityFacing? arrivalFacing,
    MapWarp? warp,
    bool compensatePendingScene = false,
  }) async {
    if (_disposed ||
        transitioning.value ||
        (!compensatePendingScene &&
            (presentationPaused || interactionActive.value))) {
      return;
    }
    final generation = ++_transferGeneration;
    final source = _capturePrepared();
    final sourceOrigins = Map.of(_mapOrigins);
    final sourceConnection = _connectionEntry;
    final lease = Object();
    if (warp != null) _nativeScreenTransition = warp.transition;
    var native =
        warp != null &&
        (warp.transition.type != MapWarpTransitionType.none ||
            warp.ladder != null ||
            warp.door != null ||
            (_knownMaps[targetMapId]?.warps.any(
                  (entry) => entry.pos == warp.targetPos && entry.door != null,
                ) ??
                false));
    if (native) {
      _nativeDoorLease = lease;
      _assets.owners[lease] = source.imageIds;
    }
    final facing = movement.facing;
    final diagonal = movement.allowDiagonalMovement;
    movement.setPaused(true);
    final restoreSourceMovement = movement.captureNativeTraversalRollback();
    interactionError.value = null;
    transitioning.value = true;
    SpatialExplorationSession? candidate;
    Future<void>? candidatePreparation;
    var acceptingCandidate = true;
    var departureStarted = false;
    void rollbackSource() {
      final changed = !identical(movement, source.movement);
      bundle = source.bundle;
      movement = source.movement;
      restoreSourceMovement();
      _entityVisuals = source.visuals;
      _imageIds = source.imageIds;
      _smartTileAnimations = source.animations;
      _assets.owners[_assetOwner] = _imageIds;
      _mapOrigins
        ..clear()
        ..addAll(sourceOrigins);
      _connectionEntry = sourceConnection;
      _warps = SpatialWarpController(
        map: bundle.map,
        x: movement.x,
        z: movement.z,
      );
      attachWorldStateProviders();
      if (changed) mapRevision.value++;
    }

    Future<bool> presentDeparture() async {
      final passage = warp!;
      final departure = _resolveNativeDoor(source.bundle, passage);
      _nativeDoorLease = lease;
      _assets.owners[lease] = source.imageIds;
      _nativeDoorRollback = rollbackSource;
      if ((departure != null || passage.ladder != null) &&
          !await _waitForNativeRenderer(source.bundle.map.id)) {
        return false;
      }
      if (_disposed || generation != _transferGeneration) return false;
      _nativeDoor.start(
        ladder: passage.ladder,
        departureMapId: source.bundle.map.id,
        departure: departure,
        departurePos: departure == null ? null : passage.pos,
        departureStart: (x: movement.x, z: movement.z),
        transition: passage.transition,
      );
      departureStarted = true;
      final firstFrame = waitForNativeTraversalStartFrame?.call();
      if (firstFrame != null &&
          !await Future.any<bool>([
            firstFrame.then((_) => true),
            _nativeDoor.finished,
          ])) {
        return false;
      }
      if (_disposed || generation != _transferGeneration) return false;
      if (!await _nativeDoor.readyToTransfer ||
          _disposed ||
          generation != _transferGeneration) {
        return false;
      }
      final coveredFrame = passage.transition.type == MapWarpTransitionType.none
          ? null
          : waitForNativeDoorBlackoutFrame?.call();
      if (coveredFrame != null &&
          !await Future.any<bool>([
            coveredFrame.then((_) => true),
            _nativeDoor.finished,
          ])) {
        return false;
      }
      return !_disposed && generation == _transferGeneration;
    }

    try {
      if (native && !await presentDeparture()) return;
      final cached = _preparedMaps[targetMapId]?.bundle;
      final loading = cached == null ? _loadMap(targetMapId) : null;
      final next = cached ??
          (native
              ? await Future.any<RuntimeMapBundle?>([
                  loading!,
                  _nativeDoor.finished.then((_) => null),
                ])
              : await loading!);
      if (next == null) return;
      if (_disposed || generation != _transferGeneration) return;
      _validateDestination(next, targetMapId, bundle.projectRootDirectory);
      SpatialDoorTraversalBinding? arrivalDoor;
      Future<void> prepareCandidate() async {
        Future<void> prepareSession() async {
          final prepared = await _load(
            next,
            arrival: spatialArrival == null ? resolveArrival(next.map) : null,
            spatialArrival: spatialArrival,
            facing:
                arrivalFacing ??
                (native
                    ? _nativeDoor.playerPose?.facing ?? movement.facing
                    : facing),
            characterId: character.id,
            worldStateProvider: worldStateProvider,
            modelPoseProvider: native ? modelRuntimeState : null,
            entityIsPresent: entityIsPresent,
            entityProjection: entityProjection,
            presentationStateProvider: presentationStateProvider,
            loadMap: _loadMap,
            sharedAssets: _assets,
            knownMaps: _knownMaps.values,
          );
          if (!acceptingCandidate ||
              _disposed ||
              generation != _transferGeneration) {
            prepared.dispose();
            if (!_disposed) {
              _assets.retain({
                for (final prepared in _preparedMaps.values)
                  ...prepared.imageIds,
              });
            }
            return;
          }
          candidate = prepared;
        }

        try {
          final rendererPreparation = native
              ? Future<void>.sync(
                  () => prepareNativeDoorDestination?.call(
                    next,
                    () =>
                        acceptingCandidate &&
                        !_disposed &&
                        generation == _transferGeneration,
                  ),
                )
              : Future<void>.value();
          await Future.wait<void>([
            prepareSession(),
            rendererPreparation,
          ], eagerError: true);
        } on Object catch (error) {
          if (acceptingCandidate &&
              !_disposed &&
              generation == _transferGeneration) {
            acceptingCandidate = false;
            interactionError.value = error;
            if (native) _nativeDoor.cancel();
          }
          if (!_disposed) {
            _assets.retain({
              for (final prepared in _preparedMaps.values) ...prepared.imageIds,
            });
          }
        }
      }

      if (warp != null) {
        final matching = next.map.warps
            .where((entry) => entry.pos == warp.targetPos && entry.door != null)
            .toList();
        if (matching.length > 1) {
          throw StateError('Plusieurs portes correspondent à cette arrivée.');
        }
        arrivalDoor = _resolveNativeDoor(next, matching.firstOrNull);
        final departure = _resolveNativeDoor(bundle, warp);
        native =
            warp.ladder != null ||
            departure != null ||
            arrivalDoor != null ||
            warp.transition.type != MapWarpTransitionType.none;
        if (native) {
          if (!departureStarted && !await presentDeparture()) return;
          _nativeArrivalDoor = arrivalDoor;
          _nativeDoor.configureArrival(
            arrival: arrivalDoor,
            arrivalPos: warp.targetPos,
          );
        }
      }
      candidatePreparation ??= prepareCandidate();
      if (native) {
        if (!await Future.any<bool>([
          candidatePreparation.then((_) => true),
          _nativeDoor.finished,
        ])) {
          return;
        }
      } else {
        await candidatePreparation;
      }
      final preparedCandidate = candidate;
      if (!acceptingCandidate || preparedCandidate == null) return;
      if (_disposed || generation != _transferGeneration) return;
      if (arrivalDoor != null &&
          !preparedCandidate.movement.canTraverseActor(
            preparedCandidate.movement.x,
            preparedCandidate.movement.z,
            arrivalDoor.exitPos.x + .5,
            arrivalDoor.exitPos.y + .5,
          )) {
        throw StateError('Le chemin de sortie de la porte est bloqué.');
      }
      onBeforeMapChange?.call();
      final previousOrigin = _mapOrigins[bundle.map.id] ?? ui.Offset.zero;
      _preparedMaps[bundle.map.id] = _capturePrepared();
      final nextMovement = preparedCandidate.movement;
      final nextWarps = preparedCandidate._warps;
      final nextAnimations = preparedCandidate._smartTileAnimations;
      _entityVisuals = preparedCandidate._entityVisuals;
      _imageIds = preparedCandidate._imageIds;
      _assets.owners[_assetOwner] = _imageIds;
      final preparedNeighbors = Map.of(preparedCandidate._preparedMaps);
      final preparedOrigins = Map.of(preparedCandidate._mapOrigins);
      final preparedBundle = preparedCandidate.bundle;
      preparedCandidate.dispose();
      candidate = null;
      bundle = preparedBundle;
      movement = nextMovement;
      _smartTileAnimations = nextAnimations;
      _preparedMaps.addAll(preparedNeighbors);
      _mapOrigins.addAll(preparedOrigins);
      _preparedMaps[bundle.map.id] = _capturePrepared();
      _mapOrigins[bundle.map.id] = connectionEntry == null
          ? ui.Offset.zero
          : previousOrigin +
                spatialConnectionOffset(
                  connectionEntry.sourceSize,
                  next.map.size,
                  connectionEntry.connection.direction,
                  connectionEntry.connection.offset,
                );
      attachWorldStateProviders();
      _warps = nextWarps;
      movement.setDiagonalMovement(diagonal);
      if (native) movement.setPaused(true);
      npcFacing.clear();
      _connectionEntry = connectionEntry;
      _trimPreparedMaps();
      if (spatialArrival != null) {
        _linkPreparedMaps(_preparedMaps.keys.toSet());
      }
      if (native) {
        final rendered = _waitForNativeRenderer(bundle.map.id);
        mapRevision.value++;
        if (!await rendered || _disposed || generation != _transferGeneration) {
          return;
        }
        final coveredDestinationFrame = waitForNativeDoorBlackoutFrame?.call();
        if (coveredDestinationFrame != null &&
            !await Future.any<bool>([
              coveredDestinationFrame.then((_) => true),
              _nativeDoor.finished,
            ])) {
          return;
        }
        if (_disposed || generation != _transferGeneration) return;
        _nativeDoor.transferCompleted();
        if (!await _nativeDoor.finished ||
            _disposed ||
            generation != _transferGeneration) {
          return;
        }
        _nativeDoorRollback = null;
        _nativeDoorLease = null;
        _nativeArrivalDoor = null;
        _nativeDoor.clear();
        nativeDoorBlackout.value = 0;
      }
      mapRevision.value++;
    } on Object catch (error) {
      if (!_disposed && generation == _transferGeneration) {
        interactionError.value = error;
      }
    } finally {
      acceptingCandidate = false;
      candidate?.dispose();
      if (identical(_nativeDoorLease, lease)) {
        _completeNativeRenderer(false);
        _nativeDoorRollback?.call();
        _nativeDoorRollback = null;
        _nativeDoorLease = null;
        _nativeArrivalDoor = null;
        _nativeDoor.clear();
        nativeDoorBlackout.value = 0;
      }
      _assets.owners.remove(lease);
      if (!_disposed) {
        _assets.retain({
          for (final prepared in _preparedMaps.values) ...prepared.imageIds,
        });
      }
      if (!_disposed && generation == _transferGeneration) {
        movement.setPaused(presentationPaused || interactionActive.value);
        transitioning.value = false;
        onFrame?.call();
      }
    }
  }
  void dispose() {
    if (_disposed) return;
    if (_dialogueSound case final sound?) unawaited(sound.dispose());
    if (_dialogueMusic case final music?) unawaited(music.dispose());
    _completeDialogue(const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
        message: 'The spatial dialogue owner was disposed.',
      ),
    );
    _completeNativeRenderer(false);
    _nativeDoor.cancel();
    _nativeDoorRollback?.call();
    _nativeDoorRollback = null;
    _nativeDoorLease = null;
    _nativeDoor.clear();
    nativeDoorBlackout.dispose();
    cinematicFadeOpacity.dispose();
    graphics.dispose();
    waitForNativeDoorBlackoutFrame = null;
    prepareNativeDoorDestination = null;
    _disposed = true;
    _transferGeneration++;
    onFrame = null;
    onPresentationFrame = null;
    _interactionGeneration++;
    _dialogue?.removeFromParent();
    _dialogue = null;
    interactionError.dispose();
    interactionActive.dispose();
    dialoguePresentation.dispose();
    storyActive.dispose();
    mapRevision.dispose();
    transitioning.dispose();
    movement.setPaused(true);
    for (final prepared in _preparedMaps.values) {
      prepared.movement.setConnectedNeighbors({});
    }
    _preparedMaps.clear();
    _assets.owners.remove(_assetOwner);
    _assets.owners.remove(_avatarAssetOwner);
    if (_ownsAssets) _assets.dispose();
  }

  void cancelPendingTransition() {
    if (_disposed) return;
    _transferGeneration++;
    final native = nativeDoorTraversalActive;
    if (native) {
      _completeNativeRenderer(false);
      _nativeDoor.cancel();
      _nativeDoorRollback?.call();
      _nativeDoorRollback = null;
      _nativeDoorLease = null;
      _nativeArrivalDoor = null;
      _nativeDoor.clear();
      nativeDoorBlackout.value = 0;
    }
    movement.setPaused(
      native ? presentationPaused || interactionActive.value : true,
    );
    transitioning.value = false;
  }

  void resetPosition() {
    if (_disposed || transitioning.value) return;
    closeDialogue();
    movement.reset();
    movement.setPaused(presentationPaused);
    _warps = SpatialWarpController(
      map: bundle.map,
      x: movement.x,
      z: movement.z,
    );
  }
}

final class _SpatialModelPresenceIndex {
  _SpatialModelPresenceIndex(MapData map) {
    for (final instance in map.spatialScene!.instances) {
      entityIdsByInstanceId.putIfAbsent(instance.id, () => instance.entityId);
    }
    for (final entity in map.entities) {
      entitiesById.putIfAbsent(entity.id, () => entity);
    }
  }

  final entityIdsByInstanceId = <String, String?>{};
  final entitiesById = <String, MapEntity>{};
}

final class _PreparedSpatialMap {
  _PreparedSpatialMap(
    this.bundle,
    this.movement,
    this.visuals,
    this.imageIds,
    this.animations,
  );
  final RuntimeMapBundle bundle;
  final SpatialMovementController movement;
  final SpatialEntityVisualPlan visuals;
  final Set<String> imageIds;
  final SpatialSmartTileAnimationController animations;
}

final class _SpatialActorAssets {
  _SpatialActorAssets(this.budget) : emotes = SpatialCinematicEmoteVisuals(budget);
  final SpatialCinematicEmoteVisuals emotes;
  final RuntimeResourceBudget budget;
  final reservations = <String, RuntimeResourceReservation>{};
  final images = <String, ui.Image>{};
  final textures = <String, SpatialActorTexture>{};
  final owners = <Object, Set<String>>{};
  final pending = <String, Future<void>>{};
  bool disposed = false;

  Future<void> load(
    String id,
    String path,
    SpatialEntityVisualPlan plan,
  ) async {
    if (images.containsKey(id)) return;
    final future = pending.putIfAbsent(id, () async {
      final file = File(path);
      final length = await file.length();
      if (length > budget.profile.maximumEncodedBytes) {
        throw const RuntimeResourceAdmissionException('encoded_bytes');
      }
      final reservation = await budget.acquire(
        transientBytes: length * 2,
        isCurrent: () => !disposed,
      );
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      ui.Codec? codec;
      ui.Image? image;
      try {
        final bytes = await file.readAsBytes();
        if (bytes.length != length) {
          throw const RuntimeResourceAdmissionException('source_changed');
        }
        buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        final residentLimit = reservation.profile.maximumResidentBytes ~/ 2;
        final transientLimit = (reservation.profile.maximumTransientBytes - length * 2) ~/ 3;
        final pixels = runtimeImageRgbaByteLength(descriptor.width, descriptor.height,
          maximumBytes: residentLimit < transientLimit
              ? residentLimit
              : transientLimit,
        );
        reservation.resize(residentBytes: pixels * 2,
          transientBytes: length * 2 + pixels * 3,
        );
        codec = await descriptor.instantiateCodec();
        image = (await codec.getNextFrame()).image;
        reservation.ensureCurrent();
        final texture = await plan.createTexture(id, image);
        if (disposed) {
          throw StateError('Les ressources de la session sont fermées.');
        }
        images[id] = image;
        textures[id] = texture;
        reservation.commit();
        reservations[id] = reservation;
        image = null;
      } on Object {
        reservation.release();
        rethrow;
      } finally {
        image?.dispose();
        codec?.dispose();
        descriptor?.dispose();
        buffer?.dispose();
      }
    });
    try {
      await future;
    } finally {
      if (identical(pending[id], future)) pending.remove(id);
    }
  }

  void retain(Set<String> ids) {
    final retained = {...ids, for (final owned in owners.values) ...owned};
    for (final id
        in images.keys.where((id) => !retained.contains(id)).toList()) {
      images.remove(id)!.dispose();
      textures.remove(id);
      reservations.remove(id)?.release();
    }
  }

  void dispose() {
    emotes.dispose();
    if (disposed) return;
    disposed = true;
    for (final image in images.values) {
      image.dispose();
    }
    images.clear();
    textures.clear();
    owners.clear();
    for (final reservation in reservations.values) {
      reservation.release();
    }
    reservations.clear();
  }
}

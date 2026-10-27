import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart';
import 'spatial_cinematic_runtime_playback_sink.dart';
import 'spatial_exploration_session.dart';
import 'spatial_npc_fixed_route_runtime.dart';
import 'spatial_visual_playback.dart';
import 'spatial_lift_playback.dart';

final class SpatialStoryPlayback {
  SpatialStoryPlayback({
    required this.session,
    required this.readGameState,
    required this.writeGameState,
  }) {
    visualRules = SpatialVisualRuleResolver(session.bundle.manifest);
    session.worldVisualProfile = () => visualRules.resolve(readGameState(), session.bundle.map.id);
    visuals = SpatialVisualPlayback(readBase: resolvedVisuals, publish: (profile) => session.visualOverrides = profile);
    models = SpatialModelAnimationController(
      mapId: () => session.bundle.map.id,
      instances: () => session.bundle.map.spatialScene!.instances,
      models: () => session.bundle.manifest.models3d,
      state: readGameState().spatialWorldState,
      canClose: _canClose,
      commit: (world) =>
          writeGameState(readGameState().copyWith(spatialWorldState: world)),
    );
    autonomousNpcs = SpatialNpcFixedRouteRuntime(
      readMap: () => projectMapEntityPresentations(project: session.bundle.manifest,
          gameState: readGameState(), map: session.bundle.map),
      readActor: (entity) => models.worldState.actorState(session.bundle.map.id, entity.id),
      isPresent: (entity) => session.entityIsPresent?.call(session.bundle.map.id, entity) ?? true,
      readVariantKey: (entity) => entity.properties[mapEntityPresentationVariantIdProperty],
      readInstanceBoolean: (id, key) {
        final instances = readGameState().mapInstanceWorldState;
        final scope = instances.instanceRef(session.bundle.map.id);
        return scope != null && instances.eventBoolean(scope, id, key);
      },
      canTraverse: (entity, x, z, nextX, nextZ, reservations) {
        SpatialActorRuntimeState? current(String id) {
          final pose = autonomousNpcs.poseFor(id);
          return pose == null ? models.worldState.actorState(session.bundle.map.id, id) :
              SpatialActorRuntimeState(x: pose.x, z: pose.z, facing: pose.facing);
        }
        return session.movement.canTraverseActor(x, z, nextX, nextZ,
            ignoredEntityId: entity.id, collideWithPlayer: true,
            actorStateProvider: (id) => reservations[id] ?? current(id));
      },
      commitActor: (id, pose) {
        final world = models.worldState.setActorState(session.bundle.map.id, id, pose);
        writeGameState(readGameState().copyWith(spatialWorldState: world));
        models.synchronize(world);
      },
      random: Random(),
    );
    lifts = SpatialLiftPlayback(readMap: () => session.bundle.map, readWorld: () => readGameState().spatialWorldState, writeWorld: (world) => writeGameState(readGameState().copyWith(spatialWorldState:world)));
    session.liftHeightAt = lifts.heightAt;
    session.liftModelPose = lifts.modelPose;
    cinematics = CinematicRuntimePlaybackController(
      sink: SpatialCinematicRuntimePlaybackSink(
        project: session.bundle.manifest,
        activeMap: () => session.bundle.map,
        containsPoint: session.containsCinematicPoint,
        heightAt: session.cinematicHeightAt,
        readActor: _readActor,
        writeActor: (actor, pose) => _poses[_key(actor)] = pose,
        readCamera: () => camera,
        readVisuals: () => resolvedVisuals().overriddenBy(session.visualOverrides).overriddenBy(session.cinematicVisualOverrides),
        readVisualOverrides: () => session.cinematicVisualOverrides,
        writeVisuals: (profile) => session.cinematicVisualOverrides = profile,
        writeFadeOpacity: (opacity) =>
            session.cinematicFadeOpacity.value = opacity ?? 0,
        retainFadeOnCompletion: () => _sceneFadeOwner != null,
        writeCamera: (pose) => camera = pose,
        canTraverse: (actor, fromX, fromZ, toX, toZ, poses, crossingActors) => session.movement.canTraverseActor(
            fromX, fromZ, toX, toZ, allowConnectedMaps: true,
            connectedMaps: session.cinematicMovementNeighbors,
            ignoredEntityId: actor.mapEntityId,
            ignoredEntityIds: {for (final binding in crossingActors) if (binding.mapEntityId != null) binding.mapEntityId!},
            actorStateProvider: (id) {
          final pose = poses.entries
              .where((entry) =>
                  entry.key.kind == CinematicActorBindingKind.mapEntity &&
                  entry.key.mapEntityId == id)
              .firstOrNull
              ?.value;
          return pose == null
              ? null
              : SpatialActorRuntimeState(
                  x: pose.x, z: pose.z, facing: pose.facing);
        },
            playerPosition: PlayerSpatialPosition(
                x: poses.entries
                        .where((entry) =>
                            entry.key.kind == CinematicActorBindingKind.player)
                        .firstOrNull
                        ?.value
                        .x ??
                    _playerPose().x,
                z: poses.entries
                        .where((entry) => entry.key.kind == CinematicActorBindingKind.player)
                        .firstOrNull
                        ?.value
                        .z ??
                    _playerPose().z),
            collideWithPlayer: actor.kind == CinematicActorBindingKind.mapEntity && !crossingActors.any((binding) => binding.kind == CinematicActorBindingKind.player)),
        setInputLocked: (locked) {
          session.storyInputLocked = locked;
          if (!locked) _publishActivity();
        },
        onCompletedPoses: _commitPoses,
        onRestored: (keepFinal) {
          final snapshot = _companionSnapshot;
          _companionSnapshot = null;
          if (!keepFinal && snapshot != null) session.restoreCompanionTrail(snapshot);
        },
        isReady: () => !_disposed && !session.transitioning.value,
      ),
    );
    session.worldStateProvider = () => models.worldState;
    session.heroStoryPose = () {
      if (session.nativeDoorTraversalActive) return null;
      final animated = _poses['player'];
      if (cinematics.isPlaying && animated != null) return animated;
      final pose = _playerPose();
      return pose.x != session.movement.x || pose.z != session.movement.z ||
              pose.facing != session.movement.facing
          ? pose
          : null;
    };
    session.npcStoryPose = (entity) => cinematics.isPlaying ? _poses['entity:${entity.id}'] : null;
    session.npcAutonomousPose = (entity) => autonomousNpcs.poseFor(entity.id);
    session.onBeforeMapChange = () {
      lifts.cancel();
      _resetFade();
      visuals.reset();
      session.cinematicVisualOverrides = SpatialVisualPatch();
      autonomousNpcs.flush();
      autonomousNpcs.reset();
    };
    session.onPresentationFrame = update;
    session.onCancelStory = cancel;
    session.onSkipStory = skip;
    session.storyCamera = () => camera;
    session.attachWorldStateProviders();
  }

  final SpatialExplorationSession session;
  late final SpatialVisualRuleResolver visualRules;
  late final SpatialLiftPlayback lifts;
  late final SpatialVisualPlayback visuals;
  SpatialVisualPatch resolvedVisuals() {
    final bundle = session.bundle;
    final scene = bundle.map.spatialScene!;
    return SpatialVisualPatch.fromScene(camera: scene.camera, atmosphere: bundle.spatialAtmosphereSettings, cycle: scene.dayNightCycle)
        .overriddenBy(bundle.visualProfile).overriddenBy(session.worldVisualProfile?.call() ?? SpatialVisualPatch());
  }
  Future<String> playVisual(SceneInteractiveCommand command, {Object? owner}) async {
    if (command is! SceneWorldPresentationInteractiveCommand) return 'blocked';
    final result = await visuals.execute(command, owner: owner);
    return result == 'completed' ? 'completed' : 'blocked';
  }
  final GameState Function() readGameState;
  final void Function(GameState) writeGameState;
  late final SpatialModelAnimationController models;
  late final CinematicRuntimePlaybackController cinematics;
  late final SpatialNpcFixedRouteRuntime autonomousNpcs;
  final _poses = <String, SpatialCinematicActorPose>{};
  SpatialCinematicCameraPose? camera;
  bool _disposed = false;
  bool wasCancelled = false;
  Object? _sceneFadeOwner;
  PartyCompanionTrail? _companionSnapshot;

  void releaseScene(Object owner) {
    visuals.releaseScene(owner);
    if (identical(_sceneFadeOwner, owner)) {
      cinematics.cancel();
      _resetFade();
    }
  }

  void _resetFade() {
    _sceneFadeOwner = null;
    session.cinematicFadeOpacity.value = 0;
  }

  String _key(CinematicActorBinding actor) =>
      actor.kind == CinematicActorBindingKind.player
          ? 'player'
          : 'entity:${actor.mapEntityId}';

  SpatialCinematicActorPose? _readActor(CinematicActorBinding actor) {
    final override = _poses[_key(actor)];
    if (override != null) return override;
    if (actor.kind == CinematicActorBindingKind.player) {
      return _playerPose();
    }
    final entity = session.bundle.map.entities
        .where((value) => value.id == actor.mapEntityId && value.npc != null)
        .firstOrNull;
    if (entity == null ||
        !(session.entityIsPresent?.call(session.bundle.map.id, entity) ??
            true)) {
      return null;
    }
    final autonomous = autonomousNpcs.poseFor(entity.id);
    if (autonomous != null) return autonomous;
    final saved =
        models.worldState.actorState(session.bundle.map.id, entity.id);
    return SpatialCinematicActorPose(
        x: saved?.x ?? entity.pos.x + .5,
        z: saved?.z ?? entity.pos.y + .5,
        facing: saved?.facing ?? session.npcFacing[entity.id] ?? entity.npc!.facing);
  }

  SpatialCinematicActorPose _playerPose() {
    final animated = _poses['player'];
    if (animated != null) return animated;
    final state = session.presentationStateProvider?.call() ?? readGameState();
    final position = state.currentMapId == session.bundle.map.id
        ? state.playerSpatialPosition
        : null;
    return SpatialCinematicActorPose(
        x: position?.x ?? session.movement.x,
        z: position?.z ?? session.movement.z,
        facing: position == null ? session.movement.facing : state.playerFacing);
  }

  bool _canClose(SpatialModelInstance instance) {
    if (session.movement.wouldModelBlockActor(
        instance.id,
        _playerPose().x,
        _playerPose().z)) {
      return false;
    }
    for (final entity
        in session.bundle.map.entities.where((value) => value.npc != null)) {
      if (!(session.entityIsPresent?.call(session.bundle.map.id, entity) ??
          true)) {
        continue;
      }
      final pose = _readActor(CinematicActorBinding(
          actorId: entity.id,
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: entity.id))!;
      if (session.movement.wouldModelBlockActor(instance.id, pose.x, pose.z)) {
        return false;
      }
    }
    return true;
  }

  void _commitPoses(
      Map<CinematicActorBinding, SpatialCinematicActorPose> poses) {
    var state = readGameState();
    var world = models.worldState;
    for (final entry in poses.entries) {
      final pose = entry.value;
      if (entry.key.kind == CinematicActorBindingKind.player) {
        state = state.copyWith(
            playerPosition: GridPos(x: pose.x.floor(), y: pose.z.floor()),
            playerSpatialPosition: PlayerSpatialPosition(x: pose.x, z: pose.z),
            playerFacing: pose.facing);
      } else {
        world = world.setActorState(
            session.bundle.map.id,
            entry.key.mapEntityId!,
            SpatialActorRuntimeState(
                x: pose.x, z: pose.z, facing: pose.facing));
      }
    }
    state = state.copyWith(spatialWorldState: world);
    writeGameState(state);
    models.synchronize(world);
  }

  Future<String> playModel(SceneInteractiveCommand command) async {
    if (_disposed ||
        models.isPlaying ||
        cinematics.isPlaying ||
        command is! ScenePlayModelAnimationInteractiveCommand) {
      return 'blocked';
    }
    wasCancelled = false;
    session.interactionError.value = null;
    models.synchronize(readGameState().spatialWorldState);
    final future = models.play(command);
    _publishActivity();
    try {
      final result = await future;
      if (result == 'cancelled') {
        throw StateError('The spatial animation was cancelled.');
      }
      return result;
    } finally {
      _publishActivity();
    }
  }

  Future<String> playCinematic(
      SceneRuntimePlanIntent intent, String sourceId, {Object? sceneOwner}) async {
    if (_disposed || models.isPlaying || cinematics.isPlaying) {
      throw StateError('Spatial playback is busy.');
    }
    if (_sceneFadeOwner != null && !identical(_sceneFadeOwner, sceneOwner)) {
      throw StateError('Another scene owns the spatial cinematic fade.');
    }
    _sceneFadeOwner = sceneOwner;
    _companionSnapshot = session.captureCompanionTrail();
    autonomousNpcs.update(0, paused: true);
    _poses.clear();
    wasCancelled = false;
    session.interactionError.value = null;
    models.synchronize(readGameState().spatialWorldState);
    final future = SceneCinematicRuntimeAwaitableAdapter(
            runtimeSourceId: sourceId,
            project: session.bundle.manifest,
            player: cinematics)
        .playCinematic(intent);
    _publishActivity();
    try {
      final result = await future;
      if (!result.success || result.scenePortId == null) {
        _resetFade();
        throw StateError(
            result.message ?? 'The spatial cinematic did not complete.');
      }
      return result.scenePortId!;
    } finally {
      final snapshot = _companionSnapshot;
      _companionSnapshot = null;
      if (snapshot != null) session.restoreCompanionTrail(snapshot);
      if (!cinematics.isPlaying) _poses.clear();
      _publishActivity();
    }
  }

  Future<bool> playTransient(CinematicAsset asset) async {
    if (_disposed || models.isPlaying || cinematics.isPlaying || _sceneFadeOwner != null) {
      return false;
    }
    autonomousNpcs.update(0, paused: true);
    await session.prepareTransientCinematic(asset);
    if (_disposed) return false;
    wasCancelled = false;
    session.interactionError.value = null;
    _poses.clear();
    models.synchronize(readGameState().spatialWorldState);
    final future = cinematics.play(asset);
    _publishActivity();
    try {
      final result = await future;
      return result.success;
    } finally {
      if (!cinematics.isPlaying) _poses.clear();
      _publishActivity();
    }
  }

  Future<String> playPlatform(SceneInteractiveCommand command) async {
    final result = lifts.play(command);
    _publishActivity();
    try { return await result; } finally { _publishActivity(); }
  }

  void update(double dt, bool paused) {
    if (_disposed) return;
    autonomousNpcs.update(dt, paused: paused || session.movement.paused || models.isPlaying || cinematics.isPlaying ||
        session.interactionActive.value || session.storyInputLocked || session.nativeDoorTraversalActive);
    models.update(dt, paused: paused);
    lifts.update(dt, paused: paused);
    if (!paused) visuals.advance(dt);
    if (!paused && dt.isFinite && dt > 0) {
      cinematics.update(Duration(microseconds: (dt * 1000000).round()));
    }
  }

  void synchronize(SpatialWorldState state) {
    _resetFade();
    if (models.isPlaying || cinematics.isPlaying || lifts.isPlaying) cancel();
    models.synchronize(state);
    visuals.reset();
    session.cinematicVisualOverrides = SpatialVisualPatch();
    _poses.clear();
    autonomousNpcs.reset();
    camera = null;
  }

  void _publishActivity() {
    if (!_disposed) {
      session.storyActive.value = models.isPlaying || cinematics.isPlaying || lifts.isPlaying;
    }
  }

  void cancel() {
    if (models.isPlaying || cinematics.isPlaying) wasCancelled = true;
    models.cancel();
    cinematics.cancel();
    lifts.cancel();
    _resetFade();
    _publishActivity();
  }

  void skip() {
    if (session.presentationPaused) return;
    models.update(86400);
    lifts.update(86400, paused:false);
    cinematics.update(const Duration(days: 1));
    _publishActivity();
  }

  void dispose() {
    if (_disposed) return;
    cancel();
    _disposed = true;
    visuals.reset();
    session.worldVisualProfile = null;
    session.cinematicVisualOverrides = SpatialVisualPatch();
    autonomousNpcs.dispose();
    models.dispose();
    session.onPresentationFrame = null;
    session.onBeforeMapChange = null;
    session.onCancelStory = null;
    session.onSkipStory = null;
    session.liftHeightAt = null;
    session.liftModelPose = null;
    session.worldStateProvider = null;
    session.heroStoryPose = null;
    session.npcStoryPose = null;
    session.npcAutonomousPose = null;
    session.storyCamera = null;
  }
}

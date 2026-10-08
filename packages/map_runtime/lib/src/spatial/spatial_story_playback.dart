import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/scene_runtime/cinematic_runtime_playback_controller.dart';
import '../application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart';
import 'spatial_cinematic_runtime_playback_sink.dart';
import 'spatial_exploration_session.dart';

final class SpatialStoryPlayback {
  SpatialStoryPlayback({
    required this.session,
    required this.readGameState,
    required this.writeGameState,
  }) {
    models = SpatialModelAnimationController(
      mapId: () => session.bundle.map.id,
      instances: () => session.bundle.map.spatialScene!.instances,
      models: () => session.bundle.manifest.models3d,
      state: readGameState().spatialWorldState,
      canClose: _canClose,
      commit: (world) =>
          writeGameState(readGameState().copyWith(spatialWorldState: world)),
    );
    cinematics = CinematicRuntimePlaybackController(
      sink: SpatialCinematicRuntimePlaybackSink(
        project: session.bundle.manifest,
        activeMap: () => session.bundle.map,
        readActor: _readActor,
        writeActor: (actor, pose) => _poses[_key(actor)] = pose,
        readCamera: () => camera,
        writeCamera: (pose) => camera = pose,
        canTraverse: (actor, fromX, fromZ, toX, toZ, poses) => session.movement.canTraverseActor(
            fromX, fromZ, toX, toZ, ignoredEntityId: actor.mapEntityId,
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
                    _poses['player']?.x ??
                    session.movement.x,
                z: poses.entries
                        .where((entry) => entry.key.kind == CinematicActorBindingKind.player)
                        .firstOrNull
                        ?.value
                        .z ??
                    _poses['player']?.z ??
                    session.movement.z),
            collideWithPlayer: actor.kind == CinematicActorBindingKind.mapEntity),
        setInputLocked: (locked) {
          session.storyInputLocked = locked;
          if (!locked) _publishActivity();
        },
        onCompletedPoses: _commitPoses,
        isReady: () => !_disposed && !session.transitioning.value,
      ),
    );
    session.worldStateProvider = () => models.worldState;
    session.heroStoryPose = () => _poses['player'];
    session.npcStoryPose = (entity) => _poses['entity:${entity.id}'];
    session.onPresentationFrame = update;
    session.onCancelStory = cancel;
    session.onSkipStory = skip;
    session.storyCamera = () => camera;
    session.attachWorldStateProviders();
  }

  final SpatialExplorationSession session;
  final GameState Function() readGameState;
  final void Function(GameState) writeGameState;
  late final SpatialModelAnimationController models;
  late final CinematicRuntimePlaybackController cinematics;
  final _poses = <String, SpatialCinematicActorPose>{};
  SpatialCinematicCameraPose? camera;
  bool _disposed = false;
  bool wasCancelled = false;

  String _key(CinematicActorBinding actor) =>
      actor.kind == CinematicActorBindingKind.player
          ? 'player'
          : 'entity:${actor.mapEntityId}';

  SpatialCinematicActorPose? _readActor(CinematicActorBinding actor) {
    final override = _poses[_key(actor)];
    if (override != null) return override;
    if (actor.kind == CinematicActorBindingKind.player) {
      return SpatialCinematicActorPose(
          x: session.movement.x,
          z: session.movement.z,
          facing: session.movement.facing);
    }
    final entity = session.bundle.map.entities
        .where((value) => value.id == actor.mapEntityId && value.npc != null)
        .firstOrNull;
    if (entity == null ||
        !(session.entityIsPresent?.call(session.bundle.map.id, entity) ??
            true)) {
      return null;
    }
    final saved =
        models.worldState.actorState(session.bundle.map.id, entity.id);
    return SpatialCinematicActorPose(
        x: saved?.x ?? entity.pos.x + .5,
        z: saved?.z ?? entity.pos.y + .5,
        facing: saved?.facing ?? session.npcFacing[entity.id] ?? entity.npc!.facing);
  }

  bool _canClose(SpatialModelInstance instance) {
    if (session.movement.wouldModelBlockActor(
        instance.id,
        _poses['player']?.x ?? session.movement.x,
        _poses['player']?.z ?? session.movement.z)) {
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
      SceneRuntimePlanIntent intent, String sourceId) async {
    if (_disposed || models.isPlaying) {
      throw StateError('Spatial playback is busy.');
    }
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
        throw StateError(
            result.message ?? 'The spatial cinematic did not complete.');
      }
      return result.scenePortId!;
    } finally {
      _publishActivity();
    }
  }

  void update(double dt, bool paused) {
    if (_disposed) return;
    models.update(dt, paused: paused);
    if (!paused && dt.isFinite && dt > 0) {
      cinematics.update(Duration(microseconds: (dt * 1000000).round()));
    }
  }

  void synchronize(SpatialWorldState state) {
    if (models.isPlaying || cinematics.isPlaying) cancel();
    models.synchronize(state);
    _poses.clear();
    camera = null;
  }

  void _publishActivity() {
    if (!_disposed) {
      session.storyActive.value = models.isPlaying || cinematics.isPlaying;
    }
  }

  void cancel() {
    if (models.isPlaying || cinematics.isPlaying) wasCancelled = true;
    models.cancel();
    cinematics.cancel();
    _publishActivity();
  }

  void skip() {
    if (session.presentationPaused) return;
    models.update(86400);
    cinematics.update(const Duration(days: 1));
    _publishActivity();
  }

  void dispose() {
    if (_disposed) return;
    cancel();
    _disposed = true;
    models.dispose();
    session.onPresentationFrame = null;
    session.onCancelStory = null;
    session.onSkipStory = null;
    session.worldStateProvider = null;
    session.heroStoryPose = null;
    session.npcStoryPose = null;
    session.storyCamera = null;
  }
}

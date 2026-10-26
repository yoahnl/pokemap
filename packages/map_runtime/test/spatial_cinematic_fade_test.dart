import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_story_playback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'scene holds black across clips and an arbitrary awaited action',
    () async {
      final host = await _Host.load();
      addTearDown(host.dispose);
      final owner = Object();
      final out = host.play('out', owner: owner);
      host.story.update(.1, false);
      expect(host.opacity, closeTo(.5, .00001));
      host.story.update(.1, false);
      expect(await out, 'completed');
      expect(host.opacity, 1);
      expect(host.session.storyInputLocked, isFalse);

      await Future<void>.delayed(Duration.zero);
      host.story.update(3, false);
      expect(host.opacity, 1);
      host.story.releaseScene(Object());
      expect(host.opacity, 1);

      final reveal = host.play('in', owner: owner);
      expect(host.opacity, 1);
      host.story.update(.1, false);
      expect(host.opacity, closeTo(.5, .00001));
      host.story.update(.1, false);
      expect(await reveal, 'completed');
      expect(host.opacity, 0);
      host.story.releaseScene(owner);
      expect(host.opacity, 0);
    },
  );

  test('standalone fade clears at clip completion', () async {
    final host = await _Host.load();
    addTearDown(host.dispose);
    final out = host.play('out');
    host.story.update(.1, false);
    expect(host.opacity, closeTo(.5, .00001));
    host.story.update(.1, false);
    expect(await out, 'completed');
    expect(host.opacity, 0);
  });

  test(
    'scene termination cancels an active fade before releasing black',
    () async {
      final host = await _Host.load();
      addTearDown(host.dispose);
      final owner = Object();
      final out = host.play('out', owner: owner);
      final rejected = expectLater(out, throwsStateError);
      host.story.update(.1, false);
      host.story.releaseScene(owner);
      await rejected;
      host.story.update(1, false);
      expect(host.opacity, 0);
      expect(host.session.storyInputLocked, isFalse);
    },
  );

  for (final termination in [
    'scene',
    'cancel',
    'map',
    'synchronize',
    'dispose',
  ]) {
    test('$termination releases black between clips', () async {
      final host = await _Host.load();
      addTearDown(host.dispose);
      final owner = Object();
      final out = host.play('out', owner: owner);
      host.story.update(.2, false);
      await out;
      expect(host.opacity, 1);
      switch (termination) {
        case 'scene':
          host.story.releaseScene(owner);
        case 'cancel':
          host.story.cancel();
        case 'map':
          host.session.onBeforeMapChange!();
        case 'synchronize':
          host.story.synchronize(host.state.spatialWorldState);
        case 'dispose':
          host.story.dispose();
      }
      expect(host.opacity, 0);
      expect(host.session.storyInputLocked, isFalse);
    });
  }

  test(
    'cancelling an active fade restores input and clears the overlay',
    () async {
      final host = await _Host.load();
      addTearDown(host.dispose);
      final out = host.play('out', owner: Object());
      final rejected = expectLater(out, throwsStateError);
      host.story.update(.1, false);
      expect(host.opacity, closeTo(.5, .00001));
      host.story.cancel();
      await rejected;
      expect(host.opacity, 0);
      expect(host.session.storyInputLocked, isFalse);
    },
  );

  test('failed next clip clears the retained blackout', () async {
    final host = await _Host.load();
    addTearDown(host.dispose);
    final owner = Object();
    final out = host.play('out', owner: owner);
    host.story.update(.2, false);
    await out;
    expect(host.opacity, 1);
    await expectLater(host.play('invalid', owner: owner), throwsStateError);
    expect(host.opacity, 0);
    expect(host.session.storyInputLocked, isFalse);
  });

  test(
    'commit failure clears the blackout even with an active scene owner',
    () async {
      final host = await _Host.load();
      addTearDown(host.dispose);
      host.failCommit = true;
      final out = host.play('out', owner: Object());
      final rejected = expectLater(out, throwsStateError);
      host.story.update(.2, false);
      await rejected;
      expect(host.opacity, 0);
      expect(host.session.storyInputLocked, isFalse);
    },
  );
  for (final sameOwner in [true, false]) {
    test(
      'rejecting a concurrent clip preserves fade owner and poses sameOwner=$sameOwner',
      () async {
        final host = await _Host.load(bindPlayer: true);
        addTearDown(host.dispose);
        final owner = Object();
        final first = host.play('out', owner: owner);
        host.story.update(.1, false);
        final pose = host.session.heroStoryPose!();
        expect(pose, isNotNull);
        expect(host.opacity, closeTo(.5, .00001));
        await expectLater(
          host.play('out', owner: sameOwner ? owner : Object()),
          throwsStateError,
        );
        expect(host.session.heroStoryPose!(), same(pose));
        expect(host.opacity, closeTo(.5, .00001));
        expect(host.session.storyInputLocked, isTrue);
        host.story.update(.1, false);
        expect(await first, 'completed');
        expect(host.opacity, 1);
        host.story.releaseScene(Object());
        expect(host.opacity, 1);
        host.story.releaseScene(owner);
        expect(host.opacity, 0);
      },
    );
  }
}

final class _Host {
  _Host(this.root, this.session, this.state) {
    story = SpatialStoryPlayback(
      session: session,
      readGameState: () => state,
      writeGameState: (value) {
        if (failCommit) throw StateError('Commit unavailable');
        state = value;
      },
    );
  }

  final Directory root;
  final SpatialExplorationSession session;
  GameState state;
  late final SpatialStoryPlayback story;
  bool failCommit = false;
  double get opacity => session.cinematicFadeOpacity.value;

  Future<String> play(String id, {Object? owner}) => story.playCinematic(
    SceneRuntimePlanIntent.playCinematic(cinematicId: id),
    'source',
    sceneOwner: owner,
  );

  static Future<_Host> load({bool bindPlayer = false}) async {
    final root = await Directory.systemTemp.createTemp('spatial-fade-');
    final path = '${root.path}/actor.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final actor = ProjectCharacterEntry(
      id: 'actor',
      name: 'Actor',
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          for (final state in [
            CharacterAnimationState.idle,
            CharacterAnimationState.walk,
          ])
            CharacterAnimation(
              state: state,
              direction: direction,
              sourceAssetId: 'actor',
              frames: [
                CharacterAnimationFrame(
                  source: const TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: 32,
                    height: 32,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
      ],
    );
    final project = ProjectManifest(
      name: 'Fade',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'actor',
      ),
      characters: [actor],
      cinematics: [
        for (final mode in ['out', 'in', 'invalid'])
          CinematicAsset(
            id: mode,
            title: mode,
            mapId: 'map',
            actorCompletionPolicy: CinematicActorCompletionPolicy.keepFinal,
            requiredActors: [
              if (bindPlayer) CinematicActorRef(actorId: 'hero'),
            ],
            stageContext: bindPlayer
                ? CinematicStageContext(
                    actorBindings: [
                      CinematicActorBinding(
                        actorId: 'hero',
                        kind: CinematicActorBindingKind.player,
                      ),
                    ],
                    stagePoints: [
                      CinematicStagePoint(
                        id: 'start',
                        label: 'Start',
                        x: 2,
                        y: 2,
                      ),
                    ],
                    initialPlacements: [
                      CinematicActorInitialPlacement(
                        actorId: 'hero',
                        kind: CinematicActorInitialPlacementKind.stagePoint,
                        stagePointId: 'start',
                      ),
                    ],
                  )
                : null,
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'fade',
                  kind: CinematicTimelineStepKind.fade,
                  durationMs: 200,
                  metadata: {
                    cinematicTimelineFadeModeMetadataKey: mode == 'out'
                        ? 'fadeOut'
                        : mode == 'in'
                        ? 'fadeIn'
                        : 'invalid',
                  },
                ),
              ],
            ),
          ),
      ],
    );
    final session = await SpatialExplorationSession.load(
      RuntimeMapBundle(
        manifest: project,
        map: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 8, height: 8),
          spatialScene: MapSpatialScene(width: 8, depth: 8),
        ),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {'actor': path},
      ),
    );
    return _Host(
      root,
      session,
      GameState(
        saveId: 'save',
        currentMapId: 'map',
        playerPosition: GridPos(
          x: session.movement.x.floor(),
          y: session.movement.z.floor(),
        ),
        playerSpatialPosition: PlayerSpatialPosition(
          x: session.movement.x,
          z: session.movement.z,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    story.dispose();
    session.dispose();
    await root.delete(recursive: true);
  }
}

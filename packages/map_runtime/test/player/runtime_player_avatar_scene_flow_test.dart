import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

const _mapId = 'avatar_room';
const _spawn = GridPos(x: 2, y: 2);
const _costumeEvent = 'evt_019abcde-1500-7000-8000-000000000001';
const _restoreEvent = 'evt_019abcde-1500-7000-8000-000000000002';
const _brokenEvent = 'evt_019abcde-1500-7000-8000-000000000003';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Player changes avatar through an event, saves to disk and restores it',
    () async {
      final fixture = await _fixture();
      final game = await fixture.open();
      final player = _player(game);
      final initialPosition = player.position.clone();
      final initialSize = player.size.clone();
      final initialFoot = player.footPoint.clone();
      final blockedPosition = await _blockedWestEnd(game);
      game.debugSetPlayerStateForTest(position: _spawn, facing: Direction.west);

      await _interact(game, _costumeEvent);

      expect(identical(_player(game), player), isTrue);
      expect(
        game.gameStateSnapshot.trainerProfile.avatarCharacterId,
        'costume',
      );
      expect(player.characterEntry?.id, 'costume');
      expect(player.position, initialPosition);
      expect(player.size, initialSize);
      expect(player.footPoint, initialFoot);
      expect(player.cinematicFacing, EntityFacing.west);
      expect(game.debugPlayerGridPosition, _spawn);
      await game.ready();
      final dressedActor = player.children
          .whereType<OverworldActorComponent>()
          .single;
      expect(dressedActor.character.id, 'costume');
      expect(
        dressedActor.tileImages.keys,
        contains('character-animation:costume'),
      );
      expect(await _blockedWestEnd(game), blockedPosition);
      game.debugSetPlayerStateForTest(position: _spawn, facing: Direction.west);

      expect(await game.saveGame(), isTrue);
      expect(await fixture.saveFile.exists(), isTrue);
      final savedJson = jsonDecode(await fixture.saveFile.readAsString());
      expect(savedJson['trainerProfile']['avatarCharacterId'], 'costume');
      final saved = await fixture.repository.load();
      expect(saved!.trainerProfile.avatarCharacterId, 'costume');
      expect(saved.playerPosition, _spawn);
      expect(saved.playerFacing, EntityFacing.west);

      final resumed = await fixture.open(saved: saved);
      final resumedPlayer = _player(resumed);
      expect(
        resumed.gameStateSnapshot.trainerProfile.avatarCharacterId,
        'costume',
      );
      expect(resumedPlayer.characterEntry?.id, 'costume');
      expect(resumedPlayer.position, initialPosition);
      expect(resumedPlayer.cinematicFacing, EntityFacing.west);
      await resumed.ready();
      expect(
        resumedPlayer.children
            .whereType<OverworldActorComponent>()
            .single
            .character
            .id,
        'costume',
      );

      resumed.debugSetPlayerStateForTest(
        position: _spawn,
        facing: Direction.east,
      );
      final restorationPosition = resumedPlayer.position.clone();
      await _interact(resumed, _restoreEvent);
      expect(
        resumed.gameStateSnapshot.trainerProfile.avatarCharacterId,
        'hero',
      );
      expect(resumedPlayer.characterEntry?.id, 'hero');
      expect(resumedPlayer.position, restorationPosition);
      expect(resumedPlayer.size, initialSize);
      expect(resumedPlayer.cinematicFacing, EntityFacing.east);
      expect(await resumed.saveGame(), isTrue);
      final restored = await fixture.repository.load();
      expect(restored!.trainerProfile.avatarCharacterId, 'hero');
      final reopened = await fixture.open(saved: restored);
      expect(_player(reopened).characterEntry?.id, 'hero');
      expect(_player(reopened).cinematicFacing, EntityFacing.east);
      expect(reopened.debugPlayerGridPosition, _spawn);
    },
  );

  test(
    'Player rolls back the whole avatar scene when later media is unavailable',
    () async {
      final fixture = await _fixture();
      final game = await fixture.open();
      game.debugSetPlayerStateForTest(
        position: _spawn,
        facing: Direction.north,
      );
      final player = _player(game);
      final initialPosition = player.position.clone();
      final initialSize = player.size.clone();
      final initialFoot = player.footPoint.clone();
      final initialProfile = game.gameStateSnapshot.trainerProfile;
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      expect(request.targetId, 'broken_dresser');
      expect(game.dispatchOverworldInteraction(request), isTrue);
      await _settle(game);

      expect(game.gameStateSnapshot.trainerProfile, initialProfile);
      expect(player.characterEntry?.id, 'hero');
      expect(player.position, initialPosition);
      expect(player.size, initialSize);
      expect(player.footPoint, initialFoot);
      expect(player.cinematicFacing, EntityFacing.north);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(_brokenEvent)),
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
      await game.ready();
      expect(
        player.children
            .whereType<OverworldActorComponent>()
            .single
            .character
            .id,
        'hero',
      );
      expect(await game.saveGame(), isTrue);
      expect(
        (await fixture.repository.load())!.trainerProfile.avatarCharacterId,
        'hero',
      );
    },
  );

  test('Player presents the avatar before commit and restores it on presentation cancellation', () async {
    final fixture = await _fixture(suspendedPresentation: true);
    final presentation = _SuspendedPresentation();
    final game = await fixture.open(presentationPlayer: presentation);
    addTearDown(() {
      if (!presentation.terminal.isCompleted) presentation.cancel();
    });
    final player = _player(game);
    final initialState = game.gameStateSnapshot;
    final initialPosition = player.position.clone();
    final initialSize = player.size.clone();
    final request = game.overworldInteractionSnapshot.primaryAction!.request;
    expect(game.dispatchOverworldInteraction(request), isTrue);
    await _waitUntil(game, () => presentation.request != null);
    await game.ready();

    expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
    expect(game.gameStateSnapshot, initialState);
    expect(game.gameStateSnapshot.trainerProfile.avatarCharacterId, 'hero');
    expect(player.characterEntry?.id, 'costume');
    final actor = player.children.whereType<OverworldActorComponent>().single;
    expect(actor.character.id, 'costume');
    expect(actor.debugAnimationSource?.imageId, 'character-animation:costume');
    expect(actor.debugAnimationSource?.sourceRect.width, 64);
    expect(actor.debugAnimationSource?.sourceRect.height, 48);
    expect(player.position, initialPosition);
    expect(player.size, initialSize);
    expect(player.cinematicFacing, EntityFacing.west);
    expect(await game.saveGame(), isFalse);

    presentation.cancel();
    await _settle(game);
    await game.ready();

    expect(game.gameStateSnapshot, initialState);
    expect(player.characterEntry?.id, 'hero');
    final restoredActor = player.children
        .whereType<OverworldActorComponent>()
        .single;
    expect(restoredActor.character.id, 'hero');
    expect(
      restoredActor.debugAnimationSource?.imageId,
      'character-animation:hero',
    );
    expect(restoredActor.debugAnimationSource?.sourceRect.width, 32);
    expect(restoredActor.debugAnimationSource?.sourceRect.height, 32);
    expect(player.position, initialPosition);
    expect(player.size, initialSize);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_costumeEvent)),
    );
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(await game.saveGame(), isTrue);
    expect(
      (await fixture.repository.load())!.trainerProfile.avatarCharacterId,
      'hero',
    );
  });

  for (final invalid in [
    'missingId',
    'ambiguousId',
    'missingMedia',
    'unreadableMedia',
  ]) {
    test(
      'Player rejects persisted avatar $invalid without choosing a default',
      () async {
        var fixture = await _fixture();
        final id = invalid == 'missingId' ? 'unknown' : 'costume';
        await fixture.repository.save(
          GameState(
            saveId: 'invalid_avatar',
            currentMapId: _mapId,
            playerPosition: _spawn,
            playerFacing: EntityFacing.east,
            trainerProfile: TrainerProfile(
              name: 'Player',
              avatarCharacterId: id,
            ),
          ),
        );
        final saved = await fixture.repository.load();
        if (invalid == 'ambiguousId') {
          fixture = _AvatarFixture(
            fixture.root,
            fixture.bundle.copyWith(
              manifest: fixture.bundle.manifest.copyWith(
                characters: [
                  ...fixture.bundle.manifest.characters,
                  _character('costume', 64, 48),
                ],
              ),
            ),
            fixture.repository,
          );
        } else if (invalid == 'missingMedia') {
          await File('${fixture.root.path}/costume.png').delete();
        } else if (invalid == 'unreadableMedia') {
          await File('${fixture.root.path}/costume.png')
              .writeAsBytes([1, 2, 3]);
        }
        await expectLater(
          fixture.open(saved: saved),
          throwsA(
            invalid.endsWith('Id')
                ? isA<FormatException>()
                : anyOf(isA<StateError>(), isA<Exception>()),
          ),
        );
        expect(
          (await fixture.repository.load())!.trainerProfile.avatarCharacterId,
          id,
        );
      },
    );
  }

  test(
    'Player keeps the configured default when the save has no avatar selection',
    () async {
      final fixture = await _fixture();
      await fixture.repository.save(
        const GameState(
          saveId: 'default_avatar',
          currentMapId: _mapId,
          playerPosition: _spawn,
          trainerProfile: TrainerProfile(name: 'Player'),
        ),
      );
      final game = await fixture.open(saved: await fixture.repository.load());
      expect(_player(game).characterEntry?.id, 'hero');
      expect(game.gameStateSnapshot.trainerProfile.avatarCharacterId, isNull);
    },
  );
}

PlayerComponent _player(PlayableMapGame game) =>
    game.world.children.whereType<PlayerComponent>().single;

Future<void> _interact(PlayableMapGame game, String eventId) async {
  final request = game.overworldInteractionSnapshot.primaryAction!.request;
  expect(game.dispatchOverworldInteraction(request), isTrue);
  await _settle(game);
  expect(
    game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
    contains(eventId),
  );
}

Future<void> _settle(PlayableMapGame game) async {
  for (var tick = 0; tick < 500; tick++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (!game.debugIsMapActivationDispatchInFlight &&
        !game.debugIsNarrativeSpatialDispatchInFlight &&
        !game.debugIsGameplayInputLocked) {
      return;
    }
  }
  fail('The avatar event did not settle.');
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() condition) async {
  for (var tick = 0; tick < 500; tick++) {
    if (condition()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('The avatar presentation did not start.');
}

Future<Vector2> _blockedWestEnd(PlayableMapGame game) async {
  game.debugSetPlayerStateForTest(position: _spawn, facing: Direction.west);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.left),
  );
  for (var tick = 0; tick < 40; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.left),
  );
  for (var tick = 0; tick < 20; tick++) {
    game.update(0.016);
  }
  expect(game.debugPlayerGridPosition, _spawn);
  return _player(game).position.clone();
}

final class _AvatarFileRepository extends FileGameSaveRepository {
  _AvatarFileRepository(this.file);

  final File file;

  @override
  Future<String> getSaveFilePath() async => file.path;
}

final class _AvatarGame extends PlayableMapGame {
  _AvatarGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    required super.saveData,
    required super.runtimeMapBundleLoader,
    super.presentationCinematicPlayer,
  }) : super(initialMapActivationReason: MapActivationReason.saveRestore);

  @override
  bool get isLoaded => true;
}

final class _AvatarFixture {
  _AvatarFixture(this.root, this.bundle, this.repository);

  final Directory root;
  final RuntimeMapBundle bundle;
  final _AvatarFileRepository repository;

  File get saveFile => repository.file;

  Future<PlayableMapGame> open({
    GameState? saved,
    ScenePresentationCinematicRuntimePlayer? presentationPlayer,
  }) async {
    final game = _AvatarGame(
      bundle: bundle,
      projectFilePath: '${root.path}/project.json',
      saveRepository: repository,
      presentationCinematicPlayer: presentationPlayer,
      saveData: saveDataFromGameState(
        saved ??
            const GameState(
              saveId: 'avatar_save',
              currentMapId: _mapId,
              playerPosition: _spawn,
              playerFacing: EntityFacing.west,
              trainerProfile: TrainerProfile(
                name: 'Player',
                avatarCharacterId: 'hero',
              ),
            ),
      ),
      runtimeMapBundleLoader: ({
        required projectFilePath,
        required mapId,
      }) async => bundle,
    );
    addTearDown(game.onRemove);
    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _settle(game);
    await game.ready();
    return game;
  }
}

Future<_AvatarFixture> _fixture({bool suspendedPresentation = false}) async {
  final root = await Directory.systemTemp.createTemp('runtime-player-avatar-');
  addTearDown(() => root.delete(recursive: true));
  for (final (id, width, height) in [('hero', 32, 32), ('costume', 64, 48)]) {
    await File('${root.path}/$id.png')
        .writeAsBytes(img.encodePng(img.Image(width: width, height: height)));
  }
  final scenes = [
    _scene('costume', [
      'costume',
    ], suspendedPresentation: suspendedPresentation),
    _scene('restore', ['hero']),
    _scene('broken', ['costume', 'broken']),
  ];
  final project = ProjectManifest(
    name: 'Avatar Scene lifecycle',
    maps: const [
      ProjectMapEntry(id: _mapId, name: 'Room', relativePath: 'room.json'),
    ],
    tilesets: const [],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      defaultPlayerCharacterId: 'hero',
    ),
    characters: [
      _character('hero', 32, 32),
      _character('costume', 64, 48),
      _character('broken', 32, 32),
    ],
    scenes: scenes,
    presentationCinematics: [
      PresentationCinematicAsset(
        id: 'avatar_pause',
        title: 'Avatar preview',
        durationUs: 1000000,
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        for (final (eventId, entityId, sceneId) in [
          (_costumeEvent, 'dresser', 'costume'),
          (_restoreEvent, 'restorer', 'restore'),
          (_brokenEvent, 'broken_dresser', 'broken'),
        ])
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: sceneId,
              source: NarrativeEventSourceRef.entityInteract(_mapId, entityId),
              conditions: const [],
              sceneId: sceneId,
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
      ],
      legacyClaims: const [],
    ),
  );
  final map = MapData(
    id: _mapId,
    name: 'Room',
    size: const GridSize(width: 6, height: 6),
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      const MapEntity(
        id: 'start',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: _spawn,
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
      for (final (id, position) in [
        ('dresser', const GridPos(x: 1, y: 2)),
        ('restorer', const GridPos(x: 3, y: 2)),
        ('broken_dresser', const GridPos(x: 2, y: 1)),
      ])
        MapEntity(
          id: id,
          name: id,
          kind: MapEntityKind.npc,
          pos: position,
          npc: const MapEntityNpcData(displayName: 'Dresser'),
        ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  await File('${root.path}/room.json').writeAsString(jsonEncode(map.toJson()));
  final bundle = RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: const {},
    characterAnimationAbsolutePathsByAssetId: {
      'hero': '${root.path}/hero.png',
      'costume': '${root.path}/costume.png',
    },
  );
  return _AvatarFixture(
    root,
    bundle,
    _AvatarFileRepository(File('${root.path}/save.json')),
  );
}

ProjectCharacterEntry _character(String id, int width, int height) =>
    ProjectCharacterEntry(
      id: id,
      name: id,
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
              sourceAssetId: id,
              frames: [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
      ],
    );

SceneAsset _scene(
  String id,
  List<String> characterIds, {
  bool suspendedPresentation = false,
}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      for (var i = 0; i < characterIds.length; i++)
        SceneNode(
          id: 'avatar_$i',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setPlayerAvatar(characterId: characterIds[i]),
          ),
        ),
      if (suspendedPresentation)
        SceneNode(
          id: 'preview',
          kind: SceneNodeKind.presentationCinematic,
          payload: ScenePresentationCinematicPayload(
            presentationCinematicId: 'avatar_pause',
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_avatar',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'avatar_0',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (var i = 0; i < characterIds.length; i++)
        SceneEdge(
          id: 'avatar_${i}_next',
          fromNodeId: 'avatar_$i',
          fromPortId: 'completed',
          toNodeId: i + 1 < characterIds.length
              ? 'avatar_${i + 1}'
              : suspendedPresentation
              ? 'preview'
              : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      if (suspendedPresentation)
        SceneEdge(
          id: 'preview_end',
          fromNodeId: 'preview',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.presentationCompleted,
        ),
    ],
  ),
);

final class _SuspendedPresentation
    implements ScenePresentationCinematicRuntimePlayer {
  ScenePresentationCinematicRuntimeRequest? request;
  final terminal = Completer<RuntimePresentationExecutionTerminal>();

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest value,
  ) {
    request = value;
    return terminal.future;
  }

  void cancel() => terminal.complete(
    const RuntimePresentationExecutionTerminal(
      runToken: RuntimePresentationRunToken(1),
      result: RuntimePresentationExecutionResult.cancelled,
    ),
  );
}

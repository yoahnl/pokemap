import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_cinematic_runtime_playback_sink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'native exploration resolves dedicated character assets and authored frame timing',
      () async {
    final root = await Directory.systemTemp.createTemp('spatial-runtime-');
    addTearDown(() => root.delete(recursive: true));
    final image = img.Image(width: 128, height: 64);
    final path = '${root.path}/hero.png';
    await File(path).writeAsBytes(img.encodePng(image));
    final character = ProjectCharacterEntry(
        id: 'hero',
        name: 'Héros',
        tilesetId: 'unused',
        animations: [
          for (final direction in [
            EntityFacing.north,
            EntityFacing.south,
            EntityFacing.east,
            EntityFacing.west
          ])
            for (final state in CharacterAnimationState.values)
              CharacterAnimation(
                  state: state,
                  direction: direction,
                  sourceAssetId: 'hero-sheet',
                  frames: const [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0, y: 0, width: 32, height: 32),
                        durationMs: 50),
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 64, y: 16, width: 32, height: 32),
                        durationMs: 100)
                  ])
        ]);
    final scene = MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)));
    final manifest = ProjectManifest(
        version: ProjectVersion.v9,
        name: 'Spatial',
        settings: const ProjectSettings(
            dimension: ProjectDimension.threeD,
            defaultPlayerCharacterId: 'hero'),
        maps: const [],
        tilesets: const [],
        characters: [character]);
    final bundle = RuntimeMapBundle(
        manifest: manifest,
        map: MapData(
            version: ProjectVersion.v9,
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 8, height: 8),
            layers: const [],
            spatialScene: scene),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {'hero-sheet': path});
    final session = await SpatialExplorationSession.load(bundle);
    addTearDown(session.dispose);
    expect(session.bundle.map, bundle.map);
    expect(session.frame(0).frame, const Rect.fromLTWH(0, 0, 32, 32));
    session.movement.setInput(x: 0, z: -1);
    final first = session.frame(.05);
    expect(first.frame, const Rect.fromLTWH(64, 16, 32, 32));
    expect(first.z, lessThan(4));
    session.movement.setInput(x: 1, z: 0, run: true);
    session.frame(.05);
    expect(session.movement.running, isTrue);
    session.movement.releaseInput();
    expect(session.frame(.05).frame, const Rect.fromLTWH(0, 0, 32, 32));
    session.movement.setPaused(true);
    final paused = session.frame(0);
    expect(session.frame(1).x, paused.x);
  });
  test(
      'NPC dialogue facing is scoped and persistent poses resume after it closes',
      () async {
    final root = await Directory.systemTemp.createTemp('spatial-npc-facing-');
    addTearDown(() => root.delete(recursive: true));
    final image = img.Image(width: 128, height: 32);
    final path = '${root.path}/actors.png';
    await File(path).writeAsBytes(img.encodePng(image));
    final directions = [
      EntityFacing.north,
      EntityFacing.south,
      EntityFacing.east,
      EntityFacing.west
    ];
    final character = ProjectCharacterEntry(
        id: 'actor',
        name: 'Actor',
        tilesetId: 'unused',
        animations: [
          for (var index = 0; index < directions.length; index++)
            for (final state in [
              CharacterAnimationState.idle,
              CharacterAnimationState.walk
            ])
              CharacterAnimation(
                  state: state,
                  direction: directions[index],
                  sourceAssetId: 'actor-sheet',
                  frames: [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: index * 32, y: 0, width: 32, height: 32),
                        durationMs: 100)
                  ])
        ]);
    final npc = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 4, y: 2),
        npc: const MapEntityNpcData(
            characterId: 'actor', facing: EntityFacing.north));
    final other = npc.copyWith(id: 'other', pos: const GridPos(x: 1, y: 4));
    await File('${root.path}/hello.json').writeAsBytes(
        const RuntimeDialogueDocumentCodec()
            .encodeUtf8(RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(
          title: 'Start', steps: [RuntimeDialogueLine('Bonjour !')])
    ])));
    var world = const SpatialWorldState.empty()
        .setActorState('map', npc.id,
            SpatialActorRuntimeState(x: 4.5, z: 2.5, facing: EntityFacing.east))
        .setActorState(
            'map',
            other.id,
            SpatialActorRuntimeState(
                x: 1.5, z: 4.5, facing: EntityFacing.west));
    final before = world;
    final session = await SpatialExplorationSession.load(
        RuntimeMapBundle(
            manifest: ProjectManifest(
                version: ProjectVersion.v9,
                name: 'Facing',
                settings: const ProjectSettings(
                    dimension: ProjectDimension.threeD,
                    defaultPlayerCharacterId: 'actor'),
                maps: const [],
                tilesets: const [],
                characters: [
                  character
                ],
                dialogues: const [
                  ProjectDialogueEntry(
                      id: 'hello', name: 'Hello', relativePath: 'hello.json')
                ]),
            map: MapData(
                version: ProjectVersion.v9,
                id: 'map',
                name: 'Map',
                size: const GridSize(width: 8, height: 8),
                layers: const [],
                entities: [npc, other],
                spatialScene: MapSpatialScene(
                    width: 8,
                    depth: 8,
                    navigation: SpatialNavigationProfile(
                        spawn: SpatialSpawn(x: 4, z: 4)))),
            projectRootDirectory: root.path,
            tilesetAbsolutePathsById: const {},
            characterAnimationAbsolutePathsByAssetId: {'actor-sheet': path}),
        worldStateProvider: () => world);
    addTearDown(session.dispose);
    session.npcFacing[npc.id] = EntityFacing.north;
    session.npcFacing[other.id] = EntityFacing.south;
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(64, 0, 32, 32));
    final dialogue = session
        .showDialogue(const DialogueRef(dialogueId: 'hello'), entity: npc);
    await _waitForDialogue(session);
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(32, 0, 32, 32));
    expect(session.npcFrame(other).frame, const Rect.fromLTWH(96, 0, 32, 32));
    session.npcStoryPose = (entity) => entity.id == npc.id
        ? const SpatialCinematicActorPose(
            x: 4.5, z: 2.5, facing: EntityFacing.north)
        : null;
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(0, 0, 32, 32));
    session.npcStoryPose = null;
    world = world.setActorState('map', npc.id,
        SpatialActorRuntimeState(x: 4.5, z: 2.5, facing: EntityFacing.west));
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(32, 0, 32, 32));
    session.confirmDialogue();
    expect((await dialogue).success, isTrue);
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(96, 0, 32, 32));
    world = before;
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(64, 0, 32, 32));
    world = const SpatialWorldState.empty();
    expect(session.npcFrame(npc).frame, const Rect.fromLTWH(32, 0, 32, 32));
    final cancelled = session
        .showDialogue(const DialogueRef(dialogueId: 'hello'), entity: other);
    await _waitForDialogue(session);
    expect(session.npcFrame(other).frame, const Rect.fromLTWH(64, 0, 32, 32));
    world = before;
    session.closeDialogue();
    expect((await cancelled).success, isFalse);
    expect(session.npcFrame(other).frame, const Rect.fromLTWH(96, 0, 32, 32));
    world = const SpatialWorldState.empty();
    expect(session.npcFrame(other).frame, const Rect.fromLTWH(64, 0, 32, 32));
  });
  test('3D test rejects missing player instead of inventing an atlas',
      () async {
    final bundle = RuntimeMapBundle(
        manifest: const ProjectManifest(
            version: ProjectVersion.v9,
            name: 'Missing hero',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(dimension: ProjectDimension.threeD)),
        map: MapData(
            version: ProjectVersion.v9,
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 2, height: 2),
            spatialScene: MapSpatialScene(width: 2, depth: 2)),
        projectRootDirectory: '/unused',
        tilesetAbsolutePathsById: const {});
    await expectLater(SpatialExplorationSession.load(bundle), throwsStateError);
  });
}

Future<void> _waitForDialogue(SpatialExplorationSession session) async {
  if (session.dialoguePresentation.value != null) return;
  final completion = Completer<void>();
  void listener() {
    if (session.dialoguePresentation.value != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  session.dialoguePresentation.addListener(listener);
  try {
    await completion.future;
  } finally {
    session.dialoguePresentation.removeListener(listener);
  }
}

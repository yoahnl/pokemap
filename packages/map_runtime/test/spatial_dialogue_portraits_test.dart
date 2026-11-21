import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show
        FileGameSaveRepository,
        PlayableMapGame,
        RuntimeDialogueTextSpeed,
        RuntimeInputControl,
        RuntimeInputEvent;
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:map_runtime/src/spatial/spatial_exploration_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '2D interactions publish the two portraits and the neutral fallback',
    () async {
      final fixture = await _portraitProject(ProjectDimension.twoD);
      const map = MapData(
        id: 'garden',
        name: 'Jardin',
        size: GridSize(width: 8, height: 8),
        tilesetId: 'sprites',
        mapMetadata: MapMetadata(defaultSpawnId: 'entrance'),
        entities: [
          MapEntity(
            id: 'entrance',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 4, y: 4),
            blocksMovement: false,
            spawn: MapEntitySpawnData(
              role: EntitySpawnRole.playerStart,
              facing: EntityFacing.north,
            ),
          ),
          MapEntity(
            id: 'speaker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 3),
            npc: MapEntityNpcData(
              characterId: 'hero',
              dialogue: DialogueRef(dialogueId: 'hello'),
            ),
          ),
        ],
      );
      final bundle = await _bundle(fixture, map);
      final game = _LoadedPortraitGame(
        bundle: bundle,
        projectFilePath: '${fixture.root}/project.json',
        saveRepository: _PortraitSaveRepository('${fixture.root}/save.json'),
      );
      addTearDown(game.onRemove);
      game.setDialogueFlutterOverlayPreferred(true);
      game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.instant);
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _driveGame(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            game.debugCompletedMapActivationDispatchCount > 0,
      );
      expect(game.debugFlowPhaseName, 'overworld');
      void confirm() {
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          ),
          isTrue,
        );
      }

      final presentation = game.dialoguePresentationListenable;
      confirm();
      await _driveGame(game, () => presentation.value?.fullText == 'Bonjour.');
      expect(presentation.value?.portrait?.portraitStateId, 'neutral');
      confirm();
      await _driveGame(game, () => presentation.value?.fullText == 'Oh !');
      expect(presentation.value?.portrait?.portraitStateId, 'surprised');
      confirm();
      await _driveGame(
        game,
        () => presentation.value?.fullText == 'Je réfléchis.',
      );
      expect(presentation.value?.portrait?.portraitStateId, 'neutral');
      confirm();
      await _driveGame(
        game,
        () => presentation.value?.fullText == 'À bientôt.',
      );
      expect(presentation.value?.portrait, isNull);
    },
  );

  test(
    'spatial dialogue shows authored expressions and falls back per line',
    () async {
      final (session, root) = await _openSession();
      final residentBytes = session.bundle.resourceBudget.residentBytes;
      final result = session.showDialogue(
        const DialogueRef(dialogueId: 'hello'),
      );
      await _waitForDialogue(session);
      final first = session.dialoguePresentation.value!;
      expect(first.fullText, 'Bonjour.');
      expect(first.portrait?.portraitStateId, 'neutral');
      expect(first.portrait?.characterName, 'Élia');
      expect(first.portrait?.fitMode, CharacterPortraitFitMode.contain);

      session.confirmDialogue();
      final second = session.dialoguePresentation.value!;
      expect(second.revision, greaterThan(first.revision));
      expect(second.fullText, 'Oh !');
      expect(second.portrait?.portraitStateId, 'surprised');
      expect(second.portrait?.absoluteFilePath, startsWith('$root/assets/'));
      expect(second.portrait?.fitMode, CharacterPortraitFitMode.cover);
      expect(
        second.portrait?.absoluteFilePath,
        isNot(first.portrait?.absoluteFilePath),
      );

      session.confirmDialogue();
      final third = session.dialoguePresentation.value!;
      expect(third.revision, greaterThan(second.revision));
      expect(third.fullText, 'Je réfléchis.');
      expect(third.portrait?.characterId, 'elia');
      expect(third.portrait?.portraitStateId, 'neutral');
      expect(
        third.portrait?.absoluteFilePath,
        first.portrait?.absoluteFilePath,
      );
      session.confirmDialogue();
      final fourth = session.dialoguePresentation.value!;
      expect(fourth.fullText, 'À bientôt.');
      expect(fourth.portrait, isNull);
      session.confirmDialogue();
      expect(
        (await result.timeout(const Duration(seconds: 3))).success,
        isTrue,
      );
      expect(session.dialoguePresentation.value, isNull);
      expect(session.bundle.resourceBudget.residentBytes, residentBytes);
    },
  );

  test('closing during icon preload keeps the next dialogue and releases its image', () async {
    final (session, root) = await _openSession();
    final budget = session.bundle.resourceBudget;
    final before = budget.residentBytes;
    final readingIcon = Completer<void>();
    final finishReading = Completer<void>();
    final outside = Zone.current;
    List<SceneDialogueLinePolicy> withIcon(String text) => [
      SceneDialogueLinePolicy(
        nodeName: 'Start',
        lineIndex: 0,
        feedback: DialogueLineFeedback(
          segments: [
            DialogueTextSegment(text),
            DialogueIconSegment(
              assetId: 'dialogue-icon',
              widthPx: 32,
              heightPx: 32,
            ),
          ],
        ),
      ),
    ];
    final opening = IOOverrides.runZoned(
      () => session.showDialogue(
        const DialogueRef(dialogueId: 'with-icon'),
        linePolicies: withIcon('Patientez.'),
      ),
      createFile: (path) {
        final file = outside.run(() => File(path));
        return path == '$root/hero.png'
            ? _DelayedIcon(file, readingIcon, finishReading.future)
            : file;
      },
    );
    addTearDown(() async {
      if (!finishReading.isCompleted) finishReading.complete();
      session.closeDialogue();
      await opening.timeout(const Duration(seconds: 3));
    });
    await Future.any<void>([
      readingIcon.future,
      opening.then<void>((result) {
        throw StateError('Dialogue ended before preload: ${result.message}');
      }),
    ]).timeout(const Duration(seconds: 3));
    expect(session.dialoguePresentation.value, isNull);
    session.closeDialogue();

    final replacement = session.showDialogue(
      const DialogueRef(dialogueId: 'plain'),
      linePolicies: withIcon('Une autre réplique.'),
    );
    await _waitForDialogue(session);
    final current = session.dialoguePresentation.value!;
    expect(current.fullText, 'Une autre réplique.\uFFFC');
    expect(current.portrait, isNull);
    expect(current.iconImages.keys, ['dialogue-icon']);
    final retainedBytes = budget.residentBytes;
    expect(retainedBytes, greaterThan(before));

    finishReading.complete();
    expect(
      (await opening.timeout(const Duration(seconds: 3))).success,
      isFalse,
    );
    expect(session.dialoguePresentation.value, same(current));
    expect(budget.residentBytes, retainedBytes);

    session.confirmDialogue();
    expect(
      (await replacement.timeout(const Duration(seconds: 3))).success,
      isTrue,
    );
    expect(session.dialoguePresentation.value, isNull);
    expect(budget.residentBytes, before);
  });
}

Future<void> _waitForDialogue(SpatialExplorationSession session) async {
  final presentation = session.dialoguePresentation;
  if (presentation.value != null) return;
  final published = Completer<void>();
  void changed() {
    if (presentation.value != null && !published.isCompleted) {
      published.complete();
    }
  }

  presentation.addListener(changed);
  try {
    await published.future.timeout(const Duration(seconds: 3));
  } finally {
    presentation.removeListener(changed);
  }
}

typedef _PortraitProject = ({
  String root,
  String heroPath,
  RuntimeProjectCatalog catalog,
});

Future<_PortraitProject> _portraitProject(ProjectDimension dimension) async {
  final qaRoot = Platform.environment['AVELUNE_QA_ROOT'];
  final parent = qaRoot == null
      ? Directory.systemTemp
      : await Directory(qaRoot).create(recursive: true);
  final directory = await parent.createTemp('spatial-portraits-');
  addTearDown(() => directory.delete(recursive: true));
  final root = await directory.resolveSymbolicLinks();

  final heroPath = '$root/hero.png';
  await File(heroPath)
      .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
  const states = [
    CharacterPortraitStateDefinition(id: 'neutral', displayName: 'Neutre'),
    CharacterPortraitStateDefinition(id: 'surprised', displayName: 'Surprise'),
  ];
  final records = <AssetRecord>[];
  for (final (index, state) in states.indexed) {
    final bytes = image.encodePng(image.Image(width: 16 + index, height: 16));
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'image/png',
    );
    final blob = File('$root/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    records.add(
      AssetRecord(
        id: 'elia-${state.id}',
        logicalPath: 'assets/portraits/elia-${state.id}.png',
        artifact: artifact,
      ),
    );
  }
  final registry = File('$root/$assetCatalogStorageKey');
  await registry.writeAsString(
    jsonEncode(AssetCatalog(records: records).toJson()),
  );
  await File('$root/hello.yarn').writeAsString('''
title: Start
---
<<portrait elia neutral>>
Bonjour.
<<portrait elia surprised>>
Oh !
<<portrait elia missing>>
Je réfléchis.
À bientôt.
===
''');
  await File('$root/plain.yarn').writeAsString('''
title: Start
---
Une autre réplique.\uFFFC
===
''');
  await File('$root/with-icon.yarn').writeAsString('''
title: Start
---
<<portrait elia neutral>>
Patientez.\uFFFC
===
''');
  final project = ProjectManifest(
    version: dimension == ProjectDimension.threeD
        ? ProjectVersion.v9
        : ProjectVersion.v8,
    name: 'Expressions',
    maps: const [],
    settings: ProjectSettings(
      dimension: dimension,
      defaultPlayerCharacterId: 'hero',
    ),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'sprites',
        name: 'Sprites',
        relativePath: 'hero.png',
      ),
    ],
    characters: [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'sprites',
        animations: [
          for (final direction in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: direction,
              sourceAssetId: 'hero',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
        ],
      ),
      const ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'sprites',
        portraits: [
          CharacterPortraitVariant(
            portraitStateId: 'neutral',
            assetId: 'elia-neutral',
          ),
          CharacterPortraitVariant(
            portraitStateId: 'surprised',
            assetId: 'elia-surprised',
            fitMode: CharacterPortraitFitMode.cover,
          ),
        ],
      ),
    ],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'hello',
        name: 'Hello',
        relativePath: 'hello.yarn',
      ),
      ProjectDialogueEntry(
        id: 'plain',
        name: 'Plain',
        relativePath: 'plain.yarn',
      ),
      ProjectDialogueEntry(
        id: 'with-icon',
        name: 'With icon',
        relativePath: 'with-icon.yarn',
      ),
    ],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: states,
    ),
  );
  final publication = PortableCatalogPublication.encodeProject(project);
  final projectFile = File('$root/project.json');
  await projectFile.writeAsString(jsonEncode(publication.descriptor));
  for (final object in publication.storage.objects.entries) {
    final file = File('$root/catalog/objects/${object.key}.json');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(object.value);
  }
  final catalog = await RuntimeProjectCatalog.open(projectFile.path);
  addTearDown(catalog.dispose);
  return (catalog: catalog, root: root, heroPath: heroPath);
}

Future<RuntimeMapBundle> _bundle(_PortraitProject fixture, MapData map) async {
  final (:catalog, :root, :heroPath) = fixture;
  final manifest = await catalog.manifestForMap(map);
  expect(manifest.characters.map((character) => character.id), ['hero']);
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: root,
    tilesetAbsolutePathsById: {'dialogue-icon': heroPath, 'sprites': heroPath},
    characterAnimationAbsolutePathsByAssetId: {'hero': heroPath},
    projectCatalog: catalog,
  );
}

Future<(SpatialExplorationSession, String)> _openSession() async {
  final fixture = await _portraitProject(ProjectDimension.threeD);
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'garden',
    name: 'Jardin',
    size: const GridSize(width: 8, height: 8),
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
    ),
  );
  final session = await SpatialExplorationSession.load(
    await _bundle(fixture, map),
  );
  addTearDown(session.dispose);
  return (session, fixture.root);
}

class _LoadedPortraitGame extends PlayableMapGame {
  _LoadedPortraitGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

class _PortraitSaveRepository extends FileGameSaveRepository {
  _PortraitSaveRepository(this.path);

  final String path;

  @override
  Future<String> getSaveFilePath() async => path;
}

Future<void> _driveGame(PlayableMapGame game, bool Function() ready) async {
  for (var frame = 0; frame < 180 && !ready(); frame++) {
    game.update(1 / 60);
    await Future<void>.delayed(const Duration(milliseconds: 8));
  }
  expect(ready(), isTrue, reason: 'Phase: ${game.debugFlowPhaseName}');
}

final class _DelayedIcon extends Fake implements File {
  _DelayedIcon(this._file, this._reading, this._finishReading);

  final File _file;
  final Completer<void> _reading;
  final Future<void> _finishReading;

  @override
  Future<FileStat> stat() => _file.stat();

  @override
  String resolveSymbolicLinksSync() => _file.resolveSymbolicLinksSync();

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async {
    _reading.complete();
    await _finishReading;
    return _file.open(mode: mode);
  }
}

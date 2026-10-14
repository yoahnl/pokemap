import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

const _welcome =
    'Bienvenue dans la carte source. Ce texte vient de la commande suivante.';
const _returning = 'Content de te revoir.';
const _independent = 'Je suis indépendant.';
const _independentReturning =
    "Mon A est distinct et l'interrupteur global est actif.";
const _archiveHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifestPath =
      Platform.environment['AVELUNE_AC13_EVENT_REFERENCE_MANIFEST'];
  final skip = manifestPath == null
      ? 'Generate ac13_event_reference_fixtures.dart and set AVELUNE_AC13_EVENT_REFERENCE_MANIFEST.'
      : false;
  late _Reference reference;
  late Map<String, List<int>> nativeBytesBefore;

  setUpAll(() async {
    if (manifestPath == null) return;
    reference = _Reference(
      Map<String, dynamic>.from(
        jsonDecode(await File(manifestPath).readAsString()) as Map,
      ),
    );
    expect(reference.raw['writerVerified'], isTrue);
    expect(reference.raw['sourceUnchanged'], isTrue);
    expect(reference.raw['sourceScriptsArchiveHash'], _archiveHash);
    expect(reference.raw['sourceScriptsExecuted'], 0);
    expect(reference.raw['aiCalls'], 0);
    expect(reference.raw['published'], isTrue);
    expect(reference.raw['globalPlayabilityCertified'], isFalse);
    expect(
      reference.raw['sourceHashesAfter'],
      reference.raw['sourceHashesBefore'],
    );
    nativeBytesBefore = await _nativeBytes(reference);
  });

  tearDownAll(() async {
    if (manifestPath == null) return;
    final after = await _nativeBytes(reference);
    expect(after.keys.toSet(), nativeBytesBefore.keys.toSet());
    for (final entry in nativeBytesBefore.entries) {
      expect(
        after[entry.key],
        orderedEquals(entry.value),
        reason: 'Runtime must preserve native project ${entry.key}',
      );
    }
  });

  test('EV-A converted pages keep independent self switches and global state through disk reload', () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: reference.projectFilePath,
      mapId: reference.mapId(1),
    );
    expect(bundle.manifest.eventRegistry!.mode, EventSystemMode.v2Only);
    expect(
      bundle.manifest.eventRegistry!.records.where(
        (record) => record.definitionOrNull != null,
      ),
      hasLength(5),
    );
    expect(
      bundle.manifest.eventRegistry!.records.where(
        (record) => record.draftOrNull != null,
      ),
      hasLength(1),
    );
    expect(bundle.manifest.settings.defaultPlayerCharacterId, isNotNull);
    expect(bundle.characterAnimationAbsolutePathsByAssetId, isNotEmpty);
    final welcomeEntity = bundle.map.entities.singleWhere(
      (entity) => entity.id == reference.entityId('Welcome'),
    );
    expect(welcomeEntity.kind, MapEntityKind.npc);
    expect(welcomeEntity.blocksMovement, isTrue);
    expect(welcomeEntity.properties[mapEntityCollisionWidthProperty], '1');
    expect(welcomeEntity.properties[mapEntityCollisionHeightProperty], '1');
    final welcomeA = reference.selfFact(1);
    final independentA = reference.selfFact(2);
    final global = reference.globalFact(1);
    expect(welcomeA, isNot(independentA));
    final saveRoot = await Directory.systemTemp.createTemp('ac13-ev-a-save-');
    final repository = _DiskSaveRepository(
      path.join(saveRoot.path, 'save.json'),
    );
    _ConvertedReferenceGame? game;
    try {
      game = await _start(reference, 1, repository);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      await _ticks(game, 12);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(game.debugIsPlayerStepping, isFalse);
      await _interact(game, _welcome);
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[welcomeA],
        isNull,
      );
      await _finishDialogue(game);
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[welcomeA],
        isTrue,
      );
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[global],
        isTrue,
      );
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[independentA],
        isNull,
      );
      await _interact(game, _returning);
      await _finishDialogue(game);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 3, y: 0),
        facing: Direction.south,
      );
      await _interact(game, _independent);
      await _finishDialogue(game);
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[independentA],
        isTrue,
      );
      await _interact(game, _independentReturning);
      await _finishDialogue(game);
      final expectedFacts = {welcomeA: true, independentA: true, global: true};
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        expectedFacts,
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(await game.saveGame(), isTrue);
      expect(await File(repository.filePath).exists(), isTrue);
      final persisted = (await repository.load())!;
      expect(persisted.currentMapId, reference.mapId(1));
      expect(persisted.playerPosition, const GridPos(x: 3, y: 0));
      expect(
        persisted.narrativeFactRuntimeState.overridesByFactId,
        expectedFacts,
      );
      expect(
        persisted.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      game.onRemove();
      game = await _start(reference, 1, repository);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      expect(await game.loadGame(), isTrue);
      await _waitUntil(game, () => _idle(game!));
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        expectedFacts,
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 3, y: 0));
      await _interact(game, _independentReturning);
      await _finishDialogue(game);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      await _interact(game, _returning);
      await _finishDialogue(game);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        expectedFacts,
      );
    } finally {
      game?.onRemove();
      await saveRoot.delete(recursive: true);
    }
  }, skip: skip);

  test(
    'unknown script and following reward stay one whole quarantined event',
    () async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: reference.projectFilePath,
        mapId: reference.mapId(1),
      );
      final projection = Map<String, dynamic>.from(
        (reference.raw['sourceEvents'] as Map)['projection'] as Map,
      );
      final events = (projection['events'] as List).cast<Map>();
      final quarantined = events.singleWhere(
        (event) => event['status'] == 'quarantinedWholeEvent',
      );
      expect(quarantined['gaps'], contains('sourceQuarantined'));
      expect(
        (quarantined['pages'] as List).cast<Map>().every(
          (page) => page['nativeEventId'] == null,
        ),
        isTrue,
      );
      expect(
        bundle.map.entities.where(
          (entity) => entity.name == 'Quarantined reward',
        ),
        isEmpty,
      );
      expect(
        bundle.manifest.eventRegistry!.records
            .singleWhere((record) => record.draftOrNull != null)
            .draftOrNull!
            .name,
        'Quarantined reward',
      );
      expect(bundle.manifest.facts, hasLength(3));
      expect(bundle.manifest.scenes, hasLength(5));
      final factBindings = projection['factBindings'] as Map;
      expect(
        factBindings.keys.where((key) => (key as String).contains(':event:3:')),
        isEmpty,
      );
      expect(
        factBindings.containsKey('source:${reference.namespace}:switch:2'),
        isFalse,
      );
      final saveRoot = await Directory.systemTemp.createTemp(
        'ac13-quarantine-save-',
      );
      final game = await _start(
        reference,
        1,
        _DiskSaveRepository(path.join(saveRoot.path, 'save.json')),
      );
      try {
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 5, y: 0),
          facing: Direction.south,
        );
        final before = game.gameStateSnapshot;
        _press(game, RuntimeInputControl.primary);
        await _ticks(game, 60);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(game.dialoguePresentationListenable.value, isNull);
        expect(game.gameStateSnapshot.bag, before.bag);
        expect(
          game.gameStateSnapshot.narrativeFactRuntimeState,
          before.narrativeFactRuntimeState,
        );
        expect(
          game.gameStateSnapshot.narrativeEventProgress,
          before.narrativeEventProgress,
        );
      } finally {
        game.onRemove();
        await saveRoot.delete(recursive: true);
      }
    },
    skip: skip,
  );

  test('EV-C converted static warp preserves facing, waits for fade, and reloads without an arrival loop', () async {
    final arrival = await loadRuntimeMapBundle(
      projectFilePath: reference.projectFilePath,
      mapId: reference.mapId(2),
    );
    expect(arrival.map.warps, hasLength(1));
    expect(arrival.map.warps.single.pos, const GridPos(x: 2, y: 2));
    expect(arrival.map.warps.single.targetMapId, reference.mapId(2));
    expect(arrival.map.warps.single.triggerMode, MapWarpTriggerMode.sceneOnly);
    expect(
      arrival.map.entities.where(
        (entity) => entity.kind != MapEntityKind.spawn,
      ),
      isEmpty,
    );
    final saveRoot = await Directory.systemTemp.createTemp('ac13-ev-c-save-');
    final repository = _DiskSaveRepository(
      path.join(saveRoot.path, 'save.json'),
    );
    _ConvertedReferenceGame? game;
    try {
      game = await _start(reference, 1, repository);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 2),
        facing: Direction.south,
      );
      final activationBefore = game.debugCompletedMapActivationDispatchCount;
      final source = await loadRuntimeMapBundle(
        projectFilePath: reference.projectFilePath,
        mapId: reference.mapId(1),
      );
      final warpEntity = source.map.entities.singleWhere(
        (entity) => entity.id == reference.entityId('Static warp'),
      );
      expect(warpEntity.kind, MapEntityKind.npc);
      expect(warpEntity.blocksMovement, isTrue);
      expect(warpEntity.properties[mapEntityCollisionWidthProperty], '1');
      expect(warpEntity.properties[mapEntityCollisionHeightProperty], '1');
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      await _ticks(game, 12);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 2));
      expect(game.debugHasPendingMapTransition, isFalse);
      _press(game, RuntimeInputControl.primary);
      await _waitUntil(game, () => game!.debugFlowPhaseName == 'mapTransition');
      expect(game.gameStateSnapshot.currentMapId, reference.mapId(1));
      game.update(0.001);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.gameStateSnapshot.currentMapId, reference.mapId(1));
      var transitionTicks = 0;
      await _waitUntil(game, () {
        transitionTicks++;
        return game!.gameStateSnapshot.currentMapId == reference.mapId(2) &&
            _idle(game);
      });
      expect(transitionTicks, greaterThan(1));
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
      expect(
        game.debugCompletedMapActivationDispatchCount,
        activationBefore + 1,
      );
      final afterTransfer = game.debugCompletedMapActivationDispatchCount;
      await _ticks(game, 120);
      expect(game.gameStateSnapshot.currentMapId, reference.mapId(2));
      expect(game.debugCompletedMapActivationDispatchCount, afterTransfer);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(await game.saveGame(), isTrue);
      final disk = (await repository.load())!;
      expect(disk.currentMapId, reference.mapId(2));
      expect(disk.playerPosition, const GridPos(x: 2, y: 2));
      expect(disk.playerFacing, EntityFacing.south);
      game.onRemove();
      game = await _start(reference, 1, repository);
      expect(game.gameStateSnapshot.currentMapId, reference.mapId(1));
      expect(await game.loadGame(), isTrue);
      await _waitUntil(
        game,
        () =>
            game!.gameStateSnapshot.currentMapId == reference.mapId(2) &&
            _idle(game),
      );
      final activationAfterReload =
          game.debugCompletedMapActivationDispatchCount;
      await _ticks(game, 120);
      expect(game.gameStateSnapshot.currentMapId, reference.mapId(2));
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
      expect(
        game.debugCompletedMapActivationDispatchCount,
        activationAfterReload,
      );
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.debugFlowPhaseName, 'overworld');
    } finally {
      game?.onRemove();
      await saveRoot.delete(recursive: true);
    }
  }, skip: skip);
}

final class _Reference {
  const _Reference(this.raw);
  final Map<String, dynamic> raw;
  String get projectFilePath => raw['projectFilePath'] as String;
  String get namespace => raw['sourceNamespace'] as String;
  String mapId(int sourceId) => (raw['mapIds'] as Map)['$sourceId'] as String;
  String entityId(String name) => (raw['entityIds'] as Map)[name] as String;
  Map get _factBindings =>
      ((raw['sourceEvents'] as Map)['projection'] as Map)['factBindings']
          as Map;
  String selfFact(int eventId) =>
      _factBindings['source:$namespace:map:1:event:$eventId:self:A'] as String;
  String globalFact(int switchId) =>
      _factBindings['source:$namespace:switch:$switchId'] as String;
}

Future<Map<String, List<int>>> _nativeBytes(_Reference reference) async => {
  for (final name in (reference.raw['nativeHashes'] as Map).keys)
    name as String: await File(
      path.join(path.dirname(reference.projectFilePath), name),
    ).readAsBytes(),
};

Future<_ConvertedReferenceGame> _start(
  _Reference reference,
  int sourceMapId,
  FileGameSaveRepository repository,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: reference.projectFilePath,
    mapId: reference.mapId(sourceMapId),
  );
  final game = _ConvertedReferenceGame(
    bundle: bundle,
    projectFilePath: reference.projectFilePath,
    saveRepository: repository,
    initialGameState: GameState(
      saveId: 'original-ac13-reference',
      currentMapId: bundle.map.id,
    ),
  );
  game.onGameResize(Vector2(320, 240));
  game.setDialogueFlutterOverlayPreferred(true);
  await game.onLoad();
  await _waitUntil(game, () => _idle(game));
  return game;
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition;

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<void> _interact(PlayableMapGame game, String expectedText) async {
  expect(_idle(game), isTrue);
  _press(game, RuntimeInputControl.primary);
  await _waitUntil(
    game,
    () => game.dialoguePresentationListenable.value != null,
  );
  expect(game.dialoguePresentationListenable.value!.fullText, expectedText);
  expect(game.debugFlowPhaseName, 'dialogue');
}

Future<void> _finishDialogue(PlayableMapGame game) async {
  if (!game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed) {
    _press(game, RuntimeInputControl.primary);
    expect(
      game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
      isTrue,
    );
  }
  _press(game, RuntimeInputControl.primary);
  await _waitUntil(game, () => _idle(game));
  expect(game.dialoguePresentationListenable.value, isNull);
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 480; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Converted source trace did not settle: phase=${game.debugFlowPhaseName}, map=${game.gameStateSnapshot.currentMapId}, activation=${game.debugIsMapActivationDispatchInFlight}, spatial=${game.debugIsNarrativeSpatialDispatchInFlight}, outcomes=${game.debugIsNarrativeOutcomeWorkInFlight}',
  );
}

final class _ConvertedReferenceGame extends PlayableMapGame {
  _ConvertedReferenceGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    required super.initialGameState,
  });
  @override
  bool get isLoaded => true;
}

final class _DiskSaveRepository extends FileGameSaveRepository {
  _DiskSaveRepository(this.filePath);
  final String filePath;
  @override
  Future<String> getSaveFilePath() async => filePath;
}

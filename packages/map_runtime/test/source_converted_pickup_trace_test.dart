import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

late String _found;
late String _bag;
late String _itemName;
late int _delayMicros;
const _archiveHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifestPath =
      Platform.environment['AVELUNE_AC13_PICKUP_REFERENCE_MANIFEST'];
  final skip = manifestPath == null
      ? 'Generate ac13_pickup_reference_fixture.dart and set AVELUNE_AC13_PICKUP_REFERENCE_MANIFEST.'
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
    final symbol = reference.raw['pickupSymbol'] ?? 'BURNHEAL';
    expect(symbol, isIn(['BURNHEAL', 'TM101']));
    final machine = symbol == 'TM101';
    _itemName = machine ? 'TM101' : 'Burn Heal';
    _found = machine ? 'You found TM101 Aerial Ace!' : 'You found a Burn Heal!';
    _bag =
        "You put the $_itemName in\nyour Bag's \uFFFC${machine ? 'TMs & HMs' : 'Medicine'} pocket.";
    _delayMicros = machine ? 3500000 : 2000000;
    expect(reference.raw['machineUseQualified'] ?? false, isFalse);
    expect(reference.raw['writerVerified'], isTrue);
    expect(reference.raw['sourceUnchanged'], isTrue);
    expect(reference.raw['sourceScriptsArchiveHash'], _archiveHash);
    expect(reference.raw['sourceScriptsExecuted'], 0);
    expect(reference.raw['aiCalls'], 0);
    expect(reference.raw['published'], isFalse);
    expect(reference.raw['sourceAutoplayBgm'], isFalse);
    expect(reference.raw['globalPlayabilityCertified'], isFalse);
    expect(reference.raw['fullBagSourceParityQualified'], isFalse);
    expect(reference.raw['sourceBagMutationTimingQualified'], isFalse);
    expect(
      reference.raw['nativeConsequenceCommitPolicy'],
      'bufferUntilSceneCompleted',
    );
    final sourceEvents = reference.raw['sourceEvents'] as Map;
    final projection = sourceEvents['projection'] as Map;
    expect(projection['pickupExecutionQualification'], {
      'stateBoundary': 'afterCompletedInteraction',
      'nativeConsequenceCommitPolicy': 'bufferUntilSceneCompleted',
      'sourceBagMutationTimingQualified': false,
      'fullPickupParityQualified': false,
    });
    expect(
      reference.raw['sourceHashesAfter'],
      reference.raw['sourceHashesBefore'],
    );
    nativeBytesBefore = await _nativeBytes(reference);
    expect(
      nativeBytesBefore.keys.toSet(),
      (reference.raw['nativeHashes'] as Map).keys.toSet(),
    );
  });

  tearDownAll(() async {
    if (manifestPath == null) return;
    final after = await _nativeBytes(reference);
    expect(after.keys.toSet(), nativeBytesBefore.keys.toSet());
    for (final entry in nativeBytesBefore.entries) {
      expect(
        after[entry.key],
        orderedEquals(entry.value),
        reason: 'Runtime must preserve the generated project ${entry.key}',
      );
    }
  });

  test('EV-B converted unit pickup plays typed feedback, releases collision and survives disk reload without duplication', () async {
    final bundle = await _bundle(reference);
    expect(bundle.manifest.eventRegistry!.mode, EventSystemMode.v2Only);
    expect(
      diagnoseWorldRules(bundle.manifest, maps: [bundle.map]).diagnostics
          .where((entry) => entry.severity == WorldRuleDiagnosticSeverity.error)
          .map((entry) => '${entry.code.name}:${entry.ruleId}'),
      isEmpty,
    );
    final entity = bundle.map.entities.singleWhere(
      (entry) => entry.id == reference.pickupEntityId,
    );
    expect(entity.kind, MapEntityKind.npc);
    expect(entity.blocksMovement, isTrue);
    expect(entity.npc!.characterId, isNotNull);
    expect(bundle.characterAnimationAbsolutePathsByAssetId, isNotEmpty);
    final policies = _lineFeedbacks(bundle.manifest);
    expect(policies.keys, unorderedEquals([_found, _bag]));
    final found = policies[_found]!;
    final bag = policies[_bag]!;
    expect(found.revealIntervalMicros, 25000);
    expect(found.advance.kind, DialogueLineAdvanceKind.autoAfterReveal);
    expect(found.advance.delayMicros, _delayMicros);
    expect(found.audioCue!.volume, 0.8);
    expect(bag.revealIntervalMicros, 25000);
    expect(bag.advance.kind, DialogueLineAdvanceKind.confirm);
    expect(bag.audioCue, isNull);
    final name = found.segments.whereType<DialogueTextSegment>().singleWhere(
      (segment) =>
          segment.text ==
          (_itemName == 'TM101' ? 'TM101 Aerial Ace' : _itemName),
    );
    expect(name.style!.colorArgb, 0xff0070f8);
    final icon = bag.segments.whereType<DialogueIconSegment>().single;
    expect(icon.widthPx, 18);
    expect(icon.heightPx, 32);
    final iconBytes = await File(bundle.tilesetAbsolutePathsById[icon.assetId]!)
        .readAsBytes();
    expect(iconBytes, orderedEquals(await reference.originalBytes('icon')));
    expect(ByteData.sublistView(iconBytes).getUint32(16), 18);
    expect(ByteData.sublistView(iconBytes).getUint32(20), 32);
    final media = bundle.manifest.cinematicMediaAssets.singleWhere(
      (entry) => entry.id == found.audioCue!.mediaAssetId,
    );
    expect(media.kind, CinematicMediaAssetKind.sound);
    expect(media.durationMs, 1000);
    expect(media.loopByDefault, isFalse);
    expect(
      await File(path.join(bundle.projectRootDirectory, media.relativePath))
          .readAsBytes(),
      orderedEquals(await reference.originalBytes('audio')),
    );
    final saveRoot = await Directory.systemTemp.createTemp('ac13-pickup-save-');
    final repository = _DiskSaveRepository(
      path.join(saveRoot.path, 'save.json'),
    );
    final audio = _AudioTrace();
    _ConvertedPickupGame? game;
    try {
      game = await _start(reference, repository, audio);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      expect(
        game.debugRuntimeNpcPositions[reference.pickupEntityId],
        const GridPos(x: 1, y: 1),
      );
      await _tryEnterPickup(game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      _press(game, RuntimeInputControl.primary);
      await _waitUntil(
        game,
        () => game!.dialoguePresentationListenable.value != null,
      );
      final first = game.dialoguePresentationListenable.value!;
      expect(first.fullText, _found);
      expect(first.isCurrentLineFullyRevealed, isFalse);
      final revealedRunes = first.text.runes.length;
      game.update(0.025);
      expect(
        game.dialoguePresentationListenable.value!.text.runes.length,
        revealedRunes + 1,
      );
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(await game.saveGame(), isFalse);
      expect(await File(repository.filePath).exists(), isFalse);
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[reference.selfFact],
        isNull,
      );
      await _waitUntil(game, () => audio.cues.isNotEmpty);
      expect(audio.cues, hasLength(1));
      expect(audio.cues.single, found.audioCue);
      _press(game, RuntimeInputControl.primary);
      expect(
        game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
        isTrue,
      );
      expect(
        game.dialoguePresentationListenable.value!.isAdvanceAvailable,
        isFalse,
      );
      _press(game, RuntimeInputControl.primary);
      expect(game.dialoguePresentationListenable.value!.fullText, _found);
      game.update(_delayMicros / 1000000 - 0.001);
      await Future<void>.delayed(Duration.zero);
      expect(game.dialoguePresentationListenable.value!.fullText, _found);
      game.update(0.0011);
      await _waitUntil(
        game,
        () => game!.dialoguePresentationListenable.value?.fullText == _bag,
      );
      expect(
        game
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId[reference.selfFact],
        isNull,
      );
      _press(game, RuntimeInputControl.primary);
      final second = game.dialoguePresentationListenable.value!;
      expect(second.isCurrentLineFullyRevealed, isTrue);
      expect(second.isAdvanceAvailable, isTrue);
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(await game.saveGame(), isFalse);
      expect(await File(repository.filePath).exists(), isFalse);
      expect(second.segments.whereType<DialogueIconSegment>().single, icon);
      expect(second.iconPngBytes[icon.assetId], orderedEquals(iconBytes));
      game.update(3);
      await Future<void>.delayed(Duration.zero);
      expect(game.dialoguePresentationListenable.value!.fullText, _bag);
      _press(game, RuntimeInputControl.primary);
      await _waitUntil(game, () => _idle(game!));
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(game.gameStateSnapshot.bag.entries, [
        BagEntry(itemId: reference.itemId, quantity: 1),
      ]);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        {reference.selfFact: true},
      );
      expect(
        game.debugRuntimeNpcPositions.containsKey(reference.pickupEntityId),
        isFalse,
      );
      await _tryEnterPickup(game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(audio.cues, hasLength(1));
      expect(audio.playbackIds.toSet(), hasLength(1));
      expect(await game.saveGame(), isTrue);
      expect(await File(repository.filePath).exists(), isTrue);
      final saved = (await repository.load())!;
      expect(saved.bag.entries, [
        BagEntry(itemId: reference.itemId, quantity: 1),
      ]);
      expect(saved.narrativeFactRuntimeState.overridesByFactId, {
        reference.selfFact: true,
      });
      expect(
        saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      game.onRemove();
      game = await _start(reference, repository, audio);
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(await game.loadGame(), isTrue);
      await _waitUntil(game, () => _idle(game!));
      expect(game.gameStateSnapshot.bag.entries, [
        BagEntry(itemId: reference.itemId, quantity: 1),
      ]);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        {reference.selfFact: true},
      );
      expect(
        game.debugRuntimeNpcPositions.containsKey(reference.pickupEntityId),
        isFalse,
      );
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 60);
      expect(_idle(game), isTrue);
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(game.gameStateSnapshot.bag.entries, [
        BagEntry(itemId: reference.itemId, quantity: 1),
      ]);
      expect(audio.cues, hasLength(1));
      await _tryEnterPickup(game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    } finally {
      game?.onRemove();
      await saveRoot.delete(recursive: true);
    }
  }, skip: skip);

  test('an unknown source script quarantines the entire following pickup without native grants or feedback', () async {
    final bundle = await _bundle(reference);
    final events = (reference.projection['events'] as List).cast<Map>();
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
        (entity) => entity.name == 'Quarantined pickup',
      ),
      isEmpty,
    );
    expect(
      bundle.manifest.eventRegistry!.records
          .where((record) => record.draftOrNull != null)
          .single
          .draftOrNull!
          .name,
      'Quarantined pickup',
    );
    expect(
      (reference.projection['factBindings'] as Map).keys.where(
        (key) => (key as String).contains(':event:2:'),
      ),
      isEmpty,
    );
    final saveRoot = await Directory.systemTemp.createTemp(
      'ac13-quarantine-save-',
    );
    final audio = _AudioTrace();
    _ConvertedPickupGame? game;
    try {
      game = await _start(
        reference,
        _DiskSaveRepository(path.join(saveRoot.path, 'save.json')),
        audio,
      );
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 4, y: 0),
        facing: Direction.south,
      );
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 60);
      expect(_idle(game), isTrue);
      expect(game.gameStateSnapshot.bag.entries, isEmpty);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(audio.cues, isEmpty);
    } finally {
      game?.onRemove();
      await saveRoot.delete(recursive: true);
    }
  }, skip: skip);

  test('native refused grant keeps the source pickup present with no success text, audio or consumed fact', () async {
    final saveRoot = await Directory.systemTemp.createTemp(
      'ac13-refused-save-',
    );
    final repository = _DiskSaveRepository(
      path.join(saveRoot.path, 'save.json'),
    );
    final audio = _AudioTrace();
    _ConvertedPickupGame? game;
    try {
      game = await _start(
        reference,
        repository,
        audio,
        bag: Bag(
          entries: [
            BagEntry(
              itemId: reference.itemId,
              quantity: maximumBagEntryQuantity,
            ),
          ],
        ),
      );
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      final before = game.gameStateSnapshot.bag;
      final observedTexts = <String>[];
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 120, observedTexts: observedTexts);
      expect(_idle(game), isTrue);
      expect(game.gameStateSnapshot.bag, before);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(observedTexts, isEmpty);
      expect(audio.cues, isEmpty);
      expect(
        game.debugRuntimeNpcPositions[reference.pickupEntityId],
        const GridPos(x: 1, y: 1),
      );
      await _tryEnterPickup(game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(await game.saveGame(), isTrue);
      final saved = (await repository.load())!;
      expect(saved.bag, before);
      expect(saved.narrativeFactRuntimeState.overridesByFactId, isEmpty);
      game.onRemove();
      game = await _start(reference, repository, audio);
      expect(await game.loadGame(), isTrue);
      await _waitUntil(game, () => _idle(game!));
      expect(game.gameStateSnapshot.bag, before);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      expect(
        game.debugRuntimeNpcPositions[reference.pickupEntityId],
        const GridPos(x: 1, y: 1),
      );
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 120, observedTexts: observedTexts);
      expect(game.gameStateSnapshot.bag, before);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty,
      );
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(observedTexts, isEmpty);
      expect(audio.cues, isEmpty);
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
  String get mapId => raw['mapId'] as String;
  String get itemId => raw['itemId'] as String;
  String get pickupEntityId =>
      (raw['entityIds'] as Map)['Original pickup'] as String;
  Map get projection => (raw['sourceEvents'] as Map)['projection'] as Map;
  String get selfFact =>
      (projection['factBindings']
              as Map)['source:${raw['sourceNamespace']}:map:1:event:1:self:A']
          as String;
  Future<Uint8List> originalBytes(String kind) => File(
    path.join(
      raw['sourceRootPath'] as String,
      ((raw['originalMedia'] as Map)[kind] as Map)['relativePath'] as String,
    ),
  ).readAsBytes();
}

Map<String, DialogueLineFeedback> _lineFeedbacks(ProjectManifest manifest) => {
  for (final scene in manifest.scenes)
    for (final node in scene.graph.nodes)
      if (node.payload case final SceneYarnDialoguePayload payload)
        for (final policy in payload.linePolicies)
          policy.feedback.segments.map((entry) => entry.plainText).join():
              policy.feedback,
};

Future<Map<String, List<int>>> _nativeBytes(_Reference reference) async {
  final root = path.dirname(reference.projectFilePath);
  final result = <String, List<int>>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result[path.relative(entry.path, from: root)] = await entry.readAsBytes();
    }
  }
  return result;
}

Future<RuntimeMapBundle> _bundle(_Reference reference) => loadRuntimeMapBundle(
  projectFilePath: reference.projectFilePath,
  mapId: reference.mapId,
);

Future<_ConvertedPickupGame> _start(
  _Reference reference,
  FileGameSaveRepository repository,
  _AudioTrace audio, {
  Bag? bag,
}) async {
  final bundle = await _bundle(reference);
  final game = _ConvertedPickupGame(
    bundle: bundle,
    projectFilePath: reference.projectFilePath,
    saveRepository: repository,
    dialogueFeedbackPlaybackPort: audio,
    initialGameState: GameState(
      saveId: 'original-ac13-pickup',
      currentMapId: bundle.map.id,
      bag: bag ?? const Bag(),
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

Future<void> _tryEnterPickup(PlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.down),
    ),
    isTrue,
  );
  await _ticks(game, 1);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.down),
  );
  await _waitUntil(game, () => !game.debugIsPlayerStepping);
}

Future<void> _ticks(
  PlayableMapGame game,
  int count, {
  List<String>? observedTexts,
}) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    final presentation = game.dialoguePresentationListenable.value;
    if (presentation != null) observedTexts?.add(presentation.fullText);
  }
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 480; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Converted pickup did not settle: phase=${game.debugFlowPhaseName}, '
    'activation=${game.debugIsMapActivationDispatchInFlight}, '
    'outcomes=${game.debugIsNarrativeOutcomeWorkInFlight}, '
    'dialogue=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

final class _AudioTrace implements DialogueFeedbackPlaybackPort {
  final cues = <DialogueAudioCue>[];
  final playbackIds = <String>[];
  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    cues.add(cue);
    playbackIds.add(playbackId);
  }
}

final class _ConvertedPickupGame extends PlayableMapGame {
  _ConvertedPickupGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    required super.initialGameState,
    required super.dialogueFeedbackPlaybackPort,
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

import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
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
      hasLength(8),
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

  testWidgets(
    'EVT01 last true empty page masks both lower pages before and after disk reload',
    (tester) async {
      final bundle = (await tester.runAsync(
        () => loadRuntimeMapBundle(
          projectFilePath: reference.projectFilePath,
          mapId: reference.mapId(1),
        ),
      ))!;
      final entityId = reference.entityId('Empty final page');
      final projection =
          ((reference.raw['sourceEvents'] as Map)['projection'] as Map);
      final projected = (projection['events'] as List).cast<Map>().singleWhere(
        (event) =>
            (event['locator'] as Map)['mapId'] == 1 &&
            (event['locator'] as Map)['eventId'] == 5,
      );
      final pages = (projected['pages'] as List).cast<Map>();
      expect(pages.map((page) => page['originalPageIndex']), [0, 1, 2]);
      expect(pages.map((page) => page['isEmpty']), [false, false, true]);
      expect((pages.first['condition'] as Map)['kind'], 'always');
      final namespace = reference.namespace;
      for (final page in pages.skip(1)) {
        final condition = page['condition'] as Map;
        expect(condition['kind'], 'all');
        final children = (condition['children'] as List).cast<Map>();
        expect(children, hasLength(1));
        expect(children.single['kind'], 'selfSwitch');
        expect(
          children.single['factId'],
          'source:$namespace:map:1:event:5:self:A',
        );
        expect(children.single['expectedValue'], isTrue);
      }
      final definitions =
          bundle.manifest.eventRegistry!.records
              .map((record) => record.definitionOrNull)
              .whereType<NarrativeEventDefinition>()
              .where(
                (definition) =>
                    definition.source.kind ==
                        NarrativeEventSourceKind.entityInteract &&
                    definition.source.toJson()['entityId'] == entityId,
              )
              .toList()
            ..sort((a, b) => a.priority.compareTo(b.priority));
      expect(definitions.map((definition) => definition.priority), [0, 1, 2]);
      expect(
        definitions.map((definition) => definition.id),
        pages.map((page) => page['nativeEventId']),
      );
      final emptyDefinition = definitions.last;
      final emptyScene = bundle.manifest.scenes.singleWhere(
        (scene) => scene.id == emptyDefinition.sceneId,
      );
      expect(emptyScene.graph.nodes.map((node) => node.kind), [
        SceneNodeKind.start,
        SceneNodeKind.end,
      ]);
      expect(emptyScene.graph.edges, hasLength(1));
      expect(emptyScene.graph.edges.single.fromPortId, 'completed');
      final selfA = reference.selfFact(5);
      final selfB =
          reference._factBindings['source:$namespace:map:1:event:5:self:B']
              as String;
      final evidencePath =
          Platform.environment['AVELUNE_AC13_EMPTY_PAGE_EVIDENCE_ROOT'];
      final saveRoot = evidencePath == null
          ? (await tester.runAsync(
              () => Directory.systemTemp.createTemp('ac13-evt01-empty-page-'),
            ))!
          : Directory(evidencePath);
      if (evidencePath != null) {
        expect(path.isAbsolute(evidencePath), isTrue);
        expect(await tester.runAsync(saveRoot.exists), isFalse);
        await tester.runAsync(() => saveRoot.create(recursive: true));
      }
      final savePath = path.join(saveRoot.path, 'save.json');
      final nativeRoot = path.dirname(reference.projectFilePath);
      final sourceRoot = reference.raw['sourceRootPath'] as String;
      final nativeBefore = (await tester.runAsync(
        () => _emptyPageDirectoryBytes(nativeRoot),
      ))!;
      final sourceBefore = (await tester.runAsync(
        () => _emptyPageDirectoryBytes(sourceRoot),
      ))!;
      final referenceBytes = (await tester.runAsync(
        () => File(manifestPath!).readAsBytes(),
      ))!;
      final repository = _DiskSaveRepository(savePath);
      final authorities = <Map<String, Object?>>[];
      final interactions = <Map<String, Object?>>[];
      final sounds = _EmptyPageSoundTrace();
      late PlayableMapGame game;
      Future<void> observeAuthority(
        NarrativeEventOccurrence occurrence,
        NarrativeEventDispatchAuthorityPreparation preparation,
      ) async {
        if (occurrence.source.kind != NarrativeEventSourceKind.entityInteract ||
            occurrence.source.toJson()['entityId'] != entityId) {
          return;
        }
        expectSync(preparation, isA<NarrativeEventDispatchAuthorityReady>());
        final ready = preparation as NarrativeEventDispatchAuthorityReady;
        final decision = ready.plan(gameState: game.gameStateSnapshot);
        expectSync(decision, isA<NarrativeEventDispatchHandled>());
        final selected = decision as NarrativeEventDispatchHandled;
        authorities.add({
          'eventId': selected.eventId,
          'sceneId': selected.sceneId,
          'priority': selected.priority,
          'legacyFallbackAllowed': selected.legacyFallbackAllowed,
        });
      }

      var music = RuntimeMusicService(
        driver: _EmptyPageSilentMusicDriver(),
        fadeDelay: (_) async {},
      );
      game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: reference.projectFilePath,
        saveRepository: repository,
        initialGameState: GameState(
          saveId: 'original-ac13-empty-page',
          currentMapId: bundle.map.id,
          playerPosition: const GridPos(x: 3, y: 4),
          playerFacing: EntityFacing.north,
        ),
        musicService: music,
        sceneSoundEffectPlaybackPort: sounds,
        afterNarrativeAuthorityPreparation: observeAuthority,
      );
      var mounted = false;
      Future<void> interactWithEmptyPage(String stage) async {
        final before = strictGameStateSaveJson(game.gameStateSnapshot);
        final previous = authorities.length;
        final dialogueSeen = <String>[];
        final notificationsSeen = <bool>[];
        void observeDialogue() {
          final snapshot = game.dialoguePresentationListenable.value;
          if (snapshot != null) {
            dialogueSeen.add(snapshot.fullText);
          }
        }

        void observeNotification() {
          if (game.runtimeNotificationListenable.value != null) {
            notificationsSeen.add(true);
          }
        }

        game.dialoguePresentationListenable.addListener(observeDialogue);
        game.runtimeNotificationListenable.addListener(observeNotification);
        try {
          expect(_emptyPageWidgetIdle(game), isTrue);
          _press(game, RuntimeInputControl.primary);
          expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
          await _waitForEmptyPageWidget(
            tester,
            () =>
                authorities.length == previous + 1 &&
                _emptyPageWidgetIdle(game),
          );
          expect(authorities.last, {
            'eventId': emptyDefinition.id,
            'sceneId': emptyDefinition.sceneId,
            'priority': 2,
            'legacyFallbackAllowed': false,
          });
          for (var frame = 0; frame < 45; frame++) {
            await _pumpEmptyPageWidget(tester);
            expect(_emptyPageWidgetIdle(game), isTrue);
            expect(game.dialoguePresentationListenable.value, isNull);
            expect(strictGameStateSaveJson(game.gameStateSnapshot), before);
          }
          expect(dialogueSeen, isEmpty);
          expect(notificationsSeen, isEmpty);
          expect(sounds.calls, isEmpty);
          expect(
            game
                .gameStateSnapshot
                .narrativeFactRuntimeState
                .overridesByFactId[selfB],
            isNull,
          );
          interactions.add({
            'stage': stage,
            'selected': authorities.last,
            'dispatchStarted': true,
            'returnedIdle': true,
            'dialogueSeen': dialogueSeen,
            'notificationsSeen': notificationsSeen,
            'stateBefore': before,
            'stateAfter': strictGameStateSaveJson(game.gameStateSnapshot),
          });
        } finally {
          game.dialoguePresentationListenable.removeListener(observeDialogue);
          game.runtimeNotificationListenable.removeListener(
            observeNotification,
          );
        }
      }

      try {
        mounted = true;
        await _mountEmptyPageWidget(tester, game);
        final baseline = game.gameStateSnapshot;
        expect(baseline.narrativeFactRuntimeState.overridesByFactId, isEmpty);
        _press(game, RuntimeInputControl.primary);
        await _waitForEmptyPageWidget(
          tester,
          () =>
              game.dialoguePresentationListenable.value?.fullText ==
              'Première page à jouer avant la page vide.',
        );
        expect(authorities.single['eventId'], definitions.first.id);
        expect(authorities.single['priority'], 0);
        final current = game.dialoguePresentationListenable.value!;
        if (!current.isCurrentLineFullyRevealed) {
          _press(game, RuntimeInputControl.primary);
          expect(
            game
                .dialoguePresentationListenable
                .value!
                .isCurrentLineFullyRevealed,
            isTrue,
          );
        }
        _press(game, RuntimeInputControl.primary);
        await _waitForEmptyPageWidget(tester, () => _emptyPageWidgetIdle(game));
        final writer = NarrativeFactRuntimeWriter(
          NarrativeFactRuntimeResolver.fromFacts(bundle.manifest.facts),
        );
        expect(
          bundle.manifest.facts
              .singleWhere((fact) => fact.id == selfA)
              .legacyFlagName,
          isNull,
        );
        final written = writer.setFact(
          gameState: baseline,
          factId: selfA,
          value: true,
        );
        expect(written.success, isTrue);
        final expected = written.gameState;
        expect(expected.narrativeFactRuntimeState.overridesByFactId, {
          selfA: true,
        });
        expect(expected.storyFlags.activeFlags, {
          ...baseline.storyFlags.activeFlags,
          selfA,
        });
        expect(expected.progression.storyFlags, [
          ...baseline.progression.storyFlags,
          selfA,
        ]);
        expect(
          strictGameStateSaveJson(game.gameStateSnapshot),
          strictGameStateSaveJson(expected),
        );
        await interactWithEmptyPage('after_first_interaction');
        expect(await tester.runAsync(game.saveGame), isTrue);
        final saved = (await tester.runAsync(
          () => _DiskSaveRepository(savePath).load(),
        ))!;
        expect(
          strictGameStateSaveJson(saved),
          strictGameStateSaveJson(expected),
        );
        final savedBytes = (await tester.runAsync(
          () => File(savePath).readAsBytes(),
        ))!;
        await _unmountEmptyPageWidget(tester, game, music);
        mounted = false;
        music = RuntimeMusicService(
          driver: _EmptyPageSilentMusicDriver(),
          fadeDelay: (_) async {},
        );
        game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: reference.projectFilePath,
          saveRepository: _DiskSaveRepository(savePath),
          initialGameState: saved,
          initialMapActivationReason: MapActivationReason.saveRestore,
          musicService: music,
          sceneSoundEffectPlaybackPort: sounds,
          afterNarrativeAuthorityPreparation: observeAuthority,
        );
        mounted = true;
        await _mountEmptyPageWidget(tester, game);
        final activation = game.debugLastCompletedMapActivation!;
        expect(game.debugCompletedMapActivationDispatchCount, 1);
        expect(activation.reason, MapActivationReason.saveRestore);
        expect(activation.mapId, saved.currentMapId);
        expect(
          activation.activationId,
          matches(RegExp(r'^mapact_[1-9][0-9]*_1$')),
        );
        final activationId = activation.activationId;
        final token = 'map:$activationId';
        final oldTokens =
            saved.narrativeEventProgress.appliedNarrativeResetTokens;
        expect(oldTokens, isNot(contains(token)));
        final restoredExpected = saved.copyWith(
          narrativeEventProgress: saved.narrativeEventProgress.copyWith(
            appliedNarrativeResetTokens: [...oldTokens, token],
          ),
        );
        expect(
          strictGameStateSaveJson(game.gameStateSnapshot),
          strictGameStateSaveJson(restoredExpected),
        );
        await interactWithEmptyPage('after_new_game_save_restore');
        expect(authorities.map((entry) => entry['priority']), [0, 2, 2]);
        expect(
          (await tester.runAsync(() => File(savePath).readAsBytes()))!,
          orderedEquals(savedBytes),
        );
        await tester.runAsync(() async {
          expect(await _emptyPageDirectoryBytes(nativeRoot), nativeBefore);
          expect(await _emptyPageDirectoryBytes(sourceRoot), sourceBefore);
          expect(
            await File(manifestPath!).readAsBytes(),
            orderedEquals(referenceBytes),
          );
          await File(
            path.join(saveRoot.path, 'evt01-completed.json'),
          ).writeAsString(
            jsonEncode({
              'kind': 'sourceConvertedLastTrueEmptyPageRuntimeTrace',
              'version': 1,
              'sourceEventId': 5,
              'completed': true,
              'usesRealGameWidget': true,
              'usesRuntimeInputEvents': true,
              'directSceneInvocation': false,
              'sourcePageTruthAfterFirstInteraction': [true, true, true],
              'sourcePageEmpty': [false, false, true],
              'observedAuthoritySelections': authorities,
              'interactions': interactions,
              'savedState': strictGameStateSaveJson(saved),
              'restoredState': strictGameStateSaveJson(game.gameStateSnapshot),
              'onlyColdBootDelta': token,
              'saveRestoredByNewRepositoryAndGame': true,
              'separateOsProcess': false,
              'sourceAndNativeBytesUnchanged': true,
              'sourceIntermediateFactCommitTimingQualified': false,
              'sourceAdmission': false,
              'guiQualified': false,
            }),
            flush: true,
          );
        });
      } finally {
        if (mounted) {
          await _unmountEmptyPageWidget(tester, game, music);
        }
        if (evidencePath == null) {
          await tester.runAsync(() => saveRoot.delete(recursive: true));
        }
      }
    },
    skip: manifestPath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );

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
      expect(bundle.manifest.facts, hasLength(5));
      expect(bundle.manifest.scenes, hasLength(8));
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

bool _emptyPageWidgetIdle(PlayableMapGame game) =>
    game.isLoaded &&
    _idle(game) &&
    !game.debugIsGameplayInputLocked &&
    !game.debugIsEntityAutorunInFlight &&
    game.dialoguePresentationListenable.value == null &&
    game.inputAuthoritySnapshot.acceptsOverworldInput;

Future<void> _pumpEmptyPageWidget(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}

Future<void> _waitForEmptyPageWidget(
  WidgetTester tester,
  bool Function() complete,
) async {
  for (var frame = 0; frame < 1800; frame++) {
    if (complete()) {
      return;
    }
    await _pumpEmptyPageWidget(tester);
  }
  fail('Converted empty-page GameWidget did not settle.');
}

Future<void> _mountEmptyPageWidget(
  WidgetTester tester,
  PlayableMapGame game,
) async {
  game.onGameResize(Vector2(640, 480));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<PlayableMapGame>(game: game),
    ),
  );
  await _waitForEmptyPageWidget(tester, () => game.isLoaded);
  await tester.runAsync(() async => await game.toBeLoaded());
  await _waitForEmptyPageWidget(tester, () => _emptyPageWidgetIdle(game));
}

Future<void> _unmountEmptyPageWidget(
  WidgetTester tester,
  PlayableMapGame game,
  RuntimeMusicService music,
) async {
  for (final control in RuntimeInputControl.values) {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await tester.pumpWidget(const SizedBox.shrink());
  var disposed = false;
  final pending = music.dispose().whenComplete(() => disposed = true);
  for (var frame = 0; frame < 120 && !disposed; frame++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(disposed, isTrue);
  await pending;
}

Future<Map<String, List<int>>> _emptyPageDirectoryBytes(String root) async {
  final result = <String, List<int>>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    expect(entry, isNot(isA<Link>()));
    if (entry is File) {
      result[path.relative(entry.path, from: root)] = await entry.readAsBytes();
    }
  }
  return result;
}

final class _EmptyPageSilentMusicDriver implements FlameCinematicAudioDriver {
  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async => Object();
  @override
  Future<void> setVolume(Object handle, double volume) async {}
  @override
  Future<void> stop(Object handle) async {}
}

final class _EmptyPageSoundTrace implements SceneSoundEffectPlaybackPort {
  final calls = <String>[];
  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    calls.add(mediaAssetId);
  }
}

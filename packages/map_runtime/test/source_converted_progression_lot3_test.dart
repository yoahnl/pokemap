import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:path/path.dart' as path;

const _namespace = 'original-lot3-progression';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath =
      Platform.environment['AVELUNE_LOT3_PROGRESSION_REFERENCE'];
  final missingReference = referencePath == null;

  testWidgets(
    'converted source progression dispatches, changes pages and survives cold disk reload',
    (tester) async {
      await tester.runAsync(() async {
        final reference = Map<String, dynamic>.from(
          jsonDecode(await File(referencePath!).readAsString()) as Map,
        );
        expect(reference['kind'], 'originalLot3ProgressionReference');
        expect(reference['schemaVersion'], 1);
        expect(reference['sourceNamespace'], _namespace);
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['writerOrigin'], 'converterWorkflow.writeApproved');
        expect(reference['published'], isTrue);
        expect(reference['sourceUnchanged'], isTrue);
        expect(reference['sourceScriptsExecuted'], 0);
        expect(reference['aiCalls'], 0);
        expect(reference['fullKantoCertified'], isFalse);
        expect(reference['manualStudioCertified'], isFalse);
        expect(reference['manualPlayerCertified'], isFalse);
        final projectFile = reference['projectFilePath'] as String;
        final sourceRoot = reference['sourceRootPath'] as String;
        final nativeRoot = path.dirname(projectFile);
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(reference['sourceHashesAfter'], reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
        final projection =
            ((reference['sourceEvents'] as Map)['projection'] as Map);
        expect(projection['qualifiedEventCount'], 3);
        expect(projection['quarantinedEventCount'], 1);
        final unknown = (projection['events'] as List).cast<Map>().singleWhere(
          (event) => (event['locator'] as Map)['eventId'] == 4,
        );
        expect(unknown['status'], 'quarantinedWholeEvent');
        expect(unknown['gaps'], contains('sourceCommandUnqualified'));
        final bindings = projection['factBindings'] as Map;
        final counter = bindings['source:$_namespace:variable:1'] as String;
        final global = bindings['source:$_namespace:switch:1'] as String;
        final self =
            bindings['source:$_namespace:map:1:event:1:self:A'] as String;
        expect(bindings.containsKey('source:$_namespace:variable:2'), isFalse);
        expect(bindings.containsKey('source:$_namespace:switch:2'), isFalse);
        expect(
          bindings.containsKey('source:$_namespace:map:1:event:4:self:A'),
          isFalse,
        );
        final ids = reference['entityIds'] as Map;
        final npc = ids['Progression NPC'] as String;
        final object = ids['Disappearing object'] as String;
        final gate = ids['Progression gate'] as String;
        final saveRoot = await Directory.systemTemp.createTemp(
          'lot3-progression-save-',
        );
        final savePath = path.join(saveRoot.path, 'game_save.json');
        PlayableMapGame? game;
        try {
          game = await _start(
            tester,
            projectFile,
            reference['mapId'] as String,
            _DiskSave(savePath),
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valuesByFactId,
            isEmpty,
          );
          expect(game.debugIsNpcActorVisible(npc), isTrue);
          await game.ready();
          expect(game.debugIsNpcActorVisible(object), isTrue);
          expect(game.debugIsNpcActorVisible(gate), isTrue);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 4, y: 1),
            facing: Direction.south,
          );
          _press(game, RuntimeInputControl.down);
          await _ticks(game, 20);
          expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 1));
          expect(game.debugIsPlayerStepping, isFalse);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 1),
            facing: Direction.south,
          );
          await _interact(game, 'Avant la progression.');
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valuesByFactId,
            isEmpty,
          );
          await _nextLine(game, 'Compteur validé.');
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valuesByFactId,
            isEmpty,
          );
          await _finishDialogue(game);
          _expectProgress(game.gameStateSnapshot, counter, global, self);
          await _waitUntil(
            game,
            () =>
                game!.debugIsNpcActorVisible(object) != true &&
                game.debugIsNpcActorVisible(gate) != true &&
                game.debugIsNpcActorVisible(npc) == true,
          );
          expect(game.debugIsNpcActorVisible(npc), isTrue);
          final bundle = await loadRuntimeMapBundle(
            projectFilePath: projectFile,
            mapId: reference['mapId'] as String,
          );
          final projected = projectMapEntityPresentations(
            project: bundle.manifest,
            gameState: game.gameStateSnapshot,
            map: bundle.map,
          );
          final projectedNpc = projected.entities.singleWhere(
            (entity) => entity.id == npc,
          );
          final authoredNpc = bundle.map.entities.singleWhere(
            (entity) => entity.id == npc,
          );
          expect(
            projectedNpc.npc!.characterId,
            authoredNpc.presentation!.variants.first.characterId,
          );
          await _waitUntil(
            game,
            () => game!.world
                .descendants()
                .whereType<OverworldActorComponent>()
                .any(
                  (actor) =>
                      actor.character.id == projectedNpc.npc!.characterId &&
                      actor.isMounted,
                ),
          );
          expect(
            game.world.descendants().whereType<OverworldActorComponent>().where(
              (actor) => actor.character.id == projectedNpc.npc!.characterId,
            ),
            hasLength(1),
            reason:
                'Expected ${projectedNpc.npc!.characterId}; mounted characters '
                '${game.world.descendants().whereType<OverworldActorComponent>().map((actor) => actor.character.id).toList()}; '
                'children ${game.world.children.map((child) => child.runtimeType).toList()}',
          );
          expect(game.debugNpcVisualFacing(npc), EntityFacing.east);
          for (final id in [object, gate]) {
            final entity = projected.entities.singleWhere(
              (entity) => entity.id == id,
            );
            expect(entity.npc, isNull);
            expect(entity.blocksMovement, isFalse);
          }
          await _interact(game, 'Après la progression.');
          await _finishDialogue(game);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 4, y: 1),
            facing: Direction.south,
          );
          await _stepIntoGate(game);
          expect(await game.saveGame(), isTrue);
          expect(await File(savePath).exists(), isTrue);
          final saved = (await _DiskSave(savePath).load())!;
          _expectProgress(saved, counter, global, self);
          expect(saved.playerPosition, const GridPos(x: 4, y: 2));
          expect(
            saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            isEmpty,
          );
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;
          game = await _start(
            tester,
            projectFile,
            reference['mapId'] as String,
            _DiskSave(savePath),
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.valuesByFactId,
            isEmpty,
          );
          expect(game.debugIsNpcActorVisible(object), isTrue);
          expect(game.debugIsNpcActorVisible(gate), isTrue);
          expect(await game.loadGame(), isTrue);
          await _waitUntil(
            game,
            () =>
                _idle(game!) &&
                game.debugIsNpcActorVisible(object) != true &&
                game.debugIsNpcActorVisible(gate) != true &&
                game.world
                    .descendants()
                    .whereType<OverworldActorComponent>()
                    .any(
                      (actor) =>
                          actor.character.id == projectedNpc.npc!.characterId &&
                          actor.isMounted,
                    ),
          );
          _expectProgress(game.gameStateSnapshot, counter, global, self);
          expect(game.debugNpcVisualFacing(npc), EntityFacing.east);
          expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 2));
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 1),
            facing: Direction.south,
          );
          await _interact(game, 'Après la progression.');
          await _finishDialogue(game);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 4, y: 1),
            facing: Direction.south,
          );
          await _stepIntoGate(game);
          _expectProgress(game.gameStateSnapshot, counter, global, self);
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
      });
    },
    skip: missingReference,
  );
}

void _expectProgress(
  GameState state,
  String counter,
  String global,
  String self,
) {
  expect(state.narrativeFactRuntimeState.valuesByFactId, {
    counter: NarrativeValue.integer(2),
    global: const NarrativeValue.boolean(true),
    self: const NarrativeValue.boolean(true),
  });
}

Future<PlayableMapGame> _start(
  WidgetTester tester,
  String projectFile,
  String mapId,
  FileGameSaveRepository repository,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: mapId,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: GameState(
      saveId: 'lot3-progression',
      currentMapId: bundle.map.id,
    ),
  );
  game.onGameResize(Vector2(320, 240));
  game.setDialogueFlutterOverlayPreferred(true);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<PlayableMapGame>(game: game),
    ),
  );
  await game.toBeLoaded();
  await game.ready();
  game.pauseEngine();
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

Future<void> _interact(PlayableMapGame game, String line) async {
  expect(_idle(game), isTrue);
  _press(game, RuntimeInputControl.primary);
  await _waitUntil(
    game,
    () => game.dialoguePresentationListenable.value != null,
  );
  expect(game.dialoguePresentationListenable.value!.fullText, line);
}

void _advance(PlayableMapGame game) {
  if (!game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed) {
    _press(game, RuntimeInputControl.primary);
    expect(
      game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
      isTrue,
    );
  }
  _press(game, RuntimeInputControl.primary);
}

Future<void> _nextLine(PlayableMapGame game, String line) async {
  _advance(game);
  await _waitUntil(
    game,
    () => game.dialoguePresentationListenable.value?.fullText == line,
  );
  expect(game.dialoguePresentationListenable.value!.fullText, line);
}

Future<void> _finishDialogue(PlayableMapGame game) async {
  _advance(game);
  await _waitUntil(game, () => _idle(game));
  expect(game.dialoguePresentationListenable.value, isNull);
}

Future<void> _stepIntoGate(PlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.down),
    ),
    isTrue,
  );
  try {
    await _waitUntil(
      game,
      () => game.debugPlayerGridPosition == const GridPos(x: 4, y: 2),
    );
  } finally {
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.down),
    );
  }
  await _waitUntil(game, () => !game.debugIsPlayerStepping);
  expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 2));
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
    'LOT3 progression did not settle: phase=${game.debugFlowPhaseName}, '
    'position=${game.debugPlayerGridPosition}',
  );
}

Future<Map<String, String>> _hashes(String root) async {
  final entries = <String, String>{};
  await for (final entity in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      entries[path.relative(entity.path, from: root)] = crypto.sha256
          .convert(await entity.readAsBytes())
          .toString();
    }
  }
  final names = entries.keys.toList()..sort();
  return {for (final name in names) name: entries[name]!};
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}

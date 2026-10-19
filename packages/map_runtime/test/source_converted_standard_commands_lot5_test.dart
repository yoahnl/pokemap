import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

const _namespace = 'original-lot5-standard-commands';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_LOT5_COMMANDS_REFERENCE'];
  testWidgets(
    'converted inline sound reveals once and guarded autorun stays terminal after disk reload',
    (tester) async {
      await tester.runAsync(() async {
        final reference = Map<String, dynamic>.from(
          jsonDecode(await File(referencePath!).readAsString()) as Map,
        );
        expect(reference['kind'], 'originalLot5CommandsReference');
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['sourceScriptsExecuted'], 0);
        expect(reference['aiCalls'], 0);
        expect(reference['fullKantoCertified'], isFalse);
        expect(reference['manualStudioCertified'], isFalse);
        expect(reference['audiblePlaybackCertified'], isFalse);
        final projectFile = reference['projectFilePath'] as String;
        final sourceRoot = reference['sourceRootPath'] as String;
        final nativeRoot = path.dirname(projectFile);
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(reference['sourceHashesAfter'], reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
        final projection =
            (reference['sourceEvents'] as Map)['projection'] as Map;
        expect(projection['qualifiedEventCount'], 2);
        expect(projection['quarantinedEventCount'], 1);
        final bindings = projection['factBindings'] as Map;
        final ready = bindings['source:$_namespace:switch:1'] as String;
        final terminal =
            bindings['source:$_namespace:map:1:event:2:self:A'] as String;
        final mapId = reference['mapId'] as String;
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: mapId,
        );
        final media = bundle.manifest.cinematicMediaAssets.singleWhere(
          (entry) => entry.label == 'OriginalCue',
        );
        final authoredCue = bundle.manifest.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneYarnDialoguePayload>()
            .expand((payload) => payload.linePolicies)
            .map((policy) => policy.feedback.audioCue)
            .whereType<DialogueAudioCue>()
            .single;
        expect(authoredCue.mediaAssetId, media.id);
        expect(authoredCue.role, DialogueAudioCueRole.effect);
        expect(authoredCue.revealOffset, 6);
        expect(authoredCue.volume, closeTo(0.48, 0.000001));
        final resolver = NarrativeFactRuntimeResolver.fromFacts(
          bundle.manifest.facts,
        );
        expect(resolver.isValid, isTrue);
        final port = _RecordingPort();
        final seenLines = <String>[];
        final saveRoot = await Directory.systemTemp.createTemp(
          'lot5-commands-save-',
        );
        final repository = _DiskSave(path.join(saveRoot.path, 'save.json'));
        PlayableMapGame? game;
        try {
          game = await _start(
            tester,
            projectFile,
            mapId,
            repository,
            port,
            seenLines,
          );
          expect(_fact(game, resolver, ready), isFalse);
          expect(_fact(game, resolver, terminal), isFalse);
          expect(seenLines, isEmpty);
          expect(port.calls, isEmpty);
          await _ticks(game, 60);
          expect(game.dialoguePresentationListenable.value, isNull);
          expect(seenLines, isEmpty);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 1),
            facing: Direction.south,
          );
          await _interact(game);
          expect(_fact(game, resolver, ready), isFalse);
          expect(_fact(game, resolver, terminal), isFalse);
          await _revealCue(game, port, authoredCue, expectedCalls: 1);
          await _waitUntil(
            game,
            () => game!
                .dialoguePresentationListenable
                .value!
                .isCurrentLineFullyRevealed,
          );
          expect(port.calls, hasLength(1));
          _press(game, RuntimeInputControl.primary);
          await _waitUntil(
            game,
            () =>
                game!.dialoguePresentationListenable.value?.fullText ==
                'Séquence terminée.',
          );
          expect(_fact(game, resolver, ready), isTrue);
          expect(_fact(game, resolver, terminal), isFalse);
          expect(game.inputAuthoritySnapshot.isGameplayLocked, isTrue);
          _finishCurrentLine(game);
          await _waitUntil(game, () => _idle(game!));
          expect(_fact(game, resolver, terminal), isTrue);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          expect(game.dialoguePresentationListenable.value, isNull);
          expect(
            seenLines.where((line) => line == 'Séquence terminée.'),
            hasLength(1),
          );
          await _ticks(game, 90);
          expect(game.dialoguePresentationListenable.value, isNull);
          await _move(
            game,
            RuntimeInputControl.right,
            const GridPos(x: 2, y: 1),
          );
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 1, y: 1),
          );
          expect(await game.saveGame(), isTrue);
          final saved = (await repository.load())!;
          expect(
            saved.narrativeFactRuntimeState.valuesByFactId[ready],
            const NarrativeValue.boolean(true),
          );
          expect(
            saved.narrativeFactRuntimeState.valuesByFactId[terminal],
            const NarrativeValue.boolean(true),
          );
          expect(
            saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            isEmpty,
          );
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;
          seenLines.clear();
          game = await _start(
            tester,
            projectFile,
            mapId,
            _DiskSave(repository.filePath),
            port,
            seenLines,
          );
          expect(await game.loadGame(), isTrue);
          await _waitUntil(game, () => _idle(game!));
          expect(_fact(game, resolver, ready), isTrue);
          expect(_fact(game, resolver, terminal), isTrue);
          await _ticks(game, 120);
          expect(game.dialoguePresentationListenable.value, isNull);
          expect(seenLines, isEmpty);
          expect(port.calls, hasLength(1));
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _move(
            game,
            RuntimeInputControl.right,
            const GridPos(x: 2, y: 1),
          );
          await _move(
            game,
            RuntimeInputControl.left,
            const GridPos(x: 1, y: 1),
          );
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 1),
            facing: Direction.south,
          );
          await _interact(game);
          await _revealCue(game, port, authoredCue, expectedCalls: 2);
          await _waitUntil(
            game,
            () => game!
                .dialoguePresentationListenable
                .value!
                .isCurrentLineFullyRevealed,
          );
          _press(game, RuntimeInputControl.primary);
          await _waitUntil(game, () => _idle(game!));
          await _ticks(game, 60);
          expect(
            seenLines.where((line) => line == 'Séquence terminée.'),
            isEmpty,
          );
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          expect(port.calls, hasLength(2));
          expect(
            port.calls.map((call) => call.playbackId).toSet(),
            hasLength(2),
          );
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
        expect(await _hashes(sourceRoot), reference['sourceHashesBefore']);
        expect(await _hashes(nativeRoot), reference['nativeHashes']);
      });
    },
    skip: referencePath == null,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

bool _fact(
  PlayableMapGame game,
  NarrativeFactRuntimeResolver resolver,
  String id,
) {
  final state = game.gameStateSnapshot;
  final result = resolver.resolve(
    factId: id,
    runtimeState: state.narrativeFactRuntimeState,
    storyFlags: state.storyFlags,
  );
  expect(result, isA<NarrativeFactRuntimeResolved>());
  return (result as NarrativeFactRuntimeResolved).value;
}

Future<PlayableMapGame> _start(
  WidgetTester tester,
  String projectFile,
  String mapId,
  FileGameSaveRepository repository,
  _RecordingPort port,
  List<String> seenLines,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: mapId,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    dialogueFeedbackPlaybackPort: port,
    initialGameState: GameState(
      saveId: 'lot5-commands',
      currentMapId: bundle.map.id,
    ),
  );
  port.visibleText = () => game.dialoguePresentationListenable.value?.text;
  game.dialoguePresentationListenable.addListener(() {
    final line = game.dialoguePresentationListenable.value?.fullText;
    if (line != null && (seenLines.isEmpty || seenLines.last != line)) {
      seenLines.add(line);
    }
  });
  game.setDialogueTextSpeed(RuntimeDialogueTextSpeed.normal);
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
  await _waitUntil(
    game,
    () =>
        game.debugCompletedMapActivationDispatchCount > 0 &&
        _idle(game) &&
        game.inputAuthoritySnapshot.acceptsOverworldInput,
  );
  await _ticks(game, 2);
  await _waitUntil(game, () => _idle(game));
  return game;
}

Future<void> _interact(PlayableMapGame game) async {
  expect(_idle(game), isTrue);
  _press(game, RuntimeInputControl.primary);
  await _waitUntil(
    game,
    () => game.dialoguePresentationListenable.value != null,
  );
  expect(game.dialoguePresentationListenable.value!.fullText, 'Avant.Après.');
  expect(game.inputAuthoritySnapshot.isGameplayLocked, isTrue);
}

Future<void> _revealCue(
  PlayableMapGame game,
  _RecordingPort port,
  DialogueAudioCue expected, {
  required int expectedCalls,
}) async {
  for (var tick = 0; tick < 500; tick++) {
    final visible =
        game.dialoguePresentationListenable.value!.text.runes.length;
    if (visible >= 5) break;
    expect(port.calls, hasLength(expectedCalls - 1));
    game.update(0.001);
    await Future<void>.delayed(Duration.zero);
  }
  expect(game.dialoguePresentationListenable.value!.text, 'Avant');
  expect(port.calls, hasLength(expectedCalls - 1));
  for (var tick = 0; tick < 100; tick++) {
    if (port.calls.length == expectedCalls) break;
    game.update(0.001);
    await Future<void>.delayed(Duration.zero);
  }
  expect(port.calls, hasLength(expectedCalls));
  expect(game.dialoguePresentationListenable.value!.text, 'Avant.');
  expect(port.calls.last.visibleText, 'Avant.');
  expect(port.calls.last.cue, expected);
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
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

void _finishCurrentLine(PlayableMapGame game) {
  if (!game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed) {
    _press(game, RuntimeInputControl.primary);
  }
  _press(game, RuntimeInputControl.primary);
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
  GridPos target,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  try {
    await _waitUntil(game, () => game.debugPlayerGridPosition == target);
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _waitUntil(game, () => !game.debugIsPlayerStepping && _idle(game));
  expect(game.debugPlayerGridPosition, target);
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 480; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'LOT5 commands did not settle: phase=${game.debugFlowPhaseName}, position=${game.debugPlayerGridPosition}, line=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<Map<String, String>> _hashes(String root) async {
  final values = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      values[path.relative(entry.path, from: root)] = crypto.sha256
          .convert(await entry.readAsBytes())
          .toString();
    }
  }
  final names = values.keys.toList()..sort();
  return {for (final name in names) name: values[name]!};
}

final class _RecordingPort implements DialogueFeedbackPlaybackPort {
  final calls =
      <({DialogueAudioCue cue, String playbackId, String? visibleText})>[];
  String? Function()? visibleText;

  @override
  Future<void> playCue(
    DialogueAudioCue cue, {
    required String playbackId,
  }) async {
    calls.add((
      cue: cue,
      playbackId: playbackId,
      visibleText: visibleText?.call(),
    ));
  }
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}

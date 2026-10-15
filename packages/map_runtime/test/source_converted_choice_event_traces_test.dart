import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/dialogue_overlay_component.dart';
import 'package:path/path.dart' as path;

const _namespace = 'original-ac13-evt04-choice-cancel';
const _archiveHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_EVT04_REFERENCE'];
  final evidenceRoot = Platform.environment['AVELUNE_EVT04_EVIDENCE_ROOT'];
  final bool skip = referencePath == null || evidenceRoot == null;
  Map<String, dynamic>? reference;
  Map<String, String>? projectBefore;
  Map<String, String>? sourceBefore;
  String? referenceHash;
  setUpAll(() async {
    if (referencePath == null || evidenceRoot == null) return;
    expect(path.isAbsolute(referencePath), isTrue);
    expect(path.isAbsolute(evidenceRoot), isTrue);
    final raw = _object(jsonDecode(await File(referencePath).readAsString()));
    expect(raw['kind'], 'originalRmxpChoiceCancellationReference');
    expect(raw['version'], 1);
    expect(raw['sourceNamespace'], _namespace);
    expect(raw['sourceScriptsArchiveHash'], _archiveHash);
    expect(raw['published'], isTrue);
    expect(raw['verified'], isTrue);
    expect(raw['sourceUnchanged'], isTrue);
    expect(raw['writerOrigin'], 'converterWorkflow.writeApproved');
    expect(raw['sourceScriptsExecuted'], 0);
    expect(raw['aiCalls'], 0);
    expect(raw['sourceAdmission'], isFalse);
    expect(raw['playableCertified'], isFalse);
    expect(raw['sourceHashesBefore'], raw['sourceHashesAfter']);
    final projection = _projection(raw);
    expect(projection['qualifiedEventCount'], 2);
    expect(projection['quarantinedEventCount'], 0);
    expect(_object(raw['originalCommands'])['1'], _sourceCommands(true));
    expect(_object(raw['originalCommands'])['2'], _sourceCommands(false));
    final native = await _inventory(raw['projectPath'] as String);
    final source = await _inventory(raw['sourceRootPath'] as String);
    expect(native, raw['nativeHashes']);
    expect(source, raw['sourceHashesBefore']);
    expect(
      await Directory(evidenceRoot).exists(),
      isFalse,
      reason: 'Every qualification run must use a fresh evidence directory.',
    );
    await Directory(evidenceRoot).create(recursive: true);
    referenceHash = await _sha(File(referencePath));
    projectBefore = native;
    sourceBefore = source;
    reference = raw;
  });
  tearDownAll(() async {
    final raw = reference;
    if (raw == null) return;
    expect(await _inventory(raw['projectPath'] as String), projectBefore);
    expect(await _inventory(raw['sourceRootPath'] as String), sourceBefore);
    expect(await _sha(File(referencePath!)), referenceHash);
  });

  for (final scenario in const [
    _Scenario('choice_0', 1, 0, 'A', 'Branche A.'),
    _Scenario('choice_1', 1, 1, 'B', 'Branche B.'),
    _Scenario(
      'secondary_cancel',
      1,
      1,
      'C',
      'Annulation distincte.',
      cancel: true,
    ),
    _Scenario('disabled_cancel', 2, 1, 'B', 'Branche B.', disabledCancel: true),
  ]) {
    testWidgets(
      'EVT04 freshly converted ${scenario.name}',
      (tester) async {
        final raw = reference!;
        final caseRoot = Directory(path.join(evidenceRoot!, scenario.name));
        await tester.runAsync(() => caseRoot.create());
        final savePath = path.join(caseRoot.path, 'game_save.json');
        final repository = _DiskSave(savePath);
        final bundle = (await tester.runAsync(
          () => loadRuntimeMapBundle(
            projectFilePath: raw['projectFilePath'] as String,
            mapId: raw['mapId'] as String,
          ),
        ))!;
        expect(bundle.manifest.eventRegistry!.mode, EventSystemMode.v2Only);
        final entityId = _object(raw['entityIds'])[scenario.eventId.toString()];
        final entity = bundle.map.entities.singleWhere((e) => e.id == entityId);
        expect(entity.kind, MapEntityKind.npc);
        expect(entity.blocksMovement, isTrue);
        expect(entity.npc?.characterId, isNotNull);
        final start = GridPos(x: scenario.eventId == 1 ? 1 : 4, y: 2);
        expect(entity.pos, GridPos(x: start.x, y: 1));
        final music = RuntimeMusicService(
          driver: _SilentMusicDriver(),
          fadeDelay: (_) async {},
        );
        final sounds = _SoundTrace();
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: raw['projectFilePath'] as String,
          saveRepository: repository,
          initialGameState: GameState(
            saveId: 'evt04-${scenario.name}',
            currentMapId: bundle.map.id,
            playerPosition: start,
            playerFacing: EntityFacing.north,
          ),
          musicService: music,
          sceneSoundEffectPlaybackPort: sounds,
        );
        final trace = <Map<String, Object?>>[];
        var stage = 'boot';
        var completed = false;
        GameState? saved;
        try {
          await _mount(tester, game);
          expect(game.gameStateSnapshot.playerPosition, start);
          final baseline = game.gameStateSnapshot;
          expect(baseline.narrativeFactRuntimeState.overridesByFactId, isEmpty);
          await _idle(tester, game, 30);
          expect(
            strictGameStateSaveJson(game.gameStateSnapshot),
            strictGameStateSaveJson(baseline),
          );
          stage = 'primary_interaction';
          _press(game, RuntimeInputControl.primary);
          await _line(
            tester,
            game,
            scenario.eventId == 1 ? 'Quelle voie ?' : 'Choix obligatoire.',
          );
          _record(trace, game, stage);
          await _advanceLine(tester, game);
          await _until(
            tester,
            game,
            () =>
                game.dialoguePresentationListenable.value?.mode ==
                DialoguePresentationMode.choices,
          );
          expect(
            game.descendants().whereType<DialogueOverlayComponent>(),
            hasLength(1),
          );
          final initialChoice = game.dialoguePresentationListenable.value!;
          expect(initialChoice.choices.map((c) => c.label).toList(), [
            'Voie A',
            'Voie B',
          ]);
          expect(
            initialChoice.choices.where((c) => c.selected).single.index,
            0,
          );
          expect(
            game.inputAuthoritySnapshot.context,
            RuntimeInputContext.dialogue,
          );
          expect(await tester.runAsync(game.saveGame), isFalse);
          expect(await tester.runAsync(() => File(savePath).exists()), isFalse);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
            isEmpty,
          );
          if (scenario.choiceIndex == 1) {
            _press(game, RuntimeInputControl.down);
          }
          expect(
            game.dialoguePresentationListenable.value!.choices
                .where((c) => c.selected)
                .single
                .index,
            scenario.choiceIndex,
          );
          expect(game.gameStateSnapshot.playerPosition, start);
          stage = 'choice_ready';
          _record(trace, game, stage);
          if (scenario.disabledCancel) {
            final before = game.dialoguePresentationListenable.value!;
            final beforeState = strictGameStateSaveJson(game.gameStateSnapshot);
            _press(game, RuntimeInputControl.secondary);
            await _frames(tester, 45);
            final after = game.dialoguePresentationListenable.value!;
            expect(after.mode, DialoguePresentationMode.choices);
            expect(after.revision, before.revision);
            expect(
              after.choices.map((c) => c.label).toList(),
              before.choices.map((c) => c.label).toList(),
            );
            expect(after.choices.where((c) => c.selected).single.index, 1);
            expect(
              strictGameStateSaveJson(game.gameStateSnapshot),
              beforeState,
            );
            expect(await tester.runAsync(game.saveGame), isFalse);
            expect(
              await tester.runAsync(() => File(savePath).exists()),
              isFalse,
            );
            _record(trace, game, 'secondary_disabled_still_waiting');
          }
          stage = scenario.cancel ? 'secondary_cancel' : 'primary_choice';
          _press(
            game,
            scenario.cancel
                ? RuntimeInputControl.secondary
                : RuntimeInputControl.primary,
          );
          await _line(tester, game, scenario.branchText);
          _record(trace, game, stage);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
            isEmpty,
          );
          await _advanceLine(tester, game);
          stage = 'common_continuation';
          await _line(
            tester,
            game,
            scenario.eventId == 1
                ? 'Continuation commune.'
                : 'Continuation obligatoire.',
          );
          _record(trace, game, stage);
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
            isEmpty,
            reason: 'Scene consequences stay buffered until the common end.',
          );
          expect(await tester.runAsync(game.saveGame), isFalse);
          await _advanceLine(tester, game);
          await _until(tester, game, () => _ready(game));
          final expectedFacts = {
            _fact(raw, scenario.eventId, scenario.factKey): true,
            _fact(raw, scenario.eventId, 'D'): true,
          };
          final factWriter = NarrativeFactRuntimeWriter(
            NarrativeFactRuntimeResolver.fromFacts(bundle.manifest.facts),
          );
          var expected = baseline;
          for (final entry in expectedFacts.entries) {
            final definition = bundle.manifest.facts.singleWhere(
              (fact) => fact.id == entry.key,
            );
            expect(definition.legacyFlagName, isNull);
            final written = factWriter.setFact(
              gameState: expected,
              factId: entry.key,
              value: entry.value,
            );
            expect(written.success, isTrue);
            expected = written.gameState;
          }
          expect(
            expected.narrativeFactRuntimeState.overridesByFactId,
            expectedFacts,
          );
          expect(expected.storyFlags.activeFlags, {
            ...baseline.storyFlags.activeFlags,
            ...expectedFacts.keys,
          });
          final expectedProgressionFlags = [...baseline.progression.storyFlags];
          for (final factId in expectedFacts.keys) {
            if (!expectedProgressionFlags.contains(factId)) {
              expectedProgressionFlags.add(factId);
            }
          }
          expect(expected.progression.storyFlags, expectedProgressionFlags);
          expect(
            strictGameStateSaveJson(game.gameStateSnapshot),
            strictGameStateSaveJson(expected),
            reason: 'Only the chosen branch marker and common continuation may commit.',
          );
          expect(sounds.calls, isEmpty);
          await _idle(tester, game, 90);
          expect(
            strictGameStateSaveJson(game.gameStateSnapshot),
            strictGameStateSaveJson(expected),
          );
          stage = 'disk_save';
          expect(await tester.runAsync(game.saveGame), isTrue);
          final reloaded = await tester.runAsync(
            () => _DiskSave(savePath).load(),
          );
          expect(reloaded, isNotNull);
          expect(
            strictGameStateSaveJson(reloaded!),
            strictGameStateSaveJson(expected),
          );
          saved = reloaded;
          _record(trace, game, stage);
        } finally {
          await _unmount(tester, game, music);
          if (saved == null) {
            await tester.runAsync(
              () => _observations(caseRoot, scenario, stage, false, trace),
            );
          }
        }
        final prior = saved;
        final savedHash = (await tester.runAsync(() => _sha(File(savePath))))!;
        final restoredMusic = RuntimeMusicService(
          driver: _SilentMusicDriver(),
          fadeDelay: (_) async {},
        );
        final restored = PlayableMapGame(
          bundle: bundle,
          projectFilePath: raw['projectFilePath'] as String,
          saveRepository: _DiskSave(savePath),
          initialGameState: prior,
          initialMapActivationReason: MapActivationReason.saveRestore,
          musicService: restoredMusic,
          sceneSoundEffectPlaybackPort: sounds,
        );
        try {
          stage = 'new_game_instance_save_restore';
          await _mount(tester, restored);
          final activation = restored.debugLastCompletedMapActivation!;
          expect(restored.debugCompletedMapActivationDispatchCount, 1);
          expect(activation.reason, MapActivationReason.saveRestore);
          expect(activation.mapId, prior.currentMapId);
          expect(
            activation.activationId,
            matches(RegExp(r'^mapact_[1-9][0-9]*_1$')),
          );
          final oldTokens =
              prior.narrativeEventProgress.appliedNarrativeResetTokens;
          final token = 'map:${activation.activationId}';
          expect(oldTokens, isNot(contains(token)));
          final expected = prior.copyWith(
            narrativeEventProgress: prior.narrativeEventProgress.copyWith(
              appliedNarrativeResetTokens: [...oldTokens, token],
            ),
          );
          expect(
            strictGameStateSaveJson(restored.gameStateSnapshot),
            strictGameStateSaveJson(expected),
          );
          await _idle(tester, restored, 90);
          expect(
            strictGameStateSaveJson(restored.gameStateSnapshot),
            strictGameStateSaveJson(expected),
          );
          expect(await tester.runAsync(() => _sha(File(savePath))), savedHash);
          expect(sounds.calls, isEmpty);
          _record(trace, restored, stage);
          await tester.runAsync(() async {
            expect(
              await _inventory(raw['projectPath'] as String),
              projectBefore,
            );
            expect(
              await _inventory(raw['sourceRootPath'] as String),
              sourceBefore,
            );
            await File(
              path.join(caseRoot.path, 'completed.json'),
            ).writeAsString(
              jsonEncode({
                'kind': 'evt04OriginalChoiceCancellationRuntimeTrace',
                'version': 1,
                'case': scenario.name,
                'completed': true,
                'referenceSha256': referenceHash,
                'processId': pid,
                'usesRealGameWidget': true,
                'usesRuntimeInputEvents': true,
                'directSceneInvocation': false,
                'sourceEventId': scenario.eventId,
                'choiceIndexBeforeAction': scenario.choiceIndex,
                'action': scenario.cancel ? 'secondary' : 'primary',
                'disabledSecondaryPreservedChoice': scenario.disabledCancel,
                'expectedBranchFact': scenario.factKey,
                'stateAfterCompletion': strictGameStateSaveJson(prior),
                'restoredState': strictGameStateSaveJson(
                  restored.gameStateSnapshot,
                ),
                'saveSha256': savedHash,
                'saveRestoredByNewRepositoryAndGameInstance': true,
                'separateOsProcess': false,
                'stateBoundary': 'afterCompletedInteraction',
                'sourceIntermediateFactCommitTimingQualified': false,
                'onlyColdBootDelta': {
                  'path': 'narrativeEventProgress.appliedNarrativeResetTokens',
                  'addedToken': token,
                },
                'nativeInventoryUnchanged': true,
                'sourceInventoryUnchanged': true,
                'sounds': sounds.calls,
                'trace': trace,
                'sourceAdmission': false,
                'guiQualified': false,
                'playableCertified': false,
              }),
              flush: true,
            );
          });
          completed = true;
        } finally {
          await _unmount(tester, restored, restoredMusic);
          await tester.runAsync(
            () => _observations(caseRoot, scenario, stage, completed, trace),
          );
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}

final class _Scenario {
  const _Scenario(
    this.name,
    this.eventId,
    this.choiceIndex,
    this.factKey,
    this.branchText, {
    this.cancel = false,
    this.disabledCancel = false,
  });
  final String name;
  final int eventId;
  final int choiceIndex;
  final String factKey;
  final String branchText;
  final bool cancel;
  final bool disabledCancel;
}

Map<String, dynamic> _object(Object? input) =>
    Map<String, dynamic>.from(input! as Map);

Map<String, dynamic> _projection(Map<String, dynamic> raw) =>
    _object(_object(raw['sourceEvents'])['projection']);

String _fact(Map<String, dynamic> raw, int eventId, String key) =>
    _object(
          _projection(raw)['factBindings'],
        )['source:$_namespace:map:1:event:$eventId:self:$key']
        as String;

List<Map<String, Object?>> _sourceCommands(bool cancellable) => [
  {
    'code': 101,
    'indent': 0,
    'parameters': [cancellable ? 'Quelle voie ?' : 'Choix obligatoire.'],
  },
  {
    'code': 102,
    'indent': 0,
    'parameters': [
      ['Voie A', 'Voie B'],
      cancellable ? 5 : 0,
    ],
  },
  {
    'code': 402,
    'indent': 0,
    'parameters': [0, 'Voie A'],
  },
  {
    'code': 101,
    'indent': 1,
    'parameters': ['Branche A.'],
  },
  {
    'code': 123,
    'indent': 1,
    'parameters': ['A', 0],
  },
  {
    'code': 402,
    'indent': 0,
    'parameters': [1, 'Voie B'],
  },
  {
    'code': 101,
    'indent': 1,
    'parameters': ['Branche B.'],
  },
  {
    'code': 123,
    'indent': 1,
    'parameters': ['B', 0],
  },
  if (cancellable) ...[
    {'code': 403, 'indent': 0, 'parameters': []},
    {
      'code': 101,
      'indent': 1,
      'parameters': ['Annulation distincte.'],
    },
    {
      'code': 123,
      'indent': 1,
      'parameters': ['C', 0],
    },
  ],
  {'code': 404, 'indent': 0, 'parameters': []},
  {
    'code': 101,
    'indent': 0,
    'parameters': [
      cancellable ? 'Continuation commune.' : 'Continuation obligatoire.',
    ],
  },
  {
    'code': 123,
    'indent': 0,
    'parameters': ['D', 0],
  },
];

Future<String> _sha(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

Future<Map<String, String>> _inventory(String root) async {
  final hashes = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    expect(entry, isNot(isA<Link>()));
    if (entry is File) {
      hashes[path.relative(entry.path, from: root)] = await _sha(entry);
    }
  }
  final names = hashes.keys.toList()..sort();
  return {for (final name in names) name: hashes[name]!};
}

bool _ready(PlayableMapGame game) =>
    game.isLoaded &&
    !game.debugIsGameplayInputLocked &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    game.dialoguePresentationListenable.value == null &&
    game.inputAuthoritySnapshot.acceptsOverworldInput;

Future<void> _pump(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}

Future<void> _frames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await _pump(tester);
  }
}

Future<void> _until(
  WidgetTester tester,
  PlayableMapGame game,
  bool Function() predicate,
) async {
  for (var frame = 0; frame < 1800; frame++) {
    if (predicate()) return;
    await _pump(tester);
  }
  fail(
    'Runtime did not settle: ${jsonEncode({'flow': game.debugFlowPhaseName, 'input': game.inputAuthoritySnapshot.context.name, 'dialogueMode': game.dialoguePresentationListenable.value?.mode.name, 'dialogueText': game.dialoguePresentationListenable.value?.fullText, 'pendingScene': game.debugIsNarrativeSpatialDispatchInFlight})}',
  );
}

Future<void> _mount(WidgetTester tester, PlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<PlayableMapGame>(game: game),
    ),
  );
  await _until(tester, game, () => game.isLoaded);
  await tester.runAsync(() async => await game.toBeLoaded());
  await _until(tester, game, () => _ready(game));
}

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<void> _line(
  WidgetTester tester,
  PlayableMapGame game,
  String text,
) async {
  await _until(tester, game, () {
    final current = game.dialoguePresentationListenable.value;
    return current?.mode == DialoguePresentationMode.line &&
        current?.fullText == text;
  });
  expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.dialogue);
  expect(
    game.descendants().whereType<DialogueOverlayComponent>(),
    hasLength(1),
  );
}

Future<void> _advanceLine(WidgetTester tester, PlayableMapGame game) async {
  final current = game.dialoguePresentationListenable.value!;
  expect(current.mode, DialoguePresentationMode.line);
  if (!current.isCurrentLineFullyRevealed) {
    _press(game, RuntimeInputControl.primary);
    expect(
      game.dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
      isTrue,
    );
  }
  _press(game, RuntimeInputControl.primary);
  await _pump(tester);
}

Future<void> _idle(WidgetTester tester, PlayableMapGame game, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await _pump(tester);
    expect(_ready(game), isTrue);
  }
}

void _record(
  List<Map<String, Object?>> trace,
  PlayableMapGame game,
  String stage,
) {
  final current = game.dialoguePresentationListenable.value;
  trace.add({
    'stage': stage,
    'flow': game.debugFlowPhaseName,
    'mode': current?.mode.name,
    'text': current?.fullText,
    'choices': [
      for (final choice in current?.choices ?? <DialoguePresentationChoice>[])
        {
          'index': choice.index,
          'label': choice.label,
          'selected': choice.selected,
        },
    ],
    'state': strictGameStateSaveJson(game.gameStateSnapshot),
  });
}

Future<void> _unmount(
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

Future<void> _observations(
  Directory root,
  _Scenario scenario,
  String stage,
  bool completed,
  List<Map<String, Object?>> trace,
) async {
  await File(path.join(root.path, 'observations.json')).writeAsString(
    jsonEncode({
      'case': scenario.name,
      'stage': stage,
      'completed': completed,
      'trace': trace,
      'sourceAdmission': false,
    }),
    flush: true,
  );
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;
  @override
  Future<String> getSaveFilePath() async {
    await File(filePath).parent.create(recursive: true);
    return filePath;
  }
}

final class _SilentMusicDriver implements FlameCinematicAudioDriver {
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

final class _SoundTrace implements SceneSoundEffectPlaybackPort {
  final calls = <Map<String, Object?>>[];
  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    calls.add({
      'mediaAssetId': mediaAssetId,
      'volume': volume,
      'playbackId': playbackId,
    });
  }
}

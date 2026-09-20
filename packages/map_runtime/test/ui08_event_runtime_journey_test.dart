import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/ui08_event_runtime_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UI08 mapEnter activation plays the Scene and emits its real outcome',
      () async {
    final root = await Directory.systemTemp.createTemp('ui08_map_enter_');
    addTearDown(() => root.delete(recursive: true));
    final bundle = await createUi08RuntimeFixture(
      root,
      NarrativeEventReusePolicy.oneShot,
      source: NarrativeEventSourceRef.mapEnter(ui08MapId),
    );
    final game = _LoadedGame(
      bundle: bundle,
      projectFilePath: '${root.path}/project.json',
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await _until(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isEmpty);
    _advanceDialogue(game);
    await _until(
        game,
        () =>
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds
                .contains(ui08ReceiverEvent) &&
            !game.debugIsMapActivationDispatchInFlight &&
            _idle(game));
    expect(game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.initialBoot);
    expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        containsAll([ui08ProducerEvent, ui08ReceiverEvent]));
    expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId[ui08ReceivedFact],
        isTrue);
    expect(
        game.gameStateSnapshot.narrativeEventProgress
            .deliveredNarrativeOutcomeDeliveryIds,
        hasLength(1));
  });

  for (final policy in NarrativeEventReusePolicy.values) {
    test(
        'UI08 ${policy.name}: real interaction, Yarn, qualified outcome, '
        'consumption and second passage', () async {
      final root = await Directory.systemTemp.createTemp('ui08_runtime_');
      addTearDown(() => root.delete(recursive: true));
      final bundle = await createUi08RuntimeFixture(root, policy);
      final before = {
        for (final name in ['project.json', 'maps/station.json'])
          name: await File('${root.path}/$name').readAsString(),
      };
      final occurrences = <NarrativeEventOccurrence>[];
      final game = _LoadedGame(
        bundle: bundle,
        projectFilePath: '${root.path}/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          occurrences.add(occurrence);
        },
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
      expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
      final action = game.overworldInteractionSnapshot.primaryAction!;
      expect(action.request.targetId, ui08EntityId);
      expect(game.dispatchOverworldInteraction(action.request), isTrue);
      await _until(game, () => game.debugFlowPhaseName == 'dialogue');
      expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
      expect(
          occurrences.where((value) =>
              value.source.kind == NarrativeEventSourceKind.outcomeReceived),
          isEmpty);

      _advanceDialogue(game);
      await _until(
          game,
          () =>
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds
                  .contains(ui08ReceiverEvent) &&
              _idle(game));
      final first = game.gameStateSnapshot;
      expect(
          first.narrativeFactRuntimeState.overridesByFactId[ui08ReceivedFact],
          isTrue);
      expect(first.narrativeEventProgress.consumedNarrativeEventIds,
          isNot(contains(ui08WrongProducerEvent)));
      expect(
          first.narrativeEventProgress.consumedNarrativeEventIds
              .contains(ui08ProducerEvent),
          policy == NarrativeEventReusePolicy.oneShot);
      expect(first.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          hasLength(1));
      expect(first.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
          isEmpty);
      final emitted = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: ui08ProducerScene,
          outcomeId: 'meeting.completed',
        ),
      );
      expect(
          occurrences.where((value) => value.source == emitted), hasLength(1));

      if (policy == NarrativeEventReusePolicy.oneShot) {
        expect(game.overworldInteractionSnapshot.primaryAction, isNull);
        expect(game.dispatchOverworldInteraction(action.request), isFalse);
        expect(
            game.handleRuntimeInputEvent(
                const RuntimeInputEvent.press(RuntimeInputControl.primary)),
            isTrue);
        await _until(game, () => _idle(game));
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugHasPendingDialogueLoad, isFalse);
        expect(
            game.gameStateSnapshot.narrativeEventProgress
                .deliveredNarrativeOutcomeDeliveryIds,
            hasLength(1));
      } else {
        final second = game.overworldInteractionSnapshot.primaryAction!;
        expect(game.dispatchOverworldInteraction(second.request), isTrue);
        await _until(game, () => game.debugFlowPhaseName == 'dialogue');
        _advanceDialogue(game);
        await _until(
            game,
            () =>
                game.gameStateSnapshot.narrativeEventProgress
                        .deliveredNarrativeOutcomeDeliveryIds.length ==
                    2 &&
                _idle(game));
        expect(occurrences.where((value) => value.source == emitted),
            hasLength(2));
        expect(
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds,
            [ui08ReceiverEvent]);
      }
      for (final entry in before.entries) {
        expect(await File('${root.path}/${entry.key}').readAsString(),
            entry.value);
      }
    });
  }
}

bool _idle(PlayableMapGame game) =>
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight;

void _advanceDialogue(PlayableMapGame game) {
  expect(
      game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary)),
      isTrue);
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 1000; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('UI08 runtime timeout: ${game.debugFlowPhaseName}, '
      'events=${game.gameStateSnapshot.narrativeEventProgress.toJson()}');
}

final class _LoadedGame extends PlayableMapGame {
  _LoadedGame(
      {required super.bundle,
      required super.projectFilePath,
      super.beforeNarrativeAuthorityPreparation});

  @override
  bool get isLoaded => true;
}

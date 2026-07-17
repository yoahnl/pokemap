import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('J3 Selbrume sources through PlayableMapGame production hooks', () {
    for (final fixture in <SelbrumeEventV2RuntimeFixture>[
      SelbrumeEventV2RuntimeFixture.locate(),
      SelbrumeEventV2RuntimeFixture.locatePromoted(),
    ]) {
      for (final target in const <_EntityTarget>[
        _EntityTarget(
          label: 'Lysa NPC',
          mapId: selbrumePortMapId,
          entityId: selbrumeLysaEntityId,
          eventId: selbrumeLysaEventId,
          sceneId: selbrumeLysaSceneId,
          playerPos: GridPos(x: 26, y: 17),
          facing: EntityFacing.north,
          completesImmediately: false,
        ),
        _EntityTarget(
          label: 'glass clue object',
          mapId: selbrumeMarshMapId,
          entityId: selbrumeClueEntityId,
          eventId: selbrumeClueEventId,
          sceneId: selbrumeClueSceneId,
          playerPos: GridPos(x: 8, y: 33),
          facing: EntityFacing.north,
          completesImmediately: true,
        ),
      ]) {
        test(
            '${fixture.label}: ${target.label} dispatches its authored Scene once',
            () async {
          final source = NarrativeEventSourceRef.entityInteract(
            target.mapId,
            target.entityId,
          );
          final prepared = <NarrativeEventSourceRef>[];
          final decisions = <NarrativeEventDispatchDecision>[];
          final bundle = await fixture.loadHarnessBundle(
            mapId: target.mapId,
            playerPos: target.playerPos,
            facing: target.facing,
          );
          final authoredRecord =
              bundle.manifest.eventRegistry!.records.singleWhere(
            (record) => record.definitionOrNull?.source == source,
          );
          expect(
            authoredRecord.definitionOrNull?.sceneId,
            target.sceneId,
          );
          late _TestPlayableMapGame game;
          game = _TestPlayableMapGame(
            bundle: bundle,
            projectFilePath: fixture.projectPath,
            beforeNarrativeAuthorityPreparation: (occurrence) async {
              if (occurrence.source == source) prepared.add(occurrence.source);
            },
            afterNarrativeAuthorityPreparation:
                (occurrence, preparation) async {
              if (occurrence.source == source &&
                  preparation is NarrativeEventDispatchAuthorityReady) {
                decisions.add(
                  preparation.plan(gameState: game.gameStateSnapshot),
                );
              }
            },
          );

          await _load(game);
          expect(game.debugPlayerGridPosition, target.playerPos);
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          await _pumpUntil(game, () => prepared.isNotEmpty);
          if (target.completesImmediately) {
            await _pumpUntil(
              game,
              () => game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds
                  .contains(target.eventId),
            );
          }

          expect(prepared, <NarrativeEventSourceRef>[source]);
          expect(decisions.single, isA<NarrativeEventDispatchHandled>());
          expect(
            (decisions.single as NarrativeEventDispatchHandled).sceneId,
            target.sceneId,
          );
          if (target.completesImmediately) {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              contains(target.eventId),
            );
            expect(
              game.handleRuntimeInputEvent(
                const RuntimeInputEvent.press(RuntimeInputControl.primary),
              ),
              isTrue,
            );
            await _pumpTicks(game, 30);
            expect(
              prepared,
              <NarrativeEventSourceRef>[source, source],
            );
            expect(decisions, hasLength(2));
            final ineligible = decisions.last;
            expect(ineligible, isNot(isA<NarrativeEventDispatchHandled>()));
            expect(
              _reasons(ineligible),
              contains(NarrativeEventDispatchReason.eventConsumed),
              reason: 'A consumed one-shot source must be ineligible.',
            );
          } else {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              isNot(contains(target.eventId)),
              reason: 'Lysa remains in-flight until the host closes Yarn.',
            );
            expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
          }
        });
      }

      test('${fixture.label}: port entry dispatches from a real movement front',
          () async {
        final source = NarrativeEventSourceRef.triggerEnter(
          selbrumePortMapId,
          selbrumePortEntryTriggerId,
        );
        final prepared = <NarrativeEventSourceRef>[];
        final decisions = <NarrativeEventDispatchDecision>[];
        final bundle = await fixture.loadHarnessBundle(
          mapId: selbrumePortMapId,
          playerPos: const GridPos(x: 25, y: 1),
          facing: EntityFacing.east,
        );
        final authoredRecord =
            bundle.manifest.eventRegistry!.records.singleWhere(
          (record) => record.definitionOrNull?.source == source,
        );
        expect(
          authoredRecord.definitionOrNull?.sceneId,
          selbrumePortEntrySceneId,
        );
        late _TestPlayableMapGame game;
        game = _TestPlayableMapGame(
          bundle: bundle,
          projectFilePath: fixture.projectPath,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source == source) prepared.add(occurrence.source);
          },
          afterNarrativeAuthorityPreparation: (occurrence, preparation) async {
            if (occurrence.source == source &&
                preparation is NarrativeEventDispatchAuthorityReady) {
              decisions.add(
                preparation.plan(gameState: game.gameStateSnapshot),
              );
            }
          },
        );

        await _load(game);
        expect(prepared, isEmpty,
            reason: 'Spawn outside must not be an entry.');
        await _runSingleMove(game, RuntimeInputControl.right);
        await _pumpUntil(
          game,
          () => game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .contains(selbrumePortEntryEventId),
        );

        expect(game.debugPlayerGridPosition, const GridPos(x: 26, y: 1));
        expect(prepared, <NarrativeEventSourceRef>[source]);
        expect(decisions.single, isA<NarrativeEventDispatchHandled>());
        expect(
          (decisions.single as NarrativeEventDispatchHandled).sceneId,
          selbrumePortEntrySceneId,
        );

        await _runSingleMove(game, RuntimeInputControl.left);
        await _runSingleMove(game, RuntimeInputControl.right);
        await _pumpTicks(game, 30);
        expect(
          prepared,
          <NarrativeEventSourceRef>[source, source],
        );
        expect(decisions, hasLength(2));
        final ineligible = decisions.last;
        expect(ineligible, isNot(isA<NarrativeEventDispatchHandled>()));
        expect(
          _reasons(ineligible),
          contains(NarrativeEventDispatchReason.eventConsumed),
          reason: 'Re-entering a consumed one-shot trigger must be ineligible.',
        );
      });
    }
  });
}

List<NarrativeEventDispatchReason> _reasons(
  NarrativeEventDispatchDecision decision,
) {
  return switch (decision) {
    NarrativeEventDispatchClaimedButIneligible(:final reasons) => reasons,
    NarrativeEventDispatchNoMatch(:final reasons) => reasons,
    NarrativeEventDispatchHandled() => const <NarrativeEventDispatchReason>[],
  };
}

Future<void> _pumpTicks(PlayableMapGame game, int ticks) async {
  for (var index = 0; index < ticks; index++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  for (var index = 0; index < 180; index++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (!game.debugIsPlayerStepping) return;
  }
  fail('Timed out waiting for the Selbrume movement step.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 2000,
}) async {
  for (var index = 0; index < maxTicks; index++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out waiting for the Selbrume Event V2 runtime dispatch.');
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.beforeNarrativeAuthorityPreparation,
    super.afterNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _EntityTarget {
  const _EntityTarget({
    required this.label,
    required this.mapId,
    required this.entityId,
    required this.eventId,
    required this.sceneId,
    required this.playerPos,
    required this.facing,
    required this.completesImmediately,
  });

  final String label;
  final String mapId;
  final String entityId;
  final String eventId;
  final String sceneId;
  final GridPos playerPos;
  final EntityFacing facing;
  final bool completesImmediately;
}

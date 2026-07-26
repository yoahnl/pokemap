import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

const _clueGlassFactId = 'fact_clue_glass_found';
const _portAlertFactId = 'fact_port_alert_seen';
const _portStepId = 'step_go_to_port';
// Real bundle/image loading and movement scheduling need timers and I/O turns;
// a zero-duration microtask loop starves the canonical Port dispatch. The
// waits below remain state-driven and bounded, with this minimal event-loop
// yield only between simulated runtime ticks.
const _asyncRuntimeYield = Duration(milliseconds: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('J3 Selbrume sources through PlayableMapGame production hooks', () {
    test('canonical Lysa cohort has two deterministic authority keys',
        () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final bundle = await fixture.loadHarnessBundle(
        mapId: selbrumePortMapId,
        playerPos: const GridPos(x: 26, y: 17),
        facing: EntityFacing.north,
      );
      final source = NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      );
      final index = buildNarrativeEventSourceIndex(
        bundle.manifest.eventRegistry!.records,
      );
      final lysaRecords = index.index.recordsFor(source);

      expect(index.conflicts.where((conflict) => conflict.source == source),
          isEmpty);
      expect(
        lysaRecords.map((record) => record.id),
        <String>[selbrumeLysaRematchEventId, selbrumeLysaEventId],
        reason: 'Runtime authority orders priority DESC then order ASC.',
      );
      expect(
        lysaRecords
            .singleWhere(
              (record) =>
                  record.definitionOrNull?.priority == 0 &&
                  record.definitionOrNull?.order == 0,
            )
            .id,
        selbrumeLysaEventId,
      );
      expect(
        lysaRecords
            .singleWhere(
              (record) =>
                  record.definitionOrNull?.priority == 1 &&
                  record.definitionOrNull?.order == 5,
            )
            .id,
        selbrumeLysaRematchEventId,
      );
    });

    test('canonical Lysa one-shot stays consumed after a save reload',
        () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      const playerPos = GridPos(x: 26, y: 17);
      const facing = EntityFacing.north;
      final source = NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      );
      final bundle = await fixture.loadHarnessBundle(
        mapId: selbrumePortMapId,
        playerPos: playerPos,
        facing: facing,
      );
      final serialized = saveDataFromGameState(
        GameState(
          saveId: 'sel_fin_00_lysa_reload',
          currentMapId: selbrumePortMapId,
          playerPosition: playerPos,
          playerFacing: facing,
          narrativeEventProgress: NarrativeEventProgress(
            consumedNarrativeEventIds: const <String>{
              selbrumeLysaEventId,
            },
          ),
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: const <String, bool>{
              'fact_port_alert_seen': true,
            },
          ),
        ),
      ).toJson();
      final reloadedSave = SaveData.fromJson(serialized);
      final decisions = <NarrativeEventDispatchDecision>[];
      late _TestPlayableMapGame game;
      game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveData: reloadedSave,
        initialMapActivationReason: MapActivationReason.saveRestore,
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
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(selbrumeLysaEventId),
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(game, () => decisions.isNotEmpty);

      expect(decisions.single, isNot(isA<NarrativeEventDispatchHandled>()));
      expect(
        _reasons(decisions.single),
        contains(NarrativeEventDispatchReason.eventConsumed),
      );
      expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
    });

    for (final fixture in <SelbrumeEventV2RuntimeFixture>[
      SelbrumeEventV2RuntimeFixture.locate(),
      SelbrumeEventV2RuntimeFixture.locateCanonical(),
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
          canonicalPrerequisiteFactId: 'fact_port_alert_seen',
        ),
        _EntityTarget(
          label: 'glass clue object',
          mapId: selbrumeMarshMapId,
          entityId: selbrumeClueEntityId,
          eventId: selbrumeClueEventId,
          sceneId: selbrumeClueSceneId,
          playerPos: GridPos(x: 8, y: 33),
          facing: EntityFacing.north,
          terminalFactId: _clueGlassFactId,
          canonicalPrerequisiteFactId: 'fact_mado_met',
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
          final sourceRecords = buildNarrativeEventSourceIndex(
            bundle.manifest.eventRegistry!.records,
          ).index.recordsFor(source);
          final authoredById = sourceRecords.singleWhere(
            (record) => record.id == target.eventId,
          );
          final authoredDefinition = authoredById.definitionOrNull!;
          final authoredRecord = sourceRecords.singleWhere(
            (record) =>
                record.definitionOrNull?.priority ==
                    authoredDefinition.priority &&
                record.definitionOrNull?.order == authoredDefinition.order,
          );
          expect(authoredRecord.id, target.eventId);
          expect(authoredRecord.definitionOrNull?.source, source);
          expect(
            authoredRecord.definitionOrNull?.sceneId,
            target.sceneId,
          );
          late _TestPlayableMapGame game;
          game = _TestPlayableMapGame(
            bundle: bundle,
            projectFilePath: fixture.projectPath,
            saveData: fixture.isCanonicalProject
                ? _canonicalSaveData(
                    mapId: target.mapId,
                    playerPos: target.playerPos,
                    facing: target.facing,
                    prerequisiteFactId: target.canonicalPrerequisiteFactId!,
                  )
                : null,
            initialMapActivationReason: fixture.isCanonicalProject
                ? MapActivationReason.saveRestore
                : MapActivationReason.initialBoot,
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
          final closesCanonicalDialogue =
              fixture.isCanonicalProject && target.terminalFactId != null;
          if (target.terminalFactId == null || closesCanonicalDialogue) {
            await _pumpUntil(
              game,
              () => game.debugFlowPhaseName == 'dialogue',
            );
          }
          if (closesCanonicalDialogue) {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              isNot(contains(target.eventId)),
              reason: 'A one-shot Event must not be consumed while Yarn is '
                  'still open.',
            );
            expect(
              game.gameStateSnapshot.narrativeFactRuntimeState
                  .overridesByFactId[target.terminalFactId],
              isNot(isTrue),
              reason: 'Scene consequences run only after Yarn closes.',
            );
            expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
            await _completeOpenDialogue(game);
          }
          if (target.terminalFactId != null) {
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
          if (target.terminalFactId != null) {
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              contains(target.eventId),
            );
            if (closesCanonicalDialogue) {
              expect(
                game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[target.terminalFactId],
                isTrue,
                reason: 'The clue consequence must commit after Yarn closes.',
              );
            }
            expect(
              game.handleRuntimeInputEvent(
                const RuntimeInputEvent.press(RuntimeInputControl.primary),
              ),
              isTrue,
            );
            if (closesCanonicalDialogue) {
              for (var index = 0; index < 10; index++) {
                game.update(0.016);
                await Future<void>.delayed(_asyncRuntimeYield);
              }
              expect(prepared, <NarrativeEventSourceRef>[source]);
              expect(decisions, hasLength(1));
              expect(
                const RuntimeWorldRuleProjectionHook()
                    .resolve(
                      project: bundle.manifest,
                      gameState: game.gameStateSnapshot,
                      map: bundle.map,
                    )
                    .hiddenEntityIds,
                contains(target.entityId),
                reason: 'The canonical collected clue is removed from the '
                    'world before a second interaction can dispatch.',
              );
            } else {
              await _pumpUntil(game, () => decisions.length == 2);
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
            }
          } else {
            expect(game.debugFlowPhaseName, 'dialogue');
            expect(
              game.gameStateSnapshot.narrativeEventProgress
                  .consumedNarrativeEventIds,
              isNot(contains(target.eventId)),
              reason: 'SEL-FIN-00 proves NPC dispatch and Yarn opening only; '
                  'Lysa remains in-flight until the future combat E2E lot '
                  'closes Yarn and resolves battle.',
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
        final sourceRecords = buildNarrativeEventSourceIndex(
          bundle.manifest.eventRegistry!.records,
        ).index.recordsFor(source);
        final authoredById = sourceRecords.singleWhere(
          (record) => record.id == selbrumePortEntryEventId,
        );
        final authoredDefinition = authoredById.definitionOrNull!;
        final authoredRecord = sourceRecords.singleWhere(
          (record) =>
              record.definitionOrNull?.priority ==
                  authoredDefinition.priority &&
              record.definitionOrNull?.order == authoredDefinition.order,
        );
        expect(authoredRecord.id, selbrumePortEntryEventId);
        expect(authoredRecord.definitionOrNull?.source, source);
        expect(
          authoredRecord.definitionOrNull?.sceneId,
          selbrumePortEntrySceneId,
        );
        late _TestPlayableMapGame game;
        game = _TestPlayableMapGame(
          bundle: bundle,
          projectFilePath: fixture.projectPath,
          saveData: fixture.isCanonicalProject
              ? _canonicalSaveData(
                  mapId: selbrumePortMapId,
                  playerPos: const GridPos(x: 25, y: 1),
                  facing: EntityFacing.east,
                  prerequisiteFactId: 'fact_mael_mission_given',
                )
              : null,
          initialMapActivationReason: fixture.isCanonicalProject
              ? MapActivationReason.saveRestore
              : MapActivationReason.initialBoot,
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
        await _pumpUntil(game, () => prepared.isNotEmpty);
        final closesCanonicalDialogue = fixture.isCanonicalProject;
        if (closesCanonicalDialogue) {
          await _pumpUntil(
            game,
            () => game.debugFlowPhaseName == 'dialogue',
          );
          expect(
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds,
            isNot(contains(selbrumePortEntryEventId)),
            reason: 'PortAlert remains in-flight until Yarn closes.',
          );
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_portAlertFactId],
            isNot(isTrue),
            reason: 'Port alert state must not commit before Yarn closes.',
          );
          expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
          await _completeOpenDialogue(game);
        }
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
        if (closesCanonicalDialogue) {
          expect(
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[_portAlertFactId],
            isTrue,
            reason: 'Port alert state must commit after Yarn closes.',
          );
          expect(
            game.gameStateSnapshot.progression.completedStepIds,
            contains(_portStepId),
            reason: 'SEL-FIN-00 gates lifecycle closure only; mutually '
                'exclusive crowd-choice Facts belong to SEL-FIN-02.',
          );
        }

        await _runSingleMove(game, RuntimeInputControl.left);
        await _runSingleMove(game, RuntimeInputControl.right);
        await _pumpUntil(game, () => decisions.length == 2);
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

Future<void> _completeOpenDialogue(PlayableMapGame game) async {
  expect(game.debugFlowPhaseName, 'dialogue');
  // Advance actual Yarn states (lines, default choice, jumps) until the host
  // reports closure. The explicit bound is a guard against a stuck dialogue,
  // not a wall-clock wait that could conceal a lifecycle regression.
  for (var advanceCount = 0; advanceCount < 20; advanceCount++) {
    if (game.debugFlowPhaseName != 'dialogue') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Yarn stayed open after 20 explicit primary inputs.');
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
    await Future<void>.delayed(_asyncRuntimeYield);
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
    await Future<void>.delayed(_asyncRuntimeYield);
  }
  fail('Timed out waiting for the Selbrume Event V2 runtime dispatch.');
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.initialMapActivationReason,
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
    this.terminalFactId,
    this.canonicalPrerequisiteFactId,
  });

  final String label;
  final String mapId;
  final String entityId;
  final String eventId;
  final String sceneId;
  final GridPos playerPos;
  final EntityFacing facing;
  final String? terminalFactId;
  final String? canonicalPrerequisiteFactId;
}

SaveData _canonicalSaveData({
  required String mapId,
  required GridPos playerPos,
  required EntityFacing facing,
  required String prerequisiteFactId,
}) =>
    saveDataFromGameState(
      GameState(
        saveId: 'sel_fin_00_$mapId',
        currentMapId: mapId,
        playerPosition: playerPos,
        playerFacing: facing,
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: <String, bool>{
            prerequisiteFactId: true,
          },
        ),
      ),
    );

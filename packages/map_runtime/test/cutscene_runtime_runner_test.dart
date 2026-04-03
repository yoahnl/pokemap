import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CutsceneRuntimeRunner', () {
    test('idle -> running -> completed for simple dialogue cutscene', () {
      final openedDialogues = <String>[];
      final runner = CutsceneRuntimeRunner(
        context: CutsceneRuntimeContext(
          openDialogue: (dialogueId, {startNode}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          moveNpcTo: ({required entityId, required destination}) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: destination,
            );
          },
          readNpcMovementStatus: (entityId) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: const GridPos(x: 0, y: 0),
            );
          },
          faceNpc: ({required entityId, required facing}) => true,
          emitOutcome: (_) {},
          setFlag: (_) {},
          clearFlag: (_) {},
        ),
      );

      expect(runner.status.state, CutsceneRunnerState.idle);
      final started = runner.start(
        const RuntimeCutsceneAsset(
          id: 'intro',
          name: 'Intro',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'intro_dialogue'),
          ],
        ),
      );
      expect(started, isTrue);
      expect(runner.status.state, CutsceneRunnerState.running);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(openedDialogues, <String>['intro_dialogue']);
    });

    test('moveNpcTo waits until movement completed before advancing', () {
      final statuses = <ScriptedEntityMovementStatus>[
        const ScriptedEntityMovementStatus(
          entityId: 'npc_1',
          state: ScriptedEntityMovementState.moving,
          currentPos: GridPos(x: 1, y: 1),
          targetPos: GridPos(x: 3, y: 1),
        ),
        const ScriptedEntityMovementStatus(
          entityId: 'npc_1',
          state: ScriptedEntityMovementState.completed,
          currentPos: GridPos(x: 3, y: 1),
          targetPos: GridPos(x: 3, y: 1),
        ),
      ];
      var readCount = 0;
      final openedDialogues = <String>[];

      final runner = CutsceneRuntimeRunner(
        context: CutsceneRuntimeContext(
          openDialogue: (dialogueId, {startNode}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          moveNpcTo: ({required entityId, required destination}) {
            return const ScriptedEntityMovementStatus(
              entityId: 'npc_1',
              state: ScriptedEntityMovementState.moving,
              currentPos: GridPos(x: 1, y: 1),
              targetPos: GridPos(x: 3, y: 1),
            );
          },
          readNpcMovementStatus: (entityId) {
            final index = readCount.clamp(0, statuses.length - 1);
            final status = statuses[index];
            readCount += 1;
            return status;
          },
          faceNpc: ({required entityId, required facing}) => true,
          emitOutcome: (_) {},
          setFlag: (_) {},
          clearFlag: (_) {},
        ),
      );

      runner.start(
        const RuntimeCutsceneAsset(
          id: 'move_then_dialogue',
          name: 'Move then dialogue',
          steps: <RuntimeCutsceneStep>[
            CutsceneMoveNpcToStep(
              entityId: 'npc_1',
              destination: GridPos(x: 3, y: 1),
            ),
            CutsceneDialogueStep(dialogueId: 'after_move'),
          ],
        ),
      );

      // Tick 1: démarre le move.
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.running);
      expect(runner.status.activeStepIndex, 0);
      expect(openedDialogues, isEmpty);

      // Tick 2: status moving -> reste sur step 0.
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.running);
      expect(runner.status.activeStepIndex, 0);
      expect(openedDialogues, isEmpty);

      // Tick 3: status completed -> passe au step 1.
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.running);
      expect(runner.status.activeStepIndex, 1);

      // Tick 4: exécute dialogue et termine.
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(openedDialogues, <String>['after_move']);
    });

    test('wait step holds progression until duration elapsed', () {
      final openedDialogues = <String>[];
      final runner = CutsceneRuntimeRunner(
        context: CutsceneRuntimeContext(
          openDialogue: (dialogueId, {startNode}) {
            openedDialogues.add(dialogueId);
            return true;
          },
          moveNpcTo: ({required entityId, required destination}) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: destination,
            );
          },
          readNpcMovementStatus: (entityId) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: const GridPos(x: 0, y: 0),
            );
          },
          faceNpc: ({required entityId, required facing}) => true,
          emitOutcome: (_) {},
          setFlag: (_) {},
          clearFlag: (_) {},
        ),
      );

      runner.start(
        const RuntimeCutsceneAsset(
          id: 'wait_then_dialogue',
          name: 'Wait then dialogue',
          steps: <RuntimeCutsceneStep>[
            CutsceneWaitStep(durationMs: 200),
            CutsceneDialogueStep(dialogueId: 'after_wait'),
          ],
        ),
      );

      runner.update(0.05); // 50ms
      expect(runner.status.state, CutsceneRunnerState.running);
      expect(runner.status.activeStepIndex, 0);
      expect(openedDialogues, isEmpty);

      runner.update(0.10); // +100ms => total 150ms
      expect(runner.status.activeStepIndex, 0);
      expect(openedDialogues, isEmpty);

      runner.update(0.06); // +60ms => total 210ms, passe à step 1
      expect(runner.status.activeStepIndex, 1);
      expect(openedDialogues, isEmpty);

      runner.update(0.016); // exécute step dialogue
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(openedDialogues, <String>['after_wait']);
    });

    test('setFlag / clearFlag / emitOutcome are executed in order', () {
      final setFlags = <String>[];
      final clearedFlags = <String>[];
      final emittedOutcomes = <String>[];

      final runner = CutsceneRuntimeRunner(
        context: CutsceneRuntimeContext(
          openDialogue: (dialogueId, {startNode}) => true,
          moveNpcTo: ({required entityId, required destination}) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: destination,
            );
          },
          readNpcMovementStatus: (entityId) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: const GridPos(x: 0, y: 0),
            );
          },
          faceNpc: ({required entityId, required facing}) => true,
          emitOutcome: emittedOutcomes.add,
          setFlag: setFlags.add,
          clearFlag: clearedFlags.add,
        ),
      );

      runner.start(
        const RuntimeCutsceneAsset(
          id: 'flags_outcomes',
          name: 'Flags + outcomes',
          steps: <RuntimeCutsceneStep>[
            CutsceneSetFlagStep(flagName: 'story.intro_started'),
            CutsceneEmitOutcomeStep(outcomeId: 'intro.completed'),
            CutsceneClearFlagStep(flagName: 'story.intro_started'),
          ],
        ),
      );

      runner.update(0.016);
      runner.update(0.016);
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(setFlags, <String>['story.intro_started']);
      expect(emittedOutcomes, <String>['intro.completed']);
      expect(clearedFlags, <String>['story.intro_started']);
    });

    test('fails explicitly on invalid step payload', () {
      final runner = CutsceneRuntimeRunner(
        context: CutsceneRuntimeContext(
          openDialogue: (dialogueId, {startNode}) => true,
          moveNpcTo: ({required entityId, required destination}) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: destination,
            );
          },
          readNpcMovementStatus: (entityId) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: const GridPos(x: 0, y: 0),
            );
          },
          faceNpc: ({required entityId, required facing}) => true,
          emitOutcome: (_) {},
          setFlag: (_) {},
          clearFlag: (_) {},
        ),
      );

      runner.start(
        const RuntimeCutsceneAsset(
          id: 'invalid',
          name: 'Invalid',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: ''),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('empty dialogueId'));
    });
  });
}

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CutsceneRuntimeRunner v2', () {
    test('dialogue step blocks until dialogue is closed', () {
      final env = _RunnerTestEnv();
      env.dialogueOpen = true;

      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'intro',
          name: 'Intro',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'intro_dialogue'),
            CutsceneSetFlagStep(flagName: 'story.intro.done'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.running);
      expect(runner.status.activeStepIndex, 0);
      expect(env.openedDialogues, <String>['intro_dialogue']);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      env.dialogueOpen = false;
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['story.intro.done']);
    });

    test('moveNpcTo waits real movement completion before next step', () {
      final env = _RunnerTestEnv();
      env.moveStartStatusByEntity['npc_1'] = const ScriptedEntityMovementStatus(
        entityId: 'npc_1',
        state: ScriptedEntityMovementState.moving,
        currentPos: GridPos(x: 1, y: 1),
        targetPos: GridPos(x: 3, y: 1),
      );
      env.moveReadSequenceByEntity['npc_1'] =
          Queue<ScriptedEntityMovementStatus>()
            ..add(
              const ScriptedEntityMovementStatus(
                entityId: 'npc_1',
                state: ScriptedEntityMovementState.moving,
                currentPos: GridPos(x: 2, y: 1),
                targetPos: GridPos(x: 3, y: 1),
              ),
            )
            ..add(
              const ScriptedEntityMovementStatus(
                entityId: 'npc_1',
                state: ScriptedEntityMovementState.completed,
                currentPos: GridPos(x: 3, y: 1),
                targetPos: GridPos(x: 3, y: 1),
              ),
            );

      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'move_then_flag',
          name: 'Move then flag',
          steps: <RuntimeCutsceneStep>[
            CutsceneMoveNpcToStep(
              entityId: 'npc_1',
              destination: GridPos(x: 3, y: 1),
            ),
            CutsceneSetFlagStep(flagName: 'scene.move_done'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['scene.move_done']);
    });

    test('emitOutcome does not stop cutscene and next steps run', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'outcome_continues',
          name: 'Outcome continues',
          steps: <RuntimeCutsceneStep>[
            CutsceneEmitOutcomeStep(outcomeId: 'professor_intro.completed'),
            CutsceneSetFlagStep(flagName: 'story.after_outcome'),
          ],
        ),
      );

      runner.update(0.016);
      expect(env.emittedOutcomes, <String>['professor_intro.completed']);
      expect(runner.status.activeStepIndex, 1);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['story.after_outcome']);
    });

    test('callCutscene executes child then resumes parent', () {
      final env = _RunnerTestEnv();
      env.cutscenesById['child'] = const RuntimeCutsceneAsset(
        id: 'child',
        name: 'Child',
        steps: <RuntimeCutsceneStep>[
          CutsceneSetFlagStep(flagName: 'child.done'),
        ],
      );

      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'parent',
          name: 'Parent',
          steps: <RuntimeCutsceneStep>[
            CutsceneCallStep(cutsceneId: 'child'),
            CutsceneSetFlagStep(flagName: 'parent.done'),
          ],
        ),
      );

      // Tick 1: parent call -> child active
      runner.update(0.016);
      expect(runner.activeCutsceneId, 'child');
      expect(env.setFlags, isEmpty);

      // Tick 2: child step
      runner.update(0.016);
      expect(env.setFlags, <String>['child.done']);

      // Tick 3: child frame already popped, parent sort du call
      runner.update(0.016);
      expect(runner.activeCutsceneId, 'parent');
      expect(runner.status.activeStepIndex, 1);

      // Tick 4: parent final step
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['child.done', 'parent.done']);
    });

    test('callCutscene recursion is blocked explicitly', () {
      final env = _RunnerTestEnv();
      env.cutscenesById['a'] = const RuntimeCutsceneAsset(
        id: 'a',
        name: 'A',
        steps: <RuntimeCutsceneStep>[
          CutsceneCallStep(cutsceneId: 'b'),
        ],
      );
      env.cutscenesById['b'] = const RuntimeCutsceneAsset(
        id: 'b',
        name: 'B',
        steps: <RuntimeCutsceneStep>[
          CutsceneCallStep(cutsceneId: 'a'),
        ],
      );

      final runner = env.createRunner();
      runner.start(env.cutscenesById['a']!);

      runner.update(0.016); // a -> b
      runner.update(0.016); // b -> a (recursive fail)

      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('Recursive cutscene call'));
    });

    test(
        'waitUntilFlag and waitUntilOutcome unblock when conditions become true',
        () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'wait_conditions',
          name: 'Wait conditions',
          steps: <RuntimeCutsceneStep>[
            CutsceneWaitUntilFlagStep(flagName: 'gate.ready'),
            CutsceneWaitUntilOutcomeStep(outcomeId: 'route_1.entered'),
            CutsceneSetFlagStep(flagName: 'scene.completed'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);

      env.activeFlags.add('gate.ready');
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);

      env.activeOutcomes.add('route_1.entered');
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 2);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['scene.completed']);
    });

    test('start is refused while another cutscene is running', () {
      final env = _RunnerTestEnv();
      env.dialogueOpen = true;
      final runner = env.createRunner();
      final startedA = runner.start(
        const RuntimeCutsceneAsset(
          id: 'a',
          name: 'A',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'a_dialogue'),
          ],
        ),
      );
      expect(startedA, isTrue);

      final startedB = runner.start(
        const RuntimeCutsceneAsset(
          id: 'b',
          name: 'B',
          steps: <RuntimeCutsceneStep>[
            CutsceneSetFlagStep(flagName: 'b.done'),
          ],
        ),
      );
      expect(startedB, isFalse);
      expect(runner.lastStartError, contains('already running'));
      expect(runner.status.state, CutsceneRunnerState.running);
    });

    test('fails when called cutscene does not exist', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'parent',
          name: 'Parent',
          steps: <RuntimeCutsceneStep>[
            CutsceneCallStep(cutsceneId: 'missing'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('not found'));
    });

    test('waitUntilNpcMoveCompleted waits until scripted status is completed',
        () {
      final env = _RunnerTestEnv();
      env.moveReadSequenceByEntity['npc_wait'] =
          Queue<ScriptedEntityMovementStatus>()
            ..add(
              const ScriptedEntityMovementStatus(
                entityId: 'npc_wait',
                state: ScriptedEntityMovementState.moving,
                currentPos: GridPos(x: 4, y: 4),
                targetPos: GridPos(x: 7, y: 4),
              ),
            )
            ..add(
              const ScriptedEntityMovementStatus(
                entityId: 'npc_wait',
                state: ScriptedEntityMovementState.completed,
                currentPos: GridPos(x: 7, y: 4),
                targetPos: GridPos(x: 7, y: 4),
              ),
            );

      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'wait_npc',
          name: 'Wait NPC',
          steps: <RuntimeCutsceneStep>[
            CutsceneWaitUntilNpcMoveCompletedStep(entityId: 'npc_wait'),
            CutsceneSetFlagStep(flagName: 'wait.npc.done'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['wait.npc.done']);
    });

    test('fails when dialogue cannot be opened', () {
      final env = _RunnerTestEnv();
      env.dialoguesThatFailToOpen.add('missing_dialogue');
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'dialogue_fail',
          name: 'Dialogue fail',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'missing_dialogue'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('Failed to open dialogue'));
    });
  });
}

class _RunnerTestEnv {
  final List<String> openedDialogues = <String>[];
  final List<String> setFlags = <String>[];
  final List<String> clearedFlags = <String>[];
  final List<String> emittedOutcomes = <String>[];
  final Set<String> activeFlags = <String>{};
  final Set<String> activeOutcomes = <String>{};
  final Set<String> dialoguesThatFailToOpen = <String>{};
  final Map<String, RuntimeCutsceneAsset> cutscenesById =
      <String, RuntimeCutsceneAsset>{};

  final Map<String, ScriptedEntityMovementStatus> moveStartStatusByEntity =
      <String, ScriptedEntityMovementStatus>{};
  final Map<String, Queue<ScriptedEntityMovementStatus>>
      moveReadSequenceByEntity =
      <String, Queue<ScriptedEntityMovementStatus>>{};
  bool dialogueOpen = false;

  CutsceneRuntimeRunner createRunner({int maxCallDepth = 8}) {
    return CutsceneRuntimeRunner(
      maxCallDepth: maxCallDepth,
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          if (dialoguesThatFailToOpen.contains(dialogueId)) {
            return false;
          }
          openedDialogues.add(dialogueId);
          dialogueOpen = true;
          return true;
        },
        isDialogueOpen: () => dialogueOpen,
        resolveCutsceneById: (id) => cutscenesById[id],
        moveNpcTo: ({required entityId, required destination}) {
          return moveStartStatusByEntity[entityId] ??
              ScriptedEntityMovementStatus.idle(
                entityId: entityId,
                currentPos: destination,
              );
        },
        readNpcMovementStatus: (entityId) {
          final queue = moveReadSequenceByEntity[entityId];
          if (queue == null || queue.isEmpty) {
            return ScriptedEntityMovementStatus.idle(
              entityId: entityId,
              currentPos: const GridPos(x: 0, y: 0),
            );
          }
          return queue.removeFirst();
        },
        faceNpc: ({required entityId, required facing}) => true,
        emitOutcome: (outcomeId) {
          emittedOutcomes.add(outcomeId);
          activeOutcomes.add(outcomeId);
        },
        setFlag: (flagName) {
          setFlags.add(flagName);
          activeFlags.add(flagName);
        },
        clearFlag: (flagName) {
          clearedFlags.add(flagName);
          activeFlags.remove(flagName);
        },
        isFlagSet: (flagName) => activeFlags.contains(flagName),
        isOutcomeSet: (outcomeId) => activeOutcomes.contains(outcomeId),
      ),
    );
  }
}

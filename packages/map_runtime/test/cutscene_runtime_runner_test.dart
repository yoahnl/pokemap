import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('CutsceneRuntimeRunner branching core', () {
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
      expect(runner.status.activeStepIndex, 0);
      expect(env.openedDialogues, <String>['intro_dialogue']);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      env.dialogueOpen = false;
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);

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
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      runner.update(0.016);
      expect(runner.status.activeStepIndex, 1);
      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['scene.move_done']);
    });

    test('choice step waits until resolved and exposes last choice', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'starter_choice',
          name: 'Starter Choice',
          steps: <RuntimeCutsceneStep>[
            CutsceneChoiceStep(
              choiceId: 'starter_choice',
              prompt: 'Choose starter',
              options: <CutsceneChoiceOption>[
                CutsceneChoiceOption(value: 'fire', label: 'Fire'),
                CutsceneChoiceOption(value: 'water', label: 'Water'),
                CutsceneChoiceOption(value: 'grass', label: 'Grass'),
              ],
            ),
            CutsceneSetFlagStep(flagName: 'starter.chosen'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.activeChoiceRequest?.choiceId, 'starter_choice');
      expect(env.requestedChoices.length, 1);
      expect(env.setFlags, isEmpty);

      runner.update(0.016);
      expect(runner.status.activeStepIndex, 0);
      expect(env.setFlags, isEmpty);

      final resolved = runner.resolveActiveChoiceByIndex(1);
      expect(resolved, isTrue);
      expect(runner.lastChoiceResult?.choiceId, 'starter_choice');
      expect(runner.lastChoiceResult?.selectedIndex, 1);
      expect(runner.lastChoiceResult?.selectedValue, 'water');

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['starter.chosen']);
    });

    test('goto jumps to label and skips intermediate block', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'goto_scene',
          name: 'Goto scene',
          steps: <RuntimeCutsceneStep>[
            CutsceneGotoStep(label: 'end_block'),
            CutsceneLabelStep(label: 'middle'),
            CutsceneSetFlagStep(flagName: 'middle.reached'),
            CutsceneLabelStep(label: 'end_block'),
            CutsceneSetFlagStep(flagName: 'end.reached'),
          ],
        ),
      );

      _runUntilTerminal(runner);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['end.reached']);
      expect(env.setFlags, isNot(contains('middle.reached')));
    });

    test('fails when goto target label does not exist', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'bad_goto',
          name: 'Bad goto',
          steps: <RuntimeCutsceneStep>[
            CutsceneGotoStep(label: 'missing'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('not found'));
    });

    test('fails when cutscene has duplicated labels', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      final started = runner.start(
        const RuntimeCutsceneAsset(
          id: 'dup_label',
          name: 'Duplicate label',
          steps: <RuntimeCutsceneStep>[
            CutsceneLabelStep(label: 'same'),
            CutsceneLabelStep(label: 'same'),
          ],
        ),
      );

      expect(started, isFalse);
      expect(runner.status.state, CutsceneRunnerState.failed);
      expect(runner.status.failureReason, contains('duplicate label'));
    });

    test('gotoIfChoice branches to the matching label', () {
      final env = _RunnerTestEnv();
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'starter_selection',
          name: 'Starter selection',
          steps: <RuntimeCutsceneStep>[
            CutsceneChoiceStep(
              choiceId: 'starter_choice',
              prompt: 'Pick starter',
              options: <CutsceneChoiceOption>[
                CutsceneChoiceOption(value: 'fire', label: 'Fire'),
                CutsceneChoiceOption(value: 'water', label: 'Water'),
              ],
            ),
            CutsceneGotoIfChoiceStep(
              choiceId: 'starter_choice',
              expectedValue: 'fire',
              label: 'branch_fire',
            ),
            CutsceneGotoIfChoiceStep(
              choiceId: 'starter_choice',
              expectedValue: 'water',
              label: 'branch_water',
            ),
            CutsceneLabelStep(label: 'branch_fire'),
            CutsceneSetFlagStep(flagName: 'branch.fire'),
            CutsceneGotoStep(label: 'end_block'),
            CutsceneLabelStep(label: 'branch_water'),
            CutsceneSetFlagStep(flagName: 'branch.water'),
            CutsceneLabelStep(label: 'end_block'),
            CutsceneSetFlagStep(flagName: 'scene.done'),
          ],
        ),
      );

      runner.update(0.016);
      expect(runner.resolveActiveChoiceByValue('fire'), isTrue);
      _runUntilTerminal(runner);

      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['branch.fire', 'scene.done']);
      expect(env.setFlags, isNot(contains('branch.water')));
    });

    test('gotoIfFlag branches only when expected flag state matches', () {
      final env = _RunnerTestEnv()..activeFlags.add('story.ready');
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'flag_branch',
          name: 'Flag branch',
          steps: <RuntimeCutsceneStep>[
            CutsceneGotoIfFlagStep(
              flagName: 'story.ready',
              expectedSet: true,
              label: 'ready_path',
            ),
            CutsceneSetFlagStep(flagName: 'fallback.path'),
            CutsceneGotoStep(label: 'end_block'),
            CutsceneLabelStep(label: 'ready_path'),
            CutsceneSetFlagStep(flagName: 'ready.path'),
            CutsceneLabelStep(label: 'end_block'),
            CutsceneSetFlagStep(flagName: 'scene.done'),
          ],
        ),
      );

      _runUntilTerminal(runner);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['ready.path', 'scene.done']);
      expect(env.setFlags, isNot(contains('fallback.path')));
    });

    test('gotoIfOutcome branches only when expected outcome state matches', () {
      final env = _RunnerTestEnv()..activeOutcomes.add('rival_1.defeated');
      final runner = env.createRunner();
      runner.start(
        const RuntimeCutsceneAsset(
          id: 'outcome_branch',
          name: 'Outcome branch',
          steps: <RuntimeCutsceneStep>[
            CutsceneGotoIfOutcomeStep(
              outcomeId: 'rival_1.defeated',
              expectedSet: true,
              label: 'won_path',
            ),
            CutsceneSetFlagStep(flagName: 'fallback.path'),
            CutsceneGotoStep(label: 'end_block'),
            CutsceneLabelStep(label: 'won_path'),
            CutsceneSetFlagStep(flagName: 'won.path'),
            CutsceneLabelStep(label: 'end_block'),
            CutsceneSetFlagStep(flagName: 'scene.done'),
          ],
        ),
      );

      _runUntilTerminal(runner);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['won.path', 'scene.done']);
      expect(env.setFlags, isNot(contains('fallback.path')));
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

    test('callCutscene supports child labels/goto and resumes parent', () {
      final env = _RunnerTestEnv();
      env.cutscenesById['child'] = const RuntimeCutsceneAsset(
        id: 'child',
        name: 'Child',
        steps: <RuntimeCutsceneStep>[
          CutsceneGotoStep(label: 'child_end'),
          CutsceneSetFlagStep(flagName: 'child.middle'),
          CutsceneLabelStep(label: 'child_end'),
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

      _runUntilTerminal(runner);
      expect(runner.status.state, CutsceneRunnerState.completed);
      expect(env.setFlags, <String>['child.done', 'parent.done']);
      expect(env.setFlags, isNot(contains('child.middle')));
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

      runner.update(0.016);
      runner.update(0.016);

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

void _runUntilTerminal(
  CutsceneRuntimeRunner runner, {
  int maxTicks = 200,
  double dtSeconds = 0.016,
}) {
  var ticks = 0;
  while (!runner.status.isTerminal && ticks < maxTicks) {
    runner.update(dtSeconds);
    ticks += 1;
  }
}

class _RunnerTestEnv {
  final List<String> openedDialogues = <String>[];
  final List<CutsceneChoiceRequest> requestedChoices =
      <CutsceneChoiceRequest>[];
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
  bool rejectChoiceRequest = false;

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
        requestChoice: (request) {
          if (rejectChoiceRequest) {
            return false;
          }
          requestedChoices.add(request);
          return true;
        },
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

@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_input_state.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_inspector_rules.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late CinematicWorkspaceController controller;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    controller = owner.controller;
    await owner.open();
  });
  tearDown(() => owner.dispose());

  CinematicAsset asset() => controller.active!.asset;
  CinematicInputState inputs() => controller.inputsFor(asset().id);
  CinematicTimelineStep step(String id) =>
      asset().timeline.steps.singleWhere((s) => s.id == id);

  bool edit(CinematicAsset Function(CinematicAsset) transform) =>
      controller.editFromInspector(asset().id, transform, inputs());

  test(
    'changing the actor of each actor step uses the operation of its kind',
    () async {
      final jump = controller.addJump('hero', 'destination', afterStepId: 'face')!;
      final emote = controller.addEmote('hero', afterStepId: jump)!;
      final kinds = {
        for (final id in ['walk', 'face', jump, emote]) id: step(id).kind,
      };
      for (final id in kinds.keys) {
        expect(
          edit((a) => controller.stepWithActor(a, step(id), 'chief')),
          isTrue,
          reason: '$id ${controller.error}',
        );
        expect(step(id).actorId, 'chief');
        expect(step(id).kind, kinds[id]);
      }
      expect(isCinematicTimelineActorJumpStep(step(jump)), isTrue);
      expect(isCinematicTimelineActorEmoteStep(step(emote)), isTrue);

      expect(await controller.save(), isTrue, reason: controller.error);
      final saved = await owner.reread();
      expect(
        [
          for (final id in kinds.keys)
            saved.timeline.steps.singleWhere((s) => s.id == id).actorId,
        ],
        everyElement('chief'),
      );
    },
  );

  test('motion edits reach moves and jumps through their own operation', () {
    final jump = controller.addJump('hero', 'destination', afterStepId: 'face')!;
    expect(
      edit(
        (a) => controller.stepWithMotion(
          a,
          step('walk'),
          facingMode: CinematicTimelineActorFacingMode.preserve,
        ),
      ),
      isTrue,
    );
    expect(
      cinematicTimelineActorFacingModeOf(step('walk')),
      CinematicTimelineActorFacingMode.preserve,
    );
    expect(
      edit(
        (a) => controller.stepWithMotion(
          a,
          step(jump),
          facingMode: CinematicTimelineActorFacingMode.preserve,
        ),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(isCinematicTimelineActorJumpStep(step(jump)), isTrue);
    expect(
      cinematicTimelineActorFacingModeOf(step(jump)),
      CinematicTimelineActorFacingMode.preserve,
    );
  });

  test(
    'joining the previous step follows the parallel rules and explains refusals',
    () {
      expect(cinematicParallelJoinAvailable(asset(), step('opening')), isFalse);
      expect(cinematicParallelJoinAvailable(asset(), step('walk')), isTrue);
      final marked = asset().copyWith(
        timeline: CinematicTimeline(
          steps: [
            ...asset().timeline.steps,
            CinematicTimelineStep(id: 'repere', kind: CinematicTimelineStepKind.marker),
          ],
        ),
      );
      expect(
        cinematicParallelJoinAvailable(marked, marked.timeline.steps.last),
        isFalse,
      );

      final jump = controller.addJump(
        'chief',
        'destination',
        afterStepId: 'walk',
        durationMs: 800,
      )!;
      final before = asset();
      expect(
        edit(
          cinematicParallelEdit(
            (current) => joinCinematicParallelSteps(current, jump),
          ),
        ),
        isFalse,
      );
      expect(controller.error, contains(cinematicParallelEditError));
      expect(inputs().error, contains(cinematicParallelEditError));
      expect(asset(), same(before));

      expect(controller.updateDuration(jump, 1200), isTrue);
      expect(
        edit(
          cinematicParallelEdit(
            (current) => joinCinematicParallelSteps(current, jump),
          ),
        ),
        isTrue,
        reason: controller.error,
      );
      expect(step(jump).parallelGroupId, isNotNull);
      expect(step(jump).parallelGroupId, step('walk').parallelGroupId);
      expect(cinematicParallelJoinAvailable(asset(), step(jump)), isFalse);
      expect(inputs().error, isNull);
    },
  );
}

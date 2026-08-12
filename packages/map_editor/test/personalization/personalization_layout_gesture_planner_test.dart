import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  const planner = PersonalizationLayoutGesturePlanner();
  final layouts = suggestedProjectPresentationLayouts('standard');

  test('snaps a complete drag to a supported responsive slot', () {
    final plan = planner.plan(
      PersonalizationLayoutGestureRequest(
        surface: ProjectPresentationSurfaceRole.pauseMenu,
        breakpoint: ProjectPresentationBreakpoint.regular,
        profile: layouts,
        moveDelta: const Offset(.4, 0),
      ),
    );

    expect(plan.isAccepted, isTrue);
    expect(
      plan.profile.pauseMenu.regular.slot,
      ProjectPresentationLayoutSlot.right,
    );
    expect(plan.profile.pauseMenu.compact, layouts.pauseMenu.compact);
  });

  test('edits each responsive breakpoint without touching its siblings', () {
    for (final breakpoint in ProjectPresentationBreakpoint.values) {
      final plan = planner.planKeyboard(
        PersonalizationLayoutKeyboardRequest(
          surface: ProjectPresentationSurfaceRole.dialogue,
          breakpoint: breakpoint,
          profile: layouts,
          command: PersonalizationLayoutKeyboardCommand.moveUp,
        ),
      );

      expect(plan.isAccepted, isTrue, reason: breakpoint.name);
      expect(
        plan.profile.dialogue.resolve(breakpoint).slot,
        ProjectPresentationLayoutSlot.topCenter,
        reason: breakpoint.name,
      );
      for (final sibling in ProjectPresentationBreakpoint.values.where(
        (value) => value != breakpoint,
      )) {
        expect(
          plan.profile.dialogue.resolve(sibling),
          layouts.dialogue.resolve(sibling),
          reason: '${breakpoint.name} must not change ${sibling.name}',
        );
      }
    }
  });

  test('keeps sub-threshold movement as a no-op', () {
    final plan = planner.plan(
      PersonalizationLayoutGestureRequest(
        surface: ProjectPresentationSurfaceRole.dialogue,
        breakpoint: ProjectPresentationBreakpoint.regular,
        profile: layouts,
        moveDelta: const Offset(.02, .01),
      ),
    );

    expect(plan.isNoOp, isTrue);
    expect(plan.profile, layouts);
  });

  test('keyboard resize changes only bounded enum values', () {
    final plan = planner.planKeyboard(
      PersonalizationLayoutKeyboardRequest(
        surface: ProjectPresentationSurfaceRole.title,
        breakpoint: ProjectPresentationBreakpoint.expanded,
        profile: layouts,
        command: PersonalizationLayoutKeyboardCommand.grow,
      ),
    );

    expect(plan.isAccepted, isTrue);
    expect(
      plan.profile.title.expanded.width,
      ProjectPresentationContentWidth.wide,
    );
    expect(
      plan.profile.toJson().toString(),
      isNot(contains(RegExp(r'offset|coordinate|pixel'))),
    );
  });

  test('keyboard margin stays within the authored enum contract', () {
    final plan = planner.planKeyboard(
      PersonalizationLayoutKeyboardRequest(
        surface: ProjectPresentationSurfaceRole.dialogue,
        breakpoint: ProjectPresentationBreakpoint.regular,
        profile: layouts,
        command: PersonalizationLayoutKeyboardCommand.increaseMargin,
      ),
    );

    expect(plan.isAccepted, isTrue);
    expect(
      plan.profile.dialogue.regular.screenMargin,
      ProjectPresentationScreenMargin.comfortable,
    );
  });

  test('refuses a compact overflow at 200 percent text scale', () {
    final plan = planner.planKeyboard(
      PersonalizationLayoutKeyboardRequest(
        surface: ProjectPresentationSurfaceRole.title,
        breakpoint: ProjectPresentationBreakpoint.compact,
        profile: layouts,
        command: PersonalizationLayoutKeyboardCommand.grow,
        textScale: 2,
      ),
    );

    expect(plan.isRejected, isTrue);
    expect(plan.code, 'layoutGestureOverflow');
    expect(plan.profile, layouts);
  });

  test('escape cancels an in-flight ghost without a mutation', () {
    final session = PersonalizationLayoutGestureSession(
      planner: planner,
      surface: ProjectPresentationSurfaceRole.pauseMenu,
      breakpoint: ProjectPresentationBreakpoint.regular,
      profile: layouts,
    );

    session.previewMove(const Offset(.4, 0));
    expect(session.previewProfile, isNot(layouts));

    final result = session.cancel();

    expect(result, layouts);
    expect(session.previewProfile, layouts);
    expect(session.hasPendingChange, isFalse);
  });
}

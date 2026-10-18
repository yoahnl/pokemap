import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'fixtures/cinematic_facing_fixture.dart';

void main() {
  test(
    'typed authoring helpers default, update and round trip facing mode',
    () {
      final empty = facingCinematic().copyWith(timeline: CinematicTimeline());
      final created = addCinematicTimelineActorMoveStep(
        facingProject(empty),
        cinematicId: empty.id,
        actorId: 'actor',
        targetId: 'destination',
        facingMode: CinematicTimelineActorFacingMode.preserve,
      );
      expect(
        cinematicTimelineActorFacingModeOf(created.step),
        CinematicTimelineActorFacingMode.preserve,
      );
      final edited = updateCinematicTimelineActorMoveStep(
        created.updatedProject,
        cinematicId: empty.id,
        stepId: created.step.id,
        durationMs: 1500,
      );
      expect(
        cinematicTimelineActorFacingModeOf(edited.step),
        CinematicTimelineActorFacingMode.preserve,
      );
      final following = updateCinematicTimelineActorMoveStep(
        edited.updatedProject,
        cinematicId: empty.id,
        stepId: created.step.id,
        facingMode: CinematicTimelineActorFacingMode.followMovement,
      );
      expect(
        cinematicTimelineActorFacingModeOf(following.step),
        CinematicTimelineActorFacingMode.followMovement,
      );
      final defaultMove = addCinematicTimelineActorMoveStep(
        facingProject(empty),
        cinematicId: empty.id,
        actorId: 'actor',
        targetId: 'destination',
      );
      expect(
        cinematicTimelineActorFacingModeOf(defaultMove.step),
        CinematicTimelineActorFacingMode.followMovement,
      );
      final decoded = CinematicAsset.fromJson(edited.cinematic.toJson());
      expect(decoded, edited.cinematic);
      expect(
        cinematicTimelineActorFacingModeOf(decoded.timeline.steps.single),
        CinematicTimelineActorFacingMode.preserve,
      );
    },
  );

  test('timeline duplication and clipboard preserve the facing contract', () {
    final original = facingCinematic();
    final duplicate = duplicateCinematicTimelineSteps(
      original,
      stepIds: {'move'},
    );
    final copyId = duplicate.idRewrites['move'];
    expect(
      cinematicTimelineActorFacingModeOf(
        duplicate.cinematic.timeline.steps.singleWhere(
          (step) => step.id == copyId,
        ),
      ),
      CinematicTimelineActorFacingMode.preserve,
    );
    final clipboard = CinematicTimelineClipboard.fromJson(
      copyCinematicTimelineSteps(original, stepIds: {'move'}).toJson(),
    );
    final pasted = pasteCinematicTimelineSteps(
      original,
      clipboard: clipboard,
      insertionIndex: original.timeline.steps.length,
    );
    final pastedId = pasted.idRewrites['move'];
    expect(
      cinematicTimelineActorFacingModeOf(
        pasted.cinematic.timeline.steps.singleWhere(
          (step) => step.id == pastedId,
        ),
      ),
      CinematicTimelineActorFacingMode.preserve,
    );
    expect(
      original.timeline.steps.last.metadata['actor.facingMode'],
      'preserve',
    );
  });

  test(
    'editing facing duration or motion preserves a manual route and preview',
    () {
      final original = facingCinematic(
        manual: true,
        destinationX: 12,
        destinationY: 12,
        facingMode: 'followMovement',
      );
      final facingOnly = updateCinematicTimelineActorMoveStep(
        facingProject(original),
        cinematicId: original.id,
        stepId: 'move',
        facingMode: CinematicTimelineActorFacingMode.preserve,
      );
      expect(
        cinematicTimelineActorPathModeOf(facingOnly.step),
        CinematicTimelineActorPathMode.manual,
      );
      expect(facingOnly.cinematic.stageContext, original.stageContext);
      final edited = updateCinematicTimelineActorMoveStep(
        facingOnly.updatedProject,
        cinematicId: original.id,
        stepId: 'move',
        actorId: 'actor',
        targetId: 'destination',
        facingMode: CinematicTimelineActorFacingMode.preserve,
        durationMs: 2000,
        movementMode: CinematicTimelineActorMovementMode.run,
      );
      expect(
        cinematicTimelineActorPathModeOf(edited.step),
        CinematicTimelineActorPathMode.manual,
      );
      expect(edited.cinematic.stageContext, original.stageContext);
      expect(
        edited.cinematic.stageContext!.manualPaths,
        original.stageContext!.manualPaths,
      );
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: edited.cinematic,
      );
      final first = plan.frameAt(500).actorPoseById('actor')!;
      final second = plan.frameAt(1500).actorPoseById('actor')!;
      expect((first.x, first.y), (10.0, 8.0));
      expect((second.x, second.y), (12.0, 10.0));
      expect(first.facing, CinematicActorPreviewDirection.west);
      expect(second.facing, CinematicActorPreviewDirection.west);
    },
  );

  test('invalid modes refuse pure authoring without mutating the input', () {
    final invalid = facingCinematic(facingMode: 'unknown');
    final project = facingProject(invalid);
    final before = project.toJson();
    expect(
      cinematicTimelineActorFacingModeOf(invalid.timeline.steps.last),
      isNull,
    );
    expect(() => updateCinematicAsset(project, invalid), throwsArgumentError);
    expect(project.toJson(), before);
  });

  for (final entry
      in <(String, CinematicActorPreviewDirection, double, double)>[
        ('left', CinematicActorPreviewDirection.west, 12, 8),
        ('right', CinematicActorPreviewDirection.east, 4, 8),
        ('up', CinematicActorPreviewDirection.north, 8, 12),
        ('down', CinematicActorPreviewDirection.south, 8, 4),
      ]) {
    test('preserve keeps ${entry.$1} while moving backward and seeking', () {
      final asset = facingCinematic(
        direction: entry.$1,
        destinationX: entry.$3,
        destinationY: entry.$4,
      );
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        availableMapIds: ['room'],
      );
      for (final time in [500, 1000, 250, 0, 1000]) {
        expect(plan.frameAt(time).actorPoseById('actor')!.facing, entry.$2);
      }
      final end = plan.frameAt(1000).actorPoseById('actor')!;
      expect((end.x, end.y), (entry.$3, entry.$4));
    });
  }

  test(
    'manual segments preserve facing and each move captures its own actorFace',
    () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: facingCinematic(
          manual: true,
          secondMove: true,
          destinationX: 12,
          destinationY: 12,
        ),
      );
      for (final time in [250, 750]) {
        expect(
          plan.frameAt(time).actorPoseById('actor')!.facing,
          CinematicActorPreviewDirection.west,
        );
      }
      expect(
        plan.frameAt(1500).actorPoseById('actor')!.facing,
        CinematicActorPreviewDirection.north,
      );
      expect(
        plan.frameAt(250).actorPoseById('actor')!.facing,
        CinematicActorPreviewDirection.west,
      );
    },
  );

  for (final mode in [null, 'followMovement']) {
    test('follow movement remains the default mode=$mode', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: facingCinematic(facingMode: mode),
      );
      expect(
        plan.frameAt(500).actorPoseById('actor')!.facing,
        CinematicActorPreviewDirection.east,
      );
    });
  }

  for (final mode in ['unknown', '', ' preserve', 'PRESERVE']) {
    test(
      'explicit invalid facing mode "$mode" blocks preflight and preview',
      () {
        final asset = facingCinematic(facingMode: mode);
        final preflight = preflightCinematicPlayback(cinematic: asset);
        expect(preflight.isReady, isFalse);
        expect(
          preflight.issues.any(
            (issue) =>
                issue.stepId == 'move' &&
                issue.kind == CinematicPlaybackPreflightIssueKind.invalidStep,
          ),
          isTrue,
        );
        final diagnostics = diagnoseCinematicAsset(asset);
        expect(
          diagnostics.diagnostics.any(
            (issue) =>
                issue.stepId == 'move' &&
                issue.code ==
                    CinematicDiagnosticCode
                        .cinematicActorMoveInvalidFacingMode &&
                issue.severity == CinematicDiagnosticSeverity.error,
          ),
          isTrue,
        );
        final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
        expect(
          plan.diagnostics.any(
            (issue) =>
                issue.stepId == 'move' &&
                issue.blocking &&
                issue.code ==
                    CinematicPreviewPlaybackDiagnosticCode
                        .cinematicPreviewPlaybackMoveFacingModeInvalid,
          ),
          isTrue,
        );
      },
    );
  }
}

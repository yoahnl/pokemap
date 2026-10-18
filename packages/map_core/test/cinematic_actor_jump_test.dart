import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'fixtures/cinematic_facing_fixture.dart';

void main() {
  test('jump round-trips as its own timeline command', () {
    final asset = jumpCinematic();
    expect(asset.timeline.steps.last.kind.name, 'actorJump');
    expect(CinematicAsset.fromJson(asset.toJson()), asset);
  });

  test('sampler uses exact endpoints without cancellation rounding', () {
    final arrival = sampleCinematicJump(
      start: (x: 1e16, y: 1e16),
      end: (x: 1.0, y: 1.0),
      progress: 1,
      heightCells: 1,
    );
    expect(arrival, (x: 1.0, y: 1.0, liftCells: 0.0));
  });

  test('typed authoring adds defaults and edits only the jump contract', () {
    final empty = facingCinematic().copyWith(timeline: CinematicTimeline());
    final created = addCinematicTimelineActorJumpStep(
      facingProject(empty),
      cinematicId: empty.id,
      actorId: 'actor',
      targetId: 'destination',
    );
    expect(created.step.kind, CinematicTimelineStepKind.actorJump);
    expect(cinematicTimelineActorJumpHeightCellsOf(created.step), 0.5);
    expect(
      cinematicTimelineActorFacingModeOf(created.step),
      CinematicTimelineActorFacingMode.followMovement,
    );
    expect(isCinematicTimelineAuthoringStep(created.step), isTrue);
    final updated = updateCinematicTimelineActorJumpStep(
      created.updatedProject,
      cinematicId: empty.id,
      stepId: created.step.id,
      heightCells: 4,
      durationMs: 30000,
      facingMode: CinematicTimelineActorFacingMode.preserve,
    );
    expect(cinematicTimelineActorJumpHeightCellsOf(updated.step), 4);
    expect(updated.step.durationMs, 30000);
    expect(updated.cinematic.stageContext, empty.stageContext);
    final same = updateCinematicTimelineActorJumpStep(
      updated.updatedProject,
      cinematicId: empty.id,
      stepId: updated.step.id,
      durationMs: 200,
    );
    expect(cinematicTimelineActorJumpHeightCellsOf(same.step), 4);
    expect(
      cinematicTimelineActorFacingModeOf(same.step),
      CinematicTimelineActorFacingMode.preserve,
    );
    expect(
      () => removeCinematicMovementTarget(
        updated.updatedProject,
        cinematicId: empty.id,
        targetId: 'destination',
      ),
      throwsArgumentError,
    );
    expect(cinematicTimelineActorJumpHeightCellsOf(created.step), 0.5);
  });

  test('sampler clamps time while rejecting invalid numeric inputs', () {
    for (final progress in [-1.0, 0.0, 1.0, 2.0]) {
      final sample = sampleCinematicJump(
        start: (x: 2.0, y: 3.0),
        end: (x: 6.0, y: 7.0),
        progress: progress,
        heightCells: 0.5,
      );
      expect(sample.liftCells, 0);
      expect((sample.x, sample.y), progress <= 0 ? (2.0, 3.0) : (6.0, 7.0));
    }
    expect(
      sampleCinematicJump(
        start: (x: 2.0, y: 3.0),
        end: (x: 6.0, y: 7.0),
        progress: 0.25,
        heightCells: 4,
      ),
      (x: 3.0, y: 4.0, liftCells: 3.0),
    );
    for (final value in [double.nan, double.infinity]) {
      expect(
        () => sampleCinematicJump(
          start: (x: value, y: 0.0),
          end: (x: 0.0, y: 0.0),
          progress: 0.5,
          heightCells: 0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => sampleCinematicJump(
          start: (x: 0.0, y: 0.0),
          end: (x: 0.0, y: 0.0),
          progress: value,
          heightCells: 0.5,
        ),
        throwsArgumentError,
      );
    }
  });

  test('sequential jumps capture facing anew and seek deterministically', () {
    final initial = jumpCinematic();
    final asset = initial.copyWith(
      timeline: CinematicTimeline(
        steps: [
          ...initial.timeline.steps,
          facingStep('turn', 'up'),
          CinematicTimelineStep(
            id: 'again',
            kind: CinematicTimelineStepKind.actorJump,
            actorId: 'actor',
            targetId: 'destination',
            durationMs: 1000,
            metadata: {
              'actor.jumpHeightCells': '1',
              'actor.facingMode': 'preserve',
            },
          ),
        ],
      ),
    );
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
    for (final time in [1500, 500, 2000, 1500]) {
      final pose = plan.frameAt(time).actorPoseById('actor')!;
      expect(
        pose.facing,
        time == 500
            ? CinematicActorPreviewDirection.west
            : CinematicActorPreviewDirection.north,
      );
      expect(
        pose.liftCells,
        time == 2000
            ? 0
            : time == 500
            ? 0.5
            : 1,
      );
    }
  });

  test('restoreInitial resets jump ground pose and lift after completion', () {
    final asset = jumpCinematic().copyWith(
      actorCompletionPolicy: CinematicActorCompletionPolicy.restoreInitial,
    );
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
    expect(plan.frameAt(500).actorPoseById('actor')!.liftCells, 0.5);
    expect(
      plan.frameAt(1000).actorPoseById('actor'),
      plan.actorTracks.single.initialPose,
    );
  });

  for (final height in [0.0, -1.0, 4.001, double.nan, double.infinity]) {
    test('typed authoring refuses invalid height $height without mutation', () {
      final asset = facingCinematic().copyWith(timeline: CinematicTimeline());
      final project = facingProject(asset);
      final before = project.toJson();
      expect(
        () => addCinematicTimelineActorJumpStep(
          project,
          cinematicId: asset.id,
          actorId: 'actor',
          targetId: 'destination',
          heightCells: height,
        ),
        throwsArgumentError,
      );
      expect(project.toJson(), before);
    });
  }

  for (final destination in [double.nan, double.infinity, -1.0]) {
    test('invalid authored coordinates $destination block before mutation', () {
      final asset = facingCinematic(destinationX: destination)
          .copyWith(timeline: CinematicTimeline());
      final project = facingProject(asset);
      final before = project.toJson();
      expect(
        () => addCinematicTimelineActorJumpStep(
          project,
          cinematicId: asset.id,
          actorId: 'actor',
          targetId: 'destination',
        ),
        throwsArgumentError,
      );
      expect(project.toJson(), before);
    });
  }

  test('preview keeps ground motion separate from jump height', () {
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: jumpCinematic());
    final start = plan.frameAt(0).actorPoseById('actor')!;
    final apex = plan.frameAt(500).actorPoseById('actor')!;
    final end = plan.frameAt(1000).actorPoseById('actor')!;
    expect((start.x, start.y), (8.0, 8.0));
    expect((apex.x, apex.y), (10.0, 8.0));
    expect((end.x, end.y), (12.0, 8.0));
    expect(start.liftCells, 0);
    expect(apex.liftCells, 0.5);
    expect(end.liftCells, 0);
    expect(apex.facing, CinematicActorPreviewDirection.west);
    expect(
      plan.diagnostics.where((diagnostic) => diagnostic.blocking),
      isEmpty,
    );
  });

  test('jump on the spot keeps its facing and has a visible apex', () {
    final plan = buildCinematicPreviewPlaybackPlan(
      cinematic: jumpCinematic(
        destinationX: 8,
        destinationY: 8,
        facingMode: 'followMovement',
      ),
    );
    final apex = plan.frameAt(500).actorPoseById('actor')!;
    expect((apex.x, apex.y), (8.0, 8.0));
    expect(apex.liftCells, 0.5);
    expect(apex.facing, CinematicActorPreviewDirection.west);
  });

  for (final height in [null, '', '0', '-1', '4.01', 'NaN', 'Infinity', ' 1']) {
    test('invalid jump height $height blocks preflight and authoring', () {
      final asset = jumpCinematic(height: height);
      expect(preflightCinematicPlayback(cinematic: asset).issues, isNotEmpty);
      expect(
        () => updateCinematicAsset(facingProject(asset), asset),
        throwsArgumentError,
      );
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
      expect(plan.diagnostics.where((issue) => issue.blocking), isNotEmpty);
      expect((plan.frameAt(500).actorPoseById('actor')!.x), 8);
    });
  }

  for (final duration in [0, 199, 30001]) {
    test('invalid jump duration $duration blocks authoring and playback', () {
      final asset = jumpCinematic(durationMs: duration);
      expect(preflightCinematicPlayback(cinematic: asset).issues, isNotEmpty);
      expect(
        () => updateCinematicAsset(facingProject(asset), asset),
        throwsArgumentError,
      );
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
      expect(plan.diagnostics.where((issue) => issue.blocking), isNotEmpty);
    });
  }
}

CinematicAsset jumpCinematic({
  String? height = '0.5',
  String? facingMode = 'preserve',
  double destinationX = 12,
  double destinationY = 8,
  int durationMs = 1000,
}) {
  final json = facingCinematic(
    destinationX: destinationX,
    destinationY: destinationY,
  ).toJson();
  final steps = (json['timeline'] as Map<String, dynamic>)['steps'] as List;
  final jump = steps.last as Map<String, dynamic>;
  jump['kind'] = 'actorJump';
  jump['durationMs'] = durationMs;
  jump['metadata'] = <String, String>{
    'authoring.kind': 'basicBlock',
    'authoring.source': 'cinematic-builder-v0',
    'authoring.block': 'actorJump',
    'actor.jumpHeightCells': ?height,
    'actor.facingMode': ?facingMode,
  };
  return CinematicAsset.fromJson(json);
}

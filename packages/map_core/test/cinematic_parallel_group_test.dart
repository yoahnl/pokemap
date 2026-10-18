import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'fixtures/cinematic_facing_fixture.dart';

void main() {
  test('storyboard cuts at the group boundary when camera is second', () {
    final source = twoActorCinematic();
    final steps = source.timeline.steps;
    final cameraSecond = source.copyWith(timeline: CinematicTimeline(
        steps: [steps[0], steps[1], steps[3], steps[2]]));
    final cameraFirst = source.copyWith(timeline: CinematicTimeline(
        steps: [steps[0], steps[3], steps[1], steps[2]]));
    final a = buildCinematicStoryboardReadModel(cameraSecond);
    final b = buildCinematicStoryboardReadModel(cameraFirst);
    expect(a.shots, hasLength(2));
    expect(a.shots.map((shot) => (shot.label, shot.startMs, shot.durationMs)),
        b.shots.map((shot) => (shot.label, shot.startMs, shot.durationMs)));
    expect(a.shots.last.stepIds.toSet(), {'move', 'camera', 'otherMove'});
    expect(a.totalDurationMs, 1500);
  });

  test('parallel group is a first class step field', () {
    final asset = parallelCinematic();
    expect(asset.timeline.steps.last.toJson()['parallelGroupId'], 'pair');
    expect(CinematicAsset.fromJson(asset.toJson()), asset);
  });
  test('parallel steps share time and the next step waits for the longest', () {
    final asset = parallelCinematic();
    final layout = buildCinematicTimelineTimeLayoutReadModel(asset);
    expect(layout.blocks.map((block) => block.startMs), [0, 0, 0]);
    expect(layout.totalDurationMs, 1000);
  });
  test('same actor parallel commands refuse before authoring mutation', () {
    final asset = parallelCinematic(sameActor: true);
    expect(preflightCinematicPlayback(cinematic: asset).isReady, isFalse);
    final project = facingProject(asset);
    final before = project.toJson();
    expect(() => updateCinematicAsset(project, asset), throwsArgumentError);
    expect(project.toJson(), before);
  });
  test('timeline estimate counts the longest grouped member once', () {
    final asset = parallelCinematic();
    expect(
      buildCinematicTimelineLaneReadModel(asset).estimatedDurationMs,
      1000,
    );
  });
  for (final value in [null, '', ' pair', 'pair ', 1]) {
    test('explicit invalid group id $value is rejected', () {
      final json = facingCinematic().toJson();
      (((json['timeline'] as Map)['steps'] as List).last
              as Map)['parallelGroupId'] =
          value;
      expect(() => CinematicAsset.fromJson(json), throwsArgumentError);
    });
  }
  test('group timing uses a maximum then a sequential barrier', () {
    final asset = parallelCinematic();
    final extended = asset.copyWith(
      timeline: CinematicTimeline(
        steps: [
          ...asset.timeline.steps,
          CinematicTimelineStep(
            id: 'after',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 200,
          ),
        ],
      ),
    );
    final schedule = buildCinematicTimelineSchedule(extended);
    expect(schedule.isValid, isTrue);
    expect(schedule.groups.map((group) => group.durationMs), [0, 1000, 200]);
    expect(schedule.steps.map((member) => member.startMs), [0, 0, 0, 1000]);
    expect(schedule.totalDurationMs, 1200);
    expect(schedule.groups[1].members.map((member) => member.stepIndex), [
      1,
      2,
    ]);
  });
  test('nominal dialogue timing preserves the explicit preview runtime distinction', () {
    final asset = facingCinematic().copyWith(
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'dialogue',
            kind: CinematicTimelineStepKind.dialogueLine,
            dialogueText: 'Hello',
          ),
          CinematicTimelineStep(
            id: 'sound',
            kind: CinematicTimelineStepKind.sound,
          ),
        ],
      ),
    );
    expect(buildCinematicTimelineSchedule(asset).totalDurationMs, 600);
    expect(
      buildCinematicTimelineSchedule(
        asset,
        timing: CinematicTimelineScheduleTiming.runtime,
      ).totalDurationMs,
      300,
    );
  });
  test(
    'group id cannot recur after a marker and markers cannot be grouped',
    () {
      final asset = parallelCinematic();
      final grouped = asset.timeline.steps.last;
      final marker = CinematicTimelineStep(
        id: 'marker',
        kind: CinematicTimelineStepKind.marker,
      );
      final split = asset.copyWith(
        timeline: CinematicTimeline(
          steps: [...asset.timeline.steps.take(2), marker, grouped],
        ),
      );
      expect(
        buildCinematicTimelineSchedule(split).issues.map((issue) => issue.kind),
        contains(CinematicTimelineScheduleIssueKind.nonContiguousGroup),
      );
      final marked = CinematicTimelineStep.fromJson({
        ...marker.toJson(),
        'parallelGroupId': 'pair',
      });
      final bad = asset.copyWith(timeline: CinematicTimeline(steps: [marked]));
      expect(
        buildCinematicTimelineSchedule(bad).issues.single.kind,
        CinematicTimelineScheduleIssueKind.groupedMarker,
      );
    },
  );
  for (final kinds in [
    [CinematicTimelineStepKind.camera, CinematicTimelineStepKind.shake],
    [
      CinematicTimelineStepKind.dialogueLine,
      CinematicTimelineStepKind.dialogueLine,
    ],
    [CinematicTimelineStepKind.fade, CinematicTimelineStepKind.fade],
    [
      CinematicTimelineStepKind.actorEmote,
      CinematicTimelineStepKind.actorEmote,
    ],
    [CinematicTimelineStepKind.sound, CinematicTimelineStepKind.sound],
    [CinematicTimelineStepKind.music, CinematicTimelineStepKind.music],
    [CinematicTimelineStepKind.fx, CinematicTimelineStepKind.fx],
  ]) {
    test('parallel resource conflict $kinds is explicit', () {
      final asset = facingCinematic().copyWith(
        timeline: CinematicTimeline(
          steps: [
            for (var i = 0; i < kinds.length; i++)
              CinematicTimelineStep(
                id: 'step$i',
                kind: kinds[i],
                durationMs: 1000,
                parallelGroupId: 'group',
              ),
          ],
        ),
      );
      final issues = buildCinematicTimelineSchedule(asset).issues;
      expect(
        issues.map((issue) => issue.kind),
        contains(CinematicTimelineScheduleIssueKind.resourceConflict),
      );
      expect(issues.first.stepIds, ['step0', 'step1']);
    });
  }
  test(
    'same physical map entity conflicts even with distinct actor aliases',
    () {
      final json = parallelCinematic(sameActor: true).toJson();
      (json['requiredActors'] as List).add({'actorId': 'alias'});
      final context = json['stageContext'] as Map;
      context['actorBindings'] = [
        {'actorId': 'actor', 'kind': 'mapEntity', 'mapEntityId': 'npc'},
        {'actorId': 'alias', 'kind': 'mapEntity', 'mapEntityId': 'npc'},
      ];
      final steps = (json['timeline'] as Map)['steps'] as List;
      (steps.last as Map)['actorId'] = 'alias';
      (steps.last as Map)['durationMs'] = 1000;
      final schedule = buildCinematicTimelineSchedule(
        CinematicAsset.fromJson(json),
      );
      expect(schedule.issues.single.resourceKey, 'actor:entity:room:npc');
    },
  );
  test('distinct actors with differing movement durations are refused', () {
    final json = parallelCinematic(sameActor: true).toJson();
    (((json['timeline'] as Map)['steps'] as List).last as Map)['actorId'] =
        'other';
    final issues = buildCinematicTimelineSchedule(CinematicAsset.fromJson(json))
        .issues;
    expect(
      issues.map((issue) => issue.kind),
      contains(CinematicTimelineScheduleIssueKind.movementDurationMismatch),
    );
  });
  test(
    'group setter is atomic and duplication rewrites the group identity',
    () {
      final source = facingCinematic().copyWith(
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'first',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 200,
            ),
            CinematicTimelineStep(
              id: 'second',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 400,
            ),
          ],
        ),
      );
      final grouped = setCinematicTimelineParallelGroup(
        source,
        stepIds: {'first', 'second'},
        parallelGroupId: 'pair',
      ).cinematic;
      expect(source.timeline.steps.first.parallelGroupId, isNull);
      expect(buildCinematicTimelineSchedule(grouped).totalDurationMs, 400);
      final copied = duplicateCinematicTimelineSteps(
        grouped,
        stepIds: {'first', 'second'},
      ).cinematic;
      final schedule = buildCinematicTimelineSchedule(copied);
      expect(schedule.isValid, isTrue);
      expect(schedule.groups, hasLength(2));
      expect(
        schedule.groups[0].parallelGroupId,
        isNot(schedule.groups[1].parallelGroupId),
      );
      final clipboard = copyCinematicTimelineSteps(
        grouped,
        stepIds: {'first', 'second'},
      );
      final pasted = pasteCinematicTimelineSteps(
        grouped,
        clipboard: clipboard,
        insertionIndex: 2,
      ).cinematic;
      expect(buildCinematicTimelineSchedule(pasted).isValid, isTrue);
      expect(buildCinematicTimelineSchedule(pasted).groups, hasLength(2));
      final ungrouped = setCinematicTimelineParallelGroup(
        grouped,
        stepIds: {'first', 'second'},
        parallelGroupId: null,
      ).cinematic;
      expect(buildCinematicTimelineSchedule(ungrouped).totalDurationMs, 600);
    },
  );
  test('editing a grouped move preserves its group and unrelated metadata', () {
    final asset = parallelCinematic();
    final edited = updateCinematicTimelineActorMoveStep(
      facingProject(asset),
      cinematicId: asset.id,
      stepId: 'move',
      facingMode: CinematicTimelineActorFacingMode.followMovement,
    );
    expect(edited.step.parallelGroupId, 'pair');
    expect(edited.cinematic.timeline.steps.last.parallelGroupId, 'pair');
  });

  test(
    'two actors and camera share starts, seek and barrier deterministically',
    () {
      final asset = twoActorCinematic();
      final reversed = asset.copyWith(
        timeline: CinematicTimeline(
          steps: [
            asset.timeline.steps.first,
            ...asset.timeline.steps.skip(1).toList().reversed,
          ],
        ),
      );
      for (final source in [asset, reversed]) {
        final plan = buildCinematicPreviewPlaybackPlan(cinematic: source);
        expect(plan.diagnostics.where((issue) => issue.blocking), isEmpty);
        expect(plan.totalDurationMs, 1500);
        expect(plan.executableDurationMs, 1500);
        for (final time in [500, 1200, 500]) {
          final frame = plan.frameAt(time);
          expect(frame.actorPoseById('actor')!.x, time == 500 ? 10 : 12);
          expect(frame.actorPoseById('other')!.y, time == 500 ? 8 : 12);
          expect(frame.cameraPose.geometry.centerX, 8);
        }
        expect(
          buildCinematicTimelineLaneReadModel(source).estimatedDurationMs,
          1500,
        );
        expect(
          buildCinematicsLibraryReadModel(facingProject(source))
              .canonicalEntries
              .single
              .timeline
              .estimatedDurationMs,
          1500,
        );
        expect(buildCinematicStoryboardReadModel(source).totalDurationMs, 1500);
      }
    },
  );
}

CinematicAsset parallelCinematic({bool sameActor = false}) {
  final json = facingCinematic().toJson();
  final steps = (json['timeline'] as Map)['steps'] as List;
  final move = steps.last as Map<String, dynamic>;
  move['parallelGroupId'] = 'pair';
  steps.add(<String, dynamic>{
    'id': 'wait',
    'kind': sameActor ? 'actorMove' : 'wait',
    'parallelGroupId': 'pair',
    'durationMs': 500,
    if (sameActor) ...{
      'actorId': 'actor',
      'targetId': 'destination',
      'metadata': move['metadata'],
    },
  });
  return CinematicAsset.fromJson(json);
}

CinematicAsset twoActorCinematic() {
  final json = facingCinematic().toJson();
  (json['requiredActors'] as List).add({'actorId': 'other'});
  (json['movementTargets'] as List).add({
    'targetId': 'otherTarget',
    'label': 'Other',
  });
  final context = json['stageContext'] as Map;
  (context['actorBindings'] as List).add({
    'actorId': 'other',
    'kind': 'mapEntity',
    'mapEntityId': 'npc-other',
  });
  (context['initialPlacements'] as List).add({
    'actorId': 'other',
    'kind': 'stagePoint',
    'stagePointId': 'otherStart',
  });
  (context['stagePoints'] as List).addAll(<Map<String, dynamic>>[
    {'id': 'otherStart', 'label': 'Other start', 'x': 4, 'y': 4},
    {'id': 'otherEnd', 'label': 'Other end', 'x': 4, 'y': 12},
  ]);
  (context['movementTargetBindings'] as List).add({
    'targetId': 'otherTarget',
    'kind': 'stagePoint',
    'sourceId': 'otherEnd',
  });
  final steps = (json['timeline'] as Map)['steps'] as List;
  final move = steps.last as Map<String, dynamic>;
  move['parallelGroupId'] = 'group';
  steps.add({
    ...move,
    'id': 'otherMove',
    'actorId': 'other',
    'targetId': 'otherTarget',
  });
  steps.add({
    'id': 'camera',
    'kind': 'camera',
    'parallelGroupId': 'group',
    'durationMs': 1500,
    'metadata': {
      'camera.mode': 'focus',
      'camera.targetKind': 'actor',
      'camera.targetActorId': 'actor',
      'camera.zoomPreset': 'medium',
    },
  });
  return CinematicAsset.fromJson(json);
}

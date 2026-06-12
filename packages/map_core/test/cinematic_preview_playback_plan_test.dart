import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildCinematicPreviewPlaybackPlan', () {
    test('empty cinematic produces an empty plan and timeline diagnostic', () {
      final cinematic = CinematicAsset(
        id: 'cinematic_empty',
        title: 'Empty cinematic',
        timeline: CinematicTimeline(),
      );

      final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);
      final frame = plan.frameAt(120);

      expect(plan.cinematicId, 'cinematic_empty');
      expect(plan.totalDurationMs, 0);
      expect(plan.timelineItems, isEmpty);
      expect(plan.actorTracks, isEmpty);
      expect(frame.timeMs, 120);
      expect(frame.clampedTimeMs, 0);
      expect(frame.activeStepIds, isEmpty);
      expect(frame.actorPoses, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackTimelineEmpty,
        ),
      );
      expect(plan.capabilities.hasUnsupportedSteps, isFalse);
    });

    test('derives timeline items and clamps frame time deterministically', () {
      final cinematic = _directMoveCinematic();

      final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);

      expect(plan.totalDurationMs, 1700);
      expect(
        plan.timelineItems.map((item) => (
              item.stepId,
              item.stepIndex,
              item.kind,
              item.startMs,
              item.endMs,
              item.visualDurationMs,
              item.durationSource,
              item.supported,
            )),
        [
          (
            'face_down',
            0,
            CinematicTimelineStepKind.actorFace,
            0,
            300,
            cinematicTimelineFallbackVisualDurationMs,
            CinematicTimelineVisualDurationSource.fallback,
            true,
          ),
          (
            'wait',
            1,
            CinematicTimelineStepKind.wait,
            300,
            700,
            400,
            CinematicTimelineVisualDurationSource.explicit,
            true,
          ),
          (
            'move_direct',
            2,
            CinematicTimelineStepKind.actorMove,
            700,
            1700,
            1000,
            CinematicTimelineVisualDurationSource.explicit,
            true,
          ),
        ],
      );

      expect(plan.frameAt(-20).clampedTimeMs, 0);
      expect(plan.frameAt(-20).activeStepIds, ['face_down']);
      expect(plan.frameAt(300).activeStepIds, ['wait']);
      expect(plan.frameAt(1699).activeStepIds, ['move_direct']);
      expect(plan.frameAt(1700).activeStepIds, isEmpty);
      expect(plan.frameAt(2200).clampedTimeMs, 1700);

      final first = plan.frameAt(1100);
      final second = plan.frameAt(1100);
      expect(second, first);
    });

    test('uses actor display preview position before stageContext placement',
        () {
      final actorDisplayPreviewModel = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 acteur projetable.',
        actors: [
          CinematicActorDisplayPreviewActor(
            actorId: 'actor_lysa',
            label: 'Lysa',
            role: null,
            bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            bindingSourceId: null,
            bindingSourceLabel: null,
            position: const CinematicActorPreviewPosition(
              status: CinematicActorPreviewPositionStatus.resolved,
              sourceKind: CinematicActorPreviewPositionSourceKind.stagePoint,
              x: 4,
              y: 5,
              sourceId: 'preview_point',
              sourceLabel: 'Preview point',
            ),
            appearance: const CinematicActorPreviewAppearance(
              status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
            ),
            direction: CinematicActorPreviewDirection.west,
            directionSource: CinematicActorPreviewDirectionSource.actorFace,
            renderHint: CinematicActorPreviewRenderHint.placeholder,
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: _directMoveCinematic(),
        actorDisplayPreviewModel: actorDisplayPreviewModel,
      );

      final pose = plan.actorTracks.single.initialPose;
      expect(pose.x, 4);
      expect(pose.y, 5);
      expect(pose.facing, CinematicActorPreviewDirection.west);
      expect(pose.source, CinematicActorPlaybackPoseSource.actorDisplay);
      expect(pose.actorLabel, 'Lysa');
    });

    test('reports missing initial pose without fake zero fallback', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_missing_start',
          title: 'Missing start',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          timeline: CinematicTimeline(
            steps: [
              _waitStep(id: 'wait', durationMs: 300),
            ],
          ),
        ),
      );

      final pose = plan.frameAt(0).actorPoseById('actor_lysa')!;
      expect(pose.x, isNull);
      expect(pose.y, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackActorInitialPoseMissing,
        ),
      );
    });

    test('actorFace changes facing and wait preserves the pose', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: _directMoveCinematic(),
      );

      final facingDuringFace = plan.frameAt(10).actorPoseById('actor_lysa')!;
      final facingDuringWait = plan.frameAt(450).actorPoseById('actor_lysa')!;

      expect(facingDuringFace.facing, CinematicActorPreviewDirection.south);
      expect(facingDuringWait.facing, CinematicActorPreviewDirection.south);
      expect(facingDuringWait.x, 0);
      expect(facingDuringWait.y, 0);
      expect(
          facingDuringWait.source, CinematicActorPlaybackPoseSource.actorFace);
    });

    test('direct actorMove interpolates linearly and reaches destination', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: _directMoveCinematic(),
      );

      final halfway = plan.frameAt(1200).actorPoseById('actor_lysa')!;
      final finalPose = plan.frameAt(1700).actorPoseById('actor_lysa')!;

      expect(halfway.x, closeTo(5, 0.001));
      expect(halfway.y, closeTo(0, 0.001));
      expect(halfway.facing, CinematicActorPreviewDirection.east);
      expect(halfway.isInterpolated, isTrue);
      expect(halfway.activeStepId, 'move_direct');
      expect(halfway.source, CinematicActorPlaybackPoseSource.actorMoveDirect);

      expect(finalPose.x, 10);
      expect(finalPose.y, 0);
      expect(finalPose.isInterpolated, isFalse);
    });

    test('direct actorMove missing destination produces diagnostic', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: _directMoveCinematic(
          movementTargetBindings: const [],
          movementTargets: [
            CinematicMovementTargetRef(
              targetId: 'target_port',
              label: 'Port',
            ),
          ],
        ),
      );

      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackMoveDestinationMissing,
        ),
      );
      final pose = plan.frameAt(1200).actorPoseById('actor_lysa')!;
      expect(pose.x, 0);
      expect(pose.y, 0);
    });

    test('manual actorMove interpolates through waypoints by distance', () {
      final cinematic = _manualPathCinematic();
      final before = cinematic.toJson();

      final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);
      final midPose = plan.frameAt(350).actorPoseById('actor_lysa')!;
      final finalPose = plan.frameAt(700).actorPoseById('actor_lysa')!;

      expect(midPose.x, closeTo(3, 0.001));
      expect(midPose.y, closeTo(2, 0.001));
      expect(midPose.facing, CinematicActorPreviewDirection.south);
      expect(
          midPose.source, CinematicActorPlaybackPoseSource.actorMoveManualPath);
      expect(midPose.isInterpolated, isTrue);
      expect(finalPose.x, closeTo(6, 0.001));
      expect(finalPose.y, closeTo(4, 0.001));
      expect(cinematic.toJson(), before);
    });

    test('manual actorMove reports missing path and missing waypoint', () {
      final withoutPath = buildCinematicPreviewPlaybackPlan(
        cinematic: _manualPathCinematic(manualPaths: const []),
      );
      final withMissingWaypoint = buildCinematicPreviewPlaybackPlan(
        cinematic: _manualPathCinematic(
          manualPaths: [
            CinematicManualPath(
              id: 'path_missing_waypoint',
              label: 'Missing waypoint',
              ownerActorMoveStepId: 'move_manual',
              waypointStagePointIds: const ['missing_point'],
            ),
          ],
        ),
      );

      expect(
        withoutPath.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackManualPathMissing,
        ),
      );
      expect(
        withMissingWaypoint.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackManualPathPointMissing,
        ),
      );
    });

    test('manual actorMove with all zero-length segments stays deterministic',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: _manualPathCinematic(
          stagePoints: [
            _point('start', 0, 0),
            _point('wp_a', 0, 0),
            _point('wp_b', 0, 0),
            _point('dest', 0, 0),
          ],
        ),
      );

      final first = plan.frameAt(350).actorPoseById('actor_lysa')!;
      final second = plan.frameAt(350).actorPoseById('actor_lysa')!;

      expect(second, first);
      expect(first.x, 0);
      expect(first.y, 0);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackManualPathZeroLength,
        ),
      );
    });

    test(
        'fade returns fade state and camera remains an unsupported placeholder',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_fx',
          title: 'FX cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'fade_out',
                kind: CinematicTimelineStepKind.fade,
                durationMs: 1000,
                metadata: const {
                  cinematicTimelineFadeModeMetadataKey: 'fadeOut',
                },
              ),
              CinematicTimelineStep(
                id: 'camera_hold',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
              ),
            ],
          ),
        ),
      );

      final fadeFrame = plan.frameAt(500);
      final cameraFrame = plan.frameAt(1200);

      expect(fadeFrame.fadeState, isNotNull);
      expect(fadeFrame.fadeState!.mode, CinematicFadePlaybackMode.fadeOut);
      expect(fadeFrame.fadeState!.opacity, closeTo(0.5, 0.001));
      expect(cameraFrame.cameraPose, isNotNull);
      expect(cameraFrame.cameraPose!.supported, isFalse);
      expect(plan.capabilities.supportsFade, isTrue);
      expect(plan.capabilities.supportsCamera, isFalse);
      expect(plan.capabilities.hasUnsupportedSteps, isTrue);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraUnsupported,
        ),
      );
    });

    test('unsupported steps produce no-code diagnostics', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_dialogue',
          title: 'Dialogue cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'dialogue',
                kind: CinematicTimelineStepKind.dialogueLine,
                durationMs: 500,
              ),
            ],
          ),
        ),
      );

      expect(plan.timelineItems.single.supported, isFalse);
      expect(plan.capabilities.hasUnsupportedSteps, isTrue);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackUnsupportedStep,
        ),
      );
      expect(
        plan.diagnostics
            .singleWhere(
              (diagnostic) =>
                  diagnostic.code ==
                  CinematicPreviewPlaybackDiagnosticCode
                      .cinematicPreviewPlaybackUnsupportedStep,
            )
            .message,
        'Ce bloc n’est pas encore prévisualisé.',
      );
    });
  });
}

CinematicAsset _directMoveCinematic({
  List<CinematicMovementTargetRef>? movementTargets,
  List<CinematicMovementTargetBinding>? movementTargetBindings,
}) {
  return CinematicAsset(
    id: 'cinematic_direct',
    title: 'Direct movement',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
    ],
    movementTargets: movementTargets ??
        [
          CinematicMovementTargetRef(
            targetId: 'target_port',
            label: 'Port',
          ),
        ],
    stageContext: CinematicStageContext(
      stagePoints: [
        _point('start', 0, 0),
        _point('dest', 10, 0),
      ],
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_lysa',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_lysa',
          kind: CinematicActorInitialPlacementKind.stagePoint,
          stagePointId: 'start',
        ),
      ],
      movementTargetBindings: movementTargetBindings ??
          [
            CinematicMovementTargetBinding(
              targetId: 'target_port',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'dest',
            ),
          ],
    ),
    timeline: CinematicTimeline(
      steps: [
        _actorFaceStep(
          id: 'face_down',
          actorId: 'actor_lysa',
          direction: CinematicTimelineActorFacingDirection.down,
        ),
        _waitStep(id: 'wait', durationMs: 400),
        _actorMoveStep(
          id: 'move_direct',
          actorId: 'actor_lysa',
          targetId: 'target_port',
          durationMs: 1000,
          pathMode: CinematicTimelineActorPathMode.direct,
        ),
      ],
    ),
  );
}

CinematicAsset _manualPathCinematic({
  List<CinematicManualPath>? manualPaths,
  List<CinematicStagePoint>? stagePoints,
}) {
  return CinematicAsset(
    id: 'cinematic_manual',
    title: 'Manual movement',
    requiredActors: [
      CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
    ],
    movementTargets: [
      CinematicMovementTargetRef(
        targetId: 'target_dest',
        label: 'Destination',
      ),
    ],
    stageContext: CinematicStageContext(
      stagePoints: stagePoints ??
          [
            _point('start', 0, 0),
            _point('wp_a', 3, 0),
            _point('wp_b', 3, 4),
            _point('dest', 6, 4),
          ],
      actorBindings: [
        CinematicActorBinding(
          actorId: 'actor_lysa',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
          actorId: 'actor_lysa',
          kind: CinematicActorInitialPlacementKind.stagePoint,
          stagePointId: 'start',
        ),
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
          targetId: 'target_dest',
          kind: CinematicMovementTargetBindingKind.stagePoint,
          sourceId: 'dest',
        ),
      ],
      manualPaths: manualPaths ??
          [
            CinematicManualPath(
              id: 'path_manual',
              label: 'Manual path',
              ownerActorMoveStepId: 'move_manual',
              waypointStagePointIds: const ['wp_a', 'wp_b'],
            ),
          ],
    ),
    timeline: CinematicTimeline(
      steps: [
        _actorMoveStep(
          id: 'move_manual',
          actorId: 'actor_lysa',
          targetId: 'target_dest',
          durationMs: 700,
          pathMode: CinematicTimelineActorPathMode.manual,
        ),
      ],
    ),
  );
}

CinematicTimelineStep _actorFaceStep({
  required String id,
  required String actorId,
  required CinematicTimelineActorFacingDirection direction,
}) {
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.actorFace,
    actorId: actorId,
    metadata: {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineBasicBlockMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
      cinematicTimelineAuthoringBlockMetadataKey:
          cinematicTimelineActorFaceBlockMetadataValue,
      cinematicTimelineActorDirectionMetadataKey: direction.name,
    },
  );
}

CinematicTimelineStep _actorMoveStep({
  required String id,
  required String actorId,
  required String targetId,
  required int durationMs,
  required CinematicTimelineActorPathMode pathMode,
}) {
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.actorMove,
    actorId: actorId,
    targetId: targetId,
    durationMs: durationMs,
    metadata: {
      cinematicTimelineDraftMetadataKindKey:
          cinematicTimelineBasicBlockMetadataKindValue,
      cinematicTimelineDraftMetadataSourceKey:
          cinematicTimelineDraftMetadataSourceValue,
      cinematicTimelineAuthoringBlockMetadataKey:
          cinematicTimelineActorMoveBlockMetadataValue,
      cinematicTimelineActorMovementModeMetadataKey:
          CinematicTimelineActorMovementMode.walk.name,
      cinematicTimelineActorPathModeMetadataKey: pathMode.name,
    },
  );
}

CinematicTimelineStep _waitStep({
  required String id,
  required int durationMs,
}) {
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.wait,
    durationMs: durationMs,
  );
}

CinematicStagePoint _point(String id, double x, double y) {
  return CinematicStagePoint(id: id, label: id, x: x, y: y);
}

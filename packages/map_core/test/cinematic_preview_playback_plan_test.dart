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

    test('V1-123 camera block produces active playback state', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera',
          title: 'Camera cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_reset',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 1000,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'reset',
                },
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(500);

      expect(frame.cameraPose.isActive, isTrue);
      expect(frame.cameraPose.activeStepId, 'camera_reset');
      expect(frame.cameraPose.isSupported, isTrue);
      expect(frame.cameraPose.supported, isTrue);
      expect(frame.cameraPose.mode, CinematicTimelineCameraMode.reset);
      expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
      expect(frame.cameraPose.diagnostics, isEmpty);
      expect(plan.capabilities.supportsCamera, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isFalse);
    });

    test('V1-123 camera playback state exposes clamped progress', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_progress',
          title: 'Camera progress cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'wait',
                kind: CinematicTimelineStepKind.wait,
                durationMs: 200,
              ),
              CinematicTimelineStep(
                id: 'camera_hold',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 1000,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
              ),
            ],
          ),
        ),
      );

      expect(plan.frameAt(-50).cameraPose.isActive, isFalse);
      expect(plan.frameAt(199).cameraPose.isActive, isFalse);
      expect(plan.frameAt(200).cameraPose.progress, 0);
      expect(plan.frameAt(700).cameraPose.progress, closeTo(0.5, 0.001));
      expect(plan.frameAt(1199).cameraPose.progress, closeTo(0.999, 0.001));
      expect(plan.frameAt(1200).cameraPose.isActive, isFalse);
      expect(plan.frameAt(2000).cameraPose.isActive, isFalse);
    });

    test('V1-123 unsupported camera mode produces diagnostic without crashing',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_unknown',
          title: 'Camera unknown cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_orbit',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'orbit',
                },
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.isActive, isTrue);
      expect(frame.cameraPose.activeStepId, 'camera_orbit');
      expect(frame.cameraPose.isSupported, isFalse);
      expect(frame.cameraPose.mode, isNull);
      expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
      expect(
        frame.cameraPose.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraUnsupported,
        ),
      );
      expect(plan.capabilities.supportsCamera, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isTrue);
    });

    test('V1-131 camera focus remains symbolic until geometry exists', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_focus',
          title: 'Camera focus cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_focus',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'focus',
                  cinematicTimelineCameraTargetKindMetadataKey: 'sceneCenter',
                  cinematicTimelineCameraZoomPresetMetadataKey: 'medium',
                },
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.isActive, isTrue);
      expect(frame.cameraPose.activeStepId, 'camera_focus');
      expect(frame.cameraPose.mode, CinematicTimelineCameraMode.focus);
      expect(frame.cameraPose.isSupported, isFalse);
      expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
      expect(
        frame.cameraPose.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraUnsupported,
        ),
      );
      expect(plan.capabilities.supportsCamera, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isTrue);
    });

    test(
        'V1-133 camera focus scene center exposes geometry when stage bounds are available',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_scene_center',
          title: 'Camera scene center',
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.sceneCenter(),
                zoomPreset: CinematicCameraZoomPreset.medium,
              ),
            ],
          ),
        ),
        stageBounds: const CinematicPreviewPlaybackStageBounds(
          width: 12,
          height: 8,
        ),
      );

      final frame = plan.frameAt(250);
      final geometry = frame.cameraPose.geometry;

      expect(frame.cameraPose.isSupported, isFalse);
      expect(geometry.isAvailable, isTrue);
      expect(geometry.targetKind, CinematicCameraTargetKind.sceneCenter);
      expect(geometry.targetLabel, 'Centre de la scène');
      expect(geometry.centerX, 6);
      expect(geometry.centerY, 4);
      expect(geometry.zoomPreset, CinematicCameraZoomPreset.medium);
      expect(
        frame.cameraPose.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraUnsupported,
        ),
      );
    });

    test(
        'V1-133 camera focus scene center reports unavailable geometry when bounds are missing',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_scene_center_missing_bounds',
          title: 'Camera scene center missing bounds',
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.sceneCenter(),
                zoomPreset: CinematicCameraZoomPreset.medium,
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.geometry.isAvailable, isFalse);
      expect(
        frame.cameraPose.geometry.diagnostics
            .map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraTargetStageMapMissing,
        ),
      );
    });

    test('V1-133 camera focus actor resolves geometry from active actor pose',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_actor',
          title: 'Camera actor',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          stageContext: CinematicStageContext(
            stagePoints: [_point('start', 2, 3)],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_lysa',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'start',
              ),
            ],
          ),
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.actor(
                  actorId: 'actor_lysa',
                ),
                zoomPreset: CinematicCameraZoomPreset.close,
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);
      final geometry = frame.cameraPose.geometry;

      expect(geometry.isAvailable, isTrue);
      expect(geometry.targetKind, CinematicCameraTargetKind.actor);
      expect(geometry.actorId, 'actor_lysa');
      expect(geometry.targetLabel, 'Lysa');
      expect(geometry.centerX, 2);
      expect(geometry.centerY, 3);
      expect(geometry.zoomPreset, CinematicCameraZoomPreset.close);
    });

    test('V1-133 camera focus actor consumes actorMove playback pose', () {
      final cinematic = _directMoveCinematic(
        steps: [
          _actorMoveStep(
            id: 'move_direct',
            actorId: 'actor_lysa',
            targetId: 'target_port',
            durationMs: 1000,
            pathMode: CinematicTimelineActorPathMode.direct,
          ),
          _cameraFocusStep(
            id: 'camera_focus',
            target: CinematicCameraTargetBinding.actor(
              actorId: 'actor_lysa',
            ),
            zoomPreset: CinematicCameraZoomPreset.medium,
          ),
        ],
      );
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);

      final frame = plan.frameAt(1250);
      final actorPose = frame.actorPoseById('actor_lysa');

      expect(actorPose?.x, 10);
      expect(actorPose?.y, 0);
      expect(frame.cameraPose.geometry.isAvailable, isTrue);
      expect(frame.cameraPose.geometry.centerX, actorPose?.x);
      expect(frame.cameraPose.geometry.centerY, actorPose?.y);
    });

    test(
        'V1-133 camera focus actor reports missing pose for unavailable actor position',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_actor_missing_pose',
          title: 'Camera actor missing pose',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.actor(
                  actorId: 'actor_lysa',
                ),
                zoomPreset: CinematicCameraZoomPreset.medium,
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.geometry.isAvailable, isFalse);
      expect(
        frame.cameraPose.geometry.diagnostics
            .map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraTargetActorWithoutPosition,
        ),
      );
    });

    test('V1-133 camera focus stage point resolves geometry from stage point',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_stage_point',
          title: 'Camera stage point',
          stageContext: CinematicStageContext(
            stagePoints: [_point('balcony', 7, 5)],
          ),
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.stagePoint(
                  stagePointId: 'balcony',
                ),
                zoomPreset: CinematicCameraZoomPreset.wide,
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);
      final geometry = frame.cameraPose.geometry;

      expect(geometry.isAvailable, isTrue);
      expect(geometry.targetKind, CinematicCameraTargetKind.stagePoint);
      expect(geometry.stagePointId, 'balcony');
      expect(geometry.targetLabel, 'balcony');
      expect(geometry.centerX, 7);
      expect(geometry.centerY, 5);
      expect(geometry.zoomPreset, CinematicCameraZoomPreset.wide);
    });

    test('V1-133 camera focus stage point reports unknown stage point', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_unknown_stage_point',
          title: 'Camera unknown stage point',
          stageContext: CinematicStageContext(
            stagePoints: [_point('known', 1, 1)],
          ),
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.stagePoint(
                  stagePointId: 'missing',
                ),
                zoomPreset: CinematicCameraZoomPreset.medium,
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.geometry.isAvailable, isFalse);
      expect(
        frame.cameraPose.geometry.diagnostics
            .map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraTargetStagePointUnknown,
        ),
      );
    });

    test(
        'V1-133 camera focus stage point reports out of map when bounds are available',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_stage_point_out_of_map',
          title: 'Camera stage point out of map',
          stageContext: CinematicStageContext(
            stagePoints: [_point('outside', 20, 1)],
          ),
          timeline: CinematicTimeline(
            steps: [
              _cameraFocusStep(
                id: 'camera_focus',
                target: CinematicCameraTargetBinding.stagePoint(
                  stagePointId: 'outside',
                ),
                zoomPreset: CinematicCameraZoomPreset.medium,
              ),
            ],
          ),
        ),
        stageBounds: const CinematicPreviewPlaybackStageBounds(
          width: 10,
          height: 8,
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.geometry.isAvailable, isFalse);
      expect(
        frame.cameraPose.geometry.diagnostics
            .map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraTargetStagePointOutOfMap,
        ),
      );
    });

    test('V1-133 reset and hold do not expose target geometry', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_reset_hold',
          title: 'Camera reset hold',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_reset',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'reset',
                },
              ),
              CinematicTimelineStep(
                id: 'camera_hold',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
              ),
            ],
          ),
        ),
        stageBounds: const CinematicPreviewPlaybackStageBounds(
          width: 10,
          height: 8,
        ),
      );

      expect(plan.frameAt(250).cameraPose.geometry.isAvailable, isFalse);
      expect(plan.frameAt(750).cameraPose.geometry.isAvailable, isFalse);
    });

    test('V1-133 invalid camera metadata remains diagnostic and non-crashing',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_invalid_focus',
          title: 'Camera invalid focus',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_focus',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'focus',
                  cinematicTimelineCameraTargetKindMetadataKey: 'orbital',
                  cinematicTimelineCameraZoomPresetMetadataKey: 'macro',
                },
              ),
            ],
          ),
        ),
      );

      final frame = plan.frameAt(250);

      expect(frame.cameraPose.isActive, isTrue);
      expect(frame.cameraPose.geometry.isAvailable, isFalse);
      expect(
        frame.cameraPose.geometry.diagnostics
            .map((diagnostic) => diagnostic.code),
        containsAll([
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraTargetKindUnsupported,
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraZoomPresetUnsupported,
        ]),
      );
    });

    test('V1-123 missing camera mode stays diagnosed and does not mutate asset',
        () {
      final cinematic = CinematicAsset(
        id: 'cinematic_camera_missing_mode',
        title: 'Camera missing mode cinematic',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'camera_missing_mode',
              kind: CinematicTimelineStepKind.camera,
              durationMs: 500,
            ),
          ],
        ),
      );
      final before = cinematic.toJson();

      final plan = buildCinematicPreviewPlaybackPlan(cinematic: cinematic);
      final frame = plan.frameAt(250);

      expect(frame.cameraPose.isActive, isTrue);
      expect(frame.cameraPose.isSupported, isFalse);
      expect(frame.cameraPose.activeStepId, 'camera_missing_mode');
      expect(frame.cameraPose.progress, closeTo(0.5, 0.001));
      expect(
        frame.cameraPose.diagnostics.single.message,
        'Cadrage caméra incomplet.',
      );
      expect(cinematic.toJson(), before);
    });

    test('V1-123 consecutive camera steps choose deterministic active state',
        () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_camera_consecutive',
          title: 'Camera consecutive cinematic',
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'camera_reset',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 400,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'reset',
                },
              ),
              CinematicTimelineStep(
                id: 'camera_hold',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 600,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
              ),
            ],
          ),
        ),
      );

      final beforeBoundary = plan.frameAt(399).cameraPose;
      final atBoundary = plan.frameAt(400).cameraPose;
      final nearEnd = plan.frameAt(999).cameraPose;
      final afterEnd = plan.frameAt(1000).cameraPose;

      expect(beforeBoundary.activeStepId, 'camera_reset');
      expect(beforeBoundary.mode, CinematicTimelineCameraMode.reset);
      expect(beforeBoundary.progress, closeTo(0.9975, 0.001));
      expect(atBoundary.activeStepId, 'camera_hold');
      expect(atBoundary.mode, CinematicTimelineCameraMode.hold);
      expect(atBoundary.progress, 0);
      expect(nearEnd.activeStepId, 'camera_hold');
      expect(nearEnd.progress, closeTo(0.998, 0.001));
      expect(afterEnd.isActive, isFalse);
    });

    test('fade returns fade state alongside camera playback state', () {
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
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
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
      expect(cameraFrame.cameraPose.isActive, isTrue);
      expect(cameraFrame.cameraPose.isSupported, isTrue);
      expect(cameraFrame.cameraPose.mode, CinematicTimelineCameraMode.hold);
      expect(plan.capabilities.supportsFade, isTrue);
      expect(plan.capabilities.supportsCamera, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isFalse);
      expect(
        cameraFrame.visibleDiagnostics.map((diagnostic) => diagnostic.code),
        isNot(
          contains(
            CinematicPreviewPlaybackDiagnosticCode
                .cinematicPreviewPlaybackCameraUnsupported,
          ),
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

    test('V1-127 actorEmote exposes active emote playback state', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_emote',
          title: 'Emote cinematic',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          timeline: CinematicTimeline(
            steps: [
              _actorEmoteStep(
                id: 'emote',
                actorId: 'actor_lysa',
                emoteId: cinematicDefaultActorEmoteId,
                durationMs: 800,
              ),
            ],
          ),
        ),
      );

      final startFrame = plan.frameAt(0);
      final midFrame = plan.frameAt(400);
      final nearEndFrame = plan.frameAt(799);
      final endFrame = plan.frameAt(800);

      expect(
          plan.timelineItems.single.kind, CinematicTimelineStepKind.actorEmote);
      expect(plan.timelineItems.single.supported, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isFalse);
      expect(startFrame.activeStepIds, ['emote']);
      expect(startFrame.activeEmotes, hasLength(1));
      expect(startFrame.activeEmotes.single.activeStepId, 'emote');
      expect(startFrame.activeEmotes.single.actorId, 'actor_lysa');
      expect(startFrame.activeEmotes.single.actorLabel, 'Lysa');
      expect(
        startFrame.activeEmotes.single.emoteId,
        cinematicDefaultActorEmoteId,
      );
      expect(startFrame.activeEmotes.single.emoteLabel, 'Surprise');
      expect(startFrame.activeEmotes.single.progress, 0);
      expect(startFrame.activeEmotes.single.isSupported, isTrue);
      expect(startFrame.activeEmotes.single.supported, isTrue);
      expect(startFrame.activeEmotes.single.diagnostics, isEmpty);
      expect(midFrame.activeEmotes.single.progress, closeTo(0.5, 0.001));
      expect(nearEndFrame.activeEmotes.single.progress, closeTo(0.998, 0.002));
      expect(endFrame.activeStepIds, isEmpty);
      expect(endFrame.activeEmotes, isEmpty);
      expect(startFrame.actorPoseById('actor_lysa'), isNotNull);
    });

    test('V1-127 actorEmote exposes unsupported diagnostics locally', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_emote_invalid',
          title: 'Invalid emotes',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          timeline: CinematicTimeline(
            steps: [
              _actorEmoteStep(
                id: 'missing_actor',
                actorId: null,
                emoteId: cinematicDefaultActorEmoteId,
                durationMs: 300,
              ),
              _actorEmoteStep(
                id: 'unknown_actor',
                actorId: 'actor_missing',
                emoteId: cinematicDefaultActorEmoteId,
                durationMs: 300,
              ),
              _actorEmoteStep(
                id: 'missing_emote',
                actorId: 'actor_lysa',
                emoteId: null,
                durationMs: 300,
              ),
              _actorEmoteStep(
                id: 'unknown_emote',
                actorId: 'actor_lysa',
                emoteId: 'missing_emote',
                durationMs: 300,
              ),
              _actorEmoteStep(
                id: 'invalid_duration',
                actorId: 'actor_lysa',
                emoteId: cinematicDefaultActorEmoteId,
                durationMs: 0,
              ),
            ],
          ),
        ),
      );

      expect(plan.capabilities.hasUnsupportedSteps, isTrue);
      expect(plan.timelineItems.every((item) => item.supported), isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackEmoteActorMissing,
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackEmoteActorUnknown,
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackEmoteMissing,
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackEmoteUnknown,
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackZeroDurationStep,
        ]),
      );

      final missingActor = plan.frameAt(0).activeEmotes.single;
      expect(missingActor.activeStepId, 'missing_actor');
      expect(missingActor.actorId, isNull);
      expect(missingActor.emoteId, cinematicDefaultActorEmoteId);
      expect(missingActor.isSupported, isFalse);
      expect(
        missingActor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackEmoteActorMissing,
        ),
      );

      final unknownActor = plan.frameAt(350).activeEmotes.single;
      expect(unknownActor.activeStepId, 'unknown_actor');
      expect(unknownActor.actorId, 'actor_missing');
      expect(unknownActor.emoteLabel, 'Surprise');
      expect(unknownActor.isSupported, isFalse);

      final missingEmote = plan.frameAt(650).activeEmotes.single;
      expect(missingEmote.activeStepId, 'missing_emote');
      expect(missingEmote.actorId, 'actor_lysa');
      expect(missingEmote.emoteId, isNull);
      expect(missingEmote.isSupported, isFalse);

      final unknownEmote = plan.frameAt(950).activeEmotes.single;
      expect(unknownEmote.activeStepId, 'unknown_emote');
      expect(unknownEmote.emoteId, 'missing_emote');
      expect(unknownEmote.emoteLabel, isNull);
      expect(unknownEmote.isSupported, isFalse);

      final invalidDuration = plan.frameAt(1250).activeEmotes.single;
      expect(invalidDuration.activeStepId, 'invalid_duration');
      expect(invalidDuration.durationMs,
          cinematicTimelineFallbackVisualDurationMs);
      expect(invalidDuration.isSupported, isFalse);
      expect(
        invalidDuration.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackZeroDurationStep,
        ),
      );
    });

    test('V1-127 active emotes stay deterministic in mixed timelines', () {
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: CinematicAsset(
          id: 'cinematic_emote_mixed',
          title: 'Mixed emotes',
          requiredActors: [
            CinematicActorRef(actorId: 'actor_lysa', label: 'Lysa'),
          ],
          timeline: CinematicTimeline(
            steps: [
              _actorEmoteStep(
                id: 'emote_question',
                actorId: 'actor_lysa',
                emoteId: 'question',
                durationMs: 200,
              ),
              _actorEmoteStep(
                id: 'emote_heart',
                actorId: 'actor_lysa',
                emoteId: 'heart',
                durationMs: 200,
              ),
              CinematicTimelineStep(
                id: 'fade_out',
                kind: CinematicTimelineStepKind.fade,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineFadeModeMetadataKey: 'fadeOut',
                },
              ),
              CinematicTimelineStep(
                id: 'camera_hold',
                kind: CinematicTimelineStepKind.camera,
                durationMs: 500,
                metadata: const {
                  cinematicTimelineCameraModeMetadataKey: 'hold',
                },
              ),
            ],
          ),
        ),
      );

      final firstFrame = plan.frameAt(100);
      final secondFrame = plan.frameAt(250);
      final repeatedSecondFrame = plan.frameAt(250);
      final fadeFrame = plan.frameAt(450);
      final cameraFrame = plan.frameAt(950);

      expect(firstFrame.activeEmotes.single.emoteId, 'question');
      expect(secondFrame.activeEmotes.single.emoteId, 'heart');
      expect(repeatedSecondFrame.activeEmotes, secondFrame.activeEmotes);
      expect(fadeFrame.activeEmotes, isEmpty);
      expect(fadeFrame.fadeState, isNotNull);
      expect(cameraFrame.activeEmotes, isEmpty);
      expect(cameraFrame.cameraPose.isActive, isTrue);
      expect(plan.capabilities.hasUnsupportedSteps, isFalse);
    });
  });
}

CinematicAsset _directMoveCinematic({
  List<CinematicMovementTargetRef>? movementTargets,
  List<CinematicMovementTargetBinding>? movementTargetBindings,
  List<CinematicTimelineStep>? steps,
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
      steps: steps ??
          [
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

CinematicTimelineStep _actorEmoteStep({
  required String id,
  required String? actorId,
  required String? emoteId,
  required int durationMs,
}) {
  final metadata = {
    cinematicTimelineDraftMetadataKindKey:
        cinematicTimelineBasicBlockMetadataKindValue,
    cinematicTimelineDraftMetadataSourceKey:
        cinematicTimelineDraftMetadataSourceValue,
    cinematicTimelineAuthoringBlockMetadataKey:
        cinematicTimelineActorEmoteBlockMetadataValue,
    if (emoteId != null) cinematicTimelineActorEmoteEmoteIdMetadataKey: emoteId,
  };
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.actorEmote,
    label: 'Émotion',
    actorId: actorId,
    durationMs: durationMs,
    metadata: metadata,
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

CinematicTimelineStep _cameraFocusStep({
  required String id,
  required CinematicCameraTargetBinding target,
  required CinematicCameraZoomPreset zoomPreset,
  int durationMs = 500,
}) {
  final metadata = <String, String>{
    cinematicTimelineCameraModeMetadataKey:
        CinematicTimelineCameraMode.focus.name,
    cinematicTimelineCameraTargetKindMetadataKey: target.kind.name,
    cinematicTimelineCameraZoomPresetMetadataKey: zoomPreset.name,
    if (target.actorId != null)
      cinematicTimelineCameraTargetActorIdMetadataKey: target.actorId!,
    if (target.stagePointId != null)
      cinematicTimelineCameraTargetStagePointIdMetadataKey:
          target.stagePointId!,
  };
  return CinematicTimelineStep(
    id: id,
    kind: CinematicTimelineStepKind.camera,
    durationMs: durationMs,
    metadata: metadata,
  );
}

CinematicStagePoint _point(String id, double x, double y) {
  return CinematicStagePoint(id: id, label: id, x: x, y: y);
}

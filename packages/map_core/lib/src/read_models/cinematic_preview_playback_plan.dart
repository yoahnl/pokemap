import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../authoring/cinematic_authoring_operations.dart';
import '../models/cinematic_asset.dart';
import '../models/cinematic_emote_catalog.dart';
import 'cinematic_actor_display_preview_model.dart';
import 'cinematic_timeline_time_layout_read_model.dart';

enum CinematicPreviewPlaybackDiagnosticSeverity {
  info,
  warning,
  error,
}

enum CinematicPreviewPlaybackDiagnosticCode {
  cinematicPreviewPlaybackUnsupportedStep,
  cinematicPreviewPlaybackActorMissing,
  cinematicPreviewPlaybackActorInitialPoseMissing,
  cinematicPreviewPlaybackMoveDestinationMissing,
  cinematicPreviewPlaybackManualPathMissing,
  cinematicPreviewPlaybackManualPathPointMissing,
  cinematicPreviewPlaybackManualPathZeroLength,
  cinematicPreviewPlaybackZeroDurationStep,
  cinematicPreviewPlaybackTimelineEmpty,
  cinematicPreviewPlaybackStageContextMissing,
  cinematicPreviewPlaybackMapUnavailable,
  cinematicPreviewPlaybackCameraUnsupported,
  cinematicPreviewPlaybackCameraTargetMissing,
  cinematicPreviewPlaybackCameraTargetKindUnsupported,
  cinematicPreviewPlaybackCameraTargetActorMissing,
  cinematicPreviewPlaybackCameraTargetActorUnknown,
  cinematicPreviewPlaybackCameraTargetActorWithoutPosition,
  cinematicPreviewPlaybackCameraTargetStagePointMissing,
  cinematicPreviewPlaybackCameraTargetStagePointUnknown,
  cinematicPreviewPlaybackCameraTargetStagePointOutOfMap,
  cinematicPreviewPlaybackCameraTargetStageMapMissing,
  cinematicPreviewPlaybackCameraZoomPresetMissing,
  cinematicPreviewPlaybackCameraZoomPresetUnsupported,
  cinematicPreviewPlaybackFadeUnsupported,
  cinematicPreviewPlaybackEmoteActorMissing,
  cinematicPreviewPlaybackEmoteActorUnknown,
  cinematicPreviewPlaybackEmoteMissing,
  cinematicPreviewPlaybackEmoteUnknown,
}

enum CinematicActorPlaybackPoseSource {
  actorDisplay,
  initialPlacement,
  actorFace,
  actorMoveDirect,
  actorMoveManualPath,
  missing,
}

enum CinematicPreviewPlaybackPointSource {
  actorDisplay,
  initialPlacement,
  stagePoint,
  resolvedMovementTarget,
}

enum CinematicFadePlaybackMode {
  fadeIn,
  fadeOut,
  unknown,
}

@immutable
final class CinematicPreviewPlaybackDiagnostic {
  CinematicPreviewPlaybackDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.stepId,
    this.actorId,
    this.timeMs,
    bool? blocking,
  }) : blocking = blocking ??
            severity == CinematicPreviewPlaybackDiagnosticSeverity.error;

  final CinematicPreviewPlaybackDiagnosticCode code;
  final CinematicPreviewPlaybackDiagnosticSeverity severity;
  final String message;
  final String? stepId;
  final String? actorId;
  final int? timeMs;
  final bool blocking;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.stepId == stepId &&
          other.actorId == actorId &&
          other.timeMs == timeMs &&
          other.blocking == blocking;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        stepId,
        actorId,
        timeMs,
        blocking,
      );
}

@immutable
final class CinematicPreviewPlaybackCapabilities {
  const CinematicPreviewPlaybackCapabilities({
    required this.supportsActorMoveDirect,
    required this.supportsActorMoveManualPath,
    required this.supportsActorFace,
    required this.supportsWait,
    required this.supportsFade,
    required this.supportsCamera,
    required this.hasUnsupportedSteps,
  });

  final bool supportsActorMoveDirect;
  final bool supportsActorMoveManualPath;
  final bool supportsActorFace;
  final bool supportsWait;
  final bool supportsFade;
  final bool supportsCamera;
  final bool hasUnsupportedSteps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackCapabilities &&
          other.supportsActorMoveDirect == supportsActorMoveDirect &&
          other.supportsActorMoveManualPath == supportsActorMoveManualPath &&
          other.supportsActorFace == supportsActorFace &&
          other.supportsWait == supportsWait &&
          other.supportsFade == supportsFade &&
          other.supportsCamera == supportsCamera &&
          other.hasUnsupportedSteps == hasUnsupportedSteps;

  @override
  int get hashCode => Object.hash(
        supportsActorMoveDirect,
        supportsActorMoveManualPath,
        supportsActorFace,
        supportsWait,
        supportsFade,
        supportsCamera,
        hasUnsupportedSteps,
      );
}

@immutable
final class CinematicPreviewPlaybackPoint {
  const CinematicPreviewPlaybackPoint({
    required this.x,
    required this.y,
    required this.source,
    this.sourceId,
  });

  final double x;
  final double y;
  final CinematicPreviewPlaybackPointSource source;
  final String? sourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackPoint &&
          other.x == x &&
          other.y == y &&
          other.source == source &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(x, y, source, sourceId);
}

@immutable
final class CinematicPreviewPlaybackStageBounds {
  const CinematicPreviewPlaybackStageBounds({
    required this.width,
    required this.height,
  })  : assert(width > 0),
        assert(height > 0);

  final double width;
  final double height;

  double get centerX => width / 2;
  double get centerY => height / 2;

  bool containsPoint(double x, double y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackStageBounds &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

@immutable
final class CinematicActorPlaybackPose {
  const CinematicActorPlaybackPose({
    required this.actorId,
    this.actorLabel,
    this.x,
    this.y,
    required this.facing,
    required this.source,
    required this.isInterpolated,
    this.activeStepId,
  });

  final String actorId;
  final String? actorLabel;
  final double? x;
  final double? y;
  final CinematicActorPreviewDirection facing;
  final CinematicActorPlaybackPoseSource source;
  final bool isInterpolated;
  final String? activeStepId;

  bool get hasPosition => x != null && y != null;

  CinematicActorPlaybackPose copyWith({
    double? x,
    double? y,
    CinematicActorPreviewDirection? facing,
    CinematicActorPlaybackPoseSource? source,
    bool? isInterpolated,
    String? activeStepId,
    bool clearActiveStepId = false,
  }) {
    return CinematicActorPlaybackPose(
      actorId: actorId,
      actorLabel: actorLabel,
      x: x ?? this.x,
      y: y ?? this.y,
      facing: facing ?? this.facing,
      source: source ?? this.source,
      isInterpolated: isInterpolated ?? this.isInterpolated,
      activeStepId:
          clearActiveStepId ? null : activeStepId ?? this.activeStepId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorPlaybackPose &&
          other.actorId == actorId &&
          other.actorLabel == actorLabel &&
          other.x == x &&
          other.y == y &&
          other.facing == facing &&
          other.source == source &&
          other.isInterpolated == isInterpolated &&
          other.activeStepId == activeStepId;

  @override
  int get hashCode => Object.hash(
        actorId,
        actorLabel,
        x,
        y,
        facing,
        source,
        isInterpolated,
        activeStepId,
      );
}

@immutable
final class CinematicPreviewActorTrack {
  CinematicPreviewActorTrack({
    required this.actorId,
    this.actorLabel,
    required this.initialPose,
    required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  final String actorId;
  final String? actorLabel;
  final CinematicActorPlaybackPose initialPose;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewActorTrack &&
          other.actorId == actorId &&
          other.actorLabel == actorLabel &&
          other.initialPose == initialPose &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        actorId,
        actorLabel,
        initialPose,
        Object.hashAll(diagnostics),
      );
}

@immutable
final class CinematicPreviewPlaybackTimelineItem {
  CinematicPreviewPlaybackTimelineItem({
    required this.stepId,
    required this.stepIndex,
    required this.kind,
    required this.label,
    required this.startMs,
    required this.endMs,
    this.durationMs,
    required this.visualDurationMs,
    required this.durationSource,
    this.actorId,
    this.actorLabel,
    this.targetId,
    this.targetLabel,
    required this.supported,
    required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  final String stepId;
  final int stepIndex;
  final CinematicTimelineStepKind kind;
  final String label;
  final int startMs;
  final int endMs;
  final int? durationMs;
  final int visualDurationMs;
  final CinematicTimelineVisualDurationSource durationSource;
  final String? actorId;
  final String? actorLabel;
  final String? targetId;
  final String? targetLabel;
  final bool supported;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  bool containsTime(int timeMs) => startMs <= timeMs && timeMs < endMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackTimelineItem &&
          other.stepId == stepId &&
          other.stepIndex == stepIndex &&
          other.kind == kind &&
          other.label == label &&
          other.startMs == startMs &&
          other.endMs == endMs &&
          other.durationMs == durationMs &&
          other.visualDurationMs == visualDurationMs &&
          other.durationSource == durationSource &&
          other.actorId == actorId &&
          other.actorLabel == actorLabel &&
          other.targetId == targetId &&
          other.targetLabel == targetLabel &&
          other.supported == supported &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        stepId,
        stepIndex,
        kind,
        label,
        startMs,
        endMs,
        durationMs,
        visualDurationMs,
        durationSource,
        actorId,
        actorLabel,
        targetId,
        targetLabel,
        supported,
        Object.hashAll(diagnostics),
      );
}

@immutable
final class CinematicFadePlaybackState {
  const CinematicFadePlaybackState({
    required this.opacity,
    required this.mode,
    this.activeStepId,
  });

  final double opacity;
  final CinematicFadePlaybackMode mode;
  final String? activeStepId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicFadePlaybackState &&
          other.opacity == opacity &&
          other.mode == mode &&
          other.activeStepId == activeStepId;

  @override
  int get hashCode => Object.hash(opacity, mode, activeStepId);
}

@immutable
final class CinematicCameraPlaybackGeometry {
  CinematicCameraPlaybackGeometry.available({
    required this.targetKind,
    required this.targetLabel,
    this.actorId,
    this.stagePointId,
    required this.centerX,
    required this.centerY,
    required this.zoomPreset,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  })  : isAvailable = true,
        diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  CinematicCameraPlaybackGeometry.unavailable({
    this.targetKind,
    this.targetLabel,
    this.actorId,
    this.stagePointId,
    this.zoomPreset,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  })  : isAvailable = false,
        centerX = null,
        centerY = null,
        diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  const CinematicCameraPlaybackGeometry.none()
      : isAvailable = false,
        targetKind = null,
        targetLabel = null,
        actorId = null,
        stagePointId = null,
        centerX = null,
        centerY = null,
        zoomPreset = null,
        diagnostics = const <CinematicPreviewPlaybackDiagnostic>[];

  final bool isAvailable;
  final CinematicCameraTargetKind? targetKind;
  final String? targetLabel;
  final String? actorId;
  final String? stagePointId;
  final double? centerX;
  final double? centerY;
  final CinematicCameraZoomPreset? zoomPreset;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicCameraPlaybackGeometry &&
          other.isAvailable == isAvailable &&
          other.targetKind == targetKind &&
          other.targetLabel == targetLabel &&
          other.actorId == actorId &&
          other.stagePointId == stagePointId &&
          other.centerX == centerX &&
          other.centerY == centerY &&
          other.zoomPreset == zoomPreset &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        isAvailable,
        targetKind,
        targetLabel,
        actorId,
        stagePointId,
        centerX,
        centerY,
        zoomPreset,
        Object.hashAll(diagnostics),
      );
}

@immutable
final class CinematicCameraPlaybackPose {
  CinematicCameraPlaybackPose({
    required this.isActive,
    required this.isSupported,
    required this.progress,
    this.activeStepId,
    this.mode,
    this.geometry = const CinematicCameraPlaybackGeometry.none(),
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  const CinematicCameraPlaybackPose.inactive()
      : isActive = false,
        isSupported = false,
        progress = 0,
        activeStepId = null,
        mode = null,
        geometry = const CinematicCameraPlaybackGeometry.none(),
        diagnostics = const <CinematicPreviewPlaybackDiagnostic>[];

  final bool isActive;
  final bool isSupported;
  final String? activeStepId;
  final CinematicTimelineCameraMode? mode;
  final double progress;
  final CinematicCameraPlaybackGeometry geometry;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  bool get supported => isSupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicCameraPlaybackPose &&
          other.isActive == isActive &&
          other.isSupported == isSupported &&
          other.activeStepId == activeStepId &&
          other.mode == mode &&
          other.progress == progress &&
          other.geometry == geometry &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        isActive,
        isSupported,
        activeStepId,
        mode,
        progress,
        geometry,
        Object.hashAll(diagnostics),
      );
}

@immutable
final class CinematicActorEmotePlaybackState {
  CinematicActorEmotePlaybackState({
    required this.activeStepId,
    required this.stepIndex,
    required this.actorId,
    this.actorLabel,
    required this.emoteId,
    this.emoteLabel,
    required this.durationMs,
    required this.elapsedMs,
    required this.progress,
    required this.isSupported,
    List<CinematicPreviewPlaybackDiagnostic> diagnostics = const [],
  }) : diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics);

  final String activeStepId;
  final int stepIndex;
  final String? actorId;
  final String? actorLabel;
  final String? emoteId;
  final String? emoteLabel;
  final int durationMs;
  final int elapsedMs;
  final double progress;
  final bool isSupported;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;

  bool get supported => isSupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicActorEmotePlaybackState &&
          other.activeStepId == activeStepId &&
          other.stepIndex == stepIndex &&
          other.actorId == actorId &&
          other.actorLabel == actorLabel &&
          other.emoteId == emoteId &&
          other.emoteLabel == emoteLabel &&
          other.durationMs == durationMs &&
          other.elapsedMs == elapsedMs &&
          other.progress == progress &&
          other.isSupported == isSupported &&
          _listEquals(other.diagnostics, diagnostics);

  @override
  int get hashCode => Object.hash(
        activeStepId,
        stepIndex,
        actorId,
        actorLabel,
        emoteId,
        emoteLabel,
        durationMs,
        elapsedMs,
        progress,
        isSupported,
        Object.hashAll(diagnostics),
      );
}

@immutable
final class CinematicPreviewPlaybackFrame {
  CinematicPreviewPlaybackFrame({
    required this.timeMs,
    required this.clampedTimeMs,
    required List<String> activeStepIds,
    required List<CinematicActorPlaybackPose> actorPoses,
    List<CinematicActorEmotePlaybackState> activeEmotes = const [],
    this.fadeState,
    CinematicCameraPlaybackPose? cameraPose,
    required List<CinematicPreviewPlaybackDiagnostic> visibleDiagnostics,
  })  : activeStepIds = List<String>.unmodifiable(activeStepIds),
        actorPoses = List<CinematicActorPlaybackPose>.unmodifiable(actorPoses),
        activeEmotes =
            List<CinematicActorEmotePlaybackState>.unmodifiable(activeEmotes),
        cameraPose = cameraPose ?? const CinematicCameraPlaybackPose.inactive(),
        visibleDiagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(
          visibleDiagnostics,
        );

  final int timeMs;
  final int clampedTimeMs;
  final List<String> activeStepIds;
  final List<CinematicActorPlaybackPose> actorPoses;
  final List<CinematicActorEmotePlaybackState> activeEmotes;
  final CinematicFadePlaybackState? fadeState;
  final CinematicCameraPlaybackPose cameraPose;
  final List<CinematicPreviewPlaybackDiagnostic> visibleDiagnostics;

  CinematicActorPlaybackPose? actorPoseById(String actorId) {
    final normalizedId = actorId.trim();
    for (final pose in actorPoses) {
      if (pose.actorId == normalizedId) {
        return pose;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicPreviewPlaybackFrame &&
          other.timeMs == timeMs &&
          other.clampedTimeMs == clampedTimeMs &&
          _listEquals(other.activeStepIds, activeStepIds) &&
          _listEquals(other.actorPoses, actorPoses) &&
          _listEquals(other.activeEmotes, activeEmotes) &&
          other.fadeState == fadeState &&
          other.cameraPose == cameraPose &&
          _listEquals(other.visibleDiagnostics, visibleDiagnostics);

  @override
  int get hashCode => Object.hash(
        timeMs,
        clampedTimeMs,
        Object.hashAll(activeStepIds),
        Object.hashAll(actorPoses),
        Object.hashAll(activeEmotes),
        fadeState,
        cameraPose,
        Object.hashAll(visibleDiagnostics),
      );
}

@immutable
final class CinematicPreviewPlaybackPlan {
  CinematicPreviewPlaybackPlan._({
    required this.cinematicId,
    required this.totalDurationMs,
    required List<CinematicPreviewPlaybackTimelineItem> timelineItems,
    required List<CinematicPreviewActorTrack> actorTracks,
    required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
    required this.capabilities,
    required Map<String, _ActorMovePlaybackPlan> movePlans,
    required Map<String, CinematicActorPreviewDirection> actorFaceDirections,
    required Map<String, _ActorEmotePlaybackPlan> actorEmotePlans,
    required Map<String, CinematicFadePlaybackMode> fadeModes,
    required Map<String, CinematicTimelineCameraMode> cameraModes,
    required Map<String, CinematicTimelineCameraFocusBinding>
        cameraFocusBindings,
    required Map<String, CinematicStagePoint> stagePointsById,
    required CinematicPreviewPlaybackStageBounds? stageBounds,
  })  : timelineItems = List<CinematicPreviewPlaybackTimelineItem>.unmodifiable(
          timelineItems,
        ),
        actorTracks = List<CinematicPreviewActorTrack>.unmodifiable(
          actorTracks,
        ),
        diagnostics =
            List<CinematicPreviewPlaybackDiagnostic>.unmodifiable(diagnostics),
        _movePlans = Map<String, _ActorMovePlaybackPlan>.unmodifiable(
          movePlans,
        ),
        _actorFaceDirections =
            Map<String, CinematicActorPreviewDirection>.unmodifiable(
          actorFaceDirections,
        ),
        _actorEmotePlans = Map<String, _ActorEmotePlaybackPlan>.unmodifiable(
          actorEmotePlans,
        ),
        _fadeModes = Map<String, CinematicFadePlaybackMode>.unmodifiable(
          fadeModes,
        ),
        _cameraModes = Map<String, CinematicTimelineCameraMode>.unmodifiable(
          cameraModes,
        ),
        _cameraFocusBindings =
            Map<String, CinematicTimelineCameraFocusBinding>.unmodifiable(
          cameraFocusBindings,
        ),
        _stagePointsById = Map<String, CinematicStagePoint>.unmodifiable(
          stagePointsById,
        ),
        _stageBounds = stageBounds;

  final String cinematicId;
  final int totalDurationMs;
  final List<CinematicPreviewPlaybackTimelineItem> timelineItems;
  final List<CinematicPreviewActorTrack> actorTracks;
  final List<CinematicPreviewPlaybackDiagnostic> diagnostics;
  final CinematicPreviewPlaybackCapabilities capabilities;
  final Map<String, _ActorMovePlaybackPlan> _movePlans;
  final Map<String, CinematicActorPreviewDirection> _actorFaceDirections;
  final Map<String, _ActorEmotePlaybackPlan> _actorEmotePlans;
  final Map<String, CinematicFadePlaybackMode> _fadeModes;
  final Map<String, CinematicTimelineCameraMode> _cameraModes;
  final Map<String, CinematicTimelineCameraFocusBinding> _cameraFocusBindings;
  final Map<String, CinematicStagePoint> _stagePointsById;
  final CinematicPreviewPlaybackStageBounds? _stageBounds;

  CinematicPreviewPlaybackFrame frameAt(int timeMs) =>
      evaluateCinematicPreviewPlaybackFrame(this, timeMs: timeMs);
}

CinematicPreviewPlaybackPlan buildCinematicPreviewPlaybackPlan({
  required CinematicAsset cinematic,
  CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets = const {},
  CinematicPreviewPlaybackStageBounds? stageBounds,
}) {
  final timeLayout = buildCinematicTimelineTimeLayoutReadModel(cinematic);
  final stageContext = cinematic.stageContext;
  final diagnostics = <CinematicPreviewPlaybackDiagnostic>[];
  final actorTracks = <CinematicPreviewActorTrack>[];
  final stagePointsById = <String, CinematicStagePoint>{
    for (final point
        in stageContext?.stagePoints ?? const <CinematicStagePoint>[])
      point.id: point,
  };

  if (timeLayout.blocks.isEmpty) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackTimelineEmpty,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.info,
        message: 'La cinématique ne contient aucun bloc à lire.',
      ),
    );
  }

  if (stageContext == null && cinematic.requiredActors.isNotEmpty) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackStageContextMissing,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
        message: 'Le contexte de scène est absent pour cette cinématique.',
      ),
    );
  }

  for (final actor in cinematic.requiredActors) {
    final trackDiagnostics = <CinematicPreviewPlaybackDiagnostic>[];
    final initialPose = _initialPoseForActor(
      actor: actor,
      stageContext: stageContext,
      actorDisplayPreviewModel: actorDisplayPreviewModel,
      resolvedMovementTargets: resolvedMovementTargets,
      diagnostics: trackDiagnostics,
    );
    diagnostics.addAll(trackDiagnostics);
    actorTracks.add(
      CinematicPreviewActorTrack(
        actorId: actor.actorId,
        actorLabel: actor.label,
        initialPose: initialPose,
        diagnostics: trackDiagnostics,
      ),
    );
  }

  final actorTrackIds = {
    for (final track in actorTracks) track.actorId,
  };
  final movePlans = <String, _ActorMovePlaybackPlan>{};
  final faceDirections = <String, CinematicActorPreviewDirection>{};
  final emotePlans = <String, _ActorEmotePlaybackPlan>{};
  final fadeModes = <String, CinematicFadePlaybackMode>{};
  final cameraModes = <String, CinematicTimelineCameraMode>{};
  final cameraFocusBindings = <String, CinematicTimelineCameraFocusBinding>{};
  final timelineItems = <CinematicPreviewPlaybackTimelineItem>[];
  var hasUnsupportedSteps = false;

  for (final block in timeLayout.blocks) {
    final step = cinematic.timeline.steps[block.stepIndex];
    final itemDiagnostics = <CinematicPreviewPlaybackDiagnostic>[];
    var supported = _stepSupportedForPlayback(step);
    if (!supported) {
      hasUnsupportedSteps = true;
    }

    if (step.durationMs != null && step.durationMs! <= 0) {
      itemDiagnostics.add(
        CinematicPreviewPlaybackDiagnostic(
          code: CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackZeroDurationStep,
          severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
          message: 'Ce bloc utilise la durée de prévisualisation par défaut.',
          stepId: step.id,
        ),
      );
    }

    switch (step.kind) {
      case CinematicTimelineStepKind.actorFace:
        final direction = cinematicTimelineActorFacingDirectionOf(step);
        if (step.actorId == null || !actorTrackIds.contains(step.actorId)) {
          itemDiagnostics.add(_actorMissingDiagnostic(step));
        } else if (direction != null) {
          faceDirections[step.id] = _directionFromActorFace(direction);
        }
      case CinematicTimelineStepKind.actorMove:
        final plan = _buildActorMovePlan(
          step: step,
          stageContext: stageContext,
          actorTracks: actorTracks,
          actorTrackIds: actorTrackIds,
          resolvedMovementTargets: resolvedMovementTargets,
          diagnostics: itemDiagnostics,
        );
        movePlans[step.id] = plan;
      case CinematicTimelineStepKind.fade:
        final fadeMode = _fadeModeOf(step);
        if (fadeMode == CinematicFadePlaybackMode.unknown) {
          itemDiagnostics.add(
            CinematicPreviewPlaybackDiagnostic(
              code: CinematicPreviewPlaybackDiagnosticCode
                  .cinematicPreviewPlaybackFadeUnsupported,
              severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
              message: 'Ce fondu n’est pas encore prévisualisé.',
              stepId: step.id,
            ),
          );
          hasUnsupportedSteps = true;
        } else {
          fadeModes[step.id] = fadeMode;
        }
      case CinematicTimelineStepKind.camera:
        final cameraMode = _cameraModeOf(step);
        if (cameraMode == null) {
          itemDiagnostics.add(_cameraUnsupportedDiagnostic(step));
          hasUnsupportedSteps = true;
        } else {
          cameraModes[step.id] = cameraMode;
          if (cameraMode == CinematicTimelineCameraMode.focus) {
            final focusBinding = cinematicTimelineCameraFocusBindingOf(step);
            if (focusBinding != null) {
              cameraFocusBindings[step.id] = focusBinding;
            }
            itemDiagnostics.addAll(
              _cameraFocusStaticDiagnostics(step),
            );
            itemDiagnostics.add(_cameraUnsupportedDiagnostic(step));
            supported = false;
            hasUnsupportedSteps = true;
          }
        }
      case CinematicTimelineStepKind.wait:
        break;
      case CinematicTimelineStepKind.actorEmote:
        final plan = _buildActorEmotePlan(
          step: step,
          actorTracks: actorTracks,
          actorTrackIds: actorTrackIds,
          diagnostics: itemDiagnostics,
        );
        emotePlans[step.id] = plan;
        if (!plan.isSupported) {
          supported = false;
          hasUnsupportedSteps = true;
        }
        break;
      case CinematicTimelineStepKind.dialogueLine:
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.shake:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        itemDiagnostics.add(
          CinematicPreviewPlaybackDiagnostic(
            code: CinematicPreviewPlaybackDiagnosticCode
                .cinematicPreviewPlaybackUnsupportedStep,
            severity: CinematicPreviewPlaybackDiagnosticSeverity.info,
            message: 'Ce bloc n’est pas encore prévisualisé.',
            stepId: step.id,
          ),
        );
        hasUnsupportedSteps = true;
    }

    diagnostics.addAll(itemDiagnostics);
    timelineItems.add(
      CinematicPreviewPlaybackTimelineItem(
        stepId: block.stepId,
        stepIndex: block.stepIndex,
        kind: block.kind,
        label: block.label,
        startMs: block.startMs,
        endMs: block.endMs,
        durationMs: block.durationMs,
        visualDurationMs: block.visualDurationMs,
        durationSource: block.durationSource,
        actorId: block.actorId,
        actorLabel: block.actorLabel,
        targetId: block.targetId,
        targetLabel: block.targetLabel,
        supported: supported,
        diagnostics: itemDiagnostics,
      ),
    );
  }

  return CinematicPreviewPlaybackPlan._(
    cinematicId: cinematic.id,
    totalDurationMs: timeLayout.totalDurationMs,
    timelineItems: timelineItems,
    actorTracks: actorTracks,
    diagnostics: diagnostics,
    capabilities: CinematicPreviewPlaybackCapabilities(
      supportsActorMoveDirect: true,
      supportsActorMoveManualPath: true,
      supportsActorFace: true,
      supportsWait: true,
      supportsFade: true,
      supportsCamera: true,
      hasUnsupportedSteps: hasUnsupportedSteps,
    ),
    movePlans: movePlans,
    actorFaceDirections: faceDirections,
    actorEmotePlans: emotePlans,
    fadeModes: fadeModes,
    cameraModes: cameraModes,
    cameraFocusBindings: cameraFocusBindings,
    stagePointsById: stagePointsById,
    stageBounds: stageBounds,
  );
}

CinematicPreviewPlaybackFrame evaluateCinematicPreviewPlaybackFrame(
  CinematicPreviewPlaybackPlan plan, {
  required int timeMs,
}) {
  final clampedTimeMs = timeMs.clamp(0, plan.totalDurationMs).toInt();
  final activeStepIds = [
    for (final item in plan.timelineItems)
      if (item.containsTime(clampedTimeMs)) item.stepId,
  ];
  final posesByActorId = <String, CinematicActorPlaybackPose>{
    for (final track in plan.actorTracks) track.actorId: track.initialPose,
  };

  CinematicFadePlaybackState? fadeState;
  var cameraPose = const CinematicCameraPlaybackPose.inactive();
  final activeEmotes = <CinematicActorEmotePlaybackState>[];

  for (final item in plan.timelineItems) {
    if (clampedTimeMs < item.startMs) {
      break;
    }
    switch (item.kind) {
      case CinematicTimelineStepKind.actorFace:
        final direction = plan._actorFaceDirections[item.stepId];
        final actorId = item.actorId;
        if (direction != null && actorId != null) {
          final current = posesByActorId[actorId];
          if (current != null) {
            posesByActorId[actorId] = current.copyWith(
              facing: direction,
              source: CinematicActorPlaybackPoseSource.actorFace,
              isInterpolated: false,
              activeStepId: item.stepId,
            );
          }
        }
      case CinematicTimelineStepKind.actorMove:
        final movePlan = plan._movePlans[item.stepId];
        if (movePlan == null) {
          break;
        }
        final current = posesByActorId[movePlan.actorId];
        if (current == null) {
          break;
        }
        final next = _poseForMove(
          current: current,
          movePlan: movePlan,
          item: item,
          clampedTimeMs: clampedTimeMs,
        );
        posesByActorId[movePlan.actorId] = next;
      case CinematicTimelineStepKind.fade:
        if (item.containsTime(clampedTimeMs)) {
          final mode = plan._fadeModes[item.stepId];
          if (mode != null) {
            fadeState = _fadeStateFor(
              item: item,
              mode: mode,
              clampedTimeMs: clampedTimeMs,
            );
          }
        }
      case CinematicTimelineStepKind.camera:
        if (item.containsTime(clampedTimeMs)) {
          cameraPose = _cameraPoseFor(
            item: item,
            mode: plan._cameraModes[item.stepId],
            focusBinding: plan._cameraFocusBindings[item.stepId],
            actorPosesById: posesByActorId,
            stagePointsById: plan._stagePointsById,
            stageBounds: plan._stageBounds,
            clampedTimeMs: clampedTimeMs,
          );
        }
      case CinematicTimelineStepKind.wait:
      case CinematicTimelineStepKind.actorEmote:
        if (item.containsTime(clampedTimeMs)) {
          activeEmotes.add(
            _emotePlaybackStateFor(
              item: item,
              plan: plan._actorEmotePlans[item.stepId],
              clampedTimeMs: clampedTimeMs,
            ),
          );
        }
        break;
      case CinematicTimelineStepKind.dialogueLine:
      case CinematicTimelineStepKind.sound:
      case CinematicTimelineStepKind.music:
      case CinematicTimelineStepKind.shake:
      case CinematicTimelineStepKind.fx:
      case CinematicTimelineStepKind.marker:
        break;
    }
  }

  return CinematicPreviewPlaybackFrame(
    timeMs: timeMs,
    clampedTimeMs: clampedTimeMs,
    activeStepIds: activeStepIds,
    actorPoses: posesByActorId.values.toList(),
    activeEmotes: activeEmotes,
    fadeState: fadeState,
    cameraPose: cameraPose,
    visibleDiagnostics: plan.diagnostics,
  );
}

CinematicActorPlaybackPose _initialPoseForActor({
  required CinematicActorRef actor,
  required CinematicStageContext? stageContext,
  required CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
  required Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets,
  required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
}) {
  final displayActor = actorDisplayPreviewModel?.actorById(actor.actorId);
  final displayPosition = displayActor?.position;
  if (displayPosition != null &&
      displayPosition.isResolved &&
      displayPosition.x != null &&
      displayPosition.y != null) {
    return CinematicActorPlaybackPose(
      actorId: actor.actorId,
      actorLabel: displayActor?.label ?? actor.label,
      x: displayPosition.x!.toDouble(),
      y: displayPosition.y!.toDouble(),
      facing: displayActor?.direction ?? CinematicActorPreviewDirection.unknown,
      source: CinematicActorPlaybackPoseSource.actorDisplay,
      isInterpolated: false,
    );
  }

  CinematicPreviewPlaybackPoint? point;
  if (stageContext != null) {
    final placement = _placementFor(stageContext, actor.actorId);
    if (placement != null) {
      point = switch (placement.kind) {
        CinematicActorInitialPlacementKind.stagePoint => _stagePointById(
            stageContext,
            placement.stagePointId,
          ),
        CinematicActorInitialPlacementKind.fromMovementTarget =>
          _movementTargetPoint(
            stageContext: stageContext,
            targetId: placement.targetId,
            resolvedMovementTargets: resolvedMovementTargets,
          ),
        CinematicActorInitialPlacementKind.unset ||
        CinematicActorInitialPlacementKind.fromMapEntity =>
          null,
      };
    }
  }

  final facing =
      displayActor?.direction ?? CinematicActorPreviewDirection.unknown;
  if (point != null) {
    return CinematicActorPlaybackPose(
      actorId: actor.actorId,
      actorLabel: displayActor?.label ?? actor.label,
      x: point.x,
      y: point.y,
      facing: facing,
      source: CinematicActorPlaybackPoseSource.initialPlacement,
      isInterpolated: false,
    );
  }

  diagnostics.add(
    CinematicPreviewPlaybackDiagnostic(
      code: CinematicPreviewPlaybackDiagnosticCode
          .cinematicPreviewPlaybackActorInitialPoseMissing,
      severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
      message: 'Cet acteur n’a pas de position de départ.',
      actorId: actor.actorId,
    ),
  );
  return CinematicActorPlaybackPose(
    actorId: actor.actorId,
    actorLabel: displayActor?.label ?? actor.label,
    facing: facing,
    source: CinematicActorPlaybackPoseSource.missing,
    isInterpolated: false,
  );
}

_ActorMovePlaybackPlan _buildActorMovePlan({
  required CinematicTimelineStep step,
  required CinematicStageContext? stageContext,
  required List<CinematicPreviewActorTrack> actorTracks,
  required Set<String> actorTrackIds,
  required Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets,
  required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
}) {
  final actorId = step.actorId;
  if (actorId == null || !actorTrackIds.contains(actorId)) {
    diagnostics.add(_actorMissingDiagnostic(step));
  }

  final pathMode = cinematicTimelineActorPathModeOf(step) ??
      CinematicTimelineActorPathMode.direct;
  final destination = stageContext == null
      ? resolvedMovementTargets[step.targetId]
      : _movementTargetPoint(
          stageContext: stageContext,
          targetId: step.targetId,
          resolvedMovementTargets: resolvedMovementTargets,
        );

  if (destination == null) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackMoveDestinationMissing,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message:
            'Impossible de prévisualiser ce déplacement : la destination est introuvable.',
        stepId: step.id,
        actorId: actorId,
      ),
    );
  }

  if (pathMode == CinematicTimelineActorPathMode.direct) {
    return _ActorMovePlaybackPlan(
      stepId: step.id,
      actorId: actorId ?? '',
      pathMode: pathMode,
      destination: destination,
      waypoints: const [],
    );
  }

  final waypoints = <CinematicPreviewPlaybackPoint>[];
  CinematicManualPath? manualPath;
  if (stageContext != null) {
    for (final candidate in stageContext.manualPaths) {
      if (candidate.ownerActorMoveStepId == step.id) {
        manualPath = candidate;
        break;
      }
    }
  }

  if (manualPath == null) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackManualPathMissing,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message: 'Ce déplacement manuel n’a pas de trajet à lire.',
        stepId: step.id,
        actorId: actorId,
      ),
    );
  } else if (stageContext != null) {
    for (final pointId in manualPath.waypointStagePointIds) {
      final point = _stagePointById(stageContext, pointId);
      if (point == null) {
        diagnostics.add(
          CinematicPreviewPlaybackDiagnostic(
            code: CinematicPreviewPlaybackDiagnosticCode
                .cinematicPreviewPlaybackManualPathPointMissing,
            severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
            message: 'Ce trajet manuel utilise un repère manquant.',
            stepId: step.id,
            actorId: actorId,
          ),
        );
      } else {
        waypoints.add(point);
      }
    }
  }

  CinematicActorPlaybackPose? initialPose;
  for (final track in actorTracks) {
    if (track.actorId == actorId) {
      initialPose = track.initialPose;
      break;
    }
  }
  if (initialPose != null && initialPose.hasPosition && destination != null) {
    final allPoints = [
      CinematicPreviewPlaybackPoint(
        x: initialPose.x!,
        y: initialPose.y!,
        source: CinematicPreviewPlaybackPointSource.initialPlacement,
      ),
      ...waypoints,
      destination,
    ];
    if (_positiveSegmentCount(allPoints) == 0 && allPoints.length > 1) {
      diagnostics.add(
        CinematicPreviewPlaybackDiagnostic(
          code: CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackManualPathZeroLength,
          severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
          message: 'Ce trajet manuel ne déplace pas encore l’acteur.',
          stepId: step.id,
          actorId: actorId,
        ),
      );
    }
  }

  return _ActorMovePlaybackPlan(
    stepId: step.id,
    actorId: actorId ?? '',
    pathMode: pathMode,
    destination: destination,
    waypoints: waypoints,
  );
}

_ActorEmotePlaybackPlan _buildActorEmotePlan({
  required CinematicTimelineStep step,
  required List<CinematicPreviewActorTrack> actorTracks,
  required Set<String> actorTrackIds,
  required List<CinematicPreviewPlaybackDiagnostic> diagnostics,
}) {
  final actorId = cinematicTimelineActorEmoteActorIdOf(step);
  String? actorLabel;
  if (actorId == null) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackEmoteActorMissing,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message: 'Impossible de prévisualiser cette émotion : acteur manquant.',
        stepId: step.id,
      ),
    );
  } else if (!actorTrackIds.contains(actorId)) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackEmoteActorUnknown,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message:
            'Impossible de prévisualiser cette émotion : acteur introuvable.',
        stepId: step.id,
        actorId: actorId,
      ),
    );
  } else {
    for (final track in actorTracks) {
      if (track.actorId == actorId) {
        actorLabel = track.actorLabel;
        break;
      }
    }
  }

  final emoteId = cinematicTimelineActorEmoteEmoteIdOf(step);
  final emoteEntry = cinematicEmoteCatalogEntryById(emoteId);
  if (emoteId == null) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackEmoteMissing,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message: 'Impossible de prévisualiser cette émotion : choix manquant.',
        stepId: step.id,
        actorId: actorId,
      ),
    );
  } else if (emoteEntry == null) {
    diagnostics.add(
      CinematicPreviewPlaybackDiagnostic(
        code: CinematicPreviewPlaybackDiagnosticCode
            .cinematicPreviewPlaybackEmoteUnknown,
        severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
        message:
            'Impossible de prévisualiser cette émotion : choix indisponible.',
        stepId: step.id,
        actorId: actorId,
      ),
    );
  }

  return _ActorEmotePlaybackPlan(
    actorId: actorId,
    actorLabel: actorLabel,
    emoteId: emoteId,
    emoteLabel: emoteEntry?.label,
    isSupported: diagnostics.isEmpty,
  );
}

CinematicActorPlaybackPose _poseForMove({
  required CinematicActorPlaybackPose current,
  required _ActorMovePlaybackPlan movePlan,
  required CinematicPreviewPlaybackTimelineItem item,
  required int clampedTimeMs,
}) {
  if (!current.hasPosition || movePlan.destination == null) {
    return current.copyWith(
      isInterpolated: false,
      activeStepId: item.stepId,
    );
  }

  final progress = clampedTimeMs >= item.endMs
      ? 1.0
      : ((clampedTimeMs - item.startMs) / item.visualDurationMs)
          .clamp(0.0, 1.0);
  final source = movePlan.pathMode == CinematicTimelineActorPathMode.manual
      ? CinematicActorPlaybackPoseSource.actorMoveManualPath
      : CinematicActorPlaybackPoseSource.actorMoveDirect;
  final start = CinematicPreviewPlaybackPoint(
    x: current.x!,
    y: current.y!,
    source: CinematicPreviewPlaybackPointSource.initialPlacement,
  );
  final route = movePlan.pathMode == CinematicTimelineActorPathMode.manual
      ? [start, ...movePlan.waypoints, movePlan.destination!]
      : [start, movePlan.destination!];
  final interpolation = _pointAlongRoute(route, progress);
  final isInterpolated = clampedTimeMs < item.endMs && progress > 0;

  return CinematicActorPlaybackPose(
    actorId: current.actorId,
    actorLabel: current.actorLabel,
    x: interpolation.point.x,
    y: interpolation.point.y,
    facing: interpolation.facing ?? current.facing,
    source: source,
    isInterpolated: isInterpolated,
    activeStepId: item.stepId,
  );
}

CinematicFadePlaybackState _fadeStateFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required CinematicFadePlaybackMode mode,
  required int clampedTimeMs,
}) {
  final localProgress = _timelineItemProgress(item, clampedTimeMs);
  final opacity = switch (mode) {
    CinematicFadePlaybackMode.fadeIn => 1.0 - localProgress,
    CinematicFadePlaybackMode.fadeOut => localProgress,
    CinematicFadePlaybackMode.unknown => 0.0,
  };
  return CinematicFadePlaybackState(
    opacity: opacity,
    mode: mode,
    activeStepId: item.stepId,
  );
}

CinematicCameraPlaybackPose _cameraPoseFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required CinematicTimelineCameraMode? mode,
  required CinematicTimelineCameraFocusBinding? focusBinding,
  required Map<String, CinematicActorPlaybackPose> actorPosesById,
  required Map<String, CinematicStagePoint> stagePointsById,
  required CinematicPreviewPlaybackStageBounds? stageBounds,
  required int clampedTimeMs,
}) {
  final geometry = _cameraGeometryFor(
    item: item,
    mode: mode,
    focusBinding: focusBinding,
    actorPosesById: actorPosesById,
    stagePointsById: stagePointsById,
    stageBounds: stageBounds,
  );
  return CinematicCameraPlaybackPose(
    isActive: true,
    isSupported: mode != null && item.supported,
    activeStepId: item.stepId,
    mode: mode,
    progress: _timelineItemProgress(item, clampedTimeMs),
    geometry: geometry,
    diagnostics: _mergedDiagnostics(item.diagnostics, geometry.diagnostics),
  );
}

CinematicCameraPlaybackGeometry _cameraGeometryFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required CinematicTimelineCameraMode? mode,
  required CinematicTimelineCameraFocusBinding? focusBinding,
  required Map<String, CinematicActorPlaybackPose> actorPosesById,
  required Map<String, CinematicStagePoint> stagePointsById,
  required CinematicPreviewPlaybackStageBounds? stageBounds,
}) {
  if (mode != CinematicTimelineCameraMode.focus) {
    return const CinematicCameraPlaybackGeometry.none();
  }
  final staticDiagnostics = _cameraGeometryDiagnostics(item.diagnostics);
  if (focusBinding == null) {
    return CinematicCameraPlaybackGeometry.unavailable(
      diagnostics: staticDiagnostics,
    );
  }
  final target = focusBinding.target;
  final zoomPreset = focusBinding.zoomPreset;
  switch (target.kind) {
    case CinematicCameraTargetKind.sceneCenter:
      if (stageBounds == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.sceneCenter,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStageMapMissingDiagnostic(item.stepId),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.sceneCenter,
        targetLabel: _cameraTargetLabel(target),
        centerX: stageBounds.centerX,
        centerY: stageBounds.centerY,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
    case CinematicCameraTargetKind.actor:
      final actorId = target.actorId;
      if (actorId == null || actorId.isEmpty) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorMissingDiagnostic(item.stepId),
          ],
        );
      }
      final pose = actorPosesById[actorId];
      if (pose == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          actorId: actorId,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorUnknownDiagnostic(item.stepId, actorId),
          ],
        );
      }
      if (!pose.hasPosition) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.actor,
          actorId: actorId,
          targetLabel: pose.actorLabel ?? _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetActorWithoutPositionDiagnostic(item.stepId, actorId),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.actor,
        actorId: actorId,
        targetLabel: pose.actorLabel ?? _cameraTargetLabel(target),
        centerX: pose.x!,
        centerY: pose.y!,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
    case CinematicCameraTargetKind.stagePoint:
      final stagePointId = target.stagePointId;
      if (stagePointId == null || stagePointId.isEmpty) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointMissingDiagnostic(item.stepId),
          ],
        );
      }
      final point = stagePointsById[stagePointId];
      if (point == null) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          stagePointId: stagePointId,
          targetLabel: _cameraTargetLabel(target),
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointUnknownDiagnostic(
              item.stepId,
              stagePointId,
            ),
          ],
        );
      }
      if (stageBounds != null && !stageBounds.containsPoint(point.x, point.y)) {
        return CinematicCameraPlaybackGeometry.unavailable(
          targetKind: CinematicCameraTargetKind.stagePoint,
          stagePointId: stagePointId,
          targetLabel: point.label,
          zoomPreset: zoomPreset,
          diagnostics: [
            ...staticDiagnostics,
            _cameraTargetStagePointOutOfMapDiagnostic(
              item.stepId,
              stagePointId,
            ),
          ],
        );
      }
      return CinematicCameraPlaybackGeometry.available(
        targetKind: CinematicCameraTargetKind.stagePoint,
        stagePointId: stagePointId,
        targetLabel: point.label,
        centerX: point.x,
        centerY: point.y,
        zoomPreset: zoomPreset,
        diagnostics: staticDiagnostics,
      );
  }
}

List<CinematicPreviewPlaybackDiagnostic> _cameraFocusStaticDiagnostics(
  CinematicTimelineStep step,
) {
  final diagnostics = <CinematicPreviewPlaybackDiagnostic>[];
  final rawTargetKind =
      step.metadata[cinematicTimelineCameraTargetKindMetadataKey]?.trim();
  final targetKind = cinematicTimelineCameraTargetKindOf(step);
  if (rawTargetKind == null || rawTargetKind.isEmpty) {
    diagnostics.add(_cameraTargetMissingDiagnostic(step.id));
  } else if (targetKind == null) {
    diagnostics.add(
      _cameraTargetKindUnsupportedDiagnostic(step.id, rawTargetKind),
    );
  } else {
    switch (targetKind) {
      case CinematicCameraTargetKind.sceneCenter:
        break;
      case CinematicCameraTargetKind.actor:
        final actorId = step
            .metadata[cinematicTimelineCameraTargetActorIdMetadataKey]
            ?.trim();
        if (actorId == null || actorId.isEmpty) {
          diagnostics.add(_cameraTargetActorMissingDiagnostic(step.id));
        }
        break;
      case CinematicCameraTargetKind.stagePoint:
        final stagePointId = step
            .metadata[cinematicTimelineCameraTargetStagePointIdMetadataKey]
            ?.trim();
        if (stagePointId == null || stagePointId.isEmpty) {
          diagnostics.add(_cameraTargetStagePointMissingDiagnostic(step.id));
        }
        break;
    }
  }

  final rawZoom =
      step.metadata[cinematicTimelineCameraZoomPresetMetadataKey]?.trim();
  if (rawZoom == null || rawZoom.isEmpty) {
    diagnostics.add(_cameraZoomPresetMissingDiagnostic(step.id));
  } else if (cinematicTimelineCameraZoomPresetOf(step) == null) {
    diagnostics.add(_cameraZoomPresetUnsupportedDiagnostic(step.id, rawZoom));
  }
  return diagnostics;
}

List<CinematicPreviewPlaybackDiagnostic> _cameraGeometryDiagnostics(
  List<CinematicPreviewPlaybackDiagnostic> diagnostics,
) {
  return [
    for (final diagnostic in diagnostics)
      if (diagnostic.code !=
          CinematicPreviewPlaybackDiagnosticCode
              .cinematicPreviewPlaybackCameraUnsupported)
        diagnostic,
  ];
}

List<CinematicPreviewPlaybackDiagnostic> _mergedDiagnostics(
  List<CinematicPreviewPlaybackDiagnostic> primary,
  List<CinematicPreviewPlaybackDiagnostic> secondary,
) {
  final result = <CinematicPreviewPlaybackDiagnostic>[];
  for (final diagnostic in [...primary, ...secondary]) {
    if (!result.contains(diagnostic)) {
      result.add(diagnostic);
    }
  }
  return result;
}

String _cameraTargetLabel(CinematicCameraTargetBinding target) {
  return target.label ??
      switch (target.kind) {
        CinematicCameraTargetKind.sceneCenter => 'Centre de la scène',
        CinematicCameraTargetKind.actor => target.actorId ?? 'Acteur',
        CinematicCameraTargetKind.stagePoint => target.stagePointId ?? 'Repère',
      };
}

CinematicPreviewPlaybackDiagnostic _cameraTargetMissingDiagnostic(
  String stepId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra doit choisir une cible.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetKindUnsupportedDiagnostic(
  String stepId,
  String targetKind,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetKindUnsupported,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le type de cible caméra "$targetKind" n’est pas supporté.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetActorMissingDiagnostic(
  String stepId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetActorMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra sur acteur doit choisir un acteur.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetActorUnknownDiagnostic(
  String stepId,
  String actorId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetActorUnknown,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra référence un acteur inconnu.',
    stepId: stepId,
    actorId: actorId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetActorWithoutPositionDiagnostic(
  String stepId,
  String actorId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetActorWithoutPosition,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
    message: 'L’acteur ciblé par la caméra n’a pas de position preview.',
    stepId: stepId,
    actorId: actorId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetStagePointMissingDiagnostic(
  String stepId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetStagePointMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra sur repère doit choisir un repère.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetStagePointUnknownDiagnostic(
  String stepId,
  String stagePointId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetStagePointUnknown,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra référence un repère inconnu.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetStagePointOutOfMapDiagnostic(
  String stepId,
  String stagePointId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetStagePointOutOfMap,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le repère ciblé par la caméra est en dehors des bounds stage.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraTargetStageMapMissingDiagnostic(
  String stepId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraTargetStageMapMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
    message: 'Le centre de scène caméra nécessite des bounds stage.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraZoomPresetMissingDiagnostic(
  String stepId,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraZoomPresetMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le cadrage caméra doit choisir un plan.',
    stepId: stepId,
  );
}

CinematicPreviewPlaybackDiagnostic _cameraZoomPresetUnsupportedDiagnostic(
  String stepId,
  String zoomPreset,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraZoomPresetUnsupported,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Le plan caméra "$zoomPreset" n’est pas supporté.',
    stepId: stepId,
  );
}

double _timelineItemProgress(
  CinematicPreviewPlaybackTimelineItem item,
  int clampedTimeMs,
) {
  if (item.visualDurationMs <= 0) {
    return 0;
  }
  return ((clampedTimeMs - item.startMs) / item.visualDurationMs)
      .clamp(0.0, 1.0)
      .toDouble();
}

CinematicActorEmotePlaybackState _emotePlaybackStateFor({
  required CinematicPreviewPlaybackTimelineItem item,
  required _ActorEmotePlaybackPlan? plan,
  required int clampedTimeMs,
}) {
  final elapsedMs =
      (clampedTimeMs - item.startMs).clamp(0, item.visualDurationMs).toInt();
  return CinematicActorEmotePlaybackState(
    activeStepId: item.stepId,
    stepIndex: item.stepIndex,
    actorId: plan?.actorId ?? item.actorId,
    actorLabel: plan?.actorLabel ?? item.actorLabel,
    emoteId: plan?.emoteId,
    emoteLabel: plan?.emoteLabel,
    durationMs: item.visualDurationMs,
    elapsedMs: elapsedMs,
    progress: _timelineItemProgress(item, clampedTimeMs),
    isSupported: plan?.isSupported == true && item.supported,
    diagnostics: item.diagnostics,
  );
}

bool _stepSupportedForPlayback(CinematicTimelineStep step) {
  return switch (step.kind) {
    CinematicTimelineStepKind.wait ||
    CinematicTimelineStepKind.actorFace ||
    CinematicTimelineStepKind.actorMove ||
    CinematicTimelineStepKind.fade ||
    CinematicTimelineStepKind.actorEmote =>
      true,
    CinematicTimelineStepKind.camera => _cameraModeOf(step) != null &&
        _cameraModeOf(step) != CinematicTimelineCameraMode.focus,
    CinematicTimelineStepKind.dialogueLine ||
    CinematicTimelineStepKind.sound ||
    CinematicTimelineStepKind.music ||
    CinematicTimelineStepKind.shake ||
    CinematicTimelineStepKind.fx ||
    CinematicTimelineStepKind.marker =>
      false,
  };
}

CinematicTimelineCameraMode? _cameraModeOf(CinematicTimelineStep step) {
  return cinematicTimelineCameraModeOf(step);
}

CinematicPreviewPlaybackDiagnostic _cameraUnsupportedDiagnostic(
  CinematicTimelineStep step,
) {
  final hasMode =
      step.metadata.containsKey(cinematicTimelineCameraModeMetadataKey);
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackCameraUnsupported,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.warning,
    message: hasMode
        ? 'Caméra non prévisualisée dans cette version.'
        : 'Cadrage caméra incomplet.',
    stepId: step.id,
  );
}

CinematicPreviewPlaybackDiagnostic _actorMissingDiagnostic(
  CinematicTimelineStep step,
) {
  return CinematicPreviewPlaybackDiagnostic(
    code: CinematicPreviewPlaybackDiagnosticCode
        .cinematicPreviewPlaybackActorMissing,
    severity: CinematicPreviewPlaybackDiagnosticSeverity.error,
    message: 'Impossible de prévisualiser ce bloc : l’acteur est introuvable.',
    stepId: step.id,
    actorId: step.actorId,
  );
}

CinematicPreviewPlaybackPoint? _movementTargetPoint({
  required CinematicStageContext stageContext,
  required String? targetId,
  required Map<String, CinematicPreviewPlaybackPoint> resolvedMovementTargets,
}) {
  final normalizedTargetId = targetId?.trim();
  if (normalizedTargetId == null || normalizedTargetId.isEmpty) {
    return null;
  }
  CinematicMovementTargetBinding? binding;
  for (final candidate in stageContext.movementTargetBindings) {
    if (candidate.targetId == normalizedTargetId) {
      binding = candidate;
      break;
    }
  }
  if (binding != null &&
      binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
    final point = _stagePointById(stageContext, binding.sourceId);
    if (point != null) {
      return CinematicPreviewPlaybackPoint(
        x: point.x,
        y: point.y,
        source: CinematicPreviewPlaybackPointSource.resolvedMovementTarget,
        sourceId: normalizedTargetId,
      );
    }
  }
  return resolvedMovementTargets[normalizedTargetId];
}

CinematicPreviewPlaybackPoint? _stagePointById(
  CinematicStageContext stageContext,
  String? stagePointId,
) {
  final normalizedPointId = stagePointId?.trim();
  if (normalizedPointId == null || normalizedPointId.isEmpty) {
    return null;
  }
  for (final point in stageContext.stagePoints) {
    if (point.id == normalizedPointId) {
      return CinematicPreviewPlaybackPoint(
        x: point.x,
        y: point.y,
        source: CinematicPreviewPlaybackPointSource.stagePoint,
        sourceId: point.id,
      );
    }
  }
  return null;
}

CinematicActorInitialPlacement? _placementFor(
  CinematicStageContext stageContext,
  String actorId,
) {
  for (final placement in stageContext.initialPlacements) {
    if (placement.actorId == actorId) {
      return placement;
    }
  }
  return null;
}

CinematicActorPreviewDirection _directionFromActorFace(
  CinematicTimelineActorFacingDirection direction,
) {
  return switch (direction) {
    CinematicTimelineActorFacingDirection.up =>
      CinematicActorPreviewDirection.north,
    CinematicTimelineActorFacingDirection.down =>
      CinematicActorPreviewDirection.south,
    CinematicTimelineActorFacingDirection.left =>
      CinematicActorPreviewDirection.west,
    CinematicTimelineActorFacingDirection.right =>
      CinematicActorPreviewDirection.east,
  };
}

CinematicActorPreviewDirection? _directionFromDelta(double dx, double dy) {
  if (dx == 0 && dy == 0) {
    return null;
  }
  if (dx.abs() >= dy.abs()) {
    return dx >= 0
        ? CinematicActorPreviewDirection.east
        : CinematicActorPreviewDirection.west;
  }
  return dy >= 0
      ? CinematicActorPreviewDirection.south
      : CinematicActorPreviewDirection.north;
}

CinematicFadePlaybackMode _fadeModeOf(CinematicTimelineStep step) {
  return switch (step.metadata[cinematicTimelineFadeModeMetadataKey]) {
    'fadeIn' => CinematicFadePlaybackMode.fadeIn,
    'fadeOut' => CinematicFadePlaybackMode.fadeOut,
    _ => CinematicFadePlaybackMode.unknown,
  };
}

int _positiveSegmentCount(List<CinematicPreviewPlaybackPoint> points) {
  var count = 0;
  for (var i = 0; i < points.length - 1; i++) {
    if (_distance(points[i], points[i + 1]) > 0) {
      count += 1;
    }
  }
  return count;
}

_RouteInterpolation _pointAlongRoute(
  List<CinematicPreviewPlaybackPoint> points,
  double progress,
) {
  if (points.length <= 1) {
    return _RouteInterpolation(point: points.first, facing: null);
  }

  final positiveSegments = <_RouteSegment>[];
  for (var i = 0; i < points.length - 1; i++) {
    final start = points[i];
    final end = points[i + 1];
    final length = _distance(start, end);
    if (length > 0) {
      positiveSegments
          .add(_RouteSegment(start: start, end: end, length: length));
    }
  }

  if (positiveSegments.isEmpty) {
    return _RouteInterpolation(point: points.first, facing: null);
  }

  final totalLength = positiveSegments.fold<double>(
    0,
    (sum, segment) => sum + segment.length,
  );
  final targetLength = totalLength * progress.clamp(0.0, 1.0);
  var walked = 0.0;
  for (final segment in positiveSegments) {
    final endOfSegment = walked + segment.length;
    if (targetLength <= endOfSegment || segment == positiveSegments.last) {
      final segmentProgress =
          ((targetLength - walked) / segment.length).clamp(0.0, 1.0);
      final x = _lerp(segment.start.x, segment.end.x, segmentProgress);
      final y = _lerp(segment.start.y, segment.end.y, segmentProgress);
      return _RouteInterpolation(
        point: CinematicPreviewPlaybackPoint(
          x: x,
          y: y,
          source: segment.end.source,
          sourceId: segment.end.sourceId,
        ),
        facing: _directionFromDelta(
          segment.end.x - segment.start.x,
          segment.end.y - segment.start.y,
        ),
      );
    }
    walked = endOfSegment;
  }
  return _RouteInterpolation(point: positiveSegments.last.end, facing: null);
}

double _distance(
  CinematicPreviewPlaybackPoint a,
  CinematicPreviewPlaybackPoint b,
) {
  return math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
}

double _lerp(double start, double end, double t) => start + (end - start) * t;

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

@immutable
final class _ActorMovePlaybackPlan {
  _ActorMovePlaybackPlan({
    required this.stepId,
    required this.actorId,
    required this.pathMode,
    required this.destination,
    required List<CinematicPreviewPlaybackPoint> waypoints,
  }) : waypoints = List<CinematicPreviewPlaybackPoint>.unmodifiable(waypoints);

  final String stepId;
  final String actorId;
  final CinematicTimelineActorPathMode pathMode;
  final CinematicPreviewPlaybackPoint? destination;
  final List<CinematicPreviewPlaybackPoint> waypoints;
}

@immutable
final class _ActorEmotePlaybackPlan {
  const _ActorEmotePlaybackPlan({
    required this.actorId,
    required this.actorLabel,
    required this.emoteId,
    required this.emoteLabel,
    required this.isSupported,
  });

  final String? actorId;
  final String? actorLabel;
  final String? emoteId;
  final String? emoteLabel;
  final bool isSupported;
}

@immutable
final class _RouteSegment {
  const _RouteSegment({
    required this.start,
    required this.end,
    required this.length,
  });

  final CinematicPreviewPlaybackPoint start;
  final CinematicPreviewPlaybackPoint end;
  final double length;
}

@immutable
final class _RouteInterpolation {
  const _RouteInterpolation({
    required this.point,
    required this.facing,
  });

  final CinematicPreviewPlaybackPoint point;
  final CinematicActorPreviewDirection? facing;
}

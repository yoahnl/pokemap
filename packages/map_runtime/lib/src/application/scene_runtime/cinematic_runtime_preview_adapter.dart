import 'package:map_core/map_core.dart';

final class CinematicRuntimePreview {
  CinematicRuntimePreview({
    required this.cinematicId,
    required this.canStart,
    required Iterable<Map<String, Object?>> preflightIssues,
    required Iterable<String> timelineKinds,
    required this.totalDurationMs,
    required this.executableDurationMs,
    required Iterable<String> hostLimitations,
  })  : preflightIssues = List.unmodifiable(preflightIssues),
        timelineKinds = List.unmodifiable(timelineKinds),
        hostLimitations = List.unmodifiable(hostLimitations);

  final String cinematicId;
  final bool canStart;
  final List<Map<String, Object?>> preflightIssues;
  final List<String> timelineKinds;
  final int totalDurationMs;
  final int executableDurationMs;
  final List<String> hostLimitations;

  Map<String, Object?> toJson() => {
        'cinematicId': cinematicId,
        'canStart': canStart,
        'preflightIssues': preflightIssues,
        'timelineKinds': timelineKinds,
        'totalDurationMs': totalDurationMs,
        'executableDurationMs': executableDurationMs,
        'hostLimitations': hostLimitations,
      };
}

/// Read-only runtime projection for API/editor previews. Structural checks are
/// shared with live playback; mounted actor handles and decoded media remain
/// host-owned and are deliberately reported as limitations.
final class CinematicRuntimePreviewAdapter {
  const CinematicRuntimePreviewAdapter();

  CinematicRuntimePreview inspect({
    required ProjectManifest project,
    required CinematicAsset cinematic,
    String? activeMapId,
  }) {
    final mapIds = project.maps.map((map) => map.id);
    final preflight = preflightCinematicPlayback(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
      activeMapId: activeMapId,
      mode: CinematicPlaybackPreflightMode.runtime,
    );
    final plan = buildCinematicPreviewPlaybackPlan(
      cinematic: cinematic,
      dialogues: project.dialogues,
      mediaAssets: project.cinematicMediaAssets,
      availableMapIds: mapIds,
    );
    return CinematicRuntimePreview(
      cinematicId: cinematic.id,
      canStart: preflight.isReady &&
          plan.diagnostics.every((diagnostic) => !diagnostic.blocking),
      preflightIssues: [
        for (final issue in preflight.issues)
          <String, Object?>{
            'kind': issue.kind.name,
            'message': issue.message,
            if (issue.stepId != null) 'stepId': issue.stepId,
            if (issue.referenceId != null) 'referenceId': issue.referenceId,
          },
      ],
      timelineKinds: [
        for (final step in cinematic.timeline.steps) step.kind.name,
      ],
      totalDurationMs: plan.totalDurationMs,
      executableDurationMs: plan.executableDurationMs,
      hostLimitations: const [
        'Mounted Flame actor handles are verified only by the playback sink.',
        'Media decoding and device audio availability are host responsibilities.',
        'Preview inspection does not execute commands or mutate runtime state.',
      ],
    );
  }
}

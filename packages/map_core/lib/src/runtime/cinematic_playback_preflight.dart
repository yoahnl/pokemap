import '../models/cinematic_asset.dart';
import '../models/cinematic_media_asset.dart';
import '../models/project_manifest.dart';

enum CinematicPlaybackPreflightMode { preview, runtime }

enum CinematicPlaybackPreflightIssueKind {
  invalidActorReference,
  unsupportedActorBinding,
  invalidMapReference,
  invalidTargetReference,
  invalidStep,
  missingDialogue,
  missingMedia,
  mediaTypeMismatch,
}

final class CinematicPlaybackPreflightIssue {
  const CinematicPlaybackPreflightIssue({
    required this.kind,
    required this.message,
    this.stepId,
    this.referenceId,
  });

  final CinematicPlaybackPreflightIssueKind kind;
  final String message;
  final String? stepId;
  final String? referenceId;
}

final class CinematicPlaybackPreflightReport {
  CinematicPlaybackPreflightReport({
    required List<CinematicPlaybackPreflightIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final List<CinematicPlaybackPreflightIssue> issues;

  bool get isReady => issues.isEmpty;
}

/// Shared structural and asset preflight used by both editor preview and the
/// runtime. Host availability (mounted Flame actors, active map, files on
/// disk) remains the responsibility of the concrete adapter.
CinematicPlaybackPreflightReport preflightCinematicPlayback({
  required CinematicAsset cinematic,
  Iterable<ProjectDialogueEntry> dialogues = const [],
  Iterable<CinematicMediaAsset> mediaAssets = const [],
  Iterable<String>? availableMapIds,
  String? activeMapId,
  CinematicPlaybackPreflightMode mode = CinematicPlaybackPreflightMode.preview,
}) {
  final issues = <CinematicPlaybackPreflightIssue>[];
  final dialogueIds = dialogues.map((entry) => entry.id).toSet();
  final mediaById = <String, CinematicMediaAsset>{
    for (final media in mediaAssets) media.id: media,
  };
  final authoredMapId = cinematic.mapId;
  final knownMapIds = availableMapIds?.toSet();
  if (authoredMapId != null &&
      knownMapIds != null &&
      !knownMapIds.contains(authoredMapId)) {
    issues.add(_issue(
      CinematicPlaybackPreflightIssueKind.invalidMapReference,
      'Cinematic "${cinematic.id}" references unavailable map '
      '"$authoredMapId".',
      referenceId: authoredMapId,
    ));
  } else if (authoredMapId != null &&
      activeMapId != null &&
      authoredMapId != activeMapId) {
    issues.add(_issue(
      CinematicPlaybackPreflightIssueKind.invalidMapReference,
      'Cinematic "${cinematic.id}" targets map "$authoredMapId" but the '
      'active map is "$activeMapId".',
      referenceId: authoredMapId,
    ));
  }
  final context = cinematic.stageContext;
  final actorBindings = <String, CinematicActorBinding>{};
  for (final binding in context?.actorBindings ?? const []) {
    if (actorBindings.containsKey(binding.actorId)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidActorReference,
        'Actor "${binding.actorId}" has duplicate bindings.',
        referenceId: binding.actorId,
      ));
      continue;
    }
    if (mode == CinematicPlaybackPreflightMode.runtime &&
        (binding.kind == CinematicActorBindingKind.cinematicOnly ||
            binding.kind == CinematicActorBindingKind.unbound)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.unsupportedActorBinding,
        'Actor "${binding.actorId}" uses unsupported runtime binding '
        '"${binding.kind.name}".',
        referenceId: binding.actorId,
      ));
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        (binding.mapEntityId == null || binding.mapEntityId!.isEmpty)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidActorReference,
        'Actor "${binding.actorId}" is missing mapEntityId.',
        referenceId: binding.actorId,
      ));
    }
    actorBindings[binding.actorId] = binding;
  }
  if (mode == CinematicPlaybackPreflightMode.runtime) {
    for (final actor in cinematic.requiredActors) {
      if (!actorBindings.containsKey(actor.actorId)) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.invalidActorReference,
          'Required actor "${actor.actorId}" has no runtime binding.',
          referenceId: actor.actorId,
        ));
      }
    }
  }

  final targetIds =
      cinematic.movementTargets.map((target) => target.targetId).toSet();
  final stagePointIds = (context?.stagePoints ?? const <CinematicStagePoint>[])
      .map((point) => point.id)
      .toSet();
  final targetBindings = <String, CinematicMovementTargetBinding>{};
  for (final binding in context?.movementTargetBindings ??
      const <CinematicMovementTargetBinding>[]) {
    if (!targetIds.contains(binding.targetId) ||
        targetBindings.containsKey(binding.targetId)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidTargetReference,
        'Movement target "${binding.targetId}" has an invalid binding.',
        referenceId: binding.targetId,
      ));
      continue;
    }
    final sourceId = binding.sourceId;
    if (mode == CinematicPlaybackPreflightMode.runtime &&
        binding.kind != CinematicMovementTargetBindingKind.mapEntity &&
        binding.kind != CinematicMovementTargetBindingKind.stagePoint) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidTargetReference,
        'Movement target "${binding.targetId}" uses unsupported runtime '
        'binding "${binding.kind.name}".',
        referenceId: binding.targetId,
      ));
    }
    if (mode == CinematicPlaybackPreflightMode.runtime &&
        (sourceId == null || sourceId.isEmpty)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidTargetReference,
        'Movement target "${binding.targetId}" is missing sourceId.',
        referenceId: binding.targetId,
      ));
    }
    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint &&
        sourceId != null &&
        !stagePointIds.contains(sourceId)) {
      issues.add(_issue(
        CinematicPlaybackPreflightIssueKind.invalidTargetReference,
        'Movement target "${binding.targetId}" references unknown stage '
        'point "$sourceId".',
        referenceId: sourceId,
      ));
    }
    targetBindings[binding.targetId] = binding;
  }
  if (mode == CinematicPlaybackPreflightMode.runtime) {
    for (final targetId in targetIds) {
      if (!targetBindings.containsKey(targetId)) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.invalidTargetReference,
          'Movement target "$targetId" has no runtime binding.',
          referenceId: targetId,
        ));
      }
    }
  }

  for (final step in cinematic.timeline.steps) {
    if (step.durationMs != null && step.durationMs! < 0) {
      issues.add(_stepIssue(step, 'has a negative duration.'));
    }
    if (step.kind == CinematicTimelineStepKind.wait &&
        step.durationMs == null) {
      issues.add(_stepIssue(step, 'requires durationMs.'));
    }
    if (_requiresActor(step.kind)) {
      final actorId = step.actorId;
      final known =
          cinematic.requiredActors.any((actor) => actor.actorId == actorId);
      if (actorId == null ||
          !known ||
          (mode == CinematicPlaybackPreflightMode.runtime &&
              !actorBindings.containsKey(actorId))) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.invalidActorReference,
          'Step "${step.id}" references an unavailable actor.',
          stepId: step.id,
          referenceId: actorId,
        ));
      }
    }
    if (step.kind == CinematicTimelineStepKind.actorMove) {
      final targetId = step.targetId;
      if (targetId == null ||
          !targetIds.contains(targetId) ||
          (mode == CinematicPlaybackPreflightMode.runtime &&
              !targetBindings.containsKey(targetId))) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.invalidTargetReference,
          'Step "${step.id}" references an unavailable movement target.',
          stepId: step.id,
          referenceId: targetId,
        ));
      }
    }
    if (step.kind == CinematicTimelineStepKind.dialogueLine) {
      final dialogueId = step.assetRef;
      final hasInlineFallback = step.dialogueText?.trim().isNotEmpty == true;
      if (!hasInlineFallback &&
          (dialogueId == null || !dialogueIds.contains(dialogueId))) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.missingDialogue,
          'Dialogue line "${step.id}" references an unavailable dialogue.',
          stepId: step.id,
          referenceId: dialogueId,
        ));
      }
    }
    final expectedMediaKind = _expectedMediaKind(step.kind);
    if (expectedMediaKind != null) {
      final mediaId = step.assetRef;
      final media = mediaId == null ? null : mediaById[mediaId];
      if (media == null) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.missingMedia,
          'Step "${step.id}" references an unavailable media asset.',
          stepId: step.id,
          referenceId: mediaId,
        ));
      } else if (media.kind != expectedMediaKind) {
        issues.add(_issue(
          CinematicPlaybackPreflightIssueKind.mediaTypeMismatch,
          'Step "${step.id}" expects ${expectedMediaKind.name}, not '
          '${media.kind.name}.',
          stepId: step.id,
          referenceId: mediaId,
        ));
      }
    }
  }
  return CinematicPlaybackPreflightReport(issues: issues);
}

CinematicMediaAssetKind? cinematicExpectedMediaKind(
  CinematicTimelineStepKind kind,
) =>
    _expectedMediaKind(kind);

CinematicMediaAssetKind? _expectedMediaKind(CinematicTimelineStepKind kind) =>
    switch (kind) {
      CinematicTimelineStepKind.sound => CinematicMediaAssetKind.sound,
      CinematicTimelineStepKind.music => CinematicMediaAssetKind.music,
      CinematicTimelineStepKind.fx => CinematicMediaAssetKind.cinematicFx,
      _ => null,
    };

bool _requiresActor(CinematicTimelineStepKind kind) =>
    kind == CinematicTimelineStepKind.actorMove ||
    kind == CinematicTimelineStepKind.actorFace ||
    kind == CinematicTimelineStepKind.actorEmote;

CinematicPlaybackPreflightIssue _stepIssue(
  CinematicTimelineStep step,
  String message,
) =>
    _issue(
      CinematicPlaybackPreflightIssueKind.invalidStep,
      'Step "${step.id}" $message',
      stepId: step.id,
    );

CinematicPlaybackPreflightIssue _issue(
  CinematicPlaybackPreflightIssueKind kind,
  String message, {
  String? stepId,
  String? referenceId,
}) =>
    CinematicPlaybackPreflightIssue(
      kind: kind,
      message: message,
      stepId: stepId,
      referenceId: referenceId,
    );

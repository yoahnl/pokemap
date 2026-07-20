import '../models/cinematic_asset.dart';
import '../models/cinematic_media_asset.dart';
import 'cinematic_authoring_operations.dart';

final class CinematicCommandAuthoringResult {
  const CinematicCommandAuthoringResult({
    required this.previousCinematic,
    required this.cinematic,
    required this.step,
  });

  final CinematicAsset previousCinematic;
  final CinematicAsset cinematic;
  final CinematicTimelineStep step;
}

/// Commands authored by NSC-66 stay editable and serializable, but cannot be
/// published until a runtime acknowledges their playback contract.
List<CinematicTimelineStep> cinematicCommandPublicationBlockers(
  CinematicAsset cinematic,
) =>
    List<CinematicTimelineStep>.unmodifiable(
      cinematic.timeline.steps.where(
        (step) =>
            isCinematicTimelineCommandStep(step) &&
            step.kind != CinematicTimelineStepKind.marker &&
            step.metadata[cinematicTimelineCommandRuntimeStatusMetadataKey] ==
                cinematicTimelineCommandRuntimeDraftStatus,
      ),
    );

CinematicCommandAuthoringResult addCinematicTimelineCommandStep(
  CinematicAsset cinematic, {
  required CinematicTimelineStepKind kind,
  String? afterStepId,
  String? label,
  String? actorId,
  String? dialogueId,
  String? dialogueText,
  CinematicMediaAsset? mediaAsset,
  int? durationMs,
  double volume = 1,
  int fadeMs = 0,
  bool loop = false,
  double intensity = 0.5,
}) {
  final steps = cinematic.timeline.steps.toList();
  final insertionIndex = _insertionIndex(steps, afterStepId);
  final step = _buildCommandStep(
    cinematic,
    kind: kind,
    label: label,
    actorId: actorId,
    dialogueId: dialogueId,
    dialogueText: dialogueText,
    mediaAsset: mediaAsset,
    durationMs: durationMs,
    volume: volume,
    fadeMs: fadeMs,
    loop: loop,
    intensity: intensity,
  );
  steps.insert(insertionIndex, step);
  return _result(cinematic, steps, step);
}

CinematicCommandAuthoringResult updateCinematicTimelineCommandStep(
  CinematicAsset cinematic, {
  required String stepId,
  String? label,
  String? actorId,
  String? dialogueId,
  String? dialogueText,
  CinematicMediaAsset? mediaAsset,
  int? durationMs,
  double? volume,
  int? fadeMs,
  bool? loop,
  double? intensity,
}) {
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == stepId);
  if (index < 0 || !isCinematicTimelineCommandStep(steps[index])) {
    throw ArgumentError.value(stepId, 'stepId', 'Unknown authorable command.');
  }
  final source = steps[index];
  final updated = _buildCommandStep(
    cinematic,
    kind: source.kind,
    id: source.id,
    label: label ?? source.label,
    actorId: actorId ?? source.actorId,
    dialogueId: dialogueId ??
        (source.kind == CinematicTimelineStepKind.dialogueLine
            ? source.assetRef
            : null),
    dialogueText: dialogueText ?? source.dialogueText,
    mediaAsset: mediaAsset ?? _mediaFromStep(source),
    durationMs: durationMs ?? source.durationMs,
    volume:
        volume ?? _double(source, cinematicTimelineCommandVolumeMetadataKey, 1),
    fadeMs: fadeMs ??
        _integer(source, cinematicTimelineCommandFadeMsMetadataKey, 0),
    loop: loop ??
        source.metadata[cinematicTimelineCommandLoopMetadataKey] == 'true',
    intensity: intensity ??
        _double(source, cinematicTimelineCommandIntensityMetadataKey, 0.5),
  );
  steps[index] = updated;
  return _result(cinematic, steps, updated);
}

CinematicCommandAuthoringResult removeCinematicTimelineCommandStep(
  CinematicAsset cinematic, {
  required String stepId,
}) {
  final steps = cinematic.timeline.steps.toList();
  final index = steps.indexWhere((step) => step.id == stepId);
  if (index < 0 || !isCinematicTimelineCommandStep(steps[index])) {
    throw ArgumentError.value(stepId, 'stepId', 'Unknown authorable command.');
  }
  final removed = steps.removeAt(index);
  return _result(cinematic, steps, removed);
}

CinematicTimelineStep _buildCommandStep(
  CinematicAsset cinematic, {
  required CinematicTimelineStepKind kind,
  String? id,
  String? label,
  String? actorId,
  String? dialogueId,
  String? dialogueText,
  CinematicMediaAsset? mediaAsset,
  int? durationMs,
  required double volume,
  required int fadeMs,
  required bool loop,
  required double intensity,
}) {
  const supported = {
    CinematicTimelineStepKind.dialogueLine,
    CinematicTimelineStepKind.shake,
    CinematicTimelineStepKind.sound,
    CinematicTimelineStepKind.music,
    CinematicTimelineStepKind.fx,
    CinematicTimelineStepKind.marker,
  };
  if (!supported.contains(kind)) {
    throw ArgumentError.value(kind, 'kind', 'Unsupported command kind.');
  }
  if (actorId != null &&
      !cinematic.requiredActors.any((actor) => actor.actorId == actorId)) {
    throw ArgumentError.value(actorId, 'actorId', 'Unknown cinematic actor.');
  }
  if (kind == CinematicTimelineStepKind.dialogueLine &&
      (dialogueId == null || dialogueId.trim().isEmpty)) {
    throw ArgumentError.value(dialogueId, 'dialogueId', 'Dialogue required.');
  }
  final expectedMediaKind = switch (kind) {
    CinematicTimelineStepKind.sound => CinematicMediaAssetKind.sound,
    CinematicTimelineStepKind.music => CinematicMediaAssetKind.music,
    CinematicTimelineStepKind.fx => CinematicMediaAssetKind.cinematicFx,
    _ => null,
  };
  if (expectedMediaKind != null && mediaAsset?.kind != expectedMediaKind) {
    throw ArgumentError.value(mediaAsset?.kind, 'mediaAsset',
        'A ${expectedMediaKind.name} asset is required.');
  }
  if (!volume.isFinite || volume < 0 || volume > 1) {
    throw RangeError.range(volume, 0, 1, 'volume');
  }
  if (fadeMs < 0) throw RangeError.value(fadeMs, 'fadeMs');
  if (!intensity.isFinite || intensity < 0 || intensity > 1) {
    throw RangeError.range(intensity, 0, 1, 'intensity');
  }
  if (durationMs != null) {
    validateCinematicTimelineDurationMs(
      durationMs,
      argumentName: 'durationMs',
      minMs: 1,
    );
  }
  final cleanLabel = label?.trim();
  if (kind == CinematicTimelineStepKind.marker &&
      (cleanLabel == null || cleanLabel.isEmpty)) {
    throw ArgumentError.value(label, 'label', 'Marker label required.');
  }
  final metadata = <String, String>{
    cinematicTimelineDraftMetadataSourceKey:
        cinematicTimelineDraftMetadataSourceValue,
    cinematicTimelineDraftMetadataKindKey:
        cinematicTimelineCommandMetadataKindValue,
    cinematicTimelineAuthoringBlockMetadataKey: kind.name,
    if (kind != CinematicTimelineStepKind.marker)
      cinematicTimelineCommandRuntimeStatusMetadataKey:
          cinematicTimelineCommandRuntimeDraftStatus,
    if (expectedMediaKind != null) ...{
      cinematicTimelineCommandVolumeMetadataKey: '$volume',
      cinematicTimelineCommandFadeMsMetadataKey: '$fadeMs',
      cinematicTimelineCommandLoopMetadataKey: '$loop',
    },
    if (kind == CinematicTimelineStepKind.shake ||
        kind == CinematicTimelineStepKind.fx)
      cinematicTimelineCommandIntensityMetadataKey: '$intensity',
  };
  return CinematicTimelineStep(
    id: id ?? _freshId(cinematic, 'step_${kind.name}'),
    kind: kind,
    label: cleanLabel?.isNotEmpty == true ? cleanLabel : _defaultLabel(kind),
    durationMs: durationMs ?? _defaultDuration(kind),
    actorId: actorId,
    dialogueText: dialogueText,
    assetRef: kind == CinematicTimelineStepKind.dialogueLine
        ? dialogueId
        : mediaAsset?.id,
    metadata: metadata,
  );
}

CinematicMediaAsset? _mediaFromStep(CinematicTimelineStep step) {
  final id = step.assetRef;
  final kind = switch (step.kind) {
    CinematicTimelineStepKind.sound => CinematicMediaAssetKind.sound,
    CinematicTimelineStepKind.music => CinematicMediaAssetKind.music,
    CinematicTimelineStepKind.fx => CinematicMediaAssetKind.cinematicFx,
    _ => null,
  };
  if (id == null || kind == null) return null;
  return CinematicMediaAsset(
    id: id,
    label: id,
    kind: kind,
    relativePath: 'preserved/by/id',
  );
}

int _insertionIndex(List<CinematicTimelineStep> steps, String? afterStepId) {
  if (afterStepId == null) return steps.length;
  final index = steps.indexWhere((step) => step.id == afterStepId);
  if (index < 0) throw ArgumentError.value(afterStepId, 'afterStepId');
  return index + 1;
}

String _freshId(CinematicAsset cinematic, String root) {
  final ids = {for (final step in cinematic.timeline.steps) step.id};
  var candidate = root;
  var suffix = 2;
  while (ids.contains(candidate)) {
    candidate = '${root}_${suffix++}';
  }
  return candidate;
}

String _defaultLabel(CinematicTimelineStepKind kind) => switch (kind) {
      CinematicTimelineStepKind.dialogueLine => 'Jouer un dialogue',
      CinematicTimelineStepKind.shake => 'Tremblement caméra',
      CinematicTimelineStepKind.sound => 'Jouer un son',
      CinematicTimelineStepKind.music => 'Jouer une musique',
      CinematicTimelineStepKind.fx => 'Déclencher un FX',
      CinematicTimelineStepKind.marker => 'Nouveau repère',
      _ => kind.name,
    };

int? _defaultDuration(CinematicTimelineStepKind kind) => switch (kind) {
      CinematicTimelineStepKind.dialogueLine => 1500,
      CinematicTimelineStepKind.shake => 500,
      CinematicTimelineStepKind.fx => 800,
      _ => null,
    };

double _double(CinematicTimelineStep step, String key, double fallback) =>
    double.tryParse(step.metadata[key] ?? '') ?? fallback;

int _integer(CinematicTimelineStep step, String key, int fallback) =>
    int.tryParse(step.metadata[key] ?? '') ?? fallback;

CinematicCommandAuthoringResult _result(
  CinematicAsset previous,
  List<CinematicTimelineStep> steps,
  CinematicTimelineStep step,
) =>
    CinematicCommandAuthoringResult(
      previousCinematic: previous,
      cinematic: previous.copyWith(timeline: CinematicTimeline(steps: steps)),
      step: step,
    );

import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';

@immutable
final class CinematicTimelineEditResult {
  CinematicTimelineEditResult({
    required this.previousCinematic,
    required this.cinematic,
    Map<String, String> idRewrites = const {},
  }) : idRewrites = Map.unmodifiable(idRewrites);

  final CinematicAsset previousCinematic;
  final CinematicAsset cinematic;
  final Map<String, String> idRewrites;
}

@immutable
final class CinematicTimelineClipboard {
  CinematicTimelineClipboard({
    required List<CinematicTimelineStep> steps,
    this.schemaVersion = 1,
  }) : steps = List.unmodifiable(steps);

  factory CinematicTimelineClipboard.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'];
    if (rawSteps is! List) {
      throw const FormatException('Timeline clipboard requires steps.');
    }
    return CinematicTimelineClipboard(
      schemaVersion:
          json['schemaVersion'] is int ? json['schemaVersion'] as int : 1,
      steps: [
        for (final raw in rawSteps)
          if (raw is Map)
            CinematicTimelineStep.fromJson(Map<String, dynamic>.from(raw)),
      ],
    );
  }

  final int schemaVersion;
  final List<CinematicTimelineStep> steps;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'steps': [for (final step in steps) step.toJson()],
      };
}

CinematicTimelineEditResult moveCinematicTimelineSteps(
  CinematicAsset cinematic, {
  required Set<String> stepIds,
  required int insertionIndex,
}) {
  final selection = _validatedSelection(cinematic, stepIds);
  final original = cinematic.timeline.steps;
  if (insertionIndex < 0 || insertionIndex > original.length) {
    throw RangeError.range(
        insertionIndex, 0, original.length, 'insertionIndex');
  }
  final selected = [
    for (final step in original)
      if (selection.contains(step.id)) step
  ];
  final remaining = [
    for (final step in original)
      if (!selection.contains(step.id)) step
  ];
  final selectedBefore = original
      .take(insertionIndex)
      .where((step) => selection.contains(step.id))
      .length;
  final effectiveIndex =
      (insertionIndex - selectedBefore).clamp(0, remaining.length);
  remaining.insertAll(effectiveIndex, selected);
  return _result(cinematic, remaining);
}

CinematicTimelineEditResult duplicateCinematicTimelineSteps(
  CinematicAsset cinematic, {
  required Set<String> stepIds,
}) {
  final selection = _validatedSelection(cinematic, stepIds);
  final original = cinematic.timeline.steps;
  final lastIndex =
      original.lastIndexWhere((step) => selection.contains(step.id));
  final existing = {for (final step in original) step.id};
  final rewrites = <String, String>{};
  final clones = <CinematicTimelineStep>[];
  for (final step in original.where((step) => selection.contains(step.id))) {
    final id = _freshStepId(step.id, existing);
    rewrites[step.id] = id;
    clones.add(_cloneStep(step, id));
  }
  final steps = original.toList()..insertAll(lastIndex + 1, clones);
  return _result(cinematic, steps, idRewrites: rewrites);
}

CinematicTimelineClipboard copyCinematicTimelineSteps(
  CinematicAsset cinematic, {
  required Set<String> stepIds,
}) {
  final selection = _validatedSelection(cinematic, stepIds);
  return CinematicTimelineClipboard(
    steps: [
      for (final step in cinematic.timeline.steps)
        if (selection.contains(step.id)) step,
    ],
  );
}

CinematicTimelineEditResult pasteCinematicTimelineSteps(
  CinematicAsset cinematic, {
  required CinematicTimelineClipboard clipboard,
  required int insertionIndex,
}) {
  final steps = cinematic.timeline.steps.toList();
  if (insertionIndex < 0 || insertionIndex > steps.length) {
    throw RangeError.range(insertionIndex, 0, steps.length, 'insertionIndex');
  }
  final existing = {for (final step in steps) step.id};
  final rewrites = <String, String>{};
  final clones = <CinematicTimelineStep>[];
  for (final step in clipboard.steps) {
    final id = _freshStepId(step.id, existing);
    rewrites[step.id] = id;
    clones.add(_cloneStep(step, id));
  }
  steps.insertAll(insertionIndex, clones);
  return _result(cinematic, steps, idRewrites: rewrites);
}

CinematicTimelineEditResult deleteCinematicTimelineSteps(
  CinematicAsset cinematic, {
  required Set<String> stepIds,
}) {
  final selection = _validatedSelection(cinematic, stepIds);
  return _result(
    cinematic,
    [
      for (final step in cinematic.timeline.steps)
        if (!selection.contains(step.id)) step,
    ],
  );
}

Set<String> _validatedSelection(
  CinematicAsset cinematic,
  Set<String> stepIds,
) {
  if (stepIds.isEmpty) {
    throw ArgumentError.value(stepIds, 'stepIds', 'Selection cannot be empty.');
  }
  final known = {for (final step in cinematic.timeline.steps) step.id};
  final missing = stepIds.difference(known);
  if (missing.isNotEmpty) {
    throw ArgumentError.value(
      missing.first,
      'stepIds',
      'Timeline selection contains an unknown step.',
    );
  }
  return stepIds;
}

CinematicTimelineEditResult _result(
  CinematicAsset previous,
  List<CinematicTimelineStep> steps, {
  Map<String, String> idRewrites = const {},
}) {
  return CinematicTimelineEditResult(
    previousCinematic: previous,
    cinematic: previous.copyWith(timeline: CinematicTimeline(steps: steps)),
    idRewrites: idRewrites,
  );
}

CinematicTimelineStep _cloneStep(CinematicTimelineStep step, String id) =>
    CinematicTimelineStep.fromJson({...step.toJson(), 'id': id});

String _freshStepId(String sourceId, Set<String> existing) {
  final root = '${sourceId}_copy';
  var candidate = root;
  var suffix = 2;
  while (!existing.add(candidate)) {
    candidate = '${root}_${suffix++}';
  }
  return candidate;
}

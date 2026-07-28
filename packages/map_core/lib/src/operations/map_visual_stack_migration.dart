import 'dart:collection';

import 'package:meta/meta.dart';

import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_visual_stack_config.dart';
import 'map_visual_composition.dart';

enum MapVisualStackMigrationStatus {
  ready,
  noChange,
  blocked,
}

enum MapVisualStackDifferenceKind {
  added,
  removed,
  moved,
}

/// One inspectable difference between the legacy and canonical composition
/// plans.
@immutable
final class MapVisualStackDifference {
  const MapVisualStackDifference({
    required this.kind,
    required this.stepStableKey,
    required this.occurrence,
    required this.beforeIndex,
    required this.afterIndex,
  });

  final MapVisualStackDifferenceKind kind;
  final String stepStableKey;

  /// Zero-based occurrence among steps sharing [stepStableKey].
  ///
  /// Valid maps normally expose unique keys. Keeping the occurrence makes the
  /// diagnostic deterministic even while inspecting malformed legacy data.
  final int occurrence;
  final int? beforeIndex;
  final int? afterIndex;

  String get stableKey {
    final subject =
        occurrence == 0 ? stepStableKey : '$stepStableKey#${occurrence + 1}';
    return '${kind.name}:$subject:'
        '${beforeIndex?.toString() ?? '-'}->'
        '${afterIndex?.toString() ?? '-'}';
  }
}

/// Pure preview of adopting canonical visual-stack semantics for one map.
///
/// Building this object never mutates or persists [before]. Call
/// [applyMapVisualStackMigration] with this exact reviewed preview to obtain
/// [after].
@immutable
final class MapVisualStackMigrationPreview {
  MapVisualStackMigrationPreview._({
    required this.status,
    required this.before,
    required this.after,
    required this.beforePlan,
    required this.afterPlan,
    required List<MapVisualStackDifference> differences,
    required List<MapVisualCompositionDiagnostic> diagnostics,
  })  : differences = UnmodifiableListView(differences),
        diagnostics = UnmodifiableListView(diagnostics);

  final MapVisualStackMigrationStatus status;
  final MapData before;
  final MapData after;
  final MapVisualCompositionPlan? beforePlan;
  final MapVisualCompositionPlan? afterPlan;
  final UnmodifiableListView<MapVisualStackDifference> differences;
  final UnmodifiableListView<MapVisualCompositionDiagnostic> diagnostics;

  bool get canApply => status == MapVisualStackMigrationStatus.ready;
}

/// Previews the one-way legacy-to-canonical visual-stack migration.
///
/// This operation is deliberately not part of map decoding. A caller must
/// present the returned before/after plans and differences, then explicitly
/// pass the reviewed preview to [applyMapVisualStackMigration].
MapVisualStackMigrationPreview previewMapVisualStackMigration(MapData map) {
  final beforeResult = buildMapVisualCompositionPlan(map);
  if (!beforeResult.canCompose) {
    return MapVisualStackMigrationPreview._(
      status: MapVisualStackMigrationStatus.blocked,
      before: map,
      after: map,
      beforePlan: null,
      afterPlan: null,
      differences: const <MapVisualStackDifference>[],
      diagnostics: beforeResult.diagnostics,
    );
  }

  if (map.visualStack != null) {
    return MapVisualStackMigrationPreview._(
      status: MapVisualStackMigrationStatus.noChange,
      before: map,
      after: map,
      beforePlan: beforeResult.plan,
      afterPlan: beforeResult.plan,
      differences: const <MapVisualStackDifference>[],
      diagnostics: beforeResult.diagnostics,
    );
  }

  final after = map.copyWith(
    version: ProjectVersion.v3,
    visualStack: MapVisualStackConfig.canonicalV1,
  );
  final afterResult = buildMapVisualCompositionPlan(after);
  if (!afterResult.canCompose) {
    return MapVisualStackMigrationPreview._(
      status: MapVisualStackMigrationStatus.blocked,
      before: map,
      after: map,
      beforePlan: beforeResult.plan,
      afterPlan: null,
      differences: const <MapVisualStackDifference>[],
      diagnostics: <MapVisualCompositionDiagnostic>[
        ...beforeResult.diagnostics,
        ...afterResult.diagnostics,
      ],
    );
  }

  return MapVisualStackMigrationPreview._(
    status: MapVisualStackMigrationStatus.ready,
    before: map,
    after: after,
    beforePlan: beforeResult.plan,
    afterPlan: afterResult.plan,
    differences: _buildDifferences(
      beforeResult.plan!,
      afterResult.plan!,
    ),
    diagnostics: <MapVisualCompositionDiagnostic>[
      ...beforeResult.diagnostics,
      ...afterResult.diagnostics,
    ],
  );
}

/// Applies an explicitly reviewed visual-stack migration preview.
///
/// A changed map rejects the stale preview. Unsupported future semantics are
/// never rewritten. Reapplying to canonical v1 returns the exact input map.
MapData applyMapVisualStackMigration({
  required MapData map,
  required MapVisualStackMigrationPreview preview,
}) {
  if (map != preview.before) {
    throw StateError(
      'Visual stack migration preview is stale for map ${map.id}.',
    );
  }

  switch (preview.status) {
    case MapVisualStackMigrationStatus.blocked:
      throw StateError(
        'Visual stack migration is blocked for map ${map.id}.',
      );
    case MapVisualStackMigrationStatus.noChange:
      return map;
    case MapVisualStackMigrationStatus.ready:
      final current = previewMapVisualStackMigration(map);
      if (current.status != MapVisualStackMigrationStatus.ready ||
          current.after != preview.after ||
          !_sameDifferences(current.differences, preview.differences)) {
        throw StateError(
          'Visual stack migration preview is stale for map ${map.id}.',
        );
      }
      return preview.after;
  }
}

List<MapVisualStackDifference> _buildDifferences(
  MapVisualCompositionPlan before,
  MapVisualCompositionPlan after,
) {
  final beforeSteps = _indexSteps(before.steps);
  final afterSteps = _indexSteps(after.steps);
  final beforeByIdentity = <String, _IndexedCompositionStep>{
    for (final step in beforeSteps) step.identity: step,
  };
  final afterByIdentity = <String, _IndexedCompositionStep>{
    for (final step in afterSteps) step.identity: step,
  };
  final differences = <MapVisualStackDifference>[];

  for (final step in beforeSteps) {
    final matching = afterByIdentity[step.identity];
    if (matching == null) {
      differences.add(
        MapVisualStackDifference(
          kind: MapVisualStackDifferenceKind.removed,
          stepStableKey: step.stableKey,
          occurrence: step.occurrence,
          beforeIndex: step.index,
          afterIndex: null,
        ),
      );
    } else if (matching.index != step.index) {
      differences.add(
        MapVisualStackDifference(
          kind: MapVisualStackDifferenceKind.moved,
          stepStableKey: step.stableKey,
          occurrence: step.occurrence,
          beforeIndex: step.index,
          afterIndex: matching.index,
        ),
      );
    }
  }

  for (final step in afterSteps) {
    if (!beforeByIdentity.containsKey(step.identity)) {
      differences.add(
        MapVisualStackDifference(
          kind: MapVisualStackDifferenceKind.added,
          stepStableKey: step.stableKey,
          occurrence: step.occurrence,
          beforeIndex: null,
          afterIndex: step.index,
        ),
      );
    }
  }
  return differences;
}

List<_IndexedCompositionStep> _indexSteps(
  Iterable<MapVisualCompositionStep> steps,
) {
  final occurrences = <String, int>{};
  final indexed = <_IndexedCompositionStep>[];
  var index = 0;
  for (final step in steps) {
    final stableKey = step.stableKey;
    final occurrence = occurrences[stableKey] ?? 0;
    occurrences[stableKey] = occurrence + 1;
    indexed.add(
      _IndexedCompositionStep(
        stableKey: stableKey,
        occurrence: occurrence,
        index: index,
      ),
    );
    index += 1;
  }
  return indexed;
}

bool _sameDifferences(
  List<MapVisualStackDifference> left,
  List<MapVisualStackDifference> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index].stableKey != right[index].stableKey) return false;
  }
  return true;
}

final class _IndexedCompositionStep {
  const _IndexedCompositionStep({
    required this.stableKey,
    required this.occurrence,
    required this.index,
  });

  final String stableKey;
  final int occurrence;
  final int index;

  String get identity => '$stableKey\u0000$occurrence';
}

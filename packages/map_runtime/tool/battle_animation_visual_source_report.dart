import 'dart:collection';
import 'dart:io';

import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_move_placement_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';

void main(List<String> args) {
  final summaryOnly = args.contains('--summary-only');
  final report = buildBattleAnimationVisualSourceReport();
  final rows = report.rows;
  final counts = report.countBySource;

  stdout.writeln('# Battle Animation Visual Source Report');
  stdout.writeln();
  stdout.writeln('Total normalized SDK/runtime move ids: `${rows.length}`');
  for (final source in <String>[
    'exact Ruby verified',
    'exact RMXP verified',
    'adapted',
    'SDK family fallback',
    'no animation',
    'needs visual retune',
  ]) {
    stdout.writeln('- `$source`: `${counts[source] ?? 0}`');
  }
  stdout.writeln(
    '- `exact RMXP position == 3 phases`: `${report.rmxpPosition3Count}`',
  );
  for (final entry in report.rmxpPlacementPolicyCounts.entries) {
    stdout.writeln('- `RMXP placement ${entry.key}`: `${entry.value}`');
  }
  stdout.writeln(
    '- `critical anchors verified`: '
    '`${report.criticalAnchorsVerified.length}`',
  );
  stdout.writeln(
    '- `needs placement review`: `${report.needsPlacementReview.length}`',
  );

  if (summaryOnly) {
    return;
  }

  stdout.writeln();
  stdout.writeln(
    '| moveId | sdkMoveId | visualSource | recipeId | userAnim | targetAnim |',
  );
  stdout.writeln('| --- | ---: | --- | --- | ---: | ---: |');
  for (final row in rows) {
    stdout.writeln(
      '| `${row.moveId}` | ${row.sdkNumericMoveId ?? ''} | '
      '${row.visualSource} | `${row.recipeId ?? ''}` | '
      '${row.userAnimationId ?? ''} | ${row.targetAnimationId ?? ''} |',
    );
  }

  if (report.duplicateAliases.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('## Duplicate aliases');
    stdout.writeln();
    stdout.writeln('| normalizedMoveId | source ids |');
    stdout.writeln('| --- | --- |');
    for (final duplicate in report.duplicateAliases) {
      stdout.writeln(
        '| `${duplicate.normalizedMoveId}` | '
        '${duplicate.sourceMoveIds.map((id) => '`$id`').join(', ')} |',
      );
    }
  }

  if (report.needsPlacementReview.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('## RMXP placement review');
    stdout.writeln();
    stdout.writeln('| moveId | phase | animationId | policy | implicit |');
    stdout.writeln('| --- | --- | ---: | --- | --- |');
    for (final row in report.needsPlacementReview) {
      stdout.writeln(
        '| `${row.moveId}` | ${row.phase.name} | ${row.animationId} | '
        '${row.policy.name} | ${row.isImplicit} |',
      );
    }
  }
}

BattleAnimationVisualSourceReport buildBattleAnimationVisualSourceReport() {
  final sourceMoveIds = SplayTreeSet<String>()
    ..addAll(BattleSdkMoveIdCatalog.sdkMoveIdByNormalizedMoveId.keys)
    ..addAll(BattleMoveVisualCatalog.recipeBySDKMoveId.keys)
    ..addAll(BattleMoveVisualCatalog.aliasBySDKMoveId.keys)
    ..addAll(BattleMoveVisualCatalog.aliasBySDKMoveId.values);

  final sourceMoveIdsByNormalizedId =
      SplayTreeMap<String, SplayTreeSet<String>>();
  for (final sourceMoveId in sourceMoveIds) {
    final normalizedMoveId =
        BattleMoveVisualCatalog.normalizeSDKMoveId(sourceMoveId);
    if (normalizedMoveId == null) {
      continue;
    }
    sourceMoveIdsByNormalizedId
        .putIfAbsent(normalizedMoveId, SplayTreeSet<String>.new)
        .add(sourceMoveId);
  }

  final rows = <BattleAnimationVisualSourceRow>[
    for (final normalizedMoveId in sourceMoveIdsByNormalizedId.keys)
      _classify(normalizedMoveId),
  ];
  final counts = <String, int>{};
  for (final row in rows) {
    counts.update(row.visualSource, (count) => count + 1, ifAbsent: () => 1);
  }

  final duplicateAliases = <BattleAnimationDuplicateAlias>[
    for (final entry in sourceMoveIdsByNormalizedId.entries)
      if (entry.value.length > 1)
        BattleAnimationDuplicateAlias(
          normalizedMoveId: entry.key,
          sourceMoveIds: entry.value.toList(growable: false),
        ),
  ];
  final placementAuditRows = _buildRmxpPlacementAuditRows(rows);
  final rmxpPlacementPolicyCounts = <String, int>{};
  for (final row in placementAuditRows) {
    rmxpPlacementPolicyCounts.update(
      row.policy.name,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  final criticalAnchorsVerified = <String>[
    for (final entry
        in RmxpMovePlacementCatalog.auditedCriticalMovePolicies.entries)
      if (_criticalPolicyIsVerified(entry.key, entry.value)) entry.key,
  ];
  final criticalMoveIds =
      RmxpMovePlacementCatalog.auditedCriticalMovePolicies.keys.toSet();
  final needsPlacementReview = <BattleAnimationRmxpPlacementAuditRow>[
    for (final row in placementAuditRows)
      if (row.isImplicit && criticalMoveIds.contains(row.moveId)) row,
  ];

  return BattleAnimationVisualSourceReport(
    rows: rows,
    countBySource: Map<String, int>.unmodifiable(counts),
    duplicateAliases: duplicateAliases,
    rmxpPosition3Count: placementAuditRows.length,
    rmxpPlacementPolicyCounts:
        Map<String, int>.unmodifiable(rmxpPlacementPolicyCounts),
    criticalAnchorsVerified: List<String>.unmodifiable(criticalAnchorsVerified),
    needsPlacementReview:
        List<BattleAnimationRmxpPlacementAuditRow>.unmodifiable(
      needsPlacementReview,
    ),
  );
}

List<BattleAnimationRmxpPlacementAuditRow> _buildRmxpPlacementAuditRows(
  List<BattleAnimationVisualSourceRow> rows,
) {
  final auditRows = <BattleAnimationRmxpPlacementAuditRow>[];
  for (final row in rows) {
    final userAnimationId = row.userAnimationId;
    if (userAnimationId != null) {
      _addPlacementAuditRow(
        auditRows,
        moveId: row.moveId,
        phase: RmxpPlacementPhase.user,
        animationId: userAnimationId,
      );
    }
    final targetAnimationId = row.targetAnimationId;
    if (targetAnimationId != null) {
      _addPlacementAuditRow(
        auditRows,
        moveId: row.moveId,
        phase: RmxpPlacementPhase.target,
        animationId: targetAnimationId,
      );
    }
  }
  return auditRows;
}

void _addPlacementAuditRow(
  List<BattleAnimationRmxpPlacementAuditRow> rows, {
  required String moveId,
  required RmxpPlacementPhase phase,
  required int animationId,
}) {
  final animation = BattleSdkRmxpAnimationCatalog.require(animationId);
  if (animation.position != 3) {
    return;
  }
  final spec = RmxpMovePlacementCatalog.resolve(
    sdkMoveId: moveId,
    animationId: animationId,
    phase: phase,
    animation: animation,
  );
  rows.add(
    BattleAnimationRmxpPlacementAuditRow(
      moveId: moveId,
      phase: phase,
      animationId: animationId,
      policy: spec.policy,
      isImplicit: spec.isImplicit,
    ),
  );
}

bool _criticalPolicyIsVerified(
  String moveId,
  RmxpPlacementPolicy expectedPolicy,
) {
  final sdkNumericMoveId =
      BattleSdkMoveIdCatalog.sdkMoveIdByNormalizedMoveId[moveId];
  if (sdkNumericMoveId == null) {
    return false;
  }
  final animationId = BattleSdkRmxpAnimationCatalog
      .moveTargetAnimationIdBySdkMoveId[sdkNumericMoveId];
  if (animationId == null) {
    return false;
  }
  final animation = BattleSdkRmxpAnimationCatalog.require(animationId);
  final spec = RmxpMovePlacementCatalog.resolve(
    sdkMoveId: moveId,
    animationId: animationId,
    phase: RmxpPlacementPhase.target,
    animation: animation,
  );
  return spec.policy == expectedPolicy && !spec.isImplicit;
}

BattleAnimationVisualSourceRow _classify(String moveId) {
  final normalizedMoveId =
      BattleMoveVisualCatalog.normalizeSDKMoveId(moveId) ?? moveId;
  final resolvedRecipe = _resolveDirectRecipe(normalizedMoveId);
  final recipe = resolvedRecipe?.recipeId;
  final sdkNumericMoveId =
      BattleSdkMoveIdCatalog.sdkMoveIdByNormalizedMoveId[normalizedMoveId];
  final userAnimationId = sdkNumericMoveId == null
      ? null
      : BattleSdkRmxpAnimationCatalog
          .moveUserAnimationIdBySdkMoveId[sdkNumericMoveId];
  final targetAnimationId = sdkNumericMoveId == null
      ? null
      : BattleSdkRmxpAnimationCatalog
          .moveTargetAnimationIdBySdkMoveId[sdkNumericMoveId];

  final visualSource = () {
    if (recipe == BattleMoveVisualRecipeId.noAnimation ||
        BattleMoveVisualCatalog.explicitNoAnimationSDKIds
            .contains(normalizedMoveId)) {
      return 'no animation';
    }
    if (recipe != null &&
        recipe.name.startsWith('sdkExact') &&
        BattleMoveVisualCatalog.exactRubySDKMoveIds
            .contains(normalizedMoveId)) {
      return 'exact Ruby verified';
    }
    if (userAnimationId != null || targetAnimationId != null) {
      return 'exact RMXP verified';
    }
    if (recipe != null &&
        (BattleMoveVisualCatalog.adaptedSDKMoveIds.contains(normalizedMoveId) ||
            BattleMoveVisualCatalog.adaptedSDKMoveIds
                .contains(resolvedRecipe?.resolvedSDKMoveId))) {
      return 'adapted';
    }
    if (recipe != null) {
      return 'SDK family fallback';
    }
    return 'needs visual retune';
  }();

  return BattleAnimationVisualSourceRow(
    moveId: normalizedMoveId,
    sdkNumericMoveId: sdkNumericMoveId,
    visualSource: visualSource,
    recipeId: recipe?.name,
    userAnimationId: userAnimationId,
    targetAnimationId: targetAnimationId,
  );
}

_ResolvedMoveRecipe? _resolveDirectRecipe(String sdkMoveId) {
  if (BattleMoveVisualCatalog.explicitNoAnimationSDKIds.contains(sdkMoveId)) {
    return _ResolvedMoveRecipe(
      recipeId: BattleMoveVisualRecipeId.noAnimation,
      resolvedSDKMoveId: sdkMoveId,
    );
  }
  final direct = BattleMoveVisualCatalog.recipeBySDKMoveId[sdkMoveId];
  if (direct != null) {
    return _ResolvedMoveRecipe(
      recipeId: direct,
      resolvedSDKMoveId: sdkMoveId,
    );
  }

  final visited = <String>{sdkMoveId};
  var current = sdkMoveId;
  while (true) {
    final next = BattleMoveVisualCatalog.aliasBySDKMoveId[current];
    if (next == null || !visited.add(next)) {
      return null;
    }
    final recipe = BattleMoveVisualCatalog.recipeBySDKMoveId[next];
    if (recipe != null) {
      return _ResolvedMoveRecipe(
        recipeId: recipe,
        resolvedSDKMoveId: next,
      );
    }
    current = next;
  }
}

final class _ResolvedMoveRecipe {
  const _ResolvedMoveRecipe({
    required this.recipeId,
    required this.resolvedSDKMoveId,
  });

  final BattleMoveVisualRecipeId recipeId;
  final String resolvedSDKMoveId;
}

final class BattleAnimationVisualSourceReport {
  const BattleAnimationVisualSourceReport({
    required this.rows,
    required this.countBySource,
    required this.duplicateAliases,
    required this.rmxpPosition3Count,
    required this.rmxpPlacementPolicyCounts,
    required this.criticalAnchorsVerified,
    required this.needsPlacementReview,
  });

  final List<BattleAnimationVisualSourceRow> rows;
  final Map<String, int> countBySource;
  final List<BattleAnimationDuplicateAlias> duplicateAliases;
  final int rmxpPosition3Count;
  final Map<String, int> rmxpPlacementPolicyCounts;
  final List<String> criticalAnchorsVerified;
  final List<BattleAnimationRmxpPlacementAuditRow> needsPlacementReview;
}

final class BattleAnimationDuplicateAlias {
  const BattleAnimationDuplicateAlias({
    required this.normalizedMoveId,
    required this.sourceMoveIds,
  });

  final String normalizedMoveId;
  final List<String> sourceMoveIds;
}

final class BattleAnimationVisualSourceRow {
  const BattleAnimationVisualSourceRow({
    required this.moveId,
    required this.sdkNumericMoveId,
    required this.visualSource,
    required this.recipeId,
    required this.userAnimationId,
    required this.targetAnimationId,
  });

  final String moveId;
  final int? sdkNumericMoveId;
  final String visualSource;
  final String? recipeId;
  final int? userAnimationId;
  final int? targetAnimationId;
}

final class BattleAnimationRmxpPlacementAuditRow {
  const BattleAnimationRmxpPlacementAuditRow({
    required this.moveId,
    required this.phase,
    required this.animationId,
    required this.policy,
    required this.isImplicit,
  });

  final String moveId;
  final RmxpPlacementPhase phase;
  final int animationId;
  final RmxpPlacementPolicy policy;
  final bool isImplicit;
}

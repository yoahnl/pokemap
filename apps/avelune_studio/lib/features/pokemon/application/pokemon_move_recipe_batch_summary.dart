import 'package:map_authoring/map_authoring.dart';

final class PokemonMoveRecipeBatchSummary {
  PokemonMoveRecipeBatchSummary(List<BattleMoveRecipeBatchEntry> results)
    : imported = _count(results, {BattleMoveRecipeBatchStatus.imported}),
      alreadyPresent = _count(results, {
        BattleMoveRecipeBatchStatus.alreadyPresent,
      }),
      preserved = _count(results, {
        BattleMoveRecipeBatchStatus.custom,
        BattleMoveRecipeBatchStatus.preserved,
      }),
      missing = _count(results, {BattleMoveRecipeBatchStatus.missing}),
      uncertain = _count(results, {
        BattleMoveRecipeBatchStatus.ambiguous,
        BattleMoveRecipeBatchStatus.uncertain,
      }),
      pilots = results.where((entry) => entry.isPilotFallback).length,
      failed = _count(results, {BattleMoveRecipeBatchStatus.failed}),
      details = [
        for (final entry in results)
          if (entry.status != BattleMoveRecipeBatchStatus.imported) entry,
      ];

  final int imported;
  final int alreadyPresent;
  final int preserved;
  final int missing;
  final int uncertain;
  final int pilots;
  final int failed;
  final List<BattleMoveRecipeBatchEntry> details;

  static int _count(
    List<BattleMoveRecipeBatchEntry> results,
    Set<BattleMoveRecipeBatchStatus> statuses,
  ) => results.where((entry) => statuses.contains(entry.status)).length;
}

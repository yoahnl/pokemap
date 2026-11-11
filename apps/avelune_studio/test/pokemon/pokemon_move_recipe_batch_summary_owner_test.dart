import 'package:avelune_studio/features/pokemon/application/pokemon_move_recipe_batch_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

BattleMoveRecipeBatchEntry _entry(
  int index,
  BattleMoveRecipeBatchStatus status, {
  bool pilot = false,
}) => BattleMoveRecipeBatchEntry(
  index: index,
  projectMoveId: 'move-$index',
  status: status,
  isPilotFallback: pilot,
);

void main() {
  test('every status lands in its own counter', () {
    final summary = PokemonMoveRecipeBatchSummary([
      _entry(0, BattleMoveRecipeBatchStatus.imported),
      _entry(1, BattleMoveRecipeBatchStatus.imported),
      _entry(2, BattleMoveRecipeBatchStatus.alreadyPresent),
      _entry(3, BattleMoveRecipeBatchStatus.custom),
      _entry(4, BattleMoveRecipeBatchStatus.preserved),
      _entry(5, BattleMoveRecipeBatchStatus.missing),
      _entry(6, BattleMoveRecipeBatchStatus.ambiguous),
      _entry(7, BattleMoveRecipeBatchStatus.uncertain),
      _entry(8, BattleMoveRecipeBatchStatus.failed),
    ]);

    expect(summary.imported, 2);
    expect(summary.alreadyPresent, 1);
    expect(summary.preserved, 2);
    expect(summary.missing, 1);
    expect(summary.uncertain, 2);
    expect(summary.failed, 1);
    expect(summary.pilots, 0);
  });

  test('details keep everything that was not imported, in order', () {
    final summary = PokemonMoveRecipeBatchSummary([
      _entry(0, BattleMoveRecipeBatchStatus.missing),
      _entry(1, BattleMoveRecipeBatchStatus.imported),
      _entry(2, BattleMoveRecipeBatchStatus.failed),
    ]);

    expect(summary.details.map((entry) => entry.index), [0, 2]);
  });

  test('pilot fallbacks are counted whatever their status', () {
    final summary = PokemonMoveRecipeBatchSummary([
      _entry(0, BattleMoveRecipeBatchStatus.imported, pilot: true),
      _entry(1, BattleMoveRecipeBatchStatus.alreadyPresent, pilot: true),
      _entry(2, BattleMoveRecipeBatchStatus.imported),
    ]);

    expect(summary.pilots, 2);
    expect(summary.imported, 2);
  });

  test('an empty batch is all zero', () {
    final summary = PokemonMoveRecipeBatchSummary(const []);

    expect([
      summary.imported,
      summary.alreadyPresent,
      summary.preserved,
      summary.missing,
      summary.uncertain,
      summary.pilots,
      summary.failed,
      summary.details.length,
    ], everyElement(0));
  });
}

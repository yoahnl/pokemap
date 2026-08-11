import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('legacy item registries and per-item battle facades are absent', () {
    const forbiddenSymbols = <String>{
      'PlayerItemEffectRegistry',
      'PlayerItemOperations',
      'BattleBagHpHealItemKind',
      'tryApplyRuntimeBattlePotionUse',
      'tryApplyRuntimeBattleSuperPotionUse',
      'tryApplyRuntimeBattleHyperPotionUse',
      'tryApplyRuntimeBattleMaxPotionUse',
      'tryApplyRuntimePsdkBattleBagHpHealItemUse',
      'applyPotionTurn',
      'applySuperPotionTurn',
      'applyHyperPotionTurn',
      'applyMaxPotionTurn',
    };
    final violations = <String>[];

    for (final directoryPath in <String>[
      '../map_gameplay/lib',
      '../map_battle/lib',
      '../map_runtime/lib',
    ]) {
      for (final entity in Directory(directoryPath).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final symbol in forbiddenSymbols) {
          if (source.contains(symbol)) {
            violations.add('${entity.path}: $symbol');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('the save codec has no knowledge of the legacy bag wire', () {
    final source = File('lib/src/models/save_data.dart').readAsStringSync();

    expect(source, isNot(contains('categoryId')));
    expect(source, isNot(contains('LegacyBag')));
    expect(source, isNot(contains('migrateBag')));
    expect(source, isNot(contains('convertBag')));
  });
}

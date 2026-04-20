import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_layout.dart';

void main() {
  Rect rectOrZero(Rect? rect) => rect ?? Rect.zero;

  void expectVisibleRectsInsideHud(
    BattleSceneHudLayout layout, {
    required bool allowMissingHpValue,
  }) {
    final visibleRects = <Rect>[
      layout.nameRect,
      layout.levelRect,
      layout.hpLabelRect,
      layout.hpBarRect,
      if (layout.genderRect != null) layout.genderRect!,
      if (layout.statusRect != null) layout.statusRect!,
      if (layout.hpValueRect != null) layout.hpValueRect!,
    ];

    for (final rect in visibleRects) {
      expect(layout.hudRect.contains(rect.topLeft), isTrue);
      expect(
        layout.hudRect.contains(rect.bottomRight - const Offset(0.01, 0.01)),
        isTrue,
      );
    }

    expect(layout.nameRect.overlaps(layout.levelRect), isFalse);
    expect(rectOrZero(layout.genderRect).overlaps(layout.levelRect), isFalse);
    expect(layout.hpBarRect.overlaps(layout.nameRect), isFalse);
    if (!allowMissingHpValue) {
      expect(layout.hpValueRect, isNotNull);
    }
  }

  group('BattleSceneHudLayout', () {
    test('keeps an enemy hud compact and overlap-free', () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 220, 72),
        isPlayerSide: false,
        speciesText: 'Pikachu',
        genderSymbol: '♂',
        levelText: 'Lv.15',
        hpValueText: '100%',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.showsHpValue, isFalse);
    });

    test('keeps a player hud robust with long text and visible hp values', () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 286, 84),
        isPlayerSide: true,
        speciesText: 'very_long_species_name_that_should_not_overlap',
        genderSymbol: '♀',
        levelText: 'Lv.100',
        hpValueText: '152/152',
        statusText: 'BRN',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: false);
      expect(layout.showsHpValue, isTrue);
    });

    test('hides numeric hp before allowing internal overlap on compact player hud',
        () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 154, 68),
        isPlayerSide: true,
        speciesText: 'very_long_species_name_that_should_not_overlap',
        genderSymbol: '♂',
        levelText: 'Lv.100',
        hpValueText: '152/152',
        statusText: 'PAR',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.showsHpValue, isFalse);
    });
  });
}

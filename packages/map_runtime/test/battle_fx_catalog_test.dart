import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';

void main() {
  group('BattleFxCatalog', () {
    test('contains returns true for copied effect ids', () {
      expect(BattleFxCatalog.contains('fireball'), isTrue);
      expect(BattleFxCatalog.contains('shadowball'), isTrue);
      expect(BattleFxCatalog.contains('impact'), isTrue);
      expect(BattleFxCatalog.contains('tatsugiri'), isTrue);
      expect(BattleFxCatalog.contains('protect'), isFalse);
    });

    test('require returns expected package asset key', () {
      expect(
        BattleFxCatalog.require('shadowball').assetKey,
        equals('packages/map_runtime/assets/fx/shadowball.png'),
      );
    });

    test('require throws on unknown effect id', () {
      expect(
        () => BattleFxCatalog.require('definitely-missing-fx'),
        throwsStateError,
      );
    });

    test('allEffectIds contains no duplicates', () {
      final ids = BattleFxCatalog.allEffectIds.toList(growable: false);
      expect(ids.toSet().length, equals(ids.length));
    });

    test('all asset keys end with .png', () {
      for (final effectId in BattleFxCatalog.allEffectIds) {
        expect(
          BattleFxCatalog.require(effectId).assetKey,
          endsWith('.png'),
          reason: effectId,
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';

void main() {
  group('BattleFxCatalog', () {
    test('contains returns true for copied effect ids', () {
      expect(BattleFxCatalog.contains('aerial_ace'), isTrue);
      expect(BattleFxCatalog.contains('vine_whip'), isTrue);
      expect(BattleFxCatalog.contains('thunder_02'), isTrue);
      expect(BattleFxCatalog.contains('stat_up'), isTrue);
      expect(BattleFxCatalog.contains('protect'), isFalse);
    });

    test('require returns expected package asset key', () {
      expect(
        BattleFxCatalog.require('aerial_ace').assetKey,
        equals('packages/map_runtime/assets/battle_animations/aerial_ace.png'),
      );
    });

    test('declares SDK sprite sheet metadata for exact recipes', () {
      final spec = BattleFxCatalog.require('aerial_ace');

      expect(spec.kind, BattleFxAssetKind.spriteSheet);
      expect(spec.frameWidth, equals(208));
      expect(spec.frameHeight, equals(192));
      expect(spec.frameCount, equals(13));
      expect(spec.columns, equals(13));
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

    test('no catalog entry points to the removed legacy fx folder', () {
      for (final effectId in BattleFxCatalog.allEffectIds) {
        expect(
          BattleFxCatalog.require(effectId).assetKey,
          isNot(contains('/assets/fx/')),
          reason: effectId,
        );
      }
    });
  });
}

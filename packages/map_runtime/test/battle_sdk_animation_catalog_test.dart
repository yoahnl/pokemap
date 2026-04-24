import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';

void main() {
  group('Battle SDK animation catalog', () {
    test('declares SDK animation assets with package keys', () {
      final aerialAce = BattleFxCatalog.require('aerial_ace');
      final vineWhip = BattleFxCatalog.require('vine_whip');
      final thunderWave = BattleFxCatalog.require('thunder_02');

      expect(aerialAce.kind, equals(BattleFxAssetKind.spriteSheet));
      expect(
          aerialAce.assetKey,
          equals(
              'packages/map_runtime/assets/battle_animations/aerial_ace.png'));
      expect(aerialAce.frameWidth, equals(208));
      expect(aerialAce.frameHeight, equals(192));
      expect(aerialAce.frameCount, equals(13));

      expect(vineWhip.kind, equals(BattleFxAssetKind.spriteSheet));
      expect(vineWhip.frameWidth, equals(200));
      expect(vineWhip.frameHeight, equals(200));
      expect(vineWhip.frameCount, equals(56));

      expect(thunderWave.kind, equals(BattleFxAssetKind.spriteSheet));
      expect(thunderWave.frameWidth, equals(192));
      expect(thunderWave.frameHeight, equals(192));
    });

    test('does not expose legacy Showdown asset paths', () {
      for (final assetId in BattleFxCatalog.allEffectIds) {
        final spec = BattleFxCatalog.require(assetId);
        expect(spec.assetKey, contains('assets/battle_animations/'));
        expect(spec.assetKey, isNot(contains('assets/fx/')));
      }
    });

    test('declared SDK assets exist on disk', () {
      for (final assetId in BattleFxCatalog.allEffectIds) {
        final spec = BattleFxCatalog.require(assetId);
        final relativePath =
            spec.assetKey.replaceFirst('packages/map_runtime/', '');
        expect(File(relativePath).existsSync(), isTrue, reason: assetId);
      }
    });

    test('declared sprite-sheet source rects stay inside png bounds', () {
      for (final assetId in BattleFxCatalog.allEffectIds) {
        final spec = BattleFxCatalog.require(assetId);

        for (var frameIndex = 0; frameIndex < spec.frameCount; frameIndex++) {
          final column = frameIndex % spec.columns;
          final row = frameIndex ~/ spec.columns;
          final right = (column + 1) * spec.frameWidth;
          final bottom = (row + 1) * spec.frameHeight;

          expect(right, lessThanOrEqualTo(spec.width), reason: assetId);
          expect(bottom, lessThanOrEqualTo(spec.height), reason: assetId);
        }
      }
    });
  });
}

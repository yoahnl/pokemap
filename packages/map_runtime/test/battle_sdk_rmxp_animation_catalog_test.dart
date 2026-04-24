import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';

void main() {
  group('BattleSdkRmxpAnimationCatalog', () {
    test('imports the full Pokemon SDK RMXP animation dataset', () {
      expect(BattleSdkRmxpAnimationCatalog.byAnimationId, hasLength(874));
      expect(BattleSdkRmxpAnimationCatalog.moveTargetAnimationIdBySdkMoveId,
          hasLength(652));
      expect(BattleSdkRmxpAnimationCatalog.moveUserAnimationIdBySdkMoveId,
          hasLength(243));
      expect(
        BattleSdkRmxpAnimationCatalog.moveTargetAnimationIdBySdkMoveId.values
            .whereType<int>(),
        hasLength(615),
      );
    });

    test('maps visible sample moves to exact SDK RMXP animations', () {
      final samples = <String, ({int moveId, int? user, int? target})>{
        'thundershock': (moveId: 84, user: null, target: 84),
        'swift': (moveId: 129, user: null, target: 129),
        'shockwave': (moveId: 351, user: 351, target: 351),
        'electroball': (moveId: 486, user: null, target: 676),
      };

      for (final entry in samples.entries) {
        expect(
          BattleSdkMoveIdCatalog.sdkMoveIdByNormalizedMoveId[entry.key],
          equals(entry.value.moveId),
          reason: entry.key,
        );
        expect(
          BattleSdkRmxpAnimationCatalog
              .moveUserAnimationIdBySdkMoveId[entry.value.moveId],
          equals(entry.value.user),
          reason: '${entry.key} user',
        );
        expect(
          BattleSdkRmxpAnimationCatalog
              .moveTargetAnimationIdBySdkMoveId[entry.value.moveId],
          equals(entry.value.target),
          reason: '${entry.key} target',
        );
        final animation = BattleSdkRmxpAnimationCatalog
            .byAnimationId[entry.value.target ?? entry.value.user];
        expect(animation, isNotNull, reason: entry.key);
        expect(animation!.frameMax, greaterThan(0), reason: entry.key);
        expect(animation.frames, isNotEmpty, reason: entry.key);
        expect(BattleFxCatalog.contains(animation.assetId), isTrue);
      }

      expect(BattleSdkRmxpAnimationCatalog.byAnimationId[84]?.name,
          equals('N/ECLAIR'));
      expect(BattleSdkRmxpAnimationCatalog.byAnimationId[84]?.assetId,
          equals('017_thunder01'));
      expect(BattleSdkRmxpAnimationCatalog.byAnimationId[129]?.name,
          equals('F/METEORE'));
      expect(BattleSdkRmxpAnimationCatalog.byAnimationId[129]?.assetId,
          equals('025_support02'));
    });

    test('every referenced RMXP sheet exists in the SDK asset catalog', () {
      final missing = <String>[];
      for (final animation
          in BattleSdkRmxpAnimationCatalog.byAnimationId.values) {
        if (!BattleFxCatalog.contains(animation.assetId)) {
          missing.add('${animation.id}:${animation.animationName}');
        }
      }
      expect(missing, isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/movement_feedback.dart';

void main() {
  group('movement feedback', () {
    test('returns surf feedback for waterRequiresSurf reason', () {
      expect(
        runtimeMovementBlockedMessage(
          GameplayMovementBlockReason.waterRequiresSurf,
        ),
        waterRequiresSurfFeedbackMessage,
      );
    });

    test('returns null for generic solid and out-of-bounds reasons', () {
      expect(
        runtimeMovementBlockedMessage(GameplayMovementBlockReason.solid),
        isNull,
      );
      expect(
        runtimeMovementBlockedMessage(GameplayMovementBlockReason.outOfBounds),
        isNull,
      );
    });
  });
}

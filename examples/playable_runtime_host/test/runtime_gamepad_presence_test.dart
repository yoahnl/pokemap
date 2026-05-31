import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/runtime_gamepad_presence.dart';

void main() {
  group('RuntimeGamepadPresence', () {
    test('reports false when no connected gamepad is listed', () async {
      final presence = RuntimeGamepadPresence(
        connectedGamepadCount: () async => 0,
      );

      await expectLater(presence.hasConnectedGamepads(), completion(isFalse));
    });

    test('reports true when at least one connected gamepad is listed',
        () async {
      final presence = RuntimeGamepadPresence(
        connectedGamepadCount: () async => 2,
      );

      await expectLater(presence.hasConnectedGamepads(), completion(isTrue));
    });
  });
}

import 'package:pokemap_loader/src/runtime_battle_command_overlay_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowRuntimeBattleCommandOverlay', () {
    test('shows the Flutter battle overlay whenever battle is active and snapshot exists', () {
      expect(
        shouldShowRuntimeBattleCommandOverlay(
          supportsTouchControls: false,
          hasConnectedGamepad: true,
          isBattleActive: true,
          hasSnapshot: true,
        ),
        isTrue,
      );
    });

    test('hides the Flutter battle overlay when there is no battle snapshot', () {
      expect(
        shouldShowRuntimeBattleCommandOverlay(
          supportsTouchControls: true,
          hasConnectedGamepad: true,
          isBattleActive: true,
          hasSnapshot: false,
        ),
        isFalse,
      );
    });

    test('hides the Flutter battle overlay when battle is not active', () {
      expect(
        shouldShowRuntimeBattleCommandOverlay(
          supportsTouchControls: true,
          hasConnectedGamepad: false,
          isBattleActive: false,
          hasSnapshot: true,
        ),
        isFalse,
      );
    });
  });
}

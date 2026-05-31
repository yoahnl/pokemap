import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/runtime_touch_controls_visibility.dart';

void main() {
  group('resolveRuntimeTouchControlsVisibility', () {
    test('shows touch controls only when no blocker is active', () {
      final state = resolveRuntimeTouchControlsVisibility(
        supportsTouchControls: true,
        userHidden: false,
        hasConnectedGamepad: false,
        isBattleActive: false,
      );

      expect(state.showToggleButton, isTrue);
      expect(state.showControls, isTrue);
      expect(state.blockReason, isNull);
      expect(state.toggleTooltip, equals('Masquer les contrôles tactiles'));
    });

    test('hides controls during battle but keeps the toggle button', () {
      final state = resolveRuntimeTouchControlsVisibility(
        supportsTouchControls: true,
        userHidden: false,
        hasConnectedGamepad: false,
        isBattleActive: true,
      );

      expect(state.showToggleButton, isTrue);
      expect(state.showControls, isFalse);
      expect(
        state.blockReason,
        RuntimeTouchControlsBlockReason.battleActive,
      );
      expect(
        state.toggleTooltip,
        equals('Combat en cours · les contrôles tactiles sont masqués'),
      );
    });

    test('hides controls when a gamepad is connected', () {
      final state = resolveRuntimeTouchControlsVisibility(
        supportsTouchControls: true,
        userHidden: false,
        hasConnectedGamepad: true,
        isBattleActive: false,
      );

      expect(state.showToggleButton, isTrue);
      expect(state.showControls, isFalse);
      expect(
        state.blockReason,
        RuntimeTouchControlsBlockReason.gamepadConnected,
      );
      expect(
        state.toggleTooltip,
        equals('Manette connectée · les contrôles tactiles sont masqués'),
      );
    });

    test('remembers the explicit user hide preference', () {
      final state = resolveRuntimeTouchControlsVisibility(
        supportsTouchControls: true,
        userHidden: true,
        hasConnectedGamepad: false,
        isBattleActive: false,
      );

      expect(state.showToggleButton, isTrue);
      expect(state.showControls, isFalse);
      expect(
        state.blockReason,
        RuntimeTouchControlsBlockReason.userHidden,
      );
      expect(state.toggleTooltip, equals('Afficher les contrôles tactiles'));
    });
  });
}

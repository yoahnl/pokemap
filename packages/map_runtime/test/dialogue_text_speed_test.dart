import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('RuntimeDialogueTextSpeed', () {
    test('keeps an explicit instant mode for backwards-compatible rendering',
        () {
      expect(RuntimeDialogueTextSpeed.instant.revealInterval, isNull);
      expect(RuntimeDialogueTextSpeed.fromStorage('instant'),
          RuntimeDialogueTextSpeed.instant);
    });

    test('normalizes invalid persisted values to the requested fallback', () {
      expect(
        RuntimeDialogueTextSpeed.fromStorage(
          'warp-speed',
          fallback: RuntimeDialogueTextSpeed.normal,
        ),
        RuntimeDialogueTextSpeed.normal,
      );
    });

    test('orders real reveal intervals from slowest to fastest', () {
      expect(
        RuntimeDialogueTextSpeed.slow.revealInterval!,
        greaterThan(RuntimeDialogueTextSpeed.normal.revealInterval!),
      );
      expect(
        RuntimeDialogueTextSpeed.normal.revealInterval!,
        greaterThan(RuntimeDialogueTextSpeed.fast.revealInterval!),
      );
    });
  });
}

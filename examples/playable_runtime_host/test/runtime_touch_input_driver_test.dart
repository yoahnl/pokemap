import 'package:pokemap_loader/src/runtime_touch_input_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('runtimeInputControlFromTouchVector', () {
    test('uses a dead zone and dominant axis for virtual stick movement', () {
      expect(
          runtimeInputControlFromTouchVector(const Offset(0.1, 0.1)), isNull);
      expect(
        runtimeInputControlFromTouchVector(const Offset(0.8, 0.2)),
        RuntimeInputControl.right,
      );
      expect(
        runtimeInputControlFromTouchVector(const Offset(-0.9, 0.1)),
        RuntimeInputControl.left,
      );
      expect(
        runtimeInputControlFromTouchVector(const Offset(0.2, -0.95)),
        RuntimeInputControl.up,
      );
      expect(
        runtimeInputControlFromTouchVector(const Offset(0.2, 0.95)),
        RuntimeInputControl.down,
      );
    });
  });

  group('RuntimeTouchInputDriver', () {
    test('emits only the press/release transitions needed by the runtime', () {
      final driver = RuntimeTouchInputDriver();

      expect(
        driver.updateVector(const Offset(0.9, 0.1)),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.right),
        ],
      );
      expect(driver.updateVector(const Offset(0.8, 0.2)), isEmpty);
      expect(
        driver.updateVector(const Offset(-0.8, 0.1)),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.right),
          RuntimeInputEvent.press(RuntimeInputControl.left),
        ],
      );
      expect(
        driver.updateVector(Offset.zero),
        const <RuntimeInputEvent>[
          RuntimeInputEvent.release(RuntimeInputControl.left),
        ],
      );
    });
  });
}

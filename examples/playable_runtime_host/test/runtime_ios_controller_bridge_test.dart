import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:playable_runtime_host/src/runtime_ios_controller_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtimeInputEventFromIosControllerMessage', () {
    test('maps valid controller payloads to runtime events', () {
      expect(
        runtimeInputEventFromIosControllerMessage(const <String, String>{
          'control': 'primary',
          'phase': 'press',
        }),
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(
        runtimeInputEventFromIosControllerMessage(const <String, String>{
          'control': 'left',
          'phase': 'release',
        }),
        const RuntimeInputEvent.release(RuntimeInputControl.left),
      );
    });

    test('ignores unsupported payloads', () {
      expect(runtimeInputEventFromIosControllerMessage(null), isNull);
      expect(
        runtimeInputEventFromIosControllerMessage(const <String, String>{
          'control': 'start',
          'phase': 'press',
        }),
        isNull,
      );
      expect(
        runtimeInputEventFromIosControllerMessage(const <String, String>{
          'control': 'primary',
          'phase': 'hold',
        }),
        isNull,
      );
    });
  });

  test('dispatches only supported iOS controller events from the stream',
      () async {
    final controller = StreamController<Object?>();
    final recordedEvents = <RuntimeInputEvent>[];

    final subscription = listenToRuntimeIosControllerEvents(
      eventStream: controller.stream,
      dispatch: (event) {
        recordedEvents.add(event);
        return true;
      },
    );

    controller.add(const <String, String>{
      'control': 'up',
      'phase': 'press',
    });
    controller.add(const <String, String>{
      'control': 'secondary',
      'phase': 'release',
    });
    controller.add(const <String, String>{
      'control': 'unsupported',
      'phase': 'press',
    });

    await pumpEventQueue();
    await subscription.cancel();
    await controller.close();

    expect(
      recordedEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.up),
        RuntimeInputEvent.release(RuntimeInputControl.secondary),
      ],
    );
  });
}

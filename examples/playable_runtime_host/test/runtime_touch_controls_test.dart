import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:playable_runtime_host/src/runtime_touch_controls.dart';

void main() {
  testWidgets('lays out the virtual joystick and buttons for portrait',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RuntimeTouchControls(
            dispatch: (_) {},
          ),
        ),
      ),
    );

    final joystickCenter = tester.getCenter(
      find.byKey(const Key('runtime-touch-joystick')),
    );
    final primaryCenter = tester.getCenter(
      find.byKey(const Key('runtime-touch-primary-button')),
    );

    expect(joystickCenter.dx, lessThan(195));
    expect(primaryCenter.dx, greaterThan(195));
  });

  testWidgets('dispatches primary and secondary button presses and releases',
      (tester) async {
    final recordedEvents = <RuntimeInputEvent>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RuntimeTouchControls(
            dispatch: recordedEvents.add,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('runtime-touch-primary-button'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(
      recordedEvents,
      const <RuntimeInputEvent>[
        RuntimeInputEvent.press(RuntimeInputControl.primary),
        RuntimeInputEvent.release(RuntimeInputControl.primary),
      ],
    );
  });
}

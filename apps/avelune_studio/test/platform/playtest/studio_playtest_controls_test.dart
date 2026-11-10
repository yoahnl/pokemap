import 'package:avelune_studio/platform/playtest/studio_playtest_controls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('detached and busy controls cannot mutate a test session', () async {
    final controls = StudioPlaytestControls();
    final calls = <String>[];
    await controls.save();
    await controls.newGame();
    controls.requestClose();
    expect(controls.attached, isFalse);
    var status = const StudioPlaytestStatus(ready: true, busy: true);
    controls.attach(
      Object(),
      status: () => status,
      save: () async => calls.add('save'),
      resume: () async => calls.add('resume'),
      newGame: () async => calls.add('new'),
      togglePause: () async => calls.add('pause'),
      setSpeed: (speed) => calls.add('speed:${speed.multiplier}'),
      toggleDiagonal: () => calls.add('diagonal'),
      requestClose: () => calls.add('close'),
    );
    await controls.save();
    await controls.resume();
    await controls.newGame();
    await controls.togglePause();
    controls.setTestSpeed(PlaytestSpeed.normal);
    controls.toggleDiagonal();
    expect(calls, isEmpty);
    status = const StudioPlaytestStatus(ready: true);
    await controls.resume();
    expect(calls, isEmpty);
    status = const StudioPlaytestStatus(ready: true, hasSave: true);
    await controls.save();
    await controls.resume();
    await controls.newGame();
    await controls.togglePause();
    controls.setTestSpeed(PlaytestSpeed.normal);
    controls.toggleDiagonal();
    controls.requestClose();
    expect(calls, [
      'save',
      'resume',
      'new',
      'pause',
      'speed:1',
      'diagonal',
      'close',
    ]);
  });

  test('old surface cannot detach replacement session controls', () async {
    final controls = StudioPlaytestControls();
    final previous = Object();
    final replacement = Object();
    var saves = 0;
    void attach(Object owner) => controls.attach(
      owner,
      status: () => const StudioPlaytestStatus(ready: true),
      save: () async {
        saves++;
      },
      resume: () async {},
      newGame: () async {},
      togglePause: () async {},
      setSpeed: (_) {},
      toggleDiagonal: () {},
      requestClose: () {},
    );
    attach(previous);
    expect(() => attach(replacement), throwsStateError);
    controls.detach(previous);
    attach(replacement);
    controls.detach(previous);
    await controls.save();
    expect(saves, 1);
    controls.detach(replacement);
    await controls.save();
    expect(saves, 1);
    expect(controls.status.ready, isFalse);
  });
}

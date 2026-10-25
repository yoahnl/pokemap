import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AveluneFrameRate.setLimit(AveluneFrameRate.defaultLimit));

  test('exposes the five supported limits and defaults to 60 FPS', () {
    expect(AveluneFrameRate.supportedLimits, [30, 45, 60, 90, 120]);
    expect(AveluneFrameRate.defaultLimit, 60);
    expect(AveluneFrameRate.limit, 60);
  });

  test('only notifies when the selected limit changes', () {
    var notifications = 0;
    void changed() => notifications++;
    AveluneFrameRate.changes.addListener(changed);
    addTearDown(() => AveluneFrameRate.changes.removeListener(changed));
    AveluneFrameRate.setLimit(45);
    AveluneFrameRate.setLimit(45);
    expect(AveluneFrameRate.limit, 45);
    expect(notifications, 1);
  });

  test('rejects unsupported limits without changing the selection', () {
    AveluneFrameRate.setLimit(45);
    for (final limit in [-1, 0, 29, 46, 240]) {
      expect(() => AveluneFrameRate.setLimit(limit), throwsArgumentError);
      expect(AveluneFrameRate.limit, 45);
    }
  });
}

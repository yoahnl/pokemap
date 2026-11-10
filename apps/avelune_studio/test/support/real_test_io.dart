import 'package:flutter_test/flutter_test.dart';

class RealTestIo {
  static Future<Object?>? pending;

  static Future<T?> run<T>(
    WidgetTester tester,
    Future<T> Function() action,
  ) async {
    while (pending != null) {
      await pending;
    }
    final operation = tester.runAsync(action);
    pending = operation;
    try {
      return await operation;
    } finally {
      if (identical(pending, operation)) pending = null;
    }
  }

  static Future<void> pump(WidgetTester tester, {int frames = 4}) async {
    for (var index = 0; index < frames; index++) {
      await pending;
      await run(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/embedding/avelune_frame_rate_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.runtime/frame_rate');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AveluneFrameRate.setLimit(60);
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    AveluneFrameRate.setLimit(60);
  });

  test(
    'Android receives the initial limit and every requested frame rate',
    () async {
      final bridge = AveluneFrameRateBridge()..attach();
      addTearDown(bridge.detach);
      await Future<void>.delayed(Duration.zero);
      for (final limit in [30, 45, 90, 120]) {
        AveluneFrameRate.setLimit(limit);
        await Future<void>.delayed(Duration.zero);
      }

      expect(calls.map((call) => call.method), everyElement('setLimit'));
      expect(calls.map((call) => (call.arguments as Map)['framesPerSecond']), [
        60,
        30,
        45,
        90,
        120,
      ]);
    },
  );

  test(
    'attaching once and detaching prevents duplicate and stale requests',
    () async {
      final bridge = AveluneFrameRateBridge();
      bridge.attach();
      bridge.attach();
      await Future<void>.delayed(Duration.zero);
      bridge.detach();
      bridge.detach();
      AveluneFrameRate.setLimit(90);
      await Future<void>.delayed(Duration.zero);

      expect(calls, hasLength(1));
    },
  );

  test(
    'non Android hosts do not require a native frame rate channel',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final bridge = AveluneFrameRateBridge()..attach();
      addTearDown(bridge.detach);
      AveluneFrameRate.setLimit(120);
      await Future<void>.delayed(Duration.zero);

      expect(calls, isEmpty);
    },
  );

  test(
    'a missing optional surface hint does not reject the rendering limit',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw MissingPluginException();
      });
      final bridge = AveluneFrameRateBridge()..attach();
      addTearDown(bridge.detach);
      AveluneFrameRate.setLimit(45);
      await Future<void>.delayed(Duration.zero);

      expect(AveluneFrameRate.limit, 45);
    },
  );
}

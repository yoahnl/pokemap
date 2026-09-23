import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the native iOS host retains the shared Flutter platform channel', () {
    final channel =
        File(
          '../Avelune iOS/AveluneiOS/Infrastructure/HubPlatformChannel.swift',
        ).readAsStringSync();
    final adapter =
        File('lib/platform/ios_hub_platform_adapter.dart').readAsStringSync();
    final composition =
        File(
          '../Avelune iOS/AveluneiOS/Infrastructure/AppComposition.swift',
        ).readAsStringSync();

    expect(channel, contains('com.yoahnl.avelune.player/ios'));
    expect(adapter, contains("MethodChannel('com.yoahnl.avelune.player/ios')"));
    expect(channel, contains('availableDiskBytes'));
    expect(composition, contains('FlutterEngineManager()'));
    expect(composition, contains('FlutterGameDataSource(engine: engine)'));
  });
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pokemap_hub/app/di/hub_composition.dart';
import 'package:pokemap_hub/core/ports/hub_platform_port.dart';
import 'package:pokemap_hub/platform/ios_hub_platform_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const iosChannel = MethodChannel('com.yoahnl.avelune.player/ios');

  test('iOS adapter delegates package picking and disk capacity to native code',
      () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(iosChannel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'pickPackage' => '/tmp/adventure.pokemapgame',
        'availableDiskBytes' => 987654321,
        _ => throw MissingPluginException(),
      };
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iosChannel, null),
    );
    final supportRoot =
        await Directory.systemTemp.createTemp('pokemap-ios-adapter-');
    addTearDown(() => supportRoot.delete(recursive: true));
    final adapter = IOSHubPlatformAdapter();

    expect(
      await adapter.pickPackage(),
      '/tmp/adventure.pokemapgame',
    );
    expect(await adapter.availableDiskBytes(supportRoot), 987654321);
    expect(calls, <String>['pickPackage', 'availableDiskBytes']);
  });

  test('iOS adapter rejects invalid native disk capacity', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      iosChannel,
      (call) async => call.method == 'availableDiskBytes' ? -1 : null,
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(iosChannel, null),
    );
    final supportRoot =
        await Directory.systemTemp.createTemp('pokemap-ios-capacity-');
    addTearDown(() => supportRoot.delete(recursive: true));

    await expectLater(
      IOSHubPlatformAdapter().availableDiskBytes(supportRoot),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('shared composition attaches and owns the selected platform adapter',
      () async {
    final supportRoot =
        await Directory.systemTemp.createTemp('pokemap-hub-composition-');
    addTearDown(() => supportRoot.delete(recursive: true));
    final adapter = _RecordingPlatformAdapter();

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final composition = await HubComposition.create(
      dashboardNotifier: container.read(hubDashboardNotifierProvider.notifier),
      platformAdapter: adapter,
      supportRoot: supportRoot,
    );

    expect(adapter.openHandler, isNotNull);
    expect(adapter.disposed, isFalse);
    expect(
      composition.appearanceController.state.status,
      AveluneAppearanceControllerStatus.ready,
    );

    composition.dispose();

    expect(adapter.disposed, isTrue);
  });

  test('Hub import action reaches the selected platform adapter', () async {
    final supportRoot =
        await Directory.systemTemp.createTemp('pokemap-hub-import-action-');
    addTearDown(() => supportRoot.delete(recursive: true));
    final adapter = _RecordingPlatformAdapter();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final composition = await HubComposition.create(
      dashboardNotifier: container.read(hubDashboardNotifierProvider.notifier),
      platformAdapter: adapter,
      supportRoot: supportRoot,
    );

    composition.actions.onImportRequested?.call();
    await Future<void>.delayed(Duration.zero);

    expect(adapter.pickCalls, 1);

    composition.dispose();
  });
}

final class _RecordingPlatformAdapter implements HubPlatformAdapter {
  HubPackageOpenHandler? openHandler;
  bool disposed = false;
  int pickCalls = 0;

  @override
  Future<void> attachPackageOpenHandler(HubPackageOpenHandler handler) async {
    openHandler = handler;
  }

  @override
  Future<int> availableDiskBytes(Directory supportRoot) async => 1 << 40;

  @override
  void dispose() {
    disposed = true;
  }

  @override
  Future<String?> pickPackage() async {
    pickCalls += 1;
    return null;
  }
}

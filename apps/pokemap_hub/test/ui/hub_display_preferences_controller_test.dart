import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-display-controller-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('applies persisted settings and restores them after restart', () async {
    final store = HubDisplayPreferencesStore(supportRoot: root);
    const initial = HubDisplayPreferences(
      mode: HubDisplayMode.fullscreen,
      windowSize: HubWindowSizePreset.compact,
    );
    await store.save(HubDesktopPlatform.macos, initial);
    final firstDriver = _MemoryDisplayDriver(HubDesktopPlatform.macos);
    final first = HubDisplayPreferencesController(
      store: store,
      driver: firstDriver,
    );
    addTearDown(first.dispose);

    await first.initialize();
    expect(first.snapshot.status, HubDisplayPreferencesStatus.ready);
    expect(firstDriver.applied, <HubDisplayPreferences>[initial]);

    const updated = HubDisplayPreferences(
      windowSize: HubWindowSizePreset.spacious,
    );
    await first.update(updated);
    expect(first.snapshot.preferences, updated);

    final restartedDriver = _MemoryDisplayDriver(HubDesktopPlatform.macos);
    final restarted = HubDisplayPreferencesController(
      store: HubDisplayPreferencesStore(supportRoot: root),
      driver: restartedDriver,
    );
    addTearDown(restarted.dispose);
    await restarted.initialize();

    expect(restarted.snapshot.preferences, updated);
    expect(restartedDriver.applied, <HubDisplayPreferences>[updated]);
  });

  test('reports unsupported platforms without touching the window API',
      () async {
    final driver = _MemoryDisplayDriver(null);
    final controller = HubDisplayPreferencesController(
      store: HubDisplayPreferencesStore(supportRoot: root),
      driver: driver,
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(
      controller.snapshot.status,
      HubDisplayPreferencesStatus.unsupported,
    );
    expect(driver.applied, isEmpty);
  });

  test('window driver exits fullscreen before applying a safe preset',
      () async {
    final api = _MemoryWindowApi(isFullScreen: true);
    final driver = WindowManagerHubDisplayDriver(
      windowApi: api,
      debugPlatform: HubDesktopPlatform.macos,
    );

    await driver.apply(
      const HubDisplayPreferences(
        windowSize: HubWindowSizePreset.spacious,
      ),
    );

    expect(
      api.calls,
      <String>[
        'ensure',
        'minimum:800x600',
        'isFullscreen',
        'fullscreen:false',
        'size:1440x900',
        'center',
      ],
    );
  });

  test('window driver enters fullscreen without forcing a window size',
      () async {
    final api = _MemoryWindowApi(isFullScreen: false);
    final driver = WindowManagerHubDisplayDriver(
      windowApi: api,
      debugPlatform: HubDesktopPlatform.macos,
    );

    await driver.apply(
      const HubDisplayPreferences(mode: HubDisplayMode.fullscreen),
    );

    expect(
      api.calls,
      <String>[
        'ensure',
        'minimum:800x600',
        'isFullscreen',
        'fullscreen:true',
      ],
    );
  });
}

final class _MemoryDisplayDriver implements HubDisplayDriver {
  _MemoryDisplayDriver(this.platform);

  @override
  final HubDesktopPlatform? platform;
  final applied = <HubDisplayPreferences>[];

  @override
  Future<void> apply(HubDisplayPreferences preferences) async {
    applied.add(preferences);
  }
}

final class _MemoryWindowApi implements HubWindowApi {
  _MemoryWindowApi({required bool isFullScreen}) : _isFullScreen = isFullScreen;

  bool _isFullScreen;
  final calls = <String>[];

  @override
  Future<void> center() async => calls.add('center');

  @override
  Future<void> ensureInitialized() async => calls.add('ensure');

  @override
  Future<bool> isFullScreen() async {
    calls.add('isFullscreen');
    return _isFullScreen;
  }

  @override
  Future<void> setFullScreen(bool value) async {
    calls.add('fullscreen:$value');
    _isFullScreen = value;
  }

  @override
  Future<void> setMinimumSize(Size size) async {
    calls.add('minimum:${size.width.round()}x${size.height.round()}');
  }

  @override
  Future<void> setSize(Size size) async {
    calls.add('size:${size.width.round()}x${size.height.round()}');
  }
}

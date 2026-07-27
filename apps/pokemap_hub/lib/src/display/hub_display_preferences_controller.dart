import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'hub_display_preferences.dart';
import 'hub_display_preferences_store.dart';

enum HubDisplayPreferencesStatus { idle, ready, unsupported, error }

@immutable
final class HubDisplayPreferencesSnapshot {
  const HubDisplayPreferencesSnapshot({
    required this.status,
    required this.preferences,
    this.platform,
    this.safeMessage,
  });

  final HubDisplayPreferencesStatus status;
  final HubDisplayPreferences preferences;
  final HubDesktopPlatform? platform;
  final String? safeMessage;

  bool get canUpdate =>
      status == HubDisplayPreferencesStatus.ready ||
      status == HubDisplayPreferencesStatus.error;
}

abstract interface class HubDisplayDriver {
  HubDesktopPlatform? get platform;

  Future<void> apply(HubDisplayPreferences preferences);
}

abstract interface class HubWindowApi {
  Future<void> ensureInitialized();

  Future<bool> isFullScreen();

  Future<void> setFullScreen(bool value);

  Future<void> setMinimumSize(Size size);

  Future<void> setSize(Size size);

  Future<void> center();
}

final class WindowManagerHubWindowApi implements HubWindowApi {
  const WindowManagerHubWindowApi();

  @override
  Future<void> ensureInitialized() => windowManager.ensureInitialized();

  @override
  Future<bool> isFullScreen() => windowManager.isFullScreen();

  @override
  Future<void> setFullScreen(bool value) => windowManager.setFullScreen(value);

  @override
  Future<void> setMinimumSize(Size size) => windowManager.setMinimumSize(size);

  @override
  Future<void> setSize(Size size) => windowManager.setSize(size, animate: true);

  @override
  Future<void> center() => windowManager.center();
}

/// Desktop window adapter. Unsupported platforms remain a no-op at product
/// level instead of attempting a mobile system-UI approximation.
final class WindowManagerHubDisplayDriver implements HubDisplayDriver {
  WindowManagerHubDisplayDriver({
    HubWindowApi windowApi = const WindowManagerHubWindowApi(),
    HubDesktopPlatform? debugPlatform,
  })  : _windowApi = windowApi,
        _platform = debugPlatform ?? _currentPlatform();

  final HubWindowApi _windowApi;
  final HubDesktopPlatform? _platform;

  @override
  HubDesktopPlatform? get platform => _platform;

  @override
  Future<void> apply(HubDisplayPreferences preferences) async {
    if (_platform == null) {
      throw UnsupportedError('Desktop display controls are unavailable.');
    }
    await _windowApi.ensureInitialized();
    await _windowApi.setMinimumSize(const Size(800, 600));
    if (preferences.mode == HubDisplayMode.fullscreen) {
      if (!await _windowApi.isFullScreen()) {
        await _windowApi.setFullScreen(true);
      }
      return;
    }
    if (await _windowApi.isFullScreen()) {
      await _windowApi.setFullScreen(false);
    }
    await _windowApi.setSize(preferences.windowSize.logicalSize);
    await _windowApi.center();
  }

  static HubDesktopPlatform? _currentPlatform() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => HubDesktopPlatform.macos,
      TargetPlatform.windows => HubDesktopPlatform.windows,
      TargetPlatform.linux => HubDesktopPlatform.linux,
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia =>
        null,
    };
  }
}

final class HubDisplayPreferencesController extends ChangeNotifier {
  HubDisplayPreferencesController({
    required HubDisplayPreferencesGateway store,
    required HubDisplayDriver driver,
  })  : _store = store,
        _driver = driver;

  final HubDisplayPreferencesGateway _store;
  final HubDisplayDriver _driver;
  Future<void> _tail = Future<void>.value();

  HubDisplayPreferencesSnapshot _snapshot = const HubDisplayPreferencesSnapshot(
    status: HubDisplayPreferencesStatus.idle,
    preferences: HubDisplayPreferences(),
  );

  HubDisplayPreferencesSnapshot get snapshot => _snapshot;

  Future<void> initialize() => _serialize(() async {
        final platform = _driver.platform;
        if (platform == null) {
          _publish(
            const HubDisplayPreferencesSnapshot(
              status: HubDisplayPreferencesStatus.unsupported,
              preferences: HubDisplayPreferences(),
              safeMessage: 'Display controls are unavailable on this platform.',
            ),
          );
          return;
        }
        try {
          final preferences = await _store.load(platform);
          await _driver.apply(preferences);
          _publish(
            HubDisplayPreferencesSnapshot(
              status: HubDisplayPreferencesStatus.ready,
              preferences: preferences,
              platform: platform,
            ),
          );
        } on Object {
          _publish(
            HubDisplayPreferencesSnapshot(
              status: HubDisplayPreferencesStatus.error,
              preferences: const HubDisplayPreferences(),
              platform: platform,
              safeMessage: 'Display preferences could not be applied.',
            ),
          );
        }
      });

  Future<void> update(HubDisplayPreferences preferences) =>
      _serialize(() async {
        final platform = _driver.platform;
        if (platform == null || !_snapshot.canUpdate) return;
        final previous = _snapshot.preferences;
        try {
          await _driver.apply(preferences);
          await _store.save(platform, preferences);
          _publish(
            HubDisplayPreferencesSnapshot(
              status: HubDisplayPreferencesStatus.ready,
              preferences: preferences,
              platform: platform,
            ),
          );
        } on Object {
          _publish(
            HubDisplayPreferencesSnapshot(
              status: HubDisplayPreferencesStatus.error,
              preferences: previous,
              platform: platform,
              safeMessage: 'Display preferences could not be saved.',
            ),
          );
        }
      });

  Future<void> settle() => _tail;

  Future<void> _serialize(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.catchError((_) {});
    return next;
  }

  void _publish(HubDisplayPreferencesSnapshot snapshot) {
    _snapshot = snapshot;
    notifyListeners();
  }
}

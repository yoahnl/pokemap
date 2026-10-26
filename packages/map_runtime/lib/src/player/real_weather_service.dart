import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'real_weather_provider.dart';
import 'real_weather_cache.dart';
export 'real_weather_cache.dart';

final class RealWeatherStatus {
  const RealWeatherStatus({
    this.snapshot,
    this.loading = false,
    this.offline = false,
  });
  final RealWeatherSnapshot? snapshot;
  final bool loading, offline;
}

final class RealWeatherService extends ValueNotifier<RealWeatherStatus> {
  RealWeatherService({
    required this.provider,
    required this.cache,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       super(const RealWeatherStatus());
  static final shared = RealWeatherService(
    provider: OpenMeteoRealWeatherProvider(),
    cache: FileRealWeatherCache(),
  );
  final RealWeatherProvider provider;
  final RealWeatherCache cache;
  final DateTime Function() now;
  RealWeatherPreferences? _preferences;
  Future<void>? _pending;
  DateTime? _lastAttempt;
  int _generation = 0;
  bool _closed = false;
  Future<void> refresh(
    RealWeatherPreferences preferences, {
    bool force = false,
  }) {
    if (_closed) return Future.value();
    if (!preferences.enabled) {
      _generation++;
      _preferences = preferences;
      _pending = null;
      _lastAttempt = null;
      value = const RealWeatherStatus();
      return Future.value();
    }
    final same = preferences == _preferences;
    if (same && _pending != null) return _pending!;
    if (same &&
        !force &&
        _lastAttempt != null &&
        now().difference(_lastAttempt!) >= Duration.zero &&
        now().difference(_lastAttempt!) < const Duration(minutes: 20)) {
      return Future.value();
    }
    _preferences = preferences;
    _lastAttempt = now();
    final generation = ++_generation;
    return _pending = Future<void>.microtask(() => _refresh(preferences, generation, force));
  }

  bool _current(int generation) => !_closed && generation == _generation;
  Future<void> _refresh(
    RealWeatherPreferences prefs,
    int generation,
    bool force,
  ) async {
    if (!_current(generation)) return;
    RealWeatherSnapshot? cached = value.snapshot;
    try {
      cached ??= await cache.read();
    } on Object {
      cached = null;
    }
    if (!_current(generation)) return;
    if (cached != null &&
        (!cached.usableAt(now()) ||
            (prefs.location == null
                ? !cached.fromIp
                : cached.fromIp || prefs.location != cached.location))) {
      cached = null;
    }
    value = RealWeatherStatus(snapshot: cached, loading: true);
    try {
      if (!force &&
          cached != null &&
          now().difference(cached.fetchedAt) < const Duration(minutes: 20)) {
        value = RealWeatherStatus(snapshot: cached);
        return;
      }
      final location = prefs.location ?? await provider.locate();
      if (!_current(generation)) return;
      final fetched = await provider.fetch(location, now());
      final snapshot = RealWeatherSnapshot(
        location: fetched.location,
        conditions: fetched.conditions,
        fetchedAt: fetched.fetchedAt,
        fromIp: prefs.location == null,
      );
      if (!_current(generation)) return;
      value = RealWeatherStatus(snapshot: snapshot);
      try {
        await cache.write(snapshot);
      } on Object {
        if (_current(generation)) {
          value = RealWeatherStatus(snapshot: snapshot, offline: true);
        }
      }
    } on Object {
      if (_current(generation)) {
        value = RealWeatherStatus(snapshot: cached, offline: true);
      }
    } finally {
      if (_current(generation)) _pending = null;
    }
  }

  @override
  void dispose() {
    _closed = true;
    _generation++;
    super.dispose();
  }
}

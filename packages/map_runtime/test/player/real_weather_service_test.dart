import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/real_weather_service.dart';
import 'package:map_runtime/src/player/real_weather_provider.dart';

void main() {
  test('bounded private file cache survives a fresh reader and rejects corrupt data', () async {
    final directory = await Directory.systemTemp.createTemp('avelune-weather-cache-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/weather.json');
    final snapshot = RealWeatherSnapshot(location: RealWeatherLocation(latitude: 48, longitude: 2, label: 'City'), conditions: SpatialVisualPatch.fromJson({'weatherKind': 'rain'}), fetchedAt: DateTime.utc(2026));
    await FileRealWeatherCache(file: () async => file).write(snapshot);
    final reopened = await FileRealWeatherCache(file: () async => file).read();
    expect(reopened!.toJson(), snapshot.toJson());
    expect(await file.length(), lessThan(1024));
    expect(await directory.list().length, 1);
    await file.writeAsString('x' * 32769);
    await expectLater(FileRealWeatherCache(file: () async => file).read(), throwsFormatException);
  });

  test(
    'provider uses caller IP and bounded weather units; never stores the IP',
    () async {
      final uris = <Uri>[];
      final provider = OpenMeteoRealWeatherProvider(
        clientFactory: () => MockClient((request) async {
          uris.add(request.url);
          if (request.url.host == 'get.geojs.io')
            return http.Response(
              jsonEncode({
                'ip': 'private',
                'latitude': '48.86',
                'longitude': '2.35',
                'city': 'Paris',
                'country_code': 'FR',
              }),
              200,
            );
          return http.Response(
            jsonEncode({
              'current': {
                'weather_code': 63,
                'cloud_cover': 90,
                'wind_speed_10m': 20,
                'wind_direction_10m': 90,
                'precipitation': 2,
              },
            }),
            200,
          );
        }),
      );
      final location = await provider.locate();
      final weather = await provider.fetch(location, DateTime.utc(2026));
      expect(uris.first.toString(), 'https://get.geojs.io/v1/ip/geo.json');
      expect(uris.last.queryParameters['wind_speed_unit'], 'kmh');
      expect(
        weather.conditions.choice(SpatialVisualParameter.weatherKind),
        'rain',
      );
      expect(
        weather.conditions.number(SpatialVisualParameter.weatherCloudCover),
        .9,
      );
      expect(jsonEncode(weather.toJson()), isNot(contains('private')));
    },
  );
  test('invalid and oversized provider replies are rejected', () async {
    final location = RealWeatherLocation(
      latitude: 48,
      longitude: 2,
      label: 'City',
    );
    for (final body in [
      'x' * 65537,
      '{}',
      '{"current":{"weather_code":999}}',
    ]) {
      final provider = OpenMeteoRealWeatherProvider(
        clientFactory: () => MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        provider.fetch(location, DateTime.utc(2026)),
        throwsFormatException,
      );
    }
  });
  test(
    'manual city and return to IP never reuse the other source cache',
    () async {
      final provider = _Provider();
      final service = RealWeatherService(provider: provider, cache: _Cache());
      const automatic = RealWeatherPreferences(enabled: true);
      await service.refresh(automatic);
      expect(provider.locations, 1);
      await service.refresh(
        RealWeatherPreferences(
          enabled: true,
          location: RealWeatherLocation(
            latitude: 49,
            longitude: 3,
            label: 'Manual',
          ),
        ),
      );
      expect(service.value.snapshot!.fromIp, isFalse);
      await service.refresh(automatic);
      expect(provider.locations, 2);
      expect(provider.forecasts, 3);
      expect(service.value.snapshot!.fromIp, isTrue);
      service.dispose();
    },
  );
  test('a disabled preference ignores a previously pending response', () async {
    final provider = _DelayedProvider();
    final cache = _Cache();
    final service = RealWeatherService(provider: provider, cache: cache);
    final pending = service.refresh(
      const RealWeatherPreferences(enabled: true),
    );
    await Future<void>.delayed(Duration.zero);
    await service.refresh(const RealWeatherPreferences());
    provider.gate.complete(
      RealWeatherSnapshot(
        location: RealWeatherLocation(
          latitude: 48,
          longitude: 2,
          label: 'Old city',
        ),
        conditions: SpatialVisualPatch.fromJson({'weatherKind': 'snow'}),
        fetchedAt: DateTime.now(),
      ),
    );
    await pending;
    expect(service.value.snapshot, isNull);
    expect(cache.value, isNull);
    service.dispose();
  });
  test('service has single flight, cache reuse, stale offline fallback and late response isolation', () async {
    var now = DateTime.utc(2026);
    final provider = _Provider();
    final cache = _Cache();
    final service = RealWeatherService(
      provider: provider,
      cache: cache,
      now: () => now,
    );
    const enabled = RealWeatherPreferences(enabled: true);
    final first = service.refresh(enabled);
    final same = service.refresh(enabled);
    await Future.wait([first, same]);
    expect(provider.locations, 1);
    expect(provider.forecasts, 1);
    await service.refresh(enabled);
    expect(provider.forecasts, 1);
    now = now.add(const Duration(minutes: 21));
    provider.fail = true;
    await service.refresh(enabled);
    expect(service.value.snapshot, isNotNull);
    expect(service.value.offline, isTrue);
    final reopened = RealWeatherService(
      provider: provider,
      cache: cache,
      now: () => now,
    );
    await reopened.refresh(enabled);
    expect(reopened.value.snapshot, isNotNull);
    now = now.add(const Duration(days: 2));
    await reopened.refresh(enabled, force: true);
    expect(reopened.value.snapshot, isNull);
    final before = provider.forecasts;
    await service.refresh(const RealWeatherPreferences());
    expect(provider.forecasts, before);
    expect(service.value.snapshot, isNull);
    service.dispose();
    reopened.dispose();
  });
}

class _Provider implements RealWeatherProvider {
  int locations = 0, forecasts = 0;
  bool fail = false;
  @override
  Future<RealWeatherLocation> locate() async {
    locations++;
    return RealWeatherLocation(latitude: 48, longitude: 2, label: 'Paris');
  }

  @override
  Future<List<RealWeatherLocation>> search(String query) async => [];
  @override
  Future<RealWeatherSnapshot> fetch(
    RealWeatherLocation location,
    DateTime now,
  ) async {
    forecasts++;
    if (fail) throw StateError('Offline');
    return RealWeatherSnapshot(
      location: location,
      conditions: SpatialVisualPatch.fromJson({'weatherKind': 'rain'}),
      fetchedAt: now,
    );
  }
}

class _Cache implements RealWeatherCache {
  RealWeatherSnapshot? value;
  @override
  Future<RealWeatherSnapshot?> read() async => value;
  @override
  Future<void> write(RealWeatherSnapshot snapshot) async {
    value = snapshot;
  }
}

class _DelayedProvider extends _Provider {
  final gate = Completer<RealWeatherSnapshot>();
  @override
  Future<RealWeatherSnapshot> fetch(
    RealWeatherLocation location,
    DateTime now,
  ) => gate.future;
}

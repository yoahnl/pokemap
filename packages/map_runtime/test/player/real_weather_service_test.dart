import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/real_weather_service.dart';
import 'package:map_runtime/src/player/real_weather_provider.dart';

void main() {
  test('provider uses caller IP and bounded weather units; never stores the IP', () async {
    final uris = <Uri>[];
    final provider = OpenMeteoRealWeatherProvider(clientFactory: () => MockClient((request) async {
      uris.add(request.url);
      if (request.url.host == 'get.geojs.io') return http.Response(jsonEncode({'ip': 'private', 'latitude': '48.86', 'longitude': '2.35', 'city': 'Paris', 'country_code': 'FR'}), 200);
      return http.Response(jsonEncode({'current': {'weather_code': 63, 'cloud_cover': 90, 'wind_speed_10m': 20, 'wind_direction_10m': 90, 'precipitation': 2}}), 200);
    }));
    final location = await provider.locate();
    final weather = await provider.fetch(location, DateTime.utc(2026));
    expect(uris.first.toString(), 'https://get.geojs.io/v1/ip/geo.json');
    expect(uris.last.queryParameters['wind_speed_unit'], 'kmh');
    expect(weather.conditions.choice(SpatialVisualParameter.weatherKind), 'rain');
    expect(weather.conditions.number(SpatialVisualParameter.weatherCloudCover), .9);
    expect(jsonEncode(weather.toJson()), isNot(contains('private')));
  });
  test('service has single flight, cache reuse, stale offline fallback and late response isolation', () async {
    var now = DateTime.utc(2026);
    final provider = _Provider();
    final cache = _Cache();
    final service = RealWeatherService(provider: provider, cache: cache, now: () => now);
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
    final reopened = RealWeatherService(provider: provider, cache: cache, now: () => now);
    await reopened.refresh(enabled);
    expect(reopened.value.snapshot, isNotNull);
    now = now.add(const Duration(days: 2));
    await reopened.refresh(enabled, force: true);
    expect(reopened.value.snapshot, isNull);
    final before = provider.forecasts;
    await service.refresh(const RealWeatherPreferences());
    expect(provider.forecasts, before);
    expect(service.value.snapshot, isNull);
    service.dispose(); reopened.dispose();
  });
}
class _Provider implements RealWeatherProvider {
  int locations = 0, forecasts = 0;
  bool fail = false;
  @override
  Future<RealWeatherLocation> locate() async { locations++; return RealWeatherLocation(latitude: 48, longitude: 2, label: 'Paris'); }
  @override
  Future<List<RealWeatherLocation>> search(String query) async => [];
  @override
  Future<RealWeatherSnapshot> fetch(RealWeatherLocation location, DateTime now) async {
    forecasts++;
    if (fail) throw StateError('Offline');
    return RealWeatherSnapshot(location: location, conditions: SpatialVisualPatch.fromJson({'weatherKind': 'rain'}), fetchedAt: now);
  }
}
class _Cache implements RealWeatherCache {
  RealWeatherSnapshot? value;
  @override
  Future<RealWeatherSnapshot?> read() async => value;
  @override
  Future<void> write(RealWeatherSnapshot snapshot) async { value = snapshot; }
}

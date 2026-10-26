import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

abstract interface class RealWeatherProvider {
  Future<RealWeatherLocation> locate();
  Future<List<RealWeatherLocation>> search(String query);
  Future<RealWeatherSnapshot> fetch(RealWeatherLocation location, DateTime now);
}

final class OpenMeteoRealWeatherProvider implements RealWeatherProvider {
  OpenMeteoRealWeatherProvider({http.Client Function()? clientFactory, this.timeout = const Duration(seconds: 8)}) : _clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() _clientFactory;
  final Duration timeout;
  Future<Map<String, dynamic>> _get(Uri uri) async {
    final client = _clientFactory();
    try {
      return await (() async {
        final response = await client.send(http.Request('GET', uri)..followRedirects = false);
        if (response.statusCode != 200) throw const FormatException('Weather service unavailable.');
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 65536) throw const FormatException('Weather response too large.');
          bytes.addAll(chunk);
        }
        final json = jsonDecode(utf8.decode(bytes));
        if (json is! Map<String, dynamic>) throw const FormatException('Invalid weather response.');
        return json;
      })().timeout(timeout);
    } finally { client.close(); }
  }
  @override
  Future<RealWeatherLocation> locate() async {
    final json = await _get(Uri.https('get.geojs.io', '/v1/ip/geo.json'));
    final lat = double.tryParse('${json['latitude']}');
    final lon = double.tryParse('${json['longitude']}');
    if (lat == null || lon == null) throw const FormatException('Location unavailable.');
    final label = json['city'] ?? json['region'] ?? json['country'];
    if (label is! String) throw const FormatException('Location unavailable.');
    return RealWeatherLocation(latitude: double.parse(lat.toStringAsFixed(2)), longitude: double.parse(lon.toStringAsFixed(2)), label: label, countryCode: json['country_code'] as String? ?? '');
  }
  @override
  Future<List<RealWeatherLocation>> search(String query) async {
    final term = query.trim();
    if (term.length < 2 || term.length > 120) return const [];
    final json = await _get(Uri.https('geocoding-api.open-meteo.com', '/v1/search', {'name': term, 'count': '5', 'language': 'fr', 'format': 'json'}));
    final results = json['results'];
    if (results == null) return const [];
    if (results is! List || results.length > 5) throw const FormatException('Invalid location search.');
    return [for (final row in results) RealWeatherLocation(latitude: (row as Map)['latitude'] as num, longitude: row['longitude'] as num, label: [row['name'], row['admin1'], row['country']].whereType<String>().join(', '), countryCode: row['country_code'] as String? ?? '')];
  }
  @override
  Future<RealWeatherSnapshot> fetch(RealWeatherLocation location, DateTime now) async {
    final json = await _get(Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${location.latitude}', 'longitude': '${location.longitude}',
      'current': 'weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,precipitation',
      'wind_speed_unit': 'kmh', 'timezone': 'UTC', 'forecast_days': '1',
    }));
    final current = json['current'];
    if (current is! Map) throw const FormatException('Current weather unavailable.');
    double number(String key, double min, double max) {
      final value = current[key];
      if (value is! num || !value.isFinite || value < min || value > max) throw const FormatException('Invalid weather observation.');
      return value.toDouble();
    }
    final code = current['weather_code'];
    if (code is! int) throw const FormatException('Invalid weather code.');
    final kind = switch (code) {
      0 => SpatialWeatherKind.clear,
      1 || 2 || 3 => SpatialWeatherKind.cloudy,
      45 || 48 => SpatialWeatherKind.fog,
      51 || 53 || 55 || 56 || 57 => SpatialWeatherKind.drizzle,
      61 || 63 || 66 || 67 || 80 || 81 => SpatialWeatherKind.rain,
      65 || 82 => SpatialWeatherKind.downpour,
      71 || 73 || 75 || 77 || 85 || 86 => SpatialWeatherKind.snow,
      95 || 97 => SpatialWeatherKind.storm,
      96 || 99 => SpatialWeatherKind.hail,
      _ => throw const FormatException('Unsupported weather code.'),
    };
    final cloud = number('cloud_cover', 0, 100) / 100;
    final wind = number('wind_speed_10m', 0, 500);
    final direction = number('wind_direction_10m', 0, 360);
    final rain = number('precipitation', 0, 1000);
    return RealWeatherSnapshot(location: location, fetchedAt: now, conditions: SpatialVisualPatch.fromJson({
      'weatherKind': kind.name,
      'weatherIntensity': kind == SpatialWeatherKind.clear || kind == SpatialWeatherKind.cloudy || kind == SpatialWeatherKind.fog ? 1 : (.3 + rain / 8).clamp(.3, 1),
      'weatherCloudCover': cloud, 'weatherWindStrength': (wind / 40).clamp(0, 2),
      'weatherWindDirection': ((-direction + 180) % 360) - 180,
      if (kind == SpatialWeatherKind.fog) 'weatherFogStrength': 1,
    }));
  }
}

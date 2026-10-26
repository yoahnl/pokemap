import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

abstract interface class RealWeatherProvider {
  Future<RealWeatherLocation> locate();
  Future<List<RealWeatherLocation>> search(String query);
  Future<RealWeatherSnapshot> fetch(RealWeatherLocation location, DateTime now);
}

final class OpenMeteoRealWeatherProvider implements RealWeatherProvider {
  OpenMeteoRealWeatherProvider({
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 8),
  }) : _clientFactory = clientFactory ?? http.Client.new;
  final http.Client Function() _clientFactory;
  final Duration timeout;
  Future<Map<String, dynamic>> _get(Uri uri) async {
    final client = _clientFactory();
    try {
      return await (() async {
        final response = await client.send(
          http.Request('GET', uri)..followRedirects = false,
        );
        if (response.statusCode != 200) {
          throw const FormatException('Weather service unavailable.');
        }
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 65536) {
            throw const FormatException('Weather response too large.');
          }
          bytes.addAll(chunk);
        }
        final json = jsonDecode(utf8.decode(bytes));
        if (json is! Map<String, dynamic>) {
          throw const FormatException('Invalid weather response.');
        }
        return json;
      })().timeout(timeout);
    } finally {
      client.close();
    }
  }

  @override
  Future<RealWeatherLocation> locate() async {
    final json = await _get(Uri.https('get.geojs.io', '/v1/ip/geo.json'));
    final lat = double.tryParse('${json['latitude']}');
    final lon = double.tryParse('${json['longitude']}');
    if (lat == null || lon == null) {
      throw const FormatException('Location unavailable.');
    }
    final label = json['city'] ?? json['region'] ?? json['country'];
    if (label is! String) throw const FormatException('Location unavailable.');
    return RealWeatherLocation(
      latitude: double.parse(lat.toStringAsFixed(2)),
      longitude: double.parse(lon.toStringAsFixed(2)),
      label: label,
      countryCode: json['country_code'] as String? ?? '',
    );
  }

  @override
  Future<List<RealWeatherLocation>> search(String query) async {
    final term = query.trim();
    if (term.length < 2 || term.length > 120) return const [];
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': term,
        'count': '5',
        'language': 'fr',
        'format': 'json',
      }),
    );
    final results = json['results'];
    if (results == null) return const [];
    if (results is! List || results.length > 5) {
      throw const FormatException('Invalid location search.');
    }
    return [
      for (final row in results)
        RealWeatherLocation(
          latitude: (row as Map)['latitude'] as num,
          longitude: row['longitude'] as num,
          label: [
            row['name'],
            row['admin1'],
            row['country'],
          ].whereType<String>().join(', '),
          countryCode: row['country_code'] as String? ?? '',
        ),
    ];
  }

  @override
  Future<RealWeatherSnapshot> fetch(
    RealWeatherLocation location,
    DateTime now,
  ) async {
    final json = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${location.latitude}',
        'longitude': '${location.longitude}',
        'current': 'weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,precipitation,rain,showers,snowfall',
        'wind_speed_unit': 'kmh',
        'timezone': 'auto',
        'forecast_days': '1',
      }),
    );
    final current = json['current'];
    final offset = json['utc_offset_seconds'];
    final zone = json['timezone'];
    if (current is! Map || offset is! int || zone is! String) {
      throw const FormatException('Current weather unavailable.');
    }
    double number(String key, double min, double max) {
      final value = current[key];
      if (value is! num || !value.isFinite || value < min || value > max) {
        throw const FormatException('Invalid weather observation.');
      }
      return value.toDouble();
    }

    final code = current['weather_code'];
    if (code is! int) throw const FormatException('Invalid weather code.');
    var kind = switch (code) {
      0 => SpatialWeatherKind.clear,
      1 || 2 => SpatialWeatherKind.partlyCloudy,
      3 => SpatialWeatherKind.cloudy,
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
    final interval = current['interval'] ?? 900;
    if (interval is! num || !interval.isFinite || interval <= 0 || interval > 3600) {
      throw const FormatException('Invalid weather observation interval.');
    }
    final snowfall = current['snowfall'] == null ? 0.0 : number('snowfall', 0, 100);
    final rainfall = (current['rain'] == null ? 0.0 : number('rain', 0, 1000)) +
        (current['showers'] == null ? 0.0 : number('showers', 0, 1000));
    final rainRate = rain * 3600 / interval;
    final snowRate = snowfall * 3600 / interval;
    if (code < 95 && snowfall > 0) {
      kind = rainfall > 0 ? SpatialWeatherKind.sleet : SpatialWeatherKind.snow;
    } else if (code < 50 && rainfall > 0) {
      kind = rainRate >= 7.5 ? SpatialWeatherKind.downpour : rainRate < .5 ? SpatialWeatherKind.drizzle : SpatialWeatherKind.rain;
    }
    if (kind == SpatialWeatherKind.snow && wind >= 35 && (code == 75 || code == 86 || snowRate >= 1)) {
      kind = SpatialWeatherKind.blizzard;
    }
    if (kind == SpatialWeatherKind.snow && (code == 75 || code == 86 || snowRate >= 1)) kind = SpatialWeatherKind.heavySnow;
    if (kind == SpatialWeatherKind.storm && (wind >= 45 || rainRate >= 15)) kind = SpatialWeatherKind.tempest;
    if ((kind == SpatialWeatherKind.clear || kind == SpatialWeatherKind.cloudy || kind == SpatialWeatherKind.partlyCloudy) && wind >= 25) kind = SpatialWeatherKind.windy;
    final minimum = switch (code) {
      65 || 75 || 82 || 99 => .95,
      55 || 57 || 63 || 73 || 81 || 86 || 95 || 96 || 97 => .7,
      _ => .4,
    };
    final intensity = switch (kind) {
      SpatialWeatherKind.clear || SpatialWeatherKind.cloudy || SpatialWeatherKind.fog => 1.0,
      SpatialWeatherKind.snow => (minimum + snowRate / 2).clamp(.4, 1.0),
      SpatialWeatherKind.blizzard => 1.0,
      _ => (minimum + rainRate / 16).clamp(.3, 1.0),
    };
    return RealWeatherSnapshot(
      location: location,
      fetchedAt: now,
      utcOffsetSeconds: offset,
      timeZone: zone,
      conditions: SpatialVisualPatch.fromJson({
        'weatherKind': kind.name,
        'weatherIntensity': intensity,
        'weatherCloudCover': cloud,
        'weatherWindStrength': (wind / 40).clamp(0, 2),
        'weatherWindDirection': ((-direction + 180) % 360) - 180,
        if (kind == SpatialWeatherKind.fog) 'weatherFogStrength': 1,
      }),
    );
  }
}

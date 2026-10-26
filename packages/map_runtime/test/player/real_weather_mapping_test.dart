import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/player/real_weather_provider.dart';

void main() {
  Future<RealWeatherSnapshot> observation(
    int code, {
    double snowfall = 0,
    double wind = 10,
    double rain = 0,
  }) {
    return OpenMeteoRealWeatherProvider(
      clientFactory: () => MockClient((request) async {
        expect(request.url.queryParameters['current'], contains('snowfall'));
        return http.Response(
          jsonEncode({
            'utc_offset_seconds': 0,
            'timezone': 'UTC',
            'current': {
              'weather_code': code,
              'cloud_cover': 95,
              'wind_speed_10m': wind,
              'wind_direction_10m': 0,
              'precipitation': rain,
              'snowfall': snowfall,
              'rain': rain,
              'showers': 0,
              'interval': 900,
            },
          }),
          200,
        );
      }),
    ).fetch(
      RealWeatherLocation(latitude: 60, longitude: 0, label: 'Weather test'),
      DateTime.utc(2026),
    );
  }

  test(
    'every provider weather code reaches its expected weather family',
    () async {
      final families = <String, List<int>>{
        'clear': [0],
        'partlyCloudy': [1, 2],
        'cloudy': [3],
        'fog': [45, 48],
        'drizzle': [51, 53, 55, 56, 57],
        'rain': [61, 63, 66, 67, 80, 81],
        'downpour': [65, 82],
        'snow': [71, 73, 77, 85],
        'heavySnow': [75, 86],
        'storm': [95],
        'hail': [96, 99],
      };
      for (final family in families.entries) {
        for (final code in family.value) {
          final result = await observation(code);
          expect(
            result.conditions.choice(SpatialVisualParameter.weatherKind),
            family.key,
            reason: 'weather code $code',
          );
          if (family.key == 'snow') {
            expect(
              result.conditions.number(SpatialVisualParameter.weatherIntensity),
              greaterThanOrEqualTo(.4),
            );
          }
        }
      }
    },
  );
  test('mixed precipitation, severe storms and dry wind remain distinct', () async {
    for (final item in [(await observation(73, snowfall: .2, rain: .2), 'sleet'), (await observation(95, wind: 60, rain: 5), 'tempest'), (await observation(3, wind: 40), 'windy')]) {
      expect(item.$1.conditions.choice(SpatialVisualParameter.weatherKind), item.$2);
    }
  });
  test(
    'snowfall and heavy wind remain visible even with a contradictory sky code',
    () async {
      final snow = await observation(3, snowfall: .3);
      expect(
        snow.conditions.choice(SpatialVisualParameter.weatherKind),
        'heavySnow',
      );
      final blizzard = await observation(75, snowfall: .4, wind: 45);
      expect(
        blizzard.conditions.choice(SpatialVisualParameter.weatherKind),
        'blizzard',
      );
      expect(
        blizzard.conditions.number(SpatialVisualParameter.weatherIntensity),
        greaterThanOrEqualTo(.9),
      );
      final cloudy = await observation(3);
      expect(
        cloudy.conditions.choice(SpatialVisualParameter.weatherKind),
        'cloudy',
      );
    },
  );
}

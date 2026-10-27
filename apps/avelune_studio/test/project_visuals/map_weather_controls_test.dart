import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_weather_controls.dart';

void main() {
  testWidgets(
    'map weather force, clear and inherit preserve unrelated settings',
    (tester) async {
      var patch = SpatialVisualPatch.fromJson({'haloStrength': 1.2});
      final inherited = SpatialVisualPatch.fromJson({
        'weatherMode': 'real',
        'weatherKind': 'rain',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => MapWeatherControls(
                  patch: patch,
                  inherited: inherited,
                  onChanged: (next) => setState(() => patch = next),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> choose(String key, String label) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await choose('map-weather-source', 'Forcer une météo');
      expect(patch.choice(SpatialVisualParameter.weatherMode), 'fixed');
      expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
      await choose('map-weather-kind', 'Orage');
      expect(patch.choice(SpatialVisualParameter.weatherKind), 'storm');
      expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
      await choose('map-weather-source', 'Forcer un ciel dégagé');
      expect(patch.choice(SpatialVisualParameter.weatherKind), 'clear');
      expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isFalse);
      await choose('map-weather-source', 'Suivre la météo du projet');
      expect(patch.toJson(), {'haloStrength': 1.2});
      expect(
        inherited
            .overriddenBy(patch)
            .choice(SpatialVisualParameter.weatherMode),
        'real',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

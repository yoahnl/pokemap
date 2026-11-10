import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('map weather force, clear and inherit preserve unrelated settings', () {
    var patch = SpatialVisualPatch.fromJson({'haloStrength': 1.2});
    final inherited = SpatialVisualPatch.fromJson({
      'weatherMode': 'real',
      'weatherKind': 'rain',
    });
    SpatialVisualEditing editing() => SpatialVisualEditing(
      patch: patch,
      inherited: inherited,
      onChanged: (next) => patch = next,
    );
    expect(editing().mapWeatherSource, 'inherit');
    editing().setMapWeatherSource('fixed');
    expect(editing().mapWeatherSource, 'fixed');
    expect(patch.choice(SpatialVisualParameter.weatherMode), 'fixed');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isTrue);
    editing().selectWeather(SpatialWeatherKind.storm);
    expect(patch.choice(SpatialVisualParameter.weatherKind), 'storm');
    expect(patch.number(SpatialVisualParameter.haloStrength), 1.2);
    editing().setMapWeatherSource('clear');
    expect(editing().mapWeatherSource, 'clear');
    expect(patch.choice(SpatialVisualParameter.weatherKind), 'clear');
    expect(patch.enabled(SpatialVisualParameter.weatherEnabled), isFalse);
    editing().setMapWeatherSource('inherit');
    expect(editing().mapWeatherSource, 'inherit');
    expect(patch.toJson(), {'haloStrength': 1.2});
    expect(
      inherited.overriddenBy(patch).choice(SpatialVisualParameter.weatherMode),
      'real',
    );
  });
}

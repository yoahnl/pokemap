import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final project = SpatialVisualPatch.fromJson({
    'halosEnabled': true,
    'haloStrength': 1.06,
    'haloSpread': 1.2825,
    'fireflies': true,
    'fireflyDensity': 1.28,
    'weatherMode': 'real',
  });

  test('an effect copies the project values when the map takes it over', () {
    var patch = SpatialVisualPatch.fromJson({'timeMode': 'fixed'});
    SpatialVisualEditing editing() => SpatialVisualEditing(
      patch: patch,
      inherited: project,
      onChanged: (next) => patch = next,
    );
    expect(editing().overridesEffect(MapEffect.halos), isFalse);

    editing().setEffectOverride(MapEffect.halos, override: true);

    expect(editing().overridesEffect(MapEffect.halos), isTrue);
    expect(patch.toJson(), {
      'timeMode': 'fixed',
      'halosEnabled': true,
      'haloStrength': 1.06,
      'haloSpread': 1.2825,
    });

    editing().change(SpatialVisualParameter.halosEnabled, false);
    expect(
      editing().effective.enabled(SpatialVisualParameter.halosEnabled),
      isFalse,
    );
    expect(editing().overridesEffect(MapEffect.fireflies), isFalse);

    editing().setEffectOverride(MapEffect.halos, override: false);

    expect(patch.toJson(), {'timeMode': 'fixed'});
  });

  test('an effect the project leaves unset starts off with its defaults', () {
    var patch = SpatialVisualPatch();
    SpatialVisualEditing editing() => SpatialVisualEditing(
      patch: patch,
      inherited: project,
      onChanged: (next) => patch = next,
    );

    editing().setEffectOverride(MapEffect.water, override: true);

    expect(patch.enabled(SpatialVisualParameter.waterAnimated), isFalse);
    expect(
      patch.number(SpatialVisualParameter.waterStrength),
      editing().number(SpatialVisualParameter.waterStrength),
    );
    expect(patch.number(SpatialVisualParameter.waterSpeed), isNotNull);
  });

  test('a partial map override still counts as the map setting', () {
    final editing = SpatialVisualEditing(
      patch: SpatialVisualPatch.fromJson({'fogOpacity': .2}),
      inherited: project,
      onChanged: (_) {},
    );

    expect(editing.overridesEffect(MapEffect.fog), isTrue);
    expect(editing.overridesEffect(MapEffect.windows), isFalse);
  });
}

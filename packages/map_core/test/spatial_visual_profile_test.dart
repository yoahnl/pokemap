import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('empty patches preserve baseline camera and local bindings', () {
    final camera = SpatialCameraProfile();
    final atmosphere = SpatialAtmosphereSettings(waterAnimated: true);
    final patch = SpatialVisualPatch();
    expect(patch.applyCamera(camera), same(camera));
    expect(patch.applyAtmosphere(atmosphere), same(atmosphere));
  });

  test('project defaults and local overrides retain local sources', () {
    final base = SpatialAtmosphereSettings(
      halos: [
        SpatialAtmosphereHalo(
          instanceId: 'lamp',
          localPosition: Model3dVector3(x: 0, y: 2, z: 0),
        ),
      ],
      waterTargets: [SpatialAtmosphereMaterialTarget(materialName: 'water')],
    );
    final project = SpatialVisualPatch.fromJson({
      'pitchDegrees': 34,
      'fieldOfViewDegrees': 16.4,
      'halosEnabled': true,
      'haloStrength': 1.1,
      'depthOfFieldEnabled': true,
    });
    final effective = project.overriddenBy(
      SpatialVisualPatch.fromJson({'haloStrength': .6}),
    );
    final camera = effective.applyCamera(SpatialCameraProfile());
    final atmosphere = effective.applyAtmosphere(base);
    expect(camera.pitchDegrees, 34);
    expect(camera.fieldOfViewDegrees, 16.4);
    expect(atmosphere.haloStrength, .6);
    expect(atmosphere.halos.single.instanceId, 'lamp');
    expect(atmosphere.waterTargets.single.materialName, 'water');
    expect(atmosphere.depthOfFieldEnabled, isTrue);
    expect(SpatialVisualPatch.fromJson(effective.toJson()), effective);
  });

  test('documents validate scope and reject unknown future schemas', () {
    final document = SpatialVisualDocument(
      profile: SpatialVisualPatch.fromJson({'fogOpacity': .2}),
    );
    expect(
      SpatialVisualDocument.fromJson(document.toJson()).profile,
      document.profile,
    );
    expect(
      SpatialVisualDocument.relativePathForMap('village'),
      'maps/village.visual.json',
    );
    expect(
      () => SpatialVisualDocument.relativePathForMap('../outside'),
      throwsFormatException,
    );
    expect(
      () => SpatialVisualDocument.fromJson({
        ...document.toJson(),
        'schemaVersion': 99,
      }),
      throwsFormatException,
    );
    expect(
      () => SpatialVisualDocument.fromJson({
        ...document.toJson(),
        'unexpected': true,
      }),
      throwsFormatException,
    );
  });

  test('parameter constraints reject malformed and nonfinite updates', () {
    for (final invalid in [
      {'halosEnabled': 1},
      {'pitchDegrees': 0},
      {'fieldOfViewDegrees': 120},
      {'depthOfFieldStrength': double.nan},
      {'fogOpacity': .8},
      {'fogStart': 20, 'fogEnd': 10},
      {'waterTargets': []},
      {'unknown': true},
      {'minuteOfDay': 1440},
    ]) {
      expect(() => SpatialVisualPatch.fromJson(invalid), throwsFormatException);
    }
  });

  test('interpolation blends numbers and enables boolean effects', () {
    final from = SpatialVisualPatch.fromJson({
      'pitchDegrees': 34,
      'haloStrength': .4,
      'halosEnabled': false,
    });
    final to = SpatialVisualPatch.fromJson({
      'pitchDegrees': 42,
      'haloStrength': 1.2,
      'halosEnabled': true,
    });
    final halfway = SpatialVisualPatch.interpolate(from, to, .5);
    expect(halfway.value(SpatialVisualParameter.pitchDegrees), 38);
    expect(
      halfway.value(SpatialVisualParameter.haloStrength),
      closeTo(.8, 1e-9),
    );
    expect(halfway.value(SpatialVisualParameter.halosEnabled), isTrue);
  });
}

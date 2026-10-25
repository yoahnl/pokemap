import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('v2 halo and fog settings survive a complete document round trip', () {
    final raw = <String, dynamic>{
      'schemaVersion': 2,
      'mapId': 'village',
      'settings': {
        'halosEnabled': true,
        'haloStrength': 1.4,
        'haloSpread': 1.2,
        'depthFogEnabled': true,
        'fogOpacity': .32,
        'fogStart': 39,
        'fogEnd': 49,
        'halos': [
          {
            'instanceId': 'lamp',
            'localPosition': {'x': 0, 'y': 2.25, 'z': 0},
            'radiusX': 1.05,
            'radiusY': 1.05,
            'opacity': .36,
            'colorRgb': 0xffcf83,
            'window': false,
          },
        ],
      },
    };
    final document = SpatialAtmosphereDocument.fromJson(raw);
    expect(document.toJson()['schemaVersion'], 2);
    final settings = document.settings.toJson();
    for (final key in (raw['settings'] as Map).keys) {
      expect(settings[key], (raw['settings'] as Map)[key]);
    }
  });
  test('defaults keep legacy presentation disabled', () {
    final settings = SpatialAtmosphereSettings();
    expect(settings.waterAnimated, isFalse);
    expect(settings.windowsLit, isFalse);
    expect(settings.fireflies, isFalse);
    expect(settings.halosEnabled, isFalse);
    expect(settings.depthFogEnabled, isFalse);
  });
  test(
    'protected v1 atmosphere retains its meaning without mutating the input',
    () {
      final raw = <String, dynamic>{
        'schemaVersion': 1,
        'mapId': 'village',
        'settings': {'windowsLit': true, 'windowStrength': .9},
      };
      final settings = SpatialAtmosphereDocument.fromJson(raw).settings;
      expect(settings.windowsLit, isTrue);
      expect(settings.windowStrength, .9);
      expect(settings.halosEnabled, isFalse);
      expect(settings.depthFogEnabled, isFalse);
      expect(raw['schemaVersion'], 1);
      expect(raw['settings'], {'windowsLit': true, 'windowStrength': .9});
      expect(
        SpatialAtmosphereDocument(
          mapId: 'village',
          settings: settings,
        ).toJson()['schemaVersion'],
        2,
      );
      expect(
        () => SpatialAtmosphereDocument.fromJson({
          'schemaVersion': 1,
          'mapId': 'village',
          'settings': {'halosEnabled': true},
        }),
        throwsFormatException,
      );
    },
  );
  test('fog ordering and halo bounds reject malformed data', () {
    for (final raw in [
      {'fogStart': 50, 'fogEnd': 40},
      {'fogOpacity': .6},
      {'haloSpread': 0},
      {'haloStrength': double.nan},
      {
        'halos': [
          {
            'instanceId': 'lamp',
            'localPosition': {'x': 0, 'y': 2, 'z': 0},
            'radiusX': 0,
          },
        ],
      },
    ]) {
      expect(
        () =>
            SpatialAtmosphereSettings.fromJson(Map<String, dynamic>.from(raw)),
        throwsFormatException,
      );
    }
  });
  test('sidecar round trips all settings and explicit scene targets', () {
    final settings = SpatialAtmosphereSettings(
      waterAnimated: true,
      windowsLit: true,
      fireflies: true,
      waterStrength: .7,
      waterSpeed: 1.2,
      windowStrength: .9,
      fireflyDensity: 1.4,
      waterTargets: [SpatialAtmosphereMaterialTarget.groundTileset('river')],
      windows: [
        SpatialAtmosphereWindow(
          target: SpatialAtmosphereMaterialTarget(
            instanceId: 'house',
            materialName: 'wall',
          ),
          uvRects: [
            SpatialAtmosphereUvRect(left: .1, top: .2, right: .3, bottom: .4),
          ],
        ),
      ],
      fireflyZones: [
        SpatialAtmosphereFireflyZone(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 2, y: 1, z: 3),
          ),
        ),
      ],
    );
    final document = SpatialAtmosphereDocument(
      mapId: 'village',
      settings: settings,
    );
    expect(
      SpatialAtmosphereDocument.fromJson(document.toJson()).settings,
      settings,
    );
    expect(settings.copyWith(windowsLit: false).windowsLit, isFalse);
    expect(settings.copyWith(windowsLit: false).fireflies, isTrue);
    expect(
      SpatialAtmosphereDocument.relativePathForMap('village'),
      'maps/village.atmosphere.json',
    );
  });
  test('future versions and malformed bounded values fail safely', () {
    expect(
      () => SpatialAtmosphereDocument.fromJson({
        'schemaVersion': 3,
        'mapId': 'village',
        'settings': {},
      }),
      throwsFormatException,
    );
    expect(
      () => SpatialAtmosphereDocument.relativePathForMap('../outside'),
      throwsFormatException,
    );
    expect(
      () => SpatialAtmosphereSettings(waterStrength: double.nan),
      throwsFormatException,
    );
    expect(
      () => SpatialAtmosphereSettings(fireflyDensity: 3),
      throwsFormatException,
    );
    expect(
      () => SpatialAtmosphereSettings.fromJson({'waterAnimated': 1}),
      throwsFormatException,
    );
    expect(
      () => SpatialAtmosphereUvRect(left: 0, top: 0, right: 2, bottom: 1),
      throwsFormatException,
    );
  });
}

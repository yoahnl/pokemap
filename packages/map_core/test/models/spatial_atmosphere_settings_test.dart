import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('defaults keep legacy presentation disabled', () {
    final settings = SpatialAtmosphereSettings();
    expect(settings.waterAnimated, isFalse);
    expect(settings.windowsLit, isFalse);
    expect(settings.fireflies, isFalse);
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
        'schemaVersion': 2,
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

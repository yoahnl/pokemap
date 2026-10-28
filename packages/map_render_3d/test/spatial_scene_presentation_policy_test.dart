import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  test('clear views mask authored effects without rebuilding the scene', () {
    final controller = SpatialSceneController(
      presentationEffectsEnabled: false,
    );
    addTearDown(controller.dispose);
    final settings = SpatialAtmosphereSettings(
      depthOfFieldEnabled: true,
      depthFogEnabled: true,
      halosEnabled: true,
      fireflies: true,
      halos: [
        SpatialAtmosphereHalo(
          instanceId: 'lamp',
          localPosition: Model3dVector3.zero,
        ),
      ],
      weather: SpatialWeatherSettings(enabled: true, lightning: true),
    );
    controller.applyAtmosphereSettings(settings);
    final presentation = controller.presentationProfile;
    final depth = controller.depthOfFieldProfile;
    final weather = controller.weatherSettings;
    final atmosphere = controller.atmosphereProfile;
    var sceneChanges = 0;
    controller.sceneChanges.addListener(() => sceneChanges++);
    for (var index = 0; index < 10; index++) {
      controller.visualProfile = SpatialVisualPatch.fromJson({
        'depthOfFieldEnabled': true,
        'depthOfFieldStrength': index / 10,
        'depthFogEnabled': true,
        'halosEnabled': true,
        'weatherEnabled': true,
        'fireflies': true,
      });
      controller.worldEnvironment = const WorldEnvironmentFrame(
        weatherKind: SpatialWeatherKind.storm,
        weatherIntensity: 1,
      );
      controller
        ..halosEnabled = true
        ..depthFogEnabled = true
        ..fireflies = true
        ..depthOfFieldEnabled = true;
      expect(controller.presentationProfile, same(presentation));
      expect(controller.presentationProfile.halos, isEmpty);
      expect(controller.depthOfFieldProfile, same(depth));
      expect(controller.depthOfFieldProfile.active, isFalse);
      expect(controller.weatherSettings, same(weather));
      expect(controller.weatherSettings.enabled, isFalse);
      expect(controller.weatherSettings.lightning, isFalse);
      expect(controller.fireflies, isFalse);
      expect(controller.halosEnabled, isFalse);
      expect(controller.depthFogEnabled, isFalse);
      expect(controller.atmosphereProfile, same(atmosphere));
    }
    expect(sceneChanges, 0);
    expect(settings.depthOfFieldEnabled, isTrue);
    expect(settings.halos.length, 1);
    expect(settings.weather.enabled, isTrue);
    final game = SpatialSceneController()..applyAtmosphereSettings(settings);
    addTearDown(game.dispose);
    expect(game.depthOfFieldProfile.active, isTrue);
    expect(game.halosEnabled, isTrue);
    expect(game.depthFogEnabled, isTrue);
    expect(game.fireflies, isTrue);
    expect(game.weatherSettings, same(settings.weather));
    expect(game.presentationProfile.halos.length, 1);
  });
}

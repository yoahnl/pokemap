import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy lights retain their exact representation and behavior', () {
    final legacy = {
      'localPosition': {'x': 0.0, 'y': 2.0, 'z': 0.0},
      'radius': 4.0,
      'intensity': 1.0,
      'colorRgb': 0xffd59a,
      'nightOnly': true,
    };
    final light = Model3dPointLight.fromJson(legacy);
    expect(light.toJson(), legacy);
    expect(light.colorCycle, isNull);
    expect(light.proximity, isNull);
  });
  test(
    'light behavior validates, round trips and samples the simulation clock',
    () {
      final cycle = ModelLightColorCycle(
        colors: [0xff0000, 0x0000ff],
        periodSeconds: 8,
      );
      final proximity = ModelLightProximity(
        mode: ModelLightProximityMode.near,
        enterDistance: 3,
        exitDistance: 4,
        fadeSeconds: .4,
      );
      final light = Model3dPointLight(
        localPosition: Model3dVector3.zero,
        colorCycle: cycle,
        proximity: proximity,
      );
      expect(Model3dPointLight.fromJson(light.toJson()), light);
      expect(cycle.sample(0), 0xff0000);
      expect(cycle.sample(2), 0x800080);
      expect(cycle.sample(4), 0x0000ff);
      expect(cycle.sample(8), 0xff0000);
      expect(
        () => ModelLightColorCycle(colors: [0xffffff]),
        throwsFormatException,
      );
      expect(
        () => ModelLightColorCycle(colors: [0, 1], periodSeconds: double.nan),
        throwsFormatException,
      );
      expect(
        () => ModelLightProximity(enterDistance: 4, exitDistance: 3),
        throwsFormatException,
      );
      expect(
        () => ModelLightProximity.fromJson({'mode': 'invalid'}),
        throwsFormatException,
      );
      expect(light.copyWith(clearColorCycle: true).colorCycle, isNull);
      expect(light.copyWith(clearProximity: true).proximity, isNull);
    },
  );
}

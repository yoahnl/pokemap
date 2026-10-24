import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('point shadow capability combines used lights and effective casters across maps', () {
    final lamp = ProjectModel3dEntry.fromJson({..._model().toJson(), 'id': 'lamp', 'relativePath': 'assets/models3d/lamp.glb'}).copyWith(light: Model3dPointLight(localPosition: Model3dVector3.zero));
    final house = ProjectModel3dEntry.fromJson({..._model().toJson(), 'id': 'house', 'relativePath': 'assets/models3d/house.glb'}).copyWith(castsShadowsByDefault: true);
    final project = ProjectManifest(name: 'Lighting', maps: [], tilesets: [], models3d: [lamp, house]);
    MapData map(String id, String modelId, {bool? castsShadows}) => MapData(
      id: id, name: id, size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [SpatialModelInstance(
        id: 'placement', modelId: modelId, position: Model3dVector3.zero, castsShadows: castsShadows)]));
    final lit = map('lit', 'lamp');
    final casting = map('casting', 'house');
    expect(SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId, 'map3d.point-light-shadows@1');
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project), false);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project, maps: [lit]), false);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project, maps: [casting]), false);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project, maps: [lit, casting]), true);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project, maps: [lit, map('off', 'house', castsShadows: false)]), false);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project.copyWith(models3d: [lamp, house.copyWith(castsShadowsByDefault: false)]), maps: [lit, map('on', 'house', castsShadows: true)]), true);
    expect(SpatialSceneLightingCapabilities.requiresPointLightShadows(project.copyWith(models3d: [lamp.copyWith(light: lamp.light!.copyWith(intensity: 0)), house]), maps: [lit, casting]), false);
  });
  test('attached point light survives resource JSON and rejects invalid values', () {
    final light = <String, dynamic>{
      'localPosition': {'x': 0.0, 'y': 2.25, 'z': 0.0},
      'radius': 4.0, 'intensity': 1.0, 'colorRgb': 0xffd59a, 'nightOnly': true,
    };
    final attached = ProjectModel3dEntry.fromJson({..._model().toJson(), 'light': light});
    expect(attached.toJson()['light'], light);
    expect(attached.copyWith(name: 'Lamp').toJson()['light'], light);
    expect(ProjectModel3dEntry.fromJson(attached.toJson()), attached);
    for (final invalid in [0, 64.1, '4']) {
      expect(() => ProjectModel3dEntry.fromJson({..._model().toJson(),
        'light': {...light, 'radius': invalid}}), throwsFormatException);
    }
    expect(ProjectModel3dEntry.fromJson({..._model().toJson(), 'light': null}), _model());
  });
  test('day night cycle survives scene JSON and rejects invalid timing', () {
    final scene = MapSpatialScene(width: 4, depth: 4);
    final cycle = <String, dynamic>{'durationSeconds': 600.0, 'startMinuteOfDay': 720};
    final configured = MapSpatialScene.fromJson({...scene.toJson(), 'dayNightCycle': cycle});
    expect(configured.toJson()['dayNightCycle'], cycle);
    expect(configured.copyWith(generateCliffs: false).toJson()['dayNightCycle'], cycle);
    for (final duration in [0, 9, 86401, '600']) {
      expect(() => MapSpatialScene.fromJson({...scene.toJson(),
        'dayNightCycle': {...cycle, 'durationSeconds': duration}}), throwsFormatException);
    }
  });
  test('visual cycle evaluator wraps deterministically and preserves scene edits', () {
    final cycle = SpatialDayNightCycle();
    expect(cycle.minuteAtElapsed(0), 720);
    expect(cycle.minuteAtElapsed(150), 1080);
    expect(cycle.minuteAtElapsed(300), 0);
    expect(cycle.minuteAtElapsed(600), 720);
    expect(cycle.minuteAtElapsed(1200), 720);
    for (final elapsed in [-1.0, double.nan, double.infinity]) {
      expect(() => cycle.minuteAtElapsed(elapsed), throwsFormatException);
    }
    for (final minute in [-1, 1440]) {
      expect(() => SpatialDayNightCycle(startMinuteOfDay: minute), throwsFormatException);
    }
    final map = MapData(id: 'map', name: 'Map', version: ProjectVersion.v9, size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4));
    const operations = SpatialMapOperations();
    final configured = operations.configureDayNightCycle(map, cycle);
    expect(operations.configureLevelHeight(configured, .5).spatialScene!.dayNightCycle, cycle);
    expect(operations.configureDayNightCycle(configured, null), map);
    expect(configured.spatialScene!.copyWith(clearDayNightCycle: true), map.spatialScene);
  });
  test('point light limits and capability derivation ignore unused resources', () {
    final light = Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 2.25, z: 0));
    for (final invalid in [-1.0, 4.01, double.nan]) {
      expect(() => light.copyWith(intensity: invalid), throwsFormatException);
    }
    for (final rgb in [-1, 0x1000000]) {
      expect(() => light.copyWith(colorRgb: rgb), throwsFormatException);
    }
    expect(Model3dPointLight.fromJson(light.toJson()), light);
    final model = _model().copyWith(light: light);
    expect(model.copyWith(clearLight: true), _model());
    final project = ProjectManifest(name: 'Light', maps: [], tilesets: [], models3d: [model]);
    final map = MapData(id: 'map', name: 'Map', version: ProjectVersion.v9, size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [SpatialModelInstance(
        id: 'lamp', modelId: model.id, position: Model3dVector3(x: 1, y: 0, z: 1))]));
    expect(SpatialSceneLightingCapabilities.requiresPointLights(project), false);
    expect(SpatialSceneLightingCapabilities.requiresPointLights(project, maps: [map]), true);
    expect(SpatialSceneLightingCapabilities.requiresPointLights(project.copyWith(models3d: [model.copyWith(light: light.copyWith(intensity: 0))]), maps: [map]), false);
    expect(SpatialSceneLightingCapabilities.requiresDayNight(project, maps: [map]), false);
    expect(SpatialSceneLightingCapabilities.requiresDayNight(project, maps: [const SpatialMapOperations().configureDayNightCycle(map, SpatialDayNightCycle())]), true);
  });
  test('shadow casting defaults off and roundtrips explicit resource settings', () {
    final original = _model();
    expect(original.toJson(), isNot(contains('castsShadowsByDefault')));
    final enabled = ProjectModel3dEntry.fromJson({
      ...original.toJson(), 'castsShadowsByDefault': true,
    });
    expect(enabled.toJson()['castsShadowsByDefault'], true);
    expect(enabled.copyWith(name: 'Shadow tree').toJson()['castsShadowsByDefault'], true);
    expect(ProjectModel3dEntry.fromJson(enabled.toJson()), enabled);
    expect(enabled, isNot(original));
    for (final invalid in [null, 1, 'true']) {
      expect(() => ProjectModel3dEntry.fromJson({
        ...original.toJson(), 'castsShadowsByDefault': invalid,
      }), throwsFormatException);
    }
  });
  test('instance shadow override preserves inherit on and off through map JSON', () {
    final original = SpatialModelInstance(id: 'tree', modelId: 'model',
      position: Model3dVector3.zero);
    for (final value in [null, false, true]) {
      final instance = SpatialModelInstance.fromJson({
        ...original.toJson(), 'castsShadows': value,
      });
      expect(instance.toJson()['castsShadows'], value);
      expect(instance.copyWith(scale: 2).toJson()['castsShadows'], value);
      expect(SpatialModelInstance.fromJson(instance.toJson()), instance);
    }
    for (final invalid in [1, 'false']) {
      expect(() => SpatialModelInstance.fromJson({
        ...original.toJson(), 'castsShadows': invalid,
      }), throwsFormatException);
    }
  });
  test('shadow inheritance resets without losing placement data and derives package capability', () {
    final disabled = _model();
    final enabled = disabled.copyWith(castsShadowsByDefault: true);
    final instance = SpatialModelInstance(id: 'tree', modelId: disabled.id,
      position: Model3dVector3(x: 1, y: 0, z: 1));
    expect(instance.effectiveCastsShadows(disabled), false);
    expect(instance.effectiveCastsShadows(enabled), true);
    expect(instance.copyWith(castsShadows: false).effectiveCastsShadows(enabled), false);
    final reset = instance.copyWith(castsShadows: true).copyWith(clearCastsShadows: true);
    expect(reset, instance);
    final project = ProjectManifest(name: 'Shadows', maps: [], tilesets: [], models3d: [enabled]);
    MapData map(SpatialModelInstance item) => MapData(id: 'first-map', name: 'Map',
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [item]));
    expect(SpatialModelShadowCapabilities.requiresCapability(project), false);
    expect(SpatialModelShadowCapabilities.requiresCapability(project, maps: [map(instance)]), true);
    expect(SpatialModelShadowCapabilities.requiresCapability(project, maps: [map(instance.copyWith(castsShadows: false))]), false);
    expect(SpatialModelShadowCapabilities.requiresCapability(project.copyWith(models3d: [disabled]), maps: [map(instance.copyWith(castsShadows: true))]), true);
  });
  test('model default blocking preserves explicit false without default churn', () {
    final blocking = _model();
    expect(blocking.toJson(), isNot(contains('blocksMovementByDefault')));
    final nonblocking = ProjectModel3dEntry.fromJson({
      ...blocking.toJson(),
      'blocksMovementByDefault': false,
    });
    expect(nonblocking.toJson()['blocksMovementByDefault'], false);
    expect(nonblocking.copyWith(name: 'Decoration').toJson()['blocksMovementByDefault'], false);
    expect(ProjectModel3dEntry.fromJson(nonblocking.toJson()), nonblocking);
    expect(nonblocking, isNot(blocking));
    expect(nonblocking.hashCode, isNot(blocking.hashCode));
    final explicitTrue = ProjectModel3dEntry.fromJson({
      ...blocking.toJson(),
      'blocksMovementByDefault': true,
    });
    expect(explicitTrue, blocking);
    expect(explicitTrue.toJson(), blocking.toJson());
    for (final invalid in [null, 0, 'false', <String, dynamic>{}]) {
      expect(() => ProjectModel3dEntry.fromJson({
        ...blocking.toJson(),
        'blocksMovementByDefault': invalid,
      }), throwsFormatException);
    }
  });
  test(
    'local collision bounds roundtrip independently of visible geometry',
    () {
      final collision = {
        'min': {'x': .75, 'y': 0.0, 'z': .25},
        'max': {'x': 1.25, 'y': 1.0, 'z': .75},
      };
      final model = ProjectModel3dEntry.fromJson({
        ..._model().toJson(),
        'collisionBounds': collision,
      });
      expect(model.toJson()['collisionBounds'], collision);
      expect(model.inspection, _model().inspection);
      expect(ProjectModel3dEntry.fromJson(model.toJson()), model);
      expect(
        model.copyWith(name: 'Tree').toJson()['collisionBounds'],
        collision,
      );
      expect(model, isNot(_model()));
      expect(
        () => ProjectModel3dEntry.fromJson({
          ..._model().toJson(),
          'collisionBounds': {
            'min': {'x': 1.0, 'y': 0.0, 'z': 0.0},
            'max': {'x': 1.0, 'y': 1.0, 'z': 1.0},
          },
        }),
        throwsFormatException,
      );
    },
  );
  test('model material roundtrips explicit MASK and rejects other cutoffs', () {
    final json = {
      'index': 0,
      'name': 'BW2',
      'alphaMode': 'mask',
      'alphaCutoff': .5,
      'doubleSided': true,
    };
    expect(Model3dMaterial.fromJson(json).toJson(), json);
    expect(
      () => Model3dMaterial.fromJson({...json, 'doubleSided': 'true'}),
      throwsFormatException,
    );
    expect(
      () => Model3dMaterial.fromJson({...json, 'alphaCutoff': .1}),
      throwsFormatException,
    );
    expect(
      () => Model3dMaterial.fromJson({...json, 'alphaMode': 'blend'}),
      throwsFormatException,
    );
  });
  test(
    'model catalog roundtrips inspected metadata and authoring transforms',
    () {
      final model = _model();
      final manifest = ProjectManifest(
        name: 'Models',
        maps: [],
        tilesets: [],
        models3d: [model],
      );
      final reopened = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );
      expect(reopened, manifest);
      expect(reopened.hashCode, manifest.hashCode);
      expect(reopened.models3d.single.toJson(), model.toJson());
      expect(reopened.models3d.single.inspection.bounds.size.toJson(), {
        'x': 2.0,
        'y': 3.0,
        'z': 1.0,
      });
      expect(
        () => reopened.models3d.single.inspection.animations.add(
          Model3dAnimation(index: 2, name: 'Other', durationSeconds: 1),
        ),
        throwsUnsupportedError,
      );
    },
  );
  test('duplicate catalog identities are rejected', () {
    final manifest = ProjectManifest(
      name: 'Models',
      maps: [],
      tilesets: [],
      models3d: [_model(), _model()],
    );
    expect(
      () => ProjectManifest.fromJson(manifest.toJson()),
      throwsA(isA<Exception>()),
    );
    expect(
      () => ProjectValidator.validate(manifest),
      throwsA(isA<ValidationException>()),
    );
  });
  test('source path escapes and invalid model transforms are rejected', () {
    expect(
      () => ProjectModel3dEntry.fromJson({
        ..._model().toJson(),
        'relativePath': '../outside.glb',
      }),
      throwsFormatException,
    );
    expect(
      () => _model().copyWith(scale: double.infinity),
      throwsFormatException,
    );
    expect(() => _model().copyWith(scale: -1), throwsFormatException);
    expect(
      () => Model3dVector3(x: double.nan, y: 0, z: 0),
      throwsFormatException,
    );
    expect(
      () => Model3dBounds(
        min: Model3dVector3(x: 2, y: 0, z: 0),
        max: Model3dVector3.zero,
      ),
      throwsFormatException,
    );
  });
}

ProjectModel3dEntry _model() => ProjectModel3dEntry(
  id: 'house',
  name: 'House',
  sourceAssetId: 'model3d_house',
  relativePath: 'assets/models3d/house.glb',
  scale: 2,
  pivot: Model3dVector3(x: 1, y: 0, z: 0),
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 2, y: 3, z: 1),
    ),
    meshCount: 1,
    triangleCount: 12,
    materials: [Model3dMaterial(index: 0, name: 'Stone')],
    animations: [Model3dAnimation(index: 0, name: 'Wind', durationSeconds: 2)],
    diagnostics: ['bounds.static_scene_only'],
  ),
);

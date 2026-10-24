import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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

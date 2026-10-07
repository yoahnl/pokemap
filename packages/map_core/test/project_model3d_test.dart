import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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

import 'package:avelune_studio/features/resources/application/model_resource_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

ProjectModel3dEntry _model() => ProjectModel3dEntry(
  id: 'lamp',
  name: 'Lamp',
  sourceAssetId: 'model3d_lamp',
  relativePath: 'assets/models3d/lamp.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -1, y: 0.5, z: 2),
      max: Model3dVector3(x: 3, y: 3, z: 6),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);

void main() {
  test('every renderer diagnostic maps to its own message and unknown codes fall back', () {
    final labels = {
      for (final code in [
        'renderer.missing_material_magenta',
        'bounds.static_scene_only',
        'bounds.bind_pose_only',
        'renderer.ignored_color_0',
        'renderer.ignored_normalTexture',
        'renderer.ignored_occlusionTexture',
        'renderer.ignored_emissiveTexture',
        'renderer.ignored_metallicRoughnessTexture',
      ])
        code: modelDiagnosticLabel(code),
    };
    expect(labels.values.toSet(), hasLength(labels.length));
    expect(labels['renderer.missing_material_magenta'], contains('rose'));
    expect(labels['bounds.bind_pose_only'], contains('pose initiale'));
    expect(
      modelDiagnosticLabel('renderer.ignored_emissiveFactor'),
      modelDiagnosticLabel('renderer.ignored_emissiveTexture'),
    );
    for (final code in [
      'renderer.ignored_metallicFactor',
      'renderer.ignored_roughnessFactor',
    ]) {
      expect(
        modelDiagnosticLabel(code),
        modelDiagnosticLabel('renderer.ignored_metallicRoughnessTexture'),
      );
    }
    final fallback = modelDiagnosticLabel('renderer.something_new');
    expect(fallback, contains('propriété visuelle'));
    expect(labels.values, isNot(contains(fallback)));
  });

  test('scale text accepts decimals with a comma and refuses non positive or invalid numbers', () {
    expect(parseModelScale('1,5'), 1.5);
    expect(parseModelScale('2'), 2.0);
    for (final text in ['0', '-1', 'abc', '', 'NaN', 'Infinity']) {
      expect(parseModelScale(text), isNull, reason: text);
    }
    expect(modelScaleRefusal, 'L’échelle doit être un nombre positif.');
  });

  test('foot pivot is the horizontal centre of the bounds at their lowest height', () {
    expect(modelFootPivotFields(_model()), {
      'pivot': {'x': 1.0, 'y': 0.5, 'z': 4.0},
    });
  });

  test('configure payloads carry the model identity and only the requested field', () {
    expect(modelConfigurePayload('lamp', modelShadowFields(true)), {
      'modelId': 'lamp',
      'castsShadowsByDefault': true,
    });
    expect(modelConfigurePayload('lamp', {'scale': 2.0, 'name': 'Lampe'}), {
      'modelId': 'lamp',
      'scale': 2.0,
      'name': 'Lampe',
    });
    expect(modelLightFields(null), {'light': null});
    final light = Model3dPointLight(
      localPosition: Model3dVector3(x: 0, y: 2, z: 0),
    );
    expect(modelConfigurePayload('lamp', modelLightFields(light)), {
      'modelId': 'lamp',
      'light': light.toJson(),
    });
  });
}

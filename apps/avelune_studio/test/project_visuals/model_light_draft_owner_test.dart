import 'package:avelune_studio/features/resources/application/model_light_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  test('lamp preview edits stay local until save and preserve cycle proximity and flame crackle', () async {
    final light = Model3dPointLight(
      localPosition: Model3dVector3(x: 0, y: 2, z: 0),
      colorCycle: ModelLightColorCycle(colors: [0xffd59a, 0xbddfff]),
      proximity: ModelLightProximity(mode: ModelLightProximityMode.near),
    );
    final model = _model(light: light);
    final draft = ModelLightDraft(model);
    final preview = ModelPreviewController()..setLight(light);
    addTearDown(preview.dispose);
    var saves = 0;
    Model3dPointLight? persisted;
    draft.values[1] = '2.75';
    preview.setLight(draft.build());
    expect(preview.light!.localPosition.y, 2.75);
    expect(saves, 0);
    draft.flame = true;
    draft.flameStyle = ModelLightFlameStyle.brazier;
    draft.flameCrackleVolume = .75;
    preview.setLight(draft.build());
    expect(preview.light!.flame!.style, ModelLightFlameStyle.brazier);
    expect(preview.light!.flame!.crackleVolume, .75);
    expect(saves, 0);
    preview.setLight(
      preview.light!.copyWith(localPosition: Model3dVector3(x: 1, y: 3, z: 2)),
    );
    expect(draft.move(preview.light!.localPosition), isTrue);
    expect(draft.values[1], '3.0000');
    expect(draft.move(preview.light!.localPosition), isFalse);
    expect(
      await draft.save((value) async {
        saves++;
        persisted = value;
      }, canSave: () => true),
      isTrue,
    );
    expect(saves, 1);
    expect(persisted!.localPosition, Model3dVector3(x: 1, y: 3, z: 2));
    expect(persisted!.colorCycle, light.colorCycle);
    expect(persisted!.proximity, light.proximity);
    expect(persisted!.flame!.crackleVolume, .75);
    expect(model.light, same(light));
    draft.flame = false;
    preview.setLight(draft.build());
    expect(preview.light!.flame, isNull);
    expect(saves, 1);
  });

  test(
    'invalid light numbers and bounds are refused without publishing',
    () async {
      final draft = ModelLightDraft(_model())..enabled = true;
      var saves = 0;
      Future<void> publish(Model3dPointLight? _) async {
        saves++;
      }

      draft.values[0] = 'NaN';
      expect(await draft.save(publish, canSave: () => true), isFalse);
      expect(draft.error, contains('nombres valides'));
      draft.values[0] = '0,25';
      draft.values[3] = '0';
      expect(await draft.save(publish, canSave: () => true), isFalse);
      expect(saves, 0);
      draft.values[3] = '4';
      expect(await draft.save(publish, canSave: () => false), isFalse);
      expect(saves, 0);
    },
  );

  test('light persistence failures preserve the editable settings and disabling clears the definition', () async {
    final draft = ModelLightDraft(_model())
      ..enabled = true
      ..flame = true
      ..flameCrackleVolume = .75;
    expect(
      await draft.save(
        (_) async => throw StateError('Disque indisponible'),
        canSave: () => true,
      ),
      isFalse,
    );
    expect(draft.error, contains('Disque indisponible'));
    expect(draft.flameCrackleVolume, .75);
    expect(draft.saving, isFalse);
    draft.enabled = false;
    final saved = <Model3dPointLight?>[];
    expect(
      await draft.save((value) async {
        saved.add(value);
      }, canSave: () => true),
      isTrue,
    );
    expect(saved, [null]);
    draft.dispose();
    expect(
      await draft.save((value) async {
        saved.add(value);
      }, canSave: () => true),
      isFalse,
    );
    expect(saved, hasLength(1));
  });
}

ProjectModel3dEntry _model({Model3dPointLight? light}) => ProjectModel3dEntry(
  id: 'lamp',
  name: 'Lamp',
  sourceAssetId: 'model3d_lamp',
  relativePath: 'assets/models3d/lamp.glb',
  light: light,
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 3, z: 1),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);

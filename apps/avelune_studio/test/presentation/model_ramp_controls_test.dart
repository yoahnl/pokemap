import 'package:avelune_studio/features/resources/application/model_definition_drafts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

ProjectModel3dEntry _model() => ProjectModel3dEntry(
  id: 'stairs',
  name: 'Escalier',
  sourceAssetId: 'stairs-source',
  relativePath: 'assets/models3d/stairs.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -.5, y: 0, z: -2),
      max: Model3dVector3(x: .5, y: 1, z: 0),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);

void main() {
  test(
    'the stair draft proposes bounds and saves a reusable profile',
    () async {
      Model3dRampProfile? saved;
      final model = _model();
      final draft = ModelRampDraft(model)..enabled = true;
      expect(
        await draft.save((value) async => saved = value, canSave: () => true),
        isTrue,
      );
      expect(saved!.width, 1);
      expect(saved!.depth, 2);
      expect(saved!.highHeight, 1);
      expect(saved!.direction, SpatialRampDirection.north);
      expect(model.rampProfile, isNull);
    },
  );

  test(
    'invalid dimensions keep their raw stair draft without publishing',
    () async {
      final draft = ModelRampDraft(_model())..enabled = true;
      var publications = 0;
      Future<void> publish(Model3dRampProfile? _) async {
        publications++;
      }

      draft.values[2] = 'NaN';
      expect(await draft.save(publish, canSave: () => true), isFalse);
      expect(draft.error, contains('dimensions valides'));
      draft.values[2] = '-1';
      expect(await draft.save(publish, canSave: () => true), isFalse);
      expect(publications, 0);
      expect(draft.values[2], '-1');
    },
  );

  test('a disabled stair draft clears the profile and busy or closed drafts refuse saves', () async {
    final draft = ModelRampDraft(_model());
    final saved = <Model3dRampProfile?>[];
    Future<void> publish(Model3dRampProfile? value) async {
      saved.add(value);
    }

    expect(await draft.save(publish, canSave: () => false), isFalse);
    expect(saved, isEmpty);
    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saved, [null]);
    draft.dispose();
    expect(await draft.save(publish, canSave: () => true), isFalse);
    expect(saved, hasLength(1));
  });
}

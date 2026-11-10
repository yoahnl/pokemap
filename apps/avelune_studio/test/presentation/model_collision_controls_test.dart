import 'package:avelune_studio/features/resources/application/model_definition_drafts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test('resource collision retains the default for future placements', () {
    final model = spatialEnvironmentProject().models3d.single;
    final draft = ModelCollisionDraft(model);
    expect(draft.blocksMovementByDefault, model.blocksMovementByDefault);
    expect(draft.custom, model.collisionBounds != null);
  });

  test('custom collision validates six local coordinates and saves an independent volume', () async {
    var model = spatialEnvironmentProject().models3d.single.copyWith(scale: 2);
    final visualBounds = model.inspection.bounds;
    final draft = ModelCollisionDraft(model)..custom = true;
    final saved = <Model3dBounds?>[];
    Future<void> publish(Model3dBounds? bounds, bool blocks) async {
      saved.add(bounds);
      model = model.copyWith(
        blocksMovementByDefault: blocks,
        collisionBounds: bounds,
        clearCollisionBounds: bounds == null,
      );
    }

    draft.values[0] = '0,1';
    draft.values[3] = '0';
    expect(await draft.save(publish, canSave: () => true), isFalse);
    expect(
      draft.error,
      'Chaque maximum doit être supérieur au minimum correspondant.',
    );
    draft.values[3] = 'NaN';
    expect(await draft.save(publish, canSave: () => true), isFalse);
    expect(draft.error, 'Saisissez six nombres valides pour le volume.');
    expect(saved, isEmpty);
    draft.values = ['-0,1', '0', '-0,1', '0,1', '1,5', '0,1'];
    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saved.single!.toJson(), {
      'min': {'x': -.1, 'y': 0.0, 'z': -.1},
      'max': {'x': .1, 'y': 1.5, 'z': .1},
    });
    expect(model.inspection.bounds, visualBounds);
    draft.custom = false;
    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saved.last, isNull);
    expect(model.collisionBounds, isNull);
    expect(model.inspection.bounds, visualBounds);
  });

  test(
    'collision changes cancel locally and remote failures retain the draft',
    () async {
      final model = spatialEnvironmentProject().models3d.single;
      final draft = ModelCollisionDraft(model)
        ..custom = true
        ..blocksMovementByDefault = false;
      var fails = true;
      final saved = <bool>[];
      Future<void> publish(Model3dBounds? bounds, bool blocks) async {
        if (fails) throw StateError('Révision modifiée');
        saved.add(blocks);
      }

      expect(await draft.save(publish, canSave: () => true), isFalse);
      expect(draft.error, contains('Révision modifiée'));
      expect(draft.custom, isTrue);
      expect(draft.blocksMovementByDefault, isFalse);
      fails = false;
      expect(await draft.save(publish, canSave: () => true), isTrue);
      expect(saved, [false]);
      final cancelled = ModelCollisionDraft(model);
      expect(cancelled.custom, isFalse);
      expect(cancelled.blocksMovementByDefault, model.blocksMovementByDefault);
    },
  );

  test('placement default saves independently of volume and supports cancel and busy state', () async {
    var model = spatialEnvironmentProject().models3d.single.copyWith(
      collisionBounds: Model3dBounds(
        min: Model3dVector3(x: -.1, y: 0, z: -.1),
        max: Model3dVector3(x: .1, y: 1, z: .1),
      ),
    );
    final original = model.collisionBounds;
    var draft = ModelCollisionDraft(model)..blocksMovementByDefault = false;
    draft = ModelCollisionDraft(model);
    expect(draft.blocksMovementByDefault, isTrue);
    draft.blocksMovementByDefault = false;
    final saved = <bool>[];
    Future<void> publish(Model3dBounds? bounds, bool blocks) async {
      saved.add(blocks);
      model = model.copyWith(
        collisionBounds: bounds,
        blocksMovementByDefault: blocks,
      );
    }

    expect(await draft.save(publish, canSave: () => true), isTrue);
    expect(saved, [false]);
    expect(model.collisionBounds, original);
    expect(model.blocksMovementByDefault, isFalse);
    expect(await draft.save(publish, canSave: () => false), isFalse);
    expect(saved, [false]);
  });
}

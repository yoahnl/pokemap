import 'dart:async';

import 'package:avelune_studio/features/resources/application/model_definition_drafts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test(
    'requested shadows update before persistence and roll back on failure',
    () async {
      final pending = Completer<void>();
      final draft = ModelShadowDraft(
        spatialEnvironmentProject().models3d.single,
      );
      var calls = 0;
      Future<void> publish(bool _) {
        calls++;
        return pending.future;
      }

      final saving = draft.save(true, publish, canSave: () => true);
      expect(draft.value, isTrue);
      expect(draft.saving, isTrue);
      expect(await draft.save(false, publish, canSave: () => true), isFalse);
      expect(calls, 1);
      pending.completeError(StateError('Disque indisponible'));
      expect(await saving, isFalse);
      expect(draft.value, isFalse);
      expect(draft.saving, isFalse);
      expect(draft.error, contains('Disque indisponible'));
    },
  );

  for (final fails in [false, true]) {
    test(
      'obsolete shadow ${fails ? 'failure' : 'success'} cannot update another model',
      () async {
        final pending = Completer<void>();
        final original = spatialEnvironmentProject().models3d.single;
        final draft = ModelShadowDraft(original);
        final saving = draft.save(
          true,
          (_) => pending.future,
          canSave: () => true,
        );
        draft.update(
          ProjectModel3dEntry.fromJson({
            ...original.toJson(),
            'id': 'other',
            'relativePath': 'assets/models3d/other.glb',
          }),
        );
        if (fails) {
          pending.completeError(StateError('Ancienne écriture'));
        } else {
          pending.complete();
        }
        expect(await saving, isFalse);
        expect(draft.value, isFalse);
        expect(draft.saving, isFalse);
        expect(draft.error, isNull);
      },
    );
  }

  test('model shadow publication receives the selected default without changing the original resource', () async {
    final model = spatialEnvironmentProject().models3d.single;
    final draft = ModelShadowDraft(model);
    bool? saved;
    expect(
      await draft.save(true, (value) => saved = value, canSave: () => true),
      isTrue,
    );
    expect(saved, isTrue);
    expect(model.castsShadowsByDefault, isFalse);
  });

  test(
    'failed shadow save retains the old value and explains failure',
    () async {
      final draft = ModelShadowDraft(
        spatialEnvironmentProject().models3d.single,
      );
      expect(
        await draft.save(
          true,
          (_) async => throw StateError('Enregistrement refusé'),
          canSave: () => true,
        ),
        isFalse,
      );
      expect(draft.value, isFalse);
      expect(draft.error, contains('Enregistrement refusé'));
    },
  );

  test('resource shadows start disabled and save the selected default while respecting busy state', () async {
    var model = spatialEnvironmentProject().models3d.single;
    final draft = ModelShadowDraft(model);
    expect(draft.value, isFalse);
    final saved = <bool>[];
    expect(await draft.save(true, saved.add, canSave: () => true), isTrue);
    model = model.copyWith(castsShadowsByDefault: true);
    draft.update(model);
    expect(draft.value, isTrue);
    expect(await draft.save(false, saved.add, canSave: () => false), isFalse);
    expect(saved, [true]);
  });

  test('placed decor follows its resource until overridden and can reset', () {
    var model = spatialEnvironmentProject().models3d.single;
    var instance = SpatialModelInstance(
      id: 'house',
      modelId: model.id,
      position: Model3dVector3.zero,
    );
    expect(instance.effectiveCastsShadows(model), isFalse);
    model = model.copyWith(castsShadowsByDefault: true);
    expect(instance.effectiveCastsShadows(model), isTrue);
    instance = instance.copyWith(castsShadows: false);
    expect(instance.effectiveCastsShadows(model), isFalse);
    instance = instance.copyWith(clearCastsShadows: true);
    expect(instance.castsShadows, isNull);
    expect(instance.effectiveCastsShadows(model), isTrue);
  });
}

import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_terrain_lifecycle.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_replacement_fixture.dart';

Future<(ResourceReplacementFixture, TerrainDraftController)> _open({
  bool saved = true,
  bool published = false,
}) async {
  final host = await ResourceReplacementFixture.create();
  host.navigation.prepareTerrain(host.item);
  final model = host.navigation.terrain!;
  model.rename('Chemin du jardin');
  for (var i = 0; i < 16; i++) {
    model.selectedRule = i;
    model.assign(0, 0);
  }
  if (saved) {
    expect(
      await model.save(host.navigation.mutate, publish: published),
      isTrue,
    );
  }
  return (host, model);
}

Future<void> _manage(
  ResourceReplacementFixture host,
  TerrainDraftController model,
  TerrainResourceAction action,
  Future<void> Function(ResourceTerrainLifecycleController) present, {
  bool published = false,
  Future<bool> Function(TerrainManagementOwners)? confirmOwnerSave,
}) => runTerrainResourceManagement(
  navigation: host.navigation,
  action: action,
  name: model.draft.name,
  draftId: published ? null : model.draft.id,
  presetId: published ? model.draft.targetPresetId : null,
  isActive: () => true,
  confirmOwnerSave: confirmOwnerSave ?? (_) async => false,
  present: present,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renaming a terrain draft changes its name without publishing modified connections', () async {
    final (host, model) = await _open(published: true);
    model.selectedRule = 0;
    model.assign(1, 0);
    expect(await model.save(host.navigation.mutate), isTrue);
    final before = await host.reopen();
    final maps = await host.fixture.mapFile.readAsBytes();
    String? error;
    await _manage(host, model, TerrainResourceAction.rename, (
      controller,
    ) async {
      controller.name = 'Préparation renommée';
      error = await controller.apply();
    });
    final after = await host.reopen();
    expect(error, isNull);
    expect(after.smartTileCatalog.drafts.single.name, 'Préparation renommée');
    expect(
      after.smartTileCatalog.drafts.single.rules,
      before.smartTileCatalog.drafts.single.rules,
    );
    expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
    expect(after.tilesets, before.tilesets);
    expect(await host.fixture.mapFile.readAsBytes(), maps);
    expect(host.navigation.managementDialogActive, isFalse);
  });

  test('duplicating a published terrain resumes one independent unpublished preparation', () async {
    final (host, model) = await _open(published: true);
    final before = await host.reopen();
    String? error;
    await _manage(host, model, TerrainResourceAction.duplicate, (
      controller,
    ) async {
      controller.name = 'Chemin indépendant';
      error = await controller.apply();
    }, published: true);
    final after = await host.reopen();
    expect(error, isNull);
    expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
    final copy = after.smartTileCatalog.drafts.singleWhere(
      (entry) => entry.name == 'Chemin indépendant',
    );
    expect(copy.id, isNot(model.draft.id));
    expect(copy.targetPresetId, isNot(model.draft.targetPresetId));
    expect(host.navigation.terrain!.draft.id, copy.id);
    expect(after.tilesets, before.tilesets);
  });

  test('deleting a local-only terrain discards its own preparation without disk writes', () async {
    final (host, model) = await _open(saved: false);
    final before = await host.fixture.manifestFile.readAsBytes();
    String? error;
    bool? prepared;
    await _manage(host, model, TerrainResourceAction.deleteDraft, (
      controller,
    ) async {
      await controller.prepareRemoval();
      prepared = controller.ready && controller.preparation == null;
      controller.confirm(true);
      error = await controller.apply();
    });
    expect(prepared, isTrue);
    expect(error, isNull);
    expect(host.navigation.terrains.containsKey(model.draft.id), isFalse);
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test(
    'refusing to save an owning terrain preserves its current draft and disk',
    () async {
      final (host, model) = await _open();
      model.rename('Saisie conservée');
      final before = await host.fixture.manifestFile.readAsBytes();
      var presented = false;
      final owners = <String>[];
      await _manage(
        host,
        model,
        TerrainResourceAction.rename,
        (_) async {
          presented = true;
        },
        confirmOwnerSave: (session) async {
          owners.addAll(session.owners.map((owner) => owner.draft.id));
          return false;
        },
      );
      expect(presented, isFalse);
      expect(owners, [model.draft.id]);
      expect(model.draft.name, 'Saisie conservée');
      expect(model.dirty, isTrue);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test('owner consent saves connections as a draft before renaming the published terrain', () async {
    final (host, model) = await _open(published: true);
    model.selectedRule = 0;
    model.assign(1, 0);
    final originalPreset =
        (await host.reopen()).smartTileCatalog.presets.single;
    final results = <String?>[];
    await _manage(
      host,
      model,
      TerrainResourceAction.rename,
      (controller) async {
        controller.name = 'Chemin renommé';
        results.add(await controller.apply());
      },
      published: true,
      confirmOwnerSave: (session) async {
        final error = await session.save();
        results.add(error);
        return error == null;
      },
    );
    final after = await host.reopen();
    expect(results, [null, null]);
    expect(after.smartTileCatalog.presets.single.name, 'Chemin renommé');
    expect(
      after.smartTileCatalog.presets.single.copyWith(name: originalPreset.name),
      originalPreset,
    );
    expect(after.smartTileCatalog.drafts.single.rules, model.draft.rules);
  });

  test(
    'a replaced terrain owner cannot be saved through an older consent',
    () async {
      final (host, model) = await _open();
      model.rename('Saisie ancienne');
      final session = TerrainManagementOwners(host.navigation, {
        'draftId': model.draft.id,
      });
      host.navigation.terrains.remove(model.draft.id);
      final before = await host.fixture.manifestFile.readAsBytes();
      expect(await session.save(), contains('ont changé'));
      expect(model.dirty, isTrue);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test(
    'closing terrain removal releases its retained canonical preparation',
    () async {
      final (host, model) = await _open();
      late ResourceMutationPreparation preparation;
      await _manage(host, model, TerrainResourceAction.deleteDraft, (
        controller,
      ) async {
        await controller.prepareRemoval();
        preparation = controller.preparation!;
      });
      await expectLater(
        host.navigation.applyPrepared(preparation, confirmDestructive: true),
        throwsA(isA<ResourceFailure>()),
      );
      expect((await host.reopen()).smartTileCatalog.drafts, hasLength(1));
      expect(host.navigation.managementDialogActive, isFalse);
    },
  );
}

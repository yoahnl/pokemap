import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/terrain_lifecycle_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unchanged normalized name performs no write', () async {
    final host = await openTerrainLifecycle();
    final preset = host.workspace.project!.smartTileCatalog.presets.single;
    final bytes = await host.fixture.manifestFile.readAsBytes();
    String? error;
    await manageTerrainLifecycle(host, TerrainResourceAction.rename, (
      controller,
    ) async {
      controller.name = '  ${preset.name}  ';
      error = await controller.apply();
    }, presetId: preset.id);
    expect(error, isNull);
    expect(await host.fixture.manifestFile.readAsBytes(), bytes);
    expect(host.navigation.pendingReceipt, isNull);
  });

  test('rename conflict keeps input and newer saved metadata', () async {
    final host = await openTerrainLifecycle();
    final preset = host.workspace.project!.smartTileCatalog.presets.single;
    String? error, input;
    await manageTerrainLifecycle(host, TerrainResourceAction.rename, (
      controller,
    ) async {
      controller.name = 'Ma saisie préservée';
      await host.fixture.resources.mutate('smart_tile.preset.rename', {
        'presetId': preset.id,
        'name': 'Version concurrente',
      });
      error = await controller.apply();
      input = controller.name;
    }, presetId: preset.id);
    expect(error, isNotNull);
    expect(input, 'Ma saisie préservée');
    final current = await LocalMapWorkspaceAdapter().loadProject(
      host.fixture.session,
    );
    expect(current.smartTileCatalog.presets.single.name, 'Version concurrente');
  });

  test(
    'dirty preparation copy requires explicit save without publication',
    () async {
      final host = await openTerrainLifecycle(savedDraft: true);
      final before = host.workspace.project!;
      final original = before.smartTileCatalog.drafts.single;
      host.navigation.resumeTerrain(original);
      host.navigation.terrain!.rename('Préparation locale');
      var presented = false;
      await manageTerrainLifecycle(host, TerrainResourceAction.duplicate, (
        _,
      ) async {
        presented = true;
      }, draftId: original.id);
      expect(presented, isFalse);
      expect(host.navigation.terrain!.draft.name, 'Préparation locale');
      expect(
        (await LocalMapWorkspaceAdapter().loadProject(host.fixture.session))
            .smartTileCatalog,
        before.smartTileCatalog,
      );
      final errors = <String?>[];
      await manageTerrainLifecycle(
        host,
        TerrainResourceAction.duplicate,
        (controller) async {
          errors.add(await controller.apply());
        },
        draftId: original.id,
        confirmOwnerSave: (session) async {
          final error = await session.save();
          errors.add(error);
          return error == null;
        },
      );
      final after = await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      );
      expect(errors, [null, null]);
      expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
      expect(
        after.smartTileCatalog.drafts.where(
          (draft) => draft.name == 'Préparation locale — copie',
        ),
        hasLength(1),
      );
      expect(
        after.smartTileCatalog.drafts
            .singleWhere((draft) => draft.id == original.id)
            .name,
        'Préparation locale',
      );
    },
  );

  test(
    'advanced path metadata stays editable without converting rules',
    () async {
      final host = await openTerrainLifecycle(advanced: true);
      final before = host.workspace.project!;
      String? error;
      await manageTerrainLifecycle(host, TerrainResourceAction.rename, (
        controller,
      ) async {
        controller.name = 'Terrain avancé renommé';
        error = await controller.apply();
      }, presetId: before.smartTileCatalog.presets.single.id);
      final after = await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      );
      expect(error, isNull);
      expect(
        after.smartTileCatalog.presets.single.name,
        'Terrain avancé renommé',
      );
      expect(
        after.smartTileCatalog.presets.single.rules,
        before.smartTileCatalog.presets.single.rules,
      );
      expect(host.navigation.terrain, isNull);
    },
  );

  test('local-only preparation withdrawal writes nothing', () async {
    final host = await openTerrainLifecycle();
    final before = host.workspace.project!;
    final preset = before.smartTileCatalog.presets.single;
    host.navigation.prepareTerrain(
      ResourceItem(
        id: preset.id,
        name: preset.name,
        kind: ResourceKind.terrains,
        terrain: preset,
      ),
    );
    final model = host.navigation.terrain!;
    model.rename('Brouillon uniquement local');
    String? error;
    await manageTerrainLifecycle(host, TerrainResourceAction.deleteDraft, (
      controller,
    ) async {
      await controller.prepareRemoval();
      controller.confirm(true);
      error = await controller.apply();
    }, draftId: model.draft.id);
    expect(error, isNull);
    expect(host.navigation.terrains, isEmpty);
    expect(
      (await LocalMapWorkspaceAdapter().loadProject(host.fixture.session))
          .smartTileCatalog,
      before.smartTileCatalog,
    );
  });
}

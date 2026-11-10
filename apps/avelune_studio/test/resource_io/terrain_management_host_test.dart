import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/terrain_lifecycle_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'published path rename persists without publishing draft rules',
    () async {
      final host = await openTerrainLifecycle(savedDraft: true);
      final before = host.workspace.project!;
      final preset = before.smartTileCatalog.presets.single;
      String? error;
      await manageTerrainLifecycle(host, TerrainResourceAction.rename, (
        controller,
      ) async {
        controller.name = 'Sentier des étoiles';
        error = await controller.apply();
      }, presetId: preset.id);
      final after = await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      );
      expect(error, isNull);
      expect(after.smartTileCatalog.presets.single.name, 'Sentier des étoiles');
      expect(after.smartTileCatalog.presets.single.rules, preset.rules);
      expect(after.smartTileCatalog.drafts.single.name, 'Sentier des étoiles');
      expect(
        after.smartTileCatalog.drafts.single.rules,
        before.smartTileCatalog.drafts.single.rules,
      );
      expect(after.tilesets, before.tilesets);
      host.navigation.resumeTerrain(after.smartTileCatalog.drafts.single);
      expect(
        await host.navigation.terrain!.save(
          host.navigation.mutate,
          publish: true,
        ),
        isTrue,
      );
      final republished = await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      );
      expect(
        republished.smartTileCatalog.presets.single.name,
        'Sentier des étoiles',
      );
      expect(
        republished.smartTileCatalog.presets.single.rules,
        after.smartTileCatalog.drafts.single.rules,
      );
      expect(republished.smartTileCatalog.drafts, isEmpty);
    },
  );

  test(
    'published path duplicates into an independent saved preparation',
    () async {
      final host = await openTerrainLifecycle();
      final before = host.workspace.project!;
      final preset = before.smartTileCatalog.presets.single;
      String? error;
      await manageTerrainLifecycle(host, TerrainResourceAction.duplicate, (
        controller,
      ) async {
        controller.name = 'Chemin indépendant';
        error = await controller.apply();
      }, presetId: preset.id);
      final after = await LocalMapWorkspaceAdapter().loadProject(
        host.fixture.session,
      );
      expect(error, isNull);
      expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
      final draft = after.smartTileCatalog.drafts.single;
      expect(draft.name, 'Chemin indépendant');
      expect(draft.targetPresetId, isNot(preset.id));
      expect(draft.sourcePresetId, isNull);
      expect(terrainDraftCompatibilityProblem(after, draft), isNull);
      expect(host.navigation.terrain!.draft.id, draft.id);
    },
  );

  test('draft withdrawal preserves published terrain and source', () async {
    final host = await openTerrainLifecycle(savedDraft: true);
    final before = host.workspace.project!;
    String? error;
    await manageTerrainLifecycle(host, TerrainResourceAction.deleteDraft, (
      controller,
    ) async {
      await controller.prepareRemoval();
      controller.confirm(true);
      error = await controller.apply();
    }, draftId: before.smartTileCatalog.drafts.single.id);
    final after = await LocalMapWorkspaceAdapter().loadProject(
      host.fixture.session,
    );
    expect(error, isNull);
    expect(after.smartTileCatalog.drafts, isEmpty);
    expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
    expect(after.tilesets, before.tilesets);
  });

  test('painted path deletion is refused through real preparation', () async {
    final host = await openTerrainLifecycle(used: true);
    final before = host.workspace.project!;
    final bytes = await host.fixture.manifestFile.readAsBytes();
    String? error;
    bool? canApply;
    await manageTerrainLifecycle(host, TerrainResourceAction.deleteDraft, (
      controller,
    ) async {
      await controller.prepareRemoval();
      error = controller.error;
      controller.confirm(true);
      canApply = controller.canApply;
    }, presetId: before.smartTileCatalog.presets.single.id);
    expect(error, isNotNull);
    expect(canApply, isFalse);
    expect(await host.fixture.manifestFile.readAsBytes(), bytes);
  });
}

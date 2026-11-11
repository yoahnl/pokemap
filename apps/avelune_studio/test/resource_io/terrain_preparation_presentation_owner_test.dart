import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_management_copy.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_terrain_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_workspace_routing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../support/map_workspace_fixture.dart';
import 'resource_fixture.dart';

void main() {
  test('rename and duplicate dialogs describe a published terrain or a saved draft', () {
    expect(terrainManagementTitle(duplicate: true), 'Dupliquer le terrain ou chemin');
    expect(terrainManagementTitle(duplicate: false), 'Renommer le terrain ou chemin');
    expect(
      terrainManagementDescription(duplicate: false, draft: false, name: 'Herbe'),
      'Seul le nom de la publication et de ses préparations liées change. Aucun raccord modifié n’est publié.',
    );
    expect(
      terrainManagementDescription(duplicate: false, draft: true, name: 'Herbe'),
      'Seul le nom de ce brouillon change. Aucun raccord modifié n’est publié.',
    );
    final published = terrainManagementDescription(
      duplicate: true,
      draft: false,
      name: 'Herbe',
    );
    expect(published, startsWith('Version publiée : Herbe. '));
    expect(published, contains('sans publication'));
    expect(
      terrainManagementDescription(duplicate: true, draft: true, name: 'Herbe'),
      startsWith('Brouillon enregistré : Herbe. '),
    );
  });

  test('draft status line, usages routing and resumability follow the real saved preparation', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final pixels = image.Image(width: 64, height: 96);
    for (var y = 0; y < pixels.height; y++) {
      for (var x = 0; x < pixels.width; x++) {
        pixels.setPixelRgb(x, y, 30 + x, 200 - y, 60);
      }
    }
    await fixture.source.writeAsBytes(image.encodePng(pixels));
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: fixture.resources,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
    addTearDown(navigation.dispose);
    await navigation.accept(await fixture.import());
    final source = resourceCatalog(workspace.project!).single;
    navigation.prepareTerrain(source);
    final terrain = navigation.terrain!;
    terrain.assign(1, 2);
    terrain.rename('Premier terrain');
    expect(await navigation.saveDrafts(), isTrue);
    final draft = workspace.project!.smartTileCatalog.drafts.single;
    final assigned = draft.rules
        .where((rule) => rule.candidates.isNotEmpty)
        .length;
    expect(assigned, 1);

    expect(
      terrainDraftSubtitle(draft),
      'Brouillon enregistré · 1 / ${draft.rules.length} raccords',
    );
    expect(
      terrainDraftSubtitle(draft, status: 'Version publiée'),
      'Version publiée · 1 / ${draft.rules.length} raccords',
    );
    expect(
      terrainDraftSubtitle(draft, compatible: false),
      'Brouillon enregistré · 1 / ${draft.rules.length} raccords · Raccords avancés en lecture seule',
    );
    expect(terrainDraftResumable(workspace.project!, draft), isTrue);

    final opened = <ResourceItem>[];
    final managed = <(String, String)>[];
    Future<void> run(TerrainResourceAction action) =>
        runTerrainPreparationAction(
          navigation: navigation,
          draft: draft,
          action: action,
          openUsages: opened.add,
          manage: ({required name, required draftId}) async =>
              managed.add((name, draftId)),
        );

    await run(TerrainResourceAction.usages);
    expect(opened, isEmpty);
    expect(managed, isEmpty);
    expect(
      navigation.error,
      'La publication liée est absente. Cette préparation n’est pas un terrain placé sur une carte.',
    );

    await run(TerrainResourceAction.rename);
    await run(TerrainResourceAction.deleteDraft);
    expect(managed, [
      ('Premier terrain', draft.id),
      ('Premier terrain', draft.id),
    ]);
    expect(opened, isEmpty);

    for (var mask = 0; mask < 16; mask++) {
      terrain.selectedRule = mask;
      terrain.assign(mask % 4, mask ~/ 4);
    }
    expect(await terrain.save(navigation.mutate, publish: true), isTrue);
    final preset = workspace.project!.smartTileCatalog.presets.single;
    navigation.setImportError('');
    await run(TerrainResourceAction.usages);
    expect(opened, hasLength(1));
    expect(opened.single.terrain, preset);
    expect(opened.single.id, preset.id);
    expect(opened.single.kind, ResourceKind.terrains);
    expect(draft.targetPresetId, preset.id);
  });
}

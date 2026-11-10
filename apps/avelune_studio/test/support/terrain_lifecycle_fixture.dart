import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_terrain_lifecycle.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../resource_io/resource_fixture.dart';
import 'resource_replacement_fixture.dart';

Future<ResourceReplacementFixture> openTerrainLifecycle({
  bool published = true,
  bool savedDraft = false,
  bool used = false,
  bool advanced = false,
}) => ResourceReplacementFixture.create(
  configure: (fixture) => seedUwU5Terrain(
    fixture,
    published: published,
    savedDraft: savedDraft,
    used: used,
    advanced: advanced,
  ),
);

Future<void> manageTerrainLifecycle(
  ResourceReplacementFixture host,
  TerrainResourceAction action,
  Future<void> Function(ResourceTerrainLifecycleController) present, {
  String? presetId,
  String? draftId,
  Future<bool> Function(TerrainManagementOwners)? confirmOwnerSave,
}) {
  final catalog = host.workspace.project!.smartTileCatalog;
  final name = presetId != null
      ? catalog.presets.singleWhere((entry) => entry.id == presetId).name
      : host.navigation.terrains[draftId]?.draft.name ??
            catalog.drafts
                .where((entry) => entry.id == draftId)
                .firstOrNull
                ?.name ??
            '';
  return runTerrainResourceManagement(
    navigation: host.navigation,
    action: action,
    name: name,
    presetId: presetId,
    draftId: draftId,
    isActive: () => true,
    confirmOwnerSave: confirmOwnerSave ?? (_) async => false,
    present: present,
  );
}

Future<void> seedUwU5Terrain(
  ResourceFixture fixture, {
  required bool published,
  required bool savedDraft,
  required bool used,
  bool advanced = false,
}) async {
  final project = await fixture.maps.loadProject(fixture.session);
  final model = TerrainDraftController(
    manifest: project,
    atlas: terrainAtlas(project.tilesets.single, 'path-atlas'),
    id: 'path-draft',
    name: 'Chemin des essais',
  );
  for (var i = 0; i < 16; i++) {
    model.selectedRule = i;
    model.assign(0, 0);
  }
  if (advanced) {
    final rules = model.draft.rules.toList();
    final first = rules.first;
    rules[0] = first.copyWith(
      candidates: [first.candidates.single.copyWith(weight: 2)],
    );
    model.draft = model.draft.copyWith(rules: rules);
  }
  expect(
    await model.save(
      (action, parameters) async =>
          (await fixture.resources.mutate(action, parameters)).manifest,
      publish: published,
    ),
    isTrue,
    reason: model.error,
  );
  if (savedDraft && published) {
    model.selectedRule = 0;
    model.assign(1, 0);
    expect(
      await model.save(
        (action, parameters) async =>
            (await fixture.resources.mutate(action, parameters)).manifest,
      ),
      isTrue,
      reason: model.error,
    );
  }
  if (used) {
    final document = await fixture.loadMap();
    await fixture.maps.saveMap(
      fixture.session,
      document,
      document.map.copyWith(
        layers: [
          ...document.map.layers,
          SmartTileLayer(
            id: 'painted-path',
            name: 'Chemin peint',
            presetId: model.draft.targetPresetId,
            usage: SmartTileUsage.path,
            materialPalette: const ['', 'material-path-draft'],
            field: SmartTileField.cell(
              semanticCells: [0, 0, 0, 0, 0, 1, ...List.filled(10, 0)],
            ),
          ),
        ],
      ),
    );
  }
}

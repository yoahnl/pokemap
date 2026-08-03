import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_connection_profile.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';

void main() {
  test('keeps allowed, default, and active material responsibilities distinct',
      () {
    final controller = _configuredController();
    const grass = ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Herbe',
      connectionGroupId: 'ground',
    );
    const dirt = ProjectSmartTileMaterial(
      id: 'dirt',
      name: 'Terre',
      connectionGroupId: 'path',
    );

    controller.addMaterial(grass);
    expect(controller.state.defaultMaterialId, 'grass');
    expect(controller.state.activeMaterialId, 'grass');

    controller.addMaterial(dirt);
    expect(controller.state.materials, <ProjectSmartTileMaterial>[grass, dirt]);
    expect(controller.state.defaultMaterialId, 'grass');
    expect(controller.state.activeMaterialId, 'dirt');

    controller.setDefaultMaterial('dirt');
    controller.setActiveMaterial('grass');
    final draft = controller.compileAuthoringDraft(
      lastStage: SmartTileAuthoringStage.materials,
    );
    expect(draft.materials, <ProjectSmartTileMaterial>[grass, dirt]);
    expect(draft.allowedMaterialIds, <String>['grass', 'dirt']);
    expect(draft.defaultMaterialId, 'dirt');
    expect(controller.state.activeMaterialId, 'grass');
  });

  test('creates stable hidden IDs and resolves name collisions', () {
    final controller = _configuredController();

    final first = controller.createMaterial(name: 'Herbe fraîche');
    final second = controller.createMaterial(name: 'Herbe fraîche');

    expect(first.id, 'smart-tile-material-herbe-fraiche');
    expect(second.id, 'smart-tile-material-herbe-fraiche-2');
    expect(first.connectionGroupId, first.id);
    expect(controller.state.activeMaterialId, second.id);
  });

  test('blocks removing a default or active material', () {
    final controller = _configuredController()
      ..addMaterial(
        const ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'ground',
        ),
      )
      ..addMaterial(
        const ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Terre',
          connectionGroupId: 'path',
        ),
      );

    expect(
      controller.materialRemovalBlocker('grass'),
      SmartTileMaterialRemovalBlocker.defaultMaterial,
    );
    expect(
      controller.materialRemovalBlocker('dirt'),
      SmartTileMaterialRemovalBlocker.activeMaterial,
    );
    expect(
      () => controller.removeMaterial('dirt'),
      throwsA(isA<SmartTileMaterialInUseException>()),
    );
  });

  test('blocks removing a non-active material referenced by a rule', () {
    const grass = ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Herbe',
      connectionGroupId: 'ground',
    );
    const dirt = ProjectSmartTileMaterial(
      id: 'dirt',
      name: 'Terre',
      connectionGroupId: 'path',
    );
    const draft = ProjectSmartTileAuthoringDraft(
      id: 'draft-terrain',
      targetPresetId: 'terrain',
      name: 'Terrain',
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.materials,
      materials: <ProjectSmartTileMaterial>[grass, dirt],
      defaultMaterialId: 'dirt',
      allowedMaterialIds: <String>['grass', 'dirt'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'grass-rule',
          centerMatch: SmartTileSlotMatch.material('grass'),
        ),
      ],
    );
    final controller = SmartTileAuthoringController.fromCanonicalDraft(draft);

    expect(
      controller.materialRemovalBlocker('grass'),
      SmartTileMaterialRemovalBlocker.mappedMaterial,
    );
    expect(
      () => controller.removeMaterial('grass'),
      throwsA(isA<SmartTileMaterialInUseException>()),
    );
  });

  test('hydrates catalog materials referenced by a reopened draft', () {
    const grass = ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Herbe du projet',
      connectionGroupId: 'ground',
    );
    const draft = ProjectSmartTileAuthoringDraft(
      id: 'draft-terrain',
      targetPresetId: 'terrain',
      name: 'Terrain',
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.materials,
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
    );

    final controller = SmartTileAuthoringController.fromCanonicalDraft(
      draft,
      catalogMaterials: const <ProjectSmartTileMaterial>[grass],
    );

    expect(controller.state.materials, <ProjectSmartTileMaterial>[grass]);
    expect(controller.state.defaultMaterialId, 'grass');
    expect(controller.state.activeMaterialId, 'grass');
  });

  test('changes profile only after caller decides whether mappings are reset',
      () {
    final controller = _configuredController()
      ..addMaterial(
        const ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'ground',
        ),
      )
      ..addAtlasVariant(
        mask: 0,
        column: 0,
        row: 0,
        candidateId: 'frame',
      );
    final borders = smartTileConnectionProfileById(
      SmartTileConnectionProfileId.borders,
    ).resolve();

    expect(
      () => controller.configureConnections(
        borders,
        clearMappings: false,
      ),
      throwsStateError,
    );
    expect(controller.state.mappings, isNotEmpty);

    controller.configureConnections(borders, clearMappings: true);
    expect(controller.state.topology, SmartTileTopology.wangEdge4);
    expect(controller.state.templateHint, SmartTileTemplateHint.edge16);
    expect(controller.state.mappings, isEmpty);
  });
}

SmartTileAuthoringController _configuredController() {
  final controller = SmartTileAuthoringController.blank();
  controller
    ..configureIdentity(id: 'smart-tile', name: 'Smart Tile')
    ..selectUsage(SmartTileUsage.terrain)
    ..configureAtlas(
      atlasId: 'atlas',
      atlasName: 'Atlas',
      tilesetId: 'tileset',
      geometry: const SmartTileGridGeometry(
        imageWidth: 64,
        imageHeight: 64,
        cellWidth: 32,
        cellHeight: 32,
      ),
    );
  return controller;
}

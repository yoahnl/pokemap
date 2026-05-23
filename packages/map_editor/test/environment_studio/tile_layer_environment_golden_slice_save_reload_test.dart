import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tile_layer_environment_attachment_read_model_builder.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_clear_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/environment_generated_placement_add_element_provider.dart';
import 'package:map_editor/src/features/editor/state/environment_mask_brush_size_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/panels/layers_panel_presentation.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Environment-48 Golden Slice save/reload', () {
    test(
        'préserve environnement, placements, grouping et reste clearable après reload',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('env48_save_reload_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final manifest = _manifest();
      final initialMap = _map();
      final manifestPath = p.join(tempDir.path, 'project.json');
      final mapPath = p.join(tempDir.path, 'maps', 'golden.json');
      await FileProjectRepository().saveProject(manifest, manifestPath);
      await FileMapRepository().saveMap(
        initialMap,
        mapPath,
        projectDialogueContext: manifest,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      await notifier.loadProject(manifestPath, rememberAsRecent: false);
      await notifier.loadMap('maps/golden.json');
      notifier.state = notifier.state.copyWith(
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(
        notifier.deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(
          const GridPos(x: 3, y: 2),
        ),
        isTrue,
      );

      notifier.selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
        'bush',
      );
      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedAdd);
      expect(
        notifier.addGeneratedEnvironmentPlacementAtForActiveTileLayer(
          const GridPos(x: 4, y: 0),
        ),
        isTrue,
      );
      container.read(environmentMaskBrushSizeProvider.notifier).state = 7;
      notifier.state = notifier.state.copyWith(
        hoveredTile: const GridPos(x: 1, y: 1),
      );

      await notifier.saveActiveMap();
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isDirty, isFalse);

      final savedMapJson = await File(mapPath).readAsString();
      expect(savedMapJson, isNot(contains('generatedAdd')));
      expect(savedMapJson, isNot(contains('hoveredTile')));
      expect(savedMapJson, isNot(contains('environmentMaskEditMode')));

      final reloadedContainer = ProviderContainer();
      addTearDown(reloadedContainer.dispose);
      final reloadedNotifier =
          reloadedContainer.read(editorNotifierProvider.notifier);
      await reloadedNotifier.loadProject(
        manifestPath,
        rememberAsRecent: false,
      );
      await reloadedNotifier.loadMap('maps/golden.json');

      final reloadedState = reloadedNotifier.state;
      final reloadedMap = reloadedState.activeMap!;
      final reloadedArea = _areaById(reloadedMap, 'area');
      final placedIds =
          reloadedMap.placedElements.map((placed) => placed.id).toSet();

      expect(reloadedState.activeLayerId, 'tiles');
      expect(reloadedState.selectedEnvironmentAreaId, isNull);
      expect(reloadedState.environmentMaskEditMode, isNull);
      expect(reloadedState.hoveredTile, isNull);
      expect(
        reloadedContainer.read(environmentGeneratedPlacementAddElementProvider),
        isNull,
      );
      expect(
        reloadedContainer.read(environmentMaskBrushSizeProvider),
        kDefaultEnvironmentMaskBrushSize,
      );

      expect(_tileLayer(reloadedMap).tiles, _tileLayer(initialMap).tiles);
      expect(_environmentLayer(reloadedMap).content.targetTileLayerId, 'tiles');
      expect(reloadedArea.mask, _areaById(initialMap, 'area').mask);
      expect(reloadedArea.seed, 17);
      expect(reloadedArea.paramsOverride, _params);
      expect(reloadedArea.presetId, 'forest');
      expect(reloadedArea.generatedPlacementIds, const [
        'generated_keep',
        'env_gen_area_4_0_bush',
      ]);
      expect(reloadedArea.generatedPlacementIds.toSet().length,
          reloadedArea.generatedPlacementIds.length);
      for (final id in reloadedArea.generatedPlacementIds) {
        expect(placedIds, contains(id));
      }

      expect(placedIds, contains('manual_tree'));
      expect(placedIds, contains('generated_keep'));
      expect(placedIds, contains('env_gen_area_4_0_bush'));
      expect(placedIds, contains('other_generated'));
      expect(placedIds, isNot(contains('generated_delete')));
      expect(
          reloadedArea.generatedPlacementIds, isNot(contains('manual_tree')));
      final added = reloadedMap.placedElements.singleWhere(
        (placed) => placed.id == 'env_gen_area_4_0_bush',
      );
      expect(added.layerId, 'tiles');
      expect(added.elementId, 'bush');
      expect(added.pos, const GridPos(x: 4, y: 0));
      final manual = reloadedMap.placedElements.singleWhere(
        (placed) => placed.id == 'manual_tree',
      );
      expect(manual.layerId, 'tiles');
      expect(manual.elementId, 'tree');
      expect(manual.pos, const GridPos(x: 0, y: 0));
      expect(_areaById(reloadedMap, 'other').generatedPlacementIds,
          const ['other_generated']);

      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: reloadedState.project,
        map: reloadedMap,
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        selectedGeneratedPlacementElementId: 'bush',
      );
      expect(model.hasAttachment, isTrue);
      expect(model.activeTileLayerId, 'tiles');
      expect(model.attachedEnvironmentLayerId, 'env');
      expect(model.hasMask, isTrue);
      expect(model.maskActiveCellCount, greaterThan(0));
      expect(model.generatedPlacementCount, 2);
      expect(model.existingGeneratedPlacementCount, 2);
      expect(model.missingGeneratedPlacementCount, 0);
      expect(model.selectedAreaHasParamsOverride, isTrue);
      expect(model.selectedAreaSeed, 17);
      expect(model.canClearGeneratedPlacements, isTrue);
      expect(model.canRegenerate, isTrue);
      expect(model.canShuffle, isTrue);
      expect(model.canAddGeneratedPlacement, isTrue);

      final rows = buildLayerPanelPresentationRows(
        reloadedMap,
        activeLayerId: 'env',
      );
      expect(rows.map((row) => row.layer.id), const ['tiles', 'objects']);
      final tileRow = rows.singleWhere((row) => row.layer.id == 'tiles');
      expect(tileRow.environmentAttachmentLabel, 'Environnement actif');
      expect(tileRow.attachedEnvironmentLayerIds, const ['env']);
      expect(tileRow.isActive, isTrue);
      expect(tileRow.isTechnicalEnvironmentSelection, isTrue);

      final clear =
          ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
        reloadedMap,
        tileLayerId: 'tiles',
        areaId: 'area',
      );
      expect(clear.removedPlacementIds,
          unorderedEquals(['generated_keep', 'env_gen_area_4_0_bush']));
      expect(_areaById(clear.map, 'area').generatedPlacementIds, isEmpty);
      expect(clear.map.placedElements.map((placed) => placed.id),
          contains('manual_tree'));
      expect(clear.map.placedElements.map((placed) => placed.id),
          contains('other_generated'));
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 0.62,
  variation: 0.18,
  edgeDensity: 0.74,
  minSpacingCells: 1,
);

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Environment 48',
    maps: const [
      ProjectMapEntry(
        id: 'golden',
        name: 'Golden',
        relativePath: 'maps/golden.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'nature',
        name: 'Nature',
        relativePath: 'tilesets/nature.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'nature', name: 'Nature'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      ProjectElementEntry(
        id: 'bush',
        name: 'Bush',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
        ],
      ),
      ProjectElementEntry(
        id: 'big_tree',
        name: 'Big Tree',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 1, width: 2, height: 2),
          ),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(elementId: 'bush', weight: 1),
          EnvironmentPaletteItem(elementId: 'big_tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
}

MapData _map() {
  return MapData(
    id: 'golden',
    name: 'Golden',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Décor',
        tilesetId: 'nature',
        tiles: [
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment — Décor',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Forêt',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: [
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                ],
              ),
              seed: 17,
              paramsOverride: _params,
              generatedPlacementIds: const [
                'generated_keep',
                'generated_delete',
              ],
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Bosquet',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
              ),
              seed: 9,
              generatedPlacementIds: const ['other_generated'],
            ),
          ],
        ),
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual_tree',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'generated_keep',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 3),
      ),
      MapPlacedElement(
        id: 'generated_delete',
        layerId: 'tiles',
        elementId: 'big_tree',
        pos: GridPos(x: 2, y: 1),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 4, y: 4),
      ),
    ],
  );
}

TileLayer _tileLayer(MapData map) {
  return map.layers.whereType<TileLayer>().single;
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return _environmentLayer(map)
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
}

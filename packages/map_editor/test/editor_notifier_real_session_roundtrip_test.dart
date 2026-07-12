import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test('real editor session preserves every placement while editing water',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_origin_session_',
    );
    addTearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    final manifest = _manifest();
    final original = _map();
    final manifestPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'session.json');
    final projectRepository = FileProjectRepository();
    final mapRepository = FileMapRepository();
    await projectRepository.saveProject(manifest, manifestPath);
    await mapRepository.saveMap(
      original,
      mapPath,
      projectDialogueContext: manifest,
    );
    final beforeJson =
        jsonDecode(await File(mapPath).readAsString()) as Map<String, dynamic>;

    final firstContainer = ProviderContainer();
    final firstNotifier = firstContainer.read(editorNotifierProvider.notifier);
    firstNotifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
    );
    await firstNotifier.loadMap('maps/session.json');
    firstNotifier.setPathLayerAnimationMode(
      layerId: 'water',
      mode: PathAnimationMode.alwaysActive,
    );
    await firstNotifier.saveActiveMap();
    expect(firstNotifier.state.errorMessage, isNull);
    expect(firstNotifier.state.isDirty, isFalse);
    firstContainer.dispose();

    final afterJson =
        jsonDecode(await File(mapPath).readAsString()) as Map<String, dynamic>;
    expect(afterJson['placedElements'], beforeJson['placedElements']);

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final secondNotifier =
        secondContainer.read(editorNotifierProvider.notifier);
    secondNotifier.state = EditorState(
      projectRootPath: root.path,
      project: await projectRepository.loadProject(manifestPath),
    );
    await secondNotifier.loadMap('maps/session.json');

    final reloaded = secondNotifier.state.activeMap!;
    expect(reloaded.placedElements, original.placedElements);
    expect(
      reloaded,
      original.copyWith(
        layers: [
          for (final layer in original.layers)
            if (layer is PathLayer && layer.id == 'water')
              layer.copyWith(animationMode: PathAnimationMode.alwaysActive)
            else
              layer,
        ],
      ),
    );
    expect(secondNotifier.state.savedMapSnapshot, reloaded);
    expect(secondNotifier.state.isDirty, isFalse);
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Origin session',
      maps: const [
        ProjectMapEntry(
          id: 'session',
          name: 'Session',
          relativePath: 'maps/session.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'nature',
          name: 'Nature',
          relativePath: 'tilesets/nature.png',
        ),
      ],
      pathPresets: const [
        ProjectPathPreset(
          id: 'water',
          name: 'Water',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'nature',
        ),
      ],
      environmentPresets: [
        EnvironmentPreset(
          id: 'forest',
          name: 'Forest',
          templateId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          ],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0,
        ),
      ],
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      elementCategories: const [
        ProjectElementCategory(id: 'nature', name: 'Nature'),
        ProjectElementCategory(id: 'building', name: 'Building'),
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
          id: 'house',
          name: 'House',
          tilesetId: 'nature',
          categoryId: 'building',
          frames: [
            TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
          ],
        ),
      ],
    );

MapData _map() => MapData(
      id: 'session',
      name: 'Session',
      size: const GridSize(width: 3, height: 1),
      layers: <MapLayer>[
        const PathLayer(
          id: 'water',
          name: 'Water',
          presetId: 'water',
          cells: [true, true, true],
        ),
        const TileLayer(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'nature',
          tiles: [1, 0, 1],
        ),
        EnvironmentLayer(
          id: 'environment',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: [
              EnvironmentArea(
                id: 'forest',
                name: 'Forest',
                presetId: 'forest',
                seed: 1,
                mask: EnvironmentAreaMask(
                  width: 3,
                  height: 1,
                  cells: const [false, false, true],
                ),
                generatedPlacementIds: const ['environment_tree'],
              ),
            ],
          ),
        ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'authored_house',
          layerId: 'decor',
          elementId: 'house',
          pos: GridPos(x: 1, y: 0),
          properties: {
            'pokemapPlacementOrigin': 'authored',
            'designerNote': 'keep',
          },
        ),
        MapPlacedElement(
          id: 'tile_tree',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
          properties: {
            'pokemapPlacementOrigin': 'tile_index',
            'indexedNote': 'keep',
          },
        ),
        MapPlacedElement(
          id: 'environment_tree',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 0),
          properties: {
            'pokemapPlacementOrigin': 'environment',
            'seed': '1',
          },
        ),
      ],
    );

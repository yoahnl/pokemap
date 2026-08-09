import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test(
    'project element brush routes one pointer-down to semantic placement',
    () async {
      final seeded = _RoutingEditorNotifier(_state());
      final container = ProviderContainer(
        overrides: <Override>[
          editorNotifierProvider.overrideWith(() => seeded),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final beforeCells = (notifier.state.activeMap!.layers.single as TileLayer)
          .cells
          .toList(growable: false);

      await notifier.paintSelectedBrushAt(
        const GridPos(x: 3, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
      );
      await notifier.paintSelectedBrushAt(
        const GridPos(x: 4, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
        partOfStroke: true,
      );

      expect(seeded.semanticPlacements, const <GridPos>[GridPos(x: 3, y: 2)]);
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).cells,
        beforeCells,
      );
    },
  );

  test(
    'project element preview exposes the footprint and rejects overflow',
    () async {
      final seeded = _RoutingEditorNotifier(_state());
      final container = ProviderContainer(
        overrides: <Override>[
          editorNotifierProvider.overrideWith(() => seeded),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);

      final valid = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 3, y: 2),
        tilesetColumnsById: const <String, int>{'village': 64},
      );
      final invalid = notifier.resolveMapToolPreview(
        hoveredTile: const GridPos(x: 10, y: 8),
        tilesetColumnsById: const <String, int>{'village': 64},
      );

      expect(valid?.mode, MapToolPreviewMode.elementPlacement);
      expect(valid?.size, const GridSize(width: 8, height: 7));
      expect(valid?.elementId, 'guesthouse');
      expect(valid?.validity, MapToolPreviewValidity.valid);
      expect(invalid?.mode, MapToolPreviewMode.elementPlacement);
      expect(invalid?.validity, MapToolPreviewValidity.invalid);
      expect(invalid?.reason, isNotEmpty);

      await notifier.paintSelectedBrushAt(
        const GridPos(x: 10, y: 8),
        tilesetColumnsById: const <String, int>{'village': 64},
      );

      expect(seeded.semanticPlacements, isEmpty);
      expect(notifier.state.errorMessage, contains('dépasse'));
    },
  );

  test(
    'canonical placement selects the instance and keeps properties editable',
    () async {
      final fixture = await _CanonicalPlacementFixture.create();
      addTearDown(fixture.dispose);

      await fixture.notifier.placeSelectedProjectElementAt(
        const GridPos(x: 3, y: 2),
      );

      final placed = fixture.notifier.state.activeMap!.placedElements.single;
      expect(placed.id, 'objects::3::2');
      expect(fixture.notifier.state.selectedPlacedElementInstanceId, placed.id);
      expect(fixture.notifier.state.canUndoMap, isTrue);
      expect(fixture.notifier.state.isDirty, isFalse);
      expect(
        (fixture.notifier.state.activeMap!.layers.single as TileLayer).cells,
        everyElement(0),
      );

      fixture.notifier.setPlacedElementInstanceOpacity(
        instanceId: placed.id,
        opacity: 0.45,
      );

      expect(
        fixture.notifier.state.activeMap!.placedElements.single.opacity,
        0.45,
      );
      expect(fixture.notifier.state.selectedPlacedElementInstanceId, placed.id);
    },
  );

  test('canonical placement participates in map undo and redo', () async {
    final fixture = await _CanonicalPlacementFixture.create();
    addTearDown(fixture.dispose);
    await fixture.notifier.placeSelectedProjectElementAt(
      const GridPos(x: 3, y: 2),
    );

    fixture.notifier.undoMap();
    await _waitFor(
      () => fixture.notifier.state.activeMap!.placedElements.isEmpty,
    );

    expect(fixture.notifier.state.canRedoMap, isTrue);
    expect(fixture.notifier.state.selectedPlacedElementInstanceId, isNull);

    fixture.notifier.redoMap();
    await _waitFor(
      () => fixture.notifier.state.activeMap!.placedElements.length == 1,
    );

    expect(
      fixture.notifier.state.selectedPlacedElementInstanceId,
      'objects::3::2',
    );
    expect(fixture.notifier.state.canUndoMap, isTrue);
  });
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for canonical editor state.');
}

final class _CanonicalPlacementFixture {
  _CanonicalPlacementFixture._({
    required this.root,
    required this.container,
    required this.notifier,
  });

  final Directory root;
  final ProviderContainer container;
  final EditorNotifier notifier;

  static Future<_CanonicalPlacementFixture> create() async {
    final root = await Directory.systemTemp.createTemp('element-placement-');
    final manifest = _projectWithMap();
    final map = _mapForCanonicalPlacement();
    await Directory('${root.path}/maps').create();
    await File(
      '${root.path}/project.json',
    ).writeAsString(jsonEncode(manifest.toJson()), flush: true);
    final mapPath = '${root.path}/maps/map.json';
    await File(mapPath).writeAsString(jsonEncode(map.toJson()), flush: true);
    final seeded = _SeededEditorNotifier(
      _state().copyWith(
        projectRootPath: root.path,
        project: manifest,
        activeMap: map,
        activeMapPath: mapPath,
        savedMapSnapshot: map,
      ),
    );
    final container = ProviderContainer(
      overrides: <Override>[editorNotifierProvider.overrideWith(() => seeded)],
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    return _CanonicalPlacementFixture._(
      root: root,
      container: container,
      notifier: notifier,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _SeededEditorNotifier extends EditorNotifier {
  _SeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() => initialState;
}

ProjectManifest _projectWithMap() => const ProjectManifest(
  name: 'Placement project',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'tilesets/village.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'tilesets/village.png',
        pixelWidth: 2048,
        pixelHeight: 1024,
        tileWidth: 32,
        tileHeight: 32,
      ),
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'guesthouse',
      name: 'Guesthouse',
      tilesetId: 'village',
      categoryId: 'building',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 1, width: 8, height: 7),
        ),
      ],
    ),
  ],
);

MapData _mapForCanonicalPlacement() => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 16, height: 12),
  layers: <MapLayer>[
    MapLayer.tile(
      id: 'objects',
      name: 'Objects',
      cells: List<int>.filled(16 * 12, 0),
    ),
  ],
);

final class _RoutingEditorNotifier extends EditorNotifier {
  _RoutingEditorNotifier(this.initialState);

  final EditorState initialState;
  final List<GridPos> semanticPlacements = <GridPos>[];

  @override
  EditorState build() => initialState;

  @override
  Future<void> placeSelectedProjectElementAt(GridPos pos) async {
    semanticPlacements.add(pos);
  }
}

EditorState _state() => EditorState(
  project: const ProjectManifest(
    name: 'Placement project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'village',
        name: 'Village',
        relativePath: 'tilesets/village.png',
      ),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'guesthouse',
        name: 'Guesthouse',
        tilesetId: 'village',
        categoryId: 'building',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 1, width: 8, height: 7),
          ),
        ],
      ),
    ],
  ),
  activeMap: MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 16, height: 12),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'objects',
        name: 'Objects',
        cells: List<int>.filled(16 * 12, 0),
      ),
    ],
  ),
  activeLayerId: 'objects',
  activeTool: EditorToolType.tilePaint,
  activeBrush: const EditorBrush.projectElement(elementId: 'guesthouse'),
);

import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final bottomToTop in [false, true]) {
    test(
      'selected 3D preset erases its layer behind soil with ${bottomToTop ? "back-first" : "front-first"} layers',
      () {
        final fixture = _selectedPresetEraseFixture(bottomToTop: bottomToTop);
        final source = fixture.map;
        final before = jsonEncode(source.toJson());
        final grass = source.layers.whereType<SmartTileLayer>().firstWhere(
          (layer) => layer.presetId == fixture.preset.id,
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession()
          ..prepareTerrainPainting(fixture.preset)
          ..tool = StudioMapTool.erase;
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 3, y: 2),
        )!;
        expect(stroke.buffer.layerId, grass.id);
        expect(document.current, same(source));
        expect(document.undoCount, 0);
        final preview = stroke.preview.layers
            .whereType<SmartTileLayer>()
            .firstWhere((layer) => layer.id == grass.id);
        expect(
          smartTileMaterialIdAt(preview, mapSize: source.size, x: 3, y: 2),
          isNull,
        );
        expect(preview.patternStrokes.single.cells, [
          const GridPos(x: 2, y: 2),
          const GridPos(x: 4, y: 2),
          const GridPos(x: 5, y: 2),
        ]);
        expect(
          preview.patternStrokes.single.phaseX,
          grass.patternStrokes.single.phaseX,
        );
        expect(
          preview.patternStrokes.single.phaseY,
          grass.patternStrokes.single.phaseY,
        );
        for (final layer in source.layers.where(
          (layer) => layer.id != grass.id,
        )) {
          expect(
            stroke.preview.layers.firstWhere((entry) => entry.id == layer.id),
            layer,
          );
        }
        expect(stroke.preview.spatialScene, source.spatialScene);
        final committed = stroke.commit();
        expect(committed, stroke.preview);
        document.commit(committed);
        expect(document.undoCount, 1);
        document.restore(redo: false);
        expect(jsonEncode(document.current.toJson()), before);
        document.restore(redo: true);
        expect(document.current, committed);
      },
    );
    for (final selectedLayerPresent in [false, true]) {
      test(
        'selected 3D preset refuses foreign soil when ${selectedLayerPresent ? "its cell is empty" : "its layer is absent"} with ${bottomToTop ? "back-first" : "front-first"} layers',
        () {
          final fixture = _selectedPresetEraseFixture(
            bottomToTop: bottomToTop,
            selectedLayerPresent: selectedLayerPresent,
            selectedCellOwned: false,
          );
          final source = fixture.map;
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapEditingViewportSession()
            ..prepareTerrainPainting(fixture.preset)
            ..tool = StudioMapTool.erase;
          addTearDown(view.dispose);
          expect(
            MapCanvasStroke.start(
              map: source,
              project: fixture.project,
              view: view,
              commands: MapEditingCommands(document, fixture.project),
              origin: const GridPos(x: 3, y: 2),
            ),
            isNull,
          );
          expect(document.current, same(source));
          expect(document.undoCount, 0);
        },
      );
    }
  }

  for (final spatial in [false, true]) {
    test(
      '${spatial ? "unselected 3D" : "selected 2D"} preset erase preserves frontmost selection',
      () {
        final fixture = _selectedPresetEraseFixture(spatial: spatial);
        final source = fixture.map;
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapEditingViewportSession();
        if (!spatial) view.prepareTerrainPainting(fixture.preset);
        view.tool = StudioMapTool.erase;
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 3, y: 2),
        )!;
        expect(stroke.buffer.layerId, 'soil-layer');
        final erased = stroke.commit();
        final soil = erased.layers.whereType<SmartTileLayer>().firstWhere(
          (layer) => layer.id == 'soil-layer',
        );
        expect(
          smartTileMaterialIdAt(soil, mapSize: source.size, x: 3, y: 2),
          isNull,
        );
        for (final layer in source.layers.where(
          (layer) => layer.id != soil.id,
        )) {
          expect(
            erased.layers.firstWhere((entry) => entry.id == layer.id),
            layer,
          );
        }
      },
    );
  }
}

({ProjectManifest project, MapData map, ProjectSmartTilePreset preset})
_selectedPresetEraseFixture({
  bool spatial = true,
  bool bottomToTop = false,
  bool selectedLayerPresent = true,
  bool selectedCellOwned = true,
}) {
  final fixture = patternFixture(spatial: spatial);
  final soilPreset = fixture.preset.copyWith(
    id: 'soil',
    name: 'Sol',
    usage: SmartTileUsage.terrain,
  );
  final soil = MapLayer.smartTile(
    id: 'soil-layer',
    name: 'Sol',
    presetId: soilPreset.id,
    usage: soilPreset.usage,
    materialPalette: ['', soilPreset.defaultMaterialId],
    field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
  );
  final original = fixture.map.layers.whereType<SmartTileLayer>().single;
  final grass = original.copyWith(
    field: SmartTileField.cell(
      semanticCells: [
        for (var index = 0; index < 64; index++)
          index == 19 && selectedCellOwned ? 1 : 0,
      ],
    ),
    patternStrokes: [
      original.patternStrokes.single.copyWith(
        cells: [
          for (final cell in original.patternStrokes.single.cells)
            if (selectedCellOwned || cell != const GridPos(x: 3, y: 2)) cell,
        ],
      ),
    ],
  );
  final tiles = MapLayer.tile(
    id: 'foreign-tiles',
    name: 'Autre sol',
    palette: const [TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0)],
    cells: List.filled(64, 0),
  );
  final layers = <MapLayer>[
    soil,
    if (selectedLayerPresent) grass,
    if (!spatial) tiles,
  ];
  final project = fixture.project.copyWith(
    tilesets: [
      ...fixture.project.tilesets,
      ...workspaceProject.tilesets.where(
        (entry) => !fixture.project.tilesets.any((item) => item.id == entry.id),
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      formatVersion: fixture.project.smartTileCatalog.formatVersion,
      categories: fixture.project.smartTileCatalog.categories,
      atlases: fixture.project.smartTileCatalog.atlases,
      materials: fixture.project.smartTileCatalog.materials,
      animations: fixture.project.smartTileCatalog.animations,
      presets: [soilPreset, fixture.preset],
      patterns: fixture.project.smartTileCatalog.patterns,
      drafts: fixture.project.smartTileCatalog.drafts,
    ),
  );
  return (
    project: project,
    map: fixture.map.copyWith(
      layers: bottomToTop ? layers.reversed.toList() : layers,
      properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
    ),
    preset: fixture.preset,
  );
}

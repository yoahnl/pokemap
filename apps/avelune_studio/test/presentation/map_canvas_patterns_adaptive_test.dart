import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_patterns.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final kind in [
    'unique adaptive',
    'ordinary',
    'multiple adaptive',
    'visible ordinary with adaptive sibling',
    'incomplete template support',
  ]) {
    test('preset selection initializes $kind construction coherently', () {
      final fixture = adaptiveBridgeFixture();
      final catalog = fixture.project.smartTileCatalog;
      final preset = kind == 'visible ordinary with adaptive sibling'
          ? fixture.preset.copyWith(
              rules: [
                SmartTileRule(
                  id: 'visible',
                  centerMatch: SmartTileSlotMatch.material(
                    fixture.preset.defaultMaterialId,
                  ),
                  candidates: [
                    SmartTileCandidate(
                      id: 'visible',
                      parts: fixture.pattern.cells.first.parts,
                    ),
                  ],
                ),
              ],
            )
          : kind == 'incomplete template support'
          ? fixture.preset.copyWith(
              coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
            )
          : fixture.preset;
      final patterns = kind == 'ordinary'
          ? [fixture.pattern.copyWith(construction: null)]
          : [
              fixture.pattern,
              if (kind == 'multiple adaptive')
                fixture.pattern.copyWith(id: 'bridge-alt'),
            ];
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          categories: catalog.categories,
          atlases: catalog.atlases,
          materials: catalog.materials,
          presets: [preset],
          patterns: patterns,
        ),
      );
      final view = MapEditingViewportSession()..prepareTerrainPainting(preset);
      addTearDown(view.dispose);
      view.reconcileResources(project, mapId: fixture.map.id, map: fixture.map);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: fixture.map,
          mapId: fixture.map.id,
          revision: 'r0',
        ),
      );
      final unique = kind == 'unique adaptive';
      expect(view.terrainPatternId, unique ? fixture.pattern.id : null);
      expect(
        jsonEncode(document.current.toJson()),
        jsonEncode(fixture.map.toJson()),
      );
      if (unique) {
        view.selectTerrainPattern(null);
        view.reconcileResources(
          project,
          mapId: fixture.map.id,
          map: fixture.map,
        );
        expect(view.terrainPatternId, isNull);
      }
    });
  }

  test(
    'adaptive native bridge selects a full-width line gesture by default',
    () {
      final fixture = adaptiveBridgeFixture();
      final view = MapEditingViewportSession()
        ..prepareTerrainPainting(fixture.preset)
        ..selectTerrainPattern(fixture.pattern);
      addTearDown(view.dispose);

      expect(view.terrainPatternMode, SmartTilePatternSelectionKind.line);
    },
  );

  test('adaptive native bridge survives intermediate lengths, previews and undoes a complete section', () {
    final fixture = adaptiveBridgeFixture();
    final before = jsonEncode(fixture.map.toJson());
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapEditingViewportSession()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..terrainPatternMode = SmartTilePatternSelectionKind.line;
    addTearDown(view.dispose);
    MapCanvasStroke? stroke;
    expect(
      () => stroke = MapCanvasStroke.start(
        map: fixture.map,
        project: fixture.project,
        view: view,
        commands: MapEditingCommands(document, fixture.project),
        origin: const GridPos(x: 1, y: 1),
      ),
      returnsNormally,
    );
    expect(stroke, isNotNull);
    expect(jsonEncode(document.current.toJson()), before);
    expect(
      stroke!.preview.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    stroke!.paint(const GridPos(x: 1, y: 6));
    final previewLayer = stroke!.preview.layers
        .whereType<SmartTileLayer>()
        .single;
    expect(previewLayer.patternStrokes.single.cells, hasLength(30));
    expect(
      previewLayer.patternStrokes.single.constructionBounds,
      const MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 5, height: 6),
      ),
    );
    stroke!.paint(const GridPos(x: 1, y: 5));
    expect(
      stroke!.preview.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    expect(() => stroke!.commit(), throwsA(isA<ValidationException>()));
    expect(jsonEncode(document.current.toJson()), before);
    stroke!.paint(const GridPos(x: 1, y: 6));
    final committed = stroke!.commit();
    expect(committed, stroke!.preview);
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), before);
  });

  test('adaptive construction picker scopes native families through existing categories', () {
    final fixture = adaptiveBridgeFixture();
    final catalog = fixture.project.smartTileCatalog;
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        categories: [
          ...catalog.categories,
          const ProjectSmartTileCategory(id: 'foreign-style', name: 'Foreign'),
        ],
        atlases: catalog.atlases,
        materials: catalog.materials,
        presets: catalog.presets,
        patterns: [
          fixture.pattern,
          fixture.pattern.copyWith(id: 'foreign', categoryId: 'foreign-style'),
        ],
      ),
    );

    expect(
      availableTerrainPatterns(
        project: project,
        map: fixture.map,
        preset: fixture.preset,
      ).map((pattern) => pattern.id),
      [fixture.pattern.id],
    );
  });
}

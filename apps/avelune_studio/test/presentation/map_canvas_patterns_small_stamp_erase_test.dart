import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_patterns_fixtures.dart';

void main() {
  test('selected small 3D stamp erases from its empty centre with exact preview, commit and Undo', () {
    final fixture = atomicStampFixture();
    final source = fixture.map;
    final before = jsonEncode(source.toJson());
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 3),
    )!;
    final originalLayer = source.layers.whereType<SmartTileLayer>().single;
    final previewLayer = stroke.preview.layers
        .whereType<SmartTileLayer>()
        .single;
    expect(previewLayer.patternStrokes, isEmpty);
    expect(previewLayer.field, originalLayer.field);
    expect(previewLayer.materialPalette, originalLayer.materialPalette);
    expect(stroke.preview.spatialScene, source.spatialScene);
    expect(document.current, same(source));
    expect(document.undoCount, 0);
    final committed = stroke.commit();
    expect(committed, stroke.preview);
    expect(
      resolveSpatialSmartTileInstances(
        map: committed,
        catalog: fixture.project.smartTileCatalog,
      ).where((instance) => instance.modelId == 'ground-detail'),
      isEmpty,
    );
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), before);
    document.restore(redo: true);
    expect(document.current, committed);
  });

  test('selected small 3D stamp does not erase the underlying material outside its ownership', () {
    final fixture = atomicStampFixture();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    expect(
      MapCanvasStroke.start(
        map: fixture.map,
        project: fixture.project,
        view: view,
        commands: MapEditingCommands(document, fixture.project),
        origin: const GridPos(x: 0, y: 0),
      ),
      isNull,
    );
    expect(document.current, same(fixture.map));
    expect(document.undoCount, 0);
  });

  for (final samePattern in [false, true]) {
    test(
      'selected small 3D stamp removes only the top ${samePattern ? "same" : "different"} overlapping unit',
      () {
        final fixture = atomicStampFixture();
        final other = fixture.pattern.copyWith(id: 'other-detail');
        final project = withStampPatterns(fixture.project, [
          fixture.pattern,
          other,
        ]);
        final originalLayer = fixture.map.layers
            .whereType<SmartTileLayer>()
            .single;
        final applied = applySmartTilePatternGesture(
          originalLayer,
          pattern: samePattern ? fixture.pattern : other,
          mapSize: fixture.map.size,
          selection: const SmartTilePatternSelection.stamp(
            anchor: GridPos(x: 3, y: 3),
          ),
          strokeId: 'top-unit',
        );
        final source = replaceSmartTileLayer(fixture.map, layer: applied.layer);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = selectedStampEraseView(
          fixture.preset,
          samePattern ? fixture.pattern : other,
        );
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 4, y: 4),
        )!;
        stroke.paint(const GridPos(x: 4, y: 4));
        final erased = stroke.commit();
        expect(erased.layers.whereType<SmartTileLayer>().single, originalLayer);
        expect(stroke.preview, erased);
        document.commit(erased);
        expect(document.undoCount, 1);
        document.restore(redo: false);
        expect(
          jsonEncode(document.current.toJson()),
          jsonEncode(source.toJson()),
        );
      },
    );
  }

  test('selected small 3D stamp cannot erase through a different top owner even when that owner has no part', () {
    final fixture = atomicStampFixture();
    final other = fixture.pattern.copyWith(id: 'other-detail');
    final project = withStampPatterns(fixture.project, [
      fixture.pattern,
      other,
    ]);
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final source = replaceSmartTileLayer(
      fixture.map,
      layer: layer.copyWith(
        patternStrokes: [
          ...layer.patternStrokes,
          layer.patternStrokes.single.copyWith(
            id: 'covering-unit',
            patternId: other.id,
          ),
        ],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    expect(
      MapCanvasStroke.start(
        map: source,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 3),
      ),
      isNull,
    );
    expect(document.current, same(source));
  });

  test('selected small 3D stamp drag erases two units with one Undo and keeps neighbours', () {
    final fixture = atomicStampFixture();
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final applied = applySmartTilePatternGesture(
      layer,
      pattern: fixture.pattern,
      mapSize: fixture.map.size,
      selection: const SmartTilePatternSelection.stamp(
        anchor: GridPos(x: 5, y: 2),
      ),
      strokeId: 'second-unit',
    );
    final source = replaceSmartTileLayer(fixture.map, layer: applied.layer);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 3),
    )!;
    stroke.paint(const GridPos(x: 6, y: 3));
    final committed = stroke.commit();
    expect(
      committed.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    expect(
      committed.layers.whereType<SmartTileLayer>().single.field,
      layer.field,
    );
    expect(committed.spatialScene, source.spatialScene);
    expect(committed, stroke.preview);
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), jsonEncode(source.toJson()));
  });
}

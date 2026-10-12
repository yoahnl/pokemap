
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_border_commands_test.dart' show borderDocument;
import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  test('world cell quantization roundtrips quarter half and integer border offsets', () {
    for (final value in [
      -1.25,
      -1,
      -.75,
      -.5,
      -.25,
      0.0,
      .25,
      .5,
      .75,
      1.0,
      1.25,
    ]) {
      final fixture = _fixture(
        true,
        offset: Model3dVector3(x: value, y: 0, z: value),
      );
      final draft = MapBorderEraseDraft(
        sourceMap: fixture.map,
        sourceProject: fixture.project,
        layerId: 'studio-bordures',
        featureId: 'line',
        points: const [],
      );
      final world = GridPos(x: (5.5 + value).floor(), y: (5.5 + value).floor());
      expect(draft.pointFromWorldCell(world), const GridPos(x: 5, y: 5));
    }
  });
  for (final spatial in [false, true]) {
    test(
      'shared ${spatial ? '3D' : '2D'} command previews split commits once and undoes exactly',
      () {
        final fixture = _fixture(spatial);
        final document = borderDocument(fixture.map);
        final commands = MapBorderEditingCommands(document, fixture.project);
        final draft = MapBorderEraseDraft(
          sourceMap: fixture.map,
          sourceProject: fixture.project,
          layerId: 'studio-bordures',
          featureId: 'line',
          points: const [GridPos(x: 5, y: 5)],
        );
        final preview = commands.previewErase(draft);
        _expectSplit(preview);
        expect(document.current, same(fixture.map));
        expect(document.undoCount, 0);
        commands.finishErase(draft);
        expect(document.current, preview);
        expect(document.undoCount, 1);
        expect(MapData.fromJson(preview.toJson()), preview);
        document.restore(redo: false);
        expect(document.current, fixture.map);
        document.restore(redo: true);
        expect(document.current, preview);
        expect(
          () => commands.finishErase(draft),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => MapBorderEditingCommands(
            borderDocument(fixture.map),
            fixture.project.copyWith(name: 'Changed'),
          ).previewErase(draft),
          throwsA(isA<ValidationException>()),
        );
        final hidden = fixture.map.copyWith(
          layers: [
            for (final layer in fixture.map.layers)
              layer.id == 'studio-bordures'
                  ? layer.copyWith(isVisible: false)
                  : layer,
          ],
        );
        expect(
          () =>
              MapBorderEditingCommands(
                borderDocument(hidden),
                fixture.project,
              ).previewErase(
                MapBorderEraseDraft(
                  sourceMap: hidden,
                  sourceProject: fixture.project,
                  layerId: 'studio-bordures',
                  featureId: 'line',
                  points: draft.points,
                ),
              ),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  }

  testWidgets(
    '2D selected local eraser previews fragments then release commits and Escape cancels',
    (tester) async {
      final host = await _pump(tester, false);
      await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
      await tester.pump();
      final initial = host.document.current;
      final point = _at(tester, host.view, 5, 5);
      final gesture = await tester.startGesture(
        point,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      _expectSplit(host.visuals.renderedMap!);
      expect(host.document.current, same(initial));
      expect(host.document.undoCount, 0);
      await gesture.up();
      await tester.pump();
      _expectSplit(host.document.current);
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      final cancelled = await tester.startGesture(
        point,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await cancelled.up();
      await tester.pump();
      expect(host.document.current, initial);
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '2D drag erases sampled cells and rejects changed zoom or selection',
    (tester) async {
      final host = await _pump(tester, false);
      await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
      await tester.pump();
      Offset at(int x) => _at(tester, host.view, x, 5);
      final drag = await tester.startGesture(
        at(4),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveTo(at(6));
      await tester.pump();
      await drag.up();
      await tester.pump();
      final strokes =
          (_feature(host.document.current).geometry as BorderStrokeGeometry)
              .strokes;
      expect(strokes.map((stroke) => stroke.points), [
        [const GridPos(x: 2, y: 5), const GridPos(x: 3, y: 5)],
        [const GridPos(x: 7, y: 5), const GridPos(x: 8, y: 5)],
      ]);
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      final before = host.document.current;
      final zoom = await tester.startGesture(
        at(5),
        kind: PointerDeviceKind.mouse,
      );
      host.view.transform.value = host.view.transform.value.clone()
        ..scaleByDouble(1.1, 1.1, 1, 1);
      await zoom.up();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      final selection = await tester.startGesture(
        at(5),
        kind: PointerDeviceKind.mouse,
      );
      host.view.borderFeature = null;
      await selection.up();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '3D local erase shows native preview and preserves foreign models with one undo',
    (tester) async {
      final host = await _pump(tester, true);
      await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      final before = host.document.current;
      expect(scene().onDragStart!(5, 5, null), true);
      await tester.pump();
      expect(scene().scene.instances, hasLength(7));
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
      scene().onDragEnd!();
      await tester.pump();
      _expectSplit(host.document.current);
      expect(
        host.document.current.spatialScene!.instances.lastWhere(
          (instance) => instance.id == 'foreign',
        ),
        before.spatialScene!.instances.singleWhere(
          (instance) => instance.id == 'foreign',
        ),
      );
      expect(host.document.undoCount, 1);
      host.document.restore(redo: false);
      host.refresh();
      await tester.pump();
      expect(host.document.current, before);
      expect(scene().onDragStart!(5, 5, null), true);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      scene().onDragEnd!();
      expect(host.document.current, before);
      expect(host.document.undoCount, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('3D erase rejects camera and tool changes', (tester) async {
    final host = await _pump(tester, true);
    await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
    await tester.pump();
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    final before = host.document.current;
    for (final cameraChange in [
      (SpatialSceneController camera) => camera.dolly(100),
      (SpatialSceneController camera) => camera.orbit(12, 0),
      (SpatialSceneController camera) => camera.panBy(1, 0),
    ]) {
      expect(scene().onDragStart!(5, 5, null), true);
      cameraChange(scene().controller);
      scene().onDragEnd!();
      await tester.pump();
      expect(host.document.current, same(before));
      expect(host.document.undoCount, 0);
    }
    expect(scene().onDragStart!(5, 5, null), true);
    host.view.tool = StudioMapTool.select;
    host.refresh();
    await tester.pump();
    scene().onDragEnd!();
    expect(host.document.current, same(before));
    expect(host.document.undoCount, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'complete erasure returns to draw mode and never silently selects another trace',
    (tester) async {
      final host = await _pump(tester, true);
      await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      expect(scene().onDragStart!(2, 5, null), true);
      scene().onDragUpdate!((8, 5));
      scene().onDragEnd!();
      await tester.pump();
      expect(
        host.document.current.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features,
        isEmpty,
      );
      expect(
        host.document.current.spatialScene!.instances.map(
          (instance) => instance.id,
        ),
        ['foreign'],
      );
      expect(host.view.borderFeature, isNull);
      expect(host.view.borderEditingMode, BorderStrokeEditingMode.draw);
      expect(host.document.undoCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'native eraser converts world cells back to the offset authored trace',
    (tester) async {
      final host = await _pump(
        tester,
        true,
        offset: Model3dVector3(x: .5, y: .25, z: .5),
      );
      await tester.tap(find.byKey(const ValueKey('border-stroke-erase-mode')));
      await tester.pump();
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(6, 6, null), true);
      scene.onDragEnd!();
      await tester.pump();
      _expectSplit(host.document.current);
      expect(
        _feature(host.document.current).spatialOffsetWorld,
        Model3dVector3(x: .5, y: .25, z: .5),
      );
      expect(host.document.undoCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final spatial in [false, true]) {
    testWidgets(
      '${spatial ? '3D' : '2D'} hidden selection requires an explicit visible trace choice',
      (tester) async {
        final host = await _pump(tester, spatial);
        await tester.tap(
          find.byKey(const ValueKey('border-stroke-erase-mode')),
        );
        await tester.pump();
        final original = host.document.current;
        final first = original.layers.whereType<BorderLayer>().single;
        final feature = first.content.features.single;
        var map = addBorderLayer(
          original,
          id: 'other-border',
          name: 'Autre calque',
        );
        map = upsertBorderFeature(
          map,
          layerId: 'other-border',
          feature: BorderFeature(
            id: 'other',
            name: 'Autre tracé',
            blueprintId: feature.blueprintId,
            seed: feature.seed,
            overrides: const [],
            keepOutRegions: const [],
            geometry: feature.geometry,
          ),
        );
        map = map.copyWith(
          layers: [
            for (final layer in map.layers)
              layer.id == first.id ? layer.copyWith(isVisible: false) : layer,
          ],
        );
        host.document.current = map;
        host.refresh();
        await tester.pump();
        final picker = tester
            .widget<DropdownButton<({String layerId, String featureId})>>(
              find.byKey(const ValueKey('border-feature-picker')),
            );
        expect(picker.value, isNull);
        expect(find.text('Choisir un tracé visible'), findsOneWidget);
        expect(find.textContaining('n’est plus visible'), findsOneWidget);
        final before = host.document.current;
        picker.onChanged!((layerId: 'other-border', featureId: 'other'));
        await tester.pump();
        expect(host.view.borderFeature, (
          layerId: 'other-border',
          featureId: 'other',
        ));
        expect(host.document.current, same(before));
        expect(host.document.undoCount, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}

({ProjectManifest project, MapData map}) _fixture(
  bool spatial, {
  Model3dVector3? offset,
}) {
  final project = spatial
      ? spatialBorderProject()
      : workspaceProject.copyWith(borderCatalog: testBorderCatalog());
  final source = spatial
      ? spatialBorderMap().copyWith(
          spatialScene: spatialBorderMap().spatialScene!.copyWith(
            instances: [
              SpatialModelInstance(
                id: 'foreign',
                modelId: 'oak',
                position: Model3dVector3(x: .5, y: 0, z: .5),
              ),
            ],
          ),
        )
      : workspaceMap('a');
  final document = borderDocument(source);
  final commands = MapBorderEditingCommands(document, project);
  commands.finish(
    MapBorderDrawingDraft.start(
      mapId: source.id,
      mapSize: source.size,
      blueprintId: spatial ? 'fence' : 'muret',
      origin: const GridPos(x: 2, y: 5),
      sourceMap: source,
      sourceProject: project,
      featureId: 'line',
      seed: BorderSignedInt64.fromInt(17),
    ).addAngle(const GridPos(x: 8, y: 5)),
  );
  if (offset != null) {
    commands.setSpatialOffset(
      layerId: 'studio-bordures',
      featureId: 'line',
      offset: offset,
      source: _feature(document.current),
    );
    commands.applyExisting(
      commands.previewExisting(layerId: 'studio-bordures', featureId: 'line'),
      source: document.current,
      sourceProject: project,
    );
  }
  return (project: project, map: document.current);
}

BorderFeature _feature(MapData map) =>
    map.layers.whereType<BorderLayer>().single.content.features.single;

Offset _at(WidgetTester tester, MapWorkspaceViewState view, int x, int y) {
  final canvas = tester.widget<MapWorkspaceCanvas>(
    find.byType(MapWorkspaceCanvas),
  );
  final box = tester.renderObject<RenderBox>(
    find.byKey(const ValueKey('map-canvas')),
  );
  return box.localToGlobal(
    Offset(
      (x + .5) *
          canvas.project.settings.tileWidth *
          canvas.project.settings.displayScale,
      (y + .5) *
          canvas.project.settings.tileHeight *
          canvas.project.settings.displayScale,
    ),
  );
}

void _expectSplit(MapData map) {
  final feature = _feature(map);
  final strokes = (feature.geometry as BorderStrokeGeometry).strokes;
  expect(strokes, hasLength(2));
  expect(strokes.map((stroke) => stroke.points.length), [3, 3]);
  expect(
    strokes.expand((stroke) => stroke.points),
    isNot(contains(const GridPos(x: 5, y: 5))),
  );
  expect(feature.materialization, isNotNull);
}

Future<
  ({
    EditableMapDocument document,
    MapWorkspaceViewState view,
    _Visuals visuals,
    VoidCallback refresh,
  })
>
_pump(WidgetTester tester, bool spatial, {Model3dVector3? offset}) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixture = _fixture(spatial, offset: offset);
  final document = borderDocument(fixture.map);
  final view = MapWorkspaceViewState()
    ..tool = StudioMapTool.border
    ..borderBlueprintId = spatial ? 'fence' : 'muret';
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(),
  )..project = fixture.project;
  final visuals = _Visuals();
  addTearDown(view.dispose);
  addTearDown(controller.dispose);
  late VoidCallback refresh;
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            refresh = () => setState(() {});
            return Column(
              children: [
                MapBorderToolPanel(
                  document: document,
                  project: fixture.project,
                  view: view,
                  onChanged: refresh,
                  onCreateModel: () {},
                ),
                Expanded(
                  child: spatial
                      ? SpatialMapEditor(
                          document: document,
                          controller: controller,
                          project: fixture.project,
                          visuals: visuals,
                          view: view,
                          onChanged: refresh,
                        )
                      : MapWorkspaceCanvas(
                          document: document,
                          project: fixture.project,
                          visuals: visuals,
                          view: view,
                          onChanged: refresh,
                          gestureGeneration: 0,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return (document: document, view: view, visuals: visuals, refresh: refresh);
}

class _Visuals extends WorkspaceTestVisuals implements SpatialWorkspaceVisuals {
  MapData? renderedMap;
  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) {
    renderedMap = map;
    return const SizedBox.expand();
  }

  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

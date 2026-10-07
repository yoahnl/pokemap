import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_terrain_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/services.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'slope preview shows its complete area, rise and invalid guidance',
    (tester) async {
      final map = reliefMap(raised: true);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.ramp;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SpatialMapEditor(
                document: document,
                controller: controller,
                project: workspaceProject,
                visuals: ReliefVisuals(),
                view: view,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      );
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      expect(canvas().onDragStart!(3, 5, null), isTrue);
      canvas().onDragUpdate!((4, 3));
      await tester.pump();
      expect(
        canvas().cellOverlays.where(
          (item) => item.kind == SpatialCellOverlayKind.preview,
        ),
        hasLength(6),
      );
      expect(find.textContaining('vers le nord'), findsOneWidget);
      expect(find.textContaining('0 → 1 blocs'), findsOneWidget);
      expect(find.textContaining('Zone 2 × 3 cases'), findsOneWidget);
      expect(document.current, same(map));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(canvas().scene.navigation.ramps, hasLength(1));
      expect(document.undoCount, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(canvas().scene.navigation.ramps, isEmpty);
      expect(canvas().onDragStart!(0, 5, null), isTrue);
      canvas().onDragUpdate!((1, 3));
      await tester.pump();
      expect(
        find.textContaining('La pente doit relier un sol bas'),
        findsOneWidget,
      );
      expect(document.undoCount, 0);
      canvas().onDragEnd!();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
    },
  );

  testWidgets(
    'model hover is temporary, Shift is precise, and click matches preview',
    (tester) async {
      final model = ProjectModel3dEntry(
        id: 'rock',
        name: 'Rocher',
        sourceAssetId: 'rock_source',
        relativePath: 'assets/models3d/rock.glb',
        inspection: Model3dInspection(
          meshCount: 1,
          triangleCount: 12,
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
        ),
      );
      final project = workspaceProject.copyWith(models3d: [model]);
      final map = reliefMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.place
        ..model3d = model;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('precision-focus-field')),
                  Expanded(
                    child: SpatialMapEditor(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: ReliefVisuals(),
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      SpatialSceneView canvas() => tester.widget(find.byType(SpatialSceneView));
      final hit = SpatialSurfaceHit(
        cell: (2, 3),
        position: Model3dVector3(x: 2.2, y: 0, z: 3.7),
      );
      expect(canvas().onHover, isNotNull);
      canvas().onHover!(hit);
      await tester.pump();
      expect(canvas().placementPreview!.position.x, 2.5);
      expect(canvas().placementPreview!.position.z, 3.5);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      canvas().onHover!(null);
      await tester.pump();
      expect(canvas().placementPreview, isNull);
      canvas().onHover!(hit);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('precision-focus-field')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      canvas().onHover!(hit);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(canvas().controller.view, SpatialEditorView.orbit);
      expect(canvas().placementPreview!.position, hit.position);
      canvas().onSurfaceTap!(hit);
      await tester.pump();
      expect(
        document.current.spatialScene!.instances.single.position,
        hit.position,
      );
      expect(document.undoCount, 1);
      expect(canvas().placementPreview, isNull);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(MapData.fromJson(document.current.toJson()), document.current);
      view.tool = StudioMapTool.select;
      canvas().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: document.current.spatialScene!.instances.single.id,
          cell: (2, 3),
        ),
      );
      await tester.pump();
      final placed = document.current;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, same(placed));
      expect(document.undoCount, 1);
    },
  );

  testWidgets(
    'Shift arrows orbit the editor without changing the game camera',
    (tester) async {
      final map = reliefMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.terrain
        ..spatialTerrainMode = SpatialTerrainMode.relief;
      addTearDown(controller.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SpatialMapEditor(
                document: document,
                controller: controller,
                project: workspaceProject,
                visuals: ReliefVisuals(),
                view: view,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      );
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      final yaw = scene.controller.yaw;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(view.spatialFreeView, isTrue);
      expect(scene.controller.view, SpatialEditorView.orbit);
      expect(scene.controller.yaw, isNot(yaw));
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(document.current.spatialScene!.camera, map.spatialScene!.camera);
      final canvas = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(canvas.onDragStart!(1, 3, null), isTrue);
      canvas.onDragEnd!();
      expect(document.undoCount, 1);
    },
  );

  testWidgets('3D terrain tools open without choosing a ground resource', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceToolStrip(
            view: view,
            spatial: true,
            onChanged: () {},
            onMoreTools: () {},
            onResources: () {},
            storyAvailable: false,
            paletteVisible: true,
            onUndo: null,
            onRedo: null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Terrains'));
    expect(view.tool, StudioMapTool.terrain);
    expect(view.terrain, isNull);
  });

  testWidgets('relief toolbar exposes the target height without an inspector', (
    tester,
  ) async {
    final view = MapWorkspaceViewState()
      ..tool = StudioMapTool.terrain
      ..spatialTerrainMode = SpatialTerrainMode.relief;
    addTearDown(view.dispose);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: reliefMap(), mapId: 'a', revision: 'r'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapTerrainToolPanel(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    expect(find.byType(StudioSelect), findsOneWidget);
    tester.widget<StudioSelect>(find.byType(StudioSelect)).onChanged!('3');
    expect(view.spatialTerrainLevel, 3);
    expect(document.undoCount, 0);
  });

  test('slope eraser removes a narrow ramp intersecting the painted cell', () {
    final map = reliefMap(raised: true);
    final withRamp = const SpatialMapOperations().configureNavigation(
      map,
      map.spatialScene!.navigation.copyWith(
        ramps: [
          SpatialRamp(
            id: 'narrow',
            x: 3.1,
            z: 3,
            width: .2,
            depth: 3,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    final erase = SpatialTerrainStroke(
      source: withRamp,
      mode: SpatialTerrainMode.ramp,
      level: 1,
      erase: true,
      origin: const GridPos(x: 3, y: 4),
    );
    expect(erase.commit().spatialScene!.navigation.ramps, isEmpty);
    final adjacent = SpatialTerrainStroke(
      source: withRamp,
      mode: SpatialTerrainMode.ramp,
      level: 1,
      erase: true,
      origin: const GridPos(x: 2, y: 4),
    );
    expect(adjacent.commit().spatialScene!.navigation.ramps, hasLength(1));
  });
  test('block elevation preserves a module alignment above its ground', () {
    final map = reliefMap().copyWith(
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'rock',
            position: Model3dVector3(x: 2, y: .01, z: 4),
          ),
        ],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
    );
    final commands = SpatialModelEditingCommands(document, workspaceProject);
    commands.update('stairs', heightLevel: 2);
    commands.update('stairs', x: 3);
    expect(
      document.current.spatialScene!.instances.single.position.y,
      closeTo(2.01, .000001),
    );
  });
  test(
    'moving a raised module keeps its elevation above its destination ground',
    () {
      final levels = List.filled(64, 0)..[4 * 8 + 4] = 1;
      final map = reliefMap().copyWith(
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          heightLevels: levels,
          instances: [
            SpatialModelInstance(
              id: 'module',
              modelId: 'rock',
              position: Model3dVector3(x: 1.5, y: 2, z: 4.5),
            ),
          ],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      SpatialModelEditingCommands(
        document,
        workspaceProject,
      ).update('module', x: 4.5);
      expect(document.current.spatialScene!.instances.single.position.y, 3);
      final commands = SpatialModelEditingCommands(document, workspaceProject);
      commands.update('module', heightLevel: 4);
      expect(document.current.spatialScene!.instances.single.position.y, 5);
      final beforeInvalid = document.current;
      expect(
        () => commands.update('module', heightLevel: 33),
        throwsStateError,
      );
      expect(document.current, same(beforeInvalid));
    },
  );
  test(
    'block brush interpolates, reanchors models and records one history entry',
    () {
      final map = reliefMap().copyWith(
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          instances: [
            SpatialModelInstance(
              id: 'prop',
              modelId: 'rock',
              position: Model3dVector3(x: 4.5, y: .75, z: 4.5),
            ),
          ],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final stroke = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.relief,
        level: 3,
        erase: false,
        origin: const GridPos(x: 1, y: 4),
      );
      stroke.paint(const GridPos(x: 6, y: 4));
      expect(document.current, same(map));
      expect(stroke.preview.spatialScene!.instances.single.position.y, 3.75);
      document.commit(stroke.commit());
      expect(document.undoCount, 1);
      for (var x = 1; x <= 6; x++) {
        expect(document.current.spatialScene!.heightAt(x, 4), 3);
      }
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(MapData.fromJson(document.current.toJson()), document.current);
    },
  );

  test(
    'slope connects low to high and can be erased without flattening ground',
    () {
      final map = reliefMap(raised: true);
      final stroke = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: false,
        origin: const GridPos(x: 3, y: 5),
      );
      stroke.paint(const GridPos(x: 3, y: 3));
      final result = stroke.commit();
      final ramp = result.spatialScene!.navigation.ramps.single;
      expect(ramp.direction, SpatialRampDirection.north);
      expect(ramp.lowLevel, 0);
      expect(ramp.highLevel, 1);
      expect(result.spatialScene!.worldHeightAt(3.5, 4.5), .5);
      final erase = SpatialTerrainStroke(
        source: result,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: true,
        origin: const GridPos(x: 3, y: 4),
      );
      expect(erase.commit(), map);
      final invalid = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: false,
        origin: const GridPos(x: 1, y: 5),
      );
      invalid.paint(const GridPos(x: 1, y: 3));
      expect(invalid.commit, throwsStateError);
      expect(invalid.preview, same(map));
    },
  );

  testWidgets('relief drag previews height and Escape discards the stroke', (
    tester,
  ) async {
    final map = reliefMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
    );
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapWorkspaceViewState()
      ..tool = StudioMapTool.terrain
      ..spatialTerrainMode = SpatialTerrainMode.relief
      ..spatialTerrainLevel = 2;
    addTearDown(controller.dispose);
    addTearDown(view.dispose);
    late VoidCallback redraw;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = () => setState(() {});
              return SpatialMapEditor(
                document: document,
                controller: controller,
                project: workspaceProject,
                visuals: ReliefVisuals(),
                view: view,
                onChanged: () => setState(() {}),
              );
            },
          ),
        ),
      ),
    );
    var canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    canvas.onHover!(
      SpatialSurfaceHit(
        cell: (1, 4),
        position: Model3dVector3(x: 1.25, y: 0, z: 4.75),
      ),
    );
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(
      canvas.cellOverlays.where(
        (item) =>
            item.kind == SpatialCellOverlayKind.preview &&
            item.cell == (1, 4) &&
            item.targetHeight == 2,
      ),
      hasLength(1),
    );
    expect(find.textContaining('0 → 2 blocs'), findsOneWidget);
    expect(
      canvas.cellOverlays.where(
        (item) =>
            item.kind == SpatialCellOverlayKind.preview &&
            item.cell == (1, 4) &&
            item.targetHeight == 0,
      ),
      hasLength(1),
    );
    expect(document.undoCount, 0);
    expect(canvas.onDragStart!(1, 4, null), isTrue);
    canvas.onDragUpdate!((5, 4));
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.scene.heightAt(3, 4), 2);
    expect(document.current, same(map));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    canvas.onDragEnd!();
    expect(document.current, map);
    expect(document.undoCount, 0);
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.onDragStart!(1, 4, null), isTrue);
    canvas.onDragUpdate!((5, 4));
    canvas.onDragEnd!();
    expect(document.current.spatialScene!.heightAt(3, 4), 2);
    expect(document.undoCount, 1);
    canvas.onDragStart!(1, 2, null);
    canvas.onDragUpdate!((5, 2));
    document.commit(
      document.current.copyWith(name: 'Renommée pendant le trait'),
    );
    redraw();
    await tester.pump();
    canvas = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(canvas.scene, document.current.spatialScene);
    expect(canvas.groundMap, same(document.current));
    final changed = document.current;
    canvas.onDragEnd!();
    expect(document.current, same(changed));
  });

  testWidgets('cliff texture picker is undoable and can clear its reference', (
    tester,
  ) async {
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: reliefMap(), mapId: 'a', revision: 'r'),
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    final project = workspaceProject.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: [
          const ProjectSmartTileAtlas(
            id: 'wall',
            name: 'Paroi NB2',
            tilesetId: 'atlas',
            columns: 1,
            rows: 1,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpatialTerrainControls(
            document: document,
            project: project,
            view: view,
            visuals: WorkspaceTestVisuals(),
            onChanged: () {},
          ),
        ),
      ),
    );
    final picker = tester.widget<StudioSelect>(find.byType(StudioSelect));
    picker.onChanged!('wall');
    expect(document.current.spatialScene!.cliffFrame!.atlasId, 'wall');
    expect(document.undoCount, 1);
    picker.onChanged!('none');
    expect(document.current.spatialScene!.cliffFrame, isNull);
    document.restore(redo: false);
    expect(document.current.spatialScene!.cliffFrame!.atlasId, 'wall');
  });
  for (final spatial in [false, true]) {
    testWidgets(
      'terrain modes are ${spatial ? "available in 3D" : "absent in 2D"}',
      (tester) async {
        final map = spatial
            ? MapData(
                id: 'a',
                name: 'Relief',
                version: ProjectVersion.v9,
                size: const GridSize(width: 8, height: 7),
                spatialScene: MapSpatialScene(width: 8, depth: 7),
              )
            : workspaceMap('a');
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: 'a', revision: 'relief-ui'),
        );
        final view = MapWorkspaceViewState();
        addTearDown(view.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapTerrainToolPanel(
                document: document,
                project: workspaceProject,
                visuals: WorkspaceTestVisuals(),
                view: view,
                onChanged: () {},
              ),
            ),
          ),
        );
        expect(find.text('Relief'), spatial ? findsOneWidget : findsNothing);
        expect(find.text('Pente'), spatial ? findsOneWidget : findsNothing);
        if (spatial) {
          await tester.tap(find.text('Relief'));
          expect(view.tool, StudioMapTool.terrain);
        }
        expect(document.undoCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

MapData reliefMap({bool raised = false}) => MapData(
  id: 'a',
  name: 'Relief',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++)
          raised && z >= 1 && z <= 2 && x >= 2 && x <= 5 ? 1 : 0,
    ],
  ),
);

class ReliefVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

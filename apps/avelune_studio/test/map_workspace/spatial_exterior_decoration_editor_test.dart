import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_decor_inspector_tabs.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_editor_pane.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip_selection.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_exterior_decoration_controls.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_camera_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_connection_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_day_night_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('exterior pane keeps its routed inspector visible', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final exterior = await MapExteriorDecorationController.open(
      workspaceSession,
      map,
      _ExteriorPort(),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..exteriorDecoration = exterior;
    final view = MapWorkspaceViewState();
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final search = TextEditingController();
    addTearDown(exterior.dispose);
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    addTearDown(search.dispose);
    exterior.setEditingExterior(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceEditorPane(
            controller: controller,
            document: document,
            project: spatialEnvironmentProject(),
            visuals: _SpatialVisuals(),
            view: view,
            search: search,
            generation: 0,
            showNavigator: false,
            showToolStrip: false,
            showPaletteDock: false,
            inspector: const SizedBox(
              width: 100,
              child: Text('Exterior inspector'),
            ),
            onActivate: (_) {},
            onOrganizeMaps: null,
            onToolChanged: () {},
            onChanged: () {},
            onMoreTools: () {},
            onResources: () {},
            onZoneDrawn: null,
            onContextMenu: null,
          ),
        ),
      ),
    );
    expect(find.text('Exterior inspector'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('exterior model properties round trip through map coordinates', (
    tester,
  ) async {
    final project = spatialEnvironmentProject();
    final map = spatialEnvironmentMap();
    final exterior = await MapExteriorDecorationController.open(
      workspaceSession,
      map,
      _ExteriorPort(),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..exteriorDecoration = exterior;
    final view = MapWorkspaceViewState();
    addTearDown(exterior.dispose);
    addTearDown(view.dispose);
    exterior.setEditingExterior(true);
    exterior.selectAt(-3, 2);
    final target = exterior.editingDocument!;
    final instance = SpatialModelEditingCommands(target, project).place(
      project.models3d.single,
      GridPos(x: -3 - exterior.originX, y: 2 - exterior.originZ),
    );
    target.selectedId = instance.id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSelectionInspector(
            document: document,
            project: project,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            onOpenElement: (_) {},
            onEditElement: (_) {},
          ),
        ),
      ),
    );
    final x = tester.widget<StudioCommitField>(
      find.byKey(const ValueKey('decor-geometry-x')),
    );
    final z = tester.widget<StudioCommitField>(
      find.byKey(const ValueKey('decor-geometry-y')),
    );
    expect(double.parse(x.value), -2.5);
    expect(double.parse(z.value), 2.5);
    expect(x.tryCommit!('-3.5'), isTrue);
    expect(
      target.current.spatialScene!.instances.single.position.x +
          exterior.originX,
      -3.5,
    );
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    expect(find.text('Bloque le passage'), findsNothing);
    expect(find.text('Événements de ce décor'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'switching to exterior resets unsupported tools without map writes',
    (tester) async {
      final map = spatialEnvironmentMap();
      final exterior = await MapExteriorDecorationController.open(
        workspaceSession,
        map,
        _ExteriorPort(),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.character
        ..paletteTab = 'Personnages'
        ..paletteTiles = true;
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapExteriorDecorationControls(
              controller: exterior,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      tester.widget<StudioSelect>(find.byType(StudioSelect)).onChanged!(
        'exterior',
      );
      await tester.pump();
      expect(exterior.editingExterior, isTrue);
      expect(view.tool, StudioMapTool.select);
      expect(view.paletteTab, 'Décors');
      expect(view.paletteTiles, isFalse);
      expect(exterior.editingDocument, isNull);
      expect(exterior.current!.sectors, isEmpty);
      expect(
        find.text(
          'Cliquez à l’extérieur de la zone jouable pour commencer à peindre ou placer un décor.',
        ),
        findsOneWidget,
      );
      exterior.configureMargins(west: 0, east: 0, north: 0, south: 0);
      await tester.pump();
      expect(
        find.text(
          'Définissez au moins une marge pour créer du décor extérieur.',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('exterior tools exclude every gameplay and raw tile action', () {
    expect(
      StudioMapTool.values.where(isExteriorDecorationTool),
      unorderedEquals([
        StudioMapTool.select,
        StudioMapTool.pan,
        StudioMapTool.place,
        StudioMapTool.terrain,
        StudioMapTool.border,
        StudioMapTool.environment,
        StudioMapTool.erase,
        StudioMapTool.eraseDecor,
      ]),
    );
  });

  testWidgets('exterior inspector follows the selected visual document', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final exterior = await MapExteriorDecorationController.open(
      workspaceSession,
      map,
      _ExteriorPort(),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..exteriorDecoration = exterior;
    final view = MapWorkspaceViewState()..tool = StudioMapTool.connection;
    addTearDown(exterior.dispose);
    addTearDown(view.dispose);
    exterior.setEditingExterior(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSelectionInspector(
            document: document,
            project: spatialEnvironmentProject(),
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            onOpenElement: (_) {},
            onEditElement: (_) {},
            onLinkMaps: (_, _, _) async {},
            onUnlinkMaps: (_) async {},
          ),
        ),
      ),
    );
    expect(
      find.text(
        'Cliquez dans le décor extérieur pour sélectionner une zone à éditer.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MapDecorInspectorTabs), findsNothing);
    exterior.selectAt(-1, 1);
    await tester.pump();
    final inspector = tester.widget<MapDecorInspectorTabs>(
      find.byType(MapDecorInspectorTabs),
    );
    expect(inspector.document, same(exterior.editingDocument));
    expect(inspector.document, isNot(same(document)));
    expect(find.byType(MapCameraPanel), findsNothing);
    expect(find.byType(MapDayNightPanel), findsNothing);
    expect(find.byType(MapConnectionPanel), findsNothing);
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    exterior.setEditingExterior(false);
    await tester.pump();
    expect(find.byType(MapDecorInspectorTabs), findsNothing);
    expect(find.byType(MapConnectionPanel), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('exterior toolbar offers visual families without gameplay', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapWorkspaceToolStrip(
            view: view,
            exterior: true,
            spatial: true,
            onChanged: () {},
            onMoreTools: () {},
            onResources: () {},
            storyAvailable: true,
            paletteVisible: true,
            onUndo: null,
            onRedo: null,
          ),
        ),
      ),
    );
    expect(find.text('Environnements'), findsOneWidget);
    for (final label in ['Zones', 'Collisions', 'Passages', 'Connexions']) {
      expect(find.text(label), findsNothing);
    }
    await tester.tap(find.byTooltip('Autres outils de carte'));
    await tester.pumpAndSettle();
    expect(find.text('Placer un personnage'), findsNothing);
    expect(find.text('Peindre les collisions'), findsNothing);
    expect(find.text('Peindre'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'native exterior environment strokes preserve the playable render inputs',
    (tester) async {
      final project = spatialEnvironmentProject();
      final map = spatialEnvironmentMap().copyWith(
        entities: const [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(characterId: 'guide'),
          ),
        ],
      );
      final exterior = await MapExteriorDecorationController.open(
        workspaceSession,
        map,
        _ExteriorPort(),
      );
      exterior.setEditingExterior(true);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
      )..exteriorDecoration = exterior;
      final view = MapWorkspaceViewState()
        ..selectEnvironmentPreset(
          document,
          project,
          project.environmentPresets.single,
        );
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(exterior.current?.sectors, isEmpty);
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final visuals = _SpatialVisuals();
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: project,
            visuals: visuals,
            view: view,
            onChanged: () {},
          ),
        ),
      );
      SpatialSceneView scene() =>
          tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      await tester.pumpWidget(canvas());
      expect(scene().resolveAuthoringTarget!(0, 0), isNull);
      final target = scene().resolveAuthoringTarget!(-1, 1)!;
      final child = exterior.editingDocument!;
      final commands = EnvironmentEditingCommands(child, project);
      await tester.pumpWidget(canvas());
      final localX = -1 - exterior.originX;
      final localZ = 1 - exterior.originZ;
      expect(scene().onContextMenu, isNull);
      for (final tool in [
        StudioMapTool.character,
        StudioMapTool.warp,
        StudioMapTool.spawn,
        StudioMapTool.encounterPaint,
        StudioMapTool.encounterErase,
        StudioMapTool.gameplayZone,
      ]) {
        view.tool = tool;
        expect(scene().onDragStart!(localX, localZ, null), isFalse);
        expect(document.current, same(map));
        expect(exterior.current!.sectors.single.layers, isEmpty);
        expect(exterior.current!.sectors.single.scene.instances, isEmpty);
      }
      view.tool = StudioMapTool.environment;
      expect(scene().onDragStart!(localX, localZ, null), isTrue);
      scene().onDragEnd!();
      expect(
        commands.areas.single.area.mask.isActiveAt(localX, localZ),
        isTrue,
      );
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(exterior.canUndo, isTrue);
      await tester.pumpWidget(canvas());
      expect(visuals.previewedMaps, [map]);
      expect(scene().groundMap, same(map));
      expect(scene().scene, same(map.spatialScene));
      expect(scene().authoringTarget?.offset, target.offset);
      expect(scene().decorations.single.decoration.sectors, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'an exterior brush crosses sector boundaries in one reversible gesture',
    (tester) async {
      final project = spatialEnvironmentProject();
      final map = spatialEnvironmentMap();
      final exterior = await MapExteriorDecorationController.open(
        workspaceSession,
        map,
        _ExteriorPort(),
      );
      exterior.setEditingExterior(true);
      exterior.configureMargins(west: 64, east: 0, north: 16, south: 0);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
      )..exteriorDecoration = exterior;
      final view = MapWorkspaceViewState()..tool = StudioMapTool.environment;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final visuals = _SpatialVisuals();
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: project,
            visuals: visuals,
            view: view,
            onChanged: () {},
          ),
        ),
      );
      SpatialSceneView scene() =>
          tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      await tester.pumpWidget(canvas());
      scene().resolveAuthoringTarget!(-33, 1);
      view.environment = EnvironmentEditingCommands(
        exterior.editingDocument!,
        project,
      ).create(project.environmentPresets.single);
      await tester.pumpWidget(canvas());
      final before = exterior.current!;
      expect(
        scene().onDragStart!(
          -33 - exterior.originX,
          1 - exterior.originZ,
          null,
        ),
        isTrue,
      );
      expect(scene().resolveAuthoringTarget!(-31, 1), isNotNull);
      scene().onDragUpdate!((-31 - exterior.originX, 1 - exterior.originZ));
      scene().onDragEnd!();
      final painted = exterior.current!;
      final worldCells = <(int, int)>{
        for (final sector in painted.sectors)
          for (final layer in sector.layers.whereType<EnvironmentLayer>())
            for (final area in layer.content.areas)
              for (var z = 0; z < area.mask.height; z++)
                for (var x = 0; x < area.mask.width; x++)
                  if (area.mask.isActiveAt(x, z))
                    (x + sector.originX, z + sector.originZ),
      };
      expect(worldCells, {(-33, 1), (-32, 1), (-31, 1)});
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      exterior.undo();
      expect(exterior.current, before);
      exterior.redo();
      expect(exterior.current, painted);
      await tester.pumpWidget(canvas());
      scene().resolveAuthoringTarget!(-33, 2);
      await tester.pumpWidget(canvas());
      expect(
        scene().onDragStart!(
          -33 - exterior.originX,
          2 - exterior.originZ,
          null,
        ),
        isTrue,
      );
      scene().resolveAuthoringTarget!(-31, 2);
      scene().onDragCancel!();
      expect(exterior.current, painted);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

final class _ExteriorPort implements MapExteriorDecorationPort {
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => const MapExteriorDecorationState(decoration: null, revision: 'r0');
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  final previewedMaps = <MapData>[];
  @override
  Future<Uint8List> readModel(String id) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String id) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async {
    previewedMaps.add(map);
    return SpatialNpcPreview({}, () {});
  }
}

import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
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

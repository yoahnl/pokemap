
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../../packages/map_core/test/support/spatial_border_ground_surface_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'one native Border crosses sector boundaries with a persistent logical owner',
    (tester) async {
      final map = spatialEnvironmentMap(),
          project = spatialBorderFixture().project;
      final exterior = await MapExteriorDecorationController.open(
        workspaceSession,
        map,
        _Port(),
      );
      exterior.setEditingExterior(true);
      exterior.configureMargins(west: 64, east: 16, north: 16, south: 16);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
      )..exteriorDecoration = exterior;
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.border
        ..borderBlueprintId = 'fence';
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      final visuals = _Visuals();
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
      for (final point in [
        const GridPos(x: -35, y: 2),
        const GridPos(x: -30, y: 2),
      ]) {
        expect(scene().resolveAuthoringTarget!(point.x, point.y), isNotNull);
        scene().onCell(point.x - exterior.originX, point.y - exterior.originZ);
        await tester.pumpWidget(canvas());
      }
      expect(view.borderDraft!.canFinish, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpWidget(canvas());
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      final border = exterior.current!.borders.single;
      expect(border.originX, -64);
      expect(border.originZ, -16);
      expect(border.instances, isNotEmpty);
      expect(
        exterior.current!.sectors.expand(
          (v) => v.layers.whereType<BorderLayer>(),
        ),
        isEmpty,
      );
      exterior.undo();
      expect(exterior.current!.borders, isEmpty);
      exterior.redo();
      expect(exterior.current!.borders.single, border);
      view.borderEditingMode = BorderStrokeEditingMode.erase;
      view.borderFeature = (layerId: border.layerId, featureId: border.id);
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
      scene().onDragEnd!();
      await tester.pumpWidget(canvas());
      expect(
        exterior.current!.borders.single.feature.geometry,
        isNot(border.feature.geometry),
      );
      expect(document.current, same(map));
      await tester.pumpWidget(const SizedBox());
    },
  );
}

final class _Port implements MapExteriorDecorationPort {
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => const MapExteriorDecorationState(decoration: null, revision: 'r0');
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Visuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String id) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String id) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

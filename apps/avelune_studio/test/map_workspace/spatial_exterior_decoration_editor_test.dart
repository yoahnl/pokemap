import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';
import 'spatial_exterior_decoration_editor_support.dart';

void main() {
  testWidgets('exterior model properties round trip through map coordinates', (
    tester,
  ) async {
    final project = spatialEnvironmentProject();
    final map = spatialEnvironmentMap();
    final exterior = await MapExteriorDecorationController.open(
      workspaceSession,
      map,
      ExteriorPort(),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..exteriorDecoration = exterior;
    final view = MapEditingViewportSession();
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
    final commands = SpatialModelEditingCommands(target, project);
    expect(instance.position.x + exterior.originX, -2.5);
    expect(instance.position.z + exterior.originZ, 2.5);
    commands.update(instance.id, x: -3.5 - exterior.originX);
    expect(
      target.current.spatialScene!.instances.single.position.x +
          exterior.originX,
      -3.5,
    );
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    expect(exterior.canUndo, isTrue);
  });

  test(
    'switching to exterior resets unsupported tools without map writes',
    () async {
      final map = spatialEnvironmentMap();
      final exterior = await MapExteriorDecorationController.open(
        workspaceSession,
        map,
        ExteriorPort(),
      );
      final view = MapEditingViewportSession()..tool = StudioMapTool.character;
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      view.prepareExteriorEditing(true);
      exterior.setEditingExterior(true);
      expect(exterior.editingExterior, isTrue);
      expect(view.tool, StudioMapTool.select);
      expect(exterior.editingDocument, isNull);
      expect(exterior.current!.sectors, isEmpty);
      exterior.configureMargins(west: 0, east: 0, north: 0, south: 0);
      expect(exterior.current!.sectors, isEmpty);
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

  test('exterior editing document follows the selected sector', () async {
    final map = spatialEnvironmentMap();
    final exterior = await MapExteriorDecorationController.open(
      workspaceSession,
      map,
      ExteriorPort(),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    )..exteriorDecoration = exterior;
    addTearDown(exterior.dispose);
    exterior.setEditingExterior(true);
    expect(exterior.editingDocument, isNull);
    exterior.selectAt(-1, 1);
    expect(exterior.editingDocument, isNotNull);
    expect(exterior.editingDocument, isNot(same(document)));
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    exterior.setEditingExterior(false);
    expect(exterior.editingExterior, isFalse);
  });
}

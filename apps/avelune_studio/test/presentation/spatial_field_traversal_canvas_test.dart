import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('native 3D canvas shows movement and encounter zones', (
    tester,
  ) async {
    final project = spatialEnvironmentProject();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: spatialEnvironmentMap().copyWith(
          gameplayZones: const [
            MapGameplayZone(
              id: 'grass',
              name: 'Herbes',
              kind: GameplayZoneKind.encounter,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 3, height: 3),
              ),
              cellMask: [GridPos(x: 0, y: 0), GridPos(x: 2, y: 1)],
              encounter: EncounterZonePayload(),
            ),
          ],
        ),
        mapId: 'a',
        revision: 'initial',
      ),
    );
    final controller =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    final view = MapEditingViewportSession()
      ..tool = StudioMapTool.gameplayZone
      ..zoneKind = GameplayZoneKind.movement
      ..revealedZones = const {GameplayZoneKind.encounter};
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: _Visuals(),
              view: view,
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    SpatialSceneView scene() =>
        tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    Iterable<SpatialCellOverlay> zone(String id) => scene().cellOverlays
        .where((cell) => cell.id.startsWith('zone:$id:'));

    expect(zone('grass').map((cell) => cell.cell), unorderedEquals([(1, 1), (3, 2)]));

    expect(scene().onDragStart!(6, 2, null), isTrue, reason: document.error);
    scene().onDragUpdate!((7, 3));
    scene().onDragEnd!();
    await tester.pump();
    final drawn = document.current.gameplayZones.last;
    expect(drawn.kind, GameplayZoneKind.movement);
    expect(zone(drawn.id), hasLength(4));
    final colors = Theme.of(
      tester.element(find.byType(SpatialSceneView)),
    ).colorScheme;
    expect(zone(drawn.id).map((cell) => cell.color).toSet(), {colors.primary});
    expect(zone('grass').map((cell) => cell.color).toSet(), {colors.secondary});

    view.revealedZones = const {};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: project,
            visuals: _Visuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    expect(zone('grass'), isEmpty);
    expect(zone(drawn.id), hasLength(4));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'native 3D canvas draws selects previews and cancels an editable field route',
    (tester) async {
      final project = spatialEnvironmentProject();
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: spatialEnvironmentMap(),
          mapId: 'a',
          revision: 'initial',
        ),
      );
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.gameplayZone
        ..zoneKind = GameplayZoneKind.fieldAction;
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SpatialMapEditingViewport(
                document: document,
                controller: controller,
                project: project,
                visuals: _Visuals(),
                view: view,
                onChanged: () => refresh(() {}),
              ),
            ),
          ),
        ),
      );
      SpatialSceneView scene() =>
          tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene().onDragStart!(2, 3, null), isTrue, reason: document.error);
      scene().onDragUpdate!((5, 3));
      await tester.pump();
      expect(
        scene().cellOverlays.where(
          (cell) => cell.id.startsWith('field-zone-draft:'),
        ),
        hasLength(4),
      );
      scene().onDragEnd!();
      await tester.pump();
      expect(document.error, isNull);
      final zone = document.current.gameplayZones.single;
      expect(zone.fieldAction!.waterfall, isNotNull);
      expect(zone.area.size, const GridSize(width: 4, height: 1));
      expect(view.selectedFor('a', MapSelectionFamily.zone), zone.id);
      expect(
        scene().cellOverlays.where(
          (cell) => cell.id.startsWith('field-route:'),
        ),
        hasLength(3),
      );
      expect(scene().onDragStart!(2, 3, null), isTrue);
      scene().onDragEnd!();
      expect(document.current.gameplayZones, hasLength(1));
      expect(scene().onDragStart!(6, 3, null), isTrue);
      scene().onDragUpdate!((8, 3));
      scene().onDragCancel!();
      expect(document.current.gameplayZones, hasLength(1));
      expect(scene().onDragStart!(8, 7, null), isTrue);
      scene().onDragEnd!();
      expect(document.error, contains('trois cases'));
      expect(document.current.gameplayZones, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _Visuals extends WorkspaceTestVisuals implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_border_commands_test.dart'
    show borderDocument, borderDraft;
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  testWidgets(
    'native trace previews real units then Enter commits once and Escape discards',
    (tester) async {
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final document = borderDocument(map);
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.border
        ..borderBlueprintId = 'fence';
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
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
                visuals: _BorderVisuals(),
                view: view,
                onChanged: () => refresh(() {}),
              ),
            ),
          ),
        ),
      );
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      scene().onCell(2, 5);
      await tester.pump();
      scene().onHover!(
        SpatialSurfaceHit(
          position: Model3dVector3(x: 5.5, y: 2, z: 5.5),
          cell: (5, 5),
        ),
      );
      await tester.pump();
      expect(scene().scene.instances, hasLength(4));
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      scene().onCell(5, 5);
      await tester.pump();
      scene().onCell(5, 7);
      await tester.pump();
      final preview = scene().scene;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(view.borderDraft, isNull);
      expect(document.current.spatialScene, preview);
      expect(document.undoCount, 1);
      final applied = document.current;
      scene().onCell(7, 2);
      scene().onCell(9, 2);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(view.borderDraft, isNull);
      expect(document.current, same(applied));
      expect(document.undoCount, 1);
      final id = applied.spatialScene!.instances.first.id;
      view.tool = StudioMapTool.select;
      await tester.pump();
      final hit = SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: id,
        cell: (2, 5),
      );
      expect(scene().onDragStart!(2, 5, hit), isFalse);
      expect(
        document.error,
        SpatialModelEditingCommands.generatedBorderMessage,
      );
      expect(
        view.borderFeature,
        SpatialModelEditingCommands(document, project).borderOwner(id),
      );
      expect(document.undoCount, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native trace rejects source and camera changes without writes', (
    tester,
  ) async {
    final project = spatialBorderProject();
    final document = borderDocument(spatialBorderMap());
    final view = MapEditingViewportSession()
      ..tool = StudioMapTool.border
      ..borderBlueprintId = 'fence';
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    VoidCallback rebuild = () {};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) {
              rebuild = () => refresh(() {});
              return SpatialMapEditingViewport(
                document: document,
                controller: controller,
                project: project,
                visuals: _BorderVisuals(),
                view: view,
                onChanged: rebuild,
              );
            },
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    scene().onCell(2, 5);
    scene().onCell(5, 5);
    view.spatialFreeView = true;
    rebuild();
    await tester.pump();
    expect(view.borderDraft, isNull);
    expect(document.undoCount, 0);
    scene().onCell(2, 5);
    scene().onCell(5, 5);
    document.commit(document.current.copyWith(name: 'Révision suivante'));
    rebuild();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(view.borderDraft, isNull);
    expect(document.undoCount, 1);
    expect(document.current.layers.whereType<BorderLayer>(), isEmpty);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'regeneration preview cancel apply and feature removal stay explicit',
    (tester) async {
      final project = spatialBorderProject(
        anchor: Model3dVector3(x: .1, y: 0, z: 0),
      );
      final map = spatialBorderMap();
      final document = borderDocument(map);
      MapBorderEditingCommands(
        document,
        project,
      ).finish(borderDraft(map, project));
      final source = document.current;
      final changed = project.copyWith(
        models3d: [project.models3d.single.copyWith(scale: 2)],
      );
      final commands = MapBorderEditingCommands(document, changed);
      final feature = commands.visibleFeatures.single;
      final status = commands.regenerationStatus(
        layerId: feature.layer.id,
        featureId: feature.feature.id,
      );
      expect(status.stale, isTrue);
      final preview = commands.prepareExisting(
        layerId: feature.layer.id,
        featureId: feature.feature.id,
      );
      expect(preview.result.spatialScene, isNot(source.spatialScene));
      expect(document.current, same(source));
      expect(document.undoCount, 1);
      commands.applyRegeneration(preview);
      expect(document.current, preview.result);
      expect(document.undoCount, 2);
      commands.delete(layerId: feature.layer.id, featureId: feature.feature.id);
      expect(document.current.spatialScene!.instances, isEmpty);
      expect(document.undoCount, 3);
    },
  );

  testWidgets(
    'an authored native border without generated units can prepare and apply its first preview',
    (tester) async {
      final project = spatialBorderProject();
      final map = spatialBorderMap();
      final draft = borderDraft(map, project);
      final source = upsertBorderFeature(
        addBorderLayer(map, id: 'border', name: 'Clôtures'),
        layerId: 'border',
        feature: BorderFeature(
          id: 'unmaterialized',
          name: 'Clôture préparée',
          blueprintId: 'fence',
          seed: draft.seed,
          geometry: BorderStrokeGeometry(strokes: [draft.stroke]),
          overrides: const [],
          keepOutRegions: const [],
        ),
        template: BorderBlueprintTemplate.connectedLine,
      );
      final document = borderDocument(source);
      final commands = MapBorderEditingCommands(document, project);
      final preview = commands.prepareExisting(
        layerId: 'border',
        featureId: 'unmaterialized',
      );
      expect(document.current, same(source));
      expect(preview.result.spatialScene!.instances, hasLength(6));
      commands.applyRegeneration(preview);
      expect(document.current.spatialScene!.instances, hasLength(6));
      expect(document.undoCount, 1);
    },
  );
}

class _BorderVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

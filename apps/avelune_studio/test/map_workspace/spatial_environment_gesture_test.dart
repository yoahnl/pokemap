import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets(
    'the existing environment and border tools are enabled in spatial maps',
    (tester) async {
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapWorkspaceToolStrip(
              view: view,
              onChanged: () {},
              onMoreTools: () {},
              onResources: () {},
              storyAvailable: false,
              paletteVisible: true,
              spatial: true,
              onUndo: null,
              onRedo: null,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<StudioButton>(find.widgetWithText(StudioButton, 'Bordures'))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Environnements'));
      expect(view.tool, StudioMapTool.environment);
      expect(view.paletteTab, 'Environnements');
    },
  );

  testWidgets(
    'spatial strokes preview exact cells, commit once and render generation',
    (tester) async {
      var project = spatialEnvironmentProject();
      final map = spatialEnvironmentMap();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
      );
      final commands = EnvironmentEditingCommands(document, project);
      final first = commands.create(project.environmentPresets.single);
      final second = commands.create(project.environmentPresets.single);
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.environment
        ..environment = first;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      final visuals = _SpatialVisuals();
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
      final source = document.current;
      final history = document.undoCount;
      expect(scene().onDragStart!(2, 5, null), isTrue);
      scene().onDragUpdate!((5, 5));
      expect(document.current, same(source));
      await tester.pumpWidget(canvas());
      expect(
        scene().cellOverlays
            .where((cell) => cell.id.startsWith('environment-stroke:'))
            .map((cell) => cell.cell),
        [(2, 5), (3, 5), (4, 5), (5, 5)],
      );
      scene().onDragEnd!();
      expect(document.undoCount, history + 1);
      expect(commands.area(first)!.mask.activeCellCount, 4);
      commands.preview(first);
      await tester.pumpWidget(canvas());
      expect(scene().scene.instances, hasLength(4));
      expect(document.current.spatialScene!.instances, isEmpty);
      commands.apply(first);
      document.restore(redo: false);
      expect(document.current.spatialScene!.instances, isEmpty);
      document.restore(redo: true);
      expect(document.current.spatialScene!.instances, hasLength(4));
      first.tool = EnvironmentPaintTool.erase;
      await tester.pumpWidget(canvas());
      scene().onCell(3, 5);
      expect(commands.area(first)!.mask.isActiveAt(3, 5), isFalse);
      commands.preview(first);
      commands.apply(first);
      expect(document.current.spatialScene!.instances, hasLength(3));
      first.tool = EnvironmentPaintTool.rectangle;
      await tester.pumpWidget(canvas());
      expect(scene().onDragStart!(7, 2, null), isTrue);
      scene().onDragUpdate!((8, 3));
      scene().onDragEnd!();
      expect(commands.area(first)!.mask.activeCellCount, 7);
      final committed = document.current;
      for (final change in <VoidCallback>[
        () => view.environment = second,
        () => first.tool = EnvironmentPaintTool.brush,
        () => view.tool = StudioMapTool.select,
        () => view.spatialFreeView = true,
        () => project = project.copyWith(name: 'Projet rechargé'),
      ]) {
        view
          ..environment = first
          ..tool = StudioMapTool.environment
          ..spatialFreeView = false;
        first.tool = EnvironmentPaintTool.rectangle;
        await tester.pumpWidget(canvas());
        expect(scene().onDragStart!(1, 1, null), isTrue);
        scene().onDragUpdate!((4, 4));
        change();
        await tester.pumpWidget(canvas());
        scene().onDragEnd!();
        expect(document.current, same(committed));
      }
      view
        ..environment = first
        ..tool = StudioMapTool.environment
        ..spatialFreeView = false;
      await tester.pumpWidget(canvas());
      expect(scene().onDragStart!(1, 1, null), isTrue);
      scene().onDragUpdate!((4, 4));
      document.commit(document.current.copyWith(name: 'Édition indépendante'));
      final renamed = document.current;
      scene().onDragEnd!();
      expect(document.current, same(renamed));
      expect(scene().onDragStart!(1, 1, null), isTrue);
      scene().onDragUpdate!((4, 4));
      scene().onDragCancel!();
      expect(document.current, same(renamed));
      expect(scene().onDragStart!(-1, 1, null), isFalse);
    },
  );
}

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

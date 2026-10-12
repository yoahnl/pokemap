import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
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
  for (final (size, scale) in [
    (const Size(1024, 640), 1.0),
    (const Size(1440, 900), 1.0),
    (const Size(1024, 640), 1.5),
  ]) {
    testWidgets(
      '3D border draft keeps viewport and pointer alignment $size $scale',
      (tester) async {
        final fixture = await _mount(tester, size: size, scale: scale);
        final editor = tester.getRect(find.byType(SpatialMapEditor));
        final viewport = tester.getRect(find.byType(SpatialSceneView));
        final pointer = viewport.topLeft + viewport.size.center(Offset.zero);
        final local = tester
            .renderObject<RenderBox>(find.byType(SpatialSceneView))
            .globalToLocal(pointer);
        fixture.scene(tester).onSurfaceTap!(
          SpatialSurfaceHit(
            cell: (2, 6),
            position: Model3dVector3(x: 2.5, y: 0, z: 6.5),
          ),
        );
        await tester.pump();
        expect(tester.getRect(find.byType(SpatialMapEditor)), editor);
        expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
        expect(
          tester
              .renderObject<RenderBox>(find.byType(SpatialSceneView))
              .globalToLocal(pointer),
          local,
        );
        expect(find.text('Créer un autre modèle'), findsNothing);
        expect(find.text('Terminer le tracé'), findsOneWidget);
        fixture.scene(tester).onCell(8, 6);
        await tester.pump();
        expect(tester.getRect(find.byType(SpatialMapEditor)), editor);
        expect(fixture.view.borderDraft!.anchors, [
          const GridPos(x: 2, y: 6),
          const GridPos(x: 8, y: 6),
        ]);
        expect(fixture.document.dirty, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
        expect(fixture.view.borderDraft, isNull);
        expect(fixture.document.undoCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'refused 3D border stays in the footer without moving the viewport',
    (tester) async {
      final fixture = await _mount(tester);
      final source = fixture.document.current;
      final viewport = tester.getRect(find.byType(SpatialSceneView));
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final failure = fixture.document.error;
      expect(
        failure,
        contains('border.spatial.straight_only_geometry_required'),
      );
      expect(_notices(failure!), findsOneWidget);
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      expect(fixture.document.current, same(source));
      expect(fixture.document.undoCount, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(fixture.document.error, isNull);
      expect(fixture.view.borderDraft, isNull);
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      expect(_notices(failure), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Escape preserves a later non-border document error', (
    tester,
  ) async {
    final fixture = await _mount(tester);
    fixture.scene(tester).onCell(2, 6);
    fixture.scene(tester).onCell(8, 8);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    fixture.document.error = 'Échec de sauvegarde distinct';
    fixture.refresh();
    await tester.pump();
    expect(_notices('Échec de sauvegarde distinct'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fixture.document.error, 'Échec de sauvegarde distinct');
    expect(_notices('Échec de sauvegarde distinct'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'finish button and hover retain one owned refusal until an angle is removed',
    (tester) async {
      final fixture = await _mount(tester, size: const Size(1440, 900));
      final viewport = tester.getRect(find.byType(SpatialSceneView));
      final source = fixture.document.current;
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.ensureVisible(find.text('Terminer le tracé'));
      await tester.tap(find.text('Terminer le tracé'));
      await tester.pump();
      final failure = fixture.document.error!;
      expect(_notices(failure), findsOneWidget);
      fixture.scene(tester).onHover!(
        SpatialSurfaceHit(
          cell: (9, 8),
          position: Model3dVector3(x: 9.5, y: 0, z: 8.5),
        ),
      );
      await tester.pump();
      expect(_notices(failure), findsOneWidget);
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      await tester.ensureVisible(find.text('Retirer le dernier angle'));
      await tester.tap(find.text('Retirer le dernier angle'));
      await tester.pump();
      expect(fixture.document.error, isNull);
      expect(fixture.view.borderDraft!.anchors, hasLength(1));
      expect(tester.getRect(find.byType(SpatialSceneView)), viewport);
      expect(fixture.document.current, same(source));
      expect(fixture.document.undoCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel button clears its refusal while retaining a different error',
    (tester) async {
      final fixture = await _mount(tester, size: const Size(1440, 900));
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      fixture.document.error = 'Échec de sauvegarde après le refus';
      fixture.refresh();
      await tester.pump();
      await tester.ensureVisible(find.text('Annuler le tracé'));
      await tester.tap(find.text('Annuler le tracé'));
      await tester.pump();
      expect(fixture.view.borderDraft, isNull);
      expect(fixture.document.error, 'Échec de sauvegarde après le refus');
      expect(_notices('Échec de sauvegarde après le refus'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a corrected border finishes after a refusal with no lingering error',
    (tester) async {
      final fixture = await _mount(tester, size: const Size(1440, 900));
      final source = fixture.document.current;
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fixture.document.error, isNotNull);
      await tester.ensureVisible(find.text('Retirer le dernier angle'));
      await tester.tap(find.text('Retirer le dernier angle'));
      await tester.pump();
      fixture.scene(tester).onCell(8, 6);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(fixture.document.current, isNot(same(source)));
      expect(fixture.document.current.spatialScene!.instances, isNotEmpty);
      expect(fixture.document.error, isNull);
      expect(fixture.view.borderDraftFailure, isNull);
      expect(fixture.view.borderDraft, isNull);
      expect(fixture.document.undoCount, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controller errors stay globally visible during a refused border',
    (tester) async {
      final fixture = await _mount(tester);
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      fixture.controller.error = 'Impossible de charger le projet';
      fixture.refresh();
      await tester.pump();
      expect(_notices('Impossible de charger le projet'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(fixture.controller.error, 'Impossible de charger le projet');
      expect(_notices('Impossible de charger le projet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('2D keeps its wrapping actions and global error notice', (
    tester,
  ) async {
    final fixture = await _mount(tester, spatial: false);
    final map = fixture.document.current;
    fixture.view.borderDraft = MapBorderDrawingDraft.start(
      mapId: map.id,
      mapSize: map.size,
      blueprintId: 'muret',
      origin: const GridPos(x: 2, y: 6),
    ).addAngle(const GridPos(x: 8, y: 6));
    fixture.document.error = 'Erreur 2D conservée';
    fixture.refresh();
    await tester.pump();
    expect(find.byType(MapWorkspaceCanvas), findsOneWidget);
    expect(find.byType(SpatialMapEditor), findsNothing);
    expect(find.text('Créer un autre modèle'), findsOneWidget);
    expect(find.text('Terminer le tracé'), findsOneWidget);
    expect(_notices('Erreur 2D conservée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a controller failure with the same text is not owned by the draft',
    (tester) async {
      final fixture = await _mount(tester);
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final failure = fixture.document.error!;
      fixture.controller.error = failure;
      fixture.refresh();
      await tester.pump();
      expect(_notices(failure), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(fixture.controller.error, failure);
      expect(_notices(failure), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a draft error remains visible when the resources replace the editor',
    (tester) async {
      final fixture = await _mount(tester);
      fixture.scene(tester).onCell(2, 6);
      fixture.scene(tester).onCell(8, 8);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final failure = fixture.document.error!;
      tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .onResources();
      await tester.pump();
      expect(find.byType(SpatialSceneView), findsNothing);
      expect(_notices(failure), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _notices(String message) => find.byWidgetPredicate(
  (widget) => widget is StudioNotice && widget.message == message,
);

Future<_Fixture> _mount(
  WidgetTester tester, {
  Size size = const Size(1024, 640),
  double scale = 1,
  bool spatial = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = spatial
      ? spatialBorderProject(straightOnly: true)
      : workspaceProject.copyWith(borderCatalog: testBorderCatalog());
  final map = spatial
      ? MapData(
          id: 'a',
          name: 'Atelier vierge',
          version: ProjectVersion.v9,
          size: const GridSize(width: 16, height: 16),
          spatialScene: MapSpatialScene(width: 16, depth: 16),
        )
      : workspaceMap('a');
  final document = borderDocument(map);
  final controller =
      MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project
        ..active = document;
  controller.documents[map.id] = document;
  final view = MapWorkspaceViewState()
    ..tool = StudioMapTool.border
    ..borderBlueprintId = spatial ? 'fence' : 'muret';
  final search = TextEditingController();
  final homeSearch = TextEditingController();
  addTearDown(controller.dispose);
  addTearDown(view.dispose);
  addTearDown(search.dispose);
  addTearDown(homeSearch.dispose);
  late VoidCallback refresh;
  var resourcesOpen = false;
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, update) {
          refresh = () => update(() {});
          return MapWorkspaceLayout(
            activeSpace: resourcesOpen ? 'resources' : 'map',
            resourceContent: resourcesOpen ? const SizedBox.expand() : null,
            controller: controller,
            view: view,
            visuals: _Visuals(),
            search: search,
            homeSearch: homeSearch,
            error: controller.error ?? document.error,
            palette: true,
            inspector: false,
            generation: 0,
            onPalette: () {},
            onInspector: () {},
            onChanged: refresh,
            onToolChanged: refresh,
            onActivate: (_) {},
            onSave: () {},
            onTest: () {},
            onClose: () {},
            onResources: () {
              resourcesOpen = true;
              refresh();
            },
            onMap: () {},
            onExport: () {},
            onPokemon: () {},
            onOpenElement: (_) {},
            onEditElement: (_) {},
          );
        },
      ),
    ),
  );
  await tester.pump();
  return _Fixture(document, controller, view, refresh);
}

class _Fixture {
  _Fixture(this.document, this.controller, this.view, this.refresh);
  final EditableMapDocument document;
  final MapWorkspaceController controller;
  final MapWorkspaceViewState view;
  final VoidCallback refresh;
  SpatialSceneView scene(WidgetTester tester) =>
      tester.widget(find.byType(SpatialSceneView));
}

class _Visuals extends WorkspaceTestVisuals implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async =>
      throw StateError('Layout fixture');
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

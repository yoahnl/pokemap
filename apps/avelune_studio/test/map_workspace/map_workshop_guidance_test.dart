import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  test('fit keeps the complete map inside the available viewport', () {
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    const viewport = Size(1000, 700);
    const content = Size(1000, 800);
    view.fitViewport(viewport, content);
    final matrix = view.transform.value;
    final left = matrix.entry(0, 3), top = matrix.entry(1, 3);
    expect(left, greaterThanOrEqualTo(0));
    expect(top, greaterThanOrEqualTo(0));
    expect(
      left + content.width * view.scale,
      lessThanOrEqualTo(viewport.width),
    );
    expect(
      top + content.height * view.scale,
      lessThanOrEqualTo(viewport.height),
    );
  });

  testWidgets('tool panels resize the fitted viewport without clipping', (
    tester,
  ) async {
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    const content = Size(2048, 1664);
    void attach(Size viewport) => view.attachViewport(
      viewport,
      content,
      const Size(32, 32),
      mounted: () => true,
    );
    attach(const Size(904, 229));
    tester.binding.scheduleFrame();
    await tester.pump();
    attach(const Size(904, 181));
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(content.height * view.scale, lessThanOrEqualTo(181));
    expect(view.transform.value.entry(1, 3), greaterThanOrEqualTo(0));
    view.transform.value = view.transform.value.clone()
      ..translateByDouble(12, 15, 0, 1)
      ..scaleByDouble(2, 2, 1, 1);
    final manual = view.transform.value.clone();
    attach(const Size(904, 300));
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(view.transform.value.storage, manual.storage);
    view.recenter!();
    expect(content.height * view.scale, lessThanOrEqualTo(300));
    attach(const Size(904, 200));
    attach(const Size(904, 170));
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(content.height * view.scale, closeTo(170, .001));
  });

  testWidgets(
    'terrain highlight is available without grid and without mutating the map',
    (tester) async {
      final draft = terrainDraft();
      assignAll(draft);
      final project = publishFixture(draft);
      final preset = project.smartTileCatalog.presets.single;
      final map = applyTerrainStroke(
        map: workspaceMap('a'),
        manifest: project,
        preset: preset,
        cells: [const GridPos(x: 2, y: 2), const GridPos(x: 4, y: 2)],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
      );
      final view = MapEditingViewportSession()
        ..terrain = preset
        ..tool = StudioMapTool.terrain;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapEditingViewport2D(
              document: document,
              project: project,
              visuals: WorkspaceTestVisuals(),
              view: view,
              onChanged: () {},
              gestureGeneration: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(view.grid, isFalse);
      expect(find.byKey(const ValueKey('terrain-highlight')), findsOneWidget);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(document.undoCount, 0);
    },
  );

  testWidgets('an empty map remains bounded when the grid is disabled', (
    tester,
  ) async {
    final map = workspaceMap('a').copyWith(layers: []);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: 'a'),
    );
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapEditingViewport2D(
            document: document,
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            view: view,
            onChanged: () {},
            gestureGeneration: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-surface-bounds')), findsOneWidget);
    expect(
      find.text(
        'Carte vide · choisissez un terrain ou un décor dans la palette.',
      ),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('map-surface-bounds'))),
      const Size(640, 512),
    );
    expect(document.current, same(map));
  });
}

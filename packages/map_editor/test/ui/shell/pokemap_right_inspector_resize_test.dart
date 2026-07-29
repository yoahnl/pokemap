import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage right inspector resize', () {
    testWidgets(
        'starts at the session token and clamps mouse resizing to 280-560 px',
        (tester) async {
      final container =
          await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      expect(tester.getSize(region).width, 360);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        360,
      );
      expect(tester.takeException(), isNull, reason: 'initial width');

      await _dragHandle(tester, handle, -100);
      expect(tester.getSize(region).width, 460);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        460,
      );
      expect(tester.takeException(), isNull, reason: '460 px width');

      await _dragHandle(tester, handle, -400);
      expect(tester.getSize(region).width, 560);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        560,
      );
      expect(tester.takeException(), isNull, reason: '560 px width');

      await _dragHandle(tester, handle, 500);
      expect(tester.getSize(region).width, 280);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorWidth,
        280,
      );
      expect(tester.takeException(), isNull, reason: '280 px width');
    });

    testWidgets('keeps the chosen width after hide and reopen', (tester) async {
      final container =
          await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      await _dragHandle(tester, handle, -60);
      expect(tester.getSize(region).width, 420);

      await tester.tap(find.bySemanticsLabel('Hide right panel').first);
      await tester.pumpAndSettle();
      expect(region, findsNothing);
      expect(
        container.read(worldMapWorkspaceSessionProvider).inspectorVisible,
        isFalse,
      );

      await tester.tap(find.bySemanticsLabel('Show right panel').first);
      await tester.pumpAndSettle();
      expect(tester.getSize(region).width, 420);
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((state) => state.inspectorVisible, 'visible', isTrue)
            .having((state) => state.inspectorWidth, 'width', 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands to the maximum when the map explorer is collapsed',
        (tester) async {
      final container =
          await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      expect(tester.getSize(region).width, 360);

      await tester.tap(
        find.byKey(const ValueKey<String>('project-explorer-toggle')),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(region).width, 560);
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        isA<WorldMapWorkspaceSession>()
            .having((state) => state.explorerExpanded, 'explorer', isFalse)
            .having((state) => state.inspectorWidth, 'width', 560),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses an overlay without a resize handle at compact width',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1000, 800),
      );

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      expect(tester.getSize(region).width, 360);
      expect(handle, findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-overlay'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps non-map inspector state local and unchanged',
        (tester) async {
      final state = _editorState().copyWith(
        workspaceMode: EditorWorkspaceMode.tileset,
        selectedTilesetEditorId: 'tileset-a',
        project: buildShellChromeProject(
          tilesets: const <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'tileset-a',
              name: 'Tileset A',
              relativePath: 'tilesets/tileset-a.json',
            ),
          ],
        ),
      );
      final container = await pumpEditorShellPage(tester, initialState: state);

      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('right-inspector-region'),
              ),
            )
            .width,
        336,
      );
      expect(
        container.read(worldMapWorkspaceSessionProvider),
        const WorldMapWorkspaceSession(),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _dragHandle(
  WidgetTester tester,
  Finder handle,
  double delta,
) async {
  await tester.drag(
    handle,
    Offset(delta, 0),
    touchSlopX: 0,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
}

EditorState _editorState() {
  final map = buildShellChromeMap(
    id: 'resize_map',
    name: 'Resize Map',
    width: 8,
    height: 8,
    layers: const <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tiles: <int>[],
      ),
    ],
  );
  return EditorState(
    projectRootPath: '/tmp/right_inspector_resize_test',
    project: buildShellChromeProject(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'resize_map',
          name: 'Resize Map',
          relativePath: 'maps/resize_map.json',
        ),
      ],
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}

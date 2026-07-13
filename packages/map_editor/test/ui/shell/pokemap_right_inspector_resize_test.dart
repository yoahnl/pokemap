import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage right inspector resize', () {
    testWidgets('starts at 336 px and clamps mouse resizing to 280-560 px',
        (tester) async {
      await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      expect(tester.getSize(region).width, 336);
      expect(tester.takeException(), isNull, reason: 'initial width');

      await _dragHandle(tester, handle, -100);
      expect(tester.getSize(region).width, 436);
      expect(tester.takeException(), isNull, reason: '436 px width');

      await _dragHandle(tester, handle, -400);
      expect(tester.getSize(region).width, 560);
      expect(tester.takeException(), isNull, reason: '560 px width');

      await _dragHandle(tester, handle, 500);
      expect(tester.getSize(region).width, 280);
      expect(tester.takeException(), isNull, reason: '280 px width');
    });

    testWidgets('keeps the chosen width after hide and reopen', (tester) async {
      await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      final handle = find.byKey(
        const ValueKey<String>('right-inspector-resize-handle'),
      );
      await _dragHandle(tester, handle, -84);
      expect(tester.getSize(region).width, 420);

      await tester.tap(find.bySemanticsLabel('Hide right panel').first);
      await tester.pumpAndSettle();
      expect(region, findsNothing);

      await tester.tap(find.bySemanticsLabel('Show right panel').first);
      await tester.pumpAndSettle();
      expect(tester.getSize(region).width, 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expands to the maximum when the map explorer is collapsed',
        (tester) async {
      await pumpEditorShellPage(tester, initialState: _editorState());

      final region = find.byKey(
        const ValueKey<String>('right-inspector-region'),
      );
      expect(tester.getSize(region).width, 336);

      await tester.tap(
        find.byKey(const ValueKey<String>('project-explorer-toggle')),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(region).width, 560);
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps width to preserve 320 px of center stage',
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
      expect(tester.getSize(region).width, 324);

      await _dragHandle(tester, handle, -400);
      expect(tester.getSize(region).width, 324);
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

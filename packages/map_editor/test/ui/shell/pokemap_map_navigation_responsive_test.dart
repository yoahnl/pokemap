import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('Map canvas navigation responsive shell layout', () {
    testWidgets('keeps every compact action visible and usable at 800x600',
        (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(800, 600),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      _expectAdaptiveWorkspace(tester, inspectorIsOverlay: true);
      _expectNavigationActionsDiscoverable();

      await tester.tap(_navigationAction('map-navigation-zoom-out'));
      await tester.pump();

      expect(
        container.read(editorNotifierProvider).zoom,
        closeTo(1 / 1.2, 1e-6),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps every compact action visible at 1280x800',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1280, 800),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      _expectAdaptiveWorkspace(tester, inspectorIsOverlay: false);
      _expectNavigationActionsDiscoverable();
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps every action inside the narrow 1000x800 breakpoint',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1000, 800),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      _expectNavigationActionsDiscoverable();
      expect(tester.takeException(), isNull);
    });

    testWidgets('retains labelled actions when the canvas is wide',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: _editorState(),
        surfaceSize: const Size(1800, 900),
      );

      _expectAllNavigationActionsInsideCanvas(tester);
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-fit'),
          matching: find.text('Ajuster'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-actual-size'),
          matching: find.text('100 %'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _navigationAction('map-navigation-center'),
          matching: find.text('Centrer'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Finder _navigationAction(String key) {
  return find.byKey(ValueKey<String>(key));
}

void _expectNavigationActionsDiscoverable() {
  for (final action in const <({
    String key,
    String tooltip,
    String label,
  })>[
    (
      key: 'map-navigation-fit',
      tooltip: 'Ajuster la carte',
      label: 'Ajuster',
    ),
    (
      key: 'map-navigation-actual-size',
      tooltip: 'Afficher à 100 %',
      label: '100 %',
    ),
    (
      key: 'map-navigation-center',
      tooltip: 'Centrer la carte',
      label: 'Centrer',
    ),
  ]) {
    final tooltip = find.byTooltip(action.tooltip);
    if (tooltip.evaluate().isNotEmpty) {
      expect(tooltip, findsOneWidget);
    } else {
      expect(
        find.descendant(
          of: _navigationAction(action.key),
          matching: find.text(action.label),
        ),
        findsOneWidget,
      );
    }
  }
}

void _expectAllNavigationActionsInsideCanvas(WidgetTester tester) {
  final canvasRect = tester.getRect(find.byType(MapCanvas));
  for (final key in const <String>[
    'map-navigation-zoom-out',
    'map-navigation-zoom-in',
    'map-navigation-fit',
    'map-navigation-actual-size',
    'map-navigation-center',
  ]) {
    final actionRect = tester.getRect(_navigationAction(key));
    expect(
      actionRect.left,
      greaterThanOrEqualTo(canvasRect.left),
      reason: '$key must not be clipped on the left',
    );
    expect(
      actionRect.right,
      lessThanOrEqualTo(canvasRect.right),
      reason: '$key must not be clipped on the right',
    );
    expect(
      actionRect.top,
      greaterThanOrEqualTo(canvasRect.top),
      reason: '$key must not be clipped at the top',
    );
    expect(
      actionRect.bottom,
      lessThanOrEqualTo(canvasRect.bottom),
      reason: '$key must not be clipped at the bottom',
    );
  }
}

void _expectAdaptiveWorkspace(
  WidgetTester tester, {
  required bool inspectorIsOverlay,
}) {
  expect(
    find.byKey(const ValueKey<String>('world-map-workspace')),
    findsOneWidget,
  );
  expect(
    tester
        .getSize(
          find.byKey(
            const ValueKey<String>('world-map-canvas-region'),
          ),
        )
        .width,
    greaterThanOrEqualTo(320),
  );
  expect(
    find.byKey(
      ValueKey<String>(
        inspectorIsOverlay
            ? 'world-map-inspector-overlay'
            : 'world-map-inspector-dock',
      ),
    ),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
}

EditorState _editorState() {
  final map = buildShellChromeMap(
    id: 'responsive_navigation_map',
    name: 'Map',
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
    projectRootPath: '/tmp/responsive_navigation_map',
    project: buildShellChromeProject(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'responsive_navigation_map',
          name: 'Map',
          relativePath: 'maps/responsive_navigation_map.json',
        ),
      ],
    ),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeLayerId: 'ground',
    savedMapSnapshot: map,
  );
}

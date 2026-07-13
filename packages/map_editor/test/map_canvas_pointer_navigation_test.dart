import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('MapCanvas pointer navigation', () {
    for (final kind in <ui.PointerDeviceKind>[
      ui.PointerDeviceKind.mouse,
      ui.PointerDeviceKind.trackpad,
    ]) {
      testWidgets(
        'scroll pans naturally for ${kind.name} without zooming or editing',
        (tester) async {
          final container = _createContainer();
          const map = _activeMap;
          container.read(editorNotifierProvider.notifier).state =
              const EditorState(
            project: _project,
            activeMap: map,
            activeLayerId: 'ground',
            savedMapSnapshot: map,
            panOffset: Offset(10, 20),
            zoom: 1.25,
          );

          await _pumpCanvas(tester, container);

          final canvasCenter = tester.getCenter(find.byType(MapCanvas));
          tester.binding.handlePointerEvent(
            PointerScrollEvent(
              position: canvasCenter,
              kind: kind,
              scrollDelta: const Offset(24, -16),
            ),
          );
          await tester.pump();

          final state = container.read(editorNotifierProvider);
          expect(state.panOffset, const Offset(-14, 36));
          expect(state.zoom, 1.25);
          expect(state.activeMap, same(map));
        },
      );
    }

    testWidgets('zero scroll delta is ignored', (tester) async {
      final container = _createContainer();
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        activeMap: _activeMap,
        activeLayerId: 'ground',
        savedMapSnapshot: _activeMap,
      );

      await _pumpCanvas(tester, container);
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(MapCanvas)),
          kind: ui.PointerDeviceKind.mouse,
        ),
      );
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.panOffset, Offset.zero);
      expect(state.zoom, 1);
      expect(state.activeMap, same(_activeMap));
    });
  });
}

ProviderContainer _createContainer() {
  final container = ProviderContainer();
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    subscription.close();
    container.dispose();
  });
  return container;
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _project = ProjectManifest(
  name: 'pointer_navigation_project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _activeMap = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tiles: <int>[0, 0, 0, 0],
    ),
  ],
);

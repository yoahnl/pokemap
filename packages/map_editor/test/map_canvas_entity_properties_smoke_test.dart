import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/entity_properties_panel.dart';

void main() {
  group('MapCanvas and EntityPropertiesPanel smoke tests', () {
    late Directory tempProjectRoot;

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('map_editor_canvas_panel_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    Future<void> pumpEditorSurface(
      WidgetTester tester,
      ProviderContainer container, {
      required Widget child,
      Size surfaceSize = const Size(1400, 1000),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: surfaceSize.width,
                    height: surfaceSize.height,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    EditorState buildEditorState() {
      const activeMap = MapData(
        id: 'route_1',
        name: 'Route 1',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tiles: <int>[
              0, 0, 0, 0,
              0, 0, 0, 0,
              0, 0, 0, 0,
              0, 0, 0, 0,
            ],
          ),
        ],
        entities: <MapEntity>[
          MapEntity(
            id: 'npc_1',
            name: 'Guide',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              displayName: 'Guide',
            ),
          ),
        ],
      );

      return EditorState(
        projectRootPath: tempProjectRoot.path,
        project: const ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
          name: 'smoke_project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: activeMap,
        activeLayerId: 'ground',
        selectedEntityId: 'npc_1',
      );
    }

    testWidgets('MapCanvas renders an active map without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = buildEditorState();

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 900,
          height: 700,
          child: MapCanvas(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EntityPropertiesPanel renders the selected NPC inspector',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = buildEditorState();

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 560,
          height: 980,
          child: EntityPropertiesPanel(embedded: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('PNJ'), findsWidgets);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

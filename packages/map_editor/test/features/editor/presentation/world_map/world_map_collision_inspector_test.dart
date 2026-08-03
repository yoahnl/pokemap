import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_collision_inspector.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  testWidgets(
    'switches only the existing collision size mode and shows resolved size',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          activeBrush: EditorBrush.projectElement(elementId: 'house'),
          collisionBrushSizeMode: CollisionBrushSizeMode.brushFootprint,
          savedMapSnapshot: _map,
        );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: WorldMapCollisionInspector(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2 × 3 cases'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-collision-single-tile'),
        ),
      );
      await tester.pump();

      expect(
        notifier.state.collisionBrushSizeMode,
        CollisionBrushSizeMode.singleTile,
      );
      expect(find.text('1 × 1 case'), findsOneWidget);
      _expectTransientOnly(notifier);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-collision-brush-footprint'),
        ),
      );
      await tester.pump();

      expect(
        notifier.state.collisionBrushSizeMode,
        CollisionBrushSizeMode.brushFootprint,
      );
      expect(find.text('2 × 3 cases'), findsOneWidget);
      _expectTransientOnly(notifier);
    },
  );

  testWidgets(
    'shows uncapped collision size and reports an unresolved brush honestly',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'collision',
          activeTool: EditorToolType.collisionPaint,
          activeBrush: EditorBrush.projectElement(elementId: 'long-house'),
          collisionBrushSizeMode: CollisionBrushSizeMode.brushFootprint,
          savedMapSnapshot: _map,
        );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: const Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: WorldMapCollisionInspector(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('17 × 2 cases'), findsOneWidget);

      notifier.state = notifier.state.copyWith(
        activeBrush:
            const EditorBrush.projectElement(elementId: 'missing-element'),
      );
      await tester.pump();

      expect(find.text('Empreinte indisponible'), findsOneWidget);
      expect(find.text('1 × 1 case'), findsNothing);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    },
  );
}

void _expectTransientOnly(EditorNotifier notifier) {
  expect(notifier.state.activeMap, same(_map));
  expect(
    notifier.state.activeBrush,
    const EditorBrush.projectElement(elementId: 'house'),
  );
  expect(notifier.state.mapUndoStack, isEmpty);
  expect(notifier.state.mapRedoStack, isEmpty);
  expect(notifier.state.isDirty, isFalse);
}

const _project = ProjectManifest(
  name: 'Collision inspector',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'house',
      name: 'House',
      tilesetId: 'world',
      categoryId: 'building',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'long-house',
      name: 'Long House',
      tilesetId: 'world',
      categoryId: 'building',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 17, height: 2),
        ),
      ],
    ),
  ],
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
      ],
    ),
  ],
);

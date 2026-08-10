import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_library_panel.dart';

void main() {
  group('NSC-30 Scenes library lifecycle', () {
    testWidgets('searches names tags folders and declared outcomes',
        (tester) async {
      await _pumpPanel(tester);

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_forest')),
          findsOneWidget);

      final search = find.descendant(
        of: find.byKey(const ValueKey('scenes-library-search')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(search, 'rival');
      await tester.pump();

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_forest')),
          findsNothing);
    });

    testWidgets('filters archived scenes without deleting them',
        (tester) async {
      await _pumpPanel(tester);

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_archive')),
          findsNothing);

      await tester.tap(find.text('Scènes actives'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scènes archivées').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_archive')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsNothing);
    });

    testWidgets('exposes edit duplicate archive and protected delete actions',
        (tester) async {
      var editCount = 0;
      var duplicateCount = 0;
      var archiveCount = 0;
      var deleteCount = 0;
      await _pumpPanel(
        tester,
        onEdit: () => editCount++,
        onDuplicate: () => duplicateCount++,
        onArchive: () => archiveCount++,
        onDelete: () => deleteCount++,
      );

      await tester.tap(find.byKey(const ValueKey('scenes-library-edit')));
      await tester.tap(find.byKey(const ValueKey('scenes-library-duplicate')));
      await tester
          .tap(find.byKey(const ValueKey('scenes-library-toggle-archive')));
      await tester.tap(find.byKey(const ValueKey('scenes-library-delete')));

      expect(
          (editCount, duplicateCount, archiveCount, deleteCount), (1, 1, 1, 1));
      expect(find.textContaining('2 usages'), findsOneWidget);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onArchive,
  VoidCallback? onDelete,
}) async {
  final project = ProjectManifest(
    name: 'Scenes library',
    maps: const [],
    tilesets: const [],
    scenes: [
      _scene(
        'scene_port',
        name: 'Rencontre au port',
        tags: const ['rival'],
        folder: 'Acte 1',
        outcomes: [SceneOutcome(id: 'victory', label: 'Victoire')],
      ),
      _scene('scene_forest', name: 'Forêt brumeuse'),
      _scene('scene_archive', name: 'Ancienne scène', archived: true),
    ],
  );
  final scenes = buildNarrativeWorkspaceProjection(project).scenes;
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 780,
          child: SceneLibraryPanel(
            scenes: scenes,
            selectedSceneId: 'scene_port',
            consumerCountBySceneId: const {'scene_port': 2},
            onSelectScene: (_) {},
            onEditScene: onEdit,
            onDuplicateScene: onDuplicate,
            onToggleArchiveScene: onArchive,
            onDeleteScene: onDelete,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SceneAsset _scene(
  String id, {
  required String name,
  List<String> tags = const [],
  String? folder,
  bool archived = false,
  List<SceneOutcome> outcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: name,
    tags: tags,
    declaredOutcomes: outcomes,
    metadata: {
      sceneLibraryFolderMetadataKey: ?folder,
      if (archived) sceneLibraryArchivedMetadataKey: 'true',
    },
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

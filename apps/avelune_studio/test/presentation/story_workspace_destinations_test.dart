import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'the scene title directory reports failures and retries without reading documents',
    (tester) async {
      final index = memoryIndex()..titleFailure = StateError('lecture refusée');
      await openMemoryStudio(tester, index);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('memory-failed')), findsOneWidget);
      expect(find.textContaining('lecture refusée'), findsOneWidget);
      index.titleFailure = null;
      await tester.tap(find.text('Réessayer'));
      await settleMemory(tester);
      expect(find.text('Ouverture de la porte'), findsOneWidget);
      expect(index.titleRequests, [
        NarrativeTitleKind.scenes,
        NarrativeTitleKind.scenes,
      ]);
      expect(index.documentRequests, isEmpty);
    },
  );

  testWidgets(
    'an empty scene directory does not create data or open a document',
    (tester) async {
      final index = memoryIndex()
        ..titlesByKind[NarrativeTitleKind.scenes] = const [];
      await openMemoryStudio(tester, index);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(find.text('Aucune scène pour l’instant'), findsOneWidget);
      expect(index.documentRequests, isEmpty);
      expect(index.titlesByKind[NarrativeTitleKind.scenes], isEmpty);
    },
  );

  testWidgets(
    'a scene without a behaviour opens the existing graph on demand and returns to the directory',
    (tester) async {
      final scene = SceneAsset(
        id: 'gate',
        name: 'Ouverture de la porte',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'flow',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final index = memoryIndex()
        ..documents['gate'] = SceneDocument(
          scene: scene,
          dialogues: const [],
          missingDialogueIds: const [],
          events: const [],
          maps: const {},
          mapReads: 0,
        );
      await openMemoryStudio(
        tester,
        index,
        project: memoryProject.copyWith(scenes: [scene]),
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      expect(index.documentRequests, ['gate']);
      expect(
        find.byKey(const ValueKey('scene-graph-preview-gate')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('story-scene-open')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('scene-focus-graph-gate')),
        findsOneWidget,
      );
      expect(index.documentRequests, ['gate']);
      await tester.tap(find.byKey(const ValueKey('scene-focus-close')));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('story-scenes-list')), findsOneWidget);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .selected,
        isTrue,
      );
    },
  );

  testWidgets(
    'the dialogue library loads its own titles without changing section',
    (tester) async {
      final index = memoryIndex();
      await openMemoryStudio(tester, index);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      expect(index.titleRequests, [NarrativeTitleKind.dialogues]);
      expect(
        find.byKey(const ValueKey('story-dialogue-catalog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-dialogue-behaviours')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('story-dialogue-scenes')), findsNothing);
      expect(index.documentRequests, isEmpty);
    },
  );
}

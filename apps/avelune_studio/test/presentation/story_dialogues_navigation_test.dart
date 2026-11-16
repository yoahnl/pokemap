import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';

import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../dialogues/dialogue_catalog_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'a scene opens its exact document and returns with the graph selection',
    (tester) async {
      final h = DialogueCatalogHarness(count: 2);
      final dialogue = h.port.documents['talk_1']!.dialogue;
      final scene = SceneAsset(
        id: 'gate',
        name: 'Un document partagé',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'talk',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: dialogue.id),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'first',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'talk',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'last',
              fromNodeId: 'talk',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final index = memoryIndex();
      index.titlesByKind.addAll(h.index.titlesByKind);
      index.documents['gate'] = SceneDocument(
        scene: scene,
        dialogues: [dialogue],
        missingDialogueIds: const [],
        events: const [],
        maps: const {},
        mapReads: 0,
      );
      final maps = await openMemoryStudio(
        tester,
        index,
        dialogueCatalog: h.port,
        project: memoryProject.copyWith(
          scenes: [scene],
          dialogues: [dialogue.entry],
        ),
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-open')));
      await settleMemory(tester);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('scene-graph-card-talk'))),
      );
      await settleMemory(tester);
      final pendingTitles = Completer<List<NarrativeTitle>>();
      index.titleLoader = (kind) async => kind == NarrativeTitleKind.dialogues
          ? pendingTitles.future
          : index.titlesByKind[kind] ?? const [];
      await tester.tap(
        find.byKey(const ValueKey('story-open-dialogue-talk_1')),
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-facts')));
      await settleMemory(tester);
      pendingTitles.complete(index.titlesByKind[NarrativeTitleKind.dialogues]);
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('story-dialogue-catalog')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('story-return')));
      await settleMemory(tester);
      await tester.tap(
        find.byKey(const ValueKey('story-open-dialogue-talk_1')),
      );
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('dialogue-document-talk_1')),
        findsOneWidget,
      );
      expect(h.port.requests, ['talk_1']);
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('dialogue-editor-translation')),
        'Hello from the graph.',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dialogue-catalog-back')));
      await settleMemory(tester);
      await tester.enterText(
        find.byKey(const ValueKey('dialogue-catalog-search')),
        '0',
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('dialogue-catalog-refresh')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-return')));
      await settleMemory(tester);
      await tester.tap(
        find.byKey(const ValueKey('story-open-dialogue-talk_1')),
      );
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('dialogue-document-talk_1')),
        findsOneWidget,
      );
      expect(h.port.requests.where((id) => id == 'talk_1'), hasLength(2));
      await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudioDraftField>(
              find.byKey(const ValueKey('dialogue-editor-translation')),
            )
            .value,
        'Hello from the graph.',
      );
      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('story-return')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('scene-focus-graph-gate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('scene-graph-inspector-talk')),
        findsOneWidget,
      );
      expect(maps.writes, 0);
    },
  );
}

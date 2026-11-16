import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../storyline/storyline_widget_support.dart';
import '../scenes/scene_catalog_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'missing references are counted separately from existing scenes',
    (tester) async {
      await openTrameStudio(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(find.text('1 scène'), findsOneWidget);
      expect(find.text('1 référence à vérifier'), findsOneWidget);
    },
  );
  testWidgets('a failed preview waits for an explicit retry', (tester) async {
    final index = memoryIndex();
    await openTrameStudio(tester, index: index);
    await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
    await settleMemory(tester);
    await settleMemory(tester);
    expect(index.documentRequests, ['gate']);
    final inspector = find.byKey(
      const ValueKey('scene-catalog-inspector-gate'),
    );
    final retry = find.descendant(
      of: inspector,
      matching: find.widgetWithText(StudioButton, 'Réessayer'),
    );
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await settleMemory(tester);
    expect(index.documentRequests, ['gate', 'gate']);
  });
  testWidgets(
    'unavailable story metadata is not presented as outside the story',
    (tester) async {
      final index = memoryIndex();
      await openMemoryStudio(tester, index);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .subtitle,
        'Rattachement inconnu',
      );
    },
  );
  testWidgets(
    'a hidden inspector loads no preview and the graph reuses the selected document',
    (tester) async {
      final index = memoryIndex();
      index.documents['gate'] = catalogDocument(trameProject.scenes.last);
      await openTrameStudio(tester, index: index);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.enterText(
        find.byKey(const ValueKey('scene-catalog-search')),
        'porte',
      );
      await tester.tap(find.byKey(const ValueKey('story-toggle-inspector')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      expect(index.documentRequests, isEmpty);
      await tester.tap(find.byKey(const ValueKey('story-toggle-inspector')));
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
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('scene-catalog-search')),
            )
            .controller!
            .text,
        'porte',
      );
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
    'an orphan remains openable and a local deletion stays explicit',
    (tester) async {
      final index = memoryIndex();
      index.titlesByKind[NarrativeTitleKind.scenes] = const [
        NarrativeTitle(id: 'orphan', title: 'Sans porteur'),
      ];
      final scene = catalogScene('orphan', 'Sans porteur');
      index.documents[scene.id] = catalogDocument(scene);
      await openTrameStudio(tester, index: index);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-orphan')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('story-scene-open')),
            )
            .onPressed,
        isNotNull,
      );
      final page = tester.widget<StoryPage>(find.byType(StoryPage));
      page.staging.stage((draft) {
        draft.load(StoryDraftKind.scene, scene.id, scene);
        draft.remove(StoryDraftKind.scene, scene.id);
      });
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('story-scene-orphan')), findsOneWidget);
      expect(find.text('Retirée du brouillon'), findsOneWidget);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('story-scene-open')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'a scene rename updates the list and filtering clears the inspector',
    (tester) async {
      final index = memoryIndex();
      index.documents['gate'] = catalogDocument(trameProject.scenes.last);
      await openTrameStudio(tester, index: index);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      final page = tester.widget<StoryPage>(find.byType(StoryPage));
      page.staging.stage((draft) {
        draft.load(StoryDraftKind.scene, 'gate', trameProject.scenes.last);
        draft.put(StoryDraftKind.scene, catalogScene('gate', 'Un autre nom'));
      });
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .label,
        'Un autre nom',
      );
      await tester.enterText(
        find.byKey(const ValueKey('scene-catalog-search')),
        'introuvable',
      );
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('scene-catalog-inspector-gate')),
        findsNothing,
      );
      expect(
        find.text('Aucune scène ne correspond à ces filtres.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('scene-catalog-clear')));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('story-scene-gate')), findsOneWidget);
    },
  );
  testWidgets(
    'the scene catalogue includes a scene created only in the draft',
    (tester) async {
      await openTrameStudio(tester);
      final page = tester.widget<StoryPage>(find.byType(StoryPage));
      final scene = SceneAsset(
        id: 'new_scene',
        name: 'Un départ inédit',
        graph: trameProject.scenes.first.graph,
      );
      page.staging.stage((draft) {
        draft.load(StoryDraftKind.scene, scene.id, null);
        draft.put(StoryDraftKind.scene, scene);
      });
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('story-scene-new_scene')),
        findsOneWidget,
      );
      expect(find.text('Un départ inédit'), findsOneWidget);
    },
  );
}

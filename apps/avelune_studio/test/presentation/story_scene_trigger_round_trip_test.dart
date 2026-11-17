import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../dialogues/dialogue_catalog_support.dart';
import '../scenes/steps/scene_step_fixtures.dart';
import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'a local trigger follows its scene and shared dialogue and returns',
    (tester) async {
      final dialogue = _dialogue();
      final scene = _scene(dialogue.id);
      final record = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: guideTalk,
          name: 'Parler au guide',
          source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
          conditions: const [],
          sceneId: scene.id,
          priority: 0,
          order: 0,
        ),
      );
      final index = memoryIndex()
        ..titlesByKind[NarrativeTitleKind.dialogues] = [
          NarrativeTitle(id: dialogue.id, title: dialogue.entry.name),
        ]
        ..documents[scene.id] = SceneDocument(
          scene: scene,
          dialogues: [dialogue],
          missingDialogueIds: const [],
          events: [record],
          maps: const {},
          mapReads: 0,
        );
      final catalog = FakeDialogueCatalog()
        ..documents[dialogue.id] = DialogueCatalogDocument(
          dialogue: dialogue,
          sceneIds: [scene.id, 'another_scene'],
          notCovered: const [],
        );
      await openMemoryStudio(
        tester,
        index,
        dialogueCatalog: catalog,
        loadDialogue: (id) async => catalog.documents[id]!.dialogue,
        world: MapOnlyWorld.new,
        project: memoryProject.copyWith(
          scenes: [scene],
          dialogues: [dialogue.entry],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [record],
            legacyClaims: const [],
          ),
        ),
      );
      await _tap(tester, 'map-space-story');
      final binding = interactionBinding(tester);
      final maps = interactionMaps(tester);
      final origin = maps.active;
      binding.search('Guide');
      await openInteractionRule(tester);
      expect(interactionFilter(tester).value, 'a');
      final search = interactionKey('behaviours-search').hitTestable();
      await tester.enterText(search, 'guide');
      await settleMemory(tester);
      await tester.ensureVisible(interactionKey('map-story-scene-open'));
      await _tap(tester, 'map-story-scene-open');
      expect(interactionKey('scene-focus-graph-gate'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await settleMemory(tester);
      final outline = interactionKey('scene-graph-outline-search');
      final field = find.descendant(
        of: outline,
        matching: find.byType(TextField),
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: field, matching: find.byType(EditableText)),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(field, 'lettre');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await settleMemory(tester);
      expect(interactionKey('scene-graph-outline-start'), findsNothing);
      await _tap(tester, 'scene-graph-outline-ask');

      _language(tester).onChanged!('en');
      await settleMemory(tester);
      await _tap(tester, 'scene-focus-preview');
      expect(_exit(tester, 'yes').label, 'Accept the letter');
      expect(_exit(tester, 'no').label, 'Refuser la lettre');
      expect(
        find.descendant(
          of: interactionKey('scene-graph-port-ask-yes'),
          matching: find.text('Accept the letter'),
        ),
        findsOneWidget,
      );
      await _tap(tester, 'scene-focus-exit-yes');
      expect(interactionKey('scene-focus-path-accepted'), findsOneWidget);
      expect(interactionKey('scene-focus-path-refused'), findsNothing);
      await _tap(tester, 'scene-focus-preview');

      await _tap(tester, 'story-open-dialogue-${dialogue.id}');
      expect(
        interactionKey('dialogue-document-${dialogue.id}'),
        findsOneWidget,
      );
      expect(catalog.requests, [dialogue.id]);
      expect(
        tester
            .widget<StudioSelect>(interactionKey('dialogue-catalog-language'))
            .value,
        'en',
      );
      await _tap(tester, 'story-return');
      expect(interactionKey('scene-graph-inspector-ask'), findsOneWidget);
      expect(_language(tester).value, 'en');
      expect(
        tester
            .widget<SceneGraphCanvas>(find.byType(SceneGraphCanvas).first)
            .scene
            .graph,
        scene.graph,
      );
      await _tap(tester, 'scene-focus-close');
      expect(
        interactionKey('map-story-behaviour-name-$guideTalk'),
        findsOneWidget,
      );
      expect(interactionFilter(tester).value, 'a');
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: search, matching: find.byType(TextField)),
            )
            .controller!
            .text,
        'guide',
      );
      await _tap(tester, 'story-return');
      expect(maps.active, same(origin));
      expect(binding.selected!.id, 'guide');
      expect(binding.query, 'Guide');
      expect(binding.behaviours.draft.recorded, 0);
    },
  );
}

StudioSelect _language(WidgetTester tester) =>
    tester.widget(interactionKey('scene-graph-preview-language'));

StudioButton _exit(WidgetTester tester, String id) =>
    tester.widget(interactionKey('scene-focus-exit-$id'));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(interactionKey(key));
  await settleMemory(tester);
}

StoryDialogueSource _dialogue() {
  const source =
      'title: Start\n---\n'
      '-> Accepter la lettre\n    <<outcome yes>>\n'
      '-> Refuser la lettre\n    <<outcome no>>\n===\n';
  final parsed = readLocalizedDialogue(source: source, sourceLocale: 'fr');
  return StoryDialogueSource(
    source: source,
    entry: ProjectDialogueEntry(
      id: 'talk',
      name: 'La lettre',
      relativePath: 'dialogues/talk.yarn',
      declaredOutcomes: [
        DialogueDeclaredOutcome(id: 'yes', label: 'Accepter'),
        DialogueDeclaredOutcome(id: 'no', label: 'Refuser'),
      ],
      localization: parsed.localization.translate(
        parsed.localization.units.first.id,
        'en',
        'Accept the letter',
      ),
    ),
  );
}

SceneAsset _scene(String dialogueId) => SceneAsset(
  id: 'gate',
  name: 'Ouverture de la porte',
  graph: graphOf(
    [
      startNode(),
      SceneNode(
        id: 'ask',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogueId,
          expectedOutcomes: ['yes', 'no'],
        ),
      ),
      endNode('accepted'),
      endNode('refused'),
    ],
    [
      link('start', 'ask'),
      link('ask', 'refused'),
      for (final (port, to) in [('yes', 'accepted'), ('no', 'refused')])
        SceneEdge(
          id: 'ask.$port',
          fromNodeId: 'ask',
          fromPortId: port,
          toNodeId: to,
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);

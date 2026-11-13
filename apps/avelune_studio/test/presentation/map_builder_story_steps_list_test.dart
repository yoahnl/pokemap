import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../scenes/steps/scene_step_fixtures.dart';

ProjectManifest stepsProject() => ProjectManifest(
  name: 'Steps',
  maps: const [],
  tilesets: const [],
  facts: [
    NarrativeFactDefinition(id: 'met', label: 'Rencontré'),
    NarrativeFactDefinition(id: 'gate', label: 'Portail ouvert'),
  ],
  trainers: const [
    ProjectTrainerEntry(id: 'rival', name: 'Rival', trainerClass: 'Rival'),
    ProjectTrainerEntry(id: 'ace', name: 'As', trainerClass: 'Ace'),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'talk',
      name: 'Bonjour du chef',
      relativePath: 'dialogues/talk.yarn',
    ),
  ],
);

MapData stepsMap() => const MapData(
  id: 'town',
  name: 'Town',
  size: GridSize(width: 4, height: 4),
  entities: [
    MapEntity(
      id: 'guide',
      name: 'Guide',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(),
    ),
    MapEntity(
      id: 'mom',
      name: 'Maman',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 2, y: 1),
      npc: MapEntityNpcData(),
    ),
  ],
);

Future<List<SceneAsset>> pumpSteps(
  WidgetTester tester,
  SceneAsset scene, {
  ProjectManifest? project,
  bool enabled = true,
}) async {
  final changes = <SceneAsset>[];
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MapBuilderStorySteps(
            scene: scene,
            project: project ?? stepsProject(),
            map: stepsMap(),
            enabled: enabled,
            onChanged: (next) {
              changes.add(next);
              return true;
            },
          ),
        ),
      ),
    ),
  );
  return changes;
}

SceneNode setFactNode(String id, String factId) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.consequence(
    SceneConsequence.setFact(factId: factId, value: true),
  ),
);

SceneNode factConditionNode(String id, String factId) => SceneNode(
  id: id,
  kind: SceneNodeKind.condition,
  payload: SceneConditionPayload(
    conditionRef: factId,
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.fact,
      sourceId: factId,
      operator: SceneConditionOperator.isTrue,
    ),
  ),
);

SceneAsset linearScene() => sceneOf(
  [
    startNode(),
    setFactNode('fact', 'met'),
    dialogueNode('talk'),
    endNode('end'),
  ],
  [link('start', 'fact'), link('fact', 'talk'), link('talk', 'end')],
);

SceneAsset nestedScene() => sceneOf(
  [
    startNode(),
    factConditionNode('if', 'gate'),
    setFactNode('yes', 'met'),
    battleNode('fight'),
    endNode('end'),
  ],
  [
    link('start', 'if'),
    link('if', 'yes', port: 'true'),
    link('if', 'fight', port: 'false'),
    link('yes', 'end'),
    link('fight', 'end', port: 'victory'),
    link('fight', 'end', port: 'defeat'),
  ],
);

void main() {
  testWidgets('a linear scene reads as a list of steps', (tester) async {
    await pumpSteps(tester, linearScene());
    expect(find.byKey(const ValueKey('story-step-fact')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-step-talk')), findsOneWidget);
    expect(find.text('Retenir un fait'), findsOneWidget);
    expect(find.text('Rencontré'), findsOneWidget);
    expect(find.text('Bonjour du chef'), findsOneWidget);
    final fact = tester.getTopLeft(
      find.byKey(const ValueKey('story-step-fact')),
    );
    final talk = tester.getTopLeft(
      find.byKey(const ValueKey('story-step-talk')),
    );
    expect(fact.dy, lessThan(talk.dy));
  });

  testWidgets('si / sinon are nested blocks', (tester) async {
    await pumpSteps(tester, nestedScene());
    expect(find.text('Alors'), findsOneWidget);
    expect(find.text('Sinon'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('story-step-branch-if-0')),
        matching: find.byKey(const ValueKey('story-step-yes')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('story-step-branch-if-1')),
        matching: find.byKey(const ValueKey('story-step-fight')),
      ),
      findsOneWidget,
    );
    expect(find.text('Portail ouvert'), findsOneWidget);
  });

  testWidgets('a mechanical failure branch reads « en cas d’échec »', (
    tester,
  ) async {
    await pumpSteps(
      tester,
      sceneOf(
        [startNode(), giveNode('gift'), pcNode('pc'), endNode('end')],
        [
          link('start', 'gift'),
          link('gift', 'end', port: 'received'),
          link('gift', 'pc', port: 'bagFull'),
          link('pc', 'end'),
          link('pc', 'end', port: 'cancelled'),
        ],
      ),
    );
    expect(find.text('En cas d’échec · sac plein'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('story-step-branch-gift-1')),
        matching: find.byKey(const ValueKey('story-step-advanced-pc')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a command without a form is an advanced, read-only step', (
    tester,
  ) async {
    final scene = sceneOf(
      [startNode(), soundNode('sfx'), endNode('end')],
      [link('start', 'sfx'), link('sfx', 'end')],
    );
    final changes = await pumpSteps(tester, scene);
    final card = find.byKey(const ValueKey('story-step-advanced-sfx'));
    expect(card, findsOneWidget);
    expect(find.text('Étape avancée'), findsOneWidget);
    expect(find.text('playSoundEffect'), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.byType(StudioSelect)),
      findsNothing,
    );
    expect(changes, isEmpty);
  });

  testWidgets('a missing reference shows its id and is never rewritten', (
    tester,
  ) async {
    final scene = sceneOf(
      [startNode(), setFactNode('fact', 'lost_fact'), endNode('end')],
      [link('start', 'fact'), link('fact', 'end')],
    );
    final changes = await pumpSteps(
      tester,
      scene,
      project: const ProjectManifest(name: 'Partial', maps: [], tilesets: []),
    );
    expect(find.text('lost_fact'), findsOneWidget);
    expect(changes, isEmpty);
  });

  for (final (name, scene, key, text) in [
    (
      'loop',
      sceneOf(
        [startNode(), pcNode('a'), pcNode('b'), endNode('end')],
        [
          link('start', 'a'),
          link('a', 'b'),
          link('a', 'end', port: 'cancelled'),
          link('b', 'end'),
          link('b', 'a', port: 'cancelled'),
        ],
      ),
      'story-steps-loop',
      'boucle',
    ),
    (
      'true graph',
      sceneOf(
        [
          startNode(),
          conditionNode('asked'),
          dialogueNode('first', ['yes', 'no']),
          dialogueNode('again', ['yes', 'no']),
          factNode('accept'),
          factNode('refuse'),
          endNode('end'),
        ],
        [
          link('start', 'asked'),
          link('asked', 'first', port: 'false'),
          link('asked', 'again', port: 'true'),
          link('first', 'accept', port: 'yes'),
          link('first', 'refuse', port: 'no'),
          link('again', 'accept', port: 'yes'),
          link('again', 'refuse', port: 'no'),
          link('accept', 'end'),
          link('refuse', 'end'),
        ],
      ),
      'story-steps-true-graph',
      'se croisent',
    ),
  ]) {
    testWidgets('the $name fallback opens read-only with an explanation', (
      tester,
    ) async {
      final changes = await pumpSteps(tester, scene);
      expect(find.byKey(ValueKey(key)), findsOneWidget);
      expect(find.textContaining(text), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNothing);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.text('Étape'), findsNothing);
      for (final select in tester.widgetList<StudioSelect>(
        find.byType(StudioSelect),
      )) {
        expect(select.onChanged, isNull);
      }
      expect(changes, isEmpty);
    });
  }
}

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/scene_step_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'steps/scene_step_fixtures.dart';

ProjectManifest _project() => ProjectManifest(
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

const _map = MapData(
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

SceneNode _setFact(String id, String factId) => SceneNode(
  id: id,
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.consequence(
    SceneConsequence.setFact(factId: factId, value: true),
  ),
);

SceneNode _factCondition(String id, String factId) => SceneNode(
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

final _presence = SceneNode(
  id: 'show',
  kind: SceneNodeKind.action,
  payload: SceneActionPayload.consequence(
    SceneConsequence.setNpcPresence(
      mapId: 'town',
      entityId: 'guide',
      present: true,
    ),
  ),
);

Future<List<SceneNode>> _pump(
  WidgetTester tester,
  SceneNode node, {
  ProjectManifest? project,
  bool enabled = true,
}) async {
  final edits = <SceneNode>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SceneStepForm(
            scene: sceneOf(
              [startNode(), node, endNode('end')],
              [link('start', node.id)],
            ),
            project: project ?? _project(),
            map: _map,
            node: node,
            enabled: enabled,
            onEdit: edits.add,
          ),
        ),
      ),
    ),
  );
  return edits;
}

Future<void> _choose(WidgetTester tester, String key, String option) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, node, key, option, check) in [
    (
      'fact',
      _setFact('fact', 'met'),
      'story-step-fact-fact',
      'Portail ouvert',
      (SceneNode node) => expect(
        ((node.payload as SceneActionPayload).consequence!
                as SceneSetFactConsequence)
            .factId,
        'gate',
      ),
    ),
    (
      'fact value',
      _setFact('fact', 'met'),
      'story-step-value-fact',
      'Non',
      (SceneNode node) => expect(
        ((node.payload as SceneActionPayload).consequence!
                as SceneSetFactConsequence)
            .value,
        isFalse,
      ),
    ),
    (
      'trainer',
      battleNode('fight'),
      'story-step-trainer-fight',
      'As',
      (SceneNode node) =>
          expect((node.payload as SceneBattlePayload).trainerId, 'ace'),
    ),
    (
      'condition fact',
      _factCondition('if', 'gate'),
      'story-step-condition-fact-if',
      'Rencontré',
      (SceneNode node) => expect(
        (node.payload as SceneConditionPayload).conditionSource!.sourceId,
        'met',
      ),
    ),
    (
      'condition value',
      _factCondition('if', 'gate'),
      'story-step-condition-value-if',
      'Faux',
      (SceneNode node) => expect(
        (node.payload as SceneConditionPayload).conditionSource!.operator,
        SceneConditionOperator.isFalse,
      ),
    ),
  ]) {
    testWidgets('the $name form edits only that step', (tester) async {
      final edits = await _pump(tester, node);
      await _choose(tester, key, option);
      expect(edits, hasLength(1));
      expect(edits.single.id, node.id);
      expect(edits.single.kind, node.kind);
      check(edits.single);
    });
  }

  testWidgets('the presence form picks a map character and an effect', (
    tester,
  ) async {
    SceneSetNpcPresenceConsequence change(SceneNode node) =>
        (node.payload as SceneActionPayload).consequence!
            as SceneSetNpcPresenceConsequence;
    var edits = await _pump(tester, _presence);
    await _choose(tester, 'story-step-entity-show', 'Maman');
    expect(change(edits.single).entityId, 'mom');
    edits = await _pump(tester, _presence);
    await _choose(tester, 'story-step-presence-show', 'Disparaît');
    expect(change(edits.single).present, isFalse);
    expect(change(edits.single).entityId, 'guide');
  });

  testWidgets('a dialogue step names its dialogue', (tester) async {
    await _pump(tester, dialogueNode('talk'));

    expect(find.text('Bonjour du chef'), findsOneWidget);
  });

  testWidgets('a missing reference shows its id and is never rewritten', (
    tester,
  ) async {
    final edits = await _pump(
      tester,
      _setFact('fact', 'lost_fact'),
      project: const ProjectManifest(name: 'Partial', maps: [], tilesets: []),
    );

    expect(find.text('lost_fact'), findsOneWidget);
    expect(edits, isEmpty);
  });

  testWidgets('a disabled form cannot change anything', (tester) async {
    await _pump(tester, _setFact('fact', 'met'), enabled: false);

    for (final select in tester.widgetList<StudioSelect>(
      find.byType(StudioSelect),
    )) {
      expect(select.onChanged, isNull);
    }
  });
}

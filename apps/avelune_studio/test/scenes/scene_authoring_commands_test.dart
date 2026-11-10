import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_readable_summary.dart';
import 'package:avelune_studio/features/scenes/application/scene_node_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'linked payload choices retain native dialogue and unique battle identity',
    () {
      const project = ProjectManifest(
        name: 'Choix',
        maps: [],
        tilesets: [],
        dialogues: [
          ProjectDialogueEntry(
            id: 'guide',
            name: 'Guide',
            relativePath: 'guide.yarn',
            defaultStartNode: 'Start',
            declaredOutcomes: [
              DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
            ],
          ),
        ],
        encounterTables: [
          ProjectEncounterTable(
            id: 'unique',
            name: 'Gardien',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'bulbasaur',
                minLevel: 30,
                maxLevel: 30,
              ),
            ],
          ),
          ProjectEncounterTable(
            id: 'variable',
            name: 'Variable',
            encounterKind: EncounterKind.special,
            tags: ['studio:unique'],
            entries: [
              ProjectEncounterEntry(
                speciesId: 'bulbasaur',
                minLevel: 30,
                maxLevel: 31,
              ),
            ],
          ),
          ProjectEncounterTable(
            id: 'ordinary',
            name: 'Ordinaire',
            encounterKind: EncounterKind.special,
            entries: [
              ProjectEncounterEntry(
                speciesId: 'bulbasaur',
                minLevel: 30,
                maxLevel: 30,
              ),
            ],
          ),
        ],
      );
      final dialogue =
          scenePayloadChoices(project, SceneNodeKind.yarnDialogue)['guide']!.$2
              as SceneYarnDialoguePayload;
      expect((dialogue.dialogueId, dialogue.yarnNodeName), ('guide', 'Start'));
      expect(dialogue.expectedOutcomes, ['accepted']);
      final battles = scenePayloadChoices(project, SceneNodeKind.battle);
      expect(battles.keys, ['unique:unique']);
      final battle = battles.values.single.$2 as SceneBattlePayload;
      expect(battle.battleKind, 'wild');
      expect(battle.battleTemplateId, 'unique');
      expect(
        battle.declaredOutcomes,
        containsAll(['victory', 'captured', 'defeat', 'runaway']),
      );
      expect(scenePayloadChoices(project, SceneNodeKind.action), isEmpty);
    },
  );
  late SceneAsset base;
  setUp(() {
    base = createSceneDraftInProject(
      ProjectManifest(name: 'Narration', maps: [], tilesets: []),
      name: 'Rencontre',
    ).createdScene;
  });

  test('adding a linked node lays out and connects in one undo entry', () {
    base = removeSceneEdgeDraft(base, base.graph.edges.single.id).updatedScene;
    final session = SceneEditSession(base, base: base);
    final id = session.addAt(
      SceneNodeKind.yarnDialogue,
      title: 'Conversation',
      payload: SceneYarnDialoguePayload(dialogueId: 'guide'),
      x: 420,
      y: 180,
      fromNodeId: 'node_start',
      fromPortId: 'completed',
    );
    expect(id, isNotNull, reason: session.error);
    expect(session.undoCount, 1);
    final node = session.current.graph.nodes.singleWhere(
      (node) => node.id == id,
    );
    expect((node.payload as SceneYarnDialoguePayload).dialogueId, 'guide');
    final layout = session.current.layout.nodeLayouts.singleWhere(
      (node) => node.nodeId == id,
    );
    expect((layout.x, layout.y), (420, 180));
    expect(
      session.current.graph.edges.any(
        (edge) => edge.fromNodeId == 'node_start' && edge.toNodeId == id,
      ),
      isTrue,
    );
    session.restore(redo: false);
    expect(session.current, base);
    session.restore(redo: true);
    expect(session.current.graph.nodes.any((node) => node.id == id), isTrue);
  });

  test('a rejected connection cannot retain its newly created node', () {
    final session = SceneEditSession(base, base: base);
    final id = session.addAt(
      SceneNodeKind.merge,
      x: 20,
      y: 40,
      fromNodeId: 'missing',
      fromPortId: 'completed',
    );
    expect(id, isNull);
    expect(session.current, base);
    expect(session.undoCount, 0);
    expect(session.error, isNotNull);
  });

  test('read only scene rejects an addition without changing its draft', () {
    final session = SceneEditSession(
      base,
      base: base,
      canMutate: () => 'Lecture seule',
    );
    expect(session.addAt(SceneNodeKind.merge, x: 20, y: 40), isNull);
    expect(session.current, base);
    expect(session.error, 'Lecture seule');
    expect(session.canUndo, isFalse);
  });

  test(
    'search and readable traversal preserve unreachable blocks and source',
    () {
      final session = SceneEditSession(base, base: base);
      final id = session.addAt(
        SceneNodeKind.merge,
        title: 'Réunion',
        x: 20,
        y: 40,
      )!;
      final before = session.current.toJson();
      expect(sceneNodeMatches(session.current, 'reunion').single.id, id);
      expect(sceneNodeMatches(session.current, 'introuvable'), isEmpty);
      final summary = sceneReadableSummary(
        session.current,
        (node) => node.title ?? node.id,
      );
      expect(summary.unreached, 1);
      expect(summary.steps, ['Fin · Fin']);
      expect(session.current.toJson(), before);
    },
  );
}

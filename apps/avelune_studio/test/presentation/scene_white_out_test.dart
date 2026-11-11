import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_battle_recovery_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('whiteOut command selection is available only in $dimension', () {
      final draft = SceneActionDraft(
        project: _project(dimension),
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(
        draft.commands.any(
          (command) => command.id == NarrativeCommandIds.whiteOut,
        ),
        dimension == ProjectDimension.twoD,
      );
      if (dimension == ProjectDimension.twoD) {
        draft.choose(NarrativeCommandIds.whiteOut);
        expect(
          (draft.buildPayload() as SceneActionPayload).interactiveCommand!
              .toJson(),
          {'kind': 'whiteOut'},
        );
      }
    });

    test(
      'historical battle recovery selection preserves graph in $dimension',
      () {
        final scene = _battleScene();
        final session = SceneEditSession(scene, base: scene);
        final node = scene.graph.nodes.singleWhere(
          (node) => node.id == 'battle',
        );
        final selection = HistoricalSceneBattleRecoverySelection(
          project: _project(dimension),
          current: node.payload as SceneBattlePayload,
        );
        expect(selection.available, dimension == ProjectDimension.twoD);
        final payload = selection.select(
          SceneBattleDefeatRecovery.returnToRecoveryPoint,
        );
        if (payload != null) {
          expect(session.replacePayload(node, payload), isTrue);
        }
        expect(
          (session.current.graph.nodes
                      .singleWhere((node) => node.id == 'battle')
                      .payload
                  as SceneBattlePayload)
              .defeatRecovery,
          dimension == ProjectDimension.twoD
              ? SceneBattleDefeatRecovery.returnToRecoveryPoint
              : SceneBattleDefeatRecovery.continueScene,
        );
        expect(session.current.graph.edges, scene.graph.edges);
        expect(session.current.layout, scene.layout);
        expect(session.current.metadata, scene.metadata);
        expect(session.undoCount, dimension == ProjectDimension.twoD ? 1 : 0);
        if (selection.available) {
          session.restore(redo: false);
          expect(session.current, scene);
        }
      },
    );
  }
  test(
    'unavailable historical selection retains an existing 3D recovery payload',
    () {
      final payload = SceneBattlePayload(
        battleKind: 'trainer',
        trainerId: 'rival',
        defeatRecovery: SceneBattleDefeatRecovery.returnToRecoveryPoint,
      );
      final selection = HistoricalSceneBattleRecoverySelection(
        project: _project(ProjectDimension.threeD),
        current: payload,
      );
      expect(selection.select(SceneBattleDefeatRecovery.continueScene), isNull);
      expect(selection.current, same(payload));
      expect(
        selection.current.defeatRecovery,
        SceneBattleDefeatRecovery.returnToRecoveryPoint,
      );
      final scene = _battleScene();
      final session = SceneEditSession(scene, base: scene);
      expect(
        session.replacePayload(
          scene.graph.nodes.singleWhere((node) => node.id == 'battle'),
          payload,
        ),
        isTrue,
      );
      expect(
        (session.current.graph.nodes
                    .singleWhere((node) => node.id == 'battle')
                    .payload
                as SceneBattlePayload)
            .defeatRecovery,
        payload.defeatRecovery,
      );
    },
  );
}

ProjectManifest _project(ProjectDimension dimension) => ProjectManifest(
  name: 'Recovery',
  maps: const [],
  tilesets: const [],
  settings: ProjectSettings(dimension: dimension),
  scenes: [_battleScene()],
  trainers: const [
    ProjectTrainerEntry(
      id: 'rival',
      name: 'Rival',
      trainerClass: 'Rival',
      team: [ProjectTrainerPokemonEntry(speciesId: 'bird', level: 5)],
    ),
  ],
);

SceneAsset _battleScene() => SceneAsset(
  id: 'scene',
  name: 'Rival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(battleKind: 'trainer', trainerId: 'rival'),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'battle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'win',
        fromNodeId: 'battle',
        fromPortId: 'victory',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'lose',
        fromNodeId: 'battle',
        fromPortId: 'defeat',
        toNodeId: 'end',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);

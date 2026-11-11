import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';

import 'support/ui06_scene_fixture.dart';

void main() {
  test(
    'canonical scene commands build both branches then publish and reopen',
    () async {
      final fixture = await Ui06SceneFixture.create();
      final maps = MapWorkspaceController(fixture.session, fixture.maps);
      await maps.initialize();
      final controller = SceneWorkspaceController(
        maps,
        LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
        changed: () {},
      );
      addTearDown(() async {
        controller.dispose();
        maps.dispose();
        await fixture.dispose();
      });
      final session = controller.create(
        'Rencontre construite par les commandes',
      )!;
      expect(session.current.graph.nodes, hasLength(2));
      expect(session.disconnect(session.current.graph.edges.single.id), isTrue);
      expect(session.current.graph.edges, isEmpty);
      expect(session.move('node_start', 20, 200), isTrue);
      expect(session.move('node_end', 1220, 400), isTrue);
      String dialogue(String id, double x, double y) {
        final payload = scenePayloadChoices(
          controller.project,
          SceneNodeKind.yarnDialogue,
        )[id]!.$2;
        return session.addAt(
          SceneNodeKind.yarnDialogue,
          title: Ui06SceneFixture.names[id],
          payload: payload,
          x: x,
          y: y,
        )!;
      }

      final welcome = dialogue('station_welcome', 220, 200);
      final condition = session.addAt(
        SceneNodeKind.condition,
        title: 'Condition',
        x: 460,
        y: 200,
      )!;
      expect(
        session.mutate(
          (scene) => updateSceneConditionSource(
            scene,
            nodeId: condition,
            source: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: Ui06SceneFixture.passFactId,
              operator: SceneConditionOperator.isTrue,
            ),
          ).updatedScene,
        ),
        isTrue,
      );
      final refusal = dialogue('station_refusal', 710, 440);
      final agreement = dialogue('station_agreement', 710, 20);
      final action = session.addAt(
        SceneNodeKind.action,
        title: 'Autoriser le départ',
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(
            factId: Ui06SceneFixture.departureFactId,
            value: true,
          ),
        ),
        x: 960,
        y: 20,
      )!;
      final end = session.addAt(
        SceneNodeKind.end,
        title: 'Fin',
        x: 1220,
        y: 20,
      )!;
      for (final label in ['Attente', 'Embarquement']) {
        expect(session.addOutcome(label), isTrue);
      }
      for (final target in [('node_end', 'result_1'), (end, 'result_2')]) {
        expect(
          session.mutate(
            (scene) => updateSceneEndPayload(
              scene,
              nodeId: target.$1,
              sceneOutcomeId: target.$2,
              outcomePolicy: null,
            ).updatedScene,
          ),
          isTrue,
        );
      }
      for (final connection in [
        ('node_start', 'completed', welcome),
        (welcome, 'completed', condition),
        (condition, 'false', refusal),
        (condition, 'true', agreement),
        (refusal, 'completed', 'node_end'),
        (agreement, 'completed', action),
        (action, 'completed', end),
      ]) {
        expect(
          session.connect(connection.$1, connection.$2, connection.$3),
          isTrue,
          reason: session.error,
        );
      }
      expect(session.current.graph.nodes, hasLength(8));
      expect(session.current.graph.edges, hasLength(7));
      expect(
        (session.current.graph.nodes
                    .firstWhere((node) => node.id == condition)
                    .payload
                as SceneConditionPayload)
            .conditionSource!
            .sourceId,
        Ui06SceneFixture.passFactId,
      );
      expect(
        (session.current.graph.nodes
                    .firstWhere((node) => node.id == action)
                    .payload
                as SceneActionPayload)
            .consequence,
        SceneConsequence.setFact(
          factId: Ui06SceneFixture.departureFactId,
          value: true,
        ),
      );
      final expected = session.current;
      final history = session.undoCount;
      session.restore(redo: false);
      expect(session.current.graph.edges, hasLength(6));
      session.restore(redo: true);
      expect(session.current, same(expected));
      expect(session.undoCount, history);
      final plan = buildSceneRuntimePlan(expected);
      expect(plan.plan, isNotNull, reason: plan.diagnostics.toString());
      for (final choice in ['false', 'true']) {
        final preview = previewSceneRuntimePath(
          plan.plan!,
          input: SceneDryRunInputState(
            outputPortByNodeId: {
              welcome: 'completed',
              condition: choice,
              refusal: 'completed',
              agreement: 'completed',
            },
          ),
        );
        expect(preview.status, SceneDryRunPreviewStatus.completed);
        expect(
          preview.sceneOutcomeId,
          choice == 'false' ? 'result_1' : 'result_2',
        );
      }
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(
        controller.busy,
        isFalse,
        reason: 'La publication doit produire un reçu.',
      );
      expect(session.error, isNull);
      expect(session.dirty, isFalse);
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(
        reopened.scenes.firstWhere((scene) => scene.id == expected.id),
        expected,
      );
      expect(
        reopened.scenes.firstWhere(
          (scene) => scene.id == Ui06SceneFixture.sceneId,
        ),
        fixture.scene,
      );
    },
  );
}

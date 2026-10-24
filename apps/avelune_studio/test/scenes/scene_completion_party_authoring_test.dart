import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  for (final enabled in [false, true]) {
    testWidgets(
      'party recording toggles and reopens losslessly from $enabled',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final original = _finish(enabled);
        final scene = SceneAsset(
          id: 'finish',
          name: 'Victoire',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'finish',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(original),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'finish',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'leave',
                fromNodeId: 'finish',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
        );
        final fixture = (await tester.runAsync(
          () => CinematicAdapterFixture.create(scenes: [scene]),
        ))!;
        addTearDown(fixture.dispose);
        final project = (await tester.runAsync(fixture.readManifest))!;
        SceneNodePayload? applied;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SceneActionForm(
                  project: project,
                  current: scene.graph.nodes[1].payload,
                  onApply: (payload) => applied = payload,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = tester
            .widgetList<StudioToggleRow>(find.byType(StudioToggleRow))
            .singleWhere(
              (widget) =>
                  widget.label ==
                  'Enregistrer l’équipe dans le journal des victoires',
            );
        expect(toggle.value, enabled);
        toggle.onChanged!(!enabled);
        await tester.pumpAndSettle();
        final submit = find.text('Appliquer l’action');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        final expected = Map<String, dynamic>.from(original.toJson());
        if (enabled) {
          expected.remove('recordParty');
        } else {
          expected['recordParty'] = true;
        }
        expect((applied as SceneActionPayload).consequence!.toJson(), expected);
        final editedJson = scene.toJson();
        (((editedJson['graph'] as Map)['nodes'] as List)[1] as Map)['payload'] =
            applied!.toJson();
        final edited = SceneAsset.fromJson(editedJson);
        final reopened = (await tester.runAsync(() async {
          await LocalSceneAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ).publishScene(base: scene, current: edited);
          return LocalMapWorkspaceAdapter().loadProject(fixture.session);
        }))!;
        expect(reopened.scenes.single, edited);
        expect(
          (reopened.scenes.single.graph.nodes[1].payload as SceneActionPayload)
              .consequence!
              .toJson(),
          expected,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

SceneFinishGameConsequence _finish(bool recordParty) =>
    SceneConsequence.fromJson({
      'kind': 'finishGame',
      'contractVersion': 1,
      'endingId': 'custom.ending:champion',
      'outcome': 'victory',
      'commitPolicy': 'persistBeforePresentation',
      'result': {
        'title': {
          'fallback': 'Victoire',
          'translations': {'en': 'Victory', 'de': 'Sieg'},
        },
        'summary': {'fallback': 'Parcours accompli'},
        'details': [
          {'fallback': 'Équipe gagnante'},
        ],
      },
      'credits': {
        'title': {
          'fallback': 'Crédits',
          'translations': {'de': 'Mitwirkende'},
        },
        'author': 'Auteur',
        'contributors': ['Une équipe'],
        'licenses': ['Une licence'],
        'endingLabel': {'fallback': 'Champion'},
        'skippable': false,
      },
      'postGamePolicy': 'continueGame',
      'label': 'Titre conservé',
      'notes': 'Notes conservées',
      if (recordParty) 'recordParty': true,
    }) as SceneFinishGameConsequence;

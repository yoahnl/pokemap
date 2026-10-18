import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  testWidgets('party predicates are guided rather than manually entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SceneConditionForm(
            project: ProjectManifest(name: 'Team', maps: [], tilesets: []),
            current: SceneConditionPayload(),
            onApply: (_) {},
          ),
        ),
      ),
    );
    final family = tester
        .widgetList<StudioSelect>(find.byType(StudioSelect))
        .first;
    expect(family.options, contains('partyState'));
  });

  testWidgets(
    'four party predicates and negation use catalogue and canonical field ability',
    (tester) async {
      final changes = <SceneConditionSource>[];
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: SceneConditionForm(
                  project: ProjectManifest(
                    name: 'Team',
                    maps: [],
                    tilesets: [],
                  ),
                  current: SceneConditionPayload(
                    conditionSource:
                        SceneConditionSource.partyCanReceivePokemon(),
                  ),
                  loadMoves: () async {
                    loads++;
                    return {'tackle': 'Charge'};
                  },
                  onApply: changes.add,
                ),
              ),
            ),
          ),
        ),
      );
      void select(String key, String value) => tester
          .widget<StudioSelect>(find.byKey(ValueKey(key)))
          .onChanged!(value);
      Future<void> apply() async {
        final button = find.text('Appliquer la condition');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
      }

      expect(loads, 0);
      select('scene-party-expected', 'false');
      await tester.pump();
      await apply();
      expect(
        changes.last.partyConditionKind,
        ScenePartyConditionKind.canReceivePokemon,
      );
      expect(changes.last.partyExpected, isFalse);
      for (final kind in [
        ScenePartyConditionKind.knowsMove,
        ScenePartyConditionKind.hasUsableMove,
      ]) {
        select('scene-party-kind', kind.name);
        await tester.pumpAndSettle();
        select('scene-party-move', 'tackle');
        await tester.pump();
        await apply();
        expect(changes.last.partyConditionKind, kind);
        expect(changes.last.partyMoveId, 'tackle');
        expect(changes.last.partyExpected, isFalse);
      }
      select('scene-party-kind', 'canUseFieldAbility');
      await tester.pump();
      select('scene-party-ability', 'rock_smash');
      await tester.pump();
      await apply();
      expect(changes.last.partyFieldAbility, FieldAbility.rockSmash);
      expect(changes.last.value, 'rock_smash');
      expect(loads, 2);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing catalogue and stale project cannot replace a saved move reference',
    (tester) async {
      final pending = Completer<Map<String, String>>();
      final current = SceneConditionPayload(
        conditionSource: SceneConditionSource.partyKnowsMove(moveId: 'missing'),
      );
      var applied = false;
      Future<void> mount(
        String name,
        Future<Map<String, String>> Function() loader,
      ) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: SceneConditionForm(
                  project: ProjectManifest(name: name, maps: [], tilesets: []),
                  current: current,
                  loadMoves: loader,
                  onApply: (_) => applied = true,
                ),
              ),
            ),
          ),
        ),
      );
      await mount('Old', () => pending.future);
      await mount('New', () async => throw StateError('Unavailable'));
      await tester.pumpAndSettle();
      pending.complete({'missing': 'Stale'});
      await tester.pumpAndSettle();
      expect(find.textContaining('indisponible ou ambigu'), findsOneWidget);
      expect(
        tester
            .widgetList<StudioSelect>(find.byType(StudioSelect))
            .singleWhere(
              (field) => field.key == const ValueKey('scene-party-move'),
            )
            .options,
        isEmpty,
      );
      expect(applied, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real inspector condition supports undo redo canonical publication and reopen',
    (tester) async {
      final scene = SceneAsset(
        id: 'team',
        name: 'Équipe',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'check',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.partyCanReceivePokemon(),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'check',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'yes',
              fromNodeId: 'check',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'no',
              fromNodeId: 'check',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
      );
      final fixture = (await tester.runAsync(() async {
        final f = await CinematicAdapterFixture.create();
        final project = (await f.readManifest()).copyWith(
          scenes: [scene],
          pokemon: (await f.readManifest()).pokemon.copyWith(
            enabled: true,
            catalogFiles: {'moves': 'data/moves.json'},
          ),
        );
        final moves = f.file('data/moves.json');
        await moves.parent.create(recursive: true);
        await moves.writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'kind': 'catalog',
            'catalog': 'moves',
            'entries': [
              {'id': 'tackle', 'name': 'Charge'},
            ],
          }),
        );
        await f.writeManifest(project);
        await f.maps.loadProject(f.session);
        return f;
      }))!;
      addTearDown(() => fixture.dispose());
      final project = (await tester.runAsync(fixture.readManifest))!;
      final session = SceneEditSession(scene, base: scene);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: StatefulBuilder(
                builder: (context, refresh) => SceneInspector(
                  session: session,
                  project: project,
                  nodeId: 'check',
                  edgeId: null,
                  changed: () => refresh(() {}),
                  onDocument: (_) {},
                  onDelete: () {},
                  onDuplicate: () {},
                  loadMoves: () async => {'tackle': 'Charge'},
                ),
              ),
            ),
          ),
        ),
      );
      tester
          .widget<StudioSelect>(find.byKey(const ValueKey('scene-party-kind')))
          .onChanged!('knowsMove');
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(find.byKey(const ValueKey('scene-party-move')))
          .onChanged!('tackle');
      await tester.pump();
      final button = find.text('Appliquer la condition');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(session.undoCount, 1);
      final edited = session.current;
      session.restore(redo: false);
      expect(session.current, scene);
      session.restore(redo: true);
      expect(session.current, edited);
      final reopened = (await tester.runAsync(() async {
        await LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ).publishScene(base: scene, current: edited);
        return LocalMapWorkspaceAdapter().loadProject(fixture.session);
      }))!;
      expect(reopened.scenes.single, edited);
      expect(reopened.scenes.single.graph.edges, scene.graph.edges);
      expect(reopened.scenes.single.layout, scene.layout);
      expect(reopened.facts, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '3D field ability explains availability without disabling negation',
    (tester) async {
      SceneConditionSource? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: SceneConditionForm(
                  project: ProjectManifest(
                    name: 'Spatial',
                    version: ProjectVersion.v9,
                    settings: const ProjectSettings(
                      dimension: ProjectDimension.threeD,
                    ),
                    maps: [],
                    tilesets: [],
                  ),
                  current: SceneConditionPayload(
                    conditionSource:
                        SceneConditionSource.partyCanUseFieldAbility(
                          ability: FieldAbility.surf,
                          expected: false,
                        ),
                  ),
                  onApply: (source) => saved = source,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Player 2D'), findsOneWidget);
      expect(find.textContaining('PP0'), findsOneWidget);
      final apply = find.text('Appliquer la condition');
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pump();
      expect(saved!.partyExpected, isFalse);
      expect(saved!.partyFieldAbility, FieldAbility.surf);
      expect(tester.takeException(), isNull);
    },
  );
}

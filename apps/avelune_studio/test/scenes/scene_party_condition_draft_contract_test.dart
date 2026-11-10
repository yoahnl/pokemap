import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_condition_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  test('party predicates retain negation and load exact move references only when required', () async {
    var loads = 0;
    final draft = SceneConditionDraft(
      project: const ProjectManifest(name: 'Team', maps: [], tilesets: []),
      current: SceneConditionPayload(
        conditionSource: SceneConditionSource.partyCanReceivePokemon(),
      ),
      changed: () {},
      loadMoves: () async {
        loads++;
        return {'tackle': 'Charge'};
      },
    );
    addTearDown(draft.dispose);
    expect(draft.availableFamilies, contains('partyState'));
    expect(loads, 0);
    draft.expected = false;
    expect(
      draft.prepared!.partyConditionKind,
      ScenePartyConditionKind.canReceivePokemon,
    );
    expect(draft.prepared!.partyExpected, isFalse);
    for (final kind in [
      ScenePartyConditionKind.knowsMove,
      ScenePartyConditionKind.hasUsableMove,
    ]) {
      draft.partyKind = kind;
      await draft.loadPartyMoves();
      draft.referenceId = 'tackle';
      expect(draft.prepared!.partyConditionKind, kind);
      expect(draft.prepared!.partyMoveId, 'tackle');
      expect(draft.prepared!.partyExpected, isFalse);
    }
    draft.selectPartyKind('canUseFieldAbility');
    draft.ability = FieldAbility.rockSmash;
    expect(draft.prepared!.partyFieldAbility, FieldAbility.rockSmash);
    expect(draft.prepared!.value, 'rock_smash');
    expect(loads, 2);
  });

  test('missing move catalogue and stale project responses preserve the saved reference', () async {
    final pending = Completer<Map<String, String>>();
    final current = SceneConditionPayload(
      conditionSource: SceneConditionSource.partyKnowsMove(moveId: 'missing'),
    );
    final draft = SceneConditionDraft(
      project: const ProjectManifest(name: 'Old', maps: [], tilesets: []),
      current: current,
      changed: () {},
      loadMoves: () => pending.future,
    );
    addTearDown(draft.dispose);
    draft.configure(
      project: const ProjectManifest(name: 'New', maps: [], tilesets: []),
      current: current,
      loadMoves: () async => throw StateError('Unavailable'),
      loadItems: null,
      loadMap: null,
    );
    await draft.loadPartyMoves();
    pending.complete({'missing': 'Stale'});
    await pending.future;
    expect(draft.movesError, contains('indisponible ou ambigu'));
    expect(draft.moveOptions, isEmpty);
    expect(draft.prepared, isNull);
    expect(draft.current, same(current));
  });

  test(
    '3D field ability keeps the canonical ability and negative expectation',
    () {
      final current = SceneConditionPayload(
        conditionSource: SceneConditionSource.partyCanUseFieldAbility(
          ability: FieldAbility.surf,
          expected: false,
        ),
      );
      final draft = SceneConditionDraft(
        project: const ProjectManifest(
          name: 'Spatial',
          version: ProjectVersion.v9,
          settings: ProjectSettings(dimension: ProjectDimension.threeD),
          maps: [],
          tilesets: [],
        ),
        current: current,
        changed: () {},
      );
      addTearDown(draft.dispose);
      expect(draft.prepared!.partyExpected, isFalse);
      expect(draft.prepared!.partyFieldAbility, FieldAbility.surf);
      expect(draft.current, same(current));
    },
  );

  test('party condition draft supports native undo redo publication and cold reopen', () async {
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
    final fixture = await CinematicAdapterFixture.create();
    addTearDown(fixture.dispose);
    final initial = await fixture.readManifest();
    final project = initial.copyWith(
      scenes: [scene],
      pokemon: initial.pokemon.copyWith(
        enabled: true,
        catalogFiles: {'moves': 'data/moves.json'},
      ),
    );
    final moves = fixture.file('data/moves.json');
    await moves.parent.create(recursive: true);
    await moves.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'kind': 'pokemon_catalog',
        'catalog': 'moves',
        'entries': [
          {'id': 'tackle', 'name': 'Charge'},
        ],
      }),
    );
    await fixture.writeManifest(project);
    await fixture.maps.loadProject(fixture.session);
    final before = await moves.readAsBytes();
    final session = SceneEditSession(scene, base: scene);
    final node = scene.graph.nodes.singleWhere((node) => node.id == 'check');
    final draft = SceneConditionDraft(
      project: project,
      current: node.payload as SceneConditionPayload,
      changed: () {},
      loadMoves: () async => {'tackle': 'Charge'},
    );
    addTearDown(draft.dispose);
    draft.partyKind = ScenePartyConditionKind.knowsMove;
    await draft.loadPartyMoves();
    draft.referenceId = 'tackle';
    expect(
      session.replacePayload(
        node,
        SceneConditionPayload(conditionSource: draft.prepared!),
      ),
      isTrue,
    );
    expect(session.undoCount, 1);
    final edited = session.current;
    session.restore(redo: false);
    expect(session.current, scene);
    session.restore(redo: true);
    expect(session.current, edited);
    await LocalSceneAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ).publishScene(base: scene, current: edited);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(reopened.scenes.single, edited);
    expect(reopened.scenes.single.graph.edges, scene.graph.edges);
    expect(reopened.scenes.single.layout, scene.layout);
    expect(reopened.facts, isEmpty);
    expect(await moves.readAsBytes(), before);
  });
}

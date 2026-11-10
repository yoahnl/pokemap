import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_pokemon_gift_moves_draft.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  for (final interactive in [false, true]) {
    test(
      '${interactive ? 'interactive' : 'consequence'} gift owners preserve ordered moves through one apply undo redo publication and cold reopen',
      () async {
        final scene = _scene(interactive);
        final node = scene.graph.nodes.singleWhere((node) => node.id == 'gift');
        final original = node.payload as SceneActionPayload;
        final fixture = await CinematicAdapterFixture.create(scenes: [scene]);
        addTearDown(fixture.dispose);
        final initial = await fixture.readManifest();
        final movesFile = fixture.file('data/moves.json');
        await movesFile.parent.create(recursive: true);
        await movesFile.writeAsString(
          jsonEncode({
            'schemaVersion': 1,
            'kind': 'pokemon_catalog',
            'catalog': 'moves',
            'entries': [
              {'id': 'exceptional', 'name': 'Capacité exceptionnelle'},
              {'id': 'tackle', 'name': 'Charge'},
            ],
          }),
        );
        await fixture.writeManifest(
          initial.copyWith(
            pokemon: initial.pokemon.copyWith(
              enabled: true,
              catalogFiles: {'moves': 'data/moves.json'},
            ),
          ),
        );
        await fixture.maps.loadProject(fixture.session);
        final project = await fixture.readManifest();
        final beforeDisk = await fixture.file('project.json').readAsBytes();
        final session = SceneEditSession(scene, base: scene);
        final action = SceneActionDraft(
          project: project,
          current: original,
          changed: () {},
          loadMoves: _moves,
          loadSpecies: _species,
        );
        addTearDown(action.dispose);
        final moves = ScenePokemonGiftMovesDraft(
          value: action.giftMoves,
          catalogueScope: project,
          changed: () {},
          onChanged: action.setGiftMoves,
          onValidityChanged: action.setGiftMovesValid,
          loadMoves: _moves,
        );
        addTearDown(moves.dispose);
        void refreshMoves() => moves.configure(
          value: action.giftMoves,
          catalogueScope: project,
          loadMoves: _moves,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          action.commandId,
          interactive
              ? NarrativeCommandIds.receivePokemonFromCatalog
              : NarrativeCommandIds.givePokemonFromCatalog,
        );
        expect(action.giftMoves, isNull);
        expect(action.valid, isTrue);
        moves.change(['']);
        refreshMoves();
        await Future<void>.delayed(Duration.zero);
        expect(moves.valid, isFalse);
        expect(action.valid, isFalse);
        moves.change(['exceptional']);
        refreshMoves();
        expect(action.valid, isTrue);
        moves.change([...moves.value!, '']);
        refreshMoves();
        expect(action.valid, isFalse);
        moves.change(['exceptional', 'tackle']);
        refreshMoves();
        expect(action.valid, isTrue);
        moves.swap(0, 1);
        refreshMoves();
        expect(action.giftMoves, ['tackle', 'exceptional']);
        moves.swap(1, 0);
        refreshMoves();
        expect(action.giftMoves, ['exceptional', 'tackle']);
        expect(action.valid, isTrue);
        expect(session.current, scene);
        expect(session.undoCount, 0);
        expect(session.revision, 0);
        expect(session.dirty, isFalse);
        expect(action.current, same(original));
        expect(await fixture.file('project.json').readAsBytes(), beforeDisk);
        final applied = action.buildPayload() as SceneActionPayload;
        final expected = {
          ...(original.consequence?.toJson() ??
              original.interactiveCommand!.toJson()),
          'moveIds': ['exceptional', 'tackle'],
        };
        expect(_command(applied), expected);
        expect(session.replacePayload(node, applied), isTrue);
        expect(session.undoCount, 1);
        expect(session.revision, 1);
        expect(session.dirty, isTrue);
        final edited = session.current;
        expect(_command(_gift(edited)), expected);
        final editedNode = edited.graph.nodes.singleWhere(
          (node) => node.id == 'gift',
        );
        expect(editedNode.title, node.title);
        expect(editedNode.description, node.description);
        expect(edited.graph.edges, scene.graph.edges);
        expect(edited.layout, scene.layout);
        expect(edited.metadata, scene.metadata);
        expect(session.replacePayload(node, applied), isFalse);
        expect(session.undoCount, 1);
        expect(session.revision, 1);
        session.restore(redo: false);
        expect(session.current, scene);
        expect(session.dirty, isFalse);
        expect(session.canUndo, isFalse);
        expect(session.canRedo, isTrue);
        session.restore(redo: true);
        expect(session.current, edited);
        expect(session.undoCount, 1);
        expect(session.canRedo, isFalse);
        expect(await fixture.file('project.json').readAsBytes(), beforeDisk);
        await LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ).publishScene(base: scene, current: session.current);
        final reopened = await LocalMapWorkspaceAdapter().loadProject(
          fixture.session,
        );
        expect(reopened.scenes.single, edited);
        expect(_command(_gift(reopened.scenes.single)), expected);
        expect(reopened.scenes.single.graph.edges, scene.graph.edges);
        expect(reopened.scenes.single.layout, scene.layout);
        expect(reopened.scenes.single.metadata, scene.metadata);
      },
    );
  }
}

Map<String, dynamic> _command(SceneActionPayload payload) =>
    payload.consequence?.toJson() ?? payload.interactiveCommand!.toJson();

SceneActionPayload _gift(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'gift').payload
        as SceneActionPayload;

SceneAsset _scene(bool interactive) => SceneAsset(
  id: 'gift-scene',
  name: 'Compagnon',
  metadata: const {'preserved': 'gift'},
  layout: SceneGraphLayout(
    nodeLayouts: [
      SceneNodeLayout(nodeId: 'start', x: 40, y: 80),
      SceneNodeLayout(nodeId: 'gift', x: 320, y: 80),
      SceneNodeLayout(nodeId: 'end', x: 600, y: 80),
    ],
    edgeLayouts: [
      SceneEdgeLayout(
        edgeId: 'enter',
        controlPoints: [SceneLayoutPoint(x: 200, y: 40)],
      ),
    ],
  ),
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'gift',
        kind: SceneNodeKind.action,
        title: 'Compagnon choisi',
        description: 'Capacités ordonnées',
        payload: interactive
            ? SceneActionPayload.interactive(
                SceneInteractiveCommand.receivePokemonFromCatalog(
                  speciesId: 'bird',
                  formId: 'base',
                  level: 8,
                  nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
                  nicknameMaxGraphemes: 12,
                  pokedexPresentationPolicy:
                      ScenePokemonGiftPokedexPresentationPolicy.never,
                ),
              )
            : SceneActionPayload.consequence(
                SceneConsequence.givePokemonFromCatalog(
                  speciesId: 'bird',
                  formId: 'base',
                  level: 8,
                ),
              ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'gift',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port
          in interactive ? ['party', 'pc', 'noCapacity'] : ['completed'])
        SceneEdge(
          id: 'leave-$port',
          fromNodeId: 'gift',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

Future<Map<String, String>> _moves() async => {
  'exceptional': 'Capacité exceptionnelle',
  'tackle': 'Charge',
};

Future<List<PokemonSpeciesSummary>> _species() async => const [
  PokemonSpeciesSummary(
    id: 'bird',
    name: 'Oiseau',
    nationalDex: 1,
    generation: 1,
    types: ['normal'],
    formIds: ['base'],
    baseFormId: 'base',
    mediaRelativePath: '',
    enabled: true,
    relativePath: 'bird.json',
  ),
];

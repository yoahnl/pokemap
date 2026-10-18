import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  for (final interactive in [false, true]) {
    testWidgets(
      '${interactive ? 'interactive' : 'consequence'} gift inspector supports undo redo canonical publication and reopen',
      (tester) async {
        final scene = SceneAsset(
          id: 'gift-scene',
          name: 'Compagnon',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'gift',
                kind: SceneNodeKind.action,
                payload: interactive
                    ? SceneActionPayload.interactive(
                        SceneInteractiveCommand.receivePokemonFromCatalog(
                          speciesId: 'bird',
                          formId: 'base',
                          level: 8,
                          nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer,
                          nicknameMaxGraphemes: 12,
                          pokedexPresentationPolicy: ScenePokemonGiftPokedexPresentationPolicy.never,
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
                  in interactive
                      ? ['party', 'pc', 'noCapacity']
                      : ['completed'])
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
        final fixture = (await tester.runAsync(() async {
          final fixture = await CinematicAdapterFixture.create();
          final original = await fixture.readManifest();
          final moves = fixture.file('data/moves.json');
          await moves.parent.create(recursive: true);
          await moves.writeAsString(
            jsonEncode({
              'schemaVersion': 1,
              'kind': 'catalog',
              'catalog': 'moves',
              'entries': [
                {'id': 'exceptional', 'name': 'Capacité exceptionnelle'},
                {'id': 'tackle', 'name': 'Charge'},
              ],
            }),
          );
          await fixture.writeManifest(
            original.copyWith(
              scenes: [scene],
              pokemon: original.pokemon.copyWith(
                enabled: true,
                catalogFiles: {'moves': 'data/moves.json'},
              ),
            ),
          );
          await fixture.maps.loadProject(fixture.session);
          return fixture;
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
                      nodeId: 'gift',
                      edgeId: null,
                      changed: () => refresh(() {}),
                      onDocument: (_) {},
                      onDelete: () {},
                      onDuplicate: () {},
                      loadMoves: _moves,
                      loadSpecies: _species,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('scene-gift-move-mode')),
            )
            .onChanged!('explicit');
        await tester.pumpAndSettle();
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('scene-gift-move-0')),
            )
            .onChanged!('exceptional');
        await tester.pump();
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('scene-gift-move-add')),
            )
            .onPressed!();
        await tester.pump();
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('scene-gift-move-1')),
            )
            .onChanged!('tackle');
        await tester.pump();
        final apply = find.text('Appliquer l’action');
        await tester.ensureVisible(apply);
        await tester.pumpAndSettle();
        await tester.tap(apply);
        await tester.pumpAndSettle();
        expect(session.undoCount, 1);
        final edited = session.current;
        final payload =
            edited.graph.nodes.singleWhere((node) => node.id == 'gift').payload
                as SceneActionPayload;
        expect(
          (payload.consequence?.toJson() ??
              payload.interactiveCommand!.toJson())['moveIds'],
          ['exceptional', 'tackle'],
        );
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
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

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

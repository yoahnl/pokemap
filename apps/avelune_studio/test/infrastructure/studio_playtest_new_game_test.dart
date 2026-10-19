import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../tool/create_example_project.dart';

void main() {
  testWidgets('cancelling the player name returns to the editor', (tester) async {
    late Directory root;
    late ProjectSession session;
    late ProjectManifest project;
    late String revision;
    late String originalManifest;
    var port = LocalMapWorkspaceAdapter();
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('studio-cancel-start-');
      await writeExampleProject(root);
      session = ProjectSession(
        sessionId: 'cancel-start',
        name: 'Cancel start',
        directoryPath: await root.resolveSymbolicLinks(),
      );
      final base = await port.loadProject(session);
      project = const SceneActions().createPreSessionScene(
        base.copyWith(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'jardin',
            startSpawnId: 'depart',
          ),
        ),
        maps: [exampleMap('jardin', 'Jardin des essais')],
        sceneId: 'cancel-start',
        name: 'Départ annulable',
        templateId: 'identitySetup',
        setAsEntrypoint: true,
      );
      originalManifest = jsonEncode(project.toJson());
      await File('${root.path}/project.json').writeAsString(originalManifest);
      port = LocalMapWorkspaceAdapter();
      await port.loadProject(session);
      revision = (await port.loadMap(session, project.maps.first)).revision;
    });
    addTearDown(() => root.delete(recursive: true));
    final saves = StudioPlaytestSession();
    var closed = 0;
    var playtestOpen = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setHostState) => playtestOpen
                ? StudioPlaytestView(
                    session: session,
                    entry: project.maps.first,
                    expectedRevision: revision,
                    port: port,
                    testSession: saves,
                    onClose: () => setHostState(() {
                      closed++;
                      playtestOpen = false;
                    }),
                  )
                : const Text('Éditeur de carte'),
          ),
        ),
      ),
    );
    await _waitFor(tester, find.byType(PlayerSceneInteractionSurface));
    expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
    await tester.tap(find.byKey(const ValueKey('scene-interaction-cancel')));
    await _waitFor(tester, find.text('Éditeur de carte'));
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(find.byType(StudioPlaytestView), findsNothing);
    expect(find.byType(PlayerSceneInteractionSurface), findsNothing);
    expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
    expect(find.textContaining('Le test ne peut pas démarrer'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(saves.hasSave, isFalse);
    expect(await saves.load(), isNull);
    await tester.runAsync(() async {
      expect(
        await File('${root.path}/project.json').readAsString(),
        originalManifest,
      );
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'normal playtest asks for a starter and resets through the same flow',
    (tester) async {
      late Directory root;
      late ProjectSession session;
      late ProjectManifest project;
      late String revision;
      late String originalManifest;
      var port = LocalMapWorkspaceAdapter();
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('studio-guided-start-');
        await writeExampleProject(root);
        final speciesRoot = await Directory('${root.path}/data/pokemon/species')
            .create(recursive: true);
        for (final id in ['first', 'second']) {
          await File('${speciesRoot.path}/$id.json').writeAsString(
            jsonEncode({
              'schemaVersion': 1,
              'id': id,
              'typing': {
                'types': ['normal'],
              },
              'baseStats': {
                'hp': 45,
                'atk': 45,
                'def': 45,
                'spa': 45,
                'spd': 45,
                'spe': 45,
              },
              'abilities': {'primary': 'run_away'},
              'progression': {
                'growthRateId': 'medium_fast',
                'baseExp': 64,
                'catchRate': 45,
              },
            }),
          );
        }
        session = ProjectSession(
          sessionId: 'guided-start',
          name: 'Guided start',
          directoryPath: await root.resolveSymbolicLinks(),
        );
        final base = await port.loadProject(session);
        project = const SceneActions().createPreSessionScene(
          base.copyWith(
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'jardin',
              startSpawnId: 'depart',
              starterOptions: [
                ProjectStarterOption(
                  id: 'first',
                  label: 'Premier compagnon',
                  pokemon: PlayerPokemon(
                    speciesId: 'first',
                    natureId: 'hardy',
                    abilityId: 'run_away',
                  ),
                ),
                ProjectStarterOption(
                  id: 'second',
                  label: 'Second compagnon',
                  pokemon: PlayerPokemon(
                    speciesId: 'second',
                    natureId: 'hardy',
                    abilityId: 'run_away',
                  ),
                ),
              ],
            ),
          ),
          maps: [exampleMap('jardin', 'Jardin des essais')],
          sceneId: 'guided-start',
          name: 'Départ guidé',
          templateId: 'identitySetup',
          setAsEntrypoint: true,
        );
        originalManifest = jsonEncode(project.toJson());
        await File('${root.path}/project.json').writeAsString(originalManifest);
        port = LocalMapWorkspaceAdapter();
        await port.loadProject(session);
        revision = (await port.loadMap(session, project.maps.first)).revision;
      });
      addTearDown(() => root.delete(recursive: true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioPlaytestView(
              session: session,
              entry: project.maps.first,
              expectedRevision: revision,
              port: port,
              onClose: () {},
            ),
          ),
        ),
      );
      await _waitFor(tester, find.byType(PlayerSceneInteractionSurface));
      expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('scene-interaction-text-field')),
        'Yoahn',
      );
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-text-submit')),
      );
      await _waitFor(tester, find.text('Second compagnon'));
      await tester.tap(find.text('Second compagnon'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('scene-interaction-selection-submit')),
      );
      await _waitFor(tester, find.byType(GameWidget<PlayableMapGame>));
      final game = tester
          .widget<GameWidget<PlayableMapGame>>(
            find.byType(GameWidget<PlayableMapGame>),
          )
          .game!;
      for (var attempt = 0; attempt < 300; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 16));
        if (game.isLoaded && !game.debugIsMapActivationDispatchInFlight) break;
      }
      expect(game.isLoaded, isTrue);
      expect(game.gameStateSnapshot.party.members.single.speciesId, 'second');
      expect(game.gameStateSnapshot.trainerProfile.name, 'Yoahn');
      expect(game.gameStateSnapshot.currentMapId, 'jardin');
      await tester.tap(find.text('Enregistrer le test'));
      await _waitFor(
        tester,
        find.text('Test enregistré en mémoire pour cette session.'),
      );
      await tester.tap(find.text('Reprendre le test'));
      await _waitFor(tester, find.text('Sauvegarde du test reprise.'));
      expect(game.gameStateSnapshot.party.members.single.speciesId, 'second');
      await tester.tap(find.text('Nouvelle partie'));
      await _waitFor(tester, find.byType(PlayerSceneInteractionSurface));
      expect(find.byType(GameWidget<PlayableMapGame>), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        expect(
          await File('${root.path}/project.json').readAsString(),
          originalManifest,
        );
      });
    },
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

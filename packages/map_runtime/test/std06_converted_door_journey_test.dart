import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        installConvertedQaHeadlessAudio,
        mountConvertedQaGame,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(installConvertedQaHeadlessAudio);
  final referencePath = Platform.environment['AVELUNE_STD06_DOOR_REFERENCE'];
  testWidgets(
    'converted generic doors return control and survive a cold save',
    (tester) async {
      await tester.runAsync(() async {
        final reference = jsonDecode(
          await File(referencePath!).readAsString(),
        ) as Map<String, dynamic>;
        expect(reference['kind'], 'std06ConvertedDoorFixture');
        expect(reference['sourceScriptsExecuted'], 0);
        expect(reference['aiCalls'], 0);
        expect(reference['nativeWriterVerified'], isTrue);
        final projectPath = reference['projectFilePath'] as String;
        final projectFile = await FileSystemEntity.isDirectory(projectPath)
            ? '$projectPath/project.json'
            : projectPath;
        final firstMap = reference['startMapId'] as String;
        final secondMap = reference['otherMapId'] as String;
        final studioEditPath =
            Platform.environment['AVELUNE_STD06_STUDIO_EDIT'];
        if (studioEditPath != null) {
          final edit =
              jsonDecode(await File(studioEditPath).readAsString()) as Map;
          expect(edit['reopenVerified'], isTrue);
          final project = await loadProjectManifestFromFile(projectFile);
          final scene = project.scenes.singleWhere(
            (scene) => scene.id == edit['sceneId'],
          );
          final payload =
              scene.graph.nodes
                      .singleWhere((node) => node.id == edit['nodeId'])
                      .payload
                  as SceneActionPayload;
          final route =
              payload.interactiveCommand as SceneActorRouteInteractiveCommand;
          expect(
            route.steps.whereType<SceneActorMoveStep>().single.durationMs,
            edit['durationMs'],
          );
        }
        final spawn = GridPos.fromJson(
          reference['spawn'] as Map<String, dynamic>,
        );
        final arrival = GridPos.fromJson(
          reference['arrival'] as Map<String, dynamic>,
        );
        final temporary = await Directory.systemTemp.createTemp(
          'std06-door-save-',
        );
        final saves = ConvertedQaDiskSave('${temporary.path}/save.json');
        PlayableMapGame? game;
        try {
          game = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            GameState(
              saveId: 'std06-generic-door',
              currentMapId: firstMap,
              playerPosition: spawn,
              playerFacing: EntityFacing.north,
            ),
          );
          final active = game;
          Future<void> crossDoor(String destination) async {
            expect(
              active.handleRuntimeInputEvent(
                const RuntimeInputEvent.press(RuntimeInputControl.up),
              ),
              isTrue,
            );
            try {
              for (var tick = 0; tick < 1200; tick++) {
                active.update(.025);
                await active.ready();
                await Future<void>.delayed(const Duration(milliseconds: 1));
                if (active.gameStateSnapshot.currentMapId == destination) break;
              }
            } finally {
              active.handleRuntimeInputEvent(
                const RuntimeInputEvent.release(RuntimeInputControl.up),
              );
            }
            await waitConvertedQaIdle(active);
            expect(active.gameStateSnapshot.currentMapId, destination);
            expect(active.debugPlayerGridPosition, arrival);
            expect(active.debugIsPlayerVisible, isTrue);
            expect(active.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          }

          await crossDoor(secondMap);
          await crossDoor(firstMap);
          expect(await active.saveGame(), isTrue);
          final saved = (await saves.load())!;
          expect(saved.currentMapId, firstMap);
          expect(saved.playerPosition, arrival);
          active.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;
          final reopened = await mountConvertedQaGame(
            tester,
            projectFile,
            saves,
            saved,
            restoredSave: saveDataFromGameState(saved),
          );
          game = reopened;
          await waitConvertedQaIdle(reopened);
          expect(reopened.gameStateSnapshot.currentMapId, firstMap);
          expect(reopened.debugPlayerGridPosition, arrival);
          expect(reopened.debugIsPlayerVisible, isTrue);
          expect(reopened.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await temporary.delete(recursive: true);
        }
      });
    },
    skip: referencePath == null,
  );
}

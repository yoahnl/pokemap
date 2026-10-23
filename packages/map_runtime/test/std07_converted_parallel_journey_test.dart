import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        mountConvertedQaGame,
        installConvertedQaHeadlessAudio,
        pressConvertedQaPrimary,
        driveConvertedQaDialogue,
        waitConvertedQaIdle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_STD07_PLAYER_REFERENCE'];
  setUp(installConvertedQaHeadlessAudio);
  testWidgets(
    'converted parallel process reacts to local acquisition without map reentry',
    (tester) async {
      await tester.runAsync(() async {
        final reference =
            jsonDecode(await File(referencePath!).readAsString()) as Map;
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['strictReopenVerified'], isTrue);
        final projectFile = reference['projectFilePath'] as String;
        final manifest = await loadProjectManifestFromFile(projectFile);
        final saveRoot = await Directory.systemTemp.createTemp(
          'std07-player-save-',
        );
        final repository = ConvertedQaDiskSave(
          path.join(saveRoot.path, 'save.json'),
        );
        final spawn = reference['spawn'] as Map;
        final initial = GameState(
          saveId: 'std07-converted',
          currentMapId: reference['startMapId'] as String,
          playerPosition: GridPos(x: spawn['x'] as int, y: spawn['y'] as int),
        );
        PlayableMapGame? active;
        bool fact(PlayableMapGame game, String key) =>
            game.gameStateSnapshot.narrativeFactRuntimeState
                .valueFor(reference[key] as String)
                ?.boolValue ??
            manifest.facts
                .singleWhere((fact) => fact.id == reference[key])
                .defaultValue;
        try {
          final game = await mountConvertedQaGame(
            tester,
            projectFile,
            repository,
            initial,
          );
          active = game;
          game.resumeEngine();
          for (var tick = 0; tick < 20; tick++) {
            game.update(.025);
            await Future<void>.delayed(Duration.zero);
          }
          expect(fact(game, 'ownGuardFactId'), isFalse);
          expect(fact(game, 'foreignTargetFactId'), isFalse);
          expect(game.debugIsGameplayInputLocked, isFalse);
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.down),
          );
          for (var tick = 0; tick < 4; tick++) {
            game.update(.025);
            await Future<void>.delayed(Duration.zero);
          }
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.down),
          );
          await waitConvertedQaIdle(game);
          pressConvertedQaPrimary(game);
          final lines = <String>[];
          await driveConvertedQaDialogue(game, lines, requireBattle: false);
          for (var tick = 0; tick < 24; tick++) {
            game.update(.025);
            await Future<void>.delayed(Duration.zero);
          }
          expect(game.gameStateSnapshot.currentMapId, initial.currentMapId);
          expect(
            game.gameStateSnapshot.bag.entries.any(
              (entry) =>
                  entry.itemId == reference['itemId'] && entry.quantity == 1,
            ),
            isTrue,
          );
          expect(fact(game, 'ownGuardFactId'), isTrue);
          expect(fact(game, 'foreignTargetFactId'), isTrue);
          expect(game.debugIsGameplayInputLocked, isFalse);
          expect(await game.saveGame(), isTrue);
          final saved = game.gameStateSnapshot;
          game.onRemove();
          active = null;
          await tester.pumpWidget(const SizedBox.shrink());
          final reloaded = await mountConvertedQaGame(
            tester,
            projectFile,
            repository,
            initial,
          );
          active = reloaded;
          expect(await reloaded.loadGame(), isTrue);
          await waitConvertedQaIdle(reloaded);
          expect(reloaded.gameStateSnapshot.bag, saved.bag);
          expect(fact(reloaded, 'ownGuardFactId'), isTrue);
          expect(fact(reloaded, 'foreignTargetFactId'), isTrue);
        } finally {
          active?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
      });
    },
    skip: referencePath == null,
  );
}

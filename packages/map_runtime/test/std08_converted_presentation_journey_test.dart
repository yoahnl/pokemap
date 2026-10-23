import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'source_converted_gym_reward_journey_test.dart'
    show
        ConvertedQaDiskSave,
        mountConvertedQaGame,
        installConvertedQaHeadlessAudio,
        pressConvertedQaPrimary;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_STD08_PLAYER_REFERENCE'];
  setUp(() => installConvertedQaHeadlessAudio(completePlayback: true));
  testWidgets(
    'source converted pictures enter through the real Event V2 interaction on both maps',
    (tester) async {
      await tester.runAsync(() async {
        final reference =
            jsonDecode(await File(referencePath!).readAsString()) as Map;
        expect(reference['nativeWriterVerified'], isTrue);
        expect(reference['strictReopenVerified'], isTrue);
        final root = reference['projectFilePath'] as String;
        final projectFile = root.endsWith('.json')
            ? root
            : '$root/project.json';
        final saveRoot = await Directory.systemTemp.createTemp(
          'std08-converted-player-',
        );
        PlayableMapGame? active;
        try {
          for (final presentation
              in (reference['presentations'] as List).cast<Map>()) {
            final anchor = presentation['startAnchor'] as Map;
            final initial = GameState(
              saveId: 'std08-converted',
              currentMapId: presentation['mapId'] as String,
              playerPosition: GridPos(
                x: anchor['x'] as int,
                y: (anchor['y'] as int) + 1,
              ),
              playerFacing: EntityFacing.north,
            );
            final game = await mountConvertedQaGame(
              tester,
              projectFile,
              ConvertedQaDiskSave('${saveRoot.path}/save.json'),
              initial,
            );
            active = game;
            game.resumeEngine();
            pressConvertedQaPrimary(game);
            for (var tick = 0; tick < 400; tick++) {
              game.update(.025);
              await Future<void>.delayed(const Duration(milliseconds: 1));
              if (game.debugWorldPresentationFrame.pictures.isNotEmpty &&
                  !game.debugIsGameplayInputLocked &&
                  game.debugPendingSceneWaitCount == 0)
                break;
            }
            final picture = game.debugWorldPresentationFrame.pictures.single;
            expect(picture.mediaAssetId, reference['pictureMediaId']);
            expect(picture.scope, SceneVisualScope.map);
            expect(game.debugWorldPresentationVisible, isTrue);
            expect(game.debugIsGameplayInputLocked, isFalse);
            expect(await game.saveGame(), isTrue);
            game.onRemove();
            active = null;
            await tester.pumpWidget(const SizedBox.shrink());
          }
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

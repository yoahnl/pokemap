import 'dart:async';
import 'dart:io';

import 'package:avelune_attack_compare/main.dart' show extractPreviewResources;
import 'package:avelune_attack_compare/preview_game.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_sfx_player.dart';

final class _Voice implements AudioPlayer {
  final complete = StreamController<void>.broadcast();
  var resumes = 0;
  var stops = 0;
  var disposals = 0;
  var prepared = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPlayerComplete) return complete.stream;
    if (invocation.isSetter) return null;
    if (invocation.memberName == #setSource) prepared = true;
    if (invocation.memberName == #resume) resumes++;
    if (invocation.memberName == #stop) stops++;
    if (invocation.memberName == #dispose) {
      disposals++;
      return complete.close();
    }
    return Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  for (final delayed in [false, true]) {
    testWidgets(
      delayed
          ? 'does not start a clip that arrives after the attack'
          : 'plays one move clip at a source sound event and releases it',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final qaRoot = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
        final root = await tester.runAsync(
          () => extractPreviewResources(
            parent: qaRoot == null ? null : Directory(qaRoot),
          ),
        );
        addTearDown(() async {
          if (await root!.exists()) await root.delete(recursive: true);
        });
        final voices = <_Voice>[];
        var loads = 0;
        final pending = Completer<Uint8List?>();
        final status = ValueNotifier<String>('Preparing');
        final game = BattlePreviewGame(
          projectRoot: root!.path,
          move: const PreviewMove(
            'fissure',
            'Abîme',
            null,
            'ground',
            PsdkBattleMoveCategory.physical,
            bundleAsset: 'assets/bw2/batch/fissure.json',
          ),
          status: status,
          loadMoveAudio: (_) async {
            loads++;
            return delayed ? pending.future : Uint8List.fromList([1, 2, 3]);
          },
          soundPlayer: FlameAudioBattleSfxPlayer(
            playerFactory: () {
              final voice = _Voice();
              voices.add(voice);
              return voice;
            },
          ),
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 393,
              height: 852,
              child: GameWidget(game: game),
            ),
          ),
        );
        for (
          var tick = 0;
          tick < 360 && status.value != 'Combat prêt · appuie sur Lancer';
          tick++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 3)),
          );
        }
        expect(status.value, 'Combat prêt · appuie sur Lancer');
        unawaited(game.play());
        for (
          var tick = 0;
          tick < 600 && !status.value.contains('terminée');
          tick++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 3)),
          );
        }
        expect(status.value, contains('terminée'));
        expect(loads, 1);
        if (delayed) {
          expect(status.value, contains('sans son source'));
          pending.complete(Uint8List.fromList([1, 2, 3]));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          expect(voices.where((voice) => voice.prepared), isEmpty);
        } else {
          expect(status.value, contains('son approximatif'));
          final voice = voices.singleWhere((voice) => voice.prepared);
          expect(voice.resumes, 1);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        if (!delayed) {
          final voice = voices.singleWhere((voice) => voice.prepared);
          expect(voice.stops, 1);
          expect(voice.disposals, 1);
        }
        status.dispose();
      },
    );
  }
}

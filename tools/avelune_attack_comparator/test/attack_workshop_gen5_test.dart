import 'dart:io';

import 'package:avelune_attack_compare/main.dart' show extractPreviewResources;
import 'package:avelune_attack_compare/preview_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rootPath = Platform.environment['AVELUNE_ATTACK_WORKSHOP_QA'];
  for (final scenario in [
    (move: PreviewMove.tackle, player: 'gen5:totodile', enemy: 'gen5:pidgey'),
    (
      move: PreviewMove.surf,
      player: 'herdier-back.gif',
      enemy: 'trubbish-front.gif',
    ),
  ]) {
    testWidgets(
      'attack workshop loads sprites for ${scenario.move.label}',
      (tester) async {
        final root = (await tester.runAsync(() =>
            extractPreviewResources(parent: Directory(rootPath!))))!;
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        final status = ValueNotifier<String>('Preparing');
        final game = BattlePreviewGame(
          projectRoot: root.path,
          move: scenario.move,
          status: status,
        );
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 393, height: 852, child: GameWidget(game: game)),
        ));
        BattleOverlayComponent? overlay() {
          final values = game.children.whereType<BattleOverlayComponent>();
          return values.isEmpty ? null : values.first;
        }
        for (var i = 0; i < 360; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
          if ((overlay()?.debugPlayerCombatant?.currentSpriteSourcePath ?? '')
                  .endsWith(scenario.player) &&
              (overlay()?.debugEnemyCombatant?.currentSpriteSourcePath ?? '')
                  .endsWith(scenario.enemy)) {
            break;
          }
        }
        expect(overlay()?.debugPlayerCombatant?.currentSpriteSourcePath,
            endsWith(scenario.player));
        expect(overlay()?.debugEnemyCombatant?.currentSpriteSourcePath,
            endsWith(scenario.enemy));
        await tester.pumpWidget(const SizedBox());
        status.dispose();
      },
      skip: rootPath == null,
    );
  }
}

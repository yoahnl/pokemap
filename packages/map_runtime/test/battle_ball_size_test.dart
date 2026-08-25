import 'dart:ui' show Size;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Recette du 2026-08-25 : « la pokéball que l'on lance pour attraper un
/// pokémon sauvage est trop petite ».
///
/// BETA-BAT-024 avait déjà corrigé la Ball d'envoi, mais la formule se
/// mesurait sur le sprite VISÉ. Le sprite ennemi étant plus petit que celui
/// du joueur, la Ball de capture perdait ~30 % — alors que c'est la même
/// Ball, lancée par la même main.
const _stats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

Future<BattleOverlayComponent> _overlay(Vector2 viewport) async {
  final overlay = BattleOverlayComponent(
    session: createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: const BattleCombatantData(
          speciesId: 'grenousse',
          level: 5,
          maxHp: 20,
          currentHp: 20,
          stats: _stats,
          moves: <BattleMoveData>[
            BattleMoveData(id: 'ecras_face', name: 'Écras’Face', power: 20),
          ],
        ),
        enemyPokemon: const BattleCombatantData(
          speciesId: 'roucool',
          level: 5,
          maxHp: 20,
          currentHp: 20,
          stats: _stats,
          moves: <BattleMoveData>[
            BattleMoveData(id: 'tornade', name: 'Tornade', power: 20),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      ),
    ),
    viewportSize: viewport,
    onPlayerChoice: (_) {},
  );
  await overlay.onLoad();
  await overlay.waitForPendingVisualSync();
  return overlay;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final viewport in const <Size>[
    Size(640, 360),
    Size(844, 390),
    Size(390, 844),
  ]) {
    test(
        'la Ball garde la même taille quelle que soit la cible en '
        '${viewport.width.toInt()}x${viewport.height.toInt()}', () async {
      final overlay = await _overlay(
        Vector2(viewport.width, viewport.height),
      );
      final layout = BattleSceneLayout.forViewport(viewportSize: viewport);

      expect(
        overlay.debugBallCellSize,
        closeTo(layout.playerSpriteRect.height * (64 / 96), 0.001),
        reason: 'la Ball se mesure sur le sprite du joueur, pas sur la cible',
      );
      expect(
        overlay.debugBallCellSize,
        greaterThan(layout.enemySpriteRect.height * (64 / 96)),
        reason: 'l’ancienne formule, mesurée sur l’ennemi, la rendait plus '
            'petite à la capture qu’à l’envoi — c’est ce que la recette a vu',
      );
    });
  }

  test('la Ball reste visible par rapport au Pokémon', () async {
    const viewport = Size(640, 360);
    final overlay = await _overlay(Vector2(viewport.width, viewport.height));
    final layout = BattleSceneLayout.forViewport(viewportSize: viewport);

    // La cellule est très paddée : la Ball opaque occupe ~22 % de sa boîte.
    expect(
      overlay.debugBallCellSize / layout.playerSpriteRect.height,
      closeTo(64 / 96, 0.001),
    );
  });
}

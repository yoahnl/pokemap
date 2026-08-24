import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_flash_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

// BETA-BAT-031 — recette du 2026-08-24 (vidéo « combat animation ») :
// « pour la capture et la sortie de pokéball, tu as utilisé une technique un
// peu drôle, tu as rendu tout petit les pokémons ! mais on le voit quand
// même » et « l'ouverture de la pokéball que tu as fait est bien, mais ça
// manque de l'espèce de flash jolie ».
//
// Référence : Pokémon Platine. Le Pokémon n'apparaît jamais en miniature
// détaillée — il entre et sort en silhouette LUMINEUSE, précédée d'un éclat
// blanc.

BattleSession _session() => createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: const BattleCombatantData(
          speciesId: 'grenousse',
          level: 5,
          maxHp: 20,
          currentHp: 20,
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 90,
          ),
          moves: <BattleMoveData>[
            BattleMoveData(id: 'tackle', name: 'Charge', power: 20),
          ],
        ),
        enemyPokemon: const BattleCombatantData(
          speciesId: 'machop',
          level: 5,
          maxHp: 20,
          currentHp: 20,
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 10,
          ),
          moves: <BattleMoveData>[
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      ),
    );

Future<BattleOverlayComponent> _mount() async {
  final overlay = BattleOverlayComponent(
    session: _session(),
    viewportSize: Vector2(960, 540),
    onPlayerChoice: (_) {},
  );
  await overlay.onLoad();
  await overlay.waitForPendingVisualSync();
  return overlay;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('le Pokémon ne se montre plus en miniature', () {
    test(
        'la sortie de Ball allume une lueur qui masque le sprite, puis rend '
        'ses couleurs', () async {
      final overlay = await _mount();
      final player = overlay.debugPlayerCombatant!;

      await player.playMaterializeIn(durationSeconds: 0.2);
      player.update(0.05);

      expect(
        player.debugMaterializeGlowActive,
        isTrue,
        reason: 'un sprite détaillé réduit à quelques pixels reste un sprite',
      );
      expect(player.currentVisualToneColor, isNotNull);
      expect(
        player.currentVisualScaleX,
        lessThan(1),
        reason: 'il grandit encore : c’est bien pendant ce temps que la '
            'miniature se voyait',
      );

      for (var i = 0; i < 6; i++) {
        player.update(0.05);
      }
      expect(
        player.debugMaterializeGlowActive,
        isFalse,
        reason: 'sorti de sa Ball, il reprend ses couleurs',
      );
      expect(player.currentVisualToneColor, isNull);
    });

    test('l’absorption dans la Ball allume la même lueur', () async {
      final overlay = await _mount();
      final enemy = overlay.debugEnemyCombatant!;

      await enemy.playMaterializeOut(durationSeconds: 0.2);
      enemy.update(0.05);

      expect(enemy.debugMaterializeGlowActive, isTrue);
      expect(enemy.currentVisualToneColor, isNotNull);
    });

    test(
        'une silhouette se mélange PLEINEMENT, une teinte d’état reste '
        'légère', () async {
      final overlay = await _mount();
      final enemy = overlay.debugEnemyCombatant!;

      // La silhouette d'entrée et la lueur doivent masquer le sprite ; une
      // teinte de statut ne doit que le colorer. Le mélange plafonné à 35 %
      // pour tout le monde donnait une « ombre » qui n'était qu'un sprite
      // assombri.
      enemy.holdIntroSlideOffscreen(distancePx: 1080);
      expect(enemy.debugIntroSilhouetteActive, isTrue);
      final silhouetteMix = enemy.debugVisualToneMaxMix;

      enemy.snapToBattlePose();
      await enemy.playTone(
        color: const Color(0xFF7B2FBE),
        durationSeconds: 0.4,
      );
      final statusMix = enemy.debugVisualToneMaxMix;

      expect(silhouetteMix, 1.0);
      expect(statusMix, lessThan(silhouetteMix));
    });
  });

  group('le flash d’ouverture', () {
    test('s’allume puis s’éteint et se retire', () async {
      final flash = BattleBallFlashComponent(
        center: const Offset(100, 100),
        radiusPx: 60,
        durationSeconds: 0.28,
      );

      expect(flash.debugProgress, 0);
      flash.update(0.14);
      expect(flash.debugProgress, closeTo(0.5, 1e-9));
      flash.update(0.2);
      expect(flash.debugProgress, 1.0);
    });

    test('posé sur la scène, il vit sa durée puis disparaît', () async {
      final overlay = await _mount();
      // Le flash est déclenché par le callback d'ouverture de la Ball (une
      // ligne dans `onOpen`, à côté du son que BETA-BAT-022 couvre déjà).
      // Ce test porte sur SA mécanique : posé au bon endroit, il vit puis se
      // retire.
      overlay.debugSpawnBallFlashForTest(BattleSideId.player);

      var sawFlash = false;
      for (var i = 0; i < 40; i++) {
        overlay.updateTree(0.05);
        await Future<void>.delayed(Duration.zero);
        sawFlash = sawFlash ||
            overlay.children.whereType<BattleBallFlashComponent>().isNotEmpty;
      }

      expect(
        sawFlash,
        isTrue,
        reason: 'l’ouverture de la Ball projette son éclat',
      );
      expect(
        overlay.children.whereType<BattleBallFlashComponent>(),
        isEmpty,
        reason: 'un éclat ne traîne pas : il s’éteint et se retire',
      );
    });
  });
}

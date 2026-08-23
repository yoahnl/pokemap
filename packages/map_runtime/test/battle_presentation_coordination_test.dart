import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

// Recette du 2026-08-23 (vidéo 18-58-46) : « soucis de coordination entre les
// attaques, le résultat visuel sur la barre, le moment où l'on est mort et
// les sons ». La sonde a prouvé que le moteur est déjà à l'heure (hit avec le
// clignotement et la barre, down juste avant la chute, chute avant le message
// K.O.). Les menteurs étaient les AFFICHAGES : le badge K.O. du HUD lisait
// l'état FINAL du tour dès son premier instant, et le panneau de commandes
// restait affiché pendant les présentations. Ces tests verrouillent la
// timeline visible du tour fatal.

const _slowStats = BattleStatsSnapshot(
  attack: 40,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _fastStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 90,
);

BattleSession _fatalSession() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 5,
        maxHp: 17,
        currentHp: 1,
        stats: _fastStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'ecras_face', name: 'Écras’Face', power: 20),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'roucool',
        level: 4,
        maxHp: 19,
        currentHp: 12,
        stats: _slowStats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tornade', name: 'Tornade', power: 40),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

Future<BattleOverlayComponent> _mountFatalTurn({
  BattleSfxPlayerLog? seLog,
}) async {
  final session = _fatalSession();
  final overlay = BattleOverlayComponent(
    session: session,
    viewportSize: Vector2(960, 540),
    onPlayerChoice: (_) {},
    playSfx: seLog == null
        ? null
        : (name, {required volume, required pitch}) => seLog.add(name),
  );
  await overlay.onLoad();
  await overlay.waitForPendingVisualSync();
  final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
  expect(afterTurn.state.outcome?.type, BattleOutcomeType.defeat);
  overlay.updateState(afterTurn);
  await overlay.waitForPendingVisualSync();
  return overlay;
}

Future<void> _pump(BattleOverlayComponent overlay, double seconds) async {
  for (var elapsed = 0.0; elapsed < seconds; elapsed += 0.1) {
    overlay.updateTree(0.1);
    await Future<void>.delayed(Duration.zero);
  }
}

typedef BattleSfxPlayerLog = List<String>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le badge K.O. attend que la barre affichée soit à zéro', () async {
    final overlay = await _mountFatalTurn();

    expect(
      overlay.debugPlayerHud!.debugStatusLabel,
      isEmpty,
      reason: 'l’issue est calculée mais pas encore jouée : afficher K.O. '
          'pendant que le Pokémon attaque spoile la mort — le défaut filmé',
    );
    expect(overlay.debugPlayerHud!.currentDisplayedHp, 1.0);

    await _pump(overlay, 2.0);
    expect(
      overlay.debugPlayerHud!.debugStatusLabel,
      isEmpty,
      reason: 'la Tornade fatale n’a pas encore frappé',
    );

    await _pump(overlay, 10.0);
    expect(overlay.debugPlayerHud!.currentDisplayedHp, 0.0);
    expect(
      overlay.debugPlayerHud!.debugStatusLabel,
      'K.O.',
      reason: 'une fois la mort JOUÉE, le badge dit la vérité',
    );
  });

  test('la timeline du tour fatal reste dans l’ordre de la référence',
      () async {
    final seLog = <String>[];
    final overlay = await _mountFatalTurn(seLog: seLog);

    var spriteFellBeforeKoMessage = false;
    var sawKoMessage = false;
    String? currentMessage;
    for (var elapsed = 0.0; elapsed < 12.0; elapsed += 0.1) {
      overlay.updateTree(0.1);
      await Future<void>.delayed(Duration.zero);
      currentMessage = overlay.debugCurrentAnimationMessage;
      final hp = overlay.debugPlayerHud!.currentDisplayedHp;
      final badge = overlay.debugPlayerHud!.debugStatusLabel;
      expect(
        badge == 'K.O.' && hp > 0,
        isFalse,
        reason: 'le badge K.O. ne précède JAMAIS la barre affichée à zéro '
            '(t≈$elapsed, pv=$hp)',
      );
      if (currentMessage == 'grenousse est K.O. !') {
        sawKoMessage = true;
        if (overlay.debugPlayerSpriteOpacity == 0.0) {
          spriteFellBeforeKoMessage = true;
        }
      }
    }

    expect(sawKoMessage, isTrue, reason: 'le message K.O. doit être joué');
    expect(
      spriteFellBeforeKoMessage,
      isTrue,
      reason: 'la chute (0,1 s) précède le message « est K.O. ! » — parité',
    );
    expect(
      seLog,
      containsAllInOrder(<String>['hit', 'hit', 'down']),
      reason: 'les deux impacts puis le son de K.O., dans cet ordre',
    );
  });
}

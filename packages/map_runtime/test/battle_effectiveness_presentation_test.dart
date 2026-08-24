import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

// BETA-BAT-020 — recette du 2026-08-24 : « selon l'efficacité de l'attaque,
// on doit marquer si c'est plus ou moins efficace et avoir un bruit d'impact
// différent ». L'audit a montré que TOUTE la chaîne existe (chart de types,
// messages, sons hit/hitplus/hitlow importés de la référence) et que la
// donnée du Train est complète (721 espèces typées, 954 capacités typées) —
// le combat filmé était simplement un matchup neutre. Ces tests verrouillent
// la présentation des trois cas de bout en bout au niveau de la scène : le
// bon SON et le bon MESSAGE, ou le silence de la neutralité.

const _stats = BattleStatsSnapshot(
  attack: 60,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 90,
);

const _slowStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

BattleSession _session({
  required String moveType,
  required BattleTypingSnapshot enemyTyping,
}) {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: BattleCombatantData(
        speciesId: 'attacker',
        level: 10,
        maxHp: 40,
        currentHp: 40,
        stats: _stats,
        typing: const BattleTypingSnapshot(primaryType: 'normal'),
        moves: <BattleMoveData>[
          BattleMoveData(
            id: 'test_move',
            name: 'Coup Test',
            power: 40,
            type: moveType,
          ),
        ],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'defender',
        level: 8,
        maxHp: 60,
        currentHp: 60,
        stats: _slowStats,
        typing: enemyTyping,
        moves: const <BattleMoveData>[
          BattleMoveData(id: 'tackle', name: 'Charge', power: 20),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

Future<({List<String> seLog, Set<String> messages})> _playFirstTurn(
  BattleSession session,
) async {
  final seLog = <String>[];
  final messages = <String>{};
  final overlay = BattleOverlayComponent(
    session: session,
    viewportSize: Vector2(960, 540),
    onPlayerChoice: (_) {},
    playSfx: (name, {required volume, required pitch}) => seLog.add(name),
  );
  await overlay.onLoad();
  await overlay.waitForPendingVisualSync();

  final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
  overlay.updateState(afterTurn);
  await overlay.waitForPendingVisualSync();
  for (var i = 0; i < 400 && overlay.isTurnPresentationActive; i++) {
    overlay.updateTree(0.05);
    await Future<void>.delayed(Duration.zero);
    final message = overlay.debugCurrentAnimationMessage;
    if (message != null) messages.add(message);
  }
  return (seLog: seLog, messages: messages);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'un coup super efficace joue hitplus et annonce « C’est super '
      'efficace ! »', () async {
    final result = await _playFirstTurn(_session(
      moveType: 'fire',
      enemyTyping: const BattleTypingSnapshot(primaryType: 'grass'),
    ));
    expect(
      result.seLog,
      contains('hitplus'),
      reason: 'la référence choisit le son d’impact selon le multiplicateur',
    );
    expect(result.seLog, isNot(contains('hit')));
    expect(
      result.messages,
      contains('C’est super efficace !'),
      reason: 'le message d’efficacité se lit dans la boîte de dialogue',
    );
  });

  test(
      'un coup résisté joue hitlow et annonce « Ce n’est pas très '
      'efficace… »', () async {
    final result = await _playFirstTurn(_session(
      moveType: 'grass',
      enemyTyping: const BattleTypingSnapshot(primaryType: 'fire'),
    ));
    expect(result.seLog, contains('hitlow'));
    expect(result.messages, contains('Ce n’est pas très efficace…'));
  });

  test(
      'un coup neutre joue hit et reste muet sur l’efficacité — la parité '
      'du silence', () async {
    final result = await _playFirstTurn(_session(
      moveType: 'normal',
      enemyTyping: const BattleTypingSnapshot(primaryType: 'grass'),
    ));
    expect(result.seLog, contains('hit'));
    expect(result.seLog, isNot(contains('hitplus')));
    expect(result.seLog, isNot(contains('hitlow')));
    expect(
      result.messages.where(
        (m) => m.contains('efficace'),
      ),
      isEmpty,
      reason: 'la référence ne dit rien quand le multiplicateur vaut 1',
    );
  });
}

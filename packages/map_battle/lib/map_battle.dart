/// Battle engine for Pokémon-like RPG combat.
///
/// Pure Dart package, independent of Flutter/Flame.
/// Deterministic, testable, and minimal.
///
/// ## Usage
///
/// ```dart
/// // 1. Create setup
/// final setup = BattleSetup(
///   playerPokemon: BattleCombatantData(
///     speciesId: 'pikachu',
///     level: 5,
///     maxHp: 20,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   enemyPokemon: BattleCombatantData(
///     speciesId: 'lapras',
///     level: 5,
///     maxHp: 25,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   isTrainerBattle: true,
///   trainerId: 'gym_leader_1',
/// );
///
/// // 2. Create session
/// final session = createBattleSession(setup);
///
/// // 3. Get available choices
/// final choices = session.getAvailableChoices();
///
/// // 4. Apply choice
/// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
///
/// // 5. Check if finished
/// if (newSession.state.isFinished) {
///   final outcome = newSession.state.outcome!;
///   if (outcome.isVictory) {
///     // Mark trainer as defeated
///   }
/// }
/// ```
library map_battle;

export 'src/battle_setup.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_stats.dart';
export 'src/battle_rng.dart';
export 'src/battle_action.dart';
export 'src/battle_move.dart';
export 'src/battle_resolution.dart';

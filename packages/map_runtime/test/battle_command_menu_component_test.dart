import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  int power = 40,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  bool isTrainerBattle = true,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

BattleCommandPanelComponent _panelFromOverlay(BattleOverlayComponent overlay) {
  return overlay.children.whereType<BattleCommandPanelComponent>().single;
}

void main() {
  group('Battle command panel responsive layout', () {
    test('uses a stacked mobile layout on narrow widths', () async {
      final panel = BattleCommandPanelComponent(
        position: Vector2.zero(),
        size: Vector2(360, 220),
        onChoiceSelected: (_) {},
        onRootActionSelected: (_) {},
      );

      await panel.onLoad();

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.stacked);
      expect(panel.promptPanelSize.x, closeTo(360, 0.01));
      expect(panel.commandsPanelSize.x, closeTo(360, 0.01));
      expect(panel.commandsPanelPosition.y, greaterThan(0));
    });

    test('keeps the split layout on wider battle panels', () async {
      final panel = BattleCommandPanelComponent(
        position: Vector2.zero(),
        size: Vector2(920, 170),
        onChoiceSelected: (_) {},
        onRootActionSelected: (_) {},
      );

      await panel.onLoad();

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.split);
      expect(panel.commandsPanelPosition.x, greaterThan(0));
      expect(panel.promptPanelSize.x, lessThan(panel.size.x));
    });
  });

  group('Battle command menu root', () {
    test('model exposes exactly FIGHT/BAG/POKÉMON/RUN on the root menu', () {
      final session = _session(
        player: _combatant(
          speciesId: 'charmander',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'squirtle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle'),
          ],
        ),
      );

      final model = buildBattleCommandMenuModel(
        session: session,
        mode: BattleCommandMenuMode.root,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(
        model.rootEntries.map((entry) => entry.label).toList(growable: false),
        const <String>['FIGHT', 'BAG', 'POKÉMON', 'RUN'],
      );
    });

    test('trainer root disables BAG and RUN when those choices are absent', () {
      final session = _session(
        player: _combatant(
          speciesId: 'charmander',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'squirtle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle'),
          ],
        ),
      );

      final model = buildBattleCommandMenuModel(
        session: session,
        mode: BattleCommandMenuMode.root,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(model.rootEntries[BattleCommandRootAction.fight.index].enabled,
          isTrue);
      expect(
        model.rootEntries[BattleCommandRootAction.bag.index].enabled,
        isFalse,
      );
      expect(
        model.rootEntries[BattleCommandRootAction.run.index].enabled,
        isFalse,
      );
    });

    test('POKÉMON is disabled without a legal switch and enabled with one', () {
      final noSwitchSession = _session(
        player: _combatant(
          speciesId: 'charmander',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'squirtle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle'),
          ],
        ),
      );
      final switchSession = _session(
        player: _combatant(
          speciesId: 'charmander',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch'),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'ivysaur',
            lineupIndex: 1,
            moves: <BattleMoveData>[
              _move(id: 'vine_whip', name: 'Vine Whip'),
            ],
          ),
        ],
        enemy: _combatant(
          speciesId: 'squirtle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle'),
          ],
        ),
      );

      final noSwitchModel = buildBattleCommandMenuModel(
        session: noSwitchSession,
        mode: BattleCommandMenuMode.root,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );
      final switchModel = buildBattleCommandMenuModel(
        session: switchSession,
        mode: BattleCommandMenuMode.root,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(
        noSwitchModel
            .rootEntries[BattleCommandRootAction.pokemon.index].enabled,
        isFalse,
      );
      expect(
        switchModel.rootEntries[BattleCommandRootAction.pokemon.index].enabled,
        isTrue,
      );
    });
  });

  group('Battle command menu interaction', () {
    test('overlay root navigation moves in a real 2x2 grid', () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'ivysaur',
              lineupIndex: 1,
              moves: <BattleMoveData>[
                _move(id: 'vine_whip', name: 'Vine Whip'),
              ],
            ),
          ],
          enemy: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();
      final panel = _panelFromOverlay(overlay);

      expect(panel.currentSelectedRootIndex, 0);
      overlay.moveSelectionRight();
      expect(panel.currentSelectedRootIndex, 1);
      overlay.moveSelectionDown();
      expect(panel.currentSelectedRootIndex, 3);
      overlay.moveSelectionLeft();
      expect(panel.currentSelectedRootIndex, 2);
      overlay.moveSelectionUp();
      expect(panel.currentSelectedRootIndex, 0);
    });

    test('FIGHT opens legal moves and validates the selected fight choice',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
              _move(id: 'ember', name: 'Ember'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
      expect(overlay.validateSelectedChoice(), isTrue);

      final panel = _panelFromOverlay(overlay);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      expect(panel.currentChoiceLabels, const <String>['Scratch', 'Ember']);

      overlay.moveSelectionRight();
      expect(panel.currentSelectedChoiceIndex, 1);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceFight>());
      expect((pickedChoice as PlayerBattleChoiceFight).moveIndex, 1);
    });

    test(
        'fight submenu supports left and right navigation on a real 2x2 move grid',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
              _move(id: 'ember', name: 'Ember'),
              _move(id: 'smokescreen', name: 'Smokescreen', power: 0),
              _move(id: 'dragon_rage', name: 'Dragon Rage'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();
      expect(overlay.validateSelectedChoice(), isTrue);

      final panel = _panelFromOverlay(overlay);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      expect(panel.currentSelectedChoiceIndex, 0);

      overlay.moveSelectionRight();
      expect(panel.currentSelectedChoiceIndex, 1);

      overlay.moveSelectionDown();
      expect(panel.currentSelectedChoiceIndex, 3);

      overlay.moveSelectionLeft();
      expect(panel.currentSelectedChoiceIndex, 2);
    });

    test('forced continue shows a dedicated CONTINUE action', () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'charizard',
            lineupIndex: 0,
            volatileState: const BattleVolatileState(mustRecharge: true),
            moves: <BattleMoveData>[
              _move(id: 'hyper_beam', name: 'Hyper Beam', power: 150),
            ],
          ),
          enemy: _combatant(
            speciesId: 'dragonair',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'slam', name: 'Slam'),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final panel = _panelFromOverlay(overlay);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.continueOnly);
      expect(panel.currentChoiceLabels, const <String>['CONTINUE']);
    });
  });

  test('pokemon submenu uses two columns when many legal switches exist', () {
    final reserve = List<BattleCombatantData>.generate(
      5,
      (index) => _combatant(
        speciesId: 'reserve_$index',
        lineupIndex: index + 1,
        moves: <BattleMoveData>[
          _move(id: 'tackle_$index', name: 'Tackle $index'),
        ],
      ),
      growable: false,
    );
    final session = _session(
      player: _combatant(
        speciesId: 'lead',
        lineupIndex: 0,
        moves: <BattleMoveData>[
          _move(id: 'scratch', name: 'Scratch'),
        ],
      ),
      playerReserve: reserve,
      enemy: _combatant(
        speciesId: 'enemy',
        lineupIndex: 0,
        moves: <BattleMoveData>[
          _move(id: 'slam', name: 'Slam'),
        ],
      ),
    );

    final model = buildBattleCommandMenuModel(
      session: session,
      mode: BattleCommandMenuMode.pokemon,
      selectedRootIndex: BattleCommandRootAction.pokemon.index,
      selectedChoiceIndex: 0,
    );

    expect(model.choiceEntries, hasLength(5));
    expect(model.choiceColumns, 2);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_item_icon_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';
import 'package:path/path.dart' as p;

const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9tsAAAAASUVORK5CYII=';

final _itemCapabilityResolver = ItemCapabilityResolver(
  ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
);

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
  int catchRate = 45,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    catchRate: catchRate,
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
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

GameState _gameState({
  Bag bag = const Bag(),
}) {
  return GameState(
    saveId: 'battle-bag-ui-shell',
    bag: bag,
  );
}

BagEntry _bagEntry({
  required String itemId,
  required int quantity,
}) {
  return BagEntry(
    itemId: itemId,
    quantity: quantity,
  );
}

Future<void> _writeProjectItemsCatalog(
  Directory root, {
  required List<Map<String, Object?>> entries,
}) async {
  final catalogFile = File(
    p.join(root.path, 'data', 'pokemon', 'catalogs', 'items.json'),
  );
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
    jsonEncode(<String, Object?>{
      'catalog': 'items',
      'entries': entries,
    }),
  );
}

Future<String> _writeTinyItemSprite(
  Directory root,
  String itemId,
) async {
  final file = File(
    p.join(root.path, 'data', 'pokemon', 'assets', 'items', '$itemId.png'),
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(_tinyPngBase64));
  return file.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BattleSdkRmxpAnimationCatalog.ensureLoaded);

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

    test(
        'trainer root keeps BAG enabled for inspection and RUN disabled when those choices are absent',
        () {
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
        isTrue,
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
        itemCapabilityResolver: _itemCapabilityResolver,
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

      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          0);
      overlay.moveSelectionRight();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          1);
      overlay.moveSelectionDown();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          3);
      overlay.moveSelectionLeft();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          2);
      overlay.moveSelectionUp();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          0);
    });

    test('FIGHT opens legal moves and validates the selected fight choice',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.primaryLabel)
              .toList(),
          const <String>['Scratch', 'Ember']);

      overlay.moveSelectionRight();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          1);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceFight>());
      expect((pickedChoice as PlayerBattleChoiceFight).moveIndex, 1);
    });

    test(
        'fight submenu supports left and right navigation on a real 2x2 move grid',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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
      expect(overlay.currentMenuMode, BattleCommandMenuMode.fight);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          0);

      overlay.moveSelectionRight();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          1);

      overlay.moveSelectionDown();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          3);

      overlay.moveSelectionLeft();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          2);
    });

    test(
        'battle party submenu opens from root POKÉMON when switch choices exist',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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

      overlay.moveSelectionDown();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          BattleCommandRootAction.pokemon.index);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.primaryLabel)
              .toList(),
          const <String>['charmander', 'ivysaur']);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.enabled)
              .toList(),
          const <bool>[false, true]);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.statusLabel ?? '')
              .toList(),
          const <String>['Actif', 'OK']);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          1);
    });

    test('battle bag submenu opens from root BAG when bag can be inspected',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
          allowCapture: true,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', quantity: 3),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          BattleCommandRootAction.bag.index);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => '${entry.primaryLabel} ${entry.trailingLabel}')
              .toList(),
          const <String>['Poké Ball x3']);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.enabled)
              .toList(),
          const <bool>[true]);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          0);
    });

    test(
        'battle bag submenu renders supported medicines and disables unknown items',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', quantity: 2),
              _bagEntry(
                itemId: 'antidote',
                quantity: 1,
              ),
              _bagEntry(
                itemId: 'rare-candy',
                quantity: 1,
              ),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => '${entry.primaryLabel} ${entry.trailingLabel}')
            .toList(),
        const <String>['Antidote x1', 'Potion x2', 'rare-candy x1'],
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.enabled)
            .toList(),
        const <bool>[true, true, false],
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.statusLabel ?? '')
            .toList(),
        const <String>['OK', 'OK', 'Invalid definition'],
      );
    });

    test('battle medicine target submenu shows active and reserve pokemon',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            currentHp: 24,
            maxHp: 40,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'bulbasaur',
              lineupIndex: 1,
              currentHp: 30,
              maxHp: 30,
              moves: <BattleMoveData>[
                _move(id: 'vine_whip', name: 'Vine Whip'),
              ],
            ),
            _combatant(
              speciesId: 'squirtle',
              lineupIndex: 2,
              currentHp: 0,
              maxHp: 35,
              moves: <BattleMoveData>[
                _move(id: 'tackle', name: 'Tackle'),
              ],
            ),
          ],
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', quantity: 2),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(
        overlay.currentMenuMode,
        BattleCommandMenuMode.bagMedicineTarget,
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.primaryLabel)
            .toList(),
        const <String>['charmander', 'bulbasaur', 'squirtle'],
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.enabled)
            .toList(),
        const <bool>[true, false, false],
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.statusLabel ?? '')
            .toList(),
        const <String>['OK', 'Full HP', 'K.O.'],
      );
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          equals(0));
    });

    test('battle medicine target submenu does not mask active full hp status',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', quantity: 1),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.statusLabel ?? '')
            .toList(),
        const <String>['Full HP'],
      );
      expect(
        overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => entry.enabled)
            .toList(),
        const <bool>[false],
      );
    });

    test(
        'battle bag submenu keeps poke ball visible but disabled in trainer battle',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: true,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', quantity: 2),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => '${entry.primaryLabel} ${entry.trailingLabel}')
              .toList(),
          const <String>['Poké Ball x2']);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.enabled)
              .toList(),
          const <bool>[false]);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.statusLabel ?? '')
              .toList(),
          const <String>['Trainer only']);
    });

    test('battle bag submenu handles an empty bag', () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'pidgey',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
        ),
        gameState: _gameState(),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => '${entry.primaryLabel} ${entry.trailingLabel}')
              .toList(),
          isEmpty);
      expect(overlay.currentPromptText, 'Sac vide.');
    });

    test('battle party submenu keeps fainted reserves visible but disabled',
        () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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
              speciesId: 'bulbasaur',
              lineupIndex: 1,
              currentHp: 0,
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

      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.enabled)
              .toList()[BattleCommandRootAction.pokemon.index],
          isFalse);
      overlay.moveSelectionDown();
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          BattleCommandRootAction.pokemon.index);
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
    });

    test('party submenu preserves battle reserveIndex instead of visualIndex',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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
              speciesId: 'fainted_one',
              lineupIndex: 1,
              currentHp: 0,
              moves: <BattleMoveData>[
                _move(id: 'growl', name: 'Growl', power: 0),
              ],
            ),
            _combatant(
              speciesId: 'healthy_two',
              lineupIndex: 2,
              moves: <BattleMoveData>[
                _move(id: 'slash', name: 'Slash'),
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
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionDown();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.primaryLabel)
              .toList(),
          const <String>['charmander', 'fainted_one', 'healthy_two']);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .singleWhere((entry) => entry.selected)
              .index,
          2);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceSwitch>());
      expect((pickedChoice as PlayerBattleChoiceSwitch).reserveIndex, 1);
    });

    test('bag submenu prefers project local item sprites when available',
        () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'battle_bag_item_icons_',
      );
      addTearDown(() async {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      });
      final pokeBallPath = await _writeTinyItemSprite(projectRoot, 'poke-ball');
      final hyperPotionPath =
          await _writeTinyItemSprite(projectRoot, 'hyper-potion');
      final potionPath = await _writeTinyItemSprite(projectRoot, 'potion');
      await _writeProjectItemsCatalog(
        projectRoot,
        entries: <Map<String, Object?>>[
          <String, Object?>{
            'id': 'poke-ball',
            'name': 'Poké Ball',
          },
          <String, Object?>{
            'id': 'hyper-potion',
            'name': 'Hyper Potion',
          },
          <String, Object?>{
            'id': 'potion',
            'name': 'Potion',
          },
        ],
      );

      final iconResolver = BattleBagItemIconResolver(
        manifest: const ProjectManifest(
          name: 'Bag Icon Test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        projectRootDirectory: projectRoot.path,
      );
      final visualAssetCache = BattleVisualAssetCache();
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
        session: _session(
          player: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'scratch', name: 'Scratch'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'tackle', name: 'Tackle'),
            ],
          ),
          isTrainerBattle: false,
          allowCapture: true,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', quantity: 2),
              _bagEntry(
                itemId: 'hyper-potion',
                quantity: 1,
              ),
              _bagEntry(itemId: 'potion', quantity: 1),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        bagItemIconResolver: iconResolver,
        visualAssetCache: visualAssetCache,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      for (var attempt = 0; attempt < 100; attempt += 1) {
        if (overlay.currentCommandOverlaySnapshot!.entries.every(
          (entry) => entry.iconAssetPath != null,
        )) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(
        {
          p.normalize(pokeBallPath),
          p.normalize(hyperPotionPath),
          p.normalize(potionPath),
        },
        equals(overlay.currentCommandOverlaySnapshot!.entries
            .map((entry) => p.normalize(entry.iconAssetPath!))
            .toSet()),
      );
    });

    test('forced continue shows a dedicated CONTINUE action', () async {
      final overlay = BattleOverlayComponent(
        itemCapabilityResolver: _itemCapabilityResolver,
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
      expect(overlay.currentMenuMode, BattleCommandMenuMode.continueOnly);
      expect(
          overlay.currentCommandOverlaySnapshot!.entries
              .map((entry) => entry.primaryLabel)
              .toList(),
          const <String>['CONTINUE']);
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

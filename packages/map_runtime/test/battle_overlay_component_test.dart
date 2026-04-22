import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/direction.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_potion_apply.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_combatant_gender_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_debug_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_presentation.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
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
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

PlayerPokemon _partyMember({
  required String speciesId,
  int level = 10,
  int currentHp = 20,
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'pressure',
    level: level,
    knownMoveIds: const <String>['tackle'],
    currentHp: currentHp,
  );
}

GameState _gameState({
  Bag bag = const Bag(),
  List<PlayerPokemon> partyMembers = const <PlayerPokemon>[],
}) {
  return GameState(
    saveId: 'battle-overlay-bag-shell',
    bag: bag,
    party: PlayerParty(members: partyMembers),
  );
}

BagEntry _bagEntry({
  required String itemId,
  required String categoryId,
  required int quantity,
}) {
  return BagEntry(
    itemId: itemId,
    categoryId: categoryId,
    quantity: quantity,
  );
}

RuntimeMapBundle _runtimeBundle({
  MapMetadata mapMetadata = const MapMetadata(),
  MapRole mapRole = MapRole.exterior,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Lot 2 Battle Background Tests',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
          role: mapRole,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
    ),
    map: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: const GridSize(width: 4, height: 3),
      mapMetadata: mapMetadata,
    ),
    projectRootDirectory: '/tmp/lot2_battle_backgrounds',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    zoneId: 'grass_zone',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 6,
    minLevel: 6,
    maxLevel: 6,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    trainerId: 'trainer_rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<String> _writeTinyBattleBackgroundImage() async {
  final directory = await Directory.systemTemp.createTemp(
    'battle_overlay_background_',
  );
  final file = File('${directory.path}/trainer_background.png');
  await file.writeAsBytes(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGOMmnbnPwMDAwMTiABhACpmAs+3EdpKAAAAAElFTkSuQmCC',
    ),
  );
  return file.path;
}

void _expectRectCloseTo(
  ui.Rect actual,
  ui.Rect expected, {
  double tolerance = 0.01,
}) {
  expect(actual.left, closeTo(expected.left, tolerance));
  expect(actual.top, closeTo(expected.top, tolerance));
  expect(actual.right, closeTo(expected.right, tolerance));
  expect(actual.bottom, closeTo(expected.bottom, tolerance));
}

void main() {
  group('BattleBackgroundResolver lot 2 context resolution', () {
    const resolver = BattleBackgroundResolver();

    test('resolves an outdoor wild family from a real wild request', () {
      final spec = resolver.resolve(
        request: _wildRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.wildOutdoor));
    });

    test('resolves an outdoor trainer family from a real trainer request', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.trainerOutdoor));
    });

    test('prioritizes indoor map truth over the battle kind when needed', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(
          mapMetadata: const MapMetadata(
            isIndoor: true,
            mapType: MapType.interior,
          ),
          mapRole: MapRole.interior,
        ),
      );

      expect(spec.key, equals(BattleBackgroundKey.indoor));
    });
  });

  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });

    test('renders Stealth Rock set and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'stealth_rock',
            name: 'Stealth Rock',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsStealthRock: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'stealth_rock',
              name: 'Stealth Rock',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsStealthRock: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        stealthRockEvents: <BattleStealthRockEvent>[
          BattleStealthRockEvent.set(
            side: BattleSideId.enemy,
            sourceMoveId: 'stealth_rock',
          ),
          BattleStealthRockEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 10,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'stealth_rock',
                name: 'Stealth Rock',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsStealthRock: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.set(
              side: BattleSideId.enemy,
              sourceMoveId: 'stealth_rock',
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 10,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Stealth Rock est posé du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 10 dégâts de Stealth Rock à l’entrée'),
      );
    });

    test(
        'renders Spikes layer growth and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'spikes',
            name: 'Spikes',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsSpikes: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'spikes',
              name: 'Spikes',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsSpikes: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        spikesEvents: <BattleSpikesEvent>[
          BattleSpikesEvent.setLayer(
            side: BattleSideId.enemy,
            layers: 2,
          ),
          BattleSpikesEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 13,
            layers: 2,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'spikes',
                name: 'Spikes',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsSpikes: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.setLayer(
              side: BattleSideId.enemy,
              layers: 2,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 13,
              layers: 2,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Spikes monte à 2 couche(s) du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 13 dégâts de Spikes à l’entrée (2 couche(s))'),
      );
    });
  });

  group('BattleOverlayComponent lot 1 scene composition', () {
    test(
        'uses a stable fallback background when no runtime context is injected',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.fallbackField),
      );
    });

    test(
        'mounts a structured battle scene with backdrop, battler zones, huds, command box and narration box by default',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleSceneBackdropComponent>(),
        hasLength(1),
      );
      expect(
        overlay.children.whereType<BattleSceneCombatantComponent>(),
        hasLength(2),
      );
      expect(
        overlay.children.whereType<BattleSceneHudComponent>(),
        hasLength(2),
      );
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
      expect(overlay.children.whereType<BattleDebugPanelComponent>(), isEmpty);
      expect(overlay.debugPanelMounted, isFalse);
    });

    test('consumes the pure scene layout with stable battler relations',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'charmander',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final playerCombatant = overlay.children
          .whereType<BattleSceneCombatantComponent>()
          .firstWhere((component) => component.belongsToPlayerSide);
      final enemyCombatant = overlay.children
          .whereType<BattleSceneCombatantComponent>()
          .firstWhere((component) => !component.belongsToPlayerSide);
      final layout = overlay.currentSceneLayout;

      _expectRectCloseTo(
        playerCombatant.currentSpriteRect,
        layout.playerSpriteRect,
      );
      _expectRectCloseTo(
        enemyCombatant.currentSpriteRect,
        layout.enemySpriteRect,
      );
      _expectRectCloseTo(
        playerCombatant.currentPlatformRect,
        layout.playerPlatformRect,
      );
      _expectRectCloseTo(
        enemyCombatant.currentPlatformRect,
        layout.enemyPlatformRect,
      );
      expect(
        layout.playerSpriteRect.height,
        greaterThan(layout.enemySpriteRect.height),
      );
      expect(
          layout.playerFootAnchor.dy, greaterThan(layout.enemyFootAnchor.dy));
      expect(
          layout.enemyFootAnchor.dx, greaterThan(layout.playerFootAnchor.dx));
      expect(
        layout.playerSpriteRect.bottom,
        lessThanOrEqualTo(layout.commandPanelRect.top),
      );
      expect(layout.enemySpriteRect.overlaps(layout.enemyHudRect), isFalse);
      expect(layout.playerSpriteRect.overlaps(layout.playerHudRect), isFalse);
    });

    test('keeps battler scale stable on wider landscape viewports', () async {
      Future<BattleSceneLayout> loadLayout(Vector2 viewportSize) async {
        final overlay = BattleOverlayComponent(
          session: _session(
            player: _combatant(
              speciesId: 'squirtle',
              lineupIndex: 0,
              moves: <BattleMoveData>[_tackle()],
            ),
            enemy: _combatant(
              speciesId: 'charmander',
              lineupIndex: 0,
              moves: <BattleMoveData>[_tackle()],
            ),
          ),
          viewportSize: viewportSize,
          onPlayerChoice: (_) {},
        );

        await overlay.onLoad();

        return overlay.currentSceneLayout;
      }

      final reference = await loadLayout(Vector2(960, 540));
      final laptop = await loadLayout(Vector2(1280, 720));
      final wide = await loadLayout(Vector2(1600, 900));

      expect(
        laptop.playerSpriteRect.size,
        equals(reference.playerSpriteRect.size),
      );
      expect(
        laptop.enemySpriteRect.size,
        equals(reference.enemySpriteRect.size),
      );
      expect(
        wide.playerSpriteRect.size,
        equals(reference.playerSpriteRect.size),
      );
      expect(
        wide.enemySpriteRect.size,
        equals(reference.enemySpriteRect.size),
      );
    });

    test(
        'switches to a mobile-friendly bottom panel layout on narrow viewports',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'pikachu',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final panel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      await panel.onLoad();

      expect(panel.currentLayoutMode, BattleCommandPanelLayoutMode.stacked);
      expect(
        panel.commandsPanelPosition.y,
        greaterThan(panel.promptPanelPosition.y),
      );
      expect(panel.promptPanelSize.x, closeTo(panel.size.x, 0.01));
      expect(panel.commandsPanelSize.x, closeTo(panel.size.x, 0.01));
      expect(
        overlay.currentSceneLayout.commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.stacked,
      );
    });

    test('keeps portrait HUDs inset and readable on 390x844', () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'squirtle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'caterpie',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final layout = overlay.currentSceneLayout;

      expect(layout.enemyHudRect.left, greaterThanOrEqualTo(14));
      expect(layout.sceneRect.right - layout.playerHudRect.right,
          greaterThanOrEqualTo(14));
      expect(layout.enemyHudRect.overlaps(layout.playerSpriteRect.inflate(4)),
          isFalse);
    });

    test('updateState keeps scene rects stable for a fixed viewport', () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'squirtle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'ivysaur',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'pikachu',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();
      final initialLayout = overlay.currentSceneLayout;

      final nextSession = _session(
        player: _combatant(
          speciesId: 'ivysaur',
          lineupIndex: 1,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'pikachu',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );

      overlay.updateState(nextSession);
      await overlay.waitForPendingVisualSync();

      final updatedLayout = overlay.currentSceneLayout;
      _expectRectCloseTo(
        updatedLayout.playerSpriteRect,
        initialLayout.playerSpriteRect,
      );
      _expectRectCloseTo(
        updatedLayout.enemySpriteRect,
        initialLayout.enemySpriteRect,
      );
      _expectRectCloseTo(
        updatedLayout.commandPanelRect,
        initialLayout.commandPanelRect,
      );
    });

    test('mounts the resolved background family inside the backdrop layer',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        backgroundSpec: const BattleBackgroundSpec(
          key: BattleBackgroundKey.trainerOutdoor,
        ),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final backdrop =
          overlay.children.whereType<BattleSceneBackdropComponent>().single;

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
      expect(
        backdrop.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
    });

    test('loads an authored explicit trainer image when the spec resolves one',
        () async {
      final explicitImagePath = await _writeTinyBattleBackgroundImage();
      final backdrop = BattleSceneBackdropComponent(
        size: Vector2(960, 540),
        backgroundSpec: BattleBackgroundSpec.explicitImage(
          absolutePath: explicitImagePath,
          fallbackKey: BattleBackgroundKey.trainerOutdoor,
        ),
      );

      await backdrop.onLoad();
      expect(backdrop.currentBackgroundKey, BattleBackgroundKey.trainerOutdoor);
      expect(backdrop.hasResolvedExplicitImage, isTrue);
    });

    test('keeps the debug panel opt-in and separate from the normal battle UI',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        showDebugPanel: true,
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleDebugPanelComponent>(),
        hasLength(1),
      );
      expect(overlay.debugPanelMounted, isTrue);
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
    });

    test('updateState refreshes the visible prompt and command menu source',
        () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(overlay.currentPromptText, equals('Que doit faire le joueur ?'));
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
      expect(overlay.getSelectedChoice(), isNull);

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );

      overlay.updateState(forcedReplacementSession);
      await overlay.waitForPendingVisualSync();

      expect(
        overlay.currentPromptText,
        equals('Choisis un remplaçant.'),
      );
      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceSwitch>());
      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(commandPanel.currentSelectedPartyIndex, 1);
      expect(
        commandPanel.currentPartySpeciesLabels,
        const <String>['sproutle', 'benchmate'],
      );
    });

    test(
        'root BAG opens the battle bag submenu without dispatching a battle choice',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          allowCapture: true,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 3),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
          commandPanel.currentBagEntryLabels, const <String>['Poké Ball x3']);
      expect(pickedChoice, isNull);
    });

    test(
        'selecting a capture-capable poke ball dispatches PlayerBattleChoiceCapture',
        () async {
      PlayerBattleChoice? pickedChoice;
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'wild_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        allowCapture: true,
      );
      final overlay = BattleOverlayComponent(
        session: session,
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(
        pickedChoice,
        isA<PlayerBattleChoiceCapture>(),
      );
      expect(session.state.outcome, isNull);
      expect(
        _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            ],
          ),
        ).bag.entries.single.quantity,
        equals(1),
      );
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.getSelectedChoice(), isNull);
    });

    test(
        'selecting disabled poke ball in trainer battle does not dispatch capture',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'trainer_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          isTrainerBattle: true,
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(pickedChoice, isNull);
    });

    test(
        'selecting potion from battle bag opens the medicine target shell without dispatching',
        () async {
      PlayerBattleChoice? pickedChoice;
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(
        overlay.currentMenuMode,
        BattleCommandMenuMode.bagMedicineTarget,
      );
      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(
        commandPanel.currentMedicineTargetSpeciesLabels,
        const <String>['sproutle'],
      );
      expect(pickedChoice, isNull);
    });

    test(
        'selecting a valid medicine target commits a real potion turn without dispatching a PlayerBattleChoice',
        () async {
      PlayerBattleChoice? pickedChoice;
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 12,
          maxHp: 40,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 1,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'wild_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );
      final gameState = _gameState(
        bag: Bag(
          entries: <BagEntry>[
            _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 12),
          _partyMember(speciesId: 'benchmate', currentHp: 40),
        ],
      );
      late BattleOverlayComponent overlay;
      overlay = BattleOverlayComponent(
        session: session,
        gameState: gameState,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
        onBagHpHealItemUseRequested: (action, entry) {
          final result = switch (action.itemId) {
            'potion' => tryApplyRuntimeBattlePotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[0, 1],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[0, 1],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            _ => null,
          };
          if (result == null) {
            return false;
          }
          overlay.updateState(
            result.updatedSession,
            gameState: result.updatedGameState,
          );
          return true;
        },
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);

      expect(overlay.validateSelectedChoice(), isTrue);

      await overlay.waitForPendingVisualSync();

      expect(pickedChoice, isNull);
      expect(overlay.debugSession.state.currentTurn, isNotNull);
      expect(
        overlay.debugSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.potion),
        ),
      );
      expect(overlay.debugSession.state.player.currentHp, equals(32));
      expect(overlay.debugGameState.party.members.first.currentHp, equals(32));
      expect(overlay.debugGameState.bag.entries, isEmpty);
      expect(overlay.isTurnPresentationActive, isTrue);
      expect(
        overlay.currentPromptText,
        equals('Joueur utilise Potion sur sproutle !'),
      );
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isFalse);

      overlay.updateTree(0.50);
      expect(overlay.currentPromptText, equals('sproutle récupère 20 PV.'));
    });

    test(
        'selecting a reserve medicine target commits a real potion turn and updates runtime state',
        () async {
      PlayerBattleChoice? pickedChoice;
      late BattleOverlayComponent overlay;
      overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 1,
            currentHp: 22,
            maxHp: 40,
            moves: <BattleMoveData>[_tackle()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'benchmate',
              lineupIndex: 0,
              currentHp: 35,
              maxHp: 40,
              moves: <BattleMoveData>[_tackle()],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 22),
            _partyMember(speciesId: 'benchmate', currentHp: 35),
          ],
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
        onBagHpHealItemUseRequested: (action, entry) {
          final result = switch (action.itemId) {
            'potion' => tryApplyRuntimeBattlePotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[1, 0],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[1, 0],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            _ => null,
          };
          if (result == null) {
            return false;
          }
          overlay.updateState(
            result.updatedSession,
            gameState: result.updatedGameState,
          );
          return true;
        },
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);
      overlay.moveSelectionDown();

      expect(overlay.validateSelectedChoice(), isTrue);

      await overlay.waitForPendingVisualSync();

      expect(pickedChoice, isNull);
      expect(overlay.debugSession.state.currentTurn, isNotNull);
      expect(
        overlay.debugSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.potion),
        ),
      );
      expect(overlay.debugSession.state.player.currentHp, equals(22));
      expect(
        overlay.debugSession.state.playerReserve.single.currentHp,
        equals(40),
      );
      expect(overlay.debugGameState.party.members[0].currentHp, equals(22));
      expect(overlay.debugGameState.party.members[1].currentHp, equals(40));
      expect(overlay.currentPromptText,
          equals('Joueur utilise Potion sur benchmate !'));
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
    });

    test(
        'selecting a valid super potion target commits a real turn without dispatching a PlayerBattleChoice',
        () async {
      PlayerBattleChoice? pickedChoice;
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 22,
          maxHp: 90,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'wild_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );
      final gameState = _gameState(
        bag: Bag(
          entries: <BagEntry>[
            _bagEntry(
              itemId: 'super-potion',
              categoryId: 'medicine',
              quantity: 1,
            ),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 22),
        ],
      );
      late BattleOverlayComponent overlay;
      overlay = BattleOverlayComponent(
        session: session,
        gameState: gameState,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
        onBagHpHealItemUseRequested: (action, entry) {
          final result = switch (action.itemId) {
            'potion' => tryApplyRuntimeBattlePotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[0],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
                session: overlay.debugSession,
                gameState: overlay.debugGameState,
                context: const RuntimeActiveBattleContext(
                  request: TrainerBattleStartRequest(
                    requestId: 'trainer-request',
                    createdAtEpochMs: 1,
                    returnContext: OverworldReturnContext(
                      mapId: 'field_map',
                      playerPos: GridPos(x: 1, y: 1),
                      playerFacing: Direction.north,
                    ),
                    trainerId: 'trainer',
                    npcEntityId: 'npc_trainer',
                    mapId: 'field_map',
                    playerPos: GridPos(x: 1, y: 1),
                  ),
                  playerPartyIndex: 0,
                  playerPartySlotIndicesByLineupIndex: <int>[0],
                ),
                targetLineupIndex: entry.lineupIndex,
              ),
            _ => null,
          };
          if (result == null) {
            return false;
          }
          overlay.updateState(
            result.updatedSession,
            gameState: result.updatedGameState,
          );
          return true;
        },
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
      expect(overlay.validateSelectedChoice(), isTrue);

      await overlay.waitForPendingVisualSync();

      expect(pickedChoice, isNull);
      expect(overlay.debugSession.state.currentTurn, isNotNull);
      expect(
        overlay.debugSession.state.currentTurn!.playerAction,
        isA<BattleActionBagHpHealItemUse>().having(
          (action) => action.itemKind,
          'itemKind',
          equals(BattleBagHpHealItemKind.superPotion),
        ),
      );
      expect(overlay.debugSession.state.player.currentHp, equals(72));
      expect(overlay.debugGameState.party.members.first.currentHp, equals(72));
      expect(overlay.debugGameState.bag.entries, isEmpty);
      expect(overlay.isTurnPresentationActive, isTrue);
      expect(
        overlay.currentPromptText,
        equals('Joueur utilise Super Potion sur sproutle !'),
      );
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(overlay.validateSelectedChoice(), isFalse);

      overlay.updateTree(0.50);
      expect(overlay.currentPromptText, equals('sproutle récupère 50 PV.'));
    });

    test('full hp medicine targets stay visible but non-selectable', () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_tackle()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'benchmate',
              lineupIndex: 1,
              currentHp: 35,
              maxHp: 35,
              moves: <BattleMoveData>[_tackle()],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
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

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(
        commandPanel.currentMedicineTargetSelectableStates,
        const <bool>[false, false],
      );
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(overlay.debugSession.state.player.currentHp, equals(40));
      expect(overlay.debugGameState.bag.entries.single.quantity, equals(1));
    });

    test('fainted medicine targets stay visible but non-selectable', () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 15,
            maxHp: 40,
            moves: <BattleMoveData>[_tackle()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 1,
              currentHp: 0,
              maxHp: 35,
              moves: <BattleMoveData>[_tackle()],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
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
      overlay.moveSelectionDown();

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(commandPanel.currentSelectedMedicineTargetIndex, equals(1));
      expect(
        commandPanel.currentMedicineTargetStatusLabels,
        const <String>['Actif', 'K.O.'],
      );
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(
          overlay.debugSession.state.playerReserve.single.currentHp, equals(0));
      expect(overlay.debugGameState.bag.entries.single.quantity, equals(1));
    });

    test('escape from medicine target returns to bag and then to root',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 40,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
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
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);

      expect(overlay.handleEscape(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);

      expect(overlay.handleEscape(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
    });

    test('updateState refreshes bag menu source', () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'wild_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
            ],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      overlay.moveSelectionRight();
      expect(overlay.validateSelectedChoice(), isTrue);

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(commandPanel.currentBagEntryLabels, const <String>['Potion x1']);

      overlay.updateState(
        initialSession,
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _bagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 4),
            ],
          ),
        ),
      );
      await overlay.waitForPendingVisualSync();

      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
      expect(
        commandPanel.currentBagEntryLabels,
        const <String>['Poké Ball x2', 'Potion x4'],
      );
    });

    test(
        'voluntary switch selection applies PlayerBattleChoiceSwitch and refreshes battle state',
        () async {
      PlayerBattleChoice? pickedChoice;
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      overlay.moveSelectionDown();
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceSwitch>());

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceSwitch>());
      expect((pickedChoice as PlayerBattleChoiceSwitch).reserveIndex, 0);

      overlay.updateState(initialSession.applyChoice(pickedChoice!));
      await overlay.waitForPendingVisualSync();

      expect(overlay.currentPlayerHudSpeciesText, equals('benchmate'));
      final playerCombatant = overlay.children
          .whereType<BattleSceneCombatantComponent>()
          .singleWhere((component) => component.belongsToPlayerSide);
      expect(playerCombatant.currentSpeciesLabel, equals('benchmate'));
    });

    test(
        'forced replacement opens party menu and does not allow backing out to invalid root actions',
        () async {
      PlayerBattleChoice? pickedChoice;
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'fainted_one',
            lineupIndex: 1,
            currentHp: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 2,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      expect(overlay.handleEscape(), isFalse);
      expect(overlay.moveSelectionRight(), isFalse);
      expect(overlay.currentMenuMode, BattleCommandMenuMode.pokemon);
      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(
        commandPanel.currentPartySpeciesLabels,
        const <String>['sproutle', 'fainted_one', 'benchmate'],
      );
      expect(commandPanel.currentSelectedPartyIndex, 2);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceSwitch>());
      expect((pickedChoice as PlayerBattleChoiceSwitch).reserveIndex, 1);

      overlay.updateState(initialSession.applyChoice(pickedChoice!));
      await overlay.waitForPendingVisualSync();

      expect(overlay.currentPlayerHudSpeciesText, equals('benchmate'));
    });

    test(
        'forced replacement keeps a later valid reserve selectable after moving the cursor',
        () async {
      PlayerBattleChoice? pickedChoice;
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_one',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
          _combatant(
            speciesId: 'bench_two',
            lineupIndex: 2,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (choice) => pickedChoice = choice,
      );

      await overlay.onLoad();

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(commandPanel.currentSelectedPartyIndex, 1);

      overlay.moveSelectionDown();
      expect(commandPanel.currentSelectedPartyIndex, 2);

      expect(overlay.validateSelectedChoice(), isTrue);
      expect(pickedChoice, isA<PlayerBattleChoiceSwitch>());
      expect((pickedChoice as PlayerBattleChoiceSwitch).reserveIndex, 1);
    });

    test('does not repeat the main prompt again in the narration body',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(overlay.currentPromptText, equals('Que doit faire le joueur ?'));
      expect(commandPanel.currentNarrationText,
          isNot('Que doit faire le joueur ?'));
      expect(
        commandPanel.currentNarrationText,
        isNot(
            contains('Que doit faire le joueur ?\nQue doit faire le joueur ?')),
      );
    });

    test('keeps the resolved timeline visible when a real turn exists',
        () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final nextSession =
          initialSession.applyChoice(const PlayerBattleChoiceFight(0));
      overlay.updateState(nextSession);
      await overlay.waitForPendingVisualSync();

      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;
      expect(commandPanel.currentPromptText, isNotEmpty);
      expect(commandPanel.currentNarrationText, isEmpty);
    });

    test('shows resolved gender symbols in both hud labels when known',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          isTrainerBattle: true,
        ),
        viewportSize: Vector2(960, 540),
        genderResolver: const BattleCombatantGenderResolver(
          playerLineupGenderIdsByIndex: <int, String>{0: 'female'},
          enemyLineupGenderIdsByIndex: <int, String>{0: 'male'},
        ),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(overlay.currentPlayerHudSpeciesText, equals('sproutle ♀'));
      expect(overlay.currentEnemyHudSpeciesText, equals('sparkitten ♂'));
    });

    test(
        'updates the player gender label when the active lineup member changes',
        () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'aquafi',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        isTrainerBattle: true,
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        genderResolver: const BattleCombatantGenderResolver(
          playerLineupGenderIdsByIndex: <int, String>{
            0: 'female',
            1: 'male',
          },
        ),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final switchedSession =
          initialSession.applyChoice(const PlayerBattleChoiceSwitch(0));
      overlay.updateState(switchedSession);
      await overlay.waitForPendingVisualSync();

      expect(overlay.currentPlayerHudSpeciesText, equals('aquafi ♂'));
    });

    test('plays a short turn presentation with flash and hp tween on damage',
        () async {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 40,
          stats: _stats(speed: 120, attack: 180),
          moves: <BattleMoveData>[_tackle(power: 180)],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 24,
          currentHp: 24,
          stats: _stats(speed: 40, defense: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: session,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();
      await overlay.waitForPendingVisualSync();

      final initialEnemyHud = overlay.children
          .whereType<BattleSceneHudComponent>()
          .singleWhere((hud) => !hud.belongsToPlayerSide);
      final initialEnemyCombatant = overlay.children
          .whereType<BattleSceneCombatantComponent>()
          .singleWhere((combatant) => !combatant.belongsToPlayerSide);

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final currentTurn = afterTurn.state.currentTurn!;
      final expectedSteps = buildBattleTurnPresentationSteps(
        playerBefore: session.state.player,
        enemyBefore: session.state.enemy,
        turnResult: currentTurn,
      );

      expect(expectedSteps, isNotEmpty);
      expect(expectedSteps.first.animatesDamage, isTrue);

      overlay.updateState(afterTurn);
      await overlay.waitForPendingVisualSync();
      final commandPanel =
          overlay.children.whereType<BattleCommandPanelComponent>().single;

      expect(overlay.isTurnPresentationActive, isTrue);
      expect(overlay.currentPromptText, equals(expectedSteps.first.message));
      expect(commandPanel.currentNarrationText, isEmpty);
      expect(
        initialEnemyHud.currentDisplayedHp.round(),
        equals(session.state.enemy.currentHp),
      );
      expect(initialEnemyCombatant.isHitFlashActive, isFalse);
      expect(overlay.validateSelectedChoice(), isFalse);

      overlay.updateTree(0.20);

      expect(initialEnemyCombatant.isHitFlashActive, isTrue);
      expect(initialEnemyHud.isHpAnimationActive, isTrue);

      overlay.updateTree(0.05);

      expect(
        initialEnemyHud.currentDisplayedHp,
        lessThan(session.state.enemy.currentHp.toDouble()),
      );
      expect(
        initialEnemyHud.currentDisplayedHp,
        greaterThan(afterTurn.state.enemy.currentHp.toDouble()),
      );

      overlay.updateTree(1.5);

      expect(overlay.isTurnPresentationActive, isFalse);
      expect(initialEnemyCombatant.isHitFlashActive, isFalse);
      expect(initialEnemyHud.isHpAnimationActive, isFalse);
      expect(
        initialEnemyHud.currentDisplayedHp.round(),
        equals(afterTurn.state.enemy.currentHp),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_debug_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_component.dart';

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
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
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

    test('updateState refreshes the visible prompt and selected choice source',
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
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceFight>());

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

      expect(
        overlay.currentPromptText,
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceSwitch>());
    });
  });
}

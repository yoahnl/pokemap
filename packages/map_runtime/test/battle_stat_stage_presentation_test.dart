import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_stat_aura_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

// BETA-BAT-021 — recette du 2026-08-24 : « le pokémon du joueur a
// intimidation… il y a une animation pour montrer que son attaque est
// descendu ». Le moteur résolvait déjà les étages ; rien ne les portait
// jusqu'à l'écran.
//
// Oracle : UI::StatAnimation (planche 12×10 parcourue en 1,5 s) +
// change_stat_animation (le SE part avec l'aura) + les textes de
// Data/Text/Dialogs 100019.

BattleSession _session() {
  return createBattleSession(
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
}

BattleAnimationPlan _planFor(List<BattleTurnEvent> timeline) {
  final before = _session();
  return BattleTurnAnimationPlanner(
    speciesDisplayName: (speciesId) =>
        speciesId == 'grenousse' ? 'Grenousse' : 'Machoc',
  ).buildForTurn(
    playerBefore: before.state.player,
    enemyBefore: before.state.enemy,
    turnResult: BattleTurnResult(
      playerAction: const BattleActionNone(),
      enemyAction: const BattleActionNone(),
      executions: const <BattleMoveExecution>[],
      timeline: timeline,
    ),
    moveCatalog: RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
    resolver: BattleMoveVisualResolver(
      RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
    ),
  );
}

List<String> _messagesOf(BattleAnimationPlan plan) => <String>[
      for (final step in plan.flattenedSteps)
        if (step is ShowMessageStep) step.message,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('le plan dit et montre les changements d’étage', () {
    test(
        'recette du 2026-08-25 : une baisse de PRÉCISION se voit et se dit',
        () {
      // « il manque toujours d'animation de perte de précision par exemple
      // avec l'attaque Jet de Sable ». Le moteur PSDK appliquait bien la
      // baisse — il connaît `accuracy` et `evasion` — mais BattleStatId
      // s'arrêtait aux cinq stats de combat : l'adaptateur n'avait rien vers
      // quoi traduire et JETAIT l'événement. Ni aura, ni message.
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.enemy,
          stat: BattleStatId.accuracy,
          amount: -1,
          currentStage: -1,
        ),
      ]);

      final aura = plan.steps.whereType<StatStageAuraStep>().single;
      expect(aura.side, BattleSideId.enemy);
      expect(aura.isRise, isFalse);
      expect(
        _messagesOf(plan),
        contains(contains('La Précision')),
        reason: 'la stat doit être nommée, pas passée sous silence',
      );
    });

    test('recette du 2026-08-25 : une hausse d’ESQUIVE se voit et se dit', () {
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.player,
          stat: BattleStatId.evasion,
          amount: 2,
          currentStage: 2,
        ),
      ]);

      final aura = plan.steps.whereType<StatStageAuraStep>().single;
      expect(aura.isRise, isTrue);
      expect(aura.sheetName, 'stat_up');
      expect(
        _messagesOf(plan),
        contains(contains('L’Esquive')),
      );
    });

    test('une baisse joue l’aura descendante AVANT son message', () {
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.player,
          stat: BattleStatId.attack,
          amount: -1,
          currentStage: -1,
        ),
      ]);

      final aura = plan.steps.whereType<StatStageAuraStep>().single;
      expect(aura.side, BattleSideId.player);
      expect(aura.isRise, isFalse);
      expect(aura.sheetName, 'stat_down');
      expect(aura.seName, 'stat_fall_down');
      expect(aura.durationSeconds, closeTo(1.5, 1e-9),
          reason: 'les 120 cellules de la référence en 1,5 s');
      expect(
        _messagesOf(plan),
        contains('L’Attaque de Grenousse baisse !'),
      );
      expect(
        plan.steps.indexOf(aura),
        lessThan(
          plan.steps.indexWhere((step) => step is ShowMessageStep),
        ),
        reason: 'la référence joue l’aura puis affiche le texte',
      );
    });

    test('une hausse prend la planche montante et son son', () {
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.enemy,
          stat: BattleStatId.defense,
          amount: 1,
          currentStage: 1,
        ),
      ]);

      final aura = plan.steps.whereType<StatStageAuraStep>().single;
      expect(aura.isRise, isTrue);
      expect(aura.sheetName, 'stat_up');
      expect(aura.seName, 'stat_rise_up');
      expect(_messagesOf(plan), contains('La Défense de Machoc augmente !'));
    });

    test('l’ampleur suit le nombre d’étages, comme la référence', () {
      String messageFor(int amount) => _messagesOf(_planFor(<BattleTurnEvent>[
            BattleTurnStatStageEvent(
              side: BattleSideId.player,
              stat: BattleStatId.speed,
              amount: amount,
              currentStage: amount,
            ),
          ])).single;

      expect(messageFor(1), 'La Vitesse de Grenousse augmente !');
      expect(messageFor(2), 'La Vitesse de Grenousse augmente beaucoup !');
      expect(messageFor(3), 'La Vitesse de Grenousse augmente énormément !');
      expect(messageFor(-2), 'La Vitesse de Grenousse baisse beaucoup !');
    });

    test(
        'un changement REFUSÉ se dit mais ne joue aucune aura — la référence '
        'n’anime qu’un changement appliqué', () {
      final atCeiling = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.player,
          stat: BattleStatId.attack,
          amount: 0,
          currentStage: 6,
        ),
      ]);
      final atFloor = _planFor(<BattleTurnEvent>[
        const BattleTurnStatStageEvent(
          side: BattleSideId.player,
          stat: BattleStatId.attack,
          amount: 0,
          currentStage: -6,
        ),
      ]);

      expect(atCeiling.steps.whereType<StatStageAuraStep>(), isEmpty);
      expect(
        _messagesOf(atCeiling),
        contains('L’Attaque de Grenousse ne peut plus augmenter !'),
      );
      expect(
        _messagesOf(atFloor),
        contains('L’Attaque de Grenousse ne peut plus baisser !'),
      );
    });
  });

  group('la traduction PSDK porte les étages jusqu’à la présentation', () {
    test('Rugissement fait baisser l’Attaque et l’événement arrive', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _psdkCombatant(
            id: 'player',
            moves: <PsdkBattleMoveData>[
              _psdkMove(
                id: 'growl',
                category: PsdkBattleMoveCategory.status,
                power: 0,
                stageMods: const <PsdkBattleMoveStageMod>[
                  PsdkBattleMoveStageMod(stat: 'atk', stages: -1),
                ],
              ),
            ],
          ),
          opponent: _psdkCombatant(
            id: 'wild',
            moves: <PsdkBattleMoveData>[_psdkMove(id: 'tackle', power: 40)],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 47,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;

      final statEvents =
          turn.timeline.whereType<BattleTurnStatStageEvent>().toList();
      expect(statEvents, isNotEmpty,
          reason: 'le moteur résolvait déjà l’étage : il arrive enfin');
      expect(statEvents.first.stat, BattleStatId.attack);
      expect(statEvents.first.amount, -1);
      expect(statEvents.first.side, BattleSideId.enemy);
    });

    test(
        'PIÈGE de vocabulaire : `spd` de la référence est la VITESSE, pas la '
        'Défense Spéciale', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
          player: _psdkCombatant(
            id: 'player',
            moves: <PsdkBattleMoveData>[
              _psdkMove(
                id: 'string_shot',
                category: PsdkBattleMoveCategory.status,
                power: 0,
                stageMods: const <PsdkBattleMoveStageMod>[
                  PsdkBattleMoveStageMod(stat: 'spd', stages: -1),
                ],
              ),
            ],
          ),
          opponent: _psdkCombatant(
            id: 'wild',
            moves: <PsdkBattleMoveData>[_psdkMove(id: 'tackle', power: 40)],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 47,
          ),
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;

      expect(
        turn.timeline.whereType<BattleTurnStatStageEvent>().first.stat,
        BattleStatId.speed,
        reason: 'les intervertir échangerait deux auras et deux messages',
      );
    });
  });

  // BETA-BAT-031 — CONSTAT À NE PAS PERDRE, recette du 2026-08-24 (« si on
  // arrive au maximum "la défense de X ne peut pas baisser plus !" ») :
  //
  // Le message ci-dessus (amount == 0) EXISTE côté présentation, mais le
  // moteur ne produit aujourd'hui AUCUN événement quand la borne est
  // atteinte : `BattleStatChangeHandler` retourne `applied: false` sans
  // événement, et les appelants filtrent sur `applied`. La branche de la
  // référence est ailleurs — un move de stat qui ne peut rien appliquer
  // ÉCHOUE (`move_failed`), et la parité PSDK exige alors qu'aucun
  // `stat_stage_change` ne soit émis : `psdk_move_families/` le teste
  // explicitement (s_toxic_thread, s_parting_shot).
  //
  // Faire remonter la borne jusqu'au joueur demande donc une RAISON d'échec
  // dédiée dans le moteur, pas un événement de stat à zéro — j'ai essayé
  // cette voie et elle casse onze tests de parité. À traiter dans son propre
  // ticket, avec l'oracle sous les yeux.

  group('la scène joue l’aura', () {
    test('le son part avec l’aura et le composant se monte puis se retire',
        () async {
      final seLog = <String>[];
      final overlay = BattleOverlayComponent(
        session: _session(),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
        playSfx: (name, {required volume, required pitch}) => seLog.add(name),
      );
      await overlay.onLoad();
      await overlay.waitForPendingVisualSync();

      final afterTurn = _session().withRuntimeDisplayState(
        currentTurn: const BattleTurnResult(
          playerAction: BattleActionNone(),
          enemyAction: BattleActionNone(),
          executions: <BattleMoveExecution>[],
          timeline: <BattleTurnEvent>[
            BattleTurnStatStageEvent(
              side: BattleSideId.player,
              stat: BattleStatId.attack,
              amount: -1,
              currentStage: -1,
            ),
          ],
        ),
      );
      overlay.updateState(afterTurn);
      await overlay.waitForPendingVisualSync();

      // Laisser le décodage des planches finir (préchargé au montage).
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      // Pomper jusqu'à ce que l'aura ait vécu ET disparu : sa durée est
      // 1,5 s, mais le nombre exact de tours ne doit pas être un invariant
      // du test — seul compte qu'elle apparaisse puis se retire.
      var sawAura = false;
      var auraGone = false;
      for (var i = 0; i < 120; i++) {
        overlay.updateTree(0.05);
        await Future<void>.delayed(Duration.zero);
        final mounted =
            overlay.children.whereType<BattleStatAuraComponent>().isNotEmpty;
        if (mounted) {
          sawAura = true;
        } else if (sawAura) {
          auraGone = true;
          break;
        }
      }

      expect(seLog, contains('stat_fall_down'),
          reason: 'parité change_stat_animation : le SE part avec l’aura');
      expect(sawAura, isTrue, reason: 'l’aura se monte au-dessus de la cible');
      expect(
        auraGone,
        isTrue,
        reason: 'elle se retire à sa dernière cellule',
      );
    });
  });
}

PsdkBattleCombatantSetup _psdkCombatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
  int? attackStage,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 120,
    currentHp: 120,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    statStages: attackStage == null
        ? null
        : PsdkBattleStatStages(values: <String, int>{'atk': attackStage}),
    moves: moves,
  );
}

PsdkBattleMoveData _psdkMove({
  required String id,
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 0,
    pp: 15,
    currentPp: 15,
    priority: 0,
    battleEngineMethod:
        category == PsdkBattleMoveCategory.status ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    stageMods: stageMods,
  );
}

# Lot 9-d — Battle BAG potion real apply

## 1. Résumé exécutif

Le lot 9-d est implémenté.

`Potion` n'est plus un simple shell de ciblage UI : dans le BAG battle, sélectionner `Potion` puis une cible valide applique maintenant un vrai soin runtime immédiat de `20 PV` capé à `maxHp`, décrémente réellement `GameState.bag`, met à jour la `BattleSession` visible, et laisse le flow BAG/capture existant intact.

Le lot reste volontairement borné :

- aucun `PlayerBattleChoiceUseItem` n'est créé ;
- aucun moteur générique d'items battle n'est ouvert ;
- aucun registre runtime d'effets d'items n'est introduit ;
- aucune logique `Bubble` / bridge moves / Showdown / BDC-01 n'est touchée ;
- aucun autre objet que `potion` n'est branché ;
- la capture lot 9-b reste inchangée.

## 2. Confirmation de scope

Ce lot continue bien le fil BAG runtime/UI/runtime-writeback :

- `lot-9a` : menu BAG battle UI shell ;
- `lot-9b` : capture wiring ;
- `lot-9c` : shell de ciblage medicine ;
- `lot-9d` : application réelle de `Potion`.

Ce lot **ne continue pas** `BDC-01`.

## 3. Audit critique du prompt avant implémentation

### 3.1 Instruction remise en cause

Le prompt poussait fortement vers une solution “probablement runtime only” et demandait d'éviter `map_battle` sauf nécessité démontrée.

### 3.2 Pourquoi cette instruction posait problème

Une lecture aveugle “runtime only, zéro changement `map_battle`” aurait conduit à une solution bancale pour une raison structurelle : le runtime possède le vrai `GameState`, mais la vérité battle visible reste la `BattleSession` immutable. Sans seam public minimal pour patcher honnêtement un combattant joueur déjà présent, on avait seulement de mauvaises options :

- muter seulement l'overlay : mensonger, car `PlayableMapGame` resterait désynchronisé ;
- reconstruire une session complète depuis `BattleSetup` : lossy et fragile ;
- attendre `runtime_battle_outcome_apply.dart` : trop tard, car ce seam ne sert qu'au write-back post-combat, pas à un effet immédiat pendant le tour de choix ;
- ouvrir un système générique d'items dans `map_battle` : beaucoup trop large pour 9-d.

### 3.3 Preuves trouvées dans le repo

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - l'overlay lot 9-c savait ouvrir le shell medicine, mais ne possédait pas la vérité durable du runtime ;
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - le propriétaire du vrai `_battleSession`, du vrai `_gameState` et du vrai `_activeBattleContext` est `PlayableMapGame` ;
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - ce fichier traite le write-back **après** issue de combat, pas un effet BAG immédiat en plein battle UI ;
- `packages/map_battle/lib/src/battle_session.dart`
  - `BattleSession` est immutable ;
- `packages/map_battle`
  - le moteur expose déjà `BattleCombatant.withHeal(...)`, donc la logique de clamp HP existait déjà ;
- `RuntimeActiveBattleContext`
  - transporte déjà le mapping honnête `lineup -> party slot`, donc le runtime dispose du seam juste pour écrire dans la bonne entrée de party sans heuristique sur l'index visuel.

### 3.4 Alternative retenue

J'ai retenu la plus petite solution honnête :

- l'effet `Potion` reste **runtime-local** ;
- aucun item battle générique n'est ajouté à `map_battle` ;
- j'ai ajouté un **micro-seam** `map_battle` strictement technique :
  - `BattleSession.withUpdatedPlayerCombatant(...)`
- l'application réelle de Potion vit dans un helper runtime dédié ;
- `PlayableMapGame` reste propriétaire de la mutation réelle ;
- `BattleOverlayComponent` reste uniquement l'orchestrateur UX.

### 3.5 Interprétation finale du prompt

Je **n'ai pas suivi aveuglément** la consigne “probablement runtime only” dans son sens strict.

Je l'ai interprétée ainsi :

- pas de système générique d'items dans `map_battle` ;
- pas de `PlayerBattleChoiceUseItem` ;
- pas d'extension du scheduler battle ;
- **mais** un seam immutable minimal dans `map_battle` est acceptable et même nécessaire pour éviter un faux support runtime.

## 4. Audit initial du code existant

### 4.1 Fichiers audit és avant modification

- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### 4.2 Rapports relus

- `reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `reports/lot-9b-battle-bag-capture-wiring-report.md`
- `reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`
- `reports/lot-9c-battle-bag-medicine-target-shell-report.md`
- `reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`

### 4.3 Contrats existants identifiés

- `BattleBagMenuModel` sait déjà classer `captureBall`, `medicine`, `unsupported`.
- `battle_medicine_target_menu_model.dart` cible déjà la **lineup battle courante**, pas la party complète du save.
- `BattleOverlayComponent` sait déjà ouvrir `bagMedicineTarget`, naviguer, et revenir au BAG/root.
- `PlayableMapGame` possède la vérité durable :
  - `_battleSession`
  - `_gameState`
  - `_activeBattleContext`
- `RuntimeActiveBattleContext` fournit déjà le mapping lineup -> slot de party.
- `BattleCombatant.withHeal(...)` existe déjà côté `map_battle`.
- `BattleSession` était immutable sans seam de patch runtime honnête.

### 4.4 Risques principaux identifiés avant code

- mentir visuellement en soignant l'overlay seulement ;
- écrire dans le mauvais Pokémon runtime si on utilise un index visuel au lieu d'un `lineupIndex` ;
- casser la capture 9-b ;
- ouvrir accidentellement un faux système générique d'items ;
- utiliser `runtime_battle_outcome_apply.dart` au mauvais moment ;
- créer un UX post-usage incohérent si `Potion` disparaît après consommation.

### 4.5 Limites de scope à préserver

- pas de generic item battle engine ;
- pas de `PlayerBattleChoiceUseItem` ;
- pas de `BattleItemUseAction` ;
- pas d'éditeur/catalogue ;
- pas d'autres medicines ;
- pas de changement capture ;
- pas de write-back post-combat pour `Potion` ;
- effet immédiat et borné à `Potion`.

## 5. Sub-agents / passes dédiées

### 5.1 Audit / Architecture

- Type : vrai sub-agent
- Verdict : `OK`
- Conclusion :
  - garder l'effet côté runtime ;
  - introduire un micro-seam immutable dans `map_battle` ;
  - éviter `runtime_battle_outcome_apply.dart` comme point principal d'injection ;
  - retour UX au BAG après succès.

### 5.2 Implémentation

- Type : passe locale nommée
- Verdict : `OK`
- Conclusion :
  - helper runtime dédié ;
  - overlay réduit au rôle d'orchestrateur ;
  - propriétaire réel = `PlayableMapGame`.

### 5.3 Tests

- Type : vrai sub-agent + consolidation locale
- Verdict : `OK`
- Conclusion :
  - couverture helper pure ;
  - couverture overlay ;
  - couverture intégration `PlayableMapGame`.

### 5.4 Build / Validation

- Type : vrai sub-agent
- Verdict : `OK`
- Conclusion :
  - `packages/map_runtime` n'est pas un target build Flutter app ;
  - la validation correcte est `flutter analyze` + tests ciblés + `flutter test` complet du package ;
  - `map_battle` a aussi été retesté complètement parce qu'un seam y a été touché.

### 5.5 Critique finale

- Type : passe locale nommée
- Verdict : `OK`
- Conclusion :
  - aucun scope générique d'item n'a été ouvert ;
  - le plus gros risque restant est purement produit/métier : l'usage de Potion ne consomme pas encore un “tour engine” complet comme un vrai système battle item canonique.

## 6. Décision d’architecture retenue

### 6.1 Point d’injection retenu

Le vrai apply de `Potion` vit en deux endroits complémentaires :

- helper runtime pur :
  - `packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
- propriétaire runtime réel :
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Le parent `PlayableMapGame` déclenche l'apply, met à jour ses vraies sources de vérité, puis l'overlay se resynchronise dessus.

### 6.2 Pourquoi c’est le seam le plus petit et le plus honnête

- l'effet est immédiat et local au runtime ;
- aucune action battle générique n'est créée ;
- la session visible reste cohérente ;
- le `GameState` reste cohérent ;
- le mapping de cible passe par `lineupIndex`, pas par index visuel ;
- la consommation BAG réelle est faite là où vit déjà le vrai `GameState`.

### 6.3 Pourquoi `runtime_battle_outcome_apply.dart` n’a pas été choisi

Ce seam est post-combat. Or 9-d exige un effet :

- immédiat ;
- visible dans l'overlay courant ;
- visible dans la session courante ;
- effectif avant la fin de combat.

Le réutiliser comme point principal aurait été structurellement trop tardif.

### 6.4 Pourquoi un micro-touch `map_battle` a été accepté

Sans `BattleSession.withUpdatedPlayerCombatant(...)`, le runtime n'avait pas de moyen honnête de refléter un vrai soin sans :

- mentir à l'overlay ;
- reconstruire une session ;
- ou ouvrir un système beaucoup trop large.

Le seam ajouté reste strictement technique et immutable.

## 7. État git initial exact

### 7.1 `git status --short --untracked-files=all`

```text
 M codex_rule.md
```

### 7.2 `git diff --stat`

```text
 codex_rule.md | 123 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
```

### 7.3 Classification honnête de dirtiness initiale

- `preexisting_out_of_scope`
  - `codex_rule.md`
- `preexisting_in_scope`
  - aucun
- `created_by_this_lot`
  - à ce stade initial : aucun
- `modified_by_this_lot`
  - à ce stade initial : aucun

## 8. Fichiers modifiés

### 8.1 Fichiers créés

- `packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
  - Ajout du helper runtime pur d’application réelle de `Potion`.
  - Impact attendu :
    - vrai heal immédiat ;
    - vraie consommation BAG ;
    - write-through honnête vers `BattleSession` et `GameState`.

- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
  - Ajout de la couverture pure du helper runtime.
  - Impact attendu :
    - preuve du heal ;
    - preuve du cap ;
    - preuve de la consommation ;
    - preuve des garde-fous négatifs.

### 8.2 Fichiers modifiés

- `packages/map_battle/lib/src/battle_session.dart`
  - Zone modifiée :
    - ajout de `withUpdatedPlayerCombatant(...)`
    - ajout de `_replacePlayerCombatantByLineupIndex(...)`
  - Raison :
    - seam immutable minimal pour refléter un effet runtime réel sans moteur générique d’items.
  - Impact attendu :
    - mise à jour honnête du combattant joueur ciblé par `lineupIndex`.

- `packages/map_battle/test/battle_session_test.dart`
  - Zone modifiée :
    - nouveaux tests pour active et reserve.
  - Raison :
    - prouver que le seam battle reste borné et correct.
  - Impact attendu :
    - non-régression de l’immutabilité et de l’identité lineup.

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - Zones modifiées :
    - import du résultat runtime potion ;
    - callback `onPotionUseRequested` ;
    - branche `bagMedicineTarget` ;
    - feedback/narration honnêtes ;
    - debug getters ;
    - retour UX au BAG après succès.
  - Raison :
    - transformer le shell 9-c en usage réel sans émettre de `PlayerBattleChoice`.
  - Impact attendu :
    - feedback réel ;
    - état BAG cohérent ;
    - session affichée cohérente.

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - Zones modifiées :
    - import du helper runtime ;
    - callback `_onBattlePotionUseRequested(...)`
    - branchement du callback dans l’overlay ;
    - getters debug de test.
  - Raison :
    - garder la mutation réelle au bon propriétaire runtime.
  - Impact attendu :
    - vraie source de vérité runtime mise à jour ;
    - tests E2E honnêtes.

- `packages/map_runtime/test/battle_overlay_component_test.dart`
  - Zones modifiées :
    - test shell remplacé par vrai test de mutation ;
    - test réserve ;
    - garde-fous full HP / K.O. renforcés.
  - Raison :
    - prouver que le lot n’est plus seulement UI shell.
  - Impact attendu :
    - non-régression overlay + BAG.

- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
  - Zone modifiée :
    - ajout d’un test intégration `PlayableMapGame`.
  - Raison :
    - prouver que le parent runtime réel change, pas seulement l’overlay.
  - Impact attendu :
    - validation de bout en bout du fil 9-d.

## 9. Contenu complet des fichiers créés

### 9.1 `packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_outcome_apply.dart';

const _runtimeBattlePotionItemId = 'potion';
const _runtimeBattlePotionCategoryId = 'medicine';
const _runtimeBattlePotionHealAmount = 20;

class RuntimeBattlePotionApplyResult {
  const RuntimeBattlePotionApplyResult({
    required this.updatedSession,
    required this.updatedGameState,
    required this.targetSpeciesId,
    required this.targetLineupIndex,
    required this.healedAmount,
  });

  final BattleSession updatedSession;
  final GameState updatedGameState;
  final String targetSpeciesId;
  final int targetLineupIndex;
  final int healedAmount;
}

// Lot 9-d reste volontairement borné :
// - aucun contrat générique d'items battle ;
// - aucune action map_battle nouvelle ;
// - juste l'application runtime immédiate de Potion sur la lineup battle
//   courante et sur le vrai GameState.
RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
  required BattleSession session,
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
}) {
  if (session.decisionRequest is! BattleTurnChoiceRequest) {
    return null;
  }

  final targetCombatant = _findPlayerCombatantByLineupIndex(
    session: session,
    targetLineupIndex: targetLineupIndex,
  );
  if (targetCombatant == null ||
      targetCombatant.isFainted ||
      targetCombatant.currentHp >= targetCombatant.maxHp) {
    return null;
  }

  if (!_hasPotionAvailable(gameState.bag)) {
    return null;
  }

  final healedCombatant = targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
  if (healedAmount <= 0) {
    return null;
  }

  final updatedSession = session.withUpdatedPlayerCombatant(healedCombatant);
  final updatedGameState = _applyPotionToRuntimeState(
    gameState: gameState,
    context: context,
    healedCombatant: healedCombatant,
  );

  return RuntimeBattlePotionApplyResult(
    updatedSession: updatedSession,
    updatedGameState: updatedGameState,
    targetSpeciesId: healedCombatant.speciesId,
    targetLineupIndex: healedCombatant.lineupIndex,
    healedAmount: healedAmount,
  );
}

BattleCombatant? _findPlayerCombatantByLineupIndex({
  required BattleSession session,
  required int targetLineupIndex,
}) {
  final active = session.state.player;
  if (active.lineupIndex == targetLineupIndex) {
    return active;
  }
  for (final combatant in session.state.playerReserve) {
    if (combatant.lineupIndex == targetLineupIndex) {
      return combatant;
    }
  }
  return null;
}

// Le write-back lot 9-d ne touche que :
// - le slot de party runtime exactement aligné sur le lineup battle ciblé ;
// - la consommation d'une seule Potion ;
// - rien d'autre dans le save runtime.
GameState _applyPotionToRuntimeState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleCombatant healedCombatant,
}) {
  final partyIndex = _resolvePlayerPartySlotIndex(
    context: context,
    targetLineupIndex: healedCombatant.lineupIndex,
    partyLength: gameState.party.members.length,
  );
  final members = List<PlayerPokemon>.of(gameState.party.members, growable: false);
  final currentMember = members[partyIndex];
  members[partyIndex] = currentMember.copyWith(currentHp: healedCombatant.currentHp);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: members),
    bag: _consumeOnePotionOrThrow(gameState.bag),
  );
}

int _resolvePlayerPartySlotIndex({
  required RuntimeActiveBattleContext context,
  required int targetLineupIndex,
  required int partyLength,
}) {
  if (context.playerPartySlotIndicesByLineupIndex.isEmpty) {
    if (targetLineupIndex != 0) {
      throw StateError(
        'Lot 9-d ne peut pas cibler honnêtement une réserve sans mapping lineup->party runtime.',
      );
    }
    if (context.playerPartyIndex < 0 || context.playerPartyIndex >= partyLength) {
      throw StateError(
        'Lot 9-d a reçu un playerPartyIndex runtime invalide: '
        'index=${context.playerPartyIndex}, partyLength=$partyLength',
      );
    }
    return context.playerPartyIndex;
  }

  if (targetLineupIndex < 0 ||
      targetLineupIndex >= context.playerPartySlotIndicesByLineupIndex.length) {
    throw StateError(
      'Lot 9-d a reçu un lineupIndex battle invalide pour Potion: '
      'lineupIndex=$targetLineupIndex, '
      'mappingLength=${context.playerPartySlotIndicesByLineupIndex.length}',
    );
  }

  final partyIndex =
      context.playerPartySlotIndicesByLineupIndex[targetLineupIndex];
  if (partyIndex < 0 || partyIndex >= partyLength) {
    throw StateError(
      'Lot 9-d a reçu un mapping lineup->party invalide pour Potion: '
      'lineupIndex=$targetLineupIndex, partyIndex=$partyIndex, '
      'partyLength=$partyLength',
    );
  }
  return partyIndex;
}

bool _hasPotionAvailable(Bag bag) {
  for (final entry in bag.normalized().entries) {
    if (entry.itemId == _runtimeBattlePotionItemId &&
        entry.categoryId == _runtimeBattlePotionCategoryId) {
      return true;
    }
  }
  return false;
}

Bag _consumeOnePotionOrThrow(Bag bag) {
  final nextEntries = <BagEntry>[];
  var consumed = false;

  for (final entry in bag.normalized().entries) {
    final isPotion = entry.itemId == _runtimeBattlePotionItemId &&
        entry.categoryId == _runtimeBattlePotionCategoryId;
    if (!isPotion) {
      nextEntries.add(entry);
      continue;
    }
    if (consumed) {
      nextEntries.add(entry);
      continue;
    }

    consumed = true;
    final nextQuantity = entry.quantity - 1;
    if (nextQuantity > 0) {
      nextEntries.add(entry.copyWith(quantity: nextQuantity));
    }
  }

  if (!consumed) {
    throw StateError('Impossible de consommer Potion : aucune entrée potion disponible.');
  }

  return Bag(entries: nextEntries).normalized();
}
```

### 9.2 `packages/map_runtime/test/battle_potion_apply_runtime_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_potion_apply.dart';

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
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: 40,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int level = 30,
  int maxHp = 40,
  int? currentHp,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: true,
      trainerId: 'trainer',
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
  required Bag bag,
  required List<PlayerPokemon> partyMembers,
}) {
  return GameState(
    saveId: 'battle-potion-runtime',
    bag: bag,
    party: PlayerParty(members: partyMembers),
  );
}

RuntimeActiveBattleContext _context({
  required int playerPartyIndex,
  required List<int> lineupPartyIndices,
}) {
  return RuntimeActiveBattleContext(
    request: const TrainerBattleStartRequest(
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
    playerPartyIndex: playerPartyIndex,
    playerPartySlotIndicesByLineupIndex: lineupPartyIndices,
  );
}

void main() {
  group('tryApplyRuntimeBattlePotionUse', () {
    test('potion heals a damaged active target by 20 and consumes one item', () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 12,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 12),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(20));
      expect(result.updatedSession.state.player.currentHp, equals(32));
      expect(result.updatedGameState.party.members.first.currentHp, equals(32));
      expect(
        result.updatedGameState.bag.entries,
        const <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );
    });

    test('potion heal is capped at max hp', () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 35,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 35),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(5));
      expect(result.updatedSession.state.player.currentHp, equals(40));
      expect(result.updatedGameState.party.members.first.currentHp, equals(40));
    });

    test(
        'potion use removes the bag entry when quantity reaches zero and targets the intended reserve by lineup identity',
        () {
      final result = tryApplyRuntimeBattlePotionUse(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 1,
            currentHp: 22,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'sproutle',
              lineupIndex: 0,
              currentHp: 35,
              maxHp: 40,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        gameState: _gameState(
          bag: const Bag(
            entries: <BagEntry>[
              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 22),
            _partyMember(speciesId: 'sproutle', currentHp: 35),
          ],
        ),
        context: _context(
          playerPartyIndex: 0,
          lineupPartyIndices: const <int>[1, 0],
        ),
        targetLineupIndex: 0,
      );

      expect(result, isNotNull);
      expect(result!.healedAmount, equals(5));
      expect(result.updatedSession.state.player.currentHp, equals(22));
      expect(
        result.updatedSession.state.playerReserve.single.currentHp,
        equals(40),
      );
      expect(result.updatedGameState.party.members[0].currentHp, equals(22));
      expect(result.updatedGameState.party.members[1].currentHp, equals(40));
      expect(result.updatedGameState.bag.entries, isEmpty);
    });

    test('potion use does not affect a full hp or fainted target', () {
      final fullHpState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 40),
        ],
      );
      final fullHpSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 40,
          maxHp: 40,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );

      expect(
        tryApplyRuntimeBattlePotionUse(
          session: fullHpSession,
          gameState: fullHpState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
        ),
        isNull,
      );
      expect(fullHpSession.state.player.currentHp, equals(40));
      expect(fullHpState.party.members.first.currentHp, equals(40));
      expect(fullHpState.bag.entries.single.quantity, equals(1));

      final faintedState = _gameState(
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
          ],
        ),
        partyMembers: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 0),
        ],
      );
      final faintedSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          maxHp: 40,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );

      expect(
        tryApplyRuntimeBattlePotionUse(
          session: faintedSession,
          gameState: faintedState,
          context: _context(
            playerPartyIndex: 0,
            lineupPartyIndices: const <int>[0],
          ),
          targetLineupIndex: 0,
        ),
        isNull,
      );
      expect(faintedSession.state.player.currentHp, equals(0));
      expect(faintedState.party.members.first.currentHp, equals(0));
      expect(faintedState.bag.entries.single.quantity, equals(1));
    });
  });
}
```

## 10. Diffs / zones modifiées des fichiers existants

### 10.1 `packages/map_battle/lib/src/battle_session.dart`

```diff
+  BattleSession withUpdatedPlayerCombatant(BattleCombatant updatedCombatant) {
+    if (state.isFinished) {
+      throw StateError(
+        'Impossible de patcher un combattant joueur sur une BattleSession terminée.',
+      );
+    }
+
+    final updatedPlayerSide = _replacePlayerCombatantByLineupIndex(
+      side: state.playerSide,
+      updatedCombatant: updatedCombatant,
+    );
+
+    return BattleSession._(
+      state: BattleState(
+        phase: state.phase,
+        playerSide: updatedPlayerSide,
+        enemySide: state.enemySide,
+        field: state.field,
+        currentTurn: state.currentTurn,
+        outcome: state.outcome,
+      ),
+      setup: setup,
+      rng: rng,
+      opponentPolicy: opponentPolicy,
+      pendingTurn: pendingTurn,
+    );
+  }
...
+BattleSideState _replacePlayerCombatantByLineupIndex({
+  required BattleSideState side,
+  required BattleCombatant updatedCombatant,
+}) {
+  if (side.active.lineupIndex == updatedCombatant.lineupIndex) {
+    return side.withActive(updatedCombatant);
+  }
+  ...
+}
```

### 10.2 `packages/map_battle/test/battle_session_test.dart`

```diff
+    test(
+        'withUpdatedPlayerCombatant updates the active player combatant without mutating the enemy state',
+        () {
+      final session = createBattleSession(createTestSetup());
+      final updatedSession = session.withUpdatedPlayerCombatant(
+        session.state.player.withDamage(6),
+      );
+      expect(updatedSession.state.player.currentHp, equals(14));
+      expect(updatedSession.state.enemy.currentHp, equals(25));
+    });
+
+    test(
+        'withUpdatedPlayerCombatant updates a reserve combatant by lineup identity',
+        () {
+      ...
+      expect(updatedSession.state.playerReserve.single.currentHp, equals(14));
+    });
```

### 10.3 `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```diff
+import '../../application/runtime_battle_potion_apply.dart';
...
-    return const <String>['Action BAG non branchée dans ce lot.'];
+    return const <String>['Le sac reflète maintenant l’état réel du runtime.'];
...
+  final RuntimeBattlePotionApplyResult? Function(BattleMedicineTargetEntry entry)?
+      onPotionUseRequested;
...
+  BattleSession get debugSession => _session;
+  GameState get debugGameState => _gameState;
...
-      _handleMedicineTargetEntrySelected(selectedEntry);
-      return true;
+      return _handleMedicineTargetEntrySelected(selectedEntry);
...
-  void _handleMedicineTargetEntrySelected(BattleMedicineTargetEntry entry) {
+  bool _handleMedicineTargetEntrySelected(BattleMedicineTargetEntry entry) {
+    ...
+    final applyResult = onPotionUseRequested?.call(entry);
+    if (applyResult == null) {
+      return false;
+    }
+    ...
+    _session = applyResult.updatedSession;
+    _gameState = applyResult.updatedGameState;
+    _bagFeedbackMessage =
+        '${applyResult.targetSpeciesId} récupère ${applyResult.healedAmount} PV.';
+    ...
+    _menuMode = BattleCommandMenuMode.bag;
+    _selectedBagIndex = _firstSelectableBagIndexFor(bagMenuModel);
+    _syncPanelsOnly();
+    _pendingVisualSync = _syncVisualState(previousSession: previousSession);
+    unawaited(_pendingVisualSync);
+    return true;
```

### 10.4 `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```diff
+import '../../application/runtime_battle_potion_apply.dart';
+import 'battle_medicine_target_menu_model.dart';
...
+  BattleOverlayComponent? get debugBattleOverlayComponent => _battleOverlay;
+  BattleSession? get debugBattleSessionSnapshot => _battleSession;
...
+          onPotionUseRequested: _onBattlePotionUseRequested,
...
+  RuntimeBattlePotionApplyResult? _onBattlePotionUseRequested(
+    BattleMedicineTargetEntry entry,
+  ) {
+    final battleSession = _battleSession;
+    final activeBattleContext = _activeBattleContext;
+    if (battleSession == null || activeBattleContext == null) {
+      return null;
+    }
+    final result = tryApplyRuntimeBattlePotionUse(
+      session: battleSession,
+      gameState: _gameState,
+      context: activeBattleContext,
+      targetLineupIndex: entry.lineupIndex,
+    );
+    if (result == null) {
+      return null;
+    }
+    _battleSession = result.updatedSession;
+    _gameState = result.updatedGameState;
+    return result;
+  }
```

### 10.5 `packages/map_runtime/test/battle_overlay_component_test.dart`

```diff
-    test(
-        'selecting a valid medicine target shows shell feedback without dispatching or mutating state',
+    test(
+        'selecting a valid medicine target heals immediately, consumes one potion, and does not dispatch a PlayerBattleChoice',
         () async {
+      ...
+      overlay = BattleOverlayComponent(
+        ...
+        onPotionUseRequested: (entry) => tryApplyRuntimeBattlePotionUse(
+          session: overlay.debugSession,
+          gameState: overlay.debugGameState,
+          context: const RuntimeActiveBattleContext(...),
+          targetLineupIndex: entry.lineupIndex,
+        ),
+      );
+      ...
+      expect(overlay.debugSession.state.player.currentHp, equals(32));
+      expect(overlay.debugGameState.party.members.first.currentHp, equals(32));
+      expect(overlay.debugGameState.bag.entries, isEmpty);
+      expect(overlay.currentPromptText, equals('sproutle récupère 20 PV.'));
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+    });
+
+    test('selecting a reserve medicine target heals it and updates visible hp',
+        () async {
+      ...
+    });
...
+      expect(overlay.debugSession.state.player.currentHp, equals(40));
+      expect(overlay.debugGameState.bag.entries.single.quantity, equals(1));
...
+      expect(overlay.debugSession.state.playerReserve.single.currentHp, equals(0));
+      expect(overlay.debugGameState.bag.entries.single.quantity, equals(1));
```

### 10.6 `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

```diff
+    test('battle BAG potion use persists to PlayableMapGame state', () async {
+      ...
+      const initialState = GameState(
+        saveId: 'wild-flow-potion-save',
+        bag: Bag(
+          entries: <BagEntry>[
+            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+          ],
+        ),
+        party: PlayerParty(
+          members: <PlayerPokemon>[
+            PlayerPokemon(
+              speciesId: 'sproutle',
+              ...
+              currentHp: 12,
+            ),
+          ],
+        ),
+      );
+      ...
+      expect(game.debugBattleSessionSnapshot!.state.player.currentHp, equals(expectedHealedHp));
+      expect(game.gameStateSnapshot.party.members.first.currentHp, equals(expectedHealedHp));
+      expect(game.gameStateSnapshot.bag.entries, isEmpty);
+    });
```

## 11. Tests créés ou modifiés

### 11.1 Créés

- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart`

### 11.2 Modifiés

- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### 11.3 Couverture assurée

- comportement positif :
  - heal actif ;
  - heal réserve ;
  - cap à `maxHp` ;
  - disparition de l’entrée BAG à quantité 1 ;
- cas négatifs :
  - full HP ;
  - K.O. ;
  - pas de `PlayerBattleChoice` item ;
- garde-fous :
  - identité `lineupIndex` ;
  - capture inchangée ;
  - parent `PlayableMapGame` réellement muté ;
- non-régression :
  - `dart test` complet `map_battle` ;
  - `flutter test` complet `map_runtime`.

## 12. Commandes de test lancées et résultats exacts

### 12.1 Tests ciblés runtime demandés

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_bag_menu_model_test.dart
=> PASS ("All tests passed!")

cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_medicine_target_menu_model_test.dart
=> PASS ("All tests passed!")

cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_command_menu_component_test.dart
=> PASS ("All tests passed!")

cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart
=> PASS ("All tests passed!")

cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_potion_apply_runtime_test.dart
=> PASS ("All tests passed!")
```

### 12.2 Validation package complet runtime

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter test
=> PASS ("All tests passed!")
```

Le run complet a fini à `+448` tests.

### 12.3 Validation package complet battle

```text
cd packages/map_battle && /opt/homebrew/bin/dart test
=> PASS ("All tests passed!")
```

Le run complet a fini à `+198` tests.

## 13. Commandes d’analyse lancées et résultats exacts

Commande lancée :

```text
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/presentation/flame/battle_bag_menu_model.dart \
  lib/src/presentation/flame/battle_medicine_target_menu_model.dart \
  lib/src/presentation/flame/battle_command_menu_model.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/application/runtime_battle_potion_apply.dart \
  test/battle_bag_menu_model_test.dart \
  test/battle_medicine_target_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/battle_potion_apply_runtime_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat final exact :

```text
No issues found! (ran in 2.2s)
```

Note honnête :

- une première passe d’analyse avait remonté 3 infos de style dans des tests modifiés ;
- elles ont été corrigées ;
- l’analyse finale ci-dessus est propre.

## 14. Build

### 14.1 Build Flutter app sur `packages/map_runtime`

Non applicable.

Preuve repo :

- `packages/map_runtime` n’a pas de `lib/main.dart`
- la vérification shell `test -f packages/map_runtime/lib/main.dart; echo $?` retourne `1`
- le vrai host applicatif buildable vit dans `examples/playable_runtime_host`

Conclusion :

- aucune commande `flutter build ...` n’a été lancée pour `packages/map_runtime`, car ce package n’est pas une app Flutter autonome ;
- la meilleure validation alternative applicable ici est :
  - `flutter analyze --no-pub`
  - tests ciblés
  - `flutter test` complet du package

### 14.2 Pourquoi je n’ai pas buildé le host ici

Le lot 9-d porte un seam runtime/package et non un chantier host UI/macOS.

Le build host aurait été possible comme validation supplémentaire, mais ce n’était pas la validation la plus pertinente ni la plus petite pour ce lot, alors que :

- le package modifié n’est pas lui-même buildable ;
- les tests runtime complets passent ;
- l’intégration `PlayableMapGame` est couverte explicitement.

## 15. Capture 9-b préservée

Conservé explicitement :

- `BattleBagMenuActionCapture` inchangée ;
- Poké Ball sauvage dispatch toujours `PlayerBattleChoiceCapture` ;
- trainer battle : capture toujours visible mais désactivée ;
- aucune consommation capture déplacée dans 9-d ;
- aucun write-back capture changé.

## 16. Choix UX retenu après usage réussi

J’ai retenu :

- **retour au BAG** après usage réussi.

Pourquoi ce choix est le plus petit et le plus stable :

- le feedback de succès reste visible sur un écran encore pertinent ;
- on évite de laisser le curseur sur une cible devenue full HP ;
- on évite un saut implicite root/non-root différent selon les quantités ;
- le comportement reste simple à tester ;
- on n’a pas besoin d’un deuxième état spécial post-usage.

Je n’ai pas retenu :

- rester dans le shell : trop de logique supplémentaire de renormalisation de cible ;
- retour root : UX un peu plus brusque et moins local au contexte BAG.

## 17. Limites explicitement conservées

- `Potion` seulement ;
- heal flat `20` seulement ;
- pas de revive ;
- pas d’antidote ;
- pas de full restore ;
- pas de X Attack ;
- pas d’item registry ;
- pas de `PlayerBattleChoiceUseItem` ;
- pas de système générique d’items battle ;
- pas de consommation de tour battle canonique via moteur item ;
- pas de changement au move bridge ;
- pas de changement BDC-01 ;
- pas de changement capture.

## 18. Auto-critique finale honnête

### 18.1 Risques restants

- le plus gros risque restant est conceptuel, pas technique :
  - `Potion` ne consomme pas encore un “tour engine item” au sens d’un vrai moteur battle générique ;
  - elle applique un effet runtime local pendant l’état de décision.
- si un futur lot demande des objets qui interagissent avec la résolution de tour adverse, cette architecture bornée ne suffira pas à elle seule.

### 18.2 Tests manquants possibles

- un test supplémentaire “zéro potion en BAG après refresh overlay/updateState” aurait pu être ajouté, même si le package complet couvre déjà la stabilité générale ;
- un test host app explicite aurait pu être ajouté, mais il aurait surtout validé l’intégration hôte plutôt que le seam package lui-même.

### 18.3 Effets de bord possibles

- le feedback BAG post-usage est maintenant plus “runtime-state centric” ;
- si une future UX veut rester dans le shell de cible, il faudra retravailler la narration medicine pour ce nouveau flow.

### 18.4 Choix discutables

- le micro-touch `map_battle` peut surprendre dans un lot “runtime d’abord” ;
- je considère pourtant qu’il est plus honnête qu’une illusion overlay-only ;
- le retour systématique au BAG est un choix de simplicité produit, pas une obligation moteur.

### 18.5 Pourquoi le lot reste malgré tout borné

- aucun contrat générique d’item n’est sorti ;
- un seul item, une seule valeur de heal, une seule famille de cible ;
- mutation par `lineupIndex` uniquement ;
- aucune nouvelle sémantique de combat globale ;
- capture, bridge et editor restent intacts.

## 19. État git final exact

### 19.1 `git status --short --untracked-files=all`

État final attendu pour ce lot après création du report :

```text
 M codex_rule.md
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
?? packages/map_runtime/test/battle_potion_apply_runtime_test.dart
?? reports/lot-9d-battle-bag-potion-real-apply-report.md
```

### 19.2 `git diff --stat`

Dernier `git diff --stat` relevé sur les fichiers trackés :

```text
 codex_rule.md                                      | 123 ++++++++++++++++
 packages/map_battle/lib/src/battle_session.dart    |  63 +++++++++
 packages/map_battle/test/battle_session_test.dart  |  71 ++++++++++
 packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart | 79 ++++++++---
 packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart        | 38 +++++
 packages/map_runtime/test/battle_overlay_component_test.dart                  | 156 +++++++++++++++++++--
 packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart               | 83 +++++++++++
```

Note honnête :

- `git diff --stat` n’inclut pas les fichiers non trackés ;
- les créations `runtime_battle_potion_apply.dart`, `battle_potion_apply_runtime_test.dart` et ce report apparaissent donc dans `git status`, pas dans ce `diff --stat`.

## 20. Prochaines étapes proposées sans implémentation

- lot suivant : décider si l’usage d’item doit commencer à consommer un vrai “tour battle” ou rester un seam runtime borné ;
- ouvrir éventuellement `Super Potion`, mais seulement si le contrat reste encore simple et local ;
- factoriser prudemment un mini-helper runtime local pour plusieurs heals flat **sans** ouvrir un système générique d’items ;
- si le produit le demande plus tard, définir explicitement la sémantique de “turn cost” des items battle, mais dans un lot séparé et assumé.

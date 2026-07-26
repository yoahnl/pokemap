# RM-022 — Unified Battle Decision Contract V0 — Evidence Pack

Date : 2026-07-26
Lot canonique : `RM-022`
Lien mécanique : `FG-052`
Verdict proposé : `RM-022 DONE`, `FG-052 PARTIAL`

## 1. Résultat

Le chemin PSDK du produit utilise désormais une requête canonique unique pour
les moves, switches volontaires, remplacements forcés, captures et fuites.
`BattleSessionFacade` refuse une commande joueur absente de la requête avant
toute mutation.

La fuite n'est plus appliquée à la seule `BattleSession` legacy d'affichage :
elle est soumise au moteur PSDK, produit un outcome `fled`, puis la vue legacy
est reconstruite pour l'overlay existant.

Le remplacement forcé possède un kind dédié et s'exécute entre deux tours,
sans action adverse supplémentaire ni incrément du numéro de tour.
`noLegalChoice` reste terminal et typé jusqu'à l'implémentation de Struggle par
`RM-029`.

## 2. Audit initial

- Deux contrats coexistaient :
  `BattleDecisionRequest`/`PlayerBattleChoice` dans la session legacy et
  `BattleEngineDecisionRequest`/`BattleDecision` dans le moteur PSDK.
- Le runtime construisait une session PSDK mais affichait une session legacy
  reconstruite.
- Moves, captures et switches traversaient l'adapter PSDK.
- Le cas `PlayerBattleChoiceRun` contournait explicitement l'adapter et
  mutait seulement `_battleSession`.
- La requête PSDK ne publiait pas `canFlee`.
- Un actif PSDK K.O. avec une réserve exposait un `turnChoice`, sans distinguer
  le remplacement forcé.
- `BattleEngineDecisionRequest.allows` existait mais la façade ne l'appliquait
  pas.
- Les moves sans PP produisaient déjà le kind typé `noLegalChoice`.

## 3. Décisions d'architecture

1. `BattleEngineDecisionRequest` reste le contrat canonique du moteur PSDK.
2. `BattleSessionFacade` est l'autorité joueur/runtime qui valide les quatre
   familles RM-022 : fight, switch, flee et capture.
3. Le `BattleEngine` brut conserve ses seams spécialisés pour les ports de
   moves PSDK qui testent volontairement des tentatives empêchées.
4. Les items, mega, shift et no-action restent des extensions de confiance;
   `RM-023` doit promouvoir les items dans la requête.
5. La session legacy n'est plus une autorité de mutation sur le chemin PSDK :
   elle reste un modèle de présentation temporaire.
6. Une fuite réussie est prioritaire sur les attaques; une fuite refusée peut
   encore laisser l'adversaire agir sur le seam moteur bas niveau.

## 4. Passes et verdicts

Le mode multi-agent n'était pas autorisé sans demande explicite. Cinq passes
séparées ont été exécutées par le même agent.

### Audit / Architecture

**GO** avec deux contraintes : ne pas implémenter Struggle dans ce lot et ne
pas casser les seams moteur qui vérifient les échecs de moves PSDK.

### Implémentation

**CONFORME** : contrat pur dans `map_battle`, validation à la façade,
orchestration runtime dans `map_runtime`, aucun couplage Flutter dans le moteur.

### Tests

**VERT** : tests du contrat, adapter, smoke Golden et intégration
`PlayableMapGame`.

### Build / Validation

**VERT** : analyses statiques propres et suites complètes des packages touchés.
`map_runtime` est une librairie Flutter sans host autonome; le smoke et
l'intégration `PlayableMapGame` constituent la preuve exécutable du lot.

### Critique finale

**ACCEPTABLE POUR RM-022** : la commande et sa validation sont canoniques,
mais l'overlay consomme encore une projection legacy. La suppression totale de
cette projection serait un chantier de migration UI distinct et n'est pas
nécessaire pour fermer le bug de double autorité.

## 5. TDD et incidents utiles

### RED initial

```text
Error: 'BattleDecisionRejectedError' isn't a type.
Member not found: 'forcedReplacement'.
The getter 'canFlee' isn't defined for BattleEngineDecisionRequest.
+0 -1: Some tests failed.
```

### Ajustement de frontière

Une première validation placée directement dans `BattleEngine` a fait échouer
23 tests spécialisés. Ces tests soumettent volontairement des moves empêchés,
sans PP ou verrouillés afin de vérifier leurs hooks PSDK. La validation produit
a donc été déplacée vers `BattleSessionFacade`, frontière réellement utilisée
par le runtime. La suite moteur est redevenue verte sans affaiblir le chemin
joueur.

### Régression d'intégration détectée

La première soumission canonique de fuite laissait l'attaque adverse être
présentée avant l'outcome :

```text
Expected: 'Tu as pris la fuite !'
Actual: 'sparkitten utilise Scratch !'
```

La cause était le bucket d'ordre `flee` inférieur à `fight`. La fuite est
maintenant résolue dans le bucket prioritaire, et l'intégration Player runtime
prouve de nouveau la narration immédiate.

## 6. Commandes et résultats

### `map_battle` ciblé

```bash
cd packages/map_battle
dart test \
  test/unified_battle_decision_contract_test.dart \
  test/psdk_misc_action_test.dart \
  test/battle_engine_clean_architecture_test.dart \
  test/psdk_switch_action_test.dart \
  test/psdk_pp_history_test.dart \
  -r failures-only
dart analyze
```

```text
+33: All tests passed!
Analyzing map_battle...
No issues found!
```

### `map_runtime` ciblé

```bash
cd packages/map_runtime
flutter test \
  test/runtime_psdk_battle_decision_contract_test.dart \
  test/runtime_psdk_battle_session_adapter_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  -r failures-only
```

```text
+16: All tests passed!
```

### Intégration fuite `PlayableMapGame`

```bash
flutter test test/wild_battle_end_to_end_flow_test.dart \
  --plain-name \
  'lot 11 battle end hands off from final narration to post-battle acknowledgement' \
  -r failures-only
flutter analyze
```

```text
+1: All tests passed!
No issues found! (ran in 7.0s)
```

### Suites complètes

```bash
cd packages/map_battle
dart test -r failures-only
dart analyze
```

```text
+1752: All tests passed!
Analyzing map_battle...
No issues found!
```

Le résultat complet `map_runtime` est consigné après la dernière exécution
fraîche dans la section de clôture ci-dessous.

## 7. Fichiers du lot

| Fichier | Zone modifiée |
|---|---|
| `docs/superpowers/plans/2026-07-26-rm-022-unified-battle-decision-contract.md` | plan |
| `packages/map_battle/lib/map_battle.dart` | export de l'erreur typée |
| `packages/map_battle/lib/src/application/battle_engine.dart` | routage remplacement forcé |
| `packages/map_battle/lib/src/application/battle_session_facade.dart` | validation canonique |
| `packages/map_battle/lib/src/application/battle_turn_runner.dart` | remplacement hors tour |
| `packages/map_battle/lib/src/domain/action/battle_action_ordering.dart` | priorité fuite |
| `packages/map_battle/lib/src/domain/decision/battle_decision.dart` | kinds, fuite, contrat |
| `packages/map_battle/test/unified_battle_decision_contract_test.dart` | tests moteur/façade |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` | mapping public unique |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | suppression du bypass Run |
| `packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart` | tests adapter |
| `reports/gameplay/fg_052_unified_battle_decision_contract_v0.md` | Evidence Pack |

## 8. État Git et isolation

Les sept modifications préexistantes suivantes restent hors commit :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Le plan ignoré par la règle `docs/` est ajouté avec `git add -f` sur son chemin
exact. Aucun stage global n'est utilisé.

## 9. Limites et risques

- `BattleDecisionRequest` legacy subsiste comme projection UI.
- Les items ne sont pas encore énumérés par la requête canonique.
- `noLegalChoice` n'offre volontairement aucune sortie avant `RM-029`.
- Le remplacement forcé applique les hazards; un remplacement K.O. peut donc
  produire une nouvelle requête forcée ou une défaite.
- Les combats restent singles-only.
- La fuite bloquée par trapping n'est pas exposée par le produit lorsque
  `setup.canFlee` est faux; les passthrough `Run Away`/`Smoke Ball` restent des
  seams moteur bas niveau hors contrat produit RM-022.

## 10. Proposition de statut

- `RM-022` : **DONE**.
- `FG-052` : **PARTIAL**, car `RM-029` doit encore remplacer
  `noLegalChoice` par Struggle lorsque les PP sont épuisés.

## 11. Clôture de validation

```bash
cd packages/map_runtime
flutter test -r failures-only
flutter analyze
```

```text
+2187 ~1: 1 skipped test.
+2187 ~1: All other tests passed!
Analyzing map_runtime...
No issues found! (ran in 5.4s)
```

État attendu après le commit isolé : seuls les sept fichiers utilisateur
préexistants listés en section 8 restent modifiés.

## 12. Contenu complet des fichiers créés

Les fichiers créés sont reproduits ci-dessous; le présent rapport n'est pas
reproduit récursivement.

### `docs/superpowers/plans/2026-07-26-rm-022-unified-battle-decision-contract.md`

```markdown
# RM-022 Unified Battle Decision Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Faire de `BattleDecision` et `BattleEngineDecisionRequest` le chemin
canonique unique du runtime PSDK pour les moves, switches volontaires,
remplacements forcés et fuite, avec un état typé `noLegalChoice`.

**Architecture:** `map_battle` produit et valide la requête canonique.
`BattleTurnRunner` traite le remplacement forcé hors tour adverse.
`map_runtime` ne résout plus la fuite dans la session legacy d'affichage :
toute commande PSDK est soumise au même moteur, puis la vue legacy est
reconstruite uniquement pour la présentation existante.

**Non-goal:** Struggle reste explicitement réservé à `RM-029`; les objets
génériques restent réservés à `RM-023`.

---

### Task 1: Enrichir et faire respecter la requête canonique

**Files:**
- Modify: `packages/map_battle/lib/src/domain/decision/battle_decision.dart`
- Modify: `packages/map_battle/lib/src/application/battle_engine.dart`
- Test: `packages/map_battle/test/unified_battle_decision_contract_test.dart`

- [ ] Écrire les tests RED pour `forcedReplacement`, `canFlee`,
  `noLegalChoice` et le rejet atomique d'une décision interdite.
- [ ] Ajouter `forcedReplacement` à `BattleEngineDecisionRequestKind`.
- [ ] Dériver moves/switch/fuite/capture selon le type exact de requête.
- [ ] Valider la décision avant toute mutation du moteur.
- [ ] Préserver provisoirement l'item bridge existant jusqu'à `RM-023`.

### Task 2: Résoudre le remplacement forcé sans tour adverse

**Files:**
- Modify: `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- Test: `packages/map_battle/test/unified_battle_decision_contract_test.dart`

- [ ] Exposer une résolution dédiée au switch imposé.
- [ ] Ne pas incrémenter le numéro de tour.
- [ ] Ne pas créer d'action adverse.
- [ ] Appliquer hooks et hazards de switch.
- [ ] Produire la prochaine requête ou l'outcome après le remplacement.

### Task 3: Soumettre la fuite au moteur PSDK de production

**Files:**
- Modify:
  `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Test:
  `packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart`

- [ ] Prouver en RED qu'une fuite via l'adapter ne termine pas encore PSDK.
- [ ] Exposer le mapping compatibilité `PlayerBattleChoice` →
  `BattleDecision` sans dupliquer la policy.
- [ ] Soumettre `Run` au PSDK comme tous les autres choix.
- [ ] Reconstruire la session legacy uniquement après la décision canonique.
- [ ] Vérifier qu'un trainer rejette la fuite sans mutation.

### Task 4: Vérification

- [ ] Tests ciblés et analyses de `map_battle` et `map_runtime`.
- [ ] Suites complètes des deux packages.
- [ ] Smoke Golden runtime.
- [ ] Evidence Pack `FG-052`.
- [ ] Diff check, commit isolé, état Git final.

```

### `packages/map_battle/test/unified_battle_decision_contract_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('unified battle decision contract', () {
    test('wild turn exposes flee through the canonical request', () {
      final engine = BattleEngine(
        setup: _setup(canFlee: true),
      );

      final request = engine.currentRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.canFlee, isTrue);
      expect(request.allowedDecisions, contains(isA<BattleFleeDecision>()));
      expect(request.allows(const BattleDecision.flee()), isTrue);
    });

    test('trainer turn rejects flee atomically', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(isTrainerBattle: true),
      );
      final before = session.state;

      expect(session.decisionRequest.canFlee, isFalse);
      expect(
        () => session.submit(const BattleDecision.flee()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, before.turnNumber);
      expect(
        session.state.battlerAt(psdkPlayerSlot).currentHp,
        before.battlerAt(psdkPlayerSlot).currentHp,
      );
    });

    test('fainted active produces a forced replacement request', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'player-reserve', hp: 80),
          ],
        ),
      );

      final request = engine.currentRequest;

      expect(
        request.kind,
        BattleEngineDecisionRequestKind.forcedReplacement,
      );
      expect(request.fightChoices, isEmpty);
      expect(request.canFlee, isFalse);
      expect(request.canCapture, isFalse);
      expect(
        request.allowedDecisions.single,
        isA<BattleSwitchDecision>().having(
          (decision) => decision.partyIndex,
          'partyIndex',
          1,
        ),
      );
    });

    test('forced replacement does not grant the opponent another action', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'player-reserve', hp: 80),
          ],
          opponentMoves: <PsdkBattleMoveData>[
            _move(id: 'opponent-hit', power: 200),
          ],
        ),
      );

      final result = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      expect(result.state.turnNumber, 0);
      expect(
        result.state.battlerAt(psdkPlayerSlot).id,
        'player-reserve',
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).currentHp,
        80,
      );
      expect(
        result.nextRequest?.kind,
        BattleEngineDecisionRequestKind.turnChoice,
      );
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
    });

    test('exhausted PP stays an explicit noLegalChoice until RM-029', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.noLegalChoice);
      expect(request.allowedDecisions, isEmpty);
      expect(
        () => session.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, 0);
    });
  });
}

BattleEngineSetup _setup({
  bool canFlee = false,
  bool isTrainerBattle = false,
  int playerHp = 80,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player-active',
      hp: playerHp,
      moves: playerMoves,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(
      id: 'opponent-active',
      hp: 80,
      moves: opponentMoves,
    ),
    canFlee: canFlee,
    isTrainerBattle: isTrainerBattle,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: '$id-move')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int power = 40,
  int pp = 10,
  int? currentPp,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
```

### `packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

void main() {
  group('runtime PSDK canonical battle decision contract', () {
    test('run choice terminates the PSDK engine instead of display-only state',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(canFlee: true),
      );

      expect(
        adapter.allowsPlayerChoice(const PlayerBattleChoiceRun()),
        isTrue,
      );

      final result =
          adapter.submitPlayerChoice(const PlayerBattleChoiceRun());

      expect(result.outcome?.kind, BattleEngineOutcomeKind.fled);
      expect(adapter.state.isFinished, isTrue);
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
      expect(
        adapter
            .createLegacyOutcome(isTrainerBattle: false)
            .isRunaway,
        isTrue,
      );
    });

    test('trainer run is rejected by the canonical request without mutation',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(isTrainerBattle: true),
      );

      expect(
        adapter.allowsPlayerChoice(const PlayerBattleChoiceRun()),
        isFalse,
      );
      expect(
        () => adapter.submitPlayerChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(adapter.state.turnNumber, 0);
      expect(adapter.state.isFinished, isFalse);
    });

    test('forced replacement is exposed and resolved without an enemy turn',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'reserve', hp: 80),
          ],
        ),
      );

      expect(
        adapter.decisionRequest.kind,
        BattleEngineDecisionRequestKind.forcedReplacement,
      );

      final result = adapter.submitPlayerChoice(
        const PlayerBattleChoiceSwitch(0),
      );

      expect(result.state.turnNumber, 0);
      expect(result.state.battlerAt(psdkPlayerSlot).id, 'reserve');
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
    });

    test('typed noLegalChoice reaches the runtime adapter unchanged', () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      expect(
        adapter.decisionRequest.kind,
        BattleEngineDecisionRequestKind.noLegalChoice,
      );
      expect(adapter.decisionRequest.allowedDecisions, isEmpty);
    });
  });
}

PsdkBattleSetup _setup({
  bool canFlee = false,
  bool isTrainerBattle = false,
  int playerHp = 80,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleMoveData>? playerMoves,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      hp: playerHp,
      moves: playerMoves,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(id: 'opponent', hp: 80),
    canFlee: canFlee,
    isTrainerBattle: isTrainerBattle,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: '$id-move')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int currentPp = 10,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 10,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
```

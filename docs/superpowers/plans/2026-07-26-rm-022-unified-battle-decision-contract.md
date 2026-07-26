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

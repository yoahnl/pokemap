# SEL-000 — Selbrume Narrative & Gameplay Readiness Audit

**Date** : 2026-05-23
**Repo** : `/Users/karim/Project/pokemonProject`
**Scope** : Audit sans code — état des lieux complet pour rendre le mini-scénario Selbrume jouable de bout en bout.

---

## Table des matières

1. [Résumé exécutif](#1-résumé-exécutif)
2. [Contexte : le mini-scénario Selbrume](#2-contexte--le-mini-scénario-selbrume)
3. [Audit par sous-système](#3-audit-par-sous-système)
   - 3.1 [Narrative Studio (Editor)](#31-narrative-studio-editor)
   - 3.2 [Modèles narratifs (map_core)](#32-modèles-narratifs-map_core)
   - 3.3 [Runtime narratif (map_runtime)](#33-runtime-narratif-map_runtime)
   - 3.4 [Gameplay pur (map_gameplay)](#34-gameplay-pur-map_gameplay)
   - 3.5 [Système de combat (map_battle)](#35-système-de-combat-map_battle)
   - 3.6 [Intégration map / zones / rencontres](#36-intégration-map--zones--rencontres)
   - 3.7 [Sauvegarde / Chargement](#37-sauvegarde--chargement)
   - 3.8 [Architecture transversale](#38-architecture-transversale)
4. [Matrice Selbrume : besoins vs état réel](#4-matrice-selbrume--besoins-vs-état-réel)
5. [Blocages critiques identifiés](#5-blocages-critiques-identifiés)
6. [Plan de travail proposé](#6-plan-de-travail-proposé)
7. [Recommandation Golden Slice](#7-recommandation-golden-slice)
8. [Annexe : preuves et références](#8-annexe--preuves-et-références)

---

## 1. Résumé exécutif

Le repo PokeMap possède une infrastructure solide pour le rendu, les combats, la sauvegarde, et les bases narratives. Cependant, **le scénario Selbrume ne peut pas fonctionner de bout en bout aujourd'hui** à cause de trois catégories de lacunes :

| Catégorie | Sévérité | Résumé |
|---|---|---|
| **Actions gameplay manquantes dans le runtime narratif** | 🔴 Critique | Aucune commande `GivePokemon`, `StartTrainerBattle`, `HealParty`, `GrantBadge`, `OpenShop` n'existe dans le catalogue de cutscene steps ou de script commands. |
| **Disconnect editor ↔ runtime narratif** | 🟠 Majeur | Le Narrative Studio (Global Story / Step Studio / Cutscene Studio) produit des métadonnées JSON que le runtime ignore largement ; le `ScenarioRuntimeExecutor` implémente son propre interpréteur ad-hoc. |
| **Mécaniques RPG structurelles absentes** | 🟡 Significatif | Pas de PC/Box, pas de shop, pas de heal center, pas de XP/level-up/evolution, `giveItem` utilise `metadata` au lieu du `Bag`, pas de `givePokemon`. |

**Verdict** : ~60% de l'infrastructure technique existe. Il manque ~15 lots de travail ciblés (estimés 3-5 semaines) pour un Selbrume jouable MVP.

---

## 2. Contexte : le mini-scénario Selbrume

Le scénario Selbrume teste le pipeline complet d'un fangame minimal :

```
┌─────────────────────────────────────────────────────────────┐
│  SELBRUME — Mini-scénario de validation                     │
│                                                             │
│  1. New Game → Nom du joueur                                │
│  2. Labo Professeur → Dialogue → Choix starter (3 starters)│
│  3. Route 1 → Herbes hautes → Rencontres sauvages           │
│  4. Route 1 → Rival → Combat dresseur                       │
│  5. Selbrume → Centre Pokémon → Soin                        │
│  6. Selbrume → Boutique → Achat Poké Balls                  │
│  7. Route 2 → Capture sauvage                               │
│  8. Route 2 → Dresseurs                                     │
│  9. Arène → Champion → Combat + Badge                       │
│ 10. Save/Load à tout moment                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Audit par sous-système

### 3.1 Narrative Studio (Editor)

**Fichiers inspectés** :
- [global_story_studio_authoring.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart)
- [step_studio_authoring.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart)
- [cutscene_studio/](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/cutscene_studio/)
- [narrative_workspace_projection.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart)

**État** :

| Composant | Existe | Fonctionnel | Prêt Selbrume |
|---|---|---|---|
| Global Story Studio (chapitres/arcs) | ✅ | ✅ Partial | ❌ |
| Step Studio (étapes de progression) | ✅ | ✅ Partial | ❌ |
| Cutscene Studio (séquences visuelles) | ✅ | ✅ Partial | ❌ |
| Dialogue Studio (Yarn) | ✅ | ✅ | 🟡 |
| Narrative Workspace (vue unifiée) | ✅ | ✅ | 🟡 |

**Problème central — "La façade"** :

Le rapport existant [narrative_studio_readiness_audit.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/narrative_studio_readiness_audit.md) documente déjà ce problème : le Narrative Studio est une **façade visuelle** dont les métadonnées JSON ne sont pas consommées par le runtime. Concrètement :

- **Global Story** crée des chapitres avec des nœuds `ScenarioAsset` (scope `globalStory`) → le runtime a un `GlobalStoryChapterRuntime` ([global_story_chapter_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart)) mais il ne pilote **aucune action gameplay**.
- **Step Studio** crée des steps avec des conditions de complétion → le runtime a un `StepStudioCompletionRuntime` ([step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart)) qui marque des `completedStepIds` dans la progression, mais **ne déclenche pas d'actions monde**.
- **Cutscene Studio** compile vers des `RuntimeCutsceneAsset` → le `CutsceneRuntimeRunner` ([cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart)) exécute des steps (dialogue, move NPC, wait, choice, set/clear flag, goto) mais **aucun step gameplay** (give pokemon, start battle, heal, etc.).

---

### 3.2 Modèles narratifs (map_core)

**Fichiers inspectés** :
- [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) — Graphe nœuds/arêtes, `ScenarioScope` (globalStory / localEventFlow)
- [script_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_asset.dart) — Commandes de script (`ScriptCommandType`)
- [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) — Événements map (actor, object, triggerZone, effect)
- [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) — NPC data, visibility rules, conditional dialogues

**Catalogue de commandes script existant** ([script_asset.dart:84-132](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_asset.dart#L84-L132)) :

| Commande | Existe | Implémentée runtime |
|---|---|---|
| `goto` | ✅ | ✅ |
| `end` | ✅ | ✅ |
| `setFlag` | ✅ | ✅ |
| `clearFlag` | ✅ | ✅ |
| `setVariable` | ✅ | ✅ |
| `incrementVariable` | ✅ | ✅ |
| `openDialogue` | ✅ | ✅ |
| `waitForDialogue` | ✅ | ✅ |
| `warpPlayer` | ✅ | ✅ |
| `giveItem` | ✅ | 🟡 (utilise `metadata` au lieu de `Bag`) |
| `unlockFieldAbility` | ✅ | ✅ |
| `markEventConsumed` | ✅ | ✅ |

**Commandes MANQUANTES pour Selbrume** :

| Commande nécessaire | Statut |
|---|---|
| `givePokemon` | ❌ N'existe pas |
| `startTrainerBattle` | ❌ N'existe pas dans ScriptCommandType |
| `startWildBattle` | ❌ N'existe pas dans ScriptCommandType |
| `healParty` | ❌ N'existe pas |
| `grantBadge` | ❌ N'existe pas |
| `openShop` | ❌ N'existe pas |
| `showChoice` | 🟡 Existe dans Cutscene (`CutsceneChoiceStep`) mais pas dans `ScriptCommandType` |
| `setMoney` / `addMoney` | ❌ N'existe pas |

**Conditions script existantes** (validées dans [validators.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart)) :

| Condition | Existe |
|---|---|
| `flagIsSet` / `flagIsUnset` | ✅ |
| `eventIsConsumed` | ✅ |
| `allOf` / `anyOf` / `not` | ✅ |
| `variableEquals` / `variableGreaterThan` | ✅ |
| `hasPokemonInParty` | ❌ |
| `hasBadge` | ❌ |
| `hasItem` | ❌ |

---

### 3.3 Runtime narratif (map_runtime)

**Fichiers inspectés** :
- [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart)
- [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart)
- [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart)
- [script_command_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/script_command_executor.dart)
- [npc_runtime_presence.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/npc_runtime_presence.dart)
- [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)

**Cutscene Steps existants** ([cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart)) :

| Step | Existe | Selbrume |
|---|---|---|
| `CutsceneDialogueStep` | ✅ | ✅ |
| `CutsceneChoiceStep` | ✅ | ✅ |
| `CutsceneMoveNpcToStep` | ✅ | ✅ |
| `CutsceneWaitStep` | ✅ | ✅ |
| `CutsceneWaitUntilDialogueClosedStep` | ✅ | ✅ |
| `CutsceneWaitUntilNpcMoveCompletedStep` | ✅ | ✅ |
| `CutsceneFaceNpcStep` | ✅ | ✅ |
| `CutsceneSetFlagStep` / `CutsceneClearFlagStep` | ✅ | ✅ |
| `CutsceneEmitOutcomeStep` | ✅ | ✅ |
| `CutsceneGotoStep` / `CutsceneGotoIfChoiceStep` | ✅ | ✅ |
| `CutsceneGotoIfFlagStep` / `CutsceneGotoIfOutcomeStep` | ✅ | ✅ |
| `CutsceneCallStep` | ✅ | ✅ |
| `CutsceneLabelStep` | ✅ | ✅ |
| `CutsceneWaitUntilFlagStep` / `CutsceneWaitUntilOutcomeStep` | ✅ | ✅ |
| **`CutsceneGivePokemonStep`** | ❌ | 🔴 |
| **`CutsceneStartBattleStep`** | ❌ | 🔴 |
| **`CutsceneHealPartyStep`** | ❌ | 🔴 |
| **`CutsceneGrantBadgeStep`** | ❌ | 🔴 |
| **`CutsceneOpenShopStep`** | ❌ | 🔴 |
| **`CutsceneGiveItemStep`** | ❌ | 🔴 (existe dans ScriptCommand mais pas en cutscene) |

**Point positif** : Le `CutsceneRuntimeRunner` a une architecture extensible (classes concrètes typées, pattern matching). Ajouter de nouveaux steps est un travail incrémental.

**NPC Visibility & Conditional Dialogues** :
- `MapEntityNpcVisibilityRule` avec `MapEntityNpcVisibilityMode` → ✅ Fonctionne.
- `MapEntityConditionalDialogue` → ✅ Variantes de dialogue conditionnelles testées.
- `MapEntityRuntimePredicateEvaluator` → ✅ Évalue les prédicats.
- `isNpcRuntimePresentOnMap` → ✅ Filtre spatial NPC.

**Constat** : Le système de visibilité conditionnelle NPC est prêt pour Selbrume (ex: rival qui apparaît/disparaît selon les flags).

---

### 3.4 Gameplay pur (map_gameplay)

**Fichiers inspectés** :
- [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart)
- [script_condition_evaluator.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/script_condition_evaluator.dart)
- [gameplay_encounter.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_encounter.dart)
- [surf_evaluation.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/surf_evaluation.dart)
- [event_page_resolver.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/event_page_resolver.dart)

**Mutations GameState existantes** ([game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart)) :

| Mutation | Existe | Fonctionnelle | Note |
|---|---|---|---|
| `setFlag` / `clearFlag` | ✅ | ✅ | |
| `setVariable` / `incrementVariable` | ✅ | ✅ | |
| `unlockFieldAbility` | ✅ | ✅ | |
| `markEventConsumed` | ✅ | ✅ | |
| `warpPlayer` | ✅ | ✅ | |
| `setPlayerMovementMode` | ✅ | ✅ | |
| `giveItem` | ✅ | 🔴 **Broken** | Utilise `metadata` au lieu de `Bag` (L137-152) |
| `applyAll` | ✅ | ✅ | Batch atomique |
| **`givePokemon`** | ❌ | — | N'existe pas |
| **`healParty`** | ❌ | — | N'existe pas |
| **`grantBadge`** | ❌ | — | N'existe pas |
| **`addMoney`** | ❌ | — | N'existe pas |
| **`removeMoney`** | ❌ | — | N'existe pas |

> [!WARNING]
> `giveItem` (L137-152) stocke les items dans `GameState.metadata` via une clé `"item_$itemId"` au lieu d'utiliser le modèle `Bag` / `BagEntry` qui existe déjà dans [save_data.dart:272-338](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L272-L338). Le runtime de capture ([runtime_battle_outcome_apply.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart)) utilise correctement `Bag`, créant un **split de données** entre le script system et le battle system.

**Tests** : 127 tests passent (`dart test` vert).

---

### 3.5 Système de combat (map_battle)

**Fichiers inspectés** :
- [battle_setup.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart)
- [battle_session.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart)
- [battle_resolution.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart)
- [map_battle.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart)

**État** : ✅ **Le plus mature du repo.**

| Feature | État | Preuve |
|---|---|---|
| `BattleSetup` (isTrainerBattle, allowCapture, trainerId) | ✅ | [battle_setup.dart:15-73](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart#L15-L73) |
| `BattleSession` (tour par tour, switch, capture, fuite) | ✅ | [battle_session.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart) |
| `BattleOutcome` (victory, defeat, runaway, captured) | ✅ | [battle_resolution.dart:409-457](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart#L409-L457) |
| AI dresseur | ✅ | [psdk_battle_ai.dart](file:///Users/karim/Project/pokemonProject/packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart) |
| Capture (probabiliste stub) | ✅ | Lot 13 — capture immédiate quand proposée |
| 1162 tests | ✅ | `dart test` vert |

**Verdict combat** : Le moteur de combat est prêt pour Selbrume. Le problème est **comment y arriver** depuis une cutscene/script narratif.

---

### 3.6 Intégration map / zones / rencontres

**Fichiers inspectés** :
- [encounter_to_battle_request.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/encounter_to_battle_request.dart)
- [battle_start_request.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart)
- [trainer_battle_request.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart)
- [runtime_battle_outcome_apply.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart)
- [map_gameplay_zone_payloads](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart)

| Feature | État | Note |
|---|---|---|
| `GameplayZone` (encounter, movement, hazard) | ✅ | Modèle complet |
| `EncounterZonePayload` → `WildBattleStartRequest` | ✅ | Pipeline encounter → battle request |
| `WildBattleStartRequest` / `TrainerBattleStartRequest` | ✅ | [battle_start_request.dart:35-140](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart#L35-L140) |
| `buildTrainerBattleRequestFromNpc` | ✅ | [trainer_battle_request.dart:17-41](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart#L17-L41) |
| Battle outcome write-back (HP, capture, trainer defeated) | ✅ | [runtime_battle_outcome_apply.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart) |
| Whiteout-lite (relève 1 HP si party full KO) | ✅ | L79-119 |
| `_startBattleHandoff` dans `PlayableMapGame` | ✅ | L4033 |
| Encounter zone dans l'éditeur | ✅ | [encounter_tables_panel](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/encounter_tables_panel_table_widgets.dart), [gameplay_zone_properties_panel](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/gameplay_zone_properties_panel.dart) |

**Verdict rencontres** : Le pipeline zone → encounter → battle → outcome → write-back **fonctionne**. C'est un point fort.

**Manque** : Le déclenchement de combat **depuis une cutscene** (ex: rival, champion d'arène) n'est pas câblé. Le combat NPC dresseur passe par `buildTrainerBattleRequestFromNpc` déclenché par line-of-sight dans le `PlayableMapGame`, pas depuis une commande narrative.

---

### 3.7 Sauvegarde / Chargement

**Fichiers inspectés** :
- [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart)
- [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart)
- [game_state_persistence.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/game_state_persistence.dart)
- [save_game_use_case.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/save_game_use_case.dart)
- [load_game_use_case.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_game_use_case.dart)

| Feature | État | Note |
|---|---|---|
| `SaveData` ↔ `GameState` bidirectionnel | ✅ | `gameStateFromSaveData` / `saveDataFromGameState` |
| `PlayerParty` (members: `List<PlayerPokemon>`) | ✅ | Max 6 par le battle engine |
| `PlayerPokemon` (species, level, nature, ability, moves, HP, IVs/EVs) | ✅ | Modèle complet |
| `Bag` / `BagEntry` (itemId, categoryId, quantity) | ✅ | Modèle complet |
| `TrainerProfile` (name, badges, money, playtime) | ✅ | |
| `PlayerProgression` (storyFlags, completedStepIds, completedCutsceneIds, seen/caught species) | ✅ | |
| `StoryFlags` / `ScriptVariables` runtime | ✅ | |
| `consumedEventIds` | ✅ | |
| Flag migration (progression ↔ storyFlags) | ✅ | `normalizeLoadedGameState` |
| **PC/Box storage** | ❌ | N'existe pas. Capture limitée à party < 6. |
| **XP / level-up** | ❌ | Aucune structure dans `GameState` ou `PlayerPokemon` |
| **Evolution** | ❌ | |

**Verdict save/load** : Le pipeline save/load est fonctionnel et couvre tous les champs `GameState`. Les données manquantes (XP, PC) sont des lacunes de modèle, pas de pipeline.

---

### 3.8 Architecture transversale

| Aspect | État | Détail |
|---|---|---|
| Package boundaries (core/gameplay/battle/runtime/editor) | ✅ | Respectées |
| Public barrels | ✅ | `map_core.dart`, `map_gameplay.dart`, `map_battle.dart`, `map_runtime.dart` |
| Tests map_core | ✅ 1905 pass | `dart test` vert |
| Tests map_gameplay | ✅ 127 pass | `dart test` vert |
| Tests map_battle | ✅ 1162 pass | `dart test` vert |
| Validation project | ✅ | [validators.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart) — 2000+ lignes |
| No-code-first (editor UX) | 🟡 | Narrative Studio a l'UI mais manque d'actions gameplay |

---

## 4. Matrice Selbrume : besoins vs état réel

| # | Besoin Selbrume | Infrastructure | Authoring (Editor) | Runtime | Verdict |
|---|---|---|---|---|---|
| 1 | **New Game** (nom joueur) | `TrainerProfile.name` ✅ | ❌ Pas d'écran New Game | ❌ Pas de flow New Game | 🔴 ABSENT |
| 2 | **Dialogue NPC** (Yarn) | `YarnDialogueRef` ✅ | ✅ Dialogue Studio | ✅ `parseYarnFile` + `DialogueSession` | ✅ PRÊT |
| 3 | **Choix joueur** (ex: starter) | `CutsceneChoiceStep` ✅ | ✅ Cutscene Studio | ✅ `CutsceneRuntimeRunner` | ✅ PRÊT |
| 4 | **Give Pokémon** (starter) | `PlayerParty` ✅ | ❌ Pas de step/commande | ❌ Pas de mutation ni cutscene step | 🔴 ABSENT |
| 5 | **Rencontres sauvages** (herbes) | `GameplayZone` + `EncounterZonePayload` ✅ | ✅ Encounter Table Panel | ✅ Pipeline complet | ✅ PRÊT |
| 6 | **Combat dresseur** (rival/arène) | `BattleSetup` + `TrainerBattleStartRequest` ✅ | ✅ NPC trainerId | 🟡 LOS only, pas depuis cutscene | 🟠 PARTIEL |
| 7 | **Capture sauvage** | Lot 13/14 ✅ | N/A | ✅ `_consumeOnePokeBallOrThrow` | ✅ PRÊT |
| 8 | **Write-back combat** (HP, trainer defeated) | `applyRuntimeBattleOutcomeToGameState` ✅ | N/A | ✅ | ✅ PRÊT |
| 9 | **Heal party** (centre pokémon) | `PlayerPokemon.currentHp` ✅ | ❌ Pas de step/commande | ❌ Pas de mutation | 🔴 ABSENT |
| 10 | **Shop** (achat Poké Balls) | `Bag` / `BagEntry` ✅ | ❌ Pas d'UI shop | ❌ Pas de runtime shop | 🔴 ABSENT |
| 11 | **Give Item** (via script) | `BagEntry` ✅ | 🟡 `ScriptCommandType.giveItem` | 🔴 `metadata` au lieu de `Bag` | 🟠 BROKEN |
| 12 | **Badge** (arène) | `TrainerProfile.badgeIds` ✅ | ❌ Pas de commande | ❌ Pas de mutation | 🔴 ABSENT |
| 13 | **Save / Load** | `SaveData` ↔ `GameState` ✅ | N/A | ✅ use cases | ✅ PRÊT |
| 14 | **Warp** (changement de map) | `warpPlayer` ✅ | ✅ Warp panel | ✅ | ✅ PRÊT |
| 15 | **NPC visibilité conditionnelle** | `MapEntityNpcVisibilityRule` ✅ | ✅ Entity properties | ✅ `isNpcRuntimePresentOnMap` | ✅ PRÊT |
| 16 | **Dialogue conditionnel NPC** | `MapEntityConditionalDialogue` ✅ | ✅ | ✅ | ✅ PRÊT |
| 17 | **Flags / Variables** | `StoryFlags` + `ScriptVariables` ✅ | ✅ | ✅ | ✅ PRÊT |
| 18 | **Cutscene** (scénarisée) | `RuntimeCutsceneAsset` ✅ | ✅ Cutscene Studio | ✅ `CutsceneRuntimeRunner` | ✅ PRÊT |
| 19 | **PC/Box** (overflow party) | ❌ Aucun modèle | ❌ | ❌ | 🔴 ABSENT |
| 20 | **XP / Level-up** | ❌ Aucun modèle | ❌ | ❌ | 🟡 NON-MVP |
| 21 | **Argent** | `TrainerProfile.money` ✅ | ❌ Pas de mutation | ❌ | 🟠 PARTIEL |

**Synthèse** :
- ✅ PRÊT : 10/21 (48%)
- 🟠 PARTIEL : 3/21 (14%)
- 🔴 ABSENT : 7/21 (33%)
- 🟡 NON-MVP : 1/21 (5%)

---

## 5. Blocages critiques identifiés

### 🔴 BLK-1 : Aucune commande `givePokemon`

**Impact** : Impossible de donner un starter au joueur.
**Localisation du gap** :
- `ScriptCommandType` ([script_asset.dart:84-132](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_asset.dart#L84-L132)) — pas de `givePokemon`
- `GameStateMutations` ([game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart)) — pas de `givePokemon`
- `RuntimeCutsceneStep` ([cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart)) — pas de `CutsceneGivePokemonStep`

**Solution estimée** : 3 fichiers à modifier, ~50-80 lignes. Mutation pure + script command + cutscene step.

---

### 🔴 BLK-2 : Pas de déclenchement de combat depuis cutscene/script

**Impact** : Le rival et le champion d'arène ne peuvent pas initier un combat depuis une séquence narrative.
**Localisation du gap** :
- `_startBattleHandoff` dans `PlayableMapGame` ([playable_map_game.dart:4033](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4033)) existe mais n'est appelé que depuis le pipeline encounter ou LOS.
- Il n'y a pas de `CutsceneStartBattleStep` ni de `ScriptCommandType.startBattle`.

**Solution estimée** : Créer un `CutsceneStartTrainerBattleStep` qui suspend la cutscene, délègue au `_startBattleHandoff`, et reprend après l'outcome. Complexité moyenne (async handoff).

---

### 🔴 BLK-3 : `giveItem` cassé (metadata vs Bag)

**Impact** : Les Poké Balls données par script ne sont pas dans le `Bag`, donc le combat les ignore.
**Localisation du gap** : [game_state_mutations.dart:137-152](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart#L137-L152) — stocke dans `metadata` au lieu de `Bag`.
**Solution estimée** : Réécrire `giveItem` pour utiliser `Bag.entries`, ~20 lignes. Le modèle `BagEntry` existe déjà.

---

### 🔴 BLK-4 : Pas de `healParty`

**Impact** : Le centre Pokémon ne peut pas soigner.
**Solution estimée** : Mutation triviale — `copyWith(currentHp: maxHp)` sur chaque membre. ~15 lignes. Le maxHp n'est pas calculé (pas de stats engine), donc probablement un heal to a configurable value ou un "full heal" nominal.

---

### 🔴 BLK-5 : Pas de `grantBadge`

**Impact** : Le champion d'arène ne peut pas donner un badge.
**Localisation** : `TrainerProfile.badgeIds` existe ([save_data.dart:239](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L239)) mais aucune mutation ne l'utilise.
**Solution estimée** : Mutation triviale — ~10 lignes.

---

### 🔴 BLK-6 : Pas d'écran New Game

**Impact** : Le joueur ne peut pas nommer son personnage ni démarrer une partie.
**Solution estimée** : Flow runtime minimal — overlay Flutter + création `GameState` initiale. Complexité moyenne.

---

### 🟠 BLK-7 : Pas de shop runtime

**Impact** : Achat Poké Balls impossible.
**Solution estimée** : Overlay Flutter + mutations `addMoney`/`removeMoney`/`addBagEntry`. Complexité significative (UI + data).

---

## 6. Plan de travail proposé

### Phase 1 — Mutations gameplay fondamentales (Priorité 🔴 critique)

| Lot | Titre | Package | Effort | Dépendances |
|---|---|---|---|---|
| SEL-01 | `giveItem` → utiliser `Bag` au lieu de `metadata` | `map_gameplay` | S | Aucune |
| SEL-02 | Mutation `givePokemon` (ajouter à party) | `map_gameplay` | S | Aucune |
| SEL-03 | Mutation `healParty` (full heal) | `map_gameplay` | XS | Aucune |
| SEL-04 | Mutation `grantBadge` | `map_gameplay` | XS | Aucune |
| SEL-05 | Mutations `addMoney` / `removeMoney` | `map_gameplay` | XS | Aucune |

> **Total Phase 1** : ~1-2 jours. Pure Dart, entièrement testable.

---

### Phase 2 — Commandes script + cutscene steps (Priorité 🔴 critique)

| Lot | Titre | Packages | Effort | Dépendances |
|---|---|---|---|---|
| SEL-06 | `ScriptCommandType.givePokemon` + executor | `map_core` + `map_runtime` | S | SEL-02 |
| SEL-07 | `ScriptCommandType.healParty` + executor | `map_core` + `map_runtime` | XS | SEL-03 |
| SEL-08 | `ScriptCommandType.grantBadge` + executor | `map_core` + `map_runtime` | XS | SEL-04 |
| SEL-09 | `CutsceneGivePokemonStep` | `map_runtime` | S | SEL-02 |
| SEL-10 | `CutsceneHealPartyStep` | `map_runtime` | XS | SEL-03 |
| SEL-11 | `CutsceneStartTrainerBattleStep` (async handoff) | `map_runtime` | M | Aucune (battle engine prêt) |
| SEL-12 | `CutsceneGiveItemStep` | `map_runtime` | XS | SEL-01 |
| SEL-13 | `CutsceneGrantBadgeStep` | `map_runtime` | XS | SEL-04 |

> **Total Phase 2** : ~3-5 jours. Nécessite coordination core/runtime.

---

### Phase 3 — Flows runtime intégrés (Priorité 🟠 majeur)

| Lot | Titre | Package | Effort | Dépendances |
|---|---|---|---|---|
| SEL-14 | Flow New Game (overlay + GameState init) | `map_runtime` | M | SEL-02 |
| SEL-15 | Shop runtime minimal (overlay + buy/sell) | `map_runtime` | M-L | SEL-01, SEL-05 |
| SEL-16 | Heal center interaction (overlay ou cutscene) | `map_runtime` | S | SEL-03 |

> **Total Phase 3** : ~3-5 jours. Flutter UI dans `map_runtime`.

---

### Phase 4 — Conditions enrichies (Priorité 🟡)

| Lot | Titre | Package | Effort |
|---|---|---|---|
| SEL-17 | Condition `hasPokemonInParty` | `map_core` + `map_gameplay` | XS |
| SEL-18 | Condition `hasBadge` | `map_core` + `map_gameplay` | XS |
| SEL-19 | Condition `hasItem` (in Bag) | `map_core` + `map_gameplay` | XS |

> **Total Phase 4** : ~1 jour.

---

### Phase 5 — Contenu Selbrume (après infrastructure)

| Lot | Titre | Package | Effort |
|---|---|---|---|
| SEL-20 | Map Labo + Professeur NPC + Dialogue starter | `map_editor` fixtures | M |
| SEL-21 | Map Route 1 + herbes + encounters + Rival NPC | `map_editor` fixtures | M |
| SEL-22 | Map Selbrume + Centre Pokémon + Boutique | `map_editor` fixtures | M |
| SEL-23 | Map Route 2 + dresseurs | `map_editor` fixtures | S |
| SEL-24 | Map Arène + Champion + Badge | `map_editor` fixtures | M |
| SEL-25 | Cutscene Selbrume complète (Global Story) | `map_editor` fixtures | L |
| SEL-26 | Smoke test E2E Selbrume | `examples/playable_runtime_host` | M |

> **Total Phase 5** : ~5-7 jours. Contenu authoring + test intégration.

---

### Résumé effort estimé

| Phase | Effort | Priorité |
|---|---|---|
| Phase 1 — Mutations | 1-2 jours | 🔴 |
| Phase 2 — Script/Cutscene steps | 3-5 jours | 🔴 |
| Phase 3 — Flows runtime | 3-5 jours | 🟠 |
| Phase 4 — Conditions | 1 jour | 🟡 |
| Phase 5 — Contenu | 5-7 jours | 🟡 |
| **Total** | **13-20 jours** | |

---

## 7. Recommandation Golden Slice

> [!IMPORTANT]
> **La Golden Slice Selbrume la plus petite et la plus prouvable** :
>
> `SEL-01` + `SEL-02` + `SEL-03` + `SEL-09` + `SEL-11` + `SEL-14`
>
> Soit : fix `giveItem`, ajouter `givePokemon`, `healParty`, câbler les cutscene steps correspondants, ajouter le trigger battle depuis cutscene, et le flow New Game.
>
> **Résultat** : Un joueur peut créer une partie, recevoir un starter via cutscene, explorer des herbes, combattre un rival déclenché par cutscene, se soigner, et sauvegarder.
>
> **Effort estimé** : ~5-7 jours de développement.

### Exclure du Golden Slice MVP

- XP / level-up / evolution (non-MVP, énorme complexité)
- PC/Box (party < 6 suffit pour le scénario)
- Shop complet (Poké Balls peuvent être données par script en MVP)
- Money system complet (badge sans récompense monétaire en MVP)

---

## 8. Annexe : preuves et références

### Tests exécutés pendant l'audit

| Package | Commande | Résultat |
|---|---|---|
| `map_core` | `cd packages/map_core && dart test` | ✅ 1905 pass |
| `map_gameplay` | `cd packages/map_gameplay && dart test` | ✅ 127 pass |
| `map_battle` | `cd packages/map_battle && dart test` | ✅ 1162 pass |

### Rapports existants consultés

- [narrative_studio_readiness_audit.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/narrative_studio_readiness_audit.md)
- [narrative_studio_product_model_v0.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/narrative_studio_product_model_v0.md)
- [pokemap_roadmap_mecaniques_fangame.md](file:///Users/karim/Project/pokemonProject/pokemap_roadmap_mecaniques_fangame.md)

### Fichiers clés inspectés

| Fichier | Rôle |
|---|---|
| [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | État de partie runtime |
| [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | Modèle de sauvegarde persisté |
| [script_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_asset.dart) | Commandes de script (12 types) |
| [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) | Graphe narratif (nœuds/arêtes) |
| [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | Mutations pure Dart |
| [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart) | 17 types de cutscene steps |
| [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart) | Exécuteur de cutscenes |
| [runtime_battle_outcome_apply.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart) | Write-back post-combat |
| [battle_start_request.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart) | Requête de combat (sealed class) |
| [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) | NPC data + visibility rules |
| [validators.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart) | Validation projet (2000+ lignes) |

### Git status

Aucune modification de fichier effectuée pendant cet audit (conformément au lot SEL-000).

---

*Rapport généré par audit SEL-000. Aucun code n'a été modifié.*

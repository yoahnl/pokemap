# NS-GS-01 — Golden Slice Exact Specification

**Date** : 2026-05-23
**Repo** : `/Users/karim/Project/pokemonProject`
**Lot** : NS-GS-01 — Documentary only (aucun code)
**Auteur** : Audit automatisé

---

## 1. Objet du document

Ce document est la spécification exacte, exploitable et vérifiable du **Golden Slice narratif** du scénario *Les Brumes de Selbrume*.

Le Golden Slice couvre la séquence minimale :

```text
Maël (Bourg de Selbrume)
→ mission / setup initial (starter optionnel)
→ arrivée au Port des Brisants
→ alerte port (foule paniquée)
→ rencontre Lysa (rival)
→ combat rival (battle_rival_port)
→ victory / defeat branch
→ facts persistants
→ step completed
→ world rule visible (Lysa change de dialogue)
→ save/load cohérent
```

Ce slice est le premier test end-to-end du pipeline :

```text
Event → Scene → Outcome → Fact → Step → World Rule
```

Si ce golden slice fonctionne, le modèle narratif de PokeMap tient debout.

---

## 2. Documents sources lus

| Document | Chemin | Rôle |
|---|---|---|
| selbrume.md | `MVP Selbrume/selbrume.md` | Scénario canonique (2261 lignes) |
| narrative_studio.md | `MVP Selbrume/narrative_studio.md` | Vision produit Narrative Studio (1859 lignes) |
| SEL-000-bis | `reports/gameplay/selbrume_readiness_audit_and_plan_bis.md` | Audit readiness corrigé (784 lignes) |
| SEL-A2 | `reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md` | Contrat Event → Scene → Outcome → Fact |
| SEL-A1 | `reports/gameplay/sel_a1_narrative_glossary.md` | Glossaire narratif |
| SEL-B2 | `reports/gameplay/sel_b2_battle_from_scene.md` | Battle from Scene implémenté |
| SEL-B1 | `reports/gameplay/sel_b1_fix_give_item_to_bag.md` | Fix giveItem → Bag implémenté |

---

## 3. Périmètre exact du Golden Slice

### Inclus

```text
1 storyline (main story — La brume du phare)
1 chapitre (Chapitre 1 — Le port)
4 story steps (intro, mission, aller au port, combat rival)
2 maps (map_bourg_selbrume, map_port_brisants)
3 NPCs (npc_mael, npc_lysa, npc_soline — figurante)
2 events (event_mael_intro, event_rival_meet)
2 scenes / ScenarioAssets (scene_mael_intro, scene_rival_meet)
2 dialogues Yarn (yarn_mael_intro, yarn_rival_intro)
2 cinematics (cinematic_rival_smiles, cinematic_rival_teases)
1 combat trainer (battle_rival_port / trainer_lysa_port)
2 scenes post-combat (scene_rival_after_win, scene_rival_after_loss)
8+ facts / flags
4+ world rules (NPC visibility changes)
1 save/load cycle
```

### Exclu du Golden Slice

```text
Chapitres 2, 3, 4
Marais, Phare, Cabane
Quêtes annexes (cristaux, Goélise, cabane)
Boss battle (static encounter)
Wild encounters
Shop, Money, XP, Level-up, Evolution
PC/Box
Heal center
Key items
Passage locked/unlocked
Quest tracking system
Event Builder UI, Scene Builder UI, Facts & World Rules UI
Validator reachability
```

---

## 4. Maps requises

### map_bourg_selbrume

```text
ID            : map_bourg_selbrume
Rôle          : Hub — point de départ, maison de Maël, retour
Taille        : petite (libre, ~20x20 minimum)
Spawn player  : devant la maison de Maël ou sur la place
Zones         : place centrale, sortie vers le port (sud ou est)
Encounters    : aucune (village)
Triggers      : aucun trigger zone dans le GS
```

Entités :

| Entity ID | Type | Position | Rôle |
|---|---|---|---|
| `entity_mael_bourg` | NPC | Place centrale | Maël — interaction déclenche event_mael_intro |
| `entity_exit_to_port` | Warp/Door | Bord de map | Transition vers map_port_brisants |

### map_port_brisants

```text
ID            : map_port_brisants
Rôle          : Port — rencontre rival Lysa, alerte
Taille        : petite à moyenne (~25x20 minimum)
Spawn player  : arrivée depuis bourg (entrée nord ou ouest)
Zones         : quai, zone de la foule, zone de Lysa
Encounters    : aucune dans le GS (optionnel : herbes sur le chemin)
Triggers      : trigger_port_arrival (zone d'entrée)
```

Entités :

| Entity ID | Type | Position | Rôle |
|---|---|---|---|
| `entity_lysa_port` | NPC | Quai principal | Lysa — interaction déclenche event_rival_meet |
| `entity_soline_port` | NPC | Près du bureau du port | Soline — figurante, dialogue simple |
| `entity_exit_to_bourg` | Warp/Door | Bord de map | Retour vers map_bourg_selbrume |

---

## 5. NPCs requis

### npc_mael

```text
ID            : npc_mael
Entity        : entity_mael_bourg (sur map_bourg_selbrume)
Sprite        : à définir (homme adulte, garde-nature)
Direction     : face au joueur (ou sud)
```

Dialogues conditionnels :

| Condition | Dialogue | Comportement |
|---|---|---|
| `step_intro_selbrume` NOT completed | yarn_mael_intro (via scene_mael_intro) | Donne la mission, potentiellement le starter |
| `step_mission_received` completed AND `step_rival_battle` NOT completed | yarn_mael_encouragement | "Va voir au port, il se passe quelque chose." |
| `step_rival_battle` completed | yarn_mael_post_rival | "Tu as fait du bon travail au port." |

Visibility rules :

```text
Toujours présent sur map_bourg_selbrume (pas de règle de masquage dans le GS)
```

### npc_lysa

```text
ID            : npc_lysa
Entity        : entity_lysa_port (sur map_port_brisants)
Sprite        : à définir (jeune femme, rival)
Direction     : face au joueur
trainerId     : trainer_lysa_port
```

Dialogues conditionnels :

| Condition | Dialogue | Comportement |
|---|---|---|
| `step_go_to_port` completed AND `fact_rival_defeated` NOT set | event_rival_meet → scene_rival_meet | Provoque le joueur, lance le combat |
| `fact_rival_defeated` set (victory) | yarn_lysa_post_win | "Pas mal… On se reverra." |
| `fact_rival_lost` set (defeat) | yarn_lysa_post_loss | "C'est moi la plus forte ! Mais t'as du cran." |

Visibility rules :

| Rule | Condition | Effet |
|---|---|---|
| Avant step_go_to_port completed | `stepNotCompleted:step_go_to_port` | Lysa absente du port |
| Après step_go_to_port, avant combat | `stepCompleted:step_go_to_port AND NOT storyFlagSet:fact_rival_battle_done` | Lysa présente, interactable |
| Après combat (victory) | `storyFlagSet:battle:battle_rival_port:victory` | Lysa présente, dialogue post-victory |
| Après combat (defeat) | `storyFlagSet:battle:battle_rival_port:defeat` | Lysa présente, dialogue post-defeat |

### npc_soline (figurante)

```text
ID            : npc_soline
Entity        : entity_soline_port (sur map_port_brisants)
Sprite        : à définir (femme adulte, responsable du port)
Direction     : face au joueur
```

Dialogue :

```text
Dialogue simple (pas d'event, pas de scene).
"La brume est bizarre ces derniers jours..."
```

Visibility : toujours présente.

---

## 6. Story Steps (progression)

### Storyline : story_main_brume_phare

### Chapter : chapter_1_port

| Step ID | Nom | Completion mode | Completion trigger | Pré-requis |
|---|---|---|---|---|
| `step_intro_selbrume` | Introduction à Selbrume | `whenCutsceneEnds` | Fin de scene_mael_intro | Aucun (step initial) |
| `step_mission_received` | Recevoir la mission | `whenOutcomeEmitted` | Outcome `mission_started` de scene_mael_intro | step_intro_selbrume |
| `step_go_to_port` | Aller au port | `whenFlagSet` | Flag `fact_arrived_at_port` posé par trigger_port_arrival | step_mission_received |
| `step_rival_battle` | Combat rival | `whenCutsceneEnds` | Fin de scene_rival_after_win OU scene_rival_after_loss | step_go_to_port |

### Mapping vers l'existant runtime

Le runtime actuel supporte uniquement `whenCutsceneEnds` via `StepCompletionCutsceneIndex` dans [step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart).

Conséquences pour le GS :

```text
step_intro_selbrume    → whenCutsceneEnds     → ✅ supporté nativement
step_mission_received  → whenOutcomeEmitted   → ❌ pas supporté (doit être ajouté ou contourné)
step_go_to_port        → whenFlagSet          → ❌ pas supporté (doit être ajouté ou contourné)
step_rival_battle      → whenCutsceneEnds     → ✅ supporté nativement
```

**Contournement V0** : les steps `step_mission_received` et `step_go_to_port` peuvent être fusionnés avec la cutscene précédente/suivante et utiliser `whenCutsceneEnds` si les modes `whenOutcomeEmitted`/`whenFlagSet` ne sont pas implémentés à temps.

---

## 7. Events

### event_mael_intro

```text
ID            : event_mael_intro
Trigger       : interaction joueur avec entity_mael_bourg
Source type   : entityInteract (kScenarioSourceEntityInteract)
```

Pages :

| Page | Condition | Action |
|---|---|---|
| Page 1 (première visite) | `stepNotCompleted:step_intro_selbrume` | Lance scene_mael_intro |
| Page 2 (mission reçue, pas encore au port) | `stepCompleted:step_mission_received AND stepNotCompleted:step_go_to_port` | Dialogue simple yarn_mael_encouragement |
| Page 3 (rival battu) | `stepCompleted:step_rival_battle` | Dialogue simple yarn_mael_post_rival |

### Mapping vers l'existant

Le modèle `MapEventDefinition` dans [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) supporte les pages conditionnelles avec `ScriptRef`. Le runtime les résout via `EventPageResolver` dans `map_gameplay`.

```text
MapEventDefinition.pages → chaque page a une condition + une ScriptRef
ScriptRef pointe vers un ScenarioAsset (graphe) ou un CutsceneAsset (séquence)
La première page dont la condition est vraie est exécutée
```

**Statut** : ✅ Le modèle et le runtime existent. Le contenu doit être créé.

### event_rival_meet

```text
ID            : event_rival_meet
Trigger       : interaction joueur avec entity_lysa_port
Source type   : entityInteract
```

Pages :

| Page | Condition | Action |
|---|---|---|
| Page 1 (première rencontre) | `stepCompleted:step_go_to_port AND NOT storyFlagSet:fact_rival_battle_done` | Lance scene_rival_meet |
| Page 2 (après victoire) | `storyFlagSet:battle:battle_rival_port:victory` | Dialogue yarn_lysa_post_win |
| Page 3 (après défaite) | `storyFlagSet:battle:battle_rival_port:defeat` | Dialogue yarn_lysa_post_loss |

---

## 8. Scenes (ScenarioAssets)

### scene_mael_intro

```text
ID            : scene_mael_intro
Scope         : local (attaché à map_bourg_selbrume)
entryNodeId   : node_start
declaredOutcomes : [mission_started]
activationCondition : null (déclenché par event_mael_intro)
```

Graphe :

```text
[node_start] (type: start)
    │
    ▼
[node_dialogue_intro] (type: action, kind: openDialogue)
    │  → dialogue: yarn_mael_intro
    │
    ▼
[node_condition_party] (type: condition)
    │  → condition: partyEmpty (ScriptConditionType.custom / partySize == 0)
    │
    ├── true branch ──▶ [node_starter_flow] (type: action, kind: showMessage)
    │                     │  → "Maël te tend une Poké Ball..."
    │                     │  → (starter donné via action ou pré-chargé — voir §13 Décision D1)
    │                     ▼
    │                   [node_merge_1] (type: action, kind: flowMerge)
    │
    └── false branch ─▶ [node_existing_pokemon] (type: action, kind: openDialogue)
                          │  → dialogue: yarn_mael_existing_pokemon
                          │  → "Tu as déjà un compagnon ? Parfait."
                          ▼
                        [node_merge_1]
                          │
                          ▼
[node_emit_mission] (type: action, kind: emitOutcome)
    │  → outcomeId: mission_started
    │
    ▼
[node_set_flag] (type: action, kind: setFlag)
    │  → flagName: fact_mission_started
    │
    ▼
[node_end] (type: end)
```

### scene_rival_meet

```text
ID            : scene_rival_meet
Scope         : local (attaché à map_port_brisants)
entryNodeId   : node_start
declaredOutcomes : [rival_battle_started]
activationCondition : null (déclenché par event_rival_meet)
```

Graphe :

```text
[node_start] (type: start)
    │
    ▼
[node_dialogue_rival] (type: action, kind: openDialogue)
    │  → dialogue: yarn_rival_intro
    │  → Yarn retourne un outcome parmi : confident / hesitant / aggressive
    │
    ▼
[node_condition_tone] (type: condition)
    │  → condition: storyFlagSet (flag = outcome:confident)
    │
    ├── true branch ──▶ [node_cinematic_smiles] (type: action, kind: openDialogue)
    │                     │  → cinématique : cinematic_rival_smiles
    │                     ▼
    │                   [node_merge_tone]
    │
    └── false branch ─▶ [node_cinematic_teases] (type: action, kind: openDialogue)
                          │  → cinématique : cinematic_rival_teases
                          ▼
                        [node_merge_tone]
                          │
                          ▼
[node_battle] (type: action, kind: startTrainerBattle)  ← SEL-B2
    │  → trainerId: trainer_lysa_port
    │  → npcEntityId: entity_lysa_port
    │  → battleId: battle_rival_port
    │  → SUSPEND : le graphe s'arrête ici
    │  → Runtime lance le battle handoff
    │  → BattleOutcome → flag battle:battle_rival_port:victory OU defeat
    │  → dispatchContinuation reprend le graphe
    │
    ▼
[node_condition_victory] (type: condition)
    │  → condition: storyFlagSet (flag = battle:battle_rival_port:victory)
    │
    ├── true branch ──▶ [node_victory_scene] (type: action, kind: openDialogue)
    │                     │  → dialogue: yarn_rival_after_win
    │                     │  → "Pas mal… Je l'admets."
    │                     ▼
    │                   [node_set_victory_flag] (type: action, kind: setFlag)
    │                     │  → flagName: fact_rival_defeated
    │                     ▼
    │                   [node_merge_outcome]
    │
    └── false branch ─▶ [node_defeat_scene] (type: action, kind: openDialogue)
                          │  → dialogue: yarn_rival_after_loss
                          │  → "C'est moi la plus forte !"
                          ▼
                        [node_set_defeat_flag] (type: action, kind: setFlag)
                          │  → flagName: fact_rival_lost
                          ▼
                        [node_merge_outcome]
                          │
                          ▼
[node_set_battle_done] (type: action, kind: setFlag)
    │  → flagName: fact_rival_battle_done
    │
    ▼
[node_emit_outcome] (type: action, kind: emitOutcome)
    │  → outcomeId: rival_battle_done
    │
    ▼
[node_end] (type: end)
```

### Mapping vers l'existant

Les deux scenes utilisent `ScenarioAsset` (modèle existant dans [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart)) avec les types de nœuds existants :

| Node type | Existant ? | Preuve |
|---|---|---|
| `start` | ✅ | `ScenarioNodeType.start` |
| `end` | ✅ | `ScenarioNodeType.end` |
| `action` (openDialogue) | ✅ | `kScenarioActionOpenDialogue` |
| `action` (showMessage) | ✅ | `kScenarioActionShowMessage` |
| `action` (setFlag) | ✅ | `kScenarioActionSetFlag` |
| `action` (emitOutcome) | ✅ | `kScenarioActionEmitOutcome` |
| `action` (startTrainerBattle) | ✅ | `kScenarioActionStartTrainerBattle` (SEL-B2) |
| `action` (flowMerge) | ✅ | `kScenarioActionFlowMerge` |
| `condition` | ✅ | `ScenarioNodeType.condition` |

Tous les types de nœuds nécessaires au GS sont déjà implémentés dans le runtime.

---

## 9. Dialogues Yarn

### yarn_mael_intro

```text
ID      : yarn_mael_intro
Fichier : assets/dialogues/yarn_mael_intro.yarn (à créer)
```

Contenu attendu :

```text
Maël présente le contexte :
- La brume étrange autour du phare
- Les pêcheurs inquiets
- Les Pokémon nerveux

Outcomes possibles Yarn :
- accept_mission → le joueur accepte d'aller au port
- ask_more → le joueur pose des questions, puis accepte quand même

(Les deux outcomes convergent vers mission_started dans le graphe)
```

### yarn_rival_intro

```text
ID      : yarn_rival_intro
Fichier : assets/dialogues/yarn_rival_intro.yarn (à créer)
```

Contenu attendu :

```text
Lysa interpelle le joueur :
- "Toi aussi tu es venu voir la brume ?"
- Elle se moque / provoque

Choix joueur :
- "Je peux aider." → outcome: confident
- "Je ne suis pas sûr." → outcome: hesitant
- "Pousse-toi, je vais régler ça." → outcome: aggressive

L'outcome influence la cinématique pré-combat, pas le combat lui-même.
```

### yarn_rival_after_win

```text
ID      : yarn_rival_after_win
Contenu : Lysa reconnaît la force du joueur, part vers les marais.
```

### yarn_rival_after_loss

```text
ID      : yarn_rival_after_loss
Contenu : Lysa se moque mais reconnaît le courage du joueur.
```

### yarn_mael_encouragement / yarn_mael_post_rival

```text
Dialogues simples (pas de choix, pas d'outcome).
Variantes contextuelles de Maël selon la progression.
```

### Mapping vers l'existant

Le runtime Yarn est opérationnel :

```text
parseYarnFile() → ✅ (packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart)
DialogueSession → ✅ (packages/map_runtime/lib/src/application/dialogue_runtime_models.dart)
YarnDialogueRef → ✅ (intégré dans MapEntityNpcData et ScenarioNodePayload)
Choix Yarn → ✅ (options de dialogue gérées par le runtime)
```

---

## 10. Cinematics

### cinematic_rival_smiles

```text
ID      : cinematic_rival_smiles
Type    : RuntimeCutsceneAsset (séquence linéaire)
Trigger : outcome "confident" de yarn_rival_intro
```

Steps :

```text
1. CutsceneWaitStep (0.5s)
2. CutsceneCharacterEmoteStep (entity_lysa_port, emote: smile)
3. CutsceneShowMessageStep ("Lysa sourit. 'D'accord, montre-moi ce que tu sais faire.'")
4. CutsceneWaitStep (0.3s)
```

### cinematic_rival_teases

```text
ID      : cinematic_rival_teases
Type    : RuntimeCutsceneAsset (séquence linéaire)
Trigger : outcomes "hesitant" ou "aggressive" de yarn_rival_intro
```

Steps :

```text
1. CutsceneWaitStep (0.5s)
2. CutsceneCharacterEmoteStep (entity_lysa_port, emote: smirk)
3. CutsceneShowMessageStep ("Lysa ricane. 'On verra bien si tu fais le poids !'")
4. CutsceneWaitStep (0.3s)
```

### Mapping vers l'existant

Le Cutscene Runtime Runner est opérationnel :

```text
RuntimeCutsceneAsset          → ✅ (cutscene_runtime_models.dart)
CutsceneWaitStep              → ✅ (type existant)
CutsceneShowMessageStep       → ✅ (type existant)
CutsceneCharacterEmoteStep    → 🧪 à vérifier (17 step types existent)
```

Si `CutsceneCharacterEmoteStep` n'existe pas encore, les cinématiques peuvent se limiter à `ShowMessage` + `Wait` pour le V0.

---

## 11. Combat

### battle_rival_port

```text
ID            : battle_rival_port
Type          : Trainer battle
Trainer ID    : trainer_lysa_port
NPC Entity    : entity_lysa_port
battleId      : battle_rival_port (pour le flag naming)
```

Trainer Lysa (à créer dans le manifest) :

```text
Trainer :
  id          : trainer_lysa_port
  name        : Lysa
  pokemonTeam : 1 Pokémon, niveau ~5
  sprite      : à définir
  defeatText  : "Pas mal du tout !"
```

Outcomes possibles :

| BattleOutcomeType | Flag posé | Suffixe |
|---|---|---|
| `victory` | `battle:battle_rival_port:victory` | `victory` |
| `defeat` | `battle:battle_rival_port:defeat` | `defeat` |
| `runaway` | `battle:battle_rival_port:flee` | `flee` |
| `captured` | n/a (trainer battle) | n/a |

Convention de flag — SEL-B2 :

```text
Format : battle:<battleId>:<outcome>
Helper : scenarioBattleOutcomeFlagName(battleId, outcomeSuffix)
Fichier : scenario_battle_outcome_flags.dart
```

La défaite **ne bloque PAS** l'histoire. Elle produit un branchement différent (scene_rival_after_loss), puis rejoint le flux principal.

### Pipeline de déclenchement (SEL-B2 implémenté)

```text
scene_rival_meet → node_battle (kind: startTrainerBattle)
→ ScenarioRuntimeExecutor retourne ScenarioRuntimeEffect(type: battle)
→ PlayableMapGame._handleScenarioBattleEffect()
→ Construit TrainerBattleStartRequest via buildTrainerBattleRequestFromNpc
→ Mémorise _pendingScenarioBattleSourceId + _pendingScenarioBattleId
→ Enqueue dans _pendingBattleRequest
→ update() → _startBattleHandoff() → combat
→ _onBattleFinished(BattleOutcome)
→ Pose flag battle:battle_rival_port:<outcome> via _storyFlags.set
→ _resumeScenarioAfterRuntimeSource → dispatchContinuation
→ Le graphe reprend après node_battle
→ node_condition_victory évalue le flag
→ Branche victory ou defeat
```

**Statut** : ✅ Pipeline complet implémenté et testé (23 tests verts — SEL-B2).

---

## 12. Facts / Flags

### Registre complet des flags du Golden Slice

| Flag name | Posé par | Utilisé par | Type |
|---|---|---|---|
| `fact_mission_started` | scene_mael_intro (node_set_flag) | Condition visibility Lysa au port | Story flag |
| `fact_arrived_at_port` | trigger_port_arrival (action setFlag) | step_go_to_port completion | Story flag |
| `battle:battle_rival_port:victory` | _onBattleFinished via SEL-B2 helper | node_condition_victory dans scene_rival_meet | Battle outcome flag |
| `battle:battle_rival_port:defeat` | _onBattleFinished via SEL-B2 helper | node_condition_victory (false branch) | Battle outcome flag |
| `fact_rival_defeated` | scene_rival_meet (node_set_victory_flag) | Lysa dialogue post-win, Maël dialogue variant | Story flag |
| `fact_rival_lost` | scene_rival_meet (node_set_defeat_flag) | Lysa dialogue post-loss | Story flag |
| `fact_rival_battle_done` | scene_rival_meet (node_set_battle_done) | Lysa event page 2/3 condition | Story flag |
| `outcome:mission_started` | emitOutcome dans scene_mael_intro | Progression step completion | Outcome flag |
| `outcome:rival_battle_done` | emitOutcome dans scene_rival_meet | Step completion step_rival_battle | Outcome flag |

### Mapping vers l'existant

```text
StoryFlags.activeFlags → Set<String> dans GameState → ✅
GameStateMutations.setFlag(state, flagName) → ✅
ScriptConditionType.storyFlagSet → ✅
ScriptConditionType.storyFlagNotSet → ✅
MapEntityRuntimePredicateKind.storyFlagSet → ✅
MapEntityRuntimePredicateKind.storyFlagUnset → ✅
scenarioBattleOutcomeFlagName(battleId, suffix) → ✅ (SEL-B2)
```

Tous les flags du GS sont des `String` stockés dans `StoryFlags.activeFlags`. Pas de typage fort (les flags sont des strings libres). Acceptable pour le GS.

---

## 13. Décisions à prendre

### D1 — Starter : donné par Maël en jeu OU pré-chargé dans GameState initial ?

```text
Option A : Maël donne le starter pendant scene_mael_intro
  → Nécessite : mutation givePokemon dans map_gameplay + action dans ScenarioExecutor
  → Avantage : scénario complet, testable, fidèle au scénario canonique
  → Coût : ~M (mutation + action + tests)

Option B : Le starter est pré-chargé dans le GameState initial (New Game)
  → Nécessite : un flow New Game qui initialise le party avec un Pokémon
  → Avantage : contourne le problème givePokemon, plus simple
  → Coût : ~S
  → Inconvénient : Maël ne "donne" pas le starter, il dit juste "tu as déjà un compagnon"

Option C : Hybride — le GameState initial contient un starter, mais si party vide Maël en donne un
  → Nécessite : les deux mécanismes
  → Avantage : robuste
  → Coût : M+S

Recommandation : Option B pour le GS V0, Option A pour le GS V1.
```

### D2 — New Game flow : comment initialiser le GameState ?

```text
Option A : Overlay Flutter "New Game" avec choix du nom + starter
  → Coût : M-L (overlay + init state + transition vers première map)

Option B : GameState hardcodé en fixture pour le GS V0
  → Un fichier JSON de sauvegarde initiale chargé au démarrage
  → Coût : XS
  → Inconvénient : pas testable end-to-end pour le "vrai" New Game

Option C : Minimal New Game — nom du joueur + starter prédéfini, pas de choix
  → Coût : S

Recommandation : Option B pour le GS V0 (fixture), Option C pour le GS V1.
```

### D3 — Step completion modes additionnels

```text
Le runtime actuel ne supporte que whenCutsceneEnds.

Pour le GS, les steps step_mission_received et step_go_to_port auraient besoin de :
- whenOutcomeEmitted (quand un outcome est émis par une scene)
- whenFlagSet (quand un flag est posé)

Contournement V0 : fusionner ces steps dans la cutscene précédente et utiliser
whenCutsceneEnds pour tout.

Recommandation : Contournement V0 (fusionner), puis ajouter les modes en V1.
```

### D4 — Cinématiques : steps types disponibles

```text
Le GS utilise des cinématiques simples (attente + message + emote).

Si CutsceneCharacterEmoteStep n'existe pas, les cinématiques se limitent à :
- CutsceneWaitStep
- CutsceneShowMessageStep
- CutsceneMoveCharacterStep (existe)

Cela suffit pour le GS V0.
```

---

## 14. World Rules

### Règles de visibilité NPC

| Règle | NPC | Condition | Effet |
|---|---|---|---|
| WR-01 | npc_lysa (port) | `stepNotCompleted:step_go_to_port` | Lysa absente |
| WR-02 | npc_lysa (port) | `stepCompleted:step_go_to_port AND NOT storyFlagSet:fact_rival_battle_done` | Lysa présente, event actif |
| WR-03 | npc_lysa (port) | `storyFlagSet:fact_rival_battle_done` | Lysa présente, dialogue post-combat |

### Mapping vers l'existant

```text
MapEntityNpcVisibilityRule → ✅ (map_entity_payloads.dart)
MapEntityRuntimePredicateKind.stepCompleted → ✅
MapEntityRuntimePredicateKind.stepNotCompleted → ✅
MapEntityRuntimePredicateKind.storyFlagSet → ✅
MapEntityRuntimePredicateKind.storyFlagUnset → ✅
isNpcRuntimePresentOnMap() → ✅ (npc_runtime_presence.dart)
_refreshWorldNpcPresence() → ✅ (playable_map_game.dart)
```

Les 8 `MapEntityRuntimePredicateKind` disponibles couvrent tous les besoins du GS :

```text
storyFlagSet, storyFlagUnset
stepCompleted, stepNotCompleted
chapterCompleted, chapterNotCompleted
cutsceneCompleted, cutsceneNotCompleted
```

---

## 15. Save/Load

### Données persistées

| Donnée | Champ SaveData | Sérialisée ? |
|---|---|---|
| Position joueur | `SaveData.playerPosition` | ✅ |
| Map courante | `SaveData.currentMapId` | ✅ |
| Party (Pokémon) | `SaveData.party` (PlayerParty) | ✅ |
| Bag (items) | `SaveData.bag` (Bag) | ✅ (SEL-B1 fix) |
| Story flags | `SaveData.playerProgression.storyFlags` | ✅ |
| Completed steps | `SaveData.playerProgression.completedStepIds` | ✅ |
| Completed cutscenes | `SaveData.playerProgression.completedCutsceneIds` | ✅ |
| Trainers battus | `SaveData.trainerProfile.defeatedTrainerIds` | ✅ |
| Metadata libre | `SaveData.metadata` | ✅ |

### Scénario de test save/load pour le GS

```text
1. Nouveau jeu → spawn sur map_bourg_selbrume
2. Parler à Maël → mission reçue → flags posés
3. SAUVEGARDER
4. Quitter et recharger
5. Vérifier :
   - Position restaurée
   - Flags fact_mission_started et outcome:mission_started présents
   - step_intro_selbrume et step_mission_received dans completedStepIds
   - Maël affiche le dialogue "Va voir au port"
6. Aller au port → trigger pose fact_arrived_at_port
7. Parler à Lysa → combat → victoire
8. SAUVEGARDER
9. Quitter et recharger
10. Vérifier :
    - Flag battle:battle_rival_port:victory présent
    - Flag fact_rival_defeated présent
    - Flag fact_rival_battle_done présent
    - step_rival_battle dans completedStepIds
    - Lysa affiche dialogue post-victory
    - trainer_lysa_port dans defeatedTrainerIds
```

### Mapping vers l'existant

```text
FileGameSaveRepository → ✅ (file_game_save_repository.dart)
SaveGameUseCase → ✅ (save_game_use_case.dart)
LoadGameUseCase → ✅ (load_game_use_case.dart)
normalizeLoadedGameState → ✅ (GameState ↔ SaveData bidirectionnel)
```

### Limite V0

```text
Sauvegarder pendant un combat narratif (entre le lancement du combat et la
continuation du graphe) n'est PAS supporté. Le pending scenario battle est
en mémoire uniquement (_pendingScenarioBattleSourceId). Si le joueur
sauvegarde et quitte pendant le combat, le graphe scénario ne pourra pas
reprendre au reload. Acceptable pour le GS V0.
```

---

## 16. Séquence complète du Golden Slice

### Flux narratif complet

```text
═══════════════════════════════════════════════════════
  GOLDEN SLICE — Les Brumes de Selbrume (Chapitre 1)
═══════════════════════════════════════════════════════

1. NEW GAME
   ├─ GameState initial (fixture ou New Game flow)
   ├─ Party : 1 Pokémon starter (pré-chargé — Décision D1)
   ├─ Bag : vide (ou 5 Poké Balls)
   ├─ StoryFlags : vide
   ├─ CompletedSteps : vide
   └─ Spawn : map_bourg_selbrume, devant Maël

2. INTERACTION MAËL (map_bourg_selbrume)
   ├─ Joueur interagit avec entity_mael_bourg
   ├─ event_mael_intro résolu → Page 1 (stepNotCompleted:step_intro_selbrume)
   ├─ Lance scene_mael_intro (ScenarioAsset)
   │   ├─ node_dialogue_intro → yarn_mael_intro
   │   ├─ node_condition_party → si party vide : message starter / sinon : message existant
   │   ├─ node_emit_mission → outcome: mission_started
   │   ├─ node_set_flag → flag: fact_mission_started
   │   └─ node_end
   ├─ Step step_intro_selbrume → completed (whenCutsceneEnds)
   ├─ Step step_mission_received → completed (contournement V0)
   └─ ⟹ Maël change de dialogue → "Va au port"

3. TRANSITION map_bourg_selbrume → map_port_brisants
   ├─ Joueur emprunte entity_exit_to_port (warp)
   ├─ Arrivée sur map_port_brisants
   ├─ trigger_port_arrival → setFlag: fact_arrived_at_port
   ├─ Step step_go_to_port → completed
   └─ ⟹ Lysa apparaît au port (WR-02 : stepCompleted:step_go_to_port)

4. INTERACTION LYSA (map_port_brisants)
   ├─ Joueur interagit avec entity_lysa_port
   ├─ event_rival_meet résolu → Page 1
   ├─ Lance scene_rival_meet (ScenarioAsset)
   │   ├─ node_dialogue_rival → yarn_rival_intro
   │   │   └─ Joueur choisit : confident / hesitant / aggressive
   │   ├─ node_condition_tone → branche sur outcome Yarn
   │   │   ├─ confident → cinematic_rival_smiles
   │   │   └─ autre → cinematic_rival_teases
   │   ├─ node_battle → kind: startTrainerBattle
   │   │   ├─ trainerId: trainer_lysa_port
   │   │   ├─ npcEntityId: entity_lysa_port
   │   │   ├─ battleId: battle_rival_port
   │   │   └─ ⟹ SUSPEND : graphe suspendu
   │   │
   │   ╠═══ COMBAT ═══╗
   │   ║               ║
   │   ║  battle handoff → BattleSetup → combat tour par tour
   │   ║  Lysa : 1 Pokémon ~niveau 5
   │   ║  Joueur : starter ~niveau 5
   │   ║               ║
   │   ╠═══════════════╝
   │   │
   │   ├─ _onBattleFinished(BattleOutcome)
   │   │   ├─ Flag posé : battle:battle_rival_port:victory OU defeat
   │   │   └─ dispatchContinuation → graphe reprend
   │   │
   │   ├─ node_condition_victory → évalue flag victory
   │   │   ├─ VICTORY :
   │   │   │   ├─ yarn_rival_after_win
   │   │   │   └─ setFlag: fact_rival_defeated
   │   │   └─ DEFEAT :
   │   │       ├─ yarn_rival_after_loss
   │   │       └─ setFlag: fact_rival_lost
   │   │
   │   ├─ node_set_battle_done → setFlag: fact_rival_battle_done
   │   ├─ node_emit_outcome → outcome: rival_battle_done
   │   └─ node_end
   │
   ├─ Step step_rival_battle → completed (whenCutsceneEnds)
   └─ ⟹ Lysa change de dialogue (WR-03)

5. POST-COMBAT
   ├─ Lysa reste sur la map, dialogue variant selon victory/defeat
   ├─ Maël (si retour à Bourg) → dialogue "Tu as fait du bon travail"
   └─ Le joueur peut explorer librement

6. SAVE/LOAD
   ├─ Sauvegarde valide à tout point hors combat
   ├─ Au reload : position, flags, steps, party, bag restaurés
   └─ Monde visuel recalculé depuis les flags (NPC visibility)
```

---

## 17. Acquis techniques confirmés

| Capacité | Statut | Preuve |
|---|---|---|
| ScenarioAsset graphe traversal | ✅ | 14 tests `scenario_runtime_executor_test.dart` |
| ScenarioNodeType : start, end, action, condition, choice, reference | ✅ | Enum complet dans `scenario_asset.dart` |
| 13 action kinds supportés par l'executor | ✅ | `kScenarioAction*` constants dans `scenario_runtime_executor.dart` |
| startTrainerBattle depuis graphe scénario | ✅ | SEL-B2 — 9 tests, pipeline complet |
| Battle outcome → flag déterministe | ✅ | `battle:<battleId>:<outcome>` — SEL-B2 |
| Post-battle continuation → graphe reprend | ✅ | `dispatchContinuation` — SEL-B2 |
| Yarn dialogue runtime | ✅ | `parseYarnFile`, `DialogueSession` |
| StoryFlags set/check | ✅ | `GameStateMutations.setFlag`, `ScriptConditionType.storyFlagSet` |
| NPC visibility rules | ✅ | `MapEntityNpcVisibilityRule`, 8 predicate kinds |
| Conditional dialogue pages | ✅ | `MapEntityConditionalDialogue`, `EventPageResolver` |
| Step completion (whenCutsceneEnds) | ✅ | `StepCompletionCutsceneIndex` |
| Save/Load flags, steps, party, bag | ✅ | `SaveData ↔ GameState` bidirectionnel |
| giveItem → Bag | ✅ | SEL-B1 — 6 tests, Bag.normalized() |
| Cutscene runtime | ✅ | 17 step types, `CutsceneRuntimeRunner` (801 lignes) |
| emitOutcome | ✅ | `kScenarioActionEmitOutcome` |
| flowMerge | ✅ | `kScenarioActionFlowMerge` |
| Map transition (warp) | ✅ | `kScenarioActionTransitionMap` |

---

## 18. Écarts / Gaps confirmés

| # | Gap | Impact GS | Contournement V0 | Lot à créer |
|---|---|---|---|---|
| GAP-01 | Pas de New Game flow | P0 | Fixture GameState JSON | NS-GS-02 |
| GAP-02 | Pas de givePokemon | P1 | Starter pré-chargé dans fixture | NS-GS-03 |
| GAP-03 | Step completion uniquement whenCutsceneEnds | P1 | Fusionner steps dans cutscenes | NS-GS-04 |
| GAP-04 | Pas de contenu Selbrume (maps, NPCs, dialogues) | P0 | Créer fixtures minimales | NS-GS-05 |
| GAP-05 | Pas de trigger_port_arrival (zone trigger → setFlag) | P1 | Utiliser trigger zone existant | NS-GS-05 |
| GAP-06 | Tone branching (outcome Yarn → condition dans graphe) | P1 | Le runtime supporte la condition ; l'authoring doit poser le flag Yarn | NS-GS-05 |
| GAP-07 | Trainer Lysa pas définie dans le manifest | P0 | Créer la fixture trainer | NS-GS-05 |
| GAP-08 | Pas de healParty | P2 | Le joueur peut se battre avec les PV restants | Hors GS V0 |
| GAP-09 | Pas de static encounter / boss battle | Hors GS | N/A | NS-GS-08 |
| GAP-10 | Cinematic emote step à vérifier | P2 | Utiliser showMessage + wait | NS-GS-05 |

---

## 19. Validation criteria (Definition of Done du Golden Slice)

Le Golden Slice est **jouable** si et seulement si :

```text
1. Le joueur spawn sur map_bourg_selbrume avec un starter.
2. Le joueur peut parler à Maël → scene_mael_intro se joue complètement.
3. Les flags fact_mission_started et outcome:mission_started sont posés.
4. Les steps step_intro_selbrume et step_mission_received sont complétés.
5. Le joueur peut se déplacer vers map_port_brisants via le warp.
6. Le trigger_port_arrival pose fact_arrived_at_port.
7. Le step step_go_to_port est complété.
8. Lysa apparaît sur la map (visibility rule satisfaite).
9. Le joueur peut parler à Lysa → scene_rival_meet se joue.
10. Le dialogue Yarn yarn_rival_intro propose un choix.
11. La cinématique correspondante se joue.
12. Le combat trainer contre Lysa se lance.
13. Le combat se joue jusqu'à un outcome (victory ou defeat).
14. Le flag battle:battle_rival_port:<outcome> est posé.
15. Le graphe scénario reprend après le combat.
16. La branche victory ou defeat se joue correctement.
17. Les flags fact_rival_defeated / fact_rival_lost et fact_rival_battle_done sont posés.
18. Le step step_rival_battle est complété.
19. Lysa affiche un dialogue post-combat différent selon victory/defeat.
20. Le joueur peut sauvegarder.
21. Au reload, tous les flags, steps, party, bag et position sont restaurés.
22. Au reload, Lysa affiche le bon dialogue post-combat.
23. Maël affiche un dialogue contextuel si le joueur revient au bourg.
```

---

## 20. Ambiguïtés restantes

| # | Ambiguïté | Impact | Décision requise par |
|---|---|---|---|
| AMB-01 | Le starter est-il donné par Maël en jeu ou pré-chargé ? | Change le scope du GS (givePokemon mutation vs fixture) | Utilisateur → NS-GS-02 |
| AMB-02 | Quel Pokémon starter ? | Besoin d'un ID Pokémon existant dans le projet | Utilisateur |
| AMB-03 | Quel Pokémon a Lysa ? | Besoin d'un ID + niveau + moves | Utilisateur |
| AMB-04 | Le tone outcome Yarn (confident/hesitant/aggressive) pose-t-il un flag automatiquement ou faut-il un nœud setFlag explicite ? | Impact le graphe scene_rival_meet | Technique → NS-GS-05 |
| AMB-05 | Les 3 outcomes Yarn (confident/hesitant/aggressive) sont-ils réduits à 2 branches (confident vs reste) pour le GS V0 ? | Simplifie le graphe | Utilisateur |
| AMB-06 | La défaite autorise-t-elle un re-match immédiat ou le joueur continue avec son party affaibli ? | Impact le flow post-defeat | Utilisateur |
| AMB-07 | Le step_go_to_port est-il complété par un trigger zone ou par l'arrivée sur la map ? | Impact le mécanisme de completion | Technique → NS-GS-04/05 |
| AMB-08 | Faut-il une alerte port (foule paniquée) comme cutscene séparée ou intégrée dans scene_rival_meet ? | selbrume.md mentionne scene_port_alert, mais le GS minimal peut s'en passer | Utilisateur |

---

## 21. Roadmap NS-GS-02 à NS-GS-12

| Lot | Titre | Type | Dépendance | Effort |
|---|---|---|---|---|
| **NS-GS-02** | Starter / Initial Party Decision | Décision | — | XS |
| **NS-GS-03** | givePokemon mutation + scenario action (si D1 = Option A) | Code | NS-GS-02 | M |
| **NS-GS-04** | New Game Flow V0 (fixture GameState ou overlay minimal) | Code | NS-GS-02 | S-M |
| **NS-GS-05** | Contenu Golden Slice (maps, NPCs, dialogues Yarn, ScenarioAssets, trainer, cinématiques) | Contenu | NS-GS-02, NS-GS-04 | L |
| **NS-GS-06** | Zone Trigger → setFlag pour step_go_to_port | Code | — | S |
| **NS-GS-07** | Step completion modes additionnels (whenFlagSet, whenOutcomeEmitted) — si non contourné | Code | — | M |
| **NS-GS-08** | Static encounter / boss battle trigger (Pokémon du phare — hors GS V0) | Code | SEL-B2 | M |
| **NS-GS-09** | healParty mutation + cutscene step ou overlay (hors GS V0) | Code | — | S |
| **NS-GS-10** | Integration test end-to-end du Golden Slice | Test | NS-GS-05 | M |
| **NS-GS-11** | Validator reachability pour ScenarioAsset | Code | — | M |
| **NS-GS-12** | Golden Slice V1 — scene_port_alert + givePokemon runtime + full Chapitre 1 | Contenu+Code | NS-GS-03, NS-GS-07 | L |

### Chemin critique pour le GS V0 jouable

```text
NS-GS-02 (décision starter)
→ NS-GS-04 (New Game flow / fixture)
→ NS-GS-05 (contenu — maps, NPCs, Yarn, ScenarioAssets, trainer)
→ NS-GS-06 (trigger zone si nécessaire)
→ NS-GS-10 (test end-to-end)
```

Estimation chemin critique : **S + S-M + L + S + M ≈ 3-5 sessions de travail**.

---

## 22. Résumé des lots déjà terminés

| Lot | Statut | Impact sur le GS |
|---|---|---|
| SEL-A1 — Glossaire narratif | ✅ Done | Vocabulaire unifié |
| SEL-A2 — Contrat Event→Scene→Outcome→Fact | ✅ Done | Architecture documentée |
| SEL-B1 — Fix giveItem → Bag | ✅ Done | Items fonctionnels dans le Bag |
| SEL-B2 — Battle from Scene | ✅ Done | Combat depuis graphe scénario opérationnel |
| SEL-B2-bis — Validation hardening | ✅ Done | Wiring runtime confirmé |

---

## 23. Evidence Pack

### Fichiers runtime inspectés

| Fichier | Lignes | Rôle vérifié |
|---|---|---|
| [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) | 179 | ScenarioAsset model, ScenarioNodeType enum, ScenarioEdgeKind, declaredOutcomes, activationCondition |
| [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) | 1186 | 13 kScenarioAction* constants, dispatch(), dispatchContinuation(), condition evaluation |
| [scenario_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart) | — | ScenarioRuntimeEffectType enum (none, dialogue, script, message, battle) |
| [scenario_battle_outcome_flags.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart) | — | scenarioBattleOutcomeFlagName helper, kBattleOutcomeSuffix* constants |
| [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) | 4000+ | _handleScenarioBattleEffect, _onBattleFinished SEL-B2 block, _resumeScenarioAfterRuntimeSource |
| [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart) | 313 | 17 CutsceneStep types |
| [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart) | 801 | Sequential playback, choice, branch |
| [step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart) | 130 | whenCutsceneEnds — seul mode de completion |
| [global_story_chapter_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart) | 102 | Index chapitres → steps |
| [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | 166+ | 10 mutations, giveItem fixed (SEL-B1) |
| [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) | 162 | MapEventDefinition pages conditionnelles |
| [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) | 408 | NPC visibility rules, conditional dialogues, 8 predicate kinds |
| [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | — | PlayerProgression (storyFlags, completedStepIds, completedCutsceneIds), Bag, SaveData |
| [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | — | GameState, StoryFlags, TrainerBattleRecord |
| [file_game_save_repository.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart) | — | FileGameSaveRepository |

### Commandes exécutées (lecture seule)

```bash
rg "ScenarioNodeType|ScenarioRuntimeEffectType" packages/map_runtime/lib --type dart --no-line-number
rg "scenarioOutcomeFlagName|kScenarioAction" packages/map_runtime/lib --type dart --no-line-number
rg "activationCondition|kStepStudioDocumentMetadataKey|kGlobalStoryStudio" packages/map_core/lib --type dart --no-line-number
rg "giveItem|GiveItem" packages/map_gameplay --type dart -l
rg "class Bag|class GameState|class PlayerProgression|class SaveData" packages/map_core/lib --type dart --no-line-number
rg "givePokemon|giveStarterPokemon|starter" packages/map_gameplay --type dart --no-line-number
rg "YarnProject|YarnDialogue|DialogueRunner" packages/map_runtime/lib --type dart -l
rg "FileGameSaveRepository|save_repository|saveGameState|loadGameState" packages/map_runtime/lib --type dart -l
rg "newGame|NewGame|new_game" packages/map_runtime/lib --type dart -l
rg "Trainer" packages/map_core/lib/src/models/ --type dart -l
rg "givePokemon|addPartyMember|party" packages/map_gameplay/lib --type dart --no-line-number
rg "TrainerData|trainerData|TrainerDefinition" packages/map_core/lib --type dart -l
```

### Preuves clés SEL-B2 (battle from scene)

```text
Fichier test : packages/map_runtime/test/scenario_battle_from_scene_test.dart
Résultat : 9 tests, all passed
Fichier test existant : packages/map_runtime/test/scenario_runtime_executor_test.dart
Résultat : 14 tests, all passed
Total combiné : 23 tests, all passed
dart analyze lib/src/application/scenario_runtime/ : No issues found
```

### Preuves clés SEL-B1 (giveItem fix)

```text
Fichier test : packages/map_gameplay/test/game_state_mutations_test.dart
Résultat : 6 tests, all passed
dart test (global map_gameplay) : 133 tests, all passed
dart analyze : 2 issues (none in modified files)
```

### Action kinds confirmés dans ScenarioRuntimeExecutor

```text
kScenarioActionRunScript       = 'runScript'
kScenarioActionOpenDialogue    = 'openDialogue'
kScenarioActionShowMessage     = 'showMessage'
kScenarioActionMoveCharacter   = 'moveCharacter'
kScenarioActionFollowCharacter = 'followCharacter'
kScenarioActionFaceCharacter   = 'faceCharacter'
kScenarioActionTransitionMap   = 'transitionMap'
kScenarioActionSetFlag         = 'setFlag'
kScenarioActionClearFlag       = 'clearFlag'
kScenarioActionEmitOutcome     = 'emitOutcome'
kScenarioActionStartTrainerBattle = 'startTrainerBattle'
kScenarioActionFlowMerge       = 'flowMerge'
kScenarioActionAuthoringPlaceholder = 'authoringPlaceholder'
```

### ScenarioRuntimeEffectType enum

```text
none
dialogue
script
message
battle
```

### MapEntityRuntimePredicateKind enum (8 kinds)

```text
storyFlagSet
storyFlagUnset
stepCompleted
stepNotCompleted
chapterCompleted
chapterNotCompleted
cutsceneCompleted
cutsceneNotCompleted
```

### Fichiers non modifiés par ce lot

```text
Aucun fichier de code modifié.
Aucune fixture modifiée.
Aucun test modifié.
Aucun build_runner lancé.
Aucune opération Git d'écriture effectuée.
```

---

*Fin du document NS-GS-01.*

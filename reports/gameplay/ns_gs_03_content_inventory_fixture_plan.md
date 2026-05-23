# NS-GS-03 — Content Inventory & Fixture Plan

---

## 1. Résumé exécutif

Ce lot inventorie **tous** les contenus, fixtures, assets, ids, fichiers et dépendances nécessaires pour construire le Golden Slice Selbrume V0. Il ne crée rien ; il produit la **liste de courses officielle**.

Le Golden Slice V0 prouve le pipeline complet :

```text
Spawn à Bourg Selbrume (party vide)
→ interaction avec Maël (PNJ mentor)
→ Maël donne réellement le starter (GivePokemon)
→ Maël donne la mission
→ le joueur se déplace au Port des Brisants
→ interaction avec Lysa (rivale)
→ combat rival (battle handoff)
→ victory / defeat branch
→ facts persistants
→ step completed
→ world rule visible
→ save/load cohérent
```

GivePokemon (NS-GS-06) est une **dépendance obligatoire** : le joueur commence sans Pokémon.

`sproutle` et `sparkitten` sont des **recommandations techniques candidates**, pas des décisions utilisateur irréversibles. Le starter et le Pokémon rival restent confirmables/remplaçables avant la création effective des fixtures.

Après review de ce rapport, le prochain lot est **NS-GS-04 — Runtime Smoke Strategy**.

---

## 2. Sources et méthode

### Documents lus

| Document | Chemin |
|---|---|
| NS-GS-01 | [ns_gs_01_golden_slice_exact_specification.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_01_golden_slice_exact_specification.md) |
| NS-GS-02 | [ns_gs_02_starter_initial_party_decision.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_02_starter_initial_party_decision.md) |
| SEL-A1 | [sel_a1_narrative_glossary.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_a1_narrative_glossary.md) |
| SEL-A2 | [sel_a2_event_scene_outcome_fact_contract.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md) |
| SEL-B2 | [sel_b2_battle_from_scene.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_b2_battle_from_scene.md) |
| SEL-B2-bis | [sel_b2_battle_from_scene_bis.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_b2_battle_from_scene_bis.md) |
| SEL-B1 | [sel_b1_fix_give_item_to_bag.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_b1_fix_give_item_to_bag.md) |
| Scénario | [selbrume.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/selbrume.md) |
| Roadmap | [road_map.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/road_map.md) |
| Vision | [narrative_studio.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/narrative_studio.md) |

### Fichiers inspectés (lecture seule)

| Fichier / zone | Rôle |
|---|---|
| [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | GameState fields |
| [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | PlayerPokemon, PlayerParty, Bag, PlayerProgression, SaveData |
| [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) | ScenarioAsset, ScenarioNode, ScenarioNodePayload |
| [map_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_data.dart) | MapData, MapEntity, events list |
| [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) | NPC visibility rules, conditional dialogues, spawn data |
| [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) | MapEventDefinition |
| [project_manifest.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart) | ProjectManifest (maps, trainers, pokemon) |
| [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) | kScenarioAction* constants |
| [scenario_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart) | ScenarioRuntimeEffectType, ScenarioRuntimeSourceType |
| [scenario_battle_outcome_flags.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart) | scenarioBattleOutcomeFlagName |
| [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart) | RuntimeCutsceneAsset, cutscene step types |
| [step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart) | Step completion via cutscene end |
| [global_story_chapter_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart) | Chapter completion via step ids |
| [step_studio_world_presence_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart) | NPC presence rules via step ids |
| [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) | Battle handoff, scenario dispatch |
| [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | 10 existing mutations, no givePokemon |
| [project.json](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json) | GBS project manifest |
| [golden_field.json](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json) | GBS map structure |
| [runtime_host_launch_save.json](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json) | GBS save fixture (party pre-loaded) |
| [runtime_demo_party_seed.dart](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart) | Party seed pattern |
| Species JSON files | sproutle (001), sparkitten (004) |

### Commandes exécutées

```bash
git status --short --untracked-files=all
rg "MapEventDefinition|MapEntityNpcVisibilityRule|ScenarioAsset|RuntimeCutsceneAsset" packages/map_core/lib --type dart -l
rg "startTrainerBattle|ScenarioRuntimeEffectType|dispatchContinuation" packages/map_runtime/lib --type dart -l
rg "enum ScenarioRuntimeEffectType" packages/map_runtime/lib/src/application/scenario_runtime/
rg "kScenarioAction*" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
rg "scenarioBattleOutcome" packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
rg "class PlayerProgression|storyFlags|completedStepIds" packages/map_core/lib/src/models/save_data.dart
rg "class GameState|@Default" packages/map_core/lib/src/models/game_state.dart
rg "Bag|BagEntry" packages/map_core/lib/src/models/save_data.dart
find . -path "*/golden_battle_slice/*"
find . -path "*/map_bourg*" -o -path "*/port_brisants*" -o -path "*/selbrume*"
```

### Limites de l'audit

- Pas de tests lancés.
- Pas de build_runner lancé.
- Pas de lecture exhaustive de tout le code runtime — ciblé sur les modèles et les action kinds.
- Les assets visuels (sprites, tilesets) n'ont pas été audités exhaustivement.

---

## 3. Décisions héritées de NS-GS-01/02

| Décision | Source | Statut |
|---|---|---|
| Maël est un PNJ mentor, pas le joueur | NS-GS-01 | Canonique |
| Le joueur commence sans starter reçu (party vide) | NS-GS-02-bis | Canonique |
| Maël donne réellement le starter en jeu (Option A) | NS-GS-02-bis | Canonique |
| NS-GS-06 GivePokemon Minimal est obligatoire avant NS-GS-12 | NS-GS-02-bis | Canonique |
| Le starter recommandé actuel est `sproutle` | NS-GS-02 | **Candidat/recommandation** — confirmable par l'utilisateur |
| Le starter final reste confirmable/remplaçable | NS-GS-02-bis | Canonique |
| Le Pokémon rival recommandé actuel est `sparkitten` | NS-GS-02 | **Candidat/recommandation** — confirmable par l'utilisateur |
| L'Option B (starter pré-chargé) est rejetée pour GS V0 | NS-GS-02-bis | Canonique |
| L'Option C (hybride) est rejetée pour GS V0 | NS-GS-02-bis | Canonique |

> [!IMPORTANT]
> `sproutle` est une recommandation technique actuelle, pas une décision utilisateur irréversible.
> `sparkitten` est une recommandation technique actuelle, pas une décision utilisateur irréversible.
> L'utilisateur peut confirmer ou remplacer ces species avant la création des fixtures (NS-GS-08/11).

---

## 4. Périmètre exact de l'inventaire

### Inclus

```text
Bourg Selbrume — map minimale avec Maël
Port des Brisants — map minimale avec Lysa et Soline
Maël — PNJ mentor, donne le starter, donne la mission
Lysa — rivale, combat trainer
Soline — figurante, dialogue simple
Starter donné par Maël — via GivePokemon
Combat rival Lysa — battle handoff
Facts, flags, battle outcome flags
Story steps et chapter
World rules (visibilité NPC, dialogues conditionnels)
Save/load du GameState complet
```

### Exclu (hors scope GS V0)

```text
Marais Salants, Bois de la Chaise-Brume, Passage des Dames
Phare (extérieur, intérieur, sommet)
Cabane du gardien
Boss final
Quêtes annexes
Shop / marchand
PC / boxes
Heal center
Wild encounters
XP / level-up avancé
Évolutions
Pokédex complet
Choix complet de starter (3 starters)
UI starter selection overlay
UI complète Narrative Studio / Éditeur
Validator narratif complet
Système de capture
Système d'échange Pokémon
```

---

## 5. Vue globale des lots consommateurs

| Lot | Consomme quels éléments de l'inventaire | Dépendances | Notes |
|---|---|---|---|
| **NS-GS-05** | Initial state, currentMapId, playerPosition, party vide, bag vide, storyFlags vide, completedStepIds vide | Aucune (premier lot code) | Prépare le GameState/SaveData initial |
| **NS-GS-06** | Mutation givePokemon, PlayerPokemon, speciesId, fact_starter_received, anti-doublon | NS-GS-05 (party vide) | Rend GivePokemon utilisable par scénario |
| **NS-GS-08** | map_bourg_selbrume, entity_mael_bourg, npc_mael, scene_mael_intro, yarn_mael_*, starter donné | NS-GS-05, NS-GS-06 | Contenu Maël et Bourg |
| **NS-GS-09** | map_port_brisants, entity_lysa_port, npc_lysa, entity_soline_port, npc_soline, scene_rival_meet, yarn_rival_*, warps | NS-GS-08 (warp from Bourg) | Contenu Lysa et Port |
| **NS-GS-10** | story_main_brume_phare, chapter_1_port, step_*, world rules, conditional dialogues, NPC presence rules | NS-GS-08, NS-GS-09 | Câblage narratif |
| **NS-GS-11** | trainer_lysa_port, battle_rival_port, team Lysa, battle outcome flags, victory/defeat text | NS-GS-09 | Battle fixture Lysa |
| **NS-GS-12** | Tous les éléments ci-dessus, save/load fixtures, smoke test scripts | NS-GS-05..11 | Smoke test final |

---

## 6. Inventaire initial state / New Game minimal

| Élément | ID / valeur proposée | Statut | Lot responsable | Notes |
|---|---|---|---|---|
| currentMapId | `map_bourg_selbrume` | À créer | NS-GS-05 | Map de départ |
| playerPosition | `GridPos(x: ?, y: ?)` près de Maël | À définir | NS-GS-05 + NS-GS-08 | Position exacte dépend du layout de la map |
| playerFacing | `EntityFacing.south` | Par défaut | NS-GS-05 | Défaut GameState |
| party | `PlayerParty()` **vide** | Défaut | NS-GS-05 | **NE PAS pré-charger le starter** |
| bag | `Bag()` vide | Défaut | NS-GS-05 | Aucun item initial en V0 |
| trainerProfile.name | `"Joueur"` ou configurable | À définir | NS-GS-05 | Placeholder acceptable en V0 |
| storyFlags | `StoryFlags()` vide | Défaut | NS-GS-05 | Aucun flag initial |
| progression.storyFlags | `[]` vide | Défaut | NS-GS-05 | Pas de progression initiale |
| progression.completedStepIds | `[]` vide | Défaut | NS-GS-05 | Pas de step complétée |
| progression.completedCutsceneIds | `[]` vide | Défaut | NS-GS-05 | Pas de cutscene complétée |
| consumedEventIds | `{}` vide | Défaut | NS-GS-05 | Pas d'event consommé |
| metadata | `{}` vide | Défaut | NS-GS-05 | Pas de metadata initiale |
| saveId | UUID auto-généré | À implémenter | NS-GS-05 | Identifiant de sauvegarde |

> [!IMPORTANT]
> La party initiale est vide. Le starter est reçu de Maël via GivePokemon (NS-GS-06).

---

## 7. Inventaire GivePokemon minimal

| Besoin | Description | Package probable | Lot | Notes |
|---|---|---|---|---|
| Mutation addPartyMember / givePokemon | Ajouter un `PlayerPokemon` à `GameState.party.members` | `map_gameplay` | NS-GS-06 | Mutation pure Dart dans `GameStateMutations` |
| Création PlayerPokemon | `PlayerPokemon(speciesId, level, knownMoveIds, natureId, abilityId, currentHp)` | `map_core` (modèle existant) | NS-GS-06 | Le modèle `PlayerPokemon` existe déjà |
| speciesId candidat | `sproutle` | — | NS-GS-06 | Candidat paramétrable |
| level | 5 | — | NS-GS-06 | Recommandation |
| knownMoveIds | `[tackle, growl]` | — | NS-GS-06 | Recommandation |
| currentHp | Calculé ou fixe (~22) | — | NS-GS-06 | Doit être plein |
| natureId | `hardy` (neutre) | — | NS-GS-06 | Recommandation |
| abilityId | `overgrow` | — | NS-GS-06 | Recommandation |
| Anti-doublon | Vérifier que le starter n'est pas déjà dans la party (flag `fact_starter_received` ou party non vide) | `map_gameplay` | NS-GS-06 | Empêcher le redon |
| Flag fact_starter_received | Posé par le ScenarioAsset après givePokemon réussi | `map_runtime` (via `kScenarioActionSetFlag`) | NS-GS-08 (utilise NS-GS-06) | Action `setFlag` existe déjà |
| Action ScenarioAsset | Nouveau `kScenarioActionGivePokemon` ou script `runScript` qui appelle givePokemon | `map_runtime` | NS-GS-06 | Choix d'implémentation : action kind natif vs runScript |
| Tests unitaires | Test mutation : party vide → party avec 1 Pokémon | `map_gameplay/test` | NS-GS-06 | Obligatoire |
| Tests save/load | Test que le Pokémon donné survit save → reload | `map_core/test` ou `map_runtime/test` | NS-GS-06 | Obligatoire |

### Non-objectifs de NS-GS-06

```text
Pas de choix starter (un seul Pokémon fixe)
Pas d'UI riche (pas d'animation de don, pas de notification overlay)
Pas de système complet de cadeaux Pokémon
Pas d'échange Pokémon
Pas de stockage PC
Pas de validation exhaustive de toutes les espèces
Pas de calcul HP à partir des stats de base
Un seul Pokémon donné (le starter), un seul donneur (Maël)
```

---

## 8. Inventaire maps

| Map id | Nom auteur | Rôle GS | Taille minimale | Contenu requis | Lot | Statut |
|---|---|---|---|---|---|---|
| `map_bourg_selbrume` | Bourg de Selbrume | Village de départ | 16×12 minimum | Spawn joueur, Maël, warp vers Port | NS-GS-08 | À créer |
| `map_port_brisants` | Port des Brisants | Lieu du combat rival | 16×12 minimum | Lysa, Soline, zone combat, warp vers Bourg | NS-GS-09 | À créer |

### map_bourg_selbrume — détail

| Élément | Description | Lot | Statut |
|---|---|---|---|
| Objectif | Zone de départ : le joueur y spawne et parle à Maël | NS-GS-08 | À créer |
| Spawn | `entity_spawn_bourg` — position de départ du joueur | NS-GS-08 | À créer |
| Warp vers Port | `entity_exit_to_port` — transition vers `map_port_brisants` | NS-GS-08 | À créer |
| NPC Maël | `entity_mael_bourg` — mentor, interaction → scene_mael_intro | NS-GS-08 | À créer |
| Tiles | Placeholder acceptable : sol, maisons, chemins | NS-GS-08 | Placeholder OK |
| Éléments optionnels | Décor, panneaux, arbres | post-GS | Optionnel |

### map_port_brisants — détail

| Élément | Description | Lot | Statut |
|---|---|---|---|
| Objectif | Lieu du combat rival Lysa | NS-GS-09 | À créer |
| Warp vers Bourg | `entity_exit_to_bourg` — retour vers `map_bourg_selbrume` | NS-GS-09 | À créer |
| NPC Lysa | `entity_lysa_port` — rivale, interaction → scene_rival_meet | NS-GS-09 | À créer |
| NPC Soline | `entity_soline_port` — figurante, dialogue simple | NS-GS-09 | À créer |
| Trigger arrivée | `trigger_port_arrival` — optionnel, peut déclencher une cutscene d'arrivée | NS-GS-09 | Optionnel |
| Tiles | Placeholder acceptable : quai, sol, eau | NS-GS-09 | Placeholder OK |
| Éléments optionnels | Bateaux, décor portuaire | post-GS | Optionnel |

---

## 9. Inventaire entities et NPCs

### Table NPCs

| NPC id | Nom auteur | Rôle | Map | Entity id | Lot | Statut | Notes |
|---|---|---|---|---|---|---|---|
| `npc_mael` | Maël | Mentor / garde-nature, donne le starter | `map_bourg_selbrume` | `entity_mael_bourg` | NS-GS-08 | À créer | Interaction → scene_mael_intro |
| `npc_lysa` | Lysa | Rivale, combat trainer | `map_port_brisants` | `entity_lysa_port` | NS-GS-09 | À créer | Interaction → scene_rival_meet |
| `npc_soline` | Soline | Figurante / info NPC | `map_port_brisants` | `entity_soline_port` | NS-GS-09 | À créer | Dialogue simple, placeholder V0 |

### Table entities

| Entity id | Type | Map | Rôle | Déclencheur / interaction | Lot | Notes |
|---|---|---|---|---|---|---|
| `entity_spawn_bourg` | Spawn | `map_bourg_selbrume` | Position de départ du joueur | Automatique | NS-GS-08 | Utilisé par NS-GS-05 initial state |
| `entity_mael_bourg` | NPC | `map_bourg_selbrume` | Maël mentor | entityInteract → scene_mael_intro | NS-GS-08 | Visibilité : toujours visible |
| `entity_exit_to_port` | Warp | `map_bourg_selbrume` | Transition vers Port | Warp auto ou interaction | NS-GS-08 | Destination : entity_arrival_from_bourg |
| `entity_arrival_from_bourg` | Spawn | `map_port_brisants` | Arrivée depuis Bourg | — | NS-GS-09 | Destination du warp |
| `entity_lysa_port` | NPC | `map_port_brisants` | Lysa rivale | entityInteract → scene_rival_meet | NS-GS-09 | Visibilité : world rule |
| `entity_soline_port` | NPC | `map_port_brisants` | Soline figurante | entityInteract → dialogue simple | NS-GS-09 | Visibilité : toujours visible |
| `entity_exit_to_bourg` | Warp | `map_port_brisants` | Retour vers Bourg | Warp auto ou interaction | NS-GS-09 | Destination : entity_spawn_bourg ou autre |

---

## 10. Inventaire events et triggers

| Event / Trigger id | Type | Source | Conditions | Action attendue | Lot | Notes |
|---|---|---|---|---|---|---|
| `event_mael_intro` | entityInteract | Joueur interagit avec `entity_mael_bourg` | fact_starter_received absent (ou party vide) | Lance scene_mael_intro | NS-GS-08 | Scène complète : dialogue + givePokemon + mission |
| `event_mael_encouragement` | entityInteract | Joueur re-parle à Maël après starter | fact_starter_received posé | Lance yarn_mael_encouragement ou yarn_mael_post_rival | NS-GS-08 | Dialogue conditionnel |
| `event_rival_meet` | entityInteract | Joueur interagit avec `entity_lysa_port` | fact_mission_started posé, fact_rival_battle_done absent | Lance scene_rival_meet | NS-GS-09 | Scène complète : dialogue + combat + branch |
| `event_rival_after` | entityInteract | Joueur re-parle à Lysa après combat | fact_rival_battle_done posé | Lance yarn_rival_after_win ou yarn_rival_after_loss | NS-GS-09 | Dialogue conditionnel |
| `event_soline_idle` | entityInteract | Joueur interagit avec `entity_soline_port` | Aucune | Lance yarn_soline_port_idle | NS-GS-09 | Dialogue simple placeholder |
| `trigger_port_arrival` | triggerEnter | Joueur entre dans une zone du port | fact_mission_started posé, first visit | Cutscene d'arrivée optionnelle | NS-GS-09 | Optionnel en V0 |

> [!NOTE]
> La distinction entre interaction NPC et trigger zone est gérée par `ScenarioRuntimeSourceType` :
> - `entityInteract` pour les NPCs
> - `triggerEnter` pour les zones trigger
> - `mapEnter` pour l'arrivée sur une map

---

## 11. Inventaire storyline / chapter / story steps

### Storyline

| Storyline id | Nom auteur | Type | Lot | Statut |
|---|---|---|---|---|
| `story_main_brume_phare` | La Brume du Phare | Main storyline | NS-GS-10 | À créer |

### Chapter

| Chapter id | Nom auteur | Storyline | Lot | Statut |
|---|---|---|---|---|
| `chapter_1_port` | Chapitre 1 — Alerte au port | `story_main_brume_phare` | NS-GS-10 | À créer |

### Steps

| Step id | Nom auteur | Pré-requis | Completion attendue | Lot | Notes |
|---|---|---|---|---|---|
| `step_intro_selbrume` | Début à Selbrume | Aucun (premier step) | Joueur a parlé à Maël et reçu la mission | NS-GS-10 | Inclut le don du starter ; peut être complété lorsque scene_mael_intro atteint `end` |
| `step_starter_received` | Starter reçu | — | fact_starter_received posé | NS-GS-10 | Peut être fusionné avec step_intro_selbrume si un seul step suffit. Note : décision à valider par l'utilisateur |
| `step_mission_received` | Mission reçue | step_starter_received | fact_mission_started posé | NS-GS-10 | Peut être fusionné avec step_intro_selbrume. Note : décision à valider |
| `step_go_to_port` | Aller au port | step_mission_received | Joueur arrive au port (mapEnter ou trigger) | NS-GS-10 | Complété par arrivée au port |
| `step_rival_battle` | Combat rival | step_go_to_port | fact_rival_battle_done posé | NS-GS-10 | Complété après victory ou defeat |

> [!NOTE]
> Les steps `step_starter_received` et `step_mission_received` peuvent être fusionnés avec `step_intro_selbrume` si l'utilisateur préfère un découpage plus simple. Le runtime supporte un step par scénario local (completion via cutscene end). La granularité fine est recommandée pour les world rules mais pas obligatoire.

---

## 12. Inventaire facts, flags et outcomes

| Id | Type | Label auteur | Produit par | Lu par | Lot | Notes |
|---|---|---|---|---|---|---|
| `fact_starter_received` | Fact auteur (storyFlag) | Starter reçu | scene_mael_intro (setFlag) | event_mael_intro (condition anti-redon), world rules | NS-GS-08 | Posé après givePokemon |
| `fact_mission_started` | Fact auteur (storyFlag) | Mission lancée | scene_mael_intro (setFlag) | event_rival_meet (condition), world rules | NS-GS-08 | Posé après dialogue mission |
| `fact_arrived_at_port` | Fact auteur (storyFlag) | Arrivée au port | trigger_port_arrival ou mapEnter handler | world rules | NS-GS-09 | Optionnel en V0 — peut être remplacé par step_go_to_port |
| `fact_rival_battle_done` | Fact auteur (storyFlag) | Combat rival terminé | scene_rival_meet (setFlag) | world rules, dialogue conditionnel Lysa | NS-GS-09 | Posé après battle outcome branch |
| `fact_rival_defeated` | Fact auteur (storyFlag) | Victoire contre Lysa | scene_rival_meet branch victory | dialogue conditionnel Lysa, Maël | NS-GS-09 | Posé seulement en cas de victoire |
| `fact_rival_lost` | Fact auteur (storyFlag) | Défaite contre Lysa | scene_rival_meet branch defeat | dialogue conditionnel Lysa | NS-GS-09 | Posé seulement en cas de défaite |
| `battle:battle_rival_port:victory` | Battle outcome flag | Victoire combat | scenarioBattleOutcomeFlagName auto | scene_rival_meet branch condition | NS-GS-11 | Généré automatiquement par le runtime |
| `battle:battle_rival_port:defeat` | Battle outcome flag | Défaite combat | scenarioBattleOutcomeFlagName auto | scene_rival_meet branch condition | NS-GS-11 | Généré automatiquement |
| `battle:battle_rival_port:flee` | Battle outcome flag | Fuite combat | scenarioBattleOutcomeFlagName auto | scene_rival_meet branch condition | NS-GS-11 | Fuite : décision ouverte (interdit ou defeat-like) |
| `outcome:mission_started` | Scenario outcome | Mission lancée | scene_mael_intro (emitOutcome) | Autres scénarios via outcomeReceived | NS-GS-08 | Émis en fin de scène Maël |
| `outcome:rival_battle_done` | Scenario outcome | Combat rival terminé | scene_rival_meet (emitOutcome) | Autres scénarios | NS-GS-09 | Émis en fin de scène rivale |

> [!NOTE]
> Les `battle:*:*` flags sont générés automatiquement par `scenarioBattleOutcomeFlagName()` dans [scenario_battle_outcome_flags.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart).
> Les facts auteur (`fact_*`) sont posés manuellement par le ScenarioAsset via `kScenarioActionSetFlag`.
> Les outcomes sont émis via `kScenarioActionEmitOutcome`.

---

## 13. Inventaire world rules et dialogues conditionnels

| Rule id | Cible | Condition | Effet visible | Lot | Notes |
|---|---|---|---|---|---|
| `wr_lysa_visible_before_battle` | `entity_lysa_port` | fact_mission_started ET NOT fact_rival_battle_done | Lysa visible au port | NS-GS-10 | Via `MapEntityNpcVisibilityRule` ou `StepStudioWorldPresenceRule` |
| `wr_lysa_invisible_before_mission` | `entity_lysa_port` | NOT fact_mission_started | Lysa absente / invisible | NS-GS-10 | Le joueur ne doit pas combattre avant la mission |
| `wr_lysa_dialogue_post_victory` | `entity_lysa_port` | fact_rival_defeated | Lysa dialogue post-victoire | NS-GS-10 | Via `MapEntityConditionalDialogue` |
| `wr_lysa_dialogue_post_defeat` | `entity_lysa_port` | fact_rival_lost | Lysa dialogue post-défaite | NS-GS-10 | Via `MapEntityConditionalDialogue` |
| `wr_mael_dialogue_before_starter` | `entity_mael_bourg` | NOT fact_starter_received | Maël lance scene_mael_intro | NS-GS-10 | Interaction → scénario |
| `wr_mael_dialogue_after_starter` | `entity_mael_bourg` | fact_starter_received ET NOT fact_rival_battle_done | Maël dit encouragement (yarn_mael_encouragement) | NS-GS-10 | Via `MapEntityConditionalDialogue` |
| `wr_mael_dialogue_post_rival` | `entity_mael_bourg` | fact_rival_battle_done | Maël réagit au résultat du combat | NS-GS-10 | Via `MapEntityConditionalDialogue` |
| `wr_soline_idle` | `entity_soline_port` | Aucune condition (toujours visible) | Soline dialogue simple | NS-GS-09 | Figurante — dialogue placeholder |

> [!NOTE]
> Le runtime supporte deux systèmes pour la visibilité/présence NPC :
> - `MapEntityNpcVisibilityRule` (côté map JSON, évalué par `MapEntityRuntimePredicateEvaluator`)
> - `StepStudioWorldPresenceRule` (côté Step Studio metadata, évalué par `StepStudioWorldPresenceRuntime`)
>
> Le choix du système dépend du workflow d'authoring. Les deux sont fonctionnels.

---

## 14. Inventaire ScenarioAssets / Scenes

| Scene id | Backing technique | Déclencheur | Nodes requis | Facts/outcomes produits | Lot | Notes |
|---|---|---|---|---|---|---|
| `scene_mael_intro` | ScenarioAsset (localEventFlow) | entityInteract sur entity_mael_bourg | openDialogue → yarn_mael_intro_before_gift, **givePokemon → starterCandidate**, setFlag → fact_starter_received, openDialogue → yarn_mael_mission, setFlag → fact_mission_started, emitOutcome → mission_started | fact_starter_received, fact_mission_started, outcome:mission_started | NS-GS-08 | Dépend de NS-GS-06 (givePokemon) |
| `scene_rival_meet` | ScenarioAsset (localEventFlow) | entityInteract sur entity_lysa_port | openDialogue → yarn_rival_intro, faceCharacter → entity_lysa_port, startTrainerBattle → trainer_lysa_port (battleId: battle_rival_port), **branch on battle outcome**, setFlag → fact_rival_defeated ou fact_rival_lost, setFlag → fact_rival_battle_done, openDialogue → yarn_rival_after_win ou yarn_rival_after_loss, emitOutcome → rival_battle_done | fact_rival_defeated ou fact_rival_lost, fact_rival_battle_done, battle:battle_rival_port:*, outcome:rival_battle_done | NS-GS-09 | Branch victory/defeat post-combat |

### scene_mael_intro — graphe conceptuel

```text
[source: entityInteract, mapId: map_bourg_selbrume, entityId: entity_mael_bourg]
  ↓
[node_dialogue_before_gift] (openDialogue → yarn_mael_intro_before_gift)
  ↓
[node_give_starter] (givePokemon → starterCandidate, L5, tackle+growl)
  ↓
[node_set_starter_flag] (setFlag → fact_starter_received)
  ↓
[node_dialogue_mission] (openDialogue → yarn_mael_mission)
  ↓
[node_set_mission_flag] (setFlag → fact_mission_started)
  ↓
[node_emit_mission] (emitOutcome → mission_started)
  ↓
[end]
```

### scene_rival_meet — graphe conceptuel

```text
[source: entityInteract, mapId: map_port_brisants, entityId: entity_lysa_port]
  ↓
[node_dialogue_intro] (openDialogue → yarn_rival_intro)
  ↓
[node_face_lysa] (faceCharacter → entity_lysa_port)
  ↓
[node_start_battle] (startTrainerBattle → trainerId: trainer_lysa_port, battleId: battle_rival_port)
  ↓ (graphe suspendu — combat joué)
[node_resume] (dispatchContinuation après BattleOutcome)
  ├── branch: battle:battle_rival_port:victory
  │     ↓
  │   [node_set_victory] (setFlag → fact_rival_defeated)
  │     ↓
  │   [node_dialogue_win] (openDialogue → yarn_rival_after_win)
  │     ↓
  │   [merge]
  └── branch: battle:battle_rival_port:defeat
        ↓
      [node_set_defeat] (setFlag → fact_rival_lost)
        ↓
      [node_dialogue_loss] (openDialogue → yarn_rival_after_loss)
        ↓
      [merge]
  ↓
[node_set_battle_done] (setFlag → fact_rival_battle_done)
  ↓
[node_emit_rival_done] (emitOutcome → rival_battle_done)
  ↓
[end]
```

---

## 15. Inventaire Yarn dialogues

| Yarn id | Rôle | Choix joueur | Outcomes | Lot | Notes |
|---|---|---|---|---|---|
| `yarn_mael_intro_before_gift` | Maël accueille le joueur et annonce le don du starter | Non | — | NS-GS-08 | Texte placeholder acceptable en V0 |
| `yarn_mael_mission` | Maël explique la mission (brume, phare, port) | Oui (accepter / demander plus) | accept_mission | NS-GS-08 | Texte placeholder acceptable |
| `yarn_mael_encouragement` | Maël encourage le joueur (re-parle après starter, avant combat) | Non | — | NS-GS-08 | Texte court placeholder |
| `yarn_mael_post_rival` | Maël réagit au résultat du combat rival | Non | — | NS-GS-08 | Conditionnel : victory vs defeat. Placeholder acceptable |
| `yarn_rival_intro` | Lysa se présente et provoque le joueur | Non | — | NS-GS-09 | Texte placeholder acceptable |
| `yarn_rival_after_win` | Lysa réagit après défaite (joueur gagne) | Non | — | NS-GS-09 | Texte placeholder acceptable |
| `yarn_rival_after_loss` | Lysa réagit après victoire (joueur perd) | Non | — | NS-GS-09 | Texte placeholder acceptable |
| `yarn_soline_port_idle` | Soline dit un dialogue simple | Non | — | NS-GS-09 | Texte placeholder — figurante |

---

## 16. Inventaire RuntimeCutsceneAssets / Cinematics

| Cinematic id | Déclenchée par | Steps minimaux | Lot | Notes |
|---|---|---|---|---|
| `cinematic_starter_received` | scene_mael_intro après givePokemon | ShowMessage "[Joueur] reçoit [Starter] !" + Wait | NS-GS-08 | Peut être un simple `showMessage` dans le ScenarioAsset au lieu d'une cutscene dédiée |
| `cinematic_rival_approach` | scene_rival_meet avant combat | FaceNpc, Wait, MoveNpc (Lysa s'approche) | NS-GS-09 | Optionnel en V0 — peut être remplacé par faceCharacter |
| `cinematic_rival_depart_win` | scene_rival_meet branch victory | MoveNpc (Lysa s'éloigne), ShowMessage | NS-GS-09 | Optionnel en V0 — peut être un simple dialogue |
| `cinematic_rival_depart_loss` | scene_rival_meet branch defeat | ShowMessage | NS-GS-09 | Optionnel en V0 — peut être un simple dialogue |

> [!NOTE]
> En V0, la plupart des cinematics peuvent être remplacées par des actions ScenarioAsset simples :
> `showMessage` + `faceCharacter` + `moveCharacter`. Le RuntimeCutsceneAsset est disponible
> pour des séquences plus complexes, mais pas obligatoire pour le GS V0.

---

## 17. Inventaire trainer et battle Lysa

| Élément | ID | Valeur proposée | Statut | Lot | Notes |
|---|---|---|---|---|---|
| Trainer id | `trainer_lysa_port` | — | À créer | NS-GS-11 | Doit être dans le ProjectManifest |
| Battle id | `battle_rival_port` | — | À créer | NS-GS-11 | Utilisé par `scenarioBattleOutcomeFlagName` |
| npcEntityId | `entity_lysa_port` | — | Référencé | NS-GS-11 | Lié à l'entité NPC |
| Trainer name | `Lysa` | — | À définir | NS-GS-11 | Nom affiché en combat |
| Trainer class | `Rivale` ou `Rival` | — | À définir | NS-GS-11 | Classe affichée |
| Team Pokémon | **candidat** `sparkitten` | L5, tackle+growl | **Candidat** | NS-GS-11 | **Confirmable par l'utilisateur** |
| Battle difficulty | 4 (par ex.) | — | À définir | NS-GS-11 | Recommandation |
| Battle background | Placeholder ou `trainer_rookie.png` existant | — | À définir | NS-GS-11 | Asset existant dans GBS réutilisable |
| Victory outcome flag | `battle:battle_rival_port:victory` | Auto-généré | Existant (runtime) | NS-GS-11 | Via `scenarioBattleOutcomeFlagName` |
| Defeat outcome flag | `battle:battle_rival_port:defeat` | Auto-généré | Existant (runtime) | NS-GS-11 | Via `scenarioBattleOutcomeFlagName` |
| Flee outcome flag | `battle:battle_rival_port:flee` | Auto-généré | Existant (runtime) | NS-GS-11 | Décision ouverte : interdit ou defeat-like |
| Victory text | Placeholder | — | À rédiger | NS-GS-11 | Texte placeholder acceptable |
| Defeat text | Placeholder | — | À rédiger | NS-GS-11 | Texte placeholder acceptable |

> [!IMPORTANT]
> `sparkitten` est une recommandation technique actuelle, pas une décision utilisateur irréversible.

---

## 18. Inventaire assets visuels nécessaires

| Asset | Usage | Obligatoire GS V0 ? | Placeholder accepté ? | Lot | Notes |
|---|---|---|---|---|---|
| Sprite Maël (overworld) | NPC overworld | Oui | Oui (sprite NPC générique) | NS-GS-08 | Peut utiliser un sprite existant du projet |
| Sprite Lysa (overworld) | NPC overworld | Oui | Oui (sprite NPC générique) | NS-GS-09 | Peut utiliser un sprite existant |
| Sprite Soline (overworld) | NPC overworld | Oui | Oui (sprite NPC générique) | NS-GS-09 | Figurante — placeholder suffit |
| Sprite joueur (overworld) | Personnage joueur | Oui | Oui (sprite existant) | NS-GS-05 | Le runtime a probablement un sprite joueur par défaut |
| Battle sprite sproutle (front/back) | Combat | Oui | Oui si sprite déjà existant dans GBS | NS-GS-11 | Pas de sprite dans GBS actuellement ; le battle peut utiliser un placeholder |
| Battle sprite sparkitten (front/back) | Combat | Oui | Oui si sprite déjà existant dans GBS | NS-GS-11 | Même remarque |
| Tileset Bourg | Map auteur | Oui | Oui (tileset basique) | NS-GS-08 | Peut utiliser un tileset existant du projet |
| Tileset Port | Map auteur | Oui | Oui (tileset basique) | NS-GS-09 | Peut utiliser un tileset existant |
| Battle background | Fond de combat | Oui | Oui (`trainer_rookie.png` existant dans GBS) | NS-GS-11 | Réutilisable |
| UI notification "reçu Pokémon" | Notification in-game | Non | Oui (showMessage suffit) | post-GS | V0 utilise showMessage |
| Emotes NPC | Bulles d'exclamation | Non | Non nécessaire en V0 | post-GS | Polish |

---

## 19. Inventaire save/load et fixtures de test

| Fixture / test data | Rôle | Contenu attendu | Lot | Notes |
|---|---|---|---|---|
| `selbrume_initial_save.json` | État initial New Game | Party vide, bag vide, currentMapId = map_bourg_selbrume, flags vides | NS-GS-05 | Fixture de départ |
| `selbrume_after_mael.json` | État après Maël | Party = [starterCandidate L5], fact_starter_received, fact_mission_started | NS-GS-12 | Fixture de test intermédiaire |
| `selbrume_after_victory.json` | État après victoire Lysa | Party = [starterCandidate], fact_rival_defeated, fact_rival_battle_done, battle:battle_rival_port:victory | NS-GS-12 | Fixture de test victory |
| `selbrume_after_defeat.json` | État après défaite Lysa | Party = [starterCandidate], fact_rival_lost, fact_rival_battle_done, battle:battle_rival_port:defeat | NS-GS-12 | Fixture de test defeat |
| Test: save → reload → identique | Cycle save/load du starter reçu | Party inchangée, flags inchangés, position inchangée | NS-GS-12 | Smoke test obligatoire |

> [!NOTE]
> Ces fixtures ne doivent PAS être créées maintenant. Elles sont listées ici pour que NS-GS-12 sache quoi produire.

---

## 20. Matrice de dépendances

| Élément | Dépend de | Bloque | Lot créateur | Lot validateur |
|---|---|---|---|---|
| GameState initial (party vide) | — | GivePokemon, scene_mael_intro, smoke test | NS-GS-05 | NS-GS-12 |
| GivePokemon mutation | PlayerPokemon modèle (existe) | scene_mael_intro | NS-GS-06 | NS-GS-12 |
| kScenarioActionGivePokemon ou runScript | GivePokemon mutation | scene_mael_intro | NS-GS-06 | NS-GS-08 |
| fact_starter_received | GivePokemon, scene_mael_intro | World rules Maël, event anti-redon | NS-GS-08 | NS-GS-12 |
| map_bourg_selbrume | — | Spawn, Maël, warp vers Port | NS-GS-08 | NS-GS-12 |
| map_port_brisants | map_bourg_selbrume (warp) | Lysa, combat, warp retour | NS-GS-09 | NS-GS-12 |
| scene_mael_intro | GivePokemon (NS-GS-06), map_bourg_selbrume (NS-GS-08) | scene_rival_meet (fact_mission_started) | NS-GS-08 | NS-GS-12 |
| scene_rival_meet | scene_mael_intro (fact_mission_started), trainer_lysa_port (NS-GS-11) | smoke test | NS-GS-09 | NS-GS-12 |
| trainer_lysa_port | ProjectManifest (NS-GS-11), species sparkitten (existe) | startTrainerBattle | NS-GS-11 | NS-GS-12 |
| battle_rival_port | trainer_lysa_port | battle outcome flags | NS-GS-11 | NS-GS-12 |
| Save/load starter reçu | GivePokemon, SaveData sérialisation (existe) | smoke test | NS-GS-06 | NS-GS-12 |
| Story steps | scene_mael_intro, scene_rival_meet | World rules, chapter completion | NS-GS-10 | NS-GS-12 |
| World rules | story steps, facts | NPC visibility, conditional dialogues | NS-GS-10 | NS-GS-12 |

---

## 21. Ordre de création recommandé

```text
1. NS-GS-05 — New Game Minimal Runtime
   - Crée : GameState initial (party vide, bag vide, currentMapId, saveId)
   - Consomme : rien (premier lot code)
   - Débloque : NS-GS-06 (party vide à remplir)

2. NS-GS-06 — GivePokemon Minimal
   - Crée : mutation addPartyMember/givePokemon, action ScenarioAsset, tests
   - Consomme : NS-GS-05 (party vide)
   - Débloque : NS-GS-08 (scene_mael_intro peut donner le starter)

3. NS-GS-08 — Bourg Selbrume / Maël Content
   - Crée : map_bourg_selbrume, entity_mael_bourg, scene_mael_intro, yarns Maël, warp vers Port
   - Consomme : NS-GS-05 (spawn), NS-GS-06 (givePokemon)
   - Débloque : NS-GS-09 (le joueur peut aller au Port)

4. NS-GS-09 — Port Brisants / Lysa Content
   - Crée : map_port_brisants, entity_lysa_port, entity_soline_port, scene_rival_meet, yarns rivale, warp retour
   - Consomme : NS-GS-08 (warp, fact_mission_started)
   - Débloque : NS-GS-11 (le combat peut être câblé)

5. NS-GS-10 — Storyline / Chapter / Steps / World Rules
   - Crée : story_main_brume_phare, chapter_1_port, steps, world rules, conditional dialogues
   - Consomme : NS-GS-08 + NS-GS-09 (facts, NPCs)
   - Débloque : NS-GS-12 (les world rules sont vérifiables)

6. NS-GS-11 — Battle Lysa Authoring Fixture
   - Crée : trainer_lysa_port, battle_rival_port dans ProjectManifest, team sparkitten, textes combat
   - Consomme : NS-GS-09 (entity_lysa_port)
   - Débloque : NS-GS-12 (le combat est jouable)

7. NS-GS-12 — Golden Slice Smoke Test
   - Crée : fixtures de test, script de smoke test
   - Consomme : TOUT (NS-GS-05..11)
   - Débloque : Golden Slice V0 prouvé
```

---

## 22. Hors scope explicite

```text
Choix complet de starter (3 starters, UI sélection)
Pokédex complet
XP / level-up avancé
Évolutions
PC / boxes
Shop / marchand
Heal center
Wild encounters
Système de capture
Système d'échange Pokémon
Marais Salants (map_marais_salants)
Bois de la Chaise-Brume (map_bois_chaise_brume)
Passage des Dames (map_passage_dames)
Phare extérieur, intérieur, sommet
Cabane du gardien
Boss final
Quêtes annexes
Validator narratif complet
Éditeur visuel complet Narrative Studio
Badges
Money / économie
Field moves (Surf, Cut, etc.)
Deuxième chapter / storyline
```

---

## 23. Risques et garde-fous

| Risque | Impact | Garde-fou | Lot concerné |
|---|---|---|---|
| GivePokemon trop large (système complet) | Fort — sur-ingénierie | NS-GS-06 limité : 1 Pokémon, 1 donneur, pas d'UI riche | NS-GS-06 |
| Starter donné deux fois | Fort — Pokémon dupliqué | Flag fact_starter_received + condition anti-redon dans scénario | NS-GS-06, NS-GS-08 |
| Party vide au moment du combat | Fort — crash | World rule : Lysa invisible si fact_starter_received absent ; smoke test | NS-GS-10, NS-GS-12 |
| Species id candidat non présent dans le projet final | Moyen — combat crash | Vérifier que le projet Selbrume contient les species JSON | NS-GS-08, NS-GS-11 |
| sproutle choisi sans validation utilisateur finale | Faible — mauvais starter | sproutle est marqué candidat, pas irréversible | NS-GS-08 |
| sparkitten choisi sans validation utilisateur finale | Faible — mauvais rival Pokémon | sparkitten est marqué candidat, pas irréversible | NS-GS-11 |
| Dialogue Maël ambigu (confusion Maël = joueur) | Moyen — mauvaise compréhension | NS-GS-08 doit rédiger "Maël dit X au joueur", jamais "Maël fait X" | NS-GS-08 |
| Confusion Maël/joueur dans les lots | Moyen | Vocabulaire strict : "le joueur parle à Maël", "Maël donne le starter au joueur" | Tous |
| Fixtures créées avant inventaire validé | Moyen — rework | NS-GS-03 doit être validé avant NS-GS-05 | NS-GS-03 |
| Smoke test incomplet | Fort — faux positif | NS-GS-04 définit la stratégie ; NS-GS-12 l'exécute | NS-GS-04, NS-GS-12 |
| Save/load corrompt le starter reçu | Fort | Test obligatoire save → reload → party identique | NS-GS-06, NS-GS-12 |

---

## 24. Décisions ouvertes pour l'utilisateur

| Décision | Options | Recommandation actuelle | À trancher avant quel lot |
|---|---|---|---|
| Starter final | sproutle, ou un autre species (squirtle, bulbasaur, custom Selbrume) | `sproutle` (candidat technique) | NS-GS-08 |
| Pokémon de Lysa final | sparkitten, ou un autre species | `sparkitten` (candidat technique) | NS-GS-11 |
| Nom affiché du joueur | "Joueur", configurable, ou prénom fixe | "Joueur" (placeholder) | NS-GS-05 |
| Nom affiché du starter si custom | Nom espèce, ou surnom | Nom espèce (pas de surnom en V0) | NS-GS-08 |
| Ton exact du dialogue Maël | Bienveillant, mystérieux, pressé | Bienveillant + légèrement pressé | NS-GS-08 |
| Défaite contre Lysa : continuation ou rematch | Le jeu continue après défaite (Lysa s'éloigne) OU le joueur peut re-combattre | Continuation (la défaite est un outcome valide, le jeu continue) | NS-GS-09 |
| Fuite en combat rival | Interdit (fuite bloquée) OU defeat-like (fuite = défaite) | Interdit ou defeat-like — pas de branche "flee" distincte | NS-GS-11 |
| Soline : figurante ou première world rule post-rival | Simple dialogue idle OU dialogue qui change après le combat | Figurante simple (dialogue fixe) en V0 | NS-GS-09 |
| Granularité des story steps | 1 step (intro_selbrume tout-en-un) OU 3 steps séparés (starter, mission, go_to_port) | 3 steps séparés (meilleure traçabilité pour world rules) | NS-GS-10 |

---

## 25. Recommandation finale

```text
NS-GS-03 ne crée rien.
NS-GS-03 donne l'inventaire officiel du Golden Slice Selbrume V0.

L'inventaire couvre :
- 2 maps (Bourg Selbrume, Port Brisants)
- 3 NPCs (Maël, Lysa, Soline)
- 7 entities
- 6 events / triggers
- 1 storyline, 1 chapter, 5 steps
- 11 facts / flags / outcomes
- 7 world rules
- 2 ScenarioAssets
- 8 Yarn dialogues
- 4 cinematics (optionnelles en V0)
- 1 trainer + 1 battle
- ~11 assets visuels (placeholders acceptés)
- 5 fixtures de test

Après review de ce rapport, le prochain lot est :
NS-GS-04 — Runtime Smoke Strategy

NS-GS-04 utilisera cet inventaire pour définir quels tests doivent prouver le Golden Slice.
On ne passe PAS directement à NS-GS-05.
La roadmap impose NS-GS-04 avant le code.
```

---

## 26. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre — aucun fichier modifié ou untracked pertinent)
```

### Fichier créé

```text
reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md
```

### Commandes de lecture exécutées

```bash
git status --short --untracked-files=all
rg "MapEventDefinition|MapEntityNpcVisibilityRule|ScenarioAsset|RuntimeCutsceneAsset" packages/map_core/lib --type dart -l
rg "startTrainerBattle|ScenarioRuntimeEffectType|dispatchContinuation" packages/map_runtime/lib --type dart -l
rg "kScenarioAction*" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
rg "scenarioBattleOutcome" packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
rg "class PlayerProgression|storyFlags|completedStepIds" packages/map_core/lib/src/models/save_data.dart
rg "class GameState|@Default" packages/map_core/lib/src/models/game_state.dart
rg "Bag|BagEntry" packages/map_core/lib/src/models/save_data.dart
rg "defeatedTrainerIds|trainersDefeated" packages/map_core/lib/src/models/ --type dart
rg "MapEntityConditionalDialogue|MapEntityNpcVisibilityRule|MapEntityRuntimePredicate" packages/map_core/lib/src/models/map_entity_payloads.dart
rg "class RuntimeCutsceneAsset|CutsceneStep" packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
rg "StepStudioWorldPresenceRuleKind" packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
rg "GlobalStoryChapterStepIndex" packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
find . -path "*/golden_battle_slice/*"
find . -path "*/map_bourg*" -o -path "*/selbrume*" -o -path "*/port_brisants*"
```

### Git status/diff final

```bash
$ git diff --check
(sortie vide — pas de whitespace errors)
EXIT:0

$ git diff --stat
(sortie vide — le fichier est untracked, pas staged)

$ git diff --name-only
(sortie vide — pas de fichier tracked modifié)

$ git status --short --untracked-files=all
?? reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md
```

### Confirmations

```text
Un seul fichier créé : reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md
Aucun code modifié.
Aucune fixture modifiée.
Aucun test modifié.
Aucun build_runner lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 27. Auto-review

| Question | Réponse |
|---|---|
| Le rapport est-il exhaustif ? | ✅ 2 maps, 3 NPCs, 7 entities, 6 events, 5 steps, 11 facts, 7 world rules, 2 scénarios, 8 yarns, 4 cinematics, 1 trainer/battle, ~11 assets, 5 fixtures |
| Le lot reste-t-il documentaire ? | ✅ Un seul fichier MD créé, aucun code |
| Maël est-il bien traité comme PNJ et non comme joueur ? | ✅ "le joueur parle à Maël", "Maël donne le starter au joueur" |
| La décision GivePokemon est-elle correctement propagée ? | ✅ NS-GS-06 obligatoire, party initiale vide, scene_mael_intro utilise givePokemon |
| Sproutle est-il bien marqué comme candidat/recommandation ? | ✅ Marqué `starterCandidate` / "recommandation technique actuelle" partout |
| Sparkitten est-il bien marqué comme candidat/recommandation ? | ✅ Marqué "candidat technique" / "confirmable par l'utilisateur" |
| Chaque élément a-t-il un lot responsable ? | ✅ Colonne `Lot` dans chaque tableau |
| NS-GS-04 sait-il quoi utiliser pour sa stratégie de test ? | ✅ Inventaire complet, matrice de dépendances, fixtures de test listées |
| Y a-t-il une dette restante ? | ⚠️ Décisions ouvertes pour l'utilisateur (§24) — à trancher avant les lots concernés |

---

*Fin du document NS-GS-03.*

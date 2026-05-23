# SEL-A1 — Glossaire narratif canonique PokeMap

**Date** : 2026-05-23
**Repo** : `/Users/karim/Project/pokemonProject`
**Lot** : SEL-A1 (Phase A — Clarification avant tout code)
**Auteur** : Audit automatisé
**Aucun code modifié.**

---

## 1. Objectif de ce document

Ce document fixe le vocabulaire narratif de PokeMap pour le scénario Selbrume et le futur Narrative Studio.

Il répond à cette question :

> Comment définir proprement les concepts narratifs de PokeMap pour que le scénario Selbrume puisse être construit progressivement sans refactor massif, sans exposer les flags techniques, et sans mélanger Scenario, Scene, Cutscene, Script, Step et Event ?

Chaque concept est défini avec :

- **Nom canonique** = le nom que l'auteur voit dans l'éditeur
- **Rôle** = ce que ce concept fait dans le système
- **Ce que ce n'est pas** = frontière explicite avec les autres concepts
- **État dans le repo** = ce qui existe concrètement aujourd'hui
- **Écart avec la vision** = ce qui manque pour atteindre la cible `narrative_studio.md`

---

## 2. Sources produit fournies par l'utilisateur

### narrative_studio.md

- **Rôle** : Document de vision produit. Décrit le modèle mental cible du Narrative Studio, ses concepts, ses écrans, ses règles non négociables, et la roadmap N0→N13.
- **Contenu utile retenu** :
  - 10 concepts canoniques : Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule, Validator
  - Séparation stricte Scene (graph) vs Cinematic (linéaire)
  - Séparation Event (déclencheur) vs Scene (orchestration)
  - Yarn produit des outcomes, pas la progression
  - Facts = UX humaine sur les flags techniques
  - World Rules = changements visuels du monde conditionnés par Facts/Steps
  - 11 écrans UI cible (Overview → Validator)
  - Phrase canonique : "Quand [déclencheur] Si [conditions] Alors [actions] Puis [conséquences]"
  - Règles non négociables (§21, 10 points)
- **Décisions retenues** :
  - Le glossaire ci-dessous reprend les 10 concepts cibles de `narrative_studio.md` comme noms canoniques
  - La séparation Event/Scene/Cinematic est la structure mentale officielle
  - Le terme "Scenario" (actuel) n'est PAS un concept cible — il sera mappé progressivement

### selbrume.md

- **Rôle** : Scénario de référence canonique. Mini-jeu complet (2-3h) qui teste toute la grammaire narrative.
- **Contenu utile retenu** :
  - 9 zones, 6 personnages, 4 chapitres, 12 story steps
  - 3 quêtes annexes (cristaux, Goélise, cabane)
  - ~20 events détaillés avec trigger/conditions/actions/facts
  - ~10 scenes avec nodes graphés
  - ~14 cinématiques linéaires
  - ~8 dialogues Yarn avec outcomes
  - ~35 facts nommés
  - ~15 world rules
  - 3 combats (rival, donjon, boss)
  - Golden slice cible : parler à Lysa → Event → Scene → Yarn → Cinematic → Combat → Fact → Step → World Rule → Validator
- **Décisions retenues** :
  - Le Golden Slice est le combat rival au port (pas l'intro Maël)
  - Les facts sont nommés humainement (`fact_rival_port_defeated`), pas en flags bruts
  - Les configurations A (starter) et B (pokémon existant) doivent être supportées

### Comment ces fichiers influencent le glossaire

Les concepts canoniques ci-dessous sont alignés sur `narrative_studio.md` §3-§12. Les exemples sont tirés de `selbrume.md`. Le mapping vers le repo est fait par inspection fraîche du code (voir SEL-000-bis).

### Ce qui reste à vérifier dans le code réel

| Vérification | Raison |
|---|---|
| Runtime item pickup flow | Tests map_runtime bloqués par `swiftly` build hook |
| Step completion depuis flag (pas cutscene) | Seul mode `whenCutsceneEnds` confirmé |
| Activation condition sur ScenarioAsset en runtime | Existe dans le modèle, non testé runtime |
| Trigger zone conditionnel (passage bloqué) | Non testé runtime |

---

## 3. Les 10 concepts canoniques

---

### 3.1 Storyline

| Aspect | Définition |
|---|---|
| **Nom canonique** | Storyline |
| **Ancien nom repo** | `ScenarioAsset` (scope: `globalStory`) |
| **Rôle** | Une ligne narrative complète : histoire principale, quête annexe, tutoriel, épilogue |
| **Contient** | Chapters → Story Steps |
| **Ce que ce n'est pas** | Pas une scène. Pas un event. Pas un conteneur de tout. |
| **Exemples Selbrume** | `story_main_brume_phare`, `story_side_salt_crystals`, `story_side_goelise_port`, `story_side_lighthouse_cabin` |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| Modèle `ScenarioAsset` avec `scope: globalStory` | ✅ | [scenario_asset.dart:21](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L21) |
| Concept "Storyline" nommé explicitement | ❌ | Grep `Storyline` → 0 résultats dans `map_core` |
| Type secondaire (side quest, tutoriel) | ❌ | Pas de champ `storylineType` sur `ScenarioAsset` |
| `activationCondition` (condition de disponibilité) | ✅ | [scenario_asset.dart:38](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L38) |
| Éditeur Global Story Studio | ✅ | [global_story_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) |
| Storylines Board (plusieurs storylines) | ❌ | Le Studio est un seul graphe, pas un tableau de storylines |

#### Écart

Le concept existe techniquement via `ScenarioAsset(scope: globalStory)`, mais **le nom Storyline n'apparaît nulle part**. L'éditeur montre un seul graphe "Global Story", pas un tableau de storylines. Il n'y a pas de notion de type (main/side/tutorial). Pour Selbrume, les 4 storylines (1 main + 3 sides) ne peuvent pas coexister dans l'UI actuelle de façon structurée.

#### Recommandation V0

- Renommer conceptuellement `ScenarioAsset(scope: globalStory)` en "Storyline" dans la doc et l'UI
- Ajouter un champ optionnel `storylineType` (`main`, `sideQuest`, `tutorial`, `epilogue`) — modèle seulement
- L'éditeur Global Story Studio devient le "Storyline Graph" pour UNE storyline
- Un "Storylines Board" est un écran de liste (pas un graphe)

---

### 3.2 Chapter

| Aspect | Définition |
|---|---|
| **Nom canonique** | Chapter |
| **Ancien nom repo** | Metadata JSON dans `kGlobalStoryStudioDocumentMetadataKey` |
| **Rôle** | Organise une Storyline en grands moments narratifs |
| **Contient** | Story Steps |
| **Ce que ce n'est pas** | Pas une scène. Pas un conteneur de logique. Un outil d'organisation. |
| **Exemples Selbrume** | `chapter_1_port`, `chapter_2_marais`, `chapter_3_phare`, `chapter_4_epilogue` |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| Concept "Chapter" dans le runtime | ✅ | [global_story_chapter_runtime.dart:11-63](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart#L11-L63) — `kGlobalStoryStudioDocumentMetadataKey` |
| Modèle typé `Chapter` dans `map_core` | ❌ | Pas de `class Chapter` — stocké en JSON dans `ScenarioAsset.metadata` |
| Predicate `chapterCompleted` / `chapterNotCompleted` | ✅ | [map_entity_payloads.dart:63-68](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L63-L68) |
| Editor UI chapitres | ✅ | Global Story Studio affiche des chapitres (via metadata) |

#### Écart

Le chapitre existe en tant que concept runtime et éditeur, mais son modèle est **stocké en JSON brut non typé** dans `ScenarioAsset.metadata`. Il n'y a pas de `class Chapter` dans `map_core`. Les predicates `chapterCompleted`/`chapterNotCompleted` existent pour la visibilité NPC, ce qui confirme que le concept est actif côté gameplay.

#### Recommandation V0

- Acceptable pour le Golden Slice tel quel (le runtime fonctionne)
- Typer `Chapter` dans `map_core` après le GS si le metadata JSON devient un problème

---

### 3.3 Story Step

| Aspect | Définition |
|---|---|
| **Nom canonique** | Story Step |
| **Ancien nom repo** | Step Studio (`kStepStudioDocumentMetadataKey`) + `completedStepIds` |
| **Rôle** | Jalon logique de progression : "Où en est le joueur ?" |
| **Ce que ce n'est pas** | Pas une scène. Pas une cinématique. Pas un event. Un marqueur de progression. |
| **États V0** | Inactive, Active, Completed |
| **États futurs** | Failed, Skipped, Locked, Optional |
| **Exemples Selbrume** | `step_intro_selbrume`, `step_go_to_port`, `step_rival_battle`, `step_find_three_clues` |

#### Ce qu'une Step doit pouvoir avoir (vision narrative_studio.md)

```text
conditions d'activation → quand la step devient Active
conditions de complétion → quand la step devient Completed
events liés → quels events de map sont associés
scènes liées → quelles scenes sont jouées pendant cette step
facts produits → quels facts sont posés quand la step est completed
world rules associées → quels changements du monde cette step provoque
quêtes débloquées → quelles storylines secondaires deviennent disponibles
```

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `completedStepIds` dans `PlayerProgression` | ✅ | [save_data.dart:202](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L202) |
| Step completion runtime | ✅ | [step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart) |
| Predicate `stepCompleted` / `stepNotCompleted` | ✅ | [map_entity_payloads.dart:59-62](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L59-L62) |
| Step modèle typé dans `map_core` | ❌ | Stocké en JSON dans `ScenarioAsset.metadata` |
| Modes de complétion | 🟡 | Seul `whenCutsceneEnds` existe |
| Step activation automatique | ❌ | Pas de `ActivateStep` dans les commandes |
| Conditions d'activation sur Step | ❌ | Les steps n'ont pas de condition propre |

#### Écart

Les steps fonctionnent comme marqueurs de progression (completed ✅), mais :

1. Pas de modèle typé `StoryStep` dans `map_core` — JSON dans metadata
2. Pas de concept d'**activation** de step (seul le completion fonctionne)
3. Pas de complétion par flag/fact — uniquement par fin de cutscene
4. `selbrume.md` demande `Activate Step step_enter_marais` dans les actions d'event → **le verbe "Activate" n'existe pas**
5. `selbrume.md` demande `Complete Step step_rival_battle` après combat → **le verbe "Complete" n'existe que via cutsceneEnds**

#### Recommandation V0

- Ajouter un `ScriptCommandType.completeStep` (mutation directe, pas via cutscene)
- Ajouter un `ScriptCommandType.activateStep` (pose un flag d'activation)
- L'état Active/Inactive peut être dérivé d'un flag `step_<id>_active` pour le V0
- Repousser le modèle typé `StoryStep` à après le GS

---

### 3.4 Event

| Aspect | Définition |
|---|---|
| **Nom canonique** | Event |
| **Ancien nom repo** | `MapEventDefinition` (partiel) + `ScenarioAsset(scope: localEventFlow)` (partiel) |
| **Rôle** | Règle de déclenchement locale. Quand + Si → Alors + Puis |
| **Attaché à** | Un PNJ, une zone, un objet, une porte, un coffre, un dresseur |
| **Ce que ce n'est pas** | Pas une scène (Event = pourquoi/quand. Scene = ce qui se déroule). |
| **Exemples Selbrume** | `event_mael_intro`, `event_enter_port_alert`, `event_rival_port_meet`, `event_soline_unlock_passage` |

#### Structure d'un Event (vision narrative_studio.md §7 + §18.9)

```text
Déclencheur : interact / enter_zone / inspect / battle_won / collect
Conditions  : Step active + Fact vrai/faux
Actions     : Play Scene / Launch Battle / SetFact / GivePokemon / GiveItem
Récompenses : XP / Argent / Objet
Changements : Fact posé / Step activée / World Rule appliquée
Comportement: une seule fois / réinitialisable
```

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `MapEventDefinition` (pages conditionnelles) | ✅ | [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) — 162 lignes |
| `ScenarioAsset(scope: localEventFlow)` | ✅ | Graphe pour event flows locaux |
| Trigger `entityInteract` dans runtime | ✅ | [scenario_runtime_executor.dart:14](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L14) |
| Trigger `enterZone` dans runtime | ✅ | [scenario_runtime_executor.dart:83-97](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L83-L97) |
| Event Builder UI | ❌ | Grep `EventBuilder` → 0 résultats |
| Event as structured rules (Quand/Si/Alors/Puis) | ❌ | L'event est un graphe libre, pas un formulaire |
| Post-event actions (SetFact, CompleteStep, GiveItem) | 🟡 | `SetFlag` ✅, `CompleteStep` ❌, `GivePokemon` ❌ |
| Event attaché à un élément de map | 🟡 | MapEntity a `ScriptRef`, pas `EventRef` explicite |

#### Écart majeur

**Le concept Event au sens `narrative_studio.md` n'existe pas en tant qu'entité unifiée.**

Le repo a deux systèmes partiels :
- `MapEventDefinition` : pages conditionnelles avec ScriptRef, orienté RMXP-style
- `ScenarioAsset(scope: localEventFlow)` : graphe de nodes pour event flows

Aucun des deux ne correspond au concept cible Event = règle structurée "Quand/Si/Alors/Puis" de `narrative_studio.md` §7. Le concept cible est plus proche d'un formulaire de blocs que d'un graphe.

**Mais pour le Golden Slice**, la combinaison existante (`MapEventDefinition` pages + `ScenarioAsset` localEventFlow + conditions + script commands) peut **émuler** un Event en pratique, même si l'UX n'est pas le formulaire structuré cible.

#### Recommandation V0

- **Ne pas créer un nouveau modèle `Event` pour le GS** — utiliser `MapEventDefinition` pages + `ScenarioAsset(localEventFlow)` existants
- Documenter comment émuler le pattern Event avec les outils existants
- L'Event Builder UI est un lot post-GS (lot N9 dans la roadmap `narrative_studio.md`)
- Le terme "Event" dans la doc Selbrume = conceptuel, mappé vers `MapEventDefinition` + flow scénario

---

### 3.5 Scene

| Aspect | Définition |
|---|---|
| **Nom canonique** | Scene |
| **Ancien nom repo** | `ScenarioAsset` (graphe de nodes, sans scope clair) |
| **Rôle** | Orchestration narrative en graphe. Quels dialogues, quelles branches, quelles cinématiques, quels combats, dans quel ordre. |
| **Contient** | Nodes : Start, Dialogue Yarn, Branch by outcome, Condition, Play Cinematic, Play Combat, Action, Reward, Merge, Emit Scene Outcome, End |
| **Ce que ce n'est pas** | Pas un event (Scene = ce qui se déroule. Event = quand/pourquoi). Pas une cinématique (Scene branche. Cinematic ne branche pas). |
| **Exemples Selbrume** | `scene_mael_intro`, `scene_port_alert`, `scene_rival_meet`, `scene_rival_after_win`, `scene_final_pokemon` |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `ScenarioAsset` comme graphe de nodes | ✅ | [scenario_asset.dart:39-40](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L39-L40) — `nodes` + `edges` |
| Node types (start, dialogue, action, condition, choice, reference, end) | ✅ | [scenario_asset.dart:134-148](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L134-L148) — `ScenarioNodeType` |
| Edge types (next, trueBranch, falseBranch, choice, reference) | ✅ | [scenario_asset.dart:167-178](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L167-L178) |
| Outcomes (declared + emitted) | ✅ | [scenario_asset.dart:31](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L31) + [scenario_runtime_executor.dart:638](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L638) |
| Distinction Scene vs Storyline | ❌ | Le même modèle `ScenarioAsset` sert aux deux (via `scope`) |
| Node type "Play Cinematic" | ❌ | Pas de node type `playCinematic` dans `ScenarioNodeType` |
| Node type "Play Combat" | ❌ | Pas de node type `playCombat` |
| Node type "Merge" | ❌ | Pas de merge explicite (les edges convergent implicitement) |
| Scene Builder UI (graphe dédié) | ❌ | Le graphe est partagé avec Global Story |

#### Écart majeur

**Le concept Scene au sens `narrative_studio.md` est partiellement couvert par `ScenarioAsset`**, mais avec plusieurs faiblesses :

1. `ScenarioAsset` est utilisé à la fois pour Storyline (globalStory) et pour Scene/Event (localEventFlow). Ce n'est pas grave structurellement (le graphe est le même), mais conceptuellement c'est ambigu pour l'auteur.
2. Les node types manquent les actions clés de Selbrume : `playCinematic`, `playCombat`, `reward`, `merge`.
3. Les node types existants (`dialogue`, `action`, `condition`, `choice`) couvrent la mécanique de base mais pas le vocabulaire riche de `narrative_studio.md` §18.5.

#### Recommandation V0

- **Réutiliser `ScenarioAsset(scope: localEventFlow)` comme "Scene"** pour le GS
- Le graphe existant avec `dialogue → condition → choice → action → end` peut émuler les scenes de Selbrume
- `playCinematic` peut être émulé via un node `action` avec `actionKind = "playCinematic"` + `params.cinematicId`
- `playCombat` nécessite un nouveau mécanisme (voir BLK-1 du SEL-000-bis)
- `merge` est implicite via la convergence d'edges vers un même node
- Le Scene Builder UI est un lot post-GS

---

### 3.6 Cinematic

| Aspect | Définition |
|---|---|
| **Nom canonique** | Cinematic |
| **Ancien nom repo** | `RuntimeCutsceneAsset` + `CutsceneRuntimeRunner` |
| **Rôle** | Séquence linéaire jouée à l'écran. Mise en scène, chorégraphie, pas de branches. |
| **Contient** | Steps linéaires : camera, move NPC, emote, dialogue, wait, fade, sound, FX |
| **Ce que ce n'est pas** | Pas une scène (Cinematic ne branche PAS). Pas un event. Pas un script. |
| **Exemples Selbrume** | `cinematic_port_panic`, `cinematic_rival_smiles`, `cinematic_passage_revealed`, `cinematic_mist_disperses` |

#### Règle canonique (narrative_studio.md §9)

```text
Scene = cerveau d'orchestration → peut brancher
Cinematic = chorégraphe visuel → linéaire uniquement
```

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `RuntimeCutsceneAsset` (modèle) | ✅ | [cutscene_runtime_models.dart:1-313](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart#L1-L313) — 17 step types |
| `CutsceneRuntimeRunner` (exécution) | ✅ | [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart) — 801 lignes |
| Step types (dialogue, moveNpc, wait, fadeIn/Out, emote, playSound, cameraMove) | ✅ | 17 types dans l'enum |
| Step type `CutsceneChoiceStep` (branche dans la cinématique !) | ⚠️ | Existe mais **viole la règle** "pas de branches dans les cinématiques" |
| Cutscene Studio (éditeur) | ✅ | [cutscene_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) |
| Cutscene step `startBattle` | ❌ | BLK-1 confirmé dans SEL-000-bis |
| Cutscene step `givePokemon` | ❌ | Aucun step gameplay |
| Cinematic Builder V2 (storyboard/timeline/blocking) | ❌ | L'éditeur actuel est un Step Editor, pas un timeline builder |

#### Écart notable

1. **Le terme "Cutscene" du repo = "Cinematic" de la vision** — renommage conceptuel nécessaire dans la doc
2. **`CutsceneChoiceStep` viole la règle "pas de branches dans les cinématiques"** — mais en pratique c'est un choix dialogue inline, pas un branchement narratif. Pour le V0, c'est acceptable si on documente que les choix narratifs (Yarn outcomes) passent par la Scene, et les choix dialogue inline (2-3 réponses) peuvent rester dans la cinématique comme raccourci.
3. **Pas de step gameplay** dans les cinématiques : pas de `startBattle`, `givePokemon`, `healParty`, `giveItem`. C'est le blocage central BLK-1.

#### Recommandation V0

- Accepter le renommage conceptuel : `RuntimeCutsceneAsset` = "Cinematic" dans la doc utilisateur
- Garder `CutsceneChoiceStep` comme raccourci pour choix dialogue inline, mais documenter que les vrais branchements narratifs passent par la Scene
- Ajouter `CutsceneStartBattleStep` (BLK-1) — nécessaire pour le GS
- Le Cinematic Builder V2 (timeline/storyboard) est post-GS (lot N8)

---

### 3.7 Dialogue Yarn

| Aspect | Définition |
|---|---|
| **Nom canonique** | Dialogue Yarn |
| **Ancien nom repo** | `DialogueRef` + `YarnDialogueRef` + `parseYarnFile` |
| **Rôle** | Contenu dialogué avec choix et outcomes. Raconte et produit des résultats. |
| **Ce que ce n'est pas** | Pas la progression. Pas le moteur narratif. Yarn influence la Scene, pas la Storyline directement. |
| **Exemples Selbrume** | `yarn_mael_intro`, `yarn_port_alert`, `yarn_rival_intro`, `yarn_mado_intro`, `yarn_goelise_choice` |

#### Règle canonique (narrative_studio.md §10)

```text
Yarn raconte et produit des outcomes.
Scene lit les outcomes et orchestre la suite.
Event applique les conséquences persistantes.
Storyline progresse via Facts / Steps.
```

À éviter :
```text
Yarn termine directement une Story Step.
Yarn donne directement des objets.
Yarn modifie 12 flags techniques en douce.
```

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `DialogueRef` (id + script path) | ✅ | [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) |
| `parseYarnFile` parser | ✅ | [parse_yarn_dialogue.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart) — 93 lignes |
| `DialogueSession` runtime | ✅ | [dialogue_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/dialogue_runtime_models.dart) — 145 lignes |
| Dialogue conditionnel par predicate | ✅ | [map_entity_payloads.dart:102-107](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L102-L107) |
| Outcomes Yarn → Scene | ✅ | `CutsceneEmitOutcomeStep` + executor `emitOutcome` |
| Yarn side-effects (give/set/modify) | ❌ | Yarn est lecture seule — conforme à la vision ✅ |

#### Écart

Minimal. Yarn est déjà implémenté conformément à la vision : il raconte, produit des outcomes, et ne modifie pas la progression. La conformité est bonne.

#### Recommandation V0

- Rien à changer. Le dialogue Yarn fonctionne pour le GS.
- Documenter dans le guide auteur que les outcomes Yarn doivent être lus par la Scene, pas directement consommés par le runtime.

---

### 3.8 Fact

| Aspect | Définition |
|---|---|
| **Nom canonique** | Fact |
| **Ancien nom repo** | `StoryFlags.activeFlags` (Set\<String\>) |
| **Rôle** | Fait lisible du monde. L'équivalent UX d'un flag, formulé humainement. |
| **Types V0** | Booléen (vrai/faux via flag set/unset) |
| **Types futurs** | Numérique, texte, enum, compteur, collection |
| **Ce que ce n'est pas** | Pas un flag brut. L'auteur manipule "Rival battu au port", pas `flag_rival_port_defeated = true`. |
| **Exemples Selbrume** | `fact_main_story_started`, `fact_rival_port_defeated`, `fact_port_crowd_panicked`, `fact_passage_dames_unlocked`, `fact_crystal_1_collected` |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `StoryFlags(activeFlags: Set<String>)` | ✅ | `GameState` → `StoryFlags` |
| `setFlag` / `unsetFlag` mutations | ✅ | [game_state_mutations.dart:14](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart#L14) |
| `storyFlagSet` / `storyFlagUnset` predicates | ✅ | [map_entity_payloads.dart:54-57](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L54-L57) |
| Persistance dans `SaveData.PlayerProgression.storyFlags` | ✅ | [save_data.dart:201](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L201) |
| Fact Registry / Fact Browser UI | ❌ | Pas d'écran pour voir/gérer les facts |
| Fact avec label humain | ❌ | Les flags sont des strings bruts (`rival_defeated`) |
| Fact typé (booléen/compteur/enum) | ❌ | Seulement Set\<String\> (présence = vrai) |
| `ScriptVariableValue.int` (compteur) | ✅ | Existe dans `script_conditions.dart` mais pas utilisé pour les facts |

#### Écart

**Techniquement fonctionnel** : les flags marchent, sont persistés, sont évaluables, et conditionnent la visibilité NPC.

**Conceptuellement décalé** : l'auteur manipule des strings bruts (`rival_port_defeated`), pas des Fact lisibles ("Rival battu au port"). Le `narrative_studio.md` demande que l'ID technique soit caché dans une section avancée, et que l'UX montre un nom lisible.

#### Recommandation V0

- **Garder les string flags pour le GS** — c'est suffisant pour le runtime
- Nommer les flags avec la convention `fact_<slug>` pour préfigurer le modèle Fact
- L'UI Fact Browser est un lot post-GS (lot N10)
- Un modèle `FactDefinition(id, label, type, defaultValue)` dans `map_core` peut être ajouté après le GS

---

### 3.9 World Rule

| Aspect | Définition |
|---|---|
| **Nom canonique** | World Rule |
| **Ancien nom repo** | `MapEntityNpcVisibilityRule` + `MapEntityRuntimePredicateKind` + `MapEntityConditionalDialogue` |
| **Rôle** | Change l'apparence ou le comportement du monde selon des Facts / Steps / Conditions |
| **Ce que ce n'est pas** | Pas un event (pas de déclenchement). Pas un fact (pas une donnée). Une règle passive qui s'applique automatiquement. |
| **Exemples Selbrume** | "PNJ Lysa visible si fact_rival_port_defeated = false", "Passage utilisable si fact_passage_dames_unlocked = true", "Cristal disparaît si fact_crystal_1_collected = true" |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `MapEntityNpcVisibilityRule` (visible si predicate) | ✅ | [map_entity_payloads.dart:89-94](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L89-L94) |
| `MapEntityRuntimePredicateKind` (8 kinds) | ✅ | `storyFlagSet/Unset`, `stepCompleted/NotCompleted`, `chapterCompleted/NotCompleted`, `cutsceneCompleted/NotCompleted` |
| `MapEntityConditionalDialogue` (dialogue variant si fact) | ✅ | [map_entity_payloads.dart:102-107](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L102-L107) |
| Runtime evaluator | ✅ | `isNpcRuntimePresentOnMap` + `MapEntityRuntimePredicateEvaluator` |
| "World Rule" nommé explicitement | ❌ | Concept distribué en 3 mécanismes, pas unifié |
| Porte verrouillée/déverrouillée | ❌ | Pas de modèle "porte" conditionnel |
| Zone bloquée/débloquée | ❌ | Pas de modèle "zone accessible si" |
| Objet disparaît si ramassé | 🟡 | `ItemPickupMode.once` existe, mais pas lié aux facts |
| Changement visuel conditionnel (brume on/off) | ❌ | Pas de concept d'état visuel conditionnel |
| Facts & World Rules UI | ❌ | Pas d'écran dédié |

#### Écart

**Les World Rules existent en fragments fonctionnels** (NPC visibility, conditional dialogue) mais **pas comme concept unifié**. Le `narrative_studio.md` demande un écran "Facts & World Rules" qui montre des règles lisibles comme "Porte du phare utilisable si Clé obtenue". Le repo implémente cela pour les NPC et les dialogues, mais pas pour les portes, les zones, les objets ramassables, ni les changements visuels.

#### Recommandation V0

- **Utiliser les visibility rules existantes** pour le GS (NPC visible/invisible + dialogue conditionnel)
- **Émuler les passages bloqués** via un NPC bloqueur avec visibility rule (fonctionne !)
- L'écran Facts & World Rules est post-GS (lot N10)
- Le concept "porte" conditionnel peut être émulé par un panneau + visibility rule + trigger zone pour le GS

---

### 3.10 Validator

| Aspect | Définition |
|---|---|
| **Nom canonique** | Validator |
| **Ancien nom repo** | `_validateScenarios` dans `validators.dart` |
| **Rôle** | Garantit que le contenu narratif est jouable, atteignable et cohérent |
| **Exemples de détections** | Storyline sans début, Step non atteignable, Scene appelée mais inexistante, Fact jamais produit, Branch impossible |
| **Exemples Selbrume** | Vérifier que `step_rival_battle` est atteignable depuis `step_go_to_port`, que `fact_passage_dames_unlocked` est produit avant d'être lu, que `scene_rival_meet` existe quand l'event la référence |

#### État dans le repo

| Élément | Existe | Preuve |
|---|---|---|
| `_validateScenarios` | ✅ | [validators.dart:761](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart#L761) |
| `_validateMapEvent` | ✅ | [validators.dart:1802](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart#L1802) |
| `_validateDialogueFolders` | ✅ | [validators.dart:306](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart#L306) |
| `_validateScriptCondition` | ✅ | [validators.dart:967](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart#L967) |
| Reachability validator (graphe traversal) | ❌ | Grep `reachability\|unreachable\|orphan\|dangling` → 0 |
| Fact declared-but-never-produced | ❌ | Pas de cross-reference facts |
| Scene-called-but-missing | ❌ | Pas de cross-reference scenes |
| Validator UI | ❌ | Pas d'écran Validator dédié |
| Diagnostics narratifs | 🟡 | Diagnostics existants couvrent la structure (nodes, edges, conditions) mais pas la logique narrative |

#### Écart

Le repo a un validator structurel solide (1900+ lignes), mais **pas de validator narratif**. Les détections demandées par `narrative_studio.md` §18.11 (20 types de checks) sont presque toutes absentes. Seule la validation de structure (nodes/edges/outcomes) existe.

#### Recommandation V0

- Ajouter un check minimal de reachability (1 source, 1 end, pas de nœud orphelin) pour le GS
- Les 20 types de checks de `narrative_studio.md` sont un lot post-GS (lot N12)

---

## 4. Table de mapping : Concept cible → Concept repo actuel

| # | Concept cible (narrative_studio.md) | Concept repo actuel | Mapping possible V0 | Écart principal |
|---|---|---|---|---|
| 1 | **Storyline** | `ScenarioAsset(scope: globalStory)` | ✅ Direct | Pas de type main/side, pas de Storylines Board |
| 2 | **Chapter** | JSON dans `ScenarioAsset.metadata` | ✅ Direct | Pas typé dans map_core |
| 3 | **Story Step** | `completedStepIds` + Step Studio metadata | 🟡 Partial | Pas de concept Active/Inactive, completion uniquement via cutscene |
| 4 | **Event** | `MapEventDefinition` + `ScenarioAsset(localEventFlow)` | 🟡 Emulable | Pas d'entité unifiée "Event", deux systèmes partiels |
| 5 | **Scene** | `ScenarioAsset(scope: localEventFlow)` | 🟡 Emulable | Pas de node types `playCinematic`/`playCombat`, même modèle que Storyline |
| 6 | **Cinematic** | `RuntimeCutsceneAsset` + `CutsceneRuntimeRunner` | ✅ Direct | Renommage conceptuel, `CutsceneChoiceStep` viole la règle "pas de branches" |
| 7 | **Dialogue Yarn** | `DialogueRef` + `parseYarnFile` + `DialogueSession` | ✅ Conforme | — |
| 8 | **Fact** | `StoryFlags(activeFlags: Set<String>)` | 🟡 Fonctionnel | Pas de label humain, pas de types, pas de registry |
| 9 | **World Rule** | `NpcVisibilityRule` + `ConditionalDialogue` + predicates | 🟡 Fragmenté | Pas de concept unifié, pas de porte/zone/objet conditionnel |
| 10 | **Validator** | `_validateScenarios` + `_validateMapEvent` + diagnostics | 🟡 Structurel only | Pas de validator narratif (reachability, cross-ref facts, etc.) |

---

## 5. Écarts entre la vision cible et l'existant du repo

### Écart E1 — Absence du concept "Storyline" nommé

- **Vision** : Le Storylines Board montre toutes les lignes narratives (main, sides, tutorials)
- **Repo** : `ScenarioAsset(scope: globalStory)` existe mais sans nom "Storyline", sans type, sans Board
- **Impact GS** : Faible — on n'a qu'une Storyline pour le GS
- **Action** : Renommage doc uniquement pour le V0

### Écart E2 — Chapter et Step non typés (JSON metadata)

- **Vision** : Chapters et Steps sont des modèles typés dans `map_core`
- **Repo** : Stockés dans `ScenarioAsset.metadata` comme JSON brut, lus par le runtime via `jsonDecode`
- **Impact GS** : Faible — le runtime fonctionne, le risque est la fragilité silencieuse
- **Action** : Acceptable pour le GS. Typer après si le JSON casse silencieusement.

### Écart E3 — Pas de Step activation

- **Vision** : `selbrume.md` utilise `Activate Step step_enter_marais` dans les actions d'event
- **Repo** : Seule la completion existe. Pas d'état Active/Inactive.
- **Impact GS** : Moyen — les steps de Selbrume suivent un chemin linéaire dans le GS, l'activation peut être déduite de la completion de la step précédente
- **Action** : Pour le GS, l'activation implicite suffit (step N+1 est active quand step N est completed). L'activation explicite est un lot post-GS.

### Écart E4 — Pas de combat depuis Scene/Cinematic (BLK-1 + BLK-2)

- **Vision** : `selbrume.md` §11 Event rival : "Launch Battle : battle_rival_port" + post-combat actions
- **Repo** : Aucun `CutsceneStartBattleStep`. Le combat se déclenche uniquement par LOS/encounter.
- **Impact GS** : 🔴 Bloquant total — le combat Lysa et le boss phare sont impossibles
- **Action** : Implémenter `CutsceneStartTrainerBattleStep` + mécanisme async suspend/resume (lot SEL-B2)

### Écart E5 — Pas de `givePokemon`

- **Vision** : `selbrume.md` §11 Event starter : "GivePokemon selected_starter"
- **Repo** : Aucune mutation `givePokemon`, aucun step cutscene
- **Impact GS** : Contournable si Config B (joueur commence avec pokémon)
- **Action** : Pour le GS : utiliser Config B (starter pré-chargé dans GameState initial). Pour le scénario complet : implémenter `givePokemon` (lot SEL-B4).

### Écart E6 — `giveItem` écrit dans metadata au lieu de Bag (BLK-3)

- **Vision** : Items donnés sont dans le Bag du joueur
- **Repo** : `giveItem` écrit dans `GameState.metadata`, pas dans `Bag`
- **Impact GS** : Moyen — pas d'item donné dans le GS initial, mais nécessaire pour les quêtes (cristaux, clé cabane)
- **Action** : Fixer `giveItem` → `Bag` (lot SEL-B1)

### Écart E7 — Pas d'Event Builder UI

- **Vision** : Écran formulaire structuré "Quand/Si/Alors/Puis" (narrative_studio.md §18.9)
- **Repo** : Pas de composant nommé EventBuilder
- **Impact GS** : L'auteur doit construire les events via les outils existants (MapEvent pages + scripts)
- **Action** : Post-GS (lot N9)

### Écart E8 — Pas de Scene Builder UI dédié

- **Vision** : Écran graphe dédié aux Scenes (narrative_studio.md §18.5)
- **Repo** : Le graphe scénario existant sert à tout (Global Story + Event Flow)
- **Impact GS** : L'auteur utilise le graphe existant, pas de distinction UI
- **Action** : Post-GS (lot N6)

### Écart E9 — Pas de Fact Registry / World Rules UI

- **Vision** : Écran "Facts & World Rules" avec noms lisibles (narrative_studio.md §18.10)
- **Repo** : Pas d'écran, flags en strings bruts
- **Impact GS** : Faible — l'auteur connaît ses facts par convention
- **Action** : Post-GS (lot N10)

### Écart E10 — Pas de Validator narratif

- **Vision** : 20 types de checks (narrative_studio.md §18.11)
- **Repo** : Validator structurel seulement
- **Impact GS** : Faible pour 1 storyline, important pour le scénario complet
- **Action** : Check minimal de reachability pour le GS. Validator complet post-GS (lot N12).

### Écart E11 — Pas de New Game flow

- **Vision** : `selbrume.md` commence par "le joueur commence" → écran de départ, choix nom, etc.
- **Repo** : Pas de flow New Game
- **Impact GS** : 🔴 Bloquant — impossible de démarrer le jeu
- **Action** : Lot SEL-B6 (overlay minimal + GameState init)

### Écart E12 — Pas de passage conditionnel (porte/zone)

- **Vision** : "Passage des Dames utilisable si fact_passage_dames_unlocked = true"
- **Repo** : Pas de modèle porte/zone conditionnel
- **Impact GS** : Émulable via NPC bloqueur avec visibility rule
- **Action** : Émulation V0. Concept typé post-GS.

---

## 6. Réponse à la question centrale

> Comment définir proprement les concepts narratifs de PokeMap pour que le scénario Selbrume puisse être construit progressivement sans refactor massif, sans exposer les flags techniques, et sans mélanger Scenario, Scene, Cutscene, Script, Step et Event ?

### Stratégie recommandée : Renommage + Extension, pas Refactor

Le repo n'a pas besoin d'un refactor massif. Il a besoin de :

1. **Renommage conceptuel** (doc + UI labels, pas le code) :

| Ancien terme repo | Nouveau terme auteur | Code inchangé |
|---|---|---|
| `ScenarioAsset(scope: globalStory)` | "Storyline" | Même classe |
| `ScenarioAsset(scope: localEventFlow)` | "Scene" ou "Event Flow" | Même classe |
| `RuntimeCutsceneAsset` | "Cinematic" | Même classe |
| `StoryFlags.activeFlags` | "Facts" | Même Set\<String\> |
| `NpcVisibilityRule` + `ConditionalDialogue` | "World Rules" | Même mécanismes |
| `completedStepIds` | "Story Steps completed" | Même liste |

2. **Extensions ponctuelles** (lot par lot, pas en bloc) :

| Extension | Lot | Effort |
|---|---|---|
| `CutsceneStartTrainerBattleStep` + post-battle resume | SEL-B2 | L |
| `ScriptCommandType.completeStep` (direct, pas via cutscene) | SEL-B2 ou B9 | S |
| Fix `giveItem` → Bag | SEL-B1 | S |
| New Game flow overlay | SEL-B6 | M |
| `CutsceneStartWildBattleStep` (boss) | SEL-B3 | M |
| Passage conditionnel (NPC bloqueur émulé) | SEL-B5 | S |
| `givePokemon` mutation + step (si Config A) | SEL-B4 | S |
| Reachability validator minimal | SEL-B10 | S |

3. **Lots reportés** (pas dans le GS) :

| Concept | Lot reporté |
|---|---|
| Modèle `Storyline` typé dans `map_core` | Post-GS |
| Modèle `Chapter` typé dans `map_core` | Post-GS |
| Modèle `StoryStep` typé dans `map_core` | Post-GS |
| Modèle `Event` unifié dans `map_core` | Post-GS |
| Modèle `FactDefinition` dans `map_core` | Post-GS |
| Modèle `WorldRule` unifié dans `map_core` | Post-GS |
| Event Builder UI | Post-GS (N9) |
| Scene Builder UI | Post-GS (N6) |
| Cinematic Builder V2 | Post-GS (N8) |
| Facts & World Rules UI | Post-GS (N10) |
| Validator narratif complet | Post-GS (N12) |

### Pourquoi cette stratégie fonctionne

- **Pas de refactor massif** : on ne renomme pas les classes Dart, on renomme les labels UI et la doc
- **Pas d'exposition de flags** : les flags restent techniques derrière, la doc et les UI utilisent le vocabulaire Fact
- **Pas de mélange** : chaque concept a un mapping clair vers le repo (voir §4)
- **Progression possible** : le GS se construit avec les outils existants + 4-5 extensions. Le modèle typé vient après.
- **Selbrume testable** : le Golden Slice (Lysa combat au port) est implémentable avec SEL-B1 + B2 + B6 + contenu

---

## 7. Commandes exécutées

| # | Commande | But |
|---|---|---|
| 1 | `git status --short --untracked-files=all` | État initial (clean) |
| 2 | `rg "Storyline\|StoryLine" packages/map_core/lib` | Vérifier absence concept Storyline |
| 3 | `rg "class Chapter\|ChapterModel" packages/map_core/lib` | Vérifier absence modèle Chapter |
| 4 | `rg "ScenarioScope" packages/map_core/lib` | Vérifier les valeurs globalStory/localEventFlow |
| 5 | `rg "Fact\|fact_\|FactModel" packages/map_core/lib/src/models` | Vérifier absence modèle Fact |
| 6 | `rg "class SceneGraph\|SceneNode\|SceneAsset" packages/map_core/lib` | Vérifier absence modèle Scene |
| 7 | `rg "class StoryStep\|StepAsset\|stepCompleted" packages/map_core/lib/src/models` | Vérifier Step completion |
| 8 | `rg "CinematicAsset\|RuntimeCutsceneAsset" packages/map_core/lib` | Vérifier modèle Cinematic |
| 9 | `rg "ScenarioNodePayload" packages/map_core/lib/src/models/scenario_asset.dart` | Vérifier node payload |
| 10 | Lecture intégrale `scenario_asset.dart:100-179` | Node types + edge types |

---

## 8. Fichiers créés / modifiés

| Action | Fichier |
|---|---|
| CRÉÉ | `reports/gameplay/sel_a1_narrative_glossary.md` (ce rapport) |
| Modifié | aucun |

---

## 9. Git status final

```
git status --short --untracked-files=all
?? reports/gameplay/sel_a1_narrative_glossary.md
```

---

*Rapport SEL-A1 généré le 2026-05-23. Aucun code de production, test, fixture, ou fichier generated n'a été modifié.*

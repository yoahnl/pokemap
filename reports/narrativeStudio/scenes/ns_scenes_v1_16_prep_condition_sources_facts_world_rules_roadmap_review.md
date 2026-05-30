# NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review

## Resume executif

Verdict : `NS-SCENES-V1-16-prep` est realise en documentation-only.

Decision principale : ne pas coder immediatement `Condition Authoring V0` sous forme de label ou texte libre. Le prochain vrai lot doit etre `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis seulement `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

Raison : le Scene Builder est maintenant assez utilisable visuellement pour accueillir des nodes metier, mais une condition no-code doit lire des sources reelles et nommees. Sans contrat de sources, on retomberait dans un editeur de flags techniques, exactement ce que les documents produit Selbrume demandent d'eviter.

## Raison du lot

V1-12 a permis d'ajouter des nodes. V1-13 a ajoute les edges. V1-14 a pose le canvas Blueprint-like. V1-15 et V1-15-bis ont rendu les connexions visibles, creables et supprimables.

Le blocage suivant n'est donc plus le graph lui-meme, mais le sens metier des nodes. Le node `condition` existe en draft, avec un payload qui peut rester vide ou contenir un libelle/ref draft. Si V1-16 codait seulement un champ texte, l'utilisateur pourrait creer une condition qui ressemble a du no-code mais qui ne serait ni validee, ni pickee, ni reliee a un objet metier.

## Etat actuel du Scene Builder

- SceneAsset est le modele authoring canonique.
- ProjectManifest.scenes est le stockage canonique.
- SceneGraph contient nodes et edges.
- SceneGraphLayout contient seulement le layout editor.
- Le runtime ignore totalement le layout.
- Les nodes V0 ajoutables sont `condition`, `merge`, `end`.
- Les edges V0 utilisent des ports explicites : `start.completed`, `condition.true`, `condition.false`, `merge.completed`.
- Les ports visuels, le drag de connexion, le canvas zoom/pan/drag node et la suppression d'edge existent.
- Aucun runtime Scene V1 n'est branche.
- `StorylineStep.sceneLinkIds` reste desactive.

## Probleme des conditions sans sources metier

Une Condition Scene V1 doit repondre a une question lisible :

```text
Est-ce que telle situation du monde, de la progression, de l'inventaire,
du joueur, d'un event ou d'un resultat local est vraie ?
```

Elle ne doit pas etre :

```text
conditionDraft = "rival_port_defeated == true"
```

Le modele actuel contient deja des briques techniques utiles : `ScriptCondition`, `GameState.storyFlags`, `ScriptVariables`, `consumedEventIds`, `MapEventDefinition`, `StorylineStep` et des predicates de map/entity. Ces briques peuvent servir de backend, mais ne doivent pas devenir l'experience utilisateur principale.

## Analyse des Condition Sources

| Source | Responsabilite produit | Exemple utilisateur | Equivalent technique actuel | Maturite | Utilisable en V0 ? | Picker / registry | Risque si expose trop tot |
|---|---|---|---|---|---|---|---|
| Fact | Etat persistant lisible du monde ou de la progression. | "Rival battu au port" est vrai. | `GameState.storyFlags`, `StoryFlags`, `ScriptCondition.flagIsSet/flagIsUnset`, futures refs Fact. | Partielle : stockage technique existe, registry authoring absente. | Oui seulement si presente comme source fact-like existante et diagnostiquee ; non pour broad UX sans registry. | Fact Registry requise pour UX propre ; picker requis. | Exposer des flags bruts et perdre le no-code. |
| StoryStep / progression narrative | Jalon logique de progression, pas declencheur direct de scene. | "Etape Combat rival active/complete". | `StorylineAsset`, `StorylineStep`, `StorylineEffectType.activateStep/completeStep`, predicates step dans certaines zones de map. | Partielle. | Oui plus tard pour lecture simple active/complete, apres contrat. | Storyline/Chapter/Step picker requis. | Confondre progression et trigger ; brancher Storylines trop tot. |
| Battle outcome | Resultat local d'un combat dans une scene. | victoire/defaite contre rival. | `SceneEdgeKind.battleVictory/battleDefeat`, battle runtime legacy, trainer refs. | Non pret pour Scene V1 authoring. | Non en V0 Condition Sources. | Battle/trainer picker + runtime plan requis. | Transformer un outcome local en Fact persistant sans action explicite. |
| Dialogue outcome | Resultat local d'un dialogue Yarn. | choix confident/hesitant/aggressive. | `SceneEdgeKind.dialogueOutcome`, `YarnDialoguePayload.dialogueId`, outcomes attendus. | Non pret sans Yarn picker/outcome strategy. | Non en V0 Condition Sources. | Yarn dialogue/outcome picker requis. | Laisser Yarn piloter toute la progression. |
| Inventory / item possession | Etat de possession ou quantite d'objet. | "Le joueur a la cle de la cabane". | Bag / inventory dans `GameState`, catalog items selon projet. | Partielle : runtime state existe, source authoring absente. | Pas en tout premier V0 sans item picker ; candidat court terme. | Item picker requis ; pas Fact Registry. | IDs d'items saisis a la main, confusion consommable/key item. |
| Party state | Etat de l'equipe ou capacite accessible. | "Un Pokemon connait Surf" ou "party non vide". | `PlayerParty`, `ScriptCondition.partyHasMove/partyHasUsableMove`, field abilities. | Partielle. | Oui seulement pour un petit sous-ensemble avec picker/enum existant ; sinon defer. | Move/ability picker requis. | Conditions fragiles sur IDs de moves ou mecanique battle incomplete. |
| Trainer / rival defeated state | Etat persistant d'un trainer battu. | "Rival du port deja vaincu". | Conventions legacy via flags/trainer defeat helpers ; trainers dans ProjectManifest. | Partielle et legacy. | Non comme source dediee tant que la convention n'est pas formalisee ; possible via Fact. | Trainer picker + convention Fact/flag. | Hardcoder des flags de trainer ou doubler Fact/trainer state. |
| Map/event consumed state | Etat local d'event deja consomme. | coffre ouvert, PNJ event deja joue. | `GameState.consumedEventIds`, `ScriptCondition.eventIsConsumed`, `MapEventDefinition`. | Assez mature techniquement. | Oui apres contrat, avec picker map/event. | Map/Event picker requis. | Utiliser consumed event comme systeme de progression general. |
| Variable custom | Valeur authoring custom bool/int/string. | compteur d'indices trouves >= 3. | `ScriptVariables`, `ScriptCondition.variableEquals/GreaterThan/LessThan`. | Technique existante, registry authoring absente. | Non pour V0 UX ; seulement backend. | Variable registry requise. | Reintroduire variables magiques. |
| World state | Etat visible derive du monde. | porte ouverte, PNJ visible, dialogue alterne. | Predicates de map/entity, conditional dialogues, world-like rules dispersees. | Dispersee. | Non avant World Rule Contract. | World Rule registry/contract requis. | Boucles invisibles et comportement runtime difficile a predire. |

## Analyse des Facts

Decision : un Fact PokeMap n'est pas seulement un flag nomme. C'est un fait lisible du monde, expose a l'auteur avec un libelle humain, une description et une intention narrative.

Position V0 :

- Bool-first : la majorite des facts Selbrume sont des faits vrais/faux.
- Runtime storage : les facts bool peuvent mapper vers `GameState.storyFlags` ou une couche equivalente, sans exposer ce detail comme UX principale.
- Types futurs : number/text/enum restent necessaires pour certains compteurs, choix ou variables, mais doivent attendre une registry plus solide.
- Authoring registry : une future Fact Registry doit vivre dans `ProjectManifest` ou un sous-modele canonique rattache au projet, avec id stable, label, description, type, categorie et tags.
- UX : les pickers doivent afficher "Rival battu au port" plutot que `fact_rival_port_defeated`.

Decision de sequencing : Fact Registry ne doit pas bloquer un tout premier `Condition Authoring V0` limite aux sources existantes, mais elle doit preceder l'authoring serieux Selbrume, les actions `setFact/clearFact`, les World Rules et les validators complets.

## Analyse des World Rules

Decision : une World Rule est une regle visible ou comportementale du monde derivee de Facts, Steps, variables ou conditions. Elle ne doit pas etre une action cachee de scene qui modifie directement le monde sans contrat.

Une World Rule peut a terme :

- masquer ou montrer un PNJ ;
- changer un dialogue de PNJ ;
- ouvrir/fermer une porte ;
- activer/desactiver une collision ;
- changer un etat de map ou d'ambiance ;
- rendre un event disponible ou indisponible ;
- modifier l'apparence du monde selon progression.

Position runtime : une World Rule doit etre reevaluee par les resolvers/runtime selon l'etat courant, plutot qu'etre seulement une consequence one-shot d'une scene. Une scene ou un event peut produire un Fact ; la World Rule observe ce Fact et change le monde.

Decision de sequencing : le contrat World Rule doit venir avant le golden slice Selbrume. Il peut venir apres un `Condition Authoring V0` tres limite, mais avant tout authoring ambitieux d'actions et avant de pretendre que Selbrume est representable proprement.

## Analyse des Actions / Consequences

| Action / consequence | Deja existante ? | Manquante ? | Node Action ou consequence ? | Picker requis ? | Runtime requis ? |
|---|---|---|---|---|---|
| setFact | Equivalent technique via flags/story state, mais pas Fact Registry Scene V1. | UX Fact Registry et action contract. | Action/consequence explicite. | Fact picker. | Oui pour effet persistant. |
| clearFact | Equivalent technique probable via state mutation, pas UX no-code. | Contract + picker + diagnostics. | Action/consequence explicite. | Fact picker. | Oui. |
| completeStoryStep | `StorylineEffectType.completeStep` existe cote modele Storyline. | Bridge Scene/Event vers progression stable. | Consequence narrative explicite, pas outcome implicite. | Storyline/step picker. | Oui. |
| activateStoryStep | `StorylineEffectType.activateStep` existe. | Meme bridge authoring/runtime. | Consequence narrative explicite. | Storyline/step picker. | Oui. |
| giveItem | Bag/inventory state existe. | Action Scene V1 + item picker + runtime handoff. | Action node ou consequence d'event/scene. | Item picker. | Oui. |
| givePokemon | Party state existe. | Action + Pokemon/species picker + runtime. | Action node/consequence. | Pokemon/species picker. | Oui. |
| startTrainerBattle | Battle/trainer runtime legacy existe. | BattleNode Scene V1 + trainer/battle picker + plan runtime. | Preferer BattleNode, pas action generique. | Trainer/battle picker. | Oui. |
| openYarnDialogue | Dialogue/Yarn payload existe cote model. | Yarn picker/outcomes + runtime Scene. | Preferer YarnDialogueNode. | Dialogue/outcome picker. | Oui. |
| playCinematic | Cinematic runtime legacy existe. | Cinematic picker + SceneRuntimePlan. | Preferer CinematicNode. | Cinematic picker. | Oui. |
| warpPlayer | Script/runtime action probable. | Map/warp picker + action contract. | Action node/consequence. | Map/warp picker. | Oui. |
| setMapEntityVisible | Predicates/entity visibility existent partiellement. | World Rule contract + entity picker. | Preferer World Rule plutot qu'action one-shot. | Map/entity picker. | Oui/resolver. |
| setMapEntityDialogue | Conditional dialogues existent partiellement. | World Rule/dialogue rule contract. | Preferer World Rule ou dialogue rule. | Entity/dialogue picker. | Oui/resolver. |

Principe transversal : un outcome local n'est pas persistant par defaut. Un `SceneOutcome`, un `DialogueOutcome` ou un `BattleOutcome` devient Fact, Step completed ou World Rule uniquement via une action/consequence explicite.

## Options de roadmap comparees

### Option A — Garder V1-16 Condition Authoring V0 immediatement

Verdict : rejetee.

Avantage : rapide et techniquement peu risquee si on se contente d'un label ou d'un texte draft.

Risque majeur : recreer un editeur de texte technique. Les conditions ne seraient pas reliees a des objets metier, les diagnostics seraient faibles, et l'auteur verrait vite des IDs bruts ou des conventions implicites.

### Option B — Inserer Fact Registry avant tout Condition Authoring

Verdict : trop lourde si appliquee strictement.

Avantage : produit propre, pickers no-code solides, vocabulaire Fact/World Rule clair.

Risque : ralentir l'authoring graph et lancer un gros chantier de registry avant de valider le premier flux Condition dans le Scene Builder.

### Option C — Hybride pragmatique

Verdict : retenue.

Sequence recommandee :

```text
V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review
V1-16 — Condition Sources Contract V0
V1-17 — Condition Authoring V0 (Existing Sources Only)
V1-18 — Fact Registry V0
V1-19 — World Rule Contract V0
V1-20 — World Rules V0
```

Pourquoi : ce compromis evite le texte magique sans immobiliser le builder. On commence par cadrer les sources, puis on code un Condition Authoring limite aux sources existantes et honnetes, puis on renforce Facts et World Rules avant Selbrume.

## Decision recommandee

Retenir Option C, avec un changement de roadmap :

- `NS-SCENES-V1-16-prep` est marque DONE.
- `NS-SCENES-V1-16` devient `Condition Sources Contract V0`.
- `Condition Authoring V0` est decale en `NS-SCENES-V1-17` et borne aux sources existantes.
- `Fact Registry V0` devient `NS-SCENES-V1-18`.
- `World Rule Contract V0` et `World Rules V0` sont ajoutes avant le runtime/golden slice.
- `StorylineStep -> Scene Link` reste repousse apres Event -> Scene, Runtime Executor MVP et Golden Slice.

## Roadmap corrigee

| Lot | Statut | Role |
|---|---|---|
| NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review | DONE | Revue architecture/roadmap, aucune implementation. |
| NS-SCENES-V1-16 — Condition Sources Contract V0 | TODO | Definir les sources conditionnelles, leurs mappings, pickers, diagnostics et limites. |
| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | TODO | Configurer Condition avec sources existantes uniquement. |
| NS-SCENES-V1-18 — Fact Registry V0 | TODO | Registry authoring de facts lisibles, bool-first. |
| NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Contrat des regles visibles derivees du monde. |
| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier authoring/validation de world rules controlees. |
| NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Plan runtime pur, sans execution. |
| NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Pickers refs Yarn/Cinematic/Battle/Action. |
| NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Refs, sources, ports, unreachable, cycles, payloads. |
| NS-SCENES-V1-24 — Event to Scene Trigger Prep | TODO | Event local/runtime vers Scene V1. |
| NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Execution minimale d'un SceneRuntimePlan. |
| NS-SCENES-V1-26 — Golden Slice Selbrume Scene/Event Prep | TODO | Slice controle Event -> Scene -> consequences. |
| NS-SCENES-V1-27 — StorylineStep to Scene Link | TODO | Lien StorylineStep seulement apres stabilisation. |

## Impact sur Selbrume

Selbrume a besoin de la chaine :

```text
Event -> Scene -> Dialogue outcome -> Cinematic/Battle -> Fact -> Story Step -> World Rule
```

La revue confirme que :

- Event -> Scene reste plus prioritaire que StorylineStep -> Scene.
- Les facts Selbrume doivent etre des objets authoring lisibles avant d'etre largement utilises.
- Les World Rules Selbrume doivent transformer le monde visible selon facts/steps, pas etre des scripts caches.
- Condition Authoring V0 peut demarrer avant Fact Registry seulement si elle reste limitee aux sources existantes et presentees honnetement.
- Le golden slice ne doit pas hardcoder Mael, Lysa, Port ou Selbrume dans le produit.

## Prochain lot exact

`NS-SCENES-V1-16 — Condition Sources Contract V0`

Objectif du prochain lot : definir le contrat des sources conditionnelles no-code, leurs mappings techniques, les sources V0 autorisees, les pickers requis, les diagnostics et la strategie d'execution/refus, sans encore coder une UI Condition complete.

## Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md`

Fichiers modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests/analyze non requis

- `dart analyze` non requis : aucun fichier Dart modifie.
- `flutter analyze` non requis : aucun widget ou fichier Flutter modifie.
- `dart test` non requis : aucun code ni test modifie.
- `flutter test` non requis : aucun code ni widget modifie.
- Verification obligatoire conservee : `git diff --check`.

## Git status initial

Commande : `pwd`

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`

```text
main
```

Commande : `git status --short --untracked-files=all`

```text
Sortie : <vide>
```

Commande : `git diff --stat`

```text
Sortie : <vide>
```

Commande : `git log --oneline -n 10`

```text
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
```

## Git status final

Commande : `git status --short --untracked-files=all`

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md
```

Commande : `git diff --stat`

```text
 .../scenes/road_map_scene_builder_authoring.md     | 41 ++++++++++++-----
 reports/narrativeStudio/scenes/road_map_scenes.md  | 52 +++++++++++++++++-----
 2 files changed, 71 insertions(+), 22 deletions(-)
```

Commande : `git diff --name-only`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git diff --check`

```text
Sortie : <vide>
```

## Evidence Pack

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`

Fichier absent : aucun fichier obligatoire attendu n'est absent.

Impact : aucun.

### Contenu complet du rapport cree

Le present fichier est le rapport cree pour `NS-SCENES-V1-16-prep`; son contenu complet correspond a l'integralite de ce document.

### Diff complet de road_map_scene_builder_authoring.md et road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 05372260..649a3820 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-16 — Condition Authoring V0
+NS-SCENES-V1-16 — Condition Sources Contract V0
 ```
 
 ## Principes
@@ -20,6 +20,8 @@ NS-SCENES-V1-16 — Condition Authoring V0
 - Runtime ignore toujours `SceneGraphLayout`.
 - `ScenarioAsset` reste legacy/bridge, pas modele produit final.
 - `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.
+- Une Condition no-code doit lire une source metier explicite ; pas de condition textuelle magique ni de flag technique expose comme experience principale.
+- Les Facts et World Rules doivent etre cadres avant le golden slice, meme si le premier authoring Condition peut rester limite aux sources existantes.
 
 ## Roadmap recommandee
 
@@ -31,14 +33,19 @@ NS-SCENES-V1-16 — Condition Authoring V0
 | NS-SCENES-V1-14 | Blueprint Graph Canvas Foundation / Layout Authoring V0 | core / editor | Ajouter grille, zoom boutons + pinch trackpad, pan, drag node et persistence memoire de `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap, pas de ports graphiques complexes, pas de cable tire a la souris. | `scene_authoring_operations.dart`, graph view, workspace Scenes, widget tests. | Tests update layout, zoom/reset, pinch trackpad non mutant, pan local, drag/persist layout, nodes/edges inchanges, edge visible apres deplacement. | Coupler layout et runtime ; gestes ambigus avec connexion V1-13 ; churn de diffs. | DONE : positions sauvegardees en memoire, zoom/pan locaux, edges suivent les nodes, aucun effet runtime. | V1-13. |
 | NS-SCENES-V1-15 | Visual Port Connection UX V0 | editor | Transformer la connexion V1-13 en interaction Blueprint-like : ports visibles, preview wire, highlight/snap, drop sur input. | Pas de runtime, pas de suppression/reconnexion avancee, pas de ports complexes pour nodes desactives. | graph canvas, node cards, connection state tests. | DONE : ports visibles, drag output, preview line, target highlight, drop valide cree edge, drop vide annule. | Reintroduire drag-and-drop trop large ; rendre actifs des nodes sans payload honnete. | DONE : connexion visuelle claire, toujours basee sur ports V0, aucune fake ref. | V1-14. |
 | NS-SCENES-V1-15-bis | Edge Selection / Deletion UX V0 | core / editor | Rendre les liens corrigibles : selection locale d'edge, highlight, inspecteur de lien, suppression memoire. | Pas de reconnexion avancee, pas de payload picker, pas de runtime, pas d'edition de condition. | `scene_authoring_operations.dart`, graph view, inspector, workspace Scenes. | Tests remove edge core, selection/highlight inspector, suppression, nodes/layout preserves, creation V1-15 apres suppression. | Supprimer trop large ; casser les ports visuels ou selection node ; confondre edge layout et graph logique. | DONE : edge selectionnable et supprimable, ProjectManifest.scenes mis a jour en memoire, aucune fake ref. | V1-15. |
-| NS-SCENES-V1-16 | Condition Authoring V0 | core / editor | Configurer un `ConditionNode` V0 avec payload minimal honnete et diagnostics utiles. | Pas de runtime, pas d'expressions complexes, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector draft controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; fake refs. | Condition configurable sans mensonge, scene invalide si condition incomplete bloquante. | V1-15-bis. |
-| NS-SCENES-V1-17 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-15 ou V1-16. |
-| NS-SCENES-V1-18 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-16, V1-17 utile. |
-| NS-SCENES-V1-19 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-15, V1-18. |
-| NS-SCENES-V1-20 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-17, V1-19. |
-| NS-SCENES-V1-21 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/action simple/dialogue handoff minimal. | Pas de full battle/cinematic si non pret, pas StorylineStep link. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-17, V1-19. |
-| NS-SCENES-V1-22 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-20, V1-21, payloads/diagnostics. |
-| NS-SCENES-V1-23 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-20, V1-21, V1-22. |
+| NS-SCENES-V1-16-prep | Condition Sources / Facts / World Rules Roadmap Review | doc-only / architecture-review | Decider si Condition Authoring peut commencer sans cadrer Facts, World Rules et sources conditionnelles. | Pas de code, pas de widget, pas de modele, pas de runtime. | rapport V1-16-prep, roadmaps. | `git diff --check` uniquement. | Rester trop abstrait ou bloquer inutilement l'authoring. | DONE : option hybride retenue, prochain lot exact defini, roadmaps ajustees. | V1-15-bis. |
+| NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport ou read model pur si necessaire, `scene_diagnostics.dart` seulement si diagnostic contractuel decide. | Si code absent : `git diff --check`; si read model pur : tests core/analyze. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | Contrat clair pour Fact, StoryStep, event consumed, party, inventory, variable et world state, avec sources V0 autorisees. | V1-16-prep. |
+| NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | Condition configurable via source explicite, scene invalide si condition incomplete bloquante. | V1-16. |
+| NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest` si decide, read models/pickers, tests serialization. | Tests registry JSON, picker refs, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | Facts lisibles, refs stables, mapping runtime documente vers etat persistant. | V1-16, V1-17 utile. |
+| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de runtime complet, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | `git diff --check` ou tests core si modele pur. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | Types de regles, sources, effets, priorites et diagnostics de base definis. | V1-18 recommande. |
+| NS-SCENES-V1-20 | World Rules V0 | core / editor / gameplay | Premier authoring/validation de World Rules controlees : visibilite, dialogue, porte/collision ou map state selon contrat. | Pas de runtime Scene complet, pas de StorylineStep link. | map entity/world rule models si decide, editor picker, diagnostics. | Tests refs map/entity, evaluation pure, diagnostics. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | Regles visibles authorables et validables, sans flags bruts dans l'UX. | V1-19. |
+| NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-17, V1-18 utile. |
+| NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-17, V1-21 utile. |
+| NS-SCENES-V1-23 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions et facts/world rules. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-17, V1-18, V1-22. |
+| NS-SCENES-V1-24 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-23. |
+| NS-SCENES-V1-25 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/action simple/dialogue handoff minimal. | Pas de full battle/cinematic si non pret, pas StorylineStep link. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-21, V1-23. |
+| NS-SCENES-V1-26 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-20, V1-24, V1-25, payloads/diagnostics. |
+| NS-SCENES-V1-27 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-24, V1-25, V1-26. |
 
 ## Options comparees
 
@@ -46,7 +53,7 @@ NS-SCENES-V1-16 — Condition Authoring V0
 |---|---|---|
 | A — Continuer directement RuntimePlan puis StorylineStep | Rejetee | RuntimePlan seul ne rend pas le builder utilisable ; StorylineStep link trop tot confond progression et declencheur. |
 | B — Basculer uniquement graph authoring | Rejetee partiellement | Aligne bien Blueprint-like, mais risque de creer des graphes sans contrat runtime. |
-| C — Hybride Blueprint + runtime plan | Retenue | Donne vite un builder utile, garde runtime plan proche, puis enchaine Event -> Scene avant StorylineStep. |
+| C — Hybride Blueprint + sources metier + runtime plan | Retenue | Garde le builder utilisable, evite les conditions textuelles magiques, puis enchaine Fact/World Rules, runtime plan, Event -> Scene avant StorylineStep. |
 | D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |
 
 ## Mise a jour V1-11
@@ -93,7 +100,7 @@ Decision : les ports visuels V0 sont maintenant presents sur le canvas. L'auteur
 
 Limites : pas de suppression/reconnexion, pas de ports actifs pour Yarn/Action/Battle/Cinematic/Branch, pas d'edition de payload, pas de runtime.
 
-Prochain lot exact : `NS-SCENES-V1-16 — Condition Authoring V0`.
+Prochain lot exact : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review`.
 
 ## Mise a jour V1-15-bis
 
@@ -103,7 +110,17 @@ Decision : V1-15-bis ajoute la correction des liens sans ouvrir la reconnexion a
 
 Limites : pas de reconnexion, pas de suppression node, pas de payload picker, pas de runtime, pas d'edition Condition.
 
-Prochain lot exact : `NS-SCENES-V1-16 — Condition Authoring V0`.
+Prochain lot exact : `NS-SCENES-V1-16 — Condition Sources Contract V0`.
+
+## Mise a jour V1-16-prep
+
+Statut : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review` est DONE.
+
+Decision : Condition Authoring V0 ne doit pas commencer par un payload texte libre. Le Scene Builder doit d'abord cadrer les sources de condition lisibles, leur mapping vers l'existant (`GameState`, `ScriptCondition`, story progression, map/event state), les pickers requis et les diagnostics. La roadmap insere donc `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis deplace l'authoring effectif en `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
+
+Limites : aucune Fact Registry, World Rule, UI Condition ou runtime n'est code dans V1-16-prep.
+
+Prochain lot exact : `NS-SCENES-V1-16 — Condition Sources Contract V0`.
 
 ## Selbrume golden slice
 
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 496948b2..5ed17515 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -54,20 +54,52 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0 | DONE | Canvas Blueprint-like de base : grille, zoom local par boutons et pinch trackpad, pan local, deplacement de nodes, persistence memoire de `SceneGraphLayout`, edges qui suivent, sans impact runtime. |
 | NS-SCENES-V1-15 — Visual Port Connection UX V0 | DONE | Ports visuels V0, drag depuis output, preview wire, highlight/snap des inputs compatibles, drop valide cree un edge via les regles V1-13, drop vide annule. |
 | NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0 | DONE | Selection locale d'edge, highlight visuel, inspecteur de lien et suppression d'edge en memoire via operation pure, sans runtime ni reconnexion avancee. |
-| NS-SCENES-V1-16 — Condition Authoring V0 | TODO | Ajouter le premier authoring minimal du payload Condition sans fake refs, avec diagnostics honnetes et sans runtime. |
-| NS-SCENES-V1-17 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
-| NS-SCENES-V1-18 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
-| NS-SCENES-V1-19 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
-| NS-SCENES-V1-20 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume. |
-| NS-SCENES-V1-21 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
-| NS-SCENES-V1-22 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
-| NS-SCENES-V1-23 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers et runtime MVP stabilises. |
+| NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review | DONE | Revue architecture/roadmap : refuser une Condition V0 textuelle magique, cadrer sources metier, Facts, World Rules et consequences avant authoring payload. |
+| NS-SCENES-V1-16 — Condition Sources Contract V0 | TODO | Definir le contrat no-code des sources de condition, leur mapping vers l'existant, leurs pickers requis et les diagnostics attendus, sans UI payload complete. |
+| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | TODO | Configurer un `ConditionNode` V0 uniquement avec des sources existantes et honnetes, sans texte magique ni refs inventees. |
+| NS-SCENES-V1-18 — Fact Registry V0 | TODO | Ajouter une registry authoring de Facts lisibles, bool-first, preparant les pickers no-code et le mapping runtime vers l'etat persistant. |
+| NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions, sans encore brancher tout le runtime. |
+| NS-SCENES-V1-20 — World Rules V0 | TODO | Premier authoring/validation de World Rules controlees : visibilite, dialogue, portes/collisions ou map state selon contrat. |
+| NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
+| NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
+| NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
+| NS-SCENES-V1-24 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume. |
+| NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
+| NS-SCENES-V1-26 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
+| NS-SCENES-V1-27 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers et runtime MVP stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-16 — Condition Authoring V0`
+`NS-SCENES-V1-16 — Condition Sources Contract V0`
 
-Raison : V1-15-bis rend les connexions corrigibles. Le prochain blocage authoring est le premier payload metier honnete : configurer une Condition V0 sans fake refs et avec diagnostics clairs, avant de reprendre les pickers lourds ou le runtime plan.
+Raison : V1-15-bis rend les connexions corrigibles, mais une Condition V0 ne doit pas devenir un champ texte technique. Avant de coder l'authoring du payload, il faut definir les sources lisibles, leurs mappings vers `GameState` / `ScriptCondition` / progression, les pickers requis, les diagnostics et les limites d'execution.
+
+## Decisions V1-16-prep
+
+- Le lot est documentation-only : aucun code, widget, modele, runtime, test ou fixture n'est modifie.
+- `Condition Authoring V0` immediat avec label/draft textuel est rejete : il recreerait un editeur de flags techniques.
+- Option retenue : hybride pragmatique. Inserer `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
+- Les Conditions Scene V1 devront lire des sources metier explicites : Facts, StorySteps, resultats locaux de dialogue/combat, inventaire, party, map/event state, variables authoring et World State.
+- Un Fact PokeMap est un fait lisible du monde, pas seulement un flag brut. V0 doit etre bool-first, mappe au runtime via `GameState.storyFlags` ou equivalent, puis evoluer vers types number/text/enum avec registry.
+- Une World Rule est une regle visible/efficace du monde derivee de Facts/Steps/conditions ; elle doit etre cadree avant le golden slice Selbrume, mais ne bloque pas un Condition Authoring V0 limite aux sources existantes.
+- Les actions/consequences doivent rester explicites : un SceneOutcome local ne devient Fact, Step completed ou World Rule que via une action/consequence authorisee.
+- `Event -> Scene` reste prioritaire sur `StorylineStep -> Scene`; `StorylineStep.sceneLinkIds` reste repousse apres builder, triggers, runtime MVP et golden slice.
+
+## Limites V1-16-prep
+
+- Pas de Fact Registry codee.
+- Pas de World Rule codee.
+- Pas de Condition UI codee.
+- Pas de nouveau payload, JSON, Freezed ou build_runner.
+- Pas de runtime, Event -> Scene, StorylineStep link ou donnee Selbrume.
+
+## Tests V1-16-prep
+
+- Dart analyze non requis : lot documentation-only.
+- Flutter analyze non requis : lot documentation-only.
+- Dart test non requis : lot documentation-only.
+- Flutter test non requis : lot documentation-only.
+- Verification requise : `git diff --check`.
 
 ## Decisions V1-15-bis
```

### Sorties finales

Commande : `git status --short --untracked-files=all`

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md
```

Commande : `git diff --stat`

```text
 .../scenes/road_map_scene_builder_authoring.md     | 41 ++++++++++++-----
 reports/narrativeStudio/scenes/road_map_scenes.md  | 52 +++++++++++++++++-----
 2 files changed, 71 insertions(+), 22 deletions(-)
```

Commande : `git diff --name-only`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git diff --check`

```text
Sortie : <vide>
```

## Auto-review critique

- La decision evite le piege le plus probable : coder une condition textuelle qui semble utile mais contourne le no-code.
- La roadmap reste plus lente que "Condition Authoring tout de suite", mais elle protege le modele produit avant Selbrume.
- Risque residuel : `Condition Sources Contract V0` devra rester borne ; s'il devient une mega-spec Facts/WorldRules, il retardera trop l'authoring.
- Point de vigilance : Fact Registry ne doit pas devenir un systeme de flags techniques maquilles. Les labels et categories doivent etre traites comme des objets produit.
- Point de vigilance : World Rules doivent rester observables/validables, pas des scripts caches.

## Regard critique sur le prompt

Le prompt force utilement l'arret avant une Condition V0 fragile. Il est cependant large : il couvre sources de conditions, facts, world rules, consequences et roadmap, ce qui pourrait pousser a tout definir d'un coup. La bonne reduction est de trancher le sequencing maintenant, puis de limiter le prochain lot au contrat des sources conditionnelles V0.

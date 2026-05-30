# NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint

## Resume executif

Le checkpoint est realise en documentation-only.

Decision principale : le prochain lot exact recommande est :

```text
NS-SCENES-V1-21 — Payload Pickers V0
```

Le `Scene Runtime Plan V0` reste indispensable, mais il est repousse apres les Payload Pickers et apres `Event -> Scene Trigger Prep`. La raison est simple : le Scene Builder est maintenant visuellement credible, les Conditions/Facts/World Rules existent en V0, mais les scenes ne peuvent pas encore contenir honnetement les refs metier du golden slice : Yarn, Cinematic, Battle et Action. Compiler une Scene en plan runtime avant ces refs produirait surtout un plan sur des graphes encore pauvres.

Roadmap corrigee :

1. `NS-SCENES-V1-21 — Payload Pickers V0`
2. `NS-SCENES-V1-22 — Event to Scene Trigger Prep`
3. `NS-SCENES-V1-23 — Scene Runtime Plan V0`
4. `NS-SCENES-V1-24 — Diagnostics / Validator Expansion`
5. `NS-SCENES-V1-25 — Scene Runtime Executor MVP`
6. `NS-SCENES-V1-26 — World Rules Map Editor Integration V0`
7. `NS-SCENES-V1-27 — Golden Slice Selbrume Scene/Event Prep`
8. `NS-SCENES-V1-28 — StorylineStep to Scene Link`

## Raison du lot

V1-20 a ajoute les World Rules comme donnees projet authorables, validables et projetables de maniere pure. V1-20-bis a corrige la roadmap pour ne pas partir automatiquement vers le runtime.

Ce checkpoint relit donc la vision produit avant de reprendre le code. Le but est d'eviter deux erreurs symetriques :

- partir trop vite vers le runtime alors que les scenes ne peuvent pas encore porter les payloads metier ;
- rester trop longtemps dans le polish UI sans rejoindre le chemin jouable Selbrume.

## Etat actuel du Scene Builder

Etat valide apres les lots recents :

- Canvas Blueprint-like avec grille, zoom, pinch trackpad, pan, drag node et layout memoire.
- Nodes, ports, edges, creation visuelle de liens et suppression de liens.
- Conditions structurees, sans texte magique.
- Fact Registry V0 dans `ProjectManifest.facts`.
- World Rules V0 dans `ProjectManifest.worldRules`.
- Diagnostics Scene et World Rules deja presents.

Blocages restants :

- Les nodes metier `yarnDialogue`, `cinematic`, `battle`, `action` ne sont pas encore configurables par pickers honnetes.
- `Event -> Scene` n'est pas encore cadre/branche.
- `SceneRuntimePlan` n'existe pas encore.
- Le runtime executor Scene V1 n'existe pas.
- Le Validator transversal n'a pas encore la couverture golden slice.
- Les World Rules ne sont pas encore integrees depuis le contexte Map Editor cible.

## Relecture de la vision Narrative Studio

La vision produit relue dans `MVP Selbrume/narrative_studio.md` est constante :

- PokeMap vise un RPG Maker Pokemon-like moderne, no-code autant que possible.
- Le createur ne doit pas penser en flags techniques.
- Le createur doit penser en situations, evenements, decisions, consequences, progression et changements visibles du monde.
- La grammaire produit est : `Quand [declencheur] / Si [conditions] / Alors [actions ou scene ou dialogue ou combat ou cinematic] / Puis [consequences ou facts ou changements du monde]`.
- `Event` = pourquoi/quand quelque chose demarre.
- `Scene` = ce qui se deroule une fois demarre.
- `Yarn` raconte et produit des outcomes, mais ne doit pas piloter toute la progression.
- `Fact` est une verite persistante lisible du monde.
- `World Rule` change l'apparence ou le comportement du monde selon Facts/Steps/Conditions.
- `Validator` est central pour l'outil no-code.

Conclusion produit : le prochain lot doit rapprocher les scenes de vrais contenus metier configurables, sans fake refs. C'est le trou principal avant Event -> Scene et Runtime Plan.

## Analyse golden slice Selbrume

Golden slice cible :

```text
Parler a Lysa au port
-> Event verifie Step active + Rival pas battu
-> Event lance Scene "Rencontre rival"
-> Scene joue Dialogue Yarn "rival_intro"
-> Yarn outcome confident/hesitant/aggressive
-> Scene branches to different Cinematics
-> Battle Rival
-> victory/defeat
-> persistent Fact
-> Story Step completed
-> World Rule change Lysa/PNJ/access
-> Validator confirms reachability
```

Lecture du chemin :

- Le premier contact runtime vient d'un Event de map, pas d'une StorylineStep.
- La Scene doit pouvoir appeler Yarn, brancher sur outcome, jouer Cinematic, lancer Battle et emettre des consequences.
- Facts et World Rules existent maintenant en V0, mais les refs de Scene vers Yarn/Cinematic/Battle/Action sont encore le maillon absent.
- Event -> Scene est urgent, mais il doit pointer vers une scene metier, pas seulement vers un graph vide ou conditionnel.
- Runtime Plan devient plus pertinent apres refs metier et preparation Event -> Scene.

## Options comparees

### Option A — Scene Runtime Plan V0 maintenant

Verdict : rejetee comme prochain lot, conservee en V1-23.

Ce que ca debloque :

- Contrat pur d'execution future.
- Mapping `SceneNodeKind -> intent`.
- Blocage des scenes invalides avant runtime.

Ce que ca ne debloque pas encore :

- Pas de selection Yarn/Cinematic/Battle/Action.
- Pas de Event -> Scene.
- Pas de scene Selbrume construisible avec vraies refs.

Risque : figer un plan runtime autour de payloads que l'authoring ne sait pas encore produire proprement.

### Option B — Event to Scene Trigger Prep maintenant

Verdict : tres prioritaire, placee en V1-22.

Ce que ca debloque :

- Le lien produit majeur Map/Event -> Scene.
- Une trajectoire plus proche de Selbrume que StorylineStep -> Scene.

Ce que ca ne debloque pas encore :

- Les Scenes ciblees restent pauvres si Yarn/Cinematic/Battle/Action ne sont pas configurables.

Risque : relier la map a une Scene qui ne peut pas encore representer la situation "Rencontre rival".

### Option C — Payload Pickers V0 maintenant

Verdict : retenue comme V1-21.

Ce que ca debloque :

- Activation honnete des nodes metier.
- Refs Yarn/Cinematic/Battle/Action selectionnees depuis le projet ou marquees draft/incompletes explicitement.
- Base concrete pour diagnostics refs/outcomes.
- Base concrete pour Event -> Scene et Runtime Plan.

Risque : scope editor trop large si le lot essaye de faire tous les payloads en profondeur.

Garde-fou : V1-21 doit rester V0, pickers/drafts honnetes, pas de runtime, pas de seed Selbrume, pas de saisie libre comme workflow principal.

### Option D — Diagnostics / Validator Expansion maintenant

Verdict : utile mais trop tot comme prochain lot, placee en V1-24.

Ce que ca debloque :

- Validation plus forte des graphs.
- Preparation golden slice.

Ce que ca ne debloque pas encore :

- Sans payload refs, beaucoup de diagnostics metier seraient theoriques ou limites aux conditions/facts/world rules deja existants.

Risque : construire un validator avant que les refs metier a valider soient authorables.

### Option E — World Rules Map Editor Integration maintenant

Verdict : necessaire, placee en V1-26.

Ce que ca debloque :

- World Rules visibles depuis les cibles map/entity/event.
- Meilleure UX no-code pour consequences visibles.

Ce que ca ne debloque pas encore :

- La Scene "Rencontre rival" reste incapable d'appeler ses contenus metier si Payload Pickers manquent.

Risque : investir dans la visualisation des consequences avant d'avoir le contenu Scene qui les produit.

### Option F — Narrative Overview Alignment Polish maintenant

Verdict : a traiter plus tard ou opportunistiquement, pas comme V1-21.

Ce que ca debloque :

- Correction de l'incoherence "Facts — necessite un modele".
- Meilleure coherence de l'overview.

Ce que ca ne debloque pas :

- Aucun pas direct vers Selbrume jouable.

Risque : confondre polish de surface et progression du produit jouable.

## Matrice comparative

Scores : 1 faible, 5 fort.

| Option | Vision produit | Valeur immediate | Golden slice | Risque archi faible | Anti fake refs | Dependances pretes | Runtime absent acceptable | Testabilite | Total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A Runtime Plan | 3 | 3 | 3 | 4 | 4 | 3 | 5 | 5 | 30 |
| B Event -> Scene | 5 | 4 | 5 | 3 | 4 | 3 | 4 | 4 | 32 |
| C Payload Pickers | 5 | 5 | 5 | 4 | 5 | 4 | 5 | 4 | 37 |
| D Diagnostics / Validator | 4 | 3 | 4 | 5 | 5 | 3 | 5 | 5 | 34 |
| E World Rules Map Editor | 4 | 3 | 4 | 4 | 4 | 4 | 5 | 4 | 32 |
| F Overview Polish | 2 | 2 | 1 | 5 | 5 | 5 | 5 | 5 | 30 |

Decision : Option C gagne car elle ferme le trou le plus concret entre "builder joli" et "scene construisible".

## Decision recommandee

Retenir :

```text
NS-SCENES-V1-21 — Payload Pickers V0
```

Definition du prochain lot :

- rendre configurables les payloads Yarn, Cinematic, Battle et Action sans fake refs ;
- utiliser des pickers projet quand les catalogues existent ;
- sinon exposer des drafts incomplets explicitement diagnostiquables ;
- ne pas activer BranchByOutcome sans source outcome/mappings honnetes ;
- ne pas brancher runtime ;
- ne pas creer de donnees Selbrume.

## Roadmap corrigee

| Lot | Statut | Role |
|---|---|---|
| NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | DONE | Decision produit : Payload Pickers V0 devient le prochain lot. |
| NS-SCENES-V1-21 — Payload Pickers V0 | TODO | Configurer refs Yarn/Cinematic/Battle/Action sans fake refs. |
| NS-SCENES-V1-22 — Event to Scene Trigger Prep | TODO | Relier Event local/runtime a Scene V1 sans StorylineStep trigger. |
| NS-SCENES-V1-23 — Scene Runtime Plan V0 | TODO | Compiler SceneAsset valide en intents purs sans layout. |
| NS-SCENES-V1-24 — Diagnostics / Validator Expansion | TODO | Valider refs, outcomes, reachability, cycles, Events, Facts, World Rules. |
| NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 sans ScenarioAsset canonique. |
| NS-SCENES-V1-26 — World Rules Map Editor Integration V0 | TODO | Reconnecter World Rules a leurs cibles map/entity/event. |
| NS-SCENES-V1-27 — Golden Slice Selbrume Scene/Event Prep | TODO | Prouver la chaine Lysa/rival en fixture/projet controle. |
| NS-SCENES-V1-28 — StorylineStep to Scene Link | TODO | Lier StoryStep a Scene apres triggers/runtime/golden slice. |

## Impact Selbrume

Avant le slice Lysa, il faut au minimum :

- Payload Pickers V0 pour `yarn_rival_intro`, `cinematic_rival_smiles`, `cinematic_rival_teases`, `battle_rival_port` et actions de consequences.
- Event -> Scene pour "parler a Lysa au port".
- Runtime Plan pour transformer la Scene en intents.
- Runtime Executor MVP pour jouer le sous-ensemble.
- Diagnostics/Validator pour ref inconnue, outcome non gere, fact jamais produit, world rule cible absente.
- World Rules Map Editor Integration pour relire le changement Lysa depuis la map.

Peut attendre :

- StorylineStep -> Scene Link complet.
- Cinematic Builder avance, si les cinematics peuvent etre referencees comme assets/fixtures controles.
- Fact types avances au-dela du bool-first.

## Risques

- V1-21 pourrait devenir trop large si chaque payload devient un sous-editeur complet. Il doit rester picker/draft V0.
- Les refs Yarn/Battle/Cinematic peuvent ne pas avoir toutes des registries parfaites. Dans ce cas, V1-21 doit distinguer picker reel, draft incomplet et diagnostic bloquant.
- BranchByOutcome ne doit pas etre active sans source outcome et mappings honnetes.
- Runtime Plan doit rester proche : le repousser ne veut pas dire l'abandonner.
- Event -> Scene doit rester avant StorylineStep -> Scene.

## Non-objectifs confirmes

Ce checkpoint n'ajoute pas :

- code ;
- widget ;
- modele Dart ;
- test ;
- build_runner ;
- runtime Scene ;
- Event -> Scene ;
- StorylineStep.sceneLinkIds ;
- payload picker code ;
- Fact/World Rule code ;
- donnees Selbrume ;
- migration ScenarioAsset ;
- fake refs.

## Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md`

Fichiers modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests / analyze

Documentation-only :

- `dart analyze` non requis.
- `flutter analyze` non requis.
- `dart test` non requis.
- `flutter test` non requis.
- `build_runner` non requis.

Commande obligatoire :

```text
git diff --check
```

Resultat final : voir Evidence Pack.

## Git status initial

Commande :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sorties :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` initial :

```text
Sortie : <vide>
```

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git log --oneline -n 10` initial :

```text
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
```

## Git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
```

## Git diff --stat final

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 36 +++++++++++++-------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 38 ++++++++++++----------
 2 files changed, 45 insertions(+), 29 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport non suivi. Le rapport cree apparait dans `git status --short --untracked-files=all`.

## Git diff --name-only final

Commande :

```text
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` ne liste pas le rapport non suivi. Le rapport cree apparait dans `git status --short --untracked-files=all`.

## Git diff --check final

Commande :

```text
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
```

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/cac739de-0ed8-4e6b-a211-a91fc72477e3/pasted-text.txt
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_bis_roadmap_checkpoint_correction.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/models/narrative_fact.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/verification-before-completion/SKILL.md
```

### Contenu complet du rapport cree

Ce fichier est le rapport cree pour `NS-SCENES-V1-20-checkpoint`. Son contenu complet est le present document, depuis le titre `# NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint` jusqu'a la section `Regard critique sur le prompt`.

### Diff complet de road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 23c389bb..617dab31 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint
+NS-SCENES-V1-21 — Payload Pickers V0
 ```
 
 ## Principes
@@ -40,14 +40,15 @@ NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint
 | NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
 | NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
 | NS-SCENES-V1-20-bis | Roadmap Checkpoint Correction | doc-only / roadmap | Corriger l'aiguillage post V1-20 : inserer le checkpoint Narrative Studio demande et eviter de lancer V1-21 automatiquement. | Pas de code, pas de widget, pas de modele, pas de tests, pas de screenshots. | roadmaps + rapport bis. | `git diff --check` uniquement. | Continuer vers runtime sans relire la vision produit ; laisser V1-21 comme prochain implicite. | DONE : V1-20 reste DONE, prochain lot exact devient V1-20-checkpoint, V1-21 reste candidat post-checkpoint, note Facts overview ajoutee. | V1-20. |
-| NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite : Runtime Plan, Event -> Scene, World Rules Map Editor, Payload Pickers, Validator ou golden slice path. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | `git diff --check` uniquement. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | Decision claire, prochain lot exact justifie, trajectoire Selbrume revalidee. | V1-20-bis. |
-| NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide, si le checkpoint confirme que c'est bien la prochaine etape. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; court-circuiter Event -> Scene ou World Rules Map Editor si plus prioritaire. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-20-checkpoint. |
-| NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-17, V1-21 utile. |
-| NS-SCENES-V1-23 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions et facts/world rules. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-17, V1-18, V1-22. |
-| NS-SCENES-V1-24 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-23. |
-| NS-SCENES-V1-25 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/action simple/dialogue handoff minimal. | Pas de full battle/cinematic si non pret, pas StorylineStep link. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-21, V1-23. |
-| NS-SCENES-V1-26 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-20, V1-24, V1-25, payloads/diagnostics. |
-| NS-SCENES-V1-27 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-24, V1-25, V1-26. |
+| NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite apres World Rules V0. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | DONE : `git diff --check`. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | DONE : Payload Pickers V0 retenu comme V1-21, trajectoire Selbrume revalidee. | V1-20-bis. |
+| NS-SCENES-V1-21 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal. | workspace Scenes, inspector draft controls, projection refs, diagnostics refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes, nodes metier activables seulement avec payload valide. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | Node payloads metier configurables avec vraies refs ou drafts clairement invalides, aucun fake ref. | V1-17, V1-18, V1-20-checkpoint. |
+| NS-SCENES-V1-22 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link, pas de migration ScenarioAsset. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy ; cibler des scenes incompletes. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21. |
+| NS-SCENES-V1-23 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-21, V1-22 utile. |
+| NS-SCENES-V1-24 | Diagnostics / Validator Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions, facts, world rules et Event -> Scene. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, diagnostics world rules/event, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide, erreurs runtime bloquantes explicites. | V1-21, V1-22, V1-23. |
+| NS-SCENES-V1-25 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/dialogue/cinematic/battle/action via callbacks limites. | Pas de full bridge ScenarioAsset, pas StorylineStep link, pas de consequences persistantes implicites. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-23, V1-24. |
+| NS-SCENES-V1-26 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule pickers, diagnostics. | Tests affichage contextuel, picker target, refs inconnues, overview toujours coherent. | World Rules inutilisables si seulement en overview ; UI trop large. | Les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts. | V1-20, V1-24 utile. |
+| NS-SCENES-V1-27 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-21, V1-22, V1-25, V1-26. |
+| NS-SCENES-V1-28 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-22, V1-25, V1-27. |
 
 ## Options comparees
 
@@ -196,6 +197,18 @@ Note non bloquante : l'overview affiche encore parfois `Facts — necessite un m
 
 Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
 
+## Mise a jour V1-20-checkpoint
+
+Statut : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint` est DONE.
+
+Decision : apres relecture de la vision Narrative Studio et du golden slice Selbrume, le prochain lot exact devient `NS-SCENES-V1-21 — Payload Pickers V0`. Le Runtime Plan reste indispensable, mais il est repousse apres la configuration honnete des payloads metier et apres la preparation Event -> Scene, car un plan runtime sur des scenes sans refs Yarn/Cinematic/Battle/Action debloquerait peu de valeur produit.
+
+Comparaison retenue : Event -> Scene est prioritaire pour Selbrume, mais il doit cibler une Scene capable de contenir un dialogue Yarn, une cinematic, un battle et des actions avec de vraies refs. Diagnostics/Validator doit suivre quand ces refs existent. World Rules Map Editor Integration reste necessaire avant le golden slice complet, mais ne bat pas les Payload Pickers comme prochain lot.
+
+Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune donnee Selbrume et aucun StorylineStep link n'est ajoute dans le checkpoint.
+
+Prochain lot exact : `NS-SCENES-V1-21 — Payload Pickers V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
@@ -204,12 +217,13 @@ Avant le golden slice, il faut au minimum :
 - Edge Authoring V0.
 - Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
+- Event to Scene Trigger Prep pour relier map/event et Scene V1 sans StorylineStep comme declencheur.
+- Scene Runtime Plan V0 pour compiler une Scene valide en intents sans layout.
 - Diagnostics Expansion.
 - World Rules V0 pour les consequences visibles controlees.
 - Narrative Studio Direction Checkpoint pour choisir l'ordre runtime / map events / payloads / validator.
-- Scene Runtime Plan V0.
-- Event to Scene Trigger Prep.
 - Scene Runtime Executor MVP.
+- World Rules Map Editor Integration V0 pour relire les consequences depuis les cibles map/entity.
 
 Peut attendre apres le slice :
 
```

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index e7684beb..f7a94797 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -61,33 +61,35 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-19 — World Rule Contract V0 | DONE | Contrat produit/technique des World Rules V0 : registry projet future avec targets explicites, sources Fact/Step/Event, effets V0 limites et diagnostics requis. |
 | NS-SCENES-V1-20 — World Rules V0 | DONE | Premier modele/authoring/validation de World Rules controlees : registry `ProjectManifest.worldRules`, operations pures, diagnostics, projection pure et apercu editor minimal. |
 | NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction | DONE | Correction documentaire : inserer le checkpoint Narrative Studio obligatoire apres V1-20 et conserver V1-21 comme candidat, pas comme prochain automatique. |
-| NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | TODO | Relire la vision Narrative Studio et choisir la suite la plus logique avant Runtime Plan, Event -> Scene, Payload Pickers, Diagnostics Expansion ou integration Map Editor des World Rules. |
-| NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
-| NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
-| NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
-| NS-SCENES-V1-24 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume. |
+| NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | DONE | Checkpoint produit post World Rules : la suite retenue est Payload Pickers V0 avant Event -> Scene, Runtime Plan, diagnostics et runtime MVP. |
+| NS-SCENES-V1-21 — Payload Pickers V0 | TODO | Ajouter des pickers/drafts honnetes pour Yarn, Cinematic, Battle et Action afin de configurer les nodes metier sans fake refs. |
+| NS-SCENES-V1-22 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume, sans execution runtime complete. |
+| NS-SCENES-V1-23 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
+| NS-SCENES-V1-24 — Diagnostics / Validator Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles, payloads incomplets, Facts et World Rules. |
 | NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
-| NS-SCENES-V1-26 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
-| NS-SCENES-V1-27 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers et runtime MVP stabilises. |
+| NS-SCENES-V1-26 — World Rules Map Editor Integration V0 | TODO | Rendre les World Rules visibles/configurables depuis le contexte map/entity/event sans brancher de runtime Scene. |
+| NS-SCENES-V1-27 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
+| NS-SCENES-V1-28 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP et golden slice stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`
+`NS-SCENES-V1-21 — Payload Pickers V0`
 
-Raison : V1-20 a ajoute les World Rules authoring comme donnees projet validables, sans les brancher au runtime. Le Scene Builder, les Conditions, les Facts et les World Rules sont maintenant assez avances pour imposer un checkpoint de direction avant de relancer un lot de code. Il faut relire la vision Narrative Studio et decider si la suite la plus logique est `Scene Runtime Plan`, `Event -> Scene`, l'integration Map Editor des World Rules, les Payload Pickers, le renforcement du Validator ou un autre chemin vers le golden slice Selbrume.
+Raison : le checkpoint V1-20 confirme que le Scene Builder est maintenant assez solide visuellement et structurellement, mais qu'il ne sait pas encore authorer les nodes metier du golden slice sans references reelles. Le prochain blocage produit est donc de rendre configurables les refs Yarn, Cinematic, Battle et Action sans fake data. `Event -> Scene` et `SceneRuntimePlan` restent indispensables, mais ils deviennent plus utiles une fois qu'une Scene peut porter des payloads metier honnetes.
 
-`NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais il ne doit pas etre lance automatiquement avant reevaluation de la direction.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
 
-Questions obligatoires du checkpoint :
+Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
-- Faut-il faire Scene Runtime Plan maintenant ?
-- Faut-il d'abord cadrer Event -> Scene ?
-- Faut-il d'abord relier les World Rules au Map Editor ?
-- Faut-il avancer les Payload Pickers ?
-- Faut-il renforcer le Validator ?
-- Quelle trajectoire mene le plus vite au golden slice Selbrume ?
+## Decisions V1-20-checkpoint
 
-Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point doit etre traite comme polish/alignement UI dans un lot futur ou pendant le checkpoint, sans correction code dans V1-20-bis.
+- Le checkpoint est DONE en documentation-only : aucun code, widget, modele, runtime, build_runner ou donnee Selbrume n'est ajoute.
+- Option retenue : `NS-SCENES-V1-21 — Payload Pickers V0`.
+- `Scene Runtime Plan V0` est repousse en V1-23 : il reste necessaire, mais trop abstrait tant que Yarn/Cinematic/Battle/Action ne sont pas configurables avec de vraies refs.
+- `Event -> Scene Trigger Prep` est place en V1-22 : Selbrume demarre depuis des Events de map, mais l'Event doit cibler une Scene metier, pas seulement un graph Start/Condition/End.
+- `Diagnostics / Validator Expansion` suit les pickers et le lien Event -> Scene pour valider des refs et outcomes reels.
+- `World Rules Map Editor Integration V0` reste necessaire avant le golden slice complet, mais ne doit pas passer avant la capacite a authorer les scenes metier.
+- `StorylineStep to Scene Link` reste apres golden slice/runtime MVP afin de ne pas confondre progression narrative et declencheur local.
 
 ## Decisions V1-20-bis
 
```

### Git status final exact

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
```

### Git diff --stat final

```text
 .../scenes/road_map_scene_builder_authoring.md     | 36 +++++++++++++-------
 reports/narrativeStudio/scenes/road_map_scenes.md  | 38 ++++++++++++----------
 2 files changed, 45 insertions(+), 29 deletions(-)
```

### Git diff --name-only final

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### Git diff --check final

```text
Sortie : <vide>
```

## Auto-review critique

Ce qui est prouve :

- Les fichiers obligatoires ont ete lus ou audites par recherche ciblee.
- Le checkpoint compare les six options demandees.
- La decision recommande un seul prochain lot : `NS-SCENES-V1-21 — Payload Pickers V0`.
- Les deux roadmaps sont mises a jour.
- Aucun fichier code, widget, modele ou runtime n'a ete modifie.

Limites :

- La matrice utilise un scoring d'architecture produit qualitatif, pas une mesure quantitative.
- Le rapport ne valide pas par tests, car le lot est documentation-only.
- Le polish Facts overview reste note mais non corrige, conformement au scope.

## Regard critique sur le prompt

Le prompt est utile parce qu'il force un arret de direction avant de repartir en code. Il aurait pu etre encore plus strict sur la priorite relative "Payload Pickers vs Event -> Scene", mais la comparaison obligatoire a permis de trancher proprement. La demande d'Evidence Pack complet reste couteuse pour un lot doc-only, surtout avec diffs longs, mais elle protege bien contre les changements silencieux de roadmap.

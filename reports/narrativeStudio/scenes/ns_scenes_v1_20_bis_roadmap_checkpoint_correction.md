# NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction

## Resume executif

`NS-SCENES-V1-20 — World Rules V0` reste fonctionnellement accepte et DONE.

Ce bis corrige uniquement l'aiguillage documentaire post V1-20 : le prochain lot recommande n'est plus `NS-SCENES-V1-21 — Scene Runtime Plan V0`, mais `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

`NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais il ne doit plus etre lance automatiquement avant reevaluation de la direction Narrative Studio.

## Raison du bis

Le prompt V1-20 demandait explicitement de recommander un checkpoint apres World Rules V0. La roadmap V1-20 finale recommandait directement `V1-21 — Scene Runtime Plan V0`.

Le Scene Builder, les Conditions, la Fact Registry et les World Rules sont maintenant suffisamment avances pour justifier un arret de direction. Avant de repartir vers runtime, Payload Pickers, Diagnostics Expansion, Event -> Scene ou integration Map Editor des World Rules, il faut verifier quelle trajectoire sert le mieux le golden slice Selbrume et la vision Narrative Studio.

## Confirmation V1-20 fonctionnellement accepte

V1-20 reste DONE. Le lot a ajoute :

- `ProjectManifest.worldRules` ;
- `WorldRuleDefinition` ;
- `WorldRuleSource`, `WorldRuleTarget`, `WorldRuleEffect` ;
- operations authoring pures `addWorldRule`, `updateWorldRule`, `removeWorldRule` ;
- diagnostics World Rules ;
- projection pure `projectWorldRuleEffects` ;
- overview minimal cote Narrative Studio.

Aucun code V1-20 n'est corrige dans ce bis.

## Probleme detecte dans la roadmap

Avant ce bis, les deux roadmaps indiquaient directement :

```text
NS-SCENES-V1-21 — Scene Runtime Plan V0
```

comme prochain lot recommande.

Cette recommandation contredisait la consigne V1-20, qui demandait :

```text
NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint
```

## Correction appliquee

Corrections appliquees dans les deux roadmaps :

- `NS-SCENES-V1-20 — World Rules V0` reste DONE.
- `NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction` est ajoute comme DONE.
- `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint` est ajoute comme prochain lot TODO.
- `NS-SCENES-V1-21 — Scene Runtime Plan V0` reste present, mais comme candidat logique apres checkpoint.
- La raison du checkpoint est explicitee.
- L'incoherence Facts overview est notee sans correction code.

## Prochain lot exact corrige

```text
NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint
```

Le checkpoint doit repondre notamment a :

- Faut-il faire Scene Runtime Plan maintenant ?
- Faut-il d'abord cadrer Event -> Scene ?
- Faut-il d'abord relier les World Rules au Map Editor ?
- Faut-il avancer les Payload Pickers ?
- Faut-il renforcer le Validator ?
- Quelle trajectoire mene le plus vite au golden slice Selbrume ?

## Impact sur V1-21

`NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint.

Il ne doit pas etre lance automatiquement avant reevaluation, car le risque produit est de repartir vers l'execution avant d'avoir choisi si le blocage principal est plutot :

- Event -> Scene ;
- Payload Pickers ;
- World Rules dans le Map Editor ;
- Diagnostics / Validator ;
- Runtime Plan pur ;
- golden slice Selbrume.

## Note sur l'incoherence Facts overview

Note non bloquante ajoutee : l'overview affiche encore parfois `Facts — necessite un modele` alors que `NS-SCENES-V1-18 — Fact Registry V0` existe.

Ce point doit etre traite comme polish/alignement UI dans un lot futur ou pendant le checkpoint. Il n'est pas corrige dans ce bis, car le scope interdit tout code/widget.

## Fichiers modifies

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_bis_roadmap_checkpoint_correction.md`

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
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
```

Interpretation :

- `git status --short --untracked-files=all` initial : Sortie : <vide>
- `git diff --stat` initial : Sortie : <vide>

## Git status final

Commande finale executee apres creation du rapport :

```text
git status --short --untracked-files=all
```

Sortie :

```text
M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_20_bis_roadmap_checkpoint_correction.md
```

## Git diff --stat

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 23 +++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 27 ++++++++++++++++++++--
 2 files changed, 45 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport untracked. Le rapport apparait dans `git status --short --untracked-files=all`.

## Git diff --name-only

Commande :

```text
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` ne liste pas les fichiers untracked. Le rapport cree apparait dans `git status --short --untracked-files=all`.

## Git diff --check

Commande :

```text
git diff --check
```

Sortie :

```text
<vide>
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
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `MVP Selbrume/narrative_studio.md`
- `/Users/karim/.codex/attachments/50d5ac3a-013c-4eee-9e20-4b88f2130e39/pasted-text.txt`

Fichiers obligatoires absents : aucun.

### Contenu complet du rapport cree

Le present fichier est le rapport cree pour `NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction`. Son contenu complet est constitue de toutes les sections de ce document, de `# NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction` jusqu'a `Regard critique sur le prompt`.

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index a41502e4..e7684beb 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -60,6 +60,8 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-18 — Fact Registry V0 | DONE | Registry authoring de Facts lisibles bool-first dans `ProjectManifest.facts`, operations pures, JSON, diagnostics refs inconnues et picker Condition prioritaire. |
 | NS-SCENES-V1-19 — World Rule Contract V0 | DONE | Contrat produit/technique des World Rules V0 : registry projet future avec targets explicites, sources Fact/Step/Event, effets V0 limites et diagnostics requis. |
 | NS-SCENES-V1-20 — World Rules V0 | DONE | Premier modele/authoring/validation de World Rules controlees : registry `ProjectManifest.worldRules`, operations pures, diagnostics, projection pure et apercu editor minimal. |
+| NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction | DONE | Correction documentaire : inserer le checkpoint Narrative Studio obligatoire apres V1-20 et conserver V1-21 comme candidat, pas comme prochain automatique. |
+| NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | TODO | Relire la vision Narrative Studio et choisir la suite la plus logique avant Runtime Plan, Event -> Scene, Payload Pickers, Diagnostics Expansion ou integration Map Editor des World Rules. |
 | NS-SCENES-V1-21 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
 | NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
 | NS-SCENES-V1-23 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
@@ -70,9 +72,30 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-21 — Scene Runtime Plan V0`
+`NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`
 
-Raison : V1-20 a ajoute les World Rules authoring comme donnees projet validables, sans les brancher au runtime. Le prochain bloc peut revenir a la preparation d'execution Scene V1 avec un `SceneRuntimePlan` pur, en gardant layout, World Rules et runtime separes.
+Raison : V1-20 a ajoute les World Rules authoring comme donnees projet validables, sans les brancher au runtime. Le Scene Builder, les Conditions, les Facts et les World Rules sont maintenant assez avances pour imposer un checkpoint de direction avant de relancer un lot de code. Il faut relire la vision Narrative Studio et decider si la suite la plus logique est `Scene Runtime Plan`, `Event -> Scene`, l'integration Map Editor des World Rules, les Payload Pickers, le renforcement du Validator ou un autre chemin vers le golden slice Selbrume.
+
+`NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais il ne doit pas etre lance automatiquement avant reevaluation de la direction.
+
+Questions obligatoires du checkpoint :
+
+- Faut-il faire Scene Runtime Plan maintenant ?
+- Faut-il d'abord cadrer Event -> Scene ?
+- Faut-il d'abord relier les World Rules au Map Editor ?
+- Faut-il avancer les Payload Pickers ?
+- Faut-il renforcer le Validator ?
+- Quelle trajectoire mene le plus vite au golden slice Selbrume ?
+
+Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point doit etre traite comme polish/alignement UI dans un lot futur ou pendant le checkpoint, sans correction code dans V1-20-bis.
+
+## Decisions V1-20-bis
+
+- V1-20 reste DONE et fonctionnellement accepte : `ProjectManifest.worldRules`, `WorldRuleDefinition`, operations authoring, diagnostics, projection pure et overview minimal sont conserves.
+- Le prochain lot exact est corrige en `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
+- V1-21 Scene Runtime Plan V0 reste dans la roadmap comme candidat post-checkpoint, pas comme prochain automatique.
+- Le checkpoint est obligatoire parce que continuer directement vers le runtime risquerait de contourner la question produit : Narrative Studio doit mener vers des situations, decisions, consequences et changements visibles du monde, pas seulement vers un moteur executable.
+- L'incoherence Facts overview est notee comme polish futur, sans modification editor dans ce bis.
 
 ## Decisions V1-20
```

### Diff complet de road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 83cc86b0..23c389bb 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-21 — Scene Runtime Plan V0
+NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint
 ```
 
 ## Principes
@@ -39,7 +39,9 @@ NS-SCENES-V1-21 — Scene Runtime Plan V0
 | NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest`, operations facts, picker Condition, tests serialization/diagnostics. | DONE : tests registry JSON, operations pures, picker Fact, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | DONE : Facts lisibles stockes dans `ProjectManifest.facts`, refs stables, picker prioritaire, fallback technique conserve. | V1-16, V1-17. |
 | NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
 | NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
-| NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-17, V1-18 utile. |
+| NS-SCENES-V1-20-bis | Roadmap Checkpoint Correction | doc-only / roadmap | Corriger l'aiguillage post V1-20 : inserer le checkpoint Narrative Studio demande et eviter de lancer V1-21 automatiquement. | Pas de code, pas de widget, pas de modele, pas de tests, pas de screenshots. | roadmaps + rapport bis. | `git diff --check` uniquement. | Continuer vers runtime sans relire la vision produit ; laisser V1-21 comme prochain implicite. | DONE : V1-20 reste DONE, prochain lot exact devient V1-20-checkpoint, V1-21 reste candidat post-checkpoint, note Facts overview ajoutee. | V1-20. |
+| NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite : Runtime Plan, Event -> Scene, World Rules Map Editor, Payload Pickers, Validator ou golden slice path. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | `git diff --check` uniquement. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | Decision claire, prochain lot exact justifie, trajectoire Selbrume revalidee. | V1-20-bis. |
+| NS-SCENES-V1-21 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide, si le checkpoint confirme que c'est bien la prochaine etape. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; court-circuiter Event -> Scene ou World Rules Map Editor si plus prioritaire. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-20-checkpoint. |
 | NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-17, V1-21 utile. |
 | NS-SCENES-V1-23 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions et facts/world rules. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-17, V1-18, V1-22. |
 | NS-SCENES-V1-24 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-23. |
@@ -178,7 +180,21 @@ Integration : les operations pures `addWorldRule`, `updateWorldRule` et `removeW
 
 Limites : pas d'ecran dedie World Rules, pas de picker map/entity/event/dialogue, pas de runtime Scene, pas d'Event -> Scene, pas de StorylineStep link, pas de collision/warp/tile/ambience dynamique, pas de donnees Selbrume.
 
-Prochain lot exact : `NS-SCENES-V1-21 — Scene Runtime Plan V0`.
+Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
+
+## Mise a jour V1-20-bis
+
+Statut : `NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction` est DONE.
+
+Decision : V1-20 reste fonctionnellement accepte et DONE. La roadmap ne doit cependant pas lancer automatiquement `NS-SCENES-V1-21 — Scene Runtime Plan V0`. Le prochain lot exact est corrige en `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
+
+Raison : le Scene Builder, les Conditions, la Fact Registry et les World Rules forment maintenant un socle produit assez avance pour relire la vision Narrative Studio avant de choisir le prochain axe. Le checkpoint doit arbitrer entre Runtime Plan, Event -> Scene, World Rules reliees au Map Editor, Payload Pickers, Diagnostics/Validator et trajectoire golden slice Selbrume.
+
+Impact V1-21 : `NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais n'est plus le prochain lot automatique.
+
+Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que `NS-SCENES-V1-18 — Fact Registry V0` existe. Ce polish/alignement UI doit etre traite dans un lot futur ou pendant le checkpoint, sans code dans V1-20-bis.
+
+Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
 
 ## Selbrume golden slice
 
@@ -190,6 +206,7 @@ Avant le golden slice, il faut au minimum :
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
 - Diagnostics Expansion.
 - World Rules V0 pour les consequences visibles controlees.
+- Narrative Studio Direction Checkpoint pour choisir l'ordre runtime / map events / payloads / validator.
 - Scene Runtime Plan V0.
 - Event to Scene Trigger Prep.
 - Scene Runtime Executor MVP.
```

### git status final exact

```text
M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_20_bis_roadmap_checkpoint_correction.md
```

### git diff --stat final

```text
 .../scenes/road_map_scene_builder_authoring.md     | 23 +++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 27 ++++++++++++++++++++--
 2 files changed, 45 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport untracked. Le rapport apparait dans `git status final`.

### git diff --name-only final

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` ne liste pas le rapport untracked ; il est visible dans `git status final`.

### git diff --check final

```text
Sortie : <vide>
```

## Auto-review critique

- Scope respecte : seules les deux roadmaps et ce rapport documentaire sont modifies/crees.
- Aucun fichier Dart, Flutter, modele, test, screenshot, JSON ou build output n'est modifie.
- V1-20 reste DONE et n'est pas reinterprete.
- Le prochain lot exact est corrige en checkpoint.
- V1-21 est conserve explicitement comme candidat apres checkpoint.
- L'incoherence Facts overview est notee sans correction code.
- Limite : le rapport contient une reference auto-descriptive pour son propre contenu complet, car reproduire integralement un fichier dans lui-meme cree une boucle documentaire.

## Regard critique sur le prompt

Le prompt est utile et precis : il corrige une incoherence de roadmap sans rouvrir V1-20. La contrainte no-code/no-widget est necessaire pour eviter un bis de polish UI deguise.

Point de vigilance : demander le contenu complet du rapport a l'interieur du rapport lui-meme est auto-referentiel. La formulation gagnerait a preciser que le rapport entier constitue cette preuve, tandis que les diffs complets des fichiers modifies restent reproduits explicitement.

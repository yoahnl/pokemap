# NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment

## Résumé exécutif

Verdict : lot réalisé en `documentation-only`.

Décision roadmap : retenir une **roadmap hybride orientée Blueprint-like**. Le besoin produit immédiat n'est pas de lier Storylines ni de brancher le runtime ; c'est de rendre le Scene Builder réellement constructible : node drafts, palette, ajout de nodes, edges, layout, payload pickers et diagnostics élargis.

Le `SceneRuntimePlan V0` décidé en V1-10 reste nécessaire, mais il est repositionné après les premiers lots d'authoring graph minimal. `Event -> Scene` passe avant `StorylineStep -> Scene`, car Selbrume démarre surtout ses scènes depuis des Events de map, pas depuis une Story Step qui déclenche tout.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
```

## Raison du lot

V1-10 a correctement préparé la stratégie runtime : pas de branchement prématuré, pas de conversion automatique vers `ScenarioAsset`, futur `SceneRuntimePlan` pur.

Mais le Scene Builder actuel reste surtout read-only avec une création de draft minimale. Il ne permet pas encore à l'auteur de construire une scène Blueprint-like. Continuer directement vers `StorylineStep to Scene Link` ou vers runtime-only laisserait le besoin produit principal bloqué.

## Rappel de V1-10 Runtime Execution Prep

V1-10 a décidé :

- `SceneAsset` ne doit pas être exécuté directement.
- Le runtime doit consommer un plan pur futur, sans layout.
- `ScenarioRuntimeExecutor` peut inspirer ou servir de bridge temporaire explicite.
- Aucune conversion automatique `SceneAsset -> ScenarioAsset`.
- `StorylineStep.sceneLinkIds` reste hors scope tant que Scene V1 n'est pas stable.

Cette décision reste valide.

## Besoin Blueprint-like

Le Scene Builder cible doit évoluer vers :

- palette de nodes ;
- ajout de nodes ;
- configuration de nodes ;
- ports visibles et sorties explicites ;
- connexion de nodes ;
- layout authorable ;
- payload pickers honnêtes ;
- diagnostics qui guident l'auteur ;
- exécution future via plan runtime.

Le builder ne doit pas devenir un éditeur de flags. Il doit permettre de penser en situations, décisions, scènes et conséquences.

## Options comparées

| Option | Verdict | Ce que ça débloque | Ce que ça bloque / risque |
|---|---|---|---|
| Option A — Continuer roadmap actuelle : RuntimePlan puis StorylineStep | Rejetée | Avance le runtime pur. | L'auteur ne peut toujours pas construire une scène ; StorylineStep trop tôt confond progression et déclenchement. |
| Option B — Basculer uniquement vers Graph Authoring | Rejetée partiellement | Aligne vite le builder avec l'objectif Blueprint-like. | Risque de créer des graphes sans contrat runtime ni payload strategy. |
| Option C — Hybride Blueprint + Runtime Plan | Retenue | Rend le builder utile, garde runtime plan proche, place Event -> Scene avant StorylineStep. | Demande de tenir la discipline des petits lots. |
| Option D — Event-first | Rejetée maintenant | Selbrume dépend bien des Events. | Trop tôt si aucune scène construite visuellement ne peut être ciblée. |

## Décision recommandée

Recommandation ferme : **Option C — Roadmap hybride**.

Ordre retenu :

1. Définir les node drafts et garde-fous anti-fake refs.
2. Ajouter le node authoring minimal.
3. Ajouter l'edge authoring.
4. Ajouter le layout authoring.
5. Ajouter `SceneRuntimePlan V0`.
6. Ajouter les payload pickers.
7. Étendre les diagnostics.
8. Préparer `Event -> Scene`.
9. Ajouter l'executor Scene MVP.
10. Préparer le golden slice Selbrume.
11. Brancher `StorylineStep -> Scene` seulement ensuite.

## Roadmap recommandée

La roadmap détaillée est créée dans :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Synthèse :

| Lot | Type | Objectif |
|---|---|---|
| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | doc-only / planning | Définir nodes ajoutables, payload drafts, ports, limites anti-fake refs. |
| NS-SCENES-V1-12 — Node Authoring V0 | core / editor | Palette minimale et création de nodes draft. |
| NS-SCENES-V1-13 — Edge Authoring V0 | core / editor | Connexion explicite ports/nodes, validation de compatibilité. |
| NS-SCENES-V1-14 — Layout Authoring V0 | editor | Déplacement de nodes et persistance du layout. |
| NS-SCENES-V1-15 — Scene Runtime Plan V0 | core | Plan pur depuis `SceneAsset`, sans layout ni Flutter. |
| NS-SCENES-V1-16 — Payload Pickers V0 | editor / core | Pickers Yarn, cinematic, battle/action refs. |
| NS-SCENES-V1-17 — Diagnostics Expansion | core / editor | Refs, ports requis, outcomes, unreachable, cycles. |
| NS-SCENES-V1-18 — Event to Scene Trigger Prep | core / editor / doc | Préparer Event local/runtime -> Scene V1. |
| NS-SCENES-V1-19 — Scene Runtime Executor MVP | runtime / core | Exécuter un sous-ensemble de `SceneRuntimePlan`. |
| NS-SCENES-V1-20 — Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Préparer le slice Lysa/rival sans hardcode produit. |
| NS-SCENES-V1-21 — StorylineStep to Scene Link | core / editor | Lien StoryStep -> Scene après builder/triggers/runtime MVP. |

## Prochain lot exact

```text
NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
```

Pourquoi : avant de rendre les boutons de palette actifs, il faut décider quels nodes V0 sont ajoutables, quels payloads sont valides en draft, quels ports existent, et comment éviter les références Yarn/Battle/Cinematic fictives.

## Impact sur Selbrume golden slice

Le slice cible :

```text
Parler à Lysa au port
→ Event vérifie Step active + Rival pas battu
→ Scene “Rencontre rival”
→ Dialogue Yarn “rival_intro”
→ Outcome confident / hesitant / aggressive
→ Cinematic différente selon outcome
→ Combat Rival
→ Outcome victory / defeat
→ Fact persistant
→ Step completed
→ World Rule change Lysa
→ Quête annexe disponible
→ Validator confirme atteignabilité
```

Lots nécessaires avant ce slice :

- V1-12 Node Authoring V0.
- V1-13 Edge Authoring V0.
- V1-15 Scene Runtime Plan V0.
- V1-16 Payload Pickers V0.
- V1-17 Diagnostics Expansion.
- V1-18 Event to Scene Trigger Prep.
- V1-19 Scene Runtime Executor MVP.

Peut attendre après :

- StorylineStep -> Scene Link complet.
- World Rule editor complet.
- Fact registry avancé.
- Cinematic builder avancé si une fixture cinematic contrôlée suffit.

## Risques

- Trop avancer le runtime sans builder utile.
- Trop avancer le builder sans contrat runtime.
- Rendre Yarn/Battle/Cinematic ajoutables avec IDs libres ou fake refs.
- Brancher StorylineStep trop tôt et confondre progression narrative avec déclencheur.
- Brancher Event -> Scene sur un legacy event model sans décision explicite.

## Non-objectifs

- Pas de code.
- Pas de widget.
- Pas de modèle.
- Pas de runtime.
- Pas d'authoring.
- Pas de migration.
- Pas de modification `ProjectManifest`.
- Pas de modification `SceneAsset`.
- Pas de `StorylineStep.sceneLinkIds`.
- Pas de seed Selbrume.
- Pas de scène `Annonce au port`.
- Pas de Maël, Lysa ou Port hardcodés.
- Pas de fake data.

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers modifiés

- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Tests / analyze

Tests Dart : non requis.

Sortie :

```text
Non exécuté : lot documentation-only, aucun code Dart modifié.
```

Tests Flutter : non requis.

Sortie :

```text
Non exécuté : aucun widget Flutter modifié.
```

Analyze : non requis.

Sortie :

```text
Non exécuté : aucun code modifié.
```

## Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

## Git diff --stat initial

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

## Git log initial

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
```

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
?? reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 reports/narrativeStudio/scenes/road_map_scenes.md | 36 ++++++++++++++++++++---
 1 file changed, 32 insertions(+), 4 deletions(-)
```

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check final

Commande :

```bash
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

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_06_graph_read_only_skeleton.md
reports/narrativeStudio/scenes/ns_scenes_v1_06_bis_graph_read_only_fallback_layout_hardening.md
reports/narrativeStudio/scenes/ns_scenes_v1_07_node_inspector_read_only.md
reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md
reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Contenu complet des fichiers Markdown créés

#### reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md

Contenu complet : le présent document.

#### reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md

````markdown
# NS-SCENES-V1 — Roadmap Scene Builder Authoring

## Verdict

Roadmap recommandee : **Option C hybride**, avec priorite immediate au Scene Builder Blueprint-like.

Le runtime reste indispensable, mais le prochain blocage produit est plus basique : une personne peut creer une scene draft, mais ne peut pas encore construire visuellement une scene. La suite doit donc poser l'authoring graph avant de brancher Storylines ou d'executer en jeu.

## Prochain lot exact recommande

```text
NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
```

## Principes

- Scene Builder doit devenir un outil Blueprint-like : palette, nodes, ports, edges, payloads, diagnostics.
- Aucun node actif ne doit cacher une fake ref.
- Yarn, battle et cinematic ne deviennent ajoutables que si leur payload draft est honnete ou si un picker existe.
- Runtime ignore toujours `SceneGraphLayout`.
- `ScenarioAsset` reste legacy/bridge, pas modele produit final.
- `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.

## Roadmap recommandee

| ID | Titre | Type | Objectif | Non-objectifs | Fichiers probables | Tests attendus | Risques | Criteres d'acceptation | Dependances |
|---|---|---|---|---|---|---|---|---|---|
| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change sauf recommandation. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | Liste claire des node drafts V0, ports, payloads autorises/interdits, prochain lot authoring. | V1-10-bis. |
| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si payloads trop vides ; UI trop proche d'un builder complet. | Nodes autorises ajoutables, selection auto, inspector read-only ou draft, diagnostics mis a jour. | V1-11. |
| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer/supprimer edges simples, valider compatibilite. | Pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scene_graph_read_only_view.dart` evolue en graph draft view, tests. | Tests fromPortId, edge kind, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | Edge cree depuis port explicite, diagnostics edge visibles, aucun edge implicite par proximite. | V1-12. |
| NS-SCENES-V1-14 | Layout Authoring V0 | editor | Deplacer nodes et persister `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap avancee, pas de auto-route edges final. | graph view, layout operations, widget tests. | Tests drag/persist layout, fallback non persiste, runtime data inchangee. | Coupler layout et runtime ; churn de diffs. | Positions stables sauvegardees, layout incomplet reste warning, aucun effet runtime. | V1-13. |
| NS-SCENES-V1-15 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-13 ou V1-14. |
| NS-SCENES-V1-16 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-12, V1-15 utile. |
| NS-SCENES-V1-17 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-13, V1-16. |
| NS-SCENES-V1-18 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-15, V1-17. |
| NS-SCENES-V1-19 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/action simple/dialogue handoff minimal. | Pas de full battle/cinematic si non pret, pas StorylineStep link. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-15, V1-17. |
| NS-SCENES-V1-20 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-18, V1-19, payloads/diagnostics. |
| NS-SCENES-V1-21 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-18, V1-19, V1-20. |

## Options comparees

| Option | Verdict | Raison |
|---|---|---|
| A — Continuer directement RuntimePlan puis StorylineStep | Rejetee | RuntimePlan seul ne rend pas le builder utilisable ; StorylineStep link trop tot confond progression et declencheur. |
| B — Basculer uniquement graph authoring | Rejetee partiellement | Aligne bien Blueprint-like, mais risque de creer des graphes sans contrat runtime. |
| C — Hybride Blueprint + runtime plan | Retenue | Donne vite un builder utile, garde runtime plan proche, puis enchaine Event -> Scene avant StorylineStep. |
| D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |

## Selbrume golden slice

Avant le golden slice, il faut au minimum :

- Node Authoring V0.
- Edge Authoring V0.
- Payload Pickers V0 pour Yarn, battle, cinematic/action.
- Diagnostics Expansion.
- Scene Runtime Plan V0.
- Event to Scene Trigger Prep.
- Scene Runtime Executor MVP.

Peut attendre apres le slice :

- StorylineStep -> Scene Link complet.
- World Rule editor complet.
- Fact registry avance.
- Cinematic editor avance si une cinematic fixture controlee suffit.
````

### Diff complet de road_map_scenes.md

````diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 2bb57176..1396a697 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -47,14 +47,42 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-08 — Authoring Minimal Scene Draft | DONE | Creation d'une SceneAsset draft minimale depuis le workspace Scenes, ajout en memoire dans `ProjectManifest.scenes`, selection auto et graph/inspector read-only. |
 | NS-SCENES-V1-09 — Scene Validation Diagnostics | DONE | Diagnostics Scene V1 purs dans `map_core` et affichage editor : erreurs/warnings de graph, layout et outcomes, sans mutation ni correction automatique. |
 | NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
-| NS-SCENES-V1-11 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
-| NS-SCENES-V1-12 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres plan runtime Scene V1 stable et strategie de triggers clarifiee. |
+| NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment | DONE | Roadmap reconcilee : priorite au Scene Builder Blueprint-like, runtime plan conserve mais decale apres authoring graph minimal. |
+| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | TODO | Definir les nodes ajoutables, payload drafts, ports et limites pour eviter les fausses refs avant l'authoring actif. |
+| NS-SCENES-V1-12 — Node Authoring V0 | TODO | Ajouter une palette de nodes et l'ajout read/write de nodes draft dans le graph Scene, sans payload picker avance. |
+| NS-SCENES-V1-13 — Edge Authoring V0 | TODO | Permettre la connexion explicite des ports/nodes avec validation de compatibilite, sans runtime. |
+| NS-SCENES-V1-14 — Layout Authoring V0 | TODO | Permettre le deplacement des nodes et la persistence de `SceneGraphLayout`, sans impact runtime. |
+| NS-SCENES-V1-15 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
+| NS-SCENES-V1-16 — Payload Pickers V0 | TODO | Ajouter les pickers Yarn, cinematic, battle/action refs et limiter les IDs libres. |
+| NS-SCENES-V1-17 — Diagnostics Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles et payloads incomplets. |
+| NS-SCENES-V1-18 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume. |
+| NS-SCENES-V1-19 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
+| NS-SCENES-V1-20 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
+| NS-SCENES-V1-21 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers et runtime MVP stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-11 — Scene Runtime Plan V0`
+`NS-SCENES-V1-11 — Scene Graph Draft Node Strategy`
 
-Raison : V1-10 tranche la strategie runtime sans coder l'execution. Le prochain blocage n'est pas `StorylineStep.sceneLinkIds`, mais un plan runtime pur et testable qui transforme une `SceneAsset` valide en intents executables, sans layout, sans Flutter et sans conversion automatique en `ScenarioAsset`.
+Raison : V1-10 tranche la strategie runtime, mais le Scene Builder ne permet pas encore de construire une scene. Avant de coder une palette ou des connexions, il faut definir les node drafts autorises, leurs ports, leurs payloads minimaux et les garde-fous anti-fake refs. Le `SceneRuntimePlan` reste necessaire, mais il vient apres un authoring graph minimal.
+
+## Decisions V1-10-bis
+
+- Option recommandee : roadmap hybride orientee Blueprint-like.
+- Ne pas continuer directement vers `StorylineStep to Scene Link`.
+- Ne pas faire `SceneRuntimePlan V0` immediatement si le builder ne sait toujours pas creer de graph utile.
+- Inserer d'abord `Scene Graph Draft Node Strategy`, puis `Node Authoring V0`, `Edge Authoring V0`, `Layout Authoring V0`.
+- Conserver `SceneRuntimePlan V0` tot dans la suite, mais apres les premiers lots d'authoring graph.
+- Placer `Event -> Scene Trigger Prep` avant `StorylineStep -> Scene Link`, car Selbrume demarre surtout les scenes depuis des events de map.
+- Garder `StorylineStep.sceneLinkIds` desactive jusqu'a builder + triggers + runtime MVP stabilises.
+- La roadmap detaillee Blueprint-like vit aussi dans `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.
+
+## Limites V1-10-bis
+
+- Documentation-only : aucun code, widget, modele ou runtime.
+- Aucun node authoring n'est ajoute.
+- Aucun event trigger n'est branche.
+- Aucun seed Selbrume ni scene de reference n'est cree.
 
 ## Decisions V1-10
````

### Diff complet de road_map_scene_builder_authoring.md

````diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
new file mode 100644
--- /dev/null
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -0,0 +1,72 @@
+# NS-SCENES-V1 — Roadmap Scene Builder Authoring
+
+## Verdict
+
+Roadmap recommandee : **Option C hybride**, avec priorite immediate au Scene Builder Blueprint-like.
+
+Le runtime reste indispensable, mais le prochain blocage produit est plus basique : une personne peut creer une scene draft, mais ne peut pas encore construire visuellement une scene. La suite doit donc poser l'authoring graph avant de brancher Storylines ou d'executer en jeu.
+
+## Prochain lot exact recommande
+
+```text
+NS-SCENES-V1-11 — Scene Graph Draft Node Strategy
+```
+
+## Principes
+
+- Scene Builder doit devenir un outil Blueprint-like : palette, nodes, ports, edges, payloads, diagnostics.
+- Aucun node actif ne doit cacher une fake ref.
+- Yarn, battle et cinematic ne deviennent ajoutables que si leur payload draft est honnete ou si un picker existe.
+- Runtime ignore toujours `SceneGraphLayout`.
+- `ScenarioAsset` reste legacy/bridge, pas modele produit final.
+- `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.
+
+## Roadmap recommandee
+
+| ID | Titre | Type | Objectif | Non-objectifs | Fichiers probables | Tests attendus | Risques | Criteres d'acceptation | Dependances |
+|---|---|---|---|---|---|---|---|---|---|
+| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change sauf recommandation. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | Liste claire des node drafts V0, ports, payloads autorises/interdits, prochain lot authoring. | V1-10-bis. |
+| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si payloads trop vides ; UI trop proche d'un builder complet. | Nodes autorises ajoutables, selection auto, inspector read-only ou draft, diagnostics mis a jour. | V1-11. |
+| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer/supprimer edges simples, valider compatibilite. | Pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scene_graph_read_only_view.dart` evolue en graph draft view, tests. | Tests fromPortId, edge kind, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | Edge cree depuis port explicite, diagnostics edge visibles, aucun edge implicite par proximite. | V1-12. |
+| NS-SCENES-V1-14 | Layout Authoring V0 | editor | Deplacer nodes et persister `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap avancee, pas de auto-route edges final. | graph view, layout operations, widget tests. | Tests drag/persist layout, fallback non persiste, runtime data inchangee. | Coupler layout et runtime ; churn de diffs. | Positions stables sauvegardees, layout incomplet reste warning, aucun effet runtime. | V1-13. |
+| NS-SCENES-V1-15 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-13 ou V1-14. |
+| NS-SCENES-V1-16 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de full editor payload, pas de runtime. | workspace Scenes, inspector draft controls, projection refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main. | Node payloads configurables avec vraies refs ou drafts clairement invalides. | V1-12, V1-15 utile. |
+| NS-SCENES-V1-17 | Diagnostics Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles. | Pas de correction auto, pas de Validator global complet. | `scene_diagnostics.dart`, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide. | V1-13, V1-16. |
+| NS-SCENES-V1-18 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-15, V1-17. |
+| NS-SCENES-V1-19 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/action simple/dialogue handoff minimal. | Pas de full battle/cinematic si non pret, pas StorylineStep link. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-15, V1-17. |
+| NS-SCENES-V1-20 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-18, V1-19, payloads/diagnostics. |
+| NS-SCENES-V1-21 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-18, V1-19, V1-20. |
+
+## Options comparees
+
+| Option | Verdict | Raison |
+|---|---|---|
+| A — Continuer directement RuntimePlan puis StorylineStep | Rejetee | RuntimePlan seul ne rend pas le builder utilisable ; StorylineStep link trop tot confond progression et declencheur. |
+| B — Basculer uniquement graph authoring | Rejetee partiellement | Aligne bien Blueprint-like, mais risque de creer des graphes sans contrat runtime. |
+| C — Hybride Blueprint + runtime plan | Retenue | Donne vite un builder utile, garde runtime plan proche, puis enchaine Event -> Scene avant StorylineStep. |
+| D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |
+
+## Selbrume golden slice
+
+Avant le golden slice, il faut au minimum :
+
+- Node Authoring V0.
+- Edge Authoring V0.
+- Payload Pickers V0 pour Yarn, battle, cinematic/action.
+- Diagnostics Expansion.
+- Scene Runtime Plan V0.
+- Event to Scene Trigger Prep.
+- Scene Runtime Executor MVP.
+
+Peut attendre apres le slice :
+
+- StorylineStep -> Scene Link complet.
+- World Rule editor complet.
+- Fact registry avance.
+- Cinematic editor avance si une cinematic fixture controlee suffit.
````

## Auto-review critique

- Le lot ne modifie aucun code : conforme au scope.
- La roadmap ne part pas dans le runtime seul : elle répond au besoin Blueprint-like.
- `SceneRuntimePlan V0` n'est pas supprimé ; il est repositionné après les premiers lots qui rendent le graph authorable.
- `Event -> Scene` passe avant `StorylineStep -> Scene`, cohérent avec Selbrume.
- Risque : la roadmap est plus longue, mais elle évite de livrer un lien narratif vers des scènes non construites ou non déclenchables.

## Regard critique sur le prompt

Le prompt corrige utilement la trajectoire V1-10 : runtime prep était sain techniquement, mais insuffisant pour le besoin auteur. La demande de comparer les options évite de choisir par inertie. Le point le plus important est la distinction Step vs Event : la Story Step représente la progression, l'Event déclenche la scène.

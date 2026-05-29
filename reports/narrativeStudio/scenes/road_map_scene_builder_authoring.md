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

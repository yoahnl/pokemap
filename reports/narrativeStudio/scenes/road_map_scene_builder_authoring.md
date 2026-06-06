# NS-SCENES-V1 — Roadmap Scene Builder Authoring

## Verdict

Roadmap recommandee : **Option C hybride**, avec priorite immediate au Scene Builder Blueprint-like.

Le runtime reste indispensable, mais le prochain blocage produit est plus basique : une personne peut creer une scene draft, mais ne peut pas encore construire visuellement une scene. La suite doit donc poser l'authoring graph avant de brancher Storylines ou d'executer en jeu.

## Prochain lot exact recommande

```text
NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract
```

## Principes

- Scene Builder doit devenir un outil Blueprint-like : palette, nodes, ports, edges, payloads, diagnostics.
- Aucun node actif ne doit cacher une fake ref.
- Yarn, battle et cinematic ne deviennent ajoutables que si leur payload draft est honnete ou si un picker existe.
- Runtime ignore toujours `SceneGraphLayout`.
- `ScenarioAsset` reste legacy/bridge, pas modele produit final.
- `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.
- Une Condition no-code doit lire une source metier explicite ; pas de condition textuelle magique ni de flag technique expose comme experience principale.
- Les Facts et World Rules doivent etre cadres avant le golden slice, meme si le premier authoring Condition peut rester limite aux sources existantes.

## Roadmap recommandee

| ID | Titre | Type | Objectif | Non-objectifs | Fichiers probables | Tests attendus | Risques | Criteres d'acceptation | Dependances |
|---|---|---|---|---|---|---|---|---|---|
| NS-SCENES-V1-11 | Scene Graph Draft Node Strategy | doc-only / planning | Definir nodes ajoutables, defaults, ports, payload drafts, restrictions anti-fake refs. | Pas de UI, pas de runtime, pas de model change. | `reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md`, roadmap. | Non requis hors `git diff --check`. | Trop de doc, ou inversement palette codee trop tot. | DONE : Condition, Merge et Fin ajoutables V0 ; Yarn/Action/Battle/Cinematic/Branch desactives jusqu'aux refs/payloads honnetes. | V1-10-bis. |
| NS-SCENES-V1-12 | Node Authoring V0 | core / editor | Ajouter palette minimale et creation de nodes draft `condition`, `merge`, `end` dans `ProjectManifest.scenes` en memoire. | Pas de edge authoring avance, pas de pickers refs, pas de runtime, pas de nodes Yarn/Action/Battle/Cinematic/Branch actifs. | `scene_authoring_operations.dart`, `scenes_workspace.dart`, tests Scenes. | Tests core operations + widget palette/add node + no fake refs. | Nodes inutilisables si diagnostics trop faibles ; UI trop proche d'un builder complet. | DONE : nodes V0 ajoutables, selection auto, inspector read-only/draft, nodes desactives honnetes, aucun edge automatique. | V1-11. |
| NS-SCENES-V1-13 | Edge Authoring V0 | core / editor | Connecter explicitement ports/nodes, creer des edges simples, valider compatibilite. | Pas de suppression, pas de drag complexe, pas de runtime, pas de auto-layout final. | operations core edges, `scenes_workspace.dart`, tests. | Tests fromPortId, edge kind derive, incompatibilites, ProjectManifest non touche hors scenes. | Branches implicites, edges invalides, UX de connexion trop lourde. | DONE : edge cree depuis port explicite, no duplicate source port, aucun edge implicite par proximite. | V1-12. |
| NS-SCENES-V1-14 | Blueprint Graph Canvas Foundation / Layout Authoring V0 | core / editor | Ajouter grille, zoom boutons + pinch trackpad, pan, drag node et persistence memoire de `SceneGraphLayout` sans modifier le graph logique. | Pas de runtime, pas de minimap, pas de ports graphiques complexes, pas de cable tire a la souris. | `scene_authoring_operations.dart`, graph view, workspace Scenes, widget tests. | Tests update layout, zoom/reset, pinch trackpad non mutant, pan local, drag/persist layout, nodes/edges inchanges, edge visible apres deplacement. | Coupler layout et runtime ; gestes ambigus avec connexion V1-13 ; churn de diffs. | DONE : positions sauvegardees en memoire, zoom/pan locaux, edges suivent les nodes, aucun effet runtime. | V1-13. |
| NS-SCENES-V1-15 | Visual Port Connection UX V0 | editor | Transformer la connexion V1-13 en interaction Blueprint-like : ports visibles, preview wire, highlight/snap, drop sur input. | Pas de runtime, pas de suppression/reconnexion avancee, pas de ports complexes pour nodes desactives. | graph canvas, node cards, connection state tests. | DONE : ports visibles, drag output, preview line, target highlight, drop valide cree edge, drop vide annule. | Reintroduire drag-and-drop trop large ; rendre actifs des nodes sans payload honnete. | DONE : connexion visuelle claire, toujours basee sur ports V0, aucune fake ref. | V1-14. |
| NS-SCENES-V1-15-bis | Edge Selection / Deletion UX V0 | core / editor | Rendre les liens corrigibles : selection locale d'edge, highlight, inspecteur de lien, suppression memoire. | Pas de reconnexion avancee, pas de payload picker, pas de runtime, pas d'edition de condition. | `scene_authoring_operations.dart`, graph view, inspector, workspace Scenes. | Tests remove edge core, selection/highlight inspector, suppression, nodes/layout preserves, creation V1-15 apres suppression. | Supprimer trop large ; casser les ports visuels ou selection node ; confondre edge layout et graph logique. | DONE : edge selectionnable et supprimable, ProjectManifest.scenes mis a jour en memoire, aucune fake ref. | V1-15. |
| NS-SCENES-V1-16-prep | Condition Sources / Facts / World Rules Roadmap Review | doc-only / architecture-review | Decider si Condition Authoring peut commencer sans cadrer Facts, World Rules et sources conditionnelles. | Pas de code, pas de widget, pas de modele, pas de runtime. | rapport V1-16-prep, roadmaps. | `git diff --check` uniquement. | Rester trop abstrait ou bloquer inutilement l'authoring. | DONE : option hybride retenue, prochain lot exact defini, roadmaps ajustees. | V1-15-bis. |
| NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport V1-16, roadmaps. | `git diff --check` uniquement. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | DONE : sources V0 autorisees/reportees, contrat conceptuel, operateurs, diagnostics et pickers definis. | V1-16-prep. |
| NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | DONE : condition configurable via source structuree explicite, diagnostics bloquants si incomplete, picker limite aux refs existantes. | V1-16. |
| NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest`, operations facts, picker Condition, tests serialization/diagnostics. | DONE : tests registry JSON, operations pures, picker Fact, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | DONE : Facts lisibles stockes dans `ProjectManifest.facts`, refs stables, picker prioritaire, fallback technique conserve. | V1-16, V1-17. |
| NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de modele, pas de runtime, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | DONE : `git diff --check`. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | DONE : sources, targets, effets, stockage, priorites et diagnostics definis. | V1-18. |
| NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
| NS-SCENES-V1-20-bis | Roadmap Checkpoint Correction | doc-only / roadmap | Corriger l'aiguillage post V1-20 : inserer le checkpoint Narrative Studio demande et eviter de lancer V1-21 automatiquement. | Pas de code, pas de widget, pas de modele, pas de tests, pas de screenshots. | roadmaps + rapport bis. | `git diff --check` uniquement. | Continuer vers runtime sans relire la vision produit ; laisser V1-21 comme prochain implicite. | DONE : V1-20 reste DONE, prochain lot exact devient V1-20-checkpoint, V1-21 reste candidat post-checkpoint, note Facts overview ajoutee. | V1-20. |
| NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite apres World Rules V0. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | DONE : `git diff --check`. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | DONE : Payload Pickers V0 retenu comme V1-21, trajectoire Selbrume revalidee. | V1-20-bis. |
| NS-SCENES-V1-21-prep | Linked Asset Public Contracts Audit | doc-only / architecture-review | Auditer Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et BranchByOutcome avant les pickers. | Pas de code, pas de widget, pas de modele, pas de tests, pas de build_runner. | rapport V1-21-prep, roadmaps. | DONE : `git diff --check`. | Lancer des pickers d'IDs bruts ; confondre contrats publics et implementation interne. | DONE : contrats publics recommandes, node verdicts, V1-21 ajuste vers Linked Asset Contracts V0. | V1-20-checkpoint. |
| NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | DONE : tests contrats/read models purs + `dart analyze`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | DONE : Dialogue/Battle/Cinematic bridge exposent contrats publics ; Action/Branch restent disabled. | V1-21-prep. |
| NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes en consommant les contrats publics : Dialogue Yarn et Battle trainer V0 ; Cinematic bridgeOnly reste desactive prudemment. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal, pas d'Action/Branch actifs. | workspace Scenes, operations authoring, tests Scene Builder. | DONE : tests pickers refs reelles, diagnostics visibles, outcomes Yarn non inventes, battle victory/defeat, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | DONE : Dialogue/Battle configurables avec vraies refs, Cinematic/Action/Branch restent honnetement desactives, aucun fake ref. | V1-21. |
| NS-SCENES-V1-23 | Event to Scene Trigger Prep | doc / architecture-review | Auditer les events existants et decider le contrat minimal Event local -> Scene V1. | Pas de modele persiste, pas de generated files, pas de runtime, pas de StorylineStep link, pas de migration ScenarioAsset. | rapport V1-23, roadmaps. | DONE : `git diff --check`. | Coder trop vite un champ `sceneId` au mauvais niveau ; recreer un script cache. | DONE : decision `startScene` page/action retenue, implementation reportee a un bis. | V1-21, V1-22. |
| NS-SCENES-V1-23-bis | Event to Scene Link V0 | core / editor | Implementer le lien authoring persistant minimal `MapEventPage -> Scene V1` avec refs reelles, diagnostics et UI/picker bornes, sans execution runtime. | Pas de SceneRuntimePlan, pas de runtime Scene, pas de StorylineStep link, pas de ScenarioAsset final, pas de fake event/scene. | `map_event_definition.dart`, operations map events, validators/diagnostics, event properties panel, tests. | DONE : JSON/ops/validator/diagnostics/editor cible ; scene existante OK, scene manquante error, event sans scene OK, refs legacy non promues. | Toucher Freezed/JSON/generated ; melanger script/message/scene ; rendre le runtime implicite. | DONE : un event/page peut cibler une Scene reelle de facon visible et validable, sans execution. | V1-23. |
| NS-SCENES-V1-24 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, `scene_runtime_plan_builder.dart`, tests core. | DONE : start/end/condition/merge/dialogue/battle/cinematic intents, diagnostics Scene error bloque, Action/Branch unsupported, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | DONE : plan pur testable, ignore layout, refuse scenes invalides et nodes unsupported, aucun runtime. | V1-22, V1-23 utile. |
| NS-SCENES-V1-25 | Diagnostics / Validator Expansion | core / editor | DONE : diagnostics refs projet, ports V0, duplicates, unreachable/cycles et Event -> Scene readiness renforces. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, `event_scene_link_diagnostics.dart`, tests diagnostics/runtime-plan. | DONE : tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | DONE : erreurs runtime bloquantes explicites, warnings authoring conserves pour drafts, builder runtime-plan reste pur. | V1-22, V1-23, V1-24. |
| NS-SCENES-V1-25-bis | Dialogue/Battle Ports Authoring V0 | core / editor | Rendre `yarnDialogue.completed` et `battle.victory/defeat` authorables, diagnostiques et connectables visuellement avant runtime executor. | Pas de runtime Scene, pas de parsing Yarn, pas de BranchByOutcome authoring, pas de Cinematic/Action ports nouveaux, pas de Selbrume. | `scene_authoring_operations.dart`, `scene_diagnostics.dart`, runtime-plan tests, graph view, Scenes widget tests, screenshot V1-25-bis. | DONE : ports authorables, edges derives, diagnostics warning/error, runtime-plan preserve, canvas drag/drop Dialogue/Battle, visual gate. | Inventer des outcomes Yarn ; rendre le battle runtime-aware ; ouvrir Branch trop tot. | DONE : Dialogue et Battle deviennent branchables sans fake refs, sans execution et sans nouveau moteur. | V1-22, V1-24, V1-25. |
| NS-SCENES-V1-26 | Scene Runtime Executor MVP | core | DONE : executer un sous-ensemble `SceneRuntimePlan` via callbacks limites condition/dialogue/cinematic/battle, avec trace, erreurs et `maxSteps`. | Pas de branchement PlayableMapGame, pas Event -> Scene runtime, pas de ScenarioAsset, pas de consequences persistantes. | `scene_runtime_executor.dart`, tests executor. | DONE : start/end/dialogue/battle/condition/merge/cinematic, erreurs transitions/callback/cycle, no layout/project. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites ; importer runtime/battle. | DONE : executor pur map_core, callbacks explicites, aucun ScenarioAsset canonique, aucun runtime map. | V1-24, V1-25, V1-25-bis. |
| NS-SCENES-V1-26-bis | Scene Runtime Executor Evidence & Review Hardening | review / evidence | Fermer V1-26 avec audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et Evidence Pack complet. | Pas de V1-27, pas de runtime map, pas de nouvelle feature, pas de ScenarioAsset, pas de consequences persistantes. | rapport V1-26-bis, roadmaps. | DONE : executor/test reproduits integralement dans le rapport, tests/analyze relances, `git diff --check` final. | Review trop legere sur un futur coeur runtime ; evidence incomplete. | DONE : V1-26 confirme, aucun runtime map branche, V1-27 reste TODO. | V1-26. |
| NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule read model, diagnostics, creation event V0. | DONE : read model cible pur, EventPropertiesPanel creation/toggle, EntityPropertiesPanel affichage/toggle, tests core/editor/analyze/visual gate. | World Rules inutilisables si seulement en overview ; UI trop large. | DONE : les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts ni brancher runtime. | V1-20, V1-25 utile. |
| NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | DONE : readiness core event -> scene -> Dialogue.completed -> Battle.victory/defeat -> fins, refs et World Rules authoring. | Mettre des donnees Selbrume dans le produit ; scope trop large. | DONE : slice neutre prouve la chaine, sans hardcode produit, sans runtime map. | V1-22, V1-23, V1-26, V1-27. |
| NS-SCENES-V1-28-bis | Event to Scene Runtime Hook V0 | runtime / integration | DONE : brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites. | Pas de consequences persistantes automatiques, pas de StorylineStep link, pas de ScenarioAsset, pas de seed produit. | `scene_event_runtime_hook.dart`, `scene_runtime_host_callbacks.dart`, `scene_runtime_hook_result.dart`, `playable_map_game.dart`, tests runtime cibles. | DONE : event page sans scene ignoree, scene manquante/diagnostics/plan invalides refuses, dialogue/battle executes via callbacks test, no ScenarioAsset, no mutation. | Brancher trop large ; appliquer World Rules/runtime consequences trop tot ; casser legacy events. | DONE : `sceneTarget` court-circuite message/script legacy de la meme page et lance un hook controle sans consequences persistantes. | V1-26, V1-28. |
| NS-SCENES-V1-28-ter | Scene Consequence Contract Prep | doc / architecture-review | DONE : cadrer les consequences persistantes Scene V1 apres le hook runtime : outcomes -> consequences explicites, Fact/event consumed, World Rules projection et gaps battle/dialogue. | Pas de consequence codee, pas de BranchByOutcome, pas de StorylineStep link, pas de ScenarioAsset final. | rapport V1-28-ter, roadmaps, audit callbacks runtime. | DONE : `git diff --check`, aucun test Dart/Flutter requis. | Coder des writes Fact/WorldRule trop tot ; oublier que battle result concret reste une seam runtime. | DONE : option ActionNode/Consequence V0 explicite retenue, V0 limite, writes runtime reportes. | V1-28-bis. |
| NS-SCENES-V1-28-quater | Scene Consequence Model V0 | core | DONE : ajouter un modele authoring pur de consequences Scene V1, porte par ActionNode/Consequence explicite, pour `setFact` et `markEventConsumed`. | Pas de runtime write, pas de World Rule application directe, pas de UI complete, pas de StorylineStep link, pas de battle adapter. | `scene_consequence.dart`, `scene_asset.dart`, `scene_diagnostics.dart`, tests model/JSON/diagnostics/runtime-plan. | DONE : tests JSON/model, diagnostics refs Fact/map/event, ActionNode typé encore bloque au runtime-plan, `dart analyze`. | Transformer ActionNode en mini-script ; ouvrir giveItem/storyStep trop tot. | DONE : consequences typées, lisibles, validables et non executées automatiquement. | V1-28-ter. |
| NS-SCENES-V1-28-quinquies | Scene Consequence Runtime Write V0 | runtime / integration | DONE : appliquer explicitement les consequences V0 au runtime via un seam controle. | Pas de World Rule direct apply, pas de battle adapter, pas de StorylineStep link, pas de giveItem/teleport. | `scene_consequence_runtime_writer.dart`, hook runtime Scene, executor/plan, tests no partial writes. | DONE : setFact true/false, markEventConsumed, no WorldRule direct apply, no writes when executor/write fails. | Ecrire trop tot dans GameState ; appliquer les World Rules au lieu de projeter ; coupler aux battle outcomes. | DONE : consequences V0 appliquees explicitement et atomiquement au runtime, sans effets magiques. | V1-28-quater. |
| NS-SCENES-V1-28-sexies | Battle Runtime Outcome Adapter V0 | runtime / integration | DONE : fournir au Scene runtime un vrai resultat battle awaitable `victory` / `defeat` pour suivre les ports BattleNode existants. | Pas de resultat invente, pas de StorylineStep link, pas de consequence supplementaire, pas de refonte battle. | `scene_battle_runtime_outcome_adapter.dart`, result, `PlayableMapGame`, hook tests. | DONE : adapter victory/defeat/failure, hook battle branches + consequences, core non-regression, analyzes. | Coupler Scene V1 aux internes battle ; court-circuiter le flow runtime existant ; inventer une victoire. | DONE : BattleNode avance sur un outcome runtime reel et testable, sans consequence ecrite par l'adapter. | V1-28-bis, V1-28-quinquies. |
| NS-SCENES-V1-28-septies | Dialogue Runtime Awaitable Adapter V0 | runtime / integration | DONE : rendre `showDialogue` awaitable pour que la Scene continue apres fermeture reelle du dialogue. | Pas d'outcomes Yarn inventes, pas de BranchByOutcome, pas de refactor Dialogue Studio. | `scene_dialogue_runtime_awaitable_adapter.dart`, result, `PlayableMapGame`, hook tests. | DONE : dialogue completed reel, failure propre, no consequence write partiel, pending hook prouve. | Laisser la Scene continuer trop tot ; confondre completed avec outcomes Yarn. | DONE : Dialogue.completed devient temporellement fiable depuis `DialogueOverlayComponent.onFinished`. | V1-28-bis, V1-28-sexies. |
| NS-SCENES-V1-28-octies | Golden Slice Runtime Smoke V0 | runtime / integration | DONE : prouver la chaine runtime controlee Event -> Scene -> Dialogue awaitable -> Battle outcome -> consequences commit. | Pas de StorylineStep link, pas de donnees Selbrume produit, pas de nouveaux payloads, pas de World Rule direct apply. | `scene_runtime_golden_slice_smoke_test.dart`, rapport, roadmaps. | DONE : smoke victory pending dialogue + battle victory + commit, smoke defeat, smoke failure no partial write, non-regressions hook/adapters/core. | Confondre smoke neutre et seed produit ; masquer un failure dialogue/battle. | DONE : chaine runtime complete prouvee avant `StorylineStep.sceneLinkIds`. | V1-28-bis, V1-28-quinquies, V1-28-sexies, V1-28-septies. |
| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables comme lien authoring/progression. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy, pas de completion Step runtime. | operations Storyline scene links, diagnostics/read model, Storylines workspace, tests. | DONE : JSON/ops/diagnostics/read model, UI picker scenes reelles, remove link, visual gate, analyzes. | Confondre step et trigger ; progression pilotant toute la scene. | DONE : StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28-octies. |
| NS-SCENES-V1-30 | Scene Node Payload Editing V0 | core / editor | Rendre les payloads Dialogue Yarn et Battle trainer corrigeables depuis l'inspecteur via contrats publics reels. | Pas d'outcomes Yarn, pas de BranchByOutcome, pas de Cinematic/Action avance, pas de runtime. | operations Scene payload, inspector Scenes, tests core/editor, visual gate. | DONE : operations pures, pickers Dialogue/Battle, update memoire `ProjectManifest.scenes`, tests/analyze, aucun fake ref. | Revenir a des IDs tapes a la main ; dupliquer les pickers ; modifier runtime. | DONE : refs Dialogue/Battle modifiables sans changer graph/layout/runtime et sans inventer d'outcomes. | V1-21, V1-22, V1-25-bis. |
| NS-SCENES-V1-30-bis | Scene Node Deletion UX V0 | core / editor | Permettre la suppression controlee des nodes Scene non-start depuis l'inspecteur. | Pas de reconnexion automatique, pas de runtime, pas de payload editing supplementaire, pas de suppression de scene/event/storyline. | `removeSceneNodeDraft`, inspector danger zone, tests core/editor, visual gate. | DONE : nodes non-start supprimables, edges entrants/sortants et layouts nettoyes, Start et dernier End proteges, confirmation destructive. | Supprimer le Start ; auto-reparer le graph ; masquer les diagnostics apres deletion. | DONE : graph corrigible sans fake refs, sans runtime et sans mutation hors `ProjectManifest.scenes`. | V1-15-bis, V1-25-bis, V1-30. |
| NS-SCENES-V1-31 | Scene Consequence Authoring UI V0 | core / editor | Exposer l'authoring no-code des consequences V0 `setFact` et `markEventConsumed` depuis ActionNode/inspector. | Pas de giveItem/warp/storyStep runtime, pas de World Rule direct apply, pas de BranchByOutcome. | inspector/action authoring, consequence pickers, tests diagnostics/runtime non-regression. | DONE : ActionNode consequence editable, refs Fact/map/event pickers, no fake refs, runtime write existant non casse. | Transformer ActionNode en script libre ; ecrire trop tot dans runtime depuis l'UI. | DONE : consequences V0 authorables proprement et validables avant checkpoint beta. | V1-28-quater, V1-28-quinquies, V1-30-bis. |
| NS-SCENES-V1-31-bis | Scene Consequence Runtime Evidence Sweep | review / evidence | Confirmer que V1-31 n'a pas casse runtime-plan, executor, hook runtime, writer consequences et golden smoke. | Pas de nouvelle feature, pas de code produit, pas de runtime nouveau, pas de checkpoint beta complet. | rapport V1-31-bis, roadmaps. | DONE : tests core/runtime/editor/analyze et anti-scope relances. | Confondre evidence sweep et nouveau lot runtime ; corriger hors scope. | DONE : V1-31 confirme, aucun 31-ter necessaire. | V1-31. |
| NS-SCENES-V1-32 | Scene V1 Beta Readiness Checkpoint | review / roadmap | Auditer l'etat beta Scene V1 apres authoring payloads, consequences, runtime hook et golden smoke. | Pas de nouveau node, pas de runtime additionnel, pas de modele, pas de migration. | rapport checkpoint, roadmaps, audit gaps. | DONE : tests/analyze cibles relances, readiness matrix, gap register, risques et prochain lot exact. | Continuer a coder sans verifier le systeme complet ; ignorer les limites UX/runtime. | DONE : beta controlee oui, golden-slice jouable complet non, prochain verrou persistance runtime. | V1-31. |
| NS-SCENES-V1-33 | Runtime State Persistence Gate V0 | runtime / integration | Prouver que les writes Scene V1 (`setFact`, `markEventConsumed`) survivent a save/reload et restent lisibles par Conditions/World Rules. | Pas de nouveau node, pas de payload picker, pas de projection World Rules runtime, pas de golden slice jouable complet. | `scene_runtime_state_persistence_gate_test.dart`, rapport, roadmaps. | DONE : Scene -> consequence write -> save -> reload -> condition/world rule source readable, regressions runtime ciblees. | Construire la projection monde avant d'avoir verrouille l'etat persistant ; confondre save generale et preuve Scene-specific. | DONE : gate save/reload Scene-specific vert, aucune production modifiee. | V1-32. |
| NS-SCENES-V1-34 | World Rules Runtime Projection Hook V0 | runtime / integration | Appliquer prudemment au runtime jouable les effets World Rules projetes depuis le `GameState` recharge, apres le verrou persistence V1-33. | Pas de nouvelle consequence, pas de Scene payload, pas de World Rule editor avance, pas de StorylineStep runtime trigger. | runtime world rule projection hook, map runtime tests, rapport. | DONE : projection fact/event consomme lue depuis GameState, application runtime bornee aux entites/events/dialogue override, non-mutation du manifest/map/state et regressions save/load. | Appliquer les World Rules trop largement ; confondre projection pure et mutation definitive du monde. | DONE : hook runtime pur + branchement presence/dialogue/event, sans mutation durable ni nouvelle consequence. | V1-33. |
| NS-SCENES-V1-35 | Facts & World Rules Manager UI V0 | editor / product | Donner un espace no-code dedie pour gerer Facts et World Rules au-dela des apercus contextuels, avec labels lisibles, diagnostics et navigation vers cibles. | Pas de runtime nouveau, pas de nouveaux effets, pas de Scene consequence supplementaire, pas de seed Selbrume. | manager Facts/World Rules, read models editor, tests widget, rapport. | DONE : read model pur, creation/edition/suppression Facts, creation/edition/toggle/suppression World Rules, diagnostics/usages, overview/sidebar, visual gate et analyzes. | Refaire un editeur de flags techniques ; dupliquer les panneaux contextuels map sans coherence. | DONE : Facts et Regles du monde actifs, aucun ID libre comme workflow principal, aucun runtime modifie. | V1-34. |
| NS-SCENES-V1-36 | Cinematic V1 Contract / Bridge Decision | doc / architecture-review | Decider le contrat Cinematic V1 canonique et la place du bridge Cutscene/Scenario avant Cinematics Library et Builder V2. | Pas de runtime cinematic nouveau, pas de refonte Cutscene Studio, pas de Scene payload supplementaire. | rapport V1-36, roadmaps, audit Cutscene/Scenario/Cinematic. | DONE : `git diff --check`, contrat tranche, frontieres legacy, prochain lot exact. | Promouvoir ScenarioAsset comme modele final ; coder une cinematic avant contrat. | DONE : CinematicAsset futur retenu, ScenarioAsset/Cutscene restent bridge legacy explicite. | V1-35. |
| NS-SCENES-V1-37 | CinematicAsset Core Model V0 | core / contract | Ajouter le modele core/storage/read contract minimal de Cinematic V1 lineaire et diagnostiquable. | Pas de Cinematic Builder V2, pas de runtime cinematic avance, pas de migration Cutscene/Scenario automatique, pas de SceneGraph bis. | `CinematicAsset`, `ProjectManifest.cinematics`, public contract, diagnostics/tests core. | DONE : JSON/manifest/read model/diagnostics/scene plan + analyze core. | Sur-modeliser la timeline ; convertir le legacy trop tot ; laisser des actions qui ecrivent le monde. | DONE : modele dedie stable, bridge legacy conserve, Scene peut viser canonical ou bridge explicite. | V1-36. |
| NS-SCENES-V1-38 | Cinematics Library V0 | editor / read-model | Rendre les CinematicAsset visibles, navigables et diagnostiques dans Narrative Studio. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy. | workspace/library Cinematics, liste, selection, metadata authoring, diagnostics/usages, overview/sidebar. | DONE : read model pur, Library editor, bridges legacy explicites, tests widget/read model, analyze editor/core cible, visual gate. | Confondre library avec Builder ; reactiver Cutscene Studio comme canonique. | DONE : cinematic assets visibles avant authoring avance, sans runtime ni migration. | V1-37. |
| NS-SCENES-V1-39 | Cinematic Scene Builder Picker V0 | core / editor | Ajouter/editer un `CinematicNode` depuis un picker `CinematicAsset` canonique et rendre `cinematic.completed` authorable. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy, pas de bridge selectionnable en workflow normal. | operations Scene cinematic, picker/inspector Scene Builder, diagnostics, tests core/editor, visual gate. | DONE : canonical-only, bridge legacy warning, completed port, tests/analyze, screenshot. | Promouvoir les bridges Scenario comme choix normal ; laisser entrer des cinematicId libres. | DONE : CinematicNode honnete, editable et connectable sans fake ref. | V1-38. |
| NS-SCENES-V1-40 | Cinematic Runtime Adapter V0 | runtime / integration | Remplacer l'ack cinematic bridge par un adapter awaitable qui resout un `CinematicAsset` canonique, attend une completion reelle et retourne `completed`. | Pas de Builder V2, pas de timeline editor UI, pas de migration ScenarioAsset, pas de playback visuel complet, pas d'effets gameplay depuis cinematic. | adapter cinematic runtime, result/request/player V0, wiring PlayableMapGame, tests hook no partial writes, rapport. | DONE : canonical awaitable, bridge legacy explicite, unknown failed, consequences post-cinematic commit apres completion, tests/analyze. | Continuer a ack immediatement ; traiter scenarioBridge comme canonical ; laisser une cinematic ecrire le monde. | DONE : pont runtime propre Scene -> CinematicAsset -> completed. | V1-39. |
| NS-SCENES-V1-41 | Cinematic Builder V0 Scope / Runtime Playback Contract | doc / architecture-review | Cadrer le futur Builder V0 et le futur contrat Runtime Playback avant de coder l'UI, la timeline, les blocs authorables ou le player visuel. | Pas de code Dart, pas de widget, pas de timeline editor, pas de playback visuel, pas de migration ScenarioAsset, pas d'effet gameplay cinematic. | rapport V1-41, roadmaps. | DONE : rapport contractuel, capability matrix, taxonomie blocs, frontieres anti-scope, `git diff --check`. | Coder le Builder trop tot ; refaire ScenarioAsset ; ouvrir branches/failures authorables ; laisser Cinematic ecrire le monde. | DONE : Builder V0 = assembleur lineaire sandboxe ; Runtime Playback V0/V1 = lecture bornee sans gameplay effect ; prochain lot shell seulement. | V1-40. |
| NS-SCENES-V1-42 | Cinematic Builder V0 Shell | editor / ui-shell | Ouvrir un shell Builder depuis la Cinematics Library pour un `CinematicAsset` canonique, avec zones read-only et navigation retour. | Pas de timeline editor, pas de mutation `ProjectManifest`, pas de preview runtime, pas de migration bridge, pas de modele core. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : Library -> Builder -> retour, bridge legacy exclu, palette/preview/deroule/inspecteur visibles, boutons inactifs, visual gate, analyze cible. | Confondre shell et authoring ; promouvoir bridge legacy ; laisser croire que la preview est jouable. | DONE : shell V0 lisible, strictement read-only et canonique-only. | V1-41. |
| NS-SCENES-V1-43 | Cinematic Timeline Read-only / Step Inspector V0 | editor / ui-readonly | Rendre le deroule du Builder inspectable : steps reels ordonnes, selection locale, inspecteur detaille lecture seule et diagnostics contextualises. | Pas de mutation de timeline, pas de modele core, pas de preview runtime, pas de migration bridge. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : liste steps, selection locale, inspecteur step, diagnostics, non-mutation, visual gate, analyze cible. | Confondre inspection et authoring ; dupliquer le read model core ; creer une selection persistante inutile. | DONE : Builder inspectable sans changer `ProjectManifest`, core ou runtime. | V1-42. |
| NS-SCENES-V1-44 | Cinematic Timeline Authoring Drafts V0 | core / editor | Ajouter un brouillon neutre dans le deroule Cinematic, l'inspecter et le retirer de facon bornee via operations pures. | Pas de vrais blocs metier, pas d'edition de champs, pas de player visuel, pas de runtime, pas de changement schema. | `cinematic_authoring_operations.dart`, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/remove draft purs, insertion apres selection ou fin, suppression refusee hors brouillon, mutation memoire, visual gate, analyses. | Laisser un brouillon produire un effet ; supprimer un vrai step ; confondre marker neutre et bloc moteur. | DONE : marker draft identifie par metadata, UI no-code bornee, non-regression core/editor prouvee. | V1-43. |
| NS-SCENES-V1-45 | Cinematic Wait/Fade/Camera Basic Blocks V0 | core / editor | Activer les premiers blocs metier simples du Cinematic Builder : Attente, Fondu et Camera basique. | Pas de deplacement acteur, pas de dialogue, pas de FX/Son, pas de preview runtime, pas de reordonnancement, pas de changement schema. | operations cinematic authoring, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/update/remove authoring-owned, presets duree, modes fade/camera, protections non-owned, visual gate, analyses. | Transformer les metadata authoring en API runtime ; ouvrir trop tot des cibles acteur/map. | DONE : blocs V0 bornes, canonical-only preserve, aucun runtime modifie. | V1-44. |
| NS-SCENES-V1-46 | Cinematic Actor References / Actor Facing V0 | core / editor | Ajouter les references acteur requises et un bloc Orientation acteur V0 dans le Cinematic Builder. | Pas de deplacement acteur, pas de chemin/pathfinding, pas de timeline multi-track, pas de drag/drop, pas de preview runtime, pas de dialogue/FX/Son. | operations cinematic authoring, diagnostics cinematic, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : acteurs requis, bloc `actorFace`, picker acteur, direction up/down/left/right, diagnostics acteur inconnu, visual gate, analyses. | Confondre orientation et mouvement ; exposer des ids acteur comme workflow principal ; ouvrir trop tot runtime/player. | DONE : actor refs et facing bornes, canonical-only preserve, aucun runtime modifie. | V1-45. |
| NS-SCENES-V1-47 | Cinematic Actor Movement Block V0 Prep / Contract | doc-only / architecture-review | Definir le contrat du futur bloc `actorMove` avant authoring : acteur, cible, duree, movementMode, pathMode, lane, diagnostics et frontieres runtime. | Pas de code Dart, pas de widget, pas de package modifie, pas de schema JSON, pas de actorMove authorable, pas de preview runtime. | rapport V1-47, roadmaps. | DONE : contrat V0, options target comparees, diagnostics cadres, roadmap post V1-47, checks anti-scope. | Coder actorMove trop tot ; creer une position libre non diagnostiquable ; lier le mouvement a un runtime implicite. | DONE : actorMove cadre sans implementation, prochain verrou lane grouping retenu. | V1-46. |
| NS-SCENES-V1-48 | Cinematic Timeline Lane Grouping V0 | core / editor | Transformer le deroule du Cinematic Builder en timeline par pistes derivees et testees. | Pas de lane persistante, pas de drag/drop, pas de reordonnancement, pas de `actorMove` authorable, pas de preview runtime. | `cinematic_timeline_lane_read_model.dart`, Builder cinematics, tests core/widget, rapport, screenshot. | DONE : lanes Camera/Acteurs/Dialogue/FX/Audio/Transitions/Temps/Autres, selection depuis lane, actions existantes preservees, Visual Gate, analyses. | Faire croire a un vrai multi-track parallele ; stocker un layout de lanes ; ouvrir actorMove trop tot. | DONE : timeline lisible comme pistes sans augmenter la puissance runtime/editor. | V1-47. |
| NS-SCENES-V1-49 | Cinematic Actor Movement Block V0 | core / editor | Rendre `actorMove` authorable via acteur requis, cible authoring stable, duree, marche/course et pathMode direct verrouille. | Pas de pathfinding, pas de coordonnees `x/y`, pas de cible runtime map/entity, pas de drag/drop, pas de reorder, pas de preview runtime. | `cinematic_asset.dart`, `cinematic_authoring_operations.dart`, `cinematic_diagnostics.dart`, `cinematic_timeline_lane_read_model.dart`, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : target refs JSON, operations cible, add/update actorMove, diagnostics refs/modes/duree, UI palette/inspector, Visual Gate, analyses. | Creer une fausse navigation runtime ; exposer des IDs techniques ou positions libres ; casser les lanes V1-48. | DONE : bloc deplacement acteur V0 authorable, validable et borne, sans runtime ni pathfinding. | V1-48. |
| NS-SCENES-V1-50 | Cinematic Actor Movement Inspector Polish / Target Labels V0 | core / editor | Polir `actorMove` sans l'elargir : labels/description de cibles editables, pickers plus lisibles, resume humain, timeline actorMove derivee. | Pas de time axis, pas de bar layout, pas de playhead, pas de drag/drop, pas de pathfinding, pas de runtime, pas de preview jouable. | `cinematic_timeline_lane_read_model.dart`, Builder/Library cinematics, `narrative_workspace_canvas.dart`, tests core/widget, rapport, screenshot. | DONE : target labels/description editables, suppression cible libre, cible utilisee protegee, actorMove labels derives, Visual Gate, analyses. | Transformer le polish en time axis ; muter `step.label` comme source runtime ; exposer `targetId` en UX principale. | DONE : actorMove plus lisible, stable par IDs, sans nouveau pouvoir moteur. | V1-49. |
| NS-SCENES-V1-51 | Cinematic Timeline Time Axis / Bar Layout V0 | core / editor | Transformer les lanes cinematic en projection temporelle lisible : axe, ticks, barres proportionnelles, durees explicites/fallback. | Pas de drag/drop, resize, reorder, playhead fonctionnel, scrubber, transport playback, runtime, pathfinding, coordonnees libres, persistance `startMs/endMs`. | `cinematic_timeline_time_layout_read_model.dart`, Builder cinematics, tests core/widget, rapport, screenshot 1663x926. | DONE : read model pur derive, ticks par duree totale, UI `Timeline par pistes`, barres proportionnelles, selection preservee, Visual Gate, analyses. | Faire croire a une timeline editable ou frame-perfect ; stocker du timing derive ; ouvrir le playback trop tot. | DONE : projection temporelle honnete, proportionnelle et non editable, sans nouveau pouvoir runtime. | V1-50. |
| NS-SCENES-V1-52 | Cinematic Timeline Selection Cursor / Playhead Placeholder V0 | editor / ui-readonly | Ajouter une aiguille de selection derivee du bloc selectionne dans la timeline temporelle. | Pas de playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, preview runtime, persistance cursor/playhead/start/end. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : badge `Selection`, curseur vertical + handle non interactifs, alignement sur `startMs`, tap axe sans seek, Visual Gate et analyses. | Faire croire a une lecture runtime ; transformer le repere en playhead de playback ; stocker une position temporelle. | DONE : aiguille de selection claire, non interactive et purement derivee. | V1-51. |
| NS-SCENES-V1-53 | Cinematic Timeline Transport Controls Placeholder V0 | editor / ui-readonly | Ajouter Reset / Play / Stop sous la timeline comme controles visuels placeholders. | Pas de playback, timer, seek, scrubber, transport fonctionnel, preview runtime, drag/drop, resize, reorder, mutation JSON, modification runtime. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : boutons disabled, selection/curseur preserves, aucune mutation ProjectManifest, Visual Gate et analyses. V1-56 les rend icon-only pour respecter les proportions finales. | Faire croire a un lecteur cinematic ; ajouter un etat de lecture ; deplacer le curseur depuis les boutons. | DONE : controles visibles, honnetes, non fonctionnels et bornes au Builder. | V1-52. |
| NS-SCENES-V1-54 | Cinematic Timeline Visual Polish / Density Pass V0 | editor / ui-polish | Polir la densite visuelle de la timeline : lanes, barres, labels, badges, spacing, controles transport et proportions preview/timeline. | Pas de playback, timer, seek, scrubber, hover details, drag/drop, resize, reorder, changement JSON, runtime ou model core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : lanes 28px, axe 24px, barres 22px, empty states courts, transport medium, metadata strip allegee, Visual Gate et analyses ciblees. | Confondre polish et edition temporelle ; reintroduire IDs bruts comme UX principale ; casser le ratio demande par Karim. | DONE : timeline plus dense et lisible sans nouveau pouvoir. | V1-53. |
| NS-SCENES-V1-55 | Cinematic Timeline Interaction Polish / Hover Details V0 | editor / ui-readonly | Ajouter une inspection legere au survol des barres de timeline. | Pas de playback, seek, scrubber, selection auto, drag/drop, resize, reorder, mutation JSON, runtime ou focus clavier avance. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : detail inline no-code, highlight hover, semantics, hover exit, selection/curseur/inspecteur preserves, ProjectManifest non mute, Visual Gate et analyses ciblees. | Confondre hover et selection ; creer un tooltip fragile ou un controle temporel implicite ; afficher des IDs techniques. | DONE : hover lisible et temporaire sans nouveau pouvoir. | V1-54. |
| NS-SCENES-V1-56 | Cinematic Timeline Bar Geometry / Duration Scale Correction V0 | editor / ui-readonly | Corriger la geometrie visuelle des barres et le ratio utile preview/timeline. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle ou focus clavier avance. | Builder cinematics, design system card, tests widget, rapport, screenshot 1663x926. | DONE : origine X commune ticks/barres/curseur, largeur par `visualDurationMs`, colonne pistes 128 px, labels complets sans meta parasite, rangées 48 px, barres 36 px, chrome compacte, hover overlay stable, transport icon-only, Visual Gate et analyses ciblees. | Confondre correction visuelle et edition temporelle ; deplacer le curseur ; stocker du layout derive ; laisser le sandbox ou les pistes ecraser la timeline. | DONE : barres temporelles rectangulaires, proportionnelles et non editables, avec timeline lisible, sans nouveau pouvoir. | V1-55. |
| NS-SCENES-V1-57 | Cinematic Timeline Keyboard Navigation / Selection Polish V0 | editor / ui-readonly | Ajouter une navigation clavier locale entre blocs de timeline par ordre lineaire. | Pas de navigation verticale par piste, pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle ou modele core. | Builder cinematics, design system card focus, tests widget, rapport, screenshot 1663x926. | DONE : ArrowRight/ArrowLeft/Home/End, demarrage premier/dernier sans selection, focus local timeline, TextField proteges, curseur/preview/inspecteur synchronises, Visual Gate et analyses ciblees. | Capturer les fleches globalement ; confondre selection avec seek/playhead ; casser les proportions V1-56. | DONE : selection clavier locale et non destructive, sans nouveau pouvoir runtime/editor. | V1-56. |
| NS-SCENES-V1-58 | Cinematic Timeline Lane Vertical Navigation Prep / Contract | doc-only / interaction-contract | Definir le contrat futur ArrowUp/ArrowDown avant implementation. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de raccourci actif, pas de runtime, pas de playback, seek, scrubber, drag/drop, resize, reorder ou mutation JSON. | Rapport V1-58, roadmaps. | DONE : options A/B/C/D comparees, Option B retenue, `centerMs`, lanes vides, bords, sans selection, tie-breaks et tests futurs documentes, checks anti-scope. | Coder la navigation verticale trop tot ; creer un seek spatial ambigu ; casser la navigation horizontale V1-57 ou les proportions V1-56. | DONE : contrat clair pour V1-59, sans nouvelle capability. | V1-57. |
| NS-SCENES-V1-59 | Cinematic Timeline Lane Vertical Navigation V0 | editor / ui-readonly | Implementer ArrowUp/ArrowDown selon le contrat Option B V1-58 : prochaine lane non vide, bloc cible par `centerMs` le plus proche. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle, nouvelle capability authoring ou modele core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : ArrowUp/ArrowDown locaux, lanes vides ignorees, bords stables, sans selection, timeline vide, tie-break distance/`stepIndex`, TextFields proteges, curseur/preview/inspecteur synchronises, Visual Gate et analyses ciblees. | Capturer les fleches globalement ; utiliser hover/pixels comme source ; confondre navigation verticale avec seek temporel ; casser V1-56/V1-57. | DONE : navigation verticale locale et non destructive, sans nouveau pouvoir runtime/editor temporel. | V1-58. |
| NS-SCENES-V1-60 | Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0 | editor / ui-polish | Remplacer le long badge clavier par une aide compacte locale qui explique les fleches, Home et End. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mouse playhead, mutation JSON, runtime, nouvelle capability temporelle ou modele core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : badge/bouton compact `Aide clavier`, panneau local toggle click, contenu horizontal/vertical/Home/End, mention selection-only, selection/curseur/inspecteur preserves, Visual Gate et analyses ciblees. | Faire croire a un scrubber ou playhead souris ; casser les proportions V1-56 ; melanger aide et statut. | DONE : aide clavier lisible et non intrusive, sans nouveau pouvoir timeline. | V1-59. |
| NS-SCENES-V1-61 | Cinematic Timeline Mouse Playhead / Scrub Prep Contract | doc-only / interaction-contract | Cadrer le futur playhead souris type Final Cut avant toute implementation. | Pas de code produit, pas de seek actif, pas de drag, pas de playback, pas de scrubber, pas de mutation JSON, pas de runtime. | Rapport V1-61, roadmaps. | DONE : Option B retenue, `Mouse Time Probe` local separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps, scroll/clamp/snap, tests futurs, checks anti-scope. | Coder le playhead trop tot ; transformer le curseur V1-52 en scrubber sans contrat ; promettre un playback non implemente. | DONE : contrat futur clair, aucune capability ajoutee. | V1-60. |
| NS-SCENES-V1-62 | Cinematic Timeline Mouse Time Probe / Playhead Drag V0 | editor / ui-readonly | Implementer le repere temporel souris local selon le contrat V1-61. | Pas de playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, mutation JSON, runtime, persistence temporelle ou model core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : click/drag axe/fond, clamp 0..totalDurationMs, scroll horizontal, selection/inspecteur preserves, probe clear sur selection bloc/clavier, hover/aide/clavier/transports preserves, non-mutation. | Confondre probe local et playback playhead ; deplacer les blocs ; casser V1-56/V1-57/V1-59/V1-60. | DONE : probe souris lisible et local, sans nouveau pouvoir runtime/editor temporel. | V1-61. |
| NS-SCENES-V1-63 | Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0 | doc / ui-polish-prep | Cadrer le polish futur du probe souris : lisibilite, bords, snap optionnel aux bornes, edge cases de scroll et libelles. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, implementation snap si le contrat reste ambigu. | Rapport V1-63, roadmaps. | DONE : Option E retenue, snap futur aux bords et starts/ends de blocs, seuil `8 px`, click/drag/release cadres, bords/scroll/fallback/tie-breaks/vocabulaire/tests futurs documentes. | Rendre le probe trop proche d'un playhead runtime ; introduire un snap saccade sans contrat. | DONE : contrat polish/snap clair avant implementation, sans code produit ni package modifie. | V1-62. |
| NS-SCENES-V1-64 | Cinematic Timeline Mouse Probe Boundary Snap V0 | editor / ui-readonly | Implementer le snap leger du repere souris selon le contrat V1-63. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, snap ticks, edition temporelle ou transport fonctionnel. | Builder cinematics, tests widget, rapport, screenshot. | DONE : snap 0/fin/starts/ends par seuil 8 px, badge aligne, scroll respecte, selection/inspecteur/projet preserves. | Confondre snap d'inspection et edition temporelle ; rendre le drag saccade ; casser V1-62. | DONE : snap local et reversible, sans nouveau pouvoir runtime/editor temporel. | V1-63. |
| NS-SCENES-V1-65 | Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0 | editor / ui-polish | Polir l'experience du repere souris snappe : controles d'effacement/retour au repere lisibles, libelles courts et etats vides. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, snap ticks, edition temporelle ou transport fonctionnel. | Builder cinematics, tests widget, rapport, screenshot. | DONE : clear local explicite `Effacer le repère`, micro-explication `Repère local : inspection uniquement.`, Escape local timeline, TextFields proteges, selection/inspecteur/projet preserves, transports disabled preserves. | Confondre clear du probe avec reset playback ; ajouter un controle de lecture ; casser les proportions timeline. | DONE : polish local et reversible du probe, sans nouveau pouvoir runtime/editor temporel. | V1-64. |
| NS-SCENES-V1-66 | Cinematic Timeline Mouse Probe Help / Selection Explanation V0 | editor / ui-polish | Expliquer clairement dans l'aide locale la difference entre `Selection` et `Repere`, et rappeler que le probe est une inspection non mutante. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | DONE : aide locale `Aide repère`, labels courts Selection/Repere/Alignement/Preview, selection/probe non ambigus, clear/Escape/aide clavier/transports preserves. | Transformer l'aide en tutoriel verbeux ; faire croire a un playhead runtime ; encombrer la timeline. | DONE : explication concise et no-code, sans nouveau pouvoir temporel. | V1-65. |
| NS-SCENES-V1-67 | Cinematic Timeline Duration Editing / Resize Prep Contract | doc-only / interaction-contract | Cadrer l'edition de duree des blocs cinematic avant implementation : `durationMs`, blocs authoring-owned, min/max, presets, relation avec layout derive, probe souris et resize futur. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de resize actif, pas de playback, pas de timeline libre, pas de `startMs/endMs` persistants. | Rapport V1-67, roadmaps. | DONE : contrat inspecteur V1-68 puis resize bord droit V1-69, checks anti-scope, aucun package modifie. | Coder le resize trop tot ; modifier des steps non-owned ; transformer la timeline lineaire en timeline libre. | DONE : Option C retenue, V1-68 et V1-69 cadres, scroll/visibility repousse en backlog V1-72. | V1-66. |
| NS-SCENES-V1-68 | Cinematic Timeline Duration Inspector Editing V0 | editor / authoring | Ajouter l'edition no-code de `durationMs` depuis l'inspecteur pour les blocs authoring-owned supportes. | Pas de resize souris, pas de drag de bloc, pas de playback, pas de seek runtime, pas de timeline libre, pas de `startMs/endMs` persistants. | Builder cinematics, operations authoring core, tests widget/core cibles, rapport, screenshot. | DONE : presets courts, champ numerique borne, +/-100, validation min/max core, `actorFace.durationMs`, recalcul layout derive, clear probe apres acceptation, non-owned non editables. | Ouvrir trop de blocs non possedes ; exposer JSON/IDs ; faire croire a un playback. | DONE : durees editables depuis l'inspecteur, non-mutation runtime, transports disabled. | V1-67. |
| NS-SCENES-V1-69 | Cinematic Timeline Duration Resize Handles V0 | editor / authoring | Ajouter un handle de resize uniquement sur le bord droit des barres editables, reutilisant les bornes et validations V1-68. | Pas de drag du bloc entier, pas de bord gauche, pas de changement de lane, pas de reorder, pas de playback, pas de `startMs/endMs` persistants. | Builder cinematics, tests widget drag/resize, rapport, screenshot si lot UI. | DONE : handle droit sur selection editable, augmentation/diminution, clamp min/max, snap 100 ms, clear probe, selection preservee, non-owned et marker sans handle. | Hit testing trop large ; confusion avec probe souris ; casser les proportions de timeline. | DONE : resize borne et lisible, sans timeline libre. | V1-68. |
| NS-SCENES-V1-70 | Cinematic Timeline Duration Validation / Diagnostics Polish V0 | editor / ui-polish | Consolider les messages d'erreur, bornes, feedback no-code et diagnostics autour de l'edition/resize de duree. | Pas de nouveau modele temporel, pas de playback, pas de seek runtime, pas de timeline libre, pas de drag/reorder de blocs. | Builder cinematics, diagnostics core, tests widget/core, rapport, screenshot. | DONE : aide bornes min/max/pas 100 ms, erreurs inline, feedback clamp, non-editables expliques, diagnostics duree renforces, Visual Gate. | Dupliquer la validation core ; transformer le polish en nouveau pouvoir de montage. | DONE : edition de duree plus explicite, sans elargir le contrat V1-68/V1-69. | V1-69. |
| NS-SCENES-V1-71 | Cinematic Stage / Map Context Prep Contract | doc / interaction-contract | Cadrer le contexte de scene cinematic avant preview reelle : map cible, decor, acteurs, bindings, positions initiales, cibles map-aware. | Pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de mutation gameplay, pas de donnees Selbrume codees. | Rapport V1-71, roadmaps, audit contrats map/actors. | DONE : option hybride retenue, mapId/backdropMode, actor bindings, initial placements, movement target bindings, diagnostics et tests futurs cadres. | Confondre contexte stage avec runtime preview ; coder les bindings trop tot ; hardcoder le golden slice. | DONE : prochain verrou produit map/acteurs/context explicite avant implementation. | V1-70. |
| NS-SCENES-V1-72 | Cinematic Stage / Map Context Core Model V0 | core / authoring | Implementer le modele authoring minimal du Stage Context dans CinematicAsset en reutilisant `CinematicAsset.mapId` comme seule ancre Stage Map, plus backdropMode, actorBindings, initialPlacements, movementTargetBindings et diagnostics core. | Pas d'UI lourde, pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de donnees Selbrume codees. | `cinematic_asset.dart`, diagnostics cinematic, tests JSON/diagnostics/authoring, rapport. | DONE : serialization, diagnostics stage/bindings/targets, drafts autorises, aucune mutation timeline. | Dupliquer `mapId` existant ; coder la preview trop tot ; bloquer les cinematics abstraites. | DONE : contrat V1-71 materialise en modele core minimal et diagnostiquable sans `stageContext.mapId`. | V1-71. |
| NS-SCENES-V1-73 | Cinematic Stage / Map Context Editor V0 | editor / authoring | Exposer le Stage Context V1-72 dans le Cinematic Builder/Library : map/backdrop, actor bindings, placements initiaux et target bindings via controles no-code. | Pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding, pas de coordonnees libres par defaut, pas de donnees Selbrume codees. | Builder cinematics, read models/pickers editor, tests widget, rapport, screenshot si UI. | DONE : edition stage context en memoire, diagnostics lisibles, timeline/sandbox preserves, no `stageContext.mapId`, Visual Gate 1663x926. | UI trop dense ; creer une fausse preview ; exposer IDs bruts au lieu de pickers. | DONE : Stage Context authorable cote editor sans elargir runtime ni casser les proportions timeline. | V1-72. |
| NS-SCENES-V1-74 | Cinematic Stage Context Diagnostics / Preview Readiness Polish V0 | editor / ui-polish | Rendre le Stage Context comprehensible avant preview future : status readiness, checklist no-code, diagnostics stage humains et resume Library `Preview`. | Pas de preview reelle, playback, timer, pathfinding, source map-aware reelle, `stageContext.mapId`, IDs libres ou runtime. | Builder/Library cinematics, petit read model editor pur, tests widget, rapport, screenshot. | DONE : `Preparation preview`, statuts sandbox/incomplet/bloquant/pret, checklist visible, messages mapEntity/mapEvent temporaires, Visual Gate. | Masquer les lacunes derriere un faux OK ; faire croire a une preview reelle ; casser la densite de l'inspecteur. | DONE : readiness lisible et honnete, sans nouveau pouvoir runtime/editor temporel. | V1-73. |
| NS-SCENES-V1-75 | Cinematic Map Entity/Event Source Audit / Picker Prep Contract | doc / architecture-review | Auditer les donnees map accessibles cote editor pour preparer de futurs pickers `mapEntity` / `mapEvent` honnetes. | Pas de picker actif, pas de runtime preview, pas de free coordinates, pas de `sourceId` tape a la main, pas de donnees Selbrume. | Rapport V1-75, roadmaps, audit MapData/editor services. | DONE : `ProjectManifest.maps` audite comme metadata/relativePath, `MapData.entities/events` identifies comme sources reelles, snapshot editor non destructive reperee, Option E retenue, contrat `CinematicStageMapSourceCatalog` et tests futurs cadres. | Brancher des IDs bruts ou une source incomplete ; confondre map authoring et runtime state. | DONE : contrat pret avant implementation map-aware, sans package ni picker actif. | V1-74. |
| NS-SCENES-V1-76 | Cinematic Stage Map Source Catalog V0 | core / read-model | Creer le catalogue pur des sources map-aware depuis `ProjectMapEntry` et `MapData`, avant tout picker. | Pas de UI, pas de picker actif, pas de preview reelle, pas de runtime, pas de pathfinding, pas de donnees Selbrume, pas de chargement MapData. | `cinematic_stage_map_source_catalog.dart`, export `map_core.dart`, test catalogue, rapports. | DONE : TDD RED/GREEN, statuts missing/unavailable/mismatch/available, entities/events reels, labels no-code, ids secondaires, `canBindActor`, `canBeMovementTarget`, tests/analyze core verts, tests editor cibles verts. | Lier le Builder trop tot ; charger la map depuis core ; exposer IDs bruts comme workflow. | DONE : catalogue consommable par V1-77, sans UI ni runtime. | V1-75. |
| NS-SCENES-V1-77 | Cinematic Stage Map Entity/Event Pickers V0 | editor / authoring | Brancher le catalogue V1-76 au Builder pour choisir de vraies sources `MapData.entities/events` dans les bindings stage. | Pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de coordonnees libres, pas de JSON/ID brut saisi, pas de donnees Selbrume. | Builder/Library cinematics, readiness preview, tests widget, rapport, screenshot. | DONE : actor binding -> vraie `mapEntity`, movement target -> vraie `mapEntity` ou vrai `mapEvent`, snapshot MapData non destructive, labels no-code, readiness alignee, Visual Gate 1663x926. | Charger la map au mauvais niveau ; exposer les ids bruts ; casser timeline/proportions ; faire croire a une preview reelle. | DONE : pickers map-aware honnetes actifs, sans runtime ni preview reelle. | V1-76. |
| NS-SCENES-V1-78 | Cinematic Character Library Binding Prep Contract | doc / architecture-review | Cadrer comment un acteur `cinematicOnly` choisira un personnage depuis la Character Library. | Pas de code produit, pas de modèle, pas de widget, pas de picker, pas de preview réelle, pas de runtime, pas de package, pas de test, pas de screenshot, pas de donnée Selbrume. | Rapport V1-78, roadmaps, audit Character Library / Stage Context / usages characters. | DONE : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables, labels no-code, assets tileset/animations/directions cadrés, options comparées, Option B retenue, contrat V0/diagnostics/tests futurs définis. | Mélanger identité d'acteur et apparence ; coder un picker avant le modèle ; faire croire à une preview réelle. | DONE : contrat prêt pour modèle Core V0, sans modifier le produit. | V1-77. |
| NS-SCENES-V1-79 | Cinematic Character Library Binding Core Model V0 | core / authoring | Implémenter le modèle authoring minimal permettant de lier un actor `cinematicOnly` à un personnage de la Character Library, avec JSON backward-compatible, opérations pures et diagnostics. | Pas d'UI picker, pas de preview réelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity en V0, pas de donnée Selbrume. | `cinematic_asset.dart`, authoring operations, diagnostics cinematic, tests JSON/operations/diagnostics, rapport. | DONE : `CinematicActorAppearanceBinding` separe, `stageContext.actorAppearanceBindings`, validation actor/character, diagnostics refs cassees, JSON backward-compatible, tests/analyze core verts. | Trop alourdir `CinematicActorBinding` ; autoriser les overrides visuels trop tôt ; casser les anciens JSON. | DONE : modèle minimal stable avant le picker Character Library, sans UI ni preview reelle. | V1-78. |
| NS-SCENES-V1-80 | Cinematic Character Library Picker V0 | editor / authoring | Exposer dans le Cinematic Builder un picker no-code pour choisir un `ProjectCharacterEntry` pour un acteur `cinematicOnly`, en consommant `actorAppearanceBindings` V1-79. | Pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity/unbound en V0, pas de donnee Selbrume. | Builder cinematics, readiness editor, tests widget, rapport, screenshot. | DONE : picker Character Library lisible, selection/clear explicites, empty/broken states, labels no-code, diagnostics Character Library visibles, aucun ID brut comme workflow principal. | Brancher une fausse preview ; melanger acteur et apparence ; exposer `characterId` comme saisie libre. | DONE : premier pont editor entre acteur cinematic-only et Character Library, sans preview reelle ni runtime. | V1-79. |
| NS-SCENES-V1-81 | Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | editor / ui-polish | Polir les diagnostics apparence/stage apres V1-80 : refs cassees, changement de kind apres selection, assets Character Library incomplets et messages readiness. | Pas de preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound, mutation Character Library ou nouveau modele core. | Builder/Library cinematics, readiness editor, tests widget, rapport, screenshot si UI. | DONE : drift apparence lisible, actions de nettoyage explicites, readiness precise, summary Library et Visual Gate. | Masquer une reference cassee ; supprimer automatiquement une ref ; faire croire a une preview reelle. | DONE : diagnostic polish apres picker, sans elargir le pouvoir runtime/editor. | V1-80. |
| NS-SCENES-V1-82 | Cinematic Map Backdrop Preview Prep Contract | doc-only / architecture-review | Cadrer la future preview de decor map du Cinematic Builder avant toute implementation visuelle : source MapData, renderer autorise, viewport/camera, diagnostics, anti-runtime, tests futurs. | Pas de code produit, pas de package, pas de widget, pas de test, pas de screenshot, pas de map affichee, pas de preview reelle, runtime, playback, pathfinding, collision, image IA ou donnees Selbrume. | Rapport V1-82, roadmaps. | DONE : sub-agents/passes A-E, arbitrage final, Option E retenue, contrat backdrop/viewport/readiness/tests futurs, checks anti-scope documentaires. | Coder la preview trop tot ; reutiliser PlayableMapGame ; coupler MapCanvas massif ; vendre une fausse preview. | DONE : contrat pret pour V1-83 read model, sans modifier les packages par V1-82. | V1-81. |
| NS-SCENES-V1-83 | Cinematic Map Backdrop Preview Read Model V0 | core / read-model | Creer un read model pur du backdrop preview depuis Stage Context + `ProjectMapEntry` + `MapData` : statuts, labels, dimensions, layers visuels, diagnostics, viewport recommendation. | Pas de renderer UI, pas de map affichee, pas de runtime/Flame, pas de playback, pas d'acteurs rendus, pas de pathfinding/collision. | `cinematic_map_backdrop_preview_model.dart`, export `map_core.dart`, tests purs, rapport. | DONE : RED/GREEN sur statuses disabled/missing/unknown/unavailable/mismatch/tilesetUnavailable/available, layers visuels, diagnostics, viewport recommendation, tests/analyze core verts. | Confondre read model et renderer ; charger le disque depuis core ; ignorer les erreurs snapshot. | DONE : contrat V1-82 materialise en projection testable, sans rendu. | V1-82. |
| NS-SCENES-V1-84 | Cinematic Map Backdrop Preview Renderer V0 | editor / preview-sandbox | Brancher le read model V1-83 dans le Cinematic Builder pour afficher un decor map sandbox read-only depuis une `MapData` deja chargee par l'editor. | Pas de runtime/Flame, pas de `PlayableMapGame`, pas de playback, pas d'acteurs rendus, pas de pathfinding/collision, pas de mutation map/projet. | Builder cinematics, snapshot map editor, renderer read-only, tests widget, rapport, screenshot. | DONE : `CinematicMapBackdropPreviewModel` passe au Builder, renderer sandbox read-only visible, fallbacks humains tous statuts, diagnostics, snapshot non destructive, Visual Gate, tests builder/library/core et analyse ciblee verts. | Refaire un runtime dans l'editor ; casser les proportions demandees par Karim ; rendre des acteurs ou collisions trop tot. | DONE : V1-84 affiche enfin un decor de map statique dans le Builder ; V1-84 ne lance toujours pas la cinematique. | V1-83. |
| NS-SCENES-V1-85 | Cinematic Map Backdrop Visual Primitives V0 | core / editor preview-sandbox | Remplacer le rendu de bandes V1-84 par des primitives visuelles spatiales derivees de `MapData` reelle : cellules, chemins, surfaces, ancres objet/environnement et fallback summary honnete. | Pas de runtime/Flame, pas de `PlayableMapGame`, pas de playback, pas d'acteurs rendus, pas de fake tiles, pas de pathfinding/collision, pas de mutation map/projet. | Read model backdrop, panel/painter cinematic, tests widget/core, rapport, screenshot. | DONE : `visualPrimitives`, mini renderer CustomPainter tokenise, grille/cellules visibles, fallbacks V1-84 preserves, Visual Gate, tests builder/library/core et analyse ciblee verts. | Inventer une fake map ; brancher MapCanvas complet ; casser les proportions preview/timeline. | DONE : V1-85 rend le decor plus map-like sans rendre une cinematique jouable. | V1-84. |
| NS-SCENES-V1-86 | Cinematic Map Backdrop Visual Composition Polish V0 | editor / ui-polish | A la demande de Karim, corriger la composition du backdrop avant Actor Display : viewport map plus grand/proportionnel, rail meta/legende secondaire, grille/primitives plus lisibles, preview/timeline equilibrees. | Pas de tiles/assets finaux, runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, panel/painter backdrop, tests widget, rapport, screenshot. | DONE : test RED/GREEN viewport >= 220 px, ratio map preserve, legende secondaire, diagnostics sans overflow, Visual Gate 1663x926, tests builder/library/core cibles et analyse ciblee verts. | Trop reduire la timeline ; vendre une preview runtime ; agrandir les badges au lieu de la carte ; oublier le rapport avec code. | DONE : V1-86 rend le decor beaucoup plus lisible ; V1-86 ne rend toujours pas la cinematique jouable. | V1-85. |
| NS-SCENES-V1-87 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs dans la preview backdrop lisible, en decidant sources, apparences, positions et diagnostics avant tout renderer actor. | Pas de rendu acteur actif, pas de runtime/Flame, pas de playback/interpolation, pas de pathfinding/collision, pas de donnee Selbrume. | Rapport V1-87, roadmaps. | TODO : contrat acteurs preview, sources actor bindings/placements/Character Library, anti-scope runtime. | Poser des acteurs sur une projection encore trop abstraite ; confondre actor display et gameplay runtime. | TODO : contrat pret pour un renderer actor statique futur. | V1-86. |
| NS-SCENES-V1-90 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Character Library. |

## Mise a jour V1-86

Statut : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0` est DONE.

Demande : Karim a demande ce lot de polish backdrop avant de passer aux acteurs. L'ancien prochain lot recommande `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract` est donc repousse a `NS-SCENES-V1-87`.

Decision : le Builder adapte l'equilibre preview/timeline uniquement quand un backdrop preview model est disponible, agrandit le viewport map structurel, deplace meta et legende hors de la surface map, rend les diagnostics sous forme de pills compactes et renforce le painter editor-only par grille adaptive, chemins ruban et ancres halo/core.

Scope realise : map structurelle plus lisible, carte proportionnelle avec shortest side teste >= 220 px, legende secondaire, diagnostics sans overflow, timeline par pistes preservee, transports toujours desactives, pickers/inspector preserves.

Preuve : Visual Gate V1-86 1663x926, `cinematic_builder_workspace_test.dart` vert, `cinematics_library_workspace_test.dart` vert, test core backdrop vert, analyse ciblee editor verte. Verification large tentee : `flutter test --reporter=compact` sur tout `map_editor` reste rouge hors lot (`+2191 -18`) et `flutter analyze` global reste rouge sur dette Pokemon SDK preexistante.

Limites : le rendu reste structurel et non jouable. Aucun tileset asset final, acteur rendu, runtime, Flame, playback, pathfinding/collision, mutation map/projet, donnee Selbrume, image IA ou `gpt-image-2` n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract`.

## Mise a jour V1-85

Statut : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0` est DONE.

Demande : Karim a fourni le prompt V1-85 et a autorise l'utilisation de sub-agents au besoin. Le scope etait de rendre le decor map plus credible que V1-84 avec des primitives derivees de `MapData`, tout en restant sandbox/read-only.

Decision : `map_core` expose des primitives pures dans `CinematicMapBackdropPreviewModel` (`visualPrimitives`, `mapWidth`, `mapHeight`) et le Builder les rend via un mini painter editor-only recevant ses couleurs depuis le design system. Les layers sans donnees spatiales restent en fallback `layerSummary`.

Scope realise : cellules tile/path/surface, ancres objet depuis `MapPlacedElement`, support environnement par masques, grille proportionnelle, compteur de primitives, legendes layer, fallback sans primitives, fallbacks/diagnostics V1-84 preserves, transports disabled, timeline/duree/resize/probe/pickers preserves.

Preuve : RED/GREEN core et editor, `cinematic_map_backdrop_preview_model_test.dart` vert, `cinematic_builder_workspace_test.dart` vert, `cinematics_library_workspace_test.dart` vert, Visual Gate V1-85 1663x926, analyse ciblee editor verte, `dart analyze` core vert.

Limites : rendu tiles/assets final absent ; V1-85 ne rend pas d'acteurs, ne lance pas la cinematique, n'importe pas Flame/runtime, ne rend pas collisions/triggers/events/entities et n'utilise aucune donnee Selbrume ni image IA.

Prochain lot exact recommande : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0`, a la demande de Karim avant l'Actor Display.

## Mise a jour V1-84

Statut : `NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0` est DONE.

Demande : Karim a fourni le prompt V1-84 et a autorise l'utilisation de sub-agents au besoin. Le scope etait de consommer V1-83 dans le Builder pour afficher un decor sandbox read-only, pas une preview runtime.

Decision : le read model V1-83 suffit pour un renderer V0 honnete. Le Builder reçoit un `CinematicMapBackdropPreviewModel` construit cote editor avec `CinematicAsset.mapId`, `ProjectMapEntry`, `stageContext.backdropMode`, la snapshot `MapData` deja chargee et les tilesets disponibles quand ils existent. Aucun chargement de map n'est ajoute dans le Builder.

Scope realise : nouveau panel `cinematic_map_backdrop_preview_panel.dart`, branchement dans `_PreviewSandbox`, wiring Library snapshot -> backdrop model, fallbacks humains `backdropDisabled`, `missingStageMap`, `stageMapUnknown`, `mapDataUnavailable`, `mapDataMismatch`, `tilesetUnavailable`, diagnostics read model, preservation timeline/duree/resize/probe, pickers map-aware et Character Library avec backdrop visible.

Preuve : test preflight rouge connu reproduit puis corrige de facon ciblee, test RED/GREEN available backdrop, tests de fallbacks, non-mutation projet/MapData, absence acteurs/collision overlays, tests interaction timeline avec backdrop visible, test Library snapshot -> Builder, Visual Gate 1663x926, tests core cibles verts, `cinematic_builder_workspace_test.dart` vert, `cinematics_library_workspace_test.dart` vert, analyse ciblee editor verte.

Limites : rendu structurel abstrait, pas encore rendu final des tiles/assets ; pas de runtime, Flame, PlayableMapGame, playback, acteurs rendus, Character Library sprites rendus, collision/pathfinding/triggers/event/entity overlays, mutation map/projet, donnees Selbrume ou image IA.

Prochain lot exact recommande : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0`.

## Mise a jour V1-83

Statut : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0` est DONE.

Demande : Karim a fourni le prompt et a autorise l'utilisation de sub agents au besoin. Le scope etait de construire la projection testable du decor, pas d'afficher la map dans l'interface.

Decision : le read model vit dans `map_core`, comme contrat public pur entre les donnees chargees par l'editor et le futur renderer V1-84. Il consomme `CinematicAsset.mapId`, `ProjectMapEntry` et `MapData` deja fournis ; il ne lit pas de fichier, ne charge pas de tileset image et ne depend ni de Flutter ni de Flame.

Scope realise : statuses backdrop disabled/missing/unknown/unavailable/mismatch/tilesetUnavailable/available, diagnostics severite/code, layers visuels derives de `MapData.layers`, exclusion collision/entities/events/triggers/warps/gameplayZones, label/relativePath/size summary, renderRefs legers et viewport recommendation pure.

Preuve : test RED puis GREEN du read model, tests core `cinematic_stage_map_source_catalog_test.dart`, `cinematic_asset_test.dart`, `project_manifest_cinematics_test.dart` et `dart analyze` verts. Test editor Library vert ; test editor Builder rouge sur une attente read-only contredite par le champ de renommage acteur existant, hors scope V1-83.

Limites : pas de renderer UI, pas de map affichee, pas de runtime/Flame, pas de playback, pas d'acteurs rendus, pas de pathfinding/collision, pas de `stageContext.mapId`, pas de donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0`.

## Mise a jour V1-82

Statut : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract` est DONE.

Demande : Karim a relance le lot apres l'oubli du rapport. Le scope etait strictement documentaire avec sub-agents / passes specialisees obligatoires, aucun code produit, aucun package, aucun test, aucune preview reelle.

Decision : Option E retenue. Le Builder doit d'abord consommer un contrat/read model backdrop preview avant tout rendu. La source canonique reste `CinematicAsset.mapId` + `ProjectManifest.maps` + `ProjectMapEntry.relativePath` + `MapData` chargee par le niveau editor. `stageContext.backdropMode.none` signifie decor volontairement desactive ; `projectMap` demande une preview seulement si mapId, ProjectMapEntry et MapData sont disponibles et alignes.

Scope realise : audit Stage Context/mapId/backdropMode, audit MapData snapshot, audit Map Editor rendering, audit runtime/Flame anti-scope, audit Product/UX, synthese des sub-agents et arbitrages, options A-E comparees, contrat conceptuel `CinematicMapBackdropPreviewModel`, viewport/camera, diagnostics futurs, tests futurs V1-83/V1-84 et Evidence Pack.

Limites : V1-82 n'affiche pas la map, ne code pas de renderer, ne reutilise pas `PlayableMapGame`, ne modifie pas runtime/Flame, ne lance pas de playback, ne rend pas les acteurs et ne hardcode aucune donnee Selbrume. Les fichiers `packages/` modifies au Gate 0 sont preexistants hors V1-82.

Prochain lot exact recommande : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`.

## Mise a jour V1-81

Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.

Demande : Karim a fourni le prompt du lot et a autorise l'utilisation de sub agents au besoin. Le scope retenu reste concentre sur le polish editor des apparences Character Library.

Decision : les refs d'apparence ne sont jamais supprimees automatiquement. Le Builder expose des messages humains et des actions explicites pour nettoyer ref character cassee, actor kind incompatible et actor supprime/orphelin. La Library resume le drift via `Preview : apparence a corriger`.

Scope realise : diagnostics apparence humanises, Character Library vide expliquee, character incomplet explique sans preview reelle, readiness `Apparences acteurs` alignee, Visual Gate V1-81, tests Builder/Library, analyse cible editor.

Limites : pas de preview reelle, pas de runtime, pas de mutation Character Library, pas de pathfinding, pas de donnees Selbrume, pas de `characterId` dans `CinematicActorBinding` ou `requiredActors`.

Prochain lot exact recommande : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

## Mise a jour V1-80

Statut : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0` est DONE.

Demande : Karim a fourni le prompt du prochain lot et a autorise l'utilisation de sub agents au besoin. Le scope retenu consomme V1-79 sans modifier `map_core`.

Decision : le picker vit dans le Cinematic Builder, section `Acteurs` / `Apparence`. Il selectionne un `ProjectCharacterEntry` seulement pour un acteur `cinematicOnly`; les actors `player`, `mapEntity` et `unbound` affichent une apparence heritee ou un message d'abord lier en cinematique uniquement.

Scope realise : callbacks editor pour `upsertCinematicActorAppearanceBinding` et `removeCinematicActorAppearanceBinding`, passage de `ProjectManifest.characters`, picker avec nom/tileset/frame/tags/id technique discret, clear explicite, etat bibliotheque vide, etat ref cassee, readiness apparences et messages diagnostics V1-79 humanises.

Preuve : test RED/GREEN du picker, suite Builder, suite Library, analyse cible editor et Visual Gate V1-80. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity/unbound, pas de modification Character Library, pas de creation/edition/suppression de personnage, pas de `stageContext.mapId`, pas d'image IA et pas de build_runner.

Prochain lot exact recommande : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0`.

## Mise a jour V1-79

Statut : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0` est DONE.

Demande : Karim a demande de reprendre le prochain lot en autorisant l'utilisation de sub agents au besoin ; le scope retenu reste le contrat V1-78, c'est-a-dire le modele core avant tout picker UI.

Decision : le lien Character Library est stocke dans une couche separee d'apparence, `CinematicActorAppearanceBinding`, portee par `CinematicStageContext.actorAppearanceBindings`. `CinematicActorBinding` ne stocke pas `characterId`, pour ne pas melanger le role stage logique avec l'apparence choisie.

Scope realise : serialization JSON backward-compatible, operations pures upsert/remove, validation `cinematicOnly`, diagnostics actor inconnu, character inconnu, Character Library indisponible, sprite/preview manquants, et tests JSON/manifest/operations/diagnostics.

Preuve : tests cibles `map_core` verts, `dart analyze` `map_core` vert, suite complete `map_core` terminee sur `+2390 All tests passed!`, tests editor non-regression Builder/Library verts. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites : pas de picker Character Library, pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de donnee Selbrume, pas de `stageContext.mapId`, pas d'image IA et pas de build_runner.

Prochain lot exact recommande : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0`. L'ancien `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0` est deplace en backlog `NS-SCENES-V1-90`.

## Mise a jour V1-74

Statut : `NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0` est DONE.

Decision : la readiness de preview reste une projection editor-side, pas une preview runtime. Le Builder affiche un status, une checklist et des diagnostics humains ; les codes techniques ne restent visibles qu'en reference secondaire. Les options `mapEntity` et `mapEvent` restent desactivees avec une explication de lot futur.

Preuve : tests widget Builder/Library, Visual Gate V1-74, `map_core` cibles verts, analyse cible editor verte. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Prochain lot exact recommande : `NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract`.

## Mise a jour V1-75

Statut : `NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract` est DONE.

Decision : les pickers `mapEntity` / `mapEvent` ne doivent pas etre actives directement depuis `ProjectManifest.maps`. Le manifest donne seulement `ProjectMapEntry.id/name/relativePath`; les sources reelles vivent dans `MapData.entities` et `MapData.events`. Le Builder ne recoit aujourd'hui que `stageMaps: widget.project.maps`, donc V1-76 doit d'abord creer un catalogue stage-aware pur.

Option recommandee : Option E, read model dedie alimente par une source `MapData` fiable. Cote editor, `EditorNotifier.loadMapSnapshotById` est le point d'entree non destructif le plus propre pour obtenir la map stage sans changer la map active. Cote contrat, `CinematicStageMapSourceCatalog` doit exposer labels no-code, ids techniques secondaires discrets et capabilities `canBindActor` / `canBeMovementTarget`.

Contrats cadres : actor binding V0 peut selectionner une `MapEntity` stable ; movement target V0 peut selectionner une `MapEntity` ou un `MapEventDefinition` positionne ; aucun actor binding direct vers event ; aucune saisie manuelle `sourceId`, `mapEntityId` ou `eventId` ; aucune coordonnee libre comme workflow principal.

Diagnostics futurs : `actorBindingMapEntityUnknown`, `movementTargetBindingMapEntityUnknown`, `movementTargetBindingMapEventUnknown`, `stageMapSourcesUnavailable`, `stageMapEntitySourceUnavailable`, `stageMapEventSourceUnavailable`, en plus des diagnostics missing/required stage deja presents.

Tests futurs : V1-76 doit prouver le catalogue depuis de vraies `MapData`, les labels, ids secondaires et capabilities sans runtime ni `GameState`; V1-77 devra prouver les pickers actifs sans TextField d'id brut et sans mutation de timeline ou preview playback.

Limites : V1-75 est doc-only ; aucun package, test, picker actif, preview reelle, runtime, pathfinding, screenshot, image IA ou donnees Selbrume n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0`.

## Mise a jour V1-76

Statut : `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0` est DONE.

Decision : le Builder ne consomme toujours pas les entites/events directement. V1-76 ajoute d'abord un read model pur `CinematicStageMapSourceCatalog`, construit depuis `ProjectMapEntry` et une `MapData` deja chargee, afin que V1-77 puisse brancher des pickers honnetes sans IDs libres.

Contrat livre : statuts `missingStageMap`, `mapDataUnavailable`, `mapIdMismatch`, `available`; sources entites depuis `MapData.entities`; sources events depuis `MapData.events`; labels no-code avec fallback id uniquement en dernier recours; `secondaryLabel` technique discret; `kindLabel`; `positionSummary`; diagnostics locaux; `canBindActor` pour NPC; `canBeMovementTarget` pour entites/events positionnes.

Preuve : test catalogue TDD RED/GREEN, tests core cinematics cibles, `dart analyze` map_core vert, tests editor Builder/Library verts. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites confirmees : pas de picker actif, pas de UI modifiee, pas de preview reelle, pas de runtime, pas de pathfinding, pas de `stageContext.mapId`, pas de donnees Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`.

## Mise a jour V1-77

Statut : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0` est DONE.

Decision : le catalogue V1-76 est maintenant fourni au Builder depuis le niveau editor. La Library charge une snapshot `MapData` non destructive pour la map de scene, construit le `CinematicStageMapSourceCatalog`, puis le Builder active les choix `mapEntity` / `mapEvent` uniquement quand le catalogue est disponible et aligne.

Scope realise : picker actor binding `mapEntity` depuis les entites PNJ bindables, picker movement target `mapEntity` depuis les entites cibles, picker movement target `mapEvent` depuis les events positionnes, labels no-code, detail type/tuile, readiness map-aware et messages d'indisponibilite honnetes.

Preuve : rapport V1-77, evidence pack V1-77, tests Builder/Library, tests/analyze core, analyse cible editor et Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png` en 1663x926. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites confirmees : preview reelle eteinte, runtime intouché, timeline/duree/resize/probe/transports preserves, aucun ID libre, aucun JSON brut, aucun `stageContext.mapId`, aucune image IA ou `gpt-image-2`.

Prochain lot exact recommande : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.

## Mise a jour V1-78

Statut : `NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract` est DONE.

Decision : le besoin formule par Karim remplace temporairement le drift diagnostics. `cinematicOnly` doit signifier acteur propre a la cinematique, non place sur la map, mais capable de referencer un personnage de la Character Library pour son apparence authoring.

Option recommandee : ne pas ajouter `characterId` directement dans `CinematicActorBinding` en V0. Creer plutot une couche separee d'apparence, conceptuellement `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings`, afin de ne pas melanger binding logique et apparence. En V0, ce binding est recommande seulement pour les acteurs `cinematicOnly`.

Preuve : rapport V1-78, audit `ProjectManifest.characters`, `ProjectCharacterEntry`, Character Library editor, refs joueur/PNJ/dresseur/runtime et Stage Context V1-72/V1-77. Aucune modification de package, test, runtime, preview, screenshot, image IA ou donnee Selbrume n'est ajoutee.

Limites confirmees : V1-78 est doc-only ; aucun modele core, aucune migration JSON, aucun picker Character Library, aucune preview acteur et aucun runtime ne sont codes.

Prochain lot exact recommande : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0`.

## Mise a jour V1-66

Statut : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0` est DONE.

Decision : le Builder affiche maintenant une aide locale `Aide repère`, visible uniquement avec un repere souris actif. Elle explique la difference entre selection inspectee et repere temporel local, avec un rappel d'alignement et de preview future, sans mutation ni nouveau controle temporel.

Preuve : tests widget cibles et suite Builder/Library verts, Visual Gate V1-66, tests core time layout/lane et analyses ciblees. La trajectoire immediate est corrigee a la demande de Karim : le lot suivant devient `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`.

## Mise a jour V1-67

Statut : `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` est DONE.

Decision : V1-67 est documentaire et remplace le scroll/visibility polish immediat. Le contrat retient l'edition inspecteur d'abord, puis le resize souris par bord droit. `durationMs` reste la seule valeur persistante autorisee ; `startMs` et `endMs` restent derives.

Preuve : rapport V1-67, roadmaps corrigees, checks anti-scope documentaires. Aucun code produit, package, test, screenshot, runtime, playback ou timeline libre n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`.

## Mise a jour V1-68

Statut : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0` est DONE.

Decision : l'edition no-code de `durationMs` est active depuis l'inspecteur pour `wait`, `fade`, `camera`, `actorFace` et `actorMove`. La validation n'est pas UI-only : elle passe par `map_core`, avec min 100 ms, min 200 ms pour `actorMove`, et max 30000 ms.

Preuve : rapport V1-68, tests RED puis GREEN core/editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.png`, suite Builder+Library `+80`, analyse cible editor verte, `map_core` analyze vert. L'analyse globale `map_editor` reste rouge par dette preexistante hors lot.

Prochain lot exact recommande : `NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0`.

## Options comparees

| Option | Verdict | Raison |
|---|---|---|
| A — Continuer directement RuntimePlan puis StorylineStep | Rejetee | RuntimePlan seul ne rend pas le builder utilisable ; StorylineStep link trop tot confond progression et declencheur. |
| B — Basculer uniquement graph authoring | Rejetee partiellement | Aligne bien Blueprint-like, mais risque de creer des graphes sans contrat runtime. |
| C — Hybride Blueprint + sources metier + runtime plan | Retenue | Garde le builder utilisable, evite les conditions textuelles magiques, puis enchaine Fact/World Rules, runtime plan, Event -> Scene avant StorylineStep. |
| D — Event-first | Rejetee maintenant | Selbrume a besoin d'Event -> Scene, mais trop tot si le builder ne peut pas construire la scene cible. |

## Mise a jour V1-11

Statut : `NS-SCENES-V1-11 — Scene Graph Draft Node Strategy` est DONE.

Decision : le premier authoring de nodes doit rester tres strict. En V0, seuls `condition`, `merge` et `end` deviennent ajoutables, car ils peuvent etre crees avec le modele actuel sans reference inventee. `start` reste unique. `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` restent visibles mais desactives dans la future palette tant que leurs refs, source outcomes ou action kinds ne sont pas honnetes.

Prochain lot exact : `NS-SCENES-V1-12 — Node Authoring V0`.

## Mise a jour V1-12

Statut : `NS-SCENES-V1-12 — Node Authoring V0` est DONE.

Decision : V1-12 a code seulement les nodes autorises par V1-11. La palette V0 active `Condition`, `Merge` et `Fin`. Les nodes `Début`, `Dialogue`, `Action`, `Combat`, `Cinématique` et `Branche` restent desactives avec raison courte. Aucun edge n'est cree automatiquement.

Prochain lot exact : `NS-SCENES-V1-13 — Edge Authoring V0`.

## Mise a jour V1-13

Statut : `NS-SCENES-V1-13 — Edge Authoring V0` est DONE.

Decision : V1-13 ajoute seulement la creation explicite d'edges V0. Les ports authorables sont `start.completed`, `condition.true`, `condition.false` et `merge.completed`. `SceneEdge.kind` est derive du port. Le mode connexion editor est local : node source selectionne, bouton de port, clic sur node cible. La selection reste sur la source apres creation pour connecter les branches d'une condition.

Limites : aucun drag and drop, aucune suppression d'edge, aucune reconnexion avancee, aucune preview line, aucun runtime, aucun StorylineStep link.

Prochain lot exact : `NS-SCENES-V1-14 — Layout Authoring V0`.

## Mise a jour V1-14

Statut : `NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0` est DONE.

Decision : V1-14 elargit `Layout Authoring V0` en socle canvas Blueprint-like. Le Scene Builder affiche une grille, des controles zoom/reset, le pinch trackpad MacBook, un pan local et des nodes deplacables. Le drag persiste uniquement `SceneGraphLayout` dans `ProjectManifest.scenes` en memoire ; `SceneGraph.nodes` et `SceneGraph.edges` restent inchanges. Les edges suivent les positions courantes, la selection et l'inspecteur restent coherents, et la connexion V1-13 reste fonctionnelle.

Limites : pas de ports visuels connectables, pas de preview line de connexion, pas de suppression/reconnexion avancee, pas de minimap, pas d'auto-layout, pas de runtime.

Prochain lot exact : `NS-SCENES-V1-15 — Visual Port Connection UX V0`.

## Mise a jour V1-15

Statut : `NS-SCENES-V1-15 — Visual Port Connection UX V0` est DONE.

Decision : les ports visuels V0 sont maintenant presents sur le canvas. L'auteur peut dragger depuis un output authorable, voir un cable de preview, beneficier d'un highlight/snap sur les inputs compatibles, puis dropper sur un input pour creer un edge via la meme operation V1-13. Drop hors cible annule sans mutation.

Limites : pas de suppression/reconnexion, pas de ports actifs pour Yarn/Action/Battle/Cinematic/Branch, pas d'edition de payload, pas de runtime.

Prochain lot exact : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review`.

## Mise a jour V1-15-bis

Statut : `NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0` est DONE.

Decision : V1-15-bis ajoute la correction des liens sans ouvrir la reconnexion avancee. Une operation pure `removeSceneEdgeDraft` supprime l'edge cible et conserve le reste du SceneAsset. Cote editor, l'edge est selectionnable, highlight dans le canvas, visible dans un inspecteur de lien, puis supprimable via `Supprimer le lien`. La selection edge est locale et reset apres suppression.

Limites : pas de reconnexion, pas de suppression node, pas de payload picker, pas de runtime, pas d'edition Condition.

Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

## Mise a jour V1-16

Statut : `NS-SCENES-V1-16 — Condition Sources Contract V0` est DONE.

Decision : le contrat V0 autorise seulement les sources qu'on peut exposer sans inventer de refs : fait existant technique fact-like, step complete/non complete et event consomme/non consomme. `ScriptCondition` reste un backend technique, pas une UX. Les sources inventory, party, script variables, trainer defeated dedie, dialogue/battle outcomes et World Rules sont reportees jusqu'aux pickers, registries ou runtime plans correspondants.

Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune Fact Registry, aucune World Rule.

Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

## Mise a jour V1-16-prep

Statut : `NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review` est DONE.

Decision : Condition Authoring V0 ne doit pas commencer par un payload texte libre. Le Scene Builder doit d'abord cadrer les sources de condition lisibles, leur mapping vers l'existant (`GameState`, `ScriptCondition`, story progression, map/event state), les pickers requis et les diagnostics. La roadmap insere donc `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis deplace l'authoring effectif en `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

Limites : aucune Fact Registry, World Rule, UI Condition ou runtime n'est code dans V1-16-prep.

Prochain lot exact : `NS-SCENES-V1-16 — Condition Sources Contract V0`.

## Mise a jour V1-17

Statut : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)` est DONE.

Decision : V1-17 code l'authoring no-code d'un `ConditionNode` a source unique. Les sources V0 actives sont `factLikeStoryFlag`, `storyStepCompletion` et `consumedEvent`, selectionnees depuis des refs existantes derivees du projet. Le payload reste structure via `SceneConditionSource`; aucun texte libre, ID fake, runtime ou World Rule n'est introduit. Une condition incomplete devient une erreur authoring, ce qui garde les scenes non executables tant que le payload n'est pas honnete.

Limites : pas de Fact Registry, pas de sources inventory/party/dialogue outcome/battle outcome/script variable/world state, pas de AND/OR, pas de payload picker Yarn/Battle/Cinematic, pas de runtime, pas de StorylineStep link, pas d'Event -> Scene.

Prochain lot exact : `NS-SCENES-V1-18 — Fact Registry V0`.

## Mise a jour V1-18

Statut : `NS-SCENES-V1-18 — Fact Registry V0` est DONE.

Decision : V1-18 ajoute une registry authoring bool-first via `ProjectManifest.facts` et `NarrativeFactDefinition`. Les Facts portent un id stable, un label lisible, une description, une categorie, une valeur par defaut, des tags et un lien optionnel vers un flag legacy. Les operations pures d'ajout, mise a jour et suppression preservent le manifest original, et la suppression refuse les Facts encore references par une condition Scene V1.

Integration Scene Builder : le picker Condition expose les Facts de registry comme source prioritaire `SceneConditionSourceKind.fact`. Les refs fact-like legacy restent disponibles comme fallback technique, sans migration automatique ni conversion destructive.

Limites : bool-only, pas de registry editor dediee, pas de World Rules, pas de runtime, pas de Event -> Scene, pas de StorylineStep link, pas de donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-19 — World Rule Contract V0`.

## Mise a jour V1-19

Statut : `NS-SCENES-V1-19 — World Rule Contract V0` est DONE.

Decision : une World Rule V0 est une regle authoring declarative, inspectable et validable. Elle lit une source metier (`Fact`, `StoryStep completed/notCompleted`, `consumed event`) et projette un effet visible/actif sur une cible explicite du monde. Elle n'est pas un script cache, une action one-shot de Scene, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.

Stockage futur recommande : registry projet canonique avec targets explicites, plus affichage contextuel dans Map Editor/entity inspector. Les implementations existantes `MapEntityNpcVisibilityRule`, `MapEntityConditionalDialogue`, `MapEntityRuntimePredicateEvaluator`, `NpcMapPresencePredicate` et `StepStudioWorldPresenceRule` servent d'inspiration ou de bridge, pas de modele produit final.

Effets V0 recommandes : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si les refs sont validables. Les collisions dynamiques, warps dynamiques, deplacements d'entites et ambiances/map state sont repousses.

Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime et aucune donnee Selbrume ne sont ajoutes.

Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.

## Mise a jour V1-20

Statut : `NS-SCENES-V1-20 — World Rules V0` est DONE.

Decision : V1-20 ajoute une registry canonique `ProjectManifest.worldRules` et un modele `WorldRuleDefinition` declaratif. Les sources V0 supportees sont `Fact`, `StoryStep completion` et `consumed event`. Les targets V0 sont `mapEntity`, `npcDialogue` et `mapEvent`. Les effets V0 sont `entityVisible`, `entityHidden`, `npcDialogueOverride`, `eventEnabled`, `eventDisabled` et `eventHidden`.

Integration : les operations pures `addWorldRule`, `updateWorldRule` et `removeWorldRule` preservent le manifest original et refusent les mismatches. `diagnoseWorldRules` couvre refs inconnues, predicates incompatibles, target/effect mismatch, conflits de priorite et labels techniques. `projectWorldRuleEffects` fournit une projection pure depuis `GameState`, sans mutation ni runtime. L'overview du Narrative Studio affiche compteur, diagnostics et premiers labels World Rules.

Limites : pas d'ecran dedie World Rules, pas de picker map/entity/event/dialogue, pas de runtime Scene, pas d'Event -> Scene, pas de StorylineStep link, pas de collision/warp/tile/ambience dynamique, pas de donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

## Mise a jour V1-20-bis

Statut : `NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction` est DONE.

Decision : V1-20 reste fonctionnellement accepte et DONE. La roadmap ne doit cependant pas lancer automatiquement `NS-SCENES-V1-21 — Scene Runtime Plan V0`. Le prochain lot exact est corrige en `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

Raison : le Scene Builder, les Conditions, la Fact Registry et les World Rules forment maintenant un socle produit assez avance pour relire la vision Narrative Studio avant de choisir le prochain axe. Le checkpoint doit arbitrer entre Runtime Plan, Event -> Scene, World Rules reliees au Map Editor, Payload Pickers, Diagnostics/Validator et trajectoire golden slice Selbrume.

Impact V1-21 : `NS-SCENES-V1-21 — Scene Runtime Plan V0` reste un candidat logique apres checkpoint, mais n'est plus le prochain lot automatique.

Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que `NS-SCENES-V1-18 — Fact Registry V0` existe. Ce polish/alignement UI doit etre traite dans un lot futur ou pendant le checkpoint, sans code dans V1-20-bis.

Prochain lot exact : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.

## Mise a jour V1-20-checkpoint

Statut : `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint` est DONE.

Decision : apres relecture de la vision Narrative Studio et du golden slice Selbrume, le prochain lot exact devient `NS-SCENES-V1-21 — Payload Pickers V0`. Le Runtime Plan reste indispensable, mais il est repousse apres la configuration honnete des payloads metier et apres la preparation Event -> Scene, car un plan runtime sur des scenes sans refs Yarn/Cinematic/Battle/Action debloquerait peu de valeur produit.

Comparaison retenue : Event -> Scene est prioritaire pour Selbrume, mais il doit cibler une Scene capable de contenir un dialogue Yarn, une cinematic, un battle et des actions avec de vraies refs. Diagnostics/Validator doit suivre quand ces refs existent. World Rules Map Editor Integration reste necessaire avant le golden slice complet, mais ne bat pas les Payload Pickers comme prochain lot.

Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune donnee Selbrume et aucun StorylineStep link n'est ajoute dans le checkpoint.

Prochain lot exact : `NS-SCENES-V1-21 — Payload Pickers V0`.

## Mise a jour V1-21-prep

Statut : `NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit` est DONE.

Decision : les Payload Pickers ne doivent pas demarrer directement. Le Scene Builder doit stocker des refs stables, mais il doit aussi lire des contrats publics minimaux pour afficher, brancher et diagnostiquer les nodes metier. Ces contrats doivent exposer labels, existence, statut, diagnostics, outputs/outcomes et contraintes sans reveler toute l'implementation interne de Dialogue Yarn, Cinematic/Cutscene, Battle ou Action.

Verdict par famille : Dialogue/Yarn et Battle/Trainer sont les plus proches d'un picker honnete, mais leurs contracts publics doivent etre formalises avant UI. Cinematic/Cutscene reste dangereux tant que Cutscene Studio compile vers `ScenarioAsset` sans vrai contrat cinematic canonique. Action/Consequence reste trop disperse entre ScriptAsset, ScenarioRuntimeExecutor, Facts et World Rules. BranchByOutcome reste disabled tant que les producteurs d'outcomes et les mappings outcome -> edge ne sont pas explicites.

Roadmap : `NS-SCENES-V1-21 — Linked Asset Contracts V0` devient le prochain lot exact. `Payload Pickers V0` est decale en V1-22. `Event -> Scene` reste prioritaire apres que les scenes puissent pointer vers des contenus metier honnetes. `Scene Runtime Plan V0` reste necessaire ensuite. `StorylineStep.sceneLinkIds` reste repousse.

Limites : aucun code, widget, modele, test, build_runner, runtime, Event -> Scene, StorylineStep link, fake data ou donnee Selbrume n'est ajoute.

Prochain lot exact : `NS-SCENES-V1-21 — Linked Asset Contracts V0`.

## Mise a jour V1-21

Statut : `NS-SCENES-V1-21 — Linked Asset Contracts V0` est DONE.

Decision : V1-21 ajoute un read model public pur dans `map_core` pour que les futurs pickers Scene Builder ne lisent pas directement des IDs bruts ni des details internes. `DialoguePublicContract` expose les dialogues du manifest avec label/source/start node et diagnostic d'outcomes absents. `BattlePublicContract` expose uniquement les trainer battles depuis `ProjectManifest.trainers`, avec outcomes `victory` / `defeat`, sans importer `map_battle`. `CinematicPublicContract` existe seulement comme bridge explicite `scenarioBridge` pour les scenarios marques Cutscene Studio, avec statut `bridgeOnly` et diagnostic `legacyBridge`.

Limites : pas de Payload Picker UI, pas de runtime, pas de `CinematicAsset`, pas d'Action Registry, pas de Consequence authoring, pas de BranchByOutcome mapping, pas d'Event -> Scene, pas de StorylineStep link et aucune donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-22 — Payload Pickers V0`.

## Mise a jour V1-22

Statut : `NS-SCENES-V1-22 — Payload Pickers V0` est DONE.

Decision : V1-22 active seulement les pickers dont les contrats publics V1-21 sont assez honnetes pour creer un payload sans ID brut. Le picker Dialogue consomme `DialoguePublicContract` et cree un `SceneYarnDialoguePayload` avec `dialogueId` reel, start node connu et outcomes Yarn non inventes. Le picker Battle consomme `BattlePublicContract` et cree un `SceneBattlePayload` trainer avec outcomes `victory` / `defeat`.

Scope prudent : Cinematic reste desactive meme quand un contrat `scenarioBridge` existe, avec raison `bridge Scenario uniquement`, car ce n'est pas encore un `CinematicAsset` canonique. Action reste desactivee jusqu'a `ActionPublicContract` / `ConsequencePublicContract`. BranchByOutcome reste desactivee jusqu'aux mappings outcome -> edge.

Limites : pas de runtime, pas de Event -> Scene, pas de SceneRuntimePlan, pas de StorylineStep link, pas d'Action Registry, pas de Branch mapping, pas de donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-23 — Event to Scene Trigger Prep`.

## Mise a jour V1-23

Statut : `NS-SCENES-V1-23 — Event to Scene Trigger Prep` est DONE.

Decision : V1-23 ne code pas encore le lien persistant. L'audit montre que `MapEventDefinition` est un modele Freezed/JSON genere et que le bon niveau produit n'est pas l'event entier, mais la page/action active. Le contrat cible devient donc une action explicite `startScene` ou un `sceneTarget` equivalent porte par `MapEventPage`, avec reference vers une `SceneAsset` reelle et diagnostics refs inconnues.

Options rejetees : `MapEventDefinition.sceneId` direct, car il ignore les pages conditionnelles ; metadata string libre, car trop implicite ; `ScenarioAsset`, car il resterait un bridge legacy et deviendrait trop facilement le modele final.

Limites : aucun code, aucun widget, aucun modele, aucun generated file, aucun runtime et aucune donnee Selbrume ne sont ajoutes.

Prochain lot exact : `NS-SCENES-V1-23-bis — Event to Scene Link V0`.

## Mise a jour V1-23-bis

Statut : `NS-SCENES-V1-23-bis — Event to Scene Link V0` est DONE.

Decision : le contrat persistant minimal vit sur `MapEventPage.sceneTarget`, avec un `MapEventSceneTarget(sceneId)` explicite. Le lien est authoring-only et cible une `SceneAsset` reelle depuis `ProjectManifest.scenes`. Aucun champ `sceneId` global n'est ajoute a `MapEventDefinition`, aucun `metadata['sceneId']` ne devient source de verite et aucun `ScenarioAsset` n'est promu.

Implementation : operations pures `setMapEventPageSceneTarget` / `clearMapEventPageSceneTarget`, validation via `MapValidator`, diagnostics purs `diagnoseEventSceneLinks`, picker Scene V1 dans `EventPropertiesPanel`, clear du lien et message `Lien authoring uniquement, runtime Scene à venir.` Les messages/scripts legacy restent visibles et preserves.

Limites : pas de runtime Scene, pas de `SceneRuntimePlan`, pas de `SceneRuntimeExecutor`, pas de `StorylineStep.sceneLinkIds`, pas d'Event -> Scene runtime, pas de fake event/scene/ref, pas de donnees Selbrume.

Tests : JSON/copyWith, operations set/clear, validator refs, diagnostics event-scene, widget picker/select/clear, workspace Scenes, overview shell, projection narrative, analyzes ciblees.

Prochain lot exact : `NS-SCENES-V1-24 — Scene Runtime Plan V0`.

## Mise a jour V1-24

Statut : `NS-SCENES-V1-24 — Scene Runtime Plan V0` est DONE.

Decision : V1-24 ajoute un modele runtime-plan pur dans `map_core` et un builder `buildSceneRuntimePlan(SceneAsset)` qui compile les nodes et edges logiques en intents declaratifs sans executer quoi que ce soit. Le plan expose `sceneId`, `startNodeId`, nodes, edges et outcomes declares. Il ignore completement `SceneGraphLayout`.

Intents supportes : `start`, `end`, `evaluateCondition`, `merge`, `showDialogue`, `startBattle`, `playCinematic`. Le dialogue expose seulement `dialogueId`, `yarnNodeName` et outcomes declares par payload ; aucun outcome Yarn n'est invente. Le battle expose seulement `battleKind`, refs trainer/template/npc et outcomes declares par payload ; aucun import `map_battle`. Cinematic reste bridgeOnly en warning. Action et BranchByOutcome restent erreurs runtime-plan avec `plan == null`.

Limites : pas de `SceneRuntimeExecutor`, pas de runtime Scene, pas de Event -> Scene runtime trigger, pas de StorylineStep link, pas de ScenarioAsset promu, pas de fake refs/outcomes, pas de donnees Selbrume.

Tests : `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-25 — Diagnostics / Validator Expansion`.

## Mise a jour V1-25

Statut : `NS-SCENES-V1-25 — Diagnostics / Validator Expansion` est DONE.

Decision : V1-25 renforce le filet de securite sans ouvrir l'execution runtime. Les diagnostics locaux couvrent les ports V0 incompatibles, le type de lien incoherent, les doublons depuis un port single-output, les ports requis manquants, les nodes non atteignables, les fins non atteignables et les cycles V0 non supportes. Les diagnostics cross-project verifient Dialogue, Battle trainer, Fact, World Rule future source et Cinematic bridge via `ProjectManifest` et `LinkedAssetContractsSnapshot`.

Event -> Scene : `diagnoseEventSceneLinks` detecte maintenant les pages qui melangent `sceneTarget` avec message/script legacy et signale une erreur runtime-readiness quand la Scene cible ne peut pas produire de `SceneRuntimePlan`.

Limites : pas d'editor surfacing nouveau, pas de runtime Scene, pas de `SceneRuntimeExecutor`, pas de ScenarioAsset promu, pas de StorylineStep link, pas de donnees Selbrume. Les payloads/refs impossibles via les constructeurs stricts restent proteges au niveau modele.

Tests : `cd packages/map_core && dart test test/scene_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_project_diagnostics_test.dart`, `cd packages/map_core && dart test test/event_scene_link_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-25-bis — Dialogue/Battle Ports Authoring V0`.

## Mise a jour V1-25-bis

Statut : `NS-SCENES-V1-25-bis — Dialogue/Battle Ports Authoring V0` est DONE.

Decision : V1-25-bis insere un verrou authoring avant l'executor runtime. Les nodes Dialogue Yarn et Battle existaient avec de vraies refs depuis les pickers, mais restaient difficiles a orchestrer. Le lot ajoute donc `yarnDialogue.completed -> defaultFlow` et `battle.victory/defeat -> battleVictory/battleDefeat` dans la source de verite des ports authorables, les diagnostics et les tests runtime-plan.

UI : le canvas expose ces ports visuels, permet le drag/drop via le systeme V1-15 existant, conserve les regles V1-13/V1-25 et ajoute un visual gate `ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png`. Les screenshots V1-15/V1-17/V1-18 ont ete rafraichis par le test golden complet pour rester coherents avec le rendu courant des ports.

Limites : pas de runtime Scene, pas de parsing Yarn, pas d'outcomes Yarn inventes, pas de BranchByOutcome authoring, pas de nouveaux ports Cinematic/Action, pas de `map_battle`, pas de donnees Selbrume.

Tests : `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`, `cd packages/map_core && dart test test/scene_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`, `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-26 — Scene Runtime Executor MVP`.

## Mise a jour V1-26

Statut : `NS-SCENES-V1-26 — Scene Runtime Executor MVP` est DONE.

Decision : V1-26 place l'executor dans `map_core`, pas dans `map_runtime`, pour garder un moteur pur et testable. `SceneRuntimeExecutor` prend un `SceneRuntimePlan`, appelle des callbacks injectes pour les intents metier et suit uniquement les ports retournes. Le plan reste la frontiere : pas de `ProjectManifest`, pas de layout, pas de disque, pas de Yarn parser, pas de battle engine.

API : `SceneRuntimeExecutor`, `SceneRuntimeExecutionCallbacks`, `SceneRuntimeExecutionResult`, `SceneRuntimeExecutionStatus`, `SceneRuntimeExecutionTraceEntry` et `SceneRuntimeExecutionErrorCode` sont exportes par `map_core.dart`.

Comportement : start/merge suivent `completed`, end termine, condition suit `true`/`false`, dialogue suit `completed`, battle suit `victory`/`defeat`, cinematic suit `completed`. Les erreurs de transition manquante/ambigue, cible absente, port callback non supporte, callback en erreur et limite `maxSteps` retournent un resultat `failed` propre.

Limites : pas de branchement `PlayableMapGame`, pas de Event -> Scene runtime trigger, pas de `ScenarioRuntimeExecutor` modifie, pas de `StorylineStep.sceneLinkIds`, pas de mutation `GameState`, pas de Fact/World Rule/consequence appliquee, pas de donnee Selbrume.

Tests : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

## Mise a jour V1-26-bis

Statut : `NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening` est DONE.

Decision : V1-26 est confirme apres audit/evidence. `SceneRuntimeExecutor` reste un executor pur de `SceneRuntimePlan`, sans import runtime/battle/gameplay/editor, sans `ProjectManifest`, sans layout, sans disque, sans Yarn parser, sans battle engine et sans consequence persistante.

Evidence : le rapport V1-26-bis reproduit integralement `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` et `packages/map_core/test/scene_runtime_executor_test.dart`, documente les reviews imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et relance les tests/analyze V1-26.

Corrections code : aucune. La review n'a pas trouve de faille concrete justifiant une modification de l'executor ou des tests.

Limites : V1-27 n'est pas commence. Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `ScenarioAsset`, `StorylineStep.sceneLinkIds`, Fact write, World Rule projection runtime ou donnee Selbrume n'est ajoute.

Tests : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

## Mise a jour V1-27

Statut : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0` est DONE.

Decision : le contexte Map Editor consomme maintenant un read model pur `WorldRuleTargetContextReadModel` pour relire les rules par cible explicite `mapEvent`, `mapEntity` et `npcDialogue`, avec labels lisibles et diagnostics attaches. Le read model ne lit pas `GameState`, n'ecrit rien, ne touche ni disque ni runtime.

Implementation editor : l'inspector Event affiche les rules ciblant l'event, leur etat active/inactive, source, effet et diagnostics ; il permet de creer une rule V0 `Fact -> eventEnabled/eventDisabled/eventHidden` avec target auto depuis la map et l'event selectionnes. L'inspector Entity affiche/toggle les rules `mapEntity`; pour les PNJ il affiche/toggle aussi `npcDialogue`.

Limites : pas de creation avancee pour entite/PNJ depuis leur inspector, pas de runtime Scene, pas d'application dynamique des rules au monde, pas de collision/warp dynamique, pas de donnees Selbrume.

Tests : core WorldRule existants + read model cible, editor event/entity/overview/shell/projection/design guardrail, analyse ciblee editor, `dart analyze` core, visual gate `ns_scenes_v1_27_world_rules_map_editor_integration_v0.png`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`.

## Mise a jour V1-28

Statut : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep` est DONE.

Decision : le lot reste core-first et ajoute `GoldenSliceReadinessReport` dans `map_core` pour verifier une fixture neutre event -> scene -> dialogue -> battle -> victory/defeat, avec diagnostics existants, `SceneRuntimePlan`, `SceneRuntimeExecutor`, refs Dialogue/Battle et World Rules/Facts authoring-ready.

Fixture : `map_test`, `event_gate`, `scene_test_rival`, `dialogue_test_intro`, `trainer_test_rival`, `fact_test_rival_defeated`, `world_rule_test_unlock_gate`. Aucun contenu produit Selbrume, aucun `selbrume/**`, aucun runtime map.

Limites : pas de Dialogue outcomes avances, pas de BranchByOutcome, pas de consequences persistantes, pas de Fact write runtime, pas d'application World Rule runtime, pas de StorylineStep link.

Tests : `golden_slice_readiness_test`, Event->Scene diagnostics, Scene runtime plan, Scene runtime executor, linked asset contracts, Scene diagnostics, WorldRule diagnostics, WorldRule target context, `dart analyze`.

Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.

## Mise a jour V1-28-bis

Statut : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0` est DONE.

Decision : le hook runtime map est branche de facon bornee. Quand la page active d'un event porte `sceneTarget`, le runtime tente explicitement la Scene V1 et ne lance pas automatiquement le message ou script legacy de cette meme page. Le service `SceneEventRuntimeHook` reste testable hors Flame : il resout la scene, refuse les scenes absentes, refuse les diagnostics bloquants, refuse les plans non buildables, puis execute `SceneRuntimeExecutor`.

Integration runtime : `PlayableMapGame` appelle le hook depuis l'interaction event. Les callbacks concrets sont volontairement limites : condition lit seulement les sources V0 existantes sans mutation, dialogue ouvre le dialogue existant mais n'est pas encore awaitable par l'executor, cinematic est bridge acknowledged, battle reel est refuse proprement car le runtime actuel ne fournit pas encore un resultat awaitable `victory`/`defeat` sans l'inventer.

Limites : pas de Fact write, pas de World Rule runtime application, pas de consequence persistante automatique, pas de ScenarioAsset promu, pas de StorylineStep link, pas de BranchByOutcome, pas de runtime save et pas de donnee produit.

Tests : `cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart`, analyse ciblee `map_runtime`, tests core readiness/runtime-plan/executor et `map_core` analyze.

Prochain lot exact : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep`.

## Mise a jour V1-28-ter

Statut : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep` est DONE.

Decision : les consequences Scene V1 doivent devenir des objets authoring explicites, lisibles et diagnostiquables. Le contrat rejette les writes implicites depuis EndNode seul, edge, MapEventPage, StorylineStep ou metadata. Le chemin recommande est un futur ActionNode/Consequence V0 dans le graph, avec `setFact` et `markEventConsumed` comme V0 strict.

World Rules : une Scene ne les applique pas directement. Elle change un etat persistant lisible ; les World Rules le lisent et projettent les effets visibles.

Battle/dialogue : Battle.victory/defeat doit attendre un adapter awaitable reel ; Dialogue outcomes detailles attendent Dialogue Studio et ne sont pas inventes. `BranchByOutcome` reste reporte.

Prochain lot exact : `NS-SCENES-V1-28-quater — Scene Consequence Model V0`.

## Mise a jour V1-28-quater

Statut : `NS-SCENES-V1-28-quater — Scene Consequence Model V0` est DONE.

Decision : les consequences Scene V1 ont maintenant un modele authoring pur et typé : `SceneConsequence.setFact` et `SceneConsequence.markEventConsumed`. Le modele est integre prudemment a `SceneActionPayload` sans promouvoir l'ancien `actionKind` libre.

Diagnostics : `setFact` est valide contre la Fact Registry, `markEventConsumed` contre map/event quand les `MapData` sont fournis, et les anciens ActionNode libres restent unsupported authoring. Les references manquantes sont bloquantes.

Runtime : ActionNode reste refuse par `buildSceneRuntimePlan`. Aucun `GameState` n'est mute et aucun package runtime/editor/gameplay/battle n'est modifie.

Tests : `scene_consequence_model_test`, `scene_diagnostics_test`, `scene_asset_json_test`, `scene_runtime_plan_test`, `golden_slice_readiness_test`, `scene_project_diagnostics_test`, `dart analyze`.

Prochain lot exact : `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0`.

## Mise a jour V1-28-quinquies

Statut : `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0` est DONE.

Decision : le Scene Builder peut maintenant produire une consequence typée qui devient executable via `applyConsequence`, mais uniquement pour les deux writes V0 controles : `setFact` et `markEventConsumed`.

Runtime : les consequences sont stagees pendant l'execution Scene puis appliquees en une seule transaction logique si la Scene complete. En cas de callback en erreur, de ref Fact/map/event inconnue ou d'echec de write, le `GameState` original est conserve.

Limites : aucune application directe de World Rule, aucune completion de StorylineStep, aucun adapter battle, aucun picker/action supplementaire et aucune donnee Selbrume.

Tests : core plan/executor/diagnostics/consequence model, runtime writer/hook, analyzes cibles, recherches anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`.

## Mise a jour V1-28-sexies

Statut : `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0` est DONE.

Decision : le runtime Scene V1 dispose maintenant d'un adapter battle awaitable borne. Il transforme uniquement un resultat battle runtime reel en port Scene : `victory` ou `defeat`.

Integration : `PlayableMapGame` remplace le refus `UnsupportedError` du callback `startBattle` par `SceneBattleRuntimeOutcomeAdapter`, puis lance le handoff trainer battle existant. Le completer local est resolu dans `_onBattleFinished` a partir du `BattleOutcome` runtime. Les outcomes `runaway` et `captured` restent non supportes en Scene V1 V0.

Limites : pas de refactor battle engine, pas de modification `map_battle`, pas de consequence Scene dans l'adapter, pas de StorylineStep link, pas de World Rule direct apply et pas de donnee Selbrume.

Tests : adapter victory/defeat/missing refs/failures/no mutation, hook victory/defeat avec consequences V0, no staged write on battle failure, core plan/executor/consequence non-regression, analyzes et recherches anti-scope.

Prochain lot exact : `NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0`.

## Mise a jour V1-28-septies

Statut : `NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0` est DONE.

Decision : le DialogueNode Scene V1 utilise maintenant un adapter awaitable. Le callback `showDialogue` de `PlayableMapGame` ouvre le dialogue runtime existant et attend la fermeture reelle via `DialogueOverlayComponent.onFinished` avant de retourner `completed`. Les erreurs d'ouverture, de chargement ou d'annulation retournent un failure controle qui fait echouer la Scene et discard les consequences stagees.

Limites : aucun outcome Yarn detaille, aucun `BranchByOutcome`, aucun parser Yarn, aucun write `GameState` dans l'adapter, aucune World Rule appliquee, aucun `StorylineStep.sceneLinkIds`, aucun refactor Dialogue Studio.

Tests : adapter dialogue awaitable, hook pending/completed/failure avec consequence stagee, tests core runtime-plan/executor/consequence, analyzes runtime/core et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`.

## Mise a jour V1-28-octies

Statut : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0` est DONE.

Decision : le smoke reste applicatif hors Flame et utilise les vraies briques runtime testables : `SceneEventRuntimeHook`, `SceneRuntimeExecutor`, `SceneDialogueRuntimeAwaitableAdapter`, `SceneBattleRuntimeOutcomeAdapter` et `SceneConsequenceRuntimeWriter`.

Preuve : le test neutre couvre la branche victory avec dialogue pending puis completed, battle awaitable victory, `setFact`, `markEventConsumed` et commit atomique du `GameState`; la branche defeat commit seulement le Fact defeat; le cas failure abandonne une consequence stagee sans write partiel.

Limites : pas de runtime Flame complet, pas de StorylineStep link, pas de World Rule direct apply, pas de BranchByOutcome, pas d'outcome Yarn invente, pas de donnee Selbrume produit.

Prochain lot exact : `NS-SCENES-V1-29 — StorylineStep to Scene Link`.

## Mise a jour V1-29

Statut : `NS-SCENES-V1-29 — StorylineStep to Scene Link` est DONE.

Decision : le lien `StorylineStep.sceneLinkIds` est active uniquement comme relation de lecture, organisation et progression narrative. Event -> Scene reste le declencheur runtime local. Aucune Step ne lance de Scene, ne complete une progression et n'ecrit dans `GameState`.

Scope realise : operations pures add/remove/replace/clear dans `map_core`, diagnostics refs inconnues et scenes liees problematiques, read model StorylineStep -> Scenes, section `Scenes liees` dans l'edition de Step avec picker depuis `ProjectManifest.scenes`, suppression de lien et message authoring/progression only.

Preuve : tests core JSON/operations/diagnostics/read model, `scene_runtime_plan_test.dart`, test widget Storylines scene links avec golden V1-29, analyses ciblees, recherches anti-Selbrume/anti-runtime et `git diff --check`.

Limites : pas de cross-navigation avancee vers le Scene Builder, pas d'impact runtime, pas de StorylineStep completion, pas de remplacement `MapEventPage.sceneTarget`, pas de donnees Selbrume.

Prochain lot initialement prevu : `NS-SCENES-V1-30 — Scene V1 Beta Readiness Checkpoint`. Il est remplace par `NS-SCENES-V1-30 — Scene Node Payload Editing V0` pour corriger les refs Dialogue/Battle avant checkpoint.

## Mise a jour V1-30

Statut : `NS-SCENES-V1-30 — Scene Node Payload Editing V0` est DONE.

Decision : les payloads Dialogue Yarn et Battle trainer deviennent editables depuis l'inspecteur uniquement si des contrats publics reels existent. Les nodes restent lecture seule quand aucun contrat fiable n'est disponible, afin d'eviter un retour aux IDs libres.

Scope realise : operations pures `updateSceneYarnDialoguePayload` et `updateSceneBattlePayload`, pickers inspecteur Dialogue/Battle, update en memoire de `ProjectManifest.scenes`, preservation du graph/layout/outcomes et visual gate.

Limites : pas de Yarn outcomes detailles, pas de BranchByOutcome, pas de Cinematic/Action payload authoring avance, pas de runtime Scene, pas de seed Selbrume.

Prochain lot exact initialement prevu : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`.

## Mise a jour V1-30-bis

Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.

Decision : la correction du graph passe avant Consequence Authoring UI. Les nodes non-start deviennent supprimables depuis l'inspecteur, avec confirmation, suppression des edges entrants/sortants et nettoyage des layouts. Le Start reste protege et le dernier End est bloque pour eviter une scene structurellement trop cassee.

Scope realise : operation pure `removeSceneNodeDraft` elargie et gardee, helper de blocage `sceneNodeDraftRemovalBlocker`, danger zone dans l'inspecteur Scene, update en memoire de `ProjectManifest.scenes`, tests core/editor et visual gate.

Limites : pas de reconnexion automatique, pas de suppression via clavier, pas de suppression de Scene/Event/Storyline, pas de runtime, pas de Consequence UI demarree.

Prochain lot exact : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`.

## Mise a jour V1-31

Statut : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0` est DONE.

Decision : l'ActionNode est ouvert uniquement pour les consequences V0 typées. Le flux no-code autorise `setFact(factId, true/false)` depuis la Fact Registry et `markEventConsumed(mapId, eventId)` depuis les events reels de la map active. Aucun ID libre ni action generique n'est expose dans le workflow normal.

Scope realise : creation d'Action/Consequence depuis la palette quand une cible existe, pickers Facts/events, edition inspecteur des consequences, update memoire de `ProjectManifest.scenes`, port `completed` connectable, diagnostics compatibles et visual gate.

Limites : pas de `giveItem`, `warpPlayer`, StoryStep completion, World Rule direct apply, BranchByOutcome, Yarn outcomes, Cinematic payload authoring, runtime Scene, mutation GameState depuis editor, Event -> Scene ou StorylineStep link.

Prochain lot exact : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`.

## Mise a jour V1-31-bis

Statut : `NS-SCENES-V1-31-bis — Scene Consequence Runtime Evidence Sweep` est DONE.

Decision : aucun nouveau comportement n'etait necessaire. L'evidence sweep confirme que l'ActionNode consequence authorable de V1-31 reste compatible avec diagnostics, runtime-plan, executor, hook runtime, writer consequences et golden smoke.

Preuve : les tests obligatoires map_core, map_runtime et map_editor ont ete relances, ainsi que les analyzes et checks anti-scope. `Action.completed` compile et s'execute via `applyConsequence`; les writes runtime restent stages puis commits seulement en fin de Scene completee.

Limites : pas de code produit modifie, pas de runtime nouveau, pas de GameState mutation depuis editor, pas de BranchByOutcome, pas d'outcomes Yarn, pas de World Rule direct apply et pas de donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`.

## Mise a jour V1-32

Statut : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint` est DONE.

Verdict : le Scene Builder est credible pour une beta controlee d'authoring et le chemin runtime neutre est prouve en smoke. En revanche, le systeme ne doit pas etre declare pret pour une beta golden-slice jouable complete tant que la persistance ciblee des writes Scene, la projection runtime des World Rules et le vrai parcours PlayableMapGame/overlay ne sont pas verrouilles.

Decision roadmap : le prochain lot exact devient `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`. Ce lot doit relier explicitement `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter`, `FileGameSaveRepository` et la relecture Conditions/World Rules apres reload.

Limites confirmees : `BranchByOutcome` reste reporte, les outcomes Yarn detailles ne sont pas authorables/runtime, Cinematic reste bridge/provisoire, `completeStoryStep` runtime Scene reste absent, l'overview Facts doit etre aligne, les diagnostics no-code doivent encore etre durcis, et l'undo/redo ou la suppression clavier des graphes restent hors beta critique.

Prochain lot exact : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.

## Mise a jour V1-33

Statut : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0` est DONE.

Decision : le verrou persistence Scene-specific est ferme par un test runtime dedie. La chaine couverte est `SceneEventRuntimeHook` -> consequences V0 stagees -> `SceneConsequenceRuntimeWriter` -> `GameState` -> `FileGameSaveRepository` -> reload -> Condition Scene V1 -> `projectWorldRuleEffects`.

Limites : pas de projection runtime World Rules, pas d'application visuelle du monde, pas de nouveau type de consequence, pas d'editor, pas de `PlayableMapGame` full golden slice et aucune donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0`.

## Mise a jour V1-34

Statut : `NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0` est DONE.

Decision : les World Rules restent des projections declaratives lues depuis `ProjectManifest.worldRules` et `GameState`; elles ne deviennent pas des consequences Scene et n'ecrivent ni `GameState`, ni `ProjectManifest`, ni `MapData`. Le runtime dispose maintenant d'un hook borne `RuntimeWorldRuleProjectionHook` qui expose un etat lisible : entites forcees visibles/cachees, events actives/desactives/caches et overrides de dialogue PNJ.

Integration : `PlayableMapGame` utilise cette projection pour la presence PNJ, les overrides de dialogue PNJ et la possibilite de trigger un map event. Apres une Scene qui ecrit un Fact, la presence PNJ est rafraichie ; les events relisent la projection au prochain trigger.

Limites : pas de manager UI Facts/World Rules, pas de nouveau type de World Rule, pas de mutation definitive du monde, pas de collision/warp/tile dynamic state, pas de `completeStoryStep`, pas de `giveItem`, pas de BranchByOutcome et aucune donnee Selbrume.

Prochain lot exact realise : `NS-SCENES-V1-35 — Facts & World Rules Manager UI V0`.

## Mise a jour V1-35

Statut : `NS-SCENES-V1-35 — Facts & World Rules Manager UI V0` est DONE.

Decision : l'authoring centralise Facts / World Rules quitte l'etat d'apercu. Narrative Studio expose deux entrees actives qui ouvrent un workspace partage : onglet Facts pour les faits persistants lisibles et onglet Regles du monde pour les changements visibles derives.

Scope realise : read model pur manager, usages Fact depuis Scenes et World Rules, suppression Fact protegee, workspace UI no-code, creation/edition/suppression Facts, creation/edition/toggle/suppression World Rules V0, pickers reels source/cible/effet/dialogue, diagnostics visibles, overview/sidebar aligne, visual gate V1-35 et goldens Scene Builder regénérés pour le chrome commun.

Limites : pas de runtime nouveau, pas de nouvel effet World Rule, pas de nouvelle source, pas de nouvelle SceneConsequence, pas de mutation `GameState` depuis l'editor, pas de seed Selbrume, pas de workflow principal par ID technique.

Prochain lot exact : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`.

## Mise a jour V1-36

Statut : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision` est DONE.

Decision : Cinematic V1 ne doit pas heriter du graphe `ScenarioAsset`. Le futur contrat canonique est un `CinematicAsset` dedie, lineaire, visuel, referencable par un `SceneCinematicPayload.cinematicId`, expose par une Cinematics Library, puis editable dans un Cinematic Builder V2. Cutscene Studio et `ScenarioAsset` restent disponibles comme bridge/source transitoire, avec statut legacy explicite.

Scope realise : audit documentaire Cutscene Studio, `ScenarioAsset`, `ScenarioRuntimeExecutor`, `RuntimeCutsceneAsset`, `SceneRuntimePlan.playCinematic`, `CinematicPublicContract.scenarioBridge` et frontieres produit Scene/Cinematic/Event/Yarn/Facts/World Rules.

Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime cinematic, aucune migration, aucune donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-37 — CinematicAsset Core Model V0`.

## Mise a jour V1-37

Statut : `NS-SCENES-V1-37 — CinematicAsset Core Model V0` est DONE.

Decision : Cinematic V1 a maintenant son modele core canonique `CinematicAsset`, lineaire et distinct de `ScenarioAsset`. Le bridge `scenarioBridge` reste visible mais `bridgeOnly`; aucun ScenarioAsset n'est promu ou migre silencieusement.

Scope realise : modele cinematic/timeline/steps/acteurs/legacy bridge, `ProjectManifest.cinematics`, operations authoring minimales, diagnostics cinematic, contrats publics canonical + bridge, diagnostics Scene project-aware, tests core et analyze.

Limites : pas de UI, pas de Cinematics Library, pas de Builder V2, pas de runtime cinematic, pas de migration legacy, pas de donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-38 — Cinematics Library V0`.

## Mise a jour V1-38

Statut : `NS-SCENES-V1-38 — Cinematics Library V0` est DONE.

Decision : Narrative Studio expose maintenant une Cinematics Library dediee aux `CinematicAsset` canoniques. Les `ScenarioAsset` / Cutscene Studio restent visibles comme bridges legacy explicites, mais ne deviennent ni le modele canonique ni une source migree silencieusement.

Scope realise : read model pur `buildCinematicsLibraryReadModel`, workspace `CinematicsLibraryWorkspace`, creation shell metadata-only, edition titre/description/notes, suppression protegee des assets non references, usages Scene, diagnostics cinematic, overview/sidebar alignes, ancien Cutscene Studio accessible depuis la Library.

Limites : pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration Scenario/Cutscene, pas de picker Scene Builder cinematic, pas de donnee Selbrume.

## Mise a jour V1-39

Statut : `NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0` est DONE.

Decision : Scene Builder autorise la creation et l'edition d'un `CinematicNode` seulement via des `CinematicAsset` canoniques. Les bridges `ScenarioAsset`/Cutscene Studio restent visibles comme legacy, mais ne sont pas le workflow principal.

Scope realise : operations pures cinematic, picker canonical-only, inspector cinematic, sortie `completed` authorable, diagnostics ref inconnue/bridge legacy, tests core/editor, visual gate et roadmaps.

Limites : pas de Builder V2, pas de runtime cinematic, pas de timeline editor, pas de migration legacy, pas de donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`.

## Mise a jour V1-40

Statut : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0` est DONE.

Decision : le Scene runtime passe par un adapter awaitable pour les `CinematicAsset` canoniques. Les bridges `ScenarioAsset` restent legacy explicites et les refs unknown echouent proprement.

Scope realise : `SceneCinematicRuntimeAwaitableAdapter`, `SceneCinematicRuntimeAwaitableResult`, request/player V0, player no-visual borne, callback `PlayableMapGame.playCinematic`, tests de temporalite et no partial writes.

Limites : pas de Builder V2, pas de timeline editor UI, pas de playback visuel complet, pas de migration legacy, pas de gameplay depuis Cinematic.

Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.

## Mise a jour V1-41

Statut : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract` est DONE.

Decision : le futur Cinematic Builder V0 reste un assembleur de blocs cinematic simples, ordonnes et no-code, ouvert depuis la Cinematics Library. Il n'est ni Scene Builder, ni Dialogue Studio, ni Cutscene Studio legacy, ni timeline frame-perfect. Le futur Runtime Playback reste un host borne qui lit la sequence, resolve acteurs/camera/dialogue/audio/FX selon capacites, retourne `completed` et ne produit aucun effet gameplay.

Scope realise : rapport documentaire V1-41, specification Builder V0, specification Runtime Playback V0/V1, taxonomie des blocs, capability matrix, diagnostics futurs, frontieres Scene/Dialogue/Battle/Facts/World Rules/ScenarioAsset et roadmap stricte V1-42 a V1-48.

Limites : aucun Builder code, aucune timeline editor, aucun widget, aucun modele, aucun runtime visuel et aucun package modifie. V1-41 n'a pas demarre V1-42.

Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.

## Mise a jour V1-42

Statut : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est DONE.

Decision : le Builder V0 est branche comme surface read-only depuis la Cinematics Library, sans nouveau mode global et sans toucher aux contrats core/runtime. Il consomme le read model de Library, ouvre seulement les entrees `CinematicAsset` canoniques et laisse les bridges legacy dans un etat explicite non ouvrable.

Scope realise : header, retour Library, titre/id selectionnes, resume diagnostics, palette de blocs verrouillee, apercu sandbox, deroule read-only, inspecteur placeholder, etats timeline vide/existante, boutons Valider/Apercu/Sauvegarder inactifs, screenshot V1-42 et tests widget dedies.

Limites : pas de creation de blocs, pas de suppression de blocs, pas de reorganisation de timeline, pas de player visuel, pas de mutation `ProjectManifest`, pas de nouveau modele et pas de package runtime/gameplay/battle/examples modifie.

Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.

## Mise a jour V1-43

Statut : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0` est DONE.

Decision : le Builder V0 reste read-only mais devient inspectable. La Library passe le `CinematicAsset` canonique complet au Builder ; aucun enrichissement `map_core` n'etait necessaire. La selection est locale dans `CinematicBuilderWorkspace` et ne touche jamais au manifest.

Scope realise : cartes de steps ordonnees, selection visuelle, inspecteur de bloc detaille, diagnostics du step selectionne, preview sandbox avec rappel du bloc, palette verrouillee, tests de non-mutation et screenshot V1-43.

Limites : pas de creation de blocs, pas de suppression de blocs, pas de changement d'ordre, pas de sauvegarde de deroule, pas de vrai playback visuel, pas de runtime, pas de migration legacy et pas de modele core modifie.

Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.

## Mise a jour V1-44

Statut : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` est DONE.

Decision : le Cinematic Builder gagne seulement un brouillon authoring neutre. Il est stocke comme `CinematicTimelineStep.marker` avec metadata de provenance authoring, ce qui garde le deroule inspectable et modifiable sans ouvrir les vrais blocs moteur.

Scope realise : ajout et retrait via operations pures, ID stable, insertion apres le bloc selectionne ou a la fin, refus des steps inconnus et non-brouillons, mutation `ProjectManifest.cinematics` en memoire, selection automatique, inspecteur lecture seule et bouton de retrait visible seulement sur un brouillon.

Limites : pas de Camera/Fondu/Attente/Dialogue/FX/Son/Acteur authorables, pas d'edition de payload, pas de changement d'ordre, pas de preview jouable, pas de runtime, pas de migration legacy.

Preuve : tests core `cinematic_authoring_operations` et `cinematic_diagnostics`, tests widget Builder et Library, analyse ciblee et capture V1-44.

Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.

## Mise a jour V1-45

Statut : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0` est DONE.

Decision : le modele supportait deja `wait`, `fade` et `camera`. Le lot active donc ces trois blocs dans le Builder sans enum nouveau, sans migration et sans build_runner. Les metadata restent authoring-only : `authoring.kind=basicBlock`, `authoring.block=wait|fade|camera`, modes `fade.mode` et `camera.mode`.

Scope realise : operations pures `addCinematicTimelineBasicBlockStep`, `updateCinematicTimelineBasicBlockStep`, `removeCinematicTimelineAuthoringStep`, helpers d'identification authoring-owned, UI palette active Attente/Fondu/Camera, inspecteur avec presets/modes, suppression protegee, mutation memoire et refresh Library.

Limites : pas d'acteur, pas de dialogue cinematic, pas de FX, pas de son, pas de cible map complexe, pas de preview jouable, pas de drag/drop, pas de reordonnancement et pas de runtime.

Preuve : tests core authoring/diagnostics, tests widget Builder/Library, analyse ciblee et capture V1-45.

Prochain lot exact : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`.

## Mise a jour V1-46

Statut : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0` est DONE.

Decision : le modele Cinematic possedait deja les briques necessaires (`requiredActors`, `actorId`, `actorFace`). Le lot a donc ajoute l'authoring et les validations autour de ces refs, sans migration ni runtime. La direction V0 est un enum borne `up`, `down`, `left`, `right`, stocke dans `actor.direction`.

Scope realise : ajout d'acteur requis depuis la palette, bloc Orientation acteur active seulement si au moins un acteur existe, creation du step `actorFace` apres la selection courante, edition inspecteur par picker acteur et boutons direction, badges acteur/direction dans le deroule, Library rafraichie, diagnostic d'acteur inconnu.

Limites : pas de mouvement, pas de pathfinding, pas de drag/drop, pas de timeline multi-track, pas de preview jouable, pas de dialogue/FX/Son, pas de runtime.

Preuve : tests core authoring/diagnostics, tests widget Builder/Library, analyse `map_core`, analyse editor ciblee et capture V1-46.

Prochain lot exact : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.

## Mise a jour V1-47

Statut : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract` est DONE.

Decision : V1-47 ne code pas le deplacement acteur. L'audit constate que `CinematicTimelineStepKind.actorMove` existe deja et que les champs generiques `actorId`, `targetId`, `durationMs` et `metadata` pourraient porter un futur bloc, mais que le contrat de cible, de lane et de diagnostics doit rester explicite avant toute UI authorable.

Contrat retenu : `actorId` reference obligatoirement `requiredActors`, lane derivee de `actorId`, duree par presets bornes, `movementMode` authoring-only, `pathMode=direct` en V0, cible recommandee sous forme de waypoint/target authoring stable et diagnostiquable. Les positions libres, entites runtime brutes, courbes et chemins manuels sont reportes.

Limites : pas de fichiers `packages/` modifies, pas de build_runner, pas de widget lane, pas de drag/drop, pas de reordonnancement, pas de preview runtime, pas de pathfinding, pas de donnees produit.

Preuve : rapport V1-47, roadmaps seules, checks anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

## Mise a jour V1-48

Statut : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0` est DONE.

Decision : la projection par lanes est un read model pur `map_core`, pas une construction locale seulement editor. Elle expose lanes, steps, `stepIndex`, labels acteur, badges et statut authoring-owned sans muter `CinematicAsset`.

Scope realise : le Builder remplace le libelle `Déroulé read-only` par `Timeline par pistes`, affiche les lanes derivees, conserve l'ordre lineaire via index global, selectionne un bloc depuis une lane, synchronise inspecteur et preview placeholder, garde Attente/Fondu/Camera/Orientation acteur fonctionnels et laisse `Déplacement acteur` verrouille.

Limites : lanes derivees et non persistees, pas de multi-track reel, pas de drag/drop, pas de reorder, pas d'overlap, pas de actorMove authorable, pas de runtime, pas de donnees produit.

Preuve : test core lane read model, non-regression Library read model, tests widget Builder/Library, analyse `map_core`, analyse editor ciblee et Visual Gate `ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png`.

Prochain lot exact : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0`.

## Mise a jour V1-49

Statut : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0` est DONE.

Decision : `actorMove` est authoring-owned et reste volontairement V0. Il reference un acteur requis et une cible authoring stable, pas une position libre ou une entite runtime. `pathMode` est stocke en metadata et verrouille a `direct`; seul `movementMode` permet de choisir l'intention visuelle `walk` ou `run`.

Scope realise : `CinematicAsset.movementTargets`, modele `CinematicMovementTargetRef`, operations add/update/remove cible, operations add/update bloc `actorMove`, diagnostics missing/unknown actor/target, duree invalide, movementMode/pathMode invalides, read model lane avec cible/mode, palette `Cibles de déplacement`, bouton `Déplacement acteur` active seulement avec acteur+cible, inspecteur acteur/cible/duree/marche-course/direct et Visual Gate.

Limites : pas de pathfinding, pas de courbe, pas de coordonnees `x/y`, pas de picker map/entity runtime, pas de preview jouable, pas de drag/drop, pas de reordonnancement, pas de multi-track persistant, pas de donnees Selbrume.

Preuve : tests core model/operations/diagnostics/lane, tests widget Builder/Library, analyses ciblees et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png`.

Prochain lot exact : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0`.

## Mise a jour V1-50

Statut : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0` est DONE.

Decision : le polish reste strictement authoring/editor. Les cibles de deplacement sont renommables et descriptibles sans changer le schema, les IDs restent secondaires, et les titres actorMove visibles sont derives depuis les refs acteur/cible pour eviter de transformer `step.label` en source de verite runtime.

Scope realise : carte `Cibles de deplacement` editable, suppression d'une cible libre, suppression desactivee avec message pour une cible utilisee, champs tokenises, resume humain actorMove, pathMode direct explique comme verrou V0, timeline par lanes et preview sandbox alignees sur `Acteur -> Cible`, tests core/editor et Visual Gate.

Limites : pas de time axis, pas de bar layout proportionnel, pas de playhead, pas de transport controls, pas de drag/drop, pas de reorder, pas de coordonnees libres, pas de pathfinding, pas de runtime, pas de preview jouable.

Preuve : tests core authoring/lane, tests widget Builder/Library, analyses ciblees et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png`.

Prochain lot exact : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`.

## Mise a jour V1-51

Statut : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0` est DONE.

Decision : V1-51 ajoute un read model temporel pur en `map_core`, puis l'utilise dans le Builder comme projection visuelle derivee. Les durees viennent de `durationMs` quand elles sont positives, sinon d'un fallback visuel 300 ms. Les barres utilisent `startMs/endMs` calcules depuis l'ordre lineaire et ne changent pas la source de verite.

Scope realise : axe de temps, ticks adaptatifs, badges de resume, lanes derivees, barres horizontales proportionnelles, metadata compacte dans les barres, selection/inspecteur/actions preserves et capture Visual Gate en ratio 1663x926 pour respecter la reference.

Limites : pas de drag/drop, resize, reorder, playhead fonctionnel, scrubber, transport playback, preview runtime, pathfinding, coordonnees libres, persistance `startMs/endMs` ou mutation du deroule lineaire.

Preuve : tests core time layout/lane/library, tests widget Builder/Library, analyses ciblees, checks anti-scope et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png`.

Prochain lot exact : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0`.

## Mise a jour V1-52

Statut : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0` est DONE.

Decision : V1-52 reste editor-only. Le Builder resout le bloc selectionne depuis `selectedStepId` dans le time layout derive V1-51, puis place un curseur vertical sur `selectedBlock.startMs`. Aucune API core supplementaire n'est ajoutee, car le read model expose deja les blocs et leurs temps derives.

Scope realise : badge de selection temporelle, aiguille verticale, handle decoratif, absence de curseur sans selection, non-interaction via `IgnorePointer`, clic axe sans seek, selection par barre preservee, inspecteur et preview sandbox inchanges.

Limites : pas de drag/drop, resize, reorder, scrubber, seek, timer, playback, transport controls fonctionnels, preview runtime, pathfinding, coordonnees libres ou persistance `cursorTimeMs`/`playheadTimeMs`.

Preuve : test widget dedie, suite Builder, suite Library, tests core V1-51 relances, analyze cible, checks anti-scope et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png`.

Prochain lot exact : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`.

## Mise a jour V1-53

Statut : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0` est DONE.

Decision : V1-53 ajoute uniquement une affordance visuelle de transport sous la timeline. Les boutons Reset, Play et Stop sont des `PokeMapButton` disabled (`onPressed = null`) avec tooltips ; V1-56 les rend icon-only afin de respecter les proportions finales de la timeline sans promettre de preview runtime.

Scope realise : placement sous les lanes temporelles, boutons icon-only disabled, tooltips Reset/Play/Stop, test non-mutation et selection/curseur preserves, capture Visual Gate au ratio 1663x926.

Limites : pas de playback, timer, seek, scrubber, transport fonctionnel, preview runtime, drag/drop, resize, reorder, persistance temporelle, JSON, build_runner ou modification runtime/gameplay/battle/examples.

Preuve : test widget transport disabled, suite Builder `+30`, suite Library `+10`, tests core time layout/lane, analyze cible, checks anti-scope et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png`.

Prochain lot exact : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`.

## Mise a jour V1-54

Statut : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0` est DONE.

Decision : V1-54 est un density pass visuel demande par Karim pour rapprocher la timeline de la reference : preview sandbox maintenue compacte, timeline plus lisible, pistes et barres densifiees, controles transport integres de facon moins massive.

Scope realise : lanes 28px, axe 24px, barres 22px, panel spacing reduit, empty state `Aucun step`, boutons Reset/Play/Stop en medium 76px, metadata strip sans IDs redondants, test widget de densite, capture Visual Gate V1-54.

Limites : pas de playback, timer, seek, scrubber, hover details, drag/drop, resize, reorder, zoom temporel, preview runtime, mutation JSON, build_runner ou modification runtime/gameplay/battle/examples.

Preuve : suite Builder `+32`, suite Library `+10`, tests core time layout/lane, analyze cible, checks anti-scope et screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png`. `flutter analyze` complet reste bloque par dette hors scope preexistante Pokemon SDK.

Prochain lot exact : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0`.

## Mise a jour V1-55

Statut : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0` est DONE.

Decision : V1-55 ajoute une inspection locale au survol, en detail inline stable au-dessus des lanes. Le tooltip est rejete pour eviter timing, fragilite golden et impression de mecanique plus avancee. Le hover n'est pas une selection et ne pilote ni l'inspecteur ni le curseur. V1-56 rend ce detail en overlay non interactif pour ne plus deplacer la grille.

Scope realise : `hoveredStepId` local dans le widget, detail no-code du bloc survole, highlight doux non prioritaire sur selected, nettoyage a la sortie de timeline, label semantic compact, test de hover actorFace/actorMove sans mutation, capture Visual Gate V1-55.

Limites : pas de navigation clavier/focus avance dans V1-55, pas de playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, preview runtime, persistance temporelle, JSON ou build_runner.

Preuve : suite Builder `+34`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png` et checks anti-scope.

Prochain lot exact corrige par demande Karim : `NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0`.

## Mise a jour V1-56

Statut : `NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0` est DONE.

Decision : V1-56 corrige la geometrie visuelle de la timeline avant le polish clavier. Ce changement est une demande de Karim, puis une reprise explicitement redemandee par Karim : les barres de timeline devaient respecter les proportions de l'image cible et ne plus ressembler a des badges de largeur quasi fixe ou a des rangées trop fines.

Scope realise : origine X commune entre ticks, barres et curseur ; largeur de barre derivee de `visualDurationMs`; `startMs` conserve comme source de placement horizontal ; minimum compact 72 px ; barres plus rectangulaires via `PokeMapCard.borderRadius`; split preview/timeline responsive ; preview sandbox compacte ; colonne pistes 128 px ; labels de pistes complets ; acteurs en label court ; axe 34 px ; rangées 48 px ; barres 36 px ; badges en ligne compacte ; hover details en overlay stable ; transport icon-only ; test widget de geometrie et de grille utile ; capture Visual Gate V1-56.

Limites : pas de navigation clavier/focus avance, playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, persistance temporelle, JSON ou build_runner.

Preuve : suite Builder `+36`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, test de proportion utile post-retour Karim, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png` et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`.

## Mise a jour V1-57

Statut : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0` est DONE.

Decision : le lot a ete fourni par Karim et reste volontairement borne : la timeline gagne une navigation clavier horizontale locale, pas un mode playback ni un editeur de montage. ArrowRight/ArrowLeft/Home/End selectionnent les blocs par ordre `stepIndex` et initialisent la selection quand elle est vide.

Scope realise : helpers de navigation clavier, `FocusNode` dedie a la timeline, badge `Navigation clavier`, selection locale via `selectedStepId`, bordure de focus sur la barre selectionnee, synchronisation existante curseur/preview/inspecteur, protection des champs texte hors timeline, Visual Gate V1-57.

Limites : pas de navigation verticale par piste, playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, persistance temporelle, JSON ou build_runner.

Preuve : tests clavier locaux, suite Builder `+39`, suite Library `+10`, tests core time layout/lane, analyses ciblees, capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png`, evidence pack V1-57.

Prochain lot exact : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`.

## Mise a jour V1-58

Statut : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract` est DONE.

Decision : V1-58 reste documentaire. La future navigation ArrowUp/ArrowDown utilisera Option B : prochaine lane non vide au-dessus ou en dessous, puis bloc cible choisi par proximite de centre temporel. La navigation horizontale V1-57 reste lineaire par `stepIndex`; Home/End restent globaux.

Regles : temps de reference `centerMs = startMs + visualDurationMs / 2`; lanes vides non navigables en V0 ; bords sans lane non vide = selection conservee ; sans selection, ArrowUp va au dernier bloc de la derniere lane non vide et ArrowDown au premier bloc de la premiere lane non vide ; tie-break distance, puis plus petit `stepIndex`, puis ordre stable.

Tests futurs requis : selection depuis Camera vers acteur/dialogue selon lane non vide, remontee vers lane precedente, skip lanes vides, bords stables, tie-breaks, cursor/inspector/preview synchronises, non-mutation, hover ignore, TextField proteges, V1-57/V1-56 preserves.

Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.

Preuve : rapport V1-58 complet avec Gate 0, audit passes A-H, Design Gate, options comparees, Evidence Pack et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.

## Mise a jour V1-59

Statut : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0` est DONE.

Decision : V1-59 ajoute ArrowUp/ArrowDown au meme `FocusNode` local que V1-57. Le mapping vertical ne change pas ArrowLeft/ArrowRight/Home/End : il ajoute seulement `up` et `down`, resolus par `timeLayout.lanes` et les blocks derives.

Scope realise : prochaine lane non vide au-dessus/dessous, calcul `centerMs`, choix par distance puis `stepIndex`, fallback sans selection, timeline vide sans crash, bords stables, protection TextFields, synchronisation du curseur, de la preview sandbox et de l'inspecteur, badge clavier mis a jour, capture Visual Gate V1-59.

Limites : pas de playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, persistence temporelle, JSON, build_runner, runtime/gameplay/battle/examples ou mutation `ProjectManifest`.

Preuve : suite Builder `+44`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png`, rapport et Evidence Pack V1-59.

Prochain lot exact : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`.

## Mise a jour V1-60

Statut : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0` est DONE.

Decision : V1-60 remplace le badge long `Navigation clavier : ← → ↑ ↓ Home End` par le controle compact `Aide clavier`. Le clic ouvre/ferme un panneau local a la timeline qui explique `← / →`, `↑ / ↓`, `Home` et `End`, avec la mention explicite `Sélection uniquement — pas de lecture ni déplacement temporel.`

Scope realise : etat local `_timelineKeyboardHelpOpen`, badge compact interactif design-system, panneau overlay non intrusif, tests de non-mutation `ProjectManifest`, selection/curseur/inspecteur preserves, navigation V1-57/V1-59 preservee, TextFields proteges, transport controls toujours disabled et capture Visual Gate V1-60.

Limites : pas de playback, timer, seek, scrubber, mouse playhead, drag/drop, resize, reorder, zoom temporel, preview runtime, persistence temporelle, JSON, build_runner, runtime/gameplay/battle/examples ou mutation `ProjectManifest`.

Preuve : RED cible du help clavier, suite Builder `+46`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png`, rapport et Evidence Pack V1-60.

Prochain lot exact : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`.

## Mise a jour V1-61

Statut : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract` est DONE.

Decision : V1-61 retient l'Option B : un futur `Mouse Time Probe` local, visuel et editor-only, separe de `selectedStepId`. Il peut etre place par clic ou drag sur l'axe/fond temporel, jamais par drag sur une barre, et ne demarre aucun playback.

Contrat futur : click sur axe/fond positionne le probe ; drag axe/fond le fait suivre la souris ; release fige la position locale ; cancel revient a la derniere position stable ; clic sur barre continue de selectionner le bloc ; drag sur barre reste interdit en V1-62 ; conversion souris -> temps via origine X commune, scroll horizontal, `pixelsPerMs`, clamp `0..totalDurationMs`, snap V0 aux debuts/fins de blocs seulement si proche.

Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucune image IA, aucun scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnees Selbrume.

Preuve : rapport V1-61 avec passes A-I, Design Gate 28 points, options comparees, tests futurs et checks anti-scope. `git diff --check` propre et `git diff --name-only -- packages` vide.

Prochain lot exact : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.

## Mise a jour V1-62

Statut : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0` est DONE.

Decision : V1-62 implemente le contrat V1-61 sous forme d'un `timelineProbeTimeMs` local au Cinematic Builder. Le probe peut etre place par clic ou drag sur l'axe/fond temporel, utilise la meme origine X que les ticks, barres et curseur V1-56, prend en compte le scroll horizontal et clamp le temps entre `0` et `totalDurationMs`.

Scope realise : badge `Repere : <temps>`, ligne verticale unique du probe quand il existe, fallback vers `Selection : <temps>` quand le probe est absent, preview sandbox informative `Repere temporel : <temps>`, clear du probe sur clic de barre et navigation clavier, tests de non-mutation `ProjectManifest`, clamp, scroll horizontal, non-drag de bloc et Visual Gate V1-62.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag de blocs, resize, reorder, persistence temporelle, changement core/model JSON, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : test RED puis GREEN cible, suite Builder `+52`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, checks anti-scope, `git diff --check` et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png`.

Prochain lot exact : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.

## Mise a jour V1-63

Statut : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0` est DONE.

Decision : V1-63 reste documentaire. L'option V0 retenue pour le futur est l'Option E : snap leger aux bords `0 ms` / `totalDurationMs` et aux `block.startMs` / `block.endMs`, jamais aux ticks arbitraires. Le seuil recommande est `8 px`, converti en temps via `pixelsPerMs`, pour conserver une sensation stable a l'ecran.

Contrat futur V1-64 : click snap immediat si proche d'une cible ; drag snap pendant le drag si proche, avec indication subtile ; release conserve la derniere position libre ou alignee. Le snap ne modifie jamais `selectedStepId`, l'inspecteur, les barres, `visualDurationMs`, `CinematicTimeline.steps` ou `ProjectManifest`.

Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun snap actif, aucun playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, runtime, mutation JSON, build_runner, image IA ou donnees Selbrume.

Preuve : rapport V1-63 avec passes A-I, Design Gate 31 points, options A-E comparees, edge cases bords/scroll/fallback/blocs proches, tests futurs V1-64 et checks anti-scope documentaires.

Prochain lot exact : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.

## Mise a jour V1-64

Statut : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0` est DONE.

Decision : V1-64 implemente l'Option E cadree en V1-63. Le repere souris reste local au Cinematic Builder, mais se magnetise maintenant aux bords de timeline `0 ms` / `totalDurationMs` et aux `block.startMs` / `block.endMs` quand la souris est a `8 px` ou moins. Les ticks arbitraires restent exclus.

Scope realise : badge libre `Repere : <temps>` et badge snappe `Repere : <temps> · <hint>`, snap au click, au drag et a la release, prise en compte du scroll horizontal, priorites stables aux bords et debuts/fins de blocs, tests de non-mutation `ProjectManifest`, selection et inspecteur preserves, capture Visual Gate V1-64.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag de blocs, resize, reorder, persistance temporelle, changement core/model JSON, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : test RED puis GREEN cible, suite Builder `+58`, Visual Gate `+59`, suite Library `+10`, tests core time layout/lane, analyse core, analyse cible editor, checks anti-scope, `git diff --check` et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png`.

Prochain lot exact : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`.

## Mise a jour V1-65

Statut : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0` est DONE.

Decision : le repere souris dispose maintenant d'un clear local explicite `Effacer le repère`, affiche seulement quand `timelineProbeTimeMs` est actif. Le controle reste dans l'en-tete de timeline pour etre visible et separe des placeholders Reset/Play/Stop.

Scope realise : clear de `timelineProbeTimeMs` et `timelineProbeSnapHint`, micro-explication compacte `Repère local : inspection uniquement.`, preservation de `selectedStepId`, retour au curseur/badge `Selection` si un bloc est selectionne, aucun marqueur si aucune selection n'existe, Escape borne au focus timeline, TextFields proteges, snap/drag/hover/aide/transports preserves.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag de blocs, resize, reorder, persistance temporelle, changement core/model JSON, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : test RED puis GREEN cible, suite Builder/Visual Gate `+65`, suite Library `+10`, tests core time layout/lane `+6`, analyse core, analyse cible editor, checks anti-scope, `git diff --check` et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png`. `flutter analyze` global `map_editor` reste rouge sur des erreurs preexistantes hors lot dans les services Pokemon SDK.

Lot suivant realise ensuite : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`.

## Mise a jour V1-69

Statut : `NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0` est DONE.

Decision : V1-69 implemente le resize de duree uniquement depuis le bord droit des barres editables authoring-owned. Le geste modifie seulement `durationMs`, reutilise les operations authoring et bornes V1-68, quantifie au pas de 100 ms, preserve `selectedStepId`, clear le probe local et laisse `startMs` / `endMs` derives par le read model.

Scope realise : handle visible uniquement sur le bloc selectionne et editable ; blocs supportes `wait`, `fade`, `camera`, `actorFace`, `actorMove` ; non-owned, marker draft et legacy bridge sans handle ; drag droit augmente/diminue la duree ; clamp min 100 ms ou 200 ms pour `actorMove`, max 30000 ms ; blocs suivants recalcules via layout derive ; inspecteur duree mis a jour ; hover, aide, keyboard navigation et transports disabled preserves.

Limites : pas de drag du bloc entier, pas de bord gauche draggable, pas de changement de lane, pas de reorder, pas de playback, pas de seek runtime, pas de scrubber runtime, pas de preview runtime, pas de timer, pas de timeline libre, pas de persistance `startMs` / `endMs`, pas de modification `map_core`, `map_runtime`, `map_gameplay`, `map_battle`, examples, build_runner, image IA ou donnees Selbrume.

Preuve : RED puis GREEN sur `resizes selected cinematic block duration from right handle`, suite Builder `+82`, suite Library `+10`, Visual Gate `+82`, tests core authoring/time layout/lane `+34/+4/+2`, `dart analyze` core, analyse cible editor verte, `flutter analyze` global editor encore rouge uniquement sur dette preexistante Pokemon SDK, checks anti-scope et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.png`.

Prochain lot exact : `NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0`.

## Mise a jour V1-70

Statut : `NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0` est DONE.

Decision : V1-70 ajoute les panneaux de signalisation autour des durees cinematic. Les bornes, le pas de 100 ms, les refus de saisie, les clamps de resize et les raisons de non-editabilite sont visibles localement dans le Builder, sans changer le contrat V1-68/V1-69.

Scope realise : wording `Bornes : 100-30000 ms · pas 100 ms` pour wait/fade/camera/actorFace, `Bornes : 200-30000 ms · pas 100 ms` pour actorMove, messages inline `Saisis une durée en millisecondes.`, `Utilise un nombre entier de millisecondes.`, `Minimum pour ce bloc : X ms.`, `Maximum : 30000 ms.`, feedback `Minimum atteint : X ms` / `Maximum atteint : 30000 ms`, explications marker draft et lecture seule, diagnostics core pour durees persistentes invalides.

Preuve : RED puis GREEN sur le test editor recommande et sur le test core `diagnoses wait duration below minimum`, suite Builder `+93`, suite Library `+10`, tests core diagnostics/authoring/time layout/lane, `dart analyze` core, analyse cible editor verte, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png` et checks anti-scope. `flutter analyze` global `map_editor` reste rouge par dette preexistante Pokemon SDK hors lot.

Limites : pas de nouveau modele temporel, pas de changement de bornes/pas, pas de resize supplementaire, pas de drag de bloc, pas de bord gauche draggable, pas de lane/reorder, pas de playback/timer/transport fonctionnel, pas de seek/scrubber runtime, pas de persistance `startMs/endMs`, pas de runtime/gameplay/battle/examples, pas d'image IA, pas de Selbrume code.

Prochain lot exact recommande : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.

## Mise a jour V1-71

Statut : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract` est DONE.

Decision : V1-71 est documentaire et retient une option hybride : `CinematicAsset` porte le contexte stage par defaut pour rendre la Library/Builder/previews futures comprehensibles, tandis que les overrides Scene/Event restent un futur explicite. L'audit note que `CinematicAsset.mapId` existe deja, mais reste insuffisant seul pour une preview reelle.

Contrat retenu : map cible optionnelle, `backdropMode` `none | projectMap`, actor bindings V0 `player | mapEntity | cinematicOnly | unbound`, initial placements par source nommee, movement target bindings map-aware optionnels et diagnostics previews/readiness sans bloquer les drafts abstraits.

Preuve : rapport V1-71, Gate 0 propre, audit `CinematicAsset` / `requiredActors` / `movementTargets`, audit `MapData.entities`, `MapData.events`, `MapEntity.pos`, `MapEventDefinition.position`, `MapEntitySpawnData`, checks anti-scope et `git diff --check`.

Limites : aucun code produit, package, test, modele JSON, map picker, actor binding code, preview reelle, runtime, pathfinding, screenshot, build_runner, image IA ou donnees Selbrume.

Correction roadmap : `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0` est deplace en backlog `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0`. Le prochain lot exact devient `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.

## Mise a jour V1-72

Statut : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0` est DONE.

Decision : le Stage Context est maintenant un modele core authoring optionnel dans `CinematicAsset.stageContext`. `CinematicAsset.mapId` reste l'unique ancre Stage Map ; aucun `stageContext.mapId` n'existe. Les cinematics abstraites sans `stageContext` restent autorisees comme drafts.

Scope realise : modeles/JSON, operations pures, diagnostics stage/readiness, tests RED puis GREEN, manifest round-trip et non-regression Builder/Library. La timeline reste lineaire et sandboxee.

Limites : aucune UI Stage Context, aucune preview reelle, aucun runtime cinematic map-aware, aucun pathfinding, aucune coordonnee libre par defaut, aucune donnee Selbrume codee.

Preuve : rapport V1-72, evidence pack V1-72, `map_core` tests complets `+2354`, `map_core` analyze vert, tests editor Library `+10` et Builder `+93`. `map_editor flutter analyze` global reste rouge sur dette Pokemon SDK hors lot.

Prochain lot exact recommande : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0`.

## Mise a jour V1-73

Statut : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0` est DONE.

Decision : le Stage Context V1-72 est authorable depuis le Builder et resume dans la Library. `CinematicAsset.mapId` reste l'ancre Stage Map unique ; `stageContext` ne porte pas de `mapId`. Les options map-aware qui dependent de `MapData.entities/events` sont visibles mais desactivees avec messages explicites, car la source map chargee n'est pas encore disponible dans ce Builder.

Scope realise : picker map `ProjectManifest.maps`, clear map, backdrop `none/projectMap`, actor bindings `player/mapEntity/cinematicOnly/unbound`, placements initiaux `unset/fromMapEntity/fromMovementTarget`, movement target bindings `abstractPoint/mapEntity/mapEvent`, diagnostics stage, summary Library map/diagnostics, integration `NarrativeWorkspaceCanvas`.

Limites : aucune preview reelle, aucun playback/runtime, aucun pathfinding/collision/warp, aucune coordonnee libre, aucun raw JSON/ID libre, aucune donnee Selbrume codee.

Preuve : rapport V1-73, evidence pack V1-73, screenshot V1-73 `1663 x 926` SHA-256 `79621972c1c50ef26ac1f5603b1587a6a2752087bd802d43173488154a3454ed`, Builder `+119`, Library `+11`, `map_core` cibles verts, analyse cible editor verte. `map_editor flutter analyze` global reste rouge sur dette Pokemon SDK hors lot.

Prochain lot exact recommande : `NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0`.

## Selbrume golden slice

Avant le golden slice, il faut au minimum :

- Node Authoring V0.
- Edge Authoring V0.
- Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
- Linked Asset Contracts V0 avant Payload Pickers, pour eviter que les pickers ne soient de simples selecteurs d'IDs bruts.
- Payload Pickers V0 pour Yarn, battle, cinematic/action.
- Scene Node Payload Editing V0 pour corriger les refs Dialogue/Battle deja placees sans supprimer/recreer les nodes.
- Event to Scene Trigger Prep pour decider le contrat Event local -> Scene V1 sans StorylineStep comme declencheur.
- Event to Scene Link V0 pour authorer et valider ce lien avant toute execution.
- Scene Runtime Plan V0 pour compiler une Scene valide en intents sans layout.
- Diagnostics Expansion.
- Dialogue/Battle Ports Authoring V0 pour rendre les nodes metier branchables avant execution.
- World Rules V0 pour les consequences visibles controlees.
- Narrative Studio Direction Checkpoint pour choisir l'ordre runtime / map events / payloads / validator.
- Scene Runtime Executor MVP.
- World Rules Map Editor Integration V0 pour relire les consequences depuis les cibles map/entity.

Peut attendre apres le slice :

- Dialogue outcomes avances.
- BranchByOutcome authoring/runtime.
- World Rule editor avance au-dela des effets V0.
- Fact registry avance.
- Cinematic editor avance si une cinematic fixture controlee suffit.

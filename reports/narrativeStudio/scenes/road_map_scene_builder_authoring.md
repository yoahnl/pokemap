# NS-SCENES-V1 — Roadmap Scene Builder Authoring

## Verdict

Roadmap recommandee : **Option C hybride**, avec priorite immediate au Scene Builder Blueprint-like.

Le runtime reste indispensable, mais le prochain blocage produit est plus basique : une personne peut creer une scene draft, mais ne peut pas encore construire visuellement une scene. La suite doit donc poser l'authoring graph avant de brancher Storylines ou d'executer en jeu.

## Prochain lot exact recommande

```text
NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit
```

Suite V1-135 : la sequence camera V1 est fermee. Le prochain verrou produit est une fermeture globale du Cinematic Builder V1 : readiness, limites assumees, backlog V2 et trajectoire Narrative Studio, sans nouveau chantier fonctionnel.

## Principes

- Scene Builder doit devenir un outil Blueprint-like : palette, nodes, ports, edges, payloads, diagnostics.
- Aucun node actif ne doit cacher une fake ref.
- Yarn, battle et cinematic ne deviennent ajoutables que si leur payload draft est honnete ou si un picker existe.
- Runtime ignore toujours `SceneGraphLayout`.
- `ScenarioAsset` reste legacy/bridge, pas modele produit final.
- `Event -> Scene` passe avant `StorylineStep -> Scene` pour le golden slice Selbrume.
- Une Condition no-code doit lire une source metier explicite ; pas de condition textuelle magique ni de flag technique expose comme experience principale.
- Les Facts et World Rules doivent etre cadres avant le golden slice, meme si le premier authoring Condition peut rester limite aux sources existantes.
- Les dimensions d'acteurs doivent venir de `frameWidth` et `frameHeight` de la fiche personnage.

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
| NS-SCENES-V1-87 | Cinematic Map Backdrop Real Tile Rendering Prep Contract | doc-only / architecture-review | Cadrer le rendu reel des tiles/assets dans la preview cinematic avant tout code : audit MapData/layers, tilesets, asset resolution, rendu Map Editor et anti-scope runtime. | Pas de code produit, package, widget, test, screenshot, renderer, vraie map affichee, runtime/Flame, playback, acteurs rendus, fake tiles ou donnee Selbrume. | Rapport V1-87, Evidence Pack, roadmaps. | DONE : sub-agents A-E, Option E retenue, contrat futur renderer V1-88, asset registry editor-only recommande, layer ordering/fallbacks/tests futurs cadres. | Brancher MapCanvas complet ; charger les images dans build/paint ; utiliser le runtime ; poser des acteurs sur un decor abstrait. | DONE : contrat pret pour V1-88, sans modifier les packages. | V1-86. |
| NS-SCENES-V1-88 | Cinematic Map Backdrop Real Tile Renderer V0 | editor / preview-sandbox | Afficher les vraies tiles/assets de la map dans le Cinematic Builder via un renderer read-only editor-only, avec images resolues en amont et diagnostics visibles. | Pas de runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, renderer cinematic, asset registry/cache editor-only, tests widget, rapport, Visual Gate. | DONE : rendu `TileLayer` visible via instructions bitmap, registre asset editor-only, fallback structurel diagnostique, proportions V1-86 preservees, tests/Visual Gate. | Divergence visuelle avec Map Editor ; cache image perime ; fallback silencieux ; timeline reduite. | DONE : vraie map statique affichable sans lancer la cinematique. | V1-87. |
| NS-SCENES-V1-89 | Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | editor / preview-sandbox | Brancher le renderer bitmap V1-88 au vrai workspace editor : resolver tileset parent, chargement async borne, fallback diagnostique et fidelity TileLayer durcie. | Pas d'acteurs rendus, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume hardcodee ou mutation runtime/map/projet. | Library/Builder cinematics, `narrative_workspace_canvas.dart`, loader asset, tests widget/plan, rapports, screenshot. | DONE : success/fallback/collecteur/fidelite, Visual Gate 1663x926, anti-scope runtime/Flame. | Fallback silencieux ; stale cache ; charger des images dans build/paint ; reduire la timeline. | DONE : vraies tiles resolues depuis le parent editor et affichees dans le Builder. | V1-88. |
| NS-SCENES-V1-90 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs une fois le vrai decor map rendu : sources actor bindings/placements/Character Library, positions, apparences, overlay/viewport et diagnostics. | Pas de code produit, package, test, screenshot, rendu acteur actif, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume ou mutation runtime/map/projet. | Rapport V1-90, Evidence Pack, roadmaps. | DONE : sub-agents A-F, Option C retenue, contrat actor display read model, positions, apparences, overlay, diagnostics/tests/Visual Gate V1-91, anti-scope runtime. | Confondre acteur statique et gameplay ; cacher les gaps Character Library ; casser le decor V1-89 ; coder un renderer trop tot. | DONE : contrat pret pour read model Actor Display statique futur, sans rendre d'acteur. | V1-89. |
| NS-SCENES-V1-91 | Cinematic Actor Display Preview Read Model V0 | core / read-model | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary. | Pas de renderer UI, sprite actor affiche, playback, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou screenshot. | `map_core` read model actor display, tests purs, rapport. | DONE : `CinematicActorDisplayPreviewModel`, builder pur depuis `CinematicAsset`/manifest/stage map/MapData, diagnostics locaux, positions/apparences/directions/render hints et tests/analyze core verts. | Melanger read model et painter ; inventer des positions ; utiliser le runtime pour simplifier. | DONE : actor display projetable et testable, sans rendu. | V1-90. |
| NS-SCENES-V1-92 | Cinematic Actor Display Preview Renderer V0 | editor / preview-sandbox | Brancher le read model V1-91 dans le Cinematic Builder pour afficher des acteurs statiques sous forme de placeholders par-dessus le decor V1-89. | Pas de playback, actorMove interpolation, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest, sprite final ou lancement de cinematique. | Builder cinematics, overlay actor display, transform viewport partage, tests widget, rapport, screenshot. | DONE : `CinematicActorDisplayPreviewModel` construit par la Library et passe au Builder ; placeholders statiques renderables seulement, unbound/missing hors map, labels courts, direction hints, diagnostics humains, Visual Gate 1663x926 et analyses/tests verts. | Confondre projection statique et playback ; charger les sprites dans core ; casser les proportions preview/timeline. | DONE : acteurs visibles en preview editor-only, sans runtime. | V1-91. |
| NS-SCENES-V1-93 | Cinematic Map Backdrop Layer Fidelity Prep Contract | doc-only / architecture-review | A la demande de Karim, suspendre le Sprite Resolver et cadrer la fidelite map restante : audit layers MapData, rendu Map Editor, assets/catalogues, plan multi-layer, diagnostics, tests et Visual Gate V1-94. | Pas de code produit, packages, test, screenshot, renderer, MapCanvas complet, runtime/Flame, playback, fake terrain/path/environment, mutation Selbrume ou image IA. | Rapport V1-93, evidence pack, roadmaps. | DONE : sub-agents A-G, Option E retenue, contrat renderer V1-94, assets/catalogues et anti-scope documentes. | Sous-estimer les placed elements/paths ; lancer les sprites acteurs trop tot ; importer MapCanvas ou runtime pour gagner du temps. | DONE : contrat pret pour fidelity backdrop V1-94, sans modifier les packages. | V1-92. |
| NS-SCENES-V1-94 | Cinematic Map Backdrop Layer Fidelity Renderer V0 | editor / preview-sandbox | Etendre le renderer backdrop cinematic pour rendre terrain, paths, surfaces, placed elements et generated placements quand assets/donnees sont disponibles, avec plan multi-layer editor-only/read-only. | Pas de MapCanvas complet, runtime/Flame, playback, mutation projet/map, hardcode Selbrume, sprites acteurs finaux, pathfinding/collision ou outils d'edition. | Builder/Library cinematics, plan backdrop multi-layer, resolver asset catalog, tests widget/plan, rapport, Visual Gate. | DONE : plan multi-layer, terrain/path/surface/TileLayer background/foreground/placed elements/generated placements, partial render, diagnostics par famille, Visual Gate neutre, anti-scope et anti-Selbrume diff. | Ordre de couches faux ; fallback silencieux ; charger images dans paint/build ; casser l'overlay acteurs V1-92 ou les proportions timeline. | DONE : decor projet statique beaucoup plus proche du Map Editor, acteurs V1-92 preserves, sans runtime. | V1-93. |
| NS-SCENES-V1-94 bis | Cinematic Path Studio Water Fidelity Fix | editor / preview-sandbox fix | Corriger le rendu backdrop cinematic quand un `PathLayer` reference un preset de base Path Studio : retrouver l'unique pattern lie par `basePathPresetId` pour rendre l'eau/motif Path Studio comme le Map Editor. | Pas de runtime/Flame, playback, MapCanvas complet, sprites acteurs, Selbrume, image IA, refonte timeline ou changement gameplay. | Plan backdrop cinematic, test Builder ciblé, rapport, evidence pack, roadmaps. | DONE : `_resolvePathPreset` aligne la resolution base preset -> pattern unique, fallback base en cas d'ambiguite, test eau Path Studio vert et suite Builder complete verte. | Oublier que `PathLayer.presetId` pointe souvent vers le base preset ; choisir arbitrairement parmi plusieurs patterns ; casser le fallback base. | DONE : eau Path Studio restauree dans le backdrop cinematic sans elargir le scope V1-94. | V1-94. |
| NS-SCENES-V1-95 | Cinematic Backdrop Preview Framing / Zoom Controls V0 | editor / preview-sandbox | Rendre la preview backdrop lisible comme une scene cadree : Carte entiere, Vue scene, zoom local, focus acteur/bbox/centre map, transform partage et eau Path Studio visible. | Pas de runtime/Flame, playback, CameraComponent, GameState, actorMove interpolation, MapCanvas complet, MapGridPainter brut, sprites acteurs finaux, persistence zoom/framing, mutation projet/map ou donnees Selbrume. | Helper framing editor-only, Builder preview panel, render pass backdrop, test Builder, Visual Gate, rapports, roadmaps. | DONE : controles framing/zoom locaux, scene plus lisible que fit map, non-mutation, focus/fallback, acteurs placeholders alignes, Path Studio/eau visible, timeline/transports preserves, screenshot V1-95. | Zoom trop violent ; overlay acteur decale ; eau Path Studio cachee par tile background ; controls qui mangent la timeline ; confondre cadrage editor et camera runtime. | DONE : preview cadree, eau visible, acteurs V1-92 alignes, aucun runtime/playback. | V1-94 bis. |
| NS-SCENES-V1-95 bis | Cinematic Backdrop Preview Canvas UX Polish V0 | editor / preview-sandbox-ux | Polir la preview backdrop apres V1-95 : canvas plus dominant, chrome secondaire replie, pan local borne, reset/recentrage, grille masquee par defaut avec toggle local, timeline/inspector/transports conserves. | Pas de runtime/Flame, playback, CameraComponent, GameState, actorMove interpolation, MapCanvas complet, MapGridPainter brut, sprites acteurs finaux, persistence pan/zoom/grille/details, mutation projet/map ou donnees Selbrume. | Framing state local et clamp, Builder preview panel compact, renderers avec grille separable, tests Builder, Visual Gate, rapports, roadmaps. | DONE : canvas-first en Vue scene, details repliables, pan drag local + clamp + reset, grille locale, acteurs placeholders alignes, Path Studio/eau preserve, suites Builder/Library vertes. | Trop reduire la timeline ; masquer les controles utiles ; desaligner acteurs/backdrop ; rendre le pan persistant ; reintroduire un rendu runtime. | DONE : UX canvas polish editor-only, sans mutation ni runtime/playback. | V1-95. |
| NS-SCENES-V1-96 | Cinematic Backdrop Depth / Z-Order Parity Polish V0 | editor / preview-sandbox-depth | Correctif Y-sorting/depth sorting deterministe pour le decor backdrop et l'overlay des acteurs placeholders : tri par visual bottom Y, layerIndex comme tie-breaker, elementX et zOrder d'origine. Heuristiques foreground completes. Tri Y-sorting des acteurs statiques. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Plan backdrop plans, tests widget/plan, rapport V1-96, evidence pack, screenshots, roadmaps. | DONE : tri Y-sorting deterministe fonctionnel, heuristiques foreground verifiees. | Mauvais tri Y-sorting ; desalignement ; regression foreground/background passes ; collision non coupee. | DONE : decor et acteurs triés deterministiquement par Y, sans runtime. | V1-95 bis. |
| NS-SCENES-V1-96-bis | Cinematic Backdrop Real Map Editor Ordering Investigation / Fix V0 | editor / preview-sandbox-ordering | Enquête et alignement de la preview de décor sur l'ordre exact du Map Editor (Terrain -> Path -> TileBackground -> Surface -> PlacedBackground -> Foreground, boucle de calques inversée length - 1 down to 0). Tri intra-calque/intra-passe uniquement en tie-breaker. Rendu multi-tuiles split par cellule. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Plan backdrop, tests ciblés, rapport V1-96-bis, evidence pack, screenshots/Visual Gate, roadmaps. | DONE : ordre de rendu conforme à MapGridPainter, pontons sur l'eau, calques inversés corrects, multi-tuiles split. | Prioriser le y-sort global au lieu de la hiérarchie de calques ; inverser path/tileBackground. | DONE : décor et acteurs triés par calques conformes à l'éditeur, sans runtime. | V1-96. |
| NS-SCENES-V1-97 | Cinematic Actor Display Preview Sprite Resolver Prep Contract | doc-only / architecture-review | Cadrer le futur resolver de sprites statiques apres preview backdrop lisible et triee V1-96 : sources Character Library/player/mapEntity, frames idle, fallback, diagnostics, cache et anti-scope runtime. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Rapport V1-97, evidence pack, roadmaps. | DONE : contrat sprite resolver editor-only, diagnostic et tests futures. | Charger trop tot des sprites dans core ; confondre sprite statique et animation runtime ; masquer les placeholders incomplets. | DONE : contrat pret pour afficher des acteurs reconnaissables sans lancer la cinematique. | V1-96-bis. |
| NS-SCENES-V1-98 | Cinematic Actor Display Preview Sprite Resolver V0 | editor / pure-resolver | Implémenter le resolver purement logique et ses tests unitaires de parité associés sans rendu visuel. | Pas de renderer sprite actif, playback, runtime/Flame, actorMove interpolation, pathfinding/collision, mutation Character Library, generation image IA ou donnees Selbrume. | Resolver, tests unitaires, rapports, roadmaps. | DONE : resolver et 9 tests unitaires. | Coupler le resolver à la couche UI ; importer map_runtime ; casser les fallbacks de placeholders. | DONE : resolver logique capable d'associer un acteur à ses coordonnées d'atlas et son tileset. | V1-97. |
| NS-SCENES-V1-99 | Cinematic Actor Display Preview Sprite Renderer V0 | editor / preview-sandbox | Intégrer les sprites acteurs résolus par V1-98 au rendu de la preview du Cinematic Builder avec fallbacks et gestion de profondeur. | Pas de lecture de fichier synchrone dans le paint, interpolation de mouvement runtime, playback interactif ou données Selbrume. | Preview rendering canvas, actor rendering pass, fallback visuals, rapports, Visual Gate. | DONE : rendu des sprites résolus. | Casser le z-order / Y-sort des calques ; charger l'image pendant le paint ; ignorer les diagnostics de fallback. | DONE : sprites résolus dessinés à leur place respective avec la bonne hauteur et le fallback placeholder respecté. | V1-98. |
| NS-SCENES-V1-99-bis | Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0 | editor / preview-sandbox-polish | Prouver la fidélité visuelle du rendu avec un vrai sprite de personnage (Timi) et des tests robustes de non-platitude et hors-limites. | Pas de runtime, pas de Flame, pas de playback, pas de modification de code produit dans map_core/map_runtime. | Test non-platitude, test out of bounds color injection, test diagnostic warnings, golden file screenshot updated. | DONE : rendu des sprites avec assets réels. | Ne pas utiliser constructeur avec injection de couleur ; hardcoder les couleurs literals ou la palette Selbrume dans lib/ ; ignorer la dimension 32x32/64x64px. | DONE : Timi visible, tests non-platitude et hors-limites verts, injection correcte de la couleur d'erreur via constructeurs. | V1-99. |

## Mise a jour V1-94

Statut : `NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0` est DONE.

Demande : Karim a demande de rendre la preview cinematic plus proche du Map Editor avant de passer aux sprites acteurs.

Decision : `CinematicMapBackdropLayerRenderPlan` devient le plan etendu, sans remplacer brutalement `CinematicMapBackdropTileRenderPlan`. La Library charge ce plan via un loader editor-only et le Builder le compose avec l'Actor Display V1-92 au milieu des passes.

| NS-SCENES-V1-100 | Cinematic Spatial Authoring / Stage Points Prep Contract V0 | doc-only / planning | Cadrer l'édition spatiale des cinématiques, le modèle de stockage local décorrélé, les transformations géométriques écran-carte, les interactions (Option C), liens timeline (initialPlacements/targets) et diagnostics. | Lot documentaire de cadrage théorique uniquement. Aucun code produit, modèle core, UI ou test créé. | Rapport V1-100, Evidence Pack, roadmaps. | DONE : `git diff --check`. | Coder trop tôt ; lier prématurément au runtime. | DONE : Rapport de contrat V1-100 rédigé, diagnostics et tests prévus. | V1-99-bis. |
| NS-SCENES-V1-101 | Cinematic Stage Point Core Model V0 | core / model | Implémenter le modèle core des points de scène, la désérialisation JSON rétrocompatible, les opérations pures d'édition et le moteur de diagnostic avec 6 codes de validation. | Pas de Flame, pas d'UI, pas de modification hors de `map_core`. | `map_core`, `cinematic_stage_point.dart`. | DONE : `dart test` et `dart analyze` propres. | Alourdir le modèle avant l'UI. | DONE : Modèle stable, diagnostics prêts pour l'UI, compatibilité ascendante respectée. | V1-100. |
| NS-SCENES-V1-102 | Cinematic Preview Point Placement UI V0 | editor / ui | Visualiser, créer, sélectionner, déplacer par drag-and-drop, renommer et supprimer des Stage Points cinématiques dans la preview. | Pas de liaison placement acteur/target mouvement, pas de playback interactif. | `CinematicStagePointPreviewOverlay`. | DONE : Visual gate propre, tests widgets verts. | Gestion complexe des coordonnées écran/carte. | DONE : UI de placement fonctionnelle et alignée sur le design system. | V1-101. |
| NS-SCENES-V1-102-bis | Stage Point Placement UX Discoverability | editor / ux | Améliorer la découverte : bouton texte, bannières d'aide, empty states, touche Échap, puce de liste dans l'inspecteur. | Pas de playback ou liaisons logiques. | `CinematicBuilderWorkspace`. | DONE : 100% tests verts, Visual Gate mise à jour. | UX trop verbeuse. | DONE : Placement rendu intuitif pour l'auteur. | V1-102. |
| NS-SCENES-V1-102-ter | Stage Point Placement Evidence Pack Final Closure | review / doc | Clôture documentaire et Evidence Pack pour V1-102. | Aucun code produit modifié. | Rapport final. | DONE : `git diff --check`. | -- | DONE : Documentation et preuves complètes. | V1-102-bis. |
| NS-SCENES-V1-103 | Cinematic Actor Initial Placement from Stage Points V0 | core / editor | Utiliser un Stage Point comme position initiale pour acteur cinématique. Picker no-code, résolution dynamique des coordonnées. | Pas de playback, pas de liaison target mouvement. | `CinematicActorInitialPlacementKind.stagePoint`. | DONE : Tests verts, Visual Gate avec sprite de Timi sur point de scène. | Découplage de la géométrie fixe. | DONE : placement dynamique et diagnostiqué. | V1-102-ter. |
| NS-SCENES-V1-103-bis | Actor Initial Placement Stage Point Evidence Closure | review / doc | Clôture documentaire du pack de preuves de V1-103. | Aucun code produit modifié. | Rapport final. | DONE : `git diff --check`. | -- | DONE : Evidence Pack validé. | V1-103. |
| NS-SCENES-V1-104 | Cinematic ActorMove Target from Stage Points V0 | core / editor | Utiliser un Stage Point comme cible de déplacement pour `actorMove`. Transition propre entre types de cibles. | Pas d'interpolation interactive, pas de tracé graphique. | `CinematicMovementTargetBindingKind`. | DONE : Tests 100% verts, diagnostic target. | Gestion des valeurs zombies. | DONE : target authorable par point de scène, validé. | V1-103-bis. |
| NS-SCENES-V1-104-bis | ActorMove Stage Point Target Evidence / Quality Gate Closure | review / doc | Clôture documentaire et Evidence Pack pour V1-104. | Aucun code produit modifié. | Rapport final, Evidence Pack. | DONE : `git diff --check`. | -- | DONE : Evidence Pack validé. | V1-104. |
| NS-SCENES-V1-105 | Cinematic Builder UX Simplification / Destination Vocabulary V0 | editor / ux | Simplifier le vocabulaire visible du Cinematic Builder et de la Library : `Repère`, `Destination`, `Destination du déplacement`, `Position libre`, `Personnage ou objet de la map`, `Déclencheur de map`, `Marqueur temps`, `Aucun problème`. | Pas de modèle core, pas de runtime, pas de playback, pas de Manual Path authoring. | Builder/Library cinematics, tests widget, rapport, Evidence Pack, Visual Gate. | DONE : tests Builder/Library/overlay verts, analyse ciblée en sortie 0, Visual Gate 1663x926. | Laisser survivre des libellés techniques visibles ; renommer des identifiants internes par erreur. | DONE : vocabulaire no-code aligné, anciens libellés visibles absents, identifiants internes préservés. | V1-104-bis. |
| NS-SCENES-V1-106 | Cinematic Manual Path Authoring Prep Contract | doc-only / architecture-review | Cadrer le futur modèle et l’UX des trajets manuels cinématiques composés de points de passage, en continuité avec Repères, Destination et actorMove, sans code produit ni runtime. | Pas de modèle core, pas d'opération Dart, pas d'UI, pas de runtime, pas de Visual Gate. | Rapport V1-106, Evidence Pack, roadmaps. | DONE : `git diff --check`. | Sur-designer la réutilisation de chemins ; confondre Destination finale et points de passage ; rouvrir playback. | DONE : Option C+D retenue, V1-107 cadré, anti-scope confirmé. | V1-105. |
| NS-SCENES-V1-107 | Cinematic Manual Path Core Model V0 | core / model | Ajouter le modèle core authoring-only des chemins manuels cinématiques, stocké dans Stage Context, composé de Repères ordonnés, avec opérations pures et diagnostics, sans UI ni runtime. | Pas de Flame, pas d'UI, pas de modification hors de `map_core`, pas de playback runtime. | `map_core`, `cinematic_asset.dart`, `cinematic_authoring_operations.dart`, `cinematic_diagnostics.dart`. | DONE : `dart test` et `dart analyze` propres. | Divergence de step IDs (écartée par l'audit), double source (écartée par l'ownership). | DONE : modèle stable, diagnostics complets, opérations d'authoring validées par tests unitaires. | V1-106 |
| NS-SCENES-V1-108 | Cinematic Manual Path Drawing UI V0 | editor / ui | Tracé graphique du trajet manuel, configuration des points de passage (waypoint lists) et Visual Gate. | Pas de playback interactif, pas de Flame, pas de runtime. | `cinematic_manual_path_preview_overlay.dart`, `cinematic_builder_workspace.dart`, `cinematic_builder_workspace_test.dart`, screenshot V1-108. | DONE : Visual Gate V1-108-ter régénérée, ciblé V1-108 `+3`, Builder complet `+207`, Library/overlay `+26`, analyse ciblée sortie 0. | Instanciation d'objets sentinelles invalides (résolu) ; cadrage de capture Visual Gate corrigé. | DONE : tracé proportionnel affiché, waypoints ordonnés, deux repères visibles, pas d'ID technique comme workflow principal. | V1-107 |
| NS-SCENES-V1-109 | Cinematic Preview Playback Prep Contract | doc / contract | Cadrer le futur playback preview editor-only du Cinematic Builder, avec plan pur, source de vérité temporelle, transport, actorMove direct/manual path, diagnostics et anti-scope runtime/Flame. | Pas d'implémentation de playback, pas de runtime, pas de Flame, pas de ticker, pas de screenshot, pas de V1-110. | Rapport documentaire, Evidence Pack, roadmaps. | DONE : `git diff --check` documentaire. | Confondre preview editor-only et runtime ; activer les transports trop tôt ; fusionner Selection Cursor, Mouse Probe et Playback Playhead. | DONE : Option C retenue, Playback Plan pur recommandé, diagnostics/tests futurs cadrés. | V1-108 |
| NS-SCENES-V1-110 | Cinematic Preview Playback Plan Read Model V0 | core / read-model | Implémenter le plan pur de playback preview dans `map_core` : timeline items, frames déterministes, actor poses, diagnostics et capabilities. | Pas de ticker, pas de transport actif, pas de rendu editor, pas de runtime/Flame, pas de GameState. | `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`, export `map_core.dart`, test dédié, rapports. | Tests core plan vide, durée totale, active step, actorFace, actorMove direct/manual path, diagnostics, fade/camera, pureté, no persisted time. | Dupliquer les read models existants ; créer une vérité runtime cachée ; persister le temps. | DONE : plan pur exporté, frames déterministes, direct/manual path supportés côté read model, `dart analyze` et suite `map_core` complète verts, aucun editor/runtime/screenshot. | V1-109 |
| NS-SCENES-V1-111 | Cinematic Preview Playback Transport UI V0 | editor / ui | Connecter les contrôles Transport du Cinematic Builder à un état local de lecture consommant `CinematicPreviewPlaybackPlan`, sans runtime ni Flame. | Pas de timer runtime, pas de Flame, pas de GameState, pas de PlayableMapGame, pas de persistance du playhead, pas de playback runtime. | `map_editor` transport local + tests widget + rapport. | Tests Play/Pause/Stop/Reset locaux, séparation Selection Cursor / Mouse Probe / Playback Playhead, non-mutation ProjectManifest. | Confondre plan core et runtime ; rendre la timeline cliquable trop tôt ; activer des effets non supportés. | DONE : transports Play/Pause/Stop/Reset actifs, temps local, Playback Playhead distinct, statut no-code et Visual Gate, sans actor overlay playback ni runtime. | V1-110 |
| NS-SCENES-V1-112 | Cinematic ActorMove Preview Playback V0 | editor / preview-sandbox | Consommer les poses acteur du plan V1-110 pour déplacer visuellement les acteurs dans la preview pendant la lecture locale V1-111. | Pas de runtime, Flame, GameState, pathfinding, collision, scrubber/seek timeline, persistance du temps ou animation de marche avancée. | Builder cinematic actor overlay, tests widget, rapport, Visual Gate. | Tests actorMove direct/manual path visible pendant playback, non-mutation, séparation transport/sélection/probe. | Confondre preview editor-only et runtime ; déplacer les acteurs hors plan ; casser l'overlay statique existant. | DONE : les poses `CinematicPreviewPlaybackFrame.actorPoses` alimentent un modèle overlay dynamique via adaptateur editor-only, avec Visual Gate 1663x926 et tests V1-112 verts. | V1-111 |
| NS-SCENES-V1-113 | Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0 | editor / preview-sandbox | Conserver les coordonnées sub-tile des poses acteur playback dans le rendu de preview, pour supprimer l’effet de déplacement par cases. | Pas de walking animation, pas de runtime, Flame, GameState, pathfinding, collision, scrubber/seek timeline, interpolation UI ou mutation projet. | Adaptateur overlay acteur, overlay acteur, panneau preview, tests Builder, rapport, Evidence Pack, Visual Gate. | Tests V1-113 direct/manual path, pause, stop, reset, fallback pose absente/sans position, anti-round et Visual Gate. | Recalculer l’interpolation dans l’UI ; changer `map_core` inutilement ; masquer le problème par une animation de marche. | DONE : overrides sub-tile editor-only consommés depuis `actorPoses`, `round()/toInt()` supprimés pour le rendu playback, Visual Gate V1-113 générée. | V1-112 |
| NS-SCENES-V1-114 | Cinematic Actor Walking Animation Prep Contract | doc-only / architecture-review | Cadrer le futur système d’animation de marche preview-only des acteurs du Cinematic Builder, en distinguant mouvement, frame sprite, cadence, direction, fallback et anti-scope runtime/Flame/GameState, sans code produit. | Pas de code produit, pas de screenshot, pas de Visual Gate, pas de runtime, Flame, GameState, map_core ou map_editor. | Rapport V1-114, Evidence Pack, roadmaps. | Audit V1-110 à V1-113, audit sprites V1-97 à V1-99, options A-G comparées, diagnostics/tests futurs cadrés. | Coder trop tôt ; confondre interpolation de mouvement et animation sprite ; importer runtime/Flame ; faire un lot V1-115 trop large. | DONE : Option B+F retenue, trajectoire prudente resolver puis intégration, V1-115 recommandé. | V1-113 |
| NS-SCENES-V1-115 | Cinematic Actor Walking Animation Frame Resolver V0 | editor / pure-resolver | Implémenter un resolver editor-only, pur et testable, capable de choisir symboliquement une frame idle/walk/run/fallback pour les acteurs du Cinematic Builder à partir des actorPoses playback, du temps de preview, de la Character Library et des métadonnées actorMove. | Pas d'intégration renderer, pas de screenshot, pas de runtime, Flame, GameState, widget, overlay ou chargement d'image. | Resolver walking animation, test dédié, rapports, roadmaps. | Tests moving/stationary, walk/run, directions, cadence durationMs, fallbacks, déterminisme, anti-scope imports/recalcul. | Coupler le resolver au renderer ; importer Flutter indirectement ; promettre une animation visible avant V1-116. | DONE : resolver symbolique créé, tests et analyse ciblée verts, anti-scope vide. | V1-114 |
| NS-SCENES-V1-116 | Cinematic Actor Walking Animation Renderer Integration V0 | editor / preview-sandbox | Brancher le resolver V1-115 au rendu preview du Cinematic Builder afin que les acteurs affichent visuellement des frames idle/walk/run/fallback pendant le playback editor-only. | Pas de runtime, Flame, GameState, interpolation nouvelle, pathfinding, collision, map_core, manualPathId cote actorMove ou refonte multi-acteurs. | Builder preview sprite plan derivé, tests widget V1-116, Visual Gate, rapports, roadmaps. | Tests walk/run/fallback, pause, stop/reset idle, manual path, V1-113 non-regression, renderer/resolver/core ciblés, build macOS debug. | Casser l'ancrage bottom-center ; recalculer le mouvement dans l'UI ; laisser croire que la preview est runtime. | DONE : le renderer consomme la frame du resolver pendant la lecture locale, garde les fallbacks et le déplacement sub-tile, Visual Gate générée. | V1-115 |
| NS-SCENES-V1-117 | Cinematic Actor Animation Cadence / Playback Status Polish V0 | editor / preview-sandbox | Polir la cadence preview-only des frames walk/run selon la vitesse observée depuis les poses du playback plan, sans recalculer les routes, et nettoyer les statuts/badges de preview pour éviter les contradictions pendant une lecture animée active. | Pas de runtime, Flame, GameState, map_core, pathfinding, collision, recalcul de route/manual path, timer, AnimationController ou V1-118. | Resolver cadence hint, builder preview status, panneau backdrop, tests V1-117, Visual Gate, rapports, roadmaps. | Tests cadence hint, walk/run, pause, stop/reset, manual path non-mutant, statuts playback, Visual Gate, analyse ciblée, build macOS debug. | Rendre la cadence trop heuristique ; afficher encore des badges historiques ; confondre statut preview et runtime. | DONE : cadence dérivée des poses playback, statuts Lecture en cours/pause et Animation acteur prête/partielle, Visual Gate créée, anti-scope runtime intact. | V1-116 |
| NS-SCENES-V1-117-bis | ActorMove Destination Isolation Bugfix V0 | editor / bugfix | Corriger l’isolation des destinations actorMove pour que modifier la destination d’un acteur ou d’un step ne modifie pas les destinations des autres actorMove, acteurs ou trajets manuels. | Pas de V1-118, runtime, Flame, GameState, pathfinding, collision, nouveau playback, nouvelle animation, refonte Stage Points ou modification Selbrume. | `cinematic_builder_workspace.dart`, test widget V1-117-bis, rapports, roadmaps. | Test RED/GREEN multi-actorMove, V1-117, V1-116, Builder complet, Library/overlay, analyse ciblée. | Confondre une cible authoring partagée avec un bug core ; casser les bindings initiaux ; modifier manual path par accident. | DONE : chaque nouvel actorMove reçoit une destination authoring non partagée quand les cibles existantes sont déjà utilisées, et le test prouve que modifier une destination ne change pas l'autre. | V1-117 |
| NS-SCENES-V1-118 | Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0 | editor / preview-sandbox | Rendre les diagnostics et fallbacks de prévisualisation cinematic lisibles en no-code, avec détails compacts sur les acteurs/animations/sprites concernés. | Pas de V1-119, scrub/seek, runtime, Flame, GameState, map_core, pathfinding, collision, nouveau renderer ou exposition de détails techniques comme UX principale. | Helper fallback summary editor-only, Builder preview status, panneau backdrop, tests V1-118, Visual Gate, rapports, roadmaps. | Tests helper, V1-118, V1-117, V1-117-bis, V1-116, Builder complet, Library/overlay, core ciblé, analyse ciblée, build macOS debug. | Sur-expliquer la preview ; exposer sourceRect/tilesetId/payload/JSON ; ajouter du layout dans les cas sans diagnostic. | DONE : détails fallback no-code compacts, 3 messages max + compteur, Animation prête propre, Animation partielle expliquée, anti-scope runtime/map_core intact. | V1-117-bis |
| NS-SCENES-V1-119 | Cinematic Preview Playback Scrub / Seek Prep Contract | doc-only / architecture-review / interaction-contract | Cadrer le futur seek/scrub editor-only du playback preview, en separant strictement Selection Cursor, Mouse Time Probe et Playback Playhead, avec regles de hit-test, snapping, interaction Play/Pause/Stop/Reset, accessibilite et tests futurs. | Pas de code produit, pas de package, pas de screenshot, pas de Visual Gate, pas de V1-120, pas de runtime, Flame, GameState, pathfinding, collision ou persistance du temps. | Rapport V1-119, Evidence Pack V1-119, roadmaps. | Validation documentaire : audit rapports/code/tests read-only, `git diff --check`, anti-scope packages/screenshots. | Fusionner Mouse Time Probe et Playback Playhead ; faire seeker les barres au lieu de selectionner ; rendre le comportement Play pendant scrub trop complexe. | DONE : Option C retenue, hit-test strict, non-mutation cadree, tests futurs V1-120 listes, V1-120 recommande non demarre. | V1-118 |
| NS-SCENES-V1-120 | Cinematic Preview Playback Scrub / Seek UI V0 | editor / preview-sandbox | Implémenter le click-to-seek sur axe/fond vide et le drag-to-scrub du Playback Playhead dans le Cinematic Builder, en gardant Selection Cursor, Mouse Time Probe et Playback Playhead séparés. | Pas de V1-121, fade preview, runtime, Flame, GameState, map_core, pathfinding, collision, persistance playbackTimeMs, mutation projet ou nouveau moteur playback. | `cinematic_builder_workspace.dart`, tests Builder, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests V1-120, regressions V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug. | Fusionner Repère et Lecture ; faire seeker les barres ; muter les données projet ; rendre le drag fragile en lecture active. | DONE : click-to-seek axe/fond, barres selection-only, drag `Lecture`, preview acteur/animation mise à jour, non-mutation et anti-scope confirmés. | V1-119 |
| NS-SCENES-V1-121 | Cinematic Fade Preview Playback V0 | editor / preview-sandbox | Prévisualiser les blocs Fondu dans le Cinematic Builder avec un overlay editor-only piloté par `CinematicPreviewPlaybackFrame.fadeState`. | Pas de V1-122, runtime, Flame, GameState, map_core, pathfinding, collision, interpolation acteur, nouvelle persistance, mutation projet ou couleurs hardcodées. | `cinematic_builder_workspace.dart`, `cinematic_map_backdrop_preview_panel.dart`, `cinematic_fade_preview_overlay.dart`, tests Builder, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests V1-121, regressions V1-120/V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug. | Recalculer le fade dans l'UI ; couvrir timeline/inspecteur ; bloquer les interactions ; hardcoder une couleur noire. | DONE : fadeState du playback frame consommé, overlay dans la preview uniquement, Play/Pause/Stop/Reset/seek/scrub couverts, non-mutation et anti-scope confirmés. | V1-120 |
| NS-SCENES-V1-122 | Cinematic Camera Preview Playback Prep Contract | doc-only / architecture-review | Cadrer la future prévisualisation caméra editor-only du Cinematic Builder, en séparant strictement viewport d’édition, caméra cinématique, playback camera state, runtime camera et rendu preview. | Pas de code produit, pas de package, pas de screenshot, pas de Visual Gate, pas de V1-123, pas de runtime, Flame, GameState, pathfinding ou collision. | Rapport V1-122, Evidence Pack V1-122, roadmaps. | Validation documentaire : audit rapports/code/tests read-only, `git diff --check`, anti-scope packages/screenshots. | Coder une UI caméra en devinant le cadrage ; muter le viewport editor ; confondre preview editor-only et runtime camera. | DONE : Option F retenue, V1-123 read model recommandé, source de vérité future définie, séparation viewport/camera cadrée. | V1-121 |
| NS-SCENES-V1-123 | Cinematic Camera Playback State Read Model V0 | core / read-model | Implémenter dans `map_core` un état caméra de playback preview pur et déterministe, exposé par `frameAt(timeMs)`, avec `activeStepId`, `progress`, support/unsupported diagnostics et séparation stricte du viewport editor. | Pas de V1-124, UI caméra, renderer, runtime, Flame, GameState, viewport editor, screenshot ou Visual Gate. | `cinematic_preview_playback_plan.dart`, tests core, rapport, Evidence Pack, roadmaps. | Tests RED/GREEN V1-123, tests core ciblés, suite `map_core`, `dart analyze`, régressions Builder V1-120/V1-121, anti-scope packages/screenshots. | Sur-promettre un cadrage visuel sans centre/zoom ; muter le viewport editor ; confondre read model et renderer. | DONE : `cameraPose` expose état actif/inactif, mode `reset`/`hold`, progression clampée, diagnostics manquant/inconnu, aucune UI/runtime. | V1-122 |
| NS-SCENES-V1-124 | Cinematic Camera Preview Playback UI V0 | editor / preview-sandbox | Brancher l’état caméra de playback preview V1-123 au Cinematic Builder avec un overlay/cadre caméra editor-only, labels no-code et diagnostics supportés/partiels. | Pas de V1-125, nouveau modèle caméra, centre, zoom, target, follow actor, pan caméra, runtime, Flame, GameState, map_core, map_runtime ou mutation viewport editor. | `cinematic_builder_workspace.dart`, `cinematic_map_backdrop_preview_panel.dart`, `cinematic_camera_preview_overlay.dart`, tests Builder, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests RED/GREEN V1-124, régressions V1-121/V1-120/V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug. | Faire croire à un vrai pan/zoom ; exposer cameraPose/activeStepId ; bloquer seek/scrub ; hardcoder des couleurs. | DONE : `cameraPose` consommé, overlay + label no-code actifs, diagnostics unsupported no-code, inactive overlay absent, Visual Gate créée, anti-scope runtime/map_core intact. | V1-123 |
| NS-SCENES-V1-125 | Cinematic Emote Assets / Reaction Bubble Prep Contract V0 | doc-only / architecture-review / asset-audit / UX-contract | Cadrer le futur système d’emotes cinématiques à partir des assets racine `emotions.png` et `emotions2.png`, avec audit atlas, catalogue no-code, modèle `actorEmote`, diagnostics, UX inspecteur, preview playback future et trajectoire core/UI. | Pas de code produit, pas de package, pas de screenshot, pas de Visual Gate, pas de déplacement/copie d’assets, pas de pubspec, pas de V1-126. | Rapport V1-125, Evidence Pack V1-125, roadmaps. | Validation documentaire : audit assets `ls/file/shasum/sips`, audit read-only actor/playback/assets, `git diff --check`, anti-scope packages/assets/screenshots. | Exposer des frameIndex en UX ; charger les PNG depuis la racine ; confondre Emote et FX ; lancer V1-126 trop tôt. | DONE : Option B future + C + F retenue, catalogue V0 proposé, `actorEmote` cadré, V1-126 recommandé non démarré. | V1-124 |
| NS-SCENES-V1-126 | Cinematic Emote Core Model / Asset Catalog V0 | core / catalog | Implémenter le modèle core authoring du bloc `actorEmote` et le catalogue emote V0 avec JSON backward-compatible, diagnostics et tests. | Pas d’UI inspecteur, pas de renderer preview, pas de runtime, pas de Flame, pas de GameState, pas de chargement depuis chemins racine. | `map_core` cinematic asset/catalog/diagnostics/tests, rapports. | Tests JSON, catalog IDs uniques, rects valides, diagnostics actor/emote/duration, anti-scope runtime. | Surcoder le renderer ; rendre les IDs techniques visibles ; oublier l’asset path officiel. | DONE : modèle core, catalogue typé, opérations pures et diagnostics présents ; playback emote reporté. | V1-125 |
| NS-SCENES-V1-127 | Cinematic Emote Playback State Read Model V0 | core / read-model | Exposer les emotes actives dans `frameAt(timeMs)` via un état playback preview pur avant toute UI/renderer. | Pas d’UI inspecteur, pas de renderer, pas d’asset loading, pas de runtime, Flame ou GameState. | `cinematic_preview_playback_plan.dart`, tests core, rapport. | Tests activeStepId/actorId/emoteId/progress/diagnostics, non-régression seek/scrub/fade/camera/actorMove. | Démarrer le renderer trop tôt ; exposer des IDs comme workflow UI ; charger les PNG dans core. | DONE : `CinematicPreviewPlaybackFrame.activeEmotes` expose activeStepId, actorId, emoteId, labels, progress, support et diagnostics sans toucher à l’UI/runtime. | V1-126 |
| NS-SCENES-V1-128 | Cinematic Emote Block Editor UI V0 | editor / authoring | Ajouter le bloc Émotion actorEmote dans la palette et l’inspecteur du Cinematic Builder, avec picker acteur, picker réaction no-code depuis le catalogue V0, durée, diagnostics et résumé timeline humain. | Pas de rendu visuel des bulles, pas d’asset loading, pas de runtime, Flame, GameState, frameIndex visible, déplacement d’assets ou pubspec modifié. | Builder cinematic, tests widget, Visual Gate, rapport, Evidence Pack, roadmaps. | Tests RED/GREEN V1-128, régressions V1-124/V1-121/V1-120, Library/Stage overlay, tests core emote V1-126/V1-127, analyse ciblée, build macOS debug, anti-scope. | UX textuelle trop abstraite tant que les sprites ne sont pas rendus ; confusion avec Dialogue/FX. | DONE : palette Émotion, inspecteur actorEmote, pickers acteur/réaction, durée, diagnostics et label timeline humain actifs sans renderer. | V1-127 |
| NS-SCENES-V1-129 | Cinematic Emote Preview Playback UI V0 | editor / preview-sandbox | Afficher les emotes actives au-dessus des acteurs dans la preview playback du Cinematic Builder, en consommant `frame.activeEmotes` et `frame.actorPoses`, avec rendu atlas editor-only, assets officiels, fallbacks diagnostics, Play/Pause/Stop/Reset/seek/scrub fonctionnels. | Pas de runtime, Flame, GameState, FX libres, coordonnées libres, Camera Target/Zoom, ni recalcul de timeline. | `cinematic_emote_preview_overlay.dart`, preview panel, Builder, assets editor officiels, tests widget, Visual Gate, rapports. | Tests RED/GREEN V1-129, V1-128/V1-124/V1-121/V1-120, Library/Stage overlay, tests core emote/playback/authoring/diagnostics, analyses, build macOS debug, anti-scope. | Chevauchement futur emote + actorMove dépend du read model ; z-order à surveiller avec foreground complexe. | DONE : overlay emote playback visible, actorPose consommée, seek/scrub non-mutants, assets racine conservés et copies officielles déclarées. | V1-128 |
| NS-SCENES-V1-130 | Cinematic Camera Target / Zoom Authoring Prep Contract | doc-only / architecture-review | Cadrer le futur authoring Camera Target / Zoom avec cibles no-code `Centre de la scene / Acteur / Repere`, presets `Plan large / Plan moyen / Gros plan`, diagnostics futurs et separation viewport editor / camera cinematographique. | Pas de code produit, pas de package, pas de screenshot, pas de runtime, Flame, GameState, coordonnees libres ou waypoints libres. | Rapport V1-130, Evidence Pack V1-130, roadmaps. | Validation documentaire : audit read-only camera/stage/viewport/playback, `git diff --check`, anti-scope packages/screenshots. | Confondre zoom editor et zoom camera ; lancer la preview reelle trop tot ; reutiliser actorMove target comme workflow principal. | DONE : Option D + G retenue, V1-131 core model recommande, aucun code produit modifie. | V1-129 |
| NS-SCENES-V1-131 | Cinematic Camera Target / Zoom Core Model V0 | core / authoring-model | Implementer le core model camera cible/zoom retenu par V1-130 avec enums, helpers metadata, operations pures et diagnostics. | Pas d'UI preview reelle, pas de runtime, Flame, GameState, coordonnees libres, waypoints libres, `manualPathId` camera ou mutation du viewport editor. | `map_core` cinematic asset/authoring/diagnostics/tests, rapports. | Tests JSON backward-compatible, focus scene center/actor/stage point, zoom presets, diagnostics target/zoom/mode, anti-scope runtime/editor viewport. | Sur-modeliser le step Camera ; casser les blocs reset/hold historiques ; exposer des IDs techniques comme workflow principal. | DONE : mode `focus`, target kinds sceneCenter/actor/stagePoint, zoom presets wide/medium/close, bindings/helpers typés, operations pures et diagnostics core en place ; aucune UI complete ni preview camera réelle. | V1-130 |
| NS-SCENES-V1-132 | Cinematic Camera Target / Zoom Editor UI V0 | editor / authoring-ui | Brancher le core model V1-131 dans l'inspecteur Camera du Cinematic Builder avec controles no-code cible/zoom. | Pas de preview camera reelle, geometrie camera, centre/zoom numerique, runtime, Flame, GameState, mutation du viewport editor ou coordonnees libres. | Builder cinematic, tests widget, rapports. | Tests UI cible/zoom, reset/hold/focus, diagnostics no-code, anti-scope runtime/viewport. | Confondre zoom timeline/editor avec zoom camera ; exposer des IDs techniques comme workflow principal. | DONE : modes reset/hold/focus en francais, cible scene/acteur/repere, presets Plan large/moyen/gros plan, Visual Gate, sans vraie camera. | V1-131 |
| NS-SCENES-V1-133 | Cinematic Camera Geometry Playback State V0 | core / read-model | Produire un etat de geometrie camera derive cote playback : cible resolue, centre symbolique/geometrique et intention de zoom preset. | Pas de renderer UI reel, runtime, Flame, GameState, CameraComponent, mutation viewport editor, pan interactif ou preview camera finale. | `map_core` playback camera state/read model, tests, rapports. | Tests target scene/actor/stage point, zoom presets, diagnostics geometrie indisponible/supportee, regressions playback. | Sur-promettre un vrai rendu camera ; muter le viewport editor ; confondre zoom camera et zoom timeline. | DONE : `cameraPose.geometry` expose sceneCenter/actor/stagePoint, centre scene/tile, zoom preset symbolique et diagnostics honnetes, focus restant visuellement unsupported. | V1-132 |
| NS-SCENES-V1-134 | Cinematic Camera Geometry Preview UI V0 | editor / preview-ui | Brancher l'etat geometrique V1-133 dans la preview editor-only avec cadre/cible/cadrage visuel base sur la geometrie derivee. | Pas de runtime, Flame, GameState, CameraComponent, mutation viewport editor, vraie camera runtime, pan/zoom persiste ou interpolation camera. | Cinematic Builder preview, tests widget, rapports, Visual Gate. | Tests preview geometry scene/actor/stagePoint, diagnostics no-code, focus unsupported honnete, anti-scope runtime/viewport. | Faire croire a une vraie camera runtime ; confondre zoom preset et zoom numerique ; muter le viewport editor. | DONE : cadre camera editor-only, marqueur cible, labels no-code, Visual Gate et anti-scope runtime/viewport confirmes. | V1-133 |
| NS-SCENES-V1-135 | Cinematic Builder V1 Camera Closure / Polish Gate | editor / polish-gate | Fermer la sequence camera V1 par un polish/gate cible : wording, diagnostics restants, coherence inspecteur/preview et preuves finales. | Pas de nouveau moteur camera, runtime, Flame, GameState, CameraComponent, mutation viewport editor, interpolation ou nouveau continent fonctionnel. | Builder cinematic, tests de non-regression, rapports, Visual Gate finale. | Regressions camera V1-124/V1-132/V1-134, diagnostics no-code, anti-scope runtime/viewport. | Transformer le gate en nouvelle feature ; relancer une vraie camera runtime trop tot. | DONE : wording final harmonise, overlay geometrique confirme, diagnostics no-code preserves, Visual Gate finale et anti-scope runtime/viewport confirmes. | V1-134 |
| NS-SCENES-V1-136 | Cinematic Builder V1 Closure / Readiness Audit | doc / readiness-gate | Fermer officiellement le Cinematic Builder V1 par un audit global : matrice livre/backlog V2, validations finales, limites assumees et trajectoire Narrative Studio. | Pas de nouveau moteur camera, pas de runtime, pas de nouvelle feature, pas de V2 fonctionnelle, pas de mutation viewport editor. | Roadmaps, rapports, synthese readiness, preuves de non-regression. | Audit global Builder V1, checks anti-scope, tests critiques reutilises, backlog V2 explicite. | Transformer la fermeture en nouveau chantier ; masquer les limites restantes. | Recommande, non demarre. | V1-135 |

## Mise a jour V1-135

Statut : `NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate` est DONE.

Decision : la sequence camera V1 est fermee par un gate cible. L'inspecteur, l'overlay symbolique et l'overlay geometrique ne se contredisent plus : le cadrage est visible, mais la vue reste non pilotee.

Preuve : tests widget V1-135, regressions V1-134/V1-132/V1-124/V1-129, analyse ciblee, Visual Gate `ns_scenes_v1_135_cinematic_builder_v1_camera_closure_polish_gate.png` et anti-scope runtime/core/assets/Selbrume.

Limites : aucune vraie camera runtime, aucun pan/zoom reel, aucun follow permanent, aucune interpolation camera, aucun Flame/GameState et aucune mutation viewport editor.

Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-134

Statut : `NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0` est DONE.

Decision : la preview du Cinematic Builder consomme `cameraPose.geometry` pour afficher un cadre camera passif, un marqueur de cible, un libelle no-code et les diagnostics d'indisponibilite, sans recalculer la geometrie depuis les metadata.

Preuve : tests widget V1-134, regressions V1-124/V1-132/V1-129, analyse ciblee, Visual Gate `ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png` et anti-scope runtime/core/assets/Selbrume.

Limites : aucune vraie camera runtime, aucun pan/zoom numerique, aucun CameraComponent, aucun Flame/GameState et aucune mutation du viewport editor.

Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-133

Statut : `NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0` est DONE.

Decision : le read model playback expose une geometrie derivee pure via `cameraPose.geometry`. Le mode focus reste `isSupported == false` pour ne pas vendre une preview camera reelle avant le lot UI V1-134.

Preuve : tests core V1-133, regression V1-131, suite core ciblee, regression UI V1-124, analyse ciblee et anti-scope runtime/editor/assets/Selbrume.

Limites : aucune preview UI nouvelle, aucun renderer, aucun zoom numerique, aucun runtime et aucune mutation viewport. Les bounds de scene sont un input pur optionnel du read model.

Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-132

Statut : `NS-SCENES-V1-132 — Cinematic Camera Target / Zoom Editor UI V0` est DONE.

Decision : l'inspecteur Camera expose les controles no-code V1-131 sans creer de vraie camera : `Réinitialiser le cadrage`, `Maintenir le cadrage`, `Cadrer une cible`, puis cible `Centre de la scène` / `Acteur` / `Repère` et plan `Plan large` / `Plan moyen` / `Gros plan`.

Preuve : tests widget V1-132, regressions V1-124/V1-129, analyse ciblee, Visual Gate `ns_scenes_v1_132_cinematic_camera_target_zoom_editor_ui_v0.png` et anti-scope runtime/assets/Selbrume.

Limites : aucune geometrie camera, aucun centre/zoom numerique, aucun renderer reel et aucune mutation du viewport editor.

Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-131

Statut : `NS-SCENES-V1-131 — Cinematic Camera Target / Zoom Core Model V0` est DONE.

Decision : le modèle reste dans `map_core` et conserve le stockage metadata backward-compatible. `focus` est une intention authoring typée, pas une géométrie camera.

Preuve : tests V1-131 RED/GREEN puis régressions core ciblées, analyse `map_core`, régression Builder V1-124 et analyse editor ciblée.

Limites : l'UI d'authoring cible/zoom n'est pas demarrée ; la preview camera réelle et la geometrie restent hors lot.

Suite realisee : V1-132 est DONE. Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-130

Statut : `NS-SCENES-V1-130 — Cinematic Camera Target / Zoom Authoring Prep Contract` est DONE documentaire.

Decision : Option D + Option G retenue. Camera cible/zoom future doit rester no-code : `Centre de la scene`, `Acteur`, `Repere`, puis `Plan large`, `Plan moyen`, `Gros plan`. Le viewport editor local n'est pas le zoom camera cinematographique.

Preuve : audit read-only Camera V0 (`reset`/`hold`, metadata `camera.mode`, `cameraPose` symbolique), Stage Points, Actor Display, playback read model, viewport framing V1-95/V1-124, rapports crees et roadmaps alignees. Aucun code produit, package, screenshot, runtime, Flame, GameState, asset ou Selbrume n'a ete modifie par V1-130.

Limites : les enums, metadata helpers, operations pures et diagnostics restent a implementer dans V1-131.

Suite realisee : V1-132 est DONE. Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-129

Statut : `NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0` est DONE.

Résultat : le Cinematic Builder affiche les emotes actives dans la preview playback à partir du read model `frameAt(timeMs)`, sans lire la timeline brute pour l’état actif et sans muter le projet.

Preuve : tests RED/GREEN V1-129, régressions V1-128/V1-124/V1-121/V1-120, Library/Stage overlay, tests core emote/playback/authoring/diagnostics, analyse ciblée, `dart analyze`, build macOS debug, Visual Gate V1-129 et anti-scope.

Limites : l’overlay suit toute pose exposée par `actorPoses`; les scénarios avec chevauchement emote + actorMove réel restent dépendants du read model futur si la timeline devient parallèle.

Suite realisee : V1-132 est DONE. Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-128

Statut : `NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0` est DONE.

Decision : l’authoring UI du bloc actorEmote est disponible dans le Cinematic Builder. La palette expose `Émotion`, l’inspecteur propose les pickers acteur/réaction no-code, la durée reste éditable via les conventions existantes, les diagnostics restent no-code et la timeline affiche un résumé humain.

Preuve : tests RED/GREEN V1-128, régressions V1-124/V1-121/V1-120, Library/Stage overlay, tests core emote, analyse ciblée, build macOS debug et Visual Gate V1-128. Aucun renderer emote, asset loading, runtime, Flame, GameState, pubspec ou donnée Selbrume n’a été touché.

Limites : le choix d’émotion est encore textuel ; l’affichage visuel des bulles au-dessus des acteurs est le verrou du prochain lot.

Suite realisee : V1-132 est DONE. Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-127

Statut : `NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0` est DONE.

Decision : le read model pur expose `activeEmotes` dans `CinematicPreviewPlaybackFrame`, avec `CinematicActorEmotePlaybackState` immutable, progression clampée, support/diagnostics et labels acteur/emote. L’état emote référence seulement `actorId` : les positions restent dans `actorPoses`.

Preuve : tests V1-127 RED/GREEN dans `cinematic_preview_playback_plan_test.dart`, tests core ciblés, suite complète `map_core`, `dart analyze`, régressions Builder V1-121/V1-124 et Library/Stage overlay. Aucun fichier editor/runtime/asset/pubspec/Selbrume n’est modifié.

Limites : la timeline actuelle reste linéaire ; plusieurs `activeEmotes` sont supportés par la structure de liste si des fenêtres se chevauchent plus tard, mais V1-127 ne crée pas de modèle parallèle ni de renderer.

Suite realisee : V1-128 a rendu le bloc actorEmote authorable dans le Builder. Suite realisee : V1-132 est DONE. Prochain lot recommande : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-126

Statut : `NS-SCENES-V1-126 — Cinematic Emote Core Model / Asset Catalog V0` est DONE.

Decision : le core réutilise `CinematicTimelineStepKind.actorEmote`, stocke `actorId` dans le champ existant du step et `emoteId` dans metadata `actor.emoteId`, expose un catalogue typé V0 et ajoute des opérations pures + diagnostics dédiés. Le playback state emote a ensuite été ajouté par V1-127.

Preuve : tests catalogue/authoring/diagnostics/playback boundary, suite `map_core`, `dart analyze`, régressions Builder ciblées et anti-scope passés dans le lot V1-126.

Suite realisee : V1-127 puis V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-125

Statut : `NS-SCENES-V1-125 — Cinematic Emote Assets / Reaction Bubble Prep Contract V0` est DONE documentaire.

Decision : le pivot demandé est accepté. V1-124 laisse une caméra symbolique suffisante pour avancer ; les emotes apportent une valeur visuelle immédiate et disposent déjà de deux atlas candidats à la racine du projet. Le système futur doit utiliser un catalogue typé no-code, un bloc `actorEmote` attaché à un acteur et une preview dérivée de `frameAt(timeMs)`, sans frameIndex visible comme workflow principal.

Preuve : assets racine audités (`emotions.png`, `emotions2.png`), dimensions `128 x 48` prouvées, hypothèse `8 x 3` cellules de `16 x 16` documentée, options A-F comparées, rapports V1-125 créés et roadmaps alignées.

Limites : les assets restent à leur emplacement actuel et ne sont que candidats ; aucun modèle, catalogue, UI, renderer, pubspec, runtime, Flame, GameState ou screenshot n’a été créé. Camera Target / Zoom est reporté en V1-130.

Suite historique : les lots recommandes V1-126, V1-127 et V1-128 ont ete realises. Prochain lot global actuel : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-124

Statut : `NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0` est DONE.

Decision : le Cinematic Builder consomme `CinematicPreviewPlaybackFrame.cameraPose` et affiche un cadre symbolique editor-only dans la preview, avec badge `Caméra active`, label `Cadrage caméra prêt` pour les modes supportés V0 et diagnostics no-code pour les états partiels. Aucun pan/zoom réel n’est simulé.

Preuve : tests V1-124, régressions playback/fade/actor/fallback, suite Builder complète, tests core ciblés, analyse ciblée, build macOS debug et Visual Gate V1-124.

Limites : la vraie géométrie caméra reste absente du read model. Ce verrou cible/zoom reste pertinent, mais il est reporté en V1-129 après la chaîne emotes.

Suite realisee : V1-125 a cadré les emotes cinématiques, puis V1-126 a posé le core/catalogue ; prochain lot global actuel : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-123

Statut : `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0` est DONE.

Decision : le Cinematic Builder dispose maintenant d'une source de vérité `map_core` consommable plus tard : `CinematicPreviewPlaybackFrame.cameraPose` expose `isActive`, `isSupported`, `supported`, `activeStepId`, `mode`, `progress` et `diagnostics`. Les modes persistés `reset` et `hold` sont supportés côté read model ; les modes inconnus ou manquants restent diagnostiqués sans crash.

Preuve : tests V1-123 ajoutés, tests `map_core` ciblés et complets relancés, `dart analyze` vert, régressions Builder V1-120/V1-121 relancées et anti-scope vide.

Limites : aucun centre/zoom fiable n'est inventé, aucune UI caméra ou Visual Gate n'est démarrée, aucun viewport editor/runtime/Flame/GameState n'est modifié.

Prochain lot recommande historique apres V1-123 : `NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0` (realise) ; prochain lot global actuel : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-122

Statut : `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract` est DONE documentaire.

Decision : le modèle actuel ne suffit pas pour une UI camera directe. `CinematicPreviewPlaybackFrame.cameraPose` est encore un placeholder `supported: false`, les capabilities disent `supportsCamera: false`, et les blocs Camera V0 ne portent que `reset` / `hold` + durée. La suite recommandée est donc `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0`, puis une UI V1-124.

Preuve : rapport V1-122, Evidence Pack V1-122, audit read-only des rapports V1-110/V1-121, du playback plan, du bloc Camera authoring, du viewport backdrop pan/zoom et des tests existants.

Limites : aucun code produit, package Dart/Flutter, runtime, Flame, GameState, screenshot, Visual Gate ou V1-123 n'a été démarré.

Suite realisee : `NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0` est DONE ; `NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0` est maintenant DONE ; prochain lot global actuel : `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-121

Statut : `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0` est DONE.

Decision : la preview de Fondu consomme `CinematicPreviewPlaybackFrame.fadeState` et peint un overlay editor-only dans la preview map frame. Le comportement suit Play/Pause/Stop/Reset, click-to-seek et drag-to-scrub sans muter `CinematicAsset`, `ProjectManifest` ou `MapData`.

Preuve : tests V1-121, regressions V1-120/V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug et Visual Gate V1-121.

Limites : aucun runtime, Flame, GameState, map_core, pathfinding, collision, interpolation acteur, nouvelle persistance ou couleurs hardcodées n'a ete demarre pendant V1-121.

Suite historique : V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-120

Statut : `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0` est DONE.

Decision : le Cinematic Builder supporte le click-to-seek sur l'axe temporel et le fond vide des pistes, plus le drag-to-scrub du Playback Playhead `Lecture`. Les barres restent des cibles de selection auteur et ne seekent pas.

Preuve : tests V1-120, regressions V1-118/V1-117/V1-117-bis/V1-116, Builder complet, Library/overlay, fallback summary, core ciblé, analyse ciblée, build macOS debug et Visual Gate V1-120.

Limites : le fade preview a ete traite par V1-121 ; aucun runtime, Flame, GameState, map_core, pathfinding ou collision n'a ete demarre pendant V1-120. La capture reste issue du harness test.

Suite historique : V1-121 puis V1-122 ont ete realises ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-119

Statut : `NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract` est DONE documentaire.

Decision : `Option C — Click-to-seek + drag Playback Playhead controle` est retenue. Le futur V1-120 devra permettre le click-to-seek sur axe/fond timeline vide, le drag-to-scrub depuis le Playback Playhead, et conserver le clic sur barre comme selection de bloc.

Contrat central : `Selection Cursor` reste selection auteur, `Mouse Time Probe` reste inspection-only, `Playback Playhead` devient la future cible seek/scrub. Le seek ne suit pas l'inspecteur et ne persiste aucun etat dans `CinematicAsset`, `ProjectManifest` ou `MapData`.

Preuve : rapports V1-109 a V1-118 et timeline/probe V1-51/V1-52/V1-53/V1-61 a V1-70 relus, code/tests audites en lecture seule, rapport et Evidence Pack V1-119 crees, roadmaps alignees.

Limites historiques : aucun package Dart/Flutter n'avait ete modifie, aucun screenshot n'avait ete cree et V1-120 n'etait pas demarre pendant ce contrat documentaire. Cette limite a ete levee par V1-120.

Suite historique : V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-118

Statut : `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0` est DONE.

Decision : le Builder consomme un helper editor-only `CinematicPlaybackPreviewFallbackSummary` qui agrège les raisons fallback du resolver walking animation et du sprite preview plan en messages courts no-code, avec severites `info`, `warning`, `error`, trois messages visibles maximum et compteur `+N autre(s) point(s) a verifier`.

Preuve : tests helper, resolver, renderer, V1-118, V1-117, V1-117-bis, V1-116, Builder complet, Library/overlay, core ciblé, analyse ciblée, build macOS debug et Visual Gate V1-118.

Limites : le mapping reste volontairement borne aux diagnostics deja disponibles. Aucun runtime, Flame, GameState, `map_core`, scrub/seek, pathfinding, collision ou V1-119 n'a ete demarre.

Suite historique : V1-119 a ete realise en documentaire ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-117-bis

Statut : `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` est DONE.

Demande : verifier si le bug rapporte par Karim et formalise dans le prompt existe vraiment, puis corriger uniquement la regression d'isolation actorMove.

Verdict : bug confirme. Le modele core met deja a jour les actorMove par `stepId`; la regression venait de l'UI d'ajout depuis la palette, qui reutilisait la premiere `movementTarget` pour plusieurs blocs actorMove. Comme l'inspecteur edite le binding par `targetId`, plusieurs steps pouvaient partager la meme destination authoring.

Correction : `_addActorMove` choisit une cible non encore employee par un actorMove ; si aucune n'est libre, il cree une destination dediee, copie le binding de reference et assigne cette nouvelle cible au step cree.

Preuve : test RED puis GREEN `V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged`, suites V1-117/V1-116, Builder complet, Library/overlay et analyse ciblee documentees dans le rapport et l'Evidence Pack.

Limites historiques : aucun runtime, Flame, GameState, pathfinding, collision, nouveau playback, nouvelle animation ni V1-118 n'avait ete demarre pendant ce bis. `selbrume/project.json` etait deja dirty au Gate 0 et n'a pas ete modifie par ce lot.

Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-117

Statut : `NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0` est DONE.

Demande : polir la cadence visuelle preview-only des frames walk/run selon la vitesse observée depuis les poses du playback plan, puis remplacer les badges historiques contradictoires pendant une lecture animée active.

Decision : le builder calcule un hint de cadence editor-only en comparant la pose courante avec la pose du plan a `t - 100 ms`. Le resolver reste compatible V1-115 sans hint et ajuste uniquement la durée effective des frames walk/run avec des bornes prudentes. Les statuts visibles deviennent `Aperçu statique`, `Lecture en cours`, `Lecture en pause`, `Animation acteur prête`, `Animation partielle` ou `Aucun acteur animé`.

Preuve : tests resolver cadence, tests widget V1-117, non-régressions V1-116/V1-113, Visual Gate V1-117, analyse ciblée, build macOS debug, tests core ciblés et anti-scope documentés dans le rapport et l'Evidence Pack V1-117.

Limites historiques : la cadence reste une heuristique déterministe preview-only et ne remplace pas un vrai système runtime d'animation. Les details de diagnostic ont ete traites par V1-118.

Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-116

Statut : `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` est DONE.

Demande : brancher le resolver V1-115 au renderer/overlay de preview afin que `actorMove` affiche des frames de marche/course pendant la lecture editor-only.

Decision : plan de sprites derive dans le builder pendant la lecture locale uniquement, avec remplacement du `sourceTileRect` par la frame resolue. Aucun runtime, Flame, GameState, `map_core`, pathfinding ou recalcul de mouvement.

Preuve : tests V1-116, Visual Gate V1-116, tests resolver/renderer/V1-113/core, analyse ciblee, build macOS debug et anti-scope documentes dans les rapports V1-116.

Limites historiques : les libelles/status de preview restaient a polir pour ne plus afficher des badges historiques contradictoires pendant une lecture animee ; cette limite est traitee par V1-117.

Suite historique : V1-117 puis V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-115

Statut : `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0` est DONE.

Demande : choisir symboliquement la frame `idle | walk | run | fallback` des acteurs cinematic pendant le playback preview, sans lancer l'intégration renderer.

Decision : nouveau fichier resolver dédié, synchrone et déterministe, consommant les poses playback et les animations Character Library sans dépendre de Flutter, Flame, runtime ou widgets.

Preuve : test resolver dédié `+9`, renderer sprite `+21`, V1-113 ciblé `+5`, core playback plan `+12`, core actor display `+27`, analyses ciblées propres et checks anti-scope vides.

Limites historiques : au moment de V1-115, aucune animation n'etait encore affichee ; cette limite a ete traitee par V1-116 puis polie par V1-117.

Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-114

Statut : `NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract` est DONE documentaire.

Demande : cadrer le futur système d’animation de marche preview-only après le mouvement sub-tile fluide V1-113, sans modifier les packages ni créer de capture.

Decision : Option B + F retenue. Un resolver editor-only séparé choisira une frame symbolique `idle | walk | run | fallback` selon `actorPoses`, `playbackTimeMs`, `actor.movementMode` et les animations Character Library ; l’intégration renderer est repoussée à V1-116.

Preuve : rapport et Evidence Pack V1-114 dédiés, avec anti-scope packages/screenshots/runtime.

Limites historiques : V1-114 documentait seulement le contrat. V1-115 a livré le resolver symbolique ; l'affichage animé a ete traite par V1-116 puis poli par V1-117.

Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-113

Statut : `NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0` est DONE.

Demande : Fluidifier le rendu actorMove direct/manual path dans la preview du Cinematic Builder en conservant `pose.x`/`pose.y` comme `double`, sans recalculer l’interpolation dans l’UI.

Decision : Option A retenue. L’adaptateur retourne le modèle d’affichage acteur et une table d’overrides sub-tile par acteur ; l’overlay utilise ces overrides uniquement quand `CinematicPreviewPlaybackFrame.actorPoses` fournit une position.

Preuve : tests V1-113 ciblés, Visual Gate `ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png`, rapport et Evidence Pack dédiés.

Limites : le mouvement est fluide en position, mais aucune animation de marche frame-by-frame n’est démarrée.

Suite historique : V1-114, V1-115, V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-112

Statut : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` est DONE.

Demande : Connecter les poses acteur du `CinematicPreviewPlaybackFrame` au rendu preview du Cinematic Builder afin que les acteurs se déplacent visuellement pendant la lecture locale, sans recalculer l’interpolation dans l’UI, sans runtime, Flame, GameState, pathfinding ni animation de marche.

Decision : `map_editor` consomme `playbackPlan.frameAt(playbackTimeMs)` puis projette les `actorPoses` dans le modèle d’affichage acteur existant via un adaptateur dédié. La preview donne la priorité au modèle dynamique pour l’overlay acteur et garde le modèle statique pour les fallbacks/diagnostics et les aides authoring.

Preuve : tests V1-112 ciblés `+3`, Builder complet `+214`, Library/Stage overlay `+26`, sprite renderer `+21`, régressions `map_core` `+12/+27/+4`, `dart analyze` map_core sans issue, analyse ciblée `map_editor` sortie 0 avec 37 infos non fatales `prefer_const_*`, Visual Gate `ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png` en 1663x926 avec shasum `a53f2d0e5d4538afa8c5fbcffdab7ae481dd90f191c64c4290c0b78dd31baa4d`.

Limites : le contrat overlay acteur reste ancré sur des positions entières de tuile, donc la pose playback est consommée comme source de vérité mais projetée par arrondi dans l’overlay actuel. Aucun scrubber, seek, runtime, Flame, GameState, collision/pathfinding, animation de marche ou persistance du temps n’a été ajouté.

Historique avant V1-113 : V1-112 recommandait de corriger la précision visuelle du playback acteur. Cette limite a ete traitée par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-111

Statut : `NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0` est DONE.

Demande : Connecter les contrôles transport du Cinematic Builder au `CinematicPreviewPlaybackPlan` V1-110 avec un état local editor-only, sans runtime, Flame, GameState ni déplacement acteur rendu.

Decision : `map_editor` porte le ticker local avec `AnimationController`, affiche Play/Pause/Stop/Reset, temps courant, Playback Playhead `Lecture` et badges no-code. La sélection auteur et le Mouse Time Probe restent distincts du Playback Playhead.

Preuve : tests V1-111 ciblés `+4`, Builder complet `+211`, Library/Stage overlay `+26`, régressions `map_core` `+12/+4/+27`, Visual Gate `ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png` prouvée par shasum `2bb8db8e7679576d49d6fa62f4688f2e12482024712f48de5214eeca7afafcba`.

Limites historiques au moment de V1-111 : actor overlay playback non démarré ; aucun scrubber, seek, runtime, Flame, GameState ou persistance. Cette limite a ete traitée par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; V1-120 puis V1-121 ont ete realises ; V1-122 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-136 — Cinematic Builder V1 Closure / Readiness Audit`.

## Mise a jour V1-110

Statut : `NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0` est DONE.

Demande : Implémenter dans `map_core` un read model pur et déterministe du futur playback preview cinématique, sans UI, ticker, transport actif, runtime, Flame, GameState, screenshot ni V1-111.

Decision : Le plan exporté `CinematicPreviewPlaybackPlan` s'appuie sur `CinematicTimelineTimeLayoutReadModel` comme source de vérité temporelle. `frameAt(timeMs)` clamp le temps et évalue les poses d'acteurs, `actorFace`, `wait`, `actorMove` direct, `actorMove` manual path, fade V0 et caméra placeholder unsupported.

Preuve : test V1-110 dédié `+12`, tests ciblés existants verts, `dart analyze` sans issue et suite complète `map_core` `+2496`. Checks anti-scope vides pour `map_editor`, runtime/gameplay/battle/examples, Xcode et screenshots V1-110.

Limites : Pas de transport UI, pas de ticker, pas d'overlay connecté au playback, pas de runtime/Flame, pas de pathfinding/collision, pas d'animation de marche frame-by-frame.

## Mise a jour V1-109

Statut : `NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract` est DONE documentaire.

Demande : Cadrer le futur playback preview editor-only du Cinematic Builder sans implémenter de lecture, sans rendre les transports fonctionnels, sans runtime, sans Flame et sans V1-110.

Decision : Option C retenue : un plan de playback pur dans `map_core`, puis état/ticker/rendu local dans `map_editor`. Le contrat sépare explicitement Selection Cursor, Mouse Time Probe et Playback Playhead.

Preuve : Rapport `ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`, Evidence Pack `ns_scenes_v1_109_evidence_pack.md`, roadmaps mises à jour, validation documentaire `git diff --check`.

Limites : Aucun playback codé, aucun transport actif, aucun screenshot, aucun package modifié, V1-110 non démarré.

## Mise a jour V1-108

Statut : `NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0` est DONE.

Demande : Karim a demandé le tracé visuel des chemins manuels (dashed lines, badges numérotés) dans l'éditeur, avec configuration des points de passage intermédiaires (ajout, suppression, réordonnement) et Visual Gate.

Decision : Implémentation du CustomPainter `CinematicManualPathPreviewOverlay` pour projeter et dessiner le trajet à l'écran. Intégration de l'éditeur latéral dans `_ActorMoveControls`. Résolution nullable propre (`cast<CinematicManualPath?>().firstWhere`) pour éviter les plantages avec les objets sentinelles.

Preuve : Visual Gate V1-108-ter régénérée sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png` en 1663x926, checksum `f016199226ef426bdb8a28554d0221f130b06471af7f3246113b0853230dd1fe`. Tests demandés relancés : ciblé V1-108 `+3`, Builder complet `+207`, Library/overlay `+26`; analyse ciblée sortie 0 avec 37 infos non fatales `prefer_const_*`.

Limites : Pas de playback visuel, pas de Flame, pas de runtime.

## Mise a jour V1-107

Statut : `NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0` est DONE.

Demande : Implémenter le modèle core authoring-only des chemins manuels cinématiques, stocké dans `CinematicStageContext.manualPaths`, avec sérialisation backward-compatible, opérations pures d'édition et diagnostics, sans UI ni runtime.

Decision : L'ownership est stocké côté chemin via `ownerActorMoveStepId` en se basant sur le step ID stable existant. Le mode de trajet `manual` a été ajouté. Les opérations pures d'authoring (CRUD sur les chemins et points de passage) et 12 diagnostics statiques dédiés ont été implémentés et testés.

Preuve : Tous les tests unitaires et d'intégration de `map_core` compilent et passent (2484 tests au total). `dart analyze` retourne zéro erreur.

Limites : Pas d'UI de dessin, pas de preview graphique, pas de runtime.

## Mise a jour V1-106

Statut : `NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract` est DONE documentaire.

Demande : Cadrer le futur système de trajets manuels cinématiques sans modifier de code produit.

Decision : Recommander `CinematicManualPath` dans `CinematicStageContext.manualPaths`, V0 composé de Repères de scène ordonnés et owned par actorMove. La Destination finale reste dans actorMove/movementTargetBinding ; le Chemin manuel ne contient que des points de passage intermédiaires. `pathMode` pourra évoluer de `direct` vers `manual` en V1-107.

Preuve : Rapport et Evidence Pack créés, roadmaps mises à jour, aucun package modifié, aucun runtime/playback/Flame/Xcode/Visual Gate.

Limites : V1-107 non démarré ; pas de modèle Dart ni de diagnostics codés.

## Mise a jour V1-105

Statut : `NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0` est DONE.

Demande : Karim a demandé de traiter la simplification UX/vocabulaire avant de continuer vers les chemins manuels.

Decision : V1-105 est réattribué au vocabulaire no-code du Cinematic Builder. L'ancien lot `Cinematic Manual Path Authoring Prep Contract` devient V1-106, puis le core model Manual Path devient V1-107, l'UI de dessin V1-108 et le prep playback V1-109.

Preuve : Tests Builder/Library/overlay verts, analyse ciblée `flutter analyze --no-fatal-infos` en sortie 0, Visual Gate `ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png`.

Limites : Aucun contrat Manual Path, aucune mutation core/runtime, aucun branchement gameplay.

## Mise a jour V1-104 bis

Statut : `NS-SCENES-V1-104-bis — ActorMove Stage Point Target Evidence / Quality Gate Closure` est DONE.

Demande : Clôturer proprement et documenter le pack de preuves de V1-104 sans modifier le code produit.

Decision : Rédaction du rapport final de clôture bis et de l'Evidence Pack. Exécution des tests unitaires et widget (100% verts) et de l'analyse statique. Vérification par shasum de la Visual Gate (1663x926, aucun diagnostic).

Note : V1-104-bis est maintenu comme closure evidence de V1-104. Un scope repair a isolé les changements macOS/Xcode hors NS-SCENES. Le correctif macOS est suivi séparément par BUILD-MACOS-01.

## Mise a jour V1-104

Statut : `NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0` est DONE.

Demande : Permettre à une instruction cinématique `actorMove` d’utiliser un Stage Point existant comme cible de déplacement. Rendre la transition entre types de cibles propre (sans valeur zombie `sourceId`). Afficher l'option "Point de scène" et le picker dans l'inspecteur de cible de mouvement de la sidebar.

Decision : Ajout du cas `stagePoint` dans l'enum `CinematicMovementTargetBindingKind`. Résolution des coordonnées du target binding à partir du Stage Point correspondant. Implémentation des diagnostics statiques et de readiness map-aware (`movementTargetBindingStagePointMissing`, `movementTargetBindingStagePointWithoutStageMap`, `movementTargetBindingStagePointOutOfMap`). Ajout d'une option par bouton dans l'inspecteur latéral pour sélectionner le type "Point de scène" et affichage d'un sélecteur no-code (`_StagePointSourcePicker`). Validation des transitions propres (suppression des valeurs zombies `sourceId`).

Preuve : Tous les tests unitaires et widget (y compris `cinematic_builder_workspace_test.dart` et `cinematic_authoring_operations_test.dart` avec les nouveaux tests de transitions directes) passent avec succès (100% verts). Génération de la Visual Gate avec le diagnostic sur le target résolu et absent de la liste, sauvegardée sous : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png`.

Limites : Pas d'interpolation de mouvement interactif, pas de tracé graphique de chemins.

Prochain lot exact recommande : `NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract`.

## Mise a jour V1-103 bis

Statut : `NS-SCENES-V1-103-bis — Actor Initial Placement Stage Point Evidence / Visual Truth Closure` est DONE.

Demande : Clôturer proprement et documenter le pack de preuves de V1-103 sans modifier le code produit.

Decision : Rédaction du rapport final de clôture bis et de l'Evidence Pack. Exécution à blanc des tests unitaires et widget (100% verts) et de l'analyse statique. Vérification par shasum et par inspection de la vérité visuelle de la Visual Gate (1663x926, diagnostics actifs, apparence non définie).

Preuve : Rapports finaux et Evidence Pack complets sans modification de code produit.

## Mise a jour V1-103

Statut : `NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0` est DONE.

Demande : Permettre d'utiliser un Stage Point existant comme position initiale d'un acteur cinématique. L'acteur requis doit pouvoir faire référence à un `stagePointId` plutôt que de dupliquer des coordonnées géométriques (compatibilité JSON conservée). Fournir un picker no-code dans l'inspecteur latéral avec coordonnées secondaires et labels clairs. Mettre à jour dynamiquement le rendu statique et les diagnostics si le point de scène est déplacé ou supprimé.

Decision : Ajout du type de placement `CinematicActorInitialPlacementKind.stagePoint` avec `stagePointId` facultatif dans `CinematicActorInitialPlacement`. Résolution dynamique des coordonnées logiques de l'acteur via le read model `CinematicActorDisplayPreviewModel` en parcourant les points de scène actifs de la cinématique. Ajout d'une option de placement par radio dans la barre d'outils d'inspecteur de l'éditeur qui se déplie sur un sélecteur no-code (`_StagePointDropdownPopup`). Implémentation des diagnostics statiques et dynamiques (`actorInitialPlacementStagePointMissing`, `actorInitialPlacementStagePointWithoutStageMap`, `actorInitialPlacementStagePointOutOfMap`).

Preuve : Tous les tests unitaires et widget (y compris `cinematic_builder_workspace_test.dart`) passent sans aucune régression. Génération de la Visual Gate avec le sprite de Timi placé sur un point de scène sous : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_103_cinematic_actor_initial_placement_from_stage_points_v0.png`.

Limites : Pas de playback visuel ni de liaison directe à actorMove/cibles de mouvement.

Prochain lot exact recommande : `NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0`.

## Mise a jour V1-102 ter

Statut : `NS-SCENES-V1-102-ter — Stage Point Placement Evidence Pack Final Closure` est DONE.

Demande : Clôturer proprement et documenter le pack de preuves sans modifier le code produit.

Decision : Rédaction du rapport final de clôture ter et de l'Evidence Pack. Exécution à blanc des tests unitaires et widget (100% verts) et de l'analyse statique. Vérification par shasum de la Visual Gate.

Preuve : Rapports finaux et Evidence Pack complets sans modification de code produit.

## Mise a jour V1-102 bis

Statut : `NS-SCENES-V1-102-bis — Stage Point Placement UX Discoverability / Evidence Pack Repair / Codex Rules Alignment` est DONE.

Demande : Rendre le placement des Stage Points évident et accessible (remplacer l'icône de toolbar par un bouton texte, ajouter une bannière d'aide en mode placement, un message d'empty state dans le canvas et la sidebar, la touche Échap pour annuler, et afficher la liste des points dans l'inspecteur).

Decision : Modification de `_BackdropFramingControls` pour afficher un bouton texte. Ajout des widgets d'overlays de messages `_AddStagePointInstructionOverlay` et `_EmptyStagePointsHelperOverlay` se superposant directement dans le stack du canvas sans modifier la géométrie du viewport. Écoute globale de la touche Échap dans un widget `Focus` parent de `CinematicBuilderWorkspace`. Création d'une puce interactive de liste de points de scène (`_StagePointsSection`) dans le panneau latéral.

Preuve : Tous les 198 tests de `cinematic_builder_workspace_test.dart` sont 100% verts. Screenshot visual gate généré à `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_102_bis_stage_point_placement_ux_discoverability.png`.

Limites : Pas de playback visuel ni de liaison directe à actorMove/initialPlacement.

## Mise a jour V1-102

Statut : `NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0` est DONE.

Demande : Visualiser, créer (snappé au centre), sélectionner, déplacer par drag-and-drop (avec contraintes physiques aux limites de la map), renommer et supprimer des Stage Points cinématiques dans la preview et l'inspecteur. Zero modification to `MapData`, no new `mapEntity` / `mapEvent` creations, no Flame/runtime playback changes, and respect PokeMap design system widgets/tokens.

Decision : Création du composant `CinematicStagePointPreviewOverlay` positionné dans le frame de preview du décor de fond. Conversion géométrique écran-carte correcte (correctif du décalage lié au cadrage/pan/zoom). Alignement du comportement du drag and drop en éliminant la zone de tolérance de geste de Flutter (touch slop) via la capture des coordonnées initiales globales de touch-down. Gestion de l'inspecteur latéral pour l'édition de nom et la suppression.

Preuve : Test de non-régression visual gate `captures V1-102...` passant à 100% vert, générant le snapshot de référence dans narrativeStudio/scenes/screenshots. Tous les tests widgets dédiés verts.

Limites : Pas de liaison au placement initial d'acteur ou aux targets actorMove. Pas de playback visuel ni d'interaction runtime map/Flame.

Prochain lot exact recommande : `NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0`.

## Mise a jour V1-101

Statut : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0` est DONE.

Demande : Implémenter le modèle core des points de scène (`CinematicStagePoint`) sous le `stageContext` des cinématiques, la désérialisation/sérialisation JSON rétrocompatible, les opérations pures d'édition (add, update, remove), et le moteur de diagnostic avec ses 6 codes de validation (duplicate, empty ID, empty label, invalid coordinate, out of map bounds, missing map context). Pas de Flame, pas d'UI, pas de modification hors de `map_core`.

Decision : Ajout de la structure immutable `CinematicStagePoint` à `CinematicStageContext`. Coordonnées `x` et `y` typées en `double` sans restriction de finiteness au constructeur ou en désérialisation JSON (pour ne pas perturber la détection de diagnostics de format cassé), mais validées par diagnostics et authoring. diagnostics optionnels named `mapWidth`/`mapHeight` pour garder la rétrocompatibilité des signatures existantes.

Preuve : `dart test` et `dart analyze` propres dans `map_core`. Tests ajoutés couvrant la compatibilité JSON descendante (ancien JSON sans `stagePoints`), la préservation de l'ordre, les doublons, et les limites physiques optionnelles.

Limites : Modèle core et diagnostics pures uniquement. Pas de placement sur Canvas, pas de rendu visuel, pas de liaison au timeline actorMove/initialPlacement.

Prochain lot exact recommande : `NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0`.

## Mise a jour V1-100

Statut : `NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0` est DONE.

Demande : Cadrer l'édition spatiale des cinématiques directement dans la preview sans repasser par le Map Editor, définir le modèle de stockage local et décorrélé de la map de fond, la transformation géométrique bidirectionnelle écran-carte avec pan/zoom, les modèles d'interactions d'auteur (Option C), les liens avec la timeline (initialPlacements et targets), préparer les chemins manuels sans pathfinding ni collision au runtime, lister les diagnostics et la stratégie de tests.

Decision : Cadrage documentaire complet. Modèle CinematicStagePoint autonome stocké sous stageContext.stagePoints. Formules d'inversion géométrique avec pan/zoom et snapping à la tuile. Interaction via barre d'outils locale (mode outil). Diagnostics statiques complets (8 nouveaux codes) et tests unitaires/widget prévus pour V1-101+.

Preuve : Rapport de contrat ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md rédigé, Evidence Pack complet et roadmaps ajustées. Aucun code packages/ modifié (anti-scope respecté).

Limites : Lot documentaire de cadrage théorique uniquement. Aucun code produit, modèle core, UI ou test créé.

Prochain lot exact recommande : `NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0`.

## Mise a jour V1-99 bis

Statut : `NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0` est DONE.

Demande : Prouver le rendu avec un vrai sprite non plat dans le test de capture et les tests de rendu, interdire le hardcode Selbrume dans `lib/`, vérifier les dimensions du modèle strictement (32x32 tileset / 64x64px frame), et valider les hors-limites avec diagnostic/fallback sans crash.

Decision : Utilisation de `actor_sprite_test_sheet.png` (copie neutre de Timi) dans `test/fixtures/cinematics/`. Rendu configuré en 32x32px par tuile / 64x64px par frame (Timi south-idle). Le test de non-platitude échantillonne les pixels pour confirmer qu'il y a plus de 2 couleurs distinctes (23 couleurs uniques). Validation `sourceRect` hors atlas implémentée côté overlay et renderer avec messages diagnostics explicites (via `debugPrint`) et fallbacks propres.

Preuve : Tous les tests unitaires et widget dans `cinematic_actor_sprite_preview_renderer_test.dart` (21 tests) et `cinematic_builder_workspace_test.dart` passent avec succès. Nouvelle Visual Gate produite montrant le sprite complet de Timi bien aligné et dimensionné.

Limites : preview statique de la première frame idle de l'acteur.

Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.

## Mise a jour V1-99

Statut : `NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0` est DONE.

Demande : Karim a demandé d’afficher des sprites statiques réels quand ils sont résolus dans la preview, tout en conservant les placeholders V1-92 comme fallback, en préservant la profondeur V1-96-bis et sans enfreindre l'anti-scope.

Decision : Branchement du CinematicActorSpritePreviewPlan. Les images des sprites acteurs sont préchargées et mises en cache hors des cycles build/paint. CustomPaint dédié avec CinematicActorSpritePainter pour le rendu bitmap statique. Les labels, direction hints et diagnostics restent lisibles et accessibles.

Preuve : 17 tests unitaires de rendu validés dans `cinematic_actor_sprite_preview_renderer_test.dart` et test visual gate validé dans `cinematic_builder_workspace_test.dart`. Tous les tests passent au vert (213/213).

Limites : Rendu purement statique et sans playback temporel interactif ni interpolation.

Prochain lot exact recommande : `NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0`.

## Mise a jour V1-98

Statut : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0` est DONE.

Demande : Karim a demandé d'exécuter la V1-98 en implémentant le résolveur synchrone et purement symbolique, sans chargement/décodage d'images ni widgets Flame, en extrayant les dimensions de `frameWidth`/`frameHeight` du personnage plutôt que de `TilesetSourceRect`, et avec gestion des diagnostics/fallbacks de direction de l'animation idle.

Decision : Résolveur synchrone implémenté dans `CinematicActorSpritePreviewPlan` et `buildCinematicActorSpritePreviewPlan`. Support des fallbacks directionnels avec avertissement `actorDisplayDirectionFallback`, gestion de `missingIdleAnimation`, `missingDirectionFrame`, `missingCharacter`, `missingTileset` et `invalidSourceRect`. Les dimensions d'acteurs viennent de `frameWidth` et `frameHeight` de la fiche personnage.

Preuve : 9 tests unitaires complets écrits dans `cinematic_actor_sprite_preview_resolver_test.dart` passant à 100% au vert. Analyse statique Dart/Flutter propre à 100%.

Limites : Résolution logique pure, sans aucun chargement/décodage réel d'images ni affichage UI.

Prochain lot exact recommande : `NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0`.

## Mise a jour V1-97

Statut : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract` est DONE.

Demande : Karim a demandé d'auditer et cadrer la résolution asynchrone des sprites d'acteurs statiques depuis le ProjectManifest (Character Library, settings.defaultPlayerCharacterId, npc/trainer mapEntity) sans modifier de code produit ni importer de runtime Flame/gameplay.

Decision : Option C (Resolver séparé) et Option A (Réutilisation de CinematicTilesetAssetRegistry) retenues. Les métadonnées symboliques de map_core suffisent à guider la recherche de tilesets. La frame 0 d'une animation idle déterminée par direction sera découpée et mise en cache. Si indisponible, le fallback pastille V1-92 est conservé.

Preuve : Rapport de contrat V1-97 rédigé, diagnostics et tests unitaires V1-98 planifiés, checks anti-scope passés propres.

Limites : Lot documentaire de design-first uniquement. Aucun code produit modifié.

Prochain lot exact recommande : `NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0`.

## Mise a jour V1-96 bis

Statut : `NS-SCENES-V1-96-bis — Cinematic Backdrop Real Map Editor Ordering Investigation / Fix V0` est DONE.

Demande : Karim a demandé d'enquêter sur les divergences réelles, de respecter la pile de calques de l'éditeur (notamment water/ponton et toits/murs) et de s'assurer que les éléments placés multi-tuiles soient rendus cellule par cellule.

Decision : Alignement du comparateur cinématique sur le comportement du `MapGridPainter`. Ordre de rendu corrigé : Terrain -> Path (eau) -> TileBackground (ponton) -> Surface -> PlacedBackground -> Foreground. Sens de parcours décroissant (`layerIndex` descendant). Tri Y/X local en tie-breaker et zOrder conservé pour les éléments placés. Les multi-tuiles sont bien splittés et rendus cellule par cellule.

Preuve : tests de parité de calques/chemins verts, suite de test Builder et Library verte, Visual Gate actualisée : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png`.

Limites : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistance.

Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-96

Statut : `NS-SCENES-V1-96 — Cinematic Backdrop Depth / Z-Order Parity Polish V0` est DONE.

Demande : Karim a fourni le prompt V1-96 pour intercaler ce lot de profondeur afin d'avoir une parité z-index / depth ordering parfaite avec le rendu jeu / Map Editor (Y-sorting sur le visual bottom, foreground par layer/properties/tags, et tri des acteurs).

Decision : Option Z-Order V0 retenue : tri par visual bottom Y (tuiles/surfaces = y+1, objets = pos.y + height), layerIndex comme tie-breaker, elementX et zOrder d'origine. Heuristiques foreground pour forcer les éléments entiers dans la pass foreground si la couche, les propriétés de l'objet, ou l'élément projet possède des marqueurs de foreground. Tri Y-sorting des acteurs dans l'overlay.

Preuve : tests de tri et d'heuristiques verts, suite Builder verte (+190), suite Library verte (+21), tests map_core verts, analyse ciblée verte, et Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png`.

Limites : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistance.

Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-95 bis

Statut : `NS-SCENES-V1-95 bis — Cinematic Backdrop Preview Canvas UX Polish V0` est DONE.

Demande : Karim a demande ce polish pour rapprocher la preview cinematic des proportions attendues : moins de chrome dans l'aperçu, canvas plus grand, timeline toujours presente et lisible.

Decision : V1-95 bis ne change ni le modele cinematic ni le runtime. Le pan, la grille, les details et le reset restent locaux au Builder, avec le meme transform partage pour backdrop, foreground et placeholders acteurs.

Scope realise : chrome secondaire replie en `Vue scene`, details accessibles par toggle local, pan drag borne en tuiles, reset/recentrage local, grille masquee par defaut avec toggle, seuil preview responsive pour garder les interactions timeline utilisables.

Preuve : RED puis GREEN sur le test de canvas-first, paquet V1-95 bis vert, suite Builder complete `+188`, suite Library `+21`, tests core cinematic `+74`, analyse ciblee editor verte, `dart analyze` map_core vert, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png`. `flutter analyze` global `map_editor` reste rouge par dette preexistante Pokemon SDK hors lot.

Limites : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistence pan/zoom/grille/details, aucune mutation projet/map, aucune donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-95

Statut : `NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0` est DONE.

Demande : Karim a demande de corriger la preview trop mini-map apres V1-94/V1-94 bis, tout en gardant les elements Path Studio et donc l'eau visibles.

Decision : V1-95 ne devient pas une camera runtime. Le Builder garde `Carte entiere` par defaut et propose `Vue scene` avec zoom/reset local non persistant. Le focus est deterministe : acteur selectionne renderable, puis bounding box des acteurs renderable, puis centre map.

Scope realise : helper editor-only, controles design system, transform commun applique au backdrop background, overlay acteurs et foreground, compact layout preserve, ordre de render pass ajuste pour que Path Studio/eau ne soit plus recouvert par les tiles de fond.

Preuve : tests Builder complets verts, Library verte, tests core cibles verts, analyse ciblee editor verte, analyse core verte, Visual Gate `ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png`.

Limites : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistence zoom/framing, aucune mutation projet/map, aucune donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-94 bis

Statut : `NS-SCENES-V1-94 bis — Cinematic Path Studio Water Fidelity Fix` est DONE.

Demande : Karim a signale que les elements Path Studio, donc l'eau, manquaient dans le backdrop cinematic. Le prompt V1-95 attache a ete execute ensuite pour traiter le cadrage/zoom du backdrop.

Decision : le renderer cinematic resout maintenant le pattern Path Studio unique associe au preset de base du `PathLayer`. Si plusieurs patterns pointent vers le meme base preset, le fallback base reste volontairement conserve.

Scope realise : correctif local dans `cinematic_map_backdrop_layer_render_plan.dart`, test de regression `uses Path Studio center pattern when a path layer references its base preset`, rapport et evidence pack.

Preuve : test RED attendu `water_base` au lieu de `water_pattern`, puis test cible vert, scenario V1-94 non-regression vert, fichier `cinematic_builder_workspace_test.dart` complet vert (`+175`) et analyse ciblee sans issue.

Limites : pas de screenshot nouveau, pas de runtime, pas de Flame, pas de playback, pas de sprites acteurs.

Historique avant V1-95 : le prochain lot recommande etait `NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0`, desormais traite.

## Mise a jour V1-93

Statut : `NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract` est DONE.

Demande : Karim a demande de reparer le vrai probleme visuel restant avant de passer aux sprites acteurs : la preview Cinematic Builder doit tendre vers la composition Map Editor, pas seulement des `TileLayer` bitmap.

Decision : Option E retenue. V1-94 doit livrer un plan de rendu backdrop cinematic multi-layer dedie, avec resolver multi-catalogues au-dessus de `CinematicTilesetAssetRegistry`, en reutilisant seulement des helpers purs/extractibles du Map Editor. `MapCanvas` complet, `MapGridPainter` brut, runtime, Flame, GameState et playback restent interdits.

Scope realise : audit MapData layer semantics, rendering parity Map Editor, asset/catalog resolution, render plan contract, runtime/Flame/MapCanvas anti-scope, seuil produit fidelite et tests/Visual Gate V1-94.

Preuve : `ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md`, `ns_scenes_v1_93_evidence_pack.md`, sub-agents A-G, Gate 0 propre, recherches structurantes et checks anti-scope.

Limites : doc-only. Aucun `packages/`, test, screenshot, renderer, Selbrume, runtime/Flame/playback, MapCanvas ou image IA modifie/ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0`.

## Mise a jour V1-91

Statut : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0` est DONE.

Demande : Karim a fourni le prompt V1-91 et a demande un read model pur avant tout renderer. Le lot materialise la projection testable des acteurs sans rendu UI.

Decision : `map_core` expose `CinematicActorDisplayPreviewModel` et `buildCinematicActorDisplayPreviewModel({cinematic, project, stageMap, mapData, stageMapSourceCatalog})`. Le builder ne lit aucun fichier, ne charge aucun sprite, ne depend ni de Flutter/Flame/runtime/editor et ne simule pas la timeline.

Scope realise : inventaire `requiredActors`, bindings player/mapEntity/cinematicOnly/unbound, positions fromMapEntity/fromMovementTarget mapEntity/mapEvent, abstractPoint sans coordonnees, apparences player/Character Library/mapEntity NPC/trainer, directions actorFace statiques, actorMove ignore, render hints abstraits, diagnostics locaux et summary.

Preuve : RED attendu sur API absente, 25 tests V1-91 verts, tests non-regression `cinematic_map_backdrop_preview_model_test.dart`, `cinematic_stage_map_source_catalog_test.dart`, `cinematic_asset_test.dart`, `project_manifest_cinematics_test.dart` verts, `dart analyze` map_core sans issue et suite complete map_core verte.

Limites : aucun acteur n'est affiche, aucun renderer n'est ajoute, aucun sprite n'est charge, aucun runtime/playback/pathfinding/collision n'est touche, aucune donnee Selbrume ni image IA n'est utilisee.

Prochain lot exact recommande : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`.

Le polish scroll/visibility est repousse explicitement a `NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0`.

## Mise a jour V1-90

Statut : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract` est DONE.

Demande : Karim a fourni le prompt V1-90 et a demande explicitement sub-agents/passes, sans code produit ni rendu acteur. Le lot vient apres V1-89 parce que le decor map reel existe enfin dans le Builder.

Decision : Option C retenue. Le futur affichage statique des acteurs doit commencer par un read model pur, puis seulement ensuite un resolver editor et un renderer overlay. Le Builder ne doit pas porter directement toute la logique, et le runtime/Flame/GameState restent bannis.

Scope realise : audit actor sources/stage bindings, position/placement, Character Library/appearance, overlay/viewport, anti-runtime/playback, UX wording, diagnostics futurs, tests futurs et Visual Gate V1-91.

Preuve : rapports V1-90, Evidence Pack, sub-agents A-F, Gate 0 propre, checks anti-scope documentaires et `git diff --check`.

Limites : aucun fichier `packages/`, aucun test, aucun screenshot, aucun acteur/sprite/placeholder rendu, aucun playback, runtime, Flame, pathfinding/collision, mutation MapData/ProjectManifest ou donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.

## Mise a jour V1-89

Statut : `NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0` est DONE.

Demande : Karim a fourni le prompt V1-89 et a demande explicitement sub-agents/passes et preuve visuelle. Le lot ajoute le branchement workspace/asset resolution manquant apres V1-88 avant d'aller vers Actor Display.

Decision : la Library consomme un resolver parent de chemin tileset, charge un plan bitmap async via un loader dedie et conserve le fallback structurel avec diagnostics humains si l'asset manque. Le Builder reste read-only/editor-only ; aucun runtime ou acteur n'est lance.

Scope realise : wiring `NarrativeWorkspaceCanvas -> CinematicsLibraryWorkspace -> CinematicMapBackdropTilePlanLoader`, collecte des tilesets de `TileLayer`, diagnostics `tileMetricMismatch`/`noBitmapInstructions`, diagnostics partiels visibles, tests success/fallback/fidelity, Visual Gate 1663x926.

Preuve : rapports V1-89, screenshot PNG, tests ciblés, checks anti-scope et sub-agents A-E.

Limites : rendu encore limite aux `TileLayer`; surfaces/objets/environnement gardent le fallback structurel. Pas d'acteurs, playback, runtime, Flame, pathfinding/collision, mutation map/projet, hardcode Selbrume ou image IA.

Prochain lot exact recommande : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

## Mise a jour V1-88

Statut : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0` est DONE.

Demande : Karim a demande un renderer de vraies tiles/assets dans la preview Cinematic Builder, avec sub-agents/passes et capture visuelle. Le lot devait rester strictement editor-only/read-only.

Decision : V1-88 garde un renderer cinematic dedie au lieu de brancher `MapCanvas` ou le runtime. La Library/Builder accepte un `CinematicMapBackdropTileRenderPlan` optionnel ; le plan est produit depuis `MapData` + manifest + assets resolus, et le painter dessine uniquement les instructions bitmap valides.

Scope realise : `CinematicMapBackdropTileRenderPlan`, `CinematicTilesetAssetRegistry`, `CinematicMapBackdropTileRenderPainter`, integration panel/builder/library, fallback structurel, diagnostics, wording UX, tests widget/plan/fallback et Visual Gate.

Preuve : rapports V1-88, screenshot PNG 1663x926, tests ciblés verts, tests builder/library complets verts, analyse ciblee sans issue, `git diff --check` sans sortie.

Limites : le cable parent qui resout automatiquement les assets depuis l'etat global de l'editeur reste un lot suivant car le prompt n'autorisait pas la modification de ce niveau. Les acteurs et les placements non-tile restent volontairement exclus.

Prochain lot exact recommande a l'issue de V1-88 : `NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0`, ajoute ensuite a la demande de Karim avant Actor Display.

## Mise a jour V1-87

Statut : `NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract` est DONE.

Demande : Karim a demande de cadrer le rendu reel des tiles/assets avant l'Actor Display. L'ancien prochain lot V1-87 Actor Display est donc repousse a V1-89, et V1-88 devient le renderer statique de vraie map.

Decision : le futur rendu doit rester editor-only/read-only, sans runtime ni Flame. Option E retenue : petit contrat de rendu cinematic dedie, images tileset resolues en amont par un registry/cache editor, reutilisation prudente des helpers Map Editor, jamais `MapCanvas` complet.

Scope realise : audit MapData/layers visuels, resolution tilesets/assets, Map Editor rendering, runtime anti-scope, options A-E comparees, contrat V1-88, layer ordering, fallbacks, tests futurs et Visual Gate future.

Preuve : rapport V1-87, Evidence Pack V1-87, conclusions sub-agents A-E, checks anti-scope documentaires et `git diff --check`.

Limites : doc-only ; pas de renderer, pas de vraie map affichee, pas de package modifie, pas de test, pas de screenshot, pas de runtime/Flame, pas de playback, pas d'acteurs rendus.

Prochain lot exact recommande : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

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

Prochain lot exact recommande : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0`. L'ancien `NS-SCENES-V1-80 — Cinematic Timeline Scroll / Visibility Polish V0` est deplace en backlog `NS-SCENES-V1-91`.

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

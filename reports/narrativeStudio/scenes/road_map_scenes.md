# NS-SCENES-V1 — Roadmap Scenes

## Objectif produit

Construire le futur systeme de Scenes V1 du Narrative Studio : un Scene Builder no-code capable de modeliser une sequence logique executable sous forme de graphe, sans confondre Scene, Event, Cinematic, Dialogue Yarn, StorylineStep, Fact ou World Rule.

La Scene V1 doit devenir le coeur d'orchestration entre les declencheurs de map/runtime, les dialogues, les cinematiques, les combats, les actions, les consequences, les facts, les world rules et la progression narrative.

## Etat actuel

Storylines V1/V1.1 est ferme avec limitations. Le workspace Storylines sait creer une storyline principale, des quetes annexes, des chapitres, des etapes narratives, des attachements sideQuest explicites, un graph read-only et une Structure en accordions pleine largeur.

Le systeme actuel contient deja des briques narratives legacy ou transitoires :

- `ScenarioAsset` : graphe executable generique avec scopes `globalStory` et `localEventFlow`.
- `ScriptAsset` : sequence de commandes runtime bas niveau.
- `ScriptCondition` : langage pur de conditions.
- `MapEventDefinition` : evenements de map a pages conditionnelles.
- Cutscene Studio : authoring guide compile vers `ScenarioAsset`.
- Scenario runtime : bridge MVP capable de declencher dialogue, script, message, actions, combat trainer et outcomes.

Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propre. Le principal risque est de brancher les StorylineStep sur l'ancien systeme avant de stabiliser le contrat Scene.

## Regles non negociables

- Ne pas brancher `StorylineStep.sceneLinkIds` vers l'ancien systeme tant que Scene V1 n'est pas stable.
- Ne pas faire de `ScenarioAsset.localEventFlow` le modele produit final de Scene V1 sans decision explicite.
- Ne pas confondre Scene et Cinematic.
- Ne pas faire de Yarn le moteur de progression globale.
- Ne pas exposer les flags techniques comme experience principale.
- Ne pas hardcoder Selbrume ou des scenes de reference dans le code produit.
- Ne pas creer de scene placeholder automatique depuis Storylines.
- Ne pas modifier runtime/gameplay/battle depuis les lots documentaires.

## Lots

| Lot | Statut | Objectif |
|---|---|---|
| NS-SCENES-V1-00 — Scene System Scope / Current State Audit | DONE | Audit documentaire de l'existant, definition Scene V1, frontieres produit et roadmap. |
| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | DONE | Contrat produit Scene V1 formalise : definitions Scene/Graph/Node/Edge/Port/Outcome, taxonomie nodes/edges, payloads minimaux/interdits, diagnostics et runtime intents. |
| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | DONE | Decision retenue : `SceneAsset` authoring dedie + `ProjectManifest.scenes` futur, avec `ScenarioAsset` conserve comme legacy/runtime bridge temporaire et sans migration automatique. |
| NS-SCENES-V1-03 — Scene Core Model V0 | DONE | Modele core `SceneAsset` ajoute dans `map_core` avec `SceneGraph`, `SceneGraphLayout`, nodes/edges/outcomes, `ProjectManifest.scenes`, export public et tests core/JSON/manifest. |
| NS-SCENES-V1-04 — Workspace Shell Scenes | DONE | Shell editor `Scenes` branche dans Narrative Studio, lecture read-only de `ProjectManifest.scenes`, empty state honnete, actions non supportees desactivees. |
| NS-SCENES-V1-05 — Scene Tree Panel Read-only | DONE | Arborescence read-only des scenes reelles, selection locale, resume central, header Scenes compacte, aucun graph ni mutation. |
| NS-SCENES-V1-06 — Graph Read-only Skeleton | DONE | Graph Scene V1 read-only depuis le `SceneAsset` selectionne : nodes, edges, labels, layout persiste ou layout derive non persiste. |
| NS-SCENES-V1-07 — Node Inspector Read-only | DONE | Selection locale de node dans le graph read-only, inspecteur read-only du payload et des edges entrants/sortants, sans authoring ni mutation. |
| NS-SCENES-V1-08 — Authoring Minimal Scene Draft | DONE | Creation d'une SceneAsset draft minimale depuis le workspace Scenes, ajout en memoire dans `ProjectManifest.scenes`, selection auto et graph/inspector read-only. |
| NS-SCENES-V1-09 — Scene Validation Diagnostics | DONE | Diagnostics Scene V1 purs dans `map_core` et affichage editor : erreurs/warnings de graph, layout et outcomes, sans mutation ni correction automatique. |
| NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
| NS-SCENES-V1-10-bis — Scene Builder / Runtime Roadmap Alignment | DONE | Roadmap reconcilee : priorite au Scene Builder Blueprint-like, runtime plan conserve mais decale apres authoring graph minimal. |
| NS-SCENES-V1-11 — Scene Graph Draft Node Strategy | DONE | Strategie retenue : activer seulement Condition, Merge et Fin en V0 ; garder Start unique et desactiver Yarn/Action/Battle/Cinematic/Branch tant que les refs/payloads ne sont pas honnetes. |
| NS-SCENES-V1-12 — Node Authoring V0 | DONE | Operation pure `addSceneNodeDraft` et palette editor V0 : ajout Condition / Merge / Fin en memoire, selection auto, aucun edge automatique ni fake ref. |
| NS-SCENES-V1-13 — Edge Authoring V0 | DONE | Operation pure `addSceneEdgeDraft` et UI de connexion V0 : ports explicites start.completed, condition.true/false, merge.completed, edge kind derive, mise a jour memoire sans runtime. |
| NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0 | DONE | Canvas Blueprint-like de base : grille, zoom local par boutons et pinch trackpad, pan local, deplacement de nodes, persistence memoire de `SceneGraphLayout`, edges qui suivent, sans impact runtime. |
| NS-SCENES-V1-15 — Visual Port Connection UX V0 | DONE | Ports visuels V0, drag depuis output, preview wire, highlight/snap des inputs compatibles, drop valide cree un edge via les regles V1-13, drop vide annule. |
| NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0 | DONE | Selection locale d'edge, highlight visuel, inspecteur de lien et suppression d'edge en memoire via operation pure, sans runtime ni reconnexion avancee. |
| NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review | DONE | Revue architecture/roadmap : refuser une Condition V0 textuelle magique, cadrer sources metier, Facts, World Rules et consequences avant authoring payload. |
| NS-SCENES-V1-16 — Condition Sources Contract V0 | DONE | Contrat no-code des sources de condition : sources V0 autorisees, sources reportees, mapping technique, operateurs, pickers et diagnostics, sans code ni UI. |
| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | DONE | `ConditionNode` configurable avec source structuree V0 depuis refs existantes : fact-like story flag, story step completion et event consumed, sans texte magique ni fake ref. |
| NS-SCENES-V1-18 — Fact Registry V0 | DONE | Registry authoring de Facts lisibles bool-first dans `ProjectManifest.facts`, operations pures, JSON, diagnostics refs inconnues et picker Condition prioritaire. |
| NS-SCENES-V1-19 — World Rule Contract V0 | DONE | Contrat produit/technique des World Rules V0 : registry projet future avec targets explicites, sources Fact/Step/Event, effets V0 limites et diagnostics requis. |
| NS-SCENES-V1-20 — World Rules V0 | DONE | Premier modele/authoring/validation de World Rules controlees : registry `ProjectManifest.worldRules`, operations pures, diagnostics, projection pure et apercu editor minimal. |
| NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction | DONE | Correction documentaire : inserer le checkpoint Narrative Studio obligatoire apres V1-20 et conserver V1-21 comme candidat, pas comme prochain automatique. |
| NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | DONE | Checkpoint produit post World Rules : la suite retenue est Payload Pickers V0 avant Event -> Scene, Runtime Plan, diagnostics et runtime MVP. |
| NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit | DONE | Audit documentaire des contrats publics exposes au Scene Builder par Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et outcomes avant pickers. |
| NS-SCENES-V1-21 — Linked Asset Contracts V0 | DONE | Contrats/read models publics minimaux dans `map_core` : Dialogue, Battle trainer, Cinematic scenarioBridge, snapshot agrege, diagnostics, statuts et outcomes disponibles, sans runtime ni UI picker. |
| NS-SCENES-V1-22 — Payload Pickers V0 | DONE | Ajouter des pickers/drafts honnetes pour Dialogue Yarn et Battle trainer depuis les contrats publics V1-21 ; Cinematic reste bridgeOnly/desactive, Action et Branch restent desactives. |
| NS-SCENES-V1-23 — Event to Scene Trigger Prep | DONE | Decision Event -> Scene : viser un contrat explicite page/action `startScene`, ne pas ajouter `sceneId` direct sur l'event entier, ne pas reutiliser `ScenarioAsset`, et reporter l'implementation persistante a un bis cible. |
| NS-SCENES-V1-23-bis — Event to Scene Link V0 | DONE | Lien authoring persistant `MapEventPage.sceneTarget -> Scene V1`, operations set/clear, validation/diagnostics et picker editor bornes, sans runtime Scene ni migration legacy. |
| NS-SCENES-V1-24 — Scene Runtime Plan V0 | DONE | Modele pur `SceneRuntimePlan` / intents dans `map_core`, builder `SceneAsset -> SceneRuntimePlanBuildResult`, diagnostics runtime-plan, layout ignore, sans runtime ni ScenarioAsset final. |
| NS-SCENES-V1-25 — Diagnostics / Validator Expansion | DONE | Diagnostics Scene V1 renforces : ports V0, duplicates, unreachable/cycles, refs projet Dialogue/Battle/Cinematic/Facts/World Rules et readiness Event -> Scene via SceneRuntimePlan. |
| NS-SCENES-V1-25-bis — Dialogue/Battle Ports Authoring V0 | DONE | Ports authorables Dialogue.completed et Battle.victory/defeat ajoutes aux sources de verite, diagnostics, runtime-plan preservation et canvas visual-port, sans runtime ni outcomes Yarn inventes. |
| NS-SCENES-V1-26 — Scene Runtime Executor MVP | DONE | Executor pur `map_core` pour parcourir un `SceneRuntimePlan` via callbacks condition/dialogue/battle/cinematic, trace, erreurs propres et `maxSteps`, sans branchement runtime map. |
| NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening | DONE | Review/evidence hardening de V1-26 : executor confirme pur, tests/analyze relances, fichiers executor/test reproduits integralement, aucun runtime map ni V1-27 demarre. |
| NS-SCENES-V1-27 — World Rules Map Editor Integration V0 | DONE | World Rules retrouvees depuis leurs cibles Map Editor : events, entites et dialogues PNJ, avec diagnostics, toggle enabled et creation V0 fact -> map event. |
| NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | DONE | Readiness core controlee : event neutre -> Scene V1 -> Dialogue.completed -> Battle.victory/defeat -> fins, refs Dialogue/Battle, World Rule/Facts et executor pur verifies sans Selbrume produit ni runtime map. |
| NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0 | DONE | Hook runtime map controle : `MapEventPage.sceneTarget` court-circuite message/script legacy de la meme page, verifie Scene/diagnostics/runtime-plan, puis execute via `SceneRuntimeExecutor` et callbacks limites. |
| NS-SCENES-V1-28-ter — Scene Consequence Contract Prep | DONE | Contrat documentaire : consequences explicites via futur ActionNode/Consequence V0, V0 limite a setFact/markEventConsumed, World Rules en projection, battle/dialogue outcomes fiables requis avant writes runtime. |
| NS-SCENES-V1-28-quater — Scene Consequence Model V0 | DONE | Modele authoring pur `SceneConsequence` V0 ajoute : `setFact` et `markEventConsumed`, integration typée dans ActionNode, JSON roundtrip, diagnostics refs Fact/map/event, runtime plan toujours non executable. |
| NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0 | DONE | Runtime write controle pour consequences V0 : `applyConsequence` dans le plan/executor, staging dans le hook runtime, commit atomique `setFact` / `markEventConsumed`, sans World Rule direct apply ni StorylineStep link. |
| NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0 | DONE | Adapter runtime battle awaitable : trainer battle lance via le handoff existant, resultat reel mappe vers `victory` / `defeat`, failures propres, aucune consequence Scene ecrite par l'adapter. |
| NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0 | TODO | Rendre `showDialogue` awaitable cote Scene runtime pour retourner `completed` apres la vraie fermeture du dialogue, sans outcomes Yarn inventes. |
| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP, consequence model/runtime write, battle outcome adapter, dialogue awaitable, golden slice readiness et runtime hook stabilises. |

## Prochain lot recommande

`NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0`

Raison : V1-28-sexies rend le BattleNode awaitable avec un vrai resultat runtime `victory` / `defeat`. Le dernier gros seam runtime visible reste le dialogue : `showDialogue` retourne encore `completed` immediatement et doit attendre la vraie fermeture du dialogue avant de laisser la Scene continuer.

Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0.

Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.

## Mise a jour V1-27

Statut : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0` est DONE.

Decision : V1-27 ajoute un read model pur `WorldRuleTargetContextReadModel` cote `map_core` pour filtrer les World Rules par cible explicite `mapEvent`, `mapEntity` ou `npcDialogue`, attacher les diagnostics existants et produire des labels source/effet lisibles sans `GameState`, runtime, disque ou mutation.

Editor : `EventPropertiesPanel` affiche les rules ciblant l'event selectionne, expose diagnostics et toggle enabled, et permet de creer une World Rule V0 fact -> event avec mapId/eventId auto-remplis depuis le contexte. `EntityPropertiesPanel` affiche et permet de toggler les rules ciblant l'entite et, pour les PNJ, les rules de dialogue PNJ.

Limites : pas de runtime Scene, pas d'application dynamique des World Rules au monde, pas de collision/warp dynamique, pas de StorylineStep link, pas de Event -> Scene runtime trigger, pas de donnees Selbrume, pas de creation avancee mapEntity/npcDialogue depuis l'inspector.

Tests : `cd packages/map_core && dart test test/world_rule_test.dart && dart test test/world_rule_authoring_operations_test.dart && dart test test/world_rule_diagnostics_test.dart && dart test test/world_rule_projection_test.dart && dart test test/world_rule_target_context_read_model_test.dart && dart analyze`, tests editor Event/Entity/Overview/Shell/Projection/Guardrail, analyse ciblee editor, visual gate V1-27 et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`.

## Mise a jour V1-28

Statut : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep` est DONE.

Decision : le lot ajoute un read model pur `GoldenSliceReadinessReport` cote `map_core` pour verifier une chaine controlee `MapEventPage.sceneTarget -> SceneAsset -> SceneRuntimePlan -> SceneRuntimeExecutor`, avec Dialogue.completed, Battle.victory/defeat, refs Dialogue/Battle, Facts et World Rules authoring-ready.

Preuve : la fixture neutre utilise `map_test`, `event_gate`, `scene_test_rival`, `dialogue_test_intro`, `trainer_test_rival`, `fact_test_rival_defeated` et `world_rule_test_unlock_gate`. Elle ne modifie pas `selbrume/**`, ne branche pas runtime map et n'applique aucune consequence persistante.

Limites : Dialogue Yarn reste limite a `completed`, les outcomes Yarn detailles et BranchByOutcome restent futurs, les consequences persistantes ne sont pas executees, les Facts/World Rules ne sont pas appliquees au runtime et `StorylineStep.sceneLinkIds` reste reporte.

Tests : `golden_slice_readiness_test`, diagnostics Event->Scene, Scene runtime plan, Scene runtime executor, World Rule target context, contrats linked assets, diagnostics Scene/WorldRule et `dart analyze`.

Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.

## Mise a jour V1-28-bis

Statut : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0` est DONE.

Decision : le runtime map traite explicitement `MapEventPage.sceneTarget` avant les comportements legacy de la page active. Une page avec Scene V1 ne lance donc pas automatiquement son message ou script legacy en plus. Le hook resout la Scene cible depuis `ProjectManifest.scenes`, refuse les scenes absentes ou diagnostiquees en erreur, construit un `SceneRuntimePlan`, puis execute via `SceneRuntimeExecutor` avec callbacks runtime limites.

Callbacks V0 : condition lit seulement les sources deja exposees en V0 (`factLikeStoryFlag`, `storyStepCompletion`, `consumedEvent`) depuis le `GameState` existant sans mutation ; dialogue ouvre le dialogue projet via le chemin runtime existant et retourne `completed` comme seam non awaitable ; cinematic reste bridge acknowledged ; battle reel est refuse proprement car le handoff actuel ne peut pas fournir `victory`/`defeat` de facon awaitable sans inventer le resultat.

Limites : pas de consequence persistante automatique, pas de Fact write, pas de World Rule runtime application, pas de runtime save, pas de StorylineStep link, pas de ScenarioAsset promu, pas de BranchByOutcome/Yarn outcomes detailles et pas de donnee produit.

Tests : `cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart`, analyse ciblee `map_runtime`, tests core readiness/runtime-plan/executor et `map_core` analyze.

Prochain lot exact : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep`.

## Mise a jour V1-28-ter

Statut : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep` est DONE.

Decision : les consequences persistantes Scene V1 doivent etre declarees explicitement comme effets lisibles et types, pas deduites magiquement depuis un outcome, une edge, une metadata ou une page d'event. L'option retenue est un futur ActionNode/Consequence V0 explicite dans le graphe, avec modele pur avant runtime write.

V0 recommande : `setFact(factId, true/false)` et `markEventConsumed(eventId)` comme consequences simples et persistantes. `completeStoryStep` reste reporte a cause de `StorylineStep.sceneLinkIds` et du risque de confondre progression et declencheur. Les World Rules ne sont pas appliquees directement par la Scene : elles lisent ensuite Facts, steps ou events consumed et projettent le monde.

Battle/dialogue : le runtime battle doit fournir plus tard un vrai resultat awaitable `victory/defeat`, sans hardcoder. Dialogue reste `completed` tant que Dialogue Studio ne fournit pas d'outcomes publics fiables ; `BranchByOutcome` reste reporte.

Checks : documentation-only, aucun test Dart/Flutter requis, `git diff --check` final.

Prochain lot exact : `NS-SCENES-V1-28-quater — Scene Consequence Model V0`.

## Mise a jour V1-28-quater

Statut : `NS-SCENES-V1-28-quater — Scene Consequence Model V0` est DONE.

Decision : `SceneConsequence` devient le modele authoring pur des consequences persistantes Scene V1. V0 est volontairement borne a `setFact(factId, true/false)` et `markEventConsumed(mapId, eventId)`.

Integration : `SceneActionPayload` peut porter une consequence typée tout en gardant la retrocompatibilite des anciens `actionKind` libres. Les `actionKind` legacy restent diagnostiques comme unsupported authoring et ne deviennent pas le contrat final.

Diagnostics : `diagnoseSceneAgainstProject` valide `setFact` contre `ProjectManifest.facts` et `markEventConsumed` contre les maps/events fournis. Les cibles manquantes sont des erreurs. Aucun write runtime n'est code.

Runtime : `buildSceneRuntimePlan` continue de refuser ActionNode avec `unsupportedAction`. `SceneRuntimeExecutor`, `map_runtime`, `map_editor`, `map_battle`, `map_gameplay` et `GameState` ne sont pas modifies.

Tests : `scene_consequence_model_test`, `scene_diagnostics_test`, `scene_asset_json_test`, `scene_runtime_plan_test`, `golden_slice_readiness_test`, `scene_project_diagnostics_test`, `dart analyze`.

Prochain lot exact : `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0`.

## Mise a jour V1-28-quinquies

Statut : `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0` est DONE.

Decision : les ActionNode portant une `SceneConsequence` typée deviennent compilables en intent runtime `applyConsequence`. `SceneRuntimeExecutor` appelle un callback explicite `applyConsequence` et suit uniquement le port `completed`.

Runtime : `SceneEventRuntimeHook` stage les consequences pendant l'execution puis commit seulement si la Scene se termine avec succes. Le writer runtime applique uniquement `setFact` et `markEventConsumed`, refuse les refs inconnues et retourne le `GameState` original si une consequence echoue.

Limites : aucune World Rule n'est appliquee directement, aucun StorylineStep n'est complete, aucun battle adapter n'est code, aucune donnee Selbrume n'est creee et aucun package `map_battle` / `map_gameplay` / `examples` n'est modifie.

Tests : `scene_consequence_model_test`, `scene_runtime_plan_test`, `scene_runtime_executor_test`, `scene_diagnostics_test`, `map_core dart analyze`, `scene_consequence_runtime_writer_test`, `scene_event_runtime_hook_test`, analyse ciblee `map_runtime`, recherches anti-Selbrume/anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`.

## Mise a jour V1-28-sexies

Statut : `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0` est DONE.

Decision : le callback Scene V1 `startBattle` de `PlayableMapGame` ne refuse plus le combat trainer par defaut. Il passe par `SceneBattleRuntimeOutcomeAdapter`, lance le handoff trainer battle existant, attend le `BattleOutcome` runtime reel puis retourne uniquement le port Scene `victory` ou `defeat`.

Runtime : le seam awaitable est localise dans `PlayableMapGame` avec un completer pending Scene battle. `BattleOutcomeType.victory` devient `SceneBattleRuntimeOutcomePort.victory`; `BattleOutcomeType.defeat` devient `SceneBattleRuntimeOutcomePort.defeat`. `runaway` et `captured` restent non supportes pour ce V0 et echouent proprement.

Limites : aucune modification de `map_battle`, aucun refactor du battle engine, aucune consequence Scene ecrite par l'adapter, aucune World Rule appliquee, aucun StorylineStep link, aucun BranchByOutcome et aucune donnee Selbrume.

Tests : `scene_battle_runtime_outcome_adapter_test`, `scene_event_runtime_hook_test`, core `scene_runtime_plan_test`, `scene_runtime_executor_test`, `scene_consequence_model_test`, `map_core dart analyze`, analyse ciblee `map_runtime`, recherches anti-Selbrume/anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0`.

## Decisions V1-24

- `SceneRuntimePlan`, `SceneRuntimePlanNode`, `SceneRuntimePlanIntent`, `SceneRuntimePlanEdge`, `SceneRuntimePlanDiagnostic` et `SceneRuntimePlanBuildResult` sont ajoutes dans `map_core`.
- `buildSceneRuntimePlan(SceneAsset)` compile une scene structurellement valide en intents declaratifs sans lire `ProjectManifest`, disque, Yarn, battle runtime, cinematic runtime ou Scenario runtime.
- Intents V0 supportes : `start`, `end`, `evaluateCondition`, `merge`, `showDialogue`, `startBattle`, `playCinematic`.
- `ActionNode` et `BranchByOutcomeNode` restent non executables : diagnostics runtime-plan error et `plan == null`.
- `CinematicNode` est compile comme intent declaratif avec warning `cinematicBridgeOnly`, car le contrat cinematic final reste bridge/provisoire.
- Le builder reutilise `diagnoseScene(scene)` : toute erreur Scene diagnostics bloque la compilation avec `planBuildBlockedBySceneDiagnostics`.
- Les edges logiques sont copies depuis `SceneGraph.edges` avec `fromNodeId`, `fromPortId`, `toNodeId`, `kind` et `label`; aucun edge implicite n'est cree.
- `SceneGraphLayout` est ignore : il reste editor-only et ne participe pas au plan runtime.
- Aucun `SceneRuntimeExecutor`, runtime Scene, Event -> Scene runtime trigger, `StorylineStep.sceneLinkIds`, promotion `ScenarioAsset`, fake ref/outcome ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-25 — Diagnostics / Validator Expansion`.

## Decisions V1-25

- `diagnoseScene(scene)` signale maintenant les ports V0 incompatibles, les `SceneEdge.kind` incoherents avec le port source, les doublons de lien depuis un port single-output, les ports requis manquants, les nodes non atteignables, les fins non atteignables et les cycles V0 non supportes.
- Severites retenues : ports invalides et doublons = `error` runtime-bloquant ; ports requis manquants, unreachable/cycle = `warning` authoring pour ne pas tuer les drafts ; `ActionNode` et `BranchByOutcomeNode` = `warning` authoring mais restent bloques par `buildSceneRuntimePlan`.
- `diagnoseSceneAgainstProject(scene, project)` croise maintenant la scene avec `LinkedAssetContractsSnapshot` et `ProjectManifest` pour signaler dialogue absent, trainer battle absent, Fact absent, cinematic bridge absent et source future worldState sans World Rule connue.
- `diagnoseEventSceneLinks` signale maintenant les pages qui combinent `sceneTarget` avec message/script legacy, et produit une erreur runtime-readiness si la Scene cible ne peut pas produire de `SceneRuntimePlan`.
- `buildSceneRuntimePlan(scene)` reste pur, non project-aware et continue seulement a bloquer les erreurs locales Scene plus `ActionNode` / `BranchByOutcomeNode`; aucune lecture disque, Yarn, battle runtime, map_runtime ou Scenario runtime n'est ajoutee.
- Les cas structurellement impossibles via le modele public (`fromNodeId`/`toNodeId` inconnus, payload kind incoherent, payload obligatoire absent Yarn/Battle/Cinematic) restent bloques a la construction `SceneGraph` / `SceneNode`; ils sont documentes comme deja proteges par le modele strict.
- Aucun editor surfacing nouveau n'a ete ajoute : les diagnostics existants consommeront les nouveaux codes via les listes deja branchees.
- Tests executes : `cd packages/map_core && dart test test/scene_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_project_diagnostics_test.dart`, `cd packages/map_core && dart test test/event_scene_link_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-26 — Scene Runtime Executor MVP`.

## Decisions V1-25-bis

- `yarnDialogue` expose maintenant un port authorable `completed`, mappe vers `SceneEdgeKind.defaultFlow` et reste volontairement limite a une sortie de continuation simple.
- `battle` expose maintenant deux ports authorables `victory` et `defeat`, mappes respectivement vers `SceneEdgeKind.battleVictory` et `SceneEdgeKind.battleDefeat`.
- `addSceneEdgeDraft` reutilise la source de verite des ports : `edge.kind` reste derive du port, les doublons depuis un port single-output restent refuses, les self-loops et ports inconnus restent invalides.
- `diagnoseScene(scene)` reconnait ces ports comme valides ; les sorties manquantes restent des warnings de draft, tandis que port invalide, kind incompatible et doublon restent des errors runtime-bloquantes.
- `SceneRuntimePlan` reste pur et conserve les edges Dialogue.completed / Battle.victory / Battle.defeat sans appeler Yarn, battle runtime, Flame, Scenario runtime ou disque.
- Le canvas Scene Builder affiche et connecte ces ports via le systeme visuel V1-15 existant ; les nodes Action/Cinematic/Branch restent sans sortie active dans ce lot.
- Aucun `SceneRuntimeExecutor`, runtime Scene, Event -> Scene runtime trigger, `StorylineStep.sceneLinkIds`, BranchByOutcome authoring, outcome Yarn invente, import `map_battle`, fake ref ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`, `cd packages/map_core && dart test test/scene_diagnostics_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`, `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-26 — Scene Runtime Executor MVP`.

## Decisions V1-26

- `SceneRuntimeExecutor` est ajoute dans `map_core` comme executor pur de `SceneRuntimePlan`, avec callbacks injectes pour condition, dialogue, battle et cinematic.
- L'executor ne connait pas Yarn, Battle, Cinematic runtime, Flame, `map_runtime`, `ProjectManifest`, `GameState`, `ScenarioAsset` ou disque : il suit uniquement les ports retournes par callbacks.
- Intents supportes : `start`, `end`, `evaluateCondition`, `merge`, `showDialogue`, `startBattle`, `playCinematic`.
- Ports V0 suivis : `completed`, `true`, `false`, `victory`, `defeat`.
- Resultat V0 : `completed` ou `failed`, `finalNodeId`, `sceneOutcomeId`, `errorCode`, `message` et trace deterministe.
- Erreurs runtime propres : start manquant, transition manquante, transition ambigue, cible manquante, port retourne non supporte, callback en erreur et limite de pas depassee.
- `maxSteps` protege contre les cycles sans faire d'analyse de graph dans l'executor.
- Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `StorylineStep.sceneLinkIds`, import `map_battle`, mutation `GameState`, Fact write, World Rule projection runtime, fake ref ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

## Decisions V1-26-bis

- `SceneRuntimeExecutor` V1-26 est confirme comme pur : il importe seulement `dart:async` et `scene_runtime_plan.dart`.
- L'audit confirme l'absence de `map_runtime`, `map_battle`, `map_gameplay`, Flutter, Flame, disque, Yarn parser, `ScenarioRuntimeExecutor`, `PlayableMapGame`, `GameState` et `ProjectManifest` dans l'executor.
- Les callbacks restent la seule frontiere metier : condition, dialogue, battle et cinematic retournent des ports, puis l'executor suit uniquement `currentNodeId + outputPortId`.
- La trace, les erreurs, `maxSteps`, la non-mutation de `SceneRuntimePlan` et les listes immuables sont documentes dans un Evidence Pack complet.
- Aucun test ou correctif code supplementaire n'a ete necessaire apres review ; les tests V1-26 ont ete relances.
- Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `StorylineStep.sceneLinkIds`, import `map_battle`, mutation `GameState`, Fact write, World Rule projection runtime, consequence persistante, fake ref ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

## Decisions V1-23-bis

- `MapEventPage` porte maintenant un `sceneTarget` explicite vers une `SceneAsset` reelle ; aucun `sceneId` global n'est ajoute sur `MapEventDefinition`.
- `MapEventSceneTarget(sceneId)` est serialise en JSON de facon retro-compatible : ancien JSON sans `sceneTarget` reste lisible, et `sceneTarget` null n'est pas ecrit comme objet vide.
- Les operations pures `setMapEventPageSceneTarget` et `clearMapEventPageSceneTarget` ciblent `eventId + pageNumber`, preservent message/script/condition/metadata et refusent event/page inconnus ou `sceneId` vide.
- `MapValidator` valide les refs Scene lorsque `projectDialogueContext.scenes` est disponible.
- `diagnoseEventSceneLinks` signale refs Scene inconnues, cibles vides, pages desactivees avec cible et Scene cible avec erreurs de diagnostics Scene V1.
- `EventPropertiesPanel` expose un picker Scene V1 depuis `ProjectManifest.scenes`, un bouton `Retirer Scene`, un message `Lien authoring uniquement, runtime Scene à venir.` et ne masque pas message/script legacy.
- Aucun runtime Scene, `SceneRuntimePlan`, `ScenarioAsset` promu, `StorylineStep.sceneLinkIds`, metadata magic string, fake ref ou donnee Selbrume n'est ajoute.
- Tests executes : tests core JSON/ops/validator/diagnostics, `dart analyze`, widget test `EventPropertiesPanel`, tests Scenes workspace, overview shell navigation, projection narrative, analyse ciblee editor.

Prochain lot exact : `NS-SCENES-V1-24 — Scene Runtime Plan V0`.

## Decisions V1-23

- Lot architecture/audit uniquement : aucun code Dart, widget, modele persiste, generated file, runtime, test ou fixture Selbrume n'est ajoute.
- Decision principale : le plus petit contrat honnete pour Event -> Scene doit vivre au niveau de la page/action active d'un event, sous une forme explicite `startScene` ou equivalente.
- Option A `sceneId` directement sur `MapEventDefinition` est rejetee pour V1 : trop coarse pour un event a pages conditionnelles, et trop risquee comme changement JSON/generated.
- Option B `startScene` dedie est retenue comme contrat cible : elle garde le declencheur Event distinct de la Scene, evite un script cache, et prepare le runtime futur.
- Option C read model/draft non persistant est retenue seulement comme posture de V1-23 : documenter et cadrer sans migration.
- Option D `ScenarioAsset`/legacy est rejetee : ScenarioRuntimeExecutor peut inspirer le flux, mais ne devient pas le modele produit Scene V1.
- Le futur lien devra referencer une `SceneAsset` reelle dans `ProjectManifest.scenes`, produire diagnostics refs inconnues, et refuser execution tant que la scene cible a des erreurs bloquantes.
- `StorylineStep.sceneLinkIds` reste desactive ; Event -> Scene reste prioritaire pour Selbrume.
- Checks executes : `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-23-bis — Event to Scene Link V0`.

## Decisions V1-22

- `addSceneLinkedAssetNodeDraft` ajoute un node depuis un payload deja forme et refuse les kinds hors scope, sans muter la scene originale ni generer de ref.
- `ScenesWorkspace` consomme `LinkedAssetContractsSnapshot` construit depuis le `ProjectManifest` courant, puis expose des pickers Dialogue et Battle.
- Le picker Dialogue lit `DialoguePublicContract`, affiche label, id, sourceRef, start node et diagnostics ; il cree un `SceneYarnDialoguePayload` avec `dialogueId` reel et `expectedOutcomes` vide quand le contrat ne declare aucun outcome.
- Le picker Battle lit `BattlePublicContract`, affiche battle label, trainerId/trainerLabel, kind `trainer`, outcomes `victory` / `defeat` et warning equipe vide ; il cree un `SceneBattlePayload` trainer stable.
- Cinematic reste desactive dans la palette avec raison `bridge Scenario uniquement` si un contrat bridgeOnly existe ; aucun `CinematicAsset` final n'est improvise.
- Action reste desactive avec raison `contrat futur requis`.
- BranchByOutcome reste desactive avec raison `mapping futur requis`.
- Aucun runtime, Event -> Scene, StorylineStep link, SceneRuntimePlan, Action Registry, Branch mapping, fake ref, outcome Yarn invente ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`, `cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart`, `cd packages/map_core && dart analyze`, `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`, `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`, `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`, analyse ciblee `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/scenes_workspace_shell_test.dart`.
- Commandes non bloquantes documentees : `test/ui/canvas/narrative_studio_header_test.dart` est absent ; `flutter analyze --no-fatal-infos` global echoue sur des erreurs existantes hors scope dans `pokemon_sdk_move_catalog_converter.dart`.

Prochain lot exact : `NS-SCENES-V1-23 — Event to Scene Trigger Prep`.

## Decisions V1-21

- `DialoguePublicContract` est code depuis `ProjectManifest.dialogues` : id stable, label lisible, sourceRef, defaultStartNode, start nodes disponibles vides sans parsing disque, outcomes non inventes et diagnostic `missingOutcomeContract`.
- `BattlePublicContract` est code depuis `ProjectManifest.trainers` : battleRef `trainer:<trainerId>`, label lisible, battleKind `trainer`, trainerId/trainerLabel, outcomes standards `victory` / `defeat`, warning si equipe vide, sans dependance `map_battle`.
- `CinematicPublicContract` est code uniquement comme `scenarioBridge` pour les `ScenarioAsset` marques par metadata Cutscene Studio ; statut `bridgeOnly`, output `completed`, diagnostic `legacyBridge`, aucun `CinematicAsset` final improvise.
- `LinkedAssetContractsSnapshot` agrege dialogues, battles, cinematics et producteurs d'outcomes battle, mais garde `ActionNode` et `BranchByOutcome` disabled.
- `ActionPublicContract`, `ConsequencePublicContract` et le mapping complet `OutcomeProducer -> BranchByOutcome` restent documentes/futurs ; aucune registry Action ou Consequence n'est creee.
- Aucun runtime, UI picker, Event -> Scene, StorylineStep link, migration ScenarioAsset, fake data ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart` puis `cd packages/map_core && dart analyze`.

Prochain lot exact : `NS-SCENES-V1-22 — Payload Pickers V0`.

## Decisions V1-21-prep

- Lot documentation-only : aucun code, widget, modele Dart, test, build_runner, runtime, Event -> Scene, StorylineStep link ou donnee Selbrume n'est ajoute.
- Decision principale : ne pas lancer directement `NS-SCENES-V1-21 — Payload Pickers V0`.
- Option retenue : inserer `NS-SCENES-V1-21 — Linked Asset Contracts V0`, puis deplacer `Payload Pickers V0` en V1-22.
- Principe retenu : `SceneAsset` stocke des refs stables, mais le Scene Builder doit lire un contrat public minimal des assets lies. Il ne doit pas connaitre l'implementation interne complete.
- Dialogue/Yarn : registry existante via `ProjectManifest.dialogues` et `ProjectDialogueEntry`; dialogue activable apres contrat public, mais outcomes Yarn doivent etre declares/exposes proprement avant `BranchByOutcome`.
- Cinematic/Cutscene : pas de vrai `CinematicAsset` canonique ; Cutscene Studio compile vers `ScenarioAsset`, bridge utile mais non final. `CinematicNode` reste disabled tant qu'un contrat public cinematic ou bridge explicitement borne n'existe pas.
- Battle/Trainer : `ProjectManifest.trainers`, `ProjectTrainerEntry`, battle requests runtime et outcomes `victory/defeat` donnent une base assez mure pour un contrat public trainer battle V0.
- Action/Consequence : actions encore dispersees entre `ScriptAsset`, `ScenarioRuntimeExecutor`, Facts et World Rules ; `ActionNode` reste disabled jusqu'a un contrat `ActionPublicContract` / `ConsequencePublicContract` V0.
- BranchByOutcome : reste disabled tant que les producteurs d'outcomes et mappings outcome -> edge ne sont pas modelises explicitement.
- `Event -> Scene` reste prioritaire apres que les scenes puissent pointer vers des contenus metier honnetes.
- `Scene Runtime Plan V0` reste necessaire apres contrats/payloads et Event -> Scene.
- `StorylineStep.sceneLinkIds` reste repousse apres builder, triggers, runtime MVP et golden slice stabilises.

## Decisions V1-20-checkpoint

- Le checkpoint est DONE en documentation-only : aucun code, widget, modele, runtime, build_runner ou donnee Selbrume n'est ajoute.
- Option retenue : `NS-SCENES-V1-21 — Payload Pickers V0`.
- `Scene Runtime Plan V0` est repousse en V1-23 : il reste necessaire, mais trop abstrait tant que Yarn/Cinematic/Battle/Action ne sont pas configurables avec de vraies refs.
- `Event -> Scene Trigger Prep` est place en V1-22 : Selbrume demarre depuis des Events de map, mais l'Event doit cibler une Scene metier, pas seulement un graph Start/Condition/End.
- `Diagnostics / Validator Expansion` suit les pickers et le lien Event -> Scene pour valider des refs et outcomes reels.
- `World Rules Map Editor Integration V0` reste necessaire avant le golden slice complet, mais ne doit pas passer avant la capacite a authorer les scenes metier.
- `StorylineStep to Scene Link` reste apres golden slice/runtime MVP afin de ne pas confondre progression narrative et declencheur local.

## Decisions V1-20-bis

- V1-20 reste DONE et fonctionnellement accepte : `ProjectManifest.worldRules`, `WorldRuleDefinition`, operations authoring, diagnostics, projection pure et overview minimal sont conserves.
- Le prochain lot exact est corrige en `NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint`.
- V1-21 Scene Runtime Plan V0 reste dans la roadmap comme candidat post-checkpoint, pas comme prochain automatique.
- Le checkpoint est obligatoire parce que continuer directement vers le runtime risquerait de contourner la question produit : Narrative Studio doit mener vers des situations, decisions, consequences et changements visibles du monde, pas seulement vers un moteur executable.
- L'incoherence Facts overview est notee comme polish futur, sans modification editor dans ce bis.

## Decisions V1-20

- `WorldRuleDefinition` est ajoute comme modele authoring declaratif : id, label, description, enabled, source, target, effect, priority, tags et debug technique optionnel.
- `ProjectManifest.worldRules` devient la registry canonique V0 des World Rules ; champ absent ou null => liste vide, sans migration automatique depuis predicates legacy, Step Studio ou map entities.
- Sources V0 codees : `Fact`, `StoryStep completion` et `consumed event`, avec predicates compatibles controles.
- Targets V0 codees : `mapEntity`, `npcDialogue`, `mapEvent`.
- Effets V0 codes : `entityVisible`, `entityHidden`, `npcDialogueOverride`, `eventEnabled`, `eventDisabled`, `eventHidden`.
- Les operations pures `addWorldRule`, `updateWorldRule` et `removeWorldRule` preservent le manifest original, generent des IDs stables et refusent labels vides, refs structurellement invalides et mismatches target/effect.
- `diagnoseWorldRules` signale sources/targets/effects manquants ou inconnus, predicates incompatibles, mismatches, conflits de priorite et fuites d'IDs/predicates techniques.
- `projectWorldRuleEffects` projette des effets resolus depuis `ProjectManifest` + `GameState`, sans muter `ProjectManifest`, `MapData` ou `GameState`.
- L'editor affiche un etat minimal honnete dans l'aperçu : compteur World Rules, diagnostics et premiers labels, sans authoring UI complet.
- Aucun runtime Scene, aucun Event -> Scene, aucun StorylineStep link, aucune migration ScenarioAsset et aucune donnee Selbrume ne sont ajoutes.

## Limites V1-20

- Pas d'ecran dedie d'authoring World Rules dans l'editor.
- Pas de picker map/entity/event/dialogue cote UI, seulement une integration overview minimale.
- La projection pure reste non destructive et non branchee au runtime.
- Les collisions dynamiques, warps, tiles, ambience/map state, mouvements d'entites et effets composites restent hors scope.
- Les Facts restent bool-first et la projection s'appuie sur `GameState.storyFlags` / `legacyFlagName` quand disponible.

## Tests V1-20

- `cd packages/map_core && dart test test/world_rule_test.dart`
- `cd packages/map_core && dart test test/world_rule_authoring_operations_test.dart`
- `cd packages/map_core && dart test test/project_manifest_world_rules_test.dart`
- `cd packages/map_core && dart test test/world_rule_diagnostics_test.dart`
- `cd packages/map_core && dart test test/world_rule_projection_test.dart`
- `cd packages/map_core && dart test test/project_manifest_facts_test.dart`
- `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_20_CAPTURE_SCREENSHOT=true test/ui/canvas/narrative_overview_workspace_test.dart --plain-name "NarrativeOverviewWorkspace captures V1-20 World Rules screenshot when requested"`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/narrative/application/overview/narrative_overview_read_model.dart lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart`
- Verification finale : `git diff --check`.

## Decisions V1-19

- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
- Une World Rule est une regle authoring declarative, inspectable et validable qui projette un changement visible ou actif du monde depuis une source lisible.
- Une World Rule n'est pas un script cache, une action one-shot, une condition dissimulee dans un PNJ ou un flag technique expose comme UX principale.
- Stockage futur recommande : registry projet canonique, avec targets explicites et affichage contextuel depuis Map Editor/entity inspector.
- Sources V0 recommandees : Fact Registry fact, StoryStep completed/notCompleted, consumed event ; `ScriptCondition` reste backend/legacy, pas surface produit.
- Effets V0 prioritaires : presence/visibilite d'entite, dialogue conditionnel PNJ, disponibilite simple d'event si la cible est validee.
- Effets repousses : collision dynamique, warp dynamique, deplacement d'entite, ambience/map state global et World Rule source derivee d'une autre World Rule.
- Runtime futur recommande : projection/resolution non destructive depuis `GameState`, sans muter `MapData` ou `ProjectManifest`.
- Diagnostics requis : source/target/effect manquants ou inconnus, mismatch target/effect, conflits de priorite, cycles et fuite d'IDs techniques.
- Prochain lot exact : `NS-SCENES-V1-20 — World Rules V0`.

## Limites V1-19

- Aucun modele `WorldRule` n'est cree.
- Aucun champ `ProjectManifest.worldRules` n'est ajoute.
- Aucun runtime, gameplay, editor widget ou payload Scene n'est modifie.
- Les portes/collisions/warps restent conceptuellement analyses mais non autorises comme effet V0 direct.
- Aucune donnee Selbrume n'est creee.

## Tests V1-19

- Dart analyze non requis : lot documentation-only.
- Flutter analyze non requis : lot documentation-only.
- Dart test non requis : lot documentation-only.
- Flutter test non requis : lot documentation-only.
- Verification requise : `git diff --check`.

## Decisions V1-18

- `NarrativeFactDefinition` est ajoute comme definition authoring bool-first : id stable, label lisible, description, categorie, valeur par defaut, tags et lien optionnel vers un flag legacy.
- `ProjectManifest.facts` devient le stockage canonique de la registry authoring des Facts V0.
- Les operations pures `addNarrativeFact`, `updateNarrativeFact` et `removeNarrativeFact` manipulent la registry sans muter le manifest original.
- La suppression d'un Fact reference par une condition Scene V1 est refusee explicitement.
- `SceneConditionSourceKind.fact` devient une source authorable V0 avec operateurs `isTrue` / `isFalse`.
- `diagnoseSceneAgainstProject` ajoute un controle project-aware des references Fact inconnues, sans remplacer `diagnoseScene(scene)` pour les diagnostics locaux.
- Le picker Condition privilegie les Facts lisibles de la registry ; `factLikeStoryFlag` reste un fallback technique, sans migration automatique.
- Aucun runtime, World Rule, Event -> Scene, StorylineStep link ou seed Selbrume n'est ajoute.

## Limites V1-18

- Facts V0 bool-first seulement ; pas de types number/text/enum.
- Pas encore d'ecran dedie de gestion de registry dans l'editor.
- Pas de migration automatique de `factLikeStoryFlag` vers `Fact`.
- Pas de stockage runtime nouveau : le mapping vers l'etat persistant reste a cadrer/brancher plus tard.
- Pas de World Rules codees.

## Tests V1-18

- `cd packages/map_core && dart test test/narrative_fact_test.dart test/narrative_fact_authoring_operations_test.dart test/project_manifest_facts_test.dart test/scene_diagnostics_test.dart test/scene_asset_json_test.dart`
- `cd packages/map_core && dart run build_runner build --delete-conflicting-outputs`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "authors a condition from a Fact Registry source"`
- `cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "writes V1-18 Fact Registry screenshot"`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-17

- `SceneConditionSource` devient le payload structure d'une condition V0 : `sourceKind`, `sourceId`, `operator`, `value`, `label` et `debugTechnicalLabel`.
- Sources codees en V0 : `factLikeStoryFlag`, `storyStepCompletion`, `consumedEvent`.
- Operateurs V0 : `isTrue` / `isFalse` pour les sources booleennes fact-like et consumed event ; `equals completed/notCompleted` pour story step completion.
- L'operation pure `updateSceneConditionSource` met a jour un node `condition` sans muter la scene originale et sans toucher aux nodes, edges, layout, outcomes ou metadata.
- L'editor expose un panel no-code dans l'inspecteur : choisir type de source, choisir une reference existante via picker derive, choisir l'operateur/valeur, puis appliquer.
- Les diagnostics bloquent les conditions sans source structuree, les sources futures, les operateurs invalides et les valeurs manquantes ; les labels techniques bruts restent au minimum warning.
- Aucun texte libre n'est source de verite. Aucun ID invente n'est cree.
- Prochain lot : remplacer progressivement les flags techniques fact-like par une `Fact Registry V0` lisible.

## Limites V1-17

- Pas de Fact Registry codee.
- Pas de World Rule.
- Pas de runtime Scene.
- Pas de Condition AND/OR ou expression complexe.
- Pas de sources inventory, party, dialogue outcome, battle outcome, trainer defeated dedie, script variable ou world state.
- Pas de StorylineStep link, Event -> Scene ou donnee Selbrume.

## Tests V1-17

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart test test/scene_diagnostics_test.dart`
- `cd packages/map_core && dart test test/scene_asset_json_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-16

- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
- Sources V0 autorisees : fait existant technique (`storyFlag` fact-like), step complete/non complete, event consomme/non consomme.
- Sources V0 reportees : step active, inventory/item possession, party/move state, script variables, trainer defeated dedie, dialogue outcome local, battle outcome local, world state / World Rule.
- Le contrat conceptuel retient une forme `sourceKind`, `sourceId`, `field`, `operator`, `value`, `label`, `debugTechnicalLabel`, sans creer de classe Dart dans ce lot.
- V0 = une condition simple par `ConditionNode`; pas de AND/OR libre. La composition se fait par le graph avec nodes et edges.
- Operateurs V0 : `isTrue`, `isFalse`, et `equals` limite aux statuts enumeres supportes.
- Les sources temporaires fact-like doivent etre presentees comme "faits existants techniques" et migrees/wrappees par `Fact Registry V0`.
- Les diagnostics contractuels prioritaires sont : source manquante/inconnue, operateur manquant/non supporte, valeur manquante, source future, picker requis, id technique brut.
- Prochain lot : coder seulement l'authoring des sources autorisees, avec diagnostics et refus runtime futur si erreur.

## Limites V1-16

- Pas de `FactRegistry`.
- Pas de `WorldRule`.
- Pas de modification `SceneAsset` ou `ProjectManifest`.
- Pas de Condition UI codee.
- Pas de payload picker code.
- Pas de runtime Scene.
- Pas de StorylineStep link, Event -> Scene ou donnee Selbrume.

## Tests V1-16

- Dart analyze non requis : lot documentation-only.
- Flutter analyze non requis : lot documentation-only.
- Dart test non requis : lot documentation-only.
- Flutter test non requis : lot documentation-only.
- Verification requise : `git diff --check`.

## Decisions V1-16-prep

- Le lot est documentation-only : aucun code, widget, modele, runtime, test ou fixture n'est modifie.
- `Condition Authoring V0` immediat avec label/draft textuel est rejete : il recreerait un editeur de flags techniques.
- Option retenue : hybride pragmatique. Inserer `NS-SCENES-V1-16 — Condition Sources Contract V0`, puis `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
- Les Conditions Scene V1 devront lire des sources metier explicites : Facts, StorySteps, resultats locaux de dialogue/combat, inventaire, party, map/event state, variables authoring et World State.
- Un Fact PokeMap est un fait lisible du monde, pas seulement un flag brut. V0 doit etre bool-first, mappe au runtime via `GameState.storyFlags` ou equivalent, puis evoluer vers types number/text/enum avec registry.
- Une World Rule est une regle visible/efficace du monde derivee de Facts/Steps/conditions ; elle doit etre cadree avant le golden slice Selbrume, mais ne bloque pas un Condition Authoring V0 limite aux sources existantes.
- Les actions/consequences doivent rester explicites : un SceneOutcome local ne devient Fact, Step completed ou World Rule que via une action/consequence authorisee.
- `Event -> Scene` reste prioritaire sur `StorylineStep -> Scene`; `StorylineStep.sceneLinkIds` reste repousse apres builder, triggers, runtime MVP et golden slice.

## Limites V1-16-prep

- Pas de Fact Registry codee.
- Pas de World Rule codee.
- Pas de Condition UI codee.
- Pas de nouveau payload, JSON, Freezed ou build_runner.
- Pas de runtime, Event -> Scene, StorylineStep link ou donnee Selbrume.

## Tests V1-16-prep

- Dart analyze non requis : lot documentation-only.
- Flutter analyze non requis : lot documentation-only.
- Dart test non requis : lot documentation-only.
- Flutter test non requis : lot documentation-only.
- Verification requise : `git diff --check`.

## Decisions V1-15-bis

- Operation pure ajoutee : `removeSceneEdgeDraft(SceneAsset, edgeId)`.
- L'operation refuse un edge inconnu, supprime uniquement l'edge cible, conserve les nodes, outcomes, tags, metadata, description, storylineId et chapterId.
- Les `SceneEdgeLayout` du lien supprime sont retires par necessite de validation du modele ; les layouts des autres edges et des nodes restent preserves.
- Cote editor, un edge peut etre selectionne depuis son badge canvas.
- L'edge selectionne est mis en evidence visuellement dans le canvas.
- L'inspecteur affiche `Edge ID`, source node, source port, target node, kind, label et l'action `Supprimer le lien`.
- La suppression met a jour uniquement `ProjectManifest.scenes` en memoire et reset la selection d'edge.
- La creation visuelle V1-15 reste fonctionnelle apres suppression.
- Aucun runtime, aucun StorylineStep link, aucune fake ref.

## Limites V1-15-bis

- Pas de reconnexion avancee.
- Pas de suppression de node.
- Pas de payload picker.
- Pas d'edition de condition.
- Pas de confirmation modale pour la suppression d'un lien V0.

## Tests V1-15-bis

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-15

- Ports visuels ajoutes sur les nodes V0 : input `in` sur condition/merge/end, outputs `completed`, `true`, `false` selon les ports V1-13.
- Drag depuis un output authorable cree un etat local de connexion visuelle.
- Preview wire dessine un cable temporaire qui suit le pointeur.
- Les ports d'entree compatibles sont mis en evidence ; le port le plus proche est snappe dans un rayon borne.
- Drop sur un input compatible appelle l'operation V1-13 existante via le callback editor, donc `SceneEdge.kind`, duplicate source port, self-loop et ports invalides restent valides par le core.
- Drop hors cible annule sans mutation.
- Les outputs deja utilises restent visibles mais non actifs.
- Aucun runtime, aucun StorylineStep link, aucune fake ref.

## Limites V1-15

- Pas de suppression ni reconnexion avancee.
- Pas de port visuel pour Yarn/Action/Battle/Cinematic/Branch.
- Pas d'edition de payload.
- L'ancien toolbar de connexion reste disponible comme fallback, mais la voie Blueprint-like est maintenant le drag visuel des ports.

## Tests V1-15

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-14

- Operation pure ajoutee : `updateSceneNodeLayout(SceneAsset, nodeId, x, y)`.
- L'operation met a jour ou cree uniquement le `SceneNodeLayout` du node cible.
- `SceneGraph.nodes`, `SceneGraph.edges`, `declaredOutcomes`, tags, metadata, description, storylineId et chapterId sont preserves.
- Cote editor, le canvas Scene affiche une grille tokenisee, un zoom local 50 % / 200 % par boutons et pinch trackpad, un reset 100 %, un pan local et le deplacement des nodes.
- Le zoom et le pan restent locaux et ne modifient pas `ProjectManifest`.
- Le deplacement d'un node persiste en memoire uniquement `ProjectManifest.scenes[*].layout.nodeLayouts`.
- Les edges utilisent les positions courantes des nodes et suivent donc les deplacements.
- La selection locale de node et l'inspecteur restent coherents apres drag.
- La connexion V1-13 reste disponible ; pendant le mode connexion, le drag node est desactive pour eviter les gestes ambigus.
- Aucun runtime, aucun StorylineStep link, aucune donnee Selbrume, aucune fake ref.

## Limites V1-14

- Pas encore de ports visuels connectables sur les cards.
- Pas de cable Blueprint tire a la souris ni preview line de connexion.
- Pas de suppression/reconnexion avancee.
- Pas de minimap ni auto-layout complet.
- Pas de persistence disque explicite.

## Tests V1-14

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-13

- Operation pure ajoutee : `addSceneEdgeDraft(SceneAsset, fromNodeId, fromPortId, toNodeId, label?)`.
- Source de verite pure ajoutee : `authorableSceneOutputPortsForNode` / `authorableSceneOutputPortsForKind`.
- Ports supportes V0 :
  - `start.completed` -> `SceneEdgeKind.defaultFlow` ;
  - `condition.true` -> `SceneEdgeKind.conditionTrue` ;
  - `condition.false` -> `SceneEdgeKind.conditionFalse` ;
  - `merge.completed` -> `SceneEdgeKind.defaultFlow`.
- `fromPortId` est toujours explicite et `edge.kind` est derive du port, jamais choisi librement par l'utilisateur.
- `end`, `yarnDialogue`, `action`, `battle`, `cinematic` et `branchByOutcome` ne proposent aucune sortie authorable V0.
- Les edges depuis source inconnue, vers cible inconnue, depuis port inconnu, depuis `end`, depuis node source desactive, les self-loops et le deuxieme edge sortant depuis un meme `fromNodeId/fromPortId` sont refuses.
- Les IDs d'edge sont stables : `edge_<fromNodeId>_<fromPortId>_<toNodeId>` avec suffixe numerique en collision.
- Cote editor, le mode connexion est local : selection node source -> bouton port -> clic node cible -> mise a jour en memoire de `ProjectManifest.scenes`.
- Apres creation, la selection reste sur le node source pour permettre de connecter `condition.true` puis `condition.false`.
- Aucun edge automatique, aucun drag and drop, aucune suppression/reconnexion avancee, aucun runtime.

## Limites V1-13

- Pas de layout authoring interactif.
- Pas de suppression d'edge.
- Pas de preview line pendant le mode connexion.
- Pas de ports graphiques connectables complexes.
- Pas de diagnostics `missingRequiredOutput`; ils restent pour Diagnostics Expansion.
- Pas de Yarn/Action/Battle/Cinematic/Branch authoring actif.

## Tests V1-13

- `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`
- `cd packages/map_core && dart analyze`
- `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart`
- `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart`

## Decisions V1-12

- Operation pure ajoutee : `addSceneNodeDraft(SceneAsset, kind, title?, afterNodeId?)`.
- Nodes supportes : `condition`, `merge`, `end`.
- Nodes refuses : `start`, `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome`.
- Generation d'IDs stable : `node_condition`, `node_merge`, `node_end_2`, avec suffixe numerique en collision.
- Layout initial stable : a droite du node cible si layout disponible, sinon a droite du node le plus a droite, sinon fallback par index.
- Les edges existants, declared outcomes, tags, metadata, storylineId/chapterId et description sont preserves.
- L'operation ne mute jamais la scene originale.
- Cote editor, `ProjectManifest.scenes` est remplace en memoire uniquement pour la scene cible.
- La palette affiche Condition / Merge / Fin actifs, et les autres node kinds desactives avec raison courte.
- Le node ajoute est selectionne automatiquement et l'inspector affiche ce node.
- Aucun edge automatique, aucun payload picker, aucun runtime.

## Limites V1-12

- Pas de diagnostics draft payload supplementaires ; `conditionIncomplete` reste pour V1-17.
- Pas d'edge authoring ni ports connectables.
- Pas de layout authoring interactif.
- Pas de Yarn/Action/Battle/Cinematic/Branch actif.
- Pas d'Event -> Scene ni `StorylineStep.sceneLinkIds`.

## Decisions V1-11

- Strategie retenue : `SceneAsset` reste le modele authoring canonique et peut porter certains drafts incomplets, mais seulement quand le payload est honnete et diagnostiquable.
- Option B retenue avec garde-fous : pas de modele `SceneDraft` separe en V1, pas de wizard obligatoire pour chaque node, mais pas de reference factice.
- Nodes ajoutables en V0 : `condition`, `merge`, `end`.
- Nodes desactives en V0 : `start` (unique), `yarnDialogue`, `action`, `battle`, `cinematic`, `branchByOutcome`.
- `condition` peut etre ajoute avec payload vide et diagnostic `conditionIncomplete` futur ; il expose `true` / `false`.
- `merge` peut etre ajoute avec payload vide ; il sert a rejoindre plusieurs branches et expose `completed/default`.
- `end` peut etre ajoute avec `SceneEndPayload` vide ; plusieurs fins sont autorisees.
- `yarnDialogue`, `battle`, `cinematic` attendent des pickers ou une strategie explicite de payload draft.
- `action` attend un registre/action picker ou un `actionKind` draft officiel, pas une chaine bidon.
- `branchByOutcome` attend une strategie de source outcome et de mappings, meme si le modele accepte un payload vide.
- Les diagnostics futurs devront bloquer l'execution runtime si un node draft reste incomplet.
- Le prochain lot code seulement l'ajout de nodes draft V0 et la palette correspondante.

## Limites V1-11

- Documentation-only : aucun code, widget, modele ou test.
- Aucune palette n'est codee.
- Aucune operation d'authoring n'est codee.
- Aucun diagnostic supplementaire n'est code.
- Aucun runtime, event trigger ou StorylineStep link n'est branche.

## Decisions V1-10-bis

- Option recommandee : roadmap hybride orientee Blueprint-like.
- Ne pas continuer directement vers `StorylineStep to Scene Link`.
- Ne pas faire `SceneRuntimePlan V0` immediatement si le builder ne sait toujours pas creer de graph utile.
- Inserer d'abord `Scene Graph Draft Node Strategy`, puis `Node Authoring V0`, `Edge Authoring V0`, `Layout Authoring V0`.
- Conserver `SceneRuntimePlan V0` tot dans la suite, mais apres les premiers lots d'authoring graph.
- Placer `Event -> Scene Trigger Prep` avant `StorylineStep -> Scene Link`, car Selbrume demarre surtout les scenes depuis des events de map.
- Garder `StorylineStep.sceneLinkIds` desactive jusqu'a builder + triggers + runtime MVP stabilises.
- La roadmap detaillee Blueprint-like vit aussi dans `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

## Limites V1-10-bis

- Documentation-only : aucun code, widget, modele ou runtime.
- Aucun node authoring n'est ajoute.
- Aucun event trigger n'est branche.
- Aucun seed Selbrume ni scene de reference n'est cree.

## Decisions V1-10

- Decision principale : ne pas brancher encore le runtime Scene V1.
- Prochain objet technique recommande : `SceneRuntimePlan` pur cote `map_core`, derive de `SceneAsset` + `diagnoseScene`.
- `SceneRuntimePlan` doit ignorer completement `SceneGraphLayout`.
- Les scenes avec diagnostics `error` ne doivent pas etre executables ; elles doivent produire une erreur runtime/authoring lisible.
- `ScenarioRuntimeExecutor` reste supporte comme runtime legacy et source d'inspiration, mais ne devient pas le contrat Scene V1.
- Pas de conversion automatique `SceneAsset -> ScenarioAsset` au save, ni migration destructive.
- Le mapping cible est `SceneNodeKind -> SceneRuntimeIntent`, puis un futur adapter `map_runtime` executera ces intents.
- Les outcomes locaux restent non persistants par defaut ; seule une action explicite pourra persister un Fact, flag ou StoryStep.
- Le lien `StorylineStep -> Scene` est repousse apres `SceneRuntimePlan V0`.

## Limites V1-10

- Documentation-only : aucun modele runtime code n'est cree.
- Pas de tests/analyze requis hors `git diff --check`.
- Pas de modification `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle`.
- Pas de hook runtime map/event, pas d'ouverture Yarn, pas de battle handoff Scene V1, pas de cinematic playback Scene V1.

## Decisions V1-09

- Les diagnostics Scene V1 vivent dans `map_core/lib/src/diagnostics/scene_diagnostics.dart`.
- `diagnoseScene` est pur, deterministe et ne mute jamais `SceneAsset`.
- Les diagnostics couvrent start, end, edges, layout, outcomes declares/emis et graph quasi vide.
- Les cas start/edge/layout inconnus restent surtout documentaires car les constructeurs `SceneGraph` / `SceneAsset` les refusent deja.
- Le workspace Scenes affiche les compteurs dans l'arborescence et les messages dans l'inspecteur read-only.
- Aucun bouton de correction automatique ni authoring supplementaire n'est ajoute.

## Limites V1-09

- Pas de Validator global.
- Pas de diagnostics runtime, Yarn, Battle ou Cinematic resolus.
- Pas de correction automatique.
- Pas d'edition de node, edge, payload ou layout.

## Decisions V1-08

- Le bouton `Créer une scène` ouvre un dialog minimal nom + description optionnelle.
- Le bouton est place dans la barre de l'arborescence pour garder le graph dominant.
- Le nom vide est refuse dans le dialog.
- La creation passe par `createSceneDraftInProject`, operation pure `map_core`.
- Les ids de scene sont slugifies avec prefixe `scene_` et suffixe numerique en cas de collision.
- La scene draft contient uniquement `node_start`, `node_end`, `edge_start_end`, layout start/end et aucune metadata metier.
- La mutation touche uniquement `ProjectManifest.scenes` en memoire via `EditorNotifier.applyInMemoryProjectManifest`.
- La scene creee est selectionnee, puis `node_start` est selectionne dans l'inspecteur read-only.
- Aucun authoring de node, edge, payload, layout, runtime ou Storylines n'est ajoute.

## Limites V1-08

- Pas d'edition de scene existante.
- Pas d'ajout ou edition de node/edge.
- Pas de drag and drop layout.
- Pas de persistence disque explicite.
- Pas de diagnostics Scene V1 avant V1-09.

## Decisions V1-07

- Le graph read-only accepte une selection locale de node par clic.
- Le start node est selectionne automatiquement quand il existe, sinon le premier node reel.
- La selection de node est recalculee quand la scene locale change.
- L'inspecteur read-only affiche kind, id, titre, description, payload summary et edges entrants/sortants.
- Les payloads `start`, `end`, `yarnDialogue`, `condition`, `action`, `battle`, `cinematic`, `branchByOutcome` et `merge` ont un resume dedie.
- Aucun `TextField`, bouton sauver/supprimer/dupliquer, drag and drop, runtime ou mutation `ProjectManifest` n'est ajoute.

## Limites V1-07

- Pas d'edition de node, payload, edge ou layout.
- Pas de diagnostics avances.
- Pas de resolution des references Yarn, combat ou cinematic.
- Pas de StorylineStep.sceneLink.

## Decisions V1-06

- Le placeholder `Graph — bientôt` est remplace par `SceneGraphReadOnlyView`.
- Le graph lit `scene.graph.nodes`, `scene.graph.edges` et `scene.layout.nodeLayouts`.
- Un layout persiste complet est utilise tel quel.
- Si le layout est absent ou incomplet, un layout derive deterministe est calcule en memoire et non persiste.
- Les edges sont dessines par un `CustomPainter` read-only avec couleurs injectees depuis le theme.
- Les labels d'edges viennent de `SceneEdge.label` ou du couple `kind/fromPortId`.
- Aucun node inspector, drag and drop, edition de node/edge ou runtime n'est ajoute.

## Decisions V1-06-bis

- NS-SCENES-V1-06-bis — fallback layout hardening : DONE.
- Le layout derive utilise maintenant un parcours borne avec `visited`.
- Les cycles et composants deconnectes ne peuvent plus bloquer le rendu read-only.
- Le layout persiste complet reste prioritaire et aucun `SceneAsset.layout` n'est mute.
- Le prochain lot reste `NS-SCENES-V1-07 — Node Inspector Read-only`.

## Limites V1-06

- Layout derive simple et borne, suffisant pour V1-06-bis mais pas un moteur de graph final.
- Pas de zoom/pan/minimap.
- Pas de selection de node.
- Pas de payload detaille.
- Pas d'inspecteur read-only avant V1-07.

## Decisions V1-05

- `ScenesWorkspace` devient un workspace read-only structure : header compact, panneau gauche d'arborescence, zone centrale de resume.
- La selection de scene est locale au widget et ne modifie pas `ProjectManifest`.
- Les scenes sont groupees par `storylineId` puis `chapterId` quand ces champs existent ; sinon elles restent sous `Sans storyline` / `Sans chapitre`.
- Le resume central affiche nom, description, IDs, tags, nodes, edges et outcomes declares.
- Le graph reste explicitement absent : seul un placeholder read-only annonce V1-06.
- Aucun bouton d'authoring actif n'est ajoute.

## Limites V1-05

- Pas de rendu SceneGraph.
- Pas de Scene Tree editable.
- Pas de Node Inspector.
- Pas de creation, edition, suppression, duplication ou import de scene.
- Pas de runtime Scene.
- Pas de branchement Storylines `sceneLinkIds`.

## Decisions V1-04

- Nouvelle entree `Scenes` ajoutee au mode workspace editor et a la navigation interne Narrative Studio.
- L'ancien mode `step` reste distinct et libelle `Etapes`.
- `ScenesWorkspace` affiche un shell read-only : titre, explication, metriques scenes/nodes/outcomes et empty state si `ProjectManifest.scenes` est vide.
- Les scenes affichees viennent uniquement de `ProjectManifest.scenes` via la projection narrative.
- Les actions `Creer une scene` et `Builder` sont desactivees et honnetes.
- Aucun seed, aucune scene de demonstration et aucune donnee Selbrume ne sont crees.
- Le panneau droit est volontairement absent pour le mode `Scenes` en V1-04.

## Limites V1-04

- Pas de Scene Tree Panel complet.
- Pas de SceneGraph read-only.
- Pas de Node Inspector.
- Pas de creation, edition, suppression ou duplication de scene.
- Pas de runtime Scene.
- Pas de branchement Storylines `sceneLinkIds`.
- `flutter analyze --no-fatal-infos` global reste bloque par une dette preexistante hors Scenes dans `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`; l'analyse ciblee du lot passe.

## Decisions V1-03

- `SceneAsset` est le modele authoring Scene V1 dedie.
- `SceneGraph` contient `startNodeId`, nodes et edges ; il ne contient pas le layout.
- `SceneGraphLayout` est separe et editor-only : node layouts et edge layouts peuvent etre ignores par le runtime.
- `SceneNodeKind` couvre `start`, `end`, `yarnDialogue`, `condition`, `action`, `battle`, `cinematic`, `branchByOutcome`, `merge`.
- `SceneEdge` porte un `fromPortId` explicite ; le kind JSON `default` est expose via l'enum Dart `defaultFlow` pour eviter le mot-cle Dart.
- Les payloads de nodes sont types ; aucun `Map<String, dynamic>` global ne porte la logique.
- `ProjectManifest.scenes` est ajoute sans supprimer ni migrer `ProjectManifest.scenarios`.
- `map_core.dart` exporte `scene_asset.dart`.

## Limites V1-03

- Aucun workspace UI Scenes.
- Aucun runtime Scene.
- Aucun adapter `SceneAsset -> ScenarioAsset` ou `ScenarioAsset -> SceneAsset`.
- Aucun diagnostic avance de graph.
- Aucun authoring operation.
- Aucun seed Selbrume ni scene de demonstration.
- Aucun branchement `StorylineStep.sceneLinkIds`.

## Decisions V1-02

- Option retenue : `SceneAsset` authoring dedie + `ScenarioAsset` runtime bridge temporaire.
- Futur storage canonique : `ProjectManifest.scenes`, absent/null compatible vers `[]`.
- `ProjectManifest.scenarios` reste supporte comme legacy ; aucune suppression.
- Aucune migration automatique `ScenarioAsset -> SceneAsset`.
- Layout persiste dans un `SceneGraphLayout` separe du graph logique ; runtime ignore le layout.
- IDs stables : jamais derives du nom utilisateur, du texte Yarn, de la position visuelle ou de Selbrume.
- Read models separes : authoring model, editor read model, diagnostics, runtime executable model.

## Limites V1-02

- Aucun `SceneAsset` code.
- Aucun `ProjectManifest.scenes` code.
- Aucun codec JSON.
- Aucun build_runner.
- Aucun workspace UI.
- Aucun runtime Scene.
- Aucun sceneLink Storylines.

## Decisions V1-01

- Scene V1 = graph d'orchestration, pas Storyline, Event, Cinematic, Yarn, Fact ou World Rule.
- `YarnDialogueNode` est le node dialogue V1 unique ; pas de `DialogueNode` generique tant qu'un autre moteur n'existe pas.
- Les transitions sont explicites : aucune logique ne vient de la proximite visuelle des nodes.
- Les conditions restent portees par `ConditionNode`, pas par des expressions libres sur edges.
- Les payloads doivent etre types ; `metadata` ne doit porter aucune logique critique.
- Les positions de nodes sont necessaires a l'editor, mais le runtime ne doit pas dependre du layout.
- Aucun modele Dart, storage, widget, runtime, fixture Selbrume ou sceneLink n'a ete cree.

## Limites V1-01

- Storage final non tranche.
- `SceneAsset` non cree.
- `ProjectManifest.scenes` non ajoute.
- Compatibilite `ScenarioAsset` non tranchee.
- Scene Builder UI non demarre.
- StorylineStep -> Scene non branche.

## Dependances

- Storylines V1/V1.1 ferme avec limitations.
- `ProjectManifest.storylines` existant et stable.
- `ScenarioAsset`, `ScriptAsset`, `ScriptCondition`, `MapEventDefinition` audites comme legacy/adaptables.
- Runtime scenario/script/cutscene audite a haut niveau.
- Decision storage Scene V1 tranchee dans V1-02 et modele core pose dans V1-03.

## Non-objectifs globaux

- Pas de runtime complet dans V1-00 a V1-08.
- Pas de branchement `StorylineStep -> Scene` avant V1-10.
- Pas de validation narrative globale avant un lot dedie.
- Pas de facts/world rules productises avant contrat dedie.
- Pas de cinematique lineaire refondue dans le meme lot que SceneGraph.
- Pas de hardcode de Selbrume dans l'UI produit.

## Decisions canoniques

- Storylines V1/V1.1 est ferme avec limitations et ne doit pas etre rouvert par NS-SCENES-V1-00.
- `StorylineStep.sceneLinkIds` reste desactive/honnete cote UI tant que Scene V1 n'est pas stable.
- Aucun lien avec l'ancien systeme de scene/scenario ne doit etre branche avant Scene V1 stable.
- Scene V1 est un graph d'orchestration.
- Cinematic V1 doit rester une sequence visuelle lineaire.
- Dialogue Yarn porte le texte et les choix de dialogue, puis produit des outcomes lisibles.
- Event porte le declencheur local/runtime.
- Fact porte l'etat du monde persistant lisible par l'auteur.
- World Rule porte les changements visibles/actifs du monde selon facts, steps ou conditions.

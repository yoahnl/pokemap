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
| NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0 | DONE | Adapter runtime dialogue awaitable : DialogueNode ouvre le dialogue existant, attend la fermeture reelle de l'overlay, retourne seulement `completed`, failures propres, aucune consequence Scene ecrite par l'adapter. |
| NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0 | DONE | Smoke runtime neutre prouve : Event -> Scene -> Dialogue awaitable pending/completed -> Battle victory/defeat awaitable -> consequences stagees puis commit atomique GameState. |
| NS-SCENES-V1-29 — StorylineStep to Scene Link | DONE | `StorylineStep.sceneLinkIds` rendu utilisable comme lien authoring/progression vers des `SceneAsset` reelles : operations pures, diagnostics refs, read model et UI Storylines, sans runtime trigger ni remplacement Event -> Scene. |
| NS-SCENES-V1-30 — Scene Node Payload Editing V0 | DONE | Edition en inspecteur des payloads Dialogue Yarn et Battle trainer depuis les contrats publics reels : operations pures, pickers honnetes, `ProjectManifest.scenes` mis a jour en memoire, sans runtime ni fake refs. |
| NS-SCENES-V1-30-bis — Scene Node Deletion UX V0 | DONE | Suppression controlee des nodes non-start depuis l'inspecteur : node + edges entrants/sortants + layouts associes retires, Start et dernier End proteges, confirmation destructive, sans runtime ni reconnexion automatique. |
| NS-SCENES-V1-31 — Scene Consequence Authoring UI V0 | DONE | Authoring no-code des ActionNode/Consequences V0 : creation depuis vrais Facts/events, edition inspecteur `setFact` et `markEventConsumed`, port `completed` connectable, sans runtime ni fake refs. |
| NS-SCENES-V1-31-bis — Scene Consequence Runtime Evidence Sweep | DONE | Evidence sweep post V1-31 : runtime-plan, executor, hook runtime, writer consequences et golden smoke relances ; V1-31 confirme sans feature ni modification runtime. |
| NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint | DONE | Checkpoint beta : Scene V1 est prete pour une beta controlee authoring/smoke, mais pas encore pour golden-slice jouable complet ; prochain verrou retenu = persistance runtime des etats narratifs ecrits par Scene. |
| NS-SCENES-V1-33 — Runtime State Persistence Gate V0 | DONE | Gate persistence runtime : les consequences Scene V1 `setFact` et `markEventConsumed` ecrites par `SceneEventRuntimeHook` survivent au save/reload et restent lisibles par Conditions Scene et World Rules en projection pure. |
| NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0 | DONE | Hook runtime borne : World Rules projetees depuis `GameState` pilotent presence PNJ, dialogue override et disponibilite d'events sans muter `GameState`, `ProjectManifest` ou `MapData`. |
| NS-SCENES-V1-35 — Facts & World Rules Manager UI V0 | DONE | Manager no-code centralise : Facts et Regles du monde actifs depuis Narrative Studio, creation/edition/suppression bornee, pickers reels, usages/diagnostics visibles, overview aligne. |
| NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision | DONE | Decision canonique : Cinematic V1 devient un futur `CinematicAsset` lineaire dedie ; `ScenarioAsset`/Cutscene Studio restent bridge legacy explicite, jamais modele final implicite. |
| NS-SCENES-V1-37 — CinematicAsset Core Model V0 | DONE | Modele core `CinematicAsset` dedie, timeline lineaire V0, `ProjectManifest.cinematics`, operations authoring, diagnostics, contrats publics canoniques + bridge scenarioBridge legacy, tests/analyze core. |
| NS-SCENES-V1-38 — Cinematics Library V0 | DONE | Library Narrative Studio pour `CinematicAsset` canoniques : read model pur, liste/selection, metadata authoring, diagnostics/usages, bridge legacy explicite et overview aligne, sans Builder V2 ni runtime cinematic. |
| NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0 | DONE | Scene Builder peut ajouter/editer un `CinematicNode` via picker `CinematicAsset` canonique, exposer/connecter `cinematic.completed`, afficher details/diagnostics et signaler les bridges legacy sans les promouvoir. |
| NS-SCENES-V1-40 — Cinematic Runtime Adapter V0 | DONE | Runtime Scene V1 : `playCinematic(cinematicId)` resout un `CinematicAsset` canonique, passe par un adapter awaitable/player V0, attend la completion reelle, retourne `completed`, preserve les bridges legacy explicites et bloque les refs inconnues sans commit partiel. |
| NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract | DONE | Lot documentaire : contrat strict du futur Builder V0 comme assembleur no-code de sequences moteur simples, lineaires et sandboxees, plus contrat Runtime Playback V0/V1 borne, sans Builder code, sans timeline editor, sans playback visuel et sans effet gameplay depuis Cinematic. |
| NS-SCENES-V1-42 — Cinematic Builder V0 Shell | DONE | Shell editor read-only ouvert depuis la Cinematics Library pour les `CinematicAsset` canoniques : header, palette verrouillee, apercu sandbox, deroule et inspecteur placeholders, bridges legacy exclus du Builder canonique, visual gate et tests widget. |
| NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0 | DONE | Le Builder liste les steps existants dans l'ordre, permet une selection locale non persistante et affiche un inspecteur detaille lecture seule avec diagnostics contextualises, sans mutation de timeline ni changement core/runtime. |
| NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0 | DONE | Le Builder peut ajouter un bloc brouillon marker borne, l'inspecter en lecture seule et supprimer uniquement ce brouillon via operations pures `ProjectManifest.cinematics`, sans effet runtime ni vrai bloc metier. |
| NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0 | DONE | Premiers vrais blocs Cinematic Builder V0 : Attente, Fondu et Camera basique authoring-owned, edition par presets/modes bornes, suppression protegee, sans runtime ni editeur de montage complet. |
| NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0 | DONE | References acteur requises et bloc Orientation acteur V0 : ajout d'acteurs requis, bloc `actorFace` authoring-owned, picker acteur/direction, diagnostics acteur inconnu, sans mouvement ni runtime. |
| NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract | DONE | Lot documentaire : contrat spatial/temporel/timeline du futur `actorMove` V0, options de cible comparees, diagnostics cadres, sans code produit ni package modifie. |
| NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0 | DONE | Timeline par pistes derivees : read model pur `CinematicTimelineLaneReadModel`, lanes Camera/Acteurs/Dialogue/FX/Audio/Transitions/Temps/Autres, selection locale depuis lanes, Visual Gate, sans persistance de lane ni runtime. |
| NS-SCENES-V1-49 — Cinematic Actor Movement Block V0 | DONE | Bloc `actorMove` authorable V0 : cibles authoring stables, picker acteur/cible, presets duree, marche/course, pathMode direct verrouille, lane acteur derivee, diagnostics, Visual Gate, sans pathfinding ni runtime. |
| NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0 | DONE | Polish UX actorMove V0 : labels/description de cibles editables, suppression cible inutilisee, protection cible utilisee, titres actorMove derives, inspecteur/pickers/timeline plus lisibles, Visual Gate, sans time axis, bar layout, pathfinding ni runtime. |
| NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0 | DONE | Timeline lue comme projection temporelle derivee : durees visuelles explicites/fallback, ticks, pistes, barres proportionnelles, capture 1663x926 alignee sur la reference, sans drag/drop, playhead, runtime ni persistance start/end. |
| NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0 | DONE | Aiguille de selection derivee du bloc selectionne : curseur vertical aligne sur `startMs`, badge `Selection`, capture 1663x926, sans seek, scrubber, drag/drop, transport fonctionnel, runtime ni persistance cursor/playhead. |
| NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0 | DONE | Boutons Reset / Play / Stop placeholders disabled sous la timeline, capture 1663x926, sans playback, timer, seek, scrubber, preview runtime ni mutation projet. V1-56 les rend icon-only pour respecter les proportions finales. |
| NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0 | DONE | Timeline densifiee et plus lisible : lanes 28px, axe compact, barres 22px, empty states courts, controles transport medium, metadata strip allegee, capture 1663x926, sans nouveau pouvoir runtime/editor. |
| NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0 | DONE | Details inline au survol des barres : label no-code, type, piste, debut, duree et infos metier utiles, highlight doux, semantics, capture 1663x926, sans selection auto, seek, playback, drag/drop, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0 | DONE | Correctif demande par Karim : barres temporelles basees sur `startMs`/`visualDurationMs`, origine X commune ticks/barres/curseur, colonne pistes lisible a 128 px, labels complets sans meta parasite, rangées 48 px, barres 36 px, chrome timeline compacte et ratio preview/timeline corrige, capture 1663x926, sans seek, playback, drag/drop, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0 | DONE | Navigation clavier locale de la timeline : ArrowRight/ArrowLeft/Home/End selectionnent les blocs par `stepIndex`, initialisent la selection quand elle est vide, gardent curseur/preview/inspecteur synchronises, focus borne au panneau timeline, TextField proteges, capture 1663x926, sans seek, playback, scrubber, drag/drop, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract | DONE | Lot documentaire : contrat ArrowUp/ArrowDown retenu avant implementation. Option B recommandee : chercher la prochaine lane non vide au-dessus/dessous, choisir le bloc au `centerMs` le plus proche, ignorer les lanes vides, garder la selection aux bords, definir le cas sans selection, tie-breaks et tests futurs, sans code produit, package, runtime, playback, seek, drag/drop, resize, reorder ni mutation. |
| NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0 | DONE | ArrowUp/ArrowDown implementes selon Option B : prochaine lane non vide, cible par proximite `centerMs`, tie-break distance puis `stepIndex`, lanes vides ignorees, bords stables, cas sans selection et timeline vide traites, TextFields proteges, curseur/preview/inspecteur synchronises, Visual Gate 1663x926, sans playback, seek, drag/drop, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0 | DONE | Aide clavier compacte de timeline : le long badge est remplace par `Aide clavier`, panneau local toggle click expliquant `← / →`, `↑ / ↓`, Home et End, mention selection-only, selection/curseur/inspecteur preserves, Visual Gate 1663x926, sans playback, seek, scrubber, mouse playhead, drag/drop, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract | DONE | Lot documentaire : contrat futur `Mouse Time Probe` local type Final Cut, separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps avec scroll/clamp/snap, tests V1-62 listes, sans code produit, package, test, screenshot, image IA, playback, seek runtime, scrub actif, drag de blocs, runtime ni mutation. |
| NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0 | DONE | Repere temporel souris local implemente : click/drag axe ou fond timeline, conversion X -> temps avec origine V1-56 et scroll horizontal, clamp `0..totalDurationMs`, badge `Repere`, preview sandbox informative, clear sur selection bloc/clavier, non-mutation, Visual Gate 1663x926, sans playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, runtime ni mutation. |
| NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0 | DONE | Lot documentaire : Option E retenue pour le futur snap du probe, cibles `0 ms`, `totalDurationMs`, `block.startMs`, `block.endMs`, seuil `8 px`, click/drag/release cadres, edge cases bords/scroll/fallback/blocs proches et tests V1-64 definis, sans code produit, package, screenshot, snap actif, playback, seek runtime, drag de blocs, runtime ni mutation. |
| NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0 | DONE | Snap local du repere souris implemente : cibles `0 ms`, `totalDurationMs`, `block.startMs`, `block.endMs`, seuil `8 px`, badge `Repere : <temps> · <hint>`, click/drag/release, scroll horizontal, non-mutation, Visual Gate 1663x926, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
| NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0 | DONE | Controle explicite `Effacer le repère` visible seulement quand un probe local existe, micro-explication `Repère local : inspection uniquement.`, clear de `timelineProbeTimeMs`/`timelineProbeSnapHint`, retour au curseur `Selection` ou etat vide, Escape local timeline, TextFields proteges, transports disabled preserves, Visual Gate, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
| NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0 | DONE | Aide locale `Aide repère` visible seulement avec un repere actif, panneau court expliquant Selection/Repere/Alignement/Preview, coexistence aide clavier, clear/Escape preserves, Visual Gate, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
| NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract | DONE | Lot documentaire demande par Karim : contrat d'edition de `durationMs`, blocs authoring-owned editables, min/max, relation avec `startMs/endMs` derives, clear du probe apres modification, et trajectoire inspecteur V1-68 puis resize droit V1-69, sans code produit ni package modifie. |
| NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0 | DONE | Edition no-code de `durationMs` depuis l'inspecteur pour `wait`, `fade`, `camera`, `actorFace` et `actorMove`, avec validation core min/max, champ numerique, presets courts, +/-100 ms, recalcul layout derive, clear du probe apres acceptation, Visual Gate, sans resize, playback ni timeline libre. |
| NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0 | DONE | Handle droit uniquement sur les barres editables `wait`, `fade`, `camera`, `actorFace` et `actorMove`, visible sur selection, resize souris de `durationMs` via validations V1-68, quantification 100 ms, clamp min/max, clear probe, `selectedStepId` preserve, blocs suivants recalcules par layout derive, Visual Gate, sans drag de bloc, bord gauche, lane/reorder, playback, timeline libre ni `startMs/endMs` persistants. |
| NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0 | DONE | Messages d'erreur, bornes min/max, pas 100 ms, feedback clamp resize, explication blocs non editables et diagnostics duree consolides, sans elargir le modele temporel. |
| NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract | DONE | Contrat documentaire du futur contexte stage : option hybride retenue, mapId/backdropMode, actor bindings, positions initiales, targets map-aware, diagnostics futurs et roadmap post-V1-71 cadres sans code produit. |
| NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0 | DONE | Modele authoring minimal du Stage Context dans `CinematicAsset` : `CinematicAsset.mapId` reste l'unique ancre Stage Map, `stageContext` ajoute backdropMode, actorBindings, initialPlacements, movementTargetBindings, operations pures et diagnostics core, sans UI ni preview reelle. |
| NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0 | DONE | Stage Context expose dans le Cinematic Builder/Library : picker `ProjectManifest.maps`, clear map, backdrop none/projectMap, actor bindings, placements initiaux, target bindings, diagnostics stage, Visual Gate 1663x926, sans preview reelle/runtime ni `stageContext.mapId`. |
| NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0 | DONE | Panneau `Preparation preview`, statuts sandbox/incomplet/bloquant/pret, checklist no-code stage, diagnostics humains et summary Library `Preview`, sans preview reelle ni runtime. |
| NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract | DONE | Audit documentaire des vraies sources map-aware : `ProjectManifest.maps` fournit metadata/relativePath, `MapData.entities` et `MapData.events` portent les sources reelles, `EditorNotifier.loadMapSnapshotById` est le point d'entree editor non destructif recommande, Option E retenue avec contrat `CinematicStageMapSourceCatalog`, diagnostics/tests futurs cadres, sans picker actif, runtime, preview, package, test, screenshot ou donnees Selbrume. |
| NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0 | DONE | Read model pur `CinematicStageMapSourceCatalog` dans `map_core` : construit depuis `ProjectMapEntry` + `MapData`, projette entites/events reels, labels no-code, ids secondaires discrets, positionSummary secondaire, diagnostics locaux, statuses missing/unavailable/mismatch/available et capabilities `canBindActor` / `canBeMovementTarget`, avec tests core et analyze verts, sans picker actif, UI, preview reelle, runtime, pathfinding ou donnees Selbrume. |
| NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0 | DONE | Catalogue V1-76 branche au Cinematic Builder via snapshot `MapData` editor non destructive : actor binding -> vraie `mapEntity`, movement target -> vraie `mapEntity` ou vrai `mapEvent`, labels no-code, ids secondaires, readiness map-aware mise a jour, Visual Gate 1663x926, sans ID libre, JSON brut, preview reelle, runtime, playback, pathfinding ou donnees Selbrume. |
| NS-SCENES-V1-78 — Cinematic Character Library Binding Prep Contract | DONE | Lot documentaire demande par Karim : Character Library auditée, modèle `ProjectCharacterEntry` identifié, IDs stables/labels no-code/assets directionnels cadrés, options de stockage comparées, Option B recommandée avec `CinematicActorAppearanceBinding` / `stageContext.actorAppearanceBindings` futur, diagnostics/tests futurs définis, sans modèle, UI, picker, preview, runtime, package, test ou donnée Selbrume. |
| NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0 | DONE | Modele core `CinematicActorAppearanceBinding` ajoute dans `stageContext.actorAppearanceBindings`, JSON backward-compatible, operations pures upsert/remove, diagnostics actor/character binding, limite `cinematicOnly` V0, tests/analyze core verts, sans UI picker, preview réelle, runtime, pathfinding ni donnée Selbrume. |
| NS-SCENES-V1-80 — Cinematic Character Library Picker V0 | DONE | Picker no-code Character Library expose dans le Cinematic Builder pour les acteurs `cinematicOnly` : selection/clear de `ProjectCharacterEntry`, empty/broken states, messages herites player/mapEntity/unbound, readiness apparences et Visual Gate, sans preview reelle, runtime, playback, pathfinding, override player/mapEntity/unbound ou saisie libre de `characterId`. |
| NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0 | DONE | Diagnostics apparence Character Library humanises apres V1-80 : ref character cassee, actor kind incompatible, actor supprime/orphelin, Character Library vide, character incomplet, actions de correction explicites, readiness `Apparences acteurs`, summary Library et Visual Gate, sans preview reelle, runtime, playback, pathfinding, mutation Character Library ni donnee Selbrume. |
| NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract | DONE | Rapport documentaire avec sub-agents/passes specialisees : audit Stage Context/mapId/backdropMode, MapData snapshot, rendu Map Editor, anti-scope runtime/Flame, options comparees, Option E retenue, contrat backdrop preview, viewport/camera, diagnostics et tests futurs cadres, sans map affichee, preview reelle, runtime, playback, pathfinding, donnees Selbrume ni modification package V1-82. |
| NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0 | DONE | Read model pur `map_core` `CinematicMapBackdropPreviewModel` depuis `CinematicAsset.mapId`, `ProjectMapEntry` et `MapData` : statuts backdrop disabled/missing/unknown/unavailable/mismatch/tileset unavailable/available, layers visuels, diagnostics, label/size summary et viewport recommendation, avec tests/analyze core verts, sans UI, renderer, runtime, Flame, playback, pathfinding ou donnees Selbrume. |
| NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0 | DONE | Read model V1-83 branche dans le Cinematic Builder avec snapshot `MapData` editor non destructive ; renderer sandbox read-only du decor map, fallbacks humains, diagnostics, Visual Gate, tests builder/library/core et analyse ciblee verts, sans acteurs/playback/runtime/Flame/pathfinding/collision, mutation map/projet, donnees Selbrume ni image IA. |
| NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0 | DONE | Primitives visuelles pures derivees de `MapData` ajoutees au read model et rendues dans le Builder via mini painter editor-only : grille/cellules/ancres spatiales, fallback summary honnete, Visual Gate, tests core/editor/library et analyse ciblee verts, sans fake tile, runtime, Flame, playback, acteurs rendus, pathfinding/collision, donnees Selbrume ni image IA. |
| NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0 | DONE | Polish de composition demande par Karim : preview backdrop plus lisible, viewport map agrandi et proportionnel, meta/legende compactes et secondaires, grille/primitives renforcees, timeline preservee, Visual Gate 1663x926, sans tiles/assets finaux, runtime, Flame, playback, acteurs rendus, collision/pathfinding, donnees Selbrume ni image IA. |
| NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract | DONE | Lot documentaire demande par Karim : audit MapData/layers visuels, tilesets/assets, rendu Map Editor et anti-scope runtime/Flame ; Option E retenue, contrat futur renderer V1-88 defini, sans code produit, package, test, screenshot, renderer, map rendue, playback ni acteurs. |
| NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0 | DONE | Renderer bitmap editor-only read-only pour la preview du Cinematic Builder : instructions tiles derivees de `MapData`, images tileset resolues en amont, painter dedie proportionnel, diagnostics/fallbacks, Visual Gate 1663x926, tests builder/library/core et analyse ciblee verts, sans runtime, Flame, playback, acteurs rendus, pathfinding, collision, mutation projet/map, donnees Selbrume ni image IA. |
| NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | DONE | Integre le renderer bitmap V1-88 au vrai workspace editor : resolution tileset via parent/editor notifier, fallback structurel uniquement diagnostique, fidelity TileLayer durcie, Visual Gate 1663x926, sans acteurs/playback/runtime. |
| NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract | DONE | Lot documentaire demande par Karim : audit actor sources/stage bindings, positions/placements, Character Library/appearances, overlay/viewport, anti-runtime/Flame et UX ; Option C retenue, contrat futur read model actor display, diagnostics/tests/Visual Gate V1-91 cadres, sans code produit, packages, tests, screenshot, rendu acteur, runtime, playback, pathfinding/collision ni donnee Selbrume. |
| NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0 | DONE | Read model pur `map_core` `CinematicActorDisplayPreviewModel` demande par Karim : inventaire `requiredActors`, bindings player/mapEntity/cinematicOnly/unbound, positions resolues/manquantes, apparences Character Library/player/mapEntity, directions statiques, render hints abstraits, diagnostics locaux, tests/analyze core verts, sans renderer UI, sprite affiche, runtime, Flame, playback, pathfinding/collision ni donnee Selbrume. |
| NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0 | DONE | Read model V1-91 branche dans le Cinematic Builder a la demande de Karim : overlay editor-only de placeholders statiques sur le decor reel V1-89, transform viewport partage, labels courts, hints direction actorFace, diagnostics acteurs, noActors preserve en `Sans acteurs`, Visual Gate 1663x926, tests builder/library/core et analyse ciblee verts, sans playback, actorMove interpolation, runtime, Flame, pathfinding/collision ni rendu sprite final. |
| NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract | DONE | Lot documentaire demande par Karim : suspension volontaire du Sprite Resolver pour auditer la fidelite map restante apres V1-92 ; audit MapData/layers, rendu Map Editor, assets/catalogues, render plan multi-layer, anti-scope runtime/Flame/MapCanvas, tests/Visual Gate V1-94, Option E retenue, sans code produit, packages, tests, screenshot, renderer, Selbrume modifiee ni playback. |
| NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0 | DONE | Plan cinematic multi-layer editor-only/read-only ajoute au Builder/Library : terrain, paths, TileLayer background/foreground, surfaces, MapPlacedElement et generated placements environment resolus quand assets/donnees existent ; actor overlay V1-92 preserve entre passes background/foreground, diagnostics/fallbacks par famille, Visual Gate 1663x926, sans runtime, Flame, playback, MapCanvas complet, mutation projet/map ni sprites acteurs finaux. |
| NS-SCENES-V1-94 bis — Cinematic Path Studio Water Fidelity Fix | DONE | Correctif demande par Karim avant V1-95 : les `PathLayer` qui referencent un preset de base Path Studio resolvent maintenant l'unique `ProjectPathPatternPreset.basePathPresetId`, ce qui restaure l'eau/motif Path Studio dans le backdrop cinematic ; tests Builder verts, sans runtime, Flame, playback, sprites acteurs ni Selbrume. |
| NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0 | DONE | A la demande de Karim, la preview backdrop cinematic ajoute un cadrage editor-only local : mode Carte entiere preserve, mode Vue scene zoome, zoom/reset non persistants, focus acteur selectionne puis bbox acteurs puis centre map, transform partage backdrop/foreground/acteurs, eau Path Studio visible, Visual Gate, sans runtime, Flame, playback, sprites acteurs finaux ni mutation projet/map. |
| NS-SCENES-V1-95 bis — Cinematic Backdrop Preview Canvas UX Polish V0 | DONE | A la demande de Karim, la preview backdrop cinematic devient plus canvas-first : chrome secondaire replie en Vue scene, pan local drag + clamp + reset/recentrage non persistants, grille masquee par defaut avec toggle local, timeline/transports/inspector preserves, eau Path Studio et placeholders acteurs conserves, Visual Gate 1663x926, sans runtime, Flame, playback, sprites acteurs finaux ni mutation projet/map. |
| NS-SCENES-V1-96 — Cinematic Backdrop Depth / Z-Order Parity Polish V0 | DONE | A la demande de Karim, correctif Y-sorting/depth sorting deterministe pour le decor backdrop et l'overlay des acteurs placeholders : tri par visual bottom Y (pos.y + height), layerIndex comme tie-breaker, elementX et zOrder d'origine. Heuristiques foreground completes basées sur la couche (foreground/fg/roof/etc.), propriétés du placement (renderInForeground/above/foreground) et tags projet de l'element. Tri Y-sorting des acteurs statiques de l'overlay. Visual Gate, tests complets editor/library/core et analyse cibles verts, sans runtime, Flame ni playback. |
| NS-SCENES-V1-96-bis — Cinematic Backdrop Real Map Editor Ordering Investigation / Fix V0 | DONE | Enquête et alignement de la preview de décor sur l'ordre exact du Map Editor (Terrain -> Path -> TileBackground -> Surface -> PlacedBackground -> Foreground, boucle de calques inversée length - 1 down to 0). Tri intra-calque/intra-passe uniquement en tie-breaker. Support complet du rendu cell-by-cell des MapPlacedElement multi-tuiles. Visual Gate actualisée, tests complets verts sans runtime ni Flame. |
| NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract | DONE | Cadrage documentaire et design-first du futur resolver de sprites d'acteurs statiques. Définition des sources (player settings, npc/trainer mapEntity, cinematicOnly) et de la méthode de résolution de la première frame de l'animation idle. Analyse de la réutilisation de `CinematicTilesetAssetRegistry` pour le chargement d'image asynchrone hors build/paint. Identification des diagnostics et planification des tests V1-98 et Visual Gate V1-99. Aucun code produit modifie, pas de runtime, pas de Flame, pas de playback. |
| NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0 | DONE | Implémentation purement logique et synchrone du résolveur de sprites statiques avec tests unitaires de parité complets sans rendu visuel. |
| NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0 | DONE | Intégrer les sprites acteurs résolus au rendu de la preview du Cinematic Builder avec fallbacks et gestion de profondeur. |
| NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0 | DONE | Prouver la fidélité visuelle du rendu avec un vrai sprite de personnage (Timi) et des tests robustes de non-platitude et hors-limites. |
| NS-SCENES-V1-100 — Cinematic Spatial Authoring / Stage Points Prep Contract V0 | DONE | Cadrage spatial de la preview du Cinematic Builder : modèle Stage Point décorrélé de MapData/mapEntities/mapEvents, transformation click->tile avec pan/zoom, modèle UX (Option C), intégration avec placements/cibles/timeline et waypoints futurs. |
| NS-SCENES-V1-101 — Cinematic Stage Point Core Model V0 | DONE | Modèle core de Stage Point cinématique (`CinematicStagePoint`) stocké dans `CinematicStageContext.stagePoints`, sérialisation JSON backward-compatible avec ordre et description facultative, opérations pures add/update/remove, et 6 codes de diagnostics statiques (duplicate, empty ID/label, coordonnées invalides, out-of-map, point sans map). |
| NS-SCENES-V1-102 — Cinematic Preview Point Placement UI V0 | DONE | Visualiser, créer (snappé au centre), sélectionner, déplacer par drag-and-drop (avec contraintes physiques aux limites de la map), renommer et supprimer des Stage Points cinématiques dans la preview et l'inspecteur. |
| NS-SCENES-V1-102-bis — Stage Point Placement UX Discoverability / Evidence Pack Repair / Codex Rules Alignment | DONE | Rendre évidente et documentée la pose de points dans la preview cinématique, avec bouton texte clair, active mode banner overlay, empty states, Escape key deactivation et sidebar chip point list section. |
| NS-SCENES-V1-102-ter — Stage Point Placement Evidence Pack Final Closure | DONE | Clôture documentaire propre et vérifiable de V1-102 + V1-102-bis, avec rapport final conforme, Evidence Pack complet et preuves de Visual Gate par shasum. |
| NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0 | DONE | Permettre d’utiliser un Stage Point existant comme position initiale d’un acteur cinématique. |
| NS-SCENES-V1-103-bis — Actor Initial Placement Stage Point Evidence / Visual Truth Closure | DONE | Clôture documentaire, vérification de la vérité visuelle (apparence non définie, placeholder de l'acteur Timi sur Point 1, diagnostic de timeline) et validation des tests et de l'analyse statique sans modification du code produit. |
| NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0 | DONE | Permettre à une instruction cinématique `actorMove` d’utiliser un Stage Point existant comme cible de déplacement. |
| NS-SCENES-V1-104-bis — ActorMove Stage Point Target Evidence / Quality Gate Closure | DONE | Clôture documentaire, vérification de la vérité visuelle et validation des tests et de l'analyse statique sans modification du code produit. |
| NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0 | DONE | Simplification UX demandée par Karim après audit visuel : vocabulaire no-code `Repère` / `Destination`, suppression des anciens libellés visibles Stage Point/target techniques, Library et Builder alignés, Visual Gate 1663x926. |
| NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract | DONE | Cadrer le futur modèle et l’UX des trajets manuels cinématiques composés de points de passage, en continuité avec Repères, Destination et actorMove, sans code produit ni runtime. |
| NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0 | DONE | Ajouter le modèle core authoring-only des chemins manuels cinématiques stocké dans Stage Context, composé de Repères ordonnés, avec opérations pures et diagnostics, sans UI ni runtime. |
| NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0 | DONE | Dessiner le trajet de déplacement manuel dans la preview (dashed lines) et éditer/ordonner les points de passage, avec Visual Gate V1-108-ter régénérée et conforme, sans runtime/Flame/playback. |
| NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract | DONE | Cadrer le futur playback preview editor-only du Cinematic Builder, avec plan pur, source de vérité temporelle, transport, actorMove direct/manual path, diagnostics et anti-scope runtime/Flame. |
| NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0 | DONE | Implémenter dans `map_core` le plan pur de playback preview cinématique, avec timeline dérivée, frames déterministes, poses acteurs, actorMove direct/manual path, diagnostics et capabilities, sans UI, ticker, runtime ni Flame. |
| NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0 | DONE | Connecter les contrôles transport du Cinematic Builder au plan de playback preview V1-110 via un état local editor-only, avec Play/Pause/Stop/Reset, playhead de lecture et statut no-code, sans runtime, Flame, GameState ni déplacement acteur rendu. |
| NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0 | DONE | Connecter les poses `CinematicPreviewPlaybackFrame.actorPoses` au rendu preview editor-only des acteurs, avec direct/manual path visibles pendant la lecture locale, sans runtime, Flame, GameState, pathfinding, collision, scrubber/seek ni walking animation. |
| NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0 | DONE | Supprimer l’effet de déplacement par cases dans la preview playback acteur en conservant les positions sub-tile issues de `CinematicPreviewPlaybackFrame.actorPoses`, sans recalculer l’interpolation dans l’UI, sans walking animation, runtime, Flame, GameState, pathfinding ni collision. |
| NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract | DONE | Cadrer le futur système d’animation de marche preview-only des acteurs du Cinematic Builder, en distinguant mouvement, frame sprite, cadence, direction, fallback et anti-scope runtime/Flame/GameState, sans code produit. |
| NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0 | DONE | Implémenter un resolver editor-only, pur et testable, capable de choisir symboliquement une frame idle/walk/run/fallback pour les acteurs du Cinematic Builder à partir des actorPoses playback, du temps de preview, de la Character Library et des métadonnées actorMove, sans intégration renderer, screenshot, runtime, Flame ni GameState. |
| NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0 | DONE | Brancher le resolver V1-115 au rendu preview du Cinematic Builder afin que les acteurs affichent visuellement des frames idle/walk/run/fallback pendant le playback editor-only, tout en conservant le déplacement sub-tile, l’ancrage bottom-center, les fallbacks sprites et l’anti-scope runtime/Flame/GameState. |
| NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0 | DONE | Polir la cadence des frames animees a partir des poses playback et remplacer les badges contradictoires par des statuts no-code coherents pendant la lecture/pause/apercu statique, avec Visual Gate et tests de non-regression. |
| NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0 | DONE | Corriger l’isolation des destinations actorMove pour que modifier la destination d’un acteur ou d’un step ne modifie pas les destinations des autres actorMove, acteurs ou trajets manuels. |
| NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0 | DONE | Rendre les diagnostics et fallbacks de prévisualisation cinematic lisibles en no-code, avec détails compacts sur les acteurs/animations/sprites concernés, sans exposer de détails techniques ni modifier runtime, Flame, GameState ou map_core. |
| NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract | DONE | Cadrer le futur seek/scrub editor-only du playback preview, en separant strictement Selection Cursor, Mouse Time Probe et Playback Playhead, avec regles de hit-test, snapping, interaction Play/Pause/Stop/Reset, accessibilite et tests futurs, sans code produit. |

## Prochain lot exact recommande

`NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`

Raison : V1-119 a cadre le seek/scrub preview editor-only sans l'implementer. Le prochain verrou naturel est l'UI V0 de click-to-seek et drag Playback Playhead, en gardant Selection Cursor et Mouse Time Probe separes, sans demarrer runtime, Flame, GameState, pathfinding ou collision.

Ordre apres V1-102 :
1. `NS-SCENES-V1-103 — Cinematic Actor Initial Placement from Stage Points V0` (DONE)
2. `NS-SCENES-V1-103-bis — Actor Initial Placement Stage Point Evidence / Visual Truth Closure` (DONE)
3. `NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0` (DONE)
4. `NS-SCENES-V1-104-bis — ActorMove Stage Point Target Evidence / Quality Gate Closure` (DONE)
5. `NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0` (DONE)
6. `NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract` (DONE)
7. `NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0` (DONE)
8. `NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0` (DONE)
9. `NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract` (DONE documentaire)
10. `NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0` (DONE)
11. `NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0` (DONE)
12. `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` (DONE)
13. `NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0` (DONE)
14. `NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract` (DONE)
15. `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0` (DONE)
16. `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` (DONE)
17. `NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0` (DONE)
18. `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` (DONE)
19. `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0` (DONE)
20. `NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract` (DONE documentaire)
21. `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0` (recommande, non demarre)

## Mise a jour V1-119

Statut : `NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract` est DONE documentaire.

Demande : cadrer le futur click-to-seek et drag-to-scrub de la preview cinematic editor-only, sans code produit, sans package, sans screenshot et sans demarrer V1-120.

Decision : `Option C — Click-to-seek + drag Playback Playhead controle` est retenue. Clic sur axe temporel ou fond timeline vide deplacera la lecture. Drag du Playback Playhead scrubbera la preview. Clic sur une barre restera une selection de bloc et ne seekera pas.

Contrat central : `Selection Cursor` reste la selection auteur, `Mouse Time Probe` reste inspection-only, et `Playback Playhead` devient la future cible seek/scrub de la lecture preview. Le seek ne doit pas modifier `selectedStepId`, `CinematicAsset`, `ProjectManifest`, `MapData`, manual paths ou destinations actorMove.

Preuve : rapports V1-109 a V1-118 relus, rapports timeline/probe V1-51/V1-52/V1-53/V1-61 a V1-70 relus, audit code read-only de `playbackTimeMs`, `timelineProbe`, `selectedStepId`, `CinematicTimelineTimeLayoutReadModel`, snap et resize handles, Evidence Pack V1-119 cree.

Limites : aucun test Dart/Flutter, analyse package, build, screenshot ou Visual Gate n'a ete lance car le prompt V1-119 est documentaire et interdit les modifications de packages. La validation attendue est `git diff --check` et anti-scope.

Prochain lot recommande : `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-118

Statut : `NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0` est DONE.

Demande : rendre les diagnostics et fallbacks de la preview cinematic comprehensibles pour une personne non technique, notamment pendant `Animation partielle`, sans exposer `sourceRect`, `tilesetId`, `payload`, `JSON`, `actorId` ou `map_core` comme experience principale.

Decision : ajout d'un helper editor-only `CinematicPlaybackPreviewFallbackSummary` qui transforme les raisons internes du resolver walking animation et du sprite preview plan en messages no-code compacts, avec severite `info/warning/error`, maximum trois messages visibles et compteur `+N autre(s) point(s) a verifier`.

Preuve : tests helper, resolver, renderer, V1-118, V1-117, V1-117-bis, V1-116, Builder complet, Library/overlay, tests core ciblés, analyse ciblee, build macOS debug et Visual Gate V1-118 documentes dans le rapport et l'Evidence Pack.

Limites : le mapping reste borne aux diagnostics deja exposes par le resolver et le sprite preview plan. Aucun scrub/seek, runtime, Flame, GameState, pathfinding, collision, nouveau renderer ou changement `map_core` n'a ete demarre.

Suite historique : V1-119 a ete realise en documentaire ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-117-bis

Statut : `NS-SCENES-V1-117-bis — ActorMove Destination Isolation Bugfix V0` est DONE.

Demande : verifier le bug signale par Karim avant de coder, puis corriger uniquement si la preuve montre une regression reelle d'isolation des destinations actorMove.

Verdict : le bug est confirme, mais la cause racine n'etait pas une operation core qui modifie tous les steps. Le core met deja a jour par `stepId`. Le couplage venait du Builder : l'ajout de plusieurs blocs `actorMove` depuis la palette reutilisait la meme cible de mouvement globale, donc l'inspecteur modifiait le binding partage par plusieurs steps.

Correction : `_addActorMove` reutilise seulement une cible de mouvement non encore employee par un `actorMove`; si toutes les cibles existantes sont deja utilisees, le Builder cree une nouvelle destination authoring, copie le binding initial depuis la destination de reference, puis assigne cette destination dediee au nouveau step.

Preuve : test RED `V1-117-bis changing one actorMove destination keeps another actorMove destination unchanged` reproduit la regression avant correction, puis GREEN apres correction. Suites V1-117, V1-116, Builder complet, Library/overlay et analyse ciblee documentees dans le rapport et l'Evidence Pack V1-117-bis.

Limites historiques : aucun runtime, Flame, GameState, pathfinding, collision, nouvelle animation, nouveau playback ni V1-118 n'avait ete demarre pendant ce bis. `selbrume/project.json` etait deja dirty au Gate 0 et reste hors lot.

Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-117

Statut : `NS-SCENES-V1-117 — Cinematic Actor Animation Cadence / Playback Status Polish V0` est DONE.

Demande : polir la cadence d'animation et les statuts de playback de la preview cinematic, sans runtime, Flame, GameState, pathfinding, collision ni V1-118.

Decision : la cadence animee est derivee uniquement des `CinematicPreviewPlaybackFrame.actorPoses` courantes et precedentes avec une fenetre de 100 ms. Le resolver V1-115 garde son comportement historique sans hint, et consomme le hint optionnel seulement pendant un mouvement. Les anciens badges visibles "Acteurs statiques" et "Sans lecture" ont ete remplaces par `Aperçu statique`, `Lecture en cours`, `Lecture en pause`, `Animation acteur prête`, `Animation partielle` ou `Aucun acteur animé`.

Preuve : tests resolver, renderer, V1-117, V1-116, V1-113, builder complet, library/overlay, core, analyse ciblee, build macOS debug, Visual Gate `ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.png` et anti-scope documentes dans le rapport et l'Evidence Pack V1-117.

Limites historiques : les details fins de diagnostics/fallback restaient candidates pour V1-118, désormais realise ; aucun playback runtime, scrubber/seek, interpolation nouvelle, pathfinding ou collision n'a ete ajoute.

Suite historique : V1-118 a ete realise ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-116

Statut : `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` est DONE.

Demande : brancher le resolver V1-115 au rendu preview du Cinematic Builder pour afficher visuellement les frames `idle | walk | run | fallback` pendant le playback editor-only.

Decision : le builder produit un plan de sprites preview-only derive pendant la lecture locale, en remplacant uniquement le `sourceTileRect` deja resolu par la frame du resolver V1-115. Le plan de playback, les positions sub-tile, les fallbacks et le renderer restent conserves.

Preuve : tests V1-116 ciblés, Visual Gate `ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png`, tests resolver/renderer/V1-113/core, analyse ciblee, build macOS debug et anti-scope documentes dans le rapport et l'Evidence Pack V1-116.

Limites historiques : au moment de V1-116, les statuts et badges affichaient encore des libelles historiques comme "Acteurs statiques" / "Sans lecture" dans certains panneaux. Cette limite est traitee par V1-117.

Suite historique : V1-117 puis V1-118 sont realises ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-115

Statut : `NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0` est DONE.

Demande : implémenter uniquement un resolver editor-only, pur et testable, qui choisit symboliquement une frame `idle | walk | run | fallback` pour les acteurs du Cinematic Builder, sans modifier le renderer, l'overlay, le runtime, Flame ou GameState.

Decision : nouveau resolver dédié dans `map_editor`, sans import Flutter/Flame/runtime, basé sur `CinematicPreviewPlaybackFrame.actorPoses`, `playbackTimeMs`, `cinematicTimelineActorMovementModeOf(step)` et les animations Character Library.

Preuve : test resolver dédié, régressions renderer/V1-113, tests core ciblés, analyse ciblée et anti-scope vides documentés dans le rapport et l'Evidence Pack V1-115.

Limites historiques : au moment de V1-115, le résultat restait symbolique ; cette limite a ete traitee par V1-116 puis polie par V1-117.

Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-114

Statut : `NS-SCENES-V1-114 — Cinematic Actor Walking Animation Prep Contract` est DONE documentaire.

Demande : cadrer le futur système d’animation de marche preview-only après V1-113, sans coder, sans screenshot, sans Visual Gate et sans modifier `map_core`, `map_editor`, runtime, Flame ou GameState.

Decision : retenir une trajectoire prudente en deux lots. V1-115 implémente un resolver editor-only de frame `idle | walk | run | fallback` basé sur `CinematicPreviewPlaybackFrame.actorPoses`, `playbackTimeMs`, la Character Library et les métadonnées actorMove. V1-116 intégrera ensuite ce résultat au renderer/overlay.

Preuve : voir `reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md` et `reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md`.

Limites historiques : V1-114 ne codait aucune animation. V1-115 a implémenté le resolver symbolique ; le rendu frame-by-frame a ete traite par V1-116 puis poli par V1-117.

Suite historique : V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-113

Statut : `NS-SCENES-V1-113 — Cinematic Actor Playback Smooth Motion / Sub-tile Overlay Polish V0` est DONE.

Demande : Supprimer l’effet de déplacement par cases du playback acteur en conservant les coordonnées `double` issues de `CinematicPreviewPlaybackFrame.actorPoses`, sans recalculer la route ni l’interpolation dans l’UI.

Decision : `map_editor` garde `map_core` comme source de vérité du plan de playback et transmet des overrides sub-tile editor-only à l’overlay acteur. Le modèle statique reste le fallback pour les labels, sprites, diagnostics et poses sans coordonnées.

Preuve : voir `reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md` et `reports/narrativeStudio/scenes/ns_scenes_v1_113_evidence_pack.md`, avec Visual Gate `ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.png`.

Limites : aucune animation de marche n’est ajoutée ; les sprites/placeholders glissent maintenant continûment, mais la cadence de pas reste à cadrer dans V1-114.

Suite historique : V1-114, V1-115, V1-116, V1-117 et V1-118 ont ete realises ; V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-112

Statut : `NS-SCENES-V1-112 — Cinematic ActorMove Preview Playback V0` est DONE.

Demande : Connecter les poses acteur du `CinematicPreviewPlaybackFrame` au rendu preview du Cinematic Builder afin que les acteurs se déplacent visuellement pendant la lecture locale, sans recalculer l’interpolation dans l’UI, sans runtime, Flame, GameState, pathfinding ni animation de marche.

Decision : Le Builder continue de porter le temps local V1-111, appelle `playbackPlan.frameAt(playbackTimeMs)` et construit un modèle overlay dynamique depuis `actorPoses`. Le panneau de preview privilégie ce modèle dynamique pour l’acteur visible et conserve le modèle statique comme fallback/diagnostic.

Preuve : tests V1-112 ciblés `+3`, Builder complet `+214`, Library/Stage overlay `+26`, sprite renderer `+21`, régressions `map_core` `+12/+27/+4`, Visual Gate 1663x926 `ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.png` prouvée par shasum `a53f2d0e5d4538afa8c5fbcffdab7ae481dd90f191c64c4290c0b78dd31baa4d`.

Limites historiques au moment de V1-112 : aucune exécution runtime/Flame/GameState ; pas de scrubber/seek, pathfinding/collision, animation de marche ni persistance du temps. La projection entière de l’overlay a été traitée par V1-113 avec des overrides sub-tile editor-only.

## Mise a jour V1-111

Statut : `NS-SCENES-V1-111 — Cinematic Preview Playback Transport UI V0` est DONE.

Demande : Connecter les contrôles transport du Cinematic Builder au `CinematicPreviewPlaybackPlan` V1-110 via un état local editor-only, sans runtime, Flame, GameState, persistance ni déplacement acteur rendu.

Decision : Le Builder porte `playbackTimeMs` et `isPlaybackPlaying` localement via `AnimationController`, consomme `buildCinematicPreviewPlaybackPlan(...)` et `plan.frameAt(...)`, affiche Play/Pause/Stop/Reset, un Playback Playhead distinct, un temps courant et des badges no-code `Lecture en cours` / `Prévisualisation partielle`.

Preuve : Visual Gate V1-111 générée sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.png` en 1663x926, checksum `2bb8db8e7679576d49d6fa62f4688f2e12482024712f48de5214eeca7afafcba`. Tests relancés : V1-111 ciblé `+4`, Builder complet `+211`, Library/Stage overlay `+26`, core playback plan `+12`, time layout `+4`, actor display `+27`; analyses `map_core` clean et `map_editor` ciblée sortie 0 avec 37 infos non fatales `prefer_const_*`.

Limites historiques au moment de V1-111 : aucun actor overlay playback n'était branché ; aucun scrubber, seek timeline, runtime, Flame, GameState, pathfinding, collision, animation de marche ou persistance du temps n'avait été ajouté. Le branchement acteur a été traité par V1-112, puis la fluidité sub-tile par V1-113 ; la suite historique V1-114 a ete realisee, puis V1-115, V1-116, V1-117 et V1-118 ont ferme la chaîne d'animation preview actuelle. V1-119 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.

## Mise a jour V1-110

Statut : `NS-SCENES-V1-110 — Cinematic Preview Playback Plan Read Model V0` est DONE.

Demande : Implémenter dans `map_core` un plan pur et déterministe du futur playback preview cinématique, sans UI, ticker, transport actif, runtime, Flame, GameState, screenshot ni V1-111.

Decision : `CinematicPreviewPlaybackPlan` devient le contrat public consommable par les futurs lots editor. Il expose timeline dérivée, frames clampées, poses acteurs, `actorFace`, `wait`, `actorMove` direct/manual path, fade V0, caméra placeholder unsupported, diagnostics et capabilities.

Preuve : test dédié V1-110 `+12`, `dart analyze` sans issue, suite complète `map_core` `+2496`, checks anti-scope vides et aucun screenshot V1-110.

Limites : Aucun transport UI n'a été activé ; aucun playhead visuel, ticker, runtime, Flame, GameState, pathfinding, collision ou animation de marche n'a été ajouté.

## Mise a jour V1-109

Statut : `NS-SCENES-V1-109 — Cinematic Preview Playback Prep Contract` est DONE documentaire.

Demande : Cadrer le futur playback preview editor-only du Cinematic Builder sans implémenter de lecture, sans rendre les transports fonctionnels, sans runtime, sans Flame et sans V1-110.

Decision : Option C retenue : `map_core` doit produire un `CinematicPreviewPlaybackPlan` pur et déterministe ; `map_editor` ne portera plus tard que l'état local de lecture, le ticker et le rendu. Selection Cursor, Mouse Time Probe et Playback Playhead restent trois notions séparées.

Preuve : Rapport `ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`, Evidence Pack `ns_scenes_v1_109_evidence_pack.md`, roadmaps mises à jour, validation documentaire `git diff --check`.

Limites : Aucun playback codé, aucun transport actif, aucun screenshot, aucun package modifié, V1-110 non démarré.

## Mise a jour V1-108

Statut : `NS-SCENES-V1-108 — Cinematic Manual Path Drawing UI V0` est DONE.

Demande : Permettre le dessin visuel des chemins manuels (dashed lines, badges numérotés) dans l'éditeur, avec configuration des points de passage intermédiaires (ajout, suppression, réordonnement) et Visual Gate.

Decision : Implémentation du CustomPainter `CinematicManualPathPreviewOverlay` pour projeter et dessiner le trajet à l'écran. Intégration de l'éditeur latéral dans `_ActorMoveControls`. Résolution nullable propre (`cast<CinematicManualPath?>().firstWhere`) pour éviter les plantages avec les objets sentinelles.

Preuve : Visual Gate V1-108-ter régénérée sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_108_cinematic_manual_path_drawing_ui_v0.png` en 1663x926, checksum `f016199226ef426bdb8a28554d0221f130b06471af7f3246113b0853230dd1fe`. Tests demandés relancés : ciblé V1-108 `+3`, Builder complet `+207`, Library/overlay `+26`; analyse ciblée sortie 0 avec 37 infos non fatales `prefer_const_*`.

Limites : Pas de playback visuel, pas de Flame, pas de runtime.

## Mise a jour V1-107

Statut : `NS-SCENES-V1-107 — Cinematic Manual Path Core Model V0` est DONE.

Demande : Implémenter le modèle core authoring-only des chemins manuels cinématiques, stocké dans `CinematicStageContext.manualPaths`, avec sérialisation backward-compatible, opérations pures d'édition et diagnostics, sans UI ni runtime.

Decision : L'ownership est stocké côté chemin via `ownerActorMoveStepId` en se basant sur le step ID stable existant. Le mode de trajet `manual` a été ajouté. Les opérations pures d'authoring (CRUD sur les chemins et points de passage) et 12 diagnostics statiques dédiés ont été codés et testés.

Preuve : Tous les tests unitaires et d'intégration de `map_core` compilent et passent (2484 tests au total). `dart analyze` retourne zéro erreur.

Limites : Pas d'UI de dessin, pas de preview graphique, pas de runtime.

## Mise a jour V1-106

Statut : `NS-SCENES-V1-106 — Cinematic Manual Path Authoring Prep Contract` est DONE documentaire.

Demande : Cadrer le futur système de chemins manuels cinématiques sans modifier de code produit, UI, runtime, Xcode, screenshot ou Visual Gate.

Decision : Retenir un futur modèle authoring-only `CinematicManualPath` stocké dans `CinematicStageContext.manualPaths`, composé en V0 uniquement de Repères de scène ordonnés, owned par un `actorMove` en V0. La Destination finale reste séparée et portée par le mécanisme existant de Destination actorMove ; le Chemin manuel contient seulement les points de passage intermédiaires. `pathMode` reste direct par défaut et pourra être étendu vers un mode manuel en V1-107.

Preuve : Rapport principal et Evidence Pack V1-106 créés. Aucun package Dart, aucune UI, aucun runtime, aucun Xcode et aucune Visual Gate modifiés. Validation documentaire par `git diff --check`.

Limites : Pas de modèle core, pas d'opérations Dart, pas de diagnostics codés, pas d'UI de dessin, pas de playback.

## Mise a jour V1-105

Statut : `NS-SCENES-V1-105 — Cinematic Builder UX Simplification / Destination Vocabulary V0` est DONE.

Demande : Karim a demandé un lot UX de simplification avant le futur Manual Path : remplacer le vocabulaire technique visible par des termes no-code plus clairs, en particulier `Repère` pour les Stage Points et `Destination` pour les cibles de déplacement.

Decision : Le lot V1-105 anciennement prévu pour Manual Path est volontairement décalé à V1-106. V1-105 ferme maintenant l'alignement vocabulaire Builder/Library : `Ajouter un repère`, `Repère de scène`, `Position libre`, `Personnage ou objet de la map`, `Déclencheur de map`, `Destination`, `Destination du déplacement`, `Marqueur temps`, `Aucun problème` / `Tout est prêt`.

Preuve : Tests Builder, Library et overlay stage points verts, analyse ciblée `map_editor` en sortie 0 avec infos non fatales seulement, Visual Gate générée sous `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_105_cinematic_builder_ux_simplification_destination_vocabulary_v0.png`.

Limites : Pas de modèle core, pas de runtime, pas de playback, pas de Manual Path authoring démarré.

## Mise a jour V1-104 bis

Statut : `NS-SCENES-V1-104-bis — ActorMove Stage Point Target Evidence / Quality Gate Closure` est DONE.

Demande : Clôturer V1-104 proprement sans modifier le code produit.

Decision : Signature et vérification de la Visual Gate (SHA-256 Checksum : `a01124aec87923eb30257a889b4ac1348da0694cf8024dc345dcf6367cdeebcd`). Exécution et rapports de tests unitaires et widget (100% verts). Analyse statique détaillée. Justification alternative du build (tests widget complets + compilation Xcode validée).

Note : V1-104-bis est maintenu comme closure evidence de V1-104. Un scope repair a isolé les changements macOS/Xcode hors NS-SCENES. Le correctif macOS est suivi séparément par BUILD-MACOS-01.

## Mise a jour V1-104

Statut : `NS-SCENES-V1-104 — Cinematic ActorMove Target from Stage Points V0` est DONE.

Demande : Permettre à une instruction cinématique `actorMove` d’utiliser un Stage Point existant comme cible de déplacement. Rendre la transition entre types de cibles propre (sans valeur zombie `sourceId`). Afficher l'option "Point de scène" et le picker dans l'inspecteur de cible de mouvement de la sidebar.

Decision : Ajout du cas `stagePoint` dans l'enum `CinematicMovementTargetBindingKind`. Résolution des coordonnées du target binding à partir du Stage Point correspondant. Implémentation des diagnostics statiques et de readiness map-aware (`movementTargetBindingStagePointMissing`, `movementTargetBindingStagePointWithoutStageMap`, `movementTargetBindingStagePointOutOfMap`). Ajout d'une option par bouton dans l'inspecteur latéral pour sélectionner le type "Point de scène" et affichage d'un sélecteur no-code (`_StagePointSourcePicker`). Validation des transitions propres (suppression des valeurs zombies `sourceId`).

Preuve : Tous les tests unitaires et widget (y compris `cinematic_builder_workspace_test.dart` et `cinematic_authoring_operations_test.dart` avec les nouveaux tests de transitions directes) passent avec succès (100% verts). Génération de la Visual Gate avec le diagnostic sur le target résolu et absent de la liste, sauvegardée sous : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png`.

Limites : Pas d'interpolation de mouvement interactif, pas de tracé graphique de chemins.

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

Demande : Visualiser, créer (snappé au centre), sélectionner, déplacer par drag-and-drop (avec contraintes physiques aux limites de la map), renommer et supprimer des Stage Points cinématiques dans la preview et l'inspecteur, sans modifier MapData ni perturber Flame runtime.

Decision : Création du composant `CinematicStagePointPreviewOverlay` positionné dans le frame de preview du décor de fond. Conversion géométrique écran-carte correcte (correctif du décalage lié au cadrage/pan/zoom). Alignement du comportement du drag and drop en éliminant la zone de tolérance de geste de Flutter (touch slop) via la capture des coordonnées initiales globales de touch-down. Gestion de l'inspecteur latéral pour l'édition de nom et la suppression.

Preuve : Test de non-régression visual gate `captures V1-102...` passant à 100% vert, générant le snapshot de référence dans narrativeStudio/scenes/screenshots. Tous les tests widgets dédiés verts.

Limites : Pas de liaison au placement initial d'acteur ou aux targets actorMove. Pas de playback visuel ni d'interaction runtime map/Flame.

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

Demande : Karim a demandé d'intégrer le plan de sprites de la V1-98 dans la preview du Cinematic Builder pour afficher les sprites d'acteurs réels statiques s'ils sont disponibles, en respectant la profondeur de la V1-96-bis et sans enfreindre l'anti-scope (pas de Flame, pas de playback, pas de runtime).

Decision : Les sprites d'acteurs réels sont rendus en CustomPaint via le cache d'images préchargé en amont. Ancrage bottom-center respecté. Les labels, direction hints et diagnostics restent visibles. Les placeholders servent de fallback résistant.

Preuve : Tests unitaires de rendu écrits dans `cinematic_actor_sprite_preview_renderer_test.dart` et test d'intégration/Visual Gate dans `cinematic_builder_workspace_test.dart` passant avec succès.

Limites : Rendu purement statique de la première frame de l'idle, sans playback interactif ni interpolation de mouvement.

Prochain lot exact recommande : `NS-SCENES-V1-99-bis — Cinematic Actor Sprite Real Asset Fidelity / Visual Gate Polish V0`.

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

Prochain lot exact recommande : `NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0`.

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

Demande : Karim a fourni le prompt V1-95 bis pour que la preview backdrop respecte mieux les proportions attendues, avec moins de chrome et une timeline conservee.

Decision : V1-95 bis reste editor-only. Le Builder garde les donnees cinematic intactes, ajoute un pan local borne en `Vue scene`, un reset/recentrage local, un toggle local de grille et replie les details secondaires pour laisser le canvas dominer.

Preuve : tests Builder ciblés et suite complete verts, suite Library verte, tests `map_core` cinematic verts, analyse cible editor verte, `dart analyze` map_core vert, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png`.

Limites : V1-95 bis ne lance toujours pas la cinematique. Aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet, aucun sprite acteur final, aucune persistence pan/zoom/grille/details, aucune mutation projet/map.

Prochain lot exact recommande : `NS-SCENES-V1-97 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-95

Statut : `NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0` est DONE.

Demande : Karim a fourni le prompt V1-95 pour arreter l'effet mini-map apres V1-94/V1-94 bis et a rappele que les elements Path Studio/eau devaient rester visibles.

Decision : Option E retenue : conserver `Carte entiere` comme comportement par defaut et ajouter `Vue scene` avec zoom local non persistant. Le focus V0 privilegie l'acteur renderable du bloc selectionne, puis la bounding box des acteurs renderable, puis le centre de la map.

Scope realise : helper editor-only `CinematicBackdropPreviewFramingState`, calcul de framing/crop par frame commun, controles `Carte entiere` / `Vue scene` / zoom - reset + / badge zoom, partage du transform entre backdrop background, actor overlay V1-92 et foreground V1-94, compact layout sans overflow, ordre de render pass corrige pour que Path Studio/eau peigne au-dessus du tile background.

Preuve : rapports `ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.md` et `ns_scenes_v1_95_evidence_pack.md`, Visual Gate `screenshots/ns_scenes_v1_95_cinematic_backdrop_preview_framing_zoom_controls_v0.png`, `cinematic_builder_workspace_test.dart` complet vert, `cinematics_library_workspace_test.dart` vert, tests core cibles verts et analyses ciblees vertes.

Limites : V1-95 ne lance toujours pas la cinematique. Aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet, aucun sprite acteur final, aucune persistence zoom/framing, aucune mutation projet/map, aucune donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Mise a jour V1-94

Statut : `NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0` est DONE.

Demande : Karim a fourni le prompt V1-94 et a demande de rendre le backdrop cinematic beaucoup plus fidele au Map Editor avant de continuer vers les sprites acteurs.

Decision : l'Option E de V1-93 est materialisee par un plan `CinematicMapBackdropLayerRenderPlan` separe du plan tiles V1-89. Le loader reste editor-only/read-only, utilise `CinematicTilesetAssetRegistry`, et le panel compose `terrain -> tileBackground -> path -> surface -> placedBackground -> actorOverlayV1-92 -> tileForeground -> placedForeground`.

Scope realise : terrain, path, TileLayer background/foreground, surface, MapPlacedElement, generated placements environment via vrais `MapPlacedElement`, diagnostics/fallbacks par famille, partial render, preservation timeline/transports/duration/resize/probe/pickers, Visual Gate V1-94 et tests cibles.

Preuve : rapports `ns_scenes_v1_94_cinematic_map_backdrop_layer_fidelity_renderer_v0.md` et `ns_scenes_v1_94_evidence_pack.md`, screenshot `screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png`, tests Builder/Library cibles verts, `dart test` complet `map_core` vert, analyse ciblee editor verte et checks anti-scope.

Limites : V1-94 ne lance toujours pas la cinematique. Aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet. Les sprites acteurs finaux restent hors scope et doivent etre cadres par V1-96 apres le cadrage backdrop V1-95.

Historique avant V1-95 : le prochain lot recommande etait `NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0`, desormais traite.

## Mise a jour V1-94 bis

Statut : `NS-SCENES-V1-94 bis — Cinematic Path Studio Water Fidelity Fix` est DONE.

Demande : Karim a signale apres V1-94 que les elements du Path Studio, notamment l'eau, manquaient dans le backdrop cinematic. Le prompt colle preparait V1-95, mais cette remarque directe a ete priorisee comme correctif V1-94 bis.

Decision : `_resolvePathPreset` conserve la resolution par id exact de pattern, puis, si le calque reference un preset de base, cherche l'unique `ProjectPathPatternPreset` lie par `basePathPresetId`. En cas d'ambiguite, fallback base preserve pour eviter un rendu arbitraire.

Scope realise : correction locale du plan `CinematicMapBackdropLayerRenderPlan`, test de regression Path Studio/eau dans `cinematic_builder_workspace_test.dart`, evidence pack et rapport avec code.

Preuve : rapports `ns_scenes_v1_94_bis_cinematic_path_studio_water_fidelity_fix.md` et `ns_scenes_v1_94_bis_evidence_pack.md`, `cinematic_builder_workspace_test.dart` complet vert (`+175`), analyse ciblee editor verte, `git diff --check` et checks anti-scope sans sortie.

Limites : aucun screenshot nouveau, aucun runtime, aucun Flame, aucun playback, aucun MapCanvas complet, aucun sprite acteur final.

Historique avant V1-95 : le prochain lot recommande etait `NS-SCENES-V1-95 — Cinematic Backdrop Preview Framing / Zoom Controls V0`, desormais traite.

## Mise a jour V1-93

Statut : `NS-SCENES-V1-93 — Cinematic Map Backdrop Layer Fidelity Prep Contract` est DONE.

Demande : Karim a fourni le prompt V1-93 et a explicitement demande de corriger la fidelite du decor avant le Sprite Resolver. Le lot est documentaire/architecture-review uniquement : aucun renderer, aucun package, aucun test, aucun screenshot.

Decision : l'Option E est retenue. V1-94 doit creer un plan de rendu cinematic multi-layer dedie, editor-only/read-only, qui reutilise seulement des helpers purs du Map Editor et garde `CinematicTilesetAssetRegistry` comme cache bas niveau. `MapCanvas`, `MapGridPainter` brut, runtime, Flame et playback restent exclus.

Scope realise : audit MapData layer semantics, audit rendering parity Map Editor, audit assets/catalogues, audit render plan, anti-scope runtime/Flame/MapCanvas, review produit fidelite backdrop, plan tests/Visual Gate V1-94 et arbitrage sub-agents A-G.

Preuve : rapports `ns_scenes_v1_93_cinematic_map_backdrop_layer_fidelity_prep_contract.md` et `ns_scenes_v1_93_evidence_pack.md`, Gate 0 propre, sub-agents A-G, recherches `rg`, checks anti-scope et `git diff --check`.

Limites : doc-only. Aucun code produit, package, test, screenshot, renderer, MapCanvas, runtime, Flame, playback, mutation MapData/ProjectManifest, modification Selbrume, fake terrain/path/environment ou image IA n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-94 — Cinematic Map Backdrop Layer Fidelity Renderer V0`.

Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.

Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context. Le polish scroll/visibility a ensuite occupe le slot V1-80, mais V1-80 est maintenant reserve au Character Library Picker ; V1-90 est reserve a Actor Display Prep apres le lot V1-89 demande par Karim, V1-91 est pris par Actor Display Read Model, et V1-92 devient le renderer Actor Display. Le polish scroll/visibility est donc deplace explicitement en `NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0`.

## Mise a jour V1-91

Statut : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0` est DONE.

Demande : Karim a fourni le prompt V1-91 et a demande un read model pur avant tout renderer. Le lot devait construire la projection testable des acteurs, tout en confirmant que V1-91 ne rend toujours aucun acteur dans l'interface.

Decision : le read model vit dans `map_core` et consomme seulement des donnees deja chargees : `CinematicAsset`, `ProjectManifest`, `ProjectMapEntry`, `MapData` et, optionnellement, `CinematicStageMapSourceCatalog`. `requiredActors` reste l'inventaire canonique ; `actorBindings`, `actorAppearanceBindings`, `initialPlacements` et `movementTargetBindings` resolvent ou diagnostiquent bindings, apparences et positions.

Scope realise : `CinematicActorDisplayPreviewModel`, acteurs projetables, statuts globaux, positions fromMapEntity/fromMovementTarget mapEntity/mapEvent, abstractPoint sans coordonnees inventees, player sans GameState, mapEntity via NPC/trainer character, cinematicOnly via Character Library, unbound hidden, directions actorFace statiques, actorMove ignore, render hints abstraits et diagnostics locaux.

Preuve : RED test compile attendu, 25 tests V1-91 verts, tests core non-regression cibles verts, `dart analyze` map_core vert et suite complete `dart test --reporter=compact` map_core verte.

Limites : V1-91 n'ajoute aucun renderer UI, ne charge aucun sprite, n'affiche aucun acteur, n'importe ni Flutter, ni dart:ui, ni Flame, ne touche pas au runtime, n'ajoute aucun playback, currentTimeMs/playbackTimeMs/isPlaying, pathfinding/collision, image IA ou donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`.

## Mise a jour V1-90

Statut : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract` est DONE.

Demande : Karim a fourni le prompt V1-90 et a demande explicitement des sub-agents/passes, sans coder l'affichage des acteurs. Le lot devait preparer l'affichage statique futur apres le decor reel V1-89, tout en confirmant que V1-90 ne rend toujours aucun acteur.

Decision : l'Option C est retenue. Le futur actor display doit passer par un read model pur, idealement dans `map_core`, puis par un resolver editor pour les assets/sprites. Le Builder ne doit pas calculer directement toute la logique dans le widget, et le runtime/Flame/GameState sont exclus.

Scope realise : audit actor sources/stage bindings, contrat positions/placements, contrat Character Library/appearances, contrat overlay/viewport transform, anti-scope runtime/playback, wording UX, diagnostics futurs, tests futurs et Visual Gate V1-91.

Preuve : rapports `ns_scenes_v1_90_cinematic_actor_display_preview_prep_contract.md` et `ns_scenes_v1_90_evidence_pack.md`, sub-agents A-F, Gate 0 propre, checks anti-scope documentaires et `git diff --check`.

Limites : lot documentaire uniquement. Aucun code produit, package, test, screenshot, rendu acteur, sprite Character Library, placeholder acteur, runtime, Flame, playback, pathfinding/collision, mutation MapData/ProjectManifest ou donnee Selbrume n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`.

## Mise a jour V1-89

Statut : `NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0` est DONE.

Demande : Karim a fourni le prompt V1-89 et a explicitement demande d'utiliser des sub-agents/passes et une preuve visuelle/manipulation pour tester l'application. Le lot corrige la limite V1-88 : le renderer bitmap devait etre branche au vrai workspace editor et resoudre les assets depuis le parent avant toute suite Actor Display.

Decision : la resolution d'image reste editor-only et hors build/paint. `CinematicsLibraryWorkspace` garde son fallback structurel, mais charge maintenant un `CinematicMapBackdropTileRenderPlan` depuis le snapshot `MapData` et un resolver parent de chemin tileset ; `NarrativeWorkspaceCanvas` fournit ce resolver via `EditorNotifier.getTilesetAbsolutePathById`.

Scope realise : loader de plan tileset, wiring parent/editor notifier, cache/chargement asynchrone borne dans la Library, diagnostics `tileMetricMismatch` et `noBitmapInstructions`, diagnostics partiels visibles dans le meta bar, tests success/fallback/collecteur/fidelite, Visual Gate 1663x926 et screenshot artefact.

Preuve : rapports `ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md` et `ns_scenes_v1_89_evidence_pack.md`, screenshot `screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png`, sub-agents A-E, tests ciblés et checks anti-scope.

Limites : le rendu reste limite aux `TileLayer` bitmap ; les surfaces/objets/environnement continuent d'utiliser le fallback structurel existant. Aucun acteur, runtime, Flame, playback, pathfinding/collision, mutation map/projet, donnee Selbrume hardcodee ou image IA n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.

Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

## Mise a jour V1-88

Statut : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0` est DONE.

Demande : Karim a fourni le prompt V1-88 et a demande explicitement d'utiliser des sub-agents/passes et Codex computer use pour tester via capture/screenshot. Le lot devait rendre les vraies tiles/assets de la map dans la preview Cinematic Builder avant tout Actor Display.

Decision : le renderer reste dedie au Builder, editor-only et read-only. Les images sont resolues hors build/paint par un registre asset, le plan de rendu transforme les `TileLayer` visibles en instructions bitmap, puis un `CustomPainter` cinematic dessine les tiles proportionnellement dans le viewport V1-86.

Scope realise : plan de rendu tiles, diagnostic/fallback asset, painter bitmap statique, integration Builder/Library par injection optionnelle, labels UX `Carte du projet (statique)` / `Tiles reelles affichees`, tests RED/GREEN/fallback/plan, Visual Gate 1663x926 et screenshot artefact.

Preuve : rapports `ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md` et `ns_scenes_v1_88_evidence_pack.md`, screenshot `screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png`, tests ciblés et `git diff --check`.

Limites : l'integration automatique depuis le workspace parent n'est pas cablee dans ce lot parce que le prompt bornait les fichiers autorises ; V1-88 expose le contrat `BuildCinematicBackdropTileRenderPlanCallback` cote Library/Builder. Les placements visuels hors `TileLayer` restent au fallback structurel pour un lot futur.

Prochain lot exact recommande a l'issue de V1-88 : `NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0`, ajoute ensuite a la demande de Karim avant Actor Display.

## Mise a jour V1-87

Statut : `NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract` est DONE.

Demande : Karim a fourni le prompt V1-87 et a volontairement interrompu la trajectoire Actor Display pour cadrer le rendu reel des tiles/assets de map avant de poser des acteurs dans la preview.

Decision : l'Option E hybride est retenue. V1-88 doit creer un petit contrat/renderer cinematic read-only dedie, alimente par `MapData`, `ProjectManifest`, des instructions bitmap et des images tileset resolues en amont cote editor. Il peut reutiliser des helpers purs du Map Editor si leur dependance reste bornee, mais ne doit pas embarquer `MapCanvas` complet.

Scope realise : audit documentaire MapData/layers visuels, resolution tilesets/assets, rendu Map Editor, frontieres runtime/Flame, options techniques comparees, contrat futur renderer V1-88, fallbacks/diagnostics, tests futurs et Visual Gate future.

Preuve : rapports `ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md` et `ns_scenes_v1_87_evidence_pack.md`, sub-agents A-E, recherches `rg`, checks anti-scope et `git diff --check`.

Limites : doc-only. Aucun renderer n'est code, aucune vraie map n'est affichee, aucune tile n'est rendue, aucun package n'est modifie, aucun test ni screenshot n'est cree, aucun runtime/Flame/playback/acteur n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

## Mise a jour V1-86

Statut : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0` est DONE.

Demande : Karim a fourni le prompt V1-86 et a demande explicitement de corriger la composition/lisibilite du backdrop map avant de continuer vers l'Actor Display. Ce lot remplace donc volontairement l'ancien prochain lot recommande V1-86 Actor Display, qui est repousse en V1-87.

Decision : le Builder donne plus de hauteur utile au backdrop quand un `CinematicMapBackdropPreviewModel` est disponible, retire les badges redondants qui concurrencaient la carte, place meta et legende dans un rail secondaire compact, expose une vraie key de viewport pour tester la taille de map, et renforce le painter par grille adaptive, traits plus lisibles, chemins ruban et ancres halo/core.

Scope realise : preview backdrop plus grande, map proportionnelle, meta/legende secondaires, diagnostics sans overflow, timeline/pickers/inspector/transports disabled preserves, screenshot Visual Gate 1663x926 et tests de viewport/ratio/legende.

Preuve : RED/GREEN widget sur la taille du viewport, tests Builder/Library/core cibles verts, Visual Gate V1-86 `ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png`, analyse ciblee editor verte. Le `flutter test` complet du package editor reste rouge hors lot (`+2191 -18`) sur dettes preexistantes dont golden V1-29 et Pokemon SDK converter ; l'analyse globale reste rouge hors lot sur `pokemon_sdk_move_catalog_converter.dart`.

Limites : rendu toujours structurel ; les vraies tiles/assets ne sont pas rendues. Aucun acteur, runtime, Flame, playback, pathfinding/collision, mutation map/projet, donnee Selbrume, image IA ou modele `gpt-image-2` n'est ajoute.

Prochain lot exact recommande : `NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract`.

## Mise a jour V1-85

Statut : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0` est DONE.

Demande : Karim a fourni le prompt V1-85 et a autorise les sub-agents au besoin. Le scope etait d'ameliorer le decor V1-84 avec des primitives visuelles plus proches d'une vraie map, sans lancer de runtime ni rendre d'acteurs.

Decision : le read model `CinematicMapBackdropPreviewModel` est etendu en Dart pur avec `visualPrimitives`, `mapWidth` et `mapHeight`. Les primitives viennent uniquement de `MapData.layers` et `MapData.placedElements` positionnes : cellules tile/terrain/path/surface, ancres objet et environnement quand les donnees existent, sinon `layerSummary` honnete. Le renderer editor utilise un mini `CustomPainter` dedie, alimente par les couleurs du design system, sans `MapCanvas` complet.

Scope realise : preview plus map-like que V1-84 avec grille/cellules/ancres spatiales, compteur de primitives, legendes par layer, fallback sans primitives, diagnostics et fallbacks V1-84 preserves, timeline/duree/resize/probe/pickers map-aware/Character Library preserves.

Preuve : tests core `cinematic_map_backdrop_preview_model_test.dart` verts avec primitives/fallback/no fake/exclusions, tests Builder et Library verts, Visual Gate `ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png` 1663x926, analyse ciblee editor verte et `dart analyze` core vert.

Limites : rendu encore structurel ; les vraies tiles/assets ne sont pas rendues. Aucun runtime, Flame, PlayableMapGame, playback, acteurs rendus, Character Library sprites, collision/pathfinding/triggers/event/entity overlays, mutation map/projet, donnees Selbrume ou image IA.

Prochain lot exact recommande : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0`, a la demande de Karim avant l'Actor Display.

## Mise a jour V1-84

Statut : `NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0` est DONE.

Demande : Karim a fourni le prompt V1-84 et a autorise les sub-agents au besoin. Le besoin etait d'afficher enfin un decor de map statique dans le Builder tout en confirmant que V1-84 ne lance toujours pas la cinematique.

Decision : le renderer V0 consomme directement `CinematicMapBackdropPreviewModel` sans etendre `map_core`. Le modele est construit cote editor depuis `CinematicAsset.mapId`, `ProjectMapEntry`, `stageContext.backdropMode` et la snapshot `MapData` deja chargee pour les pickers ; le Builder ne charge pas de map dans `build()`.

Scope realise : nouveau panel editor pur pour la zone preview, affichage available avec map label, size summary, layers visuels, cadrage/viewport et badge read-only ; fallbacks humains pour tous les statuts non available ; diagnostics lisibles ; preservation des transports disabled, timeline, duree, resize, probe, pickers map-aware et Character Library.

Preuve : preflight Builder rouge connu reproduit puis corrige sans supprimer le test, test RED/GREEN `renders static map backdrop preview when backdrop model is available`, tests de fallbacks, mutation projet/MapData, absence acteur/collision overlay, interactions timeline avec backdrop visible, wiring Library snapshot -> Builder, Visual Gate `ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.png`, tests core cibles verts, `cinematic_builder_workspace_test.dart` vert, `cinematics_library_workspace_test.dart` vert, analyse ciblee editor verte.

Limites confirmees : V1-84 ne lance toujours pas la cinematique ; pas de runtime, Flame, PlayableMapGame, GameWidget, playback, timer, acteur rendu, sprite Character Library rendu, collision/pathfinding/triggers/event/entity overlays, mutation `ProjectManifest`/`MapData`, donnees Selbrume ou image IA.

Prochain lot exact recommande : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0`.

## Mise a jour V1-83

Statut : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0` est DONE.

Demande : Karim a fourni le prompt du prochain lot et a autorise l'utilisation de sub agents au besoin. Le besoin etait de construire la projection testable du decor avant tout rendu.

Decision : V1-83 vit dans `map_core` sous forme de read model pur. La source canonique reste `CinematicAsset.mapId -> ProjectMapEntry -> MapData`, avec `stageContext.backdropMode` comme intention backdrop et sans ajouter de `mapId` au Stage Context.

Scope realise : `CinematicMapBackdropPreviewModel`, statuts, diagnostics, `CinematicMapBackdropLayerPreview`, projection des layers visuels `MapData.layers`, exclusion collision/entities/events/triggers/warps/gameplayZones, fallback label/size summary, verification optionnelle des tilesets et viewport recommendation pure sans Flutter/Flame.

Preuve : test TDD RED/GREEN `cinematic_map_backdrop_preview_model_test.dart`, tests core non-regression cibles verts, `dart analyze` map_core vert. Le test editor `cinematics_library_workspace_test.dart` est vert ; `cinematic_builder_workspace_test.dart` reste rouge sur un champ de renommage acteur visible dans un test read-only hors scope V1-83.

Limites confirmees : aucune map affichee en UI, aucun renderer, aucun runtime, aucun Flame, aucun playback, aucun pathfinding/collision, aucun actor rendering, aucun chargement disque depuis core, aucune image IA et aucune donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0`.

## Mise a jour V1-82

Statut : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract` est DONE.

Demande : lot documentaire relance a la demande de Karim apres constat que le rapport V1-82 manquait. Le prompt imposait un rapport unique, des sub-agents ou passes specialisees, Gate 0, audit Stage Context, MapData snapshot, rendu Map Editor, runtime/Flame anti-scope, options comparees, contrat backdrop/viewport/diagnostics/tests futurs et mise a jour des roadmaps.

Decision : Option E retenue. V1-82 definit comment afficher le decor de map plus tard, mais ne l'affiche pas encore. La suite recommandee commence par un read model pur `CinematicMapBackdropPreviewModel` avant tout renderer : source canonique `CinematicAsset.mapId -> ProjectManifest.maps -> ProjectMapEntry.relativePath -> MapData`, `stageContext.backdropMode` pilote l'intention `none/projectMap`, et le Builder reste consommateur de snapshot/catalogue fourni par le niveau editor.

Scope realise : rapport V1-82 en francais, cinq sub-agents/passes documentees, arbitrage final, options A-E comparees, rejet runtime/Flame/PlayableMapGame, prudence sur MapCanvas/MapGridPainter, contrat conceptuel backdrop preview, viewport/camera, diagnostics futurs, tests futurs V1-83/V1-84 et evidence pack documentaire.

Limites confirmees : aucun code produit V1-82, aucun package modifie par V1-82, aucun test lance, aucune map affichee, aucune preview reelle, aucun runtime, playback, timer, `Ticker`, `AnimationController`, `currentTimeMs`, `playbackTimeMs`, pathfinding, collision, warp, spawn runtime, image IA ou donnee Selbrume. Les modifications `packages/` visibles au Gate 0 sont preexistantes hors V1-82 et ne sont pas incluses dans ce lot.

Prochain lot exact recommande : `NS-SCENES-V1-83 — Cinematic Map Backdrop Preview Read Model V0`.

## Mise a jour V1-81

Statut : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0` est DONE.

Demande : lot implemente a la demande de Karim, avec autorisation d'utiliser des sub agents au besoin. Le besoin etait de polir le drift apparence Character Library apres V1-80, sans ouvrir de preview reelle ni toucher au runtime.

Decision : les diagnostics d'apparence restent dans le Builder/Library/readiness editor. Aucune mutation automatique silencieuse n'est faite : les refs incompatibles, cassees ou orphelines sont visibles et nettoyables par action explicite.

Scope realise : messages humains pour ref character cassee, actor kind incompatible, acteur supprime/orphelin, Character Library vide, character sans tileset ou sans animation idle exploitable ; actions `Retirer la reference`, `Retirer l'apparence`, `Nettoyer la reference` ; readiness `Apparences acteurs` avec `OK`, `A completer` et `A corriger` ; summary Library `apparence a corriger` ; Visual Gate V1-81.

Preuve : test RED puis GREEN `shows incompatible character appearance drift when actor is no longer cinematic only`, tests Builder/Library cibles verts, core non-regression cibles verts, analyse cible editor verte, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png` generee.

Limites confirmees : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas de mutation Character Library, pas de `characterId` dans `CinematicActorBinding` ou `requiredActors`, pas de TextField ID, pas de JSON brut, pas d'image IA ou `gpt-image-2`, pas de donnee Selbrume.

Prochain lot exact recommande : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

## Mise a jour V1-80

Statut : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0` est DONE.

Demande : lot implemente a la demande de Karim, dans la continuite de V1-79. Le besoin etait d'exposer dans le Builder le binding d'apparence Character Library pour les acteurs `cinematicOnly`, sans coder de preview reelle.

Decision : le Builder consomme `ProjectManifest.characters` et les operations V1-79 `upsertCinematicActorAppearanceBinding` / `removeCinematicActorAppearanceBinding`. `CinematicActorBinding` reste separe et ne recoit pas de `characterId`.

Scope realise : section `Apparence` par acteur, picker `ProjectCharacterEntry` avec nom/tileset/frame/tags, selection et retrait explicite, etats empty/broken, messages herites pour `player`/`mapEntity`/`unbound`, readiness apparences, diagnostics V1-79 humanises, Visual Gate V1-80.

Preuve : tests Builder/Library verts, analyse cible editor verte, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_80_cinematic_character_library_picker_v0.png` generee. `flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites confirmees : pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override `player`/`mapEntity`/`unbound`, pas de modification Character Library, pas de `stageContext.mapId`, pas d'image IA ou `gpt-image-2`.

Prochain lot exact recommande : `NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0`.

## Mise a jour V1-79

Statut : `NS-SCENES-V1-79 — Cinematic Character Library Binding Core Model V0` est DONE.

Demande : lot implemente a la demande de Karim, dans la continuite du contrat V1-78. Le besoin etait de materialiser le binding core entre un acteur `cinematicOnly` et la Character Library, sans coder le picker UI ni faire croire a une preview reelle.

Decision : l'apparence reste separee du binding logique. V1-79 ajoute `CinematicActorAppearanceBinding` dans `stageContext.actorAppearanceBindings`; `CinematicActorBinding` ne recoit pas de `characterId`. En V0, un binding d'apparence est autorise uniquement pour un acteur existant dont le binding stage est `cinematicOnly`.

Scope realise : JSON backward-compatible, absence de `actorAppearanceBindings` lue comme liste vide, operations pures `upsertCinematicActorAppearanceBinding` et `removeCinematicActorAppearanceBinding`, validation authoring, diagnostics actor/character references, resolution de `ProjectManifest.characters`, tests JSON/manifest/operations/diagnostics.

Preuve : `packages/map_core` passe les tests cibles, `dart analyze` est vert, et la suite complete `dart test --reporter=compact` termine sur `+2390 All tests passed!`. Les tests editor non-regression Library/Builder passent ; `flutter analyze` global `map_editor` reste rouge uniquement sur dette Pokemon SDK preexistante hors lot.

Limites confirmees : pas de picker UI Character Library, pas de preview reelle, pas de runtime, pas de playback, pas de pathfinding, pas d'override player/mapEntity/unbound en V0, pas d'image IA, pas de donnee Selbrume et pas de `stageContext.mapId`.

Prochain lot exact recommande : `NS-SCENES-V1-80 — Cinematic Character Library Picker V0`. L'ancien polish scroll/visibility de timeline est deplace en backlog futur `NS-SCENES-V1-91 — Cinematic Timeline Scroll / Visibility Polish V0`.

## Mise a jour V1-70

Statut : `NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0` est DONE.

Decision : le Cinematic Builder rend maintenant les regles de duree lisibles sans donner plus de pouvoir a la timeline. L'inspecteur affiche les bornes `100-30000 ms` ou `200-30000 ms` pour `actorMove`, rappelle le pas `100 ms`, donne des erreurs inline no-code pour saisie vide, non entiere, sous minimum ou au-dessus maximum, et explique les blocs non editables.

Scope realise : aide min/max/pas dans la section Duree, feedback compact `Minimum atteint` / `Maximum atteint` quand une duree selectionnee est aux bornes apres edition ou resize, messages specifiques pour marker draft et bloc lecture seule, diagnostics core renforces pour durees persistentes invalides, tests editor/core et Visual Gate V1-70.

Limites : pas de nouveau modele temporel, pas de changement de bornes, pas de drag/reorder de blocs, pas de bord gauche draggable, pas de persistance `startMs/endMs`, pas de playback, pas de seek runtime, pas de scrubber runtime, pas de preview runtime, pas de modification runtime/gameplay/battle/examples, pas d'image IA ni donnees Selbrume.

Preuve : rapport V1-70, evidence pack, capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.png`, tests core/editor cibles verts, analyse cible editor verte. `flutter analyze` global `map_editor` reste rouge uniquement sur dette preexistante Pokemon SDK hors lot.

Prochain lot exact : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract`.

## Mise a jour V1-71

Statut : `NS-SCENES-V1-71 — Cinematic Stage / Map Context Prep Contract` est DONE.

Decision : V1-71 retient une option hybride : contexte stage par defaut porte par `CinematicAsset`, avec overrides Scene/Event futurs explicitement hors V0. L'audit confirme que `CinematicAsset.mapId` existe deja comme ancre map simple, mais qu'il manque encore un contrat structure pour `backdropMode`, actor bindings, initial placements et movement target bindings.

Contrat recommande : `mapId` optionnel, `backdropMode` limite a `none | projectMap`, actor bindings V0 `player | mapEntity | cinematicOnly | unbound`, initial placements par source nommee (`fromMapEntity`, `fromMovementTarget`, `namedStagePoint`, `unset`) et movement target bindings optionnels vers `abstractPoint`, `mapEntity`, `mapEvent` ou `namedStagePoint`.

Diagnostics futurs recommandes : map stage inconnue, map manquante pour preview, binding acteur absent/casse, double binding player, placement initial manquant/casse, target binding inconnu/casse et readiness preview indisponible. Les drafts restent authorables ; la preview reelle devra se desactiver ou degrader tant que le contexte n'est pas resolu.

Limites : lot documentaire uniquement, aucun code produit, package, test, screenshot, build_runner, model JSON, picker map, actor binding code, preview reelle, runtime, pathfinding ou donnees Selbrume.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_71_cinematic_stage_map_context_prep_contract.md`, Gate 0 propre, audits core/map/editor documentes, checks anti-scope et `git diff --check` propre.

Prochain lot exact : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0`.

## Mise a jour V1-72

Statut : `NS-SCENES-V1-72 — Cinematic Stage / Map Context Core Model V0` est DONE.

Decision : le Stage Context authoring vit dans `CinematicAsset.stageContext`, mais l'ancre map reste exclusivement `CinematicAsset.mapId`. Aucun `stageContext.mapId` n'est ajoute. Le modele V0 couvre `backdropMode`, actor bindings `player/mapEntity/cinematicOnly/unbound`, placements initiaux `unset/fromMapEntity/fromMovementTarget` et movement target bindings `abstractPoint/mapEntity/mapEvent`.

Scope realise : JSON/manifest round-trip, operations pures de map/stage/bindings/placements/target bindings, diagnostics core stage/readiness, tests RED puis GREEN, suite complete `map_core` verte. Les tests editor Library/Builder restent verts en non-regression.

Limites : pas d'UI Stage Context, pas de preview reelle, pas de runtime cinematic map-aware, pas de pathfinding, pas de collision/warp, pas de playback, pas de build_runner, pas de donnees Selbrume. Les diagnostics ne resolvent pas encore les IDs d'entites/events dans le contenu d'une map chargee.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_72_cinematic_stage_map_context_core_model_v0.md`, evidence pack `reports/narrativeStudio/scenes/ns_scenes_v1_72_evidence_pack.md`, `dart test --reporter=compact` `map_core` `+2354`, `dart analyze` `map_core` vert, tests editor Library `+10` et Builder `+93`. `flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK hors lot.

Prochain lot exact : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0`.

## Mise a jour V1-73

Statut : `NS-SCENES-V1-73 — Cinematic Stage / Map Context Editor V0` est DONE.

Decision : le Builder expose le Stage Context V1-72 en authoring no-code. `CinematicAsset.mapId` reste l'unique ancre Stage Map ; aucun `stageContext.mapId` n'est ajoute. Les choix mapEntity/mapEvent restent visibles mais desactives avec messages honnetes, car le Builder ne dispose pas encore d'une source fiable `MapData.entities/events`.

Scope realise : picker de map depuis `ProjectManifest.maps`, clear map, backdrop `none/projectMap`, actor bindings `player/mapEntity/cinematicOnly/unbound`, placements initiaux `unset/fromMapEntity/fromMovementTarget`, target bindings `abstractPoint/mapEntity/mapEvent`, diagnostics stage visibles, summary Library map lisible et compteur diagnostics stage, integration projet en memoire.

Limites : pas de preview reelle, pas de runtime cinematic map-aware, pas de playback, pas de pathfinding/collision/warp, pas de coordonnees libres, pas de raw JSON/IDs libres, pas de donnees Selbrume codees. Les entites/events de map seront selectionnables dans un lot futur quand le Builder recevra une source de donnees map fiable.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.md`, evidence pack `reports/narrativeStudio/scenes/ns_scenes_v1_73_evidence_pack.md`, screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_73_cinematic_stage_map_context_editor_v0.png` (`1663 x 926`, SHA-256 `79621972c1c50ef26ac1f5603b1587a6a2752087bd802d43173488154a3454ed`), tests Builder `+119`, Library `+11`, `map_core` cibles verts, analyse cible `map_editor` verte. `flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK hors lot.

Prochain lot exact : `NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0`.

## Mise a jour V1-74

Statut : `NS-SCENES-V1-74 — Cinematic Stage Context Diagnostics / Preview Readiness Polish V0` est DONE.

Decision : le Builder affiche maintenant une section `Preparation preview` pres du `Contexte de scene`. Elle classe le Stage Context en `Sandbox uniquement`, `Contexte incomplet`, `A corriger avant preview` ou `Pret pour future preview`, avec une checklist no-code : map, decor, acteurs lies, positions initiales, cibles de mouvement et sources map-aware. La Library affiche aussi un resume `Preview`.

Scope realise : diagnostics stage regroupes avec messages humains, reference technique secondaire, messages explicites pour les gaps futurs `mapEntity` / `mapEvent`, transports toujours desactives, timeline et durees preservees, aucun `stageContext.mapId`.

Limites : pas de preview reelle, pas de playback, pas de timer, pas de `currentTimeMs`/`playbackTimeMs`/`isPlaying`, pas de pathfinding/collision/warp/spawn, pas de donnees Selbrume, pas de source map-aware reelle pour entites/events.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.md`, evidence pack `reports/narrativeStudio/scenes/ns_scenes_v1_74_evidence_pack.md`, capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_74_cinematic_stage_context_diagnostics_preview_readiness_polish_v0.png`, tests Builder/Library verts, `map_core` cibles verts, analyse cible `map_editor` verte. `flutter analyze` global `map_editor` reste rouge sur dette Pokemon SDK hors lot.

Prochain lot exact : `NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract`.

## Mise a jour V1-75

Statut : `NS-SCENES-V1-75 — Cinematic Map Entity/Event Source Audit / Picker Prep Contract` est DONE.

Decision : V1-75 retient l'Option E. Le Cinematic Builder ne doit pas consommer directement les widgets Map Editor ni exposer d'IDs libres ; il doit recevoir un catalogue stage-aware pur construit depuis une `MapData` fiable. `ProjectManifest.maps` reste seulement le catalogue metadata/relativePath, tandis que les sources reelles vivent dans `MapData.entities` et `MapData.events`.

Contrat recommande : `CinematicStageMapSourceCatalog` avec `mapId`, `mapLabel`, `entities`, `events`, labels no-code, ids techniques secondaires discrets, capabilities `canBindActor` et `canBeMovementTarget`, diagnostics de sources indisponibles ou inconnues. Actor binding V0 utilise `mapEntity`; movement target V0 peut utiliser `mapEntity` ou `mapEvent`; aucun actor binding direct vers event.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md`, Gate 0 propre, audit `ProjectManifest.maps`, `ProjectMapEntry.relativePath`, `MapData.entities`, `MapData.events`, `MapEntity`, `MapEventDefinition`, `MapRepository`, `LoadMapUseCase`, `EditorNotifier.loadMapSnapshotById`, panels Entity/Event et Builder/Library Cinematics. Checks documentaires anti-scope executes.

Limites : lot documentaire uniquement, aucun code produit, package, test, picker actif, sourceId/mapEntityId/eventId ecrit, preview reelle, runtime, pathfinding, screenshot, build_runner, image IA ou donnees Selbrume.

Prochain lot exact : `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0`.

## Mise a jour V1-76

Statut : `NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0` est DONE.

Decision : le catalogue vit dans `map_core` comme read model pur et recoit une `MapData` deja chargee. Il ne depend ni de `EditorNotifier`, ni d'un repository, ni du runtime. La signature retenue est `buildCinematicStageMapSourceCatalog({required ProjectMapEntry? stageMap, required MapData? mapData})`.

Scope realise : `CinematicStageMapSourceCatalog` expose les statuts `missingStageMap`, `mapDataUnavailable`, `mapIdMismatch` et `available`; les entites viennent de `MapData.entities`; les events viennent de `MapData.events`; les labels no-code precedent les ids bruts; les ids techniques restent dans `secondaryLabel`; `canBindActor` est vrai pour les entites NPC; `canBeMovementTarget` est vrai pour les entites/events positionnes par le modele.

Preuve : test catalogue TDD RED puis GREEN, tests core cinematics cibles, `dart analyze` map_core vert, tests widget editor Builder/Library verts. `flutter analyze` map_editor reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites : aucun picker actif, aucune UI modifiee, aucune preview reelle, aucun runtime, aucun pathfinding, aucune mutation `stageContext.mapId`, aucune donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`.

## Mise a jour V1-77

Statut : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0` est DONE.

Decision : le Builder consomme maintenant le catalogue V1-76 fourni depuis le niveau editor. `CinematicsLibraryWorkspace` charge une snapshot `MapData` non destructive via `EditorNotifier.loadMapSnapshotById`, construit `CinematicStageMapSourceCatalog`, puis le transmet au `CinematicBuilderWorkspace`.

Scope realise : actor binding `mapEntity` actif avec vraies entites PNJ bindables, movement target `mapEntity` actif avec vraies entites cibles, movement target `mapEvent` actif avec vrais events positionnes, labels no-code visibles, ids techniques gardes en secondaire, readiness map-aware alignee sur le catalogue.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.md`, evidence pack, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_77_cinematic_stage_map_entity_event_pickers_v0.png` en 1663x926, tests Builder/Library verts, tests/analyze `map_core` verts et analyse cible editor verte. L'analyse globale `map_editor` reste rouge sur dette Pokemon SDK preexistante hors lot.

Limites : aucune preview reelle, aucun runtime, aucun playback, aucun timer, aucune coordonnee libre, aucun JSON brut, aucun `stageContext.mapId`, aucun pathfinding, aucune donnee Selbrume, aucune image IA ou `gpt-image-2`.

Prochain lot exact : `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0`.

## Mise a jour V1-51

Statut : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0` est DONE.

Decision : la timeline du Cinematic Builder reste fondee sur `CinematicTimeline.steps`, mais expose maintenant une projection temporelle derivee : `startMs/endMs` calcules, duree visuelle explicite ou fallback 300 ms, ticks adaptes a la duree totale, lanes derivees et barres horizontales proportionnelles. Rien de ce layout n'est persiste dans le modele.

Limites : pas de drag/drop, resize, reorder, playhead fonctionnel, scrubber, transport playback, preview runtime, pathfinding, coordonnees libres, persistance `startMs/endMs` ou mutation du deroule lineaire.

Preuve : tests core time layout/lane/library, tests widget Builder/Library, analyses ciblees, capture Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png` en 1663x926 et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0`.

## Mise a jour V1-52

Statut : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0` est DONE.

Decision : le curseur reste purement editor-side. Il est derive de `selectedStepId` et du `CinematicTimelineTimeLayoutReadModel` V1-51 ; le bloc selectionne fournit `startMs`, qui est mappe en pixels dans la timeline scrollable. Aucun `cursorTimeMs`, `playheadTimeMs`, `startMs` ou `endMs` n'est persiste dans le modele.

Scope realise : badge `Selection : <temps>`, ligne verticale et handle decoratif non interactifs, alignement sur le debut du bloc selectionne, absence de curseur sans selection, tap axe sans seek, preview sandbox et inspecteur existants preserves, capture Visual Gate V1-52.

Limites : pas de playback, timer, transport fonctionnel, scrubber, seek, drag/drop, resize, reorder, preview runtime, pathfinding, coordonnees libres ou persistance temporelle.

Preuve : test widget curseur/non-seek, suite Builder, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.png`, analyses et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0`.

## Mise a jour V1-53

Statut : `NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0` est DONE.

Decision : les controles de transport restent strictement editor-only et non fonctionnels. Le Builder affiche trois boutons disabled icon-only Reset / Play / Stop avec tooltips. Chaque `PokeMapButton` a `onPressed = null`.

Scope realise : placement sous la timeline V1-51/V1-52, boutons Reset / Play / Stop visibles en icon-only, tooltips informatifs, preservation de la selection et du curseur V1-52 apres taps, aucune mutation `ProjectManifest`, capture Visual Gate V1-53.

Limites : pas de playback, timer, seek, scrubber, preview runtime, transport fonctionnel, drag/drop, resize, reorder, persistance temporelle, changement JSON ou modification runtime/gameplay/battle/examples.

Preuve : test widget transport disabled/non-mutation, suite Builder `+30`, suite Library `+10`, tests core time layout/lane relances, analyses ciblees, checks anti-scope et Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png`.

Prochain lot exact : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`.

## Mise a jour V1-54

Statut : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0` est DONE.

Decision : V1-54 reste un polish visuel pur demande par Karim. La timeline garde les memes contrats V1-51/V1-52/V1-53, mais devient plus dense : lanes 28px, axe 24px, barres 22px, empty states courts, controles transport medium et metadata strip allegee pour retirer les IDs redondants.

Scope realise : proportions preview/timeline conservees sur surface 1663x926, nouveau test de densite, capture Visual Gate V1-54, tests Builder/Library relances, analyses ciblees vertes, aucun changement runtime/core model.

Limites : pas de playback, timer, seek, scrubber, hover details, drag/drop, resize, reorder, zoom temporel, changement JSON, build_runner ou preview runtime.

Preuve : test widget `renders polished dense timeline on reference surface`, suite Builder `+32`, suite Library `+10`, tests core time layout/lane, analyze cible, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png`. `flutter analyze` complet reste bloque par dette hors scope preexistante dans le convertisseur Pokemon SDK.

Prochain lot exact : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0`.

## Mise a jour V1-55

Statut : `NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0` est DONE.

Decision : V1-55 retient l'option inline compacte, placee au-dessus des lanes, plutot qu'un tooltip fragile. Le hover reste un etat local editor-only derive de la barre survolee ; `selectedStepId` continue de piloter la selection, l'inspecteur et le curseur. V1-56 rend ce detail en overlay non interactif pour ne plus deplacer la grille.

Scope realise : detail `Survol : ...` avec type, piste, debut, duree et infos utiles par bloc, labels humains actorMove/actorFace, highlight doux de la barre survolee quand elle n'est pas selectionnee, label semantic compact, nettoyage du hover a la sortie, test de non-selection/non-mutation et Visual Gate V1-55 en 1663x926.

Limites : pas de focus clavier avance, playback, timer, seek, scrubber, drag/drop, resize, reorder, zoom temporel, mutation JSON, build_runner, changement core/runtime ou preview runtime.

Preuve : test widget `shows hover details without selecting or moving cursor`, suite Builder `+34`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, checks anti-scope et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png`.

Prochain lot exact corrige par demande Karim : `NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0`.

## Mise a jour V1-56

Statut : `NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0` est DONE.

Decision : V1-56 remplace exceptionnellement le lot clavier initialement recommande, a la demande de Karim, pour corriger d'abord la geometrie visuelle de la timeline. Les ticks, les barres et le curseur partagent maintenant la meme origine X ; chaque barre est positionnee par `startMs` et dimensionnee par `visualDurationMs`, avec seulement une largeur minimale compacte pour conserver la lisibilite.

Scope realise : keys de mesure ticks/barres/contenu, largeur de barre factorisee, minimum visuel 72 px, variante `borderRadius` du `PokeMapCard`, barres plus rectangulaires, split preview/timeline responsive, preview sandbox compacte, colonne pistes 128 px, labels de pistes complets, acteurs en label court, axe 34 px, rangées 48 px, barres 36 px, badges en ligne compacte, hover details en overlay stable, controles transport icon-only, grille utile testee, capture Visual Gate V1-56 en 1663x926 et evidence pack dedie.

Limites : pas de navigation clavier/focus avance, playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, mutation JSON, persistance temporelle ou changement core/runtime.

Preuve : tests RED puis GREEN `renders timeline bars with corrected duration geometry` et `balances sandbox preview and useful timeline grid proportions`, suite Builder `+36`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, checks anti-scope et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png`.

Prochain lot exact : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`.

## Mise a jour V1-57

Statut : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0` est DONE.

Decision : le lot transmis par Karim ajoute une navigation clavier strictement locale dans la timeline du Cinematic Builder. Le focus est demande uniquement par interaction avec la timeline ; les touches ArrowRight, ArrowLeft, Home et End changent la selection locale par ordre lineaire `stepIndex`. Si aucune selection n'existe, ArrowRight/Home demarrent au premier bloc et ArrowLeft/End au dernier bloc.

Scope realise : `FocusNode` dedie au panneau timeline, handler `onKeyEvent` local, resolution des blocs par `stepIndex`, badge de focus `Navigation clavier`, selection via `selectedStepId` local, curseur/preview/inspecteur synchronises comme apres clic, bordure de focus pour la barre selectionnee, test de non-mutation, test de protection des `TextField`, capture Visual Gate V1-57 et evidence pack dedie.

Limites : pas de navigation verticale par piste, pas de playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, mutation JSON, persistance temporelle ou changement core/runtime.

Preuve : test RED puis GREEN `navigates selected timeline blocks with local keyboard focus`, test `keeps keyboard shortcuts local and protects text fields`, suite Builder `+39`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, checks anti-scope, screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png`.

Prochain lot exact : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`.

## Mise a jour V1-58

Statut : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract` est DONE.

Decision : V1-58 est un lot documentaire. Il ne code pas ArrowUp/ArrowDown ; il fixe le contrat du futur lot. L'option retenue est Option B : ArrowUp/ArrowDown cherchent la prochaine lane non vide dans la direction verticale, puis selectionnent dans cette lane le bloc dont le centre temporel est le plus proche du centre du bloc courant.

Regles retenues : `centerMs = startMs + visualDurationMs / 2`, comparaison par distance absolue entre centres, tie-break par plus petit `stepIndex` puis ordre stable de blocks, lanes vides ignorees, bords sans lane non vide = selection conservee. Sans selection, ArrowUp selectionnera le dernier bloc de la derniere lane non vide et ArrowDown le premier bloc de la premiere lane non vide. Si `selectedStepId` est introuvable ou si la timeline est vide, le futur handler restera non destructif.

Tests futurs requis : ArrowDown Camera -> lane non vide suivante, ArrowUp acteur -> lane non vide precedente, skip lanes vides, bords top/bottom, tie-break distance puis `stepIndex`, synchro curseur/inspecteur/preview, non-mutation `ProjectManifest`, hover ignore, TextField proteges, navigation horizontale V1-57 et geometrie V1-56 preservees.

Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md`, Gate 0 propre, audit lanes/time layout/V1-57, roadmaps mises a jour, `git diff --check`, anti-scope packages vide et Evidence Pack inclus.

Prochain lot exact : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.

## Mise a jour V1-59

Statut : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0` est DONE.

Decision : V1-59 implemente strictement le contrat V1-58. ArrowUp et ArrowDown utilisent `timeLayout.lanes` dans l'ordre visuel, ignorent les lanes vides, cherchent la prochaine lane non vide au-dessus ou en dessous et choisissent le bloc cible par proximite de `centerMs = startMs + visualDurationMs / 2`. Les tie-breaks restent distance, puis plus petit `stepIndex`, puis ordre stable de lane.

Scope realise : ajout des intents `up`/`down` au handler clavier local de la timeline, helper vertical editor-only, bords stables, fallback sans selection, timeline vide non destructive, badge clavier mis a jour, TextFields proteges, hover ignore comme source de navigation, cursor/preview/inspecteur synchronises par `selectedStepId`.

Limites : pas de playback, timer, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, zoom temporel, preview runtime, persistence temporelle, JSON, build_runner, map_runtime, map_gameplay, map_battle, examples ou mutation `ProjectManifest`.

Preuve : tests RED/GREEN de navigation verticale, tie-break, sans selection/timeline vide et TextFields ; suite Builder `+44`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png` et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`.

## Mise a jour V1-60

Statut : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0` est DONE.

Decision : V1-60 remplace le long badge clavier par `Aide clavier`, un badge compact interactif. Le panneau ouvert par clic vit dans la timeline, explique `← / →`, `↑ / ↓`, `Home` et `End`, et precise `Sélection uniquement — pas de lecture ni déplacement temporel.`

Scope realise : etat local `_timelineKeyboardHelpOpen`, panneau overlay non intrusif, selection/curseur/inspecteur preserves, navigation horizontale V1-57 et verticale V1-59 preservees, TextFields proteges, transports toujours disabled et Visual Gate V1-60.

Limites : pas de playback, timer, seek, scrubber, mouse playhead, drag/drop, resize, reorder, zoom temporel, preview runtime, persistence temporelle, JSON, build_runner, map_runtime, map_gameplay, map_battle, examples ou mutation `ProjectManifest`.

Preuve : RED/GREEN cible du help clavier, suite Builder `+46`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png` et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`.

## Mise a jour V1-61

Statut : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract` est DONE.

Decision : V1-61 retient l'Option B : un futur `Mouse Time Probe` local, visuel et editor-only, distinct du curseur de selection V1-52 et de `selectedStepId`. Il prepare le feeling de montage type Final Cut sans coder le scrubber.

Contrat futur : click axe/fond place le probe ; drag axe/fond le fait suivre la souris ; release fige le temps local ; cancel restaure la position stable ; clic barre selectionne toujours le bloc ; drag barre ne deplace pas le bloc. Conversion souris -> temps : origine X commune ticks/barres/curseur, scroll horizontal, `pixelsPerMs`, clamp `0..totalDurationMs`, snap V0 aux debuts/fins de blocs si proche.

Limites : doc-only, pas de code produit, package, test, screenshot, image IA, scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnee Selbrume.

Preuve : rapport V1-61 complet, Design Gate 28 points, options comparees, tests futurs V1-62, checks anti-scope, `git diff --check` propre et `git diff --name-only -- packages` vide.

Prochain lot exact : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.

## Mise a jour V1-62

Statut : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0` est DONE.

Decision : V1-62 implemente le `Mouse Time Probe` local prevu par V1-61. Le Cinematic Builder stocke un repere temporel editor-only, non persiste, distinct de `selectedStepId` et du playback runtime. Le repere se place par clic ou drag sur l'axe/fond temporel ; les barres restent selectionnables mais non draggables.

Scope realise : conversion X souris -> temps via origine commune V1-56 et scroll horizontal, clamp `0..totalDurationMs`, un seul repere vertical visible, badge `Repere : <temps>`, preview sandbox informative `Repere temporel : <temps>`, clear du probe sur clic de barre ou navigation clavier, inspector stable et non-mutation `ProjectManifest` prouvee.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag/drop de blocs, resize, reorder, persistence `timelineProbeTimeMs`, changement JSON/core, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : suite Builder `+52`, suite Library `+10`, tests core time layout/lane, `dart analyze` core, analyze cible editor, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.png`, checks anti-scope et rapport V1-62 avec Evidence Pack.

Prochain lot exact : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.

## Mise a jour V1-63

Statut : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0` est DONE.

Decision : V1-63 reste un lot documentaire / interaction-contract. Le futur snap V0 recommande est l'Option E : bords `0 ms` / `totalDurationMs` + starts/ends de blocs, jamais ticks arbitraires. Le seuil retenu est `8 px`, derive en ms via `pixelsPerMs`.

Contrat futur : click snap immediat si proche ; drag snap pendant le drag avec indication subtile ; release conserve la derniere position libre ou alignee. Le badge reste `Repere : <temps>`, avec suffixe sobre possible `aligné`, `debut bloc`, `fin bloc`, `debut timeline` ou `fin timeline`.

Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun snap actif, aucun playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag/drop de blocs, resize, reorder, changement JSON/core, runtime, build_runner, image IA ou donnees Selbrume.

Preuve : rapport V1-63 complet avec passes A-I, Design Gate 31 points, options A-E comparees, edge cases de bords/scroll/fallback/blocs proches, tests futurs requis et checks anti-scope documentaires.

Prochain lot exact : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.

## Mise a jour V1-64

Statut : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0` est DONE.

Decision : V1-64 implemente le snap local du `Mouse Time Probe` selon l'Option E V1-63. Les cibles sont les bords de timeline `0 ms` / `totalDurationMs` et les debuts/fins de blocs derives du read model temporel. Le seuil reste `8 px` et aucun tick arbitraire ne devient une cible.

Scope realise : badge libre `Repere : <temps>`, badge snappe `Repere : <temps> · début timeline / fin timeline / début bloc / fin bloc`, snap au click et pendant le drag, release qui conserve la derniere valeur calculee, scroll horizontal respecte, selection locale et inspecteur preserves, transports toujours disabled, capture Visual Gate V1-64.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag de blocs, resize, reorder, persistance temporelle, changement core/model JSON, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : test RED puis GREEN cible, suite Builder `+58`, Visual Gate `+59`, suite Library `+10`, tests core time layout/lane, analyse core, analyse cible editor, checks anti-scope, `git diff --check` et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png`.

Prochain lot exact : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`.

## Mise a jour V1-65

Statut : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0` est DONE.

Decision : V1-65 ajoute un clear explicite du `Mouse Time Probe` local via le controle `Effacer le repère`, place dans l'en-tete de la timeline pour rester visible et ne pas etre confondu avec les controles de transport. Le clear remet uniquement `timelineProbeTimeMs` et `timelineProbeSnapHint` a `null`.

Scope realise : bouton visible seulement avec probe actif, micro-explication compacte `Repère local : inspection uniquement.`, retour au badge/curseur `Selection` quand un bloc reste selectionne, etat vide sans marqueur quand aucune selection n'existe, Escape local quand la timeline a le focus, protection des TextFields, snap/click/drag reutilisables apres clear, hover/aide/transports preserves, capture Visual Gate V1-65.

Limites : pas de playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag de blocs, resize, reorder, persistance temporelle, changement core/model JSON, build_runner, runtime/gameplay/battle/examples, image IA ou donnees Selbrume.

Preuve : test RED puis GREEN cible, suite Builder/Visual Gate `+65`, suite Library `+10`, tests core time layout/lane `+6`, analyse core, analyse cible editor, checks anti-scope, `git diff --check` et capture `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png`. `flutter analyze` global `map_editor` reste rouge sur des erreurs preexistantes hors lot dans les services Pokemon SDK.

Lot suivant realise ensuite : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`.

## Mise a jour V1-66

Statut : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0` est DONE.

Decision : V1-66 ajoute une aide locale courte pour le repere souris, a la demande du prompt du lot. Le controle `Aide repère` apparait seulement quand `timelineProbeTimeMs` existe et reste place dans l'en-tete de timeline pres de `Effacer le repère`, sans toucher a l'inspecteur ni aux transports.

Scope realise : panneau `Aide repère` toggle local, contenu no-code `Sélection : bloc inspecté.`, `Repère : position temporelle locale.`, `Alignement : repère calé sur une borne utile.` et `Preview : lecture réelle à venir.`, coexistence avec `Aide clavier`, selection/repere/projet preserves, clear et Escape fonctionnels apres ouverture, TextFields/hover/snap/transports preserves.

Limites : pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/drop, resize, reorder, runtime, mutation JSON, changement de modele core, `ProjectManifest` ou `map_core`.

Preuve : test RED puis GREEN `shows local time probe help explaining selection and probe`, test `clears local time probe with Escape after probe help is open`, suite Builder, suite Library, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png`, tests core time layout/lane, `dart analyze` core, analyse cible editor et checks anti-scope. L'analyse globale `map_editor` reste rouge par dette preexistante hors lot.

Trajectoire corrigee par demande Karim : le lot suivant devient `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, et le scroll/visibility polish est repousse en backlog futur.

## Mise a jour V1-67

Statut : `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` est DONE.

Decision : V1-67 remplace le scroll/visibility polish immediat par un contrat documentaire de rythme cinematic. Le contrat retient l'Option C : edition de `durationMs` depuis l'inspecteur en V1-68, puis resize souris par bord droit en V1-69.

Scope realise : audit du modele `CinematicTimelineStep.durationMs`, des blocs authoring-owned, du time layout derive `startMs/endMs`, du probe souris V1-62/V1-64/V1-65/V1-66, definition des blocs editables/non editables, bornes min/max, presets, relation avec le probe et tests futurs.

Limites : pas de code produit, pas de package modifie, pas de test, pas de screenshot, pas de resize actif, pas de playback, pas de timeline libre, pas de `startMs/endMs` persistants.

Prochain lot exact : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`.

## Mise a jour V1-68

Statut : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0` est DONE.

Decision : l'edition inspecteur est livree pour les blocs authoring-owned supportes. `actorFace` accepte maintenant une duree explicite via operation authoring core, et `actorMove` garde son minimum specifique de 200 ms.

Scope realise : validation core `100/200..30000`, champ numerique ms, presets `100/250/500/1000/1500/2000/3000`, increment/decrement 100 ms, validation inline sans mutation invalide, clear du probe local apres mutation acceptee, selection preservee, Visual Gate V1-68.

Preuve : rapport V1-68, tests core authoring `+34`, suite Builder+Library `+80`, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.png`, analyse cible editor verte et `map_core` analyze vert.

Prochain lot exact : `NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0`.

## Mise a jour V1-31

Statut : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0` est DONE.

Decision : l'ActionNode devient authorable seulement comme porteur de `SceneConsequence` typée V0. L'UI ne propose pas de script libre, pas d'ID tape a la main et pas d'action generique. Les deux consequences autorisees sont `setFact(factId, value)` via `ProjectManifest.facts` et `markEventConsumed(mapId, eventId)` via les events reels de la map active.

Scope realise : operations pures `addSceneConsequenceActionNodeDraft` et `updateSceneActionConsequencePayload`, port `Action.completed` authorable et diagnostique, palette Action/Conséquence active seulement quand une cible reelle existe, pickers Facts/events, edition inspecteur, update en memoire de `ProjectManifest.scenes`, tests core/editor et visual gate.

Limites : pas de `giveItem`, `warpPlayer`, completion de StoryStep, World Rule direct apply, BranchByOutcome, Yarn outcomes, Cinematic authoring, runtime Scene, GameState mutation depuis editor, `MapEventPage.sceneTarget` ou `StorylineStep.sceneLinkIds`.

Prochain lot exact : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`.

## Mise a jour V1-31-bis

Statut : `NS-SCENES-V1-31-bis — Scene Consequence Runtime Evidence Sweep` est DONE.

Decision : V1-31 est confirme par evidence runtime. Les ActionNode typés consequence restent diagnostiques correctement, compilent en intent `applyConsequence`, sont executes par `SceneRuntimeExecutor` via callback `applyConsequence`, puis sont stages/commits par `SceneEventRuntimeHook` et `SceneConsequenceRuntimeWriter` comme avant.

Preuve : tests `scene_consequence_model`, authoring operations, diagnostics, runtime-plan, runtime-executor, writer runtime, hook runtime, golden smoke, Scenes workspace, overview/projection et analyses ciblees relances. Les checks anti-scope confirment qu'aucun fichier `map_runtime`, `map_battle`, `map_gameplay`, `examples` ou `selbrume` n'est modifie par le bis.

Limites : aucune feature, aucun runtime nouveau, aucun `PlayableMapGame`, `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter`, `GameState`, BranchByOutcome, outcome Yarn, World Rule direct apply ou donnee Selbrume n'est ajoute.

Prochain lot exact : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`.

## Mise a jour V1-32

Statut : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint` est DONE.

Verdict : Scene V1 est prete pour une beta controlee du Scene Builder et pour un smoke runtime neutre. Elle n'est pas encore prete pour une beta golden-slice jouable complete dans `PlayableMapGame`.

Readiness : authoring graph, payloads Dialogue/Battle, Conditions, Facts, World Rules authoring, Event -> Scene hook, RuntimePlan, RuntimeExecutor, consequences runtime, dialogue awaitable, battle awaitable et golden smoke sont acceptables. Les verrous restants sont la persistance ciblee des writes Scene apres save/reload, la projection runtime des World Rules apres ces writes, puis un vrai parcours jouable Flame/overlay.

Decision roadmap : le prochain lot exact devient `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`. Il doit prouver que les facts et events consumed ecrits par Scene survivent a la sauvegarde/recharge et restent consommables par Conditions et World Rules. Les lots World Rules runtime projection, golden slice playable runtime prep et diagnostics UX viennent ensuite.

Limites confirmees : pas de BranchByOutcome, pas d'outcomes Yarn detailles, Cinematic encore bridge/provisoire, pas de completion StoryStep runtime depuis Scene, Facts overview encore a aligner, pas de suppression clavier/undo-redo graph, pas de World Rules runtime apply.

Prochain lot exact : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.

## Mise a jour V1-33

Statut : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0` est DONE.

Decision : V1-33 ajoute un gate runtime cible qui relie les vraies briques `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter`, `FileGameSaveRepository`, `LoadGameUseCase`, Conditions Scene V1 et `projectWorldRuleEffects`. Le test prouve que `setFact` et `markEventConsumed` ecrits par une Scene completee sont sauvegardes, recharges, puis relus sans mutation par une Condition et par une projection World Rules pure.

Limites : aucun hook World Rules runtime n'est branche, aucune application visuelle du monde n'est faite, aucun nouveau payload/consequence n'est ajoute, aucun `PlayableMapGame` golden slice complet n'est code, aucune donnee Selbrume n'est creee et aucun package editor/battle/gameplay/examples n'est modifie.

Prochain lot exact : `NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0`.

## Mise a jour V1-34

Statut : `NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0` est DONE.

Decision : V1-34 ajoute un hook runtime borne pour transformer les effets de `projectWorldRuleEffects` en read model runtime applique au monde jouable. Les effets V0 supportes pilotent la presence/visibilite d'entites, les events `enabled/disabled/hidden` et les overrides de dialogue PNJ. La projection est relue depuis le `GameState` courant ou recharge, et ne mute jamais les sources.

Integration runtime : `PlayableMapGame` combine la presence PNJ existante avec la projection World Rules, resout un override de dialogue PNJ si une rule active le demande, bloque les interactions d'events disabled/hidden et rafraichit la presence PNJ apres une Scene qui commit un nouveau `GameState`.

Limites : pas de nouveau modele, pas de manager UI, pas de Fact/World Rule authoring nouveau, pas de World Rule qui ecrit dans `GameState`, pas de completion StoryStep, pas de BranchByOutcome, pas de donnees Selbrume et aucun package editor/battle/gameplay/examples modifie par V1-34.

Prochain lot exact realise : `NS-SCENES-V1-35 — Facts & World Rules Manager UI V0`.

## Mise a jour V1-35

Statut : `NS-SCENES-V1-35 — Facts & World Rules Manager UI V0` est DONE.

Decision : Facts et Regles du monde disposent maintenant d'un manager central no-code dans Narrative Studio. Les deux entrees de sidebar sont actives et ouvrent un workspace partage en onglets, avec compteurs, liste, recherche, edition guidee, phrase humaine de World Rule, diagnostics et usages de Facts.

Scope realise : read model pur `FactsWorldRulesManagerReadModel`, garde de suppression `removeNarrativeFact` etendue aux usages Scene consequence / World Rule, workspace editor Facts/World Rules, mutations en memoire via `EditorNotifier.applyInMemoryProjectManifest`, overview aligne, tests core/editor et visual gate V1-35. Les goldens Scene Builder historiques ont ete regeneres car le chrome Narrative Studio commun affiche maintenant Facts et Regles du monde comme entrees actives.

Limites : pas de runtime modifie, pas de nouveau type de Fact ou World Rule, pas de nouvel effet, pas de nouvelle SceneConsequence, pas de GameState mute depuis l'editor, pas de seed Selbrume, pas de workflow principal par ID technique.

Prochain lot exact : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`.

## Mise a jour V1-36

Statut : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision` est DONE.

Decision : Cinematic V1 est un futur asset canonique dedie, lineaire, visuel, referencable par Scene et diagnostiquable. Il ne branche pas, ne produit pas directement des Facts ou World Rules, ne lance pas de combat et ne remplace pas Dialogue Yarn. `ScenarioAsset` reste un bridge legacy explicite ; Cutscene Studio reste utilisable comme source/bridge transitoire, mais son schema plus large ne dicte pas Cinematic V1.

Scope realise : audit documentaire du modele cible, de Cutscene Studio, `ScenarioAsset`, `ScenarioRuntimeExecutor`, `SceneRuntimePlan.playCinematic`, `CinematicPublicContract.scenarioBridge`, et decision de roadmap avant Cinematics Library / Cinematic Builder V2.

Limites : aucun code, aucun widget, aucun modele Dart, aucune migration, aucun runtime cinematic nouveau, aucun seed Selbrume et aucune promotion implicite de `ScenarioAsset`.

Prochain lot exact : `NS-SCENES-V1-37 — CinematicAsset Core Model V0`.

## Mise a jour V1-37

Statut : `NS-SCENES-V1-37 — CinematicAsset Core Model V0` est DONE.

Decision : Cinematic V1 dispose maintenant d'un modele core canonique dedie, distinct de `ScenarioAsset`. `CinematicAsset` reste lineaire, visuel, sans graph, sans branch, sans consequence gameplay et sans runtime direct. `ProjectManifest.cinematics` stocke les assets canoniques ; `ProjectManifest.scenarios` reste preserve comme legacy/bridge.

Scope realise : modele `CinematicAsset`, `CinematicTimeline`, `CinematicTimelineStep`, acteurs requis, bridge legacy optionnel, JSON/serialization, operations authoring pures, diagnostics cinematic, `CinematicPublicContract` canonique + `scenarioBridge`, diagnostic Scene project-aware pour distinguer canonical vs bridge.

Limites : aucun widget, aucune Cinematics Library, aucun Builder V2, aucun runtime cinematic, aucune migration Scenario/Cutscene, aucune donnee Selbrume.

Tests/analyze : tests core cibles CinematicAsset, ProjectManifest, authoring operations, diagnostics, linked asset contracts, scene project diagnostics et scene runtime plan ; `dart analyze` map_core vert.

Prochain lot exact : `NS-SCENES-V1-38 — Cinematics Library V0`.

## Mise a jour V1-38

Statut : `NS-SCENES-V1-38 — Cinematics Library V0` est DONE.

Decision : les CinematicAsset canoniques deviennent visibles et navigables dans Narrative Studio via une Library dediee. `ScenarioAsset` / Cutscene Studio reste un bridge legacy explicite, accessible depuis la Library mais jamais promu ni migre silencieusement.

Scope realise : read model pur `buildCinematicsLibraryReadModel`, workspace `CinematicsLibraryWorkspace`, creation shell metadata-only, edition titre/description/notes, suppression protegee des assets non references, usages depuis Scenes, diagnostics cinematic, overview compte canoniques et bridges separement, visual gate.

Limites : pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration Scenario/Cutscene, pas de picker Scene Builder cinematic, pas de donnee Selbrume.

Lot suivant realise : `NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0`.

## Mise a jour V1-39

Statut : `NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0` est DONE.

Decision : le Scene Builder consomme uniquement les `CinematicAsset` canoniques pour creer ou modifier un `CinematicNode`. Les `ScenarioAsset` / Cutscene Studio restent visibles comme bridges legacy informatifs et diagnostiques, sans workflow normal de creation.

Scope realise : operations pures `addSceneCinematicNodeDraft` et `updateSceneCinematicPayload`, picker canonical-only, palette Cinématique active seulement avec au moins un `CinematicAsset`, inspector cinematic, `cinematic.completed` authorable/diagnostique/connectable et visual gate.

Limites : pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration Scenario/Cutscene, pas de promotion bridge legacy, pas de donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`.

## Mise a jour V1-40

Statut : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0` est DONE.

Decision : le workflow runtime normal des `CinematicNode` vise uniquement les `CinematicAsset` canoniques de `ProjectManifest.cinematics`. Le bridge `ScenarioAsset` reste legacy explicite et n'est pas promu comme canonical.

Scope realise : adapter awaitable `SceneCinematicRuntimeAwaitableAdapter`, result/request/player V0, player no-visual borne, wiring `PlayableMapGame`, tests de temporalite avec `Completer`, tests no partial writes pour `setFact` et `markEventConsumed`, unknown cinematic bloque sans write.

Limites : pas de Builder V2, pas de timeline editor, pas de playback visuel complet, pas de migration Scenario/Cutscene, pas de branches skipped/failed authorables, pas de donnee Selbrume.

Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.

## Mise a jour V1-41

Statut : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract` est DONE.

Decision : le futur Cinematic Builder V0 est borne comme assembleur no-code de sequences moteur simples, lineaires, ordonnees et sandboxees. Le futur Runtime Playback V0/V1 lit ces sequences via un host borne, retourne seulement `completed` a la Scene, signale les failures internes sans port authorable et ne peut pas ecrire de Fact, lancer de Battle, appliquer de World Rule, teleporter ou completer une StorylineStep.

Scope realise : rapport contractuel V1-41, audit des lots V1-36 a V1-40, taxonomie des blocs camera/deplacement acteur/dialogue/FX/son/fondu/attente, capability matrix Builder/Runtime/Preview/Validation, frontieres Scene/Cinematic/Dialogue/Battle/Facts/World Rules/ScenarioAsset et roadmap post V1-41.

Limites : aucun code produit, aucun modele Dart, aucun widget Flutter, aucun Builder UI, aucun timeline editor, aucun playback visuel, aucune migration legacy, aucune donnee produit et aucun package modifie. V1-41 n'a pas code le Builder.

Prochain lot exact : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell`.

## Mise a jour V1-42

Statut : `NS-SCENES-V1-42 — Cinematic Builder V0 Shell` est DONE.

Decision : le Cinematic Builder V0 existe comme shell editor local de la Cinematics Library, uniquement pour les `CinematicAsset` canoniques. Il expose une structure claire et read-only : header avec retour Library, palette de blocs verrouillee, apercu sandbox, deroule simplifie et inspecteur placeholder. Les bridges legacy restent visibles dans la Library, mais n'ouvrent pas le Builder canonique.

Scope realise : widget `CinematicBuilderWorkspace`, navigation Library -> Builder -> Library, action Builder sur entree canonique, action indisponible pour bridge legacy, etats timeline vide/existante en lecture seule, boutons Valider/Apercu/Sauvegarder inactifs, screenshot `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_42_cinematic_builder_v0_shell.png`, tests widget cibles.

Limites : aucune edition de timeline, aucune creation/suppression/reorganisation de step, aucun player visuel, aucune mutation de `ProjectManifest`, aucun modele core, aucun package runtime/gameplay/battle/examples modifie et aucune migration legacy.

Prochain lot exact : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0`.

## Mise a jour V1-43

Statut : `NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0` est DONE.

Decision : le Builder consomme le `CinematicAsset` canonique complet depuis la Library pour afficher les steps reels, sans enrichir le read model core. La selection de step reste locale au widget, non persistante, et se remet a zero si la cinematique change ou si le step selectionne n'existe plus.

Scope realise : timeline read-only ordonnee avec index, titre fallback, kind, duree, acteur, cible, assetRef et badge diagnostic ; inspecteur de bloc selectionne avec id, index, kind, duree, actorId, targetId, texte dialogue, asset, metadata, statut preview/runtime lecture seule et diagnostics contextualises ; preview sandbox inchangée avec rappel du bloc selectionne ; palette toujours verrouillee.

Limites : aucune creation de blocs, aucune suppression de blocs, aucun changement d'ordre, aucune sauvegarde de deroule, aucun vrai player visuel, aucune mutation de `ProjectManifest`, aucun changement `map_core`, aucun package runtime/gameplay/battle/examples modifie et aucune migration legacy.

Preuve : tests widget Builder et Library verts, analyse ciblee sans issue, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.png`.

Prochain lot exact : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0`.

## Mise a jour V1-44

Statut : `NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0` est DONE.

Decision : le premier authoring de deroule Cinematic reste volontairement neutre. Un bloc brouillon est un `CinematicTimelineStep.marker` identifie par metadata `authoring.kind=draft` et `authoring.source=cinematic-builder-v0`; il ne porte ni duree, ni acteur, ni cible, ni dialogue, ni asset, ni effet moteur.

Scope realise : operations pures `addCinematicTimelineDraftStep`, `removeCinematicTimelineDraftStep` et `isCinematicTimelineDraftStep`, mutation en memoire de `ProjectManifest.cinematics`, insertion apres selection ou en fin de deroule, selection automatique du brouillon cree, inspecteur lecture seule, bouton d'ajout no-code, suppression disponible seulement pour un brouillon, Library rafraichie.

Limites : aucun vrai bloc Camera/Fondu/Attente/Dialogue/FX/Son/Acteur, aucune edition de champ, aucune gestion d'ordre avancee, aucun player visuel, aucun changement de schema JSON, aucun package gameplay/battle/runtime/examples modifie et aucune migration legacy.

Preuve : tests core authoring et diagnostics verts, tests widget Builder et Library verts, analyse `map_core` et analyse editor ciblee sans issue, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.png`.

Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.

## Mise a jour V1-45

Statut : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0` est DONE.

Decision : `wait`, `fade` et `camera` existaient deja dans `CinematicTimelineStepKind`; V1-45 n'a donc pas change le schema JSON. Les blocs V0 crees par le Builder portent `authoring.source=cinematic-builder-v0`, `authoring.kind=basicBlock` et `authoring.block=wait|fade|camera`.

Scope realise : operations pures d'ajout/update/suppression authoring-owned, edition par presets de duree et modes controles `fadeIn/fadeOut` et `reset/hold`, palette Attente/Fondu/Camera active, suppression des drafts et basic blocks owned, steps non-owned proteges, mutation memoire de `ProjectManifest.cinematics`, Library rafraichie.

Limites : pas de deplacement acteur, pas de dialogue cinematic, pas de FX/Son, pas de cible map complexe, pas de preview runtime, pas de drag/drop, pas de reordonnancement et aucun package runtime/gameplay/battle/examples modifie.

Preuve : tests core authoring et diagnostics, tests widget Builder et Library, analyse core/editor, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png`.

Prochain lot exact : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`.

## Mise a jour V1-46

Statut : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0` est DONE.

Decision : `CinematicActorRef`, `CinematicAsset.requiredActors`, `CinematicTimelineStep.actorId` et `CinematicTimelineStepKind.actorFace` existaient deja. Le lot ajoute donc les operations et l'UI authoring sans migration schema : `addCinematicRequiredActor`, `addCinematicTimelineActorFacingStep`, `updateCinematicTimelineActorFacingStep`, direction V0 `up|down|left|right` et metadata `authoring.source=cinematic-builder-v0`, `authoring.kind=basicBlock`, `authoring.block=actorFace`, `actor.direction=<direction>`.

Scope realise : ajout d'acteur requis avec id stable `actor`, `actor_2`, etc. et label par defaut `Acteur`, bloc `actorFace` cree seulement avec un acteur requis, picker acteur dans l'inspecteur, boutons de direction no-code, badges acteur/direction dans le deroule, refresh Library, diagnostics `cinematicUnknownActorRef` si un step reference un acteur absent.

Limites : pas de `actorMove`, pas de chemin/pathfinding, pas de drag/drop timeline, pas de timeline multi-track, pas de preview runtime, pas de dialogue/FX/Son, aucun package runtime/gameplay/battle/examples modifie et aucune donnee Selbrume.

Preuve : tests core authoring et diagnostics, tests widget Builder et Library, analyse `map_core`, analyse editor ciblee et visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png`.

Prochain lot exact : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.

## Mise a jour V1-47

Statut : `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract` est DONE.

Decision : le lot reste documentaire. `CinematicTimelineStepKind.actorMove` existe deja, tout comme `actorId`, `targetId`, `durationMs` et `metadata`, mais aucun contrat spatial cinematic n'est encore authorable. Le futur `actorMove` V0 devra referencer uniquement `CinematicAsset.requiredActors`, utiliser une cible authoring stable et diagnostiquable, garder `pathMode` borne, ne pas impliquer de pathfinding et rester separe de toute preview/runtime.

Contrat recommande : lane derivee depuis `actorId`, duree par presets bornes, `movementMode` authoring-only (`walk`/`run` comme intention visuelle), `pathMode=direct` en V0, cible V0 sous forme de waypoint/target authoring explicite plutot qu'une position libre ou une entite map runtime brute.

Limites : aucun code Dart, aucun widget Flutter, aucun fichier `packages/`, aucun schema JSON, aucun build_runner, aucun actorMove authorable, aucune position cible codee, aucune lane persistante, aucune preview runtime, aucune donnee Selbrume.

Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_47_cinematic_actor_movement_block_v0_prep_contract.md`, roadmaps seules modifiees, `git diff --check` propre et checks anti-scope confirmant que `packages/`, runtime/gameplay/battle/examples restent intacts.

Prochain lot exact : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0`.

## Mise a jour V1-48

Statut : `NS-SCENES-V1-48 — Cinematic Timeline Lane Grouping V0` est DONE.

Decision : la projection lane vit dans `map_core` comme read model pur, afin de devenir un contrat partage entre Builder, tests et futurs blocs cinematic. Les lanes sont derivees de `CinematicTimeline.steps` et `CinematicAsset.requiredActors`, jamais persistees dans le modele.

Scope realise : `CinematicTimelineLaneReadModel`, lanes stables Camera, Acteurs requis, Dialogue, FX, Audio, Transitions, Temps / Global et Autres, actorId inconnu sans crash, index global preserve, Builder affiche `Timeline par pistes`, selectionne les blocs depuis les lanes, conserve inspecteur/preview/actions V1-45/V1-46 et garde `Déplacement acteur` verrouille.

Limites : pas de lane persistante, pas de drag/drop, pas de reordonnancement, pas d'overlap temporel, pas de `actorMove` authorable, pas de preview runtime, pas de modification runtime/gameplay/battle/examples, pas de donnees Selbrume.

Preuve : tests core `cinematic_timeline_lane_read_model_test.dart` et `cinematics_library_read_model_test.dart`, `dart analyze` map_core, tests widget Builder/Library, analyze editor cible, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.png`.

Prochain lot exact : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0`.

## Mise a jour V1-49

Statut : `NS-SCENES-V1-49 — Cinematic Actor Movement Block V0` est DONE.

Decision : le deplacement acteur V0 devient authorable uniquement via un acteur requis et une cible authoring stable stockee dans `CinematicAsset.movementTargets`. Le step utilise `actorMove`, `actorId`, `targetId`, une duree positive, `actor.movementMode=walk|run` et `actor.pathMode=direct`. Le path mode reste verrouille en direct pour eviter d'ouvrir trop tot pathfinding, courbes ou coordonnees libres.

Scope realise : modele `CinematicMovementTargetRef`, operations pures add/update/remove cible, operations add/update `actorMove`, protection de suppression d'une cible utilisee, diagnostics acteur/cible/duree/modes, read model lane enrichi avec cible/mode, palette Builder active seulement avec acteur et cible, inspecteur acteur/cible/duree/marche-course/pathMode direct, mutation memoire via Library et Visual Gate.

Limites : pas de pathfinding, pas de position `x/y`, pas de cible map/entity runtime, pas de drag/drop, pas de reordonnancement, pas de preview jouable, pas d'edition avancee de label cible dans l'inspecteur, pas de migration legacy, pas de modification runtime/gameplay/battle/examples, pas de donnees Selbrume.

Preuve : tests core `cinematic_asset_test.dart`, `cinematic_authoring_operations_test.dart`, `cinematic_diagnostics_test.dart`, `cinematic_timeline_lane_read_model_test.dart`, tests widget Builder/Library, analyses ciblees et Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_49_cinematic_actor_movement_block_v0.png`.

Prochain lot exact : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0`.

## Mise a jour V1-50

Statut : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0` est DONE.

Decision : V1-50 ne rend pas `actorMove` plus puissant ; il rend l'authoring plus lisible. Les cibles de deplacement gardent leur `targetId` stable, mais leurs labels et descriptions deviennent editables dans le Builder. Les labels actorMove visibles sont derives depuis les refs acteur/cible plutot que de muter le `step.label` persiste.

Scope realise : edition label/description des cibles, suppression d'une cible inutilisee, suppression bloquee et expliquee pour une cible utilisee, pickers acteur/cible plus lisibles, resume humain `Professeur marche vers Centre scene en 1000 ms.`, chemin direct clarifie, timeline par lanes avec titre `Acteur -> Cible`, tests core/editor et Visual Gate `ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.png`.

Limites : pas de time axis, pas de bar layout proportionnel, pas de playhead, pas de transport controls, pas de drag/drop, pas de reordonnancement, pas de coordonnees `x/y`, pas de pathfinding, pas de runtime, pas de preview jouable et pas de donnees produit.

Preuve : tests core authoring/lane, tests widget Builder/Library, analyses ciblees, capture V1-50 et checks anti-scope.

Prochain lot exact : `NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0`.

## Mise a jour V1-30-bis

Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.

Decision : les nodes Scene non-start sont supprimables depuis l'inspecteur Scene Builder. La suppression retire le node cible, ses edges entrants/sortants et les layouts associes, avec confirmation destructive. Le Start reste interdit et le dernier End reste bloque.

Scope realise : core `removeSceneNodeDraft` elargi, helper de blocage de suppression, danger zone inspecteur, update en memoire de `ProjectManifest.scenes`, tests core/editor, visual gate.

Limites : pas de suppression clavier, pas de reconnexion automatique, pas de runtime, pas de modification Storyline/Event/GameState, pas de Consequence UI.

Prochain lot exact : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`.

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

## Mise a jour V1-28-septies

Statut : `NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0` est DONE.

Decision : `SceneRuntimeHostCallbacks.showDialogue` dans `PlayableMapGame` ne retourne plus `completed` immediatement apres l'ouverture du dialogue. Il passe par `SceneDialogueRuntimeAwaitableAdapter`, ouvre le dialogue runtime existant, puis attend le signal reel de fermeture de `DialogueOverlayComponent.onFinished` avant de retourner le port Scene `completed`.

Limites : pas d'outcomes Yarn inventes, pas de BranchByOutcome, pas de parser Yarn, pas de Dialogue Studio, pas de nouvelle consequence, pas de World Rule direct apply, pas de StorylineStep link et pas de donnee Selbrume. L'adapter dialogue ne mute pas `GameState` et n'ecrit aucune consequence Scene.

Tests : adapter dialogue awaitable, hook Scene pending/completed/failure avec consequence stagee, tests core runtime-plan/executor/consequence, analyzes runtime/core, recherches anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`.

## Mise a jour V1-28-octies

Statut : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0` est DONE.

Decision : un smoke test runtime controle prouve maintenant la chaine complete `MapEventPage.sceneTarget -> SceneEventRuntimeHook -> SceneRuntimeExecutor -> SceneDialogueRuntimeAwaitableAdapter -> SceneBattleRuntimeOutcomeAdapter -> SceneConsequenceRuntimeWriter`.

Preuve : la fixture neutre utilise `map_test_runtime`, `event_test_scene`, `scene_test_runtime`, `dialogue_test_intro`, `trainer_test_guard`, `fact_test_scene_victory`, `fact_test_scene_defeat` et `fact_test_event_consumed`. Le test victory prouve que la Scene reste pending tant que le dialogue awaitable n'est pas complete, puis lance le battle awaitable, suit `victory`, stage `setFact` et `markEventConsumed`, et commit le `GameState` seulement apres la fin. Le test defeat suit `defeat` et commit seulement la consequence defeat. Le test failure prouve qu'une consequence stagee avant un battle failure n'est pas commit.

Limites : smoke applicatif hors Flame pour rester deterministe ; pas de StorylineStep link, pas de World Rule direct apply, pas de BranchByOutcome, pas d'outcome Yarn invente, pas de donnees Selbrume produit, pas de modification `map_core/lib/src`, `map_editor`, `map_battle`, `map_gameplay` ou `examples`.

Tests : smoke runtime octies, hook event runtime, adapters dialogue/battle, writer consequences, analyse ciblee runtime, tests core runtime-plan/executor/consequence, `map_core dart analyze`, recherches anti-Selbrume/anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-29 — StorylineStep to Scene Link`.

## Mise a jour V1-29

Statut : `NS-SCENES-V1-29 — StorylineStep to Scene Link` est DONE.

Decision : `StorylineStep.sceneLinkIds` reste un lien authoring/progression, pas un declencheur runtime. Le lot reutilise le champ existant, ajoute des operations pures `linkSceneToStorylineStep`, `unlinkSceneFromStorylineStep`, `replaceStorylineStepSceneLinks` et `clearStorylineStepSceneLinks`, puis expose diagnostics/read model pour afficher scenes liees, refs manquantes, erreurs Scene et readiness runtime-plan sous forme d'information.

Editor : le workspace Storylines permet de lier une Step a des scenes reelles depuis `ProjectManifest.scenes`, d'afficher les scenes liees avec label/id, de retirer un lien et de montrer explicitement que ce lien est authoring/progression only. Aucun bouton ne lance la Scene depuis la Step.

Tests : tests core JSON/operations/diagnostics/read model, `scene_runtime_plan_test.dart`, analyse `map_core`, test widget Storylines scene links, analyse ciblee editor, recherches anti-Selbrume/anti-runtime, visual gate V1-29 et `git diff --check`.

Limites : pas de cross-navigation Scene <-> StorylineStep avancee, pas de completion runtime de Step, pas de `GameState` mutation, pas de remplacement Event -> Scene, pas de World Rule direct apply, pas de BranchByOutcome/Yarn outcomes et pas de donnee Selbrume produit.

Prochain lot initialement prevu : `NS-SCENES-V1-30 — Scene V1 Beta Readiness Checkpoint`. Il est supersede par `NS-SCENES-V1-30 — Scene Node Payload Editing V0`, car les payloads Dialogue/Battle devaient rester corrigeables avant checkpoint beta.

## Mise a jour V1-30

Statut : `NS-SCENES-V1-30 — Scene Node Payload Editing V0` est DONE.

Decision : le Scene Builder peut corriger les references metier deja posees pour Dialogue Yarn et Battle trainer sans ouvrir d'edition brute. Les choix passent par `DialoguePublicContract` et `BattlePublicContract`; l'inspecteur affiche un badge editable seulement quand un contrat public existe, sinon le node reste honnetement en lecture seule.

Scope realise : operations pures `updateSceneYarnDialoguePayload` et `updateSceneBattlePayload` dans `map_core`, pickers inspecteur pour Dialogue/Battle, update en memoire de `ProjectManifest.scenes`, preservation des nodes/edges/layout/outcomes/metadata et visual gate V1-30.

Limites : pas d'outcomes Yarn detailles, pas de `BranchByOutcome`, pas de payload Cinematic/Action avance, pas de runtime, pas de `StorylineStep` runtime, pas de donnees Selbrume.

Preuve : tests core authoring/diagnostics/runtime-plan/contracts, tests widget Scene Builder, overview/projection, analyses ciblees, visual gate V1-30, recherches anti-scope et `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`.

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

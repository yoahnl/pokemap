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

## Prochain lot recommande

`NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`

Raison : V1-61 a cadre le repere temporel souris sans implementation. Le prochain verrou naturel est d'implementer le `Mouse Time Probe` local selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.

Ordre apres V1-61 : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.

Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract, puis Cinematic Timeline Mouse Time Probe / Playhead Drag V0.

Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

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

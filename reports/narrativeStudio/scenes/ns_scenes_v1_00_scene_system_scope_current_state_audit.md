# NS-SCENES-V1-00 — Scene System Scope / Current State Audit

## 1. Executive summary

Verdict global : `NS-SCENES-V1` doit demarrer par un contrat Scene V1 nouveau et explicite, pas par un branchement direct sur l'ancien `ScenarioAsset` ou sur le Cutscene Studio existant.

Niveau de maturite actuel :

- Le runtime possede deja des briques executables utiles : scenarios, scripts, conditions, dialogues, actions, combat handoff, outcomes.
- L'editor possede deja des workspaces narratifs legacy/transitoires : Storylines, Step Studio, Cutscene Studio, Dialogue Studio.
- Le modele produit cible Scene/Event/Cinematic/Yarn/Fact/World Rule n'est pas encore stabilise dans un contrat propre.

Principaux risques :

- Brancher `StorylineStep -> Scene` trop tot sur `ScenarioAsset.localEventFlow`.
- Confondre Scene et Cinematic, surtout parce que le Cutscene Studio actuel orchestre deja des branches/actions.
- Faire de Yarn un moteur cache de progression.
- Revenir a une UX de flags techniques.
- Accumuler de la logique narrative dans `metadata` sans contrat public.

Prochaine etape recommandee : `NS-SCENES-V1-01 — Scene Product Model / Graph Contract`.

## 2. Sources inspectees

| Chemin | Etat | Role suppose | Resume court | Elements utiles pour Scene V1 | Problemes / dette / ambiguities |
|---|---|---|---|---|---|
| `AGENTS.md` | existe | Regles repo | Contraintes package, no-code, design system, git safety, evidence. | Confirme que le lot doit rester scope et documente. | Aucune. |
| `agent_rules.md` | existe | Regles agent locales | Rappelle tests/evidence, interdiction d'inventer, discipline git. | Cadre l'audit et le rapport. | Aucune. |
| `skills/README.md` | existe | Index de workflows | Liste les workflows locaux de planification, debug, verification. | Confirme evidence avant conclusion. | Aucune. |
| `reports/narrativeStudio/storylines/road_map_storylines.md` | existe | Roadmap Storylines | Storylines V1/V1.1 ferme avec limitations, Scenes comme prochain chantier. | Confirme de ne pas rouvrir Storylines. | Historique riche mais non source de Scene V1. |
| `reports/narrativeStudio/storylines/ns_storylines_v1_checkpoint_acceptance.md` | absent au chemin demande | Rapport checkpoint ancien emplacement | Fichier absent au chemin racine demande. | Aucun a ce chemin. | Rapport relocalise sous `reports/narrativeStudio/storylines/v1/`. |
| `reports/narrativeStudio/storylines/v1/ns_storylines_v1_checkpoint_acceptance.md` | existe | Checkpoint Storylines V1 | Verdict `ACCEPTED WITH LIMITATIONS`; manque scenes, scene links, outcomes, facts/world rules, validation. | Justifie NS-SCENES-V1. | Mentionne une phase Scene Placeholder plus large ; ce lot affine vers audit/contract first. |
| `reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md` | existe | Seed Selbrume Storylines | Seed data-only : 1 main, 3 side quests, chapters/steps, relationships, 0 SceneLink. | Selbrume est exemple produit, pas source de code. | Ne doit pas etre transforme en scene fake ici. |
| `reports/narrativeStudio/storylines/ns_storylines_structure_bis_full_width_accordion_authoring.md` | existe | Rapport Structure V1.1 | Confirme accordions, edit/delete, reorder steps, `Lier une scene` disabled. | Montre que Storylines est assez bon pour attendre Scene V1. | SceneLink volontairement bloque, decision a conserver. |
| `MVP Selbrume/narrative_studio.md` | existe | Source produit narrative | Definit la grammaire cible, Scene, Event, Cinematic, Yarn, Fact, World Rule, Validator. | Source la plus claire pour Scene V1. | Quelques exemples Selbrume ne doivent pas devenir des donnees hardcodees. |
| `packages/map_core/lib/src/models/scenario_asset.dart` | existe | Modele scenario graph legacy | `ScenarioAsset`, `ScenarioNode`, `ScenarioEdge`, scopes `globalStory`/`localEventFlow`. | Graph, nodes, edges, outcomes, conditions. | Trop generique et semantiquement melange : global story, event flow, scene-like execution. |
| `packages/map_core/lib/src/models/script_asset.dart` | existe | Commandes runtime | `ScriptAsset`, `ScriptNode`, `ScriptCommand`, `YarnDialogueRef`. | Backend d'actions reusable. | Bas niveau, pas UX Scene Builder. |
| `packages/map_core/lib/src/models/script_conditions.dart` | existe | Conditions pures | Conditions flags, variables, party, map, event consumed. | Base technique pour ConditionNode. | UX doit wrapper en Facts/conditions lisibles. |
| `packages/map_core/lib/src/models/project_manifest.dart` | existe | Racine projet | Contient dialogues, scripts, scenarios, storylines, trainers, etc. | Montre qu'il n'y a pas encore de liste `scenes`. | Decision storage Scene V1 reste ouverte. |
| `packages/map_core/lib/src/models/game_state.dart` | existe | Etat runtime persistant | Story flags, variables, progression, consumed events, current map. | Cible d'execution et persistence. | Flags/variables ne doivent pas etre UX principale. |
| `packages/map_core/lib/src/models/map_event_definition.dart` | existe | Event map a pages | Event + pages conditionnelles + script/message. | Base Event V1 possible. | Event actuel lance scripts/messages, pas Scene V1. |
| `packages/map_core/lib/src/validation/validators.dart` | existe | Validation projet | Valide scenarios, dialogues, refs, graph edges, scopes. | Diagnostics reutilisables conceptuellement. | Validation couplee a `ScenarioAsset`. |
| `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart` | existe | Draft scenario authoring | Source + actions simples setFlag/completeStep/emitOutcome/battle. | Bon embryon de grammaire Quand/Alors. | Encore scenario-centric et technique. |
| `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart` | existe | Draft event source | Convertit options map/trigger/entity/outcome vers source scenario. | Base Event->Scene future. | Produit encore un draft scenario, pas une Scene. |
| `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart` | existe | Draft outcomes | Ajout/validation outcomes et battle outcome flags. | Distinction scenario outcome / battle outcome. | Outcomes encodes en flags, a wrapper. |
| `packages/map_core/lib/map_core.dart` | existe | Barrel core | Exporte scripts, conditions, scenarios, storylines, validation, authoring. | Confirme API publique actuelle. | Scene V1 necessitera une decision d'export plus tard, pas ici. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | existe | Router UI Narrative Studio | Route Overview, Storylines, Step, Cutscene, Dialogue. | Emplacement futur shell Scenes. | Pas de workspace Scenes aujourd'hui. |
| `packages/map_editor/lib/src/ui/canvas/narrative_library_panel.dart` | absent | Ancien panneau attendu | Fichier absent. | Aucun. | La navigation narrative actuelle est ailleurs. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart` | existe | Etat workspace narratif | Enum `globalStory`, `step`, `cutscene`; selections. | A etendre plus tard pour Scenes. | Pas de selection scene. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart` | existe | Providers projection | Projection UI depuis `ProjectManifest`. | Pattern read-model utile. | Projection legacy centree scenarios. |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | existe | Projection narrative legacy | Derive globalStories/localEventFlows/steps/outcomes depuis scenarios. | Pattern de read model. | Ne doit pas devenir domaine Scene V1. |
| `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart` | existe | Ancien Step Studio | Regles activation/completion/cutscene links/world changes en metadata. | Lecons de vocabulaire humain. | Remplace par Storylines V1 pour structure; metadata legacy. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart` | existe | Cutscene Studio authoring | Blocs dialogue/movement/transition/gameplay/logic, flow avec branches. | Palette et runtime support utiles. | Nom "Cutscene" couvre deja une Scene-like orchestration. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart` | existe | Compilation Cutscene -> Scenario | Compile flow/choices/merge vers `ScenarioAsset`. | Strategie de compilation possible. | Lie fortement UX a `ScenarioAsset` et placeholders. |
| `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` | existe | Workspace Storylines | Storylines V1/V1.1 authoring. | Confirme `Lier une scene` reste disabled. | Ne pas modifier dans ce lot. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart` | existe | Structure Storylines | Accordions, edit/delete/reorder steps, scene link notice. | Confirme frontiere avec Scenes. | Aucun branchement Scene. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart` | existe | Graph Storylines | Graph read-only. | Montre pattern canvas/read-only. | Non concerne par Scenes V1-00. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart` | existe | Model graph Storylines | Nodes/edges Storyline/Chapter/Step/SideQuest. | Exemple de VM feature-specific. | Ne doit pas etre reutilise pour SceneGraph. |
| `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart` | existe | Painter graph Storylines | Edges author order/sidequest. | Exemple visuel, pas contrat Scene. | Non modifie. |
| `packages/map_gameplay/lib/src/script_condition_evaluator.dart` | existe | Eval conditions pure | Evalue `ScriptCondition` sur `GameState`. | Reutilisable pour ConditionNode runtime. | Erreurs potentielles si conditions exposees brutes. |
| `packages/map_gameplay/lib/src/event_page_resolver.dart` | existe | Resolution Event page | Premiere page active selon conditions. | Reutilisable pour Event V1. | Event lance script/message, pas Scene. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | existe | Runtime scenario models | Source events, effects dialogue/script/message/battle, context callbacks. | Bridge runtime potentiel. | Nom et contrat Scenario MVP, pas Scene V1. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | existe | Executor Scenario | Dispatch map/trigger/entity/outcome, actions, condition, battle handoff. | Execution substrate important. | Support partiel; choice/reference non-source limites. |
| `packages/map_runtime/lib/src/application/resolve_dialogue.dart` | existe | Resolution dialogue projet | DialogueRef -> fichier Yarn + start node. | Dialogue/Yarn integration. | Ne gere pas outcomes Scene directement. |
| `packages/map_runtime/lib/src/application/cutscene_runtime_models.dart` | existe | Runtime cutscene models | Timeline/steps avec branches/gotos/outcomes. | Execution cinematic/script historique. | Productivement trop proche d'une Scene, donc a clarifier. |
| `packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart` | existe | Runner cutscene | Execute dialogue, choices, labels/gotos, movement, outcomes, flags. | Peut inspirer runtime orchestration. | Le nom Cinematic/Cutscene est trompeur si branchement. |
| `packages/map_runtime/lib/src/application/script_runtime_controller.dart` | existe | Controller scripts | Execute `ScriptAsset` nodes/commands. | Action backend. | Bas niveau. |
| `packages/map_runtime/lib/src/application/script_command_executor.dart` | existe | Executor commands | Execute dialogue, warp, give item, flags, variables, consumed event. | ActionNode backend. | Technique, a masquer en no-code. |
| `packages/map_runtime/` | inspecte par recherches ciblees | Runtime Flutter/Flame | Dialogue overlay, scenario dispatch, battle handoff. | Execution cible future. | Ne doit pas etre modifie dans V1-00. |
| `packages/map_gameplay/` | inspecte par recherches ciblees | Pure gameplay | Conditions, event page resolver, mutations. | Pure layer reutilisable. | Scene V1 ne doit pas mettre logique gameplay dans editor. |

Fichiers absents attendus :

- `reports/narrativeStudio/storylines/ns_storylines_v1_checkpoint_acceptance.md`
  - Impact : le checkpoint existe sous `reports/narrativeStudio/storylines/v1/ns_storylines_v1_checkpoint_acceptance.md`; l'audit utilise ce fichier relocalise.
- `packages/map_editor/lib/src/ui/canvas/narrative_library_panel.dart`
  - Impact : le Narrative Studio actuel n'utilise pas ce fichier ; l'audit se base sur `narrative_workspace_canvas.dart` et les providers narratifs.
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_models.dart`
  - Impact : le modele Cutscene Studio existe sous `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart`.

## 3. Current state map

### ScenarioAsset

`ScenarioAsset` est le graphe narratif executable existant. Il contient un scope (`globalStory` ou `localEventFlow`), un `entryNodeId`, des outcomes declares, une condition d'activation, des nodes, des edges et des metadata.

Forces :

- Graphe deja serialisable.
- Nodes/edges existants.
- Scopes distinguant global story et event flow.
- Validateur de graphe existant.
- Runtime bridge partiel existant.

Limites :

- Scope produit ambigu : global story, local event flow, cutscene-like flow et scene-like orchestration se croisent.
- Nodes generiques (`start`, `dialogue`, `action`, `condition`, `choice`, `reference`, `end`) insuffisamment typables pour un Scene Builder professionnel.
- Payload/actionKind/metadata portent beaucoup de sens implicite.

### ScriptAsset

`ScriptAsset` represente une sequence de commandes techniques. Il sait ouvrir un dialogue Yarn, attendre, poser des flags, modifier variables, warper, donner item, unlock ability et consommer un event.

Forces :

- Backend d'actions clair pour runtime.
- Peut servir de cible d'un `ActionNode`.

Limites :

- Trop bas niveau pour l'UX Scene Builder.
- Ne porte pas la semantique SceneGraph.

### ScriptConditions

`ScriptCondition` est un langage pur de conditions (`allOf`, `anyOf`, flags, variables, party, event consumed, player map).

Forces :

- Reutilisable pour conditions runtime.
- Evaluateur pur dans `map_gameplay`.

Limites :

- UX exposee telle quelle serait trop technique.
- Les futures Facts/World Rules doivent encapsuler les flags.

### GameState

`GameState` contient les story flags, variables, consumed events, progression, current map et donnees gameplay.

Forces :

- Cible concrete pour persistence et execution.
- Peut stocker les consequences produites par Scene V1.

Limites :

- Les concepts auteurs ne doivent pas devenir `storyFlags` bruts.

### ProjectManifest

`ProjectManifest` contient deja `dialogues`, `scripts`, `scenarios` et `storylines`. Il ne contient pas encore `scenes`.

Implication :

- NS-SCENES-V1-02 doit decider storage/read model.
- Aucun ajout `ProjectManifest.scenes` dans V1-00.

### Narrative workspace editor

Le workspace narratif route aujourd'hui :

- Overview
- Storylines
- Step
- Cutscene
- Dialogue

Il n'y a pas de workspace `Scenes` dedie. L'etat narratif connait `globalStory`, `step`, `cutscene`, mais pas `scene`.

### Runtime scenario/event execution

`ScenarioRuntimeExecutor` dispatch sur sources `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived`. Il peut declencher dialogue, script, message, actions, battle effect, outcomes et completeStep.

Ce runtime est une base utile, mais il faut le considerer comme un bridge MVP legacy/adaptable, pas comme le contrat produit Scene V1.

### Dialogue / Yarn integration

Le projet contient `ProjectDialogueEntry`, `DialogueRef`, resolution de fichier Yarn et start node. Yarn est donc deja une ressource narrative reconnue.

Il manque encore un contrat clair : Yarn produit des outcomes lisibles, la Scene les lit, puis la Scene decide.

### Battle handoff

`ScenarioRuntimeExecutor` possede `startTrainerBattle` qui retourne un `ScenarioRuntimeEffectType.battle`. `PlayableMapGame` gere ensuite le handoff battle et reprend le scenario.

Scene V1 peut reutiliser ce principe, mais doit typer explicitement `BattleNode` et ses sorties victoire/defaite.

### Cutscene / cinematic existant

Deux couches existent :

- Cutscene Studio editor : blocs et flow guide compile vers `ScenarioAsset`.
- Cutscene runtime : steps avec dialogue, choix, labels, goto, flags, outcomes, movement, waits.

Dette produit majeure : l'existant "cutscene" branche et orchestre deja. La cible canonique dit pourtant :

- Scene = graph d'orchestration qui peut brancher.
- Cinematic = sequence visuelle lineaire qui ne branche pas.

## 4. Legacy / reusable / replace classification

| Item | Classement | Raison | Risque | Condition de reutilisation | Impact Scene V1 |
|---|---|---|---|---|---|
| `StorylineAsset` | KEEP | Source authoring Storylines V1. | Aucun si non modifie. | Rester hors Scene V1-00. | Futur lien apres Scene stable. |
| `StorylineStep.sceneLinkIds` | ADAPT LATER | Champ futur utile. | Liaison prematuree vers ancien scenario. | Attendre V1-10 Scene link. | Ne pas brancher maintenant. |
| `ScenarioAsset` | ADAPT / WRAP | Graphe executable utile. | Devient Scene V1 par accident. | Wrapper ou migrer apres contrat SceneGraph. | Inspiration technique, pas modele produit final par defaut. |
| `ScenarioNode` / `ScenarioEdge` | ADAPT | Primitives graph existantes. | Trop generiques. | Mapper explicitement depuis SceneNode types. | Peut inspirer serialization/runtime adapter. |
| `ScenarioRuntimeExecutor` | WRAP | Bridge runtime deja branche. | Support partiel, noms legacy. | Adapter apres SceneGraph stable. | Runtime prep V1-09. |
| `ScriptAsset` | WRAP | Bon backend d'actions. | UX trop technique. | ActionNode peut appeler script explicitement. | Backend optionnel. |
| `ScriptCommand` | WRAP | Effets runtime concrets. | Commandes exposees brutes. | Construire actions no-code au-dessus. | ActionNode implementation detail. |
| `ScriptCondition` | KEEP / WRAP | Langage pur de conditions. | Flags techniques visibles. | Conditions auteurs doivent compiler vers cette forme. | ConditionNode backend. |
| `ScriptConditionEvaluator` | KEEP | Pure et testable. | Aucun si wrapper. | Utiliser dans runtime Scene. | Base execution conditions. |
| `MapEventDefinition` | ADAPT | Event map a pages. | Event confondu avec Scene. | Event doit declencher Scene, pas porter toute la sequence. | Futur Event -> Scene pipeline. |
| `EventPageResolver` | KEEP / WRAP | Resolution pure de page active. | Conditions trop techniques. | Integrer facts/world rules plus tard. | Base Event V1. |
| `ProjectManifest.scenarios` | DEPRECATE LATER / COMPAT | Stockage actuel scenario. | Melange legacy/futur. | V1-02 decide scenes storage. | Ne pas surcharger sans decision. |
| `ProjectManifest.dialogues` | KEEP | Bibliotheque Yarn/dialogues. | Yarn peut porter trop de progression. | Scene lit outcomes, Yarn ne persiste pas tout. | DialogueNode/YarnNode refs. |
| `ProjectManifest.scripts` | KEEP / WRAP | Scripts projet existants. | Script brut comme UX principale. | Utiliser comme action avancee. | ActionNode optionnel. |
| `ProjectManifest.trainers` | KEEP | Combat refs. | BattleNode sans refs valides. | Picker/validator. | BattleNode. |
| `GameState.storyFlags` | WRAP | Persistence simple. | UX flags brute. | Introduire Fact authoring. | Fact backend possible. |
| `GameState.progression.completedStepIds` | ADAPT | Completion steps runtime. | Couplage direct Scene->Storyline avant temps. | Apres Scene link stable. | Consequence future. |
| Step Studio authoring metadata | DEPRECATE / MINE FOR IDEAS | Ancien vocabulaire activation/completion utile. | Metadata JSON non modele propre. | Reprendre termes, pas stockage. | Reference produit. |
| Cutscene Studio editor | ADAPT / DEPRECATE | Palette et UX guide utiles. | Nom/semantique Cutscene brouille Scene. | Extraire idees de node palette. | Ne pas brancher tel quel. |
| Cutscene Studio compiler | ADAPT | Compile flow vers scenario. | Force Scene V1 a rester ScenarioAsset. | Utiliser comme reference de migration/adapter. | Decision V1-02/V1-09. |
| Cutscene runtime models/runner | WRAP / ADAPT | Execution sequence deja riche. | Branches dans "cinematic". | Clarifier Cinematic lineaire vs Scene graph. | Runtime implementation detail possible. |
| NarrativeWorkspaceProjection | ADAPT | Read model centralise. | Projection legacy scenario = domaine. | Nouveau read model Scenes. | Pattern UI. |
| Dialogue resolution runtime | KEEP | DialogueId -> Yarn file/start node. | Outcomes Yarn pas modelises ici. | Dialogue/Yarn node doit ajouter outputs. | DialogueNode backend. |
| Battle handoff scenario action | WRAP | Runtime sait suspendre et lancer battle. | Outcomes battle encodes en flags. | BattleNode explicit victory/defeat. | Reutilisation probable. |

## 5. Definition Scene V1 proposee

Une Scene V1 est une sequence logique authorable, composee de nodes et de transitions, qui orchestre une interaction narrative executable.

Elle contient :

- Un identifiant stable.
- Un titre, une description et des notes auteur.
- Un graphe `SceneGraph`.
- Un node de debut.
- Un ou plusieurs nodes de fin.
- Des nodes typés : dialogue/Yarn, action, condition, combat, cinematic, choix, branche par outcome.
- Des edges typés : default, true/false, dialogue outcome, battle victory/defeat, completed, invalid/blocked.
- Des references vers ressources existantes : dialogue, script, trainer/battle, cinematic future, facts/world rules futures.
- Des outcomes explicites de scene.
- Des diagnostics d'authoring.

Elle ne contient pas :

- Toute la storyline.
- L'organisation chapter/step.
- Le declencheur map complet.
- Le texte Yarn complet.
- Une cinematic timeline complete.
- Les facts/world rules comme blobs metadata.
- Les maps ou runtime Flame.
- Des donnees Selbrume hardcodees.

Elle orchestre :

- Dialogue Yarn.
- Actions runtime.
- Conditions.
- Combats.
- Cinematiques lineaires.
- Choix et branches locales.
- Consequences.
- Outcomes de scene.

Elle produit :

- Des `SceneOutcome` explicites.
- Des demandes de mutation runtime : fact set, item, transition, story step completion apres lien stable.
- Des diagnostics si incomplet.

Expose a l'editeur :

- Arborescence de scenes.
- Canvas graph.
- Palette de nodes.
- Inspecteur de node.
- Validation de references et transitions.
- Empty states honnetes.

Expose au runtime :

- Un read model executable.
- Un point d'entree.
- Des effets a executer.
- Des sorties/outcomes.
- Des erreurs bloquantes explicites.

## 6. Boundaries product model

| Concept | Responsabilite | Exemple utilisateur | Equivalent technique possible | Ne doit pas faire | Relations |
|---|---|---|---|---|---|
| Storyline | Ligne narrative complete. | "La brume du phare". | `StorylineAsset`. | Executer les actions runtime. | Contient chapters. |
| Chapter | Organisation d'une storyline. | "Les marais". | `StorylineChapter`. | Porter des conditions runtime complexes. | Contient story steps. |
| Story Step | Jalon de progression narrative. | "Convaincre Soline d'ouvrir le passage". | `StorylineStep`. | Devenir une scene ou un event. | Lie plus tard a Scene(s). |
| Event | Declencheur authoré depuis map/runtime. | "Quand le joueur parle au rival". | `MapEventDefinition`, source scenario. | Porter toute l'orchestration narrative. | Lance une Scene. |
| Scene | Orchestration logique d'une sequence. | "Rencontre rival". | Futur `SceneAsset`/`SceneGraph`; adapter scenario. | Etre une storyline, une cinematic ou un fichier Yarn. | Lance Yarn, Cinematic, Battle, Action; emet outcomes. |
| Cinematic | Sequence visuelle lineaire. | Camera, deplacement PNJ, fade, emote. | Futur `CinematicAsset`; runtime cutscene adapte. | Brancher ou gerer progression globale. | Appelee par Scene. |
| Dialogue Yarn | Texte, choix, outcomes de dialogue. | Conversation avec Mael. | `ProjectDialogueEntry`, Yarn file/start node. | Donner objets, terminer steps, piloter tout le monde. | Appele par Scene; renvoie outcome. |
| Fact | Fait du monde persistant lisible. | "Le rival est battu au port". | Wrapper autour flags/progression. | Etre un flag technique brut expose. | Alimente conditions/world rules. |
| World Rule | Changement visible/actif du monde. | PNJ deplace apres une scene. | Conditions + map/event/entity mutations. | Etre cache dans une scene metadata. | Lit Facts/Steps, modifie presentation/runtime. |
| Validator | Coherence/atteignabilite/jouabilite. | "Scene appelee mais inexistante". | Diagnostics core/editor. | Modifier les donnees. | Observe tout le graphe narratif. |

## 7. Scene Graph Contract draft

### SceneGraph

Role : conteneur d'une scene.

Donnees minimales :

- `sceneId`
- `startNodeId`
- `nodes`
- `edges`
- `declaredOutcomes`
- `metadata` limitee aux notes non critiques

Donnees interdites en V1 :

- Donnees de map inline.
- Dialogue Yarn inline complet.
- World rules encodees en texte libre.
- Branches runtime implicites non edgees.

Risques :

- Refaire `ScenarioAsset` sans clarifier les types.
- Stocker trop de logique dans `metadata`.

### SceneNode

Role : unite d'orchestration typée.

Donnees minimales :

- `id`
- `kind`
- `title`
- `description`
- `position`
- `payload` type par kind
- `validationState`

Donnees interdites :

- Payload non type pour tous les cas.
- Effets runtime caches dans notes.

### SceneEdge

Role : transition explicite entre nodes.

Donnees minimales :

- `id`
- `fromNodeId`
- `toNodeId`
- `kind`
- `label`
- `conditionRef` optionnelle selon kind
- `order`

Donnees interdites :

- Edge implicite derive uniquement de position visuelle.
- Edge qui signifie a la fois ordre, condition et outcome.

### SceneStartNode

Role : point d'entree unique.

Inputs : aucun.

Outputs : default.

Donnees minimales : titre, notes.

Interdit en V1 : declencheur Event complet inline.

Risque : confondre start node et event source.

### SceneEndNode

Role : fin explicite de branche.

Inputs : default/outcome/condition/battle.

Outputs : aucun.

Donnees minimales : outcome final optionnel, resume de consequence.

Interdit en V1 : mutation runtime cachee.

Risque : fin non atteignable.

### Dialogue / Yarn node

Role : ouvrir un dialogue Yarn et attendre son resultat si applicable.

Inputs : default.

Outputs : completed, dialogue outcome(s), invalid.

Donnees minimales : `dialogueId`, `startNode`, expected outcomes.

Interdit en V1 : ecrire facts/steps directement depuis Yarn.

Risque : Yarn devient moteur narratif cache.

### Condition node

Role : tester une condition auteur.

Inputs : default.

Outputs : true, false, invalid.

Donnees minimales : condition draft lisible, compilation vers backend condition.

Interdit en V1 : exposer uniquement `flagIsSet(foo.bar.raw)`.

Risque : UX technique.

### Battle node

Role : lancer un combat et attendre son outcome.

Inputs : default.

Outputs : victory, defeat, escaped/blocked si supporte plus tard.

Donnees minimales : trainer/battle reference, npc entity optionnelle, battle id stable.

Interdit en V1 : hardcoder outcomes ou trainer IDs.

Risque : couplage direct a map/runtime sans validation.

### Cinematic node

Role : lancer une cinematic lineaire.

Inputs : default.

Outputs : completed, invalid.

Donnees minimales : cinematicId future ou reference compatible.

Interdit en V1 : branchements internes.

Risque : recoller l'ancien Cutscene Studio qui branche.

### Action node

Role : executer une action runtime/no-code.

Inputs : default.

Outputs : completed, invalid.

Donnees minimales : action type, params types, validation refs.

Interdit en V1 : script brut par defaut comme seule UX.

Risque : "metadata JSON magique".

### Branch by outcome node

Role : diriger le flow selon outcome d'un node precedent ou d'un contexte.

Inputs : default ou outcome source.

Outputs : une sortie par outcome declare, fallback invalid/blocked.

Donnees minimales : source outcome, mapping outcome -> edge.

Interdit en V1 : outcomes non declares.

Risque : branches invisibles si l'outcome vit seulement dans Yarn.

### Edge kinds

| Edge kind | Signification | Source typique | Notes |
|---|---|---|---|
| `default` | Transition normale apres completion. | Start, Action, Cinematic. | Pas une condition. |
| `conditionTrue` | Condition vraie. | Condition node. | Doit avoir pair false. |
| `conditionFalse` | Condition fausse. | Condition node. | Doit avoir pair true. |
| `dialogueOutcome` | Outcome Yarn choisi/recu. | Dialogue/Yarn node. | Outcome declare. |
| `battleVictory` | Combat gagne. | Battle node. | Peut compiler vers outcome backend. |
| `battleDefeat` | Combat perdu. | Battle node. | Ne pas inventer si runtime ne supporte pas. |
| `cinematicCompleted` | Cinematic terminee. | Cinematic node. | Cinematic reste lineaire. |
| `actionCompleted` | Action terminee. | Action node. | Peut rejoindre default. |
| `invalidBlocked` | Branche explicite de blocage ou diagnostic. | Tout node validable. | Surtout pour UI/diagnostics. |

## 8. Relation Storylines <-> Scenes

Conclusion canonique : ne pas lier `StorylineStep` a l'ancien systeme.

Pourquoi :

- `StorylineStep.sceneLinkIds` existe comme intention future, mais Scene V1 n'est pas stabilise.
- `ScenarioAsset.localEventFlow` est proche d'une scene mais porte une dette de vocabulaire et de metadata.
- Le Cutscene Studio compile deja vers `ScenarioAsset`, mais melange cinematic, scene, event source et action.
- Brancher maintenant creerait une dette de migration et une UX faussement terminee.

Ce qu'il faudra preparer :

- Contrat SceneGraph clair.
- Storage/read model Scenes.
- IDs stables de scenes.
- Picker de scenes existantes.
- Validation des references.
- Strategie de migration/adaptation depuis scenarios si retenue.

Moment du lien :

- Apres `NS-SCENES-V1-01` et `V1-02` au minimum.
- Idealement apres workspace Scenes read-only + authoring minimal + diagnostics.
- Roadmap proposee : `NS-SCENES-V1-10`.

Risques si trop tot :

- SceneLink vers un objet qui change de nature.
- Storylines redevient dependent d'un vieux systeme.
- Selbrume pourrait etre "branche" par fake placeholders.
- Tests passeraient avec une abstraction mauvaise.

## 9. Relation Event <-> Scene <-> Runtime

Pipeline cible :

```text
Map Element / Event
-> Scene
-> Dialogue / Yarn
-> Cinematic
-> Battle
-> Action
-> Fact
-> Story Step
-> World Rule
-> Save
```

Ce qui existe deja :

- Map events avec pages conditionnelles.
- Resolution pure de page active.
- Scenario runtime source map/trigger/entity/outcome.
- Dialogue resolution et overlay.
- Script execution.
- Battle handoff depuis scenario action.
- GameState pour persistence.

Ce qui manque :

- `SceneAsset` ou decision alternative.
- Workspace Scenes.
- SceneGraph contract produit.
- Scene node inspector.
- Facts lisibles.
- World Rules authorables.
- Scene outcomes explicites comme concept stable.
- Event -> Scene authoring propre.
- Runtime executor Scene V1 ou adapter valide.
- Validator global Scene/Event/Storyline.

Recommendation :

- Event doit repondre a "quand et dans quel contexte demarre quelque chose ?"
- Scene doit repondre a "que se passe-t-il ensuite ?"
- Runtime doit consommer un read model Scene, pas l'UI editor.

## 10. UI Scene Builder direction

Structure recommandee du workspace Scenes :

- Top bar Narrative Studio existante.
- Sidebar interne avec `Scenes` actif lorsque le shell sera cree.
- Arborescence scenes a gauche : dossiers/scene list/status/diagnostics.
- Breadcrumb : `Narrative Studio > Scenes > <scene> > Scene Builder`.
- Zone centrale : canvas graph sombre avec grille.
- Toolbar nodes : Start, Dialogue Yarn, Condition, Battle, Cinematic, Action, Branch, End.
- Nodes differencies par type.
- Edges typés et labels visibles.
- Inspecteur droit du node selectionne.
- Onglets inspecteur : General, Conditions, Sorties, Notes.
- Panel de validation compact.
- Empty states honnetes : aucune scene, scene sans nodes, node incomplet.

Principes :

- Le graph Scene est une vue d'authoring, contrairement au graph Storylines qui reste comprehension.
- Les boutons doivent etre actifs seulement si la logique existe.
- Pas de donnees fake.
- Pas de "Annonce au port" hardcodee.
- Pas de Selbrume comme fallback UI.
- Pas de scene placeholder generee depuis Storylines dans V1-00.

## 11. Risks / anti-patterns

- Recoller un vieux `sceneLink` vers `ScenarioAsset.localEventFlow`.
- Confondre Scene et Cinematic.
- Faire de Yarn un deuxieme moteur narratif cache.
- Mettre trop de logique dans `metadata` JSON.
- Creer des boutons UI sans logique reelle.
- Hardcoder Selbrume.
- Creer des scenes fake.
- Deplacer de la logique runtime dans `map_editor`.
- Exposer les flags techniques comme UX principale.
- Appeler "cutscene" une sequence qui branche et modifie la progression.
- Appeler "scene" un event de map.
- Faire du storage avant le contrat produit.
- Melanger validator, execution runtime et authoring UI dans le meme lot.

## 12. Roadmap NS-SCENES-V1 proposee

| Lot | Objectif | Done criteria |
|---|---|---|
| NS-SCENES-V1-00 — Scene System Scope / Current State Audit | Auditer l'existant et definir le cap. | Rapport + roadmap dediee, aucun code modifie. |
| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | Definir SceneGraph/SceneNode/SceneEdge et nodes/edges types. | Contrat documentaire ou spec testable, non ambigu. |
| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | Decider stockage ProjectManifest, migration, IDs, read models. | Decision explicite : nouveau modele, adapter scenario, ou hybride. |
| NS-SCENES-V1-03 — Workspace Shell Scenes | Ajouter un shell Scenes coherent. | UI shell sans fake data ni authoring trompeur. |
| NS-SCENES-V1-04 — Scene Tree Panel Read-only | Afficher une bibliotheque de scenes reelles. | Liste/tree read-only, empty states, tests. |
| NS-SCENES-V1-05 — Graph Read-only Skeleton | Afficher une scene sous forme graph read-only. | Start/end/nodes/edges depuis donnees reelles. |
| NS-SCENES-V1-06 — Node Inspector Read-only | Inspecter node selectionne. | General/conditions/sorties/notes read-only. |
| NS-SCENES-V1-07 — Authoring Minimal Scene Draft | Creer/editer une scene draft minimale. | Mutations propres, tests, aucun runtime fake. |
| NS-SCENES-V1-08 — Scene Validation Diagnostics | Diagnostiquer scenes incompletes/invalides. | Diagnostics visibles et tests. |
| NS-SCENES-V1-09 — Runtime Execution Prep | Preparer execution ou adapter runtime. | Pas de branchement Storylines encore; preuve d'adapter. |
| NS-SCENES-V1-10 — StorylineStep <-> Scene Link | Brancher StorylineStep.sceneLinkIds vers Scene V1 stable. | Picker scenes, validation refs, aucune legacy link prematuree. |

Justification de l'ordre :

- Le contrat produit vient avant storage.
- Le storage vient avant shell authoring.
- Le read-only vient avant mutations.
- La validation vient avant runtime.
- Le lien Storylines vient en dernier.

## 13. Recommendation for next lot

Prochain lot recommande :

`NS-SCENES-V1-01 — Scene Product Model / Graph Contract`

Objectif du prochain lot :

- Verrouiller la definition `SceneGraph`.
- Nommer les nodes et edges.
- Definir les payloads minimaux.
- Definir les diagnostics minimaux.
- Decider ce qui reste hors Scene V1-01.

Ne pas faire en V1-01 si le lot reste documentaire :

- Ajouter `SceneAsset` dans `map_core`.
- Modifier `ProjectManifest`.
- Creer le workspace UI.
- Brancher Storylines.
- Migrer `ScenarioAsset`.

## 14. Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch initiale

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
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
4acf8c3f feat(storylines): add Selbrume storylines demo seed v0
b26ae424 docs(storylines): reorganize v1 screenshots and add checkpoint acceptance report
63a005e3 feat(storylines): add visual graph enrichment v1.12
db1bc6e3 docs(storylines): reorganize v1 screenshots and reports for side quest attachment
6554ad0f feat(storylines): add side quest attachment graph integration v0
a36162c7 docs(storylines): reorganize v1 screenshots and reports into v1/ folder
```

### Commandes principales executees

```text
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
for f in ...; do test -e "$f" ...; done
sed -n '1,220p' skills/README.md
sed -n '1,220p' agent_rules.md
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/script_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/script_conditions.dart
sed -n '180,360p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_event_definition.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,240p' packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
sed -n '1,240p' packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
sed -n '1,260p' packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
sed -n '1,140p' packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
sed -n '1,180p' packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
sed -n '1,180p' packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
sed -n '1,220p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,280p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,620p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
sed -n '1,220p' packages/map_gameplay/lib/src/script_condition_evaluator.dart
sed -n '1,220p' packages/map_gameplay/lib/src/event_page_resolver.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/resolve_dialogue.dart
rg --files packages/map_editor/lib/src/ui/canvas | rg 'cutscene|dialogue|step_studio|scenario|storylines'
rg "class ProjectDialogue|ProjectDialogue|Dialogue|Yarn|parseYarn|resolveDialogue" packages/map_core/lib packages/map_runtime/lib -g '*.dart'
rg "class ScenarioRuntime|ScenarioRuntime|ScenarioAction|startTrainerBattle|completeStep|authoringPlaceholder" packages/map_runtime/lib packages/map_gameplay/lib packages/map_editor/lib -g '*.dart'
find reports/narrativeStudio -iname '*checkpoint*' -o -iname '*v1_12*' -o -iname '*structure_bis*'
mkdir -p reports/narrativeStudio/scenes
```

### Liste des fichiers inspectes

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/narrative_studio.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/v1/ns_storylines_v1_checkpoint_acceptance.md
reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md
reports/narrativeStudio/storylines/ns_storylines_structure_bis_full_width_accordion_authoring.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_gameplay/lib/src/event_page_resolver.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/resolve_dialogue.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_runtime/lib/src/application/script_runtime_controller.dart
packages/map_runtime/lib/src/application/script_command_executor.dart
```

### git status final exact

```text
?? reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
?? reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --stat final

```text
Sortie : <vide>
```

### git diff --name-only final

```text
Sortie : <vide>
```

### git diff --check final

```text
Sortie : <vide>
```

### Contenu complet de `reports/narrativeStudio/scenes/road_map_scenes.md`

```text
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
| NS-SCENES-V1-01 — Scene Product Model / Graph Contract | TODO | Formaliser le contrat produit SceneGraph/SceneNode/SceneEdge, sans code model si le lot reste documentaire. |
| NS-SCENES-V1-02 — Scene Storage / ID / Read Model Decision | TODO | Decider ou stocker les Scenes, quels IDs, quels read models, et la strategie de migration/compat legacy. |
| NS-SCENES-V1-03 — Workspace Shell Scenes | TODO | Creer le shell editor `Scenes` sans authoring profond ni runtime. |
| NS-SCENES-V1-04 — Scene Tree Panel Read-only | TODO | Afficher une arborescence de scenes reelles ou fixtures explicites, sans fake fallback. |
| NS-SCENES-V1-05 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
| NS-SCENES-V1-06 — Node Inspector Read-only | TODO | Inspecteur contextuel read-only pour node selectionne, conditions, sorties et notes. |
| NS-SCENES-V1-07 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
| NS-SCENES-V1-08 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
| NS-SCENES-V1-09 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
| NS-SCENES-V1-10 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |

## Prochain lot recommande

`NS-SCENES-V1-01 — Scene Product Model / Graph Contract`

Raison : avant de creer un modele, un widget ou une migration, il faut verrouiller le vocabulaire exact du graph Scene V1, les types de nodes, les transitions et ce qui reste hors scope.

## Dependances

- Storylines V1/V1.1 ferme avec limitations.
- `ProjectManifest.storylines` existant et stable.
- `ScenarioAsset`, `ScriptAsset`, `ScriptCondition`, `MapEventDefinition` audites comme legacy/adaptables.
- Runtime scenario/script/cutscene audite a haut niveau.
- Decision storage Scene V1 a venir dans V1-02.

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
```

### Contenu complet du rapport principal cree

Le present fichier est le rapport principal cree pour `NS-SCENES-V1-00`. Son contenu complet est constitue par toutes les sections ci-dessus et ci-dessous dans ce meme document.

### Auto-review critique

- Le rapport recommande de ne pas brancher Storylines sur l'ancien systeme ; c'est plus lent a court terme mais evite une dette de migration.
- Le terme "Scene" reste a verrouiller au prochain lot avec un contrat encore plus formel.
- L'audit n'a pas execute de tests ni analyze, conformement au scope documentation-only.
- Le runtime actuel sait deja faire beaucoup de choses ; le risque est de sous-estimer la valeur de l'adapter existant, mais il serait dangereux d'en faire le modele produit sans decision.

### Regard critique sur le prompt

- Le prompt suppose a juste titre que l'ancien systeme de scenes/scenarios existe, mais il melange parfois "scenes", "scenarios", "scripts" et "cutscenes" comme des couches equivalentes ; l'audit montre justement qu'il faut les separer.
- Le prochain lot propose dans le prompt est coherent, mais "Scene Placeholder + Scene Linking Foundation" serait premature tant que le SceneGraph contract et le storage ne sont pas decides.
- Selbrume est utile comme reference produit, mais ne doit pas devenir source de fixtures ou donnees UI dans V1-00.

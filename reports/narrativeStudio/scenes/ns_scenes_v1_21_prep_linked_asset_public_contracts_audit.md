# NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit

## Resume executif

Lot realise en documentation-only.

Decision principale : ne pas lancer directement `NS-SCENES-V1-21 — Payload Pickers V0`.

Le Scene Builder ne doit pas devenir un tableau d'IDs. Il doit stocker des references stables dans `SceneAsset`, mais lire un contrat public minimal pour chaque asset lie : label lisible, existence, statut, diagnostics, inputs, outputs/outcomes et contraintes. Il ne doit pas connaitre l'implementation interne complete de Yarn, Cutscene Studio, battle runtime ou scripts.

Prochain lot exact recommande :

```text
NS-SCENES-V1-21 — Linked Asset Contracts V0
```

Puis seulement :

```text
NS-SCENES-V1-22 — Payload Pickers V0
```

## Raison du prep

Le checkpoint V1-20 avait place `Payload Pickers V0` comme prochain lot, avec une logique produit correcte : les scenes doivent pouvoir referencer Yarn, Cinematic, Battle et Action avant Event -> Scene et Runtime Plan.

L'audit montre cependant un risque : sans contrat public, un picker ne choisirait qu'un ID brut. Ce serait contraire a la vision Narrative Studio relue dans `MVP Selbrume/narrative_studio.md` : le createur doit penser en situations, decisions, consequences, progression et changements visibles, pas en flags ou IDs techniques.

La chaine visee reste :

```text
Asset -> Public Contract -> Picker -> Scene Node
```

et non :

```text
Asset -> ID
```

## Etat actuel

Le Scene Builder est visuellement credible : nodes, edges, canvas Blueprint-like, ports visuels, selection/suppression d'edges, Conditions structurees, Fact Registry V0 et World Rules V0.

Les nodes metier restent le maillon faible :

- `SceneYarnDialoguePayload` exige deja un `dialogueId`.
- `SceneBattlePayload` exige un `battleKind`.
- `SceneCinematicPayload` exige un `cinematicId`.
- `SceneActionPayload` exige un `actionKind`.
- `SceneBranchByOutcomePayload` peut porter une source outcome, mais les mappings outcome -> edge ne sont pas encore modelises.

Ces payloads sont stricts, mais l'authoring n'a pas encore de contrat public uniforme pour les remplir honnetement.

## Audit Dialogue / Yarn

### Existant

- `ProjectManifest.dialogues` existe.
- `ProjectDialogueEntry` expose `id`, `name`, `relativePath`, `tags`, `description`, `defaultStartNode`, `folderId`, `sortOrder`.
- Dialogue Studio a un modele d'edition structure : `DialogueEditorDocument`, `DialogueEditorNode`, steps de texte, choix, jump, condition et command.
- `dialogue_yarn_codec.dart` parse/emet du Yarn autour de blocs `title:`.
- `dialogue_editor_validation.dart` valide notamment les titres Yarn dupliques, jumps et documents vides.
- `SceneYarnDialoguePayload` porte `dialogueId`, `yarnNodeName`, `expectedOutcomes`, `speakerHints`.

### Reponses

| Question | Reponse |
|---|---|
| Registry de dialogues ? | Oui, via `ProjectManifest.dialogues`. |
| Picker par ID stable ? | Oui, `ProjectDialogueEntry.id` est la base stable. |
| Label lisible ? | Oui, `ProjectDialogueEntry.name`, fallback possible sur `id`. |
| Start node ? | Partiellement, `ProjectDialogueEntry.defaultStartNode` existe et `SceneYarnDialoguePayload.yarnNodeName` peut surcharger. |
| Outcomes Yarn declares ? | Pas de contrat public canonique observe. `expectedOutcomes` existe dans le payload Scene, mais ce n'est pas une registry/contrat source du dialogue. |
| Validation existence dialogue ? | Possible par comparaison `dialogueId` avec `ProjectManifest.dialogues`. |
| Validation outcome BranchByOutcome ? | Pas encore propre sans declaration d'outcomes publique. |
| Lire outcomes depuis Yarn source ? | A eviter comme source unique V0 : le parsing Yarn peut aider au preview/diagnostic, mais les outcomes narratifs doivent etre declares dans un contrat public ou metadata authoring. |

### Decision Dialogue

`YarnDialogueNode` peut devenir activable apres `DialoguePublicContract`.

Le picker Yarn ne doit pas seulement remplir `dialogueId`; il doit afficher le label, la source, le start node et les diagnostics. En revanche, `BranchByOutcome` ne doit pas etre active avec Yarn tant que les outcomes Yarn ne sont pas exposes proprement.

Contrat recommande :

```text
DialoguePublicContract
- id
- label
- sourceRef / relativePath
- defaultStartNode
- availableStartNodes
- declaredOutcomes
- diagnostics
```

## Audit Cinematic / Cutscene

### Existant

- Pas de vrai `CinematicAsset` canonique observe.
- Cutscene Studio porte un modele editor `CutsceneStudioDocument`, `CutsceneStudioBlock`, `CutsceneFlowEntry`.
- Cutscene Studio compile vers `ScenarioAsset` via `buildScenarioFromCutsceneStudioDocument`.
- `ScenarioAsset` possede `id`, `name`, `description`, `scope`, `entryNodeId`, `declaredOutcomes`, nodes, edges et metadata.
- Les metadata Cutscene Studio (`authoring.cutsceneSchema`, `authoring.cutsceneFlow`) permettent de reconnaitre un scenario issu du studio.
- Certains blocs Cutscene Studio sont supportes runtime, d'autres restent placeholders explicites.
- `SceneCinematicPayload` exige un `cinematicId`.

### Reponses

| Question | Reponse |
|---|---|
| Vrai CinematicAsset ? | Non observe. |
| Seulement ScenarioAsset / ScriptAsset / flows ? | Oui, le bridge actuel passe par `ScenarioAsset` et metadata Cutscene Studio. |
| Picker stable ? | Possible techniquement via `ProjectManifest.scenarios`, mais dangereux si presente comme Cinematic canonique. |
| Label lisible ? | Oui via `ScenarioAsset.name`, si scenario bridge accepte. |
| Map / acteurs requis ? | Pas expose comme contrat public stable. Certains blocs ont `actorId`, `mapId`, `entityId`, mais pas de synthese publique. |
| Duree / statut validation ? | Pas de contrat public stable observe. |
| Linearite garantie ? | Non. Cutscene Studio V2 a flow sequentiel + branches; `ScenarioAsset` est un graphe. |
| Pointer vers ScenarioAsset temporairement ? | Seulement comme `scenarioBridge` explicite, limite et diagnostique. |
| Danger Cinematic = Scenario ? | Oui, c'est le risque principal. `ScenarioAsset` reste legacy/bridge, pas modele produit final de Scene V1. |

### Decision Cinematic

`CinematicNode` ne doit pas etre active comme picker general en V1-22 tant qu'un `CinematicPublicContract` ou un bridge explicitement borne n'existe pas.

Contrat recommande :

```text
CinematicPublicContract
- id
- label
- sourceKind: cinematicAsset / cutsceneFlow / scenarioBridge
- linear
- requiredActors
- mapId optionnel
- declaredOutputs: completed
- diagnostics
```

Le contrat peut accepter un `sourceKind: scenarioBridge` transitoire, mais l'UI doit l'afficher comme bridge, pas comme vrai modele final.

## Audit Battle / Trainer

### Existant

- `ProjectManifest.trainers` existe.
- `ProjectTrainerEntry` expose `id`, `name`, `trainerClass`, `battleDifficulty`, `battleBackgroundRelativePath`, portraits/themes/team/tags.
- `TrainerBattleStartRequest` et `BattleStartRequest` representent le handoff runtime trainer/wild.
- `RuntimeBattleKind` expose `wild` et `trainer`.
- `BattleOutcomeType` expose `victory`, `defeat`, `runaway`, `captured`.
- Le bridge scenario a des flags d'outcome `battle:<battleId>:victory`, `defeat`, `flee`, `captured`.
- `buildNarrativeBattleReferencePickerOptions` existe deja et expose des references battle derivees de scenarios `startTrainerBattle`, avec `victory/defeat`.
- `SceneBattlePayload` porte `battleKind`, `trainerId`, `battleTemplateId`, `npcEntityId`, `declaredOutcomes`.

### Reponses

| Question | Reponse |
|---|---|
| Picker trainer stable ? | Oui, via `ProjectManifest.trainers` / `ProjectTrainerEntry.id`. |
| BattleNode trainer battle ? | Oui pour un V0 borne `battleKind: trainer`. |
| Battle templates ? | `SceneBattlePayload.battleTemplateId` existe, mais pas de registry battle template canonique observee. |
| Outcomes narratifs exposables ? | Pour trainer battle, `victory` et `defeat` sont surs. |
| Flee / capture ? | Depend du battle kind. `runaway` et `captured` concernent surtout wild/capture ; ne pas exposer pour trainer V0. |
| Scene Builder connait outcomes standards ? | Oui, via contrat public, pas via details internes du moteur battle. |
| Moteur battle separe ? | Oui. Le Scene Builder ne doit lire que le contrat public, pas les internals `map_battle`. |

### Decision Battle

`BattleNode` peut devenir activable apres `BattlePublicContract`, en V0 seulement pour trainer battle avec trainer existant.

Contrat recommande :

```text
BattlePublicContract
- id / battleRefId
- label
- battleKind: trainer / wild / boss / unknown
- trainerId optionnel
- trainerLabel optionnel
- possibleOutcomes
- diagnostics
```

V0 conseille : `trainer` seulement, outcomes `victory` et `defeat`.

## Audit Action / Consequence

### Existant

- `ScriptAsset` expose des `ScriptCommandType` bas niveau : `setFlag`, `clearFlag`, `setVariable`, `incrementVariable`, `openDialogue`, `waitForDialogue`, `warpPlayer`, `giveItem`, `unlockFieldAbility`, `markEventConsumed`.
- `ScenarioRuntimeExecutor` supporte plusieurs actions runtime : `openDialogue`, `setFlag`, `clearFlag`, `emitOutcome`, `startTrainerBattle`, `givePokemon`, `giveItem`, `completeStep`, mouvements, transition map et placeholders.
- `NarrativeScenarioAuthoringDraft` a des actions guidees : `setFlag`, `completeStep`, `emitOutcome`, `startTrainerBattle`.
- Facts et World Rules existent en V0, mais ce sont des registries/definitions, pas encore une Action Registry Scene.
- `SceneActionPayload` exige `actionKind` + `parameters`.

### Reponses

| Question | Reponse |
|---|---|
| Action Registry authoring ? | Non observee comme contrat public Scene V1. |
| Contrat no-code setFact / completeStep / giveItem ? | Partiel et disperse : Facts, scenario drafts, script commands, runtime actions. |
| Actions trop runtime/script ? | Oui pour un Node Action Scene V1 immediat. |
| Activer ActionNode sans script cache ? | Non, pas sans `ActionPublicContract` / `ConsequencePublicContract`. |
| Consequence Contract avant ActionNode ? | Oui. |

### Decision Action

`ActionNode` reste disabled.

Contrat recommande :

```text
ActionPublicContract
- actionKind
- label
- category
- inputs
- writes
- possibleOutcomes
- diagnostics
```

Pour la trajectoire produit, le contrat devrait probablement etre nomme ou complete par `ConsequencePublicContract`, car le Scene Builder doit parler de consequences lisibles : set fact, clear fact, complete step, give item, give Pokemon, emit SceneOutcome, update world state via World Rule.

## Audit BranchByOutcome

### Producteurs d'outcomes

| Producteur | Outcomes potentiels | Maturite |
|---|---|---|
| YarnDialogueNode | `completed` + outcomes declares type `confident`, `hesitant`, `aggressive` | payload possible, contrat public manquant cote dialogue |
| BattleNode trainer | `victory`, `defeat` | base mature si contrat battle |
| CinematicNode | `completed` | simple, mais contrat cinematic manquant |
| ActionNode | `completed`, `failed` ou outcomes metier | contrat action/consequence manquant |
| Scene End / SceneOutcome | Scene outcomes declares/emis | existe localement dans SceneAsset mais pas encore relie aux branches metier |

### Decisions Branch

`BranchByOutcomeNode` reste disabled.

Raisons :

- il manque une source outcome explicite selectionnable ;
- il manque un contrat public uniforme pour les outcomes Yarn/Battle/Cinematic/Action ;
- il manque un mapping authorable outcome -> edge ;
- activer la branche maintenant pousserait vers des labels ou IDs inventes.

Contrat recommande :

```text
OutcomeProducerPublicContract
- producerNodeKind
- producerRef
- outcomeSetId optionnel
- outcomes: id, label, semanticKind, persistentScope
- diagnostics
```

Et pour le node :

```text
BranchByOutcomePublicContract
- sourceNodeId
- sourceOutcomeSetRef
- mappings: outcomeId -> edgeId / targetNodeId
- fallbackPolicy
- diagnostics
```

## Contrats publics recommandes

Principe commun :

```text
SceneAsset stocke la ref stable.
Scene Builder lit un contrat public minimal.
L'implementation interne reste proprietaire de chaque asset.
Le runtime futur consomme un SceneRuntimePlan, pas le layout ni les widgets editor.
```

Contrats recommandes :

| Contrat | Champs minimaux | Role |
|---|---|---|
| `DialoguePublicContract` | `id`, `label`, `sourceRef`, `defaultStartNode`, `availableStartNodes`, `declaredOutcomes`, `diagnostics` | Permettre picker Yarn, validation existence/start node/outcomes. |
| `CinematicPublicContract` | `id`, `label`, `sourceKind`, `linear`, `requiredActors`, `mapId`, `declaredOutputs`, `diagnostics` | Eviter de confondre Cinematic et Scenario bridge. |
| `BattlePublicContract` | `battleRefId`, `label`, `battleKind`, `trainerId`, `possibleOutcomes`, `diagnostics` | Activer trainer battle sans exposer `map_battle`. |
| `ActionPublicContract` | `actionKind`, `label`, `category`, `inputs`, `writes`, `possibleOutcomes`, `diagnostics` | Preparer actions no-code sans script cache. |
| `ConsequencePublicContract` | `id`, `label`, `targetKind`, `writeKind`, `requiredRefs`, `diagnostics` | Parler de consequences persistantes plutot que de commandes. |
| `OutcomeProducerPublicContract` | `producerRef`, `outcomes`, `persistentScope`, `diagnostics` | Base de `BranchByOutcome`. |

Diagnostics communs a prevoir :

- ref absente ;
- ref inconnue ;
- label technique brut ;
- contrat incomplet ;
- outcome inconnu ;
- start node inconnu ;
- action/consequence non supportee ;
- bridge legacy utilise hors perimetre ;
- node activable mais non executable tant que diagnostics error.

## Tableau par node kind

| Node kind | Source existante | Contrat public existant ? | Contrat manquant | Activable V1-22 ? | Picker possible ? | Diagnostics necessaires | Risque si active trop tot | Recommandation |
|---|---|---|---|---|---|---|---|---|
| `YarnDialogueNode` | `ProjectManifest.dialogues`, `ProjectDialogueEntry`, Dialogue Studio | Partiel : id/label/path/start node | outcomes publics, start nodes derives, diagnostics ref/start/outcome | Oui apres V1-21, mais sans BranchByOutcome complet | Oui | missingDialogueRef, unknownStartNode, missingDeclaredOutcomes, outcomeUnknown | Picker d'ID brut ou outcomes inventes | Formaliser `DialoguePublicContract`; activer dialogue ref/start node, repousser branch outcomes si non declares. |
| `CinematicNode` | Cutscene Studio -> `ScenarioAsset` bridge | Non canonique | `CinematicPublicContract`, linearite, acteurs, statut, sourceKind | Non general ; bridge seulement si explicitement borne | Seulement bridge diagnostique | missingCinematicRef, scenarioBridgeUsed, nonLinearCutscene, unsupportedBlock | Faire de `ScenarioAsset` le modele final de Cinematic | Garder disabled jusqu'au contrat public ou bridge limite. |
| `BattleNode` | `ProjectManifest.trainers`, `ProjectTrainerEntry`, runtime battle requests, battle outcomes | Partiel via trainer refs et read models battle scenario | `BattlePublicContract` uniforme, battle templates, diagnostics trainer/team | Oui pour trainer battle apres V1-21 | Oui, trainer battle V0 | missingTrainerRef, unknownTrainer, emptyTrainerTeam warning, unsupportedBattleKind | Exposer wild/flee/capture trop tot | Activer seulement `battleKind: trainer`, outcomes `victory/defeat`. |
| `ActionNode` | `ScriptAsset`, scenario actions, Facts, World Rules, runtime executor | Non comme Action Registry Scene | `ActionPublicContract` / `ConsequencePublicContract` | Non | Non honnete en V0 direct | missingActionKind, unsupportedActionKind, missingRequiredInput, writeTargetUnknown | Reintroduire scripts caches et flags techniques | Garder disabled ; inserer contrat consequence avant authoring action. |
| `BranchByOutcomeNode` | Scene edges/outcomes, payload branch source optional, battle outcome conventions | Non suffisant | source outcome explicite, outcome set public, mapping outcome -> edge | Non | Non | missingOutcomeSource, outcomeUnknown, mappingMissing, fallbackMissing | Branches sur IDs inventes, incoherence avec Yarn/Battle | Garder disabled jusqu'aux `OutcomeProducerPublicContract` + mappings. |

## Options de roadmap comparees

| Option | Verdict | Avantage | Risque |
|---|---|---|---|
| A — continuer directement Payload Pickers V0 | Rejetee comme prochain lot | Avance vite vers des scenes configurables | Pickers d'IDs pauvres, surtout Cinematic/Action/Branch. |
| B — Linked Asset Contracts V0 avant Pickers | Retenue | Securise les contrats publics avant UI ; garde no-code honnete | Encore un lot preparatoire. |
| C — activer seulement Yarn/Battle, repousser Cinematic/Action | Rejetee comme ordre principal | Avance sur les sources les plus pretes | Fragmentation de roadmap ; risque de deux familles de contrats divergentes. |
| D — Event -> Scene avant Payloads | Rejetee maintenant | Selbrume demarre depuis Event | L'Event ciblerait encore des scenes incapables de pointer proprement vers les contenus metier. |

## Decision recommandee

Retenir l'option B :

```text
NS-SCENES-V1-21 — Linked Asset Contracts V0
NS-SCENES-V1-22 — Payload Pickers V0
```

Raisons :

- `DialoguePublicContract` et `BattlePublicContract` peuvent etre formalises rapidement depuis l'existant.
- `CinematicPublicContract` doit eviter le piege `ScenarioAsset = Cinematic final`.
- `ActionPublicContract` / `ConsequencePublicContract` doit eviter le retour aux scripts caches.
- `BranchByOutcome` a besoin de producteurs d'outcomes et mappings explicites.
- `Event -> Scene` reste prioritaire juste apres que les scenes puissent pointer vers des contenus metier honnetes.

## Prochain lot exact

```text
NS-SCENES-V1-21 — Linked Asset Contracts V0
```

Objectif recommande pour ce prochain lot :

- produire les contrats/read models publics minimaux ;
- ne pas coder l'UI de pickers complete ;
- permettre au futur V1-22 de choisir des contenus lisibles, validables et non mensongers ;
- garder `ScenarioAsset` comme bridge explicite, pas modele produit final.

## Roadmap update

Roadmap corrigee :

| Lot | Statut | Role |
|---|---|---|
| `NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit` | DONE | Audit documentaire et decision de ne pas lancer les pickers directement. |
| `NS-SCENES-V1-21 — Linked Asset Contracts V0` | TODO | Formaliser les contrats publics minimaux des assets lies. |
| `NS-SCENES-V1-22 — Payload Pickers V0` | TODO | Consommer les contrats publics dans les pickers Scene Builder. |
| `NS-SCENES-V1-23 — Event to Scene Trigger Prep` | TODO | Preparer Event -> Scene sans StorylineStep trigger. |
| `NS-SCENES-V1-24 — Scene Runtime Plan V0` | TODO | Compiler SceneAsset valide en intents purs. |
| `NS-SCENES-V1-25 — Diagnostics / Validator Expansion` | TODO | Valider refs/outcomes/reachability apres payloads et events. |
| `NS-SCENES-V1-26 — Scene Runtime Executor MVP` | TODO | Executer un sous-ensemble Scene V1. |
| `NS-SCENES-V1-27 — World Rules Map Editor Integration V0` | TODO | Rendre World Rules visibles depuis les cibles map/entity/event. |
| `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep` | TODO | Prouver la chaine en fixture/projet controle. |
| `NS-SCENES-V1-29 — StorylineStep to Scene Link` | TODO | Lier StoryStep a Scene apres stabilisation. |

## Risques

- Trop modeliser les contrats en V1-21 et retarder inutilement les pickers.
- Sous-modeliser Cinematic et laisser `ScenarioAsset` devenir silencieusement le modele final.
- Activer ActionNode avant d'avoir un vocabulaire de consequences no-code.
- Activer BranchByOutcome avant de savoir quelle source produit quels outcomes.
- Duplications possibles avec `narrative_reference_picker_read_models.dart`; V1-21 devra reutiliser ou clarifier les read models existants.

## Fichiers crees/modifies

Fichier cree :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
```

Fichiers modifies :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Tests/analyze

Lot documentation-only.

```text
dart analyze : non requis
flutter analyze : non requis
dart test : non requis
flutter test : non requis
build_runner : non requis
```

Verification requise :

```text
git diff --check
```

## Git status initial

Commande :

```bash
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
Sortie git status initial : <vide>
Sortie git diff --stat initial : <vide>
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
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
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
```

### Liste des fichiers lus

Tous les chemins attendus ont ete verifies comme presents.

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_bis_roadmap_checkpoint_correction.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/narrative_fact.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart
packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_model.dart
packages/map_editor/lib/src/features/dialogue/application/dialogue_editor_validation.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_flow.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
packages/map_runtime/lib/src/application/trainer_battle_request.dart
packages/map_runtime/lib/src/application/battle_start_request.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_battle/lib/map_battle.dart
packages/map_battle/lib/src/battle_resolution.dart
packages/map_battle/lib/src/psdk/domain/psdk_battle_outcome.dart
```

### Contenu complet du rapport cree

Ce fichier est le rapport cree pour `NS-SCENES-V1-21-prep`. Son contenu complet est le present document, depuis le titre `# NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit` jusqu'a la section `Regard critique sur le prompt`.

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index f7a94797..bde3b56e 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -62,25 +62,42 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-20 — World Rules V0 | DONE | Premier modele/authoring/validation de World Rules controlees : registry `ProjectManifest.worldRules`, operations pures, diagnostics, projection pure et apercu editor minimal. |
 | NS-SCENES-V1-20-bis — Roadmap Checkpoint Correction | DONE | Correction documentaire : inserer le checkpoint Narrative Studio obligatoire apres V1-20 et conserver V1-21 comme candidat, pas comme prochain automatique. |
 | NS-SCENES-V1-20-checkpoint — Narrative Studio Direction Checkpoint | DONE | Checkpoint produit post World Rules : la suite retenue est Payload Pickers V0 avant Event -> Scene, Runtime Plan, diagnostics et runtime MVP. |
-| NS-SCENES-V1-21 — Payload Pickers V0 | TODO | Ajouter des pickers/drafts honnetes pour Yarn, Cinematic, Battle et Action afin de configurer les nodes metier sans fake refs. |
-| NS-SCENES-V1-22 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume, sans execution runtime complete. |
-| NS-SCENES-V1-23 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
-| NS-SCENES-V1-24 — Diagnostics / Validator Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles, payloads incomplets, Facts et World Rules. |
-| NS-SCENES-V1-25 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
-| NS-SCENES-V1-26 — World Rules Map Editor Integration V0 | TODO | Rendre les World Rules visibles/configurables depuis le contexte map/entity/event sans brancher de runtime Scene. |
-| NS-SCENES-V1-27 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
-| NS-SCENES-V1-28 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP et golden slice stabilises. |
+| NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit | DONE | Audit documentaire des contrats publics exposes au Scene Builder par Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et outcomes avant pickers. |
+| NS-SCENES-V1-21 — Linked Asset Contracts V0 | TODO | Formaliser les contrats/read models publics minimaux des assets lies : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes, sans runtime. |
+| NS-SCENES-V1-22 — Payload Pickers V0 | TODO | Ajouter des pickers/drafts honnetes pour Yarn, Cinematic, Battle et Action en consommant les contrats publics, pas des IDs bruts. |
+| NS-SCENES-V1-23 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume, sans execution runtime complete. |
+| NS-SCENES-V1-24 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
+| NS-SCENES-V1-25 — Diagnostics / Validator Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles, payloads incomplets, Facts et World Rules. |
+| NS-SCENES-V1-26 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
+| NS-SCENES-V1-27 — World Rules Map Editor Integration V0 | TODO | Rendre les World Rules visibles/configurables depuis le contexte map/entity/event sans brancher de runtime Scene. |
+| NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
+| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP et golden slice stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-21 — Payload Pickers V0`
+`NS-SCENES-V1-21 — Linked Asset Contracts V0`
 
-Raison : le checkpoint V1-20 confirme que le Scene Builder est maintenant assez solide visuellement et structurellement, mais qu'il ne sait pas encore authorer les nodes metier du golden slice sans references reelles. Le prochain blocage produit est donc de rendre configurables les refs Yarn, Cinematic, Battle et Action sans fake data. `Event -> Scene` et `SceneRuntimePlan` restent indispensables, mais ils deviennent plus utiles une fois qu'une Scene peut porter des payloads metier honnetes.
+Raison : le checkpoint V1-20 confirme que le Scene Builder doit maintenant pointer vers de vrais contenus metier. L'audit V1-21-prep precise cependant qu'un picker direct risquerait de redevenir un selecteur d'ID brut tant que Dialogue, Cinematic, Battle, Action et BranchByOutcome n'exposent pas un contrat public minimal lisible par Scene Builder : label, existence, statut, diagnostics, outputs/outcomes et contraintes. Le prochain blocage produit est donc de cadrer/produire ces contrats publics avant l'UI de pickers.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
+Ordre corrige : Linked Asset Contracts V0, puis Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
+## Decisions V1-21-prep
+
+- Lot documentation-only : aucun code, widget, modele Dart, test, build_runner, runtime, Event -> Scene, StorylineStep link ou donnee Selbrume n'est ajoute.
+- Decision principale : ne pas lancer directement `NS-SCENES-V1-21 — Payload Pickers V0`.
+- Option retenue : inserer `NS-SCENES-V1-21 — Linked Asset Contracts V0`, puis deplacer `Payload Pickers V0` en V1-22.
+- Principe retenu : `SceneAsset` stocke des refs stables, mais le Scene Builder doit lire un contrat public minimal des assets lies. Il ne doit pas connaitre l'implementation interne complete.
+- Dialogue/Yarn : registry existante via `ProjectManifest.dialogues` et `ProjectDialogueEntry`; dialogue activable apres contrat public, mais outcomes Yarn doivent etre declares/exposes proprement avant `BranchByOutcome`.
+- Cinematic/Cutscene : pas de vrai `CinematicAsset` canonique ; Cutscene Studio compile vers `ScenarioAsset`, bridge utile mais non final. `CinematicNode` reste disabled tant qu'un contrat public cinematic ou bridge explicitement borne n'existe pas.
+- Battle/Trainer : `ProjectManifest.trainers`, `ProjectTrainerEntry`, battle requests runtime et outcomes `victory/defeat` donnent une base assez mure pour un contrat public trainer battle V0.
+- Action/Consequence : actions encore dispersees entre `ScriptAsset`, `ScenarioRuntimeExecutor`, Facts et World Rules ; `ActionNode` reste disabled jusqu'a un contrat `ActionPublicContract` / `ConsequencePublicContract` V0.
+- BranchByOutcome : reste disabled tant que les producteurs d'outcomes et mappings outcome -> edge ne sont pas modelises explicitement.
+- `Event -> Scene` reste prioritaire apres que les scenes puissent pointer vers des contenus metier honnetes.
+- `Scene Runtime Plan V0` reste necessaire apres contrats/payloads et Event -> Scene.
+- `StorylineStep.sceneLinkIds` reste repousse apres builder, triggers, runtime MVP et golden slice stabilises.
+
 ## Decisions V1-20-checkpoint
 
 - Le checkpoint est DONE en documentation-only : aucun code, widget, modele, runtime, build_runner ou donnee Selbrume n'est ajoute.
```

### Diff complet de road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 617dab31..adfd6fae 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-21 — Payload Pickers V0
+NS-SCENES-V1-21 — Linked Asset Contracts V0
 ```
 
 ## Principes
@@ -41,14 +41,16 @@ NS-SCENES-V1-21 — Payload Pickers V0
 | NS-SCENES-V1-20 | World Rules V0 | core / editor | Premier modele/authoring/validation de World Rules controlees : registry projet, operations pures, diagnostics, projection pure et apercu minimal. | Pas de runtime Scene complet, pas de StorylineStep link, pas de collision/warp dynamique direct, pas d'ecran editor complet. | `world_rule.dart`, `ProjectManifest`, operations authoring, diagnostics, projection, overview read model. | DONE : tests JSON/manifest/ops/diagnostics/projection + overview widget + analyze + visual gate. | Casser les predicates existants ; rendre le monde trop dynamique sans validation. | DONE : World Rules authorables et validables, compteur/labels en apercu, projection pure non runtime. | V1-19. |
 | NS-SCENES-V1-20-bis | Roadmap Checkpoint Correction | doc-only / roadmap | Corriger l'aiguillage post V1-20 : inserer le checkpoint Narrative Studio demande et eviter de lancer V1-21 automatiquement. | Pas de code, pas de widget, pas de modele, pas de tests, pas de screenshots. | roadmaps + rapport bis. | `git diff --check` uniquement. | Continuer vers runtime sans relire la vision produit ; laisser V1-21 comme prochain implicite. | DONE : V1-20 reste DONE, prochain lot exact devient V1-20-checkpoint, V1-21 reste candidat post-checkpoint, note Facts overview ajoutee. | V1-20. |
 | NS-SCENES-V1-20-checkpoint | Narrative Studio Direction Checkpoint | doc-only / product-architecture | Relire la vision Narrative Studio et choisir la meilleure suite apres World Rules V0. | Pas de code, pas de runtime, pas de payload picker, pas de StorylineStep link. | rapport checkpoint, roadmaps. | DONE : `git diff --check`. | Checkpoint trop vague ; retarder inutilement le golden slice ; repartir sur runtime sans priorisation produit. | DONE : Payload Pickers V0 retenu comme V1-21, trajectoire Selbrume revalidee. | V1-20-bis. |
-| NS-SCENES-V1-21 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes : Yarn, cinematic, battle, action. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal. | workspace Scenes, inspector draft controls, projection refs, diagnostics refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes, nodes metier activables seulement avec payload valide. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | Node payloads metier configurables avec vraies refs ou drafts clairement invalides, aucun fake ref. | V1-17, V1-18, V1-20-checkpoint. |
-| NS-SCENES-V1-22 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link, pas de migration ScenarioAsset. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy ; cibler des scenes incompletes. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21. |
-| NS-SCENES-V1-23 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-21, V1-22 utile. |
-| NS-SCENES-V1-24 | Diagnostics / Validator Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions, facts, world rules et Event -> Scene. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, diagnostics world rules/event, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide, erreurs runtime bloquantes explicites. | V1-21, V1-22, V1-23. |
-| NS-SCENES-V1-25 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/dialogue/cinematic/battle/action via callbacks limites. | Pas de full bridge ScenarioAsset, pas StorylineStep link, pas de consequences persistantes implicites. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-23, V1-24. |
-| NS-SCENES-V1-26 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule pickers, diagnostics. | Tests affichage contextuel, picker target, refs inconnues, overview toujours coherent. | World Rules inutilisables si seulement en overview ; UI trop large. | Les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts. | V1-20, V1-24 utile. |
-| NS-SCENES-V1-27 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-21, V1-22, V1-25, V1-26. |
-| NS-SCENES-V1-28 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-22, V1-25, V1-27. |
+| NS-SCENES-V1-21-prep | Linked Asset Public Contracts Audit | doc-only / architecture-review | Auditer Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et BranchByOutcome avant les pickers. | Pas de code, pas de widget, pas de modele, pas de tests, pas de build_runner. | rapport V1-21-prep, roadmaps. | DONE : `git diff --check`. | Lancer des pickers d'IDs bruts ; confondre contrats publics et implementation interne. | DONE : contrats publics recommandes, node verdicts, V1-21 ajuste vers Linked Asset Contracts V0. | V1-20-checkpoint. |
+| NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | Tests contrats/read models purs si code ; sinon `git diff --check`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | Scene Builder sait ce qu'il peut afficher/brancher/diagnostiquer sans lire l'interne complet des assets. | V1-21-prep. |
+| NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes en consommant les contrats publics : Yarn, battle, cinematic si contrat pret, action si consequence contract pret. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal. | workspace Scenes, inspector draft controls, projection refs, diagnostics refs. | Tests pickers refs reelles, refs inconnues diagnostic, boutons honnetes, nodes metier activables seulement avec payload valide. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | Node payloads metier configurables avec vraies refs ou drafts clairement invalides, aucun fake ref. | V1-21. |
+| NS-SCENES-V1-23 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link, pas de migration ScenarioAsset. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy ; cibler des scenes incompletes. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-22. |
+| NS-SCENES-V1-24 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-22, V1-23 utile. |
+| NS-SCENES-V1-25 | Diagnostics / Validator Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions, facts, world rules et Event -> Scene. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, diagnostics world rules/event, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide, erreurs runtime bloquantes explicites. | V1-22, V1-23, V1-24. |
+| NS-SCENES-V1-26 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/dialogue/cinematic/battle/action via callbacks limites. | Pas de full bridge ScenarioAsset, pas StorylineStep link, pas de consequences persistantes implicites. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-24, V1-25. |
+| NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule pickers, diagnostics. | Tests affichage contextuel, picker target, refs inconnues, overview toujours coherent. | World Rules inutilisables si seulement en overview ; UI trop large. | Les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts. | V1-20, V1-25 utile. |
+| NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-22, V1-23, V1-26, V1-27. |
+| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28. |
 
 ## Options comparees
 
@@ -209,6 +211,20 @@ Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune donnee S
 
 Prochain lot exact : `NS-SCENES-V1-21 — Payload Pickers V0`.
 
+## Mise a jour V1-21-prep
+
+Statut : `NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit` est DONE.
+
+Decision : les Payload Pickers ne doivent pas demarrer directement. Le Scene Builder doit stocker des refs stables, mais il doit aussi lire des contrats publics minimaux pour afficher, brancher et diagnostiquer les nodes metier. Ces contrats doivent exposer labels, existence, statut, diagnostics, outputs/outcomes et contraintes sans reveler toute l'implementation interne de Dialogue Yarn, Cinematic/Cutscene, Battle ou Action.
+
+Verdict par famille : Dialogue/Yarn et Battle/Trainer sont les plus proches d'un picker honnete, mais leurs contracts publics doivent etre formalises avant UI. Cinematic/Cutscene reste dangereux tant que Cutscene Studio compile vers `ScenarioAsset` sans vrai contrat cinematic canonique. Action/Consequence reste trop disperse entre ScriptAsset, ScenarioRuntimeExecutor, Facts et World Rules. BranchByOutcome reste disabled tant que les producteurs d'outcomes et les mappings outcome -> edge ne sont pas explicites.
+
+Roadmap : `NS-SCENES-V1-21 — Linked Asset Contracts V0` devient le prochain lot exact. `Payload Pickers V0` est decale en V1-22. `Event -> Scene` reste prioritaire apres que les scenes puissent pointer vers des contenus metier honnetes. `Scene Runtime Plan V0` reste necessaire ensuite. `StorylineStep.sceneLinkIds` reste repousse.
+
+Limites : aucun code, widget, modele, test, build_runner, runtime, Event -> Scene, StorylineStep link, fake data ou donnee Selbrume n'est ajoute.
+
+Prochain lot exact : `NS-SCENES-V1-21 — Linked Asset Contracts V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
@@ -216,6 +232,7 @@ Avant le golden slice, il faut au minimum :
 - Node Authoring V0.
 - Edge Authoring V0.
 - Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
+- Linked Asset Contracts V0 avant Payload Pickers, pour eviter que les pickers ne soient de simples selecteurs d'IDs bruts.
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
 - Event to Scene Trigger Prep pour relier map/event et Scene V1 sans StorylineStep comme declencheur.
 - Scene Runtime Plan V0 pour compiler une Scene valide en intents sans layout.
```

### Tests/analyze exacts

```text
dart analyze : non requis
flutter analyze : non requis
dart test : non requis
flutter test : non requis
build_runner : non requis
```

### Git status final exact

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
```

### Git diff --stat final

```text
 .../scenes/road_map_scene_builder_authoring.md     | 35 ++++++++++++++-----
 reports/narrativeStudio/scenes/road_map_scenes.md  | 39 ++++++++++++++++------
 2 files changed, 54 insertions(+), 20 deletions(-)
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

- le lot est reste documentaire ;
- les chemins demandes ont ete verifies ;
- les assets lies ont ete audites par famille ;
- la decision roadmap est explicite ;
- les roadmaps sont ajustees ;
- aucun code/runtime/widget/modele/test n'a ete modifie.

Limites :

- les contrats recommandes ne sont pas encore codes ;
- `DialoguePublicContract` devra choisir en V1-21 si les outcomes viennent de metadata authoring, d'un parse Yarn assiste, ou d'une declaration separee ;
- `CinematicPublicContract` est le point le plus delicat parce que l'existant passe par `ScenarioAsset` ;
- le statut exact des battle templates reste a clarifier en V1-21.

## Regard critique sur le prompt

Le prompt est utile parce qu'il force a separer trois choses que la roadmap risquait de melanger : ref stockee, contrat public lu par le builder et implementation interne. C'est exactement le bon frein avant de coder des pickers.

Le seul risque du prompt est d'ajouter encore un lot preparatoire alors que le produit a besoin d'avancer. La recommandation limite ce risque : V1-21 doit produire des contrats publics minimaux, pas un grand modele universel. Yarn et trainer battle doivent rester les premiers cas concrets.

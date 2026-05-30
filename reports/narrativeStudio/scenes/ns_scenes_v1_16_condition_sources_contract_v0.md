# NS-SCENES-V1-16 — Condition Sources Contract V0

## Resume executif

Verdict : `NS-SCENES-V1-16 — Condition Sources Contract V0` est realise en documentation-only.

Le contrat retient une V0 volontairement courte. Une Condition Scene V1 pourra lire seulement des sources existantes et presentables sans fausse reference :

- fait existant technique, temporairement fact-like, mappe a `GameState.storyFlags` / `ScriptCondition.flagIsSet` ou `flagIsUnset` ;
- StoryStep complete / non complete, mappe a `PlayerProgression.completedStepIds` et aux predicates `stepCompleted` / `stepNotCompleted` ;
- Event consomme / non consomme, mappe a `GameState.consumedEventIds` et `ScriptCondition.eventIsConsumed`.

Tout le reste est reporte : step active, item/inventory, party/move, script variables, trainer defeated dedie, dialogue outcome local, battle outcome local, world state et World Rules. Ces sources ont des briques techniques partielles, mais pas encore le contrat/picker/registry qui permettrait une UX no-code honnete.

Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.

## Sources inspectees

- `SceneConditionPayload` accepte aujourd'hui `conditionLabel`, `conditionRef`, `conditionDraft`, sans structure source/operator/value.
- `ScriptCondition` fournit un backend technique : flags, variables, field abilities, party moves, consumed events, current map, AND/OR/NOT.
- `GameState` expose `storyFlags`, `scriptVariables`, `progression`, `party`, `bag`, `consumedEventIds`, `currentMapId`.
- `ScriptConditionEvaluator` evalue les flags, variables, field abilities, party moves, events consommes et current map.
- `MapEventDefinition` et `EventPageResolver` prouvent un modele existant de pages conditionnelles basees sur `ScriptCondition`.
- `StorylineStep` porte `entryCondition`, `completionCondition`, `sceneLinkIds`, `expectedOutcomeIds`, et le runtime persiste les steps completes dans `PlayerProgression.completedStepIds`.
- `MapEntityRuntimePredicate` connait deja `storyFlagSet`, `storyFlagUnset`, `stepCompleted`, `stepNotCompleted`.
- Les documents Selbrume confirment que Facts et World Rules doivent etre lisibles, et que le createur ne doit pas manipuler les flags bruts comme experience principale.

## Etat technique actuel

`ScriptCondition` est un bon backend, mais il est trop bas niveau pour devenir directement le payload produit d'un `ConditionNode`.

Sources techniquement matures :

- flags narratifs bool via `GameState.storyFlags.activeFlags` ;
- steps completes via `PlayerProgression.completedStepIds` ;
- event consumed via `GameState.consumedEventIds` ;
- variables bool/int/string via `ScriptVariables` ;
- party move / usable move via `PlayerParty` ;
- current map via `GameState.currentMapId` ;
- field ability via `PlayerProgression.unlockedFieldAbilities`.

Sources techniquement partielles ou trop legacy :

- trainer defeated dedie, actuellement lie a des conventions de story flags/runtime ;
- dialogue/battle outcomes, encore locaux a des nodes ou a des scenarios legacy ;
- world state, disperse entre predicates map/entity, conditional dialogues et futures World Rules.

## Sources conditionnelles analysees

| Source | Nom produit | Description utilisateur | Equivalent technique actuel | Maturite actuelle | V0 | Raison | Picker requis | Diagnostics requis | Risques UX | Risques runtime | Lot recommande |
|---|---|---|---|---|---|---|---|---|---|---|---|
| storyFlag fact-like | Fait existant technique | Lire un fait booleen deja persiste. | `GameState.storyFlags`, `ScriptCondition.flagIsSet/flagIsUnset`, `StoryFlagsManager`. | Backend mature, registry absente. | Oui | Utile et existant, mais temporaire. | Picker de flags existants, avec label humanise et id avance. | source missing/unknown, raw id, future migration. | Revenir aux flags bruts. | Conventions de flags non centralisees. | V1-17 puis Fact Registry V1-18. |
| StoryStep state | Etape narrative completee | Verifier qu'une etape est completee ou non. | `StorylineStep`, `PlayerProgression.completedStepIds`, `MapEntityRuntimePredicate.stepCompleted`. | Lecture completed mature ; active absent. | Oui, completed/nonCompleted seulement | Peut etre picke depuis storylines, sans brancher sceneLinkIds. | Storyline/Chapter/Step picker. | source unknown, operator unsupported. | Confondre Step avec trigger. | Active state non represente. | V1-17. |
| Map/Event consumed | Event deja consomme | Verifier qu'un objet/event local est deja consomme. | `GameState.consumedEventIds`, `ScriptCondition.eventIsConsumed`, `MapEventDefinition`. | Mature cote runtime/state. | Oui | Ref existante si map/event picker disponible. | Map/Event picker. | source unknown, picker required. | Utiliser consumed event comme progression globale. | Event ids dependants map/projet. | V1-17. |
| StoryStep active | Etape narrative active | Verifier qu'une etape est en cours. | Pas d'activeStepIds explicite dans `GameState`; seulement completed. | Insuffisante. | Non | Trop ambigu sans modele d'activation runtime. | StoryStep picker + progression active contract. | future source. | Mentir sur "active". | Derivation fragile depuis completed steps. | Apres progression contract. |
| Inventory / item | Objet possede | Verifier cle, item, quantite. | `Bag`, `BagEntry`, catalog `items`. | State existe, condition backend absent. | Plus tard | Besoin d'un operator quantite et item picker. | Item picker. | source requires picker/value missing. | IDs items techniques. | Consumables/quantites mal interpretes. | Apres Payload Pickers / Fact Registry. |
| Party state | Etat equipe / move | Verifier move connu ou Pokemon utilisable. | `PlayerParty`, `ScriptCondition.partyHasMove/partyHasUsableMove`. | Backend partiel. | Plus tard | Move/species picker requis. | Move/Pokemon picker. | picker required, source unknown. | IDs moves/species visibles. | Etat combat/KO/move incomplet. | Apres picker party/move. |
| Script variable | Variable authoring | Lire bool/int/string authoring. | `ScriptVariables`, `ScriptCondition.variableEquals/GreaterThan/LessThan`. | Backend mature, registry absente. | Non | Sans registry, c'est une variable magique. | Variable registry/picker. | raw technical id, value missing. | Revenir au scripting. | Types et parsing fragiles. | Apres Variable Registry ou Fact Registry typed. |
| Trainer defeated | Dresseur battu | Verifier qu'un trainer est vaincu. | Runtime/story flag conventions, `ProjectTrainer`. | Legacy/partiel. | Non dedie | A representer d'abord comme Fact ou via trainer contract. | Trainer picker + convention. | future source. | Double etat trainer/fact. | Flags conventionnels fragiles. | Apres Battle/Trainer picker ou Fact Registry. |
| Battle outcome local | Resultat combat local | Lire victory/defeat d'un BattleNode. | `SceneEdgeKind.battleVictory/battleDefeat`, legacy outcomes. | Pas pret Scene V1. | Non | Outcome local, pas source persistante. | Battle outcome picker. | future source. | Persistance implicite. | Depend du Runtime Plan. | Apres Runtime Plan / BattleNode. |
| Dialogue outcome local | Resultat dialogue local | Lire confident/hesitant/aggressive. | `SceneEdgeKind.dialogueOutcome`, Yarn expected outcomes. | Pas pret sans Yarn picker. | Non | A router par edges, pas comme condition persistante. | Dialogue/outcome picker. | future source. | Yarn pilote toute progression. | Local/transient. | Apres Payload Pickers. |
| World state / World Rule | Etat visible du monde | Lire porte ouverte, PNJ visible, dialogue alternatif. | Map entity predicates et conditional dialogues. | Disperse. | Non | Une condition lit ; une World Rule decrit le monde. | World Rule picker/contract. | future source. | Scripts caches. | Boucles invisibles. | V1-19/V1-20. |

## Sources V0 autorisees

### `factLikeStoryFlag`

Statut : V0 allowed.

Nom utilisateur recommande : `Fait existant technique`.

Mapping :

```text
sourceKind: factLikeStoryFlag
sourceId: <flagName>
operator: isTrue | isFalse
backend: ScriptCondition.flagIsSet / ScriptCondition.flagIsUnset
runtime storage: GameState.storyFlags.activeFlags
```

Contraintes :

- source temporaire ;
- ne remplace pas `Fact Registry V0` ;
- doit afficher un label humain derive ou fourni par picker ;
- l'id technique doit rester en details avances ;
- pas de saisie libre en workflow normal.

### `storyStepCompletion`

Statut : V0 allowed, mais seulement completed/nonCompleted.

Mapping :

```text
sourceKind: storyStepCompletion
sourceId: <storylineId/chapterId/stepId ou stepId stable>
field: completionStatus
operator: equals
value: completed | notCompleted
backend: completedStepIds / MapEntityRuntimePredicate.stepCompleted
```

Contraintes :

- ne pas exposer `active` en V0 ;
- ne pas brancher `StorylineStep.sceneLinkIds` ;
- ne pas faire du StoryStep un trigger runtime de Scene.

### `consumedEvent`

Statut : V0 allowed.

Mapping :

```text
sourceKind: consumedEvent
sourceId: <mapId:eventId>
operator: isTrue | isFalse
backend: ScriptCondition.eventIsConsumed
runtime storage: GameState.consumedEventIds
```

Contraintes :

- picker map/event obligatoire ;
- source a reserver aux etats locaux comme objet ramasse ou event deja joue ;
- ne doit pas devenir un substitut de Fact global.

## Sources V0 reportees

| Source | Statut | Raison |
|---|---|---|
| step active | V0 disabled | Pas d'active state explicite dans `GameState`. |
| inventory / item | Future after picker | `Bag` existe, mais pas de condition source/picker item V0. |
| party / move | Future after picker | Backend move existe, mais pas de picker no-code suffisant pour V0. |
| script variable | Future after variable registry | Trop technique sans registry authoring. |
| trainer defeated dedie | Future after trainer/fact contract | Etat actuellement conventionnel ; preferer Fact temporaire. |
| dialogue outcome local | Future after Payload Pickers | Outcome local, a router par graph ou BranchByOutcome. |
| battle outcome local | Future after Runtime Plan / battle picker | Outcome local battle, pas source persistante V0. |
| world state / World Rule | Future after World Rule Contract | A traiter comme World Rule, pas comme condition cachee. |
| playerOnMap | Disabled for Scene Condition V0 | `ScriptCondition.playerOnMap` existe, mais la localisation de declenchement doit rester cote Event. |
| fieldAbilityUnlocked | Future after ability picker | Backend existe, mais UX/picker non prioritaire pour Condition V0. |

## Contrat conceptuel ConditionSource

Ce lot ne cree aucune classe. La forme souhaitee pour V1-17 est conceptuelle :

```text
SceneConditionSourceKind:
  factLikeStoryFlag
  storyStepCompletion
  consumedEvent
  inventoryItem
  partyState
  scriptVariable
  trainerDefeated
  dialogueOutcome
  battleOutcome
  worldState

SceneConditionSourceRef:
  sourceKind
  sourceId
  field
  label
  debugTechnicalLabel
  origin

SceneConditionOperator:
  isTrue
  isFalse
  equals
  notEquals
  greaterThan
  lessThan

SceneConditionValue:
  bool
  string
  int
  enum

SceneConditionDraftContract:
  sourceRef
  operator
  value
  displayLabel
  diagnostics
```

Champs obligatoires V0 :

- `sourceKind`
- `sourceId`
- `operator`
- `label`

Champs obligatoires selon source :

- `field` pour `storyStepCompletion` si le contrat garde un status field ;
- `value` pour `equals`;
- `debugTechnicalLabel` seulement pour affichage avance.

Champs affiches a l'utilisateur :

- `label`
- nom de source lisible ;
- operateur traduit ;
- valeur traduite.

Champs techniques a valider :

- `sourceKind`
- `sourceId`
- `field`
- `operator`
- `value`
- `origin`

Interdits V0 :

- expression libre ;
- AND/OR/NOT dans un seul node ;
- saisie manuelle d'ID comme workflow principal ;
- source future selectionnable comme valide.

## Operateurs V0

V0 = une condition simple par `ConditionNode`. Les compositions se font par le graph.

Operateurs autorises :

| Type | Operateurs V0 | Sources |
|---|---|---|
| bool | `isTrue`, `isFalse` | fact-like flag, consumedEvent |
| enum/status borne | `equals` | storyStepCompletion avec `completed` / `notCompleted` |

Operateurs reserves pour plus tard :

- `notEquals` : utile, mais peut etre remplace en V0 par choix de valeur opposee.
- `greaterThan` / `lessThan` : attendre variables typed ou item quantity.
- AND/OR/NOT : attendre un lot d'expressions ou garder la composition dans le graph.

## Diagnostics contractuels

| Code | Severity | Message utilisateur | Declenchement | Bloque runtime ? | Bloque authoring ? | Lot |
|---|---|---|---|---|---|---|
| `conditionSourceMissing` | error | Choisis une source pour cette condition. | Source absente. | Oui | Non | V1-17 |
| `conditionSourceUnknown` | error | Cette source n'existe plus dans le projet. | SourceId introuvable. | Oui | Non | V1-17 |
| `conditionOperatorMissing` | error | Choisis comment tester cette source. | Operateur absent. | Oui | Non | V1-17 |
| `conditionOperatorUnsupported` | error | Cet operateur n'est pas compatible avec cette source. | Operateur hors matrice source/type. | Oui | Non | V1-17 |
| `conditionValueMissing` | error | Cette condition attend une valeur. | `equals` sans value. | Oui | Non | V1-17 |
| `conditionSourceRequiresPicker` | warning | Cette source attend un picker avant d'etre utilisable proprement. | Source future ou picker absent. | Oui si source selectionnee | Non | V1-17/V1-23 |
| `conditionUsesFutureSource` | error | Cette source n'est pas encore supportee dans Scene V1. | Source hors V0. | Oui | Non | V1-17 |
| `conditionUsesRawTechnicalId` | warning | Cette condition affiche un identifiant technique. | Label absent ou id brut visible. | Non si source valide | Non | V1-17 |
| `conditionSourceMigratesToFactRegistry` | info | Ce fait technique sera remplace par la Fact Registry. | fact-like flag temporaire. | Non | Non | V1-18 |

Regle : une condition incomplete peut exister dans l'editeur. Une scene avec un diagnostic condition `error` ne doit pas etre executable plus tard.

## Pickers requis

| Picker | Necessaire en V0 ? | Source de donnees | Risques | Lot recommande |
|---|---|---|---|---|
| Fact-like flag picker | Oui | Flags existants depuis scenarios/story metadata/read models, puis Fact Registry. | Labels humanises insuffisants, ids bruts. | V1-17 puis V1-18 |
| StoryStep picker | Oui | `ProjectManifest.storylines`, chapters, steps. | Confondre completed et active. | V1-17 |
| Map/Event picker | Oui | Maps et `MapEventDefinition` / event ids disponibles. | Event ids locaux utilises comme progression globale. | V1-17 |
| Item picker | Non | Catalog `items`, `Bag`. | Quantites/consommables. | apres item source contract |
| Party/Move picker | Non | Catalog `moves`, `PlayerParty`. | IDs moves, etat KO. | apres move/party picker |
| Variable picker | Non | Future variable registry. | Variables magiques. | apres registry variables/facts typed |
| Trainer picker | Non | `ProjectTrainer`, battle refs. | Double etat trainer/fact. | apres battle/trainer contract |
| Dialogue outcome picker | Non | Yarn/dialogue refs et expected outcomes. | Yarn pilote progression. | apres Payload Pickers |
| Battle outcome picker | Non | BattleNode/runtime plan. | Outcome local persiste implicitement. | apres Runtime Plan/BattleNode |

## Relation avec Facts

`Condition Sources Contract V0` ne cree pas `FactRegistry`.

Champs que `Fact Registry V0` devra fournir :

- `factId`
- `label`
- `description`
- `type` : bool en V0, puis number/text/enum plus tard
- `category` ou domaine narratif
- `defaultValue`
- `debugTechnicalId` ou mapping vers storage runtime
- tags/auteur/notes

Migration/wrapping futur :

- les `factLikeStoryFlag` V0 peuvent devenir des refs `factId` si le Fact Registry adopte le meme id ;
- sinon, la registry devra porter un champ `legacyFlagName`;
- l'UI devra afficher le Fact et masquer le flag, sauf details avances.

Risque principal si on expose directement `GameState.storyFlags` : le Scene Builder devient un editeur de flags en costume no-code. La source V0 doit donc rester explicitement temporaire.

## Relation avec World Rules

Une condition lit. Une World Rule change l'apparence ou le comportement du monde.

Sources partageables plus tard :

- Fact / fact-like flag ;
- StoryStep completed/nonCompleted ;
- variables authoring ;
- event consumed si usage local ;
- item/party state si le projet les expose comme sources.

Propres aux Conditions :

- outcomes locaux de dialogue/battle quand ils servent a brancher une scene ;
- conditions transitoires liees a l'execution d'une scene.

Propres aux World Rules :

- visibilite PNJ ;
- dialogue alternatif ;
- porte/collision/route ouverte ;
- map state et ambiance ;
- disponibilite d'event ou d'objet.

Anti-script-cache :

- toute World Rule doit etre inspectable depuis l'objet/map concerne ;
- toute source doit etre pickee ;
- les effets doivent etre declares comme effets de monde, pas caches dans une condition Scene.

## Relation avec Actions / Consequences

Une condition lit. Une action ecrit.

Actions a cadrer dans les lots futurs :

- `setFact`
- `clearFact`
- `completeStoryStep`
- `activateStoryStep`
- `giveItem`
- `startTrainerBattle`
- `openYarnDialogue`
- `playCinematic`

Dependances partagees :

- `setFact` / `clearFact` dependent de Fact Registry.
- `completeStoryStep` / `activateStoryStep` dependent du StoryStep picker et du progression contract.
- `giveItem` depend de l'Item picker.
- `startTrainerBattle` depend du trainer/battle picker et du Runtime Plan.
- `openYarnDialogue` depend du dialogue/outcome picker.
- `playCinematic` depend du cinematic picker.

## Impact Selbrume

| Exemple Selbrume | Source recommandee | Disponible V0 ? | Picker requis | Lot futur |
|---|---|---|---|---|
| Rival battu au port = false | factLikeStoryFlag temporaire, puis Fact Registry | Oui temporaire | Fact-like flag picker | V1-17 puis V1-18 |
| Etape "Annonce au port" active | StoryStep active | Non | StoryStep picker + active progression contract | apres V1-17 |
| Etape "Combat rival" completee | storyStepCompletion | Oui pour completed/nonCompleted | StoryStep picker | V1-17 |
| Le joueur possede la cle de la cabane | inventoryItem ou Fact "cle obtenue" | Non direct ; oui via Fact temporaire si deja flagge | Item picker ou Fact picker | V1-18+ |
| Le joueur a aide le Goelise | Fact | Oui temporaire si flag existe | Fact-like flag picker puis Fact picker | V1-17/V1-18 |
| Passage vers le phare debloque | Fact + World Rule | Fact temporaire oui ; World Rule non | Fact picker puis World Rule picker | V1-18/V1-20 |

Aucune donnee Selbrume n'est creee. Ces exemples restent conceptuels et ne hardcodent aucun ID dans le produit.

## Roadmap update

- `road_map_scenes.md` marque `NS-SCENES-V1-16` comme DONE.
- `road_map_scene_builder_authoring.md` marque `NS-SCENES-V1-16` comme DONE.
- Le prochain lot recommande devient `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
- V1-17 n'est pas marque commence.

## Prochain lot exact

`NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`

Scope recommande :

- configurer un `ConditionNode` uniquement avec `factLikeStoryFlag`, `storyStepCompletion`, `consumedEvent` ;
- pas d'expression libre ;
- pas de Fact Registry ;
- pas de World Rules ;
- pas de runtime ;
- diagnostics condition V0 ;
- pickers/menus uniquement pour sources existantes.

## Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md`

Fichiers modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests/analyze non requis

- `dart analyze` non requis : aucun fichier Dart modifie.
- `flutter analyze` non requis : aucun widget ou fichier Flutter modifie.
- `dart test` non requis : aucun code ni test modifie.
- `flutter test` non requis : aucun code ni widget modifie.
- Verification obligatoire : `git diff --check`.

## Git status initial

Commande : `pwd`

```text
/Users/karim/Project/pokemonProject
```

Commande : `git branch --show-current`

```text
main
```

Commande : `git status --short --untracked-files=all`

```text
Sortie : <vide>
```

Commande : `git diff --stat`

```text
Sortie : <vide>
```

Commande : `git log --oneline -n 10`

```text
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
```

## Git status final

Commande : `git status --short --untracked-files=all`

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md
```

Commande : `git diff --stat`

```text
 .../scenes/road_map_scene_builder_authoring.md     | 16 ++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 36 ++++++++++++++++++++--
 2 files changed, 46 insertions(+), 6 deletions(-)
```

Commande : `git diff --name-only`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git diff --check`

```text
Sortie : <vide>
```

## Evidence Pack

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`

Fichier absent : aucun fichier obligatoire attendu n'est absent.

Impact : aucun.

### Contenu complet du rapport cree

Le present fichier est le rapport cree pour `NS-SCENES-V1-16`; son contenu complet correspond a l'integralite de ce document.

### Diff complet de road_map_scenes.md et road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 649a3820..fc580039 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-16 — Condition Sources Contract V0
+NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)
 ```
 
 ## Principes
@@ -34,7 +34,7 @@ NS-SCENES-V1-16 — Condition Sources Contract V0
 | NS-SCENES-V1-15 | Visual Port Connection UX V0 | editor | Transformer la connexion V1-13 en interaction Blueprint-like : ports visibles, preview wire, highlight/snap, drop sur input. | Pas de runtime, pas de suppression/reconnexion avancee, pas de ports complexes pour nodes desactives. | graph canvas, node cards, connection state tests. | DONE : ports visibles, drag output, preview line, target highlight, drop valide cree edge, drop vide annule. | Reintroduire drag-and-drop trop large ; rendre actifs des nodes sans payload honnete. | DONE : connexion visuelle claire, toujours basee sur ports V0, aucune fake ref. | V1-14. |
 | NS-SCENES-V1-15-bis | Edge Selection / Deletion UX V0 | core / editor | Rendre les liens corrigibles : selection locale d'edge, highlight, inspecteur de lien, suppression memoire. | Pas de reconnexion avancee, pas de payload picker, pas de runtime, pas d'edition de condition. | `scene_authoring_operations.dart`, graph view, inspector, workspace Scenes. | Tests remove edge core, selection/highlight inspector, suppression, nodes/layout preserves, creation V1-15 apres suppression. | Supprimer trop large ; casser les ports visuels ou selection node ; confondre edge layout et graph logique. | DONE : edge selectionnable et supprimable, ProjectManifest.scenes mis a jour en memoire, aucune fake ref. | V1-15. |
 | NS-SCENES-V1-16-prep | Condition Sources / Facts / World Rules Roadmap Review | doc-only / architecture-review | Decider si Condition Authoring peut commencer sans cadrer Facts, World Rules et sources conditionnelles. | Pas de code, pas de widget, pas de modele, pas de runtime. | rapport V1-16-prep, roadmaps. | `git diff --check` uniquement. | Rester trop abstrait ou bloquer inutilement l'authoring. | DONE : option hybride retenue, prochain lot exact defini, roadmaps ajustees. | V1-15-bis. |
-| NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport ou read model pur si necessaire, `scene_diagnostics.dart` seulement si diagnostic contractuel decide. | Si code absent : `git diff --check`; si read model pur : tests core/analyze. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | Contrat clair pour Fact, StoryStep, event consumed, party, inventory, variable et world state, avec sources V0 autorisees. | V1-16-prep. |
+| NS-SCENES-V1-16 | Condition Sources Contract V0 | doc / core-design | Definir les sources conditionnelles no-code, leur maturite, mapping technique, pickers, diagnostics et limite runtime. | Pas de Condition UI complete, pas de Fact Registry codee, pas de World Rule runtime. | rapport V1-16, roadmaps. | `git diff --check` uniquement. | Sur-documenter ; ou exposer `ScriptCondition` brut comme UX. | DONE : sources V0 autorisees/reportees, contrat conceptuel, operateurs, diagnostics et pickers definis. | V1-16-prep. |
 | NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | Condition configurable via source explicite, scene invalide si condition incomplete bloquante. | V1-16. |
 | NS-SCENES-V1-18 | Fact Registry V0 | core / editor | Ajouter une registry authoring de Facts lisibles, bool-first, avec labels, descriptions et categories pour pickers no-code. | Pas de World Rules completes, pas de runtime Scene complet, pas de types avances obligatoires. | `ProjectManifest` si decide, read models/pickers, tests serialization. | Tests registry JSON, picker refs, diagnostics refs inconnues. | Confondre Fact et StoryStep ; exposer seulement des IDs techniques. | Facts lisibles, refs stables, mapping runtime documente vers etat persistant. | V1-16, V1-17 utile. |
 | NS-SCENES-V1-19 | World Rule Contract V0 | doc / core-design | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions. | Pas de runtime complet, pas de Map Editor lourd, pas de seed Selbrume. | rapport contractuel, event/map model audit. | `git diff --check` ou tests core si modele pur. | Faire des World Rules des scripts caches ; creer des boucles invisibles. | Types de regles, sources, effets, priorites et diagnostics de base definis. | V1-18 recommande. |
@@ -110,7 +110,17 @@ Decision : V1-15-bis ajoute la correction des liens sans ouvrir la reconnexion a
 
 Limites : pas de reconnexion, pas de suppression node, pas de payload picker, pas de runtime, pas d'edition Condition.
 
-Prochain lot exact : `NS-SCENES-V1-16 — Condition Sources Contract V0`.
+Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
+
+## Mise a jour V1-16
+
+Statut : `NS-SCENES-V1-16 — Condition Sources Contract V0` est DONE.
+
+Decision : le contrat V0 autorise seulement les sources qu'on peut exposer sans inventer de refs : fait existant technique fact-like, step complete/non complete et event consomme/non consomme. `ScriptCondition` reste un backend technique, pas une UX. Les sources inventory, party, script variables, trainer defeated dedie, dialogue/battle outcomes et World Rules sont reportees jusqu'aux pickers, registries ou runtime plans correspondants.
+
+Limites : aucun code, aucun widget, aucun modele, aucun runtime, aucune Fact Registry, aucune World Rule.
+
+Prochain lot exact : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`.
 
 ## Mise a jour V1-16-prep
 
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 5ed17515..dcaa2fa5 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -55,7 +55,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-15 — Visual Port Connection UX V0 | DONE | Ports visuels V0, drag depuis output, preview wire, highlight/snap des inputs compatibles, drop valide cree un edge via les regles V1-13, drop vide annule. |
 | NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0 | DONE | Selection locale d'edge, highlight visuel, inspecteur de lien et suppression d'edge en memoire via operation pure, sans runtime ni reconnexion avancee. |
 | NS-SCENES-V1-16-prep — Condition Sources / Facts / World Rules Roadmap Review | DONE | Revue architecture/roadmap : refuser une Condition V0 textuelle magique, cadrer sources metier, Facts, World Rules et consequences avant authoring payload. |
-| NS-SCENES-V1-16 — Condition Sources Contract V0 | TODO | Definir le contrat no-code des sources de condition, leur mapping vers l'existant, leurs pickers requis et les diagnostics attendus, sans UI payload complete. |
+| NS-SCENES-V1-16 — Condition Sources Contract V0 | DONE | Contrat no-code des sources de condition : sources V0 autorisees, sources reportees, mapping technique, operateurs, pickers et diagnostics, sans code ni UI. |
 | NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | TODO | Configurer un `ConditionNode` V0 uniquement avec des sources existantes et honnetes, sans texte magique ni refs inventees. |
 | NS-SCENES-V1-18 — Fact Registry V0 | TODO | Ajouter une registry authoring de Facts lisibles, bool-first, preparant les pickers no-code et le mapping runtime vers l'etat persistant. |
 | NS-SCENES-V1-19 — World Rule Contract V0 | TODO | Formaliser les World Rules comme regles visibles derivees de Facts/Steps/conditions, sans encore brancher tout le runtime. |
@@ -70,9 +70,39 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-16 — Condition Sources Contract V0`
+`NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`
 
-Raison : V1-15-bis rend les connexions corrigibles, mais une Condition V0 ne doit pas devenir un champ texte technique. Avant de coder l'authoring du payload, il faut definir les sources lisibles, leurs mappings vers `GameState` / `ScriptCondition` / progression, les pickers requis, les diagnostics et les limites d'execution.
+Raison : V1-16 fixe maintenant le contrat no-code des sources conditionnelles. Le prochain lot peut coder l'authoring d'un `ConditionNode` limite aux sources V0 autorisees, sans expression libre, sans Fact Registry, sans World Rules et sans runtime.
+
+## Decisions V1-16
+
+- Lot documentation-only : aucun code, widget, modele Dart, runtime, test ou fixture n'est modifie.
+- Sources V0 autorisees : fait existant technique (`storyFlag` fact-like), step complete/non complete, event consomme/non consomme.
+- Sources V0 reportees : step active, inventory/item possession, party/move state, script variables, trainer defeated dedie, dialogue outcome local, battle outcome local, world state / World Rule.
+- Le contrat conceptuel retient une forme `sourceKind`, `sourceId`, `field`, `operator`, `value`, `label`, `debugTechnicalLabel`, sans creer de classe Dart dans ce lot.
+- V0 = une condition simple par `ConditionNode`; pas de AND/OR libre. La composition se fait par le graph avec nodes et edges.
+- Operateurs V0 : `isTrue`, `isFalse`, et `equals` limite aux statuts enumeres supportes.
+- Les sources temporaires fact-like doivent etre presentees comme "faits existants techniques" et migrees/wrappees par `Fact Registry V0`.
+- Les diagnostics contractuels prioritaires sont : source manquante/inconnue, operateur manquant/non supporte, valeur manquante, source future, picker requis, id technique brut.
+- Prochain lot : coder seulement l'authoring des sources autorisees, avec diagnostics et refus runtime futur si erreur.
+
+## Limites V1-16
+
+- Pas de `FactRegistry`.
+- Pas de `WorldRule`.
+- Pas de modification `SceneAsset` ou `ProjectManifest`.
+- Pas de Condition UI codee.
+- Pas de payload picker code.
+- Pas de runtime Scene.
+- Pas de StorylineStep link, Event -> Scene ou donnee Selbrume.
+
+## Tests V1-16
+
+- Dart analyze non requis : lot documentation-only.
+- Flutter analyze non requis : lot documentation-only.
+- Dart test non requis : lot documentation-only.
+- Flutter test non requis : lot documentation-only.
+- Verification requise : `git diff --check`.
 
 ## Decisions V1-16-prep
```

### Sorties finales

Commande : `git status --short --untracked-files=all`

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md
```

Commande : `git diff --stat`

```text
 .../scenes/road_map_scene_builder_authoring.md     | 16 ++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 36 ++++++++++++++++++++--
 2 files changed, 46 insertions(+), 6 deletions(-)
```

Commande : `git diff --name-only`

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande : `git diff --check`

```text
Sortie : <vide>
```

## Auto-review critique

- Le contrat V0 est strict : il ne cherche pas a exploiter tout `ScriptCondition`, seulement ce qui peut etre presente sans mentir.
- Le choix de reporter `scriptVariable` est volontaire, meme si le backend existe, car il n'y a pas de registry no-code.
- Le choix de reporter `step active` est important : le runtime a `completedStepIds`, pas un modele clair d'etapes actives.
- Le risque residuel est que le futur picker fact-like humanise mal des flags techniques ; `Fact Registry V0` devra corriger cela.
- V1-17 devra resister a la tentation d'ajouter item/party/variables en meme temps.

## Regard critique sur le prompt

Le prompt est bien cale apres V1-16-prep : il demande un contrat plutot qu'une implementation. Sa principale difficulte est la tentation d'autoriser trop de sources parce que `ScriptCondition` sait deja les evaluer. La bonne lecture est produit : V0 doit etre plus etroite que le backend technique pour rester no-code.

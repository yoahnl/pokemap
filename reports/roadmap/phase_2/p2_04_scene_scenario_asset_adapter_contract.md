# P2-04 — Scene / ScenarioAsset Adapter Contract

## 1. Résumé exécutif

P2-04 décide la relation canonique entre le concept produit **Scene** et le modèle technique existant `ScenarioAsset`.

Décision recommandée :

```text
Scene n'est pas un nouveau modèle persistant.
ScenarioAsset reste le substrat technique persistant et exécutable.
La trajectoire saine est un adapter / read model non persistant futur,
dérivé de ScenarioAsset, lorsque P2-05 / P2-09 / P2-10 préciseront outcomes,
diagnostics et picker sources.
```

Le lot reste donc **design-only** :

- aucun code créé ;
- aucun package modifié ;
- aucun `ProjectManifest` modifié ;
- aucun JSON, Freezed, JsonSerializable ou build_runner ;
- aucun Scene Builder ;
- aucun contenu Selbrume ;
- P2-05 non démarré.

Prochain lot exact :

```text
P2-05 — Outcome Reference Contracts
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports demandés ;
- audit ciblé de `ScenarioAsset`, graph nodes / edges / payloads, runtime execution, validators et projections editor ;
- comparaison des options Scene / `ScenarioAsset` ;
- décision d'implémentation P2-04 ;
- contrat conceptuel `SceneReadModel` non implémenté ;
- diagnostics possibles à reporter ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- modèle `map_core` ;
- JSON / migration ;
- Freezed / JsonSerializable ;
- `build_runner` ;
- `ProjectManifest` ;
- tests Dart/Flutter ;
- UI ;
- Scene Builder ;
- Cinematic Builder ;
- contenu final Selbrume ;
- P2-05.

Fichiers créés :

```text
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_2.md
```

Fichiers explicitement non modifiés :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
packages/map_core
packages/map_gameplay
packages/map_battle
packages/map_runtime
packages/map_editor
examples/playable_runtime_host
```

Note de scope : P2-04 n'a modifié aucun de ces chemins. Le dernier passage de
validation hors scope ne signale aucun changement dans ces chemins.

## 3. Sources lues

Roadmaps et rapports :

| Source | Rôle |
|---|---|
| `AGENTS.md` | Règles repo, Git safety, no-code first, package boundaries. |
| `MVP Selbrume/road_map_global.md` | Contexte global lu, non modifié. |
| `MVP Selbrume/road_map_phase_2.md` | Roadmap vivante Phase 2 à mettre à jour. |
| `MVP Selbrume/road_map_phase_1.md` | Phase 1 clôturée, lue pour contexte. |
| `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md` | Frontière P2-00 / P2-01 et rôle P2-04. |
| `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` | Inventaire technique de l'existant narratif. |
| `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md` | Décision adapter/read model pour Storyline / Chapter / Step. |
| `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` | Décision design-only Event Authoring Source. |
| `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md` | Clôture Phase 1 et concepts figés. |
| `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` | Proposition Phase 2 initiale. |
| `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` | Workflows no-code, Scene comme orchestration. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Frontière Event / Scene / Cinematic. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Glossaire canonique Phase 1. |
| `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md` | Règle de vérification avant clôture. |

Fichiers techniques lus en lecture seule :

| Source | Rôle |
|---|---|
| `packages/map_core/lib/src/models/scenario_asset.dart` | Définition `ScenarioAsset`, scopes, nodes, edges, bindings, payloads. |
| `packages/map_core/lib/src/models/project_manifest.dart` | Agrégation persistante des scenarios dans `ProjectManifest`. |
| `packages/map_core/lib/src/operations/narrative_validator.dart` | Diagnostics narratifs multi-diagnostics existants. |
| `packages/map_core/lib/src/validation/validators.dart` | Validation stricte `ProjectValidator`, dont scenarios. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | Runtime events, effects et execution context. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | Exécution des sources, actions, conditions et continuations. |
| `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` | CRUD `ScenarioAsset` côté editor. |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | Projection editor read-only des scenarios, steps et outcomes. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart` | Compilation Cutscene Studio vers `ScenarioAsset`. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart` | Modèle authoring Cutscene Studio et support runtime déclaré. |

## 4. Rappel Phase 1 / P2-01 / P2-02 / P2-03

Phase 1 a figé :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Validator diagnostique.
```

P2-01 a observé que `ScenarioAsset` est déjà le graphe scénario persistant principal : il porte `scope`, `entryNodeId`, `nodes`, `edges`, `declaredOutcomes`, `activationCondition` et `metadata`.

P2-02 a refusé les descriptors persistants Storyline / Chapter / Step pour l'instant, en recommandant adapter/read model non persistant.

P2-03 a refusé un modèle Event persistant et a recommandé un futur `EventAuthoringSourceReadModel` dérivé des source nodes de `ScenarioAsset`.

P2-04 applique la même prudence à Scene.

## 5. Problème à résoudre

Le vocabulaire produit dit :

```text
Scene orchestre.
```

Le code existant dit :

```text
ScenarioAsset persiste et exécute aujourd'hui un graphe de sources,
conditions, actions, outcomes et metadata.
```

La question n'est donc pas de créer un modèle "Scene" parce que le mot existe. La question est de savoir si le produit a besoin d'une vue lisible au-dessus du graphe technique.

Risques principaux :

- créer un `Scene` model parallèle qui duplique `ScenarioAsset` ;
- casser les validators et runtime existants ;
- mélanger Scene et Cinematic ;
- rendre Event responsable de l'orchestration ;
- migrer `ProjectManifest` sans consumer prouvé ;
- lancer un Scene Builder avant d'avoir stabilisé outcomes et diagnostics.

## 6. Inventaire ScenarioAsset comme support de Scene

Observé dans `scenario_asset.dart` :

| Élément | Observation | Lien avec Scene |
|---|---|---|
| `ScenarioAsset.id` / `name` / `description` | Identité persistante et label technique/humain. | Base du `sceneId` / label. |
| `ScenarioScope.globalStory` | Graphe de progression narrative globale. | Peut représenter des scènes de progression globale. |
| `ScenarioScope.localEventFlow` | Flow local branché sur des hooks monde. | Couvre les scènes déclenchées par Event. |
| `entryNodeId` | Node d'entrée persisté. | Point d'entrée technique, pas nécessairement langage auteur. |
| `declaredOutcomes` | Outcomes métier déclarés par scénario. | Base de P2-05. |
| `activationCondition` | Gating optionnel via `ScriptCondition`. | Condition d'entrée de la Scene / flow. |
| `nodes` | Graphe de sources, dialogues, actions, conditions, choices, references, ends. | Orchestration existante. |
| `edges` | Ordre et branches. | Orchestration existante. |
| `metadata` | Metadata authoring Step / Global Story / Cutscene. | Source editor, pas domaine pur canonique. |

Ce que `ScenarioAsset` couvre déjà :

- persistance dans `ProjectManifest.scenarios` ;
- graphe d'orchestration ;
- références dialogue / script / trainer / map / entity / outcome ;
- conditions via `ScriptCondition` ;
- outcomes déclarés ;
- metadata d'authoring ;
- exécution runtime via `ScenarioRuntimeExecutor` ;
- validation via `ProjectValidator` et `NarrativeValidator`.

Ce que le concept produit Scene ajoute :

- vocabulaire humain "Scène" plutôt que "ScenarioAsset" ;
- résumé des sources, actions, conditions, outcomes et conséquences ;
- séparation lisible entre source Event, orchestration Scene et mise en scène Cinematic ;
- diagnostic auteur centré sur les blocs ;
- future source de picker sans exposer les node IDs.

Conclusion :

```text
ScenarioAsset est la source technique actuelle.
Scene est une vue produit de l'orchestration portée par ScenarioAsset.
```

## 7. Inventaire graph nodes / edges / payloads

Observé :

| Élément | Observation | Interprétation P2-04 |
|---|---|---|
| `ScenarioNodeType.start` | Début technique du graphe. | Infrastructure de graphe, pas concept Scene séparé. |
| `ScenarioNodeType.reference` | Source runtime si `actionKind` est `source*`; sinon authoring-only. | Les references source relèvent plutôt d'Event. |
| `ScenarioNodeType.dialogue` | Dialogue asset / script / message inline possible côté runtime. | Bloc Scene d'orchestration dialogue. |
| `ScenarioNodeType.action` | Porte `actionKind` et paramètres. | Bloc Scene d'orchestration. |
| `ScenarioNodeType.condition` | Branching via `ScriptCondition`. | Condition de Scene, pas nouveau DSL. |
| `ScenarioNodeType.choice` | Validé, compilable, mais runtime MVP bloque explicitement. | Besoin de diagnostic de support runtime. |
| `ScenarioNodeType.end` | Fin de flow. | Fin Scene / branche. |
| `ScenarioEdgeKind.next` | Séquence linéaire. | Ordre Scene. |
| `ScenarioEdgeKind.trueBranch` / `falseBranch` | Branches conditionnelles. | Branching Scene. |
| `ScenarioEdgeKind.choice` | Branches de choix. | P2-05/P2-09 devront préciser outcomes/choix. |
| `ScenarioNodeBinding` | `mapId`, `eventId`, `entityId`, `warpId`, `triggerId`, `trainerId`, `dialogueId`, `scriptId`, `outcomeId`, `flagName`, `variableName`. | Données à résumer dans un read model, sans les copier comme source de vérité. |
| `ScenarioNodePayload` | `actionKind`, `message`, `condition`, `choiceLabels`, `params`. | Supporte l'orchestration, mais reste technique. |

Parties relevant de Scene :

- dialogue ;
- script ;
- message ;
- action gameplay ;
- condition ;
- battle handoff ;
- emit outcome ;
- complete step ;
- set / clear flag ;
- transition map ;
- movement / follow / face ;
- flow merge ;
- end.

Parties relevant d'Event :

- source map enter ;
- source trigger enter ;
- source entity interact ;
- source outcome ;
- matching source event ;
- conditions d'activation d'entrée.

Parties relevant d'outcomes :

- `declaredOutcomes` ;
- `emitOutcome` ;
- `sourceOutcome` ;
- `ScenarioRuntimeSourceEvent.outcomeReceived` ;
- flags `scenario.outcome.*`.

## 8. Inventaire runtime execution

Observé dans `ScenarioRuntimeExecutor` :

Sources runtime supportées :

```text
sourceMapEnter
sourceTriggerEnter
sourceEntityInteract
sourceOutcome
```

Actions / effets supportés ou traités :

| Action / node | Runtime actuel | Lecture P2-04 |
|---|---|---|
| `openDialogue` / node dialogue | Ouvre dialogue si `dialogueId`; sinon script/message possibles. | Bloc Scene réel. |
| `runScript` | Lance un script via callback. | Bloc Scene réel mais technique. |
| `showMessage` | Affiche un message. | Bloc Scene réel. |
| `setFlag` / `clearFlag` | Mutations `GameState` via story flags. | Conséquences techniques ; Fact presentation future. |
| `emitOutcome` | Pose `scenario.outcome.*`, dispatch outcome global, puis continue localement. | P2-05 central. |
| `moveCharacter` | Callback runtime, peut attendre. | Mise en scène / cinematic-like, mais orchestrée par Scene. |
| `followCharacter` | Callback runtime. | Mise en scène dans Scene, pas Cinematic Builder. |
| `faceCharacter` | Callback runtime. | Mise en scène simple. |
| `transitionMap` | Callback runtime. | Action Scene / runtime. |
| `startTrainerBattle` | Retourne effet battle et suspend le graphe. | Battle résout ; Scene reprend/interprète. |
| `givePokemon` | Mutation pure `GameState`. | Gameplay reward, hors décision Scene. |
| `giveItem` | Mutation pure `GameState`. | Gameplay reward partiel. |
| `completeStep` | Mutate `completedStepIds`. | Conséquence durable de Scene. |
| `flowMerge` | Passthrough. | Structure d'orchestration. |
| `authoringPlaceholder` | Passthrough avec message honnête. | Bloc authoring non runtime complet. |
| `condition` | Évaluée via `ScriptConditionEvaluator`. | Branching Scene. |
| `choice` | Bloqué explicitement en runtime MVP. | Diagnostic nécessaire, pas preuve runtime complète. |
| `reference` non-source | Bloqué authoring-only. | Ne doit pas être vendu comme runtime Scene. |

Conclusion runtime :

```text
ScenarioAsset exécute déjà une part importante de l'orchestration Scene,
mais tout le graphe authorable n'est pas runtime-complet.
Un SceneReadModel futur doit exposer ce support sans prétendre que tout est exécutable.
```

## 9. Inventaire validation existante

`ProjectValidator` valide déjà :

- IDs scénario uniques ;
- scénario non vide ;
- nom scénario non vide ;
- `declaredOutcomes` non vides et sans doublons ;
- `activationCondition` valide ;
- exactement un start node ;
- `entryNodeId` existant ;
- node IDs / edge IDs non vides et uniques ;
- edges vers nodes existants ;
- choice / condition avec au moins deux sorties ;
- end sans sortie ;
- références script / dialogue / map / trainer ;
- `emitOutcome` / `sourceOutcome` avec `outcomeId` ;
- contraintes scope : `globalStory` ne peut pas utiliser world source kinds, `localEventFlow` ne peut pas utiliser `sourceOutcome`.

`NarrativeValidator` produit déjà des diagnostics multi-diagnostics :

- edge vers node inconnu ;
- node inaccessible ;
- graphe sans source runtime ;
- dialogue inconnu ;
- trainer battle incomplet ou trainer inconnu ;
- source entity interact vers map/entity inconnue ;
- outcome consommé jamais émis ;
- outcome émis jamais consommé ;
- flags lus jamais produits ;
- flags produits jamais lus ;
- steps lus jamais complétés ;
- steps complétés jamais lus ;
- dialogues conditionnels inconnus.

Ce qui manque pour une vue Scene :

- diagnostics formulés en langage "Scene" ;
- classification source nodes vs action nodes ;
- déclaration "runtime-supported" vs "authoring-only" ;
- résumé des dialogues, battles, steps, flags, outcomes ;
- detection de Scene sans fin lisible ;
- mapping des branches choice/outcome à P2-05 ;
- diagnostics de Scene qui contient uniquement une source sans bloc exécutable.

Ces ajouts relèvent de P2-09 et P2-10, pas d'une implémentation P2-04.

## 10. Inventaire editor use cases / projections

`project_scenario_use_cases.dart` observe :

- création, update et suppression de `ScenarioAsset` dans `ProjectManifest.scenarios` ;
- génération d'ID stable et lisible ;
- validation via `ProjectValidator.validate` ;
- sauvegarde via repository editor.

`narrative_workspace_projection.dart` observe :

- `NarrativeScenarioSummary` dérive une vue read-only : id, name, description, scope, entry node, node count, edge count, outcomes déclarés/émis/consommés ;
- séparation `globalStories` / `localEventFlows` ;
- projection outcomes ;
- projection Step depuis metadata Step Studio ;
- aucune mutation du `ProjectManifest`.

`cutscene_studio_models.dart` observe :

- le Cutscene Studio est un modèle d'authoring Flutter/editor ;
- il porte des labels no-code et des blocs guidés ;
- son document est stocké en metadata `ScenarioAsset` ;
- certains blocs sont runtime-supported, d'autres compilent en placeholder ;
- la source du flow est explicitement séparée des blocs.

`cutscene_studio_compiler.dart` observe :

- compilation `CutsceneStudioDocument` vers `ScenarioAsset` ;
- source node `reference` + `source*` ;
- blocks transformés en `ScenarioNode` / `ScenarioEdge` ;
- outcomes déclarés collectés depuis le flow ;
- metadata `authoring.cutsceneFlow` écrite pour reprise UI ;
- scope `localEventFlow`.

Conclusion editor :

```text
map_editor contient déjà des projections et authoring models utiles,
mais ils ne doivent pas devenir la source de vérité domaine.
Un adapter Scene futur doit être dérivé du ScenarioAsset existant.
```

## 11. Consumers explicites

| Consumer | Besoin | Besoin immédiat ? | Persistence nécessaire ? |
|---|---|---:|---:|
| P2-05 Outcome Reference Contracts | Lire declared/emitted/consumed outcomes par Scene. | Oui, mais décision suffit maintenant. | Non. |
| P2-09 Narrative Validator | Diagnostics centrés Scene : support runtime, références, branches. | Futur proche. | Non. |
| P2-10 Reference Picker Read Models | Picker Scene, labels humains, statut runtime-supported. | Futur proche. | Non. |
| Future Event picker | Target Scenario/Scene lisible. | Futur. | Non. |
| Phase 4 authoring minimal | Afficher "Scène" sans node IDs. | Futur. | Non au départ. |
| `map_runtime` | Exécuter `ScenarioAsset`. | Déjà servi. | Non. |
| `ProjectValidator` | Validation stricte du graphe. | Déjà servi. | Non. |
| `NarrativeWorkspaceProjection` | Résumés editor read-only. | Déjà partiel. | Non. |

Aucun consumer ne justifie aujourd'hui :

- un wrapper persistant Scene ;
- une migration `ProjectManifest` ;
- une duplication de `ScenarioAsset`.

## 12. Options de relation Scene / ScenarioAsset

### Option A — Scene = nom produit de ScenarioAsset

Avantages :

- aucune migration ;
- aucune duplication ;
- cohérent avec le runtime actuel ;
- simple à expliquer en Phase 2.

Risques :

- le vocabulaire `ScenarioAsset` reste trop technique pour l'authoring ;
- ne distingue pas source Event, orchestration Scene, authoring metadata et runtime support ;
- pickers et diagnostics restent pauvres.

Verdict :

```text
Acceptable comme règle courte actuelle, insuffisant comme trajectoire produit.
```

### Option B — Adapter/read model non persistant

Avantages :

- dérive de `ScenarioAsset` sans nouveau stockage ;
- fournit labels, classification et diagnostics ;
- respecte "adapter avant de persister" ;
- alimente P2-05 / P2-09 / P2-10 ;
- évite de faire de `map_editor` la source de vérité domaine.

Risques :

- l'adapter peut grossir et devenir un modèle persistant déguisé ;
- il dépendra des décisions P2-05 sur outcomes ;
- il doit rester honnête sur les nodes authoring-only.

Verdict :

```text
Option recommandée comme trajectoire principale.
Aucune implémentation maintenant.
```

### Option C — Contrat pur minimal dans map_core

Avantages :

- pourrait centraliser `SceneReadModel` ;
- tests pure Dart possibles ;
- consumers P2-09/P2-10 plus clairs.

Risques :

- trop tôt avant P2-05 ;
- risque de figer les mauvais champs ;
- pourrait dupliquer `NarrativeWorkspaceProjection` ;
- consumer immédiat insuffisant dans P2-04.

Verdict :

```text
À reconsidérer après P2-05, P2-09 ou P2-10.
Pas maintenant.
```

### Option D — Wrapper persistant / nouveau Scene model

Avantages :

- identité Scene explicite ;
- pourrait découpler produit et scénario technique à long terme.

Risques :

- duplication massive de `ScenarioAsset` ;
- migration `ProjectManifest` ;
- divergence runtime / editor / validator ;
- modèle parallèle inutile ;
- coût élevé sans consumer prouvé.

Verdict :

```text
Refusé maintenant.
```

### Option E — Report complet

Avantages :

- aucune décision prématurée.

Risques :

- P2-05 manque un socle conceptuel pour outcomes ;
- P2-09/P2-10 manquent une cible de diagnostics/pickers ;
- Event/Scene boundary reste trop floue pour la suite.

Verdict :

```text
Refusé. P2-04 doit au moins décider la trajectoire.
```

## 13. Matrice comparative

| Option | Complexité | Migration | Duplication | Support P2-05 | Support P2-09/P2-10 | Recommandation |
|---|---:|---:|---:|---:|---:|---|
| A — Nom produit | Faible | Non | Non | Partiel | Partiel | Base actuelle seulement |
| B — Adapter/read model non persistant | Moyenne | Non | Faible si dérivé | Fort | Fort | Recommandée |
| C — Contrat pur minimal maintenant | Moyenne | Non | Moyen | Potentiel | Potentiel | Reporter |
| D — Wrapper persistant | Forte | Oui | Forte | Incertain | Incertain | Refuser |
| E — Report complet | Faible | Non | Non | Faible | Faible | Refuser |

## 14. Décision d'implémentation P2-04

Verdict :

```text
B — Adapter/read model recommandé plus tard : aucun code maintenant.
```

Réponses au gate :

| Question | Réponse |
|---|---|
| Un Scene adapter/read model est-il nécessaire maintenant ? | Non. La décision suffit pour P2-05 ; l'implémentation peut attendre outcomes/diagnostics/pickers. |
| Quels consumers explicites le justifient ? | P2-05, P2-09, P2-10, future Phase 4 authoring. Aucun ne nécessite du code dans P2-04. |
| Peut-il être dérivé de `ScenarioAsset` sans persistence ? | Oui, c'est la trajectoire recommandée. |
| Peut-il attendre P2-05 / P2-09 / P2-10 ? | Oui, et cela réduit le risque de mauvais champs. |
| Comment éviter de dupliquer `ScenarioAsset` ? | Ne stocker aucune copie ; dériver les listes, labels et diagnostics depuis `ScenarioAsset`. |
| Quels diagnostics deviennent possibles ? | Support runtime, références manquantes, outcomes orphelins, Scene sans fin, source-only, authoring-only. |
| La persistence est-elle nécessaire ? | Non. |

Pourquoi aucun code :

- P2-05 va modifier la compréhension des outcomes nécessaires ;
- P2-09 décidera les diagnostics prioritaires ;
- P2-10 décidera les picker read models ;
- aucun runtime ou editor n'est bloqué par l'absence d'un type Dart maintenant ;
- créer le type maintenant risquerait de figer une projection prématurée.

## 15. Contrat conceptuel recommandé

Contrat conceptuel non implémenté :

```text
SceneReadModel
```

Champs conceptuels possibles :

```text
sceneId
scenarioId
humanLabel
description
scope
entryNodeId
sourceNodes
actionNodes
conditionNodes
choiceNodes
endNodes
edges
declaredOutcomes
emittedOutcomes
consumedOutcomes
activationConditionSummary
referencedDialogues
referencedScripts
referencedBattles
completedSteps
writtenFlags
metadataSources
runtimeSupportSummary
diagnostics
```

Règles :

- `SceneReadModel` ne devient pas source de vérité ;
- il ne persiste rien ;
- il ne modifie pas `ProjectManifest` ;
- il ne duplique pas les nodes / edges ;
- il expose des résumés, pas un Scene Builder ;
- il signale clairement les blocs runtime-supported vs authoring-only ;
- il garde Event comme déclencheur et Cinematic comme mise en scène.

## 16. Diagnostics possibles

Diagnostics futurs possibles, sans implémentation P2-04 :

| Diagnostic | Sévérité probable | Phase probable |
|---|---|---|
| Scene sans source runtime | Error | P2-09 |
| Scene source-only sans bloc exécutable | Warning/Error selon policy | P2-09 |
| Scene sans fin lisible | Warning | P2-09 |
| Scene contient `choice` mais runtime MVP le bloque | Warning | P2-09 |
| Scene contient reference non-source | Warning | P2-09 |
| Scene action unknown | Error | P2-09 |
| Scene outcome déclaré jamais émis | Warning | P2-05/P2-09 |
| Scene outcome émis jamais consommé | Warning | P2-05/P2-09 |
| Scene battle sans branch defeat/victory | Warning/Error selon P2-06 | P2-06/P2-09 |
| Scene complète un step inconnu | Warning/Error selon P2-02 policy | P2-09 |
| Scene écrit flag technique sans Fact label | Warning | P2-07/P2-09 |
| Scene metadata Cutscene Studio illisible | Error | P2-09 |

## 17. Impacts sur P2-05 à P2-10

P2-05 — Outcome Reference Contracts :

- utiliser `ScenarioAsset.declaredOutcomes`, `emitOutcome`, `sourceOutcome` ;
- ne pas créer d'OutcomeRegistry persistant par défaut ;
- décider les summaries nécessaires à `SceneReadModel`.

P2-06 — Battle Reference / Outcome Contract :

- lire `startTrainerBattle` comme bloc Scene ;
- garder battle outcome victory/defeat minimal ;
- ne pas coupler `map_battle` au Narrative Studio.

P2-07 — Fact Descriptor / Presentation Layer :

- distinguer flags techniques écrits par Scene et Facts lisibles ;
- éviter de présenter `setFlag` comme Fact final.

P2-08 — World Rule Predicate Adapter :

- World Rule lit l'état produit par Scene ;
- World Rule ne déclenche pas Scene.

P2-09 — Narrative Validator Diagnostic Expansion :

- ajouter diagnostics centrés Scene ;
- réutiliser `ProjectValidator` et `NarrativeValidator`, pas créer un validator concurrent.

P2-10 — Reference Picker Read Models :

- construire la source de picker "Scène" depuis `ScenarioAsset` ;
- afficher label, scope, support runtime, sources et outcomes.

## 18. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Créer un Scene model parallèle | `ScenarioAsset` reste source technique ; adapter dérivé seulement. |
| Casser `ScenarioAsset` | P2-04 ne modifie aucun code ni JSON. |
| Transformer Scene en Cinematic | Scene orchestre ; Cinematic met en scène. |
| Event récupère l'orchestration | Event reste source + condition + target. |
| Adapter devient persistant déguisé | Aucun stockage, aucune migration, aucun `ProjectManifest`. |
| `map_editor` devient source de vérité | Les authoring metadata restent observées, pas promues en domaine canonique. |
| Sur-vendre le runtime | Le read model futur devra exposer les placeholders et nodes bloqués. |
| Outcomes stabilisés trop tôt | Attendre P2-05 avant implémentation. |

## 19. Ce que P2-04 décide

P2-04 décide :

- `ScenarioAsset` reste le substrat technique existant ;
- Scene est le concept produit d'orchestration au-dessus de ce substrat ;
- pas de modèle Scene persistant maintenant ;
- pas de migration `ProjectManifest` ;
- pas de wrapper `Scene` distinct ;
- trajectoire principale : adapter/read model non persistant futur ;
- aucun code n'est nécessaire dans ce lot ;
- P2-05 peut partir de `ScenarioAsset` pour les outcomes.

## 20. Ce que P2-04 ne décide pas

P2-04 ne décide pas :

- structure Dart finale d'un `SceneReadModel` ;
- emplacement exact du futur adapter ;
- contrat Outcome final ;
- contrat Battle outcome final ;
- FactDescriptor ;
- World Rule adapter ;
- UI picker ;
- Scene Builder ;
- Cinematic Builder ;
- JSON final ;
- migration `ProjectManifest` ;
- Selbrume réel.

## 21. Implémentation éventuelle

```text
Aucune implémentation.
```

Raison :

```text
Le lot choisit B — adapter/read model futur, design-only maintenant.
Les consumers existent, mais aucun ne nécessite une API Dart immédiate avant P2-05.
```

## 22. Tests / validations éventuels

Tests Dart/Flutter non exécutés :

```text
Non exécutés — P2-04 est design-only et ne modifie aucun code.
```

Validations pertinentes :

- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- contrôles hors scope ;
- `git status --short`.

## 23. Recommandation pour P2-05

P2-05 doit traiter :

```text
P2-05 — Outcome Reference Contracts
```

Recommandation :

- partir de `ScenarioAsset.declaredOutcomes`, `emitOutcome`, `sourceOutcome` et `ScenarioRuntimeSourceEvent.outcomeReceived` ;
- distinguer outcomes déclarés, émis, consommés et persistés en flag `scenario.outcome.*` ;
- éviter un OutcomeRegistry persistant tant que les consumers ne l'exigent pas ;
- préparer la partie outcomes du futur `SceneReadModel` ;
- ne pas modifier `ProjectManifest` sans besoin prouvé.

## 24. Mise à jour de road_map_phase_2.md

Mise à jour attendue :

```text
P2-04 : ✅ terminé
P2-05 : 🔜 prochain lot exact
```

Résumé ajouté :

```text
P2-04 décide que ScenarioAsset reste le substrat technique persistant,
que Scene est une vue produit d'orchestration, et qu'un SceneReadModel
non persistant pourra être construit plus tard si P2-05/P2-09/P2-10
le justifient. Aucun code n'est créé.
```

## 25. Evidence Pack

### 25.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 25.2 Fichiers lus

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
```

### 25.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
```

### 25.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

Fichiers modifiés présents au `git status` final mais hors changements P2-04 :

```text
Aucun au dernier status final capturé.
```

Fichier non suivi présent au `git status` final mais hors changements P2-04 :

```text
Aucun au dernier status final capturé.
```

Note : aucune modification hors P2-04 n'est présente au dernier `git status`
final capturé.

### 25.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,420p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '1,260p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '1,380p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1,320p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
sed -n '1,360p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
sed -n '1,320p' reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
sed -n '1,320p' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
sed -n '1,260p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
sed -n '1,220p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,220p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,320p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,320p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,320p' packages/map_core/lib/src/validation/validators.dart
sed -n '321,760p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '321,760p' packages/map_core/lib/src/validation/validators.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,420p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '421,920p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
rg -n "_validateScenarios|declaredOutcomes|activationCondition|entryNodeId|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|openDialogue|startTrainerBattle|flowMerge|authoringPlaceholder" packages/map_core/lib/src/validation/validators.dart
sed -n '760,1180p' packages/map_core/lib/src/validation/validators.dart
sed -n '760,980p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '920,1260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,360p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
sed -n '1,420p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
sed -n '1260,1480p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '360,780p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
sed -n '1,420p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
rg -n "ScenarioAsset|ScenarioScope|globalStory|localEventFlow|ScenarioNode|ScenarioNodeType|ScenarioEdge|ScenarioNodePayload|ScenarioNodeBinding|declaredOutcomes|activationCondition|entryNodeId|ProjectValidator|NarrativeValidator|ScenarioRuntimeExecutor|ScenarioRuntimeEffect|ScenarioRuntimeEffectType|openDialogue|runScript|showMessage|startTrainerBattle|completeStep|emitOutcome|authoringPlaceholder|flowMerge" packages/map_core/lib/src packages/map_runtime/lib/src/application/scenario_runtime packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart packages/map_editor/lib/src/features/narrative/application/cutscene_studio
sed -n '420,860p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
sed -n '780,1180p' packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
sed -n '1,220p' AGENTS.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,360p' "MVP Selbrume/road_map_phase_2.md"
sed -n '360,760p' "MVP Selbrume/road_map_phase_2.md"
rg -n "À renseigner|P2-05 non démarré|Aucune implémentation|Décision d'implémentation" reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
rg -n "À renseigner" reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '1,220p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '520,760p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
sed -n '1,120p' "MVP Selbrume/road_map_phase_2.md"
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short
```

Note : la première lecture `sed -n '1,260p' reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md` a été exécutée avant création du fichier et a retourné que le fichier n'existait pas encore. Elle est conservée ici pour exactitude de trace.

Note : les commandes de validation Git ont été relancées plusieurs fois pendant
la mise à jour de l'Evidence Pack. Les sorties en 25.6 à 25.13 correspondent au
dernier passage exécuté.

### 25.6 git diff --check

```text
```

### 25.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 95 ++++++++++++++++++++++++++++++++++++----
 1 file changed, 87 insertions(+), 8 deletions(-)
```

### 25.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 25.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
```

### 25.10 Tests / analyze

```text
Non exécutés — P2-04 est design-only et ne modifie aucun code.
```

### 25.11 Contrôle no-index du rapport créé

```text
```

### 25.12 Contrôle hors scope roadmaps / map_battle / examples

```text
```

### 25.13 Contrôle hors scope packages de code

```text
```

## 26. Auto-review critique

Checklist :

- Le lot a modifié uniquement ce qui était autorisé : oui, rapport P2-04 et roadmap Phase 2.
- Le rapport P2-04 existe au bon chemin : oui.
- `road_map_phase_2.md` a été mise à jour : oui.
- `road_map_global.md` est restée intacte : oui, contrôle hors scope sans sortie.
- Aucun code n'a été modifié : oui, contrôles hors scope sans sortie.
- Aucun build_runner n'a été lancé : oui.
- P2-05 n'a pas été commencé : oui.
- Scene reste l'orchestration : oui.
- Le contrat recommandé évite de dupliquer `ScenarioAsset` : oui.
- Les consumers sont explicites : oui.
- La décision d'implémentation est claire : oui, design-only / option B.
- Le prochain lot exact est clair : oui, P2-05.

Réserve de worktree :

```text
Aucune réserve hors scope au dernier passage de validation.
```

Regard critique sur le prompt :

Le prompt autorise une implémentation conditionnelle, mais les dépendances P2-05 / P2-09 / P2-10 rendent une API Dart P2-04 prématurée. La contrainte "design-first" est donc cohérente avec la preuve observée. Le seul point délicat est terminologique : `Cutscene Studio` compile déjà des blocs de mise en scène vers `ScenarioAsset`, ce qui peut faire croire que Scene et Cinematic sont confondues. P2-04 maintient la frontière : Scene orchestre, Cinematic met en scène, `ScenarioAsset` est le substrat technique.

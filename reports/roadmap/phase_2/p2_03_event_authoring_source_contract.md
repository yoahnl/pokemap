# P2-03 — Event Authoring Source Contract

## 1. Résumé exécutif

P2-03 a audité les sources Event existantes et décide de ne produire aucun code.

Verdict :

```text
B — Adapter/read model recommandé plus tard : aucun code maintenant.
```

Raison principale : l'existant couvre déjà l'exécution runtime via `ScenarioRuntimeSourceEvent` et les nodes `source*` de `ScenarioAsset`. Créer maintenant un contrat pur `map_core` serait prématuré, car P2-04 doit encore décider la relation Scene / `ScenarioAsset`, et P2-10 devra définir les read models de pickers. En revanche, le besoin produit est clair : il faut une vue auteur dérivée qui transforme les nodes techniques en choix no-code lisibles.

Décision P2-03 :

- ne pas créer de modèle persistant ;
- ne pas modifier `ProjectManifest` ;
- ne pas modifier `ScenarioRuntimeSourceEvent` ;
- ne pas modifier `map_runtime` ;
- ne pas créer de contrat Dart maintenant ;
- recommander un `EventAuthoringSourceReadModel` non persistant futur, dérivé de `ScenarioAsset` et des source nodes existants ;
- garder `ScenarioRuntimeSourceEvent` comme source d'exécution runtime ;
- préparer des diagnostics Validator futurs.

Le prochain lot exact est :

```text
P2-04 — Scene / ScenarioAsset Adapter Contract
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports demandés ;
- audit des sources runtime Event existantes ;
- audit des source nodes dans `ScenarioAsset` ;
- analyse de `ScenarioNodeBinding` pour les données de source ;
- analyse des conditions d'entrée via `activationCondition` et `ScriptCondition` ;
- analyse des diagnostics existants liés aux sources Event ;
- comparaison des options de contrat ;
- décision d'implémentation P2-03 ;
- définition d'un contrat conceptuel non implémenté ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- contrat Dart implémenté ;
- modèle `map_core` ;
- JSON ;
- migration ;
- modification `ProjectManifest` ;
- modification `ScenarioRuntimeSourceEvent` ;
- modification `map_runtime` ;
- modification `map_battle` ;
- UI ;
- Scene Builder ;
- P2-04 ;
- Selbrume final.

Fichiers créés :

```text
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
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

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` — contexte global Phase 2, lu sans modification.
- `MVP Selbrume/road_map_phase_2.md` — roadmap active Phase 2, mise à jour.
- `MVP Selbrume/road_map_phase_1.md` — statut Phase 1 clôturée.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md` — cadrage Phase 2 et risques de sur-modélisation.
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` — inventaire technique de l'existant narratif.
- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md` — décision adapter/read model non persistant pour Step / Storyline.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md` — passage Phase 2 et lots recommandés.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` — proposition Phase 2, dont Event Authoring Source.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` — workflow Event d'interaction, pickers et diagnostics attendus.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` — frontière Event déclenche / Scene orchestre.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` — grammaire produit canonique.

Fichiers techniques lus en lecture seule :

- `packages/map_core/lib/src/models/scenario_asset.dart` — `ScenarioAsset`, `ScenarioNode`, `ScenarioNodeBinding`, source nodes.
- `packages/map_core/lib/src/models/script_conditions.dart` — `ScriptCondition`, types et paramètres.
- `packages/map_core/lib/src/models/project_manifest.dart` — agrégation `scenarios` et risque migration.
- `packages/map_core/lib/src/operations/narrative_validator.dart` — diagnostics narratifs V0 liés aux sources.
- `packages/map_core/lib/src/validation/validators.dart` — validation structurelle des scenarios et source/action kinds.
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` — `ScenarioRuntimeSourceType` et `ScenarioRuntimeSourceEvent`.
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` — matching runtime des sources, activation, execution.
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` — CRUD `ScenarioAsset` côté editor.
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` — projection read-only existante.

## 4. Rappel Phase 1 / P2-01 / P2-02

Phase 1 a figé :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Validator diagnostique.
```

P1-02 a ajouté :

- Event observe une source : map enter, zone/trigger, interaction, outcome ;
- Event peut filtrer via conditions d'entrée simples ;
- Event choisit une Scene ou une action bornée ;
- Event ne doit pas contenir dialogue, battle, rewards, branching narratif ou écritures durables complexes.

P2-01 a observé :

- `ScenarioRuntimeSourceEvent` existe déjà côté runtime ;
- `ScenarioRuntimeExecutor` matche des nodes `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract`, `sourceOutcome` ;
- `ScenarioAsset.activationCondition` existe comme gating scénario ;
- `NarrativeValidator` contient déjà des diagnostics sur source entity interact et outcome mismatch ;
- `ProjectValidator` valide déjà quelques invariants de source/action kind.

P2-02 a décidé :

- pas de descriptor persistant Storyline / Chapter / Story Step maintenant ;
- pas de migration `ProjectManifest` ;
- adapter/read model non persistant d'abord ;
- `completedStepIds` reste source de completion ;
- P2-03 peut référencer Story Step via metadata/read model futur sans créer de modèle persistant.

## 5. Problème à résoudre

Le runtime sait déjà recevoir et matcher des events. L'authoring no-code, lui, doit pouvoir présenter ces events comme des déclencheurs compréhensibles :

```text
Quand le joueur entre sur une map
Quand le joueur entre dans une zone
Quand le joueur parle à une entité
Quand un outcome est reçu
```

Le problème P2-03 est donc de choisir entre :

- réutiliser directement les structures runtime ;
- dériver une vue auteur non persistante ;
- créer un contrat pur ;
- enrichir les runtime events ;
- créer un modèle persistant.

Le risque majeur est de dupliquer `ScenarioRuntimeSourceEvent` ou de créer un Event qui devient une mini-Scene. Un Event Authoring Source doit décrire la source, ses identifiants et son target scénario, pas orchestrer le contenu narratif.

## 6. Inventaire des sources runtime existantes

Fichier :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
```

Sources runtime observées :

| Source runtime | Factory | Données | Rôle |
|---|---|---|---|
| `mapEnter` | `ScenarioRuntimeSourceEvent.mapEnter` | `mapId` | Déclenchement à l'entrée d'une map |
| `triggerEnter` | `ScenarioRuntimeSourceEvent.triggerEnter` | `mapId`, `triggerId` | Déclenchement à l'entrée dans un trigger |
| `entityInteract` | `ScenarioRuntimeSourceEvent.entityInteract` | `mapId`, `entityId` | Interaction avec entité / PNJ |
| `outcomeReceived` | `ScenarioRuntimeSourceEvent.outcomeReceived` | `outcomeId`, `mapId` vide | Pont local vers global via outcome |

Observations :

- `ScenarioRuntimeSourceEvent` vit dans `map_runtime`, pas dans `map_core`.
- Il est orienté exécution : c'est l'événement concret reçu par le runtime.
- Il encode `mapId` et les identifiants contextuels nécessaires.
- `outcomeReceived` n'utilise pas de map et porte seulement `outcomeId`.

Ce qui peut être réutilisé conceptuellement :

- les quatre types de source ;
- la sémantique des champs `mapId`, `triggerId`, `entityId`, `outcomeId` ;
- la distinction world hooks (`mapEnter`, `triggerEnter`, `entityInteract`) / outcome bridge.

Ce qui ne doit pas être dupliqué :

- les factories runtime ;
- le matching runtime ;
- la logique d'exécution ;
- le statut runtime `noMatchingSource`, `executedEffect`, `reachedEnd`, `blocked`.

Conclusion :

`ScenarioRuntimeSourceEvent` est une bonne source d'inspiration et d'exécution, mais ce n'est pas un modèle authoring. L'authoring doit adapter le graphe existant, pas modifier l'event runtime.

## 7. Inventaire des source nodes dans ScenarioAsset

Fichiers :

```text
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

Source nodes observés :

| Source node | `payload.actionKind` | Scope attendu | Données principales | Matching runtime |
|---|---|---|---|---|
| Map enter | `sourceMapEnter` | `localEventFlow` | `binding.mapId` optionnel | Match si action kind correspond et map compatible |
| Trigger enter | `sourceTriggerEnter` | `localEventFlow` | `binding.mapId`, `binding.triggerId` | Match si trigger non vide et égal |
| Entity interact | `sourceEntityInteract` | `localEventFlow` | `binding.mapId`, `binding.entityId` | Match si entity non vide et égale |
| Outcome | `sourceOutcome` | `globalStory` | `binding.outcomeId` | Match si outcome non vide et égal |

Le runtime ne lit que des nodes :

```text
ScenarioNodeType.reference
```

avec un `payload.actionKind` source.

Le matching est contenu dans `_findMatchingSourceNode` :

- pour `mapEnter`, `mapId` vide dans le binding est toléré comme wildcard ;
- pour `triggerEnter`, `triggerId` doit être non vide et égal ;
- pour `entityInteract`, `entityId` doit être non vide et égal ;
- pour `outcomeReceived`, `outcomeId` doit être non vide et égal.

`ScenarioRuntimeExecutor._candidateScenarios` filtre aussi les candidats :

- world hooks privilégient les scenarios `localEventFlow` ;
- outcome reçu privilégie les scenarios `globalStory`.

Risques si un contrat auteur séparé est créé trop tôt :

- recréer une deuxième enum de source sans lien clair ;
- dupliquer les chaînes `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract`, `sourceOutcome` ;
- créer un mapper fragile entre authoring et runtime avant P2-04 ;
- fixer un modèle source avant d'avoir décidé Scene / `ScenarioAsset`.

Conclusion :

Le contrat auteur doit être dérivé de ces source nodes existants. Il ne doit pas inventer un nouveau graphe Event.

## 8. ScenarioNodeBinding et données de source

`ScenarioNodeBinding` expose :

```text
mapId
eventId
entityId
warpId
triggerId
trainerId
dialogueId
scriptId
outcomeId
flagName
variableName
```

Champs qui concernent directement Event Authoring Source :

| Champ | Source concernée | Rôle |
|---|---|---|
| `mapId` | `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract` | Map de contexte ou wildcard si vide selon runtime |
| `triggerId` | `sourceTriggerEnter` | Trigger / zone qui déclenche |
| `entityId` | `sourceEntityInteract` | Entité / PNJ qui déclenche |
| `outcomeId` | `sourceOutcome` | Outcome consommé par un graphe global |

Champs connexes mais non source Event P2-03 :

| Champ | Pourquoi hors Event Source |
|---|---|
| `eventId` | Utilisé comme identifiant d'event consommé dans conditions / legacy ; pas source runtime actuelle P2-03 |
| `warpId` | Cible d'action `transitionMap`, pas source Event actuelle |
| `trainerId` | Référence battle, P2-06 |
| `dialogueId` | Effet Scene / dialogue, P2-04/P2-05 |
| `scriptId` | Effet runtime, pas source Event |
| `flagName` | Fact / condition / action, P2-07 |
| `variableName` | Condition / state technique, pas source Event |

Point important :

`ScenarioNodeBinding` est déjà un conteneur général. Le read model Event Source futur doit sélectionner les champs pertinents selon `sourceType`, pas exposer tout le binding brut à l'auteur.

## 9. Conditions d’entrée et ScriptCondition

Conditions observées :

- `ScenarioAsset.activationCondition` : gating optionnel du scénario.
- `ScenarioNodePayload.condition` : condition possible au niveau node.
- `ScriptCondition` : DSL existant pure Dart.

Types de conditions disponibles :

- `allOf`
- `anyOf`
- `not`
- `flagIsSet`
- `flagIsUnset`
- `variableEquals`
- `variableGreaterThan`
- `variableLessThan`
- `fieldAbilityUnlocked`
- `partyHasMove`
- `partyHasUsableMove`
- `eventIsConsumed`
- `playerOnMap`

Paramètres utiles :

- `flagName`
- `variableName`
- `value`
- `ability`
- `moveId`
- `eventId`
- `mapId`

P2-03 ne doit pas refaire un DSL conditionnel.

Décision :

- l'Event Authoring Source peut exposer un résumé lisible de condition ;
- la source de vérité conditionnelle reste `ScriptCondition` ;
- la présentation no-code future doit traduire `ScriptCondition` en phrases humaines ;
- les diagnostics doivent vérifier les références et paramètres ;
- aucun nouveau format conditionnel n'est créé par P2-03.

## 10. Validator existant lié aux sources Event

Fichiers :

```text
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
```

Diagnostics narratifs existants liés aux sources :

| Diagnostic | Type | Observé dans | Rôle |
|---|---|---|---|
| `scenarioGraphHasNoSource` | error | `NarrativeValidator` | Scenario sans source runtime |
| `sourceEntityInteractReferencesUnknownMap` | error | `NarrativeValidator` | Source entityInteract map inconnue |
| `sourceEntityInteractReferencesUnknownEntity` | error | `NarrativeValidator` | Source entityInteract entité inconnue |
| `sourceOutcomeWithoutMatchingEmitOutcome` | warning | `NarrativeValidator` | Outcome consommé mais jamais émis |
| `emitOutcomeWithoutMatchingSourceOutcome` | warning | `NarrativeValidator` | Outcome émis mais jamais consommé |

Validation structurelle existante :

- `ProjectValidator` exige un `outcomeId` non vide pour `sourceOutcome` et `emitOutcome`.
- `ProjectValidator` interdit `sourceMapEnter`, `sourceTriggerEnter`, `sourceEntityInteract` dans un scenario `globalStory`.
- `ProjectValidator` interdit `sourceOutcome` dans un scenario `localEventFlow`.
- `ProjectValidator` vérifie `mapId` inconnu si `binding.mapId` est présent.
- `ProjectValidator` valide `activationCondition` et `node.payload.condition`.

Limites observées :

- `NarrativeValidator` diagnostique précisément `sourceEntityInteract`, mais pas encore `sourceTriggerEnter` map/trigger inconnu.
- `NarrativeValidator` ne semble pas encore diagnostiquer `sourceMapEnter` map inconnue comme diagnostic narratif spécifique.
- `triggerId` n'est pas validé comme référence précise à un trigger de map dans le diagnostic narratif.
- la logique de sources est dupliquée sous forme de chaînes dans `map_core` validators et `map_runtime` executor.

Conclusion :

P2-03 ne doit pas créer un nouveau validator concurrent. Les diagnostics futurs doivent enrichir `NarrativeValidator` / `ProjectValidator` de manière cohérente.

## 11. Consumers explicites

| Consumer | Besoin | Maintenant ? | Persistence nécessaire ? |
|---|---|---:|---:|
| `NarrativeValidator` | Diagnostiquer sources manquantes, invalides, conflictuelles | Oui, futur P2-09 | Non |
| `ProjectValidator` | Maintenir invariants structurels source/action kind | Déjà partiel | Non |
| Future Event picker | Présenter "map enter / trigger / entity / outcome" sans IDs bruts | Phase 4/P2-10 | Non |
| P2-04 Scene / `ScenarioAsset` adapter | Relier déclencheur auteur à la Scene/scenario cible | Oui, prochain lot | Non |
| P2-10 Reference Picker Read Models | Produire listes source/target lisibles | Futur | Non |
| `map_editor` authoring minimal | Créer source node + target sans manipuler le graphe brut | Phase 4 | Non au départ |
| `map_runtime` source matching | Exécuter les triggers concrets | Déjà existant | Non |

Consumer immédiat le plus clair :

```text
P2-04 doit savoir que les Event Authoring Sources seront des vues dérivées de ScenarioAsset/source nodes.
```

Le consumer ne justifie pas encore un contrat Dart dans ce lot.

## 12. Options de contrat

### Option A — Ne rien créer maintenant

Description :

Utiliser uniquement `ScenarioAsset`, source nodes et runtime source events existants.

Avantages :

- zéro code ;
- zéro migration ;
- aucun risque de duplication immédiate ;
- respecte l'existant ;
- laisse P2-04 décider Scene / `ScenarioAsset`.

Risques :

- pas de langage authoring stable ;
- pickers futurs risquent de lire directement le graphe ;
- diagnostics restent dispersés ;
- le vocabulaire no-code "Quand le joueur..." n'a pas encore de forme.

Consumers servis :

- runtime existant ;
- validators partiels existants.

Limites :

- insuffisant pour Phase 4 authoring ;
- insuffisant pour P2-10 pickers.

Verdict :

Acceptable comme état actuel, mais insuffisant comme trajectoire.

### Option B — Adapter/read model non persistant

Description :

Créer plus tard une vue auteur dérivée de `ScenarioAsset` et des source nodes, sans nouveau stockage.

Avantages :

- évite la duplication de `ScenarioRuntimeSourceEvent` ;
- expose des labels humains ;
- centralise le mapping source node -> source auteur ;
- alimente Validator et pickers ;
- ne modifie pas `ProjectManifest` ;
- reste compatible avec P2-04 et P2-10.

Risques :

- peut devenir un modèle persistant déguisé ;
- nécessite une discipline stricte sur la source de vérité ;
- doit attendre la décision P2-04 pour éviter de figer la relation Event -> Scene trop tôt.

Diagnostics possibles :

- source sans target ;
- target scenario absent ;
- source trigger sans triggerId ;
- source trigger référence trigger inconnu ;
- source mapEnter map inconnue ;
- source entityInteract entité inconnue ;
- source outcome sans emitOutcome ;
- conflit entre sources identiques.

Verdict :

Option recommandée.

### Option C — Contrat pur minimal dans map_core

Description :

Créer maintenant ou plus tard un type pur pour décrire une source auteur.

Champs minimaux possibles :

- `sourceId`
- `sourceType`
- `humanLabel`
- `mapId`
- `entityId`
- `triggerId`
- `outcomeId`
- `targetScenarioId`
- `activationConditionSummary`
- `repeatPolicySummary`
- `sourceNodeId`
- `sourceScenarioId`
- `diagnostics`

Consumer exact nécessaire :

- Validator enrichi ;
- picker read model ;
- Scene adapter ;
- authoring Phase 4.

Pourquoi pas maintenant :

- P2-04 n'a pas encore décidé Scene / `ScenarioAsset` ;
- P2-10 n'a pas encore défini les read models de pickers ;
- aucun test ciblé de contrat n'est utile sans comportement ;
- le risque de dupliquer les source nodes est encore supérieur au bénéfice.

Pourquoi plus tard :

- après P2-04, un adapter pure Dart peut être stabilisé ;
- après P2-09, diagnostics concrets justifieront une forme stable ;
- après P2-10, les pickers pourront consommer la vue.

Verdict :

Reporter l'implémentation. Décrire seulement le contrat conceptuel.

### Option D — Étendre les runtime source events

Description :

Modifier ou enrichir `ScenarioRuntimeSourceEvent` pour porter les besoins authoring.

Pourquoi c'est risqué :

- le runtime deviendrait un modèle authoring ;
- `map_runtime` influencerait la vérité domaine ;
- les labels humains et diagnostics n'ont pas leur place dans l'event runtime ;
- cela ferait glisser Phase 2 vers Phase 3.

Pourquoi reporter :

- l'event runtime actuel est assez clair ;
- ses factories représentent les événements concrets ;
- les besoins authoring peuvent être satisfaits par un adapter dérivé.

Verdict :

Refuser pour P2-03.

### Option E — Modèle persistant / ProjectManifest

Description :

Créer un modèle persistant Event Source dans `ProjectManifest`.

Risques :

- migration JSON ;
- deuxième source de vérité parallèle aux source nodes ;
- duplication `ScenarioAsset.nodes` ;
- conflit avec P2-04 ;
- authoring prématuré ;
- complexité de compatibilité projet.

Pourquoi refuser maintenant :

- les source nodes sont déjà persistés dans `ScenarioAsset` ;
- aucun consumer ne demande un stockage indépendant ;
- la phase demande adapter avant persistance.

Verdict :

Refuser.

## 13. Matrice comparative

| Option | Complexité | Migration | Duplication runtime | Support Validator | Support pickers | Timing |
|---|---:|---:|---:|---:|---:|---|
| A — Ne rien créer | Faible | Aucune | Aucune | Moyen | Faible | État actuel |
| B — Adapter/read model non persistant | Moyenne | Aucune | Faible | Fort | Fort | Recommandé plus tard |
| C — Contrat pur minimal | Moyenne | Aucune | Moyen si trop tôt | Fort | Fort | À reporter après P2-04/P2-09 |
| D — Étendre runtime events | Moyenne | Aucune | Forte côté responsabilité | Faible | Faible | Refusé |
| E — Modèle persistant | Élevée | Forte | Forte | Fort | Fort | Refusé |

## 14. Décision d’implémentation P2-03

Verdict :

```text
B — Adapter/read model recommandé plus tard : aucun code maintenant.
```

Le contrat est-il nécessaire maintenant ?

- Non. Le besoin est clair, mais l'implémentation doit attendre au minimum P2-04 pour stabiliser la relation Event source -> Scene / `ScenarioAsset`.

Quels consumers explicites le justifient ?

- Validator futur ;
- P2-04 Scene / `ScenarioAsset` adapter ;
- P2-10 Reference Picker Read Models ;
- authoring minimal Phase 4.

Peut-il être un adapter/read model au lieu d'un modèle persistant ?

- Oui. C'est la trajectoire recommandée.

Peut-il vivre dans `map_core` sans dépendre du runtime ?

- Plus tard, oui, s'il dérive uniquement de `ScenarioAsset` et des chaînes source nodes déjà présentes côté `map_core` validation. Mais P2-03 ne l'implémente pas.

Comment éviter de dupliquer `ScenarioRuntimeSourceEvent` ?

- Ne pas copier l'event runtime.
- Dériver la vue auteur depuis `ScenarioAsset.nodes`.
- Conserver `ScenarioRuntimeSourceEvent` comme modèle d'événement concret reçu par le runtime.
- Ne pas ajouter de labels humains ou diagnostics dans `map_runtime`.

Quels diagnostics deviennent possibles ?

- Sources manquantes ou invalides ;
- source target scenario absent ;
- map / trigger / entity / outcome inconnus ;
- source `sourceOutcome` sans `emitOutcome` ;
- sources identiques conflictuelles ;
- source node sans edge vers une Scene/flow ;
- Event qui contient trop d'orchestration.

La persistence est-elle nécessaire ?

- Non.

## 15. Contrat conceptuel recommandé

Contrat conceptuel non implémenté :

```text
EventAuthoringSourceReadModel
```

Forme conceptuelle :

| Champ conceptuel | Rôle | Source dérivée |
|---|---|---|
| `sourceId` | Identité de la source auteur | `scenarioId + sourceNodeId` |
| `sourceType` | Type no-code : map enter, trigger enter, entity interact, outcome | `payload.actionKind` |
| `humanLabel` | Label auteur | Source type + noms map/entity/trigger/outcome si disponibles |
| `mapId` | Map de contexte | `node.binding.mapId` |
| `entityId` | Entité déclencheuse | `node.binding.entityId` |
| `triggerId` | Trigger/zone déclencheuse | `node.binding.triggerId` |
| `outcomeId` | Outcome consommé | `node.binding.outcomeId` |
| `targetScenarioId` | Scenario/Scene contenant la source | `ScenarioAsset.id` |
| `activationConditionSummary` | Résumé lisible du gating | `ScenarioAsset.activationCondition` ou future presentation de `ScriptCondition` |
| `repeatPolicySummary` | Résumé one-shot/repeat | dérivé de conditions / flags / event consumed, non tranché |
| `sourceNodeId` | Node source technique | `ScenarioNode.id` |
| `sourceScenarioId` | Scenario porteur | `ScenarioAsset.id` |
| `diagnostics` | Problèmes authoring | Validator futur |

Contraintes :

- ce contrat n'est pas créé par P2-03 ;
- il ne duplique pas `ScenarioRuntimeSourceEvent` ;
- il ne devient pas un modèle persistant ;
- il est dérivé de `ScenarioAsset` et de ses source nodes ;
- il ne contient pas d'actions Scene ;
- il ne contient pas de battle, dialogue ou rewards.

## 16. Diagnostics possibles

Diagnostics futurs possibles sans persistence :

- scenario sans source runtime ;
- source node sans sortie ;
- source node avec target flow absent ;
- source type inconnu ;
- source mapEnter référence map inconnue ;
- source triggerEnter sans `triggerId` ;
- source triggerEnter référence trigger inconnu ;
- source triggerEnter map inconnue ;
- source entityInteract sans `entityId` ;
- source entityInteract map inconnue ;
- source entityInteract entity inconnue ;
- source outcome sans `outcomeId` ;
- source outcome sans emitOutcome correspondant ;
- emitOutcome sans sourceOutcome correspondant ;
- source world hook dans `globalStory` ;
- sourceOutcome dans `localEventFlow` ;
- plusieurs sources identiques sans priorité explicite ;
- source wildcard map trop large ;
- source avec condition impossible ;
- Event qui tente d'orchestrer dialogue/battle/reward directement.

Diagnostics à ne pas faire en P2-03 :

- pas d'auto-correction ;
- pas de migration ;
- pas de création de read model codé ;
- pas de modification du runtime.

## 17. Impacts sur P2-04 à P2-10

P2-04 — Scene / `ScenarioAsset` Adapter Contract :

- doit décider si le target d'un Event Authoring Source est une Scene, un `ScenarioAsset`, ou une projection ;
- peut s'appuyer sur la décision P2-03 : les sources viennent de source nodes existants.

P2-05 — Outcome Reference Contracts :

- devra consolider `emitOutcome` / `sourceOutcome` et outcomes déclarés ;
- pourra utiliser la distinction sourceOutcome comme Event source globale.

P2-06 — Battle Reference / Outcome Contract :

- doit garder battle comme effet Scene, pas Event source.

P2-07 — Fact Descriptor / Presentation Layer :

- devra aider à afficher les conditions Event en langage humain.

P2-08 — World Rule Predicate Adapter :

- devra maintenir World Rule passive et séparée d'Event.

P2-09 — Narrative Validator Diagnostic Expansion :

- pourra ajouter diagnostics Event source sans nouveau modèle persistant.

P2-10 — Reference Picker Read Models :

- pourra créer les pickers map/entity/trigger/outcome/scene depuis les sources dérivées.

## 18. Risques et garde-fous

| Risque | Effet | Garde-fou |
|---|---|---|
| Event devient mini-Scene | Dialogue, battle et rewards se dispersent hors Scene | Event source ne décrit que trigger + condition + target |
| Duplication de `ScenarioRuntimeSourceEvent` | Deux modèles source concurrents | Lire `ScenarioAsset.nodes`, garder runtime event runtime-only |
| Runtime devient authoring model | `map_runtime` porte labels et diagnostics | Placer les futures vues dans domaine/adapters, pas runtime |
| `ProjectManifest` migré trop tôt | Churn JSON et compatibilité cassée | Refuser toute persistence P2-03 |
| Source nodes exposés bruts en UI | UX IDs techniques | Read model futur avec labels humains |
| Conditions Event refaites | DSL concurrent | Réutiliser `ScriptCondition` et traduire en résumé |
| Source wildcard map trop large | Events inattendus | Diagnostic futur si mapId vide sur source world hook |
| Plusieurs sources identiques | Déclenchement ambigu | Diagnostic futur conflit / priorité |

## 19. Ce que P2-03 décide

P2-03 décide :

- aucun code maintenant ;
- aucun contrat Dart maintenant ;
- aucun modèle persistant ;
- aucun changement `ProjectManifest` ;
- aucun changement `ScenarioRuntimeSourceEvent` ;
- Event Authoring Source doit être un adapter/read model non persistant futur ;
- la source d'exécution reste `ScenarioRuntimeSourceEvent` ;
- la source authoring actuelle reste `ScenarioAsset` + source nodes ;
- P2-04 peut traiter Scene / `ScenarioAsset` en considérant l'Event source comme un point d'entrée dérivé.

## 20. Ce que P2-03 ne décide pas

P2-03 ne décide pas :

- la structure finale codée d'un `EventAuthoringSourceReadModel` ;
- la relation définitive Scene = `ScenarioAsset` ou adapter ;
- l'UI picker ;
- la persistence ;
- une migration `ProjectManifest` ;
- un nouveau DSL conditionnel ;
- les diagnostics implémentés ;
- le runtime Flame ;
- Selbrume réel.

## 21. Implémentation éventuelle

Aucune implémentation n'est produite par P2-03.

Justification :

- le besoin est mieux servi par un adapter/read model futur ;
- P2-04 doit d'abord décider la relation Scene / `ScenarioAsset` ;
- P2-09 devra décider les diagnostics exacts ;
- P2-10 devra décider les read models de pickers ;
- créer un type maintenant risquerait de figer prématurément le mauvais niveau d'abstraction.

## 22. Tests / validations éventuels

Aucun test Dart / Flutter n'est lancé.

Raison :

```text
P2-03 est design-only et ne modifie aucun code.
```

Validations exécutées :

- `git diff --check`
- `git diff --stat`
- `git diff --name-only`
- contrôles hors scope par `git diff --name-only`.

Tests à prévoir si un adapter/read model est créé plus tard :

- extraction des source nodes par type ;
- labels humains stables ;
- source map/entity/trigger/outcome inconnue ;
- conflit de sources identiques ;
- respect scopes `globalStory` / `localEventFlow` ;
- absence de dépendance Flutter / Flame.

## 23. Recommandation pour P2-04

P2-04 devra traiter :

```text
P2-04 — Scene / ScenarioAsset Adapter Contract
```

Recommandation :

- décider si Scene est le nom produit de `ScenarioAsset`, un wrapper ou un adapter ;
- considérer les source nodes comme points d'entrée Event vers une Scene/scenario ;
- ne pas ajouter de modèle Event persistant avant cette décision ;
- garder le branching et l'orchestration dans Scene ;
- préparer les outcomes pour P2-05.

## 24. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` est mise à jour pour indiquer :

```text
P2-03 : ✅ terminé
P2-04 : 🔜 prochain lot exact
```

Résumé ajouté :

```text
P2-03 reste design-only, refuse tout modèle persistant ou modification runtime, recommande un EventAuthoringSourceReadModel non persistant futur dérivé de ScenarioAsset/source nodes, et prépare P2-04.
```

## 25. Evidence Pack

### 25.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 25.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
```

### 25.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
```

### 25.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 25.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,360p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,180p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,260p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
sed -n '1,260p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
sed -n '1,320p' reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
sed -n '1,260p' reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
rg -n "Event|ScenarioRuntimeSourceEvent|ScenarioRuntimeSourceType|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|ScenarioNodeBinding|activationCondition|Validator|authoring source|P2-03" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/script_conditions.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,320p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,260p' packages/map_core/lib/src/validation/validators.dart
sed -n '320,760p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '260,560p' packages/map_core/lib/src/validation/validators.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,320p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
sed -n '360,760p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '760,1160p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
rg -n "ScenarioRuntimeSourceEvent|ScenarioRuntimeSourceType|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|mapEnter|triggerEnter|entityInteract|outcomeReceived|ScenarioNodeBinding|mapId|triggerId|entityId|outcomeId|activationCondition|sourceEntityInteractReferencesUnknownMap|sourceEntityInteractReferencesUnknownEntity|sourceOutcomeWithoutMatchingEmitOutcome|emitOutcomeWithoutMatchingSourceOutcome" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1260,1365p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '760,900p' packages/map_core/lib/src/validation/validators.dart
sed -n '900,1045p' packages/map_core/lib/src/validation/validators.dart
sed -n '760,920p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '600,720p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '1,520p' "MVP Selbrume/road_map_phase_2.md"
sed -n '520,680p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short
```

Note :

La commande `sed -n '1,260p' reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` a été exécutée avant création du rapport et a confirmé que le fichier n'existait pas encore. Cette commande est listée pour transparence.

### 25.6 git diff --check

```text
```

### 25.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 68 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 61 insertions(+), 7 deletions(-)
```

### 25.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 25.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
```

### 25.10 Tests / analyze

```text
Non exécutés — P2-03 est design-only et ne modifie aucun code.
```

### 25.11 git diff --no-index --check du rapport créé

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md || true
```

Sortie :

```text
```

### 25.12 Contrôle hors scope global / Phase 1 / battle / host

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
```

Sortie :

```text
```

### 25.13 Contrôle hors scope code packages

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
```

Sortie :

```text
```

## 26. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui. Les modifications prévues concernent seulement le rapport P2-03 et `MVP Selbrume/road_map_phase_2.md`.

Le rapport P2-03 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?

- Oui, avec P2-03 terminé et P2-04 comme prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui, elle a été lue mais non modifiée.

Aucun code n'a-t-il été modifié, ou le code modifié est-il justifié ?

- Aucun code n'a été modifié.

Aucun `build_runner` n'a-t-il été lancé ?

- Oui. Aucun `build_runner` n'a été lancé.

P2-04 n'a-t-il pas été commencé ?

- Oui. P2-04 est seulement recommandé comme prochain lot exact.

Event reste-t-il un déclencheur ?

- Oui. Le rapport maintient Event comme source + condition + target, sans orchestration.

Le contrat recommandé évite-t-il de dupliquer `ScenarioRuntimeSourceEvent` ?

- Oui. La recommandation est de dériver une vue auteur depuis `ScenarioAsset` et ses source nodes, pas de copier l'event runtime.

Les consumers sont-ils explicites ?

- Oui : Validator, P2-04, P2-10, authoring Phase 4 et runtime source matching existant.

La décision d'implémentation est-elle claire ?

- Oui : verdict B, aucun code maintenant.

Le prochain lot exact est-il clair ?

- Oui : `P2-04 — Scene / ScenarioAsset Adapter Contract`.

### Regard critique sur le prompt

Le prompt ouvre prudemment la porte à un petit contrat pur Dart, mais les conditions imposées sont volontairement strictes. Après audit, la prudence est justifiée : P2-03 a des consumers, mais pas encore assez de stabilité autour de Scene / `ScenarioAsset` pour créer un type maintenant. La meilleure suite est donc P2-04, pas une implémentation anticipée.

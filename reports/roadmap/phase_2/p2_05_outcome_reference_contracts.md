# P2-05 — Outcome Reference Contracts

## 1. Résumé exécutif

P2-05 décide comment rendre les outcomes narratifs sélectionnables, diagnosticables et compréhensibles côté auteur sans créer un `OutcomeRegistry` persistant.

Décision recommandée :

```text
Ne pas créer de modèle persistant.
Ne pas modifier ProjectManifest.
Ne pas créer d'OutcomeRegistry.
Garder declaredOutcomes / emitOutcome / sourceOutcome comme sources techniques.
Recommander un OutcomeReferenceReadModel non persistant futur, dérivé de ScenarioAsset.
```

Le lot reste **design-only** :

- aucun code créé ;
- aucun package modifié ;
- aucun JSON / migration ;
- aucun build_runner ;
- aucun test Dart/Flutter ;
- aucun contenu Selbrume ;
- P2-06 non démarré.

Prochain lot exact :

```text
P2-06 — Battle Reference / Outcome Contract
```

## 2. Scope du lot

Inclus :

- audit ciblé des outcomes narratifs existants ;
- distinction declared / emitted / consumed / persisted ;
- comparaison des options de contrat ;
- décision d'implémentation P2-05 ;
- contrat conceptuel `OutcomeReferenceReadModel` non implémenté ;
- diagnostics possibles à reporter ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- modèle `map_core` ;
- `OutcomeRegistry` persistant ;
- JSON / migration ;
- Freezed / JsonSerializable ;
- `ProjectManifest` ;
- tests ;
- UI ;
- Selbrume final ;
- P2-06.

Fichiers créés :

```text
reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
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

| Source | Rôle |
|---|---|
| `MVP Selbrume/road_map_global.md` | Contexte global lu, non modifié. |
| `MVP Selbrume/road_map_phase_2.md` | Roadmap vivante Phase 2 à mettre à jour. |
| `MVP Selbrume/road_map_phase_1.md` | Phase 1 clôturée, contexte. |
| `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md` | Cadre audit-first. |
| `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` | Inventaire technique. |
| `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md` | Décision adapter/read model pour steps. |
| `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` | `sourceOutcome` comme source Event globale. |
| `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md` | `SceneReadModel` futur expose outcomes. |
| `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md` | Frontières Phase 1 figées. |
| `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` | Proposition de contrats Phase 2. |
| `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` | Workflows no-code et outcomes gérés. |
| `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` | Mapping Selbrume conceptuel. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Yarn produit outcomes, Scene interprète. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Glossaire canonique. |

Fichiers techniques lus en lecture seule :

| Source | Rôle |
|---|---|
| `packages/map_core/lib/src/models/scenario_asset.dart` | `declaredOutcomes`, `ScenarioNodeBinding.outcomeId`, payloads. |
| `packages/map_core/lib/src/operations/narrative_validator.dart` | Diagnostics outcome emitted/consumed existants. |
| `packages/map_core/lib/src/validation/validators.dart` | Validation `declaredOutcomes`, `emitOutcome`, `sourceOutcome`. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | `ScenarioRuntimeSourceEvent.outcomeReceived`. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | `emitOutcome`, flag `scenario.outcome.*`, dispatch global. |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | `NarrativeOutcomeSummary`, declared/emitted/consumed. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart` | Collecte outcomes déclarés depuis flow authoring. |
| `packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart` | Résultat de scène, label humain vers outcomeId. |

## 4. Rappel Phase 1 / P2-01 à P2-04

Phase 1 :

```text
Yarn produit des outcomes.
Scene interprète les outcomes.
Battle résout.
Fact nomme ce qui est vrai.
```

P2-01 :

- `ScenarioAsset.declaredOutcomes` existe ;
- `emitOutcome` et `sourceOutcome` existent dans le graphe ;
- `NarrativeValidator` diagnostique certains mismatches.

P2-03 :

- `sourceOutcome` est une source Event globale ;
- Event reste déclencheur, pas orchestration.

P2-04 :

- `ScenarioAsset` reste le substrat technique ;
- Scene est une vue produit d'orchestration ;
- un futur `SceneReadModel` pourra exposer outcomes déclarés, émis, consommés.

## 5. Problème à résoudre

Le produit doit permettre à un auteur de choisir et comprendre des outcomes sans parler en IDs bruts.

Aujourd'hui, l'existant porte plusieurs dimensions :

```text
declaredOutcomes = outcomes annoncés par un ScenarioAsset.
emitOutcome = node qui produit un outcome.
sourceOutcome = node source qui consomme un outcome.
scenario.outcome.<id> = flag technique persistant posé par le runtime.
```

Le problème P2-05 :

- donner un vocabulaire auteur ;
- rendre les outcomes visibles dans les pickers ;
- diagnostiquer déclarés / émis / consommés / orphelins ;
- éviter un registry persistant inutile ;
- ne pas convertir automatiquement un outcome en Fact ;
- laisser les battle outcomes à P2-06.

## 6. Inventaire declaredOutcomes

Observé :

- `ScenarioAsset.declaredOutcomes` est une liste persistée dans le scénario ;
- `ProjectValidator` vérifie que chaque declared outcome est non vide et sans doublon ;
- `NarrativeWorkspaceProjection` déduplique et trie les declared outcomes ;
- `CutsceneStudioCompiler` collecte des declared outcomes depuis les blocs `emitOutcome` et `sceneResult`.

Lecture domaine :

```text
declaredOutcomes annonce ce qu'un scénario peut produire.
Ce n'est pas un registry global.
Ce n'est pas une preuve qu'un node l'émet réellement.
```

Risques :

- outcome déclaré mais jamais émis ;
- outcome émis sans être déclaré ;
- outcome déclaré dans plusieurs scènes sans intention claire ;
- ID technique exposé comme label auteur ;
- registry global ajouté trop tôt pour "nettoyer" un problème qui peut rester dérivé.

## 7. Inventaire emitOutcome

Observé dans `ScenarioRuntimeExecutor` :

- `emitOutcome` lit `node.binding.outcomeId` ;
- si l'ID est vide, le runtime bloque ;
- le runtime pose un story flag technique `scenario.outcome.<outcomeId>` ;
- le runtime dispatch ensuite `ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId)` ;
- si aucun scénario global ne consomme l'outcome, le flow local continue linéairement ;
- le résultat runtime porte `emittedOutcomeId`.

Lecture domaine :

```text
emitOutcome produit un résultat narratif.
La persistence scenario.outcome.* est un mécanisme technique.
L'auteur doit voir un label d'outcome, pas le flag technique.
```

Outcome et Fact :

- un outcome peut rester un signal de branche ;
- il ne devient Fact que si une Scene / un contrat Fact décide de l'interpréter comme vérité durable ;
- P2-07 décidera la présentation Fact.

## 8. Inventaire sourceOutcome / outcomeReceived

Observé :

- `sourceOutcome` est un node source via `ScenarioNodeType.reference` + `actionKind = sourceOutcome` ;
- `ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId)` porte uniquement l'outcome ;
- le runtime privilégie les scenarios `globalStory` pour `outcomeReceived` ;
- `ProjectValidator` interdit `sourceOutcome` dans un `localEventFlow` ;
- `ProjectValidator` exige `outcomeId` pour `sourceOutcome`.

Lecture domaine :

```text
sourceOutcome consomme un outcome pour déclencher une suite.
Il relie un flow local à la progression globale.
Il appartient à Event Authoring Source côté déclenchement, mais P2-05 doit rendre la référence outcome lisible.
```

Diagnostics existants :

- `sourceOutcomeWithoutMatchingEmitOutcome` ;
- `emitOutcomeWithoutMatchingSourceOutcome`.

## 9. Inventaire NarrativeWorkspaceProjection outcomes

Observé :

- `NarrativeOutcomeScope` classe local / global / mixed / unknown ;
- `NarrativeOutcomeSummary` expose declaredByScenarioIds, emittedByScenarioIds, consumedByScenarioIds ;
- la projection collecte `emitoutcome`, `emit_outcome`, `sourceoutcome`, `source_outcome`, `waituntiloutcome`, `wait_until_outcome` ;
- elle déduplique et trie les IDs ;
- elle reste read-only et editor-oriented.

Lecture domaine :

```text
La projection editor prouve qu'un read model outcome est utile.
Mais map_editor ne doit pas devenir la source de vérité domaine.
```

Ce qui peut être réutilisé conceptuellement :

- classification local / global / mixed ;
- graphe declared / emitted / consumed ;
- déduplication ;
- labels dérivés ;
- warning sur état inconnu.

## 10. Inventaire validation existante

`ProjectValidator` vérifie déjà :

- declared outcome vide ;
- declared outcome dupliqué ;
- `emitOutcome` sans `outcomeId` ;
- `sourceOutcome` sans `outcomeId` ;
- `globalStory` ne peut pas utiliser les sources monde ;
- `localEventFlow` ne peut pas utiliser `sourceOutcome`.

`NarrativeValidator` vérifie déjà :

- outcome consommé mais jamais émis ;
- outcome émis mais jamais consommé.

Manques pour P2-09 :

- outcome déclaré jamais émis ;
- outcome émis non déclaré ;
- label humain manquant ;
- outcome consommé par plusieurs branches sans policy ;
- outcome technique exposé dans workflow auteur ;
- outcome persisté `scenario.outcome.*` sans relation lisible ;
- outcome mélangé à Fact sans contrat.

## 11. Relation Outcome / Fact

Outcome :

```text
Résultat ou branche produit par dialogue/scene.
Peut être temporaire ou durable selon interprétation.
```

Fact :

```text
Vérité lisible du monde.
Doit être exposée avec label humain et consumers.
```

Règle P2-05 :

```text
Un outcome n'est pas automatiquement un Fact.
Scene interprète l'outcome.
P2-07 décidera comment un outcome peut alimenter Fact Descriptor / Presentation Layer.
```

Exemple conceptuel :

- outcome : "Lysa répond avec confiance" ;
- Fact éventuel : "Le rival a été battu au port" ;
- flag technique : `scenario.outcome.local.confident` ou équivalent ;
- seul le Fact est une vérité durable de monde, si la Scene l'écrit.

## 12. Relation Outcome / Battle outcome

Battle outcome ressemble à un outcome narratif car il produit victory/defeat, mais il a une source différente :

```text
battle:<battleId>:victory
battle:<battleId>:defeat
```

P2-05 ne fusionne pas les deux modèles.

Pourquoi :

- P2-06 doit décider le contrat battle reference / battle outcome ;
- battle outcome dépend du moteur combat et du handoff runtime ;
- `map_battle` doit rester indépendant du Narrative Studio ;
- victory/defeat peut être mappé vers outcomes narratifs plus tard, mais ce mapping doit être explicite.

## 13. Consumers explicites

| Consumer | Besoin | Immédiat ? | Persistence ? |
|---|---|---:|---:|
| P2-06 Battle Reference / Outcome Contract | Garder frontière scenario outcomes vs battle outcomes. | Oui, décision seulement. | Non. |
| P2-09 Narrative Validator | Diagnostics outcome complets. | Futur proche. | Non. |
| P2-10 Reference Picker Read Models | Source de picker outcome. | Futur proche. | Non. |
| Future SceneReadModel | Afficher outcomes déclarés/émis/consommés. | Futur. | Non. |
| Future Event picker | Choisir `sourceOutcome` humainement. | Futur. | Non. |
| Phase 4 authoring minimal | Mapper outcomes sans IDs bruts. | Futur. | Non au départ. |
| Runtime | Exécuter `emitOutcome` / `outcomeReceived`. | Déjà servi. | Non. |

Aucun consumer ne justifie un `OutcomeRegistry` persistant maintenant.

## 14. Options de contrat

### Option A — Garder l'existant + diagnostics futurs

Avantages :

- aucune migration ;
- aucune duplication ;
- runtime déjà fonctionnel ;
- validators existants déjà utiles.

Risques :

- UX auteur reste technique ;
- picker outcome reste à construire ;
- diagnostics restent partiels.

Verdict :

```text
Acceptable comme base actuelle, insuffisant pour Phase 4.
```

### Option B — Adapter/read model non persistant

Avantages :

- dérive de `ScenarioAsset` ;
- expose labels, scopes, declared/emitted/consumed ;
- alimente P2-09/P2-10 ;
- évite `OutcomeRegistry` ;
- ne modifie pas `ProjectManifest`.

Risques :

- risque de devenir registry déguisé ;
- doit rester read-only ;
- labels humains devront être prudents tant que les authoring metadata restent variables.

Verdict :

```text
Option recommandée comme trajectoire principale.
Aucun code maintenant.
```

### Option C — Contrat pur minimal dans map_core

Avantages :

- API pure testable ;
- pourrait centraliser la logique future de picker ;
- facilite diagnostics unitaires.

Risques :

- trop tôt avant P2-09/P2-10 ;
- API pas encore prouvée ;
- consumer immédiat insuffisant dans P2-05 ;
- risque de dupliquer projection editor.

Verdict :

```text
À reconsidérer en P2-09/P2-10, pas maintenant.
```

### Option D — OutcomeRegistry persistant

Avantages :

- labels humains centralisés ;
- policy globale possible.

Risques :

- migration `ProjectManifest` ;
- duplication de `declaredOutcomes` ;
- divergence avec `emitOutcome` / `sourceOutcome` ;
- sur-modélisation ;
- registry sans consumer clair.

Verdict :

```text
Refusé maintenant.
```

### Option E — Fusionner outcomes narratifs et battle outcomes

Avantages :

- vocabulaire unique "outcome".

Risques :

- couplage prématuré avec battle ;
- P2-06 court-circuité ;
- victory/defeat mélangé à branches narratives ;
- risque de dépendance Narrative Studio dans `map_battle`.

Verdict :

```text
Refusé. P2-06 traitera battle outcomes séparément.
```

## 15. Matrice comparative

| Option | Complexité | Migration | Duplication | Support Validator | Support pickers | Recommandation |
|---|---:|---:|---:|---:|---:|---|
| A — Existant + diagnostics futurs | Faible | Non | Non | Partiel | Faible | Base actuelle |
| B — Read model non persistant | Moyenne | Non | Faible si dérivé | Fort | Fort | Recommandée |
| C — Contrat pur maintenant | Moyenne | Non | Moyen | Potentiel | Potentiel | Reporter |
| D — OutcomeRegistry persistant | Forte | Oui | Forte | Incertain | Fort | Refuser |
| E — Fusion Battle outcomes | Forte | Incertain | Forte | Incertain | Incertain | Refuser |

## 16. Décision d'implémentation P2-05

Verdict :

```text
B — Adapter/read model recommandé plus tard : aucun code maintenant.
```

Gate :

| Question | Réponse |
|---|---|
| Un Outcome adapter/read model est-il nécessaire maintenant ? | Non. La décision suffit pour P2-06 ; implémentation peut attendre P2-09/P2-10. |
| Quels consumers explicites le justifient ? | Validator, picker read models, future SceneReadModel, future Event picker, Phase 4. Aucun ne bloque P2-05. |
| Peut-il être dérivé de `ScenarioAsset` sans persistence ? | Oui. |
| Peut-il attendre P2-09 / P2-10 ? | Oui. |
| Comment éviter de dupliquer declared/emit/source ? | Read model dérivé seulement ; aucune copie persistée. |
| Comment éviter OutcomeRegistry ? | Pas de stockage global ; labels dérivés ou metadata future. |
| Quels diagnostics deviennent possibles ? | declared jamais émis, emitted non déclaré, consumed orphelin, ID technique visible, Fact confondu. |
| La persistence est-elle nécessaire ? | Non. |

Pourquoi aucun code :

- `NarrativeWorkspaceProjection` prouve déjà la faisabilité read-only côté editor ;
- P2-09 devra choisir les diagnostics exacts ;
- P2-10 devra choisir les sources de picker ;
- P2-06 doit d'abord garder la frontière battle outcomes ;
- créer une API Dart maintenant figerait trop tôt les champs.

## 17. Contrat conceptuel recommandé

Contrat conceptuel non implémenté :

```text
OutcomeReferenceReadModel
```

Champs possibles :

```text
outcomeId
humanLabel
declaredByScenarioIds
emittedByScenarioIds
emittedByNodeIds
consumedByScenarioIds
consumedByNodeIds
persistenceFlagName
isDeclared
isEmitted
isConsumed
isOrphan
durabilityKind
linkedFactId
diagnostics
```

Règles :

- dérivé de `ScenarioAsset` ;
- pas de registry ;
- pas de persistence ;
- pas de `ProjectManifest` ;
- pas de fusion automatique avec battle outcomes ;
- ne pas exposer `scenario.outcome.*` comme label principal ;
- ne pas transformer outcome en Fact automatiquement.

## 18. Diagnostics possibles

Diagnostics futurs :

| Diagnostic | Sévérité probable | Phase probable |
|---|---|---|
| Outcome consommé jamais émis | Warning existant | Déjà/P2-09 |
| Outcome émis jamais consommé | Warning existant | Déjà/P2-09 |
| Outcome déclaré jamais émis | Warning | P2-09 |
| Outcome émis non déclaré | Warning | P2-09 |
| Outcome avec ID vide | Error existant | Déjà |
| Outcome déclaré dupliqué | Error existant | Déjà |
| Outcome exposé comme `scenario.outcome.*` en UX | Warning authoring | P2-10/Phase 4 |
| Outcome durable sans Fact / Step explicite | Warning | P2-07/P2-09 |
| Outcome consommé par plusieurs global stories sans policy | Warning | P2-09 |
| Battle outcome traité comme scenario outcome | Warning/Error | P2-06/P2-09 |

## 19. Impacts sur P2-06 à P2-10

P2-06 :

- battle outcomes restent séparés ;
- mapping battle victory/defeat vers outcome narratif doit être explicite.

P2-07 :

- Fact Descriptor devra décider quand un outcome devient vérité durable ;
- `scenario.outcome.*` reste technique.

P2-08 :

- World Rule peut lire Fact / flag / Step, mais ne consomme pas directement un outcome sans contrat clair.

P2-09 :

- ajouter diagnostics outcome complets ;
- éviter validator concurrent.

P2-10 :

- créer sources de picker outcome ;
- afficher labels humains, scopes et statut declared/emitted/consumed.

## 20. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| OutcomeRegistry prématuré | Refus explicite P2-05. |
| Duplicer `declaredOutcomes` | Read model dérivé, jamais persistant. |
| Exposer `scenario.outcome.*` en UX | Label humain principal, flag en mode avancé seulement. |
| Transformer outcome en Fact automatiquement | P2-07 décide Fact, pas P2-05. |
| Fusionner battle outcomes | P2-06 séparé. |
| `map_editor` source de vérité | Projection editor observée, pas canonisée. |
| Diagnostics trop sévères | P2-09 décidera warning/error. |

## 21. Ce que P2-05 décide

P2-05 décide :

- pas d'OutcomeRegistry persistant maintenant ;
- pas de migration `ProjectManifest` ;
- `declaredOutcomes`, `emitOutcome`, `sourceOutcome` restent sources techniques ;
- `scenario.outcome.*` est technique, pas UX principale ;
- trajectoire principale : `OutcomeReferenceReadModel` non persistant futur ;
- battle outcomes restent à P2-06 ;
- outcome ne devient pas Fact automatiquement.

## 22. Ce que P2-05 ne décide pas

P2-05 ne décide pas :

- API Dart finale d'un read model ;
- diagnostics P2-09 exacts ;
- widgets ou pickers UI ;
- FactDescriptor ;
- battle outcome contract ;
- JSON / persistence ;
- migration `ProjectManifest` ;
- Selbrume réel.

## 23. Implémentation éventuelle

```text
Aucune implémentation.
```

Raison :

```text
Le lot choisit B — adapter/read model futur, design-only maintenant.
Aucun consumer ne nécessite un type Dart immédiat avant P2-06/P2-09/P2-10.
```

## 24. Tests / validations éventuels

Tests Dart/Flutter non exécutés :

```text
Non exécutés — P2-05 est design-only et ne modifie aucun code.
```

Validations pertinentes :

- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- contrôles hors scope ;
- `git status --short`.

## 25. Recommandation pour P2-06

P2-06 doit traiter :

```text
P2-06 — Battle Reference / Outcome Contract
```

Recommandation :

- garder battle outcomes séparés des scenario outcomes ;
- limiter V0 à victory / defeat sauf preuve contraire ;
- ne pas coupler `map_battle` au Narrative Studio ;
- permettre plus tard un mapping explicite battle outcome -> outcome narratif ou Fact, mais ne pas le créer automatiquement.

## 26. Mise à jour de road_map_phase_2.md

Mise à jour attendue :

```text
P2-05 : ✅ terminé
P2-06 : 🔜 prochain lot exact
```

Résumé ajouté :

```text
P2-05 refuse un OutcomeRegistry persistant, garde declaredOutcomes /
emitOutcome / sourceOutcome comme sources techniques et recommande un
OutcomeReferenceReadModel non persistant futur.
```

## 27. Evidence Pack

### 27.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 27.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
```

### 27.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
```

### 27.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 27.5 Commandes exécutées

```text
git status --short --untracked-files=all
ctx_search(sort="timeline", source="session-events", queries=["P2-04 final status P2-05 next roadmap phase 2 report created","P2-04 evidence pack git status final road_map_phase_2 p2_04 report"], limit=3)
ctx_batch_execute(commands=[P2-05 Required Roadmap And Reports Outcome Terms, Scenario Outcome Model And Runtime Terms, Scenario Runtime Executor Outcome Focus, Narrative Validator Outcome Diagnostics Focus, Project Validator Declared Outcome Focus, Narrative Workspace Outcome Projection Focus, Cutscene Studio Outcome Compile Focus], queries=[declaredOutcomes ProjectValidator validation duplicate empty source truth, emitOutcome scenario.outcome flag dispatch outcomeReceived local continuation, sourceOutcome outcomeReceived consumes outcome global story source node diagnostics, NarrativeOutcomeSummary declared emitted consumed projection editor read-only, Outcome Fact relation outcome not automatically Fact durable Scene interprets, Battle outcome relation battle victory defeat separate P2-06, P2-04 SceneReadModel outcomes declared emitted consumed next P2-05, P2-05 roadmap next lot status road_map_phase_2])
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short
ctx_batch_execute(commands=[P2-05 Report Placeholder Check, P2-05 Roadmap Header Check], queries=[P2-05 report placeholders decision implementation OutcomeRegistry P2-06, roadmap phase 2 P2-05 done P2-06 next])
```

### 27.6 git diff --check

```text
```

### 27.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 55 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 48 insertions(+), 7 deletions(-)
```

### 27.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 27.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
```

### 27.10 Tests / analyze

```text
Non exécutés — P2-05 est design-only et ne modifie aucun code.
```

### 27.11 Contrôle no-index du rapport créé

```text
```

### 27.12 Contrôle hors scope roadmaps / map_battle / examples

```text
```

### 27.13 Contrôle hors scope packages de code

```text
```

## 28. Auto-review critique

Checklist :

- Le lot a modifié uniquement ce qui était autorisé : oui, rapport P2-05 et roadmap Phase 2.
- Le rapport P2-05 existe au bon chemin : oui.
- `road_map_phase_2.md` a été mise à jour : oui après patch roadmap.
- `road_map_global.md` est restée intacte : oui, contrôle hors scope sans sortie.
- Aucun code n'a été modifié : oui, contrôle packages sans sortie.
- Aucun build_runner n'a été lancé : oui.
- P2-06 n'a pas été commencé : oui.
- Outcome reste un résultat interprété par Scene : oui.
- Le contrat recommandé évite OutcomeRegistry prématuré : oui.
- Les consumers sont explicites : oui.
- La décision d'implémentation est claire : oui, design-only / option B.
- Le prochain lot exact est clair : oui, P2-06.

Regard critique sur le prompt :

Le prompt autorise une implémentation conditionnelle, mais les consumers réels sont P2-09/P2-10 plutôt que P2-05 immédiat. Créer un type Dart maintenant figerait trop tôt la frontière avec Fact et Battle outcome. Le bon livrable est donc une décision stricte et un contrat conceptuel, pas un modèle.

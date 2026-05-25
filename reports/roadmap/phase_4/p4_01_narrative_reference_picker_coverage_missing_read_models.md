# P4-01 — Narrative Reference Picker Coverage & Missing Read Models V0

## 1. Résumé exécutif

P4-01 est validable sur le fond : le lot ne reste pas documentaire et ajoute un petit batch concret de read models purs dans `map_core`.

Read models existants confirmés :

- `NarrativeScenarioPickerOption`
- `NarrativeOutcomePickerOption`
- `NarrativeBattleReferencePickerOption`

Read models V0 ajoutés :

- `NarrativeStoryStepPickerOption`
- `NarrativeEventSourcePickerOption`
- `NarrativePredicateReferencePickerOption`

Verdict :

```text
P4-01 : clôturable
Prochain lot exact : P4-02 — Scenario Authoring Draft Model V0
```

## 2. Scope du lot

Inclus :

- audit des read models narratifs existants ;
- ajout de read models manquants strictement dérivés ;
- tests ciblés dans `map_core` ;
- mise à jour de `MVP Selbrume/road_map_phase_4.md` ;
- rapport P4-01.

Exclus :

- UI / widget Flutter ;
- registry persistant ;
- migration JSON ;
- modification `ProjectManifest`, `ScenarioAsset`, `GameState` ;
- runtime, editor UI, Selbrume, rewards, money, XP ;
- P4-02.

## 3. Sources lues

Fichiers principaux lus :

```text
AGENTS.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_4.md
reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart
```

## 4. Couverture des read models existants

| Read model | Source | Couverture confirmée | Limite |
|---|---|---|---|
| `NarrativeScenarioPickerOption` | `ProjectManifest.scenarios` | id, label, description, scope, entry node, outcomes déclarés, compte nodes/edges, tri stable | ne décrit pas les sources Event ni les steps |
| `NarrativeOutcomePickerOption` | `ScenarioAsset.declaredOutcomes`, `emitOutcome`, `sourceOutcome` | outcomes déclarés/émis/consommés, orphelins, label humanisé, tri stable | ne crée pas de registry outcome |
| `NarrativeBattleReferencePickerOption` | nodes `startTrainerBattle`, `ProjectManifest.trainers` | battle id, trainer id, labels trainer, outcomes victory/defeat V0, fallback si trainer inconnu | ne crée pas de registry battle |

Ces trois read models restent inchangés fonctionnellement.

## 5. Gaps de pickers / read models

| Picker / read model | Décision P4-01 | Justification |
|---|---|---|
| Story Step picker | A — implémenté maintenant | Source Step Studio metadata et fallback legacy `step.*` déjà stabilisés comme metadata authoring. |
| Event Source picker | A — implémenté maintenant | Sources stables : maps du manifest, `MapData.entities`, `MapData.triggers`, outcomes dérivés. |
| Predicate / Fact reference picker | A — implémenté maintenant | Peut être strictement dérivé de flags, steps, cutscenes, scenario outcomes et battle outcomes. |
| Map picker standalone | B — reporter P4-03 | Couvert partiellement par Event Source V0 ; un picker map générique dépendra du draft source. |
| Entity / NPC picker standalone | B — reporter P4-03/P4-05 | Couvert partiellement via Event Source V0 ; authoring predicate/visibility précis arrive P4-05. |
| Trigger picker standalone | B — reporter P4-03 | Couvert partiellement via Event Source V0 quand `MapData` est fourni. |
| Dialogue picker | B — reporter P4-02/P4-07 | `ProjectManifest.dialogues` est stable, mais pas nécessaire au batch P4-01 minimal. |
| Cinematic picker | C/D — reporter Phase 7 ou décision produit | Le modèle Cinematic/Scene Builder premium n'est pas ouvert en P4-01. |
| World Rule picker | B — reporter P4-05 | Doit arriver avec draft predicate/world rule, sans `WorldRuleRegistry`. |
| Condition picker | B — reporter P4-05 | Doit se brancher sur `MapEntityRuntimePredicate` et diagnostics authoring. |

## 6. Read models ajoutés

### 6.1 `NarrativeStoryStepPickerOption`

Builder :

```text
buildNarrativeStoryStepPickerOptions(ProjectManifest manifest)
```

Sources :

- `ScenarioAsset.metadata['authoring.stepStudioDocument']` pour les scénarios `globalStory` ;
- fallback legacy `step.id`, `step.name`, `step.description`, `step.cutsceneIds`.

Champs clés :

- `stepId`
- `humanLabel`
- `description`
- `sourceScenarioId`
- `sourceScenarioLabel`
- `sourceKind`
- `order`
- `linkedCutsceneIds`
- `expectedOutcomeIds`
- `emittedOutcomeIds`

Limite volontaire : pas de `StoryStepRegistry`, pas de modèle persistant.

### 6.2 `NarrativeEventSourcePickerOption`

Builder :

```text
buildNarrativeEventSourcePickerOptions(ProjectManifest manifest, {Iterable<MapData> maps = const []})
```

Sources :

- `ProjectManifest.maps` pour `mapEnter` ;
- `MapData.triggers` pour `triggerEnter` si les maps chargées sont fournies ;
- `MapData.entities` pour `entityInteract` si les maps chargées sont fournies ;
- `buildNarrativeOutcomePickerOptions` pour `outcomeReceived`.

Sources supportées :

```text
mapEnter
triggerEnter
entityInteract
outcomeReceived
```

Limite volontaire : trigger/entity ne sont pas inventés quand `MapData` n'est pas fourni.

### 6.3 `NarrativePredicateReferencePickerOption`

Builder :

```text
buildNarrativePredicateReferencePickerOptions(ProjectManifest manifest)
```

Références dérivées :

- story flags depuis `activationCondition`, node bindings, node conditions et Step Studio metadata ;
- story steps depuis `NarrativeStoryStepPickerOption` ;
- cutscenes depuis scénarios `localEventFlow` ;
- scenario outcomes sous forme `scenario.outcome.<outcomeId>` ;
- battle outcomes sous forme `battle:<battleId>:victory` et `battle:<battleId>:defeat`.

Limite volontaire : pas de `FactRegistry`, pas de `WorldRuleRegistry`.

## 7. Read models reportés

Reportés à P4-02/P4-03 :

- Dialogue picker ;
- Map picker standalone ;
- Entity/NPC picker standalone ;
- Trigger picker standalone ;
- Event Source draft operations.

Reportés à P4-05 :

- Condition picker ;
- World Rule picker ;
- Predicate/world presence authoring draft.

Reportés à Phase 7 ou décision produit :

- Cinematic picker premium ;
- Scene Builder / Cinematic Builder complet.

## 8. Décisions d’architecture

- Les nouveaux read models vivent dans `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`.
- Ils sont exportés par le barrel existant `packages/map_core/lib/map_core.dart` sans modification supplémentaire, car ce fichier exportait déjà le fichier de read models.
- Le parsing Step Studio reste dérivé et tolérant : JSON invalide ou absent ne casse pas les pickers.
- Les refs predicate restent des facts techniques dérivés, pas une nouvelle source de vérité.
- Les options Event Source acceptent `MapData` comme source optionnelle pour ne pas transformer `ProjectManifest` en conteneur de maps chargées.

## 9. Tests exécutés

Commandes principales :

```bash
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart format --set-exit-if-changed lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart analyze
```

Résultats :

```text
dart test test/narrative_reference_picker_read_models_test.dart : All tests passed, +8
dart test test/narrative_validator_test.dart : All tests passed, +21
dart format --set-exit-if-changed : 0 changed
dart analyze : No issues found
```

## 10. Modifications effectuées

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

Fichiers créés :

```text
reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
```

Aucun fichier `road_map_global.md`, `map_editor`, `map_runtime`, `map_gameplay`, `map_battle` ou `examples/playable_runtime_host` n'a été modifié.

## 11. Evidence Pack

### 11.1 git status initial exact

```text

```

Le statut initial était propre.

### 11.2 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,320p' "MVP Selbrume/road_map_global.md"
sed -n '1,520p' "MVP Selbrume/road_map_phase_4.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_00_phase_4_roadmap_recalibration_authoring_workflow_audit.md
sed -n '1,420p' packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
sed -n '1,320p' packages/map_core/test/narrative_reference_picker_read_models_test.dart
rg -n "NarrativeScenarioPickerOption|NarrativeOutcomePickerOption|NarrativeBattleReferencePickerOption|StepStudio|StoryStep|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|outcomeReceived|MapEntityRuntimePredicate|visibilityRule|conditionalDialogues|declaredOutcomes|emitOutcome|startTrainerBattle|battle:" packages/map_core packages/map_editor packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_core/lib/src/read_models -type f 2>/dev/null | sort
find packages/map_core/test -type f | sort | rg "narrative|picker|read_model|reference|story|predicate|battle|outcome"
sed -n '1,260p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,420p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
sed -n '1,320p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,260p' packages/map_core/lib/src/models/script_conditions.dart
sed -n '1,760p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,320p' packages/map_editor/lib/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart format lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart format --set-exit-if-changed lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart
cd packages/map_core && dart test test/narrative_validator_test.dart
cd packages/map_core && dart analyze
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 11.3 TDD rouge initial

```text
cd packages/map_core && dart test test/narrative_reference_picker_read_models_test.dart

Failed to load "test/narrative_reference_picker_read_models_test.dart":
Error: Type 'NarrativeEventSourcePickerOption' not found.
Error: Type 'NarrativePredicateReferencePickerOption' not found.
Error: Method not found: 'buildNarrativeStoryStepPickerOptions'.
Error: Method not found: 'buildNarrativeEventSourcePickerOptions'.
Error: Method not found: 'buildNarrativePredicateReferencePickerOptions'.
Some tests failed.
```

### 11.4 Sortie complète du test ciblé final

```text
00:00 +0: loading test/narrative_reference_picker_read_models_test.dart
00:00 +0: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds scenario picker options with stable labels and counts
00:00 +1: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids
00:00 +2: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds battle reference picker options from trainer battle nodes
00:00 +3: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models builds story step picker options from Step Studio metadata
00:00 +4: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models dedupes story steps and keeps legacy metadata as fallback
00:00 +5: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds event source picker options from maps entities and outcomes
00:00 +6: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models builds predicate reference picker options from derived facts
00:00 +7: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: Narrative reference picker read models returns empty missing read model options for empty sources
00:00 +8: All tests passed!
```

### 11.5 Sortie complète de la régression ciblée

```text
00:00 +0: loading test/narrative_validator_test.dart
00:00 +0: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics
00:00 +1: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unknown edge target produces error
00:00 +2: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 unreachable node produces warning
00:00 +3: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 scenario without source produces error
00:00 +4: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error
00:00 +5: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error
00:00 +6: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error
00:00 +7: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error
00:00 +8: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error
00:00 +9: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown map produces error
00:00 +10: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 source entityInteract with unknown entity produces error
00:00 +11: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 sourceOutcome without matching emitOutcome produces warning
00:00 +12: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 emitOutcome without matching sourceOutcome produces warning
00:00 +13: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 declared outcome never emitted produces warning
00:00 +14: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 emitOutcome not declared by scenario produces warning
00:00 +15: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 conditional visibility rule without predicate produces error
00:00 +16: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 world rule predicate with empty refId produces error
00:00 +17: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 choice node produces runtime unsupported warning
00:00 +18: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 setFlag used by condition does not warn as unused
00:00 +19: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 completeStep used by world rule does not warn as unused
00:00 +20: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: Narrative Validator Minimal V0 diagnostics are stable and sorted deterministically
00:00 +21: All tests passed!
```

### 11.6 Format et analyze

```text
cd packages/map_core && dart format --set-exit-if-changed lib/src/read_models/narrative_reference_picker_read_models.dart test/narrative_reference_picker_read_models_test.dart
Formatted 2 files (0 changed) in 0.02 seconds.

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

### 11.7 Fichiers créés

```text
reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
```

### 11.8 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

### 11.9 Contenu / diff des fichiers modifiés

Pour `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`, le diff ajoute :

```text
NarrativeStoryStepPickerSource
NarrativeEventSourceKind
NarrativePredicateReferenceKind
NarrativeStoryStepPickerOption
NarrativeEventSourcePickerOption
NarrativePredicateReferencePickerOption
buildNarrativeStoryStepPickerOptions
buildNarrativeEventSourcePickerOptions
buildNarrativePredicateReferencePickerOptions
helpers privés de parsing metadata Step Studio, flags et labels
```

Pour `packages/map_core/test/narrative_reference_picker_read_models_test.dart`, le diff ajoute :

```text
tests Story Step metadata Step Studio
tests fallback legacy step.*
tests Event Source map/entity/trigger/outcome
tests Predicate Reference flags/steps/cutscenes/scenario outcomes/battle outcomes
test cas vide pour les trois read models ajoutés
helpers _mapData, _byEventSourceKind, _byPredicateReference
```

Pour `MVP Selbrume/road_map_phase_4.md`, le diff marque :

```text
P4-01 : terminé
Prochain lot exact : P4-02 — Scenario Authoring Draft Model V0
```

### 11.10 git diff --check exact

```text

```

### 11.11 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_4.md                   |  40 +-
 .../narrative_reference_picker_read_models.dart    | 694 +++++++++++++++++++++
 ...arrative_reference_picker_read_models_test.dart | 373 ++++++++++-
 3 files changed, 1097 insertions(+), 10 deletions(-)
```

### 11.12 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_4.md
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/narrative_reference_picker_read_models_test.dart
```

### 11.13 Contrôles hors scope

```text
git diff --name-only -- "MVP Selbrume/road_map_global.md"

git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host

git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation

```

Les trois sorties sont vides.

### 11.14 git status final exact

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
 M packages/map_core/test/narrative_reference_picker_read_models_test.dart
?? reports/roadmap/phase_4/p4_01_narrative_reference_picker_coverage_missing_read_models.md
```

## 12. Auto-review critique

- Le rapport P4-01 existe au bon chemin : oui.
- `road_map_phase_4.md` est mise à jour : oui.
- `road_map_global.md` n'est pas modifiée : oui.
- Aucun code hors `map_core` n'est modifié : oui.
- Aucun modèle persistant n'est modifié : oui.
- Aucun `ProjectManifest`, `ScenarioAsset`, `GameState` n'est modifié : oui.
- Aucun widget UI n'est créé : oui.
- Aucun registry persistant n'est créé : oui.
- Aucun Selbrume final n'est créé : oui.
- Aucun rewards/money/XP n'est ajouté : oui.
- P4-02 n'est pas exécuté : oui.
- Les tests ciblés passent : oui.
- Les gaps non traités sont explicitement reportés : oui.

## 13. Regard critique sur le prompt

Le prompt force utilement P4-01 à quitter la logique "review/design" de P4-00. La contrainte la plus structurante est la défense contre les registries persistants : elle oblige les pickers à rester dérivés des sources réelles existantes. La principale limite est que certains pickers naturellement utiles, comme Dialogue ou Map standalone, pourraient facilement gonfler le lot ; ils sont donc reportés pour préserver un batch V0 testable et réellement terminé.

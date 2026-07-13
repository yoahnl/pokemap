# NS-EVENT-V2 — Phase D — Evidence Pack

## 1. Autorité et périmètre

Lot : `NS-EVENT-V2 — PHASE D — Migration Integrity Closure, Source Catalogs & Unified Read Models V0`.

Autorité source : fichiers Dart listés ci-dessous. Ce pack ne duplique pas leurs
15 000+ lignes : conformément au §23 du prompt Phase D, il fournit chemins,
SHA-256, nombres de lignes, zones, matrices, vecteurs et sorties exactes.

```text
Production : packages/map_core uniquement
Editor production : inchangé
Runtime production : inchangé
Gameplay/Battle : inchangés
Selbrume data : inchangée par cet agent
Migration réelle : NO
Commit : NO
```

## 2. Commits baseline

```text
Phase C canonique : eb1b4998 NS-EVENT-V2 PHASE C: Legacy Compatibility & Non-Destructive Migration
Gate 0 Phase D    : 85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
Branche           : main
Arbre initial     : clean
```

`git log --oneline -n 30` au Gate 0 :

```text
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
02de2ffe feat(editor): add design-system dropdown field
816671f7 feat: refine Port des Brisants visuals and editor controls
928cccae test(selbrume): add Port des Brisants visual refinement tests
9fae047b test
7797d332 feat(selbrume): rebuild Port des Brisants from reference
a9a12723 feat(selbrume): generate seamless water family v2
bd95861a feat(selbrume): add provenance-locked visual kit v2
459242b7 feat(selbrume): validate authored maps without rebuilding
5edc3cf4 fix(selbrume): recover authored map placements
a4c7dead feat(editor): add explicit placement origin migration
39e7dc37 fix(editor): guard placement ownership and bulk saves
96d1862f fix(editor): preserve authored map placements on load
d9e08979 chore: remove generated skill cache
60b3a8af tools: add reference-to-PokeMap authoring skill
fc40a09d SEL-MAP-001: normalize legacy map filenames
e0def288 SEL-MAP-001: build Selbrume beta maps and assets
eb1b4998 NS-EVENT-V2 PHASE C: Legacy Compatibility & Non-Destructive Migration
fdaf4e5d NS-EVENT-V2 PHASE B: Canonical Domain Contracts & Structural Source Index
61941c39 NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
d26bfa9c NS-EVENT-RESET-00: Canonical Event Sources & Event Builder V2 Ultra Roadmap
56882754 NS-EVENT-41-bis: Truthful Stepper & Secondary Details Access Closure V0
ed91ca2c NS-EVENT-41: Event Builder Simplified Guided Configuration Layout V0
88314c22 NS-EVENT-40: Event Builder Shell-Level Pixel Polish & Real App Visual QA V0
89b81e47 NS-EVENT-39: Event Builder Reference UI Redesign / Flow-Based Layout V0
6fab98e4 NS-EVENT-38: Event Builder Map Placement & Post-Creation Guided Setup UX V0
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
```

Deux commits concurrents sont arrivés pendant le lot, sans commande Git write de
cet agent :

```text
56fd6342 feat(editor): use dropdown for layer creation type
39a9f7bb feat(selbrume): add forest layer to map bourg selbrume
```

Chemins concernés : layers panel + deux tests editor, et
`selbrume/maps/map_bourg_selbrume.json`. Aucun chevauchement Phase D.

## 3. Gate 0

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git branch --show-current
main
$ git status --short --untracked-files=all
<empty>
$ git diff --stat
<empty>
$ git diff --name-only
<empty>
```

Baseline Phase C ciblée exécutée avant modification : planner + receipt `PASS`.
La preuve finale plus forte est la suite complète à 2 842 tests.

## 4. Drifts et hashes

Les drifts annoncés par le prompt n'étaient pas présents dans `git status`, mais
leurs contenus ont été surveillés malgré les commits concurrents :

| Fichier | SHA-256 Gate 0 | SHA-256 final | Verdict |
|---|---|---|---|
| `packages/map_editor/pubspec.lock` | `78c3a9fee5b8cb0949c518c93fd4fae70b18fe5567334957c581d59c3ede37da` | identique | préservé |
| `selbrume/assets/GENERATED_ASSET_PROMPTS.md` | `f5c518079a279906bd7d587d756192957587396c77c6908fda56ebd8a8eb1eef` | identique | préservé |

## 5. Fichiers lus

Documents : prompt Phase D, `AGENTS.md`, `codex_rule.md`, roadmap V2, ADR
Phase A, rapports/evidence packs Phase B et C.

Contrats principaux : ProjectManifest, MapData, MapEntity, MapTrigger,
MapEventDefinition, ScenarioAsset, SceneAsset, Scene diagnostics/runtime plan,
NarrativeEventRegistry/Record/SourceRef, legacy projections, migration plan,
receipt, reference mappings, source index, V1 Event Builder read model et World
Rule projections.

Consumers de compatibilité : tests Event Builder/Scenario editor et runtime
legacy characterization.

## 6. MCP Dart et symboles

MCP Dart indisponible dans la session. Symboles inspectés par source/analyzer :

```text
NarrativeEventMigrationPlanner / Input / Plan
NarrativeEventMigrationReceipt / mappings / snapshots
LegacyMapEventProjection / LegacyScenarioSourceProjection
NarrativeEventSourceRef / NarrativeOutcomeRef
ProjectManifest / MapData / SceneAsset / ScenarioAsset
buildNarrativeSpatialEventSourceCatalog
buildNarrativeOutcomeEventSourceCatalog
buildNarrativeEventProjectCatalog
buildNarrativeEventBuilderProjectReadModel
buildNarrativeEventNavigationIndex
```

## 7. Agents et incidents

| Rôle | Résultat final | Incident |
|---|---|---|
| A Audit/architecture | PASS | aucun blocker |
| B D0 migration integrity | PASS | aucun blocker final |
| C D1 spatial | PASS | aucun blocker final |
| D D2 outcomes | PASS | aucun blocker final |
| E D3 unified read model | PASS | reviews R1/R2 |
| F D4 navigation | PASS | reviews R1/R2 |
| G tests/perf/compat | PASS après correction | premier benchmark BLOCKED |
| R1 architecture/data | PASS | aucun write |
| R2 product truthfulness | PASS | aucun write |
| Review finale contradictoire | PASS après correction | faux positif D2 BLOCKED, deux P3 fermés |

Le premier spawn G a été refusé avant création pour combinaison API invalide ;
relance correcte, aucun fichier touché. Le premier verdict G `BLOCKED` a été
traité comme un vrai gate, pas comme un avis facultatif.

La review finale a ensuite bloqué une Scene Outcome sélectionnable malgré un
Dialogue projet absent, ainsi qu'un ordre D1 documenté incomplet. D2 valide
désormais le plan, les références manifeste et les références map-backed ; les
catalogues projet/navigation transmettent le snapshot de maps. La re-review est
`PASS`. Les fixtures ajoutées ont connu un échec de chargement initial dû à une
liste `const` de `SceneEdge` non const ; annotation retirée, gates tous relancés.
La dernière passe a demandé un wording roadmap moins absolu et une preuve D4
directe du cas map-backed. Les deux ont été ajoutés. Le helper de test a d'abord
fourni un titre nullable à `MapEventDefinition`; fallback ajouté avant relance.
La re-review du delta a rendu `PASS` sans finding résiduel.

## 8. Inventaire des fichiers

### 8.1 Modifiés

| Fichier | Zone | Raison |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports | publier contrats Phase D |
| `legacy_scenario_source_projection.dart` | predicate source node | partager la définition canonique D3/D4 |
| `narrative_event_migration_plan.dart` | plan/attestation/invariants | `ready/canApply` fort |
| `narrative_event_migration_planner.dart` | façade | conserver import historique, extraire implémentation |
| `narrative_event_migration_receipt.dart` | closed-world receipt | invariants et JSON strict |
| `narrative_event_reference_mapping.dart` | mapping closure | références exactes et immuables |
| `narrative_event_migration_planner_test.dart` | D0/C4 fixtures | contextual integrity + Dialogue déclaré |
| `MVP Selbrume/road_map_event_builder_v2.md` | Phase D/E | clôture D, readiness E |

### 8.2 Créés — production

| Fichier | Lignes | SHA-256 | Autorité |
|---|---:|---|---|
| `lib/src/catalogs/narrative_event_project_catalog.dart` | 319 | `6becfebf9e483ff7eb5c0ba9f8065a027e2fdb7884f3c8f33d51d9d00a96f5d7` | contexte projet |
| `lib/src/catalogs/narrative_outcome_event_source_catalog.dart` | 228 | `56fbb5108c2eafd79f0046c0da2ab49b4c2d642e924b84770cf392a9d8628e36` | options outcomes |
| `lib/src/catalogs/narrative_spatial_event_source_catalog.dart` | 384 | `91af5b9831087cb94d25a4b1df5359c97e457997d249d44e8862b79e6b46fbe2` | options spatiales |
| `lib/src/compatibility/narrative_event_migration_choice.dart` | 366 | `efab825cc9c795a519f9aba4f019a50c05a9e6ad34a6c0d5963f73b885235a0c` | confirmation/réassignation |
| `lib/src/compatibility/narrative_event_migration_planner_impl.dart` | 3 680 | `57bc0c770ff9ad6e236d0ac2ee558a6930b61e6aed04d986c542cb73db1b12e1` | planner D0 |
| `lib/src/compatibility/narrative_event_migration_receipt_codec.dart` | 260 | `4cc887c264c488f40ac148bfafa38d3213eb949b174a59f290be88531fa522e9` | decoder bytes strict |
| `lib/src/operations/build_narrative_event_project_catalog.dart` | 586 | `9fe5b0f7c0dc134da041a9a7fad4d0337100e96a89e3247536286a5793dce0d3` | build contexte |
| `lib/src/operations/build_narrative_outcome_event_source_catalog.dart` | 814 | `6b6abf148008a9766b0bdd7c5b0f032de557ba73f1df972ea5a07a830b6f0796` | enumerate producers |
| `lib/src/operations/build_narrative_spatial_event_source_catalog.dart` | 710 | `054779645a2c1951ed0f75250ad94c30bf944dbf005aad6053586e372622ae16` | enumerate maps/entities/triggers |
| `lib/src/read_models/narrative_event_builder_project_read_model.dart` | 2 018 | `0155a10a3b48bd3e6a3c5df78bc0300ea08cb77048c43e08bead3d1345164074` | projection projet |
| `lib/src/read_models/narrative_event_navigation_intent.dart` | 969 | `ab6cb7425154f12ba9e2b551a5e9e54aa09e340a2290994f988c0efb900d07de` | destinations pures |
| `lib/src/read_models/narrative_event_read_deduplication.dart` | 12 | `8761878b1f1c1a785160fddcb81496ace39fe8b07906de8fffbb16d9a03a8bec` | helper interne exact |

Les chemins du tableau sont sous `packages/map_core/`.

### 8.3 Créés — tests et benchmark

| Fichier | Lignes | SHA-256 |
|---|---:|---|
| `test/narrative_event_builder_project_read_model_test.dart` | 966 | `c1d1d85185cbe0a39e4798586d5626f1ce973bee826f9a1a99e3f8ae4b9830e4` |
| `test/narrative_event_migration_integrity_closure_test.dart` | 1 195 | `631b81f297ee8e0e4729cb13c462c4d8b8a6d00ae012d477f76b3ed445d3580d` |
| `test/narrative_event_migration_receipt_codec_test.dart` | 338 | `5b6125dd78ab800fb42c4e412993a79a30fde8ad676f5ebcfee3d0cc75101989` |
| `test/narrative_event_navigation_intent_test.dart` | 642 | `965a5dd6fb46c22c60b7f706278c456cc7c8aa20a409634570df5a542ef52d77` |
| `test/narrative_event_read_deduplication_test.dart` | 25 | `5066e5b1fa7000515e4e4d612139194183ae8d66df6c25ea18c8e7be536d044f` |
| `test/narrative_outcome_event_source_catalog_test.dart` | 801 | `f7a6d35c35b006c93613c0251fa84111a54ca9a4ec052122baf0737b749205ea` |
| `test/narrative_spatial_event_source_catalog_test.dart` | 738 | `d1d0f2f727463631083562a2f1d2c8a8579da06dec766514b4808eeb8638d6e4` |
| `test/scene_outcome_diagnostics_test.dart` | 89 | `9b7cfd05d6c329748fc231e9ceb7bf3debf5a1c8089f69f82b42b6ba6bb361dd` |
| `tool/narrative_event_phase_d_performance.dart` | 449 | `4912eaaf0d14947b84c16ed8ffe2b5bc7a5352f519eeae6c0335e2d5ccc81fc2` |

Deux rapports sont créés. Aucun fichier supprimé. Aucun generated créé/modifié.

## 9. API publique

Exports ajoutés :

```text
narrative_spatial_event_source_catalog.dart
narrative_outcome_event_source_catalog.dart
narrative_event_project_catalog.dart
build_narrative_spatial_event_source_catalog.dart
build_narrative_outcome_event_source_catalog.dart
build_narrative_event_project_catalog.dart
narrative_event_migration_choice.dart
narrative_event_migration_receipt_codec.dart
narrative_event_builder_project_read_model.dart
narrative_event_navigation_intent.dart
```

Le helper `narrative_event_read_deduplication.dart` n'est pas exporté.

## 10. Receipt strict vectors

| Vecteur | Résultat |
|---|---|
| receipt Phase C valide | decoded |
| round-trip canonique | stable |
| schema futur | unsupported + raw bytes |
| enum futur | unsupported + raw bytes |
| champ requis absent | invalid + raw bytes |
| champ root inconnu | unsupported |
| champ nested inconnu | unsupported |
| type invalide | invalid |
| bytes non JSON | invalid |

Le decode n'alloue ni ID ni clock et ne réencode pas une failure.

## 11. Duplicate key vectors

| Vecteur JSON | Résultat |
|---|---|
| clé root littéralement dupliquée | invalid |
| clé root équivalente via escape | invalid |
| clé nested receipt dupliquée | invalid |
| clé mapping dupliquée | invalid |
| clé snapshot dupliquée | invalid |
| tableau contenant objets valides | decoded si chaque objet est fermé |

Scanner strict réutilisé ; aucune troisième implémentation permissive.

## 12. Choice vectors

| Choix | Preuve requise | Mutation silencieuse possible |
|---|---|---:|
| confirmCandidate | source exactement dans candidats | non |
| explicitReassignment | source catalogue + raison + targets | non |
| confirmation contradictoire | aucune | bloquée |
| réassignation sans raison | aucune | construction rejetée |
| source/Fact inventé | aucune | bloqué par catalogue |

## 13. Source eligibility snapshot

Snapshot littéral et tests :
`packages/map_core/test/narrative_spatial_event_source_catalog_test.dart`.

```text
mapEnter : une option par map manifeste
MapEntity : npc/sign/item/custom sélectionnables selon contrat
spawn : visible non sélectionnable
MapPlacedElement : jamais présenté comme MapEntity
MapTrigger event/custom : sélectionnable si area valide
triggers système : visibles non sélectionnables
missing map : visible + diagnostic
identity : type + mapId + ownerId, jamais position
geometry : bounds/mapWide/unavailable read-only
order : map label/id, type order, availability, human label, structural identity
```

## 14. Outcome catalog snapshot et collisions

Snapshot/tests :
`packages/map_core/test/narrative_outcome_event_source_catalog_test.dart`.

```text
scene:scene_a:victory != scene:scene_b:victory
scene:scene_a:victory != battle:trainer:rival:victory
legacyScenario:scenario_a:victory reste qualifié legacy
Yarn expected outcome -> producer Scene
producer duplicate -> ambiguous
outcome missing -> visible non selectable
```

La preuve de collision compare les refs qualifiées complètes. Aucun
`putIfAbsent(outcomeId)` global.

## 15. Migration integrity regression matrix

| # | Cas | Résultat final |
|---:|---|---|
| 1 | source missing | blocked avant IDs/clock |
| 2 | source unavailable | blocked |
| 3 | source ambiguous | blocked |
| 4 | confirm candidate exact | ready possible |
| 5 | confirmation change source | blocked |
| 6 | explicit reassignment valid | ready possible |
| 7 | Fact duplicate | blocked |
| 8 | Event condition dangling | blocked |
| 9 | proposed Event valide référencé | accepté |
| 10 | Scene missing/duplicate/unbuildable | blocked |
| 11 | outcome producer missing | blocked |
| 12 | same local outcome, right producer | accepted |
| 13 | validation catalog absent | blocked |
| 14 | receipt unknown field | unsupported |
| 15 | duplicate nested receipt key | invalid |
| 16 | assisted source/Fact invented | blocked |

## 16. Read model snapshots

Autorité :
`packages/map_core/test/narrative_event_builder_project_read_model_test.dart`.

Preuves :

- records V2 enabled/disabled partageant une source restent deux Events ;
- claim exact fusionne uniquement la présentation V2/legacy ;
- invalid claim et tombstone restent visibles ;
- drafts, missing refs et legacy sont groupés honnêtement ;
- projections Scene/World Rules sont read-only ;
- snapshot JSON littéral déterministe ;
- listes et maps exposées immuables ;
- vocabulaire technique absent du texte principal.

## 17. Claim dedup proofs

Déduplication autorisée seulement si :

```text
registry sans conflit global
claim fingerprint actuel exact
cohort/members complets
projection courante unique par provenance
receipt ID cohérent
target Event présent, configured, source identique, contexte valide
```

Sinon : résumé claim invalid/migration blocked + diagnostic. Aucun legacy caché.

## 18. Navigation destination matrix

| Entrée | Destination | Focus/raison |
|---|---|---|
| entity source | focusEntity | bounds exacts |
| trigger source | focusTrigger | area exacte |
| mapEnter | openMap | focus map sans fausse tile |
| outcome | openOutcomeProducer | non spatial |
| Scene | openScene | ou raison absent/duplicate |
| Fact | openFact | ou raison absent/duplicate |
| Event | openNarrativeEvent | ou raison absent/duplicate |
| Scenario source | openLegacyScenario | scenarioId + nodeId |
| claim provenance | openMigrationReview | provenance exacte |

Invariant factory : destination XOR `absenceReason`. Toute destination spatiale
exige un focus cohérent.

## 19. Performance environment

```json
{"dartVersion":"3.12.1 stable macos_arm64","os":"macOS 27.0 (26A5378j)","machine":"MacBookPro18,3","cpu":"Apple M1 Pro","memoryBytes":"34359738368","mode":"JIT","warmup":"1 petit non enregistré par opération","iterations":{"small":5,"medium":3,"large":2}}
```

## 20. Performance samples exacts (microsecondes)

| Dataset | Opération | Samples | Mean | Median | Result |
|---|---|---|---:|---:|---:|
| small | spatial | 13687, 9387, 8235, 7837, 7271 | 9283 | 8235 | 100 |
| small | outcome | 8378, 11241, 8241, 8010, 8120 | 8798 | 8241 | 100 |
| small | unified | 15011, 14088, 12801, 12102, 11996 | 13200 | 12801 | 50 |
| small | navigation lookup | 39, 38, 38, 43, 39 | 39 | 39 | 50 |
| small | diagnostic dedup | 359, 107, 108, 135, 103 | 162 | 108 | 50 |
| medium | spatial | 467996, 457832, 447199 | 457676 | 457832 | 2000 |
| medium | outcome | 315109, 301148, 303783 | 306680 | 303783 | 2000 |
| medium | unified | 540041, 549641, 521696 | 537126 | 540041 | 1000 |
| medium | navigation lookup | 856, 793, 859 | 836 | 856 | 1000 |
| medium | diagnostic dedup | 1901, 1428, 1145 | 1491 | 1428 | 1000 |
| large | spatial | 6611587, 6615613 | 6613600 | 6613600 | 20000 |
| large | outcome | 4245638, 4263044 | 4254341 | 4254341 | 20000 |
| large | unified | 7311036, 7155837 | 7233437 | 7233437 | 10000 |
| large | navigation lookup | 6368, 5309 | 5839 | 5839 | 10000 |
| large | diagnostic dedup | 13949, 18248 | 16099 | 16099 | 10000 |

Inputs spatiaux exacts :

| Dataset | Manifest maps | Loaded | Missing map source | Entities | Triggers | Multi-cell local | Events |
|---|---:|---:|---:|---:|---:|---:|---:|
| small | 10 | 9 | 1 | 45 | 45 | 9 | 50 |
| medium | 100 | 99 | 1 | 950 | 950 | 190 | 1 000 |
| large | 500 | 499 | 1 | 9 750 | 9 750 | 1 950 | 10 000 |

Outcome isole respectivement 100/2 000/20 000 outcomes, sans maps/Events.
Diagnostic dedup isole 150→50, 3 000→1 000 et 30 000→10 000.

## 21. Complexité et cache futur

```text
Catalog collection : O(M + S)
Catalog sorting : O(S log S)
Project event validation/grouping : O(E + dependencies), puis tris O(E log E)
Navigation index build : O(M + S + producers + E)
Navigation lookup : O(1) moyen
Diagnostic dedup : O(D + U log U)
```

Cache futur autorisable : valeur immuable par `(manifestHash, mapHashes)` ;
invalidation sur maps/entities/triggers, Scenes/outcomes, trainers, scenarios,
Facts, registry ou claims. Aucun cache global mutable Phase D.

## 22. Outputs gates ciblés

Commandes exactes du prompt, sorties finales :

```text
D0-A : 00:00 +78: All tests passed!
D1   : 00:00 +30: All tests passed!
D2   : 00:00 +21: All tests passed!
D0-B : 00:00 +105: All tests passed!
D3   : 00:00 +50: All tests passed!
D4   : 00:00 +45: All tests passed!
```

Correction C4 :

```text
2 tests suspects isolés : +2 All tests passed
planner test complet     : +50 All tests passed
```

## 23. Full map_core gate

```text
$ dart format --output=none --set-exit-if-changed <28 fichiers Dart>
Formatted 28 files (0 changed) in 0.11 seconds.

$ dart test --reporter=compact
00:07 +2842: All tests passed!

$ dart analyze
Analyzing map_core...
No issues found!
```

## 24. build_runner / generated

Deux passages finaux après fermeture des références Scene :

```text
Built with build_runner in 10s; wrote 0 outputs.
Built with build_runner in 1s; wrote 0 outputs.
```

Warning stable : SDK language 3.12 > analyzer language 3.9. Aucun generated
file modifié et aucun churn hors package.

## 25. Compatibility editor

```text
$ flutter test --reporter=compact \
  test/scenario_authoring_claim_guard_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_draft_creation_notifier_test.dart
00:15 +189: All tests passed!

$ flutter analyze --no-fatal-infos <3 tests ciblés>
No issues found! (ran in 2.8s)

$ flutter build macos --debug
Built build/macos/Build/Products/Debug/map_editor.app
```

Global editor : `451 issues`, exit 1 : 81 errors, 10 warnings, 360 infos.
Errors uniquement :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
test/application/services/pokemon_sdk_move_catalog_converter_test.dart
test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart
```

Aucune occurrence d'un chemin/symbole Phase D.

## 26. Compatibility runtime

```text
$ flutter test --reporter=compact \
  test/narrative_event_legacy_runtime_characterization_test.dart
00:02 +3: All tests passed!
```

Aucun code runtime production modifié.

## 27. Scope et Git final

`git diff --check` : vide.

Anti-scope :

```text
$ git diff --name-only -- \
  packages/map_editor/lib packages/map_runtime/lib packages/map_gameplay \
  packages/map_battle examples assets selbrume \
  "MVP Selbrume/selbrume.md" "MVP Selbrume/narrative_studio.md"
<empty>
```

Working tree final attendu et vérifié : modifications Phase D `map_core`, roadmap
et deux rapports seulement. Les commits concurrents sont déjà dans `HEAD`, pas
dans le diff de ce lot. Aucun `git add`, commit, push, merge, rebase, stash,
restore ou reset exécuté.

## 28. Reviews R1/R2/G

```text
D0-A R1 PASS / R2 PASS
D1   R1 PASS / R2 PASS
D2   R1 PASS / R2 PASS
D0-B R1 PASS / R2 PASS
D3   R1 PASS / R2 PASS
D4   R1 PASS / R2 PASS
G performance/compatibility : PASS après un BLOCKED corrigé
```

R1 : aucune source inexistante prête, aucun Fact/Event/outcome dangling prêt,
aucune réassignation silencieuse, receipt fermé, claims exacts, aucune position
dans l'identité.

R2 : labels humains, indisponibilité visible, Yarn via Scene, diagnostics avec
destination ou raison, aucune fausse action de réparation.

## 29. Risques résiduels

1. Full read model large JIT ~7.2 s ; cache immuable futur à étudier.
2. Baseline large : deux itérations seulement.
3. AOT non mesuré.
4. Outcome benchmark mono-producer massif.
5. Lookup navigation exclut construction de l'index.
6. Intents pas encore exécutés par Flutter.
7. Analyse globale editor rouge, dette Pokémon SDK hors scope.

## 30. Entry Gate Phase E

| Critère | Verdict |
|---|---|
| D0 global | PASS |
| receipt closed-world / duplicate keys | PASS |
| confirm vs reassignment | PASS |
| source/Scene/Fact/Event/outcome contextual validity | PASS |
| ready/canApply fort | PASS |
| spatial/outcome catalogs | PASS |
| unified truthful read model | PASS |
| valid claim dedup / tombstone visibility | PASS |
| navigation editor-neutral | PASS |
| diagnostics destination XOR reason | PASS |
| full core tests/analyze/build_runner | PASS |
| V1 editor/runtime compatibility | PASS ciblé |
| real migration / legacy writes | NONE |

```text
PHASE D : CLOSED / ACCEPTED
PHASE E : READY
```

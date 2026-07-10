# NS-EVENT-V2 — Phase B — Evidence Pack

## 1. Commit baseline

```text
61941c3955ca103eb8650ddbf8db06f33d563854
NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
```

## 2. Gate 0 exact

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git branch --show-current
main
$ git status --short --untracked-files=all
 M packages/map_editor/pubspec.lock
$ git diff --stat
 packages/map_editor/pubspec.lock | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)
$ git diff --name-only
packages/map_editor/pubspec.lock
```

```text
$ git log --oneline -n 30
61941c39 NS-EVENT-V2 PHASE A: Canonical Architecture Ratification
d26bfa9c NS-EVENT-RESET-00: Canonical Event Sources & Event Builder V2 Ultra Roadmap
56882754 NS-EVENT-41-bis: Truthful Stepper & Secondary Details Access Closure V0
ed91ca2c NS-EVENT-41: Event Builder Simplified Guided Configuration Layout V0
88314c22 NS-EVENT-40: Event Builder Shell-Level Pixel Polish & Real App Visual QA V0
89b81e47 NS-EVENT-39: Event Builder Reference UI Redesign / Flow-Based Layout V0
6fab98e4 NS-EVENT-38: Event Builder Map Placement & Post-Creation Guided Setup UX V0
c017dc8f NS-EVENT-37: Event Builder First Event Creation UX Simplification V0
786e86da NS-EVENT-36: Event Builder Real App Manual Creation Availability Fix / Layer Gate UX - PASS
fb440ae8 NS-EVENT-35: Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate - PARTIAL
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
```

```text
$ dart --version
Dart SDK version: 3.12.1 (stable) on "macos_arm64"
```

## 3. Fichiers et documents lus

- `AGENTS.md`, `codex_rule.md`, `skills/README.md`.
- Skills : executing plans, subagent-driven development, TDD,
  verification-before-completion, requesting code review.
- Ledger Phase A, roadmap V2, rapport Phase A, audit RESET-00.
- `ProjectManifest`, MapEvent, Scenario, Scene, Fact, World Rule, GameState,
  ScriptCondition, V1 Event Builder et leurs tests/serializers.
- Consumers de `ProjectManifest.fromJson` dans editor/runtime en lecture seule.

## 4. Symboles MCP Dart

Roots configurées : `map_core`, `map_editor`, `map_runtime`, `map_gameplay`.
Symboles inspectés : `ProjectManifest`, `ProjectVersion`, `MapEventDefinition`,
`MapEventPage`, `EventPosition`, `MapEventType`, `ScenarioAsset`, `SceneAsset`,
`NarrativeFactDefinition`, `WorldRuleDefinition`,
`NarrativeScenarioAuthoringSourceDraft`, `NarrativeEventSourcePickerOption`,
`GameState`, `ScriptCondition` et barrels publics.

Diagnostics MCP après B1/B2/B3/B4 :

```text
No errors
```

## 5. Dépendances avant/après

Avant : `freezed_annotation`, `json_annotation`, `meta` directs ; `crypto`
seulement transitif ; aucune dépendance UUID.

Après :

```yaml
environment:
  sdk: '>=3.4.0 <4.0.0'
dependencies:
  crypto: ^3.0.7
  uuid: ^4.5.3
```

Décision : `ACCEPTED`. `uuid 4.5.3` (MIT) couvre UUIDv7 ; `crypto 3.0.7`
(BSD-3-Clause) couvre SHA-256. JCS et égalité profonde restent locaux.

Hashes package :

```text
pubspec.yaml avant : c7dfc4b2c78141925b8721a7134affa8e99315c65abee72d3d8af9f8cd074fe0
pubspec.yaml après : fd53afced33a8b1fda9d17a5124d578d74acb1774fc39a0c374707815f86caa4
pubspec.lock avant : a2d7b044c201179abfea1e767e9bf9c86320025f4423ace505f3539eef5b0c29
pubspec.lock après : 5d6e53e21d3e41cd712302d1e1d2e7fc733c24670ee4eb783aa0a242a54c5bb1
```

Le lock `map_core` est ignoré par le repo mais contrôlé par hash.

## 6. Fichiers créés

```text
packages/map_core/lib/src/models/narrative_event_definition.dart
packages/map_core/lib/src/models/narrative_event_registry.dart
packages/map_core/lib/src/models/narrative_event_source_ref.dart
packages/map_core/lib/src/models/narrative_event_wire.dart
packages/map_core/lib/src/operations/narrative_event_canonical_json.dart
packages/map_core/lib/src/operations/narrative_event_claim_fingerprints.dart
packages/map_core/lib/src/operations/narrative_event_id_generator.dart
packages/map_core/lib/src/operations/narrative_event_record_operations.dart
packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
packages/map_core/lib/src/read_models/narrative_event_source_index.dart
packages/map_core/test/narrative_event_claim_fingerprints_test.dart
packages/map_core/test/narrative_event_definition_test.dart
packages/map_core/test/narrative_event_registry_codec_test.dart
packages/map_core/test/narrative_event_registry_test.dart
packages/map_core/test/narrative_event_source_index_test.dart
packages/map_core/test/narrative_event_source_ref_test.dart
reports/narrativeStudio/events/ns_event_v2_phase_b_domain_contracts_v0.md
reports/narrativeStudio/events/ns_event_v2_phase_b_evidence_pack.md
```

## 7. Fichiers modifiés

```text
MVP Selbrume/road_map_event_builder_v2.md
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/pubspec.yaml
```

Fichiers supprimés : aucun.

## 8. Generated files

```text
498a424b304b764b10633da200e1643883b79052680a60f0814aee1418df9674  packages/map_core/lib/src/models/project_manifest.freezed.dart
59e597d54d4aea130b7540b50c7393f75b135a9cf39a2f6b777f9ed0df7b24b9  packages/map_core/lib/src/models/project_manifest.g.dart
```

Justification : ajout du seul champ nullable `eventRegistry`. Aucun generated
hors `map_core`, aucun churn généré inexpliqué.

## 9. API publique exportée

```text
NarrativeEventSourceKind / NarrativeEventSourceRef
NarrativeOutcomeProducerKind / NarrativeOutcomeRef
NarrativeEventCondition / NarrativeEventReusePolicy
NarrativeEventDefinition / NarrativeEventDraft / NarrativeEventRecord
NarrativeEventIdGenerator
NarrativeEventRegistry / EventSystemMode
LegacySourceRef / LegacySourceClaimMember / LegacySourceClaim
EventRegistryDecodeResult / ValidatedLegacyClaimIndex
NarrativeEventSourceIndex / NarrativeEventSourceIndexBuildResult
NarrativeEventSourceConflict
```

Opérations exportées : publication/activation, canonical JSON, SHA-256,
fingerprints, registry decode/preflight, validated claim index et source index.

## 10. JSON goldens

```json
{"kind":"entityInteract","mapId":"map_port","entityId":"npc_lysa"}
{"kind":"triggerEnter","mapId":"map_port","triggerId":"zone_entry"}
{"kind":"mapEnter","mapId":"map_port"}
{"kind":"outcomeReceived","outcome":{"producerKind":"scene","producerId":"scene_lysa","outcomeId":"victory"}}
{"kind":"fact","factId":"rival_defeated","expectedValue":true}
{"kind":"narrativeEventConsumed","eventId":"evt_019abcde-0000-7000-8000-000000000001","expectedValue":false}
{"state":"draft","draft":{"id":"evt_019abcde-0000-7000-8000-000000000001","name":"Arrival","conditions":[],"priority":0,"order":3}}
{"schemaVersion":1,"mode":"legacyOnly","records":[],"legacyClaims":[]}
```

## 11. Vectors JCS et SHA-256

Couverture : ordre UTF-16 incluant non-BMP, strings/escaping, nombres et zéro
négatif, bool/null, arrays, nested objects, ordre Map invariant, UTF-8,
non-finite, surrogate isolé, clé non String, entier hors plage I-JSON et clés
JSON dupliquées dans le preflight.

```text
SHA-256 JCS({"a":1}) = 015abd7f5cc57a2dd94b7590f04ad8084273905ee33ec5cebeae62276a97f862
MapEvent source = sha256:6ea5956cc0973bd2b6ce93cef2ac703dd61035c6b530dac02f08610239b548db
Scenario source = sha256:e8e4b2a3a69a8b291f9e29497c94d054847d5474d2860bd86d9e90dba446a93e
cohortId = lsc_f33795b3ad4a0b7522087062de7b7fe3d0bfee38c2c8920172821baa13e4e6c5
cohortFingerprint = sha256:8e7c6e870ef25acf92eebf9f2641f198c2f2bd774920099b42f0e1bf16d14e9d
```

Preuves pré-gate : 200 000 bit patterns IEEE-754 identiques à Node ; six
fichiers du corpus JCS officiel identiques octet/hash.

## 12. Outputs build_runner

Premier gate complet :

```text
Built with build_runner in 17s; wrote 60 outputs.
```

Les outputs étaient des réécritures identiques ; aucun diff generated hors
ProjectManifest. Après ajout du manifest :

```text
Built with build_runner in 13s; wrote 12 outputs.
```

Stabilité finale :

```text
Built with build_runner in 5s; wrote 0 outputs.
Built with build_runner in 1s; wrote 0 outputs.
```

Warnings connus : analyzer language 3.9 < SDK 3.12 et contrainte historique
`json_annotation ^4.8.1`; aucun diagnostic `dart analyze`.

## 13. Outputs tests par jalon

```text
B1 targeted + regressions : 25 tests passed
B2 targeted : 20 tests passed
B2 cumulative : 80 tests passed
B3 targeted/contract suites : PASS
B3 cumulative + V1 regressions : 108 tests passed
B4 targeted final : 8 tests passed
Phase B six suites final : 57 tests passed
```

## 14. Output tests map_core complets

```text
$ dart test --reporter=compact
00:06 +2652: All tests passed!
exit=0
```

## 15. Output analyse

```text
$ dart analyze
Analyzing map_core...
No issues found!
exit=0
```

Format global historique :

```text
$ dart format --output=none --set-exit-if-changed lib test
Formatted 422 files (67 changed) in 1.95 seconds.
exit=1
```

Le mode `--output=none` n’a modifié aucun fichier. Check du scope Phase B :

```text
Formatted 19 files (0 changed) in 0.05 seconds.
exit=0
```

## 16. Performance baseline

```text
Dart: 3.12.1 (stable) on "macos_arm64"
OS: Version 27.0 (Build 26A5368g)
Records: 20001; sources: 1001
Build: 10 iterations in 258643 us; mean 25864.3 us
Lookup absent: 1000000 in 23295 us; 23.295 ns/op
Lookup single: 1000000 in 28329 us; 28.329 ns/op
Lookup multiple: 1000000 in 24894 us; 24.894 ns/op
Checksum: 21000000
```

Script temporaire : `/tmp/ns_event_v2_b4_benchmark.dart`, non ajouté au repo.

## 17. Reviews R1/R2

```text
B1 REVIEW R1: PASS
B1 REVIEW R2: PASS
B2 REVIEW R1: PASS
B2 REVIEW R2: PASS
B3 REVIEW R1: PASS
B3 REVIEW R2: PASS avec réserve Phase C
B4 REVIEW R1: PASS
B4 REVIEW R2: PASS
```

Corrections issues des reviews : classification cross-variant, preuve
dépendance/drift, safe integers JCS, duplicate JSON keys, lookup structurel,
ordre multi-conflicts, immutabilité profonde et conditions non évaluées.

## 18. Annexes hash des fichiers manuscrits créés

Ces hashes remplacent la recopie de milliers de lignes et permettent de
vérifier exactement les contenus créés :

```text
f6aab3018596b71b96a914b8dc7177c5d1b4dbaea0882cbe01e3ebf23637f7f1  packages/map_core/lib/src/models/narrative_event_definition.dart
4a07f39a6e7b3742b3e950ba9cde64ce36ef32b4af97a2ed32cd9ec615ea224b  packages/map_core/lib/src/models/narrative_event_registry.dart
1ac1fb8c00ae8f31aab06f88f5fbd820afecb80c46a2fab0b440342cd2bceac1  packages/map_core/lib/src/models/narrative_event_source_ref.dart
92f910518e5b83fd4f88d7b661f4f03f5ce995c80af7b6ec2267d27e793ca0b7  packages/map_core/lib/src/models/narrative_event_wire.dart
dc65a0f23d61434c6572b5efd132f32c6b7f4cc4675dcbe068ac341da24cd982  packages/map_core/lib/src/operations/narrative_event_canonical_json.dart
0966aa03aa4bbe3fbc58c9d8d7eab1ac5dbe6b7b67e1701ea0c3861ead2bf7a9  packages/map_core/lib/src/operations/narrative_event_claim_fingerprints.dart
771d521de2da077439ea6bcf49d787711d3258f40e561c7fe93bcd1cf46a10d8  packages/map_core/lib/src/operations/narrative_event_id_generator.dart
9decae1e9fdec5b41cbafe41435b1d191bf9ba81f64995e02625460abbaf2293  packages/map_core/lib/src/operations/narrative_event_record_operations.dart
53f24dc87301064fb512bfb0afb2bd2f4a41cf70aa7bb459c33d61e0b9906ab3  packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
8c819104bf5525ebe3c46788940f4a3d4077972e538d61b9180aae2db19d94a7  packages/map_core/lib/src/read_models/narrative_event_source_index.dart
3455a35eb2a098e450e33effd6f2a01e5083aa98d99dd59a677a0de27b60c79e  packages/map_core/test/narrative_event_claim_fingerprints_test.dart
ee9657c7e645829e3c3f098dda8a3a2048711f3eac135f6c41dc4e9a4711a735  packages/map_core/test/narrative_event_definition_test.dart
af7c7cdffce7d7cd8ad211e837cd5ba12b60c70c1c29e9f3b87821142e702cb5  packages/map_core/test/narrative_event_registry_codec_test.dart
3cb295c709560ee30a9674bf29e2bbded1983bd3ab1e4dd46fc3b8a4b8b91083  packages/map_core/test/narrative_event_registry_test.dart
e15d22642989155a5800bae1d676f1cb4a1969aff8324aad5c4669e9f07be7b4  packages/map_core/test/narrative_event_source_index_test.dart
8907bbd6e25f7231e3e658622b5fdc30b457786e83d8bf877c39dbfddafe2488  packages/map_core/test/narrative_event_source_ref_test.dart
0c7b6a96b0dc9fcd73ef0d7dd06c341d4fa724919e27318ad4e2a2c3c06739e1  reports/narrativeStudio/events/ns_event_v2_phase_b_domain_contracts_v0.md
```

L’Evidence Pack ne peut pas contenir son propre hash sans récursion ; son hash
est fourni par le commit Git final.

## 19. Gate Git final avant commit

Le snapshot exact est inséré après la dernière vérification, avant staging.

```text
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
 M packages/map_core/pubspec.yaml
 M packages/map_editor/pubspec.lock
?? packages/map_core/lib/src/models/narrative_event_definition.dart
?? packages/map_core/lib/src/models/narrative_event_registry.dart
?? packages/map_core/lib/src/models/narrative_event_source_ref.dart
?? packages/map_core/lib/src/models/narrative_event_wire.dart
?? packages/map_core/lib/src/operations/narrative_event_canonical_json.dart
?? packages/map_core/lib/src/operations/narrative_event_claim_fingerprints.dart
?? packages/map_core/lib/src/operations/narrative_event_id_generator.dart
?? packages/map_core/lib/src/operations/narrative_event_record_operations.dart
?? packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
?? packages/map_core/lib/src/read_models/narrative_event_source_index.dart
?? packages/map_core/test/narrative_event_claim_fingerprints_test.dart
?? packages/map_core/test/narrative_event_definition_test.dart
?? packages/map_core/test/narrative_event_registry_codec_test.dart
?? packages/map_core/test/narrative_event_registry_test.dart
?? packages/map_core/test/narrative_event_source_index_test.dart
?? packages/map_core/test/narrative_event_source_ref_test.dart
?? reports/narrativeStudio/events/ns_event_v2_phase_b_domain_contracts_v0.md
?? reports/narrativeStudio/events/ns_event_v2_phase_b_evidence_pack.md
```

```text
 MVP Selbrume/road_map_event_builder_v2.md          | 39 +++++++++++++++++-----
 packages/map_core/lib/map_core.dart                |  9 +++++
 .../map_core/lib/src/models/project_manifest.dart  |  2 ++
 .../lib/src/models/project_manifest.freezed.dart   | 29 +++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  5 +++
 .../narrative_reference_picker_read_models.dart    | 12 +++----
 packages/map_core/pubspec.yaml                     |  4 ++-
 packages/map_editor/pubspec.lock                   | 16 ++++-----
 8 files changed, 91 insertions(+), 25 deletions(-)
```

```text
MVP Selbrume/road_map_event_builder_v2.md
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/pubspec.yaml
packages/map_editor/pubspec.lock
```

```text
$ git diff --check
<empty>
```

## 20. Anti-scope

Commande :

```text
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume "MVP Selbrume/selbrume.md" "MVP Selbrume/narrative_studio.md" pubspec.yaml
```

Résultat attendu/final : uniquement le drift préexistant
`packages/map_editor/pubspec.lock`, strictement identique au Gate 0.

```text
hash fichier avant/après : 2fac1583a9d5864cd3bc13f2aa7a0831274bfe0fde7380782ff68d0820e90ac6
hash diff avant/après : 6b33cb8d5361c91b2aa9c8e3fcfebc99a8c3f64c4a822ff8ca55b2097d075511
```

## 21. Inventaire des risques

- Adoption du preflight par les repositories editor/runtime reportée à Phase C.
- Validation corpus réelle et receipts reportés à Phase C.
- Éligibilité stateful et dispatch reportés à F1/F2.
- Baseline de format global Dart 3.12 hors conformité historique ; scope Phase B
  propre et aucun churn accepté.
- Aucun projet réel migré, aucun runtime consumer et aucune UI dépendante.

## 22. Entry Gate Phase C

```text
PHASE B = CLOSED
R1 = PASS
R2 = PASS
map_core full tests = PASS
dart analyze = PASS
build_runner stability = PASS
PHASE C = READY
```

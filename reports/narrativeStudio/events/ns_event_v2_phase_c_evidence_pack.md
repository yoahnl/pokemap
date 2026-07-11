# NS-EVENT-V2 — Phase C — Evidence Pack

## 1. Baseline

```text
HEAD : fdaf4e5ddfb82981353c104c89377f061b207e2e
fdaf4e5d NS-EVENT-V2 PHASE B: Canonical Domain Contracts & Structural Source Index
branch : main
workspace : /Users/karim/Project/pokemonProject
```

Documents d'autorité lus : `AGENTS.md`, `codex_rule.md`, prompt Phase C,
roadmap Event Builder V2, ADR Phase A, rapports Phase A/B et Evidence Pack B.

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
$ git log --oneline -n 20
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
```

## 3. Toolchains

```text
Dart SDK version: 3.12.1 stable, macos_arm64
Flutter 3.46.0-0.3.pre, channel beta
Flutter framework revision: 677d472756
Flutter engine revision: a24b1ea55d
Flutter tool Dart: 3.13.0 beta
```

Verdict : `DART SDK BASELINE : ACCEPTED`.

## 4. Drifts préexistants et concurrents

`packages/map_editor/pubspec.lock` :

```text
hash fichier Gate 0 = 2fac1583a9d5864cd3bc13f2aa7a0831274bfe0fde7380782ff68d0820e90ac6
hash fichier final  = 2fac1583a9d5864cd3bc13f2aa7a0831274bfe0fde7380782ff68d0820e90ac6
hash diff Gate 0    = 6b33cb8d5361c91b2aa9c8e3fcfebc99a8c3f64c4a822ff8ca55b2097d075511
hash diff final     = 6b33cb8d5361c91b2aa9c8e3fcfebc99a8c3f64c4a822ff8ca55b2097d075511
```

Fichier concurrent apparu après Gate 0, non touché :

```text
selbrume/assets/GENERATED_ASSET_PROMPTS.md
size = 28313
mtime = 2026-07-11T16:02:12+0200
sha256 = 14368fe66106dd1d317c3412f113e4075110b1212ad6de43a5545695dc7bc422
```

Erreurs globales editor préexistantes :

```text
pokemon_sdk_move_catalog_converter.dart
worktree = HEAD = 2e6904472b50b3e0e7005db3384bb057b575a93ba0346bd91e57715af9de4c2d

sync_pokemon_sdk_moves_catalog_use_case.dart
worktree = HEAD = 5af7196b9038cf4538923714e1b217d6403eaa7354def146c8184dc52138f714
```

## 5. MCP Dart

Roots : `map_core`, `map_editor`, `map_runtime`.

Symboles inspectés : `NarrativeEventRegistry`, `NarrativeEventRecord`,
`ValidatedLegacyClaimIndex`, `LegacySourceRef`, `MapEventDefinition`,
`ScenarioAsset`, `SceneAsset`, `ProjectManifest`, opérations Scenario editor,
source index, claim fingerprints et Scene runtime plan builder.

Résultat final :

```text
No errors
```

## 6. Sous-agents et incidents

| Passe | Mission | Verdict |
|---|---|---|
| A | Audit architecture / C0 | PASS |
| B | Corpus / runtime characterization | PASS |
| C | Adapter MapEvent | PASS |
| D | Adapter Scenario / authoring guard | PASS |
| E | Planner / mappings / receipt | PASS après corrections |
| F | Tests / analyze / build | PASS avec dette globale editor documentée |
| G | Scope / non-destruction | PASS |
| H | Evidence / roadmap | PASS |
| R1 | Review contradictoire | PASS final |
| R2 | Review contradictoire | PASS final |

Incidents : réponses service `Bad Request`, limites temporaires de threads et
une dérive worker temporaire `map_gameplay`, retirée avant validation. Aucun
résultat agent n'a remplacé une preuve locale. R1/R2 finaux n'ont édité aucun
fichier.

## 7. Fichiers créés

Production / contrats :

```text
packages/map_core/lib/src/compatibility/legacy_event_migration_models.dart
packages/map_core/lib/src/compatibility/legacy_map_event_projection.dart
packages/map_core/lib/src/compatibility/legacy_scenario_source_projection.dart
packages/map_core/lib/src/compatibility/narrative_event_migration_plan.dart
packages/map_core/lib/src/compatibility/narrative_event_migration_planner.dart
packages/map_core/lib/src/compatibility/narrative_event_migration_receipt.dart
packages/map_core/lib/src/compatibility/narrative_event_reference_mapping.dart
```

Fixtures / outils :

```text
packages/map_core/test/fixtures/narrative_event_jcs/README.md
packages/map_core/test/fixtures/narrative_event_jcs/official/input/*.json
packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/*.txt
packages/map_core/test/fixtures/narrative_event_jcs/vectors.json
packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json
packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.sha256
packages/map_core/tool/verify_narrative_event_jcs_number_oracle.dart
packages/map_core/tool/verify_narrative_event_jcs_number_oracle.mjs
packages/map_core/tool/verify_narrative_event_jcs_vectors.dart
```

Tests :

```text
packages/map_core/test/legacy_map_event_projection_test.dart
packages/map_core/test/legacy_scenario_source_projection_test.dart
packages/map_core/test/narrative_event_legacy_corpus_test.dart
packages/map_core/test/narrative_event_migration_planner_test.dart
packages/map_core/test/narrative_event_migration_receipt_test.dart
packages/map_core/test/narrative_event_reference_mapping_test.dart
packages/map_editor/test/scenario_authoring_claim_guard_test.dart
packages/map_runtime/test/narrative_event_legacy_runtime_characterization_test.dart
```

Rapports :

```text
reports/narrativeStudio/events/ns_event_v2_phase_c_legacy_compatibility_migration_v0.md
reports/narrativeStudio/events/ns_event_v2_phase_c_evidence_pack.md
```

## 8. Fichiers modifiés et zones

| Fichier | Zones | Raison / impact |
|---|---|---|
| `MVP Selbrume/road_map_event_builder_v2.md` | statuts Phase C/D, V2-05..08 | clôture factuelle et Gate D |
| `packages/map_core/lib/map_core.dart` | exports compatibility | API Phase C publique |
| `narrative_event_definition.dart` | factory structurally unchecked | borne Phase E explicite |
| `narrative_event_canonical_json.dart` | nombres/strings/JCS strict | reproductibilité RFC 8785 |
| `narrative_event_record_operations.dart` | noms opérations structurelles | pas de publish/activate trompeur |
| `narrative_event_registry_codec.dart` | decode lexical/strict | duplicates et raw subtree fail-closed |
| `narrative_event_claim_fingerprints_test.dart` | lookup/hashes/JCS | C0/C1 regressions |
| `narrative_event_definition_test.dart` | opérations structurelles | ownership Phase E |
| `narrative_event_registry_codec_test.dart` | decode négatif | données inconnues/dupliquées |
| `narrative_event_registry_test.dart` | index provenance/tombstone | claim closure |
| `narrative_event_source_index_test.dart` | API renommée | régression compilation |
| `project_scenario_use_cases.dart` | guards create/update/delete | freeze Scenario claimé |

Fichiers supprimés : aucun.

## 9. Corpus C1

```text
corpus_v0.json SHA-256 = 6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c
stored SHA-256         = 6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c
maps=2 MapEvents=13 Scenarios=11 Scenes=4 cases=24 references=12
AUTO_SAFE=4 ASSISTED=2 BLOCKED=13 LEGACY_ONLY=3 UNSUPPORTED=2
```

Le corpus couvre actor/object/trigger, position seule, map-enter, outcome,
first-valid multi-page, scripts/messages, metadata, saves, conditions, World
Rules, conséquences, IDs collisionnés et cohortes.

## 10. Reference graph

Domaines : progression, condition, worldRule, consequence, save.

Kinds contrôlés : consumed state, ScriptCondition, WorldRule source/target,
SceneConsequence, Scenario binding, script command, metadata, validator et
save. Le path est unique dans le catalogue. Le catalogue doit égaler le corpus
sur kind/path/raw ID/map/candidats.

Policy : aucun premier match; fan-out par stable target key; tous les targets
uniquement pour progression/save; choix stale ou absent bloquant.

## 11. Outputs adapters

MapEvent : projection read-only avec provenance, fingerprint, source evidence,
pages, preserved JSON, references, diagnostics et classification. La position
seule n'est jamais une identité.

Scenario : projection read-only du Scenario complet, source node, Scene
candidate, lifecycle, graph complexity, conditions/actions et preserved JSON.
La preuve Scene est rejouée contre les assets courants et compare la trace
observable.

## 12. Claims source/provenance

- `validBySource` et `validByProvenance` résolvent le même claim/cohorte.
- Les maps invalides conservent tombstones et provenances.
- Cross-claim conflicts rendent l'index inutilisable.
- Un claim doit couvrir exactement tous les membres et targets.
- Les claims orphelins, partiels ou stales bloquent.
- Les mappings de chaque membre sont un sous-ensemble du claim; leur union est
  exactement le claim.

## 13. JCS vectors

```text
Verified 4 canonical vectors 6 official corpus pairs, 24 number vectors,
12 rejection vectors, 2 Phase B hashes, and 2 claim vectors.
```

```text
Verified 200000 deterministic IEEE-754 values against Node;
checksum b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57.
```

Le pack officiel indique sa provenance upstream. Aucun réseau n'est requis.

## 14. Planner / receipt evidence

Preuves couvertes : plan vide, AUTO_SAFE, ASSISTED, BLOCKED, UNSUPPORTED,
multi-page, IDs injectés, deterministic output, zero-ID fail-closed, stale
revision/hash, unknown data, exact receipt reuse, records désactivés, Scene
revalidation, duplicate Scenario/Scene IDs, per-provenance mappings, stable
key fan-out replay, incremental history block, backup/rollback/PONR et receipt
malformé.

Le golden receipt canonique est dans
`test/narrative_event_migration_receipt_test.dart`. Le planner ne possède aucun
filesystem handle et ne fait aucun write.

## 15. Tests ciblés

```text
C0: +47 All tests passed!
C1: +19 All tests passed!
C2: +20 All tests passed!
C3: +19 All tests passed!
C4: +88 All tests passed!
map_editor guard + regressions: +8 All tests passed!
map_runtime characterization: +3 All tests passed!
```

Commande C4 exacte :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/narrative_event_migration_planner_test.dart \
  test/narrative_event_reference_mapping_test.dart \
  test/narrative_event_migration_receipt_test.dart \
  test/legacy_map_event_projection_test.dart \
  test/legacy_scenario_source_projection_test.dart
```

## 16. Suite complète

```text
$ cd packages/map_core && dart test --reporter=compact
+2755: All tests passed!
$ dart analyze
No issues found!
```

## 17. Analyses editor/runtime

```text
map_editor targeted analyze: No issues found!
map_runtime targeted analyze: No issues found!
map_runtime dart analyze: exit 0, 349 info issues historiques
```

Global editor exécuté :

```text
flutter analyze --no-fatal-infos
438 issues found; exit 1
81 error diagnostics, tous dans deux fichiers Pokemon SDK inchangés
```

Ce résultat n'est pas vert et n'est pas revendiqué comme tel.

## 18. Format / build_runner / build

```text
dart format --output=none --set-exit-if-changed <25 fichiers Dart Phase C>
Formatted 25 files (0 changed)
```

Une première tentative d'agrégation zsh avait transmis tous les chemins comme
un argument unique. Elle a été explicitement corrigée avec `xargs`; la preuve
ci-dessus est le gate valide.

```text
build_runner pass 1: wrote 0 outputs
build_runner pass 2: wrote 0 outputs
generated files changed: none
```

```text
flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## 19. Reviews finales

```text
C0 REVIEW R1 : PASS
C0 REVIEW R2 : PASS
C1 REVIEW R1 : PASS
C1 REVIEW R2 : PASS
C2 REVIEW R1 : PASS
C2 REVIEW R2 : PASS
C3 REVIEW R1 : PASS
C3 REVIEW R2 : PASS
C4 REVIEW R1 : PASS
C4 REVIEW R2 : PASS
```

Les derniers outputs C4 : R1 `No findings`, R2 `No findings`, aucun fichier
édité par les reviewers.

## 20. Anti-scope

Attendu et vérifié vide :

```bash
git diff --name-only -- \
  packages/map_gameplay packages/map_battle examples assets selbrume \
  "MVP Selbrume/selbrume.md" "MVP Selbrume/narrative_studio.md"

git diff --name-only -- packages/map_runtime/lib
```

Aucun runtime V2, dual-read, GameState, gameplay, battle, Scene execution,
projet Selbrume, migration réelle, backup réel ou write filesystem.

## 21. Risques

- receipt history incrémental non modélisé : bloque explicitement;
- ASSISTED requiert un choix initial;
- write/apply/cutover restent Phase E+;
- dette analyzer globale Pokemon SDK hors lot;
- aucune preuve de migration réelle, volontairement.

Data loss risk : `NONE` dans Phase C, car aucun write n'existe.

## 22. Entry Gate Phase D

```text
Phase B remains valid : YES
Claim lookup source + provenance : PASS
Dart SDK baseline : ACCEPTED
JCS reproducible : PASS
Legacy corpus frozen : PASS
MapEvent adapter read-only : PASS
Scenario adapter read-only : PASS
Claimed Scenario authoring guard : PASS
Planner pure/deterministic/idempotent : PASS
Claims/reference graph complete : PASS
Legacy data modified : NO
Real project migrated : NO
Reviews without blocker : PASS
Phase D : READY au périmètre Phase C
```

Réserve : analyse globale editor préexistante rouge, avec hashes HEAD égaux.

## 23. Gate final

```text
$ git status --short --untracked-files=all
 M "MVP Selbrume/road_map_event_builder_v2.md"
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/narrative_event_definition.dart
 M packages/map_core/lib/src/operations/narrative_event_canonical_json.dart
 M packages/map_core/lib/src/operations/narrative_event_record_operations.dart
 M packages/map_core/lib/src/operations/narrative_event_registry_codec.dart
 M packages/map_core/test/narrative_event_claim_fingerprints_test.dart
 M packages/map_core/test/narrative_event_definition_test.dart
 M packages/map_core/test/narrative_event_registry_codec_test.dart
 M packages/map_core/test/narrative_event_registry_test.dart
 M packages/map_core/test/narrative_event_source_index_test.dart
 M packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
 M packages/map_editor/pubspec.lock
?? packages/map_core/lib/src/compatibility/*
?? packages/map_core/test/fixtures/narrative_event_jcs/*
?? packages/map_core/test/fixtures/narrative_event_legacy_corpus/*
?? packages/map_core/test/legacy_map_event_projection_test.dart
?? packages/map_core/test/legacy_scenario_source_projection_test.dart
?? packages/map_core/test/narrative_event_legacy_corpus_test.dart
?? packages/map_core/test/narrative_event_migration_planner_test.dart
?? packages/map_core/test/narrative_event_migration_receipt_test.dart
?? packages/map_core/test/narrative_event_reference_mapping_test.dart
?? packages/map_core/tool/verify_narrative_event_jcs_number_oracle.dart
?? packages/map_core/tool/verify_narrative_event_jcs_number_oracle.mjs
?? packages/map_core/tool/verify_narrative_event_jcs_vectors.dart
?? packages/map_editor/test/scenario_authoring_claim_guard_test.dart
?? packages/map_runtime/test/narrative_event_legacy_runtime_characterization_test.dart
?? reports/narrativeStudio/events/ns_event_v2_phase_c_evidence_pack.md
?? reports/narrativeStudio/events/ns_event_v2_phase_c_legacy_compatibility_migration_v0.md
?? selbrume/assets/GENERATED_ASSET_PROMPTS.md
```

Le listing compact avec `*` ci-dessus représente les fichiers détaillés en
section 7 et dans l'annexe; la sortie terminal exhaustive a été vérifiée.

```text
$ git diff --stat
13 files changed, 702 insertions(+), 201 deletions(-)
$ git diff --name-only
13 fichiers trackés listés ci-dessus
$ git diff --check
<empty>
$ git diff --name-only -- packages/map_gameplay packages/map_battle examples assets selbrume ...
<empty>
$ git diff --name-only -- packages/map_runtime/lib
<empty>
```

Le stat Git n'inclut pas les fichiers untracked; leur contenu complet et leurs
hashes figurent dans l'annexe. Aucun fichier n'a été stage, commit ou push.

## 24. Contenu complet des fichiers créés

Conformément à `codex_rule.md`, l'annexe suivante reproduit le contenu complet
des fichiers créés de production, fixtures, outils et tests. Les deux rapports
ne s'auto-imbriquent pas; leur contenu canonique est le présent fichier et le
rapport principal voisin.

### `packages/map_core/lib/src/compatibility/legacy_event_migration_models.dart`

SHA-256: `d6c76e533bd6281ff720a47c0d676206dda000ce90d70df93690a2b831be0818` — 93 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';

enum LegacyMigrationClassification {
  autoSafe,
  assisted,
  blocked,
  unsupported,
  legacyOnly,
}

enum LegacyProjectionClaimStatus { absent, valid, invalid }

enum LegacyMigrationDiagnosticSeverity { info, warning, error }

enum LegacyEventReferenceKind {
  consumedEventState,
  scriptCondition,
  worldRuleSource,
  worldRuleTarget,
  sceneConsequence,
  scenarioNodeBinding,
  scriptCommand,
  metadata,
  validatorDiagnostic,
}

@immutable
final class LegacyMigrationDiagnostic {
  LegacyMigrationDiagnostic({
    required String code,
    required this.severity,
    required String message,
    required String path,
  })  : code = _nonEmpty(code, 'code'),
        message = _nonEmpty(message, 'message'),
        path = _nonEmpty(path, 'path');

  final String code;
  final LegacyMigrationDiagnosticSeverity severity;
  final String message;
  final String path;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'path': path,
      };
}

@immutable
final class LegacyEventReference {
  LegacyEventReference({
    required this.kind,
    required String path,
    required String legacyEventId,
    String? mapId,
    required List<LegacySourceRef> candidateProvenances,
  })  : path = _nonEmpty(path, 'path'),
        legacyEventId = _nonEmpty(legacyEventId, 'legacyEventId'),
        mapId = _optionalNonEmpty(mapId, 'mapId'),
        candidateProvenances = List.unmodifiable(candidateProvenances);

  final LegacyEventReferenceKind kind;
  final String path;
  final String legacyEventId;
  final String? mapId;
  final List<LegacySourceRef> candidateProvenances;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'path': path,
        'legacyEventId': legacyEventId,
        if (mapId != null) 'mapId': mapId,
        'candidateProvenances': [
          for (final provenance in candidateProvenances) provenance.toJson(),
        ],
      };
}

String _nonEmpty(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalNonEmpty(String? value, String name) {
  if (value == null) return null;
  return _nonEmpty(value, name);
}
````

</details>

### `packages/map_core/lib/src/compatibility/legacy_map_event_projection.dart`

SHA-256: `46c2da598f3b0569c46753adde7be56136fc8d21bceecdd77942d0591ccc58f6` — 880 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/script_conditions.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import 'legacy_event_migration_models.dart';

abstract final class LegacyMapEventCompatibilityMetadataKeys {
  static const entityId = 'eventV2.source.entityId';
  static const triggerId = 'eventV2.source.triggerId';
}

abstract final class LegacyMapEventDiagnosticCodes {
  static const mapIdentityMismatch = 'mapIdentityMismatch';
  static const eventMissingFromMap = 'eventMissingFromMap';
  static const layerMissing = 'layerMissing';
  static const positionOutOfBounds = 'positionOutOfBounds';
  static const explicitSourceConflict = 'explicitSourceConflict';
  static const explicitSourceMissing = 'explicitSourceMissing';
  static const positionIsOnlyEvidence = 'positionIsOnlyEvidence';
  static const ambiguousPositionCandidates = 'ambiguousPositionCandidates';
  static const standaloneMapEvent = 'standaloneMapEvent';
  static const effectUnsupported = 'effectUnsupported';
  static const multiplePages = 'multiplePages';
  static const noPages = 'noPages';
  static const missingSceneTarget = 'missingSceneTarget';
  static const opaqueScript = 'opaqueScript';
  static const legacyMessage = 'legacyMessage';
  static const conditionNeedsReview = 'conditionNeedsReview';
  static const pageStateNeedsReview = 'pageStateNeedsReview';
  static const unknownRawData = 'unknownRawData';
  static const invalidClaim = 'invalidClaim';
  static const claimFingerprintStale = 'claimFingerprintStale';
  static const claimSourceMismatch = 'claimSourceMismatch';
  static const globalClaimConflict = 'globalClaimConflict';
  static const ambiguousLinkedReference = 'ambiguousLinkedReference';
  static const unresolvedLinkedReference = 'unresolvedLinkedReference';
  static const legacySprite = 'legacySprite';
  static const triggerRuntimeParityUnproven = 'triggerRuntimeParityUnproven';
}

enum LegacyMapEventSourceEvidenceKind {
  explicitMetadata,
  exactUniqueFootprint,
  ambiguousFootprint,
}

@immutable
final class LegacyMapEventSourceCandidate {
  LegacyMapEventSourceCandidate({
    required this.source,
    required this.evidence,
    required this.confirmed,
    required String reason,
  }) : reason = _requireText(reason, 'reason');

  final NarrativeEventSourceRef source;
  final LegacyMapEventSourceEvidenceKind evidence;
  final bool confirmed;
  final String reason;

  Map<String, Object?> toJson() => {
        'source': source.toJson(),
        'evidence': evidence.name,
        'confirmed': confirmed,
        'reason': reason,
      };
}

@immutable
final class LegacyMapEventPageProjection {
  LegacyMapEventPageProjection({
    required this.pageIndex,
    required this.pageNumber,
    required this.condition,
    required this.script,
    required this.spriteId,
    required this.message,
    required this.sceneId,
    required this.isHidden,
    required this.isDisabled,
    required Map<String, String> metadata,
  }) : metadata = Map.unmodifiable(metadata);

  final int pageIndex;
  final int pageNumber;
  final ScriptCondition? condition;
  final ScriptRef? script;
  final String? spriteId;
  final String? message;
  final String? sceneId;
  final bool isHidden;
  final bool isDisabled;
  final Map<String, String> metadata;

  Map<String, Object?> toJson() => {
        'pageIndex': pageIndex,
        'pageNumber': pageNumber,
        if (condition != null) 'condition': condition!.toJson(),
        if (script != null) 'script': script!.toJson(),
        if (spriteId != null) 'spriteId': spriteId,
        if (message != null) 'message': message,
        if (sceneId != null) 'sceneId': sceneId,
        'isHidden': isHidden,
        'isDisabled': isDisabled,
        'metadata': metadata,
      };
}

@immutable
final class LegacyMapEventProjection {
  LegacyMapEventProjection({
    required this.provenance,
    required this.classification,
    required this.claimStatus,
    required this.existingClaim,
    required this.sourceFingerprint,
    required List<LegacyMapEventSourceCandidate> sourceCandidates,
    required List<LegacyMapEventPageProjection> pages,
    required Map<String, Object?> preservedEventJson,
    required List<String> unconvertibleDataPaths,
    required List<LegacyEventReference> linkedReferences,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required List<String> manualActions,
  })  : sourceCandidates = List.unmodifiable(sourceCandidates),
        pages = List.unmodifiable(pages),
        preservedEventJson = _freezeObject(_normalizeJson(preservedEventJson)),
        unconvertibleDataPaths = List.unmodifiable(unconvertibleDataPaths),
        linkedReferences = List.unmodifiable(linkedReferences),
        diagnostics = List.unmodifiable(diagnostics),
        manualActions = List.unmodifiable(manualActions);

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final LegacyProjectionClaimStatus claimStatus;
  final LegacySourceClaim? existingClaim;
  final String sourceFingerprint;
  final List<LegacyMapEventSourceCandidate> sourceCandidates;
  final List<LegacyMapEventPageProjection> pages;
  final Map<String, Object?> preservedEventJson;
  final List<String> unconvertibleDataPaths;
  final List<LegacyEventReference> linkedReferences;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final List<String> manualActions;

  NarrativeEventSourceRef? get confirmedSource {
    for (final candidate in sourceCandidates) {
      if (candidate.confirmed) return candidate.source;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'classification': classification.name,
        'claimStatus': claimStatus.name,
        if (existingClaim != null) 'existingClaim': existingClaim!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'sourceCandidates': [
          for (final candidate in sourceCandidates) candidate.toJson(),
        ],
        if (confirmedSource != null)
          'confirmedSource': confirmedSource!.toJson(),
        'pages': [for (final page in pages) page.toJson()],
        'preservedEventJson': preservedEventJson,
        'unconvertibleDataPaths': unconvertibleDataPaths,
        'linkedReferences': [
          for (final reference in linkedReferences) reference.toJson(),
        ],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'manualActions': manualActions,
      };
}

LegacyMapEventProjection projectLegacyMapEventReadOnly({
  required String mapId,
  required MapData map,
  required MapEventDefinition event,
  required ValidatedLegacyClaimIndex claimIndex,
  List<LegacyEventReference> linkedReferences = const [],
  Map<String, Object?>? rawEventJson,
}) {
  final provenance = LegacySourceRef.mapEvent(mapId, event.id);
  var classification = LegacyMigrationClassification.autoSafe;
  final diagnostics = <LegacyMigrationDiagnostic>[];
  final manualActions = <String>[];
  final unconvertible = <String>[];
  final candidates = <LegacyMapEventSourceCandidate>[];

  void escalate(LegacyMigrationClassification next) {
    if (_classificationRank(next) > _classificationRank(classification)) {
      classification = next;
    }
  }

  void diagnose(
    String code,
    LegacyMigrationDiagnosticSeverity severity,
    String message,
    String path,
  ) {
    diagnostics.add(
      LegacyMigrationDiagnostic(
        code: code,
        severity: severity,
        message: message,
        path: path,
      ),
    );
  }

  if (map.id != mapId) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.mapIdentityMismatch,
      LegacyMigrationDiagnosticSeverity.error,
      'The supplied map context does not match the qualified mapId.',
      'mapId',
    );
  }
  if (!map.events.any((candidate) => candidate.id == event.id)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.eventMissingFromMap,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent is absent from the supplied map snapshot.',
      'event.id',
    );
  }
  if (!map.layers.any((layer) => layer.id == event.position.layerId)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.layerMissing,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent references a layer that does not exist.',
      'event.position.layerId',
    );
  }
  if (event.position.x < 0 ||
      event.position.y < 0 ||
      event.position.x >= map.size.width ||
      event.position.y >= map.size.height) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.positionOutOfBounds,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent position lies outside the map bounds.',
      'event.position',
    );
  }

  _collectSourceCandidates(
    mapId: mapId,
    map: map,
    event: event,
    candidates: candidates,
    escalate: escalate,
    diagnose: diagnose,
    manualActions: manualActions,
  );

  if (event.type == MapEventType.effect) {
    escalate(LegacyMigrationClassification.unsupported);
    unconvertible.add('type');
    diagnose(
      LegacyMapEventDiagnosticCodes.effectUnsupported,
      LegacyMigrationDiagnosticSeverity.error,
      'MapEvent effects have no Event V2 V0 source contract.',
      'event.type',
    );
  }

  final pages = <LegacyMapEventPageProjection>[];
  for (var index = 0; index < event.pages.length; index++) {
    final page = event.pages[index];
    pages.add(
      LegacyMapEventPageProjection(
        pageIndex: index,
        pageNumber: page.pageNumber,
        condition: page.condition,
        script: page.script,
        spriteId: page.spriteId,
        message: page.message,
        sceneId: page.sceneTarget?.sceneId,
        isHidden: page.isHidden,
        isDisabled: page.isDisabled,
        metadata: page.metadata,
      ),
    );
    if (page.script != null) {
      escalate(LegacyMigrationClassification.unsupported);
      unconvertible.add('pages[$index].script');
      diagnose(
        LegacyMapEventDiagnosticCodes.opaqueScript,
        LegacyMigrationDiagnosticSeverity.error,
        'Opaque legacy scripts cannot be converted by the V0 adapter.',
        'event.pages[$index].script',
      );
    }
    if ((page.spriteId ?? '').trim().isNotEmpty) {
      escalate(LegacyMigrationClassification.assisted);
      unconvertible.add('pages[$index].spriteId');
      manualActions.add(
        'Confirm how sprite ${page.spriteId} maps to the selected source.',
      );
      diagnose(
        LegacyMapEventDiagnosticCodes.legacySprite,
        LegacyMigrationDiagnosticSeverity.warning,
        'Legacy sprite ownership must be resolved on the selected map source.',
        'event.pages[$index].spriteId',
      );
    }
    if ((page.message ?? '').trim().isNotEmpty) {
      escalate(LegacyMigrationClassification.unsupported);
      unconvertible.add('pages[$index].message');
      diagnose(
        LegacyMapEventDiagnosticCodes.legacyMessage,
        LegacyMigrationDiagnosticSeverity.error,
        'Legacy page messages require an explicit Scene conversion.',
        'event.pages[$index].message',
      );
    }
    if ((page.sceneTarget?.sceneId ?? '').trim().isEmpty) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose a Scene for page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.missingSceneTarget,
        LegacyMigrationDiagnosticSeverity.error,
        'The page has no stable Scene target.',
        'event.pages[$index].sceneTarget',
      );
    }
    if (page.condition != null) {
      escalate(LegacyMigrationClassification.assisted);
      manualActions.add('Review the condition on page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.conditionNeedsReview,
        LegacyMigrationDiagnosticSeverity.warning,
        'The legacy condition must be mapped explicitly.',
        'event.pages[$index].condition',
      );
    }
    if (page.isHidden || page.isDisabled) {
      escalate(LegacyMigrationClassification.assisted);
      manualActions
          .add('Review hidden/disabled state on page ${page.pageNumber}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.pageStateNeedsReview,
        LegacyMigrationDiagnosticSeverity.warning,
        'Hidden and disabled page state is preserved but not inferred.',
        'event.pages[$index]',
      );
    }
  }
  if (event.pages.isEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.noPages,
      LegacyMigrationDiagnosticSeverity.error,
      'The MapEvent has no page to characterize.',
      'event.pages',
    );
  } else if (event.pages.length > 1) {
    escalate(LegacyMigrationClassification.blocked);
    manualActions
        .add('Map each legacy page without changing first-valid order.');
    diagnose(
      LegacyMapEventDiagnosticCodes.multiplePages,
      LegacyMigrationDiagnosticSeverity.error,
      'Multi-page MapEvents cannot be flattened automatically.',
      'event.pages',
    );
  }

  final normalizedRaw = _normalizeJson(rawEventJson ?? event.toJson());
  final preservedEventJson = _freezeObject(normalizedRaw);
  final unknownPaths = _unknownRawPaths(normalizedRaw);
  if (unknownPaths.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    unconvertible.addAll(unknownPaths);
    for (final path in unknownPaths) {
      diagnose(
        LegacyMapEventDiagnosticCodes.unknownRawData,
        LegacyMigrationDiagnosticSeverity.error,
        'Unknown legacy JSON is preserved and blocks automatic conversion.',
        path,
      );
    }
  }

  for (final reference in linkedReferences) {
    if (reference.legacyEventId != event.id ||
        reference.candidateProvenances.isEmpty ||
        (reference.candidateProvenances.length == 1 &&
            reference.candidateProvenances.single != provenance)) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Resolve reference ${reference.path} explicitly.');
      diagnose(
        LegacyMapEventDiagnosticCodes.unresolvedLinkedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'A linked legacy reference does not resolve to this provenance.',
        reference.path,
      );
    } else if (reference.candidateProvenances.length > 1) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose targets for reference ${reference.path}.');
      diagnose(
        LegacyMapEventDiagnosticCodes.ambiguousLinkedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'A bare legacy reference resolves to several provenances.',
        reference.path,
      );
    }
  }

  final currentFingerprint = computeMapEventSourceFingerprint(
    mapId: mapId,
    event: event,
  );
  final indexedValidClaim = claimIndex.validByProvenance[provenance];
  final invalidClaimDiagnostics = claimIndex.invalidByProvenance[provenance];
  var contextualValidClaim = indexedValidClaim;
  var contextualClaimInvalid = invalidClaimDiagnostics != null;
  if (indexedValidClaim != null) {
    final members = indexedValidClaim.members
        .where((member) => member.provenance == provenance)
        .toList();
    if (members.length != 1 ||
        members.single.sourceFingerprint != currentFingerprint) {
      contextualValidClaim = null;
      contextualClaimInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyMapEventDiagnosticCodes.claimFingerprintStale,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim fingerprint no longer matches the complete MapEvent.',
        'claim.members',
      );
    }
    NarrativeEventSourceRef? confirmedSource;
    for (final candidate in candidates) {
      if (candidate.confirmed) {
        confirmedSource = candidate.source;
        break;
      }
    }
    if (confirmedSource != null &&
        indexedValidClaim.source != confirmedSource) {
      contextualValidClaim = null;
      contextualClaimInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyMapEventDiagnosticCodes.claimSourceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim source contradicts the explicitly confirmed source.',
        'claim.source',
      );
    }
  }
  final claimStatus = contextualValidClaim != null
      ? LegacyProjectionClaimStatus.valid
      : contextualClaimInvalid
          ? LegacyProjectionClaimStatus.invalid
          : LegacyProjectionClaimStatus.absent;
  if (invalidClaimDiagnostics != null) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.invalidClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'This provenance is covered by an invalid or tombstone claim.',
      'claimIndex.invalidByProvenance',
    );
  }
  if (claimIndex.globalConflicts.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.globalClaimConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'The claim index contains a global conflict.',
      'claimIndex.globalConflicts',
    );
  }

  return LegacyMapEventProjection(
    provenance: provenance,
    classification: classification,
    claimStatus: claimStatus,
    existingClaim: contextualValidClaim,
    sourceFingerprint: currentFingerprint,
    sourceCandidates: candidates,
    pages: pages,
    preservedEventJson: preservedEventJson,
    unconvertibleDataPaths: unconvertible,
    linkedReferences: linkedReferences,
    diagnostics: diagnostics,
    manualActions: manualActions,
  );
}

void _collectSourceCandidates({
  required String mapId,
  required MapData map,
  required MapEventDefinition event,
  required List<LegacyMapEventSourceCandidate> candidates,
  required void Function(LegacyMigrationClassification) escalate,
  required void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  required List<String> manualActions,
}) {
  final hasEntityKey = event.metadata
      .containsKey(LegacyMapEventCompatibilityMetadataKeys.entityId);
  final hasTriggerKey = event.metadata
      .containsKey(LegacyMapEventCompatibilityMetadataKeys.triggerId);
  final entityId =
      event.metadata[LegacyMapEventCompatibilityMetadataKeys.entityId];
  final triggerId =
      event.metadata[LegacyMapEventCompatibilityMetadataKeys.triggerId];
  final expectsEntity =
      event.type == MapEventType.actor || event.type == MapEventType.object;
  final expectsTrigger = event.type == MapEventType.triggerZone;

  if ((hasEntityKey && hasTriggerKey) ||
      (expectsEntity && hasTriggerKey) ||
      (expectsTrigger && hasEntityKey)) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyMapEventDiagnosticCodes.explicitSourceConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'Explicit source metadata conflicts with the MapEvent type.',
      'event.metadata',
    );
    return;
  }

  if (expectsEntity && hasEntityKey) {
    final matches =
        map.entities.where((entity) => entity.id == entityId).toList();
    if (entityId == null ||
        entityId.isEmpty ||
        entityId.trim() != entityId ||
        matches.length != 1) {
      _explicitSourceMissing(escalate, diagnose, 'entityId');
      return;
    }
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'Stable entityId is encoded in legacy metadata.',
      ),
    );
    return;
  }
  if (expectsTrigger && hasTriggerKey) {
    final matches =
        map.triggers.where((trigger) => trigger.id == triggerId).toList();
    if (triggerId == null ||
        triggerId.isEmpty ||
        triggerId.trim() != triggerId ||
        matches.length != 1) {
      _explicitSourceMissing(escalate, diagnose, 'triggerId');
      return;
    }
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: NarrativeEventSourceRef.triggerEnter(mapId, triggerId),
        evidence: LegacyMapEventSourceEvidenceKind.explicitMetadata,
        confirmed: true,
        reason: 'Stable triggerId is encoded in legacy metadata.',
      ),
    );
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven,
      LegacyMigrationDiagnosticSeverity.warning,
      'Legacy triggerZone runtime parity is not proven in Phase C.',
      'event.type',
    );
    return;
  }

  if (event.type == MapEventType.effect) return;
  if (expectsEntity) {
    final matches = map.entities
        .where((entity) => _entityContains(entity, event.position))
        .toList();
    _addFootprintCandidates(
      matches.map(
        (entity) => NarrativeEventSourceRef.entityInteract(mapId, entity.id),
      ),
      candidates: candidates,
      escalate: escalate,
      diagnose: diagnose,
      manualActions: manualActions,
    );
    return;
  }
  final matches = map.triggers
      .where((trigger) => _triggerContains(trigger, event.position))
      .toList();
  _addFootprintCandidates(
    matches.map(
      (trigger) => NarrativeEventSourceRef.triggerEnter(mapId, trigger.id),
    ),
    candidates: candidates,
    escalate: escalate,
    diagnose: diagnose,
    manualActions: manualActions,
  );
  if (matches.length == 1) {
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven,
      LegacyMigrationDiagnosticSeverity.warning,
      'Legacy triggerZone runtime parity is not proven in Phase C.',
      'event.type',
    );
  }
}

void _explicitSourceMissing(
  void Function(LegacyMigrationClassification) escalate,
  void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  String field,
) {
  escalate(LegacyMigrationClassification.blocked);
  diagnose(
    LegacyMapEventDiagnosticCodes.explicitSourceMissing,
    LegacyMigrationDiagnosticSeverity.error,
    'The explicit source metadata does not resolve exactly once.',
    'event.metadata.$field',
  );
}

void _addFootprintCandidates(
  Iterable<NarrativeEventSourceRef> sources, {
  required List<LegacyMapEventSourceCandidate> candidates,
  required void Function(LegacyMigrationClassification) escalate,
  required void Function(
    String,
    LegacyMigrationDiagnosticSeverity,
    String,
    String,
  ) diagnose,
  required List<String> manualActions,
}) {
  final values = sources.toList();
  if (values.isEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Choose or materialize an explicit Event source.');
    diagnose(
      LegacyMapEventDiagnosticCodes.standaloneMapEvent,
      LegacyMigrationDiagnosticSeverity.error,
      'No compatible source owns this MapEvent position.',
      'event.position',
    );
    return;
  }
  final evidence = values.length == 1
      ? LegacyMapEventSourceEvidenceKind.exactUniqueFootprint
      : LegacyMapEventSourceEvidenceKind.ambiguousFootprint;
  for (final source in values) {
    candidates.add(
      LegacyMapEventSourceCandidate(
        source: source,
        evidence: evidence,
        confirmed: false,
        reason: values.length == 1
            ? 'One compatible source shares the exact footprint.'
            : 'Several compatible sources share the exact footprint.',
      ),
    );
  }
  if (values.length == 1) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add('Confirm the proposed source explicitly.');
    diagnose(
      LegacyMapEventDiagnosticCodes.positionIsOnlyEvidence,
      LegacyMigrationDiagnosticSeverity.warning,
      'Position is a migration hint, not source identity.',
      'event.position',
    );
  } else {
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Choose one source explicitly or cancel conversion.');
    diagnose(
      LegacyMapEventDiagnosticCodes.ambiguousPositionCandidates,
      LegacyMigrationDiagnosticSeverity.error,
      'Several source candidates share the MapEvent footprint.',
      'event.position',
    );
  }
}

bool _entityContains(MapEntity entity, EventPosition position) {
  return position.x >= entity.pos.x &&
      position.y >= entity.pos.y &&
      position.x < entity.pos.x + entity.size.width &&
      position.y < entity.pos.y + entity.size.height;
}

bool _triggerContains(MapTrigger trigger, EventPosition position) {
  return position.x >= trigger.area.pos.x &&
      position.y >= trigger.area.pos.y &&
      position.x < trigger.area.pos.x + trigger.area.size.width &&
      position.y < trigger.area.pos.y + trigger.area.size.height;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

Map<String, Object?> _normalizeJson(Map<String, Object?> value) {
  return Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
}

Map<String, Object?> _freezeObject(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freezeJson(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  return value;
}

List<String> _unknownRawPaths(Map<String, Object?> raw) {
  const eventFields = {'id', 'title', 'pages', 'position', 'type', 'metadata'};
  const pageFields = {
    'pageNumber',
    'condition',
    'script',
    'spriteId',
    'message',
    'sceneTarget',
    'isHidden',
    'isDisabled',
    'metadata',
  };
  const positionFields = {'layerId', 'x', 'y'};
  const sceneTargetFields = {'sceneId'};
  const scriptFields = {'scriptId', 'startNode'};
  const conditionFields = {'type', 'params', 'children'};
  final result = <String>{};
  _collectUnknownObjectKeys(raw, eventFields, 'event', result);
  _inspectKnownObject(
      raw['position'], positionFields, 'event.position', result);
  final pages = raw['pages'];
  if (pages is List) {
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final path = 'event.pages[$index]';
      if (page is! Map) {
        result.add(path);
        continue;
      }
      _collectUnknownObjectKeys(page, pageFields, path, result);
      _inspectKnownObject(
        page['sceneTarget'],
        sceneTargetFields,
        '$path.sceneTarget',
        result,
        optional: true,
      );
      _inspectKnownObject(
        page['script'],
        scriptFields,
        '$path.script',
        result,
        optional: true,
      );
      _inspectConditionJson(
        page['condition'],
        '$path.condition',
        conditionFields,
        result,
      );
    }
  } else {
    result.add('event.pages');
  }
  final sorted = result.toList()..sort();
  return sorted;
}

void _inspectKnownObject(
  Object? value,
  Set<String> knownFields,
  String path,
  Set<String> result, {
  bool optional = false,
}) {
  if (value == null && optional) return;
  if (value is! Map) {
    result.add(path);
    return;
  }
  _collectUnknownObjectKeys(value, knownFields, path, result);
}

void _inspectConditionJson(
  Object? value,
  String path,
  Set<String> knownFields,
  Set<String> result,
) {
  if (value == null) return;
  if (value is! Map) {
    result.add(path);
    return;
  }
  _collectUnknownObjectKeys(value, knownFields, path, result);
  final children = value['children'];
  if (children == null) return;
  if (children is! List) {
    result.add('$path.children');
    return;
  }
  for (var index = 0; index < children.length; index++) {
    _inspectConditionJson(
      children[index],
      '$path.children[$index]',
      knownFields,
      result,
    );
  }
}

void _collectUnknownObjectKeys(
  Map value,
  Set<String> knownFields,
  String path,
  Set<String> result,
) {
  for (final key in value.keys) {
    if (key is! String || !knownFields.contains(key)) {
      result.add('$path.$key');
    }
  }
}

String _requireText(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
````

</details>

### `packages/map_core/lib/src/compatibility/legacy_scenario_source_projection.dart`

SHA-256: `42e6fa123799a5efdef5fec680079098ec0711d839acde15e971fda1db2d29f4` — 890 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/script_conditions.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'legacy_event_migration_models.dart';

abstract final class LegacyScenarioDiagnosticCodes {
  static const nodeMissing = 'nodeMissing';
  static const nodeSnapshotMismatch = 'nodeSnapshotMismatch';
  static const malformedSource = 'malformedSource';
  static const outcomeQualificationRequired = 'outcomeQualificationRequired';
  static const lifecycleEvidenceMissing = 'lifecycleEvidenceMissing';
  static const multipleSources = 'multipleSources';
  static const graphOrchestrationPreserved = 'graphOrchestrationPreserved';
  static const unsupportedChoice = 'unsupportedChoice';
  static const sceneCandidateMissing = 'sceneCandidateMissing';
  static const sceneNotBuildable = 'sceneNotBuildable';
  static const sceneTraceMismatch = 'sceneTraceMismatch';
  static const invalidClaim = 'invalidClaim';
  static const claimFingerprintStale = 'claimFingerprintStale';
  static const claimSourceMismatch = 'claimSourceMismatch';
  static const globalClaimConflict = 'globalClaimConflict';
}

enum LegacyScenarioGraphComplexity {
  simpleLinear,
  multipleSources,
  branchingOrOrchestrated,
  malformed,
}

enum LegacyScenarioLifecycleEvidence { reusable, oneShot, ambiguous }

@immutable
final class LegacyScenarioActionProjection {
  LegacyScenarioActionProjection({
    required String nodeId,
    required this.nodeType,
    required String actionKind,
  })  : nodeId = _requireText(nodeId, 'nodeId'),
        actionKind = _requireText(actionKind, 'actionKind');

  final String nodeId;
  final ScenarioNodeType nodeType;
  final String actionKind;

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'nodeType': nodeType.name,
        'actionKind': actionKind,
      };
}

@immutable
final class LegacyScenarioSourceProjection {
  LegacyScenarioSourceProjection({
    required String scenarioId,
    required String nodeId,
    required this.provenance,
    required this.source,
    required this.sceneCandidateId,
    required this.lifecycleEvidence,
    required this.reusePolicyCandidate,
    required this.graphComplexity,
    required this.classification,
    required this.claimStatus,
    required this.existingClaim,
    required String sourceFingerprint,
    required List<LegacyScenarioActionProjection> actions,
    required List<ScriptCondition> conditions,
    required Map<String, Object?> preservedScenarioJson,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required List<String> manualActions,
  })  : scenarioId = _requireText(scenarioId, 'scenarioId'),
        nodeId = _requireText(nodeId, 'nodeId'),
        sourceFingerprint = _requireText(
          sourceFingerprint,
          'sourceFingerprint',
        ),
        actions = List.unmodifiable(actions),
        conditions = List.unmodifiable(conditions),
        preservedScenarioJson = _freezeObject(
          _normalizeJson(preservedScenarioJson),
        ),
        diagnostics = List.unmodifiable(diagnostics),
        manualActions = List.unmodifiable(manualActions);

  final String scenarioId;
  final String nodeId;
  final LegacySourceRef provenance;
  final NarrativeEventSourceRef? source;
  final String? sceneCandidateId;
  final LegacyScenarioLifecycleEvidence lifecycleEvidence;
  final NarrativeEventReusePolicy? reusePolicyCandidate;
  final LegacyScenarioGraphComplexity graphComplexity;
  final LegacyMigrationClassification classification;
  final LegacyProjectionClaimStatus claimStatus;
  final LegacySourceClaim? existingClaim;
  final String sourceFingerprint;
  final List<LegacyScenarioActionProjection> actions;
  final List<ScriptCondition> conditions;
  final Map<String, Object?> preservedScenarioJson;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final List<String> manualActions;

  Map<String, Object?> toJson() => {
        'scenarioId': scenarioId,
        'nodeId': nodeId,
        'provenance': provenance.toJson(),
        if (source != null) 'source': source!.toJson(),
        if (sceneCandidateId != null) 'sceneCandidateId': sceneCandidateId,
        'lifecycleEvidence': lifecycleEvidence.name,
        if (reusePolicyCandidate != null)
          'reusePolicyCandidate': reusePolicyCandidate!.name,
        'graphComplexity': graphComplexity.name,
        'classification': classification.name,
        'claimStatus': claimStatus.name,
        if (existingClaim != null) 'existingClaim': existingClaim!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'actions': [for (final action in actions) action.toJson()],
        'conditions': [
          for (final condition in conditions) condition.toJson(),
        ],
        'preservedScenarioJson': preservedScenarioJson,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'manualActions': manualActions,
      };
}

LegacyScenarioSourceProjection projectLegacyScenarioSourceReadOnly({
  required ScenarioAsset scenario,
  required ScenarioNode node,
  required List<SceneAsset> scenes,
  required ValidatedLegacyClaimIndex claimIndex,
  LegacyScenarioLifecycleEvidence lifecycleEvidence =
      LegacyScenarioLifecycleEvidence.ambiguous,
}) {
  final requestedNodeId = node.id;
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    requestedNodeId,
  );
  var classification = LegacyMigrationClassification.autoSafe;
  var complexity = LegacyScenarioGraphComplexity.simpleLinear;
  final diagnostics = <LegacyMigrationDiagnostic>[];
  final manualActions = <String>[];
  final reusePolicyCandidate = switch (lifecycleEvidence) {
    LegacyScenarioLifecycleEvidence.reusable =>
      NarrativeEventReusePolicy.reusable,
    LegacyScenarioLifecycleEvidence.oneShot =>
      NarrativeEventReusePolicy.oneShot,
    LegacyScenarioLifecycleEvidence.ambiguous => null,
  };

  void escalate(LegacyMigrationClassification next) {
    if (_classificationRank(next) > _classificationRank(classification)) {
      classification = next;
    }
  }

  void diagnose(
    String code,
    LegacyMigrationDiagnosticSeverity severity,
    String message,
    String path,
  ) {
    diagnostics.add(
      LegacyMigrationDiagnostic(
        code: code,
        severity: severity,
        message: message,
        path: path,
      ),
    );
  }

  if (lifecycleEvidence == LegacyScenarioLifecycleEvidence.ambiguous) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add('Confirm whether this Scenario is reusable or one-shot.');
    diagnose(
      LegacyScenarioDiagnosticCodes.lifecycleEvidenceMissing,
      LegacyMigrationDiagnosticSeverity.warning,
      'Project-level lifecycle references have not been qualified.',
      'scenario.lifecycle',
    );
  }

  final actualNodes = scenario.nodes
      .where((candidate) => candidate.id == requestedNodeId)
      .toList(growable: false);
  final hasCanonicalNode = actualNodes.length == 1;
  var effectiveNode = node;
  if (!hasCanonicalNode) {
    complexity = LegacyScenarioGraphComplexity.malformed;
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.nodeMissing,
      LegacyMigrationDiagnosticSeverity.error,
      'The source node is absent from the complete ScenarioAsset.',
      'scenario.nodes',
    );
  } else {
    effectiveNode = actualNodes.single;
    if (effectiveNode != node) {
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.nodeSnapshotMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The supplied node snapshot differs from the complete ScenarioAsset.',
        'scenario.nodes.$requestedNodeId',
      );
    }
  }

  final isUnqualifiedOutcome = hasCanonicalNode &&
      effectiveNode.type == ScenarioNodeType.reference &&
      effectiveNode.payload.actionKind == 'sourceOutcome' &&
      _exact(effectiveNode.binding.outcomeId);
  final source = hasCanonicalNode ? _readScenarioSource(effectiveNode) : null;
  if (source == null && !isUnqualifiedOutcome) {
    complexity = LegacyScenarioGraphComplexity.malformed;
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.malformedSource,
      LegacyMigrationDiagnosticSeverity.error,
      'The legacy source binding is incomplete or non-exact.',
      'scenario.nodes.$requestedNodeId.binding',
    );
  } else if (isUnqualifiedOutcome) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add(
      'Choose the producer that qualifies this legacy outcome.',
    );
    diagnose(
      LegacyScenarioDiagnosticCodes.outcomeQualificationRequired,
      LegacyMigrationDiagnosticSeverity.warning,
      'A legacy outcomeId does not identify its producer.',
      'scenario.nodes.$requestedNodeId.binding.outcomeId',
    );
  }

  final sourceNodes = scenario.nodes.where(_isScenarioSourceNode).toList();
  final hasChoice = scenario.nodes.any(
    (candidate) => candidate.type == ScenarioNodeType.choice,
  );
  final isSimple =
      hasCanonicalNode && _isSimpleLinearScenario(scenario, effectiveNode);
  if (sourceNodes.length > 1) {
    complexity = LegacyScenarioGraphComplexity.multipleSources;
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Review and claim every source node in this Scenario.');
    diagnose(
      LegacyScenarioDiagnosticCodes.multipleSources,
      LegacyMigrationDiagnosticSeverity.error,
      'A multi-source Scenario cannot be projected as one Event silently.',
      'scenario.nodes',
    );
  } else if (hasChoice) {
    complexity = LegacyScenarioGraphComplexity.branchingOrOrchestrated;
    escalate(LegacyMigrationClassification.unsupported);
    diagnose(
      LegacyScenarioDiagnosticCodes.unsupportedChoice,
      LegacyMigrationDiagnosticSeverity.error,
      'Choice orchestration remains outside Event V2 V0.',
      'scenario.nodes',
    );
  } else if (!isSimple &&
      complexity != LegacyScenarioGraphComplexity.malformed) {
    complexity = LegacyScenarioGraphComplexity.branchingOrOrchestrated;
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyScenarioDiagnosticCodes.graphOrchestrationPreserved,
      LegacyMigrationDiagnosticSeverity.warning,
      'The complete Scenario graph remains legacy orchestration.',
      'scenario',
    );
  }

  String? sceneCandidateId;
  if (isSimple &&
      (source != null || isUnqualifiedOutcome) &&
      sourceNodes.length == 1) {
    final rawSceneId = effectiveNode.metadata['eventV2.sceneId'];
    if (rawSceneId == null ||
        rawSceneId.isEmpty ||
        rawSceneId.trim() != rawSceneId) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose an explicit Scene for this source.');
      diagnose(
        LegacyScenarioDiagnosticCodes.sceneCandidateMissing,
        LegacyMigrationDiagnosticSeverity.error,
        'No exact Scene candidate is encoded for this source node.',
        'scenario.nodes.$requestedNodeId.metadata.eventV2.sceneId',
      );
    } else {
      final matches = scenes.where((scene) => scene.id == rawSceneId).toList();
      if (matches.length != 1) {
        escalate(LegacyMigrationClassification.blocked);
        diagnose(
          LegacyScenarioDiagnosticCodes.sceneCandidateMissing,
          LegacyMigrationDiagnosticSeverity.error,
          'The encoded Scene candidate does not resolve exactly once.',
          'scenario.nodes.$requestedNodeId.metadata.eventV2.sceneId',
        );
      } else {
        final scene = matches.single;
        final plan = buildSceneRuntimePlan(scene);
        if (!plan.canBuild) {
          escalate(LegacyMigrationClassification.blocked);
          diagnose(
            LegacyScenarioDiagnosticCodes.sceneNotBuildable,
            LegacyMigrationDiagnosticSeverity.error,
            'The Scene candidate cannot produce a runtime plan.',
            'scenes.${scene.id}',
          );
        } else if (!_sameObservableTrace(
          scenario,
          requestedNodeId,
          scene,
        )) {
          escalate(LegacyMigrationClassification.blocked);
          diagnose(
            LegacyScenarioDiagnosticCodes.sceneTraceMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'Scenario and Scene observable traces are not equivalent.',
            'scenes.${scene.id}',
          );
        } else {
          sceneCandidateId = scene.id;
        }
      }
    }
  }

  final sourceFingerprint = computeScenarioSourceFingerprint(
    scenarioId: scenario.id,
    nodeId: requestedNodeId,
    scenario: scenario,
  );
  final indexedClaim = claimIndex.validByProvenance[provenance];
  final indexedInvalid = claimIndex.invalidByProvenance[provenance];
  var contextualClaim = indexedClaim;
  var contextualInvalid = indexedInvalid != null;
  if (indexedClaim != null) {
    final members = indexedClaim.members
        .where((member) => member.provenance == provenance)
        .toList();
    if (members.length != 1 ||
        members.single.sourceFingerprint != sourceFingerprint) {
      contextualClaim = null;
      contextualInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.claimFingerprintStale,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim no longer matches the complete ScenarioAsset fingerprint.',
        'claim.members',
      );
    }
    final claimSourceMatches = source != null
        ? indexedClaim.source == source
        : isUnqualifiedOutcome
            ? _claimMatchesUnqualifiedOutcome(
                indexedClaim,
                effectiveNode.binding.outcomeId!,
              )
            : true;
    if (!claimSourceMatches) {
      contextualClaim = null;
      contextualInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.claimSourceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim source contradicts the projected Scenario source.',
        'claim.source',
      );
    }
  }
  if (indexedInvalid != null) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.invalidClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'This source node is covered by an invalid or tombstone claim.',
      'claimIndex.invalidByProvenance',
    );
  }
  if (claimIndex.globalConflicts.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.globalClaimConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'The claim index contains a global conflict.',
      'claimIndex.globalConflicts',
    );
  }
  final claimStatus = contextualClaim != null
      ? LegacyProjectionClaimStatus.valid
      : contextualInvalid
          ? LegacyProjectionClaimStatus.invalid
          : LegacyProjectionClaimStatus.absent;

  final conditions = <ScriptCondition>[
    if (scenario.activationCondition != null) scenario.activationCondition!,
    for (final candidate in scenario.nodes)
      if (candidate.payload.condition != null) candidate.payload.condition!,
  ];
  final actions = <LegacyScenarioActionProjection>[
    for (final candidate in scenario.nodes)
      if (candidate.type == ScenarioNodeType.action ||
          candidate.type == ScenarioNodeType.dialogue)
        LegacyScenarioActionProjection(
          nodeId: candidate.id,
          nodeType: candidate.type,
          actionKind: candidate.type == ScenarioNodeType.dialogue
              ? 'dialogue:${candidate.binding.dialogueId ?? ''}'
              : candidate.payload.actionKind ?? 'action:unknown',
        ),
  ];

  return LegacyScenarioSourceProjection(
    scenarioId: scenario.id,
    nodeId: requestedNodeId,
    provenance: provenance,
    source: source,
    sceneCandidateId: sceneCandidateId,
    lifecycleEvidence: lifecycleEvidence,
    reusePolicyCandidate: reusePolicyCandidate,
    graphComplexity: complexity,
    classification: classification,
    claimStatus: claimStatus,
    existingClaim: contextualClaim,
    sourceFingerprint: sourceFingerprint,
    actions: actions,
    conditions: conditions,
    preservedScenarioJson: Map<String, Object?>.from(
      jsonDecode(jsonEncode(scenario.toJson())) as Map,
    ),
    diagnostics: diagnostics,
    manualActions: manualActions,
  );
}

bool _claimMatchesUnqualifiedOutcome(
  LegacySourceClaim claim,
  String outcomeId,
) {
  return claim.source.when(
    entityInteract: (_, __) => false,
    triggerEnter: (_, __) => false,
    mapEnter: (_) => false,
    outcomeReceived: (outcome) => outcome.outcomeId == outcomeId,
  );
}

@immutable
final class ScenarioAuthoringClaimGuardResult {
  ScenarioAuthoringClaimGuardResult({
    required this.blocked,
    required this.message,
    required List<LegacySourceRef> claimedProvenances,
    required List<NarrativeEventSourceRef> conflictingSources,
  })  : claimedProvenances = List.unmodifiable(claimedProvenances),
        conflictingSources = List.unmodifiable(conflictingSources);

  final bool blocked;
  final String? message;
  final List<LegacySourceRef> claimedProvenances;
  final List<NarrativeEventSourceRef> conflictingSources;
}

ScenarioAuthoringClaimGuardResult evaluateScenarioAuthoringClaimGuard({
  required ValidatedLegacyClaimIndex claimIndex,
  ScenarioAsset? existingScenario,
  ScenarioAsset? proposedScenario,
}) {
  if (existingScenario == null && proposedScenario == null) {
    throw ArgumentError('An existing or proposed Scenario is required.');
  }
  final claimedProvenanceKeys = <LegacySourceRef>{
    ...claimIndex.validByProvenance.keys,
    ...claimIndex.invalidByProvenance.keys,
  };
  final claimedProvenances = <LegacySourceRef>[];
  if (existingScenario != null) {
    for (final provenance in claimedProvenanceKeys) {
      if (_belongsToScenario(provenance, existingScenario.id)) {
        claimedProvenances.add(provenance);
      }
    }
  }
  if (proposedScenario != null &&
      (existingScenario == null ||
          existingScenario.id != proposedScenario.id)) {
    for (final provenance in claimedProvenanceKeys) {
      if (_belongsToScenario(provenance, proposedScenario.id) &&
          !claimedProvenances.contains(provenance)) {
        claimedProvenances.add(provenance);
      }
    }
  }
  final claimedSources = <NarrativeEventSourceRef>{
    ...claimIndex.validBySource.keys,
    ...claimIndex.invalidBySource.keys,
  };
  final conflictingSources = <NarrativeEventSourceRef>{};
  for (final source in claimedSources) {
    final existingMatches = existingScenario == null
        ? 0
        : _scenarioSourceMatchCount(existingScenario, source);
    final proposedMatches = proposedScenario == null
        ? 0
        : _scenarioSourceMatchCount(proposedScenario, source);
    if (existingMatches > 0 || proposedMatches > 0) {
      conflictingSources.add(source);
    }
  }
  final blocked = claimedProvenances.isNotEmpty ||
      conflictingSources.isNotEmpty ||
      claimIndex.globalConflicts.isNotEmpty;
  return ScenarioAuthoringClaimGuardResult(
    blocked: blocked,
    message: blocked
        ? 'Cette source est gérée par Event Builder V2. '
            'Ouvrez les événements liés ou retirez explicitement la migration.'
        : null,
    claimedProvenances: claimedProvenances,
    conflictingSources: conflictingSources.toList(growable: false),
  );
}

bool _belongsToScenario(LegacySourceRef provenance, String scenarioId) {
  return provenance.when(
    mapEvent: (_, __) => false,
    scenarioSourceNode: (candidateScenarioId, _) =>
        candidateScenarioId == scenarioId,
  );
}

int _scenarioSourceMatchCount(
  ScenarioAsset scenario,
  NarrativeEventSourceRef source,
) {
  return scenario.nodes
      .where((node) => _legacyScenarioNodeMayMatchSource(node, source))
      .length;
}

bool _legacyScenarioNodeMayMatchSource(
  ScenarioNode node,
  NarrativeEventSourceRef source,
) {
  if (node.type != ScenarioNodeType.reference) return false;
  final actionKind = node.payload.actionKind?.trim() ?? '';
  final bindingMapId = node.binding.mapId?.trim() ?? '';
  return source.when(
    entityInteract: (mapId, entityId) =>
        actionKind == 'sourceEntityInteract' &&
        (bindingMapId.isEmpty || bindingMapId == mapId) &&
        node.binding.entityId?.trim() == entityId,
    triggerEnter: (mapId, triggerId) =>
        actionKind == 'sourceTriggerEnter' &&
        (bindingMapId.isEmpty || bindingMapId == mapId) &&
        node.binding.triggerId?.trim() == triggerId,
    mapEnter: (mapId) =>
        actionKind == 'sourceMapEnter' &&
        (bindingMapId.isEmpty || bindingMapId == mapId),
    outcomeReceived: (outcome) =>
        actionKind == 'sourceOutcome' &&
        node.binding.outcomeId?.trim() == outcome.outcomeId,
  );
}

NarrativeEventSourceRef? _readScenarioSource(ScenarioNode node) {
  if (node.type != ScenarioNodeType.reference) return null;
  final binding = node.binding;
  return switch (node.payload.actionKind) {
    'sourceMapEnter' when _exact(binding.mapId) =>
      NarrativeEventSourceRef.mapEnter(binding.mapId!),
    'sourceTriggerEnter'
        when _exact(binding.mapId) && _exact(binding.triggerId) =>
      NarrativeEventSourceRef.triggerEnter(
        binding.mapId!,
        binding.triggerId!,
      ),
    'sourceEntityInteract'
        when _exact(binding.mapId) && _exact(binding.entityId) =>
      NarrativeEventSourceRef.entityInteract(
        binding.mapId!,
        binding.entityId!,
      ),
    _ => null,
  };
}

bool _isScenarioSourceNode(ScenarioNode node) {
  return node.type == ScenarioNodeType.reference &&
      const {
        'sourceMapEnter',
        'sourceTriggerEnter',
        'sourceEntityInteract',
        'sourceOutcome',
      }.contains(node.payload.actionKind);
}

bool _isSimpleLinearScenario(ScenarioAsset scenario, ScenarioNode source) {
  if (scenario.activationCondition != null ||
      scenario.declaredOutcomes.isNotEmpty ||
      scenario.nodes.length != 3 ||
      scenario.edges.length != 2 ||
      !_hasOnlySourceSemantics(source)) {
    return false;
  }
  final sourceEdges =
      scenario.edges.where((edge) => edge.fromNodeId == source.id).toList();
  if (sourceEdges.length != 1 ||
      sourceEdges.single.kind != ScenarioEdgeKind.next) {
    return false;
  }
  final dialogue = scenario.nodes.where(
    (node) =>
        node.id == sourceEdges.single.toNodeId &&
        node.type == ScenarioNodeType.dialogue &&
        _hasOnlyDialogueSemantics(node),
  );
  if (dialogue.length != 1) return false;
  final dialogueEdges = scenario.edges
      .where((edge) => edge.fromNodeId == dialogue.single.id)
      .toList();
  if (dialogueEdges.length != 1 ||
      dialogueEdges.single.kind != ScenarioEdgeKind.next) {
    return false;
  }
  final hasEnd = scenario.nodes.any(
    (node) =>
        node.id == dialogueEdges.single.toNodeId &&
        node.type == ScenarioNodeType.end &&
        _hasOnlyEndSemantics(node),
  );
  return hasEnd &&
      scenario.edges.every(
        (edge) =>
            edge.kind == ScenarioEdgeKind.next &&
            edge.label.isEmpty &&
            edge.metadata.isEmpty,
      );
}

bool _hasOnlySourceSemantics(ScenarioNode node) {
  if (!_isScenarioSourceNode(node) ||
      node.type != ScenarioNodeType.reference ||
      node.payload.message != null ||
      node.payload.condition != null ||
      node.payload.choiceLabels.isNotEmpty ||
      node.payload.params.isNotEmpty ||
      node.metadata.keys.any((key) => key != 'eventV2.sceneId')) {
    return false;
  }
  final allowedBindings = switch (node.payload.actionKind) {
    'sourceMapEnter' => const {'mapId'},
    'sourceTriggerEnter' => const {'mapId', 'triggerId'},
    'sourceEntityInteract' => const {'mapId', 'entityId'},
    'sourceOutcome' => const {'outcomeId'},
    _ => const <String>{},
  };
  return _bindingContainsOnly(node.binding, allowedBindings);
}

bool _hasOnlyDialogueSemantics(ScenarioNode node) {
  return _exact(node.binding.dialogueId) &&
      _bindingContainsOnly(node.binding, const {'dialogueId'}) &&
      node.payload.actionKind == null &&
      node.payload.message == null &&
      node.payload.condition == null &&
      node.payload.choiceLabels.isEmpty &&
      node.payload.params.keys.every((key) => key == 'startNode') &&
      node.metadata.isEmpty;
}

bool _hasOnlyEndSemantics(ScenarioNode node) {
  return _bindingContainsOnly(node.binding, const {}) &&
      node.payload.actionKind == null &&
      node.payload.message == null &&
      node.payload.condition == null &&
      node.payload.choiceLabels.isEmpty &&
      node.payload.params.isEmpty &&
      node.metadata.isEmpty;
}

bool _bindingContainsOnly(
  ScenarioNodeBinding binding,
  Set<String> allowed,
) {
  final values = <String, String?>{
    'mapId': binding.mapId,
    'eventId': binding.eventId,
    'entityId': binding.entityId,
    'warpId': binding.warpId,
    'triggerId': binding.triggerId,
    'trainerId': binding.trainerId,
    'dialogueId': binding.dialogueId,
    'scriptId': binding.scriptId,
    'outcomeId': binding.outcomeId,
    'flagName': binding.flagName,
    'variableName': binding.variableName,
  };
  return values.entries.every(
    (entry) => entry.value == null || allowed.contains(entry.key),
  );
}

bool _sameObservableTrace(
  ScenarioAsset scenario,
  String sourceNodeId,
  SceneAsset scene,
) {
  if (scene.declaredOutcomes.isNotEmpty) return false;
  return _scenarioTrace(scenario, sourceNodeId).join('|') ==
      _sceneTrace(scene).join('|');
}

/// Replays the C3 Scene proof against the current immutable project assets.
bool hasEquivalentLegacyScenarioSceneCandidate({
  required ScenarioAsset scenario,
  required String sourceNodeId,
  required SceneAsset scene,
}) {
  final matchingNodes = scenario.nodes
      .where((node) => node.id == sourceNodeId)
      .toList(growable: false);
  if (matchingNodes.length != 1 || !buildSceneRuntimePlan(scene).canBuild) {
    return false;
  }
  return _sameObservableTrace(scenario, sourceNodeId, scene);
}

/// Restricts an assisted source choice to the source encoded by the Scenario.
bool isCompatibleLegacyScenarioSourceChoice({
  required LegacyScenarioSourceProjection projection,
  required ScenarioAsset scenario,
  required NarrativeEventSourceRef selectedSource,
}) {
  final projectedSource = projection.source;
  if (projectedSource != null) return selectedSource == projectedSource;
  final matchingNodes = scenario.nodes
      .where((node) => node.id == projection.nodeId)
      .toList(growable: false);
  if (matchingNodes.length != 1) return false;
  final node = matchingNodes.single;
  final rawOutcomeId = node.binding.outcomeId;
  if (node.payload.actionKind != 'sourceOutcome' || !_exact(rawOutcomeId)) {
    return false;
  }
  return selectedSource.when(
    entityInteract: (_, __) => false,
    triggerEnter: (_, __) => false,
    mapEnter: (_) => false,
    outcomeReceived: (outcome) => outcome.outcomeId == rawOutcomeId,
  );
}

List<String> _scenarioTrace(ScenarioAsset scenario, String sourceNodeId) {
  final result = <String>[];
  var currentId = sourceNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scenario.nodes.singleWhere((item) => item.id == currentId);
    if (node.type == ScenarioNodeType.dialogue) {
      result.add(
        jsonEncode({
          'kind': 'dialogue',
          'dialogueId': node.binding.dialogueId,
          'startNode': _optionalRuntimeText(node.payload.params['startNode']),
          'expectedOutcomes': const <String>[],
          'speakerHints': const <String>[],
        }),
      );
    } else if (node.type == ScenarioNodeType.end) {
      result.add(jsonEncode({'kind': 'end', 'outcomeId': null}));
      return result;
    } else if (node.id != sourceNodeId) {
      return const ['unsupported'];
    }
    final outgoing =
        scenario.edges.where((edge) => edge.fromNodeId == currentId).toList();
    if (outgoing.length != 1) return const ['unsupported'];
    currentId = outgoing.single.toNodeId;
  }
  return const ['cycle'];
}

List<String> _sceneTrace(SceneAsset scene) {
  final result = <String>[];
  var currentId = scene.graph.startNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scene.graph.nodes.singleWhere((item) => item.id == currentId);
    if (node.kind == SceneNodeKind.yarnDialogue) {
      final payload = node.payload as SceneYarnDialoguePayload;
      result.add(
        jsonEncode({
          'kind': 'dialogue',
          'dialogueId': payload.dialogueId,
          'startNode': _optionalRuntimeText(payload.yarnNodeName),
          'expectedOutcomes': payload.expectedOutcomes,
          'speakerHints': payload.speakerHints,
        }),
      );
    } else if (node.kind == SceneNodeKind.end) {
      final payload = node.payload as SceneEndPayload;
      result.add(
        jsonEncode({'kind': 'end', 'outcomeId': payload.sceneOutcomeId}),
      );
      return result;
    } else if (node.kind != SceneNodeKind.start) {
      return const ['unsupported'];
    }
    final outgoing = scene.graph.edges
        .where((edge) => edge.fromNodeId == currentId)
        .toList();
    if (outgoing.length != 1 ||
        outgoing.single.kind != SceneEdgeKind.defaultFlow ||
        outgoing.single.fromPortId != 'completed') {
      return const ['unsupported'];
    }
    currentId = outgoing.single.toNodeId;
  }
  return const ['cycle'];
}

String? _optionalRuntimeText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool _exact(String? value) {
  return value != null && value.isNotEmpty && value.trim() == value;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

Map<String, Object?> _normalizeJson(Map<String, Object?> value) {
  return Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
}

Map<String, Object?> _freezeObject(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freezeJson(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  return value;
}

String _requireText(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
````

</details>

### `packages/map_core/lib/src/compatibility/narrative_event_migration_plan.dart`

SHA-256: `a69ff9916df66ce1ff5324e5bc7fdeab9b5c38091d987150bf7f078ac55391da` — 502 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'legacy_event_migration_models.dart';
import 'legacy_map_event_projection.dart';
import 'legacy_scenario_source_projection.dart';
import 'narrative_event_migration_receipt.dart';
import 'narrative_event_reference_mapping.dart';

abstract final class NarrativeEventMigrationDiagnosticCodes {
  static const staleRevision = 'staleRevision';
  static const sourceHashMismatch = 'sourceHashMismatch';
  static const corpusEvidenceMismatch = 'corpusEvidenceMismatch';
  static const unknownLegacyData = 'unknownLegacyData';
  static const partialClaim = 'partialClaim';
  static const invalidExistingClaim = 'invalidExistingClaim';
  static const incompleteCohort = 'incompleteCohort';
  static const assistanceRequired = 'assistanceRequired';
  static const lifecycleChoiceRequired = 'lifecycleChoiceRequired';
  static const choiceContradictsProjection = 'choiceContradictsProjection';
  static const unusedChoice = 'unusedChoice';
  static const blockedProjection = 'blockedProjection';
  static const unsupportedProjection = 'unsupportedProjection';
  static const legacyOnlyProjection = 'legacyOnlyProjection';
  static const unresolvedReference = 'unresolvedReference';
  static const existingReceiptMismatch = 'existingReceiptMismatch';
  static const incrementalReceiptHistoryRequired =
      'incrementalReceiptHistoryRequired';
}

enum NarrativeEventMigrationPlanStatus {
  empty,
  ready,
  assistanceRequired,
  blocked,
  alreadyPrepared,
}

enum NarrativeEventMigrationCohortClaimStatus {
  proposed,
  existing,
  absent,
  blocked,
}

@immutable
final class NarrativeEventUnknownLegacyData {
  NarrativeEventUnknownLegacyData({
    required String path,
    required Object? value,
    this.provenance,
  })  : path = _identity(path, 'path'),
        value = _freezeJson(value);

  final String path;
  final Object? value;
  final LegacySourceRef? provenance;

  Map<String, Object?> toJson() => {
        'path': path,
        if (provenance != null) 'provenance': provenance!.toJson(),
        'value': value,
      };
}

@immutable
final class NarrativeEventMigrationTargetProposal {
  NarrativeEventMigrationTargetProposal({
    required String name,
    this.legacyPageIndex,
    required List<NarrativeEventCondition> conditions,
    String? sceneId,
    this.reusePolicy,
    required this.priority,
    required int order,
  })  : name = _identity(name.trim(), 'name'),
        conditions = List.unmodifiable(conditions),
        sceneId = _optionalIdentity(sceneId, 'sceneId'),
        order = _nonNegative(order, 'order') {
    if (legacyPageIndex != null && legacyPageIndex! < 0) {
      throw ArgumentError.value(
        legacyPageIndex,
        'legacyPageIndex',
        'must be non-negative',
      );
    }
  }

  final String name;
  final int? legacyPageIndex;
  final List<NarrativeEventCondition> conditions;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;

  bool get isConfigured => sceneId != null && reusePolicy != null;

  String recordSignature(NarrativeEventSourceRef source) {
    return canonicalizeNarrativeEventJson({
      'name': name,
      'source': source.toJson(),
      'conditions': [for (final condition in conditions) condition.toJson()],
      if (sceneId != null) 'sceneId': sceneId,
      if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
      'priority': priority,
      'order': order,
    });
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (legacyPageIndex != null) 'legacyPageIndex': legacyPageIndex,
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (sceneId != null) 'sceneId': sceneId,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        'priority': priority,
        'order': order,
      };
}

@immutable
final class NarrativeEventMigrationSourceChoice {
  NarrativeEventMigrationSourceChoice({
    required this.provenance,
    required this.source,
    required List<NarrativeEventMigrationTargetProposal> targets,
  }) : targets = List.unmodifiable(targets) {
    if (this.targets.isEmpty) {
      throw ArgumentError.value(targets, 'targets', 'must not be empty');
    }
  }

  final LegacySourceRef provenance;
  final NarrativeEventSourceRef source;
  final List<NarrativeEventMigrationTargetProposal> targets;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'source': source.toJson(),
        'targets': [for (final target in targets) target.toJson()],
      };
}

@immutable
final class NarrativeEventMigrationChoices {
  NarrativeEventMigrationChoices({
    List<NarrativeEventMigrationSourceChoice> sourceChoices = const [],
    List<NarrativeEventReferenceResolutionChoice> referenceChoices = const [],
  })  : sourceChoices = List.unmodifiable(sourceChoices),
        referenceChoices = List.unmodifiable(referenceChoices) {
    final provenances = <LegacySourceRef>{};
    for (final choice in this.sourceChoices) {
      if (!provenances.add(choice.provenance)) {
        throw ArgumentError.value(
          choice.provenance.toJson(),
          'sourceChoices',
          'a provenance can only have one source choice',
        );
      }
    }
    final paths = <String>{};
    for (final choice in this.referenceChoices) {
      if (!paths.add(choice.path)) {
        throw ArgumentError.value(
          choice.path,
          'referenceChoices',
          'a path can only have one reference choice',
        );
      }
    }
  }

  factory NarrativeEventMigrationChoices.empty() =>
      NarrativeEventMigrationChoices();

  final List<NarrativeEventMigrationSourceChoice> sourceChoices;
  final List<NarrativeEventReferenceResolutionChoice> referenceChoices;

  NarrativeEventMigrationSourceChoice? sourceChoiceFor(
    LegacySourceRef provenance,
  ) {
    for (final choice in sourceChoices) {
      if (choice.provenance == provenance) return choice;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'sourceChoices': [
          for (final choice in sourceChoices) choice.toJson(),
        ],
        'referenceChoices': [
          for (final choice in referenceChoices) choice.toJson(),
        ],
      };
}

@immutable
final class NarrativeEventMigrationItem {
  NarrativeEventMigrationItem({
    required this.provenance,
    required this.classification,
    required this.source,
    required String sourceFingerprint,
    required this.choiceApplied,
    required this.resolved,
    required List<String> targetEventIds,
  })  : sourceFingerprint = _identity(
          sourceFingerprint,
          'sourceFingerprint',
        ),
        targetEventIds = _sortedUnique(targetEventIds, 'targetEventIds');

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final NarrativeEventSourceRef? source;
  final String sourceFingerprint;
  final bool choiceApplied;
  final bool resolved;
  final List<String> targetEventIds;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'classification': classification.name,
        if (source != null) 'source': source!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'choiceApplied': choiceApplied,
        'resolved': resolved,
        'targetEventIds': targetEventIds,
      };
}

@immutable
final class NarrativeEventMigrationCohort {
  NarrativeEventMigrationCohort({
    required String cohortId,
    required this.source,
    required List<LegacySourceClaimMember> members,
    required this.classification,
    required this.complete,
    required this.claimStatus,
    required List<String> targetEventIds,
    required this.claim,
  })  : cohortId = _identity(cohortId, 'cohortId'),
        members = _sortedMembers(members),
        targetEventIds = _sortedUnique(targetEventIds, 'targetEventIds') {
    if ((claimStatus == NarrativeEventMigrationCohortClaimStatus.proposed ||
            claimStatus == NarrativeEventMigrationCohortClaimStatus.existing) &&
        claim == null) {
      throw ArgumentError('Proposed and existing cohort states require claim.');
    }
    if (!complete &&
        claimStatus == NarrativeEventMigrationCohortClaimStatus.proposed) {
      throw ArgumentError('An incomplete cohort cannot propose a claim.');
    }
  }

  final String cohortId;
  final NarrativeEventSourceRef source;
  final List<LegacySourceClaimMember> members;
  final LegacyMigrationClassification classification;
  final bool complete;
  final NarrativeEventMigrationCohortClaimStatus claimStatus;
  final List<String> targetEventIds;
  final LegacySourceClaim? claim;

  Map<String, Object?> toJson() => {
        'cohortId': cohortId,
        'source': source.toJson(),
        'members': [for (final member in members) member.toJson()],
        'classification': classification.name,
        'complete': complete,
        'claimStatus': claimStatus.name,
        'targetEventIds': targetEventIds,
        if (claim != null) 'claim': claim!.toJson(),
      };
}

@immutable
final class NarrativeEventMigrationPlannerInput {
  NarrativeEventMigrationPlannerInput({
    required this.project,
    required List<MapData> maps,
    required List<LegacyMapEventProjection> mapEventProjections,
    required List<LegacyScenarioSourceProjection> scenarioProjections,
    required this.references,
    required this.currentSnapshot,
    this.expectedSnapshot,
    required this.choices,
    required Map<String, Object?> characterizedCorpus,
    required List<Map<String, Object?>> saveSnapshots,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
    required this.backupPlan,
    this.existingReceipt,
  })  : maps = List.unmodifiable(maps),
        mapEventProjections = List.unmodifiable(mapEventProjections),
        scenarioProjections = List.unmodifiable(scenarioProjections),
        characterizedCorpus = _freezeMap(characterizedCorpus),
        saveSnapshots = List.unmodifiable([
          for (final snapshot in saveSnapshots) _freezeMap(snapshot),
        ]),
        unknownLegacyData = List.unmodifiable(unknownLegacyData);

  final ProjectManifest project;
  final List<MapData> maps;
  final List<LegacyMapEventProjection> mapEventProjections;
  final List<LegacyScenarioSourceProjection> scenarioProjections;
  final NarrativeEventReferenceCatalog references;
  final NarrativeEventMigrationSnapshot currentSnapshot;
  final NarrativeEventMigrationSnapshot? expectedSnapshot;
  final NarrativeEventMigrationChoices choices;
  final Map<String, Object?> characterizedCorpus;
  final List<Map<String, Object?>> saveSnapshots;
  final List<NarrativeEventUnknownLegacyData> unknownLegacyData;
  final NarrativeEventMigrationBackupPlan backupPlan;
  final NarrativeEventMigrationReceipt? existingReceipt;
}

@immutable
final class NarrativeEventMigrationPlan {
  NarrativeEventMigrationPlan({
    required this.status,
    required List<NarrativeEventRecord> recordsProposed,
    required List<LegacySourceClaim> claimsProposed,
    required List<NarrativeEventMigrationCohort> cohorts,
    required List<NarrativeEventMigrationItem> items,
    required this.mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required this.writePreconditions,
    required this.backupPlan,
    required this.receiptProposal,
    required this.rollbackPlan,
    required this.pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
  })  : recordsProposed = _sortedRecords(recordsProposed),
        claimsProposed = _sortedClaims(claimsProposed),
        cohorts = List.unmodifiable(cohorts),
        items = List.unmodifiable(items),
        diagnostics = List.unmodifiable(diagnostics),
        unknownLegacyData = List.unmodifiable(unknownLegacyData);

  final NarrativeEventMigrationPlanStatus status;
  final List<NarrativeEventRecord> recordsProposed;
  final List<LegacySourceClaim> claimsProposed;
  final List<NarrativeEventMigrationCohort> cohorts;
  final List<NarrativeEventMigrationItem> items;
  final NarrativeEventReferenceMappings mappings;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final NarrativeEventMigrationWritePreconditions writePreconditions;
  final NarrativeEventMigrationBackupPlan backupPlan;
  final NarrativeEventMigrationReceipt? receiptProposal;
  final NarrativeEventMigrationRollbackPlan rollbackPlan;
  final NarrativeEventMigrationPointOfNoReturn pointOfNoReturn;
  final List<NarrativeEventUnknownLegacyData> unknownLegacyData;

  bool get canApply =>
      status == NarrativeEventMigrationPlanStatus.ready &&
      receiptProposal != null;

  List<NarrativeEventRecord> get draftsProposed => List.unmodifiable([
        for (final record in recordsProposed)
          if (record.draftOrNull != null) record,
      ]);

  List<NarrativeEventMigrationItem> get autoSafeItems =>
      _itemsWith(LegacyMigrationClassification.autoSafe);
  List<NarrativeEventMigrationItem> get assistedItems =>
      _itemsWith(LegacyMigrationClassification.assisted);
  List<NarrativeEventMigrationItem> get blockedItems =>
      _itemsWith(LegacyMigrationClassification.blocked);
  List<NarrativeEventMigrationItem> get unsupportedItems =>
      _itemsWith(LegacyMigrationClassification.unsupported);
  List<NarrativeEventMigrationItem> get legacyOnlyItems =>
      _itemsWith(LegacyMigrationClassification.legacyOnly);

  List<NarrativeEventMigrationItem> _itemsWith(
    LegacyMigrationClassification classification,
  ) {
    return List.unmodifiable([
      for (final item in items)
        if (item.classification == classification) item,
    ]);
  }

  Map<String, Object?> toJson() => {
        'status': status.name,
        'canApply': canApply,
        'recordsProposed': [
          for (final record in recordsProposed) record.toJson(),
        ],
        'draftsProposed': [
          for (final record in draftsProposed) record.toJson(),
        ],
        'claimsProposed': [
          for (final claim in claimsProposed) claim.toJson(),
        ],
        'cohorts': [for (final cohort in cohorts) cohort.toJson()],
        'items': [for (final item in items) item.toJson()],
        'mappings': mappings.toJson(),
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'writePreconditions': writePreconditions.toJson(),
        'backupPlan': backupPlan.toJson(),
        if (receiptProposal != null)
          'receiptProposal': receiptProposal!.toJson(),
        'rollbackPlan': rollbackPlan.toJson(),
        'pointOfNoReturn': pointOfNoReturn.toJson(),
        'unknownLegacyData': [
          for (final value in unknownLegacyData) value.toJson(),
        ],
      };
}

List<NarrativeEventRecord> _sortedRecords(
  List<NarrativeEventRecord> records,
) {
  final sorted = List<NarrativeEventRecord>.of(records)
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(sorted);
}

List<LegacySourceClaim> _sortedClaims(List<LegacySourceClaim> claims) {
  final sorted = List<LegacySourceClaim>.of(claims)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  return List.unmodifiable(sorted);
}

List<LegacySourceClaimMember> _sortedMembers(
  List<LegacySourceClaimMember> members,
) {
  final sorted = List<LegacySourceClaimMember>.of(members)
    ..sort((left, right) => compareLegacySourceRefs(
          left.provenance,
          right.provenance,
        ));
  return List.unmodifiable(sorted);
}

List<String> _sortedUnique(List<String> values, String name) {
  final sorted = values.map((value) => _identity(value, name)).toList()..sort();
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return List.unmodifiable(sorted);
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List.unmodifiable([for (final item in value) _freezeJson(item)]);
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        _jsonKey(entry.key): _freezeJson(entry.value),
    });
  }
  throw ArgumentError.value(value, 'value', 'must contain JSON values only');
}

String _jsonKey(Object? value) {
  if (value is! String) {
    throw ArgumentError.value(value, 'JSON key', 'must be a String');
  }
  return value;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalIdentity(String? value, String name) {
  if (value == null) return null;
  return _identity(value, name);
}

int _nonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
  return value;
}
````

</details>

### `packages/map_core/lib/src/compatibility/narrative_event_migration_planner.dart`

SHA-256: `400580131486f75981a8167654d09101df0a30c2baee7de8c4b08a3061c1fc2c` — 2616 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../operations/narrative_event_canonical_json.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'legacy_event_migration_models.dart';
import 'legacy_map_event_projection.dart';
import 'legacy_scenario_source_projection.dart';
import 'narrative_event_migration_plan.dart';
import 'narrative_event_migration_receipt.dart';
import 'narrative_event_reference_mapping.dart';

abstract interface class NarrativeEventMigrationIdSource {
  String nextEventId();

  String nextReceiptId();
}

typedef NarrativeEventMigrationClock = DateTime Function();

final class NarrativeEventMigrationPlanner {
  NarrativeEventMigrationPlanner({
    required NarrativeEventMigrationIdSource ids,
    required NarrativeEventMigrationClock clock,
  })  : _ids = ids,
        _clock = clock;

  final NarrativeEventMigrationIdSource _ids;
  final NarrativeEventMigrationClock _clock;

  NarrativeEventMigrationPlan plan(
    NarrativeEventMigrationPlannerInput input,
  ) {
    final writePreconditions = NarrativeEventMigrationWritePreconditions(
      snapshot: input.currentSnapshot,
    );
    final rollbackPlan = NarrativeEventMigrationRollbackPlan.phaseCProposal();
    final pointOfNoReturn =
        NarrativeEventMigrationPointOfNoReturn.phaseCProposal();
    final unknownData = List<NarrativeEventUnknownLegacyData>.of(
      input.unknownLegacyData,
    )..sort((left, right) => left.path.compareTo(right.path));
    final candidates = _buildCandidates(input)..sort(_compareCandidates);
    final diagnostics = <LegacyMigrationDiagnostic>[
      for (final candidate in candidates) ...candidate.diagnostics,
    ];

    if (_hasCorpusEvidenceMismatch(input, candidates, diagnostics)) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final isEmpty = input.mapEventProjections.isEmpty &&
        input.scenarioProjections.isEmpty &&
        input.references.isEmpty &&
        unknownData.isEmpty &&
        input.choices.sourceChoices.isEmpty &&
        input.choices.referenceChoices.isEmpty &&
        (input.project.eventRegistry?.legacyClaims.isEmpty ?? true) &&
        input.existingReceipt == null;
    if (isEmpty) {
      return NarrativeEventMigrationPlan(
        status: NarrativeEventMigrationPlanStatus.empty,
        recordsProposed: const [],
        claimsProposed: const [],
        cohorts: const [],
        items: const [],
        mappings: NarrativeEventReferenceMappings(),
        diagnostics: const [],
        writePreconditions: writePreconditions,
        backupPlan: input.backupPlan,
        receiptProposal: null,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownLegacyData: const [],
      );
    }

    final expected = input.expectedSnapshot;
    if (expected != null && !expected.sameAs(input.currentSnapshot)) {
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.staleRevision,
          LegacyMigrationDiagnosticSeverity.error,
          'The migration snapshot no longer matches the expected revision '
              'and hashes.',
          'revisionContext',
        ),
      );
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    var hasHardBlock = _recordUnusedChoices(
      input,
      candidates,
      diagnostics,
    );
    var hasSnapshotBlock = false;
    var assistancePending = false;

    final concernedMapIds = <String>{
      for (final map in input.maps) map.id,
    };
    for (final candidate in candidates) {
      candidate.provenance.when(
        mapEvent: (mapId, _) => concernedMapIds.add(mapId),
        scenarioSourceNode: (_, __) {},
      );
      candidate.source?.when(
        entityInteract: (mapId, _) => concernedMapIds.add(mapId),
        triggerEnter: (mapId, _) => concernedMapIds.add(mapId),
        mapEnter: concernedMapIds.add,
        outcomeReceived: (_) {},
      );
    }
    final sortedConcernedMapIds = concernedMapIds.toList()..sort();
    for (final mapId in sortedConcernedMapIds) {
      if (!input.currentSnapshot.mapHashes.containsKey(mapId)) {
        hasHardBlock = true;
        hasSnapshotBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'A concerned map is missing from the hash preconditions.',
            'mapHashes.$mapId',
          ),
        );
      }
    }

    for (final candidate in candidates) {
      final snapshotKey =
          legacyMigrationSourceSnapshotKey(candidate.provenance);
      final snapshotFingerprint =
          input.currentSnapshot.legacySourceHashes[snapshotKey];
      if (snapshotFingerprint != candidate.sourceFingerprint) {
        candidate.hardBlocked = true;
        hasHardBlock = true;
        hasSnapshotBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'The legacy source fingerprint is absent or stale in the '
                'revision context.',
            'legacySourceHashes.$snapshotKey',
          ),
        );
      }
      if (candidate.hardBlocked) hasHardBlock = true;
      _addClassificationDiagnostic(candidate, diagnostics);
    }

    if (unknownData.isNotEmpty) {
      hasHardBlock = true;
      hasSnapshotBlock = true;
      for (final unknown in unknownData) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.unknownLegacyData,
            LegacyMigrationDiagnosticSeverity.error,
            'Unknown legacy data is preserved in the preview and blocks '
            'migration until it is understood.',
            unknown.path,
          ),
        );
      }
    }

    if (hasSnapshotBlock) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final duplicateProvenances = <LegacySourceRef, List<_Candidate>>{};
    for (final candidate in candidates) {
      duplicateProvenances
          .putIfAbsent(candidate.provenance, () => [])
          .add(candidate);
    }
    for (final entry in duplicateProvenances.entries) {
      if (entry.value.length < 2) continue;
      hasHardBlock = true;
      for (final candidate in entry.value) {
        candidate.hardBlocked = true;
      }
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.incompleteCohort,
          LegacyMigrationDiagnosticSeverity.error,
          'The same legacy provenance was projected more than once.',
          _provenancePath(entry.key),
        ),
      );
    }

    final groups = _buildGroups(candidates);
    final registry = input.project.eventRegistry;
    if (registry != null) {
      final claimIndex = buildValidatedLegacyClaimIndex(registry);
      if (claimIndex.globalConflicts.isNotEmpty) {
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim,
            LegacyMigrationDiagnosticSeverity.error,
            'The existing registry has global claim conflicts.',
            'eventRegistry.legacyClaims',
          ),
        );
        for (final group in groups) {
          group.hardBlocked = true;
          for (final candidate in group.candidates) {
            candidate.hardBlocked = true;
          }
        }
      }
    }

    for (final group in groups) {
      _resolveExistingClaim(
        group,
        registry,
        input.existingReceipt,
        diagnostics,
      );
      if (group.hardBlocked) hasHardBlock = true;
      final groupNeedsAssistance =
          group.candidates.any((candidate) => candidate.assistancePending);
      if (group.existingClaim == null &&
          !group.canProposeClaim &&
          !groupNeedsAssistance &&
          !group.hardBlocked) {
        group.hardBlocked = true;
        for (final candidate in group.candidates) {
          candidate.hardBlocked = true;
        }
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.incompleteCohort,
            LegacyMigrationDiagnosticSeverity.error,
            'The complete source cohort cannot be represented by configured '
                'V2 target records.',
            'cohorts.${group.cohortId}',
          ),
        );
      }
    }

    NarrativeEventMigrationReceipt? reusedReceipt;
    final existingClaims = [
      for (final group in groups)
        if (group.existingClaim != null) group.existingClaim!,
    ];
    if (registry != null) {
      final exactClaimKeys = {
        for (final claim in existingClaims)
          canonicalizeNarrativeEventJson(claim.toJson()),
      };
      final orphanClaims = [
        for (final claim in registry.legacyClaims)
          if (!exactClaimKeys.contains(
            canonicalizeNarrativeEventJson(claim.toJson()),
          ))
            claim,
      ];
      if (orphanClaims.isNotEmpty) {
        hasHardBlock = true;
        for (final claim in orphanClaims) {
          diagnostics.add(
            _diagnostic(
              NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim,
              LegacyMigrationDiagnosticSeverity.error,
              'An existing legacy claim has no exact characterized source '
                  'cohort in this plan.',
              'eventRegistry.legacyClaims.${claim.cohortId}',
            ),
          );
        }
      }
    }
    final existingReceipt = input.existingReceipt;
    if (existingClaims.isNotEmpty) {
      if (existingReceipt != null &&
          _matchesAppliedReceipt(
            input: input,
            registry: registry!,
            candidates: candidates,
            existingClaims: existingClaims,
            receipt: existingReceipt,
          )) {
        reusedReceipt = existingReceipt;
      } else {
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'Existing claims require their exact receipt, target records, and '
                'applied-state fingerprints.',
            'existingReceipt',
          ),
        );
      }
    } else if (existingReceipt != null) {
      hasHardBlock = true;
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
          LegacyMigrationDiagnosticSeverity.error,
          'The supplied receipt does not belong to any exact existing claim.',
          'existingReceipt',
        ),
      );
    }
    if (existingClaims.isNotEmpty &&
        groups.any((group) => group.existingClaim == null)) {
      hasHardBlock = true;
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes
              .incrementalReceiptHistoryRequired,
          LegacyMigrationDiagnosticSeverity.error,
          'Phase C V0 cannot append cohorts to an existing prepared receipt '
              'without an explicit receipt-history model.',
          'existingReceipt',
        ),
      );
    }

    final preflightMappings = _buildReferencePreflightMappings(
      input: input,
      candidates: candidates,
      pageMappings: _buildPageMappings(candidates),
    );
    if (preflightMappings.hasBlockingMappings) {
      hasHardBlock = true;
      _recordBlockingReferenceDiagnostics(
        preflightMappings,
        diagnostics,
      );
    }

    if (hasHardBlock) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        groups: groups,
        mappings: preflightMappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final draftCandidates = [
      for (final candidate in candidates)
        if (candidate.assistancePending &&
            !candidate.resolved &&
            !candidate.hardBlocked &&
            candidate.targets.isNotEmpty)
          candidate,
    ];
    final usedEventIds = <String>{
      if (registry != null)
        for (final record in registry.records) record.id,
    };
    assistancePending = draftCandidates.isNotEmpty;
    if (assistancePending) {
      final drafts = <NarrativeEventRecord>[];
      for (final candidate in draftCandidates) {
        _proposeDrafts(
          candidate: candidate,
          usedEventIds: usedEventIds,
          records: drafts,
        );
      }
      final idMappings = _buildIdMappings(candidates);
      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: const {},
        targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
        references: input.references,
        choices: _effectiveReferenceChoices(input),
        idMappings: idMappings,
        pageMappings: _buildPageMappings(candidates),
      );
      if (mappings.hasBlockingMappings) {
        throw StateError(
          'Assistance mapping diverged from the no-ID preflight.',
        );
      }
      _sortDiagnostics(diagnostics);
      return NarrativeEventMigrationPlan(
        status: NarrativeEventMigrationPlanStatus.assistanceRequired,
        recordsProposed: drafts,
        claimsProposed: const [],
        cohorts: [for (final group in groups) group.toPublic()],
        items: [for (final candidate in candidates) candidate.toPublic()],
        mappings: mappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        backupPlan: input.backupPlan,
        receiptProposal: null,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownLegacyData: unknownData,
      );
    }

    final groupsToPropose = [
      for (final group in groups)
        if (group.existingClaim == null &&
            group.canProposeClaim &&
            !group.hardBlocked)
          group,
    ];
    final receiptId = groupsToPropose.isNotEmpty ? _nextReceiptId() : null;
    final recordsProposed = <NarrativeEventRecord>[];
    final claimsProposed = <LegacySourceClaim>[];

    for (final group in groupsToPropose) {
      _proposeGroup(
        group: group,
        receiptId: receiptId!,
        usedEventIds: usedEventIds,
        records: recordsProposed,
        claims: claimsProposed,
      );
    }

    final idMappings = _buildIdMappings(candidates);
    final targetIdsByProvenance = <LegacySourceRef, List<String>>{};
    for (final candidate in candidates) {
      if (candidate.resolved && candidate.targetEventIds.isNotEmpty) {
        targetIdsByProvenance[candidate.provenance] = candidate.targetEventIds;
      }
    }

    final pageMappings = _buildPageMappings(candidates);
    final mappings = buildNarrativeEventReferenceMappings(
      targetEventIdsByProvenance: targetIdsByProvenance,
      targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
      references: input.references,
      choices: _effectiveReferenceChoices(input),
      idMappings: idMappings,
      pageMappings: pageMappings,
    );
    if (mappings.hasBlockingMappings) {
      throw StateError(
        'Reference allocation diverged from the no-ID preflight.',
      );
    }

    final cohortResults = <NarrativeEventMigrationCohort>[
      for (final group in groups) group.toPublic(),
    ];
    final items = <NarrativeEventMigrationItem>[
      for (final candidate in candidates) candidate.toPublic(),
    ];
    _sortDiagnostics(diagnostics);

    final status = groupsToPropose.isEmpty
        ? NarrativeEventMigrationPlanStatus.alreadyPrepared
        : NarrativeEventMigrationPlanStatus.ready;

    NarrativeEventMigrationReceipt? receiptProposal = reusedReceipt;
    if (status == NarrativeEventMigrationPlanStatus.ready) {
      final registryAfter = _registryWithProposals(
        registry,
        recordsProposed,
        claimsProposed,
      );
      final manifestAfter = input.project.copyWith(
        eventRegistry: registryAfter,
      );
      receiptProposal = NarrativeEventMigrationReceipt(
        receiptId: receiptId!,
        isProposal: true,
        snapshot: input.currentSnapshot,
        expectedManifestHashAfter: _jsonFingerprint(manifestAfter.toJson()),
        expectedRegistryHashAfter: _jsonFingerprint(registryAfter.toJson()),
        lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(_clock()),
        cohortIds: [for (final claim in claimsProposed) claim.cohortId],
        mappings: mappings,
        targetRecords: recordsProposed,
        targetClaims: claimsProposed,
        backupPlan: input.backupPlan,
        writePreconditions: writePreconditions,
        atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
      );
    }

    return NarrativeEventMigrationPlan(
      status: status,
      recordsProposed: recordsProposed,
      claimsProposed: claimsProposed,
      cohorts: cohortResults,
      items: items,
      mappings: mappings,
      diagnostics: diagnostics,
      writePreconditions: writePreconditions,
      backupPlan: input.backupPlan,
      receiptProposal: receiptProposal,
      rollbackPlan: rollbackPlan,
      pointOfNoReturn: pointOfNoReturn,
      unknownLegacyData: unknownData,
    );
  }

  NarrativeEventMigrationPlan _planWithoutIds({
    required NarrativeEventMigrationPlannerInput input,
    required List<_Candidate> candidates,
    List<_Group> groups = const [],
    NarrativeEventReferenceMappings? mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required NarrativeEventMigrationWritePreconditions writePreconditions,
    required NarrativeEventMigrationRollbackPlan rollbackPlan,
    required NarrativeEventMigrationPointOfNoReturn pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownData,
  }) {
    _sortDiagnostics(diagnostics);
    return NarrativeEventMigrationPlan(
      status: NarrativeEventMigrationPlanStatus.blocked,
      recordsProposed: const [],
      claimsProposed: const [],
      cohorts: [for (final group in groups) group.toPublic()],
      items: [for (final candidate in candidates) candidate.toPublic()],
      mappings: mappings ??
          NarrativeEventReferenceMappings(
            pageMappings: _buildPageMappings(candidates),
          ),
      diagnostics: diagnostics,
      writePreconditions: writePreconditions,
      backupPlan: input.backupPlan,
      receiptProposal: null,
      rollbackPlan: rollbackPlan,
      pointOfNoReturn: pointOfNoReturn,
      unknownLegacyData: unknownData,
    );
  }

  String _nextReceiptId() {
    final value = _ids.nextReceiptId();
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError.value(
        value,
        'nextReceiptId',
        'must return a non-empty trimmed ID',
      );
    }
    return value;
  }

  String _nextEventId(Set<String> usedEventIds) {
    for (var attempt = 0; attempt < 17; attempt++) {
      final value = _ids.nextEventId();
      if (!narrativeEventIdPattern.hasMatch(value)) {
        throw ArgumentError.value(
          value,
          'nextEventId',
          'must return a canonical Event V2 ID',
        );
      }
      if (usedEventIds.add(value)) return value;
    }
    throw StateError('Event ID generation collided 17 consecutive times.');
  }

  void _proposeGroup({
    required _Group group,
    required String receiptId,
    required Set<String> usedEventIds,
    required List<NarrativeEventRecord> records,
    required List<LegacySourceClaim> claims,
  }) {
    final targetsBySignature =
        <String, NarrativeEventMigrationTargetProposal>{};
    for (final candidate in group.candidates) {
      for (final target in candidate.targets) {
        targetsBySignature.putIfAbsent(
          target.recordSignature(group.source),
          () => target,
        );
      }
    }
    final signatures = targetsBySignature.keys.toList()..sort();
    final eventIdBySignature = <String, String>{};
    for (final signature in signatures) {
      final target = targetsBySignature[signature]!;
      final eventId = _nextEventId(usedEventIds);
      eventIdBySignature[signature] = eventId;
      final definition = NarrativeEventDefinition(
        id: eventId,
        name: target.name,
        source: group.source,
        conditions: target.conditions,
        sceneId: target.sceneId!,
        reusePolicy: target.reusePolicy!,
        priority: target.priority,
        order: target.order,
      );
      records.add(
        NarrativeEventRecord.configuredStructurallyUnchecked(
          definition,
          enabled: false,
        ),
      );
    }
    for (final candidate in group.candidates) {
      for (final target in candidate.targets) {
        final targetId =
            eventIdBySignature[target.recordSignature(group.source)]!;
        candidate.addTarget(target, targetId);
      }
      candidate.resolved = true;
    }
    final targetEventIds = eventIdBySignature.values.toList()..sort();
    final claim = LegacySourceClaim(
      cohortId: group.cohortId,
      source: group.source,
      members: group.members,
      cohortFingerprint: computeLegacySourceCohortFingerprint(
        group.cohortId,
        group.members,
      ),
      targetEventIds: targetEventIds,
      migrationReceiptId: receiptId,
    );
    claims.add(claim);
    group.proposedClaim = claim;
    group.targetEventIds = targetEventIds;
  }

  void _proposeDrafts({
    required _Candidate candidate,
    required Set<String> usedEventIds,
    required List<NarrativeEventRecord> records,
  }) {
    for (final target in candidate.targets) {
      final eventId = _nextEventId(usedEventIds);
      records.add(
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: eventId,
            name: target.name,
            source: candidate.source,
            conditions: target.conditions,
            sceneId: target.sceneId,
            reusePolicy: target.reusePolicy,
            priority: target.priority,
            order: target.order,
          ),
        ),
      );
      candidate.addTarget(target, eventId);
    }
  }
}

List<NarrativeEventIdMapping> _buildIdMappings(
  List<_Candidate> candidates,
) {
  final mappings = <NarrativeEventIdMapping>[
    for (final candidate in candidates)
      if (candidate.targetEventIds.isNotEmpty)
        NarrativeEventIdMapping(
          provenance: candidate.provenance,
          legacyId: _legacyId(candidate.provenance),
          targetEventIds: candidate.targetEventIds,
        ),
  ];
  mappings.sort(
    (left, right) => compareLegacySourceRefs(
      left.provenance,
      right.provenance,
    ),
  );
  return mappings;
}

Map<LegacySourceRef, Map<String, String>> _buildTargetIdsByKey(
  List<_Candidate> candidates,
) {
  return {
    for (final candidate in candidates)
      if (candidate.targetEventIdsByKey.isNotEmpty)
        candidate.provenance: Map.unmodifiable(candidate.targetEventIdsByKey),
  };
}

NarrativeEventRegistry _registryWithProposals(
  NarrativeEventRegistry? current,
  List<NarrativeEventRecord> proposedRecords,
  List<LegacySourceClaim> proposedClaims,
) {
  final records = <NarrativeEventRecord>[
    ...?current?.records,
    ...proposedRecords,
  ]..sort((left, right) => left.id.compareTo(right.id));
  final claims = <LegacySourceClaim>[
    ...?current?.legacyClaims,
    ...proposedClaims,
  ]..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  return NarrativeEventRegistry(
    schemaVersion: current?.schemaVersion ?? 1,
    mode: current?.mode ?? EventSystemMode.legacyOnly,
    records: records,
    legacyClaims: claims,
  );
}

bool _hasCorpusEvidenceMismatch(
  NarrativeEventMigrationPlannerInput input,
  List<_Candidate> candidates,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  var mismatch = false;

  void record(String message, String path) {
    mismatch = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        message,
        path,
      ),
    );
  }

  void recordMap(String message, String path) {
    mismatch = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        message,
        path,
      ),
    );
  }

  final candidateSourceKeys = <String>{
    for (final candidate in candidates)
      legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  final snapshotSourceKeys =
      input.currentSnapshot.legacySourceHashes.keys.toSet();
  if (!_sameStrings(candidateSourceKeys, snapshotSourceKeys)) {
    record(
      'The characterized source inventory and supplied projections differ.',
      'legacySourceHashes',
    );
  }

  if (input.currentSnapshot.corpusHash !=
      _jsonFingerprint(input.characterizedCorpus)) {
    record(
      'The characterized corpus hash does not match the supplied corpus.',
      'corpusHash',
    );
  }
  if (input.currentSnapshot.manifestHash !=
      _jsonFingerprint(input.project.toJson())) {
    record(
      'The manifest hash does not match the supplied read-only project.',
      'manifestHash',
    );
  }
  if (input.currentSnapshot.referenceCatalogHash !=
      _jsonFingerprint(input.references.toJson())) {
    record(
      'The reference catalog hash does not match the supplied catalog.',
      'referenceCatalogHash',
    );
  }
  final corpusReferences = input.characterizedCorpus['references'];
  if (corpusReferences == null) {
    if (!input.references.isEmpty) {
      record(
        'A non-empty reference catalog requires the characterized corpus '
            'reference inventory.',
        'characterizedCorpus.references',
      );
    }
  } else {
    if (corpusReferences is! List) {
      record(
        'The characterized corpus references inventory must be a list.',
        'characterizedCorpus.references',
      );
    } else {
      final corpusReferencesByPath = <String, String>{};
      for (var index = 0; index < corpusReferences.length; index++) {
        final value = corpusReferences[index];
        if (value is! Map ||
            value['kind'] is! String ||
            value['path'] is! String ||
            value['rawId'] is! String ||
            value['candidates'] is! List) {
          record(
            'Every characterized reference requires kind, path, rawId, and '
                'candidates.',
            'characterizedCorpus.references[$index]',
          );
          continue;
        }
        final kind = value['kind']! as String;
        final path = value['path']! as String;
        final rawId = value['rawId']! as String;
        final mapIdValue = value['mapId'];
        final candidateValues = value['candidates']! as List;
        final candidates = <String>{};
        var candidatesValid = true;
        for (var candidateIndex = 0;
            candidateIndex < candidateValues.length;
            candidateIndex++) {
          final candidate = candidateValues[candidateIndex];
          if (candidate is! String ||
              candidate.isEmpty ||
              candidate.trim() != candidate ||
              !candidates.add(candidate)) {
            candidatesValid = false;
            record(
              'Characterized reference candidates must be unique, non-empty '
                  'trimmed strings.',
              'characterizedCorpus.references[$index].candidates'
                  '[$candidateIndex]',
            );
          }
        }
        if (kind.isEmpty ||
            kind.trim() != kind ||
            path.isEmpty ||
            path.trim() != path ||
            rawId.isEmpty ||
            rawId.trim() != rawId ||
            (mapIdValue != null &&
                (mapIdValue is! String ||
                    mapIdValue.isEmpty ||
                    mapIdValue.trim() != mapIdValue)) ||
            corpusReferencesByPath.containsKey(path) ||
            !candidatesValid) {
          record(
            'Characterized reference fields must be unique, non-empty, and '
                'trimmed.',
            'characterizedCorpus.references[$index]',
          );
          continue;
        }
        final sortedCandidates = candidates.toList()..sort();
        corpusReferencesByPath[path] = canonicalizeNarrativeEventJson({
          'kind': kind,
          'path': path,
          'rawId': rawId,
          if (mapIdValue != null) 'mapId': mapIdValue,
          'candidates': sortedCandidates,
        });
      }
      final catalogReferencesByPath = {
        for (final reference in input.references.all)
          reference.path: canonicalizeNarrativeEventJson({
            'kind': _corpusReferenceKind(reference.kind),
            'path': reference.path,
            'rawId': reference.legacyEventId,
            if (reference.mapId != null) 'mapId': reference.mapId,
            'candidates': [
              for (final provenance in reference.candidateProvenances)
                _corpusCandidateLabel(provenance),
            ]..sort(),
          }),
      };
      if (!_sameStringMap(
        corpusReferencesByPath,
        catalogReferencesByPath,
      )) {
        record(
          'The reference catalog must exactly cover the characterized corpus '
              'reference inventory, kinds, scopes, and provenances.',
          'characterizedCorpus.references',
        );
      }
    }
  }

  final mapsById = <String, MapData>{};
  for (var index = 0; index < input.maps.length; index++) {
    final map = input.maps[index];
    if (mapsById.containsKey(map.id)) {
      recordMap(
        'The supplied read-only maps contain a duplicate map ID.',
        'maps[$index].id',
      );
      continue;
    }
    mapsById[map.id] = map;
  }
  final manifestMapIds = <String>{};
  for (var index = 0; index < input.project.maps.length; index++) {
    final entry = input.project.maps[index];
    if (!manifestMapIds.add(entry.id)) {
      recordMap(
        'The read-only manifest contains a duplicate map ID.',
        'project.maps[$index].id',
      );
    }
  }
  if (!_sameStrings(manifestMapIds, mapsById.keys.toSet())) {
    recordMap(
      'The read-only manifest map inventory does not match the supplied maps.',
      'project.maps',
    );
  }
  if (!_sameStrings(
    mapsById.keys.toSet(),
    input.currentSnapshot.mapHashes.keys.toSet(),
  )) {
    recordMap(
      'The map snapshot inventory does not match the supplied read-only maps.',
      'mapHashes',
    );
  }
  for (final entry in mapsById.entries) {
    if (input.currentSnapshot.mapHashes[entry.key] !=
        _jsonFingerprint(entry.value.toJson())) {
      recordMap(
        'A supplied read-only map does not match its snapshot hash.',
        'mapHashes.${entry.key}',
      );
    }
  }
  final scenesById = <String, List<SceneAsset>>{};
  for (var index = 0; index < input.project.scenes.length; index++) {
    final scene = input.project.scenes[index];
    scenesById.putIfAbsent(scene.id, () => []).add(scene);
  }
  for (final entry in scenesById.entries) {
    if (entry.value.length > 1) {
      recordMap(
        'The read-only manifest contains a duplicate Scene ID.',
        'project.scenes.${entry.key}',
      );
    }
  }
  final mapSourceInventory = <String>{
    for (final map in input.maps)
      for (final event in map.events)
        legacyMigrationSourceSnapshotKey(
          LegacySourceRef.mapEvent(map.id, event.id),
        ),
  };
  final projectedMapSources = <String>{
    for (final candidate in candidates)
      if (_isMapProvenance(candidate.provenance))
        legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  if (!_sameStrings(mapSourceInventory, projectedMapSources)) {
    record(
      'Every MapEvent in the supplied maps must have exactly one projection.',
      'mapEventProjections',
    );
  }
  for (final candidate in candidates) {
    candidate.provenance.when(
      mapEvent: (mapId, eventId) {
        final matches = mapsById[mapId]
                ?.events
                .where((event) => event.id == eventId)
                .toList(growable: false) ??
            const [];
        if (matches.length != 1 ||
            computeMapEventSourceFingerprint(
                  mapId: mapId,
                  event: matches.single,
                ) !=
                candidate.sourceFingerprint) {
          recordMap(
            'The MapEvent projection fingerprint does not match its '
            'read-only source.',
            _provenancePath(candidate.provenance),
          );
        }
        for (final target in candidate.targets) {
          final sceneId = target.sceneId;
          if (sceneId == null) continue;
          final matches = scenesById[sceneId] ?? const <SceneAsset>[];
          if (matches.length != 1 ||
              !buildSceneRuntimePlan(matches.single).canBuild) {
            recordMap(
              'The MapEvent target Scene is absent, duplicated, or not '
                  'buildable in the read-only manifest.',
              'scenes.$sceneId',
            );
          }
        }
      },
      scenarioSourceNode: (_, __) {},
    );
  }

  final scenariosById = <String, List<ScenarioAsset>>{};
  for (var index = 0; index < input.project.scenarios.length; index++) {
    final scenario = input.project.scenarios[index];
    scenariosById.putIfAbsent(scenario.id, () => []).add(scenario);
  }
  for (final entry in scenariosById.entries) {
    if (entry.value.length > 1) {
      recordMap(
        'The read-only manifest contains a duplicate Scenario ID.',
        'project.scenarios.${entry.key}',
      );
    }
  }
  final scenarioSourceInventory = <String>{
    for (final scenario in input.project.scenarios)
      for (final node in scenario.nodes)
        if (_isLegacyScenarioSourceNode(node.payload.actionKind))
          legacyMigrationSourceSnapshotKey(
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id),
          ),
  };
  final projectedScenarioSources = <String>{
    for (final candidate in candidates)
      if (_isScenarioProvenance(candidate.provenance))
        legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  if (!_sameStrings(scenarioSourceInventory, projectedScenarioSources)) {
    record(
      'Every Scenario source node in the manifest must have exactly one '
          'projection.',
      'scenarioProjections',
    );
  }
  for (final candidate in candidates) {
    candidate.provenance.when(
      mapEvent: (_, __) {},
      scenarioSourceNode: (scenarioId, nodeId) {
        final scenarioMatches =
            scenariosById[scenarioId] ?? const <ScenarioAsset>[];
        final scenario =
            scenarioMatches.length == 1 ? scenarioMatches.single : null;
        final projection = candidate.scenarioProjection;
        final matchingNodes = scenario?.nodes
                .where((node) => node.id == nodeId)
                .toList(growable: false) ??
            const [];
        if (scenario == null ||
            matchingNodes.length != 1 ||
            computeScenarioSourceFingerprint(
                  scenarioId: scenarioId,
                  nodeId: nodeId,
                  scenario: scenario,
                ) !=
                candidate.sourceFingerprint) {
          recordMap(
            'The Scenario projection fingerprint does not match its '
            'read-only source.',
            _provenancePath(candidate.provenance),
          );
        }
        final choice = input.choices.sourceChoiceFor(candidate.provenance);
        if (scenario != null &&
            projection?.classification ==
                LegacyMigrationClassification.assisted &&
            choice != null &&
            (!isCompatibleLegacyScenarioSourceChoice(
                  projection: projection!,
                  scenario: scenario,
                  selectedSource: choice.source,
                ) ||
                !_scenarioAssistedChoiceMatchesProjection(
                  projection,
                  choice,
                ))) {
          record(
            'The assisted Scenario choice changes source or Event semantics '
                'outside the characterized projection.',
            '${_provenancePath(candidate.provenance)}.choice',
          );
        }
        if (projection?.classification ==
                LegacyMigrationClassification.autoSafe &&
            candidate.targets.isEmpty) {
          recordMap(
            'An AUTO_SAFE Scenario projection requires a currently proven '
                'Scene candidate.',
            '${_provenancePath(candidate.provenance)}.sceneCandidateId',
          );
        }
        for (final target in candidate.targets) {
          final sceneId = target.sceneId;
          if (sceneId == null) {
            if (target.isConfigured) {
              recordMap(
                'A configured Scenario migration target requires a Scene.',
                '${_provenancePath(candidate.provenance)}.targets',
              );
            }
            continue;
          }
          final matchingScenes = scenesById[sceneId] ?? const <SceneAsset>[];
          if (scenario == null ||
              matchingScenes.length != 1 ||
              !hasEquivalentLegacyScenarioSceneCandidate(
                scenario: scenario,
                sourceNodeId: nodeId,
                scene: matchingScenes.single,
              )) {
            recordMap(
              'The Scenario target Scene is absent, not buildable, or no '
                  'longer trace-equivalent in the read-only manifest.',
              'scenes.$sceneId',
            );
          }
        }
      },
    );
  }

  final saveHashes = <String, String>{};
  final referencesByPath = {
    for (final reference in input.references.all) reference.path: reference,
  };
  for (var index = 0; index < input.saveSnapshots.length; index++) {
    final snapshot = input.saveSnapshots[index];
    final saveId = snapshot['saveId'];
    if (saveId is! String || saveId.isEmpty || saveId.trim() != saveId) {
      record(
        'Every save snapshot requires a non-empty trimmed saveId.',
        'saveSnapshots[$index].saveId',
      );
      continue;
    }
    if (saveHashes.containsKey(saveId)) {
      record(
        'Save snapshot IDs must be unique.',
        'saveSnapshots[$index].saveId',
      );
      continue;
    }
    saveHashes[saveId] = _jsonFingerprint(snapshot);
    final consumedEventIds = snapshot['consumedEventIds'];
    if (consumedEventIds == null) continue;
    if (consumedEventIds is! List) {
      record(
        'consumedEventIds must remain a characterized list when present.',
        'saveSnapshots[$index].consumedEventIds',
      );
      continue;
    }
    for (var eventIndex = 0;
        eventIndex < consumedEventIds.length;
        eventIndex++) {
      final legacyEventId = consumedEventIds[eventIndex];
      final path = 'gameStates.$saveId.consumedEventIds[$eventIndex]';
      final reference = referencesByPath[path];
      if (legacyEventId is! String ||
          legacyEventId.isEmpty ||
          legacyEventId.trim() != legacyEventId ||
          reference == null ||
          reference.kind != LegacyEventReferenceKind.consumedEventState ||
          reference.legacyEventId != legacyEventId) {
        record(
          'Every consumed Event save entry requires an exact catalogued '
          'legacy reference.',
          path,
        );
      }
    }
  }
  if (!_sameStringMap(saveHashes, input.currentSnapshot.saveHashes)) {
    record(
      'The save snapshot hashes do not match the supplied saves.',
      'saveHashes',
    );
  }
  return mismatch;
}

bool _recordUnusedChoices(
  NarrativeEventMigrationPlannerInput input,
  List<_Candidate> candidates,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  var invalid = false;
  final candidateProvenances = {
    for (final candidate in candidates) candidate.provenance,
  };
  for (final choice in input.choices.sourceChoices) {
    if (candidateProvenances.contains(choice.provenance)) continue;
    invalid = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unusedChoice,
        LegacyMigrationDiagnosticSeverity.error,
        'The source choice does not match any supplied legacy projection.',
        _provenancePath(choice.provenance),
      ),
    );
  }

  final referencePaths = {
    for (final reference in input.references.all) reference.path,
  };
  for (final choice in input.choices.referenceChoices) {
    if (referencePaths.contains(choice.path)) continue;
    invalid = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unusedChoice,
        LegacyMigrationDiagnosticSeverity.error,
        'The reference choice does not match the supplied reference catalog.',
        choice.path,
      ),
    );
  }
  return invalid;
}

String _jsonFingerprint(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(value)}';

bool _sameStrings(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

bool _isMapProvenance(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (_, __) => true,
    scenarioSourceNode: (_, __) => false,
  );
}

bool _isScenarioProvenance(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (_, __) => false,
    scenarioSourceNode: (_, __) => true,
  );
}

bool _isLegacyScenarioSourceNode(String? actionKind) {
  return const {
    'sourceMapEnter',
    'sourceTriggerEnter',
    'sourceEntityInteract',
    'sourceOutcome',
  }.contains(actionKind);
}

NarrativeEventReferenceMappings _buildReferencePreflightMappings({
  required NarrativeEventMigrationPlannerInput input,
  required List<_Candidate> candidates,
  required List<NarrativeEventPageMapping> pageMappings,
}) {
  final targetsByProvenance = <LegacySourceRef, _PreflightTargets>{};
  for (final candidate in candidates) {
    if (candidate.resolved && candidate.targetEventIds.isNotEmpty) {
      final targetKeys = candidate.targetEventIdsByKey.keys.toSet();
      targetsByProvenance[candidate.provenance] = _PreflightTargets(
        tokens: targetKeys.isNotEmpty
            ? targetKeys
            : candidate.targetEventIds.toSet(),
        targetKeys: targetKeys,
        actualIds: candidate.targetEventIds.toSet(),
      );
      continue;
    }
    final source = candidate.source;
    if (!candidate.canClaim || source == null) {
      targetsByProvenance[candidate.provenance] = _PreflightTargets.empty();
      continue;
    }
    final targetKeys = {
      for (final target in candidate.targets)
        computeNarrativeEventMigrationTargetKey(
          provenance: candidate.provenance,
          targetSignature: target.recordSignature(source),
        ),
    };
    targetsByProvenance[candidate.provenance] = _PreflightTargets(
      tokens: targetKeys,
      targetKeys: targetKeys,
      actualIds: const {},
    );
  }

  final choicesByPath = {
    for (final choice in _effectiveReferenceChoices(input)) choice.path: choice,
  };

  List<NarrativeEventReferenceMapping> resolve(
    NarrativeEventReferenceDomain domain,
    List<LegacyEventReference> references,
  ) {
    final sorted = List<LegacyEventReference>.of(references)
      ..sort((left, right) => left.path.compareTo(right.path));
    return [
      for (final reference in sorted)
        _preflightReference(
          domain: domain,
          reference: reference,
          targetsByProvenance: targetsByProvenance,
          choice: choicesByPath[reference.path],
        ),
    ];
  }

  return NarrativeEventReferenceMappings(
    pageMappings: pageMappings,
    progressionMappings: resolve(
      NarrativeEventReferenceDomain.progression,
      input.references.progression,
    ),
    conditionMappings: resolve(
      NarrativeEventReferenceDomain.condition,
      input.references.conditions,
    ),
    worldRuleMappings: resolve(
      NarrativeEventReferenceDomain.worldRule,
      input.references.worldRules,
    ),
    consequenceMappings: resolve(
      NarrativeEventReferenceDomain.consequence,
      input.references.consequences,
    ),
    saveMappings: resolve(
      NarrativeEventReferenceDomain.save,
      input.references.saves,
    ),
  );
}

NarrativeEventReferenceMapping _preflightReference({
  required NarrativeEventReferenceDomain domain,
  required LegacyEventReference reference,
  required Map<LegacySourceRef, _PreflightTargets> targetsByProvenance,
  required NarrativeEventReferenceResolutionChoice? choice,
}) {
  final tokens = <String>{};
  final targetKeys = <String>{};
  final actualIds = <String>{};
  var everyCandidateHasTargets = true;
  for (final provenance in reference.candidateProvenances) {
    final targets =
        targetsByProvenance[provenance] ?? _PreflightTargets.empty();
    if (targets.tokens.isEmpty) everyCandidateHasTargets = false;
    tokens.addAll(targets.tokens);
    targetKeys.addAll(targets.targetKeys);
    actualIds.addAll(targets.actualIds);
  }

  NarrativeEventReferenceMapping result(
    NarrativeEventReferenceMappingStatus status, {
    NarrativeEventReferenceCollisionDecision? decision,
  }) {
    return NarrativeEventReferenceMapping(
      domain: domain,
      kind: reference.kind,
      path: reference.path,
      legacyEventId: reference.legacyEventId,
      mapId: reference.mapId,
      candidateProvenances: reference.candidateProvenances,
      targetEventIds: const [],
      availableTargetKeys: targetKeys.toList(),
      status: status,
      decision: decision,
    );
  }

  if (reference.candidateProvenances.isEmpty) {
    return result(
      domain == NarrativeEventReferenceDomain.progression ||
              domain == NarrativeEventReferenceDomain.save
          ? NarrativeEventReferenceMappingStatus.preservedTombstone
          : NarrativeEventReferenceMappingStatus.blocked,
    );
  }
  if (choice == null) {
    if (reference.candidateProvenances.length > 1 || tokens.length > 1) {
      return result(NarrativeEventReferenceMappingStatus.requiresChoice);
    }
    return result(
      tokens.length == 1
          ? NarrativeEventReferenceMappingStatus.readyForAllocation
          : NarrativeEventReferenceMappingStatus.blocked,
    );
  }

  switch (choice.decision) {
    case NarrativeEventReferenceCollisionDecision.cancel:
      return result(
        NarrativeEventReferenceMappingStatus.cancelled,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.consumeAllTargets:
      final domainAllowsAll =
          domain == NarrativeEventReferenceDomain.progression ||
              domain == NarrativeEventReferenceDomain.save;
      return result(
        domainAllowsAll && everyCandidateHasTargets && tokens.isNotEmpty
            ? NarrativeEventReferenceMappingStatus.readyForAllocation
            : NarrativeEventReferenceMappingStatus.blocked,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.selectedTargets:
      if (choice.selectedTargetKeys.isNotEmpty) {
        final exactStableSelection = choice.selectedTargetKeys.every(
          targetKeys.contains,
        );
        return result(
          exactStableSelection
              ? NarrativeEventReferenceMappingStatus.readyForAllocation
              : NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      final exactExistingSelection = choice.selectedTargetEventIds.every(
        actualIds.contains,
      );
      return result(
        exactExistingSelection
            ? NarrativeEventReferenceMappingStatus.readyForAllocation
            : NarrativeEventReferenceMappingStatus.blocked,
        decision: choice.decision,
      );
  }
}

void _recordBlockingReferenceDiagnostics(
  NarrativeEventReferenceMappings mappings,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  for (final mapping in mappings.allReferenceMappings) {
    if (mapping.status == NarrativeEventReferenceMappingStatus.mapped ||
        mapping.status ==
            NarrativeEventReferenceMappingStatus.readyForAllocation ||
        mapping.status ==
            NarrativeEventReferenceMappingStatus.preservedTombstone) {
      continue;
    }
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unresolvedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'The legacy reference requires an explicit valid mapping.',
        mapping.path,
      ),
    );
  }
}

final class _PreflightTargets {
  const _PreflightTargets({
    required this.tokens,
    required this.targetKeys,
    required this.actualIds,
  });

  const _PreflightTargets.empty()
      : tokens = const {},
        targetKeys = const {},
        actualIds = const {};

  final Set<String> tokens;
  final Set<String> targetKeys;
  final Set<String> actualIds;
}

List<_Candidate> _buildCandidates(NarrativeEventMigrationPlannerInput input) {
  final result = <_Candidate>[];
  for (final projection in input.mapEventProjections) {
    final choice = input.choices.sourceChoiceFor(projection.provenance);
    final candidateDiagnostics = <LegacyMigrationDiagnostic>[
      ...projection.diagnostics,
    ];
    final confirmed = projection.confirmedSource;
    final existingSource = projection.existingClaim?.source;
    var source = confirmed ?? choice?.source ?? existingSource;
    var hardBlocked = _isHardClassification(projection.classification) ||
        projection.claimStatus == LegacyProjectionClaimStatus.invalid ||
        (projection.claimStatus == LegacyProjectionClaimStatus.valid &&
            projection.existingClaim == null);
    if (confirmed != null && choice != null && confirmed != choice.source) {
      hardBlocked = true;
      source = confirmed;
    }
    final targets = <NarrativeEventMigrationTargetProposal>[];
    var assistancePending = false;
    var choiceApplied = false;
    if (projection.classification == LegacyMigrationClassification.autoSafe) {
      final target = _autoMapTarget(projection);
      if (source == null || target == null) {
        hardBlocked = true;
      } else if (choice == null) {
        assistancePending = true;
        targets.add(target);
      } else if (!_mapLifecycleChoiceMatches(choice, target, source)) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The MapEvent choice changes more than its unresolved lifecycle.',
            _provenancePath(projection.provenance),
          ),
        );
      } else {
        choiceApplied = true;
        targets.addAll(choice.targets);
      }
    } else if (projection.classification ==
        LegacyMigrationClassification.assisted) {
      if (choice != null) {
        choiceApplied = true;
        source = choice.source;
        targets.addAll(choice.targets);
        assistancePending = targets.any((target) => !target.isConfigured);
      } else {
        assistancePending = true;
        targets.add(_draftMapTarget(projection));
      }
    } else if (choice != null) {
      hardBlocked = true;
      candidateDiagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unusedChoice,
          LegacyMigrationDiagnosticSeverity.error,
          'A source choice cannot override a blocked legacy projection.',
          _provenancePath(projection.provenance),
        ),
      );
    }
    result.add(
      _Candidate(
        provenance: projection.provenance,
        classification: projection.classification,
        source: source,
        sourceFingerprint: projection.sourceFingerprint,
        choiceApplied: choiceApplied,
        assistancePending: assistancePending,
        hardBlocked: hardBlocked,
        targets: targets,
        mapProjection: projection,
        diagnostics: candidateDiagnostics,
      ),
    );
  }
  for (final projection in input.scenarioProjections) {
    final choice = input.choices.sourceChoiceFor(projection.provenance);
    final candidateDiagnostics = <LegacyMigrationDiagnostic>[
      ...projection.diagnostics,
    ];
    final projectedSource = projection.source;
    final existingSource = projection.existingClaim?.source;
    var source = projectedSource ?? choice?.source ?? existingSource;
    var hardBlocked = _isHardClassification(projection.classification) ||
        projection.claimStatus == LegacyProjectionClaimStatus.invalid ||
        (projection.claimStatus == LegacyProjectionClaimStatus.valid &&
            projection.existingClaim == null);
    if (projectedSource != null &&
        choice != null &&
        projectedSource != choice.source) {
      hardBlocked = true;
      source = projectedSource;
    }
    final targets = <NarrativeEventMigrationTargetProposal>[];
    var assistancePending = false;
    var choiceApplied = false;
    if (projection.classification == LegacyMigrationClassification.autoSafe) {
      final target = _autoScenarioTarget(projection);
      if (source == null || target == null) {
        hardBlocked = true;
      } else if (choice != null) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.unusedChoice,
            LegacyMigrationDiagnosticSeverity.error,
            'An AUTO_SAFE Scenario projection does not accept target overrides.',
            _provenancePath(projection.provenance),
          ),
        );
      } else {
        targets.add(target);
      }
    } else if (projection.classification ==
        LegacyMigrationClassification.assisted) {
      if (choice != null) {
        choiceApplied = true;
        source = choice.source;
        targets.addAll(choice.targets);
        assistancePending = targets.any((target) => !target.isConfigured);
      } else {
        assistancePending = true;
        targets.add(_draftScenarioTarget(projection));
      }
    } else if (choice != null) {
      hardBlocked = true;
      candidateDiagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unusedChoice,
          LegacyMigrationDiagnosticSeverity.error,
          'A source choice cannot override a blocked legacy projection.',
          _provenancePath(projection.provenance),
        ),
      );
    }
    result.add(
      _Candidate(
        provenance: projection.provenance,
        classification: projection.classification,
        source: source,
        sourceFingerprint: projection.sourceFingerprint,
        choiceApplied: choiceApplied,
        assistancePending: assistancePending,
        hardBlocked: hardBlocked,
        targets: targets,
        scenarioProjection: projection,
        diagnostics: candidateDiagnostics,
      ),
    );
  }
  return result;
}

NarrativeEventMigrationTargetProposal? _autoMapTarget(
  LegacyMapEventProjection projection,
) {
  if (projection.pages.length != 1) return null;
  final page = projection.pages.single;
  if (page.sceneId == null ||
      page.condition != null ||
      page.script != null ||
      page.message != null ||
      page.isHidden ||
      page.isDisabled) {
    return null;
  }
  return NarrativeEventMigrationTargetProposal(
    name: _mapProjectionName(projection),
    legacyPageIndex: page.pageIndex,
    conditions: const [],
    sceneId: page.sceneId,
    reusePolicy: null,
    priority: 0,
    order: page.pageIndex,
  );
}

bool _mapLifecycleChoiceMatches(
  NarrativeEventMigrationSourceChoice choice,
  NarrativeEventMigrationTargetProposal projected,
  NarrativeEventSourceRef source,
) {
  if (choice.source != source || choice.targets.length != 1) return false;
  final selected = choice.targets.single;
  return selected.name == projected.name &&
      selected.legacyPageIndex == projected.legacyPageIndex &&
      selected.sceneId == projected.sceneId &&
      selected.reusePolicy != null &&
      selected.priority == projected.priority &&
      selected.order == projected.order &&
      canonicalizeNarrativeEventJson([
            for (final condition in selected.conditions) condition.toJson(),
          ]) ==
          canonicalizeNarrativeEventJson([
            for (final condition in projected.conditions) condition.toJson(),
          ]);
}

NarrativeEventMigrationTargetProposal _draftMapTarget(
  LegacyMapEventProjection projection,
) {
  final page = projection.pages.length == 1 ? projection.pages.single : null;
  return NarrativeEventMigrationTargetProposal(
    name: _mapProjectionName(projection),
    legacyPageIndex: page?.pageIndex,
    conditions: const [],
    sceneId: page?.sceneId,
    reusePolicy: null,
    priority: 0,
    order: page?.pageIndex ?? 0,
  );
}

NarrativeEventMigrationTargetProposal? _autoScenarioTarget(
  LegacyScenarioSourceProjection projection,
) {
  final sceneId = projection.sceneCandidateId;
  final reusePolicy = projection.reusePolicyCandidate;
  if (sceneId == null || reusePolicy == null) return null;
  return NarrativeEventMigrationTargetProposal(
    name: _scenarioProjectionName(projection),
    conditions: const [],
    sceneId: sceneId,
    reusePolicy: reusePolicy,
    priority: 0,
    order: 0,
  );
}

bool _scenarioAssistedChoiceMatchesProjection(
  LegacyScenarioSourceProjection projection,
  NarrativeEventMigrationSourceChoice choice,
) {
  if (choice.targets.length != 1) return false;
  final selected = choice.targets.single;
  final projectedReusePolicy = projection.reusePolicyCandidate;
  return selected.name == _scenarioProjectionName(projection) &&
      selected.legacyPageIndex == null &&
      selected.conditions.isEmpty &&
      selected.sceneId == projection.sceneCandidateId &&
      (projectedReusePolicy == null
          ? selected.reusePolicy != null
          : selected.reusePolicy == projectedReusePolicy) &&
      selected.priority == 0 &&
      selected.order == 0;
}

NarrativeEventMigrationTargetProposal _draftScenarioTarget(
  LegacyScenarioSourceProjection projection,
) {
  return NarrativeEventMigrationTargetProposal(
    name: _scenarioProjectionName(projection),
    conditions: const [],
    sceneId: projection.sceneCandidateId,
    reusePolicy: projection.reusePolicyCandidate,
    priority: 0,
    order: 0,
  );
}

List<_Group> _buildGroups(List<_Candidate> candidates) {
  final bySource = <String, _Group>{};
  for (final candidate in candidates) {
    final source = candidate.source;
    if (source == null) continue;
    final key = canonicalizeNarrativeEventJson(source.toJson());
    bySource.putIfAbsent(key, () => _Group(source)).candidates.add(candidate);
  }
  final keys = bySource.keys.toList()..sort();
  return [
    for (final key in keys) bySource[key]!..finalize(),
  ];
}

void _resolveExistingClaim(
  _Group group,
  NarrativeEventRegistry? registry,
  NarrativeEventMigrationReceipt? existingReceipt,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  if (registry == null) return;
  final expectedProvenances = {
    for (final member in group.members) member.provenance,
  };
  final relevant = registry.legacyClaims.where((claim) {
    if (claim.source == group.source) return true;
    return claim.members.any(
      (member) => expectedProvenances.contains(member.provenance),
    );
  }).toList();
  if (relevant.isEmpty) return;
  if (relevant.length == 1 && _isExactClaim(relevant.single, group, registry)) {
    final claim = relevant.single;
    group.existingClaim = claim;
    group.targetEventIds = claim.targetEventIds;
    group.hardBlocked =
        group.candidates.any((candidate) => candidate.hardBlocked);
    final recordsById = {
      for (final record in registry.records) record.id: record,
    };
    for (final candidate in group.candidates) {
      final receiptMappings = existingReceipt?.mappings.idMappings
              .where((mapping) => mapping.provenance == candidate.provenance)
              .toList(growable: false) ??
          const <NarrativeEventIdMapping>[];
      final receiptTargetIds = receiptMappings.length == 1 &&
              receiptMappings.single.targetEventIds.every(
                claim.targetEventIds.contains,
              )
          ? receiptMappings.single.targetEventIds
          : null;
      final configuredTargets = candidate.assistancePending
          ? const <NarrativeEventMigrationTargetProposal>[]
          : [
              for (final target in candidate.targets)
                if (target.isConfigured) target,
            ];
      candidate.targetEventIds = [];
      candidate.targetEventIdsByKey.clear();
      if (configuredTargets.isEmpty) {
        if (receiptTargetIds == null) {
          candidate.targetEventIds = List.of(claim.targetEventIds);
        } else {
          for (final targetId in receiptTargetIds) {
            candidate.addTarget(
              _targetProposalFromDefinition(
                recordsById[targetId]!.definitionOrNull!,
              ),
              targetId,
            );
          }
        }
      } else {
        for (final target in configuredTargets) {
          final signature = target.recordSignature(group.source);
          final matchingIds = [
            for (final targetId in claim.targetEventIds)
              if (_recordSignature(recordsById[targetId]!) == signature)
                targetId,
          ];
          if (matchingIds.length == 1) {
            candidate.addTarget(target, matchingIds.single);
          }
        }
      }
      candidate.resolved = true;
      candidate.pageTargetIds.clear();
      if (receiptTargetIds != null && existingReceipt != null) {
        for (final pageMapping in existingReceipt.mappings.pageMappings) {
          final targetId = pageMapping.targetEventId;
          if (pageMapping.provenance == candidate.provenance &&
              pageMapping.status == NarrativeEventPageMappingStatus.mapped &&
              targetId != null &&
              candidate.targetEventIds.contains(targetId)) {
            candidate.pageTargetIds[pageMapping.pageIndex] = [targetId];
          }
        }
      }
      if (candidate.mapProjection?.pages.length == 1 &&
          candidate.targetEventIds.length == 1 &&
          candidate.pageTargetIds.isEmpty) {
        candidate
            .pageTargetIds[candidate.mapProjection!.pages.single.pageIndex] = [
          candidate.targetEventIds.single
        ];
      }
    }
    return;
  }
  group.hardBlocked = true;
  for (final candidate in group.candidates) {
    candidate.hardBlocked = true;
  }
  diagnostics.add(
    _diagnostic(
      NarrativeEventMigrationDiagnosticCodes.partialClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'An existing claim overlaps this source without covering the exact '
          'complete cohort and valid targets.',
      'eventRegistry.legacyClaims.${group.cohortId}',
    ),
  );
}

bool _isExactClaim(
  LegacySourceClaim claim,
  _Group group,
  NarrativeEventRegistry registry,
) {
  if (claim.source != group.source || claim.cohortId != group.cohortId) {
    return false;
  }
  if (claim.members.length != group.members.length) return false;
  for (var index = 0; index < group.members.length; index++) {
    if (claim.members[index] != group.members[index]) return false;
  }
  final actualSignatures = <String>[];
  for (final targetId in claim.targetEventIds) {
    final matches = registry.records.where((record) => record.id == targetId);
    if (matches.length != 1) return false;
    final record = matches.single;
    if (record.enabledOrNull == true) return false;
    final definition = record.definitionOrNull;
    if (definition == null || definition.source != group.source) return false;
    actualSignatures.add(_recordSignature(record));
  }
  final expectedSignatures = <String>{
    for (final candidate in group.candidates)
      if (!candidate.assistancePending)
        for (final target in candidate.targets)
          if (target.isConfigured) target.recordSignature(group.source),
  };
  if (actualSignatures.length != actualSignatures.toSet().length ||
      (expectedSignatures.isNotEmpty &&
          !_sameStrings(expectedSignatures, actualSignatures.toSet()))) {
    return false;
  }
  return true;
}

String _recordSignature(NarrativeEventRecord record) {
  final definition = record.definitionOrNull;
  if (definition == null) return 'draft:${record.id}';
  return canonicalizeNarrativeEventJson({
    'name': definition.name,
    'source': definition.source.toJson(),
    'conditions': [
      for (final condition in definition.conditions) condition.toJson(),
    ],
    'sceneId': definition.sceneId,
    'reusePolicy': definition.reusePolicy.name,
    'priority': definition.priority,
    'order': definition.order,
  });
}

bool _matchesAppliedReceipt({
  required NarrativeEventMigrationPlannerInput input,
  required NarrativeEventRegistry registry,
  required List<_Candidate> candidates,
  required List<LegacySourceClaim> existingClaims,
  required NarrativeEventMigrationReceipt receipt,
}) {
  if (!receipt.isProposal ||
      receipt.lifecycle.status !=
          NarrativeEventMigrationReceiptStatus.prepared) {
    return false;
  }
  final expectedAtomicity =
      NarrativeEventMigrationAtomicityPlan.phaseCProposal();
  final expectedRollback = NarrativeEventMigrationRollbackPlan.phaseCProposal();
  final expectedPointOfNoReturn =
      NarrativeEventMigrationPointOfNoReturn.phaseCProposal();
  if (canonicalizeNarrativeEventJson(receipt.backupPlan.toJson()) !=
          canonicalizeNarrativeEventJson(input.backupPlan.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.atomicityPlan.toJson()) !=
          canonicalizeNarrativeEventJson(expectedAtomicity.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.rollbackPlan.toJson()) !=
          canonicalizeNarrativeEventJson(expectedRollback.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.pointOfNoReturn.toJson()) !=
          canonicalizeNarrativeEventJson(expectedPointOfNoReturn.toJson())) {
    return false;
  }
  if (receipt.expectedManifestHashAfter != input.currentSnapshot.manifestHash ||
      receipt.expectedManifestHashAfter !=
          _jsonFingerprint(input.project.toJson()) ||
      receipt.expectedRegistryHashAfter !=
          _jsonFingerprint(registry.toJson())) {
    return false;
  }
  final before = receipt.snapshot;
  final current = input.currentSnapshot;
  if (before.projectRevisionToken != current.projectRevisionToken ||
      before.corpusHash != current.corpusHash ||
      before.referenceCatalogHash != current.referenceCatalogHash ||
      !_sameStringMap(before.mapHashes, current.mapHashes) ||
      !_sameStringMap(
        before.legacySourceHashes,
        current.legacySourceHashes,
      ) ||
      !_sameStringMap(before.saveHashes, current.saveHashes)) {
    return false;
  }

  final sortedExistingClaims = List<LegacySourceClaim>.of(existingClaims)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  if (!_sameCanonicalValues(sortedExistingClaims, receipt.targetClaims)) {
    return false;
  }
  final recordsById = {
    for (final record in registry.records) record.id: record
  };
  for (final expected in receipt.targetRecords) {
    final actual = recordsById[expected.id];
    if (actual == null ||
        canonicalizeNarrativeEventJson(actual.toJson()) !=
            canonicalizeNarrativeEventJson(expected.toJson())) {
      return false;
    }
  }
  if (!_receiptTargetsMatchCurrentEvidence(
    input: input,
    candidates: candidates,
    registry: registry,
    receipt: receipt,
  )) {
    return false;
  }
  final targetsByProvenance = <LegacySourceRef, List<String>>{
    for (final candidate in candidates)
      if (candidate.resolved && candidate.targetEventIds.isNotEmpty)
        candidate.provenance: candidate.targetEventIds,
  };
  final expectedMappings = buildNarrativeEventReferenceMappings(
    targetEventIdsByProvenance: targetsByProvenance,
    targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
    references: input.references,
    choices: _effectiveReferenceChoices(input),
    idMappings: _buildIdMappings(candidates),
    pageMappings: _buildPageMappings(candidates),
  );
  if (expectedMappings.hasBlockingMappings ||
      canonicalizeNarrativeEventJson(expectedMappings.toJson()) !=
          canonicalizeNarrativeEventJson(receipt.mappings.toJson())) {
    return false;
  }
  return true;
}

List<NarrativeEventReferenceResolutionChoice> _effectiveReferenceChoices(
  NarrativeEventMigrationPlannerInput input,
) {
  final choicesByPath = <String, NarrativeEventReferenceResolutionChoice>{
    for (final choice in input.choices.referenceChoices) choice.path: choice,
  };
  final receipt = input.existingReceipt;
  if (receipt != null) {
    for (final mapping in receipt.mappings.allReferenceMappings) {
      final decision = mapping.decision;
      if (mapping.status != NarrativeEventReferenceMappingStatus.mapped ||
          decision == null ||
          choicesByPath.containsKey(mapping.path) ||
          (decision ==
                  NarrativeEventReferenceCollisionDecision.selectedTargets &&
              mapping.targetEventIds.isEmpty)) {
        continue;
      }
      choicesByPath[mapping.path] = switch (decision) {
        NarrativeEventReferenceCollisionDecision.consumeAllTargets =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
          ),
        NarrativeEventReferenceCollisionDecision.selectedTargets =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
            selectedTargetEventIds: mapping.targetEventIds,
          ),
        NarrativeEventReferenceCollisionDecision.cancel =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
          ),
      };
    }
  }
  final paths = choicesByPath.keys.toList()..sort();
  return [for (final path in paths) choicesByPath[path]!];
}

bool _receiptTargetsMatchCurrentEvidence({
  required NarrativeEventMigrationPlannerInput input,
  required List<_Candidate> candidates,
  required NarrativeEventRegistry registry,
  required NarrativeEventMigrationReceipt receipt,
}) {
  final claimedProvenances = <LegacySourceRef>{
    for (final claim in receipt.targetClaims)
      for (final member in claim.members) member.provenance,
  };
  for (final claim in receipt.targetClaims) {
    final mappedTargetIds = <String>{};
    for (final member in claim.members) {
      final mappings = receipt.mappings.idMappings
          .where((mapping) => mapping.provenance == member.provenance)
          .toList(growable: false);
      if (mappings.length != 1 ||
          mappings.single.targetEventIds.any(
            (targetId) => !claim.targetEventIds.contains(targetId),
          )) {
        return false;
      }
      mappedTargetIds.addAll(mappings.single.targetEventIds);
    }
    if (!_sameStrings(mappedTargetIds, claim.targetEventIds.toSet())) {
      return false;
    }
  }
  final recordsById = <String, List<NarrativeEventRecord>>{};
  for (final record in registry.records) {
    recordsById.putIfAbsent(record.id, () => []).add(record);
  }
  final scenesById = <String, List<SceneAsset>>{};
  for (final scene in input.project.scenes) {
    scenesById.putIfAbsent(scene.id, () => []).add(scene);
  }
  final scenariosById = <String, List<ScenarioAsset>>{};
  for (final scenario in input.project.scenarios) {
    scenariosById.putIfAbsent(scenario.id, () => []).add(scenario);
  }

  for (final candidate in candidates) {
    if (!claimedProvenances.contains(candidate.provenance)) continue;
    final mappingMatches = receipt.mappings.idMappings
        .where((mapping) => mapping.provenance == candidate.provenance)
        .toList(growable: false);
    if (mappingMatches.length != 1) return false;
    final definitions = <NarrativeEventDefinition>[];
    for (final targetId in mappingMatches.single.targetEventIds) {
      final recordMatches =
          recordsById[targetId] ?? const <NarrativeEventRecord>[];
      if (recordMatches.length != 1 ||
          recordMatches.single.enabledOrNull == true) {
        return false;
      }
      final definition = recordMatches.single.definitionOrNull;
      final source = candidate.source;
      if (definition == null || source == null || definition.source != source) {
        return false;
      }
      final sceneMatches =
          scenesById[definition.sceneId] ?? const <SceneAsset>[];
      if (sceneMatches.length != 1 ||
          !buildSceneRuntimePlan(sceneMatches.single).canBuild) {
        return false;
      }
      definitions.add(definition);
    }
    if (definitions.isEmpty) return false;

    final valid = candidate.provenance.when(
      mapEvent: (_, __) => _receiptMapTargetsMatchCurrentEvidence(
        candidate,
        definitions,
      ),
      scenarioSourceNode: (scenarioId, nodeId) {
        final scenarioMatches =
            scenariosById[scenarioId] ?? const <ScenarioAsset>[];
        final projection = candidate.scenarioProjection;
        if (scenarioMatches.length != 1 || projection == null) return false;
        final scenario = scenarioMatches.single;
        for (final definition in definitions) {
          final scene = scenesById[definition.sceneId]!.single;
          if (!hasEquivalentLegacyScenarioSceneCandidate(
            scenario: scenario,
            sourceNodeId: nodeId,
            scene: scene,
          )) {
            return false;
          }
        }
        final targets = [
          for (final definition in definitions)
            _targetProposalFromDefinition(definition),
        ];
        switch (candidate.classification) {
          case LegacyMigrationClassification.autoSafe:
            final projected = _autoScenarioTarget(projection);
            return projected != null &&
                targets.length == 1 &&
                targets.single.recordSignature(definitions.single.source) ==
                    projected.recordSignature(definitions.single.source);
          case LegacyMigrationClassification.assisted:
            return isCompatibleLegacyScenarioSourceChoice(
                  projection: projection,
                  scenario: scenario,
                  selectedSource: definitions.single.source,
                ) &&
                _scenarioAssistedChoiceMatchesProjection(
                  projection,
                  NarrativeEventMigrationSourceChoice(
                    provenance: candidate.provenance,
                    source: definitions.single.source,
                    targets: targets,
                  ),
                );
          case LegacyMigrationClassification.blocked:
          case LegacyMigrationClassification.unsupported:
          case LegacyMigrationClassification.legacyOnly:
            return false;
        }
      },
    );
    if (!valid) return false;
  }
  return true;
}

bool _receiptMapTargetsMatchCurrentEvidence(
  _Candidate candidate,
  List<NarrativeEventDefinition> definitions,
) {
  final projection = candidate.mapProjection;
  final source = candidate.source;
  if (projection == null || source == null) return false;
  switch (candidate.classification) {
    case LegacyMigrationClassification.autoSafe:
      final projected = _autoMapTarget(projection);
      if (projected == null) return false;
      return _mapLifecycleChoiceMatches(
        NarrativeEventMigrationSourceChoice(
          provenance: candidate.provenance,
          source: source,
          targets: [
            for (final definition in definitions)
              _targetProposalFromDefinition(
                definition,
                legacyPageIndex: projected.legacyPageIndex,
              ),
          ],
        ),
        projected,
        source,
      );
    case LegacyMigrationClassification.assisted:
      return true;
    case LegacyMigrationClassification.blocked:
    case LegacyMigrationClassification.unsupported:
    case LegacyMigrationClassification.legacyOnly:
      return false;
  }
}

NarrativeEventMigrationTargetProposal _targetProposalFromDefinition(
  NarrativeEventDefinition definition, {
  int? legacyPageIndex,
}) {
  return NarrativeEventMigrationTargetProposal(
    name: definition.name,
    legacyPageIndex: legacyPageIndex,
    conditions: definition.conditions,
    sceneId: definition.sceneId,
    reusePolicy: definition.reusePolicy,
    priority: definition.priority,
    order: definition.order,
  );
}

String _corpusReferenceKind(LegacyEventReferenceKind kind) {
  return switch (kind) {
    LegacyEventReferenceKind.consumedEventState => 'GameState.consumedEventIds',
    LegacyEventReferenceKind.scriptCondition => 'ScriptCondition',
    LegacyEventReferenceKind.worldRuleSource => 'WorldRuleDefinition.source',
    LegacyEventReferenceKind.worldRuleTarget => 'WorldRuleDefinition.target',
    LegacyEventReferenceKind.sceneConsequence => 'SceneConsequence',
    LegacyEventReferenceKind.scenarioNodeBinding => 'ScenarioNodeBinding',
    LegacyEventReferenceKind.scriptCommand => 'ScriptCommand',
    LegacyEventReferenceKind.metadata => 'metadata',
    LegacyEventReferenceKind.validatorDiagnostic => 'EventSceneLinkDiagnostic',
  };
}

String _corpusCandidateLabel(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => '$mapId:$eventId',
    scenarioSourceNode: (scenarioId, nodeId) =>
        'scenarioSourceNode:$scenarioId:$nodeId',
  );
}

bool _sameCanonicalValues(List<Object> left, List<Object> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final leftJson = switch (left[index]) {
      LegacySourceClaim value => value.toJson(),
      NarrativeEventRecord value => value.toJson(),
      _ => throw StateError('Unsupported canonical comparison value.'),
    };
    final rightJson = switch (right[index]) {
      LegacySourceClaim value => value.toJson(),
      NarrativeEventRecord value => value.toJson(),
      _ => throw StateError('Unsupported canonical comparison value.'),
    };
    if (canonicalizeNarrativeEventJson(leftJson) !=
        canonicalizeNarrativeEventJson(rightJson)) {
      return false;
    }
  }
  return true;
}

List<NarrativeEventPageMapping> _buildPageMappings(
  List<_Candidate> candidates,
) {
  final result = <NarrativeEventPageMapping>[];
  for (final candidate in candidates) {
    final projection = candidate.mapProjection;
    if (projection == null) continue;
    for (final page in projection.pages) {
      final targets = candidate.pageTargetIds[page.pageIndex] ?? const [];
      final canMap = candidate.resolved && targets.length == 1;
      result.add(
        NarrativeEventPageMapping(
          provenance: candidate.provenance,
          pageIndex: page.pageIndex,
          pageNumber: page.pageNumber,
          status: canMap
              ? NarrativeEventPageMappingStatus.mapped
              : NarrativeEventPageMappingStatus.preservedLegacy,
          targetEventId: canMap ? targets.single : null,
          sceneId: canMap ? page.sceneId : null,
          preservedPageJson: page.toJson(),
        ),
      );
    }
  }
  result.sort((left, right) {
    final provenance = compareLegacySourceRefs(
      left.provenance,
      right.provenance,
    );
    if (provenance != 0) return provenance;
    return left.pageIndex.compareTo(right.pageIndex);
  });
  return result;
}

void _addClassificationDiagnostic(
  _Candidate candidate,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  final path = _provenancePath(candidate.provenance);
  switch (candidate.classification) {
    case LegacyMigrationClassification.autoSafe:
      if (candidate.hardBlocked) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.blockedProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The AUTO_SAFE projection lacks a complete exact V2 target.',
            path,
          ),
        );
      } else if (candidate.assistancePending) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.lifecycleChoiceRequired,
            LegacyMigrationDiagnosticSeverity.warning,
            'The legacy MapEvent lifecycle must be chosen explicitly.',
            path,
          ),
        );
      }
    case LegacyMigrationClassification.assisted:
      if (candidate.assistancePending) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.assistanceRequired,
            LegacyMigrationDiagnosticSeverity.warning,
            'This projection requires an explicit source or target choice.',
            path,
          ),
        );
      }
    case LegacyMigrationClassification.blocked:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.blockedProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy projection remains blocked.',
          path,
        ),
      );
    case LegacyMigrationClassification.unsupported:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unsupportedProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy behavior is outside the V0 migration contract.',
          path,
        ),
      );
    case LegacyMigrationClassification.legacyOnly:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.legacyOnlyProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy behavior must remain under its compatibility adapter.',
          path,
        ),
      );
  }
}

LegacyMigrationDiagnostic _diagnostic(
  String code,
  LegacyMigrationDiagnosticSeverity severity,
  String message,
  String path,
) {
  return LegacyMigrationDiagnostic(
    code: code,
    severity: severity,
    message: message,
    path: path,
  );
}

void _sortDiagnostics(List<LegacyMigrationDiagnostic> diagnostics) {
  diagnostics.sort((left, right) {
    var comparison = left.path.compareTo(right.path);
    if (comparison != 0) return comparison;
    comparison = left.code.compareTo(right.code);
    if (comparison != 0) return comparison;
    return left.message.compareTo(right.message);
  });
}

bool _isHardClassification(LegacyMigrationClassification value) {
  return value == LegacyMigrationClassification.blocked ||
      value == LegacyMigrationClassification.unsupported ||
      value == LegacyMigrationClassification.legacyOnly;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

int _compareCandidates(_Candidate left, _Candidate right) =>
    compareLegacySourceRefs(left.provenance, right.provenance);

String _mapProjectionName(LegacyMapEventProjection projection) {
  final title = projection.preservedEventJson['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  final name = projection.preservedEventJson['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  return 'Legacy ${_legacyId(projection.provenance)}';
}

String _scenarioProjectionName(LegacyScenarioSourceProjection projection) {
  final name = projection.preservedScenarioJson['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  return 'Legacy ${projection.scenarioId}:${projection.nodeId}';
}

String _legacyId(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => eventId,
    scenarioSourceNode: (scenarioId, nodeId) => '$scenarioId:$nodeId',
  );
}

String _provenancePath(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => 'maps.$mapId.events.$eventId',
    scenarioSourceNode: (scenarioId, nodeId) =>
        'scenarios.$scenarioId.nodes.$nodeId',
  );
}

final class _Candidate {
  _Candidate({
    required this.provenance,
    required this.classification,
    required this.source,
    required this.sourceFingerprint,
    required this.choiceApplied,
    required this.assistancePending,
    required this.hardBlocked,
    required this.targets,
    this.mapProjection,
    this.scenarioProjection,
    required List<LegacyMigrationDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final NarrativeEventSourceRef? source;
  final String sourceFingerprint;
  final bool choiceApplied;
  final bool assistancePending;
  bool hardBlocked;
  final List<NarrativeEventMigrationTargetProposal> targets;
  final LegacyMapEventProjection? mapProjection;
  final LegacyScenarioSourceProjection? scenarioProjection;
  final List<LegacyMigrationDiagnostic> diagnostics;
  List<String> targetEventIds = [];
  final Map<String, String> targetEventIdsByKey = {};
  final Map<int, List<String>> pageTargetIds = {};
  bool resolved = false;

  bool get canClaim =>
      !hardBlocked &&
      !assistancePending &&
      source != null &&
      targets.isNotEmpty &&
      targets.every((target) => target.isConfigured);

  void addTarget(
    NarrativeEventMigrationTargetProposal target,
    String eventId,
  ) {
    if (!targetEventIds.contains(eventId)) targetEventIds.add(eventId);
    targetEventIds.sort();
    final targetSource = source;
    if (targetSource != null) {
      final targetKey = computeNarrativeEventMigrationTargetKey(
        provenance: provenance,
        targetSignature: target.recordSignature(targetSource),
      );
      targetEventIdsByKey[targetKey] = eventId;
    }
    final pageIndex = target.legacyPageIndex;
    if (pageIndex != null) {
      final targets = pageTargetIds.putIfAbsent(pageIndex, () => []);
      if (!targets.contains(eventId)) targets.add(eventId);
      targets.sort();
    }
  }

  NarrativeEventMigrationItem toPublic() {
    return NarrativeEventMigrationItem(
      provenance: provenance,
      classification: classification,
      source: source,
      sourceFingerprint: sourceFingerprint,
      choiceApplied: choiceApplied,
      resolved: resolved,
      targetEventIds: targetEventIds,
    );
  }
}

final class _Group {
  _Group(this.source);

  final NarrativeEventSourceRef source;
  final List<_Candidate> candidates = [];
  late List<LegacySourceClaimMember> members;
  late String cohortId;
  late LegacyMigrationClassification classification;
  bool hardBlocked = false;
  LegacySourceClaim? existingClaim;
  LegacySourceClaim? proposedClaim;
  List<String> targetEventIds = [];

  bool get canProposeClaim =>
      !hardBlocked &&
      existingClaim == null &&
      candidates.isNotEmpty &&
      candidates.every((candidate) => candidate.canClaim);

  void finalize() {
    candidates.sort(_compareCandidates);
    members = [
      for (final candidate in candidates)
        LegacySourceClaimMember(
          provenance: candidate.provenance,
          sourceFingerprint: candidate.sourceFingerprint,
        ),
    ]..sort((left, right) => compareLegacySourceRefs(
          left.provenance,
          right.provenance,
        ));
    cohortId = computeLegacySourceCohortId(
      source,
      [for (final member in members) member.provenance],
    );
    classification = candidates.first.classification;
    for (final candidate in candidates.skip(1)) {
      if (_classificationRank(candidate.classification) >
          _classificationRank(classification)) {
        classification = candidate.classification;
      }
    }
    hardBlocked = candidates.any((candidate) => candidate.hardBlocked);
  }

  NarrativeEventMigrationCohort toPublic() {
    final claim = proposedClaim ?? existingClaim;
    final status = proposedClaim != null
        ? NarrativeEventMigrationCohortClaimStatus.proposed
        : existingClaim != null
            ? NarrativeEventMigrationCohortClaimStatus.existing
            : hardBlocked
                ? NarrativeEventMigrationCohortClaimStatus.blocked
                : NarrativeEventMigrationCohortClaimStatus.absent;
    return NarrativeEventMigrationCohort(
      cohortId: cohortId,
      source: source,
      members: members,
      classification: classification,
      complete: claim != null || canProposeClaim,
      claimStatus: status,
      targetEventIds: targetEventIds,
      claim: claim,
    );
  }
}
````

</details>

### `packages/map_core/lib/src/compatibility/narrative_event_migration_receipt.dart`

SHA-256: `4ddd9630066d70379120d4482ac6cafd16301a2c0799ba33369f6eaa8f2f60ea` — 870 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_reference_mapping.dart';

final RegExp _fingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

String legacyMigrationSourceSnapshotKey(LegacySourceRef provenance) {
  return 'legacySource:${canonicalizeNarrativeEventJson(provenance.toJson())}';
}

@immutable
final class NarrativeEventMigrationSnapshot {
  NarrativeEventMigrationSnapshot({
    required String projectRevisionToken,
    required String manifestHash,
    required String corpusHash,
    required String referenceCatalogHash,
    required Map<String, String> mapHashes,
    required Map<String, String> legacySourceHashes,
    required Map<String, String> saveHashes,
  })  : projectRevisionToken = _identity(
          projectRevisionToken,
          'projectRevisionToken',
        ),
        manifestHash = _fingerprint(manifestHash, 'manifestHash'),
        corpusHash = _fingerprint(corpusHash, 'corpusHash'),
        referenceCatalogHash = _fingerprint(
          referenceCatalogHash,
          'referenceCatalogHash',
        ),
        mapHashes = _fingerprintMap(mapHashes, 'mapHashes'),
        legacySourceHashes = _fingerprintMap(
          legacySourceHashes,
          'legacySourceHashes',
        ),
        saveHashes = _fingerprintMap(saveHashes, 'saveHashes');

  factory NarrativeEventMigrationSnapshot.fromJson(Object? json) {
    final object = _object(json, 'snapshot');
    return NarrativeEventMigrationSnapshot(
      projectRevisionToken: _string(object, 'projectRevisionToken'),
      manifestHash: _string(object, 'manifestHash'),
      corpusHash: _string(object, 'corpusHash'),
      referenceCatalogHash: _string(object, 'referenceCatalogHash'),
      mapHashes: _stringMap(object['mapHashes'], 'mapHashes'),
      legacySourceHashes: _stringMap(
        object['legacySourceHashes'],
        'legacySourceHashes',
      ),
      saveHashes: _stringMap(object['saveHashes'], 'saveHashes'),
    );
  }

  final String projectRevisionToken;
  final String manifestHash;
  final String corpusHash;
  final String referenceCatalogHash;
  final Map<String, String> mapHashes;
  final Map<String, String> legacySourceHashes;
  final Map<String, String> saveHashes;

  bool sameAs(NarrativeEventMigrationSnapshot other) {
    return canonicalizeNarrativeEventJson(toJson()) ==
        canonicalizeNarrativeEventJson(other.toJson());
  }

  Map<String, Object?> toJson() => {
        'projectRevisionToken': projectRevisionToken,
        'manifestHash': manifestHash,
        'corpusHash': corpusHash,
        'referenceCatalogHash': referenceCatalogHash,
        'mapHashes': mapHashes,
        'legacySourceHashes': legacySourceHashes,
        'saveHashes': saveHashes,
      };
}

@immutable
final class NarrativeEventMigrationWritePreconditions {
  NarrativeEventMigrationWritePreconditions({
    required this.snapshot,
    this.requireProjectWritable = true,
    this.requireRegistryMigrationAllowed = true,
    this.requireNoClaimConflicts = true,
  });

  factory NarrativeEventMigrationWritePreconditions.fromJson(Object? json) {
    final object = _object(json, 'writePreconditions');
    return NarrativeEventMigrationWritePreconditions(
      snapshot: NarrativeEventMigrationSnapshot.fromJson(object['snapshot']),
      requireProjectWritable: _boolean(object, 'requireProjectWritable'),
      requireRegistryMigrationAllowed:
          _boolean(object, 'requireRegistryMigrationAllowed'),
      requireNoClaimConflicts: _boolean(object, 'requireNoClaimConflicts'),
    );
  }

  final NarrativeEventMigrationSnapshot snapshot;
  final bool requireProjectWritable;
  final bool requireRegistryMigrationAllowed;
  final bool requireNoClaimConflicts;

  bool matches(NarrativeEventMigrationSnapshot current) =>
      snapshot.sameAs(current);

  Map<String, Object?> toJson() => {
        'snapshot': snapshot.toJson(),
        'requireProjectWritable': requireProjectWritable,
        'requireRegistryMigrationAllowed': requireRegistryMigrationAllowed,
        'requireNoClaimConflicts': requireNoClaimConflicts,
      };
}

@immutable
final class NarrativeEventMigrationBackupPlan {
  NarrativeEventMigrationBackupPlan({
    required Map<String, String> futureDestinations,
    this.createBeforeCommit = true,
    this.noBackupCreatedInPhaseC = true,
  }) : futureDestinations = _identityMap(
          futureDestinations,
          'futureDestinations',
        ) {
    if (!this.futureDestinations.containsKey('manifest') ||
        !this.futureDestinations.containsKey('receipt')) {
      throw ArgumentError(
        'Backup plans require manifest and receipt destinations.',
      );
    }
    if (this.futureDestinations['manifest'] ==
        this.futureDestinations['receipt']) {
      throw ArgumentError(
        'Manifest and receipt backups require distinct destinations.',
      );
    }
    if (!createBeforeCommit || !noBackupCreatedInPhaseC) {
      throw ArgumentError(
        'Phase C backup plans must require a future pre-commit backup and '
        'must not claim that a backup was already created.',
      );
    }
  }

  factory NarrativeEventMigrationBackupPlan.fromJson(Object? json) {
    final object = _object(json, 'backupPlan');
    return NarrativeEventMigrationBackupPlan(
      futureDestinations: _stringMap(
        object['futureDestinations'],
        'futureDestinations',
      ),
      createBeforeCommit: _boolean(object, 'createBeforeCommit'),
      noBackupCreatedInPhaseC: _boolean(
        object,
        'noBackupCreatedInPhaseC',
      ),
    );
  }

  final Map<String, String> futureDestinations;
  final bool createBeforeCommit;
  final bool noBackupCreatedInPhaseC;

  Map<String, Object?> toJson() => {
        'futureDestinations': futureDestinations,
        'createBeforeCommit': createBeforeCommit,
        'noBackupCreatedInPhaseC': noBackupCreatedInPhaseC,
      };
}

enum NarrativeEventMigrationReceiptStatus { prepared, committed, recovered }

@immutable
final class NarrativeEventMigrationReceiptLifecycle {
  NarrativeEventMigrationReceiptLifecycle._({
    required this.status,
    required DateTime preparedAt,
    DateTime? committedAt,
    DateTime? recoveredAt,
  })  : preparedAt = preparedAt.toUtc(),
        committedAt = committedAt?.toUtc(),
        recoveredAt = recoveredAt?.toUtc() {
    if (this.committedAt != null &&
        this.committedAt!.isBefore(this.preparedAt)) {
      throw ArgumentError('committedAt cannot precede preparedAt.');
    }
    final recoveryFloor = this.committedAt ?? this.preparedAt;
    if (this.recoveredAt != null && this.recoveredAt!.isBefore(recoveryFloor)) {
      throw ArgumentError(
        'recoveredAt cannot precede the latest journal state.',
      );
    }
    switch (status) {
      case NarrativeEventMigrationReceiptStatus.prepared:
        if (this.committedAt != null || this.recoveredAt != null) {
          throw ArgumentError(
            'A prepared lifecycle cannot contain later timestamps.',
          );
        }
      case NarrativeEventMigrationReceiptStatus.committed:
        if (this.committedAt == null || this.recoveredAt != null) {
          throw ArgumentError(
            'A committed lifecycle requires only committedAt.',
          );
        }
      case NarrativeEventMigrationReceiptStatus.recovered:
        if (this.recoveredAt == null) {
          throw ArgumentError('A recovered lifecycle requires recoveredAt.');
        }
    }
  }

  factory NarrativeEventMigrationReceiptLifecycle.prepared(
    DateTime preparedAt,
  ) {
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.prepared,
      preparedAt: preparedAt,
    );
  }

  factory NarrativeEventMigrationReceiptLifecycle.fromJson(Object? json) {
    final object = _object(json, 'lifecycle');
    return NarrativeEventMigrationReceiptLifecycle._(
      status: _enumByName(
        NarrativeEventMigrationReceiptStatus.values,
        _string(object, 'status'),
        'lifecycle.status',
      ),
      preparedAt: _dateTime(object, 'preparedAt'),
      committedAt: _optionalDateTime(object['committedAt'], 'committedAt'),
      recoveredAt: _optionalDateTime(object['recoveredAt'], 'recoveredAt'),
    );
  }

  final NarrativeEventMigrationReceiptStatus status;
  final DateTime preparedAt;
  final DateTime? committedAt;
  final DateTime? recoveredAt;

  NarrativeEventMigrationReceiptLifecycle committed(DateTime at) {
    if (status != NarrativeEventMigrationReceiptStatus.prepared) {
      throw StateError('Only a prepared receipt can be committed.');
    }
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.committed,
      preparedAt: preparedAt,
      committedAt: at,
    );
  }

  NarrativeEventMigrationReceiptLifecycle recovered(DateTime at) {
    if (status == NarrativeEventMigrationReceiptStatus.recovered) {
      throw StateError('A recovered receipt cannot be recovered twice.');
    }
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.recovered,
      preparedAt: preparedAt,
      committedAt: committedAt,
      recoveredAt: at,
    );
  }

  Map<String, Object?> toJson() => {
        'status': status.name,
        'preparedAt': preparedAt.toIso8601String(),
        if (committedAt != null) 'committedAt': committedAt!.toIso8601String(),
        if (recoveredAt != null) 'recoveredAt': recoveredAt!.toIso8601String(),
      };
}

@immutable
final class NarrativeEventMigrationAtomicityPlan {
  NarrativeEventMigrationAtomicityPlan({
    required this.claimsMultiFileAtomicity,
    required this.manifestStagingRequired,
    required this.unitRenameOnly,
    required this.legacyMapsRemainUnchanged,
    required this.crashRecoveryUsesJournal,
    required List<String> journalStates,
  }) : journalStates = _identityList(journalStates, 'journalStates');

  factory NarrativeEventMigrationAtomicityPlan.phaseCProposal() {
    return NarrativeEventMigrationAtomicityPlan(
      claimsMultiFileAtomicity: false,
      manifestStagingRequired: true,
      unitRenameOnly: true,
      legacyMapsRemainUnchanged: true,
      crashRecoveryUsesJournal: true,
      journalStates: const ['prepared', 'committed', 'recovered'],
    );
  }

  factory NarrativeEventMigrationAtomicityPlan.fromJson(Object? json) {
    final object = _object(json, 'atomicityPlan');
    return NarrativeEventMigrationAtomicityPlan(
      claimsMultiFileAtomicity: _boolean(object, 'claimsMultiFileAtomicity'),
      manifestStagingRequired: _boolean(object, 'manifestStagingRequired'),
      unitRenameOnly: _boolean(object, 'unitRenameOnly'),
      legacyMapsRemainUnchanged: _boolean(object, 'legacyMapsRemainUnchanged'),
      crashRecoveryUsesJournal: _boolean(object, 'crashRecoveryUsesJournal'),
      journalStates: _stringList(object['journalStates'], 'journalStates'),
    );
  }

  final bool claimsMultiFileAtomicity;
  final bool manifestStagingRequired;
  final bool unitRenameOnly;
  final bool legacyMapsRemainUnchanged;
  final bool crashRecoveryUsesJournal;
  final List<String> journalStates;

  Map<String, Object?> toJson() => {
        'claimsMultiFileAtomicity': claimsMultiFileAtomicity,
        'manifestStagingRequired': manifestStagingRequired,
        'unitRenameOnly': unitRenameOnly,
        'legacyMapsRemainUnchanged': legacyMapsRemainUnchanged,
        'crashRecoveryUsesJournal': crashRecoveryUsesJournal,
        'journalStates': journalStates,
      };
}

@immutable
final class NarrativeEventMigrationRollbackPlan {
  static const phaseCConditions = [
    'The project revision token is unchanged.',
    'Manifest, map, and legacy source hashes still match the receipt.',
    'The future backup was created before commit.',
    'No V2-only progression or reference has crossed the point of no return.',
  ];

  NarrativeEventMigrationRollbackPlan({
    required this.requiresUnchangedRevision,
    required this.requiresMatchingHashes,
    required this.availableBeforePointOfNoReturn,
    required this.availableAfterPointOfNoReturn,
    required this.compensatingMigrationRequiredAfter,
    required List<String> conditions,
  }) : conditions = _identityList(conditions, 'conditions');

  factory NarrativeEventMigrationRollbackPlan.phaseCProposal() {
    return NarrativeEventMigrationRollbackPlan(
      requiresUnchangedRevision: true,
      requiresMatchingHashes: true,
      availableBeforePointOfNoReturn: true,
      availableAfterPointOfNoReturn: false,
      compensatingMigrationRequiredAfter: true,
      conditions: phaseCConditions,
    );
  }

  factory NarrativeEventMigrationRollbackPlan.fromJson(Object? json) {
    final object = _object(json, 'rollbackPlan');
    return NarrativeEventMigrationRollbackPlan(
      requiresUnchangedRevision: _boolean(object, 'requiresUnchangedRevision'),
      requiresMatchingHashes: _boolean(object, 'requiresMatchingHashes'),
      availableBeforePointOfNoReturn:
          _boolean(object, 'availableBeforePointOfNoReturn'),
      availableAfterPointOfNoReturn:
          _boolean(object, 'availableAfterPointOfNoReturn'),
      compensatingMigrationRequiredAfter:
          _boolean(object, 'compensatingMigrationRequiredAfter'),
      conditions: _stringList(object['conditions'], 'conditions'),
    );
  }

  final bool requiresUnchangedRevision;
  final bool requiresMatchingHashes;
  final bool availableBeforePointOfNoReturn;
  final bool availableAfterPointOfNoReturn;
  final bool compensatingMigrationRequiredAfter;
  final List<String> conditions;

  Map<String, Object?> toJson() => {
        'requiresUnchangedRevision': requiresUnchangedRevision,
        'requiresMatchingHashes': requiresMatchingHashes,
        'availableBeforePointOfNoReturn': availableBeforePointOfNoReturn,
        'availableAfterPointOfNoReturn': availableAfterPointOfNoReturn,
        'compensatingMigrationRequiredAfter':
            compensatingMigrationRequiredAfter,
        'conditions': conditions,
      };
}

@immutable
final class NarrativeEventMigrationPointOfNoReturn {
  static const v2OnlyProgressTrigger =
      'firstPersistedV2OnlyProgressOrReferenceNotExactlyRepresentableInLegacy';
  static const phaseCDescription =
      'Rollback stops being lossless after the first persisted V2-only '
      'progression bit or reference that cannot be represented exactly '
      'in legacy storage.';

  NarrativeEventMigrationPointOfNoReturn({
    required String trigger,
    required String description,
    required this.reached,
    required this.compensatingMigrationRequiredAfter,
  })  : trigger = _identity(trigger, 'trigger'),
        description = _identity(description, 'description');

  factory NarrativeEventMigrationPointOfNoReturn.phaseCProposal() {
    return NarrativeEventMigrationPointOfNoReturn(
      trigger: v2OnlyProgressTrigger,
      description: phaseCDescription,
      reached: false,
      compensatingMigrationRequiredAfter: true,
    );
  }

  factory NarrativeEventMigrationPointOfNoReturn.fromJson(Object? json) {
    final object = _object(json, 'pointOfNoReturn');
    return NarrativeEventMigrationPointOfNoReturn(
      trigger: _string(object, 'trigger'),
      description: _string(object, 'description'),
      reached: _boolean(object, 'reached'),
      compensatingMigrationRequiredAfter:
          _boolean(object, 'compensatingMigrationRequiredAfter'),
    );
  }

  final String trigger;
  final String description;
  final bool reached;
  final bool compensatingMigrationRequiredAfter;

  Map<String, Object?> toJson() => {
        'trigger': trigger,
        'description': description,
        'reached': reached,
        'compensatingMigrationRequiredAfter':
            compensatingMigrationRequiredAfter,
      };
}

@immutable
final class NarrativeEventMigrationReceipt {
  static const currentSchemaVersion = 1;
  static const phaseC = 'NS-EVENT-V2-PHASE-C';

  NarrativeEventMigrationReceipt({
    required String receiptId,
    this.schemaVersion = currentSchemaVersion,
    this.phase = phaseC,
    required this.isProposal,
    required this.snapshot,
    required String expectedManifestHashAfter,
    required String expectedRegistryHashAfter,
    required this.lifecycle,
    required List<String> cohortIds,
    required this.mappings,
    required List<NarrativeEventRecord> targetRecords,
    required List<LegacySourceClaim> targetClaims,
    required this.backupPlan,
    required this.writePreconditions,
    required this.atomicityPlan,
    required this.rollbackPlan,
    required this.pointOfNoReturn,
  })  : receiptId = _identity(receiptId, 'receiptId'),
        expectedManifestHashAfter = _fingerprint(
          expectedManifestHashAfter,
          'expectedManifestHashAfter',
        ),
        expectedRegistryHashAfter = _fingerprint(
          expectedRegistryHashAfter,
          'expectedRegistryHashAfter',
        ),
        cohortIds = _sortedUnique(cohortIds, 'cohortIds'),
        targetRecords = _sortedRecords(targetRecords),
        targetClaims = _sortedClaims(targetClaims) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'only schema version 1 is supported',
      );
    }
    if (phase != phaseC) {
      throw ArgumentError.value(phase, 'phase', 'must identify Phase C');
    }
    if (isProposal &&
        lifecycle.status != NarrativeEventMigrationReceiptStatus.prepared) {
      throw ArgumentError(
        'A Phase C proposal must remain in the prepared journal state.',
      );
    }
    if (isProposal &&
        (!backupPlan.noBackupCreatedInPhaseC || pointOfNoReturn.reached)) {
      throw ArgumentError(
        'A Phase C proposal cannot claim a backup or a reached point of no '
        'return.',
      );
    }
    if (!snapshot.sameAs(writePreconditions.snapshot)) {
      throw ArgumentError(
        'Receipt snapshot and write preconditions must be identical.',
      );
    }
    if (!writePreconditions.requireProjectWritable ||
        !writePreconditions.requireRegistryMigrationAllowed ||
        !writePreconditions.requireNoClaimConflicts) {
      throw ArgumentError(
        'Phase C receipts must retain every future write precondition.',
      );
    }
    if (atomicityPlan.claimsMultiFileAtomicity ||
        !atomicityPlan.manifestStagingRequired ||
        !atomicityPlan.unitRenameOnly ||
        !atomicityPlan.legacyMapsRemainUnchanged ||
        !atomicityPlan.crashRecoveryUsesJournal ||
        !_sameStrings(
          atomicityPlan.journalStates,
          const ['prepared', 'committed', 'recovered'],
        )) {
      throw ArgumentError(
        'Phase C receipts cannot claim multi-file atomicity or weaken the '
        'staging journal.',
      );
    }
    if (!rollbackPlan.requiresUnchangedRevision ||
        !rollbackPlan.requiresMatchingHashes ||
        !rollbackPlan.availableBeforePointOfNoReturn ||
        rollbackPlan.availableAfterPointOfNoReturn ||
        !rollbackPlan.compensatingMigrationRequiredAfter ||
        !_sameStrings(
          rollbackPlan.conditions,
          NarrativeEventMigrationRollbackPlan.phaseCConditions,
        )) {
      throw ArgumentError(
        'Phase C rollback is lossless only before the point of no return and '
        'while revision/hash preconditions still match.',
      );
    }
    if (!backupPlan.createBeforeCommit ||
        pointOfNoReturn.trigger !=
            NarrativeEventMigrationPointOfNoReturn.v2OnlyProgressTrigger ||
        pointOfNoReturn.description !=
            NarrativeEventMigrationPointOfNoReturn.phaseCDescription ||
        !pointOfNoReturn.compensatingMigrationRequiredAfter) {
      throw ArgumentError(
        'Phase C backup and point-of-no-return invariants cannot be weakened.',
      );
    }
    for (final mapping in mappings.allReferenceMappings) {
      if (mapping.status == NarrativeEventReferenceMappingStatus.mapped) {
        if (mapping.decision ==
            NarrativeEventReferenceCollisionDecision.cancel) {
          throw ArgumentError(
            'A mapped receipt reference cannot carry a cancel decision.',
          );
        }
        continue;
      }
      if (mapping.status ==
              NarrativeEventReferenceMappingStatus.preservedTombstone &&
          mapping.decision == null) {
        continue;
      }
      throw ArgumentError(
        'Phase C receipts require final mapped or preserved-tombstone '
        'reference mappings.',
      );
    }
    final recordIds = <String>{};
    for (final record in this.targetRecords) {
      if (!recordIds.add(record.id)) {
        throw ArgumentError('Receipt target record IDs must be unique.');
      }
      if (record.enabledOrNull == true) {
        throw ArgumentError(
          'Phase C receipt target records must remain disabled proposals.',
        );
      }
    }
    final claimCohortIds = <String>{};
    final claimedTargetIds = <String>{};
    for (final claim in this.targetClaims) {
      if (!claimCohortIds.add(claim.cohortId)) {
        throw ArgumentError('Receipt target claim cohorts must be unique.');
      }
      claimedTargetIds.addAll(claim.targetEventIds);
    }
    if (claimCohortIds.isEmpty) {
      throw ArgumentError('A migration receipt requires at least one claim.');
    }
    if (!_sameStrings(this.cohortIds, claimCohortIds.toList()..sort())) {
      throw ArgumentError(
        'Receipt cohortIds must exactly match its target claims.',
      );
    }
    if (!_sameStrings(
      recordIds.toList()..sort(),
      claimedTargetIds.toList()..sort(),
    )) {
      throw ArgumentError(
        'Receipt target records must exactly match claimed target IDs.',
      );
    }
    final recordsById = {
      for (final record in this.targetRecords) record.id: record,
    };
    for (final claim in this.targetClaims) {
      if (claim.migrationReceiptId != this.receiptId ||
          !this.cohortIds.contains(claim.cohortId)) {
        throw ArgumentError(
          'Every target claim must belong to this receipt and cohort list.',
        );
      }
      for (final targetId in claim.targetEventIds) {
        final target = recordsById[targetId]?.definitionOrNull;
        if (target == null || target.source != claim.source) {
          throw ArgumentError(
            'Every claim target must be a configured target record with the '
            'same source.',
          );
        }
      }
    }
  }

  factory NarrativeEventMigrationReceipt.fromJson(Object? json) {
    final object = _object(json, 'receipt');
    return NarrativeEventMigrationReceipt(
      receiptId: _string(object, 'receiptId'),
      schemaVersion: _integer(object, 'schemaVersion'),
      phase: _string(object, 'phase'),
      isProposal: _boolean(object, 'isProposal'),
      snapshot: NarrativeEventMigrationSnapshot.fromJson(object['snapshot']),
      expectedManifestHashAfter: _string(
        object,
        'expectedManifestHashAfter',
      ),
      expectedRegistryHashAfter: _string(
        object,
        'expectedRegistryHashAfter',
      ),
      lifecycle: NarrativeEventMigrationReceiptLifecycle.fromJson(
        object['lifecycle'],
      ),
      cohortIds: _stringList(object['cohortIds'], 'cohortIds'),
      mappings: NarrativeEventReferenceMappings.fromJson(object['mappings']),
      targetRecords: _list(object['targetRecords'], 'targetRecords')
          .map(NarrativeEventRecord.fromJson)
          .toList(),
      targetClaims: _list(object['targetClaims'], 'targetClaims')
          .map(LegacySourceClaim.fromJson)
          .toList(),
      backupPlan: NarrativeEventMigrationBackupPlan.fromJson(
        object['backupPlan'],
      ),
      writePreconditions: NarrativeEventMigrationWritePreconditions.fromJson(
        object['writePreconditions'],
      ),
      atomicityPlan: NarrativeEventMigrationAtomicityPlan.fromJson(
        object['atomicityPlan'],
      ),
      rollbackPlan: NarrativeEventMigrationRollbackPlan.fromJson(
        object['rollbackPlan'],
      ),
      pointOfNoReturn: NarrativeEventMigrationPointOfNoReturn.fromJson(
        object['pointOfNoReturn'],
      ),
    );
  }

  final String receiptId;
  final int schemaVersion;
  final String phase;
  final bool isProposal;
  final NarrativeEventMigrationSnapshot snapshot;
  final String expectedManifestHashAfter;
  final String expectedRegistryHashAfter;
  final NarrativeEventMigrationReceiptLifecycle lifecycle;
  final List<String> cohortIds;
  final NarrativeEventReferenceMappings mappings;
  final List<NarrativeEventRecord> targetRecords;
  final List<LegacySourceClaim> targetClaims;
  final NarrativeEventMigrationBackupPlan backupPlan;
  final NarrativeEventMigrationWritePreconditions writePreconditions;
  final NarrativeEventMigrationAtomicityPlan atomicityPlan;
  final NarrativeEventMigrationRollbackPlan rollbackPlan;
  final NarrativeEventMigrationPointOfNoReturn pointOfNoReturn;

  Map<String, Object?> toJson() => {
        'receiptId': receiptId,
        'schemaVersion': schemaVersion,
        'phase': phase,
        'isProposal': isProposal,
        'snapshot': snapshot.toJson(),
        'expectedManifestHashAfter': expectedManifestHashAfter,
        'expectedRegistryHashAfter': expectedRegistryHashAfter,
        'lifecycle': lifecycle.toJson(),
        'cohortIds': cohortIds,
        'mappings': mappings.toJson(),
        'targetRecords': [for (final record in targetRecords) record.toJson()],
        'targetClaims': [for (final claim in targetClaims) claim.toJson()],
        'backupPlan': backupPlan.toJson(),
        'writePreconditions': writePreconditions.toJson(),
        'atomicityPlan': atomicityPlan.toJson(),
        'rollbackPlan': rollbackPlan.toJson(),
        'pointOfNoReturn': pointOfNoReturn.toJson(),
      };
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<NarrativeEventRecord> _sortedRecords(
  List<NarrativeEventRecord> values,
) {
  final sorted = List<NarrativeEventRecord>.of(values)
    ..sort((left, right) => left.id.compareTo(right.id));
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1].id == sorted[index].id) {
      throw ArgumentError.value(values, 'targetRecords', 'duplicate event ID');
    }
  }
  return List.unmodifiable(sorted);
}

List<LegacySourceClaim> _sortedClaims(List<LegacySourceClaim> values) {
  final sorted = List<LegacySourceClaim>.of(values)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1].cohortId == sorted[index].cohortId) {
      throw ArgumentError.value(values, 'targetClaims', 'duplicate cohort ID');
    }
  }
  return List.unmodifiable(sorted);
}

Map<String, String> _fingerprintMap(
  Map<String, String> values,
  String name,
) {
  final keys = values.keys.toList()..sort();
  return Map.unmodifiable({
    for (final key in keys)
      _identity(key, '$name.key'): _fingerprint(values[key]!, '$name.$key'),
  });
}

Map<String, String> _identityMap(
  Map<String, String> values,
  String name,
) {
  final keys = values.keys.toList()..sort();
  return Map.unmodifiable({
    for (final key in keys)
      _identity(key, '$name.key'): _identity(values[key]!, '$name.$key'),
  });
}

List<String> _sortedUnique(List<String> values, String name) {
  final sorted = values.map((value) => _identity(value, name)).toList()..sort();
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return List.unmodifiable(sorted);
}

List<String> _identityList(List<String> values, String name) =>
    List.unmodifiable([
      for (final value in values) _identity(value, name),
    ]);

String _fingerprint(String value, String name) {
  if (!_fingerprintPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'must use sha256:<64 lowercase hex>',
    );
  }
  return value;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object.');
  return {
    for (final entry in value.entries) _key(entry.key, path): entry.value,
  };
}

String _key(Object? value, String path) {
  if (value is! String) throw FormatException('$path keys must be strings.');
  return value;
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be a list.');
  return List<Object?>.from(value);
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('$key must be a String.');
  return value;
}

int _integer(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('$key must be an int.');
  return value;
}

bool _boolean(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! bool) throw FormatException('$key must be a bool.');
  return value;
}

List<String> _stringList(Object? value, String path) {
  return _list(value, path).map((item) {
    if (item is! String) throw FormatException('$path must contain strings.');
    return item;
  }).toList();
}

Map<String, String> _stringMap(Object? value, String path) {
  final object = _object(value, path);
  return object.map((key, item) {
    if (item is! String) {
      throw FormatException('$path.$key must be a String.');
    }
    return MapEntry(key, item);
  });
}

DateTime _dateTime(Map<String, Object?> object, String key) {
  final value = _string(object, key);
  return _parseDateTime(value, key);
}

DateTime? _optionalDateTime(Object? value, String path) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$path must be a String.');
  return _parseDateTime(value, path);
}

DateTime _parseDateTime(String value, String path) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$path must be an ISO-8601 UTC timestamp.');
  }
  return parsed;
}

T _enumByName<T extends Enum>(List<T> values, String name, String path) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$path has unsupported value "$name".');
}
````

</details>

### `packages/map_core/lib/src/compatibility/narrative_event_reference_mapping.dart`

SHA-256: `dbad4c382fdd9ede23f4e2ae68bf795fa9e7b525a8baa1ddbc4aff04db71c6a7` — 865 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'legacy_event_migration_models.dart';

String computeNarrativeEventMigrationTargetKey({
  required LegacySourceRef provenance,
  required String targetSignature,
}) {
  final signature = _identity(targetSignature, 'targetSignature');
  return 'met_${narrativeEventCanonicalSha256({
        'provenance': provenance.toJson(),
        'targetSignature': signature,
      })}';
}

enum NarrativeEventReferenceDomain {
  progression,
  condition,
  worldRule,
  consequence,
  save,
}

enum NarrativeEventReferenceMappingStatus {
  mapped,
  readyForAllocation,
  preservedTombstone,
  requiresChoice,
  cancelled,
  blocked,
}

enum NarrativeEventReferenceCollisionDecision {
  consumeAllTargets,
  selectedTargets,
  cancel,
}

enum NarrativeEventPageMappingStatus { mapped, preservedLegacy }

@immutable
final class NarrativeEventReferenceCatalog {
  NarrativeEventReferenceCatalog({
    List<LegacyEventReference> progression = const [],
    List<LegacyEventReference> conditions = const [],
    List<LegacyEventReference> worldRules = const [],
    List<LegacyEventReference> consequences = const [],
    List<LegacyEventReference> saves = const [],
  })  : progression = List.unmodifiable(progression),
        conditions = List.unmodifiable(conditions),
        worldRules = List.unmodifiable(worldRules),
        consequences = List.unmodifiable(consequences),
        saves = List.unmodifiable(saves) {
    final paths = <String>{};
    for (final reference in all) {
      if (!paths.add(reference.path)) {
        throw ArgumentError.value(
          reference.path,
          'references',
          'reference paths must be unique across the catalog',
        );
      }
    }
    _requireReferenceKinds(
      this.progression,
      'progression',
      const {LegacyEventReferenceKind.consumedEventState},
    );
    _requireReferenceKinds(
      this.conditions,
      'conditions',
      const {LegacyEventReferenceKind.scriptCondition},
    );
    _requireReferenceKinds(
      this.worldRules,
      'worldRules',
      const {
        LegacyEventReferenceKind.worldRuleSource,
        LegacyEventReferenceKind.worldRuleTarget,
      },
    );
    _requireReferenceKinds(
      this.consequences,
      'consequences',
      const {
        LegacyEventReferenceKind.sceneConsequence,
        LegacyEventReferenceKind.scenarioNodeBinding,
        LegacyEventReferenceKind.scriptCommand,
        LegacyEventReferenceKind.metadata,
        LegacyEventReferenceKind.validatorDiagnostic,
      },
    );
    _requireReferenceKinds(
      this.saves,
      'saves',
      const {LegacyEventReferenceKind.consumedEventState},
    );
  }

  factory NarrativeEventReferenceCatalog.empty() =>
      NarrativeEventReferenceCatalog();

  factory NarrativeEventReferenceCatalog.fromJson(Object? json) {
    final object = _object(json, 'referenceCatalog');
    return NarrativeEventReferenceCatalog(
      progression: _referenceList(object['progression'], 'progression'),
      conditions: _referenceList(object['conditions'], 'conditions'),
      worldRules: _referenceList(object['worldRules'], 'worldRules'),
      consequences: _referenceList(object['consequences'], 'consequences'),
      saves: _referenceList(object['saves'], 'saves'),
    );
  }

  final List<LegacyEventReference> progression;
  final List<LegacyEventReference> conditions;
  final List<LegacyEventReference> worldRules;
  final List<LegacyEventReference> consequences;
  final List<LegacyEventReference> saves;

  List<LegacyEventReference> get all => List.unmodifiable([
        ...progression,
        ...conditions,
        ...worldRules,
        ...consequences,
        ...saves,
      ]);

  bool get isEmpty => all.isEmpty;

  Map<String, Object?> toJson() => {
        'progression': [for (final value in progression) value.toJson()],
        'conditions': [for (final value in conditions) value.toJson()],
        'worldRules': [for (final value in worldRules) value.toJson()],
        'consequences': [for (final value in consequences) value.toJson()],
        'saves': [for (final value in saves) value.toJson()],
      };
}

void _requireReferenceKinds(
  List<LegacyEventReference> references,
  String domain,
  Set<LegacyEventReferenceKind> allowed,
) {
  for (final reference in references) {
    if (!allowed.contains(reference.kind)) {
      throw ArgumentError.value(
        reference.kind,
        domain,
        'reference kind is incompatible with the catalog domain',
      );
    }
  }
}

@immutable
final class NarrativeEventReferenceResolutionChoice {
  NarrativeEventReferenceResolutionChoice({
    required String path,
    required this.decision,
    List<String> selectedTargetEventIds = const [],
    List<String> selectedTargetKeys = const [],
  })  : path = _identity(path, 'path'),
        selectedTargetEventIds = _sortedUniqueIds(
          selectedTargetEventIds,
          'selectedTargetEventIds',
        ),
        selectedTargetKeys = _sortedUniqueIds(
          selectedTargetKeys,
          'selectedTargetKeys',
        ) {
    final selectionCount = (this.selectedTargetEventIds.isEmpty ? 0 : 1) +
        (this.selectedTargetKeys.isEmpty ? 0 : 1);
    if (decision == NarrativeEventReferenceCollisionDecision.selectedTargets &&
        selectionCount != 1) {
      throw ArgumentError.value(
        [selectedTargetEventIds, selectedTargetKeys],
        'selectedTargets',
        'must use exactly one non-empty ID or stable-key selection',
      );
    }
    if (decision != NarrativeEventReferenceCollisionDecision.selectedTargets &&
        selectionCount != 0) {
      throw ArgumentError.value(
        [selectedTargetEventIds, selectedTargetKeys],
        'selectedTargets',
        'must be empty unless selectedTargets is used',
      );
    }
  }

  factory NarrativeEventReferenceResolutionChoice.fromJson(Object? json) {
    final object = _object(json, 'referenceChoice');
    return NarrativeEventReferenceResolutionChoice(
      path: _string(object, 'path'),
      decision: _enumByName(
        NarrativeEventReferenceCollisionDecision.values,
        _string(object, 'decision'),
        'decision',
      ),
      selectedTargetEventIds: _stringList(
        object['selectedTargetEventIds'],
        'selectedTargetEventIds',
      ),
      selectedTargetKeys: object.containsKey('selectedTargetKeys')
          ? _stringList(object['selectedTargetKeys'], 'selectedTargetKeys')
          : const [],
    );
  }

  final String path;
  final NarrativeEventReferenceCollisionDecision decision;
  final List<String> selectedTargetEventIds;
  final List<String> selectedTargetKeys;

  Map<String, Object?> toJson() => {
        'path': path,
        'decision': decision.name,
        'selectedTargetEventIds': selectedTargetEventIds,
        if (selectedTargetKeys.isNotEmpty)
          'selectedTargetKeys': selectedTargetKeys,
      };
}

@immutable
final class NarrativeEventIdMapping {
  NarrativeEventIdMapping({
    required this.provenance,
    required String legacyId,
    required List<String> targetEventIds,
  })  : legacyId = _identity(legacyId, 'legacyId'),
        targetEventIds = _sortedUniqueIds(
          targetEventIds,
          'targetEventIds',
          requireNotEmpty: true,
        );

  factory NarrativeEventIdMapping.fromJson(Object? json) {
    final object = _object(json, 'idMapping');
    return NarrativeEventIdMapping(
      provenance: LegacySourceRef.fromJson(object['provenance']),
      legacyId: _string(object, 'legacyId'),
      targetEventIds: _stringList(
        object['targetEventIds'],
        'targetEventIds',
      ),
    );
  }

  final LegacySourceRef provenance;
  final String legacyId;
  final List<String> targetEventIds;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'legacyId': legacyId,
        'targetEventIds': targetEventIds,
      };
}

@immutable
final class NarrativeEventPageMapping {
  NarrativeEventPageMapping({
    required this.provenance,
    required int pageIndex,
    required this.pageNumber,
    required this.status,
    String? targetEventId,
    String? sceneId,
    required Map<String, Object?> preservedPageJson,
  })  : pageIndex = _nonNegative(pageIndex, 'pageIndex'),
        targetEventId = _optionalIdentity(targetEventId, 'targetEventId'),
        sceneId = _optionalIdentity(sceneId, 'sceneId'),
        preservedPageJson = _freezeMap(preservedPageJson) {
    if (status == NarrativeEventPageMappingStatus.mapped &&
        this.targetEventId == null) {
      throw ArgumentError('A mapped page requires targetEventId.');
    }
    if (status == NarrativeEventPageMappingStatus.preservedLegacy &&
        this.targetEventId != null) {
      throw ArgumentError(
        'A preserved legacy page cannot claim a targetEventId.',
      );
    }
  }

  factory NarrativeEventPageMapping.fromJson(Object? json) {
    final object = _object(json, 'pageMapping');
    return NarrativeEventPageMapping(
      provenance: LegacySourceRef.fromJson(object['provenance']),
      pageIndex: _integer(object, 'pageIndex'),
      pageNumber: _integer(object, 'pageNumber'),
      status: _enumByName(
        NarrativeEventPageMappingStatus.values,
        _string(object, 'status'),
        'status',
      ),
      targetEventId: _optionalString(object['targetEventId'], 'targetEventId'),
      sceneId: _optionalString(object['sceneId'], 'sceneId'),
      preservedPageJson: _object(
        object['preservedPageJson'],
        'preservedPageJson',
      ),
    );
  }

  final LegacySourceRef provenance;
  final int pageIndex;
  final int pageNumber;
  final NarrativeEventPageMappingStatus status;
  final String? targetEventId;
  final String? sceneId;
  final Map<String, Object?> preservedPageJson;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'pageIndex': pageIndex,
        'pageNumber': pageNumber,
        'status': status.name,
        if (targetEventId != null) 'targetEventId': targetEventId,
        if (sceneId != null) 'sceneId': sceneId,
        'preservedPageJson': preservedPageJson,
      };
}

@immutable
final class NarrativeEventReferenceMapping {
  NarrativeEventReferenceMapping({
    required this.domain,
    required this.kind,
    required String path,
    required String legacyEventId,
    String? mapId,
    required List<LegacySourceRef> candidateProvenances,
    required List<String> targetEventIds,
    List<String> availableTargetKeys = const [],
    required this.status,
    this.decision,
  })  : path = _identity(path, 'path'),
        legacyEventId = _identity(legacyEventId, 'legacyEventId'),
        mapId = _optionalIdentity(mapId, 'mapId'),
        candidateProvenances = _sortedProvenances(candidateProvenances),
        targetEventIds = _sortedUniqueIds(
          targetEventIds,
          'targetEventIds',
        ),
        availableTargetKeys = _sortedUniqueIds(
          availableTargetKeys,
          'availableTargetKeys',
        ) {
    if (status == NarrativeEventReferenceMappingStatus.mapped &&
        this.targetEventIds.isEmpty) {
      throw ArgumentError('A mapped reference requires targetEventIds.');
    }
    if (status != NarrativeEventReferenceMappingStatus.mapped &&
        this.targetEventIds.isNotEmpty) {
      throw ArgumentError(
        'Only mapped references may expose targetEventIds.',
      );
    }
  }

  factory NarrativeEventReferenceMapping.fromJson(Object? json) {
    final object = _object(json, 'referenceMapping');
    final decisionName = _optionalString(object['decision'], 'decision');
    return NarrativeEventReferenceMapping(
      domain: _enumByName(
        NarrativeEventReferenceDomain.values,
        _string(object, 'domain'),
        'domain',
      ),
      kind: _enumByName(
        LegacyEventReferenceKind.values,
        _string(object, 'kind'),
        'kind',
      ),
      path: _string(object, 'path'),
      legacyEventId: _string(object, 'legacyEventId'),
      mapId: _optionalString(object['mapId'], 'mapId'),
      candidateProvenances: _list(
        object['candidateProvenances'],
        'candidateProvenances',
      ).map(LegacySourceRef.fromJson).toList(),
      targetEventIds: _stringList(
        object['targetEventIds'],
        'targetEventIds',
      ),
      availableTargetKeys: object.containsKey('availableTargetKeys')
          ? _stringList(
              object['availableTargetKeys'],
              'availableTargetKeys',
            )
          : const [],
      status: _enumByName(
        NarrativeEventReferenceMappingStatus.values,
        _string(object, 'status'),
        'status',
      ),
      decision: decisionName == null
          ? null
          : _enumByName(
              NarrativeEventReferenceCollisionDecision.values,
              decisionName,
              'decision',
            ),
    );
  }

  final NarrativeEventReferenceDomain domain;
  final LegacyEventReferenceKind kind;
  final String path;
  final String legacyEventId;
  final String? mapId;
  final List<LegacySourceRef> candidateProvenances;
  final List<String> targetEventIds;
  final List<String> availableTargetKeys;
  final NarrativeEventReferenceMappingStatus status;
  final NarrativeEventReferenceCollisionDecision? decision;

  Map<String, Object?> toJson() => {
        'domain': domain.name,
        'kind': kind.name,
        'path': path,
        'legacyEventId': legacyEventId,
        if (mapId != null) 'mapId': mapId,
        'candidateProvenances': [
          for (final provenance in candidateProvenances) provenance.toJson(),
        ],
        'targetEventIds': targetEventIds,
        if (availableTargetKeys.isNotEmpty)
          'availableTargetKeys': availableTargetKeys,
        'status': status.name,
        if (decision != null) 'decision': decision!.name,
      };
}

@immutable
final class NarrativeEventReferenceMappings {
  NarrativeEventReferenceMappings({
    List<NarrativeEventIdMapping> idMappings = const [],
    List<NarrativeEventPageMapping> pageMappings = const [],
    List<NarrativeEventReferenceMapping> progressionMappings = const [],
    List<NarrativeEventReferenceMapping> conditionMappings = const [],
    List<NarrativeEventReferenceMapping> worldRuleMappings = const [],
    List<NarrativeEventReferenceMapping> consequenceMappings = const [],
    List<NarrativeEventReferenceMapping> saveMappings = const [],
  })  : idMappings = List.unmodifiable(idMappings),
        pageMappings = List.unmodifiable(pageMappings),
        progressionMappings = List.unmodifiable(progressionMappings),
        conditionMappings = List.unmodifiable(conditionMappings),
        worldRuleMappings = List.unmodifiable(worldRuleMappings),
        consequenceMappings = List.unmodifiable(consequenceMappings),
        saveMappings = List.unmodifiable(saveMappings);

  factory NarrativeEventReferenceMappings.fromJson(Object? json) {
    final object = _object(json, 'referenceMappings');
    return NarrativeEventReferenceMappings(
      idMappings: _list(object['ids'], 'ids')
          .map(NarrativeEventIdMapping.fromJson)
          .toList(),
      pageMappings: _list(object['pages'], 'pages')
          .map(NarrativeEventPageMapping.fromJson)
          .toList(),
      progressionMappings: _mappingList(object, 'progression'),
      conditionMappings: _mappingList(object, 'conditions'),
      worldRuleMappings: _mappingList(object, 'worldRules'),
      consequenceMappings: _mappingList(object, 'consequences'),
      saveMappings: _mappingList(object, 'saves'),
    );
  }

  final List<NarrativeEventIdMapping> idMappings;
  final List<NarrativeEventPageMapping> pageMappings;
  final List<NarrativeEventReferenceMapping> progressionMappings;
  final List<NarrativeEventReferenceMapping> conditionMappings;
  final List<NarrativeEventReferenceMapping> worldRuleMappings;
  final List<NarrativeEventReferenceMapping> consequenceMappings;
  final List<NarrativeEventReferenceMapping> saveMappings;

  List<NarrativeEventReferenceMapping> get allReferenceMappings =>
      List.unmodifiable([
        ...progressionMappings,
        ...conditionMappings,
        ...worldRuleMappings,
        ...consequenceMappings,
        ...saveMappings,
      ]);

  bool get hasBlockingMappings => allReferenceMappings.any(
        (mapping) =>
            mapping.status != NarrativeEventReferenceMappingStatus.mapped &&
            mapping.status !=
                NarrativeEventReferenceMappingStatus.readyForAllocation &&
            mapping.status !=
                NarrativeEventReferenceMappingStatus.preservedTombstone,
      );

  Map<String, Object?> toJson() => {
        'ids': [for (final value in idMappings) value.toJson()],
        'pages': [for (final value in pageMappings) value.toJson()],
        'progression': [
          for (final value in progressionMappings) value.toJson(),
        ],
        'conditions': [
          for (final value in conditionMappings) value.toJson(),
        ],
        'worldRules': [
          for (final value in worldRuleMappings) value.toJson(),
        ],
        'consequences': [
          for (final value in consequenceMappings) value.toJson(),
        ],
        'saves': [for (final value in saveMappings) value.toJson()],
      };
}

NarrativeEventReferenceMappings buildNarrativeEventReferenceMappings({
  required Map<LegacySourceRef, List<String>> targetEventIdsByProvenance,
  Map<LegacySourceRef, Map<String, String>> targetEventIdsByTargetKey =
      const {},
  required NarrativeEventReferenceCatalog references,
  List<NarrativeEventReferenceResolutionChoice> choices = const [],
  List<NarrativeEventIdMapping> idMappings = const [],
  List<NarrativeEventPageMapping> pageMappings = const [],
}) {
  final choicesByPath = <String, NarrativeEventReferenceResolutionChoice>{};
  for (final choice in choices) {
    if (choicesByPath.containsKey(choice.path)) {
      throw ArgumentError.value(
        choice.path,
        'choices',
        'a reference path can only have one resolution choice',
      );
    }
    choicesByPath[choice.path] = choice;
  }

  List<NarrativeEventReferenceMapping> resolve(
    NarrativeEventReferenceDomain domain,
    List<LegacyEventReference> source,
  ) {
    final sorted = List<LegacyEventReference>.of(source)
      ..sort((left, right) => left.path.compareTo(right.path));
    return [
      for (final reference in sorted)
        _resolveReference(
          domain: domain,
          reference: reference,
          targets: targetEventIdsByProvenance,
          keyedTargets: targetEventIdsByTargetKey,
          choice: choicesByPath[reference.path],
        ),
    ];
  }

  return NarrativeEventReferenceMappings(
    idMappings: idMappings,
    pageMappings: pageMappings,
    progressionMappings: resolve(
      NarrativeEventReferenceDomain.progression,
      references.progression,
    ),
    conditionMappings: resolve(
      NarrativeEventReferenceDomain.condition,
      references.conditions,
    ),
    worldRuleMappings: resolve(
      NarrativeEventReferenceDomain.worldRule,
      references.worldRules,
    ),
    consequenceMappings: resolve(
      NarrativeEventReferenceDomain.consequence,
      references.consequences,
    ),
    saveMappings: resolve(
      NarrativeEventReferenceDomain.save,
      references.saves,
    ),
  );
}

NarrativeEventReferenceMapping _resolveReference({
  required NarrativeEventReferenceDomain domain,
  required LegacyEventReference reference,
  required Map<LegacySourceRef, List<String>> targets,
  required Map<LegacySourceRef, Map<String, String>> keyedTargets,
  required NarrativeEventReferenceResolutionChoice? choice,
}) {
  final available = <String>{};
  final availableByKey = <String, String>{};
  var allCandidatesMapped = true;
  for (final provenance in reference.candidateProvenances) {
    final candidateTargets = targets[provenance] ?? const <String>[];
    if (candidateTargets.isEmpty) allCandidatesMapped = false;
    available.addAll(candidateTargets);
    availableByKey.addAll(keyedTargets[provenance] ?? const {});
  }
  final sortedAvailable = available.toList()..sort();
  final availableTargetKeys = availableByKey.keys.toList()..sort();

  NarrativeEventReferenceMapping result(
    NarrativeEventReferenceMappingStatus status, {
    List<String> targetEventIds = const [],
    NarrativeEventReferenceCollisionDecision? decision,
  }) {
    return NarrativeEventReferenceMapping(
      domain: domain,
      kind: reference.kind,
      path: reference.path,
      legacyEventId: reference.legacyEventId,
      mapId: reference.mapId,
      candidateProvenances: reference.candidateProvenances,
      targetEventIds: targetEventIds,
      availableTargetKeys: availableTargetKeys,
      status: status,
      decision: decision,
    );
  }

  if (reference.candidateProvenances.isEmpty) {
    if (domain == NarrativeEventReferenceDomain.progression ||
        domain == NarrativeEventReferenceDomain.save) {
      return result(
        NarrativeEventReferenceMappingStatus.preservedTombstone,
      );
    }
    return result(NarrativeEventReferenceMappingStatus.blocked);
  }

  if (reference.candidateProvenances.length == 1 && choice == null) {
    if (sortedAvailable.isEmpty) {
      return result(NarrativeEventReferenceMappingStatus.blocked);
    }
    if (sortedAvailable.length > 1) {
      return result(NarrativeEventReferenceMappingStatus.requiresChoice);
    }
    return result(
      NarrativeEventReferenceMappingStatus.mapped,
      targetEventIds: sortedAvailable,
    );
  }

  if (choice == null) {
    return result(NarrativeEventReferenceMappingStatus.requiresChoice);
  }

  switch (choice.decision) {
    case NarrativeEventReferenceCollisionDecision.cancel:
      return result(
        NarrativeEventReferenceMappingStatus.cancelled,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.consumeAllTargets:
      if (domain != NarrativeEventReferenceDomain.progression &&
          domain != NarrativeEventReferenceDomain.save) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      if (!allCandidatesMapped || sortedAvailable.isEmpty) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      return result(
        NarrativeEventReferenceMappingStatus.mapped,
        targetEventIds: sortedAvailable,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.selectedTargets:
      if (choice.selectedTargetKeys.isNotEmpty) {
        if (choice.selectedTargetKeys.any(
          (targetKey) => !availableByKey.containsKey(targetKey),
        )) {
          return result(
            NarrativeEventReferenceMappingStatus.blocked,
            decision: choice.decision,
          );
        }
        final selectedIds = {
          for (final targetKey in choice.selectedTargetKeys)
            availableByKey[targetKey]!,
        }.toList()
          ..sort();
        return result(
          NarrativeEventReferenceMappingStatus.mapped,
          targetEventIds: selectedIds,
          decision: choice.decision,
        );
      }
      if (choice.selectedTargetEventIds.any(
        (target) => !available.contains(target),
      )) {
        return result(
          NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      return result(
        NarrativeEventReferenceMappingStatus.mapped,
        targetEventIds: choice.selectedTargetEventIds,
        decision: choice.decision,
      );
  }
}

List<NarrativeEventReferenceMapping> _mappingList(
  Map<String, Object?> object,
  String key,
) {
  return _list(object[key], key)
      .map(NarrativeEventReferenceMapping.fromJson)
      .toList();
}

List<LegacyEventReference> _referenceList(Object? value, String path) {
  return _list(value, path).map((item) {
    final object = _object(item, path);
    return LegacyEventReference(
      kind: _enumByName(
        LegacyEventReferenceKind.values,
        _string(object, 'kind'),
        '$path.kind',
      ),
      path: _string(object, 'path'),
      legacyEventId: _string(object, 'legacyEventId'),
      mapId: _optionalString(object['mapId'], '$path.mapId'),
      candidateProvenances: _list(
        object['candidateProvenances'],
        '$path.candidateProvenances',
      ).map(LegacySourceRef.fromJson).toList(),
    );
  }).toList();
}

List<LegacySourceRef> _sortedProvenances(
  List<LegacySourceRef> values,
) {
  final sorted = List<LegacySourceRef>.of(values)
    ..sort(compareLegacySourceRefs);
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(
        values,
        'candidateProvenances',
        'must not contain duplicates',
      );
    }
  }
  return List.unmodifiable(sorted);
}

List<String> _sortedUniqueIds(
  List<String> values,
  String name, {
  bool requireNotEmpty = false,
}) {
  final sorted = values.map((value) => _identity(value, name)).toList()..sort();
  if (requireNotEmpty && sorted.isEmpty) {
    throw ArgumentError.value(values, name, 'must not be empty');
  }
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return List.unmodifiable(sorted);
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List.unmodifiable([for (final item in value) _freezeJson(item)]);
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        _jsonKey(entry.key): _freezeJson(entry.value),
    });
  }
  throw ArgumentError.value(value, 'json', 'must contain JSON values only');
}

String _jsonKey(Object? value) {
  if (value is! String) {
    throw ArgumentError.value(value, 'json key', 'must be a String');
  }
  return value;
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return {
    for (final entry in value.entries) _jsonKey(entry.key): entry.value,
  };
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be a list.');
  return List<Object?>.from(value);
}

List<String> _stringList(Object? value, String path) {
  return _list(value, path).map((item) {
    if (item is! String) throw FormatException('$path must contain strings.');
    return item;
  }).toList();
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('$key must be a String.');
  return value;
}

String? _optionalString(Object? value, String path) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$path must be a String.');
  return value;
}

int _integer(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('$key must be an int.');
  return value;
}

T _enumByName<T extends Enum>(List<T> values, String name, String path) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$path has unsupported value "$name".');
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalIdentity(String? value, String name) {
  if (value == null) return null;
  return _identity(value, name);
}

int _nonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
  return value;
}
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/README.md`

SHA-256: `970820cfe9ac08f96e864897e871f61db4e2670ca90b70556427673e99dda2cc` — 41 lignes.

<details>
<summary>Contenu complet</summary>

````markdown
# Narrative Event JCS vectors

This fixture pack makes the Event V2 canonical JSON and SHA-256 contract
reproducible without network access or dynamically installed tools.

Sources:

- RFC 8785 sections 3.2.2 and 3.2.3 for number serialization, string
  serialization, and UTF-16 property ordering;
- RFC 8785 Appendix B and RFC 7493 I-JSON constraints for finite numbers,
  safe integers, Unicode scalar sequences, and duplicate member rejection;
- PokeMap NS-EVENT-V2 Phase B committed claim and legacy-source fingerprint
  goldens for project-specific preimages.

The `official/` pairs are copied from
`cyberphone/json-canonicalization/testdata` at commit
`19d51d7fe467d4706a3ff08adf8a748f29fc21e0`. That upstream repository
publishes them under Apache License 2.0. Inputs are paired with the official
UTF-8 output expressed as hexadecimal bytes so control characters remain
reviewable in Git.

`vectors.json` stores the original structured input or raw JSON source, the
expected canonical form, the expected SHA-256 digest, and the provenance of
each vector. Run either:

```text
dart test test/narrative_event_claim_fingerprints_test.dart
dart run tool/verify_narrative_event_jcs_vectors.dart
```

The tool is a convenience verifier. The normal Dart test is authoritative and
requires no Node.js installation.

An additional optional oracle replays the upstream deterministic IEEE-754
sequence and compares 200,000 Dart serializations with Node.js. It is pinned to
checksum `b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57`
and was verified with Node.js `v26.3.1`:

```text
dart run tool/verify_narrative_event_jcs_number_oracle.dart
```
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/arrays.json`

SHA-256: `f10de6ba9b5f33f1defc3c83595618227cf52acb458cf4680499cb2d56e79441` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
[ 56, { "d": true, "10": null, "1": [ ] } ]
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/french.json`

SHA-256: `26b8c837350b3fb597542e4927bb7dc81617e121865a6296aba28d19c9cc9961` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
{ "peach": "This sorting order", "péché": "is wrong according to French", "pêche": "but canonicalization MUST", "sin": "ignore locale" }
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/structures.json`

SHA-256: `d3bc135db75b9273780418ca8ff02532ac945bbdfd16b20a15a2b6aac1d83ded` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
{ "1": {"f": {"f": "hi","F": 5} ,"\n": 56.0}, "10": { }, "": "empty", "a": { }, "111": [ {"e": "yes","E": "no" } ], "A": { } }
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/unicode.json`

SHA-256: `4944fc3bc9beb2969e875d1d20b652e0f80547eaa2957d01c66b655cc71e1e95` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
{ "Unnormalized Unicode":"A\u030a" }
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/values.json`

SHA-256: `722f9a8484d0eca58a19963e9c34d64f5fbb12b3856b697feab3537321babcc7` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
{ "numbers": [333333333.33333329, 1E30, 4.50, 2e-3, 0.000000000000000000000000001], "string": "\u20ac$\u000F\u000aA'\u0042\u0022\u005c\\"\/", "literals": [null, true, false] }
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/input/weird.json`

SHA-256: `700e7d7c6f4627ecbc73ac2f54d4f1619359ec8c3ae4ec3f36b8654ecc5abe79` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````json
{ "\u20ac": "Euro Sign", "\r": "Carriage Return", "\u000a": "Newline", "1": "One", "\u0080": "Control\u007f", "\ud83d\ude02": "Smiley", "\u00f6": "Latin Small Letter O With Diaeresis", "\ufb33": "Hebrew Letter Dalet With Dagesh", "</script>": "Browser Challenge" }
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/arrays.txt`

SHA-256: `e306733ca0c4da9595ebde73ec072c295f0f9ef0ea4aafc4d267d4a04988ce51` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
5b 35 36 2c 7b 22 31 22 3a 5b 5d 2c 22 31 30 22 3a 6e 75 6c 6c 2c 22 64 22 3a 74 72 75 65 7d 5d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/french.txt`

SHA-256: `1c8307b5f071f252821ccdb700cfddf5efbb8e97723ce5aa8f2096fb23d34d9d` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
7b 22 70 65 61 63 68 22 3a 22 54 68 69 73 20 73 6f 72 74 69 6e 67 20 6f 72 64 65 72 22 2c 22 70 c3 a9 63 68 c3 a9 22 3a 22 69 73 20 77 72 6f 6e 67 20 61 63 63 6f 72 64 69 6e 67 20 74 6f 20 46 72 65 6e 63 68 22 2c 22 70 c3 aa 63 68 65 22 3a 22 62 75 74 20 63 61 6e 6f 6e 69 63 61 6c 69 7a 61 74 69 6f 6e 20 4d 55 53 54 22 2c 22 73 69 6e 22 3a 22 69 67 6e 6f 72 65 20 6c 6f 63 61 6c 65 22 7d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/structures.txt`

SHA-256: `c9401459a34dc0a211b36181a9a8c8342bc81b04add6a1556800da5b0196fcc8` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
7b 22 22 3a 22 65 6d 70 74 79 22 2c 22 31 22 3a 7b 22 5c 6e 22 3a 35 36 2c 22 66 22 3a 7b 22 46 22 3a 35 2c 22 66 22 3a 22 68 69 22 7d 7d 2c 22 31 30 22 3a 7b 7d 2c 22 31 31 31 22 3a 5b 7b 22 45 22 3a 22 6e 6f 22 2c 22 65 22 3a 22 79 65 73 22 7d 5d 2c 22 41 22 3a 7b 7d 2c 22 61 22 3a 7b 7d 7d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/unicode.txt`

SHA-256: `0471fea1ee0464e435a52510d2c187b216961a5e7e2665402ea9cb1cd04109ca` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
7b 22 55 6e 6e 6f 72 6d 61 6c 69 7a 65 64 20 55 6e 69 63 6f 64 65 22 3a 22 41 cc 8a 22 7d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/values.txt`

SHA-256: `5b1ad422110b860961e62e775ae1ab98ce12f009cca382f1a22433ce7caccc67` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
7b 22 6c 69 74 65 72 61 6c 73 22 3a 5b 6e 75 6c 6c 2c 74 72 75 65 2c 66 61 6c 73 65 5d 2c 22 6e 75 6d 62 65 72 73 22 3a 5b 33 33 33 33 33 33 33 33 33 2e 33 33 33 33 33 33 33 2c 31 65 2b 33 30 2c 34 2e 35 2c 30 2e 30 30 32 2c 31 65 2d 32 37 5d 2c 22 73 74 72 69 6e 67 22 3a 22 e2 82 ac 24 5c 75 30 30 30 66 5c 6e 41 27 42 5c 22 5c 5c 5c 5c 5c 22 2f 22 7d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/official/outhex/weird.txt`

SHA-256: `bd8bccad8b69e82eac8c3991cf151637b2a8ed2f5e552f9785f8bceec04d5019` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
7b 22 5c 6e 22 3a 22 4e 65 77 6c 69 6e 65 22 2c 22 5c 72 22 3a 22 43 61 72 72 69 61 67 65 20 52 65 74 75 72 6e 22 2c 22 31 22 3a 22 4f 6e 65 22 2c 22 3c 2f 73 63 72 69 70 74 3e 22 3a 22 42 72 6f 77 73 65 72 20 43 68 61 6c 6c 65 6e 67 65 22 2c 22 c2 80 22 3a 22 43 6f 6e 74 72 6f 6c 7f 22 2c 22 c3 b6 22 3a 22 4c 61 74 69 6e 20 53 6d 61 6c 6c 20 4c 65 74 74 65 72 20 4f 20 57 69 74 68 20 44 69 61 65 72 65 73 69 73 22 2c 22 e2 82 ac 22 3a 22 45 75 72 6f 20 53 69 67 6e 22 2c 22 f0 9f 98 82 22 3a 22 53 6d 69 6c 65 79 22 2c 22 ef ac b3 22 3a 22 48 65 62 72 65 77 20 4c 65 74 74 65 72 20 44 61 6c 65 74 20 57 69 74 68 20 44 61 67 65 73 68 22 7d
````

</details>

### `packages/map_core/test/fixtures/narrative_event_jcs/vectors.json`

SHA-256: `73fdedc253981f40784290079546baf10071829175832e21082d54c976d34e84` — 253 lignes.

<details>
<summary>Contenu complet</summary>

````json
{
  "schemaVersion": 1,
  "canonicalCases": [
    {
      "id": "rfc-8785-number-and-literal-sample",
      "provenance": "RFC 8785 section 3.2.2",
      "input": {
        "numbers": [333333333.33333329, 1e30, 4.50, 2e-3, 1e-27, -0.0],
        "literals": [null, true, false]
      },
      "canonical": "{\"literals\":[null,true,false],\"numbers\":[333333333.3333333,1e+30,4.5,0.002,1e-27,0]}",
      "sha256": "e873ca5542a5ce5f9a3ebe9860957bfcf875d9136ed379ab4e31f9f6af0d4a13"
    },
    {
      "id": "rfc-8785-utf16-property-order",
      "provenance": "RFC 8785 section 3.2.3",
      "input": {
        "€": "Euro Sign",
        "\r": "Carriage Return",
        "דּ": "Hebrew Letter Dalet With Dagesh",
        "1": "One",
        "😀": "Emoji: Grinning Face",
        "": "Control",
        "ö": "Latin Small Letter O With Diaeresis"
      },
      "canonical": "{\"\r\":\"Carriage Return\",\"1\":\"One\",\"\":\"Control\",\"ö\":\"Latin Small Letter O With Diaeresis\",\"€\":\"Euro Sign\",\"😀\":\"Emoji: Grinning Face\",\"דּ\":\"Hebrew Letter Dalet With Dagesh\"}",
      "sha256": "5e321556d22018a9656991a9e94f77ec175fa193e52a2429d312f8419ec8b08c"
    },
    {
      "id": "rfc-8785-string-escaping",
      "provenance": "RFC 8785 section 3.2.2.2",
      "input": {
        "z": [3, 2, 1],
        "a": {
          "quote": "\"",
          "slash": "/",
          "backslash": "\",
          "line": "\n"
        }
      },
      "canonical": "{\"a\":{\"backslash\":\"\\\",\"line\":\"\n\",\"quote\":\"\\"\",\"slash\":\"/\"},\"z\":[3,2,1]}",
      "sha256": "1b4c01086097d0e13de5deaad09016bb9f8657ef4e2bdaddceb2590d8904718a"
    },
    {
      "id": "i-json-safe-integers-and-negative-zero",
      "provenance": "RFC 8785 section 3.2.2.3 and RFC 7493 section 2.2",
      "input": {
        "negativeZero": -0.0,
        "max": 9007199254740991,
        "min": -9007199254740991
      },
      "canonical": "{\"max\":9007199254740991,\"min\":-9007199254740991,\"negativeZero\":0}",
      "sha256": "7728d06946509ad2a5102e01f0f4ce2089ca70337167807bfae8965174236dae"
    }
  ],
  "officialCorpus": {
    "provenance": "cyberphone/json-canonicalization testdata",
    "upstreamCommit": "19d51d7fe467d4706a3ff08adf8a748f29fc21e0",
    "cases": ["arrays", "french", "structures", "unicode", "values", "weird"]
  },
  "numberCases": [
    {"ieee754Hex": "0000000000000000", "canonical": "0", "sha256": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9"},
    {"ieee754Hex": "8000000000000000", "canonical": "0", "sha256": "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9"},
    {"ieee754Hex": "0000000000000001", "canonical": "5e-324", "sha256": "c46e7ca1be4c8734f373a56530787288fa2058d73d07855e9247e949f811a42a"},
    {"ieee754Hex": "8000000000000001", "canonical": "-5e-324", "sha256": "046f4049d09944fcb2efbf2ddb0ea8f05e0204591d6d02c9106efc88190fa7f9"},
    {"ieee754Hex": "7fefffffffffffff", "canonical": "1.7976931348623157e+308", "sha256": "c2784e1abd6317452708f3fbf9641c16b959561bc621a1d408c23a20aa2cb585"},
    {"ieee754Hex": "ffefffffffffffff", "canonical": "-1.7976931348623157e+308", "sha256": "f0347276b171ff0c36491c912285a2833de7313d1a103a4b1be0274bfe7c021f"},
    {"ieee754Hex": "4340000000000000", "canonical": "9007199254740992", "sha256": "c681da39d7273a6a24c15c9cac3a75526ff2ecf8ba4ee60346a0c70c8163bdb2"},
    {"ieee754Hex": "c340000000000000", "canonical": "-9007199254740992", "sha256": "83e109bfd7fb4984b47a46f363627c18dbbd7e57e36b05a04cd162d304df72e9"},
    {"ieee754Hex": "4430000000000000", "canonical": "295147905179352830000", "sha256": "7933ef1b34c194c7a327ef424e54282dd2872bc7bda27812f9edf7882ca340c0"},
    {"ieee754Hex": "44b52d02c7e14af5", "canonical": "9.999999999999997e+22", "sha256": "143eadc1fc2fe10a563df313c717399d1835652d710fa189119ff2e1d5cde33d"},
    {"ieee754Hex": "44b52d02c7e14af6", "canonical": "1e+23", "sha256": "0b1af6b73e932475817f8eb620deecf21ad7570df3400a23db5c79a9001597f7"},
    {"ieee754Hex": "44b52d02c7e14af7", "canonical": "1.0000000000000001e+23", "sha256": "de7cb5db5ee06bf7ef5b74ebcf94cd9d7efda28125905f7ff590724953173c7b"},
    {"ieee754Hex": "444b1ae4d6e2ef4e", "canonical": "999999999999999700000", "sha256": "dcabf7269f6bb6ec5ba8b9530825cd7ffe215d4dd26e0a237f9d753513792c07"},
    {"ieee754Hex": "444b1ae4d6e2ef4f", "canonical": "999999999999999900000", "sha256": "914b4f8b4bbe2f6e7c36ad7791fc842a7516d149e694b3a71b78cee465ff6d7a"},
    {"ieee754Hex": "444b1ae4d6e2ef50", "canonical": "1e+21", "sha256": "241c4643fa70b1dcde1205b71be4e3bebb17e9f880c8e1a33d0ead6c27271d3c"},
    {"ieee754Hex": "3eb0c6f7a0b5ed8c", "canonical": "9.999999999999997e-7", "sha256": "2ace34b29d30d300aeacd4f2bb83367fa186f11a3f02ed461f35f00fd741a242"},
    {"ieee754Hex": "3eb0c6f7a0b5ed8d", "canonical": "0.000001", "sha256": "159fb29a827ad04b260aa6c8ab6d8637f8f2b38af5c4f3cb49d6a21205e040f8"},
    {"ieee754Hex": "41b3de4355555553", "canonical": "333333333.3333332", "sha256": "0fdb7bafaf219ccaf278cd0c0a580473db01c774a0baafe72a07d01230ac5c6d"},
    {"ieee754Hex": "41b3de4355555554", "canonical": "333333333.33333325", "sha256": "bcbe1777b7d3c91c19c7f90100c595a9b3f1d9b395567da4258baf7ac655d403"},
    {"ieee754Hex": "41b3de4355555555", "canonical": "333333333.3333333", "sha256": "6bd9be1c141028789cc35db62f1b43e80d5d4ee24d6d542e775deb16799ff4c7"},
    {"ieee754Hex": "41b3de4355555556", "canonical": "333333333.3333334", "sha256": "1e099031ca0cb3cf4054688f7e2e8c95fc72828de5fa7605ce3f729e6cf79d43"},
    {"ieee754Hex": "41b3de4355555557", "canonical": "333333333.33333343", "sha256": "cf68ab5e198a77538aafd967fb122a305ba1df95c9348b1fe3dff453c7f7215f"},
    {"ieee754Hex": "becbf647612f3696", "canonical": "-0.0000033333333333333333", "sha256": "4e703d4e0928e4f339d03e1fb5454ddc33db657ad735b02530d98123b4fd4b61"},
    {"ieee754Hex": "43143ff3c1cb0959", "canonical": "1424953923781206.2", "sha256": "e1547479d27f057e3197d49417a1dcbe19dd8781b34fa9f83b789925943d00cb"}
  ],
  "rejectedNumberCases": [
    {"ieee754Hex": "7fffffffffffffff", "reason": "NaN"},
    {"ieee754Hex": "7ff0000000000000", "reason": "Infinity"}
  ],
  "invalidRawCases": [
    {
      "id": "i-json-unpaired-high-surrogate",
      "provenance": "RFC 8785 section 3.2.2.2",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\ud800\""
    },
    {
      "id": "i-json-unpaired-low-surrogate",
      "provenance": "RFC 8785 section 3.2.2.2",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\udc00\""
    },
    {
      "id": "i-json-inexact-binary64-integer",
      "provenance": "RFC 8785 section 3.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "9007199254740993"
    },
    {
      "id": "i-json-noncharacter-fdd0",
      "provenance": "RFC 7493 section 2.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\ufdd0\""
    },
    {
      "id": "i-json-noncharacter-fffe",
      "provenance": "RFC 7493 section 2.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\ufffe\""
    },
    {
      "id": "i-json-noncharacter-ffff",
      "provenance": "RFC 7493 section 2.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\uffff\""
    },
    {
      "id": "i-json-noncharacter-plane-1",
      "provenance": "RFC 7493 section 2.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\ud83f\udffe\""
    },
    {
      "id": "i-json-noncharacter-plane-16",
      "provenance": "RFC 7493 section 2.1",
      "operation": "canonicalizeDecoded",
      "rawJson": "\"\udbff\udfff\""
    },
    {
      "id": "i-json-surrogate-key",
      "provenance": "RFC 8785 section 3.2.2.2",
      "operation": "canonicalizeDecoded",
      "rawJson": "{\"\ud800\":1}"
    },
    {
      "id": "i-json-duplicate-literal-key",
      "provenance": "RFC 7493 section 2.3",
      "operation": "canonicalizeText",
      "rawJson": "{\"a\":1,\"a\":2}"
    },
    {
      "id": "i-json-duplicate-escaped-key",
      "provenance": "RFC 7493 section 2.3",
      "operation": "canonicalizeText",
      "rawJson": "{\"a\":1,\"\u0061\":2}"
    },
    {
      "id": "i-json-duplicate-event-registry-key",
      "provenance": "RFC 7493 section 2.3",
      "operation": "preflightProject",
      "rawJson": "{\"eventRegistry\":{\"schemaVersion\":1,\"schemaVersion\":1,\"mode\":\"legacyOnly\",\"records\":[],\"legacyClaims\":[]}}",
      "expectedDiagnosticContains": "Duplicate JSON key at $.eventRegistry.schemaVersion"
    }
  ],
  "phaseBHashes": [
    {
      "id": "phase-b-map-event-source",
      "provenance": "NS-EVENT-V2 Phase B committed golden",
      "preimage": "{\"event\":{\"id\":\"legacy\",\"metadata\":{},\"pages\":[{\"condition\":null,\"isDisabled\":false,\"isHidden\":false,\"message\":null,\"metadata\":{},\"pageNumber\":0,\"script\":null,\"spriteId\":null}],\"position\":{\"layerId\":\"events\",\"x\":2,\"y\":1},\"title\":\"\",\"type\":\"actor\"},\"kind\":\"mapEvent\",\"mapId\":\"map_port\"}",
      "sha256": "6ea5956cc0973bd2b6ce93cef2ac703dd61035c6b530dac02f08610239b548db"
    },
    {
      "id": "phase-b-scenario-source",
      "provenance": "NS-EVENT-V2 Phase B committed golden",
      "preimage": "{\"kind\":\"scenarioSourceNode\",\"nodeId\":\"source\",\"scenario\":{\"activationCondition\":null,\"declaredOutcomes\":[],\"description\":\"\",\"edges\":[],\"entryNodeId\":\"source\",\"id\":\"scenario\",\"metadata\":{},\"name\":\"Scenario\",\"nodes\":[],\"scope\":\"localEventFlow\"},\"scenarioId\":\"scenario\"}",
      "sha256": "e8e4b2a3a69a8b291f9e29497c94d054847d5474d2860bd86d9e90dba446a93e"
    }
  ],
  "claimCases": [
    {
      "id": "phase-b-single-map-event-cohort",
      "provenance": "NS-EVENT-V2 Phase B committed claim golden",
      "source": {
        "kind": "mapEnter",
        "mapId": "map_port"
      },
      "provenances": [
        {
          "kind": "mapEvent",
          "mapId": "map_port",
          "eventId": "lysa"
        }
      ],
      "members": [
        {
          "provenance": {
            "kind": "mapEvent",
            "mapId": "map_port",
            "eventId": "lysa"
          },
          "sourceFingerprint": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        }
      ],
      "cohortPreimage": "{\"provenances\":[{\"eventId\":\"lysa\",\"kind\":\"mapEvent\",\"mapId\":\"map_port\"}],\"source\":{\"kind\":\"mapEnter\",\"mapId\":\"map_port\"}}",
      "cohortId": "lsc_f33795b3ad4a0b7522087062de7b7fe3d0bfee38c2c8920172821baa13e4e6c5",
      "fingerprintPreimage": "{\"cohortId\":\"lsc_f33795b3ad4a0b7522087062de7b7fe3d0bfee38c2c8920172821baa13e4e6c5\",\"members\":[{\"provenance\":{\"eventId\":\"lysa\",\"kind\":\"mapEvent\",\"mapId\":\"map_port\"},\"sourceFingerprint\":\"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}]}",
      "cohortFingerprint": "sha256:8e7c6e870ef25acf92eebf9f2641f198c2f2bd774920099b42f0e1bf16d14e9d"
    },
    {
      "id": "phase-b-two-member-reversed-input-cohort",
      "provenance": "NS-EVENT-V2 Phase C deterministic multi-member golden",
      "source": {
        "kind": "mapEnter",
        "mapId": "map_port"
      },
      "provenances": [
        {
          "kind": "scenarioSourceNode",
          "scenarioId": "scenario_arrival",
          "nodeId": "source"
        },
        {
          "kind": "mapEvent",
          "mapId": "map_port",
          "eventId": "lysa"
        }
      ],
      "members": [
        {
          "provenance": {
            "kind": "scenarioSourceNode",
            "scenarioId": "scenario_arrival",
            "nodeId": "source"
          },
          "sourceFingerprint": "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        },
        {
          "provenance": {
            "kind": "mapEvent",
            "mapId": "map_port",
            "eventId": "lysa"
          },
          "sourceFingerprint": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        }
      ],
      "cohortPreimage": "{\"provenances\":[{\"eventId\":\"lysa\",\"kind\":\"mapEvent\",\"mapId\":\"map_port\"},{\"kind\":\"scenarioSourceNode\",\"nodeId\":\"source\",\"scenarioId\":\"scenario_arrival\"}],\"source\":{\"kind\":\"mapEnter\",\"mapId\":\"map_port\"}}",
      "cohortId": "lsc_65e30267a6ef9fe6e351b4a3789377d563a35b7b8e3ccb47f7bc34f3499dcda3",
      "fingerprintPreimage": "{\"cohortId\":\"lsc_65e30267a6ef9fe6e351b4a3789377d563a35b7b8e3ccb47f7bc34f3499dcda3\",\"members\":[{\"provenance\":{\"eventId\":\"lysa\",\"kind\":\"mapEvent\",\"mapId\":\"map_port\"},\"sourceFingerprint\":\"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"},{\"provenance\":{\"kind\":\"scenarioSourceNode\",\"nodeId\":\"source\",\"scenarioId\":\"scenario_arrival\"},\"sourceFingerprint\":\"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\"}]}",
      "cohortFingerprint": "sha256:f24177958517d13922af29bc3e8a8b18cee0e4649ad6323144f61b45bb5fdb2f"
    }
  ]
}
````

</details>

### `packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json`

SHA-256: `6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c` — 703 lignes.

<details>
<summary>Contenu complet</summary>

````json
{
  "schemaVersion": 1,
  "maps": [
    {
      "id": "c1_map_a",
      "name": "Legacy corpus map A",
      "size": {"width": 8, "height": 8},
      "layers": [
        {
          "runtimeType": "object",
          "id": "events",
          "name": "Events"
        }
      ],
      "entities": [
        {
          "id": "npc_actor",
          "name": "Actor candidate",
          "kind": "npc",
          "pos": {"x": 1, "y": 1}
        },
        {
          "id": "near_entity",
          "name": "Near candidate",
          "kind": "custom",
          "pos": {"x": 5, "y": 6}
        },
        {
          "id": "overlap_a",
          "name": "Overlap A",
          "kind": "custom",
          "pos": {"x": 6, "y": 1}
        },
        {
          "id": "overlap_b",
          "name": "Overlap B",
          "kind": "custom",
          "pos": {"x": 6, "y": 1}
        }
      ],
      "triggers": [
        {
          "id": "evt_trigger_script",
          "name": "Legacy trigger",
          "type": "event",
          "area": {
            "pos": {"x": 3, "y": 1},
            "size": {"width": 1, "height": 1}
          }
        },
        {
          "id": "overlap_trigger",
          "name": "Overlap trigger",
          "type": "event",
          "area": {
            "pos": {"x": 6, "y": 1},
            "size": {"width": 1, "height": 1}
          }
        }
      ],
      "events": [
        {
          "id": "evt_actor_scene",
          "title": "Actor with Scene",
          "type": "actor",
          "position": {"layerId": "events", "x": 1, "y": 1},
          "metadata": {"legacy.note": "same footprint is only a hint"},
          "pages": [
            {
              "pageNumber": 0,
              "sceneTarget": {"sceneId": "scene_intro"},
              "metadata": {
                "eventBuilder.schemaVersion": "1",
                "eventBuilder.reusePolicy": "reusable"
              }
            }
          ]
        },
        {
          "id": "evt_object_message",
          "title": "Standalone object message",
          "type": "object",
          "position": {"layerId": "events", "x": 2, "y": 1},
          "pages": [
            {"pageNumber": 0, "message": "A legacy message."}
          ]
        },
        {
          "id": "evt_trigger_script",
          "title": "Trigger zone script",
          "type": "triggerZone",
          "position": {"layerId": "events", "x": 3, "y": 1},
          "pages": [
            {
              "pageNumber": 0,
              "script": {"scriptId": "script_legacy", "startNode": "start"}
            }
          ]
        },
        {
          "id": "evt_effect_mixed",
          "title": "Effect with mixed payload",
          "type": "effect",
          "position": {"layerId": "events", "x": 4, "y": 1},
          "pages": [
            {
              "pageNumber": 0,
              "script": {"scriptId": "script_legacy"},
              "message": "Opaque mixed behavior.",
              "metadata": {
                "eventBuilder.schemaVersion": "1",
                "eventBuilder.reusePolicy": "reuse-forever"
              }
            }
          ]
        },
        {
          "id": "evt_page_order",
          "title": "First-valid page order",
          "type": "actor",
          "position": {"layerId": "events", "x": 1, "y": 3},
          "pages": [
            {
              "pageNumber": 30,
              "condition": {
                "type": "flagIsSet",
                "params": {"flagName": "flagA"}
              },
              "isHidden": true,
              "message": "First page"
            },
            {
              "pageNumber": 20,
              "condition": {
                "type": "flagIsSet",
                "params": {"flagName": "flagB"}
              },
              "isDisabled": true,
              "message": "Second page"
            },
            {"pageNumber": 10, "message": "Fallback page"}
          ]
        },
        {
          "id": "evt_near",
          "title": "Near but not linked",
          "type": "actor",
          "position": {"layerId": "events", "x": 5, "y": 5},
          "pages": [{"pageNumber": 0, "message": "Near entity"}]
        },
        {
          "id": "evt_overlap",
          "title": "Ambiguous overlap",
          "type": "actor",
          "position": {"layerId": "events", "x": 6, "y": 1},
          "pages": [{"pageNumber": 0, "message": "Many candidates"}]
        },
        {
          "id": "evt_shared",
          "title": "Shared ID on map A",
          "type": "object",
          "position": {"layerId": "events", "x": 2, "y": 4},
          "pages": [
            {
              "pageNumber": 0,
              "condition": {
                "type": "eventIsConsumed",
                "params": {"eventId": "evt_shared"}
              },
              "sceneTarget": {"sceneId": "scene_shared_a"},
              "metadata": {"opaque.eventId": "evt_shared"}
            }
          ]
        },
        {
          "id": "evt_missing_layer",
          "title": "Unknown layer",
          "type": "object",
          "position": {"layerId": "missing", "x": 2, "y": 5},
          "pages": [{"pageNumber": 0}]
        },
        {
          "id": "evt_out_of_bounds",
          "title": "Out of bounds",
          "type": "object",
          "position": {"layerId": "events", "x": 99, "y": 99},
          "pages": [{"pageNumber": 0}]
        },
        {
          "id": "evt_duplicate_position_a",
          "title": "Duplicate position A",
          "type": "object",
          "position": {"layerId": "events", "x": 7, "y": 7},
          "pages": [{"pageNumber": 0}]
        },
        {
          "id": "evt_duplicate_position_b",
          "title": "Duplicate position B",
          "type": "object",
          "position": {"layerId": "events", "x": 7, "y": 7},
          "pages": [{"pageNumber": 0}]
        }
      ]
    },
    {
      "id": "c1_map_b",
      "name": "Legacy corpus map B",
      "size": {"width": 4, "height": 4},
      "layers": [
        {
          "runtimeType": "object",
          "id": "events",
          "name": "Events"
        }
      ],
      "events": [
        {
          "id": "evt_shared",
          "title": "Shared ID on map B",
          "type": "actor",
          "position": {"layerId": "events", "x": 1, "y": 1},
          "pages": [
            {
              "pageNumber": 0,
              "sceneTarget": {"sceneId": "scene_shared_b"}
            }
          ]
        }
      ]
    }
  ],
  "scenarios": [
    {
      "id": "scn_map_enter",
      "name": "Map enter source",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"},
          "metadata": {"eventV2.sceneId": "scene_map_enter"}
        },
        {
          "id": "dialogue",
          "type": "dialogue",
          "binding": {"dialogueId": "dialogue_map_enter"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "dialogue"},
        {"id": "e2", "fromNodeId": "dialogue", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_trigger_enter",
      "name": "Trigger enter source",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a", "triggerId": "evt_trigger_script"},
          "payload": {"actionKind": "sourceTriggerEnter"},
          "metadata": {"eventV2.sceneId": "scene_trigger_enter"}
        },
        {
          "id": "dialogue",
          "type": "dialogue",
          "binding": {"dialogueId": "dialogue_trigger"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "dialogue"},
        {"id": "e2", "fromNodeId": "dialogue", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_entity_a",
      "name": "Entity source A",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a", "entityId": "npc_actor"},
          "payload": {"actionKind": "sourceEntityInteract"},
          "metadata": {"eventV2.sceneId": "scene_entity"}
        },
        {
          "id": "dialogue",
          "type": "dialogue",
          "binding": {"dialogueId": "dialogue_entity"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "dialogue"},
        {"id": "e2", "fromNodeId": "dialogue", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_entity_b",
      "name": "Entity source B",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a", "entityId": "npc_actor"},
          "payload": {"actionKind": "sourceEntityInteract"},
          "metadata": {"eventV2.sceneId": "scene_entity"}
        },
        {
          "id": "dialogue",
          "type": "dialogue",
          "binding": {"dialogueId": "dialogue_entity"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "dialogue"},
        {"id": "e2", "fromNodeId": "dialogue", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_outcome",
      "name": "Outcome source",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"outcomeId": "victory"},
          "payload": {"actionKind": "sourceOutcome"},
          "metadata": {"eventV2.sceneId": "scene_outcome"}
        },
        {
          "id": "dialogue",
          "type": "dialogue",
          "binding": {"dialogueId": "dialogue_outcome"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "dialogue"},
        {"id": "e2", "fromNodeId": "dialogue", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_multi_source",
      "name": "Multiple source nodes",
      "entryNodeId": "source_a",
      "nodes": [
        {
          "id": "source_a",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {
          "id": "source_b",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {"id": "message_a", "type": "action", "payload": {"actionKind": "showMessage", "message": "A"}},
        {"id": "message_b", "type": "action", "payload": {"actionKind": "showMessage", "message": "B"}},
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source_a", "toNodeId": "message_a"},
        {"id": "e2", "fromNodeId": "source_b", "toNodeId": "message_b"},
        {"id": "e3", "fromNodeId": "message_a", "toNodeId": "end"},
        {"id": "e4", "fromNodeId": "message_b", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_complex",
      "name": "Complex branching graph",
      "entryNodeId": "source",
      "activationCondition": {"type": "flagIsSet", "params": {"flagName": "quest_open"}},
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {
          "id": "condition",
          "type": "condition",
          "payload": {"condition": {"type": "flagIsSet", "params": {"flagName": "branch"}}}
        },
        {"id": "set", "type": "action", "payload": {"actionKind": "setFlag", "params": {"flagName": "done"}}},
        {"id": "clear", "type": "action", "payload": {"actionKind": "clearFlag", "params": {"flagName": "done"}}},
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "condition"},
        {"id": "e2", "fromNodeId": "condition", "toNodeId": "set", "kind": "trueBranch"},
        {"id": "e3", "fromNodeId": "condition", "toNodeId": "clear", "kind": "falseBranch"},
        {"id": "e4", "fromNodeId": "set", "toNodeId": "end"},
        {"id": "e5", "fromNodeId": "clear", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_choice",
      "name": "Unsupported choice",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {"id": "choice", "type": "choice", "payload": {"choiceLabels": ["A", "B"]}},
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "choice"},
        {"id": "e2", "fromNodeId": "choice", "toNodeId": "end", "kind": "choice"}
      ]
    },
    {
      "id": "scn_malformed",
      "name": "Malformed entity source",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceEntityInteract"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_wildcard",
      "name": "Legacy empty map wildcard",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": ""},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "end"}
      ]
    },
    {
      "id": "scn_command",
      "name": "Scenario event command reference",
      "entryNodeId": "source",
      "nodes": [
        {
          "id": "source",
          "type": "reference",
          "binding": {"mapId": "c1_map_a"},
          "payload": {"actionKind": "sourceMapEnter"}
        },
        {
          "id": "command",
          "type": "action",
          "binding": {"mapId": "c1_map_a", "eventId": "evt_shared"},
          "payload": {"actionKind": "markEventConsumed"}
        },
        {"id": "end", "type": "end"}
      ],
      "edges": [
        {"id": "e1", "fromNodeId": "source", "toNodeId": "command"},
        {"id": "e2", "fromNodeId": "command", "toNodeId": "end"}
      ]
    }
  ],
  "scenes": [
    {
      "id": "scene_map_enter",
      "name": "Map enter equivalent Scene",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {"id": "start", "kind": "start"},
          {"id": "dialogue", "kind": "yarnDialogue", "payload": {"kind": "yarnDialogue", "dialogueId": "dialogue_map_enter"}},
          {"id": "end", "kind": "end"}
        ],
        "edges": [
          {"id": "e1", "fromNodeId": "start", "fromPortId": "completed", "toNodeId": "dialogue", "kind": "default"},
          {"id": "e2", "fromNodeId": "dialogue", "fromPortId": "completed", "toNodeId": "end", "kind": "default"}
        ]
      }
    },
    {
      "id": "scene_trigger_enter",
      "name": "Trigger enter equivalent Scene",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {"id": "start", "kind": "start"},
          {"id": "dialogue", "kind": "yarnDialogue", "payload": {"kind": "yarnDialogue", "dialogueId": "dialogue_trigger"}},
          {"id": "end", "kind": "end"}
        ],
        "edges": [
          {"id": "e1", "fromNodeId": "start", "fromPortId": "completed", "toNodeId": "dialogue", "kind": "default"},
          {"id": "e2", "fromNodeId": "dialogue", "fromPortId": "completed", "toNodeId": "end", "kind": "default"}
        ]
      }
    },
    {
      "id": "scene_entity",
      "name": "Entity equivalent Scene",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {"id": "start", "kind": "start"},
          {"id": "dialogue", "kind": "yarnDialogue", "payload": {"kind": "yarnDialogue", "dialogueId": "dialogue_entity"}},
          {"id": "end", "kind": "end"}
        ],
        "edges": [
          {"id": "e1", "fromNodeId": "start", "fromPortId": "completed", "toNodeId": "dialogue", "kind": "default"},
          {"id": "e2", "fromNodeId": "dialogue", "fromPortId": "completed", "toNodeId": "end", "kind": "default"}
        ]
      }
    },
    {
      "id": "scene_outcome",
      "name": "Outcome equivalent Scene",
      "graph": {
        "startNodeId": "start",
        "nodes": [
          {"id": "start", "kind": "start"},
          {"id": "dialogue", "kind": "yarnDialogue", "payload": {"kind": "yarnDialogue", "dialogueId": "dialogue_outcome"}},
          {"id": "end", "kind": "end"}
        ],
        "edges": [
          {"id": "e1", "fromNodeId": "start", "fromPortId": "completed", "toNodeId": "dialogue", "kind": "default"},
          {"id": "e2", "fromNodeId": "dialogue", "fromPortId": "completed", "toNodeId": "end", "kind": "default"}
        ]
      }
    }
  ],
  "gameStates": [
    {
      "saveId": "save_c1",
      "consumedEventIds": ["evt_shared"],
      "metadata": {"fixture": "save_v1"}
    }
  ],
  "worldRules": [
    {
      "id": "rule_consumed",
      "label": "Shared event consumed",
      "source": {"kind": "consumedEvent", "sourceId": "evt_shared", "predicate": "consumed"},
      "target": {"kind": "mapEntity", "mapId": "c1_map_a", "entityId": "npc_actor"},
      "effect": {"kind": "entityVisible"}
    },
    {
      "id": "rule_visibility",
      "label": "Shared event visibility",
      "source": {"kind": "fact", "sourceId": "fact_ready", "predicate": "isTrue"},
      "target": {"kind": "mapEvent", "mapId": "c1_map_a", "eventId": "evt_shared"},
      "effect": {"kind": "eventHidden"}
    }
  ],
  "sceneConsequences": [
    {
      "kind": "markEventConsumed",
      "mapId": "c1_map_a",
      "eventId": "evt_shared",
      "label": "Consume shared map event"
    }
  ],
  "scripts": [
    {
      "id": "script_legacy",
      "defaultStartNode": "start",
      "nodes": [
        {
          "id": "start",
          "commands": [
            {"type": "markEventConsumed", "params": {"eventId": "evt_shared"}},
            {"type": "end"}
          ]
        }
      ],
      "metadata": {"relatedEventId": "evt_shared"}
    }
  ],
  "decodeProbes": [
    {
      "id": "event_position_without_layer",
      "kind": "MapEventDefinition",
      "expected": "decodeFailure",
      "json": {
        "id": "evt_missing_layer_field",
        "pages": [{"pageNumber": 0}],
        "position": {"x": 1, "y": 1}
      }
    },
    {
      "id": "unknown_legacy_payload",
      "kind": "unknownJson",
      "expected": "preservedOrBlocked",
      "expectedCanonicalSha256": "f22dbb03c59079484616d870df8f3b3133ef5c0324f835c3e2e81a74382decae",
      "json": {"futureBehavior": {"opcode": 91, "payload": [1, 2, 3]}}
    }
  ],
  "cases": [
    {"id": "ME_ACTOR_SCENE", "subject": "mapEvent:c1_map_a:evt_actor_scene", "classification": "ASSISTED", "decodeBehavior": "MapEventDefinition decodes without normalization of the raw fixture.", "runtimeBehavior": "The active page can target scene_intro when interaction is dispatched.", "sourceOfTruth": "MapEventDefinition pages and EventPosition.", "outgoingReferences": ["scene_intro"], "incomingReferences": [], "conversionPossibility": "One entity shares the footprint, but confirmation is required because position is not identity.", "lossRisk": "Selecting the wrong entity would redirect the trigger.", "features": ["actor", "sceneTarget", "validEventBuilderMetadata", "exactSingleFootprintHint"]},
    {"id": "ME_OBJECT_MESSAGE", "subject": "mapEvent:c1_map_a:evt_object_message", "classification": "BLOCKED", "decodeBehavior": "MapEventDefinition decodes the message page.", "runtimeBehavior": "Interaction shows the legacy message without a Scene.", "sourceOfTruth": "MapEventDefinition message payload.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "A source and Scene must be selected explicitly.", "lossRisk": "Message behavior would disappear if converted as an empty Event.", "features": ["object", "message", "noScene", "standalone"]},
    {"id": "ME_TRIGGER_SCRIPT", "subject": "mapEvent:c1_map_a:evt_trigger_script", "classification": "LEGACY_ONLY", "decodeBehavior": "MapEventDefinition decodes the script reference.", "runtimeBehavior": "The current MapEvent triggerZone path does not dispatch on zone entry.", "sourceOfTruth": "MapEventDefinition script and current runtime handler.", "outgoingReferences": ["script_legacy"], "incomingReferences": [], "conversionPossibility": "Keep under the legacy adapter until runtime semantics are proven.", "lossRisk": "Claiming it now could hide the only legacy handler.", "features": ["triggerZone", "script", "sameIdTrigger", "runtimeTriggerZonePartial"]},
    {"id": "ME_EFFECT_MIXED", "subject": "mapEvent:c1_map_a:evt_effect_mixed", "classification": "UNSUPPORTED", "decodeBehavior": "MapEventDefinition preserves script, message and malformed metadata values.", "runtimeBehavior": "Legacy effect semantics combine opaque payloads outside Event V2 V0.", "sourceOfTruth": "Complete MapEventDefinition raw JSON.", "outgoingReferences": ["script_legacy"], "incomingReferences": [], "conversionPossibility": "No V0 source or equivalent Scene is known.", "lossRisk": "Flattening would drop at least one payload.", "features": ["effect", "scriptAndMessage", "malformedEventBuilderMetadata"]},
    {"id": "ME_PAGE_ORDER", "subject": "mapEvent:c1_map_a:evt_page_order", "classification": "BLOCKED", "decodeBehavior": "Pages remain in list order 30, 20, 10.", "runtimeBehavior": "EventPageResolver selects the first condition-valid page and ignores hidden/disabled flags.", "sourceOfTruth": "MapEventDefinition page list order and gameplay resolver.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Several records may be needed; no flattening is allowed.", "lossRisk": "Reordering or filtering pages changes observable behavior.", "features": ["multiplePages", "firstValid", "fallbackPage", "hiddenPage", "disabledPage", "conditions"]},
    {"id": "ME_NEAR_ENTITY", "subject": "mapEvent:c1_map_a:evt_near", "classification": "BLOCKED", "decodeBehavior": "MapEventDefinition decodes with a valid position.", "runtimeBehavior": "The Event remains autonomous; proximity creates no identity link.", "sourceOfTruth": "MapEventDefinition and MapEntity geometry remain separate.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "A source must be chosen or materialized explicitly.", "lossRisk": "Nearest-neighbor inference can bind the wrong actor.", "features": ["nearEntity", "positionOnly"]},
    {"id": "ME_AMBIGUOUS_OVERLAP", "subject": "mapEvent:c1_map_a:evt_overlap", "classification": "BLOCKED", "decodeBehavior": "MapEventDefinition decodes despite overlapping sources.", "runtimeBehavior": "The legacy Event owns its position independently.", "sourceOfTruth": "MapEventDefinition, two MapEntities and one MapTrigger.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "User choice is mandatory among multiple candidates.", "lossRisk": "Any automatic source choice is ambiguous.", "features": ["multipleEntitiesSameFootprint", "entityAndTriggerOverlap"]},
    {"id": "ME_ID_COLLISION_A", "subject": "mapEvent:c1_map_a:evt_shared", "classification": "BLOCKED", "decodeBehavior": "The map-local ID decodes normally.", "runtimeBehavior": "Bare references and consumed state fan out to two map-local definitions.", "sourceOfTruth": "Qualified mapId plus eventId and the reference inventory.", "outgoingReferences": ["evt_shared", "scene_shared_a"], "incomingReferences": ["save_c1", "rule_consumed", "rule_visibility", "sceneConsequence", "script_legacy", "scn_command"], "conversionPossibility": "An explicit collision resolution is required.", "lossRisk": "Selecting the first map changes progression and visibility.", "features": ["duplicateIdAcrossMaps", "eventReferencedByCondition", "alreadyConsumed", "worldRuleReference", "sceneConsequenceReference"]},
    {"id": "ME_ID_COLLISION_B", "subject": "mapEvent:c1_map_b:evt_shared", "classification": "BLOCKED", "decodeBehavior": "The second map-local ID decodes normally.", "runtimeBehavior": "The same bare consumed bit can address this Event too.", "sourceOfTruth": "Qualified mapId plus eventId.", "outgoingReferences": ["scene_shared_b"], "incomingReferences": ["save_c1", "rule_consumed", "script_legacy"], "conversionPossibility": "An explicit collision resolution is required.", "lossRisk": "Dropping this candidate loses a reachable legacy behavior.", "features": ["duplicateIdAcrossMaps"]},
    {"id": "ME_MISSING_LAYER", "subject": "mapEvent:c1_map_a:evt_missing_layer", "classification": "BLOCKED", "decodeBehavior": "JSON decodes but semantic map validation rejects the unknown layer.", "runtimeBehavior": "No valid placement layer exists.", "sourceOfTruth": "MapData layer catalog and EventPosition.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Repair the layer or choose a source explicitly.", "lossRisk": "Ignoring the invalid layer hides a placement defect.", "features": ["unknownLayer"]},
    {"id": "ME_OUT_OF_BOUNDS", "subject": "mapEvent:c1_map_a:evt_out_of_bounds", "classification": "BLOCKED", "decodeBehavior": "JSON decodes but semantic map validation rejects the position.", "runtimeBehavior": "The placement lies outside the map bounds.", "sourceOfTruth": "MapData size and EventPosition.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Repair placement before migration.", "lossRisk": "Clamping silently changes location.", "features": ["outOfBounds"]},
    {"id": "ME_DUPLICATE_POSITION", "subject": "mapEvent:c1_map_a:evt_duplicate_position_a", "classification": "BLOCKED", "decodeBehavior": "Both Events decode at the same coordinate.", "runtimeBehavior": "They remain distinct legacy handlers.", "sourceOfTruth": "Qualified map-local Event identities.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "No source can be inferred from the shared coordinate.", "lossRisk": "Merging them would drop a handler.", "features": ["multipleEventsSamePosition"]},
    {"id": "ME_DUPLICATE_POSITION_B", "subject": "mapEvent:c1_map_a:evt_duplicate_position_b", "classification": "BLOCKED", "decodeBehavior": "The second Event decodes at the same coordinate as its sibling.", "runtimeBehavior": "It remains a distinct legacy handler.", "sourceOfTruth": "Qualified map-local Event identities.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "No source can be inferred from the shared coordinate.", "lossRisk": "Omitting this sibling would make a future claim incomplete.", "features": ["multipleEventsSamePosition"]},
    {"id": "SC_MAP_ENTER", "subject": "scenarioSourceNode:scn_map_enter:source", "classification": "AUTO_SAFE", "decodeBehavior": "ScenarioAsset and its referenced SceneAsset decode.", "runtimeBehavior": "mapEnter reaches exactly one dialogue then end.", "sourceOfTruth": "Scenario graph plus structurally equivalent Scene graph.", "outgoingReferences": ["scene_map_enter", "dialogue_map_enter"], "incomingReferences": [], "conversionPossibility": "The one-dialogue trace is structurally identical and requires no choice.", "lossRisk": "None while the source and full Scenario fingerprint remain stable.", "features": ["mapEnter", "singleSource", "singleSceneCandidate"]},
    {"id": "SC_TRIGGER_ENTER", "subject": "scenarioSourceNode:scn_trigger_enter:source", "classification": "AUTO_SAFE", "decodeBehavior": "ScenarioAsset and its referenced SceneAsset decode.", "runtimeBehavior": "triggerEnter reaches exactly one dialogue then end.", "sourceOfTruth": "Scenario graph plus structurally equivalent Scene graph.", "outgoingReferences": ["scene_trigger_enter", "dialogue_trigger"], "incomingReferences": [], "conversionPossibility": "The one-dialogue trace is structurally identical and requires no choice.", "lossRisk": "None while the source and full Scenario fingerprint remain stable.", "features": ["triggerEnter", "singleSource", "singleSceneCandidate"]},
    {"id": "SC_ENTITY_A", "subject": "scenarioSourceNode:scn_entity_a:source", "classification": "AUTO_SAFE", "decodeBehavior": "ScenarioAsset and scene_entity decode.", "runtimeBehavior": "entityInteract reaches exactly one dialogue then end.", "sourceOfTruth": "Scenario graph plus structurally equivalent Scene graph.", "outgoingReferences": ["scene_entity", "dialogue_entity"], "incomingReferences": [], "conversionPossibility": "The source and one-dialogue trace are explicit.", "lossRisk": "None only when both same-source Scenario handlers are claimed together.", "features": ["entityInteract", "singleSource", "singleSceneCandidate", "claimedSource"]},
    {"id": "SC_ENTITY_B", "subject": "scenarioSourceNode:scn_entity_b:source", "classification": "AUTO_SAFE", "decodeBehavior": "ScenarioAsset and scene_entity decode.", "runtimeBehavior": "entityInteract reaches exactly one dialogue then end.", "sourceOfTruth": "Scenario graph plus structurally equivalent Scene graph.", "outgoingReferences": ["scene_entity", "dialogue_entity"], "incomingReferences": [], "conversionPossibility": "The source and one-dialogue trace are explicit.", "lossRisk": "None only when both same-source Scenario handlers are claimed together.", "features": ["entityInteract", "singleSource", "singleSceneCandidate", "claimedSource"]},
    {"id": "SC_OUTCOME", "subject": "scenarioSourceNode:scn_outcome:source", "classification": "ASSISTED", "decodeBehavior": "ScenarioAsset and scene_outcome decode.", "runtimeBehavior": "The raw outcome reaches one dialogue then end.", "sourceOfTruth": "ScenarioAsset raw outcome binding and producer inventory.", "outgoingReferences": ["scene_outcome", "dialogue_outcome", "victory"], "incomingReferences": [], "conversionPossibility": "A producer must be selected to qualify the outcome.", "lossRisk": "A wrong producer changes event identity.", "features": ["outcomeReceived", "unqualifiedOutcome", "singleSceneCandidate"]},
    {"id": "SC_MULTI_SOURCE", "subject": "scenario:scn_multi_source", "classification": "BLOCKED", "decodeBehavior": "Both source nodes and action branches decode.", "runtimeBehavior": "First matching Scenario/source order can select different messages.", "sourceOfTruth": "Complete ScenarioAsset node and edge order.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Split only after proving complete source cohorts.", "lossRisk": "Claiming one source node can hide the sibling handler.", "features": ["multipleSourceNodes", "multipleActions"]},
    {"id": "SC_COMPLEX", "subject": "scenario:scn_complex", "classification": "LEGACY_ONLY", "decodeBehavior": "Activation condition, branch and actions decode.", "runtimeBehavior": "The condition chooses true or false action paths.", "sourceOfTruth": "Complete ScenarioAsset graph.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Remain under the legacy adapter; Event V2 must not absorb orchestration.", "lossRisk": "Flattening loses branch and action order.", "features": ["activationCondition", "complexGraph", "branches", "multipleActions"]},
    {"id": "SC_CHOICE", "subject": "scenario:scn_choice", "classification": "UNSUPPORTED", "decodeBehavior": "The choice graph decodes.", "runtimeBehavior": "ScenarioRuntimeExecutor blocks explicitly on choice.", "sourceOfTruth": "Complete ScenarioAsset graph and runtime executor.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "No V0 conversion is available.", "lossRisk": "Flattening discards player choice.", "features": ["choice", "nonConvertibleAction"]},
    {"id": "SC_MALFORMED", "subject": "scenarioSourceNode:scn_malformed:source", "classification": "BLOCKED", "decodeBehavior": "The permissive legacy codec decodes a missing entityId.", "runtimeBehavior": "The source cannot match a valid entity interaction.", "sourceOfTruth": "Raw ScenarioNodeBinding and runtime matcher.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Repair the binding explicitly.", "lossRisk": "Guessing an entity redirects behavior.", "features": ["malformedBinding"]},
    {"id": "SC_WILDCARD", "subject": "scenarioSourceNode:scn_wildcard:source", "classification": "BLOCKED", "decodeBehavior": "The permissive legacy codec preserves the empty mapId.", "runtimeBehavior": "Legacy matching may treat the empty map as a wildcard.", "sourceOfTruth": "Raw ScenarioNodeBinding and runtime matcher.", "outgoingReferences": [], "incomingReferences": [], "conversionPossibility": "Choose an explicit map before conversion.", "lossRisk": "Picking one map narrows legacy reachability.", "features": ["emptyMapIdWildcard"]},
    {"id": "SC_COMMAND", "subject": "scenario:scn_command", "classification": "LEGACY_ONLY", "decodeBehavior": "ScenarioNodeBinding preserves the qualified map event reference.", "runtimeBehavior": "The legacy action kind remains outside Event V2 V0.", "sourceOfTruth": "Complete ScenarioAsset graph.", "outgoingReferences": ["c1_map_a:evt_shared"], "incomingReferences": [], "conversionPossibility": "Keep the orchestration legacy and map the reference later.", "lossRisk": "Dropping the command changes consumed progression.", "features": ["scenarioEventReference", "nonConvertibleAction"]}
  ],
  "pageOrders": {
    "mapEvent:c1_map_a:evt_actor_scene": [0],
    "mapEvent:c1_map_a:evt_object_message": [0],
    "mapEvent:c1_map_a:evt_trigger_script": [0],
    "mapEvent:c1_map_a:evt_effect_mixed": [0],
    "mapEvent:c1_map_a:evt_page_order": [30, 20, 10],
    "mapEvent:c1_map_a:evt_near": [0],
    "mapEvent:c1_map_a:evt_overlap": [0],
    "mapEvent:c1_map_a:evt_shared": [0],
    "mapEvent:c1_map_b:evt_shared": [0],
    "mapEvent:c1_map_a:evt_missing_layer": [0],
    "mapEvent:c1_map_a:evt_out_of_bounds": [0],
    "mapEvent:c1_map_a:evt_duplicate_position_a": [0],
    "mapEvent:c1_map_a:evt_duplicate_position_b": [0],
    "scenarioSourceNode:scn_map_enter:source": [],
    "scenarioSourceNode:scn_trigger_enter:source": [],
    "scenarioSourceNode:scn_entity_a:source": [],
    "scenarioSourceNode:scn_entity_b:source": [],
    "scenarioSourceNode:scn_outcome:source": [],
    "scenario:scn_multi_source": [],
    "scenario:scn_complex": [],
    "scenario:scn_choice": [],
    "scenarioSourceNode:scn_malformed:source": [],
    "scenarioSourceNode:scn_wildcard:source": [],
    "scenario:scn_command": []
  },
  "references": [
    {"kind": "GameState.consumedEventIds", "path": "gameStates.save_c1.consumedEventIds[0]", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]},
    {"kind": "ScriptCondition", "path": "maps.c1_map_a.events.evt_shared.pages[0].condition", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]},
    {"kind": "WorldRuleDefinition.source", "path": "worldRules.rule_consumed.source", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]},
    {"kind": "WorldRuleDefinition.target", "path": "worldRules.rule_visibility.target", "rawId": "evt_shared", "mapId": "c1_map_a", "candidates": ["c1_map_a:evt_shared"]},
    {"kind": "EventSceneLinkDiagnostic", "path": "diagnostics.eventSceneLinks[0]", "rawId": "evt_actor_scene", "mapId": "c1_map_a", "candidates": ["c1_map_a:evt_actor_scene"]},
    {"kind": "EventSceneLinkDiagnostic", "path": "diagnostics.eventSceneLinks[1]", "rawId": "evt_shared", "mapId": "c1_map_a", "candidates": ["c1_map_a:evt_shared"]},
    {"kind": "EventSceneLinkDiagnostic", "path": "diagnostics.eventSceneLinks[2]", "rawId": "evt_shared", "mapId": "c1_map_b", "candidates": ["c1_map_b:evt_shared"]},
    {"kind": "SceneConsequence", "path": "sceneConsequences[0]", "rawId": "evt_shared", "mapId": "c1_map_a", "candidates": ["c1_map_a:evt_shared"]},
    {"kind": "ScenarioNodeBinding", "path": "scenarios.scn_command.nodes.command.binding", "rawId": "evt_shared", "mapId": "c1_map_a", "candidates": ["c1_map_a:evt_shared"]},
    {"kind": "ScriptCommand", "path": "scripts.script_legacy.nodes.start.commands[0]", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]},
    {"kind": "metadata", "path": "maps.c1_map_a.events.evt_shared.pages[0].metadata.opaque.eventId", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]},
    {"kind": "metadata", "path": "scripts.script_legacy.metadata.relatedEventId", "rawId": "evt_shared", "candidates": ["c1_map_a:evt_shared", "c1_map_b:evt_shared"]}
  ],
  "cohorts": [
    {
      "id": "entity_actor_complete",
      "source": {"kind": "entityInteract", "mapId": "c1_map_a", "entityId": "npc_actor"},
      "members": [
        {"kind": "scenarioSourceNode", "scenarioId": "scn_entity_a", "nodeId": "source"},
        {"kind": "scenarioSourceNode", "scenarioId": "scn_entity_b", "nodeId": "source"}
      ]
    }
  ],
  "goldens": {
    "mapEventFingerprint": "sha256:b37cfbf34d95a6723c771e56db5f5bfaaa9c76864259f82043bf77115edb4530",
    "scenarioFingerprintA": "sha256:655b19d6f9ae64d409d37908e50ca90f346a45e7cbc3986a1417603f857f41bf",
    "scenarioFingerprintB": "sha256:b4419149ccbd6f72a7f37297aa63a6b91118c63512a2bf2c074abc1fb7053ca3",
    "cohortId": "lsc_c0030af572aefe602d6441f0f4582c6243e68d777a71938eea296906483d1163",
    "cohortFingerprint": "sha256:2abf064b57b6b9539bc093257691665269c7e32c7d23f026b2ca115944c4fb5d"
  }
}
````

</details>

### `packages/map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.sha256`

SHA-256: `3b663ef48a710a009c57357aeda643b8427d2d3f96c1157877c6420f88fddbd9` — 1 lignes.

<details>
<summary>Contenu complet</summary>

````text
6aa7be80b6819d1b9d2f062172e8bca511cbf82fde98a3863eb3e7f856d5c86c  corpus_v0.json
````

</details>

### `packages/map_core/test/legacy_map_event_projection_test.dart`

SHA-256: `b446a0e97de2a4541b8237becc5d95b9f0c505b5bfa7482c96f63783dacd0de8` — 653 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C2 MapEvent read-only projection', () {
    test('explicit actor and object links are AUTO_SAFE and confirmed', () {
      for (final type in [MapEventType.actor, MapEventType.object]) {
        final event = _event(
          id: 'legacy_${type.name}',
          type: type,
          metadata: {
            LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
          },
        );
        final map = _map(
          events: [event],
          entities: [_entity('entity_a', 1, 1)],
        );

        final projection = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: _emptyClaimIndex(),
        );

        expect(
            projection.classification, LegacyMigrationClassification.autoSafe);
        expect(projection.confirmedSource,
            NarrativeEventSourceRef.entityInteract(map.id, 'entity_a'));
        expect(projection.sourceCandidates.single.confirmed, isTrue);
      }
    });

    test('position-only evidence stays ASSISTED and never confirms a source',
        () {
      final event = _event(id: 'legacy_position_only');
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.assisted);
      expect(projection.confirmedSource, isNull);
      expect(projection.sourceCandidates.single.source,
          NarrativeEventSourceRef.entityInteract(map.id, 'entity_a'));
      expect(projection.sourceCandidates.single.confirmed, isFalse);
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.positionIsOnlyEvidence),
      );
    });

    test('ambiguous overlap and standalone Events remain BLOCKED', () {
      final event = _event(id: 'legacy_ambiguous');
      final ambiguousMap = _map(
        events: [event],
        entities: [
          _entity('entity_a', 1, 1),
          _entity('entity_b', 1, 1),
        ],
      );
      final ambiguous = projectLegacyMapEventReadOnly(
        mapId: ambiguousMap.id,
        map: ambiguousMap,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );
      expect(ambiguous.classification, LegacyMigrationClassification.blocked);
      expect(ambiguous.sourceCandidates, hasLength(2));
      expect(ambiguous.confirmedSource, isNull);

      final standaloneMap = _map(events: [event]);
      final standalone = projectLegacyMapEventReadOnly(
        mapId: standaloneMap.id,
        map: standaloneMap,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );
      expect(standalone.classification, LegacyMigrationClassification.blocked);
      expect(standalone.sourceCandidates, isEmpty);
    });

    test('trigger candidate stays LEGACY_ONLY until runtime parity is proven',
        () {
      final event = _event(
        id: 'legacy_trigger',
        type: MapEventType.triggerZone,
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.triggerId: 'trigger_a',
        },
      );
      final map = _map(
        events: [event],
        triggers: [_trigger('trigger_a', 1, 1)],
      );

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(
          projection.classification, LegacyMigrationClassification.legacyOnly);
      expect(projection.confirmedSource,
          NarrativeEventSourceRef.triggerEnter(map.id, 'trigger_a'));
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.triggerRuntimeParityUnproven),
      );
    });

    test('effect and opaque page payloads are UNSUPPORTED', () {
      final effect = _event(id: 'legacy_effect', type: MapEventType.effect);
      final script = _event(
        id: 'legacy_script',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
        pages: const [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
            script: ScriptRef(scriptId: 'opaque_script'),
            message: 'legacy message',
          ),
        ],
      );
      final map = _map(
        events: [effect, script],
        entities: [_entity('entity_a', 1, 1)],
      );

      final effectProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: effect,
        claimIndex: _emptyClaimIndex(),
      );
      final scriptProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: script,
        claimIndex: _emptyClaimIndex(),
      );
      expect(effectProjection.classification,
          LegacyMigrationClassification.unsupported);
      expect(scriptProjection.classification,
          LegacyMigrationClassification.unsupported);
      expect(scriptProjection.unconvertibleDataPaths,
          containsAll(['pages[0].script', 'pages[0].message']));
    });

    test('multi-page order is preserved and never flattened', () {
      final event = _event(
        id: 'legacy_pages',
        pages: const [
          MapEventPage(pageNumber: 30),
          MapEventPage(pageNumber: 20, isDisabled: true),
          MapEventPage(pageNumber: 10, isHidden: true),
        ],
      );
      final map = _map(events: [event]);

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(projection.pages.map((page) => page.pageNumber), [30, 20, 10]);
      expect(projection.pages[1].isDisabled, isTrue);
      expect(projection.pages[2].isHidden, isTrue);
      expect(projection.manualActions, isNotEmpty);
    });

    test('invalid map, layer, position, and broken explicit source block', () {
      final event = _event(
        id: 'legacy_invalid',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'missing_entity',
        },
        position: const EventPosition(layerId: 'missing_layer', x: 99, y: 99),
      );
      final map = _map(events: [event]);
      final projection = projectLegacyMapEventReadOnly(
        mapId: 'different_map',
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(
        projection.diagnostics.map((value) => value.code),
        containsAll({
          LegacyMapEventDiagnosticCodes.mapIdentityMismatch,
          LegacyMapEventDiagnosticCodes.layerMissing,
          LegacyMapEventDiagnosticCodes.positionOutOfBounds,
          LegacyMapEventDiagnosticCodes.explicitSourceMissing,
        }),
      );
    });

    test('claim lookup distinguishes valid claim, tombstone, and absence', () {
      final event = _event(
        id: 'legacy_claimed',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final source = NarrativeEventSourceRef.entityInteract(map.id, 'entity_a');
      final valid = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: event,
          source: source,
          validTarget: true,
        ),
      );
      final tombstone = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: event,
          source: source,
          validTarget: false,
        ),
      );
      final absent = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        claimIndex: _emptyClaimIndex(),
      );

      expect(valid.claimStatus, LegacyProjectionClaimStatus.valid);
      expect(valid.existingClaim, isNotNull);
      expect(tombstone.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(tombstone.existingClaim, isNull);
      expect(tombstone.classification, LegacyMigrationClassification.blocked);
      expect(absent.claimStatus, LegacyProjectionClaimStatus.absent);
    });

    test('ambiguous and unresolved linked references block AUTO_SAFE', () {
      final event = _event(
        id: 'legacy_reference_collision',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final provenance = LegacySourceRef.mapEvent(map.id, event.id);
      LegacyMapEventProjection project(List<LegacySourceRef> candidates) {
        return projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: _emptyClaimIndex(),
          linkedReferences: [
            LegacyEventReference(
              kind: LegacyEventReferenceKind.consumedEventState,
              path: 'save.consumedEventIds[0]',
              legacyEventId: event.id,
              candidateProvenances: candidates,
            ),
          ],
        );
      }

      final ambiguous = project([
        provenance,
        LegacySourceRef.mapEvent('map_b', event.id),
      ]);
      final unresolved = project(const []);
      expect(ambiguous.classification, LegacyMigrationClassification.blocked);
      expect(unresolved.classification, LegacyMigrationClassification.blocked);
      expect(
        ambiguous.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.ambiguousLinkedReference),
      );
      expect(
        unresolved.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.unresolvedLinkedReference),
      );
    });

    test('stale or source-contradictory claims become local tombstones', () {
      final original = _event(
        id: 'legacy_stale_claim',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final changed = original.copyWith(title: 'Changed after claim');
      final map = _map(
        events: [changed],
        entities: [
          _entity('entity_a', 1, 1),
          _entity('entity_b', 2, 2),
        ],
      );
      final sourceA =
          NarrativeEventSourceRef.entityInteract(map.id, 'entity_a');
      final stale = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: changed,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: original,
          source: sourceA,
          validTarget: true,
        ),
      );
      final contradictory = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: changed,
        claimIndex: _claimIndex(
          mapId: map.id,
          event: changed,
          source: NarrativeEventSourceRef.entityInteract(map.id, 'entity_b'),
          validTarget: true,
        ),
      );

      expect(stale.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(stale.existingClaim, isNull);
      expect(stale.classification, LegacyMigrationClassification.blocked);
      expect(
        stale.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.claimFingerprintStale),
      );
      expect(contradictory.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(contradictory.existingClaim, isNull);
      expect(
        contradictory.diagnostics.map((value) => value.code),
        contains(LegacyMapEventDiagnosticCodes.claimSourceMismatch),
      );
    });

    test('raw unknown data is preserved and blocks conversion', () {
      final event = _event(
        id: 'legacy_unknown',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
      );
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final raw = Map<String, Object?>.from(event.toJson())
        ..['futureBehavior'] = {
          'opcode': 91,
          'payload': [1, 2, 3],
        };

      final projection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        rawEventJson: raw,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.blocked);
      expect(projection.preservedEventJson['futureBehavior'], isNotNull);
      expect(
        () => projection.preservedEventJson['mutate'] = true,
        throwsUnsupportedError,
      );

      final nestedRaw = Map<String, Object?>.from(
        jsonDecode(jsonEncode(event.toJson())) as Map,
      );
      final rawPages = nestedRaw['pages']! as List;
      final rawPage = rawPages.single as Map;
      final rawScene = rawPage['sceneTarget'] as Map;
      rawScene['futureField'] = {'nested': true};
      final nestedProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: event,
        rawEventJson: nestedRaw,
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        nestedProjection.unconvertibleDataPaths,
        contains('event.pages[0].sceneTarget.futureField'),
      );
      expect(nestedProjection.classification,
          LegacyMigrationClassification.blocked);
    });

    test('sprite payload and non-exact metadata cannot remain AUTO_SAFE', () {
      final sprite = _event(
        id: 'legacy_sprite',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: 'entity_a',
        },
        pages: const [
          MapEventPage(
            pageNumber: 0,
            spriteId: 'legacy_sprite_asset',
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
          ),
        ],
      );
      final spaced = _event(
        id: 'legacy_spaced_source',
        metadata: {
          LegacyMapEventCompatibilityMetadataKeys.entityId: ' entity_a ',
        },
      );
      final map = _map(
        events: [sprite, spaced],
        entities: [_entity('entity_a', 1, 1)],
      );
      final spriteProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: sprite,
        claimIndex: _emptyClaimIndex(),
      );
      final spacedProjection = projectLegacyMapEventReadOnly(
        mapId: map.id,
        map: map,
        event: spaced,
        claimIndex: _emptyClaimIndex(),
      );

      expect(spriteProjection.classification,
          LegacyMigrationClassification.assisted);
      expect(spriteProjection.unconvertibleDataPaths,
          contains('pages[0].spriteId'));
      expect(spacedProjection.classification,
          LegacyMigrationClassification.blocked);
      expect(spacedProjection.confirmedSource, isNull);
    });

    test('projection is immutable deterministic and never mutates inputs', () {
      final event = _event(id: 'legacy_deterministic');
      final map = _map(
        events: [event],
        entities: [_entity('entity_a', 1, 1)],
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.scriptCondition,
        path: 'maps.map_a.events.legacy_deterministic.pages[0].condition',
        legacyEventId: event.id,
        candidateProvenances: [LegacySourceRef.mapEvent(map.id, event.id)],
      );
      final before = canonicalizeNarrativeEventJson({
        'map': jsonDecode(jsonEncode(map.toJson())),
        'event': jsonDecode(jsonEncode(event.toJson())),
      });

      LegacyMapEventProjection run() => projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            linkedReferences: [reference],
            claimIndex: _emptyClaimIndex(),
          );
      final first = run();
      final second = run();

      expect(canonicalizeNarrativeEventJson(first.toJson()),
          canonicalizeNarrativeEventJson(second.toJson()));
      expect(
        canonicalizeNarrativeEventJson({
          'map': jsonDecode(jsonEncode(map.toJson())),
          'event': jsonDecode(jsonEncode(event.toJson())),
        }),
        before,
      );
      expect(() => first.pages.add(first.pages.single), throwsUnsupportedError);
      expect(() => first.linkedReferences.clear(), throwsUnsupportedError);
      expect(() => first.diagnostics.clear(), throwsUnsupportedError);

      final callerRaw = <String, Object?>{
        'nested': <Object?>[1],
      };
      final manuallyBuilt = LegacyMapEventProjection(
        provenance: first.provenance,
        classification: first.classification,
        claimStatus: first.claimStatus,
        existingClaim: first.existingClaim,
        sourceFingerprint: first.sourceFingerprint,
        sourceCandidates: first.sourceCandidates,
        pages: first.pages,
        preservedEventJson: callerRaw,
        unconvertibleDataPaths: first.unconvertibleDataPaths,
        linkedReferences: first.linkedReferences,
        diagnostics: first.diagnostics,
        manualActions: first.manualActions,
      );
      callerRaw['changed'] = true;
      (callerRaw['nested']! as List<Object?>).add(2);
      expect(manuallyBuilt.preservedEventJson, isNot(contains('changed')));
      expect(manuallyBuilt.preservedEventJson['nested'], [1]);
      expect(
        () => (manuallyBuilt.preservedEventJson['nested']! as List).add(3),
        throwsUnsupportedError,
      );
    });
  });
}

MapEventDefinition _event({
  required String id,
  MapEventType type = MapEventType.actor,
  Map<String, String> metadata = const {},
  EventPosition position = const EventPosition(layerId: 'events', x: 1, y: 1),
  List<MapEventPage> pages = const [
    MapEventPage(
      pageNumber: 0,
      sceneTarget: MapEventSceneTarget(sceneId: 'scene_a'),
    ),
  ],
}) {
  return MapEventDefinition(
    id: id,
    title: id,
    type: type,
    metadata: metadata,
    position: position,
    pages: pages,
  );
}

MapData _map({
  required List<MapEventDefinition> events,
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
}) {
  return MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    entities: entities,
    triggers: triggers,
    events: events,
  );
}

MapEntity _entity(String id, int x, int y) {
  return MapEntity(
    id: id,
    kind: MapEntityKind.custom,
    pos: GridPos(x: x, y: y),
  );
}

MapTrigger _trigger(String id, int x, int y) {
  return MapTrigger(
    id: id,
    type: TriggerType.event,
    area: MapRect(
      pos: GridPos(x: x, y: y),
      size: const GridSize(width: 1, height: 1),
    ),
  );
}

ValidatedLegacyClaimIndex _emptyClaimIndex() {
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    ),
  );
}

ValidatedLegacyClaimIndex _claimIndex({
  required String mapId,
  required MapEventDefinition event,
  required NarrativeEventSourceRef source,
  required bool validTarget,
}) {
  final provenance = LegacySourceRef.mapEvent(mapId, event.id);
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeMapEventSourceFingerprint(
      mapId: mapId,
      event: event,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const targetId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [targetId],
    migrationReceiptId: 'receipt_c2',
  );
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: validTarget
          ? [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: targetId,
                  name: 'C2 target',
                  source: source,
                  conditions: const [],
                  sceneId: 'scene_a',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: false,
              ),
            ]
          : const [],
      legacyClaims: [claim],
    ),
  );
}
````

</details>

### `packages/map_core/test/legacy_scenario_source_projection_test.dart`

SHA-256: `7c5e8855ce5a9b32fdb825369e1597250328f6aeb8e631e479e70a4b8f889efd` — 490 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C3 Scenario source projection', () {
    late List<ScenarioAsset> scenarios;
    late List<SceneAsset> scenes;

    setUpAll(() {
      final fixture = Map<String, Object?>.from(
        decodeNarrativeEventJsonStrict(
          File('test/fixtures/narrative_event_legacy_corpus/corpus_v0.json')
              .readAsStringSync(),
        )! as Map,
      );
      scenarios = List<Object?>.from(fixture['scenarios']! as List)
          .map(
            (value) => ScenarioAsset.fromJson(
              Map<String, dynamic>.from(value! as Map),
            ),
          )
          .toList(growable: false);
      scenes = List<Object?>.from(fixture['scenes']! as List)
          .map(
            (value) => SceneAsset.fromJson(
              Map<String, dynamic>.from(value! as Map),
            ),
          )
          .toList(growable: false);
    });

    test('projects all four simple source kinds without promoting Scenario',
        () {
      final cases = <String, NarrativeEventSourceKind>{
        'scn_map_enter': NarrativeEventSourceKind.mapEnter,
        'scn_trigger_enter': NarrativeEventSourceKind.triggerEnter,
        'scn_entity_a': NarrativeEventSourceKind.entityInteract,
      };
      for (final entry in cases.entries) {
        final scenario = _scenario(scenarios, entry.key);
        final node = _node(scenario, 'source');
        final projection = projectLegacyScenarioSourceReadOnly(
          scenario: scenario,
          node: node,
          scenes: scenes,
          claimIndex: _emptyClaimIndex(),
          lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
        );

        expect(projection.source?.kind, entry.value);
        expect(projection.sceneCandidateId, isNotNull);
        expect(
          projection.classification,
          LegacyMigrationClassification.autoSafe,
        );
        expect(projection.graphComplexity,
            LegacyScenarioGraphComplexity.simpleLinear);
        expect(projection.provenance,
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id));
      }

      final outcome = _project(scenarios, scenes, 'scn_outcome', 'source');
      expect(outcome.source, isNull);
      expect(outcome.sceneCandidateId, 'scene_outcome');
      expect(outcome.classification, LegacyMigrationClassification.assisted);
      expect(
        outcome.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.outcomeQualificationRequired),
      );
    });

    test('defaults lifecycle to ASSISTED until project evidence is supplied',
        () {
      final scenario = _scenario(scenarios, 'scn_map_enter');
      final projection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: _node(scenario, 'source'),
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.assisted);
      expect(
        projection.lifecycleEvidence,
        LegacyScenarioLifecycleEvidence.ambiguous,
      );
      expect(projection.reusePolicyCandidate, isNull);
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.lifecycleEvidenceMissing),
      );
    });

    test('complex, multi-source, choice, and malformed graphs never flatten',
        () {
      final complex = _project(scenarios, scenes, 'scn_complex', 'source');
      final multi = _project(scenarios, scenes, 'scn_multi_source', 'source_a');
      final choice = _project(scenarios, scenes, 'scn_choice', 'source');
      final malformed = _project(scenarios, scenes, 'scn_malformed', 'source');
      final wildcard = _project(scenarios, scenes, 'scn_wildcard', 'source');

      expect(complex.classification, LegacyMigrationClassification.legacyOnly);
      expect(complex.graphComplexity,
          LegacyScenarioGraphComplexity.branchingOrOrchestrated);
      expect(multi.classification, LegacyMigrationClassification.blocked);
      expect(
          multi.graphComplexity, LegacyScenarioGraphComplexity.multipleSources);
      expect(choice.classification, LegacyMigrationClassification.unsupported);
      expect(malformed.classification, LegacyMigrationClassification.blocked);
      expect(malformed.source, isNull);
      expect(wildcard.classification, LegacyMigrationClassification.blocked);
      expect(wildcard.source, isNull);
    });

    test('valid claim, tombstone, and stale full-Scenario hash are distinct',
        () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final node = _node(scenario, 'source');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final valid = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: node,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: true,
        ),
      );
      final tombstone = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: node,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: false,
        ),
      );
      final changed = scenario.copyWith(name: 'Changed after claim');
      final stale = projectLegacyScenarioSourceReadOnly(
        scenario: changed,
        node: _node(changed, 'source'),
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: true,
        ),
      );

      expect(valid.claimStatus, LegacyProjectionClaimStatus.valid);
      expect(valid.existingClaim, isNotNull);
      expect(tombstone.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(tombstone.classification, LegacyMigrationClassification.blocked);
      expect(stale.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(stale.existingClaim, isNull);
      expect(
        stale.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.claimFingerprintStale),
      );

      final outcomeScenario = _scenario(scenarios, 'scn_outcome');
      final outcomeNode = _node(outcomeScenario, 'source');
      final wrongOutcomeClaim = projectLegacyScenarioSourceReadOnly(
        scenario: outcomeScenario,
        node: outcomeNode,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: outcomeScenario,
          node: outcomeNode,
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_outcome',
              outcomeId: 'defeat',
            ),
          ),
          validTarget: true,
        ),
        lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
      );
      expect(
        wrongOutcomeClaim.claimStatus,
        LegacyProjectionClaimStatus.invalid,
      );
      expect(
        wrongOutcomeClaim.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.claimSourceMismatch),
      );
    });

    test('projection is immutable deterministic and does not mutate Scenario',
        () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final node = _node(scenario, 'source');
      final before = canonicalizeNarrativeEventJson(
        jsonDecode(jsonEncode(scenario.toJson())),
      );
      LegacyScenarioSourceProjection run() =>
          projectLegacyScenarioSourceReadOnly(
            scenario: scenario,
            node: node,
            scenes: scenes,
            claimIndex: _emptyClaimIndex(),
          );

      final first = run();
      final second = run();
      expect(canonicalizeNarrativeEventJson(first.toJson()),
          canonicalizeNarrativeEventJson(second.toJson()));
      expect(
        canonicalizeNarrativeEventJson(
          jsonDecode(jsonEncode(scenario.toJson())),
        ),
        before,
      );
      expect(() => first.actions.clear(), throwsUnsupportedError);
      expect(() => first.conditions.clear(), throwsUnsupportedError);
      expect(
        () => first.preservedScenarioJson['mutate'] = true,
        throwsUnsupportedError,
      );
    });

    test('detached node snapshots and incomplete Scene traces are blocked', () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final canonicalNode = _node(scenario, 'source');
      final detachedNode = canonicalNode.copyWith(
        binding: canonicalNode.binding.copyWith(entityId: 'other_entity'),
      );
      final detachedProjection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: detachedNode,
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        detachedProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        detachedProjection.source,
        NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor'),
      );
      expect(
        detachedProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.nodeSnapshotMismatch),
      );

      final missingNode = canonicalNode.copyWith(id: 'missing_source');
      final malformedEdges = scenario.copyWith(
        edges: [
          const ScenarioEdge(
            id: 'missing-dialogue',
            fromNodeId: 'missing_source',
            toNodeId: 'dialogue',
          ),
          scenario.edges.last,
        ],
      );
      final missingProjection = projectLegacyScenarioSourceReadOnly(
        scenario: malformedEdges,
        node: missingNode,
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
        lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
      );
      expect(
        missingProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        missingProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.nodeMissing),
      );

      final scene = scenes.singleWhere((value) => value.id == 'scene_entity');
      final sceneJson = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(scene.toJson())) as Map,
      );
      final graph = Map<String, dynamic>.from(sceneJson['graph']! as Map);
      final nodes = List<Object?>.from(graph['nodes']! as List);
      final dialogueIndex = nodes.indexWhere(
        (value) => (value! as Map)['kind'] == 'yarnDialogue',
      );
      final dialogue = Map<String, dynamic>.from(nodes[dialogueIndex]! as Map);
      final payload = Map<String, dynamic>.from(dialogue['payload']! as Map);
      payload['yarnNodeName'] = 'DifferentStartNode';
      dialogue['payload'] = payload;
      nodes[dialogueIndex] = dialogue;
      graph['nodes'] = nodes;
      sceneJson['graph'] = graph;
      final mismatchingScene = SceneAsset.fromJson(sceneJson);
      final traceProjection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: canonicalNode,
        scenes: [
          for (final candidate in scenes)
            if (candidate.id == scene.id) mismatchingScene else candidate,
        ],
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        traceProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        traceProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.sceneTraceMismatch),
      );
    });

    test('authoring guard freezes whole claimed Scenario and duplicate source',
        () {
      final claimed = _scenario(scenarios, 'scn_entity_a');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final claimIndex = _scenarioClaimIndex(
        scenario: claimed,
        node: _node(claimed, 'source'),
        source: source,
        validTarget: true,
      );
      final siblingEdit = claimed.copyWith(
        nodes: [
          for (final node in claimed.nodes)
            if (node.id == 'dialogue')
              node.copyWith(title: 'Edited sibling')
            else
              node,
        ],
      );
      final unrelated = _scenario(scenarios, 'scn_trigger_enter');
      final duplicate = _scenario(scenarios, 'scn_entity_b');

      final claimedGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        existingScenario: claimed,
        proposedScenario: siblingEdit,
      );
      final unrelatedGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        existingScenario: unrelated,
        proposedScenario: unrelated,
      );
      final duplicateGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        proposedScenario: duplicate,
      );

      expect(claimedGuard.blocked, isTrue);
      expect(claimedGuard.message, contains('Event Builder V2'));
      expect(unrelatedGuard.blocked, isFalse);
      expect(duplicateGuard.blocked, isTrue);
    });

    test('authoring guard mirrors wildcard maps and unqualified outcomes', () {
      final mapScenario = _scenario(scenarios, 'scn_map_enter');
      final mapClaimIndex = _scenarioClaimIndex(
        scenario: mapScenario,
        node: _node(mapScenario, 'source'),
        source: NarrativeEventSourceRef.mapEnter('c1_map_a'),
        validTarget: true,
      );
      final wildcard = _scenario(scenarios, 'scn_wildcard');
      expect(
        evaluateScenarioAuthoringClaimGuard(
          claimIndex: mapClaimIndex,
          proposedScenario: wildcard,
        ).blocked,
        isTrue,
      );

      final outcomeScenario = _scenario(scenarios, 'scn_outcome');
      final outcomeClaimIndex = _scenarioClaimIndex(
        scenario: outcomeScenario,
        node: _node(outcomeScenario, 'source'),
        source: NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_outcome',
            outcomeId: 'victory',
          ),
        ),
        validTarget: true,
      );
      expect(
        evaluateScenarioAuthoringClaimGuard(
          claimIndex: outcomeClaimIndex,
          proposedScenario: outcomeScenario.copyWith(id: 'other_consumer'),
        ).blocked,
        isTrue,
      );
    });
  });
}

LegacyScenarioSourceProjection _project(
  List<ScenarioAsset> scenarios,
  List<SceneAsset> scenes,
  String scenarioId,
  String nodeId,
) {
  final scenario = _scenario(scenarios, scenarioId);
  return projectLegacyScenarioSourceReadOnly(
    scenario: scenario,
    node: _node(scenario, nodeId),
    scenes: scenes,
    claimIndex: _emptyClaimIndex(),
    lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
  );
}

ScenarioAsset _scenario(List<ScenarioAsset> scenarios, String id) {
  return scenarios.singleWhere((scenario) => scenario.id == id);
}

ScenarioNode _node(ScenarioAsset scenario, String id) {
  return scenario.nodes.singleWhere((node) => node.id == id);
}

ValidatedLegacyClaimIndex _emptyClaimIndex() {
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    ),
  );
}

ValidatedLegacyClaimIndex _scenarioClaimIndex({
  required ScenarioAsset scenario,
  required ScenarioNode node,
  required NarrativeEventSourceRef source,
  required bool validTarget,
}) {
  final provenance = LegacySourceRef.scenarioSourceNode(scenario.id, node.id);
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: node.id,
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const targetId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [targetId],
    migrationReceiptId: 'receipt_c3',
  );
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: validTarget
          ? [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: targetId,
                  name: 'C3 target',
                  source: source,
                  conditions: const [],
                  sceneId: 'scene_entity',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: false,
              ),
            ]
          : const [],
      legacyClaims: [claim],
    ),
  );
}
````

</details>

### `packages/map_core/test/narrative_event_legacy_corpus_test.dart`

SHA-256: `af1867a180ccf030cccfb29b7dc786bb7d761be852ef64e31f4024db32a54b28` — 812 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _fixtureDirectory = 'test/fixtures/narrative_event_legacy_corpus';

void main() {
  group('NS-EVENT-V2 Phase C1 legacy corpus', () {
    late File fixtureFile;
    late List<int> fixtureBytes;
    late Map<String, Object?> fixture;
    late List<MapData> maps;
    late List<ScenarioAsset> scenarios;
    late List<SceneAsset> scenes;
    late List<GameState> gameStates;
    late List<WorldRuleDefinition> worldRules;
    late List<SceneConsequence> sceneConsequences;
    late List<ScriptAsset> scripts;

    setUpAll(() {
      fixtureFile = File('$_fixtureDirectory/corpus_v0.json');
      fixtureBytes = fixtureFile.readAsBytesSync();
      fixture =
          _object(decodeNarrativeEventJsonStrict(utf8.decode(fixtureBytes)));
      maps = _list(fixture, 'maps')
          .map((value) => MapData.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scenarios = _list(fixture, 'scenarios')
          .map((value) => ScenarioAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scenes = _list(fixture, 'scenes')
          .map((value) => SceneAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      gameStates = _list(fixture, 'gameStates')
          .map((value) => GameState.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      worldRules = _list(fixture, 'worldRules')
          .map((value) => WorldRuleDefinition.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      sceneConsequences = _list(fixture, 'sceneConsequences')
          .map((value) => SceneConsequence.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scripts = _list(fixture, 'scripts')
          .map((value) => ScriptAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
    });

    test('pins raw bytes and never rewrites a source fixture', () {
      final checksumLine =
          File('$_fixtureDirectory/corpus_v0.sha256').readAsStringSync().trim();
      final expected = checksumLine.split(RegExp(r'\s+')).first;
      expect(expected, isNot('PENDING'));
      expect(sha256.convert(fixtureBytes).toString(), expected);

      final before = List<int>.of(fixtureBytes);
      for (final map in maps) {
        final encoded = jsonEncode(map.toJson());
        final decoded = MapData.fromJson(
          _dynamicObject(jsonDecode(jsonEncode(map.toJson()))),
        );
        expect(
          canonicalizeNarrativeEventJsonText(jsonEncode(decoded.toJson())),
          canonicalizeNarrativeEventJsonText(encoded),
        );
      }
      for (final scenario in scenarios) {
        final encoded = jsonEncode(scenario.toJson());
        final decoded = ScenarioAsset.fromJson(
          _dynamicObject(jsonDecode(jsonEncode(scenario.toJson()))),
        );
        expect(
          canonicalizeNarrativeEventJsonText(jsonEncode(decoded.toJson())),
          canonicalizeNarrativeEventJsonText(encoded),
        );
      }
      expect(fixtureFile.readAsBytesSync(), before);
    });

    test('covers every required MapEvent shape without flattening pages', () {
      final events = [for (final map in maps) ...map.events];
      expect(
        events.map((event) => event.type).toSet(),
        containsAll(MapEventType.values),
      );

      final ordered = _event(maps, 'c1_map_a', 'evt_page_order');
      expect(ordered.pages.map((page) => page.pageNumber), [30, 20, 10]);
      expect(ordered.pages[0].isHidden, isTrue);
      expect(ordered.pages[1].isDisabled, isTrue);
      expect(ordered.pages[2].condition, isNull);
      expect(
        readEventBuilderContractFromMapEvent(ordered).diagnostics,
        isNotEmpty,
      );

      final mixed = _event(maps, 'c1_map_a', 'evt_effect_mixed');
      final mixedKinds = readEventBuilderContractFromMapEvent(mixed)
          .diagnostics
          .map((diagnostic) => diagnostic.kind)
          .toSet();
      expect(
        mixedKinds,
        containsAll({
          EventBuilderContractDiagnosticKind.metadataMalformed,
          EventBuilderContractDiagnosticKind.unsupportedLegacyScript,
          EventBuilderContractDiagnosticKind.unsupportedLegacyMessage,
        }),
      );

      final duplicateIds = <String, List<String>>{};
      for (final map in maps) {
        for (final event in map.events) {
          duplicateIds.putIfAbsent(event.id, () => []).add(map.id);
        }
      }
      expect(duplicateIds['evt_shared'], ['c1_map_a', 'c1_map_b']);

      final samePositions = maps
          .singleWhere((map) => map.id == 'c1_map_a')
          .events
          .where((event) => event.position.x == 7 && event.position.y == 7)
          .map((event) => event.id)
          .toSet();
      expect(
        samePositions,
        {'evt_duplicate_position_a', 'evt_duplicate_position_b'},
      );
    });

    test('keeps invalid position and unknown JSON probes loss-aware', () {
      final mapA = maps.singleWhere((map) => map.id == 'c1_map_a');
      final missingLayer = _event(maps, mapA.id, 'evt_missing_layer');
      final outOfBounds = _event(maps, mapA.id, 'evt_out_of_bounds');
      expect(
        mapA.layers.any((layer) => layer.id == missingLayer.position.layerId),
        isFalse,
      );
      expect(outOfBounds.position.x >= mapA.size.width, isTrue);
      expect(outOfBounds.position.y >= mapA.size.height, isTrue);

      final probes = {
        for (final value in _list(fixture, 'decodeProbes'))
          _string(_object(value), 'id'): _object(value),
      };
      expect(
        () => MapEventDefinition.fromJson(
          _dynamicObject(probes['event_position_without_layer']!['json']),
        ),
        throwsA(anything),
      );
      expect(
        probes['unknown_legacy_payload']!['expected'],
        'preservedOrBlocked',
      );
      final unknownProbe = probes['unknown_legacy_payload']!;
      final unknownJson = _object(unknownProbe['json']);
      final canonicalBefore = canonicalizeNarrativeEventJson(unknownJson);
      final canonicalAfter = canonicalizeNarrativeEventJson(
        decodeNarrativeEventJsonStrict(jsonEncode(unknownJson)),
      );
      expect(canonicalAfter, canonicalBefore);
      final rawHash = narrativeEventCanonicalSha256(unknownJson);
      if (unknownProbe['expectedCanonicalSha256'] == 'PENDING') {
        fail('Replace unknown raw hash with $rawHash');
      }
      expect(rawHash, unknownProbe['expectedCanonicalSha256']);
      expect(
        unknownJson['futureBehavior'],
        isNotNull,
      );
      expect(
        () => MapEventDefinition.fromJson(_dynamicObject(unknownJson)),
        throwsA(anything),
      );
    });

    test('covers four Scenario sources and preserves complex graphs', () {
      final sourceKinds = <String>{};
      for (final scenario in scenarios) {
        for (final node in scenario.nodes) {
          final kind = node.payload.actionKind;
          if (kind != null && kind.startsWith('source')) sourceKinds.add(kind);
        }
      }
      expect(
        sourceKinds,
        {
          'sourceMapEnter',
          'sourceTriggerEnter',
          'sourceEntityInteract',
          'sourceOutcome',
        },
      );

      final complex =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_complex');
      expect(complex.activationCondition, isNotNull);
      expect(
        complex.edges.map((edge) => edge.kind).toSet(),
        containsAll(
            {ScenarioEdgeKind.trueBranch, ScenarioEdgeKind.falseBranch}),
      );
      expect(
        complex.nodes.where((node) => node.type == ScenarioNodeType.action),
        hasLength(2),
      );

      final wildcard =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_wildcard');
      expect(wildcard.nodes.first.binding.mapId, isEmpty);
      final malformed =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_malformed');
      expect(malformed.nodes.first.binding.entityId, isNull);
    });

    test('represents every migration classification and corpus feature', () {
      final cases =
          _list(fixture, 'cases').map(_object).toList(growable: false);
      final classifications = {
        for (final value in cases) _string(value, 'classification'),
      };
      expect(
        classifications,
        {'AUTO_SAFE', 'ASSISTED', 'BLOCKED', 'UNSUPPORTED', 'LEGACY_ONLY'},
      );
      expect(
        cases.map((value) => _string(value, 'id')).toSet(),
        hasLength(cases.length),
      );
      for (final value in cases) {
        for (final field in const [
          'decodeBehavior',
          'runtimeBehavior',
          'sourceOfTruth',
          'conversionPossibility',
          'lossRisk',
        ]) {
          expect(
            _string(value, field).trim(),
            isNotEmpty,
            reason: '${value['id']} must characterize $field.',
          );
        }
        expect(value['outgoingReferences'], isA<List>());
        expect(value['incomingReferences'], isA<List>());
      }
      final pageOrders = _object(fixture['pageOrders']);
      expect(pageOrders.keys.toSet(), {
        for (final value in cases) _string(value, 'subject'),
      });
      expect(
        {
          for (final map in maps)
            for (final event in map.events) 'mapEvent:${map.id}:${event.id}',
        },
        {
          for (final value in cases)
            if (_string(value, 'subject').startsWith('mapEvent:'))
              _string(value, 'subject'),
        },
      );
      for (final value in cases) {
        final subject = _string(value, 'subject');
        final expectedOrder = List<int>.from(pageOrders[subject]! as List);
        if (!subject.startsWith('mapEvent:')) {
          expect(expectedOrder, isEmpty);
          continue;
        }
        final parts = subject.split(':');
        expect(
          _event(maps, parts[1], parts[2]).pages.map((page) => page.pageNumber),
          expectedOrder,
        );
      }

      final autoSafeCases = cases.where(
        (value) => _string(value, 'classification') == 'AUTO_SAFE',
      );
      expect(autoSafeCases, isNotEmpty);
      for (final value in autoSafeCases) {
        final subject = _string(value, 'subject').split(':');
        expect(subject.first, 'scenarioSourceNode');
        final scenario = scenarios.singleWhere(
          (candidate) => candidate.id == subject[1],
        );
        final sourceNode = scenario.nodes.singleWhere(
          (node) => node.id == subject[2],
        );
        final sceneId = sourceNode.metadata['eventV2.sceneId'];
        expect(sceneId, isNotNull);
        final scene =
            scenes.singleWhere((candidate) => candidate.id == sceneId);
        final planResult = buildSceneRuntimePlan(scene);
        expect(
          planResult.canBuild,
          isTrue,
          reason: '$sceneId must be executable before AUTO_SAFE is allowed.',
        );
        expect(_scenarioObservableTrace(scenario, sourceNode.id),
            _sceneObservableTrace(scene));
      }

      final features = <String>{
        for (final value in cases)
          for (final feature in _list(value, 'features')) feature as String,
      };
      expect(
        features,
        containsAll({
          'actor',
          'object',
          'triggerZone',
          'effect',
          'sceneTarget',
          'script',
          'message',
          'scriptAndMessage',
          'multiplePages',
          'firstValid',
          'fallbackPage',
          'disabledPage',
          'hiddenPage',
          'unknownLayer',
          'outOfBounds',
          'multipleEventsSamePosition',
          'nearEntity',
          'multipleEntitiesSameFootprint',
          'duplicateIdAcrossMaps',
          'alreadyConsumed',
          'eventReferencedByCondition',
          'worldRuleReference',
          'sceneConsequenceReference',
          'mapEnter',
          'triggerEnter',
          'entityInteract',
          'outcomeReceived',
          'multipleSourceNodes',
          'branches',
          'multipleActions',
          'malformedBinding',
          'emptyMapIdWildcard',
          'unqualifiedOutcome',
          'claimedSource',
        }),
      );
    });

    test('keeps the qualified reference inventory deterministic', () {
      final expected =
          _list(fixture, 'references').map(_object).toList(growable: false);
      final discovered = _discoverReferences(
        maps: maps,
        scenarios: scenarios,
        scenes: scenes,
        gameStates: gameStates,
        worldRules: worldRules,
        sceneConsequences: sceneConsequences,
        scripts: scripts,
      );
      expect(
        discovered.map((value) => value.kind).toSet(),
        containsAll({
          'GameState.consumedEventIds',
          'ScriptCondition',
          'WorldRuleDefinition.source',
          'WorldRuleDefinition.target',
          'EventSceneLinkDiagnostic',
          'SceneConsequence',
          'ScenarioNodeBinding',
          'ScriptCommand',
          'metadata',
        }),
      );

      final expectedKeys = expected.map(_referenceKey).toList()..sort();
      final discoveredKeys = discovered.map((value) => value.key).toList()
        ..sort();
      expect(discoveredKeys, expectedKeys);
      final reversedKeys =
          discovered.reversed.map((value) => value.key).toList()..sort();
      expect(reversedKeys, discoveredKeys);

      final ambiguous = discovered.where(
        (value) => value.rawId == 'evt_shared' && value.candidates.length > 1,
      );
      expect(ambiguous, isNotEmpty);
      expect(
        ambiguous.every((value) => value.selectedCandidate == null),
        isTrue,
      );
    });

    test('pins source fingerprints and proves complete claim cohorts', () {
      final mapEvent = _event(maps, 'c1_map_a', 'evt_actor_scene');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final discoveredBySource = _discoverScenarioSourceProvenances(scenarios);
      final discoveredProvenances = [...discoveredBySource[source]!]
        ..sort(compareLegacySourceRefs);
      final members = [
        for (final provenance in discoveredProvenances)
          provenance.when(
            mapEvent: (_, __) => throw StateError(
              'Scenario cohort unexpectedly contains a MapEvent.',
            ),
            scenarioSourceNode: (scenarioId, nodeId) {
              final scenario = scenarios.singleWhere(
                (candidate) => candidate.id == scenarioId,
              );
              return LegacySourceClaimMember(
                provenance: provenance,
                sourceFingerprint: computeScenarioSourceFingerprint(
                  scenarioId: scenarioId,
                  nodeId: nodeId,
                  scenario: scenario,
                ),
              );
            },
          ),
      ];
      final cohortId = computeLegacySourceCohortId(
        source,
        members.map((member) => member.provenance),
      );
      final actual = <String, String>{
        'mapEventFingerprint': computeMapEventSourceFingerprint(
          mapId: 'c1_map_a',
          event: mapEvent,
        ),
        'scenarioFingerprintA': members[0].sourceFingerprint,
        'scenarioFingerprintB': members[1].sourceFingerprint,
        'cohortId': cohortId,
        'cohortFingerprint':
            computeLegacySourceCohortFingerprint(cohortId, members),
      };
      final expected = _object(fixture['goldens']);
      if (expected.values.contains('PENDING')) {
        fail('Replace C1 goldens with ${jsonEncode(actual)}');
      }
      expect(actual, expected);

      final declaredMembers = _list(
        _list(fixture, 'cohorts').map(_object).single,
        'members',
      ).map((value) => LegacySourceRef.fromJson(value)).toSet();
      final discovered = members.map((member) => member.provenance).toSet();
      expect(discovered, declaredMembers);
      expect(discoveredProvenances, hasLength(2));
      final provenanceA = LegacySourceRef.scenarioSourceNode(
        'scn_entity_a',
        'source',
      );
      final provenanceB = LegacySourceRef.scenarioSourceNode(
        'scn_entity_b',
        'source',
      );
      expect(
        declaredMembers.difference({provenanceA}),
        {provenanceB},
      );

      final claim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: members,
        cohortFingerprint: actual['cohortFingerprint']!,
        targetEventIds: const ['evt_018f1234-5678-7abc-8def-0123456789ab'],
        migrationReceiptId: 'receipt_c1',
      );
      expect(
          claim.members.map((member) => member.provenance).toSet(), discovered);
    });
  });
}

MapEventDefinition _event(
  List<MapData> maps,
  String mapId,
  String eventId,
) {
  return maps
      .singleWhere((map) => map.id == mapId)
      .events
      .singleWhere((event) => event.id == eventId);
}

String _referenceKey(Map<String, Object?> reference) {
  return '${_string(reference, 'kind')}|${_string(reference, 'path')}|'
      '${_string(reference, 'rawId')}|${reference['mapId'] ?? ''}|'
      '${_list(reference, 'candidates').join(',')}';
}

List<String> _scenarioObservableTrace(
  ScenarioAsset scenario,
  String sourceNodeId,
) {
  final trace = <String>[];
  var currentId = sourceNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node =
        scenario.nodes.singleWhere((candidate) => candidate.id == currentId);
    if (node.type == ScenarioNodeType.dialogue) {
      trace.add('dialogue:${node.binding.dialogueId}');
    } else if (node.type == ScenarioNodeType.end) {
      trace.add('end');
      return trace;
    } else if (node.id != sourceNodeId) {
      throw StateError('Non-equivalent Scenario node ${node.type.name}.');
    }
    final outgoing =
        scenario.edges.where((edge) => edge.fromNodeId == currentId);
    currentId = outgoing.single.toNodeId;
  }
  throw StateError('Scenario trace contains a cycle.');
}

List<String> _sceneObservableTrace(SceneAsset scene) {
  final trace = <String>[];
  var currentId = scene.graph.startNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scene.graph.nodes.singleWhere(
      (candidate) => candidate.id == currentId,
    );
    if (node.kind == SceneNodeKind.yarnDialogue) {
      final payload = node.payload as SceneYarnDialoguePayload;
      trace.add('dialogue:${payload.dialogueId}');
    } else if (node.kind == SceneNodeKind.end) {
      trace.add('end');
      return trace;
    } else if (node.kind != SceneNodeKind.start) {
      throw StateError('Non-equivalent Scene node ${node.kind.name}.');
    }
    final outgoing = scene.graph.edges.where(
      (edge) => edge.fromNodeId == currentId,
    );
    currentId = outgoing.single.toNodeId;
  }
  throw StateError('Scene trace contains a cycle.');
}

Map<NarrativeEventSourceRef, List<LegacySourceRef>>
    _discoverScenarioSourceProvenances(List<ScenarioAsset> scenarios) {
  final result = <NarrativeEventSourceRef, List<LegacySourceRef>>{};
  for (final scenario in scenarios) {
    for (final node in scenario.nodes) {
      final binding = node.binding;
      final source = switch (node.payload.actionKind) {
        'sourceMapEnter' when (binding.mapId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.mapEnter(binding.mapId!),
        'sourceTriggerEnter'
            when (binding.mapId ?? '').isNotEmpty &&
                (binding.triggerId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.triggerEnter(
            binding.mapId!,
            binding.triggerId!,
          ),
        'sourceEntityInteract'
            when (binding.mapId ?? '').isNotEmpty &&
                (binding.entityId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.entityInteract(
            binding.mapId!,
            binding.entityId!,
          ),
        'sourceOutcome' when (binding.outcomeId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.legacyScenario,
              producerId: scenario.id,
              outcomeId: binding.outcomeId!,
            ),
          ),
        _ => null,
      };
      if (source == null) continue;
      result.putIfAbsent(source, () => []).add(
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id),
          );
    }
  }
  return result;
}

List<_DiscoveredReference> _discoverReferences({
  required List<MapData> maps,
  required List<ScenarioAsset> scenarios,
  required List<SceneAsset> scenes,
  required List<GameState> gameStates,
  required List<WorldRuleDefinition> worldRules,
  required List<SceneConsequence> sceneConsequences,
  required List<ScriptAsset> scripts,
}) {
  final byBareId = <String, List<String>>{};
  for (final map in maps) {
    for (final event in map.events) {
      byBareId.putIfAbsent(event.id, () => []).add('${map.id}:${event.id}');
    }
  }
  for (final values in byBareId.values) {
    values.sort();
  }

  List<String> candidates(String eventId, {String? mapId}) {
    if (mapId != null) {
      final qualified = '$mapId:$eventId';
      return byBareId[eventId]?.contains(qualified) == true
          ? [qualified]
          : const [];
    }
    return List.unmodifiable(byBareId[eventId] ?? const []);
  }

  final result = <_DiscoveredReference>[];
  void add(
    String kind,
    String path,
    String eventId, {
    String? mapId,
  }) {
    result.add(
      _DiscoveredReference(
        kind: kind,
        path: path,
        rawId: eventId,
        mapId: mapId,
        candidates: candidates(eventId, mapId: mapId),
        selectedCandidate: null,
      ),
    );
  }

  for (final state in gameStates) {
    final eventIds = state.consumedEventIds.toList()..sort();
    for (var index = 0; index < eventIds.length; index++) {
      add(
        'GameState.consumedEventIds',
        'gameStates.${state.saveId}.consumedEventIds[$index]',
        eventIds[index],
      );
    }
  }
  for (final map in maps) {
    for (final event in map.events) {
      for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
        final page = event.pages[pageIndex];
        _discoverConditionReferences(
          page.condition,
          path: 'maps.${map.id}.events.${event.id}.pages[$pageIndex].condition',
          add: (eventId, path) => add('ScriptCondition', path, eventId),
        );
        for (final entry in page.metadata.entries) {
          if (entry.key.toLowerCase().contains('eventid') &&
              byBareId.containsKey(entry.value)) {
            add(
              'metadata',
              'maps.${map.id}.events.${event.id}.pages[$pageIndex].metadata.${entry.key}',
              entry.value,
            );
          }
        }
      }
    }
  }
  for (final rule in worldRules) {
    if (rule.source.kind == WorldRuleSourceKind.consumedEvent) {
      add(
        'WorldRuleDefinition.source',
        'worldRules.${rule.id}.source',
        rule.source.sourceId,
      );
    }
    if (rule.target.kind == WorldRuleTargetKind.mapEvent &&
        rule.target.eventId != null) {
      add(
        'WorldRuleDefinition.target',
        'worldRules.${rule.id}.target',
        rule.target.eventId!,
        mapId: rule.target.mapId,
      );
    }
  }
  final diagnosticProject = ProjectManifest(
    name: 'C1 diagnostic inventory',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
  );
  final linkDiagnostics = diagnoseEventSceneLinks(
    project: diagnosticProject,
    maps: maps,
  ).diagnostics;
  for (var index = 0; index < linkDiagnostics.length; index++) {
    final diagnostic = linkDiagnostics[index];
    add(
      'EventSceneLinkDiagnostic',
      'diagnostics.eventSceneLinks[$index]',
      diagnostic.eventId,
      mapId: diagnostic.mapId,
    );
  }
  for (var index = 0; index < sceneConsequences.length; index++) {
    final consequence = sceneConsequences[index];
    if (consequence is SceneMarkEventConsumedConsequence) {
      add(
        'SceneConsequence',
        'sceneConsequences[$index]',
        consequence.eventId,
        mapId: consequence.mapId,
      );
    }
  }
  for (final scenario in scenarios) {
    for (final node in scenario.nodes) {
      final eventId = node.binding.eventId;
      if (eventId != null && eventId.isNotEmpty) {
        add(
          'ScenarioNodeBinding',
          'scenarios.${scenario.id}.nodes.${node.id}.binding',
          eventId,
          mapId: node.binding.mapId,
        );
      }
    }
  }
  for (final script in scripts) {
    for (final node in script.nodes) {
      for (var index = 0; index < node.commands.length; index++) {
        final command = node.commands[index];
        final eventId = command.params['eventId'];
        if (command.type == ScriptCommandType.markEventConsumed &&
            eventId != null &&
            eventId.isNotEmpty) {
          add(
            'ScriptCommand',
            'scripts.${script.id}.nodes.${node.id}.commands[$index]',
            eventId,
          );
        }
      }
    }
    for (final entry in script.metadata.entries) {
      if (entry.key.toLowerCase().contains('eventid') &&
          byBareId.containsKey(entry.value)) {
        add(
          'metadata',
          'scripts.${script.id}.metadata.${entry.key}',
          entry.value,
        );
      }
    }
  }
  return List.unmodifiable(result);
}

void _discoverConditionReferences(
  ScriptCondition? condition, {
  required String path,
  required void Function(String eventId, String path) add,
}) {
  if (condition == null) return;
  if (condition.type == ScriptConditionType.eventIsConsumed) {
    final eventId = condition.params[ScriptConditionParams.eventId];
    if (eventId != null && eventId.isNotEmpty) add(eventId, path);
  }
  for (var index = 0; index < condition.children.length; index++) {
    _discoverConditionReferences(
      condition.children[index],
      path: '$path.children[$index]',
      add: add,
    );
  }
}

final class _DiscoveredReference {
  const _DiscoveredReference({
    required this.kind,
    required this.path,
    required this.rawId,
    required this.mapId,
    required this.candidates,
    required this.selectedCandidate,
  });

  final String kind;
  final String path;
  final String rawId;
  final String? mapId;
  final List<String> candidates;
  final String? selectedCandidate;

  String get key => '$kind|$path|$rawId|${mapId ?? ''}|${candidates.join(',')}';
}

Map<String, Object?> _object(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

Map<String, dynamic> _dynamicObject(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Object?> _list(Map<String, Object?> object, String key) {
  return List<Object?>.from(object[key]! as List);
}

String _string(Map<String, Object?> object, String key) {
  return object[key]! as String;
}
````

</details>

### `packages/map_core/test/narrative_event_migration_planner_test.dart`

SHA-256: `7029e316cba2edc3af8a429b300d702ca48c191702e896d9e4a95e125fe84a69` — 3123 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 migration planner', () {
    test('returns an empty plan without consuming IDs or clock values', () {
      final ids = _InjectedIds.forbidden();
      var clockCalls = 0;
      final plan = NarrativeEventMigrationPlanner(
        ids: ids,
        clock: () {
          clockCalls++;
          throw StateError('clock must stay unused');
        },
      ).plan(_input());

      expect(plan.status, NarrativeEventMigrationPlanStatus.empty);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(ids.calls, 0);
      expect(clockCalls, 0);
    });

    test('blocks an orphan registry claim instead of returning empty', () {
      final provenance = LegacySourceRef.mapEvent('map_orphan', 'legacy_a');
      final source = NarrativeEventSourceRef.mapEnter('map_orphan');
      const eventId = 'evt_018f0000-0000-7000-8000-000000000001';
      const receiptId = 'evmr_018f0000-0000-7000-8000-000000000002';
      final member = LegacySourceClaimMember(
        provenance: provenance,
        sourceFingerprint: _hash('a'),
      );
      final cohortId = computeLegacySourceCohortId(source, [provenance]);
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: 'Orphan target',
              source: source,
              conditions: const [],
              sceneId: 'scene_a',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: false,
          ),
        ],
        legacyClaims: [
          LegacySourceClaim(
            cohortId: cohortId,
            source: source,
            members: [member],
            cohortFingerprint: computeLegacySourceCohortFingerprint(
              cohortId,
              [member],
            ),
            targetEventIds: const [eventId],
            migrationReceiptId: receiptId,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(project: _project(eventRegistry: registry)),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim),
      );
      expect(ids.calls, 0);
    });

    test('blocks an orphan receipt instead of returning empty', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final prepared = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(existingReceipt: prepared.receiptProposal),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('plans a simple AUTO_SAFE project with complete claim and receipt',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds(
        eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
      );
      final input = _input(mapProjections: [projection]);
      final projectBefore = jsonEncode(input.project.toJson());
      final projectionBefore = jsonEncode(projection.toJson());

      final plan = _planner(ids).plan(input);

      expect(plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(plan.recordsProposed, hasLength(1));
      expect(plan.draftsProposed, isEmpty);
      expect(plan.claimsProposed, hasLength(1));
      expect(plan.cohorts.single.complete, isTrue);
      expect(plan.cohorts.single.claimStatus,
          NarrativeEventMigrationCohortClaimStatus.proposed);
      expect(plan.claimsProposed.single.members, hasLength(1));
      expect(plan.claimsProposed.single.targetEventIds,
          [plan.recordsProposed.single.id]);
      expect(plan.mappings.pageMappings.single.status,
          NarrativeEventPageMappingStatus.mapped);
      expect(plan.receiptProposal, isNotNull);
      expect(plan.receiptProposal!.isProposal, isTrue);
      expect(plan.receiptProposal!.targetClaims, plan.claimsProposed);
      expect(plan.receiptProposal!.snapshot.mapHashes, contains('map_a'));
      expect(plan.canApply, isTrue);
      expect(plan.pointOfNoReturn.reached, isFalse);
      expect(jsonEncode(input.project.toJson()), projectBefore);
      expect(jsonEncode(projection.toJson()), projectionBefore);
    });

    test('requires every MapEvent target Scene to exist and be buildable', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final maps = _mapsForProjections([projection], const []);
      final validScene = _sceneForMapTarget('scene_a');
      final projects = [
        _project(mapIds: const ['map_a']),
        _project(
          mapIds: const ['map_a'],
          scenes: [validScene, validScene],
        ).copyWith(scenes: [validScene, validScene]),
        _project(
          mapIds: const ['map_a'],
          scenes: [_unbuildableScene('scene_a')],
        ),
      ];

      for (final project in projects) {
        final ids = _InjectedIds.forbidden();
        final plan = _planner(ids).plan(
          _input(
            project: project,
            maps: maps,
            mapProjections: [projection],
            currentSnapshot: _snapshot(
              [projection],
              project: project,
              maps: maps,
            ),
          ),
        );

        expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.path),
          contains('scenes.scene_a'),
        );
        expect(ids.calls, 0);
      }
    });

    test('requires an explicit MapEvent lifecycle before proposing a claim',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds.standardTwo();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices.empty(),
        ),
      );

      expect(
        plan.status,
        NarrativeEventMigrationPlanStatus.assistanceRequired,
      );
      expect(plan.draftsProposed, hasLength(1));
      expect(plan.draftsProposed.single.draftOrNull!.reusePolicy, isNull);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(plan.canApply, isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.lifecycleChoiceRequired,
        ),
      );
    });

    test('does not let a MapEvent lifecycle choice rename the source event',
        () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'a',
      );
      final originalChoice = _defaultChoices([projection]).sourceChoices.single;
      final originalTarget = originalChoice.targets.single;
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [
              NarrativeEventMigrationSourceChoice(
                provenance: projection.provenance,
                source: originalChoice.source,
                targets: [
                  NarrativeEventMigrationTargetProposal(
                    name: 'Silent rename',
                    legacyPageIndex: originalTarget.legacyPageIndex,
                    conditions: originalTarget.conditions,
                    sceneId: originalTarget.sceneId,
                    reusePolicy: originalTarget.reusePolicy,
                    priority: originalTarget.priority,
                    order: originalTarget.order,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
        ),
      );
      expect(ids.calls, 0);
    });

    test('keeps classification buckets and proposes only an assisted draft',
        () {
      final projections = [
        _projection(
          mapId: 'map_auto',
          legacyEventId: 'auto',
          source:
              NarrativeEventSourceRef.entityInteract('map_auto', 'npc_auto'),
          sceneId: 'scene_auto',
          fingerprintCharacter: 'a',
        ),
        _projection(
          mapId: 'map_assisted',
          legacyEventId: 'assisted',
          source: NarrativeEventSourceRef.entityInteract(
            'map_assisted',
            'npc_assisted',
          ),
          sceneId: 'scene_assisted',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: 'b',
        ),
        _projection(
          mapId: 'map_blocked',
          legacyEventId: 'blocked',
          source: NarrativeEventSourceRef.entityInteract(
            'map_blocked',
            'npc_blocked',
          ),
          sceneId: 'scene_blocked',
          classification: LegacyMigrationClassification.blocked,
          fingerprintCharacter: 'c',
        ),
        _projection(
          mapId: 'map_unsupported',
          legacyEventId: 'unsupported',
          source: NarrativeEventSourceRef.entityInteract(
            'map_unsupported',
            'npc_unsupported',
          ),
          sceneId: 'scene_unsupported',
          classification: LegacyMigrationClassification.unsupported,
          fingerprintCharacter: 'd',
        ),
        _projection(
          mapId: 'map_legacy_only',
          legacyEventId: 'legacy_only',
          source: NarrativeEventSourceRef.triggerEnter(
            'map_legacy_only',
            'trigger_legacy_only',
          ),
          sceneId: 'scene_legacy_only',
          classification: LegacyMigrationClassification.legacyOnly,
          fingerprintCharacter: '8',
        ),
      ];
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(_input(mapProjections: projections));

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.autoSafeItems, hasLength(1));
      expect(plan.assistedItems, hasLength(1));
      expect(plan.blockedItems, hasLength(1));
      expect(plan.unsupportedItems, hasLength(1));
      expect(plan.legacyOnlyItems, hasLength(1));
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(plan.canApply, isFalse);
      expect(ids.calls, 0);
    });

    test('keeps every multi-page mapping and refuses a partial claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'pages',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.blocked,
        fingerprintCharacter: 'e',
        pages: [
          LegacyMapEventPageProjection(
            pageIndex: 0,
            pageNumber: 30,
            condition: null,
            script: null,
            spriteId: null,
            message: null,
            sceneId: 'scene_a',
            isHidden: false,
            isDisabled: false,
            metadata: {},
          ),
          LegacyMapEventPageProjection(
            pageIndex: 1,
            pageNumber: 20,
            condition: null,
            script: null,
            spriteId: null,
            message: null,
            sceneId: 'scene_b',
            isHidden: true,
            isDisabled: false,
            metadata: {'future': 'kept'},
          ),
        ],
      );

      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(mapProjections: [projection]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.mappings.pageMappings, hasLength(2));
      expect(
        plan.mappings.pageMappings.map((mapping) => mapping.pageNumber),
        [30, 20],
      );
      expect(
        plan.mappings.pageMappings.every(
          (mapping) =>
              mapping.status == NarrativeEventPageMappingStatus.preservedLegacy,
        ),
        isTrue,
      );
      expect(plan.claimsProposed, isEmpty);
    });

    test('applies explicit ASSISTED source and target choices', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_confirmed');
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_hint'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'f',
      );
      final choice = NarrativeEventMigrationSourceChoice(
        provenance: projection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Confirmed event',
            legacyPageIndex: 0,
            conditions: [NarrativeEventCondition.fact('fact_a', true)],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 2,
            order: 3,
          ),
        ],
      );
      final ids = _InjectedIds(
        eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
      );

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(plan.assistedItems.single.choiceApplied, isTrue);
      expect(plan.draftsProposed, isEmpty);
      expect(plan.claimsProposed.single.source, source);
      expect(
        plan.recordsProposed.single.definitionOrNull!.conditions,
        [NarrativeEventCondition.fact('fact_a', true)],
      );

      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: plan.recordsProposed,
        legacyClaims: plan.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_hint'),
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'f',
        existingClaim: plan.claimsProposed.single,
      );
      final forbiddenIds = _InjectedIds.forbidden();
      final replay = _planner(forbiddenIds).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
          existingReceipt: plan.receiptProposal,
        ),
      );

      expect(replay.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(forbiddenIds.calls, 0);
    });

    test('plans an AUTO_SAFE Scenario source with its proven lifecycle', () {
      final source = NarrativeEventSourceRef.mapEnter('map_a');
      final provenance =
          LegacySourceRef.scenarioSourceNode('scenario_a', 'source_a');
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: source,
        fingerprintCharacter: 'a',
      );
      final ids = _InjectedIds.standardTwo();

      final plan = _planner(ids).plan(
        _input(scenarioProjections: [projection]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.ready);
      expect(plan.recordsProposed.single.definitionOrNull!.source, source);
      expect(
        plan.recordsProposed.single.definitionOrNull!.reusePolicy,
        NarrativeEventReusePolicy.oneShot,
      );
      expect(plan.claimsProposed.single.members.single.provenance, provenance);
    });

    test('revalidates the current Scene proof for AUTO_SAFE Scenario sources',
        () {
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: 'a',
      );
      final scenarios = _scenariosForProjections([projection]);
      final maps = _mapsForProjections(const [], [projection]);
      final invalidProjects = [
        _project(
          mapIds: const ['map_a'],
          scenarios: scenarios,
        ),
        _project(
          mapIds: const ['map_a'],
          scenarios: scenarios,
          scenes: [
            _sceneForScenario(
              'scenario_a',
              dialogueId: 'changed_dialogue',
            ),
          ],
        ),
      ];

      for (final project in invalidProjects) {
        final ids = _InjectedIds.forbidden();
        final plan = _planner(ids).plan(
          _input(
            project: project,
            maps: maps,
            scenarioProjections: [projection],
            currentSnapshot: _snapshot(
              const [],
              scenarioProjections: [projection],
              project: project,
              maps: maps,
            ),
          ),
        );

        expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.path),
          contains('scenes.scene_scenario_a'),
        );
        expect(ids.calls, 0);
      }
    });

    test('rejects duplicate Scenario IDs before source inventory matching', () {
      final projection = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: 'a',
      );
      final scenario = _scenariosForProjections([projection]).single;
      final maps = _mapsForProjections(const [], [projection]);
      final project = _project(
        mapIds: const ['map_a'],
        scenarios: [scenario, scenario],
        scenes: _scenesForProjections([projection]),
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          scenarioProjections: [projection],
          currentSnapshot: _snapshot(
            const [],
            scenarioProjections: [projection],
            project: project,
            maps: maps,
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('project.scenarios.scenario_a'),
      );
      expect(ids.calls, 0);
    });

    test('bounds ASSISTED Scenario choices to the characterized source', () {
      final qualifiedSource = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer_scene',
          outcomeId: 'victory',
        ),
      );
      final projection = _scenarioProjection(
        scenarioId: 'scenario_outcome',
        nodeId: 'source',
        source: qualifiedSource,
        fingerprintCharacter: 'b',
      );
      expect(
        projection.classification,
        LegacyMigrationClassification.assisted,
      );
      expect(projection.source, isNull);
      final validTarget = NarrativeEventMigrationTargetProposal(
        name: 'Scenario scenario_outcome',
        conditions: const [],
        sceneId: 'scene_scenario_outcome',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      );
      final validChoice = NarrativeEventMigrationSourceChoice(
        provenance: projection.provenance,
        source: qualifiedSource,
        targets: [validTarget],
      );

      final valid = _planner(_InjectedIds.standardTwo()).plan(
        _input(
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [validChoice],
          ),
        ),
      );
      expect(valid.status, NarrativeEventMigrationPlanStatus.ready);

      final invalidChoices = [
        NarrativeEventMigrationSourceChoice(
          provenance: projection.provenance,
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'producer_scene',
              outcomeId: 'different',
            ),
          ),
          targets: [validTarget],
        ),
        NarrativeEventMigrationSourceChoice(
          provenance: projection.provenance,
          source: qualifiedSource,
          targets: [
            NarrativeEventMigrationTargetProposal(
              name: validTarget.name,
              conditions: validTarget.conditions,
              sceneId: 'missing_scene',
              reusePolicy: validTarget.reusePolicy,
              priority: validTarget.priority,
              order: validTarget.order,
            ),
          ],
        ),
      ];
      for (final choice in invalidChoices) {
        final ids = _InjectedIds.forbidden();
        final plan = _planner(ids).plan(
          _input(
            scenarioProjections: [projection],
            choices: NarrativeEventMigrationChoices(
              sourceChoices: [choice],
            ),
          ),
        );
        expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.path),
          contains('scenarios.scenario_outcome.nodes.source.choice'),
        );
        expect(ids.calls, 0);
      }
    });

    test('is idempotent with an exact existing registry and receipt', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(
        _InjectedIds(
          eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
          receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
        ),
      ).plan(_input(mapProjections: [projection]));
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final secondInput = _input(
        project: project,
        mapProjections: [projection],
        currentSnapshot: _snapshot(
          [projection],
          project: project,
        ),
        existingReceipt: first.receiptProposal,
      );
      final forbiddenIds = _InjectedIds.forbidden();

      final second = _planner(forbiddenIds).plan(secondInput);

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(second.cohorts.single.claimStatus,
          NarrativeEventMigrationCohortClaimStatus.existing);
      expect(second.receiptProposal, first.receiptProposal);
      expect(forbiddenIds.calls, 0);
    });

    test('restores distinct per-provenance targets from an exact receipt', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_shared');
      final firstProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '1',
      );
      final secondProjection = _projection(
        mapId: 'map_b',
        legacyEventId: 'legacy_b',
        source: source,
        sceneId: 'scene_b',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '2',
      );
      final choices = NarrativeEventMigrationChoices(
        sourceChoices: [
          NarrativeEventMigrationSourceChoice(
            provenance: firstProjection.provenance,
            source: source,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'First target',
                legacyPageIndex: 0,
                conditions: const [],
                sceneId: 'scene_a',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
          NarrativeEventMigrationSourceChoice(
            provenance: secondProjection.provenance,
            source: source,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'Second target',
                legacyPageIndex: 0,
                conditions: const [],
                sceneId: 'scene_b',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
        ],
      );
      final initialInput = _input(
        mapProjections: [firstProjection, secondProjection],
        choices: choices,
      );
      final first = _planner(
        _InjectedIds(
          eventIds: const [
            'evt_018f0000-0000-7000-8000-000000000001',
            'evt_018f0000-0000-7000-8000-000000000002',
          ],
          receiptIds: const [
            'evmr_018f0000-0000-7000-8000-000000000003',
          ],
        ),
      ).plan(initialInput);
      expect(first.status, NarrativeEventMigrationPlanStatus.ready);
      expect(first.recordsProposed, hasLength(2));
      final claim = first.claimsProposed.single;
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: [claim],
      );
      final project = initialInput.project.copyWith(eventRegistry: registry);
      final claimedProjections = [
        _projection(
          mapId: 'map_a',
          legacyEventId: 'legacy_a',
          source: source,
          sceneId: 'scene_a',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: '1',
          existingClaim: claim,
        ),
        _projection(
          mapId: 'map_b',
          legacyEventId: 'legacy_b',
          source: source,
          sceneId: 'scene_b',
          classification: LegacyMigrationClassification.assisted,
          confirmed: false,
          fingerprintCharacter: '2',
          existingClaim: claim,
        ),
      ];
      final ids = _InjectedIds.forbidden();

      final replay = _planner(ids).plan(
        _input(
          project: project,
          maps: initialInput.maps,
          mapProjections: claimedProjections,
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: _snapshot(
            claimedProjections,
            project: project,
            maps: initialInput.maps,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(replay.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(
        replay.mappings.idMappings.map((mapping) => mapping.targetEventIds),
        first.mappings.idMappings.map((mapping) => mapping.targetEventIds),
      );
      expect(ids.calls, 0);
    });

    test('blocks incremental cohorts until receipt history is modelled', () {
      final existingProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [existingProjection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final newProjection = _projection(
        mapId: 'map_b',
        legacyEventId: 'legacy_b',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '2',
      );
      final projections = [claimedProjection, newProjection];
      final maps = _mapsForProjections(projections, const []);
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a', 'map_b'],
        sceneIds: const ['scene_a', 'scene_b'],
      );
      final snapshot = _snapshot(
        projections,
        project: project,
        maps: maps,
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      ) as Map<String, dynamic>;
      receiptJson['snapshot'] = snapshot.toJson();
      (receiptJson['writePreconditions'] as Map<String, dynamic>)['snapshot'] =
          snapshot.toJson();
      receiptJson['expectedManifestHashAfter'] = snapshot.manifestHash;
      receiptJson['expectedRegistryHashAfter'] = _jsonHash(registry.toJson());
      final receipt = NarrativeEventMigrationReceipt.fromJson(receiptJson);
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          mapProjections: projections,
          currentSnapshot: snapshot,
          existingReceipt: receipt,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes
              .incrementalReceiptHistoryRequired,
        ),
      );
      expect(plan.recordsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('rejects an enabled target as an existing prepared proposal', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final prepared = first.recordsProposed.single;
      final enabledRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        prepared.definitionOrNull!,
        enabled: true,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [enabledRecord],
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final forbiddenIds = _InjectedIds.forbidden();

      final second = _planner(forbiddenIds).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(
        second.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim),
      );
      expect(forbiddenIds.calls, 0);
    });

    test('revalidates receipt target Scenes when choices are not replayed', () {
      final source = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'producer_scene',
          outcomeId: 'victory',
        ),
      );
      final projection = _scenarioProjection(
        scenarioId: 'scenario_outcome',
        nodeId: 'source',
        source: source,
        fingerprintCharacter: 'b',
      );
      final choice = NarrativeEventMigrationSourceChoice(
        provenance: projection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Scenario scenario_outcome',
            conditions: const [],
            sceneId: 'scene_scenario_outcome',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
        ],
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(
          scenarioProjections: [projection],
          choices: NarrativeEventMigrationChoices(sourceChoices: [choice]),
        ),
      );
      final prepared = first.recordsProposed.single.definitionOrNull!;
      final changedRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: prepared.id,
          name: prepared.name,
          source: prepared.source,
          conditions: prepared.conditions,
          sceneId: 'missing_scene',
          reusePolicy: prepared.reusePolicy,
          priority: prepared.priority,
          order: prepared.order,
        ),
        enabled: false,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [changedRecord],
        legacyClaims: first.claimsProposed,
      );
      final claimedProjection = _scenarioProjectionWithClaim(
        projection,
        first.claimsProposed.single,
      );
      final scenarios = _scenariosForProjections([projection]);
      final maps = _mapsForProjections(const [], [projection]);
      final project = _project(
        eventRegistry: registry,
        scenarios: scenarios,
        scenes: _scenesForProjections([projection]),
      );
      final snapshot = _snapshot(
        const [],
        scenarioProjections: [claimedProjection],
        project: project,
        maps: maps,
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      ) as Map<String, dynamic>;
      receiptJson['targetRecords'] = [changedRecord.toJson()];
      receiptJson['expectedManifestHashAfter'] = snapshot.manifestHash;
      receiptJson['expectedRegistryHashAfter'] = _jsonHash(registry.toJson());
      final existingReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          scenarioProjections: [claimedProjection],
          choices: NarrativeEventMigrationChoices.empty(),
          currentSnapshot: snapshot,
          existingReceipt: existingReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(
        second.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('keeps deduplicated cohort targets idempotent', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_shared');
      final projections = [
        _projection(
          mapId: 'map_a',
          legacyEventId: 'shared',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '1',
        ),
        _projection(
          mapId: 'map_b',
          legacyEventId: 'shared',
          source: source,
          sceneId: 'scene_shared',
          fingerprintCharacter: '2',
        ),
      ];
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: projections),
      );
      expect(first.recordsProposed, hasLength(1));
      expect(first.claimsProposed.single.members, hasLength(2));
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a', 'map_b'],
        sceneIds: const ['scene_shared'],
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: projections,
          currentSnapshot: _snapshot(
            projections,
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(second.receiptProposal, same(first.receiptProposal));
      expect(ids.calls, 0);
    });

    test('rejects an existing claim when its exact receipt is absent', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(second.receiptProposal, isNull);
      expect(
        second.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('rejects a receipt when an applied target record was changed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final original = first.recordsProposed.single.definitionOrNull!;
      final changedRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: original.id,
          name: 'Changed after preparation',
          source: original.source,
          conditions: original.conditions,
          sceneId: original.sceneId,
          reusePolicy: original.reusePolicy,
          priority: original.priority,
          order: original.order,
        ),
        enabled: false,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [changedRecord],
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
        existingClaim: first.claimsProposed.single,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects a receipt whose reference mappings were changed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      final mappings = receiptJson['mappings']! as Map<String, dynamic>;
      mappings['ids'] = <Object?>[];
      final changedReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: changedReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects a receipt whose backup plan differs from the input', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      final backupPlan = receiptJson['backupPlan']! as Map<String, dynamic>;
      final destinations =
          backupPlan['futureDestinations']! as Map<String, dynamic>;
      destinations['manifest'] = 'backups/phase-c/other-project.json';
      final changedReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: changedReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects a committed receipt as a Phase C prepared proposal', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final receiptJson = jsonDecode(
        jsonEncode(first.receiptProposal!.toJson()),
      )! as Map<String, dynamic>;
      receiptJson['isProposal'] = false;
      receiptJson['lifecycle'] = {
        'status': 'committed',
        'preparedAt': '2026-07-11T10:00:00.000Z',
        'committedAt': '2026-07-11T10:01:00.000Z',
      };
      final pointOfNoReturn =
          receiptJson['pointOfNoReturn']! as Map<String, dynamic>;
      pointOfNoReturn['reached'] = true;
      final committedReceipt = NarrativeEventMigrationReceipt.fromJson(
        receiptJson,
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: committedReceipt,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('rejects changed lifecycle choices for an existing exact claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '1',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final reusableTarget =
          _defaultChoices([projection]).sourceChoices.single.targets.single;
      final changedChoice = NarrativeEventMigrationSourceChoice(
        provenance: projection.provenance,
        source: projection.confirmedSource!,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: reusableTarget.name,
            legacyPageIndex: reusableTarget.legacyPageIndex,
            conditions: reusableTarget.conditions,
            sceneId: reusableTarget.sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: reusableTarget.priority,
            order: reusableTarget.order,
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [projection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [changedChoice],
          ),
          currentSnapshot: _snapshot(
            [projection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(second.recordsProposed, isEmpty);
      expect(second.receiptProposal, isNull);
      expect(ids.calls, 0);
    });

    test('does not recreate an ASSISTED draft once its exact claim exists', () {
      final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
      final initialProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'b',
      );
      final initialChoice = NarrativeEventMigrationSourceChoice(
        provenance: initialProjection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Assisted event',
            legacyPageIndex: 0,
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
        ],
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(
          mapProjections: [initialProjection],
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [initialChoice],
          ),
        ),
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: first.recordsProposed,
        legacyClaims: first.claimsProposed,
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'assisted',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: 'b',
        existingClaim: first.claimsProposed.single,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a'],
      );
      final ids = _InjectedIds.forbidden();

      final second = _planner(ids).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          currentSnapshot: _snapshot(
            [claimedProjection],
            project: project,
          ),
          existingReceipt: first.receiptProposal,
        ),
      );

      expect(second.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(second.recordsProposed, isEmpty);
      expect(second.draftsProposed, isEmpty);
      expect(second.claimsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('blocks an existing partial cohort instead of hiding a sibling', () {
      final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
      final first = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: source,
        sceneId: 'scene_a',
        fingerprintCharacter: '2',
      );
      final sibling = _projection(
        mapId: 'map_b',
        legacyEventId: 'legacy_b',
        source: source,
        sceneId: 'scene_a',
        fingerprintCharacter: '3',
      );
      final record = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: 'evt_018f0000-0000-7000-8000-000000000001',
          name: 'Existing',
          source: source,
          conditions: const [],
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: false,
      );
      final member = LegacySourceClaimMember(
        provenance: first.provenance,
        sourceFingerprint: first.sourceFingerprint,
      );
      final cohortId = computeLegacySourceCohortId(source, [first.provenance]);
      final partialClaim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint:
            computeLegacySourceCohortFingerprint(cohortId, [member]),
        targetEventIds: [record.id],
        migrationReceiptId: 'evmr_existing',
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [record],
        legacyClaims: [partialClaim],
      );

      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(
          project: _project(
            eventRegistry: registry,
            mapIds: const ['map_a', 'map_b'],
            sceneIds: const ['scene_a'],
          ),
          mapProjections: [first, sibling],
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.claimsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.partialClaim),
      );
    });

    test('rejects duplicate target signatures in an existing claim', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '3',
      );
      final first = _planner(_InjectedIds.standardTwo()).plan(
        _input(mapProjections: [projection]),
      );
      final originalRecord = first.recordsProposed.single;
      final original = originalRecord.definitionOrNull!;
      const duplicateId = 'evt_018f0000-0000-7000-8000-000000000003';
      final duplicateRecord =
          NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: duplicateId,
          name: original.name,
          source: original.source,
          conditions: original.conditions,
          sceneId: original.sceneId,
          reusePolicy: original.reusePolicy,
          priority: original.priority,
          order: original.order,
        ),
        enabled: false,
      );
      final originalClaim = first.claimsProposed.single;
      final duplicateClaim = LegacySourceClaim(
        cohortId: originalClaim.cohortId,
        source: originalClaim.source,
        members: originalClaim.members,
        cohortFingerprint: originalClaim.cohortFingerprint,
        targetEventIds: [originalRecord.id, duplicateId],
        migrationReceiptId: originalClaim.migrationReceiptId,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [originalRecord, duplicateRecord],
        legacyClaims: [duplicateClaim],
      );
      final assistedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: original.source,
        sceneId: original.sceneId,
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '3',
        existingClaim: duplicateClaim,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: _project(
            eventRegistry: registry,
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ),
          mapProjections: [assistedProjection],
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.partialClaim),
      );
      expect(ids.calls, 0);
    });

    test('keeps an invalid or tombstone claim fail-closed', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'tombstone',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: 'c',
        claimStatus: LegacyProjectionClaimStatus.invalid,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(mapProjections: [projection]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.claimsProposed, isEmpty);
      expect(ids.calls, 0);
    });

    test('blocks stale revision and source hashes before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = _snapshot([projection], revision: 'revision-current');
      final expected = _snapshot([projection], revision: 'revision-old');
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
          expectedSnapshot: expected,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.staleRevision),
      );
      expect(ids.calls, 0);
    });

    test('blocks a stale source fingerprint before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = NarrativeEventMigrationSnapshot(
        projectRevisionToken: 'revision-1',
        manifestHash: _jsonHash(
          _project(
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ).toJson(),
        ),
        corpusHash: _jsonHash(const {'version': 'C1-v0'}),
        referenceCatalogHash: _jsonHash(
          NarrativeEventReferenceCatalog.empty().toJson(),
        ),
        mapHashes: {
          'map_a': _jsonHash(
            _mapsForProjections([projection], const []).single.toJson(),
          ),
        },
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(projection.provenance): _hash('5'),
        },
        saveHashes: const {},
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('requires every concerned map hash before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final current = NarrativeEventMigrationSnapshot(
        projectRevisionToken: 'revision-1',
        manifestHash: _jsonHash(
          _project(
            mapIds: const ['map_a'],
            sceneIds: const ['scene_a'],
          ).toJson(),
        ),
        corpusHash: _jsonHash(const {'version': 'C1-v0'}),
        referenceCatalogHash: _jsonHash(
          NarrativeEventReferenceCatalog.empty().toJson(),
        ),
        mapHashes: const {},
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
        },
        saveHashes: const {},
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          mapProjections: [projection],
          currentSnapshot: current,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('blocks a changed read-only map before consuming IDs', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final originalMap = _mapsForProjections([projection], const []).single;
      final changedMap = originalMap.copyWith(name: 'Changed map');
      final snapshot = _snapshot(
        [projection],
        maps: [originalMap],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          maps: [changedMap],
          mapProjections: [projection],
          currentSnapshot: snapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch),
      );
      expect(ids.calls, 0);
    });

    test('blocks when a characterized source projection is omitted', () {
      final included = _projection(
        mapId: 'map_a',
        legacyEventId: 'included',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '4',
      );
      final omitted = _projection(
        mapId: 'map_b',
        legacyEventId: 'omitted',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '5',
      );
      final completeMaps = _mapsForProjections([included, omitted], const []);
      final incompleteSnapshot = _snapshot(
        [included],
        maps: completeMaps,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          maps: completeMaps,
          mapProjections: [included],
          currentSnapshot: incompleteSnapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('blocks when a Scenario source-node projection is omitted', () {
      final included = _scenarioProjection(
        scenarioId: 'scenario_a',
        nodeId: 'source_a',
        source: NarrativeEventSourceRef.mapEnter('map_a'),
        fingerprintCharacter: '6',
      );
      final omitted = _scenarioProjection(
        scenarioId: 'scenario_b',
        nodeId: 'source_b',
        source: NarrativeEventSourceRef.mapEnter('map_b'),
        fingerprintCharacter: '7',
      );
      final project = _project(
        mapIds: const ['map_a', 'map_b'],
        scenarios: _scenariosForProjections([included, omitted]),
        scenes: _scenesForProjections([included, omitted]),
      );
      final maps = _mapsForProjections(const [], [included, omitted]);
      final incompleteSnapshot = _snapshot(
        const [],
        scenarioProjections: [included],
        project: project,
        maps: maps,
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: project,
          maps: maps,
          scenarioProjections: [included],
          currentSnapshot: incompleteSnapshot,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        ),
      );
      expect(ids.calls, 0);
    });

    test('blocks when manifest and supplied map inventories diverge', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '8',
      );
      final maps = _mapsForProjections([projection], const []);
      final projectWithoutMap = _project(sceneIds: const ['scene_a']);
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          project: projectWithoutMap,
          maps: maps,
          mapProjections: [projection],
          currentSnapshot: _snapshot(
            [projection],
            project: projectWithoutMap,
            maps: maps,
          ),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('project.maps'),
      );
      expect(ids.calls, 0);
    });

    test('blocks stale reference and save evidence before consuming IDs', () {
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'missing',
        candidateProvenances: const [],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          saveSnapshots: const [
            {'saveId': 'save_a', 'consumedEventIds': []},
          ],
          currentSnapshot: _snapshot(const []),
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code ==
                  NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
            )
            .map((diagnostic) => diagnostic.path),
        containsAll(['referenceCatalogHash', 'saveHashes']),
      );
      expect(ids.calls, 0);
    });

    test('blocks a reference omitted from the characterized corpus catalog',
        () {
      const corpus = {
        'version': 'C1-v0',
        'references': [
          {
            'kind': 'GameState.consumedEventIds',
            'path': 'gameStates.save_a.consumedEventIds[0]',
            'rawId': 'legacy_a',
            'candidates': <String>[],
          },
        ],
      };
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(characterizedCorpus: corpus),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('characterizedCorpus.references'),
      );
      expect(ids.calls, 0);
    });

    test('blocks a catalog that truncates characterized provenances', () {
      const path = 'gameStates.save_a.consumedEventIds[0]';
      const corpus = {
        'version': 'C1-v0',
        'references': [
          {
            'kind': 'GameState.consumedEventIds',
            'path': path,
            'rawId': 'legacy_a',
            'candidates': ['map_a:legacy_a', 'map_b:legacy_a'],
          },
        ],
      };
      final references = NarrativeEventReferenceCatalog(
        progression: [
          LegacyEventReference(
            kind: LegacyEventReferenceKind.consumedEventState,
            path: path,
            legacyEventId: 'legacy_a',
            candidateProvenances: [
              LegacySourceRef.mapEvent('map_a', 'legacy_a'),
            ],
          ),
        ],
      );
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          references: references,
          characterizedCorpus: corpus,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('characterizedCorpus.references'),
      );
      expect(ids.calls, 0);
    });

    test('blocks a consumed save entry omitted from the reference catalog', () {
      const saves = [
        {
          'saveId': 'save_a',
          'consumedEventIds': ['legacy_a'],
        },
      ];
      final ids = _InjectedIds.forbidden();

      final plan = _planner(ids).plan(
        _input(
          saveSnapshots: saves,
        ),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.path),
        contains('gameStates.save_a.consumedEventIds[0]'),
      );
      expect(ids.calls, 0);
    });

    test('rejects unused source and reference choices without consuming IDs',
        () {
      final orphan = LegacySourceRef.mapEvent('map_a', 'orphan');
      final ids = _InjectedIds.forbidden();
      final choices = NarrativeEventMigrationChoices(
        sourceChoices: [
          NarrativeEventMigrationSourceChoice(
            provenance: orphan,
            source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: 'Orphan',
                conditions: const [],
                sceneId: 'scene_a',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
            ],
          ),
        ],
        referenceChoices: [
          NarrativeEventReferenceResolutionChoice(
            path: 'missing.reference.path',
            decision: NarrativeEventReferenceCollisionDecision.cancel,
          ),
        ],
      );

      final plan = _planner(ids).plan(
        _input(choices: choices),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.recordsProposed, isEmpty);
      expect(plan.receiptProposal, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.unusedChoice),
      );
      expect(ids.calls, 0);
    });

    test('preserves unknown JSON and keeps the plan blocked', () {
      final unknown = NarrativeEventUnknownLegacyData(
        path: 'maps.map_a.events.legacy_a.futureField',
        value: {
          'nested': [1, true, 'kept'],
        },
      );
      final plan = _planner(_InjectedIds.forbidden()).plan(
        _input(unknownLegacyData: [unknown]),
      );

      expect(plan.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(plan.unknownLegacyData.single.toJson(), unknown.toJson());
      final nested = plan.unknownLegacyData.single.value as Map;
      expect(() => nested['lost'] = true, throwsUnsupportedError);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(NarrativeEventMigrationDiagnosticCodes.unknownLegacyData),
      );
    });

    test('requires an explicit consumedEventIds collision resolution', () {
      final first = _projection(
        mapId: 'map_a',
        legacyEventId: 'shared',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '5',
      );
      final second = _projection(
        mapId: 'map_b',
        legacyEventId: 'shared',
        source: NarrativeEventSourceRef.entityInteract('map_b', 'npc_b'),
        sceneId: 'scene_b',
        fingerprintCharacter: '6',
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'shared',
        candidateProvenances: [first.provenance, second.provenance],
      );
      final idsA = _InjectedIds.forbidden();
      final blocked = _planner(idsA).plan(
        _input(
          mapProjections: [first, second],
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
        ),
      );
      expect(blocked.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(
        blocked.mappings.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );
      expect(blocked.recordsProposed, isEmpty);
      expect(blocked.receiptProposal, isNull);
      expect(idsA.calls, 0);

      final idsB = _InjectedIds.standardThree();
      final resolved = _planner(idsB).plan(
        _input(
          mapProjections: [first, second],
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          choices: _choicesWithReferences(
            [first, second],
            referenceChoices: [
              NarrativeEventReferenceResolutionChoice(
                path: reference.path,
                decision:
                    NarrativeEventReferenceCollisionDecision.consumeAllTargets,
              ),
            ],
          ),
        ),
      );
      expect(resolved.status, NarrativeEventMigrationPlanStatus.ready);
      expect(
        resolved.mappings.progressionMappings.single.targetEventIds,
        hasLength(2),
      );
    });

    test('selects future fan-out targets by stable pre-allocation keys', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_a', 'npc_confirmed');
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'fan_out',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '8',
      );
      final sourceChoice = NarrativeEventMigrationSourceChoice(
        provenance: projection.provenance,
        source: source,
        targets: [
          NarrativeEventMigrationTargetProposal(
            name: 'Target A',
            conditions: const [],
            sceneId: 'scene_a',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          NarrativeEventMigrationTargetProposal(
            name: 'Target B',
            conditions: const [],
            sceneId: 'scene_b',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 1,
          ),
        ],
      );
      final reference = LegacyEventReference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'fan_out',
        candidateProvenances: [projection.provenance],
      );
      final references = NarrativeEventReferenceCatalog(
        progression: [reference],
      );
      final blockedIds = _InjectedIds.forbidden();

      final blocked = _planner(blockedIds).plan(
        _input(
          mapProjections: [projection],
          references: references,
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [sourceChoice],
          ),
        ),
      );

      final availableKeys =
          blocked.mappings.progressionMappings.single.availableTargetKeys;
      expect(blocked.status, NarrativeEventMigrationPlanStatus.blocked);
      expect(availableKeys, hasLength(2));
      expect(blocked.recordsProposed, isEmpty);
      expect(blockedIds.calls, 0);

      final resolved = _planner(_InjectedIds.standardThree()).plan(
        _input(
          mapProjections: [projection],
          references: references,
          choices: NarrativeEventMigrationChoices(
            sourceChoices: [sourceChoice],
            referenceChoices: [
              NarrativeEventReferenceResolutionChoice(
                path: reference.path,
                decision:
                    NarrativeEventReferenceCollisionDecision.selectedTargets,
                selectedTargetKeys: [availableKeys.first],
              ),
            ],
          ),
        ),
      );

      expect(resolved.status, NarrativeEventMigrationPlanStatus.ready);
      expect(resolved.recordsProposed, hasLength(2));
      expect(
        resolved.mappings.progressionMappings.single.targetEventIds,
        hasLength(1),
      );

      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: resolved.recordsProposed,
        legacyClaims: resolved.claimsProposed,
      );
      final project = _project(
        eventRegistry: registry,
        mapIds: const ['map_a'],
        sceneIds: const ['scene_a', 'scene_b'],
      );
      final claimedProjection = _projection(
        mapId: 'map_a',
        legacyEventId: 'fan_out',
        source: source,
        sceneId: 'scene_a',
        classification: LegacyMigrationClassification.assisted,
        confirmed: false,
        fingerprintCharacter: '8',
        existingClaim: resolved.claimsProposed.single,
      );
      final replayIds = _InjectedIds.forbidden();
      final replay = _planner(replayIds).plan(
        _input(
          project: project,
          mapProjections: [claimedProjection],
          references: references,
          choices: NarrativeEventMigrationChoices.empty(),
          existingReceipt: resolved.receiptProposal,
        ),
      );

      expect(replay.status, NarrativeEventMigrationPlanStatus.alreadyPrepared);
      expect(
        canonicalizeNarrativeEventJson(replay.mappings.toJson()),
        canonicalizeNarrativeEventJson(resolved.mappings.toJson()),
      );
      expect(replayIds.calls, 0);
    });

    test('is deterministic for identical inputs, IDs, choices, and clock', () {
      final projection = _projection(
        mapId: 'map_a',
        legacyEventId: 'legacy_a',
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        sceneId: 'scene_a',
        fingerprintCharacter: '7',
      );
      final input = _input(mapProjections: [projection]);
      final first = _planner(_InjectedIds.standardTwo()).plan(input);
      final second = _planner(_InjectedIds.standardTwo()).plan(input);

      expect(
        canonicalizeNarrativeEventJson(first.toJson()),
        canonicalizeNarrativeEventJson(second.toJson()),
      );
    });
  });
}

NarrativeEventMigrationPlanner _planner(_InjectedIds ids) {
  return NarrativeEventMigrationPlanner(
    ids: ids,
    clock: () => DateTime.utc(2026, 7, 11, 10),
  );
}

NarrativeEventMigrationPlannerInput _input({
  ProjectManifest? project,
  List<MapData>? maps,
  List<LegacyMapEventProjection> mapProjections = const [],
  List<LegacyScenarioSourceProjection> scenarioProjections = const [],
  NarrativeEventReferenceCatalog? references,
  NarrativeEventMigrationChoices? choices,
  NarrativeEventMigrationSnapshot? currentSnapshot,
  NarrativeEventMigrationSnapshot? expectedSnapshot,
  NarrativeEventMigrationReceipt? existingReceipt,
  List<NarrativeEventUnknownLegacyData> unknownLegacyData = const [],
  Map<String, Object?>? characterizedCorpus,
  List<Map<String, Object?>> saveSnapshots = const [],
}) {
  final referenceCatalog = references ?? NarrativeEventReferenceCatalog.empty();
  final resolvedCorpus =
      characterizedCorpus ?? _characterizedCorpusFor(referenceCatalog);
  final resolvedChoices = choices ?? _defaultChoices(mapProjections);
  final resolvedMaps = maps ??
      _mapsForProjections(
        mapProjections,
        scenarioProjections,
      );
  final resolvedProject = project ??
      _project(
        mapIds: [for (final map in resolvedMaps) map.id],
        scenarios: _scenariosForProjections(scenarioProjections),
        scenes: _projectScenesForProjections(
          mapProjections,
          scenarioProjections,
          choices: resolvedChoices,
        ),
      );
  return NarrativeEventMigrationPlannerInput(
    project: resolvedProject,
    maps: resolvedMaps,
    mapEventProjections: mapProjections,
    scenarioProjections: scenarioProjections,
    references: referenceCatalog,
    currentSnapshot: currentSnapshot ??
        _snapshot(
          mapProjections,
          scenarioProjections: scenarioProjections,
          characterizedCorpus: resolvedCorpus,
          references: referenceCatalog,
          saveSnapshots: saveSnapshots,
          project: resolvedProject,
          maps: resolvedMaps,
        ),
    expectedSnapshot: expectedSnapshot,
    choices: resolvedChoices,
    characterizedCorpus: resolvedCorpus,
    saveSnapshots: saveSnapshots,
    unknownLegacyData: unknownLegacyData,
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-c/project.json',
        'receipt': 'backups/phase-c/receipt.json',
      },
    ),
    existingReceipt: existingReceipt,
  );
}

Map<String, Object?> _characterizedCorpusFor(
  NarrativeEventReferenceCatalog references,
) {
  return {
    'version': 'C1-v0',
    if (!references.isEmpty)
      'references': [
        for (final reference in references.all)
          {
            'kind': switch (reference.kind) {
              LegacyEventReferenceKind.consumedEventState =>
                'GameState.consumedEventIds',
              LegacyEventReferenceKind.scriptCondition => 'ScriptCondition',
              LegacyEventReferenceKind.worldRuleSource =>
                'WorldRuleDefinition.source',
              LegacyEventReferenceKind.worldRuleTarget =>
                'WorldRuleDefinition.target',
              LegacyEventReferenceKind.sceneConsequence => 'SceneConsequence',
              LegacyEventReferenceKind.scenarioNodeBinding =>
                'ScenarioNodeBinding',
              LegacyEventReferenceKind.scriptCommand => 'ScriptCommand',
              LegacyEventReferenceKind.metadata => 'metadata',
              LegacyEventReferenceKind.validatorDiagnostic =>
                'EventSceneLinkDiagnostic',
            },
            'path': reference.path,
            'rawId': reference.legacyEventId,
            if (reference.mapId != null) 'mapId': reference.mapId,
            'candidates': [
              for (final provenance in reference.candidateProvenances)
                provenance.when(
                  mapEvent: (mapId, eventId) => '$mapId:$eventId',
                  scenarioSourceNode: (scenarioId, nodeId) =>
                      'scenarioSourceNode:$scenarioId:$nodeId',
                ),
            ]..sort(),
          },
      ],
  };
}

NarrativeEventMigrationChoices _defaultChoices(
  List<LegacyMapEventProjection> projections,
) {
  return NarrativeEventMigrationChoices(
    sourceChoices: [
      for (final projection in projections)
        if (projection.classification ==
                LegacyMigrationClassification.autoSafe &&
            projection.confirmedSource != null &&
            projection.pages.length == 1 &&
            projection.pages.single.sceneId != null)
          NarrativeEventMigrationSourceChoice(
            provenance: projection.provenance,
            source: projection.confirmedSource!,
            targets: [
              NarrativeEventMigrationTargetProposal(
                name: _mapEventFromProjection(projection).title,
                legacyPageIndex: projection.pages.single.pageIndex,
                conditions: const [],
                sceneId: projection.pages.single.sceneId,
                reusePolicy: NarrativeEventReusePolicy.reusable,
                priority: 0,
                order: projection.pages.single.pageIndex,
              ),
            ],
          ),
    ],
  );
}

NarrativeEventMigrationChoices _choicesWithReferences(
  List<LegacyMapEventProjection> projections, {
  required List<NarrativeEventReferenceResolutionChoice> referenceChoices,
}) {
  final sourceChoices = _defaultChoices(projections).sourceChoices;
  return NarrativeEventMigrationChoices(
    sourceChoices: sourceChoices,
    referenceChoices: referenceChoices,
  );
}

ProjectManifest _project({
  NarrativeEventRegistry? eventRegistry,
  List<String> mapIds = const [],
  List<String> sceneIds = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
}) {
  final scenesById = <String, SceneAsset>{
    for (final sceneId in sceneIds) sceneId: _sceneForMapTarget(sceneId),
    for (final scene in scenes) scene.id: scene,
  };
  final sortedSceneIds = scenesById.keys.toList()..sort();
  return ProjectManifest(
    name: 'Phase C4',
    maps: [
      for (final mapId in mapIds)
        ProjectMapEntry(
          id: mapId,
          name: 'Map $mapId',
          relativePath: 'maps/$mapId.json',
        ),
    ],
    tilesets: const [],
    scenarios: scenarios,
    scenes: [for (final sceneId in sortedSceneIds) scenesById[sceneId]!],
    eventRegistry: eventRegistry,
  );
}

NarrativeEventMigrationSnapshot _snapshot(
  List<LegacyMapEventProjection> projections, {
  List<LegacyScenarioSourceProjection> scenarioProjections = const [],
  String revision = 'revision-1',
  ProjectManifest? project,
  List<MapData>? maps,
  Map<String, Object?> characterizedCorpus = const {'version': 'C1-v0'},
  NarrativeEventReferenceCatalog? references,
  List<Map<String, Object?>> saveSnapshots = const [],
}) {
  final referenceCatalog = references ?? NarrativeEventReferenceCatalog.empty();
  final resolvedMaps = maps ??
      _mapsForProjections(
        projections,
        scenarioProjections,
      );
  return NarrativeEventMigrationSnapshot(
    projectRevisionToken: revision,
    manifestHash: _jsonHash(
      (project ??
              _project(
                mapIds: [for (final map in resolvedMaps) map.id],
                scenarios: _scenariosForProjections(scenarioProjections),
                scenes: _projectScenesForProjections(
                  projections,
                  scenarioProjections,
                ),
              ))
          .toJson(),
    ),
    corpusHash: _jsonHash(characterizedCorpus),
    referenceCatalogHash: _jsonHash(referenceCatalog.toJson()),
    mapHashes: {
      for (final map in resolvedMaps) map.id: _jsonHash(map.toJson()),
    },
    legacySourceHashes: {
      for (final projection in projections)
        legacyMigrationSourceSnapshotKey(projection.provenance):
            projection.sourceFingerprint,
      for (final projection in scenarioProjections)
        legacyMigrationSourceSnapshotKey(projection.provenance):
            projection.sourceFingerprint,
    },
    saveHashes: _saveHashes(saveSnapshots),
  );
}

List<MapData> _mapsForProjections(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections,
) {
  final ids = _concernedMapIds(mapProjections, scenarioProjections).toList()
    ..sort();
  return [
    for (final id in ids)
      _mapData(
        id,
        events: [
          for (final projection in mapProjections)
            if (_mapIdOf(projection.provenance) == id)
              _mapEventFromProjection(projection),
        ],
      ),
  ];
}

MapData _mapData(
  String id, {
  String? name,
  List<MapEventDefinition> events = const [],
}) {
  return MapData(
    id: id,
    name: name ?? 'Map $id',
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Events')],
    events: events,
  );
}

MapEventDefinition _mapEventFromProjection(
  LegacyMapEventProjection projection,
) {
  return MapEventDefinition.fromJson(
    Map<String, dynamic>.from(projection.preservedEventJson),
  );
}

List<ScenarioAsset> _scenariosForProjections(
  List<LegacyScenarioSourceProjection> projections,
) {
  final scenarioIds = {
    for (final projection in projections) projection.scenarioId
  }.toList()
    ..sort();
  return [
    for (final scenarioId in scenarioIds)
      ScenarioAsset.fromJson(
        Map<String, dynamic>.from(
          projections
              .firstWhere(
                (projection) => projection.scenarioId == scenarioId,
              )
              .preservedScenarioJson,
        ),
      ),
  ];
}

List<SceneAsset> _scenesForProjections(
  List<LegacyScenarioSourceProjection> projections,
) {
  final scenarioIds = {
    for (final projection in projections) projection.scenarioId,
  }.toList()
    ..sort();
  return [
    for (final scenarioId in scenarioIds) _sceneForScenario(scenarioId),
  ];
}

List<SceneAsset> _projectScenesForProjections(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections, {
  NarrativeEventMigrationChoices? choices,
}) {
  final scenesById = <String, SceneAsset>{};
  for (final projection in mapProjections) {
    for (final page in projection.pages) {
      final sceneId = page.sceneId;
      if (sceneId != null) {
        scenesById.putIfAbsent(sceneId, () => _sceneForMapTarget(sceneId));
      }
    }
  }
  for (final choice in choices?.sourceChoices ?? const []) {
    for (final target in choice.targets) {
      final sceneId = target.sceneId;
      if (sceneId != null) {
        scenesById.putIfAbsent(sceneId, () => _sceneForMapTarget(sceneId));
      }
    }
  }
  for (final scene in _scenesForProjections(scenarioProjections)) {
    scenesById[scene.id] = scene;
  }
  final ids = scenesById.keys.toList()..sort();
  return [for (final id in ids) scenesById[id]!];
}

ScenarioNode _scenarioNodeForSource(
  String nodeId,
  NarrativeEventSourceRef? source, {
  String? sceneId,
}) {
  final actionKind = source?.when(
        entityInteract: (_, __) => 'sourceEntityInteract',
        triggerEnter: (_, __) => 'sourceTriggerEnter',
        mapEnter: (_) => 'sourceMapEnter',
        outcomeReceived: (_) => 'sourceOutcome',
      ) ??
      'sourceOutcome';
  final binding = source?.when(
        entityInteract: (mapId, entityId) => ScenarioNodeBinding(
          mapId: mapId,
          entityId: entityId,
        ),
        triggerEnter: (mapId, triggerId) => ScenarioNodeBinding(
          mapId: mapId,
          triggerId: triggerId,
        ),
        mapEnter: (mapId) => ScenarioNodeBinding(mapId: mapId),
        outcomeReceived: (outcome) => ScenarioNodeBinding(
          outcomeId: outcome.outcomeId,
        ),
      ) ??
      const ScenarioNodeBinding(outcomeId: 'unqualified');
  return ScenarioNode(
    id: nodeId,
    type: ScenarioNodeType.reference,
    binding: binding,
    payload: ScenarioNodePayload(actionKind: actionKind),
    metadata: {
      if (sceneId != null) 'eventV2.sceneId': sceneId,
    },
  );
}

String? _mapIdOf(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, _) => mapId,
    scenarioSourceNode: (_, __) => null,
  );
}

Set<String> _concernedMapIds(
  List<LegacyMapEventProjection> mapProjections,
  List<LegacyScenarioSourceProjection> scenarioProjections,
) {
  final result = <String>{};
  for (final projection in mapProjections) {
    projection.provenance.when(
      mapEvent: (mapId, _) => result.add(mapId),
      scenarioSourceNode: (_, __) {},
    );
    _addSourceMap(result, projection.confirmedSource);
  }
  for (final projection in scenarioProjections) {
    _addSourceMap(result, projection.source);
  }
  return result;
}

void _addSourceMap(Set<String> result, NarrativeEventSourceRef? source) {
  source?.when(
    entityInteract: (mapId, _) => result.add(mapId),
    triggerEnter: (mapId, _) => result.add(mapId),
    mapEnter: result.add,
    outcomeReceived: (_) {},
  );
}

LegacyMapEventProjection _projection({
  required String mapId,
  required String legacyEventId,
  required NarrativeEventSourceRef source,
  required String sceneId,
  required String fingerprintCharacter,
  LegacyMigrationClassification classification =
      LegacyMigrationClassification.autoSafe,
  bool confirmed = true,
  LegacySourceClaim? existingClaim,
  LegacyProjectionClaimStatus? claimStatus,
  List<LegacyMapEventPageProjection>? pages,
}) {
  final resolvedPages = pages ??
      [
        LegacyMapEventPageProjection(
          pageIndex: 0,
          pageNumber: 1,
          condition: null,
          script: null,
          spriteId: null,
          message: null,
          sceneId: sceneId,
          isHidden: false,
          isDisabled: false,
          metadata: const {},
        ),
      ];
  final event = MapEventDefinition(
    id: legacyEventId,
    title: 'Legacy $legacyEventId',
    pages: [
      for (final page in resolvedPages)
        MapEventPage(
          pageNumber: page.pageNumber,
          condition: page.condition,
          script: page.script,
          spriteId: page.spriteId,
          message: page.message,
          sceneTarget: page.sceneId == null
              ? null
              : MapEventSceneTarget(sceneId: page.sceneId!),
          isHidden: page.isHidden,
          isDisabled: page.isDisabled,
          metadata: page.metadata,
        ),
    ],
    position: const EventPosition(layerId: 'events', x: 0, y: 0),
    type: MapEventType.object,
    metadata: {'testFingerprint': fingerprintCharacter},
  );
  return LegacyMapEventProjection(
    provenance: LegacySourceRef.mapEvent(mapId, legacyEventId),
    classification: classification,
    claimStatus: claimStatus ??
        (existingClaim == null
            ? LegacyProjectionClaimStatus.absent
            : LegacyProjectionClaimStatus.valid),
    existingClaim: existingClaim,
    sourceFingerprint: computeMapEventSourceFingerprint(
      mapId: mapId,
      event: event,
    ),
    sourceCandidates: [
      LegacyMapEventSourceCandidate(
        source: source,
        evidence: confirmed
            ? LegacyMapEventSourceEvidenceKind.explicitMetadata
            : LegacyMapEventSourceEvidenceKind.exactUniqueFootprint,
        confirmed: confirmed,
        reason: confirmed ? 'Explicit metadata.' : 'Position hint only.',
      ),
    ],
    pages: resolvedPages,
    preservedEventJson: event.toJson(),
    unconvertibleDataPaths: const [],
    linkedReferences: const [],
    diagnostics: const [],
    manualActions: const [],
  );
}

LegacyScenarioSourceProjection _scenarioProjection({
  required String scenarioId,
  required String nodeId,
  required NarrativeEventSourceRef source,
  required String fingerprintCharacter,
}) {
  final scene = _sceneForScenario(scenarioId);
  final scenario = ScenarioAsset(
    id: scenarioId,
    name: 'Scenario $scenarioId',
    entryNodeId: nodeId,
    nodes: [
      _scenarioNodeForSource(nodeId, source, sceneId: scene.id),
      ScenarioNode(
        id: 'dialogue',
        type: ScenarioNodeType.dialogue,
        binding: ScenarioNodeBinding(
          dialogueId: 'dialogue_$scenarioId',
        ),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: [
      ScenarioEdge(
        id: 'edge_source',
        fromNodeId: nodeId,
        toNodeId: 'dialogue',
      ),
      const ScenarioEdge(
        id: 'edge_end',
        fromNodeId: 'dialogue',
        toNodeId: 'end',
      ),
    ],
    metadata: {'testFingerprint': fingerprintCharacter},
  );
  return projectLegacyScenarioSourceReadOnly(
    scenario: scenario,
    node: scenario.nodes.first,
    scenes: [scene],
    claimIndex: buildValidatedLegacyClaimIndex(
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
    ),
    lifecycleEvidence: LegacyScenarioLifecycleEvidence.oneShot,
  );
}

LegacyScenarioSourceProjection _scenarioProjectionWithClaim(
  LegacyScenarioSourceProjection projection,
  LegacySourceClaim claim,
) {
  return LegacyScenarioSourceProjection(
    scenarioId: projection.scenarioId,
    nodeId: projection.nodeId,
    provenance: projection.provenance,
    source: projection.source,
    sceneCandidateId: projection.sceneCandidateId,
    lifecycleEvidence: projection.lifecycleEvidence,
    reusePolicyCandidate: projection.reusePolicyCandidate,
    graphComplexity: projection.graphComplexity,
    classification: projection.classification,
    claimStatus: LegacyProjectionClaimStatus.valid,
    existingClaim: claim,
    sourceFingerprint: projection.sourceFingerprint,
    actions: projection.actions,
    conditions: projection.conditions,
    preservedScenarioJson: projection.preservedScenarioJson,
    diagnostics: projection.diagnostics,
    manualActions: projection.manualActions,
  );
}

SceneAsset _sceneForScenario(
  String scenarioId, {
  String? dialogueId,
}) {
  return SceneAsset.fromJson({
    'id': 'scene_$scenarioId',
    'name': 'Scene $scenarioId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {
          'id': 'dialogue',
          'kind': 'yarnDialogue',
          'payload': {
            'kind': 'yarnDialogue',
            'dialogueId': dialogueId ?? 'dialogue_$scenarioId',
          },
        },
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_start',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'dialogue',
          'kind': 'default',
        },
        {
          'id': 'edge_end',
          'fromNodeId': 'dialogue',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

SceneAsset _sceneForMapTarget(String sceneId) {
  return SceneAsset.fromJson({
    'id': sceneId,
    'name': 'Scene $sceneId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge_end',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

SceneAsset _unbuildableScene(String sceneId) {
  return SceneAsset.fromJson({
    'id': sceneId,
    'name': 'Broken $sceneId',
    'graph': {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
      ],
      'edges': <Object?>[],
    },
  });
}

String _hash(String character) => 'sha256:${character * 64}';

String _jsonHash(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(value)}';

Map<String, String> _saveHashes(List<Map<String, Object?>> snapshots) {
  return {
    for (final snapshot in snapshots)
      snapshot['saveId']! as String: _jsonHash(snapshot),
  };
}

final class _InjectedIds implements NarrativeEventMigrationIdSource {
  _InjectedIds({
    required List<String> eventIds,
    required List<String> receiptIds,
  })  : _eventIds = List.of(eventIds),
        _receiptIds = List.of(receiptIds);

  _InjectedIds.forbidden()
      : _eventIds = const [],
        _receiptIds = const [],
        _forbidden = true;

  factory _InjectedIds.standardTwo() => _InjectedIds(
        eventIds: const ['evt_018f0000-0000-7000-8000-000000000001'],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000002'],
      );

  factory _InjectedIds.standardThree() => _InjectedIds(
        eventIds: const [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000002',
        ],
        receiptIds: const ['evmr_018f0000-0000-7000-8000-000000000003'],
      );

  final List<String> _eventIds;
  final List<String> _receiptIds;
  bool _forbidden = false;
  int calls = 0;

  @override
  String nextEventId() {
    calls++;
    if (_forbidden || _eventIds.isEmpty) {
      throw StateError('event ID generation was not expected');
    }
    return _eventIds.removeAt(0);
  }

  @override
  String nextReceiptId() {
    calls++;
    if (_forbidden || _receiptIds.isEmpty) {
      throw StateError('receipt ID generation was not expected');
    }
    return _receiptIds.removeAt(0);
  }
}
````

</details>

### `packages/map_core/test/narrative_event_migration_receipt_test.dart`

SHA-256: `3e9abe0e341488aa81befb0e3e7d5fa1e41af8fa0f2904947d8b602d04e00cc3` — 563 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 migration receipt', () {
    test('round-trips the prepared receipt through a canonical JSON golden',
        () {
      final receipt = _receipt();
      final canonical = canonicalizeNarrativeEventJson(receipt.toJson());

      expect(canonical, _receiptGolden);
      final decoded = NarrativeEventMigrationReceipt.fromJson(
        receipt.toJson(),
      );
      expect(
        canonicalizeNarrativeEventJson(decoded.toJson()),
        _receiptGolden,
      );
      expect(decoded.isProposal, isTrue);
      expect(
        decoded.lifecycle.status,
        NarrativeEventMigrationReceiptStatus.prepared,
      );
      expect(decoded.expectedManifestHashAfter, _hash('1'));
      expect(decoded.expectedRegistryHashAfter, _hash('2'));
    });

    test('requires valid expected after hashes', () {
      final missingManifestHash = _receiptJson()
        ..remove('expectedManifestHashAfter');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(missingManifestHash),
        throwsFormatException,
      );

      final missingRegistryHash = _receiptJson()
        ..remove('expectedRegistryHashAfter');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(missingRegistryHash),
        throwsFormatException,
      );

      final malformedManifestHash = _receiptJson();
      malformedManifestHash['expectedManifestHashAfter'] = 'sha256:${'A' * 64}';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(malformedManifestHash),
        throwsArgumentError,
      );

      final malformedRegistryHash = _receiptJson();
      malformedRegistryHash['expectedRegistryHashAfter'] = 'sha256:short';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(malformedRegistryHash),
        throwsArgumentError,
      );
    });

    test('models prepared, committed, and recovered without false atomicity',
        () {
      final prepared = NarrativeEventMigrationReceiptLifecycle.prepared(
        DateTime.utc(2026, 7, 11, 10),
      );
      final committed = prepared.committed(DateTime.utc(2026, 7, 11, 10, 1));
      final recovered = committed.recovered(DateTime.utc(2026, 7, 11, 10, 2));

      expect(committed.status, NarrativeEventMigrationReceiptStatus.committed);
      expect(recovered.status, NarrativeEventMigrationReceiptStatus.recovered);
      expect(
        () => committed.committed(DateTime.utc(2026, 7, 11, 10, 3)),
        throwsStateError,
      );
      expect(
        () => prepared.recovered(DateTime.utc(2026, 7, 11, 9)),
        throwsArgumentError,
      );

      final receipt = _receipt();
      expect(receipt.atomicityPlan.claimsMultiFileAtomicity, isFalse);
      expect(receipt.atomicityPlan.manifestStagingRequired, isTrue);
      expect(receipt.atomicityPlan.unitRenameOnly, isTrue);
      expect(receipt.atomicityPlan.legacyMapsRemainUnchanged, isTrue);
      expect(receipt.atomicityPlan.crashRecoveryUsesJournal, isTrue);
      expect(
        receipt.atomicityPlan.journalStates,
        ['prepared', 'committed', 'recovered'],
      );
    });

    test('rejects every dishonest atomicity claim from copied JSON', () {
      const dishonestValues = <String, Object?>{
        'claimsMultiFileAtomicity': true,
        'manifestStagingRequired': false,
        'unitRenameOnly': false,
        'legacyMapsRemainUnchanged': false,
        'crashRecoveryUsesJournal': false,
        'journalStates': ['prepared', 'committed'],
      };

      for (final entry in dishonestValues.entries) {
        final json = _receiptJson();
        _jsonObject(json, 'atomicityPlan')[entry.key] = entry.value;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: entry.key,
        );
      }
    });

    test('makes rollback and the point of no return explicit', () {
      final receipt = _receipt();
      final rollback = receipt.rollbackPlan;
      final point = receipt.pointOfNoReturn;

      expect(rollback.requiresUnchangedRevision, isTrue);
      expect(rollback.requiresMatchingHashes, isTrue);
      expect(rollback.availableBeforePointOfNoReturn, isTrue);
      expect(rollback.availableAfterPointOfNoReturn, isFalse);
      expect(rollback.compensatingMigrationRequiredAfter, isTrue);
      expect(point.reached, isFalse);
      expect(point.compensatingMigrationRequiredAfter, isTrue);
      expect(
        point.trigger,
        NarrativeEventMigrationPointOfNoReturn.v2OnlyProgressTrigger,
      );
      final provenance = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      expect(
        receipt.writePreconditions.matches(
          _snapshot(
            legacySourceHashes: {
              legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
            },
          ),
        ),
        isTrue,
      );
      expect(
        receipt.writePreconditions.matches(
          _snapshot(
            projectRevisionToken: 'revision-2',
            legacySourceHashes: {
              legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
            },
          ),
        ),
        isFalse,
      );
    });

    test('requires concrete manifest and receipt backup destinations', () {
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {},
        ),
        throwsArgumentError,
      );
      for (final flags in const [
        (createBeforeCommit: false, noBackupCreatedInPhaseC: true),
        (createBeforeCommit: true, noBackupCreatedInPhaseC: false),
      ]) {
        expect(
          () => NarrativeEventMigrationBackupPlan(
            futureDestinations: const {
              'manifest': 'backup/project.json',
              'receipt': 'backup/receipt.json',
            },
            createBeforeCommit: flags.createBeforeCommit,
            noBackupCreatedInPhaseC: flags.noBackupCreatedInPhaseC,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {'manifest': 'backup/project.json'},
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {
            'manifest': 'backup/shared.json',
            'receipt': 'backup/shared.json',
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects every dishonest rollback claim from copied JSON', () {
      const dishonestValues = <String, Object?>{
        'requiresUnchangedRevision': false,
        'requiresMatchingHashes': false,
        'availableBeforePointOfNoReturn': false,
        'availableAfterPointOfNoReturn': true,
        'compensatingMigrationRequiredAfter': false,
      };

      for (final entry in dishonestValues.entries) {
        final json = _receiptJson();
        _jsonObject(json, 'rollbackPlan')[entry.key] = entry.value;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: entry.key,
        );
      }
    });

    test('rejects divergent snapshots and weakened preconditions', () {
      const preconditionFlags = [
        'requireProjectWritable',
        'requireRegistryMigrationAllowed',
        'requireNoClaimConflicts',
      ];
      for (final flag in preconditionFlags) {
        final json = _receiptJson();
        _jsonObject(json, 'writePreconditions')[flag] = false;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: flag,
        );
      }

      final divergentSnapshot = _receiptJson();
      final writePreconditions = _jsonObject(
        divergentSnapshot,
        'writePreconditions',
      );
      _jsonObject(writePreconditions, 'snapshot')['manifestHash'] = _hash('9');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(divergentSnapshot),
        throwsArgumentError,
      );
    });

    test('rejects weakened point-of-no-return guarantees', () {
      final reached = _receiptJson();
      _jsonObject(reached, 'pointOfNoReturn')['reached'] = true;
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(reached),
        throwsArgumentError,
      );

      final foreignTrigger = _receiptJson();
      _jsonObject(foreignTrigger, 'pointOfNoReturn')['trigger'] =
          'someOtherPointOfNoReturn';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignTrigger),
        throwsArgumentError,
      );

      final noCompensation = _receiptJson();
      _jsonObject(
        noCompensation,
        'pointOfNoReturn',
      )['compensatingMigrationRequiredAfter'] = false;
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(noCompensation),
        throwsArgumentError,
      );

      final changedDescription = _receiptJson();
      _jsonObject(
        changedDescription,
        'pointOfNoReturn',
      )['description'] = 'A different recovery boundary.';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(changedDescription),
        throwsArgumentError,
      );
    });

    test('rejects altered rollback conditions', () {
      final changedConditions = _receiptJson();
      _jsonObject(
        changedConditions,
        'rollbackPlan',
      )['conditions'] = ['Revision checks are optional.'];

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(changedConditions),
        throwsArgumentError,
      );
    });

    test('does not expose mutable receipt collections', () {
      final receipt = _receipt();
      expect(
        () => receipt.cohortIds.add('lsc_${'f' * 64}'),
        throwsUnsupportedError,
      );
      expect(
        () => receipt.snapshot.mapHashes['map_b'] = _hash('b'),
        throwsUnsupportedError,
      );
      expect(
        () => receipt.backupPlan.futureDestinations['manifest'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects a dishonest proposal lifecycle or foreign claim receipt', () {
      final committedProposal = _receipt().toJson();
      committedProposal['lifecycle'] = {
        'status': 'committed',
        'preparedAt': '2026-07-11T10:00:00.000Z',
        'committedAt': '2026-07-11T10:01:00.000Z',
      };
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(committedProposal),
        throwsArgumentError,
      );

      final foreignReceipt = _receipt().toJson();
      foreignReceipt['receiptId'] = 'evmr_foreign';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignReceipt),
        throwsArgumentError,
      );
    });

    test('rejects a foreign cohort and duplicate receipt identities', () {
      final foreignCohort = _receiptJson();
      (foreignCohort['cohortIds']! as List<Object?>).add('lsc_${'f' * 64}');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignCohort),
        throwsArgumentError,
      );

      final duplicateCohortId = _receiptJson();
      final cohortIds = duplicateCohortId['cohortIds']! as List<Object?>;
      cohortIds.add(cohortIds.single);
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateCohortId),
        throwsArgumentError,
      );

      final duplicateRecordId = _receiptJson();
      final targetRecords =
          duplicateRecordId['targetRecords']! as List<Object?>;
      targetRecords.add(_deepCopyJson(targetRecords.single));
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateRecordId),
        throwsArgumentError,
      );

      final duplicateClaimCohort = _receiptJson();
      final targetClaims =
          duplicateClaimCohort['targetClaims']! as List<Object?>;
      targetClaims.add(_deepCopyJson(targetClaims.single));
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateClaimCohort),
        throwsArgumentError,
      );

      final unclaimedRecord = _receiptJson();
      final unclaimedTargetRecords =
          unclaimedRecord['targetRecords']! as List<Object?>;
      final extra =
          _deepCopyJson(unclaimedTargetRecords.single) as Map<String, Object?>;
      final definition = _jsonObject(extra, 'definition');
      definition['id'] = 'evt_018f0000-0000-7000-8000-000000000003';
      unclaimedTargetRecords.add(extra);
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(unclaimedRecord),
        throwsArgumentError,
      );

      final emptyReceipt = _receiptJson();
      emptyReceipt['cohortIds'] = <Object?>[];
      emptyReceipt['targetClaims'] = <Object?>[];
      emptyReceipt['targetRecords'] = <Object?>[];
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(emptyReceipt),
        throwsArgumentError,
      );
    });

    test('rejects enabled targets in a preparation-only receipt', () {
      final enabledTarget = _receiptJson();
      final targetRecords = enabledTarget['targetRecords']! as List<Object?>;
      final targetRecord = targetRecords.single as Map<String, Object?>;
      targetRecord['enabled'] = true;

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(enabledTarget),
        throwsArgumentError,
      );
    });

    test('rejects non-final reference mappings in a prepared receipt', () {
      final unresolved = _receiptJson();
      final mappings = _jsonObject(unresolved, 'mappings');
      final progression = mappings['progression']! as List<Object?>;
      final mapping = progression.single as Map<String, Object?>;
      mapping['status'] = 'requiresChoice';
      mapping['targetEventIds'] = <Object?>[];
      mapping['decision'] = 'selectedTargets';

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(unresolved),
        throwsArgumentError,
      );
    });
  });
}

NarrativeEventMigrationReceipt _receipt() {
  final provenance = LegacySourceRef.mapEvent('map_a', 'legacy_a');
  final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
  const eventId = 'evt_018f0000-0000-7000-8000-000000000001';
  const receiptId = 'evmr_018f0000-0000-7000-8000-000000000002';
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _hash('c'),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [eventId],
    migrationReceiptId: receiptId,
  );
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: eventId,
      name: 'Legacy A',
      source: source,
      conditions: [NarrativeEventCondition.fact('fact_a', true)],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  final mappings = NarrativeEventReferenceMappings(
    idMappings: [
      NarrativeEventIdMapping(
        provenance: provenance,
        legacyId: 'legacy_a',
        targetEventIds: const [eventId],
      ),
    ],
    pageMappings: [
      NarrativeEventPageMapping(
        provenance: provenance,
        pageIndex: 0,
        pageNumber: 1,
        status: NarrativeEventPageMappingStatus.mapped,
        targetEventId: eventId,
        sceneId: 'scene_a',
        preservedPageJson: const {'pageNumber': 1},
      ),
    ],
    progressionMappings: [
      NarrativeEventReferenceMapping(
        domain: NarrativeEventReferenceDomain.progression,
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'legacy_a',
        candidateProvenances: [provenance],
        targetEventIds: const [eventId],
        status: NarrativeEventReferenceMappingStatus.mapped,
      ),
    ],
  );

  return NarrativeEventMigrationReceipt(
    receiptId: receiptId,
    isProposal: true,
    snapshot: _snapshot(
      legacySourceHashes: {
        legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
      },
    ),
    expectedManifestHashAfter: _hash('1'),
    expectedRegistryHashAfter: _hash('2'),
    lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(
      DateTime.utc(2026, 7, 11, 10),
    ),
    cohortIds: [cohortId],
    mappings: mappings,
    targetRecords: [record],
    targetClaims: [claim],
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-c/project.json',
        'receipt': 'backups/phase-c/receipt.json',
      },
    ),
    writePreconditions: NarrativeEventMigrationWritePreconditions(
      snapshot: _snapshot(
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
        },
      ),
    ),
    atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
    rollbackPlan: NarrativeEventMigrationRollbackPlan.phaseCProposal(),
    pointOfNoReturn: NarrativeEventMigrationPointOfNoReturn.phaseCProposal(),
  );
}

NarrativeEventMigrationSnapshot _snapshot({
  String projectRevisionToken = 'revision-1',
  Map<String, String> legacySourceHashes = const {},
}) {
  return NarrativeEventMigrationSnapshot(
    projectRevisionToken: projectRevisionToken,
    manifestHash: _hash('a'),
    corpusHash: _hash('d'),
    referenceCatalogHash: _hash('e'),
    mapHashes: {'map_a': _hash('b')},
    legacySourceHashes: legacySourceHashes,
    saveHashes: {'save_a': _hash('f')},
  );
}

String _hash(String character) => 'sha256:${character * 64}';

Map<String, Object?> _receiptJson() {
  return _deepCopyJson(_receipt().toJson()) as Map<String, Object?>;
}

Map<String, Object?> _jsonObject(
  Map<String, Object?> json,
  String key,
) {
  return json[key]! as Map<String, Object?>;
}

Object? _deepCopyJson(Object? value) => jsonDecode(jsonEncode(value));

const _receiptGolden =
    r'{"atomicityPlan":{"claimsMultiFileAtomicity":false,"crashRecoveryUsesJournal":true,"journalStates":["prepared","committed","recovered"],"legacyMapsRemainUnchanged":true,"manifestStagingRequired":true,"unitRenameOnly":true},'
    r'"backupPlan":{"createBeforeCommit":true,"futureDestinations":{"manifest":"backups/phase-c/project.json","receipt":"backups/phase-c/receipt.json"},"noBackupCreatedInPhaseC":true},'
    r'"cohortIds":["lsc_12536fa79346f0d0d0b4a2b8128859cdb911e05763077c6680b1badd122ffb2a"],'
    r'"expectedManifestHashAfter":"sha256:1111111111111111111111111111111111111111111111111111111111111111",'
    r'"expectedRegistryHashAfter":"sha256:2222222222222222222222222222222222222222222222222222222222222222",'
    r'"isProposal":true,'
    r'"lifecycle":{"preparedAt":"2026-07-11T10:00:00.000Z","status":"prepared"},'
    r'"mappings":{"conditions":[],"consequences":[],"ids":[{"legacyId":"legacy_a","provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],'
    r'"pages":[{"pageIndex":0,"pageNumber":1,"preservedPageJson":{"pageNumber":1},"provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"sceneId":"scene_a","status":"mapped","targetEventId":"evt_018f0000-0000-7000-8000-000000000001"}],'
    r'"progression":[{"candidateProvenances":[{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"}],"domain":"progression","kind":"consumedEventState","legacyEventId":"legacy_a","path":"gameStates.save_a.consumedEventIds[0]","status":"mapped","targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],"saves":[],"worldRules":[]},'
    r'"phase":"NS-EVENT-V2-PHASE-C",'
    r'"pointOfNoReturn":{"compensatingMigrationRequiredAfter":true,"description":"Rollback stops being lossless after the first persisted V2-only progression bit or reference that cannot be represented exactly in legacy storage.","reached":false,"trigger":"firstPersistedV2OnlyProgressOrReferenceNotExactlyRepresentableInLegacy"},'
    r'"receiptId":"evmr_018f0000-0000-7000-8000-000000000002",'
    r'"rollbackPlan":{"availableAfterPointOfNoReturn":false,"availableBeforePointOfNoReturn":true,"compensatingMigrationRequiredAfter":true,"conditions":["The project revision token is unchanged.","Manifest, map, and legacy source hashes still match the receipt.","The future backup was created before commit.","No V2-only progression or reference has crossed the point of no return."],"requiresMatchingHashes":true,"requiresUnchangedRevision":true},'
    r'"schemaVersion":1,'
    r'"snapshot":{"corpusHash":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","legacySourceHashes":{"legacySource:{\"eventId\":\"legacy_a\",\"kind\":\"mapEvent\",\"mapId\":\"map_a\"}":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"manifestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","mapHashes":{"map_a":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"projectRevisionToken":"revision-1","referenceCatalogHash":"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","saveHashes":{"save_a":"sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"}},'
    r'"targetClaims":[{"cohortFingerprint":"sha256:8ed85ba1d8ea0549a2b2f20de4de94429b267d7267593c054684ccf175366006","cohortId":"lsc_12536fa79346f0d0d0b4a2b8128859cdb911e05763077c6680b1badd122ffb2a","members":[{"provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"sourceFingerprint":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}],"migrationReceiptId":"evmr_018f0000-0000-7000-8000-000000000002","source":{"entityId":"npc_a","kind":"entityInteract","mapId":"map_a"},"targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],'
    r'"targetRecords":[{"definition":{"conditions":[{"expectedValue":true,"factId":"fact_a","kind":"fact"}],"id":"evt_018f0000-0000-7000-8000-000000000001","name":"Legacy A","order":0,"priority":0,"reusePolicy":"oneShot","sceneId":"scene_a","source":{"entityId":"npc_a","kind":"entityInteract","mapId":"map_a"}},"enabled":false,"state":"configured"}],'
    r'"writePreconditions":{"requireNoClaimConflicts":true,"requireProjectWritable":true,"requireRegistryMigrationAllowed":true,"snapshot":{"corpusHash":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","legacySourceHashes":{"legacySource:{\"eventId\":\"legacy_a\",\"kind\":\"mapEvent\",\"mapId\":\"map_a\"}":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"manifestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","mapHashes":{"map_a":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"projectRevisionToken":"revision-1","referenceCatalogHash":"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","saveHashes":{"save_a":"sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"}}}}';
````

</details>

### `packages/map_core/test/narrative_event_reference_mapping_test.dart`

SHA-256: `38180be510984e55de26ed406e1099d81c88951cee448e8ffcca8a3a7e695e9e` — 292 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 reference mapping', () {
    final provenanceA = LegacySourceRef.mapEvent('map_a', 'shared');
    final provenanceB = LegacySourceRef.mapEvent('map_b', 'shared');
    final targets = <LegacySourceRef, List<String>>{
      provenanceA: const ['evt_018f0000-0000-7000-8000-000000000001'],
      provenanceB: const ['evt_018f0000-0000-7000-8000-000000000002'],
    };

    test('rejects reference kinds placed in the wrong catalog domain', () {
      final worldRule = _reference(
        kind: LegacyEventReferenceKind.worldRuleSource,
        path: 'worldRules.rule_a.source',
        candidates: [provenanceA],
      );

      expect(
        () => NarrativeEventReferenceCatalog(progression: [worldRule]),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventReferenceCatalog(worldRules: [worldRule]),
        returnsNormally,
      );
    });

    test('blocks ambiguous consumedEventIds until an explicit choice exists',
        () {
      final reference = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        candidates: [provenanceA, provenanceB],
      );

      final unresolved = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
      );
      expect(unresolved.hasBlockingMappings, isTrue);
      expect(
        unresolved.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );
      expect(unresolved.progressionMappings.single.targetEventIds, isEmpty);

      final consumeAll = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision:
                NarrativeEventReferenceCollisionDecision.consumeAllTargets,
          ),
        ],
      );
      expect(consumeAll.hasBlockingMappings, isFalse);
      expect(
        consumeAll.progressionMappings.single.targetEventIds,
        [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000002',
        ],
      );

      final selected = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision: NarrativeEventReferenceCollisionDecision.selectedTargets,
            selectedTargetEventIds: const [
              'evt_018f0000-0000-7000-8000-000000000002',
            ],
          ),
        ],
      );
      expect(
        selected.progressionMappings.single.targetEventIds,
        ['evt_018f0000-0000-7000-8000-000000000002'],
      );

      final cancelled = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision: NarrativeEventReferenceCollisionDecision.cancel,
          ),
        ],
      );
      expect(
        cancelled.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.cancelled,
      );

      final duplicateChoice = NarrativeEventReferenceResolutionChoice(
        path: reference.path,
        decision: NarrativeEventReferenceCollisionDecision.consumeAllTargets,
      );
      expect(
        () => buildNarrativeEventReferenceMappings(
          targetEventIdsByProvenance: targets,
          references: NarrativeEventReferenceCatalog(
            progression: [reference],
          ),
          choices: [duplicateChoice, duplicateChoice],
        ),
        throwsArgumentError,
      );
    });

    test('requires a choice before one provenance fans out to many Events', () {
      final reference = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[1]',
        candidates: [provenanceA],
      );
      final fanOutTargets = <LegacySourceRef, List<String>>{
        provenanceA: const [
          'evt_018f0000-0000-7000-8000-000000000001',
          'evt_018f0000-0000-7000-8000-000000000003',
        ],
      };

      final unresolved = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: fanOutTargets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
      );
      expect(
        unresolved.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.requiresChoice,
      );

      final explicit = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: fanOutTargets,
        references: NarrativeEventReferenceCatalog(
          progression: [reference],
        ),
        choices: [
          NarrativeEventReferenceResolutionChoice(
            path: reference.path,
            decision:
                NarrativeEventReferenceCollisionDecision.consumeAllTargets,
          ),
        ],
      );
      expect(
        explicit.progressionMappings.single.status,
        NarrativeEventReferenceMappingStatus.mapped,
      );
      expect(explicit.progressionMappings.single.targetEventIds, hasLength(2));
    });

    test('maps condition, World Rule, consequence, and save references', () {
      LegacyEventReference unique(LegacyEventReferenceKind kind, String path) {
        return _reference(kind: kind, path: path, candidates: [provenanceA]);
      }

      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(
          conditions: [
            unique(
              LegacyEventReferenceKind.scriptCondition,
              'maps.map_a.events.shared.pages[0].condition',
            ),
          ],
          worldRules: [
            unique(
              LegacyEventReferenceKind.worldRuleSource,
              'worldRules.rule_a.source',
            ),
          ],
          consequences: [
            unique(
              LegacyEventReferenceKind.sceneConsequence,
              'scenes.scene_a.consequences[0]',
            ),
          ],
          saves: [
            unique(
              LegacyEventReferenceKind.consumedEventState,
              'saves.save_a.consumedEventIds[0]',
            ),
          ],
        ),
      );

      for (final mapping in [
        mappings.conditionMappings.single,
        mappings.worldRuleMappings.single,
        mappings.consequenceMappings.single,
        mappings.saveMappings.single,
      ]) {
        expect(mapping.status, NarrativeEventReferenceMappingStatus.mapped);
        expect(
          mapping.targetEventIds,
          ['evt_018f0000-0000-7000-8000-000000000001'],
        );
      }
    });

    test('preserves unknown progression and save IDs as tombstones', () {
      final unknownSave = _reference(
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'saves.save_a.consumedEventIds[0]',
        candidates: const [],
      );
      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targets,
        references: NarrativeEventReferenceCatalog(saves: [unknownSave]),
      );

      expect(mappings.hasBlockingMappings, isFalse);
      expect(
        mappings.saveMappings.single.status,
        NarrativeEventReferenceMappingStatus.preservedTombstone,
      );
      expect(mappings.saveMappings.single.legacyEventId, 'shared');
    });

    test('keeps ID, page, and reference mappings deeply immutable', () {
      final ids = NarrativeEventIdMapping(
        provenance: provenanceA,
        legacyId: 'shared',
        targetEventIds: targets[provenanceA]!,
      );
      final page = NarrativeEventPageMapping(
        provenance: provenanceA,
        pageIndex: 0,
        pageNumber: 1,
        status: NarrativeEventPageMappingStatus.preservedLegacy,
        preservedPageJson: {
          'metadata': {
            'future': ['kept'],
          },
        },
      );
      final mappings = NarrativeEventReferenceMappings(
        idMappings: [ids],
        pageMappings: [page],
      );

      expect(
        () => mappings.idMappings.add(ids),
        throwsUnsupportedError,
      );
      expect(
        () => page.preservedPageJson['new'] = true,
        throwsUnsupportedError,
      );
      final metadata = page.preservedPageJson['metadata']! as Map;
      expect(() => metadata['future'] = const [], throwsUnsupportedError);
      final future = metadata['future']! as List;
      expect(() => future.add('lost'), throwsUnsupportedError);

      final roundTrip = NarrativeEventReferenceMappings.fromJson(
        mappings.toJson(),
      );
      expect(roundTrip.toJson(), mappings.toJson());
    });
  });
}

LegacyEventReference _reference({
  required LegacyEventReferenceKind kind,
  required String path,
  required List<LegacySourceRef> candidates,
}) {
  return LegacyEventReference(
    kind: kind,
    path: path,
    legacyEventId: 'shared',
    candidateProvenances: candidates,
  );
}
````

</details>

### `packages/map_core/tool/verify_narrative_event_jcs_number_oracle.dart`

SHA-256: `c578a01c2ad418cef0436875979e444cbce38d0a6c1aac31a7732c3b25e175a2` — 65 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

const _expectedLineCount = 200000;
const _expectedChecksum =
    'b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57';

Future<void> main() async {
  final oracle = Platform.script.resolve(
    'verify_narrative_event_jcs_number_oracle.mjs',
  );
  final process = await Process.start(
    'node',
    [oracle.toFilePath(), '$_expectedLineCount'],
  );
  var count = 0;
  String? checksum;
  await for (final line in process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    if (line.startsWith('#sha256,')) {
      checksum = line.substring('#sha256,'.length);
      continue;
    }
    final separator = line.indexOf(',');
    if (separator <= 0) {
      throw FormatException('Malformed oracle line $count.');
    }
    final hex = line.substring(0, separator);
    final expected = line.substring(separator + 1);
    final actual = canonicalizeNarrativeEventJson(_doubleFromHex(hex));
    if (actual != expected) {
      throw StateError(
        'Number mismatch at line $count: $hex expected $expected got $actual',
      );
    }
    count++;
  }
  final stderr = await process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException('node', const [], stderr, exitCode);
  }
  if (count != _expectedLineCount || checksum != _expectedChecksum) {
    throw StateError(
      'Oracle summary mismatch: lines=$count checksum=$checksum stderr=$stderr',
    );
  }
  stdout.writeln(
    'Verified $count deterministic IEEE-754 values against Node; '
    'checksum $checksum.',
  );
}

double _doubleFromHex(String hex) {
  final bits = BigInt.parse(hex, radix: 16);
  final data = ByteData(8)
    ..setUint32(0, (bits & BigInt.from(0xffffffff)).toInt(), Endian.little)
    ..setUint32(4, (bits >> 32).toInt(), Endian.little);
  return data.getFloat64(0, Endian.little);
}
````

</details>

### `packages/map_core/tool/verify_narrative_event_jcs_number_oracle.mjs`

SHA-256: `bf8faacb2f27d5ad58c61a20df9426b5067e49f15cf89bb8b834c1ad990b68e5` — 93 lignes.

<details>
<summary>Contenu complet</summary>

````javascript
// Derived from cyberphone/json-canonicalization testdata/numgen.js at
// 19d51d7fe467d4706a3ff08adf8a748f29fc21e0 (Apache License 2.0).
import { createHash } from 'node:crypto';

const lineCount = Number.parseInt(process.argv[2] ?? '200000', 10);
if (!Number.isSafeInteger(lineCount) || lineCount < 1) {
  throw new Error('line count must be a positive safe integer');
}

const staticHex = `
0000000000000000 8000000000000000 0000000000000001 8000000000000001
c46696695dbd1cc3 c43211ede4974a35 c3fce97ca0f21056 c3c7213080c1a6ac
c39280f39a348556 c35d9b1f5d20d557 c327af4c4a80aaac c2f2f2a36ecd5556
c2be51057e155558 c28840d131aaaaac c253670dc1555557 c21f0b4935555557
c1e8d5d42aaaaaac c1b3de4355555556 c17fca0555555556 c1496e6aaaaaaaab
c114585555555555 c0e046aaaaaaaaab c0aa0aaaaaaaaaa c074d55555555555
c040aaaaaaaaaaab c00aaaaaaaaaaaab bfd5555555555555 bfa1111111111111
bf6b4e81b4e81b4f bf35d867c3ece2a5 bf0179ec9cbd821e becbf647612f3696
be965e9f80f29212 be61e54c672874db be2ca213d840baf8 bdf6e80fe033c8c6
bdc2533fe68fd3d2 bd8d51ffd74c861c bd5774ccac3d3817 bd22c3d6f030f9ac
bcee0624b3818f79 bcb804ea293472c7 bc833721ba905bd3 bc4ebe9c5db3c61e
bc18987d17c304e5 bbe3ad30dfcf371d bbaf7b816618582f bb792f9ab81379bf
bb442615600f9499 bb101e77800c76e1 bad9ca58cce0be35 baa4a1e0a3e6fe90
ba708180831f320d ba3a68cd9e985016 446696695dbd1cc3 443211ede4974a35
43fce97ca0f21056 43c7213080c1a6ac 439280f39a348556 435d9b1f5d20d557
4327af4c4a80aaac 42f2f2a36ecd5556 42be51057e155558 428840d131aaaaac
4253670dc1555557 421f0b4935555557 41e8d5d42aaaaaac 41b3de4355555556
417fca0555555556 41496e6aaaaaaaab 4114585555555555 40e046aaaaaaaaab
40aa0aaaaaaaaaa 4074d55555555555 4040aaaaaaaaaaab 400aaaaaaaaaaaab
3fd5555555555555 3fa1111111111111 3f6b4e81b4e81b4f 3f35d867c3ece2a5
3f0179ec9cbd821e 3ecbf647612f3696 3e965e9f80f29212 3e61e54c672874db
3e2ca213d840baf8 3df6e80fe033c8c6 3dc2533fe68fd3d2 3d8d51ffd74c861c
3d5774ccac3d3817 3d22c3d6f030f9ac 3cee0624b3818f79 3cb804ea293472c7
3c833721ba905bd3 3c4ebe9c5db3c61e 3c18987d17c304e5 3be3ad30dfcf371d
3baf7b816618582f 3b792f9ab81379bf 3b442615600f9499 3b101e77800c76e1
3ad9ca58cce0be35 3aa4a1e0a3e6fe90 3a708180831f320d 3a3a68cd9e985016
4024000000000000 4014000000000000 3fe0000000000000 3fa999999999999a
3f747ae147ae147b 3f40624dd2f1a9fc 3f0a36e2eb1c432d 3ed4f8b588e368f1
3ea0c6f7a0b5ed8d 3e6ad7f29abcaf48 3e35798ee2308c3a 3ed539223589fa95
3ed4ff26cd5a7781 3ed4f95a762283ff 3ed4f8c60703520c 3ed4f8b72f19cd0d
3ed4f8b5b31c0c8d 3ed4f8b58d1c461a 3ed4f8b5894f7f0e 3ed4f8b588ee37f3
3ed4f8b588e47da4 3ed4f8b588e3849c 3ed4f8b588e36bb5 3ed4f8b588e36937
3ed4f8b588e368f8 3ed4f8b588e368f1 3ff0000000000000 bff0000000000000
bfeffffffffffffa bfeffffffffffffb 3feffffffffffffa 3feffffffffffffb
3feffffffffffffc 3feffffffffffffe bfefffffffffffff bfefffffffffffff
3fefffffffffffff 3fefffffffffffff 3fd3333333333332 3fd3333333333333
3fd3333333333334 0010000000000000 000ffffffffffffd 000fffffffffffff
7fefffffffffffff ffefffffffffffff 4340000000000000 c340000000000000
4430000000000000 44b52d02c7e14af5 44b52d02c7e14af6 44b52d02c7e14af7
444b1ae4d6e2ef4e 444b1ae4d6e2ef4f 444b1ae4d6e2ef50 3eb0c6f7a0b5ed8c
3eb0c6f7a0b5ed8d 41b3de4355555553 41b3de4355555554 41b3de4355555555
41b3de4355555556 41b3de4355555557 becbf647612f3696 43143ff3c1cb0959
`.trim().split(/\s+/).map((value) => BigInt(`0x${value}`));

let index = 0;
let block = Buffer.alloc(32);
let randomOffset = block.length;

function bitsToDouble(bits) {
  const buffer = Buffer.allocUnsafe(8);
  buffer.writeBigUInt64LE(bits);
  return buffer.readDoubleLE();
}

function nextBits() {
  if (index < staticHex.length) return staticHex[index++];
  if (index < staticHex.length + 2000) {
    return 0x0010000000000000n + BigInt(index++ - staticHex.length);
  }
  while (true) {
    if (randomOffset >= block.length) {
      block = createHash('sha256').update(block).digest();
      randomOffset = 0;
    }
    const bits = block.readBigUInt64LE(randomOffset);
    randomOffset += 8;
    const value = bitsToDouble(bits);
    if (value !== 0 && Number.isFinite(value)) {
      index++;
      return bits;
    }
  }
}

const hash = createHash('sha256');
for (let line = 0; line < lineCount; line++) {
  const bits = nextBits();
  const value = bitsToDouble(bits);
  const output = `${bits.toString(16)},${JSON.stringify(value)}\n`;
  hash.update(output);
  process.stdout.write(output);
}
process.stdout.write(`#sha256,${hash.digest('hex')}\n`);
````

</details>

### `packages/map_core/tool/verify_narrative_event_jcs_vectors.dart`

SHA-256: `d823dd3c9773b72346dc33610a9b55c4d07cfb2760450c9bee7ee87b504a7bdd` — 232 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

void main() {
  final fixture = File.fromUri(
    Platform.script.resolve(
      '../test/fixtures/narrative_event_jcs/vectors.json',
    ),
  );
  final root = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  final failures = <String>[];
  const expectedSections = {
    'schemaVersion',
    'canonicalCases',
    'officialCorpus',
    'numberCases',
    'rejectedNumberCases',
    'invalidRawCases',
    'phaseBHashes',
    'claimCases',
  };
  if (root.keys.toSet().difference(expectedSections).isNotEmpty ||
      expectedSections.difference(root.keys.toSet()).isNotEmpty) {
    failures.add('Fixture sections do not match the version 1 schema.');
  }
  if (root['schemaVersion'] != 1) {
    failures.add('Unsupported fixture schema version.');
  }
  final ids = <String>{};

  void register(Map<String, dynamic> vector) {
    final id = vector['id'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      failures.add('Every vector must have a unique non-empty id: $id');
    }
    final provenance = vector['provenance'];
    if (provenance is! String || provenance.isEmpty) {
      failures.add('$id: missing provenance');
    }
  }

  for (final value in root['canonicalCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final canonical = canonicalizeNarrativeEventJson(vector['input']);
    final digest = narrativeEventCanonicalSha256(vector['input']);
    if (canonical != vector['canonical']) {
      failures.add('${vector['id']}: canonical output mismatch');
    }
    if (digest != vector['sha256']) {
      failures.add('${vector['id']}: SHA-256 mismatch');
    }
  }

  final corpus = root['officialCorpus'] as Map<String, dynamic>;
  if ((corpus['upstreamCommit'] as String?)?.length != 40 ||
      (corpus['provenance'] as String?)?.isEmpty != false) {
    failures.add('Official corpus provenance is incomplete.');
  }
  for (final caseName in corpus['cases'] as List<dynamic>) {
    final input = File.fromUri(
      fixture.uri.resolve('official/input/$caseName.json'),
    ).readAsStringSync();
    final expectedHex = File.fromUri(
      fixture.uri.resolve('official/outhex/$caseName.txt'),
    ).readAsStringSync().trim();
    final expectedBytes = expectedHex
        .split(RegExp(r'\s+'))
        .map((value) => int.parse(value, radix: 16))
        .toList();
    try {
      final actual = canonicalizeNarrativeEventJsonUtf8(
        decodeNarrativeEventJsonStrict(input),
      );
      if (!_listEquals(actual, expectedBytes)) {
        failures.add('$caseName: official corpus output mismatch');
      }
    } on Object catch (error) {
      failures.add('$caseName: official corpus failed: $error');
    }
  }

  for (final value in root['numberCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    final number = _doubleFromIeee754Hex(vector['ieee754Hex'] as String);
    if (canonicalizeNarrativeEventJson(number) != vector['canonical']) {
      failures.add('${vector['ieee754Hex']}: number output mismatch');
    }
    if (narrativeEventCanonicalSha256(number) != vector['sha256']) {
      failures.add('${vector['ieee754Hex']}: number SHA-256 mismatch');
    }
  }
  for (final value in root['rejectedNumberCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    final number = _doubleFromIeee754Hex(vector['ieee754Hex'] as String);
    if (!_throwsFormatException(
      () => canonicalizeNarrativeEventJson(number),
    )) {
      failures.add('${vector['ieee754Hex']}: forbidden number was accepted');
    }
  }

  for (final value in root['invalidRawCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final rawJson = vector['rawJson'] as String;
    switch (vector['operation']) {
      case 'canonicalizeDecoded':
        if (!_throwsFormatException(
          () => canonicalizeNarrativeEventJson(jsonDecode(rawJson)),
        )) {
          failures.add('${vector['id']}: invalid decoded value was accepted');
        }
      case 'canonicalizeText':
        if (!_throwsFormatException(
          () => canonicalizeNarrativeEventJsonText(rawJson),
        )) {
          failures.add('${vector['id']}: duplicate raw key was accepted');
        }
      case 'preflightProject':
        final expected = vector['expectedDiagnosticContains'] as String;
        final result = preflightProjectManifestJson(utf8.encode(rawJson));
        final rejected = result.eventRegistry.when(
          absent: () => false,
          decoded: (_) => false,
          unsupported: (_, __) => false,
          invalid: (_, diagnostics) =>
              diagnostics.any((message) => message.contains(expected)),
        );
        if (!rejected) {
          failures.add('${vector['id']}: project duplicate was accepted');
        }
      default:
        failures.add('${vector['id']}: unknown invalid operation');
    }
  }

  for (final value in root['phaseBHashes'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final preimage = vector['preimage'] as String;
    final decoded = jsonDecode(preimage);
    if (canonicalizeNarrativeEventJson(decoded) != preimage) {
      failures.add('${vector['id']}: preimage is not canonical');
    }
    if (narrativeEventCanonicalSha256(decoded) != vector['sha256']) {
      failures.add('${vector['id']}: Phase B SHA-256 mismatch');
    }
  }

  for (final value in root['claimCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final source = NarrativeEventSourceRef.fromJson(vector['source']);
    final provenances = (vector['provenances'] as List<dynamic>)
        .map(LegacySourceRef.fromJson)
        .toList()
      ..sort(compareLegacySourceRefs);
    final members = (vector['members'] as List<dynamic>)
        .map(LegacySourceClaimMember.fromJson)
        .toList()
      ..sort((left, right) {
        final provenance = compareLegacySourceRefs(
          left.provenance,
          right.provenance,
        );
        if (provenance != 0) return provenance;
        return compareNarrativeEventUtf16(
          left.sourceFingerprint,
          right.sourceFingerprint,
        );
      });
    final cohortPreimage = canonicalizeNarrativeEventJson({
      'source': source.toJson(),
      'provenances': [
        for (final provenance in provenances) provenance.toJson(),
      ],
    });
    final cohortId = computeLegacySourceCohortId(source, provenances);
    final fingerprintPreimage = canonicalizeNarrativeEventJson({
      'cohortId': cohortId,
      'members': [for (final member in members) member.toJson()],
    });
    if (cohortPreimage != vector['cohortPreimage'] ||
        cohortId != vector['cohortId'] ||
        fingerprintPreimage != vector['fingerprintPreimage'] ||
        computeLegacySourceCohortFingerprint(cohortId, members) !=
            vector['cohortFingerprint']) {
      failures.add('${vector['id']}: claim golden mismatch');
    }
  }

  if (failures.isNotEmpty) {
    throw StateError(failures.join('\n'));
  }
  stdout.writeln(
    'Verified ${(root['canonicalCases'] as List).length} canonical vectors '
    '${(corpus['cases'] as List).length} official corpus pairs, '
    '${(root['numberCases'] as List).length} number vectors, '
    '${(root['invalidRawCases'] as List).length} rejection vectors, '
    '${(root['phaseBHashes'] as List).length} Phase B hashes, and '
    '${(root['claimCases'] as List).length} claim vectors.',
  );
}

bool _throwsFormatException(Object? Function() callback) {
  try {
    callback();
    return false;
  } on FormatException {
    return true;
  }
}

bool _listEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

double _doubleFromIeee754Hex(String hex) {
  final bits = BigInt.parse(hex, radix: 16);
  final data = ByteData(8)
    ..setUint32(0, (bits >> 32).toInt(), Endian.big)
    ..setUint32(4, (bits & BigInt.from(0xffffffff)).toInt(), Endian.big);
  return data.getFloat64(0, Endian.big);
}
````

</details>

### `packages/map_editor/test/scenario_authoring_claim_guard_test.dart`

SHA-256: `f155443fe0c09b441709c5fa591b2d210807b95246289a9e89a3e846539d9638` — 384 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_scenario_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

const _guardMessage = 'Cette source est gérée par Event Builder V2. '
    'Ouvrez les événements liés ou retirez explicitement la migration.';

void main() {
  group('NS-EVENT-V2 Phase C3 Scenario authoring claim guard', () {
    test('unclaimed Scenario keeps its existing update behavior', () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'unclaimed');
      final project = _project(scenarios: [scenario]);

      final updated = await UpdateProjectScenarioUseCase(repository).execute(
        const _FakeWorkspace(),
        project,
        scenarioId: scenario.id,
        nextScenario: scenario.copyWith(name: 'Unclaimed updated'),
      );

      expect(updated.scenarios.single.name, 'Unclaimed updated');
      expect(repository.saveCalls, 1);
    });

    test('valid claim freezes sibling edit, binding change, rename, and delete',
        () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'claimed');
      final project = _project(
        scenarios: [scenario],
        eventRegistry: _registryFor(scenario),
      );
      final update = UpdateProjectScenarioUseCase(repository);
      final siblingEdit = scenario.copyWith(
        nodes: [
          for (final node in scenario.nodes)
            if (node.id == 'start')
              node.copyWith(title: 'Edited sibling')
            else
              node,
        ],
      );
      final bindingEdit = scenario.copyWith(
        nodes: [
          for (final node in scenario.nodes)
            if (node.id == 'source')
              node.copyWith(
                binding: node.binding.copyWith(entityId: 'npc_b'),
              )
            else
              node,
        ],
      );

      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: siblingEdit,
        ),
      );
      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: bindingEdit,
        ),
      );
      await _expectGuarded(
        () => update.execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: scenario.copyWith(id: 'renamed'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
        ),
      );

      expect(project.scenarios.single, same(scenario));
      expect(repository.saveCalls, 0);
    });

    test('tombstone claim remains a freeze instead of looking absent',
        () async {
      final repository = _FakeProjectRepository();
      final scenario = _scenario(id: 'tombstone');
      final project = _project(
        scenarios: [scenario],
        eventRegistry: _registryFor(scenario, targetExists: false),
      );

      await _expectGuarded(
        () => UpdateProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
          nextScenario: scenario.copyWith(name: 'Must stay frozen'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: scenario.id,
        ),
      );

      expect(repository.saveCalls, 0);
    });

    test('new ambiguous duplicate is refused while unrelated create works',
        () async {
      final claimed = _scenario(id: 'claimed');
      final project = _project(
        scenarios: [claimed],
        eventRegistry: _registryFor(claimed),
      );
      final blockedRepository = _FakeProjectRepository();

      await _expectGuarded(
        () => CreateProjectScenarioUseCase(blockedRepository).execute(
          const _FakeWorkspace(),
          project,
          scenario: _scenario(id: 'ambiguous_duplicate'),
        ),
      );
      expect(blockedRepository.saveCalls, 0);

      final allowedRepository = _FakeProjectRepository();
      final updated =
          await CreateProjectScenarioUseCase(allowedRepository).execute(
        const _FakeWorkspace(),
        project,
        scenario: _scenario(
          id: 'unrelated',
          mapId: 'map_b',
          entityId: 'npc_b',
        ),
      );
      expect(updated.scenarios.map((value) => value.id),
          containsAll(<String>['claimed', 'unrelated']));
      expect(allowedRepository.saveCalls, 1);
    });

    test('a provenance omitted from a claimed source fails closed', () async {
      final claimed = _scenario(id: 'claimed');
      final duplicate = _scenario(id: 'existing_duplicate');
      final project = _project(
        scenarios: [claimed, duplicate],
        eventRegistry: _registryFor(claimed),
      );
      final repository = _FakeProjectRepository();

      await _expectGuarded(
        () => UpdateProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: duplicate.id,
          nextScenario: duplicate.copyWith(name: 'Must remain unchanged'),
        ),
      );
      await _expectGuarded(
        () => DeleteProjectScenarioUseCase(repository).execute(
          const _FakeWorkspace(),
          project,
          scenarioId: duplicate.id,
        ),
      );

      expect(repository.saveCalls, 0);
    });
  });
}

Future<void> _expectGuarded(Future<Object?> Function() action) async {
  await expectLater(
    action,
    throwsA(
      isA<EditorInvalidOperationException>().having(
        (error) => error.message,
        'message',
        _guardMessage,
      ),
    ),
  );
}

ScenarioAsset _scenario({
  required String id,
  String mapId = 'map_a',
  String entityId = 'npc_a',
}) {
  return ScenarioAsset(
    id: id,
    name: id,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    nodes: [
      const ScenarioNode(id: 'start', type: ScenarioNodeType.start),
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: 'sourceEntityInteract',
        ),
        binding: ScenarioNodeBinding(mapId: mapId, entityId: entityId),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const [
      ScenarioEdge(id: 'start-source', fromNodeId: 'start', toNodeId: 'source'),
      ScenarioEdge(id: 'source-end', fromNodeId: 'source', toNodeId: 'end'),
    ],
  );
}

ProjectManifest _project({
  required List<ScenarioAsset> scenarios,
  NarrativeEventRegistry? eventRegistry,
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Phase C3',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
      ProjectMapEntry(
        id: 'map_b',
        name: 'Map B',
        relativePath: 'maps/map_b.json',
      ),
    ],
    tilesets: const [],
    scenarios: scenarios,
    eventRegistry: eventRegistry,
  );
}

NarrativeEventRegistry _registryFor(
  ScenarioAsset scenario, {
  bool targetExists = true,
}) {
  final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: 'source',
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const eventId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: targetExists
        ? [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: eventId,
                name: 'Claim target',
                source: source,
                conditions: const [],
                sceneId: 'scene_target',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: false,
            ),
          ]
        : const [],
    legacyClaims: [
      LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          [member],
        ),
        targetEventIds: const [eventId],
        migrationReceiptId: 'receipt_c3',
      ),
    ],
  );
}

final class _FakeProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls++;
  }
}

final class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      '/tmp/tilesets/image.png';

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}
````

</details>

### `packages/map_runtime/test/narrative_event_legacy_runtime_characterization_test.dart`

SHA-256: `df68f3230b1b995cf45f60e68b7d433824c48b631b95c06b1a49fb91bfab1e3d` — 187 lignes.

<details>
<summary>Contenu complet</summary>

````dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late List<MapData> maps;
  late List<ScenarioAsset> scenarios;

  setUpAll(() {
    final source = File(
      '../map_core/test/fixtures/narrative_event_legacy_corpus/corpus_v0.json',
    ).readAsStringSync();
    final fixture = Map<String, Object?>.from(
      decodeNarrativeEventJsonStrict(source)! as Map,
    );
    maps = List<Object?>.from(fixture['maps']! as List)
        .map(
          (value) => MapData.fromJson(
            Map<String, dynamic>.from(value! as Map),
          ),
        )
        .toList(growable: false);
    scenarios = List<Object?>.from(fixture['scenarios']! as List)
        .map(
          (value) => ScenarioAsset.fromJson(
            Map<String, dynamic>.from(value! as Map),
          ),
        )
        .toList(growable: false);
  });

  group('NS-EVENT-V2 Phase C1 legacy runtime characterization', () {
    test('first-valid keeps list order and ignores hidden/disabled flags', () {
      final event = maps
          .singleWhere((map) => map.id == 'c1_map_a')
          .events
          .singleWhere((candidate) => candidate.id == 'evt_page_order');
      const resolver = EventPageResolver();

      ActiveEventPage resolve(Set<String> flags) {
        return resolver.resolve(
          event,
          GameState(
            saveId: 'save_c1_pages',
            storyFlags: StoryFlags(activeFlags: flags),
          ),
        )!;
      }

      final fallback = resolve(const {});
      expect(fallback.pageIndex, 2);
      expect(fallback.page.pageNumber, 10);

      final hidden = resolve(const {'flagA'});
      expect(hidden.pageIndex, 0);
      expect(hidden.page.pageNumber, 30);
      expect(hidden.page.isHidden, isTrue);

      final disabled = resolve(const {'flagB'});
      expect(disabled.pageIndex, 1);
      expect(disabled.page.pageNumber, 20);
      expect(disabled.page.isDisabled, isTrue);

      final firstWins = resolve(const {'flagA', 'flagB'});
      expect(firstWins.pageIndex, 0);
      expect(firstWins.page.pageNumber, 30);
    });

    test('exact corpus sources each reach their single dialogue trace', () {
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_map_enter',
        source: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'c1_map_a'),
        expectedDialogueId: 'dialogue_map_enter',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_trigger_enter',
        source: ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: 'c1_map_a',
          triggerId: 'evt_trigger_script',
        ),
        expectedDialogueId: 'dialogue_trigger',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_a',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_b',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_outcome',
        source: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'victory',
        ),
        expectedDialogueId: 'dialogue_outcome',
      );
    });

    test('full corpus keeps first matching Scenario order explicit', () {
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_map_enter',
        source: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'c1_map_a'),
        expectedDialogueId: 'dialogue_map_enter',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_trigger_enter',
        source: ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: 'c1_map_a',
          triggerId: 'evt_trigger_script',
        ),
        expectedDialogueId: 'dialogue_trigger',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_entity_a',
        source: ScenarioRuntimeSourceEvent.entityInteract(
          mapId: 'c1_map_a',
          entityId: 'npc_actor',
        ),
        expectedDialogueId: 'dialogue_entity',
        useFullCorpus: true,
      );
      _expectDialogueDispatch(
        scenarios: scenarios,
        scenarioId: 'scn_outcome',
        source: ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'victory',
        ),
        expectedDialogueId: 'dialogue_outcome',
        useFullCorpus: true,
      );
    });
  });
}

void _expectDialogueDispatch({
  required List<ScenarioAsset> scenarios,
  required String scenarioId,
  required ScenarioRuntimeSourceEvent source,
  required String expectedDialogueId,
  bool useFullCorpus = false,
}) {
  final selected =
      scenarios.singleWhere((candidate) => candidate.id == scenarioId);
  final opened = <String>[];
  const executor = ScenarioRuntimeExecutor();
  final result = executor.dispatch(
    scenarios: useFullCorpus ? scenarios : [selected],
    sourceEvent: source,
    context: ScenarioRuntimeExecutionContext(
      gameState: const GameState(saveId: 'save_c1_runtime'),
      onGameStateUpdated: (_) {},
      openDialogue: (dialogueId, {startNode, runtimeSourceId}) {
        opened.add(dialogueId);
        return true;
      },
      runScript: (_, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    ),
  );
  expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
  expect(result.scenarioId, scenarioId);
  expect(result.sourceNodeId, 'source');
  expect(result.effect.type, ScenarioRuntimeEffectType.dialogue);
  expect(opened, [expectedDialogueId]);
}
````

</details>

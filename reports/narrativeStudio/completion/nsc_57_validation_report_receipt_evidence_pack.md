# NSC-57 — Rapport quatre dimensions et receipt runtime — Evidence Pack

## Résumé exécutif

NSC-57 introduit un rapport de publication neutre et versionné qui conserve séparément les statuts `pass`, `fail`, `indeterminate` et `notRun` pour structure, solvabilité narrative, atteignabilité physique et smoke runtime. Le projet n'est déclaré jouable que si les quatre dimensions sont `pass`.

Le fingerprint canonique vit dans `map_core` et cadre chaque couple `relativePath + bytes` trié avant SHA-256. L'éditeur et l'hôte appellent cette même fonction sur le snapshot projet complet. Le host exécute les suites obligatoires du profil `selbrume-release-v1`, puis écrit atomiquement le receipt ; absent, stale, mauvais profil ou suites partielles restent `notRun`.

La vraie production Selbrume a exécuté 3 tests de retry phare et 5 parcours E2E, puis publié un receipt frais `pass` avec le fingerprint `sha256:7c312f02c6b3a9e3411079bf59d6c3ddc91f59be3fe5f4f7725896ab83659bf1`.

**Verdict proposé : DONE.**

## Scope et état initial

- Lot : NSC-57, phase 5.
- État Git initial : branche `main`, HEAD `8162e652 feat(narrative): prove physical event reachability`, arbre propre.
- Frontières : contrats/fingerprint dans map_core ; preuve physique map_gameplay ; agrégation/lecture dans map_editor ; evidence runtime dans map_runtime ; exécution/écriture dans l'hôte.
- Le type historique `NarrativeValidationReport` existait déjà pour le validateur legacy. Le nouveau contrat porte donc le nom non ambigu `NarrativeMultidimensionalValidationReport` sans casser l'API historique.
- Non-objectifs : filtres, suppressions, quick fixes et export CI appartiennent à NSC-58.

## Passes locales équivalentes aux sub-agents

Les sub-agents sont interdits par le mode actif ; les passes de `codex_rule.md` ont été réalisées localement et séparément.

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — aucune dépendance editor→runtime, core→gameplay ou host→editor. |
| Implémentation | PASS — quatre statuts distincts, profile strict, hash canonique unique, sidecar atomique. |
| Tests | PASS — 7 core, 3 editor, 2 runtime, 4 host, 3 phare, 5 journey et 1 Selbrume Validator verts. |
| Build / Analyse | PASS — analyzers ciblés des quatre packages sans issue. |
| Critique finale | PASS — reçu absent/stale/partiel ne peut jamais devenir pass. |

## Inventaire complet

| Fichier | Zone et impact |
|---|---|
| `packages/map_core/lib/src/models/narrative_validation_report.dart` | Contrat multidimensionnel versionné, diagnostic et statut global. |
| `packages/map_core/lib/src/models/narrative_runtime_smoke_receipt.dart` | Receipt, profils et suites Release obligatoires. |
| `packages/map_core/lib/src/operations/narrative_project_fingerprint.dart` | SHA-256 canonique path+bytes, normalisation et rejet des doublons/escapes. |
| `packages/map_core/lib/map_core.dart` | Exports publics. |
| `packages/map_core/test/narrative_validation_report_test.dart` | Round-trip et priorité des statuts. |
| `packages/map_core/test/narrative_runtime_smoke_receipt_test.dart` | Codec et refus de suite partielle. |
| `packages/map_core/test/narrative_project_fingerprint_test.dart` | Ordre, slash, framing et sécurité des paths. |
| `packages/map_editor/pubspec.yaml` / `pubspec.lock` | Dépendance pure map_gameplay. |
| `packages/map_editor/lib/src/application/services/narrative_studio_validation_coordinator.dart` | Agrégation unique structure/narratif/physique/runtime. |
| `packages/map_editor/lib/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart` | Scan complet, lecture et freshness du sidecar. |
| `packages/map_editor/lib/src/features/narrative/state/narrative_validator_providers.dart` | Provider de publication quatre dimensions, provider historique conservé. |
| `packages/map_editor/test/narrative_studio_validation_coordinator_test.dart` | Indépendance des dimensions et refus du faux badge. |
| `packages/map_editor/test/narrative_runtime_smoke_receipt_repository_test.dart` | Manifest/maps/Yarn, absent/stale/partiel/frais. |
| `packages/map_editor/test/selbrume_narrative_validator_test.dart` | Structure pass, solver borné indéterminé et receipt réel frais. |
| `packages/map_runtime/lib/src/application/narrative_runtime_smoke_evidence.dart` | Constructeur runtime refusant les profils incomplets. |
| `packages/map_runtime/lib/map_runtime.dart` | Export de l'evidence. |
| `packages/map_runtime/test/narrative_runtime_smoke_evidence_test.dart` | Profil complet et fixture partielle. |
| `examples/playable_runtime_host/tool/verify_narrative_project.dart` | CLI de suites obligatoires, fingerprint et écriture atomique. |
| `examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_integration_test.dart` | Parité host/core et suites requises. |
| `examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_file_integration_test.dart` | Publication et crash avant rename. |
| `examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart` | Checkpoint séparant état métier/ledger interne et handoff dialogue/battle non flaky. |
| `selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json` | Reçu Release frais du snapshot canonique. |
| `docs/superpowers/plans/2026-07-20-nsc-57-validation-report-receipt.md` | Micro-plan TDD. |
| `reports/narrativeStudio/completion/nsc_57_validation_report_receipt_evidence_pack.md` | Présent rapport. |

## Décisions précises

- L'ordre d'agrégation est conservatif : `fail` domine `indeterminate`, qui domine `notRun`, puis `pass`.
- `isPlayable` exige quatre `pass`; aucun statut inconnu n'est assimilé.
- Le fingerprint inclut tout fichier du projet, dont maps, Yarn, catalogues et assets, et exclut uniquement le sidecar de validation, les temporaires et `.DS_Store`.
- Le profil Release exige `selbrume-lighthouse-retry` et `selbrume-player-journey`.
- Le repository editor-side ne lance rien : il lit et vérifie fingerprint, profil/version et suites.
- Le CLI n'écrit aucun receipt si une suite échoue. Le fichier temporaire est flushé dans le même dossier puis renommé ; un crash simulé conserve l'ancien receipt.
- Le ledger `appliedNarrativeResetTokens` est un reçu technique par activation. Le test E2E compare intégralement l'état métier mais contrôle ce ledger séparément : préfixe préservé et au plus un token de save-restore ajouté.
- Le handoff E2E attend explicitement dialogue ou battle lorsque l'ouverture Yarn est asynchrone, supprimant un timeout dépendant du timing.

## Commandes et résultats exacts

```text
cd packages/map_core
/opt/homebrew/bin/dart test test/narrative_validation_report_test.dart test/narrative_runtime_smoke_receipt_test.dart test/narrative_project_fingerprint_test.dart
+7: All tests passed!
/opt/homebrew/bin/dart analyze
No issues found!

cd packages/map_editor
/opt/homebrew/bin/flutter pub get
Changed 1 dependency: map_gameplay
/opt/homebrew/bin/flutter test test/narrative_studio_validation_coordinator_test.dart test/narrative_runtime_smoke_receipt_repository_test.dart
+3: All tests passed!
/opt/homebrew/bin/flutter test --reporter compact test/selbrume_narrative_validator_test.dart
+1: All tests passed! (1 min 16)
/opt/homebrew/bin/flutter analyze <six NSC-57 files>
No issues found!

cd packages/map_runtime
/opt/homebrew/bin/flutter test test/narrative_runtime_smoke_evidence_test.dart
+2: All tests passed!
/opt/homebrew/bin/flutter analyze <NSC-57 runtime files>
No issues found!

cd examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/narrative_runtime_smoke_receipt_integration_test.dart test/narrative_runtime_smoke_receipt_file_integration_test.dart
+4: All tests passed!
/opt/homebrew/bin/flutter analyze <tool + receipt tests + journey>
No issues found!
/opt/homebrew/bin/flutter test --plain-name "player completes Selbrume through PlayableMapGame production hooks" test/selbrume_player_journey_e2e_test.dart
+1: All tests passed! (2 min 27)

/opt/homebrew/bin/dart run tool/verify_narrative_project.dart --project-root ../../selbrume --profile selbrume-release-v1 --write-receipt
selbrume-lighthouse-retry: +3 All tests passed!
selbrume-player-journey: +5 All tests passed!
receipt result=pass
fingerprint=sha256:7c312f02c6b3a9e3411079bf59d6c3ddc91f59be3fe5f4f7725896ab83659bf1

git diff --check
aucune sortie
```

La première production a correctement refusé d'écrire : le parcours E2E exposait cinq comparaisons obsolètes du ledger interne puis un handoff asynchrone flaky. Après correction ciblée, le profil complet est vert. Un premier essai de CLI chargeait aussi inutilement map_runtime sous `dart run` et déclenchait un crash FFI avant main ; le CLI appelle maintenant directement le contrat neutre core tandis que l'evidence runtime reste testée dans map_runtime.

## État Git final avant commit

- Tous les fichiers listés appartiennent à NSC-57.
- Le sidecar Selbrume est volontairement versionné comme preuve fraîche du démonstrateur ; son contenu est exclu de son propre fingerprint.
- Aucun cache/build/temporaire n'est inclus.
- `git diff --check` est propre.

## Limites et auto-critique

- Selbrume conserve honnêtement une solvabilité globale `indeterminate` à cause du budget NSC-54, même si le smoke Release est `pass`. Le badge global reste donc non jouable : le receipt ne masque pas cette dimension.
- Le scan fingerprint est volontairement sur-inclusif ; un asset non consommé modifié peut rendre le reçu stale. C'est sûr mais pourra être affiné par un inventaire runtime explicite.
- Le provider de publication lit le snapshot disque pour le fingerprint. Une map active non sauvegardée est validée en mémoire mais ne peut pas être couverte par un ancien receipt ; l'UX NSC-58 doit signaler clairement ce refresh.
- La date rend le receipt reproductible en contenu métier mais naturellement différent à chaque exécution ; seul son project fingerprint détermine la freshness.
- Le test E2E Release est coûteux (~3 min 28 avec variantes), assumé pour un profil Release et non pour chaque frappe auteur.

## Prochaine étape

NSC-58 — UX Validator, suppressions gouvernées et export CI stable.

## Contenu complet des fichiers créés

Le présent rapport ne s'inclut pas récursivement. Les autres fichiers créés sont reproduits ci-dessous.

<details>
<summary>Contenu complet — docs/superpowers/plans/2026-07-20-nsc-57-validation-report-receipt.md</summary>

```markdown
# NSC-57 — Rapport quatre dimensions et receipt runtime

## Objectif

Définir un contrat neutre et versionné qui agrège validation structurelle,
solvabilité narrative, atteignabilité physique et smoke runtime, sans créer de
dépendance editor → runtime.

## Contrat

- Chaque dimension vaut `pass`, `fail`, `indeterminate` ou `notRun`.
- Le projet n'est jouable que si les quatre dimensions sont `pass`.
- Le fingerprint canonique est calculé dans `map_core` à partir de couples
  `relativePath + bytes` normalisés et triés.
- Le reçu runtime contient profil/version, suites, fixture, résultat, date et
  limites ; absent, stale ou incomplet devient `notRun`.
- Le host écrit le sidecar atomiquement et conserve le reçu précédent si le
  nouveau run échoue avant le rename.
- L'éditeur lit le sidecar et agrège, mais n'importe jamais `map_runtime`.

## Plan TDD

1. RED/GREEN core — rapport, receipt et fingerprint.
2. RED/GREEN gameplay/editor — coordinator quatre dimensions et repository de
   freshness.
3. RED/GREEN runtime/host — evidence, profils obligatoires et écriture
   atomique.
4. Gate ciblé de chaque package, production du reçu Selbrume et Evidence Pack.
```
</details>
<details>
<summary>Contenu complet — packages/map_core/lib/src/models/narrative_validation_report.dart</summary>

```dart
import 'package:meta/meta.dart' show immutable;

enum NarrativeValidationStatus { pass, fail, indeterminate, notRun }

enum NarrativeValidationDimension {
  structurallyValid,
  narrativelySolvable,
  physicallyReachable,
  runtimeSmokeVerified,
}

@immutable
final class NarrativeMultidimensionalDiagnostic {
  NarrativeMultidimensionalDiagnostic({
    required this.id,
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
    List<String> provenance = const <String>[],
  }) : provenance = List.unmodifiable(provenance);

  factory NarrativeMultidimensionalDiagnostic.fromJson(
      Map<String, dynamic> json) {
    return NarrativeMultidimensionalDiagnostic(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      severity: _requiredString(json, 'severity'),
      message: _requiredString(json, 'message'),
      path: _requiredString(json, 'path'),
      provenance: _stringList(json, 'provenance'),
    );
  }

  final String id;
  final String code;
  final String severity;
  final String message;
  final String path;
  final List<String> provenance;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'severity': severity,
        'message': message,
        'path': path,
        'provenance': provenance,
      };
}

@immutable
final class NarrativeValidationDimensionResult {
  NarrativeValidationDimensionResult({
    required this.status,
    List<NarrativeMultidimensionalDiagnostic> diagnostics =
        const <NarrativeMultidimensionalDiagnostic>[],
    List<String> evidenceRefs = const <String>[],
    List<String> limitations = const <String>[],
  })  : diagnostics = List.unmodifiable(diagnostics),
        evidenceRefs = _stableStrings(evidenceRefs),
        limitations = _stableStrings(limitations);

  factory NarrativeValidationDimensionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return NarrativeValidationDimensionResult(
      status: _status(json['status']),
      diagnostics: [
        for (final item in _objectList(json, 'diagnostics'))
          NarrativeMultidimensionalDiagnostic.fromJson(item),
      ],
      evidenceRefs: _stringList(json, 'evidenceRefs'),
      limitations: _stringList(json, 'limitations'),
    );
  }

  final NarrativeValidationStatus status;
  final List<NarrativeMultidimensionalDiagnostic> diagnostics;
  final List<String> evidenceRefs;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'evidenceRefs': evidenceRefs,
        'limitations': limitations,
      };
}

@immutable
final class NarrativeMultidimensionalValidationReport {
  NarrativeMultidimensionalValidationReport({
    this.schemaVersion = 1,
    required this.validatorVersion,
    required this.profileId,
    required this.profileVersion,
    required this.projectFingerprint,
    required DateTime generatedAt,
    required this.structurallyValid,
    required this.narrativelySolvable,
    required this.physicallyReachable,
    required this.runtimeSmokeVerified,
  }) : generatedAt = generatedAt.toUtc() {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
  }

  factory NarrativeMultidimensionalValidationReport.fromJson(
      Map<String, dynamic> json) {
    final dimensions = _object(json, 'dimensions');
    return NarrativeMultidimensionalValidationReport(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      validatorVersion: _requiredString(json, 'validatorVersion'),
      profileId: _requiredString(json, 'profileId'),
      profileVersion: _requiredInt(json, 'profileVersion'),
      projectFingerprint: _requiredString(json, 'projectFingerprint'),
      generatedAt: DateTime.parse(_requiredString(json, 'generatedAt')),
      structurallyValid: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.structurallyValid.name),
      ),
      narrativelySolvable: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.narrativelySolvable.name),
      ),
      physicallyReachable: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.physicallyReachable.name),
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.runtimeSmokeVerified.name),
      ),
    );
  }

  final int schemaVersion;
  final String validatorVersion;
  final String profileId;
  final int profileVersion;
  final String projectFingerprint;
  final DateTime generatedAt;
  final NarrativeValidationDimensionResult structurallyValid;
  final NarrativeValidationDimensionResult narrativelySolvable;
  final NarrativeValidationDimensionResult physicallyReachable;
  final NarrativeValidationDimensionResult runtimeSmokeVerified;

  List<NarrativeValidationDimensionResult> get dimensions => [
        structurallyValid,
        narrativelySolvable,
        physicallyReachable,
        runtimeSmokeVerified,
      ];

  bool get isPlayable => dimensions
      .every((dimension) => dimension.status == NarrativeValidationStatus.pass);

  NarrativeValidationStatus get overallStatus {
    if (dimensions
        .any((item) => item.status == NarrativeValidationStatus.fail)) {
      return NarrativeValidationStatus.fail;
    }
    if (dimensions.any(
      (item) => item.status == NarrativeValidationStatus.indeterminate,
    )) {
      return NarrativeValidationStatus.indeterminate;
    }
    if (dimensions
        .any((item) => item.status == NarrativeValidationStatus.notRun)) {
      return NarrativeValidationStatus.notRun;
    }
    return NarrativeValidationStatus.pass;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'validatorVersion': validatorVersion,
        'profileId': profileId,
        'profileVersion': profileVersion,
        'projectFingerprint': projectFingerprint,
        'generatedAt': generatedAt.toIso8601String(),
        'dimensions': {
          NarrativeValidationDimension.structurallyValid.name:
              structurallyValid.toJson(),
          NarrativeValidationDimension.narrativelySolvable.name:
              narrativelySolvable.toJson(),
          NarrativeValidationDimension.physicallyReachable.name:
              physicallyReachable.toJson(),
          NarrativeValidationDimension.runtimeSmokeVerified.name:
              runtimeSmokeVerified.toJson(),
        },
      };
}

NarrativeValidationStatus _status(Object? value) {
  if (value is String) {
    for (final status in NarrativeValidationStatus.values) {
      if (status.name == value) return status;
    }
  }
  throw FormatException('Unknown NarrativeValidationStatus "$value".');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key must be an object.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _objectList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be a list.');
  return [
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException('$key entries must be objects.'),
  ];
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.from(value);
}

List<String> _stableStrings(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(result);
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/lib/src/models/narrative_runtime_smoke_receipt.dart</summary>

```dart
import 'package:meta/meta.dart' show immutable;

enum NarrativeRuntimeSmokeResult { pass, fail }

@immutable
final class NarrativeRuntimeSmokeProfile {
  NarrativeRuntimeSmokeProfile({
    required this.id,
    required this.version,
    required List<String> requiredSuiteIds,
  }) : requiredSuiteIds = _stableStrings(requiredSuiteIds);

  final String id;
  final int version;
  final List<String> requiredSuiteIds;

  bool acceptsSuites(Iterable<String> suiteIds) {
    final actual = suiteIds.toSet();
    return requiredSuiteIds.every(actual.contains);
  }
}

final NarrativeRuntimeSmokeProfile selbrumeReleaseV1Profile =
    NarrativeRuntimeSmokeProfile(
  id: 'selbrume-release-v1',
  version: 1,
  requiredSuiteIds: const [
    'selbrume-lighthouse-retry',
    'selbrume-player-journey',
  ],
);

NarrativeRuntimeSmokeProfile? narrativeRuntimeSmokeProfileById(String id) =>
    id == selbrumeReleaseV1Profile.id ? selbrumeReleaseV1Profile : null;

@immutable
final class NarrativeRuntimeSmokeReceipt {
  NarrativeRuntimeSmokeReceipt({
    this.schemaVersion = 1,
    required this.projectFingerprint,
    required this.validatorVersion,
    required this.profileId,
    required this.profileVersion,
    required List<String> suiteIds,
    required this.fixtureId,
    required this.result,
    required DateTime completedAt,
    List<String> limitations = const <String>[],
  })  : suiteIds = _stableStrings(suiteIds),
        completedAt = completedAt.toUtc(),
        limitations = _stableStrings(limitations) {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(projectFingerprint)) {
      throw ArgumentError.value(projectFingerprint, 'projectFingerprint');
    }
  }

  factory NarrativeRuntimeSmokeReceipt.fromJson(Map<String, dynamic> json) {
    return NarrativeRuntimeSmokeReceipt(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      projectFingerprint: _requiredString(json, 'projectFingerprint'),
      validatorVersion: _requiredString(json, 'validatorVersion'),
      profileId: _requiredString(json, 'profileId'),
      profileVersion: _requiredInt(json, 'profileVersion'),
      suiteIds: _stringList(json, 'suiteIds'),
      fixtureId: _requiredString(json, 'fixtureId'),
      result: _result(json['result']),
      completedAt: DateTime.parse(_requiredString(json, 'completedAt')),
      limitations: _stringList(json, 'limitations'),
    );
  }

  final int schemaVersion;
  final String projectFingerprint;
  final String validatorVersion;
  final String profileId;
  final int profileVersion;
  final List<String> suiteIds;
  final String fixtureId;
  final NarrativeRuntimeSmokeResult result;
  final DateTime completedAt;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'projectFingerprint': projectFingerprint,
        'validatorVersion': validatorVersion,
        'profileId': profileId,
        'profileVersion': profileVersion,
        'suiteIds': suiteIds,
        'fixtureId': fixtureId,
        'result': result.name,
        'completedAt': completedAt.toIso8601String(),
        'limitations': limitations,
      };
}

NarrativeRuntimeSmokeResult _result(Object? value) {
  return switch (value) {
    'pass' => NarrativeRuntimeSmokeResult.pass,
    'fail' => NarrativeRuntimeSmokeResult.fail,
    _ => throw FormatException('Unknown runtime smoke result "$value".'),
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.from(value);
}

List<String> _stableStrings(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(result);
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/lib/src/operations/narrative_project_fingerprint.dart</summary>

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show immutable;

@immutable
final class NarrativeProjectFingerprintEntry {
  NarrativeProjectFingerprintEntry({
    required String relativePath,
    required List<int> bytes,
  })  : relativePath = _normalizePath(relativePath),
        bytes = Uint8List.fromList(bytes);

  final String relativePath;
  final Uint8List bytes;
}

String computeNarrativeProjectFingerprint(
  Iterable<NarrativeProjectFingerprintEntry> entries,
) {
  final ordered = entries.toList()
    ..sort((left, right) => left.relativePath.compareTo(right.relativePath));
  final seen = <String>{};
  final framed = BytesBuilder(copy: false);
  for (final entry in ordered) {
    if (!seen.add(entry.relativePath)) {
      throw ArgumentError(
          'Duplicate fingerprint path "${entry.relativePath}".');
    }
    final pathBytes = utf8.encode(entry.relativePath);
    framed
      ..add(_uint64(pathBytes.length))
      ..add(pathBytes)
      ..add(_uint64(entry.bytes.length))
      ..add(entry.bytes);
  }
  return 'sha256:${sha256.convert(framed.takeBytes())}';
}

String _normalizePath(String value) {
  var path = value.trim().replaceAll('\\', '/');
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  while (path.contains('//')) {
    path = path.replaceAll('//', '/');
  }
  if (path.isEmpty || path.startsWith('/') || path.split('/').contains('..')) {
    throw ArgumentError.value(
        value, 'relativePath', 'must stay project-relative');
  }
  return path;
}

Uint8List _uint64(int value) {
  if (value < 0) throw ArgumentError.value(value, 'value');
  final data = ByteData(8)..setUint64(0, value, Endian.big);
  return data.buffer.asUint8List();
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/test/narrative_validation_report_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips four independent statuses and requires four passes', () {
    NarrativeValidationDimensionResult dimension(
            NarrativeValidationStatus status) =>
        NarrativeValidationDimensionResult(status: status);
    final report = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'narrative-validator-v1',
      profileId: 'selbrume-release-v1',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'a' * 64}',
      generatedAt: DateTime.utc(2026, 7, 20),
      structurallyValid: dimension(NarrativeValidationStatus.pass),
      narrativelySolvable: dimension(NarrativeValidationStatus.pass),
      physicallyReachable: dimension(NarrativeValidationStatus.pass),
      runtimeSmokeVerified: dimension(NarrativeValidationStatus.notRun),
    );

    final decoded =
        NarrativeMultidimensionalValidationReport.fromJson(report.toJson());
    expect(
        decoded.runtimeSmokeVerified.status, NarrativeValidationStatus.notRun);
    expect(decoded.overallStatus, NarrativeValidationStatus.notRun);
    expect(decoded.isPlayable, isFalse);
  });

  test('fail dominates indeterminate and notRun', () {
    final pass = NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass);
    final report = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'v1',
      profileId: 'profile',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'b' * 64}',
      generatedAt: DateTime.utc(2026),
      structurallyValid: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.fail),
      narrativelySolvable: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.indeterminate),
      physicallyReachable: pass,
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
          status: NarrativeValidationStatus.notRun),
    );
    expect(report.overallStatus, NarrativeValidationStatus.fail);
  });
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/test/narrative_runtime_smoke_receipt_test.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips a versioned release receipt', () {
    final receipt = NarrativeRuntimeSmokeReceipt(
      projectFingerprint: 'sha256:${'c' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profileId: selbrumeReleaseV1Profile.id,
      profileVersion: selbrumeReleaseV1Profile.version,
      suiteIds: selbrumeReleaseV1Profile.requiredSuiteIds.reversed.toList(),
      fixtureId: 'selbrume',
      result: NarrativeRuntimeSmokeResult.pass,
      completedAt: DateTime.parse('2026-07-20T10:00:00+02:00'),
    );

    final decoded = NarrativeRuntimeSmokeReceipt.fromJson(receipt.toJson());
    expect(decoded.suiteIds, selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(decoded.completedAt.isUtc, isTrue);
    expect(selbrumeReleaseV1Profile.acceptsSuites(decoded.suiteIds), isTrue);
  });

  test('release profile refuses a partial suite', () {
    expect(
        selbrumeReleaseV1Profile.acceptsSuites(['selbrume-lighthouse-retry']),
        isFalse);
  });
}
```
</details>

<details>
<summary>Contenu complet — packages/map_core/test/narrative_project_fingerprint_test.dart</summary>

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('is stable across input order and slash normalization', () {
    final first = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'maps/a.json', bytes: utf8.encode('A')),
      NarrativeProjectFingerprintEntry(
          relativePath: r'dialogues\intro.yarn', bytes: utf8.encode('B')),
    ]);
    final second = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'dialogues/intro.yarn', bytes: utf8.encode('B')),
      NarrativeProjectFingerprintEntry(
          relativePath: './maps/a.json', bytes: utf8.encode('A')),
    ]);
    expect(second, first);
  });

  test('includes path boundaries and every file byte', () {
    final base = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: utf8.encode('AB')),
    ]);
    final split = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
          relativePath: 'project.json', bytes: utf8.encode('A')),
      NarrativeProjectFingerprintEntry(
          relativePath: 'maps/a.json', bytes: utf8.encode('B')),
    ]);
    expect(split, isNot(base));
  });

  test('rejects duplicate and escaping relative paths', () {
    expect(
      () => computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(relativePath: 'a', bytes: const []),
        NarrativeProjectFingerprintEntry(relativePath: './a', bytes: const []),
      ]),
      throwsArgumentError,
    );
    expect(
      () => NarrativeProjectFingerprintEntry(
          relativePath: '../secret', bytes: const []),
      throwsArgumentError,
    );
  });
}
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/lib/src/application/services/narrative_studio_validation_coordinator.dart</summary>

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';

final class NarrativeStudioValidationCoordinator {
  const NarrativeStudioValidationCoordinator({
    this.validatorVersion = 'narrative-validator-v1',
  });

  final String validatorVersion;

  NarrativeMultidimensionalValidationReport coordinate({
    required ProjectManifest project,
    required List<MapData> maps,
    required NarrativeProjectValidationReport projectReport,
    required String projectFingerprint,
    required NarrativeRuntimeSmokeProfile profile,
    required NarrativeRuntimeSmokeReceiptResolution runtimeReceipt,
    DateTime? generatedAt,
  }) {
    final symbolic = projectReport.symbolicReachability;
    final physical = symbolic == null
        ? null
        : validateNarrativePhysicalReachability(
            project: project,
            maps: maps,
            narrativeReport: symbolic,
          );
    final structuralDiagnostics = projectReport.diagnostics
        .where((item) => !_isNarrativeSolvabilityCode(item.code))
        .map(_projectDiagnostic)
        .toList(growable: false);
    final structuralErrors = projectReport.diagnostics.any(
      (item) =>
          item.severity == NarrativeProjectDiagnosticSeverity.error &&
          !_isNarrativeSolvabilityCode(item.code),
    );
    final narrativeDiagnostics = projectReport.diagnostics
        .where((item) => _isNarrativeSolvabilityCode(item.code))
        .map(_projectDiagnostic)
        .toList(growable: false);

    return NarrativeMultidimensionalValidationReport(
      validatorVersion: validatorVersion,
      profileId: profile.id,
      profileVersion: profile.version,
      projectFingerprint: projectFingerprint,
      generatedAt: generatedAt ?? DateTime.now().toUtc(),
      structurallyValid: NarrativeValidationDimensionResult(
        status: structuralErrors
            ? NarrativeValidationStatus.fail
            : NarrativeValidationStatus.pass,
        diagnostics: structuralDiagnostics,
      ),
      narrativelySolvable: NarrativeValidationDimensionResult(
        status: _symbolicStatus(symbolic?.verdict),
        diagnostics: narrativeDiagnostics,
        evidenceRefs: symbolic == null
            ? const []
            : ['symbolic-states:${symbolic.exploredStateCount}'],
        limitations: symbolic == null
            ? const ['La preuve symbolique n’a pas été exécutée.']
            : [for (final issue in symbolic.issues) issue.message],
      ),
      physicallyReachable: NarrativeValidationDimensionResult(
        status: _physicalStatus(physical?.verdict),
        diagnostics: physical == null
            ? const []
            : [
                for (final issue in physical.issues)
                  NarrativeMultidimensionalDiagnostic(
                    id: 'physical:${issue.code.name}:${issue.eventId ?? ''}:${issue.mapId ?? ''}',
                    code: issue.code.name,
                    severity: issue.code ==
                            NarrativePhysicalIssueCode.permanentlyBlocked
                        ? 'error'
                        : 'warning',
                    message: issue.message,
                    path: issue.mapId == null ? 'maps' : 'maps.${issue.mapId}',
                  ),
              ],
        evidenceRefs: physical == null
            ? const []
            : [
                for (final result in physical.results)
                  if (result.reachedCell != null)
                    'event:${result.eventId}@${result.mapId}:${result.reachedCell!.x},${result.reachedCell!.y}',
              ],
        limitations: physical == null
            ? const ['La preuve physique n’a pas été exécutée.']
            : const [],
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
        status: runtimeReceipt.validationStatus,
        evidenceRefs: runtimeReceipt.receipt == null
            ? const []
            : [
                NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath,
                ...runtimeReceipt.receipt!.suiteIds.map((id) => 'suite:$id'),
              ],
        limitations: [
          if (runtimeReceipt.validationStatus != NarrativeValidationStatus.pass)
            runtimeReceipt.reason,
          ...?runtimeReceipt.receipt?.limitations,
        ],
      ),
    );
  }
}

NarrativeValidationStatus _symbolicStatus(NarrativeSymbolicVerdict? verdict) =>
    switch (verdict) {
      NarrativeSymbolicVerdict.pass => NarrativeValidationStatus.pass,
      NarrativeSymbolicVerdict.fail => NarrativeValidationStatus.fail,
      NarrativeSymbolicVerdict.indeterminate =>
        NarrativeValidationStatus.indeterminate,
      null => NarrativeValidationStatus.notRun,
    };

NarrativeValidationStatus _physicalStatus(
  NarrativePhysicalReachabilityVerdict? verdict,
) =>
    switch (verdict) {
      NarrativePhysicalReachabilityVerdict.pass =>
        NarrativeValidationStatus.pass,
      NarrativePhysicalReachabilityVerdict.fail =>
        NarrativeValidationStatus.fail,
      NarrativePhysicalReachabilityVerdict.indeterminate =>
        NarrativeValidationStatus.indeterminate,
      null => NarrativeValidationStatus.notRun,
    };

NarrativeMultidimensionalDiagnostic _projectDiagnostic(
  NarrativeProjectDiagnostic item,
) =>
    NarrativeMultidimensionalDiagnostic(
      id: item.stableKey,
      code: item.code,
      severity: item.severity.name,
      message: item.message,
      path: item.path,
    );

bool _isNarrativeSolvabilityCode(String code) =>
    code.startsWith('narrative') || code == 'oneShotRetryableOutcomeSoftlock';
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/lib/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart</summary>

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

enum NarrativeRuntimeReceiptState {
  freshPass,
  freshFail,
  absent,
  stale,
  profileMismatch,
  incompleteSuites,
  invalid,
}

final class NarrativeRuntimeSmokeReceiptResolution {
  const NarrativeRuntimeSmokeReceiptResolution({
    required this.state,
    required this.reason,
    this.receipt,
  });

  final NarrativeRuntimeReceiptState state;
  final String reason;
  final NarrativeRuntimeSmokeReceipt? receipt;

  NarrativeValidationStatus get validationStatus => switch (state) {
        NarrativeRuntimeReceiptState.freshPass =>
          NarrativeValidationStatus.pass,
        NarrativeRuntimeReceiptState.freshFail =>
          NarrativeValidationStatus.fail,
        NarrativeRuntimeReceiptState.absent ||
        NarrativeRuntimeReceiptState.stale ||
        NarrativeRuntimeReceiptState.profileMismatch ||
        NarrativeRuntimeReceiptState.incompleteSuites ||
        NarrativeRuntimeReceiptState.invalid =>
          NarrativeValidationStatus.notRun,
      };
}

final class NarrativeRuntimeSmokeReceiptRepository {
  const NarrativeRuntimeSmokeReceiptRepository();

  static const relativeReceiptPath =
      '.pokemap/validation/narrative_runtime_smoke_receipt.json';

  Future<String> computeProjectFingerprint(String projectRoot) async {
    final root = Directory(p.normalize(p.absolute(projectRoot)));
    if (!await root.exists()) {
      throw FileSystemException('Project root does not exist.', root.path);
    }
    final entries = <NarrativeProjectFingerprintEntry>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.posix.normalize(
        p.relative(entity.path, from: root.path).replaceAll('\\', '/'),
      );
      if (_ignoredFingerprintPath(relative)) continue;
      entries.add(
        NarrativeProjectFingerprintEntry(
          relativePath: relative,
          bytes: await entity.readAsBytes(),
        ),
      );
    }
    return computeNarrativeProjectFingerprint(entries);
  }

  Future<NarrativeRuntimeSmokeReceiptResolution> read({
    required String projectRoot,
    required String expectedFingerprint,
    required NarrativeRuntimeSmokeProfile profile,
  }) async {
    final file = File(p.join(projectRoot, relativeReceiptPath));
    if (!await file.exists()) {
      return const NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.absent,
        reason: 'Aucun smoke runtime n’a été exécuté pour ce snapshot.',
      );
    }
    NarrativeRuntimeSmokeReceipt receipt;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Receipt must be an object.');
      }
      receipt = NarrativeRuntimeSmokeReceipt.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on Object catch (error) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.invalid,
        reason: 'Le receipt runtime est invalide : $error',
      );
    }
    if (receipt.projectFingerprint != expectedFingerprint) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.stale,
        reason: 'Le receipt appartient à un ancien snapshot du projet.',
        receipt: receipt,
      );
    }
    if (receipt.profileId != profile.id ||
        receipt.profileVersion != profile.version) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.profileMismatch,
        reason: 'Le receipt ne correspond pas au profil ${profile.id}.',
        receipt: receipt,
      );
    }
    if (!profile.acceptsSuites(receipt.suiteIds)) {
      return NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.incompleteSuites,
        reason: 'Le receipt ne couvre pas toutes les suites obligatoires.',
        receipt: receipt,
      );
    }
    return NarrativeRuntimeSmokeReceiptResolution(
      state: receipt.result == NarrativeRuntimeSmokeResult.pass
          ? NarrativeRuntimeReceiptState.freshPass
          : NarrativeRuntimeReceiptState.freshFail,
      reason: receipt.result == NarrativeRuntimeSmokeResult.pass
          ? 'Smoke runtime frais et complet.'
          : 'Le smoke runtime frais a échoué.',
      receipt: receipt,
    );
  }
}

bool _ignoredFingerprintPath(String relativePath) {
  return relativePath ==
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath ||
      relativePath.startsWith('.pokemap/validation/') ||
      relativePath.endsWith('.tmp') ||
      relativePath == '.DS_Store';
}
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/test/narrative_studio_validation_coordinator_test.dart</summary>

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_studio_validation_coordinator.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';

void main() {
  test('keeps four dimensions independent and refuses absent smoke', () {
    final symbolic = NarrativeSymbolicReachabilityReport(
      verdict: NarrativeSymbolicVerdict.pass,
      terminalStates: [NarrativeSymbolicState()],
      exploredStates: [NarrativeSymbolicState()],
      issues: const [],
      reachableSceneIds: const {},
      exploredStateCount: 1,
    );
    const project = ProjectManifest(
      name: 'Coordinator',
      maps: [],
      tilesets: [],
      newGame: ProjectNewGameConfig(
          enabled: true, startMapId: 'start', startSpawnId: 'spawn'),
    );
    final report = const NarrativeStudioValidationCoordinator().coordinate(
      project: project,
      maps: const [],
      projectReport: NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
        symbolicReachability: symbolic,
      ),
      projectFingerprint: 'sha256:${'e' * 64}',
      profile: selbrumeReleaseV1Profile,
      runtimeReceipt: const NarrativeRuntimeSmokeReceiptResolution(
        state: NarrativeRuntimeReceiptState.absent,
        reason: 'absent',
      ),
      generatedAt: DateTime.utc(2026),
    );

    expect(report.structurallyValid.status, NarrativeValidationStatus.pass);
    expect(report.narrativelySolvable.status, NarrativeValidationStatus.pass);
    expect(report.physicallyReachable.status, NarrativeValidationStatus.pass);
    expect(
        report.runtimeSmokeVerified.status, NarrativeValidationStatus.notRun);
    expect(report.isPlayable, isFalse);
  });
}
```
</details>

<details>
<summary>Contenu complet — packages/map_editor/test/narrative_runtime_smoke_receipt_repository_test.dart</summary>

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  test('fingerprint includes manifest, maps and Yarn but excludes receipt',
      () async {
    final root = await Directory.systemTemp.createTemp('receipt_repo_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    await Directory(p.join(root.path, 'maps')).create();
    await File(p.join(root.path, 'maps', 'a.json')).writeAsString('{"id":"a"}');
    await Directory(p.join(root.path, 'dialogues')).create();
    final yarn = File(p.join(root.path, 'dialogues', 'intro.yarn'));
    await yarn.writeAsString('title: Intro');
    const repository = NarrativeRuntimeSmokeReceiptRepository();

    final before = await repository.computeProjectFingerprint(root.path);
    await yarn.writeAsString('title: Changed');
    final afterYarn = await repository.computeProjectFingerprint(root.path);
    expect(afterYarn, isNot(before));

    final receiptFile = File(
      p.join(root.path,
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath),
    );
    await receiptFile.parent.create(recursive: true);
    await receiptFile.writeAsString('{}');
    expect(await repository.computeProjectFingerprint(root.path), afterYarn);
  });

  test('absent, stale, partial and fresh receipts never alias', () async {
    final root = await Directory.systemTemp.createTemp('receipt_states_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    const repository = NarrativeRuntimeSmokeReceiptRepository();
    final fingerprint = await repository.computeProjectFingerprint(root.path);
    final absent = await repository.read(
      projectRoot: root.path,
      expectedFingerprint: fingerprint,
      profile: selbrumeReleaseV1Profile,
    );
    expect(absent.state, NarrativeRuntimeReceiptState.absent);

    final file = File(
      p.join(root.path,
          NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath),
    );
    await file.parent.create(recursive: true);
    Future<void> write(
            {required String digest, required List<String> suites}) =>
        file.writeAsString(jsonEncode(NarrativeRuntimeSmokeReceipt(
          projectFingerprint: digest,
          validatorVersion: 'v1',
          profileId: selbrumeReleaseV1Profile.id,
          profileVersion: 1,
          suiteIds: suites,
          fixtureId: 'selbrume',
          result: NarrativeRuntimeSmokeResult.pass,
          completedAt: DateTime.utc(2026),
        ).toJson()));

    await write(
        digest: 'sha256:${'d' * 64}',
        suites: selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.stale,
    );
    await write(digest: fingerprint, suites: ['selbrume-lighthouse-retry']);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.incompleteSuites,
    );
    await write(
        digest: fingerprint, suites: selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(
      (await repository.read(
              projectRoot: root.path,
              expectedFingerprint: fingerprint,
              profile: selbrumeReleaseV1Profile))
          .state,
      NarrativeRuntimeReceiptState.freshPass,
    );
  });
}
```
</details>

<details>
<summary>Contenu complet — packages/map_runtime/lib/src/application/narrative_runtime_smoke_evidence.dart</summary>

```dart
import 'package:map_core/map_core.dart';

NarrativeRuntimeSmokeReceipt buildNarrativeRuntimeSmokeEvidence({
  required String projectFingerprint,
  required String validatorVersion,
  required NarrativeRuntimeSmokeProfile profile,
  required List<String> executedSuiteIds,
  required String fixtureId,
  required bool passed,
  required DateTime completedAt,
  List<String> limitations = const <String>[],
}) {
  if (!profile.acceptsSuites(executedSuiteIds)) {
    final missing = profile.requiredSuiteIds
        .where((suiteId) => !executedSuiteIds.contains(suiteId))
        .join(', ');
    throw StateError(
      'Runtime smoke profile ${profile.id} is incomplete. Missing: $missing',
    );
  }
  final normalizedFixtureId = fixtureId.trim();
  if (normalizedFixtureId.isEmpty) {
    throw ArgumentError.value(fixtureId, 'fixtureId', 'must not be empty');
  }
  return NarrativeRuntimeSmokeReceipt(
    projectFingerprint: projectFingerprint,
    validatorVersion: validatorVersion,
    profileId: profile.id,
    profileVersion: profile.version,
    suiteIds: executedSuiteIds,
    fixtureId: normalizedFixtureId,
    result: passed
        ? NarrativeRuntimeSmokeResult.pass
        : NarrativeRuntimeSmokeResult.fail,
    completedAt: completedAt,
    limitations: limitations,
  );
}
```
</details>

<details>
<summary>Contenu complet — packages/map_runtime/test/narrative_runtime_smoke_evidence_test.dart</summary>

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('builds a release receipt only after every required suite ran', () {
    final receipt = buildNarrativeRuntimeSmokeEvidence(
      projectFingerprint: 'sha256:${'f' * 64}',
      validatorVersion: 'narrative-validator-v1',
      profile: selbrumeReleaseV1Profile,
      executedSuiteIds: selbrumeReleaseV1Profile.requiredSuiteIds,
      fixtureId: 'selbrume',
      passed: true,
      completedAt: DateTime.utc(2026, 7, 20),
    );
    expect(receipt.result, NarrativeRuntimeSmokeResult.pass);
    expect(receipt.profileId, 'selbrume-release-v1');
  });

  test('refuses to promote a trivial or partial fixture', () {
    expect(
      () => buildNarrativeRuntimeSmokeEvidence(
        projectFingerprint: 'sha256:${'f' * 64}',
        validatorVersion: 'v1',
        profile: selbrumeReleaseV1Profile,
        executedSuiteIds: const ['selbrume-lighthouse-retry'],
        fixtureId: 'tiny',
        passed: true,
        completedAt: DateTime.utc(2026),
      ),
      throwsStateError,
    );
  });
}
```
</details>

<details>
<summary>Contenu complet — examples/playable_runtime_host/tool/verify_narrative_project.dart</summary>

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

typedef NarrativeSuiteRunner = Future<bool> Function(
  String suiteId,
  String testPath,
);

const _suitePaths = <String, String>{
  'selbrume-lighthouse-retry':
      'test/selbrume_lighthouse_retry_integration_test.dart',
  'selbrume-player-journey': 'test/selbrume_player_journey_e2e_test.dart',
};

Future<void> main(List<String> args) async {
  final parsed = _Arguments.parse(args);
  if (parsed == null) {
    stderr.writeln(
      'Usage: dart run tool/verify_narrative_project.dart '
      '--project-root <path> --profile selbrume-release-v1 --write-receipt',
    );
    exitCode = 64;
    return;
  }
  final profile = narrativeRuntimeSmokeProfileById(parsed.profileId);
  if (profile == null) {
    stderr.writeln('Unknown runtime smoke profile "${parsed.profileId}".');
    exitCode = 64;
    return;
  }
  final receipt = await verifyNarrativeProject(
    projectRoot: parsed.projectRoot,
    profile: profile,
    suiteRunner: _runFlutterSuite,
  );
  if (receipt == null) {
    stderr.writeln('Runtime smoke failed; the previous receipt is preserved.');
    exitCode = 1;
    return;
  }
  if (parsed.writeReceipt) {
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: parsed.projectRoot,
      receipt: receipt,
    );
  }
  stdout.writeln(jsonEncode(receipt.toJson()));
}

Future<NarrativeRuntimeSmokeReceipt?> verifyNarrativeProject({
  required String projectRoot,
  required NarrativeRuntimeSmokeProfile profile,
  required NarrativeSuiteRunner suiteRunner,
  DateTime? completedAt,
}) async {
  final executed = <String>[];
  for (final suiteId in profile.requiredSuiteIds) {
    final testPath = _suitePaths[suiteId];
    if (testPath == null || !await suiteRunner(suiteId, testPath)) return null;
    executed.add(suiteId);
  }
  final fingerprint = await fingerprintNarrativeProjectDirectory(projectRoot);
  return NarrativeRuntimeSmokeReceipt(
    projectFingerprint: fingerprint,
    validatorVersion: 'narrative-validator-v1',
    profileId: profile.id,
    profileVersion: profile.version,
    suiteIds: executed,
    fixtureId: p.basename(p.normalize(p.absolute(projectRoot))),
    result: NarrativeRuntimeSmokeResult.pass,
    completedAt: completedAt ?? DateTime.now().toUtc(),
  );
}

Future<String> fingerprintNarrativeProjectDirectory(String projectRoot) async {
  final root = Directory(p.normalize(p.absolute(projectRoot)));
  if (!await root.exists()) {
    throw FileSystemException('Project root does not exist.', root.path);
  }
  final entries = <NarrativeProjectFingerprintEntry>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.posix.normalize(
      p.relative(entity.path, from: root.path).replaceAll('\\', '/'),
    );
    if (_ignoredPath(relative)) continue;
    entries.add(
      NarrativeProjectFingerprintEntry(
        relativePath: relative,
        bytes: await entity.readAsBytes(),
      ),
    );
  }
  return computeNarrativeProjectFingerprint(entries);
}

Future<void> writeNarrativeRuntimeSmokeReceiptAtomically({
  required String projectRoot,
  required NarrativeRuntimeSmokeReceipt receipt,
  Future<void> Function(File temporaryFile)? beforeRename,
}) async {
  final destination = File(
    p.join(
      projectRoot,
      '.pokemap',
      'validation',
      'narrative_runtime_smoke_receipt.json',
    ),
  );
  await destination.parent.create(recursive: true);
  final temporary = File(
    '${destination.path}.${pid}_${DateTime.now().microsecondsSinceEpoch}.tmp',
  );
  try {
    final sink = temporary.openWrite();
    sink.write(const JsonEncoder.withIndent('  ').convert(receipt.toJson()));
    sink.write('\n');
    await sink.flush();
    await sink.close();
    if (beforeRename != null) await beforeRename(temporary);
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<bool> _runFlutterSuite(String suiteId, String testPath) async {
  final configured = Platform.environment['FLUTTER_BIN'];
  final homebrew = File('/opt/homebrew/bin/flutter');
  final executable =
      configured ?? (await homebrew.exists() ? homebrew.path : 'flutter');
  stdout.writeln('Running $suiteId ($testPath)…');
  final result = await Process.run(
    executable,
    ['test', '--reporter', 'compact', testPath],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode == 0;
}

bool _ignoredPath(String relativePath) =>
    relativePath.startsWith('.pokemap/validation/') ||
    relativePath.endsWith('.tmp') ||
    relativePath == '.DS_Store';

final class _Arguments {
  const _Arguments({
    required this.projectRoot,
    required this.profileId,
    required this.writeReceipt,
  });

  final String projectRoot;
  final String profileId;
  final bool writeReceipt;

  static _Arguments? parse(List<String> args) {
    String? projectRoot;
    String? profileId;
    var writeReceipt = false;
    for (var index = 0; index < args.length; index++) {
      switch (args[index]) {
        case '--project-root':
          if (++index >= args.length) return null;
          projectRoot = args[index];
        case '--profile':
          if (++index >= args.length) return null;
          profileId = args[index];
        case '--write-receipt':
          writeReceipt = true;
        default:
          return null;
      }
    }
    if (projectRoot == null || profileId == null) return null;
    return _Arguments(
      projectRoot: projectRoot,
      profileId: profileId,
      writeReceipt: writeReceipt,
    );
  }
}
```
</details>

<details>
<summary>Contenu complet — examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_integration_test.dart</summary>

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/verify_narrative_project.dart';

void main() {
  test('host and core produce the same complete project fingerprint', () async {
    final root = await Directory.systemTemp.createTemp('host_fingerprint_');
    addTearDown(() => root.delete(recursive: true));
    final project = File(p.join(root.path, 'project.json'));
    final map = File(p.join(root.path, 'maps', 'a.json'));
    await map.parent.create(recursive: true);
    await project.writeAsString('{}');
    await map.writeAsString('{"id":"a"}');

    final host = await fingerprintNarrativeProjectDirectory(root.path);
    final core = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: await project.readAsBytes(),
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/a.json',
        bytes: await map.readAsBytes(),
      ),
    ]);
    expect(host, core);
  });

  test('release verification records every mandatory suite', () async {
    final root = await Directory.systemTemp.createTemp('host_verify_');
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'project.json')).writeAsString('{}');
    final executed = <String>[];
    final receipt = await verifyNarrativeProject(
      projectRoot: root.path,
      profile: selbrumeReleaseV1Profile,
      suiteRunner: (suiteId, _) async {
        executed.add(suiteId);
        return true;
      },
      completedAt: DateTime.utc(2026),
    );
    expect(executed, selbrumeReleaseV1Profile.requiredSuiteIds);
    expect(receipt?.result, NarrativeRuntimeSmokeResult.pass);
  });
}
```
</details>

<details>
<summary>Contenu complet — examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_file_integration_test.dart</summary>

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/verify_narrative_project.dart';

void main() {
  test('atomic writer publishes a decodable receipt', () async {
    final root = await Directory.systemTemp.createTemp('receipt_atomic_');
    addTearDown(() => root.delete(recursive: true));
    final receipt = _receipt('a');
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: root.path,
      receipt: receipt,
    );
    final file = File(p.join(
      root.path,
      '.pokemap/validation/narrative_runtime_smoke_receipt.json',
    ));
    final decoded = NarrativeRuntimeSmokeReceipt.fromJson(
      Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
    );
    expect(decoded.projectFingerprint, receipt.projectFingerprint);
  });

  test('failure before rename preserves the previous valid receipt', () async {
    final root = await Directory.systemTemp.createTemp('receipt_preserve_');
    addTearDown(() => root.delete(recursive: true));
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: root.path,
      receipt: _receipt('a'),
    );

    await expectLater(
      writeNarrativeRuntimeSmokeReceiptAtomically(
        projectRoot: root.path,
        receipt: _receipt('b'),
        beforeRename: (_) async => throw StateError('simulated crash'),
      ),
      throwsStateError,
    );
    final file = File(p.join(
      root.path,
      '.pokemap/validation/narrative_runtime_smoke_receipt.json',
    ));
    final decoded = jsonDecode(await file.readAsString()) as Map;
    expect(decoded['projectFingerprint'], 'sha256:${'a' * 64}');
    expect(
      file.parent.listSync().whereType<File>().map((item) => item.path),
      everyElement(isNot(endsWith('.tmp'))),
    );
  });
}

NarrativeRuntimeSmokeReceipt _receipt(String hex) =>
    NarrativeRuntimeSmokeReceipt(
      projectFingerprint: 'sha256:${hex * 64}',
      validatorVersion: 'v1',
      profileId: selbrumeReleaseV1Profile.id,
      profileVersion: 1,
      suiteIds: selbrumeReleaseV1Profile.requiredSuiteIds,
      fixtureId: 'selbrume',
      result: NarrativeRuntimeSmokeResult.pass,
      completedAt: DateTime.utc(2026),
    );
```
</details>

<details>
<summary>Contenu complet — selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json</summary>

```json
{
  "schemaVersion": 1,
  "projectFingerprint": "sha256:7c312f02c6b3a9e3411079bf59d6c3ddc91f59be3fe5f4f7725896ab83659bf1",
  "validatorVersion": "narrative-validator-v1",
  "profileId": "selbrume-release-v1",
  "profileVersion": 1,
  "suiteIds": [
    "selbrume-lighthouse-retry",
    "selbrume-player-journey"
  ],
  "fixtureId": "selbrume",
  "result": "pass",
  "completedAt": "2026-07-20T18:47:36.400917Z",
  "limitations": []
}
```
</details>

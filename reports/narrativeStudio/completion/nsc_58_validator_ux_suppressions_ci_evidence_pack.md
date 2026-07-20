# NSC-58 — Validator UX, suppressions, quick fixes et CI

Date de clôture : 2026-07-20
Phase : 5 — Qualité, collaboration et livraison
Lot : NSC-58
Verdict proposé : **DONE**
Verdict courant du projet Selbrume : **indeterminate** (résultat honnête, exporté avec preuves et limites)

## Objectif et critères de clôture

Le lot ferme la boucle du Validateur narratif : chaque diagnostic doit proposer soit une navigation exacte, soit une correction réellement gouvernée et réversible, soit une explication exploitable. Le rapport de publication doit exposer séparément structure, solvabilité narrative, atteignabilité physique et smoke runtime, avec un format canonique utilisable en CI.

Critères couverts :

- suppressions persistées, motivées, attribuées, expirables et invalidées quand le diagnostic change ;
- erreurs bloquantes non supprimables ;
- diagnostics actifs, supprimés, expirés, obsolètes et résolus visibles par filtres ;
- filtres par dimension, sévérité, domaine, map, storyline, asset et statut ;
- navigation exacte vers Map, Event, Scene, Dialogue, Cinématique, Storyline/chapitre/étape, Fact et World Rule ;
- preuves, limites et dépendances affichées ;
- contrat de quick fix déterministe, prévisualisé, persistant et réversible ;
- export JSON canonique et atomique ;
- codes de sortie CI : 0 pass, 1 fail, 2 indeterminate, 3 notRun, 64 usage, 70 indisponibilité logicielle ;
- quatre verdicts indépendants et corrélés au fingerprint du projet.

## Audit initial et passes de revue

État initial : branche main, HEAD d4f37a5a, arbre de travail propre.

L’orchestration active interdisait l’usage de sub-agents pour ce lot. Aucun verdict de sub-agent n’a donc été fabriqué. Les contrôles indépendants ont été réalisés localement en quatre passes :

| Passe | Périmètre | Verdict |
|---|---|---|
| 1 | Contrats core, sérialisation stricte, mutation autorisée | Conforme |
| 2 | Services editor, persistance atomique, suppressions et quick fixes | Conforme |
| 3 | UX, filtres, preuves/limites et navigation exacte | Conforme après correction d’un import et d’une assertion trop stricte |
| 4 | CLI, rapport Selbrume, analyse statique et état Git | Conforme ; Selbrume reste honnêtement indeterminate |

## Décisions et non-objectifs

- Une suppression ne supprime jamais une erreur de release.
- Une suppression est liée à l’identifiant stable et au fingerprint du contenu ; une entrée expirée ou obsolète ne masque rien.
- Les diagnostics propres à la publication physique/runtime sont fusionnés dans la vue du validateur sans dupliquer ceux déjà projetés depuis l’authoring.
- Une correction n’est applicable que si elle est déterministe, prévisualisée, réversible et basée sur le snapshot courant.
- Le lot ne transforme pas un budget de preuve dépassé en faux échec ou faux succès : le statut reste indeterminate.
- Le lot ne modifie pas le gameplay ni le runtime ; il gouverne la preuve et l’expérience de validation.

## Inventaire des fichiers modifiés

| Fichier | Zone précise |
|---|---|
| packages/map_core/lib/map_core.dart | exports des suppressions et du codec de rapport |
| packages/map_core/lib/src/authoring/narrative_asset_mutation.dart | mutation NarrativeDiagnosticSuppressionsUpdated et garde de périmètre |
| packages/map_core/lib/src/models/map_data.dart | annotation Freezed explicite pour préserver le codec JSON généré |
| packages/map_core/lib/src/models/project_manifest.dart | collection persistée narrativeDiagnosticSuppressions et annotation codec |
| packages/map_core/lib/src/models/project_manifest.freezed.dart | code généré pour la nouvelle propriété |
| packages/map_core/lib/src/models/project_manifest.g.dart | lecture/écriture JSON des suppressions |
| packages/map_core/lib/src/validation/validators.dart | unicité de diagnosticId |
| packages/map_core/test/project_manifest_narrative_canonical_json_test.dart | couverture canonique des suppressions |
| packages/map_editor/lib/src/application/services/narrative_studio_validation_coordinator.dart | limites physiques explicites en cas d’indétermination |
| packages/map_editor/lib/src/application/use_cases/execute_narrative_authoring_transaction.dart | exécution de la nouvelle mutation |
| packages/map_editor/lib/src/features/narrative/state/narrative_validator_providers.dart | provider du service de suppression |
| packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart | cartes 4D, filtres, statuts, preuves, limites et actions gouvernées |
| packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart | fusion publication/authoring, persistance atomique, dialogues et navigation |
| packages/map_editor/test/narrative_validator_workspace_test.dart | couverture UX des dimensions, filtres et suppressions |
| packages/map_editor/test/ui/canvas/event_builder_v2_validation_navigation_test.dart | chemin Event/Map/dépendances exact |
| packages/map_editor/test/ui/canvas/narrative_validator_route_test.dart | routes Storyline, cibles obsolètes et identité snapshot |

## Fichiers créés

| Fichier | Rôle |
|---|---|
| packages/map_core/lib/src/models/narrative_diagnostic_suppression.dart | modèle strict et versionné |
| packages/map_core/lib/src/operations/narrative_validation_report_codec.dart | codec canonique, fingerprints et exit codes |
| packages/map_core/test/narrative_diagnostic_suppression_test.dart | modèle, expiration et validation |
| packages/map_core/test/narrative_validation_report_codec_test.dart | round-trip canonique et codes CI |
| packages/map_editor/lib/src/application/services/narrative_diagnostic_suppression_service.dart | statuts, fusion publication, suppression et quick fixes |
| packages/map_editor/test/narrative_diagnostic_suppression_service_test.dart | persistance, rejet, stale/expired/resolved et fusion |
| packages/map_editor/test/narrative_validator_quick_fix_test.dart | transaction et refus des corrections non gouvernées |
| packages/map_editor/test/validate_narrative_project_cli_test.dart | tests process des sorties 0/1/2/3/64 |
| packages/map_editor/tool/validate_narrative_project.dart | commande de validation locale/CI |
| reports/narrativeStudio/completion/selbrume_narrative_validation_report.json | preuve réelle canonique du démonstrateur |
| reports/narrativeStudio/completion/nsc_58_validator_ux_suppressions_ci_evidence_pack.md | présent Evidence Pack |

## Commandes et résultats exacts

### Core

- cd packages/map_core && dart test → **4271 tests réussis**.
- cd packages/map_core && dart analyze → **No issues found**.
- dart run build_runner build --delete-conflicting-outputs dans packages/map_core → génération réussie ; annotations Freezed explicites ajoutées pour éviter la disparition des codecs JSON existants.

### Editor

- Première relance après fusion publication : **échec contrôlé**, import du service absent dans narrative_workspace_canvas.dart et assertion exacte incompatible avec la provenance ajoutée.
- Relance focalisée après correction : flutter test sur suppression service, workspace et routes → **24 tests réussis**.
- Suite ciblée complète NSC-58 (9 fichiers de test) → **35 tests réussis**.
- Validation réelle Selbrume déjà exécutée dans la campagne de phase : test du validateur Selbrume → **1 test réussi**.
- Analyse ciblée de 14 fichiers du lot → **No issues found! (ran in 3.4s)**.
- Analyse complète packages/map_editor → aucun nouvel écart du lot ; **11 warnings préexistants** confinés à dialogue_studio_dialogs.dart.

### CLI et démonstrateur

- Une première invocation a visé par erreur le dossier documentaire MVP Selbrume → **exit 70**, « Le manifest du projet est introuvable. »
- Invocation corrigée : dart run tool/validate_narrative_project.dart --project-root /Users/karim/Project/pokemonProject/selbrume --profile selbrume-release-v1 --format json --output /Users/karim/Project/pokemonProject/reports/narrativeStudio/completion/selbrume_narrative_validation_report.json → **exit 2**, indeterminate.
- Fingerprint : sha256:7c312f02c6b3a9e3411079bf59d6c3ddc91f59be3fe5f4f7725896ab83659bf1.
- Structure : pass, 52 avertissements non bloquants.
- Solvabilité narrative : indeterminate, 3 diagnostics, budget symbolique 16384 documenté.
- Atteignabilité physique : indeterminate, 1 diagnostic, budget 32768 documenté.
- Smoke runtime : pass, reçu frais et références des suites présentes.
- git diff --check → **aucune erreur**.

## État Git de clôture

Au moment de construire ce document, le snapshot audité contient uniquement les fichiers NSC-58 inventoriés ci-dessus et le présent Evidence Pack. Aucun changement étranger n’a été détecté. Le commit demandé est créé après l’écriture de ce document afin de l’inclure dans le même lot ; son hash et l’état post-commit sont donc consignés dans le handoff final, évitant une référence circulaire dans le contenu du commit.

## Risques, limites et auto-critique

- Le démonstrateur n’est pas déclaré jouable par simple optimisme : les explorations symbolique et physique atteignent encore leurs budgets. C’est une limite de preuve, pas une preuve d’échec.
- Les 52 avertissements structurels restent visibles et devront être triés selon la qualité de contenu souhaitée.
- Les quick fixes disposent maintenant d’un contrat sûr, mais seuls les correctifs réellement déterministes devront être enregistrés ; ce lot ne crée volontairement aucun correctif spéculatif.
- L’UI a une couverture widget fonctionnelle, pas une campagne de comparaison visuelle pixel-perfect dans ce lot.
- Le rapport JSON est lié au fingerprint courant ; toute modification de Selbrume rend correctement le reçu/runtime et les suppressions potentiellement obsolètes.
- L’annotation Freezed explicite sur MapData est une mesure de compatibilité avec la génération locale et ne change pas son schéma.

## Proposition de statut

- NSC-58 : **DONE**.
- Phase 5 — Qualité, collaboration et livraison : **DONE côté implémentation**.
- Release Selbrume : **indeterminate**, avec raisons, preuves et limites désormais exportables et navigables ; aucun faux pass n’est revendiqué.

## Contenu complet des fichiers créés

### packages/map_core/lib/src/models/narrative_diagnostic_suppression.dart

~~~~dart
import 'package:meta/meta.dart' show immutable;

const _sha256FingerprintPattern = r'^sha256:[0-9a-f]{64}$';

/// Auditable project-owned decision to hide one non-blocking diagnostic.
///
/// The fingerprint deliberately binds the decision to the diagnostic content.
/// A changed diagnostic therefore becomes stale instead of inheriting an old
/// suppression silently.
@immutable
final class NarrativeDiagnosticSuppression {
  NarrativeDiagnosticSuppression({
    this.schemaVersion = 1,
    required String diagnosticId,
    required String diagnosticFingerprint,
    required String reason,
    required String author,
    required DateTime createdAt,
    DateTime? expiresAt,
  })  : diagnosticId = _requiredText(diagnosticId, 'diagnosticId'),
        diagnosticFingerprint = _fingerprint(diagnosticFingerprint),
        reason = _requiredText(reason, 'reason'),
        author = _requiredText(author, 'author'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt?.toUtc() {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (this.expiresAt case final expiration?
        when expiration.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must not precede createdAt',
      );
    }
  }

  factory NarrativeDiagnosticSuppression.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final createdAt = json['createdAt'];
    final expiresAt = json['expiresAt'];
    if (schemaVersion is! int) {
      throw const FormatException('schemaVersion must be an integer.');
    }
    if (createdAt is! String) {
      throw const FormatException('createdAt must be an ISO-8601 string.');
    }
    if (expiresAt != null && expiresAt is! String) {
      throw const FormatException('expiresAt must be an ISO-8601 string.');
    }
    return NarrativeDiagnosticSuppression(
      schemaVersion: schemaVersion,
      diagnosticId: _jsonText(json, 'diagnosticId'),
      diagnosticFingerprint: _jsonText(json, 'diagnosticFingerprint'),
      reason: _jsonText(json, 'reason'),
      author: _jsonText(json, 'author'),
      createdAt: DateTime.parse(createdAt),
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt),
    );
  }

  final int schemaVersion;
  final String diagnosticId;
  final String diagnosticFingerprint;
  final String reason;
  final String author;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool isExpiredAt(DateTime instant) {
    final expiration = expiresAt;
    return expiration != null && !instant.toUtc().isBefore(expiration);
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'diagnosticId': diagnosticId,
        'diagnosticFingerprint': diagnosticFingerprint,
        'reason': reason,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

String _jsonText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name);
  return normalized;
}

String _fingerprint(String value) {
  final normalized = value.trim();
  if (!RegExp(_sha256FingerprintPattern).hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'diagnosticFingerprint',
      'must be a lowercase sha256 fingerprint',
    );
  }
  return normalized;
}
~~~~

### packages/map_core/lib/src/operations/narrative_validation_report_codec.dart

~~~~dart
import 'dart:convert';

import '../models/narrative_validation_report.dart';
import 'narrative_event_canonical_json.dart';

/// Stable RFC 8785 JSON representation used by local exports and CI.
String encodeNarrativeValidationReport(
  NarrativeMultidimensionalValidationReport report,
) =>
    canonicalizeNarrativeEventJson(report.toJson());

NarrativeMultidimensionalValidationReport decodeNarrativeValidationReport(
  String source,
) {
  final decoded = decodeNarrativeEventJsonStrict(source);
  if (decoded is! Map) {
    throw const FormatException(
        'Narrative validation report must be an object.');
  }
  return NarrativeMultidimensionalValidationReport.fromJson(
    Map<String, dynamic>.from(decoded),
  );
}

String narrativeValidationDiagnosticFingerprint(
  NarrativeMultidimensionalDiagnostic diagnostic,
) =>
    narrativeValidationPayloadFingerprint(diagnostic.toJson());

/// Shared fingerprint boundary for editor diagnostics which predate the
/// multidimensional publication contract.
String narrativeValidationPayloadFingerprint(Map<String, Object?> payload) =>
    narrativeEventBytesFingerprint(
      canonicalizeNarrativeEventJsonUtf8(payload),
    );

int narrativeValidationExitCode(NarrativeValidationStatus status) =>
    switch (status) {
      NarrativeValidationStatus.pass => 0,
      NarrativeValidationStatus.fail => 1,
      NarrativeValidationStatus.indeterminate => 2,
      NarrativeValidationStatus.notRun => 3,
    };

List<int> encodeNarrativeValidationReportUtf8(
  NarrativeMultidimensionalValidationReport report,
) =>
    utf8.encode(encodeNarrativeValidationReport(report));
~~~~

### packages/map_core/test/narrative_diagnostic_suppression_test.dart

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips an auditable versioned suppression', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'warning:event:evt_port',
      diagnosticFingerprint: 'sha256:${'a' * 64}',
      reason: 'Accepté pour la démo publique.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 20, 10),
      expiresAt: DateTime.utc(2026, 8),
    );

    final decoded = NarrativeDiagnosticSuppression.fromJson(
      suppression.toJson(),
    );

    expect(decoded.schemaVersion, 1);
    expect(decoded.diagnosticId, suppression.diagnosticId);
    expect(decoded.diagnosticFingerprint, suppression.diagnosticFingerprint);
    expect(decoded.reason, suppression.reason);
    expect(decoded.author, suppression.author);
    expect(decoded.createdAt, DateTime.utc(2026, 7, 20, 10));
    expect(decoded.expiresAt, DateTime.utc(2026, 8));
  });

  test('expiration is inclusive and evaluated against UTC', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'b' * 64}',
      reason: 'Dette suivie.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026, 7, 20),
      expiresAt: DateTime.utc(2026, 7, 21),
    );

    expect(
      suppression.isExpiredAt(DateTime.utc(2026, 7, 20, 23, 59)),
      isFalse,
    );
    expect(
      suppression.isExpiredAt(DateTime.utc(2026, 7, 21)),
      isTrue,
    );
  });

  test('rejects malformed fingerprints and incomplete audit fields', () {
    expect(
      () => NarrativeDiagnosticSuppression(
        diagnosticId: 'diagnostic',
        diagnosticFingerprint: 'not-a-fingerprint',
        reason: 'Raison',
        author: 'Auteur',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeDiagnosticSuppression(
        diagnosticId: 'diagnostic',
        diagnosticFingerprint: 'sha256:${'c' * 64}',
        reason: ' ',
        author: 'Auteur',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  test('atomic mutation cannot smuggle an unrelated manifest change', () {
    final before = ProjectManifest(
      name: 'Before',
      maps: const [],
      tilesets: const [],
    );
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'d' * 64}',
      reason: 'Décision auditée.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026),
    );

    expect(
      () => NarrativeDiagnosticSuppressionsUpdated(
        before: before,
        after: before.copyWith(
          name: 'Smuggled',
          narrativeDiagnosticSuppressions: [suppression],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      NarrativeDiagnosticSuppressionsUpdated(
        before: before,
        after: before.copyWith(
          narrativeDiagnosticSuppressions: [suppression],
        ),
      ).isApplicable,
      isTrue,
    );
  });

  test('project validator rejects two owners for one diagnostic', () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: 'diagnostic',
      diagnosticFingerprint: 'sha256:${'e' * 64}',
      reason: 'Décision auditée.',
      author: 'Auteur',
      createdAt: DateTime.utc(2026),
    );
    final project = ProjectManifest(
      name: 'Duplicate owner',
      maps: const [],
      tilesets: const [],
      narrativeDiagnosticSuppressions: [suppression, suppression],
    );

    expect(() => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()));
  });
}
~~~~

### packages/map_core/test/narrative_validation_report_codec_test.dart

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('encodes a stable canonical report and keeps verdicts distinct', () {
    final report = _report(NarrativeValidationStatus.indeterminate);

    final first = encodeNarrativeValidationReport(report);
    final second = encodeNarrativeValidationReport(
      decodeNarrativeValidationReport(first),
    );

    expect(second, first);
    expect(
      decodeNarrativeValidationReport(first).overallStatus,
      NarrativeValidationStatus.indeterminate,
    );
    expect(first, contains('"schemaVersion":1'));
  });

  test('diagnostic fingerprint is stable and content-sensitive', () {
    final diagnostic = NarrativeMultidimensionalDiagnostic(
      id: 'event:evt_port',
      code: 'sourceMissing',
      severity: 'warning',
      message: 'Source absente.',
      path: 'events.evt_port.source',
      provenance: const ['map:port', 'entity:rival'],
    );

    expect(
      narrativeValidationDiagnosticFingerprint(diagnostic),
      narrativeValidationDiagnosticFingerprint(
        NarrativeMultidimensionalDiagnostic.fromJson(diagnostic.toJson()),
      ),
    );
    expect(
      narrativeValidationDiagnosticFingerprint(diagnostic),
      isNot(
        narrativeValidationDiagnosticFingerprint(
          NarrativeMultidimensionalDiagnostic(
            id: diagnostic.id,
            code: diagnostic.code,
            severity: diagnostic.severity,
            message: 'Source corrigée.',
            path: diagnostic.path,
            provenance: diagnostic.provenance,
          ),
        ),
      ),
    );
  });

  test('maps all product statuses to their documented CI exit codes', () {
    expect(narrativeValidationExitCode(NarrativeValidationStatus.pass), 0);
    expect(narrativeValidationExitCode(NarrativeValidationStatus.fail), 1);
    expect(
      narrativeValidationExitCode(NarrativeValidationStatus.indeterminate),
      2,
    );
    expect(narrativeValidationExitCode(NarrativeValidationStatus.notRun), 3);
  });

  test('unknown status is rejected instead of degrading to pass', () {
    final encoded = encodeNarrativeValidationReport(
      _report(NarrativeValidationStatus.pass),
    ).replaceFirst('"status":"pass"', '"status":"unknown"');

    expect(
      () => decodeNarrativeValidationReport(encoded),
      throwsFormatException,
    );
  });
}

NarrativeMultidimensionalValidationReport _report(
  NarrativeValidationStatus narrativeStatus,
) {
  NarrativeValidationDimensionResult dimension(
    NarrativeValidationStatus status,
  ) =>
      NarrativeValidationDimensionResult(status: status);
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'selbrume-release-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'d' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: dimension(NarrativeValidationStatus.pass),
    narrativelySolvable: dimension(narrativeStatus),
    physicallyReachable: dimension(NarrativeValidationStatus.pass),
    runtimeSmokeVerified: dimension(NarrativeValidationStatus.pass),
  );
}
~~~~

### packages/map_editor/lib/src/application/services/narrative_diagnostic_suppression_service.dart

~~~~dart
import 'package:map_core/map_core.dart';

enum NarrativeDiagnosticStatus {
  active,
  suppressed,
  expiredSuppression,
  staleSuppression,
}

final class NarrativeDiagnosticSuppressionView {
  const NarrativeDiagnosticSuppressionView({
    required this.diagnostic,
    required this.status,
    this.suppression,
  });

  final NarrativeProjectDiagnostic diagnostic;
  final NarrativeDiagnosticStatus status;
  final NarrativeDiagnosticSuppression? suppression;

  bool get isVisible => status != NarrativeDiagnosticStatus.suppressed;
}

final class NarrativeDiagnosticSuppressionSnapshot {
  NarrativeDiagnosticSuppressionSnapshot({
    required List<NarrativeDiagnosticSuppressionView> diagnostics,
    required List<NarrativeDiagnosticSuppression> resolvedSuppressions,
  })  : diagnostics = List.unmodifiable(diagnostics),
        resolvedSuppressions = List.unmodifiable(resolvedSuppressions);

  final List<NarrativeDiagnosticSuppressionView> diagnostics;
  final List<NarrativeDiagnosticSuppression> resolvedSuppressions;
}

final class NarrativeDiagnosticSuppressionRejected implements Exception {
  const NarrativeDiagnosticSuppressionRejected(this.message);

  final String message;

  @override
  String toString() => 'NarrativeDiagnosticSuppressionRejected: $message';
}

typedef PersistNarrativeProject = Future<void> Function(
  ProjectManifest project,
);

/// Adds publication-only diagnostics (notably physical/runtime evidence) to
/// the historical authoring report without duplicating diagnostics already
/// projected by the coordinator from that report.
NarrativeProjectValidationReport mergeNarrativePublicationDiagnostics({
  required NarrativeProjectValidationReport authoringReport,
  NarrativeMultidimensionalValidationReport? publicationReport,
}) {
  if (publicationReport == null) return authoringReport;
  final knownPublicationIds = authoringReport.diagnostics
      .map((diagnostic) => diagnostic.stableKey)
      .toSet();
  final merged = authoringReport.diagnostics.toList(growable: true);
  void append(
    NarrativeValidationDimension dimension,
    NarrativeValidationDimensionResult result,
  ) {
    for (final diagnostic in result.diagnostics) {
      if (!knownPublicationIds.add(diagnostic.id)) continue;
      merged.add(_publicationDiagnostic(dimension, diagnostic));
    }
  }

  append(
    NarrativeValidationDimension.structurallyValid,
    publicationReport.structurallyValid,
  );
  append(
    NarrativeValidationDimension.narrativelySolvable,
    publicationReport.narrativelySolvable,
  );
  append(
    NarrativeValidationDimension.physicallyReachable,
    publicationReport.physicallyReachable,
  );
  append(
    NarrativeValidationDimension.runtimeSmokeVerified,
    publicationReport.runtimeSmokeVerified,
  );
  return NarrativeProjectValidationReport(
    diagnostics: merged,
    mapEventViews: authoringReport.mapEventViews,
    symbolicReachability: authoringReport.symbolicReachability,
  );
}

/// Builds and persists suppression decisions without ever mutating the source
/// snapshot before durable persistence succeeds.
final class NarrativeDiagnosticSuppressionService {
  const NarrativeDiagnosticSuppressionService();

  String fingerprint(NarrativeProjectDiagnostic diagnostic) =>
      narrativeValidationPayloadFingerprint({
        'id': diagnostic.stableKey,
        'code': diagnostic.code,
        'severity': diagnostic.severity.name,
        'domain': diagnostic.domain.name,
        'message': diagnostic.message,
        'path': diagnostic.path,
        'destination': diagnostic.destination.name,
        'mapId': diagnostic.mapId,
        'eventId': diagnostic.eventId,
        'sceneId': diagnostic.sceneId,
        'dialogueId': diagnostic.dialogueId,
        'cinematicId': diagnostic.cinematicId,
        'storylineId': diagnostic.storylineId,
        'chapterId': diagnostic.chapterId,
        'stepId': diagnostic.stepId,
        'factId': diagnostic.factId,
        'worldRuleId': diagnostic.worldRuleId,
      });

  NarrativeDiagnosticSuppressionSnapshot buildSnapshot({
    required ProjectManifest project,
    required Iterable<NarrativeProjectDiagnostic> diagnostics,
    DateTime? now,
  }) {
    final instant = (now ?? DateTime.now()).toUtc();
    final current = diagnostics.toList(growable: false);
    final currentIds = current.map((item) => item.stableKey).toSet();
    final suppressionsById = <String, List<NarrativeDiagnosticSuppression>>{};
    for (final suppression in project.narrativeDiagnosticSuppressions) {
      suppressionsById
          .putIfAbsent(suppression.diagnosticId, () => [])
          .add(suppression);
    }
    return NarrativeDiagnosticSuppressionSnapshot(
      diagnostics: [
        for (final diagnostic in current)
          _viewFor(
            diagnostic,
            suppressionsById[diagnostic.stableKey] ?? const [],
            instant,
          ),
      ],
      resolvedSuppressions: [
        for (final suppression in project.narrativeDiagnosticSuppressions)
          if (!currentIds.contains(suppression.diagnosticId)) suppression,
      ],
    );
  }

  Future<ProjectManifest> suppress({
    required ProjectManifest project,
    required NarrativeProjectDiagnostic diagnostic,
    required String reason,
    required String author,
    required PersistNarrativeProject persist,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) async {
    final next = planSuppression(
      project: project,
      diagnostic: diagnostic,
      reason: reason,
      author: author,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
    await persist(next);
    return next;
  }

  ProjectManifest planSuppression({
    required ProjectManifest project,
    required NarrativeProjectDiagnostic diagnostic,
    required String reason,
    required String author,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    if (diagnostic.severity == NarrativeProjectDiagnosticSeverity.error) {
      throw const NarrativeDiagnosticSuppressionRejected(
        'Une erreur bloquante de release ne peut pas être supprimée.',
      );
    }
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: diagnostic.stableKey,
      diagnosticFingerprint: fingerprint(diagnostic),
      reason: reason,
      author: author,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      expiresAt: expiresAt,
    );
    return project.copyWith(
      narrativeDiagnosticSuppressions: [
        for (final item in project.narrativeDiagnosticSuppressions)
          if (item.diagnosticId != diagnostic.stableKey) item,
        suppression,
      ],
    );
  }

  Future<ProjectManifest> remove({
    required ProjectManifest project,
    required String diagnosticId,
    required PersistNarrativeProject persist,
  }) async {
    final next = planRemoval(
      project: project,
      diagnosticId: diagnosticId,
    );
    await persist(next);
    return next;
  }

  ProjectManifest planRemoval({
    required ProjectManifest project,
    required String diagnosticId,
  }) {
    return project.copyWith(
      narrativeDiagnosticSuppressions: [
        for (final item in project.narrativeDiagnosticSuppressions)
          if (item.diagnosticId != diagnosticId) item,
      ],
    );
  }

  NarrativeDiagnosticSuppressionView _viewFor(
    NarrativeProjectDiagnostic diagnostic,
    List<NarrativeDiagnosticSuppression> suppressions,
    DateTime now,
  ) {
    final expectedFingerprint = fingerprint(diagnostic);
    NarrativeDiagnosticSuppression? expired;
    NarrativeDiagnosticSuppression? stale;
    for (final suppression in suppressions.reversed) {
      if (suppression.diagnosticFingerprint != expectedFingerprint) {
        stale ??= suppression;
      } else if (suppression.isExpiredAt(now)) {
        expired ??= suppression;
      } else {
        return NarrativeDiagnosticSuppressionView(
          diagnostic: diagnostic,
          status: NarrativeDiagnosticStatus.suppressed,
          suppression: suppression,
        );
      }
    }
    if (expired != null) {
      return NarrativeDiagnosticSuppressionView(
        diagnostic: diagnostic,
        status: NarrativeDiagnosticStatus.expiredSuppression,
        suppression: expired,
      );
    }
    if (stale != null) {
      return NarrativeDiagnosticSuppressionView(
        diagnostic: diagnostic,
        status: NarrativeDiagnosticStatus.staleSuppression,
        suppression: stale,
      );
    }
    return NarrativeDiagnosticSuppressionView(
      diagnostic: diagnostic,
      status: NarrativeDiagnosticStatus.active,
    );
  }
}

final class NarrativeValidatorQuickFix {
  NarrativeValidatorQuickFix({
    required String diagnosticId,
    required String label,
    required String preview,
    required this.before,
    required this.after,
    required this.deterministic,
    required this.reversible,
  })  : diagnosticId = _requiredText(diagnosticId, 'diagnosticId'),
        label = _requiredText(label, 'label'),
        preview = _requiredText(preview, 'preview');

  final String diagnosticId;
  final String label;
  final String preview;
  final ProjectManifest before;
  final ProjectManifest after;
  final bool deterministic;
  final bool reversible;

  ProjectManifest get rollback => before;
}

final class NarrativeValidatorQuickFixRejected implements Exception {
  const NarrativeValidatorQuickFixRejected(this.message);

  final String message;

  @override
  String toString() => 'NarrativeValidatorQuickFixRejected: $message';
}

final class NarrativeValidatorQuickFixService {
  const NarrativeValidatorQuickFixService();

  Future<ProjectManifest> apply({
    required ProjectManifest current,
    required NarrativeValidatorQuickFix quickFix,
    required bool previewAccepted,
    required PersistNarrativeProject persist,
  }) async {
    if (!identical(current, quickFix.before) ||
        !quickFix.deterministic ||
        !quickFix.reversible ||
        !previewAccepted) {
      throw const NarrativeValidatorQuickFixRejected(
        'La correction doit être déterministe, prévisualisée et réversible.',
      );
    }
    await persist(quickFix.after);
    return quickFix.after;
  }
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name);
  return normalized;
}

NarrativeProjectDiagnostic _publicationDiagnostic(
  NarrativeValidationDimension dimension,
  NarrativeMultidimensionalDiagnostic diagnostic,
) {
  final segments = diagnostic.path.split('.');
  String? segmentAfter(String owner) {
    final index = segments.indexOf(owner);
    return index >= 0 && index + 1 < segments.length
        ? segments[index + 1]
        : null;
  }

  final mapId = segmentAfter('maps');
  final eventId = segments.length > 2 &&
          segments[0] == 'eventRegistry' &&
          segments[1] == 'records'
      ? segments[2]
      : null;
  final sceneId = segmentAfter('scenes');
  final storylineId = segmentAfter('storylines');
  final cinematicId = segmentAfter('cinematics');
  final factId = segmentAfter('facts');
  final worldRuleId = segmentAfter('worldRules');
  final route = switch ((
    mapId,
    eventId,
    sceneId,
    storylineId,
    cinematicId,
    factId,
    worldRuleId,
  )) {
    (final String id, _, _, _, _, _, _) => (
        NarrativeProjectDiagnosticDomain.map,
        NarrativeProjectDiagnosticDestination.map,
        id,
      ),
    (_, final String id, _, _, _, _, _) => (
        NarrativeProjectDiagnosticDomain.event,
        NarrativeProjectDiagnosticDestination.event,
        id,
      ),
    (_, _, final String id, _, _, _, _) => (
        NarrativeProjectDiagnosticDomain.scene,
        NarrativeProjectDiagnosticDestination.scene,
        id,
      ),
    (_, _, _, final String id, _, _, _) => (
        NarrativeProjectDiagnosticDomain.storyline,
        NarrativeProjectDiagnosticDestination.storyline,
        id,
      ),
    (_, _, _, _, final String id, _, _) => (
        NarrativeProjectDiagnosticDomain.cinematic,
        NarrativeProjectDiagnosticDestination.cinematic,
        id,
      ),
    (_, _, _, _, _, final String id, _) => (
        NarrativeProjectDiagnosticDomain.fact,
        NarrativeProjectDiagnosticDestination.fact,
        id,
      ),
    (_, _, _, _, _, _, final String id) => (
        NarrativeProjectDiagnosticDomain.worldRule,
        NarrativeProjectDiagnosticDestination.worldRule,
        id,
      ),
    _ => (
        dimension == NarrativeValidationDimension.runtimeSmokeVerified
            ? NarrativeProjectDiagnosticDomain.runtime
            : NarrativeProjectDiagnosticDomain.map,
        NarrativeProjectDiagnosticDestination.overview,
        null,
      ),
  };
  return NarrativeProjectDiagnostic(
    code: diagnostic.code,
    severity: switch (diagnostic.severity) {
      'error' => NarrativeProjectDiagnosticSeverity.error,
      'warning' => NarrativeProjectDiagnosticSeverity.warning,
      _ => NarrativeProjectDiagnosticSeverity.info,
    },
    domain: route.$1,
    message: diagnostic.provenance.isEmpty
        ? diagnostic.message
        : '${diagnostic.message} Dépendances : ${diagnostic.provenance.join(' → ')}.',
    path: diagnostic.path,
    destination: route.$2,
    suggestedFixLabel:
        'Consulter ce verdict, ses preuves et ses limites avant de décider.',
    mapId: mapId,
    eventId: eventId,
    sceneId: sceneId,
    storylineId: storylineId,
    cinematicId: cinematicId,
    factId: factId,
    worldRuleId: worldRuleId,
  );
}
~~~~

### packages/map_editor/test/narrative_diagnostic_suppression_service_test.dart

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_diagnostic_suppression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const warning = NarrativeProjectDiagnostic(
    code: 'readableLabelMatchesId',
    severity: NarrativeProjectDiagnosticSeverity.warning,
    domain: NarrativeProjectDiagnosticDomain.event,
    message: 'Le label lisible reprend l’identifiant technique.',
    path: 'eventRegistry.records.evt_port.label',
    destination: NarrativeProjectDiagnosticDestination.event,
    eventId: 'evt_port',
  );
  const service = NarrativeDiagnosticSuppressionService();

  test('persists then reloads an active suppression from ProjectManifest JSON',
      () async {
    final project = _project();
    ProjectManifest? persisted;

    final updated = await service.suppress(
      project: project,
      diagnostic: warning,
      reason: 'Dette cosmétique acceptée pour la démo.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 20),
      persist: (next) async => persisted = next,
    );
    final reloaded = ProjectManifest.fromJson(persisted!.toJson());
    final snapshot = service.buildSnapshot(
      project: reloaded,
      diagnostics: const [warning],
      now: DateTime.utc(2026, 7, 20, 12),
    );

    expect(updated.narrativeDiagnosticSuppressions, hasLength(1));
    expect(snapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.suppressed);
    expect(snapshot.resolvedSuppressions, isEmpty);
  });

  test('expired and stale suppressions never hide the current diagnostic', () {
    final fingerprint = service.fingerprint(warning);
    final expired = NarrativeDiagnosticSuppression(
      diagnosticId: warning.stableKey,
      diagnosticFingerprint: fingerprint,
      reason: 'Expiration volontaire.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
      expiresAt: DateTime.utc(2026, 7, 10),
    );
    final changedWarning = NarrativeProjectDiagnostic(
      code: warning.code,
      severity: warning.severity,
      domain: warning.domain,
      message: '${warning.message} Nouveau contexte.',
      path: warning.path,
      destination: warning.destination,
      eventId: warning.eventId,
    );
    final stale = NarrativeDiagnosticSuppression(
      diagnosticId: changedWarning.stableKey,
      diagnosticFingerprint: 'sha256:${'0' * 64}',
      reason: 'Ancien contenu.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
    );

    final expiredSnapshot = service.buildSnapshot(
      project: _project(suppressions: [expired]),
      diagnostics: const [warning],
      now: DateTime.utc(2026, 7, 20),
    );
    final staleSnapshot = service.buildSnapshot(
      project: _project(suppressions: [stale]),
      diagnostics: [changedWarning],
      now: DateTime.utc(2026, 7, 20),
    );

    expect(expiredSnapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.expiredSuppression);
    expect(staleSnapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.staleSuppression);
  });

  test('a suppression whose diagnostic disappeared is reported as resolved',
      () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: warning.stableKey,
      diagnosticFingerprint: service.fingerprint(warning),
      reason: 'Dette désormais corrigée.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
    );

    final snapshot = service.buildSnapshot(
      project: _project(suppressions: [suppression]),
      diagnostics: const [],
      now: DateTime.utc(2026, 7, 20),
    );

    expect(snapshot.resolvedSuppressions, [suppression]);
  });

  test('release-blocking errors cannot be suppressed', () async {
    final error = NarrativeProjectDiagnostic(
      code: warning.code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: warning.domain,
      message: warning.message,
      path: warning.path,
      destination: warning.destination,
      eventId: warning.eventId,
    );

    expect(
      () => service.suppress(
        project: _project(),
        diagnostic: error,
        reason: 'Tentative invalide.',
        author: 'Karim',
        persist: (_) async {},
      ),
      throwsA(isA<NarrativeDiagnosticSuppressionRejected>()),
    );
  });

  test('persistence failure leaves the immutable source project unchanged',
      () async {
    final project = _project();

    expect(
      () => service.suppress(
        project: project,
        diagnostic: warning,
        reason: 'Ne doit pas survivre.',
        author: 'Karim',
        persist: (_) async => throw StateError('disk full'),
      ),
      throwsStateError,
    );
    expect(project.narrativeDiagnosticSuppressions, isEmpty);
  });

  test('merges publication-only physical diagnostics without duplicating core',
      () {
    final authoring = NarrativeProjectValidationReport(
      diagnostics: const [warning],
      mapEventViews: const [],
    );
    final publication = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'v1',
      profileId: 'profile',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'9' * 64}',
      generatedAt: DateTime.utc(2026),
      structurallyValid: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
        diagnostics: [
          NarrativeMultidimensionalDiagnostic(
            id: warning.stableKey,
            code: warning.code,
            severity: 'warning',
            message: warning.message,
            path: warning.path,
          ),
        ],
      ),
      narrativelySolvable: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
      ),
      physicallyReachable: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.indeterminate,
        diagnostics: [
          NarrativeMultidimensionalDiagnostic(
            id: 'physical:blocked:evt_port',
            code: 'explorationBudgetExceeded',
            severity: 'warning',
            message: 'Budget physique dépassé.',
            path: 'maps.map_port',
            provenance: const ['spawn:start', 'event:evt_port'],
          ),
        ],
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
      ),
    );

    final merged = mergeNarrativePublicationDiagnostics(
      authoringReport: authoring,
      publicationReport: publication,
    );

    expect(merged.diagnostics, hasLength(2));
    expect(merged.diagnostics.last.mapId, 'map_port');
    expect(merged.diagnostics.last.destination,
        NarrativeProjectDiagnosticDestination.map);
    expect(merged.diagnostics.last.message, contains('spawn:start'));
  });
}

ProjectManifest _project({
  List<NarrativeDiagnosticSuppression> suppressions = const [],
}) =>
    ProjectManifest(
      name: 'Suppression test',
      maps: const [],
      tilesets: const [],
      narrativeDiagnosticSuppressions: suppressions,
    );
~~~~

### packages/map_editor/test/narrative_validator_quick_fix_test.dart

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_diagnostic_suppression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies only a previewed deterministic reversible project mutation',
      () async {
    const before = ProjectManifest(
      name: 'Before',
      maps: [],
      tilesets: [],
    );
    final after = before.copyWith(name: 'After');
    final quickFix = NarrativeValidatorQuickFix(
      diagnosticId: 'warning:projectName',
      label: 'Renommer le projet',
      preview: 'Before → After',
      before: before,
      after: after,
      deterministic: true,
      reversible: true,
    );
    ProjectManifest? persisted;

    final result = await const NarrativeValidatorQuickFixService().apply(
      current: before,
      quickFix: quickFix,
      previewAccepted: true,
      persist: (project) async => persisted = project,
    );

    expect(result.name, 'After');
    expect(persisted, same(after));
    expect(quickFix.rollback, same(before));
  });

  test('refuses missing preview and does not expose failed persistence',
      () async {
    const before = ProjectManifest(
      name: 'Before',
      maps: [],
      tilesets: [],
    );
    final quickFix = NarrativeValidatorQuickFix(
      diagnosticId: 'warning:projectName',
      label: 'Renommer le projet',
      preview: 'Before → After',
      before: before,
      after: before.copyWith(name: 'After'),
      deterministic: true,
      reversible: true,
    );
    const service = NarrativeValidatorQuickFixService();

    expect(
      () => service.apply(
        current: before,
        quickFix: quickFix,
        previewAccepted: false,
        persist: (_) async {},
      ),
      throwsA(isA<NarrativeValidatorQuickFixRejected>()),
    );
    expect(
      () => service.apply(
        current: before,
        quickFix: quickFix,
        previewAccepted: true,
        persist: (_) async => throw StateError('write rejected'),
      ),
      throwsStateError,
    );
    expect(before.name, 'Before');
  });
}
~~~~

### packages/map_editor/test/validate_narrative_project_cli_test.dart

~~~~dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

void main() {
  test('process preserves pass, fail, indeterminate and notRun exit codes',
      () async {
    final temporary = await Directory.systemTemp.createTemp(
      'pokemap_narrative_validator_cli_',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final cases = <NarrativeValidationStatus, int>{
      NarrativeValidationStatus.pass: 0,
      NarrativeValidationStatus.fail: 1,
      NarrativeValidationStatus.indeterminate: 2,
      NarrativeValidationStatus.notRun: 3,
    };

    for (final entry in cases.entries) {
      final input = File(p.join(temporary.path, '${entry.key.name}.json'));
      final output = File(
        p.join(temporary.path, '${entry.key.name}.output.json'),
      );
      await input.writeAsString(
        encodeNarrativeValidationReport(_report(entry.key)),
      );

      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/validate_narrative_project.dart',
          '--report-input',
          input.path,
          '--format',
          'json',
          '--output',
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, entry.value, reason: '${result.stderr}');
      expect(
        decodeNarrativeValidationReport(await output.readAsString())
            .overallStatus,
        entry.key,
      );
    }
  });

  test('usage errors are code 64 and never become a product verdict', () async {
    final result = await Process.run(
      'dart',
      [
        'run',
        'tool/validate_narrative_project.dart',
        '--format',
        'yaml',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 64);
    expect('${result.stderr}', contains('Only "--format json"'));
  });
}

NarrativeMultidimensionalValidationReport _report(
  NarrativeValidationStatus status,
) {
  NarrativeValidationDimensionResult dimension(
    NarrativeValidationStatus value,
  ) =>
      NarrativeValidationDimensionResult(status: value);
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'selbrume-release-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'e' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: dimension(status),
    narrativelySolvable: dimension(NarrativeValidationStatus.pass),
    physicallyReachable: dimension(NarrativeValidationStatus.pass),
    runtimeSmokeVerified: dimension(NarrativeValidationStatus.pass),
  );
}
~~~~

### packages/map_editor/tool/validate_narrative_project.dart

~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/services/narrative_studio_validation_coordinator.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

const _usageExitCode = 64;
const _softwareExitCode = 70;

Future<void> main(List<String> arguments) async {
  final invocation = _parseArguments(arguments);
  if (invocation case _CliUsageError(:final message)) {
    stderr.writeln(message);
    stderr.writeln(_usage);
    exit(_usageExitCode);
  }
  if (invocation is _CliHelp) {
    stdout.writeln(_usage);
    return;
  }
  final command = invocation as _CliCommand;
  try {
    final report = command.reportInput == null
        ? await _validateProject(command)
        : decodeNarrativeValidationReport(
            await File(command.reportInput!).readAsString(),
          );
    final encoded = encodeNarrativeValidationReport(report);
    final output = command.output;
    if (output == null) {
      stdout.writeln(encoded);
    } else {
      await _writeAtomically(File(output), '$encoded\n');
      stdout.writeln(
        '${report.overallStatus.name}: ${p.normalize(p.absolute(output))}',
      );
    }
    exit(narrativeValidationExitCode(report.overallStatus));
  } on Object catch (error) {
    stderr.writeln('Narrative validation unavailable: $error');
    exit(_softwareExitCode);
  }
}

Future<NarrativeMultidimensionalValidationReport> _validateProject(
  _CliCommand command,
) async {
  final projectRoot = p.normalize(p.absolute(command.projectRoot!));
  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(projectRoot, 'project.json'),
  );
  final catalogs = await _loadPokemonCatalogs(
    projectRoot,
    enabled: session.manifest.pokemon.enabled,
  );
  final projectReport = validateNarrativeProject(
    session.manifest,
    maps: session.maps,
    knownSpeciesIds: catalogs.speciesIds,
    knownMoveIds: catalogs.moveIds,
    requirePokemonCatalogs: session.manifest.pokemon.enabled,
  );
  const receiptRepository = NarrativeRuntimeSmokeReceiptRepository();
  final fingerprint =
      await receiptRepository.computeProjectFingerprint(projectRoot);
  final receipt = await receiptRepository.read(
    projectRoot: projectRoot,
    expectedFingerprint: fingerprint,
    profile: selbrumeReleaseV1Profile,
  );
  return const NarrativeStudioValidationCoordinator().coordinate(
    project: session.manifest,
    maps: session.maps,
    projectReport: projectReport,
    projectFingerprint: fingerprint,
    profile: selbrumeReleaseV1Profile,
    runtimeReceipt: receipt,
  );
}

Future<({Set<String>? speciesIds, Set<String>? moveIds})> _loadPokemonCatalogs(
  String projectRoot, {
  required bool enabled,
}) async {
  if (!enabled) {
    return (speciesIds: const <String>{}, moveIds: const <String>{});
  }
  final workspace = ProjectFileSystem(projectRoot);
  const reader = PokemonProjectDataReader();
  Set<String>? speciesIds;
  Set<String>? moveIds;
  try {
    speciesIds = {
      for (final entry in await reader.listSpeciesIndexEntries(workspace))
        entry.id,
    };
  } on Object {
    speciesIds = null;
  }
  try {
    final catalog = await reader.readCatalogByKey(workspace, 'moves');
    moveIds = {
      for (final entry in catalog.entries)
        if (entry['id'] case final String id) id,
    };
  } on Object {
    moveIds = null;
  }
  return (speciesIds: speciesIds, moveIds: moveIds);
}

Future<void> _writeAtomically(File output, String contents) async {
  await output.parent.create(recursive: true);
  final temporary = File('${output.path}.$pid.tmp');
  try {
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(output.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

sealed class _CliInvocation {
  const _CliInvocation();
}

final class _CliCommand extends _CliInvocation {
  const _CliCommand({
    required this.projectRoot,
    required this.reportInput,
    required this.output,
  });

  final String? projectRoot;
  final String? reportInput;
  final String? output;
}

final class _CliHelp extends _CliInvocation {
  const _CliHelp();
}

final class _CliUsageError extends _CliInvocation {
  const _CliUsageError(this.message);

  final String message;
}

_CliInvocation _parseArguments(List<String> arguments) {
  if (arguments.length == 1 &&
      (arguments.single == '--help' || arguments.single == '-h')) {
    return const _CliHelp();
  }
  String? projectRoot;
  String? profile;
  String? format;
  String? output;
  String? reportInput;
  for (var index = 0; index < arguments.length; index++) {
    final option = arguments[index];
    if (!const {
      '--project-root',
      '--profile',
      '--format',
      '--output',
      '--report-input',
    }.contains(option)) {
      return _CliUsageError('Unknown option "$option".');
    }
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      return _CliUsageError('Missing value for "$option".');
    }
    final value = arguments[++index].trim();
    if (value.isEmpty) return _CliUsageError('Blank value for "$option".');
    switch (option) {
      case '--project-root':
        projectRoot = value;
      case '--profile':
        profile = value;
      case '--format':
        format = value;
      case '--output':
        output = value;
      case '--report-input':
        reportInput = value;
    }
  }
  if (format != 'json') {
    return const _CliUsageError('Only "--format json" is supported.');
  }
  if ((projectRoot == null) == (reportInput == null)) {
    return const _CliUsageError(
      'Provide exactly one of --project-root or --report-input.',
    );
  }
  if (projectRoot != null && profile != selbrumeReleaseV1Profile.id) {
    return _CliUsageError(
      'Project validation requires "--profile ${selbrumeReleaseV1Profile.id}".',
    );
  }
  if (reportInput != null && profile != null) {
    return const _CliUsageError(
      '--profile cannot be combined with --report-input.',
    );
  }
  return _CliCommand(
    projectRoot: projectRoot,
    reportInput: reportInput,
    output: output,
  );
}

const _usage = '''
Usage:
  dart run tool/validate_narrative_project.dart \\
    --project-root <path> --profile selbrume-release-v1 \\
    --format json [--output <path>]

  dart run tool/validate_narrative_project.dart \\
    --report-input <report.json> --format json [--output <path>]

Exit codes: 0=pass, 1=fail, 2=indeterminate, 3=notRun, 64=usage.
''';
~~~~

### reports/narrativeStudio/completion/selbrume_narrative_validation_report.json

~~~~json
{"dimensions":{"narrativelySolvable":{"diagnostics":[{"code":"narrativeSolvabilityIndeterminate","id":"error\u001fscene\u001fnarrativeSolvabilityIndeterminate\u001fscenes.\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Le budget symbolique global de 16384 états est dépassé.","path":"scenes.","provenance":[],"severity":"error"},{"code":"narrativeSolvabilityIndeterminate","id":"error\u001fscene\u001fnarrativeSolvabilityIndeterminate\u001fscenes.scene_crystal_3\u001f\u001fevt_019abcde-5000-7000-8000-000000000019\u001fscene_crystal_3\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Le budget symbolique global de 16384 états est dépassé avant l’Event evt_019abcde-5000-7000-8000-000000000019.","path":"scenes.scene_crystal_3","provenance":[],"severity":"error"},{"code":"narrativeSolvabilityIndeterminate","id":"warning\u001fscene\u001fnarrativeSolvabilityIndeterminate\u001fscenes.scene_crystal_2.nodes.node_end\u001f\u001fevt_019abcde-5000-7000-8000-000000000018\u001fscene_crystal_2\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Le budget symbolique de 3 états est dépassé.","path":"scenes.scene_crystal_2.nodes.node_end","provenance":[],"severity":"warning"}],"evidenceRefs":["symbolic-states:16384"],"limitations":["Le budget symbolique de 3 états est dépassé.","Le budget symbolique global de 16384 états est dépassé avant l’Event evt_019abcde-5000-7000-8000-000000000019.","Le budget symbolique global de 16384 états est dépassé."],"status":"indeterminate"},"physicallyReachable":{"diagnostics":[{"code":"explorationBudgetExceeded","id":"physical:explorationBudgetExceeded::","message":"Le budget physique global de 32768 recherches est dépassé.","path":"maps","provenance":[],"severity":"warning"}],"evidenceRefs":[],"limitations":["Le budget physique global de 32768 recherches est dépassé."],"status":"indeterminate"},"runtimeSmokeVerified":{"diagnostics":[],"evidenceRefs":[".pokemap/validation/narrative_runtime_smoke_receipt.json","suite:selbrume-lighthouse-retry","suite:selbrume-player-journey"],"limitations":[],"status":"pass"},"structurallyValid":{"diagnostics":[{"code":"outcome.rawTechnicalLabel","id":"warning\u001fevent\u001foutcome.rawTechnicalLabel\u001foutcomes.battle.trainer:grant.defeat\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Readable label matches the technical id.","path":"outcomes.battle.trainer:grant.defeat","provenance":[],"severity":"warning"},{"code":"outcome.rawTechnicalLabel","id":"warning\u001fevent\u001foutcome.rawTechnicalLabel\u001foutcomes.battle.trainer:grant.victory\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Readable label matches the technical id.","path":"outcomes.battle.trainer:grant.victory","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_goelise_nest_choice.keep_item\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_goelise_nest_choice.keep_item","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_goelise_nest_choice.return_item\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_goelise_nest_choice.return_item","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_lysa_port.aggressive\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_lysa_port.aggressive","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_lysa_port.confident\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_lysa_port.confident","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_lysa_port.hesitant\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_lysa_port.hesitant","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_mado_intro.accept_help\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_mado_intro.accept_help","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_mado_intro.refuse_for_now\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_mado_intro.refuse_for_now","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_mael_intro.starter_bulbasaur\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_mael_intro.starter_bulbasaur","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_mael_intro.starter_charmander\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_mael_intro.starter_charmander","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_mael_intro.starter_squirtle\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_mael_intro.starter_squirtle","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_port_alert.panic\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_port_alert.panic","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_port_alert.reassure\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_port_alert.reassure","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_port_entry.panic\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_port_entry.panic","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_port_entry.reassure\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_port_entry.reassure","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_yvon_intro.accept_search_key\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_yvon_intro.accept_search_key","provenance":[],"severity":"warning"},{"code":"outcome.yarnOutcomeNotReEmitted","id":"warning\u001fevent\u001foutcome.yarnOutcomeNotReEmitted\u001foutcomes.scene.scene_yvon_intro.ignore_for_now\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Ce résultat de dialogue doit être réémis par une fin de Scene.","path":"outcomes.scene.scene_yvon_intro.ignore_for_now","provenance":[],"severity":"warning"},{"code":"setFlagNeverRead","id":"warning\u001ffact\u001fsetFlagNeverRead\u001fscenarios.p6_03_first_interaction.nodes.set_seen_flag\u001f\u001f\u001fp6_03_first_interaction\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Flag \"p6.selbrume.first_interaction.seen\" is set but never read.","path":"scenarios.p6_03_first_interaction.nodes.set_seen_flag","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_cabin_journal.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_cabin_journal\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_cabin_journal.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_cabin_key.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_cabin_key\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_cabin_key.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_clue_electric_tracks.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_clue_electric_tracks\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_clue_electric_tracks.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_clue_glass.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_clue_glass\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_clue_glass.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_clue_lighthouse_mark.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_clue_lighthouse_mark\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_clue_lighthouse_mark.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_crystal_1.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_crystal_1\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_crystal_1.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_crystal_2.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_crystal_2\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_crystal_2.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_crystal_3.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_crystal_3\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_crystal_3.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_ending_port.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_ending_port\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_ending_port.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_goelise_fisher_intro.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_goelise_fisher_intro\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_goelise_fisher_intro.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_goelise_keep_reward.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_goelise_keep_reward\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_goelise_keep_reward.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_goelise_nest_choice.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_goelise_nest_choice\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_goelise_nest_choice.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_goelise_return.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_goelise_return\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_goelise_return.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_lighthouse_arrival.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_lighthouse_arrival\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_lighthouse_arrival.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_lighthouse_old_note.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_lighthouse_old_note\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_lighthouse_old_note.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_lysa_port.nodes.node_defeat_end.outcomePolicy\u001f\u001f\u001fscene_lysa_port\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Défaite contre Lysa » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_lysa_port.nodes.node_defeat_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_lysa_port.nodes.node_victory_end.outcomePolicy\u001f\u001f\u001fscene_lysa_port\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Victoire contre Lysa » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_lysa_port.nodes.node_victory_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_mado_crystals_return.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_mado_crystals_return\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_mado_crystals_return.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_mado_intro.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_mado_intro\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_mado_intro.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_mael_intro.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_mael_intro\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_mael_intro.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_marais_entry.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_marais_entry\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_marais_entry.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_port_alert.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_port_alert\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_port_alert.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_port_entry.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_port_entry\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_port_entry.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_rival_after_loss.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_rival_after_loss\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_rival_after_loss.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_rival_after_win.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_rival_after_win\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_rival_after_win.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_soline_unlock_passage.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_soline_unlock_passage\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_soline_unlock_passage.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_test.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_test\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_test.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_test.nodes.node_end_2.outcomePolicy\u001f\u001f\u001fscene_test\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_test.nodes.node_end_2.outcomePolicy","provenance":[],"severity":"warning"},{"code":"sceneOutcomePolicyIndeterminate","id":"warning\u001fscene\u001fsceneOutcomePolicyIndeterminate\u001fscenes.scene_yvon_intro.nodes.node_end.outcomePolicy\u001f\u001f\u001fscene_yvon_intro\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"La fin « Fin » ne déclare pas si elle fait progresser, autorise un nouvel essai ou accepte un échec terminal. Le Validator ne peut pas l’inférer depuis son label.","path":"scenes.scene_yvon_intro.nodes.node_end.outcomePolicy","provenance":[],"severity":"warning"},{"code":"completeStepNeverRead","id":"warning\u001fstoryline\u001fcompleteStepNeverRead\u001fscenarios.p6_03_first_interaction.nodes.complete_intro_step\u001f\u001f\u001fp6_03_first_interaction\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Step \"p6.selbrume.first_interaction\" is completed but never read.","path":"scenarios.p6_03_first_interaction.nodes.complete_intro_step","provenance":[],"severity":"warning"},{"code":"scenarioGraphHasNoSource","id":"warning\u001fstoryline\u001fscenarioGraphHasNoSource\u001fscenarios.global_story.nodes\u001f\u001f\u001fglobal_story\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Scenario \"global_story\" has no runtime source node.","path":"scenarios.global_story.nodes","provenance":[],"severity":"warning"},{"code":"scenarioGraphHasUnreachableNode","id":"warning\u001fstoryline\u001fscenarioGraphHasUnreachableNode\u001fscenarios.p6_03_first_interaction.nodes.start\u001f\u001f\u001fp6_03_first_interaction\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Scenario \"p6_03_first_interaction\" has unreachable node \"start\".","path":"scenarios.p6_03_first_interaction.nodes.start","provenance":[],"severity":"warning"},{"code":"scenarioGraphHasUnreachableNode","id":"warning\u001fstoryline\u001fscenarioGraphHasUnreachableNode\u001fscenarios.test.nodes.start\u001f\u001f\u001ftest\u001f\u001f\u001f\u001f\u001f\u001f\u001f","message":"Scenario \"test\" has unreachable node \"start\".","path":"scenarios.test.nodes.start","provenance":[],"severity":"warning"}],"evidenceRefs":[],"limitations":[],"status":"pass"}},"generatedAt":"2026-07-20T19:33:06.864054Z","profileId":"selbrume-release-v1","profileVersion":1,"projectFingerprint":"sha256:7c312f02c6b3a9e3411079bf59d6c3ddc91f59be3fe5f4f7725896ab83659bf1","schemaVersion":1,"validatorVersion":"narrative-validator-v1"}
~~~~

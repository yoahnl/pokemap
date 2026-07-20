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

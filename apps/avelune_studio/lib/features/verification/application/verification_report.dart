part of 'verification_workspace_controller.dart';

enum VerificationPhase { idle, reading, analysing, ready, failed, cancelled }

/// A rule draft the author has not finished. It is not a validator diagnostic:
/// an incomplete relation is no [WorldRuleDefinition] and must neither be
/// forced into the model nor dropped to show green.
class VerificationDraftBlocker {
  const VerificationDraftBlocker({
    required this.ruleId,
    required this.label,
    required this.missing,
  });

  final String ruleId;
  final String label;
  final List<String> missing;
}

/// One completed control. Immutable: filters, scrolling and the graph read it
/// without ever recomputing it.
class VerificationReport {
  VerificationReport({
    required this.requestId,
    required this.sessionId,
    required this.generatedAt,
    required this.validatorVersion,
    required this.inputFingerprint,
    required this.freshnessKey,
    required this.project,
    required this.dependencies,
    required this.dimensions,
    required this.runtime,
    required this.scope,
    required this.limitations,
    required this.blockers,
    required this.labels,
    required this.includesDrafts,
  });

  final int requestId;
  final String sessionId;
  final DateTime generatedAt;
  final String validatorVersion;
  final String inputFingerprint;
  final String freshnessKey;
  final NarrativeProjectValidationReport project;
  final NarrativeDependencyIndex dependencies;
  final NarrativeMultidimensionalValidationReport dimensions;
  final VerificationRuntimeEvidence runtime;
  final List<String> scope;
  final List<String> limitations;
  final List<VerificationDraftBlocker> blockers;
  final Map<String, String> labels;
  final bool includesDrafts;

  List<NarrativeProjectDiagnostic> get diagnostics => project.diagnostics;

  int countOf(NarrativeProjectDiagnosticSeverity severity) =>
      diagnostics.where((diagnostic) => diagnostic.severity == severity).length;

  int errorsIn(NarrativeProjectDiagnosticDomain domain) => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.domain == domain &&
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
      )
      .length;

  int warningsIn(NarrativeProjectDiagnosticDomain domain) => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.domain == domain &&
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.warning,
      )
      .length;

  int countIn(NarrativeProjectDiagnosticDomain domain) =>
      diagnostics.where((diagnostic) => diagnostic.domain == domain).length;

  /// The human name of the element a diagnostic points at, taken from the
  /// dependency index rather than parsed out of the message.
  String labelFor(NarrativeProjectDiagnostic diagnostic) {
    for (final id in [
      diagnostic.worldRuleId,
      diagnostic.factId,
      diagnostic.dialogueId,
      diagnostic.cinematicId,
      diagnostic.stepId,
      diagnostic.chapterId,
      diagnostic.storylineId,
      diagnostic.sceneId,
      diagnostic.eventId,
      diagnostic.mapId,
    ]) {
      if (id == null || id.isEmpty) continue;
      if (labels[id] case final label?) return label;
      return id;
    }
    return diagnostic.path;
  }

  /// Where the problem lives, qualified so two homonyms stay distinct.
  String locationOf(NarrativeProjectDiagnostic diagnostic) {
    final map = diagnostic.mapId;
    final mapLabel = map == null ? null : labels[map] ?? map;
    return switch (diagnostic.domain) {
      NarrativeProjectDiagnosticDomain.map => mapLabel ?? 'Cartes',
      NarrativeProjectDiagnosticDomain.worldRule => 'Règles du monde',
      NarrativeProjectDiagnosticDomain.fact => 'États du monde',
      NarrativeProjectDiagnosticDomain.storyline => 'Histoires',
      NarrativeProjectDiagnosticDomain.runtime => 'Exécution',
      _ => mapLabel ?? diagnostic.path,
    };
  }
}

String verificationDomainLabel(NarrativeProjectDiagnosticDomain domain) =>
    switch (domain) {
      NarrativeProjectDiagnosticDomain.storyline => 'Histoires',
      NarrativeProjectDiagnosticDomain.scene => 'Scènes',
      NarrativeProjectDiagnosticDomain.event => 'Événements',
      NarrativeProjectDiagnosticDomain.dialogue => 'Dialogues',
      NarrativeProjectDiagnosticDomain.cinematic => 'Cinématiques',
      NarrativeProjectDiagnosticDomain.fact => 'États du monde',
      NarrativeProjectDiagnosticDomain.worldRule => 'Règles du monde',
      NarrativeProjectDiagnosticDomain.map => 'Cartes',
      NarrativeProjectDiagnosticDomain.runtime => 'Exécution',
    };

String verificationSeverityLabel(NarrativeProjectDiagnosticSeverity severity) =>
    switch (severity) {
      NarrativeProjectDiagnosticSeverity.error => 'Erreur',
      NarrativeProjectDiagnosticSeverity.warning => 'Avertissement',
      NarrativeProjectDiagnosticSeverity.info => 'Information',
    };

String verificationDimensionLabel(
  NarrativeValidationDimension dimension,
) => switch (dimension) {
  NarrativeValidationDimension.structurallyValid => 'Structure',
  NarrativeValidationDimension.narrativelySolvable => 'Résolution narrative',
  NarrativeValidationDimension.physicallyReachable => 'Accessibilité physique',
  NarrativeValidationDimension.runtimeSmokeVerified => 'Vérification en jeu',
};

String verificationStatusLabel(NarrativeValidationStatus status) =>
    switch (status) {
      NarrativeValidationStatus.pass => 'Vérifié',
      NarrativeValidationStatus.fail => 'En échec',
      NarrativeValidationStatus.indeterminate => 'Indéterminé',
      NarrativeValidationStatus.notRun => 'Non exécuté',
    };

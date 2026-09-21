part of 'verification_workspace_controller.dart';

enum VerificationPhase { idle, reading, analysing, ready, failed, cancelled }

/// Why a request stopped before adopting its result.
enum VerificationStop { none, replaced, closed, projectChanged }

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
    required this.savedRevision,
    required this.generatedAt,
    required this.validatorVersion,
    required this.inputFingerprint,
    required this.freshnessKey,
    required this.isolateName,
    required this.project,
    required this.dependencies,
    required this.dimensions,
    required this.runtime,
    required this.scope,
    required this.limitations,
    required this.blockers,
    required this.exclusions,
    required this.labels,
    required this.drafted,
  });

  /// Identity of this request, of the saved project, of the analysed inputs
  /// and of where the work ran — four different things, kept apart.
  final int requestId;
  final String savedRevision;
  final String inputFingerprint;
  final String isolateName;

  final DateTime generatedAt;
  final String validatorVersion;
  final String freshnessKey;
  final NarrativeProjectValidationReport project;
  final NarrativeDependencyIndex dependencies;
  final NarrativeMultidimensionalValidationReport dimensions;
  final VerificationRuntimeEvidence runtime;
  final List<String> scope;
  final List<String> limitations;
  final List<VerificationDraftBlocker> blockers;
  final List<VerificationExclusion> exclusions;
  final Map<String, String> labels;
  final bool drafted;

  List<NarrativeProjectDiagnostic> get diagnostics => project.diagnostics;

  int countOf(NarrativeProjectDiagnosticSeverity severity) =>
      diagnostics.where((item) => item.severity == severity).length;

  int errorsIn(NarrativeProjectDiagnosticDomain domain) => diagnostics
      .where(
        (item) =>
            item.domain == domain &&
            item.severity == NarrativeProjectDiagnosticSeverity.error,
      )
      .length;

  int warningsIn(NarrativeProjectDiagnosticDomain domain) => diagnostics
      .where(
        (item) =>
            item.domain == domain &&
            item.severity == NarrativeProjectDiagnosticSeverity.warning,
      )
      .length;

  int countIn(NarrativeProjectDiagnosticDomain domain) =>
      diagnostics.where((item) => item.domain == domain).length;

  /// The human name of a canonical identity.
  String labelOf(NarrativeDependencyKey key) =>
      labels[verificationKeyId(key)] ?? key.id;

  /// The human name of the element a diagnostic points at, resolved through
  /// the full canonical identity rather than a bare text identifier.
  String labelFor(NarrativeProjectDiagnostic diagnostic) {
    final resolved = verificationResolve(dependencies, diagnostic);
    if (resolved.key case final key?) return labelOf(key);
    final candidate = verificationCandidates(diagnostic).firstOrNull;
    if (candidate == null) return diagnostic.path;
    return resolved.ambiguous
        ? '${candidate.$2} (plusieurs documents)'
        : candidate.$2;
  }

  /// Where the problem lives, qualified so two homonyms stay distinct.
  String locationOf(NarrativeProjectDiagnostic diagnostic) {
    final map = diagnostic.mapId;
    final mapLabel = map == null || map.isEmpty
        ? null
        : labelOf(
            NarrativeDependencyKey(
              NarrativeDependencyTargetKind.sourceMap,
              map,
            ),
          );
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

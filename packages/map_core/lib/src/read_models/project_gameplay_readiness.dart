import 'mvp_product_criterion.dart';

/// Canonical gameplay-readiness checks required by `FG-180`.
enum ProjectGameplayReadinessCheck {
  startState,
  starterConfiguration,
  playablePartyPath,
  encounterTables,
  trainerReferences,
  shopItems,
  eventCommands,
  requiredFlagsReachable,
  fieldAbilityUnlockReachable,
  storyEndReachable,
  battleBridgeCoverage,
}

/// State of one externally produced readiness proof.
enum ProjectGameplayReadinessEvidenceStatus {
  passed,
  failed,
  unverified,
}

/// Severity exposed to creators and automated consumers.
enum ProjectGameplayReadinessSeverity {
  error,
  warning,
  info,
}

/// One source-backed proof for a canonical readiness check.
final class ProjectGameplayReadinessEvidence {
  const ProjectGameplayReadinessEvidence({
    required this.check,
    required this.status,
    required this.summary,
    this.source,
  });

  final ProjectGameplayReadinessCheck check;
  final ProjectGameplayReadinessEvidenceStatus status;
  final String summary;
  final String? source;
}

/// Normalized creator/agent diagnostic derived from readiness evidence.
final class ProjectGameplayReadinessDiagnostic {
  const ProjectGameplayReadinessDiagnostic({
    required this.check,
    required this.severity,
    required this.summary,
    this.source,
  });

  final ProjectGameplayReadinessCheck check;
  final ProjectGameplayReadinessSeverity severity;
  final String summary;
  final String? source;
}

/// Fail-closed FG-180 report for a playable project.
///
/// The report aggregates evidence produced by project validators, integration
/// tests and runtime smokes. It deliberately performs no filesystem access so
/// `map_core` remains pure Dart and callers decide how fresh evidence is
/// collected.
final class ProjectGameplayReadinessReport {
  ProjectGameplayReadinessReport._(
    Iterable<ProjectGameplayReadinessDiagnostic> diagnostics,
  ) : diagnostics = List.unmodifiable(diagnostics);

  factory ProjectGameplayReadinessReport.evaluate(
    Iterable<ProjectGameplayReadinessEvidence> evidence,
  ) {
    final supplied = <ProjectGameplayReadinessCheck,
        List<ProjectGameplayReadinessEvidence>>{};
    for (final item in evidence) {
      supplied.putIfAbsent(item.check, () => []).add(item);
    }

    final diagnostics = <ProjectGameplayReadinessDiagnostic>[];
    for (final check in ProjectGameplayReadinessCheck.values) {
      final candidates = supplied[check] ?? const [];
      if (candidates.isEmpty) {
        diagnostics.add(
          ProjectGameplayReadinessDiagnostic(
            check: check,
            severity: ProjectGameplayReadinessSeverity.warning,
            summary: 'Aucune preuve fournie pour ${_labelFor(check)}.',
          ),
        );
        continue;
      }
      if (candidates.length != 1) {
        diagnostics.add(
          ProjectGameplayReadinessDiagnostic(
            check: check,
            severity: ProjectGameplayReadinessSeverity.error,
            summary: 'Plusieurs preuves contradictoires ont été fournies pour '
                '${_labelFor(check)}.',
          ),
        );
        continue;
      }

      diagnostics.add(_normalize(candidates.single));
    }

    return ProjectGameplayReadinessReport._(diagnostics);
  }

  /// Combines project inspection with the explicit 19-outcome MVP journey.
  ///
  /// Every project check and every product criterion must appear exactly once.
  /// The many-to-one mapping is declared by [MvpProductCriterionContract] and
  /// no observation is promoted to `passed` merely because it exists.
  factory ProjectGameplayReadinessReport.evaluateProductCriteria({
    required Iterable<MvpProductCriterionEvidence> productEvidence,
    required Iterable<ProjectGameplayReadinessEvidence> projectEvidence,
  }) {
    final productByCriterion =
        <MvpProductCriterion, List<MvpProductCriterionEvidence>>{};
    for (final evidence in productEvidence) {
      productByCriterion
          .putIfAbsent(evidence.criterion, () => [])
          .add(evidence);
    }
    final projectByCheck = <ProjectGameplayReadinessCheck,
        List<ProjectGameplayReadinessEvidence>>{};
    for (final evidence in projectEvidence) {
      projectByCheck.putIfAbsent(evidence.check, () => []).add(evidence);
    }

    final synthesized = <ProjectGameplayReadinessEvidence>[];
    for (final check in ProjectGameplayReadinessCheck.values) {
      synthesized.add(
        _synthesizeProductCheck(
          check: check,
          projectCandidates: projectByCheck[check] ??
              const <ProjectGameplayReadinessEvidence>[],
          productByCriterion: productByCriterion,
        ),
      );
    }
    return ProjectGameplayReadinessReport.evaluate(synthesized);
  }

  final List<ProjectGameplayReadinessDiagnostic> diagnostics;

  List<ProjectGameplayReadinessDiagnostic> get errors => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.error,
        ),
      );

  List<ProjectGameplayReadinessDiagnostic> get warnings => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.warning,
        ),
      );

  List<ProjectGameplayReadinessDiagnostic> get infos => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.info,
        ),
      );

  bool get isPlayable =>
      errors.isEmpty &&
      warnings.isEmpty &&
      diagnostics.length == ProjectGameplayReadinessCheck.values.length;

  String get creatorMarkdown {
    final buffer = StringBuffer()
      ..writeln(isPlayable ? '# Projet jouable' : '# Projet incomplet')
      ..writeln()
      ..writeln(
        '${infos.length}/${ProjectGameplayReadinessCheck.values.length} '
        'vérifications réussies.',
      );
    if (errors.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## ${errors.length} erreur(s) à corriger');
      for (final diagnostic in errors) {
        buffer.writeln('- ${diagnostic.summary}');
      }
    }
    if (warnings.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '## ${warnings.length} vérification(s) à confirmer',
        );
      for (final diagnostic in warnings) {
        buffer.writeln('- ${diagnostic.summary}');
      }
    }
    return buffer.toString().trimRight();
  }

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Project Gameplay Readiness — agent detail')
      ..writeln()
      ..writeln('| Check | Severity | Summary | Source |')
      ..writeln('|---|---|---|---|');
    for (final diagnostic in diagnostics) {
      buffer.writeln(
        '| `${diagnostic.check.name}` | '
        '`${diagnostic.severity.name}` | '
        '${_escapeCell(diagnostic.summary)} | '
        '${_escapeCell(diagnostic.source ?? '—')} |',
      );
    }
    return buffer.toString().trimRight();
  }
}

ProjectGameplayReadinessEvidence _synthesizeProductCheck({
  required ProjectGameplayReadinessCheck check,
  required List<ProjectGameplayReadinessEvidence> projectCandidates,
  required Map<MvpProductCriterion, List<MvpProductCriterionEvidence>>
      productByCriterion,
}) {
  if (projectCandidates.length != 1) {
    return ProjectGameplayReadinessEvidence(
      check: check,
      status: ProjectGameplayReadinessEvidenceStatus.failed,
      summary: projectCandidates.isEmpty
          ? 'Aucune inspection projet fournie pour ${check.name}.'
          : 'Inspection projet dupliquée pour ${check.name}.',
      source: 'FG-180 collector',
    );
  }
  final projectDiagnostic = _normalize(projectCandidates.single);
  if (projectDiagnostic.severity != ProjectGameplayReadinessSeverity.info) {
    return ProjectGameplayReadinessEvidence(
      check: check,
      status:
          projectDiagnostic.severity == ProjectGameplayReadinessSeverity.warning
              ? ProjectGameplayReadinessEvidenceStatus.unverified
              : ProjectGameplayReadinessEvidenceStatus.failed,
      summary: projectDiagnostic.summary,
      source: projectDiagnostic.source ?? 'FG-180 project inspection',
    );
  }

  final mappedCriteria = MvpProductCriterion.values
      .where((criterion) => criterion.readinessCheck == check)
      .toList(growable: false);
  final summaries = <String>[];
  final sources = <String>{projectDiagnostic.source!};
  var status = ProjectGameplayReadinessEvidenceStatus.passed;
  for (final criterion in mappedCriteria) {
    final candidates = productByCriterion[criterion] ?? const [];
    if (candidates.length != 1) {
      status = ProjectGameplayReadinessEvidenceStatus.failed;
      summaries.add(
        candidates.isEmpty
            ? '${criterion.id} est absent.'
            : '${criterion.id} possède une preuve dupliquée.',
      );
      continue;
    }
    final evidence = candidates.single;
    if (evidence.summary.trim().isEmpty || evidence.source.trim().isEmpty) {
      status = ProjectGameplayReadinessEvidenceStatus.failed;
      summaries.add('${criterion.id} possède une preuve inexploitable.');
      continue;
    }
    sources.add(evidence.source.trim());
    summaries.add('${criterion.id}: ${evidence.summary.trim()}');
    if (evidence.status == MvpProductCriterionStatus.failed) {
      status = ProjectGameplayReadinessEvidenceStatus.failed;
    } else if (evidence.status == MvpProductCriterionStatus.unverified &&
        status == ProjectGameplayReadinessEvidenceStatus.passed) {
      status = ProjectGameplayReadinessEvidenceStatus.unverified;
    }
  }
  return ProjectGameplayReadinessEvidence(
    check: check,
    status: status,
    summary: summaries.join(' '),
    source: sources.join(', '),
  );
}

ProjectGameplayReadinessDiagnostic _normalize(
  ProjectGameplayReadinessEvidence evidence,
) {
  if (evidence.status == ProjectGameplayReadinessEvidenceStatus.passed &&
      (evidence.summary.trim().isEmpty ||
          evidence.source == null ||
          evidence.source!.trim().isEmpty)) {
    return ProjectGameplayReadinessDiagnostic(
      check: evidence.check,
      severity: ProjectGameplayReadinessSeverity.error,
      summary: 'La preuve réussie pour ${_labelFor(evidence.check)} est '
          'inexploitable : résumé et source sont obligatoires.',
      source: evidence.source,
    );
  }

  final severity = switch (evidence.status) {
    ProjectGameplayReadinessEvidenceStatus.passed =>
      ProjectGameplayReadinessSeverity.info,
    ProjectGameplayReadinessEvidenceStatus.failed =>
      ProjectGameplayReadinessSeverity.error,
    ProjectGameplayReadinessEvidenceStatus.unverified =>
      ProjectGameplayReadinessSeverity.warning,
  };
  return ProjectGameplayReadinessDiagnostic(
    check: evidence.check,
    severity: severity,
    summary: evidence.summary.trim().isEmpty
        ? 'Aucun détail fourni pour ${_labelFor(evidence.check)}.'
        : evidence.summary.trim(),
    source: evidence.source?.trim(),
  );
}

String _labelFor(ProjectGameplayReadinessCheck check) => switch (check) {
      ProjectGameplayReadinessCheck.startState => 'l’état de départ',
      ProjectGameplayReadinessCheck.starterConfiguration =>
        'la configuration du starter',
      ProjectGameplayReadinessCheck.playablePartyPath =>
        'le chemin vers une équipe jouable',
      ProjectGameplayReadinessCheck.encounterTables =>
        'les tables de rencontre',
      ProjectGameplayReadinessCheck.trainerReferences =>
        'les références de dresseurs',
      ProjectGameplayReadinessCheck.shopItems => 'les objets de boutique',
      ProjectGameplayReadinessCheck.eventCommands =>
        'les commandes événementielles',
      ProjectGameplayReadinessCheck.requiredFlagsReachable =>
        'les flags requis',
      ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable =>
        'le déblocage d’une capacité de terrain',
      ProjectGameplayReadinessCheck.storyEndReachable => 'la fin de l’histoire',
      ProjectGameplayReadinessCheck.battleBridgeCoverage =>
        'la couverture du bridge de combat',
    };

String _escapeCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();

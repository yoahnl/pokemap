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

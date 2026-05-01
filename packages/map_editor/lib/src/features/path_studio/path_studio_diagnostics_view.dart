part of 'path_studio_panel.dart';

int _diagnosticSortWeight(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking => 0,
    PathPatternDiagnosticSeverity.warning => 1,
    PathPatternDiagnosticSeverity.info => 2,
  };
}

Color _diagnosticColor(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking => PathStudioTheme.error,
    PathPatternDiagnosticSeverity.warning => PathStudioTheme.warning,
    PathPatternDiagnosticSeverity.info => PathStudioTheme.accent,
  };
}

IconData _diagnosticIcon(PathPatternDiagnosticSeverity severity) {
  return switch (severity) {
    PathPatternDiagnosticSeverity.blocking =>
      CupertinoIcons.exclamationmark_triangle_fill,
    PathPatternDiagnosticSeverity.warning =>
      CupertinoIcons.exclamationmark_triangle,
    PathPatternDiagnosticSeverity.info => CupertinoIcons.info_circle_fill,
  };
}

String _draftIssueLabel(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
  };
}

String _draftIssueDescription(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
  };
}

class _DraftDiagnosticsCard extends StatelessWidget {
  const _DraftDiagnosticsCard({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur locale',
              message: 'Le brouillon est éditable en mémoire.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.warning,
                        title: _draftIssueLabel(issue),
                        message: _draftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _LegacyPathSaveStatusCard extends StatelessWidget {
  const _LegacyPathSaveStatusCard({
    required this.plan,
    required this.hasSaveCallback,
    required this.feedbackMessage,
  });

  final PathStudioLegacyPathPatternSavePlan plan;
  final bool hasSaveCallback;
  final String? feedbackMessage;

  @override
  Widget build(BuildContext context) {
    final ready = plan.canSaveNow;
    return _SectionCard(
      key: const Key('path-studio-save-status-card'),
      title: 'Application au projet (mémoire)',
      icon: CupertinoIcons.floppy_disk,
      trailing: _StatusChip(
        label: ready ? 'Requête prête' : 'Bloquée',
        color: ready ? PathStudioTheme.success : PathStudioTheme.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _InfoTile(
                label: 'État',
                value: 'Motif PathPattern depuis path existant',
              ),
              _InfoTile(
                label: 'ID proposé',
                value: plan.proposedPathPatternPresetId,
              ),
              _InfoTile(label: 'Base', value: plan.basePathPresetId),
              _InfoTile(
                label: 'Action',
                value: ready ? 'Requête prête' : 'À corriger',
              ),
            ],
          ),
          if (feedbackMessage != null) ...[
            const SizedBox(height: 12),
            _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: feedbackMessage!,
              message:
                  'Le callback a reçu le ProjectPathPatternPreset préparé. Le manifest reste inchangé.',
            ),
          ],
          if (ready && !hasSaveCallback) ...[
            const SizedBox(height: 12),
            const _DiagnosticRow(
              icon: CupertinoIcons.info_circle_fill,
              color: PathStudioTheme.warning,
              title: 'Callback d’application absent',
              message:
                  'La requête locale est prête, mais aucun callback ne l’applique au manifest en mémoire.',
            ),
          ],
          if (plan.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SaveIssueList(issues: plan.issues),
          ],
        ],
      ),
    );
  }
}

class _SaveIssueList extends StatelessWidget {
  const _SaveIssueList({required this.issues});

  final List<PathStudioSaveIssueCode> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const _DiagnosticRow(
        icon: CupertinoIcons.check_mark_circled_solid,
        color: PathStudioTheme.success,
        title: 'Aucune issue de sauvegarde locale',
        message: 'La préparation locale ne signale aucun blocage.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final issue in issues)
          Padding(
            key: Key('path-studio-save-issue-${issue.name}'),
            padding: const EdgeInsets.only(bottom: 8),
            child: _DiagnosticRow(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: issue == PathStudioSaveIssueCode.pathVariantMappingRequired
                  ? PathStudioTheme.warning
                  : PathStudioTheme.accentCyan,
              title: pathStudioSaveIssueLabel(issue),
              message: pathStudioSaveIssueDescription(issue),
            ),
          ),
      ],
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(card.status);
    final animationLine =
        '${card.animatedCellCount > 0 ? 'Animé' : 'Statique'} — '
        '${pluralizeFr(card.centerFrameCount, 'frame', 'frames')}';
    return _SectionCard(
      title: 'Résumé',
      icon: CupertinoIcons.doc_text,
      trailing: _StatusChip(label: status.label, color: status.color),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: card.name),
          _InfoTile(
              label: 'Base', value: card.basePathPresetName ?? 'Introuvable'),
          _InfoTile(label: 'Taille du centre', value: card.centerPatternLabel),
          _InfoTile(
            label: 'Cellules',
            value: pluralizeFr(card.centerCellCount, 'cellule', 'cellules'),
          ),
          _InfoTile(label: 'Animation', value: animationLine),
          _InfoTile(
            label: 'Transparent',
            value: card.transparentColorHex ?? 'Absent',
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.card, this.summaryKey});

  final PathPatternPresetCardModel card;
  final Key? summaryKey;

  @override
  Widget build(BuildContext context) {
    final diagnostics = List<PathPatternDiagnostic>.from(card.diagnostics)
      ..sort((left, right) {
        final severityCompare = _diagnosticSortWeight(left.severity).compareTo(
          _diagnosticSortWeight(right.severity),
        );
        if (severityCompare != 0) {
          return severityCompare;
        }
        return left.title.compareTo(right.title);
      });
    final blocking = diagnostics
        .where(
          (d) => d.severity == PathPatternDiagnosticSeverity.blocking,
        )
        .toList(growable: false);
    final warnings = diagnostics
        .where(
          (d) => d.severity == PathPatternDiagnosticSeverity.warning,
        )
        .toList(growable: false);
    final infos = diagnostics
        .where(
          (d) => d.severity == PathPatternDiagnosticSeverity.info,
        )
        .toList(growable: false);
    final summaryText = formatDiagnosticsSeveritySummary(
      blocking: blocking.length,
      warning: warnings.length,
      info: infos.length,
    );
    return _SectionCard(
      title: 'Diagnostics',
      icon: CupertinoIcons.check_mark_circled,
      child: diagnostics.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Prêt',
              message: 'Aucun blocage ni warning détecté.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summaryText.isNotEmpty) ...[
                  Text(
                    summaryText,
                    key: summaryKey,
                    style: const TextStyle(
                      color: PathStudioTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (blocking.isNotEmpty) ...[
                  const Text(
                    'Blocages',
                    style: TextStyle(
                      color: PathStudioTheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...blocking.map(
                    (diagnostic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: _diagnosticIcon(diagnostic.severity),
                        color: _diagnosticColor(diagnostic.severity),
                        title: diagnostic.title,
                        message: diagnostic.suggestion == null
                            ? diagnostic.description
                            : '${diagnostic.description}\n\nSuggestion : ${diagnostic.suggestion!}',
                      ),
                    ),
                  ),
                ],
                if (warnings.isNotEmpty) ...[
                  const Text(
                    'Warnings',
                    style: TextStyle(
                      color: PathStudioTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...warnings.map(
                    (diagnostic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: _diagnosticIcon(diagnostic.severity),
                        color: _diagnosticColor(diagnostic.severity),
                        title: diagnostic.title,
                        message: diagnostic.suggestion == null
                            ? diagnostic.description
                            : '${diagnostic.description}\n\nSuggestion : ${diagnostic.suggestion!}',
                      ),
                    ),
                  ),
                ],
                if (infos.isNotEmpty) ...[
                  const Text(
                    'Infos',
                    style: TextStyle(
                      color: PathStudioTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...infos.map(
                    (diagnostic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: _diagnosticIcon(diagnostic.severity),
                        color: _diagnosticColor(diagnostic.severity),
                        title: diagnostic.title,
                        message: diagnostic.suggestion == null
                            ? diagnostic.description
                            : '${diagnostic.description}\n\nSuggestion : ${diagnostic.suggestion!}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

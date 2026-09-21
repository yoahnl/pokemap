part of 'verification_workspace_page.dart';

const _labelStyle = TextStyle(fontSize: 12);

Color _statusColour(BuildContext context, NarrativeValidationStatus status) =>
    switch (status) {
      NarrativeValidationStatus.pass => const Color(0xFF3FBF7F),
      NarrativeValidationStatus.fail => Theme.of(context).colorScheme.error,
      NarrativeValidationStatus.indeterminate => const Color(0xFFE0A93B),
      NarrativeValidationStatus.notRun => Theme.of(context).colorScheme.outline,
    };

IconData _statusIcon(NarrativeValidationStatus status) => switch (status) {
  NarrativeValidationStatus.pass => Icons.check_circle_outline,
  NarrativeValidationStatus.fail => Icons.error_outline,
  NarrativeValidationStatus.indeterminate => Icons.help_outline,
  NarrativeValidationStatus.notRun => Icons.remove_circle_outline,
};

Color _severityColour(
  BuildContext context,
  NarrativeProjectDiagnosticSeverity severity,
) => switch (severity) {
  NarrativeProjectDiagnosticSeverity.error => Theme.of(
    context,
  ).colorScheme.error,
  NarrativeProjectDiagnosticSeverity.warning => const Color(0xFFE0A93B),
  NarrativeProjectDiagnosticSeverity.info => Theme.of(
    context,
  ).colorScheme.primary,
};

IconData _severityIcon(NarrativeProjectDiagnosticSeverity severity) =>
    switch (severity) {
      NarrativeProjectDiagnosticSeverity.error => Icons.error_outline,
      NarrativeProjectDiagnosticSeverity.warning =>
        Icons.warning_amber_outlined,
      NarrativeProjectDiagnosticSeverity.info => Icons.info_outline,
    };

extension _VerificationSummary on _VerificationWorkspacePageState {
  Widget _summary() {
    final report = controller.report;
    return StudioPanel(
      title: 'Vue d’ensemble',
      children: report == null
          ? [
              const Expanded(
                child: SingleChildScrollView(
                  child: StudioEmptyState(
                    title: 'Aucun contrôle lancé',
                    description:
                        'Le projet n’a pas encore été analysé. Lancez la '
                        'vérification pour obtenir un rapport daté.',
                    icon: Icons.fact_check_outlined,
                  ),
                ),
              ),
            ]
          : [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ..._dimensions(report),
                    const SizedBox(height: 12),
                    _counters(report),
                    const SizedBox(height: 12),
                    const Text('Résultats par catégorie', style: _labelStyle),
                    const SizedBox(height: 4),
                    ..._categories(report),
                    if (report.blockers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _blockers(report),
                    ],
                    if (report.exclusions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _exclusions(report),
                    ],
                    const SizedBox(height: 12),
                    _limitations(report),
                  ],
                ),
              ),
            ],
    );
  }

  /// Four dimensions, four canonical states. No average, no percentage: a
  /// dimension that was not executed is not a success.
  List<Widget> _dimensions(VerificationReport report) => [
    for (final dimension in NarrativeValidationDimension.values)
      Builder(
        builder: (context) {
          final result = switch (dimension) {
            NarrativeValidationDimension.structurallyValid =>
              report.dimensions.structurallyValid,
            NarrativeValidationDimension.narrativelySolvable =>
              report.dimensions.narrativelySolvable,
            NarrativeValidationDimension.physicallyReachable =>
              report.dimensions.physicallyReachable,
            NarrativeValidationDimension.runtimeSmokeVerified =>
              report.dimensions.runtimeSmokeVerified,
          };
          final colour = _statusColour(context, result.status);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(_statusIcon(result.status), size: 16, color: colour),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verificationDimensionLabel(dimension),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  verificationStatusLabel(result.status),
                  style: TextStyle(fontSize: 12, color: colour),
                ),
              ],
            ),
          );
        },
      ),
  ];

  Widget _counters(VerificationReport report) => Row(
    children: [
      for (final severity in NarrativeProjectDiagnosticSeverity.values.reversed)
        Expanded(
          child: Builder(
            builder: (context) => Column(
              children: [
                Text(
                  '${report.countOf(severity)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: _severityColour(context, severity),
                  ),
                ),
                Text(
                  verificationSeverityLabel(severity),
                  style: _labelStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
    ],
  );

  /// A category without known problems says so; it never claims completeness.
  List<Widget> _categories(VerificationReport report) => [
    for (final domain in NarrativeProjectDiagnosticDomain.values)
      Builder(
        builder: (context) {
          final errors = report.errorsIn(domain);
          final warnings = report.warningsIn(domain);
          final total = report.countIn(domain);
          final selected = controller.domains.contains(domain);
          return InkWell(
            onTap: () {
              controller.toggleDomain(domain);
              refresh();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .14)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verificationDomainLabel(domain),
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          total == 0
                              ? 'Aucun problème détecté dans ce périmètre'
                              : [
                                  if (errors > 0) '$errors erreur(s)',
                                  if (warnings > 0)
                                    '$warnings avertissement(s)',
                                  if (errors == 0 && warnings == 0)
                                    '$total information(s)',
                                ].join(' · '),
                          style: _labelStyle,
                        ),
                      ],
                    ),
                  ),
                  if (errors > 0)
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    )
                  else if (warnings > 0)
                    const Icon(
                      Icons.warning_amber_outlined,
                      size: 16,
                      color: Color(0xFFE0A93B),
                    )
                  else
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF3FBF7F),
                    ),
                ],
              ),
            ),
          );
        },
      ),
  ];

  /// Unfinished rule drafts, kept apart from the validator's diagnostics.
  Widget _blockers(VerificationReport report) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Brouillons à compléter', style: _labelStyle),
      const SizedBox(height: 4),
      for (final blocker in report.blockers)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${blocker.label} — il manque ${blocker.missing.join(', ')}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      const SizedBox(height: 2),
      const Text(
        'Une règle incomplète n’est pas une définition : elle n’a pas été '
        'analysée et n’a pas été publiée.',
        style: _labelStyle,
      ),
    ],
  );

  /// What the control could not represent, named with its reason. The verdict
  /// above never claims to cover these documents.
  Widget _exclusions(VerificationReport report) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Hors du contrôle', style: _labelStyle),
      const SizedBox(height: 4),
      for (final exclusion in report.exclusions)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${exclusion.owner} · ${exclusion.label} — ${exclusion.reason}',
            style: _labelStyle,
          ),
        ),
    ],
  );

  Widget _limitations(VerificationReport report) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () {
          view.limitationsOpen = !view.limitationsOpen;
          refresh();
        },
        child: Row(
          children: [
            Icon(
              view.limitationsOpen ? Icons.expand_less : Icons.expand_more,
              size: 16,
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text('Couverture et limites', style: _labelStyle),
            ),
          ],
        ),
      ),
      if (view.limitationsOpen)
        for (final limitation in report.limitations)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• $limitation', style: _labelStyle),
          ),
    ],
  );
}

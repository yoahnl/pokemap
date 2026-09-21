part of 'verification_workspace_page.dart';

extension _VerificationList on _VerificationWorkspacePageState {
  Widget _listPanel(bool compact) {
    final report = controller.report;
    return StudioPanel(
      title: 'Résultats',
      children: [
        if (report == null)
          Expanded(
            child: SingleChildScrollView(
              child: StudioEmptyState(
                title: 'Aucun contrôle lancé',
                description:
                    'Rien n’a été analysé : ce n’est pas « aucune erreur ». '
                    'Lancez la vérification pour obtenir des résultats réels.',
                icon: Icons.fact_check_outlined,
                action: StudioButton(
                  label: 'Lancer la vérification',
                  icon: Icons.play_arrow,
                  onPressed: controller.running
                      ? null
                      : () => unawaited(_run()),
                ),
              ),
            ),
          )
        else ...[
          _tabs(report, compact),
          const SizedBox(height: 6),
          _search(report),
          const SizedBox(height: 6),
          Expanded(child: _rows(report)),
        ],
      ],
    );
  }

  /// The tabs are severity filters on this report, never a second severity
  /// vocabulary of their own.
  Widget _tabs(VerificationReport report, bool compact) {
    final severities = controller.severities;
    final selected = severities.length == 1 ? severities.first : null;
    final errors = report.countOf(NarrativeProjectDiagnosticSeverity.error);
    final warnings = report.countOf(NarrativeProjectDiagnosticSeverity.warning);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: StudioTabs<NarrativeProjectDiagnosticSeverity?>(
        items: {
          NarrativeProjectDiagnosticSeverity.error: compact
              ? 'Erreurs ($errors)'
              : 'Problèmes détectés ($errors)',
          NarrativeProjectDiagnosticSeverity.warning: compact
              ? 'Avert. ($warnings)'
              : 'Avertissements ($warnings)',
          null: compact
              ? 'Tous (${report.diagnostics.length})'
              : 'Tous les résultats (${report.diagnostics.length})',
        },
        selected: selected,
        onChanged: (next) {
          severities
            ..clear()
            ..addAll(next == null ? const [] : [next]);
          controller.changed();
          refresh();
        },
      ),
    );
  }

  Widget _search(VerificationReport report) => Row(
    children: [
      Expanded(
        child: StudioSearchField(
          controller: view.search,
          label: 'Rechercher un nom, un message, un code ou un identifiant',
          onChanged: (value) {
            controller.setSearch(value);
            refresh();
          },
        ),
      ),
      if (controller.filtered)
        StudioTool(
          label: 'Effacer les filtres',
          icon: Icons.filter_alt_off_outlined,
          onPressed: () {
            view.search.clear();
            controller.clearFilters();
            refresh();
          },
        ),
    ],
  );

  Widget _rows(VerificationReport report) {
    final visible = controller.visible;
    if (visible.isEmpty) {
      return StudioEmptyState(
        title: 'Aucun résultat pour ce filtre',
        description: controller.filtered
            ? 'Le rapport contient ${report.diagnostics.length} résultat(s). '
                  'Ce zéro est celui du filtre, pas celui du projet.'
            : 'Le contrôle n’a produit aucun diagnostic dans ce périmètre.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // The message is what the author reads: the fixed columns give way
        // before it does.
        final narrow = constraints.maxWidth < 640;
        return ListView.builder(
          controller: view.listScroll,
          itemCount: visible.length,
          itemExtent: 56,
          itemBuilder: (context, index) => _row(report, visible[index], narrow),
        );
      },
    );
  }

  Widget _row(
    VerificationReport report,
    NarrativeProjectDiagnostic item,
    bool narrow,
  ) {
    final selected = item.stableKey == controller.selectedKey;
    return InkWell(
      key: ValueKey(item.stableKey),
      onTap: () {
        controller.select(item.stableKey);
        refresh();
      },
      onDoubleTap: () => unawaited(_open(item)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .16)
              : null,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: .5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _severityIcon(item.severity),
              size: 16,
              color: _severityColour(context, item.severity),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: narrow ? 46 : 92,
              child: Text(
                narrow
                    ? _shortSeverity(item.severity)
                    : verificationSeverityLabel(item.severity),
                style: _labelStyle,
              ),
            ),
            SizedBox(
              width: narrow ? 108 : 150,
              child: Text(
                report.labelFor(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: narrow ? 88 : 120,
              child: Text(
                report.locationOf(item),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gravity stays carried by a word as well as by a colour, even when the
  /// column has to shrink.
  String _shortSeverity(NarrativeProjectDiagnosticSeverity severity) =>
      switch (severity) {
        NarrativeProjectDiagnosticSeverity.error => 'Err.',
        NarrativeProjectDiagnosticSeverity.warning => 'Avert.',
        NarrativeProjectDiagnosticSeverity.info => 'Info',
      };

  Future<void> _open(NarrativeProjectDiagnostic item) async {
    controller.select(item.stableKey);
    refresh();
    await widget.onOpen?.call(item);
  }
}

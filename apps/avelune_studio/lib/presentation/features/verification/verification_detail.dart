part of 'verification_workspace_page.dart';

extension _VerificationDetail on _VerificationWorkspacePageState {
  Widget _detail() {
    final report = controller.report;
    final item = controller.selected;
    if (report == null || item == null) {
      return StudioPanel(
        title: 'Détail',
        children: [
          if (controller.selectionNotice case final notice?)
            StudioNotice(notice),
          const Expanded(
            child: SingleChildScrollView(
              child: StudioEmptyState(
                title: 'Aucun diagnostic sélectionné',
                description:
                    'Choisissez une ligne pour comprendre le problème, son '
                    'contexte et l’éditeur qui peut le résoudre.',
                icon: Icons.article_outlined,
              ),
            ),
          ),
        ],
      );
    }
    final destination = widget.openLabel?.call(item);
    return StudioPanel(
      title: 'Détail',
      children: [
        if (controller.selectionHidden)
          const StudioNotice(
            'Sélection hors filtre : ce diagnostic n’est plus dans la liste '
            'affichée, l’action ci-dessous vise toujours cet élément.',
          ),
        Row(
          children: [
            Icon(
              _severityIcon(item.severity),
              size: 18,
              color: _severityColour(context, item.severity),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                verificationSeverityLabel(item.severity),
                style: TextStyle(
                  fontSize: 13,
                  color: _severityColour(context, item.severity),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          report.labelFor(item),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(item.message, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              _facts(report, item),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (destination == null)
          const StudioNotice(
            'Cible indisponible : ce diagnostic ne porte pas de destination '
            'ouvrable. Sa provenance reste lisible ci-dessus.',
          )
        else
          StudioButton(
            label: 'Ouvrir dans l’éditeur',
            icon: Icons.open_in_new,
            onPressed: () => unawaited(_open(item)),
          ),
        if (destination != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Destination : $destination', style: _labelStyle),
          ),
      ],
    );
  }

  /// Provenance, scope and the qualified identifiers, so two homonyms in two
  /// maps never look like the same problem.
  Widget _facts(VerificationReport report, NarrativeProjectDiagnostic item) {
    final rows = <(String, String)>[
      ('Catégorie', verificationDomainLabel(item.domain)),
      ('Emplacement', report.locationOf(item)),
      ('Chemin', item.path),
      ('Code', item.code),
      for (final entry in <(String, String?)>[
        ('Carte', item.mapId),
        ('Scène', item.sceneId),
        ('Événement', item.eventId),
        ('Dialogue', item.dialogueId),
        ('Cinématique', item.cinematicId),
        ('Histoire', item.storylineId),
        ('Chapitre', item.chapterId),
        ('Étape', item.stepId),
        ('État', item.factId),
        ('Règle', item.worldRuleId),
      ])
        if (entry.$2 != null && entry.$2!.isNotEmpty) (entry.$1, entry.$2!),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 96, child: Text(row.$1, style: _labelStyle)),
                Expanded(
                  child: SelectableText(
                    row.$2,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text('Limites de preuve', style: _labelStyle),
        Text(
          'Ce diagnostic vient du validateur canonique sur la version de '
          'travail. Aucune réparation automatique n’est proposée : le '
          'contrat agrégé ne déclare aucune correction déterministe.',
          style: _labelStyle,
        ),
      ],
    );
  }
}

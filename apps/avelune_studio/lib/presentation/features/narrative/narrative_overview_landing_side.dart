part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingSide on NarrativeOverviewLanding {
  Widget _side(BuildContext context) {
    final active = narrativeResumeItems(
      overview: overview,
      scenes: scenes,
      dialogues: dialogues,
      events: events,
      activeStoryId: activeStoryId,
      activeSceneId: activeSceneId,
      activeDialogueId: activeDialogueId,
      activeEventId: activeEventId,
      dirtyStoryIds: dirtyStoryIds,
      dirtySceneIds: dirtySceneIds,
      dirtyDialogueIds: dirtyDialogueIds,
      dirtyEventIds: dirtyEventIds,
    );
    final resume = splitNarrativeResume(active);
    VoidCallback? opener(NarrativeResumeItem item) => switch (item.kind) {
      NarrativeResumeKind.story => () => onOpenStory(item.id),
      NarrativeResumeKind.scene =>
        onOpenScene == null ? null : () => onOpenScene!(item.id),
      NarrativeResumeKind.dialogue =>
        onOpenDialogue == null ? null : () => onOpenDialogue!(item.id),
      NarrativeResumeKind.interaction => () => onOpenInteraction(item.id),
      NarrativeResumeKind.event =>
        onOpenEvent == null ? null : () => onOpenEvent!(item.id),
    };
    IconData icon(NarrativeResumeKind kind) => switch (kind) {
      NarrativeResumeKind.story => Icons.auto_stories_outlined,
      NarrativeResumeKind.scene => Icons.account_tree_outlined,
      NarrativeResumeKind.dialogue => Icons.forum_outlined,
      NarrativeResumeKind.interaction => Icons.touch_app_outlined,
      NarrativeResumeKind.event => Icons.bolt_outlined,
    };
    StudioTone tone(NarrativeResumeKind kind) => switch (kind) {
      NarrativeResumeKind.story ||
      NarrativeResumeKind.scene => StudioTone.info,
      NarrativeResumeKind.dialogue => StudioTone.feature,
      NarrativeResumeKind.interaction ||
      NarrativeResumeKind.event => StudioTone.warning,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPanel(
          key: const ValueKey('narrative-landing-resume'),
          title: active.isEmpty
              ? 'Rien à reprendre'
              : 'Reprendre votre travail',
          children: [
            if (active.isEmpty)
              const Text(
                'Aucun document n’est ouvert ni modifié. Ouvrez une histoire, '
                'une scène, un dialogue ou un événement : tant qu’il reste '
                'ouvert ou non enregistré, il apparaît ici pour le reprendre.',
              ),
            for (final item in resume.shown)
              _documentRow(
                context,
                icon: icon(item.kind),
                tone: tone(item.kind),
                leading: item.kind == NarrativeResumeKind.scene
                    ? _sceneArtwork(item.id)
                    : null,
                title: item.title,
                subtitle: item.subtitle,
                onTap: opener(item),
              ),
            if (resume.hidden > 0)
              Text('${resume.hidden} autre(s) document(s) en cours'),
            StudioButton(
              label: 'Voir tous les documents',
              secondary: true,
              onPressed: onLibrary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Contenu du projet',
          children: [
            _count(
              context,
              Icons.auto_stories_outlined,
              overview.stories.length,
              'Histoires',
            ),
            _count(
              context,
              Icons.account_tree_outlined,
              scenes.length,
              'Scènes',
            ),
            _count(context, Icons.bolt_outlined, events.length, 'Événements'),
            _count(
              context,
              Icons.forum_outlined,
              dialogues.length,
              'Dialogues',
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Vérification narrative',
          children: [
            if (verification?.running == true) ...[
              const Text('Contrôle en cours…'),
              const SizedBox(height: 6),
            ] else if (verification?.phase == VerificationPhase.failed) ...[
              const Text('Dernier contrôle échoué'),
              if (verification?.error case final error?) Text(error),
              const SizedBox(height: 6),
            ],
            if (verification?.report case final report?) ...[
              const Text('Rapport du projet'),
              const SizedBox(height: 6),
              Text(
                'Contrôle du ${report.generatedAt.day.toString().padLeft(2, '0')}/${report.generatedAt.month.toString().padLeft(2, '0')}/${report.generatedAt.year} · ${report.drafted ? 'brouillons inclus' : 'version enregistrée'}',
              ),
              const SizedBox(height: 8),
              Text(
                '${report.countOf(NarrativeProjectDiagnosticSeverity.error)} erreur(s) · ${report.countOf(NarrativeProjectDiagnosticSeverity.warning)} avertissement(s)',
              ),
              const SizedBox(height: 6),
              Text('Périmètre : ${report.scope.join(' · ')}'),
              for (final dimension in NarrativeValidationDimension.values)
                Text(
                  '${verificationDimensionLabel(dimension)} : ${verificationStatusLabel(_dimensionStatus(report, dimension))}',
                ),
              if (report.blockers.isNotEmpty)
                Text('${report.blockers.length} brouillon(s) incomplet(s)'),
              if (report.exclusions.isNotEmpty)
                Text(
                  '${report.exclusions.length} document(s) exclu(s) du contrôle',
                ),
              if (report.limitations.isNotEmpty)
                Text('Limites : ${report.limitations.first}'),
              if (verification!.stale) ...[
                const SizedBox(height: 8),
                const Text('Modifications depuis ce contrôle · à actualiser'),
              ],
              if (verification!.running) ...[
                const SizedBox(height: 8),
                const Text('Nouveau contrôle en cours…'),
              ],
            ] else if (verification?.running != true &&
                verification?.phase != VerificationPhase.failed)
              const Text('Non vérifié · aucun rapport pour ce projet.'),
            const SizedBox(height: 8),
            StudioButton(
              label: 'Ouvrir la vérification',
              secondary: true,
              onPressed: onVerification,
            ),
          ],
        ),
      ],
    );
  }

  NarrativeValidationStatus _dimensionStatus(
    VerificationReport report,
    NarrativeValidationDimension dimension,
  ) => switch (dimension) {
    NarrativeValidationDimension.structurallyValid =>
      report.dimensions.structurallyValid.status,
    NarrativeValidationDimension.narrativelySolvable =>
      report.dimensions.narrativelySolvable.status,
    NarrativeValidationDimension.physicallyReachable =>
      report.dimensions.physicallyReachable.status,
    NarrativeValidationDimension.runtimeSmokeVerified =>
      report.dimensions.runtimeSmokeVerified.status,
  };
}

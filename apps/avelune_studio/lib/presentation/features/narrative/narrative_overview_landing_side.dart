part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingSide on NarrativeOverviewLanding {
  Widget _side(BuildContext context) {
    final active =
        <
          ({
            String title,
            String id,
            String subtitle,
            bool isScene,
            IconData icon,
            StudioTone tone,
            VoidCallback? open,
          })
        >[];
    for (final story in overview.stories) {
      if (story.id != activeStoryId && !dirtyStoryIds.contains(story.id)) {
        continue;
      }
      active.add((
        id: story.id,
        title: story.title,
        subtitle: dirtyStoryIds.contains(story.id)
            ? 'Histoire · brouillon'
            : 'Histoire ouverte',
        isScene: false,
        icon: Icons.auto_stories_outlined,
        tone: StudioTone.info,
        open: () => onOpenStory(story.id),
      ));
    }
    for (final scene in scenes) {
      if (scene.id != activeSceneId && !dirtySceneIds.contains(scene.id)) {
        continue;
      }
      active.add((
        id: scene.id,
        title: scene.name,
        subtitle: dirtySceneIds.contains(scene.id)
            ? 'Scène · brouillon'
            : 'Scène ouverte',
        isScene: true,
        icon: Icons.account_tree_outlined,
        tone: StudioTone.info,
        open: onOpenScene == null ? null : () => onOpenScene!(scene.id),
      ));
    }
    for (final dialogue in dialogues) {
      if (dialogue.id != activeDialogueId &&
          !dirtyDialogueIds.contains(dialogue.id)) {
        continue;
      }
      active.add((
        id: dialogue.id,
        title: dialogue.name,
        subtitle: dirtyDialogueIds.contains(dialogue.id)
            ? 'Dialogue · brouillon'
            : 'Dialogue ouvert',
        isScene: false,
        icon: Icons.forum_outlined,
        tone: StudioTone.feature,
        open: onOpenDialogue == null
            ? null
            : () => onOpenDialogue!(dialogue.id),
      ));
    }
    for (final interaction in overview.interactions) {
      if (!interaction.dirty) continue;
      active.add((
        id: interaction.id,
        title: interaction.name,
        subtitle: 'Interaction · brouillon',
        isScene: false,
        icon: Icons.touch_app_outlined,
        tone: StudioTone.warning,
        open: () => onOpenInteraction(interaction.id),
      ));
    }
    for (final event in events) {
      if (event.id != activeEventId && !dirtyEventIds.contains(event.id)) {
        continue;
      }
      active.add((
        id: event.id,
        title: _eventName(event),
        subtitle: dirtyEventIds.contains(event.id)
            ? 'Événement · brouillon'
            : 'Événement ouvert',
        isScene: false,
        icon: Icons.bolt_outlined,
        tone: StudioTone.warning,
        open: onOpenEvent == null ? null : () => onOpenEvent!(event.id),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPanel(
          title: 'Reprendre votre travail',
          children: [
            if (active.isEmpty) ...[
              const Text('Aucun brouillon ouvert. Scènes du projet :'),
              const SizedBox(height: 8),
              for (final scene in scenes.take(4))
                _documentRow(
                  context,
                  icon: Icons.account_tree_outlined,
                  tone: StudioTone.info,
                  leading: _sceneArtwork(scene.id),
                  title: scene.name,
                  subtitle: 'Scène enregistrée',
                  onTap: onOpenScene == null
                      ? null
                      : () => onOpenScene!(scene.id),
                ),
            ],
            for (final item in active.take(5))
              _documentRow(
                context,
                icon: item.icon,
                tone: item.tone,
                leading: item.isScene ? _sceneArtwork(item.id) : null,
                title: item.title,
                subtitle: item.subtitle,
                onTap: item.open,
              ),
            if (active.length > 5)
              Text('${active.length - 5} autre(s) document(s) en cours'),
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
            const Text(
              'Aucun score n’est calculé sur cette page. Ouvrez la vérification pour consulter les diagnostics actuels.',
            ),
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
}

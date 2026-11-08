part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingIntents on NarrativeOverviewLanding {
  Widget _intents(BuildContext context, double width) {
    final intents =
        <
          ({
            String id,
            String title,
            String purpose,
            String creates,
            String editIn,
            IconData icon,
            StudioTone tone,
            VoidCallback? start,
          })
        >[
          (
            id: 'character-talk',
            title: 'Faire parler un personnage',
            purpose: 'Ouvre la carte : sélectionnez le personnage, puis « Écrire son interaction ».',
            creates: 'Rien à l’ouverture ; son événement ou son dialogue est créé quand vous le confirmez.',
            editIn: 'L’inspecteur du personnage, Événements et Dialogues',
            icon: Icons.record_voice_over_outlined,
            tone: StudioTone.info,
            start: onCreateInteraction,
          ),
          (
            id: 'scene-on-enter',
            title: 'Déclencher une scène en entrant',
            purpose: 'Ouvre Événements : déclencheur « Entrée sur la carte » ou « Entrée de zone ».',
            creates: 'Un événement, seulement quand vous le nommez ; vous lui choisissez ensuite sa scène.',
            editIn: 'Événements, puis Scènes pour son déroulé',
            icon: Icons.login,
            tone: StudioTone.warning,
            start: onEvents,
          ),
          (
            id: 'quest',
            title: 'Créer une quête',
            purpose: 'Nommez la quête ; le type « Secondaire » est proposé.',
            creates: 'Une histoire, seulement après « Créer ».',
            editIn: 'Histoires et progression : chapitres et étapes',
            icon: Icons.flag_outlined,
            tone: StudioTone.success,
            start: onCreateQuest,
          ),
          (
            id: 'movement',
            title: 'Mettre en scène un déplacement',
            purpose:
                'Ouvre Cinématiques sur carte : action « Déplacer un acteur ».',
            creates:
                'Une cinématique, seulement après « Nouvelle cinématique ».',
            editIn: 'Cinématiques sur carte, puis la scène qui la joue',
            icon: Icons.directions_walk,
            tone: StudioTone.feature,
            start: onCinematics,
          ),
        ];
    final columns = width >= 700 ? 2 : 1;
    final itemWidth = (width - 32 - (columns - 1) * 10) / columns;
    final colors = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return StudioPanel(
      key: const ValueKey('narrative-intents'),
      title: 'Qu’aimeriez-vous créer ?',
      children: [
        Text(
          'Partez d’une intention : chaque entrée ouvre l’éditeur existant et ne crée rien sans votre confirmation. Les accès directs restent au-dessus.',
          style: small,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final intent in intents)
              SizedBox(
                key: ValueKey('narrative-intent-${intent.id}'),
                width: itemWidth,
                child: StudioPanel(
                  compact: true,
                  children: [
                    Row(
                      children: [
                        StudioIconTile(
                          icon: intent.icon,
                          tone: intent.tone,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            intent.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(intent.purpose),
                    const SizedBox(height: 4),
                    Text(
                      'Crée : ${intent.creates}',
                      style: small?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    Text(
                      'À modifier dans : ${intent.editIn}',
                      style: small?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    if (intent.start == null)
                      Text(
                        'Indisponible : cet éditeur n’est pas chargé pour ce projet.',
                        style: small?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    StudioButton(
                      key: ValueKey('narrative-intent-start-${intent.id}'),
                      label: 'Commencer',
                      icon: Icons.arrow_forward,
                      secondary: true,
                      onPressed: intent.start,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _synthesis(BuildContext context, double width) {
    final stories = overview.stories;
    final colors = Theme.of(context).colorScheme;
    final header = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: colors.onSurfaceVariant);
    final columns = width >= 640;
    return StudioPanel(
      key: const ValueKey('narrative-story-synthesis'),
      title: 'Synthèse des histoires · ${stories.length}',
      actions: [
        if (onProgression != null)
          StudioButton(
            label: 'Ouvrir les graphes',
            secondary: true,
            icon: Icons.account_tree_outlined,
            onPressed: onProgression,
          ),
      ],
      children: [
        Text(
          'Accès rapide : une ligne ouvre l’histoire dans son graphe. Les graphes, scènes et événements restent les documents à modifier.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (stories.isEmpty)
          const Text('Aucune histoire à résumer pour le moment.')
        else ...[
          if (columns)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
              child: Row(
                children: [
                  Expanded(child: Text('Histoire', style: header)),
                  for (final label in _synthesisColumns)
                    SizedBox(
                      width: _synthesisColumnWidth,
                      child: Text(label, style: header),
                    ),
                ],
              ),
            ),
          for (final story in stories) _synthesisRow(story, columns),
        ],
      ],
    );
  }

  Widget _synthesisRow(StorylineAsset story, bool columns) {
    final steps = [for (final chapter in story.chapters) ...chapter.steps];
    final scenes = {
      for (final link in story.sceneLinks)
        if (link.sceneRef case final ref?) ref.targetId,
    };
    final interactions = {
      for (final step in steps)
        for (final item in overview.stepLinks[step.id] ?? const []) item.id,
    };
    final values = [
      '${story.chapters.length}',
      '${steps.length}',
      '${scenes.length}',
      '${interactions.length}',
    ];
    final type = _storyType(story.type);
    final draft = dirtyStoryIds.contains(story.id) ? ' · brouillon' : '';
    return StudioChoice(
      key: ValueKey('narrative-synthesis-${story.id}'),
      label: story.title,
      subtitle: columns
          ? '$type$draft'
          : '$type$draft · ${values[0]} chapitre(s) · ${values[1]} étape(s) · ${values[2]} scène(s) liée(s) · ${values[3]} interaction(s)',
      onTap: () => onOpenStory(story.id),
      trailing: columns
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final value in values)
                  SizedBox(width: _synthesisColumnWidth, child: Text(value)),
              ],
            )
          : null,
    );
  }
}

const _synthesisColumns = [
  'Chapitres',
  'Étapes',
  'Scènes liées',
  'Interactions',
];
const _synthesisColumnWidth = 92.0;

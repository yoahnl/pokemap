part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingSearch on NarrativeOverviewLanding {
  Widget _searchResults(BuildContext context, String query) {
    final results =
        <
          ({
            String id,
            String kind,
            String title,
            String subtitle,
            VoidCallback? open,
          })
        >[
          for (final story in overview.stories)
            if ('${story.title} ${story.description ?? ''}'
                .toLowerCase()
                .contains(query))
              (
                id: story.id,
                kind: 'Histoire',
                title: story.title,
                subtitle: _storyType(story.type),
                open: () => onOpenStory(story.id),
              ),
          for (final story in overview.stories)
            for (final chapter in _ordered(
              story.chapters,
              (item) => item.order,
            ))
              for (final step in _ordered(chapter.steps, (item) => item.order))
                if ('${step.title} ${chapter.title} ${story.title}'
                    .toLowerCase()
                    .contains(query))
                  (
                    id: '${story.id}/${step.id}',
                    kind: 'Étape',
                    title: step.title,
                    subtitle: story.title,
                    open: () => onOpenStep(story.id, step.id),
                  ),
          for (final scene in scenes)
            if (scene.name.toLowerCase().contains(query))
              (
                id: scene.id,
                kind: 'Scène',
                title: scene.name,
                subtitle: 'Éditeur de scène',
                open: onOpenScene == null ? null : () => onOpenScene!(scene.id),
              ),
          for (final dialogue in dialogues)
            if (dialogue.name.toLowerCase().contains(query))
              (
                id: dialogue.id,
                kind: 'Dialogue',
                title: dialogue.name,
                subtitle: 'Éditeur de dialogue',
                open: onOpenDialogue == null
                    ? null
                    : () => onOpenDialogue!(dialogue.id),
              ),
          for (final event in events)
            if (_eventName(event).toLowerCase().contains(query))
              (
                id: event.id,
                kind: 'Événement',
                title: _eventName(event),
                subtitle: 'Déclencheur',
                open: onOpenEvent == null ? null : () => onOpenEvent!(event.id),
              ),
          for (final item in overview.interactions)
            if (item.searchText.contains(query))
              (
                id: item.id,
                kind: 'Interaction',
                title: item.name,
                subtitle: item.mapLabel,
                open: () => onOpenInteraction(item.id),
              ),
          for (final map in project.maps)
            if (map.name.toLowerCase().contains(query))
              (
                id: map.id,
                kind: 'Carte',
                title: map.name,
                subtitle: 'Carte du projet',
                open: onOpenMap == null ? null : () => onOpenMap!(map.id),
              ),
        ];
    return StudioPanel(
      title: 'Résultats · ${results.length}',
      children: [
        if (results.isEmpty) const Text('Aucun document correspondant.'),
        if (results.isNotEmpty)
          SizedBox(
            height:
                (results.length < 5 ? results.length : 5) *
                MediaQuery.textScalerOf(context).scale(84),
            child: ListView.builder(
              key: const PageStorageKey('overview-search-list'),
              controller: resultsScroll,
              itemExtent: MediaQuery.textScalerOf(context).scale(84),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return _documentRow(
                  context,
                  key: ValueKey('overview-result-${item.kind}-${item.id}'),
                  icon: Icons.description_outlined,
                  tone: StudioTone.info,
                  title: item.title,
                  subtitle: '${item.kind} · ${item.subtitle}',
                  onTap: item.open,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _count(BuildContext context, IconData icon, int count, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            StudioIconTile(icon: icon, tone: StudioTone.info, size: 32),
            const SizedBox(width: 10),
            Text('$count', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );

  Widget _documentRow(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required StudioTone tone,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? leading,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: StudioActionCard(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      tone: tone,
      leading: leading,
      onPressed: onTap,
    ),
  );

  Widget _sceneArtwork(String id) => ClipRRect(
    borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
    child: SizedBox(
      width: 38,
      height: 38,
      child: NarrativeArtworkImage(
        key: ValueKey('narrative-scene-artwork-$id'),
        port: artworkPort,
        kind: NarrativeArtworkKind.scene,
        id: id,
        fallback: const StudioIconTile(
          icon: Icons.account_tree_outlined,
          tone: StudioTone.info,
          size: 38,
        ),
      ),
    ),
  );

  String _storyType(StorylineType type) => switch (type) {
    StorylineType.main => 'Principale',
    StorylineType.sideQuest => 'Secondaire',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Après-jeu',
    StorylineType.hiddenEvent => 'Événement caché',
  };

  String _eventName(NarrativeEventRecord record) =>
      record.definitionOrNull?.name ?? record.draftOrNull?.name ?? record.id;

  Iterable<T> _ordered<T>(List<T> values, int Function(T) order) {
    final indexed = values.indexed.toList()
      ..sort((a, b) {
        final compared = order(a.$2).compareTo(order(b.$2));
        return compared == 0 ? a.$1.compareTo(b.$1) : compared;
      });
    return indexed.map((entry) => entry.$2);
  }
}

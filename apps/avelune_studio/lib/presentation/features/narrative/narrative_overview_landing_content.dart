part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingContent on NarrativeOverviewLanding {
  Widget _stories(BuildContext context, double width) {
    final stories = overview.stories;
    final featuredScenes = stories.isEmpty && onOpenScene != null
        ? scenes.take(3).toList()
        : <SceneAsset>[];
    final columns = width >= 820
        ? 3
        : width >= 520
        ? 2
        : 1;
    final cardWidth = (width - 32 - (columns - 1) * 10) / columns;
    return StudioPanel(
      title: featuredScenes.isEmpty
          ? 'Histoires du projet · ${stories.length}'
          : 'Scènes du projet · ${scenes.length}',
      actions: [
        StudioButton(
          label: 'Histoires et progression',
          secondary: true,
          icon: Icons.route_outlined,
          onPressed: onProgression,
        ),
      ],
      children: [
        if (stories.isEmpty && featuredScenes.isEmpty)
          const Text(
            'Aucune histoire pour le moment. Créez votre premier parcours.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final scene in featuredScenes)
                SizedBox(
                  key: ValueKey('overview-featured-scene-${scene.id}'),
                  width: cardWidth,
                  height: 194,
                  child: StudioResourceCard(
                    name: scene.name,
                    category: 'Scène',
                    metadata: 'Ouvrir dans l’éditeur',
                    selected: false,
                    fillPreview: true,
                    onTap: () => onOpenScene!(scene.id),
                    preview: _scenePreview(context, scene.id),
                  ),
                ),
              for (var i = 0; i < stories.length; i++)
                SizedBox(
                  key: ValueKey('overview-story-${stories[i].id}'),
                  width: cardWidth,
                  height: 194,
                  child: StudioResourceCard(
                    name: stories[i].title,
                    category: _storyType(stories[i].type),
                    metadata:
                        '${stories[i].chapters.length} chapitre(s) · ${stories[i].chapters.expand((c) => c.steps).length} étape(s)',
                    selected: false,
                    fillPreview: true,
                    onTap: () => onOpenStory(stories[i].id),
                    preview: _storyPreview(context, stories[i]),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _scenePreview(BuildContext context, String id) {
    final colors = Theme.of(context).colorScheme;
    return NarrativeArtworkImage(
      key: ValueKey('narrative-featured-scene-artwork-$id'),
      port: artworkPort,
      kind: NarrativeArtworkKind.scene,
      id: id,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.tertiaryContainer, colors.surfaceContainerHighest],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.account_tree_outlined,
            size: 46,
            color: colors.onTertiaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _storyPreview(BuildContext context, StorylineAsset story) {
    final colors = Theme.of(context).colorScheme;
    final tone = switch (story.type) {
      StorylineType.main || StorylineType.episode => colors.primaryContainer,
      StorylineType.sideQuest ||
      StorylineType.hiddenEvent => colors.tertiaryContainer,
      _ => colors.secondaryContainer,
    };
    return NarrativeArtworkImage(
      key: ValueKey('narrative-story-artwork-${story.id}'),
      port: artworkPort,
      kind: NarrativeArtworkKind.story,
      id: story.id,
      fallback: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tone, colors.surfaceContainerHighest],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_stories_outlined,
            size: 46,
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _lower(BuildContext context, double width) {
    final compact = width < 700;
    final steps =
        <({String storyId, StorylineChapter chapter, StorylineStep step})>[
          for (final story in overview.stories)
            for (final chapter in _ordered(
              story.chapters,
              (item) => item.order,
            ))
              for (final step in _ordered(chapter.steps, (item) => item.order))
                (storyId: story.id, chapter: chapter, step: step),
        ];
    final stepPanel = StudioPanel(
      title: 'Étapes du projet · ${steps.length}',
      actions: [
        if (onProgression != null)
          StudioButton(
            label: 'Progression',
            secondary: true,
            onPressed: onProgression,
          ),
      ],
      children: [
        if (steps.isEmpty) const Text('Aucune étape créée.'),
        for (final item in steps.take(4))
          _documentRow(
            context,
            key: ValueKey('overview-step-${item.step.id}'),
            icon: Icons.radio_button_checked,
            tone: StudioTone.info,
            title: item.step.title,
            subtitle:
                '${item.chapter.title} · ${overview.stories.firstWhere((s) => s.id == item.storyId).title}',
            onTap: () => onOpenStep(item.storyId, item.step.id),
          ),
      ],
    );
    final maps = project.maps;
    final mapPanel = StudioPanel(
      title: 'Cartes du projet · ${maps.length}',
      children: [
        if (maps.isEmpty) const Text('Aucune carte dans ce projet.'),
        for (final map in maps.take(4))
          _documentRow(
            context,
            key: ValueKey('overview-map-${map.id}'),
            icon: Icons.map_outlined,
            tone: StudioTone.success,
            title: map.name,
            subtitle:
                '${overview.interactions.where((item) => item.mapId == map.id).length} interaction(s) liée(s)',
            onTap: onOpenMap == null ? null : () => onOpenMap!(map.id),
          ),
      ],
    );
    if (compact) {
      return Column(
        children: [stepPanel, const SizedBox(height: 12), mapPanel],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: stepPanel),
        const SizedBox(width: 12),
        Expanded(child: mapPanel),
      ],
    );
  }
}

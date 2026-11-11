part of 'narrative_overview_landing.dart';

extension NarrativeOverviewLandingSearch on NarrativeOverviewLanding {
  Widget _searchResults(BuildContext context, String query) {
    final matches = searchNarrativeOverview(
      overview: overview,
      project: project,
      scenes: scenes,
      dialogues: dialogues,
      events: events,
      query: query,
    );
    VoidCallback? opener(NarrativeOverviewSearchMatch item) =>
        switch (item.kind) {
          'Histoire' => () => onOpenStory(item.id),
          'Étape' => () => onOpenStep(item.storyId!, item.stepId!),
          'Scène' => onOpenScene == null ? null : () => onOpenScene!(item.id),
          'Dialogue' =>
            onOpenDialogue == null ? null : () => onOpenDialogue!(item.id),
          'Événement' =>
            onOpenEvent == null ? null : () => onOpenEvent!(item.id),
          'Interaction' => () => onOpenInteraction(item.id),
          'Carte' => onOpenMap == null ? null : () => onOpenMap!(item.id),
          _ => null,
        };
    final results = [
      for (final item in matches)
        (
          id: item.id,
          kind: item.kind,
          title: item.title,
          subtitle: item.subtitle,
          open: opener(item),
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

  String _storyType(StorylineType type) => narrativeOverviewStoryType(type);

  Iterable<T> _ordered<T>(List<T> values, int Function(T) order) =>
      orderedNarrativeOverview(values, order);
}

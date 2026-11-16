import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_rows.dart';
import 'package:avelune_studio/presentation/features/story/trame_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneCatalogFilters extends StatefulWidget {
  const SceneCatalogFilters({super.key, required this.catalog});
  final SceneCatalogController catalog;

  @override
  State<SceneCatalogFilters> createState() => _SceneCatalogFiltersState();
}

class _SceneCatalogFiltersState extends State<SceneCatalogFilters> {
  late final _query = TextEditingController(text: widget.catalog.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final l10n = context.l10n;
    final stories = catalog.storyValues;
    final storyOptions = {
      'all': l10n.sceneCatalogAllStories,
      'main': l10n.sceneCatalogMainStories,
      'side': l10n.sceneCatalogSideStories,
      'outside': l10n.trameOutside,
      for (final story in stories)
        'story:${story.id}': '${story.title} · ${l10n.trameType(story.type)}',
    };
    final chapters = {
      'all': l10n.sceneCatalogAllChapters,
      if (catalog.storyFilter != 'outside')
        'none': l10n.sceneCatalogWithoutChapter,
      for (final story in stories)
        if (sceneCatalogStoryMatches(story, catalog.storyFilter))
          for (final chapter in story.chapters)
            sceneCatalogChapterKey(story.id, chapter.id):
                '${story.title} · ${chapter.title}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('scene-catalog-search'),
          controller: _query,
          decoration: InputDecoration(
            labelText: l10n.sceneCatalogSearch,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (query) => catalog.filter(query: query),
        ),
        const SizedBox(height: StudioSpacing.l),
        Wrap(
          spacing: StudioSpacing.l,
          runSpacing: StudioSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: KeyedSubtree(
                key: const ValueKey('scene-catalog-story'),
                child: StudioSelect(
                  label: l10n.sceneCatalogStory,
                  value: storyOptions.containsKey(catalog.storyFilter)
                      ? catalog.storyFilter
                      : 'all',
                  options: storyOptions,
                  onChanged: catalog.stories.ready && catalog.storylines != null
                      ? (story) => catalog.filter(story: story)
                      : null,
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: KeyedSubtree(
                key: const ValueKey('scene-catalog-chapter'),
                child: StudioSelect(
                  label: l10n.trameMilestoneChapter,
                  value: chapters.containsKey(catalog.chapterFilter)
                      ? catalog.chapterFilter
                      : 'all',
                  options: chapters,
                  onChanged:
                      catalog.storyFilter == 'outside' ||
                          !catalog.stories.ready ||
                          catalog.storylines == null
                      ? null
                      : (chapter) => catalog.filter(chapter: chapter),
                ),
              ),
            ),
            StudioButton(
              key: const ValueKey('scene-catalog-clear'),
              label: l10n.sceneCatalogClear,
              variant: StudioButtonVariant.quiet,
              onPressed:
                  catalog.query.isEmpty &&
                      catalog.storyFilter == 'all' &&
                      catalog.chapterFilter == 'all'
                  ? null
                  : () {
                      _query.clear();
                      catalog.filter(query: '', story: 'all', chapter: 'all');
                    },
            ),
          ],
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(
          l10n.sceneCatalogFilterHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

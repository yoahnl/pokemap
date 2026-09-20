import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'story_labels.dart';

class StoryLibraryPanel extends StatelessWidget {
  const StoryLibraryPanel({
    super.key,
    required this.stories,
    required this.activeId,
    required this.search,
    required this.type,
    required this.dirtyIds,
    required this.onSearch,
    required this.onType,
    required this.onOpen,
    required this.onCreate,
  });
  final List<StorylineAsset> stories;
  final String? activeId;
  final TextEditingController search;
  final StorylineType? type;
  final Set<String> dirtyIds;
  final VoidCallback onSearch, onCreate;
  final ValueChanged<StorylineType?> onType;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filtered =
        stories
            .where(
              (s) =>
                  (type == null || s.type == type) &&
                  '${s.title} ${s.id} ${s.description ?? ''}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList()
          ..sort((a, b) {
            final order = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
            return order == 0 ? a.id.compareTo(b.id) : order;
          });
    return StudioPanel(
      compact: true,
      children: [
        Expanded(
          child: CustomScrollView(
            key: const PageStorageKey('story-library'),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Histoires',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    StudioSearchField(
                      controller: search,
                      label: 'Rechercher une histoire',
                      onChanged: (_) => onSearch(),
                    ),
                    const SizedBox(height: 10),
                    StudioSelect(
                      label: 'Type d’histoire',
                      value: type?.name ?? 'all',
                      options: {
                        'all': 'Tous les types',
                        for (final t in StorylineType.values)
                          t.name: storyTypeLabel(t),
                      },
                      onChanged: (value) => onType(
                        StorylineType.values
                            .where((t) => t.name == value)
                            .firstOrNull,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (activeId != null &&
                        !filtered.any((s) => s.id == activeId))
                      const StudioNotice(
                        'L’histoire ouverte est hors filtre. Son brouillon reste ouvert.',
                      ),
                  ],
                ),
              ),
              SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final story = filtered[index];
                  return Tooltip(
                    message: '${story.title} · ${story.id}',
                    child: StudioChoice(
                      key: ValueKey('story-library-${story.id}'),
                      label: story.title,
                      subtitle:
                          '${storyTypeLabel(story.type)} · ${dirtyIds.contains(story.id) ? 'Modifiée' : storyStatusLabel(story.status)}\n${story.id}',
                      leading: Icon(
                        story.type == StorylineType.sideQuest
                            ? Icons.alt_route
                            : Icons.auto_stories_outlined,
                      ),
                      selected: story.id == activeId,
                      onTap: () => onOpen(story.id),
                    ),
                  );
                },
              ),
              if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Aucune histoire dans cette recherche.'),
                  ),
                ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),
                    StudioButton(
                      label: 'Nouvelle histoire',
                      icon: Icons.add,
                      onPressed: onCreate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

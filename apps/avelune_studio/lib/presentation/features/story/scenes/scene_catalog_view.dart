import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_rows.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_states.dart';
import 'package:avelune_studio/presentation/features/story/story_workspace.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'scene_catalog_filters.dart';
import 'scene_catalog_inspector.dart';

class SceneCatalogView extends StatelessWidget {
  const SceneCatalogView({
    super.key,
    required this.catalog,
    required this.panels,
    this.openScene,
    this.onSelected,
  });
  final SceneCatalogController catalog;
  final StoryPanelBuilder panels;
  final SceneOpener? openScene;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (TickerMode.valuesOf(context).enabled) {
      scheduleMicrotask(() {
        catalog.sync();
        onSelected?.call(catalog.selected?.sceneId);
      });
    }
    final l10n = context.l10n;
    final state = gameMemoryResourceState(
      context,
      catalog.titles,
      loading: l10n.storyScenesLoading,
      onRetry: () => unawaited(catalog.open(force: true)),
    );
    final rows = catalog.visibleRows;
    final defined = rows.where((row) => !row.missing && !row.deleted).length;
    final references = rows.where((row) => row.missing).length;
    final deleted = rows.where((row) => row.deleted).length;
    return panels(
      state ??
          Column(
            key: const ValueKey('scene-catalog'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(StudioSpacing.xl),
                child: SceneCatalogFilters(catalog: catalog),
              ),
              if (!catalog.stories.ready || catalog.storylines == null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.xl,
                  ),
                  child: StudioNotice(l10n.sceneCatalogRelationsUnavailable),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: StudioSpacing.xl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: StudioSpacing.s,
                        runSpacing: StudioSpacing.s,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.sceneCatalogResults(defined),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (references > 0)
                            StudioBadge(
                              l10n.sceneCatalogReferences(references),
                            ),
                          if (deleted > 0)
                            StudioBadge(l10n.sceneCatalogRemovedCount(deleted)),
                        ],
                      ),
                    ),
                    StudioButton(
                      label: l10n.sceneCatalogRefresh,
                      icon: Icons.refresh,
                      variant: StudioButtonVariant.quiet,
                      onPressed: () => unawaited(catalog.open(force: true)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? StudioEmptyState(
                        icon: Icons.account_tree_outlined,
                        title: catalog.rows.isEmpty
                            ? l10n.storyScenesEmpty
                            : l10n.sceneCatalogNoResults,
                        description: catalog.rows.isEmpty
                            ? l10n.storyScenesEmptyHint
                            : l10n.sceneCatalogNoResultsHint,
                      )
                    : ListView.builder(
                        key: const ValueKey('story-scenes-list'),
                        padding: const EdgeInsets.all(StudioSpacing.xl),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final ordered = [
                            ...row.memberships.where(
                              (member) => sceneCatalogStoryMatches(
                                member.story,
                                catalog.storyFilter,
                              ),
                            ),
                            ...row.memberships.where(
                              (member) => !sceneCatalogStoryMatches(
                                member.story,
                                catalog.storyFilter,
                              ),
                            ),
                          ];
                          final links = ordered
                              .map(
                                (member) =>
                                    '${member.story.title} · ${member.chapter.title}',
                              )
                              .toSet();
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: StudioSpacing.s,
                            ),
                            child: StudioChoice(
                              key: ValueKey('story-scene-${row.id}'),
                              label: row.title.trim().isEmpty
                                  ? (row.missing
                                        ? (row.sceneId == null
                                              ? l10n.sceneCatalogMissingLink
                                              : l10n.sceneCatalogMissingScene)
                                        : l10n.storyUnnamedScene)
                                  : row.title,
                              subtitle: links.isEmpty
                                  ? (catalog.stories.ready &&
                                            catalog.storylines != null
                                        ? l10n.trameOutside
                                        : l10n.sceneCatalogUnknownMembership)
                                  : links.length == 1
                                  ? links.single
                                  : '${links.first}\n${l10n.sceneCatalogOtherPlaces(links.length - 1)}',
                              leading: Icon(
                                row.broken
                                    ? Icons.link_off
                                    : Icons.account_tree_outlined,
                              ),
                              trailing: row.deleted
                                  ? StudioBadge(l10n.sceneCatalogDeleted)
                                  : row.broken
                                  ? StudioBadge(l10n.sceneCatalogBroken)
                                  : row.unsaved
                                  ? StudioBadge(l10n.sceneCatalogDraft)
                                  : const Icon(Icons.chevron_right),
                              selected: catalog.selectedId == row.id,
                              onTap: () {
                                catalog.select(row.id);
                                onSelected?.call(row.sceneId);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
      SceneCatalogInspector(catalog: catalog, openScene: openScene),
    );
  }
}

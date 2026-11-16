import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_focus.dart';
import 'package:avelune_studio/features/scenes/application/scene_focus_controller.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_preview.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class SceneCatalogInspector extends StatelessWidget {
  const SceneCatalogInspector({
    super.key,
    required this.catalog,
    this.openScene,
  });
  final SceneCatalogController catalog;
  final SceneOpener? openScene;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = catalog.selected;
    if (row == null) {
      return StudioEmptyState(
        icon: Icons.touch_app_outlined,
        title: l10n.storySelectScene,
      );
    }
    final visible = TickerMode.valuesOf(context).enabled;
    final resource = catalog.preview;
    if (visible &&
        row.openable &&
        !resource.ready &&
        !resource.loading &&
        resource.problem == null) {
      scheduleMicrotask(() => unawaited(catalog.loadSelected()));
    }
    final document = resource.ready ? resource.value : null;
    final focus = document == null
        ? null
        : sceneCatalogFocus(catalog, document);
    final uses = focus?.launchers ?? const [];
    final open = row.openable && openScene != null
        ? () => openScene!(row.sceneId!, null)
        : null;
    return ListView(
      key: ValueKey('scene-catalog-inspector-${row.id}'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        Text(
          row.title.trim().isEmpty
              ? (row.sceneId == null
                    ? l10n.sceneCatalogMissingLink
                    : l10n.sceneCatalogMissingScene)
              : row.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: StudioSpacing.l),
        if (row.deleted) StudioNotice(l10n.sceneCatalogDeletedHint),
        if (row.broken) StudioNotice(l10n.sceneCatalogBrokenHint),
        StudioButton(
          key: const ValueKey('story-scene-open'),
          label: l10n.sceneGraphOpen,
          icon: Icons.open_in_new,
          onPressed: open,
        ),
        StudioSection(
          title: l10n.sceneCatalogMemberships,
          children: [
            if (row.memberships.isEmpty)
              Text(
                catalog.stories.ready && catalog.storylines != null
                    ? l10n.trameOutside
                    : l10n.sceneCatalogUnknownMembership,
              ),
            for (final member in row.memberships)
              Padding(
                padding: const EdgeInsets.only(bottom: StudioSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${member.story.title} · ${member.chapter.title}'),
                    if (member.step != null) Text(member.step!.title),
                    if (member.link != null) Text(member.link!.label),
                    if (member.broken || row.missing || row.deleted)
                      Text(l10n.sceneCatalogBroken),
                  ],
                ),
              ),
          ],
        ),
        if (row.openable) ...[
          if (resource.loading && document == null)
            StudioLoadingState(label: l10n.sceneFocusLoading),
          if (resource.problem != null) ...[
            StudioNotice(l10n.sceneCatalogPreviewUnavailable),
            StudioButton(
              label: l10n.memoryRetry,
              onPressed: () => unawaited(catalog.loadSelected(force: true)),
            ),
          ],
          if (document != null && visible) ...[
            if (document.scene.description?.trim().isNotEmpty == true)
              Text(document.scene.description!),
            const SizedBox(height: StudioSpacing.l),
            SceneGraphPreview(
              scene: focus!.scene ?? document.scene,
              project: null,
              onOpen: open,
            ),
            StudioSection(
              title: l10n.sceneCatalogKnownUses(uses.length),
              children: [
                Text(
                  l10n.sceneCatalogCoverage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (uses.isEmpty) Text(l10n.sceneCatalogNoKnownUse),
                for (final record in uses)
                  Padding(
                    padding: const EdgeInsets.only(top: StudioSpacing.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.name.trim().isEmpty
                              ? l10n.behavioursUnnamed
                              : record.name,
                        ),
                        Builder(
                          builder: (context) {
                            final place = focus.place(record);
                            return Text(
                              place.target == null
                                  ? l10n.behavioursWithoutMap
                                  : l10n.behavioursPlace(
                                      place.mapName ??
                                          l10n.behavioursMissingMap,
                                      place.elementName ??
                                          l10n.behavioursElementKind(
                                            place.target ==
                                                    MapStoryElementTarget.map
                                                ? 'map'
                                                : place.target!.name,
                                          ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                if (uses.length > 1)
                  StudioNotice(l10n.sceneFocusShared(uses.length)),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

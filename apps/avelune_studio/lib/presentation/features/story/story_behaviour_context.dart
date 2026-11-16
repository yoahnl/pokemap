import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_catalog_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryBehaviourContext extends StatefulWidget {
  const StoryBehaviourContext({
    super.key,
    required this.catalog,
    required this.openMap,
    required this.retry,
    required this.editable,
    required this.onSelected,
  });

  final MapBuilderStoryCatalogBinding catalog;
  final Future<bool> Function(String id) openMap;
  final Future<bool> Function(String id) retry;
  final bool editable;
  final ValueChanged<String?> onSelected;

  @override
  State<StoryBehaviourContext> createState() => _StoryBehaviourContextState();
}

class _StoryBehaviourContextState extends State<StoryBehaviourContext> {
  @override
  void initState() {
    super.initState();
    widget.catalog.addListener(_changed);
  }

  @override
  void didUpdateWidget(StoryBehaviourContext oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.catalog, widget.catalog)) {
      oldWidget.catalog.removeListener(_changed);
      widget.catalog.addListener(_changed);
    }
    scheduleMicrotask(() {
      if (mounted) unawaited(widget.catalog.sync());
    });
  }

  void _changed() {
    if (!mounted) return;
    widget.onSelected(
      widget.catalog.editor?.selectedBehaviour?.id ?? widget.catalog.selectedId,
    );
    setState(() {});
  }

  @override
  void dispose() {
    widget.catalog.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = widget.catalog;
    final editor = catalog.editor;
    final element = editor?.selected;
    final id = catalog.selectedId;
    return SingleChildScrollView(
      key: ValueKey('story-behaviour-context-$id'),
      padding: const EdgeInsets.all(StudioSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (catalog.loading)
            StudioNotice(l10n.behavioursLoading)
          else if (catalog.error case final error?)
            StudioNotice(error, isError: true)
          else if (editor != null && element != null)
            MapBuilderStoryInspector(
              binding: editor,
              element: element,
              enabled: widget.editable,
            )
          else
            StudioEmptyState(
              icon: Icons.people_outline,
              title: l10n.storyBehavioursHint,
              description: l10n.storyBehavioursOpenHint,
            ),
          if (id != null && !catalog.loading) ...[
            const SizedBox(height: StudioSpacing.l),
            if (catalog.error != null || editor?.editing?.problem != null)
              StudioButton(
                key: const ValueKey('story-behaviour-retry'),
                label: l10n.memoryRetry,
                onPressed: () => unawaited(widget.retry(id)),
              ),
            StudioButton(
              key: const ValueKey('story-behaviour-view-map'),
              label: l10n.behavioursOpenMap,
              icon: Icons.map_outlined,
              variant: StudioButtonVariant.quiet,
              onPressed: () => unawaited(widget.openMap(id)),
            ),
          ],
        ],
      ),
    );
  }
}

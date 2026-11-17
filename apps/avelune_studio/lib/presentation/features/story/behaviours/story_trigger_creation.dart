import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_catalog_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class StoryTriggerCreation extends StatefulWidget {
  const StoryTriggerCreation({
    super.key,
    required this.catalog,
    required this.maps,
    required this.editable,
    required this.openMap,
    required this.created,
    required this.cancel,
    this.mapId,
  });

  final MapBuilderStoryCatalogBinding catalog;
  final List<ProjectMapEntry> maps;
  final bool editable;
  final Future<bool> Function(String) openMap;
  final ValueChanged<String> created;
  final VoidCallback cancel;
  final String? mapId;

  @override
  State<StoryTriggerCreation> createState() => _StoryTriggerCreationState();
}

class _StoryTriggerCreationState extends State<StoryTriggerCreation> {
  late String? _mapId = widget.mapId;
  String? _source;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_load);
  }

  Future<void> _load() async {
    final request = ++_request;
    final id = _mapId;
    if (id != null) await widget.catalog.prepareCreation(id);
    if (mounted && request == _request) setState(() => _loading = false);
  }

  Future<void> _selectMap(String id) async {
    setState(() {
      _mapId = id;
      _source = null;
      _loading = true;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = widget.catalog.editor;
    final sources = [
      if (binding?.map?.id == _mapId)
        for (final element
            in binding?.elements?.elements ?? const <MapStoryElement>[])
          if (element.target != MapStoryElementTarget.map &&
              binding!.triggerKinds(element).isNotEmpty)
            element,
    ];
    final selected =
        sources.where((element) => element.key == _source).firstOrNull ??
        sources.firstOrNull;
    final problem =
        widget.catalog.error ?? binding?.editing?.problem ?? binding?.error;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(StudioSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioPageHeader(
            title: l10n.storyAddBehaviour,
            description: l10n.triggersCreateHint,
          ),
          if (widget.mapId == null)
            StudioSelect(
              key: const ValueKey('story-trigger-create-map-select'),
              label: l10n.triggersCreateMap,
              value: _mapId ?? '',
              options: {
                '': l10n.triggersCreateMap,
                for (final map in widget.maps) map.id: map.name,
              },
              onChanged: (id) {
                if (id.isNotEmpty) unawaited(_selectMap(id));
              },
            ),
          if (_loading)
            StudioNotice(l10n.behavioursLoading)
          else if (problem != null) ...[
            StudioNotice(problem, isError: true),
            StudioButton(
              key: const ValueKey('story-trigger-create-retry'),
              label: l10n.memoryRetry,
              onPressed: () {
                setState(() => _loading = true);
                unawaited(_load());
              },
            ),
          ] else if (_mapId != null && sources.isEmpty)
            StudioEmptyState(
              title: l10n.triggersNoSources,
              description: l10n.triggersNoSourcesHint,
              icon: Icons.add_location_alt_outlined,
              action: StudioButton(
                key: const ValueKey('story-trigger-create-map'),
                label: l10n.behavioursOpenMap,
                onPressed: () => unawaited(widget.openMap(_mapId!)),
              ),
            )
          else if (selected != null) ...[
            StudioSelect(
              key: const ValueKey('story-trigger-create-source'),
              label: l10n.triggersSource,
              value: selected.key,
              options: {
                for (final source in sources)
                  source.key: mapBuilderStoryName(source, l10n),
              },
              onChanged: (value) => setState(() => _source = value),
            ),
            const SizedBox(height: StudioSpacing.m),
            StudioButton(
              key: const ValueKey('story-trigger-create-confirm'),
              label: l10n.storyAddBehaviour,
              icon: Icons.add,
              onPressed:
                  widget.editable &&
                      !binding!.editingBlocked &&
                      binding.editing?.problem == null
                  ? () {
                      binding.select(selected);
                      if (!binding.addBehaviour(selected)) return;
                      final id = binding.selectedBehaviour!.id;
                      widget.catalog.selectedId = id;
                      widget.created(id);
                    }
                  : null,
            ),
          ],
          const SizedBox(height: StudioSpacing.m),
          StudioButton(
            label: l10n.cancel,
            variant: StudioButtonVariant.quiet,
            onPressed: widget.cancel,
          ),
        ],
      ),
    );
  }
}

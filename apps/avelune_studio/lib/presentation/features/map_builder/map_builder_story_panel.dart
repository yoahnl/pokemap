import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';

import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart'
    show mapBuilderStoryError;
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

export 'package:avelune_studio/presentation/features/map_builder/map_builder_story_labels.dart';

part 'map_builder_story_panel_items.dart';

class MapBuilderStoryPanel extends StatefulWidget {
  const MapBuilderStoryPanel({
    super.key,
    required this.outline,
    required this.binding,
  });

  final MapBuilderSpaceOutline outline;
  final MapBuilderStoryBinding binding;

  @override
  State<MapBuilderStoryPanel> createState() => _MapBuilderStoryPanelState();
}

class _MapBuilderStoryPanelState extends State<MapBuilderStoryPanel> {
  late final _search = TextEditingController(text: widget.binding.query);
  final _characterSearch = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _characterSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final outline = widget.outline;
    final binding = widget.binding;
    final visible = binding.visible;
    final selected = binding.selected?.key;
    final orphans = binding.orphans;
    final pending = (binding.elements?.elements ?? const <MapStoryElement>[])
        .where(
          (element) =>
              element.kind != MapStoryElementKind.map && !element.configured,
        )
        .length;
    return Ink(
      key: const ValueKey('map-space-panel'),
      width: mapBuilderLibraryWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(StudioSpacing.l),
              children: [
                Text(
                  outline.eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: StudioSpacing.xs),
                Text(
                  outline.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(outline.subtitle, style: muted),
                const SizedBox(height: StudioSpacing.l),
                TextField(
                  key: const ValueKey('map-story-search'),
                  controller: _search,
                  onChanged: binding.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: outline.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: StudioSpacing.m),
                StudioSelect(
                  key: const ValueKey('map-story-filter'),
                  label: l10n.storyShow,
                  value: binding.filter?.name ?? 'all',
                  options: {
                    'all': l10n.storyShowAll,
                    for (final kind in MapStoryElementKind.values)
                      kind.name: mapBuilderStoryKind(kind, l10n),
                  },
                  onChanged: (value) => binding.showKind(
                    MapStoryElementKind.values
                        .where((kind) => kind.name == value)
                        .firstOrNull,
                  ),
                ),
                const SizedBox(height: StudioSpacing.m),
                StudioButton(
                  key: const ValueKey('map-story-add'),
                  icon: binding.choosing ? Icons.close : Icons.add,
                  label: binding.choosing
                      ? l10n.storyAddClose
                      : outline.addLabel ?? l10n.storyAdd,
                  onPressed: binding.maps.active == null
                      ? null
                      : binding.toggleChoices,
                ),
                if (binding.choosing) ...[
                  const SizedBox(height: StudioSpacing.s),
                  ..._additions(context, muted),
                ],
                const SizedBox(height: StudioSpacing.l),
                if (orphans.isNotEmpty) ...[
                  _GroupHeader(
                    key: const ValueKey('map-story-repair'),
                    icon: Icons.build_outlined,
                    label: l10n.storyRepair,
                    count: orphans.length,
                  ),
                  if (binding.repairError case final error?) ...[
                    StudioNotice(
                      mapBuilderStoryError(error, l10n),
                      isError: true,
                    ),
                    const SizedBox(height: StudioSpacing.s),
                  ],
                  for (final orphan in orphans)
                    _Orphan(
                      key: ValueKey('map-story-orphan-${orphan.behaviour.id}'),
                      behaviour: orphan.behaviour,
                      binding: binding,
                    ),
                  const SizedBox(height: StudioSpacing.m),
                ],
                if (visible.isEmpty)
                  Text(
                    binding.query.trim().isEmpty
                        ? l10n.storyEmpty
                        : l10n.storyNoMatch,
                    key: const ValueKey('map-story-empty'),
                    style: muted,
                  ),
                for (final kind in MapStoryElementKind.values)
                  if (visible.any((element) => element.kind == kind)) ...[
                    _GroupHeader(
                      icon: mapBuilderStoryIcon(kind),
                      label: mapBuilderStoryKind(kind, l10n),
                      count: visible
                          .where((element) => element.kind == kind)
                          .length,
                    ),
                    for (final element in visible)
                      if (element.kind == kind)
                        StudioChoice(
                          key: ValueKey('map-story-element-${element.key}'),
                          leading: Icon(mapBuilderStoryIcon(kind), size: 16),
                          label: mapBuilderStoryName(element, l10n),
                          maxLines: 1,
                          subtitle: mapBuilderStoryState(element, l10n),
                          tone: element.configured ? null : StudioTone.warning,
                          selected: element.key == selected,
                          onTap: () => binding.select(element),
                        ),
                    const SizedBox(height: StudioSpacing.m),
                  ],
              ],
            ),
          ),
          if (pending > 0)
            Container(
              key: const ValueKey('map-story-pending'),
              padding: const EdgeInsets.all(StudioSpacing.l),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Text(l10n.storyPending(pending), style: muted),
            ),
        ],
      ),
    );
  }

  List<Widget> _additions(BuildContext context, TextStyle? muted) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final adding = binding.adding;
    final needle = _characterSearch.text.trim().toLowerCase();
    final selectedCharacter = binding.view()?.character?.id;
    return [
      for (final (kind, icon, label) in [
        (
          MapStoryAddition.character,
          Icons.person_outline,
          l10n.storyAddCharacter,
        ),
        (MapStoryAddition.sign, Icons.signpost_outlined, l10n.storyAddSign),
        (MapStoryAddition.zone, Icons.crop_square, l10n.storyAddZone),
      ])
        StudioChoice(
          key: ValueKey('map-story-add-${kind.name}'),
          dense: true,
          leading: Icon(icon, size: 16),
          label: label,
          selected: adding == kind,
          onTap: () => binding.startAdding(kind),
        ),
      if (adding == MapStoryAddition.character && !binding.armed) ...[
        const SizedBox(height: StudioSpacing.m),
        if (binding.charactersError case final error?)
          StudioNotice(error, isError: true)
        else if (binding.charactersLoading)
          Text(l10n.storyCharactersLoading, style: muted)
        else if (binding.characters.isEmpty)
          Text(l10n.storyNoCharacters, style: muted)
        else ...[
          TextField(
            key: const ValueKey('map-story-character-search'),
            controller: _characterSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.storyCharacterSearch,
              prefixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
          const SizedBox(height: StudioSpacing.s),
          for (final character in binding.characters)
            if (needle.isEmpty || character.name.toLowerCase().contains(needle))
              StudioChoice(
                key: ValueKey('map-story-character-${character.id}'),
                dense: true,
                label: character.name,
                selected: character.id == selectedCharacter,
                onTap: () => binding.chooseCharacter(character),
              ),
        ],
      ],
      if (binding.armed) ...[
        const SizedBox(height: StudioSpacing.m),
        Text(
          switch (adding) {
            MapStoryAddition.character => l10n.storyPlaceCharacter(
              binding.view()?.character?.name ?? '',
            ),
            MapStoryAddition.sign => l10n.storyPlaceSign,
            _ => l10n.storyDrawZone,
          },
          key: const ValueKey('map-story-add-hint'),
          style: muted,
        ),
      ],
    ];
  }
}

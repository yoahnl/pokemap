import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

part 'map_builder_gameplay_panel_rubrics.dart';

class MapBuilderGameplayPanel extends StatefulWidget {
  const MapBuilderGameplayPanel({
    super.key,
    required this.outline,
    required this.binding,
    required this.enabled,
  });

  final MapBuilderSpaceOutline outline;
  final MapBuilderGameplayBinding binding;
  final bool enabled;

  @override
  State<MapBuilderGameplayPanel> createState() =>
      _MapBuilderGameplayPanelState();
}

class _MapBuilderGameplayPanelState extends State<MapBuilderGameplayPanel> {
  late final _search = TextEditingController(text: widget.binding.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final outline = widget.outline;
    final binding = widget.binding;
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
                for (final rubric in outline.rubrics)
                  MapBuilderRubricTile(
                    rubric: rubric,
                    selected: rubric.id == binding.rubric,
                    onTap: mapBuilderGameplayRubrics.contains(rubric.id)
                        ? () {
                            _search.clear();
                            binding.openRubric(rubric.id);
                          }
                        : null,
                  ),
                const SizedBox(height: StudioSpacing.l),
                TextField(
                  key: const ValueKey('map-gameplay-search'),
                  controller: _search,
                  onChanged: binding.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: outline.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
                const SizedBox(height: StudioSpacing.m),
                ...switch (binding.rubric) {
                  'spawns' => _spawns(binding, muted),
                  'movement' => _movement(binding, muted),
                  'encounters' => _encounters(binding, muted),
                  'fieldObjects' => _fieldObjects(binding, muted),
                  _ => _connections(binding, outline, muted),
                },
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(StudioSpacing.l),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outline.note.$1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(outline.note.$2, style: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _connections(
    MapBuilderGameplayBinding binding,
    MapBuilderSpaceOutline outline,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    final connections = binding.connections;
    final passages = binding.passages;
    final selectedWarp = binding.selectedWarp?.id;
    final selectedConnection = binding.selectedConnection?.direction;
    return [
                MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      key: const ValueKey('map-gameplay-add-connection'),
                      leadingIcon: const Icon(Icons.swap_horiz, size: 18),
                      onPressed: binding.draftConnection,
                      child: Text(l10n.gameplayLinkNeighbour),
                    ),
                    MenuItemButton(
                      key: const ValueKey('map-gameplay-add-warp'),
                      leadingIcon: const Icon(
                        Icons.door_front_door_outlined,
                        size: 18,
                      ),
                      onPressed: binding.draftWarp,
                      child: Text(l10n.gameplayPlaceWarp),
                    ),
                  ],
                  builder: (context, menu, _) => StudioButton(
                    key: const ValueKey('map-gameplay-add'),
                    label: outline.addLabel ?? l10n.gameplayAddFallback,
                    icon: Icons.add,
                    onPressed: widget.enabled
                        ? () => menu.isOpen ? menu.close() : menu.open()
                        : null,
                  ),
                ),
                _Section(
                  title: l10n.gameplayNeighbours,
                  count: connections.length,
                ),
                if (connections.isEmpty)
                  Text(l10n.gameplayNoNeighbour, style: muted),
                for (final connection in connections)
                  StudioChoice(
                    key: ValueKey(
                      'map-gameplay-connection-${connection.direction.name}',
                    ),
                    leading: const Icon(Icons.swap_horiz, size: 18),
                    label: binding.mapName(connection.targetMapId),
                    subtitle: l10n.neighbourSubtitle(
                      l10n.direction(connection.direction).toLowerCase(),
                      connection.offset,
                    ),
                    selected: connection.direction == selectedConnection,
                    onTap: () => binding.selectConnection(connection.direction),
                  ),
                _Section(title: l10n.gameplayPassages, count: passages.length),
                if (passages.isEmpty)
                  Text(l10n.gameplayNoPassage, style: muted),
                for (final warp in passages)
                  StudioChoice(
                    key: ValueKey('map-gameplay-warp-${warp.id}'),
                    leading: const Icon(
                      Icons.door_front_door_outlined,
                      size: 18,
                    ),
                    label: binding.warpLabel(warp),
                    subtitle: l10n.warpCell(warp.pos.x, warp.pos.y),
                    selected: warp.id == selectedWarp,
                    onTap: () => binding.selectWarp(warp.id),
                  ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: StudioSpacing.xl,
        bottom: StudioSpacing.s,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

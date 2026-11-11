import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';

class MapBuilderCanvas extends StatelessWidget {
  const MapBuilderCanvas({
    super.key,
    required this.space,
    required this.onSpace,
    required this.entry,
    required this.tool,
    required this.onTool,
    required this.inspectorOpen,
    required this.onToggleInspector,
    required this.error,
    required this.surface,
  });

  final MapBuilderSpace space;
  final ValueChanged<MapBuilderSpace> onSpace;
  final ProjectMapEntry? entry;
  final StudioMapTool tool;
  final ValueChanged<StudioMapTool> onTool;
  final bool inspectorOpen;
  final VoidCallback onToggleInspector;
  final String? error;
  final Widget? surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final divider = BorderSide(color: scheme.outlineVariant);
    final entry = this.entry;
    final error = this.error;
    final surface = this.surface;
    return Material(
      color: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(bottom: divider),
            ),
            child: Row(
              children: [
                for (final item in MapBuilderSpace.values)
                  _SpaceTab(
                    space: item,
                    selected: item == space,
                    onTap: () => onSpace(item),
                  ),
              ],
            ),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
            decoration: BoxDecoration(border: Border(bottom: divider)),
            child: Row(
              children: [
                StudioTool(
                  key: const ValueKey('map-tool-select'),
                  label: 'Sélection',
                  icon: Icons.near_me_outlined,
                  selected: tool == StudioMapTool.select,
                  onPressed: () => onTool(StudioMapTool.select),
                ),
                const SizedBox(width: StudioSpacing.xs),
                StudioTool(
                  key: const ValueKey('map-tool-pan'),
                  label: 'Déplacer la vue',
                  icon: Icons.pan_tool_outlined,
                  selected: tool == StudioMapTool.pan,
                  onPressed: () => onTool(StudioMapTool.pan),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('map-inspector-toggle'),
                  tooltip: inspectorOpen
                      ? 'Masquer l’inspecteur'
                      : 'Afficher l’inspecteur',
                  isSelected: inspectorOpen,
                  onPressed: onToggleInspector,
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                ),
              ],
            ),
          ),
          if (entry != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                StudioSpacing.xl,
                StudioSpacing.m,
                StudioSpacing.xl,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: StudioColors.of(context).success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.s),
                  Text(entry.name, style: theme.textTheme.bodySmall),
                  Text(
                    '  ·  ${mapRoleLabel(entry.role)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: StudioNotice(error, isError: true),
            ),
          Expanded(
            child: surface == null
                ? Center(
                    child: error == null
                        ? const CircularProgressIndicator()
                        : const SizedBox(),
                  )
                : ClipRect(child: surface),
          ),
          Ink(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: divider),
            ),
            child: Row(
              children: [
                Text(
                  _toolLabel(tool),
                  key: const ValueKey('map-status-tool'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _toolLabel(StudioMapTool tool) => switch (tool) {
  StudioMapTool.select => 'Sélection',
  StudioMapTool.pan => 'Déplacer la vue',
  _ => 'Construction',
};

class _SpaceTab extends StatelessWidget {
  const _SpaceTab({
    required this.space,
    required this.selected,
    required this.onTap,
  });

  final MapBuilderSpace space;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey('map-space-${space.name}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            space.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

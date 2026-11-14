import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_border_warning.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_tool_labels.dart';

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
    this.borderWarnings = const {},
    this.reliefAvailable = false,
    this.reliefPalette,
    this.reliefNotice,
    required this.surface,
    required this.statusBar,
  });

  final MapBuilderSpace space;
  final ValueChanged<MapBuilderSpace> onSpace;
  final ProjectMapEntry? entry;
  final StudioMapTool tool;
  final ValueChanged<StudioMapTool> onTool;
  final bool inspectorOpen;
  final VoidCallback onToggleInspector;
  final String? error;
  final Set<String> borderWarnings;
  final bool reliefAvailable;
  final Widget? reliefPalette;
  final ({String message, bool isError})? reliefNotice;
  final Widget? surface;
  final Widget statusBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final divider = BorderSide(color: scheme.outlineVariant);
    final entry = this.entry;
    final error = this.error;
    final warning = mapBuilderBorderWarning(context.l10n, borderWarnings);
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
                  label: context.l10n.toolSelect,
                  icon: Icons.near_me_outlined,
                  selected: tool == StudioMapTool.select,
                  onPressed: () => onTool(StudioMapTool.select),
                ),
                const SizedBox(width: StudioSpacing.xs),
                StudioTool(
                  key: const ValueKey('map-tool-pan'),
                  label: context.l10n.toolPan,
                  icon: Icons.pan_tool_outlined,
                  selected: tool == StudioMapTool.pan,
                  onPressed: () => onTool(StudioMapTool.pan),
                ),
                if (reliefAvailable)
                  for (final (relief, label, icon) in [
                    (
                      StudioMapTool.relief,
                      context.l10n.toolRelief,
                      Icons.terrain_outlined,
                    ),
                    (
                      StudioMapTool.slope,
                      context.l10n.toolSlope,
                      Icons.trending_up,
                    ),
                    (
                      StudioMapTool.stair,
                      context.l10n.toolStair,
                      Icons.stairs_outlined,
                    ),
                  ]) ...[
                    const SizedBox(width: StudioSpacing.xs),
                    StudioTool(
                      key: ValueKey('map-tool-${relief.name}'),
                      label: label,
                      icon: icon,
                      selected: tool == relief,
                      onPressed: () => onTool(relief),
                    ),
                  ],
                const Spacer(),
                IconButton(
                  key: const ValueKey('map-inspector-toggle'),
                  tooltip: inspectorOpen
                      ? context.l10n.inspectorHide
                      : context.l10n.inspectorShow,
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
                    '  ·  ${context.l10n.mapRole(entry.role)}',
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
            )
          else if (warning != null)
            Padding(
              padding: const EdgeInsets.all(StudioSpacing.l),
              child: StudioNotice(
                warning,
                key: const ValueKey('map-border-warning'),
              ),
            ),
          Expanded(
            child: surface == null
                ? Center(
                    child: error == null
                        ? const CircularProgressIndicator()
                        : const SizedBox(),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?reliefPalette,
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(child: surface),
                            if (reliefNotice case final notice?
                                when error == null)
                              Positioned(
                                left: StudioSpacing.l,
                                top: StudioSpacing.l,
                                right: StudioSpacing.l,
                                child: StudioNotice(
                                  notice.message,
                                  key: const ValueKey('map-relief-notice'),
                                  isError: notice.isError,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          statusBar,
        ],
      ),
    );
  }
}

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
            context.l10n.mapBuilderSpace(space),
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

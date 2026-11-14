import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_relief_tool.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const mapBuilderReliefPaletteWidth = 72.0;

class MapBuilderReliefPalette extends StatelessWidget {
  const MapBuilderReliefPalette({
    super.key,
    required this.palette,
    required this.level,
    required this.onLevel,
  });

  final MapReliefPalette palette;
  final int level;
  final ValueChanged<int> onLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Ink(
      key: const ValueKey('map-relief-palette'),
      width: mapBuilderReliefPaletteWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          const SizedBox(height: StudioSpacing.s),
          Text(l10n.reliefPaletteTitle, style: theme.textTheme.labelSmall),
          IconButton(
            key: const ValueKey('map-relief-level-up'),
            tooltip: l10n.reliefLevelUp,
            onPressed: () => onLevel(level + 1),
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.s),
              children: [
                for (final value in palette.levels)
                  _ReliefLevelTile(
                    level: value,
                    selected: value == level,
                    ground: value == palette.ground,
                    onTap: () => onLevel(value),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('map-relief-level-down'),
            tooltip: l10n.reliefLevelDown,
            onPressed: level > 0 ? () => onLevel(level - 1) : null,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ReliefLevelTile extends StatelessWidget {
  const _ReliefLevelTile({
    required this.level,
    required this.selected,
    required this.ground,
    required this.onTap,
  });

  final int level;
  final bool selected, ground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final label = ground
        ? '${l10n.reliefLevel(level)} · ${l10n.reliefPaletteGround}'
        : l10n.reliefLevel(level);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: ValueKey('map-relief-level-$level'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(StudioSpacing.xs),
          child: Container(
            height: 28,
            margin: const EdgeInsets.only(bottom: StudioSpacing.xs),
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(StudioSpacing.xs),
              border: Border.all(
                color: ground ? scheme.tertiary : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ground) ...[
                  Icon(Icons.flag_outlined, size: 12, color: scheme.tertiary),
                  const SizedBox(width: StudioSpacing.xs),
                ],
                Text(
                  '$level',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

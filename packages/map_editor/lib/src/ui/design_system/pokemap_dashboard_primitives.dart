import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_card.dart';
import 'pokemap_tone.dart';

/// Structural surface for a full editor page or workspace area.
class PokeMapPageSurface extends StatelessWidget {
  const PokeMapPageSurface({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.contentSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// Compact square icon tile used by cards, sidebars and inspectors.
class PokeMapIconTile extends StatelessWidget {
  const PokeMapIconTile({
    super.key,
    required this.icon,
    this.tone = PokeMapTone.neutral,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final PokeMapTone tone;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = tone.resolve(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: colors.icon,
      ),
    );
  }
}

/// Metric/KPI tile for dashboard summaries.
class PokeMapMetricCard extends StatelessWidget {
  const PokeMapMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.tone = PokeMapTone.neutral,
    this.subtitle,
    this.badge,
    this.selected = false,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final PokeMapTone tone;
  final String? subtitle;
  final Widget? badge;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PokeMapIconTile(icon: icon, tone: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (badge != null) ...[
              const SizedBox(height: 6),
              IconTheme.merge(
                data: IconThemeData(color: toneColors.icon, size: 12),
                child: badge!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable dashboard module card for feature entry points.
class PokeMapModuleCard extends StatelessWidget {
  const PokeMapModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.tone = PokeMapTone.neutral,
    this.count,
    this.footer,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final PokeMapTone tone;
  final String? count;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PokeMapIconTile(icon: icon, tone: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (count != null)
                _PokeMapCountPill(
                  count: count!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Compact status tile for inspectors and health summaries.
class PokeMapStatusTile extends StatelessWidget {
  const PokeMapStatusTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = PokeMapTone.neutral,
  });

  final String label;
  final String value;
  final IconData? icon;
  final PokeMapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = tone.resolve(context);
    return Container(
      decoration: BoxDecoration(
        color: toneColors.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: toneColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: toneColors.icon),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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

/// Inspector container with the calmer V2 surface contract.
class PokeMapInspectorPanel extends StatelessWidget {
  const PokeMapInspectorPanel({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              Divider(color: colors.divider, height: 1),
            ],
            Padding(
              padding: padding ?? const EdgeInsets.all(14),
              child: child,
            ),
            if (footer != null) ...[
              Divider(color: colors.divider, height: 1),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class PokeMapSegmentedTab {
  const PokeMapSegmentedTab({
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Token-backed segmented tabs for mode switches.
class PokeMapSegmentedTabs extends StatelessWidget {
  const PokeMapSegmentedTabs({
    super.key,
    required this.tabs,
  });

  final List<PokeMapSegmentedTab> tabs;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.controlBorder),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tab in tabs) _PokeMapSegmentedTabButton(tab: tab),
        ],
      ),
    );
  }
}

class _PokeMapSegmentedTabButton extends StatelessWidget {
  const _PokeMapSegmentedTabButton({required this.tab});

  final PokeMapSegmentedTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final active = tab.selected;
    final enabled = tab.onTap != null;
    final foreground = active
        ? colors.brandPrimary
        : enabled
            ? colors.textSecondary
            : colors.textDisabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: GestureDetector(
        onTap: enabled ? tab.onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: active ? colors.cardSelected : colors.controlSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? colors.brandPrimaryBorder : colors.controlSurface,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.icon != null) ...[
                Icon(tab.icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokeMapCountPill extends StatelessWidget {
  const _PokeMapCountPill({required this.count});

  final String count;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        count,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../pokemap_button.dart';
import '../pokemap_empty_state.dart';

enum PokeMapCinematicLibraryMode { inGame, presentation }

enum PokeMapCinematicLibraryState { content, loading, empty, error }

class PokeMapCinematicFamilyTabs extends StatelessWidget {
  const PokeMapCinematicFamilyTabs({
    super.key,
    required this.selected,
    required this.inGameLabel,
    required this.presentationLabel,
    required this.onChanged,
  });

  final PokeMapCinematicLibraryMode selected;
  final String inGameLabel;
  final String presentationLabel;
  final ValueChanged<PokeMapCinematicLibraryMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.controlSurface,
          border: Border.all(color: colors.borderSubtle),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  semanticLabel: inGameLabel,
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(PokeMapCinematicLibraryMode.inGame),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.compact,
                  isSelected: selected == PokeMapCinematicLibraryMode.inGame,
                  child: Text(
                    inGameLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: PokeMapButton(
                  semanticLabel: presentationLabel,
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(
                          PokeMapCinematicLibraryMode.presentation,
                        ),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.compact,
                  isSelected:
                      selected == PokeMapCinematicLibraryMode.presentation,
                  child: Text(
                    presentationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PokeMapCinematicBreadcrumbItem {
  const PokeMapCinematicBreadcrumbItem({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

class PokeMapCinematicBreadcrumb extends StatelessWidget {
  const PokeMapCinematicBreadcrumb({
    super.key,
    required this.semanticLabel,
    required this.items,
  }) : assert(items.length > 0);

  final String semanticLabel;
  final List<PokeMapCinematicBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ),
              if (items[index].onPressed case final onPressed?)
                PokeMapButton(
                  semanticLabel: items[index].label,
                  onPressed: onPressed,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  child: Text(items[index].label),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    items[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class PokeMapCinematicLibraryStateSurface extends StatelessWidget {
  const PokeMapCinematicLibraryStateSurface({
    super.key,
    required this.state,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  final PokeMapCinematicLibraryState state;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (state == PokeMapCinematicLibraryState.content) {
      return child ?? const SizedBox.shrink();
    }
    if (state == PokeMapCinematicLibraryState.loading) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: '$title. $description',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                PokeMapCinematicSkeletonTile(),
                SizedBox(height: 8),
                PokeMapCinematicSkeletonTile(),
                SizedBox(height: 8),
                PokeMapCinematicSkeletonTile(),
              ],
            ),
          ),
        ),
      );
    }
    final isError = state == PokeMapCinematicLibraryState.error;
    return PokeMapEmptyState(
      title: title,
      description: description,
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.movie_filter_outlined,
      ),
      action: actionLabel == null
          ? null
          : PokeMapButton(
              semanticLabel: actionLabel,
              onPressed: onAction,
              variant: isError
                  ? PokeMapButtonVariant.secondary
                  : PokeMapButtonVariant.primary,
              child: Text(actionLabel!),
            ),
    );
  }
}

class PokeMapCinematicSkeletonTile extends StatelessWidget {
  const PokeMapCinematicSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Container(height: 10, color: colors.controlSurface),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.34,
                  child: Container(height: 8, color: colors.controlSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

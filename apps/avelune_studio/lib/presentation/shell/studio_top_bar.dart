import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/avelune_wordmark.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/widgets/studio_language_menu.dart';

const studioTopBarHeight = 64.0;
const studioTopBarWideWidth = 1440.0;

enum StudioSaveState { saved, unsaved, saving, failed }

class StudioTopBar extends StatelessWidget {
  const StudioTopBar({
    super.key,
    required this.projectName,
    required this.maps,
    required this.activeMapId,
    required this.onSelectMap,
    required this.onUndo,
    required this.onRedo,
    required this.saveState,
    required this.onSave,
    required this.onTestMap,
    this.testing = false,
  });

  final String projectName;
  final List<ProjectMapEntry> maps;
  final String? activeMapId;
  final ValueChanged<ProjectMapEntry>? onSelectMap;
  final VoidCallback? onUndo, onRedo, onSave, onTestMap;
  final StudioSaveState saveState;
  final bool testing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _build(context, compact: constraints.maxWidth < studioTopBarWideWidth),
  );

  Widget _build(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Ink(
      key: const ValueKey('studio-top-bar'),
      height: studioTopBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          const AveluneWordmark(height: 36),
          const SizedBox(width: StudioSpacing.xxl * 2),
          Flexible(
            child: Text(
              projectName,
              style: muted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.m),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
          _MapSelector(
            maps: maps,
            activeMapId: activeMapId,
            onSelect: onSelectMap,
          ),
          const Spacer(),
          _BarIcon(
            label: context.l10n.topBarUndo,
            icon: Icons.undo,
            onPressed: onUndo,
          ),
          _BarIcon(
            label: context.l10n.topBarRedo,
            icon: Icons.redo,
            onPressed: onRedo,
          ),
          const _BarDivider(),
          _BarAction(
            label: context.l10n.topBarContent,
            icon: Icons.layers_outlined,
            compact: compact,
          ),
          _BarAction(
            label: context.l10n.topBarMapSettings,
            icon: Icons.tune,
            compact: compact,
          ),
          const SizedBox(width: StudioSpacing.l),
          const StudioLanguageMenu(),
          const SizedBox(width: StudioSpacing.s),
          _SaveStatus(saveState),
          const SizedBox(width: StudioSpacing.l),
          StudioButton(
            key: const ValueKey('studio-save'),
            label: context.l10n.topBarSave,
            variant: StudioButtonVariant.secondary,
            loading: saveState == StudioSaveState.saving,
            onPressed: onSave,
          ),
          const SizedBox(width: StudioSpacing.m),
          StudioButton(
            key: const ValueKey('studio-test-map'),
            label: context.l10n.topBarTestMap,
            icon: Icons.play_arrow_rounded,
            variant: StudioButtonVariant.primary,
            loading: testing,
            onPressed: onTestMap,
          ),
        ],
      ),
    );
  }
}

class _MapSelector extends StatelessWidget {
  const _MapSelector({
    required this.maps,
    required this.activeMapId,
    required this.onSelect,
  });

  final List<ProjectMapEntry> maps;
  final String? activeMapId;
  final ValueChanged<ProjectMapEntry>? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = maps.where((entry) => entry.id == activeMapId).firstOrNull;
    return PopupMenuButton<ProjectMapEntry>(
      key: const ValueKey('studio-map-selector'),
      tooltip: context.l10n.topBarChangeMap,
      enabled: onSelect != null && maps.isNotEmpty,
      onSelected: onSelect,
      itemBuilder: (_) => [
        for (final entry in maps)
          PopupMenuItem(value: entry, child: Text(entry.name)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            active?.name ?? context.l10n.topBarNoMap,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: StudioSpacing.xs),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.label, required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    iconSize: 18,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.label,
    required this.icon,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.notAvailableYet(label),
    child: compact
        ? IconButton(
            onPressed: null,
            iconSize: 16,
            icon: Icon(icon, semanticLabel: label),
          )
        : TextButton.icon(
            onPressed: null,
            icon: Icon(icon, size: 16),
            label: Text(label),
          ),
  );
}

class _BarDivider extends StatelessWidget {
  const _BarDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: StudioSpacing.m),
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _SaveStatus extends StatelessWidget {
  const _SaveStatus(this.state);

  final StudioSaveState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studio = StudioColors.of(context);
    final (label, color) = switch (state) {
      StudioSaveState.saved => (context.l10n.saveStateSaved, studio.success),
      StudioSaveState.unsaved => (
        context.l10n.saveStateUnsaved,
        studio.warning,
      ),
      StudioSaveState.saving => (
        context.l10n.saveStateSaving,
        theme.colorScheme.primary,
      ),
      StudioSaveState.failed => (
        context.l10n.saveStateFailed,
        theme.colorScheme.error,
      ),
    };
    return Row(
      key: const ValueKey('studio-save-status'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: StudioSpacing.s),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

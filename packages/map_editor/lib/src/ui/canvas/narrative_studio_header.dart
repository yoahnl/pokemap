import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class NarrativeStudioHeader extends StatelessWidget {
  const NarrativeStudioHeader({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;

  @override
  Widget build(BuildContext context) {
    final currentLabel = _workspaceLabel(workspaceMode);
    return PokeMapPageSurface(
      key: const ValueKey('narrative-studio-header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final titleBlock = _HeaderTitle(currentLabel: currentLabel);
          final actions = _HeaderActions(
            workspaceMode: workspaceMode,
            onSelectOverview: onSelectOverview,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 8),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _workspaceLabel(EditorWorkspaceMode mode) {
    return switch (mode) {
      EditorWorkspaceMode.narrativeOverview => 'Aperçu',
      EditorWorkspaceMode.globalStory => 'Storylines',
      EditorWorkspaceMode.step => 'Scènes',
      EditorWorkspaceMode.cutscene => 'Cinématiques',
      EditorWorkspaceMode.dialogue => 'Dialogues',
      _ => 'Aperçu',
    };
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.currentLabel});

  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Narrative Studio',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Section : $currentLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.workspaceMode,
    required this.onSelectOverview,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('narrative-studio-header-actions'),
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        const _HeaderAction(
          key: ValueKey('narrative-studio-header-action-new-storyline'),
          icon: CupertinoIcons.add,
          label: 'Nouvelle storyline',
          disabledReason: 'Création de storyline à venir',
        ),
        _HeaderAction(
          key: const ValueKey('narrative-studio-header-action-overview'),
          icon: CupertinoIcons.eye,
          label: 'Aperçu',
          selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
          onTap: onSelectOverview,
        ),
        const _HeaderAction(
          key: ValueKey('narrative-studio-header-action-validate'),
          icon: CupertinoIcons.shield,
          label: 'Valider',
          disabledReason: 'Validation narrative globale non branchée en V0',
        ),
        const _HeaderAction(
          key: ValueKey('narrative-studio-header-action-search'),
          icon: CupertinoIcons.search,
          label: 'Recherche',
          disabledReason: 'Recherche narrative à venir',
        ),
        const _HeaderAction(
          key: ValueKey('narrative-studio-header-action-notifications'),
          icon: CupertinoIcons.bell,
          label: 'Notifications',
          disabledReason: 'Aucune source fiable en V0',
        ),
        const _HeaderAction(
          key: ValueKey('narrative-studio-header-action-settings'),
          icon: CupertinoIcons.gear,
          label: 'Paramètres',
          disabledReason: 'Paramètres narratifs à venir',
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.disabledReason,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String? disabledReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final button = PokeMapButton(
      onPressed: onTap,
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.secondary,
      isSelected: selected,
      leading: Icon(icon),
      child: Text(label),
    );

    if (enabled) {
      return Semantics(
        button: true,
        selected: selected,
        label: selected ? '$label - page active' : label,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: false,
      label: '$label - $disabledReason',
      child: button,
    );
  }
}

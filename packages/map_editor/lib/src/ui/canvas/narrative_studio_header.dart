import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../shared/cupertino_editor_widgets.dart';

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
    return Container(
      key: const ValueKey('narrative-studio-header'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF102033).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.activeAccent(context).withValues(alpha: 0.3),
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Narrative Studio / $currentLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Dashboard auteur',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
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
      spacing: 6,
      runSpacing: 6,
      children: [
        const _HeaderActionPill(
          key: ValueKey('narrative-studio-header-action-new-storyline'),
          icon: CupertinoIcons.add,
          label: 'Nouvelle storyline',
          disabledReason: 'Création de storyline à venir',
        ),
        _HeaderActionPill(
          key: const ValueKey('narrative-studio-header-action-overview'),
          icon: CupertinoIcons.eye,
          label: 'Aperçu',
          selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
          onTap: onSelectOverview,
        ),
        const _HeaderActionPill(
          key: ValueKey('narrative-studio-header-action-validate'),
          icon: CupertinoIcons.shield,
          label: 'Valider',
          disabledReason: 'Validation narrative globale non branchée en V0',
        ),
        const _HeaderActionPill(
          key: ValueKey('narrative-studio-header-action-search'),
          icon: CupertinoIcons.search,
          label: 'Recherche',
          disabledReason: 'Recherche narrative à venir',
        ),
        const _HeaderActionPill(
          key: ValueKey('narrative-studio-header-action-notifications'),
          icon: CupertinoIcons.bell,
          label: 'Notifications',
          disabledReason: 'Aucune source fiable en V0',
        ),
        const _HeaderActionPill(
          key: ValueKey('narrative-studio-header-action-settings'),
          icon: CupertinoIcons.gear,
          label: 'Paramètres',
          disabledReason: 'Paramètres narratifs à venir',
        ),
      ],
    );
  }
}

class _HeaderActionPill extends StatefulWidget {
  const _HeaderActionPill({
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

  bool get enabled => onTap != null;

  @override
  State<_HeaderActionPill> createState() => _HeaderActionPillState();
}

class _HeaderActionPillState extends State<_HeaderActionPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final selected = widget.selected;
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : enabled
            ? EditorChrome.accentPrimary
            : EditorChrome.subtleLabel(context);
    final fill = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.18)
        : enabled && _hovered
            ? EditorChrome.activeAccent(context).withValues(alpha: 0.12)
            : enabled
                ? const Color(0xFF14263A)
                : const Color(0xFF111B27);
    final border = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.68)
        : enabled && _hovered
            ? EditorChrome.activeAccent(context).withValues(alpha: 0.38)
            : const Color(0x334A89FF);
    final textColor = enabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context).withValues(alpha: 0.62);

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: '${widget.label} — ${widget.disabledReason}',
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${widget.label} — page active' : widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: widget.onTap,
          child: content,
        ),
      ),
    );
  }
}

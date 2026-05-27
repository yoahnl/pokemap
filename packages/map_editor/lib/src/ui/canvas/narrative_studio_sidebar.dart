import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../shared/cupertino_editor_widgets.dart';

class NarrativeStudioSidebar extends StatelessWidget {
  const NarrativeStudioSidebar({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.compact,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Navigation interne Narrative Studio',
      child: Container(
        key: const ValueKey('narrative-studio-sidebar'),
        width: compact ? 132 : 154,
        decoration: BoxDecoration(
          color: _NarrativeSidebarColors.panelFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _NarrativeSidebarColors.panelBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Narrative Studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _NarrativeSidebarColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Navigation interne',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _NarrativeSidebarColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-overview'),
                icon: CupertinoIcons.square_grid_2x2,
                label: 'Aperçu',
                subtitle: 'Dashboard auteur',
                selected:
                    workspaceMode == EditorWorkspaceMode.narrativeOverview,
                onTap: onSelectOverview,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-storylines'),
                icon: CupertinoIcons.doc_text,
                label: 'Storylines',
                subtitle: 'Histoire globale',
                selected: workspaceMode == EditorWorkspaceMode.globalStory,
                onTap: onSelectGlobal,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-scenes'),
                icon: CupertinoIcons.square_grid_2x2,
                label: 'Scènes',
                subtitle: 'Étapes narratives',
                selected: workspaceMode == EditorWorkspaceMode.step,
                onTap: onSelectStep,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-cutscenes'),
                icon: CupertinoIcons.film,
                label: 'Cinématiques',
                subtitle: 'Studio existant',
                selected: workspaceMode == EditorWorkspaceMode.cutscene,
                onTap: onSelectCutscene,
              ),
              _SidebarEntry(
                key: const ValueKey('narrative-studio-sidebar-dialogues'),
                icon: CupertinoIcons.text_bubble,
                label: 'Dialogues',
                subtitle: 'Studio existant',
                selected: workspaceMode == EditorWorkspaceMode.dialogue,
                onTap: onSelectDialogue,
              ),
              const SizedBox(height: 4),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-facts'),
                icon: CupertinoIcons.doc_text,
                label: 'Facts',
                subtitle: 'Nécessite un modèle',
                selected: false,
              ),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-world-rules'),
                icon: CupertinoIcons.checkmark_seal,
                label: 'Règles du monde',
                subtitle: 'À venir',
                selected: false,
              ),
              const _SidebarEntry(
                key: ValueKey('narrative-studio-sidebar-validator'),
                icon: CupertinoIcons.check_mark_circled,
                label: 'Validateur',
                subtitle: 'Non branché',
                selected: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarEntry extends StatelessWidget {
  const _SidebarEntry({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : _enabled
            ? EditorChrome.accentPrimary
            : _NarrativeSidebarColors.disabledText;
    final borderColor = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.72)
        : _NarrativeSidebarColors.itemBorder;
    final fill = selected
        ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.14)
        : _enabled
            ? _NarrativeSidebarColors.itemFill
            : _NarrativeSidebarColors.disabledFill;

    final content = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _enabled
                        ? _NarrativeSidebarColors.primaryText
                        : _NarrativeSidebarColors.disabledText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Actif' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selected ? accent : _NarrativeSidebarColors.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!_enabled) {
      return content;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: content,
    );
  }
}

abstract final class _NarrativeSidebarColors {
  static const panelFill = Color(0xFF102033);
  static const panelBorder = Color(0x334A89FF);
  static const itemFill = Color(0xFF14263A);
  static const disabledFill = Color(0xFF111B27);
  static const itemBorder = Color(0x2E6BA8FF);
  static const primaryText = Color(0xFFE6EEF8);
  static const mutedText = Color(0xFF8EA0B5);
  static const disabledText = Color(0xFF718197);
}

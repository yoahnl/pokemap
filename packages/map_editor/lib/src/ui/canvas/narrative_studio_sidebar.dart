import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

class NarrativeStudioSidebar extends StatelessWidget {
  const NarrativeStudioSidebar({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectScenes,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.compact,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectScenes;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      label: 'Navigation interne Narrative Studio',
      child: SizedBox(
        key: const ValueKey('narrative-studio-sidebar'),
        width: compact ? 148 : 164,
        child: PokeMapPanel(
          expandChild: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Narrative Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Navigation interne',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-overview'),
                  icon: CupertinoIcons.square_grid_2x2,
                  label: 'Aperçu',
                  subtitle: 'Vue d’ensemble',
                  selected:
                      workspaceMode == EditorWorkspaceMode.narrativeOverview,
                  onTap: onSelectOverview,
                ),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-storylines'),
                  icon: CupertinoIcons.doc_text,
                  label: 'Storylines',
                  subtitle: 'Histoire globale',
                  selected: workspaceMode == EditorWorkspaceMode.globalStory,
                  onTap: onSelectGlobal,
                ),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-scenes'),
                  icon: CupertinoIcons.square_stack_3d_up,
                  label: 'Scènes',
                  subtitle: 'Builder à venir',
                  selected: workspaceMode == EditorWorkspaceMode.scenes,
                  onTap: onSelectScenes,
                ),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-steps'),
                  icon: CupertinoIcons.square_grid_2x2,
                  label: 'Étapes',
                  subtitle: 'Étapes narratives',
                  selected: workspaceMode == EditorWorkspaceMode.step,
                  onTap: onSelectStep,
                ),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-cutscenes'),
                  icon: CupertinoIcons.film,
                  label: 'Cinématiques',
                  subtitle: 'Studio existant',
                  selected: workspaceMode == EditorWorkspaceMode.cutscene,
                  onTap: onSelectCutscene,
                ),
                _NarrativeSidebarItem(
                  key: const ValueKey('narrative-studio-sidebar-dialogues'),
                  icon: CupertinoIcons.text_bubble,
                  label: 'Dialogues',
                  subtitle: 'Studio existant',
                  selected: workspaceMode == EditorWorkspaceMode.dialogue,
                  onTap: onSelectDialogue,
                ),
                const SizedBox(height: 6),
                const _SidebarSectionLabel('Non branché V0'),
                const SizedBox(height: 4),
                const _NarrativeSidebarItem(
                  key: ValueKey('narrative-studio-sidebar-facts'),
                  icon: CupertinoIcons.doc_text,
                  label: 'Facts',
                  subtitle: 'Nécessite un modèle',
                  selected: false,
                ),
                const _NarrativeSidebarItem(
                  key: ValueKey('narrative-studio-sidebar-world-rules'),
                  icon: CupertinoIcons.checkmark_seal,
                  label: 'Règles du monde',
                  subtitle: 'À venir',
                  selected: false,
                ),
                const _NarrativeSidebarItem(
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
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 1),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NarrativeSidebarItem extends StatelessWidget {
  const _NarrativeSidebarItem({
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: PokeMapSidebarItem(
        icon: Icon(icon),
        label: label,
        subtitle: selected ? 'Actif' : subtitle,
        selected: selected,
        disabled: onTap == null,
        onTap: onTap,
      ),
    );
  }
}

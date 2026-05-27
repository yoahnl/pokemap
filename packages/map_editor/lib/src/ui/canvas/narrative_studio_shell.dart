import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../shared/cupertino_editor_widgets.dart';

class NarrativeStudioShell extends StatelessWidget {
  const NarrativeStudioShell({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.child,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Narrative Studio Shell',
      child: Column(
        key: const ValueKey('narrative-studio-shell'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NarrativeStudioTransientNavigation(
            workspaceMode: workspaceMode,
            onSelectOverview: onSelectOverview,
            onSelectGlobal: onSelectGlobal,
            onSelectStep: onSelectStep,
            onSelectCutscene: onSelectCutscene,
            onSelectDialogue: onSelectDialogue,
          ),
          const SizedBox(height: 8),
          Expanded(
            key: const ValueKey('narrative-studio-main-content'),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _NarrativeStudioTransientNavigation extends StatelessWidget {
  const _NarrativeStudioTransientNavigation({
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('narrative-studio-transitional-navigation'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ModeChip(
            label: 'Aperçu',
            selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
            onTap: onSelectOverview,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Histoire globale',
            selected: workspaceMode == EditorWorkspaceMode.globalStory,
            onTap: onSelectGlobal,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Étape',
            selected: workspaceMode == EditorWorkspaceMode.step,
            onTap: onSelectStep,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Cinématique',
            selected: workspaceMode == EditorWorkspaceMode.cutscene,
            onTap: onSelectCutscene,
          ),
          const SizedBox(width: 6),
          _ModeChip(
            label: 'Dialogue',
            selected: workspaceMode == EditorWorkspaceMode.dialogue,
            onTap: onSelectDialogue,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? EditorChrome.inspectorJoyCyan
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? EditorChrome.islandFillElevated(context)
              : EditorChrome.sidebarHoverFill(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent.withValues(alpha: 0.7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: accent,
          ),
        ),
      ),
    );
  }
}

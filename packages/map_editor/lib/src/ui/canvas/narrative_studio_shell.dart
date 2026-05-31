import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import 'narrative_studio_sidebar.dart';

class NarrativeStudioShell extends StatelessWidget {
  const NarrativeStudioShell({
    super.key,
    required this.workspaceMode,
    required this.onSelectOverview,
    required this.onSelectGlobal,
    required this.onSelectScenes,
    required this.onSelectStep,
    required this.onSelectCutscene,
    required this.onSelectDialogue,
    required this.onSelectFacts,
    required this.onSelectWorldRules,
    required this.child,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectScenes;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
  final VoidCallback onSelectFacts;
  final VoidCallback onSelectWorldRules;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Narrative Studio Shell',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactSidebar = constraints.maxWidth < 1100;
          return Row(
            key: const ValueKey('narrative-studio-shell'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NarrativeStudioSidebar(
                workspaceMode: workspaceMode,
                onSelectOverview: onSelectOverview,
                onSelectGlobal: onSelectGlobal,
                onSelectScenes: onSelectScenes,
                onSelectStep: onSelectStep,
                onSelectCutscene: onSelectCutscene,
                onSelectDialogue: onSelectDialogue,
                onSelectFacts: onSelectFacts,
                onSelectWorldRules: onSelectWorldRules,
                compact: compactSidebar,
              ),
              SizedBox(width: compactSidebar ? 7 : 8),
              Expanded(
                key: const ValueKey('narrative-studio-main-content'),
                child: child,
              ),
            ],
          );
        },
      ),
    );
  }
}

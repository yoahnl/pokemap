import 'package:flutter/cupertino.dart';

import '../../features/editor/state/models/editor_workspace_mode.dart';
import 'narrative_studio_header.dart';
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
    required this.child,
  });

  final EditorWorkspaceMode workspaceMode;
  final VoidCallback onSelectOverview;
  final VoidCallback onSelectGlobal;
  final VoidCallback onSelectScenes;
  final VoidCallback onSelectStep;
  final VoidCallback onSelectCutscene;
  final VoidCallback onSelectDialogue;
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
                compact: compactSidebar,
              ),
              SizedBox(width: compactSidebar ? 7 : 8),
              Expanded(
                key: const ValueKey('narrative-studio-main-content'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NarrativeStudioHeader(
                      workspaceMode: workspaceMode,
                      onSelectOverview: onSelectOverview,
                    ),
                    const SizedBox(height: 7),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

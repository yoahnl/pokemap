import 'package:map_core/map_core.dart';

import '../../../features/editor/state/models/editor_workspace_mode.dart';

/// Incremental adoption gate for the shared Narrative Studio product shell.
///
/// The policy is deliberately detached from widgets and providers so routing
/// can be tested as a complete truth table before any workspace is migrated.
abstract final class NarrativeStudioShellPolicy {
  static bool shouldUseProductShell({
    required EditorWorkspaceMode workspaceMode,
    required EventSystemMode eventSystemMode,
  }) {
    if (workspaceMode == EditorWorkspaceMode.scenes ||
        workspaceMode == EditorWorkspaceMode.globalStory ||
        workspaceMode == EditorWorkspaceMode.step ||
        workspaceMode == EditorWorkspaceMode.cinematics ||
        workspaceMode == EditorWorkspaceMode.dialogue ||
        workspaceMode == EditorWorkspaceMode.facts ||
        workspaceMode == EditorWorkspaceMode.shops ||
        workspaceMode == EditorWorkspaceMode.worldRules ||
        workspaceMode == EditorWorkspaceMode.narrativeValidator ||
        workspaceMode == EditorWorkspaceMode.narrativeOverview) {
      return true;
    }
    if (workspaceMode != EditorWorkspaceMode.events) return false;

    return switch (eventSystemMode) {
      EventSystemMode.legacyOnly => true,
      EventSystemMode.dualRead || EventSystemMode.v2Only => true,
    };
  }
}

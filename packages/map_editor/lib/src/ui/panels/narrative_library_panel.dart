import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Navigateur narratif dans la colonne gauche.
///
/// Rôle produit:
/// - fournir une navigation claire vers les 3 workspaces centraux
/// - exposer rapidement Global Story / Steps / Cutscenes / Outcomes
/// - rester un navigateur (pas un éditeur principal)
class NarrativeLibraryPanel extends ConsumerWidget {
  const NarrativeLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final narrative = ref.watch(narrativeWorkspaceControllerProvider);
    final narrativeController =
        ref.read(narrativeWorkspaceControllerProvider.notifier);
    final projection = ref.watch(narrativeWorkspaceProjectionProvider);

    if (projection == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    return ListView(
      padding: embedded
          ? kInspectorTileBodyPadding
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        _WorkspaceQuickActions(
          editor: editor,
          onGlobal: () {
            notifier.selectGlobalStoryWorkspace();
            narrativeController.openGlobalStory(
              scenarioId: narrative.selectedGlobalStoryId,
            );
          },
          onStep: () {
            notifier.selectStepWorkspace();
            narrativeController.openStep(
              stepId: narrative.selectedStepId,
              globalScenarioId: narrative.selectedGlobalStoryId,
            );
          },
          onCutscene: () {
            notifier.selectCutsceneWorkspace();
            narrativeController.openCutscene(
              cutsceneScenarioId: narrative.selectedCutsceneId,
            );
          },
        ),
        const SizedBox(height: 10),
        const EditorSidebarSectionTitle('GLOBAL STORY', leftInset: 2),
        ...projection.globalStories.map(
          (scenario) => EditorSidebarListRow(
            selected: narrative.selectedGlobalStoryId == scenario.id &&
                editor.workspaceMode == EditorWorkspaceMode.globalStory,
            onTap: () {
              narrativeController.selectGlobalStory(scenario.id);
              narrativeController.openGlobalStory(scenarioId: scenario.id);
              notifier.selectGlobalStoryWorkspace();
            },
            leading: const MacosIcon(CupertinoIcons.link),
            title: Text(scenario.name),
            subtitle: Text(
              '${scenario.nodeCount} nodes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const EditorSidebarSectionTitle('STEPS', leftInset: 2),
        ...projection.steps.map(
          (step) => EditorSidebarListRow(
            selected: narrative.selectedStepId == step.id &&
                editor.workspaceMode == EditorWorkspaceMode.step,
            onTap: () {
              narrativeController.selectStep(step.id);
              narrativeController.openStep(
                stepId: step.id,
                globalScenarioId: step.globalScenarioId,
              );
              notifier.selectStepWorkspace();
            },
            leading: const MacosIcon(CupertinoIcons.flag),
            title: Text(step.name),
            subtitle: Text(
              'Cutscenes: ${step.linkedCutsceneIds.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const EditorSidebarSectionTitle('CUTSCENES', leftInset: 2),
        ...projection.localEventFlows.map(
          (scenario) => EditorSidebarListRow(
            selected: narrative.selectedCutsceneId == scenario.id &&
                editor.workspaceMode == EditorWorkspaceMode.cutscene,
            onTap: () {
              narrativeController.selectCutscene(scenario.id);
              narrativeController.openCutscene(
                cutsceneScenarioId: scenario.id,
              );
              notifier.selectCutsceneWorkspace();
            },
            leading: const MacosIcon(CupertinoIcons.play_rectangle),
            title: Text(scenario.name),
            subtitle: Text(
              '${scenario.nodeCount} nodes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const EditorSidebarSectionTitle('OUTCOMES', leftInset: 2),
        ...projection.outcomes.map(
          (outcome) => EditorSidebarListRow(
            selected: narrative.selectedOutcomeId == outcome.id,
            onTap: () => narrativeController.selectOutcome(outcome.id),
            leading: const MacosIcon(CupertinoIcons.circle_grid_3x3_fill),
            title: Text(outcome.id),
            subtitle: Text(
              'emitters: ${outcome.emittedByScenarioIds.length} • consumers: ${outcome.consumedByScenarioIds.length}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceQuickActions extends StatelessWidget {
  const _WorkspaceQuickActions({
    required this.editor,
    required this.onGlobal,
    required this.onStep,
    required this.onCutscene,
  });

  final EditorState editor;
  final VoidCallback onGlobal;
  final VoidCallback onStep;
  final VoidCallback onCutscene;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ActionChip(
          label: 'Global Story',
          selected: editor.workspaceMode == EditorWorkspaceMode.globalStory,
          onTap: onGlobal,
        ),
        _ActionChip(
          label: 'Step',
          selected: editor.workspaceMode == EditorWorkspaceMode.step,
          onTap: onStep,
        ),
        _ActionChip(
          label: 'Cutscene',
          selected: editor.workspaceMode == EditorWorkspaceMode.cutscene,
          onTap: onCutscene,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? EditorChrome.inspectorJoyMint
        : EditorChrome.subtleLabel(context);
    return CupertinoButton(
      minimumSize: const Size(28, 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.75)),
          color: selected
              ? EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
                )
              : EditorChrome.sidebarHoverFill(context),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';
import '../../theme/theme.dart';

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
          'Aucun projet chargé',
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
          ),
        ),
      );
    }

    final primaryGlobalStory = projection.globalStories.isEmpty
        ? null
        : projection.globalStories.first;
    final additionalGlobalStories = projection.globalStories.length > 1
        ? projection.globalStories.length - 1
        : 0;

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
          onDialogue: notifier.selectDialogueWorkspace,
        ),
        const SizedBox(height: 10),
        const EditorSidebarSectionTitle('HISTOIRE GLOBALE (UNIQUE)', leftInset: 2),
        if (primaryGlobalStory == null)
          EditorSidebarListRow(
            selected: false,
            onTap: () {},
            leading: const MacosIcon(CupertinoIcons.exclamationmark_triangle),
            title: const Text('Aucun scénario global'),
          ),
        if (primaryGlobalStory != null)
          EditorSidebarListRow(
            selected:
                narrative.selectedGlobalStoryId == primaryGlobalStory.id &&
                    editor.workspaceMode == EditorWorkspaceMode.globalStory,
            onTap: () {
              narrativeController.selectGlobalStory(primaryGlobalStory.id);
              narrativeController.openGlobalStory(
                scenarioId: primaryGlobalStory.id,
              );
              notifier.selectGlobalStoryWorkspace();
            },
            leading: const MacosIcon(CupertinoIcons.link),
            title: Text(primaryGlobalStory.name),
            subtitle: Text(
              '${primaryGlobalStory.nodeCount} nodes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (additionalGlobalStories > 0) ...[
          const SizedBox(height: 6),
          InspectorEmbeddedFootnote(
            text:
                'Plusieurs scénarios globaux détectés. L’éditeur fonctionne avec le premier pour respecter la règle métier "un seul Global Story".',
            accent: context.pokeMapColors.warning,
          ),
        ],
        const SizedBox(height: 8),
        const EditorSidebarSectionTitle('ÉTAPES', leftInset: 2),
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
        const EditorSidebarSectionTitle('CINÉMATIQUES', leftInset: 2),
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
        const EditorSidebarSectionTitle('RÉSULTATS', leftInset: 2),
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
    required this.onDialogue,
  });

  final EditorState editor;
  final VoidCallback onGlobal;
  final VoidCallback onStep;
  final VoidCallback onCutscene;
  final VoidCallback onDialogue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _ActionChip(
          label: 'Histoire globale',
          selected: editor.workspaceMode == EditorWorkspaceMode.globalStory,
          onTap: onGlobal,
        ),
        _ActionChip(
          label: 'Étape',
          selected: editor.workspaceMode == EditorWorkspaceMode.step,
          onTap: onStep,
        ),
        _ActionChip(
          label: 'Cinématique',
          selected: editor.workspaceMode == EditorWorkspaceMode.cutscene,
          onTap: onCutscene,
        ),
        _ActionChip(
          label: 'Dialogue',
          selected: editor.workspaceMode == EditorWorkspaceMode.dialogue,
          onTap: onDialogue,
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
    final colors = context.pokeMapColors;
    final color = selected
        ? colors.brandPrimary
        : colors.textSecondary;
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
              ? colors.surfaceSelected
              : colors.surfaceSubtle,
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

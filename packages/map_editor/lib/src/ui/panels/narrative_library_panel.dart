import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../design_system/design_system.dart';
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
          onOverview: notifier.selectNarrativeOverviewWorkspace,
          onGlobal: () {
            notifier.selectGlobalStoryWorkspace();
            narrativeController.openGlobalStory(
              scenarioId: narrative.selectedGlobalStoryId,
            );
          },
          onScenes: () {
            notifier.selectScenesWorkspace();
            narrativeController.openScenes();
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
        const EditorSidebarSectionTitle('HISTOIRE GLOBALE (UNIQUE)',
            leftInset: 2),
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
        const EditorSidebarSectionTitle('SCÈNES', leftInset: 2),
        EditorSidebarListRow(
          selected: editor.workspaceMode == EditorWorkspaceMode.scenes,
          onTap: () {
            notifier.selectScenesWorkspace();
            narrativeController.openScenes();
          },
          leading: const MacosIcon(CupertinoIcons.square_stack_3d_up),
          title: const Text('Scènes'),
          subtitle: Text('${projection.scenes.length} scènes'),
        ),
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
    required this.onOverview,
    required this.onGlobal,
    required this.onScenes,
    required this.onStep,
    required this.onCutscene,
    required this.onDialogue,
  });

  final EditorState editor;
  final VoidCallback onOverview;
  final VoidCallback onGlobal;
  final VoidCallback onScenes;
  final VoidCallback onStep;
  final VoidCallback onCutscene;
  final VoidCallback onDialogue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.narrativeOverview,
                  onPressed: onOverview,
                  child: const Text('Aperçu'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.globalStory,
                  onPressed: onGlobal,
                  child: const Text('Histoire globale'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.scenes,
                  onPressed: onScenes,
                  child: const Text('Scènes'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.step,
                  onPressed: onStep,
                  child: const Text('Étape'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.cutscene,
                  onPressed: onCutscene,
                  child: const Text('Cinématique'),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 32,
                child: PokeMapButton(
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.secondary,
                  isSelected: editor.workspaceMode == EditorWorkspaceMode.dialogue,
                  onPressed: onDialogue,
                  child: const Text('Dialogue'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

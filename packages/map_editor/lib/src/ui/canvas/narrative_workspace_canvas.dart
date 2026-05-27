import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/state/narrative_workspace_providers.dart';
import '../../features/narrative/state/narrative_workspace_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import 'cutscene_studio_workspace.dart';
import 'dialogue_studio_workspace.dart';
import 'global_story_studio_workspace.dart';
import 'narrative_overview_workspace.dart';
import 'step_studio_workspace.dart';

/// Workspace central du studio narratif.
///
/// Ce widget est la "surface de création" principale pour:
/// - Global Story
/// - Step
/// - Cutscene
///
/// Intention produit:
/// - éviter un modèle "inspecteur de champs à droite"
/// - rendre la narration éditable dans l'îlot central, comme un vrai workspace
class NarrativeWorkspaceCanvas extends ConsumerWidget {
  const NarrativeWorkspaceCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final editorNotifier = ref.read(editorNotifierProvider.notifier);
    final narrative = ref.watch(narrativeWorkspaceControllerProvider);
    final narrativeController =
        ref.read(narrativeWorkspaceControllerProvider.notifier);
    final projection = ref.watch(narrativeWorkspaceProjectionProvider);

    if (projection == null) {
      return Center(
        child: Text(
          'Load a project to start structuring Global Story, Steps and Cutscenes.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );
    }

    final selectedGlobal = _resolveScenarioById(
      projection,
      narrative.selectedGlobalStoryId,
      fallback: projection.globalStories.isNotEmpty
          ? projection.globalStories.first
          : null,
    );
    final selectedCutscene = _resolveScenarioById(
      projection,
      narrative.selectedCutsceneId,
      fallback: projection.localEventFlows.isNotEmpty
          ? projection.localEventFlows.first
          : null,
    );
    final selectedStep = _resolveStepById(
      projection,
      narrative.selectedStepId,
      fallback: projection.steps.isNotEmpty ? projection.steps.first : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NarrativeModeStrip(
          workspaceMode: editor.workspaceMode,
          onSelectOverview: editorNotifier.selectNarrativeOverviewWorkspace,
          onSelectGlobal: () {
            editorNotifier.selectGlobalStoryWorkspace();
            narrativeController.openGlobalStory(
              scenarioId: selectedGlobal?.id,
            );
          },
          onSelectStep: () {
            editorNotifier.selectStepWorkspace();
            narrativeController.openStep(
              stepId: selectedStep?.id,
              globalScenarioId: selectedStep?.globalScenarioId,
            );
          },
          onSelectCutscene: () {
            editorNotifier.selectCutsceneWorkspace();
            narrativeController.openCutscene(
              cutsceneScenarioId: selectedCutscene?.id,
            );
          },
          onSelectDialogue: editorNotifier.selectDialogueWorkspace,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: switch (editor.workspaceMode) {
            EditorWorkspaceMode.narrativeOverview => NarrativeOverviewWorkspace(
                readModel: buildNarrativeOverviewReadModel(
                  project: editor.project!,
                ),
              ),
            EditorWorkspaceMode.globalStory => GlobalStoryStudioWorkspace(
                editorNotifier: editorNotifier,
                project: editor.project,
                projection: projection,
                selectedGlobalStoryId: narrative.selectedGlobalStoryId,
                selectedStepId: narrative.selectedStepId,
                onSelectGlobalStory: (scenarioId) {
                  if (scenarioId == null || scenarioId.trim().isEmpty) {
                    return;
                  }
                  narrativeController.selectGlobalStory(scenarioId);
                  narrativeController.openGlobalStory(scenarioId: scenarioId);
                },
                onSelectStep: (stepId) {
                  if (stepId == null || stepId.trim().isEmpty) {
                    return;
                  }
                  final step = projection.steps
                      .where((item) => item.id == stepId)
                      .cast<NarrativeStepSummary?>()
                      .firstWhere((item) => item != null, orElse: () => null);
                  narrativeController.selectStep(stepId);
                  if (step != null) {
                    narrativeController
                        .selectGlobalStory(step.globalScenarioId);
                  }
                },
                onOpenStepStudio: (stepId) {
                  final step = projection.steps
                      .where((item) => item.id == stepId)
                      .cast<NarrativeStepSummary?>()
                      .firstWhere((item) => item != null, orElse: () => null);
                  narrativeController.selectStep(stepId);
                  narrativeController.openStep(
                    stepId: stepId,
                    globalScenarioId: step?.globalScenarioId,
                  );
                  editorNotifier.selectStepWorkspace();
                },
              ),
            EditorWorkspaceMode.step => _StepWorkspaceBody(
                projection: projection,
                selectedStep: selectedStep,
                onSelectStep: (stepId) {
                  final step = projection.steps
                      .where((s) => s.id == stepId)
                      .cast<NarrativeStepSummary?>()
                      .firstWhere((s) => s != null, orElse: () => null);
                  narrativeController.selectStep(stepId);
                  narrativeController.openStep(
                    stepId: stepId,
                    globalScenarioId: step?.globalScenarioId,
                  );
                },
                onSelectOutcome: narrativeController.selectOutcome,
                onOpenCutsceneStudio: (cutsceneScenarioId) {
                  // Même séquence que la bibliothèque narrative : sélection +
                  // état de vue, puis bascule du workspace éditeur.
                  narrativeController.selectCutscene(cutsceneScenarioId);
                  narrativeController.openCutscene(
                    cutsceneScenarioId: cutsceneScenarioId,
                  );
                  editorNotifier.selectCutsceneWorkspace();
                },
                editorNotifier: editorNotifier,
                project: editor.project,
                activeMap: editor.activeMap,
              ),
            EditorWorkspaceMode.cutscene => _CutsceneWorkspaceBody(
                editorNotifier: editorNotifier,
                project: editor.project,
                activeMap: editor.activeMap,
                projection: projection,
                selectedCutscene: selectedCutscene,
                onSelectCutscene: (scenarioId) {
                  narrativeController.selectCutscene(scenarioId);
                  narrativeController.openCutscene(
                    cutsceneScenarioId: scenarioId,
                  );
                },
                onSelectOutcome: narrativeController.selectOutcome,
              ),
            EditorWorkspaceMode.dialogue => const DialogueStudioWorkspace(),
            // Workspaces non narratifs: ce widget ne doit pas être utilisé.
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

NarrativeScenarioSummary? _resolveScenarioById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeScenarioSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  return projection.scenarioById[id] ?? fallback;
}

NarrativeStepSummary? _resolveStepById(
  NarrativeWorkspaceProjection projection,
  String? id, {
  NarrativeStepSummary? fallback,
}) {
  if (id == null || id.trim().isEmpty) {
    return fallback;
  }
  for (final step in projection.steps) {
    if (step.id == id) {
      return step;
    }
  }
  return fallback;
}

class _NarrativeModeStrip extends StatelessWidget {
  const _NarrativeModeStrip({
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
    return Row(
      children: [
        _ModeChip(
          label: 'Aperçu',
          selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
          onTap: onSelectOverview,
        ),
        const SizedBox(width: 6),
        _ModeChip(
          label: 'Global Story',
          selected: workspaceMode == EditorWorkspaceMode.globalStory,
          onTap: onSelectGlobal,
        ),
        const SizedBox(width: 6),
        _ModeChip(
          label: 'Step',
          selected: workspaceMode == EditorWorkspaceMode.step,
          onTap: onSelectStep,
        ),
        const SizedBox(width: 6),
        _ModeChip(
          label: 'Cutscene',
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

class _StepWorkspaceBody extends StatelessWidget {
  const _StepWorkspaceBody({
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedStep,
    required this.onSelectStep,
    required this.onSelectOutcome,
    required this.onOpenCutsceneStudio,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeStepSummary? selectedStep;
  final ValueChanged<String> onSelectStep;
  final ValueChanged<String?> onSelectOutcome;

  /// Depuis Step Studio : ouvrir la mise en scène sans l’éditer dans la step.
  final ValueChanged<String> onOpenCutsceneStudio;

  @override
  Widget build(BuildContext context) {
    return StepStudioWorkspace(
      editorNotifier: editorNotifier,
      project: project,
      activeMap: activeMap,
      projection: projection,
      selectedStepId: selectedStep?.id,
      onSelectStep: (stepId) {
        if (stepId == null) {
          return;
        }
        onSelectStep(stepId);
      },
      onSelectOutcome: onSelectOutcome,
      onOpenCutsceneStudio: onOpenCutsceneStudio,
    );
  }
}

class _CutsceneWorkspaceBody extends StatelessWidget {
  const _CutsceneWorkspaceBody({
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedCutscene,
    required this.onSelectCutscene,
    required this.onSelectOutcome,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedCutscene;
  final ValueChanged<String> onSelectCutscene;
  final ValueChanged<String?> onSelectOutcome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: _NarrativeListCard(
            title: 'Local Event Flows / Cutscenes',
            subtitle: 'Scene execution layer',
            emptyText: 'No local flow available.',
            children: projection.localEventFlows
                .map(
                  (scenario) => EditorSidebarListRow(
                    selected: selectedCutscene?.id == scenario.id,
                    onTap: () => onSelectCutscene(scenario.id),
                    leading: const Icon(CupertinoIcons.play_rectangle),
                    title: Text(scenario.name),
                    subtitle: Text(
                      '${scenario.nodeCount} nodes • entry: ${scenario.entryNodeId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Semantics(
                      label: 'Supprimer cette cutscene',
                      button: true,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(32),
                        onPressed: () async {
                          await deleteCutsceneWithUserConfirmation(
                            context: context,
                            editorNotifier: editorNotifier,
                            projection: projection,
                            scenarioId: scenario.id,
                            selectedScenarioId: selectedCutscene?.id,
                            onSelectReplacement: onSelectCutscene,
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.trash,
                          size: 17,
                          color: EditorChrome.inspectorJoyCoral,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: project == null
              ? const EditorPaneSurface(
                  radius: 20,
                  tint: EditorChrome.islandWarmTint,
                  child: Center(
                    child: Text('Load a project to edit cutscenes.'),
                  ),
                )
              : CutsceneStudioWorkspace(
                  editorNotifier: editorNotifier,
                  project: project!,
                  activeMap: activeMap,
                  projection: projection,
                  selectedCutscene: selectedCutscene,
                  onSelectCutscene: onSelectCutscene,
                  onSelectOutcome: onSelectOutcome,
                  onOpenDialogueStudio: (dialogueId) {
                    editorNotifier.selectProjectDialogue(dialogueId);
                    editorNotifier.selectDialogueWorkspace();
                  },
                ),
        ),
      ],
    );
  }
}

class _NarrativeListCard extends StatelessWidget {
  const _NarrativeListCard({
    required this.title,
    required this.subtitle,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandNeutralTint,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: children.isEmpty
                ? Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) => children[index],
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemCount: children.length,
                  ),
          ),
        ],
      ),
    );
  }
}

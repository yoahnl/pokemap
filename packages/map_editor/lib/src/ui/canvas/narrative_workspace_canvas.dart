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
import 'narrative_overview_workspace.dart';
import 'narrative_studio_shell.dart';
import 'scenes/scene_node_read_only_inspector.dart';
import 'scenes_workspace.dart';
import 'step_studio_workspace.dart';
import 'storylines_workspace.dart';

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

    void openOverview() {
      editorNotifier.selectNarrativeOverviewWorkspace();
    }

    void openGlobalStory() {
      editorNotifier.selectGlobalStoryWorkspace();
      narrativeController.openGlobalStory(
        scenarioId: selectedGlobal?.id,
      );
    }

    void openStep() {
      editorNotifier.selectStepWorkspace();
      narrativeController.openStep(
        stepId: selectedStep?.id,
        globalScenarioId: selectedStep?.globalScenarioId,
      );
    }

    void openScenes() {
      editorNotifier.selectScenesWorkspace();
      narrativeController.openScenes();
    }

    void openCutscene() {
      editorNotifier.selectCutsceneWorkspace();
      narrativeController.openCutscene(
        cutsceneScenarioId: selectedCutscene?.id,
      );
    }

    void openDialogue() {
      editorNotifier.selectDialogueWorkspace();
    }

    final mainContent = switch (editor.workspaceMode) {
      EditorWorkspaceMode.narrativeOverview => NarrativeOverviewWorkspace(
          readModel: buildNarrativeOverviewReadModel(
            project: editor.project!,
          ),
          onOpenStorylines: openGlobalStory,
          onOpenScenes: openScenes,
          onOpenCutscenes: openCutscene,
          onOpenDialogues: openDialogue,
        ),
      EditorWorkspaceMode.globalStory => StorylinesWorkspace(
          projection: projection,
          selectedGlobalStoryId: narrative.selectedGlobalStoryId,
        ),
      EditorWorkspaceMode.scenes => ScenesWorkspace(
          scenes: projection.scenes,
          conditionSourceOptions: editor.project == null
              ? const []
              : _buildSceneConditionSourceOptions(
                  editor.project!,
                  activeMap: editor.activeMap,
                ),
          onCreateSceneDraft: ({
            required String name,
            String? description,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final result = createSceneDraftInProject(
              project,
              name: name,
              description: description,
            );
            editorNotifier.applyInMemoryProjectManifest(
              result.updatedProject,
              statusMessage: 'Scene draft created',
            );
            return result.createdScene.id;
          },
          onAddNodeDraft: ({
            required String sceneId,
            required SceneNodeKind kind,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            final result = addSceneNodeDraft(
              project.scenes[sceneIndex],
              kind: kind,
            );
            final scenes = project.scenes.toList(growable: true);
            scenes[sceneIndex] = result.updatedScene;
            editorNotifier.applyInMemoryProjectManifest(
              project.copyWith(scenes: scenes),
              statusMessage: 'Scene node draft added',
            );
            return result.createdNode.id;
          },
          onAddEdgeDraft: ({
            required String sceneId,
            required String fromNodeId,
            required String fromPortId,
            required String toNodeId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return null;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return null;
            }
            try {
              final result = addSceneEdgeDraft(
                project.scenes[sceneIndex],
                fromNodeId: fromNodeId,
                fromPortId: fromPortId,
                toNodeId: toNodeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene edge draft added',
              );
              return result.createdEdge.id;
            } on ArgumentError {
              return null;
            }
          },
          onRemoveEdgeDraft: ({
            required String sceneId,
            required String edgeId,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = removeSceneEdgeDraft(
                project.scenes[sceneIndex],
                edgeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene edge draft removed',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateNodeLayout: ({
            required String sceneId,
            required String nodeId,
            required double x,
            required double y,
          }) async {
            final project = editor.project;
            if (project == null) {
              return;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return;
            }
            try {
              final result = updateSceneNodeLayout(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                x: x,
                y: y,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene node layout updated',
              );
            } on ArgumentError {
              return;
            }
          },
          onUpdateConditionSource: ({
            required String sceneId,
            required String nodeId,
            required SceneConditionSource source,
          }) async {
            final project = editor.project;
            if (project == null) {
              return false;
            }
            final sceneIndex =
                project.scenes.indexWhere((scene) => scene.id == sceneId);
            if (sceneIndex < 0) {
              return false;
            }
            try {
              final result = updateSceneConditionSource(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                source: source,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene condition source updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
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
    };

    return NarrativeStudioShell(
      workspaceMode: editor.workspaceMode,
      onSelectOverview: openOverview,
      onSelectGlobal: openGlobalStory,
      onSelectScenes: openScenes,
      onSelectStep: openStep,
      onSelectCutscene: openCutscene,
      onSelectDialogue: openDialogue,
      child: mainContent,
    );
  }
}

List<SceneConditionSourcePickerOption> _buildSceneConditionSourceOptions(
  ProjectManifest project, {
  MapData? activeMap,
}) {
  final optionsByKey = <String, SceneConditionSourcePickerOption>{};

  void add(SceneConditionSourcePickerOption option) {
    final sourceId = option.sourceId.trim();
    if (sourceId.isEmpty) {
      return;
    }
    optionsByKey.putIfAbsent(
      '${option.sourceKind.name}:$sourceId',
      () => option,
    );
  }

  for (final reference in buildNarrativePredicateReferencePickerOptions(
    project,
  )) {
    if (reference.referenceKind != NarrativePredicateReferenceKind.storyFlag) {
      continue;
    }
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
        sourceId: reference.referenceId,
        label: reference.humanLabel,
        debugTechnicalLabel: reference.debugTechnicalLabel,
      ),
    );
  }

  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        add(
          SceneConditionSourcePickerOption(
            sourceKind: SceneConditionSourceKind.storyStepCompletion,
            sourceId: step.id,
            label: step.title,
            debugTechnicalLabel: '${storyline.id}:${chapter.id}:${step.id}',
          ),
        );
      }
    }
  }
  for (final step in buildNarrativeStoryStepPickerOptions(project)) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.storyStepCompletion,
        sourceId: step.stepId,
        label: step.humanLabel,
        debugTechnicalLabel: step.debugTechnicalLabel,
      ),
    );
  }

  final maps = activeMap == null ? const <MapData>[] : [activeMap];
  for (final eventSource in buildNarrativeEventSourcePickerOptions(
    project,
    maps: maps,
  )) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.consumedEvent,
        sourceId: eventSource.sourceId,
        label: eventSource.humanLabel,
        debugTechnicalLabel: eventSource.debugTechnicalLabel,
      ),
    );
  }

  final options = optionsByKey.values.toList(growable: false);
  options.sort((a, b) {
    final byKind = a.sourceKind.index.compareTo(b.sourceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    if (byLabel != 0) {
      return byLabel;
    }
    return a.sourceId.toLowerCase().compareTo(b.sourceId.toLowerCase());
  });
  return List<SceneConditionSourcePickerOption>.unmodifiable(options);
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

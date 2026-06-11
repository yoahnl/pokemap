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
import '../design_system/design_system.dart';
import 'cinematics/cinematics_library_workspace.dart';
import 'cutscene_studio_workspace.dart';
import 'dialogue_studio_workspace.dart';
import 'facts_world_rules/facts_world_rules_workspace.dart';
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
          style: DefaultTextStyle.of(context).style.copyWith(
                color: EditorChrome.subtleLabel(context),
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

    void openFacts() {
      editorNotifier.selectFactsWorkspace();
    }

    void openWorldRules() {
      editorNotifier.selectWorldRulesWorkspace();
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
          onOpenFacts: openFacts,
          onOpenWorldRules: openWorldRules,
        ),
      EditorWorkspaceMode.globalStory => StorylinesWorkspace(
          projection: projection,
          selectedGlobalStoryId: narrative.selectedGlobalStoryId,
        ),
      EditorWorkspaceMode.scenes => ScenesWorkspace(
          scenes: projection.scenes,
          linkedAssetContracts: editor.project == null
              ? null
              : buildLinkedAssetContractsSnapshot(editor.project!),
          cinematicsLibrary: editor.project == null
              ? null
              : buildCinematicsLibraryReadModel(editor.project!),
          conditionSourceOptions: editor.project == null
              ? const []
              : _buildSceneConditionSourceOptions(
                  editor.project!,
                  activeMap: editor.activeMap,
                ),
          consequenceFactOptions: editor.project == null
              ? const []
              : _buildSceneConsequenceFactOptions(editor.project!),
          consequenceEventOptions: editor.project == null
              ? const []
              : _buildSceneConsequenceEventOptions(
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
          onAddLinkedAssetNodeDraft: ({
            required String sceneId,
            required SceneNodePayload payload,
            String? title,
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
              final result = payload is SceneCinematicPayload
                  ? addSceneCinematicNodeDraft(
                      project.scenes[sceneIndex],
                      project: project,
                      cinematicId: payload.cinematicId,
                      title: title,
                    )
                  : addSceneLinkedAssetNodeDraft(
                      project.scenes[sceneIndex],
                      payload: payload,
                      title: title,
                    );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene linked asset node draft added',
              );
              return result.createdNode.id;
            } on ArgumentError {
              return null;
            }
          },
          onAddConsequenceActionNodeDraft: ({
            required String sceneId,
            required SceneConsequence consequence,
            String? title,
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
              final result = addSceneConsequenceActionNodeDraft(
                project.scenes[sceneIndex],
                consequence: consequence,
                title: title,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene consequence action node added',
              );
              return result.createdNode.id;
            } on ArgumentError {
              return null;
            }
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
          onRemoveNodeDraft: ({
            required String sceneId,
            required String nodeId,
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
              final result = removeSceneNodeDraft(
                project.scenes[sceneIndex],
                nodeId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene node draft removed',
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
          onUpdateYarnDialoguePayload: ({
            required String sceneId,
            required String nodeId,
            required String dialogueId,
            String? yarnNodeName,
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
              final result = updateSceneYarnDialoguePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                dialogueId: dialogueId,
                yarnNodeName: yarnNodeName,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene dialogue payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateBattlePayload: ({
            required String sceneId,
            required String nodeId,
            required String trainerId,
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
              final result = updateSceneBattlePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                trainerId: trainerId,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene battle payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateCinematicPayload: ({
            required String sceneId,
            required String nodeId,
            required String cinematicId,
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
              final result = updateSceneCinematicPayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                cinematicId: cinematicId,
                project: project,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene cinematic payload updated',
              );
              return true;
            } on ArgumentError {
              return false;
            }
          },
          onUpdateActionConsequence: ({
            required String sceneId,
            required String nodeId,
            required SceneConsequence consequence,
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
              final result = updateSceneActionConsequencePayload(
                project.scenes[sceneIndex],
                nodeId: nodeId,
                consequence: consequence,
              );
              final scenes = project.scenes.toList(growable: true);
              scenes[sceneIndex] = result.updatedScene;
              editorNotifier.applyInMemoryProjectManifest(
                project.copyWith(scenes: scenes),
                statusMessage: 'Scene consequence payload updated',
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
      EditorWorkspaceMode.cutscene => _CinematicsWorkspaceBody(
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
      EditorWorkspaceMode.facts => _buildFactsWorldRulesWorkspace(
          editor: editor,
          editorNotifier: editorNotifier,
          readLatestProject: () => ref.read(editorNotifierProvider).project,
          initialMode: FactsWorldRulesWorkspaceMode.facts,
        ),
      EditorWorkspaceMode.worldRules => _buildFactsWorldRulesWorkspace(
          editor: editor,
          editorNotifier: editorNotifier,
          readLatestProject: () => ref.read(editorNotifierProvider).project,
          initialMode: FactsWorldRulesWorkspaceMode.worldRules,
        ),
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
      onSelectFacts: openFacts,
      onSelectWorldRules: openWorldRules,
      child: mainContent,
    );
  }
}

Widget _buildFactsWorldRulesWorkspace({
  required EditorState editor,
  required EditorNotifier editorNotifier,
  required ProjectManifest? Function() readLatestProject,
  required FactsWorldRulesWorkspaceMode initialMode,
}) {
  final project = editor.project;
  if (project == null) {
    return const SizedBox.shrink();
  }
  final maps =
      editor.activeMap == null ? const <MapData>[] : [editor.activeMap!];
  return FactsWorldRulesWorkspace(
    project: project,
    activeMap: editor.activeMap,
    initialMode: initialMode,
    onCreateFact: ({required String label}) async {
      try {
        final result = addNarrativeFact(project, label: label);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact created',
        );
        return result.createdFact.id;
      } on ArgumentError {
        return null;
      }
    },
    onUpdateFact: ({
      required String factId,
      required String label,
      required String description,
      required String category,
      required bool defaultValue,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = updateNarrativeFact(
          latest,
          factId: factId,
          label: label,
          description: description,
          category: category,
          defaultValue: defaultValue,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact updated',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onRemoveFact: ({required String factId}) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = removeNarrativeFact(latest, factId: factId);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'Fact removed',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onCreateWorldRule: ({
      required String label,
      required String description,
      required bool enabled,
      required WorldRuleSource source,
      required WorldRuleTarget target,
      required WorldRuleEffect effect,
      required int priority,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return null;
        }
        final result = addWorldRule(
          latest,
          label: label,
          description: description,
          enabled: enabled,
          source: source,
          target: target,
          effect: effect,
          priority: priority,
          maps: maps,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule created',
        );
        return result.createdRule.id;
      } on ArgumentError {
        return null;
      }
    },
    onUpdateWorldRule: ({
      required String ruleId,
      required String label,
      required String description,
      required bool enabled,
      required WorldRuleSource source,
      required WorldRuleTarget target,
      required WorldRuleEffect effect,
      required int priority,
    }) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = updateWorldRule(
          latest,
          ruleId: ruleId,
          label: label,
          description: description,
          enabled: enabled,
          source: source,
          target: target,
          effect: effect,
          priority: priority,
          maps: maps,
        );
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule updated',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
    onRemoveWorldRule: ({required String ruleId}) async {
      try {
        final latest = readLatestProject();
        if (latest == null) {
          return false;
        }
        final result = removeWorldRule(latest, ruleId: ruleId);
        editorNotifier.applyInMemoryProjectManifest(
          result.updatedProject,
          statusMessage: 'World rule removed',
        );
        return true;
      } on ArgumentError {
        return false;
      }
    },
  );
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

  for (final fact in project.facts) {
    add(
      SceneConditionSourcePickerOption(
        sourceKind: SceneConditionSourceKind.fact,
        sourceId: fact.id,
        label: fact.label,
        debugTechnicalLabel: fact.legacyFlagName ?? fact.id,
        description: fact.description,
        category: fact.category,
      ),
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

List<SceneConsequenceFactPickerOption> _buildSceneConsequenceFactOptions(
  ProjectManifest project,
) {
  final options = [
    for (final fact in project.facts)
      if (fact.id.trim().isNotEmpty)
        SceneConsequenceFactPickerOption(
          factId: fact.id,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          debugTechnicalLabel: fact.legacyFlagName ?? fact.id,
        ),
  ];
  options.sort((a, b) {
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    if (byLabel != 0) {
      return byLabel;
    }
    return a.factId.toLowerCase().compareTo(b.factId.toLowerCase());
  });
  return List<SceneConsequenceFactPickerOption>.unmodifiable(options);
}

List<SceneConsequenceEventPickerOption> _buildSceneConsequenceEventOptions(
  ProjectManifest project, {
  MapData? activeMap,
}) {
  if (activeMap == null) {
    return const [];
  }
  final mapEntry = project.maps
      .where((entry) => entry.id == activeMap.id)
      .cast<ProjectMapEntry?>()
      .firstWhere((entry) => entry != null, orElse: () => null);
  final mapLabel = mapEntry?.name ?? activeMap.name;
  final options = [
    for (final event in activeMap.events)
      if (event.id.trim().isNotEmpty)
        SceneConsequenceEventPickerOption(
          mapId: activeMap.id,
          mapLabel: mapLabel,
          eventId: event.id,
          eventLabel: event.title.trim().isEmpty ? event.id : event.title,
          debugTechnicalLabel: '${activeMap.id}:${event.id}',
        ),
  ];
  options.sort((a, b) {
    final byMap = a.mapLabel.toLowerCase().compareTo(b.mapLabel.toLowerCase());
    if (byMap != 0) {
      return byMap;
    }
    final byEvent =
        a.eventLabel.toLowerCase().compareTo(b.eventLabel.toLowerCase());
    if (byEvent != 0) {
      return byEvent;
    }
    return a.eventId.toLowerCase().compareTo(b.eventId.toLowerCase());
  });
  return List<SceneConsequenceEventPickerOption>.unmodifiable(options);
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

class _CinematicsWorkspaceBody extends StatefulWidget {
  const _CinematicsWorkspaceBody({
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
  State<_CinematicsWorkspaceBody> createState() =>
      _CinematicsWorkspaceBodyState();
}

class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
  bool _showLegacyCutsceneStudio = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project == null) {
      return Center(
        child: Text(
          'Load a project to browse CinematicAsset.',
          textAlign: TextAlign.center,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: EditorChrome.subtleLabel(context),
              ),
        ),
      );
    }

    if (_showLegacyCutsceneStudio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('cinematics-library-back-button'),
              onPressed: () {
                setState(() => _showLegacyCutsceneStudio = false);
              },
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.chevron_left),
              child: const Text('Retour à la Library cinématiques'),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _CutsceneWorkspaceBody(
              editorNotifier: widget.editorNotifier,
              project: project,
              activeMap: widget.activeMap,
              projection: widget.projection,
              selectedCutscene: widget.selectedCutscene,
              onSelectCutscene: widget.onSelectCutscene,
              onSelectOutcome: widget.onSelectOutcome,
            ),
          ),
        ],
      );
    }

    return CinematicsLibraryWorkspace(
      project: project,
      onCreateCinematicShell: _createCinematicShell,
      onUpdateCinematicMetadata: _updateCinematicMetadata,
      onRemoveCinematic: _removeCinematic,
      onAddTimelineDraft: _addCinematicTimelineDraft,
      onRemoveTimelineDraft: _removeCinematicTimelineDraft,
      onAddTimelineBasicBlock: _addCinematicTimelineBasicBlock,
      onUpdateTimelineBasicBlock: _updateCinematicTimelineBasicBlock,
      onAddRequiredActor: _addCinematicRequiredActor,
      onRenameRequiredActor: _renameCinematicRequiredActor,
      onRemoveRequiredActor: _removeCinematicRequiredActor,
      onAddMovementTarget: _addCinematicMovementTarget,
      onUpdateMovementTarget: _updateCinematicMovementTarget,
      onRemoveMovementTarget: _removeCinematicMovementTarget,
      onAddTimelineActorFacing: _addCinematicTimelineActorFacing,
      onUpdateTimelineActorFacing: _updateCinematicTimelineActorFacing,
      onAddTimelineActorMove: _addCinematicTimelineActorMove,
      onUpdateTimelineActorMove: _updateCinematicTimelineActorMove,
      onRemoveTimelineAuthoringStep: _removeCinematicTimelineAuthoringStep,
      onUpdateStageMap: _updateCinematicStageMap,
      onUpdateStageContext: _updateCinematicStageContext,
      onUpdateCinematicAsset: _updateCinematicAsset,
      onUpsertActorBinding: _upsertCinematicActorBinding,
      onUpsertActorAppearanceBinding: _upsertCinematicActorAppearanceBinding,
      onRemoveActorAppearanceBinding: _removeCinematicActorAppearanceBinding,
      onUpsertActorInitialPlacement: _upsertCinematicActorInitialPlacement,
      onUpsertMovementTargetBinding: _upsertCinematicMovementTargetBinding,
      onLoadStageMapSnapshot: widget.editorNotifier.loadMapSnapshotById,
      onResolveBackdropTilesetPath:
          widget.editorNotifier.getTilesetAbsolutePathById,
      onOpenLegacyCutsceneStudio: () {
        setState(() => _showLegacyCutsceneStudio = true);
      },
    );
  }

  Future<String?> _createCinematicShell({required String title}) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return null;
    }
    final id = _nextCinematicAssetId(project, cleanTitle);
    try {
      final result = addCinematicAsset(
        project,
        CinematicAsset(
          id: id,
          title: cleanTitle,
          timeline: CinematicTimeline(),
        ),
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'CinematicAsset created',
      );
      return result.cinematic.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicMetadata({
    required String cinematicId,
    required String title,
    required String description,
    required String notes,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    final existing = findCinematicById(project, cinematicId);
    if (existing == null) {
      return false;
    }
    try {
      final result = updateCinematicAsset(
        project,
        CinematicAsset(
          id: existing.id,
          title: title.trim(),
          description: description.trim(),
          storylineId: existing.storylineId,
          chapterId: existing.chapterId,
          mapId: existing.mapId,
          tags: existing.tags,
          requiredActors: existing.requiredActors,
          movementTargets: existing.movementTargets,
          stageContext: existing.stageContext,
          timeline: existing.timeline,
          notes: notes.trim(),
          metadata: existing.metadata,
          legacyBridge: existing.legacyBridge,
        ),
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'CinematicAsset metadata updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematic({required String cinematicId}) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicAsset(project, cinematicId);
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'CinematicAsset removed',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineDraft({
    required String cinematicId,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineDraftStep(
        project,
        cinematicId: cinematicId,
        afterStepId: afterStepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic timeline draft created',
      );
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _removeCinematicTimelineDraft({
    required String cinematicId,
    required String stepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicTimelineDraftStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic timeline draft removed',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineBasicBlock({
    required String cinematicId,
    required CinematicTimelineBasicBlockKind blockKind,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineBasicBlockStep(
        project,
        cinematicId: cinematicId,
        blockKind: blockKind,
        afterStepId: afterStepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic timeline basic block created',
      );
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineBasicBlock({
    required String cinematicId,
    required String stepId,
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineBasicBlockStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        durationMs: durationMs,
        fadeMode: fadeMode,
        cameraMode: cameraMode,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic timeline basic block updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicRequiredActor({
    required String cinematicId,
    String? label,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        label: label ?? 'Acteur',
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic required actor created',
      );
      return result.actor.actorId;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _renameCinematicRequiredActor({
    required String cinematicId,
    required String actorId,
    required String label,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = renameCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        label: label,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic required actor renamed',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicRequiredActor({
    required String cinematicId,
    required String actorId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicRequiredActor(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic required actor removed',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicMovementTarget({
    required String cinematicId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        label: 'Cible',
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic movement target created',
      );
      return result.target.targetId;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicMovementTarget({
    required String cinematicId,
    required String targetId,
    required String label,
    String? description,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        targetId: targetId,
        label: label,
        description: description,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic movement target updated',
      );
      return result.target.targetId == targetId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicMovementTarget({
    required String cinematicId,
    required String targetId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicMovementTarget(
        project,
        cinematicId: cinematicId,
        targetId: targetId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic movement target removed',
      );
      return result.removedTarget.targetId == targetId;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineActorFacing({
    required String cinematicId,
    required String actorId,
    required CinematicTimelineActorFacingDirection direction,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineActorFacingStep(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        direction: direction,
        afterStepId: afterStepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor facing block created',
      );
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineActorFacing({
    required String cinematicId,
    required String stepId,
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
    int? durationMs,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineActorFacingStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        actorId: actorId,
        direction: direction,
        durationMs: durationMs,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor facing block updated',
      );
      return result.step.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<String?> _addCinematicTimelineActorMove({
    required String cinematicId,
    required String actorId,
    required String targetId,
    required int durationMs,
    required CinematicTimelineActorMovementMode movementMode,
    String? afterStepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return null;
    }
    try {
      final result = addCinematicTimelineActorMoveStep(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
        targetId: targetId,
        durationMs: durationMs,
        movementMode: movementMode,
        afterStepId: afterStepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor movement block created',
      );
      return result.step.id;
    } on ArgumentError {
      return null;
    }
  }

  Future<bool> _updateCinematicTimelineActorMove({
    required String cinematicId,
    required String stepId,
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicTimelineActorMoveStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
        actorId: actorId,
        targetId: targetId,
        durationMs: durationMs,
        movementMode: movementMode,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor movement block updated',
      );
      return result.step.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicTimelineAuthoringStep({
    required String cinematicId,
    required String stepId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicTimelineAuthoringStep(
        project,
        cinematicId: cinematicId,
        stepId: stepId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic timeline authoring step removed',
      );
      return result.removedStep.id == stepId;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicStageMap({
    required String cinematicId,
    String? mapId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicStageMap(
        project,
        cinematicId: cinematicId,
        mapId: mapId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic stage map updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicStageContext({
    required String cinematicId,
    required CinematicStageContext stageContext,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicStageContext(
        project,
        cinematicId: cinematicId,
        stageContext: stageContext,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic stage context updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _updateCinematicAsset({
    required String cinematicId,
    required CinematicAsset cinematic,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = updateCinematicAsset(
        project,
        cinematic,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic asset updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorBinding({
    required String cinematicId,
    required CinematicActorBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor binding updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorAppearanceBinding({
    required String cinematicId,
    required CinematicActorAppearanceBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorAppearanceBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor appearance updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _removeCinematicActorAppearanceBinding({
    required String cinematicId,
    required String actorId,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = removeCinematicActorAppearanceBinding(
        project,
        cinematicId: cinematicId,
        actorId: actorId,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor appearance removed',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicActorInitialPlacement({
    required String cinematicId,
    required CinematicActorInitialPlacement placement,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicActorInitialPlacement(
        project,
        cinematicId: cinematicId,
        placement: placement,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic actor placement updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<bool> _upsertCinematicMovementTargetBinding({
    required String cinematicId,
    required CinematicMovementTargetBinding binding,
  }) async {
    final project = widget.project;
    if (project == null) {
      return false;
    }
    try {
      final result = upsertCinematicMovementTargetBinding(
        project,
        cinematicId: cinematicId,
        binding: binding,
      );
      widget.editorNotifier.applyInMemoryProjectManifest(
        result.updatedProject,
        statusMessage: 'Cinematic target binding updated',
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }
}

String _nextCinematicAssetId(ProjectManifest project, String title) {
  final slug = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = slug.isEmpty ? 'cinematic' : 'cinematic_$slug';
  final existingIds = project.cinematics.map((asset) => asset.id).toSet();
  if (!existingIds.contains(base)) {
    return base;
  }
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
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
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: EditorChrome.primaryLabel(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: DefaultTextStyle.of(context).style.copyWith(
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
                      style: DefaultTextStyle.of(context).style.copyWith(
                            color: EditorChrome.subtleLabel(context),
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

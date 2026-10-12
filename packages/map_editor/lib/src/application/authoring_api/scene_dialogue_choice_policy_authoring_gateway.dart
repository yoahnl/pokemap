import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'authoring_query_adapter.dart';

final class SceneDialogueChoiceOption {
  const SceneDialogueChoiceOption({
    required this.outcomeId,
    required this.label,
  });

  final String outcomeId;
  final String label;
}

final class SceneDialogueChoiceScopeOption {
  const SceneDialogueChoiceScopeOption({
    required this.nodeName,
    required this.choiceIndex,
    required this.labels,
    required this.choices,
    required this.branches,
  });

  final String nodeName;
  final int choiceIndex;
  final List<String> labels;
  final List<SceneDialogueChoiceOption> choices;
  final List<SceneDialogueChoiceOption> branches;

  String get label => '$nodeName · Choix ${choiceIndex + 1}';
}

final class SceneDialogueChoicePolicyEditorData {
  const SceneDialogueChoicePolicyEditorData({
    required this.scopes,
    required this.policies,
  });

  final List<SceneDialogueChoiceScopeOption> scopes;
  final List<SceneDialogueChoicePolicy> policies;
}

final class SceneDialogueChoicePolicyAuthoringGateway {
  const SceneDialogueChoicePolicyAuthoringGateway({required this.queries});

  final AuthoringQueryAdapter queries;

  Future<SceneDialogueChoicePolicyEditorData> load(
    String projectRoot, {
    required ProjectManifest project,
    required String sceneId,
    required String nodeId,
  }) async {
    final session = await queries.open(projectRoot);
    final (scene, node, payload) = _target(project, sceneId, nodeId);
    _requireSameDialogue(session, project, payload.dialogueId);
    final document = session.dialogueDocument(payload.dialogueId);
    validateSceneDialogueChoicePolicies(
      sceneDialogueChoiceScopes(document),
      payload.choicePolicies,
    );
    final blocks = <(String, int), RuntimeDialogueChoiceBlock>{};
    for (final yarnNode in document.nodes) {
      var index = 0;
      void visit(List<RuntimeDialogueStep> steps) {
        for (final step in steps) {
          if (step is! RuntimeDialogueChoiceBlock) continue;
          blocks[(yarnNode.title, index++)] = step;
          for (final choice in step.choices) {
            visit(choice.steps);
          }
        }
      }

      visit(yarnNode.steps);
    }
    final emitted = {
      for (final block in blocks.values)
        for (final choice in block.choices) choice.outcomeId,
    };
    final branches = <SceneDialogueChoiceOption>[];
    for (final outcome in payload.expectedOutcomes) {
      if (emitted.contains(outcome)) continue;
      final edge = scene.graph.edges
          .where(
            (edge) =>
                edge.fromNodeId == node.id &&
                edge.fromPortId == outcome &&
                edge.kind == SceneEdgeKind.dialogueOutcome,
          )
          .firstOrNull;
      if (edge == null) continue;
      final target = scene.graph.nodes
          .where((node) => node.id == edge.toNodeId)
          .firstOrNull;
      branches.add(
        SceneDialogueChoiceOption(
          outcomeId: outcome,
          label: target?.title ?? 'Branche ${branches.length + 1}',
        ),
      );
    }
    final scopes = <SceneDialogueChoiceScopeOption>[];
    for (final scope in sceneDialogueChoiceScopes(document)) {
      final block = blocks[(scope.nodeName, scope.choiceIndex)]!;
      final choices = <SceneDialogueChoiceOption>[];
      for (final choice in block.choices) {
        final outcome = choice.outcomeId;
        if (outcome == null ||
            !payload.expectedOutcomes.contains(outcome) ||
            block.choices.where((item) => item.outcomeId == outcome).length !=
                1) {
          continue;
        }
        choices.add(
          SceneDialogueChoiceOption(outcomeId: outcome, label: choice.text),
        );
      }
      scopes.add(
        SceneDialogueChoiceScopeOption(
          nodeName: scope.nodeName,
          choiceIndex: scope.choiceIndex,
          labels: List.unmodifiable(block.choices.map((choice) => choice.text)),
          choices: List.unmodifiable(choices),
          branches: List.unmodifiable(branches),
        ),
      );
    }
    return SceneDialogueChoicePolicyEditorData(
      scopes: List.unmodifiable(scopes),
      policies: payload.choicePolicies,
    );
  }

  Future<ProjectManifest> updateDraft(
    String projectRoot, {
    required ProjectManifest project,
    required String sceneId,
    required String nodeId,
    required SceneDialogueChoicePolicy policy,
    MapData? activeMap,
  }) async {
    await queries.invalidate(projectRoot);
    final session = await queries.open(projectRoot);
    final (_, _, payload) = _target(project, sceneId, nodeId);
    _requireSameDialogue(session, project, payload.dialogueId);
    final document = session.dialogueDocument(payload.dialogueId);
    final maps = [
      for (final map in session.maps)
        if (activeMap?.id == map.id) activeMap! else map,
      if (activeMap != null &&
          !session.maps.any((map) => map.id == activeMap.id))
        activeMap,
    ];
    return const SceneActions().updateDialogueChoicePolicy(
      project,
      maps: maps,
      sceneId: sceneId,
      nodeId: nodeId,
      choicePolicy: policy,
      dialogue: document,
    );
  }

  (SceneAsset, SceneNode, SceneYarnDialoguePayload) _target(
    ProjectManifest project,
    String sceneId,
    String nodeId,
  ) {
    final scene = project.scenes
        .where((scene) => scene.id == sceneId)
        .firstOrNull;
    final node = scene?.graph.nodes
        .where((node) => node.id == nodeId)
        .firstOrNull;
    if (scene == null ||
        node == null ||
        node.payload is! SceneYarnDialoguePayload) {
      throw StateError('Le nœud de dialogue sélectionné est introuvable.');
    }
    return (scene, node, node.payload as SceneYarnDialoguePayload);
  }

  void _requireSameDialogue(
    EditorAuthoringReadSession session,
    ProjectManifest project,
    String dialogueId,
  ) {
    final expected = project.dialogues
        .where((entry) => entry.id == dialogueId)
        .firstOrNull;
    final actual = session.manifest.dialogues
        .where((entry) => entry.id == dialogueId)
        .firstOrNull;
    if (expected == null || actual != expected) {
      throw StateError(
        'Le dialogue a changé. Enregistrez puis rechargez le projet.',
      );
    }
  }
}

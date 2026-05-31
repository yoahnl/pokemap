import '../diagnostics/event_scene_link_diagnostics.dart';
import '../diagnostics/scene_diagnostics.dart';
import '../diagnostics/world_rule_diagnostics.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/world_rule.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'world_rule_target_context_read_model.dart';

enum GoldenSliceReadinessIssueSeverity {
  error,
  warning,
  info,
}

enum GoldenSliceReadinessIssueCode {
  goldenSliceNoEventSceneTarget,
  goldenSliceSceneMissing,
  goldenSliceSceneHasDiagnostics,
  goldenSliceRuntimePlanNotBuildable,
  goldenSliceDialogueRefMissing,
  goldenSliceBattleRefMissing,
  goldenSliceBattleVictoryNotReachable,
  goldenSliceBattleDefeatNotReachable,
  goldenSliceWorldRuleMissing,
  goldenSliceWorldRuleHasDiagnostics,
  goldenSliceDialogueNodeMissing,
  goldenSliceBattleNodeMissing,
}

final class GoldenSliceReadinessIssue {
  const GoldenSliceReadinessIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.mapId,
    this.eventId,
    this.pageNumber,
    this.sceneId,
    this.nodeId,
  });

  final GoldenSliceReadinessIssueCode code;
  final GoldenSliceReadinessIssueSeverity severity;
  final String message;
  final String? mapId;
  final String? eventId;
  final int? pageNumber;
  final String? sceneId;
  final String? nodeId;
}

final class GoldenSliceReadinessEventTarget {
  const GoldenSliceReadinessEventTarget({
    required this.mapId,
    required this.eventId,
    required this.pageNumber,
    required this.pageIndex,
    required this.sceneId,
    required this.sceneExists,
    required this.runtimePlanBuildable,
    required this.containsDialogue,
    required this.containsBattle,
    required this.battleVictoryReachable,
    required this.battleDefeatReachable,
    required this.worldRuleCount,
  });

  final String mapId;
  final String eventId;
  final int pageNumber;
  final int pageIndex;
  final String sceneId;
  final bool sceneExists;
  final bool runtimePlanBuildable;
  final bool containsDialogue;
  final bool containsBattle;
  final bool battleVictoryReachable;
  final bool battleDefeatReachable;
  final int worldRuleCount;
}

final class GoldenSliceReadinessReport {
  GoldenSliceReadinessReport({
    required List<GoldenSliceReadinessEventTarget> eventTargets,
    required List<GoldenSliceReadinessIssue> issues,
  })  : eventTargets =
            List<GoldenSliceReadinessEventTarget>.unmodifiable(eventTargets),
        issues = List<GoldenSliceReadinessIssue>.unmodifiable(issues);

  final List<GoldenSliceReadinessEventTarget> eventTargets;
  final List<GoldenSliceReadinessIssue> issues;

  int get eventSceneTargetCount => eventTargets.length;

  bool get isReady => issues.every(
        (issue) => issue.severity != GoldenSliceReadinessIssueSeverity.error,
      );

  bool get hasIssues => issues.isNotEmpty;

  List<GoldenSliceReadinessIssue> byCode(
    GoldenSliceReadinessIssueCode code,
  ) {
    return List<GoldenSliceReadinessIssue>.unmodifiable(
      issues.where((issue) => issue.code == code),
    );
  }
}

GoldenSliceReadinessReport buildGoldenSliceReadinessReport(
  ProjectManifest project, {
  required List<MapData> maps,
}) {
  final scenesById = {for (final scene in project.scenes) scene.id: scene};
  final dialogueIds = project.dialogues.map((dialogue) => dialogue.id).toSet();
  final trainerIds = project.trainers.map((trainer) => trainer.id).toSet();
  final eventLinkDiagnostics = diagnoseEventSceneLinks(
    project: project,
    maps: maps,
  );
  final targets = <GoldenSliceReadinessEventTarget>[];
  final issues = <GoldenSliceReadinessIssue>[];

  for (final map in maps) {
    for (final event in map.events) {
      for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
        final page = event.pages[pageIndex];
        final sceneId = page.sceneTarget?.sceneId.trim();
        if (sceneId == null || sceneId.isEmpty) {
          continue;
        }

        final scene = scenesById[sceneId];
        if (scene == null) {
          targets.add(
            GoldenSliceReadinessEventTarget(
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              pageIndex: pageIndex,
              sceneId: sceneId,
              sceneExists: false,
              runtimePlanBuildable: false,
              containsDialogue: false,
              containsBattle: false,
              battleVictoryReachable: false,
              battleDefeatReachable: false,
              worldRuleCount: 0,
            ),
          );
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode.goldenSliceSceneMissing,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message: 'La page d’event cible une Scene V1 absente.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: sceneId,
            ),
          );
          continue;
        }

        final sceneDiagnostics = diagnoseSceneAgainstProject(scene, project);
        final planResult = buildSceneRuntimePlan(scene);
        final dialogueNodeIds = <String>[];
        final battleNodeIds = <String>[];
        for (final node in scene.graph.nodes) {
          switch (node.payload) {
            case SceneYarnDialoguePayload(:final dialogueId):
              dialogueNodeIds.add(node.id);
              if (!dialogueIds.contains(dialogueId)) {
                issues.add(
                  GoldenSliceReadinessIssue(
                    code: GoldenSliceReadinessIssueCode
                        .goldenSliceDialogueRefMissing,
                    severity: GoldenSliceReadinessIssueSeverity.error,
                    message:
                        'La Scene V1 référence un dialogue absent du projet.',
                    mapId: map.id,
                    eventId: event.id,
                    pageNumber: page.pageNumber,
                    sceneId: scene.id,
                    nodeId: node.id,
                  ),
                );
              }
            case SceneBattlePayload(:final battleKind, :final trainerId):
              battleNodeIds.add(node.id);
              if (battleKind == 'trainer' &&
                  (trainerId == null || !trainerIds.contains(trainerId))) {
                issues.add(
                  GoldenSliceReadinessIssue(
                    code: GoldenSliceReadinessIssueCode
                        .goldenSliceBattleRefMissing,
                    severity: GoldenSliceReadinessIssueSeverity.error,
                    message:
                        'La Scene V1 référence un trainer absent du projet.',
                    mapId: map.id,
                    eventId: event.id,
                    pageNumber: page.pageNumber,
                    sceneId: scene.id,
                    nodeId: node.id,
                  ),
                );
              }
            case SceneStartPayload():
            case SceneEndPayload():
            case SceneConditionPayload():
            case SceneActionPayload():
            case SceneCinematicPayload():
            case SceneBranchByOutcomePayload():
            case SceneMergePayload():
              break;
          }
        }

        if (dialogueNodeIds.isEmpty) {
          issues.add(
            GoldenSliceReadinessIssue(
              code:
                  GoldenSliceReadinessIssueCode.goldenSliceDialogueNodeMissing,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message: 'La Scene V1 cible ne contient aucun Dialogue Yarn.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }
        if (battleNodeIds.isEmpty) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode.goldenSliceBattleNodeMissing,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message: 'La Scene V1 cible ne contient aucun BattleNode.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }

        if (sceneDiagnostics.hasErrors) {
          issues.add(
            GoldenSliceReadinessIssue(
              code:
                  GoldenSliceReadinessIssueCode.goldenSliceSceneHasDiagnostics,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message: 'La Scene V1 cible contient des diagnostics bloquants.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }
        if (!planResult.canBuild) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode
                  .goldenSliceRuntimePlanNotBuildable,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message:
                  'La Scene V1 cible ne peut pas produire de SceneRuntimePlan.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }

        final battleNodeId = battleNodeIds.firstOrNull;
        final victoryReachable = battleNodeId != null &&
            _isEndReachableFromPort(scene, battleNodeId, 'victory');
        final defeatReachable = battleNodeId != null &&
            _isEndReachableFromPort(scene, battleNodeId, 'defeat');
        if (!victoryReachable) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode
                  .goldenSliceBattleVictoryNotReachable,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message:
                  'Le port victory du combat n’atteint aucune fin de scène.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
              nodeId: battleNodeId,
            ),
          );
        }
        if (!defeatReachable) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode
                  .goldenSliceBattleDefeatNotReachable,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message:
                  'Le port defeat du combat n’atteint aucune fin de scène.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
              nodeId: battleNodeId,
            ),
          );
        }

        final worldRules = buildWorldRuleTargetContextReadModel(
          project,
          maps: [map],
          targetKind: WorldRuleTargetKind.mapEvent,
          mapId: map.id,
          eventId: event.id,
        );
        if (worldRules.isEmpty) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode.goldenSliceWorldRuleMissing,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message: 'Aucune World Rule ne cible l’event du slice.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }
        if (worldRules.diagnostics.any(
          (diagnostic) =>
              diagnostic.severity == WorldRuleDiagnosticSeverity.error,
        )) {
          issues.add(
            GoldenSliceReadinessIssue(
              code: GoldenSliceReadinessIssueCode
                  .goldenSliceWorldRuleHasDiagnostics,
              severity: GoldenSliceReadinessIssueSeverity.error,
              message:
                  'Une World Rule liée à l’event contient un diagnostic bloquant.',
              mapId: map.id,
              eventId: event.id,
              pageNumber: page.pageNumber,
              sceneId: scene.id,
            ),
          );
        }

        targets.add(
          GoldenSliceReadinessEventTarget(
            mapId: map.id,
            eventId: event.id,
            pageNumber: page.pageNumber,
            pageIndex: pageIndex,
            sceneId: scene.id,
            sceneExists: true,
            runtimePlanBuildable: planResult.canBuild,
            containsDialogue: dialogueNodeIds.isNotEmpty,
            containsBattle: battleNodeIds.isNotEmpty,
            battleVictoryReachable: victoryReachable,
            battleDefeatReachable: defeatReachable,
            worldRuleCount: worldRules.ruleCount,
          ),
        );
      }
    }
  }

  if (targets.isEmpty) {
    issues.add(
      const GoldenSliceReadinessIssue(
        code: GoldenSliceReadinessIssueCode.goldenSliceNoEventSceneTarget,
        severity: GoldenSliceReadinessIssueSeverity.error,
        message: 'Aucun event de map ne cible une Scene V1.',
      ),
    );
  }

  for (final diagnostic in eventLinkDiagnostics.diagnostics) {
    if (diagnostic.severity == EventSceneLinkDiagnosticSeverity.error &&
        diagnostic.code ==
            EventSceneLinkDiagnosticCode
                .eventSceneTargetRuntimePlanNotBuildable) {
      continue;
    }
    if (diagnostic.severity == EventSceneLinkDiagnosticSeverity.error &&
        diagnostic.code ==
            EventSceneLinkDiagnosticCode.eventSceneTargetUnknown) {
      continue;
    }
    if (diagnostic.severity == EventSceneLinkDiagnosticSeverity.error) {
      issues.add(
        GoldenSliceReadinessIssue(
          code: GoldenSliceReadinessIssueCode.goldenSliceSceneHasDiagnostics,
          severity: GoldenSliceReadinessIssueSeverity.error,
          message: diagnostic.message,
          mapId: diagnostic.mapId,
          eventId: diagnostic.eventId,
          pageNumber: diagnostic.pageNumber,
          sceneId: diagnostic.sceneId,
        ),
      );
    }
  }

  return GoldenSliceReadinessReport(
    eventTargets: targets,
    issues: issues,
  );
}

bool _isEndReachableFromPort(
  SceneAsset scene,
  String battleNodeId,
  String portId,
) {
  final nodesById = {for (final node in scene.graph.nodes) node.id: node};
  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => <SceneEdge>[]).add(edge);
  }

  final queue = <String>[
    for (final edge in scene.graph.edges)
      if (edge.fromNodeId == battleNodeId && edge.fromPortId == portId)
        edge.toNodeId,
  ];
  final visited = <String>{};
  while (queue.isNotEmpty) {
    final nodeId = queue.removeAt(0);
    if (!visited.add(nodeId)) {
      continue;
    }
    final node = nodesById[nodeId];
    if (node == null) {
      continue;
    }
    if (node.kind == SceneNodeKind.end) {
      return true;
    }
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      queue.add(edge.toNodeId);
    }
  }
  return false;
}

import 'package:map_core/map_core_domain.dart';

enum SceneGraphProblemLevel { blocking, warning }

final class SceneGraphProblem {
  const SceneGraphProblem({
    required this.code,
    required this.level,
    required this.message,
    this.nodeId,
    this.edgeId,
  });

  final SceneDiagnosticCode code;
  final SceneGraphProblemLevel level;
  final String message;
  final String? nodeId;
  final String? edgeId;
}

final class SceneGraphChecks {
  SceneGraphChecks(List<SceneGraphProblem> problems)
    : problems = List.unmodifiable(problems);

  final List<SceneGraphProblem> problems;

  bool get blocking => problems.any(
    (problem) => problem.level == SceneGraphProblemLevel.blocking,
  );

  Iterable<SceneGraphProblem> ofNode(String nodeId) =>
      problems.where((problem) => problem.nodeId == nodeId);

  SceneGraphProblemLevel? levelOfNode(String nodeId) => _worst(ofNode(nodeId));

  SceneGraphProblemLevel? levelOfEdge(String edgeId) =>
      _worst(problems.where((problem) => problem.edgeId == edgeId));

  static SceneGraphProblemLevel? _worst(Iterable<SceneGraphProblem> found) =>
      found.isEmpty
      ? null
      : found.any((p) => p.level == SceneGraphProblemLevel.blocking)
      ? SceneGraphProblemLevel.blocking
      : SceneGraphProblemLevel.warning;
}

const _layoutCodes = {
  SceneDiagnosticCode.layoutUnknownNode,
  SceneDiagnosticCode.layoutMissingNode,
};

SceneGraphChecks checkSceneGraph(SceneAsset scene) => SceneGraphChecks([
  for (final diagnostic in diagnoseScene(scene).diagnostics)
    if (!_layoutCodes.contains(diagnostic.code))
      if (switch (diagnostic.severity) {
            SceneDiagnosticSeverity.error => SceneGraphProblemLevel.blocking,
            SceneDiagnosticSeverity.warning => SceneGraphProblemLevel.warning,
            SceneDiagnosticSeverity.info => null,
          }
          case final level?)
        SceneGraphProblem(
          code: diagnostic.code,
          level: level,
          message: diagnostic.message,
          nodeId: diagnostic.nodeId,
          edgeId: diagnostic.edgeId,
        ),
]);

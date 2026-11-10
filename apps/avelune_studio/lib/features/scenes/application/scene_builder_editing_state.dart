import 'package:map_core/map_core_domain.dart';

class SceneBuilderEditingState {
  String? nodeId, edgeId;
  final choices = <String, String>{};
  SceneAsset? previewDocument;
  SceneDryRunPreviewResult? preview;
  String? previewError;
  void invalidate(SceneAsset scene) {
    if (nodeId != null && !scene.graph.nodes.any((node) => node.id == nodeId)) {
      nodeId = null;
    }
    if (edgeId != null && !scene.graph.edges.any((edge) => edge.id == edgeId)) {
      edgeId = null;
    }
    choices.removeWhere(
      (id, _) => !scene.graph.nodes.any((node) => node.id == id),
    );
    if (previewDocument != null && previewDocument != scene) {
      preview = null;
      previewDocument = null;
      previewError = 'La scène a changé. Recalculez le chemin.';
    }
  }

  void calculate(SceneAsset scene) {
    previewDocument = scene;
    final plan = buildSceneRuntimePlan(scene);
    if (plan.plan == null) {
      preview = null;
      previewError = plan.diagnostics.map((d) => d.message).join('\n');
      return;
    }
    previewError = null;
    preview = previewSceneRuntimePath(
      plan.plan!,
      input: SceneDryRunInputState(outputPortByNodeId: choices),
    );
  }
}

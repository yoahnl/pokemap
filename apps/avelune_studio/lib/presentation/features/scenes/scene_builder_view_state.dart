import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';

class SceneBuilderViewStore {
  final _views = <String, SceneBuilderViewState>{};
  bool sceneLibrary = false;
  String search = '';
  SceneBuilderViewState forScene(String id) =>
      _views.putIfAbsent(id, SceneBuilderViewState.new);
  void dispose() {
    for (final view in _views.values) {
      view.viewport.dispose();
    }
  }
}

class SceneBuilderViewState {
  final viewport = SceneGraphViewport();
  String? nodeId, edgeId;
  bool libraryOpen = false, inspectorOpen = false, previewOpen = false;
  final choices = <String, String>{};
  SceneAsset? previewDocument;
  SceneDryRunPreviewResult? preview;
  String? previewError;
  void invalidate(SceneAsset scene) {
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

import 'package:avelune_studio/features/scenes/coordination/scene_builder_session.dart';

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

class SceneBuilderViewState extends SceneBuilderSession {
  bool libraryOpen = false,
      inspectorOpen = false,
      previewOpen = false,
      summaryOpen = false;
}

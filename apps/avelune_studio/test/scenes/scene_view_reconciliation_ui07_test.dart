import 'package:avelune_studio/presentation/features/scenes/scene_builder_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'catalog refresh clears only vanished scene targets and retains viewport',
    () {
      final original = createSceneDraftInProject(
        const ProjectManifest(name: 'Scène', maps: [], tilesets: []),
        name: 'Rencontre',
      ).createdScene;
      final view = SceneBuilderViewState();
      addTearDown(view.viewport.dispose);
      view.nodeId = original.graph.nodes.last.id;
      view.edgeId = original.graph.edges.first.id;
      view.choices[view.nodeId!] = 'continue';
      view.viewport.pan = const Offset(120, -40);
      view.viewport.zoom = .6;
      final reduced = SceneAsset.fromJson({
        ...original.toJson(),
        'layout': SceneGraphLayout().toJson(),
        'graph': {
          ...original.graph.toJson(),
          'nodes': [original.graph.nodes.first.toJson()],
          'edges': <Object?>[],
        },
      });
      view.invalidate(reduced);
      expect(view.nodeId, isNull);
      expect(view.edgeId, isNull);
      expect(view.choices, isEmpty);
      expect(view.viewport.pan, const Offset(120, -40));
      expect(view.viewport.zoom, .6);
      view.nodeId = original.graph.nodes.first.id;
      view.invalidate(original);
      expect(view.nodeId, original.graph.nodes.first.id);
    },
  );
}

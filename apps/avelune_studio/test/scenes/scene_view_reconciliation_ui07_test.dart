import 'package:avelune_studio/features/scenes/application/scene_builder_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('catalog refresh clears only vanished scene targets and choices', () {
    final original = createSceneDraftInProject(
      const ProjectManifest(name: 'Scène', maps: [], tilesets: []),
      name: 'Rencontre',
    ).createdScene;
    final view = SceneBuilderEditingState();
    view.nodeId = original.graph.nodes.last.id;
    view.edgeId = original.graph.edges.first.id;
    view.choices[view.nodeId!] = 'continue';
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
    view.nodeId = original.graph.nodes.first.id;
    view.invalidate(original);
    expect(view.nodeId, original.graph.nodes.first.id);
  });
}

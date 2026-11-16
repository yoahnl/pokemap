import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_catalog_controller.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import '../storyline/storyline_fakes.dart';

SceneAsset catalogScene(String id, [String? name]) => SceneAsset(
  id: id,
  name: name ?? id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'flow',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

SceneDocument catalogDocument(SceneAsset scene) => SceneDocument(
  scene: scene,
  dialogues: const [],
  missingDialogueIds: const [],
  events: const [],
  maps: const {},
  mapReads: 0,
);

final class CatalogHarness {
  CatalogHarness({int count = 2}) {
    index.titlesByKind[NarrativeTitleKind.scenes] = [
      for (var i = 0; i < count; i++)
        NarrativeTitle(id: 'scene_$i', title: 'Scène $i'),
    ];
    for (var i = 0; i < count; i++) {
      index.documents['scene_$i'] = catalogDocument(
        catalogScene('scene_$i', 'Scène $i'),
      );
    }
    controller = SceneCatalogController(
      port: index,
      storylines: stories,
      draft: draft,
      source: () => source,
      changed: () => changes++,
    );
  }

  final index = FakeNarrativeIndex();
  final stories = FakeStorylineRead();
  final draft = StoryDraft();
  final source = FakeBehaviourSource();
  late final SceneCatalogController controller;
  int changes = 0;
}

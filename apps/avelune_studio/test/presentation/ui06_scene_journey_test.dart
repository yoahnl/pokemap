import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_builder_editing_state.dart';
import 'package:avelune_studio/features/scenes/application/scene_linked_document_reader.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('scene commands undo linked reading and preview preserve the native document', () async {
    final fixture = await Ui06SceneFixture.create();
    addTearDown(fixture.dispose);
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
      narrative: narrative,
      changed: () {},
    );
    addTearDown(scenes.dispose);
    expect(scenes.open(Ui06SceneFixture.sceneId), isTrue);
    final session = scenes.active!;
    final initial = session.current;
    final recorded = await fixture.maps.loadProject(fixture.session);
    final firstEdge = initial.graph.edges.first;
    expect(session.disconnect(firstEdge.id), isTrue);
    expect(session.current.graph.edges, isNot(contains(firstEdge)));
    expect(session.undoCount, 1);
    session.restore(redo: false);
    expect(session.current, initial);
    final state = SceneBuilderEditingState()..nodeId = 'welcome';
    final node = initial.graph.nodes.singleWhere(
      (node) => node.id == state.nodeId,
    );
    final payload = node.payload as SceneYarnDialoguePayload;
    final reader = SceneLinkedDocumentReader();
    final document = await reader.readDialogueDocument(
      payload.dialogueId,
      maps.project!,
      narrative,
    );
    expect(
      document.toJson().toString(),
      contains(Ui06SceneFixture.lines['station_welcome']!),
    );
    state.calculate(initial);
    expect(state.preview, isNotNull);
    expect(state.previewError, isNull);
    expect(state.nodeId, node.id);
    expect(session.current, initial);
    expect(session.dirty, isFalse);
    expect(await fixture.maps.loadProject(fixture.session), recorded);
  });
}

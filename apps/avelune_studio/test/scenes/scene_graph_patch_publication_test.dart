import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_catalog_transaction.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_edits.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_layout.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_ids.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_patch.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  late Ui06SceneFixture patched;
  late Ui06SceneFixture whole;
  setUp(() async {
    patched = await Ui06SceneFixture.create();
    whole = await Ui06SceneFixture.create();
  });
  tearDown(() async {
    await patched.dispose();
    await whole.dispose();
  });

  SceneAsset insertRememberedFact(SceneAsset scene) {
    final next = scene.graph.edges.singleWhere(
      (edge) => edge.fromNodeId == 'welcome' && edge.fromPortId == 'completed',
    );
    var links = 0;
    final ids = SceneStepIds(
      node: () => 'remember',
      edge: () => 'remembered_${links++}',
    );
    final added = addSceneGraphStep(
      scene,
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setFact(
          factId: Ui06SceneFixture.departureFactId,
          value: false,
        ),
      ),
      at: const SceneGraphPoint(0, 400),
      from: (nodeId: 'welcome', portId: 'completed'),
      ids: ids,
    );
    final relinked = connectSceneGraphExit(
      (added as SceneGraphEdited).scene,
      from: (nodeId: 'remember', portId: 'completed'),
      toNodeId: next.toNodeId,
      ids: ids,
    );
    return (relinked as SceneGraphEdited).scene;
  }

  Future<List<String>> recordedActions(Ui06SceneFixture fixture) async {
    final found = <String>[];
    await for (final entity in fixture.directory.list(recursive: true)) {
      if (entity is! File || entity.path.endsWith('/project.json')) continue;
      final text = utf8.decode(
        await entity.readAsBytes(),
        allowMalformed: true,
      );
      for (final action in const ['scene.graph.patch', 'scene.upsert']) {
        if (text.contains('"$action"')) found.add(action);
      }
    }
    return found;
  }

  test('a graph-only edit is published by patch with the same result as a whole write', () async {
    final base = patched.scene;
    expect(whole.scene, base);
    final current = insertRememberedFact(base);
    final patch = (sceneGraphPatchForScenes(
      base: base,
      current: current,
    ) as SceneGraphPatchReady).patch;
    expect(patch.upsertNodes.map((node) => node.id), ['remember']);
    expect(patch.upsertEdges.map((edge) => edge.id), [
      'remembered_0',
      'remembered_1',
    ]);
    expect(patch.removeNodeIds, isEmpty);
    expect(patch.removeEdgeIds, ['edge_welcome_completed_pass']);
    expect(patch.nodeLayouts.single.nodeId, 'remember');
    final patchBytes = utf8.encode(jsonEncode(patch.toParameters())).length;
    final wholeBytes = utf8.encode(jsonEncode(current.toJson())).length;
    expect(patchBytes, lessThan(wholeBytes ~/ 2));

    final receipt = await LocalSceneAdapter(
      session: patched.session,
      mapAdapter: patched.maps,
    ).publishScene(base: base, current: current);
    await LocalNarrativeCatalogTransaction(
      session: whole.session,
      mapAdapter: whole.maps,
    ).run(
      actionId: 'scene.upsert',
      parameters: (_) => {'scene': current.toJson()},
    );

    expect(receipt.scene, current);
    expect(receipt.catalog.changedPaths, ['project.json']);
    expect(await recordedActions(patched), contains('scene.graph.patch'));
    expect(await recordedActions(patched), isNot(contains('scene.upsert')));
    final patchedProject = await LocalMapWorkspaceAdapter().loadProject(
      patched.session,
    );
    final wholeProject = await LocalMapWorkspaceAdapter().loadProject(
      whole.session,
    );
    expect(patchedProject.scenes.single, current);
    expect(patchedProject.toJson(), wholeProject.toJson());
  });

  test('a layout move still writes the whole scene', () async {
    final base = patched.scene;
    final moved = updateSceneNodeLayout(
      insertRememberedFact(base),
      nodeId: 'welcome',
      x: 900,
      y: 900,
    ).updatedScene;
    expect(
      sceneGraphPatchForScenes(base: base, current: moved),
      isA<SceneGraphPatchUnsupported>(),
    );
    final receipt = await LocalSceneAdapter(
      session: patched.session,
      mapAdapter: patched.maps,
    ).publishScene(base: base, current: moved);
    expect(receipt.scene, moved);
    expect(await recordedActions(patched), contains('scene.upsert'));
    expect(
      await recordedActions(patched),
      isNot(contains('scene.graph.patch')),
    );
  });

  test('a stale base is refused by the patch path without writing', () async {
    final base = patched.scene;
    final port = LocalSceneAdapter(
      session: patched.session,
      mapAdapter: patched.maps,
    );
    await port.publishScene(base: base, current: insertRememberedFact(base));
    final file = File('${patched.directory.path}/project.json');
    final bytes = await file.readAsBytes();
    await expectLater(
      port.publishScene(base: base, current: insertRememberedFact(base)),
      throwsA(isA<SceneFailure>()),
    );
    expect(await file.readAsBytes(), bytes);
  });
}

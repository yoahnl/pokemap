import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'editor bridge preserves layout and other nodes through semantic patch',
    () async {
      final root = await Directory.systemTemp.createTemp('scene-graph-editor-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final scene = SceneAsset(
        id: 'test',
        name: 'Test',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'finish',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        layout: SceneGraphLayout(
          nodeLayouts: [SceneNodeLayout(nodeId: 'start', x: 20, y: 40)],
        ),
      );
      await file.writeAsString(
        jsonEncode(
          ProjectManifest(
            name: 'Editor graph',
            maps: [],
            tilesets: [],
            scenes: [scene],
          ).toJson(),
        ),
      );
      const reader = EditorProjectFileReader();
      final canonicalRoot = await reader.canonicalizeDirectory(root.path);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      await queries.retainOnly(canonicalRoot);
      await mutations.retainOnly(canonicalRoot);
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final before = await file.readAsBytes();
      final plan = await mutations.plan(
        canonicalRoot,
        actionId: 'scene.graph.patch',
        parameters: {
          'sceneId': 'test',
          'upsertNodes': [
            SceneNode(
              id: 'end',
              kind: SceneNodeKind.end,
              title: 'Fin vérifiée',
            ).toJson(),
          ],
        },
        idempotencyKey: 'editor-scene-edit',
      );
      expect(await file.readAsBytes(), before);
      final result = await mutations.apply(
        plan,
        operationId: 'editor-scene-apply',
      );
      expect(result.receipt.actionId, 'scene.graph.patch');
      final updated = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      ).scenes.single;
      expect(updated.graph.nodes.last.title, 'Fin vérifiée');
      expect(updated.graph.nodes.first, scene.graph.nodes.first);
      expect(updated.graph.edges, scene.graph.edges);
      expect(updated.layout, scene.layout);
    },
  );
}

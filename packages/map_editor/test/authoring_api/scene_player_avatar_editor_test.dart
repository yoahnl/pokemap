import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test(
      'L15 editor bridge persists avatar selection and restoration in ${dimension.name}',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'l15-avatar-editor-',
        );
        addTearDown(() => root.delete(recursive: true));
        final scene = SceneAsset(
          id: 'avatar',
          name: 'Tenue',
          metadata: const {'preserved': 'yes'},
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'change',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                  SceneConsequence.healParty(),
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'change',
                kind: SceneEdgeKind.defaultFlow,
              ),
              SceneEdge(
                id: 'leave',
                fromNodeId: 'change',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            ],
          ),
          layout: SceneGraphLayout(
            nodeLayouts: [SceneNodeLayout(nodeId: 'change', x: 20, y: 40)],
          ),
        );
        final manifest = ProjectManifest(
          name: 'Avatar',
          version: dimension == ProjectDimension.threeD
              ? ProjectVersion.v9
              : ProjectVersion.v8,
          settings: ProjectSettings(dimension: dimension),
          maps: [],
          tilesets: [
            const ProjectTilesetEntry(
              id: 'actors',
              name: 'Acteurs',
              relativePath: 'actors.json',
            ),
          ],
          characters: [
            for (final id in ['original', 'uniform'])
              ProjectCharacterEntry(
                id: id,
                name: id,
                tilesetId: 'actors',
                animations: [
                  for (final direction in EntityFacing.values)
                    CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: direction,
                      frames: [
                        CharacterAnimationFrame(
                          source: TilesetSourceRect(
                            x: 0,
                            y: 0,
                            width: 1,
                            height: 2,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
          scenes: [scene],
        );
        final file = File('${root.path}/project.json');
        await file.writeAsString(jsonEncode(manifest.toJson()));
        const reader = EditorProjectFileReader();
        final path = await reader.canonicalizeDirectory(root.path);
        final queries = AuthoringQueryAdapter(fileReader: reader);
        final mutations = AuthoringMutationAdapter(
          fileReader: reader,
          queries: queries,
          projectRoots: reader,
        );
        addTearDown(queries.closeAll);
        addTearDown(mutations.closeAll);
        await queries.retainOnly(path);
        await mutations.retainOnly(path);
        for (final id in ['uniform', 'original']) {
          final before = await file.readAsBytes();
          final plan = await mutations.plan(
            path,
            actionId: 'scene.graph.patch',
            idempotencyKey: 'avatar-$id',
            parameters: {
              'sceneId': 'avatar',
              'upsertNodes': [
                {
                  'id': 'change',
                  'kind': 'action',
                  'payload': {
                    'consequence': {
                      'kind': 'setPlayerAvatar',
                      'characterId': id,
                    },
                  },
                },
              ],
            },
          );
          expect(await file.readAsBytes(), before);
          final applied = await mutations.apply(
            plan,
            operationId: 'apply-avatar-$id',
          );
          expect(applied.receipt.actionId, 'scene.graph.patch');
          final stored = ProjectManifest.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          ).scenes.single;
          final payload =
              stored.graph.nodes
                      .singleWhere((node) => node.id == 'change')
                      .payload
                  as SceneActionPayload;
          expect(payload.consequence!.toJson(), {
            'kind': 'setPlayerAvatar',
            'characterId': id,
          });
          expect(stored.layout, scene.layout);
          expect(stored.metadata, scene.metadata);
        }
        final before = await file.readAsBytes();
        await expectLater(
          mutations.plan(
            path,
            actionId: 'scene.graph.patch',
            idempotencyKey: 'avatar-missing',
            parameters: {
              'sceneId': 'avatar',
              'upsertNodes': [
                {
                  'id': 'change',
                  'kind': 'action',
                  'payload': {
                    'consequence': {
                      'kind': 'setPlayerAvatar',
                      'characterId': 'missing',
                    },
                  },
                },
              ],
            },
          ),
          throwsA(
            isA<EditorAuthoringMutationFailure>().having(
              (error) => error.code,
              'code',
              'scene.publication_blocked',
            ),
          ),
        );
        expect(await file.readAsBytes(), before);
      },
    );
  }
}


import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:test/test.dart';

void main() {
  group('L15 persistent player avatar', () {

    test('compiles, previews change and restores by explicit selection', () {
      final scene = _scene(['costume', 'original']);
      final project = _project(scenes: [scene]);
      final diagnostics = diagnoseSceneAgainstProject(scene, project);
      expect(
        diagnostics.hasErrors,
        isFalse,
        reason: diagnostics.diagnostics
            .map((issue) => issue.message)
            .join('\n'),
      );
      final built = buildSceneRuntimePlan(scene);
      expect(built.plan, isNotNull);
      final preview = previewSceneRuntimePath(
        built.plan!,
        input: SceneDryRunInputState(
          consequenceState: SceneDryRunConsequenceState(
            playerAvatarCharacterId: 'original',
            money: 42,
            itemQuantityById: {'potion': 2},
          ),
        ),
      );

      expect(preview.status, SceneDryRunPreviewStatus.completed);
      expect(preview.consequenceState.playerAvatarCharacterId, 'original');
      expect(preview.consequenceState.money, 42);
      expect(preview.consequenceState.itemQuantityById, {'potion': 2});
      expect(preview.consequenceChanges.map((change) => change.afterSummary), [
        'avatar=costume',
        'avatar=original',
      ]);
      expect(preview.consequenceChanges.first.beforeSummary, 'avatar=original');
      expect(
        buildSceneRuntimePlan(
          SceneAsset.fromJson({
            ...scene.toJson(),
            'executionProfile': 'preSession',
          }),
        ).plan,
        isNull,
      );
    });

  });
}

ProjectCharacterEntry _character(String id, {String? sourceAssetId}) =>
    ProjectCharacterEntry(
      id: id,
      name: id,
      tilesetId: 'sprites',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            sourceAssetId: sourceAssetId,
            frames: [
              const CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
      ],
    );

ProjectManifest _project({
  List<ProjectCharacterEntry>? characters,
  List<ProjectTilesetEntry>? tilesets,
  List<SceneAsset> scenes = const [],
}) => ProjectManifest(
  name: 'Avatar contract',
  maps: [],
  tilesets:
      tilesets ??
      [
        const ProjectTilesetEntry(
          id: 'sprites',
          name: 'Sprites',
          relativePath: 'assets/sprites.png',
        ),
      ],
  characters: characters ?? [_character('original'), _character('costume')],
  scenes: scenes,
);

SceneAsset _scene(List<String> characterIds) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < characterIds.length; index++)
      SceneNode(
        id: 'avatar_$index',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setPlayerAvatar(characterId: characterIds[index]),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scene-avatar',
    name: 'Avatar scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: index == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (var index = 0; index < nodes.length; index++)
          SceneNodeLayout(nodeId: nodes[index].id, x: index * 200, y: 0),
      ],
    ),
  );
}

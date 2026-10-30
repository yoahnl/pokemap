import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  test('image puzzles require a capability only when a scene uses them', () {
    const empty = ProjectManifest(name: 'Empty', maps: [], tilesets: []);
    expect(SpatialGameplayCapabilities.requiresImagePuzzle(empty), isFalse);
    final command = SceneInteractiveCommand.openImagePuzzle(
        definition: ImagePuzzleDefinition(
            puzzleId: 'mosaic', imageResourceId: 'image', rows: 2, columns: 2));
    final project = empty.copyWith(scenes: [
      SceneAsset(
          id: 'puzzle',
          name: 'Puzzle',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'open',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(command))
          ]))
    ]);
    expect(SpatialGameplayCapabilities.requiresImagePuzzle(project), isTrue);
    expect(AveluneRuntimeCompatibility.host().capabilities,
        contains(SpatialGameplayCapabilities.imagePuzzleCapabilityId));
  });
}

import 'package:avelune_studio/features/scenes/application/scene_image_puzzle_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'puzzle owner reopens the complete image and placement definition',
    () async {
      final definition = ImagePuzzleDefinition(
        puzzleId: 'mosaic',
        imageResourceId: 'image',
        rows: 2,
        columns: 2,
        trayCapacity: 2,
        allowedQuarterTurns: [0, 2],
        fixedPieceIds: [0],
        allowReset: false,
        allowSwap: true,
        initialPieces: [
          ImagePuzzlePiece(pieceId: 0, slot: 0),
          ImagePuzzlePiece(pieceId: 1, slot: 2, quarterTurns: 2),
          ImagePuzzlePiece(pieceId: 2, slot: 4),
          ImagePuzzlePiece(pieceId: 3, slot: 3),
        ],
      );
      final draft = SceneImagePuzzleDraft(
        current: SceneOpenImagePuzzleInteractiveCommand(definition: definition),
        changed: () {},
        loadVisualMedia: () async => ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'image',
              label: 'Mosaïque choisie',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'image-source',
            ),
            ProjectMediaAsset(
              id: 'sound',
              label: 'Son exclu',
              kind: ProjectMediaKind.audio,
              sourceAssetId: 'sound-source',
            ),
          ],
        ),
      );
      addTearDown(draft.dispose);
      await draft.load();
      expect(draft.fixed, [0]);
      expect(draft.images, {'image': 'Mosaïque choisie'});
      expect(draft.definition, definition);
    },
  );
}

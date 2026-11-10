import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_image_puzzle_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

ProjectMediaCatalog _catalog(String id) => ProjectMediaCatalog(
  entries: [
    ProjectMediaAsset(
      id: id,
      label: 'Mosaïque',
      kind: ProjectMediaKind.image,
      sourceAssetId: 'source',
    ),
  ],
);

void main() {
  test(
    'initial layout keeps fixed pieces and rejects duplicate occupied slots',
    () async {
      final draft = SceneImagePuzzleDraft(
        current: null,
        changed: () {},
        loadVisualMedia: () async => _catalog('image'),
      );
      addTearDown(draft.dispose);
      await draft.load();
      draft.change('puzzleId', 'mosaic');
      draft.change('imageResourceId', 'image');
      draft.change('rows', 2);
      draft.change('columns', 2);
      draft.change('fixedPieceIds', [0]);
      final pieces = draft.initial();
      expect(pieces.first, {'pieceId': 0, 'slot': 0, 'quarterTurns': 0});
      expect(pieces.map((piece) => piece['slot']).toSet(), hasLength(4));
      draft.change('initialPieces', pieces);
      expect(draft.definition, isNotNull);
      draft.piece(1, 'slot', 0);
      expect(draft.definition, isNull);
    },
  );

  test('disposal ignores a late media catalogue without notifying', () async {
    final media = Completer<ProjectMediaCatalog>();
    var changes = 0;
    final draft = SceneImagePuzzleDraft(
      current: null,
      changed: () => changes++,
      loadVisualMedia: () => media.future,
    );
    final pending = draft.load();
    draft.dispose();
    media.complete(_catalog('late'));
    await pending;
    expect(draft.images, isEmpty);
    expect(changes, 0);
  });
}

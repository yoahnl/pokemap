import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/decor_draft_test.dart' as fixtures;

void main() {
  test(
    'a continuous stroke follows the source image and excludes outside cells',
    () {
      final draft = DecorDraft(tileset: fixtures.atlas())
        ..selection = const TilesetSourceRect(x: 0, y: 0, width: 5, height: 3);
      draft.beginCollisionPointer(4, 10, fine: false, solid: true);
      draft.moveCollisionPointer(68, 10, fine: false, solid: true);
      draft.moveCollisionPointer(1000, 10, fine: false, solid: true);
      draft.endCollisionPointer();
      expect(draft.blocked, {for (var x = 0; x < 5; x++) GridPos(x: x, y: 0)});
      expect(draft.collisionDrawing, isFalse);
      expect(draft.collisionPoint(-1, 10, fine: false), isNull);
      expect(draft.collisionPoint(80, 10, fine: false), isNull);
      draft.undoCollision();
      expect(draft.build().collisionProfile, isNull);
      draft.redoCollision();
      expect(draft.blocked, hasLength(5));
    },
  );

  test('fine keyboard painting and cancellation preserve exactly the completed strokes', () {
    final draft = DecorDraft(tileset: fixtures.atlas())
      ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2, height: 2);
    draft.beginCollisionPointer(3.2, 4.8, fine: true, solid: true);
    draft.endCollisionPointer();
    expect(draft.collisionCursor, const GridPos(x: 3, y: 4));
    draft.moveCollisionCursor(const GridPos(x: 1, y: 0), fine: true);
    draft.paintCollisionCursor(fine: true, solid: true);
    expect(draft.collisionCursor, const GridPos(x: 4, y: 4));
    final completed = draft.build().collisionProfile;
    draft.beginCollisionPointer(12, 6, fine: true, solid: true);
    draft.cancelCollisionPointer();
    expect(draft.collisionDrawing, isFalse);
    expect(draft.build().collisionProfile, completed);
    draft.undoCollision();
    expect(draft.collisionPixels![4 * 32 + 3], isTrue);
    expect(draft.collisionPixels![4 * 32 + 4], isFalse);
    draft.undoCollision();
    expect(draft.build().collisionProfile, isNull);
    draft.moveCollisionCursor(const GridPos(x: -100, y: 100), fine: true);
    expect(draft.collisionCursor, const GridPos(x: 0, y: 47));
  });
}

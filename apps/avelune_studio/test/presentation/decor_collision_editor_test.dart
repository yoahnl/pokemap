import 'dart:async';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/decor_draft_test.dart' as fixtures;

void main() {
  test('changing source dimensions cannot silently crop a fine mask', () {
    final draft = DecorDraft(tileset: fixtures.atlas())
      ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2);
    draft.paintCollisionPixel(const GridPos(x: 20, y: 4), solid: true);
    final before = draft.build();
    expect(draft.selectSource(const TilesetSourceRect(x: 0, y: 0)), isFalse);
    expect(draft.selection, before.frames.first.source);
    expect(draft.build().collisionProfile, before.collisionProfile);
    expect(draft.error, contains('Conservez les dimensions'));
    expect(
      draft.selectSource(const TilesetSourceRect(x: 1, y: 0, width: 2)),
      isTrue,
    );
    expect(draft.build().collisionProfile, before.collisionProfile);
    draft.setBlocked(false);
    expect(draft.selectSource(const TilesetSourceRect(x: 0, y: 0)), isTrue);
    expect(draft.error, isNull);
  });

  test(
    'cell brush and pixel eraser share the source and undo an entire stroke',
    () {
      final draft = DecorDraft(tileset: fixtures.atlas())
        ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2);
      draft.beginCollisionPointer(4, 10, fine: false, solid: true);
      draft.moveCollisionPointer(20, 10, fine: false, solid: true);
      draft.endCollisionPointer();
      expect(draft.build().collisionProfile!.cells, hasLength(2));
      draft.undoCollision();
      expect(draft.build().collisionProfile, isNull);
      draft.redoCollision();
      expect(draft.build().collisionProfile!.cells, hasLength(2));
      draft.beginCollisionPointer(3.5, 4.5, fine: true, solid: false);
      draft.endCollisionPointer();
      final mask = draft.build().collisionProfile!.collisionMask!;
      final pixels = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
      expect(pixels[4 * 32 + 3], isFalse);
      expect(pixels.where((value) => value), hasLength(32 * 24 - 1));
      expect(draft.collisionPixels![4 * 32 + 3], isFalse);
      draft.undoCollision();
      expect(draft.build().collisionProfile!.collisionMask, isNull);
    },
  );

  test(
    'failed saving retains focused text and collisions for an identical retry',
    () async {
      final draft = DecorDraft(tileset: fixtures.atlas())
        ..name = 'Arbre à l’orée';
      draft.beginCollisionPointer(4, 8, fine: false, solid: true);
      draft.endCollisionPointer();
      var fail = true;
      final snapshots = <ProjectElementEntry>[];
      Future<void> publish(ProjectElementEntry value) async {
        snapshots.add(value);
        if (fail) throw StateError('Publication refusée');
      }

      expect(await draft.save(publish), isFalse);
      expect(draft.error, contains('Publication refusée'));
      expect(draft.name, 'Arbre à l’orée');
      expect(draft.blocked, {const GridPos(x: 0, y: 0)});
      fail = false;
      expect(await draft.save(publish), isTrue);
      expect(snapshots, hasLength(2));
      expect(snapshots.last, snapshots.first);
      expect(draft.error, isNull);
    },
  );

  test('a pending decor save has a single publication and a closed view receives no late failure', () async {
    final draft = DecorDraft(tileset: fixtures.atlas());
    final gate = Completer<void>();
    var active = true, publications = 0;
    final operation = draft.save((_) async {
      publications++;
      await gate.future;
      throw StateError('Trop tard');
    }, isActive: () => active);
    expect(draft.saving, isTrue);
    expect(
      await draft.save((_) async {
        publications++;
      }),
      isFalse,
    );
    active = false;
    gate.complete();
    expect(await operation, isFalse);
    expect(publications, 1);
    expect(draft.saving, isFalse);
    expect(draft.error, isNull);
  });
}

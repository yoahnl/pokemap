import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const manifest = ProjectManifest(
  name: 'Non square',
  maps: [],
  tilesets: [],
  settings: ProjectSettings(tileWidth: 16, tileHeight: 24),
);
ProjectTilesetEntry atlas({
  int margin = 0,
  int spacing = 0,
  int offset = 0,
  int width = 16,
}) => ProjectTilesetEntry(
  id: 'atlas',
  name: 'Planche',
  relativePath: 'atlas.png',
  source: ProjectRegularAtlasTilesetSource(
    assetId: 'atlas',
    pixelWidth: 160,
    pixelHeight: 240,
    tileWidth: width,
    tileHeight: 24,
    marginX: margin,
    spacingY: spacing,
    pixelOffsetX: offset,
  ),
);

void main() {
  test('one coarse cell preserves fine pixels outside its rectangle', () {
    final source = atlas();
    final pixels = List<bool>.filled(32 * 24, false)..[4 * 32 + 20] = true;
    final mask = ElementCollisionPixelMask(
      widthPx: 32,
      heightPx: 24,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: 32,
        heightPx: 24,
        solidPixels: pixels,
      ),
    );
    final original = ProjectElementEntry(
      id: 'tree',
      name: 'Arbre',
      tilesetId: source.id,
      categoryId: 'forest',
      frames: const [
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0, width: 2)),
      ],
      collisionProfile: ElementCollisionProfile(
        collisionMask: mask,
        visualMask: mask,
        occlusionMask: mask,
        cells: const [GridPos(x: 1, y: 0)],
      ),
    );
    final draft = DecorDraft(tileset: source, original: original);
    draft.beginCollisionStroke();
    draft.paintCollisionCell(const GridPos(x: 0, y: 0), solid: true);
    draft.endCollisionStroke();
    final result = draft.build();
    final changed = result.collisionProfile!.collisionMask!;
    final actual = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: 32,
      heightPx: 24,
      dataBase64: changed.dataBase64,
    );
    for (var y = 0; y < 24; y++) {
      for (var x = 0; x < 32; x++) {
        expect(actual[y * 32 + x], x < 16 || (x == 20 && y == 4));
      }
    }
    expect(result.collisionProfile!.visualMask, mask);
    expect(result.collisionProfile!.occlusionMask, mask);
    draft.undoCollision();
    expect(draft.build().collisionProfile, original.collisionProfile);
    draft.redoCollision();
    expect(draft.build(), result);
    draft.beginCollisionStroke();
    draft.paintCollisionCell(const GridPos(x: 0, y: 0), solid: false);
    draft.endCollisionStroke();
    expect(draft.build().collisionProfile!.collisionMask, mask);
  });

  test('fine erasing projects cells and groups a stroke for undo', () {
    final draft = DecorDraft(tileset: atlas())
      ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2)
      ..setBlocked(true);
    final before = draft.build();
    draft.beginCollisionStroke();
    for (var x = 0; x < 16; x++) {
      for (var y = 0; y < 24; y++) {
        draft.paintCollisionPixel(GridPos(x: x, y: y), solid: false);
      }
    }
    draft.endCollisionStroke();
    final result = draft.build();
    expect(result.collisionProfile!.cells, [const GridPos(x: 1, y: 0)]);
    final restored = ProjectElementEntry.fromJson(result.toJson());
    expect(restored, result);
    draft.undoCollision();
    expect(draft.build(), before);
    draft.redoCollision();
    expect(draft.build(), result);
    draft.beginCollisionStroke();
    draft.paintCollisionPixel(
      const GridPos(x: 22, y: 4),
      solid: false,
      size: 4,
    );
    draft.cancelCollisionStroke();
    expect(draft.build(), result);
  });

  test(
    'rebase preserves concurrent draft changes and the published identity',
    () {
      final draft = DecorDraft(tileset: atlas())
        ..name = 'Avant publication'
        ..selection = const TilesetSourceRect(x: 0, y: 0, width: 2)
        ..variant = true;
      final saved = draft.build().copyWith(id: 'identity-published');
      draft.name = 'Saisie pendant la sauvegarde';
      draft.beginCollisionStroke();
      draft.paintCollisionCell(const GridPos(x: 1, y: 0), solid: true);
      draft.endCollisionStroke();
      draft.rebase(saved);
      final result = draft.build();
      expect(result.id, saved.id);
      expect(result.name, 'Saisie pendant la sauvegarde');
      expect(result.collisionProfile!.cells, [const GridPos(x: 1, y: 0)]);
      expect(draft.variant, isFalse);
      expect(draft.canUndoCollision, isTrue);
    },
  );

  test(
    'out of bounds painting leaves the definition and history unchanged',
    () {
      final draft = DecorDraft(tileset: atlas());
      final before = draft.build();
      draft.beginCollisionStroke();
      draft.paintCollisionCell(const GridPos(x: -1, y: 0), solid: true);
      draft.paintCollisionPixel(const GridPos(x: 16, y: 24), solid: true);
      draft.endCollisionStroke();
      expect(draft.build(), before);
      expect(draft.canUndoCollision, isFalse);
    },
  );

  test('coarse painting retains a canonical fine collision mask', () {
    final pixels = List<bool>.filled(32 * 24, false)..[4 * 32 + 20] = true;
    final original = ProjectElementEntry(
      id: 'fine-tree',
      name: 'Arbre fin',
      tilesetId: 'atlas',
      categoryId: 'forest',
      frames: const [
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0, width: 2)),
      ],
      collisionProfile: ElementCollisionProfile(
        collisionMask: ElementCollisionPixelMask(
          widthPx: 32,
          heightPx: 24,
          dataBase64: ElementCollisionMaskCodec.encodePackedBits(
            widthPx: 32,
            heightPx: 24,
            solidPixels: pixels,
          ),
        ),
        cells: const [GridPos(x: 1, y: 0)],
      ),
    );
    final draft = DecorDraft(tileset: atlas(), original: original);
    draft.setBlocked(true);
    final mask = draft.build().collisionProfile!.collisionMask;
    expect(mask, isNotNull);
    expect(mask!.widthPx, 32);
    expect(mask.heightPx, 24);
    expect(
      ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      ),
      everyElement(isTrue),
    );
  });

  test(
    'decor conversion permits matching non-square grid and precisely rejects unsupported geometry',
    () {
      expect(canCreateDecor(atlas(), manifest), isTrue);
      expect(
        decorConversionProblem(atlas(margin: 1), manifest),
        contains('marges'),
      );
      expect(
        decorConversionProblem(atlas(spacing: 2), manifest),
        contains('espacements'),
      );
      expect(
        decorConversionProblem(atlas(offset: 3), manifest),
        contains('décalage'),
      );
      expect(
        decorConversionProblem(atlas(width: 32), manifest),
        contains('16 × 24'),
      );
      expect(canCreateDecor(atlas().copyWith(source: null), manifest), isFalse);
    },
  );

  test(
    'variant creates independent identity and preserves animation, categories and advanced collision data',
    () {
      final mask = ElementCollisionPixelMask(
        widthPx: 1,
        heightPx: 1,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 1,
          heightPx: 1,
          solidPixels: [true],
        ),
      );
      final original = ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'atlas',
        categoryId: 'forest',
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0),
            durationMs: 150,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0),
            durationMs: 300,
          ),
        ],
        collisionProfile: ElementCollisionProfile(
          collisionMask: mask,
          visualMask: mask,
          occlusionMask: mask,
          cells: const [GridPos(x: 0, y: 0)],
        ),
      );
      final initial = original.toJson();
      final draft = DecorDraft(tileset: atlas(), original: original)
        ..variant = true
        ..name = '  Variante  '
        ..selection = const TilesetSourceRect(x: 2, y: 2);
      final result = draft.build();
      expect(result.id, isNot(original.id));
      expect(result.name, 'Variante');
      expect(result.frames, original.frames);
      expect(result.categoryId, original.categoryId);
      expect(result.collisionProfile, original.collisionProfile);
      expect(original.toJson(), initial);
      draft.setBlocked(false);
      final traversable = draft.build();
      expect(traversable.collisionProfile!.cells, isEmpty);
      expect(traversable.collisionProfile!.collisionMask, isNull);
      expect(traversable.collisionProfile!.occlusionMask, mask);
      expect(traversable.collisionProfile!.visualMask, mask);
      expect(original.toJson(), initial);
    },
  );

  test('new rectangle decor blocks selected cells and rejects blank name', () {
    final draft = DecorDraft(tileset: atlas())
      ..selection = const TilesetSourceRect(x: 3, y: 4, width: 2, height: 3)
      ..name = 'Maison';
    draft.setBlocked(true);
    final result = draft.build();
    expect(result.frames.single.source, draft.selection);
    expect(result.tilesetId, 'atlas');
    expect(result.collisionProfile!.cells, hasLength(6));
    expect(result.collisionProfile!.cells, contains(const GridPos(x: 1, y: 2)));
    draft.name = '  ';
    expect(draft.build, throwsFormatException);
  });
}

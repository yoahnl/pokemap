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

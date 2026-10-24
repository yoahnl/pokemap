import 'package:image/image.dart' as img;
import 'package:map_authoring/src/domains/assets/resource_pack_border_sources.dart';
import 'package:map_authoring/src/domains/maps/canonical_border_snapshot_compiler.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('multi-cell Border export preserves semi-transparent source RGBA', () async {
    final image = img.Image(width: 2, height: 4, numChannels: 4);
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 2; x++) {
        image.setPixelRgba(x, y, 110 + x * 35, 70 + y * 20, 249, [1, 127, 254, 255][y]);
      }
    }
    final bytes = img.encodePng(image);
    const element = ProjectElementEntry(id: 'glass-wall', name: 'Vitre', tilesetId: 'atlas', categoryId: 'wall', frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2), durationMs: 120)]);
    final manifest = ProjectManifest(name: 'Border RGBA', maps: [], settings: const ProjectSettings(tileWidth: 2, tileHeight: 2), elements: [element], tilesets: [ProjectTilesetEntry(id: 'atlas', name: 'Vitre', relativePath: 'assets/glass.png', source: ProjectRegularAtlasTilesetSource(assetId: 'glass-pixels', pixelWidth: 2, pixelHeight: 4, tileWidth: 2, tileHeight: 2))]);
    final expected = const CanonicalBorderSnapshotCompiler().prepare(sourceElementId: element.id, frames: [CanonicalBorderSourceFrame(sourceProjectRelativePath: 'assets/glass.png', encodedImageBytes: bytes, sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 2, height: 4), durationMs: 120)]);
    final actual = await prepareResourcePackElementSource(manifest, element, (tile, assetId) async => bytes);
    expect(actual.snapshot.contentFingerprint, expected.snapshot.contentFingerprint);
    expect(actual.files.single.bytes, expected.files.single.bytes);
  });
}

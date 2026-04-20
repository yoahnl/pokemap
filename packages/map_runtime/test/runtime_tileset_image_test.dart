import 'dart:ui';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRuntimeTilesetChunks', () {
    test('splits tall tilesets into bounded vertical chunks', () {
      final chunks = buildRuntimeTilesetChunks(
        totalWidth: 256,
        totalHeight: 17056,
        maxChunkHeight: 4096,
      );

      expect(chunks, hasLength(5));
      expect(chunks.first.top, 0);
      expect(chunks.first.height, 4096);
      expect(chunks.last.top, 16384);
      expect(chunks.last.height, 672);
      expect(
        chunks.every((chunk) => chunk.height > 0 && chunk.height <= 4096),
        isTrue,
      );
    });
  });

  group('resolveRuntimeTilesetDrawSlices', () {
    test('splits a source rect that crosses a chunk boundary', () {
      final chunks = buildRuntimeTilesetChunks(
        totalWidth: 256,
        totalHeight: 17056,
        maxChunkHeight: 4096,
      );

      final slices = resolveRuntimeTilesetDrawSlices(
        sourceRect: const Rect.fromLTWH(32, 4080, 32, 64),
        destinationRect: const Rect.fromLTWH(10, 20, 64, 128),
        chunks: chunks,
      );

      expect(slices, hasLength(2));
      expect(slices.first.chunkIndex, 0);
      expect(slices.first.sourceRect, const Rect.fromLTWH(32, 4080, 32, 16));
      expect(
        slices.first.destinationRect,
        const Rect.fromLTWH(10, 20, 64, 32),
      );
      expect(slices.last.chunkIndex, 1);
      expect(slices.last.sourceRect, const Rect.fromLTWH(32, 0, 32, 48));
      expect(
        slices.last.destinationRect,
        const Rect.fromLTWH(10, 52, 64, 96),
      );
    });

    test('returns empty when the source rect exceeds the atlas bounds', () {
      final chunks = buildRuntimeTilesetChunks(
        totalWidth: 256,
        totalHeight: 1024,
        maxChunkHeight: 512,
      );

      final slices = resolveRuntimeTilesetDrawSlices(
        sourceRect: const Rect.fromLTWH(0, 1000, 32, 64),
        destinationRect: const Rect.fromLTWH(0, 0, 32, 64),
        chunks: chunks,
      );

      expect(slices, isEmpty);
    });
  });

  test('loadTilesetImageFromFilePath chunks very tall tilesets', () async {
    final tempDir = Directory.systemTemp.createTempSync('tileset_chunk_test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final tallImage = img.Image(width: 8, height: 5000);
    img.fill(tallImage, color: img.ColorRgba8(255, 0, 0, 255));
    final path = p.join(tempDir.path, 'tall_tileset.png');
    await File(path).writeAsBytes(img.encodePng(tallImage, level: 0));

    final loaded = await loadTilesetImageFromFilePath(path);

    expect(loaded.width, 8);
    expect(loaded.height, 5000);
    expect(loaded.chunkCount, 2);
  });
}

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a tall atlas preserves chunk boundaries within the default image budget',
    () async {
      const width = 256;
      const height = 28160;
      const rows = [0, 4095, 4096, 8191, 8192, height - 1];
      final source = img.Image(
        width: width,
        height: height,
        numChannels: 4,
        textData: {
          'profile-note': String.fromCharCodes(
            Uint8List(600000)..fillRange(0, 600000, 120),
          ),
        },
      );
      for (var index = 0; index < rows.length; index++) {
        source.setPixelRgba(
          0,
          rows[index],
          30 + index,
          70 + index,
          110 + index,
          255,
        );
      }
      final bytes = Uint8List.fromList(img.encodePng(source));
      expect(bytes.length, greaterThan(600000));
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      expect(budget.profile.maximumTransientBytes, 64 * 1024 * 1024);
      expect(budget.profile.maximumResidentBytes, 64 * 1024 * 1024);
      final atlas = await decodeRuntimeTilesetImage(
        bytes,
        resourceBudget: budget,
      );
      addTearDown(atlas.dispose);
      expect(atlas.width, width);
      expect(atlas.height, height);
      expect(atlas.chunkCount, 7);
      expect(atlas.chunks.every((chunk) => chunk.height <= 4096), isTrue);
      expect(budget.residentBytes, width * height * 4);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
      expect(budget.peakBytes, lessThanOrEqualTo(128 * 1024 * 1024));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()
        ..isAntiAlias = false
        ..filterQuality = ui.FilterQuality.none;
      for (var index = 0; index < rows.length; index++) {
        atlas.drawImageRect(
          canvas,
          ui.Rect.fromLTWH(0, rows[index].toDouble(), 1, 1),
          ui.Rect.fromLTWH(index.toDouble(), 0, 1, 1),
          paint,
        );
      }
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      final rendered = await picture.toImage(rows.length, 1);
      addTearDown(rendered.dispose);
      final rgba = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      for (var index = 0; index < rows.length; index++) {
        expect(
          [
            for (var channel = 0; channel < 4; channel++)
              rgba.getUint8(index * 4 + channel),
          ],
          [30 + index, 70 + index, 110 + index, 255],
          reason: 'source row ${rows[index]}',
        );
      }
      atlas.dispose();
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
    },
  );

  test(
    'a tall PNG is split before the backend image decoder is called',
    () async {
      final directory = await Directory.systemTemp.createTemp('tall-atlas-');
      addTearDown(() => directory.delete(recursive: true));
      final bytes = img.encodePng(img.Image(width: 16, height: 5000));
      final file = await File('${directory.path}/atlas.png')
          .writeAsBytes(bytes);
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final atlas = await loadTilesetImageFromFilePath(
        file.path,
        resourceBudget: budget,
        decoder: (_) =>
            throw StateError('The backend cannot decode a full atlas.'),
      );
      addTearDown(atlas.dispose);
      expect(atlas.height, 5000);
      expect(atlas.chunkCount, 2);
    },
  );

  for (final format in [img.Format.uint8, img.Format.uint16]) {
    test(
      'chunked $format PNG preserves alpha and its transparent color',
      () async {
        final scale = format == img.Format.uint16 ? 257 : 1;
        final source = img.Image(
          width: 2,
          height: 5000,
          numChannels: 4,
          format: format,
        );
        source.setPixelRgba(
          0,
          4500,
          200 * scale,
          100 * scale,
          50 * scale,
          128 * scale,
        );
        source.setPixelRgba(
          1,
          4500,
          20 * scale,
          40 * scale,
          60 * scale,
          255 * scale,
        );
        final budget = RuntimeResourceBudget();
        addTearDown(budget.dispose);
        final atlas = await decodeRuntimeTilesetImage(
          Uint8List.fromList(img.encodePng(source)),
          resourceBudget: budget,
          transparentColor: TilesetTransparentColor(
            red: 20,
            green: 40,
            blue: 60,
          ),
        );
        addTearDown(atlas.dispose);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        atlas.drawImageRect(
          canvas,
          const ui.Rect.fromLTWH(0, 4500, 2, 1),
          const ui.Rect.fromLTWH(0, 0, 2, 1),
          ui.Paint()..filterQuality = ui.FilterQuality.none,
        );
        final picture = recorder.endRecording();
        addTearDown(picture.dispose);
        final rendered = await picture.toImage(2, 1);
        addTearDown(rendered.dispose);
        final rgba = (await rendered.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(
          [for (var i = 0; i < 8; i++) rgba.getUint8(i)],
          [100, 50, 25, 128, 0, 0, 0, 0],
        );
      },
    );
  }

  test(
    'excess PNG scanlines are refused before the CPU image decoder',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 2, height: 5000, numChannels: 4)),
      );
      final compressed = BytesBuilder(copy: false);
      final data = ByteData.sublistView(bytes);
      for (var offset = 8; offset < bytes.length;) {
        final length = data.getUint32(offset);
        if (data.getUint32(offset + 4) == 0x49444154) {
          compressed.add(
            Uint8List.sublistView(bytes, offset + 8, offset + 8 + length),
          );
        }
        offset += length + 12;
      }
      final expanded = BytesBuilder(copy: false)
        ..add(ZLibCodec().decode(compressed.takeBytes()))
        ..add(Uint8List(8192));
      final replacement = Uint8List.fromList(
        ZLibCodec().encode(expanded.takeBytes()),
      );
      final idat = Uint8List(replacement.length + 12);
      ByteData.sublistView(idat)
        ..setUint32(0, replacement.length)
        ..setUint32(4, 0x49444154);
      idat.setRange(8, 8 + replacement.length, replacement);
      ByteData.sublistView(idat).setUint32(
        idat.length - 4,
        getCrc32(Uint8List.sublistView(idat, 4, idat.length - 4)),
      );
      final malformed =
          (BytesBuilder(copy: false)
                ..add(Uint8List.sublistView(bytes, 0, 33))
                ..add(idat)
                ..add(Uint8List.sublistView(bytes, bytes.length - 12)))
              .takeBytes();
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      await expectLater(
        decodeRuntimeTilesetImage(malformed, resourceBudget: budget),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (error) => error.reason,
            'reason',
            'png_scanlines',
          ),
        ),
      );
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
    },
  );

  for (final fromFile in [false, true]) {
    test(
      'two 16-bit PNGs queue using their actual bit depth, file=$fromFile',
      () async {
        final source = img.Image(
          width: 256,
          height: 10240,
          numChannels: 4,
          format: img.Format.uint16,
        );
        final bytes = Uint8List.fromList(img.encodePng(source));
        expect(bytes[24], 16);
        final budget = RuntimeResourceBudget();
        addTearDown(budget.dispose);
        final allocation = runtimeTilesetImageAllocation(
          encodedLength: bytes.length,
          width: 256,
          height: 10240,
          sourceBitDepth: 16,
        );
        expect(
          allocation.transientBytes * 2,
          greaterThan(budget.profile.maximumTransientBytes),
        );
        final directory = await Directory.systemTemp.createTemp('deep-atlas-');
        addTearDown(() => directory.delete(recursive: true));
        final file = await File('${directory.path}/atlas.png')
            .writeAsBytes(bytes);
        Future<RuntimeTilesetImage> load() => fromFile
            ? loadTilesetImageFromFilePath(file.path, resourceBudget: budget)
            : decodeRuntimeTilesetImage(bytes, resourceBudget: budget);
        final atlases = await Future.wait([load(), load()]);
        for (final atlas in atlases) {
          expect(atlas.height, 10240);
          atlas.dispose();
        }
        expect(
          budget.residentBytes + budget.transientBytes + budget.activeDecodes,
          0,
        );
      },
    );
  }

  test(
    'an atlas beyond the transient limit is still refused before decoding',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 1, height: 1)),
      );
      ByteData.sublistView(bytes)
        ..setUint32(16, 256)
        ..setUint32(20, 50000);
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      await expectLater(
        decodeRuntimeTilesetImage(bytes, resourceBudget: budget),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (error) => error.reason,
            'reason',
            'image_dimensions',
          ),
        ),
      );
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
    },
  );
}

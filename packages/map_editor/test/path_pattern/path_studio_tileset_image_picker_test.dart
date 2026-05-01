import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_tileset_image_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathStudioTilesetImagePicker image support', () {
    test('resolves an image from project root and tileset relativePath',
        () async {
      final temp = await Directory.systemTemp.createTemp('path_studio_image_');
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/main.png'));
      await imageFile.parent.create(recursive: true);
      await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'main',
          name: 'Main',
          relativePath: 'tilesets/main.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.loaded);
      expect(result.image!.absolutePath, imageFile.path);
      expect(result.image!.imageWidthPx, 64);
      expect(result.image!.imageHeightPx, 32);
      expect(result.image!.columns, 4);
      expect(result.image!.rows, 2);
    });

    test('returns a fallback status when the image file is absent', () async {
      final temp =
          await Directory.systemTemp.createTemp('path_studio_missing_');
      addTearDown(() => temp.delete(recursive: true));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'missing',
          name: 'Missing',
          relativePath: 'tilesets/missing.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.missingFile);
      expect(result.image, isNull);
      expect(result.message, contains('introuvable'));
    });

    test('applies the tileset transparent color to displayed bytes', () async {
      final temp = await Directory.systemTemp.createTemp('path_studio_alpha_');
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/alpha.png'));
      await imageFile.parent.create(recursive: true);
      await imageFile.writeAsBytes(await _pngBytes(width: 16, height: 16));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: ProjectTilesetEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'tilesets/alpha.png',
          transparentColor: TilesetTransparentColor.fromHexRgb('ff00ff'),
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      final decoded = img.decodePng(result.image!.bytes)!;
      expect(decoded.getPixel(0, 0).a.toInt(), 0);
    });

    test('converts a local click position to tile coordinates', () {
      final source = pathStudioTileSourceFromLocalPosition(
        localPosition: const ui.Offset(35, 17),
        displaySize: const ui.Size(128, 64),
        columns: 4,
        rows: 2,
      );

      expect(source.x, 1);
      expect(source.y, 0);
      expect(source.width, 1);
      expect(source.height, 1);
    });

    test('converts a zoomed local click position to tile coordinates', () {
      final source = pathStudioTileSourceFromLocalPosition(
        localPosition: const ui.Offset(175, 72),
        displaySize: const ui.Size(256, 128),
        columns: 4,
        rows: 2,
      );

      expect(source.x, 2);
      expect(source.y, 1);
    });
  });
}

Future<Uint8List> _pngBytes({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFFFF00FF);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

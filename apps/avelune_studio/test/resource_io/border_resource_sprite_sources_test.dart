import 'dart:io';

import 'package:avelune_studio/features/resources/data/border_resource_sources.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/raster_border_fixture.dart';

void main() {
  final crop = BorderPixelRect(x: 0, y: 0, width: 32, height: 32);

  test(
    'a draft sourced from a complete PNG keeps its implicit rectangle',
    () async {
      final sources = await _prepare(sheetWidth: 32);
      expect(sources.single.frames.single.rect, isNull);
    },
  );

  test('a draft cropped from a sheet keeps its explicit rectangle', () async {
    final sources = await _prepare(sheetWidth: 64, draftCrop: crop);
    expect(sources.single.frames.single.rect, crop);
  });

  test(
    'a crop that differs from the original complete PNG is refused',
    () async {
      await expectLater(
        _prepare(sheetWidth: 64),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('a changé'),
          ),
        ),
      );
    },
  );
}

Future<List<BorderResourcePrimitive>> _prepare({
  required int sheetWidth,
  BorderPixelRect? draftCrop,
}) async {
  final temporary = await Directory.systemTemp.createTemp('border-source-');
  addTearDown(() => temporary.delete(recursive: true));
  final root = await temporary.resolveSymbolicLinks();
  const path = 'tile.png';
  final pixels = image.Image(width: sheetWidth, height: 32);
  image.fill(pixels, color: image.ColorRgb8(36, 48, 60));
  final bytes = image.encodePng(pixels);
  await File('$root/$path').writeAsBytes(bytes);
  const anchor = BorderPixelPos(x: 16, y: 16);
  final authored = const CanonicalBorderSnapshotCompiler().prepare(
    sourceElementId: 'sprite',
    anchorPx: anchor,
    frames: [
      CanonicalBorderSourceFrame(
        sourceProjectRelativePath: path,
        encodedImageBytes: bytes,
        sourceRectPx: draftCrop,
      ),
    ],
  );
  final manifest = rasterBorderProject(authored.metrics);
  return prepareExistingBorderSpriteSources(
    manifest,
    root,
    manifest.borderCatalog.records.single.draft.definition.primitives,
  );
}

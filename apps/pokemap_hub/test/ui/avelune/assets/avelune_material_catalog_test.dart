import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/assets/avelune_material_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AveluneMaterialCatalog', () {
    test('declares the complete production asset contract', () {
      expect(AveluneMaterialCatalog.backgrounds, hasLength(5));
      expect(AveluneMaterialCatalog.furniture, hasLength(6));
      expect(AveluneMaterialCatalog.consoleLayers, hasLength(4));
      expect(AveluneMaterialCatalog.cartridgeLayers, hasLength(5));
      expect(AveluneMaterialCatalog.all, hasLength(22));
      expect(
        AveluneMaterialCatalog.all.map((asset) => asset.id).toSet(),
        hasLength(AveluneMaterialCatalog.all.length),
      );
      expect(
        AveluneMaterialCatalog.all.map((asset) => asset.path),
        everyElement(allOf(startsWith('assets/avelune/'), endsWith('.webp'))),
      );
      expect(
        AveluneMaterialCatalog.background('amber').id,
        'background.amber',
      );
      expect(
        AveluneMaterialCatalog.furnitureFinish('ivory').id,
        'furniture.ivory',
      );
      expect(
        () => AveluneMaterialCatalog.background('unknown'),
        throwsArgumentError,
      );
    });

    test('every asset loads, decodes and meets its size contract', () async {
      for (final asset in AveluneMaterialCatalog.all) {
        final data = await rootBundle.load(asset.path);
        expect(data.lengthInBytes, greaterThan(0), reason: asset.id);
        final image = await _decode(data);
        expect(image.width, greaterThanOrEqualTo(asset.minimumSize.width),
            reason: '${asset.id}: width');
        expect(image.height, greaterThanOrEqualTo(asset.minimumSize.height),
            reason: '${asset.id}: height');

        if (asset.requiresTransparentCorners) {
          final pixels =
              await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          expect(pixels, isNotNull, reason: asset.id);
          final rgba = pixels!.buffer.asUint8List();
          for (final alphaIndex in <int>[
            3,
            ((image.width - 1) * 4) + 3,
            ((image.height - 1) * image.width * 4) + 3,
            ((image.height * image.width) - 1) * 4 + 3,
          ]) {
            expect(rgba[alphaIndex], 0, reason: '${asset.id}: alpha corner');
          }
        }
      }
    });

    test('all furniture finishes preserve one geometry and alpha silhouette',
        () async {
      final bounds = <_AlphaBounds>[];
      final sizes = <ui.Size>[];

      for (final asset in AveluneMaterialCatalog.furniture) {
        final image = await _decode(await rootBundle.load(asset.path));
        sizes.add(ui.Size(image.width.toDouble(), image.height.toDouble()));
        bounds.add(await _alphaBounds(image));
      }

      expect(sizes.toSet(), hasLength(1));
      expect(bounds.toSet(), hasLength(1));
    });

    test('production manifest proves source, tool and transformation',
        () async {
      final manifest = jsonDecode(
        await rootBundle.loadString(AveluneMaterialCatalog.manifestAssetPath),
      ) as Map<String, Object?>;
      final entries =
          (manifest['assets']! as List<Object?>).cast<Map<String, Object?>>();

      expect(manifest['schemaVersion'], 1);
      expect(manifest['productionUseApproved'], isTrue);
      expect(entries, hasLength(AveluneMaterialCatalog.all.length));
      expect(
        entries.map((entry) => entry['id']).toSet(),
        AveluneMaterialCatalog.all.map((asset) => asset.id).toSet(),
      );
      for (final entry in entries) {
        expect(entry['source'], isNotEmpty);
        expect(entry['tool'], isNotEmpty);
        expect(entry['transformation'], isNotEmpty);
        expect(entry['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
        final asset = AveluneMaterialCatalog.all.singleWhere(
          (candidate) => candidate.id == entry['id'],
        );
        final bytes = await rootBundle.load(asset.path);
        expect(
          sha256.convert(bytes.buffer.asUint8List()).toString(),
          entry['sha256'],
          reason: '${asset.id}: manifest digest',
        );
      }
    });
  });
}

Future<ui.Image> _decode(ByteData data) async {
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<_AlphaBounds> _alphaBounds(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (rgba[((y * image.width + x) * 4) + 3] == 0) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  return _AlphaBounds(left, top, right, bottom);
}

final class _AlphaBounds {
  const _AlphaBounds(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  @override
  bool operator ==(Object other) =>
      other is _AlphaBounds &&
      left == other.left &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

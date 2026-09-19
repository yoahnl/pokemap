import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceStressFixture fixture;
  setUp(() async => fixture = await ResourceStressFixture.create());
  tearDown(() => fixture.dispose());

  test(
    'catalogue refresh keeps unrelated decoded images and requests only demand',
    () async {
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
      );
      addTearDown(resources.dispose);
      resources.setActiveMap(fixture.lateMap);
      await resources.settled;
      final original = resources.images[fixture.lateAtlasId];
      final updated = fixture.manifest.copyWith(
        tilesets: [
          ...fixture.manifest.tilesets,
          const ProjectTilesetEntry(
            id: 'new',
            name: 'New',
            relativePath: 'assets/new.png',
          ),
        ],
      );
      await File(
        '${fixture.directory.path}/assets/new.png',
      ).writeAsBytes(await _png(32, 32, 0xff0000ff));
      await resources.updateCatalog(
        updated,
        changedRelativePaths: {'assets/new.png'},
      );
      expect(resources.tilesets, contains('new'));
      expect(resources.images[fixture.lateAtlasId], same(original));
      expect(resources.store.decoder.reads, 1);
      final brush = Object();
      resources.retain(brush, {'new'});
      await resources.settled;
      expect(resources.store.decoder.reads, 2);
      expect(resources.images['new']!.width, 32);
      resources.release(brush);
    },
  );

  test(
    'same-path pixels and aliases refresh while previous painters retain the old image',
    () async {
      final file = File('${fixture.directory.path}/assets/atelier.png');
      await file.writeAsBytes(await _png(32, 32, 0xffff0000));
      final manifest = fixture.manifest.copyWith(
        tilesets: [
          const ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'assets/atelier.png',
          ),
          const ProjectTilesetEntry(
            id: 'alias',
            name: 'Alias',
            relativePath: 'assets/atelier.png',
          ),
        ],
      );
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
      );
      addTearDown(resources.dispose);
      final painter = Object();
      resources.retain(painter, {'a', 'alias'});
      await resources.settled;
      final old = resources.images['a']!;
      expect(resources.images['alias'], same(old));
      expect(await _pixel(old), [255, 0, 0, 255]);
      await file.writeAsBytes(await _png(32, 32, 0xff0000ff));
      await resources.updateCatalog(
        manifest,
        changedRelativePaths: {'assets/atelier.png'},
      );
      await resources.settled;
      final fresh = resources.images['a']!;
      expect(fresh, isNot(same(old)));
      expect(resources.images['alias'], same(fresh));
      expect(await _pixel(fresh), [0, 0, 255, 255]);
      expect(old.debugDisposed, isFalse);
      expect(await _pixel(old), [255, 0, 0, 255]);
      expect(resources.decodedBytes, 32 * 32 * 4 * 2);
      resources.release(painter);
      expect(old.debugDisposed, isTrue);
      expect(fresh.debugDisposed, isFalse);
      expect(resources.decodedBytes, 32 * 32 * 4);
      expect(resources.store.decoder.decodes, 2);
    },
  );

  test(
    'deterministic oversize is not decoded or retried until resource changes',
    () async {
      final manifest = fixture.manifest.copyWith(
        tilesets: [
          const ProjectTilesetEntry(
            id: 'large',
            name: 'Large',
            relativePath: 'assets/large.png',
          ),
        ],
      );
      final file = File('${fixture.directory.path}/assets/large.png');
      await file.writeAsBytes(await _png(64, 64, 0xff00ff00));
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
        maximumBytes: 4096,
      );
      addTearDown(resources.dispose);
      final owner = Object();
      resources.retain(owner, {'large'});
      await resources.settled;
      expect(resources.store.decoder.decodes, 0);
      expect(resources.diagnostics.single.canRetry, isFalse);
      expect(resources.diagnostics.single.detail, contains('16384'));
      for (var index = 0; index < 3; index++) {
        resources.release(owner);
        resources.retain(owner, {'large'});
        await resources.retryResources({'large'});
      }
      expect(resources.store.decoder.reads, 1);
      await file.writeAsBytes(await _png(16, 16, 0xff00ff00));
      await resources.updateCatalog(
        manifest,
        changedRelativePaths: {'assets/large.png'},
      );
      await resources.settled;
      expect(resources.images['large']!.width, 16);
      expect(resources.diagnostics, isEmpty);
      resources.release(owner);
    },
  );

  test(
    '4096 by 5280 atlas uses existing chunks with bounded whole-decode reservation',
    () async {
      final encoded = await _png(4096, 5280, 0xff336699);
      await File(
        '${fixture.directory.path}/assets/large.png',
      ).writeAsBytes(encoded);
      final manifest = fixture.manifest.copyWith(
        tilesets: [
          const ProjectTilesetEntry(
            id: 'large',
            name: 'Large',
            relativePath: 'assets/large.png',
          ),
        ],
      );
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
      );
      addTearDown(resources.dispose);
      await resources.store.request('large');
      final image = resources.images['large']!;
      expect(image.width, 4096);
      expect(image.height, 5280);
      expect(resources.decodedBytes, 86507520);
      expect(resources.decodedBytes, greaterThan(64 * 1024 * 1024));
      expect(resources.store.decoder.decodes, 1);
      expect(
        resources.store.decoder.peakTransientBytes,
        encoded.length * 2 + 86507520 * 4,
      );
      expect(
        resources.store.peakAccountedBytes,
        lessThanOrEqualTo(resources.store.maximumWorkingBytes),
      );
      expect(await _pixel(image, const ui.Rect.fromLTWH(100, 4090, 16, 16)), [
        51,
        102,
        153,
        255,
      ]);
      expect(resources.diagnostics, isEmpty);
    },
  );
}

Future<Uint8List> _png(int width, int height, int argb) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(ui.Color(argb), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

Future<List<int>> _pixel(RuntimeTilesetImage image, [ui.Rect? source]) async {
  final recorder = ui.PictureRecorder();
  final region = source ?? const ui.Rect.fromLTWH(0, 0, 1, 1);
  image.drawImageRect(
    ui.Canvas(recorder),
    region,
    ui.Offset.zero & region.size,
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final output = await picture.toImage(
    region.width.toInt(),
    region.height.toInt(),
  );
  picture.dispose();
  final bytes = await output.toByteData();
  output.dispose();
  final pixels = bytes!.buffer.asUint8List(
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  for (var offset = 4; offset < pixels.length; offset += 4) {
    expect(pixels.sublist(offset, offset + 4), pixels.sublist(0, 4));
  }
  return pixels.sublist(0, 4);
}

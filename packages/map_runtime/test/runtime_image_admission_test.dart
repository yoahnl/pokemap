import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/border/border_runtime_asset_cache.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('direct PNG decoding fits without reserving readback and split buffers', () async {
    final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 32)));
    final budget = RuntimeResourceBudget(profile: const RuntimeResourceProfile(
      maximumResidentBytes: 4096, maximumTransientBytes: 12288));
    final image = await decodeRuntimeTilesetImage(bytes, resourceBudget: budget);
    expect(image.width, 32);
    expect(image.height, 32);
    expect(budget.residentBytes, 4096);
    image.dispose();
    expect(budget.residentBytes + budget.transientBytes + budget.activeDecodes, 0);
    budget.dispose();
  });

  test('color-key readback keeps its larger admission requirement', () async {
    final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 32)));
    final budget = RuntimeResourceBudget(profile: const RuntimeResourceProfile(
      maximumResidentBytes: 4096, maximumTransientBytes: 12288));
    await expectLater(decodeRuntimeTilesetImage(bytes, resourceBudget: budget,
      transparentColor: TilesetTransparentColor.fromHexRgb('ff00ff')),
      throwsA(isA<RuntimeResourceAdmissionException>()));
    expect(budget.residentBytes + budget.transientBytes + budget.activeDecodes, 0);
    budget.dispose();
  });

  test('vertical PNG splitting keeps its larger admission requirement', () async {
    final bytes = Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 4097)));
    const rgba = 8 * 4097 * 4;
    final budget = RuntimeResourceBudget(profile: const RuntimeResourceProfile(
      maximumResidentBytes: rgba, maximumTransientBytes: rgba * 3));
    await expectLater(decodeRuntimeTilesetImage(bytes, resourceBudget: budget),
      throwsA(isA<RuntimeResourceAdmissionException>()));
    expect(budget.residentBytes + budget.transientBytes + budget.activeDecodes, 0);
    budget.dispose();
  });

  test(
    'a cancelled prefetch does not cancel a demand joining its flight',
    () async {
      final gate = Completer<Map<String, RuntimeTilesetImage>>();
      final cache = RuntimeTilesetImageSingleFlightCache(
        loader: (paths, {transparentColorByTilesetId = const {}}) =>
            gate.future,
      );
      var current = true;
      final prefetch = cache.loadById(
        {'image': '/image.png'},
        prefetch: true,
        isCurrent: () => current,
      );
      final rejection = expectLater(
        prefetch,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      final demand = cache.loadById({'image': '/image.png'});
      current = false;
      final image = await decodeRuntimeTilesetImage(
        Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1))),
      );
      gate.complete({'image': image});
      expect((await demand)['image'], same(image));
      await rejection;
      expect(image.isDisposed, isFalse);
      cache.dispose();
      expect(image.isDisposed, isTrue);
    },
  );

  test(
    'a cancelled border prefetch keeps a shared demand image alive',
    () async {
      final gate = Completer<RuntimeTilesetImage>();
      final cache = BorderRuntimeAssetCache(
        imageLoader: (_, {transparentColor}) => gate.future,
      );
      final frame = BorderRuntimeFrameRequest(
        snapshotId: 'snapshot',
        frameIndex: 0,
        relativeAssetPath: 'image.png',
        sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
        transparentColorArgb: null,
      );
      var current = true;
      final prefetch = cache.loadFrame(
        projectRoot: '/tmp',
        frame: frame,
        prefetch: true,
        isCurrent: () => current,
      );
      final rejection = expectLater(
        prefetch,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      final demand = cache.loadFrame(projectRoot: '/tmp', frame: frame);
      current = false;
      final image = await decodeRuntimeTilesetImage(
        Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1))),
      );
      gate.complete(image);
      expect(await demand, same(image));
      await rejection;
      expect(image.isDisposed, isFalse);
      await cache.dispose();
      expect(image.isDisposed, isTrue);
    },
  );

  test(
    'throwing progress drains the batch and releases successful images',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-admission-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      final budget = RuntimeResourceBudget();
      await expectLater(
        loadTilesetImagesById(
          {'a': file.path, 'b': file.path},
          resourceBudget: budget,
          onProgress: (_, _) => throw StateError('progress failure'),
        ),
        throwsStateError,
      );
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
      budget.dispose();
    },
  );

  test('atlas and borders share one resident admission boundary', () async {
    final directory = await Directory.systemTemp.createTemp('image-admission-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/image.png');
    await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 256),
    );
    final atlas = RuntimeTilesetImageSingleFlightCache(
      loader: loadTilesetImagesById,
      resourceBudget: budget,
      identity: 'game@1',
    );
    final border = BorderRuntimeAssetCache(
      resourceBudget: budget,
      identity: 'game@1',
    );
    addTearDown(() async {
      atlas.dispose();
      await border.dispose();
      budget.dispose();
    });
    await atlas.loadById({'image': file.path});
    expect(budget.residentBytes, 256);
    final frame = BorderRuntimeFrameRequest(
      snapshotId: 'snapshot',
      frameIndex: 0,
      relativeAssetPath: 'image.png',
      sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 8, height: 8),
      durationMs: 100,
      transparentColorArgb: null,
    );
    await expectLater(
      border.loadFrame(projectRoot: directory.path, frame: frame),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(budget.residentBytes, 256);
    atlas.trimToBudget(maxBytes: 0, retainedImages: const []);
    await border.loadFrame(projectRoot: directory.path, frame: frame);
    expect(budget.residentBytes, 256);
    await border.dispose();
    expect(budget.residentBytes, 0);
  });

  test(
    'decode failure releases both resident and transient reservations',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-admission-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      final budget = RuntimeResourceBudget();
      await expectLater(
        loadTilesetImageFromFilePath(
          file.path,
          resourceBudget: budget,
          decoder: (_) async => throw StateError('decoder failure'),
        ),
        throwsStateError,
      );
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
      budget.dispose();
    },
  );

  test(
    'a cancelled decode disposes late pixels and releases admission',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-admission-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      final budget = RuntimeResourceBudget();
      var current = true;
      ui.Image? late;
      await expectLater(
        loadTilesetImageFromFilePath(
          file.path,
          resourceBudget: budget,
          isCurrent: () => current,
          decoder: (bytes) async {
            final codec = await ui.instantiateImageCodec(bytes);
            late = await decodeFirstFrameAndDispose(codec);
            current = false;
            return late!;
          },
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(late!.debugDisposed, isTrue);
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
      budget.dispose();
    },
  );

  test('oversized pixels are refused before the image codec', () async {
    final directory = await Directory.systemTemp.createTemp('image-admission-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/image.png');
    await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumResidentBytes: 255),
    );
    var decoded = 0;
    await expectLater(
      loadTilesetImageFromFilePath(
        file.path,
        resourceBudget: budget,
        decoder: (bytes) async {
          decoded++;
          final codec = await ui.instantiateImageCodec(bytes);
          return decodeFirstFrameAndDispose(codec);
        },
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(decoded, 0);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
    budget.dispose();
  });

  test(
    'exact admission is released when the returned image is disposed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-admission-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(maximumResidentBytes: 256),
      );
      final image = await loadTilesetImageFromFilePath(
        file.path,
        resourceBudget: budget,
      );
      expect(budget.residentBytes, 256);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
      image.dispose();
      image.dispose();
      expect(budget.residentBytes, 0);
      budget.dispose();
    },
  );

  test('batch custom loaders also have bounded active work', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 2),
    );
    var active = 0;
    var peak = 0;
    final images = await loadTilesetImagesById(
      {for (var index = 0; index < 7; index++) '$index': '$index'},
      resourceBudget: budget,
      loader: (path, {transparentColor}) async {
        active++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 2));
        active--;
        return decodeRuntimeTilesetImage(
          Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1))),
          resourceBudget: budget,
        );
      },
    );
    expect(peak, 2);
    for (final image in images.values) {
      image.dispose();
    }
    expect(budget.residentBytes, 0);
    budget.dispose();
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pokemap-image-cache-');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('reports missing files without pinning a null cache entry', () async {
    final cache = _immediateCache(tempDir);
    final missingPath = '${tempDir.path}/missing.png';

    final first = await cache.load(missingPath);
    final second = await cache.load(missingPath);

    expect(first.failure?.kind, EditorImageFailureKind.missingFile);
    expect(second.failure?.kind, EditorImageFailureKind.missingFile);
    expect(cache.diagnostics.entries, 0);
    expect(cache.diagnostics.missingFiles, 2);
    expect(cache.diagnostics.misses, 2);

    cache.dispose();
  });

  test('reuses decoded pixels through distinct consumer image handles',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final first = await cache.load(file.path);
    final second = await cache.load(file.path);

    expect(first.image, isNotNull);
    expect(identical(second.image, first.image), isFalse);
    expect(second.image!.isCloneOf(first.image!), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.misses, 1);
    expect(cache.diagnostics.hits, 1);

    first.dispose();
    expect(second.image!.debugDisposed, isFalse);
    final secondConsumerClone = second.image!.clone();
    secondConsumerClone.dispose();
    second.dispose();
    cache.dispose();
  });

  test('canonical path aliases share one decoded image', () async {
    final file = File('${tempDir.path}/tiles.png');
    final alias = Link('${tempDir.path}/tiles-alias.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    await alias.create(file.path);
    final cache = _immediateCache(tempDir);

    final first = await cache.load(file.path);
    final second = await cache.load(alias.path);

    expect(identical(second.image, first.image), isFalse);
    expect(second.image!.isCloneOf(first.image!), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.hits, 1);

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  test('invalidates a same-path image when the file fingerprint changes',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final first = await cache.load(file.path);
    expect(first.image?.width, 1);

    await file.writeAsBytes(_png(width: 2, height: 1), flush: true);
    await file.setLastModified(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    final second = await cache.load(file.path);
    await Future<void>.delayed(Duration.zero);

    expect(second.image?.width, 2);
    expect(identical(second.image, first.image), isFalse);
    expect(cache.diagnostics.invalidations, 1);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.disposedImages, 1);
    expect(first.image!.debugDisposed, isFalse);
    final retainedConsumerClone = first.image!.clone();
    retainedConsumerClone.dispose();

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  testWidgets(
      'default retirement keeps superseded images through the handoff frame',
      (tester) async {
    final file = File('${tempDir.path}/tiles.png');
    final cache = EditorImageCache(sessionKey: tempDir.path);
    late EditorImageLoadResult first;
    late EditorImageLoadResult second;
    await tester.runAsync(() async {
      await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
      first = await cache.load(file.path);
      await file.writeAsBytes(_png(width: 2, height: 1), flush: true);
      await file.setLastModified(
        DateTime.now().add(const Duration(seconds: 2)),
      );
      second = await cache.load(file.path);
    });

    expect(first.image?.width, 1);
    expect(second.image?.width, 2);
    expect(cache.diagnostics.disposedImages, 0);

    await tester.pump();
    expect(cache.diagnostics.disposedImages, 1);
    expect(first.image!.debugDisposed, isFalse);

    cache.dispose();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(cache.diagnostics.disposedImages, 2);
    expect(first.image!.debugDisposed, isFalse);
    expect(second.image!.debugDisposed, isFalse);

    first.dispose();
    second.dispose();
  });

  test('consumer release is idempotent and independent from cache disposal',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final result = await cache.load(file.path);

    cache.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(cache.diagnostics.disposedImages, 1);
    expect(result.image!.debugDisposed, isFalse);
    expect(result.image!.debugGetOpenHandleStackTraces(), hasLength(1));

    result.release();
    result.dispose();

    expect(result.image!.debugDisposed, isTrue);
    expect(result.image!.debugGetOpenHandleStackTraces(), isEmpty);
  });

  test('keeps decode variants isolated in the cache key', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final original = await cache.load(file.path);
    final transformed = await cache.load(
      file.path,
      variantKey: 'transparent:ff00ff',
      transformBytes: (_) => _png(width: 2, height: 1),
    );
    final transformedAgain = await cache.load(
      file.path,
      variantKey: 'transparent:ff00ff',
      transformBytes: (_) => _png(width: 3, height: 1),
    );

    expect(original.image?.width, 1);
    expect(transformed.image?.width, 2);
    expect(identical(transformedAgain.image, transformed.image), isFalse);
    expect(
      transformedAgain.image!.isCloneOf(transformed.image!),
      isTrue,
    );
    expect(cache.diagnostics.entries, 2);
    expect(cache.diagnostics.hits, 1);

    original.dispose();
    transformed.dispose();
    transformedAgain.dispose();
    cache.dispose();
  });

  test('returns a typed decode diagnostic and recovers after replacement',
      () async {
    final file = File('${tempDir.path}/broken.png');
    await file.writeAsBytes(<int>[1, 2, 3], flush: true);
    final cache = _immediateCache(tempDir);

    final broken = await cache.load(file.path);
    expect(broken.failure?.kind, EditorImageFailureKind.decodeFailed);
    expect(broken.failure?.path, endsWith('broken.png'));
    expect(cache.diagnostics.decodeFailures, 1);
    expect(cache.diagnostics.entries, 0);

    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    await file.setLastModified(
      DateTime.now().add(const Duration(seconds: 2)),
    );
    final recovered = await cache.load(file.path);

    expect(recovered.image, isNotNull);
    expect(recovered.failure, isNull);

    recovered.dispose();
    cache.dispose();
  });

  test('bulk loading preserves typed failures for the canvas', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final results = await cache.loadMany({
      'ground': file.path,
      'missing': '${tempDir.path}/missing.png',
    });

    expect(results['ground']?.image, isNotNull);
    expect(
      results['missing']?.failure?.kind,
      EditorImageFailureKind.missingFile,
    );

    for (final result in results.values) {
      result.dispose();
    }
    cache.dispose();
  });

  test('bulk loading gives each consumer id its own image handle', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final results = await cache.loadMany({
      'ground': file.path,
      'details': file.path,
    });
    final ground = results['ground']!;
    final details = results['details']!;

    expect(identical(ground.image, details.image), isFalse);
    expect(ground.image!.isCloneOf(details.image!), isTrue);

    ground.dispose();
    details.dispose();
    cache.dispose();
  });

  test('dispose is idempotent and owns decoded images', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    final consumer = await cache.load(file.path);

    cache.dispose();
    cache.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(cache.diagnostics.isDisposed, isTrue);
    expect(cache.diagnostics.disposedImages, 1);
    expect(consumer.image!.debugDisposed, isFalse);
    final afterDispose = await cache.load(file.path);
    expect(afterDispose.failure?.kind, EditorImageFailureKind.cacheDisposed);

    consumer.dispose();
  });

  test('dispose owns an image that is still decoding', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final transformGate = Completer<Uint8List>();
    final cache = _immediateCache(tempDir);
    final pending = cache.load(
      file.path,
      variantKey: 'pending',
      transformBytes: (_) => transformGate.future,
    );
    await Future<void>.delayed(Duration.zero);

    cache.dispose();
    transformGate.complete(_png(width: 1, height: 1));
    final result = await pending;
    await Future<void>.delayed(Duration.zero);

    expect(result.failure?.kind, EditorImageFailureKind.cacheDisposed);
    expect(cache.diagnostics.disposedImages, 1);
  });

  test('evicts the least-recently-used master by decoded byte weight',
      () async {
    final firstFile = File('${tempDir.path}/first.png');
    final secondFile = File('${tempDir.path}/second.png');
    final thirdFile = File('${tempDir.path}/third.png');
    for (final file in <File>[firstFile, secondFile, thirdFile]) {
      await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    }
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 8,
    );
    final decodeCounts = <String, int>{};

    Future<EditorImageLoadResult> loadTracked(File file) {
      return cache.load(
        file.path,
        variantKey: 'tracked',
        transformBytes: (bytes) {
          decodeCounts.update(file.path, (count) => count + 1,
              ifAbsent: () => 1);
          return bytes;
        },
      );
    }

    final first = await loadTracked(firstFile);
    final second = await loadTracked(secondFile);
    final touchedFirst = await loadTracked(firstFile);
    final third = await loadTracked(thirdFile);

    expect(cache.diagnostics.maximumDecodedBytes, 8);
    expect(cache.diagnostics.residentDecodedBytes, 8);
    expect(cache.diagnostics.peakDecodedBytes, greaterThanOrEqualTo(8));
    expect(cache.diagnostics.evictions, 1);
    expect(cache.diagnostics.entries, 2);
    expect(decodeCounts[firstFile.path], 1);
    expect(decodeCounts[secondFile.path], 1);
    expect(decodeCounts[thirdFile.path], 1);

    final reloadedSecond = await loadTracked(secondFile);

    expect(decodeCounts[secondFile.path], 2);
    expect(cache.diagnostics.residentDecodedBytes, lessThanOrEqualTo(8));

    first.dispose();
    second.dispose();
    touchedFirst.dispose();
    third.dispose();
    reloadedSecond.dispose();
    cache.dispose();
  });

  test('keeps an acquired lease usable after its master is evicted', () async {
    final firstFile = File('${tempDir.path}/leased.png');
    final secondFile = File('${tempDir.path}/replacement.png');
    await firstFile.writeAsBytes(_png(width: 1, height: 1), flush: true);
    await secondFile.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 4,
    );

    final leased = await cache.load(firstFile.path);
    final replacement = await cache.load(secondFile.path);

    expect(cache.diagnostics.evictions, 1);
    expect(cache.diagnostics.residentDecodedBytes, 4);
    expect(leased.image!.debugDisposed, isFalse);
    final proofOfLife = leased.image!.clone();
    expect(proofOfLife.width, 1);
    proofOfLife.dispose();

    leased.dispose();
    replacement.dispose();
    cache.dispose();
  });

  test('serves an oversized image without retaining its decoded master',
      () async {
    final file = File('${tempDir.path}/oversized.png');
    await file.writeAsBytes(_png(width: 3, height: 3), flush: true);
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 16,
    );
    var decodeCount = 0;

    Future<EditorImageLoadResult> loadOversized() {
      return cache.load(
        file.path,
        variantKey: 'oversized',
        transformBytes: (bytes) {
          decodeCount += 1;
          return bytes;
        },
      );
    }

    final first = await loadOversized();

    expect(first.image, isNotNull);
    expect(cache.diagnostics.entries, 0);
    expect(cache.diagnostics.residentDecodedBytes, 0);

    final second = await loadOversized();

    expect(second.image, isNotNull);
    expect(decodeCount, 2);
    expect(cache.diagnostics.residentDecodedBytes, 0);

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  test('shares one in-flight decode across concurrent loads', () async {
    final file = File('${tempDir.path}/concurrent.png');
    await file.writeAsBytes(_png(width: 2, height: 2), flush: true);
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 64,
    );
    final transformStarted = Completer<void>();
    final transformGate = Completer<Uint8List>();
    var transformCount = 0;

    FutureOr<Uint8List> gatedTransform(Uint8List bytes) {
      transformCount += 1;
      if (!transformStarted.isCompleted) {
        transformStarted.complete();
      }
      return transformGate.future;
    }

    final firstFuture = cache.load(
      file.path,
      variantKey: 'concurrent',
      transformBytes: gatedTransform,
    );
    final secondFuture = cache.load(
      file.path,
      variantKey: 'concurrent',
      transformBytes: gatedTransform,
    );
    await transformStarted.future.timeout(const Duration(seconds: 2));

    expect(transformCount, 1);
    expect(cache.diagnostics.inFlightLoads, 1);

    transformGate.complete(_png(width: 2, height: 2));
    final results = await Future.wait(<Future<EditorImageLoadResult>>[
      firstFuture,
      secondFuture,
    ]);

    expect(cache.diagnostics.inFlightLoads, 0);
    expect(cache.diagnostics.residentDecodedBytes, 16);
    expect(identical(results.first.image, results.last.image), isFalse);
    expect(results.first.image!.isCloneOf(results.last.image!), isTrue);

    for (final result in results) {
      result.dispose();
    }
    cache.dispose();
  });

  test('shares one source decode and returns distinct crop leases', () async {
    final file = File('${tempDir.path}/crop-source.png');
    await file.writeAsBytes(_png(width: 2, height: 2), flush: true);
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 64,
    );
    final transformStarted = Completer<void>();
    final transformGate = Completer<Uint8List>();
    late Uint8List sourceBytes;
    var sourceTransformCount = 0;

    FutureOr<Uint8List> gatedTransform(Uint8List bytes) {
      sourceBytes = bytes;
      sourceTransformCount += 1;
      if (!transformStarted.isCompleted) {
        transformStarted.complete();
      }
      return transformGate.future;
    }

    final firstFuture = cache.loadCrop(
      file.path,
      sourceRect: const ui.Rect.fromLTWH(0, 0, 1, 1),
      variantKey: 'crop:top-left',
      transformBytes: gatedTransform,
    );
    final secondFuture = cache.loadCrop(
      file.path,
      sourceRect: const ui.Rect.fromLTWH(0, 0, 1, 1),
      variantKey: 'crop:top-left',
      transformBytes: gatedTransform,
    );
    await transformStarted.future.timeout(const Duration(seconds: 2));

    expect(sourceTransformCount, 1);

    transformGate.complete(sourceBytes);
    final results = await Future.wait(<Future<EditorImageLoadResult>>[
      firstFuture,
      secondFuture,
    ]);

    expect(results.first.image?.width, 1);
    expect(results.first.image?.height, 1);
    expect(identical(results.first.image, results.last.image), isFalse);
    expect(results.first.image!.isCloneOf(results.last.image!), isTrue);
    expect(cache.diagnostics.entries, 2);
    expect(cache.diagnostics.residentDecodedBytes, 20);

    for (final result in results) {
      result.dispose();
    }
    cache.dispose();
  });

  test('distinct crops reuse the same decoded source variant', () async {
    final file = File('${tempDir.path}/distinct-crops-source.png');
    await file.writeAsBytes(_png(width: 2, height: 2), flush: true);
    final cache = _boundedImmediateCache(
      tempDir,
      maximumDecodedBytes: 64,
    );
    var sourceTransformCount = 0;

    Uint8List countSourceDecode(Uint8List bytes) {
      sourceTransformCount += 1;
      return bytes;
    }

    final first = await cache.loadCrop(
      file.path,
      sourceRect: const ui.Rect.fromLTWH(0, 0, 1, 1),
      variantKey: 'crop:top-left',
      sourceVariantKey: 'shared-tileset',
      transformBytes: countSourceDecode,
    );
    final second = await cache.loadCrop(
      file.path,
      sourceRect: const ui.Rect.fromLTWH(1, 1, 1, 1),
      variantKey: 'crop:bottom-right',
      sourceVariantKey: 'shared-tileset',
      transformBytes: countSourceDecode,
    );

    expect(sourceTransformCount, 1);
    expect(first.image?.width, 1);
    expect(second.image?.width, 1);
    expect(cache.diagnostics.entries, 3);

    first.dispose();
    second.dispose();
    cache.dispose();
  });

  test('provider isolates and disposes project sessions', () async {
    final container = ProviderContainer();
    final first = container.read(editorImageCacheProvider('/project/a'));
    final second = container.read(editorImageCacheProvider('/project/b'));

    expect(identical(first, second), isFalse);

    container.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(first.diagnostics.isDisposed, isTrue);
    expect(second.diagnostics.isDisposed, isTrue);
  });

  test('autoDispose releases a cache when its provider listener closes',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      editorImageCacheProvider('/project/a'),
      (_, __) {},
    );
    final cache = container.read(editorImageCacheProvider('/project/a'));

    subscription.close();
    await container.pump();

    expect(cache.diagnostics.isDisposed, isTrue);
  });

  test('invalidating a provider replaces and disposes its project owner',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      editorImageCacheProvider('/project/a'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final first = container.read(editorImageCacheProvider('/project/a'));

    container.invalidate(editorImageCacheProvider('/project/a'));
    final second = container.read(editorImageCacheProvider('/project/a'));
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, second), isFalse);
    expect(first.diagnostics.isDisposed, isTrue);
    expect(second.diagnostics.isDisposed, isFalse);
  });
}

Uint8List _png({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}

EditorImageCache _immediateCache(Directory directory) {
  return EditorImageCache(
    sessionKey: directory.path,
    retirementScheduler: (disposeImage) => disposeImage(),
  );
}

EditorImageCache _boundedImmediateCache(
  Directory directory, {
  required int maximumDecodedBytes,
}) {
  return EditorImageCache(
    sessionKey: directory.path,
    maximumDecodedBytes: maximumDecodedBytes,
    retirementScheduler: (disposeImage) => disposeImage(),
  );
}

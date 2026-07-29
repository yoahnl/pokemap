import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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

  test('reuses a decoded image while its file fingerprint is unchanged',
      () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);

    final first = await cache.load(file.path);
    final second = await cache.load(file.path);

    expect(first.image, isNotNull);
    expect(identical(second.image, first.image), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.misses, 1);
    expect(cache.diagnostics.hits, 1);

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

    expect(identical(second.image, first.image), isTrue);
    expect(cache.diagnostics.entries, 1);
    expect(cache.diagnostics.hits, 1);

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

    cache.dispose();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(cache.diagnostics.disposedImages, 2);
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
    expect(identical(transformedAgain.image, transformed.image), isTrue);
    expect(cache.diagnostics.entries, 2);
    expect(cache.diagnostics.hits, 1);

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

    cache.dispose();
  });

  test('dispose is idempotent and owns decoded images', () async {
    final file = File('${tempDir.path}/tiles.png');
    await file.writeAsBytes(_png(width: 1, height: 1), flush: true);
    final cache = _immediateCache(tempDir);
    await cache.load(file.path);

    cache.dispose();
    cache.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(cache.diagnostics.isDisposed, isTrue);
    expect(cache.diagnostics.disposedImages, 1);
    final afterDispose = await cache.load(file.path);
    expect(afterDispose.failure?.kind, EditorImageFailureKind.cacheDisposed);
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

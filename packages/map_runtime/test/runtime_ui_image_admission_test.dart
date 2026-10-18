import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_ui_image.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List png() =>
      Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

  RuntimeResourceBudget budget(int resident) => RuntimeResourceBudget(
    profile: RuntimeResourceProfile(
      maximumResidentBytes: resident,
      maximumTransientBytes: 4096,
      maximumEncodedBytes: 4096,
      maximumConcurrentDecodes: 1,
    ),
  );

  test('UI lease counts retained bytes and releases once', () async {
    final bytes = png();
    final resources = budget(64 + bytes.length);
    final lease = await decodeRuntimeUiImage(
      bytes,
      resourceBudget: resources,
      retainedEncodedBytes: bytes.length,
    );
    expect(resources.residentBytes, 64 + bytes.length);
    expect(resources.transientBytes, 0);
    expect(resources.activeDecodes, 0);
    lease.dispose();
    lease.dispose();
    expect(lease.image.debugDisposed, isTrue);
    expect(resources.residentBytes, 0);
  });

  test('UI admission rejects pixels before calling the decoder', () async {
    final resources = budget(63);
    var decoderCalls = 0;
    await expectLater(
      decodeRuntimeUiImage(
        png(),
        resourceBudget: resources,
        decoder: (_) async {
          decoderCalls++;
          throw StateError('must not decode');
        },
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(decoderCalls, 0);
    expect(resources.residentBytes, 0);
    expect(resources.transientBytes, 0);
    expect(resources.activeDecodes, 0);
  });

  test('UI cancellation after a decode closes the late image', () async {
    final resources = budget(64);
    final decoded = Completer<ui.Image>();
    final entered = Completer<void>();
    var current = true;
    final loading = decodeRuntimeUiImage(
      png(),
      resourceBudget: resources,
      isCurrent: () => current,
      decoder: (_) {
        entered.complete();
        return decoded.future;
      },
    );
    final rejected = expectLater(
      loading,
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    await entered.future;
    final codec = await ui.instantiateImageCodec(png());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    current = false;
    decoded.complete(image);
    await rejected;
    expect(image.debugDisposed, isTrue);
    expect(resources.residentBytes, 0);
    expect(resources.transientBytes, 0);
  });

  test(
    'owned cache evicts unused images while preserving its active scope',
    () async {
      final resources = budget(128);
      final cache = RuntimeOwnedImageCache(
        loadLease: (_) =>
            decodeRuntimeUiImage(png(), resourceBudget: resources),
      );
      final unused = await cache.load('unused');
      final scope = cache.beginScope();
      final active = await cache.load('active');
      final next = await cache.load('next');
      expect(unused.debugDisposed, isTrue);
      expect(active.debugDisposed, isFalse);
      expect(next.debugDisposed, isFalse);
      expect(resources.residentBytes, 128);
      cache.endScope(scope);
      expect(active.debugDisposed, isTrue);
      expect(next.debugDisposed, isTrue);
      expect(resources.residentBytes, 0);
      cache.dispose();
    },
  );

  test('owned cache closes a lease that finishes after disposal', () async {
    final resources = budget(64);
    final gate = Completer<RuntimeUiImageLease>();
    final cache = RuntimeOwnedImageCache(loadLease: (_) => gate.future);
    final loading = cache.load('late');
    final rejected = expectLater(
      loading,
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final lease = await decodeRuntimeUiImage(png(), resourceBudget: resources);
    cache.dispose();
    gate.complete(lease);
    await rejected;
    expect(lease.image.debugDisposed, isTrue);
    expect(resources.residentBytes, 0);
  });

  test(
    'battle visual readback releases its admitted clone and transient bytes',
    () async {
      final directory = await Directory.systemTemp.createTemp('l5-ui-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(png());
      final resources = budget(128);
      final cache = BattleVisualAssetCache(resourceBudget: resources);
      final scope = cache.beginScope();
      final image = await cache.loadImage(file.path);
      expect(resources.residentBytes, 64);
      final rect = await cache.loadOpaqueSourceRect(file.path, image: image);
      expect(rect, const ui.Rect.fromLTWH(0, 0, 4, 4));
      expect(resources.residentBytes, 64);
      expect(resources.transientBytes, 0);
      expect(resources.activeDecodes, 0);
      cache.endScope(scope);
      expect(image.debugDisposed, isTrue);
      expect(resources.residentBytes, 0);
      cache.dispose();
    },
  );

  test('ending an image scope closes a lease that completes later', () async {
    final resources = budget(64);
    final gate = Completer<RuntimeUiImageLease>();
    final cache = RuntimeOwnedImageCache(loadLease: (_) => gate.future);
    final scope = cache.beginScope();
    final loading = cache.load('late');
    final rejected = expectLater(
      loading,
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final lease = await decodeRuntimeUiImage(png(), resourceBudget: resources);
    cache.endScope(scope);
    gate.complete(lease);
    await rejected;
    expect(lease.image.debugDisposed, isTrue);
    expect(resources.residentBytes, 0);
    cache.dispose();
  });

  test(
    'a new image scope can adopt the pending image of a retired scope',
    () async {
      final resources = budget(64);
      final gate = Completer<RuntimeUiImageLease>();
      final cache = RuntimeOwnedImageCache(loadLease: (_) => gate.future);
      final firstScope = cache.beginScope();
      final first = cache.load('image');
      cache.endScope(firstScope);
      final nextScope = cache.beginScope();
      final second = cache.load('image');
      final lease = await decodeRuntimeUiImage(
        png(),
        resourceBudget: resources,
      );
      gate.complete(lease);
      expect(identical(await first, await second), isTrue);
      expect(lease.image.debugDisposed, isFalse);
      expect(resources.residentBytes, 64);
      cache.endScope(nextScope);
      expect(resources.residentBytes, 0);
      cache.dispose();
    },
  );

  test('standalone battle caches have independent resource sessions', () {
    final first = BattleFxBundleCache();
    final second = BattleFxBundleCache();
    expect(identical(first.resourceBudget, second.resourceBudget), isFalse);
    first.dispose();
    expect(first.resourceBudget.isDisposed, isTrue);
    expect(second.resourceBudget.isDisposed, isFalse);
    second.dispose();
  });

  test(
    'default battle FX decoding uses and releases its shared budget',
    () async {
      final bytes = png();
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (_) async => ByteData.sublistView(bytes),
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        ),
      );
      final resources = budget(64);
      final cache = BattleFxBundleCache(resourceBudget: resources);
      final scope = cache.beginScope();
      final image = await cache.loadImage('aerial_ace');
      expect(resources.residentBytes, 64);
      expect(identical(await cache.loadImage('aerial_ace'), image), isTrue);
      cache.endScope(scope);
      expect(image.debugDisposed, isTrue);
      expect(resources.residentBytes, 0);
      cache.dispose();
    },
  );
}

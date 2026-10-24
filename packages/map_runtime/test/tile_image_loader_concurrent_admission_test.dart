import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('queued PNG cancellation releases all reservations', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final held = await budget.acquire(
      transientBytes: budget.profile.maximumTransientBytes,
    );
    var current = true;
    final failure = expectLater(
      decodeRuntimeTilesetImage(
        bytes,
        resourceBudget: budget,
        isCurrent: () => current,
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(budget.pendingDecodes, 1);
    current = false;
    held.release();
    await failure;
    expect(budget.pendingDecodes, 0);
    expect(
      budget.residentBytes + budget.transientBytes + budget.activeDecodes,
      0,
    );
  });

  test('JPEG keeps its existing strict decode path', () async {
    final directory = await Directory.systemTemp.createTemp('strict-jpeg-');
    addTearDown(() => directory.delete(recursive: true));
    final file = await File('${directory.path}/image.jpg')
        .writeAsBytes(img.encodeJpg(img.Image(width: 32, height: 32)));
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final image = await loadTilesetImageFromFilePath(
      file.path,
      resourceBudget: budget,
    );
    expect(image.width, 32);
    expect(image.height, 32);
    image.dispose();
    expect(
      budget.residentBytes + budget.transientBytes + budget.activeDecodes,
      0,
    );
  });

  test('a PNG whose dimensions change while queued is refused without leaking admission', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final held = await budget.acquire(
      transientBytes: budget.profile.maximumTransientBytes,
    );
    final decoding = decodeRuntimeTilesetImage(bytes, resourceBudget: budget);
    final failure = expectLater(
      decoding,
      throwsA(
        isA<RuntimeResourceAdmissionException>().having(
          (error) => error.reason,
          'reason',
          'image_dimensions_changed',
        ),
      ),
    );
    expect(budget.pendingDecodes, 1);
    ByteData.sublistView(bytes).setUint32(16, 16);
    held.release();
    await failure;
    expect(
      budget.residentBytes + budget.transientBytes + budget.activeDecodes,
      0,
    );
  });

  test('zero PNG dimensions are refused before allocation', () async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    ByteData.sublistView(bytes).setUint32(16, 0);
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
  });

  test('large PNGs queue within the unchanged 64 MiB profile', () async {
    final directory = await Directory.systemTemp.createTemp(
      'large-png-admission-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final large = Uint8List.fromList(
      img.encodePng(img.Image(width: 256, height: 16192)),
    );
    final small = Uint8List.fromList(
      img.encodePng(img.Image(width: 256, height: 16192)),
    );
    final firstFile = await File('${directory.path}/large.png')
        .writeAsBytes(large);
    final secondFile = await File('${directory.path}/small.png')
        .writeAsBytes(small);
    const profile = RuntimeResourceProfile();
    const resident = 256 * 16192 * 4 * 2;
    final firstTransient = runtimeTilesetImageAllocation(
      encodedLength: large.length,
      width: 256,
      height: 16192,
    ).transientBytes;
    final secondTransient = runtimeTilesetImageAllocation(
      encodedLength: small.length,
      width: 256,
      height: 16192,
    ).transientBytes;
    expect(resident, lessThan(profile.maximumResidentBytes));
    expect(firstTransient, lessThan(profile.maximumTransientBytes));
    expect(secondTransient, lessThan(profile.maximumTransientBytes));
    expect(
      firstTransient + secondTransient,
      greaterThan(profile.maximumTransientBytes),
    );
    final budget = RuntimeResourceBudget(profile: profile);
    addTearDown(budget.dispose);
    final held = await budget.acquire(
      residentBytes: resident ~/ 2,
      transientBytes: firstTransient,
    );
    final images = <RuntimeTilesetImage>[];
    addTearDown(() {
      held.release();
      for (final image in images) {
        image.dispose();
      }
    });
    Object? failure;
    var finished = false;
    final second =
        loadTilesetImageFromFilePath(
          secondFile.path,
          resourceBudget: budget,
        ).then<void>(
          (image) {
            images.add(image);
            finished = true;
          },
          onError: (Object error) {
            failure = error;
            finished = true;
          },
        );
    while (budget.pendingDecodes == 0 && !finished) {
      await Future<void>.delayed(Duration.zero);
    }
    final pending = budget.pendingDecodes;
    held.release();
    await second;
    images.add(
      await loadTilesetImageFromFilePath(
        firstFile.path,
        resourceBudget: budget,
      ),
    );
    expect(failure, isNull);
    expect(pending, 1);
    expect(budget.residentBytes, resident);
    expect(budget.transientBytes, 0);
    for (final image in images) {
      image.dispose();
    }
    expect(
      budget.residentBytes + budget.transientBytes + budget.activeDecodes,
      0,
    );
  });

  test(
    'individually admitted PNGs queue under combined transient pressure',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 32, height: 32)),
      );
      final directory = await Directory.systemTemp.createTemp(
        'concurrent-png-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = await File('${directory.path}/atlas.png')
          .writeAsBytes(bytes);
      const rgba = 32 * 32 * 4;
      final required = bytes.length * 2 + rgba * 2;
      final budget = RuntimeResourceBudget(
        profile: RuntimeResourceProfile(
          maximumResidentBytes: rgba * 2,
          maximumTransientBytes: required + bytes.length * 2,
          maximumConcurrentDecodes: 2,
        ),
      );
      addTearDown(budget.dispose);
      final firstStarted = Completer<void>();
      final release = Completer<void>();
      var decodes = 0;
      Future<ui.Image> decoder(Uint8List bytes) async {
        decodes++;
        if (decodes == 1) {
          firstStarted.complete();
          await release.future;
        }
        return decodeFirstFrameAndDispose(
          await ui.instantiateImageCodec(bytes),
        );
      }

      final images = <RuntimeTilesetImage>[];
      addTearDown(() {
        for (final image in images) {
          image.dispose();
        }
      });
      final first = loadTilesetImageFromFilePath(
        file.path,
        resourceBudget: budget,
        decoder: decoder,
      );
      await firstStarted.future;
      Object? failure;
      var secondFinished = false;
      final second =
          loadTilesetImageFromFilePath(
            file.path,
            resourceBudget: budget,
            decoder: decoder,
          ).then<void>(
            (image) {
              images.add(image);
              secondFinished = true;
            },
            onError: (Object error) {
              failure = error;
              secondFinished = true;
            },
          );
      while (budget.pendingDecodes == 0 && !secondFinished) {
        await Future<void>.delayed(Duration.zero);
      }
      final pending = budget.pendingDecodes;
      final decodesBeforeRelease = decodes;
      release.complete();
      images.add(await first);
      await second;
      expect(failure, isNull);
      expect(pending, 1);
      expect(decodesBeforeRelease, 1);
      expect(budget.residentBytes, rgba * 2);
      expect(budget.transientBytes, 0);
      for (final image in images) {
        image.dispose();
      }
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
    },
  );

  test(
    'PNG admission preserves two simultaneous decodes when both fit',
    () async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 32, height: 32)),
      );
      final directory = await Directory.systemTemp.createTemp('parallel-png-');
      addTearDown(() => directory.delete(recursive: true));
      final file = await File('${directory.path}/atlas.png')
          .writeAsBytes(bytes);
      const rgba = 32 * 32 * 4;
      final required = bytes.length * 2 + rgba * 2;
      final budget = RuntimeResourceBudget(
        profile: RuntimeResourceProfile(
          maximumResidentBytes: rgba * 2,
          maximumTransientBytes: required * 2,
          maximumConcurrentDecodes: 2,
        ),
      );
      addTearDown(budget.dispose);
      final bothStarted = Completer<void>();
      final release = Completer<void>();
      var active = 0;
      Future<ui.Image> decoder(Uint8List bytes) async {
        if (++active == 2) bothStarted.complete();
        await release.future;
        return decodeFirstFrameAndDispose(
          await ui.instantiateImageCodec(bytes),
        );
      }

      final pending = [
        for (var i = 0; i < 2; i++)
          loadTilesetImageFromFilePath(
            file.path,
            resourceBudget: budget,
            decoder: decoder,
          ),
      ];
      await bothStarted.future;
      expect(budget.activeDecodes, 2);
      expect(budget.transientBytes, required * 2);
      release.complete();
      final images = await Future.wait(pending);
      for (final image in images) {
        image.dispose();
      }
      expect(
        budget.residentBytes + budget.transientBytes + budget.activeDecodes,
        0,
      );
    },
  );
}

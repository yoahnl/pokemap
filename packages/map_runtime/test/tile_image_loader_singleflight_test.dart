import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

Future<RuntimeTilesetImage> _fakeRuntimeTilesetImage(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(4, 4);
    final runtimeImage = RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: const <RuntimeTilesetChunk>[
        RuntimeTilesetChunk(top: 0, height: 4, width: 4),
      ],
      width: 4,
      height: 4,
    );
    addTearDown(() {
      if (!runtimeImage.debugDisposed) {
        runtimeImage.dispose();
      }
    });
    return runtimeImage;
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overlapping callers share normalized paths and preserve batch load',
      () async {
    final batchCompleter = Completer<Map<String, RuntimeTilesetImage>>();
    final requestedBatches = <Map<String, String>>[];
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        requestedBatches.add(Map<String, String>.of(paths));
        return batchCompleter.future;
      },
    );

    final firstFuture = cache.loadById(<String, String>{
      'water': '/tmp/project/tilesets/water.png',
      'grass': '/tmp/project/tilesets/grass.png',
    });
    final aliasFuture = cache.loadById(<String, String>{
      'waterAlias': '/tmp/project/tilesets/./water.png',
    });
    final thirdFuture = cache.loadById(<String, String>{
      'thirdWaterAlias': '/tmp/project/tilesets/../tilesets/water.png',
    });

    expect(
      requestedBatches,
      equals(<Map<String, String>>[
        <String, String>{
          'water': '/tmp/project/tilesets/water.png',
          'grass': '/tmp/project/tilesets/grass.png',
        },
      ]),
    );

    final water = await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366FF));
    final grass = await _fakeRuntimeTilesetImage(const ui.Color(0xFF33AA55));
    batchCompleter.complete(<String, RuntimeTilesetImage>{
      'water': water,
      'grass': grass,
    });

    final first = await firstFuture;
    final alias = await aliasFuture;
    final third = await thirdFuture;
    expect(identical(first['water'], water), isTrue);
    expect(identical(first['grass'], grass), isTrue);
    expect(identical(alias['waterAlias'], water), isTrue);
    expect(identical(third['thirdWaterAlias'], water), isTrue);
  });

  test('ids sharing one key inside a batch converge on one loader id',
      () async {
    Map<String, String>? requestedPaths;
    final water = await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366FF));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedPaths = Map<String, String>.of(paths);
        return <String, RuntimeTilesetImage>{paths.keys.single: water};
      },
    );

    final result = await cache.loadById(<String, String>{
      'water': '/tmp/project/tilesets/water.png',
      'waterAlias': '/tmp/project/tilesets/./water.png',
    });

    expect(
      requestedPaths,
      equals(<String, String>{
        'water': '/tmp/project/tilesets/water.png',
      }),
    );
    expect(identical(result['water'], water), isTrue);
    expect(identical(result['waterAlias'], water), isTrue);
  });

  test('same path with different transparent colors uses distinct cache keys',
      () async {
    final redImage = await _fakeRuntimeTilesetImage(const ui.Color(0xFFFF0000));
    final blueImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF0000FF));
    Map<String, TilesetTransparentColor>? requestedColors;
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedColors = Map<String, TilesetTransparentColor>.of(
          transparentColorByTilesetId,
        );
        return <String, RuntimeTilesetImage>{
          'red': redImage,
          'blue': blueImage,
        };
      },
    );
    final red = TilesetTransparentColor(red: 255, green: 0, blue: 0);
    final blue = TilesetTransparentColor(red: 0, green: 0, blue: 255);

    final result = await cache.loadById(
      <String, String>{
        'red': '/tmp/project/tilesets/shared.png',
        'blue': '/tmp/project/tilesets/shared.png',
      },
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'red': red,
        'blue': blue,
      },
    );

    expect(
        requestedColors,
        equals(<String, TilesetTransparentColor>{
          'red': red,
          'blue': blue,
        }));
    expect(identical(result['red'], redImage), isTrue);
    expect(identical(result['blue'], blueImage), isTrue);
  });

  test('omitted ids stay omitted and are retried by a later request', () async {
    var loadCount = 0;
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF22CC88));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        loadCount += 1;
        if (loadCount == 1) {
          return const <String, RuntimeTilesetImage>{};
        }
        return <String, RuntimeTilesetImage>{'water': recovered};
      },
    );

    final omitted = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final retried = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(omitted, isEmpty);
    expect(loadCount, equals(2));
    expect(identical(retried['water'], recovered), isTrue);
  });

  test('partial batch success caches success and retries only omitted id',
      () async {
    final loaded = await _fakeRuntimeTilesetImage(const ui.Color(0xFF44AA66));
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFAA6644));
    final requestedBatches = <Map<String, String>>[];
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedBatches.add(Map<String, String>.of(paths));
        if (requestedBatches.length == 1) {
          return <String, RuntimeTilesetImage>{'loaded': loaded};
        }
        return <String, RuntimeTilesetImage>{'missing': recovered};
      },
    );

    final first = await cache.loadById(const <String, String>{
      'loaded': '/tmp/project/loaded.png',
      'missing': '/tmp/project/missing.png',
    });
    final second = await cache.loadById(const <String, String>{
      'loaded': '/tmp/project/loaded.png',
      'missing': '/tmp/project/missing.png',
    });

    expect(first.keys, orderedEquals(<String>['loaded']));
    expect(
      requestedBatches,
      equals(<Map<String, String>>[
        <String, String>{
          'loaded': '/tmp/project/loaded.png',
          'missing': '/tmp/project/missing.png',
        },
        <String, String>{'missing': '/tmp/project/missing.png'},
      ]),
    );
    expect(identical(second['loaded'], loaded), isTrue);
    expect(identical(second['missing'], recovered), isTrue);
  });

  test('disposes loader images returned for ids outside the requested batch',
      () async {
    final requested =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366AA));
    final extraneous =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFAA6633));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        return <String, RuntimeTilesetImage>{
          paths.keys.single: requested,
          'not-requested': extraneous,
        };
      },
    );

    final result = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(identical(result['water'], requested), isTrue);
    expect(requested.debugDisposed, isFalse);
    expect(extraneous.debugDisposed, isTrue);
    cache.dispose();
  });

  test('equivalent RGB values share the transparent-color cache key', () async {
    var loadCount = 0;
    final image = await _fakeRuntimeTilesetImage(const ui.Color(0xFF778899));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        loadCount += 1;
        return <String, RuntimeTilesetImage>{paths.keys.single: image};
      },
    );

    final first = await cache.loadById(
      const <String, String>{'first': '/tmp/project/shared.png'},
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'first': TilesetTransparentColor(red: 12, green: 34, blue: 56),
      },
    );
    final second = await cache.loadById(
      const <String, String>{'second': '/tmp/project/shared.png'},
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'second': TilesetTransparentColor(red: 12, green: 34, blue: 56),
      },
    );

    expect(loadCount, equals(1));
    expect(identical(first['first'], image), isTrue);
    expect(identical(second['second'], image), isTrue);
  });

  test('batch errors are shared by concurrent callers and allow retry',
      () async {
    final failedBatch = Completer<Map<String, RuntimeTilesetImage>>();
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFFFAA33));
    var loadCount = 0;
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        loadCount += 1;
        if (loadCount == 1) {
          return failedBatch.future;
        }
        return Future<Map<String, RuntimeTilesetImage>>.value(
          <String, RuntimeTilesetImage>{'retry': recovered},
        );
      },
    );

    final first = cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final overlapping = cache.loadById(
      const <String, String>{
        'waterAlias': '/tmp/project/./water.png',
      },
    );
    final firstExpectation = expectLater(first, throwsStateError);
    final overlappingExpectation = expectLater(overlapping, throwsStateError);
    failedBatch.completeError(StateError('decode failed'));

    await Future.wait<void>(<Future<void>>[
      firstExpectation,
      overlappingExpectation,
    ]);
    final retried = await cache.loadById(
      const <String, String>{'retry': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(retried['retry'], recovered), isTrue);
  });

  test('synchronous loader errors do not poison later retries', () async {
    var loadCount = 0;
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFCC8844));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        loadCount += 1;
        if (loadCount == 1) {
          throw StateError('synchronous failure');
        }
        return Future<Map<String, RuntimeTilesetImage>>.value(
          <String, RuntimeTilesetImage>{paths.keys.single: recovered},
        );
      },
    );

    await expectLater(
      cache.loadById(
        const <String, String>{'water': '/tmp/project/water.png'},
      ),
      throwsStateError,
    );
    final retry = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(retry['water'], recovered), isTrue);
  });

  test('a fresh cache instance reloads the same image path', () async {
    var loadCount = 0;
    final firstImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF112233));
    final secondImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF445566));

    Future<Map<String, RuntimeTilesetImage>> loader(
      Map<String, String> paths, {
      Map<String, TilesetTransparentColor> transparentColorByTilesetId =
          const {},
    }) async {
      loadCount += 1;
      return <String, RuntimeTilesetImage>{
        paths.keys.single: loadCount == 1 ? firstImage : secondImage,
      };
    }

    final firstCache = RuntimeTilesetImageSingleFlightCache(loader: loader);
    final first = await firstCache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final reloadedCache = RuntimeTilesetImageSingleFlightCache(loader: loader);
    final reloaded = await reloadedCache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(first['water'], firstImage), isTrue);
    expect(identical(reloaded['water'], secondImage), isTrue);
  });
}

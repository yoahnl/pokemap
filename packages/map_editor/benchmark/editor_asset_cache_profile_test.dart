import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles 100 assets across duplicates failures and ten cycles',
      (tester) async {
    final receipt = await tester.runAsync(() async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_editor_asset_profile_',
      );
      try {
        final roots = <Directory>[
          await Directory('${sandbox.path}/project_a').create(),
          await Directory('${sandbox.path}/project_b').create(),
        ];
        final paths = <String>[];
        for (var index = 0; index < 100; index++) {
          final path = '${roots.first.path}/asset_$index.png';
          await File(path).writeAsBytes(_png(index), flush: true);
          paths.add(path);
        }

        const budget = 32 * 1024;
        final cache = EditorImageCache(
          sessionKey: roots.first.path,
          maximumDecodedBytes: budget,
          retirementScheduler: _disposeImmediately,
        );
        final otherProjectCache = EditorImageCache(
          sessionKey: roots.last.path,
          maximumDecodedBytes: budget,
          retirementScheduler: _disposeImmediately,
        );
        final rssBefore = ProcessInfo.currentRss;
        final stopwatch = Stopwatch()..start();

        final duplicates = await Future.wait([
          for (var index = 0; index < 8; index++) cache.load(paths.first),
        ]);
        for (final result in duplicates) {
          expect(result.image, isNotNull);
          result.dispose();
        }

        final rssByCycle = <int>[];
        for (var cycle = 0; cycle < 10; cycle++) {
          for (final path in paths) {
            final result = await cache.load(path);
            expect(result.image, isNotNull);
            result.dispose();
          }
          final missing = await cache.load(
            '${roots.first.path}/missing_$cycle.png',
          );
          expect(
            missing.failure?.kind,
            EditorImageFailureKind.missingFile,
          );
          rssByCycle.add(ProcessInfo.currentRss);
        }

        final isolated = await otherProjectCache.load(paths.first);
        expect(isolated.image, isNotNull);
        isolated.dispose();
        stopwatch.stop();

        final diagnostics = cache.diagnostics;
        expect(diagnostics.residentDecodedBytes, lessThanOrEqualTo(budget));
        expect(diagnostics.inFlightLoads, 0);
        expect(diagnostics.evictions, greaterThan(0));
        expect(diagnostics.missingFiles, 10);
        expect(otherProjectCache.diagnostics.entries, 1);

        final result = <String, Object?>{
          'schemaVersion': 1,
          'benchmark': 'editor_asset_cache',
          'assets': paths.length,
          'duplicateCallers': duplicates.length,
          'cycles': 10,
          'elapsedUs': stopwatch.elapsedMicroseconds,
          'rssBeforeBytes': rssBefore,
          'rssAfterBytes': ProcessInfo.currentRss,
          'rssByCycleBytes': rssByCycle,
          'cache': _diagnosticsJson(diagnostics),
          'otherProjectCache': _diagnosticsJson(otherProjectCache.diagnostics),
        };
        cache.dispose();
        otherProjectCache.dispose();
        return result;
      } finally {
        await sandbox.delete(recursive: true);
      }
    });

    // Keep one machine-readable line for the Evidence Pack runner.
    // ignore: avoid_print
    print(jsonEncode(receipt));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Uint8List _png(int seed) {
  final image = img.Image(width: 16, height: 16);
  img.fill(
    image,
    color: img.ColorRgba8(
      seed % 255,
      (seed * 3) % 255,
      (seed * 7) % 255,
      255,
    ),
  );
  return Uint8List.fromList(img.encodePng(image));
}

Map<String, Object?> _diagnosticsJson(
  EditorImageCacheDiagnostics diagnostics,
) =>
    {
      'entries': diagnostics.entries,
      'hits': diagnostics.hits,
      'misses': diagnostics.misses,
      'invalidations': diagnostics.invalidations,
      'missingFiles': diagnostics.missingFiles,
      'decodeFailures': diagnostics.decodeFailures,
      'disposedImages': diagnostics.disposedImages,
      'maximumDecodedBytes': diagnostics.maximumDecodedBytes,
      'residentDecodedBytes': diagnostics.residentDecodedBytes,
      'peakDecodedBytes': diagnostics.peakDecodedBytes,
      'evictions': diagnostics.evictions,
      'inFlightLoads': diagnostics.inFlightLoads,
    };

void _disposeImmediately(void Function() disposeImage) => disposeImage();

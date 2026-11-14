import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import '../support/resource_stress_fixture.dart';
import 'studio_resource_catalog_update_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceStressFixture fixture;
  setUp(() async => fixture = await ResourceStressFixture.create());
  tearDown(() => fixture.dispose());

  test(
    'pixel refresh still waits for pending image decode before invalidation',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final resources = await StudioMapResources.load(
        fixture.session,
        fixture.manifest,
        decode: (bytes, {transparentColor}) async {
          if (!started.isCompleted) {
            started.complete();
            await release.future;
          }
          return decodeRuntimeTilesetImage(
            bytes,
            transparentColor: transparentColor,
          );
        },
      );
      addTearDown(resources.dispose);
      final request = resources.store.request(fixture.lateAtlasId);
      Future<void>? refresh;
      try {
        await started.future.timeout(const Duration(seconds: 5));
        var completed = false;
        refresh = resources
            .updateCatalog(
              fixture.manifest,
              changedRelativePaths: {
                fixture.manifest.tilesets
                    .firstWhere((entry) => entry.id == fixture.lateAtlasId)
                    .relativePath,
              },
            )
            .then((_) => completed = true);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(completed, isFalse);
        expect(resources.catalogVersion, 0);
      } finally {
        if (!release.isCompleted) release.complete();
        await request;
        await refresh;
      }
      expect(resources.catalogVersion, 1);
      expect(resources.images, isNot(contains(fixture.lateAtlasId)));
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test(
    'overlapping image refreshes invalidate changes applied while waiting',
    () async {
      for (final entry in {
        'a': 0xffff0000,
        'a-next': 0xff0000ff,
        'b': 0xff00ff00,
        'b-next': 0xffffff00,
        'blocker': 0xff000000,
      }.entries) {
        await File('${fixture.directory.path}/assets/${entry.key}.png')
            .writeAsBytes(await pngBytes(16, 16, entry.value));
      }
      final manifest = fixture.manifest.copyWith(
        tilesets: [
          for (final id in ['a', 'b', 'blocker'])
            ProjectTilesetEntry(
              id: id,
              name: id,
              relativePath: 'assets/$id.png',
            ),
        ],
      );
      final started = Completer<void>();
      final release = Completer<void>();
      var decodes = 0;
      final resources = await StudioMapResources.load(
        fixture.session,
        manifest,
        decode: (bytes, {transparentColor}) async {
          if (++decodes == 2) {
            started.complete();
            await release.future;
          }
          return decodeRuntimeTilesetImage(
            bytes,
            transparentColor: transparentColor,
          );
        },
      );
      final owner = Object();
      addTearDown(() async {
        resources.release(owner);
        await resources.dispose();
      });
      resources.retain(owner, {'a'});
      await resources.settled;
      expect(await decodedPixel(resources.images['a']!), [255, 0, 0, 255]);
      final blocker = resources.store.request('blocker');
      Future<void>? first;
      Future<void>? second;
      final firstManifest = manifest.copyWith(
        tilesets: [
          for (final entry in manifest.tilesets)
            entry.id == 'a'
                ? entry.copyWith(relativePath: 'assets/a-next.png')
                : entry,
        ],
      );
      final secondManifest = manifest.copyWith(
        tilesets: [
          for (final entry in manifest.tilesets)
            entry.id == 'b'
                ? entry.copyWith(relativePath: 'assets/b-next.png')
                : entry,
        ],
      );
      try {
        await started.future.timeout(const Duration(seconds: 5));
        first = resources.updateCatalog(firstManifest);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        second = resources.updateCatalog(secondManifest);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(resources.catalogVersion, 0);
      } finally {
        if (!release.isCompleted) release.complete();
        await blocker;
        await first;
        await second;
      }
      await resources.settled;
      expect(resources.catalogVersion, 2);
      expect(resources.manifest, secondManifest);
      expect(resources.paths['a'], endsWith('/assets/a.png'));
      expect(await decodedPixel(resources.images['a']!), [255, 0, 0, 255]);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

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
      await File('${fixture.directory.path}/assets/new.png')
          .writeAsBytes(await pngBytes(32, 32, 0xff0000ff));
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
}

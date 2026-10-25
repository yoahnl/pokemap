import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
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
    'scoped catalogue removal retires held images without reading absent paths',
    () async {
      for (final entry in {'scoped-a': 0xffff0000, 'scoped-b': 0xff0000ff}.entries) {
        await File('${fixture.directory.path}/assets/${entry.key}.png')
            .writeAsBytes(await _png(16, 16, entry.value));
      }
      final first = ProjectManifest(
        name: 'Scoped images',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'assets/scoped-a.png',
          ),
        ],
      );
      final second = first.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'b',
            name: 'B',
            relativePath: 'assets/scoped-b.png',
          ),
        ],
      );
      final resources = await StudioMapResources.load(fixture.session, first);
      final previousPainter = Object();
      final nextPainter = Object();
      addTearDown(() async {
        resources.release(previousPainter);
        resources.release(nextPainter);
        await resources.dispose();
      });
      resources.retain(previousPainter, {'a'});
      await resources.settled;
      final previous = resources.images['a']!;
      expect(resources.store.decoder.reads, 1);
      expect(resources.store.decoder.decodes, 1);

      await resources.updateCatalog(second);
      await resources.settled;

      expect(resources.paths.keys, ['b']);
      expect(resources.images, isNot(contains('a')));
      expect(resources.diagnostics, isEmpty);
      expect(resources.store.decoder.reads, 1);
      expect(resources.store.decoder.decodes, 1);
      expect(previous.debugDisposed, isFalse);
      expect(await _pixel(previous), [255, 0, 0, 255]);

      resources.retain(nextPainter, {'b'});
      await resources.settled;
      final current = resources.images['b']!;
      expect(await _pixel(current), [0, 0, 255, 255]);
      expect(resources.store.decoder.reads, 2);
      expect(resources.store.decoder.decodes, 2);
      expect(resources.diagnostics, isEmpty);
      resources.release(previousPainter);
      expect(previous.debugDisposed, isTrue);
      expect(current.debugDisposed, isFalse);
    },
  );

  test(
    'catalogue invalidation still reloads admitted pinned images',
    () async {
      final file = File('${fixture.directory.path}/assets/scoped-current.png');
      await file.writeAsBytes(await _png(16, 16, 0xffff0000));
      final manifest = ProjectManifest(
        name: 'Scoped current image',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'current',
            name: 'Current',
            relativePath: 'assets/scoped-current.png',
          ),
        ],
      );
      final resources = await StudioMapResources.load(fixture.session, manifest);
      final painter = Object();
      addTearDown(() async {
        resources.release(painter);
        await resources.dispose();
      });
      resources.retain(painter, {'current'});
      await resources.settled;
      final previous = resources.images['current']!;
      expect(resources.store.decoder.reads, 1);
      expect(resources.store.decoder.decodes, 1);
      await file.writeAsBytes(await _png(16, 16, 0xff0000ff));

      await resources.updateCatalog(
        manifest,
        changedRelativePaths: {'assets/scoped-current.png'},
      );
      await resources.settled;

      final current = resources.images['current']!;
      expect(current, isNot(same(previous)));
      expect(await _pixel(current), [0, 0, 255, 255]);
      expect(resources.store.decoder.reads, 2);
      expect(resources.store.decoder.decodes, 2);
      expect(resources.diagnostics, isEmpty);
      expect(previous.debugDisposed, isFalse);
      resources.release(painter);
      expect(previous.debugDisposed, isTrue);
      expect(current.debugDisposed, isFalse);
    },
  );

  test(
    'explicit unknown image requests still report unsupported without decoding',
    () async {
      final resources = await StudioMapResources.load(
        fixture.session,
        const ProjectManifest(name: 'Empty scope', maps: [], tilesets: []),
      );
      addTearDown(resources.dispose);

      await resources.store.request(
        'not-in-partial-catalog',
        retainUntilComplete: true,
      );
      await resources.settled;

      expect(resources.diagnostics.single.resourceId, 'not-in-partial-catalog');
      expect(resources.diagnostics.single.cause, WorkspaceResourceCause.unsupported);
      expect(resources.store.decoder.reads, 0);
      expect(resources.store.decoder.decodes, 0);
    },
  );

  for (final contactShadow in <bool?>[true, false, null]) {
    test(
      'metadata contact shadow $contactShadow refresh does not wait for pending image decode',
      () async {
        final before = fixture.manifest.copyWith(
          characters: [
            for (final character in fixture.manifest.characters)
              character.copyWith(contactShadow: contactShadow != true),
          ],
        );
        await _expectMetadataRefreshWithoutDecode(
          fixture,
          before,
          before.copyWith(
            characters: [
              for (final character in before.characters)
                character.copyWith(contactShadow: contactShadow),
            ],
          ),
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  }

  test('metadata project shadow default refresh does not wait for pending image decode', () async {
    await _expectMetadataRefreshWithoutDecode(
      fixture,
      fixture.manifest,
      fixture.manifest.copyWith(
        settings: fixture.manifest.settings.copyWith(
          actorContactShadowsByDefault: true,
        ),
      ),
    );
  }, timeout: const Timeout(Duration(seconds: 20)));

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
            .writeAsBytes(await _png(16, 16, entry.value));
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
      expect(await _pixel(resources.images['a']!), [255, 0, 0, 255]);
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
      expect(await _pixel(resources.images['a']!), [255, 0, 0, 255]);
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
      final diagnostics = resources.diagnostics
          .map((item) => '${item.cause.name}: ${item.detail}')
          .join('; ');
      expect(
        resources.images,
        contains('large'),
        reason: 'reads=${resources.store.decoder.reads}, '
            'decodes=${resources.store.decoder.decodes}, '
            'transient=${resources.store.decoder.peakTransientBytes}, '
            'diagnostics=$diagnostics',
      );
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

Future<void> _expectMetadataRefreshWithoutDecode(
  ResourceStressFixture fixture,
  ProjectManifest before,
  ProjectManifest after,
) async {
  expect(before.characters, isNotEmpty);
  final started = Completer<void>();
  final release = Completer<void>();
  final resources = await StudioMapResources.load(
    fixture.session,
    before,
    decode: (bytes, {transparentColor}) async {
      started.complete();
      await release.future;
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
    refresh = resources.updateCatalog(
      after,
      changedRelativePaths: {'project.json'},
    );
    await refresh.timeout(const Duration(seconds: 1));
    expect(resources.manifest, after);
    expect(resources.catalogVersion, 1);
    expect(resources.store.decoder.decodes, 1);
    expect(resources.images, isNot(contains(fixture.lateAtlasId)));
    expect(release.isCompleted, isFalse);
  } finally {
    if (!release.isCompleted) release.complete();
    await request;
    await refresh;
  }
  expect(resources.images, contains(fixture.lateAtlasId));
  expect(resources.store.decoder.decodes, 1);
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

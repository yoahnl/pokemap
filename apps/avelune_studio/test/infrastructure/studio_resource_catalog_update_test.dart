import 'dart:async';
import 'dart:io';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/rendering/contracts/workspace_resource_diagnostic.dart';
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
    'scoped catalogue removal retires held images without reading absent paths',
    () async {
      for (final entry in {'scoped-a': 0xffff0000, 'scoped-b': 0xff0000ff}.entries) {
        await File('${fixture.directory.path}/assets/${entry.key}.png')
            .writeAsBytes(await pngBytes(16, 16, entry.value));
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
      expect(await decodedPixel(previous), [255, 0, 0, 255]);

      resources.retain(nextPainter, {'b'});
      await resources.settled;
      final current = resources.images['b']!;
      expect(await decodedPixel(current), [0, 0, 255, 255]);
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
      await file.writeAsBytes(await pngBytes(16, 16, 0xffff0000));
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
      await file.writeAsBytes(await pngBytes(16, 16, 0xff0000ff));

      await resources.updateCatalog(
        manifest,
        changedRelativePaths: {'assets/scoped-current.png'},
      );
      await resources.settled;

      final current = resources.images['current']!;
      expect(current, isNot(same(previous)));
      expect(await decodedPixel(current), [0, 0, 255, 255]);
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

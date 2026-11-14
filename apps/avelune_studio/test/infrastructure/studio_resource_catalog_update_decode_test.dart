import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/resource_stress_fixture.dart';
import 'studio_resource_catalog_update_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceStressFixture fixture;
  setUp(() async => fixture = await ResourceStressFixture.create());
  tearDown(() => fixture.dispose());

  test('same-path pixels and aliases refresh while previous painters retain the old image', () async {
    final file = File('${fixture.directory.path}/assets/atelier.png');
    await file.writeAsBytes(await pngBytes(32, 32, 0xffff0000));
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
    final resources = await StudioMapResources.load(fixture.session, manifest);
    addTearDown(resources.dispose);
    final painter = Object();
    resources.retain(painter, {'a', 'alias'});
    await resources.settled;
    final old = resources.images['a']!;
    expect(resources.images['alias'], same(old));
    expect(await decodedPixel(old), [255, 0, 0, 255]);
    await file.writeAsBytes(await pngBytes(32, 32, 0xff0000ff));
    await resources.updateCatalog(
      manifest,
      changedRelativePaths: {'assets/atelier.png'},
    );
    await resources.settled;
    final fresh = resources.images['a']!;
    expect(fresh, isNot(same(old)));
    expect(resources.images['alias'], same(fresh));
    expect(await decodedPixel(fresh), [0, 0, 255, 255]);
    expect(old.debugDisposed, isFalse);
    expect(await decodedPixel(old), [255, 0, 0, 255]);
    expect(resources.decodedBytes, 32 * 32 * 4 * 2);
    resources.release(painter);
    expect(old.debugDisposed, isTrue);
    expect(fresh.debugDisposed, isFalse);
    expect(resources.decodedBytes, 32 * 32 * 4);
    expect(resources.store.decoder.decodes, 2);
  });

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
      await file.writeAsBytes(await pngBytes(64, 64, 0xff00ff00));
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
      await file.writeAsBytes(await pngBytes(16, 16, 0xff00ff00));
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

  test('4096 by 5280 atlas uses existing chunks with bounded whole-decode reservation', () async {
    final encoded = await pngBytes(4096, 5280, 0xff336699);
    await File('${fixture.directory.path}/assets/large.png')
        .writeAsBytes(encoded);
    final manifest = fixture.manifest.copyWith(
      tilesets: [
        const ProjectTilesetEntry(
          id: 'large',
          name: 'Large',
          relativePath: 'assets/large.png',
        ),
      ],
    );
    final resources = await StudioMapResources.load(fixture.session, manifest);
    addTearDown(resources.dispose);
    await resources.store.request('large');
    final diagnostics = resources.diagnostics
        .map((item) => '${item.cause.name}: ${item.detail}')
        .join('; ');
    expect(
      resources.images,
      contains('large'),
      reason:
          'reads=${resources.store.decoder.reads}, '
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
    expect(
      await decodedPixel(image, const ui.Rect.fromLTWH(100, 4090, 16, 16)),
      [51, 102, 153, 255],
    );
    expect(resources.diagnostics, isEmpty);
  });
}

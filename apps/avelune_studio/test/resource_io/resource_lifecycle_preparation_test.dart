import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_lifecycle_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

Uint8List candidate({int width = 64}) {
  final pixels = image.Image(width: width, height: 48);
  image.fill(pixels, color: image.ColorRgba8(220, 80, 30, 160));
  return Uint8List.fromList(image.encodePng(pixels));
}

Future<Map<String, List<int>>> files(Directory directory) async => {
  for (final entity in await directory.list(recursive: true).toList())
    if (entity is File)
      entity.path.substring(directory.path.length): await entity.readAsBytes(),
};

void main() {
  test('replacement retains inspected bytes despite source changes', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final original = imported.manifest.tilesets.single;
    final frozen = candidate();
    await fixture.source.writeAsBytes(frozen);
    final before = await files(fixture.root);
    final request = ResourceReplacementRequest(
      tilesetId: original.id,
      sourcePath: fixture.source.path,
      bytes: frozen,
    );
    final preview = await fixture.resources.prepareReplacement(request);
    expect(await files(fixture.root), before);
    expect(preview.candidateBytes, frozen);
    expect(preview.preparation.confirmationRequired, true);
    await fixture.source.writeAsBytes(candidate(width: 80));
    frozen[0] = 0;
    final result = await fixture.resources.applyPrepared(
      preview.preparation,
      confirmDestructive: true,
    );
    final updated = result.manifest.tilesets.single;
    expect(updated.id, original.id);
    final grid = updated.source as ProjectRegularAtlasTilesetSource;
    final originalGrid = original.source as ProjectRegularAtlasTilesetSource;
    expect(grid.tileWidth, originalGrid.tileWidth);
    expect(grid.tileHeight, originalGrid.tileHeight);
    expect(
      await File('${fixture.root.path}/${updated.relativePath}').readAsBytes(),
      preview.candidateBytes,
    );
    await expectLater(
      fixture.resources.applyPrepared(
        preview.preparation,
        confirmDestructive: true,
      ),
      throwsA(isA<ResourceFailure>()),
    );
    final reopened = await fixture.maps.loadProject(fixture.session);
    expect(reopened.tilesets.single, updated);
    expect(await fixture.mapFile.readAsBytes(), before['/garden.json']);
  });

  test(
    'released preparation cannot write and preview cancellation changes nothing',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final before = await files(fixture.root);
      final preview = await fixture.resources.prepareReplacement(
        ResourceReplacementRequest(
          tilesetId: imported.manifest.tilesets.single.id,
          sourcePath: fixture.source.path,
          bytes: candidate(),
        ),
      );
      await fixture.resources.releasePreparation(preview.preparation);
      await expectLater(
        fixture.resources.applyPrepared(
          preview.preparation,
          confirmDestructive: true,
        ),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await files(fixture.root), before);
    },
  );

  test(
    'wrong dimensions and malformed PNG are refused before staging publication',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final before = await files(fixture.root);
      for (final bytes in [candidate(width: 80), candidate().sublist(0, 33)]) {
        await expectLater(
          fixture.resources.prepareReplacement(
            ResourceReplacementRequest(
              tilesetId: imported.manifest.tilesets.single.id,
              sourcePath: fixture.source.path,
              bytes: Uint8List.fromList(bytes),
            ),
          ),
          throwsA(isA<ResourceFailure>()),
        );
        expect(await files(fixture.root), before);
      }
    },
  );

  test(
    'reconciliation failure retains real receipt without repeating publication',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      var fail = true;
      final adapter = LocalResourceAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
        beforeReconciliation: () async {
          if (fail) throw StateError('refresh');
        },
      );
      addTearDown(adapter.dispose);
      final preview = await adapter.prepareReplacement(
        ResourceReplacementRequest(
          tilesetId: imported.manifest.tilesets.single.id,
          sourcePath: fixture.source.path,
          bytes: candidate(),
        ),
      );
      ResourceFailure? failure;
      try {
        await adapter.applyPrepared(
          preview.preparation,
          confirmDestructive: true,
        );
      } on ResourceFailure catch (error) {
        failure = error;
      }
      expect(failure?.partialReceipt, isNotNull);
      final published = await files(fixture.root);
      await expectLater(
        adapter.applyPrepared(preview.preparation, confirmDestructive: true),
        throwsA(isA<ResourceFailure>()),
      );
      fail = false;
      await adapter.reconcileReceipt(failure!.partialReceipt!);
      expect(await files(fixture.root), published);
    },
  );
}

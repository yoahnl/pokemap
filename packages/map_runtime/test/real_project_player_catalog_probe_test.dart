import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/performance/real_project_player_catalog_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final partitioned in [false, true]) {
    test(
      'measures one shared catalog and A B C A, partitioned=$partitioned',
      () async {
        final fixture = await _fixture(partitioned: partitioned);
        final output = p.join(fixture.parent.path, 'receipt.json');
        final before = await File(fixture.projectFile).readAsBytes();
        final receipt = await runRealProjectPlayerCatalogProbe(
          projectDirectory: fixture.root.path,
          outputPath: output,
        );
        expect(receipt['status'], 'completed');
        expect(receipt['route'], ['a', 'b', 'c', 'a']);
        expect(receipt['bundleLoadCount'], 4);
        expect(receipt['catalogOpenCount'], 1);
        final phases = (receipt['phases']! as List).cast<Map>();
        expect(phases.map((phase) => phase['phase']), [
          'catalogOpen',
          'firstMap',
          'visit',
          'visit',
          'revisit',
          'dispose',
        ]);
        for (final phase in phases) {
          expect(phase['elapsedMicroseconds'], isNonNegative);
          expect(phase['rssBeforeBytes'], greaterThan(0));
          expect(phase['rssAfterBytes'], greaterThan(0));
          expect(
            phase['rssSampledPeakBytes'],
            greaterThanOrEqualTo(phase['rssBeforeBytes']! as int),
          );
        }
        final loads = phases.where(
          (phase) => phase.containsKey('dependencies'),
        );
        for (final phase in loads) {
          final dependencies = phase['dependencies']! as Map;
          expect((dependencies['tilesets']! as Map)['count'], 1);
          expect(phase['catalogShared'], isTrue);
          expect(phase['resourceBudgetShared'], isTrue);
        }
        expect(loads.first['dependencies'], loads.last['dependencies']);
        expect(receipt['catalogOwnerReleased'], isTrue);
        expect((receipt['source']! as Map)['unchanged'], isTrue);
        expect((receipt['mapSources']! as List), hasLength(3));
        expect(await File(fixture.projectFile).readAsBytes(), before);
        expect(await File(output).length(), lessThanOrEqualTo(30 * 1024));
        expect(jsonDecode(await File(output).readAsString()), receipt);
        expect(
          await fixture.root
              .list(recursive: true)
              .where((entry) => p.basename(entry.path) == 'receipt.json')
              .length,
          0,
        );
      },
    );
  }

  test(
    'refuses an output inside the source, including a parent symlink',
    () async {
      final fixture = await _fixture();
      final link = Link(p.join(fixture.parent.path, 'output-link'));
      await link.create(fixture.root.path);
      for (final output in [
        p.join(fixture.root.path, 'receipt.json'),
        p.join(link.path, 'receipt.json'),
      ]) {
        await expectLater(
          runRealProjectPlayerCatalogProbe(
            projectDirectory: fixture.root.path,
            outputPath: output,
          ),
          throwsArgumentError,
        );
        expect(await File(output).exists(), isFalse);
      }
    },
  );

  test('refuses an existing output symlink into the source', () async {
    final fixture = await _fixture();
    final link = Link(p.join(fixture.parent.path, 'receipt.json'));
    await link.create(fixture.projectFile);
    final before = await File(fixture.projectFile).readAsBytes();
    await expectLater(
      runRealProjectPlayerCatalogProbe(
        projectDirectory: fixture.root.path,
        outputPath: link.path,
      ),
      throwsArgumentError,
    );
    expect(await File(fixture.projectFile).readAsBytes(), before);
  });

  test(
    'records a malformed source error without changing that source',
    () async {
      final fixture = await _fixture();
      await File(fixture.projectFile).writeAsString('{');
      final receipt = await runRealProjectPlayerCatalogProbe(
        projectDirectory: fixture.root.path,
        outputPath: p.join(fixture.parent.path, 'receipt.json'),
      );
      expect(receipt['status'], 'failed');
      expect((receipt['error']! as Map)['phase'], 'catalogOpen');
      expect((receipt['error']! as Map)['type'], 'FormatException');
      expect((receipt['source']! as Map)['unchanged'], isTrue);
      expect(await File(fixture.projectFile).readAsString(), '{');
    },
  );

  test('bounds the map selection and refuses overwriting evidence', () async {
    final fixture = await _fixture();
    final output = File(p.join(fixture.parent.path, 'receipt.json'));
    await output.writeAsString('preserve');
    await expectLater(
      runRealProjectPlayerCatalogProbe(
        projectDirectory: fixture.root.path,
        outputPath: output.path,
      ),
      throwsArgumentError,
    );
    expect(await output.readAsString(), 'preserve');
    await expectLater(
      runRealProjectPlayerCatalogProbe(
        projectDirectory: fixture.root.path,
        outputPath: p.join(fixture.parent.path, 'other.json'),
        mapIds: ['a', 'a', 'b'],
      ),
      throwsArgumentError,
    );
  });
}

Future<_Fixture> _fixture({bool partitioned = false}) async {
  final parent = await Directory.systemTemp.createTemp('catalog-probe-test-');
  addTearDown(() => parent.delete(recursive: true));
  final root = await Directory(p.join(parent.path, 'project')).create();
  final project = ProjectManifest(
    name: 'Catalog probe',
    maps: [
      for (final id in ['a', 'b', 'c'])
        ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
    ],
    tilesets: [
      for (final id in ['a', 'b', 'c', 'unused'])
        ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
    ],
  );
  final file = File(p.join(root.path, 'project.json'));
  if (partitioned) {
    final publication = PortableCatalogPublication.encodeProject(project);
    await file.writeAsString(jsonEncode(publication.descriptor));
    for (final object in publication.storage.objects.entries) {
      final target = File(
        p.join(root.path, 'catalog/objects/${object.key}.json'),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(object.value);
    }
  } else {
    await file.writeAsString(jsonEncode(project.toJson()));
  }
  await Directory(p.join(root.path, 'maps')).create();
  for (final id in ['a', 'b', 'c']) {
    await File(p.join(root.path, 'maps/$id.json')).writeAsString(
      jsonEncode(
        MapData(
          id: id,
          name: id,
          size: const GridSize(width: 2, height: 2),
          tilesetId: id,
        ).toJson(),
      ),
    );
  }
  return _Fixture(parent, root, file.path);
}

final class _Fixture {
  const _Fixture(this.parent, this.root, this.projectFile);
  final Directory parent;
  final Directory root;
  final String projectFile;
}

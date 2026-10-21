import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catalog source is bound to the exact admitted bytes before decoding',
    () async {
      final fixture = await _fixture();
      final bytes = await fixture.readAsBytes();
      final expected = narrativeEventBytesFingerprint(bytes).substring(7);
      final catalog = await RuntimeProjectCatalog.open(
        fixture.path,
        expectedSourceSha256: expected,
      );
      catalog.dispose();
      final changed = (await fixture.readAsString()).replaceFirst(
        'Cache',
        'Other',
      );
      await fixture.writeAsString(changed);
      await expectLater(
        RuntimeProjectCatalog.open(
          fixture.path,
          expectedSourceSha256: expected,
        ),
        throwsA(isA<FormatException>()),
      );
      await fixture.writeAsString('{');
      await expectLater(
        RuntimeProjectCatalog.open(
          fixture.path,
          expectedSourceSha256: expected,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('fingerprint'),
          ),
        ),
      );
    },
  );

  test(
    'batch source fingerprints bind each map to admitted bytes before decoding',
    () async {
      final fixture = await _fixture();
      final catalog = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(catalog.dispose);
      final expected = {
        for (final id in ['a', 'b'])
          id: narrativeEventBytesFingerprint(
            await File('${fixture.parent.path}/$id.json').readAsBytes(),
          ).substring(7),
      };
      expect(
        (await catalog.loadNarrativeMapData(expectedSha256ByMapId: expected))
            .length,
        2,
      );
      final file = File('${fixture.parent.path}/b.json');
      await file.writeAsString(
        (await file.readAsString()).replaceFirst('Beta', 'Zeta'),
      );
      await expectLater(
        catalog.loadNarrativeMapData(expectedSha256ByMapId: expected),
        throwsA(
          isA<MapLoadException>().having(
            (error) => error.message,
            'message',
            contains('fingerprint'),
          ),
        ),
      );
      await file.writeAsString('{');
      await expectLater(
        catalog.loadNarrativeMapData(expectedSha256ByMapId: expected),
        throwsA(
          isA<MapLoadException>().having(
            (error) => error.message,
            'message',
            contains('fingerprint'),
          ),
        ),
      );
    },
  );

  test('batch rejects incomplete or extra admitted map fingerprints', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(fixture.path);
    addTearDown(catalog.dispose);
    await expectLater(
      Future.sync(
        () => catalog.loadNarrativeMapData(expectedSha256ByMapId: const {}),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      Future.sync(
        () => catalog.loadNarrativeMapData(
          expectedSha256ByMapId: const {'a': 'bad', 'b': 'bad'},
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'admitted fingerprint dictionary is copied before asynchronous loading',
    () async {
      final fixture = await _fixture();
      final catalog = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(catalog.dispose);
      final expected = {
        for (final id in ['a', 'b'])
          id: narrativeEventBytesFingerprint(
            await File('${fixture.parent.path}/$id.json').readAsBytes(),
          ).substring(7),
      };
      await expectLater(
        Future.sync(
          () => catalog.loadNarrativeMapData(
            expectedSha256ByMapId: {...expected, 'unknown': expected['a']!},
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      final pending = catalog.loadNarrativeMapData(
        expectedSha256ByMapId: expected,
      );
      expected['a'] = List.filled(64, '0').join();
      expect((await pending).map((map) => map.id), ['a', 'b']);
    },
  );

  test('unchanged map content reuses decoded value for sequential and concurrent reads', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(fixture.path);
    addTearDown(catalog.dispose);
    final first = await catalog.loadMapData('a');
    final next = await Future.wait([
      catalog.loadMapData('a'),
      catalog.loadMapData('a'),
    ]);
    expect(next[0], same(first));
    expect(next[1], same(first));
  });

  test('concurrent cold reads share one decoded result', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(fixture.path);
    addTearDown(catalog.dispose);
    final values = await Future.wait([
      catalog.loadMapData('a'),
      catalog.loadMapData('a'),
    ]);
    expect(values[0], same(values[1]));
  });

  test(
    'aggregate source byte ceiling evicts smaller individual maps',
    () async {
      final fixture = await _fixture();
      final length = await File('${fixture.parent.path}/a.json').length();
      final catalog = await RuntimeProjectCatalog.open(
        fixture.path,
        maximumCachedMapBytes: length + 1,
      );
      addTearDown(catalog.dispose);
      final first = await catalog.loadMapData('a');
      await catalog.loadMapData('b');
      expect(await catalog.loadMapData('a'), isNot(same(first)));
    },
  );

  test(
    'changed bytes invalidate a map with identical size and modification time',
    () async {
      final fixture = await _fixture();
      final catalog = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(catalog.dispose);
      final first = await catalog.loadMapData('a');
      final file = File('${fixture.parent.path}/a.json');
      final before = await file.stat();
      await file.writeAsString(
        (await file.readAsString()).replaceFirst('Alpha', 'Bravo'),
      );
      await file.setLastModified(before.modified);
      expect(await file.length(), before.size);
      expect((await file.stat()).modified, before.modified);
      final changed = await catalog.loadMapData('a');
      expect(changed, isNot(same(first)));
      expect(changed.name, 'Bravo');
    },
  );

  test(
    'map cache evicts least recently used values at its entry ceiling',
    () async {
      final fixture = await _fixture();
      final catalog = await RuntimeProjectCatalog.open(
        fixture.path,
        maximumCachedMaps: 1,
      );
      addTearDown(catalog.dispose);
      final first = await catalog.loadMapData('a');
      await catalog.loadMapData('b');
      expect(await catalog.loadMapData('a'), isNot(same(first)));
    },
  );

  test('source byte ceiling prevents retaining an oversized map', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(
      fixture.path,
      maximumCachedMapBytes: 1,
    );
    addTearDown(catalog.dispose);
    final first = await catalog.loadMapData('a');
    expect(await catalog.loadMapData('a'), isNot(same(first)));
  });

  test('failed and missing reads can be retried after correction', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(fixture.path);
    addTearDown(catalog.dispose);
    final file = File('${fixture.parent.path}/a.json');
    await file.writeAsString('{');
    await expectLater(
      catalog.loadMapData('a'),
      throwsA(isA<FormatException>()),
    );
    await file.writeAsString(jsonEncode(_map('a', 'Alpha').toJson()));
    expect((await catalog.loadMapData('a')).id, 'a');
    await file.delete();
    await expectLater(
      catalog.loadMapData('a'),
      throwsA(isA<FileSystemException>()),
    );
    await file.writeAsString(jsonEncode(_map('a', 'Alpha').toJson()));
    expect((await catalog.loadMapData('a')).id, 'a');
  });

  test(
    'identity and symlink containment remain enforced after warming',
    () async {
      final fixture = await _fixture();
      final catalog = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(catalog.dispose);
      await catalog.loadMapData('a');
      final file = File('${fixture.parent.path}/a.json');
      await file.writeAsString(jsonEncode(_map('b', 'Wrong').toJson()));
      await expectLater(
        catalog.loadMapData('a'),
        throwsA(isA<MapLoadException>()),
      );
      await file.delete();
      final outside = await Directory.systemTemp.createTemp(
        'catalog-map-outside-',
      );
      addTearDown(() => outside.delete(recursive: true));
      final target = File('${outside.path}/a.json');
      await target.writeAsString(jsonEncode(_map('a', 'Alpha').toJson()));
      await Link(file.path).create(target.path);
      await expectLater(
        catalog.loadMapData('a'),
        throwsA(isA<MapLoadException>()),
      );
    },
  );

  test('disposed catalog refuses cached and in flight reads', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(fixture.path);
    final pending = catalog.loadMapData('a');
    catalog.dispose();
    await expectLater(pending, throwsStateError);
    await expectLater(
      Future.sync(() => catalog.loadMapData('a')),
      throwsStateError,
    );
  });

  test('narrative batch preserves order and validates every map without retaining the corpus', () async {
    final fixture = await _fixture();
    final catalog = await RuntimeProjectCatalog.open(
      fixture.path,
      maximumCachedMaps: 1,
    );
    addTearDown(catalog.dispose);
    final first = await catalog.loadMapData('a');
    final batch = await catalog.loadNarrativeMapData();
    expect(batch.map((map) => map.id), ['a', 'b']);
    expect(batch.map((map) => map.name), ['Alpha', 'Beta']);
    expect(await catalog.loadMapData('a'), same(first));
    await File('${fixture.parent.path}/b.json')
        .writeAsString(jsonEncode(_map('a', 'Wrong').toJson()));
    await expectLater(
      catalog.loadNarrativeMapData(),
      throwsA(isA<MapLoadException>()),
    );
  });
}

MapData _map(String id, String name) =>
    MapData(id: id, name: name, size: const GridSize(width: 2, height: 2));

Future<File> _fixture() async {
  final root = await Directory.systemTemp.createTemp(
    'runtime-catalog-map-cache-',
  );
  addTearDown(() => root.delete(recursive: true));
  final file = File('${root.path}/project.json');
  await file.writeAsString(
    jsonEncode(
      ProjectManifest(
        name: 'Cache',
        maps: const [
          ProjectMapEntry(id: 'a', name: 'Alpha', relativePath: 'a.json'),
          ProjectMapEntry(id: 'b', name: 'Beta', relativePath: 'b.json'),
        ],
        tilesets: const [],
      ).toJson(),
    ),
  );
  await File('${root.path}/a.json')
      .writeAsString(jsonEncode(_map('a', 'Alpha').toJson()));
  await File('${root.path}/b.json')
      .writeAsString(jsonEncode(_map('b', 'Beta').toJson()));
  return file;
}

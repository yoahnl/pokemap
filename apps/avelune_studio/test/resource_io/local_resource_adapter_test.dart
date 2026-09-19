import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

void main() {
  late ResourceFixture fixture;
  setUp(() async => fixture = await ResourceFixture.create());
  tearDown(() => fixture.dispose());

  test('cancel before validation publishes no file or resource', () async {
    final before = await fixture.manifestFile.readAsBytes();
    final files = await fixture.root
        .list(recursive: true)
        .map((f) => f.path)
        .toList();
    await fixture.resources.dispose();
    expect(await fixture.manifestFile.readAsBytes(), before);
    expect(
      await fixture.root.list(recursive: true).map((f) => f.path).toList(),
      files,
    );
  });

  test(
    'PNG imports atomically into durable catalogue with non-square grid',
    () async {
      final mapBefore = await fixture.mapFile.readAsBytes();
      final sourceBefore = await fixture.source.readAsBytes();
      final receipt = await fixture.import();
      final tileset = receipt.manifest.tilesets.single;
      final source = tileset.source! as ProjectRegularAtlasTilesetSource;
      expect((source.tileWidth, source.tileHeight), (16, 24));
      expect((source.columns, source.rows), (4, 2));
      expect(receipt.changedPaths, contains('project.json'));
      expect(receipt.changedPaths, isNot(contains('garden.json')));
      expect(
        await File(
          '${fixture.root.path}/${tileset.relativePath}',
        ).readAsBytes(),
        sourceBefore,
      );
      expect(await fixture.source.readAsBytes(), sourceBefore);
      expect(await fixture.mapFile.readAsBytes(), mapBefore);
      expect(receipt.revision, isNot(receipt.beforeRevision));
      final reopened = LocalMapWorkspaceAdapter();
      expect((await reopened.loadProject(fixture.session)).tilesets, [tileset]);
    },
  );

  test(
    'dirty map survives import and saves against accepted receipt',
    () async {
      final loaded = await fixture.loadMap();
      final dirty = loaded.map.copyWith(name: 'Travail conservé');
      final before = await fixture.mapFile.readAsBytes();
      await fixture.import();
      expect(await fixture.mapFile.readAsBytes(), before);
      await fixture.maps.saveMap(fixture.session, loaded, dirty);
      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadProject(fixture.session);
      expect(
        (await reopened.loadMap(fixture.session, ResourceFixture.entry)).map,
        dirty,
      );
    },
  );

  test(
    'first decor category and definition commit together; variant preserves original',
    () async {
      final imported = await fixture.import();
      final element = fixture.element(imported.createdTilesetId!);
      final saved = await fixture.resources.saveElement(element);
      final original = saved.manifest.elements.single;
      expect(saved.manifest.elementCategories.single.id, original.categoryId);
      expect(original.frames, element.frames);
      final variant = original.copyWith(
        id: 'tree_variant',
        name: 'Autre arbre',
      );
      final second = await fixture.resources.saveElement(variant);
      expect(second.manifest.elements, containsAll([original, variant]));
      final reopened = LocalMapWorkspaceAdapter();
      expect(
        (await reopened.loadProject(fixture.session)).elements,
        second.manifest.elements,
      );
    },
  );

  test(
    'invalid grid leaves manifest, source and resource catalogue unpublished',
    () async {
      final before = await fixture.manifestFile.readAsBytes();
      await expectLater(
        fixture.import(tileWidth: 17),
        throwsA(isA<ResourceFailure>()),
      );
      expect(await fixture.manifestFile.readAsBytes(), before);
      expect(await Directory('${fixture.root.path}/assets').exists(), isFalse);
      expect(
        (await fixture.maps.resourceBaseline(
          fixture.session,
        )).manifest.tilesets,
        isEmpty,
      );
    },
  );

  test(
    'external manifest edit blocks import without accepting foreign revision',
    () async {
      final current =
          jsonDecode(await fixture.manifestFile.readAsString())
              as Map<String, dynamic>;
      current['name'] = 'Édition externe';
      await fixture.manifestFile.writeAsString(jsonEncode(current));
      final before = await fixture.manifestFile.readAsBytes();
      await expectLater(fixture.import(), throwsA(isA<ResourceFailure>()));
      expect(await fixture.manifestFile.readAsBytes(), before);
      expect(await Directory('${fixture.root.path}/assets').exists(), isFalse);
    },
  );

  test(
    'external map edit stays protected by map CAS after own import',
    () async {
      final loaded = await fixture.loadMap();
      await fixture.mapFile.writeAsString(
        jsonEncode(loaded.map.copyWith(name: 'Externe').toJson()),
      );
      final external = await fixture.mapFile.readAsBytes();
      await fixture.import();
      await expectLater(
        fixture.maps.saveMap(
          fixture.session,
          loaded,
          loaded.map.copyWith(name: 'Travail local'),
        ),
        throwsException,
      );
      expect(await fixture.mapFile.readAsBytes(), external);
    },
  );

  test('resource API rejects map mutation and preserves map bytes', () async {
    final before = await fixture.mapFile.readAsBytes();
    await expectLater(
      fixture.resources.mutate('map.delete', {'mapId': 'garden'}),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.mapFile.readAsBytes(), before);
  });

  test(
    'unchanged definition can be used without a mutation or lost conflict guard',
    () async {
      final imported = await fixture.import();
      final first = await fixture.resources.saveElement(
        fixture.element(imported.createdTilesetId!),
      );
      final element = first.manifest.elements.single;
      final before = await fixture.manifestFile.readAsBytes();
      final same = await fixture.resources.saveElement(element);
      expect(same.changedPaths, isEmpty);
      expect(same.revision, first.revision);
      expect(same.manifest, first.manifest);
      expect(await fixture.manifestFile.readAsBytes(), before);
      await fixture.manifestFile.writeAsString(
        '${await fixture.manifestFile.readAsString()}\n',
      );
      await expectLater(
        fixture.resources.saveElement(element),
        throwsA(isA<ResourceFailure>()),
      );
    },
  );
}

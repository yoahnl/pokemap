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
        (await fixture.maps.resourceBaseline(fixture.session))
            .manifest
            .tilesets,
        isEmpty,
      );
    },
  );

  test(
    'external manifest edit blocks import without accepting foreign revision',
    () async {
      final current = jsonDecode(
        await fixture.manifestFile.readAsString(),
      ) as Map<String, dynamic>;
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
    'folder organization uses canonical mutation and preserves open maps',
    () async {
      final loaded = await fixture.loadMap();
      final mapBytes = await fixture.mapFile.readAsBytes();
      final receipt = await fixture.resources.mutate('map.library.reorganize', {
        'groups': [
          const ProjectMapGroup(
            id: 'village',
            name: 'Village',
            type: MapGroupType.village,
          ).toJson(),
        ],
        'assignments': [
          {'mapId': 'garden', 'groupId': 'village'},
        ],
      });
      expect(receipt.manifest.maps.single.groupId, 'village');
      expect(receipt.changedPaths, ['project.json']);
      expect(await fixture.mapFile.readAsBytes(), mapBytes);
      final reopened = LocalMapWorkspaceAdapter();
      final manifest = await reopened.loadProject(fixture.session);
      expect(manifest.groups.single.name, 'Village');
      expect(manifest.maps.single.groupId, 'village');
      await fixture.maps.saveMap(
        fixture.session,
        loaded,
        loaded.map.copyWith(name: 'Jardin modifié'),
      );
      expect(
        (await reopened.loadMap(
          fixture.session,
          manifest.maps.single,
        )).map.name,
        'Jardin modifié',
      );
    },
  );

  test('invalid folder move leaves manifest and map unchanged', () async {
    final manifestBytes = await fixture.manifestFile.readAsBytes();
    final mapBytes = await fixture.mapFile.readAsBytes();
    await expectLater(
      fixture.resources.mutate('map.library.reorganize', {
        'assignments': [
          {'mapId': 'garden', 'groupId': 'missing'},
        ],
      }),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.manifestFile.readAsBytes(), manifestBytes);
    expect(await fixture.mapFile.readAsBytes(), mapBytes);
  });

  test('unchanged definition can be used without a mutation or lost conflict guard', () async {
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
  });
}

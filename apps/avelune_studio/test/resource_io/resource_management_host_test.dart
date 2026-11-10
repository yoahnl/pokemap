import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthoringResourceFixture> open({bool noMaps = false}) async {
    final fixture = await AuthoringResourceFixture.create(noMaps: noMaps);
    addTearDown(fixture.dispose);
    return fixture;
  }

  Future<String?> rename(
    AuthoringResourceFixture fixture,
    String name, {
    String? revision,
  }) async {
    final item = resourceCatalog(fixture.workspace.project!)
        .firstWhere((item) => item.tileset != null);
    return publishResourceManagementChange(
      fixture.navigation,
      revision ?? await fixture.navigation.captureResourceRevision(),
      'tileset.metadata.update',
      {'tilesetId': item.id, 'name': name, 'folderId': item.tileset!.folderId},
      reveal: item,
    );
  }

  test(
    'metadata saves and reopens with stable references and image bytes',
    () async {
      final fixture = await open();
      final before = fixture.workspace.project!;
      final image = File(
        '${fixture.directory.path}/${before.tilesets.single.relativePath}',
      );
      final pixels = await image.readAsBytes();
      final maps = await fixture.mapFiles();
      final map = fixture.workspace.active!.current;
      expect(await rename(fixture, 'Été — la planche des rêves'), isNull);
      final reopened = await fixture.reopen();
      final after = reopened.tilesets.single;
      expect(after.name, 'Été — la planche des rêves');
      expect(
        after.copyWith(name: before.tilesets.single.name),
        before.tilesets.single,
      );
      expect(reopened.elements, before.elements);
      expect(reopened.characters, before.characters);
      expect(fixture.workspace.active!.current, map);
      expect(await fixture.mapFiles(), maps);
      expect(await image.readAsBytes(), pixels);
      expect(
        fixture.navigation.library.selectedIdentity,
        'tileset:${after.id}',
      );
      expect(fixture.navigation.library.revealPending, isFalse);
    },
  );

  test(
    'identical metadata publication preserves exact project bytes',
    () async {
      final fixture = await open();
      final file = File('${fixture.directory.path}/project.json');
      final before = await file.readAsString();
      expect(
        await rename(fixture, fixture.workspace.project!.tilesets.single.name),
        isNull,
      );
      expect(await file.readAsString(), before);
    },
  );

  test(
    'metadata rejects a stale captured revision without overwriting disk',
    () async {
      final fixture = await open();
      final revision = await fixture.navigation.captureResourceRevision();
      final file = File('${fixture.directory.path}/project.json');
      final content =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      content['name'] = 'Modification extérieure';
      await file.writeAsString(jsonEncode(content));
      final external = await file.readAsString();
      expect(
        await rename(fixture, 'Mon titre concurrent', revision: revision),
        isNotNull,
      );
      expect(await file.readAsString(), external);
      final reopened = await fixture.reopen();
      expect(reopened.name, 'Modification extérieure');
      expect(
        reopened.tilesets.single.name,
        fixture.workspace.project!.tilesets.single.name,
      );
    },
  );

  test('metadata saves and reopens without an active map', () async {
    final fixture = await open(noMaps: true);
    expect(fixture.workspace.active, isNull);
    expect(await rename(fixture, 'Planche sans carte'), isNull);
    final reopened = await fixture.reopen();
    expect(reopened.tilesets.single.name, 'Planche sans carte');
    expect(reopened.maps, isEmpty);
  });
}

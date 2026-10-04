import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/uwu4_resource_host.dart';

void main() {
  testWidgets('cancelling the prepared source withdrawal writes nothing', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    await host.action('decors:tree', 'Supprimer la définition…');
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    final before = await host.reopen();
    final root = host.fixture.directory.path;
    final paths = [
      'project.json',
      'assets/.pokemap-assets.json',
      before.tilesets.single.relativePath,
    ];
    final bytes = (await tester.runAsync(
      () => Future.wait(paths.map((path) => File('$root/$path').readAsBytes())),
    ))!;
    await host.family(ResourceKind.images);
    await host.action(
      'images:${before.tilesets.single.id}',
      'Supprimer la planche…',
    );
    await host.tap('resource-removal-source');
    final watch = Stopwatch()..start();
    await host.tap('resource-management-cancel');
    watch.stop();
    debugPrint('UWU5_SOURCE_CANCEL_HOST_US=${watch.elapsedMicroseconds}');
    expect(find.byKey(const ValueKey('resource-removal-source')), findsNothing);
    expect((await host.reopen()).tilesets, before.tilesets);
    for (var index = 0; index < paths.length; index++) {
      expect(
        await tester.runAsync(File('$root/${paths[index]}').readAsBytes),
        bytes[index],
      );
    }
  });

  testWidgets('source removal can return to definition-only after analysis', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = await host.reopen();
    final sourceFile = File(
      '${host.fixture.directory.path}/${before.tilesets.single.relativePath}',
    );
    final sourceBytes = (await tester.runAsync(sourceFile.readAsBytes))!;
    final catalogFile = File(
      '${host.fixture.directory.path}/assets/.pokemap-assets.json',
    );
    final catalogBytes = (await tester.runAsync(catalogFile.readAsBytes))!;
    await host.action('decors:tree', 'Supprimer la définition…');
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    await host.family(ResourceKind.images);
    await host.action(
      'images:${before.tilesets.single.id}',
      'Supprimer la planche…',
    );
    final source = find.byKey(const ValueKey('resource-removal-source'));
    expect(tester.widget<CheckboxListTile>(source).value, isFalse);
    await host.tap('resource-removal-source');
    expect(tester.widget<CheckboxListTile>(source).value, isTrue);
    expect(tester.widget<CheckboxListTile>(source).onChanged, isNotNull);
    expect(find.text('Le fichier source restera intact.'), findsNothing);
    await host.tap('resource-removal-source');
    expect(tester.widget<CheckboxListTile>(source).value, isFalse);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('resource-removal-confirm')),
          )
          .value,
      isFalse,
    );
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    expect((await host.reopen()).tilesets, isEmpty);
    expect(await tester.runAsync(sourceFile.readAsBytes), sourceBytes);
    expect(await tester.runAsync(catalogFile.readAsBytes), catalogBytes);
  });

  testWidgets(
    'confirmed source removal applies the announced logical effects',
    (tester) async {
      final host = await openUwU4ResourceHost(tester);
      final before = await host.reopen();
      final sourcePath = before.tilesets.single.relativePath;
      final sourceFile = File('${host.fixture.directory.path}/$sourcePath');
      final catalogFile = File(
        '${host.fixture.directory.path}/assets/.pokemap-assets.json',
      );
      final catalog =
          jsonDecode((await tester.runAsync(catalogFile.readAsString))!)
              as Map<String, dynamic>;
      expect(catalog['records'], hasLength(1));
      await host.action('decors:tree', 'Supprimer la définition…');
      await host.tap('resource-removal-confirm');
      await host.tap('resource-management-save');
      await host.family(ResourceKind.images);
      await host.action(
        'images:${before.tilesets.single.id}',
        'Supprimer la planche…',
      );
      await host.tap('resource-removal-source');
      final addressed = sourcePath.startsWith('assets/.pokemap-store/');
      expect(
        find.textContaining(
          addressed
              ? 'fichier adressé par contenu'
              : 'son fichier seront retirés',
        ),
        findsOneWidget,
      );
      await host.fixture.capture(tester, 'uwu5-host-source-removal');
      await host.tap('resource-removal-confirm');
      await host.tap('resource-management-save');
      expect((await host.reopen()).tilesets, isEmpty);
      final after =
          jsonDecode((await tester.runAsync(catalogFile.readAsString))!)
              as Map<String, dynamic>;
      expect(after['records'], isEmpty);
      expect(await tester.runAsync(sourceFile.exists), addressed);
    },
  );
}

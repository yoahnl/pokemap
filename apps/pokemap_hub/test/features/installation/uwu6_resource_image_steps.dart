import 'dart:io';

import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'uwu6_resource_host.dart';

Future<({String sheetId, String decorId, String placedId})> editUwu6Images(
  Uwu6ResourceHost host,
) async {
  final tester = host.tester;
  await host.go('Ressources');
  await host.family(ResourceKind.images);
  await host.text('Importer une image');
  await host.text('Importer');
  final imported = host.fixture.controller.project!.tilesets.singleWhere(
    (item) => item.name == 'Planche témoin UwU VI',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Nom du décor'),
    'Décor rouge témoin',
  );
  await host.text('Enregistrer et utiliser');
  final original = host.fixture.controller.project!.elements.singleWhere(
    (item) => item.name == 'Décor rouge témoin',
  );
  await host.cell(4, 6);
  final placed = host.fixture.controller.active!.current.placedElements
      .singleWhere((item) => item.elementId == original.id);
  await host.saveMap();
  await host.go('Ressources');
  await host.family(ResourceKind.decors);
  await host.action('decors:${original.id}', 'Dupliquer la définition…');
  await host.enter('resource-duplicate-name', 'Copie traversable');
  await host.tap('resource-management-save');
  final copy = host.fixture.controller.project!.elements.singleWhere(
    (item) => item.name == 'Copie traversable',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Nom du décor'),
    'Copie indépendante éditée',
  );
  await host.text('Traversable');
  await host.text('Enregistrer et utiliser');
  final afterCopy = await host.reopen();
  expect(
    afterCopy.elements.singleWhere((item) => item.id == original.id),
    original,
  );
  expect(copy.id, isNot(original.id));
  expect(
    afterCopy.elements.singleWhere((item) => item.id == copy.id).name,
    'Copie indépendante éditée',
  );
  expect(
    host.fixture.controller.active!.current.placedElements
        .singleWhere((item) => item.id == placed.id)
        .elementId,
    original.id,
  );

  await host.go('Ressources');
  await host.family(ResourceKind.images);
  final decoder = host.fixture.visuals!.store.decoder;
  final reads = decoder.reads;
  final decodes = decoder.decodes;
  final metadata = Stopwatch()..start();
  await host.action('images:${imported.id}', 'Modifier les informations');
  await host.enter('resource-information-name', 'Planche émeraude — témoin');
  await host.tap('resource-management-save');
  await host.tap('resource-manage-containers');
  await host.tap('resource-container-create');
  await host.enter('resource-container-name', 'Témoins visuels');
  await host.tap('resource-management-save');
  final folder = host.fixture.controller.project!.tilesetFolders.singleWhere(
    (entry) => entry.name == 'Témoins visuels',
  );
  await host.text('Retour aux ressources');
  await host.action('images:${imported.id}', 'Déplacer vers…');
  await host.choose('resource-move-destination', 'Témoins visuels');
  await host.tap('resource-management-save');
  final named = (await host.reopen()).tilesets.singleWhere(
    (entry) => entry.id == imported.id,
  );
  expect(
    named.copyWith(name: imported.name, folderId: imported.folderId),
    imported,
  );
  expect(named.folderId, folder.id);
  metadata.stop();
  expect(
    decoder.decodes,
    decodes,
    reason: 'Changing title and folder must preserve decoded pixels.',
  );
  print(
    'UWU6_RESOURCE_METADATA_US=${metadata.elapsedMicroseconds} reads=${decoder.reads - reads} decodes=${decoder.decodes - decodes}',
  );
  host.replacement = true;
  final before = await tester.runAsync(
    () =>
        File(
          p.join(host.fixture.directory.path, imported.relativePath),
        ).readAsBytes(),
  );
  expect(before, host.oldPixels);
  await host.action('images:${imported.id}', 'Remplacer l’image source…');
  expect(find.text('Actuellement'), findsOneWidget);
  expect(find.text('Après remplacement'), findsOneWidget);
  await host.fixture.capture(tester, 'uwu6-widget-image-replacement');
  await host.tap('resource-replacement-confirm');
  await host.tap('resource-management-save');
  final after = (await host.reopen()).tilesets.singleWhere(
    (entry) => entry.id == imported.id,
  );
  final newBytes = await tester.runAsync(
    () =>
        File(
          p.join(host.fixture.directory.path, after.relativePath),
        ).readAsBytes(),
  );
  expect(newBytes, host.newPixels);
  expect(after.id, imported.id);
  expect(after.source, imported.source);
  expect(newBytes, isNot(before));
  expect(after.folderId, folder.id);
  expect(after.name, 'Planche émeraude — témoin');
  print(
    'UWU6_RESOURCE_IMAGE_UI imported=${imported.id} decor=${original.id} copy=${copy.id} instance=${placed.id}',
  );
  return (sheetId: imported.id, decorId: original.id, placedId: placed.id);
}

Future<void> inspectUwu6ClosedUsages(
  Uwu6ResourceHost host,
  String sheetId,
  String placedId,
  String closedMapId,
) async {
  expect(host.fixture.controller.documents.containsKey(closedMapId), false);
  await host.go('Ressources');
  await host.family(ResourceKind.images);
  await host.action('images:$sheetId', 'Voir les usages dans le projet');
  await host.tap('resource-usage-analyze');
  final report =
      host.tester
          .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
          .report!;
  expect(report.complete, true);
  expect(
    report.entries.any(
      (entry) => entry.mapId == closedMapId && entry.entityId == placedId,
    ),
    true,
  );
  expect(report.entries.any((entry) => entry.ownerId.isNotEmpty), true);
  expect(host.fixture.controller.documents.containsKey(closedMapId), false);
  await host.fixture.capture(host.tester, 'uwu6-widget-closed-map-usages');
  await host.text('Retour aux ressources');
  print(
    'UWU6_RESOURCE_CLOSED_MAP_UI=$closedMapId entries=${report.entries.length}',
  );
}

import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_containers.dart';
import 'package:avelune_studio/features/resources/application/resource_image_import_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_definition_lifecycle.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_workspace_import_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/platform/rendering/resource_image_content_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/run_resource_replacement.dart';
import 'uwu6_resource_host.dart';

Future<({String sheetId, String decorId, String placedId})> editUwu6Images(
  Uwu6ResourceHost host,
) => host.io(() async {
  final navigation = host.navigation;
  final controller = host.fixture.controller;
  final imported = await ResourceWorkspaceImportWorkflow(
    navigation: navigation,
    isActive: () => true,
  ).importImage(
    picker: host.pickImage,
    intent: ResourceImportIntent.decor,
    confirm: (image, project) async {
      final draft = ResourceImageImportDraft(
        image: image,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        existingNames: {for (final tileset in project.tilesets) tileset.name},
      );
      try {
        await draft.verify(verifyResourceImageContent);
        return draft.build();
      } finally {
        draft.dispose();
      }
    },
  );
  expect(imported, true, reason: navigation.error);
  final sheet = controller.project!.tilesets.singleWhere(
    (item) => item.name == 'Planche témoin UwU VI',
  );
  final decor = navigation.decor!;
  expect(decor.tileset.id, sheet.id);
  decor.name = 'Décor rouge témoin';
  final beforeSave = controller.active!.current;
  await navigation.saveDecor(decor.build());
  expect(navigation.error, isNull);
  final original = controller.project!.elements.singleWhere(
    (item) => item.name == 'Décor rouge témoin',
  );
  expect(controller.active!.current, beforeSave);
  expect(navigation.library.selectedIdentity, 'element:${original.id}');
  final document = controller.active!;
  final placedId = MapEditingCommands(
    document,
    controller.project!,
  ).place(original, const GridPos(x: 4, y: 6));
  expect(placedId, isNotNull, reason: document.error);
  controller.notify();
  final placed = document.current.placedElements.singleWhere(
    (item) => item.elementId == original.id,
  );
  expect(await controller.save(document), true, reason: document.error);
  expect(document.dirty, false, reason: document.error);
  await runResourceDefinitionDuplicate(
    navigation: navigation,
    item: _item(controller.project!, (item) => item.element?.id == original.id),
    isActive: () => true,
    confirmOwnerSave: () async => true,
    present: (session) async {
      session.name = 'Copie traversable';
      expect(await session.apply(), isNull);
    },
  );
  expect(navigation.error, isNull);
  final copy = controller.project!.elements.singleWhere(
    (item) => item.name == 'Copie traversable',
  );
  final copyDraft = navigation.decor!;
  expect(copyDraft.original?.id, copy.id);
  copyDraft.name = 'Copie indépendante éditée';
  copyDraft.setBlocked(false);
  final beforeCopySave = controller.active!.current;
  await navigation.saveDecor(copyDraft.build());
  expect(navigation.error, isNull);
  expect(controller.active!.current, beforeCopySave);
  final afterCopy = await host.read();
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
    controller.active!.current.placedElements
        .singleWhere((item) => item.id == placed.id)
        .elementId,
    original.id,
  );

  final decoder = host.fixture.visuals!.store.decoder;
  final reads = decoder.reads;
  final decodes = decoder.decodes;
  final metadata = Stopwatch()..start();
  expect(
    await publishResourceManagementChange(
      navigation,
      await navigation.captureResourceRevision(),
      'tileset.metadata.update',
      {
        'tilesetId': sheet.id,
        'name': 'Planche émeraude — témoin',
        'folderId': sheet.folderId,
      },
    ),
    isNull,
  );
  expect(
    await publishResourceManagementChange(
      navigation,
      await navigation.captureResourceRevision(),
      containerAction(ResourceKind.images, 'upsert'),
      containerParameters(
        ResourceKind.images,
        const ResourceContainer('uwu6-witnesses', 'Témoins visuels', null, 0),
      ),
    ),
    isNull,
  );
  final folder = controller.project!.tilesetFolders.singleWhere(
    (entry) => entry.name == 'Témoins visuels',
  );
  navigation.showLibrary();
  final (moveAction, moveParameters) = resourceMoveParameters(
    _item(controller.project!, (item) => item.tileset?.id == sheet.id),
    folder.id,
  );
  expect(
    await publishResourceManagementChange(
      navigation,
      await navigation.captureResourceRevision(),
      moveAction,
      moveParameters,
    ),
    isNull,
  );
  final named = (await host.read()).tilesets.singleWhere(
    (entry) => entry.id == sheet.id,
  );
  expect(named.copyWith(name: sheet.name, folderId: sheet.folderId), sheet);
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
  final before = await File(
    p.join(host.fixture.directory.path, sheet.relativePath),
  ).readAsBytes();
  expect(before, host.oldPixels);
  await runReplacementForTest(
    navigation: navigation,
    item: _item(controller.project!, (item) => item.tileset?.id == sheet.id),
    picker: host.pickImage,
    isActive: () => true,
    present: (session) async {
      expect(session.preview.beforeBytes, host.oldPixels);
      expect(session.preview.candidateBytes, host.newPixels);
      session.confirm(true);
      expect(await session.apply(), isNull);
    },
  );
  final after = (await host.read()).tilesets.singleWhere(
    (entry) => entry.id == sheet.id,
  );
  final newBytes = await File(
    p.join(host.fixture.directory.path, after.relativePath),
  ).readAsBytes();
  expect(newBytes, host.newPixels);
  expect(after.id, sheet.id);
  expect(after.source, sheet.source);
  expect(newBytes, isNot(before));
  expect(after.folderId, folder.id);
  expect(after.name, 'Planche émeraude — témoin');
  print(
    'UWU6_RESOURCE_IMAGE_OWNER imported=${sheet.id} decor=${original.id} copy=${copy.id} instance=${placed.id}',
  );
  return (sheetId: sheet.id, decorId: original.id, placedId: placed.id);
});

Future<void> inspectUwu6ClosedUsages(
  Uwu6ResourceHost host,
  String sheetId,
  String placedId,
  String closedMapId,
) => host.io(() async {
  final navigation = host.navigation;
  final controller = host.fixture.controller;
  expect(controller.documents.containsKey(closedMapId), false);
  final usages = ResourceUsageController(
    target: resourceUsageTargetFor(
      _item(controller.project!, (item) => item.tileset?.id == sheetId),
    ),
    port: navigation.usages,
    dirtyOwners: () => navigation.usageDraftOwners,
    openOwner: navigation.openUsageOwner,
    canOpenOwner: navigation.canOpenUsageOwner,
    changed: () {},
  );
  try {
    await usages.analyze();
    expect(usages.error, isNull);
    final report = usages.report!;
    expect(report.complete, true);
    expect(
      report.entries.any(
        (entry) => entry.mapId == closedMapId && entry.entityId == placedId,
      ),
      true,
    );
    expect(report.entries.any((entry) => entry.ownerId.isNotEmpty), true);
    expect(controller.documents.containsKey(closedMapId), false);
    print(
      'UWU6_RESOURCE_CLOSED_MAP_OWNER=$closedMapId entries=${report.entries.length}',
    );
  } finally {
    usages.dispose();
  }
});

ResourceItem _item(ProjectManifest project, bool Function(ResourceItem) test) =>
    resourceCatalog(project).singleWhere(test);

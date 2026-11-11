import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_containers.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core_domain.dart';

import '../support/resource_owner_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('actual import decor owner publication placement closed map usages metadata organization and reopen', () async {
    final host = await ResourceOwnerHost.create();
    final navigation = host.navigation;
    final workspace = host.workspace;
    final fixture = host.fixture;
    final pixels = image.Image(width: 64, height: 48);
    image.fill(pixels, color: image.ColorRgb8(30, 160, 70));
    final source = File('${fixture.root.path}/journey-source.png');
    await source.writeAsBytes(image.encodePng(pixels));

    await navigation.import(
      ResourceImageImport(
        sourcePath: source.path,
        name: 'Planche pilote',
        tileWidth: workspace.project!.settings.tileWidth,
        tileHeight: workspace.project!.settings.tileHeight,
      ),
      intent: ResourceImportIntent.source,
    );
    expect(navigation.error, isNull);
    final imported = workspace.project!.tilesets.singleWhere(
      (item) => item.name == 'Planche pilote',
    );
    expect(navigation.importedSource?.tileset?.id, imported.id);
    expect(navigation.decor, isNull);
    final png = File('${fixture.root.path}/${imported.relativePath}');
    final pngBytes = await png.readAsBytes();

    navigation.edit(
      resourceCatalog(workspace.project!)
          .singleWhere((item) => item.tileset?.id == imported.id),
    );
    expect(navigation.importedSource, isNull);
    expect(navigation.decor!.tileset.id, imported.id);
    final draft = navigation.decor!..name = 'Décor pilote';
    final beforeSave = workspace.active!.current;
    await navigation.saveDecor(draft.build());
    expect(navigation.error, isNull);
    final element = workspace.project!.elements.singleWhere(
      (item) => item.name == 'Décor pilote',
    );
    expect(element.tilesetId, imported.id);
    expect(workspace.active!.current, beforeSave);
    expect(navigation.library.selectedIdentity, 'element:${element.id}');

    final document = workspace.active!;
    final placedId = MapEditingCommands(document, workspace.project!).place(
      element,
      const GridPos(x: 1, y: 1),
    );
    expect(placedId, isNotNull);
    final placed = document.current.placedElements.singleWhere(
      (item) => item.elementId == element.id,
    );
    expect(document.dirty, isTrue);
    expect(await workspace.save(document), isTrue);
    expect(document.dirty, isFalse);
    final savedMap = document.current;

    final reader = LocalMapWorkspaceAdapter();
    await reader.loadProject(fixture.session);
    final closedMaps = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: reader,
    );
    addTearDown(closedMaps.dispose);
    final report = await closedMaps.usages.analyze(
      resourceUsageTargetFor(
        resourceCatalog(workspace.project!)
            .singleWhere((item) => item.tileset?.id == imported.id),
      ),
    );
    expect(report.complete, isTrue);
    expect(
      report.entries.any(
        (entry) => entry.mapId == 'garden' && entry.entityId == placed.id,
      ),
      isTrue,
    );

    expect(
      await publishResourceManagementChange(
        navigation,
        await navigation.captureResourceRevision(),
        'tileset.metadata.update',
        {
          'tilesetId': imported.id,
          'name': 'Planche du jardin',
          'folderId': imported.folderId,
        },
      ),
      isNull,
    );
    Future<String?> storeFolder(ResourceContainer folder) async =>
        publishResourceManagementChange(
          navigation,
          await navigation.captureResourceRevision(),
          containerAction(ResourceKind.images, 'upsert'),
          containerParameters(ResourceKind.images, folder),
        );
    const createdFolder = ResourceContainer(
      'journey-plants',
      'Images végétales',
      null,
      0,
    );
    expect(await storeFolder(createdFolder), isNull);
    const renamedFolder = ResourceContainer(
      'journey-plants',
      'Végétation',
      null,
      0,
    );
    expect(await storeFolder(renamedFolder), isNull);
    final folder = workspace.project!.tilesetFolders.single;
    final (moveAction, moveParameters) = resourceMoveParameters(
      resourceCatalog(workspace.project!)
          .singleWhere((item) => item.tileset?.id == imported.id),
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
    expect(
      await deleteResourceContainer(navigation, ResourceKind.images, renamedFolder),
      isNotNull,
    );
    const empty = ResourceContainer(
      'journey-empty',
      'Dossier temporaire',
      null,
      0,
    );
    expect(await storeFolder(empty), isNull);
    expect(
      await deleteResourceContainer(navigation, ResourceKind.images, empty),
      isNull,
    );

    final reopened = await host.reopen();
    final after = reopened.tilesets.singleWhere(
      (item) => item.id == imported.id,
    );
    expect(after.name, 'Planche du jardin');
    expect(after.folderId, folder.id);
    expect(
      after.copyWith(name: imported.name, folderId: imported.folderId),
      imported,
    );
    expect(reopened.tilesetFolders.single.name, 'Végétation');
    expect(
      reopened.elements.singleWhere((item) => item.id == element.id),
      element,
    );
    expect(await png.readAsBytes(), pngBytes);
    final independent = LocalMapWorkspaceAdapter();
    final manifest = await independent.loadProject(fixture.session);
    final reloaded = await independent.loadMap(
      fixture.session,
      manifest.maps.singleWhere((entry) => entry.id == 'garden'),
    );
    expect(reloaded.map, savedMap);
  });
}

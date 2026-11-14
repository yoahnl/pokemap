import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import 'resource_pack_import_host_fixture.dart';
export 'resource_pack_import_host_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('valid 3D project imports the global eight resources and thirteen supports then reopens after session close', () async {
    final camera = SpatialCameraProfile();
    final map = MapData(
      id: 'spatial-room',
      name: 'Spatial room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 6),
      layers: const [],
      spatialScene: MapSpatialScene(width: 8, depth: 6, camera: camera),
    );
    final target = ProjectManifest(
      name: 'Spatial pack target',
      version: ProjectVersion.v9,
      tilesets: [],
      maps: [
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'spatial-room.json',
        ),
      ],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: camera,
        tileWidth: 2,
        tileHeight: 2,
      ),
    );
    ProjectValidator.validate(target, maps: [map]);
    MapValidator.validate(map, projectDialogueContext: target);
    final source = await ResourcePackImportFixture.create(target: target);
    final host = await ResourcePackTestHost.create(
      sourceFixture: source,
      initialMap: map,
    );
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/spatial-room.json');
    final mapBefore = await mapFile.readAsBytes();
    await host.prepare();
    expect(host.transfer.error, isNull);
    expect(host.transfer.preparedSummary['resourceCount'], 8);
    expect(host.transfer.preparedSummary['supportCount'], 13);
    expect(host.transfer.canApply, isTrue);
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    expect(host.transfer.requiresReconciliation, isFalse);
    expect(host.navigation.pendingReceipt, isNull);
    final installed = host.workspace.project!;
    expect(installed.tilesets, hasLength(1));
    expect(installed.elements, hasLength(2));
    expect(installed.models3d, hasLength(1));
    expect(installed.characters, hasLength(1));
    expect(installed.smartTileCatalog.presets, hasLength(1));
    expect(installed.borderCatalog.records, hasLength(1));
    expect(installed.environmentPresets, hasLength(1));
    expect(
      installed.resourcePackInstallations.entries.single.resources,
      hasLength(8),
    );
    expect(
      installed.resourcePackInstallations.entries.single.supports,
      hasLength(13),
    );
    final projectAfterImport = await host.manifestFile.readAsBytes();
    expect(await host.transfer.requestClose(), isTrue);
    await host.closeSession();
    final reopenedAdapter = LocalMapWorkspaceAdapter();
    final reopened = await reopenedAdapter.loadProject(host.session);
    final reopenedMap = (await reopenedAdapter.loadMap(
      host.session,
      reopened.maps.single,
    )).map;
    ProjectValidator.validate(reopened, maps: [reopenedMap]);
    MapValidator.validate(reopenedMap, projectDialogueContext: reopened);
    expect(reopened, installed);
    expect(reopened.settings.dimension, ProjectDimension.threeD);
    expect(reopened.settings.spatialCamera, camera);
    expect(reopenedMap.spatialScene!.camera, camera);
    expect(reopenedMap, map);
    expect(await mapFile.readAsBytes(), mapBefore);
    expect(await host.manifestFile.readAsBytes(), projectAfterImport);
  });
  test('additional roots in an existing installation reveal a newly added native resource', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.transfer.beginImport();
    await host.transfer.setFilter(kind: 'element');
    await host.transfer.selectFiltered();
    await host.transfer.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    expect(host.transfer.addedCount, greaterThan(0));
    expect(host.transfer.firstImported, isNotNull);
    final selected = host.transfer.firstImported!;
    expect(selected.kind, isNot('element'));
  });
  test('real archive installs seven native kinds and supports, reopens and reimports without apply', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.prepare();
    expect(host.transfer.canApply, isTrue);
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    final receipt = host.navigation.workspace.project!;
    expect(receipt.tilesets, isNotEmpty);
    expect(receipt.elements, isNotEmpty);
    expect(receipt.models3d, isNotEmpty);
    expect(receipt.characters, isNotEmpty);
    expect(receipt.smartTileCatalog.presets, isNotEmpty);
    expect(receipt.smartTileCatalog.atlases, isNotEmpty);
    expect(receipt.smartTileCatalog.materials, isNotEmpty);
    expect(receipt.borderCatalog.records, isNotEmpty);
    expect(receipt.environmentPresets, isNotEmpty);
    final reopened = await host.reopen();
    expect(reopened, receipt);
    await host.navigation.mutate('resource.classify', {
      'resourceKind': 'element',
      'resourceId': receipt.elements.first.id,
      'placementContext': 'interior',
    });
    final before = await host.manifestFile.readAsBytes();
    await host.prepare();
    expect(host.transfer.canApply, isFalse);
    expect(host.transfer.notice, contains('déjà installées'));
    expect(await host.manifestFile.readAsBytes(), before);
    expect(
      (await host.reopen()).resourceLibraryCatalog
          .entryFor('element', receipt.elements.first.id)
          ?.placementContext,
      ResourcePlacementContext.interior,
    );
  });
}

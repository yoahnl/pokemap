import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_spatial_map_selection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

const qaRoot = '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r3';

void main() {
  tearDownAll(() async {
    final root = Directory(qaRoot);
    if (await root.exists() && await root.list().isEmpty) await root.delete();
  });

  test(
      'catalog admission recurses only through supported common-map operations',
      () {
    final valid = _operation('valid').toBatchParameters();
    expect(
        CatalogSpatialMapSelection.supports('map3d.edit_batch',
            parameters: valid),
        isTrue);
    for (final action in [
      'map3d.edit_batch',
      'map.save',
      'border_blueprint.create'
    ]) {
      expect(
          CatalogSpatialMapSelection.supports('map3d.edit_batch', parameters: {
            ...valid,
            'operations': [
              {'actionId': action, 'actionVersion': 1, 'parameters': {}}
            ],
          }),
          isFalse);
    }
    expect(CatalogSpatialMapSelection.supports('map3d.instance.delete_batch'),
        isTrue);
  });

  for (final storage in ReliabilityStorage.values) {
    test('$storage map edit persists and reopens through the real facade',
        () async {
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.interiorHole,
          storage: storage,
          qaRoot: qaRoot);
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      fixture.reader.paths.clear();
      final result = await fixture.api.mapEdit(
          fixture.opened.projectHandle, _operation('persist-${storage.name}'));
      expect(result['status'], 'applied');
      expect(
          fixture.reader.paths.where((path) =>
              path.endsWith('.glb') ||
              path.endsWith('.png') ||
              path.startsWith('maps/') && path != 'maps/map.json'),
          isEmpty);
      await fixture.reopen();
      final map = await fixture.readMap();
      final terrain = map.layers.whereType<SmartTileLayer>().single;
      expect(smartTileMaterialIdAt(terrain, mapSize: map.size, x: 12, y: 8),
          'grass');
      final replay = await fixture.api.mapEdit(
          fixture.opened.projectHandle, _operation('persist-${storage.name}'));
      expect(replay['status'], 'applied');
      expect(replay['operationId'], result['operationId']);
    });

    test('$storage unchanged edits produce no map writes and survive reopen',
        () async {
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.healthy,
          storage: storage,
          qaRoot: qaRoot);
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final before = await fixture.mapFile.readAsBytes();
      final result = await fixture.api.mapEdit(
          fixture.opened.projectHandle, _operation('no-op-${storage.name}'));
      expect(result['status'], 'unchanged');
      expect(await fixture.mapFile.readAsBytes(), before);
      await fixture.reopen();
      final replay = await fixture.api.mapEdit(
          fixture.opened.projectHandle, _operation('no-op-${storage.name}'));
      expect(replay['status'], 'unchanged');
      expect(await fixture.mapFile.readAsBytes(), before);
    });
  }

  for (final unrelated in [0, 90]) {
    test(
        'native scoped map reads ignore $unrelated foreign maps and invalid resources',
        () async {
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.interiorHole, qaRoot: qaRoot);
      addTearDown(fixture.dispose);
      final file = File('${fixture.root.path}/project.json');
      final project =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (project['maps'] as List).addAll([
        for (var i = 0; i < unrelated; i++)
          {
            'id': 'foreign-$i',
            'name': 42,
            'relativePath': 'maps/foreign-$i.json'
          }
      ]);
      (project['models3d'] as List).addAll([
        for (var i = 0; i < unrelated; i++)
          {'id': 'foreign-model-$i', 'name': 42}
      ]);
      await file.writeAsString(jsonEncode(project));
      fixture.reader.paths.clear();
      final selected = await fixture.api.readWorkshopSnapshot(
          fixture.opened.projectHandle,
          actionId: 'map3d.edit_batch',
          parameters: _operation('scope').toBatchParameters());
      expect(selected.maps.map((m) => m.id), ['map']);
      expect(selected.manifest.maps.map((m) => m.id), ['map']);
      expect(selected.manifest.models3d.map((m) => m.id),
          isNot(contains(startsWith('foreign-'))));
      expect(fixture.reader.paths.toSet(), {'project.json', 'maps/map.json'});
    });
  }
}

MapEditOperation _operation(String id) =>
    MapEditOperation(operationId: id, mapId: 'map', operations: const [
      {
        'actionId': 'smart_tile.cell.paint',
        'actionVersion': 1,
        'parameters': {
          'layerId': 'terrain',
          'materialId': 'grass',
          'cells': [
            {'x': 12, 'y': 8}
          ],
        }
      }
    ]);

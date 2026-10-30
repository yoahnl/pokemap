import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

const _qaRoot = '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r3';

void main() {
  tearDownAll(() async {
    final root = Directory(_qaRoot);
    if (await root.exists() && await root.list().isEmpty) await root.delete();
  });
  for (final storage in ReliabilityStorage.values) {
    test(
        '$storage JSONL map_edit previews applies reopens and replays by operationId',
        () async {
      final fixture = await ReliabilityMapFixture.create(
          variant: ReliabilityMapVariant.interiorHole,
          storage: storage,
          qaRoot: _qaRoot);
      addTearDown(fixture.dispose);
      await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
      final before = await fixture.mapFile.readAsBytes();
      final request = <String, Object?>{
        'operationId': 'jsonl-${storage.name}',
        'mapId': 'map',
        'operations': [
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
          },
        ],
      };
      final preview = await fixture.command('map_edit', {
        'projectHandle': fixture.opened.projectHandle.value,
        ...request,
        'dryRun': true,
      });
      expect(preview.status, AuthoringResultStatus.success,
          reason: preview.toJson().toString());
      expect(preview.data['status'], 'planned');
      expect(await fixture.mapFile.readAsBytes(), before);
      final result = await fixture.command('map_edit', {
        'projectHandle': fixture.opened.projectHandle.value,
        ...request,
      });
      expect(result.status, AuthoringResultStatus.success,
          reason: result.toJson().toString());
      expect(result.data['status'], 'applied');
      final applied = await fixture.mapFile.readAsBytes();
      expect(applied, isNot(before));
      await fixture.reopen();
      final map = await fixture.readMap();
      expect(
          smartTileMaterialIdAt(map.layers.whereType<SmartTileLayer>().single,
              mapSize: map.size, x: 12, y: 8),
          'grass');
      final replay = await fixture.command('map_edit', {
        'projectHandle': fixture.opened.projectHandle.value,
        ...request,
      });
      expect(replay.status, AuthoringResultStatus.success,
          reason: replay.toJson().toString());
      expect(replay.data['operationId'], result.data['operationId']);
      expect(replay.data['receipt'], result.data['receipt']);
      expect(await fixture.mapFile.readAsBytes(), applied);
      final invalid = await fixture.command('map_edit', {
        'projectHandle': fixture.opened.projectHandle.value,
        ...request,
        'operationId': 'invalid-${storage.name}',
        'operations': [
          {
            'actionId': 'smart_tile.cell.paint',
            'actionVersion': 1,
            'parameters': {
              'layerId': 'terrain',
              'materialId': 'sea',
              'cells': [
                {'x': 11, 'y': 8}
              ],
            }
          },
          {
            'actionId': 'smart_tile.cell.paint',
            'actionVersion': 1,
            'parameters': {
              'layerId': 'terrain',
              'materialId': 'missing',
              'cells': [
                {'x': 12, 'y': 8}
              ],
            }
          },
        ],
      });
      expect(invalid.status, AuthoringResultStatus.failure);
      expect(invalid.error!.details['domainCode'],
          'map3d.edit_batch.operation_failed');
      expect(await fixture.mapFile.readAsBytes(), applied);
      expect(request.containsKey('planId'), isFalse);
    });
  }
}

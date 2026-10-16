import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';

void main() {
  test(
    'regional draft preserves navigation, undo and abandon without publication',
    () async {
      final port = MemoryRegionalMapPort();
      final controller = RegionalMapController(port, changed: () {});
      await controller.load();
      controller.createRegion('Kanto');
      final id = controller.region!.id;
      controller.editRegion(imagePath: 'assets/region.png');
      controller.createPoint('Town', 'town');
      expect(controller.dirty, isTrue);
      controller.editPoint(u: .7, v: .2);
      expect(controller.point!.u, .7);
      controller.undo();
      expect(controller.point!.u, .5);
      expect(controller.region!.id, id);
      controller.discard();
      expect(controller.dirty, isFalse);
      expect(controller.catalog.regions, isEmpty);
      expect(port.actions, isEmpty);
    },
  );
  test('regional publication uses region and POI semantics and rejects an unpublished spawn map', () async {
    final port = MemoryRegionalMapPort();
    var mapDirty = true;
    final controller = RegionalMapController(
      port,
      changed: () {},
      mapDraftProblem: (_) => mapDirty ? 'Carte en brouillon.' : null,
    );
    await controller.load();
    controller.createRegion('Kanto');
    controller.editRegion(imagePath: 'assets/region.png');
    controller.createPoint('Town', 'town');
    controller.editPoint(
      destination: ProjectRegionDestination(mapId: 'town', spawnId: 'arrival'),
    );
    expect(await controller.saveAll(), isFalse);
    expect(controller.error, contains('brouillon'));
    expect(port.actions, isEmpty);
    mapDirty = false;
    expect(await controller.saveAll(), isTrue);
    expect(port.actions, [
      'regionalMap.region.upsert',
      'regionalMap.poi.upsert',
    ]);
    expect(controller.dirty, isFalse);
    controller.editPoint(label: 'Changed');
    port.fail = true;
    expect(await controller.saveAll(), isFalse);
    expect(controller.dirty, isTrue);
    expect(controller.point!.label, 'Changed');
  });
  test(
    'missing image or exact spawn remains an explicit invalid draft',
    () async {
      final port = MemoryRegionalMapPort();
      final controller = RegionalMapController(port, changed: () {});
      await controller.load();
      controller.createRegion('Kanto');
      expect(await controller.saveAll(), isFalse);
      expect(controller.error, contains('image'));
      controller.editRegion(imagePath: 'assets/region.png');
      controller.createPoint('Town', 'town');
      controller.editPoint(label: '');
      expect(await controller.saveAll(), isFalse);
      expect(controller.dirty, isTrue);
      expect(controller.pointLabel, '');
      expect(controller.error, contains('noms'));
      controller.editPoint(label: 'Town');
      controller.editPoint(
        destination: ProjectRegionDestination(
          mapId: 'town',
          spawnId: 'deleted',
        ),
      );
      expect(await controller.saveAll(), isFalse);
      expect(controller.error, contains('arrivée'));
      expect(port.actions, isEmpty);
    },
  );
}

final class MemoryRegionalMapPort implements RegionalMapPort {
  ProjectManifest project = ProjectManifest(
    name: 'Regional',
    tilesets: [],
    maps: const [
      ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
    ],
  );
  final actions = <String>[];
  bool fail = false;
  Uint8List? imageBytes;
  RegionalMapSource source() => RegionalMapSource(
    project: project,
    revision: 'revision',
    maps: const {
      'town': MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 8, height: 8),
        entities: [
          MapEntity(
            id: 'arrival',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 3, y: 4),
            blocksMovement: false,
            spawn: MapEntitySpawnData(),
          ),
        ],
      ),
    },
    images: const {'assets/region.png': 'Region'},
  );
  @override
  Future<RegionalMapSource> load() async => source();
  @override
  Future<Uint8List?> readImage(String path) async => imageBytes;
  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    if (fail) throw StateError('Publication failed');
    actions.add(actionId);
    final catalog = project.regionalMap ?? ProjectRegionalMapCatalog();
    project = project.copyWith(
      regionalMap: ProjectRegionalMapCatalog(
        regions: actionId == 'regionalMap.region.upsert'
            ? [
                ...catalog.regions.where(
                  (region) => region.id != (parameters['region'] as Map)['id'],
                ),
                ProjectRegionDefinition.fromJson(
                  Map<String, dynamic>.from(parameters['region'] as Map),
                ),
              ]
            : catalog.regions,
        pointsOfInterest: actionId == 'regionalMap.poi.upsert'
            ? [
                ...catalog.pointsOfInterest.where(
                  (point) => point.id != (parameters['poi'] as Map)['id'],
                ),
                ProjectRegionPointOfInterest.fromJson(
                  Map<String, dynamic>.from(parameters['poi'] as Map),
                ),
              ]
            : catalog.pointsOfInterest,
      ),
    );
    return source();
  }
}

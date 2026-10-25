import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/features/regional_map/data/local_regional_map_adapter.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';

void main() {
  test('Studio regional CRUD publishes canonical actions and confirms destructive changes without changing map bytes', () async {
    final fixture = await createRegionalFixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    final before = await fixture.map.readAsBytes();
    final owner = RegionalMapController(fixture.port, changed: () {});
    await owner.load();
    expect(await owner.port.readImage('assets/region.png'), fixture.imageBytes);
    owner.createRegion('Kanto');
    owner.editRegion(imagePath: 'assets/region.png');
    owner.createPoint('Town', 'town');
    owner.editPoint(
      destination: ProjectRegionDestination(mapId: 'town', spawnId: 'arrival'),
    );
    expect(await owner.saveAll(), isTrue, reason: owner.error);
    final pointId = owner.point!.id;
    final reopened = await fixture.port.load();
    expect(reopened.project.regionalMap!.pointsOfInterest.single.id, pointId);
    expect(
      reopened
          .project
          .regionalMap!
          .pointsOfInterest
          .single
          .destination!
          .spawnId,
      'arrival',
    );
    owner.deletePoint();
    expect(await owner.saveAll(), isTrue, reason: owner.error);
    owner.deleteRegion();
    expect(await owner.saveAll(), isTrue, reason: owner.error);
    expect((await fixture.port.load()).project.regionalMap!.regions, isEmpty);
    expect(await fixture.map.readAsBytes(), before);
  });
  for (final addRegion in [true, false]) {
    testWidgets(
      'native ${addRegion ? 'region' : 'POI'} publication reconciles canonical API order and stays clean on resave, close, export and reopen',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await createRegionalFixture();
          addTearDown(() => fixture.root.delete(recursive: true));
          await seedApiRegionalCatalog(fixture.port);
          final mapBytes = await fixture.map.readAsBytes();
          final maps = MapWorkspaceController(
            fixture.port.session,
            fixture.port.mapAdapter,
          );
          await maps.initialize();
          addTearDown(maps.dispose);
          final port = RecordingRegionalMapPort(fixture.port);
          final owner = RegionalMapController(
            port,
            changed: () {},
            projectChanged: maps.acceptResources,
          );
          addTearDown(owner.dispose);
          await owner.load();
          expect(owner.region!.id, 'zeta');
          if (addRegion) {
            owner.createRegion('Native region');
            owner.editRegion(imagePath: 'assets/region.png');
          } else {
            owner.createPoint('Native point', 'town');
            owner.editPoint(
              destination: ProjectRegionDestination(
                mapId: 'town',
                spawnId: 'arrival',
              ),
            );
          }
          final selection = addRegion ? owner.regionId : owner.pointId;
          expect(owner.dirty, isTrue);
          expect(await owner.saveAll(), isTrue, reason: owner.error);
          expect(owner.dirty, isFalse);
          expect(addRegion ? owner.regionId : owner.pointId, selection);
          final published = await fixture.port.load();
          expect(owner.catalog, published.project.regionalMap);
          final ids = addRegion
              ? owner.catalog.regions.map((region) => region.id).toList()
              : owner.catalog.pointsOfInterest
                    .map((point) => point.id)
                    .toList();
          expect(ids, [...ids]..sort());
          expect(ids, contains(selection));
          final publicationCount = port.actions.length;
          final projectFile = File('${fixture.root.path}/project.json');
          final projectBytes = await projectFile.readAsBytes();
          expect(await owner.saveAll(), isTrue);
          late WorkspaceActions actions;
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  actions = WorkspaceActions(
                    controller: maps,
                    context: () => context,
                    mounted: () => true,
                    changed: () {},
                    resources: () => null,
                    narrative: () => null,
                    regionalMap: () => owner,
                    runtimeBuilder: (_, _, _) => const SizedBox(),
                  );
                  return const Scaffold();
                },
              ),
            ),
          );
          expect(actions.hasPendingChanges, isFalse);
          expect(await actions.flushEditors(), isTrue);
          expect(await actions.allowClose(), isTrue);
          expect(await actions.saveForExport(), isTrue);
          expect(port.actions, hasLength(publicationCount));
          expect(await projectFile.readAsBytes(), projectBytes);
          expect(await fixture.map.readAsBytes(), mapBytes);
          final reopened = RegionalMapController(fixture.port, changed: () {});
          addTearDown(reopened.dispose);
          await reopened.load();
          expect(reopened.catalog, owner.catalog);
          expect(reopened.dirty, isFalse);
        });
      },
    );
  }
  test('partial regional publication preserves the complete remaining native draft and retries only unpublished changes', () async {
    final fixture = await createRegionalFixture();
    addTearDown(() => fixture.root.delete(recursive: true));
    await seedApiRegionalCatalog(fixture.port);
    final port = RecordingRegionalMapPort(fixture.port)
      ..failAction = 'regionalMap.poi.upsert';
    final owner = RegionalMapController(port, changed: () {});
    addTearDown(owner.dispose);
    await owner.load();
    owner.createRegion('Native region');
    owner.editRegion(imagePath: 'assets/region.png');
    final nativeRegionId = owner.regionId;
    owner.createPoint('Native point', 'town');
    owner.editPoint(
      destination: ProjectRegionDestination(mapId: 'town', spawnId: 'arrival'),
    );
    final nativePointId = owner.pointId, desired = owner.catalog;
    expect(await owner.saveAll(), isFalse);
    expect(owner.error, contains('brouillon est conservé'));
    expect(owner.dirty, isTrue);
    expect(owner.canUndo, isTrue);
    expect(owner.catalog, desired);
    expect(owner.pointId, nativePointId);
    final partial = (await fixture.port.load()).project.regionalMap!;
    expect(
      partial.regions.any((region) => region.id == nativeRegionId),
      isTrue,
    );
    expect(partial.pointsOfInterest.map((point) => point.id), ['town']);
    expect(owner.source!.project.regionalMap, partial);
    expect(port.actions, [
      'regionalMap.region.upsert',
      'regionalMap.poi.upsert',
    ]);
    port.failAction = null;
    expect(await owner.saveAll(), isTrue, reason: owner.error);
    expect(owner.dirty, isFalse);
    expect(owner.catalog, (await fixture.port.load()).project.regionalMap);
    expect(owner.pointId, nativePointId);
    expect(port.actions, [
      'regionalMap.region.upsert',
      'regionalMap.poi.upsert',
      'regionalMap.poi.upsert',
    ]);
    expect(await owner.saveAll(), isTrue);
    expect(port.actions, hasLength(3));
  });
  test(
    'Studio refuses a spawn changed on disk since its picker snapshot',
    () async {
      final fixture = await createRegionalFixture();
      addTearDown(() => fixture.root.delete(recursive: true));
      final owner = RegionalMapController(fixture.port, changed: () {});
      await owner.load();
      owner.createRegion('Kanto');
      owner.editRegion(imagePath: 'assets/region.png');
      expect(await owner.saveAll(), isTrue, reason: owner.error);
      owner.createPoint('Town', 'town');
      owner.editPoint(
        destination: ProjectRegionDestination(
          mapId: 'town',
          spawnId: 'arrival',
        ),
      );
      final projectBefore = await File('${fixture.root.path}/project.json')
          .readAsBytes();
      expect(await owner.loadMap('town'), isTrue);
      final currentMap = owner.source!.maps['town']!;
      await fixture.map.writeAsString(
        jsonEncode(currentMap.copyWith(entities: []).toJson()),
      );
      expect(await owner.saveAll(), isFalse);
      expect(owner.error, contains('arrivée a changé'));
      expect(owner.dirty, isTrue);
      expect(
        await File('${fixture.root.path}/project.json').readAsBytes(),
        projectBefore,
      );
    },
  );
}

Future<void> seedApiRegionalCatalog(LocalRegionalMapAdapter port) async {
  var source = await port.load();
  source = await port.publish(
    base: source,
    actionId: 'regionalMap.region.upsert',
    parameters: {
      'region': {
        'id': 'zeta',
        'label': 'API region',
        'imagePath': 'assets/region.png',
      },
    },
  );
  await port.publish(
    base: source,
    actionId: 'regionalMap.poi.upsert',
    parameters: {
      'poi': {
        'id': 'town',
        'regionId': 'zeta',
        'label': 'API town',
        'u': .5,
        'v': .5,
        'mapIds': ['town'],
        'destination': {'mapId': 'town', 'spawnId': 'arrival'},
      },
    },
  );
}

final class RecordingRegionalMapPort
    implements RegionalMapPort, RegionalMapDetailsPort {
  RecordingRegionalMapPort(this.delegate);
  final LocalRegionalMapAdapter delegate;
  final actions = <String>[];
  String? failAction;
  @override
  Future<RegionalMapSource> load() => delegate.load();
  @override
  Future<Uint8List?> readImage(String path) => delegate.readImage(path);
  @override
  Future<MapData> readMap({
    required RegionalMapSource source,
    required String mapId,
  }) => delegate.readMap(source: source, mapId: mapId);
  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    actions.add(actionId);
    if (actionId == failAction) throw StateError('Interrupted publication');
    return delegate.publish(
      base: base,
      actionId: actionId,
      parameters: parameters,
    );
  }
}

Future<
  ({
    Directory root,
    LocalRegionalMapAdapter port,
    File map,
    List<int> imageBytes,
  })
>
createRegionalFixture() async {
  final temp = await Directory.systemTemp.createTemp('studio-regional-');
  final root = Directory(await temp.resolveSymbolicLinks());
  final session = ProjectSession(
    sessionId: root.path,
    directoryPath: root.path,
    name: 'Regional',
  );
  const project = ProjectManifest(
    name: 'Regional',
    tilesets: [],
    maps: [
      ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
    ],
  );
  const map = MapData(
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
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  final mapFile = File('${root.path}/maps/town.json');
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(jsonEncode(map.toJson()));
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
  final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(bytes);
  await File('${root.path}/$assetCatalogStorageKey').writeAsString(
    jsonEncode(
      AssetCatalog(
        records: [
          AssetRecord(
            id: 'region-image',
            logicalPath: 'assets/region.png',
            artifact: artifact,
          ),
        ],
      ).toJson(),
    ),
  );
  final adapter = LocalMapWorkspaceAdapter();
  await adapter.loadProject(session);
  return (
    root: root,
    port: LocalRegionalMapAdapter(session: session, mapAdapter: adapter),
    map: mapFile,
    imageBytes: bytes,
  );
}

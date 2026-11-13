import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/regional_map/data/local_regional_map_adapter.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';

void main() {
  test(
    'regional source offers only region-admissible images and loads map folders',
    () async {
      final fixture = await createRegionalFixture(
        groups: const [
          ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.city),
        ],
        mapGroupId: 'johto',
        extraImagePaths: const ['presentation/intro.png', 'data/icon.png'],
      );
      addTearDown(() => fixture.root.delete(recursive: true));
      final source = await fixture.port.load();
      expect(source.images.keys, ['assets/region.png']);
      expect(source.project.groups.map((group) => group.id), ['johto']);
      expect(source.project.maps.single.groupId, 'johto');
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
createRegionalFixture({
  List<ProjectMapGroup> groups = const [],
  String? mapGroupId,
  List<String> extraImagePaths = const [],
}) async {
  final temp = await Directory.systemTemp.createTemp('studio-regional-');
  final root = Directory(await temp.resolveSymbolicLinks());
  final session = ProjectSession(
    sessionId: root.path,
    directoryPath: root.path,
    name: 'Regional',
  );
  final project = ProjectManifest(
    name: 'Regional',
    tilesets: [],
    groups: groups,
    maps: [
      ProjectMapEntry(
        id: 'town',
        name: 'Town',
        relativePath: 'maps/town.json',
        groupId: mapGroupId,
      ),
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
          for (final (index, path) in extraImagePaths.indexed)
            AssetRecord(
              id: 'extra-image-$index',
              logicalPath: path,
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

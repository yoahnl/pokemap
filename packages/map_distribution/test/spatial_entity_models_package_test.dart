import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('hidden pickups need no visible 3D model', () {
    final payload = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(payload['project/maps/map.json']!))
            as Map<String, dynamic>);
    final owner = MapEntity(
        id: 'hidden-object',
        kind: MapEntityKind.item,
        pos: const GridPos(x: 0, y: 0),
        item: const MapEntityItemData(
            gameItemId: 'resource', visibility: MapEntityItemVisibility.hidden));
    payload['project/maps/map.json'] = utf8.encode(
        jsonEncode(map.copyWith(entities: [owner]).toJson()));
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(
            capabilities: ['map3d@1', 'map3d.gameplay@1']),
        payloadFiles: payload);
    expect(const GamePackageInspector().inspect(built.packageBytes).payloadPaths,
        contains('project/maps/map.json'));
  });
  test('visible pickups still require a linked 3D model', () {
    final payload = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(payload['project/maps/map.json']!))
            as Map<String, dynamic>);
    final owner = MapEntity(
        id: 'visible-object',
        kind: MapEntityKind.item,
        pos: const GridPos(x: 0, y: 0),
        item: const MapEntityItemData(gameItemId: 'resource'));
    payload['project/maps/map.json'] = utf8.encode(
        jsonEncode(map.copyWith(entities: [owner]).toJson()));
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(
                capabilities: ['map3d@1', 'map3d.gameplay@1']),
            payloadFiles: payload),
        throwsA(isA<GamePackageFormatException>().having((error) => error.code,
            'code', 'runtime3d.gameplay_unsupported')));
  });
  test('entity-linked 3D objects fail closed without capability and on older players',
      () {
    final payload = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(payload['project/maps/map.json']!))
            as Map<String, dynamic>);
    final owner = MapEntity(id: 'object', kind: MapEntityKind.item, pos: const GridPos(x: 0, y: 0), item: const MapEntityItemData(gameItemId: 'resource'));
    payload['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(entities: [owner],
      spatialScene: map.spatialScene!.copyWith(instances: [map.spatialScene!.instances.single.copyWith(entityId: owner.id)])).toJson()));
    expect(
        () => const GamePackageBuilder().build(
            manifest: spatialManifest(capabilities: ['map3d@1', 'map3d.gameplay@1']),
            payloadFiles: payload),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message,
            'message',
            contains(SpatialModelInstance.entityBindingCapabilityId))));
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(
            capabilities: ['map3d@1', 'map3d.gameplay@1', SpatialModelInstance.entityBindingCapabilityId]),
        payloadFiles: payload);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains(SpatialModelInstance.entityBindingCapabilityId));
    final older = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const {'map3d@1', 'map3d.gameplay@1'},
        supportedProjectFormats: const {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: const {1});
    expect(
        () => GamePackageInspector(hostCompatibility: older)
            .inspect(built.packageBytes),
        throwsA(isA<GamePackageFormatException>()
            .having((error) => error.code, 'code', 'capabilityUnsupported')));
  });
}

import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/cs_audio_package_fixture.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    test('$dimension persistent Strength requires extended obstacle semantics', () {
      final files = csAudioPayload(dimension);
      final initial = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)) as Map<String, dynamic>);
      final spatial = initial.spatialScene;
      final map = initial.copyWith(entities: [
        ...initial.entities,
        const MapEntity(id: 'boulder', kind: MapEntityKind.custom, pos: GridPos(x: 0, y: 0),
          fieldObstacle: MapEntityFieldObstacleData(kind: FieldObstacleKind.strengthBoulder,
            resetPolicy: FieldObstacleResetPolicy.persistent)),
      ], spatialScene: spatial?.copyWith(instances: [spatial.instances.single.copyWith(entityId: 'boulder')]));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.toJson()));
      final base = [FieldObstacleCapabilities.capabilityId,
        if (spatial != null) ...[SpatialGameplayCapabilities.capabilityId, SpatialModelInstance.entityBindingCapabilityId]];
      expect(() => const GamePackageBuilder().build(manifest: csAudioManifest(dimension, base), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>().having((error) => error.message,
          'extended semantics', contains(FieldObstacleCapabilities.extendedCapabilityId))));
      final built = const GamePackageBuilder().build(
        manifest: csAudioManifest(dimension, [...base, FieldObstacleCapabilities.extendedCapabilityId]), payloadFiles: files);
      expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities,
        contains(FieldObstacleCapabilities.extendedCapabilityId));
    });
  }
  for (final dimension in ProjectDimension.values) {
    test(
        '$dimension persistent obstacles require an explicit package capability',
        () {
      final files = csAudioPayload(dimension);
      final initial = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      final spatial = initial.spatialScene;
      final map = initial.copyWith(
          entities: [
            ...initial.entities,
            const MapEntity(
                id: 'tree',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                fieldObstacle: MapEntityFieldObstacleData(
                    kind: FieldObstacleKind.cutTree,
                    resetPolicy: FieldObstacleResetPolicy.persistent))
          ],
          spatialScene: spatial?.copyWith(instances: [
            spatial.instances.single.copyWith(entityId: 'tree')
          ]));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.toJson()));
      final base = [
        if (spatial != null) ...[
          SpatialGameplayCapabilities.capabilityId,
          SpatialModelInstance.entityBindingCapabilityId
        ]
      ];
      expect(
          () => const GamePackageBuilder().build(
              manifest: csAudioManifest(dimension, base), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.message,
              'missing capability',
              contains(FieldObstacleCapabilities.capabilityId))));
      final built = const GamePackageBuilder().build(
          manifest: csAudioManifest(
              dimension, [...base, FieldObstacleCapabilities.capabilityId]),
          payloadFiles: files);
      expect(
          const GamePackageInspector()
              .inspect(built.packageBytes)
              .manifest
              .compatibility
              .requiredCapabilities,
          contains(FieldObstacleCapabilities.capabilityId));
    });
  }
}

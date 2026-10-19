import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';

void main() {
  test('navigation advertises continuous ramp endpoint numbers', () {
    final descriptor = MapMutationDispatcher.canonical()
        .descriptors
        .singleWhere((value) => value.id == 'map3d.navigation.configure');
    final schema = descriptor.extensions['inputSchema'] as Map;
    final navigation = (schema['properties'] as Map)['navigation'] as Map;
    final ramps = (navigation['properties'] as Map)['ramps'] as Map;
    final properties = ((ramps['items'] as Map)['properties']) as Map;
    expect((properties['lowLevel'] as Map)['type'], 'number');
    expect((properties['highLevel'] as Map)['type'], 'number');
    expect((properties['lowLevel'] as Map)['exclusiveMaximum'], 64);
    expect((properties['highLevel'] as Map)['exclusiveMinimum'], 0);
  });

  test('fractional navigation survives direct and JSONL plan apply reopen undo',
      () async {
    final outputs = <List<int>>[];
    for (final direct in [true, false]) {
      final host = await ResourceInformationFixture.create(ProjectManifest(
        name: 'Fractional stairs',
        maps: const [],
        tilesets: const [],
        version: ProjectVersion.v9,
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ));
      addTearDown(host.dispose);
      final surface = SpatialTerrainSurface(
        id: 'upper-platform',
        x: 1,
        z: 1,
        height: 1.5,
        footprints: [
          BorderGroundFootprint(points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: 4, z: 0),
            BorderGroundPoint(x: 4, z: 1),
            BorderGroundPoint(x: 0, z: 1),
          ]),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Platforms',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [surface]),
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 6, z: 6)),
        ),
      );
      final file = File('${host.root.path}/maps/map.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map.toJson()));
      final manifest = await host.read();
      await File('${host.root.path}/project.json').writeAsString(jsonEncode(
        manifest.copyWith(maps: [
          const ProjectMapEntry(
              id: 'map', name: 'Platforms', relativePath: 'maps/map.json'),
        ]).toJson(),
      ));
      final before = await file.readAsBytes();
      final navigation = map.spatialScene!.navigation.toJson();
      (navigation['ramps'] as List).add({
        'id': 'stairs',
        'x': 2,
        'z': 2,
        'width': 1,
        'depth': 2,
        'lowLevel': 0,
        'highLevel': 1.5,
        'direction': 'north',
      });
      final parameters = <String, Object?>{
        'mapId': 'map',
        'navigation': navigation
      };
      if (direct) {
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final plan = await host.mutations.plan(
            ProjectHandle(host.project),
            AuthoringRequest(
              requestId: 'fractional',
              actionId: 'map3d.navigation.configure',
              actionVersion: 1,
              workspaceHandle: host.workspace,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'fractional',
              parameters: parameters,
            ));
        expect(await file.readAsBytes(), before);
        await host.mutations.apply(ProjectHandle(host.project),
            planId: plan['planId'] as String, operationId: 'fractional');
      } else {
        final plan = await host.plan('map3d.navigation.configure', parameters);
        expect(plan.status, AuthoringResultStatus.success,
            reason: plan.toJson().toString());
        expect(await file.readAsBytes(), before);
        expect((await host.apply(plan)).status, AuthoringResultStatus.success);
      }
      final stored = MapData.fromJson(jsonDecode(await file.readAsString()));
      final scene = stored.spatialScene!;
      expect(scene.navigation.ramps.single.highLevel, 1.5);
      expect(
          scene.rampHasTerrainContacts(scene.navigation.ramps.single), isTrue);
      expect(scene.worldHeightAt(2.5, 3), .75);
      expect(scene.levelHeight, 1);
      expect(scene.heightLevels, map.spatialScene!.heightLevels);
      outputs.add(await file.readAsBytes());
      final invalid =
          jsonDecode(jsonEncode(navigation)) as Map<String, dynamic>;
      (invalid['ramps'] as List).single['highLevel'] = .5;
      final rejected = await host.plan('map3d.navigation.configure',
          {'mapId': 'map', 'navigation': invalid});
      expect(rejected.status, AuthoringResultStatus.failure);
      expect(await file.readAsBytes(), outputs.last);
      await host.command('close', {'projectHandle': host.project});
      final reopened =
          await host.command('open', {'projectRoot': host.root.path});
      expect(reopened.status, AuthoringResultStatus.success);
      final handle = ProjectHandle(reopened.data['projectHandle'] as String);
      expect((await host.snapshots.load(handle)).maps.single, stored);
      final history = await host.mutations.history(handle, limit: 1);
      await host.mutations.undo(handle,
          entryId: (history['entries'] as List).single['entryId'] as String,
          idempotencyKey: 'undo-fractional');
      expect(MapData.fromJson(jsonDecode(await file.readAsString())), map);
      await host.command('close', {'projectHandle': handle.value});
    }
    expect(outputs[0], outputs[1]);
  });
}

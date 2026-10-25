import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/smart_tile_native_transition_guard.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'environment_spatial_actions_test.dart' show spatialEnvironmentFixture;

ProjectSnapshot snapshot({required bool scoped}) {
  final fixture = spatialEnvironmentFixture();
  final manifest = fixture.project.copyWith(maps: [
    ...fixture.project.maps,
    const ProjectMapEntry(
        id: 'other', name: 'Other', relativePath: 'maps/other.json'),
  ]);
  return ProjectSnapshot(
      projectHandle: const ProjectHandle('project'),
      revision:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      manifest: manifest,
      maps: [fixture.map],
      materializedCatalogProject: scoped,
      availableProjectSections: scoped ? const {} : null,
      scopedStorageRevisions: scoped
          ? {
              'maps/map.json':
                  'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
            }
          : null,
      resourceFingerprints: {
        'project':
            'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        'map:map':
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
      },
      resourceBytes: {
        'project': utf8.encode(jsonEncode(manifest.toJson())),
        'map:map': utf8.encode(jsonEncode(fixture.map.toJson()))
      },
      resourceStorageKeys: {
        'project': 'project.json',
        'map:map': 'maps/map.json'
      });
}

void main() {
  test(
      'unchanged published catalog permits a selected map Smart Tile preflight',
      () {
    final value = snapshot(scoped: true);
    expect(
        () => preflightNativeSmartTileMutation(
            snapshot: value,
            projectedManifest: value.manifest,
            projectedMaps: {'map': value.maps.single}),
        returnsNormally);
    expect(
        () => requireExistingNativeSmartTileProject(value,
            operation: 'smart_tile.cell.paint'),
        returnsNormally);
  });

  test('an unscoped incomplete map snapshot remains rejected', () {
    final value = snapshot(scoped: false);
    expect(
        () => preflightNativeSmartTileMutation(
            snapshot: value,
            projectedManifest: value.manifest,
            projectedMaps: {'map': value.maps.single}),
        throwsA(isA<MapAuthoringException>()));
  });

  test('a selected map preflight cannot change shared catalog or project data',
      () {
    final value = snapshot(scoped: true);
    expect(
        () => preflightNativeSmartTileMutation(
            snapshot: value,
            projectedManifest: value.manifest.copyWith(name: 'Changed project'),
            projectedMaps: {'map': value.maps.single}),
        throwsA(isA<MapAuthoringException>()));
  });

  test('a selected map preflight cannot project an unrelated map', () {
    final value = snapshot(scoped: true);
    expect(
        () => preflightNativeSmartTileMutation(
            snapshot: value,
            projectedManifest: value.manifest,
            projectedMaps: {'other': value.maps.single.copyWith(id: 'other')}),
        throwsA(isA<MapAuthoringException>()));
  });
}

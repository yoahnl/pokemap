import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

import '../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test(
    'rejects invalid exterior data before resolving map dependencies',
    () async {
      final root = await Directory.systemTemp.createTemp('exterior-admission-');
      addTearDown(() => root.delete(recursive: true));
      final path = '${root.path}/project.json';
      const mapId = 'route';
      final map = MapData(
        id: mapId,
        name: 'Route',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(
          width: 4,
          depth: 4,
          instances: [
            SpatialModelInstance(
              id: 'roadside',
              modelId: 'absent-model',
              position: Model3dVector3(x: 1, y: 0, z: 1),
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Exterior admission',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(
            id: mapId,
            name: 'Route',
            relativePath: 'maps/route.json',
          ),
        ],
        tilesets: const [],
      );
      await Directory('${root.path}/maps').create();
      await File(path).writeAsString(jsonEncode(project.toJson()));
      await File('${root.path}/maps/route.json')
          .writeAsString(jsonEncode(map.toJson()));
      final sidecar = File('${root.path}/maps/route.decoration.json');
      await sidecar.writeAsString('{}');
      final catalog = await RuntimeProjectCatalog.open(path);
      addTearDown(catalog.dispose);
      Future<Object> load() => loadRuntimeMapBundle(
        projectFilePath: path,
        mapId: mapId,
        projectCatalog: catalog,
      );
      await expectLater(
        load(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid exterior decoration storage definition'),
          ),
        ),
      );
      await sidecar.delete();
      await expectLater(
        load(),
        throwsA(isA<RuntimeCatalogDefinitionMissingException>()),
      );
    },
  );

  test('bundle retains companions from both supplied project views', () async {
    final root = await Directory.systemTemp.createTemp('companion-projection-');
    addTearDown(() => root.delete(recursive: true));
    ProjectPartyCompanionConfig companion(String id) =>
        ProjectPartyCompanionConfig(
          enabled: true,
          mappings: [
            PartyCompanionVisual(
              speciesId: id,
              formId: 'base',
              characterId: id,
            ),
          ],
        );
    final files = spatialPayload();
    final base = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)),
    );
    final hero = base.characters.first;
    final project = base.copyWith(
      pokemon: base.pokemon.copyWith(enabled: true),
      partyCompanion: companion('first'),
      characters: [
        ...base.characters,
        for (final id in ['first', 'second', 'unused'])
          hero.copyWith(id: id, name: id),
      ],
    );
    files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
    for (final entry in files.entries.where(
      (e) => e.key.startsWith('project/'),
    )) {
      final file = File(
        '${root.path}/${entry.key.substring('project/'.length)}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final path = '${root.path}/project.json';
    final catalog = await RuntimeProjectCatalog.open(path);
    addTearDown(catalog.dispose);
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: path,
      mapId: base.maps.first.id,
      preloadedManifest: project.copyWith(partyCompanion: companion('second')),
      projectCatalog: catalog,
    );
    expect(
      bundle.manifest.characters.map((actor) => actor.id),
      unorderedEquals([hero.id, 'first', 'second']),
    );
  });

  test(
    'exterior roots admit only their selected model without loading its bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('exterior-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4),
      );
      final model = ProjectModel3dEntry(
        id: 'exterior-only',
        name: 'Exterior',
        sourceAssetId: 'exterior-source',
        relativePath: 'assets/models3d/exterior-only.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      );
      final project = ProjectManifest(
        name: 'Exterior',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(
            id: 'route',
            name: 'Route',
            relativePath: 'maps/route.json',
          ),
        ],
        tilesets: const [],
        models3d: [model],
      );
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/route.json')
          .writeAsString(jsonEncode(map.toJson()));
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      final catalog = await RuntimeProjectCatalog.open(
        '${root.path}/project.json',
      );
      addTearDown(() => catalog.dispose());
      final ProjectManifest regular = await catalog.manifestForMaps([map]);
      expect(regular.models3d, isEmpty);
      final ProjectManifest exterior = await catalog.manifestForMaps(
        [map],
        extraDefinitionKeys: [
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'exterior-only'),
        ],
      );
      expect(exterior.models3d.single, model);
      expect(await File('${root.path}/assets/exterior.glb').exists(), isFalse);
    },
  );
}

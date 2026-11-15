import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';
import '../map_workspace/map_relief_fixture.dart';

Future<void> writeReliefCatalogProject(Directory root) async {
  await writeExampleProject(root);
  for (final id in ['jardin', 'clairiere']) {
    final file = File('${root.path}/maps/$id.json');
    final map = MapData.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    await file.writeAsString(
      jsonEncode(reliefToolMap().copyWith(id: map.id, name: map.name).toJson()),
    );
  }
  final file = File('${root.path}/project.json');
  final source = ProjectManifest.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  await file.delete();
  final relief = reliefToolProject();
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'relief-flow-test',
    project: source.copyWith(
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      models3d: [...relief.models3d, _bank(relief.models3d.single)],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: relief.borderCatalog.formatVersion,
        records: [
          relief.borderCatalog.records.single,
          _bankBorder(relief.borderCatalog, 'berge', 'Talus — angles courts'),
          _bankBorder(relief.borderCatalog, 'contour', 'Contour natif — 1'),
        ],
      ),
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (final id in ['fence', 'berge'])
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: id,
              familyId: 'relief',
              category: ResourceUsageCategory.relief,
            ),
        ],
      ),
    ),
  );
}

final class ReadLogReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader,
        ProjectDirectoryReader {
  final paths = <String>[];
  Completer<void>? gate;
  final _local = const LocalProjectFileReader();

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _local.canonicalizeDirectory(path);

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => _local.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _local.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    await gate?.future;
    return _local.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}

ProjectModel3dEntry _bank(ProjectModel3dEntry face) => ProjectModel3dEntry(
  id: 'bank',
  name: 'Berge basse',
  sourceAssetId: 'bank-source',
  relativePath: 'assets/models3d/bank.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(
        x: face.inspection.bounds.min.x,
        y: -.6,
        z: face.inspection.bounds.min.z,
      ),
      max: face.inspection.bounds.max,
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

BorderBlueprintRecord _bankBorder(
  ProjectBorderCatalog catalog,
  String id,
  String name,
) {
  final raw = encodeBorderBlueprintRecordJson(
    catalog.records.single,
    formatVersion: catalog.formatVersion,
  );
  raw['id'] = id;
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['name'] = name;
    for (final primitive in (definition['primitives'] as List).cast<Map>()) {
      primitive['sourceModelId'] = 'bank';
    }
  }
  return decodeBorderBlueprintRecordJson(
    raw,
    formatVersion: catalog.formatVersion,
  );
}

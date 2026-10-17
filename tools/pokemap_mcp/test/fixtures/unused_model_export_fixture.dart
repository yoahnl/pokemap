import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_distribution/test/support/glb_fixture.dart';
import '../../../../packages/map_distribution/test/support/spatial_package_fixture.dart';

Future<void> main(List<String> args) async {
  final root = Directory(args.single).absolute;
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(jsonDecode(
      utf8.decode(files['project/project.json']!)) as Map<String, dynamic>);
  final catalog = AssetCatalog.fromJson(jsonDecode(
      utf8.decode(files['project/$assetCatalogStorageKey']!))
      as Map<String, dynamic>);
  final bytes = triangleGlb(edit: (json) {
    json['nodes'][0].remove('translation');
    json['nodes'][0].remove('scale');
    json['extras'] = {'fixture': 'obsolete-model'};
  });
  final artifact = ContentArtifactRef.fromBytes(bytes,
      mediaType: 'model/gltf-binary');
  final unused = AssetRecord(
      id: 'obsolete-source',
      logicalPath: 'assets/models3d/obsolete.glb',
      artifact: artifact);
  files['project/${unused.logicalPath}'] = bytes;
  files['project/${assetBlobStorageKey(artifact)}'] = bytes;
  files['project/$assetCatalogStorageKey'] = utf8.encode(jsonEncode(
      AssetCatalog(records: [...catalog.records, unused]).toJson()));
  files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
      models3d: [
        ...project.models3d,
        ProjectModel3dEntry(
            id: 'obsolete',
            name: 'Obsolete model',
            sourceAssetId: unused.id,
            relativePath: unused.logicalPath,
            inspection: const GlbModel3dInspector().inspect(bytes))
      ],
      smartTileCatalog: const ProjectSmartTileCatalog.empty()).toJson()));
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key.substring(8)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  await GamePackageExportProfileStore(projectRoot: root).save(
      GamePackageExportProfile(
          gameId: 'games.example.unused-models-mcp',
          gameVersion: '0.1.0',
          title: 'Unused model MCP',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr']));
  stdout.writeln(jsonEncode({
    'unusedLogicalPath': unused.logicalPath,
    'unusedBlobPath': assetBlobStorageKey(artifact),
  }));
}
